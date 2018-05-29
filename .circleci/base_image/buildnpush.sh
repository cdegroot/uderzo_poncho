#!/bin/sh
export mydir=$(cd $(dirname $0); /bin/pwd)
name=cdegroot/uderzo-ci:$(git rev-parse --short HEAD)
# We pre-compile all asdf-managed dependencies to keep circle runs quick and simple.
rm .tool-versions
(cd ../../; find . -name .tool-versions | xargs cat | sort -u >$mydir/.tool-versions)
docker build -t $name .
docker push $name
echo Published $name
