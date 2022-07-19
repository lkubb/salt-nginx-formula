# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

nginx-package-install-pkg-installed:
  pkg.installed:
    - name: {{ nginx.lookup.pkg.name }}

# Using the whitelist makes unlisted disappear. Just sync all modules.
Custom nginx modules are synced:
  saltutil.sync_all:
    - refresh: true
