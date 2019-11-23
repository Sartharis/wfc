# 
# Makefile for wfc driver
#

set -eu				# make it an error to reference non-existent env variable
set -o pipefail		# raise error if commands or pipes incorrect

# C++14 compiler
CXX=g++
CPPFLAGS="--std=c++14 -Wall -Wno-sign-compare -O2 -g -DNDEBUG"
LDLIBS="-lstdc++ -lpthread -ldl"
OBJECTS=""

git submodule update --init --recursive

mkdir -p build

for source_path in *.cpp; do
	obj_path="build/${source_path%.cpp}.o"
	OBJECTS="$OBJECTS $obj_path"
	if [ ! -f $obj_path ] || [ $obj_path -ot $source_path ]; then
		echo "Compiling $source_path to $obj_path..."
		$CXX $CPPFLAGS                      \
			-I libs -I libs/emilib          \
			-c $source_path -o $obj_path
	fi
done

echo "Linking..."
$CXX $CPPFLAGS $OBJECTS $LDLIBS -o wfc.bin
echo "Done."

# Run it:
# mkdir -p output
# ./wfc.bin $@
# exit

# make clean will clear the build dir
clean:
	rm -rf build

.PHONY: clean
