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

#include <time.h>






/*
 * memory allocation functions with integrate success test 
 * (this functions will be used as hooks for the CL MMU)
 */

/**
 * safely allocates memory malloc-style.
 *
 * This function allocates a block of memory of the requested size,
 * and does a test for malloc() failure which aborts the program and
 * prints an error message if the system is out of memory.
 * So the return value of this function can be used without further
 * testing for malloc() failure.
 *
 * @param bytes  Number of bytes to allocate
 * @return       Pointer to the block of allocated memory
 */
void *
cl_malloc(size_t bytes) {
  void *block;

  block = malloc(bytes);
  if (block == NULL) {
    fprintf(stderr, "CL: Out of memory. (killed)\n");
    fprintf(stderr, "CL: [cl_malloc(%ld)]\n", bytes);
    printf("\n");		/* for CQP's child mode */
    exit(1);
  }
  return block;
}

/**
 * safely allocates memory calloc-style.
 *
 * @see cl_malloc
 * @param nr_of_elements  Number of elements to allocate
 * @param element_size    Size of each element
 * @return                Pointer to the block of allocated memory
 */
void *
cl_calloc(size_t nr_of_elements, size_t element_size) {
  void *block;

  block = calloc(nr_of_elements, element_size);
  if (block == NULL) {
    fprintf(stderr, "CL: Out of memory. (killed)\n");
    fprintf(stderr, "CL: [cl_calloc(%ld*%ld bytes)]\n", nr_of_elements, element_size);
    printf("\n");		/* for CQP's child mode */
    exit(1);
  }
  return block;
}

/**
 * safely reallocates memory.
 *
 * @see cl_malloc
 * @param block  Pointer to the block to be reallocated
 * @param bytes  Number of bytes to allocate to the resized memory block
 * @ return      Pointer to the block of reallocated memory
 */
void *
cl_realloc(void *block, size_t bytes) {
  void *new_block;

  if (block == NULL) 
    new_block = malloc(bytes);	/* some OSs don't fall back to malloc() if block == NULL */
  else
    new_block = realloc(block, bytes);

  if (new_block == NULL) {
    if (bytes == 0) {
      /* don't warn any more, reallocating to 0 bytes should create no problems, at least on Linux and Solaris */
      /* (the message was probably shown on Linux only, because Solaris doesn't return NULL in this case) */
      /* fprintf(stderr, "CL: WARNING realloc() to 0 bytes!\n"); */      
    }
    else {
      fprintf(stderr, "CL: Out of memory. (killed)\n");
      fprintf(stderr, "CL: [cl_realloc(block at %p to %ld bytes)]\n", block, bytes);
      printf("\n");		/* for CQP's child mode */
      exit(1);
    }
  }
  return new_block;
}

/**
 * safely duplicates a string.
 *
 * @see cl_malloc
 * @param string  Pointer to the original string
 * @return        Pointer to the newly duplicated string
 */
char *
cl_strdup(char *string) {
  char *new_string;

  new_string = strdup(string);
  if (new_string == NULL) {
    fprintf(stderr, "CL: Out of memory. (killed)\n");
    fprintf(stderr, "CL: [cl_strdup(addr=%p, len=%ld)]\n", string, strlen(string));
    printf("\n");		/* for CQP's child mode */
    exit(1);
  }
  return new_string;
}








/*
 * built-in random number generator (avoid dependence on quality of system's rand() function)
 *
 * this random number generator is a version of Marsaglia-multicarry which is one of the RNGs used by R
 */



static unsigned int RNG_I1=1234, RNG_I2=5678;

/**
 * Restores the state of the CL-internal random number generator.
 *
 * @param i1  The value to set the first RNG integer to (if zero, resets it to 1)
 * @param i2  The value to set the second RNG integer to (if zero, resets it to 1)
 */
void
cl_set_rng_state(unsigned int i1, unsigned int i2) {
  RNG_I1 = (i1) ? i1 : 1; 	/* avoid zero values as seeds */
  RNG_I2 = (i2) ? i2 : 1;
}

/* read current state of CL-internal RNG (two unsigned 32-bit integers) */
/**
 * Reads current state of CL-internal random number generator.
 *
 * The integers currently held in RNG_I1 and RNG_I2 are written to the
 * two memory locations supplied as arguments.
 *
 * @param i1  Target location for the value of RNG_I1
 * @param i2  Target location for the value of RNG_I2
 */
void 
cl_get_rng_state(unsigned int *i1, unsigned int *i2) {
  *i1 = RNG_I1; 
  *i2 = RNG_I2;
}

/**
 * Initialises the CL-internal random number generator.
 *
 * @param seed  A single 32bit number to use as the seed
 */
void
cl_set_seed(unsigned int seed) {
  cl_set_rng_state(seed, 69069 * seed + 1); /* this is the way that R does it */
}

/**
 *  Initialises the CL-internal random number generator from the current system time.
 */
void
cl_randomize(void) {
  cl_set_seed(time(NULL));
}

/**
 * Gets a random number.
 *
 * Part of the CL-internal random number generator.
 *
 * @return  The random number, an unsigned 32-bit integer with uniform distribution
 */
unsigned int
cl_random(void) {
  RNG_I1 = 36969*(RNG_I1 & 0177777) + (RNG_I1 >> 16);
  RNG_I2 = 18000*(RNG_I2 & 0177777) + (RNG_I2 >> 16);
  return((RNG_I1 << 16) ^ (RNG_I2 & 0177777));
}

/**
 * Gets a random number in the range [0,1] with uniform distribution.
 *
 * Part of the CL-internal random number generator.
 *
 * @return  The generated random number.
 */
double 
cl_runif(void) {
  return cl_random() * 2.328306437080797e-10; /* = cl_random / (2^32 - 1) */
}







/*
 *  display progress bar in terminal window
 */

/* non-exported global variables for progress bar */
int progress_bar_pass = 1;
int progress_bar_total = 1;
int progress_bar_simple = 0;

/**
 * Activates or deactivates child (simple) mode for progress_bar.
 *
 * @param on_off  The new setting for the progress bar mode,
 *                where 1 = simple messages ON STDOUT,
 *                0 = pretty-printed messages with carriage returns ON STDERR
 */
void
progress_bar_child_mode(int on_off) {
  progress_bar_simple = on_off;
}

/**
 * Clears the progress bar currently displayed on the terminal.
 *
 * Note: assumes line width of 60 characters.
 */
void
progress_bar_clear_line(void) {
  if (progress_bar_simple) {
    /* messages are on separated lines, so do nothing here */
  }
  else {
    /* clear the contents of the bottom terminal line */
    fprintf(stderr, "                                                            \r");
    fflush(stderr);
  }
}

/**
 * Prints a new progress bar (passes-plus-message format).
 *
 * The progress bar printed is as follows:
 *
 * [pass {pass} of {total}: {message}]
 *
 * If total is equal to zero, the function uses the pass
 * and total values from the last call of this function.
 *
 */
void
progress_bar_message(int pass, int total, char *message) {
  /* [pass <pass> of <total>: <message>]   (uses pass and total values from last call if total == 0)*/
  if (total <= 0) {
    pass = progress_bar_pass;
    total = progress_bar_total;
  }
  else {
    progress_bar_pass = pass;
    progress_bar_total = total;
  }
  if (progress_bar_simple) {
    fprintf(stdout, "-::-PROGRESS-::-\t%d\t%d\t%s\n", pass, total, message);
    fflush(stdout);
  }
  else {
    fprintf(stderr, "[");
    fprintf(stderr, "pass %d of %d: ", pass, total);
    fprintf(stderr, "%s]     \r", message);
    fflush(stderr);
  }
}


/*   (if total == 0, uses pass and total values from last call) */
/**
 * Prints a new progress bar (passes-plus-percentage-done format).
 *
 * The progress bar printed is as follows:
 *
 * [pass {pass} of {total}: {percentage}% complete]
 *
 * If total is equal to zero, the function uses the pass
 * and total values from the last call of this function.
 */
void
progress_bar_percentage(int pass, int total, int percentage) {
  /* [pass <pass> of <total>: <percentage>% complete]  (uses progress_bar_message) */
  char message[20];
  sprintf(message, "%3d%c complete", percentage, '%');
  progress_bar_message(pass, total, message);
}


/*
 *  print indented 'tabularised' lists
 */

/* status variables (non-exported globals) */
int ilist_cursor;         /* the 'cursor' (column where next item will be printed) */
int ilist_linewidth;      /* so start_indented_list() can override default config */
int ilist_tab;            /* ... */
int ilist_indent;         /* ... */

/* internal function: print <n> blanks */
void
ilist_print_blanks(int n) {
  while (n > 0) {
    printf(" ");
    n--;
  }
}

/**
 * Begins the printing of a line in an indented 'tabularised' list.
 *
 * This function begins the printing of the first line of an indented
 * If any of the three parameters are zero, this function uses the internal default value
 * for that parameter instead (ILIST macro constants).
 *
 * @param linewidth  Width of the line (in characters)
 * @param tabsize    Tabulator steps (in characters)
 * @param indent     Indentation of the list from left margin (in characters)
 */
void
start_indented_list(int linewidth, int tabsize, int indent) {
  /* set status variables */
  ilist_linewidth = (linewidth > 0) ? linewidth : ILIST_LINEWIDTH;
  ilist_tab = (tabsize > 0) ? tabsize : ILIST_TAB;
  ilist_indent = (indent > 0) ? indent : ILIST_INDENT;
  ilist_cursor = 0;
  /* indent from left margin */
  ilist_print_blanks(ilist_indent);
} 

/**
 * Starts a new line in an indented 'tabularised' list.
 *
 * Used when a line break is needed within an indented list; this function
 * starts a new line (as <br> in HTML), an showing optional label in indentation.
 *
 * @param label  The optional label, if this is NULL, no label is used; if it is
 *               a string, then the string appears on the far left hand side.
 */
void
print_indented_list_br(char *label) {
  int llen = (label != NULL) ? strlen(label) : 0;
  
  if (ilist_cursor != 0) {
    printf("\n");
  }
  else {
    printf("\r");
  }
  if (llen <= 0) {
    ilist_print_blanks(ilist_indent);
  }
  else {
    printf(label);
    ilist_print_blanks(ilist_indent - llen);
  }
  ilist_cursor = 0;
}

/**
 * Prints an item into an ongoing indented list.
 *
 * @param string  The string to print as a list item.
 */
void
print_indented_list_item(char *string) {
  int len;

  if (string != NULL) {
    len = strlen(string);
    if ((ilist_cursor + len) > ilist_linewidth) {
      print_indented_list_br("");
    }
    printf("%s", string);
    ilist_cursor += len;
    /* advance cursor to next tabstop */
    if (ilist_cursor < ilist_linewidth) {
      printf(" ");
      ilist_cursor++;
    }
    while ((ilist_cursor < ilist_linewidth) && ((ilist_cursor % ilist_tab) != 0)) {
      printf(" ");
      ilist_cursor++;
    }
  }
}

/**
 * Ends the printing of a line in an indented 'tabularised' list.
 */
void
end_indented_list(void) {
  if (ilist_cursor == 0) {
    printf("\r");        /* no output on last line (just indention) -> erase indention */
  }
  else {
    printf("\n");
  }
  ilist_cursor = 0;
  fflush(stdout);
}

