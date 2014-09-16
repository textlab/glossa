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
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

/** magic number of the subcropus file format */
#define SUBCORPMAGIC 36193928

/** Boolean: controls whether a "registry" header in the subcorpus file gets printed or not */
int print_header = 1;

/**
 * Gets the size of the file.
 *
 * @param fd  File handle.
 * @return    The size of the file, from stat().
 */
int
file_length(FILE *fd)
{
  struct stat stat_buf;
  if(fstat(fileno(fd), &stat_buf) == EOF)
    return(EOF);
  else
    return(stat_buf.st_size);
}

/**
 * Reads a subcorpus file and prints information about it to STDOUT.
 *
 * "Subcorpus file" here means (a) it begins with the subcorpus magic number;
 * (b)then there is a "registry" area terminated by one or more zero bytes;
 * (c) then there may be the size of the subcorpus;
 * (d) then there are a whole load of
 * start-end range integer pairs, to the end of the file.
 *
 * The registry is printed iff print_header. The start-end pairs
 * are printed on tab-delimited lines, one line per pair.
 *
 * @param fd  File pointer.
 * @return    Boolean: true for all OK, false for problem.
 */
int
show_subcorpus_info(FILE *fd)
{
  char        *field;
  char        *p;

  struct range_t {
    int start;
    int end;
  };
  struct range_t *range;

  char *registry, *o_name;
  int size;

  int len, j;

  len = file_length(fd);

  if (len <= 0) {
    perror("ERROR: File length of subcorpus is <= 0");
    return 0;
  }
  else {
    
    /* the subcorpus is treated as a byte array */
    field = (char *)malloc(len);
    
    /* read the subcorpus */
    
    if (len != fread(field, 1, len, fd)) {
      fprintf(stderr, "Read error while reading corpus data\n");
      return 0;
    }
    else if (*((int *)field) == SUBCORPMAGIC || *((int *)field) == SUBCORPMAGIC+1) {
      
      int magic;

      magic = *((int *)field);

      p = ((char *)field) + sizeof(int);
      
      registry = (char *)p;
      
      while (*p)
        p++;
      /* skip the '\0' character */
      p++;

      
      o_name = (char *)p;
      
      /* advance p to the end of the 2nd string */
      while (*p)
        p++;
      /* skip the '\0' character */
      p++;
      
      /* the length is divisible by 4 -- advance p over the additional '\0' characters */
      while ((p - field) % 4)
        p++;

      if (magic == SUBCORPMAGIC) {
        size = (len - (p - field)) / (2 * sizeof(int));
      }
      else {
        memcpy(&size, p, sizeof(int));
        p += sizeof(int);
        fprintf(stderr, "Note: new subcorpus format\n");
      }

      if (print_header) {

        printf("REGISTRY %s\n", registry);
        printf("O_NAME   %s\n", o_name);
        printf("SIZE     %d\n", size);

      }

      range = (struct range_t *) p;

      for (j = 0; j < size; j++)
        printf("%d\t%d\n",
               range[j].start, range[j].end);
    }
    else {
      fprintf(stderr, "Magic number incorrect\n");
      return 0;
    }
      
    free(field);
    p = NULL;
    field = NULL;
      
    return 1;
  }
}


/* *************** *\
 *      MAIN()     *
\* *************** */

/**
 * Main function for cwb-decode-nqrfile.
 *
 * @param argc   Number of command-line arguments.
 * @param argv   Command-line arguments.
 */
int
main(int argc, char **argv)
{
  int i;
  FILE *fd;

  for (i = 1; i < argc; i++) {
    if (strcmp(argv[i], "-h") == 0)
      print_header = 0;
    else if (strcmp(argv[i], "+h") == 0)
      print_header = 1;
    else {

      /* treat arg as sc-name */

      if (strcmp(argv[i], "-") == 0) {
        if (!show_subcorpus_info(stdin))
          exit(1);
      }
      else {
        if ((fd = fopen(argv[i], "r")) == NULL) {
          perror(argv[i]);
          exit(1);
        }
        else {
          if (!show_subcorpus_info(fd))
            exit(1);
          fclose(fd);
        }
      }
    }
  }
  exit(0);
}
