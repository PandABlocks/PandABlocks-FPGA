#
# Extension module to support PID block
# model composer; variable sampling frequency; fixed point
#
# latest rev: feb 23 2024
#

# fixed point parameter scaling
P_SCALE   = 2**23
P_RAWMAX  = (2**31-1)
I_SCALE   = 2**4
I_RAWMAX  = (2**10-1)
D_SCALE   = 2**7
D_RAWMAX  = (2**12-1)
FS_MAX    = 1e6
FS_MIN    = 1
FF_SCALE  = 2**10
GI_SCALE  = 2**25
G1D_SCALE = 2**32
G2D_SCALE = 2**7
LOG_FNAME = '/tmp/pidlog.txt'

WRITELOG = False

import struct


def float_to_hex(f):
    return hex(struct.unpack('<I', struct.pack('<f', f))[0])


class PidReader:
    # "request" is xxx in the "extension: xxx" of the parameter definition in the block.ini
    # "number" is the block instance number (in case there are more than one)
    def __init__(self):
        pass

    def read(self, request, number):
        global pid_table
        a=pid_table[number][request.upper()]
        return a
    

class PidWriter:
    def __init__(self):
        pass

    def __del__(self):
        pass

    def logentry(self, s):
        self.debugfile=open(LOG_FNAME,"a")
        self.debugfile.write(s)
        self.debugfile.close()
        
    def trim_positive_param(self, v, rawmax, scale):
        return min(abs(v),rawmax)/scale
        
    def parse_KP(self, number, value):
        pid_table[number]['KP']= self.trim_positive_param(value, P_RAWMAX, P_SCALE)
        gp=pid_table[number]['KP']*P_SCALE
        v=int(gp)
        if WRITELOG:
            s="PID{0:d}.RESERVED_GP={1:d}\n".format(number+1,v)
            self.logentry(s)
        return(v,)
        
    def parse_KI(self, number, value):
        pid_table[number]['KI']= self.trim_positive_param(value, I_RAWMAX, I_SCALE)
        fs=pid_table[number]['FS']
        gi=pid_table[number]['KI']/(2.*fs)*GI_SCALE
        v=int(gi)
        if WRITELOG:
            s="PID{0:d}.RESERVED_GI={1:d}\n".format(number+1,v)
            self.logentry(s)
        return(v,)
        
    def parse_KD(self, number, value):
        pid_table[number]['KD']= self.trim_positive_param(value, D_RAWMAX, D_SCALE)
        fs=pid_table[number]['FS']
        gd=2.0*pid_table[number]['KD']*fs
        ff=pid_table[number]['F_FILTER']
        # keep f_filter below Fs/4 (for bilinear convergence) and non-zero
        if ((ff==0) or (ff>=(fs/4.))):
            ff=round(fs/5.*FF_SCALE)/FF_SCALE
            pid_table[number]['F_FILTER']= ff
        R=fs/ff
        g1d=(2*R-1)/(2*R+1)*G1D_SCALE
        g2d=gd/(2*R+1)*G2D_SCALE
        v1=int(g1d)
        v2=int(g2d)
        if WRITELOG:
            s=     "PID{0:d}.RESERVED_G1D={1:d}\n".format(number+1,v1)
            s= s + "PID{0:d}.RESERVED_G2D={1:d}\n".format(number+1,v2)
            self.logentry(s)
        return(v1,v2)

    def parse_F_FILTER(self, number, value):
        fs=pid_table[number]['FS']
        ff=value/FF_SCALE
        # keep f_filter below Fs/4 (for bilinear convergence) and non-zero
        if ((ff==0) or (ff>=(fs/4.))):
            ff=round(fs/5.*FF_SCALE)/FF_SCALE
        pid_table[number]['F_FILTER']= ff
        kd=pid_table[number]['KD']*D_SCALE
        t=self.parse_KD(number,kd)
        return t

    def parse_F_SAMPLE(self, number, value):
        fs=min(FS_MAX,max(FS_MIN,value))
        pid_table[number]['FS']= fs
        ki=pid_table[number]['KI']*I_SCALE
        kd=pid_table[number]['KD']*D_SCALE
        # return concatenation of tuples
        t= self.parse_KI(number,ki) + self.parse_KD(number,kd)
        return t

pid_table=[]
default_pid_params= \
    {
    'KP'      :   1.0,
    'KI'      :   0.0,
    'KD'      :   0.0,
    'F_FILTER':  20.0,
    'FS'      : 100.0
    }
PID_Reader=PidReader()
PID_Writer=PidWriter()

class Extension:
    def __init__(self, count):
        # count is the number of modules of this type that are instantiated in
        # this PandABox App, as defined in the app.ini file
        global pid_table
        pid_table=[default_pid_params.copy() for _ in range(count)]
        # note that the .copy() is needed, to avoid making n references to
        # the same object (dict)

    def parse_read(self, request):
        # request is the extension parameter associated to this particular block field
        # block_num is the which of the "count" instances is addressed
        #return lambda block_num, *args: PID_Reader.read(request, block_num, *args)
        return lambda block_num: PID_Reader.read(request, block_num)

    def parse_write(self, request):
        # request is the extension parameter associated to this particular block field
        # block_num is the which of the "count" instances is addressed
        methodName="parse_"+request.upper()
        theMethod=getattr(PID_Writer,methodName)
        #return lambda block_num, value, *args: theMethod(block_num, value, *args)
        return lambda block_num, value: theMethod(block_num, value)



# ---------------  main  ------------------------
# just for test

# if __name__ == '__main__':
#  
#    cicci = Extension(2)
#    print(pid_table)
#    kp_reader=cicci.parse_read('kP')
#    kp_writer=cicci.parse_write('kP')
#    ki_reader=cicci.parse_read('kI')
#    ki_writer=cicci.parse_write('kI')
#    kd_reader=cicci.parse_read('kD')
#    kd_writer=cicci.parse_write('kD')
#    ffilt_reader=cicci.parse_read('f_filter')
#    ffilt_writer=cicci.parse_write('f_filter')
#    # f_filt
#    print('------------')
#    readback_val= ffilt_reader.read(0)
#    print("f_filt1 before=",readback_val)
#    ffilt_writer.write(0,14756)
#    readback_val= ffilt_reader.read(0)
#    print("f_filt1 after=",readback_val)
#    # k_p
#    print('------------')
#    readback_val= kp_reader.read(0)
#    print("kp1 before=",readback_val)
#    kp_writer.write(0,3.4*PARAM_SCALE)
#    readback_val= kp_reader.read(0)
#    print("kp1 after=",readback_val)
#    readback_val= kp_reader.read(1)
#    print("kp2 after=",readback_val)
#    print('------------')
#    print(pid_table)
#    # use case kp=7, ki=2, kd=0.1, ff=5kHz
#    print('================')
#    # GP = 1088421888
#    # GI =  897988541
#    # G1D= 1065286241
#    # G2D= 1137154510
#    ffilt_writer.write(1,4000)
#    kp_writer.write(1,7*PARAM_SCALE)
#    ki_writer.write(1,2.0*PARAM_SCALE)
#    kd_writer.write(1,0.1*PARAM_SCALE)
#    print(pid_table)
