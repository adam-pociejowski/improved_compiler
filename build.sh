#!/bin/bash
 bison -d kompilator.y
 flex kompilator.l
 g++ -o kompilator functions.h functions.cpp lex.yy.c kompilator.tab.c -std=c++11
 ./kompilator < input
