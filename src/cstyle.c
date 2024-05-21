// Main program

#include <stdlib.h>
#include <stdio.h>

#include <cstyle/util.h>

int main()
{
    char *message = get_encoded_message();
    printf("Generating secret random message:\n%s\nYou are welcome.\n", message);
    free(message);
    return EXIT_FAILURE;
}
