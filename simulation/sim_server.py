# Simple hardware simulation server.
#
# Lists on a socket port and performs the appropriate exchange to implement
# hardware reading and writing.

from pkg_resources import require
require('numpy')

import argparse
import os
import sys
import socket
import struct
import numpy


parser = argparse.ArgumentParser(description = 'PandA Hardware simulation')
parser.add_argument(
    '-d', '--daemon', action = 'store_true', help = 'Run as daemon process')
parser.add_argument(
    '--hardware', default = 'sim_hardware', help = 'Simulation module to load')
parser.add_argument(
    'config_dir', help = 'Path to configuration directory')
args = parser.parse_args()

sim_hardware = __import__(args.hardware)


# We daemonise the server by double forking, but we leave the controlling
# terminal and other file connections alone.
def daemonise():
    if os.fork():
        # Exit first parent
        sys.exit(0)
    # Do second fork to avoid generating zombies
    if os.fork():
        sys.exit(0)


class SocketFail(Exception):
    pass


# Ensures exactly n bytes are read from sock
def read(sock, n):
    result = ''
    while len(result) < n:
        rx = sock.recv(n - len(result))
        if not rx:
            raise SocketFail('End of input')
        result = result + rx
    return result


def run_simulation(conn):
    while True:
        command_word = read(conn, 4)
        command, block, num, reg = struct.unpack('cBBB', command_word)
        if command == 'R':
            tx = controller.do_read_data(block, num, reg)
            conn.sendall(struct.pack('I', tx))
        elif command == 'W':
            value, = struct.unpack('I', read(conn, 4))
            controller.do_write_config(block, num, reg, value)
        elif command == 'T':
            length, = struct.unpack('I', read(conn, 4))
            data = read(conn, length * 4)
            data = numpy.fromstring(data, dtype = numpy.int32)
            controller.do_write_table(block, num, reg, data)
        elif command == 'C':
            bits, changes = controller.do_read_bits()
            conn.sendall(struct.pack('256?', *bits + changes))
        elif command == 'P':
            positions, changes = controller.do_read_positions()
            conn.sendall(struct.pack('32I32?', *positions + changes))
        elif command == 'M':
            controller.set_capture_masks(*struct.unpack('4I', read(conn, 16)))
        else:
            print 'Unexpected command', repr(command_word)
            raise SocketFail('Unexpected command')


sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.bind(('localhost', 9999))
sock.listen(0)

# Create as much of the controller before we daemonise so that errors can be
# caught if possible at this stage.
controller = sim_hardware.Controller(args.config_dir)

print 'Simulating server ready'
if args.daemon:
    daemonise()

# If any threads need to be started this must happen after daemonising, as
# threads won't survive.
controller.start()

(conn, addr) = sock.accept()
conn.setsockopt(socket.SOL_TCP, socket.TCP_NODELAY, 1)
try:
    run_simulation(conn)
except (SocketFail, KeyboardInterrupt) as e:
    print 'Simulation closed:', repr(e)
