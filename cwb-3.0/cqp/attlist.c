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
#include <string.h>

#include "../cl/macros.h"

#include "../cl/corpus.h"
#include "../cl/attributes.h"

#include "attlist.h"

/**
 * Creates a new AttributeList.
 *
 * @param element_type  What type of attribute is this? ATT_POS, ATT_STRUC, etc.
 * @return              Pointer to the new AttributeList object.
 */
AttributeList *
NewAttributeList(int element_type)
{
  AttributeList *l;

  l = (AttributeList *)cl_malloc(sizeof(AttributeList));

  l->list = NULL;
  l->element_type = element_type;
  l->list_valid = 0;
  
  return l;
}

/**
 * Deletes an AttributeList object.
 *
 * @param list  Address of the pointer to the list to delete.
 */
int
DestroyAttributeList(AttributeList **list)
{
  AttributeInfo *ai;

  /* first, deallocate all members of the list */

  ai = (*list)->list;

  while (ai) {

    AttributeInfo *ai2;

    ai2 = ai;
    ai = ai->next;

    cl_free(ai2->name);
    ai2->attribute = NULL;
    ai2->status = 0;
    ai2->next = NULL;
    ai2->prev = NULL;

    free(ai2);
  }

  (*list)->list = NULL;
  (*list)->list_valid = 0;
  (*list)->element_type = 0;

  free(*list);
  *list = NULL;

  return 1;
}


/**
 * Adds a new AttributeInfo to an AttributeList object.
 *
 * @param list            The list to add to.
 * @param name            The name of the Attribvute that this AttributeInfo refers to.
 * @param initial_status  Initial setting for the status member of the new AttributeInfo.
 * @param position        If this is 1, the new AttributeInfo is added at the beginning
 *                        of the list. If it is 0, it is added at the end of the list.
 *                        Otherwise, this specifies a particular insertion position
 *                        (the given number of steps down the linked list).
 * @return                A pointer to the new AttributeInfo, or NULL for error.
 */
AttributeInfo
*AddNameToAL(AttributeList *list,
             char *name,
             int initial_status,
             int position)
{
  if (MemberAL(list, name))
    return NULL;
  else {

    AttributeInfo *ai;
    
    ai = (AttributeInfo *)cl_malloc(sizeof(AttributeInfo));

    ai->status = initial_status;
    ai->name = cl_strdup(name);
    ai->attribute = NULL;
    ai->next = NULL;
    ai->prev = NULL;

    if (list->list == NULL)
      list->list = ai;
    else {

      if (position == 1) {

        /* insertion at beginning */
        ai->next = list->list;
        list->list = ai;

      }
      else if (position == 0) {

        /* insert new element at end of list */

        AttributeInfo *prev;

        prev = list->list;

        while (prev->next)
          prev = prev->next;

        ai->prev = prev;
        prev->next = ai;
      }
      else {

        /* insert new element at certain position */

        AttributeInfo *prev;

        prev = list->list;

        while (prev->next && position > 2) {
          prev = prev->next;
          position--;
        }

        ai->prev = prev;
        ai->next = prev->next;

        prev->next->prev = ai;
        prev->next = ai;
      }
    }

    /* return the new element */

    list->list_valid = 0;

    return ai;
  }
}


/**
 * Deletes an AttributeInfo from the AttributeList.
 *
 * @param list   The list from which to delete.
 * @param name   The name of the AttributeInfo to delete.
 * @return       True if the attribute info was found and deleted;
 *               otherwise false.
 */
int 
RemoveNameFromAL(AttributeList *list, char *name)
{
  AttributeInfo *this, *prev;

  if (list->list) {

    prev = NULL;
    this = list->list;

    while (this && strcmp(this->name, name) != 0) {
      prev = this;
      this = this->next;
    }

    if (this) {

      /* this now points to the member with the given name. */
      
      /* unchain it */

      if (prev == NULL) {
        /* this is first element of attribute list */
        list->list = this->next;
        if (this->next)
          this->next->prev = list->list;
      }
      else {
        prev->next = this->next;
        if (this->next)
          this->next->prev = prev;
      }

      cl_free(this->name);
      this->attribute = NULL;
      this->status = 0;
      this->next = NULL;
      this->prev = NULL;
      free(this);

      return 1;
    }
    else 
      /* not a member of the list */
      return 0;

  }
  else
    /* list is empty, nothing to do. */
    return 0;
}


/**
 * Deletes an AttributeInfo from the AttributeList.
 *
 * Unlike RemoveNameFromAL(), this function deletes an AttributeInfo
 * known by its pointer, rather than one known by its name.
 *
 * @see RemoveNameFromAL
 * @param list   The list from which to delete.
 * @param this   The address (pointer) of the AttributeInfo to delete.
 * @return       True if the attribute info was found and deleted;
 *               otherwise false.
 */
int 
Unchain(AttributeList *list, AttributeInfo *this)
{
  AttributeInfo *prev;

  if (list && list->list && this) {

    if (this == list->list) {
      list->list = this->next;
      if (list->list)
        list->list->prev = NULL;
    }
    else {

      prev = list->list;

      while (prev && prev->next != this)
        prev = prev->next;

      if (prev) {
        prev->next = this->next;
        if (prev->next)
          prev->next->prev = prev;
      }
      else
        this = NULL;
    }

    if (this) {
      cl_free(this->name);
      this->attribute = NULL;
      this->status = 0;
      this->prev = NULL;
      this->next = NULL;
      free(this);
      return 1;
    }
    else
      return 0;
  }
  else
    return 0;
}

/**
 * Gets the number of entries in an AttributeList.
 *
 * @param list  The list to size up.
 * @return      The number of elements in the list.
 */
int
NrOfElementsAL(AttributeList *list)
{
  int nr;
  AttributeInfo *l;

  nr = 0;
  l = list->list;

  while (l) {
    nr++;
    l = l->next;
  }

  return nr;
}


/**
 * Checks whether the AttributeList contains an entry with the given attribute name.
 *
 * @param list  The list to search.
 * @param name  The name of the element to search for.
 * @return      Boolean: true if the element is found as a member of the list.
 */
int
MemberAL(AttributeList *list, char *name)
{
  return (FindInAL(list, name) ? 1 : 0);
}


/**
 * Finds an entry in an AttribvuteList.
 *
 * @param list  The list to search.
 * @param name  The name of the element to search for.
 * @return      Pointer to the AttributeInfo with the matching name,
 *              or NULL if the name was not found.
 */
AttributeInfo *FindInAL(AttributeList *list, char *name)
{
  AttributeInfo *this;

  if (list && list->list) {

    this = list->list;

    while (this && strcmp(this->name, name) != 0)
      this = this->next;
    
    return this;
  }
  else
    return NULL;
}


/**
 * Goes through an AttributeList, deletes entries for attributes that don't exist, and adds entries for those that do.
 *
 * Note that all AttributeInfo entries are linked to the actual Attribute objects by this function.
 *
 * @param list         The AttributeList to recompute.
 * @param corpus       The corpus in which these attributes are found.
 * @param init_status  Not currently used.
 * @return             Always 1.
 */
int
RecomputeAL(AttributeList *list, Corpus *corpus, int init_status)
{
  /* silly implementation, but usually short lists. so what... */

  Attribute *attr;
  AttributeInfo *ai, *prev, *this;


  prev = NULL;
  ai = list->list;

  while (ai) {

    this = ai;
    ai = ai->next;

    if (corpus == NULL ||
        !find_attribute(corpus, this->name, list->element_type, NULL)) {

      /* unchain */

      if (prev) {
        prev->next = ai;
        if (prev->next)
          prev->next->prev = prev;
      }
      else {
        list->list = ai;
        if (ai)
          ai->prev = NULL;
      }

      /* free */

      cl_free(this->name);
      this->attribute = NULL;
      this->status = 0;
      this->prev = NULL;
      this->next = NULL;
      free(this);
      
    }
    else
      prev = this;

  }

  if (corpus) {
    for (attr = corpus->attributes; attr; attr = attr->any.next)
      if (attr->type == list->element_type) {
        ai = AddNameToAL(list, attr->any.name, 0, 0);
        if (ai)
          ai->attribute = attr;
      }
  }

  list->list_valid = 0;

  return 1;
}


/**
 * Verifies an AttributeList.
 *
 * Note that all AttributeInfo entries are linked to the actual Attribute objects by this function.
 *
 * If the relevant attribute cannot be found, the entry is deleted iff remove_illegal_entries.
 *
 * @param list                    The list to verify.
 * @param corpus                  The corpus for which this list should be valid.
 * @param remove_illegal_entries  Boolean: see function description.
 * @return                        Boolean: true for all OK, false for error.
 */
int
VerifyList(AttributeList *list,
           Corpus *corpus,
           int remove_illegal_entries)
{
  int result;
  AttributeInfo *ai, *prev, *this;
  
  result = 1;

  if (!list)
    return 0;
  
  prev = NULL;
  ai = list->list;

  while (ai) {

    ai->attribute = find_attribute(corpus, 
                                   ai->name,
                                   list->element_type,
                                   NULL);

    this = ai;
    ai = ai->next;

    if (this->attribute == NULL) {

      if (remove_illegal_entries) {

        if (prev == NULL) {

          /* delete first element */
          list->list = ai;
          if (ai)
            ai->prev = NULL;
        }
        else {
          /* unchain this element */
          prev->next = ai;
          if (ai)
            ai->prev = prev;
        }

        cl_free(this->name);
        free(this);

      }
      else 
        result = 0;
    }
    else
      prev = this;
  }

  list->list_valid = result;

  return result;
}

