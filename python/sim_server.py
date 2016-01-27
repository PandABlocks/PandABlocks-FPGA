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
import socket
import struct
import numpy


parser = argparse.ArgumentParser(description = 'PandA Hardware simulation')
parser.add_argument(
    '-d', '--daemon', action = 'store_true', help = 'Run as daemon process')
parser.add_argument(
    'config_dir', help = 'Path to configuration directory')
args = parser.parse_args()

sys.path.append(os.path.dirname(__file__))
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
            # Read one register
            tx = controller.do_read_register(block, num, reg)
            conn.sendall(struct.pack('I', tx))
        elif command == 'W':
            # Write one register
            value, = struct.unpack('I', read(conn, 4))
            controller.do_write_register(block, num, reg, value)
        elif command == 'T':
            # Write data array to large table
            length, = struct.unpack('I', read(conn, 4))
            data = read(conn, length * 4)
            data = numpy.fromstring(data, dtype = numpy.int32)
            controller.do_write_table(block, num, reg, data)
        elif command == 'D':
            # Retrieve increment of data stream
            length, = struct.unpack('I', read(conn, 4))
            data = controller.do_read_capture(length / 4)
            if data is None:
                conn.sendall(struct.pack('I', -1))
            else:
                assert data.dtype == numpy.int32
                raw_data = data.data
                assert len(raw_data) <= length
                conn.sendall(struct.pack('I', len(raw_data)))
                conn.sendall(raw_data)
        else:
            print 'Unexpected command', repr(command_word)
            raise SocketFail('Unexpected command')


sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.bind(('localhost', 9999))
sock.listen(0)

# Create as much of the controller before we daemonise so that errors can be
# caught if possible at this stage.
controller = Controller(args.config_dir)

print 'Simulating server ready'
if args.daemon:
    daemonise()

# If any threads need to be started this must happen after daemonising, as
# threads won't survive.
controller.start()

(conn, addr) = sock.accept()
sock.close()

conn.setsockopt(socket.SOL_TCP, socket.TCP_NODELAY, 1)
try:
    run_simulation(conn)
except (SocketFail, KeyboardInterrupt) as e:
    print 'Simulation closed:', repr(e)
