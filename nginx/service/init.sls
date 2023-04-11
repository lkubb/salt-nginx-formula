# vim: ft=sls

{#-
    Starts the nginx service (and session key rotation service, if configured)
    and enables it at boot time.
    Has a dependency on `nginx.config`_.
#}

include:
  - .running
