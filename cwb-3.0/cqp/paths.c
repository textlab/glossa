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
#include "../cl/globals.h"

#include "paths.h"

/**
 * Tokenises a string into components split by ':'.
 *
 * @param s  The string to tokenise; or, NULL if tokenisation has already been initialised.
 * @return   The next token from the string.
 */
char *
get_path_component(char *s)
{
  register int c;
  char *tok;
  static char *last;
  
  if (s == NULL && (s = last) == NULL)
    return (NULL);
  
  do {
    c = *s++;
  } while (c == ':');
  
  if (c == 0) {           /* no non-delimiter characters */
    last = NULL;
    return (NULL);
  }
  tok = s - 1;
  
  for (;;) {
    c = *s++;

    if (c == ':' || c == '\0') {
      if (c == 0)
        s = NULL;
      else
        s[-1] = 0;
      last = s;
      return (tok);
    }
  }
  /* NOTREACHED */
 
  assert(0 && "Not reached");
  return NULL;
}

