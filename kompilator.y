%{
#include "functions.h"
stack<unsigned long long int> st;
stack<int> reg_to_reset;
stack<ParserVar> for_stack;
ParserVar actual;
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
%type<var> iterator
%type<var> identifier
%type<var> expression
%type<var> condition

%%

program
: DECLARE vdeclarations { organizeVariables(); }
 IN commands END	{ addOutput("HALT"); printOutput(); }
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
: identifier ASSIGN {
	actual = $1;
}
expression SEMICOLON {
	if (!isIterator(actual.name)) {
		if (isRegister($4.stored) || $4.value != -1) {
			Variable v = getVariable(string(actual.name));
			if ($4.value == -1) storeVariable(actual, $4);
			else if (isRegister(actual.stored)) {			//initialize superVar with num
				addOutput("RESET "+intToString(actual.stored));
				setValueInRegister($4.value, actual.stored);
			}
			else {
				ParserVar p = $4;
				p.index = -1;
				Register reg = prepareRegister($4);
				p.stored = reg.index;
				storeVariable(actual, p);
			}
			v.isInitialized = true;
			setVariable(v);
		} else yyerror("Result of expression isn't stored in register");
	} else yyerror("Trying change iterator value");
}
| IF condition THEN commands ENDIF	{
	setOutput(st.top(), intToString(getK())); st.pop(); st.pop();
	freeRegister(reg_to_reset.top(), true);
	reg_to_reset.pop();
}
| IF condition THEN commands else commands ENDIF	{
	setOutput(st.top(), intToString(getK())); st.pop(); st.pop();
	freeRegister(reg_to_reset.top(), true);
	reg_to_reset.pop();
}
| WHILE condition DO commands ENDWHILE	{
	setOutput(st.top(), intToString(getK() + 1)); st.pop();
	addOutput("JUMP "+intToString(st.top())); st.pop();
	freeRegister(reg_to_reset.top(), true);
	reg_to_reset.pop();
}
| FOR iterator FROM value TO value	{
	Register reg1 = prepareRegister($4), reg2;
	if (isRegister($6.stored)) {  			 //FOR i FROM value TO superVar
		reg2 = getFreeRegister(true);
		addOutput("COPY "+intToString(reg2.index)+" "+intToString($6.stored));
	}
	else reg2 = prepareRegister($6);
	setRegister(reg2, true);
	addOutput("INC "+intToString(reg2.index));
	addOutput("SUB "+intToString(reg2.index)+" "+intToString(reg1.index));
	storeIterator($2, reg1);
	freeRegister(reg1.index, true);
	ParserVar p;
	p.index = -1;
	p.stored = addLoopCounter(reg2);
	p.name = strdup("");
	freeRegister(reg2.index, true);
	st.push(getK());
	reg1 = prepareRegister(p);
	for_stack.push($2);
	for_stack.push(p);
	st.push(getK());
	addOutput("JZERO "+intToString(reg1.index)+" ");
	freeRegister(reg1.index, true);
	reg_to_reset.push(reg1.index);
}
DO commands ENDFOR	{
	ParserVar counter = for_stack.top();
	for_stack.pop();
	ParserVar iterator = for_stack.top();
	for_stack.pop();
	saveLoopCounter(counter);
	Register reg = prepareRegister(iterator);				//Increasing value of iterator
	addOutput("INC "+intToString(reg.index));
	storeIterator(iterator, reg);
	setOutput(st.top(), intToString(getK() + 1));
	st.pop();
	addOutput("JUMP "+intToString(st.top()));
	st.pop();
	freeRegister(reg_to_reset.top(), true);
	reg_to_reset.pop();
	deleteIterator(iterator, counter);
}
| FOR iterator DOWN FROM value TO value {
	Register reg1, reg2;
	reg1 = prepareRegister($7);
	if (isRegister($5.stored)) {
		reg2 = getFreeRegister(false);
		addOutput("COPY "+intToString(reg2.index)+" "+intToString($5.stored));
	}
	else reg2 = prepareRegister($5);
	Register reg3 = getFreeRegister(false);
	setRegister(reg1, true);
	setRegister(reg2, true);
	setRegister(reg3, true);
	addOutput("COPY "+intToString(reg3.index)+" "+intToString(reg2.index));
	storeIterator($2, reg3);
	addOutput("INC "+intToString(reg2.index));
	addOutput("SUB "+intToString(reg2.index)+" "+intToString(reg1.index));
	freeRegister(reg1.index, true);
	ParserVar p;
	p.index = -1;
	p.stored = addLoopCounter(reg2);
	p.name = strdup("");
	freeRegister(reg2.index, true);
	st.push(getK());
	reg1 = prepareRegister(p);
	for_stack.push($2);
	for_stack.push(p);
	st.push(getK());
	addOutput("JZERO "+intToString(reg1.index)+" ");
	freeRegister(reg1.index, true);
	reg_to_reset.push(reg1.index);
}
DO commands ENDFOR	{
	ParserVar counter = for_stack.top();
	for_stack.pop();
	ParserVar iterator = for_stack.top();
	for_stack.pop();
	saveLoopCounter(counter);
	Register reg = prepareRegister(iterator);
	addOutput("DEC "+intToString(reg.index));
	storeIterator(iterator, reg);
	setOutput(st.top(), intToString(getK() + 1));
	st.pop();
	addOutput("JUMP "+intToString(st.top()));
	st.pop();
	freeRegister(reg_to_reset.top(), true);
	reg_to_reset.pop();
	deleteIterator(iterator, counter);
}
| GET identifier SEMICOLON	{
	ParserVar p;
	Variable v = getVariable(string($2.name));
	if (isRegister(v.stored)) {
		addOutput("READ "+intToString(v.stored));
	}
	else {
		Register reg = getFreeRegister(false);
		addOutput("READ "+intToString(reg.index));
		p.stored = reg.index;
		p.index = -1;
		storeVariable($2, p);
	}
	v.isInitialized = true;
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
	freeRegister(reg_to_reset.top(), true);
}
;


expression
: value	{
	if ($1.stored == -1) $$ = $1;   //num
	else {
		Register reg = prepareRegister($1);
		$$.index = -1;
		$$.stored = reg.index;
		$$.value = -1;
	}
}
|	value ADD value {
	resetAllRegisters(true);
	if (isRegister($1.stored) || isRegister($3.stored)) {               //superVar optimalization
		int optimalization = 0;  									 //0 - nothing, 1 - a := a + somthing, 2 - a := something + a
		ParserVar leftSite = actual;
		if (isRegister(leftSite.stored)) {
			if (leftSite.stored == $1.stored) optimalization = 1;  			 	  //a := a + something
			else if (leftSite.stored == $3.stored) optimalization = 2; 	  	//a := something + a
			else optimalization = 3;																			  //a := b + something
		}

		if (isRegister($1.stored) && isRegister($3.stored)) {   					//superVar + superVar
			Register reg = getFreeRegister(true);
			addOutput("COPY "+intToString(reg.index)+" "+intToString($3.stored));
			Register reg2 = prepareRegister($1);
			addOutput("ADD "+intToString(reg.index)+" "+intToString(reg2.index));
			$$.stored = reg.index;
			freeRegister(reg2.index, true);
		}
		else if (isRegister($1.stored)) {       		//superVar + notSuperVar
			if ($3.stored == -1 && $3.value < 8 && optimalization != 0) {   //$3 = NUM
				if (optimalization == 1) {							//a := a + 1
					for (int i = 0; i < $3.value; i++) addOutput("INC "+intToString($1.stored));
					$$.stored = leftSite.stored;
				}
				else if (optimalization == 3) { 				//a := b + 1;
					addOutput("COPY "+intToString(leftSite.stored)+" "+intToString($1.stored));
					for (int i = 0; i < $3.value; i++) addOutput("INC "+intToString(leftSite.stored));
					$$.stored = leftSite.stored;
				}
			}
			else if (optimalization != 0) {
				if (optimalization == 1) {    					//a := a + something
					Register reg = prepareRegister($3);
					addOutput("ADD "+intToString(leftSite.stored)+" "+intToString(reg.index));
					freeRegister(reg.index, true);
					$$.stored = leftSite.stored;
				}
				else if (optimalization == 3) {					//a := b + something
					addOutput("COPY "+intToString(leftSite.stored)+" "+intToString($1.stored));
					Register reg = prepareRegister($3);
					addOutput("ADD "+intToString(leftSite.stored)+" "+intToString(reg.index));
					freeRegister(reg.index, true);
					$$.stored = leftSite.stored;
				}
			}
			else if (optimalization == 0) { 					//a := b + 1  //a is stored in memory
				Register reg = prepareRegister($3);
				addOutput("ADD "+intToString(reg.index)+" "+intToString($1.stored));
				$$.stored = reg.index;
			}	else yyerror("$1 superVar problem in addition");
		}
		else if (isRegister($3.stored)) {  					//notSuperVar + superVar
			if ($1.stored == -1 && $1.value < 8 && optimalization != 0) {   //$1 = NUM
				if (optimalization == 2) {							//a := 1 + a
					for (int i = 0; i < $1.value; i++) addOutput("INC "+intToString(leftSite.stored));
					$$.stored = leftSite.stored;
				}
				else if (optimalization == 3) { 				//a := 1 + b;
					addOutput("COPY "+intToString(leftSite.stored)+" "+intToString($3.stored));
					for (int i = 0; i < $1.value; i++) addOutput("INC "+intToString(leftSite.stored));
					$$.stored = leftSite.stored;
				}
			}
			else if (optimalization != 0) {
				if (optimalization == 2) {    					//a := something + a
					Register reg = prepareRegister($1);
					addOutput("ADD "+intToString($3.stored)+" "+intToString(reg.index));
					freeRegister(reg.index, true);
					$$.stored = leftSite.stored;
				}
				else if (optimalization == 3) {					//a := something + b
					addOutput("COPY "+intToString(leftSite.stored)+" "+intToString($3.stored));
					Register reg = prepareRegister($1);
					addOutput("ADD "+intToString(leftSite.stored)+" "+intToString(reg.index));
					freeRegister(reg.index, true);
					$$.stored = leftSite.stored;
				}
			}
			else if (optimalization == 0) { 					//a := something + b  //a is stored in memory
				Register reg = prepareRegister($1);
				addOutput("ADD "+intToString(reg.index)+" "+intToString($3.stored));
				$$.stored = reg.index;
			}	else yyerror("$3 superVar problem in addition");
		}	else yyerror("superVar problem in addition");
	}
	else {																			   //Other a := 1 + 1 etc..
		int quickResult = quickAddition($1, $3);
		if (quickResult != -1) $$.stored = quickResult;
		else {
			Register reg_1 = prepareRegister($1);
			Register reg_2 = prepareRegister($3);
			addOutput("ADD "+intToString(reg_1.index)+" "+intToString(reg_2.index));
			freeRegister(reg_2.index, true);
			$$.stored = reg_1.index;
		}
	}
	$$.index = -1;
	$$.value = -1;
}
| value MINUS value	{
	resetAllRegisters(true);
	if (isRegister($1.stored) || isRegister($3.stored)) {  												//superVar optimalization
		int optimalization = 0;  									 //0 - nothing, 1 - a := a + somthing, 2 - a := something - a
		ParserVar leftSite = actual;
		if (isRegister(leftSite.stored)) {
			if (leftSite.stored == $1.stored) optimalization = 1;  			 	  //a := a - something
			else if (leftSite.stored == $3.stored) optimalization = 2; 	  	//a := something - a
			else optimalization = 3;																			  //a := b - something
		}

		if ($1.stored == $3.stored && optimalization == 1) {							//a := a - a
			addOutput("RESET "+intToString($1.stored));
			$$.stored = $1.stored;
		}
		else if ($1.stored == $3.stored && optimalization == 3) {					//b := a - a
			addOutput("RESET "+intToString(leftSite.stored));
			$$.stored = leftSite.stored;
		}
		else if (isRegister($1.stored)) {																								//superVar - something
			if ($3.stored == -1 && $3.value < 8 && optimalization != 0) {
				if (optimalization == 1) {							//a := a - 1
					for (int i = 0; i < $3.value; i++) addOutput("DEC "+intToString($1.stored));
					$$.stored = leftSite.stored;
				}
				else if (optimalization == 3) { 				//a := b - 1;
					addOutput("COPY "+intToString(leftSite.stored)+" "+intToString($1.stored));
					for (int i = 0; i < $3.value; i++) addOutput("DEC "+intToString(leftSite.stored));
					$$.stored = leftSite.stored;
				}
			}
			else if (optimalization != 0) {
				if (optimalization == 1) {    					//a := a - something
					Register reg = prepareRegister($3);
					addOutput("SUB "+intToString(leftSite.stored)+" "+intToString(reg.index));
					freeRegister(reg.index, true);
					$$.stored = leftSite.stored;
				}
				else if (optimalization == 3) {					//a := b - something
					addOutput("COPY "+intToString(leftSite.stored)+" "+intToString($1.stored));
					Register reg = prepareRegister($3);
					addOutput("SUB "+intToString(leftSite.stored)+" "+intToString(reg.index));
					freeRegister(reg.index, true);
					$$.stored = leftSite.stored;
				}
			}
			else if (optimalization == 0) {						//a := b - something //a in memory
				Register reg = prepareRegister($3);
				Register reg2 = getFreeRegister(false);
				addOutput("COPY "+intToString(reg2.index)+" "+intToString($1.stored));
				addOutput("SUB "+intToString(reg2.index)+" "+intToString(reg.index));
				freeRegister(reg.index, true);
				$$.stored = reg2.index;
			}	else yyerror("$1 superVar problem in subtraction");
		}
		else {																		//a := something - a;
			Register reg = prepareRegister($1);
			Register reg2 = prepareRegister($3);
			addOutput("SUB "+intToString(reg.index)+" "+intToString(reg2.index));
			$$.stored = reg.index;
		}
	}
	else {
		int quickResult = quickSubtraction($1, $3);
		if (quickResult != -1) $$.stored = quickResult;
		else {
			Register reg1 = prepareRegister($1);
			Register reg2 = prepareRegister($3);
			addOutput("SUB "+intToString(reg1.index)+" "+intToString(reg2.index));
			freeRegister(reg2.index, true);
			$$.stored = reg1.index;
		}
	}
	$$.index = -1;
	$$.value = -1;
}
| value MULTI value	{
	resetAllRegisters(true);
	int optimalization = 0;
	if (isRegister($1.stored) || isRegister($3.stored)) {
		ParserVar leftSite = actual;
		if (isRegister(leftSite.stored)) {
			if (leftSite.stored == $1.stored) optimalization = 1;
			else if (leftSite.stored == $3.stored) optimalization = 2;
		}
	}

	unsigned long long int quickResult = quickMultiplication($1, $3, optimalization);
	if (quickResult != -1) $$.stored = quickResult;
	else {
		Register reg1, reg2, reg3 = getFreeRegister(true);
		if (isRegister($1.stored)) {    // if $1 is superVar we need to make copy od that value or we will lost it
			Register reg = prepareRegister($1);
			reg1 = getFreeRegister(false);
			addOutput("COPY "+intToString(reg1.index)+" "+intToString(reg.index));
		}
		else reg1 = prepareRegister($1);

		if (isRegister($3.stored)) {	  // if $3 is superVar we need to make copy od that value or we will lost it
			Register reg = prepareRegister($3);
			reg2 = getFreeRegister(false);
			addOutput("COPY "+intToString(reg2.index)+" "+intToString(reg.index));
		}
		else reg2 = prepareRegister($3);

		addOutput("JODD "+intToString(reg2.index)+" "+intToString(getK() + 5));
		addOutput("SHL "+intToString(reg1.index));
		addOutput("SHR "+intToString(reg2.index));
		addOutput("JZERO "+intToString(reg2.index)+" "+intToString(getK() + 5));
		addOutput("JUMP "+intToString(getK() - 4));
		addOutput("ADD "+intToString(reg3.index)+" "+intToString(reg1.index));
		addOutput("DEC "+intToString(reg2.index));
		addOutput("JUMP "+intToString(getK() - 6));
		freeRegister(reg2.index, true);
		freeRegister(reg1.index, true);
		$$.stored = reg3.index;
	}
	$$.index = -1;
	$$.value = -1;
}
| value DIV value	{
	resetAllRegisters(true);
	int optimalization = 0;
	if (isRegister($1.stored) || isRegister($3.stored)) {
		ParserVar leftSite = actual;
		if (isRegister(leftSite.stored) && leftSite.stored == $1.stored) optimalization = 1;
	}
	unsigned long long int quickResult = quickDivision($1, $3, optimalization);
	if (quickResult != -1) $$.stored = quickResult;
	else {
		Register reg1, reg2, reg3 = getFreeRegister(false), reg4 = getFreeRegister(false), reg5 = getFreeRegister(true);
		if (isRegister($1.stored)) {    // if $1 is superVar we need to make copy od that value or we will lost it
			Register reg = prepareRegister($1);
			reg1 = getFreeRegister(false);
			addOutput("COPY "+intToString(reg1.index)+" "+intToString(reg.index));
		}
		else reg1 = prepareRegister($1);

		if (isRegister($3.stored)) {	  // if $3 is superVar we need to make copy od that value or we will lost it
			Register reg = prepareRegister($3);
			reg2 = getFreeRegister(false);
			addOutput("COPY "+intToString(reg2.index)+" "+intToString(reg.index));
		}
		else reg2 = prepareRegister($3);

		addOutput("JZERO "+intToString(reg1.index)+" "+intToString(getK() + 21));
		addOutput("JZERO "+intToString(reg2.index)+" "+intToString(getK() + 20));
		addOutput("COPY "+intToString(reg3.index)+" "+intToString(reg2.index));
		addOutput("SHL "+intToString(reg3.index));
		addOutput("COPY "+intToString(reg4.index)+" "+intToString(reg3.index));
		addOutput("SUB "+intToString(reg4.index)+" "+intToString(reg1.index));
		addOutput("JZERO "+intToString(reg4.index)+" "+intToString(getK() - 3));
		addOutput("SHR "+intToString(reg3.index));
		addOutput("COPY "+intToString(reg4.index)+" "+intToString(reg3.index));
		addOutput("INC "+intToString(reg4.index));
		addOutput("SUB "+intToString(reg4.index)+" "+intToString(reg2.index));
		addOutput("JZERO "+intToString(reg4.index)+" "+intToString(getK() + 10));
		addOutput("SHL "+intToString(reg5.index));
		addOutput("COPY "+intToString(reg4.index)+" "+intToString(reg1.index));
		addOutput("INC "+intToString(reg4.index));
		addOutput("SUB "+intToString(reg4.index)+" "+intToString(reg3.index));
		addOutput("JZERO "+intToString(reg4.index)+" "+intToString(getK() + 3));
		addOutput("SUB "+intToString(reg1.index)+" "+intToString(reg3.index));
		addOutput("INC "+intToString(reg5.index));
		addOutput("SHR "+intToString(reg3.index));
		addOutput("JUMP "+intToString(getK() - 12));
		freeRegister(reg1.index, true);
		freeRegister(reg2.index, true);
		freeRegister(reg3.index, true);
		freeRegister(reg4.index, true);
		$$.stored = reg5.index;
	}
	$$.index = -1;
	$$.value = -1;
}
| value MODULO value	{
	resetAllRegisters(true);
	Register reg1, reg2, reg3 = getFreeRegister(false), reg4 = getFreeRegister(false);
	if (isRegister($1.stored)) {    // if $1 is superVar we need to make copy od that value or we will lost it
		Register reg = prepareRegister($1);
		reg1 = getFreeRegister(false);
		addOutput("COPY "+intToString(reg1.index)+" "+intToString(reg.index));
	}
	else reg1 = prepareRegister($1);

	if (isRegister($3.stored)) {	  // if $3 is superVar we need to make copy od that value or we will lost it
		Register reg = prepareRegister($3);
		reg2 = getFreeRegister(false);
		addOutput("COPY "+intToString(reg2.index)+" "+intToString(reg.index));
	}
	else reg2 = prepareRegister($3);
	addOutput("JZERO "+intToString(reg1.index)+" "+intToString(getK() + 23));
	addOutput("JZERO "+intToString(reg2.index)+" "+intToString(getK() + 21));
	addOutput("COPY "+intToString(reg3.index)+" "+intToString(reg2.index));
	addOutput("SHL "+intToString(reg3.index));
	addOutput("COPY "+intToString(reg4.index)+" "+intToString(reg3.index));
	addOutput("SUB "+intToString(reg4.index)+" "+intToString(reg1.index));
	addOutput("JZERO "+intToString(reg4.index)+" "+intToString(getK() - 3));
	addOutput("SHR "+intToString(reg3.index));
	addOutput("COPY "+intToString(reg4.index)+" "+intToString(reg3.index));
	addOutput("INC "+intToString(reg4.index));
	addOutput("SUB "+intToString(reg4.index)+" "+intToString(reg2.index));
	addOutput("JZERO "+intToString(reg4.index)+" "+intToString(getK() + 8));
	addOutput("COPY "+intToString(reg4.index)+" "+intToString(reg1.index));
	addOutput("INC "+intToString(reg4.index));
	addOutput("SUB "+intToString(reg4.index)+" "+intToString(reg3.index));
	addOutput("JZERO "+intToString(reg4.index)+" "+intToString(getK() + 2));
	addOutput("SUB "+intToString(reg1.index)+" "+intToString(reg3.index));
	addOutput("SHR "+intToString(reg3.index));
	addOutput("JUMP "+intToString(getK() - 10));
	freeRegister(reg3.index, true);
	freeRegister(reg4.index, true);
	addOutput("JUMP "+intToString(getK() + 2));
	addOutput("RESET "+intToString(reg1.index));
	freeRegister(reg2.index, true);
	$$.index = -1;
	$$.stored = reg1.index;
	$$.value = -1;
}
;


condition
: value EQUAL value	{
	resetAllRegisters(true);
	st.push(getK());
	Register reg1, reg2, reg3;
	if ($3.value == 0 && $3.stored == -1) reg3 = prepareRegister($1); // a = 0
	else if (isRegister($1.stored) && isRegister($3.stored)) {  // superVar = superVar
		reg3 = getFreeRegister(false);
		Register reg4 = getFreeRegister(false);
		addOutput("COPY "+intToString(reg3.index)+" "+intToString($1.stored));
		addOutput("COPY "+intToString(reg4.index)+" "+intToString($3.stored));
		addOutput("SUB "+intToString(reg3.index)+" "+intToString($3.stored));
		addOutput("SUB "+intToString(reg4.index)+" "+intToString($1.stored));
		addOutput("ADD "+intToString(reg3.index)+" "+intToString(reg4.index));
		freeRegister(reg2.index, true);
		freeRegister(reg4.index, true);
	}
	else if (isRegister($1.stored)) {                      //superVar = something
		reg2 = prepareRegister($3);
		reg3 = getFreeRegister(false);
		addOutput("COPY "+intToString(reg3.index)+" "+intToString($1.stored));
		addOutput("SUB "+intToString(reg3.index)+" "+intToString(reg2.index));
		addOutput("SUB "+intToString(reg2.index)+" "+intToString($1.stored));
		addOutput("ADD "+intToString(reg3.index)+" "+intToString(reg2.index));
		freeRegister(reg2.index, true);
	}
	else if (isRegister($3.stored)) {											 //something = superVar
		reg2 = prepareRegister($1);
		reg3 = getFreeRegister(false);
		addOutput("COPY "+intToString(reg3.index)+" "+intToString($3.stored));
		addOutput("SUB "+intToString(reg3.index)+" "+intToString(reg2.index));
		addOutput("SUB "+intToString(reg2.index)+" "+intToString($3.stored));
		addOutput("ADD "+intToString(reg3.index)+" "+intToString(reg2.index));
		freeRegister(reg2.index, true);
	}
	else {																								 //something = something
		reg1 = prepareRegister($1);
		reg2 = prepareRegister($3);
		reg3 = getFreeRegister(false);
		addOutput("COPY "+intToString(reg3.index)+" "+intToString(reg1.index));
		addOutput("SUB "+intToString(reg3.index)+" "+intToString(reg2.index));
		addOutput("SUB "+intToString(reg2.index)+" "+intToString(reg1.index));
		addOutput("ADD "+intToString(reg3.index)+" "+intToString(reg2.index));
		freeRegister(reg1.index, true);
		freeRegister(reg2.index, true);
	}
	addOutput("JZERO "+intToString(reg3.index)+" "+intToString(getK() + 2));
	st.push(getK());
	addOutput("JUMP ");
	setRegister(reg3, true);
	reg_to_reset.push(reg3.index);
}
| value DIFFERENT value	{
	resetAllRegisters(true);
	st.push(getK());
	Register reg1, reg2, reg3;
	if ($3.value == 0 && $3.stored == -1) reg3 = prepareRegister($1);
	else if (isRegister($1.stored) && isRegister($3.stored)) {  // superVar != superVar
		reg3 = getFreeRegister(false);
		Register reg4 = getFreeRegister(false);
		addOutput("COPY "+intToString(reg3.index)+" "+intToString($1.stored));
		addOutput("COPY "+intToString(reg4.index)+" "+intToString($3.stored));
		addOutput("SUB "+intToString(reg3.index)+" "+intToString($3.stored));
		addOutput("SUB "+intToString(reg4.index)+" "+intToString($1.stored));
		addOutput("ADD "+intToString(reg3.index)+" "+intToString(reg4.index));
		freeRegister(reg2.index, true);
		freeRegister(reg4.index, true);
	}
	else if (isRegister($1.stored)) {                      //superVar != something
		reg2 = prepareRegister($3);
		reg3 = getFreeRegister(false);
		addOutput("COPY "+intToString(reg3.index)+" "+intToString($1.stored));
		addOutput("SUB "+intToString(reg3.index)+" "+intToString(reg2.index));
		addOutput("SUB "+intToString(reg2.index)+" "+intToString($1.stored));
		addOutput("ADD "+intToString(reg3.index)+" "+intToString(reg2.index));
		freeRegister(reg2.index, true);
	}
	else if (isRegister($3.stored)) {											 //something != superVar
		reg2 = prepareRegister($1);
		reg3 = getFreeRegister(false);
		addOutput("COPY "+intToString(reg3.index)+" "+intToString($3.stored));
		addOutput("SUB "+intToString(reg3.index)+" "+intToString(reg2.index));
		addOutput("SUB "+intToString(reg2.index)+" "+intToString($3.stored));
		addOutput("ADD "+intToString(reg3.index)+" "+intToString(reg2.index));
		freeRegister(reg2.index, true);
	}
	else {																								 //something != something
		reg1 = prepareRegister($1);
		reg2 = prepareRegister($3);
		reg3 = getFreeRegister(false);
		addOutput("COPY "+intToString(reg3.index)+" "+intToString(reg1.index));
		addOutput("SUB "+intToString(reg3.index)+" "+intToString(reg2.index));
		addOutput("SUB "+intToString(reg2.index)+" "+intToString(reg1.index));
		addOutput("ADD "+intToString(reg3.index)+" "+intToString(reg2.index));
		freeRegister(reg1.index, true);
		freeRegister(reg2.index, true);
	}
	st.push(getK());
	addOutput("JZERO "+intToString(reg3.index)+" ");
	setRegister(reg3, true);
	reg_to_reset.push(reg3.index);
}
| value LESS value	{
	resetAllRegisters(true);
	st.push(getK());
	Register reg1 = prepareRegister($1), reg2;
	if (isRegister($3.stored)) {  // something < superVar
		reg2 = getFreeRegister(false);
		addOutput("COPY "+intToString(reg2.index)+" "+intToString($3.stored));
	}
	else reg2 = prepareRegister($3);
	addOutput("SUB "+intToString(reg2.index)+" "+intToString(reg1.index));
	freeRegister(reg1.index, true);
	st.push(getK());
	addOutput("JZERO "+intToString(reg2.index)+" ");
	setRegister(reg2, true);
	reg_to_reset.push(reg2.index);
}
| value MORE value	{
	resetAllRegisters(true);
	st.push(getK());
	Register reg;
	if ($3.value == 0 && $3.stored == -1) reg = prepareRegister($1); // a > 0
	else {
		Register reg1 = prepareRegister($3);
		if (isRegister($1.stored)) {  // superVar > something
			reg = getFreeRegister(false);
			addOutput("COPY "+intToString(reg.index)+" "+intToString($1.stored));
		}
		else reg = prepareRegister($1);
		addOutput("SUB "+intToString(reg.index)+" "+intToString(reg1.index));
		freeRegister(reg1.index, true);
	}
	st.push(getK());
	addOutput("JZERO "+intToString(reg.index)+" ");
	setRegister(reg, true);
	reg_to_reset.push(reg.index);
}
| value LESS_OR_EQUAL value	{
	resetAllRegisters(true);
	st.push(getK());
	Register reg1 = prepareRegister($1), reg2;
	if (isRegister($3.stored)) {  // something < superVar
		reg2 = getFreeRegister(false);
		addOutput("COPY "+intToString(reg2.index)+" "+intToString($3.stored));
	}
	else reg2 = prepareRegister($3);
	addOutput("INC "+intToString(reg2.index));
	addOutput("SUB "+intToString(reg2.index)+" "+intToString(reg1.index));
	freeRegister(reg1.index, true);
	st.push(getK());
	addOutput("JZERO "+intToString(reg2.index)+" ");
	setRegister(reg2, true);
	reg_to_reset.push(reg2.index);
}
| value MORE_OR_EQUAL value	{
	resetAllRegisters(true);
	st.push(getK());
	Register reg1 = prepareRegister($3), reg2;
	if (isRegister($1.stored)) {  // superVar > something
		reg2 = getFreeRegister(false);
		addOutput("COPY "+intToString(reg2.index)+" "+intToString($1.stored));
	}
	else reg2 = prepareRegister($1);
	addOutput("INC "+intToString(reg2.index));
	addOutput("SUB "+intToString(reg2.index)+" "+intToString(reg1.index));
	freeRegister(reg1.index, true);
	st.push(getK());
	addOutput("JZERO "+intToString(reg2.index)+" ");
	setRegister(reg2, true);
	reg_to_reset.push(reg2.index);
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
: identifier	{
	Variable v = getVariable(string($1.name));
	if (v.isInitialized || v.length != -1 || v.iterator) 	$$ = $1;
	else yyerror("Variable "+string($1.name)+" is not initialized!");
}
| NUM	{
	$$.stored = -1;
	$$.value = $1;
	$$.name = strdup("");
	$$.index = -1;
}
;


identifier
: ID	{
	if (isDeclared($1, false)) {
		Variable v = getVariable($1);
		if (v.iterator) { 		 								//We are taking most nested iterator of this ID
			vector<ParserVar> stack_tmp_vec;
			ParserVar ps;
			ps.name = strdup("");

			while (string(ps.name).compare(string($1)) && for_stack.size() > 0) {		//Poping iterators from stack while we don't have our iterator
				ps = for_stack.top();
				stack_tmp_vec.insert(stack_tmp_vec.begin(), ps);
				for_stack.pop();
			}

			if (!string(ps.name).compare(string($1))) $$ = ps;
			else yyerror("Iterators stack error");

			for (auto i = stack_tmp_vec.begin(); i != stack_tmp_vec.end(); i++) for_stack.push(*i);  //Returning stack to previous state
		}
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
