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
paletteTable = {}
level = {
	name = "Pikachu",
	width = 10,
	height = 10,
	map = {	1,0,0,1,0,0,0,0,0,1,
			1,1,0,1,1,0,0,0,1,1,
			0,1,1,0,1,1,1,1,1,0,
			0,0,1,1,0,0,0,0,0,1,
			0,0,1,0,0,0,0,0,0,0,
			0,0,1,0,1,0,0,0,0,1,
			0,1,0,1,1,0,0,0,1,1,
			0,1,1,0,0,0,1,0,0,0,
			0,1,1,0,0,1,1,1,0,0,
			0,0,1,1,0,0,0,0,0,1}
}
local DeltaTimer, newTime = Timer.new(), 0
local Controls_check = Controls.check
local Color_new = Color.new
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
	drawRect(0,0,24*level.width,24*level.height, Color_new(0, 0, 0))
	local y = 0
	for i = 0, level.width - 1 do
		local x = 0
		for j = 0, level.height - 1 do
			local now = 1 - level.map[i*level.width+j+1]
			drawRect(x, y, 22, 22, Color_new(255*now, 255*now, 255*now))
			x = x + 24
		end
		y = y + 24
	end
end
Scan_Palette(palette)
while true do
	dt = newTime / 8
	Timer.reset(DeltaTimer)
	pad = Controls.read()
	Graphics.initBlend()
	Screen.clear()
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