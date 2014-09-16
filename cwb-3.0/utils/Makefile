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

# the following targets are available
#
#  all		compile tools
#  clean        delete object files and binaries
#  realclean    also deleted automatically generated parsers and dependencies
#  depend	update dependencies
#  install	install tool binaries
#  uninstall	uninstall tools from chosen location (currently not supported)
#  relase       install to binary release dir
#  size		print size of source code (line counts)
#

.PHONY: all clean realclean depend install uninstall size

## ----------------------------------------------------------------------
## CWB command-line utilities  headers / sources / binaries 

SRCS =  cwb-atoi.c cwb-itoa.c \
	cwb-makeall.c \
	cwb-encode.c cwb-decode.c cwb-lexdecode.c \
	cwb-huffcode.c cwb-compress-rdx.c \
	cwb-s-encode.c cwb-s-decode.c \
	cwb-describe-corpus.c cwb-decode-nqrfile.c \
	cwb-scan-corpus.c \
	barlib.c feature_maps.c \
	cwb-align.c cwb-align-show.c cwb-align-encode.c

HDRS =	barlib.h feature_maps.h

## PROGRAMS: the utils which form an essential part of the CWB (plus some useful helper tools)
#       cwb-atoi, cwb-itoa  convert ascii to CWB integers and vice versa
#       cwb-encode          encode corpus (position stream & lexicon)
#       cwb-makeall         create index & sorted index components (using Corpus Library)
#       cwb-huffcode	    compress token stream of p-attribute
#       cwb-compress-rdx    compress index of p-attribute
#       cwb-decode          decode corpus (output corpus in text format)
#       cwb-lexdecode       decode corpus lexicon
#       cwb-s-encode        add s-attribute to encoded corpus
#       cwb-s-decode        decode s-attribute (output: <reg.start> TAB <reg.end> TAB <annotation>)
#       cwb-describe-corpus prints some corpus info and/or statistics
#       cwb-decode-nqrfile  decode named query result file (prints information on STDOUT)
#       cwb-scan-corpus     scan corpus for n-grams of adjacent tokens or different p-attributes
#       cwb-align           EasyAlign sentence aligner (operates on CWB-encoded corpora)
#       cwb-align-show      simple terminal-based viewer for EasyAlign alignment files (.align)
#       cwb-align-encode    encode .align file into CWB format (.alx, and .alg for backward compatibility)

PROGRAMS = cwb-atoi$(EXEC_SUFFIX) cwb-itoa$(EXEC_SUFFIX) \
	cwb-makeall$(EXEC_SUFFIX) \
	cwb-encode$(EXEC_SUFFIX) cwb-decode$(EXEC_SUFFIX) cwb-lexdecode$(EXEC_SUFFIX) \
	cwb-huffcode$(EXEC_SUFFIX) cwb-compress-rdx$(EXEC_SUFFIX) \
	cwb-s-encode$(EXEC_SUFFIX) cwb-s-decode$(EXEC_SUFFIX) \
	cwb-describe-corpus$(EXEC_SUFFIX) cwb-decode-nqrfile$(EXEC_SUFFIX) \
	cwb-scan-corpus$(EXEC_SUFFIX) \
	cwb-align$(EXEC_SUFFIX) cwb-align-show$(EXEC_SUFFIX) cwb-align-encode$(EXEC_SUFFIX)

## ----------------------------------------------------------------------

all: $(PROGRAMS)

## general linking rule for all utility programs
cwb-%$(EXEC_SUFFIX): cwb-%.o
	$(RM) $@
	$(CC) $(CFLAGS) -o $@ $< $(CL_LIBS) $(LDFLAGS_ALL)

## special rule for align program, which requires barlib.o and feature_maps.o libraries
cwb-align$(EXEC_SUFFIX): cwb-align.o barlib.o feature_maps.o
	$(RM) $@
	$(CC) $(CFLAGS) -o $@ $^ $(CL_LIBS) $(LDFLAGS_ALL)

depend:
	-$(RM) depend.mk
	$(MAKE) depend.mk

depend.mk:
	-$(RM) depend.mk
	$(DEPEND) $(DEPEND_CFLAGS_ALL) $(SRCS) > depend.mk

install: $(PROGRAMS)
	if [ ! -d "$(BININSTDIR)" ]; then $(INSTALL) $(INST_FLAGS_DIR) "$(BININSTDIR)"; fi;
	for i in $(PROGRAMS); do $(INSTALL) $(INST_FLAGS_BIN) $$i "$(BININSTDIR)"; done

release: $(PROGRAMS)
	if [ ! -d "$(RELEASE_DIR)/bin" ]; then $(INSTALL) $(INST_FLAGS_DIR) "$(RELEASE_DIR)/bin"; fi;
	for i in $(PROGRAMS); do $(INSTALL) $(INST_FLAGS_BIN) $$i "$(RELEASE_DIR)/bin"; done

uninstall:
	@$(ECHO) "ERROR: uninstall operation is currently not supported!"
# 	for i in $(PROGRAMS) ;\
# 	do \
# 	$(RM) $(BININSTDIR)/$$i ; \
# 	done

size:
	$(WC) $(SRCS) $(HDRS)

clean:
	$(RM) $(PROGRAMS) *.o *~

realclean:	clean
	-$(RM) depend.mk

# -------- dependencies --------
include depend.mk

