# vim: ft=sls

{#-
    Manages Nginx snippets.
    Has a dependency on `nginx.package`_.
#}

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_package_install = tplroot ~ ".package.install" %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}
{%- from tplroot ~ "/libtofsstack.jinja" import files_switch with context %}

include:
  - {{ sls_package_install }}

Snippets directory exists:
  file.directory:
    - name: {{ nginx.lookup.snippets }}
    - makedirs: true
    - require:
      - sls: {{ sls_package_install }}

{%- if nginx.snippets %}

Nginx snippets are managed:
  file.managed:
    - names:
{%-   for name in nginx.snippets %}
      - {{ nginx.lookup.snippets | path_join(name ~ ".conf") }}:
        - source: {{ files_switch(
                        [name ~ ".conf", "snippet.conf.j2"],
                        config=nginx,
                        lookup="Nginx snippet " ~ name ~ " is managed",
                        indent_width=10
                     )
                  }}
        - context:
            snippet_name: {{ name }}
{%-   endfor %}
    - mode: '0644'
    - user: root
    - group: {{ nginx.lookup.rootgroup }}
    - makedirs: true
    - template: jinja
    - require:
      - file: {{ nginx.lookup.snippets }}
    - defaults:
        nginx: {{ nginx | json }}
{%- endif %}
