pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
color_map={0,1,9,2,7,2,10,4,8,9}
::start::
 --grab random pixel from 0-127
 x=rnd(128)
 y=rnd(128)
 --get color # of that pixel
 -- (or its neighbor below)
 col=pget(x,y+rnd(2))
 --randomly re-set that color
 --to the color map
 if rnd(50)<col then 
  col=color_map[col]
 end
 -- draw circle and seed 
 -- first row with white pixels
 circ(x,y,1,col)
 pset(y,127,7)
goto start
