# RGlossa

RGlossa is a reimplementation of the [Glossa search system](https://github.com/noklesta/glossa_svn) in Ruby on Rails.

Rglossa is currently under active development. It is functional but still has some way to go before it reaches feature parity with the old Glossa version.

## Prerequisites

* Ruby >= 1.9.2 (>= 1.9.3 is recommended)
* [The IMS Open Corpus Workbench (CWB)](http://cwb.sourceforge.net/). Check out the latest version from SVN to get support for UTF-8-encoded corpora.

## Installation instructions

### Install Ruby and Rails
Unless you have Ruby >= 1.9.2 installed, you need to install it. The easiest way is to use the [Ruby Version Manager (RVM)](https://rvm.io/), which lets you install Ruby without root access to the server and run several Ruby versions side by side. Installation instructions can be found [here](https://rvm.io/rvm/install/). After installing RVM, get the latest Ruby version (2.1 at the time of writing):

    rvm install 2.1

Set this version to be your default Ruby version:

    rvm use 2.1 --default

(or see [the RVM documentation](https://rvm.io/workflow/rvmrc/) about how to
create an *.rvmrc* file in your application directory that will automatically
switch to this version when you enter the directory).

### Create your RGlossa application

The easiest way to make an application is to clone our application template:

    git clone https://github.com/textlab/glossa

The following commands install the required gems and initialise the database:

    cd glossa
    bundle
    rake db:migrate

If you want to develop rglossa, the *rglossa* gem should be checked out in a
separate directory, and you need to set up an override in the application
directory, so that your checked-out version is used instead of the version from
the Gemfile:

    cd ..
    git clone -b react-mergespeech https://github.com/textlab/rglossa
    cd glossa
    bundle config --local local.rglossa ../rglossa

If you want to work on a branch other than the default one, you may need to
disable branch checking:

    bundle config --local disable_local_branch_check true

#### Troubleshooting

If you are getting the following message:

    You passed :github as an option for gem 'rglossa', but it is invalid.

you need to update the *bundler* gem:

    gem install bundler -N

Also, if you are using an old version of Rails, you may get the following message:

    Bundler could not find compatible versions for gem "rails"
      In Gemfile:
        rglossa (>= 0) ruby depends on
          rails (~> 3.2.19) ruby

In that case, please install the version of the *rails* gem that is mentioned in the error message, e.g.:

    gem install rails -v3.2.19 -N

As an alternative to creating a new application, you may already have a Rails application and want to make RGlossa part of that. Since RGlossa is implemented as a Rails engine, this can easily be achieved by mounting RGlossa at some subpath within the application. See the [wiki](http://github.com/textlab/rglossa/wiki) for more information.

### Optionally install R

RGlossa uses [R](http://www.r-project.org/) for various statistics. The R support is optional, but if you want to use it you need to install R on your server, along with an R package called rcqp.

#### Installing R itself

* In Fedora, R is included in the package repository and can be installed with `yum install R`.

* In RedHat Enterprise Linux 5 and 6, R is available from the EPEL repository. [This link](http://fedoraproject.org/wiki/EPEL#How_can_I_use_these_extra_packages.3F) describes how to enable EPEL. With EPEL enabled, simply run `yum install R`.

* Installation of R in Ubuntu is described [here](http://cran.r-project.org/bin/linux/ubuntu/).

* Installation of R in Debian is described [here](http://cran.r-project.org/bin/linux/debian/).

* Installation of R in openSUSE is described [here](http://cran.r-project.org/bin/linux/suse/).

#### Installing the R package rcqp

* Check that your server fulfills the requirements listed under *Prerequisites* in [the rcqp installation instructions](http://cran.r-project.org/web/packages/rcqp/INSTALL). Most notably you need to have Glib 2 and pcre installed.

* Download and unzip the package sources (the plyr package is required by rcqp):

        curl http://cran.r-project.org/src/contrib/plyr_1.8.tar.gz | tar xz
        curl http://cran.r-project.org/src/contrib/rcqp_0.3.tar.gz | tar xz

* Create a registry directory in the standard location expected by CWB (unless it already exists):

        mkdir -p /usr/local/share/cwb/registry

* Install the packages in R (you must probably be root to do this):

        R CMD INSTALL plyr rcqp

  Note: If you get an error message saying that the glib-2.0 library was not found by pkg-config, you need to install the header files for Glib 2. Depending on your distribution, these header files can be found in a package called libglib2.0-dev, glib2-devel, or something similar.

### Other optional packages

For the waveform visualisation to work, you need to install a few more packages.
Try to use your package manager to install as much as possible. In Debian-based
distributions run:
    
    apt-get install libav-tools mp3splt tcl8.4-dev tk8.4-dev python-tk imagemagick xvfb

In Fedora-based distributions run:

    yum install ffmpeg tcl-devel tk-devel tkinter ImageMagick xorg-x1-server-Xvfb

Some of the packages are not available in Linux distributions and must be
installed manually. This is the full list of required packages:

* **[FFmpeg](https://www.ffmpeg.org/)**. In recent versions of Debian and
  Ubuntu, install `libav-tools` instead of `ffmpeg`, and let *avconv* be called
  as *ffmpeg*, e.g.:

        cd /usr/local/bin && ln -s ../../bin/avconv ffmpeg

* **[Mp3Splt](http://mp3splt.sourceforge.net)**. If your package manager cannot
  install it automatically, check the site with [packages for various
  distributions](http://mp3splt.sourceforge.net/mp3splt_page/downloads.php).

* **TCL/TK**. Note that TCL/TK 8.4 and 8.5 work without problems, version 8.6
  probably requires fixing the source code of Snack, due to incompatibilities.

* **[Python 2.x](http://www.python.org)**. Note that it must be a 2.x version,
  not a 3.x version.

* **TkInter**.

* **[ImageMagick](http://www.imagemagick.org)**.

* **Xvfb** (X virtual framebuffer).

* **[The Snack Sound Toolkit](http://www.speech.kth.se/snack/)**. Unlike the
  above packages, Snack is probably unavailable in binary form for your
  distribution, and the only option is to compile it from the
  [source](http://www.speech.kth.se/snack/dist/snack2.2.10.tar.gz).

## More information

For more information, see the [RGlossa wiki](http://github.com/textlab/rglossa/wiki).
