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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "../cl/corpus.h"
#include "../cl/attributes.h"
#include "../cl/cdaccess.h"
#include "../cl/macros.h"

#include "variables.h"

#include "output.h"


/* TODO: shrink malloced buffers as necessary - for VarSpace as well
   as for items in single vars */

/* ---------------------------------------------------------------------- */

#define ITEM_REALLOC 8

#define VARIABLE_REALLOC 16

int nr_variables = 0;
Variable *VariableSpace = NULL;


/* ---------------------------------------------------------------------- */

Variable
FindVariable(char *varname)
{
  int i;
  
  for (i = 0; i < nr_variables; i++)
    if (VariableSpace[i] && strcmp(VariableSpace[i]->my_name, varname) == 0)
      return VariableSpace[i];
  
  return NULL;
}

int
VariableItemMember(Variable v, char *item)
{
  int i;

  for (i = 0; i < v->nr_items; i++)
    if (!v->items[i].free && strcmp(v->items[i].sval, item) == 0)
      return 1;

  return 0;
}

int
VariableAddItem(Variable v, char *item)
{
  int i;

  if (!VariableItemMember(v, item)) {
    
    v->valid = 0;
    
    for (i = 0; i < v->nr_items; i++)
      if (v->items[i].free) {
	v->items[i].free = 0;
	v->items[i].sval = cl_strdup(item);
	v->items[i].ival = -1;
	break;
      }

    if (i >= v->nr_items) {

      /* no space in list. malloc. */

      v->nr_items += ITEM_REALLOC;
      
      if (v->items == NULL) 
	v->items = (VariableItem *)cl_malloc(sizeof(VariableItem) * 
					  v->nr_items);
      else 
	v->items = (VariableItem *)cl_realloc(v->items,
					   sizeof(VariableItem) * 
					   v->nr_items);
      
      if (v->items == NULL) {
	fprintf(stderr, "Fatal Error #6: no memory left.");
	perror("Memory fault");
	assert(0 && "Big Problem here!");
      }

      v->items[i].sval = cl_strdup(item);
      v->items[i].free = 0;
      v->items[i].ival = -1;

      i++;

      for ( ; i < v->nr_items; i++) {
	v->items[i].sval = NULL;
	v->items[i].free = 1;
	v->items[i].ival = -1;
      }
    }
  }
  return 1;
}

int
VariableSubtractItem(Variable v, char *item)
{
  int i;

  v->valid = 0;

  for (i = 0; i < v->nr_items; i++)
    
    /* wir löschen _alle_ vorkommen eines items in der Liste! */
    
    if (!v->items[i].free && 
	v->items[i].sval != NULL &&
	strcmp(v->items[i].sval, item) == 0) {
      cl_free(v->items[i].sval);
      v->items[i].ival = -1;
      v->items[i].free++;
    }
  
  return 1;
}

int
VariableDeleteItems(Variable v)
{
  v->valid = 0;
  v->nr_items = 0;
  v->nr_valid_items = 0;
  v->nr_invalid_items = 0;
  cl_free(v->items);
  return 1;
}

int
DropVariable(Variable *vp)
{
  int i;

  Variable v = *vp;

  VariableDeleteItems(v);
  
  cl_free(v->my_name);
  cl_free(v->my_corpus); 
  cl_free(v->my_attribute);

  for (i = 0; i < nr_variables; i++)
    if (VariableSpace[i] == v) {
      VariableSpace[i] = NULL;
      break;
    }

  if (i >= nr_variables) {
    fprintf(stderr, 
	    "Error #5 in variable logic. Please contact developer.\n");
  }
  
  *vp = NULL;
  vp = NULL;
  
  return 1;
}

Variable
NewVariable(char *varname)
{
  Variable v;
  int i;

  if (varname == NULL)
    return NULL;

  v = (Variable)cl_malloc(sizeof(VariableBuffer));
  v->valid = 0;
  v->my_name = cl_strdup(varname);
  v->my_corpus = NULL;
  v->my_attribute = NULL;
  v->nr_items = 0;
  v->items = NULL;

  for (i = 0; i < nr_variables; i++) {
    if (VariableSpace[i] == NULL) {
      VariableSpace[i] = v;
      break;
    }
  }

  if (i >= nr_variables) {

    /* not inserted, malloc */
    
    nr_variables += VARIABLE_REALLOC;

    if (VariableSpace == NULL)
      VariableSpace = (Variable *)cl_malloc(nr_variables * sizeof(Variable));
    else
      VariableSpace = (Variable *)cl_realloc(VariableSpace, 
					  nr_variables * sizeof(Variable));
    if (VariableSpace == NULL) {
      fprintf(stderr, "Fatal Error: Variable space out of memory.\n");
      assert(0 && "Sorry, big problem here!");
    }
    
    VariableSpace[i++] = v;

    for ( ; i < nr_variables; i++)
      VariableSpace[i] = NULL;
  }

  return v;
}

int
SetVariableValue(char *varName, 
		 char operator, 
		 char *varValues)
{
  Variable v;
  char *item;
  FILE *fd;

  if ((v = FindVariable(varName)) == NULL) {

    v = NewVariable(varName);
    
    if (v == NULL) {
      cqpmessage(Error, "Out of memory.");
      return 0;
    }
  }

  switch (operator) {
    
  case '+':			/* += operator: extend */
    
    item = strtok(varValues, " \t\n");
    while (item) {
      VariableAddItem(v, item);
      item = strtok(NULL, " \t\n");
    }

    break;

  case '-':			/* -= operator: substract */

    item = strtok(varValues, " \t\n");
    while (item) {
      VariableSubtractItem(v, item);
      item = strtok(NULL, " \t\n");
    }

    break;

  case '=':			/* = operator: absolute setting */

    VariableDeleteItems(v);

    item = strtok(varValues, " \t\n");
    while (item) {
      VariableAddItem(v, item);
      item = strtok(NULL, " \t\n");
    }
    break;

  case '<':			/* < operator: read from file */

    VariableDeleteItems(v);

    if ((fd = OpenFile(varValues, "r"))) {
      
      int l;
      char s[1024];

      while (fgets(s, 1024, fd) != NULL) {

	l = strlen(s);

	if (l > 0 && s[l-1] == '\n') {

	  /* strip trailing newline */
	  s[l-1] = '\0'; l--;
	}

	if (l > 0)
	  VariableAddItem(v, s);
      }
      fclose(fd);
    }
    else {
      perror(varValues);
      cqpmessage(Warning, "Can't open %s: no such file or directory",
		 varValues);
      return 0;
    }
    break;
    
  default:
    return 0;
    break;
  }

  return 1;
}


/* 
 *  variables iterator
 */
int variables_iterator_idx;

void 
variables_iterator_new(void) {
  variables_iterator_idx = 0;
}

Variable 
variables_iterator_next(void) {
  if (variables_iterator_idx < nr_variables) {
    return VariableSpace[variables_iterator_idx++];
  }
  else {
    return NULL;
  }
}



int
VerifyVariable(Variable v, 
	       Corpus *corpus, 
	       Attribute *attribute)
{
  int i;

  int nr_valid, nr_invalid;

  if (v->valid == 0 || 
      v->my_corpus == NULL || v->my_attribute == NULL ||
      strcmp(v->my_corpus, corpus->registry_name) != 0 ||
      strcmp(v->my_attribute, attribute->any.name) != 0) {
    
    v->valid = 0;
    cl_free(v->my_corpus);
    cl_free(v->my_attribute);

    if (attribute->any.type != ATT_POS) {
      return 0;
    }

    v->my_corpus = cl_strdup(corpus->registry_name);
    v->my_attribute = cl_strdup(attribute->any.name);
    
    nr_valid = 0;
    nr_invalid = 0;
    
    for (i = 0; i < v->nr_items; i++) {

      if (!v->items[i].free) {
	if (v->items[i].sval == NULL) {
	  fprintf(stderr, "Error #1 in variable logic. Contact developer.\n");
	  v->items[i].ival = -1;
	}
	else
	  v->items[i].ival = get_id_of_string(attribute, v->items[i].sval);

	if (v->items[i].ival < 0)
	  nr_invalid++;
	else
	  nr_valid++;
      }
    }
    
    v->nr_valid_items = nr_valid;
    v->nr_invalid_items = nr_invalid;
    
    if (nr_valid > 0)
      v->valid = 1;
    else
      v->valid = 0;
  }
  
  return v->valid;
}


/* comparison function for qsort() of id_list returned by GetVariableItems */
static
int intcompare(const void *i, const void *j)
{
  return(*(int *)i - *(int *)j);
}

int *
GetVariableItems(Variable v, 
		 Corpus *corpus, Attribute *attribute, 
		 /* returned: */
		 int *nr_items)
{
  if (VerifyVariable(v, corpus, attribute)) {

    int *items;
    int i, ip;

    if (v->nr_valid_items > 0) {
      items = (int *)cl_malloc(v->nr_valid_items * sizeof(int));
      *nr_items = v->nr_valid_items;

      ip = 0;
      for (i = 0; i < v->nr_items; i++)
	if (!v->items[i].free && v->items[i].ival >= 0) {
	  if (ip >= v->nr_valid_items)
	    fprintf(stderr, 
		    "Error #2 in variable logic. Please contact developer.\n");
	  else {
	    items[ip] = v->items[i].ival;
	    ip++;
	  }
	}

      if (ip != v->nr_valid_items) 
	fprintf(stderr, 
		"Error #3 in variable logic. Please contact developer.\n");

      /* eval_bool() <eval.c> expects a sorted list of IDs (for binary search) */
      qsort(items, *nr_items, sizeof(int), intcompare);
      return items;
    }
    else {
      *nr_items = 0;
      return NULL;
    }
  }
  else {
    *nr_items = 0;
    return NULL;
  }
}

char **
GetVariableStrings(Variable v, 
		   /* returned: */
		   int *nr_items)
{
  char **result;
  int i, j, N;
  
  /* count number of items (strings) stored in variable */
  N = 0;
  for (i=0; i < v->nr_items; i++) {
    if (!v->items[i].free) N++;
  }
  *nr_items = N;

  if (N == 0) {
    return NULL;
  }
  else {
    /* allocate pointer table which will be returned */
    result = cl_malloc(N * sizeof(char *));
  
    /* insert pointers into result table */
    j = 0;
    for (i=0; i < v->nr_items; i++) {
      if (!v->items[i].free) {
	result[j] = v->items[i].sval;
	j++;
      }
    }
    
    return result;		/* must be freed by caller */
  }
}
