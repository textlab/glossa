# Glossa

This is the the **Glossa search system**, implemented in Ruby on Rails.

Glossa is currently under active development. It is functional but still has
some way to go before it reaches feature parity with the [old version of
Glossa](https://github.com/noklesta/glossa_svn).

## Docker-based installation

The simplest way to install Glossa, is to use a ready-to-use Docker image that
we provide. It can be done in a few easy steps:

* **[Install Docker](https://docs.docker.com/installation/)**. The linked website
  provides installation instructions for all major operating systems. Note that
  Docker works only on 64-bit systems.
* **Download the control scripts**:
  [glossa_start](https://raw.githubusercontent.com/textlab/glossa/master/script/glossa_start.sh),
  [glossa_stop](https://raw.githubusercontent.com/textlab/glossa/master/script/glossa_stop.sh),
  [glossa_addr](https://raw.githubusercontent.com/textlab/glossa/master/script/glossa_addr.sh).
  The scripts should work on all operating systems, including Windows (Docker
  installs Git Bash). On Linux/Mac you will need to make them executable. If
  you save them to your desktop, call `chmod 755 ~/Desktop/glossa_*.sh` or
  something similar in your terminal. You can click on them or call them from
  the command line to start, stop and check the address of Glossa,
  respectively.
* **Call `glossa_start.sh`**. Glossa should be up and running now. The default
  address on Linux is <http://127.0.0.1:61054/admin>, and on other systems it
  is <http://192.168.59.103:61054/admin>. In case of problems you may call
  `glossa_addr.sh` to check the address.

### Notes

If you adapt the Docker setup to your needs, keep in mind that the container
`glossa` contains only the application code, so it is safe to delete it and
re-create it from the `textlab/glossa` image. Conversely, the container
`glossa-data` stores all your Glossa-related data, including settings and
corpora. **If you delete this container, they will be lost!**

If you have problems, first make sure that you can call `docker` (on Linux and
Mac) and/or `boot2docker` (on Mac and Windows) from the command line (Git Bash
on Windows). If you cannot, there is a problem with your Docker installation.

## Standard installation from GitHub

This is the way to install Glossa if you want to adapt it to your needs, or
don't wish to use Docker. You will need a Unix system, preferably Linux.

Most important prerequisites:

* Ruby >= 1.9.2 (>= 1.9.3 is recommended)
* [The IMS Open Corpus Workbench (CWB)](http://cwb.sourceforge.net/)

### Branches

The GitHub repository contains two branches:

* `coffeescript` is a stable version of Glossa that uses Ruby on Rails, CoffeeScript and an SQL database,
* `master` is an early development version of Glossa that uses JRuby on Rails, ClojureScript and the OrientDB database.

### Install Ruby and Rails

Unless you have Ruby >= 1.9.2 installed, you need to install it. The easiest
way is to use the [Ruby Version Manager (RVM)](https://rvm.io/), which lets you
install Ruby without root access to the server and run several Ruby versions
side by side. Installation instructions can be found
[here](https://rvm.io/rvm/install/). After installing RVM, get Ruby
(version 2.2 at the time of writing):

    rvm install `cat .ruby-version`

Note that other Ruby versions than the one indicated in `.ruby-version` may
or may not work.

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

    git clone -b coffeescript https://github.com/textlab/glossa

The following commands install the required gems and modules, and initialise the database:

    cd glossa
    bundle
    rake db:migrate

If you are using the (unstable) master branch, you also need [Node.js](https://nodejs.org/en/), 
which in turn enables you to install a few [bower](http://bower.io/) components using the
following commands: 

    npm install -g bower
    bower install

Finally, you can start Glossa:

    bundle exec rails server

With the default settings, Glossa will be available at
`http://127.0.0.1:61054/admin` in your browser. You may add `-p <port_name>` to
run Glossa on another port.

### Non-default database settings

By default an SQLite database in the subdirectory `db` will be used. You can
set the environment variable `DATABASE_URL` if you want to customise the
database settings. This variable has to be set before running `rake` and
`rails` commands.

`DATABASE_URL` should have the following form

    <adapter>://<username>:<password>@<hostname>/<database>

For example, if you want to connect to a MySQL database called `glossa_db` at
your machine, providing the username `glossa_user` and the password `5pwd@#`,
you should set it as follows:

    export DATABASE_URL=mysql2://glossa_user:5pwd%40%23@localhost/glossa_db

Note that the elements of the URL (including the password) are
[URL-encoded](http://en.wikipedia.org/wiki/Percent-encoding).

If you want to use SQLite, only the path to the database file needs to be
provided:

    export DATABASE_URL=sqlite3:///db/glossa.db

The above variable points to a relative path, `db/glossa.db`. To use an
absolute path, one more slash is needed. The following example points to a
database located in `/corpora/glossa.db`:

    export DATABASE_URL=sqlite3:////corpora/glossa.db

Alternatively, instead of setting `DATABASE_URL`, you may edit
`config/database.yml` and provide your database settings there.

If you use a database adapter other than SQLite, and the database doesn't
exist, you need to create it with the following command:

    rake db:create

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

  **Note**: If you get an error message saying that the glib-2.0 library was
  not found by pkg-config, you need to install the header files for Glib 2.
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
application and want to make Glossa part of that. The `rglossa` gem is
implemented as a Rails engine, this can easily be achieved by mounting `rglossa`
at some subpath within the application. See the
[wiki](http://github.com/textlab/rglossa/wiki) for more information.

## Development of Glossa

If you want to develop Glossa, you probably want to use the `master` branch,
not the `coffeescript` branch.  You should follow the instructions from the
section [Standard installation from GitHub](#standard-installation-from-github),
with the following modifications:

* As of September 2015, only the head version of RVM can install JRuby 9. Run
  the following command after installing RVM and before installing Ruby:

    rvm get head

* Don't specify any branch when cloning Glossa (`master` is the default):

    git clone https://github.com/textlab/glossa

* Apart from the Rails server, also run:

    lein figwheel

  If you have `rlwrap` installed, run `rlwrap lein figwheel` instead; you will
  get line editing, persistent history and completion. Figwheel detects
  modified ClojureScript files, compiles them and sends them to the client in
  real time; no page reload is needed.

## Upgrade
### Docker image

To upgrade the Glossa Docker image to the newest version, you need to pull the
image. On Linux/Mac open your terminal, and on Windows open Git Bash and run
`boot2docker ssh`. Then run the following command to download the latest image:

    docker pull textlab/glossa

Now you can stop and start Glossa as usual.

### Glossa from GitHub

If you pulled Glossa from GitHub, you may upgrade it to the newest version
with the following commands:

    cd glossa
    git pull
    bundle
    rake db:migrate

## More information

For more information, see the [RGlossa wiki](http://github.com/textlab/rglossa/wiki).

## License

Copyright © 2015 The Text Laboratory, University of Oslo

Distributed under the <a href="http://www.opensource.org/licenses/MIT">MIT License</a>.
