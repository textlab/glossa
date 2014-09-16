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
#include <string.h>
#include <unistd.h>		/* for POSIX getopt() */

#include "../cl/cl.h"


/* global variables */

/** Name of the program (from the shell) */
char *progname = "";

char corpus1_name[1024];            /**< name of the source corpus */
char corpus2_name[1024];            /**< name of the target corpus */
char s1_name[1024];                 /**< name of the source sentence regions */
char s2_name[1024];                 /**< name of the target sentence regions */
char word_name[1024] = "word";      /**< name of the p-attribute used to display tokens (usually word) */
Corpus *corpus1;                    /**< corpus handle: source corpus */
Corpus *corpus2;                    /**< corpus handle: target corpus */
Attribute *w1;                      /**< {word} attribute (or whatever is selected with -P) attribute handle: source */
Attribute *s1;                      /**< sentence attribute handle: source */
Attribute *w2;                      /**< {word} attribute (or whatever is selected with -P) attribute handle: target */
Attribute *s2;                      /**< sentence attribute handle: target */
char *registry_dir = NULL;          /**< registry directory (NULL = use CL default) */

char *align_name = "";              /**< name of the .align file */
FILE *af = NULL;                    /**< file handle .align file */
int af_is_pipe;                     /**< need to know whether to call fclose() or pclose() */

#define MIN_COL_WIDTH 20
#define MAX_COL_WIDTH 256
int COL_WIDTH = 38;                /**< width of a display column (one column for each language) */
int COL_SEP = 2;                   /**< column separator (blanks) */
#define WIDE_COL_WIDTH 55
#define WIDE_COL_SEP   6


/**
 * Lists interactive commands on STDERR.
 */
void
print_help(void)
{
  fprintf(stderr, "  RET    show next aligned region\n");
  fprintf(stderr, "  p <n>  print next <n> regions\n");
  fprintf(stderr, "  s <n>  skip next <n> regions\n");
  fprintf(stderr, "  h      this list (help)\n");
  fprintf(stderr, "  q, x   exit %s\n", progname);
}

/**
 * Prints a message describing how to use the program to STDERR and then exits.
 */
void
print_usage(void)
{
  fprintf(stderr, "\n");
  fprintf(stderr, "Usage: %s [options] <alignment file>\n\n", progname);
  fprintf(stderr, "  -P <p-att> display positional attribute <p-att> [word]\n");
  fprintf(stderr, "  -r <reg>   use registry directory <reg>\n");
  fprintf(stderr, "  -w <n>     set display column width to <n>   [%d]\n", COL_WIDTH);
  fprintf(stderr, "  -s <n>     set column separator width to <n> [%d]\n", COL_SEP);
  fprintf(stderr, "  -W         display width settings for wide xterm window\n");
  fprintf(stderr, "  -h         this help page\n\n");
  fprintf(stderr, "Displays alignment results in terminal. Aligned regions are\n");
  fprintf(stderr, "displayed side-by-side, one region at a time. The following\n");
  fprintf(stderr, "interactive commands are available:\n\n");
  print_help();
  fprintf(stderr, "\n");
  fprintf(stderr, "Part of the IMS Open Corpus Workbench v" VERSION "\n\n");
  exit(1);
}


/**
 * Parses the program's commandline arguments.
 *
 * Usage:
 * optindex = parse_args(argc, argv, required_arguments);
 *
 * @param ac        The program's argc
 * @param av        The program's argv
 * @param min_args  Minimum number of arguments to be parsed.
 * @return          The value of optind after parsing,
 *                  ie the index of the first argument in argv[]
 */
int
parse_args(int ac, char *av[], int min_args)
{
  extern int optind;                  /* getopt() interface */
  extern char *optarg;                /* getopt() interface */
  int c;
  int n;

  while ((c = getopt(ac, av, "hP:r:w:s:W")) != EOF)
    switch (c) {
      /* -P: positional attribute */
    case 'P':
      strcpy(word_name, optarg);
      break;
      /* -r: registry directory */
    case 'r':
      if (registry_dir == NULL)
        registry_dir = optarg;
      else {
        fprintf(stderr, "%s: -r option used twice\n", progname);
        exit(2);
      }
      break;
      /* -w: column width */
    case 'w':
      if (1 != sscanf(optarg, "%d", &n))
        print_usage();
      if ((n < MIN_COL_WIDTH) || (n > MAX_COL_WIDTH)) {
        fprintf(stderr, "%s: column width must be in range %d .. %d\n",
                progname, MIN_COL_WIDTH, MAX_COL_WIDTH);
        exit(1);
      }
      else {
        COL_WIDTH = n;
      }
      break;
      /* -s: column separator */
    case 's':
      if (1 != sscanf(optarg, "%d", &n))
        print_usage();
      COL_SEP = n;
      break;
      /* -W: wide display */
    case 'W':
      COL_WIDTH = WIDE_COL_WIDTH;
      COL_SEP   = WIDE_COL_SEP;
      break;
      /* -h : help page = usage */
    case 'h':
    default:
      print_usage();
    }

  if (ac - optind < min_args)
     print_usage();

  return(optind);                /* return index of first argument in argv[] */
}



/**
 * Closes the alignment file handle (if open) and exits the program.
 *
 * @param error_level  The exit code that is returned to the OS.
 */
void
goodbye(int error_level)
{
  if (af != NULL) {
    if (af_is_pipe) {
      /* skip rest of alignment file to avoid "broken pipe" message */
      char line[4096];
      while (!feof(af))
        fgets(line, 4096, af);
      pclose(af);
    }
    else
      fclose(af);
    af = NULL;
  }
  if (error_level == 0)
    printf("Goodbye.\n");
  exit(error_level);
}



/**
 * Exits the program because the end of the .align file has been reached.
 */
void
end_of_alignment(void)
{
  printf("=========================== END OF ALIGNMENT FILE ============================\n");
  goodbye(0);
}



/**
 * Reads and discards the next alignment region from an .align file.
 *
 * @param f  The file handle to read from.
 */
void
skip_next_region(FILE *f)
{
  char line[4096];

  if (feof(f)) end_of_alignment();
  fgets(line, 4096, f);
}


/**
 * Reads the next alignment region from a .align file,
 * and displays it on STDOUT.
 *
 * @param f  The file handle to read from.
 */
void
print_next_region(FILE *f)
{
  char line[4096];
  int f1, l1, f2, l2;
  int quality, args;
  char type[256];

  char *word;                         /* current token from corpus */
  char col[MAX_COL_WIDTH + 1];        /* line buffer for columns */
  int w;                              /* current column width */
  int i1, i2, n;


  /* get next alignment region */
  if (feof(f)) end_of_alignment();
  if (NULL == fgets(line, 4096, f)) end_of_alignment();
  if (5 > (args = sscanf(line, "%d %d %d %d %s %d", &f1, &l1, &f2, &l2, type, &quality))) {
    fprintf(stderr, "%s: format error in line\n\t%s", progname, line);
    fprintf(stderr, "*** IGNORED ***\n");
    return;
  }

  /* print separator bar */
  if (args == 6)
    sprintf(line, "%s-alignment [%d, %d] x [%d, %d] (%d)", type, f1, l1, f2, l2, quality);
  else
    sprintf(line, "%s-alignment [%d, %d] x [%d, %d] ", type, f1, l1, f2, l2);
  n = (2 * COL_WIDTH + COL_SEP) - strlen(line);
  printf("%s", line);
  while ((n--) > 0) printf("=");
  printf("\n\n");

  i1 = f1; i2 = f2;
  while ((i1 <= l1) || (i2 <= l2)) {
    /* fill left column */
    w = 0; col[0] = 0;
    while (i1 <= l1) {
      word = get_string_at_position(w1, i1);
      n = strlen(word);
      if (n > COL_WIDTH) {
        /* token doesn't fit in line */
        word = "<OVERSIZE TOKEN>";
        n = strlen(word);
      }
      if ((w + n) > COL_WIDTH) break; /* column full */
      sprintf(col + w, "%s", word); w += n;
      i1++;                           /* next token */
      if (w < COL_WIDTH) {
        sprintf(col + w, " ");        /* add token separator, if there's room */
        w++;
      }
    }
    printf("%s", col);                /* print left column and fill */
    while ((w++) < COL_WIDTH) printf(" ");

    for (n = COL_SEP; n > 0; n--) printf(" "); /* column separator */

    /* fill right column */
    w = 0; col[0] = 0;
    while (i2 <= l2) {
      word = get_string_at_position(w2, i2);
      n = strlen(word);
      if (n > COL_WIDTH) {
        /* token doesn't fit in line */
        word = "<OVERSIZE TOKEN>";
        n = strlen(word);
      }
      if ((w + n) > COL_WIDTH) break; /* column full */
      sprintf(col + w, "%s", word); w += n;
      i2++;                           /* next token */
      if (w < COL_WIDTH) {
        sprintf(col + w, " ");        /* add token separator, if there's room */
        w++;
      }
    }
    printf("%s", col);                /* print left column (no need to fill) */

    printf("\n");
  }
}




/* *************** *\
 *      MAIN()     *
\* *************** */

/**
 * Main function for cwb-align-show.
 *
 * @param argc   Number of command-line arguments.
 * @param argv   Command-line arguments.
 */
int
main(int argc, char** argv)
{
  int argindex;                        /* index of first argument in argv[] */
  char line[4096];                /* input buffer for .align file */
  char cmd[4096];                /* interactive command input */
  int l;

  progname = argv[0];

  /* parse command line and read arguments */
  argindex = parse_args(argc, argv, 1);
  align_name = argv[argindex];

  /* open alignment file and parse header; .gz files are automatically decompressed */
  af_is_pipe = 0;
  l = strlen(align_name);
  if ((l > 3) && (strncasecmp(align_name + l - 3, ".gz", 3) == 0)) {
    char *pipe_cmd = (char *) cl_malloc(l+10);
    sprintf(pipe_cmd, "gzip -cd %s", align_name); /* write .gz file through gzip pipe */
    af = popen(pipe_cmd, "r");
    if (af == NULL) {
      perror(pipe_cmd);
      fprintf(stderr, "%s: can't read compressed file %s\n", progname, align_name);
      exit(1);
    }
    af_is_pipe = 1;
    cl_free(pipe_cmd);
  }
  else {
    af = fopen(align_name, "r");
    if (af == NULL) {
      perror(align_name);
      fprintf(stderr, "%s: can't read file %s\n", progname, align_name);
      exit(1);
    }
  }

  /* read header = first line */
  fgets(line, 4096, af);
  if (4 != sscanf(line, "%s %s %s %s", corpus1_name, s1_name, corpus2_name, s2_name)) {
    fprintf(stderr, "%s: %s not in .align format\n", progname, align_name);
    fprintf(stderr, "wrong header: %s", line);
    goodbye(1);
  }

  /* open corpus and attributes */
  if (NULL == (corpus1 = cl_new_corpus(registry_dir, corpus1_name))) {
    fprintf(stderr, "%s: can't open corpus %s\n", progname, corpus1_name);
    goodbye(1);
  }
  if (NULL == (corpus2 = cl_new_corpus(registry_dir, corpus2_name))) {
    fprintf(stderr, "%s: can't open corpus %s\n", progname, corpus2_name);
    goodbye(1);
  }
  if (NULL == (w1 = cl_new_attribute(corpus1, word_name, ATT_POS))) {
    fprintf(stderr, "%s: can't open p-attribute %s.%s\n", progname, corpus1_name, word_name);
    goodbye(1);
  }
  if (NULL == (w2 = cl_new_attribute(corpus2, word_name, ATT_POS))) {
    fprintf(stderr, "%s: can't open p-attribute %s.%s\n", progname, corpus2_name, word_name);
    goodbye(1);
  }
  if (NULL == (s1 = cl_new_attribute(corpus1, s1_name, ATT_STRUC))) {
    fprintf(stderr, "%s: can't open s-attribute %s.%s\n",
            progname, corpus1_name, s1_name);
    goodbye(1);
  }
  if (NULL == (s2 = cl_new_attribute(corpus2, s2_name, ATT_STRUC))) {
    fprintf(stderr, "%s: can't open s-attribute %s.%s\n",
            progname, corpus2_name, s2_name);
    goodbye(1);
  }

  printf("Displaying alignment for [%s, %s] from file %s\n",
         corpus1_name, corpus2_name, align_name);
  printf("Enter 'h' for help.\n");

  /* main loop: read commands from stdin and display alignment */
  while (42) { /* :-) */
    /* command prompt */
    printf(">> "); fflush(stdout);
    fgets(cmd, 4096, stdin);

    /* "parse" command, i.e. look at first character */
    switch (cmd[0]) {
    case '\n':
      print_next_region(af);
      break;
    case 'p':
      {
        int n;
        if (1 != sscanf(cmd+1, "%d", &n))
          n = 1;
        while ((n--) > 0) {
          print_next_region(af);
          if (n > 0) printf("\n");
        }
        break;
      }
    case 's':
      {
        int n;
        if (1 != sscanf(cmd+1, "%d", &n))
          n = 1;
        while ((n--) > 0) skip_next_region(af);
        print_next_region(af);
        break;
      }
    case 'h':
      print_help();
      break;
    case 'q': case 'x':
      goodbye(0);
    default:
      fprintf(stderr, "UNKNOWN COMMAND. Type 'h' for list of commands.\n");
    }

  }

  /* that's it (we shouldn't reach this point) */
  goodbye(0);
}


