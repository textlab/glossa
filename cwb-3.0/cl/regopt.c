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
#include "regopt.h"

/**
 * @file
 *
 * The CL_Regex object, and the CL Regular Expression Optimiser.
 *
 * This is the CL front-end to POSIX regular expressions with CL semantics
 * (most notably: CL regexes always match the entire string and NOT
 * substrings.)
 *
 * Note that the optimiser is handled automatically by the CL_Regex object.
 *
 * All variables / functions containing "regopt" are internal to this
 * module and are not exported in the CL API.
 *
 * Optimisation is done by means of "grains". The grain array in a CL_Regex
 * object is a list of short strings. Any string which will match the
 * regex must contain at least one of these. Thus, the grains
 * provide a quick way of filtering out strings that definitely WON'T
 * match, and avoiding a time-wasting call to the POSIX regex
 * matching function.
 *
 * While a regex is being optimised, the grains are stored in non-exported
 * global variables in this module. Subsequently they are transferred to
 * members of the CL_regex object with which they are associated.
 * The use of global variables and a fixed-size buffer for
 * grains is partly due to historical reasons,
 * but it does also serve to reduce memory allocation overhead.
 */

char *cl_regopt_grain[MAX_GRAINS]; /**< list of 'grains' (any matching string must contain one of these) */
int cl_regopt_grain_len;           /**< all the grains have the same length */
int cl_regopt_grains;              /**< number of grains */
int cl_regopt_anchor_start;        /**< Boolean: whether grains are anchored at beginning of string */
int cl_regopt_anchor_end;          /**< Boolean: whether grains are anchored at end of string */

/**  A jump table for Boyer-Moore search algorithm; use _unsigned_ char as index; @see make_jump_table */
int cl_regopt_jumptable[256];

/**
 * Intermediate buffer for grains.
 *
 * When a regex is parsed, grains for each segment are written to this intermediate buffer;
 * if the new set of grains is better than the current one, it is copied to the global variables.
 */
char *grain_buffer[MAX_GRAINS];
/** The number of grains currently in the intermediate buffer. @see grain_buffer */
int grain_buffer_grains = 0;

/** A buffer for grain strings. @see local_grain_data */
char public_grain_data[MAX_LINE_LENGTH];
/** A buffer for grain strings. @see public_grain_data */
char local_grain_data[MAX_LINE_LENGTH];

int cl_regopt_analyse(char *regex);

/*
 * interface functions
 */

/**
 * The error message from (POSIX) regex compilation are placed in this buffer
 * if cl_new_regex() fails.
 */
char cl_regex_error[MAX_LINE_LENGTH];

/**
 * Create a new CL_regex object (ie a regular expression buffer).
 *
 * The regular expression is preprocessed according to the flags, and
 * anchored to the start and end of the string. (That is, ^ is added to
 * the start, $ to the end.)
 *
 * Then the resulting regex is compiled (using POSIX compilation) and
 * optimised. Currently the character set parameter is ignored and
 * assumed to be Latin-1.
 *
 * @param regex    String containing the regular expression
 * @param flags    IGNORE_CASE, or IGNORE_DIAC, or both, or 0.
 * @param charset  The character set of the regex. Currently ignored.
 * @return         The new CL_Regex object, or NULL in case of error.
 */
CL_Regex cl_new_regex(char *regex, int flags, CorpusCharset charset)
{
  char *iso_regex; /* allocate dynamically to support very long regexps (from RE() operator) */
  char *anchored_regex;
  CL_Regex rx;
  int error_num, optimised, i, l;

  /* allocate temporary strings */
  l = strlen(regex);
  iso_regex = (char *) cl_malloc(l + 1);
  anchored_regex = (char *) cl_malloc(l + 5);

  /* allocate and initialise CL_Regex object */
  rx = (CL_Regex) cl_malloc(sizeof(struct _CL_Regex));
  rx->iso_string = NULL;
  rx->charset = charset;
  rx->flags = flags & (IGNORE_CASE | IGNORE_DIAC); /* mask unsupported flags */
  rx->grains = 0; /* indicates no optimisation -> other opt. fields are invalid */

  /* pre-process regular expression (translate latex escapes and normalise) */
  cl_string_latex2iso(regex, iso_regex, l);
  cl_string_canonical(iso_regex, rx->flags);

  /* add start and end anchors to improve performance of regex matcher for expressions such as ".*ung" */
  sprintf(anchored_regex, "^(%s)$", iso_regex);

  /* compile regular expression with POSIX library function */
  error_num = regcomp(&rx->buffer, anchored_regex, REG_EXTENDED | REG_NOSUB);
  if (error_num != 0) {
    (void) regerror(error_num, NULL, cl_regex_error, MAX_LINE_LENGTH);
    fprintf(stderr, "Regex Compile Error: %s\n", cl_regex_error);
    cl_free(rx);
    cl_free(iso_regex);
    cl_free(anchored_regex);
    cderrno = CDA_EBADREGEX;
    return NULL;
  }

  /* allocate string buffer for cl_regex_match() function if flags are present */
  if (flags)
    rx->iso_string = (char *) cl_malloc(MAX_LINE_LENGTH); /* this is for the string being matched, not the regex! */

  /* attempt to optimise regular expression */
  optimised = cl_regopt_analyse(iso_regex);
  if (optimised) { /* copy optimiser data to CL_Regex object */
    rx->grains = cl_regopt_grains;
    rx->grain_len = cl_regopt_grain_len;
    rx->anchor_start = cl_regopt_anchor_start;
    rx->anchor_end = cl_regopt_anchor_end;
    for (i = 0; i < 256; i++)
      rx->jumptable[i] = cl_regopt_jumptable[i];
    for (i = 0; i < rx->grains; i++)
      rx->grain[i] = cl_strdup(cl_regopt_grain[i]);
    if (cl_debug)
      fprintf(stderr, "CL: using %d grain(s) for optimised regex matching\n",
          rx->grains);
  }

  cl_free(iso_regex);
  cl_free(anchored_regex);
  cderrno = CDA_OK;
  return rx;
}

/**
 * Finds the level of optimisation of a CL_Regex.
 *
 * This function returns the approximate level of optimisation,
 * computed from the ratio of grain length to number of grains
 * (0 = no grains, ergo not optimised at all).
 *
 * @param rx  The CL_Regex to check.
 * @return    0 if rx is not optimised; otherwise an integer
 *            indicating optimisation level.
 */
int cl_regex_optimised(CL_Regex rx)
{
  if (rx->grains == 0)
    return 0; /* not optimised */
  else {
    int level = (3 * rx->grain_len) / rx->grains;
    return ((level >= 1) ? level + 1 : 1);
  }
}

/**
 * Matches a regular expression against a string.
 *
 * The regular expression contained in the CL_Regex is compared to the string.
 * No settings or flags are passed to this function; rather, the
 * settings that rx was created with are used.
 *
 * @param rx   The regular expression to match.
 * @param str  The string to compare the regex to.
 * @return     Boolean: true if the regex matched, otherwise false.
 */
int cl_regex_match(CL_Regex rx, char *str)
{
  char *iso_string; /* either the original string or a pointer to rx->iso_string */
  int optimised = (rx->grains > 0);
  int i, di, k, max_i, len, jump;
  int grain_match, result;

  if (rx->flags) { /* normalise input string if necessary */
    iso_string = rx->iso_string;
    strcpy(iso_string, str);
    cl_string_canonical(iso_string, rx->flags);
  }
  else
    iso_string = str;

  grain_match = 0;
  if (optimised) {
    /* this 'optimised' matcher may look fairly bloated, but it's still way ahead of POSIX regexen */
    len = strlen(iso_string);
    /* string offset where first character of each grain would be */
    max_i = len - rx->grain_len; /* stop trying to match when i > max_i */
    if (rx->anchor_end)
      i = (max_i >= 0) ? max_i : 0; /* if anchored at end, align grains with end of string */
    else
      i = 0;

    while (i <= max_i) {
      jump = rx->jumptable[(unsigned char) iso_string[i + rx->grain_len - 1]];
      if (jump > 0) {
        i += jump; /* Boyer-Moore search */
      }
      else {
        for (k = 0; k < rx->grains; k++) {
          char *grain = rx->grain[k];
          di = 0;
          while ((di < rx->grain_len) && (grain[di] == iso_string[i + di]))
            di++;
          if (di >= rx->grain_len) {
            grain_match = 1;
            break; /* we have found a grain match and can quit the loop */
          }
        }
        i++;
      }
      if (rx->anchor_start)
        break; /* if anchored at start, only the first iteration can match */
    }
  }

  if (optimised && !grain_match) /* enabled since version 2.2.b94 (14 Feb 2006) -- before: && cl_optimize */
    result = REG_NOMATCH; /* according to POSIX.2 */
  else
    result = regexec(&(rx->buffer), iso_string, 0, NULL, 0);

#if 0  /* debugging code used before version 2.2.b94 */
  /* critical: optimiser didn't accept candidate, but regex matched */
  if ((result == 0) && optimised && !grain_match)
  fprintf(stderr, "CL ERROR: regex optimiser did not accept '%s' although it should have!\n", iso_string);
#endif

  return (result == 0); /* return true if regular expression matched */
}

/**
 * Deletes a CL_Regex object.
 *
 * @param rx  The CL_Regex to delete.
 */
void cl_delete_regex(CL_Regex rx)
{
  int i;
  regfree(&(rx->buffer));           /* free POSIX regex buffer */
  cl_free(rx->iso_string);          /* free string buffer if it was allocated */
  for (i = 0; i < rx->grains; i++)
    cl_free(rx->grain[i]);          /* free grain strings if regex was optimised */
  free(rx);
}

/*
 * helper functions (for optimiser)
 */

/**
 * Is the given character a 'safe' character which will only match itself in a regex?
 *
 * @param c  The character
 * @return   True for non-special characters; false for special characters.
 */
int is_safe_char(unsigned char c)
{
  if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
      || (c >= '0' && c <= '9') || (c == '-' || c == '"' || c == '\'' || c
      == '%' || c == '&' || c == '/' || c == '_' || c == '!' || c == ':' || c
      == ';' || c == ',') || (c >= 128 /* && c <= 255 */)) { /* c <= 255 produces 'comparison is always true' compiler warning */
    return 1;
  }
  else {
    return 0;
  }
}

/**
 * Reads in a grain from a regex - part of the CL Regex Optimiser.
 *
 * A grain is a string of safe symbols not followed by ?, *, or {..}.
 * This function finds the longest grain it can starting at the point
 * in the regex indicated by mark; backslash-escaped characters are
 * allowed  but the backslashes must be stripped by the caller.
 *
 * @param mark  Pointer to location in the regex string from
 *              which to read.
 * @return      Pointer to the first character after the grain
 *              it has read in (or the original  "mark" pointer
 *              if no grain is found).
 */
char *
read_grain(char *mark)
{
  char *point = mark;
  int last_char_escaped = 0, glen;

  glen = 0; /* effective length of grain */
  while (is_safe_char(*point) || ((*point == '\\') && (point[1]))) {
    if (*point == '\\') {
      /* skip backslash and escaped character (but not at end of string)*/
      point++;
      last_char_escaped = 1;
    }
    else {
      last_char_escaped = 0;
    }
    point++;
    glen++;
  }
  if (point > mark) {        /* if followed by ?, *, or {..}, shrink grain by one char */
    if (*point == '?' || *point == '*' || *point == '{') {
      point--;
      glen--;
      if (last_char_escaped) /* if last character was escaped, make sure to remove the backslash as well */
        point--;
    }
  }
  if (glen >= 2)
    return point;
  else
    return mark;
}

/**
 * Reads in a matchall (dot wildcard) or safe character -
 * part of the CL Regex Optimiser.
 *
 * This function reads in matchall, any safe character,
 * or a reasonably safe-looking character class.
 *
 * @param mark  Pointer to location in the regex string from
 *              which to read.
 * @return      Pointer to the first character after the character
 *              (class) it has read in (or the original "mark"
 *              pointer if something suitable was not read).
 */
char *
read_matchall(char *mark)
{
  if (*mark == '.') {
    return mark + 1;
  }
  else if (*mark == '[') {
    char *point = mark + 1;
    /* according to the POSIX standard, \ does not have a special meaning in a character class;
     we won't skip it or any other special characters with possibly messy results;
     we just accept | as a special optimisation for the matches and contains operators in CQP */
    while (*point != ']' && *point != '\\' && *point != '[' && *point != '\0') {
      point++;
    }
    return (*point == ']') ? point + 1 : mark;
  }
  else if (is_safe_char(*mark)) {
    return mark + 1;
  }
  else if (*mark == '\\') {      /* outside a character class, \ always escapes to literal meaning */
    return mark + 2;
  }
  else {
    return mark;
  }
}

/**
 * Reads in a repetition marker - part of the CL Regex Optimiser.
 *
 * This function reads in a Kleene star (asterisk), ?, +, or
 * the general repetition modifier {n,n}; it returns a pointer
 * to the first character after the repetition modifier it has
 * found.
 *
 * @param mark  Pointer to location in the regex string from
 *              which to read.
 * @return      Pointer to the first character after the star
 *              or other modifier it has read in (or the original
 *              "mark" pointer if a repetion modifier was not
 *              read).
 */
char *
read_kleene(char *mark)
{
  char *point = mark;
  if (*point == '?' || *point == '*' || *point == '+') {
    return point + 1;
  }
  else if (*point == '{') {
    point++;
    while ((*point >= '0' && *point <= '9') || (*point == ',')) {
      point++;
    }
    return (*point == '}') ? point + 1 : mark;
  }
  else {
    return mark;
  }
}

/**
 * Reads in a wildcard - part of the CL Regex Optimiser.
 *
 * This function reads in a wildcard segment matching arbitrary
 * substring (but without a '|' symbol); it returns a pointer
 * to the first character after the wildcard segment.
 *
 * @param mark  Pointer to location in the regex string from which to read.
 * @return      Pointer to the first character after the
 *              wildcard segment (or the original "mark" pointer
 *              if a wildcard was not read).
 */
char *
read_wildcard(char *mark)
{
  char *point;
  point = read_matchall(mark);
  if (point > mark) {
    return read_kleene(point);
  }
  else {
    return mark;
  }
}

/**
 * Finds grains in a disjunction group - part of the CL Regex Optimiser.
 *
 * This function find grains in disjunction group within a regular expression;
 * the grains are then stored in the grain_buffer.
 *
 * The first argument, mark, must point to the '(' at beginning of the
 * disjunction group.
 *
 * The booleans align_start and align_end are set to true if the grains from
 * *all* alternatives are anchored at the start or end of the disjunction
 * group, respectively.
 *
 * This is a non-exported function.
 *
 * @param mark         Pointer to the disjunction group (see also function
 *                     description).
 * @param align_start  See function description.
 * @param align_end    See function description.
 * @return             A pointer to first character after the disjunction group
 *                     iff the parse succeeded, the original pointer in
 *                     the mark argument otherwise.
 *
 */
char *
read_disjunction(char *mark, int *align_start, int *align_end)
{
  char *point, *p2, *q, *buf;
  int grain, failed;

  if (*mark == '(') {
    point = mark + 1;
    buf = local_grain_data;
    grain_buffer_grains = 0;
    grain = 0;
    failed = 0;

    /* if we can extend the disjunction parser to allow parentheses around the initial segment of 
     an alternative, then regexen created by the matches operator will also be optimised! */
    *align_start = *align_end = 1;
    while (1) { /* loop over alternatives in disjunction */
      for (p2 = read_grain(point); p2 == point; p2 = read_grain(point)) {
        p2 = read_wildcard(point); /* try skipping data until grain is found */
        if (p2 > point) {
          point = p2; /* advance point and look for grain again */
          *align_start = 0; /* grain in this alternative can't be aligned at start */
        }
        else
          break;                   /* didn't find grain and can't skip any further, so give up */
      }
      if (p2 == point) {
        failed = 1;                /* no grain found in this alternative -> return failure */
        break;
      }
      if (grain < MAX_GRAINS) {
        grain_buffer[grain] = buf; /* copy grain into local grain buffer */
        for (q = point; q < p2; q++) {
          if (*q == '\\')
            q++;                   /* skip backslash used as escape character */
          *buf++ = *q;
        }
        *buf++ = '\0';
      }
      grain++;
      point = p2;
      while (*point != '|') {
        p2 = read_wildcard(point); /* try skipping data up to next | or ) */
        if (p2 > point) {
          point = p2;
          *align_end = 0;          /* grain in this alternative can't be aligned at end */
        }
        else
          break;
      }
      if (*point == '|')
        point++;                   /* continue with next alternative */
      else
        break;                     /* abort scanning */
    }

    if (*point == ')' && !failed) {
      /* if point is at ) character, we've successfully read the entire disjunction */
      grain_buffer_grains = (grain > MAX_GRAINS) ? 0 : grain;
      return point + 1;            /* continue parsing after disjunction */
    }
    else {
      return mark;                 /* failed to parse disjunction and identify grains */
    }
  }
  else {
    return mark;
  }
}

/**
 * Updates the public grain buffer -- part of the CL Regex Optimiser.
 *
 * This function copies the local grains to the public buffer, if they
 * are better than the set of grains currently there.
 *
 * A non-exported function.
 *
 * @param front_aligned  Boolean: if true, grain strings are aligned on
 *                       the left when they are reduced to equal lengths.
 * @param anchored       Boolean: if true, the grains are anchored at
 *                       beginning or end of string, depending on
 *                       front_aligned.
 */
void update_grain_buffer(int front_aligned, int anchored)
{
  char *buf = public_grain_data;
  int i, len, N;

  N = grain_buffer_grains;
  if (N > 0) {
    len = MAX_LINE_LENGTH;
    for (i = 0; i < N; i++) {
      int l = strlen(grain_buffer[i]);
      if (l < len)
        len = l;
    }
    if (len >= 2) { /* minimum grain length is 2 */
      /* we make a heuristics decision whether the new set of grains is better than the current one;
       based on grain length and the number of grains */
      if ((len > (cl_regopt_grain_len + 1)) || ((len == (cl_regopt_grain_len
          + 1)) && (N <= (3 * cl_regopt_grains))) || ((len
          == cl_regopt_grain_len) && (N < cl_regopt_grains)) || ((len
          == (cl_regopt_grain_len - 1)) && ((3 * N) < cl_regopt_grains))) {
        /* the new set of grains is better, copy them to the output buffer */
        for (i = 0; i < N; i++) {
          int l, diff;
          strcpy(buf, grain_buffer[i]);
          cl_regopt_grain[i] = buf;
          l = strlen(buf);
          assert((l >= len) && "Sorry, I messed up grain lengths while optimising a regex.");
          if (l > len) { /* reduce grains to common length */
            diff = l - len;
            if (front_aligned) {
              buf[len + 1] = '\0'; /* chop off tail */
            }
            else {
              cl_regopt_grain[i] += diff; /* chop off head, i.e. advance string pointer */
            }
          }
          buf += l + 1;
        }
        cl_regopt_grains = N;
        cl_regopt_grain_len = len;
        cl_regopt_anchor_start = cl_regopt_anchor_end = 0;
        if (anchored) {
          if (front_aligned)
            cl_regopt_anchor_start = 1;
          else
            cl_regopt_anchor_end = 1;
        }
      }
    }
  }
}

/**
 * Computes a jump table for Boyer-Moore searches.
 *
 * Unlike the textbook version, this jumptable includes the last
 * character of each grain (in order to avoid running the string
 * comparing loops every time).
 *
 * A non-exported function.
 */
void make_jump_table(void)
{
  int j, k, jump;
  unsigned int ch;
  unsigned char *grain; /* want unsigned char to compare with unsigned int ch */

  for (ch = 0; ch < 256; ch++)
    cl_regopt_jumptable[ch] = 0;
  if (cl_regopt_grains > 0) {
    /* compute smallest jump distance for each character (0 -> matches last character of one or more grains) */
    for (ch = 32; ch < 256; ch++) {
      jump = cl_regopt_grain_len; /* if character isn't contained in any of the grains, jump by grain length */
      for (k = 0; k < cl_regopt_grains; k++) {
        grain = (unsigned char *) cl_regopt_grain[k] + cl_regopt_grain_len - 1; /* pointer to last character in grain */
        for (j = 0; j < cl_regopt_grain_len; j++, grain--) {
          if (*grain == ch) {
            if (j < jump)
              jump = j;
            break; /* can't find shorter jump dist. for this grain */
          }
        }
      }
      cl_regopt_jumptable[ch] = jump;
    }
    if (cl_debug) {
      fprintf(stderr, "CL: cl_regopt_jumptable for Boyer-Moore search is\n");
      for (k = 32; k < 256; k += 16) {
        fprintf(stderr, "CL: ");
        for (j = 0; j < 15; j++) {
          ch = k + j;
          fprintf(stderr, "|%2d %c ", cl_regopt_jumptable[ch], ch);
        }
        fprintf(stderr, "\n");
      }
    }
  }
}

/**
 * Analyses a regular expression and tries to find the best set of grains.
 *
 * Part of the regex optimiser. For a given regular expression, this function will
 * try to extract a set of grains from regular expression {regex_string}. These
 * grains are then used by the CL regex matcher and cl_regex2id()
 * for faster regular expression search.
 *
 * If successful, this function returns True and stores the grains
 * in the optiomiser's global variables above (from which they should be copied
 * to a CL_Regex object's corresponding members).
 *
 * Usage: optimised = cl_regopt_analyse(regex_string);
 *
 * This is a non-exported function.
 *
 * @param regex  String containing the regex to optimise.
 * @return       Boolean: true = ok, false = couldn't optimise regex.
 */
int cl_regopt_analyse(char *regex)
{
  char *point, *mark, *q, *buf;
  int i, ok, at_start, at_end, align_start, align_end, anchored;

  mark = regex;
  if (cl_debug) {
    fprintf(stderr, "CL: cl_regopt_analyse('%s')\n", regex);
  }
  cl_regopt_grains = 0;
  cl_regopt_grain_len = 0;
  cl_regopt_anchor_start = cl_regopt_anchor_end = 0;

  ok = 1;
  while (ok) {
    at_start = (mark == regex);
    point = read_grain(mark);
    if (point > mark) { /* found single grain segment -> copy to local buffer */
      buf = local_grain_data;
      for (q = mark; q < point; q++) {
        if (*q == '\\')
          q++; /* skip backslash used as escape character */
        *buf++ = *q;
      }
      *buf++ = '\0';
      grain_buffer[0] = local_grain_data;
      grain_buffer_grains = 1;
      mark = point;
      /* update public grain set */
      at_end = (*mark == '\0');
      anchored = (at_start || at_end);
      update_grain_buffer(at_start, anchored);
      if (*mark == '+')
        mark++; /* last character of grain may be repeated -> skip the '+' */
    }
    else {
      point = read_disjunction(mark, &align_start, &align_end);
      if (point > mark) { /* found disjunction group, which is automatically stored in the local grain buffer */
        mark = point;
        /* can't accept grain set if disjunction could be optional: (..)?, (..)*, (..){0,} */
        if ((*mark == '?') || (*mark == '*') || (*mark == '{')) {
          mark = read_kleene(mark); /* accept as wildcard segment */
        }
        else {
          /* update public grain set */
          at_end = (*mark == '\0');
          at_start = (at_start && align_start); /* check that grains within disjunction are aligned, too */
          at_end = (at_end && align_end);
          anchored = (at_start || at_end);
          update_grain_buffer(at_start, anchored);
          if (*mark == '+')
            mark++;
        }
      }
      else {
        point = read_wildcard(mark);
        if (point > mark) { /* found segment matching some substring -> skip */
          mark = point;
        }
        else {
          ok = 0; /* no recognised segment starting at mark */
        }
      }
    }
    /* accept if we're at end of string */
    if (*mark == '\0') {
      ok = (cl_regopt_grains > 0) ? 1 : 0;
      if (cl_debug && ok) {
        fprintf(stderr, "CL: Regex optimised, %d grain(s) of length %d\n",
            cl_regopt_grains, cl_regopt_grain_len);
        fprintf(stderr, "CL: grain set is");
        for (i = 0; i < cl_regopt_grains; i++) {
          fprintf(stderr, " [%s]", cl_regopt_grain[i]);
        }
        if (cl_regopt_anchor_start)
          fprintf(stderr, " (anchored at beginning of string)");
        if (cl_regopt_anchor_end)
          fprintf(stderr, " (anchored at end of string)");
        fprintf(stderr, "\n");
      }
      if (ok)
        make_jump_table(); /* compute jump table for Boyer-Moore search */
      return ok;
    }
  }

  /* couldn't analyse regexp -> no optimisation */
  return 0;
}
