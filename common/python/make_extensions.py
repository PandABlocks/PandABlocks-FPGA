# This script installs files into the extensions directory

import sys
import os.path
import shutil
import fnmatch

from .ini_util import read_ini, ini_get


def get_modules(ini):
    for section in ini.sections():
        if section != '.':
            module_name = ini_get(ini, section, 'module', section.lower())
            block_name = ini_get(ini, section, 'block', module_name)
            yield module_name, block_name


def get_extension(base_dir, module):
    ini_file = os.path.join(base_dir, '%s.block.ini' % module)
    ini = read_ini(ini_file)
    extension = ini_get(ini, '.', 'extension', None)
    if extension is not None:
        if not extension:
            extension = ini.get('.', 'entity')
    return extension


def add_extension(target_dir, source_dir, extension):
    print('Adding extension', extension)
    extensions_dir = os.path.join(source_dir, 'extensions')
    files = fnmatch.filter(os.listdir(extensions_dir), '*.py')
    assert '%s.py' % extension in files, \
        'Extension module %s.py not found' % extension
    for file in files:
        shutil.copy(os.path.join(extensions_dir, file), target_dir)


def process_ini(extensions, blocks_dir, ini):
    for module, block in get_modules(ini):
        base_dir = os.path.join(blocks_dir, module)
        extension = get_extension(base_dir, block)
        if extension:
            add_extension(extensions, base_dir, extension)


def main():
    top = sys.argv[1]
    app_file = sys.argv[2]
    target = sys.argv[3]
    extensions = sys.argv[4]

    target_dir = os.path.join(top, 'targets', target)
    modules_dir = os.path.join(top, 'modules')

    target_ini = read_ini(os.path.join(target_dir, '%s.target.ini' % target))
    app_ini = read_ini(app_file)

    # Pull in extension files from both modules
    #process_ini(extensions, os.path.join(target_dir, 'blocks'), target_ini)
    process_ini(extensions, modules_dir, target_ini)
    process_ini(extensions, modules_dir, app_ini)


if __name__ == '__main__':
    main()
