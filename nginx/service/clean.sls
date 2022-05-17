# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

nginx-service-clean-service-dead:
  service.dead:
    - name: {{ nginx.lookup.service.name }}
    - enable: False
