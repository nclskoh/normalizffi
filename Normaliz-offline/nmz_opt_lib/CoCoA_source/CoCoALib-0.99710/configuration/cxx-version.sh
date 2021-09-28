#!/bin/bash

SCRIPT_NAME=[[`basename "$0"`]]
SCRIPT_DIR=`dirname "$0"`

# Auxiliary script for CoCoALib configuration process.
# Script expects the env variables CXX and CXXFLAGS to be set.

# Script prints out the version of C++ supported by the compiler $CXX:
# possible outputs are "c++03", "c++11" or "c++14"

if [ $# -ne 0 ]
then
  echo "ERROR: expected no args.   $SCRIPT_NAME"  > /dev/stderr
  exit 1
fi

# Check environment variable CXX
if [ -z "$CXX" ]
then
  echo "ERROR: environment variable CXX not set.   $SCRIPT_NAME"  > /dev/stderr
  exit 1
fi


# Create tmp directory, put test prog in it, compile and run.
umask 22
source "$SCRIPT_DIR/shell-fns.sh"
TMP_DIR=`mktempdir cxx-version`

pushd "$TMP_DIR"  > /dev/null

/bin/cat > CXXVersion.C <<EOF
#include <iostream>

int main()
{
#if __cplusplus <= 199711L
  std::cout << "c++03\n";
#endif
#if __cplusplus > 199711L && __cplusplus <= 201103L
  std::cout << "c++11\n";
#endif
#if __cplusplus > 201103L
  std::cout << "c++14\n";
#endif
}
EOF

"$CXX" $CXXFLAGS CXXVersion.C -o CXXVersion  >> LogFile  2>& 1 
if [ $? -ne 0 ]
then
    echo "ERROR: failed to compile test program in \"$TMP_DIR\".   $SCRIPT_NAME"  > /dev/stderr
    exit 2
fi
CXX_VERSION=`./CXXVersion`

# Clean up TMP_DIR
popd  > /dev/null
/bin/rm -rf "$TMP_DIR"
echo $CXX_VERSION
