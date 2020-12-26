%{
#include "book.h"
%}
%union {
	double val;
	Symbol *sym;
}

// priorities (lower line has higher priority)
%token <val> NUMBER
%token <sym> VAR BLTIN UNDEF
%type <val> expr asgn
%right '='
%left '+' '-'
%left '*' '/' '%'
%left UNARYMINUS

%%
// grammar
list: /* empty */
	| list '\n'
	| list asgn '\n'
	| list expr '\n' { printf("\t%.8g\n", $2); }
	| list error '\n' { yyerrok; }
	;
asgn: VAR '=' expr { $$=$1->u.val=$3; $1->type = VAR; }
expr: NUMBER
	| VAR { if ($1->type == UNDEF){
		execerror("undefined variable", $1->name);
		}
		$$ = $1->u.val;
		}
	| asgn
	| BLTIN '(' expr ')' { $$ = (*($1->u.ptr))($3); }
	| '-' expr %prec UNARYMINUS { $$ = -$2; }
	| VAR { if($1->type == UNDEF) execerror("undefined variable", $1->name);
		$$ = $1->u.val;}
	| expr '+' expr { $$ = $1 + $3; }
	| expr '-' expr { $$ = $1 - $3; }
	| expr '*' expr { $$ = $1 * $3; }
	| expr '/' expr {
		if($3 == 0.0) execerror("division by zero", "");
		$$ = $1 / $3; }
	| expr '%' expr { $$ = (int)$1 % (int)$3; }
	| '(' expr ')' { $$ = $2; }
	;
%%
// additional C
int main(int argc, char** argv) {
    progname = argv[0];
    init();
    setjmp(begin);
    signal(SIGFPE, fpecatch);
    return yyparse();
}

