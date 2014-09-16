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
#include <string.h>
#include <signal.h>
#include <stdarg.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/time.h>           /* for select() */


#include "../cl/cl.h"
#include "../cl/corpus.h"
#include "../cl/attributes.h"
#include "../cl/cdaccess.h"

#include "concordance.h"

#include "cqp.h"
#include "options.h"
#include "output.h"
#include "corpmanag.h"
#include "print-modes.h"
#include "print_align.h"

#include "ascii-print.h"
#include "sgml-print.h"
#include "html-print.h"
#include "latex-print.h"

/* ---------------------------------------------------------------------- */

#include <sys/types.h>
#include <sys/time.h>
#include <pwd.h>

/* ---------------------------------------------------------------------- */

TabulationItem TabulationList = NULL; /* global list of tabulation items */

/* ---------------------------------------------------------------------- */

/* stupid Solaris doesn't have setenv() function, so we need to emulate it with putenv() */
#ifdef EMULATE_SETENV

char emulate_setenv_buffer[MAX_IDENTIFIER_LENGTH]; /* should be big enough for "var=value" string */

int
setenv(const char *name, const char *value, int overwrite) {
  assert(name != NULL && value != NULL && "Invalid call of setenv() emulation function.");
  sprintf(emulate_setenv_buffer, "%s=%s", name, value);
  return putenv(emulate_setenv_buffer);
}

#endif

/* ---------------------------------------------------------------------- */

void 
print_corpus_info_header(CorpusList *cl, 
                         FILE *stream, 
                         PrintMode mode,
                         int force)
{
  if (force || GlobalPrintOptions.print_header) {

    switch(mode) {
    case PrintASCII:
      ascii_print_corpus_header(cl, stream);
      break;
      
    case PrintSGML:
      sgml_print_corpus_header(cl, stream);
      break;
      
    case PrintHTML:
      html_print_corpus_header(cl, stream);
      break;
      
    case PrintLATEX:
      latex_print_corpus_header(cl, stream);
      break;

    default:
      break;
    }
  }
}

/* ---------------------------------------------------------------------- */

FILE *
OpenTemporaryFile(char *tmp_name_buffer) {
  int fnum;
  FILE *fd;

  assert((tmp_name_buffer != NULL) && "Invalid NULL argument in OpenTemporaryFile().");
  sprintf(tmp_name_buffer, "/tmp/cqp.tmp.XXXXXX");
  fnum = mkstemp(tmp_name_buffer);
  if (fnum >= 0) {
    fd = fdopen(fnum, "w");
    if (fd) 
      return fd;
    else {
      perror("OpenTemporaryFile(): can't open stream for temporary file");
      close(fnum);
      return NULL;
    }
  }
  else {
    perror("OpenTemporaryFile(): can't create temporary file");
    return NULL;
  }
}

FILE *
OpenFile(char *name, char *mode)
{
  if (name == NULL || mode == NULL || 
      name[0] == '\0' || mode[0] == '\0')
    return NULL;
  else if (name[0] == '~' || (strncasecmp(name, "$home", 5) == 0)) {

    char s[1024];
    char *home;
    int i, sp;

    home = getenv("HOME");

    if (!home || home[0] == '\0') 
      return NULL;

    sp = 0;

    for (i = 0; sp < 1023 && home[i]; i++)
      s[sp++] = home[i];
    
    if (name[0] == '~')
      i = 1;
    else
      i = strlen("$home");

    for ( ; sp < 1023 && name[i]; i++)
      s[sp++] = name[i];
    s[sp] = '\0';
    
    return fopen(s, mode);
    
  }
  else
    return fopen(name, mode);
}


/* try to open pager <cmd> / if different from <tested_pager>, run a test first */
FILE *
open_pager(char *cmd, CorpusCharset charset) {
  FILE *pipe;

  if ((tested_pager == NULL) || (strcmp(tested_pager, cmd) != 0)) {
    pipe = popen(cmd, "w");
    if ((pipe == NULL) || (pclose(pipe) != 0)) {
      return NULL;              /* new pager cmd doesn't work -> return error */
    }
    if (tested_pager != NULL)
      free(tested_pager);
    tested_pager = cl_strdup(cmd);
  }

  /* if (less_charset_variable != "" and charset != ascii) set environment variable accordingly */
  if (*less_charset_variable && charset != ascii) {     
    char *new_value = "iso8859"; /* default setting is ISO-8859 */
    char *current_value = getenv(less_charset_variable);
    if (charset == utf8) 
      new_value = "utf-8";      /* UTF-8 */
    /* call setenv() if variable is not set or different from desired value */
    if (!current_value || strcmp(current_value, new_value)) {
      setenv(less_charset_variable, new_value, 1);
    }
  }

  pipe = popen(cmd, "w");
  return pipe;                  /* NULL if popen() failed for some reason */
}

int
open_stream(struct Redir *rd, CorpusCharset charset)
{
  int i;

  assert(rd);

  if (rd->name) {
    i = 0;
    while (rd->name[i] == ' ')
      i++;
    
    if ((rd->name[i] == '|') &&
        (rd->name[i+1] != '\0')) {
      
      if (insecure) {
        rd->stream = NULL;
        rd->is_pipe = False;
        rd->is_paging = False;
      }
      else {
        
        /* we send the output to a pipe */

        rd->is_pipe = True;
        rd->is_paging = False;
        rd->stream = popen(rd->name+i+1, rd->mode);
      }
    }
    else {

      /* normal output to file */
      
      rd->is_pipe = False;
      rd->is_paging = False;
      rd->stream = OpenFile(rd->name, rd->mode);

    }
  }
  else {
    if (pager && paging && isatty(fileno(stdout))) {
      if (insecure) {
        cqpmessage(Error, "Insecure mode, paging not allowed.\n");
        rd->stream = stdout;
        rd->is_paging = False;
        rd->is_pipe = False;
      }
      else if ((rd->stream = open_pager(pager, charset)) == NULL) {
        cqpmessage(Warning, "Could not start pager '%s', trying fallback '%s'.\n", pager, CQP_FALLBACK_PAGER);
        if ((rd->stream = open_pager(CQP_FALLBACK_PAGER, charset)) == NULL) {
          cqpmessage(Warning, "Could not start fallback pager '%s'. Paging disabled.\n", CQP_FALLBACK_PAGER);
          set_integer_option_value("Paging", 0);
          rd->is_pipe = False;
          rd->is_paging = False;
          rd->stream = stdout;
        }
        else {
          rd->is_pipe = 1;
          rd->is_paging = True;
          set_string_option_value("Pager", cl_strdup(CQP_FALLBACK_PAGER));
        }
      }
      else {
        rd->is_pipe = 1;
        rd->is_paging = True;
      }
    }
    else {
      rd->stream = stdout;
      rd->is_paging = False;
      rd->is_pipe = False;
    }
  }
  return (rd->stream == NULL ? 0 : 1);
}

int
close_stream(struct Redir *rd)
{
  int rv = 1;

  if (rd->stream) {
    if (rd->is_pipe)
      rv = ! pclose(rd->stream); /* pclose returns 0 = success, non-zero = failure */
    else if (rd->stream != stdout)
      rv = ! fclose(rd->stream); /* fclose the same */

    rd->stream = NULL;
    rd->is_pipe = 0;
  }

  return rv;
}

/* ---------------------------------------------------------------------- */

int
open_input_stream(struct InputRedir *rd)
{
  int i;
  char *tmp;

  assert(rd);

  /* TODO: check if stream is already open (options: ignore, warning, silently close old stream) */

  if (rd->name) {
    i = strlen(rd->name) - 1;
    if (i < 0) i = 0;
    while (i > 0 && rd->name[i] == ' ')
      i--;
    
    if ((rd->name[i] == '|') && i >= 1) {

      /* read input from a pipe (unless running in "secure" mode) */
      if (insecure) {
        rd->stream = NULL;
        rd->is_pipe = False;
      }
      else {
        rd->is_pipe = True;
        tmp = (char *) cl_malloc(i + 1);
        strncpy(tmp, rd->name, i);
        tmp[i] = '\0';
        rd->stream = popen(tmp, "r");
        cl_free(tmp);
      }

    }
    else {

      /* normal input from a regular file */
      rd->is_pipe = False;
      rd->stream = OpenFile(rd->name, "r");

    }
  }
  else {
    rd->stream = stdin;
    rd->is_pipe = True;  /* stdin behaves like a pipe */
  }
  return (rd->stream == NULL ? 0 : 1);
}

int
close_input_stream(struct InputRedir *rd)
{
  int rv = 1;

  if (rd->stream && rd->stream != stdin) {
    if (rd->is_pipe)
      rv = ! pclose(rd->stream); /* pclose returns 0 = success, non-zero = failure */
    else
      rv = ! fclose(rd->stream); /* fclose the same; */
  }

  rd->stream = NULL;
  rd->is_pipe = 0;
  return rv;
}


/* ---------------------------------------------------------------------- */


int broken_pipe;

static void 
bp_signal_handler(int signum)
{
  broken_pipe = 1;

  /* fprintf(stderr, "Handle broken pipe signal\n"); */

  if (signal(SIGPIPE, bp_signal_handler) == SIG_ERR)
    perror("Can't reinstall signal handler for broken pipe");
}


/* ---------------------------------------------------------------------- */

void 
print_output(CorpusList *cl, 
             FILE *fd,
             int interactive,
             ContextDescriptor *cd,
             int first, int last, /* range checking done by mode-specific print function */
             PrintMode mode)
{
  switch (mode) {
    
  case PrintSGML:
    sgml_print_output(cl, fd, interactive, cd, first, last);
    break;
    
  case PrintHTML:
    html_print_output(cl, fd, interactive, cd, first, last);
    break;
    
  case PrintLATEX:
    latex_print_output(cl, fd, interactive, cd, first, last);
    break;
    
  case PrintASCII:
    ascii_print_output(cl, fd, interactive, cd, first, last);
    break;
    
  default:
    cqpmessage(Error, "Unknown print mode");
    break;
  }
}

void 
catalog_corpus(CorpusList *cl,
               struct Redir *rd,
               int first, int last,
               PrintMode mode)
{
  int i;
  Boolean printHeader = False;

  struct Redir default_redir;

  if ((cl == NULL) || (!access_corpus(cl)))
    return;

  if (!rd) {
    default_redir.name = NULL;
    default_redir.mode = "w";
    default_redir.stream = NULL;
    default_redir.is_pipe = 0;
    rd = &default_redir;
  }

  if (!open_stream(rd, cl->corpus->charset)) {
    cqpmessage(Error, "Can't open output stream.");
    return;
  }

  assert(rd->stream);

  /* ======================================== BINARY OUTPUT */

  if (rangeoutput || mode == PrintBINARY) {

    for (i = 0; (i < cl->size); i++) {
      fwrite(&(cl->range[i].start), sizeof(int), 1, rd->stream);
      fwrite(&(cl->range[i].end), sizeof(int), 1, rd->stream);
    }

  }
  else {

    /* ====================================== ASCII, SGML OR HTML OUTPUT */

/*     if (CD.printStructureTags == NULL) */
/*       CD.printStructureTags = ComputePrintStructures(cl); */
    /* now done for current_corpus in options.c ! */

    printHeader = GlobalPrintOptions.print_header;

    /* fraglich... */
    if (GlobalPrintMode == PrintHTML)
      printHeader = True;

    if (rd->is_pipe && handle_sigpipe) {
      if (signal(SIGPIPE, bp_signal_handler) == SIG_ERR)
        perror("Can't install signal handler for broken pipe (ignored)");
    }

    /* do the job. */
    
    verify_context_descriptor(cl->corpus, &CD, 1);
    
    broken_pipe = 0;

    /* first version (Oli Christ):
       if ((!silent || printHeader) && !(rd->stream == stdout || rd->is_paging));
       */
    /* second version (Stefan Evert):     
       if (printHeader || (mode == PrintASCII && !(rd->stream == stdout || rd->is_paging))); 
    */

    /* header is printed _only_ when explicitly requested now
     * (previous behaviour was to print header automatically when saving results to a file;
     * this makes sense when such files are created to document the results of a corpus search,
     * but nowadays they are mostly used for automatic post-processing (e.g. in a Web interface),
     * where the header is just a nuisance that has to be stripped)
     */
    if (printHeader) {
      /* print something like a header */
      print_corpus_info_header(cl, rd->stream, mode, 1);
    }
    else if (printNrMatches && mode == PrintASCII)
      fprintf(rd->stream, "%d matches.\n", cl->size);
    
    print_output(cl, rd->stream, 
                 isatty(fileno(rd->stream)) || rd->is_paging, 
                 &CD, first, last, mode);
    
    if (rd->is_paging && handle_sigpipe)
      if (signal(SIGPIPE, SIG_IGN) == SIG_ERR)
        perror("Can't reinstall SIG_IGN signal handler");
    
  }

  close_stream(rd);
}

void 
cqpmessage(MessageType type, char *format, ...)
{
  va_list ap;

  va_start(ap, format);

  if ((type != Message) || verbose_parser) {
    
    char *msg;

    switch (type) {
    case Error:
      msg = "CQP Error";
      break;
    case Warning:
      msg = "Warning";
      break;
    case Message:
      msg = "Message";
      break;
    case Info:
      msg = "Information";
      break;
    default:
      msg = "<UNKNOWN MESSAGE TYPE>";
      break;
    }

    if (!silent || type == Error) {
      fprintf(stderr, "%s:\n\t", msg);
      vfprintf(stderr, format, ap);
      fprintf(stderr, "\n");
    }

  }
  va_end(ap);
}

void 
corpus_info(CorpusList *cl)
{
  FILE *fd;
  FILE *outfd;
  char buf[1024];
  int i, ok, stream_ok;
  struct Redir rd = { NULL, NULL, NULL, 0, 0 }; /* for paging (with open_stream()) */

  CorpusList * mom = NULL;
  CorpusProperty p;

  if (cl->type == SYSTEM) {
    stream_ok = open_stream(&rd, ascii);
    outfd = (stream_ok) ? rd.stream : stdout; /* use pager, or simply print to stdout if it fails */
    /* print size (should be the mother_size entry) */
    fprintf(outfd, "Size:    %d\n", cl->mother_size);
    /* print charset */
    fprintf(outfd, "Charset: ");

    if (cl->corpus->charset == unknown_charset) {
      fprintf(outfd, "<unsupported> (%s)\n", cl_corpus_property(cl->corpus, "charset"));
    }
    else {
      fprintf(outfd, "%s\n", cl_charset_name(cl->corpus->charset));
    }
    /* print properties */
    fprintf(outfd, "Properties:\n");
    p = cl_first_corpus_property(cl->corpus);
    if (p == NULL)
      fprintf(outfd, "\t<none>\n");
    else 
      for ( ; p != NULL; p = cl_next_corpus_property(p))
        fprintf(outfd, "\t%s = '%s'\n", p->property, p->value);
    fprintf(outfd, "\n");
    

    if (cl->corpus->info_file == NULL)
      fprintf(outfd, "No further information available about %s\n", cl->name);
    else if ((fd = OpenFile(cl->corpus->info_file, "r")) == NULL)
      cqpmessage(Warning,
                 "Can't open info file %s for reading",
                 cl->corpus->info_file);
    else {
      ok = 1;
      do {
        i = fread(&buf[0], sizeof(char), 1024, fd);
        if (fwrite(&buf[0], sizeof(char), i, outfd) != i)
          ok = 0;
      } while (ok && (i == 1024));
      fclose(fd);
    }

    if (stream_ok) 
      close_stream(&rd);        /* close pipe to pager if we were using it */
  }
  else if (cl->mother_name == NULL)
    cqpmessage(Warning, 
               "Corrupt corpus information for %s", cl->name);
  else if ((mom = findcorpus(cl->mother_name, SYSTEM, 0)) != NULL) {
    corpus_info(mom);
  }
  else {
    cqpmessage(Info,
               "%s is a subcorpus of %s which is not loaded. Try 'info %s' "
               "for information about %s.\n",
               cl->name, cl->mother_name, cl->mother_name, cl->mother_name);
  }
}

/* ---------------------------------------------------------------------- */

void 
free_tabulation_list(void) {
  TabulationItem item = TabulationList;
  TabulationItem old = NULL;
  while (item) {
    cl_free(item->attribute_name);
    /* if we had proper reference counting, we would delete the attribute handle here
       (but calling cl_delete_attribute() would _completely_ remove the attribute from the corpus for this session!) */
    old = item;
    item = item->next;
    cl_free(old);
  }
  TabulationList = NULL;
}

TabulationItem
new_tabulation_item(void) {
  TabulationItem item = (TabulationItem) cl_malloc(sizeof(struct _TabulationItem));
  item->attribute_name = NULL;
  item->attribute = NULL;
  item->attribute_type = ATT_NONE;
  item->flags = 0;
  item->anchor1 = NoField;
  item->offset1 = 0;
  item->anchor2 = NoField;
  item->offset2 = 0;
  item->next = NULL;
  return item;
}

void
append_tabulation_item(TabulationItem item) {
  TabulationItem end = TabulationList;
  item->next = NULL;            /* make sure that item is marked as end of list */
  if (end == NULL) {            /* empty list: item becomes first entry */
    TabulationList = item;
  }
  else {                        /* otherwise, seek end of list and append item */
    while (end->next) 
      end = end->next;
    end->next = item;
  }
}

int
pt_get_anchor_cpos(CorpusList *cl, int n, FieldType anchor, int offset) {
  int real_n, cpos;

  real_n = (cl->sortidx) ? cl->sortidx[n] : n; /* get anchor for n-th match */
  switch (anchor) {
  case KeywordField:
    cpos = cl->keywords[real_n];
    break;
  case TargetField:
    cpos = cl->targets[real_n];
    break;
  case MatchField:
    cpos = cl->range[real_n].start;
    break;
  case MatchEndField:
    cpos = cl->range[real_n].end;
    break;
  case NoField:
  default:
    assert(0 && "Can't be");
    break;
  }

  if (cpos < 0) return cpos;    /* -1 indicates undefined anchor */
  
  cpos += offset;
  if (cpos < 0) cpos = 0;
  if (cpos >= cl->mother_size) cpos = cl->mother_size - 1;

  return cpos;
}

int
pt_validate_anchor(CorpusList *cl, FieldType anchor) {  
  switch (anchor) {
  case KeywordField:
    if (cl->keywords == NULL) {
      cqpmessage(Error, "No keyword anchors defined for named query %s", cl->name);
      return 0;
    }
    break;
  case TargetField:
    if (cl->targets == NULL) {
      cqpmessage(Error, "No target anchors defined for named query %s", cl->name);
      return 0;
    }
    break;
  case MatchField:
  case MatchEndField:
    /* should always be present */
    assert(cl->range != NULL);
    break;
  case NoField:
  default:
    cqpmessage(Error, "Illegal anchor in tabulate command");
    return 0;
    break;
  }
  return 1;
}

int
print_tabulation(CorpusList *cl, int first, int last, struct Redir *rd) {
  TabulationItem item = TabulationList;
  int current;
  
  if (! cl) 
    return 0;

  if (first <= 0) first = 0;    /* make sure that first and last match to tabulate are in range */
  if (last >= cl->size) last = cl->size - 1;

  while (item) {                /* obtain attribute handles for tabulation items */
    if (item->attribute_name) {
      if (NULL != (item->attribute = cl_new_attribute(cl->corpus, item->attribute_name, ATT_POS))) {
        item->attribute_type = ATT_POS;
      }
      else if (NULL != (item->attribute = cl_new_attribute(cl->corpus, item->attribute_name, ATT_STRUC))) {
        item->attribute_type = ATT_STRUC;
        if (! cl_struc_values(item->attribute)) {
          cqpmessage(Error, "No annotated values for s-attribute ``%s'' in named query %s", item->attribute_name, cl->name);
          return 0;
        }
      }
      else {
        cqpmessage(Error, "Can't find attribute ``%s'' for named query %s", item->attribute_name, cl->name);
        return 0;
      }
    }
    else {
      item->attribute_type = ATT_NONE; /* no attribute -> print corpus position */
    }
    if (cl->size > 0) {
      /* work around bug: anchor validation will fail for empty query result (but then loop below is void anyway) */
      if (! (pt_validate_anchor(cl, item->anchor1) && pt_validate_anchor(cl, item->anchor2)))
	return 0;
    }
    item = item->next;
  }

  if (! open_stream(rd, cl->corpus->charset)) {
    cqpmessage(Error, "Can't redirect output to file or pipe\n");
    return 0;
  }

  /* tabulate selected attribute values for matches <first> .. <last> */
  for (current = first; current <= last; current++) {
    TabulationItem item = TabulationList;
    while (item) {
      int start = pt_get_anchor_cpos(cl, current, item->anchor1, item->offset1);
      int end   = pt_get_anchor_cpos(cl, current, item->anchor2, item->offset2);
      int cpos;

      if (start < 0 || end < 0) /* one of the anchors is undefined -> print single undefined value for entire range */
        start = end = -1;

      for (cpos = start; cpos <= end; cpos++) {
        if (item->attribute_type == ATT_NONE) {
          fprintf(rd->stream, "%d", cpos);
        }
        else {
          if (cpos >= 0) {      /* undefined anchors print empty string */
            char *string = NULL;
            if (item->attribute_type == ATT_POS) 
              string = cl_cpos2str(item->attribute, cpos);
            else
              string = cl_cpos2struc2str(item->attribute, cpos);
            if (string) {
              if (item->flags) {
                char *copy = cl_strdup(string);
                cl_string_canonical(copy, item->flags);
                fprintf(rd->stream, "%s", copy);
                cl_free(copy);
              }
              else {
                fprintf(rd->stream, "%s", string);
              }
            }
          }
        }
        if (cpos < end)         /* multiple values for tabulation item are separated by blanks */
          fprintf(rd->stream, " "); 
      }
      if (item->next)           /* multiple tabulation items are separated by TABs */
        fprintf(rd->stream, "\t");
      item = item->next;
    }
    fprintf(rd->stream, "\n");
  }
  
  close_stream(rd);
  free_tabulation_list();
  return 1;
}

/* ---------------------------------------------------------------------- */


