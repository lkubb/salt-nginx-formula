"""
Support for nginx
"""

from pathlib import Path
import re
import urllib.request

import salt.utils.decorators as decorators
import salt.utils.path

from salt.exceptions import CommandExecutionError

try:
    import crossplane

    HAS_CROSSPLANE = True
except ImportError:
    HAS_CROSSPLANE = False


# Cache the output of running which('nginx') so this module
# doesn't needlessly walk $PATH looking for the same binary
# for nginx over and over and over for each function herein
@decorators.memoize
def __detect_os():
    return salt.utils.path.which("nginx")


def __virtual__():
    """
    Only load the module if nginx is installed
    """
    if __detect_os():
        return True
    return (
        False,
        "The nginx execution module cannot be loaded: nginx is not installed.",
    )


def _nginx_test_full(nginx_conf=None, refresh=False):
    """
    Helper function which leverages __context__ to keep from running
    ``nginx -T`` more than once if unnecessary.
    This prevents nginx from checking OCSP stapling servers every
    time this is run, which is _a lot_ (DNS request as well).
    Make sure to call this with refresh after something about the
    configuration has changed.
    """

    contextkey = f"nginx._nginx_test.{nginx_conf}"

    if contextkey not in __context__ or refresh:
        cmd = [__detect_os(), "-T"]
        if nginx_conf is not None:
            cmd.extend(["-c", "'{}'".format(str(nginx_conf))])

        out = __salt__["cmd.run_all"](" ".join(cmd))
        if out["retcode"]:
            raise CommandExecutionError(
                "Error running nginx. Output:\n\n{}".format(out["stderr"])
            )

        __context__[contextkey] = out["stdout"]

    return __context__[contextkey]


def version():
    """
    Return server version from nginx -v

    CLI Example:

    .. code-block:: bash

        salt '*' nginx.version
    """
    cmd = "{} -v".format(__detect_os())
    out = __salt__["cmd.run"](cmd).splitlines()
    ret = out[0].rsplit("/", maxsplit=1)
    return ret[-1]


def build_info():
    """
    Return server and build arguments

    CLI Example:

    .. code-block:: bash

        salt '*' nginx.build_info
    """
    ret = {"info": []}
    out = __salt__["cmd.run"]("{} -V".format(__detect_os()))

    for i in out.splitlines():
        if i.startswith("configure argument"):
            ret["build arguments"] = re.findall(r"(?:[^\s]*'.*')|(?:[^\s]+)", i)[2:]
            continue

        ret["info"].append(i)

    return ret


def configtest(nginx_conf=None):
    """
    test configuration and exit

    CLI Example:

    .. code-block:: bash

        salt '*' nginx.configtest

    nginx_conf
        Path to the top configuration file that includes other files.
        Defaults to nginx default.
    """
    ret = {}

    cmd = [__detect_os(), "-t"]

    if nginx_conf:
        cmd.extend(["-c", "'{}'".format(nginx_conf)])

    out = __salt__["cmd.run_all"](" ".join(cmd))

    if out["retcode"] != 0:
        ret["comment"] = "Syntax Error"
        ret["stderr"] = out["stderr"]
        ret["result"] = False

        return ret

    ret["comment"] = "Syntax OK"
    ret["stdout"] = out["stderr"]
    ret["result"] = True

    return ret


def default_config_dir():
    """
    Return the path of the default configuration directory.

    CLI Example:

    .. code-block:: bash

        salt '*' nginx.default_config_dir
    """

    confd = __utils__["nginx.default_config_dir"]()

    if confd:
        return str(confd)
    raise CommandExecutionError(
        "Could not find the default configuration dir for nginx."
    )


def default_config_file():
    """
    Return the path of the default configuration file.

    CLI Example:

    .. code-block:: bash

        salt '*' nginx.default_config_file
    """

    # This could have been achieved with list_config_files()[0].

    file = __utils__["nginx.default_config_file"]()

    if file:
        return str(file)
    raise CommandExecutionError(
        "Could not find the default configuration file for nginx."
    )


def disable_site(name, nginx_conf=None, sites_enabled=None):
    """
    Disable a site configuration file.
    If the configuration uses the sites_enabled pattern (default on
    Debian and derivatives), remove symlink in ``sites-enabled``.
    If the configuration uses ``conf.d``, rename it
    to have ``.disabled`` extension instead of ``.conf``.

    CLI Example:

    .. code-block:: bash

        salt '*' nginx.disable_site example.com

    name
        Name of the site configuration file (without file extension)

    nginx_conf
        Path to the top configuration file that includes other files.
        Defaults to nginx default.

    sites_enabled
        Force a specific pattern by setting this parameter. Otherwise,
        it will be autodetected.
    """

    if nginx_conf is None:
        nginx_conf = default_config_file()

    if sites_enabled is None:
        sites_enabled = __utils__["nginx.uses_sites_enabled"](nginx_conf)

    site_file, enable_file = __utils__["nginx.get_site_enable_files"](
        name, nginx_conf, sites_enabled
    )

    if not(site_file.exists() or not sites_enabled and enable_file.exists()):
        raise CommandExecutionError("There is no site named {}.".format(name))

    # If an enabled site causes errors, listing all config files will be
    # impossible and throw an exception. To be able to disable a faulty
    # site config, catch that error.
    try:
        if str(enable_file) not in list_config_files(nginx_conf):
            return True
    except CommandExecutionError as e:
        if str(enable_file) not in str(e):
            raise e

    try:
        if sites_enabled and enable_file.is_symlink():
            enable_file.unlink()
        elif not sites_enabled:
            enable_file.rename(site_file)
    except PermissionError as e:
        raise CommandExecutionError(
            "Enabling site failed, permission denied:\n\n{}".format(e)
        )

    return str(enable_file) not in list_config_files(nginx_conf, refresh=True)


def enable_site(name, nginx_conf=None, sites_enabled=None):
    """
    Enable a site configuration file.
    If the configuration uses the sites_enabled pattern (default on
    Debian and derivatives), symlink it in ``sites-enabled``.
    If the configuration uses ``conf.d``, rename it
    to have ``.conf`` extension instead of ``.disabled``.

    CLI Example:

    .. code-block:: bash

        salt '*' nginx.enable_site example.com

    name
        Name of the site configuration file (without file extension)

    nginx_conf
        Path to the top configuration file that includes other files.
        Defaults to nginx default.

    sites_enabled
        Force a specific pattern by setting this parameter. Otherwise,
        it will be autodetected.
    """

    if nginx_conf is None:
        nginx_conf = default_config_file()

    if sites_enabled is None:
        sites_enabled = __utils__["nginx.uses_sites_enabled"](nginx_conf)

    site_file, enable_file = __utils__["nginx.get_site_enable_files"](
        name, nginx_conf, sites_enabled
    )

    if str(enable_file) in list_config_files(nginx_conf):
        return True

    if not site_file.exists():
        raise CommandExecutionError(
            "Could not find site configuration file '{}'.".format(str(site_file))
        )

    if sites_enabled:
        enable_command = enable_file.symlink_to
        target = site_file
    else:
        enable_command = site_file.rename
        target = enable_file

    try:
        enable_command(target)
    except PermissionError as e:
        raise CommandExecutionError(
            "Enabling site failed, permission denied:\n\n{}".format(e)
        )

    try:
        return str(enable_file) in list_config_files(nginx_conf, refresh=True)
    except CommandExecutionError as e:
        # We caused that error with enabling the file since above, it was working. Disable it.
        disable_site(name, nginx_conf, sites_enabled)
        return False


def list_config_files(nginx_conf=None, refresh=False):
    """
    Return a list of all active configuration files. This list is correct
    for a reloaded nginx and might be out of sync if the files have changed
    after starting the service.
    This also only works if the current configuration is valid.

    CLI Example:

    .. code-block:: bash

        salt '*' nginx.list_config_files

    nginx_conf
        Path to the top configuration file that includes other files.
        Defaults to nginx default.
    """

    out = _nginx_test_full(nginx_conf, refresh)

    return re.findall(r"^# configuration file (.*):", out, re.MULTILINE)


def remove_site(name, nginx_conf=None, sites_enabled=None):
    """
    Delete a site configuration file.

    CLI Example:

    .. code-block:: bash

        salt '*' nginx.remove_site example.com

    name
        Name of the site configuration file (without file extension)

    nginx_conf
        Path to the top configuration file that includes other files.
        Defaults to nginx default.

    sites_enabled
        Force a specific pattern by setting this parameter. Otherwise,
        it will be autodetected.
    """

    if nginx_conf is None:
        nginx_conf = default_config_file()

    if sites_enabled is None:
        sites_enabled = __utils__["nginx.uses_sites_enabled"](nginx_conf)

    if not disable_site(name, nginx_conf, sites_enabled):
        raise CommandExecutionError(
            "Could not disable the configuration for {}.".format(name)
        )

    site_file, _ = __utils__["nginx.get_site_enable_files"](
        name, nginx_conf, sites_enabled
    )

    if site_file.exists():
        try:
            site_file.unlink()
        except PermissionError as e:
            raise CommandExecutionError(
                "Removing site failed, permission denied:\n\n{}".format(e)
            )

    return True


def signal(signal=None):
    """
    Signals nginx to start, reload, reopen or stop.

    CLI Example:

    .. code-block:: bash

        salt '*' nginx.signal reload
    """
    valid_signals = ("start", "reopen", "stop", "quit", "reload")

    if signal not in valid_signals:
        raise CommandExecutionError("Signal '{}' is invalid.".format(signal))

    # Make sure you use the right arguments
    if signal == "start":
        arguments = ""
    else:
        arguments = " -s {}".format(signal)
    cmd = __detect_os() + arguments
    out = __salt__["cmd.run_all"](cmd)

    # A non-zero return code means fail
    if out["retcode"]:
        raise CommandExecutionError(
            "Failed signaling '{}' to nginx:\n\n{}".format(signal, out["stderr"])
        )

    return True


def site_enabled(name, nginx_conf=None, sites_enabled=None):
    """
    Check whether a site configuration file gets loaded by nginx
    during startup.

    CLI Example:

    .. code-block:: bash

        salt '*' nginx.site_enabled example.com

    name
        Name of the site configuration file (without file extension)

    nginx_conf
        Path to the top configuration file that includes other files.
        Defaults to nginx default.

    sites_enabled
        Force a specific pattern by setting this parameter. Otherwise,
        it will be autodetected.
    """

    if nginx_conf is None:
        nginx_conf = default_config_file()

    _, enable_file = __utils__["nginx.get_site_enable_files"](
        name, nginx_conf, sites_enabled
    )

    # If a site is enabled and its file causes errors, it will be listed
    # in stderr. This is needed to be able to remove a file again.
    try:
        return str(enable_file) in list_config_files(nginx_conf)
    except CommandExecutionError as e:
        if str(enable_file) in str(e):
            return True
        raise e


def site_exists(name, nginx_conf=None, sites_enabled=None):
    """
    Check whether a site configuration file gets loaded by nginx
    during startup.

    CLI Example:

    .. code-block:: bash

        salt '*' nginx.default_config_dir

    name
        Name of the site configuration file (without file extension)

    nginx_conf
        Path to the top configuration file that includes other files.
        Defaults to nginx default.

    sites_enabled
        Force a specific pattern by setting this parameter. Otherwise,
        it will be autodetected.
    """

    if nginx_conf is None:
        nginx_conf = default_config_file()

    if sites_enabled is None:
        sites_enabled = __utils__["nginx.uses_sites_enabled"](nginx_conf)

    site_file, enable_file = __utils__["nginx.get_site_enable_files"](
        name, nginx_conf, sites_enabled
    )

    if sites_enabled:
        return site_file.exists()

    return site_file.exists() or enable_file.exists()


def status(url="http://127.0.0.1/status"):
    """
    Return the data from an Nginx status page as a dictionary.
    http://wiki.nginx.org/HttpStubStatusModule

    url
        The URL of the status page. Defaults to 'http://127.0.0.1/status'

    CLI Example:

    .. code-block:: bash

        salt '*' nginx.status
    """
    resp = urllib.request.urlopen(url)
    status_data = resp.read()
    resp.close()

    lines = status_data.splitlines()
    if not len(lines) == 4:
        return
    # "Active connections: 1 "
    active_connections = lines[0].split()[2]
    # "server accepts handled requests"
    # "  12 12 9 "
    accepted, handled, requests = lines[2].split()
    # "Reading: 0 Writing: 1 Waiting: 0 "
    _, reading, _, writing, _, waiting = lines[3].split()
    return {
        "active connections": int(active_connections),
        "accepted": int(accepted),
        "handled": int(handled),
        "requests": int(requests),
        "reading": int(reading),
        "writing": int(writing),
        "waiting": int(waiting),
    }
