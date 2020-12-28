#pragma once
#include <ctype.h>
#include <setjmp.h>
#include <signal.h>
#include <stdio.h>

typedef struct Symbol {
    char* name;
    short type; // VAR, BLTIN, UNDEF
    union {
        double val;      // if VAL
        double (*ptr)(); // if BLTIN
    } u;
    struct Symbol* next;
} Symbol;

// symbol
Symbol *install(), *lookup();

// code generation
typedef union Datum {
    double val;
    Symbol* sym;
} Datum;

extern Datum pop();
typedef int (*Inst)();
#define STOP (Inst)0

extern void initcode();
extern Inst* code(Inst f);
extern void execute(Inst* p);

extern Inst prog[];
extern int eval();
extern int add();
extern int sub();
extern int mul();
extern int _div();
extern int negate();
extern int power();
extern int mod();
extern int assign();
extern int bltin();
extern int varpush();
extern int constpush();
extern int print();

#define code2(c1, c2)                                                          \
    code(c1);                                                                  \
    code(c2)
#define code3(c1, c2, c3)                                                      \
    code(c1);                                                                  \
    code(c2);                                                                  \
    code(c3)

// init
void init();

// util
extern jmp_buf begin;
extern char* progname;
extern int lineno;

char* emalloc();
void execerror(const char* msg, const char* t);
void warning(const char* s, const char* t);
void fpecatch();

void yyerror(const char* s);
int yylex(void);
