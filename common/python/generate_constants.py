#!/usr/bin/env python
import argparse


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('file_path')
    return parser.parse_args()


def main():
    args = parse_args()
    print('library ieee;')
    print('use ieee.std_logic_1164.all;')
    print('package panda_constants is')

    for line in open(args.file_path, 'r'):
        if '=' not in line:
            continue

        first, second = line.split('=')
        key, val = first.strip().upper(), int(second)
        print(f'    constant {key} : std_logic_vector(31 downto 0)', end='')
        print(f' := X"{val:08x}";')

    print('end panda_constants;')


if __name__ == "__main__":
    main()
