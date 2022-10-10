# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_service_running = tplroot ~ '.service.running' %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}
{%- from tplroot ~ "/libtofs.jinja" import files_switch with context %}

include:
  - {{ sls_service_running }}

Nginx default host is managed:
  nginx.site:
    - name: default
    - nginx_conf: {{ nginx.lookup.config }}
    - enabled: {{ false == nginx.disable_default_host }}
    - onlyif:
      - fun: nginx.site_exists
        name: default
        nginx_conf: {{ nginx.lookup.config }}
    - watch_in:
      - nginx-service-running-service-running

{%- for name, config in nginx.servers.items() %}

Nginx server {{ name }} is managed:
  nginx.site:
    - name: {{ name }}
    - nginx_conf: {{ nginx.lookup.config }}
{%-   if config.get("source") %}
    - source: {{ config.source }}
{%-   else %}
    - source: {{ files_switch(["servers/" ~ config.get("source_file_name", name) ~ ".conf", 'server.conf.j2'],
                              lookup='Nginx server ' ~ name ~ ' is managed'
                 )
              }}
{%-   endif %}
    - template: jinja
    - context:
        nginx: {{ nginx | json }}
        server_name: {{ name }}
    - enabled: {{ config.get("enabled", false) }}
    - now: false
    - watch_in:
      - nginx-service-running-service-running
{%- endfor %}
