function MakeTheme (_path, table) -- saves custom theme to default directory
	local len = string.len
	System.deleteFile(_path)
	local thm = System.openFile(_path, FCREATE)
	
	for k,v in pairs(table) do
		
		local hex = rgb2hex(v)
		System.writeFile(thm, k.." "..hex..'\n', len(k.." "..hex..'\n'))
		
	end
	
	System.closeFile(thm)
end

function AcceptTheme (_path, table) -- Loads theme from *.thm file
	
	local thm = System.openFile(_path, FREAD)
	local thm_size = System.sizeFile(thm)
	local k,key,value = true,"",""
	local _byte = string.byte
	for i = 1, thm_size do
		
		local str = System.readFile(thm, 1)
		local byte = _byte(str)
		
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
			table[key] = Color.new(hex2rgb(value)) 
			key = ''
			value = ''
			
		end 
		
		if byte~=10 and i == thm_size then
			
			k = true
			
			table[key] = Color.new(hex2rgb(value)) 
			
			key = ''
			
			value = ''
			
		end
		
	end
	
	System.closeFile(thm)
	
end