# GhostWrench C source code and project style guide

Most importantly: attempt to match the style of the project of the source code 
you are editing. This guide is only for non-legacy internal projects.

## Versioning

Use [semantic versioning](https://semver.org/) format `MAJOR.MINOR.PATCH`.
Increment:

1. MAJOR when you make incompatible API changes
2. MINOR when you add functionality in a backwards compatible manner
3. PATCH when you make a backwards compatible bug fix

## Source Code

### Indentation

Use 4 spaces, do not use tabs. No preference is given to putting an opening
bracket at the end of the line or on a new line. Both of these are OK:

```c
int my_func(int value)
{
    return value + 3;
}
```

```c
if (test_case == 0) {
    do_action(0);
    do_action(1);
} else if (test_case == 1) {
    do_action(2);
} else {
    do_action(42);
}
```

### Line length

_Try_ to keep line length less then 80 characters. If this is not possible do 
not mangle other aspects of the formatting or shorten variable names to achieve 
80 characters, just use as much space as is needed.

### Comments

Brief comments can be put in code to break up distinct logical sections in long 
functions to make them easier to read. They should also be put in to describe 
hacks or non-intuitive sections of code. Do not use comments to remove code, as 
a form of version control or for straight-forward easy to read code.  

### Variables

Use `snake_case`. Global variables must have descriptive names and MUST NOT use 
non-common abbreviations. DO NOT use global variables as a way to pass 
information to and from functions implicitly. There are few valid use cases for 
global variables, primarily they are used to track some singular system state 
that may change depending on interaction from external inputs (user, hardware, 
etc.). Even so, it is probably a good idea to indicate that a function may 
modify a global variable by passing it or a pointer to it explicitly to the
function.

### Functions

Use `snake_case`. If the function is designed around a specific data structure
you can prepend the function with the name of the data structure e.g. 
`MyStruct_create(MyStruct *my_struct)` this can be used to implement object
oriented solutions. For functions with a long list of variables put input on
it's own line:

```c
int long_func(
    int really_important_value,
    char *really_important_string, 
    bool do_the_thing_with_the_thing )
{
    return 5;
}
```

No maximum function length is prescribed, a function should do one thing and
take all the steps necessary to achieve that thing. If there are operations in
that function that are generally useful for other parts of the code, ONLY THEN
should those operations be put into a separate function. It is much easier to
break up a long function when things are getting too verbose than it is to 
comprehend how a rat's nest of small functions that have trivial jobs work
together to achieve something.

### Macros

Use `UPPER_SNAKE_CASE` for macros. For function like macros enclose the 
arguments in parenthesis when used in the macro body. Also, if the macro 
declares any temporary variables, make sure that it is enclosed in brackets to
prevent namespace collisions:

```c
#define FOO(x, y)             \
({                            \
    typeof(x) ret;            \
    ret = calc_ret((x), (y)); \
    (ret);                    \
})
```

### Structs, enums and typedef

typedef any structs or enums that you plan on using in multiple places (which 
should be most of them). The members of an enum should use `UPPER_SNAKE_CASE`
and the members of a struct should be in `snake_case`. The typdef name should
use `CamelCase`.

```c
typedef struct
{
    double w;
    double h;
    enum {
        RECTANGLE_BOX_IS_RED,
        RECTANGLE_BOX_IS_GREEN,
        RECTANGLE_BOX_IS_BLUE,
    } color;
} RectangleBox;
```

### Include guards

Use include guards in header files with the following format:

```c
#ifndef <MODULE_OR_PROJECT_NAME>_<PUB|PVT>_<FILENAME>_H
#define <MODULE_OR_PROJECT_NAME>_<PUB|PVT>_<FILENAME>_H

...

#endif // <MODULE_OR_PROJECT_NAME>_<PUB|PVT>_<FILENAME>_H
```

Use `PUB` for public headers that will be accessible by external programs and
libraries. Use `PVT` for headers that are for use only within the program. 

### Defining headers for external use

If your project defines headers so that your code can be used as an external
library the headers and everything defined in them should be "namespaced" with
the module or project name to avoid collisions with anything in the code that
uses them. This means the header must be included with

```c
#include <modulename/file.h>
```

and global functions, variables, typedefs and macros defined by them must be of 
the form `<modulename>_variable_or_func_name` so as not to pollute the 
namespace 

```c
// Variables
const extern int modulename_magic_number = 42;
// Functions
int modulename_magic_function(const int magic_number);
// typedefs
typedef enum
{
    MODULENAME_HAS_NO_MAGIC = 0,
    MODULENAME_HAS_MAGIC = 1,
} ModulenameHasMagic;
// Macros
#define MODULENAME_MAGIC MODULENAME_HAS_MAGIC
```

### goto

There is only one valid use of `goto` which is described in the linux coding 
style in section 7: exiting a function prematurely where some sort of cleanup
(memory free, etc.) is required. Consider the following example:

```c
int func_with_malloc()
{
    int err = 0;
    char *buffer = malloc(SIZE);
    if (!buffer)
    {
        err = 1;
        return err;
    }
    for (int ii=0; ii<=SIZE; ii++)
    {
        err = do_something_with_a_buffer(buffer);
        if (err)
        {
            goto cleanup;
        }
    }
    err = do_something_else_with_a_buffer(buffer);

cleanup:
    free(buffer);
    return err; 
}
```

Other than this one use case: do not use `goto`.

## Project Structure

The following project structure is for very simple one size fits all `make` 
based builds. For larger projects that need a more sophisticated build system 
this section should be disreguarded and the project structure should be defined
on a case by case basis.

### Makefile

See the template included in this project, if the prescribed project structure 
is adheared to, then it should work in most cases.

### Containerfile/Dockerfile

It is highly recommended you include a Containerfile/Dockerfile and a 
compose.yml file that can be used with Podman or Docker to easily set up a 
development environment. See the example provided in this repo for a simple 
setup that works in many cases. Also add a markdown called CONTAINER.md to the 
root directory of the project describing how to run the container for 
development, builds etc.

### src/

For the compiled `*.c` source files, if one of the project build targets is an 
executable, put the `main()` function into a `<project_name>.c` file. This is
a special file name which will only be used for compiling an executable and 
will not be included in static (`slib`) or dynamic library (`dlib`) builds.

### include/

For headers `*.h` that are used internally by your project are placed in this 
folder. If you are defining headers that will be used externally from your 
project put them in `include/<project_name>/`. This is done so that if a single 
source file (compilation unit) can define both internal and public headers.

### extern/

Any code or data sourced from an external source should be put in here and 
preferably downloaded as a part of the build and ignored in source control.

### test/

This folder contains `*.c` files with a main() defining a single test with a 
pass or fail criteria indicated by whether the function exits or returns with 
EXIT_FAILURE or EXIT_SUCCESS.

### script/

Any external utility or build scripts can be put in here.

### doc/

Any relevant documentation that is not auto generated or part of the source 
itself should be put in here.

### build/

This is where build artifacts will go during the build (if you are building in 
the project base directory). Source control should be configured to ignore this
folder.

### output/

This is where the final results of the build should go. Source control should 
be configured to ignore this folder.

## Unit Testing

The provided Makefile will compile and run any source files in the `test` 
folder and print the program status for each with an "OK" or "FAILED" message.
It will also run the tests under valgrind to ensure that there are non apparent
memory issues and put the output in `output` folder.

If it is desired to measure the coverage of your tests compile with the 
`--coverage` flag and use `lcov` to generate a report. Using coverage as a
target may be more harmful than helpful, use at your own risk. In a perfect 
world developers should endevor to write, relevant, stable, and smartly targeted
tests and judge their quality on how often they catch regressions and ignore
coverage, but we do not live in a perfect world.

Some code is difficult to unit test (libraries requiring a large amount of 
user input) but for most things, writing modular code will assist in your 
ability to effectivly unit test it. It will also increase the overall quality
of the finished product. It shouldn't have to be said that you should try to
make your code as modular and testable as possible.
