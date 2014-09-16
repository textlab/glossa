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


#
# ***** This file should NOT be edited! *****
#

#
# CWB version
#
VERSION = 3.0.3

#
# Check that required configuration variables are set
#

ifndef DEFAULT_REGISTRY
$(error Configuration variable DEFAULT_REGISTRY is not set (default registry directory))
endif

ifndef PREFIX 
$(error Configuration variable PREFIX is not set (software installation tree))
endif

ifndef INST_PERM
$(error Configuration variable INST_PERM is not set (access permissions for installed files))
endif

ifndef CC
$(error Configuration variable CC is not set (C compiler to use))
endif

## these variables may be empty if no special flags or libraries are needed
# ifndef CFLAGS
# $(error Configuration variable CFLAGS is not set (C compiler options))
# endif

# ifndef LDFLAGS
# $(error Configuration variable LDFLAGS is not set (linker options))
# endif

ifndef YACC
$(error Configuration variable YACC is not set (yacc or bison parser))
endif

ifndef LEX
$(error Configuration variable LEX is not set (lex or flex scanner))
endif

ifndef AR
$(error Configuration variable AR is not set (for building archive from .o files))
endif

ifndef RANLIB
$(error Configuration variable RANLIB is not set (make table of contents for .a files))
endif


#
# Variables that are normally set here but may have to be overridden in special situations
#

ifndef ETAGS
ETAGS = $(error Cannot build TAGS file, no ETAGS program given in configuration)
endif

ifndef DEPEND
DEPEND = $(error Cannot update dependencies, no DEPEND program call given in configuration)
endif

ifndef DEPEND_CFLAGS
DEPEND_CFLAGS = $(CFLAGS)
endif

# many systems have a GNU-compatible install that may be faster than the included script
ifndef INSTALL
INSTALL = $(TOP)/instutils/install.sh -c
endif

# must be set by platform config if `date` doesn't work (or if one wants to lie)
ifndef COMPILE_DATE
COMPILE_DATE = "$(shell date)"
endif

## other configuration settings that should almost never need to be changed
ifndef CHMOD
CHMOD = chmod
endif
ifndef CP
CP = cp
endif
ifndef ECHO
ECHO = echo
endif
ifndef RM
RM = rm -f
endif
ifndef WC
WC = wc -l
endif
ifndef TAR
TAR = tar
endif


#
# Command-line flags for (GNU-compatible) install program
#

INST_FLAGS = 
ifdef INST_USER
INST_FLAGS += -o $(INST_USER)
endif
ifdef INST_GROUP
INST_FLAGS += -g $(INST_GROUP)
endif
INST_PERM_DATA = $(subst 7,6,$(subst 5,4,$(subst 3,2,$(subst 1,0,$(INST_PERM)))))
INST_PERM_BIN = $(subst 6,7,$(subst 4,5,$(subst 2,3,$(subst 0,0,$(INST_PERM_DATA)))))

INST_FLAGS_DATA = $(INSTFLAGS_FILE) -m $(INST_PERM_DATA) $(INST_FLAGS)
INST_FLAGS_BIN  = $(INSTFLAGS_FILE) -m $(INST_PERM_BIN) $(INST_FLAGS)
INST_FLAGS_DIR  = $(INSTFLAGS_DIR)  -m $(INST_PERM_BIN) $(INST_FLAGS) -d


#
# Installation directory tree (default locations under PREFIX)
#

ifndef BININSTDIR
BININSTDIR = $(PREFIX)/bin
endif
ifndef MANINSTDIR
MANINSTDIR = $(PREFIX)/share/man
endif
ifndef LIBINSTDIR
LIBINSTDIR = $(PREFIX)/lib
endif
ifndef INCINSTDIR
INCINSTDIR = $(PREFIX)/include
endif

#
# CPU architecture and operating system (only used for naming binary releases)
#

ifndef RELEASE_ARCH
RELEASE_ARCH = $(shell uname -m)
endif
ifndef RELEASE_OS
RELEASE_OS = $(shell uname -s)-$(shell uname -r)
endif

RELEASE_NAME = cwb-$(VERSION)-$(RELEASE_OS)-$(RELEASE_ARCH)
RELEASE_DIR = $(TOP)/build/$(RELEASE_NAME)

#
# Set up compiler and linker flags
#

CFLAGS += $(DEBUG_FLAGS) $(SITE_CFLAGS)
LDFLAGS += $(DEBUG_FLAGS) $(SITE_LDFLAGS)

# termcap/curses support is activated by setting TERMCAP_LIBS
ifdef TERMCAP_LIBS
CFLAGS += -DUSE_TERMCAP
endif

# same for readline library support (defaults to included editline)
ifdef READLINE_LIBS
CFLAGS += -DUSE_READLINE
endif

# define macro variables for some global settings
INTERNAL_DEFINES = -DREGISTRY_DEFAULT_PATH=\""$(DEFAULT_REGISTRY)"\" -DCOMPILE_DATE=\"$(COMPILE_DATE)\" -DVERSION=\"$(VERSION)\"

# path to locally compiled CL library and linker command
LIBCL_PATH = $(TOP)/cl/libcl.a
CL_LIBS = $(LIBCL_PATH) 

# complete sets of compiler and linker flags (allows easy specification of specific build rules)
CFLAGS_ALL = $(CFLAGS) $(INTERNAL_DEFINES) $(READLINE_DEFINES) $(TERMCAP_DEFINES)
DEPEND_CFLAGS_ALL = $(DEPEND_CLAGS) $(INTERNAL_DEFINES) $(READLINE_DEFINES) $(TERMCAP_DEFINES)
LDFLAGS_ALL = $(LDFLAGS)

# readline and termcap libraries are only needed for building CQP
LDFLAGS_CQP =  $(READLINE_LIBS) $(TERMCAP_LIBS)


#
# Chapter for manpages (only for command-line tools)
#

MANEXT = 1

#
# General .c -> .o build rule
#

%.o : %.c
	$(RM) $@
	$(CC) -c  -o $@ $(CFLAGS_ALL) $<
