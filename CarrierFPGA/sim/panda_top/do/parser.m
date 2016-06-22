function [x] = parser(Arms, Channels)

x=load('read_from_hp1.txt');

len = length(x) / Arms;
start = 1;

% print average of diff of each posbus channel
for R = 1:Arms
    a = x(start:start+len-1);
    start = start + len;
    y = reshape(a,Channels,[]);
    mean(diff(y'))
    plot(diff(y'));
end



