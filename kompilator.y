%{
#include "functions.h"
stack<unsigned long long int> st;
stack<int> reg_to_reset;
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
	freeRegister(reg_to_reset.top(), true);
	reg_to_reset.pop();
}
| IF condition THEN commands else commands ENDIF	{
	setOutput(st.top(), intToString(getK())); st.pop(); st.pop();
	freeRegister(reg_to_reset.top(), true);
	reg_to_reset.pop();
}
| WHILE condition DO commands ENDWHILE	{
	setOutput(st.top(), intToString(getK()+1)); st.pop();
	addOutput("JUMP "+intToString(st.top())); st.pop();
	freeRegister(reg_to_reset.top(), true);
	reg_to_reset.pop();
}
| FOR iterator FROM value TO value	{
	Register reg1 = prepareRegister($4);
	storeIterator($2, reg1);
	st.push(getK());
	reg1 = prepareRegister($2);
	Register reg2;
	if (isRegister($6.stored)) {  			 //FOR i FROM value TO superVar
		reg2 = getFreeRegister();
		addOutput("COPY "+intToString(reg2.index)+" "+intToString($6.stored));
	}
	else reg2 = prepareRegister($6);
	setRegister(reg2, true);
	addOutput("INC "+intToString(reg2.index));
	addOutput("SUB "+intToString(reg2.index)+" "+intToString(reg1.index));
	freeRegister(reg1.index, true);
	for_stack.push($2);
	st.push(getK());
	addOutput("JZERO "+intToString(reg2.index)+" ");
	freeRegister(reg2.index, true);
	reg_to_reset.push(reg2.index);
}
DO commands ENDFOR	{
	ParserVar p1 = for_stack.top();
	for_stack.pop();
	Register reg = prepareRegister(p1);
	addOutput("INC "+intToString(reg.index));
	storeIterator(p1, reg);
	setOutput(st.top(), intToString(getK() + 1));
	st.pop();
	addOutput("JUMP "+intToString(st.top()));
	st.pop();
	deleteIterator(p1);
	freeRegister(reg_to_reset.top(), true);
	reg_to_reset.pop();
}
| FOR iterator DOWN FROM value TO value {
	Register reg1 = prepareRegister($5);
	storeIterator($2, reg1);
	st.push(getK());
	if (isRegister($2.stored)) {
		reg1 = getFreeRegister();
		addOutput("COPY "+intToString(reg1.index)+" "+intToString($2.stored));
	}
	else reg1 = prepareRegister($2);
	setRegister(reg1, true);
	Register reg2 = prepareRegister($7);
	setRegister(reg2, true);
	addOutput("INC "+intToString(reg1.index));
	addOutput("SUB "+intToString(reg1.index)+" "+intToString(reg2.index));
	freeRegister(reg2.index, true);
	for_stack.push($2);
	st.push(getK());
	addOutput("JZERO "+intToString(reg1.index)+" ");
	freeRegister(reg1.index, true);
	reg_to_reset.push(reg1.index);
}
DO commands ENDFOR	{
	ParserVar p1 = for_stack.top();
	for_stack.pop();
	Register reg = prepareRegister(p1);
	unsigned long long int index = getK();
	addOutput("JZERO "+intToString(reg.index)+" ");
	addOutput("DEC "+intToString(reg.index));
	storeIterator(p1, reg);
	setOutput(st.top(), intToString(getK()+1));
	st.pop();
	addOutput("JUMP "+intToString(st.top()));
	st.pop();
	setOutput(index, intToString(getK()));
	deleteIterator(p1);
	freeRegister(reg_to_reset.top(), true);
	reg_to_reset.pop();
}
| GET identifier SEMICOLON	{
	ParserVar p;
	Register reg = getFreeRegister();
	addOutput("READ "+intToString(reg.index));
	p.stored = reg.index;
	p.index = -1;
	storeVariable($2, p);
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
	//TODO small value increment not using new register
	Register reg = prepareRegister($1);
	$$.index = -1;
	$$.stored = reg.index;
	$$.value = $1.value;
	if ($1.value == -1) $$.error = true;
}
|	value ADD value {
	resetAllRegisters(true);
	if (isRegister($1.stored) || isRegister($3.stored)) {               //superVar optimalization
		Register reg = getFreeRegister(), reg2;
		int changedIndex = -1;

		if (isRegister($1.stored) && isRegister($3.stored)) {   					//superVar + superVar
			addOutput("COPY "+intToString(reg.index)+" "+intToString($3.stored));
			reg2 = prepareRegister($1);
		}
		else if (isRegister($1.stored) && !isRegister($3.stored)) {       //superVar + notSuperVar
			reg2 = prepareRegister($3);
			changedIndex = $1.stored;
		}
		else if (!isRegister($1.stored) && isRegister($3.stored)) {  			//notSuperVar + superVar
			reg2 = prepareRegister($1);
			changedIndex = $3.stored;
		}
		else yyerror("superVar problem in addition");                     //This shouldn't happen

		if (changedIndex != -1) {
			addOutput("ADD "+intToString(reg2.index)+" "+intToString(changedIndex));
			$$.stored = reg2.index;
		}
		else {
			addOutput("ADD "+intToString(reg.index)+" "+intToString(reg2.index));
			$$.stored = reg.index;
			freeRegister(reg2.index, true);
		}
	}
	else {
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
	$$.error = checkIfInitialized($1, $3);
}
| value MINUS value	{
	resetAllRegisters(true);
	if (isRegister($1.stored) || isRegister($3.stored)) {  												//superVar optimalization
		Register reg, reg2 = prepareRegister($3);
		if (isRegister($1.stored)) {																								//superVar - something
			reg = getFreeRegister();
			addOutput("COPY "+intToString(reg.index)+" "+intToString($1.stored));
		}
		else reg = prepareRegister($1);																							//something - superVar
		addOutput("SUB "+intToString(reg.index)+" "+intToString(reg2.index));
		freeRegister(reg2.index, true);
		$$.stored = reg.index;
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
	$$.error = checkIfInitialized($1, $3);
}
| value MULTI value	{
	resetAllRegisters(true);
//	unsigned long long int quickResult = quickMultiplication($1, $3);
//	if (quickResult != -1) $$.stored = quickResult;
//	else {
		Register reg1, reg2, reg3 = getFreeRegister();
		if (isRegister($1.stored)) {    // if $1 is superVar we need to make copy od that value or we will lost it
			Register reg = prepareRegister($1);
			reg1 = getFreeRegister();
			addOutput("COPY "+intToString(reg1.index)+" "+intToString(reg.index));
		}
		else reg1 = prepareRegister($1);

		if (isRegister($3.stored)) {	  // if $3 is superVar we need to make copy od that value or we will lost it
			Register reg = prepareRegister($3);
			reg2 = getFreeRegister();
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
		$$.index = -1;
		$$.stored = reg3.index;
		$$.error = checkIfInitialized($1, $3);
	//}
}
| value DIV value	{
	resetAllRegisters(true);
	Register reg1, reg2, reg3 = getFreeRegister(), reg4 = getFreeRegister(), reg5 = getFreeRegister();
	if (isRegister($1.stored)) {    // if $1 is superVar we need to make copy od that value or we will lost it
		Register reg = prepareRegister($1);
		reg1 = getFreeRegister();
		addOutput("COPY "+intToString(reg1.index)+" "+intToString(reg.index));
	}
	else reg1 = prepareRegister($1);

	if (isRegister($3.stored)) {	  // if $3 is superVar we need to make copy od that value or we will lost it
		Register reg = prepareRegister($3);
		reg2 = getFreeRegister();
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
	$$.index = -1;
	$$.error = checkIfInitialized($1, $3);
}
| value MODULO value	{
	resetAllRegisters(true);
	Register reg1, reg2, reg3 = getFreeRegister(), reg4 = getFreeRegister();
	if (isRegister($1.stored)) {    // if $1 is superVar we need to make copy od that value or we will lost it
		Register reg = prepareRegister($1);
		reg1 = getFreeRegister();
		addOutput("COPY "+intToString(reg1.index)+" "+intToString(reg.index));
	}
	else reg1 = prepareRegister($1);

	if (isRegister($3.stored)) {	  // if $3 is superVar we need to make copy od that value or we will lost it
		Register reg = prepareRegister($3);
		reg2 = getFreeRegister();
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
	$$.error = checkIfInitialized($1, $3);
}
;


condition
: value EQUAL value	{
	resetAllRegisters(true);
	st.push(getK());
	Register reg1, reg2, reg3 = getFreeRegister();
	if (isRegister($1.stored) && isRegister($3.stored)) {  // superVar = superVar
		Register reg4 = getFreeRegister();
		addOutput("COPY "+intToString(reg3.index)+" "+intToString($1.stored));
		addOutput("COPY "+intToString(reg4.index)+" "+intToString($3.stored));
		addOutput("SUB "+intToString(reg3.index)+" "+intToString($3.stored));
		addOutput("SUB "+intToString(reg4.index)+" "+intToString($1.stored));
		addOutput("ADD "+intToString(reg3.index)+" "+intToString(reg4.index));
		freeRegister(reg4.index, true);
	}
	else if (isRegister($1.stored)) {                      //superVar = something
		reg2 = prepareRegister($3);
		addOutput("COPY "+intToString(reg3.index)+" "+intToString($1.stored));
		addOutput("SUB "+intToString(reg3.index)+" "+intToString(reg2.index));
		addOutput("SUB "+intToString(reg2.index)+" "+intToString($1.stored));
		addOutput("ADD "+intToString(reg3.index)+" "+intToString(reg2.index));
	}
	else if (isRegister($3.stored)) {											 //something = superVar
		reg2 = prepareRegister($1);
		addOutput("COPY "+intToString(reg3.index)+" "+intToString($3.stored));
		addOutput("SUB "+intToString(reg3.index)+" "+intToString(reg2.index));
		addOutput("SUB "+intToString(reg2.index)+" "+intToString($3.stored));
		addOutput("ADD "+intToString(reg3.index)+" "+intToString(reg2.index));
	}
	else {																								 //something = something
		reg1 = prepareRegister($1);
		reg2 = prepareRegister($3);
		addOutput("COPY "+intToString(reg3.index)+" "+intToString(reg1.index));
		addOutput("SUB "+intToString(reg3.index)+" "+intToString(reg2.index));
		addOutput("SUB "+intToString(reg2.index)+" "+intToString(reg1.index));
		addOutput("ADD "+intToString(reg3.index)+" "+intToString(reg2.index));
		freeRegister(reg1.index, true);
	}
	freeRegister(reg2.index, true);
	addOutput("JZERO "+intToString(reg3.index)+" "+intToString(getK() + 2));
	st.push(getK());
	addOutput("JUMP ");
	setRegister(reg3, true);
	reg_to_reset.push(reg3.index);
	$$.error = checkIfInitialized($1, $3);
}
| value DIFFERENT value	{
	resetAllRegisters(true);
	st.push(getK());
	Register reg1, reg2, reg3 = getFreeRegister();
	if (isRegister($1.stored) && isRegister($3.stored)) {  // superVar != superVar
		Register reg4 = getFreeRegister();
		addOutput("COPY "+intToString(reg3.index)+" "+intToString($1.stored));
		addOutput("COPY "+intToString(reg4.index)+" "+intToString($3.stored));
		addOutput("SUB "+intToString(reg3.index)+" "+intToString($3.stored));
		addOutput("SUB "+intToString(reg4.index)+" "+intToString($1.stored));
		addOutput("ADD "+intToString(reg3.index)+" "+intToString(reg4.index));
		freeRegister(reg4.index, true);
	}
	else if (isRegister($1.stored)) {                      //superVar != something
		reg2 = prepareRegister($3);
		addOutput("COPY "+intToString(reg3.index)+" "+intToString($1.stored));
		addOutput("SUB "+intToString(reg3.index)+" "+intToString(reg2.index));
		addOutput("SUB "+intToString(reg2.index)+" "+intToString($1.stored));
		addOutput("ADD "+intToString(reg3.index)+" "+intToString(reg2.index));
	}
	else if (isRegister($3.stored)) {											 //something != superVar
		reg2 = prepareRegister($1);
		addOutput("COPY "+intToString(reg3.index)+" "+intToString($3.stored));
		addOutput("SUB "+intToString(reg3.index)+" "+intToString(reg2.index));
		addOutput("SUB "+intToString(reg2.index)+" "+intToString($3.stored));
		addOutput("ADD "+intToString(reg3.index)+" "+intToString(reg2.index));
	}
	else {																								 //something != something
		reg1 = prepareRegister($1);
		reg2 = prepareRegister($3);
		addOutput("COPY "+intToString(reg3.index)+" "+intToString(reg1.index));
		addOutput("SUB "+intToString(reg3.index)+" "+intToString(reg2.index));
		addOutput("SUB "+intToString(reg2.index)+" "+intToString(reg1.index));
		addOutput("ADD "+intToString(reg3.index)+" "+intToString(reg2.index));
		freeRegister(reg1.index, true);
	}
	freeRegister(reg2.index, true);
	st.push(getK());
	addOutput("JZERO "+intToString(reg3.index)+" ");
	setRegister(reg3, true);
	reg_to_reset.push(reg3.index);
	$$.error = checkIfInitialized($1, $3);
}
| value LESS value	{
	resetAllRegisters(true);
	st.push(getK());
	Register reg1 = prepareRegister($1), reg2;
	if (isRegister($3.stored)) {  // something < superVar
		reg2 = getFreeRegister();
		addOutput("COPY "+intToString(reg2.index)+" "+intToString($3.stored));
	}
	else reg2 = prepareRegister($3);
	addOutput("SUB "+intToString(reg2.index)+" "+intToString(reg1.index));
	freeRegister(reg1.index, true);
	st.push(getK());
	addOutput("JZERO "+intToString(reg2.index)+" ");
	setRegister(reg2, true);
	reg_to_reset.push(reg2.index);
	$$.error = checkIfInitialized($1, $3);
}
| value MORE value	{
	resetAllRegisters(true);
	st.push(getK());
	Register reg1 = prepareRegister($3), reg2;
	if (isRegister($1.stored)) {  // superVar > something
		reg2 = getFreeRegister();
		addOutput("COPY "+intToString(reg2.index)+" "+intToString($1.stored));
	}
	else reg2 = prepareRegister($1);
	addOutput("SUB "+intToString(reg2.index)+" "+intToString(reg1.index));
	freeRegister(reg1.index, true);
	st.push(getK());
	addOutput("JZERO "+intToString(reg2.index)+" ");
	setRegister(reg2, true);
	reg_to_reset.push(reg2.index);
	$$.error = checkIfInitialized($1, $3);
}
| value LESS_OR_EQUAL value	{
	resetAllRegisters(true);
	st.push(getK());
	Register reg1 = prepareRegister($1), reg2;
	if (isRegister($3.stored)) {  // something < superVar
		reg2 = getFreeRegister();
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
	$$.error = checkIfInitialized($1, $3);
}
| value MORE_OR_EQUAL value	{
	resetAllRegisters(true);
	st.push(getK());
	Register reg1 = prepareRegister($3), reg2;
	if (isRegister($1.stored)) {  // superVar > something
		reg2 = getFreeRegister();
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
