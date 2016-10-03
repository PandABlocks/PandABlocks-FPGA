function [x y]= parser(Fields)

f=fopen('log.file');
x = fread(f,[Fields,inf],'int32');
fclose(f);