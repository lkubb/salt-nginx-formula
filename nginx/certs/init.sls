# vim: ft=sls

{#-
    Generates certificates for servers that have ``certs`` set.
    Also generates Diffie-Hellman key exchange parameters, if requested.
    This is discouraged.
    Has a dependency on `nginx.config`_.
#}
{%- set tplroot = tpldir.split("/")[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

include:
  - .managed
  - .dhparam
{%- if nginx.tls.generate_snakeoil %}
  - .snakeoil
{%- endif %}
