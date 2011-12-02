require("strong")

function love.load()
	love.graphics.setColor(70,70,70,100)
	love.graphics.setColorMode("replace")
	rockwall = love.graphics.newImage("rockwall.png")
	spikes = love.graphics.newImage("spikes.png")
	zoom = 2
	speeds = {6,8,4}
	jumpspeed = -10
	jumping = false
	leftkey = "a"
	rightkey = "d"
	jumpkey = "w"
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
			collisions[a][b] = "empty"
			if level[a][b] == "b" then
				level[a][b] = rockwall
				collisions[a][b] = "block"
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
		getInput()
		move()
		manifestGravity()
		viewport(px,py)
	end
end

function getInput()
	if love.keyboard.isDown(rightkey) and xspeed < speed then
		xspeed = xspeed + 1
	end
	if love.keyboard.isDown(leftkey) and xspeed > 0-speed then
		xspeed = xspeed - 1
	end
	if not love.keyboard.isDown(leftkey,rightkey) then
		xspeed = 0
	end
	if jumping and (onblock(px-3,py) ~= "empty" or onblock(px-3,py+playerHeight) ~= "empty") and onblock(px,py+playerHeight+1) == "empty" and onblock(px+playerWidth,py+playerHeight+1) == "empty" then
		xspeed = speed+3
		yspeed = jumpspeed-1
	end
	if jumping and (onblock(px+playerWidth+3,py) ~= "empty" or onblock(px+playerWidth+3,py+playerHeight) ~= "empty") and onblock(px,py+playerHeight+1) == "empty" and onblock(px+playerWidth,py+playerHeight+1) == "empty" then
		xspeed = 0-speed-3
		yspeed = jumpspeed-1
	end
	if jumping and (onblock(px, py + playerHeight+1) ~= "empty" or onblock(px + playerWidth, py + playerHeight+1) ~= "empty") then
		py = py - 2
		yspeed = jumpspeed
	end
	if not love.keyboard.isDown(jumpkey) and yspeed < 0 then
		yspeed = yspeed/6 --ratio may need adjusting
	end
	jumping = false
end

function move()
	if xspeed > 0 then --going right
		if onblock(px + playerWidth + xspeed, py + playerHeight) == "empty" and onblock(px+playerWidth+xspeed,py) == "empty" then
			px = px + xspeed
		else
			xspeed = 0
		end
		if onblock(px + playerWidth + xspeed, py + playerHeight) == "slopeRight" then
			px = px + xspeed
			py = py + xspeed
		end
		if onblock(px + playerWidth + xspeed, py + playerHeight) == "slopeLeft" then
			px = px + xspeed
			py = py - xspeed
		end
		if onblock(px + playerWidth + xspeed, py + playerHeight) == "block" then
			xspeed = 0
		end
	end
	if xspeed < 0 then --going left
		if onblock(px + xspeed, py + playerHeight) == "empty" and onblock(px+xspeed,py) == "empty" then
			px = px + xspeed
		else
			xspeed = 0
		end
		if onblock(px + xspeed, py + playerHeight) == "slopeLeft" then
			px = px + xspeed
			py = py + xspeed
		end
		if onblock(px + playerWidth + xspeed, py + playerHeight) == "slopeRight" then
			px = px + xspeed
			py = py - xspeed
		end
		if onblock(px + playerWidth + xspeed, py + playerHeight) == "block" then
			xspeed = 0
		end
	end
end

function manifestGravity()
	if onblock(px, py + playerHeight+1) ~= "empty" and onblock(px + playerWidth, py + playerHeight+1) ~= "empty" then
		yspeed = 0
	else
		yspeed = yspeed + gravity
	end
	if yspeed > 8 then yspeed = 8 end
	if yspeed > 0 then
		if onblock(px, py + playerHeight + yspeed) == "empty" and onblock(px + playerWidth, py + playerHeight + yspeed) == "empty" then 
			py = py + yspeed
		else
			yspeed = 0
		end
	end
	if yspeed < 0 then
		if onblock(px, py + yspeed) == "empty" and onblock(px + playerWidth, py + yspeed) == "empty" then 
			py = py + yspeed
		else
			yspeed = 0
		end
	end
end

function viewport(x,y)
	vx = x
	vy = y
	if vx > levelwidth*32-love.graphics.getWidth() then vx = levelwidth*32-love.graphics.getWidth() end
	if vy > levelheight*32-love.graphics.getHeight() then vy = levelheight*32-love.graphics.getHeight() end
	if vx < love.graphics.getWidth()/2 then vx = love.graphics.getWidth()/2 end
	if vy < love.graphics.getHeight()/2 then vy = love.graphics.getHeight()/2 end
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
		love.graphics.rectangle("fill",px-vx+512,py-vy+320,playerWidth,playerHeight)
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
		return collisions[xcell][ycell]
	else
		return "empty"
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
	local n = math.random(1,#spawnpoints)
	px = (spawnpoints[n][1])*32+1
	py = (spawnpoints[n][2])*32-60
	vx = x
	vy = y
	gravity = 0.4
	xspeed = 0
	yspeed = 0
	playerWidth = 30
	playerHeight = 60
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
	if key == jumpkey and gamestate == "playing" then
		jumping = true
	end
	if key == "z" and gamestate == "playing" then
		gamestate = "choosecharacter"
	end
	if key == "x" and gamestate == "playing" then
		gamestate = "mainmenu"
	end
	if key == "escape" or key == "p" then
		if gamestate == "playing" then
			gamestate = "paused"
		elseif gamestate == "paused" then
			gamestate = "playing"
		end
	end
end