"""
``nginx`` Salt State Module
==========================

Manage nginx sites.
"""

# import logging
import salt.exceptions

import salt.utils.path

# log = logging.getLogger(__name__)

__virtualname__ = "nginx"


def __virtual__():
    # This could also be done with a check for the execution module,
    # e.g. if "nginx.default_config_file" in __salt__
    if salt.utils.path.which("nginx"):
        return True
    return False


def site_enabled(name, nginx_conf=None, sites_enabled=None, now=True):
    """
    Make sure a site configuration file is loaded by nginx.
    If the configuration uses the sites_enabled pattern (default on
    Debian and derivatives), symlink it in ``sites-enabled``.
    If the configuration uses ``conf.d``, rename it
    to have ``.conf`` extension instead of ``.disabled``.

    name
        The name of the configuration file for the site, without the extension.

    nginx_conf
        Path to the top configuration file that includes other files.
        Defaults to the default one used by nginx on the system.

    sites_enabled
        Force a specific pattern by setting this parameter. Otherwise,
        it will be autodetected.

    now
        Reload the nginx configuration to apply changes immediately.
        Defaults to True.
        This is a best effort and will not cause this state to fail,
        e.g. when nginx is not running.
    """

    ret = {"name": name, "result": True, "comment": "", "changes": {}}

    try:
        needs_reload = not __salt__["nginx.site_enabled"](
            name, nginx_conf, sites_enabled
        )

        if not needs_reload:
            ret["comment"] = "Site is already enabled."
        elif not __salt__["nginx.site_exists"](name, nginx_conf, sites_enabled):
            ret["result"] = False
            ret["comment"] = "A site named '{}' does not exist.".format(name)
        elif __opts__["test"]:
            if not __salt__["nginx.enable_site"](name, nginx_conf, sites_enabled):
                ret["result"] = False
                ret[
                    "comment"
                ] = "Tried to enable site '{}', but the resulting configuration was invalid or did not contain it.".format(
                    name
                )
            else:
                ret["result"] = None
                ret["comment"] = "Site '{}' would have been enabled.".format(name)
                ret["changes"] = {"enabled": name}
            __salt__["nginx.disable_site"](name, nginx_conf, sites_enabled)
        elif __salt__["nginx.enable_site"](name, nginx_conf, sites_enabled):
            ret["comment"] = "Site '{}' has been enabled.".format(name)
            ret["changes"] = {"enabled": name}
        else:
            ret["result"] = False
            ret[
                "comment"
            ] = "Could not enable site '{}'. Make sure it is valid.".format(name)
    except salt.exceptions.CommandExecutionError as e:
        ret["result"] = False
        ret["comment"] = str(e)
        return ret

    if now and needs_reload and ret["result"] != False:
        if __opts__["test"]:
            ret["comment"] += "\nWould have reloaded nginx configuration."
        else:
            try:
                __salt__["nginx.signal"]("reload")
                ret["comment"] += "\nReloaded nginx configuration."
            except CommandExecutionError as e:
                # This is e.g. caused by missing nginx process.
                ret[
                    "comment"
                ] += "\nFailed to reload nginx configuration though:\n\n{}".format(e)

    return ret


def site_disabled(name, nginx_conf=None, sites_enabled=None, now=True):
    """
    Make sure a site configuration file is not loaded by nginx.
    If the configuration uses the sites_enabled pattern (default on
    Debian and derivatives), symlink it in ``sites-enabled``.
    If the configuration uses ``conf.d``, rename it
    to have ``.conf`` extension instead of ``.disabled``.

    name
        The name of the configuration file for the site, without the extension.

    nginx_conf
        Path to the top configuration file that includes other files.
        Defaults to the default one used by nginx on the system.

    sites_enabled
        Force a specific pattern by setting this parameter. Otherwise,
        it will be autodetected.

    now
        Reload the nginx configuration to apply changes immediately.
        Defaults to True.
        This is a best effort and will not cause this state to fail,
        e.g. when nginx is not running.
    """

    ret = {"name": name, "result": True, "comment": "", "changes": {}}

    try:
        needs_reload = __salt__["nginx.site_enabled"](name, nginx_conf, sites_enabled)

        if not needs_reload:
            ret["comment"] = "Site is already disabled."
        elif __opts__["test"]:
            ret["result"] = None
            ret["comment"] = "Site '{}' would have been disabled.".format(name)
            ret["changes"] = {"disabled": name}
        elif __salt__["nginx.disable_site"](name, nginx_conf, sites_enabled):
            ret["comment"] = "Site '{}' has been disabled.".format(name)
            ret["changes"] = {"disabled": name}
            if not __salt__["nginx.configtest"](nginx_conf)["result"]:
                __salt__["nginx.enable_site"](name, nginx_conf, sites_enabled)
                ret["result"] = False
                ret["changes"] = {}
                ret[
                    "comment"
                ] = "Disabled site '{}', but the resulting config had errors. Reverted changes.".format(
                    name
                )
        else:
            ret["result"] = False
            ret["comment"] = "Something went wrong while calling nginx."
    except salt.exceptions.CommandExecutionError as e:
        ret["result"] = False
        ret["comment"] = str(e)
        # return early to avoid UnboundLocalError for needs_reload in some cases
        return ret

    if now and needs_reload and ret["result"] != False:
        if __opts__["test"]:
            ret["comment"] += "\nWould have reloaded nginx configuration."
        else:
            try:
                __salt__["nginx.signal"]("reload")
                ret["comment"] += "\nReloaded nginx configuration."
            except CommandExecutionError as e:
                # This is e.g. caused by missing nginx process.
                ret[
                    "comment"
                ] += "\nFailed to reload nginx configuration though:\n\n{}".format(e)

    return ret


def site(
    name,
    nginx_conf=None,
    sites_enabled=None,
    source=None,
    template=None,
    context=None,
    enabled=True,
    now=True,
):
    """
    Manage a site served by nginx. This is currently a wrapper for other
    states to make the configuration more concise.

    1. ``file.managed``, if requested.
       Presets are user=root, group=user.primary_group("root"), mode="0644", makedirs=False
    2. ``nginx.site_[en/dis]abled``

    @TODO: Allow defining the site file, possible using ``crossplane``.

    name
        The name of the configuration file for the site, without the extension and absolute path.

    nginx_conf
        Path to the top configuration file that includes other files.
        Defaults to the default one used by nginx on the system.

    sites_enabled
        Force a specific pattern by setting this parameter. Otherwise,
        it will be autodetected.

    source
        A (list of) URI for file.managed that defines the configuration.
        They should point to the file server since source_hash
        and skip_verify are unset.

    template
        Behaves like file.managed. E.g. set to ``jinja`` to enable templating.

    context
        A mapping of variable names to values used by the template.

    enabled
        Enable loading the site on nginx startup. Defaults to True.

    now
        Reload the nginx configuration to apply changes immediately.
        Defaults to True.
        This is a best effort and will not cause this state to fail,
        e.g. when nginx is not running.
    """

    # https://docs.saltproject.io/en/latest/ref/states/writing.html#sub-state-runs
    ret = {
        "name": name,
        "result": True,
        "comment": "",
        "changes": {},
        "sub_state_run": [],
    }

    # nginx.configtest was inherited from the Salt module and
    # already returns a ret dict
    if not __salt__["nginx.configtest"](nginx_conf)["result"]:
        ret["result"] = False
        ret[
            "comment"
        ] = "Your configuration is currently invalid. Managing sites is only possible based on a clean state. Please fix your configuration."
        return ret

    site_file, enable_file = __utils__["nginx.get_site_enable_files"](
        name, nginx_conf, sites_enabled
    )

    # Disable site temporarily without reloading configuration to make
    # sure calls to the execution module succeed, even if the new file
    # contains errors. This is necessitated by it needing a correct config
    # file to be able to list enabled ones.
    had_to_disable = False
    if __salt__["nginx.site_exists"](
        name, nginx_conf=nginx_conf, sites_enabled=sites_enabled
    ) and __salt__["nginx.site_enabled"](
        name, nginx_conf=nginx_conf, sites_enabled=sites_enabled
    ):
        ret_site_state = __states__["nginx.site_disabled"](
            name,
            nginx_conf=nginx_conf,
            sites_enabled=sites_enabled,
        )
        had_to_disable = True

        # The site will not be disabled when run with test=true, therefore
        # to check changes to the actual file for conf.d pattern, we need
        # to adjust the target.
        if __opts__["test"] and not __utils__["nginx.uses_sites_enabled"](nginx_conf):
            site_file = enable_file

    if source is not None:
        # https://docs.saltproject.io/en/latest/ref/states/writing.html#cross-calling-state-modules
        ret_file = __states__["file.managed"](
            str(site_file),
            source=source,
            template=template,
            context=context,
            user="root",
            group=__salt__["user.primary_group"]("root"),
            mode="0644",
        )
        ret_file["low"] = {
            "name": str(site_file),
            "state": "file",
            "__id__": __low__["__id__"],
            "fun": "managed",
        }
        ret["sub_state_run"].append(ret_file)

        if False == ret_file["result"]:
            ret["result"] = False
            return ret

    if had_to_disable and enabled and not __opts__["test"]:
        ret_reenable_after_changes = __states__["nginx.site_enabled"](
            name, nginx_conf=nginx_conf, sites_enabled=sites_enabled
        )

        if not ret_reenable_after_changes["result"]:
            ret["result"] = False
            ret["comment"] = (
                "The new configuration contained errors. Changes have been reverted.\n\n"
                + ret_reenable_after_changes["comment"]
            )
            ret["changes"] = {}
            ret["sub_state_run"] = []

            __salt__["file.restore_backup"](str(site_file), 0)
            # Since we checked before running anything, this has to succeed.
            __states__["nginx.site_enabled"](
                name, nginx_conf=nginx_conf, sites_enabled=sites_enabled
            )

            return ret

    site_state = site_enabled if enabled else site_disabled

    ret_site_state = site_state(name, nginx_conf, sites_enabled, now)
    ret_site_state["low"] = {
        "name": name,
        "state": "nginx",
        "__id__": __low__["__id__"],
        "fun": "site_enabled",
    }

    ret["sub_state_run"].append(ret_site_state)

    if False == ret_site_state["result"]:
        ret["result"] = False
        ret[
            "comment"
        ] = "Site configuration file {} in correct state, but could not {} it. Make sure there are no errors in your nginx configuration. Output was:\n\n{}".format(
            "would be" if __opts__["test"] else "is",
            "enable" if enabled else "disable",
            ret_site_state["comment"],
        )
        if __opts__["test"]:
            if not site_file.exists():
                ret[
                    "comment"
                ] += "\n\nYou can probably ignore this since the file would have been created if we were not running with test=true."
            else:
                ret[
                    "comment"
                ] += "\n\nIf you fixed some configuration errors since the last non-test run, you can probably ignore this warning."
        return ret

    # ret["comment"] += "\n\n" + ret_site_state["comment"]
    # ret["changes"].update(ret_site_state["changes"])
    return ret


def site_absent(name, nginx_conf=None, sites_enabled=None, now=True):
    """
    Make sure a site is not served by nginx and its configuration file is absent.
    If you just want to disable it, use ``nginx.site_disabled``.

    name
        The name of the configuration file for the site, without the extension and absolute path.

    nginx_conf
        Path to the top configuration file that includes other files.
        Defaults to the default one used by nginx on the system.

    sites_enabled
        Force a specific pattern by setting this parameter. Otherwise,
        it will be autodetected.

    now
        Reload the nginx configuration to apply changes immediately.
        Defaults to True.
        This is a best effort and will not cause this state to fail,
        e.g. when nginx is not running.
    """

    ret = {"name": name, "result": True, "comment": "", "changes": {}}

    try:
        needs_reload = __salt__["nginx.site_enabled"](name, nginx_conf, sites_enabled)

        if not __salt__["nginx.site_exists"](name, nginx_conf, sites_enabled):
            ret["comment"] = "Site {} is already absent.".format(name)
        elif __opts__["test"]:
            ret["result"] = None
            ret["comment"] = "Site {} would have been removed.".format(name)
            ret["changes"] = {"removed": name}
        elif __salt__["nginx.remove_site"](name, nginx_conf, sites_enabled):
            ret["comment"] = "Site {} has been removed".format(name)
            ret["changes"] = {"removed": name}
        else:
            ret["result"] = False
            ret["comment"] = "Something went wrong while calling nginx."
    except salt.exceptions.CommandExecutionError as e:
        ret["result"] = False
        ret["comment"] = str(e)
        return ret

    if now and needs_reload and ret["result"] != False:
        if __opts__["test"]:
            ret["comment"] += "\n\nWould have reloaded nginx configuration."
        else:
            try:
                __salt__["nginx.signal"]("reload")
                ret["comment"] += "\n\nReloaded nginx configuration."
            except CommandExecutionError as e:
                # This is e.g. caused by missing nginx master process.
                ret[
                    "comment"
                ] += "\nFailed to reload nginx configuration though, is it running?\n\n{}".format(
                    e
                )

    return ret
