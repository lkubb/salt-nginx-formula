# vim: ft=sls

{#-
    *Meta-state*.

    Undoes everything performed in the ``nginx`` meta-state
    in reverse order, i.e.
    removes managed server configurations,
    stops the service,
    removes webroots if ``nginx.lookup.remove_all_data_for_sure`` is True,
    removes snippets, the configuration file and possibly
    generated DH params and then uninstalls the package.
#}

include:
  - .servers.clean
  - .service.clean
  - .webroots.clean
  - .snippets.clean
  - .config.clean
  - .certs.clean
  - .package.clean
