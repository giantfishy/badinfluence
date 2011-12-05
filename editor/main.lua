require("strong")

function love.load()
	font = love.graphics.newFont("london.ttf",22)
	fontsmall = love.graphics.newFont("london.ttf",18)
	love.graphics.setFont(font)
	love.graphics.setColor(60,60,60,120)
	love.graphics.setColorMode("replace")
	sidebar = love.graphics.newImage("sidebar.png")
	gridsquare = love.graphics.newImage("gridsquare.png")
	selected = love.graphics.newImage("selected.png")
	spawnpoint = love.graphics.newImage("spawnpoint.png")
	rockwall = love.graphics.newImage("rockwall.png")
	spikes = love.graphics.newImage("spikes.png")
	rockwallbg = love.graphics.newImage("rockwallbg.png")
	items = {"b","-","w","#"}
	background = "backgrounds/temple.png"
	selecteditem = 1
	levelname = ""
	messages = {}
	newlevel(32,20,"backgrounds/temple.png")
end

function love.update(dt)
	mx = love.mouse.getX()
	my = love.mouse.getY()
	if state == "editing" then
		if love.mouse.isDown("l") and (mx+vx)/32 > 0 and (my+vy)/32 > 0 and mx < love.graphics.getWidth()-64 then
			edit(math.ceil((mx+vx)/32),math.ceil((my+vy)/32),items[selecteditem])
		end
		if love.mouse.isDown("r") and (mx+vx)/32 > 0 and (my+vy)/32 > 0 then
			edit(math.ceil((mx+vx)/32),math.ceil((my+vy)/32)," ")
		end
		local speed = 4
		if love.keyboard.isDown("lshift","rshift") then speed = 7 end
		if love.keyboard.isDown("up") then vy = vy - speed end
		if love.keyboard.isDown("left") then vx = vx - speed end
		if love.keyboard.isDown("down") then vy = vy + speed end
		if love.keyboard.isDown("right") then vx = vx + speed end
	end
	for n=1,#messages do
		if n < #messages+1 then
			messages[n][2] = messages[n][2]-1
			if messages[n][2] < 1 then
				table.remove(messages,n)
			end
		end
	end
end

function love.draw()
	love.graphics.draw(bgimage,0,0)
	for a=math.floor(vx/32),math.ceil((vx+love.graphics.getWidth()-64)/32) do
		for b=math.floor(vy/32),math.ceil((vy+love.graphics.getHeight())/32) do
			if a > 0 and a < levelwidth+1 and b > 0 and b < levelheight+1 then
				love.graphics.draw(gridsquare,(a-1)*32-vx,(b-1)*32-vy)
				if level[a][b] == "b" then
					love.graphics.draw(rockwall,(a-1)*32-vx,(b-1)*32-vy)
				end
				if level[a][b] == "w" then
					love.graphics.draw(spikes,(a-1)*32-vx,(b-1)*32-vy)
				end
				if level[a][b] == "#" then
					love.graphics.draw(spawnpoint,(a-1)*32-vx,(b-1)*32-vy)
				end
				if level[a][b] == "-" then
					love.graphics.draw(rockwallbg,(a-1)*32-vx,(b-1)*32-vy)
				end
			end
		end
	end
	love.graphics.setColor(255,0,0)
	love.graphics.line(levelwidth*16-vx,0-vy, levelwidth*16-vx,levelheight*32-vy)
	love.graphics.line(0-vx,levelheight*16-vy, levelwidth*32-vx,levelheight*16-vy)
	love.graphics.setColor(60,60,60,120)
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
		if items[n] == "-" then
			love.graphics.draw(rockwallbg,buttonx,buttony)
		end
		if n == selecteditem then
			love.graphics.draw(selected,buttonx,buttony)
		end
	end
	if state == "save" then
		love.graphics.rectangle("fill",0,0,love.graphics.getWidth(),love.graphics.getHeight())
		love.graphics.print("save as:\n"..levelname,10,10)
	end
	if state == "load" then
		love.graphics.rectangle("fill",0,0,love.graphics.getWidth(),love.graphics.getHeight())
		love.graphics.print("load:\n"..levelname,10,10)
	end
	if state == "new" then
		placeholders[fieldnum] = "__"
		if fields[fieldnum](1) then
			placeholders[fieldnum] = fields[fieldnum].."_"
		end
		if fields[fieldnum](2) then
			placeholders[fieldnum] = fields[fieldnum]
		end
		love.graphics.rectangle("fill",0,0,love.graphics.getWidth(),love.graphics.getHeight())
		love.graphics.print("level bounds:\n"..placeholders[1].."x"..placeholders[2].."\nbackground image:"..fields[3],10,10)
	end
	if state == "reallyquit?" then
		love.graphics.rectangle("fill",0,0,love.graphics.getWidth(),love.graphics.getHeight())
		love.graphics.print("really quit (y/n)?",10,10)
	end
	love.graphics.setFont(fontsmall)
	for n=1,#messages do
		love.graphics.print(messages[n][1],4,love.graphics.getHeight()-(16*n))
	end
	love.graphics.setFont(font)
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
	vx = 0
	vy = 0
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
			if level[b][a] ~= 0 then
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

function loadlevel(filename)
	level = {}
	local levelfile = love.filesystem.newFile(filename)
	levelfile:open("r")
	local contents = levelfile:read()
	local a = 0
	for line in contents:lines("\n") do
		if a > 0 then
			level[a] = line / "."
		else
			if a == 0 then
				background = line
			end
		end
		a = a + 1
	end
	levelwidth = #level[1]
	levelheight = #level
	local oldlevel = level
	level = {}
	for a=1,levelwidth do
		level[a] = {}
		for b=1,levelheight do
			level[a][b] = oldlevel[b][a]
		end
	end
end

function addmessage(string,time)
	table.insert(messages,{string,time})
end

function love.keypressed(key)
	if state == "save" then
		if key == "delete" or key == "backspace" then
			levelname = deletelastchar(levelname)
		else
			if key(2) == nil then
				if love.keyboard.isDown("lshift","rshift") then
					levelname = levelname..key:capitalize()
				else
					levelname = levelname..key
				end
			else
				if key == "return" or key == "kpenter" then
					local hasSpawnPoints = false
					for a=1,levelwidth do
						for b=1,levelheight do
							if level[a][b] == "#" then
								hasSpawnPoints = true
							end
						end
					end
					if hasSpawnPoints then
						if not levelname:endsWith(".txt") then
							levelname = levelname..".txt"
						end
						savelevel(levelname)
						addmessage("level saved.",100)
					else
						addmessage("can not save level without spawn points",200)
					end
					state = "editing"
				end
			end
		end
	end
	if state == "load" then
		if key == "delete" or key == "backspace" then
			levelname = deletelastchar(levelname)
		else
			if key(2) == nil then
				if love.keyboard.isDown("lshift","rshift") then
					levelname = levelname..key:capitalize()
				else
					levelname = levelname..key
				end
			else
				if key == "return" or key == "kpenter" then
					if not levelname:endsWith(".txt") then
						levelname = levelname..".txt"
					end
					loadlevel(levelname)
					addmessage("level loaded.",100)
					state = "editing"
				end
			end
		end
	end
	if state == "new" then
		if key == "delete" or key == "backspace" then
			fields[fieldnum] = deletelastchar(fields[fieldnum])
		else
			if key(2) == nil and (tonumber(key) or fieldnum == 3) then
				if love.keyboard.isDown("lshift","rshift") then
					fields[fieldnum] = fields[fieldnum]..key:capitalize()
				else
					fields[fieldnum] = fields[fieldnum]..key
				end
			else
				if key == "return" or key == "kpenter" then
					fieldnum = fieldnum + 1
					placeholders[fieldnum-1] = fields[fieldnum-1]
					if fieldnum > 3 then
						if not fields[3]:endsWith(".png") then
							fields[3] = fields[3]..".png"
						end
						if not fields[3]:startsWith("backgrounds/") then
							fields[3] = "backgrounds/"..fields[3]
						end
						newlevel(tonumber(fields[1]),tonumber(fields[2]),fields[3])
						state = "editing"
					end
				end
			end
		end
	end
	if key == "n" and state == "editing" then
		state = "new"
		fields = {"","",""}
		fieldnum = 1
		placeholders = {"__","__"}
	end
	if key == "s" and state == "editing" then
		state = "save"
	end
	if key == "l" and state == "editing" then
		state = "load"
	end
	if key == " " and state == "editing" then
		vx = 0
		vy = 0
	end
	if state == "reallyquit?" then
		if key == "y" then love.event.push('q') end
		if key == "n" then state = "editing" end
	end
	if key == "escape" then
		if state == "editing" then
			state = "reallyquit?"
		end
		if state == "save" or state == "load" or state == "new" then
			state = "editing"
		end
	end
end

function love.mousepressed(x,y,button)
	if button == "l" and state == "editing" and x > love.graphics.getWidth()-64 then
		local buttonx = math.ceil((x-love.graphics.getWidth()+64)/32)
		local buttony = math.ceil(y/32)
		selecteditem = buttonx+(2*buttony)-2
	end
end