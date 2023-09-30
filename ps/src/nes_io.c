#include "nes_io.h"
#include "xil_printf.h"

int get_user_selection(int max)
{
	char buf[10];
	int n;
	int sel;
	while(1)
	{
		n = get_user_input(buf, 10);
		if(n > 0 && n < 10) {
			sel = str_to_unsigned(buf);
			if (sel>0 && sel<max) return sel;
		}
		xil_printf("Please enter a valid file number 1-%d\r\n", max);
	}

}

int str_to_unsigned(const char* str){
	int n=0;

	//find end of string and validate digits
	while(1) {
		if (str[n+1] == 0) break;
		n++;
		if (str[n] < '0' || str[n] > '9') return -1;
	}

	int val=0;
	int place=1;
	while(n >= 0){
		val += place * (str[n--] - '0');
		place *= 10;
	}
	return val;
}


int get_user_input(char* input, int maxlen)
{
	char userInput;
	int l=0;

	while(1){
		userInput = getchar();
		if (userInput == '\r' || userInput == '\n' || l==maxlen-1)
		{
			putchar('\r');
			putchar('\n');
			// xil_printf("\r\n"); //echo
			input[l] = 0;
			break;
		}
		putchar(userInput); //echo
		// xil_printf("%c", userInput); //echo
		input[l++] = userInput;
	}

	return l;
}

