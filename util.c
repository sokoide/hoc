#include "book.h"
#include "book.tab.h"
#include <math.h>
#include <stdlib.h>
#include <string.h>

#define NSTACK 256
#define NPROG 2000

// global vars
jmp_buf begin;
int indef;
char* infile;
char** gargv;
int gargc;
char* progname;
Inst* progbase = prog; // start of current subprogram
int lineno = 1;
Inst* progp;

// local vars
static Symbol* symlist = 0;
static Datum stack[NSTACK];
static Datum* stackp;
Inst prog[NPROG];
static Inst* pc;      // program counter
static int returning; // 1 if return stmt seen

typedef struct Frame {
    Symbol* sp;
    Inst* retpc;
    Datum* argn;
    int nargs;
} Frame;

#define NFRAME 100
Frame frame[NFRAME];
Frame* fp;

// constants
static struct {
    char* name;
    double cval;
} consts[] = {
    "PI",    3.14159265358979323846,
    "E",     2.718,
    "GAMMA", 0.5772156659,
    "DEG",   57.2957795,
    "PHI",   1.618,
    0,       0,
};

// builtins
static struct {
    char* name;
    double (*func)();
} builtins[] = {
    "sin", sin, "cos", cos, 0, 0,
};

// keywords
static struct {
    char* name;
    int kval;
} keywords[] = {
    "proc", PROC,    "func", FUNC,    "return", RETURN, "if", IF, "else",
    ELSE,   "while", WHILE,  "print", PRINT,    "read", READ, 0,  0,
};

void init() {
    int i;
    Symbol* s;
    for (i = 0; consts[i].name; i++)
        install(consts[i].name, VAR, consts[i].cval);
    for (i = 0; builtins[i].name; i++) {
        s = install(builtins[i].name, BLTIN, 0.0);
        s->u.ptr = builtins[i].func;
    }
    for (i = 0; keywords[i].name; i++)
        install(keywords[i].name, keywords[i].kval, 0.0);
}

// symbol
Symbol* lookup(char* s) {
    Symbol* sp;
    for (sp = symlist; sp != (Symbol*)0; sp = sp->next)
        if (strcmp(sp->name, s) == 0)
            return sp;
    return 0; // not found
}

Symbol* install(char* s, int t, double d) {
    Symbol* sp;

    sp = (Symbol*)emalloc(sizeof(Symbol));
    sp->name = emalloc(strlen(s) + 1); // +1 for '\0'
    strcpy(sp->name, s);
    sp->type = t;
    sp->u.val = d;
    sp->next = symlist;
    symlist = sp;
    return sp;
}

// code generation
void initcode() {
    progp = progbase;
    stackp = stack;
    fp = frame;
    returning = 0;
}

int push(Datum d) {
    if (stackp >= &stack[NSTACK])
        execerror("stack overflow", (char*)0);
    *stackp++ = d;
    return 0; // ret value not used
}

Datum pop() {
    if (stackp <= stack)
        execerror("stack underflow", (char*)0);
    return *--stackp;
}

Inst* code(Inst f) {
    Inst* oprogp = progp;
    if (progp >= &prog[NPROG])
        execerror("program too big", (char*)0);
    *progp++ = f;
    return oprogp;
}

void execute(Inst* p) {
    for (pc = p; *pc != STOP && !returning;) {
        // printf("pc:%p\n", pc);
        (*(pc++))();
    }
}

int constpush() {
    Datum d;
    d.val = ((Symbol*)*pc++)->u.val;
    push(d);
    return 0; // ret value not used
}

int varpush() {
    Datum d;
    d.sym = (Symbol*)(*pc++);
    push(d);
    return 0; // ret value not used
}

int add() {
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val += d2.val;
    push(d1);
    return 0; // ret value not used
}

int sub() {
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val -= d2.val;
    push(d1);
    return 0; // ret value not used
}

int mul() {
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val *= d2.val;
    push(d1);
    return 0; // ret value not used
}

int _div() {
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    if (d2.val == 0)
        execerror("devided by zero", (char*)0);
    d1.val /= d2.val;
    push(d1);
    return 0; // ret value not used
}

int negate() {
    Datum d1;
    d1 = pop();
    d1.val = -d1.val;
    push(d1);
    return 0; // ret value not used
}

int power() {
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val = pow(d1.val, d2.val);
    push(d1);
    return 0; // ret value not used
}

int mod() {
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val = (int)d1.val % (int)d2.val;
    push(d1);
    return 0; // ret value not used
}

int eval() {
    Datum d;
    d = pop();
    if (d.sym->type == UNDEF)
        execerror("undefined variable", d.sym->name);
    d.val = d.sym->u.val;
    push(d);
    return 0; // ret value not used
}

int assign() {
    Datum d1, d2;
    d1 = pop();
    d2 = pop();
    if (d1.sym->type != VAR && d1.sym->type != UNDEF)
        execerror("assignment to non-variable", d1.sym->name);
    d1.sym->u.val = d2.val;
    d1.sym->type = VAR;
    push(d2);
    return 0; // ret value not used
}

int print() {
    Datum d;
    d = pop();
    printf("\t%.8g\n", d.val);
    return 0; // ret value not used
}

int bltin() {
    Datum d;
    d = pop();
    d.val = (*(double (*)())(*pc++))(d.val);
    push(d);
    return 0; // ret value not used
}

int le() {
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val = (double)(d1.val <= d2.val);
    push(d1);
    return 0; // ret vaule not used
}

int lt() {
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val = (double)(d1.val < d2.val);
    push(d1);
    return 0; // ret vaule not used
}

int ge() {
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val = (double)(d1.val >= d2.val);
    push(d1);
    return 0; // ret vaule not used
}

int gt() {
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val = (double)(d1.val > d2.val);
    push(d1);
    return 0; // ret vaule not used
}

int eq() {
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val = (double)(d1.val == d2.val);
    push(d1);
    return 0; // ret vaule not used
}

int ne() {
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val = (double)(d1.val != d2.val);
    push(d1);
    return 0; // ret vaule not used
}

int _and() {
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val = (double)(d1.val && d2.val);
    push(d1);
    return 0; // ret vaule not used
}

int _or() {
    Datum d1, d2;
    d2 = pop();
    d1 = pop();
    d1.val = (double)(d1.val || d2.val);
    push(d1);
    return 0; // ret vaule not used
}

int not() {
    Datum d;
    d = pop();
    d.val = (double)(!d.val);
    push(d);
    return 0; // ret vaule not used
}

int whilecode() {
    Datum d;
    Inst* savepc = pc;   // loop bocy
    execute(savepc + 2); // condition
    d = pop();
    while (d.val) {
        execute(*((Inst**)(savepc))); // body
        execute(savepc + 2);
        d = pop();
    }

    if (!returning)
        pc = *((Inst**)(savepc + 1)); // next statement
    return 0;                         // ret vaule not used
}

int ifcode() {
    Datum d;
    Inst* savepc = pc;   // loop bocy
    execute(savepc + 3); // condition
    d = pop();
    if (d.val)
        execute(*((Inst**)(savepc))); //  then part
    else if (*((Inst**)(savepc + 1)))
        execute(*((Inst**)(savepc + 1))); //  else part

    if (!returning)
        pc = *((Inst**)(savepc + 2)); // next statement
    return 0;                         // ret vaule not used
}

int prexpr() {
    Datum d;
    d = pop();
    printf("%.8g\n", d.val);
    return 0; // ret vaule not used
}

int prstr() {
    printf("%s", (char*)*pc++);
    return 0; // ret vaule not used
}

int varread() {
    Datum d;
    Symbol* var = (Symbol*)*pc++;
Again:
    switch (scanf("%lf", &var->u.val)) {
    case EOF:
        if (moreinput())
            goto Again;
        d.val = var->u.val = 0.0;
        break;
    case 0:
        execerror("non-nubmer read into", var->name);
        break;
    default:
        d.val = 1.0;
        break;
    }
    var->type = VAR;
    push(d);
    return 0; // ret vaule not used
}

int call() {
    Symbol* sp = (Symbol*)pc[0];
    if (fp++ > &frame[NFRAME - 1])
        execerror(sp->name, "call nested too deeply");
    fp->sp = sp;
    fp->nargs = (int)pc[1];
    fp->retpc = pc + 2;
    fp->argn = stackp - 1; // last argument
    execute((Inst*)(sp->u.defn));
    returning = 0;
    return 0; // ret vaule not used
}

int funcret() {
    Datum d;
    if (fp->sp->type == PROCEDURE)
        execerror(fp->sp->name, "(proc) returns value");
    d = pop(); // preserve function return value
    ret();
    push(d);
    return 0; // ret vaule not used
}

int procret() {
    if (fp->sp->type == FUNCTION)
        execerror(fp->sp->name, "(func) returns no value");
    ret();
    return 0; // ret vaule not used
}

int ret() {
    int i;
    for (i = 0; i < fp->nargs; i++)
        pop(); // pop arguments
    pc = (Inst*)fp->retpc;
    --fp;
    returning = 1;
    return 0; // ret vaule not used
}

double* getarg() {
    int nargs = (int)*pc++;
    if (nargs > fp->nargs)
        execerror(fp->sp->name, "not enough arguments");
    return &fp->argn[nargs - fp->nargs].val;
}

void arg() {
    Datum d;
    d.val = *getarg();
    push(d);
}

int argassign() {
    Datum d;
    d = pop();
    push(d);
    *getarg() = d.val;
    return 0; // ret vaule not used
}

void define(Symbol* sp) {
    sp->u.defn = (Inst)progbase;
    progbase = progp;
}

void defnonly(const char* s) {
    if (!indef)
        execerror(s, "used outside of definition");
}

// malloc wrapper
char* emalloc(unsigned n) {
    char* p;
    p = malloc(n);
    if (p == 0)
        execerror("out of memory", (char*)0);
    return p;
}

// error handling
void execerror(const char* msg, const char* t) {
    warning(msg, t);
    longjmp(begin, 0);
}

void warning(const char* s, const char* t) {
    fprintf(stderr, "%s: %s", progname, s);
    if (t) {
        fprintf(stderr, " %s", t);
    }
    fprintf(stderr, " near line %d\n", lineno);
}

void yyerror(const char* s) { warning(s, (const char*)0); }
/* void yyerror(FILE* fp, const char* s) { warning(s, (const char*)0); } */

void fpecatch() { execerror("floating point exception", (const char*)0); }

int moreinput() {
    lineno = 1;
    return 1;
}

