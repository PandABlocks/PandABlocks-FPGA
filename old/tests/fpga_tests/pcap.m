function [ts x xref y yref]=pcap(filename)

fields=6;
f = fopen(filename); x = fread(f,'6*uint32=>uint32'); fclose(f); 
raw = reshape(x, fields, []);
x1 = raw(1,:); 
x2 = raw(2,:);
ts = double(x1) + double(x2)*2^32;

x = raw(3,:);
xref = raw(4,:);

y = raw(5,:);
yref = raw(6,:);

x = 1024*typecast(x, 'int32');
xref = 1024*typecast(xref, 'int32');
y = 1024*typecast(y, 'int32');
yref = 1024*typecast(yref, 'int32');
