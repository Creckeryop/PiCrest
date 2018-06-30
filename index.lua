local Controls_check, Color_new = Controls.check, Color.new

database = {}
local Libs = { -- Libs to load
	
	"fontLib",
	"PCLrwLib",
	"configLib"
	
}

local Colors = { -- default theme
	
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

local OptionsColorsNext = { -- x => x + 1
	
	["0"] = "1", ["1"] = "2", ["2"] = "3", ["3"] = "4", ["4"] = "5", ["5"] = "6", ["6"] = "7", ["7"] = "8", ["8"] = "9", ["9"] = "A", ["A"] = "B", ["B"] = "C", ["C"] = "D", ["D"] = "E", ["E"] = "F", ["F"] = "0"
	
}

local OptionsColorsPrev = { -- x => x - 1
	
	["0"] = "F", ["1"] = "0", ["2"] = "1", ["3"] = "2", ["4"] = "3", ["5"] = "4", ["6"] = "5", ["7"] = "6", ["8"] = "7", ["9"] = "8", ["A"] = "9", ["B"] = "A", ["C"] = "B", ["D"] = "C", ["E"] = "D", ["F"] = "E"
	
}

local Animations = {
	
	"rescale", "fade", "off", now = 1
	
}

appDir = "ux0:data/BL/" --Dir for app0
dataDir = appDir.."data/" --Dir for data in app0
libDir = dataDir.."libs/" --Dir for libs in app0
levelDir = dataDir.."lvls/" --Dir for levels in app0
themesDir = dataDir.."thms/" --Dir for levels in app0
dir = "ux0:data/BL/" --Dir for ux0:data/PiCrest
configDir = dir.."config.ini"
clevelDir = dir.."levels/" --Dir for custom levels
dbDir = dir.."save.db"

if not System.doesFileExist(dbDir) then
	db = Database.open(dbDir)
	Database.execQuery(db, "CREATE TABLE REC(path varchar(255),ms Bigint);")
	Database.close(db)
end

db = Database.open(dbDir)
database_p = Database.execQuery(db, "SELECT path FROM [REC];")
Database.close(db)
db = Database.open(dbDir)
database_m = Database.execQuery(db, "SELECT ms FROM [REC];")
Database.close(db)

for i = 1, #Libs do -- Loads all libs
	
	dofile(libDir..Libs[i]..".lua")
	
end

function table.len (t) -- returns table length 
	
	local a = 0
	
	for k, v in pairs(t) do
		
		a = a + 1
		
	end
	
	return a
	
end

local pie = math.pi
local hex2rgb, rgb2hex = hex2rgb, rgb2hex
local openPCL, updatePCL, createPCL, getRNPCL = PCL_Lib.open, PCL_Lib.update, PCL_Lib.create, PCL_Lib.getRN
local readCfg, updateCfg = readCfg, updateCfg
local tile_tex, cross_tex = Graphics.loadImage(dataDir.."tile.png"),Graphics.loadImage(dataDir.."cross.png")
local tile = {stackU = {}, stackL = {}}
local DeltaTimer, newTime, actionTimer, gameTimer = Timer.new(), 0, Timer.new(), Timer.new()
local start_x, start_y, tile_size = 0, 0, 24
local half_size, square_size, square_start_x, square_start_y = tile_size / 2, tile_size - 2, start_x + 1,start_y + 1
local level_width, level_height = 0, 0
local frame_x, frame_y, x5lines, y5lines, priceXY5, frame_size = 0, 0, 0, 0, 0, tile_size + 2
local sqrt, ceil, max, len, floor, sub, sin, cos = math.sqrt, math.ceil, math.max, string.len, math.floor, string.sub, math.sin, math.cos
local dontPress = false
local lock_time, def_pause,optdelay_pause,optdelay_pause2, lil_pause = 1000, 200,300,150, 60
local pause, opt_pause = def_pause, optdelay_pause
local oldpad, newpad = SCE_CTRL_CROSS, SCE_CTRL_CROSS
local OptionsNow, OptionsCLRNow, OptionsNowKey, Old_color = 1, 0, 0, Color_new(0,0,0)
local scan_themes, themes = System.listDirectory(themesDir),{now = 1} -- Scanning system themes
local white = Color_new (255, 255, 255)
local black = Color_new (0, 0, 0)
local shadow = Color_new (0, 0, 0, 100)
local newlevel = {}
local tile_oldAdd, tile_nowAdd = 1, 1
local mh_rot = pie

local function getRecord(_path)
	local record = 0
	for i=1, #database_p do
		if database_p[i] == _path then
			record = database_m[i]
			break
		end
	end
	return record
end

local function updateRecord(_path, record)
	local id = #database_p + 1
	local create = true
	for i=1, #database_p do
		if database_p[i] == _path then
			id = i
			create = false
			break
		end
	end
	database_m[id] = record
	db = Database.open(dbDir)
	if create then
		database_p[id] = _path
		Database.execQuery(db, "INSERT INTO REC VALUES ('".._path.."',"..record..");")
		else
		Database.execQuery(db, "UPDATE [REC] SET ms = "..record..", WHERE path = '".._path.."';")
	end
	Database.close(db)
end

local function toDigits(x)
	
	local mt1000 = floor(x / 1000)
	local mt60 = floor(mt1000 / 60)
	local h = floor(mt60 / 60)
	if h > 99 then return "99:59:59" end
	local m = mt60 - h * 60					
	local s = mt1000 - mt60 * 60	
	
	if len(h)==1 then		h = "0"..h	end
	
	if len(m)==1 then		m = "0"..m	end
	
	if len(s)==1 then		s = "0"..s	end
	
	return h..":"..m..":"..s
	
end

local function drawRect (x, y, w, h, c) -- drawRect x, y, width, height, color
	
	Graphics.fillRect(x, x + w, y, y + h, c)
	
end

local function drawRectCorn (x, y, w, h, r, c) -- drawRect with Circle corners x, y, width, height, radius, color
	
	local r2,yr,xr,xwr,yhr = 2*r,y+r,x+r,x+w-r,y+h-r
	drawRect(xr,y,w-r2,h,c)
	drawRect(x,yr,r,h-r2,c)
	drawRect(xwr,yr,r,h-r2,c)
	Graphics.fillCircle(xr,yr,r,c)
	Graphics.fillCircle(xwr,yr,r,c)
	Graphics.fillCircle(xr,yhr,r,c)
	Graphics.fillCircle(xwr,yhr,r,c)
	
end

local function drawEmptyRect (x, y, w, h, t, c) -- drawRect outline x, y, width, height, thin, color
	
	drawRect(x, y, t, h, c)
	drawRect(x + t, y, w - 2 * t, t, c)
	drawRect(x + w - t, y, t, h, c)
	drawRect(x + t, y + h - t, w - 2 * t, t, c)
	
end

for i = 1, #scan_themes do -- Checking system themes
	
	if sub(scan_themes[i].name,len(scan_themes[i].name)-3,len(scan_themes[i].name)) == ".thm" then
		
		themes[#themes+1] = sub(scan_themes[i].name,1,len(scan_themes[i].name) - 4)
		
	end
	
end

themes[#themes + 1] = "custom" -- Adds custom theme to system themes
local level = openPCL (levelDir.."level1.pcl") -- Loads *.pcl file

local Options = { -- Default options
	
	["nowtheme"] = "default",
	["animation"] = "fade"
	
}

readCfg (configDir, Options) -- Loads cfg file

local function MakeTheme (_path, table) -- saves custom theme to default directory
	
	System.deleteFile(_path)
	local thm = System.openFile(_path, FCREATE)
	
	for k,v in pairs(table) do
		
		local hex = rgb2hex({Color.getR(v),Color.getG(v), Color.getB(v)})
		System.writeFile(thm, k.." "..hex..'\n', len(k.." "..hex..'\n'))
		
	end
	
	System.closeFile(thm)
end

local function AcceptTheme (_path) -- Loads theme from *.thm file
	
	local thm = System.openFile(_path, FREAD)
	local thm_size = System.sizeFile(thm)
	local k,key,value = true,"",""
	
	for i = 1, thm_size do
		
		local str = System.readFile(thm, 1)
		local byte = string.byte(str)
		
		if byte ~= 13 and byte~=10 then
			
			if str == ' ' then 
				
				k = false
				
				else
				
				if k then
					
					key = key..str
					
					else
					
					value = value..str
					
				end
				
			end
			
			elseif byte == 10 then
			
			k = true
			Colors[key] = Color.new(hex2rgb(value)) 
			key = ''
			value = ''
			
		end 
		
		if byte~=10 and i == thm_size then
			
			k = true
			
			Colors[key] = Color.new(hex2rgb(value)) 
			
			key = ''
			
			value = ''
			
		end
		
	end
	
	System.closeFile(thm)
	
end

if Options["nowtheme"] == "custom" then -- Load theme from last save
	
	if System.doesFileExist(dir.."custom.thm") then
		
		AcceptTheme(dir.."custom.thm")
		
		else
		
		Options["nowtheme"] = "default"
		AcceptTheme(themesDir.."default.thm")
		
	end
	
	else
	
	if System.doesFileExist(themesDir..Options["nowtheme"]..".thm") then
		
		AcceptTheme(themesDir..Options["nowtheme"]..".thm")
		
		else
		
		Options["nowtheme"] = "default"
		AcceptTheme(themesDir.."default.thm")
		
	end
	
end

for i=1, #themes do
	
	if themes[i] == Options["nowtheme"] then
		
		themes.now = i
		break
		
	end
	
end

for i=1, #Animations do 
	
	if Animations[i] == Options["animation"] then
		
		Animations.now = i
		break
		
	end
	
end

updateCfg (configDir, Options) -- Save changing

local function minus()
	
	Timer.reset(actionTimer)
	pause = lock_time
	tile_oldAdd = tile_nowAdd
	local time = Timer.getTime(gameTimer)+tile_nowAdd*60000
	Timer.setTime(gameTimer,-time)
	if tile_nowAdd==1 then tile_nowAdd=2 elseif tile_nowAdd==2 then tile_nowAdd=4 elseif tile_nowAdd==4 then tile_nowAdd = 8 end
	mh_rot = 0
	
end

if not System.doesFileExist (dir.."custom.thm") then -- Creates custom.thm file, if it isn't exists
	
	MakeTheme(dir.."custom.thm", Colors)
	
end

local function updateStacks () -- Creating side numbers
	
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
			
			if tile.stackL[i][now] == 0 and tile.stackL[i][0]~=0 then tile.stackL[i][now]=nil end
			
		end
		
		tile.LLen = #tile.stackL
		
	end
	
end

local function Update (_path) -- Updating variables for new level
	
	start_x = (960 - level.width * tile_size)/2
	start_y = (544 - (level.height) * tile_size + 19*ceil(level.height / 2))/2 - 4
	square_start_x = start_x + 1
	square_start_y = start_y + 1
	level_width, level_height = level.width * tile_size, level.height * tile_size
	frame_x = 0
	frame_y = 0
	level.empty = {}
	level.record = getRecord(_path)
	level.recInms = level.record
	level.record = toDigits(level.record)
	level.cross = {}
	level.square = {}
	level.nowBlocks = 0
	level.allBlocks = 0
	tile_oldAdd, tile_nowAdd = 1, 1
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

local function Controls_click (BUTTON) -- On click action
	
	return Controls_check(pad, BUTTON) and not Controls_check(oldpad, BUTTON)
	
end

local function drawLevel () --Draws level
	
	drawRect(start_x - 1, start_y - 1, level_width + 2, level_height + 2, Colors.Grid)
	local xLine = 0
	
	for i = priceXY5 - 1, max(x5lines, y5lines), priceXY5 do
		
		if i <= x5lines then
			drawRect(start_x + i, start_y+1, 2, level_height-2, Colors.X5Lines)
		end
		
		if i <= y5lines then
			drawRect(start_x+1, start_y + i, level_width-2, 2, Colors.X5Lines)
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
				
				elseif Options["animation"] == "off" and tmp1~=1 then
				
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
				
				elseif Options["animation"] == "rescale" then
				
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
				
				elseif Options["animation"] == "off" then
				
				if tmp1 == 1 then
					Graphics.drawImage(x, y, tile_tex,Colors.Square)
					elseif tmp1 == -1 then
					Graphics.drawImage(x, y, cross_tex,Colors.Cross)
				end
				
			end
			
			x = x + tile_size
			local add
			
			if Options["animation"] == "fade" then
				
				add = dt*0.03
				
				elseif Options["animation"] == "rescale" then
				
				add = dt*0.05
				
			end
			
			if Options["animation"]~="off" then
				
				if		tmp1 == 1	and tmp2 < 1 then	level.square[tmp]	= tmp2 + add
				elseif	tmp1 == 0	and tmp2 > 0 then	level.square[tmp]	= tmp2 - add	end
				
				if		tmp1 == -1	and tmp3 < 1 then	level.cross[tmp]	= tmp3 + add
				elseif	tmp1 == 0	and tmp3 > 0 then	level.cross[tmp]	= tmp3 - add	end
				
				if		tmp1 == 1	and tmp2 > 1 then	level.square[tmp]	= 1 level.cross[tmp]	= 0
				elseif	tmp1 == 0	and tmp2 < 0 then	level.square[tmp]	= 0		end
				
				if		tmp1 == -1	and tmp3 > 1 then	level.cross[tmp]	= 1 level.square[tmp]	= 0
				elseif	tmp1 == 0	and tmp3 < 0 then	level.cross[tmp]	= 0				end
				
			end
			
		end
		
		y = y + tile_size
		
	end
	
	drawEmptyRect(start_x + frame_x * tile_size - 1, start_y + frame_y * tile_size - 1, frame_size, frame_size, 4, Colors.Frame)
	
end

local function drawUpper ()
	
	local time = Timer.getTime(gameTimer)
	local	mt = toDigits(time)
	drawRect(0,35,150,20,Color_new(255,0,0))
	drawRect(0,0,170,35,black)
	FontLib_printRotated(75,45,"Record: "..level.record,0,white)
	FontLib_printExtended(85,18,mt,2,2,0,white)
	if mh_rot < pie then
		mh_rot = mh_rot + dt * pie/60
		local TwoTwoFive = 255*sin(mh_rot/2)
		FontLib_printExtended(85,17+18*sin(mh_rot),"+00:0"..(tile_oldAdd)..":00 ",2,2,0,Color.new(255,255,255,255-TwoTwoFive))
		FontLib_printExtended(start_x+(frame_x+1/2)*tile_size-1,start_y+(frame_y+1/2)*tile_size+1,"+"..(tile_oldAdd).."min",8-8*cos(mh_rot),8-8*cos(mh_rot+pie/6),0,Color.new(0,0,0,255-TwoTwoFive))
		elseif mh_rot > pie then
		mh_rot = pie
	end
	
end

local function drawNumbers () --Draw side numbers
	
	local xU, yL = start_x + half_size, start_y + half_size - 7
	local yU_start, xL_start = yL - 5, xU - 2
	local maximum = max(level.width,level.height)
	local alen, blen, clen, dlen = tile.ULen, tile.LLen
	
	for i = 0, maximum do
		
		local yU, xL = yU_start - 5 , xL_start - 5
		local a, b = i<=alen, i<=blen
		
		if a then clen = #tile.stackU[i] end
		
		if b then dlen = #tile.stackL[i] end
		
		for j = maximum, 0, -1 do
			
			if a and j<=clen then
				
				local textU = tile.stackU[i][j]
				yU = yU - 19
				FontLib_print(xU - len(textU) * 5, yU,textU, Colors.SideNumbers, 3)
			end
			
			if b and j<=dlen then
				
				local textL = tile.stackL[i][j]
				xL = xL - 19
				FontLib_print(xL - len(textL) * 5, yL,textL, Colors.SideNumbers, 3)
			end
			
		end
		
		xU = xU + tile_size
		yL = yL + tile_size
		
	end
	
end

local function Controls_frame () --Frame manipulations
	
	local time = Timer.getTime(actionTimer)
	
	if pause ~= lock_time then
		
		local _cross, _circle = Controls.check(pad, SCE_CTRL_CROSS), Controls.check(pad, SCE_CTRL_CIRCLE)
		
		if not dontPress then
			
			if _cross or _circle then
				
				local tmp = frame_y*level.width+frame_x+1
				
				if tile_storeNum then
					
					if level.empty[tmp] ~= 0 and tile_storeNum ~= 0 then
						
						if level.empty[tmp] == 1 then
							
							level.nowBlocks = level.nowBlocks - 1	
							
						end
						
						level.empty[tmp] = 0
						
					end
					
					if tile_storeNum == 0 and level.empty[tmp] == 0 then
						
						if _cross then
							
							if level.map[tmp] then
								
								level.empty[tmp] = 1
								level.nowBlocks = level.nowBlocks + 1
								
								else
								
								dontPress = true
								level.empty[tmp] = -1
								minus()
								
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
				
				if frame_y < 0 then 
					
					frame_y = level.height-1 
					
				end
				
				elseif _down then
				
				frame_y = frame_y + 1
				
				if frame_y > level.height-1 then 
					
					frame_y = 0 
					
				end
				
			end
			
			if _left then
				
				frame_x = frame_x - 1
				
				if frame_x < 0 then 
					
					frame_x = level.width-1 
					
				end
				
				elseif _right then
				
				frame_x = frame_x + 1
				
				if frame_x > level.width-1 then
					
					frame_x = 0 
					
				end
				
			end
			
			if pressed then
				
				if pause == def_pause then
					
					pause = def_pause + 1 
					
					else 
					
					pause = lil_pause 
					
				end
				
			end
			
		end
		
		if not pressed and pause~=lock_time then 
			
			pause = def_pause 
			
		end
		
		else
		
		if pause < time then
			
			Timer.reset(actionTimer)
			pause = def_pause
			
		end
		
	end
	
end

local function touchScreen () -- Moving level
	
	Touch_x,Touch_y,Touch_c,Touch_z = Controls.readTouch()
	
	if Touch_x~=nil and Touch_c==nil then
		
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

local function drawOptionsLevel () -- Draw Color settings screen
	
	local priceXY5 = 5*tile_size
	local start_x = (640)/2-priceXY5 + 1
	local start_y = 544/2-priceXY5
	local level_width = priceXY5*2+2
	local level_height = priceXY5*2+2
	drawRect(start_x - 2, start_y - 1, level_width, level_height, Colors.Grid)
	
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
		
		if floor(i / 2) == i / 2 then	drawRect(0, y - 1, x - 2, tile_size, Colors.SecondBack) end
		
		FontLib_print(x - tile_size + 6, y + 4, "1", Colors.SideNumbers, 3)
		
		for j = 0, 9 do
			
			drawRect(x, y, square_size, square_size, Colors.Tile)
			
			if j < i then
				
				Graphics.drawImage(x, y, cross_tex,Colors.Cross)
				
			end
			
			if i == 0 then
				
				if floor(j/2) == j/2 then
					
					drawRect(x - 1, 0, tile_size, y - 2, Colors.SecondBack)
					
				end
				
				FontLib_print(x + half_size-6, y - 20,"1",Colors.SideNumbers,3)
				
			end
			
			if j == i then
				
				Graphics.drawImage(x, y, tile_tex,Colors.Square)
				
			end
			
			x = x + tile_size
			
		end
		
		y = y + tile_size
		
	end
	
	drawEmptyRect(start_x - 2, start_y - 1, frame_size, frame_size, 4, Colors.Frame)
	
	drawRect(640, 0, 960, 544, Color_new(0,0,0,200))
	
	if OptionsCLRNow == 0 then
		
		drawRect(645, 20 + 16 * (OptionsNow - 1), 310, 13, Color_new(0,148,255,150))
		
		else
		
		local value = Colors[OptionsNowKey]
		local red = Color.getR(value)
		local green = Color.getG(value)
		local blue = Color.getB(value)
		drawRectCorn(228,435,200,105,10,black)
		FontLib_printExtended(328, 453, OptionsNowKey, 2, 2, 0, white)
		drawRect(258+24*OptionsCLRNow, 480,21,31, Color_new(0,148,255,150))
		FontLib_printScaled(236, 476,"0x"..rgb2hex({red, green, blue}), 3, 3,white)
		
		for i = len (red), 2 do	red = " "..red end
		for i = len (green), 2 do green = " "..green end
		for i = len (blue), 2 do blue = " "..blue end
		
		drawRect(233, 467, 44, 10, value)
		drawEmptyRect(233, 466, 44, 12,1, white)
		FontLib_printScaled(233, 467,"   "..red..green..blue,2,1, white)
		FontLib_print(238, 516 , "x - accept   o - cancel", white)
		
	end
	
	local y = 20
	
	for key, value in pairs(Colors) do
		
		if y == 20+16*(OptionsNow-1) then 
			
			OptionsNowKey = key
			
		end
		
		FontLib_print(665,y,key,white)
		FontLib_print(865,y,"0x"..rgb2hex({Color.getR(value),Color.getG(value),Color.getB(value)}),white)
		y = y + 16
		
	end
	
	FontLib_print(665,y,"Presets",white)
	FontLib_print(889-4*len(themes[themes.now]), y, "<"..themes[themes.now]..">", white)
	y = y + 16
	FontLib_print(665, y,"Animation",white)
	FontLib_print(889-4*len(Animations[Animations.now]), y, "<"..Animations[Animations.now]..">", white)
	
end

local function Controls_Options() -- Controls in settings screen
	
	local _up, _down, _left, _right, _cross, _circle = Controls_click(SCE_CTRL_UP), Controls_click(SCE_CTRL_DOWN), Controls_click(SCE_CTRL_LEFT), Controls_click(SCE_CTRL_RIGHT), Controls_click(SCE_CTRL_CROSS), Controls_click(SCE_CTRL_CIRCLE)
	local _up2, _down2 = Controls_check(pad, SCE_CTRL_UP), Controls_check(pad, SCE_CTRL_DOWN)
	local time = Timer.getTime(actionTimer)
	
	if OptionsCLRNow == 0 then
		
			if _up2 then
				if opt_pause==optdelay_pause or time > opt_pause then
				Timer.reset(actionTimer)
				OptionsNow = OptionsNow - 1 
				
				if OptionsNow<1 then OptionsNow = table.len(Colors) + 2  end
				if _up2 or _down2 then
					opt_pause = optdelay_pause2
				end
				end
				if not (_up2 or _down2) then
				opt_pause = optdelay_pause
				end
				
			elseif _down2 then
				
				if opt_pause==optdelay_pause or time > opt_pause then
				Timer.reset(actionTimer)
				OptionsNow = OptionsNow + 1
				
				if OptionsNow > table.len(Colors) + 2 then OptionsNow = 1 end
				if _up2 or _down2 then
					opt_pause = optdelay_pause2
				end
				end
				if not (_up2 or _down2) then
				opt_pause = optdelay_pause
				end
						
		elseif _cross and OptionsNow < table.len(Colors) + 1 then
			
			OptionsCLRNow = 1
			Old_color = Colors[OptionsNowKey]
			
			elseif _left or _right then
			
			local table_len = table.len(Colors)
			
			if OptionsNow == table_len + 1 then
				
				if _left then
					
					themes.now = themes.now - 1
					
					if themes.now<1 then themes.now = #themes end
					
					elseif _right then
					
					themes.now = themes.now + 1
					if themes.now>#themes then themes.now = 1 end
					
				end
				
				if themes.now == #themes then
					
					AcceptTheme(dir.."custom.thm")
					
					else
					
					AcceptTheme(themesDir..themes[themes.now]..".thm")
					
				end
				
				Options["nowtheme"] = themes[themes.now]
				updateCfg(configDir, Options)
				
				elseif OptionsNow == table_len + 2 then
				
				if _left then
					
					Animations.now = Animations.now - 1
					
					if Animations.now<1 then Animations.now = #Animations end
					
					elseif _right then
					
					Animations.now = Animations.now + 1
					
					if Animations.now>#Animations then Animations.now = 1 end
					
				end
				
				Options["animation"] = Animations[Animations.now]
				updateCfg(configDir, Options)
				
			end
		end
		
		else
		
		local value = Colors[OptionsNowKey]
		
		if _up then
			
			local hex = rgb2hex({Color.getR(value),Color.getG(value),Color.getB(value)})
			Colors[OptionsNowKey] = Color_new(hex2rgb(sub(hex,0,OptionsCLRNow-1)..OptionsColorsNext[sub(hex,OptionsCLRNow,OptionsCLRNow)]..sub(hex,OptionsCLRNow+1,len(hex))))
			
			elseif _down then
			
			local hex = rgb2hex({Color.getR(value),Color.getG(value),Color.getB(value)})
			Colors[OptionsNowKey] = Color_new(hex2rgb(sub(hex,0,OptionsCLRNow-1)..OptionsColorsPrev[sub(hex,OptionsCLRNow,OptionsCLRNow)]..sub(hex,OptionsCLRNow+1,len(hex))))
			
			elseif _left then
			
			OptionsCLRNow = OptionsCLRNow - 1
			
			if OptionsCLRNow < 1 then OptionsCLRNow = 6 end
			
			elseif _right then
			
			OptionsCLRNow = OptionsCLRNow + 1
			
			if OptionsCLRNow > 6 then OptionsCLRNow = 1 end
			
			elseif _cross then
			
			OptionsCLRNow = 0
			
			if Colors[OptionsNowKey] ~= Old_color then
				
				MakeTheme(dir.."custom.thm", Colors)
				themes.now = #themes
				Options["nowtheme"] = "custom"
				
				updateCfg(configDir, Options)
				
			end
			
			elseif _circle then
			
			Colors[OptionsNowKey] = Old_color
			
			OptionsCLRNow = 0
			
		end
		
	end
	
end

local function stepOne ()
	
	drawRectCorn (480 - len("Choose size:")*3*4-10, 20, len("Choose size:")*3*8+20, 80, 5, black )
	FontLib_printExtended (480, 60, "Choose size:", 3, 3, 0, white)
	
end

local steps = {"Choosing size"}

local function progressBar ()
	
	local text = "Step "..step.."/"..#steps.." - "..steps[step]
	drawRectCorn (480 - len(text)*2*4 - 20, 544 - 60, len(text)*2*8+40, 40, 5, black)
	FontLib_printExtended (480, 544 - 40, text, 2, 2, 0, white)
	
	if Controls_click(SCE_CTRL_LEFT) then
		newlevel.width = newlevel.width - 5
		elseif Controls_click(SCE_CTRL_RIGHT) then
		newlevel.width = newlevel.width + 5
		elseif Controls_click(SCE_CTRL_UP) then
		newlevel.height = newlevel.height - 5
		elseif Controls_click(SCE_CTRL_DOWN) then
		newlevel.height = newlevel.height + 5
	end
	if newlevel.width>15 then newlevel.width = 15 end
	if newlevel.width<5 then newlevel.width = 5 end
	if newlevel.height>15 then newlevel.height = 15 end
	if newlevel.height<5 then newlevel.height = 5 end
	
	local start_y = 272 - newlevel.height*half_size + 20
	local start_x = 480 - newlevel.width*half_size
	drawRect(start_x - 1, start_y - 1, newlevel.width*tile_size + 2, newlevel.height*tile_size + 2, Colors.Grid)
	for i = 1, newlevel.height do
		local x = start_x
		for j = 1, newlevel.width do
			drawRect(x + 1, start_y + 1, square_size, square_size, Colors.Tile)
			x = x + tile_size
		end
		start_y = start_y + tile_size
	end
end

local function UpdateNewLevel()
	
	newlevel.width = 5
	newlevel.height = 5
	
end

Update (levelDir.."level1.pcl") --Updating variables for new level
state = 3
step = 1
UpdateNewLevel ()

while true do
	
	dt = newTime / 8
	Timer.reset (DeltaTimer)
	Graphics.initBlend ()
	pad = Controls.read ()
	if state == 1 then
		
		Screen.clear (Colors.Background)
		drawLevel ()
		drawNumbers ()
		drawUpper ()
		
		elseif state == 2 then
		
		Screen.clear (Colors.Background)
		drawOptionsLevel ()
		
		elseif state == 3 then
		
		if step == 1 then
			
			Screen.clear (Colors.Background)
			stepOne ()
			
		end
		
		progressBar ()
		
	end
	Graphics.termBlend ()
	
	if state == 1 then
		
		Controls_frame ()
		--touchScreen ()
		
		elseif state == 2 then
		
		Controls_Options ()
		
	end
	
	if Controls_click (SCE_CTRL_RTRIGGER) then
		
		if state == 2 then state = 1 else state = 2 end
		
	end
	
	if Controls_click (SCE_CTRL_SELECT) then
		
		FontLib_close ()
		FTP = FTP + 1
		
	end
	
	Screen.waitVblankStart ()
	Screen.flip ()
	oldpad = pad
	newTime = Timer.getTime (DeltaTimer)
	
end