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
\"[^\"]*\" {
	size_t l = strlen(yytext);
	char sbuf[512];
	strncpy(sbuf, &yytext[1], l-2);
	sbuf[l-2] = '\0';
	yylval.sym = (Symbol*)emalloc(strlen(sbuf) +1);
	strncpy((char*)yylval.sym, sbuf, strlen(sbuf));
	return STRING;
}
$[1-9][0-9]* {
	int n;
	sscanf(&yytext[1], "%d", &n);
	yylval.narg = n;
	return ARG;
}
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
