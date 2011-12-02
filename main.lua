require("strong")

function love.load()
	love.graphics.setColor(70,70,70,100)
	love.graphics.setColorMode("replace")
	rockwall = love.graphics.newImage("rockwall.png")
	spikes = love.graphics.newImage("spikes.png")
	zoom = 2
	speeds = {6,8,4}
	jumpspeed = 8
	leftkey = "left"
	rightkey = "right"
	jumpkey = " "
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
		if love.keyboard.isDown(leftkey) then
			xspeed = xspeed - 0.4
			if xspeed < 0 - speed then
				xspeed = 0 - speed
			end
		end
		if love.keyboard.isDown(rightkey) then
			xspeed = xspeed + 0.4
			if xspeed > speed then
				xspeed = speed
			end
		end
		yspeed = yspeed + 0.3
		for n=1,2 do
			if n == 1 then px = px + 3 end
			if n == 2 then px = px - 6 end
			if playeronblock("down") or playeronblock("left") or playeronblock("right") then
				canjump = 1
			end
			if n == 2 then px = px + 3
			end
		end
		if love.keyboard.isDown(jumpkey) then
			if canjump == 1 then
				yspeed = 0 - jumpspeed
				if onblock(px-16+xspeed-4,py-16) then
					if love.keyboard.isDown(leftkey) then
						xspeed = speed/2
					elseif love.keyboard.isDown(rightkey) then
						xspeed = speed*2
					end
					yspeed = 0-jumpspeed-1
				end
				if onblock(px+16+xspeed+4,py-16) then
					if love.keyboard.isDown(leftkey) then
						xspeed = 0-speed*2
					elseif love.keyboard.isDown(rightkey) then
						xspeed = 0-speed/2
					end
					yspeed = 0-jumpspeed-1
				end
			end
		end
		if playeronblock("left") or playeronblock("right") or not (love.keyboard.isDown(leftkey) or love.keyboard.isDown(rightkey)) or (love.keyboard.isDown(leftkey) and love.keyboard.isDown(rightkey)) then
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
	if gamestate == "playing" or gamestate == "paused" then
		love.graphics.draw(background,0,0)
		for a=1,levelwidth do
			for b=1,levelheight do
				if level[a][b] ~= 0 then
					level[a][b]:setFilter("nearest", "nearest")
					love.graphics.draw(level[a][b],(b-1)*32-vx+512,(a-1)*32-vy+320)
				end
			end
		end
		love.graphics.rectangle("fill",px-16-vx+512,py-16-vy+320,32,32)
		love.graphics.print("class: "..characternames[characternum].."\ntype: "..types[charactertype],0,0)
	end
	if gamestate == "paused" then
		love.graphics.rectangle("fill",0,0,love.graphics.getWidth(),love.graphics.getHeight())
		love.graphics.printf("PAUSED",0,love.graphics.getHeight()/2,love.graphics.getWidth(),"center")
	end
end

function onblock(x,y)
	local xcell = math.ceil(y/32)
	local ycell = math.ceil(x/32)
	if xcell < levelwidth+1 and ycell < levelheight+1 and xcell > 0 and ycell > 0 then
		return collisions[xcell][ycell] == 1
	else
		return 1
	end
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
	math.randomseed(os.time())
	local n = math.random(#spawnpoints)
	px = (spawnpoints[n][1])*32-16
	py = (spawnpoints[n][2])*32-16
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
	--if key == jumpkey and gamestate == "playing" and canjump == 1 then
	--	yspeed = 0 - jumpspeed
	--	if onblock(px-16+xspeed-4,py-16) then
	--		xspeed = speed
	--	end
	--	if onblock(px+16+xspeed+4,py-16) then
	--		xspeed = 0-speed
	--	end
	--end
	if key == "escape" or key == "p" then
		if gamestate == "playing" then
			gamestate = "paused"
		elseif gamestate == "paused" then
			gamestate = "playing"
		end
	end
end

function love.keyreleased(key)
	if key == jumpkey and yspeed then
		yspeed = math.abs(yspeed)/6
	end
end