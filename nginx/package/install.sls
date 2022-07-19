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

{%- if nginx.session_ticket_key_rotation %}

Nginx session ticket key rotation is setup:
  file.managed:
    - names:
      - /usr/local/bin/nginx-create-session-ticket-keys:
        - source: salt://nginx/files/nginx-rotate-session-ticket-keys/nginx-create-session-ticket-keys
        - mode: '0744'
      - /usr/local/bin/nginx-rotate-session-ticket-keys:
        - source: salt://nginx/files/nginx-rotate-session-ticket-keys/nginx-rotate-session-ticket-keys
        - mode: '0744'
      - /etc/systemd/system/nginx-create-session-ticket-keys.service:
        - source: salt://nginx/files/nginx-rotate-session-ticket-keys/nginx-create-session-ticket-keys.service
      - /etc/systemd/system/nginx-rotate-session-ticket-keys.service:
        - source: salt://nginx/files/nginx-rotate-session-ticket-keys/nginx-rotate-session-ticket-keys.service
      - /etc/systemd/system/nginx-rotate-session-ticket-keys.timer:
        - source: salt://nginx/files/nginx-rotate-session-ticket-keys/nginx-rotate-session-ticket-keys.timer
    - mode: '0644'
    - user: root
    - group: {{ nginx.lookup.rootgroup }}
    - makedirs: true
    - template: jinja
    - require:
      - pkg: {{ nginx.lookup.pkg.name }}
{%- endif %}
