prefix ?= /usr/local
bindir = $(prefix)/bin

run:
	swift run -Xlinker "/usr/local/lib/libmonome.dylib"

build:
	swift build -c release --disable-sandbox -Xlinker "/usr/local/lib/libmonome.dylib"

clean:
	rm -rf .build

project:
	swift package generate-xcodeproj

.PHONY: run build clean project
