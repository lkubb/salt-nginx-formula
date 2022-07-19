# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{%- set sls_package_install = tplroot ~ '.package.install' %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

include:
  - {{ sls_package_install }}

{%- if nginx.webroots %}
{%-   set webroots = nginx.webroots %}
{%-   if "from_servers" == nginx.webroots %}
{%-     set webroots = [] %}
{%-     for server in nginx.servers %}
{%-       do webroots.append(nginx.lookup.webroot | path_join(server)) %}
{%-     endfor %}
{%-   elif "from_certbot" == nginx.webroots %}
{%-     set webroots = [] %}
{%-     from "certbot/map.jinja" import mapdata as certbot with context %}
{%-     for cert in certbot.certs %}
{%-       do webroots.append(nginx.lookup.webroot | path_join(cert)) %}
{%-     endfor %}
{%-   endif %}
Specified nginx webroot paths are present:
  file.directory:
    - names: {{ webroots | json }}
    - user: {{ nginx.lookup.user }}
    - group: {{ nginx.lookup.group }}
    - makedirs: true
    - require:
      - sls: {{ sls_package_install }}
{%- endif %}
