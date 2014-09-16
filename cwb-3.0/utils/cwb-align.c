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
#include <unistd.h>
#include <math.h>

#include "../cl/cl.h"

#include "feature_maps.h"


/* global variables */

/** Name of the program (from the shell) */
char *progname;

/** number of config lines in the default config */
#define DEFAULT_CONFIG_LINES 4

/**
 * Set of strings containing default configuration options.
 *
 * Notes on interpreting the lines (in order):
 * - character count
 * - shared tokens with frequency ratio >= 1/2
 * - trigrams get 3 units
 * - 4-grams get 2*3 + 4 = 10 units
 */
char *(default_config[DEFAULT_CONFIG_LINES]) = {
  "-C:1",
  "-S:50:0.4",
  "-3:3",
  "-4:4"
};

/**
 * Pointer to configuration strings.
 *
 * Set initially to default_config ; should be reset to the
 * {config} part of argv[], if configuration is specified on the
 * command line.
 */
char **config = default_config;
/**
 * Number of lines in the configuration strings array.
 */
int config_lines = DEFAULT_CONFIG_LINES;

char *corpus1_name;             /**< name of the source corpus */
char *corpus2_name;             /**< name of the target corpus */
char *s_name;                   /**< name of the S-attribute containing sentence boundaries */
Corpus *corpus1;                /**< corpus handle: source corpus */
Corpus *corpus2;                /**< corpus handle: target corpus */
Attribute *word1;               /**< word attribute handle: source */
Attribute *s1;                  /**< sentence attribute handle: source */
Attribute *word2;               /**< word attribute handle: target */
Attribute *s2;                  /**< sentence attribute handle: target */
Attribute *prealign1 = NULL;    /**< pre-alignment attribute (source) if given */
Attribute *prealign2 = NULL;    /**< pre-alignment attribute (target) */
int size1;                      /**< size of source corpus in sentences */
int size2;                      /**< size of target corpus in sentences */
int ws1;                        /**< size of source corpus in words (i.e. corpus positions) */
int ws2;                        /**< size of target corpus in words (i.e. corpus positions) */
int pre1 = 0;                   /**< number of pre-alignment regions (source corpus) */
int pre2 = 0;                   /**< number of pre-alignment regions (target corpus) */


/* global options */

char word_name[1024] = "word";  /**< name of the word attribute (default: word) */
char outfile_name[1024] = "out.align"; /**< name of the output file */

double split_factor = 1.2;      /**< 2:2 alignment split factor */
int beam_width = 50;            /**< best path search beam width */

char prealign_name[1024] = "";  /**< pre-alignment given by structural attribute */
int prealign_has_values = 0;    /**< boolean: if 1, regions with same ID values are pre-aligned */
int verbose = 0;                /**< controls printing of some extra progress info */

char *registry_directory = NULL; /** string containing location of the registry directory. */


/**
 * Prints a message describing how to use the program to STDERR and then exits.
 */
void
print_usage(void)
{
  int i;

  fprintf(stderr, "\n");
  fprintf(stderr, "Aligns two CWB-encoded corpora.\n");
  fprintf(stderr, "\n");
  fprintf(stderr, "Usage: %s [options] <source> <target> <s-attrib> [<config>]\n", progname);
  fprintf(stderr, "  <source>    source corpus identifier\n");
  fprintf(stderr, "  <target>    target corpus identifier\n");
  fprintf(stderr, "  <s-attrib>  s-attribute used as alignment grid\n");
  fprintf(stderr, "              (must exist in both source AND target corpus)\n");
  fprintf(stderr, "Options:\n");
  fprintf(stderr, "  -P <p-att> use positional attribute <p-att> for alignment [word]\n");
  fprintf(stderr, "  -S <s-att> pre-alignment (corresponding regions of the s-attribute are\n");
  fprintf(stderr, "             pre-aligned; regions must appear in identical order!)\n");
  fprintf(stderr, "  -V <s-att> pre-alignment with ID matching (identical annotation strings)\n");
  fprintf(stderr, "  -o <file>  write alignment output to file <file>      [out.align]\n");
  fprintf(stderr, "  -s <x>     set 2:2 alignment split factor to <x>      [1.2]\n");
  fprintf(stderr, "  -w <n>     use best path search beam of width <n>     [50]\n");
  fprintf(stderr, "  -r <reg>   use registry directory <reg>\n");
  fprintf(stderr, "  -v         verbose\n");
  fprintf(stderr, "  -h         this help page\n\n");
  fprintf(stderr, "Configuration flags:\n");
  fprintf(stderr, "  -C:<w>     size of alignment region (in characters)\n");
  fprintf(stderr, "  -S:<w>:<t> shared words, i.e. identical tokens in source/target corpus\n");
  fprintf(stderr, "             [to avoid false friends, frequency ratios f1/(f1+f2) and\n");
  fprintf(stderr, "              f2/(f1+f2) must be greater than threshold <t>]\n");
  fprintf(stderr, "  -1:<w>     charcters shared by source and target region\n");
  fprintf(stderr, "  -2:<w>     bigrams     ~    ~    ~     ~    ~      ~   \n");
  fprintf(stderr, "  -3:<w>     trigrams    ~    ~    ~     ~    ~      ~   \n");
  fprintf(stderr, "  -4:<w>     4-grams     ~    ~    ~     ~    ~      ~   \n");
  fprintf(stderr, "             [N-gram features are similar to orthographic cognates]\n");
  fprintf(stderr, "  -W:<w>:<f> list of translation equivalents (read from file <f>)\n");
  fprintf(stderr, "             [format: <source word> SPC <target word>]\n");
  fprintf(stderr, "[each flag defines a set of features with weight <w> per feature]\n");
  fprintf(stderr, "\n");
  fprintf(stderr, "Default configuration:\n");
  fprintf(stderr, "  ");
  for (i = 0; i < DEFAULT_CONFIG_LINES; i++)
    fprintf(stderr, "%s ", default_config[i]);
  fprintf(stderr, "\n\n");
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
  extern int optind;            /* getopt() interface */
  extern char *optarg;          /* getopt() interface */
  int c;

  progname = av[0];
  while ((c = getopt(ac, av, "+hvo:P:S:V:s:w:r:")) != EOF)
    switch (c) {
      /* -P: positional attribute */
    case 'P':
      strcpy(word_name, optarg);
      break;
      /* -S: pre-alignment */
    case 'S':
      strcpy(prealign_name, optarg);
      prealign_has_values = 0;
      break;
      /* -V: pre-alignment with ID matching */
    case 'V':
      strcpy(prealign_name, optarg);
      prealign_has_values = 1;
      break;
      /* -o: output file */
    case 'o':
      strcpy(outfile_name, optarg);
      break;
      /* -s: split factor */
    case 's':
      {
        double factor;
        if (1 == sscanf(optarg, "%lf", &factor))
          split_factor = factor;
        else
          print_usage();
        break;
      }
      /* -w: beam width */
    case 'w':
      {
        int width;
        if ((1 == sscanf(optarg, "%d", &width))
            && (width > 10))
          beam_width = width;
        else
          print_usage();
        break;
      }
      /* -v : verbose */
    case 'v':
      verbose = 1;
      break;
      /* -r: registry directory */
    case 'r':
      if (registry_directory == NULL)
        registry_directory = optarg;
      else {
        fprintf(stderr, "%s: -r option used twice\n", progname);
        exit(2);
      }
      break;
      /* -h : help page = usage */
    case 'h':
      /* unknown option: print usage */
    default:
      print_usage();
    }

  if (ac - optind < min_args)
     print_usage();

  return(optind);               /* return index of first argument in argv[] */
}

/*
   write given information to file <fd> as a .align format line
   */
/**
 * Prints an alignment line.
 *
 * This function writes the given information to the specified
 * file handle as a .align format line.
 *
 * A .align line looks like this:
 * {f1} {l1} {f2} {l2} {type} [{quality}]
 *   eg. "140 169 137 180 1:2" means that corpus (position) ranges
 *   [140,169] and [137,180] form a 1:2 alignment pair .
 *
 * Usage:
 * print_align_line(fd, f1, l1, f2, l2, quality);
 *
 * @param fd       File handle to print to.
 * @param f1       First cpos in source corpus.
 * @param l1       Last cpos in source corpus.
 * @param f2       First cpos in target corpus.
 * @param l2       Last cpos in target corpus.
 * @param quality  Quality of the alignment.
 *
 */
void
print_align_line(FILE *fd, int f1, int l1, int f2, int l2, int quality)
{
  int step1 = l1 - f1, step2 = l2 - f2;
  int wf1, wl1, wf2, wl2, dummy;

  l1--; l2--;
  cl_struc2cpos(s1, f1, &wf1, &dummy);
  cl_struc2cpos(s2, f2, &wf2, &dummy);
  if (l1 >= f1)
    cl_struc2cpos(s1, l1, &dummy, &wl1);
  else wl1 = wf1 - 1;
  if (l2 >= f2)
    cl_struc2cpos(s2, l2, &dummy, &wl2);
  else wl2 = wf2 - 1;


  fprintf(fd, "%d\t%d\t%d\t%d\t%d:%d\t%d\n",
          wf1, wl1, wf2, wl2, step1, step2, quality);
}


/**
 * Actually does the alignment.
 *
 * This function run a best_path alignment on sentence regions
 * [f1,l1]x[f2,l2] and writes the result to {outfile}
 * (in .align format).
 *
 * Usage:
 * steps = do_alignment(FMS, f1, l1, f2, l2, outfile);
 *
 * @param fms      The feature map to use in best_path alignment.
 * @param if1      First cpos in source corpus.
 * @param il1      Last cpos in source corpus.
 * @param if2      First cpos in target corpus.
 * @param il2      Last cpos in target corpus.
 * @param outfile  File handle to print the alignment lines to.
 */
int
do_alignment(FMS fms, int if1, int il1, int if2, int il2, FILE *outfile) {
  int steps, *out1, *out2, *quality;    /* return values of best_path() */
  int f1 = 0, l1 = 0, f2 = 0, l2 = 0;
  int q1 = 0, q2 = 0;
  int i, steps_created;

  best_path(fms, if1, il1, if2, il2, beam_width, verbose,
            &steps, &out1, &out2, &quality);

  steps_created = 0;
  for (i=0; i < (steps - 1); i++) {
    f1 = out1[i]; l1 = out1[i+1];
    f2 = out2[i]; l2 = out2[i+1];
    if (((l1-f1) == 2) && ((l2-f2) == 2)) {
      /* 2:2 alignment -> attempt split */
      q1 = feature_match(fms, f1, f1, f2, f2);
      q2 = feature_match(fms, f1+1, f1+1, f2+1, f2+1);
      /* combined quality of two 1:1 alignments */
      if (quality[i] <= split_factor * (q1 + q2)) {
        /* split */
        print_align_line(outfile, f1, f1+1, f2, f2+1, q1);
        print_align_line(outfile, f1+1, l1, f2+1, l2, q2);
        steps_created += 2;
        continue;
      }
      /* else go on and print 2:2 alignment */
    }
    print_align_line(outfile, f1, l1, f2, l2, quality[i]);
    steps_created++;
  }
  return steps_created;
}




/* *************** *\
 *      MAIN()     *
\* *************** */

/**
 * Main function for cwb-align.
 *
 * @param argc   Number of command-line arguments.
 * @param argv   Command-line arguments.
 */
int
main(int argc, char *argv[]) {
  int argindex;                 /* index of first argument in argv[] */
  FMS fms;
  FILE *of;                     /* output file */
  int of_is_pipe;               /* have to know whether to call fclose() or pclose() */
  int steps = 0;
  int l;

  /* parse command line and read arguments */
  argindex = parse_args(argc, argv, 3);
  corpus1_name = argv[argindex++];
  corpus2_name = argv[argindex++];
  s_name = argv[argindex++];

  /* any further arguments are config data & override the default config */
  if (argindex < argc) {
    config = argv + argindex;   /* config now points to first <config> item on command line */
    config_lines = argc - argindex; /* number of remaining items */
  }

  /* open corpora and attributes */
  if (!(corpus1 = cl_new_corpus(registry_directory, corpus1_name))) {
    fprintf(stderr, "%s: can't open corpus %s\n", progname, corpus1_name);
    exit(1);
  }
  if (!(corpus2 = cl_new_corpus(registry_directory, corpus2_name))) {
    fprintf(stderr, "%s: can't open corpus %s\n", progname, corpus2_name);
    exit(1);
  }
  if (!(word1 = cl_new_attribute(corpus1, word_name, ATT_POS))) {
    fprintf(stderr, "%s: can't open p-attribute %s.%s\n",
            progname, corpus1_name, word_name);
    exit(1);
  }
  if (!(word2 = cl_new_attribute(corpus2, word_name, ATT_POS))) {
    fprintf(stderr, "%s: can't open p-attribute %s.%s\n",
            progname, corpus2_name, word_name);
    exit(1);
  }
  if (!(s1 = cl_new_attribute(corpus1, s_name, ATT_STRUC))) {
    fprintf(stderr, "%s: can't open s-attribute %s.%s\n",
            progname, corpus1_name, s_name);
    exit(1);
  }
  if (!(s2 = cl_new_attribute(corpus2, s_name, ATT_STRUC))) {
    fprintf(stderr, "%s: can't open s-attribute %s.%s\n",
            progname, corpus2_name, s_name);
    exit(1);
  }

  /* get size of corpora (and check for data access errors) */
  ws1 = cl_max_cpos(word1);
  if (ws1 <= 0) {
    fprintf(stderr, "%s: data access error (%s.%s)\n",
            progname, corpus1_name, word_name);
    exit(1);
  }
  ws2 = cl_max_cpos(word2);
  if (ws2 <= 0) {
    fprintf(stderr, "%s: data access error (%s.%s)\n",
            progname, corpus2_name, word_name);
    exit(1);
  }
  size1 = cl_max_struc(s1);
  if (size1 <= 0) {
    fprintf(stderr, "%s: data access error (%s.%s)\n",
            progname, corpus1_name, s_name);
    exit(1);
  }
  size2 = cl_max_struc(s2);
  if (size2 <= 0) {
    fprintf(stderr, "%s: data access error (%s.%s)\n",
            progname, corpus2_name, s_name);
    exit(1);
  }
  printf("OPENING %s [%d tokens, %d <%s> regions]\n",
         corpus1_name, ws1, size1, s_name);
  printf("OPENING %s [%d tokens, %d <%s> regions]\n",
         corpus2_name, ws2, size2, s_name);

  /* open pre-alignment attributes if requested */
  if (*prealign_name != '\0') {
    if (!(prealign1 = cl_new_attribute(corpus1, prealign_name, ATT_STRUC))) {
      fprintf(stderr, "%s: can't open s-attribute %s.%s\n",
              progname, corpus1_name, prealign_name);
      exit(1);
    }
    if (!(prealign2 = cl_new_attribute(corpus2, prealign_name, ATT_STRUC))) {
      fprintf(stderr, "%s: can't open s-attribute %s.%s\n",
              progname, corpus2_name, prealign_name);
      exit(1);
    }
    pre1 = cl_max_struc(prealign1);
    if (pre1 <= 0) {
      fprintf(stderr, "%s: data access error (%s.%s)\n",
              progname, corpus1_name, prealign_name);
      exit(1);
    }
    pre2 = cl_max_struc(prealign2);
    if (pre2 <= 0) {
      fprintf(stderr, "%s: data access error (%s.%s)\n",
              progname, corpus2_name, prealign_name);
      exit(1);
    }
    printf("OPENING prealignment [%s.%s: %d regions, %s.%s: %d regions]\n",
           corpus1_name, prealign_name, pre1, corpus2_name, prealign_name, pre2);
    if (prealign_has_values) {
      /* -V: check if pre-alignment attributes really have annotations */
      if (! (cl_struc_values(prealign1) && cl_struc_values(prealign2))) {
        fprintf(stderr, "%s: -V option requires s-attribute with annotations!\n",
                progname);
        exit(1);
      }
    }
    else {
      /* -S: consistency check. there must be as many source regions as target regions */
      if (pre1 != pre2) {
        fprintf(stderr, "%s: -S switch used with inconsistent prealignment\n", progname);
        fprintf(stderr, "%s: (%d <%s> regions in %s vs. %d <%s> regions in %s)\n",
                progname, pre1, prealign_name, corpus1_name, pre2, prealign_name, corpus2_name);
        exit(1);
      }
    }
  }

  /* create feature maps structure */
  fms = create_feature_maps(config, config_lines, word1, word2, s1, s2);

  /* open output file (or pipe to gzip for .gz file) */
  of_is_pipe = 0;
  l = strlen(outfile_name);
  if ((l > 3) && (strncasecmp(outfile_name + l - 3, ".gz", 3) == 0)) {
    char *pipe_cmd = (char *) cl_malloc(l+8);
    sprintf(pipe_cmd, "gzip > %s", outfile_name); /* write .gz file through gzip pipe */
    of = popen(pipe_cmd, "w");
    if (of == NULL) {
      perror(pipe_cmd);
      fprintf(stderr, "%s: can't write compressed file %s\n", progname, outfile_name);
      exit(1);
    }
    of_is_pipe = 1;
    cl_free(pipe_cmd);
  }
  else {
    of = fopen(outfile_name, "w");
    if (of == NULL) {
      perror(outfile_name);
      fprintf(stderr, "%s: can't write file %s\n", progname, outfile_name);
      exit(1);
    }
  }

  /* .align header: <source> <s> <target> <s> */
  fprintf(of, "%s\t%s\t%s\t%s\n", corpus1_name, s_name, corpus2_name, s_name);

  /* DO THE ALIGNMENT */
  if (prealign1 == NULL) {
    /* neither -S nor -V used: just do a global alignment */
    printf("Running global alignment, please be patient ...\n");
    steps = do_alignment(fms, 0, size1 - 1, 0, size2 - 1, of);
  } /* end of global alignment */

  else if (!prealign_has_values) {
    /* -S switch: use pre-aligned regions in given order */
    int i = 0;
    int start, end, start1, end1, start2, end2;
    int f1, l1, f2, l2;

    for (i = 0; i < pre1; i++) {
      /* find first and last <s> structure in prealignment region (must be aligned with pre-alignment) */
      if (
          (0 > cl_struc2cpos(prealign1, i, &start1, &end1)) ||
          (0 > (f1 = cl_cpos2struc(s1, start1))) ||
          (0 > (l1 = cl_cpos2struc(s1, end1))) ||
          (0 > cl_struc2cpos(prealign2, i, &start2, &end2)) ||
          (0 > (f2 = cl_cpos2struc(s2, start2))) ||
          (0 > (l2 = cl_cpos2struc(s2, end2)))
          ) {
        fprintf(stderr, "%s: ERROR <%s> regions do not form a partitioning of <%s> region!\n",
                progname, s_name, prealign_name);
        exit(1);
      }
      /* check that the <s> structures do not extend beyond the pre-alignment boundaries;
         otherwise the resulting alignment file will be invalid */
      if (
          (0 > cl_struc2cpos(s1, f1, &start, &end)) ||
          (start != start1) ||
          (0 > cl_struc2cpos(s1, l1, &start, &end)) ||
          (end != end1) ||
          (0 > cl_struc2cpos(s2, f2, &start, &end)) ||
          (start != start2) ||
          (0 > cl_struc2cpos(s2, l2, &start, &end)) ||
          (end != end2)
          ) {
        fprintf(stderr, "%s: ERROR <%s> regions do not form a partitioning of <%s> region!\n",
                progname, s_name, prealign_name);
        exit(1);
      }

      printf("Aligning <%s> region #%d = [%d, %d] x [%d, %d]\n",
             prealign_name, i, f1, l1, f2, l2);
      steps += do_alignment(fms, f1, l1, f2, l2, of);
    }
  } /* end of -S type alignment */

  else {
    /* -V switch: this is the tricky bit -- need to find matching annotation strings */
    cl_lexhash lh = cl_new_lexhash(2 * pre2); /* use lexhash to identify target regions; make number of buckets large enough for fast access */
    cl_lexhash_entry entry;
    int start, end;
    int f1, l1, f2, l2;
    char *value;
    int i;

    /* read pre-alignment annotations into lexhash */
    printf("Caching pre-alignment IDs (%s.%s)\n", corpus1_name, prealign_name);
    for (i = 0; i < pre2; i++) {
      value = cl_struc2str(prealign2, i);
      entry = cl_lexhash_add(lh, value);
      entry->data.integer = i;
    }

    /* now go through pre-alignment regions in the source corpus and try to find matching ID in target corpus */
    for (i = 0; i < pre1; i++) {
      value = cl_struc2str(prealign1, i);
      /* look for matching region in target corpus */
      entry = cl_lexhash_find(lh, value);
      if (entry == NULL) {
        /* no match found */
        printf("[Skipping source region <%s %s>]\n",
               prealign_name, value);
      }
      else {
        int j = entry->data.integer;    /* number of target region */
        if (
            (0 > cl_struc2cpos(prealign1, i, &start, &end)) ||
            (0 > (f1 = cl_cpos2struc(s1, start))) ||
            (0 > (l1 = cl_cpos2struc(s1, end))) ||
            (0 > cl_struc2cpos(prealign2, j, &start, &end)) ||
            (0 > (f2 = cl_cpos2struc(s2, start))) ||
            (0 > (l2 = cl_cpos2struc(s2, end)))
            ) {
          fprintf(stderr, "%s: ERROR <%s> regions do not form a partitioning of <%s> region!\n",
                  progname, s_name, prealign_name);
          exit(1);
        }

        printf("Aligning <%s %s> regions = [%d, %d] x [%d, %d]\n",
               prealign_name, value, f1, l1, f2, l2);
        steps += do_alignment(fms, f1, l1, f2, l2, of);
        j++;                    /* go to next target region */
      }
    }

    cl_delete_lexhash(lh);
  } /* end of -V type alignment */
  printf("Alignment complete. [created %d alignment regions]\n", steps);


  /* close output file */
  if (of_is_pipe)
    pclose(of);
  else
    fclose(of);

  /* that's it */
  return 0;
}

