#include "book.h"
#include "book.tab.h"
#include <math.h>
#include <stdlib.h>
#include <string.h>

// global vars
jmp_buf begin;
char* progname;
int lineno = 1;
extern double Log(), Log10(), Exp(), Sqrt(), integer();

// local vars
static Symbol* symlist = 0;

// constants
static struct {
    char* name;
    double cval;
} consts[] = {"PI",    3.14159265358979323846,
              "E",     2.718,
              "GAMMA", 0.5772156659,
              "DEG",   57.2957795,
              "PHI",   1.618,
              0,       0};

// builtins
static struct {
    char* name;
    double (*func)();
} builtins[] = {"sin", sin, "cos", cos, 0, 0};

void init() {
    int i;
    Symbol* s;
    for (i = 0; consts[i].name; i++)
        install(consts[i].name, VAR, consts[i].cval);
    for (i = 0; builtins[i].name; i++) {
        s = install(builtins[i].name, BLTIN, 0.0);
        s->u.ptr = builtins[i].func;
    }
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
    char* emalloc();

    sp = (Symbol*)emalloc(sizeof(Symbol));
    sp->name = emalloc(strlen(s) + 1); // +1 for '\0'
    strcpy(sp->name, s);
    sp->type = t;
    sp->u.val = d;
    sp->next = symlist;
    symlist = sp;
    return sp;
}

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

void fpecatch() { execerror("floating point exception", (const char*)0); }

// yylex
int yylex(void) {
    int c;

    while ((c = getchar()) == ' ' || c == '\t')
        ;
    if (c == EOF)
        return 0;
    if (c == '.' || isdigit(c)) {
        ungetc(c, stdin);
        scanf("%lf", &yylval.val);
        return NUMBER;
    }
    if (isalpha(c)) {
        Symbol* s;
        char sbuf[100], *p = sbuf;
        do {
            *p++ = c;
        } while ((c = getchar()) != EOF && isalnum(c));
        ungetc(c, stdin);
        *p = '\0';
        if ((s = lookup(sbuf)) == 0) {
            s = install(sbuf, UNDEF, 0.0);
        }
        yylval.sym = s;
        return s->type == UNDEF ? VAR : s->type;
    }
    if (c == '\n')
        lineno++;
    return c;
}
