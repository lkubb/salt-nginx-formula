# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_package_install = tplroot ~ '.package.install' %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

include:
  - {{ sls_package_install }}

{%- if nginx.webroots %}

Specified nginx webroot paths are present:
  file.directory:
    - names: {{ nginx.webroots }}
    - user: {{ nginx.lookup.user }}
    - group: {{ nginx.lookup.group }}
    - makedirs: true
    - require:
      - sls: {{ sls_package_install }}
{%- endif %}
