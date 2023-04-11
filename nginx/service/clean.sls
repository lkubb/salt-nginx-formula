# vim: ft=sls

{#-
    Stops the nginx service (and session key rotation service, if configured)
    and disables it at boot time.
#}

{%- set tplroot = tpldir.split("/")[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

{%- if nginx.session_ticket_key_rotation %}

Nginx session ticket key rotation is dead:
  service.dead:
    - name: nginx-rotate-session-ticket-keys.timer
    - enable: false
{%- endif %}

Nginx is dead:
  service.dead:
    - name: {{ nginx.lookup.service.name }}
    - enable: false
