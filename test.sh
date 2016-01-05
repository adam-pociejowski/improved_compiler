#!/bin/bash
 bison -d kompilator.y
 flex kompilator.l
 g++ -o kompilator functions.h functions.cpp lex.yy.c kompilator.tab.c -std=c++11
 rm ~/actual/kompilator/improved/test_input
 for V in 1 2 3 4 5 6 7 8 9 10 11 12 13
 do
   echo "input_$V TEST" >> ~/actual/kompilator/improved/test_input
   ./kompilator 0 < myTests/input_$V
   ./myTests/interpreter output.mr >> ~/actual/kompilator/improved/test_input
 done
 cat < myTests/results >> ~/actual/kompilator/improved/test_input
 echo "<" >> ~/actual/kompilator/improved/test_input
 java Tester
