# vim: ft=sls

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_package_install = tplroot ~ ".package.install" %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}

include:
  - {{ sls_package_install }}

{%- set key_file = nginx.lookup.certs | path_join("snakeoil.key") %}
{%- set cert_file = nginx.lookup.certs | path_join("snakeoil.pem") %}

Nginx snakeoil private key is managed:
  x509.private_key_managed:
    - name: {{ key_file }}
    - algo: rsa
    - keysize: 2048
    - new: true
{%- if salt["file.file_exists"](key_file) %}
    - prereq:
      - Nginx snakeoil certificate is managed
{%- endif %}
    - makedirs: true
    - user: root
    - group: {{ nginx.lookup.rootgroup }}
    - mode: '0640'
    - require:
      - sls: {{ sls_package_install }}

Nginx snakeoil certificate is managed:
  x509.certificate_managed:
    - name: {{ cert_file }}
    - signing_private_key: {{ key_file }}
    - private_key: {{ key_file }}
    - days_valid: 36500
    - authorityKeyIdentifier: keyid:always
    - basicConstraints: critical, CA:false
    - subjectKeyIdentifier: hash
    - subjectAltName:
      - dns: {{ grains.id }}
    - CN: {{ grains.id }}
    - mode: '0640'
    - user: root
    - group: {{ nginx.lookup.rootgroup }}
    - makedirs: true
    - require:
      - sls: {{ sls_package_install }}
{%- if not salt["file.file_exists"](key_file) %}
      - Nginx snakeoil private key is managed
{%- endif %}
