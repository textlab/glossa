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

#ifndef _cqp_eval_h_
#define _cqp_eval_h_

#include "../cl/cdaccess.h"
#include <regex.h>

#include "regex2dfa.h"
#include "corpmanag.h"
#include "symtab.h"


#define repeat_inf -1     /* constant which indicates 'infinite repetition' */
#define repeat_none -2    /* constant which indicates 'no repetition'       */

#define MAXPATTERNS 5000

#define MAXENVIRONMENT 10


/*
 * definition of the evaluation tree of boolean expressions
 */


/**
 * Labels a boolean operation.
 */
enum b_ops { b_and,      /**< boolean and operator           */
             b_or,       /**< boolean or operator            */
             b_implies,  /**< boolean implication (->) operator */
             b_not,      /**< boolean negation               */

             cmp_gt,     /**< compare: greater than          */
             cmp_lt,     /**< compare: less than             */
             cmp_get,    /**< compare: greater or equal than */
             cmp_let,    /**< compare: less or equal than    */
             cmp_eq,     /**< compare: equal                 */
             cmp_neq,    /**< compare: not equal             */

             cmp_ex      /**< is value present? bool exprs   */
           };


/**
 * Labels the type of a {what??}.
 */
enum wf_type { NORMAL, REGEXP, CID };

/**
 * Labels the type of a boolean node.
 */
enum bnodetype { bnode,                 /**< boolean evaluation node            */
                 cnode,                 /**< constant node                      */
                 func,                  /**< function call                      */
                 sbound,                /**< structure boundary (open or close) */
                 pa_ref,                /**< reference to positional attribute  */
                 sa_ref,                /**< reference to structural attribute  */

                 string_leaf,           /**< string constant */
                 int_leaf,              /**< integer constant */
                 float_leaf,            /**< float constant */

                 id_list,               /**< list of IDs */
                 var_ref                /**< variable reference */
               };

/**
 * Union of structures underlying the Constraint / Constrainttree objects.
 *
 * Each Constraint is a node in the Constrainttree.
 */
typedef union c_tree {

  /** The type of this particular node.
   * Allows the type member of the other structures within the union to be accessed. */
  enum bnodetype type;

  /** "standard" operand node in the evaluation tree; type is "bnode" */
  struct {
    enum bnodetype type;                  /**< must be bnode                     */
    enum b_ops     op_id;                 /**< identifier of the bool operator   */
    union c_tree  *left,                  /**< points to the first operand       */
                  *right;                 /**< points to the second operand,
                                               if present                        */
  }                node;

  /** "constant" node in the evaluation tree                     */
  struct {
    enum bnodetype type;                  /**< must be cnode                     */
    int            val;                   /**< Value of the constant: 1 or 0 for true or false */
  }                constnode;

  /** function call (dynamic attribute), type is "func" */
  struct {
    enum bnodetype type;                  /**< must be func                  */
    int            predef;
    Attribute     *dynattr;
    struct _ActualParamList *args;        /**< arguments of the function     */
    int            nr_args;               /**< nr of arguments for this call */
  }                func;

  /** structure boundary */
  struct {
    enum bnodetype type;                  /**< must be sbound                */
    Attribute     *strucattr;             /**< the attribute which corresponds to the structure */
    Boolean        is_closing;            /**< True if closing tag, False for opening tag */
  }                sbound;

  /** reference to positional attribute */
  struct {
    enum bnodetype type;                  /**< must be pa_ref */
    LabelEntry     label;                 /**< may be empty (NULL) */
    Attribute     *attr;                  /**< the P-attribute we are referring to */
    int            delete;                /**< delete label after using it ? */
  }                pa_ref;

  /**
   * reference to structural attribute.
   *
   * If label is empty, this checks if the current position is at start
   * or end of structural_attribute and returns INT value (this is kept for
   * backward compatibility regarding lbound() and rbound() builtins; the new
   * syntax is to use {s} and {/s}, which are represented as 'Tag' nodes.
   *
   * If label is non-empty, the referenced S-attribute must have values, and
   * the value of the enclosing region is returned as a string; in short,
   * values of attributes can be accessed through label references .
   */
  struct {
    enum bnodetype type;                  /**< must be sa_ref */
    LabelEntry     label;                 /**< may be empty (NULL) */
    Attribute     *attr;                  /**< the s-attribute we are referring to */
    int            delete;                /**< delete label after using it ? */
  }                sa_ref;

  struct {
    enum bnodetype type;                  /**< must be var_ref */
    char          *varName;
  }                varref;

  struct {
    enum bnodetype type;                  /**< must be id_list */
    Attribute     *attr;
    LabelEntry     label;                 /**< may be empty (NULL) */
    int            negated;
    int            nr_items;
    int           *items;                 /**< an array of item IDs of size nr_items */
    int            delete;                /**< delete label after using it ? */
  }                idlist;

  /** constant (string, int, float, ...) */
  struct {
    enum bnodetype type;                  /**< string_leaf, int_leaf, or float_leaf */

    int            canon;                 /**< canonicalization mode (i.e. flags)         */
    enum wf_type   pat_type;              /**< pattern type: normal wordform or reg. exp. */
    CL_Regex       rx;                    /**< compiled regular expression (using CL frontend) */

    /** Union containing the constant type. */
    union {
      char        *sconst;               /**< operand is a string constant.           */
      int          iconst;               /**< operand is a integer constant.          */
      int          cidconst;             /**< operand is {?? corpus position??} constant */
      double       fconst;               /**< operand is a float (well, double) constant */
    }              ctype;
  }                leaf;
} Constraint;

/**
 * The Constrainttree object.
 */
typedef Constraint * Constrainttree;


/**
 * The ActualParamList object: used to build a linked list of parameters,
 * each one of which is a Constrainttree.
 */
typedef struct _ActualParamList {
  Constrainttree param;
  struct _ActualParamList *next;
} ActualParamList;


enum tnodetype { node, leaf, meet_union, tabular };

enum re_ops  { re_od_concat,        /* order dependent concat.   */
               re_oi_concat,        /* order independent concat. */
               re_disj,                /* disjunction               */
               re_repeat        /* repetition ({n} and {n,k})*/
             };

enum cooc_op { cooc_meet,
               cooc_union
             };


typedef union e_tree *Evaltree;


/* cross-check treemacros.h after changes of this data structure!!!
 * also check the print commands in tree.c */


union e_tree {
  enum tnodetype type;

  struct {
    enum tnodetype type;
    enum re_ops    op_id;      /* id_number of the RE operator */
    Evaltree       left,       /* points to the first argument */
                   right;      /* points to the second argument -- */
                               /* if it exists.                    */
    int            min,        /* minimum number of repetitions.  */
                   max;        /* maximum number of repetitions.  */
  }                node;

  struct {
    enum tnodetype type;
    int            patindex;   /* index to the patternlist */
  }                leaf;

  struct {

    enum tnodetype type;
    enum cooc_op op_id;
    int            lw, rw;
    Attribute     *struc;
    Evaltree       left, right;

  }                cooc;

  struct {
    enum tnodetype type;

    int patindex;                /* index into pattern list */
    int min_dist;                /* minimal and maximal distance to next pattern */
    int max_dist;
    Evaltree       next;        /* next pattern */
  }                tab_el;

};

/* definition of the patternlist, which builds the 'character set' for the */
/* regular expressions of wordform patterns                                */

typedef enum _avstype {
  Pattern, Tag, MatchAll, Anchor
} AVSType;

typedef union _avs {

  AVSType type;

  /* a matchall item */
  struct {
    AVSType type;                /* MatchAll */
    LabelEntry label;
    Boolean is_target;
    Boolean lookahead;                /* whether pattern is just a lookahead constraint */
  } matchall;

  /* a constraint tree */
  struct {
    AVSType type;                /* Pattern */
    LabelEntry label;
    Constrainttree constraint;
    Boolean is_target;
    Boolean lookahead;                /* whether pattern is just a lookahead constraint */
  } con;

  /* a structure describing tag */
  struct {
    AVSType type;                /* Tag */
    int is_closing;
    Attribute *attr;
    char *constraint;                /* constraint for annotated value of region (string or regexp); NULL = no constraint */
    int flags;                        /* flags passed to regexp or string constraint (information purposes only) */
    CL_Regex rx;                /* if constraint is a regexp, this holds the compiled regexp; otherwise NULL */
    int negated;                /* whether constraint is negated (!=, not matches, not contains) */
    LabelEntry right_boundary;        /* label in RDAT namespace: contains right boundary of constraining region (in StrictRegions mode) */
  } tag;

  /* an anchor point tag (used in subqueries) */
  struct {
    AVSType type;                /* Anchor */
    int is_closing;
    FieldType field;
  } anchor;
} AVStructure;

typedef AVStructure * AVS;


typedef AVStructure Patternlist[MAXPATTERNS];

/* ====================================================================== */

enum ctxtdir { leftright, left, right };
enum spacet { word, structure };

typedef struct ctxtsp {
  enum ctxtdir   direction;        /* direction of context expansion (if valid) */
  enum spacet    type;                /* kind of space.                         */
  Attribute     *attrib;        /* attribute representing the structure.  */
  int            size;                /* size of space in number of structures. */
  int            size2;                /* only for meet-context                  */
} Context;


/* ====================================================================== */

int eep;                            /**< eval environment pointer */

/**
 * The EvalEnvironment object: environment variables for the evaluation of
 * a corpus query.
 */
typedef struct evalenv {

  CorpusList *query_corpus;         /**< the search corpus for this query part */

  int rp;                           /**< index of current range (in subqueries) */

  SymbolTable labels;               /**< symbol table for labels */

  int MaxPatIndex;                  /**< the current number of patterns */
  Patternlist patternlist;          /**< global variable which holds the pattern list */

  Constrainttree gconstraint;       /**< the "global constraint" */

  Evaltree evaltree;                /**< the evaluation tree (with regular exprs) */

  DFA  dfa;                         /**< the regex NFA for the current query */

  int has_target_indicator;         /**< is there a target mark ('@') in the query? */
  LabelEntry target_label;          /**< targets are implemented as a special label "target" now */

  LabelEntry match_label;           /**< special "match" and "matchend"-Labels for access to start & end of match within query */
  LabelEntry matchend_label;

  Context search_context;           /**< the search context (within...) */

  Attribute *aligned;               /**< the attribute holding the alignment info */

  int negated;                      /**< 1 iff we should negate alignment constr */

} EvalEnvironment;

/**
 * EEPs are Eval Environment pointers.
 */
typedef EvalEnvironment *EEP;

EvalEnvironment Environment[MAXENVIRONMENT];

EEP CurEnv, evalenv;

/* ---------------------------------------------------------------------- */

int next_environment();

Boolean eval_bool(Constrainttree ctptr, RefTab rt, int corppos);

/* ==================== the three query types */

void cqp_run_query(int cut, int keep_old_ranges);

void cqp_run_mu_query(int keep_old_ranges, int cut_value);

void cqp_run_tab_query(int implode);

/* ======================================== */

int next_environment();

int free_environment(int thisenv);

void show_environment(int thisenv);

void free_environments();

#endif
