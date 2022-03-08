local _FL_TEX = Graphics.loadImage(libDir.."fnt.png")
local _FL_LEN = function(str) return #(tostring(str):gsub('[\128-\191]', '')) end
local _FL_SUB = string.sub
local _FL_SUP = string.upper
local _FL_SIN = math.sin
local _FL_COS = math.cos
local _FL_DPI = Graphics.drawPartialImage
local _FL_DIE = Graphics.drawImageExtended
local _FL_DEF = 1

FontLib = {
	[1]={
		width = 8,
		height = 14,
		startY = 0,
		letters = {
			"0","1","2","3","4","5","6","7","8","9",
			"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
			"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
			" ",".","!","?","-","+","(",")","%","$","#","|","~",":","/","<",">","^","@",","
		}
	},
	[2] = {
		width = 8,
		height = 14,
		startY = 31,
		letters = {
			"0","1","2","3","4","5","6","7","8","9",
			"A","B","V","G","D","E","J","Z","I","~","K","L","M","N","O","P","R","S","T","U","F","H","C","X","W","Y","\"","}","Q","{",
			"a","b","v","g","d","e","j","z","i","`","k","l","m","n","o","p","r","s","t","u","f","h","c","x","w","y","'","]","q","[",
			" ",".","!","?","-","+","(",")","%","$","#","|","~~",":","/","<",">","^","@",","
		}
		},
	[3]={
		width = 8,
		height = 14,
		startY = 47,
		letters = {
			"0","1","2","3","4","5","6","7","8","9",
			"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
			"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
			" ",".","!","?","-","+","(",")","%","$","#","|","~",":","/","<",">","^","@",","
		}
	},
	[4]={
		width = 16,
		height = 16,
		startY = 62,
		maxSyms = 37,
		letters = {
			'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ' ', '.', '!', '?', '-', '+', '(',
			')', '%', '$', '#', 'E', '~', ':', '/', '<', '>', '^', '@', ',', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '[', '\\', ']', 'Ĉ', '_', '`',
			'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '{', '|', '}', '~',
			'а', 'б', 'в', 'г', 'д', 'е', 'ё', 'ж', 'з', 'и', 'й', 'к', 'л', 'м', 'н', 'о', 'п',
			'р', 'с', 'т', 'у', 'ф', 'х', 'ц', 'ч', 'ш', 'щ', 'ы', 'ъ', 'ь', 'э', 'ю', 'я', 'А',
			'¡', '¢', '£', '¤', '¥', '¦', '§', '¨', '©', 'ª', '«', '¬', 'Б', '®', '¯', '°', '±', '²', '³', '´', 'µ', '¶', '·', '¸', '¹', 'º', '»',
			'¼', '½', '¾', '¿', 'À', 'Á', 'Â', 'Ã', 'Ä', 'Å', 'Æ', 'Ç', 'È', 'É', 'Ê', 'Ë', 'Ì', 'Í', 'Î', 'Ï', 'Ð', 'Ñ', 'Ò', 'Ó', 'Ô', 'Õ', 'Ö', '×',
			 'Ø', 'Ù', 'Ú', 'Û', 'Ü', 'Ý', 'Þ', 'ß', 'à', 'á', 'â', 'ã', 'ä', 'å', 'æ', 'ç', 'è', 'é', 'ê', 'ë', 'ì', 'í', 'î', 'ï', 'ð', 'ñ', 'ò', 'ó',
			 'ô', 'õ', 'ö', '÷', 'ø', 'ù', 'ú', 'û', 'ü', 'ý', 'þ', 'ÿ', 'Ā', 'ā', 'Ă', 'ă', 'Ą', 'ą', 'Ć', 'ć',
		}
	},
	[0] = {
			extrafunc = function (l) return _FL_SUP(l) end,
			width = 10,
			height = 15,
			startY = 14,
			letters = {
				"0","1","2","3","4","5","6","7","8","9"
			}
	}
}

function FontLib_setLetter(fnt, _x, l, _y)
	FontLib[fnt][l] = {x = _x, y = _y or 0}
end

for i = 0, #FontLib do
	local x, w = 0, FontLib[i].width
	for j = 1, #FontLib[i].letters do
		if i == 4 then
			if (j - 1) % FontLib[i].maxSyms == 0 and j > 1 then
				x = 0
			end
			FontLib_setLetter(i, x, FontLib[i].letters[j], math.floor((j-1) / FontLib[i].maxSyms)*FontLib[i].height +  math.floor((j-1) / FontLib[i].maxSyms))
			x = x + w
		else
			FontLib_setLetter(i, x, FontLib[i].letters[j])
			x = x + w
		end
	end
end
local utf8charPattern = "[%z\1-\127\194-\244][\128-\191]*"
function FontLib_print(x, y, text, clr, fnt)
	fnt = fnt or _FL_DEF
	local w, h, s, f = FontLib[fnt].width, FontLib[fnt].height, FontLib[fnt].startY, FontLib[fnt].extrafunc
	for l in tostring(text):gmatch(utf8charPattern) do
		if f then l = f(l) end
		if not FontLib[fnt][l] then
			l='^'
		end
		_FL_DPI(x, y,_FL_TEX,FontLib[fnt][l].x, s+FontLib[fnt][l].y, w, h, clr)
		x = x + w
	end
end
function FontLib_printScaled(x, y, text, size_x, size_y, clr, fnt)
	fnt = fnt or _FL_DEF
	local w, h, s, f = FontLib[fnt].width, FontLib[fnt].height, FontLib[fnt].startY, FontLib[fnt].extrafunc
	local wS = w * size_x
	local Sx, Sy = wS / 2, h * size_y / 2
	for l in tostring(text):gmatch(utf8charPattern) do
		if f then l = f(l) end
		if FontLib[fnt][l] ~= nil then
			_FL_DIE(x + Sx, y + Sy, _FL_TEX, FontLib[fnt][l].x, s+FontLib[fnt][l].y, w, h, 0, size_x, size_y, clr)
		end
		x = x + wS
	end
end
function FontLib_printRotated(x, y, text, rot, clr, fnt)
	fnt = fnt or _FL_DEF
	local w, h, s, f = FontLib[fnt].width, FontLib[fnt].height, FontLib[fnt].startY, FontLib[fnt].extrafunc
	local sin, cos, len = _FL_SIN(rot), _FL_COS(rot), _FL_LEN(text)
	local wS, hS = w * cos, w * sin
	local Sx, Sy = (len-1) * wS / 2, (len-1) * hS / 2
	for l in tostring(text):gmatch(utf8charPattern) do
		if f then l = f(l) end 
		if FontLib[fnt][l] ~= nil then
			_FL_DIE(x - Sx, y - Sy, _FL_TEX, FontLib[fnt][l].x, s+FontLib[fnt][l].y, w, h, rot, 1, 1, clr)
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
	local Sx, Sy = (len-1) * wS / 2, (len-1) * hS / 2
	x, y = x - Sx, y - Sy
	for l in tostring(text):gmatch(utf8charPattern) do
		if f then l = f(l) end
		if FontLib[fnt][l] ~= nil then
			_FL_DIE(x, y, _FL_TEX, FontLib[fnt][l].x, s+FontLib[fnt][l].y, w, h, rot, size_x, size_y, clr)
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