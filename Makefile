#
# Makefile for wfc driver
#

MAKEFLAGS += --warn-undefined-variables
SHELL := bash
	.SHELLFLAGS := -eu -o pipefail -c
	.DEFAULT_GOAL := all

# C++17 compiler
ENABLE="source /opt/rh/devtoolset-8/enable"
CXX=g++
CXXFLAGS=--std=c++17 -Wall -Wno-sign-compare -O3 -g -DNDEBUG
LDFLAGS=-lstdc++ -lpthread -ldl
LDLIBS=-I libs -I libs/emilib
OBJDIR=build
OBJS=$(OBJDIR)/main.o $(OBJDIR)/libs.o

FILES:=$(shell echo *.cpp)
EXECUTABLE:=main

.PHONY: all dirs clean

# Only execute `all` rule if any file in $(EXECUTABLE) have changed
all: $(EXECUTABLE)

dirs:
	@echo "Updating submodule..."
	@git submodule update --init --recursive
	@echo "Creating build and output directories..."
	@mkdir -p build
	@mkdir -p output

$(EXECUTABLE): dirs $(OBJS)
	@echo "Linking..."
	$(CXX) $(CXXFLAGS) -o $@ $(OBJS) $(LDFLAGS) $(LDLIBS)
	@echo "Done."

$(OBJDIR)/%.o: %.cpp
	$(CXX) $< $(CXXFLAGS) $(LDLIBS) -c -o $@

# make clean will clear the build dir
clean:
	rm -rf build
	rm -rf output


