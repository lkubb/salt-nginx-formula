# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_package_install = tplroot ~ '.package.install' %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}
{%- from tplroot ~ "/libtofs.jinja" import files_switch with context %}

include:
  - {{ sls_package_install }}

{%- if "sync" != nginx.config %}

nginx-config-file-file-managed:
  file.managed:
    - name: {{ nginx.lookup.config }}
    - source: {{ files_switch(['nginx.conf', 'nginx.conf.j2'],
                              lookup='nginx-config-file-file-managed'
                 )
              }}
    - mode: 644
    - user: root
    - group: {{ nginx.lookup.rootgroup }}
    - makedirs: True
    - template: jinja
    - require:
      - sls: {{ sls_package_install }}
    - context:
        nginx: {{ nginx | json }}

{%- else %}

nginx-config-file-file-managed:
  file.recurse:
    - name: {{ salt["file.dirname"](nginx.lookup.config) }}
    - source: {{ files_switch(['/etc/nginx'],
                              lookup='nginx-config-file-file-managed'
                 )
              }}
    - file_mode: '0644'
    - dir_mode: '0755'
    - user: root
    - group: {{ nginx.lookup.rootgroup }}
    - makedirs: True
    - template: jinja
    - include_empty: true
    - require:
      - sls: {{ sls_package_install }}
    - context:
        nginx: {{ nginx | json }}
{%- endif %}
