import socket
import select
import struct


class SocketFail(Exception):
    pass


class Server(object):

    """Simulation server exposing zebra2 simlation controller to TCP server"""

    def __init__(self, controller):
        """Start simulation server and create controller

        Args:
            controller(Controller): Zebra2 controller object
        """
        self.controller = controller
        self.sock_l = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock_l.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sock_l.bind(('localhost', 9999))
        self.sock_l.listen(0)

    def run(self):
        """Accept the first connection to server, then start simulation"""
        (self.sock, addr) = self.sock_l.accept()
        self.sock_l.close()

        # Set no delay on this as we're only looking at tiny amounts of data
        self.sock.setsockopt(socket.SOL_TCP, socket.TCP_NODELAY, 1)

        # Now start ticking the simulation
        try:
            while True:
                timeout = self.controller.calc_timeout()
                if timeout is None or timeout > 0:
                    # wait for up to timeout for some data
                    (rlist, _, _) = select.select((self.sock,), (), (), timeout)
                    # If we got a response, service it
                    if rlist:
                        self._respond()
                # Now service the controller
                self.controller.do_tick()
        except (KeyboardInterrupt, SocketFail) as e:
            print "Simulation closed: %r" % e

    def _read(self, n):
        """Blocking read n bytes from socket and return them"""
        result = ''
        while len(result) < n:
            rx = self.sock.recv(n - len(result))
            if not rx:
                raise SocketFail('End of input')
            result = result + rx
        return result

    def _respond(self):
        """Read a command from the socket and respond to it"""
        command_word = self._read(4)
        command, block, num, reg = struct.unpack('cBBB', command_word)
        if command == 'R':
            # Read one register
            tx = self.controller.do_read_register(block, num, reg)
            self.sock.sendall(struct.pack('I', tx))
        elif command == 'W':
            # Write one register
            value, = struct.unpack('I', self._read(4))
            self.controller.do_write_register(block, num, reg, value)
        elif command == 'T':
            # Write data array to large table
            length, = struct.unpack('I', self._read(4))
            data = self._read(length * 4)
            data = numpy.fromstring(data, dtype = numpy.int32)
            self.controller.do_write_table(block, num, data)
        elif command == 'D':
            # Retrieve increment of data stream
            length, = struct.unpack('I', self._read(4))
            data = self.controller.do_read_capture(length / 4)
            if data is None:
                self.sock.sendall(struct.pack('i', -1))
            else:
                assert data.dtype == numpy.int32
                raw_data = data.data
                assert len(raw_data) <= length
                self.sock.sendall(struct.pack('I', len(raw_data)))
                self.sock.sendall(raw_data)
        else:
            print 'Unexpected command', repr(command_word)
            raise SocketFail('Unexpected command')
