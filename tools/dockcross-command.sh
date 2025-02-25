#!/usr/bin/env bash

if (( $# >= 2 )); then
    image_complet=$1
    image=${image_complet%:*}
    tag=${image_complet#*:}
    host_arch=$(uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/')
    if test $tag = $image; then
        # use multiarch image if available
        if docker images | grep dockcross/${image} | grep latest-${host_arch} >/dev/null; then
          tag="latest-${host_arch}"
        else
          tag="latest"
        fi
    fi
    shift 1

    command=$*
    echo "command: $command"

#    echo "Pulling dockcross/$image"
#    docker pull "dockcross/$image:$tag"

    echo "Make script dockcross-$image"
    docker run --rm dockcross/"$image:$tag" > ./dockcross-"$image"
    chmod +x ./dockcross-"$image"
    
    echo "Run command in dockcross-$image"
    ./dockcross-"$image" -i dockcross/"$image:$tag" $command
else
    echo "Usage: ${0##*/} <docker imag (ex: linux-x64/linux-x64-clang/linux-arm64/windows-shared-x64/windows-static-x64...)> <command>"
    exit 1
fi
