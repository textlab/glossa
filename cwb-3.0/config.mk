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


# *********************************************************
# *  Edit this file to configure the CWB for your system  *
# *********************************************************

# 
# PLATFORM-SPECIFIC CONFIGURATION (OS and CPU type)
#
# Pre-defined platform configuration files:
#       unix          generic Unix / GCC configuration (should work on most Unix platforms)
#       linux         i386-Linux (generic)
#         linux-64       - configuration for 64-bit CPUs
#         linux-opteron  - with optimimzation for AMD Opteron processor
#       darwin        Mac OS X / Darwin [use one of the CPU-specific entries below]
#         darwin-g4      - with optimization for PowerPC G4 processor
#         darwin-g5      - with optimization for PowerPC G5 processor
#         darwin-i386    - configuration for i386-compatible processors
#         darwin-64      - 64-bit build on Intel Core2 and newer processors
#         darwin-universal - Universal build for ppc, i386 and x86_64 architecturs
#         darwin-core2   - optimised build for Core 2 CPU (requires Xcode 3.1 / OS X 10.5)
#       solaris       SUN Solaris 8 for SPARC CPU
#       cygwin        Win32 build using Cygwin emulation layer (experimental)
#
include $(TOP)/config/platform/linux-64

#
# SITE-SPECIFIC CONFIGURATION (installation path and other local settings)
#
# Pre-defined site configuration files:
#       standard        standard configuration (installation in /usr/local tree)
#         beta-install    ... install into separate tree /usr/local/cwb-<VERSION> (unless CWB_LIVE_DANGEROUSLY is set)
#       classic         "classic" configuration (CWB v2.2, uses /corpora/c1/registry)
#       osx-fink        Mac OS X installation in Fink's /sw tree
#       binary-release  Build binary package for release (static if possible, use with "make release")
#         osx-release     ... for Mac OS X
#         linux-release   ... for i386 Linux
#         solaris-release ... for SUN Solaris 2.x
#         linux-rpm       ... build binary RPM package on Linux (together with rpm-linux.spec)
#       cygwin          Win32 / Cygwin configuration (experimental)
#       
include $(TOP)/config/site/standard


#
# MANUAL CONFIGURATION (override individual platform and site settings)
#
# Manual configuration should only be used for testing or for one-off installation.
# If you intend to install further CWB releases on the same machine, it is recommended
# that you write your own configuration files (which can be stored outside the CWB
# source tree).  See INSTALL for more information.
#
# To override individual settings, uncomment and edit one or more of the assignments
# below.  The values shown are the "typical" defaults, but may be changed in the 
# platform and site configuration files you selected.
#

## Directory tree for software installation
# PREFIX = /usr/local

## Individual installation paths can be overridden
# BININSTDIR = $(PREFIX)/bin
# LIBINSTDIR = $(PREFIX)/lib
# INCINSTDIR = $(PREFIX)/include
# MANINSTDIR = $(PREFIX)/share/man

## Access permissions for installed files, optionally owner and group settings
# INST_PERM = 644
# INST_USER = ???
# INST_GROUP = ???

## Default registry for corpus declarations
# DEFAULT_REGISTRY = $(PREFIX)/share/cwb/registry

## CPU architecture and operating system for naming binary releases
# RELEASE_ARCH = ???  # e.g. i386 or x86_64
# RELEASE_OS = ???    # e.g. linux-2.6 or osx-10.4

## C compiler to use (GCC is highly recommended, others may not work)
# CC = gcc

## Override options for C compiler and linker (complete override)
# CFLAGS = -O2 -Wall
# LDFLAGS = -lm

## Include debugging information in binaries (for developers only, not enabled by default)
# DEBUG_FLAGS = -g

## Side-specific options are added to the standard CFLAGS and LDFLAGS (e.g. additional paths)
# SITE_CFLAGS =
# SITE_LDFLAGS =

## Some platforms require special libraries for socket/internet functionality 
# NETWORK_LIBS =

## CQP requires the termcap or ncurses library for text highlighting (setting TERMCAP_LIBS activates highlighting)
# TERMCAP_LIBS =
# TERMCAP_DEFINES = 


#
# The following settings will only need to be changed in very rare cases.  If necessary, 
# they are usually set in the platform configuration file to work around OS deficiencies.
#

## Readline library for command-line editing (currently, only the included editline library is supported)
# READLINE_LIBS = -L $(TOP)/editline -leditline
# READLINE_DEFINES = -I $(TOP)/editline

## CWB uses Flex/Bison for parsing registry files and CQP commands
# YACC = bison -d -t
# LEX = flex -8

## GNU-compatible install program (defaults to included shell script)
# INSTALL = $(TOP)/install.sh

## Sometimes, extra install flags are needed for files or directories (e.g. preserve modification time on OS X)
# INSTFLAGS_FILE = ???
# INSTFLAGS_DIR = ???

## Make index of symbols in source code for Emacs editor (usually etags or ctags -e)
# ETAGS = ???

## Update dependencies between source code files (flags depend on C compiler being used)
# DEPEND = gcc -MM -MG

## In the unlikely event that "date" does not work properly, or if you want to lie about the date
# COMPILE_DATE = $(shell date)


#
# ***** Do NOT edit anything below this point! *****
#

# load standard makefile settings (don't edit this)
include $(TOP)/definitions.mk
