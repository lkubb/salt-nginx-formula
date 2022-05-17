# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

nginx-package-install-pkg-installed:
  pkg.installed:
    - name: {{ nginx.lookup.pkg.name }}

Custom nginx modules are synced:
  module.run:
    - saltutil.sync_all:
      - refresh: true
      - extmod_whitelist:
          modules:
            - nginx
          states:
            - nginx
          utils:
            - nginx
