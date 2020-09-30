VERSION        ?= 0.0.1
LDFLAGS        := -X main.Version=$(VERSION)
GOFLAGS        := -ldflags "$(LDFLAGS) -s -w"
ARCH           ?= $(shell uname -m)
GOARCH         ?= $(subst x86_64,amd64,$(patsubst i%86,386,$(ARCH)))
BUILD_ARGS      = --build-arg VERSION=$(VERSION)
DIST_DIR        = postgresql_exporter.$(VERSION).linux-${GOARCH}
ARCHIVE         = postgresql_exporter.$(VERSION).linux-${GOARCH}.tar.gz

linux:
	@echo build linux
	mkdir -p ./dist/$(DIST_DIR)
	PKG_CONFIG_PATH=${PWD} GOOS=linux go build $(GOFLAGS) -o ./dist/$(DIST_DIR)/postgresql_exporter
	cp default-metrics.toml ./dist/$(DIST_DIR)
	(cd dist ; tar cfz $(ARCHIVE) $(DIST_DIR))

darwin:
	@echo build darwin
	mkdir -p ./dist/postgresql_exporter.$(VERSION).darwin-${GOARCH}
	PKG_CONFIG_PATH=${PWD} GOOS=darwin go build $(GOFLAGS) -o ./dist/postgresql_exporter.$(VERSION).darwin-${GOARCH}/postgresql_exporter
	cp default-metrics.toml ./dist/postgresql_exporter.$(VERSION).darwin-${GOARCH}
	(cd dist ; tar cfz postgresql_exporter.$(VERSION).darwin-${GOARCH}.tar.gz postgresql_exporter.$(VERSION).darwin-${GOARCH})

local-build:  linux

build: docker

deps:
	@PKG_CONFIG_PATH=${PWD} go get

test:
	@echo test
	@PKG_CONFIG_PATH=${PWD} go test $$(go list ./... | grep -v /vendor/)

clean:
	rm -rf ./dist sgerrand.rsa.pub glibc-2.29-r0.apk oci8.pc

docker: ubuntu-image alpine-image oraclelinux-image

sgerrand.rsa.pub:
	wget -q -O sgerrand.rsa.pub  https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub

glibc-2.29-r0.apk:
	wget -q -O glibc-2.29-r0.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.29-r0/glibc-2.29-r0.apk

oraclelinux-image: $(ORA_RPM)
	docker build -f oraclelinux/Dockerfile $(BUILD_ARGS) -t "iamseth/oracledb_exporter:$(VERSION)-oraclelinux" .
	docker tag "iamseth/oracledb_exporter:$(VERSION)-oraclelinux" "iamseth/oracledb_exporter:oraclelinux"

ubuntu-image: $(ORA_RPM)
	docker build $(BUILD_ARGS)  -t "iamseth/oracledb_exporter:$(VERSION)" .
	docker tag "iamseth/oracledb_exporter:$(VERSION)" "iamseth/oracledb_exporter:latest"

alpine-image: $(ORA_RPM) sgerrand.rsa.pub glibc-2.29-r0.apk
	docker build -f alpine/Dockerfile $(BUILD_ARGS) -t "iamseth/oracledb_exporter:$(VERSION)-alpine" .
	docker tag "iamseth/oracledb_exporter:$(VERSION)-alpine" "iamseth/oracledb_exporter:alpine"

travis: deps test linux
	@true

.PHONY: build deps test clean docker travis oci.pc
