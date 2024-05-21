#include <glib.h>

#include "util.h"
#include "cstyle/util.h"

// Private function
char *generate_random_message(void)
{
    return "Random message, really secure stuff *TOP_SECRET*";
}

// Public function
char *get_encoded_message(void)
{
    char *message = generate_random_message();
    size_t message_length = strlen(message);
    return g_base64_encode((guchar*)message, message_length);
}
