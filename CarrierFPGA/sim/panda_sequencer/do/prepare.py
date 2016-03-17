#!/usr/bin/env python

import sys

from numpy import *

repeats = [1,2,3,4,5,6]
mask=[14, 14,14,14,14,14]
cond =[15,15,15,15,15,15]
out1=[1,2,4,8,16, 32]
out2=[0,0,0,0,0,0]
phase1=[10,20,30,40,50,60]
phase2=[60,50,40,30,20,10]

lower = 0;
upper = 0;

for i in range(len(repeats)):
    byte0 = repeats[i]
    byte1 = mask[i] | cond[i] << 4 | out1[i] << 8 | out2[i] << 14
    byte2 = phase1[i]
    byte3 = phase2[i]
    print byte0
    print byte1
    print byte2
    print byte3

#    print 'X"%08x",' % byte0
#    print 'X"%08x",' % byte1
#    print 'X"%08x",' % byte2
#    print 'X"%08x",' % byte3

