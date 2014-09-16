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

/* This is the interactive CQP main function (interactive loop) */

#include <stdio.h>
#include <signal.h>

#include "../cl/macros.h"

#include "cqp.h"
#include "eval.h"
#include "options.h"
#include "macro.h"
#include "variables.h"
#include "output.h"
#include "ascii-print.h"


#ifdef USE_READLINE
#include <editline.h>
#endif /* USE_READLINE */



#ifdef USE_READLINE

/* unlike GNU Readline, Editline expects to get the full list of possible completions
   from the custom completion function; therefore, we need some helper routines which
   can build NULL-terminated string lists of arbitrary size;
   all functions & static variables use the namespace prefix cc_... (for custom completion)
*/
char **cc_compl_list = NULL;      /* list of possible completions */
int cc_compl_list_size = 0;       /* number of completions in list */
int cc_compl_list_allocated = 0;  /* number of entries allocated for list (incl. NULL terminator) */
#define CC_COMPL_LIST_ALLOC_BLOCK 256 /* how many list cells to allocate at a time */


/* initialise completion list (size 0) without freeing it (because it will be freed by editline library) */
void
cc_compl_list_init(void) {
  cc_compl_list = (char **) cl_malloc(CC_COMPL_LIST_ALLOC_BLOCK * sizeof(char *));
  cc_compl_list_allocated = CC_COMPL_LIST_ALLOC_BLOCK;
  cc_compl_list_size = 0;
  cc_compl_list[0] = NULL;
}

/* add string (must be alloc'ed by caller) to completion list */
void
cc_compl_list_add(char *string) {
  if (cc_compl_list_size >= cc_compl_list_allocated) {
    /* extend list if necessary */
    cc_compl_list_allocated += CC_COMPL_LIST_ALLOC_BLOCK;
    cc_compl_list = (char **) cl_realloc(cc_compl_list, cc_compl_list_allocated * sizeof(char *));
  }
  cc_compl_list[cc_compl_list_size++] = string;
  cc_compl_list[cc_compl_list_size] = NULL;
}

/* internal function for sorting list of completions */
static int
cc_compl_list_sort(const void *p1, const void *p2) {
  char *name1 = *((char **) p1);
  char *name2 = *((char **) p2);
  int result = strcmp(name1, name2);
  return result;
}

/* sort list and remove (& free) duplicates; returns pointer to list */
char **
cc_compl_list_sort_uniq(void) {
  int mark, point;
  if (cc_compl_list_size > 0)
    qsort(cc_compl_list, cc_compl_list_size, sizeof(char *), cc_compl_list_sort);       /* don't sort NULL at end of list */
  /* now for the tricky part ... go through list and remove duplicates */
  mark = 0;
  point = 1;                    /* always keep first list element */
  while (point < cc_compl_list_size) {
    if (strcmp(cc_compl_list[mark], cc_compl_list[point]) == 0) {
      free(cc_compl_list[point]); /* duplicate -> free, don't advance point */
    }
    else {
      mark++;                   /* new string -> advance mark & copy there */
      cc_compl_list[mark] = cc_compl_list[point];
    }
    point++;
  }
  cc_compl_list_size = mark + 1;
  cc_compl_list[cc_compl_list_size] = NULL;
  return cc_compl_list;
}

/* custom completion function: complete corpus/subcorpus names */
char **
cqp_custom_completion(char *line, int start, int end) {
  char *text;       /* the part of the line editline wants us to complete */
  int text_len;     /* are the first text_len characters of text[] */
  Variable var;
  CorpusList *cl;
  char *prototype, *prefix;
  char mother[128];
  char *real_name, *colon;
  int mother_len, real_len, prefix_len;
  char *completion;

  text = line + start;
  text_len = end - start;
  /* the string that GNU readline would supply to a custom completer ist
     line[start .. end]; or, equivalently, the first len = end - start characters of text[] */

  /*
   *  (A) file name completion (triggered by '> "', '>> "', and '< "' patterns before start)
   */

  /* must check for file name completion first because absolute path would be mistaken for a macro invocation */
  if ((--start >= 0) && (line[start] == '"')) {
    while ((--start >= 0) && (line[start] == ' ')) {
      /* nop */
    }
    if ((start >= 0) && ((line[start] == '>') || (line[start] == '<'))) {
      /* looks like a redirection (more or less ...), so return NULL and let editline handle filename completion */
      return NULL;
    }
    /* a string within a "set <option> ..." command may also be a filename */
    if (strncmp(line, "set ", 4) == 0) {
      return NULL;
    }
  }

  /*
   *  (B) variable name completion (triggered by '$' character)
   */
  if (text[0] == '$') {
    cc_compl_list_init();       /* init list only if custom completion has been triggered */
    variables_iterator_new();
    prefix = text + 1;
    prefix_len = text_len - 1;
    var = variables_iterator_next();
    while (var != NULL) {
      if (strncmp(prefix, var->my_name, prefix_len) == 0) { /* found variable matching prefix -> format and add */
        completion = cl_malloc(strlen(var->my_name) + 2);
        sprintf(completion, "$%s", var->my_name);
        cc_compl_list_add(completion);
      }
      var = variables_iterator_next();
    }
    return cc_compl_list_sort_uniq();
  }

  /*
   *  (C) macro name completion (triggered by '/' character)
   */
  if (text[0] == '/') {
    cc_compl_list_init();
    macro_iterator_new();
    /* find macro name matching current prefix (i.e. characters 1 .. text_len-1 of text[]) */
    prefix = cl_strdup(text + 1);
    prefix[text_len - 1] = '\0'; /* cut prefix[] to text_len - 1 characters */
    prototype = macro_iterator_next_prototype(prefix);
    while (prototype != NULL) {
      /* since the iterator ignores partially complete argument lists, we have to check that <prototype> really extends <text> */
      if (strncmp(text, prototype, text_len) == 0) {
        cc_compl_list_add(prototype);
      }
      else {
        free(prototype);        /* if prototype isn't accepted, we have to free it */
      }
      prototype = macro_iterator_next_prototype(prefix);
    }
    free(prefix);
    return cc_compl_list_sort_uniq();
  }

  /* at the moment, everything else triggers (sub)corpus name completion */

  /*
   *  (D) (sub)corpus name completion (should be triggered by uppercase letter)
   */
  cc_compl_list_init();
  colon = strchr(text, ':');
  if ((colon != NULL) && ((mother_len = colon - text) < 128)) {
    /* full subcorpus specifier: ''HGC:Last'' */
    strncpy(mother, text, mother_len);
    mother[mother_len] = '\0';
    real_name = colon + 1;
    real_len = text_len - (colon - text + 1); /* compute length of subcorpus part of name */
  }
  else {
    mother_len = 0;
    real_name = text;
    real_len = text_len;
  }

  /* run throgh corpus/subcorpus list and collect matches */
  cl = FirstCorpusFromList();
  while (cl != NULL) {
    if ((cl->type == SYSTEM) || (cl->type == SUB)) /* don't show subcorpora with status TEMP */
    {
      int handled = 0;
      /* token must be prefix of corpus name (if mother name is given, consider only subcorpora) */
      if ((strncmp(cl->name, real_name, real_len) == 0)
          && (!mother_len || (cl->type == SUB))) {
        /* if mother name is given, that has to match also; same if we're looking at a subcorpus */
        if (cl->type == SUB) {
          char *expected_mother;
          if (mother_len) {
            expected_mother = mother;
          }
          else if (current_corpus) {
            expected_mother = (current_corpus->type == SUB) ? current_corpus->mother_name : current_corpus->name;
          }
          else {
            expected_mother = cl->mother_name; /* a neat little trick: don't try mother name if no corpus is activated */
          }
          if (strcmp(cl->mother_name, expected_mother) == 0) {
            if (mother_len) {
              /* we must allocate a string of sufficient length and build a full subcorpus specifier */
              completion = (char *) cl_malloc(mother_len + 1 + strlen(cl->name) + 1);
              sprintf(completion, "%s:%s", mother, cl->name);
              cc_compl_list_add(completion);
            }
            else {
              cc_compl_list_add(cl_strdup(cl->name));
            }
            handled = 1;
          }
        }
        else {
          cc_compl_list_add(cl_strdup(cl->name));
          handled = 1;
        }
      }
      if (! handled) {
        /* other possibility: current token is prefix of mother part of a subcorpus */
        if ((cl->type == SUB) && (!mother_len) && cl->mother_name &&
            (strncmp(cl->mother_name, real_name, real_len) == 0))  {
          /* requires special handling: return ''<mother>:'' */
          char *completion = (char *) cl_malloc(strlen(cl->mother_name) + 2);
          /* just show there are subcorpora as well; user must type ':' to see subcorpora completions */
          sprintf(completion, "%s:", cl->mother_name);
          /* note that this will return the same string over and over again if there are multiple subcorpora;
             fortunately, readline sorts and uniqs the list of completions, so we don't have to worry */
          cc_compl_list_add(completion);
        }
      }
    }
    cl = NextCorpusFromList(cl);
  }
  return cc_compl_list_sort_uniq();
}

/* check that line ends in semicolon, otherwise append one to the string
   (returns either same pointer or re-allocated and modified string) */
char *
ensure_semicolon (char *line) {
  int i, l;

  if (line) {
    l = strlen(line);
    if (l > 0) {
      i = l-1;
      while ((i >= 0) && (line[i] == ' ' || line[i] == '\t' || line[i] == '\n'))
        i--;
      if (i < 0) {
        *line = 0;              /* line contains only whitespace -> replace by empty string */
      }
      else {
        if (line[i] != ';') {   /* this is the problematic case: last non-ws character is not a ';' */
          if (i+1 < l) {        /* have some whitespace at end of string that we can overwrite */
            line[i+1] = ';';
            line[i+2] = 0;
          }
          else {                /* need to reallocate string to make room for ';' */
            line = cl_realloc(line, l+2);
            line[l] = ';';
            line[l+1] = 0;
          }
        }
      }
    }
  }
  return (line);                /* return pointer to line (may have been modified and reallocated */
}



/* this function replaces cqp_parse_file(stdin,0) if we're using GNU Readline */
void readline_main(void)
{
  char prompt[512];
  char *input = NULL;

  /* activate CQP's custom completion function */
  el_user_completion_function = cqp_custom_completion;
  /* if CQP history file is specified, read history from file */
  if (cqp_history_file != NULL) {
    /* ignore errors; it's probably just that the history file doesn't exist yet */
    read_history(cqp_history_file);
  }

  /* == the line input loop == */
  while (!exit_cqp) {

    if (input != NULL)
      {
        free(input);
        input = NULL;
      }

    if (highlighting) {
      printf(get_typeface_escape('n')); /* work around 'bug' in less which may not switch off display attributes when user exits */
      fflush(stdout);
    }

    if (silent) {
      input = readline(NULL);
    } else {
      if (current_corpus != NULL) {
        /* don't use terminal colours for the prompt because they mess up readline's formatting */
        if (STREQ(current_corpus->name, current_corpus->mother_name))
          sprintf(prompt, "%s> ", current_corpus->name);
        else
          sprintf(prompt, "%s:%s[%d]> ",
                  current_corpus->mother_name,
                  current_corpus->name,
                  current_corpus->size);
      }
      else
        sprintf(prompt, "[no corpus]> ");

      input = readline(prompt);
    }

    if (input != NULL) {
      input = ensure_semicolon(input); /* add semicolon at end of line if missing (also replaces ws-only lines by "") */
      if (*input) add_history(input); /* add input line to history (unless it's an empty line) */
      cqp_parse_string(input);        /* parse & execute query */
    }
    else {
      exit_cqp = True;                /* NULL means we've had an EOF character */
    }

    /* reinstall signal handler if necessary */
    if (! signal_handler_is_installed)
      install_signal_handler();
  }

  if (save_on_exit)
    save_unsaved_subcorpora();

  if (!silent) {
    printf("\nDone. Share and enjoy!\n");
  }

}
#endif /* USE_READLINE */


/**
 * Main function for the interactive CQP program.
 *
 * Doesn't do much except call the initialisation function,
 * and then one of the loop-and-parse-input functions.
 *
 * @param argc  Number of commandline arguments.
 * @param argv  Pointer to commandline arguments.
 * @return      Return value to OS.
 */
int
main(int argc, char *argv[])
{

  which_app = cqp;

  if (!initialize_cqp(argc, argv)) {
    fprintf(stderr, "Can't initialize CQP\n");
    exit(1);
  }

  /* Test ANSII colours (if CQP was invoked with -C switch) */
  if (use_colour) {
    char *blue = get_colour_escape('b', 1);
    char *green = get_colour_escape('g', 1);
    char *red = get_colour_escape('r', 1);
    char *pink = get_colour_escape('p', 1);
    char *cyanBack = get_colour_escape('c', 0);
    char *greenBack = get_colour_escape('g', 0);
    char *yellowBack = get_colour_escape('y', 0);
    char *bold = get_typeface_escape('b');
    char *underline = get_typeface_escape('u');
    char *standout = get_typeface_escape('s');
    char *normal = get_typeface_escape('n');
    char sc_colour[256];
    int i, j;

    printf("%s%sWelcome%s to %s%sC%s%sQ%s%sP%s -- ", green, bold, normal, red, bold, pink, bold, blue, bold, normal);
    printf("the %s Colourful %s Query %s Processor %s.\n", yellowBack, greenBack, cyanBack, normal);

    for (i = 3; i <= 4; i++) {
      printf("[");
      for (j = 0; j < 8; j++) {
        sprintf(sc_colour, "\x1B[0;%d%dm", i,j);
        printf("%d%d: %sN%s%sB%s%sU%s%sS%s  ",
               i, j,
               sc_colour,
               sc_colour, bold,
               sc_colour, underline,
               sc_colour, standout,
               normal);
      }
      printf("]\n");
    }
  } /* endif use_colour */

  install_signal_handler();

  if (child_process) {
    printf("CQP version " VERSION "\n");
    fflush(stdout);
  }

  if (batchmode) {
    if (batchfd == NULL)
      fprintf(stderr, "Can't open batch file\n");
    else
      cqp_parse_file(batchfd, 1);
  }
  else {
#ifdef USE_READLINE
    if (use_readline)
      readline_main();
    else
#endif /* USE_READLINE */
      cqp_parse_file(stdin, 0);
  }

  if (macro_debug)
    macro_statistics();

  return 0;
}



