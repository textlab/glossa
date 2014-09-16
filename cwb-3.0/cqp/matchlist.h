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

#ifndef _MATCHLIST_H_
#define _MATCHLIST_H_


/* 
 * MATCH LISTS AND SET OPS ON THEM 
 */


/* 
 * set operations on (initial) matchlists
 */

typedef enum ml_setops {
  Union,
  Intersection,
  Complement,
  Identity,			/* create a copy */
  Uniq,				/* make unique lists (also called "sets" :-)) */
  Reduce			/* delete -1 items */
} MLSetOp;


typedef struct _Matchlist
{
  int  *start;
  int  *end;
  int  *target_positions;
  int tabsize;
  int matches_whole_corpus;	/* avoid copying then. 0 for no, 1 for yes */
  int is_inverted;		/* contains ``inverted'' positions, that is,
				 * positions which do NOT match */
} Matchlist;



void init_matchlist(Matchlist *matchlist);

void show_matchlist(Matchlist matchlist);

void show_matchlist_firstelements(Matchlist matchlist);

void free_matchlist(Matchlist *matchlist);


int Setop(Matchlist *list1, MLSetOp operation, Matchlist *list2);



#endif
