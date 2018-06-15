_FL_TEX = Graphics.loadImage(appDir.."libs/font.png")
_FL_LEN = string.len
_FL_SUB = string.sub
_FL_SUP = string.upper
_FL_SIN = math.sin
_FL_COS = math.cos
_FL_DPI = Graphics.drawPartialImage
_FL_DIE = Graphics.drawImageExtended
_FL_DEF = 1
FontLib = {
	[1]={
		name = "fixedSys",
		width = 8,
		height = 14,
		startY = 0,
		letters = {
			"0","1","2","3","4","5","6","7","8","9",
			"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
			"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
			" ",".","!","?","-","+","(",")","%","$","#","|","~",":","/","<",">","^","@"
		}
	},
[2] = {
		name = "IdntKnow",
		extrafunc = function (l) return _FL_SUP(l) end,
		width = 9,
		height = 14,
		startY = 14,
		letters = {
			"0","1","2","3","4","5","6","7","8","9",
			"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
			" ",".","!","?","-","+","(",")","%","$","#","|","~",":"
		}
}
}
function FontLib_setLetter(fnt, _x, l)
FontLib[fnt][l] = {x = _x}
end
for i = 1, #FontLib do
	local x, w = 0, FontLib[i].width
	for j = 1, #FontLib[i].letters do
		FontLib_setLetter(i, x, FontLib[i].letters[j])
		x = x + w
	end
end
function FontLib_print(x, y, text, clr, fnt)
	fnt = fnt or _FL_DEF
	local w, h, s, f = FontLib[fnt].width, FontLib[fnt].height, FontLib[fnt].startY, FontLib[fnt].extrafunc
	for i = 1, _FL_LEN(text) do
		local l = _FL_SUB(text, i, i)
		if f then l = f(l) end
		if FontLib[fnt][l] ~= nil then
			_FL_DPI(x, y,_FL_TEX,FontLib[fnt][l].x, s, w, h, clr)
		end
		x = x + w + 1
	end
end
function FontLib_printScaled(x, y, text, size_x, size_y, clr, fnt)
	fnt = fnt or _FL_DEF
	local w, h, s, f = FontLib[fnt].width, FontLib[fnt].height, FontLib[fnt].startY, FontLib[fnt].extrafunc
	local wS = w * size_x
	local Sx, Sy = wS / 2, h * size_y / 2
	for i = 1, _FL_LEN(text) do
		local l = _FL_SUB(text, i, i)
		if f then l = f(l) end
		if FontLib[fnt][l] ~= nil then
			_FL_DIE(x + Sx, y + Sy, _FL_TEX, FontLib[fnt][l].x, s, w, h, 0, size_x, size_y, clr)
		end
		x = x + wS + size_x
	end
end
function FontLib_printRotated(x, y, text, rot, clr, fnt)
	fnt = fnt or _FL_DEF
	local w, h, s, f = FontLib[fnt].width, FontLib[fnt].height, FontLib[fnt].startY, FontLib[fnt].extrafunc
	local sin, cos, len = _FL_SIN(rot), _FL_COS(rot), _FL_LEN(text)
	local wS, hS = w * cos, w * sin
	local Sx, Sy = (len - 1) * wS / 2, (len - 1) * hS / 2
	for i = 1, len do
		local l = _FL_SUB(text, i, i)
		if f then l = f(l) end 
		if FontLib[fnt][l] ~= nil then
			_FL_DIE(x - Sx, y - Sy, _FL_TEX, FontLib[fnt][l].x, s, w, h, rot, 1, 1, clr)
		end
		x = x + wS
		y = y + hS
	end
end
function FontLib_printExtended(x, y, text, size_x, size_y, rot, clr, fnt)
	fnt = fnt or _FL_DEF
	local w, h, s, f = FontLib[fnt].width, FontLib[fnt].height, FontLib[fnt].startY, FontLib[fnt].extrafunc
	local sin, cos, len = _FL_SIN(rot), _FL_COS(rot), _FL_LEN(text)
	local wS, hS = w * size_x * cos, w * size_x * sin
	local Sx, Sy = (len - 1) * wS / 2, (len - 1) * hS / 2
	for i=1, len do
		local l = _FL_SUB(text, i, i)
		if f then l = f(l) end
		if FontLib[fnt][l] ~= nil then
			_FL_DIE(x - Sx, y - Sy, _FL_TEX, FontLib[fnt][l].x, s, w, h, rot, size_x, size_y, clr)
		end
		x = x + wS
		y = y + hS
	end
end
function FontLib_printWShadow(x, sx, y, sy, text, c, sc, fnt)
	FontLib_print(x + sx, y + sy, text, sc, fnt)
	FontLib_print(x, y, text, c, fnt)
end
function FontLib_close()
	Graphics.freeImage(_FL_TEX)
end