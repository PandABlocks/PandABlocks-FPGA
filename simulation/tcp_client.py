import socket
import readline


class Client(object):

    def __init__(self, hostname, port):
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.s.connect((hostname, port))
        self.line_iter = self.get_lines()
        try:
            self.run()
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

    def send_recv(self, msg):
        self.s.sendall(msg + "\n")
        ret = [self.line_iter.next()]
        assert ret[0], "Connection closed"
        if ret[0].startswith("!"):
            while not ret[-1].startswith("."):
                ret.append(self.line_iter.next())
        return ret

    def run(self):
        while True:
            msg = raw_input("> ")
            for resp in self.send_recv(msg):
                print "< %s" % resp

if __name__ == "__main__":
    from argparse import ArgumentParser
    parser = ArgumentParser(
        description="Commandline client to Zebra2 TCP server")
    parser.add_argument("hostname", help="Hostname of Zebra2 box")
    parser.add_argument("port", type=int, default=8888, nargs="?",
                        help="Port number of TCP server (default 8888)")
    args = parser.parse_args()
    Client(args.hostname, args.port)
