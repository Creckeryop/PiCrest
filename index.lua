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
local DeltaTimer, newTime = Timer.new(), 0
local Controls_check = Controls.check
local Color_new = Color.new
local start_x, start_y, tile_size = 0, 0, 24
local level_width, level_height = 0, 0
local function Update()
	start_x = (960 - level.width*tile_size)/2
	start_y = (544 - level.height*tile_size)/2
	level_width, level_height = level.width*tile_size, level.height*tile_size
	frame_x = 0
	frame_y = 0
	level.empty = {}
	local tmp = 0
	for i = 0, level.height - 1 do
		for j = 0, level.width - 1 do
			level.empty[tmp + j + 1] = false
		end
		tmp = tmp + level.width
	end
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
local function drawLevel()
	drawRect(start_x - 1, start_y - 1, level_width + 2, level_height + 2, Color_new(0, 0, 0))
	drawRect(start_x + frame_x * tile_size - 1, start_y + frame_y * tile_size - 1, tile_size + 2, tile_size + 2, Color_new(255, 0, 0))
	local y = start_y + 1
	local tmp = 0
	for i = 0, level.width - 1 do
		local x = start_x + 1
		for j = 0, level.height - 1 do
			local now = level.map[tmp + j + 1]
			if now then
				Graphics.drawImage(x, y, tile_tex, Color_new(0, 148, 255))
				else
				drawRect(x, y, tile_size - 2, tile_size - 2, Color_new(255, 255, 255))	
			end
			x = x + tile_size
		end
		y = y + tile_size
		tmp = tmp + level.width
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