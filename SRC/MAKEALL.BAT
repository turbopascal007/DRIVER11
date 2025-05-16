@echo off
echo Making driver...
tpc -m driver
copy driver.exe ..\bin
bpc -cp -m -u\prg\bp\units driv386
copy driv386.exe ..\bin\driv386.exe
echo Making loader...
cd util
tpc -u.. -m load
copy load.exe ..\..\bin
echo Making builder...
tpc -u.. -m build
copy build.exe ..\..\bin
echo Making client...
cd ..\client
copy client.exe ..\..\bin
tpc -u.. -m client
cd ..\..\bin
echo Done...
