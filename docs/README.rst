.. _readme:

Nginx Formula
=============

|img_sr| |img_pc|

.. |img_sr| image:: https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg
   :alt: Semantic Release
   :scale: 100%
   :target: https://github.com/semantic-release/semantic-release
.. |img_pc| image:: https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white
   :alt: pre-commit
   :scale: 100%
   :target: https://github.com/pre-commit/pre-commit

Manage Nginx with Salt.

.. contents:: **Table of Contents**
   :depth: 1

General notes
-------------

See the full `SaltStack Formulas installation and usage instructions
<https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

If you are interested in writing or contributing to formulas, please pay attention to the `Writing Formula Section
<https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html#writing-formulas>`_.

If you want to use this formula, please pay attention to the ``FORMULA`` file and/or ``git tag``,
which contains the currently released version. This formula is versioned according to `Semantic Versioning <http://semver.org/>`_.

See `Formula Versioning Section <https://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html#versioning>`_ for more details.

If you need (non-default) configuration, please refer to:

- `how to configure the formula with map.jinja <map.jinja.rst>`_
- the ``pillar.example`` file
- the `Special notes`_ section

Special notes
-------------


Configuration
-------------
An example pillar is provided, please see `pillar.example`. Note that you do not need to specify everything by pillar. Often, it's much easier and less resource-heavy to use the ``parameters/<grain>/<value>.yaml`` files for non-sensitive settings. The underlying logic is explained in `map.jinja`.


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
Generates Diffie-Hellman key exchange parameters, if requested.
This is discouraged.
Has a dependency on `nginx.config`_.


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
Removes generated DH parameters.
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



Contributing to this repo
-------------------------

Commit messages
^^^^^^^^^^^^^^^

**Commit message formatting is significant!**

Please see `How to contribute <https://github.com/saltstack-formulas/.github/blob/master/CONTRIBUTING.rst>`_ for more details.

pre-commit
^^^^^^^^^^

`pre-commit <https://pre-commit.com/>`_ is configured for this formula, which you may optionally use to ease the steps involved in submitting your changes.
First install  the ``pre-commit`` package manager using the appropriate `method <https://pre-commit.com/#installation>`_, then run ``bin/install-hooks`` and
now ``pre-commit`` will run automatically on each ``git commit``. ::

  $ bin/install-hooks
  pre-commit installed at .git/hooks/pre-commit
  pre-commit installed at .git/hooks/commit-msg

State documentation
~~~~~~~~~~~~~~~~~~~
There is a script that semi-autodocuments available states: ``bin/slsdoc``.

If a ``.sls`` file begins with a Jinja comment, it will dump that into the docs. It can be configured differently depending on the formula. See the script source code for details currently.

This means if you feel a state should be documented, make sure to write a comment explaining it.

Testing
-------

Linux testing is done with ``kitchen-salt``.

Requirements
^^^^^^^^^^^^

* Ruby
* Docker

.. code-block:: bash

   $ gem install bundler
   $ bundle install
   $ bin/kitchen test [platform]

Where ``[platform]`` is the platform name defined in ``kitchen.yml``,
e.g. ``debian-9-2019-2-py3``.

``bin/kitchen converge``
^^^^^^^^^^^^^^^^^^^^^^^^

Creates the docker instance and runs the ``nginx`` main state, ready for testing.

``bin/kitchen verify``
^^^^^^^^^^^^^^^^^^^^^^

Runs the ``inspec`` tests on the actual instance.

``bin/kitchen destroy``
^^^^^^^^^^^^^^^^^^^^^^^

Removes the docker instance.

``bin/kitchen test``
^^^^^^^^^^^^^^^^^^^^

Runs all of the stages above in one go: i.e. ``destroy`` + ``converge`` + ``verify`` + ``destroy``.

``bin/kitchen login``
^^^^^^^^^^^^^^^^^^^^^

Gives you SSH access to the instance for manual testing.
