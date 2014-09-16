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

#ifndef _cqp_ranges_h_
#define _cqp_ranges_h_

#include "eval.h"
#include "corpmanag.h"
#include "output.h"
#include "../cl/bitfields.h"
#include "../cl/attributes.h"

#define SORT_FROM_START 0
#define SORT_FROM_END 1
#define SORT_RESET 2

/* -------------------------------------------------- sorting */

typedef struct _sort_clause {
  char *attribute_name;		/* attribute and %cd flags */
  int flags;
  FieldType anchor1;		/* start of sort region */
  int offset1;
  FieldType anchor2;		/* end of sort region */
  int offset2;
  int sort_ascending;		/* sort direction (ascending/descending) */
  int sort_reverse;		/* reverse sort (sort reversed character sequences) */
  /*   struct _sort_clause *next; */  /* used to support multiple sort clauses in a linked list */
} SortClauseBuffer, *SortClause;

/* -------------------------------------------------- ranges */

typedef enum rng_setops {
  RUnion,
  RIntersection,
  RDiff,
  /* RIdentity removed (only used by RUnion -- now rewritten to handle targets+keywords) */
  RMaximalMatches,		/* new :o) (used by longest_match strategy) */
  RMinimalMatches,		/* used by shortest_match strategy */
  RLeftMaximalMatches,		/* used by standard_match strategy */
  RNonOverlapping,              /* delete overlapping matches (for subqueries) */
  RUniq,			/* make unique lists (= ordered sets) of ranges */
  RReduce
} RangeSetOp;

/* line operation modes (for deletions) ------------------------------------- */

#define ALL_LINES 1
#define SELECTED_LINES 2
#define UNSELECTED_LINES 3

/*
 * Delete a single concordance line from a corpus 
 */

Boolean delete_interval(CorpusList *cp, int interval_number);

Boolean delete_intervals(CorpusList *cp, Bitfield which_intervals, int mode);

/*
 * copy concordance lines into (new) subcorpus 
 */

Boolean copy_intervals(CorpusList *cp,
		       Bitfield which_intervals,
		       int mode,
		       char *subcorpname);
/* unused */

Boolean calculate_ranges(CorpusList *cl,
			 int cpos, Context spc, int *left, int *right);

int calculate_rightboundary(CorpusList *cl, 
			    int cpos, 
			    Context spc);

int calculate_leftboundary(CorpusList *cl,
			   int cpos,
			   Context spc);

int RangeSetop(CorpusList *list1,
	       RangeSetOp operation,
	       CorpusList *list2,
	       Bitfield restrictor);

/* make sure that ranges are sorted in 'natural' order (i.e. by start and end cpos) 
   -- this function has to be called when matching ranges are modified and may be needed
   -- when loading a query result (with "undump") that is not sorted in ascending order;
   -- with optional "mk_sortidx" flag, a sortidx corresponding to the original ordering is created
*/
void RangeSort(CorpusList *c, int mk_sortidx);

/* either sort query result (according SortClause) or count frequencies of matching strings,
   which is based on the same sorting algorithm;
   return value indicates whether the sort was performed successfully, otherwise the sort index
   is reset to the default sort order (as is done by passing sc=NULL) */
int
SortSubcorpus(CorpusList *cl, SortClause sc, int count_mode, struct Redir *redir);

/* sort query result in random order; if seed > 0, a reproducible and stable ordering is generated
   based on the start and end corpus positions of matches (i.e. two given matches will always be
   sorted in the same order); seed should ideally be a prime number (2^31 is a particularly bad choice) */
int
SortSubcorpusRandomize(CorpusList *cl, int seed);

void
FreeSortClause(SortClause sc);

#endif
