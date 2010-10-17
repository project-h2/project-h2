#define F_CPU 20000000UL

#include <avr/io.h>
#include <util/delay.h>
 

int main (void)
{
    unsigned char counter;
    unsigned char sixbit;
    /* set PORTB for output*/
    DDRB = 0xFF;

    PORTB = 0x00;
    while (1)
    {
        for(sixbit=0; sixbit<256; sixbit++) {
            PORTB = sixbit;

            /* wait (10 * 120000) cycles = wait 1200000 cycles */
            counter = 0;
            while (counter != 50)
            {
                /* wait (30000 x 4) cycles = wait 120000 cycles */
                _delay_loop_2(30000);
                counter++;
            }
        }
    }

    return 1;
}
