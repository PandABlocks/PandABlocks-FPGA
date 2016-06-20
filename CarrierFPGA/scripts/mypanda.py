#!/bin/env dls-python

class sequencer:

    frame_index = 0

    def __init__(self, name):
        self.name = name

    def table(self, repeats, mask, cond, p1out, p2out, p1time, p2time):
        sequencer.frame_index += 1
        frame = [0]*4
        frame[0] = repeats
        frame[1] = (mask << 28)   | frame[1]
        frame[1] = (cond << 24)   | frame[1]
        frame[1] = (p1out << 16) | frame[1]
        frame[1] = (p2out << 8)  | frame[1]
        frame[2] = p1time
        frame[3] = p2time
        print 'Frame-',sequencer.frame_index, '=>', frame
