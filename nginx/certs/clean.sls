# vim: ft=sls

{#-
    Removes generated DH parameters.
    Has a dependency on `nginx.service.clean`_.
#}

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_service_clean = tplroot ~ ".service.clean" %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

include:
  - {{ sls_service_clean }}

{%- if nginx.dhparam %}

DH params are absent:
  file.absent:
    - names:
{%-   for name in nginx.dhparam %}
      - {{ nginx.lookup.certs | path_join(name ~ ".pem") }}
{%-   endfor %}
    - require:
      - sls: {{ sls_service_clean }}
{%- endif %}
