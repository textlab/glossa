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

#include "../cl/corpus.h"
#include "../cl/attributes.h"
#include "../cl/cdaccess.h"
#include "../cl/macros.h"

#include "context_descriptor.h"
#include "output.h"
#include "options.h"

#define RESET_LEFT_CONTEXT \
    cd->left_width = 25; \
    cd->left_type = CHAR_CONTEXT; \
    if (cd->left_structure_name) { \
      free(cd->left_structure_name); \
      cd->left_structure_name = NULL; \
    } \
    cd->left_structure = NULL

#define RESET_RIGHT_CONTEXT \
    cd->right_width = 25; \
    cd->right_type = CHAR_CONTEXT; \
    if (cd->right_structure_name) { \
      free(cd->right_structure_name); \
      cd->right_structure_name = NULL; \
    } \
    cd->right_structure = NULL


int verify_context_descriptor(Corpus *corpus, 
			      ContextDescriptor *cd,
			      int remove_illegal_entries)
{
  int result;

  result = 1;

  if (cd == NULL) {

    fprintf(stderr,
	    "concordance.o/verify_context_descriptor: WARNING: Context Descriptor empty!\n");

    result = 0;
  }
  else if (corpus == NULL) {

    fprintf(stderr,
	    "concordance.o/verify_context_descriptor: WARNING: Corpus Descriptor empty!\n");

    RESET_LEFT_CONTEXT;
    RESET_RIGHT_CONTEXT;

    cd->attributes = NULL;

    result = 0;

  }
  else {

    /* check left attribute */
    if (cd->left_type == STRUC_CONTEXT) {
      if (cd->left_structure_name == NULL) {
	RESET_LEFT_CONTEXT;
	result = 0;
      }
      else {
	/* find (structural) attribute */
	if ((cd->left_structure = find_attribute(corpus, 
						 cd->left_structure_name, 
						 ATT_STRUC, NULL))
	    == NULL) {
	  /* not defined -> try alignment attribute */
	  if ((cd->left_structure = find_attribute(corpus, 
						   cd->left_structure_name, 
						   ATT_ALIGN, NULL))
	      == NULL) {
	    RESET_LEFT_CONTEXT;	/* error -> reset to default context */
	    result = 0;
	  }
	  else {
	    /* alignment attribute found -> change context type to ALIGN_CONTEXT */
	    cd->left_type = ALIGN_CONTEXT;
	    if (cd->left_width != 1) {
	      cqpmessage(Warning, 
			 "Left Context '%d %s' changed to '1 %s' (alignment attribute).", 
			 cd->left_width,
			 cd->left_structure_name,
			 cd->left_structure_name);
	      cd->left_width = 1;
	    }
	  }
	}
      }
    }
    if (cd->left_width < 0) {
      fprintf(stderr,
	      "concordance.o/verify_context_descriptor: WARNING: lwidth < 0\n");
      cd->left_width = -cd->left_width;
      result = 0;
    }

    /* check right attribute */
    if (cd->right_type == STRUC_CONTEXT) {
      if (cd->right_structure_name == NULL) {
	RESET_RIGHT_CONTEXT;
	result = 0;
      }
      else {
	/* find (structural) attribute */
	if ((cd->right_structure = find_attribute(corpus, 
						 cd->right_structure_name, 
						 ATT_STRUC, NULL))
	    == NULL) {
	  /* not defined -> try alignment attribute */
	  if ((cd->right_structure = find_attribute(corpus, 
						   cd->right_structure_name, 
						   ATT_ALIGN, NULL))
	      == NULL) {
	    RESET_RIGHT_CONTEXT;	/* error -> reset to default context */
	    result = 0;
	  }
	  else {
	    /* alignment attribute found -> change context type to ALIGN_CONTEXT */
	    cd->right_type = ALIGN_CONTEXT;
	    if (cd->right_width != 1) {
	      cqpmessage(Warning, 
			 "Right Context '%d %s' changed to '1 %s' (alignment attribute).", 
			 cd->right_width,
			 cd->right_structure_name,
			 cd->right_structure_name);
	      cd->right_width = 1;
	    }
	  }
	}
      }
    }
    if (cd->right_width < 0) {
      fprintf(stderr,
	      "concordance.o/verify_context_descriptor: WARNING: lwidth < 0\n");
      cd->right_width = -cd->right_width;
      result = 0;
    }

    /* cd->print_cpos = 0; */
    
    VerifyList(cd->attributes, corpus, remove_illegal_entries);
    if (cd->attributes && cd->attributes->list == NULL)
      DestroyAttributeList(&(cd->attributes));

    (void) VerifyList(cd->strucAttributes, corpus, remove_illegal_entries);
    if (cd->strucAttributes && cd->strucAttributes->list == NULL)
      DestroyAttributeList(&(cd->strucAttributes));

    (void) VerifyList(cd->printStructureTags, corpus, remove_illegal_entries);
    if (cd->printStructureTags && cd->printStructureTags->list == NULL)
      DestroyAttributeList(&(cd->printStructureTags));

    (void) VerifyList(cd->alignedCorpora, corpus, remove_illegal_entries);
    if (cd->alignedCorpora && cd->alignedCorpora->list == NULL)
      DestroyAttributeList(&(cd->alignedCorpora));
      
  }
  return result;
}

ContextDescriptor *NewContextDescriptor()
{
  ContextDescriptor *cd;

  cd = (ContextDescriptor *)cl_malloc(sizeof(ContextDescriptor));
  initialize_context_descriptor(cd);

  return cd;
}

void FreeContextDescriptor(ContextDescriptor **cdp)
{
  /* TODO: free allocated memory */

  free(*cdp);
  *cdp = NULL;
}

int initialize_context_descriptor(ContextDescriptor *cd)
{
  cd->left_width = 0;
  cd->left_type  = CHAR_CONTEXT;
  cd->left_structure = NULL;
  cd->left_structure_name = NULL;

  cd->right_width = 0;
  cd->right_type  = CHAR_CONTEXT;
  cd->right_structure = NULL;
  cd->right_structure_name = NULL;

  cd->print_cpos =0;

  cd->attributes = NULL;
  cd->strucAttributes = NULL;
  cd->printStructureTags = NULL;
  cd->alignedCorpora = NULL;

  return 1;
}

int update_context_descriptor(Corpus *corpus,
			      ContextDescriptor *cd)
{
  AttributeInfo *ai;

  if (!cd->attributes) {
    cd->attributes = NewAttributeList(ATT_POS);
    /* cd->print_cpos = 0; */
  }
  RecomputeAL(cd->attributes, corpus, 0);

  if (!cd->strucAttributes)
    cd->strucAttributes = NewAttributeList(ATT_STRUC);
  RecomputeAL(cd->strucAttributes, corpus, 0);

  if (!cd->printStructureTags)
    cd->printStructureTags = NewAttributeList(ATT_STRUC);
  RecomputeAL(cd->printStructureTags, corpus, 0);
  
  if (!cd->alignedCorpora)
    cd->alignedCorpora = NewAttributeList(ATT_ALIGN);
  RecomputeAL(cd->alignedCorpora, corpus, 0);
  
  for (ai = cd->printStructureTags->list; ai; ) {

    /* das Merken des Nachfolgers ist notwendig, weil RemoveName.. die
     * Liste destruktiv zerstört. */

    Attribute *attr;
    AttributeInfo *next_ai;

    next_ai = ai->next;

    attr = find_attribute(corpus, ai->name, ATT_STRUC, NULL);
    if (!attr || !structure_has_values(attr))
      RemoveNameFromAL(cd->printStructureTags, ai->name);
    
    ai = next_ai;
  }
  
  return 1;

}

/* attribute (selected/unselected) print helper routine */
void 
PrintAttributes(FILE *fd, char *header, AttributeList *al, int show_if_annot) {
  int line = 0, i;
  AttributeInfo *ai;

  if (al && al->list) {
    for (ai = al->list; ai; ai = ai->next) {
      if (line++ == 0) 
	fprintf(fd, "%s", header);
      else 
	for (i = strlen(header); i; i--) fprintf(fd, " ");
      if (ai->status) fprintf(fd, "  * "); else fprintf(fd, "    ");
      if ((!show_if_annot) ||	/* structural attributes only */
	  !cl_struc_values(ai->attribute)) {
	fprintf(fd, "%s\n", ai->attribute->any.name);
      } 
      else {
	fprintf(fd, "%-20s [A]\n", ai->attribute->any.name);
      }
    }
  }
  else {
    fprintf(fd, "%s    <none>\n", header);
  }
}

/* attribute print helper routine (non pretty-printing mode) */
void 
PrintAttributesSimple(FILE *fd, char *type, AttributeList *al, int show_if_annot) {
  AttributeInfo *ai;

  if (al && al->list) {
    for (ai = al->list; ai; ai = ai->next) {
      fprintf(fd, "%s\t%s", type, ai->attribute->any.name);
      if (show_if_annot) {
	fprintf(fd, "\t%s", (cl_struc_values(ai->attribute)) ? "-V" : "");
      }
      fprintf(fd, "\n");
    }
  }
}

void
PrintContextDescriptor(ContextDescriptor *cdp)
{
  FILE *fd;
  struct Redir rd = { NULL, NULL, NULL, 0, 0 };	/* for paging (with open_stream()) */
  int stream_ok;

  if (cdp) {
    stream_ok = open_stream(&rd, ascii);
    fd = (stream_ok) ? rd.stream : stdout; /* use pager, or simply print to stdout if it fails */

    if (pretty_print) {
      fprintf(fd, "===Context Descriptor=======================================\n");
      fprintf(fd, "\n");
      fprintf(fd, "left context:     %d ", cdp->left_width);
      switch (cdp->left_type) {
      case CHAR_CONTEXT: 
	fprintf(fd, "characters\n"); break;
      case WORD_CONTEXT: 
	fprintf(fd, "tokens\n"); break;
      case STRUC_CONTEXT: 
      case ALIGN_CONTEXT:
	fprintf(fd, "%s\n", 
		cdp->left_structure_name ? cdp->left_structure_name : "???");
      }
      fprintf(fd, "right context:    %d ", cdp->right_width);
      switch (cdp->right_type) {
      case CHAR_CONTEXT: 
	fprintf(fd, "characters\n"); break;
      case WORD_CONTEXT: 
	fprintf(fd, "tokens\n"); break;
      case STRUC_CONTEXT: 
      case ALIGN_CONTEXT:
	fprintf(fd, "%s\n", 
		cdp->right_structure_name ? cdp->right_structure_name : "???");
      }
      fprintf(fd, "corpus position:  %s\n", cdp->print_cpos ? "shown" : "not shown");
      fprintf(fd, "target anchors:   %s\n", show_targets ? "shown" : "not shown");
      fprintf(fd, "\n");
      PrintAttributes(fd, "Positional Attributes:", cdp->attributes, 0);
      fprintf(fd, "\n");
      PrintAttributes(fd, "Structural Attributes:", cdp->strucAttributes, 1);
      fprintf(fd, "\n");
      /*     PrintAttributes(fd, "Structure Values:     ", cdp->printStructureTags); */
      /*     fprintf(fd, "\n"); */
      PrintAttributes(fd, "Aligned Corpora:      ", cdp->alignedCorpora, 0);
      fprintf(fd, "\n");
      fprintf(fd, "============================================================\n");
    }
    else {
      PrintAttributesSimple(fd, "p-Att", cdp->attributes, 0);
      PrintAttributesSimple(fd, "s-Att", cdp->strucAttributes, 1);
      PrintAttributesSimple(fd, "a-Att", cdp->alignedCorpora, 0);
    }

    if (stream_ok) 
      close_stream(&rd);	/* close pipe to pager if we were using it */
  }
}


