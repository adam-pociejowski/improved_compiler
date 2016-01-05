#!/bin/bash
 bison -d kompilator.y
 flex kompilator.l
 g++ -o kompilator functions.h functions.cpp lex.yy.c kompilator.tab.c -std=c++11
 for V in 1 2 3 4 5 6 7 8 9 10 11 12 13
 do
   ./kompilator 0 < myTests/input_$V
   ./myTests/interpreter output.mr
   echo "" 
 done
 cat < myTests/results 
