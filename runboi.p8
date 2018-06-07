pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--run-charlie

--holds all objects that exist
--in the game loop. each object
--should have :update and :draw
objects={}

function _init()
	--gravity = how many pixels per
	--frame should our y velocity 
	--decrease when falling
	gravity=.2
	friction=.88

	--speed of our animation
	--loops, used in player.effects
	runanimspeed=.12
	wallrunanimspeed=.2

	--delta time multiplier, 
	--essentially controls the
	--speed of the game
	dt=.5

	--game length timer
	gametime=0

	gamestate="intro"

	-- camera position
	cx=0
	cy=0

	-- camera shake values
	shakex=0
	shakey=0
	shakevx=0
	shakevy=0
	shake=0

	-- did player just touch a 
	-- mover (moving platform)?
	justhitmover=false
	lasthitmover=nil
	-- music(30)

	--set up our objects table
	add(objects,player)
	add(objects,specks)
end

function _update60()
	if gamestate=="game" then
		for object in all(objects) do
			object:update()
		end
	elseif gamestate=="intro" then
		intro:update()
	end
end

function _draw()
	cls()

	if gamestate=="game" then
		_drawgame()
	elseif gamestate=="intro" then
		intro:draw()
	end
end

function _drawgame()
	--reset camera
	camera(0,0)

	-- debug=true
	if debug then
		debugrow=0
		-- debugprint("x velocity: " .. player.vx)
		-- debugprint("y velocity: " .. player.vy)
		debugprint("run timer: " .. player.runtimer)
		debugprint("mem: " .. stat(0))
		debugprint("cpu: " .. stat(1))
		-- debugprint("sprite: " .. player.spr)
		-- debugprint("land timer: " .. abs(player.landtimer))
		-- debugprint("fall timer: " .. player.falltimer)
	end

	bgdraw()

	--draw the map
	map(0,0,0,0,128,128)

	for object in all(objects) do
		object:draw()
	end
end

function bgdraw()

	-- fillp(0b0011 1100 1100 0011)
 -- cloud checker pattern
	-- 0 = filled
	--     1111
	--     1110
	--     1111
	--     0101
	fillp(0b1111111010110101)
	for i=1,30 do
		srand(i)
		local size=i/30

			-- circles move with parallax
			-- x position scrolls slowly
			local x=(rnd(128+64)-(cx+time()*5)*(size*.7+.3)*.4)%(128+64)-32
			local y=(rnd(128+64)-cy*(size*.7+.3)*.4)%(128+64)-32

			col=1

			circfill(x,y,size*16,col)
			-- circfill(x,y,size*(col%1)*16,col+1)
	end
	fillp()
end

function debugprint(text)
	print(
		text, 
		32, --x
		12+debugrow*6, --y
		9) --color
	debugrow+=1
end
--------------------------------
-->8
--player object-----------------
player={}

--player attributes-----
--x/y pos and velocity
player.x=2 *8
player.y=7 *8
player.vx=0
player.vy=0

--lists of our previous
--positions/flippage for
--effects rendering
player.prevx=0
player.prevy=0
player.prevf=0

--the "effects" timer
player.etimer=0

--the sprite is 3x5, so the
--wr and hr dimensions are 
--radii, and x/y is the
--initial center position

player.wr=1
player.hr=2
player.w=3
player.h=5

player.hit_jump=false

--instantaneous jump velocity
--the "power" of the jump
player.jumpv=3

--movement states
player.standing=false
player.wallsliding=false

--what direction we're facing
--1 or -1, used when we're 
--facing away from a wall
--while sliding
player.facing=0

--timers used for animation
--states and particle fx
player.falltimer=0
player.landtimer=0
player.runtimer=0
player.headanimtimer=0

player.spr=64
--sprite numbers------
--64 standing
--65 running 1
--66 running 2
--67	crouching (post landing)
--80 jumping
--81 falling
--96 sliding 1
--97 sliding 2
--98 sliding 3 / hanging
--99 sliding 4

player.draw=function(p)
	p.headanimtimer=p.headanimtimer%3+1
	local xoff=p.wr
	local yoff=p.hr

	if p.standing then
		if p.landtimer>0 then
		--if we just landed, show the
		--crouch sprite
			p.spr=67
		else
		--if we're running, show
		--alternating frames of the
		--running animations
			p.spr=64+p.runtimer%3
		end
	elseif p.wallsliding	then
		p.spr=96+flr(player.runtimer%4)
	else
	--jumping
		if p.vy<0 then
			p.spr=80
		else
		 p.spr=81
		end
	end

	--flicker the flame head
	pal(9,9-(p.etimer<4 and 1 or 0))
	spr(
		p.spr, --sprite
		p.x-xoff, --x pos
		p.y-yoff, --y pos
		0.375, --width, .375*8=3px
		0.625, -- height, .625*8=5px
		p.flipx -- flip x
	)
	pal()
end

player.update=function(p)
	p.standing=p.falltimer<7
	p.moving=nil
	--move the player, x then y
	p:handleinput()
	p:movex()
	p:movey()
	p:movejump()
	p:checksliding()
	p:effects()
end

player.checksliding=function(p)
	p.wallsliding=false
	--hanging on wall to the right?
	if collide(p,'x',1) then
		p.wallsliding=true
		p.facing=-1
		if(p.vy>0) p.vy*=.97
	--hanging on wall to the left?
	elseif collide(p,'x',-1) then
		p.wallsliding=true
		p.facing=1
		if(p.vy>0) p.vy*=.97
	end
end

player.handleinput=function(p)
	if p.standing then
		p:groundinput()
	else
		p:airinput()
	end
	p:jumpinput()

	--overall x speed tweak to
	--make things feel right
	p.vx*=0.98
end

player.jumpinput=function(p)
	local jump_pressed=btn(4)
	if jump_pressed and not p.is_jumping then
		p.hit_jump=true
	else
		p.hit_jump=false
	end
	p.is_jumping=jump_pressed
end --player.jumpinput

player.movejump=function(p)
	--if standing, or if only just
	--started falling, then jump
	if(not p.hit_jump) return false
	if p.standing then
		p.vy=min(p.vy,-p.jumpv)
	elseif p.wallsliding then
	-- allow walljump if sliding
		--use normal jump speed,
		--but proportionate to how 
		--fast player is currently
		--sliding down wall
		p.vy-=p.jumpv
		p.vy=mid(p.vy,-p.jumpv/3,-p.jumpv)

		--set x velocity / direction
		--based on wall facing
		--(looking away from wall)
		p.vx=p.facing*2
		p.flipx=(p.facing==-1)

		sfx(9)
	end
end --player.movejump

player.groundinput=function(p)
	--pressing left
	if btn(0) then
		p.flipx=true
		--brake if moving in
		--opposite direction
		if(p.vx>0) p.vx*=.9
		p.vx-=.2*dt
	--pressing right
	elseif btn(1) then
		p.flipx=false
		if(p.vx<0) p.vx*=.9
		p.vx+=.2*dt
	--pressing neither, slow down
	--by our friction amount
	else
		p.vx*=friction
	end
end --player.groundinput

player.airinput=function(p)
	if btn(0) then
		p.vx-=0.15*dt
	elseif btn(1) then
		p.vx+=0.15*dt
	end
end --player.airinput

player.movex=function(p)
	--xsteps is the number of
	--pixels we think we'll move
	--based on player.vx
	local xsteps=abs(p.vx)*dt

	--for each pixel we're
	--potentially x-moving,
	--check collision
	for i=xsteps,0,-1 do
		--our step amount is the
		--smaller of 1 or the current
		--i, since p.vx can be a
		--decimal, multiplied by the
		--pos/neg sign of velocity
		local step=min(i,1)*sgn(p.vx)

		--check for x collision
		if collide(p,'x',step) then
			--if hit, stop x movement
			p.vx=0
			break
		else
			--move if we didn't hit
			p.x+=step
		end	

	end
end --player.movex

player.movey=function(p)
	--always apply gravity 
	--(downward acceleration)
	p.vy+=gravity*dt

	local ysteps=abs(p.vy)*dt
	for i=ysteps,0,-1 do
		local step=min(i,1)*sgn(p.vy)
		if collide(p,'y',step) then
			--y collision detected

			--trigger a landing effect
			if p.vy > 1 then
				p.landing_v=p.vy
			end

			--zero out y velocity and
			--reset falling timer
			p.vy=0
			p.falltimer=0
		else
			--no y collision detected
			p.y+=step
			p.falltimer+=1
		end
	end
end --player.movey

player.effects=function(p)
	if p.standing then
		p:runningeffects()
		p:landingeffects()
	elseif p.wallsliding then
		p:slidingeffects()
	end

	p:headeffects()
end --player.effects

player.runningeffects=function(p)
		--updates the run timer to
		--inform the running animation

		--if we're slow/still, then
		--zero out the run timer
		if abs(p.vx)<.3 then
			p.runtimer=0
		--otherwise if we're moving,
		--tick the run timer and
		--spawn running particles
		else
			local oruntimer=p.runtimer
			p.runtimer+=abs(p.vx)*runanimspeed
			if flr(oruntimer)!=flr(p.runtimer) and
			   p.etimer%2==0
			then
				spawnp(
					p.x, --x pos
					p.y+2,--y pos
					-p.vx/3,--x vel
					-abs(p.vx)/6,--y vel,
					.5 --jitter amount
				)
			end
		end

		--update the "landed" timer
		--for crouching animation
		if p.landtimer>0 then
			p.landtimer-=0.4
		end
end

player.landingeffects=function(p)
	--only spawn landing effects
	--if we've a landing velocity
	if(not p.landing_v) return

	--play a landing sound
	--based on current y speed
	if p.landing_v>5 then 
		sfx(15)
	else
		sfx(14)
	end

	--set the landing timer
	--based on current speed
	p.landtimer=p.landing_v

	--spawn landing particles
	for j=0,p.landing_v*2 do
		spawnp(
			p.x,
			p.y+2,
			p.landing_v/8*(rnd(2)-1),
			-p.landing_v/7*rnd(),
			.3
		)
	end

	--slight camera shake
	shakevy+=p.landing_v/6

	--reset landing velocity
	p.landing_v=nil
end

player.slidingeffects=function(p)
		local oruntimer=p.runtimer
		p.runtimer-=p.vy*wallrunanimspeed

		if flr(oruntimer)!=flr(p.runtimer) then
			spawnp(
				p.x-p.facing,
				p.y+1,
				p.facing*abs(p.vy)/4,
				0,
				0.2
			)
		end
end

player.headeffects=function(p)
	if p.etimer%6==0 then
		local ex,evx,edir
		edir=p.prevf and -1 or 1
		spawnp(
			p.prevx,
			p.prevy - p.hr,
			-edir*0.2, -- x vel
			-0.1, -- y vel
			0.1, --jitter
			9, -- color
			.7 -- duration
			)
		p.prevx=p.x
		p.prevy=p.y
		p.prevf=p.flipx
	end

	p.etimer+=1
	if(p.etimer>10) p.etimer=1
end

-- spawn a particle effect
spawnp=function(x,y,vx,vy,jitter,c,d)
	--object for the particle
	local p={
		x=x,
		y=y,
		ox=x,
		oy=y,
		vx=2*(vx+rnd(jitter*2)-jitter),
		vy=2*(vy+rnd(jitter*2)-jitter),
		c=c or 5,
		d=d or 0.5
	}
	p.duration=p.d+rnd(p.d)
	p.life=1

	add(specks,p)
end
--------------------------------
-->8
--collision code----------------

col_corners=function(p,a,v)
	--given an agent and velocity, 
	--this returns the coords of 
	--the two corners that should 
	--be checked for collisions
	local x1,x2,y1,y2

	--x movement and y movement
	--are calc'd separately. when
	--this func is called, we only
	--need to check one a

	if a=='x' then
		--if we have x-velocity, then
		--return the coords for the
		--right edge or left edge of
		--our agent sprite
		x1=p.x+sgn(v)*p.wr
		y1=p.y-p.hr
		x2=x1
		y2=p.y+p.hr
	elseif a=='y' then
		--if we have y-velocity, then
		--return the coords for the
		--top edge or bottom edge of
		--our p sprite
		x1=p.x-p.wr
		y1=p.y+sgn(v)*p.hr
		y2=y1
		x2=p.x+p.wr
	end

	--x1,y1 now represents the
	--"near" corner to check
	--(based on velocity), and
	--x2,y2 the "far" corner
	return x1,y1,x2,y2
end

--check if the given (p)
--collides on the given a (a)
--within the given distance (d)
collide=function(p,a,d,nearonly)
	--init hitmover checks
	justhitmover=false
	lasthitmover=nil

	--get the 2 corners that
	--should be checked
	x1,y1,x2,y2=col_corners(p,a,d)

	--add our potential movement
	if a=='x' then
		x1+=d
		x2+=d
	else
		y1+=d
		y2+=d
	end

	--query our 2 points to see
	--what tile types they're in
	local tile1=mget(x1/8,y1/8)
	local tile2=mget(x2/8,y2/8)

	--"nearonly" indicates we only
	--want to know if our near
	--corner will be in a wall
	if nearonly and
		iswall(tile1) and 
		(tile1!=2 or y1%8<4) 
	then
		return true
	end

	--if not nearonly, check if
	--either corner will hit a wall
	if not nearonly and
		(iswall(tile1) or 
		iswall(tile2))
	then 
		return true
	end

	--now check if we will hit any
	--moving platforms

	-- no hits detected
	return false
end

function iswall(tile)
 --we know our tile sprites
 --our stored in slots 1-7
 return tile>=1 and tile<=7
end

--------------------------------
-->8
--effects-----------------------

--specks holds all particles to
--be drawn in our object loop
specks={}
specks.update=function(this)
	for speck in all(this) do
		speck.ox=speck.x
		speck.oy=speck.y
		speck.x+=speck.vx
		speck.y+=speck.vy
		speck.vx*=.85
		speck.vy*=.85
		speck.life-=1/30/speck.duration

		if speck.life<0 or
			iswall(mget(speck.x/8,speck.y/8))
		then
			del(this, speck)
		end
	end 
end

specks.draw=function(this)
	for speck in all(this) do
		line(
			speck.x,
			speck.y,
			speck.ox,
			speck.oy,
			speck.c+(speck.life/2)*3
		)
	end
end


--------------------------------
-->8
--intro object------------------
intro={}
intro.t=0
intro.r=2
intro.draw=function()
	intro.t+=2/360
	if(intro.t>1)intro.t=0
	for i=10,7,-1 do
		print(
			"flamehead", 
			52 + intro.r * i*sin(intro.t), 
			48 + intro.r * i*cos(intro.t), 
			i
		)
	end

	print(
		"press ❎ to start",
		32,
		90,
		7
	)

end

intro.update=function()
	if btnp(4) or btnp(5) then
		gamestate="game"
	end
end




__gfx__
000000001555555144444444cd1d1d1c444444444444444444444444444444440505505000000000000000000000000000000000000000000000000000000000
000000005d5dd56542422424d1111111444414444441444444411444444114445050050500000000000000000000000000000000000000000000000000000000
0070070055555555444444441111111d444411444411444444111144444114440505505000000000000000000000000000000000000000000000000000000000
000770005d5555d542444424d1111111411111144111111441111114444114445056050500000000000000000000000000000000000000000000000000000000
000770005d5555d5444444441111111d411111144111111444411444411111145050650500000000000000000000000000000000000000000000000000000000
007007005555555500000000d1111111444411444411444444411444441111440505505000000000000000000000000000000000000000000000000000000000
00000000565dd5d5000000001111111d444414444441444444411444444114445050050500000000000000000000000000000000000000000000000000000000
000000001555555100000000c1d1d1dc444444444444444444444444444444440505505000000000000000000000000000000000000000000000000000000000
989a989a00011100000ccc00000000600000e000000e0000000ee00000e11e000000000000000000000000000000000000000000000000000000000000000000
989a989a011333110ccbbbcc00dddd6700001e0000e1000000ecce0000edde000000000000000000000000000000000000000000000000000000000000000000
a989a989030000030b00000b0d000070eeee1de00ed1eeee0edddde000ecce000000000000000000000000000000000000000000000000000000000000000000
a989a989030000030b00000bd00dd0001dcf1dceecd1fcd1e111111e00effe000000000000000000000000000000000000000000000000000000000000000000
9a989a98010000010c00000cd0d00d001dcf1dceecd1fcd100effe00e111111e0000000000000000000000000000000000000000000000000000000000000000
9a989a98010000010c00000cd00d00d0eeee1de00ed1eeee00ecce000edddde00000000000000000000000000000000000000000000000000000000000000000
89a989a9033111330bbcccbb0d0000d000001e0000e1000000edde0000ecce000000000000000000000000000000000000000000000000000000000000000000
89a989a900033300000bbb0000dddd000000e000000e000000e11e00000ee0000000000000000000000000000000000000000000000000000000000000000000
7dddddd7aaaa999998888890a99999a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d222222da888888998888890a99999a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d277772d9877888998888890a99999a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d222222d9888888998888890a99999a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d222222d9888888998888890a99999a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d222222d9888888998777890a97779a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d222222d9888888998888890a99999a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7dddddd798888889099999000aaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11616161111161611161116111616111116111111111611111111161111111110000000000000000000000000000000000000000000000000000000000000000
11616161111161611161116111616111116111111111611111111161111111110000000000000000000000000000000000000000000000000000000000000000
11616161111161611161116111616111116111111111611111111161111111110000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
00900000009000000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66600000060000006660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06000000666000000660000066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60600000060000006000000060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00900000009000000090000000900000009000000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00600000606000000060000060600000006000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66000000060000000600000006000000060000006600000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06600000660000000660000006600000060000000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60000000006000000600000006000000606000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90000000900000009000000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60600000606000006060000060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06000000060000000600000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06600000060000000600000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06000000006000000600000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000706050301020408000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100010000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100010000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100010000000000000000000001000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100010000000000000000000001000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000010101000001000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000001010100000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000000000000000000000100010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000101000100000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000100000101000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000010000000100000101000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000010000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010300201801018010180101801018010180101801018010180101801018010180101801018010180101801018010180101801018010180101801018010180101801018010180101801018010180101801018010
010200201811018110181101811018110181101811018110181101811018110181101811018110181101811018110181101811018110181101811018110181101811018110181101811018110181101811018110
010200201821018210182101821018210182101821018210182101821018210182101821018210182101821018210182101821018210182101821018210182101821018210182101821018210182101821018210
010200201831018310183101831018310183101831018310183101831018310183101831018310183101831018310183101831018310183101831018310183101831018310183101831018310183101831018310
010200201841018410184101841018410184101841018410184101841018410184101841018410184101841018410184101841018410184101841018410184101841018410184101841018410184101841018410
010200201851018510185101851018510185101851018510185101851018510185101851018510185101851018510185101851018510185101851018510185101851018510185101851018510185101851018510
010200201861018610186101861018610186101861018610186101861018610186101861018610186101861018610186101861018610186101861018610186101861018610186101861018610186101861018610
010200201871018710187101871018710187101871018710187101871018710187101871018710187101871018710187101871018710187101871018710187101871018710187101871018710187101871018710
01020000101230c500105001050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01030000151130c5001c5001050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300000c1130c405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300001011300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0104000010614106151e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400000e61524006307072450730507247073050718505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300000041500605000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01030000004770c675000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010b00001884518800168041680218805188001684416842188451880018800188001884518800168041680218805188002280018800188451880016844168421884518800188001880018805188001684416842
010b0000188351880016804168021880516805168341683218835188001b8341b832188351880016804168021880518800168341683218835188001b8341b8321883518800168041680218805188001683416832
010b000030e2530600306003060030e153060030600306003060530600306003060030e1530e0030e0030e0030e0530e0030e0030e0030e1530e0030e0030e0030e0530e0030e0030e0030e1530e0030e0030e00
010b000030e2530e0000c1530e0030e1530e0000c1530e0030e1530e0000c1530e0030e1530e0030e1530e0000c1530e0030e1530e0030e1530e0000c1530e0030e1530e0000c1530e0030e1530e0000c1530e00
010b00001ff2613f261ff2500f0000f0000f0000f0000f0000f0000f001ff0000f001ff0013f001ff3613f361ff2500f0000f0000f0000f0000f0000f0000f0000f0000f0000f0000f0000f0000f0000f0000f00
010b00001ff2613f261ff2500f001bf260ff261bf2500f0000f0000f001ff0000f001ff0013f001ff3613f361ff2500f0000f0000f0000f0000f0000f0000f0000f0000f0000f0000f0000f0000f0000f0000d00
010b00000ce5500e0000e000ce350ce7500e000ce5500e000ce500ce350ce0500e000ce5500e000ce350ce450ce5500e0000e000ce550ce150ce250ce350ce050ce500ce350ce050ce050ce150ce250ce350ce05
010b00001884418842188351680018800188001884418845188451880518800188001880516800168451680018844188452280018800188001880018845188001884518800188001880018800188001884516800
000100001fe1505e1009e100de1012e101ae101ee1023e1026e1026e1026e1028e1029e1029e1029e1028e1026e1025e1021e101fe101ee1018e1014e1011e100ee100be100be1007e1003e0003e0003e0002e00
010b00001ff1613f161ff1613f161ff1613f161ff2613f261ff2613f161ff1613f161bf060ff061bf160ff161bf160ff161bf160ff161bf160ff161bf260ff261bf260ff161bf160ff160ff150ff061bf060ff06
01090000001520015200100001000c15000100001000010000155001000c100001000c15000100001000010000152001520c100001000c15000100001000010000155001000c100001000c150001000010000100
010900000c5340c53500500005000e5340e53500500005000f5340f53500500005000050000500145341453500500005001453414535135341353511500005001153411535005000050000500005001353413535
0109000000500005001353413535115341153500500005000f5340f535005000050000500005001153411535005000050011534115350f5340f53500500005000e5340e535005000050000500005000050000500
010900000c5340c53500500005000e5340e53500500005000f5340f53500500005000050000500145341453500500005001453414535135341353511500005001153411535005000050000500005001853418535
0109000000500005001850000500145341453500500005001353413535005000050000500005001a5341a53500500005000050000500185341853500500005001353413535005000050000500005000050000500
01090000180260c026180000c0001a0260e0261a0000e0001b0260f0261b0060f00620006140062002614026180000c00020026140261f026130261d0000c0001d026110261d006110061f006130061f02613026
01090000180000c0001f026130261d026110261d006110061b0260f0261b0060f0061d006110061d02611026180000c0001d026110261b0260f0261b0060f0061a0260e0261a0060e006180060c006180060c006
01090000180260c026180060c0061a0260e0261a0060e0061b0260f0261b0060f00620006140062002614026180000c00020026140261f026130261f006130061d026110261d0061100624006180062402618026
01090000180060c006180060c006200261402620006140061f026130261f00613006260061a006260261a02624006180062400618006240261802624006180061f026130261f00613006180060c006180060c006
010900000c6050c6050c6050c6050c6050c6050c605000000c6050c6050c6050c6050c6050c6050c6050c6050c6050c6050c605000000c6050c6050c6050c6050c6050c6050c605000000c6150c6150c6150c615
010900000c6150c6150c6150c6050c6050c6050c605000000c6050c6050c6050c6050c6050c6050c6050c6050c6050c6050c605000000c6050c6050c6050c6050c6050c6050c605000000c6150c6150c6150c615
010900000c61500000000000000000000000000c61500000000000000000000000000c6150000000000000000c61500000000000000000000000000000000000006150000000615000000c625000000c63500000
0109000000516075160051607516075160f516075160f5160c5160f5160c5160f5160c516135160c51613516135160f516135160f516135161b516135161b516185161b516185161b51618516275161851627516
010900000043500000000000000000000000000043500000004330000000000000000043500000000000000000435000000000000000004350000000435000000043300000000000000000000000000000000000
010900000715207152001000010013150001000010000100071550010000100001001315000100001000010007152071520010000100131500010000100001000715500100001000010013150001000010000100
010900000c1730c000131030c0000c10014100131000f1000c6050c6050c6050c6050c1230c0000c1530c0000c0000c0000c1430c0000c6050c6050c1330c0000c6050c0000c0000c0000c1530c0000c6050c000
010900000061500000006250000000000000000062500000180730000000000000000c615000000c6250000000000000000c61500000000000000000000000001807300000000000000000000000000000000000
01090000001520015200100001000c10000100001000010000105001000c100001000c10000100001000010000152001520c100001000c10000100001000010000105001000c100001000c100001000010000100
010900000715207152001000010000100001000010000100071050010000100001000010000100001000010007152071520010000100001000010000100001000710500100001000010000100001000010000100
010900000715207152001000010000100001000010000100071050010000100001000010000100001000010007102071020010000100001000010000100001000710500100001000010000100001000010000100
000300000e6500c6201862015620126200f6200f6200d6200c6200a6200a620086100461004610046100361003610026100160001600016000060000600006000060000600006000060000600006000060000600
000200000862006620076200562004610046100361003610026100261001610016100161004600046000360003600026000160001600016000000000000000000000000000000000000000000000000000000000
010300000c916189160c9162493618936249362491630936159000d9000d9000e900179000d90012900129000f9000e9000d9000f9001490015900169000c9000c9000f90011900139001490015900169000c900
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01120010181401a1200c1101b7201b414220001f1401f524181131a1421f1101d144201201f110371462b7141e1002200026000290002a0002a0002a0002a0002900027000240001d00000000000000000000000
011200100037000172003720012502251021760252402171033510315703117033510511605252057710525000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 1012147f
00 1012147f
00 1013157f
00 1013147f
00 1113197e
00 1113147f
00 1113197f
00 1113157f
00 1716147f
00 1716157f
00 1716197f
02 1716157f
01 1a252344
00 1a252444
00 1a1b2444
00 281c2444
00 2b1d2544
00 2b1e2644
00 1a1f2744
00 1a202744
00 1a212744
00 1a222744
00 2b252744
00 2b272944
00 2c2a2944
00 2c2a2944
00 1a272944
00 1a272d44
00 2c242744
02 2d242744
03 32334344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 1a1f4344

