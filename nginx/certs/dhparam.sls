# vim: ft=sls

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_package_install = tplroot ~ ".package.install" %}
{%- set sls_service_running = tplroot ~ ".service.running" %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

include:
  - {{ sls_package_install }}
  - {{ sls_service_running }}

Certificates directory exists:
  file.directory:
    - name: {{ nginx.lookup.certs }}
    - mode: '0600'
    - user: {{ nginx.lookup.user }}
    - group: {{ nginx.lookup.group }}
    - makedirs: true
    - require:
      - sls: {{ sls_package_install }}

{%- if nginx.dhparam.values() | select("mapping") | list %}

OpenSSL is installed for Nginx dhparam generation:
  pkg.installed:
    - name: {{ nginx.lookup.pkg.openssl }}
    - install_recommends: false
{%- endif %}

{%- for name, config in nginx.dhparam.items() %}
{%-   if config is mapping %}

DH param {{ name }} was generated:
  cmd.run:
    - name: openssl dhparam -out '{{ name }}.pem' {{ config.get("keysize", 2048) }}
    - cwd: {{ nginx.lookup.certs }}
    - runas: {{ nginx.lookup.user }}
    - creates: {{ nginx.lookup.certs | path_join(name ~ ".pem") }}
    - require:
      - file: {{ nginx.lookup.certs }}
      - pkg: {{ nginx.lookup.pkg.openssl }}
{%-   endif %}

DH param {{ name }} is managed:
  file.managed:
    - name: {{ nginx.lookup.certs | path_join(name ~ ".pem") }}
{%-   if config is string %}
{%-     if "://" in config %}
    - source: {{ config }}
{%-     else %}
    - contents_pillar: {{ config }}
{%-     endif %}
{%-   else %}
    - replace: false
{%-   endif %}
    - mode: '0600'
    - user: {{ nginx.lookup.user }}
    - group: {{ nginx.lookup.group }}
    - require:
{%-   if config is mapping %}
      - DH param {{ name }} was generated
{%-   else %}
      - file: {{ nginx.lookup.certs }}
    - watch_in:
      - service: {{ nginx.lookup.service.name }}
{%-   endif %}
{%- endfor %}
