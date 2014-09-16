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

#ifndef _cqp_output_h_
#define _cqp_output_h_

#include <stdio.h>
#include "corpmanag.h"
#include "context_descriptor.h"
#include "print-modes.h"

/* definition of the redirection data structures (used in the parser) */

struct Redir {
  char *name;			/* file name for redirection */
  char *mode;			/* mode for redirection ("w" or "a") */
  FILE *stream;
  int is_pipe;
  int is_paging;		/* true iff piping into default pager */
};

struct InputRedir {
  char *name;			/* file name for redirection */
  FILE *stream;
  int is_pipe;
};

/* data structures and global list for "tabulate" command */

typedef struct _TabulationItem {
  char *attribute_name;		/* attribute (name and handle) */
  Attribute *attribute;
  int attribute_type;		/* ATT_NONE = cpos, ATT_POS, ATT_STRUC */
  int flags;			/* normalization flags (%c and %d) */
  FieldType anchor1;		/* start of token sequence to be tabulated */
  int offset1;
  FieldType anchor2;		/* end of token sequence (may be identical to start) */
  int offset2;
  struct _TabulationItem *next;	/* next tabulation item */
} *TabulationItem;

extern TabulationItem TabulationList;

/* ---------------------------------------------------------------------- */

extern int broken_pipe;

/* ---------------------------------------------------------------------- */

/* create temporary file in /tmp and open for writing; tmp_name_buffer
must point to a pre-allocated buffer that can hold at least 32 characters; 
if successful, returns an I/O stream object and copies the name of the 
temporary file into tmp_name_buffer[]; otherwise, NULL is returned and the
tmp_name_buffer[] contains an empty string */
FILE *
OpenTemporaryFile(char *tmp_name_buffer);

/* same as fopen, but supports ~ and $HOME syntax */
FILE *
OpenFile(char *name, char *mode);

int 
open_stream(struct Redir *rd, CorpusCharset charset);

int 
close_stream(struct Redir *rd);

int 
open_input_stream(struct InputRedir *rd);

int 
close_input_stream(struct InputRedir *rd);

void 
catalog_corpus(CorpusList *cl,
	       struct Redir *rd,
	       int first, int last, /* prints matches #first..#last; use (0,-1) for entire corpus  */
	       PrintMode mode);



/* print_output():
 * Ausgabe von CL, ohne Header, auf stream
 */

void 
print_output(CorpusList *cl, 
	     FILE *fd,
	     int interactive,
	     ContextDescriptor *cd,
	     int first, int last,
	     PrintMode mode);

void 
corpus_info(CorpusList *cl);


/* redirectable (error) messages & warnings */
typedef enum _msgtype {
  Error,			/* error message (always displayed) */
  Warning,			/* warning (not shown in silent mode) */
  Message,			/* used for "-d VerboseParser" output only */
  Info				/* user information (not shown in silent mode) */
} MessageType;

void 
cqpmessage(MessageType type, 
	   char *format, ...);

void 
print_corpus_info_header(CorpusList *cl, 
			 FILE *stream, 
			 PrintMode mode,
			 int force);

/* ---------------------------------------------------------------------- */

/* free global list of tabulation items (before building new one) */
void
free_tabulation_list(void);

/* allocate and initialize new tabulation item */
TabulationItem
new_tabulation_item(void);

/* append tabulation item to end of current list */
void
append_tabulation_item(TabulationItem item);

/* tabulate specified query result, using settings from global list of tabulation items;
   return value indicates whether tabulation was successful (otherwise, generates error message) */
int
print_tabulation(CorpusList *cl, int first, int last, struct Redir *rd);  

#endif
