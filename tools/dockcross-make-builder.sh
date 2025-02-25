#!/usr/bin/env bash

if (( $# >= 1 )); then
    image_complete=$1
    image=${image_complete%:*}
    tag=${image_complete#*:}
    build_file=build-$image
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

    make_arg=$*
    echo "make arg: $make_arg"

#    echo "Pulling dockcross/$image"
#    docker pull "dockcross/$image:$tag"

    echo "Make script dockcross-$image"
    docker run --rm dockcross/"$image:$tag" > ./dockcross-"$image"
    chmod +x ./dockcross-"$image"

    echo "Build $build_file"
    ./dockcross-"$image" -i dockcross/"$image:$tag" bash -c 'make CXX=${CXX} CC=${CC} AR=${AR} AS=${AS} LD=${LD} CPP=${CPP} FC=${FC} '"$make_arg"
else
    echo "Usage: ${0##*/} <docker image (ex: linux-x64/linux-x64-clang/linux-arm64/windows-shared-x64/windows-static-x64...)> <make arg.>"
    exit 1
fi
