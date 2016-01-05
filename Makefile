all: kompilator run

kompilator: kompilator.y kompilator.l functions.h functions.cpp
	bison -d kompilator.y
	flex kompilator.l
	g++ -o kompilator functions.h functions.cpp lex.yy.c kompilator.tab.c -std=c++11

run: kompilator interpreter output.mr input
	./kompilator < input
	./interpreter output.mr