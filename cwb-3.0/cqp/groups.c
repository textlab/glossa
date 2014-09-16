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

#include "../cl/globals.h"
#include <math.h>
/* apparently we don't need to include <search.h> for tfind() etc. and it doesn't */
/* exist in Gnuwin32, so we'll just leave it out */
/* #include <search.h> */

#include "../cl/attributes.h"
#include "../cl/cdaccess.h"
#include "../cl/macros.h"

#include "../cl/binsert.h"

#include "options.h"
#include "html-print.h"
#include "ascii-print.h"
#include "sgml-print.h"
#include "latex-print.h"

#include "corpmanag.h"
#include "groups.h"
#include "output.h"

#include "html-print.h"

#define SEPARATOR  "#---------------------------------------------------------------------\n"
#define SEPARATOR2 "#=====================================================================\n"


#define GROUP_DEBUG 0

#define ANY_ID -2

/* ---------------------------------------------------------------------- */

static
int compare_by_freq(const void *p1, const void *p2)
{
  return ((ID_Count_Mapping *)p2)->freq - ((ID_Count_Mapping *)p1)->freq;
} 

int
sum_freqs(ID_Count_Mapping *buffer, int bufsize, int cutoff_f)
{
  int i, insp;

  insp = 0; 
  i = 0;

  if (progress_bar) 
    progress_bar_message(2, 2, " cutoff freq.");

  for (i = 0; i < bufsize; i++) {
    if (buffer[i].freq >= cutoff_f) {
      buffer[insp].s = buffer[i].s;
      buffer[insp].t = buffer[i].t;
      buffer[insp].freq = buffer[i].freq;
      insp++;
    }
  }

  if (progress_bar) 
    progress_bar_message(2, 2, " sorting rslt");

  qsort(buffer, insp, sizeof(ID_Count_Mapping), compare_by_freq);

  if (progress_bar) 
    progress_bar_percentage(2, 2, 100); /* so total percentage runs up to 100% */

  return insp;
}

static
int compare_st_cells(const void *p1, const void *p2)
{
  int r;
  r = ((ID_Count_Mapping *)p2)->s - ((ID_Count_Mapping *)p1)->s;
  if (r == 0) 
    r = ((ID_Count_Mapping *)p2)->t - ((ID_Count_Mapping *)p1)->t;
  return r;
}

int
get_group_id(Group *group, int i, int target) {
  CorpusList *cl = group->my_corpus;
  int field_type = (target) ? group->target_field : group->source_field;
  int offset = (target) ? group->target_offset : group->source_offset;
  Attribute *attr = (target) ? group->target_attribute : group->source_attribute;
  int is_struc = (target) ? group->target_is_struc : group->source_is_struc;
  char *base = (target) ? group->target_base : group->source_base;
  int pos, id;
  
  switch (field_type) {
  case KeywordField:
    pos = cl->keywords[i];
    break;
  case TargetField:
    pos = cl->targets[i];
    break;
  case MatchField:
    pos = cl->range[i].start;
    break;
  case MatchEndField:
    pos = cl->range[i].end;
    break;
  case NoField:
    pos = ANY_ID;
    break;
  default:
    assert(0 && "Can't be");
    break;
  }
  if (pos >= 0)
    pos += offset;
  if (pos < 0) 
    id = -1;
  else {
    if (is_struc) {
      char *str = cl_cpos2struc2str(attr, pos);
      if (str) 
        id = str - base;
      else
        id = -1;
    }
    else {
      id = cl_cpos2id(attr, pos);
    }
  }
  return id;
}

char *
Group_id2str(Group *group, int id, int target) {
  Attribute *attr = (target) ? group->target_attribute : group->source_attribute;
  int is_struc = (target) ? group->target_is_struc : group->source_is_struc;
  char *base = (target) ? group->target_base : group->source_base;
  if (id == ANY_ID) 
    return "(all)";
  else if (id < 0)
    return "(none)";
  else if (is_struc) 
    return base+id;             /* keep fingers crossed ... */
  else 
    return cl_id2str(attr, id);
}

Group *
ComputeGroupInternally(Group *group)
{
  ID_Count_Mapping node;
  ID_Count_Mapping *result;

  int i;
  size_t nr_nodes;
  int percentage, new_percentage; /* for ProgressBar */
  int size = group->my_corpus->size;

  /* ---------------------------------------------------------------------- */

  nr_nodes = 0;
  
  if (progress_bar)
    progress_bar_clear_line();
  percentage = -1;

  EvaluationIsRunning = 1;

  for (i = 0; i < size; i++) {
    if (! EvaluationIsRunning)
      break;                    /* user abort (Ctrl-C) */

    if (progress_bar) {
      new_percentage = floor(0.5 + (100.0 * i) / size);
      if (new_percentage > percentage) {
        percentage = new_percentage;
        progress_bar_percentage(1, 2, percentage);
      }
    }

    node.s = get_group_id(group, i, 0);       /* source ID */
    node.t = get_group_id(group, i, 1);       /* target ID */
    node.freq = 0;
  
    result = binsert_g(&node,
                       (void **) &(group->count_cells),
                       &nr_nodes,
                       sizeof(ID_Count_Mapping),
                       compare_st_cells);

    result->freq++;
  }

  if (EvaluationIsRunning) {
    group->nr_cells = sum_freqs(group->count_cells, nr_nodes, group->cutoff_frequency);
    
    if (progress_bar)
      progress_bar_clear_line();
    
    if (group->nr_cells < nr_nodes)
      group->count_cells = 
        cl_realloc(group->count_cells, (group->nr_cells * sizeof(ID_Count_Mapping)));
  }
  else {
    cqpmessage(Warning, "Group operation aborted by user.");
    if (which_app == cqp) install_signal_handler();
    free_group(&group);         /* sets return value to NULL to indicate failure */
  }
  EvaluationIsRunning = 0;
    
  return group;
}


Group *
ComputeGroupExternally(Group *group)
{
  int i;
  int size = group->my_corpus->size;
  int cutoff_freq = group->cutoff_frequency;

  char temporary_name[32];
  FILE *fd;
  FILE *pipe;
  char sort_call[1024];

  /* ---------------------------------------------------------------------- */

  if ((fd = OpenTemporaryFile(temporary_name)) == NULL) {
    perror("Error while opening temporary file");
    cqpmessage(Warning, "Can't open temporary file");
    return group;
  }

  for (i = 0; i < size; i++) {
    fprintf(fd, "%d %d\n", get_group_id(group, i, 0), get_group_id(group, i, 1)); /* (source ID, target ID) */
  }
  fclose(fd);

  /* construct sort call */
  sprintf(sort_call, ExternalGroupingCommand, temporary_name);
  if (GROUP_DEBUG)
    fprintf(stderr, "Running grouping sort: \n\t%s\n",
            sort_call);
  if ((pipe = popen(sort_call, "r")) == NULL) {
    perror("Failure opening grouping pipe");
    cqpmessage(Warning, "Can't open grouping pipe:\n%s\n"
               "Disable external grouping by\n"
               "  set UseExternalGrouping off;", 
               sort_call);
  }
  else {
    int freq, p1, p2, tokens;
#define GROUP_REALLOC 16

    while ((tokens = fscanf(pipe, "%d%d%d", &freq, &p1, &p2)) == 3) {
      if (freq > cutoff_freq) {
        if ((group->nr_cells % GROUP_REALLOC) == 0) {
          if (group->count_cells == NULL) {
            group->count_cells = 
              (ID_Count_Mapping *)cl_malloc(GROUP_REALLOC *
                                         sizeof(ID_Count_Mapping));
          }
          else {
            group->count_cells = 
              (ID_Count_Mapping *)cl_realloc(group->count_cells,
                                          (group->nr_cells + GROUP_REALLOC) *
                                          sizeof(ID_Count_Mapping));
          }
          assert(group->count_cells);
        }

        group->count_cells[group->nr_cells].s = p1;
        group->count_cells[group->nr_cells].t = p2;
        group->count_cells[group->nr_cells].freq = freq;

        group->nr_cells = group->nr_cells + 1;
      }
    }

    if (tokens != EOF) {
      fprintf(stderr, "Warning: could not reach EOF of temporary file!\n");
    }

    pclose(pipe);
  }

  if (GROUP_DEBUG) {
    fprintf(stderr, "Keeping temporary file %s -- delete manually\n",
            temporary_name);
  }
  else if (unlink(temporary_name) != 0) {
    perror(temporary_name);
    fprintf(stderr, "Can't remove temporary file %s -- \n\t"
            "I will continue, but you should remove that file.\n",
            temporary_name);
  }
  
  return group;
}


Group *compute_grouping(CorpusList *cl,
                        FieldType source_field,
                        int source_offset,
                        char *source_attr_name,
                        FieldType target_field,
                        int target_offset,
                        char *target_attr_name,
                        int cutoff_freq)
{
  Group *group;
  Attribute *source_attr, *target_attr;
  int source_is_struc = 0, target_is_struc = 0;
  char *source_base = NULL, *target_base = 0;

  if ((cl == NULL) || (cl->corpus == NULL)) {
    cqpmessage(Warning, "Grouping:\nCan't access corpus.");
    return NULL;
  }

  if ((cl->size == 0) || (cl->range == NULL)) {
    cqpmessage(Warning, "Corpus %s is empty, no grouping possible",
               cl->name);
    return NULL;
  }

  if ((source_attr_name == NULL) && (source_field == NoField)) {
    source_attr = NULL;
  }
  else {
    source_attr = find_attribute(cl->corpus, source_attr_name, ATT_POS, NULL);
    if (source_attr == NULL) {
      source_attr = find_attribute(cl->corpus, source_attr_name, ATT_STRUC, NULL);
      source_is_struc = 1;
    }
    if (source_attr == NULL) {
      cqpmessage(Error, "Can't find attribute ``%s'' for named query %s",
                 source_attr_name, cl->name);
      return NULL;
    }
    if (source_is_struc) {
      if (cl_struc_values(source_attr)) {
        source_base = cl_struc2str(source_attr, 0); /* should be beginning of the attribute's lexicon */
        assert(source_base && "Internal error. Please don't use s-attributes in group command.");
      }
      else {
        cqpmessage(Error, "No annotated values for s-attribute ``%s'' in named query %s",
                   source_attr_name, cl->name);
        return NULL;
      }
    }

    switch (source_field) {
    case KeywordField:
      if (cl->keywords == NULL) {
        cqpmessage(Error, "No keyword anchors defined for %s", cl->name);
        return NULL;
      }
      break;
      
    case TargetField:
      if (cl->targets == NULL) {
        cqpmessage(Error, "No target anchors defined for %s", cl->name);
        return NULL;
      }
      break;
      
    case MatchField:
    case MatchEndField:
      assert(cl->range && cl->size > 0);
      break;
      
    case NoField:
    default:
      cqpmessage(Error, "Illegal second anchor in group command");
      return NULL;
      break;
    }
  }

  target_attr = find_attribute(cl->corpus, target_attr_name, ATT_POS, NULL);
  if (target_attr == NULL) {
      target_attr = find_attribute(cl->corpus, target_attr_name, ATT_STRUC, NULL);
      target_is_struc = 1;
  }
  if (target_attr == NULL) {
    cqpmessage(Error, "Can't find attribute ``%s'' for named query %s",
               target_attr_name, cl->name);
    return NULL;
  }
  if (target_is_struc) {
    if (cl_struc_values(target_attr)) {
      target_base = cl_struc2str(target_attr, 0); /* should be beginning of the attribute's lexicon */
      assert(target_base && "Internal error. Please don't use s-attributes in group command.");
    }
    else {
      cqpmessage(Error, "No annotated values for s-attribute ``%s'' in named query %s",
                 target_attr_name, cl->name);
      return NULL;
    }
  }

  switch (target_field) {
  case KeywordField:
    if (cl->keywords == NULL) {
      cqpmessage(Error, "No keyword anchors defined for %s", cl->name);
      return NULL;
    }
    break;
    
  case TargetField:
    if (cl->targets == NULL) {
      cqpmessage(Error, "No target anchors defined for %s", cl->name);
      return NULL;
    }
    break;
    
  case MatchField:
  case MatchEndField:
    assert(cl->range && cl->size > 0);
    break;
    
  case NoField:
  default:
    cqpmessage(Error, "Illegal anchor in group command");
    return NULL;
    break;
  }

  /* set up Group object */
  group = (Group *) cl_malloc(sizeof(Group));
  group->my_corpus = cl;
  group->source_attribute = source_attr;
  group->source_offset = source_offset;
  group->source_is_struc = source_is_struc;
  group->source_base = source_base;
  group->source_field = source_field;
  group->target_attribute = target_attr;
  group->target_offset = target_offset;
  group->target_is_struc = target_is_struc;
  group->target_base = target_base;
  group->target_field = target_field;
  group->nr_cells = 0;
  group->count_cells = NULL;
  group->cutoff_frequency = cutoff_freq;

  if (UseExternalGrouping && !insecure && !(source_is_struc || target_is_struc))
    return ComputeGroupExternally(group); /* modifies Group object in place and returns pointer or NULL */
  else
    return ComputeGroupInternally(group);
}

void free_group(Group **group)
{
  cl_free((*group)->count_cells);
  (*group)->my_corpus = NULL;
  (*group)->nr_cells = 0;
  (*group)->source_attribute = NULL;
  (*group)->target_attribute = NULL;

  free(*group);
  *group = NULL;
}

void print_group(Group *group, int expand, struct Redir *rd)
{
  if (group && open_stream(rd, group->my_corpus->corpus->charset)) {

    switch (GlobalPrintMode) {
    
    case PrintSGML:
      sgml_print_group(group, expand, rd->stream);
      break;
      
    case PrintHTML:
      html_print_group(group, expand, rd->stream);
      break;
      
    case PrintLATEX:
      latex_print_group(group, expand, rd->stream);
      break;
      
    case PrintASCII:
      ascii_print_group(group, expand, rd->stream);
      break;
    
    default:
      cqpmessage(Error, "Unknown print mode");
      break;
    }

    close_stream(rd);
    
  }
}


