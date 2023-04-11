# vim: ft=sls

{#-
    Generates Diffie-Hellman key exchange parameters, if requested.
    This is discouraged.
    Has a dependency on `nginx.config`_.
#}

include:
  - .dhparam
