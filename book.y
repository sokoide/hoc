%{
#include "book.h"
%}
// YYSTYPE
%union {
	Symbol *sym;	// symbols
	Inst *inst; 	// machine instructions
}

// priorities (lower line has higher priority)
%token <sym> NUMBER VAR BLTIN UNDEF
%right '='
%left '+' '-'
%left '*' '/' '%'
%left UNARYMINUS
%right '^'

%%
// grammar
list: /* empty */
	| list '\n'
	| list asgn '\n' { code2((Inst)pop, STOP); return 1; }
	| list expr '\n' { code2(print, STOP); return 1; }
	| list error '\n' { yyerrok; }
	;
asgn: VAR '=' expr { code3(varpush, (Inst)$1, assign); }
	;
expr: NUMBER { code2(constpush, (Inst)$1); }
	| VAR { code3(varpush, (Inst)$1, eval); }
	| asgn
	| BLTIN '(' expr ')' {  code2(bltin, (Inst)$1->u.ptr); }
	| '(' expr ')'
	| expr '+' expr { code(add); }
	| expr '-' expr { code(sub); }
	| expr '*' expr { code(mul); }
	| expr '/' expr { code(_div); }
	| expr '^' expr { code(power); }
	| expr '%' expr { code(mod); }
	| '-' expr %prec UNARYMINUS { code(negate); }
	;
%%
// additional C
int main(int argc, char** argv) {
	progname = argv[0];
	init();
	setjmp(begin);
	signal(SIGFPE, fpecatch);
	for(initcode(); yyparse(); initcode())
	execute(prog);
	return 0;
}

