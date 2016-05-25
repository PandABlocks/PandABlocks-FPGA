function [x y]= parser(Fields)

f=fopen('log');
x = fread(f,[Fields,inf],'int32');
fclose(f);


% print average of diff of each posbus channel
for index = 1:Fields
    y = x(index, :);
    mean(diff(y))
end

plot(diff(diff(x')));
