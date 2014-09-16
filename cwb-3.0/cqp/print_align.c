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

#include "../cl/corpus.h"
#include "../cl/attributes.h"
#include "../cl/cdaccess.h"
#include "../cl/macros.h"

#include "concordance.h"

#include "cqp.h"
#include "options.h"
#include "corpmanag.h"
#include "print-modes.h"
#include "context_descriptor.h"

#include "ascii-print.h"
#include "html-print.h"
#include "sgml-print.h"
#include "latex-print.h"

static int module_init = 0;

static ContextDescriptor AlignedCorpusCD;

/* ---------------------------------------------------------------------- */

void
init_align_module()
{
  if (module_init == 0) {

    initialize_context_descriptor(&AlignedCorpusCD);
    AlignedCorpusCD.left_type = WORD_CONTEXT;
    AlignedCorpusCD.right_type = WORD_CONTEXT;

    module_init++;
  }
}

/* ---------------------------------------------------------------------- */


/* THIS SHOULD REALLY BE REWRITTTEN SO THAT THE ALIGNED CORPUS, ITS ATTRIBUTES, AND
   THE (ALIGNED) CD ARE ONLY INITIALISED ONCE (FOR EACH CAT COMMAND) */
void
printAlignedStrings(Corpus *sourceCorpus, 
		    ContextDescriptor *cd,
		    int begin_target, 
		    int end_target,
		    int highlighting, /* highlight corpus tags of aligned lines? (ASCII mode only) */
		    FILE *stream)
{
  AttributeInfo *ai, *Sai, *Tai;
  Attribute *alat;
  Corpus *alignedCorpus;

  int dummy;

  if (!module_init)
    init_align_module();
  
  if (cd->alignedCorpora == NULL || cd->alignedCorpora->list == NULL)
    return;

  for (ai = cd->alignedCorpora->list; ai && ai->name; ai = ai->next) {

    if (ai->status) {

      /* right_width und left_width setzen */
      if (((alat = find_attribute(sourceCorpus, 
				  ai->name, 
				  ATT_ALIGN, NULL)) != NULL) &&
	  (/* if it isn't already there, load it (setup_corpus() will just increment the refcount, if the corpus is already loaded) */
	   ((alignedCorpus = setup_corpus(registry,
					  ai->name)) != NULL))) {
	
	int alg1, alg2, alg_start, alg_end;
	char *s = NULL;
	
	alg1 = cl_cpos2alg(alat, begin_target);
	alg2 = cl_cpos2alg(alat, end_target);

	if ((alg1 < 0) ||
	    (alg2 < 0) ||
	    !cl_alg2cpos(alat, alg1, &dummy, &dummy, &alg_start, &dummy) ||
	    !cl_alg2cpos(alat, alg2, &dummy, &dummy, &dummy, &alg_end) ||
	    (alg_end < alg_start)
	    ) {
	  s = cl_strdup("(no alignment found)");	    /* s != NULL signifies error or no alignment found */
	}
	
	/* For some obscure reason, the AlignedCorpusCD sometimes gets corrupted
	   from outside; so we re-initialize for every aligned corpus we print. */
	initialize_context_descriptor(&AlignedCorpusCD);
	update_context_descriptor(alignedCorpus, &AlignedCorpusCD);
	
	/* How about this: Try to show the same attributes in this corpus 
	   as in the aligned corpus */
	if (cd->attributes) {
	  for (Sai = cd->attributes->list; Sai && Sai->name; Sai = Sai->next) {
	    if ((Tai = FindInAL(AlignedCorpusCD.attributes, Sai->name)))
	      Tai->status = Sai->status;
	  }
	} /* positional attributes */
	if (cd->strucAttributes) {
	  for (Sai = cd->strucAttributes->list; Sai && Sai->name; Sai = Sai->next) {
	    if ((Tai = FindInAL(AlignedCorpusCD.strucAttributes, Sai->name)))
	      Tai->status = Sai->status;
	  }
	} /* structural attributes */
	/* printing structural attribute values in the aligned regions doesn't
	     seem to make a lot of sense, so we stick with the first two options */

	switch (GlobalPrintMode) {
	case PrintASCII:
	case PrintUNKNOWN:
	  if (s == NULL) 
	    s = compose_kwic_line(alignedCorpus, 
				  alg_start, alg_end, 
				  &AlignedCorpusCD, 
				  &dummy,
				  &dummy, &dummy,
				  NULL, NULL, 
				  NULL, 0, NULL, 
				  NULL, 0,
				  ConcLineHorizontal,
				  &ASCIIPrintDescriptionRecord,
				  0, NULL);
	  ascii_print_aligned_line(stream, highlighting, ai->name, s ? s : "(null)");
	  break;
	    
	case PrintSGML:
	  if (s == NULL)
	    s = compose_kwic_line(alignedCorpus, 
				  alg_start, alg_end, 
				  &AlignedCorpusCD, 
				  &dummy,
				  &dummy, &dummy,
				  NULL, NULL, 
				  NULL, 0, NULL, 
				  NULL, 0,
				  ConcLineHorizontal,
				  &SGMLPrintDescriptionRecord,
				  0, NULL);
	  sgml_print_aligned_line(stream, ai->name, s ? s : "(null)");
	  break;
	    
	case PrintHTML:
	  if (s == NULL)
	    s = compose_kwic_line(alignedCorpus, 
				  alg_start, alg_end, 
				  &AlignedCorpusCD, 
				  &dummy,
				  &dummy, &dummy,
				  NULL, NULL, 
				  NULL, 0, NULL, 
				  NULL, 0,
				  ConcLineHorizontal,
				  &HTMLPrintDescriptionRecord,
				  0, NULL);
	  html_print_aligned_line(stream, ai->name, s ? s : "(null)");
	  break;
	    
	case PrintLATEX:
	  if (s == NULL)
	    s = compose_kwic_line(alignedCorpus, 
				  alg_start, alg_end, 
				  &AlignedCorpusCD, 
				  &dummy,
				  &dummy, &dummy,
				  NULL, NULL, 
				  NULL, 0, NULL, 
				  NULL, 0,
				  ConcLineHorizontal,
				  &LaTeXPrintDescriptionRecord,
				  0, NULL);
	  latex_print_aligned_line(stream, ai->name, s ? s : "(null)");
	  break;
	    
	case PrintBINARY:
	  /* don't display anything */
	  break;
	    
	default:
	  assert(0 && "Unknown print mode");
	  break;
	}
	free(s);
	/* don't drop the corpus even if we're the only one using it;
	   this may waste some memory, but otherwise we'd keep loading
	   and unloading the thing */
      }
    }
  }
}
