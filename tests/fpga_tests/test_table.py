#!/usr/bin/env python

import sys
import argparse
import socket
import numpy
import base64

parser = argparse.ArgumentParser(description = 'Table tester')
parser.add_argument(
    '-s', '--server', default = 'localhost',
    help = 'PandA server name, default %(default)s')
parser.add_argument(
    '-p', '--port', default = 8888, type = int,
    help = 'PandA server port, default %(default)d')
parser.add_argument(
    '-i', '--incremental', default = False, action = 'store_true',
    help = 'Test incremental writes')
parser.add_argument(
    'table', help = 'Table to test')
args = parser.parse_args()


def get_lines(sock):
    buf = ''
    while True:
        lines = buf.split('\n')
        for line in lines[:-1]:
            yield line
        buf = lines[-1]
        # Get something new from the socket
        rx = sock.recv(4096)
        assert rx, 'Didn\'t get response in time'
        buf += rx

def expect_ok(ll):
    l = ll.next()
    if l != 'OK':
        print l
        sys.exit(1)

def read_result(ll):
    l = ll.next()
    if l[:4] == 'OK =':
        return l[4:]
    else:
        print l
        sys.exit(1)


s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((args.server, args.port))
s.setsockopt(socket.SOL_TCP, socket.TCP_NODELAY, 1)

ll = get_lines(s)

s.sendall('%s.TABLE.MAX_LENGTH?\n' % args.table)
max_length = int(read_result(ll))

print args.table, max_length

#a = max_length - 1 - numpy.arange(max_length, dtype = numpy.int32)
a = numpy.arange(max_length, dtype = numpy.int32)
e = base64.b64encode(a)


LINE_LEN = 80

if args.incremental:
    # Send the data one line at a time.  Can be very slow...
    s.sendall('%s.TABLE<\n\n' % args.table)
    expect_ok(ll)
    for i in range(0, len(e), LINE_LEN):
        s.sendall('%s.TABLE<<B\n' % args.table)
        s.sendall('%s\n\n' % e[i:i+LINE_LEN])
        expect_ok(ll)
        if i % (10*LINE_LEN) == 0:
            sys.stdout.write('.')
            sys.stdout.flush()
    sys.stdout.write('\n')
else:
    s.sendall('%s.TABLE<B\n' % args.table)
    # Send e in chunks that fit into a line.
    for i in range(0, len(e), LINE_LEN):
        s.sendall('%s\n' % e[i:i+LINE_LEN])
    s.sendall('\n')
    assert ll.next() == 'OK'


s.sendall('%s.TABLE.B?\n' % args.table)

r = ''
while True:
    l = ll.next()
    if l == '.':
        break
    assert l[0] == '!'
    r = r + l[1:]

if r != e:
    dec = base64.b64decode(r)
    ar = numpy.fromstring(dec, dtype = numpy.int32)
    print ar

    for i in range(len(ar)):
        if a[i] != ar[i]:
            print i, a[i], ar[i]
