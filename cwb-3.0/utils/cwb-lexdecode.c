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


#include <math.h>

#include "../cl/globals.h"
#include "../cl/cl.h"
#include "../cl/corpus.h"
#include "../cl/attributes.h"
#include "../cl/macros.h"

/** String set to the name of this program. */
char *progname;

int print_nr = 0;           /**< boolean: flag whether we should print line numbers */
int print_freqs = 0;        /**< boolean: print the frequencies of the words? */
int print_len = 0;          /**< boolean: print the word length s? */
int sort = 0;               /**< boolean: print the lexicon in a sorted order? */
int input_are_numbers = 0;  /**< boolean: read lexicon IDs from file? */
int show_size_only = 0;     /**< boolean: do_show should just print the size of the lexicon and exit? */
int freq_0_if_unknown = 0;  /**< boolean: print out unknown words with freq 0? */

Corpus *corpus = NULL;
char *corpus_id = NULL;
char *input_filename = NULL;

/* ---------------------------------------------------------------------- */

/**
 * Prints information about a specified item on a P-attribute
 *
 * @param attr        The attribute to search
 * @param id          The id number of the item (type) in question
 * @param fallback_s  String to print if the item is not found
 *                    (use NULL to use a default fallback string)
 */
void
print_info(Attribute *attr, int id, char *fallback_s)
{
  char *lemma;
  int freq, slen;

  if (id >= 0) {
    if (fallback_s == NULL)
      fallback_s = "(none)";

    lemma = get_id_info(attr, id, &freq, &slen);
    if (cderrno != CDA_OK) {
      cdperror("(aborting) get_id_info() failed");
      exit(1);
    }
  }
  else {
    id = -1;
    freq = 0;
    slen = 0;
    lemma = NULL;
  }

  if (print_nr)    printf("%7d\t", id);
  if (print_freqs) printf("%7d\t", freq);
  if (print_len)   printf("%7d\t", slen);
  printf("%s\n", lemma ? lemma : fallback_s);
}

/**
 * Prints out the lexicon of a P-attribute.
 *
 * This is the business end of the cwb-lexdecode program.
 *
 * @param attr_name  Name of the attribute to decode.
 * @param rx         A regex that items must match to be printed.
 *                   NULL if no regex is to be specified.
 * @param rx_flags   IGNORE_CASE; IGNORE_DIAC; both; or neither.
 */
void
do_show(char *attr_name, char *rx, int rx_flags)
{
  int i, k, len, size;
  int attr_size;

  int *idlist = NULL;
  FILE *input_fd;

  char s[1024];

  Attribute *attr = NULL;

  if ((attr = cl_new_attribute(corpus, attr_name, ATT_POS)) == NULL) {
    fprintf(stderr, "Attribute %s.%s does not exist. Aborted.\n",
            corpus_id, attr_name);
    exit(1);
  }

  attr_size = cl_max_cpos(attr);
  if (cderrno != CDA_OK) {
    cdperror("(aborting) cl_max_cpos() failed");
    exit(1);
  }

  size = cl_max_id(attr);
  if (cderrno != CDA_OK) {
    cdperror("(aborting) cl_max_id() failed");
    exit(1);
  }

  if (show_size_only) {
    printf("Tokens:\t%d\n", attr_size);
    printf("Types:\t%d\n", size);
  }
  else {                        /* without -S option */

    if (input_filename != NULL) { /* with -F <file> option */

      if (strcmp(input_filename, "-") == 0) {
        input_fd = stdin;
      }
      else if ((input_fd = fopen(input_filename, "r")) == NULL) {
        perror(input_filename);
        exit(1);
      }

      while (fgets(s, 1024, input_fd) != NULL) {

        len = strlen(s);
        if (len <= 0) {
          fprintf(stderr, "%s Warning: read empty string from input file (ignored)\n",
                  progname);
        }
        else {
          if (s[len-1] == '\n') { /* chomp; # :o) */
            s[len-1] = '\0';
            len--;
          }

          if (input_are_numbers)
            i = atoi(s);
          else
            i = cl_str2id(attr, s);

          if ((i < 0) && (!freq_0_if_unknown))
              fprintf(stderr, "%s Warning: ``%s'' not found in lexicon (ignored)\n", progname, s);
            else
              print_info(attr, i, (input_are_numbers) ? NULL : s);
        }

      }

      if (input_fd != stdin)
        fclose(input_fd);

    }
    else {                        /* without -F option */

      if (rx != NULL) {
        idlist = cl_regex2id(attr, rx, rx_flags, &size);
        if ((size == 0) || (idlist == NULL))
          return;                /* no matches */
      }

      for (k = 0; k < size; k++) {

        if (idlist != NULL) {
          i = idlist[k];
        }
        else if (sort) {
          i = get_id_from_sortidx(attr, k);
          if (cderrno != CDA_OK) {
            cdperror("(aborting) get_id_from_sortidx() failed");
            exit(1);
          }
        }
        else {
          i = k;
        }

        print_info(attr, i, NULL);
      }
    }

  } /* ends: without -S option */
}


/**
 * Prints a message describing how to use the program to STDERR and then exits.
 */
void
usage(void)
{
  fprintf(stderr, "\n");
  fprintf(stderr, "Usage:  %s [options] <corpus>\n\n", progname);
  fprintf(stderr, "Prints the lexicon (or part of it) of a positional attribute on stdout,\n");
  fprintf(stderr, "optionally with frequency information. The output line format is\n");
  fprintf(stderr, "  [ <lexicon id> TAB ] [ <frequency> TAB ] [<length> TAB ] <string>\n\n");
  fprintf(stderr, "Options:\n");
  fprintf(stderr, "  -P <att>  use p-attribute <att> [default: word]\n");
  fprintf(stderr, "  -S        only show lexicon and corpus size\n");
  fprintf(stderr, "  -r <dir>  set registry directory\n");
  fprintf(stderr, "  -f        show frequency (number of occurrences)\n");
  fprintf(stderr, "  -n        show internal lexicon ID\n");
  fprintf(stderr, "  -l        show length of annotation string\n");
  fprintf(stderr, "  -s        print in (lexically) sorted order\n");
  fprintf(stderr, "  -p <rx>   show lexicon entries matching regexp <rx> only\n");
  fprintf(stderr, "  -c        [with -p <rx>] ignore case\n");
  fprintf(stderr, "  -d        [with -p <rx>] ignore diacritics\n");
  fprintf(stderr, "  -F <file> lookup strings read from <file> ('-' for stdin)\n");
  fprintf(stderr, "  -0        [with -F <file>] show non-existing strings with freq. 0\n");
  fprintf(stderr, "  -N        [with -F <file>] read lexicon IDs from <file>\n");
  fprintf(stderr, "  -h        this help page\n\n");
  fprintf(stderr, "Part of the IMS Open Corpus Workbench v" VERSION "\n\n");
  exit(2);
}


/* *************** *\
 *      MAIN()     *
\* *************** */

/**
 * Main function for cwb-lexdecode.
 *
 * @param argc   Number of command-line arguments.
 * @param argv   Command-line arguments.
 */
int
main(int argc, char **argv) {
  char *registry_directory = NULL;
  char *attr_name = DEFAULT_ATT_NAME;
  char *rx = NULL;
  int   rx_flags = 0;

  extern int optind;
  extern char *optarg;

  int c;

  /* ------------------------------------------------- PARSE ARGUMENTS */

  progname = argv[0];

  if (argc == 1)
    usage();

  /* parse arguments */
  while ((c = getopt(argc, argv, "+P:Sr:fnlsp:cdF:O0Nh")) != EOF) {

    switch (c) {
    case 'S':                        /* S: show lexicon size only */
      show_size_only++;
      break;

    case 'P':                        /* P: attribute name */
      attr_name = optarg;
      break;

    case 'r':                        /* r: registry directory */
      if (registry_directory == NULL)
        registry_directory = optarg;
      else {
        fprintf(stderr, "%s: -r option used twice\n", progname);
        exit(2);
      }
      break;

    case 'f':                        /* f: print frequencies */
      print_freqs++;
      break;

    case 'n':                        /* n: print line numbers */
      print_nr++;
      break;

    case 'l':                        /* l: print word length */
      print_len++;
      break;

    case 's':                        /* s: print sorted */
      sort++;
      break;

    case 'p':                        /* p: match regular expression */
      rx = optarg;
      break;

    case 'c':                        /* c: ignore case */
      rx_flags |= IGNORE_CASE;
      break;

    case 'd':                        /* d: ignore diacritics */
      rx_flags |= IGNORE_DIAC;
      break;

    case 'F':                        /* F: read strings from file ('-' for stdin) */
      input_filename = optarg;
      sort = 0;                      /* reading strings from file disables sorting and pattern matching */
      rx = NULL;
      break;

    case 'O':                        /* O: _secret_ optimisation flag (turns on CL optimisations) */
      cl_set_optimize(1);
      break;

    case '0':                        /* 0: just issue 0 as freq for unknown ids */
      freq_0_if_unknown++;
      break;

    case 'N':                        /* N: read lexicon IDs from file (with -F) */
      input_are_numbers++;
      break;

    default:
    case 'h':
      usage();
      break;
    }

  }

  /* single argument: corpus id */
  if (optind < argc) {

    corpus_id = argv[optind++];

    if ((corpus = cl_new_corpus(registry_directory, corpus_id)) == NULL) {
      fprintf(stderr, "%s: Corpus %s not found in registry %s . Aborted.\n",
              progname, corpus_id,
              (registry_directory ? registry_directory : central_corpus_directory()));
      exit(1);
    }

    if (optind < argc) {
      fprintf(stderr, "Too many arguments. Try \"%s -h\" for more information.\n",
              progname);
      exit(2);
    }

    do_show(attr_name, rx, rx_flags);

    cl_delete_corpus(corpus);
  }
  else {
    fprintf(stderr, "No corpus specified. Try \"%s -h\" for more information.\n",
            progname);
    exit(2);
  }

  exit(0);
}
