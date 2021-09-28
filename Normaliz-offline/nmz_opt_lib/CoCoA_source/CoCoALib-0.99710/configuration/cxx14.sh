#!/bin/bash

SCRIPT_NAME=[[`basename "$0"`]]
SCRIPT_DIR=`dirname "$0"`

# Auxiliary script for CoCoALib configuration process.
# Script expects the env variables CXX and CXXFLAGS to be set.

# Script to see whether the -std=c++14 compiler flag is needed/recognised.
# Exit with code 1 if we did not find a way to compile C++14 code.
# Exit with code 0 if we found a way to compile C++14 code; printed
# value is flag to give compiler to get C++14 compilation
# (printed value may be empty string or "-std=c++14")


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
TMP_DIR=`mktempdir cxx14`

pushd "$TMP_DIR"  > /dev/null

/bin/cat > test-cxx14.C <<EOF
#include <iostream>
int main()
{
  int ReturnCode = 0; // will mean c++14 compliant
  std::cout << "C++ version: " << __cplusplus << std::endl;
#if __cplusplus < 201400L
  ReturnCode = 1;  // NOT C++14 compilant
#endif
  return ReturnCode;
}
EOF

# First try with no compiler flag...
"$CXX"  test-cxx14.C  -o test-cxx14  >> LogFile  2>& 1 
if [ $? -ne 0 ]
then
    echo "ERROR: test compilation unexpectedly failed; is $CXX a c++ compiler?   $SCRIPT_NAME" > /dev/stderr
    exit 1
fi
./test-cxx14  >> LogFile
if [ $? -eq 0 ]
then
    popd  > /dev/null
    /bin/rm -rf "$TMP_DIR"
    exit 0; # exit without printing (no flag needed for C++14)
fi

# Compilation without flag is not C++14 standard; try with -std=c++14

CXX14="-std=c++14"
"$CXX" $CXX14 test-cxx14.C  -o test-cxx14  >> LogFile  2>& 1 
if [ $? -ne 0 ]
then
    echo "ERROR: test compilation with flag $CXX14 failed   $SCRIPT_NAME" > /dev/stderr
    exit 1  
fi

./test-cxx14  >> LogFile
if [ $? -eq 0 ]
then
    popd  > /dev/null
    /bin/rm -rf "$TMP_DIR"
    echo "$CXX14"
    exit 0; # Success (flag for C++14 sent via echo to stdout)
fi

echo "ERROR: failed to find flag for C++14 compilation   $SCRIPT_NAME"  > /dev/stderr
exit 2 # 
