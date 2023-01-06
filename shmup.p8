pico-8 cartridge // http://www.pico-8.com
version 39
__lua__

------------------
--- GAME HOOKS ---
------------------

--- BASE HOOKS ---

function _init()
	switch_scene("title")
end

function _update()
end

function _draw()
end

--- TITLE HOOKS ---

function title_init()
	blink=anim({9,4,4,7,4,7},2)
end

function title_update()
	if (btnp(🅾️)) then
		sfx(2) -- click sound
		switch_scene("game")
	end
	blink:update()
end

function title_draw()
	cls()
	local str_start="press 🅾️ to start"
	print(str_start,hcenter(str_start),vcenter(),blink:current())
end

-- GAME_OVER HOOKS ---

function gameover_init()
	blink=anim({9,4,4,7,4,7},2)
end

function gameover_update()
	if (btnp(❎)) then
		sfx(2) -- click sound
		switch_scene("title")
	end
	blink:update()
end

function gameover_draw()
	cls()
	local str_gameover="game over"
	local str_start="press ❎ to continue"
	print(str_gameover,hcenter(str_gameover),vcenter(),9)
	print(str_start,hcenter(str_start),vcenter()+12,blink:current())
end

--- IN GAME HOOKS ---

function game_init()
	score=0
	difficulty=1
	entities={}
	enemies={}
	shots={}
	
	starfield=create_starfield(12)

	ship=create_ship(28,46)
end

function game_update()
	if (should_create_wave()) create_enemy_wave()
	for e in all(entities) do
		e:update()
	end
end

function game_draw()
	cls(0)
	for e in all(entities) do
		e:draw()
	end
	-- draw score
	print("score:"..score,1,1,7)
	-- draw energy bar
	rectfill(2,120,ship.energy,126,11)
	rect(1,120,31,126,7)
end

------------------
--- EXPLOSIONS ---
------------------

-- create muzzle effect of size, step s and color c
function create_muzzle(x,y,size,s,c)
	local muzzle={
		t=0,
		size=size,
		pos={x=x,y=y},
		s=s,
		update=function(this)
			this.size-=this.s
			if (this.size<1) del(entities,this)
		end,
		draw=function(this)
			circfill(this.pos.x,this.pos.y,this.size,7)
			circ(this.pos.x,this.pos.y,this.size,c or 9)
		end
	}
	add(entitites,muzzle)
end

-- create an explosion
function create_explosion(x,y)
		local explosion={
			smokes={},
			flares={},
			update=function(this)
				for i=#this.smokes,1,-1 do
					this.smokes[i].size-=1
					printh(this.smokes[i].size)
					if (this.smokes[i].size<1) deli(this.smokes,i)
				end
				for i=#this.flares,1,-1 do
					this.flares[i].size-=2
					if (this.flares[i].size<1) deli(this.flares,i)
				end
				if (#this.flares==0 and #this.smokes==0) del(entities,this)
			end,
			draw=function(this)
				for s in all(this.smokes) do
					circfill(s.pos.x,s.pos.y,s.size,5)
				end
				for f in all(this.flares) do
					circfill(f.pos.x,f.pos.y,f.size,7)
					circ(f.pos.x,f.pos.y,f.size,10)
					circ(f.pos.x,f.pos.y,f.size-1,9)
				end
			end
		}
		for i=1,rnd(4)+2 do
			add(
				explosion.smokes,
				{
					pos={x=x+rnd(8)-5,y=y+rnd(8)-5},
					size=flr(rnd(5)+3)
				}
			)
			add(
				explosion.flares,
				{
					pos={x=x+rnd(8)-5,y=y+rnd(8)-5},
					size=flr(rnd(7)+5)
				}
			)
		end
		sfx(3)
		add(entities,explosion)
end

---------------------
--- PLAYER'S SHIP ---
---------------------

-- create player's ship
function create_ship(x,y)
	local ship={
		pos={x=24,y=64},
		spd={x=0,y=0},
		box={x=0,y=1,w=8,h=6},
		energy=30,
		flame=create_flame(24,64),
		state="base",
		anim={
			base=anim({1},1),
			up=anim({3},1),
			dwn=anim({2},1)
		},
		update=function(this)
			for e in all(enemies) do 
				if (spr_collide(this,e)) then
					e:destroy() -- we're jumping into game_over, so we don't actually need this
					this:destroy()
				end
			end
			for s in all(shots) do
				if (spr_collide(this,s)) then
					s.remove(s)
					this.energy-=3
					if (this.energy<=0) this:destroy()
				end
			end
			this.flame:update()
			if btnp(⬆️) then
				this.spd.y-=0.5
				this.state="up"
			elseif btnp(⬇️) then
				this.spd.y+=0.5
				this.state="dwn"
			elseif btnp(⬅️) then
				this.spd.x-=0.5
				this.state="base"
			elseif btnp(➡️) then
				this.spd.x+=0.5
				this.state="base"
			else
				this.spd.x-=ship.spd.x/40
				this.spd.y-=ship.spd.y/40
			end
			if btnp(🅾️) then
				create_shot(ship.pos.x+9,ship.pos.y+2)
			end
			if (abs(this.spd.y)<0.2) this.state="base"
			this.pos.x+=this.spd.x
			this.pos.y+=this.spd.y
			this.pos=adjust_pos(this)
		end,
		draw=function(this)
			this.flame:draw(this.pos.x,this.pos.y)
			spr(this.anim[this.state]:current(),this.pos.x,this.pos.y)
		end,
		destroy=function()
			sfx(4)
			switch_scene("gameover")
		end
	}
	add(entities,ship)
	return ship
end

-- create player's ship's flame
function create_flame(x,y)
	return {
		anim=anim({4,5,6,5},1),
		update=function(this)
			this.anim:update()
		end,
		draw=function(this,x,y)
			spr(this.anim:current(),x-9,y)
		end
	}
end

-- create player's shoot
function create_shot(x,y)
	sfx(0)
	local shot={
		pos={x=x,y=y},
		spd={x=5,y=0},
		box={x=2,y=5,w=4,h=1},
		update=function(this)
			this.pos.x+=this.spd.x
			if (this.pos.x>127) del(entities,this)
		end,
		draw=function(this)
			spr(7,this.pos.x,this.pos.y)
		end,
		remove=function(this)
			del(shots,this)
			del(entitites,this)
		end
	}
	create_muzzle(x,y,10,4)
	add(entities,shot)
	add(shots,shot)
end

---------------
--- ENEMIES ---
---------------

-- creates an enemy wave
-- positions for enemies can be given
function create_enemy_wave(t)
	local wave_types={
		{
			{x=128,y=10},
			{x=148,y=40},
			{x=148,y=70},
			{x=128,y=100}
		},
		{
			{x=128,y=20},
			{x=128,y=100}
		},
		{
			{x=128,y=40},
			{x=148,y=70},
			{x=128,y=100}
		}
	}
	local wt=t or flr(rnd(3)+1)
	for e in all(wave_types[wt]) do
		create_enemy(e.x,e.y)
	end
end

-- creates single enemy
function create_enemy(x,y)
	local enemy={
		pos={x=x,y=y},
		spd={x=-1,y=0},
		box={x=1,y=1,w=6,h=6},
		flame=create_enemy_flame(x,y),
		update=function(this)
			if (abs_box(this).x1<0) this:remove()
			for s in all(shots) do
				if (spr_collide(this,s)) then
					this:destroy()
				end
			end
			this.spd.y=sin(this.pos.x>>5)
			this.pos.x+=this.spd.x
			this.pos.y+=this.spd.y
			this.flame:update()
			if (enemy_should_fire()) create_enemy_shot(this.pos.x-8,this.pos.y)
		end,
		draw=function(this)
			this.flame:draw(this.pos.x,this.pos.y)
			spr(16,this.pos.x,this.pos.y)
		end,
		destroy=function(this)
			create_explosion(this.pos.x, this.pos.y)
			this:remove()
		end,
		remove=function(this)
			del(entities, this)
			del(enemies, this)
		end
	}
	add(enemies,enemy)
	add(entities,enemy)
end

-- create enemy ship's flame
function create_enemy_flame(x,y)
	return {
		anim=anim({17,18,19,18},1),
		update=function(this)
			this.anim:update()
		end,
		draw=function(this,x,y)
			spr(this.anim:current(),x+7,y-1)
		end
	}
end

-- create enemy shot
function create_enemy_shot(x,y)
		sfx(1)
		local shot={
			pos={x=x,y=y},
			spd={x=-5,y=0},
			box={x=3,y=4,w=4,h=2},
			anim=anim({20,21},1),
			update=function(this)
				this.anim:update()
				this.pos.x+=this.spd.x
				if (this.pos.x<0) del(entities,this)
			end,
			draw=function(this)
				spr(this.anim:current(),this.pos.x,this.pos.y)
			end,
			remove=function(this)
				del(entities, this)
				del(shots, this)
			end
		}
		create_muzzle(x-1,y+3,6,3,11)
		add(entities,shot)
		add(shots,shot)
end

function should_create_wave()
	return (rnd(100)<=difficulty)
end

function enemy_should_fire()
	return (rnd(100)<=difficulty)
end
---------------
--- HELPERS ---
---------------

function abs_box(a)
	return {
		x1=a.pos.x+a.box.x,
		y1=a.pos.y+a.box.y,
		x2=a.pos.x+a.box.x+a.box.w,
		y2=a.pos.y+a.box.y+a.box.h
	}
end

-- collision detection
function spr_collide(a,b)
	local box_a=abs_box(a)
	local box_b=abs_box(b)
	return not(
		box_a.x1 > box_b.x2 or
		box_a.y1 > box_b.y2 or
		box_b.x1 > box_a.x2 or
		box_b.y1 > box_a.y2
	)
end

-- switch scene
function switch_scene(name)
	_init=_ENV[name.."_init"]
	_update=_ENV[name.."_update"]
	_draw=_ENV[name.."_draw"]
	_init()
end

-- adjusts entity position to make it on-screen
function adjust_pos(ent)
	local right=ent.box.x+ent.box.w
	local btm=ent.box.y+ent.box.h
	local newpos=ent.pos
	
	if newpos.x+right>128 then
		newpos.x=128-right
	elseif newpos.x+ent.box.x<0 then
		newpos.x=ent.box.x
	end
	if newpos.y+btm>128 then
		newpos.y=128-btm
	elseif newpos.y-ent.box.y<0 then
		newpos.y=-ent.box.y
	end
	return newpos
end

-- creates animation
-- seq is map of values (ie: {3,4,5})
-- s is ticks between animation frames
function anim(seq,s)
	return {
		t=0,
		f=1,
		s=s,
		seq=seq,
		update=function(this)
			this.t=(this.t+1)%this.s
			if (this.t==0) this.f=this.f%#this.seq+1
		end,
		current=function(this)
			return this.seq[this.f]
		end
	}
end

-- x position for a centered text string s
function hcenter(s)
  return 64-#s*2
end

-- y position for a centered text string
function vcenter()
  return 61
end

-----------------
--- STARFIELD ---
-----------------

-- create starfield
function create_starfield(n)
	-- create random stars
	local stars={}
	for i=1,n do
		star={
			pos={x=rnd(127),y=rnd(-10,137)},
			spd={x=rnd(4)+1,y=0},
			col=rnd({5,5,5,6})
		}
		add(stars,star)
	end
	
	local starfield={
		stars=stars,
		update=function(this)
			for s in all(this.stars) do
				s.pos.x-=(mid(1,s.spd.x+ship.spd.x/2,4))
				s.pos.y-=(mid(0,s.spd.y+ship.spd.y/2,4))
				if (s.pos.x<0) then
					s.pos.x=128
					s.pos.y=rnd(127)
				end
			end
		end,
		draw=function(this)
			for s in all(this.stars) do
				pset(s.pos.x,s.pos.y,s.col)
			end
		end
	}
	add(entities,starfield)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000022000002220000077220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700288220002882200088ee11000000000c000000070000000c000000000000000000000000000000000000000000000000000000000000000000000000
000770005288cc7022888c2028888820000007770000777c000000c7000000000000000000000000000000000000000000000000000000000000000000000000
00077000522888885528c78866652888000000c7000000cc00000cc707aaa0000000000000000000000000000000000000000000000000000000000000000000
007007002888222052888820655588220000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000222200000288220022888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000002882000028220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000bb300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b73600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b3366000000000070000000a0000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b66dd0097a00000aa970000a000000000bbbc7000bbb7c000000000000000000000000000000000000000000000000000000000000000000000000000000000
006555d08a000000a800000090000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00033300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000200000f750107501175014750157501a7501d7501f75024750297502f750007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000200001255011550105501055014550185501e55024550265502555021550007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000100001651016520165401655017550195601a5601d5601e5602056022560245502654026540265300d5002650026550265500d50025500255000d5000d5000d5000d5000d5000d500045000d5000d5000d500
000400000d6300e660126601a660186000b6500565002630026200261001640016300061002650026500765006640056200561000600006000060007600076000660005600036000260002600016000160001600
