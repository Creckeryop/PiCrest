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
level = {}
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
Scan_Palette(palette)
while true do
	dt = newTime / 8
	Timer.reset(DeltaTimer)
	pad = Controls.read()
	Graphics.initBlend()
	Screen.clear()
	
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