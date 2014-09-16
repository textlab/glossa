%{
/* 
 *  IMS Open Corpus Workbench (CWB)
 *  Copyright (C) 1993-2006 by IMS, University of Stuttgart
 *  Copyright (C) 2007-     by the respective contributers (see file AUTHORS)
 * 
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the
 *  Free Software Foundation; either version 2, or (at your option) any later
 *  version.
 * 
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 *  Public License for more details (in the file "COPYING", or available via
 *  WWW at http://www.gnu.org/copyleft/gpl.html).
 */


#include <sys/time.h>
#include <sys/resource.h>
#include <stdio.h>
#include <string.h>
#include <limits.h>
#include <assert.h>
#include <stdarg.h>
#include <stdlib.h>

#include "../cl/globals.h"
#include "../cl/special-chars.h"
#include "../cl/attributes.h"
#include "../cl/macros.h"

#include "cqp.h"
#include "options.h"
#include "ranges.h"
#include "symtab.h"
#include "treemacros.h"
#include "tree.h"
#include "eval.h"
#include "corpmanag.h"
#include "regex2dfa.h"
#include "builtins.h"
#include "groups.h"
#include "targets.h"
#include "attlist.h"
#include "concordance.h"
#include "output.h"
#include "print-modes.h"
#include "variables.h"

#include "parse_actions.h"

/* CQPserver user authentication */
#include "../CQi/auth.h"

/* macro expansion */
#include "macro.h"
 


/* ============================================================ YACC IF */

extern int yychar;

extern int yylex(void);

void yyerror (char *s)
{
  cqpmessage(Error, "CQP Syntax Error: %s\n\t%s <--", s, QueryBuffer);
  generate_code = 0;
}

void warn_query_lock_violation(void) {
  if (which_app != cqpserver)
    fprintf(stderr, "WARNING: query lock violation attempted\n");
  query_lock_violation++;       /* this is for the CQPserver */
}

/* ============================================================ */

#define SYNCHRONIZE

void
synchronize(void)
{
#if defined(SYNCHRONIZE)
  int macro_status;

  /* delete macro buffers & disable macro expansion while sync'ing */
  delete_macro_buffers(1); /* print stack trace on STDERR */
  macro_status = enable_macros;
  enable_macros = 0;

  if (cqp_input_string != NULL) {
    fprintf(stderr, "Synchronizing to end of line ... \n");
    while (!(yychar <= 0))
      yychar = yylex();
  }
  else {
    fprintf(stderr, "Synchronizing until next ';'...\n");
    while (!(yychar <= 0 || yychar == ';'))
      yychar = yylex();
  }

  enable_macros = macro_status; /* reset enable_macros to previous value */
#endif
}

#define YYERROR_VERBOSE

%}

%union {
  Evaltree           evalt;
  Constrainttree     boolt;
  enum b_ops         boolo;
  int                ival;
  double             fval;
  int                index;
  char              *strval;
  CorpusList        *cl;

  struct {
    int a, b;
  } intpair;

  Context            context;
  ActualParamList   *apl;

  enum ctxtdir       direction;

  struct Redir       redir;

  struct InputRedir  in_redir;

  struct {
    int ok;
    int ival;
    char *cval;
  }                  varval;

  struct {
    FieldType field;
    int inclusive;
  }                  base;

  struct {
    char *variableValue;
    char operator;
  }                  varsetting;

  struct {
    int mindist;
    int maxdist;
  }                  Distance;

  struct {
    FieldType anchor;
    int offset;
  }                  Anchor;

  struct {
    FieldType anchor1;
    int offset1;
    FieldType anchor2;
    int offset2;
  }                  AnchorPair;

  struct {
    char *name;
    int flags;
  }                  AttributeSpecification;

  RangeSetOp         rngsetop;

  SortClause         sortclause;

  FieldType          field;

  SearchStrategy     search_strategy;

  TabulationItem     tabulation_item;
}

%token <strval> ID QID LABEL STRING FLAG TAGSTART TAGEND VARIABLE IPAddress IPSubnet
%token <ival> INTEGER
%token <fval> FLOAT
%token <field> FIELD FIELDLABEL ANCHORTAG ANCHORENDTAG
%token <search_strategy> SEARCH_STRATEGY

%token TAB_SYM
%token CAT_SYM
%token DEFINE_SYM
%token DIFF_SYM
%token DISCARD_SYM
%token EXPAND_SYM
%token EXIT_SYM
%token FLAT_SYM
%token INTER_SYM
%token JOIN_SYM
%token SUBSET_SYM
%token LEFT_SYM
%token RIGHT_SYM
%token SAVE_SYM
%token SCATTER_SYM
%token SHOW_SYM
%token CD_SYM
%token TO_SYM
%token WITHIN_SYM
%token SET_SYM
%token EXEC_SYM
%token CUT_SYM
%token OCCURS_SYM
%token INFO_SYM
%token GROUP_SYM
%token WHERE_SYM
%token ESCAPE_SYM

%token MEET_SYM
%token UNION_SYM
%token MU_SYM

%token SORT_SYM
%token COUNT_SYM
%token ASC_SYM
%token DESC_SYM
%token REVERSE_SYM
%token BY_SYM
%token FOREACH_SYM
%token ON_SYM
%token YES_SYM
%token OFF_SYM
%token NO_SYM
%token SLEEP_SYM
%token REDUCE_SYM
%token MAXIMAL_SYM

%token WITH_SYM
%token WITHOUT_SYM
%token DELETE_SYM

%token SIZE_SYM
%token DUMP_SYM
%token UNDUMP_SYM
%token TABULATE_SYM

%token NOT_SYM
%token CONTAINS_SYM
%token MATCHES_SYM

%token GCDEL             /* '::' */
%token APPEND            /* '>>' */
%token LET               /* '<=' */
%token GET               /* '>=' */
%token NEQ               /* '!=' */
%token IMPLIES           /* '->' */
%token RE_PAREN          /* 'RE(' (for: [lemma = RE($var)]) */
%token EOL_SYM           /* '.EOL.' */
%token ELLIPSIS          /* '..' or '...' */

%token MATCHALL                 /* [] */
%token LCSTART                  /* [: */
%token LCEND                    /* :] */
%token LCMATCHALL               /* [::] */

%token PLUSEQ
%token MINUSEQ

%token UNLOCK_SYM               /* unlock 'QueryLock' mode */

%token USER_SYM                 /* CQPserver user authentication */
%token HOST_SYM

%token UNDEFINED_MACRO          /* dummy symbol which forces parse error when an undefined macro is encountered */
%token MACRO_SYM

%token RANDOMIZE_SYM

%token FROM_SYM
%token INCLUSIVE_SYM
%token EXCLUSIVE_SYM

%token NULL_SYM           /* 'NULL' */


  /* operator precedence */
%left IMPLIES
%left '|'
%left '*' '+' '&'
%right '!'

%type <evalt> RegWordfExpr RegWordfTerm RegWordfFactor RegWordfPower
%type <evalt> Repeat MUStatement MeetStatement UnionStatement
%type <ival> OptNumber OptInteger OptMaxNumber OptionalFlag CutStatement OptNot OptKeep
%type <ival> OptExpansion OptPercent InclusiveExclusive
%type <index> NamedWfPattern WordformPattern XMLTag AnchorPoint
%type <evalt> TabPatterns TabOtherPatterns
%type <boolt> GlobalConstraint ExtConstraint LookaheadConstraint BoolExpr
%type <boolt> RelExpr RelLHS RelRHS FunctionCall
%type <boolo> RelOp
%type <strval> LabelReference OptRefId
%type <context> Description MeetContext OptDistance
%type <direction> OptDirection
%type <redir> OptionalRedir Redir
%type <in_redir> OptionalInputRedir InputRedir
%type <base> OptBase
%type <varsetting> VariableValueSpec

%type <cl> CorpusCommand UnnamedCorpusCommand CID OptionalCID 
%type <cl> CYCommand Query AQuery CorpusSetExpr SubsetExpr MUQuery 
%type <cl> StandardQuery TABQuery

%type <ival> OptTargetSign
%type <apl> FunctionArgList SingleArg
%type <varval> VarValue
%type <rngsetop> SetOp

/* -------------------- Tabulate */

%type <tabulation_item> TabulationItem
%type <AnchorPair> TabulationRange
%type <AttributeSpecification> OptAttributeSpec

/* -------------------- Sort */

%type <sortclause> OptionalSortClause SortClause
%type <AnchorPair> SortBoundaries
%type <ival> SortDirection
%type <ival> OptReverse

/* -------------------- Delete */

%type <Distance> LineRange

/* -------------------- matches & contains etc. */
%type <ival> MvalOp OptionalNot RegexpOp

/* -------------------- macros */
%type <strval> MultiString

/* -------------------- field types */
%type <field>  OptionalFIELD
%type <Anchor> Anchor;

%type <ival> OptWithTargetKeyword OptAscending

%%

/* ============================================================ RULES */

line:                                  { prepare_parse(); }
                  command              { if (generate_code)
                                           addHistoryLine();
                                         resetQueryBuffer();
                                         YYACCEPT; }
                | ';'                 { YYACCEPT; }  /* empty command */
                | /* eps */           { YYACCEPT; }
                ;

command:                                 { prepare_input(); }
                  CorpusCommand ';'      { after_CorpusCommand($2); }
                | UNLOCK_SYM INTEGER     /* unlock 'QueryLock' mode */
                    { 
                      if ($2 == query_lock) {
                        query_lock = 0;
                      }
                      else {
                        fprintf(stderr, "ALERT! Query lock violation.\n");
                        printf("\n"); /* so CQP.pm won't block -- should no longer be needed after switching to .EOL. mechanism */
                        exit(1);
                      }
                    } ';'
                | EOLCmd ';'    /* .EOL. must be allowed in query lock mode */
                |                        {if (query_lock) {warn_query_lock_violation(); YYABORT;} }
                  InteractiveCommand ';' { }
                |                        {if (query_lock) {warn_query_lock_violation(); YYABORT;} }
                  EXIT_SYM               { exit_cqp++; }
                | error                  { /* in case of syntax errors, don't save 
                                              history file */
                                           synchronize();
                                           resetQueryBuffer();
                                           YYABORT; /* Oli did this:   yyerrok; */
                                           /* but we don't want to continue processing a line, when part of it failed */
                                         }  
                ;

CorpusCommand:  UnnamedCorpusCommand    { $$ = $1; }
                | ID '=' UnnamedCorpusCommand
                                        { $$ = in_CorpusCommand($1, $3); }
                ;

UnnamedCorpusCommand:
                  CYCommand ReStructure { $$ = in_UnnamedCorpusCommand($1); }
                ;

CYCommand:        CID                   { if (query_lock) {warn_query_lock_violation(); YYABORT;} $$ = ActivateCorpus($1); }
                | CorpusSetExpr         { $$ = after_CorpusSetExpr($1); }
                |                       { prepare_Query(); }
                  Query                 { $$ = after_Query($2); }
                ;

InteractiveCommand:       Showing
                        | Cat
                        | Saving
                        | Discard
                        | Delete
                        | Reduction
                        | OptionSetCmd
                        | VarDefCmd
                        | VarPrintCmd
                        | ExecCmd
                        | InfoCmd
                        | GroupCmd
                        | SortCmd
                        | SleepCmd
                        | SizeCmd
                        | DumpCmd
                        | UndumpCmd
                        | TabulateCmd
                        | AuthorizeCmd
                        | Macro
                        | ShowMacro
                        | RandomizeCmd
                        | ESCAPE_SYM OtherCommand
                ;


/* print special code ``-::-EOL-::-'' marking end-of-command in child mode */
EOLCmd:           EOL_SYM               { printf("-::-EOL-::-\n"); fflush(stdout); }
                ;

Cat:              CAT_SYM OptionalCID
                          OptionalRedir       { do_cat($2, &($3), 0, -1); } 
                  /* cat entire subcorpus */
                | CAT_SYM OptionalCID OptFROM INTEGER OptTO INTEGER
                          OptionalRedir       { do_cat($2, &($7), $4, $6); } 
                  /* cat part of subcorpus (matches #$3 .. #$4) */
                | CAT_SYM CorpusSetExpr OptionalRedir   
                          { if (generate_code) 
                              do_cat($2, &($3), 0, -1);
                            drop_temp_corpora();
                          }
                ;

Saving:           SAVE_SYM OptionalCID
                           OptionalRedir { do_save($2, &($3)); cl_free($3.name); }
                ;

OptionalRedir:    Redir
                | /* epsilon */         { $$.name = (char *)NULL;
                                          $$.mode = (char *)NULL;
                                          $$.stream = stdout;
                                          $$.is_pipe = 0;
                                        }
                ;

Redir:            '>' STRING            { $$.name = $2;
                                          $$.mode = "w";
                                          $$.stream = NULL;
                                          $$.is_pipe = 0;
                                        }
                | APPEND STRING         { $$.name = $2;
                                          $$.mode = "a";
                                          $$.stream = NULL;
                                          $$.is_pipe = 0;
                                        }
                ;


OptionalInputRedir:    InputRedir
                | /* epsilon */         { $$.name = (char *)NULL;
                                          $$.stream = stdin;
                                          $$.is_pipe = 0;
                                        }
                ;

InputRedir:       '<' STRING            { $$.name = $2;
                                          $$.stream = NULL;
                                          $$.is_pipe = 0;
                                        }
                ;

Showing:          SHOW_SYM              { 
                                          show_corpora_files(UNDEF);
                                        }
                | SHOW_SYM ID           { 
                                          if (strncasecmp($2, "var", 3) == 0) {
                                            do_PrintAllVariables();
                                          }
                                          else if ((strncasecmp($2, "sys", 3) == 0) || (strncasecmp($2, "corp", 4) == 0)) {
                                            show_corpora_files(SYSTEM);
                                          }
                                          else if ((strncasecmp($2, "sub", 3) == 0) || (strcasecmp($2, "named") == 0) || (strcasecmp($2, "queries") == 0)) {
                                            show_corpora_files(SUB);    
                                          }
                                          else {
                                            cqpmessage(Error, "show what?");
                                          }
                                        }
                | SHOW_SYM 
                  AttributeSelections   /* the actual work is done there */
                | SHOW_SYM
                  CD_SYM                { PrintContextDescriptor(&CD); }
                ;

AttributeSelections:    
                  AttributeSelections 
                  AttributeSelection    /* i.e. list of any number of selections */
                | AttributeSelection
                ;

AttributeSelection:
                  '+' ID                        { do_attribute_show($2, 1); }
                | '-' ID                        { do_attribute_show($2, 0); }
                ;

CorpusSetExpr:  SetOp CID CID           { if (query_lock) {warn_query_lock_violation(); YYABORT;} $$ = do_setop($1, $2, $3); }
                | SubsetExpr
                ;

SetOp:            JOIN_SYM              { $$ = RUnion; }
                | UNION_SYM             { $$ = RUnion; }
                | INTER_SYM             { $$ = RIntersection; }
                | DIFF_SYM              { $$ = RDiff; }
                ;

SubsetExpr:     SUBSET_SYM
                OptionalCID
                WHERE_SYM 
                FIELDLABEL              { 
                                          do_start_timer();
                                          prepare_do_subset($2, $4);  
                                          next_environment();   /* create environment for pattern compilation (will be freed in prepare_input() before next command) */
                                        }
                ExtConstraint           { 
                                          if (generate_code) {
                                            $$ = do_subset($4, $6);
                                            do_timing("Subset computed");
                                          }
                                          else 
                                            $$ = NULL;
                                        }
                ;


Discard:        DISCARD_SYM DiscArgs     {  }
                ;

DiscArgs:       DiscArgs CID           { if ($2)
                                            dropcorpus($2);
                                        }
                | CID                   { if ($1)
                                            dropcorpus($1);
                                        }
                ;

VarPrintCmd:    SHOW_SYM VARIABLE { do_PrintVariableValue($2); 
                                    free($2);
                                  }
                ;

VarDefCmd:      DEFINE_SYM
                VARIABLE
                VariableValueSpec { do_SetVariableValue($2, 
                                                        $3.operator, 
                                                        $3.variableValue); 
                                    free($2);
                                    free($3.variableValue);
                                  }
                |
                DEFINE_SYM VARIABLE PLUSEQ VARIABLE {
                                    do_AddSubVariables($2, /*add*/1, $4);
                                    free($2);
                                    free($4);
                                  }
                |
                DEFINE_SYM VARIABLE MINUSEQ VARIABLE {
                                    do_AddSubVariables($2, /*sub*/0, $4);
                                    free($2);
                                    free($4);
                                  }
                |
                DEFINE_SYM VARIABLE '=' VARIABLE {
                                    char *temp = cl_strdup("");
                                    do_SetVariableValue($2, '=', temp);         /* cheap trick, this is :o) */
                                    free(temp);
                                    do_AddSubVariables($2, /*add*/1, $4);
                                    free($2);
                                    free($4);
                                  }
                ;

VariableValueSpec:  
                  '<' STRING { $$.variableValue = $2; $$.operator = '<'; }
                | '=' STRING { $$.variableValue = $2; $$.operator = '='; }
                | PLUSEQ STRING { $$.variableValue = $2; $$.operator = '+'; }
                | MINUSEQ STRING { $$.variableValue = $2; $$.operator = '-'; }
                ;

OptionSetCmd:   SET_SYM ID VarValue     { char *msg;

                                          if ($3.cval != NULL && $3.ival >= 0) {
                                            msg = set_context_option_value($2, $3.cval, $3.ival);
                                          }
                                          else if ($3.cval != NULL) {
                                            /* get rid of quotes at start and end of value */
                                            /* -- removed because quotes should be stripped by lexer ({string} rule in parser.l) */
                                            /*
                                            if (($3.cval[0] == '"') && ($3.cval[strlen($3.cval)-1] == '"')
                                                || ($3.cval[0] == '\'') && ($3.cval[strlen($3.cval)-1] == '\'') ) {
                                              

                                              $3.cval[strlen($3.cval)-1] = '\0';
                                              $3.cval = $3.cval + 1;
                                            }
                                            */
                                            msg = set_string_option_value($2, $3.cval);
                                          }
                                          else
                                            msg = set_integer_option_value($2, $3.ival);

                                          if (msg != NULL)
                                            cqpmessage(Warning,
                                                       "Option set error:\n%s", msg);
                                        }
              | SET_SYM ID              { int opt;

                                          if ((opt = find_option($2)) >= 0)
                                            print_option_value(opt);
                                          else
                                            cqpmessage(Warning,
                                                     "Unknown option: ``%s''\n", $2);
                                        }
              | SET_SYM                 {
                                          print_option_values();
                                        }
              | SET_SYM CID FIELD FIELD { do_set_target($2, $3, $4); }
              | SET_SYM CID FIELD NULL_SYM { do_set_target($2, $3, NoField); }  /* erase field */
              | SET_SYM CID FIELD SEARCH_STRATEGY {
                                          if (generate_code) {
                                            old_query_corpus = query_corpus;
                                            query_corpus = $2;  /* set query_corpus for compiling the ExtConstraint pattern */
                                            next_environment(); /* create environment for pattern compilation (will be freed in prepare_input() before next command) */
                                            do_start_timer();
                                          }
                                        }  
                ExtConstraint 
                WITHIN_SYM OptDirection
                OptNumber ID OptBase    {
                                          do_set_complex_target($2, $3, $4, $6, $8, $9, $10, $11.field, $11.inclusive);
                                          if (generate_code) 
                                            do_timing("``set target ...'' completed");
                                        }
              ;

OptBase:        FROM_SYM FIELD InclusiveExclusive  {
                                          /* from (match|keyword|target) [inclusive|exclusive] */
                                          $$.field = $2;
                                          $$.inclusive = $3;
                                        }
              | /* epsilon */           { 
                                          $$.field = MatchField;
                                          $$.inclusive = 0;
                                        }
              ;

InclusiveExclusive: INCLUSIVE_SYM       { $$ = 1; }
              | EXCLUSIVE_SYM           { $$ = 0; }
              | /* epsilon */           { $$ = 0; /* default is exclusive */ }
              ;

VarValue:        INTEGER                { $$.ival = $1;
                                          $$.cval = NULL;
                                          $$.ok = 1;
                                        }
               | STRING                 { $$.ival = -1;
                                          $$.cval = $1;
                                          $$.ok = 1;
                                        }
               | ID                     {
                                          $$.ival = -1;
                                          $$.cval = $1;
                                          $$.ok = 1;
                                        }
               | ON_SYM                 { $$.ival = 1; $$.cval = NULL; $$.ok = 1; }
               | YES_SYM                { $$.ival = 1; $$.cval = NULL; $$.ok = 1; }
               | OFF_SYM                { $$.ival = 0; $$.cval = NULL; $$.ok = 1; }
               | NO_SYM                 { $$.ival = 0; $$.cval = NULL; $$.ok = 1; }
               | INTEGER ID             {
                                          $$.ival = $1;
                                          $$.cval = $2;
                                          $$.ok = 1;
                                        }
               ;

ExecCmd:          EXEC_SYM STRING       { do_exec($2); }
                ;

InfoCmd:          INFO_SYM CID          { do_info($2); }
                | INFO_SYM              { do_info(current_corpus); }
                ;

GroupCmd:       GROUP_SYM CID Anchor ID BY_SYM Anchor ID 
                  CutStatement OptExpansion OptionalRedir
                                { 
                                  do_group($2, $3.anchor, $3.offset, $4, $6.anchor, $6.offset, $7, $8, $9, &($10)); 
                                  cl_free($10.name);
                                }
              | GROUP_SYM CID Anchor ID FOREACH_SYM Anchor ID 
                  CutStatement OptExpansion OptionalRedir
                                { 
                                  do_group($2, $3.anchor, $3.offset, $4, $6.anchor, $6.offset, $7, $8, $9, &($10));
                                  cl_free($10.name);
                                }
              | GROUP_SYM CID Anchor ID 
                  CutStatement OptExpansion OptionalRedir
                                { 
                                  do_group2($2, $3.anchor, $3.offset, $4, $5, $6, &($7));
                                  cl_free($7.name);
                                }
              ;

/* the 'expand' flag is not implemented in the group command */
OptExpansion:    EXPAND_SYM { $$ = 1; } 
               | /* epsilon */ { $$ = 0; }
               ;

/* ================================================== Tabulate */

TabulateCmd:     TABULATE_SYM CID 
                   { free_tabulation_list(); }
                 TabulationItems OptionalRedir
                   { print_tabulation($2, 0, INT_MAX, &($5)); cl_free($5.name); }
               | TABULATE_SYM CID
                   { free_tabulation_list(); }
                 OptFROM INTEGER OptTO INTEGER TabulationItems OptionalRedir
                   { print_tabulation($2, $5, $7, &($9)); cl_free($9.name); }
               ;

TabulationItems: TabulationItem
                   { append_tabulation_item($1); }
               | TabulationItems ',' TabulationItem
                   { append_tabulation_item($3); }
               ;

TabulationItem:  TabulationRange OptAttributeSpec
                   {
                     $$ = new_tabulation_item();
                     $$->attribute_name = $2.name;
                     $$->flags   = $2.flags;
                     $$->anchor1 = $1.anchor1;
                     $$->offset1 = $1.offset1;
                     $$->anchor2 = $1.anchor2;
                     $$->offset2 = $1.offset2;
                   }
               ;

TabulationRange:   Anchor 
                     { $$.anchor1 = $$.anchor2 = $1.anchor; $$.offset1 = $$.offset2 = $1.offset; }
                 | Anchor OptELLIPSIS Anchor
                     { $$.anchor1 = $1.anchor; $$.offset1 = $1.offset;
                       $$.anchor2 = $3.anchor; $$.offset2 = $3.offset; } 
                 ;

OptAttributeSpec:    ID OptionalFlag
                       { $$.name = $1; $$.flags = $2; }
                   | /* eps */
                       { $$.name = NULL; $$.flags = 0; }
                   ;

/* ================================================== Sorting */

/* 'sort' <corpus> 'by' <attribute> [<flags>] [ <anchor>[:<offset>] | 'from' <a1>[:<o1>] 'to' <a2>[:<o2>] ] ['asc'|'desc'] ['reverse'] */
/* 'count' ... */
/* 'sort' <corpus>;  ->  "unsort", i.e. reset to cpos order */

SortCmd:        SORT_SYM OptionalCID OptionalSortClause
                { 
                  int ok;
                  if ($2 && generate_code) {
                    do_start_timer();
                    ok = SortSubcorpus($2, $3, 0, NULL);
                    FreeSortClause($3);
                    do_timing("Query result sorted");
                    if (autoshow && ok && ($2->size > 0))
                      catalog_corpus($2, NULL, 0, -1, GlobalPrintMode);
                  }
                }
              | SORT_SYM OptionalCID RANDOMIZE_SYM OptInteger
                {
                  int ok;
                  if ($2 && generate_code) {
                    do_start_timer();
                    ok = SortSubcorpusRandomize($2, $4);
                    do_timing("Query result randomized");
                    if (autoshow && ok && ($2->size > 0))
                      catalog_corpus($2, NULL, 0, -1, GlobalPrintMode);
                  }
                }
              | COUNT_SYM OptionalCID SortClause CutStatement OptionalRedir
                { 
                  int ok;
                  if ($2 && generate_code) {
                    ok = SortSubcorpus($2, $3, ($4 >= 1) ? $4 : 1, &($5));
                    FreeSortClause($3);
                    cl_free($5.name);
                  }
                }
              ;

OptionalSortClause: 
                SortClause              { $$ = $1; }
              | /* eps */               { $$ = NULL; }
              ;

SortClause:     BY_SYM ID OptionalFlag SortBoundaries SortDirection OptReverse
                {
                  if (generate_code) {
                    $$ = cl_malloc(sizeof(SortClauseBuffer));
                    $$->attribute_name  = $2;
                    $$->flags           = $3;
                    $$->anchor1         = $4.anchor1;
                    $$->offset1         = $4.offset1;
                    $$->anchor2         = $4.anchor2;
                    $$->offset2         = $4.offset2;
                    $$->sort_ascending  = $5;
                    $$->sort_reverse    = $6;
                  }
                  else
                    $$ = NULL;
                }
              ;

SortBoundaries: OptON Anchor { $$.anchor1 = $$.anchor2 = $2.anchor; $$.offset1 = $$.offset2 = $2.offset; }
              | OptON Anchor OptELLIPSIS Anchor
                            { $$.anchor1 = $2.anchor; $$.offset1 = $2.offset;
                              $$.anchor2 = $4.anchor; $$.offset2 = $4.offset; } 
              | /* eps */
                            { $$.anchor1 = MatchField;    $$.offset1 = 0;
                              $$.anchor2 = MatchEndField; $$.offset2 = 0; }
              ;

SortDirection:  ASC_SYM     { $$ = 1; }
              | DESC_SYM    { $$ = 0; }
              | /* eps */   { $$ = 1; }
              ;

OptReverse:     REVERSE_SYM { $$ = 1; }
              | /* eps */   { $$ = 0; }
              ;

/* ================================================== Deletions */

Reduction:        REDUCE_SYM OptionalCID TO_SYM INTEGER OptPercent
                                        {
                                          do_reduce($2, $4, $5);
                                        }
                | REDUCE_SYM OptionalCID TO_SYM MAXIMAL_SYM MATCHES_SYM
                                        {
                                          RangeSetop($2, RMaximalMatches, NULL, NULL);
                                        }
                | CUT_SYM OptionalCID INTEGER
                                        {
                                          do_cut($2, 0, $3-1);
                                        }
                | CUT_SYM OptionalCID INTEGER INTEGER
                                        {
                                          do_cut($2, $3, $4);
                                        }                                       
                ;
        
OptPercent:       '%'       { $$ = 1; }
                | /* eps */ { $$ = 0; }
                ;

Delete:           DELETE_SYM OptionalCID WITH_SYM FIELD
                                        {
                                          if ($2 && generate_code) {
                                            do_delete_lines($2, $4, SELECTED_LINES); 
                                          }
                                        }
                | DELETE_SYM OptionalCID WITHOUT_SYM FIELD
                                        { 
                                          if ($2 && generate_code) {
                                            do_delete_lines($2, $4, UNSELECTED_LINES); 
                                          }
                                        }
                | DELETE_SYM OptionalCID LineRange
                                        { 
                                          if ($2 && generate_code) {
                                             do_delete_lines_num($2, $3.mindist, $3.maxdist);
                                           }
                                         }
                ;

LineRange:        INTEGER                  { $$.mindist = $1; $$.maxdist = $1; }
                | INTEGER ELLIPSIS INTEGER { $$.mindist = $1; $$.maxdist = $3; }
                ;

/* ================================================== Sleep */

SleepCmd:  SLEEP_SYM INTEGER { do_sleep($2); };

/* ================================================== CQP Server Mode functions: Size & Dump */

SizeCmd:    SIZE_SYM CID OptionalFIELD { do_size($2, $3); }
          | SIZE_SYM VARIABLE { do_printVariableSize($2); free($2); }
          ;

DumpCmd:  
          DUMP_SYM CID OptionalRedir 
            { do_dump($2, 0, INT_MAX, &($3)); cl_free($3.name); }
        | DUMP_SYM CID OptFROM INTEGER OptTO INTEGER OptionalRedir
            { do_dump($2, $4, $6, &($7)); cl_free($7.name); } 
        ;

UndumpCmd: UNDUMP_SYM ID OptWithTargetKeyword OptAscending OptionalInputRedir 
            { do_undump($2, $3, !$4, &($5)); cl_free($5.name); }
        ;

OptAscending:  ASC_SYM    { $$ = 1; }
             | /* eps */  { $$ = 0; }
             ;

OptWithTargetKeyword:
          /* eps */     { $$ = 0; }
        | WITH_SYM FIELD        
          { 
            if ($2 == TargetField) { $$ = 1; }
            else { yyerror("Invalid extension anchor in undump command"); YYABORT; } 
          }
        | WITH_SYM FIELD FIELD
          { 
            if ( (($2 == TargetField) && ($3 == KeywordField))
                 || (($3 == TargetField) && ($2 == KeywordField))
               ) { $$ = 2; }
            else { yyerror("Invalid extension anchor in undump command"); YYABORT; } 
          }
        ;

/* ================================================== Query */

Query:          AQuery 
              | AQuery SORT_SYM OptionalSortClause 
                {
                  if ($1 && $3 && $1->size > 0) {
                    SortSubcorpus($1, $3, 0, NULL);
                    FreeSortClause($3);
                  }
                  $$ = $1;
                }
              ;

AQuery:         StandardQuery
              | MUQuery
              | TABQuery
              ;

StandardQuery:  SearchPattern
                AlignmentConstraints
                CutStatement OptKeep    { $$ = do_StandardQuery($3, $4); }
;

MUQuery:          MU_SYM
                  MUStatement OptKeep CutStatement { $$ = do_MUQuery($2, $3, $4); }
                ;

OptKeep:   '!'                          { $$ = 1; }
          | /* epsilon */               { $$ = 0; }
            ;

SearchPattern:                          { if (generate_code) { CurEnv->match_label = labellookup(CurEnv->labels, "match", LAB_DEFINED, 1); } }
                  RegWordfExpr          { within_gc = 1; 
                                          if (generate_code) { CurEnv->matchend_label = labellookup(CurEnv->labels, "matchend", LAB_DEFINED, 1); } }
                  GlobalConstraint      { within_gc = 0; }
                  SearchSpace           { do_SearchPattern($2, $4); }
                ;

RegWordfExpr:     RegWordfExpr '|' RegWordfTerm
                                        { $$ = reg_disj($1, $3); }
                | RegWordfTerm          { $$ = $1; }
                ;

RegWordfTerm:     RegWordfTerm RegWordfFactor
                                        { $$ = reg_seq($1, $2); }
                | RegWordfFactor        { $$ = $1; }
                ;

RegWordfFactor:   RegWordfPower Repeat { if (generate_code) {
                                           $$ = $2;
                                           $$->node.left = $1;
                                           $$->node.right = NULL;
                                         }
                                         else
                                           $$ = NULL;
                                       }
                | RegWordfPower '*'    { if (generate_code)
                                           NEW_EVALNODE($$, re_repeat, $1, NULL, 0, repeat_inf);
                                         else
                                           $$ = NULL;
                                       }
                | RegWordfPower '+'    { if (generate_code)
                                           NEW_EVALNODE($$, re_repeat, $1, NULL, 1, repeat_inf);
                                         else
                                           $$ = NULL;
                                       }
                | RegWordfPower '?'    { if (generate_code)
                                           NEW_EVALNODE($$, re_repeat, $1, NULL, 0, 1);
                                         else
                                           $$ = NULL;
                                       }
                | RegWordfPower        { $$ = $1; }
                ;

RegWordfPower:    '(' RegWordfExpr ')'  { $$ = $2; }
                 | NamedWfPattern       { if (generate_code)
                                            NEW_EVALLEAF($$, $1);
                                          else
                                            $$ = NULL;
                                        }
                 | XMLTag               { if (generate_code)
                                            NEW_EVALLEAF($$, $1);
                                          else
                                            $$ = NULL;
                                        }
                 | AnchorPoint          { if (generate_code)
                                            NEW_EVALLEAF($$, $1);
                                          else
                                            $$ = NULL;
                                        }
                 ;

Repeat:           '{' INTEGER '}'       { if (generate_code)
                                            NEW_EVALNODE($$, re_repeat, NULL, NULL, $2, $2);
                                          else
                                            $$ = NULL;
                                        }
                | '{' INTEGER ',' OptMaxNumber '}'
                                        { if (generate_code)
                                            NEW_EVALNODE($$, re_repeat, NULL, NULL, $2, $4);
                                          else
                                            $$ = NULL;
                                        }
                ;


AnchorPoint:      ANCHORTAG             { $$ = do_AnchorPoint($1, 0); }
                | ANCHORENDTAG          { $$ = do_AnchorPoint($1, 1); }
                ;

XMLTag:           TAGSTART '>'          { $$ = do_XMLTag($1, 0, 0, NULL, 0); }
                | TAGSTART RegexpOp STRING OptionalFlag '>' 
                                        { $$ = do_XMLTag($1, 0, $2, $3, $4); }
                | TAGEND                { $$ = do_XMLTag($1, 1, 0, NULL, 0); }
                ;

RegexpOp:         MvalOp                { $$ = $1; }
                | NEQ                   { $$ = OP_EQUAL | OP_NOT; }
                | '='                   { $$ = OP_EQUAL; }
                | /* eps */             { $$ = OP_EQUAL; }
                ;

NamedWfPattern: OptTargetSign
                OptRefId
                WordformPattern         { $$ = do_NamedWfPattern($1, $2, $3); }
                ;


OptTargetSign:    '@'                   { $$ = 1; }
                | /* epsilon */         { $$ = 0; }
                ;

OptRefId:         LABEL                 { $$ = $1; }
                | /* epsilon */         { $$ = NULL; }
                ;

WordformPattern:  ExtConstraint         { $$ = do_WordformPattern($1, 0); }
                | LookaheadConstraint   { $$ = do_WordformPattern($1, 1); }
                ;

ExtConstraint:   STRING OptionalFlag  { $$ = do_StringConstraint($1, $2); }
               | VARIABLE             { $$ = NULL;
                                        if (!FindVariable($1)) {
                                          cqpmessage(Error, 
                                                     "%s: no such variable", 
                                                     $1);
                                          generate_code = 0;
                                        }
                                        else {
                                          $$ = do_SimpleVariableReference($1);
                                        }
                                        free($1);
                                      }
               | '[' BoolExpr ']'     { $$ = $2; }
               | MATCHALL             { if (generate_code) {
                                          NEW_BNODE($$);
                                          $$->constnode.type = cnode;
                                          $$->constnode.val  = 1;
                                        }
                                      }
               ;

LookaheadConstraint: LCSTART BoolExpr LCEND  { $$ = $2; }
               | LCMATCHALL           { if (generate_code) {
                                          NEW_BNODE($$);
                                          $$->constnode.type = cnode;
                                          $$->constnode.val  = 1;
                                        }
                                      }
               ;

OptionalFlag:     FLAG                  { int flags, i;
                                          flags = 0;

                                          for (i = 0; $1[i] != '\0'; i++) {
                                            switch ($1[i]) {
                                            case 'c':
                                              flags |= IGNORE_CASE;
                                              break;
                                            case 'd':
                                              flags |= IGNORE_DIAC;
                                              break;
                                            case 'l':
                                              flags = IGNORE_REGEX; /* literal */
                                              break;
                                            default:
                                              cqpmessage(Warning, "Unknown flag %s%c (ignored)", "%", $1[i]);
                                              break;
                                            }
                                          }

                                          /* %l supersedes all others */
                                          if (flags & IGNORE_REGEX) {
                                            if (flags != IGNORE_REGEX) {
                                              cqpmessage(Warning, "%s and %s flags cannot be combined with %s (ignored)",
                                                         "%c", "%d", "%l");
                                            }
                                            flags = IGNORE_REGEX;
                                          }

                                          $$ = flags;
                                        }
                | /* epsilon */         { $$ = 0; }
                ;

GlobalConstraint:    GCDEL BoolExpr    { $$ = $2; }
                   | /* epsilon */     { $$ = NULL; }
                   ;

AlignmentConstraints:
                     AlignmentConstraints
                     ':' ID            { prepare_AlignmentConstraints($3); }
                         OptNot
                         SearchPattern { if (generate_code)
                                           CurEnv->negated = $5;
                                       }
                   | /* epsilon */     { }
                    ;

OptNot:             '!'                { $$ = 1; }
                  | /* epsilon */      { $$ = 0; }
                  ;

SearchSpace:    WITHIN_SYM OptDirection Description
                { if (generate_code) {
                    CurEnv->search_context.direction = $2;
                    CurEnv->search_context.type = $3.type;
                    CurEnv->search_context.size = $3.size;
                    CurEnv->search_context.attrib = $3.attrib;
                  }
                }
              | /* epsilon */           { if (generate_code) {
                                            CurEnv->search_context.type  = word;
                                            CurEnv->search_context.size  = hard_boundary;
                                            CurEnv->search_context.attrib = NULL;
                                          }
                                        }
                ;

CutStatement:   CUT_SYM INTEGER         { $$ = abs($2); }
              | /* epsilon */           { $$ = 0; }
                ;

OptNumber:      INTEGER                 { $$ = $1; }
              | /* epsilon */           { $$ = 1; }
                ;

OptInteger:     INTEGER                 { $$ = $1; }
              | /* epsilon */           { $$ = 0; }
                ;

OptMaxNumber:   INTEGER                 { $$ = $1; }
              | /* epsilon */           { $$ = repeat_inf; }
                ;

ReStructure:    EXPAND_SYM OptDirection
                   TO_SYM Description   { expansion.direction = $2;
                                          expansion.type = $4.type;
                                          expansion.size = $4.size;
                                          expansion.attrib = $4.attrib;
                                        }
              | /* epsilon */           { expansion.direction = leftright;
                                          expansion.type = word;
                                          expansion.size = 0;
                                          expansion.attrib = NULL;
                                        }
                ;

OptDirection:   LEFT_SYM               { $$ = left; }
              | RIGHT_SYM              { $$ = right; }
              | /* epsilon */          { $$ = leftright; }
                ;

Description:    OptNumber ID           { do_Description(&($$), $1, $2); }
              | INTEGER                { do_Description(&($$), $1, NULL); }
                ;

OptionalCID:    CID                     { $$ = $1; }
              | /* epsilon */           { $$ = findcorpus("Last", UNDEF, 0); }
                ;


CID:            ID                      { CorpusList *cl;

                                          cqpmessage(Message, "CID: %s", $1);

                                          if ((cl = findcorpus($1, UNDEF, 1)) == NULL) {
                                            cqpmessage(Error,
                                                       "Corpus ``%s'' is undefined", $1);
                                            generate_code = 0;
                                            $$ = NULL;
                                          }
                                          else if (!access_corpus(cl)) {
                                            cqpmessage(Warning,
                                                       "Corpus ``%s'' can't be accessed", $1);
                                            $$ = NULL;
                                          }
                                          else
                                            $$ = cl;
                                        }
                ;

BoolExpr:     BoolExpr IMPLIES BoolExpr { $$ = bool_implies($1, $3); }
            | BoolExpr '|' BoolExpr { $$ = bool_or($1, $3); }
            | BoolExpr '&' BoolExpr { $$ = bool_and($1, $3); }
            | '(' BoolExpr ')'      { $$ = $2; }
            | '!' BoolExpr          { $$ = bool_not($2); }
            | RelExpr               { $$ = $1; }
            ;

RelExpr:    RelLHS RelOp RelRHS   { $$ = do_RelExpr($1, $2, $3); }
          | RelLHS MvalOp STRING OptionalFlag  /* operators for multi-valued attributes */
              {
                 if ($2 & OP_NOT) {
                   $$ = do_RelExpr($1, cmp_neq, do_mval_string($3, $2, $4));
                 }
                 else {
                   $$ = do_RelExpr($1, cmp_eq,  do_mval_string($3, $2, $4));
                 }
              }
          | RelLHS                { $$ = do_RelExExpr($1); }
          ;

MvalOp:   OptionalNot CONTAINS_SYM  {$$ = OP_CONTAINS | $1;}
        | OptionalNot MATCHES_SYM   {$$ = OP_MATCHES  | $1;}
;       

OptionalNot:   NOT_SYM    {$$ = OP_NOT;}
             | /* eps */  {$$ = 0;}
;

RelLHS:           LabelReference        { $$ = do_LabelReference($1, 0); }  /* label reference "label.att"*/
                | '~' LabelReference    { $$ = do_LabelReference($2, 1); }  /* label reference with auto-delete */ 
                | ID                    { $$ = do_IDReference($1, 0); }  /* simple attribute or bare label */
                | '~' ID                { $$ = do_IDReference($2, 1); }  /* bare label with auto-delete */
                | FIELD { $$ = do_IDReference(cl_strdup(field_type_to_name($1)), 0); } /* bare match and matchend labels */
                | FunctionCall          { $$ = $1; }
                ;

RelRHS:           RelLHS                { $$ = $1; }
                | STRING OptionalFlag   { $$ = do_flagged_string($1, $2); }
                | RE_PAREN VARIABLE ')' OptionalFlag  
                                        { 
                                          $$ = do_flagged_re_variable($2, $4); 
                                        }
                | VARIABLE              { if (generate_code) {
                                            if (!FindVariable($1)) {
                                              cqpmessage(Error, 
                                                         "%s: no such variable", 
                                                         $1);
                                              generate_code = 0;
                                              $$ = NULL;
                                            }
                                            else {
                                              NEW_BNODE($$);
                                              $$->type = var_ref;
                                              $$->varref.varName = $1;
                                            }
                                          }
                                          else
                                            $$ = NULL;
                                        }
                | INTEGER               { if (generate_code) {
                                            NEW_BNODE($$);
                                            $$->type = int_leaf;
                                            $$->leaf.ctype.iconst = $1;
                                          }
                                          else
                                            $$ = NULL;
                                        }
                | FLOAT                 { if (generate_code) {
                                            NEW_BNODE($$);
                                            $$->type = float_leaf;
                                            $$->leaf.ctype.fconst = $1;
                                          }
                                          else
                                            $$ = NULL;
                                        }
                ;

RelOp:            '<'                   { $$ = cmp_lt; }
                | '>'                   { $$ = cmp_gt; }
                | '='                   { $$ = cmp_eq; }
                | NEQ                   { $$ = cmp_neq; }
                | LET                   { $$ = cmp_let; }
                | GET                   { $$ = cmp_get; }
                ;

FunctionCall:   ID '(' FunctionArgList ')'  { $$ = FunctionCall($1, $3); }
                ;

FunctionArgList: SingleArg                  { $$ = $1;
                                            }
               | FunctionArgList ',' SingleArg
                                            { ActualParamList *last;

                                              if (generate_code) {
                                                assert($1 != NULL);

                                                last = $1;
                                                while (last->next != NULL)
                                                  last = last->next;
                                                last->next = $3;
                                                $$ = $1;
                                              }
                                              else
                                                $$ = NULL;
                                            }
               ;

SingleArg:      RelRHS                   { if (generate_code) {
                                             New($$, ActualParamList);

                                             $$->param = $1;
                                             $$->next = NULL;
                                           }
                                           else
                                             $$ = NULL;
                                         }
               ;

LabelReference:  QID                    { $$ = $1; }
                ;

MUStatement:      MeetStatement         { $$ = $1; }
                | UnionStatement        { $$ = $1; }
                | WordformPattern       { if (generate_code) {
                                            NEW_EVALLEAF($$, $1);
                                          }
                                          else
                                            $$ = NULL;
                                        }
                ;

MeetStatement:  '(' MEET_SYM
                    MUStatement
                    MUStatement
                    MeetContext
                    ')'                 { $$ = do_MeetStatement($3, $4, &($5)); }
                ;

MeetContext:      INTEGER
                  INTEGER               { $$.type = word;
                                          $$.size = $1;
                                          $$.size2 = $2;
                                          $$.attrib = NULL;
                                        }
                | OptNumber ID          { do_StructuralContext(&($$), $2, $1, $1); }
                | LEFT_SYM OptNumber ID { do_StructuralContext(&($$), $3, $2, 0); }
                | RIGHT_SYM OptNumber ID{ do_StructuralContext(&($$), $3, 0, $2); }
                | /* epsilon */         { $$.type = word;
                                          $$.size = 1;
                                          $$.size2 = 1;
                                          $$.attrib = NULL;
                                        }
                ;


UnionStatement:  '(' UNION_SYM
                     MUStatement
                     MUStatement
                 ')'                    { $$ = do_UnionStatement($3, $4); }
                ;

TABQuery:        TAB_SYM
                 TabPatterns
                 SearchSpace            { $$ = do_TABQuery($2); }
                ;


TabPatterns:      NamedWfPattern
                  TabOtherPatterns      { $$ = make_first_tabular_pattern($1, $2); }
                ;

TabOtherPatterns: TabOtherPatterns
                  OptDistance
                  NamedWfPattern        { $$ = add_tabular_pattern($1, &($2), $3); }
                  
                | /* eps */             { $$ = NULL; }
                ;

OptDistance:      '{' INTEGER '}'       { do_OptDistance(&($$), $2, $2); }
                | '{' INTEGER ',' OptMaxNumber '}'
                                        { do_OptDistance(&($$), $2, $4); }
                | '{' ',' INTEGER '}'   { do_OptDistance(&($$), 0, $3); }
                | /* eps */             { do_OptDistance(&($$), 0, 0); }
                ;


/* implementations of the following 'actions' can be found in ../CQi/auth.c */
AuthorizeCmd:     USER_SYM ID STRING    { add_user_to_list($2, $3); }
                  OptionalGrants
                | HOST_SYM IPAddress    { add_host_to_list($2); }
                | HOST_SYM IPSubnet     { add_hosts_in_subnet_to_list($2); }
                | HOST_SYM '*'          { add_host_to_list(NULL); }
                ;

OptionalGrants:   '(' Grants ')'
                | /* eps */
                ;

/* add_grant_to_last_user() saves us the trouble of passing username from above */
Grants:           Grants
                  ID                    { add_grant_to_last_user($2); }
                | /* eps */
                ;

/* macro definition */
Macro:            OptDEFINE_SYM MACRO_SYM 
                  ID '(' INTEGER ')' MultiString {
                                                if (enable_macros) 
                                                  define_macro($3, $5, NULL, $7);  /* <macro.c> */
                                                else 
                                                  cqpmessage(Error, "CQP macros not enabled.");
                                                free($7);  /* don't forget to free the allocated strings */
                                                free($3);
                                                }
                | OptDEFINE_SYM MACRO_SYM
                  ID '(' STRING ')' MultiString {
                                                if (enable_macros) 
                                                  define_macro($3, 0, $5, $7);  /* <macro.c> */
                                                else 
                                                  cqpmessage(Error, "CQP macros not enabled.");
                                                free($7);  /* don't forget to free the allocated strings */
                                                free($5);
                                                free($3);
                                                }
                | OptDEFINE_SYM MACRO_SYM '<' STRING {
                                                load_macro_file($4);
                                                free($4);  /* don't forget to free the allocated string */
                                                }
                ;

OptDEFINE_SYM:    DEFINE_SYM
                | /* eps */
                ;

/* displaying macros */
ShowMacro:        SHOW_SYM MACRO_SYM    {
                                          list_macros(NULL);
                                        }
                | SHOW_SYM MACRO_SYM ID {
                                          list_macros($3);
                                          free($3);
                                        }
                | SHOW_SYM MACRO_SYM
                  ID '(' INTEGER ')'    {
                                          print_macro_definition($3, $5);
                                          free($3);
                                        }
                ;

/* a list of strings is concatenated into a single string, in order */
/* to allow multi-line macro definitions with comments */
MultiString:      MultiString STRING    {
                                          int l1 = strlen($1), l2 = strlen($2);
                                          char *s = (char *) cl_malloc(l1 + l2 + 2);
                                          strcpy(s, $1); s[l1] = ' ';
                                          strcpy(s+l1+1, $2);
                                          s[l1+l2+1] = '\0';
                                          free($1);
                                          free($2);
                                          $$ = s;
                                        }
                | STRING                { $$ = $1; }
                ;

/* set random generator seed, so results of 'reduce' can be reproduced */
RandomizeCmd:     RANDOMIZE_SYM         { cl_randomize(); }  /* seed internal RNG randomly */
                | RANDOMIZE_SYM INTEGER { cl_set_seed($2); } /* set seed for internal RNG */
                ;

OtherCommand:   /* eps */
                ;


/* optional symbols (as returned from flex) */
OptionalFIELD:    FIELD                 { $$ = $1; }
                | /* eps */             { $$ = NoField; }
                ;
OptON:            ON_SYM 
                | /* eps */
                ;
OptFROM:          FROM_SYM 
                | /* eps */
                ;
OptTO:            TO_SYM 
                | /* eps */
                ;
OptELLIPSIS:      ELLIPSIS 
                | /* eps */
                ;

/* anchor with optional offset:  e.g.  match:4  target:-1  matchend (== matchend:0) */
Anchor:           FIELD                 { $$.anchor = $1; $$.offset = 0; }
                | FIELD '[' INTEGER ']' { $$.anchor = $1; $$.offset = $3; }
                ;

%%

