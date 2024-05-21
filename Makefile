# Basic makefile for compiling and running tests for a very basic project
SHELL = /bin/sh
.SUFFIXES:

# Project configuration
PROJECT_NAME := cstyle
VERSION_MAJOR := 0
VERSION_MINOR := 1
VERSION_PATCH := 2
BUILD_CFG ?= debug
BUILD_TYPE ?= exec

# Directory definitions
ROOT_DIR := .
SRC_DIR := src
INC_DIR := include
TEST_DIR := test
SCRIPT_DIR := script
BUILD_DIR := build
OUTPUT_DIR := output
TESTOUT_DIR := $(BUILD_DIR)/$(TEST_DIR)

# Compilation settings
CFLAGS = -Wall -Wextra -Wpedantic -std=c17 -I$(INC_DIR)
ifeq ($(BUILD_CFG),debug)
CFLAGS += -g -O0 -DDEBUG
endif

# Configure external libraries
LDFLAGS = 
# glib-2.0
CFLAGS += $(shell pkg-config --cflags glib-2.0)
LDFLAGS += $(shell pkg-config --libs glib-2.0)

# Find all the source and header files
EXE_SRC = $(ROOT_DIR)/$(SRC_DIR)/$(PROJECT_NAME).c
OBJ_SRC = $(filter-out $(EXE_SRC),$(wildcard $(ROOT_DIR)/$(SRC_DIR)/*.c))
TEST_SRC = $(wildcard $(ROOT_DIR)/$(TEST_DIR)/*.c)
PVT_H = $(wildcard $(ROOT_DIR)/$(INC_DIR)/*.h)
PUB_H = $(wildcard $(ROOT_DIR)/$(INC_DIR)/$(PROJECT_NAME)/*.h)

# Calculate names of the build artifacts and outputs
EXE = ./$(OUTPUT_DIR)/$(PROJECT_NAME)-v$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH)
SLIB = ./$(OUTPUT_DIR)/lib$(PROJECT_NAME)-v$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH).a
DLIB = ./$(OUTPUT_DIR)/lib$(PROJECT_NAME)-v$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH).so
OBJS = $(patsubst $(ROOT_DIR)/$(SRC_DIR)/%.c,./$(BUILD_DIR)/%.o,$(OBJ_SRC))
TEST_EXES = $(patsubst $(ROOT_DIR)/$(TEST_DIR)/%.c,./$(BUILD_DIR)/$(TEST_DIR)/%.elf,$(TEST_SRC))
TEST_OUTS = $(patsubst $(ROOT_DIR)/$(TEST_DIR)/%.c,./$(OUTPUT_DIR)/$(TEST_DIR)/%.out,$(TEST_SRC))

# Input checking
ifneq ($(BUILD_CFG),debug)
ifneq ($(BUILD_CFG),release)
$(error BUILD_CFG must be either 'debug' or 'release')
endif
endif

ifneq ($(BUILD_TYPE),exec)
ifneq ($(BUILD_TYPE),slib)
ifneq ($(BUILD_TYPE),dlib)
$(error BUILD_TYPE must be either 'exec', 'slib', or 'dlib')
endif
endif
endif

# Build targets
.PHONY: clean

all: $(BUILD_TYPE)

exec: $(EXE)

slib: $(SLIB)

dlib: $(DLIB)

test: $(TEST_OUTS) $(TEST_EXES)

$(EXE): $(EXE_SRC) $(OBJS)
	@mkdir -p ./$(OUTPUT_DIR)
	$(CC) $(CFLAGS) -o $@ $< $(OBJS) $(LDFLAGS)

$(SLIB): $(OBJS)
	@mkdir -p ./$(OUTPUT_DIR)
	$(AR) rcs $@ $(OBJS) $(LDFLAGS)

$(DLIB): $(OBJS)
	@mkdir -p ./$(OUTPUT_DIR)
	$(CC) $(CFLAGS) -shared $(OBJS) -o $@ $(LDFLAGS)

./$(BUILD_DIR)/%.o : $(ROOT_DIR)/$(SRC_DIR)/%.c $(PVT_H) $(PUB_H)
	@mkdir -p ./$(BUILD_DIR)
	$(CC) $(CFLAGS) -c -o $@ $<

./$(BUILD_DIR)/$(TEST_DIR)/%.elf : $(ROOT_DIR)/$(TEST_DIR)/%.c $(OBJS)
	@mkdir -p ./$(BUILD_DIR)/$(TEST_DIR)
	$(CC) $(CFLAGS) -o $@ $< $(OBJS) $(LDFLAGS)

./$(OUTPUT_DIR)/$(TEST_DIR)/%.out : ./$(BUILD_DIR)/$(TEST_DIR)/%.elf $(TEST_EXES)
	@mkdir -p ./$(OUTPUT_DIR)/$(TEST_DIR)
	@$(ROOT_DIR)/$(SCRIPT_DIR)/runtest.sh $< $@

clean:
	rm -rf ./$(BUILD_DIR)/*
	rm -rf ./$(OUTPUT_DIR)/*
