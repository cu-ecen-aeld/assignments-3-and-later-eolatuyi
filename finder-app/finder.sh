#!/bin/sh
# assignment 1
# Description:
#     Write a shell script finder-app/finder.sh as described below:
#     Accepts the following runtime arguments: the first argument is a path to a directory on the filesystem, referred to below as filesdir; 
#     the second argument is a text string which will be searched within these files, referred to below as searchstr
#     
#     Exits with return value 1 error and print statements if any of the parameters above were not specified
#     
#     Exits with return value 1 error and print statements if filesdir does not represent a directory on the filesystem
#     
#     Prints a message "The number of files are X and the number of matching lines are Y" where X is the number of files in the directory 
#     and all subdirectories and Y is the number of matching lines found in respective files, where a matching line refers to a line which 
#     contains searchstr (and may also contain additional content).
#
#     Example invocation:
#            finder.sh /tmp/aesd/assignment1 linux
# Author: Ebenezer Olatuyi

#config
REQUIRED_NUM_OF_ARG=2

# validate number of arguments
if [ $# -ne $REQUIRED_NUM_OF_ARG ]; then
    echo "Line $LINENO: Error - Invalid Number of args = $#"
    exit 1
fi

# confirm first arg is a file directory
filesdir=$1
if [ ! -d "$filesdir" ]; then
    echo "Line $LINENO: Error - $1 is an Invalid directoy"
    exit 1
fi

searchstr=$2

numOfMatchingFiles=$(   grep -rl "$searchstr" "$filesdir" | wc -l)
numOfNonMatchingFiles=$(grep -rL "$searchstr" "$filesdir" | wc -l)
numOfMatchingLine=$(    grep -r  "$searchstr" "$filesdir" | wc -l)

#echo "Number of Matching Files    : $numOfMatchingFiles"
#echo "Number of Non Matching Files: $numOfNonMatchingFiles"
#echo "Number of Matching Line     : $numOfMatchingLine"

numOfInputFiles=$(($numOfMatchingFiles + $numOfNonMatchingFiles))

echo "The number of files are $numOfInputFiles and the number of matching lines are $numOfMatchingLine"
