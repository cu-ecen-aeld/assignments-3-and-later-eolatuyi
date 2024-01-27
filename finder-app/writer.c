/*
# assignment 2
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
# Date  :1-26-2024
*/

#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>

int main(int argc, char *argv[]) {
    
    openlog(NULL, 0, LOG_USER); // Setup Syslog
    
    // Check if the correct number of arguments is provided
    if (argc != 3) {
        //printf("Usage: %s <writefile> <writestr>\n", argv[0]);
        syslog(LOG_ERR | LOG_USER, "Usage: %s <writefile> <writestr>\n", argv[0]);
        return 1;
    }

    // Get the file path and writestr from the command line arguments
    char *writefile = argv[1];
    char *writestr = argv[2];

    // Validate the file path
    FILE *file = fopen(writefile, "w");
    if (file == NULL) {
        //printf("Error: Failed to open file %s... Confirm file part is valid\n", writefile);
        syslog(LOG_ERR | LOG_USER, "Error: Failed to open file %s... Confirm file part is valid\n", writefile);
        return 1;
    }

    // Validate the writestr
    if (writestr == NULL || writestr[0] == '\0') {
        //printf("Error: Invalid writestr\n");
        syslog(LOG_ERR | LOG_USER, "Error: Invalid writestr\n");
        return 1;
    }

    // write the writestr to the writefile
    syslog(LOG_DEBUG | LOG_USER, "Writing %s to %s", writestr, writefile);
    fprintf(file, "%s\n", writestr);
    fclose(file);

    return 0;
}
