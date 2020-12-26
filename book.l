%{
#include "book.h"
#include "book.tab.h"
%}

%option noyywrap

%%
[ \t] {;} // skip empty
[0-9]+\.?|[0-9]*\.[0-9]+ {
sscanf(yytext, "%lf", &yylval.val); return NUMBER; }
[a-zA-Z][a-zA-Z0-9]* {
	Symbol *s;
	if((s = lookup(yytext)) ==0)
		s = install(yytext, UNDEF, 0.0);
	yylval.sym = s;
	return s-> type == UNDEF ? VAR : s->type;}
\n	{ lineno++; return '\n';}
. 	{return yytext[0];}
