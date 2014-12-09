install='apt-get install --no-install-recommends -y'
remove='apt-get purge --auto-remove -y'
autoremove='apt-get autoremove --purge -y'

# Build dependencies for the gems, Corpus Workbench and Snack
GEM_BUILD_DEPS='git make patch binutils gcc g++ libc6-dev ruby2.0-dev libmysqlclient-dev libsqlite3-dev'
CWB_BUILD_DEPS='subversion autoconf bison flex libglib2.0-dev libncurses5-dev make binutils gcc g++ libc6-dev'
SNACK_BUILD_DEPS='curl make patch binutils gcc g++ libc6-dev tcl8.4-dev tk8.4-dev'
