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

#include "../cl/globals.h"
#include "../cl/cl.h"
#include "../cl/corpus.h"
#include "../cl/attributes.h"

char *progname = NULL;
char *registry_directory = NULL;
char *corpus_id = NULL;
Corpus *corpus = NULL;

/* ---------------------------------------- */

/**
 * Maximum number of attributes that can be printed.
 */
#define MAX_ATTRS 1024

typedef Attribute * ATPtr;
ATPtr print_list[MAX_ATTRS];    /**< list of attributes selected by user for printing */
int print_list_index = 0;       /**< denotes the last attribute to be printed */

/* before a token is printed, all regions of s-attributes from print_list[] which contain that token are copied to s_att_regions[],
   bubble-sorted (to enforce proper nesting while retaining the specified order as far as possible), and printed from s_att_regions[] */
typedef struct {
  char *name;                   /**< name of the s-attribute */
  int start;
  int end;
  char *annot;                  /**< NULL if there is no annotation */
} SAttRegion;
SAttRegion s_att_regions[MAX_ATTRS];
int sar_sort_index[MAX_ATTRS];  /**< index used for bubble-sorting list of regions */
int N_sar = 0;                  /**< number of regions currently in list (may change for each token printed) */

/* ---------------------------------------- */

#define MAX_PRINT_VALUES 1024

ATPtr printValues[MAX_PRINT_VALUES];
int printValuesIndex = 0;

/* ---------------------------------------- */

int first_token = 0;
int last = 0;
int maxlast = -1;
int printnum = 0;


typedef enum _output_modes {
  StandardMode, LispMode, EncodeMode, ConclineMode, XMLMode
} OutputMode;

int mode = StandardMode;
int xml_compatible = 0;         /* EncodeMode only, selected by option -Cx */


/* not really necessary, but we'll keep it for now -- it's cleaner anyway :o) */
/**
 * Cleans up memory prior to an error-prompted exit.
 *
 * @param error_code  Value to be returned by the program when it exits.
 */
void
cleanup(int error_code)
{
  if (corpus != NULL)
    drop_corpus(corpus);
  exit(error_code);
}

/**
 * Prints a usage message and exits the program.
 *
 * @param exit_code  Value to be returned by the program when it exits.
 */
void
usage(int exit_code) {
  fprintf(stderr, "\n");
  fprintf(stderr, "Usage:  %s [options] <corpus> [flags]\n\n", progname);
  fprintf(stderr, "Decodes CWB corpus as plain text (or in various other text formats).\n");
  fprintf(stderr, "In normal mode, the entire corpus (or a segment specified with the\n");
  fprintf(stderr, "-s and -e options) is printed on stdout. In matchlist mode (-p or -f),\n");
  fprintf(stderr, "(pairs of) corpus positions are read from stdin (or a file specified\n");
  fprintf(stderr, "with -f), and the corresponding tokens or ranges are displayed. The\n");
  fprintf(stderr, "[flags] determine which attributes to display (-ALL for all attributes).\n");
  fprintf(stderr, "See list of options for available output modes.\n");
  fprintf(stderr, "\n");
  fprintf(stderr, "Options:\n");
  fprintf(stderr, "  -L        Lisp output mode\n");
  fprintf(stderr, "  -H        concordance line ('horizontal') output mode\n");
  fprintf(stderr, "  -C        compact output mode (suitable for encode)\n");
  fprintf(stderr, "  -Cx       XML-compatible compact output (for \"encode -x ...\")\n");
  fprintf(stderr, "  -X        XML output mode\n");
  fprintf(stderr, "  -n        show corpus position ('numbers')\n");
  fprintf(stderr, "  -s <n>    first token to print (at corpus position <n>)\n");
  fprintf(stderr, "  -e <n>    last token to print (at corpus position <n>)\n");
  fprintf(stderr, "  -r <dir>  set registry directory\n");
  fprintf(stderr, "  -p        matchlist mode (input from stdin)\n");
  fprintf(stderr, "  -f <file> matchlist mode (input from <file>)\n");
  fprintf(stderr, "  -h        this help page\n\n");
  fprintf(stderr, "Flags:\n");
  fprintf(stderr, "  -P <att>  print p-attribute <att>\n");
  fprintf(stderr, "  -S <att>  print s-attribute <att> (possibly including annotations)\n");
  fprintf(stderr, "  -V <att>  show s-attribute annotation for each range in matchlist mode\n");
  fprintf(stderr, "  -A <att>  print alignment attribute <att>\n");
  fprintf(stderr, "  -ALL      print all p-attributes and s-attributes\n");
  fprintf(stderr, "  -c <att>  expand ranges to full <att> region (matchlist mode)\n\n");
  fprintf(stderr, "Part of the IMS Open Corpus Workbench v" VERSION "\n\n");

  cleanup(exit_code);
}

/**
 * Check whether a string represents a number.
 *
 * @param s  The string to check.
 * @return   Boolean: true iff s contains only digits.
 */
int
is_num(char *s) {
  int i;

  for (i = 0; s[i]; i++)
    if (!isdigit((unsigned char) s[i]))
      return 0;

  return 1;
}

/* Convert string to Lisp string with required escapes (probably)
   warning: returns pointer to static internal buffer of fixed size
   */
char *
lisp_string(char *s) {
  int i, t;
  static char ls[MAX_LINE_LENGTH];

  if (mode == LispMode) {

    t = 0;

    for (i = 0; s[i]; i++) {
      if ((s[i] == '"') || (s[i] == '\\')) {
        ls[t++] = '\\';
        ls[t++] = '\\';
        ls[t++] = '\\';
      }
      ls[t++] = s[i];
    }
    ls[t] = '\0';
    return ls;
  }
  else
    return s;
}

/* Convert string to ISO-8859-* encoded XML string; all 'critical' characters are replaced by entity references;
   warning: returns pointer to static internal buffer of fixed size; in particular, don't use it twice in a single argument list!
   */
char *
xml_string(char *s) {
  int i, t;
  static char ls[MAX_LINE_LENGTH];

  if ((mode == XMLMode) || xml_compatible) {
    t = 0;

    for (i = 0; s[i]; i++) {
      if (s[i] == '"') {
        sprintf(ls+t, "&quot;");
        t += strlen(ls+t);
      }
      else if (s[i] == '\'') {
        sprintf(ls+t, "&apos;");
        t += strlen(ls+t);
      }
      else if (s[i] == '<') {
        sprintf(ls+t, "&lt;");
        t += strlen(ls+t);
      }
      else if (s[i] == '>') {
        sprintf(ls+t, "&gt;");
        t += strlen(ls+t);
      }
      else if (s[i] == '&') {
        sprintf(ls+t, "&amp;");
        t += strlen(ls+t);
      }
      else if ((s[i] > 0) && (s[i] < 32)) {
        /* C0 controls are invalid -> substitute blanks */
        ls[t++] = ' ';
      }
      else {
        ls[t++] = s[i];
      }
    }
    ls[t] = '\0';               /* terminate converted string and return it */
    return ls;
  }
  else
    return s;
}

/* prints XML declaration, using character set specification obtained from <corpus> */
void
print_xml_declaration(void) {
  CorpusCharset charset = unknown_charset;
  if (corpus) {
    charset = cl_corpus_charset(corpus);
  }

  printf("<?xml version=\"1.0\" encoding=\"");
  switch (charset) {
  case latin1:
    printf("ISO-8859-1");
    break;
  case latin2:
    printf("ISO-8859-2");
    break;
  case latin3:
    printf("ISO-8859-3");
    break;
  case latin4:
    printf("ISO-8859-4");
    break;
  case latin5:
    printf("ISO-8859-5");
    break;
  case latin6:
    printf("ISO-8859-6");
    break;
  case latin7:
    printf("ISO-8859-7");
    break;
  case latin8:
    printf("ISO-8859-8");
    break;
  case latin9:
    printf("ISO-8859-9");
    break;
  case utf8:
    printf("UTF-8");
    break;
  case unknown_charset:
  default:
    printf("ISO-8859-1");       /* at least the parser isn't going to break down that way. probably. */
    break;
  }
  printf("\" standalone=\"yes\" ?>\n");
}


/* sort s_att_regions[MAX_ATTRS] in ascending 'nested' order, using sar_sort_index[] (which is automatically initialised);
   since only regions which begin or end at the current token are considered, such an ordering is always possible;
   without knowing the current token, we sort by end position descending, then by start position ascending, which gives us:
    - first the regions corresponding to start tags, beginning with the 'largest' region
    - then the regions corresponding to end tags, again beginning with the 'largest' region
   uses bubble sort in order to retaining the existing order of identical regions; */
void
sort_s_att_regions(void) {
  int i, temp, modified;

  for (i = 0; i < N_sar; i++)   /* initialise sort index */
    sar_sort_index[i] = i;

  modified = 1;                 /* repeat 'bubble' loop until no more modifications are made */
  while (modified) {
    modified = 0;
    for (i = 0; i < (N_sar-1); i++) {
      SAttRegion *a = &(s_att_regions[sar_sort_index[i]]); /* compare *a and *b */
      SAttRegion *b = &(s_att_regions[sar_sort_index[i+1]]);

      if ( (a->end < b->end) ||
           ((a->end == b->end) && (a->start > b->start)) ) {
        temp = sar_sort_index[i]; /* swap sar_sort_index[i] and sar_sort_index[i+1] */
        sar_sort_index[i] = sar_sort_index[i+1];
        sar_sort_index[i+1] = temp;
        modified = 1;           /* modified ordering, so we need another loop iteration */
      }
    }
  }

  return;
}

int
attr_member(Attribute *attr, ATPtr *att_list, int att_list_size)
{
  int i;
  for (i = 0; i < att_list_size; i++)
    if (att_list[i] == attr)
      return 1;
  return 0;
}

int
add_attribute(Attribute *attr)
{
  if (print_list_index < MAX_ATTRS) {
    if (attr_member(attr, print_list, print_list_index)) {
      fprintf(stderr, "Attribute %s.%s added twice to print list (ignored)\n",
              corpus_id, attr->any.name);
      return 0;
    }

    print_list[print_list_index++] = attr;
    return 1;
  }
  else {
    fprintf(stderr, "Too many attributes (maximum is %d). Aborted.\n",
            MAX_ATTRS);
    cleanup(2);
    return 0;
  }
}

int
verify_print_value_list() {
  int i;

  for (i = 0; i < printValuesIndex; i++) {
    if (attr_member(printValues[i], print_list, print_list_index)) {
      fprintf(stderr, "Warning: s-attribute %s.%s used with both -S and -V !\n",
              corpus_id, printValues[i]->any.name);
    }
  }
  return 1;
}

void
showSurroundingStructureValues(int position) {
  int i;
  char *tagname;

  for (i = 0; i < printValuesIndex; i++) {

    if (printValues[i]) {

      char *sval;
      int snum;

      snum = cl_cpos2struc(printValues[i], position);
      if (snum >= 0) {
        sval = cl_struc2str(printValues[i], snum);
        tagname = printValues[i]->any.name;

        switch (mode) {
        case ConclineMode:
          printf("<%s %s>: ", tagname, sval);
          break;

        case LispMode:
          printf("(VALUE %s \"%s\")\n", tagname, lisp_string(sval));
          break;

        case XMLMode:
          printf("<element name=\"%s\" value=\"%s\"/>\n", tagname, xml_string(sval));
          break;

        case EncodeMode:
          printf("# %s=%s\n", tagname, sval); /* pretends to be a comment, but has to be stripped before feeding output to encode */
          break;

        case StandardMode:
        default:
          printf("<%s %s>\n", tagname, sval);
          break;
        }
      }
      else {
        /* don't print tag if start position is not in region */
      }

    }
  }
}


/* show the requested attributes for a sequence of tokens (or a single token if end_position == -1);
   if -c flag was used, sequence is extended to entire s-attribute region (for matchlist mode) */
void
show_position_values(int start_position, int end_position, Attribute *context) {

  int alg, aligned_start, aligned_end, aligned_start2, aligned_end2,
    rng_start, rng_end, snum;
  int start_context, end_context, dummy;
  int lastposa, i, w;
  char *wrd;


  start_context = start_position;
  end_context = (end_position >= 0) ? end_position : start_position;

  if (context != NULL) {

    if (!cl_cpos2struc2cpos(context, start_position,
                            &start_context, &end_context)) {
      start_context = start_position;
      end_context = (end_position >= 0) ? end_position : start_position;
    }
    else if (end_position >= 0) {
      if (!get_struc_attribute(context, end_position,
                               &dummy, &end_context)) {
        end_context = (end_position >= 0) ? end_position : start_position;
      }
    }

    /* indicate that we're showing context */
    switch (mode) {
    case LispMode:
      printf("(TARGET %d\n", start_position);
      if (end_position >= 0)
        printf("(INTERVAL %d %d)\n", start_position, end_position);
      break;
    case EncodeMode:
    case ConclineMode:
      /* nothing here */
      break;
    case XMLMode:
      printf("<context start=\"%d\" end=\"%d\"/>\n", start_context, end_context);
      break;
    case StandardMode:
    default:
      if (end_position >= 0) {
        printf("INTERVAL %d %d\n", start_position, end_position);
      }
      else {
        printf("TARGET %d\n", start_position);
      }
      break;
    }

  }

  /* some extra information in -L and -H modes */
  if ((mode == LispMode) && (end_position != -1))
    printf("(CONTEXT %d %d)\n", start_context, end_context);
  else if (mode == ConclineMode) {
    if (printnum)
      printf("%8d: ", start_position);
  }

  /* now print the token sequence (including context) with all requested attributes */
  for (w = start_context; w <= end_context; w++) {
    int beg_of_line;

    /* extract s-attribute regions for start and end tags into s_att_regions[] */
    N_sar = 0;                  /* counter and index */
    for (i = 0; i < print_list_index; i++) {
      if (print_list[i]->any.type == ATT_STRUC) {
        if ( ((snum = cl_cpos2struc(print_list[i], w)) >= 0) &&
             (cl_struc2cpos(print_list[i], snum, &rng_start, &rng_end)) &&
             ((w == rng_start) || (w == rng_end)) ) {
          s_att_regions[N_sar].name = print_list[i]->any.name;
          s_att_regions[N_sar].start = rng_start;
          s_att_regions[N_sar].end = rng_end;
          if (cl_struc_values(print_list[i]))
            s_att_regions[N_sar].annot = cl_struc2str(print_list[i], snum);
          else
            s_att_regions[N_sar].annot = NULL;
          N_sar++;
        }
      }
    }
    sort_s_att_regions();       /* sort regions to ensure proper nesting of start and end tags */

    /* show corpus positions with -n option */
    if (printnum)
      switch (mode) {
      case LispMode:
        printf("(%d ", w);
        break;
      case EncodeMode:
        printf("%8d\t", w);
        break;
      case ConclineMode:
        /* nothing here (shown at start of line in -H mode) */
        break;
      case XMLMode:
        /* nothing here */
        break;
      case StandardMode:
      default:
        printf("%8d: ", w);
        break;
      }
    else {
      if (mode == LispMode)
        printf("(");            /* entire match is parenthesised list in -L mode */
    }

    lastposa = -1;

    /* print start tags (s- and a-attributes) with -C,-H,-X */
    if ((mode == EncodeMode) || (mode == ConclineMode) || (mode == XMLMode)) {

      /* print a-attributes from print_list[] */
      for (i = 0; i < print_list_index; i++) {
        switch (print_list[i]->any.type) {
        case ATT_ALIGN:
          if (
              ((alg = cl_cpos2alg(print_list[i], w)) >= 0)
              && (cl_alg2cpos(print_list[i], alg,
                              &aligned_start, &aligned_end,
                              &aligned_start2, &aligned_end2))
              && (w == aligned_start)
              ) {
            if (mode == XMLMode) {
              printf("<align type=\"start\" target=\"%s\"", print_list[i]->any.name);
              if (printnum)
                printf(" start=\"%d\" end=\"%d\"", aligned_start2, aligned_end2);
              printf("/>\n");
            }
            else {
              printf("<%s", print_list[i]->any.name);
              if (printnum)
                printf(" %d %d", aligned_start2, aligned_end2);
              printf(">%c", (mode == EncodeMode) ? '\n' : ' ');
            }
          }
          break;

        default:                /* ignore all other attribute types */
          break;
        }
      }

      /* print s-attributes from s_att_regions[] (using sar_sort_index[]) */
      for (i = 0; i < N_sar; i++) {
        SAttRegion *region = &(s_att_regions[sar_sort_index[i]]);

        if (region->start == w) {
          if (mode == XMLMode) {
            printf("<tag type=\"start\" name=\"%s\"", region->name);
            if (printnum)
              printf(" cpos=\"%d\"", w);
            if (region->annot)
              printf(" value=\"%s\"", xml_string(region->annot));
            printf("/>\n");
          }
          else {
            printf("<%s%s%s>%c",
                   region->name,
                   region->annot ? " " : "",
                   region->annot ? region->annot : "",
                   (mode == ConclineMode ? ' ' : '\n'));
          }
        }
      }

    }

    /* now print token with its attribute values (p-attributes only for -C,-H,-X) */
    if (mode == XMLMode) {
      printf("<token");
      if (printnum)
        printf(" cpos=\"%d\"", w);
      printf(">");
    }

    beg_of_line = 1;
    for (i = 0; i < print_list_index; i++) {

      switch (print_list[i]->any.type) {
      case ATT_POS:
        lastposa = i;
        if ((wrd = cl_cpos2str(print_list[i], w)) != NULL)
          switch (mode) {
          case LispMode:
            printf("(%s \"%s\")", print_list[i]->any.name, lisp_string(wrd));
            break;

          case EncodeMode:
            if (xml_compatible)
              wrd = xml_string(wrd);
            if (beg_of_line) {
              printf("%s", wrd);
              beg_of_line = 0;
            }
            else
              printf("\t%s", wrd);
            break;

          case ConclineMode:
            if (beg_of_line) {
              printf("%s", wrd);
              beg_of_line = 0;
            }
            else
              printf("/%s", wrd);
            break;

          case XMLMode:
            printf(" <attr name=\"%s\">%s</attr>",
                   print_list[i]->any.name, xml_string(wrd));
            break;

          case StandardMode:
          default:
            printf("%s=%s\t", print_list[i]->any.name, wrd);
            break;
          }
        else {
          cdperror("(aborting) cl_cpos2str() failed");
          cleanup(1);
        }
        break;

      case ATT_ALIGN:
        if ((mode != EncodeMode) && (mode != ConclineMode) && (mode != XMLMode)) {
          if (
              ((alg = cl_cpos2alg(print_list[i], w)) >= 0)
              && (cl_alg2cpos(print_list[i], alg,
                              &aligned_start, &aligned_end,
                              &aligned_start2, &aligned_end2))
              ) {
            if (mode == LispMode) {
              printf("(ALG %d %d %d %d)",
                     aligned_start, aligned_end, aligned_start2, aligned_end2);
            }
            else {
              printf("%d-%d==>%s:%d-%d\t",
                     aligned_start, aligned_end, print_list[i]->any.name, aligned_start2, aligned_end2);
            }
          }
          else if (cderrno != CDA_OK) {
            cdperror("(aborting) alignment error");
            cleanup(1);
          }
        }
        break;

      case ATT_STRUC:
        if ((mode != EncodeMode) && (mode != ConclineMode) && (mode != XMLMode)) {
          if (cl_cpos2struc2cpos(print_list[i], w, &rng_start, &rng_end)) {
            /* standard and -L mode don't show tag annotations */
            printf(mode == LispMode ? "(STRUC %s %d %d)" : "<%s>:%d-%d\t",
                   print_list[i]->any.name,
                   rng_start, rng_end);
          }
          else if (cderrno != CDA_OK)
            cdperror("(aborting) cl_cpos2struc2cpos() failed");
        }
        break;

      case ATT_DYN:
        /* dynamical attributes aren't implemented */
      default:
        break;
      }
    }

    /* print token separator (or end of token in XML mode) */
    switch (mode) {
    case LispMode:
      printf(")\n");
      break;
    case ConclineMode:
      printf(" ");
      break;
    case XMLMode:
      printf(" </token>\n");
      break;
    case EncodeMode:
    case StandardMode:
    default:
      printf("\n");
      break;
    }

    /* now, after printing all the positional attributes, print end tags with -H,-C,-X */
    if ((mode == EncodeMode)  || (mode == ConclineMode) || (mode == XMLMode)) {

      /* print s-attributes from s_att_regions[] (using sar_sort_index[] in reverse order) */
      for (i = N_sar - 1; i >= 0; i--) {
        SAttRegion *region = &(s_att_regions[sar_sort_index[i]]);

        if (region->end == w) {
          if (mode == XMLMode) {
            printf("<tag type=\"end\" name=\"%s\"", region->name);
            if (printnum)
              printf(" cpos=\"%d\"", w);
            printf("/>\n");
          }
          else {
            printf("</%s>%c", region->name,
                   (mode == ConclineMode ? ' ' : '\n'));
          }
        }
      }

      /* print a-attributes form print_list[] */
      for (i = 0; i < print_list_index; i++) {
        switch (print_list[i]->any.type) {
        case ATT_ALIGN:
          if (
              ((alg = cl_cpos2alg(print_list[i], w)) >= 0)
              && (cl_alg2cpos(print_list[i], alg,
                              &aligned_start, &aligned_end,
                              &aligned_start2, &aligned_end2))
              && (w == aligned_end)
              ) {
            if (mode == XMLMode) {
              printf("<align type=\"end\" target=\"%s\"", print_list[i]->any.name);
              if (printnum)
                printf(" start=\"%d\" end=\"%d\"", aligned_start2, aligned_end2);
              printf("/>\n");
            }
            else {
              printf("</%s", print_list[i]->any.name);
              if (printnum)
                printf(" %d %d", aligned_start2, aligned_end2);
              printf(">%c", (mode == EncodeMode) ? '\n' : ' ');
            }
          }
          break;

        default:                /* ignore all other attribute types */
          break;
        }
      }

    }

  }  /* end of match range loop */

  /* end of match (for matchlist mode in particular) */
  if ((context != NULL) && (mode == LispMode))
    printf(")\n");
  else if (mode == ConclineMode)
    printf("\n");

  return;
}


/* *************** *\
 *      MAIN()     *
\* *************** */

/**
 * Main function for cwb-decode.
 *
 * @param argc   Number of command-line arguments.
 * @param argv   Command-line arguments.
 */
int
main(int argc, char **argv)
{
  Attribute *attr;
  Attribute *context = NULL;

  int sp, ep;

  int w, cnt, read_pos_frm_stdin;

  char s[1024];
  char *token;

  char *input_filename = NULL;
  FILE *input_file = stdin;

  /* ------------------------------------------------- PARSE ARGUMENTS */

  int c;
  extern char *optarg;
  extern int optind;

  progname = argv[0];

  first_token = -1;
  last = -1;
  maxlast = -1;

  read_pos_frm_stdin = 0;

  /* use getopt() to parse command-line options */
  while((c = getopt(argc, argv, "+s:e:r:nLHCxXf:ph")) != EOF)
    switch(c) {

      /* s: start corpus position */
    case 's':
      first_token = atoi(optarg);
      break;

      /* e: end corpus position */
    case 'e':
      last = atoi(optarg);
      break;

      /* r: registry directory */
    case 'r':
      if (registry_directory == NULL)
        registry_directory = optarg;
      else {
        fprintf(stderr, "%s: -r option used twice\n", progname);
        exit(2);
      }
      break;

      /* n: show cpos in -H mode */
    case 'n':
      printnum++;
      break;

      /* x: XML-compatible output in -C mode (-Cx) */
    case 'x':
      xml_compatible++;
      break;

      /* L,H,C,X: Lisp, Horizontal, Compact, and XML modes */
    case 'L':
      mode = LispMode;
      break;
    case 'H':
      mode = ConclineMode;
      break;
    case 'C':
      mode = EncodeMode;
      break;
    case 'X':
      mode = XMLMode;
      break;

      /* f: matchlist mode / read corpus positions from file */
    case 'f':
      input_filename = optarg;
      break;

      /* p: matchlist mode / read corpus positions from stdin */
    case 'p':
      read_pos_frm_stdin++;
      break;

      /* h: help page */
    case 'h':
      usage(2);
      break;

    default:
      fprintf(stderr, "Illegal option. Try \"%s -h\" for more information.\n", progname);
      fprintf(stderr, "[remember that options go before the corpus name, and flags after it!]\n");
      cleanup(2);
    }

  /* required argument: corpus id */
  if (optind < argc) {
    corpus_id = argv[optind++];

    if ((corpus = cl_new_corpus(registry_directory, corpus_id)) == NULL) {
      fprintf(stderr, "Corpus %s not found in registry %s . Aborted.\n",
              corpus_id,
              (registry_directory ? registry_directory
               : central_corpus_directory()));
      cleanup(1);
    }
  }
  else {
    fprintf(stderr, "Missing argument. Try \"%s -h\" for more information.\n", progname);
    cleanup(2);
  }


  /* now parse output flags (-P, -S, ...) [cnt is our own argument counter] */
  for (cnt = optind; cnt < argc; cnt++) {
    if (strcmp(argv[cnt], "-c") == 0) {         /* -c: context */

      if ((context =
           cl_new_attribute(corpus, argv[++cnt], ATT_STRUC)) == NULL) {
        fprintf(stderr, "Can't open s-attribute %s.%s . Aborted.\n",
                corpus_id, argv[cnt]);
        cleanup(1);
      }

    }
    else if (strcmp(argv[cnt], "-P") == 0) {    /* -P: positional attribute */

      if ((attr = cl_new_attribute(corpus, argv[++cnt], ATT_POS)) == NULL) {
        fprintf(stderr, "Can't open p-attribute %s.%s . Aborted.\n",
                corpus_id, argv[cnt]);
        cleanup(1);
      }
      else {
        if (cl_max_cpos(attr) > 0) {
          add_attribute(attr);
          if (maxlast < 0)
            maxlast = cl_max_cpos(attr); /* determines corpus size */
        }
        else {
          fprintf(stderr, "Attribute %s.%s is declared, but not accessible (missing data?). Aborted.\n",
                  corpus_id, argv[cnt]);
          cleanup(1);
        }
      }

    }
    else if (strcmp(argv[cnt], "-ALL") == 0) {  /* -ALL: all p-attributes and s-attributes */

      for (attr = corpus->attributes; attr; attr = attr->any.next)
        if (attr->any.type == ATT_POS) {
          add_attribute(attr);
          if (maxlast < 0)
            maxlast = cl_max_cpos(attr);
        }
        else if (attr->any.type == ATT_STRUC) {
          add_attribute(attr);
        }

    }
    else if (strcmp(argv[cnt], "-D") == 0) {    /* -D: dynamic attribute (not implemented) */

      fprintf(stderr, "Sorry, dynamic attributes are not implemented. Aborting.\n");
      cleanup(2);

    }
    else if (strcmp(argv[cnt], "-A") == 0) {    /* -A: alignment attribute */

      if ((attr = cl_new_attribute(corpus, argv[++cnt], ATT_ALIGN)) == NULL) {
        fprintf(stderr, "Can't open a-attribute %s.%s . Aborted.\n",
                corpus_id, argv[cnt]);
        cleanup(1);
      }
      else
        add_attribute(attr);
    }
    else if (strcmp(argv[cnt], "-S") == 0) {    /* -S: structural attribute (as tags) */

      if ((attr = cl_new_attribute(corpus, argv[++cnt], ATT_STRUC)) == NULL) {
        fprintf(stderr, "Can't open s-attribute %s.%s . Aborted.\n",
                corpus_id, argv[cnt]);
        cleanup(1);
      }
      else
        add_attribute(attr);

    }
    else if (strcmp(argv[cnt], "-V") == 0) {    /* -V: show structural attribute values (with -p or -f) */

      if ((attr = cl_new_attribute(corpus, argv[++cnt], ATT_STRUC)) == NULL) {
        fprintf(stderr, "Can't open s-attribute %s.%s . Aborted.\n",
                corpus_id, argv[cnt]);
        cleanup(1);
      }
      else if (!cl_struc_values(attr)) {
        fprintf(stderr, "S-attribute %s.%s does not have annotations. Aborted.\n",
                corpus_id, argv[cnt]);
        cleanup(1);
      }
      else if (printValuesIndex >= MAX_PRINT_VALUES) {
        fprintf(stderr, "Too many -V attributes, sorry. Aborted.\n");
        cleanup(1);
      }
      else
        printValues[printValuesIndex++] = attr;

    }
    else {

      fprintf(stderr, "Unknown flag: %s\n", argv[cnt]);
      cleanup(2);

    }
  }

  if (input_filename != NULL) {
    if (strcmp(input_filename, "-") == 0)
      input_file = stdin;
    else if ((input_file = fopen(input_filename, "r")) == NULL) {
      perror(input_filename);
      exit(1);
    }
    read_pos_frm_stdin++;
  }

  (void) verify_print_value_list(); /* always returns TRUE anyway */

  /* ------------------------------------------------------------ DECODE CORPUS */

  if (read_pos_frm_stdin == 0) { /* normal mode: decode entire corpus or specified range */

    if (maxlast < 0) {
      fprintf(stderr, "Need at least one p-attribute (-P flag). Aborted.\n");
      cleanup(2);
    }

    if ((first_token < 0) || (first_token >= maxlast))
      first_token = 0;

    if ((last < 0) || (last >= maxlast))
      last = maxlast - 1;

    if (last < first_token) {
      fprintf(stderr, "Warning: output range #%d..#%d is empty. No output.\n", first_token, last);
      cleanup(2);
    }

    if ( (mode == XMLMode) ||
         ((mode == EncodeMode) && xml_compatible) ) {
      print_xml_declaration();
      printf("<corpus name=\"%s\" start=\"%d\" end=\"%d\">\n",
             corpus_id, first_token, last);
    }


    /* showSurroundingStructureValues(first_token); */ /* don't do that in "normal" mode, coz it doesn't make sense */

    for (w = first_token; w <= last; w++)
      show_position_values(w, -1, context);

    if ( (mode == XMLMode) ||
         ((mode == EncodeMode) && xml_compatible) ) {
      printf("</corpus>\n");
    }
  }
  else {                        /* matchlist mode: read (pairs of) corpus positions from stdin or file */

    if ( (mode == XMLMode) ||
         ((mode == EncodeMode) && xml_compatible) ) {
      print_xml_declaration();
      printf("<matchlist corpus=\"%s\">\n", corpus_id);
    }

    cnt = 0;
    while (fgets(s, 1024, input_file) != NULL) {

      token = strtok(s, " \t\n");

      if ((token != NULL) && is_num(token)) {
        sp = atoi(token);

        ep = -1;
        if ((token = strtok(NULL, " \t\n")) != NULL) {
          if (!is_num(token)) {
            fprintf(stderr, "Invalid corpus position #%s . Aborted.\n", token);
            cleanup(1);
          }
          else
            ep = atoi(token);
        }

        cnt++;                  /* count matches in matchlist  */
        if (mode == XMLMode) {
          printf("<match nr=\"%d\"", cnt);
          if (printnum)
            printf(" start=\"%d\" end=\"%d\"", sp, (ep >= 0) ? ep : sp);
          printf(">\n");
        }
        else {
          /* nothing shown before range */
        }

        showSurroundingStructureValues(sp);

        show_position_values(sp, ep, context);

        if (mode == XMLMode) {
          printf("</match>\n");
        }
        else if (mode != ConclineMode) {
          printf("\n");         /* blank line, unless in -H mode */
        }
      }
      else {
        fprintf(stderr, "Invalid corpus position #%s . Aborted.\n", s);
        cleanup(1);
      }
    }

    if (input_file != stdin)
      fclose(input_file);

    if ( (mode == XMLMode) ||
         ((mode == EncodeMode) && xml_compatible) ) {
      printf("</matchlist>\n");
    }
  }

  cleanup(0);
  return 0;                     /* just to keep gcc from complaining */
}
