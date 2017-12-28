
obj/user/faultread:     file format elf32-i386


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
  80002c:	e8 23 00 00 00       	call   800054 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
	...

00800034 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800034:	55                   	push   %ebp
  800035:	89 e5                	mov    %esp,%ebp
  800037:	83 ec 18             	sub    $0x18,%esp
	cprintf("I read %08x from location 0!\n", *(unsigned*)0);
  80003a:	a1 00 00 00 00       	mov    0x0,%eax
  80003f:	89 44 24 04          	mov    %eax,0x4(%esp)
  800043:	c7 04 24 a8 0e 80 00 	movl   $0x800ea8,(%esp)
  80004a:	e8 10 01 00 00       	call   80015f <cprintf>
}
  80004f:	c9                   	leave  
  800050:	c3                   	ret    
  800051:	00 00                	add    %al,(%eax)
	...

00800054 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800054:	55                   	push   %ebp
  800055:	89 e5                	mov    %esp,%ebp
  800057:	83 ec 18             	sub    $0x18,%esp
  80005a:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  80005d:	89 75 fc             	mov    %esi,-0x4(%ebp)
  800060:	8b 75 08             	mov    0x8(%ebp),%esi
  800063:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = &envs[ENVX(sys_getenvid())];
  800066:	e8 09 0b 00 00       	call   800b74 <sys_getenvid>
  80006b:	25 ff 03 00 00       	and    $0x3ff,%eax
  800070:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800073:	c1 e0 05             	shl    $0x5,%eax
  800076:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80007b:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800080:	85 f6                	test   %esi,%esi
  800082:	7e 07                	jle    80008b <libmain+0x37>
		binaryname = argv[0];
  800084:	8b 03                	mov    (%ebx),%eax
  800086:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80008b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80008f:	89 34 24             	mov    %esi,(%esp)
  800092:	e8 9d ff ff ff       	call   800034 <umain>

	// exit gracefully
	exit();
  800097:	e8 0c 00 00 00       	call   8000a8 <exit>
}
  80009c:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  80009f:	8b 75 fc             	mov    -0x4(%ebp),%esi
  8000a2:	89 ec                	mov    %ebp,%esp
  8000a4:	5d                   	pop    %ebp
  8000a5:	c3                   	ret    
	...

008000a8 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000a8:	55                   	push   %ebp
  8000a9:	89 e5                	mov    %esp,%ebp
  8000ab:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8000ae:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000b5:	e8 5d 0a 00 00       	call   800b17 <sys_env_destroy>
}
  8000ba:	c9                   	leave  
  8000bb:	c3                   	ret    

008000bc <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000bc:	55                   	push   %ebp
  8000bd:	89 e5                	mov    %esp,%ebp
  8000bf:	53                   	push   %ebx
  8000c0:	83 ec 14             	sub    $0x14,%esp
  8000c3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000c6:	8b 03                	mov    (%ebx),%eax
  8000c8:	8b 55 08             	mov    0x8(%ebp),%edx
  8000cb:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  8000cf:	83 c0 01             	add    $0x1,%eax
  8000d2:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  8000d4:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000d9:	75 19                	jne    8000f4 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8000db:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8000e2:	00 
  8000e3:	8d 43 08             	lea    0x8(%ebx),%eax
  8000e6:	89 04 24             	mov    %eax,(%esp)
  8000e9:	e8 ca 09 00 00       	call   800ab8 <sys_cputs>
		b->idx = 0;
  8000ee:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8000f4:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000f8:	83 c4 14             	add    $0x14,%esp
  8000fb:	5b                   	pop    %ebx
  8000fc:	5d                   	pop    %ebp
  8000fd:	c3                   	ret    

008000fe <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000fe:	55                   	push   %ebp
  8000ff:	89 e5                	mov    %esp,%ebp
  800101:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800107:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80010e:	00 00 00 
	b.cnt = 0;
  800111:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800118:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80011b:	8b 45 0c             	mov    0xc(%ebp),%eax
  80011e:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800122:	8b 45 08             	mov    0x8(%ebp),%eax
  800125:	89 44 24 08          	mov    %eax,0x8(%esp)
  800129:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80012f:	89 44 24 04          	mov    %eax,0x4(%esp)
  800133:	c7 04 24 bc 00 80 00 	movl   $0x8000bc,(%esp)
  80013a:	e8 8e 01 00 00       	call   8002cd <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80013f:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800145:	89 44 24 04          	mov    %eax,0x4(%esp)
  800149:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80014f:	89 04 24             	mov    %eax,(%esp)
  800152:	e8 61 09 00 00       	call   800ab8 <sys_cputs>

	return b.cnt;
}
  800157:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80015d:	c9                   	leave  
  80015e:	c3                   	ret    

0080015f <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80015f:	55                   	push   %ebp
  800160:	89 e5                	mov    %esp,%ebp
  800162:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800165:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800168:	89 44 24 04          	mov    %eax,0x4(%esp)
  80016c:	8b 45 08             	mov    0x8(%ebp),%eax
  80016f:	89 04 24             	mov    %eax,(%esp)
  800172:	e8 87 ff ff ff       	call   8000fe <vcprintf>
	va_end(ap);

	return cnt;
}
  800177:	c9                   	leave  
  800178:	c3                   	ret    
  800179:	00 00                	add    %al,(%eax)
  80017b:	00 00                	add    %al,(%eax)
  80017d:	00 00                	add    %al,(%eax)
	...

00800180 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800180:	55                   	push   %ebp
  800181:	89 e5                	mov    %esp,%ebp
  800183:	57                   	push   %edi
  800184:	56                   	push   %esi
  800185:	53                   	push   %ebx
  800186:	83 ec 3c             	sub    $0x3c,%esp
  800189:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80018c:	89 d7                	mov    %edx,%edi
  80018e:	8b 45 08             	mov    0x8(%ebp),%eax
  800191:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800194:	8b 45 0c             	mov    0xc(%ebp),%eax
  800197:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80019a:	8b 5d 14             	mov    0x14(%ebp),%ebx
  80019d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8001a0:	85 c0                	test   %eax,%eax
  8001a2:	75 08                	jne    8001ac <printnum+0x2c>
  8001a4:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8001a7:	39 45 10             	cmp    %eax,0x10(%ebp)
  8001aa:	77 59                	ja     800205 <printnum+0x85>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8001ac:	89 74 24 10          	mov    %esi,0x10(%esp)
  8001b0:	83 eb 01             	sub    $0x1,%ebx
  8001b3:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  8001b7:	8b 45 10             	mov    0x10(%ebp),%eax
  8001ba:	89 44 24 08          	mov    %eax,0x8(%esp)
  8001be:	8b 5c 24 08          	mov    0x8(%esp),%ebx
  8001c2:	8b 74 24 0c          	mov    0xc(%esp),%esi
  8001c6:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8001cd:	00 
  8001ce:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8001d1:	89 04 24             	mov    %eax,(%esp)
  8001d4:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8001d7:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001db:	e8 20 0a 00 00       	call   800c00 <__udivdi3>
  8001e0:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8001e4:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8001e8:	89 04 24             	mov    %eax,(%esp)
  8001eb:	89 54 24 04          	mov    %edx,0x4(%esp)
  8001ef:	89 fa                	mov    %edi,%edx
  8001f1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8001f4:	e8 87 ff ff ff       	call   800180 <printnum>
  8001f9:	eb 11                	jmp    80020c <printnum+0x8c>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001fb:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8001ff:	89 34 24             	mov    %esi,(%esp)
  800202:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800205:	83 eb 01             	sub    $0x1,%ebx
  800208:	85 db                	test   %ebx,%ebx
  80020a:	7f ef                	jg     8001fb <printnum+0x7b>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80020c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800210:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800214:	8b 45 10             	mov    0x10(%ebp),%eax
  800217:	89 44 24 08          	mov    %eax,0x8(%esp)
  80021b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800222:	00 
  800223:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800226:	89 04 24             	mov    %eax,(%esp)
  800229:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80022c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800230:	e8 fb 0a 00 00       	call   800d30 <__umoddi3>
  800235:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800239:	0f be 80 d0 0e 80 00 	movsbl 0x800ed0(%eax),%eax
  800240:	89 04 24             	mov    %eax,(%esp)
  800243:	ff 55 e4             	call   *-0x1c(%ebp)
}
  800246:	83 c4 3c             	add    $0x3c,%esp
  800249:	5b                   	pop    %ebx
  80024a:	5e                   	pop    %esi
  80024b:	5f                   	pop    %edi
  80024c:	5d                   	pop    %ebp
  80024d:	c3                   	ret    

0080024e <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80024e:	55                   	push   %ebp
  80024f:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800251:	83 fa 01             	cmp    $0x1,%edx
  800254:	7e 0e                	jle    800264 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800256:	8b 10                	mov    (%eax),%edx
  800258:	8d 4a 08             	lea    0x8(%edx),%ecx
  80025b:	89 08                	mov    %ecx,(%eax)
  80025d:	8b 02                	mov    (%edx),%eax
  80025f:	8b 52 04             	mov    0x4(%edx),%edx
  800262:	eb 22                	jmp    800286 <getuint+0x38>
	else if (lflag)
  800264:	85 d2                	test   %edx,%edx
  800266:	74 10                	je     800278 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800268:	8b 10                	mov    (%eax),%edx
  80026a:	8d 4a 04             	lea    0x4(%edx),%ecx
  80026d:	89 08                	mov    %ecx,(%eax)
  80026f:	8b 02                	mov    (%edx),%eax
  800271:	ba 00 00 00 00       	mov    $0x0,%edx
  800276:	eb 0e                	jmp    800286 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800278:	8b 10                	mov    (%eax),%edx
  80027a:	8d 4a 04             	lea    0x4(%edx),%ecx
  80027d:	89 08                	mov    %ecx,(%eax)
  80027f:	8b 02                	mov    (%edx),%eax
  800281:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800286:	5d                   	pop    %ebp
  800287:	c3                   	ret    

00800288 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800288:	55                   	push   %ebp
  800289:	89 e5                	mov    %esp,%ebp
  80028b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80028e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800292:	8b 10                	mov    (%eax),%edx
  800294:	3b 50 04             	cmp    0x4(%eax),%edx
  800297:	73 0a                	jae    8002a3 <sprintputch+0x1b>
		*b->buf++ = ch;
  800299:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80029c:	88 0a                	mov    %cl,(%edx)
  80029e:	83 c2 01             	add    $0x1,%edx
  8002a1:	89 10                	mov    %edx,(%eax)
}
  8002a3:	5d                   	pop    %ebp
  8002a4:	c3                   	ret    

008002a5 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002a5:	55                   	push   %ebp
  8002a6:	89 e5                	mov    %esp,%ebp
  8002a8:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8002ab:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002ae:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002b2:	8b 45 10             	mov    0x10(%ebp),%eax
  8002b5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002b9:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002bc:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002c0:	8b 45 08             	mov    0x8(%ebp),%eax
  8002c3:	89 04 24             	mov    %eax,(%esp)
  8002c6:	e8 02 00 00 00       	call   8002cd <vprintfmt>
	va_end(ap);
}
  8002cb:	c9                   	leave  
  8002cc:	c3                   	ret    

008002cd <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002cd:	55                   	push   %ebp
  8002ce:	89 e5                	mov    %esp,%ebp
  8002d0:	57                   	push   %edi
  8002d1:	56                   	push   %esi
  8002d2:	53                   	push   %ebx
  8002d3:	83 ec 4c             	sub    $0x4c,%esp
  8002d6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002d9:	8b 75 10             	mov    0x10(%ebp),%esi
  8002dc:	eb 12                	jmp    8002f0 <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8002de:	85 c0                	test   %eax,%eax
  8002e0:	0f 84 9f 03 00 00    	je     800685 <vprintfmt+0x3b8>
				return;
			putch(ch, putdat);
  8002e6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8002ea:	89 04 24             	mov    %eax,(%esp)
  8002ed:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8002f0:	0f b6 06             	movzbl (%esi),%eax
  8002f3:	83 c6 01             	add    $0x1,%esi
  8002f6:	83 f8 25             	cmp    $0x25,%eax
  8002f9:	75 e3                	jne    8002de <vprintfmt+0x11>
  8002fb:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  8002ff:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  800306:	bf ff ff ff ff       	mov    $0xffffffff,%edi
  80030b:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
  800312:	b9 00 00 00 00       	mov    $0x0,%ecx
  800317:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80031a:	eb 2b                	jmp    800347 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80031c:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  80031f:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  800323:	eb 22                	jmp    800347 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800325:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800328:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  80032c:	eb 19                	jmp    800347 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80032e:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  800331:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  800338:	eb 0d                	jmp    800347 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  80033a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80033d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800340:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800347:	0f b6 16             	movzbl (%esi),%edx
  80034a:	0f b6 c2             	movzbl %dl,%eax
  80034d:	8d 7e 01             	lea    0x1(%esi),%edi
  800350:	89 7d e0             	mov    %edi,-0x20(%ebp)
  800353:	83 ea 23             	sub    $0x23,%edx
  800356:	80 fa 55             	cmp    $0x55,%dl
  800359:	0f 87 08 03 00 00    	ja     800667 <vprintfmt+0x39a>
  80035f:	0f b6 d2             	movzbl %dl,%edx
  800362:	ff 24 95 60 0f 80 00 	jmp    *0x800f60(,%edx,4)
  800369:	8b 75 e0             	mov    -0x20(%ebp),%esi
  80036c:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
  800373:	bf 00 00 00 00       	mov    $0x0,%edi
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800378:	8d 14 bf             	lea    (%edi,%edi,4),%edx
  80037b:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
  80037f:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  800382:	8d 50 d0             	lea    -0x30(%eax),%edx
  800385:	83 fa 09             	cmp    $0x9,%edx
  800388:	77 2f                	ja     8003b9 <vprintfmt+0xec>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  80038a:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  80038d:	eb e9                	jmp    800378 <vprintfmt+0xab>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  80038f:	8b 45 14             	mov    0x14(%ebp),%eax
  800392:	8d 50 04             	lea    0x4(%eax),%edx
  800395:	89 55 14             	mov    %edx,0x14(%ebp)
  800398:	8b 00                	mov    (%eax),%eax
  80039a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80039d:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003a0:	eb 1a                	jmp    8003bc <vprintfmt+0xef>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a2:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
  8003a5:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8003a9:	79 9c                	jns    800347 <vprintfmt+0x7a>
  8003ab:	eb 81                	jmp    80032e <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ad:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003b0:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
  8003b7:	eb 8e                	jmp    800347 <vprintfmt+0x7a>
  8003b9:	89 7d d4             	mov    %edi,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  8003bc:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8003c0:	79 85                	jns    800347 <vprintfmt+0x7a>
  8003c2:	e9 73 ff ff ff       	jmp    80033a <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8003c7:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ca:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003cd:	e9 75 ff ff ff       	jmp    800347 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8003d2:	8b 45 14             	mov    0x14(%ebp),%eax
  8003d5:	8d 50 04             	lea    0x4(%eax),%edx
  8003d8:	89 55 14             	mov    %edx,0x14(%ebp)
  8003db:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8003df:	8b 00                	mov    (%eax),%eax
  8003e1:	89 04 24             	mov    %eax,(%esp)
  8003e4:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003e7:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8003ea:	e9 01 ff ff ff       	jmp    8002f0 <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003ef:	8b 45 14             	mov    0x14(%ebp),%eax
  8003f2:	8d 50 04             	lea    0x4(%eax),%edx
  8003f5:	89 55 14             	mov    %edx,0x14(%ebp)
  8003f8:	8b 00                	mov    (%eax),%eax
  8003fa:	89 c2                	mov    %eax,%edx
  8003fc:	c1 fa 1f             	sar    $0x1f,%edx
  8003ff:	31 d0                	xor    %edx,%eax
  800401:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800403:	83 f8 06             	cmp    $0x6,%eax
  800406:	7f 0b                	jg     800413 <vprintfmt+0x146>
  800408:	8b 14 85 b8 10 80 00 	mov    0x8010b8(,%eax,4),%edx
  80040f:	85 d2                	test   %edx,%edx
  800411:	75 23                	jne    800436 <vprintfmt+0x169>
				printfmt(putch, putdat, "error %d", err);
  800413:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800417:	c7 44 24 08 e8 0e 80 	movl   $0x800ee8,0x8(%esp)
  80041e:	00 
  80041f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800423:	8b 7d 08             	mov    0x8(%ebp),%edi
  800426:	89 3c 24             	mov    %edi,(%esp)
  800429:	e8 77 fe ff ff       	call   8002a5 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80042e:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800431:	e9 ba fe ff ff       	jmp    8002f0 <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
  800436:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80043a:	c7 44 24 08 f1 0e 80 	movl   $0x800ef1,0x8(%esp)
  800441:	00 
  800442:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800446:	8b 7d 08             	mov    0x8(%ebp),%edi
  800449:	89 3c 24             	mov    %edi,(%esp)
  80044c:	e8 54 fe ff ff       	call   8002a5 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800451:	8b 75 e0             	mov    -0x20(%ebp),%esi
  800454:	e9 97 fe ff ff       	jmp    8002f0 <vprintfmt+0x23>
  800459:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80045c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80045f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800462:	8b 45 14             	mov    0x14(%ebp),%eax
  800465:	8d 50 04             	lea    0x4(%eax),%edx
  800468:	89 55 14             	mov    %edx,0x14(%ebp)
  80046b:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  80046d:	85 f6                	test   %esi,%esi
  80046f:	ba e1 0e 80 00       	mov    $0x800ee1,%edx
  800474:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
  800477:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  80047b:	0f 8e 8c 00 00 00    	jle    80050d <vprintfmt+0x240>
  800481:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  800485:	0f 84 82 00 00 00    	je     80050d <vprintfmt+0x240>
				for (width -= strnlen(p, precision); width > 0; width--)
  80048b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80048f:	89 34 24             	mov    %esi,(%esp)
  800492:	e8 91 02 00 00       	call   800728 <strnlen>
  800497:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  80049a:	29 c2                	sub    %eax,%edx
  80049c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
					putch(padc, putdat);
  80049f:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  8004a3:	89 75 d0             	mov    %esi,-0x30(%ebp)
  8004a6:	89 7d cc             	mov    %edi,-0x34(%ebp)
  8004a9:	89 de                	mov    %ebx,%esi
  8004ab:	89 d3                	mov    %edx,%ebx
  8004ad:	89 c7                	mov    %eax,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004af:	eb 0d                	jmp    8004be <vprintfmt+0x1f1>
					putch(padc, putdat);
  8004b1:	89 74 24 04          	mov    %esi,0x4(%esp)
  8004b5:	89 3c 24             	mov    %edi,(%esp)
  8004b8:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004bb:	83 eb 01             	sub    $0x1,%ebx
  8004be:	85 db                	test   %ebx,%ebx
  8004c0:	7f ef                	jg     8004b1 <vprintfmt+0x1e4>
  8004c2:	8b 7d cc             	mov    -0x34(%ebp),%edi
  8004c5:	89 f3                	mov    %esi,%ebx
  8004c7:	8b 75 d0             	mov    -0x30(%ebp),%esi

// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
  8004ca:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8004ce:	b8 00 00 00 00       	mov    $0x0,%eax
  8004d3:	0f 49 45 e4          	cmovns -0x1c(%ebp),%eax
  8004d7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8004da:	29 c2                	sub    %eax,%edx
  8004dc:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8004df:	eb 2c                	jmp    80050d <vprintfmt+0x240>
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004e1:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8004e5:	74 18                	je     8004ff <vprintfmt+0x232>
  8004e7:	8d 50 e0             	lea    -0x20(%eax),%edx
  8004ea:	83 fa 5e             	cmp    $0x5e,%edx
  8004ed:	76 10                	jbe    8004ff <vprintfmt+0x232>
					putch('?', putdat);
  8004ef:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8004f3:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  8004fa:	ff 55 08             	call   *0x8(%ebp)
  8004fd:	eb 0a                	jmp    800509 <vprintfmt+0x23c>
				else
					putch(ch, putdat);
  8004ff:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800503:	89 04 24             	mov    %eax,(%esp)
  800506:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800509:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
  80050d:	0f be 06             	movsbl (%esi),%eax
  800510:	83 c6 01             	add    $0x1,%esi
  800513:	85 c0                	test   %eax,%eax
  800515:	74 25                	je     80053c <vprintfmt+0x26f>
  800517:	85 ff                	test   %edi,%edi
  800519:	78 c6                	js     8004e1 <vprintfmt+0x214>
  80051b:	83 ef 01             	sub    $0x1,%edi
  80051e:	79 c1                	jns    8004e1 <vprintfmt+0x214>
  800520:	8b 7d 08             	mov    0x8(%ebp),%edi
  800523:	89 de                	mov    %ebx,%esi
  800525:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800528:	eb 1a                	jmp    800544 <vprintfmt+0x277>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  80052a:	89 74 24 04          	mov    %esi,0x4(%esp)
  80052e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800535:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800537:	83 eb 01             	sub    $0x1,%ebx
  80053a:	eb 08                	jmp    800544 <vprintfmt+0x277>
  80053c:	8b 7d 08             	mov    0x8(%ebp),%edi
  80053f:	89 de                	mov    %ebx,%esi
  800541:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800544:	85 db                	test   %ebx,%ebx
  800546:	7f e2                	jg     80052a <vprintfmt+0x25d>
  800548:	89 7d 08             	mov    %edi,0x8(%ebp)
  80054b:	89 f3                	mov    %esi,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80054d:	8b 75 e0             	mov    -0x20(%ebp),%esi
  800550:	e9 9b fd ff ff       	jmp    8002f0 <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800555:	83 f9 01             	cmp    $0x1,%ecx
  800558:	7e 10                	jle    80056a <vprintfmt+0x29d>
		return va_arg(*ap, long long);
  80055a:	8b 45 14             	mov    0x14(%ebp),%eax
  80055d:	8d 50 08             	lea    0x8(%eax),%edx
  800560:	89 55 14             	mov    %edx,0x14(%ebp)
  800563:	8b 30                	mov    (%eax),%esi
  800565:	8b 78 04             	mov    0x4(%eax),%edi
  800568:	eb 26                	jmp    800590 <vprintfmt+0x2c3>
	else if (lflag)
  80056a:	85 c9                	test   %ecx,%ecx
  80056c:	74 12                	je     800580 <vprintfmt+0x2b3>
		return va_arg(*ap, long);
  80056e:	8b 45 14             	mov    0x14(%ebp),%eax
  800571:	8d 50 04             	lea    0x4(%eax),%edx
  800574:	89 55 14             	mov    %edx,0x14(%ebp)
  800577:	8b 30                	mov    (%eax),%esi
  800579:	89 f7                	mov    %esi,%edi
  80057b:	c1 ff 1f             	sar    $0x1f,%edi
  80057e:	eb 10                	jmp    800590 <vprintfmt+0x2c3>
	else
		return va_arg(*ap, int);
  800580:	8b 45 14             	mov    0x14(%ebp),%eax
  800583:	8d 50 04             	lea    0x4(%eax),%edx
  800586:	89 55 14             	mov    %edx,0x14(%ebp)
  800589:	8b 30                	mov    (%eax),%esi
  80058b:	89 f7                	mov    %esi,%edi
  80058d:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800590:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800595:	85 ff                	test   %edi,%edi
  800597:	0f 89 8c 00 00 00    	jns    800629 <vprintfmt+0x35c>
				putch('-', putdat);
  80059d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005a1:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8005a8:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  8005ab:	f7 de                	neg    %esi
  8005ad:	83 d7 00             	adc    $0x0,%edi
  8005b0:	f7 df                	neg    %edi
			}
			base = 10;
  8005b2:	b8 0a 00 00 00       	mov    $0xa,%eax
  8005b7:	eb 70                	jmp    800629 <vprintfmt+0x35c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8005b9:	89 ca                	mov    %ecx,%edx
  8005bb:	8d 45 14             	lea    0x14(%ebp),%eax
  8005be:	e8 8b fc ff ff       	call   80024e <getuint>
  8005c3:	89 c6                	mov    %eax,%esi
  8005c5:	89 d7                	mov    %edx,%edi
			base = 10;
  8005c7:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
  8005cc:	eb 5b                	jmp    800629 <vprintfmt+0x35c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num=getuint(&ap,lflag);
  8005ce:	89 ca                	mov    %ecx,%edx
  8005d0:	8d 45 14             	lea    0x14(%ebp),%eax
  8005d3:	e8 76 fc ff ff       	call   80024e <getuint>
  8005d8:	89 c6                	mov    %eax,%esi
  8005da:	89 d7                	mov    %edx,%edi
			base = 8;
  8005dc:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
  8005e1:	eb 46                	jmp    800629 <vprintfmt+0x35c>
	
		// pointer
		case 'p':
			putch('0', putdat);
  8005e3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005e7:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  8005ee:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  8005f1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005f5:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  8005fc:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8005ff:	8b 45 14             	mov    0x14(%ebp),%eax
  800602:	8d 50 04             	lea    0x4(%eax),%edx
  800605:	89 55 14             	mov    %edx,0x14(%ebp)
	
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800608:	8b 30                	mov    (%eax),%esi
  80060a:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80060f:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  800614:	eb 13                	jmp    800629 <vprintfmt+0x35c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800616:	89 ca                	mov    %ecx,%edx
  800618:	8d 45 14             	lea    0x14(%ebp),%eax
  80061b:	e8 2e fc ff ff       	call   80024e <getuint>
  800620:	89 c6                	mov    %eax,%esi
  800622:	89 d7                	mov    %edx,%edi
			base = 16;
  800624:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800629:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
  80062d:	89 54 24 10          	mov    %edx,0x10(%esp)
  800631:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800634:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800638:	89 44 24 08          	mov    %eax,0x8(%esp)
  80063c:	89 34 24             	mov    %esi,(%esp)
  80063f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800643:	89 da                	mov    %ebx,%edx
  800645:	8b 45 08             	mov    0x8(%ebp),%eax
  800648:	e8 33 fb ff ff       	call   800180 <printnum>
			break;
  80064d:	8b 75 e0             	mov    -0x20(%ebp),%esi
  800650:	e9 9b fc ff ff       	jmp    8002f0 <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800655:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800659:	89 04 24             	mov    %eax,(%esp)
  80065c:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80065f:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800662:	e9 89 fc ff ff       	jmp    8002f0 <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800667:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80066b:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800672:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  800675:	eb 03                	jmp    80067a <vprintfmt+0x3ad>
  800677:	83 ee 01             	sub    $0x1,%esi
  80067a:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
  80067e:	75 f7                	jne    800677 <vprintfmt+0x3aa>
  800680:	e9 6b fc ff ff       	jmp    8002f0 <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
  800685:	83 c4 4c             	add    $0x4c,%esp
  800688:	5b                   	pop    %ebx
  800689:	5e                   	pop    %esi
  80068a:	5f                   	pop    %edi
  80068b:	5d                   	pop    %ebp
  80068c:	c3                   	ret    

0080068d <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80068d:	55                   	push   %ebp
  80068e:	89 e5                	mov    %esp,%ebp
  800690:	83 ec 28             	sub    $0x28,%esp
  800693:	8b 45 08             	mov    0x8(%ebp),%eax
  800696:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800699:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80069c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006a0:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006a3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006aa:	85 c0                	test   %eax,%eax
  8006ac:	74 30                	je     8006de <vsnprintf+0x51>
  8006ae:	85 d2                	test   %edx,%edx
  8006b0:	7e 2c                	jle    8006de <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006b2:	8b 45 14             	mov    0x14(%ebp),%eax
  8006b5:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8006b9:	8b 45 10             	mov    0x10(%ebp),%eax
  8006bc:	89 44 24 08          	mov    %eax,0x8(%esp)
  8006c0:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8006c3:	89 44 24 04          	mov    %eax,0x4(%esp)
  8006c7:	c7 04 24 88 02 80 00 	movl   $0x800288,(%esp)
  8006ce:	e8 fa fb ff ff       	call   8002cd <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8006d3:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8006d6:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8006d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8006dc:	eb 05                	jmp    8006e3 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8006de:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8006e3:	c9                   	leave  
  8006e4:	c3                   	ret    

008006e5 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8006e5:	55                   	push   %ebp
  8006e6:	89 e5                	mov    %esp,%ebp
  8006e8:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8006eb:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8006ee:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8006f2:	8b 45 10             	mov    0x10(%ebp),%eax
  8006f5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8006f9:	8b 45 0c             	mov    0xc(%ebp),%eax
  8006fc:	89 44 24 04          	mov    %eax,0x4(%esp)
  800700:	8b 45 08             	mov    0x8(%ebp),%eax
  800703:	89 04 24             	mov    %eax,(%esp)
  800706:	e8 82 ff ff ff       	call   80068d <vsnprintf>
	va_end(ap);

	return rc;
}
  80070b:	c9                   	leave  
  80070c:	c3                   	ret    
  80070d:	00 00                	add    %al,(%eax)
	...

00800710 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800710:	55                   	push   %ebp
  800711:	89 e5                	mov    %esp,%ebp
  800713:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800716:	b8 00 00 00 00       	mov    $0x0,%eax
  80071b:	eb 03                	jmp    800720 <strlen+0x10>
		n++;
  80071d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800720:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800724:	75 f7                	jne    80071d <strlen+0xd>
		n++;
	return n;
}
  800726:	5d                   	pop    %ebp
  800727:	c3                   	ret    

00800728 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800728:	55                   	push   %ebp
  800729:	89 e5                	mov    %esp,%ebp
  80072b:	8b 4d 08             	mov    0x8(%ebp),%ecx
		n++;
	return n;
}

int
strnlen(const char *s, size_t size)
  80072e:	8b 55 0c             	mov    0xc(%ebp),%edx
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800731:	b8 00 00 00 00       	mov    $0x0,%eax
  800736:	eb 03                	jmp    80073b <strnlen+0x13>
		n++;
  800738:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80073b:	39 d0                	cmp    %edx,%eax
  80073d:	74 06                	je     800745 <strnlen+0x1d>
  80073f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800743:	75 f3                	jne    800738 <strnlen+0x10>
		n++;
	return n;
}
  800745:	5d                   	pop    %ebp
  800746:	c3                   	ret    

00800747 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800747:	55                   	push   %ebp
  800748:	89 e5                	mov    %esp,%ebp
  80074a:	53                   	push   %ebx
  80074b:	8b 45 08             	mov    0x8(%ebp),%eax
  80074e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800751:	ba 00 00 00 00       	mov    $0x0,%edx
  800756:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  80075a:	88 0c 10             	mov    %cl,(%eax,%edx,1)
  80075d:	83 c2 01             	add    $0x1,%edx
  800760:	84 c9                	test   %cl,%cl
  800762:	75 f2                	jne    800756 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
  800764:	5b                   	pop    %ebx
  800765:	5d                   	pop    %ebp
  800766:	c3                   	ret    

00800767 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800767:	55                   	push   %ebp
  800768:	89 e5                	mov    %esp,%ebp
  80076a:	53                   	push   %ebx
  80076b:	83 ec 08             	sub    $0x8,%esp
  80076e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800771:	89 1c 24             	mov    %ebx,(%esp)
  800774:	e8 97 ff ff ff       	call   800710 <strlen>
	strcpy(dst + len, src);
  800779:	8b 55 0c             	mov    0xc(%ebp),%edx
  80077c:	89 54 24 04          	mov    %edx,0x4(%esp)
  800780:	01 d8                	add    %ebx,%eax
  800782:	89 04 24             	mov    %eax,(%esp)
  800785:	e8 bd ff ff ff       	call   800747 <strcpy>
	return dst;
}
  80078a:	89 d8                	mov    %ebx,%eax
  80078c:	83 c4 08             	add    $0x8,%esp
  80078f:	5b                   	pop    %ebx
  800790:	5d                   	pop    %ebp
  800791:	c3                   	ret    

00800792 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800792:	55                   	push   %ebp
  800793:	89 e5                	mov    %esp,%ebp
  800795:	56                   	push   %esi
  800796:	53                   	push   %ebx
  800797:	8b 45 08             	mov    0x8(%ebp),%eax
  80079a:	8b 55 0c             	mov    0xc(%ebp),%edx
  80079d:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007a0:	b9 00 00 00 00       	mov    $0x0,%ecx
  8007a5:	eb 0f                	jmp    8007b6 <strncpy+0x24>
		*dst++ = *src;
  8007a7:	0f b6 1a             	movzbl (%edx),%ebx
  8007aa:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007ad:	80 3a 01             	cmpb   $0x1,(%edx)
  8007b0:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007b3:	83 c1 01             	add    $0x1,%ecx
  8007b6:	39 f1                	cmp    %esi,%ecx
  8007b8:	75 ed                	jne    8007a7 <strncpy+0x15>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007ba:	5b                   	pop    %ebx
  8007bb:	5e                   	pop    %esi
  8007bc:	5d                   	pop    %ebp
  8007bd:	c3                   	ret    

008007be <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007be:	55                   	push   %ebp
  8007bf:	89 e5                	mov    %esp,%ebp
  8007c1:	56                   	push   %esi
  8007c2:	53                   	push   %ebx
  8007c3:	8b 75 08             	mov    0x8(%ebp),%esi
  8007c6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007c9:	8b 55 10             	mov    0x10(%ebp),%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8007cc:	89 f0                	mov    %esi,%eax
  8007ce:	85 d2                	test   %edx,%edx
  8007d0:	75 0a                	jne    8007dc <strlcpy+0x1e>
  8007d2:	eb 1d                	jmp    8007f1 <strlcpy+0x33>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8007d4:	88 18                	mov    %bl,(%eax)
  8007d6:	83 c0 01             	add    $0x1,%eax
  8007d9:	83 c1 01             	add    $0x1,%ecx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8007dc:	83 ea 01             	sub    $0x1,%edx
  8007df:	74 0b                	je     8007ec <strlcpy+0x2e>
  8007e1:	0f b6 19             	movzbl (%ecx),%ebx
  8007e4:	84 db                	test   %bl,%bl
  8007e6:	75 ec                	jne    8007d4 <strlcpy+0x16>
  8007e8:	89 c2                	mov    %eax,%edx
  8007ea:	eb 02                	jmp    8007ee <strlcpy+0x30>
  8007ec:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  8007ee:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  8007f1:	29 f0                	sub    %esi,%eax
}
  8007f3:	5b                   	pop    %ebx
  8007f4:	5e                   	pop    %esi
  8007f5:	5d                   	pop    %ebp
  8007f6:	c3                   	ret    

008007f7 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8007f7:	55                   	push   %ebp
  8007f8:	89 e5                	mov    %esp,%ebp
  8007fa:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007fd:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800800:	eb 06                	jmp    800808 <strcmp+0x11>
		p++, q++;
  800802:	83 c1 01             	add    $0x1,%ecx
  800805:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800808:	0f b6 01             	movzbl (%ecx),%eax
  80080b:	84 c0                	test   %al,%al
  80080d:	74 04                	je     800813 <strcmp+0x1c>
  80080f:	3a 02                	cmp    (%edx),%al
  800811:	74 ef                	je     800802 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800813:	0f b6 c0             	movzbl %al,%eax
  800816:	0f b6 12             	movzbl (%edx),%edx
  800819:	29 d0                	sub    %edx,%eax
}
  80081b:	5d                   	pop    %ebp
  80081c:	c3                   	ret    

0080081d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80081d:	55                   	push   %ebp
  80081e:	89 e5                	mov    %esp,%ebp
  800820:	53                   	push   %ebx
  800821:	8b 45 08             	mov    0x8(%ebp),%eax
  800824:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800827:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
  80082a:	eb 09                	jmp    800835 <strncmp+0x18>
		n--, p++, q++;
  80082c:	83 ea 01             	sub    $0x1,%edx
  80082f:	83 c0 01             	add    $0x1,%eax
  800832:	83 c1 01             	add    $0x1,%ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800835:	85 d2                	test   %edx,%edx
  800837:	74 15                	je     80084e <strncmp+0x31>
  800839:	0f b6 18             	movzbl (%eax),%ebx
  80083c:	84 db                	test   %bl,%bl
  80083e:	74 04                	je     800844 <strncmp+0x27>
  800840:	3a 19                	cmp    (%ecx),%bl
  800842:	74 e8                	je     80082c <strncmp+0xf>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800844:	0f b6 00             	movzbl (%eax),%eax
  800847:	0f b6 11             	movzbl (%ecx),%edx
  80084a:	29 d0                	sub    %edx,%eax
  80084c:	eb 05                	jmp    800853 <strncmp+0x36>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  80084e:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800853:	5b                   	pop    %ebx
  800854:	5d                   	pop    %ebp
  800855:	c3                   	ret    

00800856 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800856:	55                   	push   %ebp
  800857:	89 e5                	mov    %esp,%ebp
  800859:	8b 45 08             	mov    0x8(%ebp),%eax
  80085c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800860:	eb 07                	jmp    800869 <strchr+0x13>
		if (*s == c)
  800862:	38 ca                	cmp    %cl,%dl
  800864:	74 0f                	je     800875 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800866:	83 c0 01             	add    $0x1,%eax
  800869:	0f b6 10             	movzbl (%eax),%edx
  80086c:	84 d2                	test   %dl,%dl
  80086e:	75 f2                	jne    800862 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800870:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800875:	5d                   	pop    %ebp
  800876:	c3                   	ret    

00800877 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800877:	55                   	push   %ebp
  800878:	89 e5                	mov    %esp,%ebp
  80087a:	8b 45 08             	mov    0x8(%ebp),%eax
  80087d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800881:	eb 07                	jmp    80088a <strfind+0x13>
		if (*s == c)
  800883:	38 ca                	cmp    %cl,%dl
  800885:	74 0a                	je     800891 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800887:	83 c0 01             	add    $0x1,%eax
  80088a:	0f b6 10             	movzbl (%eax),%edx
  80088d:	84 d2                	test   %dl,%dl
  80088f:	75 f2                	jne    800883 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  800891:	5d                   	pop    %ebp
  800892:	c3                   	ret    

00800893 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800893:	55                   	push   %ebp
  800894:	89 e5                	mov    %esp,%ebp
  800896:	83 ec 0c             	sub    $0xc,%esp
  800899:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80089c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80089f:	89 7d fc             	mov    %edi,-0x4(%ebp)
  8008a2:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008a5:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008a8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008ab:	85 c9                	test   %ecx,%ecx
  8008ad:	74 30                	je     8008df <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008af:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008b5:	75 25                	jne    8008dc <memset+0x49>
  8008b7:	f6 c1 03             	test   $0x3,%cl
  8008ba:	75 20                	jne    8008dc <memset+0x49>
		c &= 0xFF;
  8008bc:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008bf:	89 d3                	mov    %edx,%ebx
  8008c1:	c1 e3 08             	shl    $0x8,%ebx
  8008c4:	89 d6                	mov    %edx,%esi
  8008c6:	c1 e6 18             	shl    $0x18,%esi
  8008c9:	89 d0                	mov    %edx,%eax
  8008cb:	c1 e0 10             	shl    $0x10,%eax
  8008ce:	09 f0                	or     %esi,%eax
  8008d0:	09 d0                	or     %edx,%eax
  8008d2:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  8008d4:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  8008d7:	fc                   	cld    
  8008d8:	f3 ab                	rep stos %eax,%es:(%edi)
  8008da:	eb 03                	jmp    8008df <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8008dc:	fc                   	cld    
  8008dd:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8008df:	89 f8                	mov    %edi,%eax
  8008e1:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8008e4:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8008e7:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8008ea:	89 ec                	mov    %ebp,%esp
  8008ec:	5d                   	pop    %ebp
  8008ed:	c3                   	ret    

008008ee <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8008ee:	55                   	push   %ebp
  8008ef:	89 e5                	mov    %esp,%ebp
  8008f1:	83 ec 08             	sub    $0x8,%esp
  8008f4:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8008f7:	89 7d fc             	mov    %edi,-0x4(%ebp)
  8008fa:	8b 45 08             	mov    0x8(%ebp),%eax
  8008fd:	8b 75 0c             	mov    0xc(%ebp),%esi
  800900:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800903:	39 c6                	cmp    %eax,%esi
  800905:	73 36                	jae    80093d <memmove+0x4f>
  800907:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  80090a:	39 d0                	cmp    %edx,%eax
  80090c:	73 2f                	jae    80093d <memmove+0x4f>
		s += n;
		d += n;
  80090e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800911:	f6 c2 03             	test   $0x3,%dl
  800914:	75 1b                	jne    800931 <memmove+0x43>
  800916:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80091c:	75 13                	jne    800931 <memmove+0x43>
  80091e:	f6 c1 03             	test   $0x3,%cl
  800921:	75 0e                	jne    800931 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800923:	83 ef 04             	sub    $0x4,%edi
  800926:	8d 72 fc             	lea    -0x4(%edx),%esi
  800929:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  80092c:	fd                   	std    
  80092d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80092f:	eb 09                	jmp    80093a <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800931:	83 ef 01             	sub    $0x1,%edi
  800934:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800937:	fd                   	std    
  800938:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  80093a:	fc                   	cld    
  80093b:	eb 20                	jmp    80095d <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80093d:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800943:	75 13                	jne    800958 <memmove+0x6a>
  800945:	a8 03                	test   $0x3,%al
  800947:	75 0f                	jne    800958 <memmove+0x6a>
  800949:	f6 c1 03             	test   $0x3,%cl
  80094c:	75 0a                	jne    800958 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  80094e:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800951:	89 c7                	mov    %eax,%edi
  800953:	fc                   	cld    
  800954:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800956:	eb 05                	jmp    80095d <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800958:	89 c7                	mov    %eax,%edi
  80095a:	fc                   	cld    
  80095b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  80095d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800960:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800963:	89 ec                	mov    %ebp,%esp
  800965:	5d                   	pop    %ebp
  800966:	c3                   	ret    

00800967 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800967:	55                   	push   %ebp
  800968:	89 e5                	mov    %esp,%ebp
  80096a:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  80096d:	8b 45 10             	mov    0x10(%ebp),%eax
  800970:	89 44 24 08          	mov    %eax,0x8(%esp)
  800974:	8b 45 0c             	mov    0xc(%ebp),%eax
  800977:	89 44 24 04          	mov    %eax,0x4(%esp)
  80097b:	8b 45 08             	mov    0x8(%ebp),%eax
  80097e:	89 04 24             	mov    %eax,(%esp)
  800981:	e8 68 ff ff ff       	call   8008ee <memmove>
}
  800986:	c9                   	leave  
  800987:	c3                   	ret    

00800988 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800988:	55                   	push   %ebp
  800989:	89 e5                	mov    %esp,%ebp
  80098b:	57                   	push   %edi
  80098c:	56                   	push   %esi
  80098d:	53                   	push   %ebx
  80098e:	8b 7d 08             	mov    0x8(%ebp),%edi
  800991:	8b 75 0c             	mov    0xc(%ebp),%esi
  800994:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800997:	ba 00 00 00 00       	mov    $0x0,%edx
  80099c:	eb 1a                	jmp    8009b8 <memcmp+0x30>
		if (*s1 != *s2)
  80099e:	0f b6 04 17          	movzbl (%edi,%edx,1),%eax
  8009a2:	83 c2 01             	add    $0x1,%edx
  8009a5:	0f b6 4c 16 ff       	movzbl -0x1(%esi,%edx,1),%ecx
  8009aa:	38 c8                	cmp    %cl,%al
  8009ac:	74 0a                	je     8009b8 <memcmp+0x30>
			return (int) *s1 - (int) *s2;
  8009ae:	0f b6 c0             	movzbl %al,%eax
  8009b1:	0f b6 c9             	movzbl %cl,%ecx
  8009b4:	29 c8                	sub    %ecx,%eax
  8009b6:	eb 09                	jmp    8009c1 <memcmp+0x39>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009b8:	39 da                	cmp    %ebx,%edx
  8009ba:	75 e2                	jne    80099e <memcmp+0x16>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009bc:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009c1:	5b                   	pop    %ebx
  8009c2:	5e                   	pop    %esi
  8009c3:	5f                   	pop    %edi
  8009c4:	5d                   	pop    %ebp
  8009c5:	c3                   	ret    

008009c6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009c6:	55                   	push   %ebp
  8009c7:	89 e5                	mov    %esp,%ebp
  8009c9:	8b 45 08             	mov    0x8(%ebp),%eax
  8009cc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  8009cf:	89 c2                	mov    %eax,%edx
  8009d1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  8009d4:	eb 07                	jmp    8009dd <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009d6:	38 08                	cmp    %cl,(%eax)
  8009d8:	74 07                	je     8009e1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009da:	83 c0 01             	add    $0x1,%eax
  8009dd:	39 d0                	cmp    %edx,%eax
  8009df:	72 f5                	jb     8009d6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009e1:	5d                   	pop    %ebp
  8009e2:	c3                   	ret    

008009e3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009e3:	55                   	push   %ebp
  8009e4:	89 e5                	mov    %esp,%ebp
  8009e6:	57                   	push   %edi
  8009e7:	56                   	push   %esi
  8009e8:	53                   	push   %ebx
  8009e9:	8b 55 08             	mov    0x8(%ebp),%edx
  8009ec:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009ef:	eb 03                	jmp    8009f4 <strtol+0x11>
		s++;
  8009f1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009f4:	0f b6 02             	movzbl (%edx),%eax
  8009f7:	3c 20                	cmp    $0x20,%al
  8009f9:	74 f6                	je     8009f1 <strtol+0xe>
  8009fb:	3c 09                	cmp    $0x9,%al
  8009fd:	74 f2                	je     8009f1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  8009ff:	3c 2b                	cmp    $0x2b,%al
  800a01:	75 0a                	jne    800a0d <strtol+0x2a>
		s++;
  800a03:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a06:	bf 00 00 00 00       	mov    $0x0,%edi
  800a0b:	eb 10                	jmp    800a1d <strtol+0x3a>
  800a0d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a12:	3c 2d                	cmp    $0x2d,%al
  800a14:	75 07                	jne    800a1d <strtol+0x3a>
		s++, neg = 1;
  800a16:	8d 52 01             	lea    0x1(%edx),%edx
  800a19:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a1d:	85 db                	test   %ebx,%ebx
  800a1f:	0f 94 c0             	sete   %al
  800a22:	74 05                	je     800a29 <strtol+0x46>
  800a24:	83 fb 10             	cmp    $0x10,%ebx
  800a27:	75 15                	jne    800a3e <strtol+0x5b>
  800a29:	80 3a 30             	cmpb   $0x30,(%edx)
  800a2c:	75 10                	jne    800a3e <strtol+0x5b>
  800a2e:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800a32:	75 0a                	jne    800a3e <strtol+0x5b>
		s += 2, base = 16;
  800a34:	83 c2 02             	add    $0x2,%edx
  800a37:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a3c:	eb 13                	jmp    800a51 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a3e:	84 c0                	test   %al,%al
  800a40:	74 0f                	je     800a51 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a42:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a47:	80 3a 30             	cmpb   $0x30,(%edx)
  800a4a:	75 05                	jne    800a51 <strtol+0x6e>
		s++, base = 8;
  800a4c:	83 c2 01             	add    $0x1,%edx
  800a4f:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800a51:	b8 00 00 00 00       	mov    $0x0,%eax
  800a56:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a58:	0f b6 0a             	movzbl (%edx),%ecx
  800a5b:	8d 59 d0             	lea    -0x30(%ecx),%ebx
  800a5e:	80 fb 09             	cmp    $0x9,%bl
  800a61:	77 08                	ja     800a6b <strtol+0x88>
			dig = *s - '0';
  800a63:	0f be c9             	movsbl %cl,%ecx
  800a66:	83 e9 30             	sub    $0x30,%ecx
  800a69:	eb 1e                	jmp    800a89 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800a6b:	8d 59 9f             	lea    -0x61(%ecx),%ebx
  800a6e:	80 fb 19             	cmp    $0x19,%bl
  800a71:	77 08                	ja     800a7b <strtol+0x98>
			dig = *s - 'a' + 10;
  800a73:	0f be c9             	movsbl %cl,%ecx
  800a76:	83 e9 57             	sub    $0x57,%ecx
  800a79:	eb 0e                	jmp    800a89 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800a7b:	8d 59 bf             	lea    -0x41(%ecx),%ebx
  800a7e:	80 fb 19             	cmp    $0x19,%bl
  800a81:	77 14                	ja     800a97 <strtol+0xb4>
			dig = *s - 'A' + 10;
  800a83:	0f be c9             	movsbl %cl,%ecx
  800a86:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800a89:	39 f1                	cmp    %esi,%ecx
  800a8b:	7d 0e                	jge    800a9b <strtol+0xb8>
			break;
		s++, val = (val * base) + dig;
  800a8d:	83 c2 01             	add    $0x1,%edx
  800a90:	0f af c6             	imul   %esi,%eax
  800a93:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800a95:	eb c1                	jmp    800a58 <strtol+0x75>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800a97:	89 c1                	mov    %eax,%ecx
  800a99:	eb 02                	jmp    800a9d <strtol+0xba>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800a9b:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800a9d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800aa1:	74 05                	je     800aa8 <strtol+0xc5>
		*endptr = (char *) s;
  800aa3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800aa6:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800aa8:	89 ca                	mov    %ecx,%edx
  800aaa:	f7 da                	neg    %edx
  800aac:	85 ff                	test   %edi,%edi
  800aae:	0f 45 c2             	cmovne %edx,%eax
}
  800ab1:	5b                   	pop    %ebx
  800ab2:	5e                   	pop    %esi
  800ab3:	5f                   	pop    %edi
  800ab4:	5d                   	pop    %ebp
  800ab5:	c3                   	ret    
	...

00800ab8 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800ab8:	55                   	push   %ebp
  800ab9:	89 e5                	mov    %esp,%ebp
  800abb:	83 ec 0c             	sub    $0xc,%esp
  800abe:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800ac1:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800ac4:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ac7:	b8 00 00 00 00       	mov    $0x0,%eax
  800acc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800acf:	8b 55 08             	mov    0x8(%ebp),%edx
  800ad2:	89 c3                	mov    %eax,%ebx
  800ad4:	89 c7                	mov    %eax,%edi
  800ad6:	89 c6                	mov    %eax,%esi
  800ad8:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800ada:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800add:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800ae0:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800ae3:	89 ec                	mov    %ebp,%esp
  800ae5:	5d                   	pop    %ebp
  800ae6:	c3                   	ret    

00800ae7 <sys_cgetc>:

int
sys_cgetc(void)
{
  800ae7:	55                   	push   %ebp
  800ae8:	89 e5                	mov    %esp,%ebp
  800aea:	83 ec 0c             	sub    $0xc,%esp
  800aed:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800af0:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800af3:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800af6:	ba 00 00 00 00       	mov    $0x0,%edx
  800afb:	b8 01 00 00 00       	mov    $0x1,%eax
  800b00:	89 d1                	mov    %edx,%ecx
  800b02:	89 d3                	mov    %edx,%ebx
  800b04:	89 d7                	mov    %edx,%edi
  800b06:	89 d6                	mov    %edx,%esi
  800b08:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800b0a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800b0d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800b10:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800b13:	89 ec                	mov    %ebp,%esp
  800b15:	5d                   	pop    %ebp
  800b16:	c3                   	ret    

00800b17 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800b17:	55                   	push   %ebp
  800b18:	89 e5                	mov    %esp,%ebp
  800b1a:	83 ec 38             	sub    $0x38,%esp
  800b1d:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800b20:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800b23:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b26:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b2b:	b8 03 00 00 00       	mov    $0x3,%eax
  800b30:	8b 55 08             	mov    0x8(%ebp),%edx
  800b33:	89 cb                	mov    %ecx,%ebx
  800b35:	89 cf                	mov    %ecx,%edi
  800b37:	89 ce                	mov    %ecx,%esi
  800b39:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800b3b:	85 c0                	test   %eax,%eax
  800b3d:	7e 28                	jle    800b67 <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800b3f:	89 44 24 10          	mov    %eax,0x10(%esp)
  800b43:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800b4a:	00 
  800b4b:	c7 44 24 08 d4 10 80 	movl   $0x8010d4,0x8(%esp)
  800b52:	00 
  800b53:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800b5a:	00 
  800b5b:	c7 04 24 f1 10 80 00 	movl   $0x8010f1,(%esp)
  800b62:	e8 3d 00 00 00       	call   800ba4 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800b67:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800b6a:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800b6d:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800b70:	89 ec                	mov    %ebp,%esp
  800b72:	5d                   	pop    %ebp
  800b73:	c3                   	ret    

00800b74 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b74:	55                   	push   %ebp
  800b75:	89 e5                	mov    %esp,%ebp
  800b77:	83 ec 0c             	sub    $0xc,%esp
  800b7a:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800b7d:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800b80:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b83:	ba 00 00 00 00       	mov    $0x0,%edx
  800b88:	b8 02 00 00 00       	mov    $0x2,%eax
  800b8d:	89 d1                	mov    %edx,%ecx
  800b8f:	89 d3                	mov    %edx,%ebx
  800b91:	89 d7                	mov    %edx,%edi
  800b93:	89 d6                	mov    %edx,%esi
  800b95:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b97:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800b9a:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800b9d:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800ba0:	89 ec                	mov    %ebp,%esp
  800ba2:	5d                   	pop    %ebp
  800ba3:	c3                   	ret    

00800ba4 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800ba4:	55                   	push   %ebp
  800ba5:	89 e5                	mov    %esp,%ebp
  800ba7:	56                   	push   %esi
  800ba8:	53                   	push   %ebx
  800ba9:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800bac:	8d 75 14             	lea    0x14(%ebp),%esi

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800baf:	8b 1d 00 20 80 00    	mov    0x802000,%ebx
  800bb5:	e8 ba ff ff ff       	call   800b74 <sys_getenvid>
  800bba:	8b 55 0c             	mov    0xc(%ebp),%edx
  800bbd:	89 54 24 10          	mov    %edx,0x10(%esp)
  800bc1:	8b 55 08             	mov    0x8(%ebp),%edx
  800bc4:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800bc8:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800bcc:	89 44 24 04          	mov    %eax,0x4(%esp)
  800bd0:	c7 04 24 00 11 80 00 	movl   $0x801100,(%esp)
  800bd7:	e8 83 f5 ff ff       	call   80015f <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800bdc:	89 74 24 04          	mov    %esi,0x4(%esp)
  800be0:	8b 45 10             	mov    0x10(%ebp),%eax
  800be3:	89 04 24             	mov    %eax,(%esp)
  800be6:	e8 13 f5 ff ff       	call   8000fe <vcprintf>
	cprintf("\n");
  800beb:	c7 04 24 c4 0e 80 00 	movl   $0x800ec4,(%esp)
  800bf2:	e8 68 f5 ff ff       	call   80015f <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800bf7:	cc                   	int3   
  800bf8:	eb fd                	jmp    800bf7 <_panic+0x53>
  800bfa:	00 00                	add    %al,(%eax)
  800bfc:	00 00                	add    %al,(%eax)
	...

00800c00 <__udivdi3>:
  800c00:	83 ec 1c             	sub    $0x1c,%esp
  800c03:	89 7c 24 14          	mov    %edi,0x14(%esp)
  800c07:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
  800c0b:	8b 44 24 20          	mov    0x20(%esp),%eax
  800c0f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  800c13:	89 74 24 10          	mov    %esi,0x10(%esp)
  800c17:	8b 74 24 24          	mov    0x24(%esp),%esi
  800c1b:	85 ff                	test   %edi,%edi
  800c1d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  800c21:	89 44 24 08          	mov    %eax,0x8(%esp)
  800c25:	89 cd                	mov    %ecx,%ebp
  800c27:	89 44 24 04          	mov    %eax,0x4(%esp)
  800c2b:	75 33                	jne    800c60 <__udivdi3+0x60>
  800c2d:	39 f1                	cmp    %esi,%ecx
  800c2f:	77 57                	ja     800c88 <__udivdi3+0x88>
  800c31:	85 c9                	test   %ecx,%ecx
  800c33:	75 0b                	jne    800c40 <__udivdi3+0x40>
  800c35:	b8 01 00 00 00       	mov    $0x1,%eax
  800c3a:	31 d2                	xor    %edx,%edx
  800c3c:	f7 f1                	div    %ecx
  800c3e:	89 c1                	mov    %eax,%ecx
  800c40:	89 f0                	mov    %esi,%eax
  800c42:	31 d2                	xor    %edx,%edx
  800c44:	f7 f1                	div    %ecx
  800c46:	89 c6                	mov    %eax,%esi
  800c48:	8b 44 24 04          	mov    0x4(%esp),%eax
  800c4c:	f7 f1                	div    %ecx
  800c4e:	89 f2                	mov    %esi,%edx
  800c50:	8b 74 24 10          	mov    0x10(%esp),%esi
  800c54:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800c58:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800c5c:	83 c4 1c             	add    $0x1c,%esp
  800c5f:	c3                   	ret    
  800c60:	31 d2                	xor    %edx,%edx
  800c62:	31 c0                	xor    %eax,%eax
  800c64:	39 f7                	cmp    %esi,%edi
  800c66:	77 e8                	ja     800c50 <__udivdi3+0x50>
  800c68:	0f bd cf             	bsr    %edi,%ecx
  800c6b:	83 f1 1f             	xor    $0x1f,%ecx
  800c6e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800c72:	75 2c                	jne    800ca0 <__udivdi3+0xa0>
  800c74:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
  800c78:	76 04                	jbe    800c7e <__udivdi3+0x7e>
  800c7a:	39 f7                	cmp    %esi,%edi
  800c7c:	73 d2                	jae    800c50 <__udivdi3+0x50>
  800c7e:	31 d2                	xor    %edx,%edx
  800c80:	b8 01 00 00 00       	mov    $0x1,%eax
  800c85:	eb c9                	jmp    800c50 <__udivdi3+0x50>
  800c87:	90                   	nop
  800c88:	89 f2                	mov    %esi,%edx
  800c8a:	f7 f1                	div    %ecx
  800c8c:	31 d2                	xor    %edx,%edx
  800c8e:	8b 74 24 10          	mov    0x10(%esp),%esi
  800c92:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800c96:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800c9a:	83 c4 1c             	add    $0x1c,%esp
  800c9d:	c3                   	ret    
  800c9e:	66 90                	xchg   %ax,%ax
  800ca0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800ca5:	b8 20 00 00 00       	mov    $0x20,%eax
  800caa:	89 ea                	mov    %ebp,%edx
  800cac:	2b 44 24 04          	sub    0x4(%esp),%eax
  800cb0:	d3 e7                	shl    %cl,%edi
  800cb2:	89 c1                	mov    %eax,%ecx
  800cb4:	d3 ea                	shr    %cl,%edx
  800cb6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800cbb:	09 fa                	or     %edi,%edx
  800cbd:	89 f7                	mov    %esi,%edi
  800cbf:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800cc3:	89 f2                	mov    %esi,%edx
  800cc5:	8b 74 24 08          	mov    0x8(%esp),%esi
  800cc9:	d3 e5                	shl    %cl,%ebp
  800ccb:	89 c1                	mov    %eax,%ecx
  800ccd:	d3 ef                	shr    %cl,%edi
  800ccf:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800cd4:	d3 e2                	shl    %cl,%edx
  800cd6:	89 c1                	mov    %eax,%ecx
  800cd8:	d3 ee                	shr    %cl,%esi
  800cda:	09 d6                	or     %edx,%esi
  800cdc:	89 fa                	mov    %edi,%edx
  800cde:	89 f0                	mov    %esi,%eax
  800ce0:	f7 74 24 0c          	divl   0xc(%esp)
  800ce4:	89 d7                	mov    %edx,%edi
  800ce6:	89 c6                	mov    %eax,%esi
  800ce8:	f7 e5                	mul    %ebp
  800cea:	39 d7                	cmp    %edx,%edi
  800cec:	72 22                	jb     800d10 <__udivdi3+0x110>
  800cee:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  800cf2:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800cf7:	d3 e5                	shl    %cl,%ebp
  800cf9:	39 c5                	cmp    %eax,%ebp
  800cfb:	73 04                	jae    800d01 <__udivdi3+0x101>
  800cfd:	39 d7                	cmp    %edx,%edi
  800cff:	74 0f                	je     800d10 <__udivdi3+0x110>
  800d01:	89 f0                	mov    %esi,%eax
  800d03:	31 d2                	xor    %edx,%edx
  800d05:	e9 46 ff ff ff       	jmp    800c50 <__udivdi3+0x50>
  800d0a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800d10:	8d 46 ff             	lea    -0x1(%esi),%eax
  800d13:	31 d2                	xor    %edx,%edx
  800d15:	8b 74 24 10          	mov    0x10(%esp),%esi
  800d19:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800d1d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800d21:	83 c4 1c             	add    $0x1c,%esp
  800d24:	c3                   	ret    
	...

00800d30 <__umoddi3>:
  800d30:	83 ec 1c             	sub    $0x1c,%esp
  800d33:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  800d37:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
  800d3b:	8b 44 24 20          	mov    0x20(%esp),%eax
  800d3f:	89 74 24 10          	mov    %esi,0x10(%esp)
  800d43:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  800d47:	8b 74 24 24          	mov    0x24(%esp),%esi
  800d4b:	85 ed                	test   %ebp,%ebp
  800d4d:	89 7c 24 14          	mov    %edi,0x14(%esp)
  800d51:	89 44 24 08          	mov    %eax,0x8(%esp)
  800d55:	89 cf                	mov    %ecx,%edi
  800d57:	89 04 24             	mov    %eax,(%esp)
  800d5a:	89 f2                	mov    %esi,%edx
  800d5c:	75 1a                	jne    800d78 <__umoddi3+0x48>
  800d5e:	39 f1                	cmp    %esi,%ecx
  800d60:	76 4e                	jbe    800db0 <__umoddi3+0x80>
  800d62:	f7 f1                	div    %ecx
  800d64:	89 d0                	mov    %edx,%eax
  800d66:	31 d2                	xor    %edx,%edx
  800d68:	8b 74 24 10          	mov    0x10(%esp),%esi
  800d6c:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800d70:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800d74:	83 c4 1c             	add    $0x1c,%esp
  800d77:	c3                   	ret    
  800d78:	39 f5                	cmp    %esi,%ebp
  800d7a:	77 54                	ja     800dd0 <__umoddi3+0xa0>
  800d7c:	0f bd c5             	bsr    %ebp,%eax
  800d7f:	83 f0 1f             	xor    $0x1f,%eax
  800d82:	89 44 24 04          	mov    %eax,0x4(%esp)
  800d86:	75 60                	jne    800de8 <__umoddi3+0xb8>
  800d88:	3b 0c 24             	cmp    (%esp),%ecx
  800d8b:	0f 87 07 01 00 00    	ja     800e98 <__umoddi3+0x168>
  800d91:	89 f2                	mov    %esi,%edx
  800d93:	8b 34 24             	mov    (%esp),%esi
  800d96:	29 ce                	sub    %ecx,%esi
  800d98:	19 ea                	sbb    %ebp,%edx
  800d9a:	89 34 24             	mov    %esi,(%esp)
  800d9d:	8b 04 24             	mov    (%esp),%eax
  800da0:	8b 74 24 10          	mov    0x10(%esp),%esi
  800da4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800da8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800dac:	83 c4 1c             	add    $0x1c,%esp
  800daf:	c3                   	ret    
  800db0:	85 c9                	test   %ecx,%ecx
  800db2:	75 0b                	jne    800dbf <__umoddi3+0x8f>
  800db4:	b8 01 00 00 00       	mov    $0x1,%eax
  800db9:	31 d2                	xor    %edx,%edx
  800dbb:	f7 f1                	div    %ecx
  800dbd:	89 c1                	mov    %eax,%ecx
  800dbf:	89 f0                	mov    %esi,%eax
  800dc1:	31 d2                	xor    %edx,%edx
  800dc3:	f7 f1                	div    %ecx
  800dc5:	8b 04 24             	mov    (%esp),%eax
  800dc8:	f7 f1                	div    %ecx
  800dca:	eb 98                	jmp    800d64 <__umoddi3+0x34>
  800dcc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800dd0:	89 f2                	mov    %esi,%edx
  800dd2:	8b 74 24 10          	mov    0x10(%esp),%esi
  800dd6:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800dda:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800dde:	83 c4 1c             	add    $0x1c,%esp
  800de1:	c3                   	ret    
  800de2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800de8:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800ded:	89 e8                	mov    %ebp,%eax
  800def:	bd 20 00 00 00       	mov    $0x20,%ebp
  800df4:	2b 6c 24 04          	sub    0x4(%esp),%ebp
  800df8:	89 fa                	mov    %edi,%edx
  800dfa:	d3 e0                	shl    %cl,%eax
  800dfc:	89 e9                	mov    %ebp,%ecx
  800dfe:	d3 ea                	shr    %cl,%edx
  800e00:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800e05:	09 c2                	or     %eax,%edx
  800e07:	8b 44 24 08          	mov    0x8(%esp),%eax
  800e0b:	89 14 24             	mov    %edx,(%esp)
  800e0e:	89 f2                	mov    %esi,%edx
  800e10:	d3 e7                	shl    %cl,%edi
  800e12:	89 e9                	mov    %ebp,%ecx
  800e14:	d3 ea                	shr    %cl,%edx
  800e16:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800e1b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800e1f:	d3 e6                	shl    %cl,%esi
  800e21:	89 e9                	mov    %ebp,%ecx
  800e23:	d3 e8                	shr    %cl,%eax
  800e25:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800e2a:	09 f0                	or     %esi,%eax
  800e2c:	8b 74 24 08          	mov    0x8(%esp),%esi
  800e30:	f7 34 24             	divl   (%esp)
  800e33:	d3 e6                	shl    %cl,%esi
  800e35:	89 74 24 08          	mov    %esi,0x8(%esp)
  800e39:	89 d6                	mov    %edx,%esi
  800e3b:	f7 e7                	mul    %edi
  800e3d:	39 d6                	cmp    %edx,%esi
  800e3f:	89 c1                	mov    %eax,%ecx
  800e41:	89 d7                	mov    %edx,%edi
  800e43:	72 3f                	jb     800e84 <__umoddi3+0x154>
  800e45:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800e49:	72 35                	jb     800e80 <__umoddi3+0x150>
  800e4b:	8b 44 24 08          	mov    0x8(%esp),%eax
  800e4f:	29 c8                	sub    %ecx,%eax
  800e51:	19 fe                	sbb    %edi,%esi
  800e53:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800e58:	89 f2                	mov    %esi,%edx
  800e5a:	d3 e8                	shr    %cl,%eax
  800e5c:	89 e9                	mov    %ebp,%ecx
  800e5e:	d3 e2                	shl    %cl,%edx
  800e60:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800e65:	09 d0                	or     %edx,%eax
  800e67:	89 f2                	mov    %esi,%edx
  800e69:	d3 ea                	shr    %cl,%edx
  800e6b:	8b 74 24 10          	mov    0x10(%esp),%esi
  800e6f:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800e73:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800e77:	83 c4 1c             	add    $0x1c,%esp
  800e7a:	c3                   	ret    
  800e7b:	90                   	nop
  800e7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e80:	39 d6                	cmp    %edx,%esi
  800e82:	75 c7                	jne    800e4b <__umoddi3+0x11b>
  800e84:	89 d7                	mov    %edx,%edi
  800e86:	89 c1                	mov    %eax,%ecx
  800e88:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
  800e8c:	1b 3c 24             	sbb    (%esp),%edi
  800e8f:	eb ba                	jmp    800e4b <__umoddi3+0x11b>
  800e91:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800e98:	39 f5                	cmp    %esi,%ebp
  800e9a:	0f 82 f1 fe ff ff    	jb     800d91 <__umoddi3+0x61>
  800ea0:	e9 f8 fe ff ff       	jmp    800d9d <__umoddi3+0x6d>
