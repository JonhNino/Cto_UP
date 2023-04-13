#include "board.h"
#include "7seg.h"

void outp(unsigned int addr, char data)
// Output byte to port
 { __asm
    { mov dx, addr
      mov al, data
      out dx, al
    }
 }

char inp(unsigned int addr)
// Input byte from port
 { char result;
   __asm
    { mov dx, addr
      in al, dx
      mov result, al
    }
   return result;
 }

void set_int(unsigned char int_no, void * service_proc)
 { _asm
    { push es
      xor ax, ax
      mov es, ax
      mov al, int_no
      xor ah, ah
      shl ax, 1
      shl ax, 1
      mov si, ax
      mov ax, service_proc
      mov es:[si], ax
      inc si
      inc si
      mov bx, cs
      mov es:[si], bx
      pop es
    }
 }

/* USART */

unsigned char putch_buffer[256];
unsigned char putch_out_pos;
unsigned char putch_pos;

void putch_out(void)
// Output one symbol from buffer to 8251A USART
 { if (putch_out_pos == putch_pos)
      return;
   if((inp(ADR_USART_STAT) & 0x01) == 0)
      return;
   outp(ADR_USART_DATA, putch_buffer[putch_out_pos]);
   putch_out_pos++;
 }

unsigned char putch( unsigned char c )
// Put one symbol into buffer
 { putch_buffer[putch_pos] = c;
   putch_pos++;
   return c;
 }

void prints(char* s)
// Print string using putch() function
 { char c;
   while(s && *s)
    { c = *s;
      if (c == '\r')
         c = '\n';
      putch(c);
      s++;
    }
 }

void printui(unsigned int i)
// Print unsigned int using putch() function
 { unsigned char val;
   unsigned int temp = 10000;
   unsigned char printed=0;
   while (temp >= 1)
    { val = (i / temp) % 10;
      if ((val!=0) || printed || (temp == 1))
       { putch(val + '0');
         printed = 1;
       }
      if (temp == 1)
         break;
      temp /= 10;
    }
 }

void setup_usart(void)
// 8251 USART Setup
 { /* setup USART */
   outp(ADR_USART_CMD, 0x7D); /* ED */
   outp(ADR_USART_CMD, 0x07); /* RxEn, TxEn, DTRa */

   putch_out_pos = 0;
   putch_pos = 0;
 }

/* Timer */

signed char delay;

int sound_enabled;
int display_enabled;

void sound_nmi(void)
 { delay++;
   if (delay >= 10)
      delay = -delay;   
   outp(ADR_TIMER_CONTROL, TIMER_COUNTER2 | TIMER_MODE2 | TIMER_LSB);
   outp(ADR_TIMER_DATA2, ABS(delay)+0x40);
 }

void _interrupt _far nmi_handler(void);

void setup_nmi(void)
// Set NMI Timer at 50Hz.
 { set_int(0x02, (void *)&nmi_handler);

   outp(ADR_TIMER_CONTROL, TIMER_COUNTER1 | TIMER_MODE2 | TIMER_LSB_MSB);
   outp(ADR_TIMER_DATA1, 0xD0);	
   outp(ADR_TIMER_DATA1, 0x07);	
 }

/* PIO */

// Value to be displayed
unsigned int display_value;

// Current display position
unsigned char cur_display_pos;
// Current dispaly segments
unsigned char cur_display_segs;

unsigned char keys[16];

#define KEY_7	0
#define KEY_8	1
#define KEY_9	2
#define KEY_DIV	3
#define KEY_4	4
#define KEY_5	5
#define KEY_6	6
#define KEY_MUL	7
#define KEY_1	8
#define KEY_2	9
#define KEY_3	10
#define KEY_MIN	11
#define KEY_C	12
#define KEY_0	13
#define KEY_EQ	14
#define KEY_PLU	15

#define KEYBUFFERLEN 16

unsigned char keybuffer[KEYBUFFERLEN];
unsigned char keypos=0;

void process_key(unsigned char keycode)
 { if (keypos < KEYBUFFERLEN)
    { keybuffer[keypos] = keycode;
      keypos++;
    }
 }

#define NUM_LED_DIGITS 4

unsigned char disp_buffer[4] = {LED_INIT_VAL, LED_INIT_VAL, LED_INIT_VAL, LED_INIT_VAL};

void display_nmi(void)
// Display And Keyboard Handler
 { unsigned int i;
   unsigned int cur_key;
   unsigned int keys_inp;
   unsigned int out_value;

   // Light Off All Digits
   outp(ADR_PPI_PORTA, 0xFF);
   // Output Segments Value
   outp(ADR_PPI_PORTB, cur_display_segs);
   // Light On Current Digit
   outp(ADR_PPI_PORTA, 0xFF & ~(1 << cur_display_pos));

   // Keyboard Input
   keys_inp = inp(ADR_PPI_PORTC);
   cur_key = (cur_display_pos * 4);
   for (i=0; i<4; i++)
    { if (keys_inp & (1 << i))
         keys[cur_key]=0;
      else
       { if (!keys[cur_key])
          { process_key(cur_key);
            keys[cur_key]=1;
          }
       }
      cur_key++;
    }

   // Shift To The Next Digit
   cur_display_pos++;
   if (cur_display_pos > 3)
    { cur_display_pos = 0;
    }
   // Set Next Digit Value
   cur_display_segs = disp_buffer[cur_display_pos];
 }

void init_pio(void)
/* 8255A PIO Demo */
 {  outp(ADR_PPI_CONTROL, PPI_PORTA_OUT | PPI_PORTB_OUT | PPI_PORTCL_INP | PPI_PORTCH_INP | PPI_MODE_BCL_0 | PPI_MODE_ACH_0 | PPI_ACTIVE);

    display_value = 0;
    cur_display_pos = 0;
    cur_display_segs = 0xFF;

    display_enabled = 1;
 }


/* NMI Interrupt Handler */

void _interrupt _far nmi_handler(void)
 { if (sound_enabled)
      sound_nmi();
   if (display_enabled)
      display_nmi();
   putch_out();
 }

/* Support functions */

void initialise(void)
 { sound_enabled = 0;
   display_enabled = 0;
   cur_display_segs = LED_INIT_VAL;
   setup_nmi();
   setup_usart();
   init_pio();
 }

char input ()
 { if (keypos > 0)
    { unsigned char head_key = keybuffer[0];
      keypos--;
      for (unsigned char i=0; i<keypos; i++)
         keybuffer[i] = keybuffer[i+1];
      switch (head_key)
       { case KEY_0:
            return '0';
         case KEY_1:
            return '1';
         case KEY_2:
            return '2';
         case KEY_3:
            return '3';
         case KEY_4:
            return '4';
         case KEY_5:
            return '5';
         case KEY_6:
            return '6';
         case KEY_7:
            return '7';
         case KEY_8:
            return '8';
         case KEY_9:
            return '9';
         case KEY_PLU:
            return '+';
         case KEY_MIN:
            return '-';
         case KEY_MUL:
            return '*';
         case KEY_DIV:
            return '/';
         case KEY_EQ:
            return '=';
         case KEY_C:
            return 'C';
       }
    }
   return 0;
 }

char output(char ch)
 { putch(ch);
   if (ch >= '0' && ch <= '9')
    { for (char i=0; i<NUM_LED_DIGITS-1; i++)
         disp_buffer[i] = disp_buffer[i+1];
      disp_buffer[NUM_LED_DIGITS-1] = LED_ENCODE(ch - '0');
    }
   return ch;
 }

void clearscreen()
 { putch(13);
   for (char i=0; i<NUM_LED_DIGITS; i++)
      disp_buffer[i] = LED_INIT_VAL;
 }
