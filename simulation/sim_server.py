#!/usr/bin/env python

# Simple hardware simulation server.
#
# Lists on a socket port and performs the appropriate exchange to implement
# hardware reading and writing.

import socket
import struct

import sim_hardware


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
        command, block, num, reg = struct.unpack('cBBB', read(conn, 4))
        if command == 'R':
            tx = sim_hardware.do_read_data(block, num, reg)
            conn.sendall(struct.pack('I', tx))
        elif command == 'W':
            value, = struct.unpack('I', read(conn, 4))
            sim_hardware.do_write_config(block, num, reg, value)
        elif command == 'A' or command == 'B':
            length, = struct.unpack('I', read(conn, 4))
            data = read(conn, length)
            sim_hardware.do_write_table(block, num, reg, command == 'B', data)
        elif command == 'C':
            bits, changes = sim_hardware.do_read_bits()
            conn.sendall(struct.pack('256?', *bits + changes))
        elif command == 'P':
            positions, changes = sim_hardware.do_read_positions()
            conn.sendall(struct.pack('32I32?', *positions + changes))
        else:
            print 'Unexpected command', repr(command)
            raise SocketFail('Unexpected command')


sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.bind(('localhost', 9999))
sock.listen(0)

(conn, addr) = sock.accept()
conn.setsockopt(socket.SOL_TCP, socket.TCP_NODELAY, 1)
try:
    run_simulation(conn)
except SocketFail, e:
    print 'Simulation closed:', e
