%function [x ts f1 f7]=pcap(filename)

fields=7;
f = fopen(filename); x = fread(f,'7*uint32=>uint32'); fclose(f); 
x = reshape(x, fields, []);
x1 = x(1,:); 
x2 = x(2,:);
ts = double(x1) + double(x2)*2^32;
f1= x(3,:);
f7= x(7,:);
f1 = typecast(f1, 'int32');
f7 = typecast(f7, 'int32');


