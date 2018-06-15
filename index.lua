Libs = {
	"fontLib"
}
appDir = "ux0:data/BL/"
libDir = appDir.."libs/"
dataDir = appDir.."data/"
dir = "ux0:data/BL/"
for i = 1, #Libs do 
	dofile(libDir..Libs[i]..".lua")
end
palette = Graphics.loadImage(dataDir.."palette.png")
tile_tex = Graphics.loadImage(dataDir.."tile.png")
paletteTable = {}
level = {
	name = "Pikachu",
	width = 10,
	height = 10,
	map = {	true,false,false,true,false,false,false,false,false,true,
		true,true,false,true,true,false,false,false,true,true,
		false,true,true,false,true,true,true,true,true,false,
		false,false,true,true,false,false,false,false,false,true,
		false,false,true,false,false,false,false,false,false,false,
		false,false,true,false,true,false,false,false,false,true,
		false,true,false,true,true,false,false,false,true,true,
		false,true,true,false,false,false,true,false,false,false,
		false,true,true,false,false,true,true,true,false,false,
	false,false,true,true,false,false,false,false,false,true}
}
local tile = {stackU = {}, stackL = {}}
local DeltaTimer, newTime = Timer.new(), 0
local Controls_check = Controls.check
local Color_new = Color.new
local start_x, start_y, tile_size = 0, 0, 24
local square_size, square_start_x, square_start_y = tile_size - 2, start_x + 1,start_y + 1
local level_width, level_height = 0, 0
local frame_x, frame_y, x5lines, y5lines, priceXY5, frame_size = 0, 0, 0, 0, 0, tile_size + 2
local ceil, max, len = math.ceil, math.max, string.len
local actionTimer = Timer.new()
local dontPress = false
local lock_time, pause, def_pause, lil_pause = 1000, 300, 300, 90
function updateStacks()
	for i = 0, math.max(level.width,level.height) - 1 do
		if i < level.width then			tile.stackU[i] = {[0]=0}		end
		if i < level.height then		tile.stackL[i] = {[0]=0}		end
	end
	for i=0, level.width-1 do
		local now = 0
		for j=0, level.height-1 do
			if level.map[j*level.width+i+1] then
				tile.stackU[i][now] = tile.stackU[i][now] + 1
			else
				if tile.stackU[i][now]~=nil and tile.stackU[i][now]>0 then
					now = now + 1
					tile.stackU[i][now] = 0
				end
			end
		end
		if tile.stackU[i][now]==0 and tile.stackU[i][0]~=0 then tile.stackU[i][now]=nil end
	end
	local tmp = 0
	for i=0, level.height-1 do
		local now = 0
		for j=0, level.width-1 do
			tmp = tmp + 1
			if level.map[tmp] then
				tile.stackL[i][now] = tile.stackL[i][now] + 1
			else
				if tile.stackL[i][now]~=nil and tile.stackL[i][now]>0 then
					now = now + 1
					tile.stackL[i][now] = 0
				end
			end
		end
		if tile.stackL[i][now]==0 and tile.stackL[i][0]~=0 then tile.stackL[i][now]=nil end
	end
end
local function Update()
	start_x = (960 - level.width * tile_size)/2
	start_y = (544 - level.height * tile_size)/2
	square_start_x = start_x + 1
	square_start_y = start_y + 1
	level_width, level_height = level.width * tile_size, level.height * tile_size
	frame_x = 0
	frame_y = 0
	level.empty = {}
	local tmp = 0
	for i = 0, level.height - 1 do
		for j = 0, level.width - 1 do
			tmp = tmp + 1
			level.empty[tmp] = false
		end
	end
	priceXY5 = 5 * tile_size
	x5lines = (ceil(level.width/5) - 1) * priceXY5
	y5lines = (ceil(level.height/5) - 1) * priceXY5
	updateStacks()
end
local function Controls_click(BUTTON)
	return Controls_check(pad, BUTTON) and not Controls_check(oldpad, BUTTON)
end
local function Scan_Palette(pal_tex)
	for i = 1, 2 do
		Graphics.initBlend()
		Screen.clear()
		Graphics.drawImage(0,0,pal_tex)
		if i == 2 then
			for i = 0, Graphics.getImageWidth(pal_tex) do
				paletteTable[i] = {}
				for j = 0, Graphics.getImageHeight(pal_tex) do
					paletteTable[i][j] = Screen.getPixel(i,j)
				end
			end
		end
		Graphics.termBlend()
		Screen.waitVblankStart()
		Screen.flip()
	end
end
local function drawRect(x, y, w, h, c)
	Graphics.fillRect(x, x + w, y, y + h, c)
end
local function drawEmptyRect(x, y, w, h, t, c)
	drawRect(x, y, t, h, c)
	drawRect(x + t, y, w - 2 * t, t, c)
	drawRect(x + w - t, y, t, h, c)
	drawRect(x + t, y + h - t, w - 2 * t, t, c)
end
local function drawLevel()
	drawRect(start_x - 1, start_y - 1, level_width + 2, level_height + 2, Color_new(0, 0, 0))
	local xLine = 0
	for i = priceXY5 - 1, x5lines, priceXY5 do
		drawRect(start_x + i, start_y, 3, level_height, Color_new(200,0,0))
	end
	for i = priceXY5 - 1, y5lines, priceXY5 do
		drawRect(start_x, start_y + i, level_width, 3, Color_new(200,0,0))
	end
	local y = square_start_y
	local tmp = 0
	for i = 0, level.width - 1 do
		local x = square_start_x
		for j = 0, level.height - 1 do
			tmp = tmp + 1
			if level.empty[tmp] then
				Graphics.drawImage(x, y, tile_tex, Color_new(0, 148, 255))
				else
				drawRect(x, y, square_size, square_size, Color_new(255, 255, 255))	
			end
			x = x + tile_size
		end
		y = y + tile_size
	end
	drawEmptyRect(start_x + frame_x * tile_size - 1, start_y + frame_y * tile_size - 1, frame_size, frame_size, 4, Color_new(200, 0, 200))
end
local function drawNumbers()
	local halhSize = tile_size/2
	local xU = start_x
	local yL = start_y
	for i=0, max(level.width,level.height) do
		local yU = start_y-2
		local xL = start_x-2
		for j = max(level.width,level.height), 0, -1 do
			if i<=#tile.stackU and j<=#tile.stackU[i] then
				yU = yU - tile_size
				local textU = tile.stackU[i][j]
				FontLib_print(xU+halhSize-len(textU)*5-2,yU+halhSize-7+2,textU,Color_new(0, 0, 0),2)
				FontLib_print(xU+halhSize-len(textU)*5,yU+halhSize-7,textU,Color_new(255, 255, 255),2)
			end
			if i<=#tile.stackL and j<=#tile.stackL[i] then
				xL = xL - tile_size
				local textL = tile.stackL[i][j]
				FontLib_print(xL+halhSize-len(textL)*5-2,yL+halhSize-7+2,textL,Color_new(0, 0, 0),2)
				FontLib_print(xL+halhSize-len(textL)*5	,yL+halhSize-7,textL,Color_new(255, 255, 255),2)
			end
		end
		xU = xU + tile_size
		yL = yL + tile_size
	end
end
local function Controls_frame()
	local time = Timer.getTime(actionTimer)
	if pause ~= lock_time then
		if not dontPress then
			if pause == def_pause or time > pause then
				Timer.reset(actionTimer)
				local pressed = false
				if Controls_check(pad, SCE_CTRL_UP) or Controls_check(pad, SCE_CTRL_DOWN) or Controls_check(pad, SCE_CTRL_LEFT) or Controls_check(pad, SCE_CTRL_RIGHT) then
					pressed = true
				end
				if Controls_check(pad, SCE_CTRL_UP) then
					frame_y = frame_y - 1
					elseif Controls_check(pad, SCE_CTRL_DOWN) then
					frame_y = frame_y + 1
				end
				if Controls_check(pad, SCE_CTRL_LEFT) then
					frame_x = frame_x - 1
					elseif Controls_check(pad, SCE_CTRL_RIGHT) then
					frame_x = frame_x + 1
				end
				if frame_y < 0 then frame_y = level.height-1 elseif frame_y > level.height-1 then frame_y = 0 end
				if frame_x < 0 then frame_x = level.width-1 elseif frame_x > level.width-1 then frame_x = 0 end
				if pressed and pause==def_pause then
					pause = def_pause + 1 
					elseif pressed and pause == def_pause + 1 then 
					pause = lil_pause 
					elseif not pressed then 
					pause = def_pause 
				end
			end
		end
		else
		if pause < time then
			Timer.reset(actionTimer)
			pause = def_pause
		end
	end
end
Scan_Palette(palette)
Update()
while true do
	dt = newTime / 8
	Timer.reset(DeltaTimer)
	pad = Controls.read()
	Graphics.initBlend()
	Screen.clear(Color_new(180,180,180))
	drawLevel()
	drawNumbers()
	Controls_frame()
	Graphics.termBlend()
	if Controls_click(SCE_CTRL_SELECT) then
		FontLib_close()
		FTP = FTP + 1
	end	  
	Screen.waitVblankStart()
	Screen.flip()
	oldpad = pad
	newTime = Timer.getTime(DeltaTimer)
end