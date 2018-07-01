pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
x2=95
y2=63 
::start::
cls() 
for j=-2,2 do 
  for i=0,1,.05 do 
    a=i+time()/8 
    x=cos(a)*30+64+j 
    y=sin(a)*30+64+j 
    if(j*j>0) then
      line(x,y,x2,y2,8+i*3)
    end
    rectfill(x-1,y+2,x+1,y+4,1+i*15)
    line(64,64,x,y,2)
    x2,y2=x,y 
  end 
  for i=-1,1,2 do 
   if(j!=0) then 
    line(64+j,64+j,64+j*3+i*16,99+j*3,8+j) 
   end
  end 
end 
flip()
goto start
