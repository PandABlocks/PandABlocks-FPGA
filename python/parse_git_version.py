#!/bin/env python
import sys
import logging
import re

git_version = sys.argv[1]

try:
    # Get the git tag numbers, they should be of the format x.y[.z][-something]
    match = re.match("(\d+)\.(\d+)(?:\.(\d+))?(?:-(\d+))?", git_version)
    assert match, "Git version %r can't be parsed" % git_version
    hex_numbers = []
    for g in match.groups():
        if g:
            hex_numbers.append("%02x" % min(int(g), 255))
        else:
            hex_numbers.append("00")
    print "".join(hex_numbers[-1:] + hex_numbers[:-1])
except Exception as e:
    logging.exception(e)
    # Something went wrong, just print 0.0.0
    print "000000"
