# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_service_clean = tplroot ~ '.package.install' %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

include:
  - {{ sls_service_clean }}

{#- This can lead to data loss, so hide it behind a switch #}

{%- if nginx.webroots and nginx.lookup.remove_all_data_for_sure %}

Specified nginx webroot paths are absent:
  file.absent:
    - names: {{ nginx.webroots }}
    - require:
      - sls: {{ sls_service_clean }}
{%- endif %}
