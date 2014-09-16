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
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <assert.h>


/* byte order conversion functions taken from Corpus Library */
#include "../cl/globals.h"
#include "../cl/endian.h"
#include "../cl/macros.h"
#include "../cl/cl.h"
#include "../cl/storage.h"      /* for NwriteInt() */
#include "../cl/lexhash.h"

/* ---------------------------------------------------------------------- */

#define UMASK              0644

/* file storing ranges of given structural attribute */
#define RNG_RNG "%s/%s.rng"

/* attribute value index of a given structural attribute */
#define RNG_AVX "%s/%s.avx"

/* attribute values of a given structural attribute */
#define RNG_AVS "%s/%s.avs"


/* ---------------------------------------------------------------------- */

/* configuration variables // command-line switches */
int debug = 0;
int silent = 0;                 /* avoid messages in -M / -a modes */
int strip_blanks_in_values = 0; /* Wow, this is unused :o) */
int set_syntax_strict = 0;      /* check that set attributes are always given in the same syntax */
int in_memory = 0;              /* create list of regions in memory (allowing non-linear input), then write to disk */
int add_to_existing = 0;        /* add to existing attribute: implies <in_memory>, existing regions are automatically inserted at startup */
FILE *text_fd = NULL;

/* global variables */
Corpus *corpus = NULL;          /* corpus we're working on; at the moment, this is only required for <add_to_existing> */
int line = 0;
enum {
  set_none, set_any, set_regular, set_whitespace
} set_att = set_none;           /* set attributes */


/* ---------------------------------------------------------------------- */

typedef struct {
  char *dir;                    /* directory where this range is stored */
  char *name;                   /* range name */

  int store_values;             /* flag indicating whether to store values */

  int ready;                    /* flag indicates whether open_range() has already been called */
  FILE *fd;                     /* fd of x.rng */
  FILE *avx;                    /* the attribute value index */
  FILE *avs;                    /* the attribute values */

  int last_cpos;                /* end of last region (consistency checking) */
  int num;                      /* the next will be the num-th structure */
  int offset;                   /* string offset for next string */
} Range;

Range range;

/* ---------------------------------------------------------------------- */

char *progname = NULL;

/* ---------------------------------------------------------------------- */

/* The "structure list" data type is used for 'adding' regions (-a).
 * In this case, all existing regions are read into an ordered, bidirectional list;
 * new regions are inserted into that list (overlaps are automatically resolved
 * in favour of the 'earlier' region; if start point is identical, the longer
 * region is retained). Only when the entire input has been read, the data
 * will be actually encoded and stored on disk.
 */

typedef struct _SL {
  int start;                    /* start of region */
  int end;                      /* end of region */
  char *annot;                  /* annotated string */
  struct _SL *prev;
  struct _SL *next;
} *SL;

SL StructureList = NULL;        /* (single) global list */
SL SL_Point = NULL;             /* pointer into list; NULL = start of list; linear search starts from SL_Point */

/* SL functions:
 *  item = SL_seek(cpos);           (find region containing (or preceding) cpos; NULL = start of list; sets SL_Point to returned value)
 *  item = SL_insert_after_point(start, end, annot);   (insert region [start, end, annot] after SL_Point; no overlap/position checking)
 *  SL_delete(item);                (delete region from list; updates SL_Point if it happened to point at item)
 *  SL_insert(start, end, annot);   (user function: combines SL_seek(), SL_insert_at_point() and ambiguity resolution)
 *  SL_rewind();                    (reset SL_Point to start of list)
 *  item = SL_next();               (returns item marked by point, then advances point to next item; NULL at end of list)
 */

void
SL_rewind(void) {
  SL_Point = StructureList;
}

SL
SL_next(void) {
  SL item;

  item = SL_Point;
  if (SL_Point != NULL)
    SL_Point = SL_Point->next;
  return item;
}

SL
SL_seek(int cpos) {
  if (SL_Point == NULL)          /* start-of-list case */
    SL_Point = StructureList;

  while (SL_Point != NULL) {
    if ((SL_Point->start <= cpos) && (cpos <= SL_Point->end))
      return SL_Point;           /* found region containing cpos */
    if ((cpos < SL_Point->start)) {
      SL_Point = SL_Point->prev; /* try previous region: SL_Point may become NULL = start of list */
    }
    else if ((cpos > SL_Point->end) && (SL_Point->next != NULL) && (SL_Point->next->start <= cpos)) {
      SL_Point = SL_Point->next; /* try next region, but only if it isn't _behind_ cpos */
    }
    else {
      return SL_Point;          /* can't do better than that */
    }
  }
  return NULL;
}

SL
SL_insert_after_point(int start, int end, char *annot) {
  /* allocate and initialise new item to insert into list */
  SL item = (SL) cl_malloc(sizeof(struct _SL));
  item->start = start;
  item->end = end;
  if (annot != NULL)
    item->annot = cl_strdup(annot);
  else
    item->annot = NULL;
  item->prev = NULL;
  item->next = NULL;
  /* this function has to handle a number of special cases ... */
  if (SL_Point == NULL) {          /* insert at start of list */
    if (StructureList == NULL) {   /* empty list */
      SL_Point = StructureList = item;
    }
    else {
      item->next = StructureList;
      StructureList->prev = item;
      SL_Point = StructureList = item;
    }
  }
  else if (SL_Point->next == NULL) { /* insert at end of list */
    item->prev = SL_Point;
    SL_Point = SL_Point->next = item;
  }
  else {                            /* insert somewhere inside list */
    item->next = SL_Point->next; /* links between new item and following item */
    SL_Point->next->prev = item;
    SL_Point->next = item;       /* links between point and new item */
    item->prev = SL_Point;
    SL_Point = item;
  }
  return SL_Point;
}

void
SL_delete(SL item) {
  /* unlink item ... we have to handle a few special cases again */
  if (item->prev == NULL) {     /* delete first list element */
    StructureList = item->next;
    if (item->next != NULL)
      item->next->prev = NULL;
    if (item == SL_Point)
      SL_Point = item->next;    /* if SL_Point was positioned at this item, set it to following one */
  }
  else {
    item->prev->next = item->next; /* link preceding item to following item (which may be NULL) */
    if (item->next != NULL)
      item->next->prev = item->prev;
    if (item == SL_Point)
      SL_Point = item->prev;    /* default is to set SL_Point to preceding item (which we now know to exist) */
  }
  /* free item object */
  cl_free(item->annot);
  free(item);
}

void
SL_insert(int start, int end, char *annot) {
  SL point, item;

  point = SL_seek(start);
  if (point == NULL) {
    item = SL_insert_after_point(start, end, annot); /* insert item at start of list */
  }
  else if ((point->start <= start) && (start <= point->end)) {
    if ((point->start < start) || (point->end > end)) { /* overlap: don't insert */
      return;
    }
    else {                                              /* overlap: overwrite previous entry */
      item = SL_insert_after_point(start, end, annot);
      SL_delete(point); /* this re-establishes list ordering */
    }
  }
  else {                        /* non-overlapping: simply insert new region after point */
    item = SL_insert_after_point(start, end, annot);
  }

  /* new item may overlap one or more of the following ones, which we must delete */
  point = item->next;
  while ((point != NULL) && (point->start <= item->end)) { /* (point->start > item->start) implied by insertion above */
    SL_delete(point);
    point = item->next;
  }
}


/* ---------------------------------------------------------------------- */




/* ok = parse_line(char *line, int *start, int *end, char **annot);
   parse input line; expects standard TAB-separated format;
   first two fields must be numbers, optional third field is returned in <annot> */
int
parse_line(char *line, int *start, int *end, char **annot) {
  char *field, *field_end;
  char *line_copy = cl_strdup(line); /* work on copy to retain original for error messages */
  int has_annotation = 1;

  /* first field: INT range_start */
  field = line_copy;
  field_end = strchr(field, '\t');
  if (field_end == NULL)
    return 0;
  else {
    *field_end = 0;
    errno = 0;
    *start = atoi(field);
    if (errno != 0 || *start < 0) return 0;
    field = field_end + 1;
  }

  /* second field: INT range_end */
  field_end = strchr(field, '\t');
  if (field_end == NULL) {
    has_annotation = 0;
    field_end = strchr(field, '\n');
  }
  if (field_end == NULL)
    return 0;
  else {
    *field_end = 0;
    errno = 0;
    *end = atoi(field);
    if (errno != 0 || *end < 0) return 0;
    field = field_end + 1;
  }

  /* optional third field: STRING annotation */
  if (has_annotation) {
    field_end = strchr(field, '\t');
    if (field_end != NULL) {
      return 0;                 /* make sure there are no extra fields */
    }
    else {
      field_end = strchr(field, '\n');
      if (field_end == NULL) {
        return 0;
      }
      else {
        *field_end = 0;
        *annot = cl_strdup(field);
      }
    }
  }
  else {
    *annot = NULL;
  }

  cl_free(line_copy);
  return 1;                     /* OK */
}


/* ---------------------------------------------------------------------- */

/* annot = check_set(char *annot);
   changes annotation string <annot> to standard set attribute syntax; on first call,
   checks whether annotations are already given in '|'-delimited form, otherwise it will
   always split on whitespace;
   the string <annot> may be reallocated (i.e. caller must use & free the returned value);
   if there are syntax errors, check_set() returns NULL */
char *
check_set(char *annot) {
  char *set;
  int split;                    /* need to split on whitespace? */

  if (set_att == set_none || annot == NULL) {
    return annot;               /* no modification needed */
  }
  else if ((!set_syntax_strict) || set_att == set_any) {
    if (annot[0] == '|') {
      set_att = set_regular;
    }
    else {
      set_att = set_whitespace;
    }
  }

  split = (set_att == set_whitespace) ? 1 : 0;
  set = cl_make_set(annot, split);
  cl_free(annot);
  return set;
}


/* ---------------------------------------------------------------------- */

/* ======================================== print usage message and exit */

void
usage() {
  fprintf(stderr, "\n");
  fprintf(stderr, "Usage:  %s [options] (-S <att> | -V <att>)\n", progname);
  fprintf(stderr, "\n");
  fprintf(stderr, "Adds s-attributes with computed start and end points to a corpus\n");
  fprintf(stderr, "\n");
  fprintf(stderr, "Options:\n");
  fprintf(stderr, "  -B        strip leading/trailing blanks from annotations\n");
  fprintf(stderr, "  -d <dir>  directory for output files\n");
  fprintf(stderr, "  -f <file> read input from <file> [default: stdin]\n");
  fprintf(stderr, "  -M        create list of regions in memory (resolving overlaps)\n");
  fprintf(stderr, "  -r <dir>  set registry directory <dir>\n");
  fprintf(stderr, "  -C <id>   work on corpus <id> (with -a option)\n");
  fprintf(stderr, "  -a        add to existing annotation (resolving overlaps, implies -M)\n");
  fprintf(stderr, "  -m        treat annotations as feature set (or 'multi-value') attribute\n");
  fprintf(stderr, "  -s        (with -m) check that format of set annotations is consistent\n");
  fprintf(stderr, "  -q        silent mode ('be quiet')\n");
  fprintf(stderr, "  -D        debug mode\n");
  fprintf(stderr, "  -S <att>  generate s-attribute <att>\n");
  fprintf(stderr, "  -V <att>  generate s-attribute <att> with annotations\n");
  fprintf(stderr, "Part of the IMS Open Corpus Workbench v" VERSION "\n\n");
  exit(2);
}

/* =================================================== declare_range() / open_range() / close_range() */

/* initialise range and set name/directory */
void
declare_range(char *name, char *directory, int store_values)
{
  range.name = cl_strdup(name);
  range.dir = cl_strdup(directory);

  range.num = 0;
  range.offset = 0;
  range.store_values = store_values;
  range.last_cpos = -1;

  range.ready = 0;
  range.fd = NULL;
  range.avs = NULL;
  range.avx = NULL;
}

/* open disk files for declared range */
void
open_range(void)
{
  char buf[MAX_LINE_LENGTH];

  sprintf(buf, RNG_RNG, range.dir, range.name);
  if ((range.fd = fopen(buf, "w")) == NULL) {
    perror(buf);
    exit(1);
  }

  if (range.store_values) {
    sprintf(buf, RNG_AVS, range.dir, range.name);
    if ((range.avs = fopen(buf, "w")) == NULL) {
      perror(buf);
      exit(1);
    }

    sprintf(buf, RNG_AVX, range.dir, range.name);
    if ((range.avx = fopen(buf, "w")) == NULL) {
      perror(buf);
      exit(1);
    }
  }

  range.ready = 1;
}

/* close disk files of open range */
void
close_range(void)
{
  if (range.ready) {
    if (EOF == fclose(range.fd)) {
      perror("Error writing RNG file");
      exit(1);
    }

    if (range.avs) {
      if (EOF == fclose(range.avs)) {
        perror("Error writing AVS file");
        exit(1);
      }
    }

    if (range.avx) {
      if (EOF == fclose(range.avx)) {
        perror("Error writing AVX file");
        exit(1);
      }
    }

    range.ready = 0;
  }
}


/* ======================================== parse options and set global vars */

void
parse_options(int argc, char **argv)
{
  int c;
  extern char *optarg;
  extern int optind;

  /* by default, output files are written to current directory */
  char *directory = ".";
  /* may need to set registry if source corpus is specified */
  char *registry = NULL;
  /* source corpus _may_ be set with the -C switch */
  char *corpus_name = NULL;

  /* if text_fd is unspecified, stdin will be used */
  text_fd = NULL;
  /* make sure either -S or -V is used: reset range.name now & check after getopt */
  range.name = NULL;

  while((c = getopt(argc, argv, "+qBd:f:msDS:V:r:C:Mah")) != EOF)
    switch(c) {

      /* q: be silent (quiet) */
    case 'q':
      silent++;
      break;

      /* B: strip blanks */
    case 'B':
      strip_blanks_in_values++;
      break;

      /* d: directory for generated data files */
    case 'd':
      directory = optarg;
      break;

      /* f: read input from file */
    case 'f':
      if (text_fd) {
        fprintf(stderr, "Error: -f option used twice\n\n");
        exit(1);
      }
      if ((text_fd = fopen(optarg, "r")) == NULL) {
        perror("Can't open input file");
        exit(1);
      }
      break;

      /* M: compile list in memory, then write to disk */
    case 'M':
      in_memory++;
      break;

      /* a: add to existing attribute (implies -M) */
    case 'a':
      add_to_existing++;
      in_memory++;
      break;

      /* r: registry directory */
    case 'r':
      registry = optarg;
      break;

      /* C: source corpus */
    case 'C':
      corpus_name = optarg;
      break;

      /* m: set ('multi-value') attribute */
    case 'm':
      set_att = set_any;        /* don't know yet whether it's '|'-delimited or "split on whitespace" */
      break;

      /* s: strict syntax checks on set attribute */
    case 's':
      set_syntax_strict++;
      break;

      /* D: debug mode */
    case 'D':
      debug++;
      break;

      /* S: s-attribute without annotations */
    case 'S':
      declare_range(optarg, directory, 0);
      if (optind < argc) {
        fprintf(stderr, "Error: -S <att> must be last flag on command line.\n\n");
        exit(1);
      }
      break;

      /* V: s-attribute with annotations */
    case 'V':
      declare_range(optarg, directory, 1);
      if (optind < argc) {
        fprintf(stderr, "Error: -V <att> must be last flag on command line.\n\n");
        exit(1);
      }
      break;

    /* default or -h: error */
    case 'h':
    default:
      usage();
      break;
    }

  /* now, check the default and obligatory values */
  if (!text_fd)
    text_fd = stdin;
  if (range.name == NULL) {
    fprintf(stderr, "Error: either -S or -V flag must be specified.\n\n");
    exit(1);
  }
  if (optind < argc) {
    fprintf(stderr, "Error: extra arguments.\n\n");
    exit(1);
  }

  /* if -C <corpus> was specified, open source corpus */
  if (corpus_name != NULL) {
    corpus = cl_new_corpus(registry, corpus_name);
    if (corpus == NULL) {
      fprintf(stderr, "Error: Can't find corpus <%s>!\n", corpus_name);
      exit(1);
    }
  }

}


/* ======================================== write region data to disk files (as defined in global variable <range>) */

cl_lexhash LH = NULL;           /* use lexhash to avoid multiple copies of annotations (-m mode) */

void
write_region_to_disk(int start, int end, char *annot) {
  if (!range.ready)
    open_range();
  if (range.store_values && (LH == NULL))
    LH = cl_new_lexhash(0);

  /* write start & end positions of region */
  NwriteInt(start, range.fd);
  NwriteInt(end, range.fd);

  /* store annotation for -V attribute */
  if (range.store_values) {
    int offset, id;
    cl_lexhash_entry entry;

    entry = cl_lexhash_find(LH, annot);
    if (entry == NULL) {
      /* must add string to hash */
      entry = cl_lexhash_add(LH, annot);
      entry->data.integer = range.offset;
      range.offset += strlen(annot) + 1; /* increment range offset */
      if (0 > fprintf(range.avs, "%s%c", annot, 0)) {
        perror("Error writing AVS file");
        exit(1);
      }
    }
    id = entry->id;
    offset = entry->data.integer;

    NwriteInt(range.num, range.avx);
    NwriteInt(offset, range.avx);
  }

  range.num++;   /* increment range number */
  range.last_cpos = end;
}



/* *************** *\
 *      MAIN()     *
\* *************** */



/*

  Input:  a list of regions (on stdin or in the file specified in the first argument
          to the program name) with lines in the folling format:
  <start> TAB <end> [ TAB <annotation> ]

  <start> = corpus position of first token in region
  <end> = corpus position of last token in region
  <annotation> = annotation text (only if s-attribute was specified with -V)

  Output: file <att>.rng (plus <att>.avs, <att>.avx for -V attributes)
*/

/**
 * Main function for cwb-s-encode.
 *
 * @param argc   Number of command-line arguments.
 * @param argv   Command-line arguments.
 */
int
main(int argc, char **argv)
{
  int input_line;
  int start, end;
  char *annot;
  char buf[MAX_LINE_LENGTH];
  Attribute *att;
  int V_switch, values, S_annotations_dropped;
  int i, N;

  progname = argv[0];
  parse_options(argc, argv);

  /* -a mode: read existing regions into memory */
  if (add_to_existing) {
    if (corpus == NULL) {
      fprintf(stderr, "Error: You have to specify source corpus (-C <corpus>) for -a switch.\n");
      exit(1);
    }
    att = cl_new_attribute(corpus, range.name, ATT_STRUC);
    if ((att != NULL) && (cl_max_struc(att) > 0)) {
      V_switch = range.store_values;
      values = cl_struc_values(att);
      if (V_switch && (!values)) {
        fprintf(stderr, "Error: Existing regions of -V attribute have no annotations.\n");
        exit(1);
      }
      else if ((!V_switch) && values) {
        fprintf(stderr, "Error: Existing regions of -S attributes have annotations.\n");
        exit(1);
      }
      if (!silent)
        printf("[Loading previous <%s> regions]\n", range.name);

      N = cl_max_struc(att);
      for (i = 0; i < N; i++) {
        cl_struc2cpos(att, i, &start, &end);
        annot = cl_struc2str(att, i);
        SL_insert(start, end, annot);
      }
    }
    else {
      if (!silent)
        printf("[No <%s> regions defined (skipped)]\n", range.name);
    }
  }

  /* loop reading input (stdin or -f <file>) */
  if (in_memory && (!silent))
    printf("[Reading input data]\n");
  input_line = 0;
  S_annotations_dropped = 0;
  while (fgets(buf, MAX_LINE_LENGTH, text_fd)) {
    input_line++;

    /* check for buffer overflow */
    if (strlen(buf) >= (MAX_LINE_LENGTH - 1)) {
      fprintf(stderr, "BUFFER OVERFLOW, input line #%d is too long:\n>> %s", input_line, buf);
      exit(1);
    }

    if (! parse_line(buf, &start, &end, &annot)) {
      fprintf(stderr, "FORMAT ERROR on line #%d:\n>> %s", input_line, buf);
      exit(1);
    }
    if (range.store_values && (annot == NULL)) {
      fprintf(stderr, "MISSING ANNOTATION on line #%d:\n>> %s", input_line, buf);
      exit(1);
    }
    if ((!range.store_values) && (annot != NULL)) {
      if (! S_annotations_dropped)
        fprintf(stderr, "WARNING: Annotation for -S attribute ignored on line #%d (warning issued only once):\n>> %s", input_line, buf);
      S_annotations_dropped++;
    }
    if ((start <= range.last_cpos) || (end < start)) {
      fprintf(stderr, "RANGE INCONSISTENCY on line #%d:\n>> %s(end of previous range was %d)\n", input_line, buf, range.last_cpos);
      exit(1);
    }
    if (annot != NULL && set_att != set_none) {
      /* convert set annotation into standard syntax */
      annot = check_set(annot);
      if (annot == NULL) {
        fprintf(stderr, "SET ANNOTATION SYNTAX ERROR on line #%d:\n>> %s", input_line, buf);
        exit(1);
      }
    }

    /* debugging output */
    if (debug) {
      printf("[%d, %d]", start, end);
      if (annot != NULL) {
        printf(" <%s>", annot);
      }
      printf("\n");
    }

    /* in -M mode, store this region in memory; otherwise write it to the disk files */
    if (in_memory)
      SL_insert(start, end, annot);
    else
      write_region_to_disk(start, end, annot);

    cl_free(annot);
  }

  /* in -M mode, write data to disk now */
  if (in_memory) {
    SL item;

    if (!silent)
      printf("[Creating encoded disk file(s)]\n");
    SL_rewind();
    while ((item = SL_next()) != NULL)
      write_region_to_disk(item->start, item->end, item->annot);
  }

  /* close files */
  close_range();

  if (S_annotations_dropped > 0)
    fprintf(stderr, "Warning: %d annotation values dropped for -S attribute '%s'.\n", S_annotations_dropped, range.name);

  exit(0);
}
