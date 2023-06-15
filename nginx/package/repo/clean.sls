# vim: ft=sls

{#-
    This state will remove the configured nginx repository.
    This works for apt/dnf/yum/zypper-based distributions only by default.
#}

{%- set tplroot = tpldir.split("/")[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}


{%- if nginx.lookup.pkg_manager not in ["apt", "dnf", "yum", "zypper"] %}
{%-   if salt["state.sls_exists"](slsdotpath ~ "." ~ nginx.lookup.pkg_manager ~ ".clean") %}

include:
  - {{ slsdotpath ~ "." ~ nginx.lookup.pkg_manager ~ ".clean" }}
{%-   endif %}

{%- else %}
{%-   for reponame, enabled in nginx.lookup.enablerepo.items() %}
{%-     if enabled %}

Nginx {{ reponame }} repository is absent:
  pkgrepo.absent:
{%-       for conf in ["name", "ppa", "ppa_auth", "keyid", "keyid_ppa", "copr"] %}
{%-         if conf in nginx.lookup.repos[reponame] %}
    - {{ conf }}: {{ nginx.lookup.repos[reponame][conf] }}
{%-         endif %}
{%-       endfor %}
{%-     endif %}
{%-   endfor %}
{%- endif %}
