# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_config_clean = tplroot ~ '.config.clean' %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

include:
  - {{ sls_config_clean }}

nginx-package-clean-pkg-removed:
  pkg.removed:
    - name: {{ nginx.lookup.pkg.name }}
    - require:
      - sls: {{ sls_config_clean }}
