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


#include "barlib.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>


/**
 * Creates an N-by-M bar with beam width W.
 *
 * @param N    First dimension size of new matrix (see BARdesc).
 * @param M    Second dimension size of new matrix (see BARdesc).
 * @param W    Beam width size of new matrix (see BARdesc).
 * @return     The new BARdesc object.
 */
BARdesc
BAR_new(int N, int M, int W)
{
  BARdesc BAR;
  int i;
  int size, vsize;

  assert(BAR = (BARdesc) malloc(sizeof(struct _BARdesc)));
  BAR->x_size = N;
  BAR->y_size = M;
  BAR->d_size = N + M;
  BAR->beam_width = W;
  vsize = BAR->d_size;
  size = vsize * W;

  /* allocate data space */
  assert(BAR->data = (int *) malloc(size * sizeof(int)));
  BAR->data_size = size;
  /* allocate and init access vectors */
  assert(BAR->d_block_start_x = (int *) malloc(vsize * sizeof(int)));
  for (i = 0; i < BAR->d_size; i++) {
    BAR->d_block_start_x[i] = -1;
  }
  assert(BAR->d_block_data = (int **) malloc(vsize * sizeof(int *)));
  for (i = 0; i < BAR->d_size; i++) {
    BAR->d_block_data[i] = BAR->data + i*W;
  }
  BAR->vector_size = vsize;
  return(BAR);
}

/**
 * Changes the size of a BAR (erasing the contents of the BAR).
 *
 * @see BARdesc
 *
 * @param BAR  The BAR to resize.
 * @param N    First dimension new size of matrix (see BARdesc).
 * @param M    Second dimension new size of matrix (see BARdesc).
 * @param W    Beam width new size of matrix (see BARdesc).
   */
void
BAR_reinit(BARdesc BAR, int N, int M, int W)
{
  int i;
  int size, vsize;

  assert(BAR);

  BAR->x_size = N;
  BAR->y_size = M;
  BAR->d_size = N + M;
  BAR->beam_width = W;
  vsize = BAR-> d_size;
  size = vsize * W;

  /* reallocate data space if necessary */
  if (size > BAR->data_size) {
    assert(BAR->data = (int *) realloc(BAR->data, size * sizeof(int)));
    BAR->data_size = size;
  }
  /* reallocate access vectors if necessary */
  if (vsize > BAR->vector_size) {
    assert(BAR->d_block_start_x = (int *) realloc(BAR->d_block_start_x, vsize * sizeof(int)));
    assert(BAR->d_block_data = (int **) realloc(BAR->d_block_data, vsize * sizeof(int *)));
    BAR -> vector_size = vsize;
  }
  /* init access vectors */
  for (i = 0; i < BAR->d_size; i++) {
    BAR->d_block_data[i] = BAR->data + i*W;
  }
  for (i = 0; i < BAR->d_size; i++) {
    BAR->d_block_start_x[i] = -1;
  }
}

/**
 * Destroys a BAR.
 *
 * @param BAR Descriptor of the BAR to destroy.
 */
void
BAR_delete(BARdesc BAR)
{
  assert(BAR);
  free(BAR->data);	
  free(BAR->d_block_start_x);
  free(BAR->d_block_data);
  free(BAR);
}

/**
 * Sets an element of a BAR.
 *
 * Usage:
 *
 * BAR_write(BAR, x, y, i);
 *
 * sets A(x,y) = i.
 *
 * - if (x,y) is outside matrix or beam range, the function call is ignored.
 * - if d_(x+y) hasn't been accessed before, the block_start_x value is set to x.
 *
 * @param BAR     BAR descriptor
   @param x       matrix x coordinate
 * @param y       matrix y coordinate
 * @param i       value to set it to
 *

 */
void
BAR_write(BARdesc BAR, int x, int y, int i)
{
  int *p, *p1;
  if (((unsigned)x < BAR->x_size) && ((unsigned)y < BAR->y_size)) { /* fast bounds check */
    int d = x + y;
    if (BAR->d_block_start_x[d] < 0) { 
      /* uninitialised diagonal */
      BAR->d_block_start_x[d] = x;
      /* initialise diagonal with zeroes */
      p1 = BAR->d_block_data[d] + BAR->beam_width;
      for (p = BAR->d_block_data[d]; p < p1; p++) *p = 0;
      BAR->d_block_data[d][0] = i;
    } 
    else {
      /* set value if within beam range */
      int dx = x - BAR->d_block_start_x[d];
      if ((unsigned)dx < BAR->beam_width) {
        BAR->d_block_data[d][dx] = i;
      }
    }
  }
}

/**
 * Reads from a BAR.
 *
 * Usage:
 *
 * i = A(x,y)
 *
 * is expressed as
 *
 * i = BAR_read(BAR, x, y);
 *
 * @param BAR     BAR descriptor
   @param x       matrix x coordinate
 * @param y       matrix y coordinate
   @return        the value of A(x,y);  if (x,y) is
                  outside matrix or beam range, returns 0.
   */
int
BAR_read(BARdesc BAR, int x, int y)
{
  if (((unsigned)x < BAR->x_size) && ((unsigned)y < BAR->y_size)) {
    int d = x + y;
    int x_start = BAR->d_block_start_x[d];
    if ((x_start >= 0) && ((unsigned)(x - x_start) < BAR->beam_width)) {
      return BAR->d_block_data[d][x - x_start];
    }
    else {
      return 0;
    }
  }
  else {
    return 0;
  }
}

