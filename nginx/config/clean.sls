# vim: ft=sls

{#-
    Removes the configuration of the nginx service and has a
    dependency on `nginx.service.clean`_.
#}

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_service_clean = tplroot ~ ".service.clean" %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

include:
  - {{ sls_service_clean }}

Nginx configuration is absent:
  file.absent:
    - name: {{ nginx.lookup.config }}
    - require:
      - sls: {{ sls_service_clean }}

{%- if grains | traverse("selinux:enabled") %}
{%-   if nginx.selinux.httpd_can_network_connect is not none %}

Nginx can act as reverse proxy:
  selinux.boolean:
    - name: httpd_can_network_connect
    - value: false
    - persist: true
{%-   endif %}
{%- endif %}
