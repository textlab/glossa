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
#include <assert.h>
#include <string.h>
#include <limits.h>
#include <math.h>
/* we can't include <search.h> since we then get conflicts with leaf type */


#include <sys/types.h>         /* required for regex */

#include "../cl/globals.h"
#include "../cl/macros.h"
#include "../cl/corpus.h"

#include <regex.h>                /* use the CWB regex package! */

#include "../cl/attributes.h"
#include "../cl/cdaccess.h"
#include "../cl/special-chars.h"

#include "cqp.h"
#include "ranges.h"
#include "options.h"
#include "tree.h"
#include "symtab.h"
#include "corpmanag.h"
#include "regex2dfa.h"
#include "eval.h"
#include "builtins.h"
#include "output.h"
#include "matchlist.h"


#define no_match -1

#define RED_THRESHOLD 0.01




int
nr_positions(CorpusList *cp)
{
  int nr_pos, i;

  assert(cp);
  
  nr_pos = -1;
  
  if (cp->size >= 0) {
    nr_pos = 0;

    for (i = 0; i < cp->size; i++)
      nr_pos += cp->range[i].end - cp->range[i].start + 1;
    
  }
  
  return nr_pos;
}

float
red_factor(CorpusList *cp, int *nr_pos)
{
  int size;
  Attribute *attr;

  assert(cp);

  if (!access_corpus(cp))
    return 0.0;
  
  if ((attr = find_attribute(cp->corpus, DEFAULT_ATT_NAME, ATT_POS, NULL)) == NULL)
    return 0.0;

  if ((size = cp->mother_size) < 0)
    return 0.0;

  if ((*nr_pos = nr_positions(cp)) < 0)
    return 0.0;

  return (*nr_pos + 0.0) / (size + 0.0);
}

/* set the appropriate values to the corpus id (given by its pointer to */
/* the symbol table).                                                   */
void
set_corpus_matchlists(CorpusList *cp,
                      Matchlist *matchlist,
                      int nr_lists,
                      int keep_old_ranges)
{
  int i;
  
  if (keep_old_ranges) {

    int rp, mp;

    /* delete the ranges which didn't lead to a match */

    /* TODO: Interaction with target @ settings */

    cl_free(cp->sortidx);
 
    /* keep keywords, ranges, targets */


    mp = 0;
    rp = 0;

    while (rp < cp->size) {

      if (mp < matchlist[0].tabsize) {

        if (matchlist[0].start[mp] >= cp->range[rp].start) {

          if (matchlist[0].start[mp] > cp->range[rp].end ||
              matchlist[0].end[mp] > cp->range[rp].end) {
            /* the match is not wholly within the current range */
            cp->range[rp++].start = -1;
          }
          else {

            /* this match lies within the current range. So keep
             * that range and increment.
             */

            rp ++;

          }
        }
        else
          /* match.start < range.start */
          mp++;
      }
      else {

        /* mp >= matchlist[0].tabsize */
        /* we can't find a matchlist element, so mark the range as deleted */

        cp->range[rp++].start = -1;
      }
    }
    
    (void) RangeSetop(cp, RReduce, NULL, NULL);
    
  }
  else {
    cl_free(cp->range);
    cl_free(cp->targets);
    cl_free(cp->keywords);
    cl_free(cp->sortidx);

    if (matchlist[0].tabsize > 0)
      cp->range = 
        (Range *)cl_malloc(sizeof(Range) * matchlist[0].tabsize);
    
    cp->size = matchlist[0].tabsize;
    
    for (i = 0; i < matchlist[0].tabsize; i++) {
      cp->range[i].start = matchlist[0].start[i];
      cp->range[i].end   = matchlist[0].end[i];
    }
    
    if (matchlist[0].target_positions) {
      cp->targets = matchlist[0].target_positions;
      matchlist[0].target_positions = NULL;
    }

    assert((nr_lists <= 1) && "set_corpus_matchlists(): multiple lists not supported!");
  }
}



int
get_corpus_positions(Attribute *attribute,
                     char *wordform,
                     Matchlist *matchlist)
{

  int word_id;

  assert(attribute);
  assert(matchlist);
  assert(matchlist->start == NULL);

  word_id = get_id_of_string(attribute, wordform);
  
  if ((word_id >= 0) && (cderrno == CDA_OK)) {

    /* get the positions of the id in the attribute */
    matchlist->start = collect_matches(attribute,
                                       &word_id,
                                       1,
                                       1,
                                       &(matchlist->tabsize),
                                       NULL, 0);
    matchlist->matches_whole_corpus = 0;
  }

  if (initial_matchlist_debug &&
      (matchlist->start != NULL) &&
      (matchlist->tabsize > 0) && !silent)
    fprintf(stderr, "matched initial wordform for non-regex %s, "
            "%d matches\n", wordform, matchlist->tabsize);

  return(matchlist->tabsize);
}


/**
 * Get corpus positions matching a regular expression on a given attribute.
 *
 * get_matched_corpus_positions looks in a corpus which is to be loaded for
 * a regular expression 'regstr' of attribute 'attr' and returns the table
 * of matching start indices (start_table) and the tablesize (tabsize).
 *
 * @param attribute        The attribute to search on. May be NULL, in which case DEFAULT_ATT_NAME is used.
 * @param regstr           String containing the regular expression.
 * @param canonicalize     Flags to be passed to the CL regex engine.
 * @param matchlist        Location where the list of matches will be placed.
 * @param restrictor_list  ??
 * @param restrictor_size  ??
 * @return                 The number of matches found.
 */
int
get_matched_corpus_positions(Attribute *attribute,
                             char *regstr,
                             int canonicalize,
                             Matchlist *matchlist,
                             int *restrictor_list,
                             int restrictor_size)
{
  int *word_ids, nr_of_words, i, size, range;

  assert(matchlist);
  assert(matchlist->start == NULL);

  matchlist->is_inverted = 0;

  if (attribute == NULL)
    attribute = find_attribute(evalenv->query_corpus->corpus,
                               DEFAULT_ATT_NAME,
                               ATT_POS, NULL);

  assert(attribute);

  size = get_attribute_size(attribute);
  range = get_id_range(attribute);
  
  /* changed .* / .+ optimization to .* only -- so "" will be handled correctly as an attribute value
     (will be standard in CWB 4.0, and may happen now if someone runs encode with -U "") */
  if (STREQ(regstr, ".*")) {
    if (eval_debug) 
      fprintf(stderr, "get_matched_corpus_positions: */+ optimization\n");
    
    matchlist->start = (int *)cl_malloc(sizeof(int) * size);

    /* we here produce a copy of a system corpus. TODO: optimize that
     * with the "matches_whole_corpus"-flag.
     */

    for (i = 0; i < size; i++)
      matchlist->start[i] = i;
    matchlist->tabsize = size;
    matchlist->matches_whole_corpus = 1;
  }
  else {
    
    /* get the word ids of the word forms which are matched by the 
     * regular expression  'regstr' 
     */

    word_ids = collect_matching_ids(attribute,
                                    regstr,
                                    canonicalize,
                                    &nr_of_words);

    if (nr_of_words == range) {
      
      /* again, matches whole corpus. TODO: optimize.
       */
      
      matchlist->start = (int *)cl_malloc(sizeof(int) * size);
      
      /* we here produce a copy of a system corpus. TODO: optimize that
       * with the "matches_whole_corpus"-flag.
       */
      
      for (i = 0; i < size; i++)
        matchlist->start[i] = i;
      matchlist->tabsize = size;
      matchlist->matches_whole_corpus = 1;

      cl_free(word_ids);

    }
    else if ((word_ids != NULL) && (nr_of_words > 0)) {

      /* are there any matching word forms? */
      
      /* get the position numbers in the active corpus of the word ids */
      matchlist->start = collect_matches(attribute,
                                         word_ids,
                                         nr_of_words,
                                         1,
                                         &(matchlist->tabsize),
                                         restrictor_list,
                                         restrictor_size);
      cl_free(word_ids);
    }
    else {
      matchlist->tabsize = 0;
      matchlist->matches_whole_corpus = 0;
    }
  }

  if (initial_matchlist_debug && 
      (matchlist->start != NULL) &&
      (matchlist->tabsize > 0) && !silent)
    fprintf(stderr, "matched initial pattern for regex %s, "
            "%d matches\n",
            regstr,
            matchlist->tabsize);

  return(matchlist->tabsize);
}



/*
 * This is the function which evaluates an AVS to true or false.
 */
/* labelrefs is the reference table for the current state (needed to set labels/targets) */
/* target_labelrefs is the reference table of the target state; if the constraint is fulfilled, */
/* eval_constraint() has to copy labelrefs to target_labelrefs and set labels there. */
Boolean
eval_constraint(AVS avs, int corppos, RefTab labelrefs, RefTab target_labelrefs)
{
  int start, end, struc, anchor;
  int result = False;
  CorpusList *corpus;

  switch (avs->type) {
  case Tag:
    struc = cl_cpos2struc(avs->tag.attr, corppos);
    if (struc < 0)
      return False;
    cl_struc2cpos(avs->tag.attr, struc, &start, &end);

    /* opening tag */
    if (avs->tag.is_closing == False) {
      result = (corppos == start) ? True : False;
      /* evaluate optional constraint only when at start of region */
      if (result && avs->tag.constraint) {
        char *val = cl_struc2str(avs->tag.attr, struc);
        if (val) {
          if (avs->tag.rx)
            result = cl_regex_match(avs->tag.rx, val); /* pre-compiled regex available */
          else
            result = (0 == strcmp(avs->tag.constraint, val)); /* no pre-compiled regex -> match as plain string */
        }
        else
          result = False;
        if (avs->tag.negated)
          result = !result;
      }
    }
    /* closing tag */
    else {
      result = (corppos == end) ? True : False;
      if (strict_regions && (avs->tag.right_boundary != NULL)) {
        int rbound = get_reftab(labelrefs, avs->tag.right_boundary->ref, -1);
        if ((rbound < 0) || (corppos != rbound))  /* check that a within region constraint was set by an open tag, and that this is the matching close tag! */
          result = False;                          /* (so that <s> []* </s> will work and <s></s> won't match, plus some more exotic cases) */
      }
    }

    if (result) {
      dup_reftab(labelrefs, target_labelrefs);
      /* in StrictRegions mode, set corresponding label (open tag) or clear it (close tag) */
      if (strict_regions && (avs->tag.right_boundary != NULL)) {
        if (avs->tag.is_closing == False) /* open tag */
          set_reftab(target_labelrefs, avs->tag.right_boundary->ref, end);
        else                                     /* close tag */
          set_reftab(target_labelrefs, avs->tag.right_boundary->ref, -1);
      }
      
    }
    return result;

  case Anchor:
    corpus = evalenv->query_corpus;
    switch (avs->anchor.field) {
    case MatchField:
      anchor = corpus->range[evalenv->rp].start;
      break;
    case MatchEndField:
      anchor = corpus->range[evalenv->rp].end;
      break;
    case TargetField:
      assert("Internal error in eval_constraint()" && corpus->targets != NULL);
      anchor = corpus->targets[evalenv->rp];
      break;
    case KeywordField:
      assert("Internal error in eval_constraint()" && corpus->keywords != NULL);
      anchor = corpus->keywords[evalenv->rp];
      break;
    default:
      assert("Internal error in eval_constraint(): no handler for anchor." && 0);
    }
    /* we don't have to worry about whether it's an opening or closing anchor tag,
     * because corppos already is the _effective_ cpos (passed from simulate()) */
    result = ((anchor >= 0) && (anchor == corppos)) ? True : False;

    /* don't forget to copy the reftab to the target state */
    if (result) 
      dup_reftab(labelrefs, target_labelrefs);
    return result;

  case Pattern:

    /* used to reset the list of labels (kill forward references) here */
    /* Ah great, so labels can only be set by the _last_ active candidate,
       because it will erase all the labels set by earlier candidates for
       this point. However, if we keep labels pointing to the current 
       cpos, we should be OK (assuming that all states progress in parallel 
       along the corpus). This should enable us to get optional labels at
       least. If several candidates pass through the same labelled pattern
       at different times, though, that label will be re-set whenever
       a candidate arrives; this is simply because CQP doesn't have a full 
       labels implementation. Rats.
       */
    
    /* if (evalenv->labels) 
         reset_labellist(evalenv->labels, corppos+1); */
    /* we're resetting from corppos+1 because another active state may just
       have set a label to the current corppos! */

    /* Got some rat poison now, i.e. a new labels implementation !!! */


  
    /* now evaluate the pattern */

    result = eval_bool(avs->con.constraint, labelrefs, corppos);

    /* if the current constraint is labelled, set the 
       corresponding label value; but _only_ if result is True,
       i.e. if the automaton actually reaches that state! 
     */

    if (result) {
      dup_reftab(labelrefs, target_labelrefs); /* copy labels to target state & set label there*/
      if (avs->con.label != NULL)
        set_reftab(target_labelrefs, avs->con.label->ref, corppos);
    }
   
    /* return the evaluation of the bool tree of the constraint */
    return result;

  case MatchAll:
    /* if (evalenv->labels)            !!! RAT POISON !!!
       reset_labellist(evalenv->labels, corppos+1);     */
    dup_reftab(labelrefs, target_labelrefs);
    if (avs->matchall.label != NULL)
      set_reftab(target_labelrefs, avs->matchall.label->ref, corppos);
    return True;
  }
  assert(0 && "Not reached");
  return 0;
}




/* get the corpus position referenced by a label wrt. to the reference table rt */
/* (corppos used to be required for anchor labels, which are now removed, but it'll be useful for the 'this' label) */
int 
get_label_referenced_position(LabelEntry label, RefTab rt, int corppos)
{
  int referenced_position = -1;

  if (label) {
    referenced_position = get_reftab(rt, label->ref, corppos);
    if (eval_debug) 
      fprintf(stderr, "Evaluating label %s = %d\n", label->name, referenced_position);
  }

  return referenced_position;
}



Boolean
get_leaf_value(Constrainttree ctptr,
               RefTab rt, /* label reference table of the current simulation */
               int corppos,
               DynCallResult *dcr,
               int deliver_strings)
{
  int pos, rv;
  DynCallResult *fargs;
  ActualParamList *p;
  Boolean params_ok;

  int struc_start, struc_end;

  assert(ctptr);

  dcr->type = ATTAT_NONE;

  switch (ctptr->type) {
  case func:

    if (ctptr->func.nr_args > 0) {

      fargs = (DynCallResult *)cl_malloc(sizeof(DynCallResult) * ctptr->func.nr_args);
      if (fargs == NULL)
        return False;
      
      pos = 0;
      params_ok = True;
      for (p = ctptr->func.args; (p != NULL) &&
                                 (pos < ctptr->func.nr_args) &&
                                 params_ok;
           p = p->next, pos++)
        params_ok = get_leaf_value(p->param, rt, corppos, &(fargs[pos]), 1);
      
      /* we don't want to crash when one of the args can't be computed!) */
      assert(!params_ok || pos == ctptr->func.nr_args);

      if (params_ok) {

        if (ctptr->func.predef >= 0) {
          rv = call_predefined_function(ctptr->func.predef,
                                        fargs,
                                        pos,
                                        ctptr,
                                        dcr);
          free(fargs);
          /* if the evaluation of a builtin function fails, this is usually due to a usage error;
             -> abort query evaluation to avoid hundreds or thousands of error messages (simulate Ctrl-C signal) */
          if (!rv)
            EvaluationIsRunning = 0;
          return rv;
        }
        else {

          assert(ctptr->func.dynattr);

          pos = call_dynamic_attribute(ctptr->func.dynattr,
                                       dcr,
                                       fargs,
                                       ctptr->func.nr_args);
          free(fargs);
          return ((pos == 1) && (cderrno == CDA_OK)) ? True : False;

        }
      }
      else {
        /* parameter cannot be calculated */
        free(fargs);
        return False;
      }
    }
    else
      return False;
    break;

  case pa_ref:

    if (ctptr->pa_ref.attr == NULL) {

      /* label reference without an attribute -> returns referenced corpus position */

      assert(ctptr->pa_ref.label);

      dcr->type = ATTAT_POS;
      dcr->value.intres = get_label_referenced_position(ctptr->pa_ref.label, rt, corppos);
      if (ctptr->pa_ref.delete) {
        if (eval_debug)
          fprintf(stderr, "** AUTO-DELETING LABEL %s = %d\n",
                 ctptr->pa_ref.label->name, dcr->value.intres);
        set_reftab(rt, ctptr->pa_ref.label->ref, -1);
      }
      return True;
    }
    else {

      int referenced_position;

      if (ctptr->pa_ref.label == NULL)
        referenced_position = corppos;
      else {

        referenced_position = get_label_referenced_position(ctptr->pa_ref.label, rt, corppos);
        if (ctptr->pa_ref.delete) {
          if (eval_debug)
            fprintf(stderr, "** AUTO-DELETING LABEL %s = %d\n",
                   ctptr->pa_ref.label->name, referenced_position);
          set_reftab(rt, ctptr->pa_ref.label->ref, -1);
        }

        if (referenced_position < 0) {
          dcr->type = ATTAT_NONE;
          return True;
        }
      }

      if (deliver_strings) {
        dcr->type = ATTAT_STRING;
        dcr->value.charres = get_string_at_position(ctptr->pa_ref.attr,
                                                    referenced_position);
      }
      else {
        dcr->type = ATTAT_PAREF;
        dcr->value.parefres.attr = ctptr->pa_ref.attr;

        assert(dcr->value.parefres.attr);

        dcr->value.parefres.token_id = get_id_at_position(ctptr->pa_ref.attr,
                                                          referenced_position);
      }
      return (cderrno == CDA_OK) ? True : False;
    }
    break;

  case sa_ref:

    if (ctptr->sa_ref.label == NULL) {
      /* bare reference to S-attribute -> old behaviour */
      dcr->type = ATTAT_INT;
      dcr->value.intres = 0;
      if (get_struc_attribute(ctptr->sa_ref.attr, 
                              corppos,
                              &struc_start, &struc_end)) {

        if (corppos  == struc_start)
          dcr->value.intres += 1;

        if (corppos == struc_end)
          dcr->value.intres += 2;

        /* new: make sure the value of an saref (without values) is
           non-zero (i.e. evaluates to True) as long as we are within a region */
        if ((corppos >= struc_start) && (corppos <= struc_end))
          dcr->value.intres += 4;
        /* not really necessary, since get_struc_attribute() returns 0 if we're not inside a region */
      }
      else if (cderrno != CDA_OK) { /* get_struc_attribtue() sets cderrno=CDA_OK if not in region */
        return False;                /* this _is_ an error */
      }
      
      return True;
    }
    else {
      /* label reference to S-attribute -> return value of containing region */
      int referenced_position = get_label_referenced_position(ctptr->sa_ref.label, rt, corppos);
      
      if (ctptr->sa_ref.delete) {
        if (eval_debug)
          fprintf(stderr, "** AUTO-DELETING LABEL %s = %d\n",
                 ctptr->sa_ref.label->name, referenced_position);
        set_reftab(rt, ctptr->sa_ref.label->ref, -1);
      }

      if (referenced_position < 0) {
        dcr->type = ATTAT_NONE;        /* don't know what it does; copied from pa_ref */
        return True;
      }

      dcr->type = ATTAT_STRING;
      dcr->value.charres = structure_value_at_position(ctptr->sa_ref.attr, 
                                                       referenced_position);

      /* structure_value_at_position() sets CDA_EPOSORNG if not in region */
      if (cderrno == CDA_EPOSORNG) {
        dcr->type = ATTAT_NONE;        /* reasonable behaviour: return ATTAT_NONE if not in region */
        return True;
      }

      return (cderrno == CDA_OK) ? True : False;
    }
    break;

  case string_leaf:

    if (ctptr->leaf.pat_type == CID) {

      /*
       * that's quick & dirty. We should have a cidref node 
       */

      dcr->type = ATTAT_INT;
      dcr->value.intres = ctptr->leaf.ctype.cidconst;
    }
    else {
      dcr->type = ATTAT_STRING;
      dcr->value.charres = ctptr->leaf.ctype.sconst;
    }
    return True;
    break;

  case float_leaf:
    dcr->type = ATTAT_FLOAT;
    dcr->value.floatres = ctptr->leaf.ctype.fconst;
    break;

  case int_leaf:
    dcr->type = ATTAT_INT;
    dcr->value.intres = ctptr->leaf.ctype.iconst;
    return True;
    break;

  default:
    cqpmessage(Error, 
               "get_leaf_value(): Illegal node type %d\n",
               __FILE__, ctptr->type);
    EvaluationIsRunning = 0;
    return False;
    break;
  }
  assert(0 && "Not reached");
  return 0;
}



/* evaluate the boolean constraint tree by using recursion
 * "corppos" is the current corpus position 
 */

static
int
intcompare(const void *i, const void *j)
{
  return(*(int *)i - *(int *)j);
}

Boolean
eval_bool(Constrainttree ctptr, RefTab rt, int corppos)
{
  DynCallResult lhs, rhs;
  int start, end, id;
  int referenced_corppos;

  if (ctptr)
    if (ctptr->type == bnode) {
      switch(ctptr->node.op_id) {

        /* logical and */
      case b_and: 
        if (eval_debug)
          fprintf(stderr, "eval_bool: evaluate boolean and\n");
        assert((ctptr->node.left != NULL) && (ctptr->node.right != NULL));
        return(eval_bool(ctptr->node.left, rt, corppos) &&
               eval_bool(ctptr->node.right, rt, corppos));
        break;

        /* logical or */
      case b_or:
        if (eval_debug)
          fprintf(stderr, "eval_bool: evaluate boolean or\n");
        assert((ctptr->node.left != NULL) && (ctptr->node.right != NULL));

        return(eval_bool(ctptr->node.left, rt, corppos) ||
               eval_bool(ctptr->node.right, rt, corppos));
        break;

        /* logical implication */
      case b_implies:
        if (eval_debug)
          fprintf(stderr, "eval_bool: evaluate boolean implication\n");
        assert((ctptr->node.left != NULL) && (ctptr->node.right != NULL));

        return((eval_bool(ctptr->node.left, rt, corppos)) ? eval_bool(ctptr->node.right, rt, corppos) : True);
        break;

        /* logical not */
      case b_not:
        if (eval_debug)
          fprintf(stderr, "eval_bool: evaluate boolean not\n");

        if (!ctptr->node.left)
          return(True);

        assert(ctptr->node.right == NULL);
        return(!eval_bool(ctptr->node.left, rt, corppos));
        break;

        /* relational operators */
      case cmp_gt:
      case cmp_lt:
      case cmp_get:
      case cmp_let:
      case cmp_eq:
      case cmp_neq:
      case cmp_ex:

        if (eval_debug)
          fprintf(stderr, "eval_bool: evaluate comparisons\n");

        /* check presence of arguments */
        assert((ctptr->node.left != NULL) &&
               ((ctptr->node.op_id == cmp_ex) || (ctptr->node.right != NULL)));

        /*
         * LHS:
         *  -- Attribute reference (type String)
         *  -- Function call       (type String or Integer)
         *  -- Qualified Label reference (type String)
         */

        switch (ctptr->node.left->type) {
        case func:
        case pa_ref:
        case sa_ref:                /* label refernce to S-attribute with values */
          if (get_leaf_value(ctptr->node.left, rt, corppos, &lhs, 0) == False)
            return False;
          break;

        default:
          cqpmessage(Error,
                     "Illegal type (%d) of LHS argument in pattern.",
                     ctptr->node.left->type);
          EvaluationIsRunning = 0;
          return False;
          break;
        }

        /* if we only check for existence of a value, the RHS is neglected */
        if (ctptr->node.op_id == cmp_ex)
          switch (lhs.type) {
          case ATTAT_STRING:
            return (lhs.value.charres != NULL);
            break;

          case ATTAT_PAREF:
            return (lhs.value.parefres.token_id >= 0 ? 1 : 0);
            break;

          case ATTAT_FLOAT:
            return (lhs.value.floatres == 0.0 ? 0 : 1);
            break;

          case ATTAT_INT:
            return (lhs.value.intres == 0) ? 0 : 1;
            break;

          case ATTAT_POS:        /* returned by bare label references */
            return (lhs.value.intres >= 0) ? 1 : 0;
            break;

          case ATTAT_NONE:        /* undefined value, always evaluates to False */
            return 0;
            break;

          default:
            cqpmessage(Error,
                       "Illegal type (%d) of existence expression.",
                       lhs.type);
            EvaluationIsRunning = 0;
            return False;
          }

        /* otherwise, we have to compute & check the RHS */

        assert(ctptr->node.right != NULL);

        switch(ctptr->node.right->type) {
        case func:
        case pa_ref:
        case sa_ref:
        case int_leaf:
        case float_leaf:
        case string_leaf:
          if (get_leaf_value(ctptr->node.right, rt, corppos, &rhs, 0) == False)
            return False;
          break;

        default:
          cqpmessage(Error,
                     "Illegal type (%d) of RHS argument in pattern.",
                  ctptr->node.right->type);
          EvaluationIsRunning = 0;
          return False;
          break;
        }


        /* OK. We now evaluate the relational operator */

        /* make it easier in case of ints */
        if (lhs.type == ATTAT_POS)
          lhs.type = ATTAT_INT;
        if (rhs.type == ATTAT_POS)
          rhs.type = ATTAT_INT;

        if ((lhs.type == ATTAT_NONE) || (rhs.type == ATTAT_NONE))
          /* cannot evaluate */
          return False;


        if (lhs.type == ATTAT_PAREF && rhs.type == ATTAT_INT) {

          if (ctptr->node.op_id == cmp_eq)
             return (lhs.value.parefres.token_id == rhs.value.intres ? 1 : 0);
          else if (ctptr->node.op_id == cmp_neq)
             return (lhs.value.parefres.token_id != rhs.value.intres ? 1 : 0);
          else {
            cqpmessage(Error,
                       "Comparison operators >, >=, <, <= not allowed for p-attribute.");
            EvaluationIsRunning = 0;
            return False;
          }
        }
        else if (lhs.type == ATTAT_PAREF && rhs.type == ATTAT_PAREF) {

          if (lhs.value.parefres.attr == NULL || rhs.value.parefres.attr == NULL) {
            cqpmessage(Error,
                       "Missing p-attribute on PAREF (lhs or rhs)");
            EvaluationIsRunning = 0;
            return False;
          }
          else if (lhs.value.parefres.attr == rhs.value.parefres.attr)
            switch (ctptr->node.op_id) {
            case cmp_eq:
              return lhs.value.parefres.token_id == rhs.value.parefres.token_id;
              break;
            case cmp_neq:
              return lhs.value.parefres.token_id != rhs.value.parefres.token_id;
              break;
            default:
              cqpmessage(Error,
                         "Comparison operators >, >=, <, <= not allowed between p-attributes.");
              EvaluationIsRunning = 0;
              return False;
              break;
            }
          else {

            char *ls, *rs;

            ls = get_string_of_id(lhs.value.parefres.attr, lhs.value.parefres.token_id);
            rs = get_string_of_id(rhs.value.parefres.attr, rhs.value.parefres.token_id);

            switch (ctptr->node.op_id) {
            case cmp_eq:
              return strcmp(ls, rs) == 0;
              break;
            case cmp_neq:
              return strcmp(ls, rs) != 0;
              break;
            default:
              cqpmessage(Error,
                         "Comparison operators >, >=, <, <= not allowed between p-attributes.");
              EvaluationIsRunning = 0;
              return False;
              break;
            }
          }
        }
        else if ((lhs.type == ATTAT_PAREF || lhs.type == ATTAT_STRING)
                 && (rhs.type == ATTAT_STRING || rhs.type == ATTAT_PAREF)) {

          /* ok. we have strings or parefs on both sides. we cannot have
           * parefs both left and right, since this is handled above.
           */

          char *ls, *rs;

          ls = NULL; rs = NULL;

          if (lhs.type == ATTAT_PAREF) {
            assert(lhs.value.parefres.attr);
            ls = get_string_of_id(lhs.value.parefres.attr, lhs.value.parefres.token_id);
            if ((ls == NULL) || cderrno != CDA_OK) {
              cqpmessage(Error,
                         "Error accessing p-attribute %s (lexicon ID #%d).",
                          lhs.value.parefres.attr->any.name, lhs.value.parefres.token_id);
              EvaluationIsRunning = 0;
              return False;
            }
          }
          else
            ls = lhs.value.charres;

          if (rhs.type == ATTAT_PAREF) {
            assert(rhs.value.parefres.attr);
            rs = get_string_of_id(rhs.value.parefres.attr, rhs.value.parefres.token_id);
            if ((rs == NULL) || cderrno != CDA_OK) {
              cqpmessage(Error,
                         "Error accessing p-attribute %s (lexicon ID #%d).",
                          rhs.value.parefres.attr->any.name, rhs.value.parefres.token_id);
              EvaluationIsRunning = 0;
              return False;
            }
          }
          else
            rs = rhs.value.charres;

          assert(rs && ls);

          assert(ctptr->node.right);

          /* The string on the right sight can be either a RegExp or a literal string.
             RegExps may only occur in string leafs, i.e. strings entered directly in the
             query. All other string values (such as paref's or saref's or return values
             of function calls are literal strings */
          if ((ctptr->node.right->type != string_leaf) ||
              (ctptr->node.right->leaf.pat_type == NORMAL))
            /* literal string */
            return ((ctptr->node.op_id == cmp_eq) ? STREQ(ls, rs) : !STREQ(ls, rs));

          else if (ctptr->node.right->leaf.pat_type == REGEXP) {
            /* RegExp */
            if (STREQ(rs, ".*")) /* see note about .* / .+ optimization above  */

              return (ctptr->node.op_id == cmp_eq) ? True : False;

            else {

              /* perform a regular expression match of the two */
              return((ctptr->node.op_id == cmp_eq) ?
                     cl_regex_match(ctptr->node.right->leaf.rx, ls) :
                     !cl_regex_match(ctptr->node.right->leaf.rx, ls));
            }
          }
          else {
            cqpmessage(Error,
                       "Internal error in eval_bool()<eval.c>: right->pat_type == CID???");
            EvaluationIsRunning = 0;
            return False;
          }
        }

        if (lhs.type != rhs.type) {
          cqpmessage(Error,
                     "LHS type (%d) doesn't match RHS type (%d), can't compare.",
                     lhs.type, rhs.type);
          EvaluationIsRunning = 0;
          return False;
        }

        switch (lhs.type) {
        case ATTAT_INT:

          switch (ctptr->node.op_id) {
          case cmp_gt:
            return lhs.value.intres > rhs.value.intres;
            break;
          case cmp_lt:
            return lhs.value.intres < rhs.value.intres;
            break;
          case cmp_get:
            return lhs.value.intres >= rhs.value.intres;
            break;
          case cmp_let:
            return lhs.value.intres <= rhs.value.intres;
            break;
          case cmp_eq:
            return lhs.value.intres == rhs.value.intres;
            break;
          case cmp_neq:
            return lhs.value.intres != rhs.value.intres;
            break;
          default:
            cqpmessage(Error,
                       "Illegal numerical comparison operator (%d).",
                       ctptr->node.op_id);
            EvaluationIsRunning = 0;
            return False;
            break;
          }
          break;

        case ATTAT_FLOAT:

          switch (ctptr->node.op_id) {
          case cmp_gt:
            return lhs.value.floatres > rhs.value.floatres;
            break;
          case cmp_lt:
            return lhs.value.floatres < rhs.value.floatres;
            break;
          case cmp_get:
            return lhs.value.floatres >= rhs.value.floatres;
            break;
          case cmp_let:
            return lhs.value.floatres <= rhs.value.floatres;
            break;
          case cmp_eq:
            return lhs.value.floatres == rhs.value.floatres;
            break;
          case cmp_neq:
            return lhs.value.floatres != rhs.value.floatres;
            break;
          default:
            cqpmessage(Error,
                       "Illegal numerical comparison operator (%d).",
                       ctptr->node.op_id);
            EvaluationIsRunning = 0;
            return False;
            break;
          }
          break;

        case ATTAT_PAREF:
        case ATTAT_STRING:
        case ATTAT_POS:
        case ATTAT_VAR:
        default:
          assert(0);
          break;

        }

        /* are we still here? */

        assert("In principle, this should be a non-reachable point. Sorry." && 0);
        break;

      default:
        cqpmessage(Error,
                   "Illegal boolean operand (%d) in pattern.\n",
                   ctptr->node.op_id);
        EvaluationIsRunning = 0;
        return False;
        break;
      }
    }
    else if (ctptr->type == cnode) {
      return ctptr->constnode.val == 0 ? False : True;
    }
    else if (ctptr->type == id_list) {
      int res;

      if (eval_debug)
        fprintf(stderr, "eval_bool: evaluate id_list membership\n");

      assert(ctptr->idlist.attr);

      if (ctptr->idlist.label) {
        referenced_corppos = get_label_referenced_position(ctptr->idlist.label, rt, corppos);
        if (ctptr->idlist.delete) {
          if (eval_debug)
            fprintf(stderr, "** AUTO-DELETING LABEL %s = %d\n",
                   ctptr->idlist.label->name, referenced_corppos);
          set_reftab(rt, ctptr->idlist.label->ref, -1);
        }
      }
      else {
        referenced_corppos = corppos;
      }

      if (ctptr->idlist.nr_items <= 0)
        res = 0;                /* never member */
      else { 

        id = get_id_at_position(ctptr->idlist.attr, referenced_corppos);

        if (id >= 0)
          res = bsearch((char *)&id,
                        (char *)(ctptr->idlist.items),
                        ctptr->idlist.nr_items,
                        sizeof(int),
                        intcompare) == NULL ? 0 : 1;
        else
          res = 0;
      }

      if (ctptr->idlist.negated)
        return !res;
      else
        return res;
    }
    else if (ctptr->type == sbound) {

      assert("Not reached any more" && 0 && ctptr->sbound.strucattr != NULL);

      if (!get_struc_attribute(ctptr->sbound.strucattr, corppos, &start, &end) ||
          (cderrno != CDA_OK))
        return False;
      else {
        if (ctptr->sbound.is_closing == False)
          /* opening tag */
          return (corppos == start) ? True : False;
        else
          /* closing tag */
          return (corppos == end) ? True : False;
      }
    } 
    else {
      cqpmessage(Error, 
                 "Internal error in eval_bool()<eval.c>: Illegal node type %d.",
                 ctptr->type);
      EvaluationIsRunning = 0;
      return False;
    }
  else
    return(True);

  assert(0 && "Not reached");
  return 0;
}




int mark_offrange_cells(Matchlist *matchlist, 
                        CorpusList *corpus)
{
  int rp, i, del;

  rp = 0;
  i = 0;
  del = 0;

  assert(matchlist);
  assert(corpus);

  /* this is only of importance when we are working on a subcorpus.
   * Test that. */

  assert(corpus->mother_size > 0);

  if ((corpus->size == 1) &&
      (corpus->range[0].start == 0) &&
      (corpus->range[0].end == corpus->mother_size - 1))
    
      return 0;
  
  while (i < matchlist->tabsize) {
      
    if ((rp >= corpus->size) ||
        (matchlist->start[i] < corpus->range[rp].start)) {
      matchlist->start[i] = -1;
      if (matchlist->end)
        matchlist->end[i] = -1;
      i++;
      del++;
    }
    else if (matchlist->start[i] > corpus->range[rp].end)
      rp++;
    else
      i++;
  }
  return del;
}




Boolean calculate_initial_matchlist_1(Constrainttree ctptr, 
                                      Matchlist *matchlist,
                                      CorpusList *corpus)
{
  int   i;

  Matchlist left, right;

  /* do NOT use free_matchlist here! */

  init_matchlist(&left);
  init_matchlist(&right);

  if (ctptr) {

    if (ctptr->type == bnode) {
      switch(ctptr->node.op_id) {

      case b_and:                /* logical and */

        assert(ctptr->node.left && ctptr->node.right);

        /* just the beginnings of an implementation for the b_and operator (by oli);
           never mind, the entire <eval.c> code will have to be rewritten for CWB-3.0 */
#ifdef INITIAL_MATCH_BY_MU

        if (calculate_initial_matchlist_1(ctptr->node.left, &left, corpus) &&
            calculate_initial_matchlist_1(ctptr->node.right, &right, corpus)) {

          Setop(&left, Intersection, &right);

          free_matchlist(&right);

          matchlist->start = left.start;
          matchlist->end   = left.end;
          matchlist->tabsize = left.tabsize;
          matchlist->matches_whole_corpus = 0;
          matchlist->is_inverted = 0;

          return True;
        }
        else {
          free_matchlist(matchlist)
          free_matchlist(&left);
          free_matchlist(&right);
          return False;
        }
#else

        /* this is the old code. */

        if (calculate_initial_matchlist_1(ctptr->node.left, &left, corpus)) {

          /* We have b_and. So try to eval the right tree for each
           * position yielded by the left tree. */

          for (i = 0; i < left.tabsize; i++) {
            if (!EvaluationIsRunning)
              break;
            if (left.start[i] >= 0 &&
                !eval_bool(ctptr->node.right, NULL, left.start[i]))
              /* we're ignoring labels at the moment, so we pass NULL as reftab */
              left.start[i] = -1;
          }

          if (!Setop(&left, Reduce, NULL))
            return False;

          matchlist->start = left.start;
          matchlist->end   = left.end;
          matchlist->tabsize = left.tabsize;
          matchlist->matches_whole_corpus = 0;

          return True;
        }
        else {
          free_matchlist(matchlist);
          free_matchlist(&left);
          free_matchlist(&right);
          return False;
        }
#endif

        break;

      case b_or:                /* logical or */

        if (eval_debug)
          fprintf(stderr, "calc_initial_ml: boolean or\n");

        assert(ctptr->node.left && ctptr->node.right);

        if (calculate_initial_matchlist_1(ctptr->node.left, &left, corpus) &&
            calculate_initial_matchlist_1(ctptr->node.right, &right, corpus)) {

          if (left.is_inverted)
            if (!Setop(&left, Complement, NULL))
              return False;

          if (right.is_inverted)
            if (!Setop(&right, Complement, NULL))
               return False;

          if (!Setop(&left, Union, &right))
            return False;

          free_matchlist(&right);

          matchlist->start = left.start;
          matchlist->end   = left.end;
          matchlist->tabsize = left.tabsize;
          matchlist->matches_whole_corpus = left.matches_whole_corpus;
          matchlist->is_inverted = 0;

          return True;
        }
        else {
          free_matchlist(matchlist);
          free_matchlist(&left);
          free_matchlist(&right);
          return False;
        }
        break;

      case b_implies:                /* logical implication (not optimised in query initial position) */

        /* for the moment, this is just a ridiculous dummy implementation; replace when tables are ready */
        /* matchlist should be initialised and empty, hence invert it to get list of all corpus positions */
        if (!Setop(matchlist, Complement, NULL))
          return False;

        mark_offrange_cells(matchlist, corpus);
        for (i = 0; i < matchlist->tabsize; i++) {
          if (!EvaluationIsRunning) {
            free_matchlist(matchlist);
            return False;
          }
          if (matchlist->start[i] >= 0 &&
              !eval_bool(ctptr, NULL, matchlist->start[i]))
            /* we're ignoring labels at the moment, so we pass NULL as reftab */
            matchlist->start[i] = -1;
        }

        if (!Setop(matchlist, Reduce, NULL))
          return False;

        return True;
        break;

      case b_not:                /* logical negation */

        if (eval_debug)
          fprintf(stderr, "calc_initial_ml: boolean not\n");

        assert(ctptr->node.left);

        if (calculate_initial_matchlist_1(ctptr->node.left,
                                          matchlist, corpus)) {

          if (!Setop(matchlist, Complement, NULL))
            return False;

          if (mark_offrange_cells(matchlist, corpus))
            if (!Setop(matchlist, Reduce, NULL))
              return False;

          return True;
        }
        else {
          free_matchlist(matchlist);
          return False;
        }

        break;

        /* relational operators */
      case cmp_gt:
      case cmp_lt:
      case cmp_get:
      case cmp_let:
      case cmp_eq:
      case cmp_neq:
      case cmp_ex:

        if (eval_debug)
          fprintf(stderr, "calc_initial_ml: evaluate comparisons\n");

        /* check argument types */

        assert((ctptr->node.left != NULL) &&
               ((ctptr->node.op_id == cmp_ex) || (ctptr->node.right != NULL)));

        /* on the left, there can be
         *   func
         *   pa_ref
         * on the right,
         *   string_leaf
         *   int_leaf
         * may occur additionally.
         */

        switch (ctptr->node.left->type) {

        case func:
        case sa_ref:
          /* for the moment, this is just a ridiculous dummy implementation; replace when tables are ready */
          /* matchlist should be initialised and empty, hence invert it to get list of all corpus positions */
          if (!Setop(matchlist, Complement, NULL))
            return False;

          mark_offrange_cells(matchlist, corpus);
          for (i = 0; i < matchlist->tabsize; i++) {
            if (!EvaluationIsRunning) {
              free_matchlist(matchlist);
              return False;
            }
            if (matchlist->start[i] >= 0 &&
                !eval_bool(ctptr, NULL, matchlist->start[i]))
              /* we're ignoring labels at the moment, so we pass NULL as reftab */
              matchlist->start[i] = -1;
          }

          if (!Setop(matchlist, Reduce, NULL))
            return False;

          return True;
          break;

        case pa_ref:

          if (ctptr->node.left->pa_ref.label) {
            /* this shouldn't happen because no labels are defined in query initial position */
            /* sadly, [_ = 1042] would be very useful, but it's a hell of a special case to implement here */
            cqpmessage(Error,
                       "Reference to label '%s' not allowed in query initial position.",
                       ctptr->node.left->pa_ref.label->name);
            return False;

          }
          else {

            /*
             * we have a non-labelled pa_ref on the left
             * should have a string atom on the right
             */

            if ((ctptr->node.right == NULL) ||
                (ctptr->node.right->type != string_leaf)) {
              /* for the moment, this is just a ridiculous dummy implementation; replace when tables are ready */
              /* matchlist should be initialised and empty, hence invert it to get list of all corpus positions */
              if (!Setop(matchlist, Complement, NULL))
                return False;

              mark_offrange_cells(matchlist, corpus);
              for (i = 0; i < matchlist->tabsize; i++) {
                if (!EvaluationIsRunning) {
                  free_matchlist(matchlist);
                  return False;
                }

                if (matchlist->start[i] >= 0 &&
                    !eval_bool(ctptr, NULL, matchlist->start[i]))
                  /* we're ignoring labels at the moment, so we pass NULL as reftab */
                  matchlist->start[i] = -1;
              }

              if (!Setop(matchlist, Reduce, NULL))
                return False;

              return True;
            }

            switch (ctptr->node.right->leaf.pat_type) {
            case REGEXP:

              /* check whether we have a ".+" or ".*" on the right --in this case
               * there is nothing to do (matched by everything)
               * TODO: change that in case "" may be returned by attribute access
               * --> removed ".+" optimisation, which may produce wrong results e.g. if LHS is function call
               */

              if ((strcmp(ctptr->node.right->leaf.ctype.sconst, ".*") == 0)) {
                if (ctptr->node.op_id == cmp_neq) {

                  /* every word is != ".*", so just return an empty match list */
                  free_matchlist(matchlist);
                  return True;

                }
                else {

                  /* return a copy of the corpus (expensive, but what shall we do)? */
                  get_matched_corpus_positions(ctptr->node.left->pa_ref.attr,
                                               ".*",
                                               0,
                                               matchlist,
                                               (int *)corpus->range,
                                               corpus->size);

                  if (mark_offrange_cells(matchlist, corpus))
                    if (!Setop(matchlist, Reduce, NULL))
                      return False;

                  return True;
                }
              }
              else {
                 get_matched_corpus_positions(ctptr->node.left->pa_ref.attr,
                                             ctptr->node.right->leaf.ctype.sconst,
                                             ctptr->node.right->leaf.canon,
                                             matchlist,
                                             (int *)corpus->range,
                                             corpus->size);
              }

              break;

            case NORMAL:

              get_corpus_positions(ctptr->node.left->pa_ref.attr,
                                   ctptr->node.right->leaf.ctype.sconst,
                                   matchlist);

              break;

            case CID:

              matchlist->start = get_positions(ctptr->node.left->pa_ref.attr,
                                               ctptr->node.right->leaf.ctype.cidconst,
                                               &(matchlist->tabsize),
                                               (int *)corpus->range,
                                               corpus->size);
              matchlist->matches_whole_corpus = 0;
              matchlist->is_inverted = 0;
              matchlist->end = NULL;

              break;

            default:
              cqpmessage(Error,
                         "Unknown pattern type (%d) on RHS of comparison operator.",
                         ctptr->node.right->leaf.pat_type);
              return False;
              break;
            }

            if (mark_offrange_cells(matchlist, corpus))
              if (!Setop(matchlist, Reduce, NULL))
                return False;

            if (ctptr->node.op_id == cmp_neq)
              if (!Setop(matchlist, Complement, NULL))
                return False;        /* Auswertung bei Speicherueberlauf abbrechen */
          }
          return(True);

          break;

        default:

          cqpmessage(Error,
                     "Wrong node type (%d) on LHS of comparison operator.",
                     ctptr->node.left->type);
          break;

        }   /* switch (ctptr->node.left->type) ... */
        break;

      default:

        assert("Internal error in calculate_initial_matchlist_1(): Unknown comparison operator." && 0);
        break;

      }     /* switch (ctptr->node.op_id) ... */
    }       
    else if (ctptr->type == cnode) {

      if (ctptr->constnode.val == 0) {
        matchlist->start = NULL;
        matchlist->end   = NULL;
        matchlist->tabsize = 0;
        matchlist->matches_whole_corpus = 0;
              matchlist->is_inverted = 0;
      }
      else {
        get_matched_corpus_positions(ctptr->node.left->pa_ref.attr,
                                     ".*",
                                     0,
                                     matchlist,
                                     (int *)corpus->range,
                                     corpus->size);
        if (mark_offrange_cells(matchlist, corpus))
          if (!Setop(matchlist, Reduce, NULL))
            return False;
      }

      return True;
    }
    else if (ctptr->type == id_list) {

      if (ctptr->idlist.label == NULL) {

        if (ctptr->idlist.nr_items > 0) {

          assert(ctptr->idlist.attr);

          matchlist->start = collect_matches(ctptr->idlist.attr,
                                             ctptr->idlist.items,
                                             ctptr->idlist.nr_items,
                                             1, /* sort: yes */
                                             &(matchlist->tabsize),
                                             NULL, 0);

          matchlist->end = NULL;
          matchlist->matches_whole_corpus = 0;
          matchlist->is_inverted = 0;
        }
        else {
          matchlist->start = NULL;
          matchlist->end   = NULL;
          matchlist->tabsize = 0;
          matchlist->matches_whole_corpus = 0;
          matchlist->is_inverted = 0;
        }

        if (ctptr->idlist.negated)
          if (!Setop(matchlist, Complement, NULL))
            return False;

        if (mark_offrange_cells(matchlist, corpus))
          if (!Setop(matchlist, Reduce, NULL))
            return False;

        return True;

      }
      else {

        cqpmessage(Error,
                   "Reference to label '%s' not allowed in query initial position.",
                   ctptr->node.left->idlist.label->name);
        return False;

      }    /* if (ctptr->idlist.label == NULL) ... else ... */
    }

    else {
      cqpmessage(Error, 
                 "Internal error in calculate_initial_matchlist_1()<eval.c>: Illegal node type %d.\n",
                 ctptr->type);
      return(False);
    }   /* if (ctptr->type == bnode) ... else if ...  */
  }
  else {

    return(True);

  }     /* if (ctptr) ...  */
  

  assert("Internal error in calculate_initial_matchlist1(): went over the edge." && 0);
  return 0;
}

Boolean calculate_initial_matchlist(Constrainttree ctptr, 
                                    Matchlist *matchlist,
                                    CorpusList *corpus)
{
  Boolean res;

  res = calculate_initial_matchlist_1(ctptr, matchlist, corpus);

  if (res && matchlist) {

    if (matchlist->is_inverted) {
      matchlist->is_inverted = 0;
      res = Setop(matchlist, Complement, NULL);
    }

    if (res && mark_offrange_cells(matchlist, corpus)) {
      res = Setop(matchlist, Reduce, NULL);
    }
  }

  return res;
}




/* try to match the given word form pattern and return success. */
Boolean matchfirstpattern(AVS pattern, 
                          Matchlist *matchlist,
                          CorpusList *corpus)
{
  int nr_strucs, nr_ok, ok, i, k, start, end, nr_pos, cpos;
  Bitfield bf;
  float red;
  char *val;

  assert(pattern);

  switch (pattern->type) {

  case Tag:

    assert(pattern->tag.attr != NULL);
    
    nr_strucs = cl_max_struc(pattern->tag.attr);
    if (nr_strucs <= 0) {        /* CL considers 0 regions a missing data error, but we won't be that strict */
      matchlist->tabsize = 0;        /* should be initialised to that, but make sure we report 0 matches  */
      return True;
    }

    /* if there is a constraint, match annotated strings first */
    bf = create_bitfield(nr_strucs); /* always use bitfield (the memory overhead is acceptable) */
    if (pattern->tag.constraint) {
      clear_all_bits(bf);
      nr_ok = 0;
      for (i = 0; (i < nr_strucs) && (EvaluationIsRunning); i++) {
        val = cl_struc2str(pattern->tag.attr, i);
        if (val) {
          if (pattern->tag.rx)
            ok = cl_regex_match(pattern->tag.rx, val);
          else
            ok = (0 == strcmp(pattern->tag.constraint, val));
          if (pattern->tag.negated)
            ok = !ok;
        }
        else
          ok = 0;
        if (ok) {
          set_bit(bf, i);
          nr_ok++;
        }
      }
      if (!EvaluationIsRunning)
        nr_ok = 0;                /* user abort -> stop query execution */
    }
    else {
      set_all_bits(bf);                /* no constraint -> all regions are possible start points */
      nr_ok = nr_strucs;
    }

    if (nr_ok <= 0) {                /* no matches -> return empty matchlist */
      destroy_bitfield(&bf);
      matchlist->tabsize = 0;
      return True;
    }
    else {
      /* compute the initial matchlist according to the flags in bf */
      matchlist->start = (int *)cl_malloc(sizeof(int) * nr_ok);
      matchlist->end = NULL;
      matchlist->matches_whole_corpus = 0;
    
      k = 0;
      for (i = 0; i < nr_strucs; i++) {
        if (get_bit(bf, i)) {
          if (!cl_struc2cpos(pattern->tag.attr, i, &start, &end)) {
            destroy_bitfield(&bf);
            cl_free(matchlist->start);
            return False;
          }
          matchlist->start[k++] = (pattern->tag.is_closing) ? (end + 1) : start;
          /* NB: it's (end+1) for a closing tag, since the tag refers to the token at cpos-1 */
        }
      }
    }
    destroy_bitfield(&bf);
    matchlist->tabsize = nr_ok;
    return True;
    break;

  case Anchor:
    
    /* first, check some error conditions */
    if ((corpus->size == 0) || (corpus->range == NULL)) {
      cqpmessage(Error, "Subquery on empty corpus. Not evaluated.");
      return False;
    }
    if ((pattern->anchor.field == TargetField) && (corpus->targets == NULL)) {
      cqpmessage(Error, "No <target> anchors found in query corpus.");
      return False;
    }
    if ((pattern->anchor.field == KeywordField) && (corpus->keywords == NULL)) {
      cqpmessage(Error, "No <keyword> anchors found in query corpus.");
      return False;
    }
    
    /* allocate matchlist with maximal size required */
    matchlist->start = (int *)cl_malloc(sizeof(int) * corpus->size);
    matchlist->end = NULL;
    matchlist->matches_whole_corpus = 0;
    matchlist->tabsize = corpus->size;

    /* now go through all ranges in the query corpus and copy the corresponding anchor position into the matchlist */
    for (i = 0; i < corpus->size; i++) {
      switch (pattern->anchor.field) {
      case MatchField:
        cpos = corpus->range[i].start;
        break;
      case MatchEndField:
        cpos = corpus->range[i].end;
        break;
      case TargetField:
        cpos = corpus->targets[i];
        break;
      case KeywordField:
        cpos = corpus->keywords[i];
        break;
      default:
        assert("Internal Error" && 0);
      }
      if (pattern->anchor.is_closing && (cpos >= 0))
        cpos++;                        /* </target> anchor refers to point after target token etc. */
      matchlist->start[i] = cpos;
    }
    
    /* remove 'undefined' target or keyword anchors */
    if (!Setop(matchlist, Reduce, NULL)) 
      return False;
    return True;
    
  case Pattern:

    /* no need to set labels here, since this is done in the following NFA simulation */

    if (0 &&
        (query_optimize) &&
        ((red = red_factor(corpus, &nr_pos)) != 0.0) &&
        (red < RED_THRESHOLD)) {

      /*
       * THIS IS CURRENTLY DISABLED (TODO!)
       * ----------------------------------------------------------------------
       * 
       * The evaluator optimization expects the ``initial matchlist''
       * to be exact, that is, there mustn't be any CPs in it which don't
       * reflect to valid start states in the automaton.
       *
       * Fri Mar 17 11:12:47 1995 (oli)
       */

      if (!silent)
        fprintf(stderr, "QOpt: %f (pos %d)\n", red, nr_pos);

      matchlist->start = (int *)cl_malloc(sizeof(int) * nr_pos);
      matchlist->end = NULL;
      matchlist->matches_whole_corpus = 0;
    
      if (matchlist->start == NULL)
        return False;
      matchlist->tabsize = nr_pos;
      
      k = 0;
      for (i = 0; i < corpus->size; i++)
        for (start = corpus->range[i].start;
             start <= corpus->range[i].end;
             start++) {
          assert(k < nr_pos);
          matchlist->start[k++] = start;
        }

      assert(k == nr_pos);

      if (!silent)
        fprintf(stderr, "QOpt: copied ranges\n");

      return (k == nr_pos);
    }
    else {
      int ok;
      ok = calculate_initial_matchlist(pattern->con.constraint,
                                       matchlist, corpus);
      return ok;
    }

    break;

  case MatchAll:
    get_matched_corpus_positions(NULL, ".*", 0, matchlist,
                                 (int *)corpus->range, corpus->size);
    return True;
    break;
  }
  
  assert("Internal Error." && 0);
  return False;
}





void simulate(Matchlist *matchlist, int *cut,
              int start_state, int start_offset, /* start_offset is always set to 0; no idea what it was meant for??? */
              int *state_vector, int *target_vector,
              RefTab *reftab_vector, RefTab *reftab_target_vector,
              int start_transition)
{
  int i, p, cpos, effective_cpos, rp;
  int strict_regions_ok, lookahead_constraint, zero_width_pattern;

  int target_state, transition_valid;

  int state,
    boundary, b1, b2,
    running_states,
    winner,
    my_target,
    this_is_a_winner;

  int *help;
  RefTab *help2;

  AVStructure *condition;

  int nr_transitions = 0;

  int percentage, new_percentage; /* for ProgressBar option */

  assert(evalenv->query_corpus);
  assert(evalenv->query_corpus->size > 0);
  assert(evalenv->query_corpus->range);
  assert(matchlist);
  assert(matchlist->start);
  assert(matchlist->end);

  /* 
   * state 0 must neither be final nor error
   */

  assert(!evalenv->dfa.Final[0] && (evalenv->dfa.E_State != 0));

  if ((evalenv->query_corpus->size == 0) ||
      (evalenv->query_corpus->range == NULL)) {
    free_matchlist(matchlist);
  }
  else {

    assert(state_vector);
    assert(target_vector);
    assert(reftab_vector);
    assert(reftab_target_vector);
    
    rp = 0;
    i = 0;
    percentage = -1;

    while ((i < matchlist->tabsize) && ((*cut) != 0) && EvaluationIsRunning) {
      
      if (progress_bar && !evalenv->aligned) {
        new_percentage = floor(0.5 + (100.0 * i) / matchlist->tabsize);
        if (new_percentage > percentage) {
          percentage = new_percentage;
          progress_bar_percentage(0, 0, percentage);
        }
      }
      /* 
       * find the appropriate range
       * three cases:
       * 1 start point smaller than range beginning
       *   we should have considered that start point before. so
       *   we cannot have a match in this case.
       *   action: assign -1 to matchlist->start and increment i
       * 2 start point within range (ok)
       *   action: simulate automaton
       * 3 start point beyond range end
       *   we have to check whether a later range will contain the
       *   starting point. 
       *   action: increment rp. 
       */
    
      my_target = -1;

      if (debug_simulation)
        fprintf(stderr, "Looking at matchlist element %d (cpos %d)\n"
                "  range[rp=%d]=[%d,%d]\n",
                i, matchlist->start[i],
                rp,
                (rp < evalenv->query_corpus->size) ?
                evalenv->query_corpus->range[rp].start : -1,
                (rp < evalenv->query_corpus->size) ?
                evalenv->query_corpus->range[rp].end : -1);
      
      if ((rp >= evalenv->query_corpus->size) ||
          (matchlist->start[i] < evalenv->query_corpus->range[rp].start)) {
        /* case 1
         * - no match possible
         */
        matchlist->start[i] = -1;
        i++;
      }
      else if (matchlist->start[i] > evalenv->query_corpus->range[rp].end)
        /* case 3
         * - no match in this range.
         * check for a later one (but keep the current matchlist element)
         */
        rp++;
      else {
      
        /* case 2
         * simulate automaton
         */

        /* determine maximal right boundary for this match:
         * boundary = MIN() of
         *  - boundary given by "within" clause (defaults to hard_boundary, if there is no "within" clause)
         *  - right boundary of current range in the query_corpus (for subqueries)
         */
        b1 = calculate_rightboundary(evalenv->query_corpus,
                                     matchlist->start[i],
                                     evalenv->search_context);
        b2 = evalenv->query_corpus->range[rp].end;
        boundary = MIN(b1, b2);

        if (debug_simulation)
          fprintf(stderr, "Starting NFA simulation. Max bound is %d\n",
                  boundary);

        if (boundary == -1) {
          /*
           * no match here, since not within selected boundary.
           */
          matchlist->start[i] = -1;
          if (debug_simulation)
            fprintf(stderr, "  ... not within selected boundary\n");
        }
        else {

          int first_transition_traversed;

          /*
           * set up some 'global' variables in evalenv (which subroutines may need to use)
           */

          evalenv->rp = rp;        /* current range (in subquery); used to evaluate Anchor constraints */

          /*
           * all states are inactive / reset label references
           */

          for (state = 0; state < evalenv->dfa.Max_States; state++) {
            state_vector[state] = -1;
            reset_reftab(reftab_vector[state]);
          }

          /*
           * activate initial state and set the special "match" label
           */

          state_vector[start_state] = matchlist->start[i] + start_offset;
          set_reftab(reftab_vector[start_state], evalenv->match_label->ref, matchlist->start[i] + start_offset);

          running_states = 1;        /* the number of currently active states */
          winner = -1;                /* the end position of the winning (final) state */

          first_transition_traversed = 0; /* the first transition was not yet traversed */

          /* bail out on the first winner, unless matching_strategy == longest match */
          /* (in longest_match strategy, wait until we don't have any running states left) */
          while (((winner < 0) || (matching_strategy == longest_match))
                 && (running_states > 0)) {

            /*
             * the core of the whole simulation
             */

            /*
             * first clear the list of target states
             */

            for (state = 0; state < evalenv->dfa.Max_States; state++)
              target_vector[state] = -1;
            /* no need to reset the target reftab, since only reftab associated
               with active states will be considered */

            for (state = 0;
                 (state < evalenv->dfa.Max_States) &&
                   ((winner < 0) || (matching_strategy == longest_match)) &&  /* abort when we've found a winner, unless strategy is longest match */
                   (running_states > 0);                      /* no remaining active states -> simulation finished */
                 state++) {

              cpos = state_vector[state];
              /* A state always refers to a point between two consecutive tokens.
               * cpos = state_vector[state] is the corpus position of the second token.
               * Hence, in a query, patterns and open tags refer to the second token (at cpos),
               * where as closing tags refer to the first token (at cpos-1)
               */

              if (debug_simulation) {
                fprintf(stderr, "  state %d, cpos %d...\n", state, cpos);
                if (symtab_debug)
                  print_label_values(evalenv->labels, reftab_vector[state], cpos);
              }

              /* Transitions from this state are allowed if:
               * - cpos >= 0         -->  state is active
               * - cpos <= boundary  -->  within right boundary for this match
               * !! if the next query element is a closing tag, we have to substitue cpos-1 for cpos in this condition !!
               * --> we'll test (cpos >= 0) right now and the other condition separately for each possible transition
               */

              if (cpos >= 0) {        /* active state */

                running_states--; /* this state becomes inactive; it will spawn new active states if there are valid transitions */

                for (p = 0;        /* cycle through all possible transitions from this state */
                     (p < evalenv->dfa.Max_Input)
                       && ((winner < 0) || (matching_strategy == longest_match)); /* in shortest_match mode, stop evaluation as soon as there is a winner */
                     p++) {

                  /* the target state (that is, the state we reach after the transition) */
                  target_state = evalenv->dfa.TransTable[state][p];

                  /* if we reach a non-error state with this transition */
                  if (target_state != evalenv->dfa.E_State) {

                    /* condition is the AVStructure ("pattern") associated with this transition */
                    condition = &(evalenv->patternlist[p]);

                    /* check whether the associated condition is a lookahead constraint pattern */
                    lookahead_constraint =
                      ((condition->type == MatchAll) && (condition->matchall.lookahead)) ||
                      ((condition->type == Pattern) && (condition->con.lookahead));

                    /* tags, anchors, and lookahead constraints are zero-width patterns */
                    zero_width_pattern =
                      (condition->type == Tag) || (condition->type == Anchor) || lookahead_constraint;

                    /* check if we're still in range (i.e. effective_cpos <= boundary; except for lookahead constraint) */
                    effective_cpos = cpos;
                    /* a closing tag or anchor point refers to effective_cpos = cpos-1 */
                    if ((condition->type == Tag && condition->tag.is_closing)
                        || (condition->type == Anchor && condition->anchor.is_closing))
                      effective_cpos--;

                    /* In StrictRegions mode, we have to check all constraints imposed by region boundaries now. */
                    strict_regions_ok = 1;
                    if (strict_regions) {
                      int flags = LAB_RDAT | LAB_DEFINED | LAB_USED; /* 'active' labels in rdat namespace */
                      LabelEntry rbound_label = symbol_table_new_iterator(evalenv->labels, flags);
                      while (rbound_label != NULL) {
                        int rbound = get_reftab(reftab_vector[state], rbound_label->ref, -1);
                        if ((rbound >= 0) && (effective_cpos > rbound))
                          strict_regions_ok = 0; /* a within region constraint has been violated */
                        rbound_label = symbol_table_iterator(rbound_label, flags);
                      }
                    }

                    /* if we're in range, evaluate the constraint and activate target state iff true */
                    if ( ((effective_cpos <= boundary) ||
                          (lookahead_constraint && (effective_cpos == boundary+1)))
                         && strict_regions_ok ) {

                      /* IF this is the first transition we pass from the start state,
                       * AND it is the one for which we built the initial matchlist,
                       * we can save a little time if we don't evaluate the condition again;
                       * if (start_transition >= 0) we can also safely ignore all other
                       * transitions from the start state because they will crop up in another
                       * initial matchlist (start_transition < 0 happens in "aligned" queries, for instance)
                       *
                       * !! THIS MESSES UP THE SHORTEST MATCH STRATEGY !!  ->  results have to be cleaned up after the query
                       */
                      if ((state == start_state) &&
                          (start_transition >= 0) &&
                          (first_transition_traversed == 0)) {

                        transition_valid = (start_transition == p) ? 1 : 0;

                        /* if this first transition is valid, we need to copy the reftab
                         * and set the optional label associated with this transition (otherwise done by eval_constraint()) */
                        if (transition_valid) {
                          LabelEntry label;

                          /* copy the state's reftab to the target state (done by eval_constrain() in the other cases) */
                          dup_reftab(reftab_vector[state], reftab_target_vector[target_state]);
                          if (condition->type == Pattern)
                            label = condition->con.label;
                          else if (condition->type == MatchAll)
                            label = condition->matchall.label;
                          else
                            label = NULL;

                          if (label != NULL) {
                            set_reftab(reftab_target_vector[target_state], label->ref, effective_cpos); /* see below */
                          }

                          /* if the skipped first pattern was an open tag, we have to set the corresponding label in StrictRegions mode here */
                          if (strict_regions && (condition->type == Tag)) {
                            int start, end;
                            if ((! condition->tag.is_closing) &&
                                (condition->tag.right_boundary != NULL) &&
                                get_struc_attribute(condition->tag.attr, effective_cpos, &start, &end)) {
                              set_reftab(reftab_target_vector[target_state], condition->tag.right_boundary->ref, end);
                            }
                          }

                        }
                      }
                      /* OTHERWISE we evaluate the condition associated with the transition
                       * (NB this condition refers to the effective_cpos!)
                       */
                      else {
                        transition_valid = eval_constraint(condition, effective_cpos,
                                                           reftab_vector[state], reftab_target_vector[target_state]);
                      }    /* if ((state == start_state) && ... ) ...  */

                      /* now set target for this transition */
                      if (transition_valid && matchlist->target_positions) {/* the second condition should be unecessary */
                        int pattern_is_targeted;

                        if (condition->type == Pattern) {
                          pattern_is_targeted = condition->con.is_target;
                        }
                        else if (condition->type == MatchAll) {
                          pattern_is_targeted = condition->matchall.is_target;
                        }
                        else {
                          pattern_is_targeted = 0;
                        }

                        if (pattern_is_targeted) {
                          set_reftab(reftab_target_vector[target_state], evalenv->target_label->ref, /* the special "target" label */
                                     effective_cpos); /* since only patterns can be targeted, this is ==cpos at the moment, but why not change it? */
                        }
                      }

                      /* now, finally, check if we have a winner, i.e.
                       * - the target state is a final state
                       * - the optional global constraint is fulfilled
                       * and then advance to the next token (unless transition was associated with a tag or anchor point)
                       */
                      if (transition_valid) {

                        nr_transitions++;
                        if (nr_transitions == 20000) {
                          CheckForInterrupts();
                          nr_transitions = 0;
                        }

                        if (debug_simulation) {
                          fprintf(stderr, "Transition %d --%d-> %d  (pattern %d TRUE at cpos=%d)\n",
                                  state, p, target_state, p, effective_cpos);
                          if (symtab_debug)
                            print_label_values(evalenv->labels, reftab_target_vector[target_state], effective_cpos);
                        }

                        /* check for winner */
                        this_is_a_winner = 0;
                        if (evalenv->dfa.Final[target_state]) {
                          if (evalenv->gconstraint == NULL) {
                            this_is_a_winner = 1;
                          }
                          else {
                            int matchend_cpos = (zero_width_pattern) ? cpos - 1 : cpos;
                            /* set special "matchend" label before the global constraint is evaluated */
                            set_reftab(reftab_target_vector[target_state], evalenv->matchend_label->ref, matchend_cpos);
                            /* evaluate global constraint with current cpos set to -1 (undef) */
                            if (eval_bool(evalenv->gconstraint, reftab_target_vector[target_state], -1)) {
                              this_is_a_winner = 1;
                            }
                            /* delete "matchend" label in case we continue the simulation (longest match mode) */
                            set_reftab(reftab_target_vector[target_state], evalenv->matchend_label->ref, -1);
                          }
                        }

                        if (this_is_a_winner) {

                          if (debug_simulation)
                            fprintf(stderr, "Winning cpos found at %d\n", cpos);

                          /* remember the last token (cpos) of this winner & its target position (if set) */
                          winner = (zero_width_pattern) ?  cpos - 1 : cpos;
                          /* for zero-width elements, the last token of the match is the token _before_ the current corpus position
                             [NB: for closing tags and anchors we could have used the effective cpos, but not for open tags and lookahead constraints]
                          */

                          if (evalenv->has_target_indicator) {
                            my_target = get_reftab(reftab_target_vector[target_state],
                                                   evalenv->target_label->ref, -1);
                          }
                          /* NB If (matching_strategy == longest_match) later winners will overwrite
                             the <winner> and <my_target> variables */
                        }

                        /* if our matching strategy is longest_match, we have to activate the target state,
                         * so our winner can expand to a longer match in queries like ''"ADJA" "NN"+;'' */
                        if (!this_is_a_winner || (matching_strategy == longest_match)) {
                          /* for zero-width elements, don't increment corpus position (think of "<s><np> ... </np></s>" for instance) */
                          if (zero_width_pattern) {
                            target_vector[target_state] = cpos;  /* this is NOT the effective cpos, otherwise we'd go backwards! */
                          }
                          else {
                            target_vector[target_state] = cpos + 1;
                          }
                        }

                      } /* if (transition_valid) ...           [check for winners] */

                    }   /* if (effective_cpos <= boundary) ... */

                  }     /* if (target_state != evalenv->dfa.E_State) ... */

                }       /* for (p = 0; ... ; p++) ...          [loop over all transitions from this state] */

              }         /* if (cpos >= 0) ...                  [active state] */

            }           /* for (state = 0; ... ; state++) ...  [loop over all states] */

            /* we have now traversed all possible transitions from all active states
             * -> if this is the first simulation cycle, we have now done our first transitions */
            first_transition_traversed = 1;

            /* if we haven't found a winner, or we're looking for other winners,
               check if there are still any active states */
            if ((winner < 0) || (matching_strategy == longest_match)) {
              running_states = 0;
              for (state = 0; state < evalenv->dfa.Max_States; state++)
                if (target_vector[state] >= 0)
                  running_states++;

              /* while we're at it, swap the current state & target vectors and reftabs for the next simulation cycle */
              help = state_vector;
              state_vector = target_vector;
              target_vector = help;

              help2 = reftab_vector;
              reftab_vector = reftab_target_vector;
              reftab_target_vector = help2;
            }

            /*
               Some nonsensical CQP queries involving XML tags or zero-width assertions (such as ``<s> *'') can lead to a FSA with
               eps-cycles (i.e. a cycle that returns to the same state without consuming a token) and hence to an infinite loop in the simulation.
               The hallmark of such an infinite loop should be that the state_vector converges to a stable state (a "fixed point").
               Here, we check for this situation (state_vector == target_vector) and abort FSA simulation if it is caught in an infinite loop.
               For now, an emphatic error message is printed (asking users to file a bug report if this code should abort a valid query) and
               query execution is stopped immediately.  Once we are reasonably certain that the infinite loop test works correctly, we might
               also simply consider set the current run to "no match" and continue with the next starting point in the list.
            */
            for (state = 0; state < evalenv->dfa.Max_States; state++)
                if (state_vector[state] != target_vector[state])
                  break;
            if (state >= evalenv->dfa.Max_States) {
              /* state_vector hasn't changed in last simulation step => caught in infinite loop */
              cqpmessage(Error, "Infinite loop detected: did you quantify over a zero-width element (XML tag or lookahead)?\n"
                         "\tIf you are reasonably sure that your query is valid, please contact the CWB development team and file a bug report!\n"
                         "\tQuery execution aborted.");
              running_states = 0; /* this should get us safely out of the inner loop ... */
              EvaluationIsRunning = 0; /* ... and the outer loop */
            }
    

          }    /* while (((winner < 0) || ... ) && (running_states > 0)) ...  */

          /*
           * if we returned here, we either have a winning
           * corpus position or no running states any more.
           */

          if (debug_simulation)
            fprintf(stderr, "NFA sim terminated. Winner %d, running states %d\n",
                    winner, running_states);

          /* queries like "</s>" will return empty matches -> ignore those (set to no match)
           * (NB this doesn't happen for open tags, since "<s>" == "<s> []")
           */
          if ((winner >= 0) && (winner >= matchlist->start[i])) {
            if (*cut > 0)
              *cut = *cut - 1;
            matchlist->end[i] = winner;
          }
          else
            matchlist->start[i] = -1;

        }


        if (matchlist->target_positions) {
          if (matchlist->start[i] >= 0)
            matchlist->target_positions[i] = my_target;
          else
            matchlist->target_positions[i] = -1;
        }

        i++;                        /* move to the next regarded matchlist element */


      } /* case 2: simulate automaton */


    }   /* while ((i < matchlist->tabsize) && ... ) ...  [simulate automaton for current matchlist] */
    
    /*
     * if we left the execution prematurely ... (interrupt, I guess?)
     */
    while (i < matchlist->tabsize) {
      matchlist->start[i] = -1;
      i++;
    }

  }     /* the big "else" (unless evalenv->query_corpus->size == 0) */
}




int check_alignment_constraints(Matchlist *ml)
{
  int mlp, envp, i;
  int as, ae, dum1, dum2, dum3;
  EEP tmp;

  int *state_vector;
  int *target_vector;
  RefTab *reftab_vector;
  RefTab *reftab_target_vector;

  Matchlist matchlist;

  if (eep > 0) {

    /*
     * we have alignments
     */


    EvaluationIsRunning = 1;

    init_matchlist(&matchlist);

    for (envp = 1; envp <= eep; envp++) {
      
      assert(Environment[envp].aligned);
      tmp = evalenv;
      evalenv = &(Environment[envp]);

      state_vector = (int *)cl_malloc(sizeof(int) * Environment[envp].dfa.Max_States);
      target_vector = (int *)cl_malloc(sizeof(int) * Environment[envp].dfa.Max_States);
      reftab_vector = (RefTab *) cl_malloc(sizeof(RefTab) * evalenv->dfa.Max_States);
      reftab_target_vector = (RefTab *) cl_malloc(sizeof(RefTab) * evalenv->dfa.Max_States);
      /* init reference table for current evalenv */
      for (i = 0; i < evalenv->dfa.Max_States; i++) {
        reftab_vector[i] = new_reftab(evalenv->labels);
        reftab_target_vector[i] = new_reftab(evalenv->labels);
      }

      for (mlp = 0; mlp < ml->tabsize; mlp++)

        if (ml->start[mlp] != no_match) {
          int alg1, alg2;
          if (0 > (alg1 = cl_cpos2alg(Environment[envp].aligned, ml->start[mlp])))
            ml->start[mlp] = no_match;
          else if (!cl_alg2cpos(Environment[envp].aligned,
                                alg1, &dum1, &dum2, &as, &dum3) || (cderrno != CDA_OK))
            ml->start[mlp] = no_match;
          else if (0 > (alg2 = cl_cpos2alg(Environment[envp].aligned, ml->end[mlp])))
            ml->start[mlp] = no_match;
          else if (!cl_alg2cpos(Environment[envp].aligned,
                                alg2, &dum1, &dum2, &dum3, &ae) || (cderrno != CDA_OK))
            ml->start[mlp] = no_match;
          else if ((ae < as)  || (ae < 0) || (as < 0))
            ml->start[mlp] = no_match;
          else {

            /* construct initial matchlist by assuming
             * that every position in the aligned range
             * may be an initial matchpoint
             */

            matchlist.tabsize = ae - as + 1;
            matchlist.start = (int *)cl_malloc(sizeof(int) * matchlist.tabsize);
            matchlist.end   = (int *)cl_malloc(sizeof(int) * matchlist.tabsize);

            for (i = as; i <= ae; i++) {
              matchlist.start[i - as] = i;
              matchlist.end[i - as] = i;
            }

            dum1 = 1;

            /* don't reset label references here, because it shouldn't
               really be necessary (it's done in simulate()) */
            simulate(&matchlist, &dum1, 0, 0,
                     state_vector, target_vector,
                     reftab_vector, reftab_target_vector,
                     -1);

            if (dum1 != evalenv->negated)
              ml->start[mlp] = no_match;

            free_matchlist(&matchlist);

          }
        }
      free(state_vector);
      free(target_vector);
      for (i = 0; i < evalenv->dfa.Max_States; i++) {
        delete_reftab(reftab_vector[i]);
        delete_reftab(reftab_target_vector[i]);
      }
      free(reftab_vector);
      free(reftab_target_vector);

      evalenv = tmp;
    }

    if (!EvaluationIsRunning) {
      cqpmessage(Info, "Evaluation interruted: results may be incomplete.");
      if (which_app == cqp) install_signal_handler();
    }
  }
  
  return 0;
}

/* simulate the dfa */
void
simulate_dfa(int envidx, int cut, int keep_old_ranges)
{
  int p, maxresult, state, i;
  Matchlist matchlist;
  Matchlist total_matchlist; 

  int *state_vector;            /* currently active states are marked with corresponding cpos */
  int *target_vector;                /* target states when simulating transition */
  RefTab *reftab_vector;        /* the reference tables corresponding to the state vector */
  RefTab *reftab_target_vector;        /* the reference tables corresponding to the target vector */

  int allocate_target_space;

  /* We can avoid wasting memory if the first transition of the FSA is
     deterministic, because there's no need to collect matches in 
     total_matchlist then. */
  int FirstTransitionIsDeterministic;
  int trans_count = 0, current_transition = 0;


  assert(envidx <= eep);        /* envidx == 0, actually ...  check_alignment_constraint EXPLICITLY assumes that everything
                                   else is an alignment constraint! */
  evalenv = &Environment[envidx];

  /* Apparently Max_Input is the maximal number of transitions that appears in the 
     FSA, so we have Max_Input transitions from every state and the unused ones go
     to dfa.E_State (error state?) and aren't evaluated. To cut a long story short,
     we'll have to count how many transitions from the start state we'll have to
     follow. Heck. */
  /* this loop is essentially the same as the main loop below */
  for (p = 0; p < evalenv->dfa.Max_Input; p++)
    if (evalenv->dfa.TransTable[0][p] != evalenv->dfa.E_State) 
      trans_count++;
  FirstTransitionIsDeterministic = (trans_count == 1) ? 1 : 0;

  init_matchlist(&matchlist);
  if (!FirstTransitionIsDeterministic) 
    init_matchlist(&total_matchlist);

  allocate_target_space = evalenv->has_target_indicator;

  assert(evalenv->query_corpus);

  if (evalenv->dfa.Final[0] == True) {
    cqpmessage(Error, 
               "Query matches empty string, evaluation aborted (otherwise whole corpus would be matched)\n");

    set_corpus_matchlists(evalenv->query_corpus, 
                          &matchlist, /* total_matchlist may be uninitialised */
                          1,
                          0);
    free_matchlist(&matchlist);

  }
  else if (evalenv->query_corpus->size == 0) {
    cqpmessage(Info,
               "Query corpus is empty (and so is the result).");
    free_matchlist(&matchlist);
  }
  else {

    /* allocate the state and reference table vectors here, so that this has
     * not to be done in every simulate iteration
     */

    state_vector = (int *)cl_malloc(sizeof(int) * evalenv->dfa.Max_States);
    target_vector = (int *)cl_malloc(sizeof(int) * evalenv->dfa.Max_States);
    reftab_vector = (RefTab *) cl_malloc(sizeof(RefTab) * evalenv->dfa.Max_States);
    reftab_target_vector = (RefTab *) cl_malloc(sizeof(RefTab) * evalenv->dfa.Max_States);
    /* init reference table for current evalenv */
    for (i = 0; i < evalenv->dfa.Max_States; i++) {
      reftab_vector[i] = new_reftab(evalenv->labels);
      reftab_target_vector[i] = new_reftab(evalenv->labels);
    }

    EvaluationIsRunning = 1;

    /* first transition loop (loops over all possible initial patterns) */
    for (p = 0; 
         (p < evalenv->dfa.Max_Input) && EvaluationIsRunning;
         p++)

      if ((state = evalenv->dfa.TransTable[0][p]) != evalenv->dfa.E_State) {

        current_transition++;        /* counts how many of the trans_count initial transitions we have evaluated */
        if (progress_bar && !evalenv->aligned) {
          progress_bar_clear_line();
          progress_bar_message(current_transition, trans_count, "    preparing");
        }

        if (evalenv->labels) {
          for (i = 0; i < evalenv->dfa.Max_States; i++) {
            reset_reftab(reftab_vector[i]);        /* reset all label references */
            reset_reftab(reftab_target_vector[i]); /* shouldn't be necessary, just to make sure */
          }
        }

        /* match the initial pattern. */
        if (matchfirstpattern(&(evalenv->patternlist[p]),
                              &matchlist,
                              evalenv->query_corpus) == True) {

          if (initial_matchlist_debug) {
            fprintf(stderr, "After initial matching for transition %d: ", p);
            show_matchlist_firstelements(matchlist);
            print_symbol_table(evalenv->labels);
          }

          if (matchlist.tabsize > 0) {

            matchlist.end = (int *)cl_malloc(sizeof(int) * matchlist.tabsize);
            (void) memcpy(matchlist.end, matchlist.start,
                          sizeof(int) * matchlist.tabsize);

            if (allocate_target_space) {
              matchlist.target_positions = (int *)cl_malloc(sizeof(int) * matchlist.tabsize);
              for (i = 0; i < matchlist.tabsize; i++)
                matchlist.target_positions[i] = -1;
            }

            /* when 'cut <n>' is specified, try to get <n> matches from every intial pattern; */
            /* then reduce to a total of <n> matches after sorting */
            if (cut <= 0)
              maxresult = -1;
            else
              maxresult = cut;

            simulate(&matchlist, &maxresult, 0, 0,
                     state_vector, target_vector,
                     reftab_vector, reftab_target_vector,
                     p);

            if (initial_matchlist_debug) {
              fprintf(stderr, "After simulation for transition %d:\n ", p);
              show_matchlist(matchlist);
            }

            if (progress_bar && !evalenv->aligned)
              progress_bar_message(current_transition, trans_count, "merging reslt");

            /* reduce matchlist for this pass */
            Setop(&matchlist, Reduce, NULL);

            /* collect the matches (unless there's only one transition) */
            if (!FirstTransitionIsDeterministic) {
              Setop(&total_matchlist, Union, &matchlist);
            }

            if (initial_matchlist_debug && (!FirstTransitionIsDeterministic)) {
              fprintf(stderr, "Complete Matchlist after simulating transition %d: \n", p);
              show_matchlist(total_matchlist);
            }
          }
        }
        else {
          if (EvaluationIsRunning) {
            cqpmessage(Error, "Problems while computing initial matchlist for pattern %d. Aborted.\n", p);
            EvaluationIsRunning = 0;
          }
        }

        if (!FirstTransitionIsDeterministic)
          free_matchlist(&matchlist);

        if (progress_bar && !evalenv->aligned)
          progress_bar_clear_line();
      }        /* end of loop over all initial transitions */
    
    /* if there's only one transition, the total matchlist is the same as the matchlist
       of that transition, so we just copy it (note that we didn't initialize total_matchlist
       in that case */
    if (FirstTransitionIsDeterministic) 
      total_matchlist = matchlist;

    if (initial_matchlist_debug) {
      fprintf(stderr, "After total simulation:\n");
      show_matchlist(total_matchlist);
    }

    if (!EvaluationIsRunning) {
      cqpmessage(Warning, "Evaluation interruted: results will be incomplete.");
      if (which_app == cqp) install_signal_handler();
    }

    check_alignment_constraints(&total_matchlist);
    
    EvaluationIsRunning = 0;
    
    /* may need to reduce again after checking alignment constraints */
    Setop(&total_matchlist, Reduce, NULL);
    
    if (initial_matchlist_debug) {
      fprintf(stderr, "after final reducing\n");
      show_matchlist(total_matchlist);
    }
    
    set_corpus_matchlists(evalenv->query_corpus, 
                          &total_matchlist,
                          1,
                          keep_old_ranges);
    free_matchlist(&total_matchlist);

    free(state_vector);
    free(target_vector);
    for (i = 0; i < evalenv->dfa.Max_States; i++) {
      delete_reftab(reftab_vector[i]);
      delete_reftab(reftab_target_vector[i]);
    }
    free(reftab_vector);
    free(reftab_target_vector);
  }
}

void
cqp_run_query(int cut, int keep_old_ranges)
{
  if (eep >= 0) {
    if (hard_cut > 0)
      if (hard_cut < cut)
        cut = hard_cut;
    simulate_dfa(0, cut, keep_old_ranges);
  }
}

int eval_mu_tree(Evaltree et, Matchlist* ml);

void 
cqp_run_mu_query(int keep_old_ranges, int cut_value)
{
  Matchlist matchlist;
  int ok;

  init_matchlist(&matchlist);

  evalenv = &Environment[0];

  assert(evalenv->query_corpus);

  ok = eval_mu_tree(evalenv->evaltree, &matchlist);

  if (! ok) {
    cqpmessage(Error, "Evaluation of MU query has failed (or been interrupted by user)");
    free_matchlist(&matchlist);        /* automatically initialises to empty match list */
  }


  if (matchlist.tabsize > 0) {

    mark_offrange_cells(&matchlist, evalenv->query_corpus);

    Setop(&matchlist, Reduce, NULL);

    if (cut_value > 0 && matchlist.tabsize > cut_value) {

      int i;
      
      for (i = cut_value; i < matchlist.tabsize; i++)
        matchlist.start[i] = -1;
      Setop(&matchlist, Reduce, NULL);
    }

    matchlist.end = (int *)cl_malloc(sizeof(int) * matchlist.tabsize);
    memcpy(matchlist.end, matchlist.start, sizeof(int) * matchlist.tabsize);
  }
  else {
    assert(matchlist.start == NULL);
  }

  set_corpus_matchlists(evalenv->query_corpus, 
                        &matchlist,
                        1,
                        keep_old_ranges);
}

void
cqp_run_tab_query(int implode)
{
  int nr_columns, i, this_col;
  Evaltree col;

  int smallest_col; 

  Matchlist *lists;
  int *positions;
  Evaltree *constraints;

  /* ------------------------------------------------------------ */

  evalenv = &Environment[0];

  assert(evalenv->query_corpus);

  /* here: eval. */

  nr_columns = 0;
  for (col = evalenv->evaltree; col; col = col->tab_el.next) {
    assert(col->type = tabular);
    nr_columns++;
  }

  assert(nr_columns > 0);

  /* die Matchlisten */

  lists = (Matchlist *)cl_malloc(nr_columns * sizeof(Matchlist));
  memset((char *)lists, '\0', nr_columns * sizeof(Matchlist));

  /* die Positionen in den einzelnen Matchlisten */

  positions = (int *)cl_malloc(nr_columns * sizeof(int));
  memset((char *)positions, '\0', nr_columns * sizeof(int));

  /* zur Bequemlichkeit, damit wir die Constraints als Array
   * adressieren können */

  constraints = (Evaltree *)cl_malloc(nr_columns * sizeof(Evaltree));
  memset((char *)constraints, '\0', nr_columns * sizeof(Evaltree));

  /* ---------------------------------------- */

  i = 0;
  smallest_col = 0;
  for (col = evalenv->evaltree; col; col = col->tab_el.next) {

    constraints[i] = col;

    init_matchlist(&lists[i]);
    calculate_initial_matchlist(evalenv->patternlist[col->tab_el.patindex].con.constraint, 
                                &lists[i], evalenv->query_corpus);

    if (i > 0) {
      if (lists[smallest_col].tabsize > lists[i].tabsize)
        smallest_col = i;
    }
    i++;
  }

  /* OK. Let's reduce them. */

  /* simple, silly algorighm. Just to test the beast. */
  /* TODO: optimize by using smallest_col */

  while (positions[0] < lists[0].tabsize) {

    int next_col, this_pos, next_pos, l_pos, r_pos;

    next_pos = -1;

    for (next_col = 1; next_col < nr_columns; next_col++) {

      this_col = next_col - 1;

      /* position in der aktuellen Liste */
      this_pos = lists[this_col].start[positions[this_col]];

      /* Minimale und maximale CP fuer Hit */
      l_pos = this_pos + constraints[next_col]->tab_el.min_dist;

      if (constraints[next_col]->tab_el.max_dist == repeat_inf)
        r_pos = this_pos + hard_boundary;
      else
        r_pos = this_pos + constraints[next_col]->tab_el.max_dist;

      while (positions[next_col] < lists[next_col].tabsize &&
             (next_pos = lists[next_col].start[positions[next_col]]) < l_pos) {

        /* mark for deletion */
        lists[next_col].start[positions[next_col]] = -1;
        positions[next_col]++;

      }

      if (positions[next_col] >= lists[next_col].tabsize ||
          next_pos > r_pos)
        break;
    }

    if (next_col >= nr_columns) {

      /* hit */
      for (i = 0; i < nr_columns; i++)
        positions[i]++;
      
    }
    else {
      lists[0].start[positions[0]] = -1;
      positions[0]++;
    }
  }

  /* go throuh all lists and mark positions which are not yet visited */
  for (this_col = 0; this_col < nr_columns; this_col++) {

    for (i = positions[this_col]; i < lists[this_col].tabsize; i++)
      lists[this_col].start[i] = -1;
    Setop(&(lists[this_col]), Reduce, NULL);

  }


  /* delete offrange cells when we are in a subcorpus */

  if (lists[0].tabsize > 0) {

    mark_offrange_cells(&lists[0], evalenv->query_corpus);

    Setop(&lists[0], Reduce, NULL);

    lists[0].end = (int *)cl_malloc(sizeof(int) * lists[0].tabsize);
    memcpy(lists[0].end, lists[0].start, sizeof(int) * lists[0].tabsize);
  }
  else {
    assert(lists[0].start == NULL);
  }

  set_corpus_matchlists(evalenv->query_corpus, 
                        lists,
                        nr_columns,
                        0);

  free(positions);
  free(constraints);

  for (i = 0; i < nr_columns; i++)
    free_matchlist(&lists[i]);
  free(lists);
}

/* ---------------------------------------------------------------------- */


int
meet_mu(Matchlist *list1, Matchlist *list2,
        int meet_lw, int meet_rw,
        Attribute *struc)
{

  /* this is very similar to Setop(Intersection)/matchlist.c, but we
   * have to take care of the context (lw, rw, struc) */

  Matchlist tmp;

  int i, j, k, start, end;
  int lw, rw;
  int i_region, bdry_region;

  if ((list1->tabsize == 0) || (list2->tabsize == 0)) {

    /*
     * Bingo. one of the two is empty. So is their intersection.
     */

    cl_free(list1->start);
    cl_free(list1->end);
    list1->tabsize = 0;
    list1->matches_whole_corpus = 0;
  }
  else {

    /*
     * We have to do some work now
     */

    tmp.tabsize = MIN(list1->tabsize, list2->tabsize);
    
    tmp.start = (int *)cl_malloc(sizeof(int) * tmp.tabsize);
    tmp.end = NULL;
    
    i = 0;                        /* the position in list1 */
    j = 0;                        /* the position in list2 */
    k = 0;                        /* the insertion point in the result list */
    
    lw = meet_lw;                 /* for token context */
    rw = meet_rw;
    
    while ((i < list1->tabsize) && (j < list2->tabsize)) {
      
      if (struc != NULL) {
        i_region = cl_cpos2struc(struc, list1->start[i]);
        if (i_region < 0) {
          i++;
          continue;
        }
        else {
          lw = 0;
          if (meet_lw > 0) {
            bdry_region = i_region - (meet_lw - 1);
            if (bdry_region < 0) bdry_region = 0;
            if (cl_struc2cpos(struc, bdry_region, &start, &end))
              lw = start - list1->start[i];
          }
          rw = 0;
          if (meet_rw > 0) {
            bdry_region = i_region + (meet_rw - 1);
            if (bdry_region >= cl_max_struc(struc)) bdry_region = cl_max_struc(struc) - 1;
            if (cl_struc2cpos(struc, bdry_region, &start, &end))
              rw = end - list1->start[i];
          }
        }
      }

      if (list1->start[i]+rw < list2->start[j]) {
        i++;
      }
      else if (list1->start[i]+lw > list2->start[j]) {
        j++;
      }
      else {

        assert((list1->start[i]+lw <= list2->start[j]) &&
               (list1->start[i]+rw >= list2->start[j]));

        tmp.start[k] = list1->start[i];

        i++;
        j++;
        k++;
      }
    }
    
    assert(k <= tmp.tabsize);
    
    if (k == 0) {
      /* we did not copy anything. result is empty. */
      cl_free(tmp.start); tmp.start = NULL;
    }
    else if (k < tmp.tabsize) {
      
      /* we did not eliminate any duplicates if k==tmp.tabsize. 
       * So, in that case, we do not have to bother with reallocs.
       */
      
      tmp.start = (int *)cl_realloc((char *)tmp.start, sizeof(int) * k);
    }
    
    cl_free(list1->start);
    
    list1->start = tmp.start; tmp.start = NULL;
    list1->end   = NULL;
    list1->tabsize = k;
    list1->matches_whole_corpus = 0;
  }

  return 1;
}

int
eval_mu_tree(Evaltree et, Matchlist* ml)
{
  Matchlist arg2;
  int ok;

  assert(et);

  if (et->type == meet_union) {

    switch (et->cooc.op_id) {
      
    case cooc_meet:
      
      init_matchlist(&arg2);
 
      if (! eval_mu_tree(et->cooc.left, ml)) 
        return 0;
      if (! eval_mu_tree(et->cooc.right, &arg2)) {
        free_matchlist(&arg2);
        return 0;
      }

      ok = meet_mu(ml, &arg2, et->cooc.lw, et->cooc.rw, et->cooc.struc);
      
      free_matchlist(&arg2);
      
      return ok;
      break;
      
    case cooc_union:

      init_matchlist(&arg2);

      if (! eval_mu_tree(et->cooc.left, ml)) 
        return 0;
      if (! eval_mu_tree(et->cooc.right, &arg2)) {
        free_matchlist(&arg2);
        return 0;
      }

      Setop(ml, Union, &arg2);
      free_matchlist(&arg2);

      return 1;

      break;
      
    default:
      assert("Illegal node type in cooc" && 0);
      break;
    }

  }
  else if (et->type == leaf) {

    assert(CurEnv);
    
    EvaluationIsRunning = 1;
    
    ok = calculate_initial_matchlist(evalenv->patternlist[et->leaf.patindex].con.constraint, 
                                     ml, evalenv->query_corpus);
    
    return ok && EvaluationIsRunning; /* aborts evaluation on user interrupt */
  }
  else {
    assert("Illegal node type in MU Evaluation Tree" && 0);
  }

  assert(0 && "Not reached");
  return 0;
}



/* ---------------------------------------------------------------------- */

int next_environment(void)
{
  if (eep >= MAXENVIRONMENT) {
    fprintf(stderr, "No more environments for evaluation (max %d exceeded)\n",
            MAXENVIRONMENT);
    return 0;
  }
  else {
    eep++;

    Environment[eep].query_corpus = NULL;
    Environment[eep].labels = new_symbol_table();

    Environment[eep].MaxPatIndex = -1;

    Environment[eep].gconstraint = NULL;

    Environment[eep].evaltree = NULL;

    Environment[eep].has_target_indicator = 0;
    Environment[eep].target_label = NULL;

    Environment[eep].match_label = NULL;
    Environment[eep].matchend_label = NULL;

    init_dfa(&Environment[eep].dfa);

    Environment[eep].search_context.direction = leftright;
    Environment[eep].search_context.type = word;
    Environment[eep].search_context.attrib = NULL;
    Environment[eep].search_context.size = 0;

    Environment[eep].negated = 0;

    CurEnv = &Environment[eep];

    return 1;
  }
}

/**
 * Frees an evaluation environment.
 *
 * @param thisenv  The eval environment to free.
 * @return         Boolean: true if the deletion went OK;
 *                 false if the environment to be freed was
 *                 not occupied (will print an error message).
 */
int
free_environment(int thisenv)
{
  int i;

  if ((thisenv < 0) || (thisenv > eep)) {
    fprintf(stderr, "Environment %d not occupied\n",
            thisenv);
    return 0;
  }
  else {

    Environment[thisenv].query_corpus = NULL;
    delete_symbol_table(Environment[thisenv].labels);
    Environment[thisenv].labels = NULL;

    for (i = 0; i <= Environment[thisenv].MaxPatIndex; i++) {

      switch (Environment[thisenv].patternlist[i].type) {

      case Pattern:
        free_booltree(Environment[thisenv].patternlist[i].con.constraint);
        Environment[thisenv].patternlist[i].con.constraint = NULL;
        Environment[thisenv].patternlist[i].con.label = NULL;
        Environment[thisenv].patternlist[i].con.is_target = False;
        Environment[thisenv].patternlist[i].con.lookahead = False;
        break;

      case Tag:
        Environment[thisenv].patternlist[i].tag.attr = NULL;
        Environment[thisenv].patternlist[i].tag.right_boundary = NULL;
        cl_free(Environment[thisenv].patternlist[i].tag.constraint);
        Environment[thisenv].patternlist[i].tag.flags = 0;
        if (Environment[thisenv].patternlist[i].tag.rx) {
          cl_delete_regex(Environment[thisenv].patternlist[i].tag.rx);
          Environment[thisenv].patternlist[i].tag.rx = NULL;
        }
        break;

      case Anchor:
        Environment[thisenv].patternlist[i].anchor.field = NoField;
        break;

      case MatchAll:
        Environment[thisenv].patternlist[i].matchall.label = NULL;
        Environment[thisenv].patternlist[i].matchall.is_target = False;
        Environment[thisenv].patternlist[i].matchall.lookahead = False;
        break;

      default:
        assert("Illegal AVS type in pattern list of ee" && 0);
        break;
      }
    }

    Environment[thisenv].MaxPatIndex = -1;

    free_booltree(Environment[thisenv].gconstraint);
    Environment[thisenv].gconstraint = NULL;

    free_evaltree(&Environment[thisenv].evaltree);

    if (Environment[thisenv].dfa.TransTable)
      free_dfa(&Environment[thisenv].dfa);

    Environment[thisenv].search_context.direction = leftright;
    Environment[thisenv].search_context.type = word;
    Environment[thisenv].search_context.attrib = NULL;
    Environment[thisenv].search_context.size = 0;

    Environment[thisenv].has_target_indicator = 0;

    return 1;
  }
}

void
show_environment(int thisenv)
{
  if ((thisenv < 0) || (thisenv > eep))
    fprintf(stderr, "Environment %d not used\n",
            thisenv);
  else {
    
    printf("\n ================= ENVIRONMENT #%d ===============\n\n", thisenv);
    
    printf("Has %starget indicator.\n", Environment[thisenv].has_target_indicator ? "" : "no ");

    if (show_compdfa) {
      printf("\n==================== DFA:\n\n");
      show_complete_dfa(Environment[thisenv].dfa);
    }
    
    if (show_evaltree) {
      printf("\n==================== Evaluation Tree:\n\n");
      print_evaltree(thisenv, Environment[thisenv].evaltree, 0);
    }

    if (show_gconstraints) {
      printf("\n==================== Global Constraints:\n\n");
      print_booltree(Environment[thisenv].gconstraint, 0);
    }
    
    if (show_patlist)
      show_patternlist(thisenv);

    printf(" ================= END ENVIRONMENT #%d =============\n", thisenv);
    fflush(stdout);
  }
}

void
free_environments(void)
{
  int i;

  for (i = 0; i <= eep; i++)
    if (!free_environment(i)) {
      fprintf(stderr, "Problems while free'ing environment %d\n", i);
      break;
    }
  eep = -1;
}
