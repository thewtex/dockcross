
#
# Parameters
#

# Name of the docker executable
DOCKER = docker

# Docker organization to pull the images from
ORG = dockcross

# Directory where to generate the dockcross script for each images (e.g bin/dockcross-manylinux2014-x64)
BIN = ./bin

# Prefer bash to support use of "set -o pipefail"
SHELL=/bin/bash

# These images are built using the "build implicit rule"
STANDARD_IMAGES = android-arm android-arm64 android-x86 android-x86_64 \
	linux-x86 linux-x64 linux-x64-clang linux-arm64 linux-arm64-musl linux-arm64-full \
	linux-armv5 linux-armv5-musl linux-armv5-uclibc linux-m68k-uclibc linux-s390x linux-x64-tinycc \
	linux-armv6 linux-armv6-lts linux-armv6-musl linux-arm64-lts linux-mipsel-lts \
	linux-armv7l-musl linux-armv7 linux-armv7a linux-armv7-lts linux-armv7a-lts linux-x86_64-full \
	linux-mips linux-mips-lts linux-ppc64le linux-riscv64 linux-riscv32 linux-xtensa-uclibc \
	web-wasi \
	windows-static-x86 windows-static-x64 windows-static-x64-posix windows-armv7 \
	windows-shared-x86 windows-shared-x64 windows-shared-x64-posix windows-arm64 \
	bare-armv7emhf-nano_newlib

# Generated Dockerfiles.
GEN_IMAGES = android-arm android-arm64 \
	linux-x86 linux-x64 linux-x64-clang linux-arm64 linux-arm64-musl linux-arm64-full \
	manylinux_2_28-x64 \
	manylinux2014-x64 manylinux2014-x86 \
	manylinux2014-aarch64 linux-arm64-lts \
	web-wasm web-wasi linux-mips linux-mips-lts windows-arm64 windows-armv7 \
	windows-static-x86 windows-static-x64 windows-static-x64-posix \
	windows-shared-x86 windows-shared-x64 windows-shared-x64-posix \
	linux-armv7 linux-armv7a linux-armv7l-musl linux-armv7-lts linux-armv7a-lts linux-x86_64-full \
	linux-armv6 linux-armv6-lts linux-armv6-musl linux-mipsel-lts \
	linux-armv5 linux-armv5-musl linux-armv5-uclibc linux-ppc64le linux-s390x \
	linux-riscv64 linux-riscv32 linux-m68k-uclibc linux-x64-tinycc linux-xtensa-uclibc \
	bare-armv7emhf-nano_newlib

GEN_IMAGE_DOCKERFILES = $(addsuffix /Dockerfile,$(GEN_IMAGES))

# These images are expected to have explicit rules for *both* build and testing
NON_STANDARD_IMAGES = manylinux_2_28-x64 manylinux2014-x64 manylinux2014-x86 \
		      manylinux2014-aarch64 web-wasm

# Docker composite files
DOCKER_COMPOSITE_SOURCES = common.docker common.debian common.manylinux2014 common.manylinux_2 common.buildroot \
	common.crosstool common.webassembly common.windows common-manylinux.crosstool common.dockcross \
	common.label-and-env
DOCKER_COMPOSITE_FOLDER_PATH = common/
DOCKER_COMPOSITE_PATH = $(addprefix $(DOCKER_COMPOSITE_FOLDER_PATH),$(DOCKER_COMPOSITE_SOURCES))

# This list all available images
IMAGES = $(STANDARD_IMAGES) $(NON_STANDARD_IMAGES)

# Optional arguments for test runner (test/run.py) associated with "testing implicit rule"
linux-x64-tinycc.test_ARGS = --languages C
windows-static-x86.test_ARGS = --exe-suffix ".exe"
windows-static-x64.test_ARGS = --exe-suffix ".exe"
windows-static-x64-posix.test_ARGS = --exe-suffix ".exe"
windows-shared-x86.test_ARGS = --exe-suffix ".exe"
windows-shared-x64.test_ARGS = --exe-suffix ".exe"
windows-shared-x64-posix.test_ARGS = --exe-suffix ".exe"
bare-armv7emhf-nano_newlib.test_ARGS = --linker-flags="--specs=nosys.specs"

# On CircleCI, do not attempt to delete container
# See https://circleci.com/docs/docker-btrfs-error/
RM = --rm
ifeq ("$(CIRCLECI)", "true")
	RM =
endif

# Ensures locally built image is used
PULL = --pull never

# Tag images with date and Git short hash in addition to revision
TAG := $(shell date '+%Y%m%d')-$(shell git rev-parse --short HEAD)

# shellcheck executable
SHELLCHECK := shellcheck

# Defines the level of verification (error, warning, info...)
SHELLCHECK_SEVERITY_LEVEL := error

#
# images: This target builds all IMAGES (because it is the first one, it is built by default)
#
images: base $(IMAGES)

#
# test: This target ensures all IMAGES are built and run the associated tests
#
test: base.test $(addsuffix .test,$(IMAGES))

#
# Generic Targets (can specialize later).
#

$(GEN_IMAGE_DOCKERFILES) Dockerfile: %Dockerfile: %Dockerfile.in $(DOCKER_COMPOSITE_PATH)
	sed \
		-e '/common.docker/ r $(DOCKER_COMPOSITE_FOLDER_PATH)common.docker' \
		-e '/common.debian/ r $(DOCKER_COMPOSITE_FOLDER_PATH)common.debian' \
		-e '/common.manylinux_2/ r $(DOCKER_COMPOSITE_FOLDER_PATH)common.manylinux_2' \
		-e '/common.manylinux2014/ r $(DOCKER_COMPOSITE_FOLDER_PATH)common.manylinux2014' \
		-e '/common.crosstool/ r $(DOCKER_COMPOSITE_FOLDER_PATH)common.crosstool' \
		-e '/common.buildroot/ r $(DOCKER_COMPOSITE_FOLDER_PATH)common.buildroot' \
		-e '/common-manylinux.crosstool/ r $(DOCKER_COMPOSITE_FOLDER_PATH)common-manylinux.crosstool' \
		-e '/common.webassembly/ r $(DOCKER_COMPOSITE_FOLDER_PATH)common.webassembly' \
		-e '/common.windows/ r $(DOCKER_COMPOSITE_FOLDER_PATH)common.windows' \
		-e '/common.dockcross/ r $(DOCKER_COMPOSITE_FOLDER_PATH)common.dockcross' \
		-e '/common.label-and-env/ r $(DOCKER_COMPOSITE_FOLDER_PATH)common.label-and-env' \
		$< > $@

#
# web-wasm
#
web-wasm: web-wasm/Dockerfile
	mkdir -p $@/imagefiles && cp -r imagefiles $@/
	cp -r test web-wasm/
	$(DOCKER) build -t $(ORG)/web-wasm:latest \
		-t $(ORG)/web-wasm:$(TAG) \
		--build-arg IMAGE=$(ORG)/web-wasm \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		web-wasm
	rm -rf web-wasm/test
	rm -rf $@/imagefiles

web-wasm.test/fast:
	cp -r test web-wasm/
	$(DOCKER) run $(PULL) $(RM) $(ORG)/web-wasm > $(BIN)/dockcross-web-wasm && chmod +x $(BIN)/dockcross-web-wasm
	$(BIN)/dockcross-web-wasm python test/run.py --exe-suffix ".js"
	rm -rf web-wasm/test

web-wasm.test: web-wasm web-wasm.test/fast
#
# manylinux2014-aarch64
#
manylinux2014-aarch64: manylinux2014-aarch64/Dockerfile
	@# Register qemu
	docker run --rm --privileged hypriot/qemu-register
	@# Get libstdc++ from quay.io/pypa/manylinux2014_aarch64 container
	docker run -v `pwd`:/host --rm -e LIB_PATH=/host/$@/xc_script/ quay.io/pypa/manylinux2014_aarch64 bash -c "PASS=1 /host/$@/xc_script/docker_setup_scrpits/copy_libstd.sh"
	mkdir -p $@/imagefiles && cp -r imagefiles $@/
	$(DOCKER) build -t $(ORG)/manylinux2014-aarch64:latest \
		-t $(ORG)/manylinux2014-aarch64:$(TAG) \
		--build-arg IMAGE=$(ORG)/manylinux2014-aarch64 \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		-f manylinux2014-aarch64/Dockerfile .
	rm -rf $@/imagefiles
	@# libstdc++ is coppied into image, now remove it
	docker run -v `pwd`:/host --rm quay.io/pypa/manylinux2014_aarch64 bash -c "rm -rf /host/$@/xc_script/usr"

manylinux2014-aarch64.test/fast:
	$(DOCKER) run $(PULL) $(RM) $(ORG)/manylinux2014-aarch64 > $(BIN)/dockcross-manylinux2014-aarch64 \
		&& chmod +x $(BIN)/dockcross-manylinux2014-aarch64
	$(BIN)/dockcross-manylinux2014-aarch64 /opt/python/cp38-cp38/bin/python test/run.py

manylinux2014-aarch64.test: manylinux2014-aarch64 manylinux2014-aarch64.test/fast

#
# manylinux_2_28-x64
#
manylinux_2_28-x64: manylinux_2_28-x64/Dockerfile
	mkdir -p $@/imagefiles && cp -r imagefiles $@/
	$(DOCKER) build -t $(ORG)/manylinux_2_28-x64:latest \
		-t $(ORG)/manylinux_2_28-x64:$(TAG) \
		--build-arg IMAGE=$(ORG)/manylinux_2_28-x64 \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		-f manylinux_2_28-x64/Dockerfile .
	rm -rf $@/imagefiles

manylinux_2_28-x64.test/fast:
	$(DOCKER) run $(PULL) $(RM) $(ORG)/manylinux_2_28-x64 > $(BIN)/dockcross-manylinux_2_28-x64 \
		&& chmod +x $(BIN)/dockcross-manylinux_2_28-x64
	$(BIN)/dockcross-manylinux_2_28-x64 /opt/python/cp310-cp310/bin/python test/run.py

manylinux_2_28-x64.test: manylinux_2_28-x64 manylinux_2_28-x64.test/fast

#
# manylinux2014-x64
#
manylinux2014-x64: manylinux2014-x64/Dockerfile
	mkdir -p $@/imagefiles && cp -r imagefiles $@/
	$(DOCKER) build -t $(ORG)/manylinux2014-x64:latest \
		-t $(ORG)/manylinux2014-x64:$(TAG) \
		--build-arg IMAGE=$(ORG)/manylinux2014-x64 \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		-f manylinux2014-x64/Dockerfile .
	rm -rf $@/imagefiles

manylinux2014-x64.test/fast:
	$(DOCKER) run $(PULL) $(RM) $(ORG)/manylinux2014-x64 > $(BIN)/dockcross-manylinux2014-x64 \
		&& chmod +x $(BIN)/dockcross-manylinux2014-x64
	$(BIN)/dockcross-manylinux2014-x64 /opt/python/cp38-cp38/bin/python test/run.py

manylinux2014-x64.test: manylinux2014-x64 manylinux2014-x64.test/fast

#
# manylinux2014-x86
#
manylinux2014-x86: manylinux2014-x86/Dockerfile
	mkdir -p $@/imagefiles && cp -r imagefiles $@/
	$(DOCKER) build -t $(ORG)/manylinux2014-x86:latest \
		-t $(ORG)/manylinux2014-x86:$(TAG) \
		--build-arg IMAGE=$(ORG)/manylinux2014-x86 \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		-f manylinux2014-x86/Dockerfile .
	rm -rf $@/imagefiles

manylinux2014-x86.test/fast:
	$(DOCKER) run $(PULL) $(RM) $(ORG)/manylinux2014-x86 > $(BIN)/dockcross-manylinux2014-x86 \
		&& chmod +x $(BIN)/dockcross-manylinux2014-x86
	$(BIN)/dockcross-manylinux2014-x86 /opt/python/cp38-cp38/bin/python test/run.py

manylinux2014-x86.test: manylinux2014-x86 manylinux2014-x86.test/fast

#
# base
#
base: Dockerfile imagefiles/
	$(DOCKER) build -t $(ORG)/base:latest \
		-t $(ORG)/base:$(TAG) \
		--build-arg IMAGE=$(ORG)/base \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		.

base.test/fast:
	$(DOCKER) run $(PULL) $(RM) $(ORG)/base > $(BIN)/dockcross-base && chmod +x $(BIN)/dockcross-base

base.test: base base.test/fast

base.save/fast:
	mkdir -p ./cache
	set -o pipefail; \
	docker save debian:bullseye-slim $(ORG)/base:latest | xz -e9 -T0 > ./cache/base.tar.xz

base.save: base base.save/fast

base.load:
	set -o pipefail; \
	xz -d -k < ./cache/base.tar.xz | docker load

# display
#
display_images:
	for image in $(IMAGES); do echo $$image; done

$(VERBOSE).SILENT: display_images

#
# build implicit rule
#
$(addsuffix /fast,$(STANDARD_IMAGES)): %/fast: %/Dockerfile
	$(eval IMAGE_NAME = $(@:/fast=))
	echo "Building IMAGE_NAME [$(IMAGE_NAME)]"
	mkdir -p $(IMAGE_NAME)/imagefiles && cp -r imagefiles $(IMAGE_NAME)/
	$(DOCKER) build -t $(ORG)/$(IMAGE_NAME):latest \
		-t $(ORG)/$(IMAGE_NAME):$(TAG) \
		--build-arg IMAGE=$(ORG)/$(IMAGE_NAME) \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		$(IMAGE_NAME)
	rm -rf $(IMAGE_NAME)/imagefiles

.SECONDEXPANSION:
$(STANDARD_IMAGES): base $$(addsuffix /fast, $$@)

clean:
	for d in $(IMAGES) ; do rm -rf $$d/imagefiles ; done
	for d in $(IMAGES) ; do rm -rf $(BIN)/dockcross-$$d ; done
	for d in $(GEN_IMAGE_DOCKERFILES) ; do rm -f $$d ; done
	rm -f Dockerfile

purge: clean
# Remove all untagged images
	$(DOCKER) container ls -aq | xargs -r $(DOCKER) container rm -f
# Remove all images with organization (ex dockcross/*)
	$(DOCKER) images --filter=reference='$(ORG)/*' --format='{{.Repository}}:{{.Tag}}' | xargs -r $(DOCKER) rmi -f

# Check bash syntax
bash-check:
	find . -type f \( -name "*.sh" -o -name "*.bash" \) -print0 | xargs -0 -P"$(shell nproc)" -I{} \
		$(SHELLCHECK) --check-sourced --color=auto --format=gcc --severity=warning --shell=bash --enable=all "{}"

#
# testing implicit rule
#
$(addsuffix .test/fast,$(STANDARD_IMAGES)):
	$(eval IMAGE_NAME = $(basename $(@:/fast=)))
	$(DOCKER) run $(PULL) $(RM) $(ORG)/$(IMAGE_NAME) > $(BIN)/dockcross-$(IMAGE_NAME) \
		&& chmod +x $(BIN)/dockcross-$(IMAGE_NAME)
	$(BIN)/dockcross-$(IMAGE_NAME) python3 test/run.py $($(patsubst /fast,,$@)_ARGS)

.SECONDEXPANSION:
$(addsuffix .test,$(STANDARD_IMAGES)): $$(basename $$@) $$(addsuffix /fast, $$@)

#
# testing prerequisites implicit rule
#
test.prerequisites:
	mkdir -p $(BIN)

$(addsuffix .test/fast,base $(IMAGES)): test.prerequisites

#
# saving/loading implicit rule
#
$(addsuffix .save/fast,$(IMAGES)):
	mkdir -p ./cache-$(basename $@)
	set -o pipefail; \
	$(DOCKER) save $(ORG)/$(basename $@):latest | xz -e9 -T0 > ./cache/$(basename $@).tar.xz

.SECONDEXPANSION:
$(addsuffix .save,$(IMAGES)): $$(basename $$@) $(addsuffix /fast,$$@)

$(addsuffix .load,$(IMAGES)):
	set -o pipefail; \
	xz -d -k < ./cache/$(basename $@).tar.xz | $(DOCKER) load

.PHONY: base images $(IMAGES) test %.test %.test/fast %.save %.save/fast %.load %.load/fast clean purge bash-check display_images
