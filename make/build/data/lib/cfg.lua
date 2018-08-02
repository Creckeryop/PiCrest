function readCfg(p,b)
if System.doesFileExist(p) then
local c=System.openFile(p,FREAD)
local f=System.readFile(c,System.sizeFile(c))
System.closeFile(c)
local t,k,v,s=true,'',''
for i=1,f:len() do
s=f:sub(i,i)
if s~='\r' and s~='\n' then
if s==' ' and t then
t=false
else
if t then
k=k..s
else
v=v..s
end
end
elseif s=='\n' then
b[k]=tonumber(v) or v
k,v,t='','',true
end
end
b[k]=v
end
end
function updateCfg(p,t)
System.deleteFile(p)
local c,a=System.openFile(p,FCREATE)
for k,v in pairs(t) do
a=k.." "..v.."\n"
System.writeFile(c,a,a:len())
end
System.closeFile(c)
end