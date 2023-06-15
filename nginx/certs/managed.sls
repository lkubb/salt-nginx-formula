# vim: ft=sls

{%- set tplroot = tpldir.split("/")[0] %}
{%- set sls_package_install = tplroot ~ ".package.install" %}
{%- from tplroot ~ "/map.jinja" import mapdata as nginx with context %}
{%- from tplroot ~ "/libtofsstack.jinja" import files_switch with context %}
{%- set user = nginx | traverse("lookup:user", "nginx") %}
{%- set group = nginx | traverse("lookup:group", "nginx") %}

include:
  - {{ sls_package_install }}

{%- set any_certs = [] %}
{%- for name, server_config in nginx.servers.items() %}
{%-   if not server_config.get("certs") %}
{%-     continue %}
{%-   endif %}
{%-   do any_certs.append(true) %}
{%-   for cert in (server_config.certs if server_config.certs | is_list else ([{}] if server_config.certs is true else [server_config.certs])) %}
{%-     set cert_name = cert.get("name", name) %}
{%-     set keyfile = nginx.lookup.certs | path_join(cert_name) ~ ".key" %}
{%-     set certfile = nginx.lookup.certs | path_join(cert_name) ~ ".pem" %}
{%-     set config = salt["defaults.merge"](nginx.tls.cert_defaults, cert, in_place=false) %}

Nginx {{ cert_name }} private key is managed:
  x509.private_key_managed:
    - name: {{ keyfile }}
    - algo: rsa
    - keysize: 2048
    - new: true
{%-     if salt["file.file_exists"](keyfile) %}
    - prereq:
      - Nginx {{ cert_name }} certificate is managed
{%-     endif %}
    - makedirs: true
    - user: {{ nginx.lookup.user }}
    - group: {{ nginx.lookup.group }}
    - require:
      - sls: {{ sls_package_install }}

Nginx {{ cert_name }} certificate is managed:
  x509.certificate_managed:
    - name: {{ certfile }}
    - ca_server: {{ config.ca_server or "null" }}
    - signing_policy: {{ config.signing_policy or "null" }}
    - signing_cert: {{ config.signing_cert or "null" }}
    - signing_private_key: {{ config.signing_private_key or (keyfile if not config.ca_server and not config.signing_cert else "null") }}
    - private_key: {{ keyfile }}
    - authorityKeyIdentifier: keyid:always
    - basicConstraints: critical, CA:false
    - subjectKeyIdentifier: hash
{%-     if config.san %}
    - subjectAltName:  {{ config.san | json }}
{%-     else %}
    - subjectAltName:
      - dns: {{ config.cn or ([grains.fqdn] + grains.fqdns) | reject("==", "localhost.localdomain") | first | d(grains.id) }}
      - ip: {{ (grains.get("ip4_interfaces", {}).get("eth0", [""]) | first) or (grains.get("ipv4") | reject("==", "127.0.0.1") | first) }}
{%-     endif %}
    - CN: {{ config.cn or grains.fqdns | reject("==", "localhost.localdomain") | first | d(grains.id) }}
    - mode: '0640'
    - user: {{ nginx.lookup.user }}
    - group: {{ nginx.lookup.group }}
    - makedirs: true
    - append_certs: {{ config.intermediate | json }}
    - days_remaining: {{ config.days_remaining }}
    - days_valid: {{ config.days_valid }}
    - require:
      - sls: {{ sls_package_install }}
{%-     if not salt["file.file_exists"](keyfile) %}
      - Nginx {{ cert_name }} private key is managed
{%-     endif %}
{%-   endfor %}
{%- endfor %}

{%- for ca_name, ca_cert in nginx.tls.ca_certs.items() %}

CA cert for {{ ca_name }} is managed:
  file.managed:
    - name: {{ nginx.lookup.certs | path_join("ca", ca_name) }}.pem
    - contents: {{ ((ca_cert | join("\n")) if ca_cert | is_list else ca_cert) | json }}
    - makedirs: true
    - require:
      - sls: {{ sls_package_install }}
{%- endfor %}

{%- if not any_certs or nginx.tls.ca_certs %}

Make Nginx certs file requirable:
  test.nop
{%- endif %}
