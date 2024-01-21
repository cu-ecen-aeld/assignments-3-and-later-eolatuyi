#!/bin/bash
# assignment 1
# Description:
#    Write a shell script finder-app/writer.sh as described below
#    
#    Accepts the following arguments: the first argument is a full path to a file (including filename) on the filesystem, 
#    referred to below as writefile; the second argument is a text string which will be written within this file, referred to below as writestr
#    
#    Exits with value 1 error and print statements if any of the arguments above were not specified
#    
#    Creates a new file with name and path writefile with content writestr, overwriting any existing file and creating the path if it doesn’t 
#    exist. Exits with value 1 and error print statement if the file could not be created.
#    
#    Example:
#    
#       writer.sh /tmp/aesd/assignment1/sample.txt ios
#    
#    Creates file:
#    
#       /tmp/aesd/assignment1/sample.txt
#    
#           With content:
#    
#               ios
# Author: Ebenezer Olatuyi

#config
REQUIRED_NUM_OF_ARG=2

# validate number of arguments
if [ $# -ne $REQUIRED_NUM_OF_ARG ]; then
    echo "Line $LINENO: Error - Invalid Number of args = $#"
    exit 1
fi

writefile=$1
writestr=$2
directory=$(dirname "$writefile")

# confirm file name is valid by touching it and suppressing error out
# if touch fails, attempt to make path before redirection writetr to writefile
if [  $(touch "$writefile" 2> "/dev/null" || mkdir -p "$directory") ]; then
    echo "Line $LINENO: Error - $1 is an Invalid filename"
    exit 1
fi

echo "$writestr" > "$writefile"