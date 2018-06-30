PCL_Lib = {}
function rgb2hex(rgb)
	local hexadecimal = ""
	for i = 1, #rgb do
		local hex = ''
		while (rgb[i] > 0) do
			local index = math.fmod(rgb[i], 16) + 1
			rgb[i] = math.floor(rgb[i] / 16)
			hex = string.sub('0123456789ABCDEF', index, index) .. hex			
		end
		if(string.len(hex) == 0)then
			hex = '00'
		elseif(string.len(hex) == 1)then
			hex = '0' .. hex
		end
		hexadecimal = hexadecimal .. hex
	end
	return hexadecimal
	end
function hex2rgb(hex)
    hex = hex:gsub("#","")
    return tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
end
function PCL_Lib.open(_path) --Takes table from PCL file
	local lvl = {[1] = ""}
	pcl = System.openFile(_path, FREAD)
	pcl_size = System.sizeFile(pcl)
	local now = 1
	for i = 1, pcl_size do
		local str = System.readFile(pcl,1)
		if string.byte(str) ~= 13 and string.byte(str)~=10 then
			lvl[now] = lvl[now]..str
			elseif string.byte(str) == 10 then
			now = now + 1
			lvl[now] = ""
		end
	end
	lvl.name = lvl[1]
	lvl.width = tonumber(lvl[2])
	lvl.height = tonumber(lvl[3])
	lvl.map = {}
	lvl.pmap = {}
	lvl.path = _path
	local now = 4
	local y = 0
	for i = 1, lvl.height do
		local x = 1
		local tmp = 1
		for j = 1, lvl.width do
			l = tonumber(string.sub(lvl[now], tmp, tmp))
			if l == 1 then
			lvl.map[y+x] = true
			else
			lvl.map[y+x] = false
			end
			lvl.pmap[y+x] = Color.new(hex2rgb(string.sub(lvl[now], tmp+1, tmp+6)))
			tmp = tmp + 7
			x = x + 1
		end
		y = y + lvl.width
		now = now + 1
	end
	for i = 1, #lvl do
		table.remove(lvl, 1)
	end
	System.closeFile(pcl)	
	return lvl
end
function PCL_Lib.create(_path, level, check) --Create new or Rewrite old PCL file
	if check and System.doesFileExist(_path) then
		return false
		elseif check then
		return true
	end
	local str = {tostring(level.name).."\n", tostring(level.width).."\n", tostring(level.height).."\n", map = {}}
	if System.doesFileExist(_path) then
		System.deleteFile(_path)
	end
	pcl = System.openFile(_path, FCREATE)
	for i = 1, #str do
		System.writeFile(pcl, str[i], len(str[i]))
	end
	for i=1, #level.map do
		local getHex = rgb2hex({Color.getR(level.pmap[i]),Color.getG(level.pmap[i]), Color.getB(level.pmap[i])})
		if level.map[i] then
			str.map[i] = "1"..getHex
			else
			str.map[i] = "0"..getHex
		end
	end
	local x = 0
	for i=1, level.height do
		for j=1, level.width do
			x = x + 1
			System.writeFile(pcl, str.map[x], len(str.map[x]))
		end
		System.writeFile(pcl, '\n', 1)
	end
	System.closeFile(pcl)
end