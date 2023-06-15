# vim: ft=sls

{#-
    This state will install the configured nginx repository.
    This works for apt/dnf/yum/zypper-based distributions only by default.
#}

{%- set tplroot = tpldir.split("/")[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

include:
{%- if nginx.lookup.pkg_manager in ["apt", "dnf", "yum", "zypper"] %}
  - {{ slsdotpath }}.install
{%- elif salt["state.sls_exists"](slsdotpath ~ "." ~ nginx.lookup.pkg_manager) %}
  - {{ slsdotpath }}.{{ nginx.lookup.pkg_manager }}
{%- else %}
  []
{%- endif %}
