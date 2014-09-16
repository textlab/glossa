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


int 
is_prime(int n) {
  int i;
  for(i = 2; i*i <= n; i++)
    if ((n % i) == 0) 
      return 0;
  return 1;
}

int 
find_prime(int n) {
  for( ; n > 0 ; n++)		/* will exit on int overflow */
    if (is_prime(n)) 
      return n;
  return 0;
}

unsigned int 
hash_string(char *string) {
  unsigned char *s = (unsigned char *)string;
  unsigned int result = 0;
  for( ; *s; s++)
    result = (result * 33 ) ^ (result >> 27) ^ *s;
  return result;
}

unsigned int 
hash_macro(char *macro_name, unsigned int args) {
  unsigned char *name = (unsigned char *)macro_name;
  unsigned int result = args;
  for( ; *name; name++)
    result = (result * 33 ) ^ (result >> 27) ^ *name;
  return result;
}
