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

#ifndef _cqp_h_
#define _cqp_h_

#define CQPRC_NAME ".cqprc"
#define CQPMACRORC_NAME ".cqpmacros"
/** The number of file handles CQP can store in its file-array (ie max number of nested files) @see cqp_parse_file ) */
#define MAXCQPFILES 20

/** Size of the CQP query buffer. */
#define QUERY_BUFFER_SIZE 2048

#include <stdio.h>

#define True 1
#define False 0
/**
 * DEPRACATED means of storing a Boolean value
 */
typedef char Boolean;
/* typedef enum bool { False, True } Boolean; */

typedef enum _cyctype {
  NoExpression, Query, Activation, SetOperation, Assignment
} CYCtype;

CYCtype LastExpression;

extern int reading_cqprc;

/* ======================================== Query Buffer Interface */

/* ========== see parser.l:extendQueryBuffer() for details */
/* ========== initialization done in parse_actions.c:prepare_parse() */

extern char QueryBuffer[QUERY_BUFFER_SIZE];
extern int QueryBufferP;
extern int QueryBufferOverflow;

/* ======================================== Other global variables */

char *searchstr;                /**< needs to be global, unfortunately */
int exit_cqp;                   /**< 1 iff exit-command was issued while parsing */

char *cqp_input_string;
int cqp_input_string_position;

void cqp_randomize(void);

int initialize_cqp(int argc, char **argv);


int cqp_parse_file(FILE *fd, int exit_on_parse_errors);

int cqp_parse_string(char *s);

/* ====================================================================== */

/**
 * Interrupt callback functions are of this type.
 */
typedef void (*InterruptCheckProc)(void);

int EvaluationIsRunning;

int setInterruptCallback(InterruptCheckProc f);

void CheckForInterrupts();

int signal_handler_is_installed;

void install_signal_handler(void); /* install Ctrl-C interrupt handler (clears EvaluationIsRunning flag) */


/* ====================================================================== */

#endif
