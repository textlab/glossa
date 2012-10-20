# RGlossa

RGlossa is a reimplementation of the [Glossa search system](https://github.com/noklesta/glossa_svn) in Ruby on Rails.

## Requirements

* Ruby >= 1.9.2
* PostgreSQL. RGlossa is being developed with version 9.1, but other versions may work as well.
* [The IMS Open Corpus Workbench (CWB)](http://cwb.sourceforge.net/). Check out the latest version from SVN to get support for UTF-8-encoded corpora.

## Installation

### *R*

*R* is included in the Fedora package repository and can be installed with `yum install R`.

In RedHat Enterprise Linux 5 and 6, *R* is available from the *EPEL* repository. [This link](http://fedoraproject.org/wiki/EPEL#How_can_I_use_these_extra_packages.3F) describes how to enable *EPEL*. With *EPEL* enabled, simply run `yum install R`.

Installation of *R* in Ubuntu is described [here](http://cran.r-project.org/bin/linux/ubuntu/).

Installation of *R* in Debian is described [here](http://cran.r-project.org/bin/linux/debian/).

Installation of *R* in openSUSE is described [here](http://cran.r-project.org/bin/linux/suse/).

#### Installing the *R* package *rcqp*

* Check that your server fulfills the requirements listed under *Prerequisites* in [the rcqp installation instructions](http://cran.r-project.org/web/packages/rcqp/INSTALL). Most notably you need to have [Glib 2](http://www.gtk.org/download.html) and [pcre](http://www.pcre.org/) installed.

* Download and unzip the package sources (the *plyr* package is required by *rcqp*):

        curl http://cran.r-project.org/src/contrib/plyr_1.7.1.tar.gz | tar xz
        curl http://cran.r-project.org/src/contrib/rcqp_0.3.tar.gz | tar xz

* Create a registry directory in the standard location expected by CWB (unless it already exists):

        mkdir -p /usr/local/share/cwb/registry

* Install the packages in *R* (you must probably be root to do this):

        R CMD INSTALL plyr rcqp

  Note: If you get an error message saying that the *glib-2.0* library was not found by pkg-config, you need to install the header files for Glib 2. Depending on your distribution, these header files can be found in a package called *libglib2.0-dev*, *glib2-devel*, or something similar.
