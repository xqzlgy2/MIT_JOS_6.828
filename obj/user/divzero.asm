
obj/user/divzero:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 37 00 00 00       	call   800068 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
	...

00800034 <umain>:

int zero;

void
umain(int argc, char **argv)
{
  800034:	55                   	push   %ebp
  800035:	89 e5                	mov    %esp,%ebp
  800037:	83 ec 18             	sub    $0x18,%esp
	zero = 0;
  80003a:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800041:	00 00 00 
	cprintf("1/0 is %08x!\n", 1/zero);
  800044:	b8 01 00 00 00       	mov    $0x1,%eax
  800049:	b9 00 00 00 00       	mov    $0x0,%ecx
  80004e:	89 c2                	mov    %eax,%edx
  800050:	c1 fa 1f             	sar    $0x1f,%edx
  800053:	f7 f9                	idiv   %ecx
  800055:	89 44 24 04          	mov    %eax,0x4(%esp)
  800059:	c7 04 24 b8 0e 80 00 	movl   $0x800eb8,(%esp)
  800060:	e8 0e 01 00 00       	call   800173 <cprintf>
}
  800065:	c9                   	leave  
  800066:	c3                   	ret    
	...

00800068 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800068:	55                   	push   %ebp
  800069:	89 e5                	mov    %esp,%ebp
  80006b:	83 ec 18             	sub    $0x18,%esp
  80006e:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  800071:	89 75 fc             	mov    %esi,-0x4(%ebp)
  800074:	8b 75 08             	mov    0x8(%ebp),%esi
  800077:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = &envs[ENVX(sys_getenvid())];
  80007a:	e8 05 0b 00 00       	call   800b84 <sys_getenvid>
  80007f:	25 ff 03 00 00       	and    $0x3ff,%eax
  800084:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800087:	c1 e0 05             	shl    $0x5,%eax
  80008a:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80008f:	a3 08 20 80 00       	mov    %eax,0x802008

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800094:	85 f6                	test   %esi,%esi
  800096:	7e 07                	jle    80009f <libmain+0x37>
		binaryname = argv[0];
  800098:	8b 03                	mov    (%ebx),%eax
  80009a:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80009f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8000a3:	89 34 24             	mov    %esi,(%esp)
  8000a6:	e8 89 ff ff ff       	call   800034 <umain>

	// exit gracefully
	exit();
  8000ab:	e8 0c 00 00 00       	call   8000bc <exit>
}
  8000b0:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  8000b3:	8b 75 fc             	mov    -0x4(%ebp),%esi
  8000b6:	89 ec                	mov    %ebp,%esp
  8000b8:	5d                   	pop    %ebp
  8000b9:	c3                   	ret    
	...

008000bc <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000bc:	55                   	push   %ebp
  8000bd:	89 e5                	mov    %esp,%ebp
  8000bf:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8000c2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000c9:	e8 59 0a 00 00       	call   800b27 <sys_env_destroy>
}
  8000ce:	c9                   	leave  
  8000cf:	c3                   	ret    

008000d0 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000d0:	55                   	push   %ebp
  8000d1:	89 e5                	mov    %esp,%ebp
  8000d3:	53                   	push   %ebx
  8000d4:	83 ec 14             	sub    $0x14,%esp
  8000d7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000da:	8b 03                	mov    (%ebx),%eax
  8000dc:	8b 55 08             	mov    0x8(%ebp),%edx
  8000df:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  8000e3:	83 c0 01             	add    $0x1,%eax
  8000e6:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  8000e8:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000ed:	75 19                	jne    800108 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8000ef:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8000f6:	00 
  8000f7:	8d 43 08             	lea    0x8(%ebx),%eax
  8000fa:	89 04 24             	mov    %eax,(%esp)
  8000fd:	e8 c6 09 00 00       	call   800ac8 <sys_cputs>
		b->idx = 0;
  800102:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800108:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  80010c:	83 c4 14             	add    $0x14,%esp
  80010f:	5b                   	pop    %ebx
  800110:	5d                   	pop    %ebp
  800111:	c3                   	ret    

00800112 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800112:	55                   	push   %ebp
  800113:	89 e5                	mov    %esp,%ebp
  800115:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  80011b:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800122:	00 00 00 
	b.cnt = 0;
  800125:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80012c:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80012f:	8b 45 0c             	mov    0xc(%ebp),%eax
  800132:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800136:	8b 45 08             	mov    0x8(%ebp),%eax
  800139:	89 44 24 08          	mov    %eax,0x8(%esp)
  80013d:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800143:	89 44 24 04          	mov    %eax,0x4(%esp)
  800147:	c7 04 24 d0 00 80 00 	movl   $0x8000d0,(%esp)
  80014e:	e8 8a 01 00 00       	call   8002dd <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800153:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800159:	89 44 24 04          	mov    %eax,0x4(%esp)
  80015d:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800163:	89 04 24             	mov    %eax,(%esp)
  800166:	e8 5d 09 00 00       	call   800ac8 <sys_cputs>

	return b.cnt;
}
  80016b:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800171:	c9                   	leave  
  800172:	c3                   	ret    

00800173 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800173:	55                   	push   %ebp
  800174:	89 e5                	mov    %esp,%ebp
  800176:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800179:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80017c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800180:	8b 45 08             	mov    0x8(%ebp),%eax
  800183:	89 04 24             	mov    %eax,(%esp)
  800186:	e8 87 ff ff ff       	call   800112 <vcprintf>
	va_end(ap);

	return cnt;
}
  80018b:	c9                   	leave  
  80018c:	c3                   	ret    
  80018d:	00 00                	add    %al,(%eax)
	...

00800190 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800190:	55                   	push   %ebp
  800191:	89 e5                	mov    %esp,%ebp
  800193:	57                   	push   %edi
  800194:	56                   	push   %esi
  800195:	53                   	push   %ebx
  800196:	83 ec 3c             	sub    $0x3c,%esp
  800199:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80019c:	89 d7                	mov    %edx,%edi
  80019e:	8b 45 08             	mov    0x8(%ebp),%eax
  8001a1:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8001a4:	8b 45 0c             	mov    0xc(%ebp),%eax
  8001a7:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8001aa:	8b 5d 14             	mov    0x14(%ebp),%ebx
  8001ad:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8001b0:	85 c0                	test   %eax,%eax
  8001b2:	75 08                	jne    8001bc <printnum+0x2c>
  8001b4:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8001b7:	39 45 10             	cmp    %eax,0x10(%ebp)
  8001ba:	77 59                	ja     800215 <printnum+0x85>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8001bc:	89 74 24 10          	mov    %esi,0x10(%esp)
  8001c0:	83 eb 01             	sub    $0x1,%ebx
  8001c3:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  8001c7:	8b 45 10             	mov    0x10(%ebp),%eax
  8001ca:	89 44 24 08          	mov    %eax,0x8(%esp)
  8001ce:	8b 5c 24 08          	mov    0x8(%esp),%ebx
  8001d2:	8b 74 24 0c          	mov    0xc(%esp),%esi
  8001d6:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8001dd:	00 
  8001de:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8001e1:	89 04 24             	mov    %eax,(%esp)
  8001e4:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8001e7:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001eb:	e8 20 0a 00 00       	call   800c10 <__udivdi3>
  8001f0:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8001f4:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8001f8:	89 04 24             	mov    %eax,(%esp)
  8001fb:	89 54 24 04          	mov    %edx,0x4(%esp)
  8001ff:	89 fa                	mov    %edi,%edx
  800201:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800204:	e8 87 ff ff ff       	call   800190 <printnum>
  800209:	eb 11                	jmp    80021c <printnum+0x8c>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80020b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80020f:	89 34 24             	mov    %esi,(%esp)
  800212:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800215:	83 eb 01             	sub    $0x1,%ebx
  800218:	85 db                	test   %ebx,%ebx
  80021a:	7f ef                	jg     80020b <printnum+0x7b>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80021c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800220:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800224:	8b 45 10             	mov    0x10(%ebp),%eax
  800227:	89 44 24 08          	mov    %eax,0x8(%esp)
  80022b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800232:	00 
  800233:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800236:	89 04 24             	mov    %eax,(%esp)
  800239:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80023c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800240:	e8 fb 0a 00 00       	call   800d40 <__umoddi3>
  800245:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800249:	0f be 80 d0 0e 80 00 	movsbl 0x800ed0(%eax),%eax
  800250:	89 04 24             	mov    %eax,(%esp)
  800253:	ff 55 e4             	call   *-0x1c(%ebp)
}
  800256:	83 c4 3c             	add    $0x3c,%esp
  800259:	5b                   	pop    %ebx
  80025a:	5e                   	pop    %esi
  80025b:	5f                   	pop    %edi
  80025c:	5d                   	pop    %ebp
  80025d:	c3                   	ret    

0080025e <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80025e:	55                   	push   %ebp
  80025f:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800261:	83 fa 01             	cmp    $0x1,%edx
  800264:	7e 0e                	jle    800274 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800266:	8b 10                	mov    (%eax),%edx
  800268:	8d 4a 08             	lea    0x8(%edx),%ecx
  80026b:	89 08                	mov    %ecx,(%eax)
  80026d:	8b 02                	mov    (%edx),%eax
  80026f:	8b 52 04             	mov    0x4(%edx),%edx
  800272:	eb 22                	jmp    800296 <getuint+0x38>
	else if (lflag)
  800274:	85 d2                	test   %edx,%edx
  800276:	74 10                	je     800288 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800278:	8b 10                	mov    (%eax),%edx
  80027a:	8d 4a 04             	lea    0x4(%edx),%ecx
  80027d:	89 08                	mov    %ecx,(%eax)
  80027f:	8b 02                	mov    (%edx),%eax
  800281:	ba 00 00 00 00       	mov    $0x0,%edx
  800286:	eb 0e                	jmp    800296 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800288:	8b 10                	mov    (%eax),%edx
  80028a:	8d 4a 04             	lea    0x4(%edx),%ecx
  80028d:	89 08                	mov    %ecx,(%eax)
  80028f:	8b 02                	mov    (%edx),%eax
  800291:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800296:	5d                   	pop    %ebp
  800297:	c3                   	ret    

00800298 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800298:	55                   	push   %ebp
  800299:	89 e5                	mov    %esp,%ebp
  80029b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80029e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002a2:	8b 10                	mov    (%eax),%edx
  8002a4:	3b 50 04             	cmp    0x4(%eax),%edx
  8002a7:	73 0a                	jae    8002b3 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002a9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8002ac:	88 0a                	mov    %cl,(%edx)
  8002ae:	83 c2 01             	add    $0x1,%edx
  8002b1:	89 10                	mov    %edx,(%eax)
}
  8002b3:	5d                   	pop    %ebp
  8002b4:	c3                   	ret    

008002b5 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002b5:	55                   	push   %ebp
  8002b6:	89 e5                	mov    %esp,%ebp
  8002b8:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8002bb:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002be:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002c2:	8b 45 10             	mov    0x10(%ebp),%eax
  8002c5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002c9:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002cc:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002d0:	8b 45 08             	mov    0x8(%ebp),%eax
  8002d3:	89 04 24             	mov    %eax,(%esp)
  8002d6:	e8 02 00 00 00       	call   8002dd <vprintfmt>
	va_end(ap);
}
  8002db:	c9                   	leave  
  8002dc:	c3                   	ret    

008002dd <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002dd:	55                   	push   %ebp
  8002de:	89 e5                	mov    %esp,%ebp
  8002e0:	57                   	push   %edi
  8002e1:	56                   	push   %esi
  8002e2:	53                   	push   %ebx
  8002e3:	83 ec 4c             	sub    $0x4c,%esp
  8002e6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002e9:	8b 75 10             	mov    0x10(%ebp),%esi
  8002ec:	eb 12                	jmp    800300 <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8002ee:	85 c0                	test   %eax,%eax
  8002f0:	0f 84 9f 03 00 00    	je     800695 <vprintfmt+0x3b8>
				return;
			putch(ch, putdat);
  8002f6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8002fa:	89 04 24             	mov    %eax,(%esp)
  8002fd:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800300:	0f b6 06             	movzbl (%esi),%eax
  800303:	83 c6 01             	add    $0x1,%esi
  800306:	83 f8 25             	cmp    $0x25,%eax
  800309:	75 e3                	jne    8002ee <vprintfmt+0x11>
  80030b:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  80030f:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  800316:	bf ff ff ff ff       	mov    $0xffffffff,%edi
  80031b:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
  800322:	b9 00 00 00 00       	mov    $0x0,%ecx
  800327:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80032a:	eb 2b                	jmp    800357 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80032c:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  80032f:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  800333:	eb 22                	jmp    800357 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800335:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800338:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  80033c:	eb 19                	jmp    800357 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80033e:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  800341:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  800348:	eb 0d                	jmp    800357 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  80034a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80034d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800350:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800357:	0f b6 16             	movzbl (%esi),%edx
  80035a:	0f b6 c2             	movzbl %dl,%eax
  80035d:	8d 7e 01             	lea    0x1(%esi),%edi
  800360:	89 7d e0             	mov    %edi,-0x20(%ebp)
  800363:	83 ea 23             	sub    $0x23,%edx
  800366:	80 fa 55             	cmp    $0x55,%dl
  800369:	0f 87 08 03 00 00    	ja     800677 <vprintfmt+0x39a>
  80036f:	0f b6 d2             	movzbl %dl,%edx
  800372:	ff 24 95 60 0f 80 00 	jmp    *0x800f60(,%edx,4)
  800379:	8b 75 e0             	mov    -0x20(%ebp),%esi
  80037c:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
  800383:	bf 00 00 00 00       	mov    $0x0,%edi
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800388:	8d 14 bf             	lea    (%edi,%edi,4),%edx
  80038b:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
  80038f:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  800392:	8d 50 d0             	lea    -0x30(%eax),%edx
  800395:	83 fa 09             	cmp    $0x9,%edx
  800398:	77 2f                	ja     8003c9 <vprintfmt+0xec>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  80039a:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  80039d:	eb e9                	jmp    800388 <vprintfmt+0xab>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  80039f:	8b 45 14             	mov    0x14(%ebp),%eax
  8003a2:	8d 50 04             	lea    0x4(%eax),%edx
  8003a5:	89 55 14             	mov    %edx,0x14(%ebp)
  8003a8:	8b 00                	mov    (%eax),%eax
  8003aa:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ad:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003b0:	eb 1a                	jmp    8003cc <vprintfmt+0xef>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003b2:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
  8003b5:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8003b9:	79 9c                	jns    800357 <vprintfmt+0x7a>
  8003bb:	eb 81                	jmp    80033e <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003bd:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003c0:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
  8003c7:	eb 8e                	jmp    800357 <vprintfmt+0x7a>
  8003c9:	89 7d d4             	mov    %edi,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  8003cc:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8003d0:	79 85                	jns    800357 <vprintfmt+0x7a>
  8003d2:	e9 73 ff ff ff       	jmp    80034a <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8003d7:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003da:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003dd:	e9 75 ff ff ff       	jmp    800357 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8003e2:	8b 45 14             	mov    0x14(%ebp),%eax
  8003e5:	8d 50 04             	lea    0x4(%eax),%edx
  8003e8:	89 55 14             	mov    %edx,0x14(%ebp)
  8003eb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8003ef:	8b 00                	mov    (%eax),%eax
  8003f1:	89 04 24             	mov    %eax,(%esp)
  8003f4:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f7:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8003fa:	e9 01 ff ff ff       	jmp    800300 <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003ff:	8b 45 14             	mov    0x14(%ebp),%eax
  800402:	8d 50 04             	lea    0x4(%eax),%edx
  800405:	89 55 14             	mov    %edx,0x14(%ebp)
  800408:	8b 00                	mov    (%eax),%eax
  80040a:	89 c2                	mov    %eax,%edx
  80040c:	c1 fa 1f             	sar    $0x1f,%edx
  80040f:	31 d0                	xor    %edx,%eax
  800411:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800413:	83 f8 06             	cmp    $0x6,%eax
  800416:	7f 0b                	jg     800423 <vprintfmt+0x146>
  800418:	8b 14 85 b8 10 80 00 	mov    0x8010b8(,%eax,4),%edx
  80041f:	85 d2                	test   %edx,%edx
  800421:	75 23                	jne    800446 <vprintfmt+0x169>
				printfmt(putch, putdat, "error %d", err);
  800423:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800427:	c7 44 24 08 e8 0e 80 	movl   $0x800ee8,0x8(%esp)
  80042e:	00 
  80042f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800433:	8b 7d 08             	mov    0x8(%ebp),%edi
  800436:	89 3c 24             	mov    %edi,(%esp)
  800439:	e8 77 fe ff ff       	call   8002b5 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80043e:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800441:	e9 ba fe ff ff       	jmp    800300 <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
  800446:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80044a:	c7 44 24 08 f1 0e 80 	movl   $0x800ef1,0x8(%esp)
  800451:	00 
  800452:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800456:	8b 7d 08             	mov    0x8(%ebp),%edi
  800459:	89 3c 24             	mov    %edi,(%esp)
  80045c:	e8 54 fe ff ff       	call   8002b5 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800461:	8b 75 e0             	mov    -0x20(%ebp),%esi
  800464:	e9 97 fe ff ff       	jmp    800300 <vprintfmt+0x23>
  800469:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80046c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80046f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800472:	8b 45 14             	mov    0x14(%ebp),%eax
  800475:	8d 50 04             	lea    0x4(%eax),%edx
  800478:	89 55 14             	mov    %edx,0x14(%ebp)
  80047b:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  80047d:	85 f6                	test   %esi,%esi
  80047f:	ba e1 0e 80 00       	mov    $0x800ee1,%edx
  800484:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
  800487:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  80048b:	0f 8e 8c 00 00 00    	jle    80051d <vprintfmt+0x240>
  800491:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  800495:	0f 84 82 00 00 00    	je     80051d <vprintfmt+0x240>
				for (width -= strnlen(p, precision); width > 0; width--)
  80049b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80049f:	89 34 24             	mov    %esi,(%esp)
  8004a2:	e8 91 02 00 00       	call   800738 <strnlen>
  8004a7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  8004aa:	29 c2                	sub    %eax,%edx
  8004ac:	89 55 e4             	mov    %edx,-0x1c(%ebp)
					putch(padc, putdat);
  8004af:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  8004b3:	89 75 d0             	mov    %esi,-0x30(%ebp)
  8004b6:	89 7d cc             	mov    %edi,-0x34(%ebp)
  8004b9:	89 de                	mov    %ebx,%esi
  8004bb:	89 d3                	mov    %edx,%ebx
  8004bd:	89 c7                	mov    %eax,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004bf:	eb 0d                	jmp    8004ce <vprintfmt+0x1f1>
					putch(padc, putdat);
  8004c1:	89 74 24 04          	mov    %esi,0x4(%esp)
  8004c5:	89 3c 24             	mov    %edi,(%esp)
  8004c8:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004cb:	83 eb 01             	sub    $0x1,%ebx
  8004ce:	85 db                	test   %ebx,%ebx
  8004d0:	7f ef                	jg     8004c1 <vprintfmt+0x1e4>
  8004d2:	8b 7d cc             	mov    -0x34(%ebp),%edi
  8004d5:	89 f3                	mov    %esi,%ebx
  8004d7:	8b 75 d0             	mov    -0x30(%ebp),%esi

// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
  8004da:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8004de:	b8 00 00 00 00       	mov    $0x0,%eax
  8004e3:	0f 49 45 e4          	cmovns -0x1c(%ebp),%eax
  8004e7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8004ea:	29 c2                	sub    %eax,%edx
  8004ec:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8004ef:	eb 2c                	jmp    80051d <vprintfmt+0x240>
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004f1:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8004f5:	74 18                	je     80050f <vprintfmt+0x232>
  8004f7:	8d 50 e0             	lea    -0x20(%eax),%edx
  8004fa:	83 fa 5e             	cmp    $0x5e,%edx
  8004fd:	76 10                	jbe    80050f <vprintfmt+0x232>
					putch('?', putdat);
  8004ff:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800503:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  80050a:	ff 55 08             	call   *0x8(%ebp)
  80050d:	eb 0a                	jmp    800519 <vprintfmt+0x23c>
				else
					putch(ch, putdat);
  80050f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800513:	89 04 24             	mov    %eax,(%esp)
  800516:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800519:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
  80051d:	0f be 06             	movsbl (%esi),%eax
  800520:	83 c6 01             	add    $0x1,%esi
  800523:	85 c0                	test   %eax,%eax
  800525:	74 25                	je     80054c <vprintfmt+0x26f>
  800527:	85 ff                	test   %edi,%edi
  800529:	78 c6                	js     8004f1 <vprintfmt+0x214>
  80052b:	83 ef 01             	sub    $0x1,%edi
  80052e:	79 c1                	jns    8004f1 <vprintfmt+0x214>
  800530:	8b 7d 08             	mov    0x8(%ebp),%edi
  800533:	89 de                	mov    %ebx,%esi
  800535:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800538:	eb 1a                	jmp    800554 <vprintfmt+0x277>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  80053a:	89 74 24 04          	mov    %esi,0x4(%esp)
  80053e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800545:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800547:	83 eb 01             	sub    $0x1,%ebx
  80054a:	eb 08                	jmp    800554 <vprintfmt+0x277>
  80054c:	8b 7d 08             	mov    0x8(%ebp),%edi
  80054f:	89 de                	mov    %ebx,%esi
  800551:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800554:	85 db                	test   %ebx,%ebx
  800556:	7f e2                	jg     80053a <vprintfmt+0x25d>
  800558:	89 7d 08             	mov    %edi,0x8(%ebp)
  80055b:	89 f3                	mov    %esi,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80055d:	8b 75 e0             	mov    -0x20(%ebp),%esi
  800560:	e9 9b fd ff ff       	jmp    800300 <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800565:	83 f9 01             	cmp    $0x1,%ecx
  800568:	7e 10                	jle    80057a <vprintfmt+0x29d>
		return va_arg(*ap, long long);
  80056a:	8b 45 14             	mov    0x14(%ebp),%eax
  80056d:	8d 50 08             	lea    0x8(%eax),%edx
  800570:	89 55 14             	mov    %edx,0x14(%ebp)
  800573:	8b 30                	mov    (%eax),%esi
  800575:	8b 78 04             	mov    0x4(%eax),%edi
  800578:	eb 26                	jmp    8005a0 <vprintfmt+0x2c3>
	else if (lflag)
  80057a:	85 c9                	test   %ecx,%ecx
  80057c:	74 12                	je     800590 <vprintfmt+0x2b3>
		return va_arg(*ap, long);
  80057e:	8b 45 14             	mov    0x14(%ebp),%eax
  800581:	8d 50 04             	lea    0x4(%eax),%edx
  800584:	89 55 14             	mov    %edx,0x14(%ebp)
  800587:	8b 30                	mov    (%eax),%esi
  800589:	89 f7                	mov    %esi,%edi
  80058b:	c1 ff 1f             	sar    $0x1f,%edi
  80058e:	eb 10                	jmp    8005a0 <vprintfmt+0x2c3>
	else
		return va_arg(*ap, int);
  800590:	8b 45 14             	mov    0x14(%ebp),%eax
  800593:	8d 50 04             	lea    0x4(%eax),%edx
  800596:	89 55 14             	mov    %edx,0x14(%ebp)
  800599:	8b 30                	mov    (%eax),%esi
  80059b:	89 f7                	mov    %esi,%edi
  80059d:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005a0:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005a5:	85 ff                	test   %edi,%edi
  8005a7:	0f 89 8c 00 00 00    	jns    800639 <vprintfmt+0x35c>
				putch('-', putdat);
  8005ad:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005b1:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8005b8:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  8005bb:	f7 de                	neg    %esi
  8005bd:	83 d7 00             	adc    $0x0,%edi
  8005c0:	f7 df                	neg    %edi
			}
			base = 10;
  8005c2:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005c7:	eb 70                	jmp    800639 <vprintfmt+0x35c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8005c9:	89 ca                	mov    %ecx,%edx
  8005cb:	8d 45 14             	lea    0x14(%ebp),%eax
  8005ce:	e8 8b fc ff ff       	call   80025e <getuint>
  8005d3:	89 c6                	mov    %eax,%esi
  8005d5:	89 d7                	mov    %edx,%edi
			base = 10;
  8005d7:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
  8005dc:	eb 5b                	jmp    800639 <vprintfmt+0x35c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num=getuint(&ap,lflag);
  8005de:	89 ca                	mov    %ecx,%edx
  8005e0:	8d 45 14             	lea    0x14(%ebp),%eax
  8005e3:	e8 76 fc ff ff       	call   80025e <getuint>
  8005e8:	89 c6                	mov    %eax,%esi
  8005ea:	89 d7                	mov    %edx,%edi
			base = 8;
  8005ec:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
  8005f1:	eb 46                	jmp    800639 <vprintfmt+0x35c>
	
		// pointer
		case 'p':
			putch('0', putdat);
  8005f3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005f7:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  8005fe:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800601:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800605:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80060c:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80060f:	8b 45 14             	mov    0x14(%ebp),%eax
  800612:	8d 50 04             	lea    0x4(%eax),%edx
  800615:	89 55 14             	mov    %edx,0x14(%ebp)
	
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800618:	8b 30                	mov    (%eax),%esi
  80061a:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80061f:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  800624:	eb 13                	jmp    800639 <vprintfmt+0x35c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800626:	89 ca                	mov    %ecx,%edx
  800628:	8d 45 14             	lea    0x14(%ebp),%eax
  80062b:	e8 2e fc ff ff       	call   80025e <getuint>
  800630:	89 c6                	mov    %eax,%esi
  800632:	89 d7                	mov    %edx,%edi
			base = 16;
  800634:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800639:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
  80063d:	89 54 24 10          	mov    %edx,0x10(%esp)
  800641:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800644:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800648:	89 44 24 08          	mov    %eax,0x8(%esp)
  80064c:	89 34 24             	mov    %esi,(%esp)
  80064f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800653:	89 da                	mov    %ebx,%edx
  800655:	8b 45 08             	mov    0x8(%ebp),%eax
  800658:	e8 33 fb ff ff       	call   800190 <printnum>
			break;
  80065d:	8b 75 e0             	mov    -0x20(%ebp),%esi
  800660:	e9 9b fc ff ff       	jmp    800300 <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800665:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800669:	89 04 24             	mov    %eax,(%esp)
  80066c:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80066f:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800672:	e9 89 fc ff ff       	jmp    800300 <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800677:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80067b:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800682:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  800685:	eb 03                	jmp    80068a <vprintfmt+0x3ad>
  800687:	83 ee 01             	sub    $0x1,%esi
  80068a:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
  80068e:	75 f7                	jne    800687 <vprintfmt+0x3aa>
  800690:	e9 6b fc ff ff       	jmp    800300 <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
  800695:	83 c4 4c             	add    $0x4c,%esp
  800698:	5b                   	pop    %ebx
  800699:	5e                   	pop    %esi
  80069a:	5f                   	pop    %edi
  80069b:	5d                   	pop    %ebp
  80069c:	c3                   	ret    

0080069d <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80069d:	55                   	push   %ebp
  80069e:	89 e5                	mov    %esp,%ebp
  8006a0:	83 ec 28             	sub    $0x28,%esp
  8006a3:	8b 45 08             	mov    0x8(%ebp),%eax
  8006a6:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006a9:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006ac:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006b0:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006b3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006ba:	85 c0                	test   %eax,%eax
  8006bc:	74 30                	je     8006ee <vsnprintf+0x51>
  8006be:	85 d2                	test   %edx,%edx
  8006c0:	7e 2c                	jle    8006ee <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006c2:	8b 45 14             	mov    0x14(%ebp),%eax
  8006c5:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8006c9:	8b 45 10             	mov    0x10(%ebp),%eax
  8006cc:	89 44 24 08          	mov    %eax,0x8(%esp)
  8006d0:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8006d3:	89 44 24 04          	mov    %eax,0x4(%esp)
  8006d7:	c7 04 24 98 02 80 00 	movl   $0x800298,(%esp)
  8006de:	e8 fa fb ff ff       	call   8002dd <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8006e3:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8006e6:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8006e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8006ec:	eb 05                	jmp    8006f3 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8006ee:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8006f3:	c9                   	leave  
  8006f4:	c3                   	ret    

008006f5 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8006f5:	55                   	push   %ebp
  8006f6:	89 e5                	mov    %esp,%ebp
  8006f8:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8006fb:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8006fe:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800702:	8b 45 10             	mov    0x10(%ebp),%eax
  800705:	89 44 24 08          	mov    %eax,0x8(%esp)
  800709:	8b 45 0c             	mov    0xc(%ebp),%eax
  80070c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800710:	8b 45 08             	mov    0x8(%ebp),%eax
  800713:	89 04 24             	mov    %eax,(%esp)
  800716:	e8 82 ff ff ff       	call   80069d <vsnprintf>
	va_end(ap);

	return rc;
}
  80071b:	c9                   	leave  
  80071c:	c3                   	ret    
  80071d:	00 00                	add    %al,(%eax)
	...

00800720 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800720:	55                   	push   %ebp
  800721:	89 e5                	mov    %esp,%ebp
  800723:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800726:	b8 00 00 00 00       	mov    $0x0,%eax
  80072b:	eb 03                	jmp    800730 <strlen+0x10>
		n++;
  80072d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800730:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800734:	75 f7                	jne    80072d <strlen+0xd>
		n++;
	return n;
}
  800736:	5d                   	pop    %ebp
  800737:	c3                   	ret    

00800738 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800738:	55                   	push   %ebp
  800739:	89 e5                	mov    %esp,%ebp
  80073b:	8b 4d 08             	mov    0x8(%ebp),%ecx
		n++;
	return n;
}

int
strnlen(const char *s, size_t size)
  80073e:	8b 55 0c             	mov    0xc(%ebp),%edx
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800741:	b8 00 00 00 00       	mov    $0x0,%eax
  800746:	eb 03                	jmp    80074b <strnlen+0x13>
		n++;
  800748:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80074b:	39 d0                	cmp    %edx,%eax
  80074d:	74 06                	je     800755 <strnlen+0x1d>
  80074f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800753:	75 f3                	jne    800748 <strnlen+0x10>
		n++;
	return n;
}
  800755:	5d                   	pop    %ebp
  800756:	c3                   	ret    

00800757 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800757:	55                   	push   %ebp
  800758:	89 e5                	mov    %esp,%ebp
  80075a:	53                   	push   %ebx
  80075b:	8b 45 08             	mov    0x8(%ebp),%eax
  80075e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800761:	ba 00 00 00 00       	mov    $0x0,%edx
  800766:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  80076a:	88 0c 10             	mov    %cl,(%eax,%edx,1)
  80076d:	83 c2 01             	add    $0x1,%edx
  800770:	84 c9                	test   %cl,%cl
  800772:	75 f2                	jne    800766 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
  800774:	5b                   	pop    %ebx
  800775:	5d                   	pop    %ebp
  800776:	c3                   	ret    

00800777 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800777:	55                   	push   %ebp
  800778:	89 e5                	mov    %esp,%ebp
  80077a:	53                   	push   %ebx
  80077b:	83 ec 08             	sub    $0x8,%esp
  80077e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800781:	89 1c 24             	mov    %ebx,(%esp)
  800784:	e8 97 ff ff ff       	call   800720 <strlen>
	strcpy(dst + len, src);
  800789:	8b 55 0c             	mov    0xc(%ebp),%edx
  80078c:	89 54 24 04          	mov    %edx,0x4(%esp)
  800790:	01 d8                	add    %ebx,%eax
  800792:	89 04 24             	mov    %eax,(%esp)
  800795:	e8 bd ff ff ff       	call   800757 <strcpy>
	return dst;
}
  80079a:	89 d8                	mov    %ebx,%eax
  80079c:	83 c4 08             	add    $0x8,%esp
  80079f:	5b                   	pop    %ebx
  8007a0:	5d                   	pop    %ebp
  8007a1:	c3                   	ret    

008007a2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007a2:	55                   	push   %ebp
  8007a3:	89 e5                	mov    %esp,%ebp
  8007a5:	56                   	push   %esi
  8007a6:	53                   	push   %ebx
  8007a7:	8b 45 08             	mov    0x8(%ebp),%eax
  8007aa:	8b 55 0c             	mov    0xc(%ebp),%edx
  8007ad:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007b0:	b9 00 00 00 00       	mov    $0x0,%ecx
  8007b5:	eb 0f                	jmp    8007c6 <strncpy+0x24>
		*dst++ = *src;
  8007b7:	0f b6 1a             	movzbl (%edx),%ebx
  8007ba:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007bd:	80 3a 01             	cmpb   $0x1,(%edx)
  8007c0:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007c3:	83 c1 01             	add    $0x1,%ecx
  8007c6:	39 f1                	cmp    %esi,%ecx
  8007c8:	75 ed                	jne    8007b7 <strncpy+0x15>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007ca:	5b                   	pop    %ebx
  8007cb:	5e                   	pop    %esi
  8007cc:	5d                   	pop    %ebp
  8007cd:	c3                   	ret    

008007ce <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007ce:	55                   	push   %ebp
  8007cf:	89 e5                	mov    %esp,%ebp
  8007d1:	56                   	push   %esi
  8007d2:	53                   	push   %ebx
  8007d3:	8b 75 08             	mov    0x8(%ebp),%esi
  8007d6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007d9:	8b 55 10             	mov    0x10(%ebp),%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8007dc:	89 f0                	mov    %esi,%eax
  8007de:	85 d2                	test   %edx,%edx
  8007e0:	75 0a                	jne    8007ec <strlcpy+0x1e>
  8007e2:	eb 1d                	jmp    800801 <strlcpy+0x33>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8007e4:	88 18                	mov    %bl,(%eax)
  8007e6:	83 c0 01             	add    $0x1,%eax
  8007e9:	83 c1 01             	add    $0x1,%ecx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8007ec:	83 ea 01             	sub    $0x1,%edx
  8007ef:	74 0b                	je     8007fc <strlcpy+0x2e>
  8007f1:	0f b6 19             	movzbl (%ecx),%ebx
  8007f4:	84 db                	test   %bl,%bl
  8007f6:	75 ec                	jne    8007e4 <strlcpy+0x16>
  8007f8:	89 c2                	mov    %eax,%edx
  8007fa:	eb 02                	jmp    8007fe <strlcpy+0x30>
  8007fc:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  8007fe:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800801:	29 f0                	sub    %esi,%eax
}
  800803:	5b                   	pop    %ebx
  800804:	5e                   	pop    %esi
  800805:	5d                   	pop    %ebp
  800806:	c3                   	ret    

00800807 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800807:	55                   	push   %ebp
  800808:	89 e5                	mov    %esp,%ebp
  80080a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80080d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800810:	eb 06                	jmp    800818 <strcmp+0x11>
		p++, q++;
  800812:	83 c1 01             	add    $0x1,%ecx
  800815:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800818:	0f b6 01             	movzbl (%ecx),%eax
  80081b:	84 c0                	test   %al,%al
  80081d:	74 04                	je     800823 <strcmp+0x1c>
  80081f:	3a 02                	cmp    (%edx),%al
  800821:	74 ef                	je     800812 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800823:	0f b6 c0             	movzbl %al,%eax
  800826:	0f b6 12             	movzbl (%edx),%edx
  800829:	29 d0                	sub    %edx,%eax
}
  80082b:	5d                   	pop    %ebp
  80082c:	c3                   	ret    

0080082d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80082d:	55                   	push   %ebp
  80082e:	89 e5                	mov    %esp,%ebp
  800830:	53                   	push   %ebx
  800831:	8b 45 08             	mov    0x8(%ebp),%eax
  800834:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800837:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
  80083a:	eb 09                	jmp    800845 <strncmp+0x18>
		n--, p++, q++;
  80083c:	83 ea 01             	sub    $0x1,%edx
  80083f:	83 c0 01             	add    $0x1,%eax
  800842:	83 c1 01             	add    $0x1,%ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800845:	85 d2                	test   %edx,%edx
  800847:	74 15                	je     80085e <strncmp+0x31>
  800849:	0f b6 18             	movzbl (%eax),%ebx
  80084c:	84 db                	test   %bl,%bl
  80084e:	74 04                	je     800854 <strncmp+0x27>
  800850:	3a 19                	cmp    (%ecx),%bl
  800852:	74 e8                	je     80083c <strncmp+0xf>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800854:	0f b6 00             	movzbl (%eax),%eax
  800857:	0f b6 11             	movzbl (%ecx),%edx
  80085a:	29 d0                	sub    %edx,%eax
  80085c:	eb 05                	jmp    800863 <strncmp+0x36>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  80085e:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800863:	5b                   	pop    %ebx
  800864:	5d                   	pop    %ebp
  800865:	c3                   	ret    

00800866 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800866:	55                   	push   %ebp
  800867:	89 e5                	mov    %esp,%ebp
  800869:	8b 45 08             	mov    0x8(%ebp),%eax
  80086c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800870:	eb 07                	jmp    800879 <strchr+0x13>
		if (*s == c)
  800872:	38 ca                	cmp    %cl,%dl
  800874:	74 0f                	je     800885 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800876:	83 c0 01             	add    $0x1,%eax
  800879:	0f b6 10             	movzbl (%eax),%edx
  80087c:	84 d2                	test   %dl,%dl
  80087e:	75 f2                	jne    800872 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800880:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800885:	5d                   	pop    %ebp
  800886:	c3                   	ret    

00800887 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800887:	55                   	push   %ebp
  800888:	89 e5                	mov    %esp,%ebp
  80088a:	8b 45 08             	mov    0x8(%ebp),%eax
  80088d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800891:	eb 07                	jmp    80089a <strfind+0x13>
		if (*s == c)
  800893:	38 ca                	cmp    %cl,%dl
  800895:	74 0a                	je     8008a1 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800897:	83 c0 01             	add    $0x1,%eax
  80089a:	0f b6 10             	movzbl (%eax),%edx
  80089d:	84 d2                	test   %dl,%dl
  80089f:	75 f2                	jne    800893 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  8008a1:	5d                   	pop    %ebp
  8008a2:	c3                   	ret    

008008a3 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008a3:	55                   	push   %ebp
  8008a4:	89 e5                	mov    %esp,%ebp
  8008a6:	83 ec 0c             	sub    $0xc,%esp
  8008a9:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8008ac:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8008af:	89 7d fc             	mov    %edi,-0x4(%ebp)
  8008b2:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008b5:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008b8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008bb:	85 c9                	test   %ecx,%ecx
  8008bd:	74 30                	je     8008ef <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008bf:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008c5:	75 25                	jne    8008ec <memset+0x49>
  8008c7:	f6 c1 03             	test   $0x3,%cl
  8008ca:	75 20                	jne    8008ec <memset+0x49>
		c &= 0xFF;
  8008cc:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008cf:	89 d3                	mov    %edx,%ebx
  8008d1:	c1 e3 08             	shl    $0x8,%ebx
  8008d4:	89 d6                	mov    %edx,%esi
  8008d6:	c1 e6 18             	shl    $0x18,%esi
  8008d9:	89 d0                	mov    %edx,%eax
  8008db:	c1 e0 10             	shl    $0x10,%eax
  8008de:	09 f0                	or     %esi,%eax
  8008e0:	09 d0                	or     %edx,%eax
  8008e2:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  8008e4:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  8008e7:	fc                   	cld    
  8008e8:	f3 ab                	rep stos %eax,%es:(%edi)
  8008ea:	eb 03                	jmp    8008ef <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8008ec:	fc                   	cld    
  8008ed:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8008ef:	89 f8                	mov    %edi,%eax
  8008f1:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8008f4:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8008f7:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8008fa:	89 ec                	mov    %ebp,%esp
  8008fc:	5d                   	pop    %ebp
  8008fd:	c3                   	ret    

008008fe <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8008fe:	55                   	push   %ebp
  8008ff:	89 e5                	mov    %esp,%ebp
  800901:	83 ec 08             	sub    $0x8,%esp
  800904:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800907:	89 7d fc             	mov    %edi,-0x4(%ebp)
  80090a:	8b 45 08             	mov    0x8(%ebp),%eax
  80090d:	8b 75 0c             	mov    0xc(%ebp),%esi
  800910:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800913:	39 c6                	cmp    %eax,%esi
  800915:	73 36                	jae    80094d <memmove+0x4f>
  800917:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  80091a:	39 d0                	cmp    %edx,%eax
  80091c:	73 2f                	jae    80094d <memmove+0x4f>
		s += n;
		d += n;
  80091e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800921:	f6 c2 03             	test   $0x3,%dl
  800924:	75 1b                	jne    800941 <memmove+0x43>
  800926:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80092c:	75 13                	jne    800941 <memmove+0x43>
  80092e:	f6 c1 03             	test   $0x3,%cl
  800931:	75 0e                	jne    800941 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800933:	83 ef 04             	sub    $0x4,%edi
  800936:	8d 72 fc             	lea    -0x4(%edx),%esi
  800939:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  80093c:	fd                   	std    
  80093d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80093f:	eb 09                	jmp    80094a <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800941:	83 ef 01             	sub    $0x1,%edi
  800944:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800947:	fd                   	std    
  800948:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  80094a:	fc                   	cld    
  80094b:	eb 20                	jmp    80096d <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80094d:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800953:	75 13                	jne    800968 <memmove+0x6a>
  800955:	a8 03                	test   $0x3,%al
  800957:	75 0f                	jne    800968 <memmove+0x6a>
  800959:	f6 c1 03             	test   $0x3,%cl
  80095c:	75 0a                	jne    800968 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  80095e:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800961:	89 c7                	mov    %eax,%edi
  800963:	fc                   	cld    
  800964:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800966:	eb 05                	jmp    80096d <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800968:	89 c7                	mov    %eax,%edi
  80096a:	fc                   	cld    
  80096b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  80096d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800970:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800973:	89 ec                	mov    %ebp,%esp
  800975:	5d                   	pop    %ebp
  800976:	c3                   	ret    

00800977 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800977:	55                   	push   %ebp
  800978:	89 e5                	mov    %esp,%ebp
  80097a:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  80097d:	8b 45 10             	mov    0x10(%ebp),%eax
  800980:	89 44 24 08          	mov    %eax,0x8(%esp)
  800984:	8b 45 0c             	mov    0xc(%ebp),%eax
  800987:	89 44 24 04          	mov    %eax,0x4(%esp)
  80098b:	8b 45 08             	mov    0x8(%ebp),%eax
  80098e:	89 04 24             	mov    %eax,(%esp)
  800991:	e8 68 ff ff ff       	call   8008fe <memmove>
}
  800996:	c9                   	leave  
  800997:	c3                   	ret    

00800998 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800998:	55                   	push   %ebp
  800999:	89 e5                	mov    %esp,%ebp
  80099b:	57                   	push   %edi
  80099c:	56                   	push   %esi
  80099d:	53                   	push   %ebx
  80099e:	8b 7d 08             	mov    0x8(%ebp),%edi
  8009a1:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009a4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009a7:	ba 00 00 00 00       	mov    $0x0,%edx
  8009ac:	eb 1a                	jmp    8009c8 <memcmp+0x30>
		if (*s1 != *s2)
  8009ae:	0f b6 04 17          	movzbl (%edi,%edx,1),%eax
  8009b2:	83 c2 01             	add    $0x1,%edx
  8009b5:	0f b6 4c 16 ff       	movzbl -0x1(%esi,%edx,1),%ecx
  8009ba:	38 c8                	cmp    %cl,%al
  8009bc:	74 0a                	je     8009c8 <memcmp+0x30>
			return (int) *s1 - (int) *s2;
  8009be:	0f b6 c0             	movzbl %al,%eax
  8009c1:	0f b6 c9             	movzbl %cl,%ecx
  8009c4:	29 c8                	sub    %ecx,%eax
  8009c6:	eb 09                	jmp    8009d1 <memcmp+0x39>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009c8:	39 da                	cmp    %ebx,%edx
  8009ca:	75 e2                	jne    8009ae <memcmp+0x16>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009cc:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009d1:	5b                   	pop    %ebx
  8009d2:	5e                   	pop    %esi
  8009d3:	5f                   	pop    %edi
  8009d4:	5d                   	pop    %ebp
  8009d5:	c3                   	ret    

008009d6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009d6:	55                   	push   %ebp
  8009d7:	89 e5                	mov    %esp,%ebp
  8009d9:	8b 45 08             	mov    0x8(%ebp),%eax
  8009dc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  8009df:	89 c2                	mov    %eax,%edx
  8009e1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  8009e4:	eb 07                	jmp    8009ed <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009e6:	38 08                	cmp    %cl,(%eax)
  8009e8:	74 07                	je     8009f1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009ea:	83 c0 01             	add    $0x1,%eax
  8009ed:	39 d0                	cmp    %edx,%eax
  8009ef:	72 f5                	jb     8009e6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009f1:	5d                   	pop    %ebp
  8009f2:	c3                   	ret    

008009f3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009f3:	55                   	push   %ebp
  8009f4:	89 e5                	mov    %esp,%ebp
  8009f6:	57                   	push   %edi
  8009f7:	56                   	push   %esi
  8009f8:	53                   	push   %ebx
  8009f9:	8b 55 08             	mov    0x8(%ebp),%edx
  8009fc:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009ff:	eb 03                	jmp    800a04 <strtol+0x11>
		s++;
  800a01:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a04:	0f b6 02             	movzbl (%edx),%eax
  800a07:	3c 20                	cmp    $0x20,%al
  800a09:	74 f6                	je     800a01 <strtol+0xe>
  800a0b:	3c 09                	cmp    $0x9,%al
  800a0d:	74 f2                	je     800a01 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a0f:	3c 2b                	cmp    $0x2b,%al
  800a11:	75 0a                	jne    800a1d <strtol+0x2a>
		s++;
  800a13:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a16:	bf 00 00 00 00       	mov    $0x0,%edi
  800a1b:	eb 10                	jmp    800a2d <strtol+0x3a>
  800a1d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a22:	3c 2d                	cmp    $0x2d,%al
  800a24:	75 07                	jne    800a2d <strtol+0x3a>
		s++, neg = 1;
  800a26:	8d 52 01             	lea    0x1(%edx),%edx
  800a29:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a2d:	85 db                	test   %ebx,%ebx
  800a2f:	0f 94 c0             	sete   %al
  800a32:	74 05                	je     800a39 <strtol+0x46>
  800a34:	83 fb 10             	cmp    $0x10,%ebx
  800a37:	75 15                	jne    800a4e <strtol+0x5b>
  800a39:	80 3a 30             	cmpb   $0x30,(%edx)
  800a3c:	75 10                	jne    800a4e <strtol+0x5b>
  800a3e:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800a42:	75 0a                	jne    800a4e <strtol+0x5b>
		s += 2, base = 16;
  800a44:	83 c2 02             	add    $0x2,%edx
  800a47:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a4c:	eb 13                	jmp    800a61 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a4e:	84 c0                	test   %al,%al
  800a50:	74 0f                	je     800a61 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a52:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a57:	80 3a 30             	cmpb   $0x30,(%edx)
  800a5a:	75 05                	jne    800a61 <strtol+0x6e>
		s++, base = 8;
  800a5c:	83 c2 01             	add    $0x1,%edx
  800a5f:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800a61:	b8 00 00 00 00       	mov    $0x0,%eax
  800a66:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a68:	0f b6 0a             	movzbl (%edx),%ecx
  800a6b:	8d 59 d0             	lea    -0x30(%ecx),%ebx
  800a6e:	80 fb 09             	cmp    $0x9,%bl
  800a71:	77 08                	ja     800a7b <strtol+0x88>
			dig = *s - '0';
  800a73:	0f be c9             	movsbl %cl,%ecx
  800a76:	83 e9 30             	sub    $0x30,%ecx
  800a79:	eb 1e                	jmp    800a99 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800a7b:	8d 59 9f             	lea    -0x61(%ecx),%ebx
  800a7e:	80 fb 19             	cmp    $0x19,%bl
  800a81:	77 08                	ja     800a8b <strtol+0x98>
			dig = *s - 'a' + 10;
  800a83:	0f be c9             	movsbl %cl,%ecx
  800a86:	83 e9 57             	sub    $0x57,%ecx
  800a89:	eb 0e                	jmp    800a99 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800a8b:	8d 59 bf             	lea    -0x41(%ecx),%ebx
  800a8e:	80 fb 19             	cmp    $0x19,%bl
  800a91:	77 14                	ja     800aa7 <strtol+0xb4>
			dig = *s - 'A' + 10;
  800a93:	0f be c9             	movsbl %cl,%ecx
  800a96:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800a99:	39 f1                	cmp    %esi,%ecx
  800a9b:	7d 0e                	jge    800aab <strtol+0xb8>
			break;
		s++, val = (val * base) + dig;
  800a9d:	83 c2 01             	add    $0x1,%edx
  800aa0:	0f af c6             	imul   %esi,%eax
  800aa3:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800aa5:	eb c1                	jmp    800a68 <strtol+0x75>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800aa7:	89 c1                	mov    %eax,%ecx
  800aa9:	eb 02                	jmp    800aad <strtol+0xba>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800aab:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800aad:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ab1:	74 05                	je     800ab8 <strtol+0xc5>
		*endptr = (char *) s;
  800ab3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800ab6:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800ab8:	89 ca                	mov    %ecx,%edx
  800aba:	f7 da                	neg    %edx
  800abc:	85 ff                	test   %edi,%edi
  800abe:	0f 45 c2             	cmovne %edx,%eax
}
  800ac1:	5b                   	pop    %ebx
  800ac2:	5e                   	pop    %esi
  800ac3:	5f                   	pop    %edi
  800ac4:	5d                   	pop    %ebp
  800ac5:	c3                   	ret    
	...

00800ac8 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800ac8:	55                   	push   %ebp
  800ac9:	89 e5                	mov    %esp,%ebp
  800acb:	83 ec 0c             	sub    $0xc,%esp
  800ace:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800ad1:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800ad4:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ad7:	b8 00 00 00 00       	mov    $0x0,%eax
  800adc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800adf:	8b 55 08             	mov    0x8(%ebp),%edx
  800ae2:	89 c3                	mov    %eax,%ebx
  800ae4:	89 c7                	mov    %eax,%edi
  800ae6:	89 c6                	mov    %eax,%esi
  800ae8:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800aea:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800aed:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800af0:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800af3:	89 ec                	mov    %ebp,%esp
  800af5:	5d                   	pop    %ebp
  800af6:	c3                   	ret    

00800af7 <sys_cgetc>:

int
sys_cgetc(void)
{
  800af7:	55                   	push   %ebp
  800af8:	89 e5                	mov    %esp,%ebp
  800afa:	83 ec 0c             	sub    $0xc,%esp
  800afd:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800b00:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800b03:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b06:	ba 00 00 00 00       	mov    $0x0,%edx
  800b0b:	b8 01 00 00 00       	mov    $0x1,%eax
  800b10:	89 d1                	mov    %edx,%ecx
  800b12:	89 d3                	mov    %edx,%ebx
  800b14:	89 d7                	mov    %edx,%edi
  800b16:	89 d6                	mov    %edx,%esi
  800b18:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800b1a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800b1d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800b20:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800b23:	89 ec                	mov    %ebp,%esp
  800b25:	5d                   	pop    %ebp
  800b26:	c3                   	ret    

00800b27 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800b27:	55                   	push   %ebp
  800b28:	89 e5                	mov    %esp,%ebp
  800b2a:	83 ec 38             	sub    $0x38,%esp
  800b2d:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800b30:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800b33:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b36:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b3b:	b8 03 00 00 00       	mov    $0x3,%eax
  800b40:	8b 55 08             	mov    0x8(%ebp),%edx
  800b43:	89 cb                	mov    %ecx,%ebx
  800b45:	89 cf                	mov    %ecx,%edi
  800b47:	89 ce                	mov    %ecx,%esi
  800b49:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800b4b:	85 c0                	test   %eax,%eax
  800b4d:	7e 28                	jle    800b77 <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800b4f:	89 44 24 10          	mov    %eax,0x10(%esp)
  800b53:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800b5a:	00 
  800b5b:	c7 44 24 08 d4 10 80 	movl   $0x8010d4,0x8(%esp)
  800b62:	00 
  800b63:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800b6a:	00 
  800b6b:	c7 04 24 f1 10 80 00 	movl   $0x8010f1,(%esp)
  800b72:	e8 3d 00 00 00       	call   800bb4 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800b77:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800b7a:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800b7d:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800b80:	89 ec                	mov    %ebp,%esp
  800b82:	5d                   	pop    %ebp
  800b83:	c3                   	ret    

00800b84 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b84:	55                   	push   %ebp
  800b85:	89 e5                	mov    %esp,%ebp
  800b87:	83 ec 0c             	sub    $0xc,%esp
  800b8a:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800b8d:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800b90:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b93:	ba 00 00 00 00       	mov    $0x0,%edx
  800b98:	b8 02 00 00 00       	mov    $0x2,%eax
  800b9d:	89 d1                	mov    %edx,%ecx
  800b9f:	89 d3                	mov    %edx,%ebx
  800ba1:	89 d7                	mov    %edx,%edi
  800ba3:	89 d6                	mov    %edx,%esi
  800ba5:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800ba7:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800baa:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800bad:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800bb0:	89 ec                	mov    %ebp,%esp
  800bb2:	5d                   	pop    %ebp
  800bb3:	c3                   	ret    

00800bb4 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800bb4:	55                   	push   %ebp
  800bb5:	89 e5                	mov    %esp,%ebp
  800bb7:	56                   	push   %esi
  800bb8:	53                   	push   %ebx
  800bb9:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800bbc:	8d 75 14             	lea    0x14(%ebp),%esi

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800bbf:	8b 1d 00 20 80 00    	mov    0x802000,%ebx
  800bc5:	e8 ba ff ff ff       	call   800b84 <sys_getenvid>
  800bca:	8b 55 0c             	mov    0xc(%ebp),%edx
  800bcd:	89 54 24 10          	mov    %edx,0x10(%esp)
  800bd1:	8b 55 08             	mov    0x8(%ebp),%edx
  800bd4:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800bd8:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800bdc:	89 44 24 04          	mov    %eax,0x4(%esp)
  800be0:	c7 04 24 00 11 80 00 	movl   $0x801100,(%esp)
  800be7:	e8 87 f5 ff ff       	call   800173 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800bec:	89 74 24 04          	mov    %esi,0x4(%esp)
  800bf0:	8b 45 10             	mov    0x10(%ebp),%eax
  800bf3:	89 04 24             	mov    %eax,(%esp)
  800bf6:	e8 17 f5 ff ff       	call   800112 <vcprintf>
	cprintf("\n");
  800bfb:	c7 04 24 c4 0e 80 00 	movl   $0x800ec4,(%esp)
  800c02:	e8 6c f5 ff ff       	call   800173 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800c07:	cc                   	int3   
  800c08:	eb fd                	jmp    800c07 <_panic+0x53>
  800c0a:	00 00                	add    %al,(%eax)
  800c0c:	00 00                	add    %al,(%eax)
	...

00800c10 <__udivdi3>:
  800c10:	83 ec 1c             	sub    $0x1c,%esp
  800c13:	89 7c 24 14          	mov    %edi,0x14(%esp)
  800c17:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
  800c1b:	8b 44 24 20          	mov    0x20(%esp),%eax
  800c1f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  800c23:	89 74 24 10          	mov    %esi,0x10(%esp)
  800c27:	8b 74 24 24          	mov    0x24(%esp),%esi
  800c2b:	85 ff                	test   %edi,%edi
  800c2d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  800c31:	89 44 24 08          	mov    %eax,0x8(%esp)
  800c35:	89 cd                	mov    %ecx,%ebp
  800c37:	89 44 24 04          	mov    %eax,0x4(%esp)
  800c3b:	75 33                	jne    800c70 <__udivdi3+0x60>
  800c3d:	39 f1                	cmp    %esi,%ecx
  800c3f:	77 57                	ja     800c98 <__udivdi3+0x88>
  800c41:	85 c9                	test   %ecx,%ecx
  800c43:	75 0b                	jne    800c50 <__udivdi3+0x40>
  800c45:	b8 01 00 00 00       	mov    $0x1,%eax
  800c4a:	31 d2                	xor    %edx,%edx
  800c4c:	f7 f1                	div    %ecx
  800c4e:	89 c1                	mov    %eax,%ecx
  800c50:	89 f0                	mov    %esi,%eax
  800c52:	31 d2                	xor    %edx,%edx
  800c54:	f7 f1                	div    %ecx
  800c56:	89 c6                	mov    %eax,%esi
  800c58:	8b 44 24 04          	mov    0x4(%esp),%eax
  800c5c:	f7 f1                	div    %ecx
  800c5e:	89 f2                	mov    %esi,%edx
  800c60:	8b 74 24 10          	mov    0x10(%esp),%esi
  800c64:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800c68:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800c6c:	83 c4 1c             	add    $0x1c,%esp
  800c6f:	c3                   	ret    
  800c70:	31 d2                	xor    %edx,%edx
  800c72:	31 c0                	xor    %eax,%eax
  800c74:	39 f7                	cmp    %esi,%edi
  800c76:	77 e8                	ja     800c60 <__udivdi3+0x50>
  800c78:	0f bd cf             	bsr    %edi,%ecx
  800c7b:	83 f1 1f             	xor    $0x1f,%ecx
  800c7e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800c82:	75 2c                	jne    800cb0 <__udivdi3+0xa0>
  800c84:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
  800c88:	76 04                	jbe    800c8e <__udivdi3+0x7e>
  800c8a:	39 f7                	cmp    %esi,%edi
  800c8c:	73 d2                	jae    800c60 <__udivdi3+0x50>
  800c8e:	31 d2                	xor    %edx,%edx
  800c90:	b8 01 00 00 00       	mov    $0x1,%eax
  800c95:	eb c9                	jmp    800c60 <__udivdi3+0x50>
  800c97:	90                   	nop
  800c98:	89 f2                	mov    %esi,%edx
  800c9a:	f7 f1                	div    %ecx
  800c9c:	31 d2                	xor    %edx,%edx
  800c9e:	8b 74 24 10          	mov    0x10(%esp),%esi
  800ca2:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800ca6:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800caa:	83 c4 1c             	add    $0x1c,%esp
  800cad:	c3                   	ret    
  800cae:	66 90                	xchg   %ax,%ax
  800cb0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800cb5:	b8 20 00 00 00       	mov    $0x20,%eax
  800cba:	89 ea                	mov    %ebp,%edx
  800cbc:	2b 44 24 04          	sub    0x4(%esp),%eax
  800cc0:	d3 e7                	shl    %cl,%edi
  800cc2:	89 c1                	mov    %eax,%ecx
  800cc4:	d3 ea                	shr    %cl,%edx
  800cc6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800ccb:	09 fa                	or     %edi,%edx
  800ccd:	89 f7                	mov    %esi,%edi
  800ccf:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800cd3:	89 f2                	mov    %esi,%edx
  800cd5:	8b 74 24 08          	mov    0x8(%esp),%esi
  800cd9:	d3 e5                	shl    %cl,%ebp
  800cdb:	89 c1                	mov    %eax,%ecx
  800cdd:	d3 ef                	shr    %cl,%edi
  800cdf:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800ce4:	d3 e2                	shl    %cl,%edx
  800ce6:	89 c1                	mov    %eax,%ecx
  800ce8:	d3 ee                	shr    %cl,%esi
  800cea:	09 d6                	or     %edx,%esi
  800cec:	89 fa                	mov    %edi,%edx
  800cee:	89 f0                	mov    %esi,%eax
  800cf0:	f7 74 24 0c          	divl   0xc(%esp)
  800cf4:	89 d7                	mov    %edx,%edi
  800cf6:	89 c6                	mov    %eax,%esi
  800cf8:	f7 e5                	mul    %ebp
  800cfa:	39 d7                	cmp    %edx,%edi
  800cfc:	72 22                	jb     800d20 <__udivdi3+0x110>
  800cfe:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  800d02:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800d07:	d3 e5                	shl    %cl,%ebp
  800d09:	39 c5                	cmp    %eax,%ebp
  800d0b:	73 04                	jae    800d11 <__udivdi3+0x101>
  800d0d:	39 d7                	cmp    %edx,%edi
  800d0f:	74 0f                	je     800d20 <__udivdi3+0x110>
  800d11:	89 f0                	mov    %esi,%eax
  800d13:	31 d2                	xor    %edx,%edx
  800d15:	e9 46 ff ff ff       	jmp    800c60 <__udivdi3+0x50>
  800d1a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800d20:	8d 46 ff             	lea    -0x1(%esi),%eax
  800d23:	31 d2                	xor    %edx,%edx
  800d25:	8b 74 24 10          	mov    0x10(%esp),%esi
  800d29:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800d2d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800d31:	83 c4 1c             	add    $0x1c,%esp
  800d34:	c3                   	ret    
	...

00800d40 <__umoddi3>:
  800d40:	83 ec 1c             	sub    $0x1c,%esp
  800d43:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  800d47:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
  800d4b:	8b 44 24 20          	mov    0x20(%esp),%eax
  800d4f:	89 74 24 10          	mov    %esi,0x10(%esp)
  800d53:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  800d57:	8b 74 24 24          	mov    0x24(%esp),%esi
  800d5b:	85 ed                	test   %ebp,%ebp
  800d5d:	89 7c 24 14          	mov    %edi,0x14(%esp)
  800d61:	89 44 24 08          	mov    %eax,0x8(%esp)
  800d65:	89 cf                	mov    %ecx,%edi
  800d67:	89 04 24             	mov    %eax,(%esp)
  800d6a:	89 f2                	mov    %esi,%edx
  800d6c:	75 1a                	jne    800d88 <__umoddi3+0x48>
  800d6e:	39 f1                	cmp    %esi,%ecx
  800d70:	76 4e                	jbe    800dc0 <__umoddi3+0x80>
  800d72:	f7 f1                	div    %ecx
  800d74:	89 d0                	mov    %edx,%eax
  800d76:	31 d2                	xor    %edx,%edx
  800d78:	8b 74 24 10          	mov    0x10(%esp),%esi
  800d7c:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800d80:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800d84:	83 c4 1c             	add    $0x1c,%esp
  800d87:	c3                   	ret    
  800d88:	39 f5                	cmp    %esi,%ebp
  800d8a:	77 54                	ja     800de0 <__umoddi3+0xa0>
  800d8c:	0f bd c5             	bsr    %ebp,%eax
  800d8f:	83 f0 1f             	xor    $0x1f,%eax
  800d92:	89 44 24 04          	mov    %eax,0x4(%esp)
  800d96:	75 60                	jne    800df8 <__umoddi3+0xb8>
  800d98:	3b 0c 24             	cmp    (%esp),%ecx
  800d9b:	0f 87 07 01 00 00    	ja     800ea8 <__umoddi3+0x168>
  800da1:	89 f2                	mov    %esi,%edx
  800da3:	8b 34 24             	mov    (%esp),%esi
  800da6:	29 ce                	sub    %ecx,%esi
  800da8:	19 ea                	sbb    %ebp,%edx
  800daa:	89 34 24             	mov    %esi,(%esp)
  800dad:	8b 04 24             	mov    (%esp),%eax
  800db0:	8b 74 24 10          	mov    0x10(%esp),%esi
  800db4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800db8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800dbc:	83 c4 1c             	add    $0x1c,%esp
  800dbf:	c3                   	ret    
  800dc0:	85 c9                	test   %ecx,%ecx
  800dc2:	75 0b                	jne    800dcf <__umoddi3+0x8f>
  800dc4:	b8 01 00 00 00       	mov    $0x1,%eax
  800dc9:	31 d2                	xor    %edx,%edx
  800dcb:	f7 f1                	div    %ecx
  800dcd:	89 c1                	mov    %eax,%ecx
  800dcf:	89 f0                	mov    %esi,%eax
  800dd1:	31 d2                	xor    %edx,%edx
  800dd3:	f7 f1                	div    %ecx
  800dd5:	8b 04 24             	mov    (%esp),%eax
  800dd8:	f7 f1                	div    %ecx
  800dda:	eb 98                	jmp    800d74 <__umoddi3+0x34>
  800ddc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800de0:	89 f2                	mov    %esi,%edx
  800de2:	8b 74 24 10          	mov    0x10(%esp),%esi
  800de6:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800dea:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800dee:	83 c4 1c             	add    $0x1c,%esp
  800df1:	c3                   	ret    
  800df2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800df8:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800dfd:	89 e8                	mov    %ebp,%eax
  800dff:	bd 20 00 00 00       	mov    $0x20,%ebp
  800e04:	2b 6c 24 04          	sub    0x4(%esp),%ebp
  800e08:	89 fa                	mov    %edi,%edx
  800e0a:	d3 e0                	shl    %cl,%eax
  800e0c:	89 e9                	mov    %ebp,%ecx
  800e0e:	d3 ea                	shr    %cl,%edx
  800e10:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800e15:	09 c2                	or     %eax,%edx
  800e17:	8b 44 24 08          	mov    0x8(%esp),%eax
  800e1b:	89 14 24             	mov    %edx,(%esp)
  800e1e:	89 f2                	mov    %esi,%edx
  800e20:	d3 e7                	shl    %cl,%edi
  800e22:	89 e9                	mov    %ebp,%ecx
  800e24:	d3 ea                	shr    %cl,%edx
  800e26:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800e2b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800e2f:	d3 e6                	shl    %cl,%esi
  800e31:	89 e9                	mov    %ebp,%ecx
  800e33:	d3 e8                	shr    %cl,%eax
  800e35:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800e3a:	09 f0                	or     %esi,%eax
  800e3c:	8b 74 24 08          	mov    0x8(%esp),%esi
  800e40:	f7 34 24             	divl   (%esp)
  800e43:	d3 e6                	shl    %cl,%esi
  800e45:	89 74 24 08          	mov    %esi,0x8(%esp)
  800e49:	89 d6                	mov    %edx,%esi
  800e4b:	f7 e7                	mul    %edi
  800e4d:	39 d6                	cmp    %edx,%esi
  800e4f:	89 c1                	mov    %eax,%ecx
  800e51:	89 d7                	mov    %edx,%edi
  800e53:	72 3f                	jb     800e94 <__umoddi3+0x154>
  800e55:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800e59:	72 35                	jb     800e90 <__umoddi3+0x150>
  800e5b:	8b 44 24 08          	mov    0x8(%esp),%eax
  800e5f:	29 c8                	sub    %ecx,%eax
  800e61:	19 fe                	sbb    %edi,%esi
  800e63:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800e68:	89 f2                	mov    %esi,%edx
  800e6a:	d3 e8                	shr    %cl,%eax
  800e6c:	89 e9                	mov    %ebp,%ecx
  800e6e:	d3 e2                	shl    %cl,%edx
  800e70:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800e75:	09 d0                	or     %edx,%eax
  800e77:	89 f2                	mov    %esi,%edx
  800e79:	d3 ea                	shr    %cl,%edx
  800e7b:	8b 74 24 10          	mov    0x10(%esp),%esi
  800e7f:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800e83:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800e87:	83 c4 1c             	add    $0x1c,%esp
  800e8a:	c3                   	ret    
  800e8b:	90                   	nop
  800e8c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e90:	39 d6                	cmp    %edx,%esi
  800e92:	75 c7                	jne    800e5b <__umoddi3+0x11b>
  800e94:	89 d7                	mov    %edx,%edi
  800e96:	89 c1                	mov    %eax,%ecx
  800e98:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
  800e9c:	1b 3c 24             	sbb    (%esp),%edi
  800e9f:	eb ba                	jmp    800e5b <__umoddi3+0x11b>
  800ea1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800ea8:	39 f5                	cmp    %esi,%ebp
  800eaa:	0f 82 f1 fe ff ff    	jb     800da1 <__umoddi3+0x61>
  800eb0:	e9 f8 fe ff ff       	jmp    800dad <__umoddi3+0x6d>
