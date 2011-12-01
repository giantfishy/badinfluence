require("strong")

function love.load()
	love.graphics.setColor(0,40,0,150)
	--love.graphics.setColor(255,255,255)
	love.graphics.setColorMode("replace")
	rockwall = love.graphics.newImage("rockwall.png")
	spikes = love.graphics.newImage("spikes.png")
	zoom = 2
	speeds = {4,6,3}
	characternames = {"fool","playboy","eccentric","psychopath","liar","traveller","agent","lunatic","hitman","doctor","convict","alcoholic"}
	characternum = 1
	types = {"ganker","flanker","tanker"}
	font = love.graphics.newFont("london.ttf", 18)
	love.graphics.setFont(font)
	leveltoload = ""
	gamestate = "mainmenu"
end

function loadlevel(filename)
	level = {}
	collisions = {}
	spawnpoints = {}
	local levelfile = love.filesystem.newFile(filename)
	levelfile:open("r")
	local contents = levelfile:read()
	local a = 0
	for line in contents:lines("\n") do
		if a > 0 then
			level[a] = line / "."
		else
			if a == 0 then
				background = love.graphics.newImage(line)
			end
		end
		a = a + 1
	end
	levelwidth = # level
	levelheight = # level[1]
	for a=1,levelwidth do
		collisions[a] = {}
		for b=1,levelheight do
			collisions[a][b] = 0
			if level[a][b] == "b" then
				level[a][b] = rockwall
				collisions[a][b] = 1
			end
			if level[a][b] == "w" then level[a][b] = spikes end
			if level[a][b] == " " then level[a][b] = 0 end
			if level[a][b] == "#" then
				table.insert(spawnpoints,{b,a})
				level[a][b] = 0
			end
		end
	end
	gamestate = "choosecharacter"
end

function love.update(dt)
	if gamestate == "playing" then
		canjump = 0
		if love.keyboard.isDown("a") then
			xspeed = xspeed - 0.4
			if xspeed < 0 - speed then
				xspeed = 0 - speed
			end
		end
		if love.keyboard.isDown("d") then
			xspeed = xspeed + 0.4
			if xspeed > speed then
				xspeed = speed
			end
		end
		yspeed = yspeed + 0.2
		for n=1,2 do
			if n == 1 then px = px + 3 end
			if n == 2 then px = px - 6 end
			if playeronblock("down") or playeronblock("up") or playeronblock("left") or playeronblock("right") then
				canjump = 1
			end
			if n == 2 then px = px + 3
			end
		end
		if playeronblock("left") or playeronblock("right") or not (love.keyboard.isDown("a") or love.keyboard.isDown("d")) or (love.keyboard.isDown("a") and love.keyboard.isDown("d")) then
			xspeed = 0
		end
		if playeronblock("down") or playeronblock("up") then
			yspeed = 0
		end
		px = px + xspeed
		py = py + yspeed
		vx = px
		vy = py
		if vx > levelwidth*32-love.graphics.getWidth() then vx = levelwidth*32-love.graphics.getWidth() end
		if vy > levelheight*32-love.graphics.getHeight() then vy = levelheight*32-love.graphics.getHeight() end
		if vx < love.graphics.getWidth()/2 then vx = love.graphics.getWidth()/2 end
		if vy < love.graphics.getHeight()/2 then vy = love.graphics.getHeight()/2 end
	end
end

function love.draw()
	if gamestate == "mainmenu" then
		love.graphics.print("level to load:\n"..leveltoload,10,10)
	end
	if gamestate == "choosecharacter" then
		love.graphics.print("current class is "..characternames[characternum]..".\nleft and right to change character, space to select character\nthis screen is very much a wip",0,0)
	end
	if gamestate == "playing" then
		love.graphics.draw(background,0,0)
		for a=1,levelwidth do
			for b=1,levelheight do
				if level[a][b] ~= 0 then
					--level[a][b]:setFilter("nearest", "nearest")
					love.graphics.draw(level[a][b],(b-1)*32-vx+512,(a-1)*32-vy+320)
				end
			end
		end
		love.graphics.rectangle("fill",px-16-vx+512,py-16-vy+320,32,32)
		love.graphics.print("class: "..characternames[characternum].."\ntype: "..types[charactertype],0,0)
	end
end

function onblock(x,y)
	local xcell = math.ceil(y/32)
	local ycell = math.ceil(x/32)
	return collisions[xcell][ycell] == 1
end

function playeronblock(direction)
	if direction == "down" then
		return onblock(px+12,py+16+yspeed) or onblock(px-12,py+16+yspeed)
	end
	if direction == "up" then
		return onblock(px+12,py-16+yspeed) or onblock(px-12,py-16+yspeed)
	end
	if direction == "left" then
		return onblock(px-16+xspeed-2,py+12) or onblock(px-16+xspeed-2,py-12)
	end
	if direction == "right" then
		return onblock(px+16+xspeed+2,py+12) or onblock(px+16+xspeed+2,py-12)
	end
end

function changecharacter(newnum)
	if newnum > 12 then newnum = 1 end
	if newnum < 1 then newnum = 12 end
	characternum = newnum
	charactertype = math.ceil(characternum/4)
	speed = speeds[charactertype]
	if characternames[characternum] == "doctor" then
		speed = speed + 0.5
	end
	jumpspeed = 8
	math.randomseed(os.time())
	px = (spawnpoints[math.random(# spawnpoints)][1])*32-16
	py = (spawnpoints[math.random(# spawnpoints)][2])*32-16
	vx = x
	vy = y
	xspeed = 0
	yspeed = 0
	if playeronblock("left") then
		px = px + 4
	end
	if playeronblock("right") then
		px = px - 4
	end
	if playeronblock("up") then
		py = py + 4
	end
	if playeronblock("down") then
		py = py - 4
	end
end

function deletelastchar(string)
	local result = ""
	local list = {}
	for s in string:chars() do
		table.insert(list,s)
	end
	table.remove(list,#list)
	for n=1,#list do
		result = result..list[n]
	end
	return result
end

function love.keypressed(key)
	if gamestate == "mainmenu" then
		if key == "delete" or key == "backspace" then
			leveltoload = deletelastchar(leveltoload)
		else
			if key(2) == nil then
				if love.keyboard.isDown("lshift","rshift") then
					leveltoload = leveltoload..key:capitalize()
				else
					leveltoload = leveltoload..key
				end
			else
				if key == "return" or key == "kpenter" then
					if not leveltoload:endsWith(".txt") then
						leveltoload = leveltoload..".txt"
					end
					loadlevel(leveltoload)
				end
			end
		end
	end
	if key == "left" and gamestate == "choosecharacter" then
		changecharacter(characternum - 1)
	end
	if key == "right" and gamestate == "choosecharacter" then
		changecharacter(characternum + 1)
	end
	if key == " " and gamestate == "choosecharacter" then
		changecharacter(characternum)
		gamestate = "playing"
	end
	if key == "z" and gamestate == "playing" then
		gamestate = "choosecharacter"
	end
	if key == "w" and gamestate == "playing" and canjump == 1 then
		yspeed = 0 - jumpspeed
		if onblock(px-16+xspeed-4,py-16) then
			xspeed = speed
		end
		if onblock(px+16+xspeed+4,py-16) then
			xspeed = 0-speed
		end
	end
	if key == "escape" or key == "p" then
		if gamestate == "playing" then gamestate = "paused" end
		if gamestate == "paused" then gamestate = "playing" end
	end
end