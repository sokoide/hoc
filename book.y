%{
#include "book.h"
%}
// YYSTYPE
%union {
	Symbol *sym;	// symbols
	Inst *inst; 	// machine instructions
}

// priorities (lower line has higher priority)
%token <sym> NUMBER PRINT VAR BLTIN UNDEF WHILE IF ELSE
%type <inst> stmt asgn expr stmtlist cond while if end
%right '='
%left OR
%left AND
%left GT GE LT LE EQ NE
%left '+' '-'
%left '*' '/' '%'
%left UNARYMINUS NOT
%right '^'

%%
// grammar
list: /* nothing */
	| list '\n'
	| list asgn '\n' { code2((Inst)pop, STOP); return 1; }
	| list stmt '\n' { code(STOP); return 1; }
	| list expr '\n' { code2(print, STOP); return 1; }
	| list error '\n' { yyerrok; }
	;
asgn: VAR '=' expr { $$=$3; code3(varpush, (Inst)$1, assign); }
	;
stmt: expr	{ code((Inst)pop); }
	| PRINT expr { code(prexpr); $$=$2; }
	| while cond stmt end {
		($1)[1] = (Inst)$3; // body of loop
		($1)[2] = (Inst)$4; } // end, if cond fails
	| if cond stmt end { // else-less if
		($1)[1] = (Inst)$3;	// then part
		($1)[3] = (Inst)$4; } // end, if cond fails
	| if cond stmt end ELSE stmt end { // if with else
		($1)[1] = (Inst)$3;	// them part
		($1)[2] = (Inst)$6; // else part
		($1)[3] = (Inst)$7; } // end, if cond fails
	| '{' stmtlist '}' { $$=$2; }
	;
cond: '(' expr ')' { code(STOP); $$=$2; }
	;
while: WHILE { $$ = code3(whilecode, STOP, STOP); }
	 ;
if:	IF { $$ = code(ifcode); code3(STOP, STOP, STOP); }
  ;
end: /* nothing */ { code(STOP); $$=progp; }
   ;
stmtlist: /* nothing */ { $$=progp; }
	| stmtlist '\n'
	| stmtlist stmt
	;
expr: NUMBER { $$=code2(constpush, (Inst)$1); }
	| VAR { $$=code3(varpush, (Inst)$1, eval); }
	| asgn
	| BLTIN '(' expr ')' { $$ = $3; code2(bltin, (Inst)$1->u.ptr); }
	| '(' expr ')' { $$ = $2; }
	| expr '+' expr { code(add); }
	| expr '-' expr { code(sub); }
	| expr '*' expr { code(mul); }
	| expr '/' expr { code(_div); }
	| expr '^' expr { code(power); }
	| expr '%' expr { code(mod); }
	| '-' expr %prec UNARYMINUS { $$ = $2; code(negate); }
	| expr GT expr { code(gt); }
	| expr GE expr { code(ge); }
	| expr LT expr { code(lt); }
	| expr LE expr { code(le); }
	| expr EQ expr { code(eq); }
	| expr NE expr { code(ne); }
	| expr AND expr { code(_and); }
	| expr OR expr { code(_or); }
	| NOT expr { $$ = $2; code(not); }
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

