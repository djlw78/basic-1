set PATH=%PATH%;C:\MinGW\bin
gcc -std=gnu99 -Wall *.c -o basic.exe
pause
copy basic.exe "%HOMEPATH%\Dropbox\Public"
pause
