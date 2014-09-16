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

/* maximum length of a line in a macro definition file */
#define MACRO_FILE_MAX_LINE_LENGTH 1024

/* read one character from input (called from YY_INPUT() in <parser.l>) */
int yy_input_char(void);

/* check if input is being read from macro expansion */
int yy_input_from_macro(void);

/* initialise macro database */
void init_macros(void);

/* define a new macro:
 *   name = macro name
 *   args = # of arguments (0 .. 10)
 *     alternatively, specify:
 *   argstr = macro argument string (e.g. ``$0=name $1=label'')
 *   definition = macro definition ... this string is substituted for /<name>(...)
 *          $0 .. $9 refer to the macro's arguments and CAN NOT be escaped
 */
int define_macro(char *name, int args, char *argstr, char *definition);

/* load macro definitions from file */
void load_macro_file(char *name);

/* expand macro <name>; reads macro argument list using yy_input_char and pushes
 * an input buffer with the replacement string on top of the buffer list;
 * returns 0 if macro is not defined or if there is a syntax error in the argument list 
 */
int expand_macro(char *name);

/* delete active input buffers created by macro expansion; returns # of buffers deleted
 * used when synchronizing after a parse error 
 * (if <trace> is true, prints stack trace on STDERR)
 */
int delete_macro_buffers(int trace);

/* macro iterator functions (iterate through all macros in hash) for command-line completion */
void macro_iterator_new(void);	                      /* start new iterator */
char *macro_iterator_next(char *prefix, int *nargs);  /* returns next macro name (matching prefix if specified), and number of arguments; NULL at end of list */
char *macro_iterator_next_prototype(char *prefix);    /* returns next macro (matching prefix if specified), as a formatted prototype (malloc'ed) */

/* list all defined macros on stdout; 
 * if <prefix> is not NULL, list only macros beginning with <prefix> */
void list_macros(char *prefix);

/* print definition of macro on stdout */
void print_macro_definition(char *name, int args);

/* print macro hash statistics on stderr (called by CQP if MacroDebug is activated) */
void macro_statistics(void);

