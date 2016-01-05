%{
#include "functions.h"
#include "kompilator.tab.h"
#include <stdio.h>
#include <string.h>
%}
%%


\[[^[]*\]		;
[_a-z]+			{ yylval.str = strdup(yytext); return ID; }
[0-9]+			{ yylval.num = atoi(yytext); return NUM; }
"="					{ return EQUAL; }
"+"					{ return ADD; }
"-"					{ return MINUS; }
"*"					{ return MULTI; }
"/"					{ return DIV; }
"%"					{ return MODULO; }
"("					{ return LEFT; }
")"					{ return RIGHT; }
"<"					{ return LESS; }
"<="				{ return LESS_OR_EQUAL; }
">"					{ return MORE; }
">="				{ return MORE_OR_EQUAL; }
"!="				{ return DIFFERENT; }
";"					{ return SEMICOLON; }
":="				{ return ASSIGN; }
"DECLARE"		{ return DECLARE; }
"IN"				{ return IN; }
"GET"				{ return GET; }
"PUT"				{ return PUT; }
"IF"				{ return IF; }
"THEN"			{ return THEN; }
"ELSE"			{ return ELSE; }
"ENDIF"			{ return ENDIF; }
"WHILE"			{ return WHILE; }
"DO"				{ return DO; }
"ENDWHILE"	{ return ENDWHILE; }
"FOR"				{ return FOR; }
"DOWN"			{ return DOWN; }
"FROM"			{ return FROM; }
"TO"				{ return TO; }
"ENDFOR"		{ return ENDFOR; }
"END"				{ return END; }
[_a-z0-9]+	{ printf("Unrecognized identifier: %s\n", yytext); exit(0); }
[ \t\n]			;
.						{ printf("Error detected during compilation: %s\n", yytext); exit(0); }

%%
int yywrap(void) {
	return 1;
}
