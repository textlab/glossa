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

#ifndef _VARIABLES_H_
#define _VARIABLES_H_

/* ---------------------------------------------------------------------- */

#include "../cl/corpus.h"
#include "../cl/attributes.h"

/* ---------------------------------------------------------------------- */

typedef struct _variable_item {
  int free;
  char *sval;
  int ival;
} VariableItem;

typedef struct _variable_buf {

  int valid;			/* flag whether I'm valid or not */
  char *my_name;		/* my name */

  char *my_corpus;		/* name of corpus I'm valid for */
  char *my_attribute;		/* name of attribute I'm valid for */

  int nr_valid_items;		/* only valid after validation */
  int nr_invalid_items;
  
  int nr_items;			/* number of items */
  VariableItem *items;		/* set of items */
  
} VariableBuffer, *Variable;

extern int nr_variables;
extern Variable *VariableSpace;

/* ---------------------------------------------------------------------- */

Variable
FindVariable(char *varname);

int
VariableItemMember(Variable v, char *item);

int
VariableAddItem(Variable v, char *item);

int
VariableSubtractItem(Variable v, char *item);

int
VariableDeleteItems(Variable v);

int
DropVariable(Variable *vp);

Variable
NewVariable(char *varname);

int
SetVariableValue(char *varName, 
		 char operator, 
		 char *varValues);

/* variable iterator functions */
void variables_iterator_new(void);
Variable variables_iterator_next(void);	/* returns NULL at end of list */


/* check variable's strings against corpus.attribute lexicon */
int
VerifyVariable(Variable v, 
	       Corpus *corpus, 
	       Attribute *attribute);

/* get lexicon IDs of variable's strings in corpus.attribute lexicon */
int *
GetVariableItems(Variable v, 
		 Corpus *corpus, Attribute *attribute, 
		 /* returned: */
		 int *nr_items);

/* returns list of pointers to variable's strings */
char **
GetVariableStrings(Variable v, int *nr_items);

#endif
