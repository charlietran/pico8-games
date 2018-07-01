pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
alive_color=7
width=128
height=128

prev_i=1
line_i=2
lines={{},{}}

cls()

--draw r pent
pset(64,60,alive_color)
pset(64,61,alive_color)
pset(64,62,alive_color)
pset(65,60,alive_color)
pset(63,61,alive_color)

function get(x,y)
 if x<1 or
    x>width or
    y<1 or
    y>height
 then
  return 0
 else
  return pget(x-1,y-1)
 end
end

function get_buffered(i,x)
 if x<1 or x>width then
  return 0
 else
  return lines[i][x]
 end
end

while true do
 flip()
 
 --clear line buffer
 for x=1,width do
  lines[1][x]=0
  lines[2][x]=0
 end
 
 for y=1,height do
  --swap line buffers
  prev_i=line_i
  line_i=(line_i%2)+1
  
  --copy cur line to buffer
  for x=1,width do
   lines[line_i][x]=pget(x-1,y-1)
  end
  
  for x=1,width do
   neighbors=(
    get_buffered(prev_i,x-1)+
    get_buffered(prev_i,x)+
    get_buffered(prev_i,x+1)+
    get_buffered(line_i,x-1)+
    get_buffered(line_i,x+1)+
    get(x-1,y+1)+
    get(x,y+1)+
    get(x+1,y+1)
   )
   
   if neighbors==alive_color*3 or
      (neighbors==alive_color*2 and
      pget(x-1,y-1)==alive_color)
   then
    pset(x-1,y-1,alive_color)
   else
    pset(x-1,y-1,0)
   end
 	end
 end
end 
