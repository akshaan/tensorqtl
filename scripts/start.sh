#!/bin/sh

set -e
git clone https://github.com/akshaan/tensorqtl.git .
pip3 install --upgrade pip setuptools
pip3 install -e .
exec "$@"
