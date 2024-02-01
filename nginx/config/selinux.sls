# vim: ft=sls

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_package_install = tplroot ~ ".package.install" %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

include:
  - {{ sls_package_install }}

{%- if grains | traverse("selinux:enabled") %}
{%-   if nginx.selinux.httpd_can_network_connect is not none %}

Nginx can act as reverse proxy:
  selinux.boolean:
    - name: httpd_can_network_connect
    - value: {{ nginx.selinux.httpd_can_network_connect }}
    - persist: true
{%-   endif %}
{%- endif %}
