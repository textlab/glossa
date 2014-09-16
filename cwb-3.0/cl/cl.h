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


#ifndef _cwb_cl_h
#define _cwb_cl_h

#include <strings.h>                /* for size_t */

/*
 *  declaration of opaque object structures,
 *  and definition of public objects, enums, and constants
 *
 *  (The underlying structures are defined elsewhere.)
 */
typedef struct TCorpus Corpus;                        /**< The Corpus object: contains information on a loaded corpus. */
typedef union _Attribute Attribute;                   /**< The Attribute object: an entire segment of a corpus (of any flavour; s, p etc). */
typedef struct _position_stream_rec_ *PositionStream; /**< The PositionStream object: gives stream-like reading of an Attribute. */
typedef struct _CL_Regex *CL_Regex;                   /**< The CL_Regex object: an optimised regular expression. */
typedef struct _CL_BitVec *CL_BitVec;                 /**< The CL_BitVec object: doesn't seem to exist {???-- AH}. */

/**
 * The CorpusProperty object.
 *
 * The underlying structure takes the form of a linked-list entry.
 *
 * Each Corpus object has, as one of its members, the head entry
 * on a list of CorpusProperties.
 */
typedef struct TCorpusProperty {
  /** A string specifying the property in question. */
  char *property;
  /** A string containing the value of the property in question. */
  char *value;
  /** Pointer to the next entry in the linked list. */
  struct TCorpusProperty *next;
} *CorpusProperty;

/**
 * Identifier for one of the character sets supported by CWB.
 */
typedef enum ECorpusCharset {
  ascii,
  /* planned support for ISO-8859-* charsets */
  /* latin1 = 8859-1, latin2 = 8859-2, latin3 = 8859-3, latin4 = 8859-4, cyrillic = 8859-5,
     arabic = 8859-6, greek = 8859-7, hebrew = 8859-8, latin5 = 8859-9, latin6 = 8859-10,
     latin7 = 8859-13, latin8 = 8859-14, latin9 = 8859-15 */
  latin1, latin2, latin3, latin4, cyrillic,
  arabic, greek,  hebrew, latin5, latin6,
  latin7, latin8, latin9,
  /* hoped-for support for UTF-8 charset */
  utf8,
  /* everything else is 'unknown' .. client apps should check the corresponding property value */
  unknown_charset
} CorpusCharset;


/**
 *  maximum size of 'dynamic' strings
 */
#define CL_DYN_STRING_SIZE 2048

/**
 *  The DynCallResult object (needed to allocate space for dynamic function arguments)
 */
typedef struct _DCR {
  int type;              /**< Type of DynCallResult, indicated by one of the  ATTAT_x macro constants*/
  union {
    int intres;
    char *charres;
    double floatres;
    struct {
      Attribute *attr;
      int token_id;
    } parefres;
  } value;               /**< value of the result: can be in, string, float, or p-attribute reference */
  /**
   * buffer for dynamic strings returned by function calls
   * NB: this imposes a hard limit on the size of dynamic strings !!
   * @see CL_DYN_STRING_SIZE
   */
  char dynamic_string_buffer[CL_DYN_STRING_SIZE]; 
} DynCallResult;

/* attribute types */
#define ATT_NONE       0
/** Positional attributes, ie streams of word tokens, word tags - any "column" that has a value at every corpus position. */
#define ATT_POS        (1<<0)
/** Structural attributes, ie a set of SGML/XML-ish "regions" in the corpus delimited by the same SGML/XML tag */
#define ATT_STRUC      (1<<1)
/** Alignment attributes, ie a set of zones of alignment between a source and target corpus */
#define ATT_ALIGN      (1<<2)
/** Dynamic attributes, ?? */
#define ATT_DYN        (1<<6)

/** shorthand for "all types of attribute" */
#define ATT_ALL        ATT_POS   | ATT_STRUC | ATT_ALIGN | ATT_DYN
/** shorthand for "all types of attribute except dynamic" */
#define ATT_REAL       ATT_POS   | ATT_STRUC | ATT_ALIGN 

/* result and argument types of dynamic attributes */
#define ATTAT_NONE    0
#define ATTAT_POS     1
#define ATTAT_STRING  2
#define ATTAT_INT     3
#define ATTAT_VAR     4                /* variable number of string arguments (only in arglist) */
#define ATTAT_FLOAT   5
#define ATTAT_PAREF   6

/* regular expression flags for cl_regex2id */
/**
 * Flag ignore-case in regular expression matching.
 * @see cl_regex2id
 */
#define IGNORE_CASE 1
/**
 * Flag ignore-diacritics in regular expression matching.
 * @see cl_regex2id
 */
#define IGNORE_DIAC 2
/**
 * Flag for: don't use regular expression matching - match as a literal string.
 * Not used in the CL but in use in CQP.
 */
#define IGNORE_REGEX 4

/* flags set in return values of cl_cpos2boundary() function */
#define STRUC_INSIDE 1  /**< cl_cpos2boundary() return flag: specified position is WITHIN a region of this s-attribute */
#define STRUC_LBOUND 2  /**< cl_cpos2boundary() return flag: specified position is AT THE START BOUNDARY OF a region of this s-attribute */
#define STRUC_RBOUND 4  /**< cl_cpos2boundary() return flag: specified position is AT THE END BOUNDARY OF a region of this s-attribute */



/* 
 *  error handling (error values and related functions) 
 */
#define CDA_OK           0        /**< everything fine; error values all less than 0 */
#define CDA_ENULLATT    -1        /**< NULL passed as attribute argument */
#define CDA_EATTTYPE    -2        /**< function was called on illegal attribute */
#define CDA_EIDORNG     -3        /**< id out of range */
#define CDA_EPOSORNG    -4        /**< position out of range */
#define CDA_EIDXORNG    -5        /**< index out of range */
#define CDA_ENOSTRING   -6        /**< no such string encoded */
#define CDA_EPATTERN    -7        /**< illegal pattern */
#define CDA_ESTRUC      -8        /**< no structure at position */
#define CDA_EALIGN      -9        /**< no alignment at position */
#define CDA_EREMOTE     -10       /**< error in remote access */
#define CDA_ENODATA     -11       /**< can't load/create necessary data */
#define CDA_EARGS       -12       /**< error in arguments for dynamic call */
#define CDA_ENOMEM      -13       /**< memory fault [unused] */
#define CDA_EOTHER      -14       /**< other error */
#define CDA_ENYI        -15       /**< not yet implemented */
#define CDA_EBADREGEX   -16       /**< bad regular expression */
#define CDA_EFSETINV    -17       /**< invalid feature set format */
#define CDA_EBUFFER     -18       /**< buffer overflow (hard-coded internal buffer sizes) */
#define CDA_EINTERNAL   -19       /**< internal data consistency error (really bad) */

extern int cderrno;

/* these are old-style-API prototypes... */
void cdperror(char *message);
char *cdperror_string(int error_num);



/*
 * easy memory management functions
 *
 * use the following memory allocation functions instead of malloc(), calloc(), realloc(), strdup()
 * in your own programs to invoke the CL's memory manager when necessary
 */
void *cl_malloc(size_t bytes);
void *cl_calloc(size_t nr_of_elements, size_t element_size);
void *cl_realloc(void *block, size_t bytes);
char *cl_strdup(char *string);
/**
 * Safely frees memory.
 *
 * @see cl_malloc
 * @param p  Pointer to memory to be freed.
 */
#define cl_free(p) do { if ((p) != NULL) { free(p); p = NULL; } } while (0)
/* the do {...} while (0) should be safe in 'bare' if..then..else blocks */



/*
 *  some CL utility functions
 */

int cl_strcmp(char *s1, char *s2);

/* string normalization features used by CL regexes and CQP (modify input string!) */
void cl_string_canonical(char *s, int flags);  /* modifies string <s> in place; flags are IGNORE_CASE and IGNORE_DIAC */
char *cl_string_latex2iso(char *str, char *result, int target_len); 
/* <result> points to buffer of appropriate size; auto-allocated if NULL; 
   str == result is explicitly allowed; conveniently returns <result> */

unsigned char *cl_string_maptable(CorpusCharset charset /*ignored*/, int flags);
/* returns pointer to static mapping table for given flags (IGNORE_CASE and IGNORE_DIAC) and character set */

/* built-in support for handling feature set attributes */
char *cl_make_set(char *s, int split);
int cl_set_size(char *s);
int cl_set_intersection(char *result, const char *s1, const char *s2);



/* CL front-end to POSIX regular expressions with CL semantics (always matches entire string);
   implements case-/diacritic-insensitive matching and optimisations */
CL_Regex cl_new_regex(char *regex, int flags, CorpusCharset charset /*ignored*/);
int cl_regex_optimised(CL_Regex rx); /* 0 = not optimised; otherwise, value indicates level of optimisation */
int cl_regex_match(CL_Regex rx, char *str); /* automatically uses normalisation flags from constructor; returns True when regex matches */
void cl_delete_regex(CL_Regex rx);
extern char cl_regex_error[];



/* built-in random number generator (RNG) */
void cl_set_seed(unsigned int seed);
void cl_randomize(void);
void cl_get_rng_state(unsigned int *i1, unsigned int *i2);
void cl_set_rng_state(unsigned int i1, unsigned int i2);
unsigned int cl_random(void);
double cl_runif(void);



/**
 *  The cl_lexhash class (lexicon hashes, with IDs and frequency counts)
 *
 *  A "lexicon hash" links strings to integers. Each cl_lexhash object
 *  represents an entire table of such things; individual string-to-int
 *  links are represented by cl_lexhash_entry objects.
 *
 *  Within the cl_lexhash, the entries are grouped into buckets. A
 *  bucket is the term for a "slot" on the hash table. The linked-list
 *  in a given bucket represent all the different string-keys that map
 *  to one particular index value.
 *
 *  Each entry contains the key itself (for search-and-retrieval),
 *  the frequency of that type (incremented when a token is added that
 *  is already in the lexhash), an ID integer, plus a bundle of "data"
 *  associated with that string.
 *
 *  These lexicon hashes are used, notably, in the encoding of corpora
 *  to CWB-index-format.
 */
typedef struct _cl_lexhash *cl_lexhash;
/**
 * Underlying structure for the cl_lexhash_entry class.
 */
typedef struct _cl_lexhash_entry {
  char *key;                        /**< hash key == token */
  unsigned int freq;                /**< frequency of this type */
  int id;                           /**< the id code of this type */
  /**
   * This entry's data fields.
   * Use as entry->data.integer, entry->data.numeric, ...
   */
  struct _cl_lexhash_entry_data {
    int integer;
    double numeric;
    void *pointer;
  } data;
  struct _cl_lexhash_entry *next;   /**< next entry on the linked-list (ie in the bucket) */
} *cl_lexhash_entry;

/*
 * ... and ... its API!!
 */
cl_lexhash cl_new_lexhash(int buckets);
void cl_delete_lexhash(cl_lexhash lh);
void cl_lexhash_set_cleanup_function(cl_lexhash lh, void (*func)(cl_lexhash_entry));
void cl_lexhash_auto_grow(cl_lexhash lh, int flag);
cl_lexhash_entry cl_lexhash_add(cl_lexhash lh, char *token);
cl_lexhash_entry cl_lexhash_find(cl_lexhash lh, char *token);
int cl_lexhash_id(cl_lexhash lh, char *token);
int cl_lexhash_freq(cl_lexhash lh, char *token);
int cl_lexhash_del(cl_lexhash lh, char *token);
int cl_lexhash_size(cl_lexhash lh);


/**
 * automatically growing list of integers (just what you always need ...)
 */
typedef struct _cl_int_list    *cl_int_list;
/**
 * automatically growing list of strings (just what you always need ...)
 */
typedef struct _cl_string_list *cl_string_list;

cl_int_list cl_new_int_list(void);                           /* create int list object */
void cl_delete_int_list(cl_int_list l);                      /* delete int list object */
void cl_int_list_lumpsize(cl_int_list l, int s);             /* memory for the list is allocated in "lumps", default size is 64 entries */
int cl_int_list_size(cl_int_list l);                         /* current size of list */
int cl_int_list_get(cl_int_list l, int n);                   /* get value of n-th element in list (0 if out of range) */
void cl_int_list_set(cl_int_list l, int n, int val);         /* set n-th element (automatically extends list) */
void cl_int_list_append(cl_int_list l, int val);             /* append element to list */
void cl_int_list_qsort(cl_int_list l);                       /* sort list (ascending order) */

cl_string_list cl_new_string_list(void);                     /* create string list object */
void cl_delete_string_list(cl_string_list l);                /* delete string list object */
void cl_free_string_list(cl_string_list l);                  /* free() all strings in list (use with care!) */
void cl_string_list_lumpsize(cl_string_list l, int s);       /* memory for the list is allocated in "lumps", default size is 64 entries */
int cl_string_list_size(cl_string_list l);                   /* current size of list */
char *cl_string_list_get(cl_string_list l, int n);           /* get value of n-th element in list (NULL if out of range) */
void cl_string_list_set(cl_string_list l, int n, char *val); /* set n-th element (does NOT make copy of string!) */
void cl_string_list_append(cl_string_list l, char *val);     /* append element to list */
void cl_string_list_qsort(cl_string_list l);                 /* sort list (using cl_strcmp()) */


/* 
 *  global CL configuration options 
 */
void cl_set_debug_level(int level);       /* 0 = none (default), 1 = some, 2 = all */
void cl_set_optimize(int state);          /* 0 = off, 1 = on */
void cl_set_memory_limit(int megabytes);  /* 0 or less turns limit off */



/*
 *  CL corpus and attribute 'methods' -- the CL core library
 */
/* new style function names (implemented as macros mapping to the old names) */
#define cl_errno cderrno
#define cl_error(message) cdperror(message)
#define cl_error_string(no) cdperror_string(no)
#define cl_new_corpus(reg, name) setup_corpus(reg, name)
#define cl_delete_corpus(c) drop_corpus(c)
#define cl_standard_registry() central_corpus_directory()
CorpusProperty cl_first_corpus_property(Corpus *corpus);
CorpusProperty cl_next_corpus_property(CorpusProperty p);
char *cl_corpus_property(Corpus *corpus, char *property);
CorpusCharset cl_corpus_charset(Corpus *corpus);
char *cl_charset_name(CorpusCharset id);
CorpusCharset cl_charset_from_name(char *name);
char *cl_charset_name_canonical(char *name_to_check);
#define cl_new_attribute(c, name, type) find_attribute(c, name, type, NULL)
#define cl_delete_attribute(a) attr_drop_attribute(a)
#define cl_sequence_compressed(a) item_sequence_is_compressed(a)
#define cl_index_compressed(a) inverted_file_is_compressed(a)
#define cl_new_stream(a, id) OpenPositionStream(a, id)
#define cl_delete_stream(ps) ClosePositionStream(ps)
#define cl_read_stream(ps, buf, size) ReadPositionStream(ps, buf, size)
#define cl_id2str(a, id) get_string_of_id(a, id)
#define cl_str2id(a, str) get_id_of_string(a, str)
#define cl_id2strlen(a, id) get_id_string_len(a, id)
#define cl_sort2id(a, sid) get_id_from_sortidx(a, sid)
#define cl_id2sort(a, id) get_sortidxpos_of_id(a, id)
#define cl_max_cpos(a) get_attribute_size(a)
#define cl_max_id(a) get_id_range(a)
#define cl_id2freq(a, id) get_id_frequency(a, id)
#define cl_id2cpos(a, id, freq) get_positions(a, id, freq, NULL, 0)
#define cl_cpos2id(a, cpos) get_id_at_position(a, cpos)
#define cl_cpos2str(a, cpos) get_string_at_position(a, cpos)
#define cl_id2all(a, sid, freq, len) get_id_info(a, sid, freq, len)
#define cl_regex2id(a, re, flags, size) collect_matching_ids(a, re, flags, size)
#define cl_idlist2freq(a, list, size) cumulative_id_frequency(a, list, size)
#define cl_idlist2cpos(a, idlist, idlist_size, sort, size) collect_matches(a, idlist, idlist_size, sort, size, NULL, 0)
#define cl_cpos2struc2cpos(a, cpos, start, end) get_struc_attribute(a, cpos, start, end)
int cl_cpos2struc(Attribute *a, int cpos);  /* normalised to standard return value behaviour */
int cl_cpos2boundary(Attribute *a, int cpos);  /* convenience function: within region or at boundary? */
#define cl_struc2cpos(a, struc, start, end) get_bounds_of_nth_struc(a, struc, start, end)
int cl_max_struc(Attribute *a);             /* normalised to standard return value behaviour */
#define cl_struc_values(a) structure_has_values(a)
#define cl_struc2str(a, struc) structure_value(a, struc)
#define cl_cpos2struc2str(a, cpos) structure_value_at_position(a, cpos)
/* extended alignment attributes (with fallback to old alignment */
int cl_has_extended_alignment(Attribute *attribute);
int cl_max_alg(Attribute *attribute);
int cl_cpos2alg(Attribute *attribute, int cpos);
int cl_alg2cpos(Attribute *attribute, int alg,
                int *source_region_start, int *source_region_end,
                int *target_region_start, int *target_region_end);





/*
 * Old-style API for the core CL functions -- deprecated as of v3.0
 */

/* corpus access functions */
Corpus *find_corpus(char *registry_dir, char *registry_name);
Corpus *setup_corpus(char *registry_dir, char *registry_name);
int drop_corpus(Corpus *corpus);
void describe_corpus(Corpus *corpus);
char *central_corpus_directory();


/* attribute access functions: general functions */
Attribute *find_attribute(Corpus *corpus, 
                          char *attribute_name,
                          int type,
                          char *data);        /* *** UNUSED *** */
int attr_drop_attribute(Attribute *attribute);
int item_sequence_is_compressed(Attribute *attribute);
int inverted_file_is_compressed(Attribute *attribute);

/* attribute access functions: position streams */
PositionStream OpenPositionStream(Attribute *attribute, int id);
int ClosePositionStream(PositionStream *ps);
int ReadPositionStream(PositionStream ps,
                       int *buffer,
                       int buffer_size);

/* attribute access functions: lexicon access (positional attributes) */
char *get_string_of_id(Attribute *attribute, int id);
int get_id_of_string(Attribute *attribute, char *id_string);
int get_id_string_len(Attribute *attribute, int id);
int get_id_from_sortidx(Attribute *attribute, int sort_index_position);
int get_sortidxpos_of_id(Attribute *attribute, int id);


/* attribute access functions: size (positional attributes) */
int get_attribute_size(Attribute *attribute);
int get_id_range(Attribute *attribute);


/* attribute access functions: token sequence & index (positional attributes) */
int get_id_frequency(Attribute *attribute, int id);

int *get_positions(Attribute *attribute, 
                   int id,
                   int *freq,
                   int *restrictor_list,
                   int restrictor_list_size);

int get_id_at_position(Attribute *attribute, int position);
char *get_string_at_position(Attribute *attribute, int position);

/* ========== some high-level constructs */

char *get_id_info(Attribute *attribute,
                  int index, int *freq, int *slen);


int *collect_matching_ids(Attribute *attribute, 
                          char *pattern,
                          int canonicalize,
                          int *number_of_matches);

int cumulative_id_frequency(Attribute *attribute,
                            int *ids,
                            int number_of_ids);



int *collect_matches(Attribute *attribute,
                     int *ids,
                     int number_of_ids,
                     int sort,
                     int *size_of_table,
                     int *restrictor_list,
                     int restrictor_list_size);


/* attribute access functions: structural attributes */
int get_struc_attribute(Attribute *attribute, 
                        int position,
                        int *struc_start,
                        int *struc_end);
int get_num_of_struc(Attribute *attribute,
                     int position,
                     int *struc_num);
int get_bounds_of_nth_struc(Attribute *attribute,
                            int struc_num,
                            int *struc_start,
                            int *struc_end);
int get_nr_of_strucs(Attribute *attribute,
                     int *nr_strucs);
int structure_has_values(Attribute *attribute);
char *structure_value(Attribute *attribute, int struc_num);
char *structure_value_at_position(Attribute *attribute, int position);


/* attribute access functions: alignment attributes (old style)*/
int get_alg_attribute(Attribute *attribute, 
                      int position,
                      int *aligned_start,
                      int *aligned_end,
                      int *aligned_start2,
                      int *aligned_end2);

/* attribute access functions: dynamic attributes (N/A) */

/* ...: parameters (of *int or *char) and structure
 * which gets the result (*int or *char)
 */
int call_dynamic_attribute(Attribute *attribute,
                           DynCallResult *dcr,
                           DynCallResult *args,
                           int nr_args);
int nr_of_arguments(Attribute *attribute);




#endif
