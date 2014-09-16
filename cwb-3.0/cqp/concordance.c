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

#include "../cl/globals.h"
#include "../cl/macros.h"
#include "../cl/corpus.h"
#include "../cl/attributes.h"
#include "../cl/cdaccess.h"


#include "concordance.h"
#include "attlist.h"
#include "options.h"

#define MAXKWICLINELEN 65535

#define SRESIZE 1024


/* ---------------------------------------------------------------------- */

/* ---------------------------------------------------------------------- */

void add_to_string(char **s, int *spos, int *ssize, char *suffix)
{
  int len, i;

  len = strlen(suffix);

  if (*s == NULL) {
    *s = cl_malloc(SRESIZE);
    *ssize = SRESIZE;
    *spos = 0;
  }

  while ((*spos + len) >= *ssize) {
    *ssize += SRESIZE;
    *s = cl_realloc(*s, *ssize);
  }
  
  for (i = 0; suffix[i]; i++) {
    ((*s)[*spos]) = suffix[i];
    *spos += 1;
  }
  ((*s)[*spos]) = '\0';
}

/* ============================== srev(): reverse string, destructively */

char *
srev(char *s)
{
  register char b;
  register int i, l;

  l = strlen(s);

  for (i = 0; i < l/2; i++) {

    b = s[l-i-1];
    s[l-i-1] = s[i];
    s[i] = b;

  }

  return s;
}

/* ---------------------------------------------------------------------- */

/* inline */
int
append(char *s, char *suffix, int *sp, int max_sp)
{
  char *k = suffix;
  int acc = 0;

  if (s && k && *k && *sp < max_sp) {
    acc = *sp;

    for ( ; *k && (*sp < max_sp); k++) {
      s[(*sp)++] = *k;
    }
    acc = *sp - acc;
  }
  return acc;
}



/* ============================== get_print_attribute_values() */

int
get_print_attribute_values(ContextDescriptor *cd,
                           int position,
                           char *s,
                           int *sp,
                           int max_sp,
                           int add_position_number,
                           PrintDescriptionRecord *pdr)
{
  if (add_position_number && pdr->CPOSPrintFormat) {
    static char num[MAX_LINE_LENGTH];  /* another 'Oli': this was num[16], definitely not enough for HTML output */
    
    sprintf(num, pdr->CPOSPrintFormat, position);
    append(s, num, sp, max_sp);
  }

  if (cd->printStructureTags) {
    
    AttributeInfo *ai;
    int pref_printed = 0;

    for (ai = cd->printStructureTags->list; ai; ai = ai->next) {
      
      char *v;
      
      if (ai->status) {
        
        assert(ai->attribute);
        
        if (!pref_printed) {
          append(s, pdr->BeforePrintStructures, sp, max_sp);
          pref_printed++;
        }
        
        append(s, pdr->StructureBeginPrefix, sp, max_sp);
        append(s, 
               pdr->printToken 
               ? pdr->printToken(ai->attribute->any.name) 
               : ai->attribute->any.name, 
               sp, max_sp);
        
        /* print value */

        v = structure_value_at_position(ai->attribute, position);
        if (v && pdr->printToken)
          v = pdr->printToken(v);

        if (v) {
          append(s, pdr->PrintStructureSeparator, sp, max_sp);
          append(s, v, sp, max_sp);
        }

        append(s, pdr->StructureBeginSuffix, sp, max_sp);
      }
    }
    
    if (pref_printed)
      append(s, pdr->AfterPrintStructures, sp, max_sp);
    
    s[*sp] = '\0';
    
  }
  
  return 1;
}



/* ============================== helpers for: get_position_values() */
/* the following code is borrowed from <utils/decode.c> and ensures that XML tags in the kwic output always nest properly */

#define MAX_S_ATTRS 1024        /* max. number of s-attribute; same as MAX_ATTRS in <utils/decode.c> and MAXRANGES in <utils/encode.c>  */
typedef struct {                
  char *name;                   /* name of the s-attribute */
  int start;
  int end;
  char *annot;                  /* NULL if there is no annotation */
} SAttRegion;
SAttRegion s_att_regions[MAX_S_ATTRS];
int sar_sort_index[MAX_S_ATTRS]; /* index used for bubble-sorting list of regions */
int N_sar = 0;                   /* number of regions currently in list (may change for each token printed) */

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


/* ============================== get_position_values(): get values at given corpus position
 */

int
get_position_values(ContextDescriptor *cd,
                    int position,
                    char *s,
                    int *sp,
                    int max_sp,
                    int add_position_number, 
                    ConcLineLayout orientation,
                    PrintDescriptionRecord *pdr,
                    int nr_mappings, 
                    Mapping *mappings)
{
  AttributeInfo *ai;
  int id, i;
  int nr_attrs = 0;
  char *word;


  /* insert all s-attribute regions which start or end at the current token into s_att_regions[],
     then sort them to ensure proper nesting, and print from the list */
  N_sar = 0;
  if (cd->strucAttributes) {
    for (ai = cd->strucAttributes->list; ai; ai = ai->next)
      if (ai->status) {
        int s_start, s_end, snum;
        
        if ( ((snum = cl_cpos2struc(ai->attribute, position)) >= 0) &&
             (cl_struc2cpos(ai->attribute, snum, &s_start, &s_end)) &&
             ((position == s_start) || (position == s_end)) ) {

          s_att_regions[N_sar].name = ai->attribute->any.name;
          s_att_regions[N_sar].start = s_start;
          s_att_regions[N_sar].end = s_end;
          if (cl_struc_values(ai->attribute))
            s_att_regions[N_sar].annot = cl_struc2str(ai->attribute, snum);
          else
            s_att_regions[N_sar].annot = NULL;
          N_sar++;
          }

        }
    sort_s_att_regions();
  } /* else N_sar == 0 */


  /* ==================== first, add starting structures */

  if (add_position_number && orientation == ConcLineHorizontal) {

    char num[16];

    sprintf(num, pdr->CPOSPrintFormat, position);
    append(s, num, sp, max_sp);
  }

  /* print open tags from s_att_regions[] (ascending) */
  if (cd->strucAttributes) {
    SAttRegion *region;
    int do_lb = 0;

    for (i = 0; i < N_sar; i++) {
      region = &(s_att_regions[sar_sort_index[i]]);
      if (region->start == position) {
        /* add start tag to s */
        static char body[MAX_LINE_LENGTH]; /* 'body' of the start tag, may include annotation  */
        if (show_tag_attributes && (region->annot != NULL)) {
          sprintf(body, "%s %s", region->name, region->annot);
        }
        else {
          strcpy(body, region->name);
        }
        
        append(s, pdr->StructureBeginPrefix, sp, max_sp);
        append(s, (pdr->printToken) ? pdr->printToken(body) : body, sp, max_sp);
        append(s, pdr->StructureBeginSuffix, sp, max_sp);
        do_lb++;
      }
    }
    
    if (do_lb && (orientation == ConcLineVertical))
      append(s, pdr->AfterLine, sp, max_sp);
  }

  if (add_position_number && orientation == ConcLineVertical) {
    char num[16];
    
    sprintf(num, pdr->CPOSPrintFormat, position);
    append(s, num, sp, max_sp);
  }


  /* ==================== then, add positional attribute values */

  /* TODO: apply mappings -- or rather FORGET ABOUT IT! */
  
  for (ai = cd->attributes->list; ai; ai = ai->next) {
    
    if (ai->attribute && ai->status > 0) {
      
      if (nr_attrs > 0)
        append(s, pdr->AttributeSeparator, sp, max_sp);
      
      word = NULL;
      
      if (nr_mappings > 0) {

        /* unused */

        int mp = 0;
        int class = 0;

        for (mp = 0; 
             mp < nr_mappings && mappings[mp]->attribute != ai->attribute;
             mp++)
          ;
        
        if (mp < nr_mappings) {

          id = get_id_at_position(ai->attribute, position);

          assert(ai->attribute == mappings[mp]->attribute);

          if (cderrno == CDA_OK) {
            class = map_id_to_class_number(mappings[mp], id);
            if (class >= 0)
              word = mappings[mp]->classes[class].class_name;
          }
        }
      }
      
      if (!word)
        word = get_string_at_position(ai->attribute, position);

      if (word != NULL)
        append(s, 
               pdr->printToken ? pdr->printToken(word) : word, 
               sp, max_sp);

      nr_attrs++;
    }
  }

  /* ==================== finally, add ending structures */

  /* print close tags from s_att_regions[] (descending) */
  if (cd->strucAttributes) {
    SAttRegion *region;
    int lb = 0;                 /* line break done? */

    for (i = N_sar - 1; i >= 0; i--) {
      region = &(s_att_regions[sar_sort_index[i]]);
      if (region->end == position) {
        if (orientation == ConcLineVertical && !lb) {
          append(s, pdr->AfterLine, sp, max_sp);
          lb++;
        }

        /* add end tag to s */
        append(s, pdr->StructureEndPrefix, sp, max_sp);
        append(s, (pdr->printToken) ? pdr->printToken(region->name) : region->name, sp, max_sp);
        append(s, pdr->StructureEndSuffix, sp, max_sp);
      }
    }
  }

  /* ==================== finish and exit */

  s[*sp] = '\0';

#if 0
  fprintf(stderr, "get_position_values() at pos %d: ``%s''\n", 
          position, s);
#endif

  return 1;
}

void
remember_this_position(int position,
                       int this_token_start, int this_token_end,
                       int *position_list,
                       int nr_positions,
                       int *returned_positions)
{
  int p;

  if (nr_positions > 0) {
    assert(position_list);

    for (p = 0; p < nr_positions; p++) {
      if (position_list[p] == position) {
        returned_positions[p * 2] = this_token_start;
        returned_positions[(p * 2)+1] = this_token_end;
      }
    }
  }
}

char *
get_field_separators(int position, 
                     ConcLineField *fields,
                     int nr_fields,
                     int at_end,
                     PrintDescriptionRecord *pdr)
{
  static char s[1024];
  int i, spos;

  spos = 0;

  if (fields && nr_fields > 0 && 
      position >= 0 && pdr && pdr->printField) {
    
    if (at_end) {
      for (i = nr_fields; i > 0; i--) {
        if (position == fields[i-1].end_position) {
          append(s, pdr->printField(fields[i-1].type, at_end), &spos, 1024);
        }
      }
    }
    else {
      for (i = 0; i < nr_fields; i++) {
        if (position == fields[i].start_position) {
          append(s, pdr->printField(fields[i].type, at_end), &spos, 1024);
        }
      }
    }
    
    s[spos] = '\0';

    if (spos > 0)
      return s;
    else
      return NULL;
  }
  else
    return NULL;
}

char *
compose_kwic_line(Corpus *corpus,
                  int match_start, int match_end,
                  ContextDescriptor *cd,
                  int *length,
                  int *s_mb,
                  int *s_me,
                  char *left_marker,
                  char *right_marker,
                  int *position_list,
                  int nr_positions,
                  int *returned_positions,
                  ConcLineField *fields,
                  int nr_fields,
                  ConcLineLayout orientation,
                  PrintDescriptionRecord *pdr,
                  int nr_mappings,
                  Mapping *mappings)
{
  int acc_len;
  int text_size;
  int start, end, index;

  char line[MAXKWICLINELEN + 1];
  int line_p;

  char token[MAXKWICLINELEN + 1];
  int token_p;

  char *word;

  char separator;
  int number_lines;

  int rng_s, rng_e, rng_n, nr_ranges;

  int this_token_start, this_token_end;

  int el_c = 0;

  int enough_context = 0;       /* ob wir noch appenden sollen oder nicht */

  int nr_selected_attributes = 0;

  AttributeList *default_list = NULL;
  AttributeInfo *ai;


  /* set the separator */

  if (orientation == ConcLineHorizontal) {
    separator = ' ';
    number_lines = 0;
  }
  else {
    separator = '\n';
    number_lines = cd->print_cpos;
  }

  /* make a dummy attribute list in case we don't yet have one. */

  if (cd->attributes == NULL ||
      cd->attributes->list == NULL) {
    default_list = NewAttributeList(ATT_POS);
    (void) AddNameToAL(default_list, DEFAULT_ATT_NAME, 1, 0);
    cd->attributes = default_list;
  }
  
  if (!cd->attributes->list_valid)
    VerifyList(cd->attributes, corpus, 1);

  for (ai = cd->attributes->list; ai; ai = ai->next) 
    if (ai->status > 0)
      nr_selected_attributes++;

  if (nr_selected_attributes == 0) {
    ai = FindInAL(cd->attributes, DEFAULT_ATT_NAME);
    if (ai) {
      ai->status = 1;
      nr_selected_attributes++;
    }
    else {
      fprintf(stderr, "ERROR: Can't select default attribute in attribute list\n");
      return NULL;
    }
  }

  assert(cd->attributes->list->attribute);

  line_p = 0;
  line[line_p] = '\0';

  text_size = get_attribute_size(cd->attributes->list->attribute);

  assert((match_start >= 0) && 
         (match_start < text_size));

  assert((match_end >= 0) && 
         (match_end < text_size) && 
         (match_end >= match_start));

  get_print_attribute_values(cd, match_start, 
                             line, &line_p, 
                             MAXKWICLINELEN, 
                             cd->print_cpos && (orientation == ConcLineHorizontal),
                             pdr);

  append(line, pdr->BeforeField, &line_p, MAXKWICLINELEN);

  /* ============================== clear array of returned positions */

  if (position_list && (nr_positions > 0)) {
    assert(returned_positions);
    
    for (el_c = 0; el_c < nr_positions * 2; el_c++)
      returned_positions[el_c] = -1;
  }


  switch(cd->left_type) {
  case CHAR_CONTEXT:
    
    acc_len = 0;                /* we have 0 characters so far */
    enough_context = 0;

    /* wir merken uns den alten Anfang, wg. srev() */
    index = line_p;

    /* NUR linken Kontext ohne MatchToken berechnen */
    
    for (start = match_start-1; 
         (start >= 0 && !enough_context); 
         start--) {

      token_p = 0;
      
      if (acc_len >= cd->left_width) {
        enough_context++;
      }
      else if (get_position_values(cd, 
                                   start, 
                                   token, &token_p, 
                                   MAXKWICLINELEN, 
                                   number_lines, 
                                   orientation, 
                                   pdr,
                                   nr_mappings, 
                                   mappings) &&
               token_p > 0) {

        if (line_p > index) {   /* no blank before first token to the left of match */
          acc_len += append(line, pdr->TokenSeparator, &line_p, MAXKWICLINELEN);
        }

        this_token_start = line_p;
        
        /* wir fügen erstmal ganz normal ein und drehen nachher um */

        if ((word = get_field_separators(start, fields, nr_fields, 0, pdr)))
          append(line, word, &line_p, MAXKWICLINELEN);
        
        append(line, pdr->BeforeToken, &line_p, MAXKWICLINELEN);

        if (token_p + acc_len < cd->left_width) {
          acc_len += append(line, token, &line_p, MAXKWICLINELEN);
        }
        else {
          acc_len += append(line, 
                            token + (token_p - (cd->left_width - acc_len)), 
                            &line_p, MAXKWICLINELEN);
        }
          
        append(line, pdr->AfterToken, &line_p, MAXKWICLINELEN);

        if ((word = get_field_separators(start, fields, nr_fields, 1, pdr)))
          append(line, word, &line_p, MAXKWICLINELEN);
        
        this_token_end = line_p;
        
        line[line_p] = '\0';
        srev(line + this_token_start);

        this_token_end = line_p;

        if (this_token_start != this_token_end)
          remember_this_position(start,
                                 this_token_start, this_token_end,
                                 position_list, nr_positions,
                                 returned_positions);

      }
      else
        enough_context = 1;
    }

    /* auffüllen (padding) mit Blanks, bis linker Kontext erreicht */
    while (acc_len < cd->left_width) {
      append(line, " ", &line_p, MAXKWICLINELEN);
      acc_len++; /* pretend to fill in necessary number of blanks, even if buffer is already full */
    }

    /* die bisherige Zeile (Linkskontext des Match-Tokens) umdrehen,
     * aber nicht evtl. printStructures
     */

#if 0
    fprintf(stderr, "line bef srev(): >>%s<<\n", line + index);
#endif

    line[line_p] = '\0';
    srev(line+index);

#if 0
    fprintf(stderr, "line aft srev(): >>%s<<\n", line + index);
#endif

    /* der spannende Teil: wir müssen wg srev() die Liste der
     * returned_positions angleichen... */

    if (position_list && (nr_positions > 0)) {

      int old_start, new_start, old_end, new_end;

      for (el_c = 0; el_c < nr_positions; el_c++) {
        
        if (returned_positions[el_c * 2] >= 0) {

          old_start = returned_positions[el_c * 2] - index;
          old_end   = returned_positions[(el_c * 2)+1] - index;

          new_start = line_p - 1 - old_end;
          new_end   = line_p - 1 - old_start;

#if 0
          fprintf(stderr, "Patching [%d,%d] to [%d,%d]\n",
                  old_start, old_end, new_start, new_end);
#endif

          returned_positions[el_c * 2] = new_start + 1;
          returned_positions[(el_c * 2)+1] = new_end + 1;

          /* weia... */
        }
      }
    }

    break;
    
  case WORD_CONTEXT:

    start = match_start - cd->left_width;

    if (start < 0)
      start = 0;

    for ( ; start < match_start; start++) {

      token_p = 0;
      if (get_position_values(cd, 
                              start, 
                              token, &token_p, 
                              MAXKWICLINELEN, 
                              number_lines,
                              orientation, 
                              pdr, 
                              nr_mappings, mappings)) {

        /* Trennzeichen einfügen, falls schon tokens in line drin sind */
        if (line_p > 0)
          append(line, pdr->TokenSeparator, &line_p, MAXKWICLINELEN);

        this_token_start = line_p;

        if ((word = get_field_separators(start, fields, nr_fields, 0, pdr)))
          append(line, word, &line_p, MAXKWICLINELEN);
        
        append(line, pdr->BeforeToken, &line_p, MAXKWICLINELEN);
        append(line, token, &line_p, MAXKWICLINELEN);
        append(line, pdr->AfterToken, &line_p, MAXKWICLINELEN);

        if ((word = get_field_separators(start, fields, nr_fields, 1, pdr)))
          append(line, word, &line_p, MAXKWICLINELEN);
        
        this_token_end = line_p;

        remember_this_position(start,
                               this_token_start, this_token_end,
                               position_list, nr_positions,
                               returned_positions);
      }
      else
        break;
    }

    break;

  case STRUC_CONTEXT:
  case ALIGN_CONTEXT:
    
    if (!cd->left_structure) {
      fprintf(stderr, "concordance.o/compose_kwic_line: lcontext attribute pointer is NULL\n");
      start = match_start - 20;
    }
    else {
      if (cd->left_type == ALIGN_CONTEXT) {
        /* context == alignment block */
        if (0 > (rng_n = cl_cpos2alg(cd->left_structure, match_start))) 
          start = match_start;
        else {
          assert(cd->left_width == 1);
          
          /* get start of source corpus alignment block */
          if (!cl_alg2cpos(cd->left_structure,
                           rng_n,
                           &rng_s, &rng_e, &rng_e, &rng_e))
            start = match_start;
          else
            start = rng_s;
        }
      }
      else {
        /* context == structural region(s) */
        if (0 > (rng_n = cl_cpos2struc(cd->left_structure, match_start)))
          start = match_start - 20;
        else {
          assert(cd->left_width >= 0);

          /* determine the lower range number */
          rng_n = MAX(0, rng_n - cd->left_width + 1);
          if (!cl_struc2cpos(cd->left_structure,
                             rng_n,
                             &rng_s, &rng_e)) 
            start = match_start - 20;
          else
            start = rng_s;
        }
      }
    }
    
    if (start < 0)
      start = 0;
      
    for ( ; start < match_start; start++) {
      
      token_p = 0;
      if (get_position_values(cd, 
                              start, 
                              token, &token_p, 
                              MAXKWICLINELEN, 
                              number_lines,
                              orientation,
                              pdr, 
                              nr_mappings, mappings)) {
        
        /* Trennzeichen einfügen, falls schon tokens in line drin sind */
        if (line_p > 0)
          append(line, pdr->TokenSeparator, &line_p, MAXKWICLINELEN);

        this_token_start = line_p;

        /* jetzt den Feldstart */
        if ((word = get_field_separators(start, fields, nr_fields, 0, pdr)))
          append(line, word, &line_p, MAXKWICLINELEN);
        
        append(line, pdr->BeforeToken, &line_p, MAXKWICLINELEN);

        /* token an line dranhängen */
        append(line, token, &line_p, MAXKWICLINELEN);

        append(line, pdr->AfterToken, &line_p, MAXKWICLINELEN);

        /* jetzt das Feldende */
        if ((word = get_field_separators(start, fields, nr_fields, 1, pdr))) {
          append(line, word, &line_p, MAXKWICLINELEN);
        }
        
        this_token_end = line_p;

        remember_this_position(start,
                               this_token_start, this_token_end,
                               position_list, nr_positions,
                               returned_positions);
      }
      else
        break;
    }

    break;
  }


  /* Der linke Kontext ist berechnet. Nun werden die Match-Tokens
   * eingefügt
   */

  /* Trennzeichen einfügen, falls schon tokens in line drin sind */
  if (line_p > 0)
    append(line, pdr->TokenSeparator, &line_p, MAXKWICLINELEN);
  
  *s_mb = line_p;

  append(line, left_marker, &line_p, MAXKWICLINELEN);
  
  for (start = match_start; start <= match_end; start++) {
    
    token_p = 0;
    if (get_position_values(cd, 
                            start, 
                            token, &token_p, 
                            MAXKWICLINELEN, 
                            number_lines,
                            orientation, 
                            pdr, 
                            nr_mappings, mappings)) {
            
      /* token an line dranhängen */

      this_token_start = line_p;


      if ((word = get_field_separators(start, fields, nr_fields, 0, pdr)))
        append(line, word, &line_p, MAXKWICLINELEN);
  
      append(line, pdr->BeforeToken, &line_p, MAXKWICLINELEN);
      append(line, token, &line_p, MAXKWICLINELEN);
      append(line, pdr->AfterToken, &line_p, MAXKWICLINELEN);
      
      if ((word = get_field_separators(start, fields, nr_fields, 1, pdr)))
        append(line, word, &line_p, MAXKWICLINELEN);

      this_token_end = line_p;

      remember_this_position(start,
                             this_token_start, this_token_end,
                             position_list, nr_positions,
                             returned_positions);

      if (start != match_end) {
        /* Trennzeichen einfügen */
        if (line_p > 0 && line_p < MAXKWICLINELEN)
          line[line_p++] = separator;
      }
    }
    else
      break;
  }
  
  append(line, right_marker, &line_p, MAXKWICLINELEN);


  *s_me = line_p;

  /* nun muß noch der Rechtskontext hinzugefügt werden */


  switch(cd->right_type) {
  case CHAR_CONTEXT:
    
    acc_len = 0;                /* we have 0 characters so far */
    enough_context = 0;

    /* nun rechten Kontext ohne MatchToken berechnen */

    for (start = match_end+1; 
         (start < text_size && !enough_context); 
         start++) {

      token_p = 0;

      if (acc_len >= cd->right_width || line_p >= MAXKWICLINELEN)
        enough_context++; /* stop if the requested number of characters have been generated or if the buffer is full */
      else if (get_position_values(cd, 
                                   start, 
                                   token, &token_p, 
                                   MAXKWICLINELEN, 
                                   number_lines,
                                   orientation,
                                   pdr, 
                                   nr_mappings, mappings)) {

        if (line_p > 0)
          acc_len += append(line, pdr->TokenSeparator, &line_p, MAXKWICLINELEN);

        this_token_start = line_p;

        /* jetzt den Feldstart */
        if ((word = get_field_separators(start, fields, nr_fields, 0, pdr)))
          append(line, word, &line_p, MAXKWICLINELEN);
        
        append(line, pdr->BeforeToken, &line_p, MAXKWICLINELEN);

        token_p = 0;
        while (token[token_p] && line_p < MAXKWICLINELEN &&
               acc_len < cd->right_width) {
          line[line_p++] = token[token_p++];
          acc_len++;
          /* acc_len += append(line, token, &line_p, MAXKWICLINELEN); */
        }
        append(line, pdr->AfterToken, &line_p, MAXKWICLINELEN);

        /* jetzt das Feldende */
        if ((word = get_field_separators(start, fields, nr_fields, 1, pdr)))
          append(line, word, &line_p, MAXKWICLINELEN);

        this_token_end = line_p;

        if (this_token_start != this_token_end)
          remember_this_position(start,
                                 this_token_start, this_token_end,
                                 position_list, nr_positions,
                                 returned_positions);
      }
      else
        enough_context = 1;
    }

    /* THIS IS NONSENSE -- deactivated by SE, 13.02.2012 */
#if 0
    /* pad right context with blanks, so we always have exactly <n> characters of context */
    while (line_p < cd->right_width)
      append(line, " ", &line_p, MAXKWICLINELEN);
#endif
    
    break;
    
  case WORD_CONTEXT:

    for (start = 1; 
         (start <= cd->right_width && 
          match_end + start < text_size); 
         start++) {

      token_p = 0;
      if (get_position_values(cd, 
                              match_end + start, 
                              token, &token_p, 
                              MAXKWICLINELEN, 
                              number_lines,
                              orientation,
                              pdr, 
                              nr_mappings, mappings)) {
        
        /* Trennzeichen einfügen, falls schon tokens in line drin sind */
        if (line_p > 0)
          append(line, pdr->TokenSeparator, &line_p, MAXKWICLINELEN);

        this_token_start = line_p;

        if ((word = get_field_separators(match_end + start, 
                                         fields, nr_fields, 0, pdr)))
          append(line, word, &line_p, MAXKWICLINELEN);
        
        append(line, pdr->BeforeToken, &line_p, MAXKWICLINELEN);
        append(line, token, &line_p, MAXKWICLINELEN);
        append(line, pdr->AfterToken, &line_p, MAXKWICLINELEN);

        if ((word = get_field_separators(match_end + start, 
                                         fields, nr_fields, 1, pdr)))
          append(line, word, &line_p, MAXKWICLINELEN);
        
        this_token_end = line_p;

        remember_this_position(match_end + start,
                               this_token_start, this_token_end,
                               position_list, nr_positions,
                               returned_positions);
      }
      else
        break;
    }

    break;

  case STRUC_CONTEXT:
  case ALIGN_CONTEXT:

    if (!cd->right_structure) {
      fprintf(stderr, "concordance.o/compose_kwic_line: rcontext attribute pointer is NULL\n");
      end = match_end + 20;
    }
    else {
      if (cd->right_type == ALIGN_CONTEXT) {
        /* context == alignment block */
        if (0 > (rng_n = cl_cpos2alg(cd->right_structure, match_end))) 
          end = match_end;
        else {
          assert(cd->right_width == 1);
          
          /* get end of source corpus alignment block */
          if (!cl_alg2cpos(cd->right_structure,
                           rng_n,
                           &rng_s, &rng_e, &rng_s, &rng_s))
            end = match_end;
          else
            end = rng_e;
        }
      }
      else {
        /* context == structural region(s) */
        if (0 > (rng_n = cl_cpos2struc(cd->right_structure, match_end)))
          end = match_end + 20;
        else {
          assert(cd->right_width >= 0);

          /* determine the upper range number */
          if (0> (nr_ranges = cl_max_struc(cd->right_structure)))
            end = match_end + 20;
          else {
            rng_n = MIN(nr_ranges-1, rng_n + cd->right_width - 1);
            if (!cl_struc2cpos(cd->right_structure,
                               rng_n,
                               &rng_s, &rng_e)) 
            end = match_end + 20;
            else
              end = rng_e;
          }
        }
      }
    }

    if (match_end >= text_size)
      match_end = text_size - 1;

    for (start = match_end + 1; start <= end; start++) {
      
      token_p = 0;
      if (get_position_values(cd, 
                              start, 
                              token, &token_p, 
                              MAXKWICLINELEN, 
                              number_lines,
                              orientation,
                              pdr, 
                              nr_mappings, mappings)) {
        
        /* Trennzeichen einfügen, falls schon tokens in line drin sind */
        if (line_p > 0 && line_p < MAXKWICLINELEN)
          line[line_p++] = separator;

        this_token_start = line_p;
        
        if ((word = get_field_separators(start, fields, nr_fields, 0, pdr)))
          append(line, word, &line_p, MAXKWICLINELEN);
        
        append(line, pdr->BeforeToken, &line_p, MAXKWICLINELEN);
        append(line, token, &line_p, MAXKWICLINELEN);
        append(line, pdr->AfterToken, &line_p, MAXKWICLINELEN);

        if ((word = get_field_separators(start, fields, nr_fields, 1, pdr)))
          append(line, word, &line_p, MAXKWICLINELEN);
        
        this_token_end = line_p;

        remember_this_position(start,
                               this_token_start, this_token_end,
                               position_list, nr_positions,
                               returned_positions);
      }
      else
        break;
    }

    break;
  }

  append(line, pdr->AfterField, &line_p, MAXKWICLINELEN);

  line[line_p] = '\0';

  /* so, das war's ... :-) */

  *length = line_p;

  /* TODO: returned_positions richtig setzen */

  return cl_strdup(line);
}


ConcordanceLine 
MakeConcordanceLine(Corpus *corpus,
                    Attribute *attribute,
                    int focus_start_position,
                    int focus_end_position,
                    ContextDescriptor *context,
                    int nr_fields,
                    ConcLineField *fields)
{
  return NULL;
}

void FreeConcordanceLine(ConcordanceLine *line_p)
{
  if (line_p) {

    ConcordanceLine line = *line_p;

    if (line->type == 0) {

      /* simple string */
      
      if (line->simpleString.s) {
        free(line->simpleString.s);
        line->simpleString.s = NULL;
      }
      
    }
    else {

      int i;

      for (i = 0; i < line->nestedString.nr_subelements; i++)
        FreeConcordanceLine(&(line->nestedString.subElements[i]));

    }

    free(*line_p);

    *line_p = NULL;

  }
}

