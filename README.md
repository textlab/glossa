# Glossa

This is the the **Glossa search system**, implemented in Ruby on Rails.

Glossa is currently under active development. It is functional but still has
some way to go before it reaches feature parity with the [old version of
Glossa](https://github.com/noklesta/glossa_svn).

## Docker-based installation

The easiest way to install Glossa, is to use a ready-to-use Docker image that
we provide. It can be done in a few easy steps:

* [Install Docker](https://docs.docker.com/installation/). The linked website
  provides installation instructions for all major operating systems. Note that
  Docker works only on 64-bit systems.
* Create a volume that will store your corpora and all other data used by
  Glossa. It needs to be done only once, by running the following command:

        docker run -v /corpora --name glossa-data busybox true

* Run the Glossa image. If the image is not present on your machine, it will be
  downloaded automatically.

        docker run -d -p 4096:3000 --volumes-from glossa-data textlab/glossa

* Connect to `http://127.0.0.1:4096/admin` in your web browser. Glossa should
  be up and running. **Note:** If you use Boot2Docker (which is the case when
  you use Windows or MacOS), change `127.0.0.1` in the address to the output
  of the `boot2docker ip` command. You may also run Glossa on a different port
  by changing `4096` to some other number in the `docker run` command and in
  the address.

## Standard installation from GitHub

This is the way to install Glossa if you want to adapt it to your needs, or
don't wish to use Docker. You will need a Unix system, preferably Linux.

Most important prerequisites:

* Ruby >= 1.9.2 (>= 1.9.3 is recommended)
* [The IMS Open Corpus Workbench (CWB)](http://cwb.sourceforge.net/)

### Install Ruby and Rails
Unless you have Ruby >= 1.9.2 installed, you need to install it. The easiest
way is to use the [Ruby Version Manager (RVM)](https://rvm.io/), which lets you
install Ruby without root access to the server and run several Ruby versions
side by side. Installation instructions can be found
[here](https://rvm.io/rvm/install/). After installing RVM, get the latest Ruby
version (2.1 at the time of writing):

    rvm install 2.1

Set this version to be your default Ruby version:

    rvm use 2.1 --default

(or see [the RVM documentation](https://rvm.io/workflow/rvmrc/) about how to
create an *.rvmrc* file in your application directory that will automatically
switch to this version when you enter the directory).

### Install the IMS Open Corpus Workbench (CWB)
Some packages are required to compile CWB. In Debian-based distributions you
may need to run:

    apt-get install flex libglib2.0-dev

Follow the installation instructions of [The IMS Open Corpus Workbench
(CWB)](http://cwb.sourceforge.net/download.php#svn). Check out the latest
version from SVN, as described at the bottom of the page, to get support for
UTF-8-encoded corpora.

### Create your Glossa application

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
    git clone https://github.com/textlab/rglossa
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

In that case, please install the version of the *rails* gem that is mentioned
in the error message, e.g.:

    gem install rails -v3.2.19 -N

You may get an error message about building a native extension, such as:

    Gem::Ext::BuildError: ERROR: Failed to build gem native extension.
    [...]
    Gem files will remain installed in ~/.rvm/gems/ruby-2.1.5/gems/mysql2-0.3.17 for inspection.
    Results logged to ~/.rvm/gems/ruby-2.1.5/extensions/x86-linux/2.1.0/mysql2-0.3.17/gem_make.out

In such case you need to install development files of the MySQL client. In a
Debian-based distribution run:

    apt-get install libmysqlclient-dev

### Optionally install R

RGlossa uses [R](http://www.r-project.org/) for various statistics. The R
support is optional, but if you want to use it you need to install R on your
server, along with an R package called rcqp.

#### Installing R itself

* In Fedora, R is included in the package repository and can be installed with
  `yum install R`.

* In RedHat Enterprise Linux 5 and 6, R is available from the EPEL repository.
  [This
  link](http://fedoraproject.org/wiki/EPEL#How_can_I_use_these_extra_packages.3F)
  describes how to enable EPEL. With EPEL enabled, simply run `yum install R`.

* Installation of R in Ubuntu is described
  [here](http://cran.r-project.org/bin/linux/ubuntu/).

* Installation of R in Debian is described
  [here](http://cran.r-project.org/bin/linux/debian/).

* Installation of R in openSUSE is described
  [here](http://cran.r-project.org/bin/linux/suse/).

#### Installing the R package rcqp

* Check that your server fulfills the requirements listed under *Prerequisites*
  in [the rcqp installation
  instructions](http://cran.r-project.org/web/packages/rcqp/INSTALL). Most
  notably you need to have Glib 2 and pcre installed.

* Download and unzip the package sources (the plyr package is required by rcqp):

        curl http://cran.r-project.org/src/contrib/plyr_1.8.tar.gz | tar xz
        curl http://cran.r-project.org/src/contrib/rcqp_0.3.tar.gz | tar xz

* Create a registry directory in the standard location expected by CWB (unless
  it already exists):

        mkdir -p /usr/local/share/cwb/registry

* Install the packages in R (you must probably be root to do this):

        R CMD INSTALL plyr rcqp

  Note: If you get an error message saying that the glib-2.0 library was not
  found by pkg-config, you need to install the header files for Glib 2.
  Depending on your distribution, these header files can be found in a package
  called libglib2.0-dev, glib2-devel, or something similar.

### Installing packages required by the waveform server

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

* **Tcl/Tk**. Note that Tcl/Tk 8.4 and 8.5 work without problems, version 8.6
  probably requires fixing the source code of Snack, due to incompatibilities.

* **[Python 2.x](http://www.python.org)**. Note that it must be a 2.x version,
  not a 3.x version. Make sure that it can be called as `python2`. If you have
  an old distribution without a `python2` executable, make a symlink, e.g.:

        cd /usr/local/bin && ln -s ../../bin/python python2

* **TkInter**.

* **[ImageMagick](http://www.imagemagick.org)**.

* **Xvfb** (X virtual framebuffer).

* **[The Snack Sound Toolkit](http://www.speech.kth.se/snack/)**. Unlike the
  above packages, Snack is probably unavailable in the binary form for your
  distribution, and must be compiled from the
  [source](http://www.speech.kth.se/snack/dist/snack2.2.10.tar.gz). We provide
  a script to simplify that task. In the directory of your Glossa application
  run:

        rake rglossa:install:snack

  Now the toolkit will be automatically downloaded and compiled. After
  successful compilation, the script will provide the commands that need to be
  executed to install the toolkit. If you keep the default installation
  directory (`/usr/local`), you will probably need to execute it as root.

  If you want another installation directory, edit `config/waveforms.json` and
  modify `snack_dir` and re-run the rake command. If you get compilation
  errors, make sure that `tcl_dir` and `tk_dir` contain directories of your
  Tcl/Tk installation (although the defaults should work fine for most
  distributions).

### Control over the waveform server

You can use the following command in the `rails console` in order to stop the
waveform server:

    Rglossa::Speech::WaveformPlayerController.stop

Alternatively, you can do it from the shell. Go to the application directory
(`glossa`) and run the following:

    kill `cat tmp/pids/genwaveform.pid`

The server can be restarted by running:

    kill -HUP `cat tmp/pids/genwaveform.pid`

There is no start command, as it starts automatically when needed. Changes in
`config/waveforms.json` require restarting the server.

## Advanced installation

As an alternative to creating a new application, you may already have a Rails
application and want to make Glossa part of that. The RGlossa gem is
implemented as a Rails engine, this can easily be achieved by mounting RGlossa
at some subpath within the application. See the
[wiki](http://github.com/textlab/rglossa/wiki) for more information.

## Development of Glossa

The core of Glossa is in the *rglossa* gem. If you want to develop *rglossa*,
it should be checked out in a separate directory, and you need to set up an
override in the application directory, so that your checked-out version is used
instead of the version from the Gemfile. Assuming that you are in the
application directory named `glossa`, you need to do the following:

    cd ..
    git clone https://github.com/textlab/rglossa
    cd glossa
    bundle config --local local.rglossa ../rglossa

If you want to work on a branch other than the default one, you may need to
disable branch checking:

    bundle config --local disable_local_branch_check true

## More information

For more information, see the [RGlossa wiki](http://github.com/textlab/rglossa/wiki).
