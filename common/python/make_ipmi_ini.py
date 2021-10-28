# This script installs the appropriate impi.ini file

import sys
import os.path
import shutil

from .compat import configparser
from .ini_util import read_ini, ini_get


fallback_ini = '''\
# No IPMI EEPROM expected
[.]
eeprom = ignore
'''

def get_modules(ini):
    for section in ini.sections():
        if section != '.':
            module_name = ini_get(ini, section, 'module', section.lower())
            yield module_name

def main():
    top = sys.argv[1]
    app_file = sys.argv[2]
    target = sys.argv[3]

    ini = read_ini(app_file)
    ini_found = None
    for module in get_modules(ini):
        ipmi_ini = os.path.join(top, 'modules', module, 'ipmi.ini')
        if os.path.isfile(ipmi_ini):
            if ini_found:
                # We can end up visiting the same module more than once
                assert ini_found == module, \
                    'Found ipmi.ini files in multiple modules: %s and %s' % (
                        ini_found, module)
            else:
                ini_found = module
                shutil.copyfile(ipmi_ini, target)

    if not ini_found:
        # If we failed to find a file generate fallback instead
        f = open(target, 'w')
        f.write(fallback_ini)
        f.close()

if __name__ == '__main__':
    main()
