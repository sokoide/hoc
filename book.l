%{
#include "book.h"
#include "book.tab.h"
%}

%option noyywrap

%%
[ \t] {;} // skip empty
[0-9]+\.?|[0-9]*\.[0-9]+ {
	double d;
	sscanf(yytext, "%lf", &d);
	yylval.sym = install("", NUMBER, d);
	return NUMBER;
	}
[a-zA-Z][a-zA-Z0-9]* {
	Symbol *s;
	if((s = lookup(yytext)) ==0)
		s = install(yytext, UNDEF, 0.0);
	yylval.sym = s;
	return s-> type == UNDEF ? VAR : s->type;}
">="	{ return GE; }
">"	{ return GT; }
"<="	{ return LE; }
"<"	{ return LT; }
"=="	{ return EQ; }
"="	{ return '='; }
"!="	{ return NE; }
"!"	{ return NOT; }
"||"	{ return OR; }
"|"	{ return '|'; }
"&&"	{ return AND; }
"&"	{ return '&'; }
\n	{ lineno++; return '\n';}
. 	{return yytext[0];}
