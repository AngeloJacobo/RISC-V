@echo off

set FNAME=%1
set ONAME=test
set STARTADDR=0
set DATAADDR=1000
set TESTDIR=.

set PREFIX=riscv64-unknown-elf-

%PREFIX%as.exe -fpic -march=rv32i -aghlms=%TESTDIR%\%ONAME%.list -o %TESTDIR%\%ONAME%.o %TESTDIR%\%FNAME%
%PREFIX%ld.exe %TESTDIR%\%ONAME%.o -Ttext %STARTADDR% -Tdata %DATAADDR% -melf32lriscv -o %ONAME%.exe
