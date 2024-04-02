#!/usr/bin/env bash

# Mount the PWD and the /work mount dir to enable access in try_run commands
exec ${WASMTIME_HOME}/bin/wasmtime -S threads=y run --dir=. --dir=$PWD --dir=/work/ "$@"
