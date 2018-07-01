pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
alive_color = 7
width = 128
height = 128

board_i = 1

boards = { {}, {} }

for y = 1, height do
 boards[1][y] = {}
 boards[2][y] = {}
 for x = 1, width do
  boards[1][y][x] = 0
  boards[2][y][x] = 0
 end
end

function get(board_index,x,y)
 if x<1 or
    x>width or
    y<1 or
    y>height
 then
  return 0
 else
  return boards[board_index][y][x]
 end
end

cls()

function draw_current_gen()
 for y=1, height do
  for x=1, width do
   pset(
    x-1,
    y-1,
    boards[board_i][y][x] * alive_color
   )
  end
 end
end

function draw_next_gen()
 next_i = (board_i%2) + 1
 for y=1, height do
  for x=1, width do
   neighbors = (
    get(board_i,x-1,y-1) +
    get(board_i,x,y-1) +
    get(board_i,x+1,y-1) +
    get(board_i,x-1,y) +
    get(board_i,x+1,y) +
    get(board_i,x-1,y+1) +
    get(board_i,x,y+1) +
    get(board_i,x+1,y+1)
   )
   if neighbors==3 or
      (neighbors==2 and
       boards[board_i][y][x]==1)
   then
    boards[next_i][y][x]=1
   else
    boards[next_i][y][x]=0
   end       
  end
 end
 board_i=next_i
end

-- draw a blinker
boards[1][60][64] = 1
boards[1][61][64] = 1
boards[1][62][64] = 1 

-- draw an r pentomino
boards[1][60][64] = 1
boards[1][60][65] = 1
boards[1][61][63] = 1 
boards[1][61][64] = 1 
boards[1][62][64] = 1 

while true do
 draw_current_gen()
 flip()
 draw_next_gen()
end

