pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-- _init() is executed once
-- at program start. also used
-- to reset after game_over
function _init()
	init_player()
	init_cave()
	game_over=false
	sfx(-1)
end

-- _update() is run 30 times
-- per second, before _draw()
-- use _update60() instead for
-- 60 fps
function _update()
	if not game_over then
 	update_player()	
 	update_cave()
 	check_hit()
 	player.score+=player.speed
 else
 	if btnp(4) then
 		_init()
 	end
	end
end

function init_player()
	player={}
	player.x=30
	player.y=64
	player.gravity=.2
	player.vy=0	
	player.speed=2
	player.score=0

	sprites={
		rising=1,
		falling=2,
		dead=3
	}
end

function init_cave()
	cave={}

	-- seed our cave with a spike
	-- to generate all other spikes
	cave[1]={top=10,btm=100}
	
	min_height=3
	max_height=45
end

function update_cave()
	-- delete {player.speed} spikes
	-- every frame, which will 
	-- get regenerated in the while
	-- loop below
	if #cave>player.speed then	
		for i=1,player.speed do
			del(cave,cave[i])
		end
	end
	 
	while #cave<128 do
		local prev_spike=cave[#cave]	
		local new_spike={}
		local prev_top=prev_spike.top
		local prev_btm=prev_spike.btm		
		
		-- generate a new top spike
		-- based on the height of the 
		-- previous spike. rnd(7)-3
		-- is used so that new spike 
		-- will sometimes be smaller
		new_spike.top=prev_top+flr(rnd(7)-3)
		new_spike.top=mid(
			min_height,
			max_height,
			new_spike.top)
		
		new_spike.btm=prev_btm-flr(rnd(7)-3)
		new_spike.btm=mid(
			127-max_height,
			127-min_height,
			new_spike.btm
		)
		
		add(cave,new_spike)
	end
end

function draw_cave()
	top_color=5
	bottom_color=5

	-- draw every spike in our cave
	-- the cave is indexed 1-128,
	-- but the screen pixels go
	-- from 0-127, so the x coord
	-- of our lines is offset by 1
	for i=1,#cave do
 	local spike=cave[i]
		local x=i-1
 	line(
 		x,0,
 		x,spike.top,
 		top_color)
 
 	line(
 		x,127,
 		x,spike.btm,
 		bottom_color)	
	end
end

function check_hit()
	-- check the collision box of
	-- the player against cave
	-- spikes. cave indexes are 
	-- accessed at x+1 because the
	-- cave table is 1-128 vs our
	-- pixel screen at 0-127
	for x=player.x,player.x+7 do
		cave_top=cave[x+1].top
		cave_bottom=cave[x].btm
		if player.y < cave_top or 
				player.y+7 > cave_bottom
		then
			game_over=true
			sfx(1)
		end	
	end
end


function update_player()
	if btnp(2) then
		player.vy-=5
		sfx(0)
	end

	-- accelerate and drop 
	player.vy+=player.gravity
	player.y+=player.vy

	-- don't allow player to go
	-- above or below screen
	player.y=min(player.y,120)
	if player.y>= 120 then
		player.vy=0
	end
	player.y=max(player.y,0)	
	if player.y<= 0 then
		player.vy=0
	end
end

function draw_player()
	local sprite=1
	if game_over then
		sprite=sprites.dead
	elseif player.vy<=0 then
		sprite=sprites.rising
 elseif player.vy>0 then
  sprite=sprites.falling
	end
	
	spr(
		sprite,
		player.x,
		player.y
	)
end

function _draw()
	-- clear screen
	cls()

	-- draw a background color 
	rectfill(
		0,0,     -- x1,y1
		127,127, -- x2,y2
		1							 -- color
	)

	draw_cave()
	draw_player()

	print(
		"score:"..player.score,
		0,0, -- x,y
		3    -- color
	)

	if game_over then
		print(
			"game oooooover",
			30,30,
			7)
	end
end
__gfx__
0000000000aaaa0000aaaa0000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aa1a1a00aaaaaa008888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700aaaaaaaaaaaaaaaa88188188000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000aaaaaaaaaa1a1aaa88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000aaaaaaaaaaaaaaaa88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700aa1111aaaaaaaaaa88111188000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aa11aa00aa11aa008888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaa0000aaaa0000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00050000071500b150141502d150221002b1002810021100201002010020100181001f100161001f10020100201002110023100231002510027100281002b1002e1002f100001000010000100001000010000100
000a00002e050230501c0501705014050110500f0500b050090500705006050080500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
