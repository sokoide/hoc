%{
#include "book.h"
//yydebug=1;
%}

// yyparse arg
/* %parse-param { FILE* fp } */

// YYSTYPE
%union {
	Symbol *sym;	// symbols
	Inst *inst; 	// machine instructions
	int narg; 		// number of arguments
}

// priorities (lower line has higher priority)
%token <sym> NUMBER STRING PRINT VAR BLTIN UNDEF WHILE IF ELSE
%token <sym> FUNCTION PROCEDURE RETURN FUNC PROC READ
%token <narg> ARG
%type <inst> expr stmt asgn prlist stmtlist
%type <inst> cond while if begin end
%type <sym> procname
%type <narg> arglist

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
	| defn '\n'
	| list asgn '\n' { code2((Inst)pop, STOP); return 1; }
	| list stmt '\n' { code(STOP); return 1; }
	| list expr '\n' { code2(print, STOP); return 1; }
	| list error '\n' { yyerrok; }
	;
asgn: VAR '=' expr { $$=$3; code3(varpush, (Inst)$1, assign); }
	| ARG '=' expr { defnonly("$"); code2((Inst)argassign, (Inst)$1); $$=$3; }
	;
stmt: expr	{ code((Inst)pop); }
	| RETURN { defnonly("return"); code(procret); }
	| RETURN expr { defnonly("return"); $$=$2; code(funcret); }
	| PROCEDURE begin '(' arglist ')' { $$=$2; code3(call, (Inst)$1, (Inst)$4); }
	| PRINT prlist { $$=$2; }
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
begin: /* nothing */ { $$=progp; }
end: /* nothing */ { code(STOP); $$=progp; }
   ;
stmtlist: /* nothing */ { $$=progp; }
	| stmtlist '\n'
	| stmtlist stmt
	;
expr: NUMBER { $$=code2(constpush, (Inst)$1); }
	| VAR { $$=code3(varpush, (Inst)$1, eval); }
	| ARG { defnonly("$"); $$=code2((Inst)arg, (Inst)$1); }
	| asgn
	| FUNCTION begin '(' arglist ')' { $$=$2; code3(call, (Inst)$1, (Inst)$4); }
	| READ '(' VAR ')' { $$=code2(varread, (Inst)$3); }
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
prlist: expr { code(prexpr); }
	  | STRING { $$ = code2(prstr, (Inst)$1); }
	  | prlist ',' expr { code(prexpr); }
	  | prlist ',' STRING { code2(prstr, (Inst)$3); }
	  ;
defn: FUNC procname { $2->type=FUNCTION; indef=1; }
	    '(' ')' stmt { code(procret); define($2); indef=0; }
	| PROC procname { $2->type=PROCEDURE; indef=1; }
	    '(' ')' stmt { code(procret); define($2); indef=0; }
	;
procname: VAR
		| FUNCTION
		| PROCEDURE
		;
arglist: /* nothing */ { $$=0; }
	   | expr { $$=1; }
	   | arglist ',' expr { $$=$1+1; }
	   ;
%%
// additional C
int main(int argc, char** argv) {
	progname = argv[0];
	if(argc == 1){
		static char *stdinonly[] = { "-" };
		gargv = stdinonly;
		gargc = 1;
	} else {
		gargv = argv+1;
		gargc = argc-1;
	}

	init();
	run();
	return 0;
}

void run() {
    setjmp(begin);
    signal(SIGFPE, fpecatch);
    for (initcode(); yyparse(); initcode())
        execute(progbase);
}
