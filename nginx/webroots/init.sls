# vim: ft=sls

{#-
    Ensures configured webroot directories are present.
    Has a dependency on `nginx.package`_.
#}

include:
  - .present
