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

#include "globals.h"

/**
 *  global configuration variable: debug level.
 *
 *  Controls how many debug messages are printed.
 *
 *  0 = none (default), 1 = some, 2 = heavy
 */
int cl_debug = 0;
/**
 *  global configuration variable: optimisation.
 *
 *  0 = off, 1 = on  (untested / expensive optimisations)
 */
int cl_optimize = 0;
/**
 *  global configuration variable: memory limit.
 *
 *  In megabytes; some functions will try to keep to this limit;
 *  0 or less turns the limit off.
 *
 *  (ensure memory limit > 2GB is correctly converted to byte size or number of ints)
 */
size_t cl_memory_limit = 0;





/* configuration functions (declared in cl.h) */

/**
 * Sets the debug level configuration variable.
 *
 * @see cl_debug
 */
void
cl_set_debug_level(int level) {
  if ((level < 0) || (level > 2)) {
    fprintf(stderr, "cl_set_debug_level(): non-existent level #%d (ignored)\n", level);
  }
  else {
    cl_debug = level;
  }
}

/**
 * Turns optimization on or off.
 *
 * @see cl_optimize
 * @param state  Boolean (true turns it on, false turns it off).
 */
void
cl_set_optimize(int state) {
  cl_optimize = (state) ? 1 : 0;
}

/**
 * Sets the memory limit.
 *
 *
 * NOTE name of parameter differs here and in cl.h -- TODO
 * @see cl_memory_limit
 */
void 
cl_set_memory_limit(int limit) {
  if (limit <= 0) {
    cl_memory_limit = 0;
  }
  else {
    cl_memory_limit = limit;
  }
}
