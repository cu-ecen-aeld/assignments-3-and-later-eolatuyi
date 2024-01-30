#include "systemcalls.h"
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <syslog.h>
#include <string.h>

/**
 * @param cmd the command to execute with system()
 * @return true if the command in @param cmd was executed
 *   successfully using the system() call, false if an error occurred,
 *   either in invocation of the system() call, or if a non-zero return
 *   value was returned by the command issued in @param cmd.
*/
bool do_system(const char *cmd)
{
/*
 *  Call the system() function with the command set in the cmd
 *   and return a boolean true if the system() call completed with success
 *   or false() if it returned a failure
*/
    int status = system(cmd);
    if (status == 0) {
        return true;
    } else {
        return false;
    }
}

/**
* @param count -The numbers of variables passed to the function. The variables are command to execute.
*   followed by arguments to pass to the command
*   Since exec() does not perform path expansion, the command to execute needs
*   to be an absolute path.
* @param ... - A list of 1 or more arguments after the @param count argument.
*   The first is always the full path to the command to execute with execv()
*   The remaining arguments are a list of arguments to pass to the command in execv()
* @return true if the command @param ... with arguments @param arguments were executed successfully
*   using the execv() call, false if an error occurred, either in invocation of the
*   fork, waitpid, or execv() command, or if a non-zero return value was returned
*   by the command issued in @param arguments with the specified arguments.
*/

bool do_exec(int count, ...)
{
    openlog("systemcalls::do_exec", 0, LOG_USER);
    va_list args;
    va_start(args, count);
    char * command[count+1];
    char full_command_path[1024];
    int i;
    for(i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);  
        if(i==0){
            if(strrchr(command[0], '/') == NULL) {
                syslog(LOG_ERR | LOG_USER, "Failed: Invalid path Arg: %s\n", command[0]);   
                return false; //Weird but had to return here to get do_exec echo without full path to fail
            }
            else strcpy(full_command_path, command[0]); 
        } 
    }
    command[count] = NULL;
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed
    command[count] = command[count];

/*

 *   Execute a system command by calling fork, execv(),
 *   and wait instead of system (see LSP page 161).
 *   Use the command[0] as the full path to the command to execute
 *   (first argument to execv), and use the remaining arguments
 *   as second argument to the execv() command.
 *
*/ 

    char *filename;

    // Find the last occurrence of the directory separator '/'
    filename = strrchr(command[0], '/');

    // If the separator is found, move one character ahead to get the filename
    if (filename != NULL) {
        filename++; // Move past the '/'
        command[0] = filename;
    } else {
        command[0] = NULL;
    }
    int status;
    // Create a buffer to hold the concatenated string
    char commandString[1024];
    int offset = 0;
    // Concatenate the command and arguments into a single string
    for (i = 0; i < count+1; i++) {
        offset += sprintf(commandString + offset, "%s ", command[i]);
    } 

    fflush(stdout);
    pid_t pid = fork();
    if (pid == -1)
    {
        // Error occurred while forking
        va_end(args);
        return false;
    }
    else if (pid == 0)
    {
        // Child process 

        //syslog(LOG_DEBUG | LOG_USER, "Args: %s %s \"%s\". pid = %d\n", argv[0], argv[1], argv[2], pid);
        syslog(LOG_DEBUG | LOG_USER, "Args: %s, \"%s\". pid = %d\n", full_command_path, commandString, pid);                      

        execv(full_command_path, command);

        syslog(LOG_ERR | LOG_USER, "Error: Failed to execute command: %s, \"%s\". pid = %d\n", full_command_path, commandString, pid);
        // execv only returns if an error occurred
        va_end(args);
        return false;
    }

    // Parent process
    
    else if(waitpid(pid, &status, 0) == -1)
    {
        // Error occurred while waiting for child process
        perror ("waitpid");
        va_end(args);
        return false;
    }
    else if(WIFEXITED(status) )
    {
        // Command executed successfully
        syslog(LOG_DEBUG | LOG_USER, "Cmd exec Success: %s, \"%s\". status = %i, WEXITSTATUS(status) = %i. pid = %d\n", full_command_path, commandString, status, WEXITSTATUS(status), pid);
        va_end(args);
        return !WEXITSTATUS(status);
    }
    else
    {
        // Command execution failed
        syslog(LOG_ERR | LOG_USER, "Cmd exec Failed: %s, \"%s\". status = %i, WEXITSTATUS(status) = %i\n", full_command_path, commandString, status, WEXITSTATUS(status));
        va_end(args);
        return false;
    }
    syslog(LOG_DEBUG | LOG_USER, "Exit Should not get here\n");
    va_end(args);
    return true;
}

/**
* @param outputfile - The full path to the file to write with command output.
*   This file will be closed at completion of the function call.
* All other parameters, see do_exec above
*/
bool do_exec_redirect(const char *outputfile, int count, ...)
{
    va_list args;
    va_start(args, count);
    char * command[count+1];
    int i;
    for(i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed
    command[count] = command[count];


/*
 *   Call execv, but first using https://stackoverflow.com/a/13784315/1446624 as a refernce,
 *   redirect standard out to a file specified by outputfile.
 *   The rest of the behaviour is same as do_exec()
 *
*/

    int pid;
    int fd = open(outputfile, O_WRONLY|O_TRUNC|O_CREAT, 0644);
    if (fd < 0) 
    { 
        perror("open"); 
        va_end(args);
        return false;
    }
    fflush(stdout);
    switch (pid = fork()) 
    {
        case -1: 
            perror("fork"); 
            // Error occurred while forking
            va_end(args);
            return false;
        case 0:
            if (dup2(fd, 1) < 0) 
            { 
                perror("dup2"); 
                va_end(args);
                return false; 
            }
            close(fd);
            execvp(command[0], command); 
            perror("execvp"); 
            // execv only returns if an error occurred
            va_end(args);
            return false;
        default:
            close(fd);
            /* do whatever the parent wants to do. */
            int status;
            if(waitpid (pid, &status, 0) == -1)
            {
                // Error occurred while waiting for child process
                va_end(args);
                return false;
            }
            else if (WIFEXITED(status) && (WEXITSTATUS(status) == 0))
            {
                // Command executed successfully
                va_end(args);
                return true;
            }
            else
            {
                // Command execution failed
                va_end(args);
                return false;
            }            
    }

    va_end(args);

    return true;
}
