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
#include <errno.h>

#include "../cl/globals.h"
#include "../cl/macros.h"

#include "../cl/attributes.h"
#include "../cl/cdaccess.h"

#include "builtins.h"
#include "eval.h"
#include "options.h"
#include "output.h"


/* valid attribute types are ATTAT_INT, ATTAT_POS, ATTAT_STRING, ATTAT_NONE */

int f_args[]        = {ATTAT_STRING};                 /**< Argument types for builtin function f */
int distance_args[] = {ATTAT_POS, ATTAT_POS};         /**< Argument types for builtin function distance (or dist) */
int distabs_args[]  = {ATTAT_POS, ATTAT_POS};         /**< Argument types for builtin function distabs */
int bound_args[]    = {ATTAT_INT};                    /**< Argument types for builtin functions lbound and rbound */
int unify_args[]    = {ATTAT_STRING, ATTAT_STRING};   /**< Argument types for builtin functions unify, prefix, is_prefix, minus*/
int ambiguity_args[]= {ATTAT_STRING};                 /**< Argument types for builtin function ambiguity */
int string_arg[]    = {ATTAT_STRING};                 /**< Argument types for builtin functions taking a single string argument */
int arith_args[]    = {ATTAT_INT, ATTAT_INT};         /**< Argument types for builtin arithemtical functions */
int ignore_args[]   = {ATTAT_POS};                    /**< Argument types for builtin function ignore */

/**
 * Global array of built-in functions.
 */
BuiltinF builtin_function[] = {
  {  0, "f",        1, f_args,        ATTAT_INT }, /* frequency of attribute value (positional attributes) */

  {  1, "distance", 2, distance_args, ATTAT_INT }, /* distance of tokens (either absolute values or labels) */
  {  2, "dist",     2, distance_args, ATTAT_INT }, /* abbreviates 'distance' */
  {  3, "distabs",  2, distabs_args,  ATTAT_INT }, /* abs(distance) */

  {  4, "int",      1, string_arg,    ATTAT_INT }, /* typecast: interpret string (e.g. an attribute value) as integer */

  {  5, "lbound",   1, bound_args,    ATTAT_INT }, /* at left boundary of s-attribute range */
  {  6, "rbound",   1, bound_args,    ATTAT_INT }, /* at right boundary of s-attribute range? */

  {  7, "unify",    2, unify_args,    ATTAT_STRING }, /* "unify", i.e. intersect feature sets */
  {  8, "ambiguity",1, ambiguity_args,ATTAT_INT }, /* "ambiguity" of feature set, i.e. cardinality of set */
  {  9, "add",      2, arith_args,    ATTAT_INT }, /* arithmetic operations: add, sub, mul */
  { 10, "sub",      2, arith_args,    ATTAT_INT }, 
  { 11, "mul",      2, arith_args,    ATTAT_INT }, 
  { 12, "prefix",   2, unify_args,    ATTAT_STRING }, /* prefix(a,b) = (longest) common prefix of strings a and b */
  { 13, "is_prefix",2, unify_args,    ATTAT_INT },    /* is_prefix(a,b) = 1 iff a is prefix of b */
  { 14, "minus",    2, unify_args,    ATTAT_STRING }, /* minus(a,b) = result of removing (longest) common prefix of a and b from a */
  { 15, "ignore",   1, ignore_args,   ATTAT_INT },    /* takes label as argument, which it ignores; returns True as an int */

  { -1, NULL,       0, NULL,          ATTAT_NONE }
};


/**
 * Gets a string containing the name of the specified argument type.
 *
 * @param type  One of the ATTAT_x constants (an argument type).
 * @return      The name of the argument type.
 */
char *
attat_name(int type)
{
  switch(type) {
  case ATTAT_NONE:
    return "ATTAT_NONE";
  case ATTAT_POS:
    return "ATTAT_POS";
  case ATTAT_STRING:
    return "ATTAT_STRING";
  case ATTAT_INT:
    return "ATTAT_INT";
  case ATTAT_VAR:
    return "ATTAT_VAR";
  case ATTAT_FLOAT:
    return "ATTAT_FLOAT";
  case ATTAT_PAREF:
    return "ATTAT_PAREF";
  default:
    return "<UNKNOWN>";
  }
}


/**
 * Gets the index of a specified predefined function.
 *
 * @see builtin_function
 * @param name  The name of the function to search for.
 * @return      An index into the builtin_function array.
 */
int 
find_predefined(char *name)
{
  int i;
  
  for (i = 0; builtin_function[i].name; i++)
    if (strcmp(builtin_function[i].name, name) == 0)
      return i;
  return -1;
}

/**
 * Checks whether a string is the name of a predefined function.
 *
 * @param name  The name of the function to search for.
 * @return      Boolean.
 */
int 
is_predefined_function(char *name)
{
  int k;

  k = find_predefined(name);
  return (k >= 0 ? 1 : 0);
}


/**
 * Calculates the length of a prefix shared by two strings.
 *
 * @param s  The first string.
 * @param t  The second string.
 * @return   The number of characters from the start of
 *           the two strings, that are identical between them.
 *           (Or, to put it another way, the index of the first
 *           non-identical character.)
 */
int
common_prefix_length(char *s, char *t)
{
  int l = 0;
  if ((s == NULL) || (t == NULL))
    return 0;
  while ((s[l] == t[l]) && s[l] && t[l])
    l++;
  return l;
}



/**
 * Calls a predefined function from the built_function array.
 *
 * @see            builtin_function
 * @param bf_id    The function to call, identified as an index to the builtin_function array.
 * @param apl      Contains the arguments to this function.
 * @param nr_args  The number of arguments the function takes.
 * @param ctptr    A constraint tree used in some (but not all) of the builtin functions.
 * @param result   Where to put the result of calling the function.
 * @return         boolean: true on success, otherwise false.
 */
int
call_predefined_function(int bf_id,
                         DynCallResult *apl,
                         int nr_args,
                         Constrainttree ctptr,
                         DynCallResult *result)
{
  int argp, pos;
  char *str0, *str1;
  Attribute *attr;

  result->type = ATTAT_NONE;

  if (nr_args != builtin_function[bf_id].nr_args) {
    fprintf(stderr, "Predefined function %s got %d args, takes %d (mismatch)\n",
            builtin_function[bf_id].name, nr_args, builtin_function[bf_id].nr_args);
    return False;
  }
  
  argp = 0;

  /* check argument types */
  /* ATTENTION there are some implicity conversions built-in functions have to provide: 
     - ATTAT_POS and ATTAT_INT are interchangeable (both use .intres, so there's no problem) 
     - ATTAT_PAREF can be cast to ATTAT_STRING (function has to evaluate label reference and retrieve the corresponding token)
     - ATTAT_NONE is accepted for ATTAT_STRING arguments; 
     so a label reference for a label that hasn't been set can receive special treatment in unify() 
     (all functions that take ATTAT_STRING arguments must be able to handle ATTAT_NONE) */

  for (argp = 0; argp < nr_args; argp++) {
    if (! ((apl[argp].type == builtin_function[bf_id].argtypes[argp]) || 
           ((apl[argp].type == ATTAT_INT)   && (builtin_function[bf_id].argtypes[argp] == ATTAT_POS)) ||
           ((apl[argp].type == ATTAT_POS)   && (builtin_function[bf_id].argtypes[argp] == ATTAT_INT)) ||
           ((apl[argp].type == ATTAT_PAREF) && (builtin_function[bf_id].argtypes[argp] == ATTAT_STRING)) ||
            ((apl[argp].type == ATTAT_NONE)  && (builtin_function[bf_id].argtypes[argp] == ATTAT_STRING)) ||
           0
           ))
      {
        cqpmessage(Error,
                   "Builtin function %s(): argument type mismatch at arg #%d\n\tExpected %s, got %s.",
                   builtin_function[bf_id].name,
                   argp,
                   attat_name(builtin_function[bf_id].argtypes[argp]),
                   attat_name(apl[argp].type));
        return False;
      } 
  }

  /* 
   * nr of args and types are correct. eval it.
   */

  switch (bf_id) {

  case 0:                        /* f */
    
    /* it should be a pa_ref */
    assert(ctptr->func.args->param->type == pa_ref);
    
    attr = ctptr->func.args->param->pa_ref.attr;
    assert(attr != NULL);
    
    if (apl[0].type == ATTAT_NONE) {
      result->type = ATTAT_INT;        /* label references which are not set return 0 (no other pa_refs should do that!) */
      result->value.intres = 0;
      return True;
    }
    else if (apl[0].type == ATTAT_PAREF)
      pos = apl[0].value.parefres.token_id;
    else
      pos = get_id_of_string(attr, apl[0].value.charres);

    if ((cderrno == CDA_OK) && (pos >= 0)) {
      result->type = ATTAT_INT;
      result->value.intres = get_id_frequency(attr, pos);
      if (cderrno == CDA_OK)
        return True;
    }
    break;
    
  case 1:                        /* distance */
  case 2:                        /* dist */
    result->type = ATTAT_INT;
    result->value.intres = apl[1].value.intres - apl[0].value.intres;
    return True;
    break;

  case 3:                        /* distabs */
    result->type = ATTAT_INT;
    result->value.intres = abs(apl[1].value.intres - apl[0].value.intres);
    return True;
    break;

  case 4:                        /* int (typecast) */

    /* convert argument from PAREF to STRING if necessary */
    if (apl[0].type == ATTAT_PAREF) {
      assert(ctptr->func.args[0].param->type == pa_ref);
      attr = ctptr->func.args[0].param->pa_ref.attr;
      assert(attr != NULL);
      str0 = get_string_of_id(attr, apl[0].value.parefres.token_id);
    }
    else
      str0 = apl[0].value.charres;

    result->type = ATTAT_NONE;
    {
      int value = 0;
      
      errno = 0;                /* might catch some conversion errors */
      value = atoi(str0);
      if (errno != 0) {
        cqpmessage(Error, "Bulitin integer conversion failed for int(%s).", str0);
        return False;                /* probably a conversion error */
      }

      result->type = ATTAT_INT;
      result->value.intres = value;
      return True;
    }

    break;

  case 5:                        /* lbound */

    attr = (ctptr->func.args->param->type == sa_ref)
      ? ctptr->func.args->param->sa_ref.attr
      : NULL;

    if (!attr) {
      cqpmessage(Error, "Builtin lbound() function requires s-attribute argument.");
      result->type = ATTAT_NONE;
      return False;
    }
    
    result->type = ATTAT_INT;
    result->value.intres = 1 & apl[0].value.intres;
    return True;

    break;

  case 6:                        /* rbound */

    attr = (ctptr->func.args->param->type == sa_ref)
      ? ctptr->func.args->param->sa_ref.attr
      : NULL;

    if (!attr) {
      cqpmessage(Error, "Builtin rbound() function requires s-attribute argument.");
      result->type = ATTAT_NONE;
      return False;
    }
    
    result->type = ATTAT_INT;
    result->value.intres = (2 & apl[0].value.intres ? 1 : 0);
    return True;

    break;

  case 7:                        /* unify */
    
    /* first handle the disallowed case of ATTAT_NONE in the 2nd argument */
    if (apl[1].type == ATTAT_NONE) {
      cqpmessage(Error, "Last argument to builtin unify() function is undefined.");
      result->type = ATTAT_NONE; /* ATTAT_NONE not allowed as second argument */
      return False;
    }

    /* init the return value (because of the special case where arg1 is ATTAT_NONE */
    result->type = ATTAT_STRING;
    result->value.charres = result->dynamic_string_buffer;

    /* convert 2nd argument from PAREF to STRING if necessary */
    if (apl[1].type == ATTAT_PAREF) {
      assert(ctptr->func.args[1].param->type == pa_ref);
      attr = ctptr->func.args[1].param->pa_ref.attr;
      assert(attr != NULL);
      str1 = get_string_of_id(attr, apl[1].value.parefres.token_id);
    }
    else
      str1 = apl[1].value.charres;

    /* if the 1st argument is ATTAT_NONE, just return 2nd argument */
    if (apl[0].type == ATTAT_NONE) {
      strcpy(result->dynamic_string_buffer, str1);
      return True;
    }
 
    /* convert 1st argument from PAREF to STRING if necessary */
    if (apl[0].type == ATTAT_PAREF) {
      assert(ctptr->func.args[0].param->type == pa_ref);
      attr = ctptr->func.args[0].param->pa_ref.attr;
      assert(attr != NULL);
      str0 = get_string_of_id(attr, apl[0].value.parefres.token_id);
    }
    else
      str0 = apl[0].value.charres;
    
    if (!cl_set_intersection(result->value.charres, str0, str1)) {
      cqpmessage(Error, "Malformed feature sets passed to builtin unify(%s, %s).", str0, str1);
      result->type = ATTAT_NONE;
      return False;
    }
    else {
      return True;
    }

    break;

  case 8:                        /* ambiguity */

    /* in the case of ATTAT_NONE, ambiguity is 0, which means 'no data' */
    /* (it might be cleaner to raise an error in this case, but it's simpler */
    /*  if we can just say ''ambiguity(a.agr) > 1'' whether 'a' has been set or not */
    if (apl[0].type == ATTAT_NONE) {
      str0 = "|";
    }
    /* convert argument from PAREF to STRING if necessary */
    else if (apl[0].type == ATTAT_PAREF) {
      assert(ctptr->func.args[0].param->type == pa_ref);
      attr = ctptr->func.args[0].param->pa_ref.attr;
      assert(attr != NULL);
      str0 = get_string_of_id(attr, apl[0].value.parefres.token_id);
    }
    else
      str0 = apl[0].value.charres;

    result->type = ATTAT_NONE;
    {
      int count = cl_set_size(str0);
      
      if (count >= 0) {
        result->type = ATTAT_INT;
        result->value.intres = count;
        return True;
      }
      else {
        cqpmessage(Error, "Malformed input string passed to builtin ambiguity(%s).", str0);
        return False;
      }
    }

    break;

  case 9:                        /* arithmetic: add */
    result->type = ATTAT_INT;
    result->value.intres = apl[0].value.intres + apl[1].value.intres;
    return True;
    break;

  case 10:                        /* arithmetic: sub */
    result->type = ATTAT_INT;
    result->value.intres = apl[0].value.intres - apl[1].value.intres;
    return True;
    break;

  case 11:                        /* arithmetic: mul */
    result->type = ATTAT_INT;
    result->value.intres = apl[0].value.intres * apl[1].value.intres;
    return True;
    break;

  case 12:                        /* prefix */
  case 13:                        /* is_prefix */
  case 14:                        /* minus */

    /* first handle the disallowed case of ATTAT_NONE type arguments */
    if (apl[0].type == ATTAT_NONE) {
      cqpmessage(Error, "First argument to builtin %s() function is undefined.",
                 builtin_function[bf_id].name);
      result->type = ATTAT_NONE; /* ATTAT_NONE not allowed as second argument */
      return False;
    }
    if (apl[1].type == ATTAT_NONE) {
      cqpmessage(Error, "Second argument to builtin %s() function is undefined.",
                 builtin_function[bf_id].name);
      result->type = ATTAT_NONE; /* ATTAT_NONE not allowed as second argument */
      return False;
    }

    /* convert 1st argument from PAREF to STRING if necessary */
    if (apl[0].type == ATTAT_PAREF) {
      assert(ctptr->func.args[0].param->type == pa_ref);
      attr = ctptr->func.args[0].param->pa_ref.attr;
      assert(attr != NULL);
      str0 = get_string_of_id(attr, apl[0].value.parefres.token_id);
    }
    else
      str0 = apl[0].value.charres;

    /* convert 2nd argument from PAREF to STRING if necessary */
    if (apl[1].type == ATTAT_PAREF) {
      assert(ctptr->func.args[1].param->type == pa_ref);
      attr = ctptr->func.args[1].param->pa_ref.attr;
      assert(attr != NULL);
      str1 = get_string_of_id(attr, apl[1].value.parefres.token_id);
    }
    else
      str1 = apl[1].value.charres;
    
    result->type = ATTAT_NONE;        /* in case of failure */
    if (bf_id == 12) {                /* prefix */
      int l = common_prefix_length(str0, str1);
      if (l >= CL_DYN_STRING_SIZE - 1) {
        cqpmessage(Error, "DCR string buffer overflow in builtin function prefix().");
        return False;
      }
      strncpy(result->dynamic_string_buffer, str0, l);
      result->dynamic_string_buffer[l] = '\0';
      result->type = ATTAT_STRING;
      result->value.charres = result->dynamic_string_buffer;
      return True;
    }
    else if (bf_id == 13) {        /* is_prefix */
      int l = common_prefix_length(str0, str1);
      result->type = ATTAT_INT;
      if (l == strlen(str0)) {
        result->value.intres = 1;
      }
      else {
        result->value.intres = 0;
      }
      return True;
    }
    else {                        /* minus */
      int lp = common_prefix_length(str0, str1);
      int l0 = strlen(str0);
      int l = l0 - lp;                /* length of resulting suffix */
      if (l >= CL_DYN_STRING_SIZE - 1) {
        cqpmessage(Error, "DCR string buffer overflow in builtin function minus().");
        return False;
      }
      strncpy(result->dynamic_string_buffer, str0 + lp, l);
      result->dynamic_string_buffer[l] = '\0';
      result->type = ATTAT_STRING;
      result->value.charres = result->dynamic_string_buffer;
      return True;
    }

    break;

  case 15:                        /* ignore */
    result->type = ATTAT_INT;
    result->value.intres = 1;
    return True;
    break;
    
  default:
    fprintf(stderr, "%s, line %d: Illegal bf_id\n", __FILE__, __LINE__);
    break;
  }

  cqpmessage(Error, "Internal error in builtin function.");
  result->type = ATTAT_NONE;
  return False;
}
