local Controls_check, Color_new, Color_getR, Color_getG, Color_getB, Color_getA = Controls.check, Color.new, Color.getR, Color.getG, Color.getB, Color.getA
local Graphics_drawImage, Graphics_dIE = Graphics.drawImage, Graphics.drawImageExtended
local Timer_new, Timer_reset, Timer_resume, Timer_pause, Timer_isPlaying, Timer_getTime, Timer_setTime = Timer.new, Timer.reset, Timer.resume, Timer.pause, Timer.isPlaying, Timer.getTime, Timer.setTime
database = {}
local Libs = { -- Libs to load
	
	"fontLib",
	"PCLrwLib",
	"configLib",
	"themeLib"
	
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
	
	"rescale", "fade", "rotating", "off", now = 1
	
}

local Options = { -- Default options
	
	["nowtheme"] = "default",
	["animation"] = "fade",
	["fps"] = "off",
	["brightness"] = 5
	
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

if not System.doesFileExist (dir.."custom.thm") then -- Creates custom.thm file, if it isn't exists
	
	MakeTheme(dir.."custom.thm", Colors)
	
end

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
local AcceptTheme, MakeTheme = AcceptTheme, MakeTheme
local tile_tex, cross_tex = Graphics.loadImage(dataDir.."tile.png"),Graphics.loadImage(dataDir.."cross.png")
local tile_stackU, tile_stackL = {}, {}
local DeltaTimer, newTime, actionTimer, gameTimer = Timer_new(), 0, Timer_new(), Timer_new()
local FPSTimer = Timer_new()
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
local level = {}
local steps = {"Choosing size"}
local rot_pause, rot_pause_max, rot_options, rot_options_max, rot_yes_or_no, rot_yes_or_no_max  = 0, 16*pie, 0, 16*pie, 0, 16*pie
local numbers_dim = 0

local function ZEWARDO ()
	
	Timer_reset(actionTimer)
	Timer_reset(gameTimer)
	
end

local function Controls_click (BUTTON) -- On click action
	
	return Controls_check(pad, BUTTON) and not Controls_check(oldpad, BUTTON)
	
end

local function newAlpha(color, a)
	if a==255 then return color end
	return Color_new(Color_getR(color), Color_getG(color), Color_getB(color), a)
end

local function change_color(color, f)
	if f == 0 then return color end
	local r, g, b,a = Color_getR(color),Color_getG(color),Color_getB(color),Color_getA(color)
	local L = 0.3 * r + 0.6 * g + 0.1 * b
	return Color_new(r+f*(L-r), g+f*(L-g), b+f*(L-b), a)
end

local function updateAllData ()
	
	for i = 1, #scan_themes do -- Checking system themes
		
		if sub(scan_themes[i].name,len(scan_themes[i].name)-3,len(scan_themes[i].name)) == ".thm" then
			
			themes[#themes+1] = sub(scan_themes[i].name,1,len(scan_themes[i].name) - 4)
			
		end
		
	end
	
	themes[#themes + 1] = "custom" -- Adds custom theme to system themes
	
	readCfg (configDir, Options) -- Loads cfg file
	
	if Options["nowtheme"] == "custom" then -- Load theme from last save
		
		if System.doesFileExist(dir.."custom.thm") then
			
			AcceptTheme(dir.."custom.thm", Colors)
			
			else
			
			Options["nowtheme"] = "default"
			AcceptTheme(themesDir.."default.thm", Colors)
			
		end
		
		else
		
		if System.doesFileExist(themesDir..Options["nowtheme"]..".thm") then
			
			AcceptTheme(themesDir..Options["nowtheme"]..".thm", Colors)
			
			else
			
			Options["nowtheme"] = "default"
			AcceptTheme(themesDir.."default.thm", Colors)
			
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
	
end

local function getRecord (_path)
	local record = 0
	for i=1, #database_p do
		if database_p[i] == _path then
			record = database_m[i]
			break
		end
	end
	return record
end

local function updateRecord (_path, record)
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

local function toDigits (x)
	
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

local function minus ()
	
	Timer_reset(actionTimer)
	pause = lock_time
	tile_oldAdd = tile_nowAdd
	local time = Timer_getTime(gameTimer)+tile_nowAdd*60000
	Timer_setTime(gameTimer,-time)
	if tile_nowAdd==1 then tile_nowAdd=2 elseif tile_nowAdd==2 then tile_nowAdd=4 elseif tile_nowAdd==4 then tile_nowAdd = 8 end
	mh_rot = 0
	
end

local function updateStacks () -- Creating side numbers
	
	for i = 0, max(level.width,level.height) - 1 do
		
		if i < level.width then		tile_stackU[i] = {[0]=0}	end
		
		if i < level.height then	tile_stackL[i] = {[0]=0}	end
		
	end
	
	do --Creating Upper side numbers
		
		for i = 0, level.width-1 do
			
			local now = 0
			
			for j=0, level.height-1 do
				
				if level.map[j*level.width+i+1] then
					
					tile_stackU[i][now] = tile_stackU[i][now] + 1
					
					else
					
					if tile_stackU[i][now] and tile_stackU[i][now] > 0 then
						
						now = now + 1
						tile_stackU[i][now] = 0
						
					end
					
					
				end
				
			end
			
			if tile_stackU[i][now] == 0 and tile_stackU[i][0] ~= 0 then tile_stackU[i][now]=nil end
			
		end
		
		tile_ULen = #tile_stackU
		
	end
	
	do --Creating Left side numbers
		
		local tmp = 0
		
		for i=0, level.height-1 do
			
			local now = 0
			
			for j=0, level.width-1 do
				
				tmp = tmp + 1
				
				if level.map[tmp] then
					
					tile_stackL[i][now] = tile_stackL[i][now] + 1
					
					else
					
					if tile_stackL[i][now] and tile_stackL[i][now] > 0 then
						
						now = now + 1
						tile_stackL[i][now] = 0
						
					end
					
				end
				
			end
			
			if tile_stackL[i][now] == 0 and tile_stackL[i][0]~=0 then tile_stackL[i][now]=nil end
			
		end
		
		tile_LLen = #tile_stackL
		
	end
	
end

local function Update () -- Updating variables for new level
	
	start_x = (960 - level.width * tile_size)/2
	start_y = (544 - (level.height) * tile_size + 19*ceil(level.height / 2))/2 - 4
	square_start_x = start_x + 1
	square_start_y = start_y + 1
	level_width, level_height = level.width * tile_size, level.height * tile_size
	frame_x = 0
	frame_y = 0
	level.empty = {}
	level.record = getRecord(level.path)
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
	ZEWARDO ()
end

local pause_delta, pause_status, pause_gravity, pause_buttons, pause_now, pause_y_buttons, pause_x_buttons = 0, false, 0, {"Continue", "Options", "Exit"}, 0, 340, 50

local yes_or_no_delta, yes_or_no_status, yes_or_no_gravity, yes_or_no_now, yes_or_no_buttons = 0, false, 0, 0,{"Yes", "No"}

local options_delta, options_status, options_gravity, options_buttons, options_now, options_y_buttons, options_x_buttons = 0, false, 0, {"Theme","Brightness","Animation","FPS","Reset saves","Back"}, 0, 250, 480

local function Rotations ()
	
	if yes_or_no_status then
		
		rot_yes_or_no = rot_yes_or_no + pie/60 * dt
		if rot_yes_or_no > rot_yes_or_no_max then rot_yes_or_no = rot_yes_or_no - rot_yes_or_no_max end
	else
	if not options_status and pause_status then
		
		rot_pause = rot_pause + pie/60 * dt
		if rot_pause > rot_pause_max then rot_pause = rot_pause - rot_pause_max end
		
		elseif options_status and pause_status then
		
		rot_options = rot_options + pie/60 * dt
		if rot_options > rot_options_max then rot_options = rot_options - rot_options_max end
		
	end
	end
	
end

local function pause_screen ()
	
	local delta = pause_delta
	
	if not options_status then
		
		if (Controls_click(SCE_CTRL_START) or pause_status and (Controls_click(SCE_CTRL_CIRCLE) or Controls_click(SCE_CTRL_CROSS) and pause_buttons[pause_now] == "Continue")) and (delta==1 or delta==0) then
			
			pause_now = 0
			dontPress = true
			pause_status = not pause_status
			
			if pause_status and Timer_isPlaying(gameTimer) then
				
				Timer_pause(gameTimer)
				
				elseif not (pause_status or Timer_isPlaying(gameTimer)) then
				
				Timer_resume(gameTimer)
				
			end
			
		end
		
	end
	
	if pause_status then
		
		if delta+pause_gravity<1 then
			
			pause_delta = pause_delta + pause_gravity
			pause_gravity = pause_gravity + 0.005*dt
			rot_pause = 0
			
			else
			
			pause_delta = 1
			pause_gravity = 0
			
		end
		
		else
		
		if delta-pause_gravity>0 then
			
			pause_delta = pause_delta - pause_gravity
			pause_gravity = pause_gravity + 0.005*dt
			
			else
			
			pause_delta = 0
			pause_gravity = 0
			
		end
	end
	
	if pause_delta > 0 then
		
		drawRect(0,0,960,544,Color_new(0, 0, 0, 100*delta))
		local y = 544 - (544 -  pause_y_buttons)*pause_delta
		local x = pause_x_buttons
		
		if not options_status then
			
			local _up, _down = Controls_click(SCE_CTRL_UP), Controls_click(SCE_CTRL_DOWN)
			
			if _down then
				
				pause_now = pause_now + 1
				if pause_now > #pause_buttons then	pause_now = 1	end
				
				elseif _up then
				
				pause_now = pause_now - 1
				if pause_now < 1 then	pause_now = #pause_buttons	end
				
			end
			
		end
		--FontLib_printExtended(145, 100*pause_delta+5 - 100*options_delta, "Pause", 5, 5, pie/90*sin(rot_pause/2), Color_new(0,0,0,100*pause_delta - 100*options_delta) )
		FontLib_printExtended(150, 100*pause_delta- 100*options_delta, "Pause", 5, 5, pie/90*sin(rot_pause/2), Color_new(255,255,255,255*pause_delta - 255*options_delta) )
		
		for i = 1, #pause_buttons do
			
			local size = i + 10
			local color = Color_new(255,255,255,255*delta)
			pause_buttons[size] = pause_buttons[size] or 3
			
			if pause_now ~= i then
				
				if pause_buttons[size]>3 then
					
					pause_buttons[size] = pause_buttons[size] - 0.1*dt
					
					elseif pause_buttons[size]<3 then
					
					pause_buttons[size] = 3
					
				end				
				
				else
				
				if pause_buttons[size]<4 then
					
					pause_buttons[size] = pause_buttons[size] + 0.1*dt
					
					elseif pause_buttons[size]>4 then
					
					pause_buttons[size] = 4
					
				end
				
				color = change_color(Color_new(255,216,0,255*delta), options_delta)
				
			end
			
			--FontLib_printScaled (x + 10*(pause_buttons[size] - 4)-4, y+4, pause_buttons[i],pause_buttons[size],pause_buttons[size], shadow)
			FontLib_printScaled (x + 10*(pause_buttons[size] - 4), y, pause_buttons[i],pause_buttons[size],pause_buttons[size], color)
			y = y + 14*pause_buttons[size]
			
		end
		
	end
end

local function options_screen()
	
	local delta = options_delta
	
	if not yes_or_no_status then
	
		if pause_delta and not options_status and Controls_click(SCE_CTRL_CROSS) and pause_buttons[pause_now]=="Options" then
			
			options_status = true
			
		end
		
		if pause_delta and options_status and Controls_click(SCE_CTRL_CIRCLE) or pause_delta and options_status and options_buttons[options_now] == "Back" and Controls_click(SCE_CTRL_CROSS) then
			
			options_now = 0
			options_status = false
			
		end
	end
	
	if options_status then
		
		if delta + options_gravity < 1 then
			
			options_delta = options_delta + options_gravity
			options_gravity = options_gravity + 0.005*dt
			rot_options = 0
			
			else
			
			options_delta = 1
			options_gravity = 0
			
		end
		
		else
		
		if not options_status and delta - options_gravity > 0 then
			
			options_delta = options_delta - options_gravity
			options_gravity = options_gravity + 0.005*dt
			
			else
			
			options_delta = 0
			options_gravity = 0
		end
		
	end
	
	if options_delta > 0 then
		
		drawRect(0,0,960,544,Color_new(0, 0, 0, 100*delta))
		local y = 544 - (544 -  options_y_buttons)*options_delta
		local x = options_x_buttons
		--FontLib_printExtended(options_x_buttons, 100*options_delta+5-100*yes_or_no_delta, "Options", 5, 5, pie/90*sin(rot_options/2), Color_new(0,0,0,100*options_delta-100*yes_or_no_delta) )
		FontLib_printExtended(options_x_buttons, 100*options_delta-100*yes_or_no_delta, "Options", 5, 5, pie/90*sin(rot_options/2), Color_new(255,255,255,255*options_delta-255*yes_or_no_delta) )
		
		if options_status and not yes_or_no_status then
			
			local _up, _down = Controls_click(SCE_CTRL_UP), Controls_click(SCE_CTRL_DOWN)
			
			if _down then
				
				options_now = options_now + 1
				if options_now > #options_buttons then	options_now = 1	end
				
				elseif _up then
				
				options_now = options_now - 1
				if options_now < 1 then	options_now = #options_buttons	end
				
			end
		end
		
		local _left,_right, _cross = Controls_click(SCE_CTRL_LEFT), Controls_click(SCE_CTRL_RIGHT), Controls_click(SCE_CTRL_CROSS)
		for i = 1, #options_buttons do
			
			local size = i + 16
			local color = Color_new(255,255,255,255*delta)
			local rot = 0
			options_buttons[size] = options_buttons[size] or 3
			local text = options_buttons[i]
			
			if options_now ~= i then
				
				if options_buttons[size]>3 then
					
					options_buttons[size] = options_buttons[size] - 0.1*dt
					
					elseif options_buttons[size]<3 then
					
					options_buttons[size] = 3
					
				end				
				
				else
				
				if options_buttons[size]<4 then
					
					options_buttons[size] = options_buttons[size] + 0.1*dt
					
					elseif options_buttons[size]>4 then
					
					options_buttons[size] = 4
					
				end
				
				color = change_color(Color_new(255,216,0,255*delta), yes_or_no_delta)
				rot = pie/60*sin(rot_options)
				
				if _left or _right or _cross then
					
					if text == "FPS" then
						
						if Options["fps"] == "on" then Options["fps"] = "off" else Options["fps"] = "on" end
						updateCfg(configDir, Options)
						
						elseif text == "Animation" then
						
						if _left then
							
							Animations.now = Animations.now - 1
							
							if Animations.now<1 then Animations.now = #Animations end
							
							Options["animation"] = Animations[Animations.now]
							updateCfg(configDir, Options)
							
							elseif _right then
							
							Animations.now = Animations.now + 1
							
							if Animations.now>#Animations then Animations.now = 1 end
							
							Options["animation"] = Animations[Animations.now]
							updateCfg(configDir, Options)
							
						end
						
						elseif text == "Theme" then
						
						if _cross then
							dontPress=true
							state = 2
						end
						
						elseif text == "Brightness" then
						
						if _left then
							if Options["brightness"] > 1 then 
								Options["brightness"] = Options["brightness"] - 1 
								updateCfg(configDir, Options)
							end
							
						elseif _right then
							if Options["brightness"] < 5 then 
								Options["brightness"] = Options["brightness"] + 1
								updateCfg(configDir, Options)
							end
						
						end
						elseif text == "Reset saves" then
							
							if _cross then

								if yes_or_no_status == true then
									if yes_or_no_now~=0 then
									yes_or_no_status = false
									if yes_or_no_now == 1 then
										System.deleteFile(dbDir)
										Update ()
									end
									yes_or_no_now = 0
									else
									yes_or_no_now = 1
									end
									
									else
									yes_or_no_status = true
									
								end
							
							end
					end
				
				end
				
			end
			
			if text == "FPS" then
				text = "FPS <"..Options["fps"]..">"
				elseif text=="Animation" then
				text = "Animation <"..Options["animation"]..">"
				elseif text=="Brightness" then
				text = text.." <"
				for i=1, 5 do
					if i <= Options["brightness"] then
						text = text.."^"
						else
						text = text.." "
					end
				end
				text = text..">"
			end
			
			--FontLib_printExtended (x-4, y+4, text,options_buttons[size],options_buttons[size],rot, shadow)
			FontLib_printExtended (x, y, text,options_buttons[size],options_buttons[size],rot, color)
			y = y + 14*options_buttons[size]
			
		end
		
	end
	
end

local function yes_or_no_screen()
	local delta = yes_or_no_delta
	if yes_or_no_status then
		
		if Controls_click(SCE_CTRL_CIRCLE) then yes_or_no_status = false yes_or_no_now = 0 end 
		
		if delta + yes_or_no_gravity < 1 then
			
			yes_or_no_delta = yes_or_no_delta + yes_or_no_gravity
			yes_or_no_gravity = yes_or_no_gravity + 0.005*dt
			rot_yes_or_no = 0
			
			else
			
			yes_or_no_delta = 1
			yes_or_no_gravity = 0
			
		end
		
		else
		
		if not yes_or_no_status and delta - yes_or_no_gravity > 0 then
			
			yes_or_no_delta = yes_or_no_delta - yes_or_no_gravity
			yes_or_no_gravity = yes_or_no_gravity + 0.005*dt
			
			else
			
			yes_or_no_delta = 0
			yes_or_no_gravity = 0
		end
		
	end
	if delta>0 then
		drawRect(0,0,960,544,Color_new(0, 0, 0, 100*delta))
		--FontLib_printExtended(480, 100*yes_or_no_delta+5, "Are you sure?", 5, 5, pie/90*sin(rot_yes_or_no/2), Color_new(0,0,0,100*yes_or_no_delta) )
		FontLib_printExtended(480, 100*yes_or_no_delta, "Are you sure?", 5, 5, pie/90*sin(rot_yes_or_no/2), Color_new(255,255,255,255*yes_or_no_delta) )
		local _left,_right, _cross = Controls_click(SCE_CTRL_LEFT), Controls_click(SCE_CTRL_RIGHT), Controls_click(SCE_CTRL_CROSS)
		if _left or _right then
			if _left then yes_or_no_now = 1 else yes_or_no_now = 2 end
		end
		local x = 240
		for i=1, #yes_or_no_buttons do
			local size = i + 16
			local color = Color_new(255,255,255,255*delta)
			local rot = 0
			yes_or_no_buttons[size] = yes_or_no_buttons[size] or 3
			if yes_or_no_now ~= i then
				
				if yes_or_no_buttons[size]>3 then
					
					yes_or_no_buttons[size] = yes_or_no_buttons[size] - 0.1*dt
					
					elseif yes_or_no_buttons[size]<3 then
					
					yes_or_no_buttons[size] = 3
					
				end				
				
				else
				
				if yes_or_no_buttons[size]<4 then
					
					yes_or_no_buttons[size] = yes_or_no_buttons[size] + 0.1*dt
					
					elseif yes_or_no_buttons[size]>4 then
					
					yes_or_no_buttons[size] = 4
					
				end
				
				color = Color_new(255,216,0,255*delta)
				rot = pie/60*sin(rot_yes_or_no)
					
			end
			FontLib_printExtended(x, 544-100*yes_or_no_delta, yes_or_no_buttons[i], yes_or_no_buttons[size], yes_or_no_buttons[size], rot, color )
			x = x + 480
		end
	end
end

local function drawLevel () --Draws level
	
	drawRect(start_x - 1, start_y - 1, level_width + 2, level_height + 2, change_color(Colors.Grid, pause_delta))
	local xLine = 0
	local color_x5lines = change_color(Colors.X5Lines, pause_delta)
	
	for i = priceXY5 - 1, max(x5lines, y5lines), priceXY5 do
		
		if i <= x5lines then
			drawRect(start_x + i, start_y+1, 2, level_height-2, color_x5lines)
		end
		
		if i <= y5lines then
			drawRect(start_x+1, start_y + i, level_width-2, 2, color_x5lines)
		end
		
	end
	
	local y = square_start_y
	local tmp = 0
	local color_secondback = change_color(Colors.SecondBack, pause_delta)
	local color_tile = change_color(Colors.Tile, pause_delta)
	local color_cross = change_color(Colors.Cross, pause_delta)
	local color_square = change_color(Colors.Square, pause_delta)
	
	for i = 0, level.height-1 do
		
		local x = square_start_x
		local i_len = i / 2
		
		if floor(i_len) == i_len then	drawRect(0, y - 1, x - 2, tile_size, color_secondback) end
		
		for j = 0, level.width - 1 do
			
			if i == 0 then
				
				local j_tmp = j /2
				
				if floor(j_tmp) == j_tmp then drawRect(x - 1, 0, tile_size, y - 2, color_secondback) end
				
			end
			
			tmp = tmp + 1
			local tmp1,tmp2,tmp3 = level.empty[tmp],level.square[tmp],level.cross[tmp]
			
			if Options["animation"]~="off" and tmp2~=1 then
				
				drawRect(x,y,square_size,square_size,	color_tile)
				
				elseif Options["animation"] == "off" and tmp1~=1 then
				
				drawRect(x,y,square_size,square_size,	color_tile)
				
			end
			
			if Options["animation"] == "fade" then
				
				if tmp3>0 and tmp3<1 then
					Graphics_drawImage(x, y, cross_tex,Color_new(Color_getR(color_cross),Color_getG(color_cross),Color_getB(color_cross),tmp3*255))
					elseif tmp3>0 then
					Graphics_drawImage(x, y, cross_tex,color_cross)
				end
				
				if tmp2>0 and tmp2<1 then
					Graphics_drawImage(x, y, tile_tex,Color_new(Color_getR(color_square),Color_getG(color_square),Color_getB(color_square),tmp2*255))
					elseif tmp2>0 then
					Graphics_drawImage(x, y, tile_tex,color_square)
				end
				
				elseif Options["animation"] == "rescale" then
				
				if tmp3>0 and tmp3<1 then
					Graphics_dIE(x-1+half_size, y-1+half_size, cross_tex,0,0,square_size,square_size,0,tmp3,tmp3,color_cross)
					elseif tmp3>0 then
					Graphics_drawImage(x, y, cross_tex,color_cross)
				end
				
				if tmp2>0 and tmp2<1 then
					Graphics_dIE(x-1+half_size, y-1+half_size, tile_tex ,0,0,square_size,square_size,0,tmp2,tmp2,color_square)
					elseif tmp2>0 then
					Graphics_drawImage(x, y, tile_tex,color_square)
				end
				elseif Options["animation"] == "rotating" then
				
				if tmp3>0 and tmp3<1 then
					Graphics_dIE(x-1+half_size, y-1+half_size, cross_tex,0,0,square_size,square_size,2*pie*tmp3,tmp3,tmp3,color_cross)
					elseif tmp3>0 then
					Graphics_drawImage(x, y, cross_tex,color_cross)
				end
				
				if tmp2>0 and tmp2<1 then
					Graphics_dIE(x-1+half_size, y-1+half_size, tile_tex ,0,0,square_size,square_size,2*pie*tmp2,tmp2,tmp2,color_square)
					elseif tmp2>0 then
					Graphics_drawImage(x, y, tile_tex,color_square)
				end
				elseif Options["animation"] == "off" then
				
				if tmp1 == 1 then
					Graphics_drawImage(x, y, tile_tex,color_square)
					elseif tmp1 == -1 then
					Graphics_drawImage(x, y, cross_tex,color_cross)
				end
				
			end
			
			x = x + tile_size
			local add
			
			if Options["animation"] == "fade" then
				
				add = dt*0.03
				
				elseif Options["animation"] == "rescale" then
				
				add = dt*0.05
				elseif Options["animation"] == "rotating" then
				
				add = dt*0.04
			end
			
			if Options["animation"]~="off" then
				
				if		tmp1 == 1	and tmp2 < 1 then	level.square[tmp]	= tmp2 + add
				elseif	tmp1 == 0	and tmp2 > 0 then	level.square[tmp]	= tmp2 - add	end
				
				if		tmp1 == -1	and tmp3 < 1 then	level.cross[tmp]	= tmp3 + add
				elseif	tmp1 == 0	and tmp3 > 0 then	level.cross[tmp]	= tmp3 - add	end
				
				if		tmp2 > 1 and tmp1 == 1 then	level.square[tmp]	= 1 level.cross[tmp]	= 0
				elseif	tmp2 < 0 and tmp1 == 0 then	level.square[tmp]	= 0		end
				
				if		tmp3 > 1 and tmp1 == -1	then	level.cross[tmp]	= 1 level.square[tmp]	= 0
				elseif	tmp3 < 0 and tmp1 == 0	then	level.cross[tmp]	= 0				end
				
			end
			
		end
		
		y = y + tile_size
		
	end
	
	drawEmptyRect(start_x + frame_x * tile_size - 1, start_y + frame_y * tile_size - 1, frame_size, frame_size, 4, change_color(newAlpha(Colors.Frame, 255*(1-pause_delta)), pause_delta))
	
end

local function drawUpper ()
	
	local time = Timer_getTime(gameTimer)
	local	mt = toDigits(time)
	drawRect(0,0,170,35,black)
	drawRect(0,35,150,20,change_color(Color_new(255,0,0), pause_delta))
	FontLib_printRotated(75,45,"Record: "..level.record,0,white)
	FontLib_printExtended(85,18,mt,2,2,0,white)
	if mh_rot < pie then
		mh_rot = mh_rot + dt * pie/60
		local TwoTwoFive = 255*(1-sin(mh_rot/2))
		FontLib_printExtended(85,17+18*sin(mh_rot),"+00:0"..(tile_oldAdd)..":00 ",2,2,0,Color_new(255,255,255,TwoTwoFive))
		FontLib_printExtended(start_x+(frame_x+1/2)*tile_size-1,start_y+(frame_y+1/2)*tile_size+1,"+"..(tile_oldAdd).."min",8*(1-cos(mh_rot)),8*(1-cos(mh_rot+pie/6)),0,Color_new(0,0,0,TwoTwoFive))
		elseif mh_rot > pie then
		mh_rot = pie
	end
	
end

local function drawNumbers () --Draw side numbers
	
	local xU, yL = start_x + half_size, start_y + half_size - 7
	local yU_start, xL_start = yL - 5, xU - 2
	local maximum = max(level.width,level.height)
	local alen, blen, clen, dlen = tile_ULen, tile_LLen
	local color_sideNumbers = change_color(newAlpha(Colors.SideNumbers, 255*(1-pause_delta)), pause_delta)
	
	for i = 0, maximum do
		
		local yU, xL = yU_start - 5 , xL_start - 5
		local a, b = i<=alen, i<=blen
		
		if a then clen = #tile_stackU[i] end
		
		if b then dlen = #tile_stackL[i] end
		
		for j = maximum, 0, -1 do
			
			if a and j<=clen then
				
				local textU = tile_stackU[i][j]
				yU = yU - 19
				FontLib_print(xU - len(textU) * 5, yU,textU, color_sideNumbers, 3)
			end
			
			if b and j<=dlen then
				
				local textL = tile_stackL[i][j]
				xL = xL - 19
				FontLib_print(xL - len(textL) * 5, yL,textL, color_sideNumbers	, 3)
			end
			
		end
		
		xU = xU + tile_size
		yL = yL + tile_size
		
	end
	
end

local function Controls_frame () --Frame manipulations
	
	local time = Timer_getTime(actionTimer)
	
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
			
			Timer_reset(actionTimer)
			
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
			
			Timer_reset(actionTimer)
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
				
				Graphics_drawImage(x, y, cross_tex,Colors.Cross)
				
			end
			
			if i == 0 then
				
				if floor(j/2) == j/2 then
					
					drawRect(x - 1, 0, tile_size, y - 2, Colors.SecondBack)
					
				end
				
				FontLib_print(x + half_size-6, y - 20,"1",Colors.SideNumbers,3)
				
			end
			
			if j == i then
				
				Graphics_drawImage(x, y, tile_tex,Colors.Square)
				
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
		local red = Color_getR(value)
		local green = Color_getG(value)
		local blue = Color_getB(value)
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
	local tmp = 1
	
	for key, value in pairs(Colors) do
		
		if y == 20+16*(OptionsNow-1) then 
			
			OptionsNowKey = key
			
		end
		
		FontLib_print(665,y,key,white)
		FontLib_print(865,y,"0x"..rgb2hex({Color_getR(value),Color_getG(value),Color_getB(value)}),white)
		y = y + 16
		
	end
	
	FontLib_print(665,y,"Presets",white)
	FontLib_print(889-4*len(themes[themes.now]), y, "<"..themes[themes.now]..">", white)
end

local function Controls_Options() -- Controls in settings screen
	
	local _up, _down, _left, _right, _cross, _circle = Controls_click(SCE_CTRL_UP), Controls_click(SCE_CTRL_DOWN), Controls_click(SCE_CTRL_LEFT), Controls_click(SCE_CTRL_RIGHT), Controls_click(SCE_CTRL_CROSS), Controls_click(SCE_CTRL_CIRCLE)
	local _up2, _down2 = Controls_check(pad, SCE_CTRL_UP), Controls_check(pad, SCE_CTRL_DOWN)
	local time = Timer_getTime(actionTimer)
	if not dontPress then
	if OptionsCLRNow == 0 then
		
		if _up2 then
			
			if opt_pause==optdelay_pause or time > opt_pause then
				
				Timer_reset(actionTimer)
				OptionsNow = OptionsNow - 1 
				
				if OptionsNow<1 then OptionsNow = table.len(Colors) + 1 end
				
				if _up2 or _down2 then
					
					opt_pause = optdelay_pause2
					
				end
				
			end
			
			if not (_up2 or _down2) then
				
				opt_pause = optdelay_pause
				
			end
			
			elseif _down2 then
			
			if opt_pause==optdelay_pause or time > opt_pause then
				
				Timer_reset(actionTimer)
				OptionsNow = OptionsNow + 1
				
				if OptionsNow > table.len(Colors) + 1 then OptionsNow = 1 end
				
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
					
					AcceptTheme(dir.."custom.thm", Colors)
					
					else
					
					AcceptTheme(themesDir..themes[themes.now]..".thm", Colors)
					
				end
				
				Options["nowtheme"] = themes[themes.now]
				updateCfg(configDir, Options)
				
			end
		end
		
		else
		
		local value = Colors[OptionsNowKey]
		
		if _up then
			
			local hex = rgb2hex({Color_getR(value),Color_getG(value),Color_getB(value)})
			Colors[OptionsNowKey] = Color_new(hex2rgb(sub(hex,0,OptionsCLRNow-1)..OptionsColorsNext[sub(hex,OptionsCLRNow,OptionsCLRNow)]..sub(hex,OptionsCLRNow+1,len(hex))))
			
			elseif _down then
			
			local hex = rgb2hex({Color_getR(value),Color_getG(value),Color_getB(value)})
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
	else
		if pad==0 then dontPress = false end
	end
end

local function stepOne ()
	
	drawRectCorn (480 - len("Choose size:")*3*4-10, 20, len("Choose size:")*3*8+20, 80, 5, black )
	FontLib_printExtended (480, 60, "Choose size:", 3, 3, 0, white)
	
end

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

local function UpdateNewLevel ()
	
	newlevel.width = 5
	newlevel.height = 5
	
end

level = openPCL (levelDir.."level1.pcl") -- Loads *.pcl file
updateAllData ()
Update () --Updating variables for new level
state = 3
step = 1
UpdateNewLevel ()
local fps = 0

while true do
	
	dt = newTime / 8
	if Options["fps"]=="on" then
		if Timer_getTime(FPSTimer)>1000 then
			
			Timer_reset(FPSTimer)
			fps = floor(1000 / newTime)
			
		end
	end
	Timer_reset (DeltaTimer)
	Graphics.initBlend ()
	pad = Controls.read ()
	
	if state == 1 then
		
		Screen.clear (change_color(Colors.Background, pause_delta))
		drawLevel ()
		
		if pause_delta ~= 1 then
			
			drawNumbers ()
			
			elseif pause_delta==1 then
			
			Rotations ()
			
		end
		
		drawUpper ()
		pause_screen ()
		if pause_delta > 0 then
			options_screen ()
		end
		yes_or_no_screen ()
		
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
	if Options["fps"]=="on" then
		drawRect(930,0,30,20,black)
		FontLib_printRotated(945,10,fps,0,white)
	end
	drawRect(0,0,960,544,Color_new(0,0,0,150-30*Options["brightness"]))
	Graphics.termBlend ()
	
	if state == 1 then
		
		if not pause_status then
			
			Controls_frame ()
			
		end
		
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
	
	if pause_delta==0 or pause_delta==1 then
		Screen.waitVblankStart ()
	end
	
	Screen.flip ()
	oldpad = pad
	newTime = Timer_getTime (DeltaTimer)
	
end