# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_package_install = tplroot ~ '.package.install' %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

{%- for name in nginx.servers %}

Nginx server {{ name }} is absent:
  nginx.site_absent:
    - name: {{ name }}
    - nginx_conf: {{ nginx.lookup.config }}
    - now: true
{%- endfor %}

Nginx default host is enabled:
  nginx.site:
    - name: default
    - nginx_conf: {{ nginx.lookup.config }}
    - enabled: true
    - onlyif:
      - fun: nginx.site_exists
        name: default
        nginx_conf: {{ nginx.lookup.config }}
