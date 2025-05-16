@echo off
echo ***CLEANING SRC..
del *.tpu
del *.tpp
del *.exe
echo ***CLEANING UTIL..
cd util
del *.exe
cd ..
echo ***CLEANING CLIENT..
cd client
del *.tpu
del *.exe
cd ..
cd ..
echo ***CLEANING BIN..
cd bin
del *.err
del *.log
echo ***CLEANING LOG..
cd log
del *.err
del *.log
cd ..
cd ..
echo ***DONE..
