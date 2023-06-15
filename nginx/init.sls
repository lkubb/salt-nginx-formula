# vim: ft=sls

{#-
    *Meta-state*.

    This installs the nginx package and possibly repository,
    manages the nginx configuration file
    plus snippets, manages webroot dirs,
    generates DH params if requested (discouraged),
    starts the associated nginx service
    and manages server configurations.
#}

include:
  - .package
  - .certs
  - .config
  - .snippets
  - .webroots
  - .service
  - .servers
