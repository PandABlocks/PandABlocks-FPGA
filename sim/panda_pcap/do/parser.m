function parser(Channels)

x=load('read_from_hp1.txt');
y=reshape(x,Channels,[]);
plot(diff(y'));
