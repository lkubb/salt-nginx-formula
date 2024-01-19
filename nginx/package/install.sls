# vim: ft=sls

{%- set tplroot = tpldir.split("/")[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

{%- if nginx.install_method == "repo" %}

include:
  - {{ slsdotpath }}.repo
{%- endif %}

Nginx is installed:
  pkg.installed:
    - name: {{ nginx.lookup.pkg.name }}

Nginx user/group is present:
  user.present:
    - name: {{ nginx.lookup.user }}
    - home: {{ nginx.lookup.workdir }}
    - shell: /sbin/nologin
    - empty_password: true
    - fullname: Nginx web server
    - system: true
    - usergroup: {{ nginx.lookup.group == nginx.lookup.user }}
{%- if nginx.lookup.groups_extra %}
    - groups: {{ nginx.lookup.groups_extra | json }}
{%- endif %}
{%- if nginx.lookup.group != nginx.lookup.user %}
    - gid: {{ nginx.lookup.group }}
    - require:
      - group: {{ nginx.lookup.group }}
  group.present:
    - name: {{ nginx.lookup.group }}
    - system: true
{%- endif %}

Custom nginx modules are synced:
  saltutil.sync_all:
    - refresh: true
    - unless:
      - '{{ ("nginx" in salt["saltutil.list_extmods"]().get("states", [])) | lower }}'

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
