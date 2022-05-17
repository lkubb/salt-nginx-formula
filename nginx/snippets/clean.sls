# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

{%- if nginx.snippets %}

Nginx snippets are absent:
  file.absent:
    - names:
{%-   for name in nginx.snippets %}
      - {{ nginx.lookup.snippets | path_join(name ~ '.conf') }}
{%-   endfor %}
{%- endif %}
