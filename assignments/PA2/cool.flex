/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
// #define MAX_STR_CONST 10
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */



%}

%x COND_MULTILINE_COMMENT COND_SINGLELINE_COMMENT
%x COND_TYPEID
%x COND_STR_CONST COND_STR_TOO_LONG
%x COND_UNKNOWN_TOKEN

/*
 * Define names for regular expressions here.
 */

DIGIT               [0-9]
BLANK               [ \n\b\t\f]
/*EOF                 <<EOF>>*/
/*
 * Keywords
 */
CLASS               class
ELSE                else
FALSE               f[aA][lL][sS][eE]
FI                  fi+
IF                  if+
IN                  in+
INHERITS            inherits+
ISVOID              isvoid+
LET                 let+
LOOP                loop+
POOL                pool+
THEN                then+
WHILE               while+
CASE                case+
ESAC                esac+
NEW                 new+
OF                  of+
NOT                 not+
TRUE                t[rR][uU][eE]

DARROW              =>
INT_CONST           {DIGIT}+
BOOL_CONST          (true|false)
REGEX_TYPEID              [A-Z][0-9a-zA-Z_]*
REGEX_OBJECTID            [a-z][0-9a-zA-Z_]*
REGEX_ASSIGN              <-
REGEX_LE                  <=
REGEX_ERROR               .*
START_MULTILINE_COMMENT       \(\*
COMMENT_STR         [^\*\)]*
END_MULTILINE_COMMENT       \*\)
START_SINGLELINE_COMMENT      --
END_SINGLELINE_COMMENT      \n

%%

 /*
  *  Nested comments
  */

{START_MULTILINE_COMMENT} {
    BEGIN(COND_MULTILINE_COMMENT);
}

{END_MULTILINE_COMMENT} {
    cool_yylval.error_msg = "Unmatched \*\)";
    BEGIN(INITIAL);
    return ERROR;
}

<COND_MULTILINE_COMMENT>[^*\n]*                    /* Remove anything except "*" and "\n" */
<COND_MULTILINE_COMMENT>\*[^*\)\n]*                 /* Remove "*" without ")" */
<COND_MULTILINE_COMMENT>\n {curr_lineno++;}        /* Line count */

<COND_MULTILINE_COMMENT>{END_MULTILINE_COMMENT} {
    BEGIN(INITIAL);
}
<COND_MULTILINE_COMMENT><<EOF>> {
    cool_yylval.error_msg = "Encountered EOF in \n multi-line comment";
    BEGIN(INITIAL);
    return ERROR;
}

{START_SINGLELINE_COMMENT} {
    BEGIN(COND_SINGLELINE_COMMENT);
}

<COND_SINGLELINE_COMMENT>[^\n]*
<COND_SINGLELINE_COMMENT>{END_SINGLELINE_COMMENT} {
    curr_lineno++;
    BEGIN(INITIAL);
}
<COND_SINGLELINE_COMMENT><<EOF>> {
    BEGIN(INITIAL);
    curr_lineno++;
}


 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
{CLASS}         { BEGIN(COND_TYPEID); return (CLASS);}
{INHERITS}      { BEGIN(COND_TYPEID); return (INHERITS);}
\:               {BEGIN(COND_TYPEID); return ':';}
{NEW}           {BEGIN(COND_TYPEID);return (NEW);} 
\@               {BEGIN(COND_TYPEID);return '@';}


<COND_TYPEID>{BLANK}

<COND_TYPEID>{REGEX_TYPEID} {
    cool_yylval.symbol = stringtable.add_string(yytext);
    BEGIN(INITIAL);
    return TYPEID;
}

{ELSE}          {return (ELSE);}
{FI}            {return (FI);} 
{IF}            {return (IF);} 
{IN}            {return (IN);} 
{ISVOID}        {return (ISVOID);}
{LET}           {return (LET);}
{LOOP}          {return (LOOP);}
{POOL}          {return (POOL);} 
{THEN}          {return (THEN);} 
{WHILE}         {return (WHILE);} 
{CASE}          {return (CASE);} 
{ESAC}          {return (ESAC);} 
{OF}            {return (OF);} 
{NOT}           {return (NOT);} 
\<-              {return ASSIGN;}
\+               {return '+';}
\/               {return '/';}
\-               {return '-';}
\*               {return '*';}
\=               {return '=';}
\<               {return '<';}
\<=              {return LE;}
\.               {return '.';}
\~               {return '~';}
\,               {return ',';}
\;               {return ';';}
\(               {return '(';}
\)               {return ')';}
\{               {return '{';}
\}               {return '}';}
<INITIAL>{DIGIT}+ {
    cool_yylval.symbol = inttable.add_string(yytext);
    return INT_CONST;
}



 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
<INITIAL>\" {
    BEGIN(COND_STR_CONST);
    string_buf_ptr = string_buf;
}

<COND_STR_CONST>\0 {
    *string_buf_ptr = '\0';
    cool_yylval.error_msg = "Encountered \\0 in string\n";
    return ERROR;
}

<COND_STR_CONST>[^\\\"\0\n]+ {
    /* Store it */
    // printf("Current buffersize: %d, yytext len: %d\n", (string_buf_ptr - string_buf), strlen(yytext));
    if(strlen(yytext) + (string_buf_ptr - string_buf) > MAX_STR_CONST) {
        printf("Set too long state\n");
        BEGIN(COND_STR_TOO_LONG);
    } else {
        strcpy(string_buf_ptr, yytext);
        string_buf_ptr += strlen(yytext);
    }
}

<COND_STR_CONST>\\. {
    /* Store the \b \t \f and \n */
    if(1 + (string_buf_ptr - string_buf) > MAX_STR_CONST) {
        BEGIN(COND_STR_TOO_LONG);
    } else {
        switch(yytext[1]) {
            case 'b': *string_buf_ptr++ = '\b'; break;
            case 't': *string_buf_ptr++ = '\t'; break;
            case 'f': *string_buf_ptr++ = '\f'; break;
            case 'n': *string_buf_ptr++ = '\n'; break;
            default: *string_buf_ptr++ = yytext[1]; break;
        }
    }
}

<COND_STR_CONST>\\\n {
    if(1 + (string_buf_ptr - string_buf) > MAX_STR_CONST) {
        BEGIN(COND_STR_TOO_LONG);
    } else {
        *string_buf_ptr++ = '\n'; break;
        curr_lineno++;
    }
}

<COND_STR_TOO_LONG>(.|\n)* {
    cool_yylval.error_msg = "String too long";
    BEGIN(INITIAL);
    return ERROR;
}

<COND_STR_CONST>\" {
    BEGIN(INITIAL);
    cool_yylval.symbol = stringtable.add_string(string_buf, string_buf_ptr - string_buf);
    return STR_CONST;
}

<COND_STR_CONST><<EOF>> {
    *string_buf_ptr = '\0';
    cool_yylval.error_msg = "Encountered EOF in string\n";
    return ERROR;
}
{TRUE}|{FALSE} {
    cool_yylval.boolean = yytext[0] == 't';
    return BOOL_CONST;
}
{REGEX_OBJECTID} {
    cool_yylval.symbol = stringtable.add_string(yytext);
    return OBJECTID;
}


[ \b\t\f]
\n curr_lineno++;

. {
    BEGIN(COND_UNKNOWN_TOKEN);
    char errorMsg[] = "Unknown token";
    sprintf(string_buf, "Line %d: %s \'%s", curr_lineno, errorMsg, yytext);
}

<COND_UNKNOWN_TOKEN>[^ \b\t\f\n]* {
    if (strlen(yytext) + strlen(string_buf) + 2 <= MAX_STR_CONST) {
        strcat(string_buf, yytext);
    }
    strcat(string_buf, "\'");
    cool_yylval.error_msg = string_buf;
    BEGIN(INITIAL);
    return ERROR;
}

<COND_UNKNOWN_TOKEN>. {
    strcat(string_buf, "\'");
    cool_yylval.error_msg = string_buf;
    BEGIN(INITIAL);
    return ERROR;
}


%%
