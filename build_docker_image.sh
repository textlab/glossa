#!/bin/sh

bundle update rglossa rglossa-r rglossa-fcs
rake railties:install:migrations   # installs migrations for all engines
rake rglossa:install:thor
docker build -t textlab/glossa .

