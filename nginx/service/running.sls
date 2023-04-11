# vim: ft=sls

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_config_file = tplroot ~ ".config.file" %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

include:
  - {{ sls_config_file }}

Nginx is running:
  service.running:
    - name: {{ nginx.lookup.service.name }}
    - enable: true
    - reload: true
    - watch:
      - sls: {{ sls_config_file }}

{%- if nginx.session_ticket_key_rotation %}

Nginx session ticket key rotation is running:
  service.running:
    - name: nginx-rotate-session-ticket-keys.timer
    - enable: true
    - require:
      - sls: {{ sls_config_file }}
{%- endif %}
