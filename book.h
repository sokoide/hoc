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
// init
void init();
// util
extern jmp_buf begin;
extern char* progname;
extern int lineno;

int yylex(void);
void yyerror(const char* s);
void execerror(const char* msg, const char* t);
void warning(const char* s, const char* t);
void fpecatch();
