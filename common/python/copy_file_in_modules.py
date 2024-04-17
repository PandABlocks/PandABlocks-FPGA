#!/usr/bin/env python
# This script finds a needed file in the included modules

import argparse
import sys
import os.path
import shutil

from .compat import configparser
from .ini_util import read_ini, ini_get


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--fallback')
    parser.add_argument('top')
    parser.add_argument('app_file')
    parser.add_argument('target_name')
    parser.add_argument('dst_path')
    return parser.parse_args()


def get_modules(ini):
    for section in ini.sections():
        if section != '.':
            module_name = ini_get(ini, section, 'module', section.lower())
            yield module_name


def main():
    args = parse_args()
    ini = read_ini(args.app_file)
    target_module_found = None
    for module in get_modules(ini):
        target_path = os.path.join(
            args.top, 'modules', module, args.target_name)
        if os.path.isfile(target_path):
            if target_module_found:
                # We can end up visiting the same module more than once
                assert target_module_found == module, \
                    'Found target file in multiple modules: %s and %s' % (
                        target_module_found, module)
            else:
                target_module_found = module
                shutil.copyfile(target_path, args.dst_path)

    if not target_module_found:
        if args.fallback:
            shutil.copyfile(args.fallback, args.dst_path)
        else:
            raise Exception('Can\'t find target file')


if __name__ == '__main__':
    main()
