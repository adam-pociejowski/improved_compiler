#ifndef HEADER_FILE
#define HEADER_FILE

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include <map>
#include <vector>
#include <sstream>
#include <fstream>
#include <stack>

using namespace std;

struct Register {
	int index;
	string id;
	bool initialized = false;
	bool isFree = true;
	bool positive = false;
	bool iterator = false;
};

struct Variable {
	unsigned long long int value;
	unsigned long long int stored;
	unsigned long long int length;
	string id;
	bool iterator = false;
};

typedef struct {
	unsigned long long int value;
	unsigned long long int stored;
	unsigned long long int index;
	char* name;
	bool error;
} ParserVar;


void yyerror(string s);
int yylex();
int yyparse();

Variable getVariable(string id);
void setVariable(Variable v);
void deleteVariable(Variable v);
void declareVariable(string id, unsigned long long int length);
void storeVariable(ParserVar p1, ParserVar p2);

unsigned long long int addIterator(string id);
void setIterator(unsigned long long int stored, Register reg);
Register getIterator(unsigned long long int stored);
bool isIterator(string id);
void storeIterator(ParserVar p, Register reg);
void deleteIterator(ParserVar p);

int setValueInRegister(unsigned long long int value, unsigned long long int reg_index);
bool isDeclared(string id, bool isArray);
bool checkIfInitialized(ParserVar p1, ParserVar p2);

void initRegisters();
Register getFreeRegister();
Register getRegisterByIndex(int reg_index);
Register prepareRegister(ParserVar pv);
bool isRegister(unsigned long long int stored);
void resetAllRegisters(bool reset);
void freeRegister(int reg_index, bool reset);
void setRegister(Register reg, bool positive);

unsigned long long int getK();
string intToString(unsigned long long int value);
void addOutput(string s);
void setOutput(int index, string s);
void printVariables();
void print(string text);
void setPrintFlag(int _flag);
void printOutput();

void organizeVariables();
unsigned long long int quickAddition(ParserVar ps1, ParserVar ps2);
unsigned long long int quickSubtraction(ParserVar ps1, ParserVar ps2);
unsigned long long int quickMultiplication(ParserVar ps1, ParserVar ps2);
unsigned long long int quickOperationsPrinter(string operation, int number, ParserVar ps1, ParserVar ps2);

#endif
