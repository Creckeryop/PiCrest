vita-mksfoex -s TITLE_ID=PICRESTGM "PiCrest" param.sfo
copy /Y param.sfo /B build\sce_sys\param.sfo
7z a -tzip "PiCrest.vpk" -r .\build\* .\build\eboot.bin 