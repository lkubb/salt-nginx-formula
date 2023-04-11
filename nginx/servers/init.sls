# vim: ft=sls

{#-
    Manages server configurations and their state (enabled/disabled).
    Has a dependency on `nginx.service`_.
#}

include:
  - .manage
