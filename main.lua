require("strong")

function love.load()
	love.graphics.setBackgroundColor(30,30,30)
	love.graphics.setColor(70,70,70,100)
	love.graphics.setColorMode("replace")
	rockwall = love.graphics.newImage("rockwall.png")
	rockwallbg = love.graphics.newImage("rockwallbg.png")
	slopeleft = love.graphics.newImage("slopeleft.png")
	sloperight = love.graphics.newImage("sloperight.png")
	ceilingleft = love.graphics.newImage("ceill.png")
	ceilingright = love.graphics.newImage("ceilr.png")
	spikes = love.graphics.newImage("spikes.png")
	frame = 1
	animationlengths = {1,6,4,1}
	music1 = love.audio.newSource("sounds/melody.ogg")
	music2 = love.audio.newSource("sounds/ingame.ogg")
	musicswap = 1
	musicswapspeed = 0
	music1:setLooping(true)
	music2:setLooping(true)
	music1:play()
	music2:play()
	click = love.audio.newSource("sounds/click.ogg", "static")
	vx = 0
	vy = 0
	zoom = 2
	speeds = {6,8,4}
	jumpspeed = -10
	jumping = false
	leftkey = "a"
	rightkey = "d"
	jumpkey = "w"
	usekey = "lshift"
	joystickleft = 2
	joystickright = 3
	joystickjump = 8
	characternames = {"fool","playboy","eccentric","psychopath","liar","traveller","agent","lunatic","hitman","doctor","convict","alcoholic"}
	characternum = 1
	types = {"ganker","flanker","tanker"}
	charsprites = {}
	arms = {}
	for n=1,12 do
		charsprites[n] = love.graphics.newImage("characters/"..characternames[n]..".png")
		arms[n] = love.graphics.newImage("characters/arms/"..characternames[n]..".png")
	end
	types = {"ganker","flanker","tanker"}
	font = love.graphics.newFont("fonts/london.ttf",18)
	love.graphics.setFont(font)
	leveltoload = 1
	gamestate = "mainmenu"
end

function swapmusic(num)
	if num == 1 then musicswapspeed = 0.01 end
	if num == 2 then musicswapspeed = -0.01 end
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
	local a = -1
	for line in contents:lines("\n") do
		line = line:chomp()
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
			if a == -1 then
				if line == "true" then wrap = true else wrap = false end
			end
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
			if level[a][b] == "<" then
				level[a][b] = sloperight
				collisions[a][b] = "slopeRight"
			end
			if level[a][b] == ">" then
				level[a][b] = slopeleft
				collisions[a][b] = "slopeLeft"
			end
			if level[a][b] == "{" then
				level[a][b] = ceilingleft
				collisions[a][b] = "empty"
			end
			if level[a][b] == "}" then
				level[a][b] = ceilingright
				collisions[a][b] = "empty"
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
	local files = love.filesystem.enumerate("levels/")
	local otherfiles = love.filesystem.enumerate("")
	local levels = {}
	for n=1,#files do
		if tostring(files[n]):endsWith(".txt") then
			table.insert(levels,"levels/"..tostring(files[n])-".txt")
		end
	end
	for n=1,#otherfiles do
		if tostring(otherfiles[n]):endsWith(".txt") then
			table.insert(levels,tostring(otherfiles[n])-".txt")
		end
	end
	return levels
end

function love.update(dt)
	mx = love.mouse.getX()
	my = love.mouse.getY()
	setMusicVolumes()
	if gamestate == "playing" then
		getInput()
		move(dt)
		manifestGravity()
		animate(dt)
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

function setMusicVolumes()
	musicswap = musicswap + musicswapspeed
	if musicswap < 0 then musicswap = 0; musicswapspeed = 0 end
	if musicswap > 1 then musicswap = 1; musicswapspeed = 0 end
	music1:setVolume(musicswap)
	music2:setVolume(1-musicswap)
end

function getInput()
	if love.joystick.isOpen(0) and vx and vy then
		local x = love.joystick.getAxis(0,2)
		local y = love.joystick.getAxis(0,3)
		if math.abs(x) > 0.3 or math.abs(y) > 0.3 then
			love.mouse.setPosition(px+playerWidth/2-vx+512+x*200,py+playerHeight/2-vy+320+y*200)
		end
	end
	animation = 1
	sliding = false
	if love.keyboard.isDown(rightkey) and xspeed < speed then
		xspeed = xspeed + 1
	end
	if love.keyboard.isDown(leftkey) and xspeed > 0-speed then
		xspeed = xspeed - 1
	end
	if not love.keyboard.isDown(leftkey,rightkey) or (love.keyboard.isDown(leftkey) and love.keyboard.isDown(rightkey)) then
		xspeed = 0
	end
	if (((onblock(px-3,py) ~= "empty" and onblock(px-3,py+playerHeight) ~= "empty") and not love.keyboard.isDown(leftkey)) or ((onblock(px+playerWidth+3,py) ~= "empty" and onblock(px+playerWidth+3,py+playerHeight) ~= "empty") and not love.keyboard.isDown(rightkey))) and onblock(px+playerWidth/2,py+playerHeight+4) == "empty" then
		sliding = true
		animation = 4
		xspeed = xspeed/8
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

function move(dt)
	if animation ~= 4 then animation = 1 end
	if xspeed > 0 then
		animation = 2
		if onblock(px + playerWidth + xspeed, py + playerHeight - 2) ~= "block" and onblock(px+playerWidth+xspeed,py) ~= "block" and onblock(px+playerWidth+xspeed,py+playerHeight/2) ~= "block" then
			px = px + xspeed
		else
			animation = 1
			xspeed = 0
			if love.keyboard.isDown(rightkey) and onblock(px+playerWidth+2,py+playerHeight) == "block" and onblock(px+playerWidth+2,py) == "block" then
				sliding = true
				direction = "left"
				animation = 4
				if charactertype == 1 and yspeed > 2.5 then yspeed = 2.5 end
				if charactertype == 2 then 
					if onblock(px+playerWidth+2,py+playerHeight) == "block" and onblock(px+playerWidth+2,py) == "block" then 
						yspeed = 0-gravity 
					else
						if yspeed > 2.5 then yspeed = 2.5 end
					end
				end
			end
		end
	end
	if xspeed < 0 then
		animation = 2
		if onblock(px + xspeed, py + playerHeight - 2) ~= "block" and onblock(px+xspeed,py) ~= "block" and onblock(px+xspeed,py+playerHeight/2) ~= "block" then
			px = px + xspeed
		else
			animation = 1
			xspeed = 0
			if love.keyboard.isDown(leftkey) and onblock(px-2,py+playerHeight) == "block" and onblock(px-2,py) == "block" then
				sliding = true
				direction = "right"
				animation = 4
				if charactertype == 1 and yspeed > 2.5 then yspeed = 2.5 end
				if charactertype == 2 then 
					if onblock(px-2,py+playerHeight) == "block" and onblock(px-2,py) == "block" then 
						yspeed = 0-gravity 
					else
						if yspeed > 2.5 then yspeed = 2.5 end
					end
				end
			end
		end
	end
	if yspeed ~= 0 and animation ~= 4 then animation = 3 end
	if invincibletimer > -1 then invincibletimer = invincibletimer - 1 end
	if (levelat(px+playerWidth/2,py+playerHeight-4) == spikes or levelat(px+playerWidth/2,py+4) == spikes) and invincibletimer < 0 then
		health = health - 200
		setinvincible(60)
	end
	if levelat(px+playerWidth/2,py+playerHeight/2) == "offscreen" and wrap then
		if px < 0-playerWidth/2 then px = levelheight*32-playerWidth/2 end
		if px > levelheight*32-playerWidth/2 then px = 0-playerWidth/2 end
	end
	drawmirror = false
	if levelat(px,py) == "offscreen" and wrap then
		drawmirror = true
		mirrorx = levelheight*32+px
		mirrory = py
	end
	if levelat(px+playerWidth,py) == "offscreen" and wrap then
		drawmirror = true
		mirrorx = px-levelheight*32
		mirrory = py
	end
	if levelat(px+playerWidth/2,py+playerHeight/2) == "offlevel" or health < 1 then
		changecharacter(characternum)
	end
	if charactertype == 3 and health < maxhealth then
		health = health + 0.4
	end
end

function manifestGravity()
	if onblock(px, py + playerHeight+1) == "block" or onblock(px + playerWidth, py + playerHeight+1) == "block" then
		yspeed = 0
	else
		yspeed = yspeed + gravity
	end
	if yspeed > 8 then yspeed = 8 end
	if onblock(px-2,py+playerHeight-4) ~= "block" and onblock(px,py+playerHeight) == "slopeLeft" and love.keyboard.isDown(leftkey) then
		px = px - 2
		py = py - 4
	end
	if onblock(px-2,py+playerHeight-4) ~= "block" and onblock(px,py+playerHeight) == "slopeRight" and love.keyboard.isDown(rightkey) then
		px = px + 2
		py = py - 4
	end
	if onblock(px,py+playerHeight) == "slopeLeft" or onblock(px,py+playerHeight-2) == "slopeLeft" then
		py = py - 2
		local xcell = math.ceil((py+playerHeight)/32)
		local ycell = math.ceil(px/32)
		if love.keyboard.isDown(leftkey,rightkey) then animation = 2 else animation = 1 end
		if px-(ycell-1)*32 < py+playerHeight-(xcell-1)*32 then
			py = xcell*32-(ycell*32-px)-playerHeight+2
			yspeed = 0
		else
			py = py + 2
		end
	end
	if onblock(px+playerWidth,py+playerHeight) == "slopeRight" or onblock(px+playerWidth,py+playerHeight-2) == "slopeRight" then
		py = py - 2
		local xcell = math.ceil((py+playerHeight)/32)
		local ycell = math.ceil((px+playerWidth)/32)
		if love.keyboard.isDown(leftkey,rightkey) then animation = 2 else animation = 1 end
		if px-(ycell-1)*32 > xcell*32-py+playerHeight then
			py = xcell*32-px-(ycell-1)*32-playerHeight+2
			yspeed = 0
		else
			py = py + 2
		end
	end
	if yspeed > 0 then
		if onblock(px, py + playerHeight + yspeed) ~= "block" and onblock(px + playerWidth, py + playerHeight + yspeed) ~= "block" then 
			py = py + yspeed
		else
			local distance = 1
			while onblock(px,py+playerHeight+distance) ~= "block" and onblock(px+playerWidth,py+playerHeight+distance) ~= "block" do
				distance = distance + 1
			end
			py = py + distance-1
			yspeed = 0
		end
	end
	if yspeed < 0 then
		if onblock(px, py + yspeed) ~= "block" and onblock(px + playerWidth, py + yspeed) ~= "block" then 
			py = py + yspeed
		else
			yspeed = 0
		end
	end
end

function animate(dt)
	playerquad = love.graphics.newQuad((math.floor(frame)-1)*32,(animation-1)*64,32,64,192,256)
	viewport(px,py)
	if sliding == false then
		direction = "right"
		if mx < px+(playerWidth/2)-1-vx+512 then direction = "left" end
	end
	local framedelay = 0.1
	if animation == 2 then framedelay = 0.6/math.abs(xspeed) end
	if animation == 3 then framedelay = 0.8/(0-yspeed) end
	if ((direction == "left" and love.keyboard.isDown(rightkey)) or (direction == "right" and love.keyboard.isDown(leftkey))) and animation == 2 then
		framedelay = framedelay * -1
	end
	frame = (frame + dt/framedelay)
	if frame > animationlengths[animation]+1 then
		frame = 1
		if animation == 3 then frame = 4 end
	end
	if frame < 1 then
		frame = animationlengths[animation]
		if animation == 3 then frame = 1 end
	end
end

function viewport(x,y)
	vx = math.floor(x)
	vy = math.floor(y)
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
			if getlevels()[a]:startsWith("levels/") then
				love.graphics.print(getlevels()[a]-"levels/",2,22+a*18)
			else
				love.graphics.print(getlevels()[a],2,22+a*18)
			end
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
		local flip = 1
		if direction == "left" then flip = -1 end
		local flash = math.floor(invincibletimer/6)
		local armangle = 0
		if direction == "right" then
			armangle = math.atan((my-(py+13-4-vy+320))/(mx-(px+playerWidth/2-1-vx+512)))-math.pi/2
		else
			armangle = math.atan((my-(py+13-4-vy+320))/(mx-(px+playerWidth/2-1-vx+512)))+math.pi/2
		end
		if invincibletimer < 0 or flash/3 ~= math.floor(flash/3) then
			love.graphics.draw(arms[characternum],math.floor(px+playerWidth/2-flip*3-vx+512),math.floor(py+15-vy+320),armangle,flip,1,5,2)
			love.graphics.drawq(charsprites[characternum],playerquad,math.floor(px-1-vx+528),math.floor(py-4-vy+320),0,flip,1,16)
			if animation ~= 4 then
				love.graphics.draw(arms[characternum],math.floor(px+playerWidth/2-flip*5-vx+512),math.floor(py+13-vy+320),armangle,flip,1,5,2)
			end
			if drawmirror then
				love.graphics.drawq(charsprites[characternum],playerquad,math.floor(mirrorx-1-vx+528),math.floor(mirrory-4-vy+320),0,flip,1,16)
			end
		end
		love.graphics.setColor(0,0,0)
		love.graphics.rectangle("fill",math.floor(px-vx+512),math.floor(py-8-vy+320),playerWidth,4)
		love.graphics.setColor(250,130,40)
		love.graphics.rectangle("fill",math.floor(px-vx+512),math.floor(py-8-vy+320),health/maxhealth*playerWidth,4)
		love.graphics.setColor(255,180,60)
		love.graphics.rectangle("fill",math.floor(px-vx+512),math.floor(py-8-vy+320),health/maxhealth*playerWidth,2)
		local cooldown = 0
		local maxcooldown = 0
		if cooldown > 0 then
			love.graphics.setColor(255,255,100,100)
			love.graphics.rectangle("fill",px-1-vx+512,py-9-vy+320,cooldown/maxcooldown*(playerWidth+2),6)
		end
		love.graphics.setColor(70,70,70,100)
		love.graphics.print("class: "..characternames[characternum].."\ntype: "..types[charactertype],0,0)
		if output then love.graphics.print(output,0,40) end
	end
	if gamestate == "paused" then
		love.graphics.rectangle("fill",0,0,love.graphics.getWidth(),love.graphics.getHeight())
		love.graphics.printf("PAUSED",0,love.graphics.getHeight()/2,love.graphics.getWidth(),"center")
	end
end

function writeToLog(message)
	local file = love.filesystem.newFile("debug/log.txt")
	file:open("a")
	file:write(message.."\n")
	file:close()
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
	direction = "right"
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
		swapmusic(1)
	end
	if key == "escape" or key == "p" then
		if gamestate == "playing" then
			gamestate = "paused"
		elseif gamestate == "paused" then
			gamestate = "playing"
		end
	end
end

function love.joystickpressed(joystick,button)
	if button == "left" and gamestate == "choosecharacter" then
		changecharacter(characternum - 1)
	end
	if button == "right" and gamestate == "choosecharacter" then
		changecharacter(characternum + 1)
	end
	if button == " " and gamestate == "choosecharacter" then
		changecharacter(characternum)
		gamestate = "playing"
	end
	if button == jumpkey and gamestate == "playing" then
		jumping = true
	end
	if button == "z" and gamestate == "playing" then
		gamestate = "choosecharacter"
	end
	if button == "x" and gamestate == "playing" then
		gamestate = "mainmenu"
	end
	if button == "escape" or button == "p" then
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
		swapmusic(2)
	end
end