#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "cstyle/util.h"

int main()
{
    int retval = EXIT_SUCCESS;
    char *expected_message = "UmFuZG9tIG1lc3NhZ2UsIHJlYWxseSBzZWN1cmUgc3R1ZmYgKlRPUF9TRUNSRVQq";
    char *actual_message = get_encoded_message();
    if (!(0 == strcmp(expected_message, actual_message)))
    {
        fprintf(stderr, "Expected and actual encoded message do not match\n");
        retval = EXIT_FAILURE;
    }
    free(actual_message);
    return retval;
}
