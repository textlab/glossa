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

#include <ctype.h>

#include "globals.h"

#include "special-chars.h"


/**
 * Table which translates latin-1 characters to lowercase.
 *
 * Use cl_string_maptable to access.
 * @see cl_string_maptable
 */
unsigned char latin1_nocase_tab[256] = {
    0,  
    1,  2,  3,  4,  5,  6,  7,  8,  9, 10,
   11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
   21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
   31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
   41, 42, 43, 44, 45, 46, 47, 48, 49, 50,
   51, 52, 53, 54, 55, 56, 57, 58, 59, 60,
   61, 62, 63, 64,
                   97, 98, 99,100,101,102, /* ABCDEF -> abcdef */
  103,104,105,106,107,108,109,110,111,112, /* GHIJKLMNOP -> ghijklmnop */
  113,114,115,116,117,118,119,120,121,122, /* QRSTUVWXYZ -> qrstuvwxyz */
  
   91, 92, 93, 94, 95, 96, 97, 98, 99,100, /* normal */
  101,102,103,104,105,106,107,108,109,110,
  111,112,113,114,115,116,117,118,119,120,
  121,122,123,124,125,126,127,128,129,130,
  131,132,133,134,135,136,137,138,139,140,
  141,142,143,144,145,146,147,148,149,150,
  151,152,153,154,155,156,157,158,159,160,
  161,162,163,164,165,166,167,168,169,170,
  171,172,173,174,175,176,177,178,179,180,
  181,182,183,184,185,186,187,188,189,190,
  191,
      224,225,226,227,228,229,230,231,232, /* 192-222 -> x+32 but not 215 */
  233,234,235,236,237,238,239,240,241,242,
  243,244,245,246,215,248,249,250,251,252,
  253,254,
          223,224,225,226,227,228,229,230,
  231,232,233,234,235,236,237,238,239,240,
  241,242,243,244,245,246,247,248,249,250,
  251,252,253,254,255
};

/**
 * Table which translates latin-1 characters
 * with diacritics to their [A-Za-z] "equivalents",
 * including ß->s, þ->t
 *
 * Use cl_string_maptable to access.
 * @see cl_string_maptable
 */
unsigned char latin1_nodiac_tab[256] = {
    0,  
    1,  2,  3,  4,  5,  6,  7,  8,  9, 10,
   11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
   21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
   31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
   41, 42, 43, 44, 45, 46, 47, 48, 49, 50,
   51, 52, 53, 54, 55, 56, 57, 58, 59, 60,
   61, 62, 63, 64, 65, 66, 67, 68, 69, 70,
   71, 72, 73, 74, 75, 76, 77, 78, 79, 80,
   81, 82, 83, 84, 85, 86, 87, 88, 89, 90,
   91, 92, 93, 94, 95, 96, 97, 98, 99,100,
  101,102,103,104,105,106,107,108,109,110,
  111,112,113,114,115,116,117,118,119,120,
  121,122,123,124,125,126,127,128,129,130,
  131,132,133,134,135,136,137,138,139,140,
  141,142,143,144,145,146,147,148,149,150,
  151,152,153,154,155,156,157,158,159,160,
  161,162,163,164,165,166,167,168,169,170,
  171,172,173,174,175,176,177,178,179,180,
  181,182,183,184,185,186,187,188,189,190,
  191,
       65, 65, 65, 65, 65, 65, 65, 67, 69, /* uppercase */
   69, 69, 69, 73, 73, 73, 73, 68, 78, 79,
   79, 79, 79, 79,215, 79, 85, 85, 85, 85,
   89, 84,115,                  /* thorn -> 'T', szlig -> 's' */
               97, 97, 97, 97, 97, 97, 97, /* lowercase */
   99,101,101,101,101,105,105,105,105,100,
  110,111,111,111,111,111,247,111,117,117,
  117,117,121,116,121
};

/**
 * Table which translates cp-1251 (ASCII +
 * cyrillic) characters to lowercase
 *
 * Use cl_string_maptable to access.
 * @see cl_string_maptable
 */
unsigned char cp1251_nocase_tab[256] = {
    0,  
    1,  2,  3,  4,  5,  6,  7,  8,  9, 10,
   11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
   21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
   31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
   41, 42, 43, 44, 45, 46, 47, 48, 49, 50,
   51, 52, 53, 54, 55, 56, 57, 58, 59, 60,
   61, 62, 63, 64,
                   97, 98, 99,100,101,102, /* ABCDEF -> abcdef */
  103,104,105,106,107,108,109,110,111,112, /* GHIJKLMNOP -> ghijklmnop */
  113,114,115,116,117,118,119,120,121,122, /* QRSTUVWXYZ -> qrstuvwxyz */
  
   91, 92, 93, 94, 95, 96, 97, 98, 99,100, /* normal */
  101,102,103,104,105,106,107,108,109,110,
  111,112,113,114,115,116,117,118,119,120,
  121,122,123,124,125,126,127,144,131,130,
  131,132,133,134,135,136,137,154,139,140,
  157,158,159,144,145,146,147,148,149,150,
  151,152,153,154,155,156,157,158,159,160,
  162,162,188,164,180,166,167,184,169,186,
  171,172,173,174,191,176,177,179,179,180,
  181,182,183,184,185,186,187,188,190,190,
  191,224,225,226,227,228,229,230,231,232,
  233,234,235,236,237,238,239,240,241,242,
  243,244,245,246,247,248,249,250,251,252,
  253,254,255,224,225,226,227,228,229,230,
  231,232,233,234,235,236,237,238,239,240,
  241,242,243,244,245,246,247,248,249,250,
  251,252,253,254,255
};

/* cp-1251 (ASCII + cyrillic) diacritic-stripping is just the identity mapping */


/*
***
unsigned char ascii_nocase_tab[256] = {
    0,  
    1,  2,  3,  4,  5,  6,  7,  8,  9, 10,
   11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
   21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
   31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
   41, 42, 43, 44, 45, 46, 47, 48, 49, 50,
   51, 52, 53, 54, 55, 56, 57, 58, 59, 60,
   61, 62, 63, 64,
                   97, 98, 99,100,101,102, 
  103,104,105,106,107,108,109,110,111,112, 
  113,114,115,116,117,118,119,120,121,122, 
  
   91, 92, 93, 94, 95, 96, 97, 98, 99,100, 
  101,102,103,104,105,106,107,108,109,110,
  111,112,113,114,115,116,117,118,119,120,
  121,122,123,124,125,126,127,144,131,130,
  131,132,133,134,135,136,137,154,139,140,
  157,158,159,144,145,146,147,148,149,150,
  151,152,153,154,155,156,157,158,159,160,
  162,162,188,164,180,166,167,184,169,186,
  171,172,173,174,191,176,177,179,179,180,
  181,182,183,184,185,186,187,188,190,190,
  191,192,193,194,195,196,197,198,199,200,
  201,202,203,204,205,206,207,208,209,210,
  211,212,213,214,215,216,217,218,219,220,
  221,222,223,224,225,226,227,228,229,230,
  231,232,233,234,235,236,237,238,239,240,
  241,242,243,244,245,246,247,248,249,250,
  251,252,253,254,255
};
****/

/*
***
unsigned char binary_nocase_tab[256] = {
    0,  
    1,  2,  3,  4,  5,  6,  7,  8,  9, 10,
   11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
   21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
   31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
   41, 42, 43, 44, 45, 46, 47, 48, 49, 50,
   51, 52, 53, 54, 55, 56, 57, 58, 59, 60,
   61, 62, 63, 64, 65, 66, 67, 68, 69, 70,
   71, 72, 73, 74, 75, 76, 77, 78, 79, 80,
   81, 82, 83, 84, 85, 86, 87, 88, 89, 90,
   91, 92, 93, 94, 95, 96, 97, 98, 99,100,
  101,102,103,104,105,106,107,108,109,110,
  111,112,113,114,115,116,117,118,119,120,
  121,122,123,124,125,126,127,144,131,130,
  131,132,133,134,135,136,137,154,139,140,
  157,158,159,144,145,146,147,148,149,150,
  151,152,153,154,155,156,157,158,159,160,
  162,162,188,164,180,166,167,184,169,186,
  171,172,173,174,191,176,177,179,179,180,
  181,182,183,184,185,186,187,188,190,190,
  191,192,193,194,195,196,197,198,199,200,
  201,202,203,204,205,206,207,208,209,210,
  211,212,213,214,215,216,217,218,219,220,
  221,222,223,224,225,226,227,228,229,230,
  231,232,233,234,235,236,237,238,239,240,
  241,242,243,244,245,246,247,248,249,250,
  251,252,253,254,255
};
****/



/* composite tables that can automatically be generated */

/**
 * Table with identity mapping of latin-1 characters
 * (no flags)
 *
 * Use cl_string_maptable to access.
 * @see cl_string_maptable
 */
unsigned char latin1_identity_tab[256];
int latin1_identity_tab_init = 0;

/**
 * Table with mapping for the %cd flag for latin-1
 * (no case, no diacritics).
 *
 * Use cl_string_maptable to access.
 * @see cl_string_maptable
 */
unsigned char latin1_nocase_nodiac_tab[256];
int latin1_nocase_nodiac_tab_init = 0;
/* this approach will be simplified and generalised to other charsets */



/**
 * Gets a specified character mapping table for use in regular expressions.
 *
 * @param charset  The character set of this corpus. Currently ignored.
 * @param flags    The flags that specify which table is required.
 *                 Can be IGNORE_CASE and/or IGNORE_DIAC.
 * @return         Pointer to the appropriate mapping table.
 */
unsigned char *
cl_string_maptable(CorpusCharset charset /*ignored*/, int flags)
{
  int icase = (flags & IGNORE_CASE) != 0;
  int idiac = (flags & IGNORE_DIAC) != 0;
  int i;
  if (icase && idiac) {
    if (! latin1_nocase_nodiac_tab_init) {
      for (i = 0; i < 256; i++) {
        latin1_nocase_nodiac_tab[i] = latin1_nocase_tab[latin1_nodiac_tab[i]];
        if (latin1_nocase_nodiac_tab[i] != latin1_nodiac_tab[latin1_nocase_tab[i]]) {
          fprintf(stderr, "tables inconsistent for #%d -> #%d\n", i, latin1_nocase_nodiac_tab[i]);
        }
      }
      latin1_nocase_nodiac_tab_init = 1;
    }
    return latin1_nocase_nodiac_tab;
  } 
  else if (icase) {
    return latin1_nocase_tab;
  }
  else if (idiac) {
    return latin1_nodiac_tab;
  }
  else {
    if (! latin1_identity_tab_init) {
      for (i = 0; i < 256; i++) {
        latin1_identity_tab[i] = i;
      }
      latin1_identity_tab_init = 1;
    }
    return latin1_identity_tab;
  }
}


/**
 * Converts a string to canonical form.
 *
 * The "canonical form" of a string is for use in comparisons where
 * case-insensitivity and/or diacritic insensitivity is desired.
 *
 * Note that the string s is modified in place.
 *
 * @param s        The string (must be Latin-1!)
 * @param flags    The flags that specify which conversions are required.
 *                 Can be IGNORE_CASE and/or IGNORE_DIAC.
 */
void 
cl_string_canonical(char *s, int flags)
{
  register unsigned char *p, *maptable;

  if (flags) {                  /* don't waste time if no flags are specified */
    maptable = cl_string_maptable(latin1, flags);
    for (p = (unsigned char *)s; *p; p++) {
      *p = maptable[*p];
    }
  }
}




/*
 */

int
hexchar2int(char c) {
  if (c >= '0' && c <= '9')
    return c - '0';
  else if (c >= 'A' && c <= 'F')
    return 10 + (c - 'A');
  else if (c >= 'a' && c <= 'f')
    return 10 + (c - 'a');
  else 
    return -1;
}

/**
 * Converts strings with latex-style blackslash escapes
 * for accented characters to ISO-8859-1 (Latin-1).
 *
 * Syntax:
 *
 * \"[AaOoUus..] --> corresponding ISO 8859-1 character
 *
 * \{octal}      --> ISO 8859-1 character
 *
 * @param str         The string to convert.
 * @param result      The location to put the altered string (which
 *                    should be shorter, or at least no longer than,
 *                    the input string. If this parameter is NULL,
 *                    space is automatically allocated for the output.
 *                    result is allowed to be the same as str.
 * @param target_len  The maximum length of the target string. If
 *                    result is NULL, then this is set automatically.
 * @return            Pointer to the altered string (if result was NULL
 *                    you need to catch this and free it when no longer
 *                    needed).
 */
char 
*cl_string_latex2iso(char *str, char *result, int target_len)
{
  /* the positions in the source and target strings */
  int src_pos = 0;
  int target_pos = 0;
  int i;

  char c;
  int val;

/** @see cl_string_latex2iso */
#define popc(s,p) s[p++]
/** @see cl_string_latex2iso */
#define pushc(s,c,p,m) s[p++] = c; if (p>=m) goto endloop;

  if (result == NULL) {
    /* auto-allocate <result> if necessary; should be shorter than input string */
    target_len = strlen(str);
    result = (char *) cl_malloc(target_len + 1);
  }
  
  c = popc(str, src_pos);
  while ((c != '\0') && (target_pos < target_len)) {

    if (c != '\\') {
      pushc(result, c, target_pos, target_len);
      c = popc(str, src_pos);
    }
    else { /* we found a backslash */

      /* get the next character */
      c = popc(str, src_pos);

      if (isdigit(c) && isdigit(str[src_pos]) && isdigit(str[src_pos+1])) {
        val = 0;
        for (i = 0; i < 3; i++) {
          val = val * 8 + ((c - '0') % 8);
          c = popc(str, src_pos);
        }
        pushc(result, (char) (val % 256), target_pos, target_len);
      }
      else if (c == '"') {     /* diaresis / umlaut */
        switch ( c = popc(str, src_pos) ) {
        case 'A': pushc(result, 'Ä', target_pos, target_len); break;
        case 'E': pushc(result, 'Ë', target_pos, target_len); break;
        case 'I': pushc(result, 'Ï', target_pos, target_len); break;
        case 'O': pushc(result, 'Ö', target_pos, target_len); break;
        case 'U': pushc(result, 'Ü', target_pos, target_len); break;
        case 'a': pushc(result, 'ä', target_pos, target_len); break;
        case 'e': pushc(result, 'ë', target_pos, target_len); break;
        case 'i': pushc(result, 'ï', target_pos, target_len); break;
        case 'o': pushc(result, 'ö', target_pos, target_len); break;
        case 'u': pushc(result, 'ü', target_pos, target_len); break;
        case 's': pushc(result, 'ß', target_pos, target_len); break;
        default:   /* copy both */
          pushc(result, '"', target_pos, target_len);
          pushc(result, c,   target_pos, target_len);
          break;
        }
        c = popc(str, src_pos);
      }
      else if (c == '\'') {     /* accent aigu */
        switch ( c = popc(str, src_pos) ) {
        case 'A': pushc(result, 'Á', target_pos, target_len); break;
        case 'E': pushc(result, 'É', target_pos, target_len); break;
        case 'I': pushc(result, 'Í', target_pos, target_len); break;
        case 'O': pushc(result, 'Ó', target_pos, target_len); break;
        case 'U': pushc(result, 'Ú', target_pos, target_len); break;
        case 'a': pushc(result, 'á', target_pos, target_len); break;
        case 'e': pushc(result, 'é', target_pos, target_len); break;
        case 'i': pushc(result, 'í', target_pos, target_len); break;
        case 'o': pushc(result, 'ó', target_pos, target_len); break;
        case 'u': pushc(result, 'ú', target_pos, target_len); break;
        default:   /* copy both */
          pushc(result, '\'', target_pos, target_len);
          pushc(result, c,   target_pos, target_len);
          break;
        }
        c = popc(str, src_pos);
      }
      else if (c == '`') {      /* accent grave */
        switch ( c = popc(str, src_pos) ) {
        case 'A': pushc(result, 'À', target_pos, target_len); break;
        case 'E': pushc(result, 'È', target_pos, target_len); break;
        case 'I': pushc(result, 'Ì', target_pos, target_len); break;
        case 'O': pushc(result, 'Ò', target_pos, target_len); break;
        case 'U': pushc(result, 'Ù', target_pos, target_len); break;
        case 'a': pushc(result, 'à', target_pos, target_len); break;
        case 'e': pushc(result, 'è', target_pos, target_len); break;
        case 'i': pushc(result, 'ì', target_pos, target_len); break;
        case 'o': pushc(result, 'ò', target_pos, target_len); break;
        case 'u': pushc(result, 'ù', target_pos, target_len); break;
        default:   /* copy both */
          pushc(result, '`', target_pos, target_len);
          pushc(result, c,   target_pos, target_len);
          break;
        }
        c = popc(str, src_pos);
      }
      else if (c == '^') {      /* accent circonflex */
        switch ( c = popc(str, src_pos) ) {
        case 'A': pushc(result, 'Â', target_pos, target_len); break;
        case 'E': pushc(result, 'Ê', target_pos, target_len); break;
        case 'I': pushc(result, 'Î', target_pos, target_len); break;
        case 'O': pushc(result, 'Ô', target_pos, target_len); break;
        case 'U': pushc(result, 'í', target_pos, target_len); break;
        case 'a': pushc(result, 'â', target_pos, target_len); break;
        case 'e': pushc(result, 'ê', target_pos, target_len); break;
        case 'i': pushc(result, 'î', target_pos, target_len); break;
        case 'o': pushc(result, 'ô', target_pos, target_len); break;
        case 'u': pushc(result, 'û', target_pos, target_len); break;
        default:   /* copy both */
          pushc(result, '^', target_pos, target_len);
          pushc(result, c,   target_pos, target_len);
          break;
        }
        c = popc(str, src_pos);
      }
      else if (c == ',') {      /* cedille */
        switch ( c = popc(str, src_pos) ) {
        case 'C': pushc(result, 'Ç', target_pos, target_len); break;
        case 'c': pushc(result, 'ç', target_pos, target_len); break;
        default:   /* copy both */
          pushc(result, ',', target_pos, target_len);
          pushc(result, c,   target_pos, target_len);
          break;
        }
        c = popc(str, src_pos);
      }
      else if (c == '~') {
        switch ( c = popc(str, src_pos) ) {
        case 'n': pushc(result, 'ñ', target_pos, target_len); break;
        case 'N': pushc(result, 'Ñ', target_pos, target_len); break;
        default:   /* copy both */
          pushc(result, '~', target_pos, target_len);
          pushc(result, c,   target_pos, target_len);
          break;
        }
        c = popc(str, src_pos);
      }
      else if (c == 'x') {
        int hex1, hex2;
        hex1 = hexchar2int(str[src_pos]);
        hex2 = (hex1 >= 0) ? hexchar2int(str[src_pos + 1]) : -1;
        if (hex1 >= 0 && hex2 >= 0) {
          pushc(result, 16 * hex1 + hex2, target_pos, target_len);
          popc(str, src_pos);
          popc(str, src_pos);
        }
        else /* copy \x literally */ {
          pushc(result, '\\', target_pos, target_len);
          pushc(result, c, target_pos, target_len);
        }
        c = popc(str, src_pos);        
      }
      else /* copy both */ {
        pushc(result, '\\', target_pos, target_len);
        pushc(result, c, target_pos, target_len);
        c = popc(str, src_pos);
      }
    }
  }
  
endloop:
  result[target_pos] = '\0';

  return result;
}
