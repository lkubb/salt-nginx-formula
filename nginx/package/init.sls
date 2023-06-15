# vim: ft=sls

{#-
    Installs the nginx package only.
    If installation from repo is configured, will also
    configure the selected repo.
#}

include:
  - .install
