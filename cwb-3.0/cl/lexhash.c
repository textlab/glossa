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
#include "macros.h"
#include "lexhash.h"


/** Defines the default number of buckets in a lexhash. */
#define DEFAULT_NR_OF_BUCKETS 250000

/** The update interval for hash performance estimation. */
#define PERFORMANCE_COUNT 1000

/** The default value for the performance limit (avg no of comparisons) before the hash is expanded. */
#define DEFAULT_PERFORMANCE_LIMIT 10



/*
 * basic utility functions
 */

/** Returns True iff n is a prime */
int 
is_prime(int n) {
  int i;
  for(i = 2; i*i <= n; i++)
    if ((n % i) == 0) 
      return 0;
  return 1;
}

/** Returns smallest prime >= n */
int 
find_prime(int n) {
  for( ; n > 0 ; n++)           /* will exit on int overflow */
    if (is_prime(n)) 
      return n;
  return 0;
}

/** Computes 32bit hash value for string */
unsigned int 
hash_string(char *string) {
  unsigned char *s = (unsigned char *)string;
  unsigned int result = 0;
  for( ; *s; s++)
    result = (result * 33 ) ^ (result >> 27) ^ *s;
  return result;
}


/*
 * cl_lexhash / cl_lexhash_entry  object definition
 */


/* cl_lexhash_entry now in <cl.h> */

/**
 * A function pointer type defining functions that can be used as the "cleanup" for a deleted cl_lexhash_entry.
 * @see cl_lexhash_set_cleanup_function
 */
typedef void (*cl_lexhash_cleanup_func)(cl_lexhash_entry);

/* typedef struct _cl_lexhash *cl_lexhash; in <cl.h> */


/**
 * Underlying structure for the cl_lexhash object.
 *
 * A cl_lexhash contains a number of buckets. Each bucket is
 * a linked-list of cl_lexhash_entry objects.
 *
 */
struct _cl_lexhash {
  cl_lexhash_entry *table;      /**< table of buckets; each "bucket" is a pointer to the list of entries that make up that bucket */
  unsigned int buckets;         /**< number of buckets in the list */
  int next_id;                  /**< ID that will be assigned to next new entry */
  int entries;                  /**< current number of entries in this hash */
  cl_lexhash_cleanup_func cleanup_func; /**< callback function used when deleting entries (see cl.h) */
  int performance_counter;      /**< a variable used for estimating hash performance (avg no of comparisons) */
  int comparisons;              /**< a variable used for estimating hash performance (avg no of comparisons) */
  double last_performance;      /**< a variable used for estimating hash performance (avg no of comparisons) */
  int auto_grow;                /**< boolean: whether to expand this hash automatically; true by default */
};


/*
 * cl_lexhash methods
 */

/**
 * Creates a new cl_lexhash object.
 *
 * @param buckets    The number of buckets in the newly-created cl_lexhash; set to 0 to use the
 *                   default number of buckets.
 * @return           The new cl_lexhash.
 */
cl_lexhash 
cl_new_lexhash(int buckets)
{
  cl_lexhash hash;
  
  if (buckets <= 0) buckets = DEFAULT_NR_OF_BUCKETS;
  hash = (cl_lexhash) cl_malloc(sizeof(struct _cl_lexhash));
  hash->buckets = find_prime(buckets);
  hash->table = cl_calloc(hash->buckets, sizeof(cl_lexhash_entry));
  hash->next_id = 0;
  hash->entries = 0;
  hash->cleanup_func = NULL;
  hash->performance_counter = PERFORMANCE_COUNT;
  hash->comparisons = 0;
  hash->last_performance = 0.0;
  hash->auto_grow = 1;
  return hash;
}


/**
 * Deallocates a cl_lexhash_entry object and its key string.
 *
 * Also, the cleanup function is run on the entry.
 *
 * Usage: cl_delete_lexhash_entry(lexhash, entry);
 *
 * This is a non-exported function.
 *
 * @see          cl_lexhash_set_cleanup_function
 * @param hash   The lexhash this entry belongs to (needed to
 *               locate the cleanup function, if any).
 * @param entry  The entry to delete.
 */
void
cl_delete_lexhash_entry(cl_lexhash hash, cl_lexhash_entry entry)
{
  if (hash != NULL) {
    /* if necessary, let cleanup callback delete objects associated with the data field */
    if (hash->cleanup_func != NULL) {
      (*(hash->cleanup_func))(entry);
    }
    cl_free(entry->key);
    cl_free(entry);
  }
}

/**
 * Deletes a cl_lexhash object.
 *
 * This deletes all the entries in all the buckets in the lexhash,
 * plus the cl_lexhash itself.
 *
 * @param hash  The cl_lexhash to delete.
 */
void 
cl_delete_lexhash(cl_lexhash hash)
{
  int i;
  cl_lexhash_entry entry, temp;
  
  if (hash != NULL && hash->table != NULL) {
    for (i = 0; i < hash->buckets; i++) {
      entry = hash->table[i];
      while (entry != NULL) {
        temp = entry;
        entry = entry->next;
        cl_delete_lexhash_entry(hash, temp);
      }
    }
  }
  cl_free(hash->table);
  cl_free(hash);
}


/**
 * Sets the cleanup function for a cl_lexhash.
 *
 * The cleanup function is called with a cl_lexhash_entry argument;
 * it should delete any objects assocated with the entry's data field.
 *
 * The cleanup function is initially set to NULL, i.e. run no function.
 *
 * @param hash  The cl_lexhash to work with.
 * @param func  Pointer to the function to use for cleanup.
 */
void
cl_lexhash_set_cleanup_function(cl_lexhash hash, cl_lexhash_cleanup_func func)
{
  if (hash != NULL)
    hash->cleanup_func = func;
}

/**
 * Turns a cl_lexhash's ability to autogrow on or off.
 *
 * When this setting is switched on, the lexhash will grow
 * automatically to avoid performance degradation.
 *
 * Note the default value for this setting is SWITCHED ON.
 *
 * @see         cl_lexhash_check_grow
 * @param hash  The hash that will be affected.
 * @param flag  New value for autogrow setting: boolean where
 *              true is on and false is off.
 */
void
cl_lexhash_auto_grow(cl_lexhash hash, int flag)
{
  if (hash != NULL)
    hash->auto_grow = flag;
}



/**
 * Grows a lexhash table, increasing the number of buckets, if necessary.
 *
 * This function checks whether growing the hash is necessary by updating
 * the performance estimate. If it is above the threshold, and auto_grow
 * is enabled, then the hashes is expanded by increasing the number of
 * buckets, such that the average fill rate is 1 (i.e. 1 lexhash_entry per
 * bucket, 1 lexhash index == 1 key-string ... on average). This gives the
 * hash better performance and makes it capable of absorbing more keys.
 *
 * Note: this function also implements the hashing algorithm and must be
 * consistent with cl_lexhash_find_i().
 *
 * Usage: expanded = cl_lexhash_check_grow(cl_lexhash hash);
 *
 * This is a non-exported function.
 *
 * @param hash  The lexhash to autogrow.
 * @return      Always 0.
 */
int
cl_lexhash_check_grow(cl_lexhash hash)
{
  double fill_rate = ((double) hash->entries) / hash->buckets;
  cl_lexhash temp;
  cl_lexhash_entry entry, next;
  int idx, offset, old_buckets, new_buckets;

  hash->last_performance = ((double) hash->comparisons) / PERFORMANCE_COUNT;
  if (hash->auto_grow && (hash->last_performance > DEFAULT_PERFORMANCE_LIMIT)) {
    if (cl_debug) {
      fprintf(stderr, "[lexhash autogrow: (perf = %3.1f  @ fill rate = %3.1f (%d/%d)]\n",
              hash->last_performance, fill_rate, hash->entries, hash->buckets);
    }
    if (fill_rate < 2.0) {
      /* there are, on average, less than two entries per bucket. */
      if (cl_debug)
        fprintf(stderr, "[autogrow aborted because of low fill rate]\n");
      return 0;
    }
    temp = cl_new_lexhash(hash->entries); /* create new hash with fill rate == 1.0 */
    old_buckets = hash->buckets;
    new_buckets = temp->buckets; /* will be a prime number >= hash->entries */
    /* move all entries from hash to the appropriate bucket in temp */
    for (idx = 0; idx < old_buckets; idx++) {
      entry = hash->table[idx];
      while (entry != NULL) {
        next = entry->next;     /* remember pointer to next entry */
        offset = hash_string(entry->key) % new_buckets;
        entry->next = temp->table[offset]; /* insert entry into its bucket in temp (most buckets should contain only 1 entry) */
        temp->table[offset] = entry;
        temp->entries++;
        entry = next;           /* continue while loop */
      }
    }
    assert((temp->entries == hash->entries) && "lexhash.c: inconsistency during hash expansion");
    cl_free(hash->table);               /* old hash table should be empty and can be deallocated */
    hash->table = temp->table;          /* update hash from temp (copy hash table and its size) */
    hash->buckets = temp->buckets;
    hash->last_performance = 0.0;       /* reset performance estimate */
    cl_free(temp);                      /* we can simply deallocate temp now, having stolen its hash table */
    if (cl_debug) {
      fill_rate = ((double) hash->entries) / hash->buckets;
      fprintf(stderr, "[grown to %d buckets  @ fill rate = %3.1f (%d/%d)]\n",
              hash->buckets, fill_rate, hash->entries, hash->buckets);
    }
  }
  return 0;
}



/**
 * Finds the entry corresponding to a particular string in a cl_lexhash.
 *
 * This function is the same as cl_lexhash_find(), but *ret_offset is set to
 * the hashtable offset computed for token (i.e. the index of the bucket within
 * the hashtable), unless *ret_offset == NULL.
 *
 * Note that this function hides the hashing algorithm details from the
 * rest of the lexhash implementation.
 *
 * Usage: entry = cl_lexhash_find_i(cl_lexhash hash, char *token, unsigned int *ret_offset);
 *
 * This is a non-exported function.
 *
 * @param hash        The hash to search.
 * @param token       The key-string to look for.
 * @param ret_offset  This integer address will be filled with the token's
 *                    hashtable offset.
 * @return            The entry that is found (or NULL if the string is not
 *                    in the hash).
 */
cl_lexhash_entry
cl_lexhash_find_i(cl_lexhash hash, char *token, unsigned int *ret_offset)
{
  unsigned int offset;
  cl_lexhash_entry entry;

  assert((hash != NULL && hash->table != NULL && hash->buckets > 0) && "cl_lexhash object was not properly initialised");
  /* get the offset of the bucket to look in by computing the hash of the string */
  offset = hash_string(token) % hash->buckets;
  if (ret_offset != NULL)
    *ret_offset = offset;
  entry = hash->table[offset];
  if (entry != NULL) 
    hash->comparisons++;        /* will need one comparison at least */
  while (entry != NULL && strcmp(entry->key, token) != 0) {
    entry = entry->next;
    hash->comparisons++;        /* this counts additional comparisons */
  }
  hash->performance_counter--;
  if (hash->performance_counter <= 0) {
    if (cl_lexhash_check_grow(hash)) 
      entry = cl_lexhash_find_i(hash, token, ret_offset); /* if hash was expanded, need to recompute offset */
    hash->performance_counter = PERFORMANCE_COUNT;
    hash->comparisons = 0;
  }
  return entry;
}


/**
 * Finds the entry corresponding to a particular string within a cl_lexhash.
 *
 * @param hash        The hash to search.
 * @param token       The key-string to look for.
 * @return            The entry that is found (or NULL if the string is not
 *                    in the hash).
 */
cl_lexhash_entry
cl_lexhash_find(cl_lexhash hash, char *token)
{
  return cl_lexhash_find_i(hash, token, NULL);
}



/**
 * Adds a token to a cl_lexhash table.
 *
 * If the string is already in the hash, its frequency count
 * is increased by 1.
 *
 * Otherwise, a new entry is created, with an auto-assigned ID;
 * note that the string is duplicated, so the original string
 * that is passed to this function does not need ot be kept in
 * memory.
 *
 * @param hash   The hash table to add to.
 * @param token  The string to add.
 * @return       A pointer to a (new or existing) entry
 */
cl_lexhash_entry
cl_lexhash_add(cl_lexhash hash, char *token)
{
  cl_lexhash_entry entry, insert_point;
  unsigned int offset;          /* this will be set to the index of the bucket this token should go in
                                   by the call to cl_lexhash_find_i                                     */
  
  entry = cl_lexhash_find_i(hash, token, &offset);
  if (entry != NULL) {
    /* token already in hash -> increment frequency count */
    entry->freq++;
    return entry;
  }
  else {
    /* add new entry for this token */
    entry = (cl_lexhash_entry) cl_malloc(sizeof(struct _cl_lexhash_entry));
    entry->key = cl_strdup(token);
    entry->freq = 1;
    entry->id = (hash->next_id)++;
    entry->data.integer = 0;            /* initialise data fields to zero values */
    entry->data.numeric = 0.0;
    entry->data.pointer = NULL;
    entry->next = NULL;
    insert_point = hash->table[offset]; /* insert entry into its bucket in the hash table */
    if (insert_point == NULL) {
      hash->table[offset] = entry;      /* only entry in this bucket so far */
    }
    else { /* always insert as last entry in its bucket (because of Zipf's Law:
              frequent lexemes tend to occur early in the corpus and should be first in their buckets for faster access) */
      while (insert_point->next != NULL)
        insert_point = insert_point->next;
      insert_point->next = entry;
    }
    hash->entries++;
    return entry;
  }
}

/* returns ID of <token>, -1 if not in hash */

/**
 * Gets the ID of a particular string within a lexhash.
 *
 * Note this is the ID integer that identifies THAT
 * PARTICULAR STRING, not the hash value of that string -
 * which only identifies the bucket the string is
 * found in!
 *
 * @param hash   The hash to look in.
 * @param token  The string to look for.
 * @return       The ID code of that string, or -1
 *               if the string is not in the hash.
 */
int 
cl_lexhash_id(cl_lexhash hash, char *token)
{
  cl_lexhash_entry entry;

  entry = cl_lexhash_find_i(hash, token, NULL);
  return (entry != NULL) ? entry->id : -1;
} 


/**
 * Gets the frequency of a particular string within a lexhash.
 *
 * @param hash   The hash to look in.
 * @param token  The string to look for.
 * @return       The frrequency of that string, or 0
 *               if the string is not in the hash
 *               (whgich is, of course, actually its frequency).
 */
int 
cl_lexhash_freq(cl_lexhash hash, char *token)
{
  cl_lexhash_entry entry;

  entry = cl_lexhash_find_i(hash, token, NULL);
  return (entry != NULL) ? entry->freq : 0;
} 

/* deletes <token> from hash & returns its frequency */
/**
 * Deletes a string from a hash.
 *
 * The entry corresponding to the specified string is
 * removed from the lexhash. If the string is not in the
 * lexhash to begin with, no action is taken.
 *
 * @param hash   The hash to alter.
 * @param token  The string to remove.
 * @return       The frequency of the deleted entry.
 */
int 
cl_lexhash_del(cl_lexhash hash, char *token)
{
  cl_lexhash_entry entry, previous;
  unsigned int offset, f;

  entry = cl_lexhash_find_i(hash, token, &offset);
  if (entry == NULL) {
    return 0;                   /* not in lexhash */
  }
  else {
    f = entry->freq;
    if (hash->table[offset] == entry) {
      hash->table[offset] = entry->next;
    }
    else {
      previous = hash->table[offset];
      while (previous->next != entry)
        previous = previous->next;
      previous->next = entry->next;
    }
    cl_delete_lexhash_entry(hash, entry);
    hash->entries--;
    return f;
  }
}



/**
 * Gets the number of different strings stored in a lexhash.
 *
 * This returns the total number of entries in all the
 * bucket linked-lists in the whole hashtable.
 *
 * @param hash  The hash to size up.
 */
int 
cl_lexhash_size(cl_lexhash hash)
{
  cl_lexhash_entry entry;
  int i, size = 0;

  assert((hash != NULL && hash->table != NULL && hash->buckets > 0) && "cl_lexhash object was not properly initialised");
  for (i = 0; i < hash->buckets; i++) {
    entry = hash->table[i];
    while (entry != NULL) {
      size++;
      entry = entry->next;
    }
  }

  return size;
}
