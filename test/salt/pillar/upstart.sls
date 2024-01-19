# vim: ft=yaml
---
nginx:
  lookup:
    master: template-master
    # Just for testing purposes
    winner: lookup
    added_in_lookup: lookup_value
    enablerepo:
      stable: true
    config: '/etc/nginx/nginx.conf'
    service:
      name: nginx
    certs: certs
    group: nginx
    groups_extra: []
    pid_file: /run/nginx.pid
    pkg:
      name: nginx
      openssl: openssl
    remove_all_data_for_sure: false
    snippets: snippets
    user: nginx
    webroot: /var/www
    workdir: /var/lib/nginx
  config:
    events:
      worker_connections: 768
    http:
      access_log: /var/log/nginx/access.log
      default_type: application/octet-stream
      error_log: /var/log/nginx/error.log
      gzip: 'on'
      include:
        - mime.types
        - conf.d/*.conf
        - sites-enabled/*
      sendfile: 'on'
      tcp_nopush: 'on'
      types_hash_max_size: 2048
    include:
      - modules-enabled/*.conf
    worker_processes: auto
  dhparam: {}
  disable_default_host: true
  install_method: pkg
  servers: {}
  session_ticket_key_rotation: false
  snippets: {}
  tls:
    ca_certs: {}
    cert_defaults:
      ca_server: null
      cn: null
      days_remaining: 7
      days_valid: 30
      intermediate: []
      root: ''
      san: []
      signing_cert: null
      signing_policy: null
      signing_private_key: null
      signing_private_key_passphrase: null
  webroots: []

  tofs:
    # The files_switch key serves as a selector for alternative
    # directories under the formula files directory. See TOFS pattern
    # doc for more info.
    # Note: Any value not evaluated by `config.get` will be used literally.
    # This can be used to set custom paths, as many levels deep as required.
    files_switch:
      - any/path/can/be/used/here
      - id
      - roles
      - osfinger
      - os
      - os_family
    # All aspects of path/file resolution are customisable using the options below.
    # This is unnecessary in most cases; there are sensible defaults.
    # Default path: salt://< path_prefix >/< dirs.files >/< dirs.default >
    #         I.e.: salt://nginx/files/default
    # path_prefix: template_alt
    # dirs:
    #   files: files_alt
    #   default: default_alt
    # The entries under `source_files` are prepended to the default source files
    # given for the state
    # source_files:
    #   nginx-config-file-file-managed:
    #     - 'example_alt.tmpl'
    #     - 'example_alt.tmpl.jinja'

    # For testing purposes
    source_files:
      nginx-config-file-file-managed:
        - 'example.tmpl.jinja'

  # Just for testing purposes
  winner: pillar
  added_in_pillar: pillar_value
