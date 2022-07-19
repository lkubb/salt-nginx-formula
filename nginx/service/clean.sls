# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

{%- if nginx.session_ticket_key_rotation %}

Nginx session ticket key rotation is dead:
  service.dead:
    - name: nginx-rotate-session-ticket-keys.timer
    - enable: False
{%- endif %}

nginx-service-clean-service-dead:
  service.dead:
    - name: {{ nginx.lookup.service.name }}
    - enable: False
