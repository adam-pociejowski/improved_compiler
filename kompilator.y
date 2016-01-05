%{
#include "functions.h"
stack<unsigned long long int> st;
stack<unsigned long long int> reg_stack;
stack<ParserVar> for_stack;
%}

%union {
	char *str;
	unsigned long long int num;
	ParserVar var;
}

%token<str> EQUAL
%token<str> ADD
%token<str> MINUS
%token<str> MULTI
%token<str> DIV
%token<str> MODULO
%token<str> LEFT
%token<str> RIGHT
%token<str> LESS
%token<str> LESS_OR_EQUAL
%token<str> MORE
%token<str> MORE_OR_EQUAL
%token<str> DIFFERENT
%token<str> SEMICOLON
%token<str> ASSIGN
%token<str> DECLARE
%token<str> IN
%token<str> GET
%token<str> PUT
%token<str> IF
%token<str> THEN
%token<str> ELSE
%token<str> ENDIF
%token<str> WHILE
%token<str> DO
%token<str> ENDWHILE
%token<str> FOR
%token<str> DOWN
%token<str> FROM
%token<str> TO
%token<str> ENDFOR
%token<str> END
%token<str> ID
%token<num> NUM
%type<var> value
%type<var> factor;
%type<var> iterator;
%type<var> identifier
%type<var> expression
%type<var> condition

%%

program
: DECLARE vdeclarations IN commands END	{ addOutput("HALT"); printOutput(); }
;


vdeclarations
: vdeclarations ID {
	if (isDeclared($2, false)) yyerror("Redeclaration of variable "+string($2));
	else declareVariable($2, -1);
}
| vdeclarations ID LEFT NUM RIGHT {
	if (isDeclared($2, true)) yyerror("Redeclaration of array "+string($2));
	else declareVariable($2, $4);
}
|	{ initRegisters(); }
;


commands
: commands command
|
;


command
: identifier ASSIGN expression SEMICOLON {
	if (!isIterator($1.name)) {
		if (isRegister($3.stored)) {
			if (!$3.error) {
				storeVariable($1, $3);
			} else yyerror("Trying to access uninitialized variable");
		} else yyerror("Result of expression isn't stored in register");
	} else yyerror("Trying change iterator value");
}
| IF condition THEN commands ENDIF	{
	setOutput(st.top(), intToString(getK())); st.pop(); st.pop();
	resetAllRegisters(true);
}
| IF condition THEN commands else commands ENDIF	{
	setOutput(st.top(), intToString(getK())); st.pop(); st.pop();
	resetAllRegisters(true);
}
| WHILE condition DO commands ENDWHILE	{
	resetAllRegisters(false);
	setOutput(st.top(), intToString(getK()+1)); st.pop();
	addOutput("JUMP "+intToString(st.top())); st.pop();
	resetAllRegisters(true);
}
| FOR iterator FROM value TO factor	{
	Register reg_1 = prepareRegister($4);
	storeIterator($2, reg_1);
	st.push(getK());
	reg_1 = prepareRegister($2);  	setRegister(reg_1, true);
	Register reg_2 = prepareRegister($6);  	setRegister(reg_2, true);
	addOutput("INC "+intToString(reg_2.index));
	addOutput("SUB "+intToString(reg_2.index)+" "+intToString(reg_1.index));
	freeRegister(reg_1.index, true);
	for_stack.push($2);	 st.push(getK());
	addOutput("JZERO "+intToString(reg_2.index)+" ");
	freeRegister(reg_2.index, true);
	reg_stack.push(reg_2.index);
}
DO commands ENDFOR	{
	ParserVar p1 = for_stack.top();	for_stack.pop();
	Register reg = prepareRegister(p1);
	addOutput("INC "+intToString(reg.index));
	storeIterator(p1, reg);
	setOutput(st.top(), intToString(getK()+1)); st.pop();
	addOutput("JUMP "+intToString(st.top())); st.pop();
	deleteIterator(p1);
	freeRegister(reg_stack.top(), true); reg_stack.pop();
}
| FOR iterator DOWN FROM value TO factor {
	Register reg_1 = prepareRegister($5);
	storeIterator($2, reg_1);
	st.push(getK());
	reg_1 = prepareRegister($2);
	setRegister(reg_1, true);
	Register reg_2 = prepareRegister($7);
	setRegister(reg_2, true);
	addOutput("INC "+intToString(reg_1.index));
	addOutput("SUB "+intToString(reg_1.index)+" "+intToString(reg_2.index));
	freeRegister(reg_2.index, true);
	for_stack.push($2);	 st.push(getK());
	addOutput("JZERO "+intToString(reg_1.index)+" ");
	freeRegister(reg_1.index, true);
	reg_stack.push(reg_1.index);
}
DO commands ENDFOR	{
	ParserVar p1 = for_stack.top();	for_stack.pop();
	Register reg = prepareRegister(p1);
	unsigned long long int index = getK();
	addOutput("JZERO "+intToString(reg.index)+" ");
	addOutput("DEC "+intToString(reg.index));
	storeIterator(p1, reg);
	setOutput(st.top(), intToString(getK()+1)); st.pop();
	addOutput("JUMP "+intToString(st.top())); st.pop();
	setOutput(index, intToString(getK()));
	deleteIterator(p1);
	freeRegister(reg_stack.top(), true); reg_stack.pop();
}
| GET identifier SEMICOLON	{
	Register reg = getFreeRegister();
	addOutput("READ "+intToString(reg.index));
	Register reg_2 = getFreeRegister();
	setValueInRegister($2.stored - 10, reg_2.index);
	addOutput("STORE "+intToString(reg.index)+" "+intToString(reg_2.index));
	freeRegister(reg_2.index, true);
	freeRegister(reg.index, true);
	Variable v = getVariable($2.name);
	v.value = 0;
	setVariable(v);
}
| PUT value SEMICOLON	{
	Register reg = prepareRegister($2);
	addOutput("WRITE "+intToString(reg.index));
	freeRegister(reg.index, true);
}
;


else
:	ELSE	{
	setOutput(st.top(), intToString(getK()+1));
	st.pop(); st.push(getK());
	addOutput("JUMP ");
}
;


expression
: value	{
	Register reg = prepareRegister($1);
	$$.index = -1;
	$$.stored = reg.index;
	$$.value = $1.value;
	if ($1.value == -1) $$.error = true;
}
|	value ADD value {
	int quickResult = quickAddition($1, $3);
	if (quickResult != -1) $$.stored = quickResult;
	else {
		Register reg_1 = prepareRegister($1);
		Register reg_2 = prepareRegister($3);
		addOutput("ADD "+intToString(reg_1.index)+" "+intToString(reg_2.index));
		freeRegister(reg_2.index, true);
		$$.stored = reg_1.index;
	}
	$$.index = -1;
	$$.error = checkIfInitialized($1, $3);
}
| value MINUS value	{
	int quickResult = quickSubtraction($1, $3);
	if (quickResult != -1) $$.stored = quickResult;
	else {
		Register reg_1 = prepareRegister($1);
		Register reg_2 = prepareRegister($3);
		addOutput("SUB "+intToString(reg_1.index)+" "+intToString(reg_2.index));
		freeRegister(reg_2.index, true);
		$$.stored = reg_1.index;
	}
	$$.index = -1;
	$$.error = checkIfInitialized($1, $3);
}
| value MULTI value	{
	unsigned long long int quickResult = quickMultiplication($1, $3);
	if (quickResult != -1) $$.stored = quickResult;
	else {
		Register reg_1 = prepareRegister($1);
		Register reg_2 = prepareRegister($3);
		Register reg_3 = getFreeRegister();
		addOutput("JODD "+intToString(reg_2.index)+" "+intToString(getK() + 5));
		addOutput("SHL "+intToString(reg_1.index));
		addOutput("SHR "+intToString(reg_2.index));
		addOutput("JZERO "+intToString(reg_2.index)+" "+intToString(getK() + 5));
		addOutput("JUMP "+intToString(getK() - 4));
		addOutput("ADD "+intToString(reg_3.index)+" "+intToString(reg_1.index));
		addOutput("DEC "+intToString(reg_2.index));
		addOutput("JUMP "+intToString(getK() - 6));
		freeRegister(reg_2.index, true);
		freeRegister(reg_1.index, true);
		$$.index = -1;
		$$.stored = reg_3.index;
		$$.error = checkIfInitialized($1, $3);
	}
}
| value DIV value	{
	if (false) {}
	else {
		Register reg1 = prepareRegister($1);
		Register reg2 = prepareRegister($3);
		Register reg3 = getFreeRegister();
		addOutput("INC "+intToString(reg1.index));
		addOutput("SUB "+intToString(reg1.index)+" "+intToString(reg2.index));
		addOutput("JZERO "+intToString(reg1.index)+" "+intToString(getK() + 3));
		addOutput("INC "+intToString(reg3.index));
		addOutput("JUMP "+intToString(getK() - 3));
		freeRegister(reg1.index, true);
		freeRegister(reg1.index, true);
		$$.stored = reg3.index;
	}
	$$.index = -1;
	$$.error = checkIfInitialized($1, $3);
}
| value MODULO value	{
	Register reg_1 = prepareRegister($1);
	Register reg_2 = prepareRegister($3);
	Register reg_3 = getFreeRegister();
	Register reg_4 = getFreeRegister();
	addOutput("JZERO "+intToString(reg_2.index)+" "+intToString(getK() + 14));
	addOutput("RESET "+intToString(reg_3.index));
	addOutput("RESET "+intToString(reg_4.index));
	addOutput("ADD "+intToString(reg_4.index)+" "+intToString(reg_2.index));
	addOutput("SUB "+intToString(reg_4.index)+" "+intToString(reg_1.index));
	addOutput("JZERO "+intToString(reg_4.index)+" "+intToString(getK() + 2));
	addOutput("JUMP "+intToString(getK() + 11));
	addOutput("ADD "+intToString(reg_3.index)+" "+intToString(reg_2.index));
	addOutput("ADD "+intToString(reg_4.index)+" "+intToString(reg_3.index));
	addOutput("SHL "+intToString(reg_4.index));
	addOutput("SUB "+intToString(reg_4.index)+" "+intToString(reg_1.index));
	addOutput("JZERO "+intToString(reg_4.index)+" "+intToString(getK() + 2));
	addOutput("JUMP "+intToString(getK() + 3));
	addOutput("SHL "+intToString(reg_3.index));
	addOutput("JUMP "+intToString(getK() - 6));
	addOutput("SUB "+intToString(reg_1.index)+" "+intToString(reg_3.index));
	addOutput("JUMP "+intToString(getK() - 15));
	freeRegister(reg_2.index, true);
	freeRegister(reg_3.index, true);
	freeRegister(reg_4.index, true);
	$$.index = -1;
	$$.stored = reg_1.index;
	$$.error = checkIfInitialized($1, $3);
}
;


condition
: value EQUAL value	{
	st.push(getK());
	Register reg_1 = prepareRegister($1);
	Register reg_2 = prepareRegister($3);
	Register reg_3 = getFreeRegister();
	addOutput("COPY "+intToString(reg_3.index)+" "+intToString(reg_2.index));
	addOutput("SUB "+intToString(reg_2.index)+" "+intToString(reg_1.index));
	addOutput("SUB "+intToString(reg_1.index)+" "+intToString(reg_3.index));
	addOutput("ADD "+intToString(reg_1.index)+" "+intToString(reg_2.index));
	freeRegister(reg_2.index, true);
	freeRegister(reg_3.index, true);
	addOutput("JZERO "+intToString(reg_1.index)+" "+intToString(getK() + 2));
	setRegister(reg_1, true);
	st.push(getK());
	addOutput("JUMP ");
	$$.error = checkIfInitialized($1, $3);
}
| value DIFFERENT value	{
	st.push(getK());
	Register reg_1 = prepareRegister($1);
	Register reg_2 = prepareRegister($3);
	Register reg_3 = getFreeRegister();
	addOutput("COPY "+intToString(reg_3.index)+" "+intToString(reg_2.index));
	addOutput("SUB "+intToString(reg_2.index)+" "+intToString(reg_1.index));
	addOutput("SUB "+intToString(reg_1.index)+" "+intToString(reg_3.index));
	addOutput("ADD "+intToString(reg_1.index)+" "+intToString(reg_2.index));
	freeRegister(reg_2.index, true);
	freeRegister(reg_3.index, true);
	setRegister(reg_1, true);
	st.push(getK());
	addOutput("JZERO "+intToString(reg_1.index)+" ");
	freeRegister(reg_1.index, true);
	$$.error = checkIfInitialized($1, $3);
}
| value LESS value	{
	st.push(getK());
	Register reg_1 = prepareRegister($1);
	Register reg_2 = prepareRegister($3);
	addOutput("SUB "+intToString(reg_2.index)+" "+intToString(reg_1.index));
	freeRegister(reg_1.index, true);
	reg_2.id = "";
	setRegister(reg_2, true);
	st.push(getK());
	addOutput("JZERO "+intToString(reg_2.index)+" ");
	freeRegister(reg_2.index, true);
	$$.error = checkIfInitialized($1, $3);
}
| value MORE value	{
	st.push(getK());
	Register reg_1 = prepareRegister($1);
	Register reg_2 = prepareRegister($3);
	addOutput("SUB "+intToString(reg_1.index)+" "+intToString(reg_2.index));
	freeRegister(reg_2.index, true);
	reg_1.id = "";
	setRegister(reg_1, true);
	st.push(getK());
	addOutput("JZERO "+intToString(reg_1.index)+" ");
	freeRegister(reg_1.index, true);
	$$.error = checkIfInitialized($1, $3);
}
| value LESS_OR_EQUAL value	{
	st.push(getK());
	Register reg_1 = prepareRegister($1);
	Register reg_2 = prepareRegister($3);
	addOutput("INC "+intToString(reg_2.index));
	addOutput("SUB "+intToString(reg_2.index)+" "+intToString(reg_1.index));
	freeRegister(reg_1.index, true);
	reg_2.id = ""; setRegister(reg_2, true);
	st.push(getK());
	addOutput("JZERO "+intToString(reg_2.index)+" ");
	freeRegister(reg_2.index, true);
	$$.error = checkIfInitialized($1, $3);
}
| value MORE_OR_EQUAL value	{
	st.push(getK());
	Register reg_1 = prepareRegister($1);
	Register reg_2 = prepareRegister($3);
	addOutput("INC "+intToString(reg_1.index));
	addOutput("SUB "+intToString(reg_1.index)+" "+intToString(reg_2.index));
	freeRegister(reg_2.index, true);
	reg_1.id = ""; setRegister(reg_1, true);
	st.push(getK());
	addOutput("JZERO "+intToString(reg_1.index)+" ");
	freeRegister(reg_1.index, true);
	$$.error = checkIfInitialized($1, $3);
}
;


iterator
: ID	{
	$$.stored = addIterator(string($1));
	$$.name = $1;
	$$.value = 0;
	$$.index = -1;
}
;


value
: identifier	{ $$ = $1; }
| NUM	{/*
	Register reg = getFreeRegister();
	setValueInRegister($1, reg.index);
	$$.stored = reg.index;
	$$.value = $1;
	$$.name = strdup("");
	$$.index = -1;*/
	$$.stored = -1;
	$$.value = $1;
	$$.name = strdup("");
	$$.index = -1;
}
;


factor
: identifier	{ $$ = $1; }
| NUM	{
	$$.value = $1;
	$$.name = strdup("");
	$$.stored = storeTempVariable($1);
	$$.index = -1;
}
;


identifier
: ID	{
	if (isDeclared($1, false)) {
		Variable v = getVariable($1);
		if (v.iterator) $$ = for_stack.top(); //We are taking most nested iterator of this ID
		else {
			$$.stored = v.stored;
			$$.value = v.value;
			$$.name = $1;
			$$.index = -1;
		}
	}
	else yyerror("Variable "+string($1)+" not declared");
}
| ID LEFT NUM RIGHT	{
	if (isDeclared($1, true)) {
		Variable v = getVariable($1);
		if ($3 >= 0 && $3 < v.length) {
			$$.stored = v.stored + $3;
			$$.value = 0;
			$$.name = $1;
			$$.index = -1;
		}	else yyerror("In array "+string($1)+" index out of bounds: "+intToString($3));
	} else yyerror("Array "+string($1)+" not declared");
}
| ID LEFT ID RIGHT	{
	if (isDeclared($1, true)) {
		if (isDeclared($3, false)) {
			Variable v = getVariable($1);
			Variable v_2 = getVariable($3);
			$$.stored = v.stored;
			$$.index = v_2.stored;
			$$.value = 0;
			$$.name = $1;
		} else yyerror("Variable "+string($3)+" not declared");
	} else yyerror("Array "+string($1)+" not declared");
}
;

%%


/* Main function */
int main(int argc, char* argv[]) {
	int flag = 1;
	if (argc > 1) flag = atoi(argv[1]);
	setPrintFlag(flag);

	return yyparse();
}
