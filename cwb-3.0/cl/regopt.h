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

#ifndef _REGOPT_H_
#define _REGOPT_H_
#include "globals.h"
#include <regex.h>

/**
 * Maximum number of grains of optimisation.
 *
 * There's no point in scanning for too many grains, but regexps can be bloody inefficient.
 */
#define MAX_GRAINS 12

/**
 * Underlying structure for CL_Regex object.
 *
 * @see regopt.c
 */
struct _CL_Regex {
  regex_t buffer;                    /**< buffer for the actual regex (POSIX) */
  CorpusCharset charset;             /**< the character set in use for this regex */
  int flags;                         /**< flags for this regex: can be IGNORE_CASE and/or IGNORE_DIAC */
  char *iso_string;                  /**< a buffer of size MAX_LINE_LENGTH used for normalisation by cl_regex_match() */

  /* data from optimiser (see global variables in regopt.c for comments) */
  int grains;                        /**< number of grains (0 = not optimised). @see cl_regopt_grains */
  int grain_len;                     /**< @see cl_regopt_grain_len */
  char *grain[MAX_GRAINS];           /**< @see cl_regopt_grain */
  int anchor_start;                  /**< @see cl_regopt_anchor_start */
  int anchor_end;                    /**< @see cl_regopt_anchor_end */
  int jumptable[256];                /**< @see cl_regopt_jumptable @see make_jump_table */
};


/* interfaces function prototypes are defined in <cl.h> */

#endif
