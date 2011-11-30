require("strong")

function love.load()
	font = love.graphics.newFont("monof55.ttf", 26)
	love.graphics.setFont(font)
	love.graphics.setColor(60,60,60,120)
	love.graphics.setColorMode("replace")
	sidebar = love.graphics.newImage("sidebar.png")
	gridsquare = love.graphics.newImage("gridsquare.png")
	selected = love.graphics.newImage("selected.png")
	spawnpoint = love.graphics.newImage("spawnpoint.png")
	rockwall = love.graphics.newImage("rockwall.png")
	spikes = love.graphics.newImage("spikes.png")
	items = {"b","w","#"}
	background = "backgrounds/temple.png"
	selecteditem = 1
	levelname = ""
	newlevel(32,20,"backgrounds/temple.png")
end

function love.update(dt)
	mx = love.mouse.getX()
	my = love.mouse.getY()
	if state == "editing" then
		if love.mouse.isDown("l") then
			edit(math.ceil(mx/32),math.ceil(my/32),items[selecteditem])
		end
		if love.mouse.isDown("r") then
			edit(math.ceil(mx/32),math.ceil(my/32)," ")
		end
	end
end

function love.draw()
	love.graphics.draw(bgimage,0,0)
	love.graphics.draw(sidebar,love.graphics.getWidth()-64,0)
	for n=1,# items do
		local buttonx = 0
		if n/2 == math.floor(n/2) then
			buttonx = love.graphics.getWidth()-32
		else
			buttonx = love.graphics.getWidth()-64
		end
		local buttony = math.floor((n-1)/2)*32
		if items[n] == "b" then
			love.graphics.draw(rockwall,buttonx,buttony)
		end
		if items[n] == "w" then
			love.graphics.draw(spikes,buttonx,buttony)
		end
		if items[n] == "#" then
			love.graphics.draw(spawnpoint,buttonx,buttony)
		end
		if n == selecteditem then
			love.graphics.draw(selected,buttonx,buttony)
		end
	end
	for a=1,levelwidth do
		for b=1,levelheight do
			love.graphics.draw(gridsquare,(a-1)*32,(b-1)*32)
			if level[a][b] == "b" then
				love.graphics.draw(rockwall,(a-1)*32,(b-1)*32)
			end
			if level[a][b] == "w" then
				love.graphics.draw(spikes,(a-1)*32,(b-1)*32)
			end
			if level[a][b] == "#" then
				love.graphics.draw(spawnpoint,(a-1)*32,(b-1)*32)
			end
		end
	end
	if state == "save" then
		love.graphics.rectangle("fill",0,0,love.graphics.getWidth(),love.graphics.getHeight())
		love.graphics.print("save as:\n"..levelname,10,10)
	end
end

function edit(x,y,entry)
	if x < levelwidth+1 and y < levelheight+1 then
		level[x][y] = entry
	end
end

function newlevel(width,height,bg)
	levelwidth = 0
	levelheight = 0
	level = {}
	background = bg
	bgimage = love.graphics.newImage(bg)
	changelevelbounds(width,height)
end

function changelevelbounds(newwidth,newheight)
	local levelbackup = level
	level = {}
	for a=1,newwidth do
		level[a] = {}
		for b=1, newheight do
			if a < levelwidth+1 and b < levelheight+1 then
				level[a][b] = levelbackup[a][b]
			else
				level[a][b] = " "
			end
		end
	end
	levelwidth = newwidth
	levelheight = newheight
	state = "editing"
end

function savelevel(filename)
	local file = love.filesystem.newFile(filename)
	file:open("w")
	file:write(background.."\n")
	for a=1,levelheight do
		local string = ""
		for b=1,levelwidth do
			if level[a][b] ~= 0 then
				if b < levelwidth then
					string = string..level[b][a].."."
				else
					string = string..level[b][a]
				end
			end
		end
		if a < levelheight then
			file:write(string.."\n")
		else
			file:write(string)
		end
	end
	file:close()
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
	if state == "save" then
		if key == "delete" or key == "backspace" then
			levelname = deletelastchar(levelname)
		else
			if key(2) == nil then
				levelname = levelname..key
			else
				if key == "return" or key == "kpenter" then
					savelevel(levelname)
					state = "editing"
				end
			end
		end
	end
	if key == "s" then
		state = "save"
	end
	if key == "escape" then
		love.event.push("q")
	end
end

function love.mousepressed(x,y,button)
	if button == "l" and state == "editing" and x > love.graphics.getWidth()-64 then
		local buttonx = math.ceil((x-love.graphics.getWidth()+64)/32)
		local buttony = math.ceil(y/32)
		selecteditem = buttonx+(2*buttony)-2
	end
end