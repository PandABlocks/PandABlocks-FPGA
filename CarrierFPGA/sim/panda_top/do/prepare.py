#!/usr/bin/env python

import sys

from numpy import *

repeats = [1,2,3,4,5,6]
mask=[14, 14,14,14,14,14]
cond =[15,15,15,15,15,15]
out1=[1,2,4,8,16, 32]
out2=[0,0,0,0,0,0]
time1=[10,20,30,40,50,60]
time2=[60,50,40,30,20,10]

lower = 0;
upper = 0;

for i in range(len(repeats)):
    lower = repeats[i] | mask[i] << 12 | cond[i] << 16 | out1[i] << 20 | out2[i] << 26
    upper = time1[i] | time2[i] << 16
    print 'X"%08x",' % lower
    print 'X"%08x",' % upper

