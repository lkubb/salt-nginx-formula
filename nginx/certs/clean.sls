# vim: ft=sls

{#-
    Removes generated certificates, private keys and DH parameters.
    Has a dependency on `nginx.service.clean`_.
#}

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_service_clean = tplroot ~ ".service.clean" %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

include:
  - {{ sls_service_clean }}

{%- set certfiles = [nginx.lookup.tls_dir | path_join("ca")] %}
{%- for name, server_config in nginx.servers.items() %}
{%-   if not server_config.get("certs") %}
{%-     continue %}
{%-   endif %}
{%-   for cert in (server_config.certs if server_config.certs | is_list else ([{}] if server_config.certs is true else [server_config.certs])) %}
{%-     set cert_name = cert.get("name", name) %}
{%-     do cert_files.append(nginx.lookup.tls_dir | path_join(cert_name) ~ ".key") %}
{%-     do cert_files.append(nginx.lookup.tls_dir | path_join(cert_name) ~ ".pem") %}
{%-   endfor %}
{%- endfor %}

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

{%- if certfiles %}

Nginx certs are absent:
  file.absent:
    - names: {{ certfiles | json }}
{%- endif %}
