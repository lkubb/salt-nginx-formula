# vim: ft=sls

{#-
    Generates certificates for servers that have ``certs`` set.
    Also generates Diffie-Hellman key exchange parameters, if requested.
    This is discouraged.
    Has a dependency on `nginx.config`_.
#}

include:
  - .managed
  - .dhparam
