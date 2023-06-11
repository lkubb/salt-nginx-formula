# vim: ft=sls

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_package_install = tplroot ~ ".package.install" %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}
{%- from tplroot ~ "/libtofsstack.jinja" import files_switch with context %}

include:
  - {{ sls_package_install }}

{%- if nginx.config != "sync" %}

Nginx configuration is managed:
  file.managed:
    - name: {{ nginx.lookup.config }}
    - source: {{ files_switch(
                    ["nginx.conf", "nginx.conf.j2"],
                    config=nginx,
                    lookup="Nginx configuration is managed",
                 )
              }}
    - mode: '0644'
    - user: root
    - group: {{ nginx.lookup.rootgroup }}
    - makedirs: true
    - template: jinja
    - require:
      - sls: {{ sls_package_install }}
    - context:
        nginx: {{ nginx | json }}

{%- else %}

Nginx configuration is managed:
  file.recurse:
    - name: {{ salt["file.dirname"](nginx.lookup.config) }}
    - source: {{ files_switch(
                    ["/etc/nginx"],
                    config=nginx,
                    lookup="Nginx configuration is managed"
                 )
              }}
    - file_mode: '0644'
    - dir_mode: '0755'
    - user: root
    - group: {{ nginx.lookup.rootgroup }}
    - makedirs: true
    - template: jinja
    - include_empty: true
    - require:
      - sls: {{ sls_package_install }}
    - context:
        nginx: {{ nginx | json }}
{%- endif %}
