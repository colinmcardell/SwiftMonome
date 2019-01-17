UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	LIBMONOME = libmonome.so
endif
ifeq ($(UNAME_S),Darwin)
	LIBMONOME = libmonome.dylib
endif

LIBDIR = /usr/local/lib
LIBRARY = $(LIBDIR)/$(LIBMONOME)

run:
	swift run -Xlinker $(LIBRARY)

build:
	swift build -c release --disable-sandbox -Xlinker $(LIBRARY)

clean:
	rm -rf .build

project:
	swift package generate-xcodeproj

.PHONY: run build clean project
