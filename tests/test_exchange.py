#!/usr/bin/env python

import sys
import socket
import time


server = socket.socket()
server.connect(('localhost', 8888))
server.settimeout(0.1)

transcript = open(sys.argv[1], 'r')



# Iterator: returns lines one at a time read from socket connection
def socket_readlines():
    buffer = ''
    while True:
        lines = buffer.split('\n')
        for line in lines[:-1]:
            yield line
        buffer = lines[-1]
        rx = server.recv(4096)
        if rx:
            buffer = buffer + rx
        else:
            yield buffer
            break

lines = socket_readlines()

def read_response(count):
    return [lines.next() for n in range(count)]


# Returns next command response set read from transcript file
def transcript_readlines():
    to_send = []
    to_receive = []

    # First scan for lines starting with <.
    for line in transcript:
        if line[0] == '<':
            to_send.append(line[2:-1])
        elif line[0] == '>':
            to_receive.append(line[2:-1])
            break

    # Now read the remainder of the response
    for line in transcript:
        if line[0] == '>':
            to_receive.append(line[2:-1])
        else:
            break

    return (to_send, to_receive)


failed = 0
while True:
    (tx, rx) = transcript_readlines()
    if not tx:
        break

    start = time.time()
    for line in tx:
        server.send(line + '\n')
    response = read_response(len(rx))
    end = time.time()

    if response == rx:
        print tx[0], 'OK %.2f ms' % (1e3 * (end - start))
    else:
        print tx[0], 'response error', response
        failed += 1

if failed:
    print failed, 'tests failed'
    sys.exit(1)
