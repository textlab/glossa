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

#include <ctype.h>
#include <sys/types.h>


#include "globals.h"

#include "endian.h"
#include "macros.h"
#include "storage.h"
#include "fileutils.h"
#include "corpus.h"
#include "attributes.h"
#include "cdaccess.h"

#include "makecomps.h"


#define BUFSIZE 0x10000

/* seems not ever to be used? */
char errmsg[MAX_LINE_LENGTH];



/* ------------------------------------------------------------ SORTED LEXICONS */


static MemBlob *SortLexicon;
static MemBlob *SortIndex;


/**
 * Sorts two lexicon entries using cl_strcmp.
 *
 * This function is for use with qsort().
 */
static int scompare(const void *idx1, const void *idx2)
{
  /* this is the way qsort(..) is meant to be used: give it void*
     and cast them to the actual type in the compare function;
     the definition below conforms to ANSI and POSIX standards according to the LDP */
  return
    cl_strcmp((char *) SortLexicon->data + ntohl(SortIndex->data[*(int *)idx1]),
              (char *) SortLexicon->data + ntohl(SortIndex->data[*(int *)idx2]));
}


/* note, the following functions are documented in attributes.c (a general overview)
 * in the context of the create_component() function that calls them */

/* note: these functions aren't guaranteed to load the component after creating it! */
/* (in fact, creat_rev_corpus() would run out of address space if it tried that on a large corpus) */

/**
 * creates a sort index.
 *
 * @see create_component
 */
int
creat_sort_lexicon(Component *lexsrt)
{
  int i;

  Component *lex;
  Component *lexidx;

  assert(lexsrt && "creat_sort_lexicon called with NULL component");
  assert(lexsrt->attribute && "attribute of component is null");

  assert(comp_component_state(lexsrt) == ComponentDefined);

  lex = ensure_component(lexsrt->attribute, CompLexicon, 1);
  lexidx = ensure_component(lexsrt->attribute, CompLexiconIdx, 1);

  assert(lex != NULL);
  assert(lexidx != NULL);

  assert(lexsrt->path != NULL);
  assert(lexidx->data.size > 0);
  assert(lexidx->data.data != NULL);

  if (!read_file_into_blob(lexidx->path, MALLOCED, sizeof(int), &(lexsrt->data))) {
    fprintf(stderr, "Can't open %s, can't create lexsrt component\n", lexidx->path);
    perror(lexidx->path);
    return 0;
  }

  assert(lexidx->data.size == lexsrt->data.size);
  assert(lexidx->data.nr_items == lexsrt->data.nr_items);
  assert(lexidx->data.item_size == lexsrt->data.item_size);

  lexsrt->size = lexidx->size;

  /* fill the area with ascending indices */
  for (i = 0; i < lexsrt->data.nr_items; i++)
    lexsrt->data.data[i] = i;

  /* now sort the area */

  SortLexicon = &(lex->data);                /* for the comparison function */
  SortIndex = &(lexidx->data);

  qsort(lexsrt->data.data, lexsrt->size, sizeof(int), scompare);

  if (write_file_from_blob(lexsrt->path, &(lexsrt->data), 1)) {

    /* ok, we now have to convert the table to NETWORK order in case
     * other (later) steps rely on its format. */

    /* convert network byte order to native integers */
    for (i = 0; i < lexsrt->data.nr_items; i++)
      lexsrt->data.data[i] = htonl(lexsrt->data.data[i]);

    return 1;
  }
  else
    return 0;
}


/**
 * creates frequency table
 *
 * @see create_component
 */
int
creat_freqs(Component *freqs)
{
  FILE *fd;
  int mc_buf[BUFSIZE];

  char *corpus_fn;

  int i, k, ptr;

  /*  read the lexicon into memory */
  Component *lexidx = ensure_component(freqs->attribute, CompLexiconIdx, 1);

  assert(freqs != NULL);
  assert(freqs->data.data == NULL);

  assert(lexidx != NULL);

  if (freqs->id != CompCorpusFreqs) {
    freqs = find_component(freqs->attribute, CompCorpusFreqs);
    assert(freqs);
  }

  if (!read_file_into_blob(lexidx->path, MALLOCED, sizeof(int), &(freqs->data))) {
    fprintf(stderr, "Can't open %s, can't create freqs component\n", lexidx->path);
    perror(lexidx->path);
    return 0;
  }
  memset((char *)freqs->data.data, '\0', freqs->data.size);
  assert(lexidx->data.size == freqs->data.size);

  freqs->size = lexidx->size;

  corpus_fn = component_full_name(freqs->attribute, CompCorpus, NULL);
  assert(corpus_fn != NULL);

  if ((fd = fopen(corpus_fn, "r")) == NULL) {
    fprintf(stderr, "makecomps:creat_freqs(): Couldn't open corpus %s\n", corpus_fn);
    perror(corpus_fn);
    exit(2);
  }

  /* do the counts */

  do {
    i = fread(&mc_buf[0], sizeof(int), BUFSIZE, fd);
    for ( k = 0; k < i; k++) {
      ptr = ntohl(mc_buf[k]);
      if ((ptr >= 0) && (ptr < freqs->size))
        freqs->data.data[ptr]++;
      else
        fprintf(stderr, ";;; makecomps:creat_freqs(): WARNING: index %d out of range\n", ptr);
    }
  } while (i == BUFSIZE);
  fclose(fd);

  /* first, we write the table to the file in order to convert it from
     host to network format. */

  if (write_file_from_blob(freqs->path, &(freqs->data), 1)) {

    /* ok, we now have to convert the table to NETWORK order in case
     * other steps rely on its format. */

    /* convert network byte order to native integers */
    for (ptr = 0; ptr < freqs->size; ptr++)
      freqs->data.data[ptr] = htonl(freqs->data.data[ptr]);

    return 1;
  }
  else
    return 0;
}


/**
 * creates reversed corpus
 *
 * @see create_component
 */
int
creat_rev_corpus(Component *revcorp)
{

  Component *freqs;
  int cpos = 0, f, id, ints_written, pass;

  int datasize;
  int primus, secundus, lexsize, buf_used;
  int *buffer;
  size_t bufsize;
  int **ptab;                        /* pointers into <buffer> */
  int *ptr;

  FILE *revcorp_fd;
  Attribute *attr;                /* the attribute we're working on */

  /* this function should only be invoked by the makeall tool (via create_component()),
     which must make sure that the lexicon and (possibly) compressed token stream have been
     created by now, so CL access to the token stream works (see do_attribute()<makeall.c>) */

  assert(revcorp != NULL);
  assert(revcorp->path != NULL);
  assert(revcorp->data.data == NULL); /* so REVCORP is unloaded */

  attr = revcorp->attribute;        /* need the attribute handle to use CL functions */

  /* get the frequency table to compute offsets and fill buffer */
  freqs = ensure_component(attr, CompCorpusFreqs, 1);

  assert(freqs != NULL);
  assert(freqs->corpus == revcorp->corpus); /* gotta be kidding ... */

  lexsize = cl_max_id(attr);        /* this is the number of lexicon entries for this attribute */
  ptab = (int **) cl_malloc(sizeof(int *) * lexsize); /* table of pointers into <buffer> */

  /* determine REVCORP size (== number of tokens) */
  datasize = cl_max_cpos(attr);

  /* allocate buffer of required size, or maximum allowed by cl_memory_limit */
  bufsize = (cl_memory_limit > 0) ? cl_memory_limit * (256 * 1024) : datasize; /* 1MB == 256k INTs */
  if (datasize < bufsize) {
    bufsize = datasize;                /* shrink buffer if full size isn't needed */
  }
  buffer = cl_malloc(4 * bufsize); /* allocate buffer */

  /* open REVCORP data file for writing */
  if ((revcorp_fd = fopen(revcorp->path, "w")) == NULL) {
    perror(revcorp->path);
    exit(1);
  }

  /* NEW multi-pass algorithm.
     In each pass through the corpus, occurrences of lex ID <primus> are directly written
     to the REVCORP file, and occurrences of IDs <primus>+1 ... <secundus> are stored in
     <buffer> (which has room for <bufsize> INTs), then written to REVCORP file.
     */

  if (cl_debug) {
    fprintf(stderr, "\nCreating REVCORP component as '%s' ... \n", revcorp->path);
    fprintf(stderr, "Size = %d INTs,  Buffer Size = %ld INTs\n", datasize, bufsize);
  }

  primus = 0;
  ints_written = 0;                /* check data sizes (written to file VS. corpus size VS. processed */
  pass = 0;                        /* count pass for debugging output */
  while (primus < lexsize) {

    /* see how many IDs fit into the buffer in one pass */
    buf_used = 0;                /* how many buffer entries are used */
    for (secundus = primus + 1; secundus < lexsize; secundus++) {
      /* increment secundus to fit as many IDs as possible into the buffer for this pass */
      f = cl_id2freq(attr, secundus);
      if (buf_used + f > bufsize) {
        secundus--;
        break;
      }
      else {
        ptab[secundus] = buffer + buf_used; /* pointer to first occurrence of lex. ID <secundus> in <buffer> */
        buf_used += f;
      }
    }

    pass++;
    if (cl_debug) {
      double perc = (100.0 * secundus) / lexsize;
      fprintf(stderr, "Pass #%-3d (%6.2f%c complete)\n", pass, perc, '%');
    }

    for (cpos = 0; cpos < datasize; cpos++) {
      id = cl_cpos2id(attr, cpos);          /* lex. ID of token found at <cpos> */
      assert((id >= 0) && (id < lexsize) && "Lexicon ID out of range. Abort.");
      if (id == primus) {
        NwriteInt(cpos, revcorp_fd); /* converts to network byte order */
        ints_written++;
      }
      else if ((id > primus) && (id <= secundus)) {
        *(ptab[id]++) = cpos;        /* store occurrence in buffer and update pointer */
      }
    }

    /* check pointers (i.e. observed frequencies vs. data from FREQS component) */
    ptr = buffer;
    for (id = primus + 1; id < secundus; id++) {
      ptr += cl_id2freq(attr, id);
      if (ptr != ptab[id]) {
        fprintf(stderr, "Pointer inconsistency for id=%d. Aborting.\n", id);
        exit(1);
      }
    }

    /* write buffered data to REVCORP file (converts to network byte-order) */
    NwriteInts(buffer, buf_used, revcorp_fd);
    ints_written += buf_used;

    /* now start next pass ... */
    primus = secundus + 1;
  }                                             /* endwhile (primus < lexsize) */

  /* we're done: close REVCORP filehandle */
  fclose(revcorp_fd);

  /* finally, check amount of data read/written vs. expected */
  if ((ints_written != cpos) || (ints_written != datasize)) {
    fprintf(stderr, "Data size inconsistency: expected=%d, read=%d, written=%d.\n", datasize, cpos, ints_written);
    exit(1);
  }

  /* free allocated memory */
  cl_free(buffer);
  cl_free(ptab);

  /*   (void) load_component(attr, CompRevCorpus);  */
  /* new in 2.2.b79: a newly created component isn't loaded automatically, in order to
     avoid running out address space for large corpora [status should be ComponentUnloaded] */

  /* returns number of passes now */
  return pass;
}


/**
 * creates index for reversed corpus
 *
 * @see create_component
 */
int
creat_rev_corpus_idx(Component *revcidx)
{
  Component *freqs;

  int i, k, sum;

  freqs = ensure_component(revcidx->attribute, CompCorpusFreqs, 1);

  assert(revcidx->path != NULL);
  assert(revcidx->data.data == NULL);
  assert(freqs != NULL);
  assert(freqs->corpus == revcidx->corpus);

  revcidx->data.size = freqs->data.size;
  revcidx->data.item_size = SIZE_INT;
  revcidx->data.nr_items = freqs->data.nr_items;
  revcidx->data.allocation_method = MALLOCED;
  revcidx->data.writeable = 1;
  revcidx->data.changed = 0;
  revcidx->data.fname = NULL;
  revcidx->data.fsize = 0;
  revcidx->data.offset = 0;

  revcidx->data.data = (int *)cl_malloc(sizeof(int) * revcidx->data.nr_items);
  memset(revcidx->data.data, '\0', revcidx->data.size);
  revcidx->size = revcidx->data.nr_items;

  sum = 0;
  for (k = 0; k < freqs->size; k++) { /* for each entry in freqs ... */

    i = ntohl(freqs->data.data[k]);    /* the frequency of word[k] */

    /* the start of word[k] is the sum of freqs of words[i<k] */
    revcidx->data.data[k] = htonl(sum);

    sum += i;          /* compute the sum for the next word */
  }

  /* sum should be the number of words in the corpus, that
     is, the length of the corpus file / sizeof(int). Check this. */

  /* WE DO NOT CONVERT the table from host to network order while
   * writing it, since it's already been created in network order!!!
   * */

  if (write_file_from_blob(revcidx->path, &(revcidx->data), 0) == 0) {
    fprintf(stderr, "Can't open %s for writing", revcidx->path);
    perror(revcidx->path);
    exit(2);
  }

  return 1;
}
