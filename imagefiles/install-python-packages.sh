#!/usr/bin/env bash

set -e
set -o pipefail

PYTHON=python
while [ $# -gt 0 ]; do
  case "$1" in
    -python)
      PYTHON=$2
      shift
      ;;
    *)
      echo "Usage: Usage: ${0##*/} [-python /path/to/bin/python]"
      exit 1
      ;;
  esac
  shift
done

cd /tmp

curl -# -LO https://bootstrap.pypa.io/pip/get-pip.py
# https://github.com/pypa/setuptools/issues/2993
export SETUPTOOLS_USE_DISTUTILS=stdlib
# Add --break-system-packages to fix change since python 3.11: https://stackoverflow.com/a/75722775/10152334
${PYTHON} get-pip.py --ignore-installed --break-system-packages 
rm get-pip.py

${PYTHON} -m pip install --break-system-packages --upgrade --ignore-installed setuptools
${PYTHON} -m pip install --break-system-packages --ignore-installed conan meson
# Purge cache to save space: https://stackoverflow.com/questions/37513597/is-it-safe-to-delete-cache-pip-directory
${PYTHON} -m pip cache purge
