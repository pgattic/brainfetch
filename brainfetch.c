#include <stdio.h>
#include <stdlib.h>

/*

		BRAINFETCH
			A BrainF*** interpreter/debugger written in standard C
			By Preston Corless (pgattic)

		Usage:
			brainfetch [FILE].bf [-d]

		Notes:
		  - For security purposes, this interpreter has static Pogram and Work
			memory allocations, meaning it has a limit to both code size and
			memory access size.
			  - Change the "#define"s to accomodate larger programs or memory.
		  - Debug mode: enabled with "-d"
			  - Slower and less memory-efficient code execution, but provides
				more helpful error messages and breakpoints.
			  - When active, the asterisk (*) command works as a breakpoint,
				upon which a small memory dump is displayed and the program ends.

*/

#define PRGMEM 50000	// Amount of bytes to reserve for program code buffer (code filesize limit for debug mode, else instruction count limit)
#define WORKMEM 30000	// Amount of bytes to reserve for work ram

void printHelp(char* arg) {
	printf("Usage:\n  %s [FILE].bf [OPTIONS]\n", arg);
	printf("Options:\n  -d	debug mode\n");
}

int loadCode(FILE* f, char* dest, char debugMode) {
	char ch;
	int head = 0;
	do {				// transfer file data to the prg array (copy all characters in debug mode, else copy only command characters)
		ch = fgetc(f);
		if (debugMode || (ch == '>' || ch == '<' || ch == '+' || ch == '-' || ch == '.' || ch == ',' || ch == '[' || ch == ']')) {
			dest[head] = ch;
			head++;
			if (head >= PRGMEM) {
				fprintf(stderr, "\nERROR: Out of Program Memory. Program file too large.\nSee \"Notes\" in brainfetch.c.\n");
				return -1;
			}
		}
	} while (ch != EOF);
	return head;		// return size (index of the last write) of file buffer
}

void printLinePosition(char* code, int pos) {
	int li = 1;
	int ch = 1;
	for (int i = 0; i < pos; i++) {
		if (code[i] == '\n') {
			li++;
			ch = 1;
		}
		ch++;
	}
	printf("Line %d:%d\n", li, ch);
}

int testCode(char* prg, int size) {	// test code for issues with brackets (quicker and safer to do before run time)
	int bracketBalance = 0;
	for (int i = 0; i < size; i++) {
		if (prg[i] == '[') { bracketBalance++; }
		if (prg[i] == ']') { bracketBalance--; }
		if (bracketBalance < 0) {
			fprintf(stderr, "\nERROR: Unopened \"]\" (\"[\" expected)\n");
			printLinePosition(prg, i);
			return 0;
		}
	}
	if (bracketBalance) {
		fprintf(stderr, "\nERROR: Unclosed \"[\" (\"]\" expected)\n");
	}
	return !bracketBalance;
}

void memDump(char* prg, char* mem, int head, int ptr) {	// Simple memory dump
	printLinePosition(prg, head);
	printf("Memory relative to memory I/O head (in brackets):\n");
	for (int i = ptr - 16; i < ptr + 17; i++) {
		if (i < 0 || i >= WORKMEM) {
			printf("- ");
		} else if (i == ptr) {
			printf("[%d] ", mem[i]);
		} else {
			printf("%d ", mem[i]);
		}
	}
	printf("\nMemory I/O head address: %d\n", ptr);
}

int main(int argc, char** argv) {

	if (argc < 2) {				// end program if no file specified
		printHelp(argv[0]);
		return 1;
	}

	FILE* f = fopen(argv[1], "r");	// open the file specified as an argument into the program

	if (!f) {					// end program if file not found
		fprintf(stderr,"%s: no such file\n\n", argv[1]);
		printHelp(argv[0]);
		return 1;
	}

	char debugMode = argv[2] ? (argv[2][0] == '-' && argv[2][1] == 'd' && argv[2][2] == 0) : 0;	// curses, C string comparison!

	char prg[PRGMEM];		// array that the bf code is temporarily stored in (for easy access by interpreter)
	int head = 0;			// index of prg that instructions are being read from
	int fileSize = loadCode(f, prg, debugMode); // fileSize is actually the index of the last byte, or the file's size minus one.

	if (fileSize < 0 || !testCode(prg, fileSize)) {	// run tests, exit program if failed
		return 1;
	}

	char mem[WORKMEM] = {0};	// Brainfetch "memory"
	int ptr = 0;				// Brainfetch "read head" (the pointer to the location in mem being accessed)
	while (head < fileSize) {	// Main interpretation loop. Each character/command is interpreted one at a time.
		switch (prg[head]) {
			case '>': ptr++; break;
			case '<': ptr--; break;
			case '+': mem[ptr]++; break;
			case '-': mem[ptr]--; break;
			case '.':
				putchar(mem[ptr]);
				break;
			case ',':
				mem[ptr] = getchar();
				break;
			case '[':
				if (mem[ptr] == 0) {
					int bracketBalance = 1;		// positive: outstanding open brackets; zero: all opened brackets are accounted for
					do {
						head++;
						if (prg[head] == '[') { bracketBalance++; }
						if (prg[head] == ']') { bracketBalance--; }
					} while (bracketBalance > 0);
				}
				break;
			case ']':
				int bracketBalance = 0;			// positive: outstanding open brackets; negative: outstanding close brackets
				do {
					head--;
					if (prg[head] == '[') { bracketBalance++; }
					if (prg[head] == ']') { bracketBalance--; }
				} while (bracketBalance <= 0);
				head--;
				break;
			case '*':	// No need to check for debugMode; without debugMode the asterisk character would never have been put in PRGMEM to begin with
				printf("\nINFO: Breakpoint hit - ");
				memDump(prg, mem, head, ptr);
				return 0;
				break;
		}
		if (ptr < 0) {
			fprintf(stderr, "\nERROR: Pointer underflow (Memory pointer < 0)\n");
			printLinePosition(mem, head);
			memDump(prg, mem, head, ptr);
			return 1;
		} else if (ptr >= WORKMEM) {
			fprintf(stderr, "\nERROR: Out of Work Memory.\nSee \"Notes\" in brainfetch.c.\n");
			return 1;
		}
		head++;
	}
	return 0;
}
