#!/bin/env python
"""
Generate FPGA version like 0.1.0c9 from git describe like 0.1-9-g5539563-dirty
"""
import logging
import re
from argparse import ArgumentParser


def parse_git_version(git_version):
    # type: (str) -> str
    # Get the git tag numbers, they should be of the format x.y[.z][-something]
    match = re.match("(\d+)\.(\d+)(?:\.(\d+))?(?:-(\d+))?", git_version)
    assert match, "Git version %r can't be parsed" % git_version
    hex_numbers = []
    for g in match.groups():
        if g:
            hex_numbers.append("%02x" % min(int(g), 255))
        else:
            hex_numbers.append("00")
    return "".join(hex_numbers[-1:] + hex_numbers[:-1])


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("git_describe", help="Output of git describe")
    git_version = parser.parse_args().git_describe
    try:
        hex_str = parse_git_version(git_version)
    except Exception as e:
        logging.exception(e)
        # Something went wrong, just print 0.0.0c0
        hex_str = "00000000"
    print hex_str


if __name__ == "__main__":
    main()
