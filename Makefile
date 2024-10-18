# Basic makefile for compiling and running tests for a very basic project
SHELL = /bin/sh
.SUFFIXES:

# Build options
BUILD_CFG ?= debug
BUILD_TYPE ?= exec
SHARED_LIB ?= 1
CFLAGS_EXTRA ?= 
LDFLAGS_EXTRA ?=

# Build Settings
CFLAGS = -Wall -Wextra -Wpedantic -std=c17 -I$(srcdir)/include
ifeq ($(BUILD_CFG),debug)
CFLAGS += -g -O0 -DDEBUG
endif
LDFLAGS = 

# Directory definitions
srcdir = .
prefix = /usr/local
exec_prefix = $(prefix)
localstatedir = $(prefix)/var
includedir = $(prefix)/include
libdir = $(exec_prefix)/lib
DESTDIR = 

# Project configuration
PROJECT_NAME = cstyle
VERSION_MAJOR = $(shell sed -n -e 's/\#define CSTYLE_VERSION_MAJOR \([0-9]*\)/\1/p' $(srcdir)/include/$(PROJECT_NAME).h)
VERSION_MINOR = $(shell sed -n -e 's/\#define CSTYLE_VERSION_MINOR \([0-9]*\)/\1/p' $(srcdir)/include/$(PROJECT_NAME).h)
VERSION_PATCH = $(shell sed -n -e 's/\#define CSTYLE_VERSION_PATCH \([0-9]*\)/\1/p' $(srcdir)/include/$(PROJECT_NAME).h)

# Configure external libraries
# glib-2.0
CFLAGS += $(shell pkg-config --cflags glib-2.0)
LDFLAGS += $(shell pkg-config --libs glib-2.0)

# Find all the source and header files
EXE_SRC = $(srcdir)/src/$(PROJECT_NAME).c
OBJ_SRC = $(filter-out $(EXE_SRC),$(wildcard $(srcdir)/src/*.c))
TEST_SRC = $(wildcard $(srcdir)/test/*.c)
PVT_H = $(wildcard $(srcdir)/include/*.h)
PUB_H = $(wildcard $(srcdir)/include/$(PROJECT_NAME)/*.h)

# Calculate names of the build artifacts and outputs
EXE = ./output/$(PROJECT_NAME)-v$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH)
ifeq ($(SHARED_LIB),1)
LIB = ./output/lib$(PROJECT_NAME)-v$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH).so
else
LIB = ./output/lib$(PROJECT_NAME)-v$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH).a
endif
OBJS = $(patsubst $(srcdir)/src/%.c,./build/%.o,$(OBJ_SRC))
TEST_EXES = $(patsubst $(srcdir)/test/%.c,./build/test/%.elf,$(TEST_SRC))
TEST_OUTS = $(patsubst $(srcdir)/test/%.c,./build/test/%.out,$(TEST_SRC))

# Input checking
ifneq ($(BUILD_CFG),debug)
ifneq ($(BUILD_CFG),release)
$(error BUILD_CFG must be either 'debug' or 'release')
endif
endif

ifneq ($(BUILD_TYPE),exec)
ifneq ($(BUILD_TYPE),lib)
$(error BUILD_TYPE must be either 'exec' or 'lib')
endif
endif

# Build targets
.PHONY: clean

all: $(BUILD_TYPE)

exec: $(EXE)

lib: $(LIB)

test: $(TEST_EXES)

runtest: $(TEST_OUTS)

$(EXE): $(EXE_SRC) $(OBJS)
	@mkdir -p ./$(OUTPUT_DIR)
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

./build/test/%.out : ./build/test/%.elf $(TEST_EXES)
	@mkdir -p ./$(OUTPUT_DIR)/$(TEST_DIR)
	@$(srcdir)/script/runtest.sh $< $@

clean:
	rm -rf ./build/*
	rm -rf ./output/*
