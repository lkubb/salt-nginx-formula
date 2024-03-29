# vim: ft=sls

{#-
    Removes the nginx package and nginx repositories.
    Has a dependency on `nginx.config.clean`_.
#}

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_config_clean = tplroot ~ ".config.clean" %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

include:
  - {{ sls_config_clean }}

{%- if nginx.session_ticket_key_rotation %}

Nginx session ticket key rotation is setup:
  file.absent:
    - names:
      - /usr/local/bin/nginx-create-session-ticket-keys
      - /usr/local/bin/nginx-rotate-session-ticket-keys
      - /etc/systemd/system/nginx-create-session-ticket-keys.service
      - /etc/systemd/system/nginx-rotate-session-ticket-keys.service
      - /etc/systemd/system/nginx-rotate-session-ticket-keys.timer
{%- endif %}

Nginx is removed:
  pkg.removed:
    - name: {{ nginx.lookup.pkg.name }}
    - require:
      - sls: {{ sls_config_clean }}
