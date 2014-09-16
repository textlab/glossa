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







#ifndef _cqp_symtab_h_
#define _cqp_symtab_h_


/*
 * The SYMBOL LOOKUP part: SymbolTable and LabelEntry 
 */

/** whether label has been defined or is defined by this call */
#define LAB_DEFINED 1
/** whether label has been used (i.e. read out) or is used by this call */
#define LAB_USED    2
/** special labels must not be set/modified by user; defined/used consistency isn't checked for special labels */
#define LAB_SPECIAL 4
/** name space #2 used for s-attribute region boundaries by query engine */
#define LAB_RDAT    8

/**
 * LabelEntry: the symbol tables are made up of two linked lists of
 *
 * @see SymbolTable.
 */
typedef struct _label_entry {
  int        flags;
  char      *name;
  int        ref;             /**< array index the label refers to */
  struct _label_entry *next;
} *LabelEntry;


/**
 * The SymbolTable object.
 *
 * cqp-2.2 uses a global symbol table to store label references which gives erroneous
 * results for queries that contain optional elements. A proper treatment of labels requires
 * each of the simulations traversing the NFA in parallel to have its own symbol table.
 * Since the actual symbols are the same for all states, it is more efficient to split the
 * symbol tables into symbol lookup and the actual data. Each simulation has its own data array
 * (which stores corpus positions), but symbol lookup is shared between all simulations and
 * returns an _index_ into the data array. If a simulation branches -- which happens at the
 * left edge of alternatives or optional elements -- the symbol data array must be duplicated.
 *
 * A symbol table now contains multiple namespaces (accessed by flags such as LAB_RDAT
 */
typedef struct _symbol_table {
  LabelEntry  user;                /**< user namespace */
  LabelEntry  rdat;                /**< namespace for LAB_RDAT labels */
  int next_index;                  /**< next free reference table index */
} *SymbolTable;

/* create new symbol table */
SymbolTable new_symbol_table();

/* delete symbol table (free all entries) */
void delete_symbol_table(SymbolTable st);

/* returns label entry, or NULL if undefined (flags are used _only_ to determine namespace) */
LabelEntry findlabel(SymbolTable st, char *s, int flags);

/* look up a label, add flags, and return label entry (NULL if undefined)
   if create is set and label does not exist, it is added to the symbol table */
LabelEntry labellookup(SymbolTable st, char *s, int flags, int create);

/* drop a label from the symbol table (NB: its reference index can't be re-used) */
/* WARNING: this function is not implemented (doesn't seem to be useful at the moment) */
void droplabel(SymbolTable st, LabelEntry l);

/* checks whether all used labels are defined (and vice versa)
 * [only non-special labels in the user namespace will be checked] */
int check_labels(SymbolTable st);

/* print symbol table contents (for debugging purposes) */
void print_symbol_table(SymbolTable st);

/* iterate through labels (visits only labels where the corresponding flags are set) */
LabelEntry symbol_table_new_iterator(SymbolTable st, int flags);
LabelEntry symbol_table_iterator(LabelEntry prev, int flags);




/* 
 * The DATA ARRAY part: RefTab 
 */


/**
 * The REfTab object (represents a reference table).
 */
typedef struct _RefTab {
  int size;
  int *data;
} *RefTab;

/* create new reference table of required size for the given symbol table */
RefTab new_reftab(SymbolTable st);
/* NB If further labels are added to <st>, you must reallocate the reference table
      to make room for the new reference indices */

/* delete reference table */
void delete_reftab(RefTab rt);

/* copies <rt1> to <rt2>; doesn't allocate new reftab for efficiency reasons */
void dup_reftab(RefTab rt1, RefTab rt2);

/* resets all referenced corpus position to -1 -> undefine all references */
void reset_reftab(RefTab rt);


void set_reftab(RefTab rt, int index, int value);
int  get_reftab(RefTab rt, int index, int cpos);


void print_label_values(SymbolTable st, RefTab rt, int cpos);



#endif
