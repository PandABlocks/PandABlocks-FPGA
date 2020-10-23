/* FPGALoad - utility for programming PSC Xilinx Spartan3E firmware.
 *
 * Following GPIOs are used to interface to FPGA for programming.
 *    CCLK  ( output, initialise 0 )
 *    D0    ( output, initialise 0 )
 *    PROGB ( output, initialise 1 )
 *    DONE  ( input  )
 *    INIT  ( input  )
 *
 * PROG_B (output) XXXXX |_______|
 *                                   ___________________________
 * INIT_B (input ) XXXXXXXXX________|
 *                                           _        _
 * CCLK   (output) XXXXX____________________| |______| |________
 *
 * DO     (output) XXXXX_____________________X________X_________
 */

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdarg.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>


#define ASSERT(e) if(!(e)) assert_fail(__FILE__, __LINE__)

static void assert_fail(const char *filename, int linenumber)
{
    fprintf(stderr, "Error at line %d, file %s (%d) [%s]\n",
        linenumber, filename, errno, strerror(errno));
    exit(1);
}


/* The GPIOs we are using.  These are all indexes into the gpio_info table
 * below, configure that table for the correct GPIO numbers. */
#define GPIO_CCLK   0
#define GPIO_D0     1
#define GPIO_PROGB  2
#define GPIO_DONE   3
#define GPIO_INIT   4
#define GPIO_M0     5


/* GPIO access table: a table of open file handles for the five GPIOs we are
 * controlling. */

/* This offset is added to each GPIO number to map from hardware pin number to
 * kernel identifier. */
#define GPIO_OFFSET     906

/* The table below is initialised with the GPIO offset for the physical pin used
 * for the GPIO function. */
struct gpio_info {
    const int gpio;     // Physical GPIO used for this function
    int file;           // Open file handle for write access to this GPIO
    const char *path;   // File name for read access to this GPIO
    bool value;         // Last value written for update optimisation
};
static struct gpio_info gpio_info[] = {
    [GPIO_CCLK]  = { .gpio = GPIO_OFFSET + 9, },
    [GPIO_D0]    = { .gpio = GPIO_OFFSET + 10, },
    [GPIO_PROGB] = { .gpio = GPIO_OFFSET + 13, },
    [GPIO_DONE]  = { .gpio = GPIO_OFFSET + 11, },
    [GPIO_INIT]  = { .gpio = GPIO_OFFSET + 12, },
    [GPIO_M0]    = { .gpio = GPIO_OFFSET + 0, },
};


static bool read_gpio(int gpio)
{
    struct gpio_info *info = &gpio_info[gpio];
    char buf[16];
    int file = open(info->path, O_RDONLY);
    ASSERT(file > 0);
    ASSERT(read(file, buf, sizeof(buf)) > 0);
    close(file);
    return buf[0] == '1';
}


static void write_gpio_value(int gpio, bool value)
{
    struct gpio_info *info = &gpio_info[gpio];
    char buf = value ? '1' : '0';
    ASSERT(write(info->file, &buf, 1) == 1);
    info->value = value;
}


/* We optimise the writing of GPIOs by not writing when the value hasn't
 * changed.  This is a worthwhile optimisation for this application: the
 * bitstream being loaded has many successive zeros, so we may save up to 30%
 * off the load time. */
static void write_gpio(int gpio, bool value)
{
    struct gpio_info *info = &gpio_info[gpio];
    if (info->value != value)
        write_gpio_value(gpio, value);
}


/* Writes given formatted string to file. */
static void write_to_file(const char *file_name, const char *format, ...)
{
    va_list args;
    va_start(args, format);
    char string[256];
    int len = vsnprintf(string, sizeof(string), format, args);
    va_end(args);

    int file = open(file_name, O_WRONLY);
    ASSERT(file != -1);
    ASSERT(write(file, string, (size_t) len) == len);
    close(file);
}


static void format_gpio_name(
    char *filename, size_t length, int gpio, const char *suffix)
{
    size_t offset =
        (size_t) snprintf(filename, length, "/sys/class/gpio/gpio%d", gpio);
    ASSERT(offset < length);
    if (suffix)
        snprintf(filename + offset, length - offset, "/%s", suffix);
}


/* Configures given GPIO for input or output and opens it for access. */
static void configure_gpio(
    struct gpio_info *info, const char *direction,
    char *filename, size_t length)
{
    format_gpio_name(filename, length, info->gpio, NULL);
    if (access(filename, F_OK) == 0)
        write_to_file("/sys/class/gpio/unexport", "%d", info->gpio);
    write_to_file("/sys/class/gpio/export", "%d", info->gpio);

    format_gpio_name(filename, length, info->gpio, "direction");
    write_to_file(filename, direction);

    /* Format path to value field. */
    format_gpio_name(filename, length, info->gpio, "value");
}


static void configure_gpio_out(int gpio, bool value)
{
    struct gpio_info *info = &gpio_info[gpio];
    char filename[64];
    configure_gpio(info, "out", filename, sizeof(filename));
    info->file = open(filename, O_WRONLY);
    ASSERT(info->file != -1);

    write_gpio_value(gpio, value);
}


static void configure_gpio_in(int gpio)
{
    struct gpio_info *info = &gpio_info[gpio];
    char filename[64];
    configure_gpio(info, "in", filename, sizeof(filename));
    info->path = strdup(filename);
}


/* Releases GPIO configuration. */
static void unconfigure_gpio(int gpio)
{
    struct gpio_info *info = &gpio_info[gpio];
    if (!info->path)
        close(info->file);
    write_to_file("/sys/class/gpio/unexport", "%d", info->gpio);
}


/*
 Following GPIOs are used to interface to FPGA for programming.
    CCLK  ( output, initialise 0 )
    D0    ( output, initialise 0 )
    PROGB ( output, initialise 1 )
    DONE  ( input  )
    INIT  ( input  )
*/
static void init_GPIOs(void)
{
    configure_gpio_out(GPIO_M0,    1);
    configure_gpio_out(GPIO_CCLK,  0);
    configure_gpio_out(GPIO_D0,    0);
    configure_gpio_out(GPIO_PROGB, 1);
    configure_gpio_in(GPIO_DONE);
    configure_gpio_in(GPIO_INIT);
}

static void close_gpios(void)
{
    unconfigure_gpio(GPIO_CCLK);
    unconfigure_gpio(GPIO_D0);
    unconfigure_gpio(GPIO_PROGB);
    unconfigure_gpio(GPIO_DONE);
    unconfigure_gpio(GPIO_INIT);
    unconfigure_gpio(GPIO_M0);
}


// Generate a cclk signal
static void cclk(void)
{
    write_gpio(GPIO_CCLK, 1);
    write_gpio(GPIO_CCLK, 0);
}


/* We expect at least one of GPIO_DONE and GPIO_INIT to be high. */
static bool check_status_ok(void)
{
    return read_gpio(GPIO_DONE)  ||  read_gpio(GPIO_INIT);
}


// This function takes a 8-bit configuration byte, and
// serializes it, MSB first, LSB Last
static void shift_byte_out(unsigned char data)
{
    for (int bit = 0; bit < 8; bit ++)
    {
        write_gpio(GPIO_D0, (data >> bit) & 1);
        cclk();
    }
}


/* Performs the actual FPGA programming work.  Returns false on failure. */
static bool program_FPGA(void)
{
    /* STEP-1: De-assert PROG_B */
    usleep(1000);
    write_gpio(GPIO_PROGB, 0);
    usleep(1000);

    /* STEP-2: Wait for INIT to go LOW */
    if (read_gpio(GPIO_INIT))
    {
        fprintf(stderr, "INIT_B signal is not LOW.\n");
        return false;
    }

    /* STEP-3: Assert PROG_B */
    write_gpio(GPIO_PROGB, 1);

    /* STEP-4: Wait for INIT to go HIGH */
    int init_count = 0;
    while (!read_gpio(GPIO_INIT))
    {
        if (init_count++ > 10000)
        {
            fprintf(stderr, "INIT_B signal is not HIGH\n");
            return false;
        }
    }
    usleep(1000);

    /* STEP-5: Read firmware binary file */
    printf("Programming FPGA...\n");
    int len;
    unsigned char StreamData[4096];
    int block = 0;
    while (
        len = read(STDIN_FILENO, StreamData, sizeof(StreamData)),
        len > 0)
    {
        if (!check_status_ok())
        {
            printf("DONE and INIT_B both low during programming!\n");
            printf("Error in block %d\n", block);
            return false;
        }

        printf(".");  fflush(stdout);
        block += 1;
        for (int j=0; j < len; j++)
            shift_byte_out(StreamData[j]);
    }
    printf("\n");

    /* STEP-6: Wait for DONE to be asserted */
    printf("Waiting for DONE to go HIGH...\n");
    int done_count = 0;
    while (!read_gpio(GPIO_DONE))
    {
        if (done_count++ > 1000)
        {
            fprintf(stderr, "DONE signal is not HIGH\n");
            return false;
        }
        cclk();
    }

    /* STEP-7 : Apply 8 additioanl CCLKs after DONE asserted to ensure
     * completion of FPGA start-up sequence.  */
    printf("Programming complete...\n");
    return true;
}


int main(int argc, char **argv)
{
    printf("Initialising GPIOs...\n");
    init_GPIOs();

    bool ok = program_FPGA();

    close_gpios();

    return ok ? 0 : 1;
}
