function readCfg (_path, _table) --loads cfg file to Options table
	
	if System.doesFileExist(_path) then
	
		local cfg = System.openFile(_path, FREAD)
		local cfg_size = System.sizeFile(cfg)
		local k,key,value = true,"",""
		
		for i = 1, cfg_size do
		
			local str = System.readFile(cfg, 1)
			
			if string.byte(str) ~= 13 and string.byte(str)~=10 then
			
				if str == ' ' then 
				
					k = false 
					
					else
					
					if k then
					
						key = key..str
						
						else
						
						value = value..str
						
					end
					
				end
				
				elseif string.byte(str) == 10 then
				
				k = true
				if tonumber(value)~=nil then
					_table[key] = tonumber(value)
				else
					_table[key] = value
				end
				key = ''
				value = ''
				
			end
			
		end
		
		_table[key] = value 
		System.closeFile(cfg)
		
	end
	
end
function updateCfg (_path, table) --updates cfg file with table value
	
	System.deleteFile(_path)
	local cfg = System.openFile(_path, FCREATE)
	
	for k,v in pairs(table) do
	
		System.writeFile(cfg, k.." "..v.."\n", string.len(k.." "..v.."\n"))
		
	end
	
	System.closeFile(cfg)
	
end
