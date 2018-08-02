PCL_Lib = {}
function rgb2hex(c)
c={Color.getR(c),Color.getG(c),Color.getB(c)}
local a,h,n,l = ''
for i=1,#c do
h=''
while c[i]>0 do
n=math.fmod(c[i],16)+1
c[i]=math.floor(c[i]/16)
h=string.sub('0123456789ABCDEF',n,n)..h
end
l=h:len()
if l==0 then
h='00'
elseif l==1 then
h='0'..h
end
a=a..h
end
return a
end
function hex2rgb(h)
h=h:gsub('#','')
return tonumber("0x"..h:sub(1,2)),tonumber("0x"..h:sub(3,4)),tonumber("0x"..h:sub(5,6))
end
function PCL_Lib.open(_path) --Takes table from PCL file
	local lvl = {[1] = ""}
	local pcl = System.openFile(_path, FREAD)
	local pcl_size = System.sizeFile(pcl)
	local file = System.readFile(pcl,pcl_size)
	System.closeFile(pcl)
	local now,bytes,str = 1,1
	for i = 1, pcl_size do
		str = file:sub(i,i)
		if str ~= '\r' and str ~= '\n' then
			lvl[now] = lvl[now]..str
			elseif str == '\n' then
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
	local t,tmp = 1
	for i = 1, lvl.height do
		tmp = 1
		for j = 1, lvl.width do
			l = tonumber(string.sub(lvl[now], tmp, tmp))
			if l == 1 then
				lvl.map[t] = true
			else
				lvl.map[t] = false
			end
			lvl.pmap[t] = Color.new(hex2rgb(string.sub(lvl[now], tmp+1, tmp+6)))
			tmp = tmp + 7
			t = t + 1
		end
		now = now + 1
	end
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
		System.writeFile(pcl, str[i], string.len(str[i]))
	end
	for i=1, level.width*level.height do
		local getHex = rgb2hex(level.pmap[i])
		if level.map[i] then str.map[i] = '1' else str.map[i] = '0' end
		str.map[i] = str.map[i]..getHex
	end
	local x = 0
	for i=1, level.height do
		for j=1, level.width do
			x = x + 1
			System.writeFile(pcl, str.map[x], string.len(str.map[x]))
		end
		System.writeFile(pcl, '\n', 1)
	end
	System.closeFile(pcl)
end
function PCL_Lib.getToSize(_path)
	local lvl, name, size = {[1] = ""}
	local pcl = System.openFile(_path, FREAD)
	local pcl_size = System.sizeFile(pcl)
	local file = System.readFile(pcl,pcl_size)
	System.closeFile(pcl)
	local now,bytes,str = 1,1
	for i = 1, pcl_size do
		str = file:sub(i,i)
		if str ~= '\r' and str ~= '\n' then
			lvl[now] = lvl[now]..str
			elseif str == '\n' then
			now = now + 1
			lvl[now] = ""
		end
		if now==4 then break end
	end
	name = lvl[1]
	size = lvl[2].."x"..lvl[3]
	return name, size
end