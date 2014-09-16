##   -*-Makefile-*-
## 
##  IMS Open Corpus Workbench (CWB)
##  Copyright (C) 1993-2006 by IMS, University of Stuttgart
##  Copyright (C) 2007-     by the respective contributers (see file AUTHORS)
## 
##  This program is free software; you can redistribute it and/or modify it
##  under the terms of the GNU General Public License as published by the
##  Free Software Foundation; either version 2, or (at your option) any later
##  version.
## 
##  This program is distributed in the hope that it will be useful, but
##  WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
##  Public License for more details (in the file "COPYING", or available via
##  WWW at http://www.gnu.org/copyleft/gpl.html).

## Read configuration settings and standard definitions
TOP = $(shell pwd)/..
include $(TOP)/config.mk

## The following targets are available:
#
#  all          create archive libcl.a
#  clean        remove object files and libcl.a
#  realclean    also deleted automatically generated parsers and dependencies
#  depend       update dependencies
#  install      install libcl.a and CL headers
#  uninstall    uninstall libcl.a and headers from chosen locations (currently not supported)
#  release      install to binary release dir
#  size         print size of source code (line counts)
#

.PHONY: all clean realclean depend install uninstall size

## Use bison/flex to compile parser for registry entries
PARSEH  = registry.tab.h
PARSES  = registry.tab.c lex.creg.c
PARSEG  = registry.l registry.y
PARSEO  = registry.tab.o lex.creg.o

## cl.h header file will be installed in subdirectory cwb/
REALINCINSTDIR = $(INCINSTDIR)/cwb

## ----------------------------------------------------------------------
## CORPUS LIBRARY  headers / sources / objects 

HDRS = globals.h macros.h \
	  list.h lexhash.h \
	  bitfields.h storage.h fileutils.h \
          special-chars.h regopt.h \
	  corpus.h attributes.h makecomps.h \
	  $(PARSEH) \
          cdaccess.h \
	  bitio.h \
	  endian.h \
	  compression.h \
	  binsert.h \
	  class-mapping.h   # used by lexdecode

SRCS   = globals.c macros.c \
	  list.c lexhash.c \
          bitfields.c storage.c fileutils.c \
	  special-chars.c regopt.c \
	  corpus.c attributes.c makecomps.c \
	  $(PARSES) \
	  cdaccess.c \
	  bitio.c \
	  endian.c \
	  compression.c \
	  binsert.c \
	  class-mapping.c 
 
OBJS   = globals.o macros.o \
	  list.o lexhash.o \
	  bitfields.o storage.o fileutils.o \
	  special-chars.o regopt.o \
	  corpus.o attributes.o \
          $(PARSEO) \
	  makecomps.o \
	  cdaccess.o \
	  bitio.o \
	  endian.o \
	  compression.o \
	  binsert.o \
	  class-mapping.o 

## Extra objects (will be compiled, but not included in libcl.a) 
#   - dl_stub.o is a dummy replacement for libdl.a, which is missing in Solaris
EXTRA_OBJS = dl_stub.o

# ----------------------------------------------------------------------

all: libcl.a $(EXTRA_OBJS)

registry.tab.c registry.tab.h: registry.y corpus.h macros.h attributes.h
	$(YACC) -p creg -v registry.y

lex.creg.c: registry.l registry.y registry.tab.h corpus.h macros.h attributes.h
	$(LEX) -Pcreg registry.l

libcl.a: $(OBJS)
	$(RM) $@
	$(AR) $@ $^
	$(RANLIB) $@

install: libcl.a
	if [ ! -d "$(LIBINSTDIR)" ]; then $(INSTALL) $(INST_FLAGS_DIR) "$(LIBINSTDIR)" ; fi;
	$(INSTALL) $(INST_FLAGS_DATA) libcl.a "$(LIBINSTDIR)"
	if [ ! -d "$(REALINCINSTDIR)" ]; then $(INSTALL) $(INST_FLAGS_DIR) "$(REALINCINSTDIR)" ; fi;
	$(INSTALL) $(INST_FLAGS_DATA) cl.h "$(REALINCINSTDIR)"

release: libcl.a
	if [ ! -d "$(RELEASE_DIR)/lib" ]; then $(INSTALL) $(INST_FLAGS_DIR) "$(RELEASE_DIR)/lib"; fi;
	$(INSTALL) $(INST_FLAGS_DATA) libcl.a "$(RELEASE_DIR)/lib"
	if [ ! -d "$(RELEASE_DIR)/include/cwb" ]; then $(INSTALL) $(INST_FLAGS_DIR) "$(RELEASE_DIR)/include/cwb"; fi;
	$(INSTALL) $(INST_FLAGS_DATA) cl.h "$(RELEASE_DIR)/include/cwb"

uninstall:
	@$(ECHO) "ERROR: uninstall operation is currently not supported!"
#	$(RM) $(LIBINSTDIR)/libcl.a
#	(cd $(INCINSTDIR); $(RM) cl.h)

depend:
	-$(RM) depend.mk
	$(MAKE) depend.mk

# be sure to create bison/flex C code before making dependencies
depend.mk:	$(PARSEH) $(PARSES) $(SRCS)
	-$(RM) depend.mk
	$(DEPEND) $(DEPEND_CFLAGS_ALL) $(SRCS) > depend.mk

clean:
	-$(RM) *.o libcl.a registry.output *~

realclean: clean
	-$(RM) registry.tab.c registry.tab.c lex.creg.c registry.tab.h
	-$(RM) depend.mk

size:	$(SRCS) $(HDRS)
	$(WC) $(SRCS) $(HDRS) 


# -------- dependencies --------
include depend.mk

