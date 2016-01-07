#!/bin/bash
 path=$(pwd)
 bison -d kompilator.y
 flex kompilator.l
 g++ -o kompilator functions.h functions.cpp lex.yy.c kompilator.tab.c -std=c++11
 rm $path/test_input
 for V in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19
 do
   echo "input_$V TEST" >> $path/test_input
   ./kompilator 0 < myTests/input_$V
   ./myTests/interpreter output.mr >> $path/test_input
 done
 cat < myTests/results >> $path/test_input
 echo "<" >> $path/test_input
 java Tester
