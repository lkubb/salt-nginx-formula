# vim: ft=sls

{%- set tplroot = tpldir.split("/")[0] %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

# There is no need for python-apt anymore.

{%- for reponame, enabled in nginx.lookup.enablerepo.items() %}
{%-   if enabled %}

Nginx {{ reponame }} repository is available:
  pkgrepo.managed:
{%-     for conf, val in nginx.lookup.repos[reponame].items() %}
    - {{ conf }}: {{ val }}
{%-     endfor %}
{%-     if nginx.lookup.pkg_manager in ["dnf", "yum", "zypper"] %}
    - enabled: 1
{%-     endif %}
    - require_in:
      - Nginx is installed

{%-   else %}

Nginx {{ reponame }} repository is disabled:
  pkgrepo.absent:
{%-     for conf in ["name", "ppa", "ppa_auth", "keyid", "keyid_ppa", "copr"] %}
{%-       if conf in nginx.lookup.repos[reponame] %}
    - {{ conf }}: {{ nginx.lookup.repos[reponame][conf] }}
{%-       endif %}
{%-     endfor %}
    - require_in:
      - Nginx is installed
{%-   endif %}
{%- endfor %}
