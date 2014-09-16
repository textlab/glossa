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

#ifndef _MAPPING_H_
#define _MAPPING_H_

#include "globals.h"
#include "corpus.h"
#include "attributes.h"



/**
 * The SingleMapping object.
 *
 * This object represents a simple many-to-one mapping between one "class" and
 * a number of different tokens (represented by integer ID codes).
 *
 * The tokens are values that occur on a particular attribute in a particular
 * corpus. (Note: positional attributes, not other types!)
 * [?? -- is this correct? -- AH]
 */
typedef struct _single_mapping {
  char *class_name;             /**< this object's class name */
  int nr_tokens;                /**< the number of tokens which this object owns */
  int *tokens;                  /**< the tokens themselves */
} SingleMappingRecord, 
    *SingleMapping;

/**
 * The Mapping object.
 *
 * A Mapping consists of a bundle of SingleMappings. Each SingleMapping represents
 * a class within the mapping, and each class maps to a number of different tokens
 * on a particular p-attribute in a particular corpus.
 *
 * Classes are mutually exclusive, i.e. a single token cannot be a member
 * of more than one class in the same Mapping.
 *
 * NB: "Mapping" is the pointer (class); MappingRecord is the underlying structure.
 *
 * @see SingleMapping
 */
typedef struct _mapping {
  Corpus *corpus;               /**< the corpus this Mapping is valid in */
  Attribute *attribute;         /**< the attribute this object is valid for */
  char *mapping_name;           /**< this Mapping's name */
  int nr_classes;               /**< the number of single mappings currently in this Mapping */
  SingleMappingRecord *classes; /**< the mappings themselves */
} MappingRecord, *Mapping;






/* -------------------- create/destruct mappings */

Mapping
read_mapping(Corpus *corpus,
             char *attr_name,
             char *file_name,
             char **error_string);


int
drop_mapping(Mapping *map);

void
print_mapping(Mapping map);

/* -------------------- token -> class */

SingleMapping
map_token_to_class(Mapping map, 
                   char *token);

int
map_token_to_class_number(Mapping map, 
                          char *token);

int
map_id_to_class_number(Mapping map, 
                       int id);

/* -------------------- class -> {tokens} */

int *
map_class_to_tokens(SingleMapping map,
                    int *nr_tokens);


/* -------------------- utils */

int
number_of_classes(Mapping map);

SingleMapping
find_mapping(Mapping map, char *name);

int
number_of_tokens(SingleMapping map);

/* -------------------- predicates */

int
member_of_class_s(Mapping map, 
                  SingleMapping class, 
                  char *token);

int
member_of_class_i(Mapping map, 
                  SingleMapping class, 
                  int id);

#endif
