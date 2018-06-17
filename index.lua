local Libs = {
	"fontLib",
	"PCLrwLib"
}
appDir = "ux0:data/BL/" --Dir for app0
libDir = appDir.."libs/" --Dir for libs in app0
dataDir = appDir.."data/" --Dir for data in app0
levelDir = appDir.."lvls/" --Dir for levels in app0
themesDir = appDir.."thms/" --Dir for levels in app0
dir = "ux0:data/BL/" --Dir for ux0:data/PiCrest
configDir = dir.."config.ini"
clevelDir = dir.."levels/" --Dir for custom levels
for i = 1, #Libs do 
	dofile(libDir..Libs[i]..".lua")
end
local hex2rgb = hex2rgb
local rgb2hex = rgb2hex
local openPCL, updatePCL, createPCL, getRNPCL = PCL_Lib.open, PCL_Lib.update, PCL_Lib.create, PCL_Lib.getRN
local tile_tex = Graphics.loadImage(dataDir.."tile.png")
local cross_tex = Graphics.loadImage(dataDir.."cross.png")
local tile = {stackU = {}, stackL = {}}
local DeltaTimer, newTime, actionTimer = Timer.new(), 0, Timer.new()
local Controls_check = Controls.check
local Color_new = Color.new
local start_x, start_y, tile_size = 0, 0, 24
local half_size, square_size, square_start_x, square_start_y = tile_size / 2, tile_size - 2, start_x + 1,start_y + 1
local level_width, level_height = 0, 0
local frame_x, frame_y, x5lines, y5lines, priceXY5, frame_size = 0, 0, 0, 0, 0, tile_size + 2
local ceil, max, len, floor, sub = math.ceil, math.max, string.len, math.floor, string.sub
local dontPress = false
local lock_time, def_pause, lil_pause = 1000, 200, 60
local pause = def_pause
local oldpad, newpad = SCE_CTRL_CROSS, SCE_CTRL_CROSS
local OptionsNow, OptionsCLRNow, OptionsNowKey, Old_color = 1, 0, 0, Color_new(0,0,0)
level = openPCL(levelDir.."level2.pcl")
Options = {
	["nowtheme"] = "default",
	["animation"] = "fade",
}
local function readCfg(_path)
	if System.doesFileExist(_path) then
		local cfg = System.openFile(_path, FREAD)
		local cfg_size = System.sizeFile(cfg)
		local k,key,value = true,"",""
		for i = 1, cfg_size do
			local str = System.readFile(cfg, 1)
			if string.byte(str) ~= 13 and string.byte(str)~=10 then
				if str == ' ' then 
					k = false 
					else
					if k then
						key = key..str
						else
						value = value..str
					end
				end
				elseif string.byte(str) == 10 then
				k = true
				Options[key] = value 
				key = ''
				value = ''
			end
		end
		Options[key] = value 
		System.closeFile(cfg)
	end
end
local function updateCfg(_path, table)
	System.deleteFile(_path)
	local cfg = System.openFile(_path, FCREATE)
	for k,v in pairs(table) do
		System.writeFile(cfg, k.." "..v.."\n",len(k.." "..v.."\n"))
	end
	System.closeFile(cfg)
end
readCfg(configDir)
local function tlen(t)
	local a = 0
	for k, v in pairs(t) do
		a = a + 1
	end
	return a
end
local Colors = {
	Tile = Color_new(255, 255, 255),
	Cross = Color_new(0, 148, 255),
	Square = Color_new(0, 148, 255),
	Background = Color_new(160, 0, 28),
	SecondBack = Color_new(200, 0, 64),
	X5Lines = Color_new(200,0,0),
	Grid = Color_new(0,0,0),
	Frame = Color_new(200, 0, 200),
	SideNumbers = Color_new (255,255,255)
}
local OptionsColorsNext = {
	["0"] = "1", ["1"] = "2", ["2"] = "3", ["3"] = "4", ["4"] = "5", ["5"] = "6", ["6"] = "7", ["7"] = "8", ["8"] = "9", ["9"] = "A", ["A"] = "B", ["B"] = "C", ["C"] = "D", ["D"] = "E", ["E"] = "F", ["F"] = "0"
}
local OptionsColorsPrev = {
	["0"] = "F", ["1"] = "0", ["2"] = "1", ["3"] = "2", ["4"] = "3", ["5"] = "4", ["6"] = "5", ["7"] = "6", ["8"] = "7", ["9"] = "8", ["A"] = "9", ["B"] = "A", ["C"] = "B", ["D"] = "C", ["E"] = "D", ["F"] = "E"
}
local function AcceptTheme(_path)
	local thm = System.openFile(_path, FREAD)
	local thm_size = System.sizeFile(thm)
	local k,key,value = true,"",""
	for i = 1, thm_size do
		local str = System.readFile(thm, 1)
		if string.byte(str) ~= 13 and string.byte(str)~=10 then
			if str == ' ' then 
				k = false
				else
				if k then
					key = key..str
					else
					value = value..str
				end
			end
			elseif string.byte(str) == 10 then
			k = true
			Colors[key] = Color.new(hex2rgb(value)) 
			key = ''
			value = ''
		end
	end
	System.closeFile(thm)
end
if Options["nowtheme"] == "custom" then
	if System.doesFileExist(dir.."custom.thm") then
		AcceptTheme(dir.."custom.thm")
		else
		Options["nowtheme"] = "default"
		AcceptTheme(themesDir.."default.thm")
	end
	else
	AcceptTheme(themesDir..Options["nowtheme"]..".thm")
end
updateCfg(configDir, Options)
local function MakeTheme(_path, table)
	System.deleteFile(_path)
	local thm = System.openFile(_path, FCREATE)
	for k,v in pairs(table) do
		local hex = rgb2hex({Color.getR(v),Color.getG(v), Color.getB(v)})
		System.writeFile(thm, k.." "..hex..'\n', len(k.." "..hex..'\n'))
	end
	System.closeFile(thm)
end
local function updateStacks() --Creating side numbers
	for i = 0, max(level.width,level.height) - 1 do
		if i < level.width then		tile.stackU[i] = {[0]=0}	end
		if i < level.height then	tile.stackL[i] = {[0]=0}	end
	end
	do --Creating Upper side numbers
		for i = 0, level.width-1 do
			local now = 0
			for j=0, level.height-1 do
				if level.map[j*level.width+i+1] then
					tile.stackU[i][now] = tile.stackU[i][now] + 1
					else
					if tile.stackU[i][now] and tile.stackU[i][now] > 0 then
						now = now + 1
						tile.stackU[i][now] = 0
					end
				end
			end
			if tile.stackU[i][now] == 0 and tile.stackU[i][0] ~= 0 then tile.stackU[i][now]=nil end
		end
		tile.ULen = #tile.stackU
	end
	do --Creating Left side numbers
		local tmp = 0
		for i=0, level.height-1 do
			local now = 0
			for j=0, level.width-1 do
				tmp = tmp + 1
				if level.map[tmp] then
					tile.stackL[i][now] = tile.stackL[i][now] + 1
					else
					if tile.stackL[i][now] and tile.stackL[i][now] > 0 then
						now = now + 1
						tile.stackL[i][now] = 0
					end
				end
			end
			if tile.stackL[i][now]==0 and tile.stackL[i][0]~=0 then tile.stackL[i][now]=nil end
		end
		tile.LLen = #tile.stackL
	end
end
local function Update() --Updating variables for new level
	start_x = (960 - level.width * tile_size)/2
	start_y = (544 - level.height * tile_size)/2
	square_start_x = start_x + 1
	square_start_y = start_y + 1
	level_width, level_height = level.width * tile_size, level.height * tile_size
	frame_x = 0
	frame_y = 0
	level.empty = {}
	level.cross = {}
	level.square = {}
	level.nowBlocks = 0
	level.allBlocks = 0
	local tmp = 0
	for i = 1, level.height do
		for j = 1, level.width do
			tmp = tmp + 1
			level.empty[tmp] = 0
			level.square[tmp] = 0
			level.cross[tmp] = 0
			if level.map[tmp] then
				level.allBlocks = level.allBlocks + 1
			end
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
	drawRect(start_x - 1, start_y - 1, level_width + 2, level_height + 2, Colors.Grid)
	local xLine = 0
	for i = priceXY5 - 1, max(x5lines, y5lines), priceXY5 do
		if i<=x5lines then
			drawRect(start_x + i, start_y, 3, level_height, Colors.X5Lines)
		end
		if i<=y5lines then
			drawRect(start_x, start_y + i, level_width, 3, Colors.X5Lines)
		end
	end
	local y = square_start_y
	local tmp = 0
	for i = 0, level.height-1 do
		local x = square_start_x
		local i_len = i / 2
		if floor(i_len) == i_len then	drawRect(0, y - 1, x - 2, tile_size, Colors.SecondBack) end
		for j = 0, level.width - 1 do
			if i == 0 then
				local j_tmp = j /2
				if floor(j_tmp) == j_tmp then drawRect(x - 1, 0, tile_size, y - 2, Colors.SecondBack) end
			end
			tmp = tmp + 1
			local tmp1,tmp2,tmp3 = level.empty[tmp],level.square[tmp],level.cross[tmp]
			if Options["animation"]~="off" and tmp2~=1 then
				drawRect(x,y,square_size,square_size,	Colors.Tile)
				elseif Options["animation"]=="off" and tmp1~=1 then
				drawRect(x,y,square_size,square_size,	Colors.Tile)
			end
			if Options["animation"] == "fade" then
				if tmp3>0 and tmp3<1 then
					Graphics.drawImage(x, y, cross_tex,Color_new(Color.getR(Colors.Cross),Color.getG(Colors.Cross),Color.getB(Colors.Cross),tmp3*255))
					elseif tmp3>0 then
					Graphics.drawImage(x, y, cross_tex,Colors.Cross)
				end
				if tmp2>0 and tmp2<1 then
					Graphics.drawImage(x, y, tile_tex,Color_new(Color.getR(Colors.Square),Color.getG(Colors.Square),Color.getB(Colors.Square),tmp2*255))
					elseif tmp2>0 then
					Graphics.drawImage(x, y, tile_tex,Colors.Square)
				end
				elseif Options["animation"]=="rescale" then
				if tmp3>0 and tmp3<1 then
					Graphics.drawImageExtended(x-1+half_size, y-1+half_size, cross_tex,0,0,square_size,square_size,0,tmp3,tmp3,Colors.Cross)
					elseif tmp3>0 then
					Graphics.drawImage(x, y, cross_tex,Colors.Cross)
				end
				if tmp2>0 and tmp2<1 then
					Graphics.drawImageExtended(x-1+half_size, y-1+half_size, tile_tex ,0,0,square_size,square_size,0,tmp2,tmp2,Colors.Square)
					elseif tmp2>0 then
					Graphics.drawImage(x, y, tile_tex,Colors.Square)
				end
				elseif Options["animation"]=="off" then
				if tmp1==1 then
					Graphics.drawImage(x, y, tile_tex,Colors.Square)
					elseif tmp1==-1 then
					Graphics.drawImage(x, y, cross_tex,Colors.Cross)
				end
			end
			x = x + tile_size
			local add
			if Options["animation"]=="fade" then
				add = dt*0.03
				elseif Options["animation"]=="rescale" then
				add = dt*0.05
			end
			if Options["animation"]~="off" then
				if		tmp1 == 1	and tmp2 < 1 then	level.square[tmp]	= tmp2 + add
				elseif	tmp1 == 0	and tmp2 > 0 then	level.square[tmp]	= tmp2 - add	end
				if		tmp1 == -1	and tmp3 < 1 then	level.cross[tmp]	= tmp3 + add
				elseif	tmp1 == 0	and tmp3 > 0 then	level.cross[tmp]	= tmp3 - add	end
				if		tmp1 == 1	and tmp2 > 1 then	level.square[tmp]	= 1
				elseif	tmp1 == 0	and tmp2 < 0 then	level.square[tmp]	= 0				end
				if		tmp1 == -1	and tmp3 > 1 then	level.cross[tmp]	= 1
				elseif	tmp1 == 0	and tmp3 < 0 then	level.cross[tmp]	= 0				end
			end
		end
		y = y + tile_size
	end
	drawEmptyRect(start_x + frame_x * tile_size - 1, start_y + frame_y * tile_size - 1, frame_size, frame_size, 4, Colors.Frame)
end
local function drawNumbers() --Draw side numbers
	local xU, yL = start_x + half_size, start_y + half_size - 7
	local yU_start, xL_start = yL - 5, xU - 2
	local maximum = max(level.width,level.height)
	local alen, blen, clen, dlen = tile.ULen, tile.LLen
	for i = 0, maximum do
		local yU, xL = yU_start, xL_start
		local a, b = i<=alen, i<=blen
		if a then clen = #tile.stackU[i] end
		if b then dlen = #tile.stackL[i] end
		for j = maximum, 0, -1 do
			if a and j<=clen then
				yU = yU - tile_size
				local textU = tile.stackU[i][j]
				FontLib_print(xU - len(textU) * 5, yU,textU, Colors.SideNumbers, 3)
				--FontLib_printWShadow(xU - len(textU) * 4, - 2, yU, 2, textU, Color_new(255, 255, 255), Color_new(0, 0, 0), 2)
			end
			if b and j<=dlen then
				xL = xL - tile_size
				local textL = tile.stackL[i][j]
				FontLib_print(xL - len(textL) * 5, yL,textL, Colors.SideNumbers, 3)
				--FontLib_printWShadow(xL - len(textL) * 4, - 2, yL, 2, textL, Color_new(255, 255, 255), Color_new(0, 0, 0), 2)
			end
		end
		xU = xU + tile_size
		yL = yL + tile_size
	end
end
local function Controls_frame() --Frame manipulations
	local time = Timer.getTime(actionTimer)
	if pause ~= lock_time then
		local _cross, _circle = Controls.check(pad, SCE_CTRL_CROSS), Controls.check(pad, SCE_CTRL_CIRCLE)
		if not dontPress then
			if _cross or _circle then
				local tmp = frame_y*level.width+frame_x+1
				if tile_storeNum then
					if level.empty[tmp]~=0 and tile_storeNum~=0 then
						if level.empty[tmp] == 1 then
							level.nowBlocks = level.nowBlocks - 1	
						end
						level.empty[tmp] = 0
					end
					if tile_storeNum==0 and level.empty[tmp]==0 then
						if _cross then
							if level.map[tmp] then
								level.empty[tmp] = 1
								level.nowBlocks = level.nowBlocks + 1
								else
								dontPress = true
								level.empty[tmp] = -1
							end
							else
							level.empty[tmp] = -1
						end
					end
					else
					tile_storeNum = level.empty[tmp]
				end
				else
				tile_storeNum = nil
			end
			elseif not (_circle or _cross) then
			dontPress = false
		end
		local pressed = false
		local _up, _down, _left, _right = Controls_check(pad, SCE_CTRL_UP), Controls_check(pad, SCE_CTRL_DOWN), Controls_check(pad, SCE_CTRL_LEFT), Controls_check(pad, SCE_CTRL_RIGHT)
		if _up or _down or _left or _right then
			pressed = true
			if _up ~= Controls_check(newpad, SCE_CTRL_UP) or _down ~= Controls_check(newpad, SCE_CTRL_DOWN) or _left ~= Controls_check(newpad, SCE_CTRL_LEFT) or _right ~= Controls_check(newpad, SCE_CTRL_RIGHT) then
				pause = def_pause
			end
			newpad = pad
		end
		if pause == def_pause or time > pause then
			Timer.reset(actionTimer)
			if _up then
				frame_y = frame_y - 1
				elseif _down then
				frame_y = frame_y + 1
			end
			if _left then
				frame_x = frame_x - 1
				elseif _right then
				frame_x = frame_x + 1
			end
			if frame_y < 0 then 
				frame_y = level.height-1 
				elseif frame_y > level.height-1 then 
				frame_y = 0 
			end
			if frame_x < 0 then 
				frame_x = level.width-1 
				elseif frame_x > level.width-1 then
				frame_x = 0 
			end
			if pressed then
				if pause == def_pause then
					pause = def_pause + 1 
					else 
					pause = lil_pause 
				end
			end
		end
		if not pressed then 
			pause = def_pause 
		end
		else
		if pause < time then
			Timer.reset(actionTimer)
			pause = def_pause
		end
	end
end
local function touchScreen()
	Touch_x,Touch_y,Touch_c,Touch_z = Controls.readTouch()
	if Touch_x~=nil then
		oldTouch_x = oldTouch_x or start_x - Touch_x
		oldTouch_y = oldTouch_y or start_y - Touch_y
		start_x = oldTouch_x + Touch_x
		start_y = oldTouch_y + Touch_y
		square_start_x = start_x + 1
		square_start_y = start_y + 1
		else
		oldTouch_x = nil
		oldTouch_y = nil
	end
end
local function drawOptionsLevel()
	local start_x = (640)/2-5*tile_size + 1
	local start_y = 544/2-5*tile_size
	local level_width = tile_size*10+2
	local level_height = tile_size*10+2
	drawRect(start_x - 2, start_y - 1, level_width, level_height, Colors.Grid)
	local priceXY5 = 5*tile_size
	for i = priceXY5 - 1, priceXY5, priceXY5 do
		if i <= priceXY5 then
			drawRect(start_x + i - 1, start_y + 1, 2, level_height - 4, Colors.X5Lines)
		end
		if i <= priceXY5 then
			drawRect(start_x, start_y + i, level_width - 4, 2, Colors.X5Lines)
		end
	end
	local y = start_y + 1
	for i = 0, 9 do
		local x = start_x
		if floor(i/2) == i/2 then	drawRect(0, y - 1, x - 2, tile_size, Colors.SecondBack) end
		FontLib_print(x - tile_size+6,y+4,"1",Colors.SideNumbers,3)
		for j = 0, 9 do
			drawRect(x, y, square_size, square_size, Colors.Tile)
			if j < i then
				Graphics.drawImage(x, y, cross_tex,Colors.Cross)
			end
			if i==0 then
				if floor(j/2) == j/2 then
					drawRect(x - 1, 0, tile_size, y - 2, Colors.SecondBack)
				end
				FontLib_print(x + half_size-6, y - 20,"1",Colors.SideNumbers,3)
			end
			if j==i then
				Graphics.drawImage(x, y, tile_tex,Colors.Square)
			end
			x = x + tile_size
		end
		y = y + tile_size
	end
	drawEmptyRect(start_x - 2, start_y - 1, frame_size, frame_size, 4, Colors.Frame)
	drawRect(640, 0, 960, 544, Color_new(0,0,0,200))
	if OptionsCLRNow == 0 then
		drawRect(645, 20+16*(OptionsNow-1),310,13, Color_new(0,148,255,150))
		else
		local value = Colors[OptionsNowKey]
		drawRect(10,9,200,79,Color_new(0,0,0,200))
		FontLib_printScaled(16, 13,OptionsNowKey,2,2,Color_new(255,255,255))
		drawRect(16+24-3+24*OptionsCLRNow, 16+26,24,39, Color_new(0,148,255,150))
		FontLib_printScaled(16, 16+26,"0x"..rgb2hex({Color.getR(value),Color.getG(value),Color.getB(value)}),3,3,Color_new(255,255,255))
	end
	local y = 20
	for key, value in pairs(Colors) do
		if y == 20+16*(OptionsNow-1) then 
			OptionsNowKey = key
		end
		FontLib_print(665,y,key,Color_new(255,255,255))
		FontLib_print(865,y,"0x"..rgb2hex({Color.getR(value),Color.getG(value),Color.getB(value)}),Color_new(255,255,255))
		y = y + 16
	end
	FontLib_print(665,y,"Presets",Color_new(255,255,255))
	FontLib_print(765,y,"<"..Options.nowtheme..">",Color_new(255,255,255))
end
local function Controls_Options()
	if OptionsCLRNow==0 then
		if Controls_check(pad, SCE_CTRL_UP) and not Controls_check(oldpad, SCE_CTRL_UP) then
			OptionsNow = OptionsNow - 1
			elseif Controls_check(pad, SCE_CTRL_DOWN) and not Controls_check(oldpad, SCE_CTRL_DOWN) then
			OptionsNow = OptionsNow + 1
		end
		if Controls_check(pad, SCE_CTRL_CROSS) and not Controls_check(oldpad, SCE_CTRL_CROSS) then
			OptionsCLRNow = 1
			Old_color = Colors[OptionsNowKey]
		end
		if OptionsNow<1 then OptionsNow = tlen(Colors)+1 end
		if OptionsNow>tlen(Colors)+1 then OptionsNow = 1 end
		else
		local value = Colors[OptionsNowKey]
		if Controls_check(pad, SCE_CTRL_UP) and not Controls_check(oldpad, SCE_CTRL_UP) then
			Colors[OptionsNowKey] = Color_new(hex2rgb(sub(rgb2hex({Color.getR(value),Color.getG(value),Color.getB(value)}),0,OptionsCLRNow-1)..OptionsColorsNext[sub(rgb2hex({Color.getR(value),Color.getG(value),Color.getB(value)}),OptionsCLRNow,OptionsCLRNow)]..sub(rgb2hex({Color.getR(value),Color.getG(value),Color.getB(value)}),OptionsCLRNow+1,len(rgb2hex({Color.getR(value),Color.getG(value),Color.getB(value)})))))
			elseif Controls_check(pad, SCE_CTRL_DOWN) and not Controls_check(oldpad, SCE_CTRL_DOWN) then
			Colors[OptionsNowKey] = Color_new(hex2rgb(sub(rgb2hex({Color.getR(value),Color.getG(value),Color.getB(value)}),0,OptionsCLRNow-1)..OptionsColorsPrev[sub(rgb2hex({Color.getR(value),Color.getG(value),Color.getB(value)}),OptionsCLRNow,OptionsCLRNow)]..sub(rgb2hex({Color.getR(value),Color.getG(value),Color.getB(value)}),OptionsCLRNow+1,len(rgb2hex({Color.getR(value),Color.getG(value),Color.getB(value)})))))
		end
		if Controls_check(pad, SCE_CTRL_LEFT) and not Controls_check(oldpad, SCE_CTRL_LEFT) then
			OptionsCLRNow = OptionsCLRNow - 1
			elseif Controls_check(pad, SCE_CTRL_RIGHT) and not Controls_check(oldpad, SCE_CTRL_RIGHT) then
			OptionsCLRNow = OptionsCLRNow + 1
		end
		if OptionsCLRNow>6 then OptionsCLRNow = 1 end
		if OptionsCLRNow<1 then OptionsCLRNow = 6 end
		if Controls_check(pad, SCE_CTRL_CROSS) and not Controls_check(oldpad, SCE_CTRL_CROSS) then
			OptionsCLRNow = 0
			if Colors[OptionsNowKey]~= Old_color then
				MakeTheme(dir.."custom.thm", Colors)
				Options["nowtheme"] = "custom"
				updateCfg(configDir, Options)
			end
		end
		if Controls_check(pad, SCE_CTRL_CIRCLE) and not Controls_check(oldpad, SCE_CTRL_CIRCLE) then
			Colors[OptionsNowKey] = Old_color
			OptionsCLRNow = 0
		end
	end
end
Update() --Updating variables for new level
state = 2
while true do
	dt = newTime / 8
	Timer.reset(DeltaTimer)
	Graphics.initBlend()
	if state==1 then
		Screen.clear(Colors.Background)
		drawLevel()
		drawNumbers()
		elseif state==2 then
		Screen.clear(Colors.Background)
		drawOptionsLevel()
	end
	Graphics.termBlend()
	pad = Controls.read()
	if state==1 then
		Controls_frame()
		touchScreen()
		elseif state == 2 then
		Controls_Options()
	end
	if Controls_click(SCE_CTRL_RTRIGGER) then
		if state == 2 then state = 1 else state = 2 end
	end
	if Controls_click(SCE_CTRL_SELECT) then
		FontLib_close()
		FTP = FTP + 1
	end
	Screen.waitVblankStart()
	Screen.flip()
	oldpad = pad
	newTime = Timer.getTime(DeltaTimer)
end