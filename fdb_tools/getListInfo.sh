#/bin/bash

baseDir=$(dirname $0)

echo "baseDir=[${baseDir}]"

export LD_LIBRARY_PATH="${baseDir}/lib"

${baseDir}/getListInfo  "$1"

exit 0
