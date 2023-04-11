# vim: ft=sls

{#-
    Removes configured webroot directories if
    ``nginx.lookup.remove_all_data_for_sure`` is True.
    Has a dependency on `nginx.service.clean`_.
#}

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_service_clean = tplroot ~ ".package.install" %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

include:
  - {{ sls_service_clean }}

{#- This can lead to data loss, so hide it behind a switch #}

{%- if nginx.webroots and nginx.lookup.remove_all_data_for_sure %}
{%-   set webroots = nginx.webroots %}
{%-   if nginx.webroots == "from_servers" %}
{%-     set webroots = [] %}
{%-     for server in nginx.servers %}
{%-       do webroots.append(nginx.lookup.webroot | path_join(server)) %}
{%-     endfor %}
{%-   elif nginx.webroots == "from_certbot" %}
{%-     set webroots = [] %}
{%-     from "certbot/map.jinja" import mapdata as certbot with context %}
{%-     for cert in certbot.certs %}
{%-       do webroots.append(nginx.lookup.webroot | path_join(cert)) %}
{%-     endfor %}
{%-   endif %}
Specified nginx webroot paths are absent:
  file.absent:
    - names: {{ webroots | json }}
    - require:
      - sls: {{ sls_service_clean }}
{%- endif %}
