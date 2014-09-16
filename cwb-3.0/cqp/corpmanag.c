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

#include <stddef.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <math.h>

#include "../cl/globals.h"
#include "../cl/macros.h"
#include "../cl/corpus.h"
#include "../cl/attributes.h"
#include "../cl/cdaccess.h"
#include "../cl/fileutils.h"

#include "corpmanag.h"
#include "cqp.h"
#include "options.h"
#include "output.h"
#include "ranges.h"
#include "paths.h"

#define COLON ':'
#define SLASH '^'


#define subcorpload_debug False

/** magic number for {?? subcorpus files} */
#define SUBCORPMAGIC 36193928
/* the sum of the original programmers' birthdays: 15081963 (Max) + 21111965 (Oli) */


/* typedef struct { */
/*   int magic; */
/*   char *regdir; */
/*   char *regname; */
/*   int  *ml; */
/* } bincorpform; */

/* module-internal function prototypes */

static Boolean attach_subcorpus(CorpusList *cl,
                                char *advertised_directory,
                                char *advertised_filename);

CorpusList *GetSystemCorpus(char *name, char *registry);

/* -------------------------------------------------- */

/** Global list of currently-loaded corpora */
CorpusList *corpuslist;


/**
 * Initialises the global corpus list (sets it to NULL, no matter what its value was).
 */
void
init_corpuslist(void)
{
  corpuslist = (CorpusList *)NULL;
  set_current_corpus(NULL, 0);
}

/**
 * Resets to empty a CorpusList object.
 *
 * This is done, largely, by freeing all its members
 * (and setting nonfreeable members to 0 or NULL)...
 *
 * @param cl         The corpus list to initialise.
 * @param free_name  Boolean: the name, mother_name and mother_sizemembers
 *                   will be cleared iff free_name.
 */
void
initialize_cl(CorpusList *cl, int free_name)
{
  if (free_name) {
    cl_free(cl->name);
    cl_free(cl->mother_name);
    cl->mother_size = 0;
  }
  cl_free(cl->registry);
  cl_free(cl->range);
  cl_free(cl->abs_fn);

  cl->type = UNDEF;
  cl->saved = cl->loaded = cl->needs_update = False;

  cl_free(cl->query_corpus);
  cl_free(cl->query_text);

  cl->corpus = NULL;
  cl->size = 0;

  if (cl->cd) 
    FreeContextDescriptor(&(cl->cd));

  cl_free(cl->sortidx);

  cl_free(cl->targets);
  cl_free(cl->keywords);
}

/**
 * Frees the global list of currently-loaded corpora.
 *
 * This function sets the corpus list to NULL and frees all members of the list.
 */
void
free_corpuslist(void)
{
  CorpusList *tmp;
  
  while(corpuslist) {
    tmp = corpuslist;
    corpuslist = tmp->next;
    initialize_cl(tmp, True);
    free(tmp);
  }
  set_current_corpus(NULL, 0);
}

/**
 * Creates a new CorpusList object.
 */
CorpusList *
NewCL(void)
{
  CorpusList *cl;

  New(cl, CorpusList);

  cl->name = NULL;
  cl->mother_name = NULL;
  cl->mother_size = 0;
  cl->registry = NULL;
  cl->abs_fn = NULL;
  cl->type = UNDEF;

  cl->local_dir = NULL;

  cl->query_corpus = NULL;
  cl->query_text = NULL;

  cl->saved = False;
  cl->loaded = False;
  cl->needs_update = False;
  cl->corpus = NULL;
  cl->range = NULL;
  cl->size = 0;
  cl->sortidx = NULL;
  cl->targets = NULL;
  cl->keywords = NULL;

  cl->cd = NULL;

  cl->next = NULL;

  return cl;
}

/* ------------------------------------------------------------ */

FieldType 
field_name_to_type(char *name)
{
  if (strcasecmp(name, "nofield") == 0)
    return NoField;
  else if (strcasecmp(name, "keyword") == 0)
    return KeywordField;
  else if ((strcasecmp(name, "target") == 0) ||
           (strcasecmp(name, "collocate") == 0))
    return TargetField;
  else if (strcasecmp(name, "match") == 0)
    return MatchField;
  else if (strcasecmp(name, "matchend") == 0)
    return MatchEndField;
  else
    return NoField;
}

char *
field_type_to_name(FieldType ft) {
  switch (ft) {
  case NoField:
    return "nofield";
  case MatchField:
    return "match";
  case MatchEndField:
    return "matchend";
  case TargetField:
    return "target";
  case KeywordField:
    return "keyword";
  default:
    cqpmessage(Error, "Internal Error: Unknown field type #%d", ft);
    return "";
  }
}


int 
NrFieldValues(CorpusList *cl, FieldType ft)
{
  int i, nr_items;
  
  nr_items = 0;

  if (cl != NULL) {
    switch (ft) {
    case MatchField:
      nr_items = cl->size;
      break;

    case KeywordField:
      if (cl->keywords != NULL)
        for (i = 0; i < cl->size; i++)
          if (cl->keywords[i] >= 0)
            nr_items++;
      break;

    case TargetField:
      if (cl->targets != NULL)
        for (i = 0; i < cl->size; i++)
          if (cl->targets[i] >= 0)
            nr_items++;
      break;
      
    default:
    case NoField:
      fprintf(stderr, "Illegal field type %d\n", ft);
      break;
    }
  }
  return nr_items;
}

/* ---------------------------------------------------------------------- */

/* A utility function required by ensure_corpus_size() */
int
SystemCorpusSize(Corpus *corpus)
{
  Attribute *attr;
  
  if ((attr = find_attribute(corpus,
                             DEFAULT_ATT_NAME,
                             ATT_POS, NULL)) != NULL)
    return get_attribute_size(attr);
  else
    return -1;
}

/* ---------------------------------------------------------------------- */
/**
 * This is an internal function used to ensure that a system corpus
 * from the corpus list is accessible and that its size has been
 * computed. In case of subcorpora, this function implements delayed
 * loading. It is necessary because of a hack that prevents CQP from
 * determining the sizes of all know corpora at start-up (which caused
 * annoying delays if one or more corpora are not accessible) and from
 * reading all subcorpora in the local corpus directory (which caused
 * a number of delays and crashes with MP templates).
 * ensure_corpus_size() is needed by findcorpus() and
 * ensure_syscorpus() at the very least. It may be needed in other
 * places to keep CQP from crashing.
 *
 * @param cl The corpus whose accessibility is to be checked.
 * @return   Boolean: true if access is OK.
 */
Boolean
ensure_corpus_size(CorpusList *cl)
{
  if (cl->type == SYSTEM) { 
    /* System corpus: check corpus size (may have to be computed now) */

    /* Check whether or not the size of the corpus has already been determined. */
    if (cl->mother_size <= 0) { /* for a system corpus, this is its size */
      /* Corpus size hasn't been computed yet, so we must do it now */

      int attr_size = SystemCorpusSize(cl->corpus);

      if (attr_size <= 0) {
        switch (user_level) {
        case 0:
          cqpmessage(Warning, "Data access error (%s)\n"
                     "Perhaps the corpus %s is not accessible "
                     "from the machine you are using.", 
                     cdperror_string(cderrno), cl->name);
          break;
        case 1:
          cqpmessage(Warning, "Corpus %s registered, but not accessible\n", cl->name);
          break;
        default:
          break;
        }

        /* If we couldn't access the corpus, remove it from the list so
           the user isn't tempted to try again. 
           Very Microsoftish, isn't it? ;-) */
        dropcorpus(cl);
        
        /* Now tell the calling function that corpus is inaccessible */
        return False;
      }
      
      /* Set size related fields in corpus list entry */
      cl->mother_size = attr_size;
      cl->range[0].end = attr_size - 1;

      /* OK */
      return True;
    }
  }
  else if (cl->type == SUB) {
    /* Subcorpus: load into memory if necessary */

    if (!cl->loaded) {
      /* load subcorpus (the local_dir entry of the corpus structure contains
         the name of the directory where the disk file can be found */
      char filename[1024];
      
      /* re-create subcorpus filename from corpus structure
         (cf. the treatment in load_corpusnames()) */
      if (cl->mother_name == NULL) {
        strcpy(filename, cl->name);
      } else {
        sprintf(filename, "%s:%s", cl->mother_name, cl->name);
      }
      return (attach_subcorpus(cl, cl->local_dir, filename));
    }

    /* if it's already loaded, just return OK */
    return True;
  }

  /* If there are any other types, at least we don't need to do anything
     with them, so just return True in this case. */
  return True;
}





/**
 * Finds a loaded corpus.
 *
 * This function tries to find the corpus with name 'name' in the list of currently
 * loaded corpora. In case of subcorpora, qualifier is the mother's
 * name. in case of system corpora, qualifier is the registry. If
 * qualifier is NULL, it is neglected and the first matching corpus is
 * returned. If type is not UNDEF, only corpora of that type are
 * returned. No side effects take place.
 *
 * @param name       The corpus we are lookign for.
 * @param qualifier  An extra "bit" of the corpus name (see function description).
 * @param type       Which type of corpus is wanted (may be UNDEF).
 * @return           Pointer to the CorpusList of the corpus that was found.
 */
CorpusList *
LoadedCorpus(char *name,
             char *qualifier,
             CorpusType type)
{
  CorpusList *sp;

  for (sp  = corpuslist; sp; sp = sp->next)

    if ((sp->type == type) ||
        ((type == UNDEF) && (sp->type != TEMP)))

      /* the type is ok. Check the name. */

      if (STREQ(sp->name, name)) {
        
        /* ignoring the qualifier is OK for system corpora (although its behaviour is not very well defined if there are
           multiple corpora with the same name in different registry directories), but it can get really messy with subcorpora;
           just imagine you've got two subcorpora with the same name (say, A) for two system corpora (say, BNC and WSJ); you
           have activated the BNC, type "cat A;", and what you get are the results for WSJ because LoadedCorpus() happens to
           find WSJ:A first; thus, if we are comparing an unqualified name to a subcorpus, we use the currently activated corpus
           as a qualifier; if no corpus is activated, we revert to guessing, which is useful when a subcorpus is loaded from
           disk immediately after startup */ 

        /* the name is also ok. Check the qualifier */
        
        if (qualifier == NULL) {
          if (sp->type == SUB) {
            if (current_corpus) {
              if (current_corpus->type == SUB) {
                qualifier = current_corpus->mother_name;
              }
              else {
                qualifier = current_corpus->name;
              }
              if (STREQ(sp->mother_name, qualifier))
                return sp;
            }
            else {
              return sp;
            }
          }
          else {
            return sp;
          }
        }
        else if (((sp->type == SYSTEM) && STREQ(sp->registry, qualifier)) ||
                 ((sp->type == SUB) && STREQ(sp->mother_name, qualifier)))
          return sp;
      }

  return NULL;
}

/* ---------------------------------------------------------------------- */

CorpusList *
findcorpus(char *s, CorpusType type, int try_recursive_search)
{
  CorpusList *sp, *tmp;
  char *colon;

  char mother_corpus[64];
  char *expansion;
  char *real_name;

  if (type != SYSTEM) {
    if ((colon = strchr(s, COLON)) != NULL) {
      strcpy(mother_corpus, s);
      mother_corpus[colon - s] = '\0';
      real_name = colon + 1;
    }
    else {
      mother_corpus[0] = '\0';
      real_name = s;
    }
  }
  else {
    real_name = s;
    mother_corpus[0] = '\0';
  }

  expansion = strchr(real_name, SLASH);

  if (mother_corpus[0] == '\0')
    sp = LoadedCorpus(real_name, NULL, type);
  else
    sp = LoadedCorpus(real_name, mother_corpus, type);

  /* We need to call ensure_corpus_size() to implement delayed loading. */
  if (sp) {
    if (!ensure_corpus_size(sp))
      return NULL;                      /* return failure */
  }
  /* (sp==0): try to find corpus through implicit expansion ("A^s" == "A expand to s") */
  else if (type != SYSTEM && expansion && try_recursive_search) {
      
    char new_name[128];
    Context ctx;

    strcpy(new_name, real_name);
    new_name[expansion - real_name] = '\0';

    if (mother_corpus[0] == '\0')
      sp = LoadedCorpus(new_name, NULL, type);
    else
      sp = LoadedCorpus(new_name, mother_corpus, type);

    if (sp) {

      int i;

      if (!ensure_corpus_size(sp)) /* delayed loading */
        return NULL; 
      if (!access_corpus(sp))
        return NULL;
      
      assert(sp->corpus);
      
      if ((ctx.attrib = find_attribute(sp->corpus, expansion+1, ATT_STRUC, NULL)) == NULL) {
        cqpmessage(Warning, "Can't expand to ``%s'' -- \n"
                   "no such structural attribute in %s",
                   expansion+1, sp->mother_name);
        return NULL;
      }
      ctx.direction = leftright;
      ctx.type = structure;
      ctx.size = 1;


      tmp = duplicate_corpus(sp, real_name, False);
      
      if (tmp == NULL) {
        fprintf(stderr, "Weird error in findcorpus\n");
        return NULL;
      }

      for (i = 0; i < tmp->size; i++) {

        int left, right;

        left = calculate_leftboundary(tmp,
                                      tmp->range[i].start,
                                      ctx);
        right = calculate_rightboundary(tmp,
                                        tmp->range[i].end,
                                        ctx);

        if (left >= 0 && right >= 0) {
          tmp->range[i].start = left;
          tmp->range[i].end   = right;
        }

      }

      RangeSetop(tmp, RUniq, NULL, NULL);

      touch_corpus(tmp);

      return tmp;
    }

  }

  return sp;
}

void
dropcorpus(CorpusList *cl)
{
  CorpusList *prev;

  /* setup the new chain of corpora */
  if (cl == corpuslist)
    /* delete first element of the list */
    corpuslist = cl->next;
  else if (corpuslist != NULL) {
    prev = corpuslist;

    while ((prev != NULL) && (prev->next != cl))
      prev = prev->next;

    if (prev == NULL) {
      fprintf(stderr, "%s:dropcorpus(): cl is not in list of loaded corpora\n",
              __FILE__);
      cl = NULL;
    }
    else {
      assert(prev->next == cl);
      prev->next = cl->next;
    }
  }
  else {
    fprintf(stderr, "%s:dropcorpus(): cl is not in list of loaded corpora (list empty)\n",
            __FILE__);
    cl = NULL;
  }

  if (current_corpus == cl)
    set_current_corpus(corpuslist, 0);

  if (cl != NULL) {
    initialize_cl(cl, True);
    free(cl);
  }
}

CorpusList *
duplicate_corpus(CorpusList *cl,
                 char *new_name,
                 Boolean force_overwrite)
{
  CorpusList *newc;

  if (cl == NULL) {
    fprintf(stderr, "%s:duplicate_corpus(): WARNING: Called with NULL corpus\n",
            __FILE__);
    return NULL;
  }

  /* newc = findcorpus(new_name, SUB, 0); */

  newc = LoadedCorpus(new_name, 
                      (cl->type == SYSTEM ? cl->registry
                                          : cl->mother_name),
                      SUB);

  /* try to make a copy of myself? */
  if (newc == cl) {
    if (force_overwrite) {
      /* we do not need to copy anything, just fake that
       * we destroyed the old one. Leave all flags as they
       * were.
       */
      cqpmessage(Warning, "LHS and RHS are identical in assignment (ignored)\n");
      return cl;
    }
    else
      /* we are not allowed to overwrite myself, so say
       * that we did not succeed.
       */
      return NULL;
  }

  /* we only get here when newc != cl */
  assert(newc != cl);

  if (newc == NULL) {
    newc = NewCL();

    /* insert it into the chain of corpora */
    newc->next = corpuslist;
    corpuslist = newc;
  }
  else if (force_overwrite)
    initialize_cl(newc, True);  /* clear all fields of newc */
  else
    newc = NULL;
  
  if (newc) {
    /* newc is not NULL iff we are about to make that copy.
     * newc is "fresh", i.e., all fields either have just been
     * allocated or are re-initialized.
     */
    newc->name = cl_strdup(new_name);
    newc->mother_name = cl_strdup(cl->mother_name);
    newc->mother_size = cl->mother_size;
    newc->registry = cl_strdup(cl->registry);
    newc->abs_fn = NULL;
    newc->type = SUB;

    /* TODO: does copying the query_* fields really make sense? */

    newc->query_corpus = cl->query_corpus ? cl_strdup(cl->query_corpus) : NULL;
    newc->query_text = cl->query_text ? cl_strdup(cl->query_text) : NULL;

    newc->saved = False;
    newc->loaded = cl->loaded;
    newc->needs_update = True;

    newc->corpus = cl->corpus;
    newc->size = cl->size;

    if (newc->size > 0) {
      newc->range = (Range *)cl_malloc(sizeof(Range) * newc->size);
      memcpy((char *)newc->range, (char *)cl->range, sizeof(Range) * newc->size);
    }
    else
      newc->range = NULL;

    if (cl->sortidx) {
      newc->sortidx = (int *)cl_malloc(cl->size * sizeof(int));
      /* bcopy(cl->sortidx, newc->sortidx, cl->size * sizeof(int)); */
      memcpy(newc->sortidx, cl->sortidx, cl->size * sizeof(int));
    }
    else
      newc->sortidx = NULL;

    if (cl->targets) {
      newc->targets = (int *)cl_malloc(cl->size * sizeof(int));
      /* bcopy(cl->targets, newc->targets, cl->size * sizeof(int)); */
      memcpy(newc->targets, cl->targets, cl->size * sizeof(int));
    }
    else
      newc->targets = NULL;

    if (cl->keywords) {
      newc->keywords = (int *)cl_malloc(cl->size * sizeof(int));
      /* bcopy(cl->keywords, newc->keywords, cl->size * sizeof(int)); */
      memcpy(newc->keywords, cl->keywords, cl->size * sizeof(int));
    }
    else
      newc->keywords = NULL;

    /* TODO: decide whether we should copy the position_lists */

  }

  if (auto_save)
    save_subcorpus(newc, NULL);

  return newc;
}

CorpusList *
make_temp_corpus(CorpusList *cl,
                 char *new_name)
{
  CorpusList *newc;

  if (cl == NULL) {
    fprintf(stderr, "%s:duplicate_corpus(): WARNING: Called with NULL corpus\n",
            __FILE__);
    return NULL;
  }

  newc = findcorpus(new_name, TEMP, 0);

  /* try to make a copy of myself? */
  if (newc == cl)
    /* we do not need to copy anything, just fake that
     * we destroyed the old one. Leave all flags as they
     * were.
     */
      return cl;

  if (newc == NULL) {
    newc = NewCL();

    /* insert it into the chain of corpora */
    newc->next = corpuslist;
    corpuslist = newc;
  }
  else
    initialize_cl(newc, True);  /* clear all fields of newc */
  
  if (newc) {
    /* newc is not NULL iff we are about to make that copy.
     * newc is "fresh", i.e., all fields either have just been
     * allocated or are re-initialized.
     */
    newc->name = cl_strdup(cl->name);
    newc->mother_name = cl_strdup(cl->mother_name);
    newc->mother_size = cl->mother_size;
    newc->registry = cl_strdup(cl->registry);
    newc->abs_fn = NULL;
    newc->type = TEMP;

    newc->query_corpus = cl->query_corpus ? cl_strdup(cl->query_corpus) : NULL;
    newc->query_text = cl->query_text ? cl_strdup(cl->query_text) : NULL;

    newc->saved = False;
    newc->loaded = cl->loaded;
    newc->needs_update = False; /* we never want to save a TEMP corpus */

    newc->corpus = cl->corpus;
    newc->size = cl->size;
    newc->sortidx = NULL;
    newc->keywords = NULL;

    /* copy the targets. Thu May 11 12:33:23 1995 (oli) */

    if (cl->targets) {

      assert(newc->size > 0);

      newc->targets = (int *)cl_malloc(sizeof(int) * newc->size);
      memcpy((char *)newc->targets, (char *)cl->targets, sizeof(int) * newc->size);

    }
    else
      newc->targets = NULL;

    /* and the keywords ... (evert) */

    if (cl->keywords) {

      assert(newc->size > 0);

      newc->keywords = (int *)cl_malloc(sizeof(int) * newc->size);
      memcpy((char *)newc->keywords, (char *)cl->keywords, sizeof(int) * newc->size);

    }
    else
      newc->keywords = NULL;

    if (newc->size > 0) {
      newc->range = (Range *)cl_malloc(sizeof(Range) * newc->size);
      memcpy((char *)newc->range, (char *)cl->range, sizeof(Range) * newc->size);
    }
    else
      newc->range = NULL;
  }
  
  return newc;
}

CorpusList *
assign_temp_to_sub(CorpusList *tmp, char *subname)
{
  CorpusList *cl;

  if (tmp == NULL) {
    fprintf(stderr, "%s:duplicate_corpus(): WARNING: Called with NULL corpus\n",
            __FILE__);
    return NULL;
  }
  
  assert(tmp->type == TEMP);

  if ((cl = findcorpus(subname, SUB, 0)) != NULL) {

    /*
     * we copy, since otherwise xkwic gets messed up with the deletion
     * of an actually displayed corpus
     */

    initialize_cl(cl, True);

    cl->name = cl_strdup(subname);
    cl_free(tmp->name);

    cl->mother_name = tmp->mother_name; tmp->mother_name = NULL;
    cl->mother_size = tmp->mother_size;
    cl->registry = tmp->registry; tmp->registry = NULL;
    cl->range = tmp->range; tmp->range = NULL;
    cl->abs_fn = tmp->abs_fn; tmp->abs_fn = NULL;

    cl->keywords = tmp->keywords; tmp->keywords = NULL;
    cl->targets = tmp->targets; tmp->targets = NULL;
    cl->sortidx = tmp->sortidx; tmp->sortidx = NULL;

    cl->query_corpus = tmp->query_corpus;
    cl->query_text = tmp->query_text;
    tmp->query_corpus = NULL;
    tmp->query_text = NULL;

    cl->type = SUB; tmp->type = UNDEF;
    cl->saved = False;
    cl->loaded = True;
    cl->needs_update = True;

    cl->corpus = tmp->corpus; tmp->corpus = NULL;
    cl->size = tmp->size; tmp->size = 0;
    
    if (auto_save)
      save_subcorpus(cl, NULL);

    dropcorpus(tmp);
    
    return cl;
  }
  else {
    /* we only have to change some fields of tmp */
    cl_free(tmp->name);
    tmp->name = cl_strdup(subname);
    tmp->type = SUB;
    tmp->needs_update = True;
    cl_free(tmp->abs_fn);

    if (auto_save)
      save_subcorpus(tmp, NULL);

    return tmp;
  }

  assert(0 && "Not reached");
  return NULL;
}

void
drop_temp_corpora(void)
{
  CorpusList *cl, *prev, *del;
  

  /* could be much more intelligent (exponential, 
   * since dropcorpus does the very same linear search
   * too), but keep this until I have some spare
   * time
   */
  
  prev = NULL;
  cl = corpuslist;

  while (cl != NULL) {
    if (cl->type == TEMP) {

      del = cl;
      cl = cl->next;
      
      if (prev == NULL)
        corpuslist = del->next;
      else
        prev->next = del->next;
      
      initialize_cl(del, True);
      free(del);
    }
    else {
      prev = cl;
      cl = cl->next;
    }
  }

  for (cl = corpuslist; cl; cl = cl->next)
    if (cl->type == TEMP)
      dropcorpus(cl);
}


/* ---------------------------------------------------------------------- */

static char *
changecase_string(char *str, enum case_mode mode)
{
  char *str_new;
  int i, len = strlen(str);

  str_new = cl_strdup(str);

  for (i = 0; i <= len; i++)
    str_new[i] = (mode == LOWER) ? tolower(str[i]) : toupper(str[i]);

  return (str_new);
}

static char *
changecase_string_no_copy(char *str, enum case_mode mode)
{
  int i;

  for (i = 0; str[i]; i++)
    str[i] = (mode == LOWER) ? tolower(str[i]) : toupper(str[i]);

  return str;
}

static char *
get_fulllocalpath(CorpusList *cl, int qualify)
{
  char fullname[1024];
  char *upname;

  if (qualify) {
    upname = cl->mother_name ? changecase_string(cl->mother_name, UPPER) : cl_strdup("NONE");

    sprintf(fullname, "%s%s%s:%s", LOCAL_CORP_PATH,
            LOCAL_CORP_PATH[strlen(LOCAL_CORP_PATH)-1] == '/' ? "" : "/",
            cl->mother_name ? cl->mother_name : "NONE",
            cl->name);

    cl_free(upname);
  }
  else
    sprintf(fullname, "%s%s%s", LOCAL_CORP_PATH,
            LOCAL_CORP_PATH[strlen(LOCAL_CORP_PATH)-1] == '/' ? "" : "/",
            cl->name);

  return cl_strdup(fullname);
}  

/* ---------------------------------------------------------------------- */


/**
 * Tests whether a file is accessible.
 *
 * A file is considered accessible
 * iff user can read it and it is not a (sub)directory.
 *
 * This test is used for registry entries.
 *
 * @param dir   Directory in which the file is to be found.
 * @param file  The filename to check.
 * @return      Boolean: true iff file is accessible.
 */
static Boolean
accessible(char *dir, char *file)
{

  /* fullname is allocated: lenth of string dir and length of string file */
  /*                        plus 1 for the '\0' character                 */
  /*                        plus 1 for an additional '/'                  */
  char *fullname = (char *)cl_malloc(strlen(dir) + strlen(file) + 2);
  Boolean success;
  struct stat filestat;

  fullname[0] = '\0';
  strcat(fullname, dir);
  if (fullname[strlen(fullname)-1] != '/')
    strcat(fullname, "/");
  strcat(fullname, file);
  
  success = False;
  if ((0 == stat(fullname, &filestat)) &&
      (! S_ISDIR(filestat.st_mode)) &&
      (access(fullname, R_OK) == 0)) {
    success = True;
  }

  free(fullname);
  
  return(success);
}

/* THIS FUNCTION IS CURRENTLY UNUSED */
/* Its previous purpose was to check the magic number of potential saved query files in the data directory,
   but this caused enormous delays when there were lots of files in this directory (e.g. in BNCweb).  So now
   every file whose name looks right will be inserted into the internal list, but accessing it will fail
   if it turns out to be bogus (which shouldn't happen anyway if the directory is handled by a sane person). */
int
check_stamp(char *directory, char *fname)
{
  FILE *fd;
  char full_name[1024];
  int magic, ok;

  sprintf(full_name, "%s/%s", directory, fname);

  if (((fd = OpenFile(full_name, "r")) == NULL) ||
      (fread(&magic, sizeof(int), 1, fd) == 0) ||
      ((magic != SUBCORPMAGIC) && (magic != SUBCORPMAGIC+1)))
    ok = 0;
  else
    ok = 1;
  
  if (fd)
    fclose(fd);
  
  return ok;
}

/* ---------------------------------------------------------------------- */

void
load_corpusnames(enum corpus_type ct)
{
  DIR           *dp;
  struct dirent *ep;
  char          *entry;

  char          dirlist[MAX_LINE_LENGTH];
  char          *dirname;
  CorpusList    *corpus;

  if (!((ct == SYSTEM) || (ct == SUB))) {
    fprintf(stderr, "Can't load corpus names for type %d\n",
            ct);
    return;
  }

  if (ct == SYSTEM) {
    if (registry == NULL)
      strcpy(dirlist, central_corpus_directory());
    else
      strcpy(dirlist, registry);
  }
  else 
    strcpy(dirlist, LOCAL_CORP_PATH);

  for (corpus = corpuslist; corpus != NULL; corpus = corpus->next)
    if ((corpus->type == ct) && (corpus->saved == True))
      corpus->type = TEMP;
  drop_temp_corpora();
      
  for (dirname = get_path_component(dirlist); 
       dirname;
       dirname = get_path_component(NULL)) {
    int optional_dir = 0; /* 1 = optional registry directory -> don't issue warning if not mounted */
    if (*dirname == '?') {
      dirname++;
      optional_dir = 1;
  }

    dp = opendir(dirname);
  
    if (dp != NULL) {

      /* discard all (loaded) corpora of this type from 
       * list of available corpora.
       */
      
      while ((ep = readdir(dp))) {
        if ((strchr(ep->d_name, '.') == NULL) &&   /* ignore files with '.' char in registry (such as hidden files) */
            (strchr(ep->d_name, '~') == NULL) &&   /* ignore files with '~' char in registry (such as emacs backup files) */
            (accessible(dirname, ep->d_name))) {   /* ignore directories & files user can't access (hidden from user) */
          
          if (ct == SUB) {
            char *colon;

            /* It can take quite long to check all files if data directory contains thousands of saved queries 
               (as it often does in BNCweb, for instance), and it counteracts the purpose of delayed loading: */
            /*      if (check_stamp(dirname, ep->d_name)) { */
            /* (note that the magic number will be checked when the saved query is loaded with attach_subcorpus()) */
              
            /* saved query results should always be named <CORPUS>:<query name> */
            if ((colon = strchr(ep->d_name, COLON)) != NULL) {

              /* Since there can be only a single data directory for saved query results, there should be no duplicates
                 and it is unnecessary to check with findcorpus().  It is this check that caused the greatest delays when
                 reading a data directory with thousands of files (because the internal list of corpus names has to be
                 searched linearly by findcorpus() for every file in the directory (-> quadratic complexity). */
              /*     corpus = findcorpus(ep->d_name, SUB, 0); */
              /*     if (corpus == NULL) { */
              /* (NB: one data directory constraint is implicit; loading might work, but save_subcorpus() will crash miserably) */

              char mother[1024]; /* Judith vs. Oli, round 231 */
              
              /* allocate memory for the new id */
              corpus = NewCL();
              
              /* fill the values of the new corpuslist element */
              strcpy(mother, ep->d_name);
              mother[colon - ep->d_name] = '\0';
              corpus->mother_name = cl_strdup(mother);
              corpus->name = cl_strdup(colon+1);
              
              corpus->next = corpuslist;
              corpuslist = corpus;
              
              corpus->type = SUB;
              corpus->loaded = corpus->needs_update = False;
              corpus->saved = True;
              /* Delayed loading: We don't want to load ALL subcorpora in
                 the local corpus directory because that gets us into trouble
                 with some MP template suites. So we don't call attach_subcorpus()
                 now (should be done by ensure_corpus_size() later which is 
                 called from findcorpus() etc.). In order to call it later,
                 we have to remember in which directory we found it. */
              corpus->local_dir = cl_strdup(dirname);
              /* attach_subcorpus(corpus, dirname, ep->d_name); */
            }

          } 
          else {
            
            entry = changecase_string_no_copy(ep->d_name, UPPER);

            corpus = LoadedCorpus(entry, NULL, SYSTEM);
            
            if (corpus == NULL) {
              corpus = GetSystemCorpus(entry, dirname);
              if (corpus) {
                corpus->next = corpuslist;
                corpuslist = corpus;
              }
            }
          }
        }
      }
      (void)closedir(dp);
    }
    else if (!silent && !optional_dir)
      cqpmessage(Warning, "Couldn't open directory %s (continuing)", dirname);
  }
}

void
check_available_corpora(enum corpus_type ct)
{
  if (ct == UNDEF) {
    load_corpusnames(SYSTEM);

    if (LOCAL_CORP_PATH)
      load_corpusnames(SUB);
  }
  else if (ct != TEMP)
    load_corpusnames(ct);

  /* current corpus is no longer valid -> reset it */
  set_current_corpus(NULL, 0);
}

/* ---------------------------------------------------------------------- */

CorpusList *
GetSystemCorpus(char *name, char *registry)
{
  Corpus *this_corpus;
  CorpusList *cl;

  char *cname;
  
  cname = changecase_string(name, LOWER);
  this_corpus = setup_corpus(registry, cname);
  free(cname);

  if (this_corpus) {

    /* to speed up CQP startup, don't try to read the size of each corpus
       that is inserted into the corpus list */
    /* done by:  evert (Thu Apr 30 13:51:45 MET DST 1998) */

    int attr_size = 0; /* this will tell us later that we haven't checked
                          corpus size / corpus access yet */

    cl = NewCL();

    cl->name = cl_strdup(name);
    cl->mother_name = cl_strdup(name);
    cl->mother_size = attr_size;
    
    if (this_corpus->registry_dir)
      cl->registry = cl_strdup(this_corpus->registry_dir);
    else if (registry)
      cl->registry = cl_strdup(registry);
    else {
      fprintf(stderr, "Warning: no registry directory for %s\n",
              name);
      cl->registry = NULL;
    }

    cl->type = SYSTEM;
    cl->abs_fn = NULL;
    
    cl->saved = True;
    cl->loaded = True;
    cl->needs_update = False;

    cl->corpus = this_corpus;
    
    cl->size = 1;
    
    /* the range of a system corpus is <0, attr_size-1> */
    /* Note that this is [0, -1] on init and must be changed when we
       determine the actual corpus size later on */
    New(cl->range, Range);
    cl->range[0].start = 0;
    cl->range[0].end   = attr_size - 1;
    
    cl->sortidx = NULL;
    cl->targets = NULL;
    cl->keywords = NULL;
    cl->next = NULL;
    return cl;
  }

  return NULL;
}

/* ------------------------------------------------------------ */

CorpusList *
ensure_syscorpus(char *registry, char *name)
{
  CorpusList *cl;

  if ((cl = LoadedCorpus(name, registry, SYSTEM)) == NULL) {

    /* the system corpus is not yet loaded. Try to get it. */
    /* (of course this shouldn't happen anyway since CQP reads in all
       available system corpora at startup) */
    
    cl = GetSystemCorpus(name, registry);

    if (cl == NULL)
      return NULL;
    else {
      cl->next = corpuslist;
      corpuslist = cl;
    }
  }

  /* now <cl> contains a valid corpus handle */
  /* If the size of the system corpus hasn't been determined yet,
     do it now. If we can't return failure. */
  if (!ensure_corpus_size(cl))
    return NULL;

  /* At this point, the corpus *cl has been fully set up. */
  return cl;
}



static Boolean
attach_subcorpus(CorpusList *cl,
                 char *advertised_directory,
                 char *advertised_filename)
{
  int         j, len;
  char       *fullname;
  FILE       *fp;

  char        *field;
  char        *p;

  Boolean load_ok;
  

  load_ok = False;

  if ((cl != NULL) && ((cl->type == SUB) || (cl->type == TEMP))) {

    initialize_cl(cl, False);

    if (advertised_directory && advertised_filename) {

      char sname[1024];
      
      strcpy(sname, advertised_directory);
      if (sname[strlen(sname)-1] != '/')
        strcat(sname, "/");
      strcat(sname, advertised_filename);

      fullname = cl_strdup(sname);
    }
    else
      fullname = get_fulllocalpath(cl, 0);

    if ((fp = OpenFile(fullname, "r")) == NULL && !advertised_filename) {
      cl_free(fullname);
      fullname = get_fulllocalpath(cl, 1);
      fp = OpenFile(fullname, "r");
    }

    if (fp == NULL)
      fprintf(stderr, "Subcorpus %s not accessible (can't open %s for reading)\n",
              cl->name, fullname);
    else {
      len = file_length(fullname);

      if (len <= 0)
        fprintf(stderr, "ERROR: File length of subcorpus is <= 0\n");
      else {


        /* the subcorpus is treated as a byte array */
        field = (char *)cl_malloc(len);
        
        /* read the subcorpus */
        
        if (len != fread(field, 1, len, fp))
          fprintf(stderr, "Read error while reading subcorpus %s\n", cl->name);
        else if ((*((int *)field) != SUBCORPMAGIC) && (*((int *)field) != SUBCORPMAGIC+1))
          fprintf(stderr, "Magic number incorrect in %s\n", fullname);
        else {

          CorpusList *mother;
          int magic;

          magic = *((int *)field);

          p = ((char *)field) + sizeof(int);
          
          cl->registry = cl_strdup((char *)p);

          cl->abs_fn = fullname;
          fullname = NULL;
          
          while (*p)
            p++;
          /* skip the '\0' character */
          p++;
          
          cl->mother_name = cl_strdup((char *)p);
          
          mother = ensure_syscorpus(cl->registry, cl->mother_name);

          if (mother == NULL || mother->corpus == NULL)
            cqpmessage(Warning, "When trying to load subcorpus %s:\n\t"
                       "Can't access mother corpus %s",
                       cl->name, cl->mother_name);
          else {

            cl->corpus = mother->corpus;
            cl->mother_size = mother->mother_size;

            assert(cl->mother_size > 0);

            /* advance p to the end of the 2nd string */
            while (*p)
              p++;
            /* skip the '\0' character */
            p++;
            
            /* the length is divisible by 4 -- 
             * advance p over the additional '\0' characters */

            while ((p - field) % 4)
              p++;
          
            if (magic == SUBCORPMAGIC) {

              cl->size = (len - (p - field)) / (2 * sizeof(int));
            
              /* the integer starts at the current offset */
              cl->range = (Range *)cl_malloc(sizeof(Range) * cl->size);
              memcpy(cl->range, p, sizeof(Range) * cl->size);
            
              cl->sortidx = NULL;
              cl->keywords = NULL;
              cl->targets = NULL;
            }
            else if (magic == (SUBCORPMAGIC + 1)) {
              
              int compsize;

              memcpy(&(cl->size), p, sizeof(int));
              p += sizeof(int);

              if (cl->size > 0) {

                cl->range = (Range *)cl_malloc(sizeof(Range) * cl->size);
                memcpy(cl->range, p, sizeof(Range) * cl->size);
                
                p += sizeof(Range) * cl->size;

                memcpy(&compsize, p, sizeof(int));
                p += sizeof(int);

                if (compsize > 0) {
                  cl->sortidx = (int *)cl_malloc(sizeof(int) * cl->size);
                  memcpy(cl->sortidx, p, sizeof(int) * cl->size);
                  p += sizeof(int) * cl->size;
                }
                
                memcpy(&compsize, p, sizeof(int));
                p += sizeof(int);
                if (compsize > 0) {
                  cl->targets = (int *)cl_malloc(sizeof(int) * cl->size);
                  memcpy(cl->targets, p, sizeof(int) * cl->size);
                  p += sizeof(int) * cl->size;
                }
                
                memcpy(&compsize, p, sizeof(int));
                p += sizeof(int);

                if (compsize > 0) {
                  cl->keywords = (int *)cl_malloc(sizeof(int) * cl->size);
                  memcpy(cl->keywords, p, sizeof(int) * cl->size);
                  p += sizeof(int) * cl->size;
                }
              }
              
            }
            else {
              assert(0 && "Can't be");
            }

            if (subcorpload_debug) {
              fprintf(stderr,
                      "Header size: %ld\n"
                      "Nr Matches: %d\n"
                      "regdir: %s\n"
                      "regname: %s\n", 
                      (long int)(p - field),
                      cl->size,
                      cl->registry,
                      cl->mother_name);
              for (j = 0; j < cl->size; j++)
                fprintf(stderr, 
                        "range[%d].start = %d\n"
                        "range[%d].end   = %d\n",
                        j, cl->range[j].start, j, cl->range[j].end);
            }
            
            free(field);
            p = NULL;
            field = NULL;
            
            cl->type = SUB;
            cl->saved = True;
            cl->loaded = True;
            cl->needs_update = False;
            load_ok = True;
          }
        }
        fclose(fp);
      }
    }
    cl_free(fullname);
  }

  if (load_ok == False) {
    if (cl != NULL)
      dropcorpus(cl);
  }
  return load_ok;
}

Boolean
save_subcorpus(CorpusList *cl, char *fname)
{
  int i, l1, l2, magic;

  FILE *fp;
  char outfn[1024];

  if (cl == NULL)
    return False;
  else if (cl->loaded == False) 
    return False;
  else if (cl->type != SUB)
    return False;
  else if ((cl->needs_update == False) || (cl->saved == True))
    return True;                /* save is ok, although we did not do anything */
  else {

    if (fname == NULL) {

      if (cl->abs_fn)
        fname = cl->abs_fn;
      else {
        if (LOCAL_CORP_PATH == NULL) {
          cqpmessage(Warning,
                     "Directory for private subcorpora isn't set, can't save %s",
                     cl->name);
          return False;
        }

        sprintf(outfn, "%s/%s:%s", 
                LOCAL_CORP_PATH, 
                cl->mother_name ? cl->mother_name : "NONE",
                cl->name);

        fname = outfn;
      }
    }

    if ((fp = OpenFile(fname, "w")) != NULL) {

      int zero; 
      zero = 0;

      magic = SUBCORPMAGIC + 1; /* new format -- Mon Jul 31 17:19:27 1995 (oli) */

      fwrite(&magic, sizeof(int), 1, fp);

      l1 = fwrite(cl->registry, 1, strlen(cl->registry) + 1, fp);
      l2 = fwrite(cl->mother_name, 1, strlen(cl->mother_name) + 1, fp);

      /* fill up */
      for (i = 0; (i+l1+l2)%4 != 0; i++)
        fputc('\0', fp);
      
      /* write the size (the number of ranges) */

      fwrite(&cl->size, sizeof(int), 1, fp); /* new Mon Jul 31 17:24:47 1995 (oli) */

      if (cl->size > 0) {

        fwrite((char *)cl->range, sizeof(Range), cl->size, fp);

        /* write the sort index  new Mon Jul 31 17:24:52 1995 (oli) */

        if (cl->sortidx) {
          fwrite(&cl->size, sizeof(int), 1, fp); /* new Mon Jul 31 17:24:47 1995 (oli) */
          fwrite((char *)cl->sortidx, sizeof(int), cl->size, fp);
        }
        else
          fwrite(&zero, sizeof(int), 1, fp); /* new Mon Jul 31 17:24:47 1995 (oli) */

        
        /* write the targets new Mon Jul 31 17:24:59 1995 (oli) */
        
        if (cl->targets) {
          fwrite(&cl->size, sizeof(int), 1, fp); /* new Mon Jul 31 17:24:47 1995 (oli) */
          fwrite((char *)cl->targets, sizeof(int), cl->size, fp);
        }
        else
          fwrite(&zero, sizeof(int), 1, fp); /* new Mon Jul 31 17:24:47 1995 (oli) */

        
        /* write the keywords new Mon Jul 31 17:25:02 1995 (oli) */

        
        if (cl->keywords) {
          fwrite(&cl->size, sizeof(int), 1, fp); /* new Mon Jul 31 17:24:47 1995 (oli) */
          fwrite((char *)cl->keywords, sizeof(int), cl->size, fp);
        }
        else
          fwrite(&zero, sizeof(int), 1, fp); /* new Mon Jul 31 17:24:47 1995 (oli) */


      }


      fclose(fp);
      
      cl->saved = True;
      cl->needs_update = False;
      
      return(True);
    }
    else {
      fprintf(stderr, "cannot open output file %s\n", fname);
      return(False);
    }
  }
}

void
save_unsaved_subcorpora()
{
  CorpusList *cl;
  
  for (cl = corpuslist; cl; cl = cl->next)
    if ((cl->type == SUB) && (cl->saved == False)) {
      if (LOCAL_CORP_PATH == NULL) {
        cqpmessage(Warning,
                   "Can't save unsaved subcorpora, directory is not set");
        return;
      }
      save_subcorpus(cl, NULL);
    }
}



/**
 * Gets the CorpusList pointer for the first corpus on the currently-loaded list.
 *
 * Function for iterating through the list of currently-loaded corpora.
 *
 * @return  The requested CorpusList pointer.
 */
CorpusList *
FirstCorpusFromList()
{
  return corpuslist;
}

/**
 * Gets the CorpusList pointer for the next corpus on the currently-loaded list.
 *
 * Function for iterating through the list of currently-loaded corpora.
 *
 * @param cl  The current corpus on the list.
 * @return  The requested CorpusList pointer.
 */
CorpusList *
NextCorpusFromList(CorpusList *cl)
{
  return (cl ? cl->next : NULL);
}


Boolean
access_corpus(CorpusList *cl)
{
  if (!cl)
    return False;
  else if (cl->loaded) {
    /* do we have range data? */
    assert((cl->size == 0) || (cl->range != NULL));
    return True;                /* already loaded, do nothing */
  }
  else if (cl->saved) { /* on disk */
    switch(cl->type) {
    case SUB:
    case TEMP:
      return attach_subcorpus(cl, NULL, NULL);
      break;
    case SYSTEM:
      assert(0);
      return True;
      break;
    default:
      return(False);
    }
  }
  assert(0 && "Not reached");
  return False;
}


/* implements the search strategy for corpora */

CorpusList *
search_corpus(char *name)
{
  CorpusList *cl;

  cl = findcorpus(name, SUB, 0);
  if (cl == NULL)
    cl = findcorpus(name, SYSTEM, 0);
  
  return cl;
}

/* change_corpus takes as argument a corpus name and makes 
 * the corpus accessible
 */

Boolean
change_corpus(char *name, Boolean silent)
{
  CorpusList *cl;

  if ((cl = search_corpus(name)) != NULL) {
    if (!access_corpus(cl)) {
      fprintf(stderr, "Can't access corpus %s, keep previous corpus\n",
              cl->name);
      cl = NULL;
    }
  }

  if (cl != NULL) {
    set_current_corpus(cl, 0);
    return True;
  }
  else
    return False;
}

Boolean
valid_subcorpus_id(char *corpusname) {
  return (findcorpus(corpusname, SYSTEM, 0) ? False : True);
}

Boolean
valid_subcorpus_name(char *corpusname) {
  return ((split_subcorpus_name == NULL) ? False : True);
}

Boolean
is_qualified(char *corpusname) {
  return (strchr(corpusname, COLON) == NULL ? 0 : 1);
}


/**
 * Splits a query result corpus-name into qualifier and local name.
 *
 * This function splits query result name {corpusname} into qualifier (name of mother corpus) and local name;
 * returns pointer to local name part, or NULL if {corpusname} is not syntactically valid;
 * if mother_name is not NULL, it must point to a buffer of suitable length (MAX_LINE_LENGTH is sufficient)
 * where the qualifier will be stored (empty string for unqualified corpus, and return value == {corpusname} in this case)
 */
char *
split_subcorpus_name(char *corpusname, char *mother_name)
{
  char *mark;
  int i, after_colon;

  if (! (isalnum(corpusname[0]) 
         || (corpusname[0] == '_')
         || (corpusname[0] == '-')
         || (corpusname[0] == '.')) )
    return NULL;
    
  mark = corpusname;
  if (mother_name)
    mother_name[0] = '\0';
  after_colon = 0;
  for (i = 1; corpusname[i]; i++) {
    if (corpusname[i] == COLON) {
      if (after_colon)          /* only one ':' separator is allowed */
        return NULL;
      if (mother_name) {        /* characters 0 .. i-1 give name of mother corpus */
        strncpy(mother_name, corpusname, i);
        mother_name[i] = '\0';
      }
      mark = corpusname + (i+1); /* local name starts from character i+1 */
      after_colon = 1;
    }
    else if (! (isalnum(corpusname[0]) 
                || (corpusname[0] == '_')
                || (corpusname[0] == '-')
                || (corpusname[0] == '^') /* should also check that there is only one implicit expansion at the end */
                || (corpusname[0] == '.')) )
      return NULL;
  }

  return mark;                  /* return pointer to local name */
}



/**
 * Touches a corpus, ie, marks it as changed.
 *
 * @param cp  The corpus to touch. This must be of type SUB.
 * @return    Boolean: true if the touch worked, otherwise false.
 */
Boolean
touch_corpus(CorpusList *cp)
{
  if ((!cp) ||
      (cp->type != SUB))
    return False;
  else {
    cp->saved = False;
    cp->needs_update = True;

    return 1;
  }
}


/**
 * Sets the current corpus (by pointer to the corpus).
 *
 * Also, execustes Xkwic side effects, if necessary
 *
 * @param cp     Pointer to the corpus to set as current.
 *               cp may be NULL, which is legal.
 * @param force  If true, the current corpus is set to the specified
 *               corpus, even if it is ALREADY set to that corpus.
 * @return       Always 1.
 */
int 
set_current_corpus(CorpusList *cp, int force)
{
  if (cp != current_corpus || force) {
    current_corpus = cp;

    if (cp) {
      AttributeInfo *ai;
      int nr_selected_attributes = 0;

      update_context_descriptor(cp->corpus, &CD);

      /* if no p-attributes are selected for output, try to switch on the default attribute */
      for (ai = CD.attributes->list; ai; ai = ai->next) 
        if (ai->status > 0)
          nr_selected_attributes++;
      if (nr_selected_attributes == 0) {
        if ((ai = FindInAL(CD.attributes, DEFAULT_ATT_NAME)) != NULL)
          ai->status = 1;
      }
    }
    else {
      DestroyAttributeList(&(CD.attributes));
      DestroyAttributeList(&(CD.strucAttributes));
    }

  }
  return 1;
}


/**
 * Sets the current corpus (by name).
 *
 * Also, execustes Xkwic side effects, if necessary.
 *
 * @param name   Name of the corpus to set as current.
 * @param force  If true, the current corpus is set to the specified
 *               corpus, even if it is ALREADY set to that corpus.
 * @return       True if the corpus was found and set, otherwise
 *               false if the corpus could not be found.
 */
int
set_current_corpus_name(char *name, int force)
{
  CorpusList *cp;
  
  if ((cp = findcorpus(name, UNDEF, 1)) == NULL)
    return 0;
  else
    return set_current_corpus(cp, force);
}


/**
 * Internal function for sorting list of corpus names.
 */
static int
show_corpora_files_sort(const void *p1, const void *p2)
{
  char *name1 = *((char **) p1);
  char *name2 = *((char **) p2);
  int result = strcmp(name1, name2);
  return result;
}

void 
show_corpora_files1(enum corpus_type ct)
{
  CorpusList *cl;
  char **list;                  /* list of corpus names */
  int i, N;
  char initial = ' ';           /* inital character of corpus name (insert <br> before new initial letter) */
  char label[4];

  if (ct == SYSTEM) {
    if (pretty_print) printf("System corpora:\n");
    /* make list of corpus names, then qsort() and print */
    N = 0;                      /* count nr of system corpora before allocating list */
    for (cl = corpuslist; cl; cl = cl->next) 
      if (cl->type == SYSTEM)  N++;
    list = (char **) cl_malloc(N * sizeof(char *)); /* allocate list */
    for (cl = corpuslist, i = 0; cl; cl = cl->next) /* compile list of corpus names */
      if (cl->type == SYSTEM)  list[i++] = cl->name;
    qsort(list, N, sizeof(char *), show_corpora_files_sort);

    if (pretty_print) 
      start_indented_list(0,0,0);       /* now print sorted list */
    for (i = 0; i < N; i++) {
      if (pretty_print) {
        if (list[i][0] != initial) {
          initial = list[i][0];
          sprintf(label, " %c:", initial);
          print_indented_list_br(label);
        }
        print_indented_list_item(list[i]);
      }
      else {
        printf("%s\n", list[i]);
      }
    }
    if (pretty_print)
      end_indented_list();

    free(list);
  }
  else if (ct == SUB) {
    if (pretty_print) printf("Named Query Results:\n");
    for (cl = corpuslist; cl; cl = cl->next)
      if (cl->type == SUB) {
        if (pretty_print) {
          printf("   %c%c%c  %s:%s [%d]\n", 
                 cl->loaded ? 'm' : '-',
                 cl->saved ? 'd' : '-',
                 cl->needs_update ? '*' : '-',
                 cl->mother_name ? cl->mother_name : "???",
                 cl->name, cl->size);
        }
        else {
          printf("%c%c%c\t%s:%s\t%d\n", 
                 cl->loaded ? 'm' : '-',
                 cl->saved ? 'd' : '-',
                 cl->needs_update ? '*' : '-',
                 cl->mother_name ? cl->mother_name : "???",
                 cl->name, cl->size);
        }
      }
  }
  else {
    assert(0 && "Invalid argument in show_corpora_files()<corpmanag.c>.");
  }
}

void 
show_corpora_files(enum corpus_type ct)
{
  if (ct == UNDEF) {
    show_corpora_files1(SYSTEM);
    show_corpora_files1(SUB);
  }
  else
    show_corpora_files1(ct);
}



/* NEW FUNCTIONS ================================================== */

/*
 * TODO  (??)
 *
 * None of these functions is used anywhere.
 * Their names are not noticeably better than the original names!
 * Also, they are a deeply inefficient way of rewriting the API; all those unnecessary function calls!
 * Can they be got rid of? -- and maybe rewrite the API the way SE did it in the CL instead -- AH. 26.9.09
 */


/* ============================== THE LIST OF CORPORA */

void
CorpusListInit(void)
{
  init_corpuslist();
}

void CorpusListFree(void)
{
  free_corpuslist();
}

/* ============================== CORPUS NAMES */

Boolean
CorpusNameValid(char *name) {
  return valid_subcorpus_id(name);
}

Boolean
CorpusNameQualified(char *name) {
  return is_qualified(name);
}

/* ============================== OPERATIONS ON/WITH CORPORA */

void
CorpusLoadDescriptors(CorpusType ct)
{
  check_available_corpora(ct);
}

Boolean CorpusDiscard(CorpusList *cl,
                      Boolean remove_file_also, 
                      Boolean save_if_unsaved)
{
  dropcorpus(cl);

  return True;
}

Boolean CorpusSave(CorpusList *cl, char *file_name)
{
  return save_subcorpus(cl, file_name);
}

Boolean CorpusSaveAll(void)
{
  save_unsaved_subcorpora();
  return True;
}

Boolean CorpusDiscardTMPCorpora(void)
{
  drop_temp_corpora();

  return True;
}

CorpusList *CorpusDuplicate(CorpusList *cl,
                            char *new_name,
                            Boolean force_overwrite)
{
  return duplicate_corpus(cl, new_name, force_overwrite);
}

CorpusList *CorpusDuplicateIntoTMP(CorpusList *cl,
                                   char *new_name)
{
  return make_temp_corpus(cl, new_name);
}

CorpusList *CorpusChangeTMPtoSUB(CorpusList *tmp, char *subname)
{
  return assign_temp_to_sub(tmp, subname);
}

Boolean CorpusLoad(CorpusList *cl)
{
  return access_corpus(cl);
}

Boolean CorpusSetCurrentByname(char *name)
{
  return set_current_corpus_name(name, 0);
}

Boolean CorpusSetCurrent(CorpusList *cl)
{
  return set_current_corpus(cl, 0);
}

Boolean CorpusTouch(CorpusList *cl)
{
  return touch_corpus(cl);
}

void CorpusShowNames(CorpusType ct)
{
  show_corpora_files(ct);
}

