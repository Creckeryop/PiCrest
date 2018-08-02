function MakeTheme(p,b)
System.deleteFile(p)
local t,h=System.openFile(p,FCREATE)
for k,v in pairs(b) do
h=k.." "..rgb2hex(v)..'\n'
System.writeFile(t,h,h:len())
end
System.closeFile(t)
end
function AcceptTheme(p,b)
local t=System.openFile(p,FREAD)
local f=System.readFile(t,System.sizeFile(t))
System.closeFile(t)
local t,k,v,l,s=true,'','',f:len()
for i=1,l do
s=f:sub(i,i)
if s~='\r' and s~='\n' then
if s==' ' then
t=false
else
if t then
k=k..s
else
v=v..s
end
end
elseif s=='\n' or s~='\n' and i==l then
b[k],k,v,t= Color.new(hex2rgb(v)),'','',true
end
end
end