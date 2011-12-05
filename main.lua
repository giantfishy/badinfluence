require("strong")

function love.load()
	love.graphics.setColor(70,70,70,100)
	love.graphics.setColorMode("replace")
	rockwall = love.graphics.newImage("rockwall.png")
	rockwallbg = love.graphics.newImage("rockwallbg.png")
	spikes = love.graphics.newImage("spikes.png")
	playboy = love.graphics.newImage("characters/playboy.png")
	click = love.audio.newSource("click.ogg", "static")
	zoom = 2
	speeds = {6,8,4}
	jumpspeed = -10
	jumping = false
	leftkey = "a"
	rightkey = "d"
	jumpkey = "w"
	usekey = "lshift"
	characternames = {"fool","playboy","eccentric","psychopath","liar","traveller","agent","lunatic","hitman","doctor","convict","alcoholic"}
	characternum = 1
	types = {"ganker","flanker","tanker"}
	font = love.graphics.newFont("london.ttf", 18)
	love.graphics.setFont(font)
	leveltoload = 1
	gamestate = "mainmenu"
end

function loadlevel(filename)
	level = {}
	objects = {}
	collisions = {}
	properties = {}
	spawnpoints = {}
	local levelfile = love.filesystem.newFile(filename)
	levelfile:open("r")
	local contents = levelfile:read()
	local a = 0
	for line in contents:lines("\n") do
		if a > 0 then
			level[a] = line / "."
			objects[a] = {}
			for b=1,#level[a] do
				if level[a][b](2) then
					objects[a][b] = level[a][b](2)
					level[a][b] = level[a][b](1)
				else
					objects[a][b] = " "
				end
			end
		else
			if a == 0 then
				background = love.graphics.newImage(line)
			end
		end
		a = a + 1
	end
	levelwidth = #level
	levelheight = #level[1]
	for a=1,levelwidth do
		collisions[a] = {}
		properties[a] = {}
		for b=1,levelheight do
			collisions[a][b] = "empty"
			if level[a][b] == "b" then
				level[a][b] = rockwall
				collisions[a][b] = "block"
			end
			if level[a][b] == "w" then 
				level[a][b] = spikes
				properties[a][b] = 0
				if a > 1 and a < levelwidth and b > 1 and b < levelheight then
					if level[a-1][b] == rockwall then properties[a][b] = 180 end
					if level[a][b-1] == rockwall then properties[a][b] = 90 end
					if level[a][b+1] == "b" then properties[a][b] = 270 end
					if level[a+1][b] == "b" then properties[a][b] = 0 end
				else
					if a == 1 and not (b == 1 or b == levelheight) then
						properties[a][b] = 180
						if level[a][b-1] == rockwall then properties[a][b] = 90 end
						if level[a][b+1] == "b" then properties[a][b] = 270 end
						if level[a+1][b] == "b" then properties[a][b] = 0 end
					end
					if b == 1 and not (a == 1 or a == levelwidth) then
						properties[a][b] = 90
						if level[a-1][b] == rockwall then properties[a][b] = 180 end
						if level[a][b+1] == "b" then properties[a][b] = 270 end
						if level[a+1][b] == "b" then properties[a][b] = 0 end
					end
					if b == levelheight and not (a == 1 or a == levelwidth) then
						properties[a][b] = 270
						if level[a-1][b] == rockwall then properties[a][b] = 180 end
						if level[a][b-1] == rockwall then properties[a][b] = 90 end
						if level[a+1][b] == "b" then properties[a][b] = 0 end
					end
					if a == levelwidth and not (b == 1 or b == levelheight) then
						properties[a][b] = 0
						if level[a-1][b] == rockwall then properties[a][b] = 180 end
						if level[a][b-1] == rockwall then properties[a][b] = 90 end
						if level[a][b+1] == "b" then properties[a][b] = 270 end
					end
				end
			end
			if level[a][b] == " " then level[a][b] = 0 end
			if level[a][b] == "#" then
				table.insert(spawnpoints,{b,a})
				level[a][b] = 0
			end
			if objects[a][b] == "b" then objects[a][b] = rockwallbg end
			if objects[a][b] == " " then objects[a][b] = 0 end
		end
	end
	gamestate = "choosecharacter"
end

function getlevels()
	local files = love.filesystem.enumerate("")
	local levels = {}
	for n=1,#files do
		if tostring(files[n]):endsWith(".txt") then
			table.insert(levels,tostring(files[n])-".txt")
		end
	end
	return levels
end

function love.update(dt)
	mx = love.mouse.getX()
	my = love.mouse.getY()
	if gamestate == "playing" then
		getInput()
		move()
		manifestGravity()
		viewport(px,py)
	end
	if gamestate == "mainmenu" then
		local previouslevel = leveltoload
		if my > 40 and my < 30+#getlevels()*18 then
			leveltoload = math.floor((my-22)/18)
		else
			if my < 41 then
				leveltoload = 1
			else
				leveltoload = #getlevels()
			end
		end
		if previouslevel ~= leveltoload then love.audio.play(click) end
	end
end

function getInput()
	if love.keyboard.isDown(rightkey) and xspeed < speed then
		xspeed = xspeed + 1
	end
	if love.keyboard.isDown(leftkey) and xspeed > 0-speed then
		xspeed = xspeed - 1
	end
	if not love.keyboard.isDown(leftkey,rightkey) or (love.keyboard.isDown(leftkey) and love.keyboard.isDown(rightkey)) then
		xspeed = 0
	end
	if jumping and (onblock(px-3,py) ~= "empty" or onblock(px-3,py+playerHeight) ~= "empty") and onblock(px,py+playerHeight+1) == "empty" and onblock(px+playerWidth,py+playerHeight+1) == "empty" then
		xspeed = speed+1
		yspeed = jumpspeed-2
	end
	if jumping and (onblock(px+playerWidth+3,py) ~= "empty" or onblock(px+playerWidth+3,py+playerHeight) ~= "empty") and onblock(px,py+playerHeight+1) == "empty" and onblock(px+playerWidth,py+playerHeight+1) == "empty" then
		xspeed = 0-speed-1
		yspeed = jumpspeed-2
	end
	if jumping and (onblock(px, py + playerHeight+1) ~= "empty" or onblock(px + playerWidth, py + playerHeight+1) ~= "empty") then
		py = py - 2
		yspeed = jumpspeed
	end
	if not love.keyboard.isDown(jumpkey) and yspeed < 0 then
		yspeed = yspeed/6
	end
	jumping = false
end

function move()
	if xspeed > 0 then
		if onblock(px + playerWidth + xspeed, py + playerHeight) == "empty" and onblock(px+playerWidth+xspeed,py) == "empty" and onblock(px+playerWidth+xspeed,py+playerHeight/2) then
			px = px + xspeed
		else
			xspeed = 0
			if love.keyboard.isDown(rightkey) then
				if charactertype == 1 and yspeed > 2.5 then yspeed = 2.5 end
				if charactertype == 2  then yspeed = 0-gravity end
			end
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
	if xspeed < 0 then
		if onblock(px + xspeed, py + playerHeight) == "empty" and onblock(px+xspeed,py) == "empty" and onblock(px+xspeed,py+playerHeight/2) then
			px = px + xspeed
		else
			xspeed = 0
			if love.keyboard.isDown(leftkey) then
				if charactertype == 1 and yspeed > 2.5 then yspeed = 2.5 end
				if charactertype == 2 then yspeed = 0-gravity end
			end
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
	if invincibletimer > -1 then invincibletimer = invincibletimer - 1 end
	if (levelat(px+playerWidth/2,py+playerHeight-4) == spikes or levelat(px+playerWidth/2,py+4) == spikes) and invincibletimer < 0 then
		health = health - 200
		setinvincible(60)
	end
	if levelat(px+playerWidth/2,py+playerHeight/2) == "offlevel" or health < 1 then
		changecharacter(characternum)
	end
	if charactertype == 3 and health < maxhealth then
		health = health + 0.4
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
			local distance = 1
			while onblock(px,py+playerHeight+distance) == "empty" and onblock(px+playerWidth,py+playerHeight+distance) == "empty" do
				distance = distance + 1
			end
			py = py + distance-1
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
	if vx > levelheight*32-love.graphics.getWidth()/2 then vx = levelheight*32-love.graphics.getWidth()/2 end
	if vy > levelwidth*32-love.graphics.getHeight()/2 then vy = levelwidth*32-love.graphics.getHeight()/2 end
	if vx < love.graphics.getWidth()/2 then vx = love.graphics.getWidth()/2 end
	if vy < love.graphics.getHeight()/2 then vy = love.graphics.getHeight()/2 end
end

function toRadians(num)
	return num*(math.pi/180)
end

function love.draw()
	if gamestate == "mainmenu" then
		love.graphics.print("pick a level:",2,2)
		love.graphics.setColor(50,50,50)
		love.graphics.rectangle("fill",0,22+leveltoload*18,200,18)
		love.graphics.setColor(70,70,70,100)
		for a=1,#getlevels() do
			love.graphics.print(getlevels()[a],2,22+a*18)
		end
	end
	if gamestate == "choosecharacter" then
		love.graphics.print("current class is "..characternames[characternum]..".\nleft and right to change character, space to select character\nthis screen is very much a wip",0,0)
	end
	if gamestate == "playing" or gamestate == "paused" then
		love.graphics.draw(background,0,0)
		for a=math.floor((vy-love.graphics.getHeight()/2)/32),math.ceil((vy+love.graphics.getHeight()/2)/32) do
			for b=math.floor((vx-love.graphics.getWidth()/2)/32),math.ceil((vx+love.graphics.getWidth()/2)/32) do
				if a > 0 and a < levelwidth+1 and b > 0 and b < levelheight+1 then
					if objects[a][b] == rockwallbg then love.graphics.draw(rockwallbg,(b-1)*32-vx+512,(a-1)*32-vy+320) end
					if level[a][b] ~= 0 then
						level[a][b]:setFilter("nearest", "nearest")
						if level[a][b] == spikes then
							love.graphics.draw(spikes,(b-1)*32-vx+512+16,(a-1)*32-vy+320+16,toRadians(properties[a][b]),1,1,16,16)
						else
							love.graphics.draw(level[a][b],(b-1)*32-vx+512,(a-1)*32-vy+320)
						end
					end
					if objects[a][b] ~= 0 and objects[a][b] ~= rockwallbg then
						objects[a][b]:setFilter("nearest","nearest")
						love.graphics.draw(objects[a][b],(b-1)*32-vx+512,(a-1)*32-vy+320)
					end
				end
			end
		end
		local flash = math.floor(invincibletimer/6)
		if invincibletimer < 0 or flash/3 ~= math.floor(flash/3) then
			love.graphics.draw(playboy,px-1-vx+512,py-4-vy+320)
		end
		love.graphics.setColor(0,0,0)
		love.graphics.rectangle("fill",px-vx+512,py-8-vy+320,playerWidth,4)
		love.graphics.setColor(250,150,50)
		love.graphics.rectangle("fill",px-vx+512,py-8-vy+320,health/maxhealth*playerWidth,4)
		--if invincibletimer > 0 then
		--	love.graphics.setColor(255,255,100,100)
		--	love.graphics.rectangle("fill",px-1-vx+512,py-9-vy+320,invincibletimer/invincible*(playerWidth+2),6)
		--end
		love.graphics.setColor(70,70,70,100)
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

function levelat(x,y)
	local xcell = math.ceil(y/32)
	local ycell = math.ceil(x/32)
	if xcell < levelwidth+1 and ycell < levelheight+1 and xcell > 0 and ycell > 0 then
		return level[xcell][ycell]
	else
		if xcell > levelwidth then
			return "offlevel"
		else
			return "offscreen"
		end
	end
end

function setinvincible(time)
	invincibletimer = time
	invincible = time
end

function changecharacter(newnum)
	if newnum > 12 then newnum = 1 end
	if newnum < 1 then newnum = 12 end
	characternum = newnum
	charactertype = math.ceil(characternum/4)
	speed = speeds[charactertype]
	if characternames[characternum] == "doctor" then
		speed = speed + 1
	end
	math.randomseed(os.time())
	math.random();math.random();math.random()
	local n = math.random(1,#spawnpoints)
	px = (spawnpoints[n][1])*32-29
	py = (spawnpoints[n][2])*32-60
	vx = x
	vy = y
	gravity = 0.35
	xspeed = 0
	yspeed = 0
	playerWidth = 30
	playerHeight = 60
	if charactertype == 1 then maxhealth = 100 end
	if charactertype == 2 then maxhealth = 50 end
	if charactertype == 3 then maxhealth = 150 end
	health = maxhealth
	setinvincible(100)
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

function love.mousepressed(x,y,button)
	if gamestate == "mainmenu" and button == "l" then
		local levelfile = getlevels()[leveltoload]..".txt"
		loadlevel(levelfile)
	end
end