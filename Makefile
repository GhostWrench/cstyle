# Basic makefile for compiling and running tests for a very basic project
SHELL = /bin/sh
.SUFFIXES:

# Build options
BUILD_CFG ?= debug
SHARED_LIB ?= 1
CFLAGS_EXTRA ?= 
LDFLAGS_EXTRA ?=
DESTDIR ?= 

# Build Settings
CFLAGS = -Wall -Wextra -Wpedantic -std=c17 -g -I$(srcdir)/include
ifeq ($(BUILD_CFG),debug)
CFLAGS += -O0 -DDEBUG
endif
LDFLAGS = 

# Project configuration
PROJECT_NAME = cstyle
VERSION_MAJOR = $(shell sed -n -e 's/\#define CSTYLE_VERSION_MAJOR \([0-9]*\)/\1/p' $(srcdir)/include/$(PROJECT_NAME)/core.h)
VERSION_MINOR = $(shell sed -n -e 's/\#define CSTYLE_VERSION_MINOR \([0-9]*\)/\1/p' $(srcdir)/include/$(PROJECT_NAME)/core.h)
VERSION_PATCH = $(shell sed -n -e 's/\#define CSTYLE_VERSION_PATCH \([0-9]*\)/\1/p' $(srcdir)/include/$(PROJECT_NAME)/core.h)

# Directory definitions (defaults recommended by GNU)
srcdir = .
prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
sbindir = $(exec_prefix)/sbin
libexecdir = $(exec_prefix)/libexec
datarootdir = $(prefix)/share
datadir = $(datarootdir)
sysconfdir = $(prefix)/etc
sharedstatedir = $(prefix)/com
localstatedir = $(prefix)/var
runstatedir = $(localstatedir)/run
includedir = $(prefix)/include
docdir = $(datarootdir)/doc/$(PROJECT_NAME)
infodir = $(datarootdir)/info
htmldir = $(docdir)
dvidir = $(docdir)
pdfdir = $(docdir)
psdir = $(docdir)
libdir = $(exec_prefix)/lib
localedir = $(datarootdir)/locale
mandir = $(datarootdir)/man

# Configure external libraries
# glib-2.0
CFLAGS += $(shell pkg-config --cflags glib-2.0)
LDFLAGS += $(shell pkg-config --libs glib-2.0)

# Find all the source and header files
EXEC_SRC = $(srcdir)/src/$(PROJECT_NAME).c
OBJ_SRC = $(filter-out $(EXEC_SRC),$(wildcard $(srcdir)/src/*.c))
TEST_SRC = $(wildcard $(srcdir)/test/*.c)
PVT_H = $(wildcard $(srcdir)/include/*.h)
PUB_H = $(wildcard $(srcdir)/include/$(PROJECT_NAME)/*.h)

# Calculate names of the build artifacts and outputs
EXEC = ./output/$(PROJECT_NAME)
ifeq ($(SHARED_LIB),1)
LIB = ./output/lib$(PROJECT_NAME).so.$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH)
else
LIB = ./output/lib$(PROJECT_NAME).a.$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH)
endif
OBJS = $(patsubst $(srcdir)/src/%.c,./build/%.o,$(OBJ_SRC))
TEST_EXECS = $(patsubst $(srcdir)/test/%.c,./build/test/%.elf,$(TEST_SRC))
TEST_OUTS = $(patsubst $(srcdir)/test/%.c,./build/test/%.out,$(TEST_SRC))

# Input checking
ifneq ($(BUILD_CFG),debug)
ifneq ($(BUILD_CFG),release)
$(error BUILD_CFG must be either 'debug' or 'release')
endif
endif

# Build targets
.PHONY: clean uninstall

all: $(EXEC) $(LIB)

exec: $(EXEC)

lib: $(LIB)

test: $(TEST_EXECS)

runtest: $(TEST_OUTS)

$(EXEC): $(EXEC_SRC) $(OBJS)
	@mkdir -p ./output
	$(CC) $(CFLAGS) $(CFLAGS_EXTRA) -o $@ $< $(OBJS) $(LDFLAGS) $(LDFLAGS_EXTRA)

ifeq ($(SHARED_LIB),1)
$(LIB): $(OBJS)
	@mkdir -p ./output
	$(CC) $(CFLAGS) $(CFLAGS_EXTRA) -shared $(OBJS) -o $@ $(LDFLAGS) $(LDFLAGS_EXTRA)
else
$(LIB): $(OBJS)
	@mkdir -p ./output
	$(AR) rcs $@ $(OBJS) $(LDFLAGS) $(LDFLAGS_EXTRA)
endif

./build/%.o : $(srcdir)/src/%.c $(PVT_H) $(PUB_H)
	@mkdir -p ./build
	$(CC) $(CFLAGS) $(CFLAGS_EXTRA) -c -o $@ $<

./build/test/%.elf : $(srcdir)/test/%.c $(OBJS)
	@mkdir -p ./build/test
	$(CC) $(CFLAGS) $(CFLAGS_EXTRA) -o $@ $< $(OBJS) $(LDFLAGS)

./build/test/%.out : ./build/test/%.elf $(TEST_EXECS)
	@mkdir -p ./build/test
	@$(srcdir)/script/runtest.sh $< $@

clean:
	rm -rf ./build/*
	rm -rf ./output/*

install: $(EXEC) $(LIB) 
	install -d $(DESTDIR)$(bindir)
	install -s -m 755 $(EXEC) $(DESTDIR)$(bindir) 
	install -d $(DESTDIR)$(libdir)
	install -s -m 755 $(LIB) $(DESTDIR)$(libdir)
	install -d $(DESTDIR)$(includedir)/$(PROJECT_NAME)
	install -m 644 $(PUB_H) $(DESTDIR)$(includedir)/$(PROJECT_NAME)

uninstall:
	rm -f $(DESTDIR)$(bindir)/$(notdir $(EXEC))
	rm -f $(DESTDIR)$(libdir)/$(notdir $(LIB))
	rm -rf $(DESTDIR)$(includedir)/$(PROJECT_NAME)
