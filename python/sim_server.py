# Simple hardware simulation server.
#
# Lists on a socket port and performs the appropriate exchange to implement
# hardware reading and writing.

try:
    from pkg_resources import require
    require('numpy')
except ImportError:
    pass

import argparse
import os
import sys

parser = argparse.ArgumentParser(description='PandA Hardware simulation')
parser.add_argument('-d', '--daemon', action='store_true',
                    help='Run as daemon process')
parser.add_argument('config_dir', help='Path to configuration directory')
args = parser.parse_args()

sys.path.append(os.path.dirname(__file__))

from zebra2.simulation.server import Server
from zebra2.simulation.controller import Controller

# We daemonise the server by double forking, but we leave the controlling
# terminal and other file connections alone.
def daemonise():
    if os.fork():
        # Exit first parent
        sys.exit(0)
    # Do second fork to avoid generating zombies
    if os.fork():
        sys.exit(0)

# Create as much of the controller before we daemonise so that errors can be
# caught if possible at this stage.
controller = Controller(args.config_dir)
server = Server(controller)

print 'Simulating server ready'
if args.daemon:
    daemonise()

# now we can start the simulation ticking
server.run()
