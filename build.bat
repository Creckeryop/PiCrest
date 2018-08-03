@RD /S /Q "make\build\data"
del /Q "make\build\index.lua"
del /Q "make\PiCrest.vpk"
del /Q "PiCrest.vpk"
if not exist "make\build\data" mkdir make\build\data
xcopy /s /i data make\build\data
copy /y index.lua /b make\build\
cd make\
call "build.bat"
cd ..
copy /Y make\PiCrest.vpk
@RD /S /Q "make\build\data" 
del /Q "make\build\index.lua" 
del /Q "make\PiCrest.vpk"
