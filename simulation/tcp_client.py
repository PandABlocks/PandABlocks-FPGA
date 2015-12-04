#!/usr/bin/env python

import socket
try:
    import readline
except ImportError:
    # don't need readline on windows
    pass


class Client(object):

    def __init__(self, hostname, port):
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.s.connect((hostname, port))
        self.line_iter = self.get_lines()
        try:
            self.run()
        except (EOFError, KeyboardInterrupt) as blah:
            pass
        finally:
            self.s.shutdown(socket.SHUT_WR)
            self.s.close()

    def get_lines(self):
        buf = ""
        while True:
            lines = buf.split("\n")
            for line in lines[:-1]:
                #print "Yield", repr(line)
                yield line
            buf = lines[-1]
            # Get something new from the socket
            rx = self.s.recv(4096)
            assert rx, "Didn't get response in time"
            buf += rx

    def recv_all(self):
        ret = [self.line_iter.next()]
        assert ret[0], "Connection closed"
        if ret[0].startswith("!"):
            while not ret[-1].startswith("."):
                ret.append(self.line_iter.next())
        return ret

    def prompt_and_send(self):
        msg = raw_input("> ")
        self.s.sendall(msg + "\n")
        return msg

    def run(self):
        while True:
            msg = self.prompt_and_send()
            if "<" in msg:
                while msg:
                    msg = self.prompt_and_send()
            for resp in self.recv_all():
                print "< %s" % resp

if __name__ == "__main__":
    from argparse import ArgumentParser
    parser = ArgumentParser(
        description="Commandline client to Zebra2 TCP server")
    parser.add_argument("hostname", default="localhost", nargs="?",
                        help="Hostname of Zebra2 box (default localhost)")
    parser.add_argument("port", type=int, default=8888, nargs="?",
                        help="Port number of TCP server (default 8888)")
    args = parser.parse_args()
    Client(args.hostname, args.port)
