from pathlib import Path
import re
import subprocess

import salt.utils.decorators as decorators
import salt.utils.path


# Cache the output of running which('nginx') so this module
# doesn't needlessly walk $PATH looking for the same binary
# for nginx over and over and over for each function herein
@decorators.memoize
def __detect_os():
    return salt.utils.path.which("nginx")


def default_config_dir():
    """
    Return the path of the default configuration directory.
    """

    file = default_config_file()

    if file:
        return file.parent
    return False


def default_config_file():
    """
    Return the path of the default configuration file.
    """

    cmd = [__detect_os(), '-t']

    # cannot use salt dunder in utils
    process = subprocess.Popen(cmd,
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)
    _, stderr = process.communicate()

    file = re.findall(r"nginx: configuration file (.*) test (?:failed|is successful)", stderr.decode())

    if file:
        return Path(file[0])
    return False


def get_site_enable_files(name, config=None, sites_enabled=None):
    """
    Return a tuple of (site_file, enable_file) for the specified
    nginx configuration (pathlib.Path objects). This takes into account the pattern
    for the configuration file (sites-available/sites-enabled vs conf.d).
    """

    if not config:
        config = default_config_file()
    else:
        config = Path(config)

    if sites_enabled is None:
        sites_enabled = uses_sites_enabled(config)

    base = config.parent

    if sites_enabled:
        enable_file = base / "sites-enabled" / name
        site_file = base / "sites-available" / name
    else:
        enable_file = base / "conf.d" / (name + ".conf")
        site_file = base / "conf.d" / (name + ".disabled")

    return site_file, enable_file


def uses_sites_enabled(config=None):
    """
    Check whether the nginx configuration uses the sites-available/sites-enabled pattern.
    If the file does not exist, returns False as well.
    """

    if not config:
        config = default_config_file()
    else:
        config = Path(config)

    if not config.exists():
        return False

    if re.findall(r"^[\s]+include (/etc/nginx/|)sites-enabled/\*;$", config.read_text(), re.MULTILINE):
        return True
    return False
