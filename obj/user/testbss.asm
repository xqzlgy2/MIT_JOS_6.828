
obj/user/testbss:     file format elf32-i386


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
  80002c:	e8 cf 00 00 00       	call   800100 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
	...

00800034 <umain>:

uint32_t bigarray[ARRAYSIZE];

void
umain(int argc, char **argv)
{
  800034:	55                   	push   %ebp
  800035:	89 e5                	mov    %esp,%ebp
  800037:	83 ec 18             	sub    $0x18,%esp
	int i;

	cprintf("Making sure bss works right...\n");
  80003a:	c7 04 24 58 0f 80 00 	movl   $0x800f58,(%esp)
  800041:	e8 1d 02 00 00       	call   800263 <cprintf>
	for (i = 0; i < ARRAYSIZE; i++)
  800046:	b8 00 00 00 00       	mov    $0x0,%eax
		if (bigarray[i] != 0)
  80004b:	83 3c 85 20 20 80 00 	cmpl   $0x0,0x802020(,%eax,4)
  800052:	00 
  800053:	74 20                	je     800075 <umain+0x41>
			panic("bigarray[%d] isn't cleared!\n", i);
  800055:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800059:	c7 44 24 08 d3 0f 80 	movl   $0x800fd3,0x8(%esp)
  800060:	00 
  800061:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
  800068:	00 
  800069:	c7 04 24 f0 0f 80 00 	movl   $0x800ff0,(%esp)
  800070:	e8 f3 00 00 00       	call   800168 <_panic>
umain(int argc, char **argv)
{
	int i;

	cprintf("Making sure bss works right...\n");
	for (i = 0; i < ARRAYSIZE; i++)
  800075:	83 c0 01             	add    $0x1,%eax
  800078:	3d 00 00 10 00       	cmp    $0x100000,%eax
  80007d:	75 cc                	jne    80004b <umain+0x17>
  80007f:	b8 00 00 00 00       	mov    $0x0,%eax
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
		bigarray[i] = i;
  800084:	89 04 85 20 20 80 00 	mov    %eax,0x802020(,%eax,4)

	cprintf("Making sure bss works right...\n");
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
  80008b:	83 c0 01             	add    $0x1,%eax
  80008e:	3d 00 00 10 00       	cmp    $0x100000,%eax
  800093:	75 ef                	jne    800084 <umain+0x50>
  800095:	b8 00 00 00 00       	mov    $0x0,%eax
		bigarray[i] = i;
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != i)
  80009a:	39 04 85 20 20 80 00 	cmp    %eax,0x802020(,%eax,4)
  8000a1:	74 20                	je     8000c3 <umain+0x8f>
			panic("bigarray[%d] didn't hold its value!\n", i);
  8000a3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8000a7:	c7 44 24 08 78 0f 80 	movl   $0x800f78,0x8(%esp)
  8000ae:	00 
  8000af:	c7 44 24 04 16 00 00 	movl   $0x16,0x4(%esp)
  8000b6:	00 
  8000b7:	c7 04 24 f0 0f 80 00 	movl   $0x800ff0,(%esp)
  8000be:	e8 a5 00 00 00       	call   800168 <_panic>
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
		bigarray[i] = i;
	for (i = 0; i < ARRAYSIZE; i++)
  8000c3:	83 c0 01             	add    $0x1,%eax
  8000c6:	3d 00 00 10 00       	cmp    $0x100000,%eax
  8000cb:	75 cd                	jne    80009a <umain+0x66>
		if (bigarray[i] != i)
			panic("bigarray[%d] didn't hold its value!\n", i);

	cprintf("Yes, good.  Now doing a wild write off the end...\n");
  8000cd:	c7 04 24 a0 0f 80 00 	movl   $0x800fa0,(%esp)
  8000d4:	e8 8a 01 00 00       	call   800263 <cprintf>
	bigarray[ARRAYSIZE+1024] = 0;
  8000d9:	c7 05 20 30 c0 00 00 	movl   $0x0,0xc03020
  8000e0:	00 00 00 
	panic("SHOULD HAVE TRAPPED!!!");
  8000e3:	c7 44 24 08 ff 0f 80 	movl   $0x800fff,0x8(%esp)
  8000ea:	00 
  8000eb:	c7 44 24 04 1a 00 00 	movl   $0x1a,0x4(%esp)
  8000f2:	00 
  8000f3:	c7 04 24 f0 0f 80 00 	movl   $0x800ff0,(%esp)
  8000fa:	e8 69 00 00 00       	call   800168 <_panic>
	...

00800100 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800100:	55                   	push   %ebp
  800101:	89 e5                	mov    %esp,%ebp
  800103:	83 ec 18             	sub    $0x18,%esp
  800106:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  800109:	89 75 fc             	mov    %esi,-0x4(%ebp)
  80010c:	8b 75 08             	mov    0x8(%ebp),%esi
  80010f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = &envs[ENVX(sys_getenvid())];
  800112:	e8 5d 0b 00 00       	call   800c74 <sys_getenvid>
  800117:	25 ff 03 00 00       	and    $0x3ff,%eax
  80011c:	8d 04 40             	lea    (%eax,%eax,2),%eax
  80011f:	c1 e0 05             	shl    $0x5,%eax
  800122:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800127:	a3 20 20 c0 00       	mov    %eax,0xc02020

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80012c:	85 f6                	test   %esi,%esi
  80012e:	7e 07                	jle    800137 <libmain+0x37>
		binaryname = argv[0];
  800130:	8b 03                	mov    (%ebx),%eax
  800132:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800137:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80013b:	89 34 24             	mov    %esi,(%esp)
  80013e:	e8 f1 fe ff ff       	call   800034 <umain>

	// exit gracefully
	exit();
  800143:	e8 0c 00 00 00       	call   800154 <exit>
}
  800148:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  80014b:	8b 75 fc             	mov    -0x4(%ebp),%esi
  80014e:	89 ec                	mov    %ebp,%esp
  800150:	5d                   	pop    %ebp
  800151:	c3                   	ret    
	...

00800154 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800154:	55                   	push   %ebp
  800155:	89 e5                	mov    %esp,%ebp
  800157:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  80015a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800161:	e8 b1 0a 00 00       	call   800c17 <sys_env_destroy>
}
  800166:	c9                   	leave  
  800167:	c3                   	ret    

00800168 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800168:	55                   	push   %ebp
  800169:	89 e5                	mov    %esp,%ebp
  80016b:	56                   	push   %esi
  80016c:	53                   	push   %ebx
  80016d:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800170:	8d 75 14             	lea    0x14(%ebp),%esi

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800173:	8b 1d 00 20 80 00    	mov    0x802000,%ebx
  800179:	e8 f6 0a 00 00       	call   800c74 <sys_getenvid>
  80017e:	8b 55 0c             	mov    0xc(%ebp),%edx
  800181:	89 54 24 10          	mov    %edx,0x10(%esp)
  800185:	8b 55 08             	mov    0x8(%ebp),%edx
  800188:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80018c:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800190:	89 44 24 04          	mov    %eax,0x4(%esp)
  800194:	c7 04 24 20 10 80 00 	movl   $0x801020,(%esp)
  80019b:	e8 c3 00 00 00       	call   800263 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8001a0:	89 74 24 04          	mov    %esi,0x4(%esp)
  8001a4:	8b 45 10             	mov    0x10(%ebp),%eax
  8001a7:	89 04 24             	mov    %eax,(%esp)
  8001aa:	e8 53 00 00 00       	call   800202 <vcprintf>
	cprintf("\n");
  8001af:	c7 04 24 ee 0f 80 00 	movl   $0x800fee,(%esp)
  8001b6:	e8 a8 00 00 00       	call   800263 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8001bb:	cc                   	int3   
  8001bc:	eb fd                	jmp    8001bb <_panic+0x53>
	...

008001c0 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8001c0:	55                   	push   %ebp
  8001c1:	89 e5                	mov    %esp,%ebp
  8001c3:	53                   	push   %ebx
  8001c4:	83 ec 14             	sub    $0x14,%esp
  8001c7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001ca:	8b 03                	mov    (%ebx),%eax
  8001cc:	8b 55 08             	mov    0x8(%ebp),%edx
  8001cf:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  8001d3:	83 c0 01             	add    $0x1,%eax
  8001d6:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  8001d8:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001dd:	75 19                	jne    8001f8 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8001df:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8001e6:	00 
  8001e7:	8d 43 08             	lea    0x8(%ebx),%eax
  8001ea:	89 04 24             	mov    %eax,(%esp)
  8001ed:	e8 c6 09 00 00       	call   800bb8 <sys_cputs>
		b->idx = 0;
  8001f2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8001f8:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001fc:	83 c4 14             	add    $0x14,%esp
  8001ff:	5b                   	pop    %ebx
  800200:	5d                   	pop    %ebp
  800201:	c3                   	ret    

00800202 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800202:	55                   	push   %ebp
  800203:	89 e5                	mov    %esp,%ebp
  800205:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  80020b:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800212:	00 00 00 
	b.cnt = 0;
  800215:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80021c:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80021f:	8b 45 0c             	mov    0xc(%ebp),%eax
  800222:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800226:	8b 45 08             	mov    0x8(%ebp),%eax
  800229:	89 44 24 08          	mov    %eax,0x8(%esp)
  80022d:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800233:	89 44 24 04          	mov    %eax,0x4(%esp)
  800237:	c7 04 24 c0 01 80 00 	movl   $0x8001c0,(%esp)
  80023e:	e8 8a 01 00 00       	call   8003cd <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800243:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800249:	89 44 24 04          	mov    %eax,0x4(%esp)
  80024d:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800253:	89 04 24             	mov    %eax,(%esp)
  800256:	e8 5d 09 00 00       	call   800bb8 <sys_cputs>

	return b.cnt;
}
  80025b:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800261:	c9                   	leave  
  800262:	c3                   	ret    

00800263 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800263:	55                   	push   %ebp
  800264:	89 e5                	mov    %esp,%ebp
  800266:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800269:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80026c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800270:	8b 45 08             	mov    0x8(%ebp),%eax
  800273:	89 04 24             	mov    %eax,(%esp)
  800276:	e8 87 ff ff ff       	call   800202 <vcprintf>
	va_end(ap);

	return cnt;
}
  80027b:	c9                   	leave  
  80027c:	c3                   	ret    
  80027d:	00 00                	add    %al,(%eax)
	...

00800280 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800280:	55                   	push   %ebp
  800281:	89 e5                	mov    %esp,%ebp
  800283:	57                   	push   %edi
  800284:	56                   	push   %esi
  800285:	53                   	push   %ebx
  800286:	83 ec 3c             	sub    $0x3c,%esp
  800289:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80028c:	89 d7                	mov    %edx,%edi
  80028e:	8b 45 08             	mov    0x8(%ebp),%eax
  800291:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800294:	8b 45 0c             	mov    0xc(%ebp),%eax
  800297:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80029a:	8b 5d 14             	mov    0x14(%ebp),%ebx
  80029d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8002a0:	85 c0                	test   %eax,%eax
  8002a2:	75 08                	jne    8002ac <printnum+0x2c>
  8002a4:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8002a7:	39 45 10             	cmp    %eax,0x10(%ebp)
  8002aa:	77 59                	ja     800305 <printnum+0x85>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8002ac:	89 74 24 10          	mov    %esi,0x10(%esp)
  8002b0:	83 eb 01             	sub    $0x1,%ebx
  8002b3:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  8002b7:	8b 45 10             	mov    0x10(%ebp),%eax
  8002ba:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002be:	8b 5c 24 08          	mov    0x8(%esp),%ebx
  8002c2:	8b 74 24 0c          	mov    0xc(%esp),%esi
  8002c6:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8002cd:	00 
  8002ce:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8002d1:	89 04 24             	mov    %eax,(%esp)
  8002d4:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8002d7:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002db:	e8 d0 09 00 00       	call   800cb0 <__udivdi3>
  8002e0:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8002e4:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8002e8:	89 04 24             	mov    %eax,(%esp)
  8002eb:	89 54 24 04          	mov    %edx,0x4(%esp)
  8002ef:	89 fa                	mov    %edi,%edx
  8002f1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8002f4:	e8 87 ff ff ff       	call   800280 <printnum>
  8002f9:	eb 11                	jmp    80030c <printnum+0x8c>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8002fb:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8002ff:	89 34 24             	mov    %esi,(%esp)
  800302:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800305:	83 eb 01             	sub    $0x1,%ebx
  800308:	85 db                	test   %ebx,%ebx
  80030a:	7f ef                	jg     8002fb <printnum+0x7b>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80030c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800310:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800314:	8b 45 10             	mov    0x10(%ebp),%eax
  800317:	89 44 24 08          	mov    %eax,0x8(%esp)
  80031b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800322:	00 
  800323:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800326:	89 04 24             	mov    %eax,(%esp)
  800329:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80032c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800330:	e8 ab 0a 00 00       	call   800de0 <__umoddi3>
  800335:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800339:	0f be 80 44 10 80 00 	movsbl 0x801044(%eax),%eax
  800340:	89 04 24             	mov    %eax,(%esp)
  800343:	ff 55 e4             	call   *-0x1c(%ebp)
}
  800346:	83 c4 3c             	add    $0x3c,%esp
  800349:	5b                   	pop    %ebx
  80034a:	5e                   	pop    %esi
  80034b:	5f                   	pop    %edi
  80034c:	5d                   	pop    %ebp
  80034d:	c3                   	ret    

0080034e <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80034e:	55                   	push   %ebp
  80034f:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800351:	83 fa 01             	cmp    $0x1,%edx
  800354:	7e 0e                	jle    800364 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800356:	8b 10                	mov    (%eax),%edx
  800358:	8d 4a 08             	lea    0x8(%edx),%ecx
  80035b:	89 08                	mov    %ecx,(%eax)
  80035d:	8b 02                	mov    (%edx),%eax
  80035f:	8b 52 04             	mov    0x4(%edx),%edx
  800362:	eb 22                	jmp    800386 <getuint+0x38>
	else if (lflag)
  800364:	85 d2                	test   %edx,%edx
  800366:	74 10                	je     800378 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800368:	8b 10                	mov    (%eax),%edx
  80036a:	8d 4a 04             	lea    0x4(%edx),%ecx
  80036d:	89 08                	mov    %ecx,(%eax)
  80036f:	8b 02                	mov    (%edx),%eax
  800371:	ba 00 00 00 00       	mov    $0x0,%edx
  800376:	eb 0e                	jmp    800386 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800378:	8b 10                	mov    (%eax),%edx
  80037a:	8d 4a 04             	lea    0x4(%edx),%ecx
  80037d:	89 08                	mov    %ecx,(%eax)
  80037f:	8b 02                	mov    (%edx),%eax
  800381:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800386:	5d                   	pop    %ebp
  800387:	c3                   	ret    

00800388 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800388:	55                   	push   %ebp
  800389:	89 e5                	mov    %esp,%ebp
  80038b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80038e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800392:	8b 10                	mov    (%eax),%edx
  800394:	3b 50 04             	cmp    0x4(%eax),%edx
  800397:	73 0a                	jae    8003a3 <sprintputch+0x1b>
		*b->buf++ = ch;
  800399:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80039c:	88 0a                	mov    %cl,(%edx)
  80039e:	83 c2 01             	add    $0x1,%edx
  8003a1:	89 10                	mov    %edx,(%eax)
}
  8003a3:	5d                   	pop    %ebp
  8003a4:	c3                   	ret    

008003a5 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8003a5:	55                   	push   %ebp
  8003a6:	89 e5                	mov    %esp,%ebp
  8003a8:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8003ab:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8003ae:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8003b2:	8b 45 10             	mov    0x10(%ebp),%eax
  8003b5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8003b9:	8b 45 0c             	mov    0xc(%ebp),%eax
  8003bc:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003c0:	8b 45 08             	mov    0x8(%ebp),%eax
  8003c3:	89 04 24             	mov    %eax,(%esp)
  8003c6:	e8 02 00 00 00       	call   8003cd <vprintfmt>
	va_end(ap);
}
  8003cb:	c9                   	leave  
  8003cc:	c3                   	ret    

008003cd <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8003cd:	55                   	push   %ebp
  8003ce:	89 e5                	mov    %esp,%ebp
  8003d0:	57                   	push   %edi
  8003d1:	56                   	push   %esi
  8003d2:	53                   	push   %ebx
  8003d3:	83 ec 4c             	sub    $0x4c,%esp
  8003d6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8003d9:	8b 75 10             	mov    0x10(%ebp),%esi
  8003dc:	eb 12                	jmp    8003f0 <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8003de:	85 c0                	test   %eax,%eax
  8003e0:	0f 84 9f 03 00 00    	je     800785 <vprintfmt+0x3b8>
				return;
			putch(ch, putdat);
  8003e6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8003ea:	89 04 24             	mov    %eax,(%esp)
  8003ed:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8003f0:	0f b6 06             	movzbl (%esi),%eax
  8003f3:	83 c6 01             	add    $0x1,%esi
  8003f6:	83 f8 25             	cmp    $0x25,%eax
  8003f9:	75 e3                	jne    8003de <vprintfmt+0x11>
  8003fb:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  8003ff:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  800406:	bf ff ff ff ff       	mov    $0xffffffff,%edi
  80040b:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
  800412:	b9 00 00 00 00       	mov    $0x0,%ecx
  800417:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80041a:	eb 2b                	jmp    800447 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80041c:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  80041f:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  800423:	eb 22                	jmp    800447 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800425:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800428:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  80042c:	eb 19                	jmp    800447 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80042e:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  800431:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  800438:	eb 0d                	jmp    800447 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  80043a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80043d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800440:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800447:	0f b6 16             	movzbl (%esi),%edx
  80044a:	0f b6 c2             	movzbl %dl,%eax
  80044d:	8d 7e 01             	lea    0x1(%esi),%edi
  800450:	89 7d e0             	mov    %edi,-0x20(%ebp)
  800453:	83 ea 23             	sub    $0x23,%edx
  800456:	80 fa 55             	cmp    $0x55,%dl
  800459:	0f 87 08 03 00 00    	ja     800767 <vprintfmt+0x39a>
  80045f:	0f b6 d2             	movzbl %dl,%edx
  800462:	ff 24 95 d4 10 80 00 	jmp    *0x8010d4(,%edx,4)
  800469:	8b 75 e0             	mov    -0x20(%ebp),%esi
  80046c:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
  800473:	bf 00 00 00 00       	mov    $0x0,%edi
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800478:	8d 14 bf             	lea    (%edi,%edi,4),%edx
  80047b:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
  80047f:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  800482:	8d 50 d0             	lea    -0x30(%eax),%edx
  800485:	83 fa 09             	cmp    $0x9,%edx
  800488:	77 2f                	ja     8004b9 <vprintfmt+0xec>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  80048a:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  80048d:	eb e9                	jmp    800478 <vprintfmt+0xab>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  80048f:	8b 45 14             	mov    0x14(%ebp),%eax
  800492:	8d 50 04             	lea    0x4(%eax),%edx
  800495:	89 55 14             	mov    %edx,0x14(%ebp)
  800498:	8b 00                	mov    (%eax),%eax
  80049a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80049d:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8004a0:	eb 1a                	jmp    8004bc <vprintfmt+0xef>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004a2:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
  8004a5:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8004a9:	79 9c                	jns    800447 <vprintfmt+0x7a>
  8004ab:	eb 81                	jmp    80042e <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ad:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8004b0:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
  8004b7:	eb 8e                	jmp    800447 <vprintfmt+0x7a>
  8004b9:	89 7d d4             	mov    %edi,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  8004bc:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8004c0:	79 85                	jns    800447 <vprintfmt+0x7a>
  8004c2:	e9 73 ff ff ff       	jmp    80043a <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8004c7:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ca:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8004cd:	e9 75 ff ff ff       	jmp    800447 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8004d2:	8b 45 14             	mov    0x14(%ebp),%eax
  8004d5:	8d 50 04             	lea    0x4(%eax),%edx
  8004d8:	89 55 14             	mov    %edx,0x14(%ebp)
  8004db:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8004df:	8b 00                	mov    (%eax),%eax
  8004e1:	89 04 24             	mov    %eax,(%esp)
  8004e4:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004e7:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8004ea:	e9 01 ff ff ff       	jmp    8003f0 <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8004ef:	8b 45 14             	mov    0x14(%ebp),%eax
  8004f2:	8d 50 04             	lea    0x4(%eax),%edx
  8004f5:	89 55 14             	mov    %edx,0x14(%ebp)
  8004f8:	8b 00                	mov    (%eax),%eax
  8004fa:	89 c2                	mov    %eax,%edx
  8004fc:	c1 fa 1f             	sar    $0x1f,%edx
  8004ff:	31 d0                	xor    %edx,%eax
  800501:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800503:	83 f8 06             	cmp    $0x6,%eax
  800506:	7f 0b                	jg     800513 <vprintfmt+0x146>
  800508:	8b 14 85 2c 12 80 00 	mov    0x80122c(,%eax,4),%edx
  80050f:	85 d2                	test   %edx,%edx
  800511:	75 23                	jne    800536 <vprintfmt+0x169>
				printfmt(putch, putdat, "error %d", err);
  800513:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800517:	c7 44 24 08 5c 10 80 	movl   $0x80105c,0x8(%esp)
  80051e:	00 
  80051f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800523:	8b 7d 08             	mov    0x8(%ebp),%edi
  800526:	89 3c 24             	mov    %edi,(%esp)
  800529:	e8 77 fe ff ff       	call   8003a5 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80052e:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800531:	e9 ba fe ff ff       	jmp    8003f0 <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
  800536:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80053a:	c7 44 24 08 65 10 80 	movl   $0x801065,0x8(%esp)
  800541:	00 
  800542:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800546:	8b 7d 08             	mov    0x8(%ebp),%edi
  800549:	89 3c 24             	mov    %edi,(%esp)
  80054c:	e8 54 fe ff ff       	call   8003a5 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800551:	8b 75 e0             	mov    -0x20(%ebp),%esi
  800554:	e9 97 fe ff ff       	jmp    8003f0 <vprintfmt+0x23>
  800559:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80055c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80055f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800562:	8b 45 14             	mov    0x14(%ebp),%eax
  800565:	8d 50 04             	lea    0x4(%eax),%edx
  800568:	89 55 14             	mov    %edx,0x14(%ebp)
  80056b:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  80056d:	85 f6                	test   %esi,%esi
  80056f:	ba 55 10 80 00       	mov    $0x801055,%edx
  800574:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
  800577:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  80057b:	0f 8e 8c 00 00 00    	jle    80060d <vprintfmt+0x240>
  800581:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  800585:	0f 84 82 00 00 00    	je     80060d <vprintfmt+0x240>
				for (width -= strnlen(p, precision); width > 0; width--)
  80058b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80058f:	89 34 24             	mov    %esi,(%esp)
  800592:	e8 91 02 00 00       	call   800828 <strnlen>
  800597:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  80059a:	29 c2                	sub    %eax,%edx
  80059c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
					putch(padc, putdat);
  80059f:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  8005a3:	89 75 d0             	mov    %esi,-0x30(%ebp)
  8005a6:	89 7d cc             	mov    %edi,-0x34(%ebp)
  8005a9:	89 de                	mov    %ebx,%esi
  8005ab:	89 d3                	mov    %edx,%ebx
  8005ad:	89 c7                	mov    %eax,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005af:	eb 0d                	jmp    8005be <vprintfmt+0x1f1>
					putch(padc, putdat);
  8005b1:	89 74 24 04          	mov    %esi,0x4(%esp)
  8005b5:	89 3c 24             	mov    %edi,(%esp)
  8005b8:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005bb:	83 eb 01             	sub    $0x1,%ebx
  8005be:	85 db                	test   %ebx,%ebx
  8005c0:	7f ef                	jg     8005b1 <vprintfmt+0x1e4>
  8005c2:	8b 7d cc             	mov    -0x34(%ebp),%edi
  8005c5:	89 f3                	mov    %esi,%ebx
  8005c7:	8b 75 d0             	mov    -0x30(%ebp),%esi

// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
  8005ca:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8005ce:	b8 00 00 00 00       	mov    $0x0,%eax
  8005d3:	0f 49 45 e4          	cmovns -0x1c(%ebp),%eax
  8005d7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8005da:	29 c2                	sub    %eax,%edx
  8005dc:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8005df:	eb 2c                	jmp    80060d <vprintfmt+0x240>
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8005e1:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8005e5:	74 18                	je     8005ff <vprintfmt+0x232>
  8005e7:	8d 50 e0             	lea    -0x20(%eax),%edx
  8005ea:	83 fa 5e             	cmp    $0x5e,%edx
  8005ed:	76 10                	jbe    8005ff <vprintfmt+0x232>
					putch('?', putdat);
  8005ef:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8005f3:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  8005fa:	ff 55 08             	call   *0x8(%ebp)
  8005fd:	eb 0a                	jmp    800609 <vprintfmt+0x23c>
				else
					putch(ch, putdat);
  8005ff:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800603:	89 04 24             	mov    %eax,(%esp)
  800606:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800609:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
  80060d:	0f be 06             	movsbl (%esi),%eax
  800610:	83 c6 01             	add    $0x1,%esi
  800613:	85 c0                	test   %eax,%eax
  800615:	74 25                	je     80063c <vprintfmt+0x26f>
  800617:	85 ff                	test   %edi,%edi
  800619:	78 c6                	js     8005e1 <vprintfmt+0x214>
  80061b:	83 ef 01             	sub    $0x1,%edi
  80061e:	79 c1                	jns    8005e1 <vprintfmt+0x214>
  800620:	8b 7d 08             	mov    0x8(%ebp),%edi
  800623:	89 de                	mov    %ebx,%esi
  800625:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800628:	eb 1a                	jmp    800644 <vprintfmt+0x277>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  80062a:	89 74 24 04          	mov    %esi,0x4(%esp)
  80062e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800635:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800637:	83 eb 01             	sub    $0x1,%ebx
  80063a:	eb 08                	jmp    800644 <vprintfmt+0x277>
  80063c:	8b 7d 08             	mov    0x8(%ebp),%edi
  80063f:	89 de                	mov    %ebx,%esi
  800641:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800644:	85 db                	test   %ebx,%ebx
  800646:	7f e2                	jg     80062a <vprintfmt+0x25d>
  800648:	89 7d 08             	mov    %edi,0x8(%ebp)
  80064b:	89 f3                	mov    %esi,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80064d:	8b 75 e0             	mov    -0x20(%ebp),%esi
  800650:	e9 9b fd ff ff       	jmp    8003f0 <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800655:	83 f9 01             	cmp    $0x1,%ecx
  800658:	7e 10                	jle    80066a <vprintfmt+0x29d>
		return va_arg(*ap, long long);
  80065a:	8b 45 14             	mov    0x14(%ebp),%eax
  80065d:	8d 50 08             	lea    0x8(%eax),%edx
  800660:	89 55 14             	mov    %edx,0x14(%ebp)
  800663:	8b 30                	mov    (%eax),%esi
  800665:	8b 78 04             	mov    0x4(%eax),%edi
  800668:	eb 26                	jmp    800690 <vprintfmt+0x2c3>
	else if (lflag)
  80066a:	85 c9                	test   %ecx,%ecx
  80066c:	74 12                	je     800680 <vprintfmt+0x2b3>
		return va_arg(*ap, long);
  80066e:	8b 45 14             	mov    0x14(%ebp),%eax
  800671:	8d 50 04             	lea    0x4(%eax),%edx
  800674:	89 55 14             	mov    %edx,0x14(%ebp)
  800677:	8b 30                	mov    (%eax),%esi
  800679:	89 f7                	mov    %esi,%edi
  80067b:	c1 ff 1f             	sar    $0x1f,%edi
  80067e:	eb 10                	jmp    800690 <vprintfmt+0x2c3>
	else
		return va_arg(*ap, int);
  800680:	8b 45 14             	mov    0x14(%ebp),%eax
  800683:	8d 50 04             	lea    0x4(%eax),%edx
  800686:	89 55 14             	mov    %edx,0x14(%ebp)
  800689:	8b 30                	mov    (%eax),%esi
  80068b:	89 f7                	mov    %esi,%edi
  80068d:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800690:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800695:	85 ff                	test   %edi,%edi
  800697:	0f 89 8c 00 00 00    	jns    800729 <vprintfmt+0x35c>
				putch('-', putdat);
  80069d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006a1:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8006a8:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  8006ab:	f7 de                	neg    %esi
  8006ad:	83 d7 00             	adc    $0x0,%edi
  8006b0:	f7 df                	neg    %edi
			}
			base = 10;
  8006b2:	b8 0a 00 00 00       	mov    $0xa,%eax
  8006b7:	eb 70                	jmp    800729 <vprintfmt+0x35c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8006b9:	89 ca                	mov    %ecx,%edx
  8006bb:	8d 45 14             	lea    0x14(%ebp),%eax
  8006be:	e8 8b fc ff ff       	call   80034e <getuint>
  8006c3:	89 c6                	mov    %eax,%esi
  8006c5:	89 d7                	mov    %edx,%edi
			base = 10;
  8006c7:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
  8006cc:	eb 5b                	jmp    800729 <vprintfmt+0x35c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num=getuint(&ap,lflag);
  8006ce:	89 ca                	mov    %ecx,%edx
  8006d0:	8d 45 14             	lea    0x14(%ebp),%eax
  8006d3:	e8 76 fc ff ff       	call   80034e <getuint>
  8006d8:	89 c6                	mov    %eax,%esi
  8006da:	89 d7                	mov    %edx,%edi
			base = 8;
  8006dc:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
  8006e1:	eb 46                	jmp    800729 <vprintfmt+0x35c>
	
		// pointer
		case 'p':
			putch('0', putdat);
  8006e3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006e7:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  8006ee:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  8006f1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006f5:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  8006fc:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006ff:	8b 45 14             	mov    0x14(%ebp),%eax
  800702:	8d 50 04             	lea    0x4(%eax),%edx
  800705:	89 55 14             	mov    %edx,0x14(%ebp)
	
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800708:	8b 30                	mov    (%eax),%esi
  80070a:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80070f:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  800714:	eb 13                	jmp    800729 <vprintfmt+0x35c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800716:	89 ca                	mov    %ecx,%edx
  800718:	8d 45 14             	lea    0x14(%ebp),%eax
  80071b:	e8 2e fc ff ff       	call   80034e <getuint>
  800720:	89 c6                	mov    %eax,%esi
  800722:	89 d7                	mov    %edx,%edi
			base = 16;
  800724:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800729:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
  80072d:	89 54 24 10          	mov    %edx,0x10(%esp)
  800731:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800734:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800738:	89 44 24 08          	mov    %eax,0x8(%esp)
  80073c:	89 34 24             	mov    %esi,(%esp)
  80073f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800743:	89 da                	mov    %ebx,%edx
  800745:	8b 45 08             	mov    0x8(%ebp),%eax
  800748:	e8 33 fb ff ff       	call   800280 <printnum>
			break;
  80074d:	8b 75 e0             	mov    -0x20(%ebp),%esi
  800750:	e9 9b fc ff ff       	jmp    8003f0 <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800755:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800759:	89 04 24             	mov    %eax,(%esp)
  80075c:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80075f:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800762:	e9 89 fc ff ff       	jmp    8003f0 <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800767:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80076b:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800772:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  800775:	eb 03                	jmp    80077a <vprintfmt+0x3ad>
  800777:	83 ee 01             	sub    $0x1,%esi
  80077a:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
  80077e:	75 f7                	jne    800777 <vprintfmt+0x3aa>
  800780:	e9 6b fc ff ff       	jmp    8003f0 <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
  800785:	83 c4 4c             	add    $0x4c,%esp
  800788:	5b                   	pop    %ebx
  800789:	5e                   	pop    %esi
  80078a:	5f                   	pop    %edi
  80078b:	5d                   	pop    %ebp
  80078c:	c3                   	ret    

0080078d <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80078d:	55                   	push   %ebp
  80078e:	89 e5                	mov    %esp,%ebp
  800790:	83 ec 28             	sub    $0x28,%esp
  800793:	8b 45 08             	mov    0x8(%ebp),%eax
  800796:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800799:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80079c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8007a0:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8007a3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8007aa:	85 c0                	test   %eax,%eax
  8007ac:	74 30                	je     8007de <vsnprintf+0x51>
  8007ae:	85 d2                	test   %edx,%edx
  8007b0:	7e 2c                	jle    8007de <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007b2:	8b 45 14             	mov    0x14(%ebp),%eax
  8007b5:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8007b9:	8b 45 10             	mov    0x10(%ebp),%eax
  8007bc:	89 44 24 08          	mov    %eax,0x8(%esp)
  8007c0:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8007c3:	89 44 24 04          	mov    %eax,0x4(%esp)
  8007c7:	c7 04 24 88 03 80 00 	movl   $0x800388,(%esp)
  8007ce:	e8 fa fb ff ff       	call   8003cd <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8007d3:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8007d6:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8007d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007dc:	eb 05                	jmp    8007e3 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007de:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007e3:	c9                   	leave  
  8007e4:	c3                   	ret    

008007e5 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007e5:	55                   	push   %ebp
  8007e6:	89 e5                	mov    %esp,%ebp
  8007e8:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007eb:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007ee:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8007f2:	8b 45 10             	mov    0x10(%ebp),%eax
  8007f5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8007f9:	8b 45 0c             	mov    0xc(%ebp),%eax
  8007fc:	89 44 24 04          	mov    %eax,0x4(%esp)
  800800:	8b 45 08             	mov    0x8(%ebp),%eax
  800803:	89 04 24             	mov    %eax,(%esp)
  800806:	e8 82 ff ff ff       	call   80078d <vsnprintf>
	va_end(ap);

	return rc;
}
  80080b:	c9                   	leave  
  80080c:	c3                   	ret    
  80080d:	00 00                	add    %al,(%eax)
	...

00800810 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800810:	55                   	push   %ebp
  800811:	89 e5                	mov    %esp,%ebp
  800813:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800816:	b8 00 00 00 00       	mov    $0x0,%eax
  80081b:	eb 03                	jmp    800820 <strlen+0x10>
		n++;
  80081d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800820:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800824:	75 f7                	jne    80081d <strlen+0xd>
		n++;
	return n;
}
  800826:	5d                   	pop    %ebp
  800827:	c3                   	ret    

00800828 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800828:	55                   	push   %ebp
  800829:	89 e5                	mov    %esp,%ebp
  80082b:	8b 4d 08             	mov    0x8(%ebp),%ecx
		n++;
	return n;
}

int
strnlen(const char *s, size_t size)
  80082e:	8b 55 0c             	mov    0xc(%ebp),%edx
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800831:	b8 00 00 00 00       	mov    $0x0,%eax
  800836:	eb 03                	jmp    80083b <strnlen+0x13>
		n++;
  800838:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80083b:	39 d0                	cmp    %edx,%eax
  80083d:	74 06                	je     800845 <strnlen+0x1d>
  80083f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800843:	75 f3                	jne    800838 <strnlen+0x10>
		n++;
	return n;
}
  800845:	5d                   	pop    %ebp
  800846:	c3                   	ret    

00800847 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800847:	55                   	push   %ebp
  800848:	89 e5                	mov    %esp,%ebp
  80084a:	53                   	push   %ebx
  80084b:	8b 45 08             	mov    0x8(%ebp),%eax
  80084e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800851:	ba 00 00 00 00       	mov    $0x0,%edx
  800856:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  80085a:	88 0c 10             	mov    %cl,(%eax,%edx,1)
  80085d:	83 c2 01             	add    $0x1,%edx
  800860:	84 c9                	test   %cl,%cl
  800862:	75 f2                	jne    800856 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
  800864:	5b                   	pop    %ebx
  800865:	5d                   	pop    %ebp
  800866:	c3                   	ret    

00800867 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800867:	55                   	push   %ebp
  800868:	89 e5                	mov    %esp,%ebp
  80086a:	53                   	push   %ebx
  80086b:	83 ec 08             	sub    $0x8,%esp
  80086e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800871:	89 1c 24             	mov    %ebx,(%esp)
  800874:	e8 97 ff ff ff       	call   800810 <strlen>
	strcpy(dst + len, src);
  800879:	8b 55 0c             	mov    0xc(%ebp),%edx
  80087c:	89 54 24 04          	mov    %edx,0x4(%esp)
  800880:	01 d8                	add    %ebx,%eax
  800882:	89 04 24             	mov    %eax,(%esp)
  800885:	e8 bd ff ff ff       	call   800847 <strcpy>
	return dst;
}
  80088a:	89 d8                	mov    %ebx,%eax
  80088c:	83 c4 08             	add    $0x8,%esp
  80088f:	5b                   	pop    %ebx
  800890:	5d                   	pop    %ebp
  800891:	c3                   	ret    

00800892 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800892:	55                   	push   %ebp
  800893:	89 e5                	mov    %esp,%ebp
  800895:	56                   	push   %esi
  800896:	53                   	push   %ebx
  800897:	8b 45 08             	mov    0x8(%ebp),%eax
  80089a:	8b 55 0c             	mov    0xc(%ebp),%edx
  80089d:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008a0:	b9 00 00 00 00       	mov    $0x0,%ecx
  8008a5:	eb 0f                	jmp    8008b6 <strncpy+0x24>
		*dst++ = *src;
  8008a7:	0f b6 1a             	movzbl (%edx),%ebx
  8008aa:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8008ad:	80 3a 01             	cmpb   $0x1,(%edx)
  8008b0:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008b3:	83 c1 01             	add    $0x1,%ecx
  8008b6:	39 f1                	cmp    %esi,%ecx
  8008b8:	75 ed                	jne    8008a7 <strncpy+0x15>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8008ba:	5b                   	pop    %ebx
  8008bb:	5e                   	pop    %esi
  8008bc:	5d                   	pop    %ebp
  8008bd:	c3                   	ret    

008008be <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8008be:	55                   	push   %ebp
  8008bf:	89 e5                	mov    %esp,%ebp
  8008c1:	56                   	push   %esi
  8008c2:	53                   	push   %ebx
  8008c3:	8b 75 08             	mov    0x8(%ebp),%esi
  8008c6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8008c9:	8b 55 10             	mov    0x10(%ebp),%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8008cc:	89 f0                	mov    %esi,%eax
  8008ce:	85 d2                	test   %edx,%edx
  8008d0:	75 0a                	jne    8008dc <strlcpy+0x1e>
  8008d2:	eb 1d                	jmp    8008f1 <strlcpy+0x33>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8008d4:	88 18                	mov    %bl,(%eax)
  8008d6:	83 c0 01             	add    $0x1,%eax
  8008d9:	83 c1 01             	add    $0x1,%ecx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8008dc:	83 ea 01             	sub    $0x1,%edx
  8008df:	74 0b                	je     8008ec <strlcpy+0x2e>
  8008e1:	0f b6 19             	movzbl (%ecx),%ebx
  8008e4:	84 db                	test   %bl,%bl
  8008e6:	75 ec                	jne    8008d4 <strlcpy+0x16>
  8008e8:	89 c2                	mov    %eax,%edx
  8008ea:	eb 02                	jmp    8008ee <strlcpy+0x30>
  8008ec:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  8008ee:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  8008f1:	29 f0                	sub    %esi,%eax
}
  8008f3:	5b                   	pop    %ebx
  8008f4:	5e                   	pop    %esi
  8008f5:	5d                   	pop    %ebp
  8008f6:	c3                   	ret    

008008f7 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008f7:	55                   	push   %ebp
  8008f8:	89 e5                	mov    %esp,%ebp
  8008fa:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008fd:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800900:	eb 06                	jmp    800908 <strcmp+0x11>
		p++, q++;
  800902:	83 c1 01             	add    $0x1,%ecx
  800905:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800908:	0f b6 01             	movzbl (%ecx),%eax
  80090b:	84 c0                	test   %al,%al
  80090d:	74 04                	je     800913 <strcmp+0x1c>
  80090f:	3a 02                	cmp    (%edx),%al
  800911:	74 ef                	je     800902 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800913:	0f b6 c0             	movzbl %al,%eax
  800916:	0f b6 12             	movzbl (%edx),%edx
  800919:	29 d0                	sub    %edx,%eax
}
  80091b:	5d                   	pop    %ebp
  80091c:	c3                   	ret    

0080091d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80091d:	55                   	push   %ebp
  80091e:	89 e5                	mov    %esp,%ebp
  800920:	53                   	push   %ebx
  800921:	8b 45 08             	mov    0x8(%ebp),%eax
  800924:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800927:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
  80092a:	eb 09                	jmp    800935 <strncmp+0x18>
		n--, p++, q++;
  80092c:	83 ea 01             	sub    $0x1,%edx
  80092f:	83 c0 01             	add    $0x1,%eax
  800932:	83 c1 01             	add    $0x1,%ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800935:	85 d2                	test   %edx,%edx
  800937:	74 15                	je     80094e <strncmp+0x31>
  800939:	0f b6 18             	movzbl (%eax),%ebx
  80093c:	84 db                	test   %bl,%bl
  80093e:	74 04                	je     800944 <strncmp+0x27>
  800940:	3a 19                	cmp    (%ecx),%bl
  800942:	74 e8                	je     80092c <strncmp+0xf>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800944:	0f b6 00             	movzbl (%eax),%eax
  800947:	0f b6 11             	movzbl (%ecx),%edx
  80094a:	29 d0                	sub    %edx,%eax
  80094c:	eb 05                	jmp    800953 <strncmp+0x36>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  80094e:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800953:	5b                   	pop    %ebx
  800954:	5d                   	pop    %ebp
  800955:	c3                   	ret    

00800956 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800956:	55                   	push   %ebp
  800957:	89 e5                	mov    %esp,%ebp
  800959:	8b 45 08             	mov    0x8(%ebp),%eax
  80095c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800960:	eb 07                	jmp    800969 <strchr+0x13>
		if (*s == c)
  800962:	38 ca                	cmp    %cl,%dl
  800964:	74 0f                	je     800975 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800966:	83 c0 01             	add    $0x1,%eax
  800969:	0f b6 10             	movzbl (%eax),%edx
  80096c:	84 d2                	test   %dl,%dl
  80096e:	75 f2                	jne    800962 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800970:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800975:	5d                   	pop    %ebp
  800976:	c3                   	ret    

00800977 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800977:	55                   	push   %ebp
  800978:	89 e5                	mov    %esp,%ebp
  80097a:	8b 45 08             	mov    0x8(%ebp),%eax
  80097d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800981:	eb 07                	jmp    80098a <strfind+0x13>
		if (*s == c)
  800983:	38 ca                	cmp    %cl,%dl
  800985:	74 0a                	je     800991 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800987:	83 c0 01             	add    $0x1,%eax
  80098a:	0f b6 10             	movzbl (%eax),%edx
  80098d:	84 d2                	test   %dl,%dl
  80098f:	75 f2                	jne    800983 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  800991:	5d                   	pop    %ebp
  800992:	c3                   	ret    

00800993 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800993:	55                   	push   %ebp
  800994:	89 e5                	mov    %esp,%ebp
  800996:	83 ec 0c             	sub    $0xc,%esp
  800999:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80099c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80099f:	89 7d fc             	mov    %edi,-0x4(%ebp)
  8009a2:	8b 7d 08             	mov    0x8(%ebp),%edi
  8009a5:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009a8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8009ab:	85 c9                	test   %ecx,%ecx
  8009ad:	74 30                	je     8009df <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8009af:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8009b5:	75 25                	jne    8009dc <memset+0x49>
  8009b7:	f6 c1 03             	test   $0x3,%cl
  8009ba:	75 20                	jne    8009dc <memset+0x49>
		c &= 0xFF;
  8009bc:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8009bf:	89 d3                	mov    %edx,%ebx
  8009c1:	c1 e3 08             	shl    $0x8,%ebx
  8009c4:	89 d6                	mov    %edx,%esi
  8009c6:	c1 e6 18             	shl    $0x18,%esi
  8009c9:	89 d0                	mov    %edx,%eax
  8009cb:	c1 e0 10             	shl    $0x10,%eax
  8009ce:	09 f0                	or     %esi,%eax
  8009d0:	09 d0                	or     %edx,%eax
  8009d2:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  8009d4:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  8009d7:	fc                   	cld    
  8009d8:	f3 ab                	rep stos %eax,%es:(%edi)
  8009da:	eb 03                	jmp    8009df <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009dc:	fc                   	cld    
  8009dd:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8009df:	89 f8                	mov    %edi,%eax
  8009e1:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8009e4:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8009e7:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8009ea:	89 ec                	mov    %ebp,%esp
  8009ec:	5d                   	pop    %ebp
  8009ed:	c3                   	ret    

008009ee <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8009ee:	55                   	push   %ebp
  8009ef:	89 e5                	mov    %esp,%ebp
  8009f1:	83 ec 08             	sub    $0x8,%esp
  8009f4:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8009f7:	89 7d fc             	mov    %edi,-0x4(%ebp)
  8009fa:	8b 45 08             	mov    0x8(%ebp),%eax
  8009fd:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a00:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a03:	39 c6                	cmp    %eax,%esi
  800a05:	73 36                	jae    800a3d <memmove+0x4f>
  800a07:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a0a:	39 d0                	cmp    %edx,%eax
  800a0c:	73 2f                	jae    800a3d <memmove+0x4f>
		s += n;
		d += n;
  800a0e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a11:	f6 c2 03             	test   $0x3,%dl
  800a14:	75 1b                	jne    800a31 <memmove+0x43>
  800a16:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a1c:	75 13                	jne    800a31 <memmove+0x43>
  800a1e:	f6 c1 03             	test   $0x3,%cl
  800a21:	75 0e                	jne    800a31 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800a23:	83 ef 04             	sub    $0x4,%edi
  800a26:	8d 72 fc             	lea    -0x4(%edx),%esi
  800a29:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800a2c:	fd                   	std    
  800a2d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a2f:	eb 09                	jmp    800a3a <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800a31:	83 ef 01             	sub    $0x1,%edi
  800a34:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800a37:	fd                   	std    
  800a38:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a3a:	fc                   	cld    
  800a3b:	eb 20                	jmp    800a5d <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a3d:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a43:	75 13                	jne    800a58 <memmove+0x6a>
  800a45:	a8 03                	test   $0x3,%al
  800a47:	75 0f                	jne    800a58 <memmove+0x6a>
  800a49:	f6 c1 03             	test   $0x3,%cl
  800a4c:	75 0a                	jne    800a58 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800a4e:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800a51:	89 c7                	mov    %eax,%edi
  800a53:	fc                   	cld    
  800a54:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a56:	eb 05                	jmp    800a5d <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a58:	89 c7                	mov    %eax,%edi
  800a5a:	fc                   	cld    
  800a5b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a5d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800a60:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800a63:	89 ec                	mov    %ebp,%esp
  800a65:	5d                   	pop    %ebp
  800a66:	c3                   	ret    

00800a67 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a67:	55                   	push   %ebp
  800a68:	89 e5                	mov    %esp,%ebp
  800a6a:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800a6d:	8b 45 10             	mov    0x10(%ebp),%eax
  800a70:	89 44 24 08          	mov    %eax,0x8(%esp)
  800a74:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a77:	89 44 24 04          	mov    %eax,0x4(%esp)
  800a7b:	8b 45 08             	mov    0x8(%ebp),%eax
  800a7e:	89 04 24             	mov    %eax,(%esp)
  800a81:	e8 68 ff ff ff       	call   8009ee <memmove>
}
  800a86:	c9                   	leave  
  800a87:	c3                   	ret    

00800a88 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a88:	55                   	push   %ebp
  800a89:	89 e5                	mov    %esp,%ebp
  800a8b:	57                   	push   %edi
  800a8c:	56                   	push   %esi
  800a8d:	53                   	push   %ebx
  800a8e:	8b 7d 08             	mov    0x8(%ebp),%edi
  800a91:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a94:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a97:	ba 00 00 00 00       	mov    $0x0,%edx
  800a9c:	eb 1a                	jmp    800ab8 <memcmp+0x30>
		if (*s1 != *s2)
  800a9e:	0f b6 04 17          	movzbl (%edi,%edx,1),%eax
  800aa2:	83 c2 01             	add    $0x1,%edx
  800aa5:	0f b6 4c 16 ff       	movzbl -0x1(%esi,%edx,1),%ecx
  800aaa:	38 c8                	cmp    %cl,%al
  800aac:	74 0a                	je     800ab8 <memcmp+0x30>
			return (int) *s1 - (int) *s2;
  800aae:	0f b6 c0             	movzbl %al,%eax
  800ab1:	0f b6 c9             	movzbl %cl,%ecx
  800ab4:	29 c8                	sub    %ecx,%eax
  800ab6:	eb 09                	jmp    800ac1 <memcmp+0x39>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800ab8:	39 da                	cmp    %ebx,%edx
  800aba:	75 e2                	jne    800a9e <memcmp+0x16>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800abc:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800ac1:	5b                   	pop    %ebx
  800ac2:	5e                   	pop    %esi
  800ac3:	5f                   	pop    %edi
  800ac4:	5d                   	pop    %ebp
  800ac5:	c3                   	ret    

00800ac6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800ac6:	55                   	push   %ebp
  800ac7:	89 e5                	mov    %esp,%ebp
  800ac9:	8b 45 08             	mov    0x8(%ebp),%eax
  800acc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800acf:	89 c2                	mov    %eax,%edx
  800ad1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800ad4:	eb 07                	jmp    800add <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800ad6:	38 08                	cmp    %cl,(%eax)
  800ad8:	74 07                	je     800ae1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800ada:	83 c0 01             	add    $0x1,%eax
  800add:	39 d0                	cmp    %edx,%eax
  800adf:	72 f5                	jb     800ad6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800ae1:	5d                   	pop    %ebp
  800ae2:	c3                   	ret    

00800ae3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800ae3:	55                   	push   %ebp
  800ae4:	89 e5                	mov    %esp,%ebp
  800ae6:	57                   	push   %edi
  800ae7:	56                   	push   %esi
  800ae8:	53                   	push   %ebx
  800ae9:	8b 55 08             	mov    0x8(%ebp),%edx
  800aec:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800aef:	eb 03                	jmp    800af4 <strtol+0x11>
		s++;
  800af1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800af4:	0f b6 02             	movzbl (%edx),%eax
  800af7:	3c 20                	cmp    $0x20,%al
  800af9:	74 f6                	je     800af1 <strtol+0xe>
  800afb:	3c 09                	cmp    $0x9,%al
  800afd:	74 f2                	je     800af1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800aff:	3c 2b                	cmp    $0x2b,%al
  800b01:	75 0a                	jne    800b0d <strtol+0x2a>
		s++;
  800b03:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b06:	bf 00 00 00 00       	mov    $0x0,%edi
  800b0b:	eb 10                	jmp    800b1d <strtol+0x3a>
  800b0d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b12:	3c 2d                	cmp    $0x2d,%al
  800b14:	75 07                	jne    800b1d <strtol+0x3a>
		s++, neg = 1;
  800b16:	8d 52 01             	lea    0x1(%edx),%edx
  800b19:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b1d:	85 db                	test   %ebx,%ebx
  800b1f:	0f 94 c0             	sete   %al
  800b22:	74 05                	je     800b29 <strtol+0x46>
  800b24:	83 fb 10             	cmp    $0x10,%ebx
  800b27:	75 15                	jne    800b3e <strtol+0x5b>
  800b29:	80 3a 30             	cmpb   $0x30,(%edx)
  800b2c:	75 10                	jne    800b3e <strtol+0x5b>
  800b2e:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800b32:	75 0a                	jne    800b3e <strtol+0x5b>
		s += 2, base = 16;
  800b34:	83 c2 02             	add    $0x2,%edx
  800b37:	bb 10 00 00 00       	mov    $0x10,%ebx
  800b3c:	eb 13                	jmp    800b51 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800b3e:	84 c0                	test   %al,%al
  800b40:	74 0f                	je     800b51 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b42:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b47:	80 3a 30             	cmpb   $0x30,(%edx)
  800b4a:	75 05                	jne    800b51 <strtol+0x6e>
		s++, base = 8;
  800b4c:	83 c2 01             	add    $0x1,%edx
  800b4f:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800b51:	b8 00 00 00 00       	mov    $0x0,%eax
  800b56:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b58:	0f b6 0a             	movzbl (%edx),%ecx
  800b5b:	8d 59 d0             	lea    -0x30(%ecx),%ebx
  800b5e:	80 fb 09             	cmp    $0x9,%bl
  800b61:	77 08                	ja     800b6b <strtol+0x88>
			dig = *s - '0';
  800b63:	0f be c9             	movsbl %cl,%ecx
  800b66:	83 e9 30             	sub    $0x30,%ecx
  800b69:	eb 1e                	jmp    800b89 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800b6b:	8d 59 9f             	lea    -0x61(%ecx),%ebx
  800b6e:	80 fb 19             	cmp    $0x19,%bl
  800b71:	77 08                	ja     800b7b <strtol+0x98>
			dig = *s - 'a' + 10;
  800b73:	0f be c9             	movsbl %cl,%ecx
  800b76:	83 e9 57             	sub    $0x57,%ecx
  800b79:	eb 0e                	jmp    800b89 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800b7b:	8d 59 bf             	lea    -0x41(%ecx),%ebx
  800b7e:	80 fb 19             	cmp    $0x19,%bl
  800b81:	77 14                	ja     800b97 <strtol+0xb4>
			dig = *s - 'A' + 10;
  800b83:	0f be c9             	movsbl %cl,%ecx
  800b86:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800b89:	39 f1                	cmp    %esi,%ecx
  800b8b:	7d 0e                	jge    800b9b <strtol+0xb8>
			break;
		s++, val = (val * base) + dig;
  800b8d:	83 c2 01             	add    $0x1,%edx
  800b90:	0f af c6             	imul   %esi,%eax
  800b93:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800b95:	eb c1                	jmp    800b58 <strtol+0x75>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800b97:	89 c1                	mov    %eax,%ecx
  800b99:	eb 02                	jmp    800b9d <strtol+0xba>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800b9b:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800b9d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ba1:	74 05                	je     800ba8 <strtol+0xc5>
		*endptr = (char *) s;
  800ba3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800ba6:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800ba8:	89 ca                	mov    %ecx,%edx
  800baa:	f7 da                	neg    %edx
  800bac:	85 ff                	test   %edi,%edi
  800bae:	0f 45 c2             	cmovne %edx,%eax
}
  800bb1:	5b                   	pop    %ebx
  800bb2:	5e                   	pop    %esi
  800bb3:	5f                   	pop    %edi
  800bb4:	5d                   	pop    %ebp
  800bb5:	c3                   	ret    
	...

00800bb8 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800bb8:	55                   	push   %ebp
  800bb9:	89 e5                	mov    %esp,%ebp
  800bbb:	83 ec 0c             	sub    $0xc,%esp
  800bbe:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800bc1:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800bc4:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bc7:	b8 00 00 00 00       	mov    $0x0,%eax
  800bcc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800bcf:	8b 55 08             	mov    0x8(%ebp),%edx
  800bd2:	89 c3                	mov    %eax,%ebx
  800bd4:	89 c7                	mov    %eax,%edi
  800bd6:	89 c6                	mov    %eax,%esi
  800bd8:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800bda:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800bdd:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800be0:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800be3:	89 ec                	mov    %ebp,%esp
  800be5:	5d                   	pop    %ebp
  800be6:	c3                   	ret    

00800be7 <sys_cgetc>:

int
sys_cgetc(void)
{
  800be7:	55                   	push   %ebp
  800be8:	89 e5                	mov    %esp,%ebp
  800bea:	83 ec 0c             	sub    $0xc,%esp
  800bed:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800bf0:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800bf3:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bf6:	ba 00 00 00 00       	mov    $0x0,%edx
  800bfb:	b8 01 00 00 00       	mov    $0x1,%eax
  800c00:	89 d1                	mov    %edx,%ecx
  800c02:	89 d3                	mov    %edx,%ebx
  800c04:	89 d7                	mov    %edx,%edi
  800c06:	89 d6                	mov    %edx,%esi
  800c08:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800c0a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800c0d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800c10:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800c13:	89 ec                	mov    %ebp,%esp
  800c15:	5d                   	pop    %ebp
  800c16:	c3                   	ret    

00800c17 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800c17:	55                   	push   %ebp
  800c18:	89 e5                	mov    %esp,%ebp
  800c1a:	83 ec 38             	sub    $0x38,%esp
  800c1d:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800c20:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c23:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c26:	b9 00 00 00 00       	mov    $0x0,%ecx
  800c2b:	b8 03 00 00 00       	mov    $0x3,%eax
  800c30:	8b 55 08             	mov    0x8(%ebp),%edx
  800c33:	89 cb                	mov    %ecx,%ebx
  800c35:	89 cf                	mov    %ecx,%edi
  800c37:	89 ce                	mov    %ecx,%esi
  800c39:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c3b:	85 c0                	test   %eax,%eax
  800c3d:	7e 28                	jle    800c67 <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c3f:	89 44 24 10          	mov    %eax,0x10(%esp)
  800c43:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800c4a:	00 
  800c4b:	c7 44 24 08 48 12 80 	movl   $0x801248,0x8(%esp)
  800c52:	00 
  800c53:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800c5a:	00 
  800c5b:	c7 04 24 65 12 80 00 	movl   $0x801265,(%esp)
  800c62:	e8 01 f5 ff ff       	call   800168 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800c67:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800c6a:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800c6d:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800c70:	89 ec                	mov    %ebp,%esp
  800c72:	5d                   	pop    %ebp
  800c73:	c3                   	ret    

00800c74 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800c74:	55                   	push   %ebp
  800c75:	89 e5                	mov    %esp,%ebp
  800c77:	83 ec 0c             	sub    $0xc,%esp
  800c7a:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800c7d:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800c80:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c83:	ba 00 00 00 00       	mov    $0x0,%edx
  800c88:	b8 02 00 00 00       	mov    $0x2,%eax
  800c8d:	89 d1                	mov    %edx,%ecx
  800c8f:	89 d3                	mov    %edx,%ebx
  800c91:	89 d7                	mov    %edx,%edi
  800c93:	89 d6                	mov    %edx,%esi
  800c95:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800c97:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800c9a:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800c9d:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800ca0:	89 ec                	mov    %ebp,%esp
  800ca2:	5d                   	pop    %ebp
  800ca3:	c3                   	ret    
	...

00800cb0 <__udivdi3>:
  800cb0:	83 ec 1c             	sub    $0x1c,%esp
  800cb3:	89 7c 24 14          	mov    %edi,0x14(%esp)
  800cb7:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
  800cbb:	8b 44 24 20          	mov    0x20(%esp),%eax
  800cbf:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  800cc3:	89 74 24 10          	mov    %esi,0x10(%esp)
  800cc7:	8b 74 24 24          	mov    0x24(%esp),%esi
  800ccb:	85 ff                	test   %edi,%edi
  800ccd:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  800cd1:	89 44 24 08          	mov    %eax,0x8(%esp)
  800cd5:	89 cd                	mov    %ecx,%ebp
  800cd7:	89 44 24 04          	mov    %eax,0x4(%esp)
  800cdb:	75 33                	jne    800d10 <__udivdi3+0x60>
  800cdd:	39 f1                	cmp    %esi,%ecx
  800cdf:	77 57                	ja     800d38 <__udivdi3+0x88>
  800ce1:	85 c9                	test   %ecx,%ecx
  800ce3:	75 0b                	jne    800cf0 <__udivdi3+0x40>
  800ce5:	b8 01 00 00 00       	mov    $0x1,%eax
  800cea:	31 d2                	xor    %edx,%edx
  800cec:	f7 f1                	div    %ecx
  800cee:	89 c1                	mov    %eax,%ecx
  800cf0:	89 f0                	mov    %esi,%eax
  800cf2:	31 d2                	xor    %edx,%edx
  800cf4:	f7 f1                	div    %ecx
  800cf6:	89 c6                	mov    %eax,%esi
  800cf8:	8b 44 24 04          	mov    0x4(%esp),%eax
  800cfc:	f7 f1                	div    %ecx
  800cfe:	89 f2                	mov    %esi,%edx
  800d00:	8b 74 24 10          	mov    0x10(%esp),%esi
  800d04:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800d08:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800d0c:	83 c4 1c             	add    $0x1c,%esp
  800d0f:	c3                   	ret    
  800d10:	31 d2                	xor    %edx,%edx
  800d12:	31 c0                	xor    %eax,%eax
  800d14:	39 f7                	cmp    %esi,%edi
  800d16:	77 e8                	ja     800d00 <__udivdi3+0x50>
  800d18:	0f bd cf             	bsr    %edi,%ecx
  800d1b:	83 f1 1f             	xor    $0x1f,%ecx
  800d1e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800d22:	75 2c                	jne    800d50 <__udivdi3+0xa0>
  800d24:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
  800d28:	76 04                	jbe    800d2e <__udivdi3+0x7e>
  800d2a:	39 f7                	cmp    %esi,%edi
  800d2c:	73 d2                	jae    800d00 <__udivdi3+0x50>
  800d2e:	31 d2                	xor    %edx,%edx
  800d30:	b8 01 00 00 00       	mov    $0x1,%eax
  800d35:	eb c9                	jmp    800d00 <__udivdi3+0x50>
  800d37:	90                   	nop
  800d38:	89 f2                	mov    %esi,%edx
  800d3a:	f7 f1                	div    %ecx
  800d3c:	31 d2                	xor    %edx,%edx
  800d3e:	8b 74 24 10          	mov    0x10(%esp),%esi
  800d42:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800d46:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800d4a:	83 c4 1c             	add    $0x1c,%esp
  800d4d:	c3                   	ret    
  800d4e:	66 90                	xchg   %ax,%ax
  800d50:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800d55:	b8 20 00 00 00       	mov    $0x20,%eax
  800d5a:	89 ea                	mov    %ebp,%edx
  800d5c:	2b 44 24 04          	sub    0x4(%esp),%eax
  800d60:	d3 e7                	shl    %cl,%edi
  800d62:	89 c1                	mov    %eax,%ecx
  800d64:	d3 ea                	shr    %cl,%edx
  800d66:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800d6b:	09 fa                	or     %edi,%edx
  800d6d:	89 f7                	mov    %esi,%edi
  800d6f:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800d73:	89 f2                	mov    %esi,%edx
  800d75:	8b 74 24 08          	mov    0x8(%esp),%esi
  800d79:	d3 e5                	shl    %cl,%ebp
  800d7b:	89 c1                	mov    %eax,%ecx
  800d7d:	d3 ef                	shr    %cl,%edi
  800d7f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800d84:	d3 e2                	shl    %cl,%edx
  800d86:	89 c1                	mov    %eax,%ecx
  800d88:	d3 ee                	shr    %cl,%esi
  800d8a:	09 d6                	or     %edx,%esi
  800d8c:	89 fa                	mov    %edi,%edx
  800d8e:	89 f0                	mov    %esi,%eax
  800d90:	f7 74 24 0c          	divl   0xc(%esp)
  800d94:	89 d7                	mov    %edx,%edi
  800d96:	89 c6                	mov    %eax,%esi
  800d98:	f7 e5                	mul    %ebp
  800d9a:	39 d7                	cmp    %edx,%edi
  800d9c:	72 22                	jb     800dc0 <__udivdi3+0x110>
  800d9e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  800da2:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800da7:	d3 e5                	shl    %cl,%ebp
  800da9:	39 c5                	cmp    %eax,%ebp
  800dab:	73 04                	jae    800db1 <__udivdi3+0x101>
  800dad:	39 d7                	cmp    %edx,%edi
  800daf:	74 0f                	je     800dc0 <__udivdi3+0x110>
  800db1:	89 f0                	mov    %esi,%eax
  800db3:	31 d2                	xor    %edx,%edx
  800db5:	e9 46 ff ff ff       	jmp    800d00 <__udivdi3+0x50>
  800dba:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800dc0:	8d 46 ff             	lea    -0x1(%esi),%eax
  800dc3:	31 d2                	xor    %edx,%edx
  800dc5:	8b 74 24 10          	mov    0x10(%esp),%esi
  800dc9:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800dcd:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800dd1:	83 c4 1c             	add    $0x1c,%esp
  800dd4:	c3                   	ret    
	...

00800de0 <__umoddi3>:
  800de0:	83 ec 1c             	sub    $0x1c,%esp
  800de3:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  800de7:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
  800deb:	8b 44 24 20          	mov    0x20(%esp),%eax
  800def:	89 74 24 10          	mov    %esi,0x10(%esp)
  800df3:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  800df7:	8b 74 24 24          	mov    0x24(%esp),%esi
  800dfb:	85 ed                	test   %ebp,%ebp
  800dfd:	89 7c 24 14          	mov    %edi,0x14(%esp)
  800e01:	89 44 24 08          	mov    %eax,0x8(%esp)
  800e05:	89 cf                	mov    %ecx,%edi
  800e07:	89 04 24             	mov    %eax,(%esp)
  800e0a:	89 f2                	mov    %esi,%edx
  800e0c:	75 1a                	jne    800e28 <__umoddi3+0x48>
  800e0e:	39 f1                	cmp    %esi,%ecx
  800e10:	76 4e                	jbe    800e60 <__umoddi3+0x80>
  800e12:	f7 f1                	div    %ecx
  800e14:	89 d0                	mov    %edx,%eax
  800e16:	31 d2                	xor    %edx,%edx
  800e18:	8b 74 24 10          	mov    0x10(%esp),%esi
  800e1c:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800e20:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800e24:	83 c4 1c             	add    $0x1c,%esp
  800e27:	c3                   	ret    
  800e28:	39 f5                	cmp    %esi,%ebp
  800e2a:	77 54                	ja     800e80 <__umoddi3+0xa0>
  800e2c:	0f bd c5             	bsr    %ebp,%eax
  800e2f:	83 f0 1f             	xor    $0x1f,%eax
  800e32:	89 44 24 04          	mov    %eax,0x4(%esp)
  800e36:	75 60                	jne    800e98 <__umoddi3+0xb8>
  800e38:	3b 0c 24             	cmp    (%esp),%ecx
  800e3b:	0f 87 07 01 00 00    	ja     800f48 <__umoddi3+0x168>
  800e41:	89 f2                	mov    %esi,%edx
  800e43:	8b 34 24             	mov    (%esp),%esi
  800e46:	29 ce                	sub    %ecx,%esi
  800e48:	19 ea                	sbb    %ebp,%edx
  800e4a:	89 34 24             	mov    %esi,(%esp)
  800e4d:	8b 04 24             	mov    (%esp),%eax
  800e50:	8b 74 24 10          	mov    0x10(%esp),%esi
  800e54:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800e58:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800e5c:	83 c4 1c             	add    $0x1c,%esp
  800e5f:	c3                   	ret    
  800e60:	85 c9                	test   %ecx,%ecx
  800e62:	75 0b                	jne    800e6f <__umoddi3+0x8f>
  800e64:	b8 01 00 00 00       	mov    $0x1,%eax
  800e69:	31 d2                	xor    %edx,%edx
  800e6b:	f7 f1                	div    %ecx
  800e6d:	89 c1                	mov    %eax,%ecx
  800e6f:	89 f0                	mov    %esi,%eax
  800e71:	31 d2                	xor    %edx,%edx
  800e73:	f7 f1                	div    %ecx
  800e75:	8b 04 24             	mov    (%esp),%eax
  800e78:	f7 f1                	div    %ecx
  800e7a:	eb 98                	jmp    800e14 <__umoddi3+0x34>
  800e7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e80:	89 f2                	mov    %esi,%edx
  800e82:	8b 74 24 10          	mov    0x10(%esp),%esi
  800e86:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800e8a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800e8e:	83 c4 1c             	add    $0x1c,%esp
  800e91:	c3                   	ret    
  800e92:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800e98:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800e9d:	89 e8                	mov    %ebp,%eax
  800e9f:	bd 20 00 00 00       	mov    $0x20,%ebp
  800ea4:	2b 6c 24 04          	sub    0x4(%esp),%ebp
  800ea8:	89 fa                	mov    %edi,%edx
  800eaa:	d3 e0                	shl    %cl,%eax
  800eac:	89 e9                	mov    %ebp,%ecx
  800eae:	d3 ea                	shr    %cl,%edx
  800eb0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800eb5:	09 c2                	or     %eax,%edx
  800eb7:	8b 44 24 08          	mov    0x8(%esp),%eax
  800ebb:	89 14 24             	mov    %edx,(%esp)
  800ebe:	89 f2                	mov    %esi,%edx
  800ec0:	d3 e7                	shl    %cl,%edi
  800ec2:	89 e9                	mov    %ebp,%ecx
  800ec4:	d3 ea                	shr    %cl,%edx
  800ec6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800ecb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800ecf:	d3 e6                	shl    %cl,%esi
  800ed1:	89 e9                	mov    %ebp,%ecx
  800ed3:	d3 e8                	shr    %cl,%eax
  800ed5:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800eda:	09 f0                	or     %esi,%eax
  800edc:	8b 74 24 08          	mov    0x8(%esp),%esi
  800ee0:	f7 34 24             	divl   (%esp)
  800ee3:	d3 e6                	shl    %cl,%esi
  800ee5:	89 74 24 08          	mov    %esi,0x8(%esp)
  800ee9:	89 d6                	mov    %edx,%esi
  800eeb:	f7 e7                	mul    %edi
  800eed:	39 d6                	cmp    %edx,%esi
  800eef:	89 c1                	mov    %eax,%ecx
  800ef1:	89 d7                	mov    %edx,%edi
  800ef3:	72 3f                	jb     800f34 <__umoddi3+0x154>
  800ef5:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800ef9:	72 35                	jb     800f30 <__umoddi3+0x150>
  800efb:	8b 44 24 08          	mov    0x8(%esp),%eax
  800eff:	29 c8                	sub    %ecx,%eax
  800f01:	19 fe                	sbb    %edi,%esi
  800f03:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800f08:	89 f2                	mov    %esi,%edx
  800f0a:	d3 e8                	shr    %cl,%eax
  800f0c:	89 e9                	mov    %ebp,%ecx
  800f0e:	d3 e2                	shl    %cl,%edx
  800f10:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800f15:	09 d0                	or     %edx,%eax
  800f17:	89 f2                	mov    %esi,%edx
  800f19:	d3 ea                	shr    %cl,%edx
  800f1b:	8b 74 24 10          	mov    0x10(%esp),%esi
  800f1f:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800f23:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800f27:	83 c4 1c             	add    $0x1c,%esp
  800f2a:	c3                   	ret    
  800f2b:	90                   	nop
  800f2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f30:	39 d6                	cmp    %edx,%esi
  800f32:	75 c7                	jne    800efb <__umoddi3+0x11b>
  800f34:	89 d7                	mov    %edx,%edi
  800f36:	89 c1                	mov    %eax,%ecx
  800f38:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
  800f3c:	1b 3c 24             	sbb    (%esp),%edi
  800f3f:	eb ba                	jmp    800efb <__umoddi3+0x11b>
  800f41:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800f48:	39 f5                	cmp    %esi,%ebp
  800f4a:	0f 82 f1 fe ff ff    	jb     800e41 <__umoddi3+0x61>
  800f50:	e9 f8 fe ff ff       	jmp    800e4d <__umoddi3+0x6d>
