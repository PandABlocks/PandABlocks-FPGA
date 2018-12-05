# This script installs files into the extensions directory

import sys
import os.path
import shutil
import fnmatch

from .compat import configparser
from .ini_util import read_ini


def get_modules(ini):
    for section in ini.sections():
        if section != '.':
            try:
                module_name = ini.get(section, "module")
            except configparser.NoOptionError:
                module_name = section.lower()
            yield(module_name)

def main():
    top = sys.argv[1]
    app_file = sys.argv[2]
    extensions = sys.argv[3]

    ini = read_ini(app_file)
    for module in get_modules(ini):
        ext_dir = os.path.join(top, 'modules', module, 'extensions')
        if os.path.isdir(ext_dir):
            for filename in fnmatch.filter(os.listdir(ext_dir), '*.py'):
                shutil.copyfile(
                    os.path.join(ext_dir, filename),
                    os.path.join(extensions, filename))


if __name__ == '__main__':
    main()

