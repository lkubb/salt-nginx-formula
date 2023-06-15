Available states
----------------

The following states are found in this formula:

.. contents::
   :local:


``nginx``
^^^^^^^^^
*Meta-state*.

This installs the nginx package,
manages the nginx configuration file
plus snippets, manages webroot dirs,
generates DH params if requested (discouraged),
starts the associated nginx service
and manages server configurations.


``nginx.package``
^^^^^^^^^^^^^^^^^
Installs the nginx package only.


``nginx.certs``
^^^^^^^^^^^^^^^
Generates certificates for servers that have ``certs`` set.
Also generates Diffie-Hellman key exchange parameters, if requested.
This is discouraged.
Has a dependency on `nginx.config`_.


``nginx.certs.dhparam``
^^^^^^^^^^^^^^^^^^^^^^^



``nginx.certs.managed``
^^^^^^^^^^^^^^^^^^^^^^^



``nginx.config``
^^^^^^^^^^^^^^^^
Manages the nginx service configuration.
Has a dependency on `nginx.package`_.


``nginx.snippets``
^^^^^^^^^^^^^^^^^^
Manages Nginx snippets.
Has a dependency on `nginx.package`_.


``nginx.webroots``
^^^^^^^^^^^^^^^^^^
Ensures configured webroot directories are present.
Has a dependency on `nginx.package`_.


``nginx.service``
^^^^^^^^^^^^^^^^^
Starts the nginx service (and session key rotation service, if configured)
and enables it at boot time.
Has a dependency on `nginx.config`_.


``nginx.servers``
^^^^^^^^^^^^^^^^^
Manages server configurations and their state (enabled/disabled).
Has a dependency on `nginx.service`_.


``nginx.clean``
^^^^^^^^^^^^^^^
*Meta-state*.

Undoes everything performed in the ``nginx`` meta-state
in reverse order, i.e.
removes managed server configurations,
stops the service,
removes webroots if ``nginx.lookup.remove_all_data_for_sure`` is True,
removes snippets, the configuration file and possibly
generated DH params and then uninstalls the package.


``nginx.package.clean``
^^^^^^^^^^^^^^^^^^^^^^^
Removes the nginx package.
Has a dependency on `nginx.config.clean`_.


``nginx.certs.clean``
^^^^^^^^^^^^^^^^^^^^^
Removes generated certificates, private keys and DH parameters.
Has a dependency on `nginx.service.clean`_.


``nginx.config.clean``
^^^^^^^^^^^^^^^^^^^^^^
Removes the configuration of the nginx service and has a
dependency on `nginx.service.clean`_.


``nginx.snippets.clean``
^^^^^^^^^^^^^^^^^^^^^^^^
Removes all managed snippets.


``nginx.webroots.clean``
^^^^^^^^^^^^^^^^^^^^^^^^
Removes configured webroot directories if
``nginx.lookup.remove_all_data_for_sure`` is True.
Has a dependency on `nginx.service.clean`_.


``nginx.service.clean``
^^^^^^^^^^^^^^^^^^^^^^^
Stops the nginx service (and session key rotation service, if configured)
and disables it at boot time.


``nginx.servers.clean``
^^^^^^^^^^^^^^^^^^^^^^^
Removes all managed server configurations.


