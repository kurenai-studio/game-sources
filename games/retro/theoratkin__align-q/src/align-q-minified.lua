m=math
b=m.abs
r=m.random
p=m.pi*2
x,y=120,68
a={{t=r()*p,r=30,c=2},{t=0,r=52,c=6},{t=r()*p,r=64,c=10}}e=.03
t=0
function TIC()if btnp(5)then
reset()end
cls()circ(x,y,15,3)line(170,y,174,y,1)for i,o in pairs(a)do
s=i==2
if w then
o.t=a[3].t
else
o.t=o.t+(y-o.r)/1000/(s and btn(4)and 2 or 1)if s and o.t>=p then t=t+1 end
o.t=o.t%p
end
circb(x,y,o.r,s and 1 or 15)k=m.cos(o.t)*o.r
j=m.sin(o.t)*o.r
circ(x+k,y+j,i+1,o.c)end
if b(a[1].t-a[2].t)<e and b(a[1].t-a[3].t)<e then
w=1
line(x+k*2,y+j*2,x-k*2,y-j*2,4)print("Success!",2,y)end
print(t,196,y)end
