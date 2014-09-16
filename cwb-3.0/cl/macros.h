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


#ifndef _macros_h_
#define _macros_h_

#include "globals.h"




/* function prototypes and macros now in <cl.h> */


/**
 * Allocates a new object.
 *
 * A macro for memory allocation which implements an object-oriented-style
 * "new" term: it evaluates to a pointer to a newly-laid out memory block
 * of the size of the specified type.
 *
 * @param T  The data type of the "object" to be created.
 * @return   A pointer to the new "object"
 * memory allocation macros
 */
#define new(T) (T *)cl_malloc(sizeof(T))
/**
 * Synonym for new (making it case-insensitive)
 * @see new
 */
#define New(P,T)  P = (T *)cl_malloc(sizeof(T))


/**
 * Tests two strings for equality.
 *
 * This macro evaluates to 1 if the strings are equal, 0 otherwise.
 * Be careful: strings are considered equal if they are both NULL,
 * they are considered non-equal when one of both is NULL.
 * @param a  the first string
 * @param b  the second string
 * @return   a Boolean
 */
#define STREQ(a,b) (((a) == (b)) || \
                    ((a) && (b) && (strcmp((a), (b)) == 0)))

/**
 * Evaluates to the smaller of two integer arguments.
 */
#define MIN(a,b) ((a)<(b) ? (a) : (b))
/**
 * Evaluates to the greater of two integer arguments.
 */
#define MAX(a,b) ((a)>(b) ? (a) : (b))


/*
 * display progress bar in terminal window (STDERR, child mode: STDOUT)
 */

void
progress_bar_child_mode(int on_off);

void
progress_bar_clear_line(void);

void
progress_bar_message(int pass, int total, char *message);

void
progress_bar_percentage(int pass, int total, int percentage);




/*
 *  print indented 'tabularised' lists
 */

/* new-style API */
#define ilist_start(lw, ts, id) start_indented_list(lw, ts, id)
#define ilist_print_break(l) print_indented_list_br(l)
#define ilist_print_item(s) print_indented_list_item(s)
#define ilist_end end_indented_list

void
start_indented_list(int linewidth, int tabsize, int indent);

void
print_indented_list_br(char *label);

void
print_indented_list_item(char *string);

void
end_indented_list(void);

/* default configuration of indented lists */
#define ILIST_INDENT      4
#define ILIST_TAB        12
#define ILIST_LINEWIDTH  72  /* total linewidth needed is ILIST_INDENT + ILIST_LINEWIDTH */


#endif
