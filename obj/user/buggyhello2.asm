
obj/user/buggyhello2:     file format elf32-i386


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

const char *hello = "hello, world\n";

void
umain(int argc, char **argv)
{
  800034:	55                   	push   %ebp
  800035:	89 e5                	mov    %esp,%ebp
  800037:	83 ec 18             	sub    $0x18,%esp
	sys_cputs(hello, 1024*1024);
  80003a:	c7 44 24 04 00 00 10 	movl   $0x100000,0x4(%esp)
  800041:	00 
  800042:	a1 00 20 80 00       	mov    0x802000,%eax
  800047:	89 04 24             	mov    %eax,(%esp)
  80004a:	e8 6d 00 00 00       	call   8000bc <sys_cputs>
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
  800066:	e8 0d 01 00 00       	call   800178 <sys_getenvid>
  80006b:	25 ff 03 00 00       	and    $0x3ff,%eax
  800070:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800073:	c1 e0 05             	shl    $0x5,%eax
  800076:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80007b:	a3 08 20 80 00       	mov    %eax,0x802008

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800080:	85 f6                	test   %esi,%esi
  800082:	7e 07                	jle    80008b <libmain+0x37>
		binaryname = argv[0];
  800084:	8b 03                	mov    (%ebx),%eax
  800086:	a3 04 20 80 00       	mov    %eax,0x802004

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
  8000b5:	e8 61 00 00 00       	call   80011b <sys_env_destroy>
}
  8000ba:	c9                   	leave  
  8000bb:	c3                   	ret    

008000bc <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000bc:	55                   	push   %ebp
  8000bd:	89 e5                	mov    %esp,%ebp
  8000bf:	83 ec 0c             	sub    $0xc,%esp
  8000c2:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8000c5:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8000c8:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000cb:	b8 00 00 00 00       	mov    $0x0,%eax
  8000d0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000d3:	8b 55 08             	mov    0x8(%ebp),%edx
  8000d6:	89 c3                	mov    %eax,%ebx
  8000d8:	89 c7                	mov    %eax,%edi
  8000da:	89 c6                	mov    %eax,%esi
  8000dc:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000de:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8000e1:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8000e4:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8000e7:	89 ec                	mov    %ebp,%esp
  8000e9:	5d                   	pop    %ebp
  8000ea:	c3                   	ret    

008000eb <sys_cgetc>:

int
sys_cgetc(void)
{
  8000eb:	55                   	push   %ebp
  8000ec:	89 e5                	mov    %esp,%ebp
  8000ee:	83 ec 0c             	sub    $0xc,%esp
  8000f1:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8000f4:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8000f7:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000fa:	ba 00 00 00 00       	mov    $0x0,%edx
  8000ff:	b8 01 00 00 00       	mov    $0x1,%eax
  800104:	89 d1                	mov    %edx,%ecx
  800106:	89 d3                	mov    %edx,%ebx
  800108:	89 d7                	mov    %edx,%edi
  80010a:	89 d6                	mov    %edx,%esi
  80010c:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  80010e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800111:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800114:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800117:	89 ec                	mov    %ebp,%esp
  800119:	5d                   	pop    %ebp
  80011a:	c3                   	ret    

0080011b <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  80011b:	55                   	push   %ebp
  80011c:	89 e5                	mov    %esp,%ebp
  80011e:	83 ec 38             	sub    $0x38,%esp
  800121:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800124:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800127:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80012a:	b9 00 00 00 00       	mov    $0x0,%ecx
  80012f:	b8 03 00 00 00       	mov    $0x3,%eax
  800134:	8b 55 08             	mov    0x8(%ebp),%edx
  800137:	89 cb                	mov    %ecx,%ebx
  800139:	89 cf                	mov    %ecx,%edi
  80013b:	89 ce                	mov    %ecx,%esi
  80013d:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  80013f:	85 c0                	test   %eax,%eax
  800141:	7e 28                	jle    80016b <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800143:	89 44 24 10          	mov    %eax,0x10(%esp)
  800147:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  80014e:	00 
  80014f:	c7 44 24 08 c0 0e 80 	movl   $0x800ec0,0x8(%esp)
  800156:	00 
  800157:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80015e:	00 
  80015f:	c7 04 24 dd 0e 80 00 	movl   $0x800edd,(%esp)
  800166:	e8 3d 00 00 00       	call   8001a8 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  80016b:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80016e:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800171:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800174:	89 ec                	mov    %ebp,%esp
  800176:	5d                   	pop    %ebp
  800177:	c3                   	ret    

00800178 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800178:	55                   	push   %ebp
  800179:	89 e5                	mov    %esp,%ebp
  80017b:	83 ec 0c             	sub    $0xc,%esp
  80017e:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800181:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800184:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800187:	ba 00 00 00 00       	mov    $0x0,%edx
  80018c:	b8 02 00 00 00       	mov    $0x2,%eax
  800191:	89 d1                	mov    %edx,%ecx
  800193:	89 d3                	mov    %edx,%ebx
  800195:	89 d7                	mov    %edx,%edi
  800197:	89 d6                	mov    %edx,%esi
  800199:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  80019b:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  80019e:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8001a1:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8001a4:	89 ec                	mov    %ebp,%esp
  8001a6:	5d                   	pop    %ebp
  8001a7:	c3                   	ret    

008001a8 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  8001a8:	55                   	push   %ebp
  8001a9:	89 e5                	mov    %esp,%ebp
  8001ab:	56                   	push   %esi
  8001ac:	53                   	push   %ebx
  8001ad:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  8001b0:	8d 75 14             	lea    0x14(%ebp),%esi

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8001b3:	8b 1d 04 20 80 00    	mov    0x802004,%ebx
  8001b9:	e8 ba ff ff ff       	call   800178 <sys_getenvid>
  8001be:	8b 55 0c             	mov    0xc(%ebp),%edx
  8001c1:	89 54 24 10          	mov    %edx,0x10(%esp)
  8001c5:	8b 55 08             	mov    0x8(%ebp),%edx
  8001c8:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8001cc:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8001d0:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001d4:	c7 04 24 ec 0e 80 00 	movl   $0x800eec,(%esp)
  8001db:	e8 c3 00 00 00       	call   8002a3 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8001e0:	89 74 24 04          	mov    %esi,0x4(%esp)
  8001e4:	8b 45 10             	mov    0x10(%ebp),%eax
  8001e7:	89 04 24             	mov    %eax,(%esp)
  8001ea:	e8 53 00 00 00       	call   800242 <vcprintf>
	cprintf("\n");
  8001ef:	c7 04 24 b4 0e 80 00 	movl   $0x800eb4,(%esp)
  8001f6:	e8 a8 00 00 00       	call   8002a3 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8001fb:	cc                   	int3   
  8001fc:	eb fd                	jmp    8001fb <_panic+0x53>
	...

00800200 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800200:	55                   	push   %ebp
  800201:	89 e5                	mov    %esp,%ebp
  800203:	53                   	push   %ebx
  800204:	83 ec 14             	sub    $0x14,%esp
  800207:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80020a:	8b 03                	mov    (%ebx),%eax
  80020c:	8b 55 08             	mov    0x8(%ebp),%edx
  80020f:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  800213:	83 c0 01             	add    $0x1,%eax
  800216:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  800218:	3d ff 00 00 00       	cmp    $0xff,%eax
  80021d:	75 19                	jne    800238 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  80021f:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  800226:	00 
  800227:	8d 43 08             	lea    0x8(%ebx),%eax
  80022a:	89 04 24             	mov    %eax,(%esp)
  80022d:	e8 8a fe ff ff       	call   8000bc <sys_cputs>
		b->idx = 0;
  800232:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800238:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  80023c:	83 c4 14             	add    $0x14,%esp
  80023f:	5b                   	pop    %ebx
  800240:	5d                   	pop    %ebp
  800241:	c3                   	ret    

00800242 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800242:	55                   	push   %ebp
  800243:	89 e5                	mov    %esp,%ebp
  800245:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  80024b:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800252:	00 00 00 
	b.cnt = 0;
  800255:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80025c:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80025f:	8b 45 0c             	mov    0xc(%ebp),%eax
  800262:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800266:	8b 45 08             	mov    0x8(%ebp),%eax
  800269:	89 44 24 08          	mov    %eax,0x8(%esp)
  80026d:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800273:	89 44 24 04          	mov    %eax,0x4(%esp)
  800277:	c7 04 24 00 02 80 00 	movl   $0x800200,(%esp)
  80027e:	e8 8a 01 00 00       	call   80040d <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800283:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800289:	89 44 24 04          	mov    %eax,0x4(%esp)
  80028d:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800293:	89 04 24             	mov    %eax,(%esp)
  800296:	e8 21 fe ff ff       	call   8000bc <sys_cputs>

	return b.cnt;
}
  80029b:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8002a1:	c9                   	leave  
  8002a2:	c3                   	ret    

008002a3 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8002a3:	55                   	push   %ebp
  8002a4:	89 e5                	mov    %esp,%ebp
  8002a6:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8002a9:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8002ac:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002b0:	8b 45 08             	mov    0x8(%ebp),%eax
  8002b3:	89 04 24             	mov    %eax,(%esp)
  8002b6:	e8 87 ff ff ff       	call   800242 <vcprintf>
	va_end(ap);

	return cnt;
}
  8002bb:	c9                   	leave  
  8002bc:	c3                   	ret    
  8002bd:	00 00                	add    %al,(%eax)
	...

008002c0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8002c0:	55                   	push   %ebp
  8002c1:	89 e5                	mov    %esp,%ebp
  8002c3:	57                   	push   %edi
  8002c4:	56                   	push   %esi
  8002c5:	53                   	push   %ebx
  8002c6:	83 ec 3c             	sub    $0x3c,%esp
  8002c9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002cc:	89 d7                	mov    %edx,%edi
  8002ce:	8b 45 08             	mov    0x8(%ebp),%eax
  8002d1:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8002d4:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002d7:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8002da:	8b 5d 14             	mov    0x14(%ebp),%ebx
  8002dd:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8002e0:	85 c0                	test   %eax,%eax
  8002e2:	75 08                	jne    8002ec <printnum+0x2c>
  8002e4:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8002e7:	39 45 10             	cmp    %eax,0x10(%ebp)
  8002ea:	77 59                	ja     800345 <printnum+0x85>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8002ec:	89 74 24 10          	mov    %esi,0x10(%esp)
  8002f0:	83 eb 01             	sub    $0x1,%ebx
  8002f3:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  8002f7:	8b 45 10             	mov    0x10(%ebp),%eax
  8002fa:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002fe:	8b 5c 24 08          	mov    0x8(%esp),%ebx
  800302:	8b 74 24 0c          	mov    0xc(%esp),%esi
  800306:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  80030d:	00 
  80030e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800311:	89 04 24             	mov    %eax,(%esp)
  800314:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800317:	89 44 24 04          	mov    %eax,0x4(%esp)
  80031b:	e8 e0 08 00 00       	call   800c00 <__udivdi3>
  800320:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800324:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800328:	89 04 24             	mov    %eax,(%esp)
  80032b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80032f:	89 fa                	mov    %edi,%edx
  800331:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800334:	e8 87 ff ff ff       	call   8002c0 <printnum>
  800339:	eb 11                	jmp    80034c <printnum+0x8c>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80033b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80033f:	89 34 24             	mov    %esi,(%esp)
  800342:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800345:	83 eb 01             	sub    $0x1,%ebx
  800348:	85 db                	test   %ebx,%ebx
  80034a:	7f ef                	jg     80033b <printnum+0x7b>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80034c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800350:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800354:	8b 45 10             	mov    0x10(%ebp),%eax
  800357:	89 44 24 08          	mov    %eax,0x8(%esp)
  80035b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800362:	00 
  800363:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800366:	89 04 24             	mov    %eax,(%esp)
  800369:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80036c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800370:	e8 bb 09 00 00       	call   800d30 <__umoddi3>
  800375:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800379:	0f be 80 10 0f 80 00 	movsbl 0x800f10(%eax),%eax
  800380:	89 04 24             	mov    %eax,(%esp)
  800383:	ff 55 e4             	call   *-0x1c(%ebp)
}
  800386:	83 c4 3c             	add    $0x3c,%esp
  800389:	5b                   	pop    %ebx
  80038a:	5e                   	pop    %esi
  80038b:	5f                   	pop    %edi
  80038c:	5d                   	pop    %ebp
  80038d:	c3                   	ret    

0080038e <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80038e:	55                   	push   %ebp
  80038f:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800391:	83 fa 01             	cmp    $0x1,%edx
  800394:	7e 0e                	jle    8003a4 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800396:	8b 10                	mov    (%eax),%edx
  800398:	8d 4a 08             	lea    0x8(%edx),%ecx
  80039b:	89 08                	mov    %ecx,(%eax)
  80039d:	8b 02                	mov    (%edx),%eax
  80039f:	8b 52 04             	mov    0x4(%edx),%edx
  8003a2:	eb 22                	jmp    8003c6 <getuint+0x38>
	else if (lflag)
  8003a4:	85 d2                	test   %edx,%edx
  8003a6:	74 10                	je     8003b8 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8003a8:	8b 10                	mov    (%eax),%edx
  8003aa:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003ad:	89 08                	mov    %ecx,(%eax)
  8003af:	8b 02                	mov    (%edx),%eax
  8003b1:	ba 00 00 00 00       	mov    $0x0,%edx
  8003b6:	eb 0e                	jmp    8003c6 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8003b8:	8b 10                	mov    (%eax),%edx
  8003ba:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003bd:	89 08                	mov    %ecx,(%eax)
  8003bf:	8b 02                	mov    (%edx),%eax
  8003c1:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8003c6:	5d                   	pop    %ebp
  8003c7:	c3                   	ret    

008003c8 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8003c8:	55                   	push   %ebp
  8003c9:	89 e5                	mov    %esp,%ebp
  8003cb:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8003ce:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8003d2:	8b 10                	mov    (%eax),%edx
  8003d4:	3b 50 04             	cmp    0x4(%eax),%edx
  8003d7:	73 0a                	jae    8003e3 <sprintputch+0x1b>
		*b->buf++ = ch;
  8003d9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8003dc:	88 0a                	mov    %cl,(%edx)
  8003de:	83 c2 01             	add    $0x1,%edx
  8003e1:	89 10                	mov    %edx,(%eax)
}
  8003e3:	5d                   	pop    %ebp
  8003e4:	c3                   	ret    

008003e5 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8003e5:	55                   	push   %ebp
  8003e6:	89 e5                	mov    %esp,%ebp
  8003e8:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8003eb:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8003ee:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8003f2:	8b 45 10             	mov    0x10(%ebp),%eax
  8003f5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8003f9:	8b 45 0c             	mov    0xc(%ebp),%eax
  8003fc:	89 44 24 04          	mov    %eax,0x4(%esp)
  800400:	8b 45 08             	mov    0x8(%ebp),%eax
  800403:	89 04 24             	mov    %eax,(%esp)
  800406:	e8 02 00 00 00       	call   80040d <vprintfmt>
	va_end(ap);
}
  80040b:	c9                   	leave  
  80040c:	c3                   	ret    

0080040d <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80040d:	55                   	push   %ebp
  80040e:	89 e5                	mov    %esp,%ebp
  800410:	57                   	push   %edi
  800411:	56                   	push   %esi
  800412:	53                   	push   %ebx
  800413:	83 ec 4c             	sub    $0x4c,%esp
  800416:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800419:	8b 75 10             	mov    0x10(%ebp),%esi
  80041c:	eb 12                	jmp    800430 <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80041e:	85 c0                	test   %eax,%eax
  800420:	0f 84 9f 03 00 00    	je     8007c5 <vprintfmt+0x3b8>
				return;
			putch(ch, putdat);
  800426:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80042a:	89 04 24             	mov    %eax,(%esp)
  80042d:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800430:	0f b6 06             	movzbl (%esi),%eax
  800433:	83 c6 01             	add    $0x1,%esi
  800436:	83 f8 25             	cmp    $0x25,%eax
  800439:	75 e3                	jne    80041e <vprintfmt+0x11>
  80043b:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  80043f:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  800446:	bf ff ff ff ff       	mov    $0xffffffff,%edi
  80044b:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
  800452:	b9 00 00 00 00       	mov    $0x0,%ecx
  800457:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80045a:	eb 2b                	jmp    800487 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80045c:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  80045f:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  800463:	eb 22                	jmp    800487 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800465:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800468:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  80046c:	eb 19                	jmp    800487 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80046e:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  800471:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  800478:	eb 0d                	jmp    800487 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  80047a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80047d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800480:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800487:	0f b6 16             	movzbl (%esi),%edx
  80048a:	0f b6 c2             	movzbl %dl,%eax
  80048d:	8d 7e 01             	lea    0x1(%esi),%edi
  800490:	89 7d e0             	mov    %edi,-0x20(%ebp)
  800493:	83 ea 23             	sub    $0x23,%edx
  800496:	80 fa 55             	cmp    $0x55,%dl
  800499:	0f 87 08 03 00 00    	ja     8007a7 <vprintfmt+0x39a>
  80049f:	0f b6 d2             	movzbl %dl,%edx
  8004a2:	ff 24 95 a0 0f 80 00 	jmp    *0x800fa0(,%edx,4)
  8004a9:	8b 75 e0             	mov    -0x20(%ebp),%esi
  8004ac:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
  8004b3:	bf 00 00 00 00       	mov    $0x0,%edi
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8004b8:	8d 14 bf             	lea    (%edi,%edi,4),%edx
  8004bb:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
  8004bf:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  8004c2:	8d 50 d0             	lea    -0x30(%eax),%edx
  8004c5:	83 fa 09             	cmp    $0x9,%edx
  8004c8:	77 2f                	ja     8004f9 <vprintfmt+0xec>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8004ca:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8004cd:	eb e9                	jmp    8004b8 <vprintfmt+0xab>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8004cf:	8b 45 14             	mov    0x14(%ebp),%eax
  8004d2:	8d 50 04             	lea    0x4(%eax),%edx
  8004d5:	89 55 14             	mov    %edx,0x14(%ebp)
  8004d8:	8b 00                	mov    (%eax),%eax
  8004da:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004dd:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8004e0:	eb 1a                	jmp    8004fc <vprintfmt+0xef>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004e2:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
  8004e5:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8004e9:	79 9c                	jns    800487 <vprintfmt+0x7a>
  8004eb:	eb 81                	jmp    80046e <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ed:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8004f0:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
  8004f7:	eb 8e                	jmp    800487 <vprintfmt+0x7a>
  8004f9:	89 7d d4             	mov    %edi,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  8004fc:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800500:	79 85                	jns    800487 <vprintfmt+0x7a>
  800502:	e9 73 ff ff ff       	jmp    80047a <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800507:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80050a:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80050d:	e9 75 ff ff ff       	jmp    800487 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800512:	8b 45 14             	mov    0x14(%ebp),%eax
  800515:	8d 50 04             	lea    0x4(%eax),%edx
  800518:	89 55 14             	mov    %edx,0x14(%ebp)
  80051b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80051f:	8b 00                	mov    (%eax),%eax
  800521:	89 04 24             	mov    %eax,(%esp)
  800524:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800527:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80052a:	e9 01 ff ff ff       	jmp    800430 <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80052f:	8b 45 14             	mov    0x14(%ebp),%eax
  800532:	8d 50 04             	lea    0x4(%eax),%edx
  800535:	89 55 14             	mov    %edx,0x14(%ebp)
  800538:	8b 00                	mov    (%eax),%eax
  80053a:	89 c2                	mov    %eax,%edx
  80053c:	c1 fa 1f             	sar    $0x1f,%edx
  80053f:	31 d0                	xor    %edx,%eax
  800541:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800543:	83 f8 06             	cmp    $0x6,%eax
  800546:	7f 0b                	jg     800553 <vprintfmt+0x146>
  800548:	8b 14 85 f8 10 80 00 	mov    0x8010f8(,%eax,4),%edx
  80054f:	85 d2                	test   %edx,%edx
  800551:	75 23                	jne    800576 <vprintfmt+0x169>
				printfmt(putch, putdat, "error %d", err);
  800553:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800557:	c7 44 24 08 28 0f 80 	movl   $0x800f28,0x8(%esp)
  80055e:	00 
  80055f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800563:	8b 7d 08             	mov    0x8(%ebp),%edi
  800566:	89 3c 24             	mov    %edi,(%esp)
  800569:	e8 77 fe ff ff       	call   8003e5 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80056e:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800571:	e9 ba fe ff ff       	jmp    800430 <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
  800576:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80057a:	c7 44 24 08 31 0f 80 	movl   $0x800f31,0x8(%esp)
  800581:	00 
  800582:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800586:	8b 7d 08             	mov    0x8(%ebp),%edi
  800589:	89 3c 24             	mov    %edi,(%esp)
  80058c:	e8 54 fe ff ff       	call   8003e5 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800591:	8b 75 e0             	mov    -0x20(%ebp),%esi
  800594:	e9 97 fe ff ff       	jmp    800430 <vprintfmt+0x23>
  800599:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80059c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80059f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8005a2:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a5:	8d 50 04             	lea    0x4(%eax),%edx
  8005a8:	89 55 14             	mov    %edx,0x14(%ebp)
  8005ab:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  8005ad:	85 f6                	test   %esi,%esi
  8005af:	ba 21 0f 80 00       	mov    $0x800f21,%edx
  8005b4:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
  8005b7:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  8005bb:	0f 8e 8c 00 00 00    	jle    80064d <vprintfmt+0x240>
  8005c1:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  8005c5:	0f 84 82 00 00 00    	je     80064d <vprintfmt+0x240>
				for (width -= strnlen(p, precision); width > 0; width--)
  8005cb:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005cf:	89 34 24             	mov    %esi,(%esp)
  8005d2:	e8 91 02 00 00       	call   800868 <strnlen>
  8005d7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  8005da:	29 c2                	sub    %eax,%edx
  8005dc:	89 55 e4             	mov    %edx,-0x1c(%ebp)
					putch(padc, putdat);
  8005df:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  8005e3:	89 75 d0             	mov    %esi,-0x30(%ebp)
  8005e6:	89 7d cc             	mov    %edi,-0x34(%ebp)
  8005e9:	89 de                	mov    %ebx,%esi
  8005eb:	89 d3                	mov    %edx,%ebx
  8005ed:	89 c7                	mov    %eax,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005ef:	eb 0d                	jmp    8005fe <vprintfmt+0x1f1>
					putch(padc, putdat);
  8005f1:	89 74 24 04          	mov    %esi,0x4(%esp)
  8005f5:	89 3c 24             	mov    %edi,(%esp)
  8005f8:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005fb:	83 eb 01             	sub    $0x1,%ebx
  8005fe:	85 db                	test   %ebx,%ebx
  800600:	7f ef                	jg     8005f1 <vprintfmt+0x1e4>
  800602:	8b 7d cc             	mov    -0x34(%ebp),%edi
  800605:	89 f3                	mov    %esi,%ebx
  800607:	8b 75 d0             	mov    -0x30(%ebp),%esi

// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
  80060a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  80060e:	b8 00 00 00 00       	mov    $0x0,%eax
  800613:	0f 49 45 e4          	cmovns -0x1c(%ebp),%eax
  800617:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80061a:	29 c2                	sub    %eax,%edx
  80061c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  80061f:	eb 2c                	jmp    80064d <vprintfmt+0x240>
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800621:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800625:	74 18                	je     80063f <vprintfmt+0x232>
  800627:	8d 50 e0             	lea    -0x20(%eax),%edx
  80062a:	83 fa 5e             	cmp    $0x5e,%edx
  80062d:	76 10                	jbe    80063f <vprintfmt+0x232>
					putch('?', putdat);
  80062f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800633:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  80063a:	ff 55 08             	call   *0x8(%ebp)
  80063d:	eb 0a                	jmp    800649 <vprintfmt+0x23c>
				else
					putch(ch, putdat);
  80063f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800643:	89 04 24             	mov    %eax,(%esp)
  800646:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800649:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
  80064d:	0f be 06             	movsbl (%esi),%eax
  800650:	83 c6 01             	add    $0x1,%esi
  800653:	85 c0                	test   %eax,%eax
  800655:	74 25                	je     80067c <vprintfmt+0x26f>
  800657:	85 ff                	test   %edi,%edi
  800659:	78 c6                	js     800621 <vprintfmt+0x214>
  80065b:	83 ef 01             	sub    $0x1,%edi
  80065e:	79 c1                	jns    800621 <vprintfmt+0x214>
  800660:	8b 7d 08             	mov    0x8(%ebp),%edi
  800663:	89 de                	mov    %ebx,%esi
  800665:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800668:	eb 1a                	jmp    800684 <vprintfmt+0x277>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  80066a:	89 74 24 04          	mov    %esi,0x4(%esp)
  80066e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800675:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800677:	83 eb 01             	sub    $0x1,%ebx
  80067a:	eb 08                	jmp    800684 <vprintfmt+0x277>
  80067c:	8b 7d 08             	mov    0x8(%ebp),%edi
  80067f:	89 de                	mov    %ebx,%esi
  800681:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800684:	85 db                	test   %ebx,%ebx
  800686:	7f e2                	jg     80066a <vprintfmt+0x25d>
  800688:	89 7d 08             	mov    %edi,0x8(%ebp)
  80068b:	89 f3                	mov    %esi,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80068d:	8b 75 e0             	mov    -0x20(%ebp),%esi
  800690:	e9 9b fd ff ff       	jmp    800430 <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800695:	83 f9 01             	cmp    $0x1,%ecx
  800698:	7e 10                	jle    8006aa <vprintfmt+0x29d>
		return va_arg(*ap, long long);
  80069a:	8b 45 14             	mov    0x14(%ebp),%eax
  80069d:	8d 50 08             	lea    0x8(%eax),%edx
  8006a0:	89 55 14             	mov    %edx,0x14(%ebp)
  8006a3:	8b 30                	mov    (%eax),%esi
  8006a5:	8b 78 04             	mov    0x4(%eax),%edi
  8006a8:	eb 26                	jmp    8006d0 <vprintfmt+0x2c3>
	else if (lflag)
  8006aa:	85 c9                	test   %ecx,%ecx
  8006ac:	74 12                	je     8006c0 <vprintfmt+0x2b3>
		return va_arg(*ap, long);
  8006ae:	8b 45 14             	mov    0x14(%ebp),%eax
  8006b1:	8d 50 04             	lea    0x4(%eax),%edx
  8006b4:	89 55 14             	mov    %edx,0x14(%ebp)
  8006b7:	8b 30                	mov    (%eax),%esi
  8006b9:	89 f7                	mov    %esi,%edi
  8006bb:	c1 ff 1f             	sar    $0x1f,%edi
  8006be:	eb 10                	jmp    8006d0 <vprintfmt+0x2c3>
	else
		return va_arg(*ap, int);
  8006c0:	8b 45 14             	mov    0x14(%ebp),%eax
  8006c3:	8d 50 04             	lea    0x4(%eax),%edx
  8006c6:	89 55 14             	mov    %edx,0x14(%ebp)
  8006c9:	8b 30                	mov    (%eax),%esi
  8006cb:	89 f7                	mov    %esi,%edi
  8006cd:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8006d0:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8006d5:	85 ff                	test   %edi,%edi
  8006d7:	0f 89 8c 00 00 00    	jns    800769 <vprintfmt+0x35c>
				putch('-', putdat);
  8006dd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006e1:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8006e8:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  8006eb:	f7 de                	neg    %esi
  8006ed:	83 d7 00             	adc    $0x0,%edi
  8006f0:	f7 df                	neg    %edi
			}
			base = 10;
  8006f2:	b8 0a 00 00 00       	mov    $0xa,%eax
  8006f7:	eb 70                	jmp    800769 <vprintfmt+0x35c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8006f9:	89 ca                	mov    %ecx,%edx
  8006fb:	8d 45 14             	lea    0x14(%ebp),%eax
  8006fe:	e8 8b fc ff ff       	call   80038e <getuint>
  800703:	89 c6                	mov    %eax,%esi
  800705:	89 d7                	mov    %edx,%edi
			base = 10;
  800707:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
  80070c:	eb 5b                	jmp    800769 <vprintfmt+0x35c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num=getuint(&ap,lflag);
  80070e:	89 ca                	mov    %ecx,%edx
  800710:	8d 45 14             	lea    0x14(%ebp),%eax
  800713:	e8 76 fc ff ff       	call   80038e <getuint>
  800718:	89 c6                	mov    %eax,%esi
  80071a:	89 d7                	mov    %edx,%edi
			base = 8;
  80071c:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
  800721:	eb 46                	jmp    800769 <vprintfmt+0x35c>
	
		// pointer
		case 'p':
			putch('0', putdat);
  800723:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800727:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80072e:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800731:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800735:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80073c:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80073f:	8b 45 14             	mov    0x14(%ebp),%eax
  800742:	8d 50 04             	lea    0x4(%eax),%edx
  800745:	89 55 14             	mov    %edx,0x14(%ebp)
	
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800748:	8b 30                	mov    (%eax),%esi
  80074a:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80074f:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  800754:	eb 13                	jmp    800769 <vprintfmt+0x35c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800756:	89 ca                	mov    %ecx,%edx
  800758:	8d 45 14             	lea    0x14(%ebp),%eax
  80075b:	e8 2e fc ff ff       	call   80038e <getuint>
  800760:	89 c6                	mov    %eax,%esi
  800762:	89 d7                	mov    %edx,%edi
			base = 16;
  800764:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800769:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
  80076d:	89 54 24 10          	mov    %edx,0x10(%esp)
  800771:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800774:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800778:	89 44 24 08          	mov    %eax,0x8(%esp)
  80077c:	89 34 24             	mov    %esi,(%esp)
  80077f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800783:	89 da                	mov    %ebx,%edx
  800785:	8b 45 08             	mov    0x8(%ebp),%eax
  800788:	e8 33 fb ff ff       	call   8002c0 <printnum>
			break;
  80078d:	8b 75 e0             	mov    -0x20(%ebp),%esi
  800790:	e9 9b fc ff ff       	jmp    800430 <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800795:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800799:	89 04 24             	mov    %eax,(%esp)
  80079c:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80079f:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8007a2:	e9 89 fc ff ff       	jmp    800430 <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8007a7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8007ab:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8007b2:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  8007b5:	eb 03                	jmp    8007ba <vprintfmt+0x3ad>
  8007b7:	83 ee 01             	sub    $0x1,%esi
  8007ba:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
  8007be:	75 f7                	jne    8007b7 <vprintfmt+0x3aa>
  8007c0:	e9 6b fc ff ff       	jmp    800430 <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
  8007c5:	83 c4 4c             	add    $0x4c,%esp
  8007c8:	5b                   	pop    %ebx
  8007c9:	5e                   	pop    %esi
  8007ca:	5f                   	pop    %edi
  8007cb:	5d                   	pop    %ebp
  8007cc:	c3                   	ret    

008007cd <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8007cd:	55                   	push   %ebp
  8007ce:	89 e5                	mov    %esp,%ebp
  8007d0:	83 ec 28             	sub    $0x28,%esp
  8007d3:	8b 45 08             	mov    0x8(%ebp),%eax
  8007d6:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8007d9:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8007dc:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8007e0:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8007e3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8007ea:	85 c0                	test   %eax,%eax
  8007ec:	74 30                	je     80081e <vsnprintf+0x51>
  8007ee:	85 d2                	test   %edx,%edx
  8007f0:	7e 2c                	jle    80081e <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007f2:	8b 45 14             	mov    0x14(%ebp),%eax
  8007f5:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8007f9:	8b 45 10             	mov    0x10(%ebp),%eax
  8007fc:	89 44 24 08          	mov    %eax,0x8(%esp)
  800800:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800803:	89 44 24 04          	mov    %eax,0x4(%esp)
  800807:	c7 04 24 c8 03 80 00 	movl   $0x8003c8,(%esp)
  80080e:	e8 fa fb ff ff       	call   80040d <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800813:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800816:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800819:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80081c:	eb 05                	jmp    800823 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  80081e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800823:	c9                   	leave  
  800824:	c3                   	ret    

00800825 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800825:	55                   	push   %ebp
  800826:	89 e5                	mov    %esp,%ebp
  800828:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80082b:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  80082e:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800832:	8b 45 10             	mov    0x10(%ebp),%eax
  800835:	89 44 24 08          	mov    %eax,0x8(%esp)
  800839:	8b 45 0c             	mov    0xc(%ebp),%eax
  80083c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800840:	8b 45 08             	mov    0x8(%ebp),%eax
  800843:	89 04 24             	mov    %eax,(%esp)
  800846:	e8 82 ff ff ff       	call   8007cd <vsnprintf>
	va_end(ap);

	return rc;
}
  80084b:	c9                   	leave  
  80084c:	c3                   	ret    
  80084d:	00 00                	add    %al,(%eax)
	...

00800850 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800850:	55                   	push   %ebp
  800851:	89 e5                	mov    %esp,%ebp
  800853:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800856:	b8 00 00 00 00       	mov    $0x0,%eax
  80085b:	eb 03                	jmp    800860 <strlen+0x10>
		n++;
  80085d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800860:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800864:	75 f7                	jne    80085d <strlen+0xd>
		n++;
	return n;
}
  800866:	5d                   	pop    %ebp
  800867:	c3                   	ret    

00800868 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800868:	55                   	push   %ebp
  800869:	89 e5                	mov    %esp,%ebp
  80086b:	8b 4d 08             	mov    0x8(%ebp),%ecx
		n++;
	return n;
}

int
strnlen(const char *s, size_t size)
  80086e:	8b 55 0c             	mov    0xc(%ebp),%edx
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800871:	b8 00 00 00 00       	mov    $0x0,%eax
  800876:	eb 03                	jmp    80087b <strnlen+0x13>
		n++;
  800878:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80087b:	39 d0                	cmp    %edx,%eax
  80087d:	74 06                	je     800885 <strnlen+0x1d>
  80087f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800883:	75 f3                	jne    800878 <strnlen+0x10>
		n++;
	return n;
}
  800885:	5d                   	pop    %ebp
  800886:	c3                   	ret    

00800887 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800887:	55                   	push   %ebp
  800888:	89 e5                	mov    %esp,%ebp
  80088a:	53                   	push   %ebx
  80088b:	8b 45 08             	mov    0x8(%ebp),%eax
  80088e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800891:	ba 00 00 00 00       	mov    $0x0,%edx
  800896:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  80089a:	88 0c 10             	mov    %cl,(%eax,%edx,1)
  80089d:	83 c2 01             	add    $0x1,%edx
  8008a0:	84 c9                	test   %cl,%cl
  8008a2:	75 f2                	jne    800896 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
  8008a4:	5b                   	pop    %ebx
  8008a5:	5d                   	pop    %ebp
  8008a6:	c3                   	ret    

008008a7 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8008a7:	55                   	push   %ebp
  8008a8:	89 e5                	mov    %esp,%ebp
  8008aa:	53                   	push   %ebx
  8008ab:	83 ec 08             	sub    $0x8,%esp
  8008ae:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8008b1:	89 1c 24             	mov    %ebx,(%esp)
  8008b4:	e8 97 ff ff ff       	call   800850 <strlen>
	strcpy(dst + len, src);
  8008b9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008bc:	89 54 24 04          	mov    %edx,0x4(%esp)
  8008c0:	01 d8                	add    %ebx,%eax
  8008c2:	89 04 24             	mov    %eax,(%esp)
  8008c5:	e8 bd ff ff ff       	call   800887 <strcpy>
	return dst;
}
  8008ca:	89 d8                	mov    %ebx,%eax
  8008cc:	83 c4 08             	add    $0x8,%esp
  8008cf:	5b                   	pop    %ebx
  8008d0:	5d                   	pop    %ebp
  8008d1:	c3                   	ret    

008008d2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8008d2:	55                   	push   %ebp
  8008d3:	89 e5                	mov    %esp,%ebp
  8008d5:	56                   	push   %esi
  8008d6:	53                   	push   %ebx
  8008d7:	8b 45 08             	mov    0x8(%ebp),%eax
  8008da:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008dd:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008e0:	b9 00 00 00 00       	mov    $0x0,%ecx
  8008e5:	eb 0f                	jmp    8008f6 <strncpy+0x24>
		*dst++ = *src;
  8008e7:	0f b6 1a             	movzbl (%edx),%ebx
  8008ea:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8008ed:	80 3a 01             	cmpb   $0x1,(%edx)
  8008f0:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008f3:	83 c1 01             	add    $0x1,%ecx
  8008f6:	39 f1                	cmp    %esi,%ecx
  8008f8:	75 ed                	jne    8008e7 <strncpy+0x15>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8008fa:	5b                   	pop    %ebx
  8008fb:	5e                   	pop    %esi
  8008fc:	5d                   	pop    %ebp
  8008fd:	c3                   	ret    

008008fe <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8008fe:	55                   	push   %ebp
  8008ff:	89 e5                	mov    %esp,%ebp
  800901:	56                   	push   %esi
  800902:	53                   	push   %ebx
  800903:	8b 75 08             	mov    0x8(%ebp),%esi
  800906:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800909:	8b 55 10             	mov    0x10(%ebp),%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80090c:	89 f0                	mov    %esi,%eax
  80090e:	85 d2                	test   %edx,%edx
  800910:	75 0a                	jne    80091c <strlcpy+0x1e>
  800912:	eb 1d                	jmp    800931 <strlcpy+0x33>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800914:	88 18                	mov    %bl,(%eax)
  800916:	83 c0 01             	add    $0x1,%eax
  800919:	83 c1 01             	add    $0x1,%ecx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  80091c:	83 ea 01             	sub    $0x1,%edx
  80091f:	74 0b                	je     80092c <strlcpy+0x2e>
  800921:	0f b6 19             	movzbl (%ecx),%ebx
  800924:	84 db                	test   %bl,%bl
  800926:	75 ec                	jne    800914 <strlcpy+0x16>
  800928:	89 c2                	mov    %eax,%edx
  80092a:	eb 02                	jmp    80092e <strlcpy+0x30>
  80092c:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  80092e:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800931:	29 f0                	sub    %esi,%eax
}
  800933:	5b                   	pop    %ebx
  800934:	5e                   	pop    %esi
  800935:	5d                   	pop    %ebp
  800936:	c3                   	ret    

00800937 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800937:	55                   	push   %ebp
  800938:	89 e5                	mov    %esp,%ebp
  80093a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80093d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800940:	eb 06                	jmp    800948 <strcmp+0x11>
		p++, q++;
  800942:	83 c1 01             	add    $0x1,%ecx
  800945:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800948:	0f b6 01             	movzbl (%ecx),%eax
  80094b:	84 c0                	test   %al,%al
  80094d:	74 04                	je     800953 <strcmp+0x1c>
  80094f:	3a 02                	cmp    (%edx),%al
  800951:	74 ef                	je     800942 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800953:	0f b6 c0             	movzbl %al,%eax
  800956:	0f b6 12             	movzbl (%edx),%edx
  800959:	29 d0                	sub    %edx,%eax
}
  80095b:	5d                   	pop    %ebp
  80095c:	c3                   	ret    

0080095d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80095d:	55                   	push   %ebp
  80095e:	89 e5                	mov    %esp,%ebp
  800960:	53                   	push   %ebx
  800961:	8b 45 08             	mov    0x8(%ebp),%eax
  800964:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800967:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
  80096a:	eb 09                	jmp    800975 <strncmp+0x18>
		n--, p++, q++;
  80096c:	83 ea 01             	sub    $0x1,%edx
  80096f:	83 c0 01             	add    $0x1,%eax
  800972:	83 c1 01             	add    $0x1,%ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800975:	85 d2                	test   %edx,%edx
  800977:	74 15                	je     80098e <strncmp+0x31>
  800979:	0f b6 18             	movzbl (%eax),%ebx
  80097c:	84 db                	test   %bl,%bl
  80097e:	74 04                	je     800984 <strncmp+0x27>
  800980:	3a 19                	cmp    (%ecx),%bl
  800982:	74 e8                	je     80096c <strncmp+0xf>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800984:	0f b6 00             	movzbl (%eax),%eax
  800987:	0f b6 11             	movzbl (%ecx),%edx
  80098a:	29 d0                	sub    %edx,%eax
  80098c:	eb 05                	jmp    800993 <strncmp+0x36>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  80098e:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800993:	5b                   	pop    %ebx
  800994:	5d                   	pop    %ebp
  800995:	c3                   	ret    

00800996 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800996:	55                   	push   %ebp
  800997:	89 e5                	mov    %esp,%ebp
  800999:	8b 45 08             	mov    0x8(%ebp),%eax
  80099c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009a0:	eb 07                	jmp    8009a9 <strchr+0x13>
		if (*s == c)
  8009a2:	38 ca                	cmp    %cl,%dl
  8009a4:	74 0f                	je     8009b5 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8009a6:	83 c0 01             	add    $0x1,%eax
  8009a9:	0f b6 10             	movzbl (%eax),%edx
  8009ac:	84 d2                	test   %dl,%dl
  8009ae:	75 f2                	jne    8009a2 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8009b0:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009b5:	5d                   	pop    %ebp
  8009b6:	c3                   	ret    

008009b7 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8009b7:	55                   	push   %ebp
  8009b8:	89 e5                	mov    %esp,%ebp
  8009ba:	8b 45 08             	mov    0x8(%ebp),%eax
  8009bd:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009c1:	eb 07                	jmp    8009ca <strfind+0x13>
		if (*s == c)
  8009c3:	38 ca                	cmp    %cl,%dl
  8009c5:	74 0a                	je     8009d1 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  8009c7:	83 c0 01             	add    $0x1,%eax
  8009ca:	0f b6 10             	movzbl (%eax),%edx
  8009cd:	84 d2                	test   %dl,%dl
  8009cf:	75 f2                	jne    8009c3 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  8009d1:	5d                   	pop    %ebp
  8009d2:	c3                   	ret    

008009d3 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8009d3:	55                   	push   %ebp
  8009d4:	89 e5                	mov    %esp,%ebp
  8009d6:	83 ec 0c             	sub    $0xc,%esp
  8009d9:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8009dc:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8009df:	89 7d fc             	mov    %edi,-0x4(%ebp)
  8009e2:	8b 7d 08             	mov    0x8(%ebp),%edi
  8009e5:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009e8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8009eb:	85 c9                	test   %ecx,%ecx
  8009ed:	74 30                	je     800a1f <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8009ef:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8009f5:	75 25                	jne    800a1c <memset+0x49>
  8009f7:	f6 c1 03             	test   $0x3,%cl
  8009fa:	75 20                	jne    800a1c <memset+0x49>
		c &= 0xFF;
  8009fc:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8009ff:	89 d3                	mov    %edx,%ebx
  800a01:	c1 e3 08             	shl    $0x8,%ebx
  800a04:	89 d6                	mov    %edx,%esi
  800a06:	c1 e6 18             	shl    $0x18,%esi
  800a09:	89 d0                	mov    %edx,%eax
  800a0b:	c1 e0 10             	shl    $0x10,%eax
  800a0e:	09 f0                	or     %esi,%eax
  800a10:	09 d0                	or     %edx,%eax
  800a12:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800a14:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800a17:	fc                   	cld    
  800a18:	f3 ab                	rep stos %eax,%es:(%edi)
  800a1a:	eb 03                	jmp    800a1f <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a1c:	fc                   	cld    
  800a1d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800a1f:	89 f8                	mov    %edi,%eax
  800a21:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800a24:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800a27:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800a2a:	89 ec                	mov    %ebp,%esp
  800a2c:	5d                   	pop    %ebp
  800a2d:	c3                   	ret    

00800a2e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a2e:	55                   	push   %ebp
  800a2f:	89 e5                	mov    %esp,%ebp
  800a31:	83 ec 08             	sub    $0x8,%esp
  800a34:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800a37:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800a3a:	8b 45 08             	mov    0x8(%ebp),%eax
  800a3d:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a40:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a43:	39 c6                	cmp    %eax,%esi
  800a45:	73 36                	jae    800a7d <memmove+0x4f>
  800a47:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a4a:	39 d0                	cmp    %edx,%eax
  800a4c:	73 2f                	jae    800a7d <memmove+0x4f>
		s += n;
		d += n;
  800a4e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a51:	f6 c2 03             	test   $0x3,%dl
  800a54:	75 1b                	jne    800a71 <memmove+0x43>
  800a56:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a5c:	75 13                	jne    800a71 <memmove+0x43>
  800a5e:	f6 c1 03             	test   $0x3,%cl
  800a61:	75 0e                	jne    800a71 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800a63:	83 ef 04             	sub    $0x4,%edi
  800a66:	8d 72 fc             	lea    -0x4(%edx),%esi
  800a69:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800a6c:	fd                   	std    
  800a6d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a6f:	eb 09                	jmp    800a7a <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800a71:	83 ef 01             	sub    $0x1,%edi
  800a74:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800a77:	fd                   	std    
  800a78:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a7a:	fc                   	cld    
  800a7b:	eb 20                	jmp    800a9d <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a7d:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a83:	75 13                	jne    800a98 <memmove+0x6a>
  800a85:	a8 03                	test   $0x3,%al
  800a87:	75 0f                	jne    800a98 <memmove+0x6a>
  800a89:	f6 c1 03             	test   $0x3,%cl
  800a8c:	75 0a                	jne    800a98 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800a8e:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800a91:	89 c7                	mov    %eax,%edi
  800a93:	fc                   	cld    
  800a94:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a96:	eb 05                	jmp    800a9d <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a98:	89 c7                	mov    %eax,%edi
  800a9a:	fc                   	cld    
  800a9b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a9d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800aa0:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800aa3:	89 ec                	mov    %ebp,%esp
  800aa5:	5d                   	pop    %ebp
  800aa6:	c3                   	ret    

00800aa7 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800aa7:	55                   	push   %ebp
  800aa8:	89 e5                	mov    %esp,%ebp
  800aaa:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800aad:	8b 45 10             	mov    0x10(%ebp),%eax
  800ab0:	89 44 24 08          	mov    %eax,0x8(%esp)
  800ab4:	8b 45 0c             	mov    0xc(%ebp),%eax
  800ab7:	89 44 24 04          	mov    %eax,0x4(%esp)
  800abb:	8b 45 08             	mov    0x8(%ebp),%eax
  800abe:	89 04 24             	mov    %eax,(%esp)
  800ac1:	e8 68 ff ff ff       	call   800a2e <memmove>
}
  800ac6:	c9                   	leave  
  800ac7:	c3                   	ret    

00800ac8 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800ac8:	55                   	push   %ebp
  800ac9:	89 e5                	mov    %esp,%ebp
  800acb:	57                   	push   %edi
  800acc:	56                   	push   %esi
  800acd:	53                   	push   %ebx
  800ace:	8b 7d 08             	mov    0x8(%ebp),%edi
  800ad1:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ad4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800ad7:	ba 00 00 00 00       	mov    $0x0,%edx
  800adc:	eb 1a                	jmp    800af8 <memcmp+0x30>
		if (*s1 != *s2)
  800ade:	0f b6 04 17          	movzbl (%edi,%edx,1),%eax
  800ae2:	83 c2 01             	add    $0x1,%edx
  800ae5:	0f b6 4c 16 ff       	movzbl -0x1(%esi,%edx,1),%ecx
  800aea:	38 c8                	cmp    %cl,%al
  800aec:	74 0a                	je     800af8 <memcmp+0x30>
			return (int) *s1 - (int) *s2;
  800aee:	0f b6 c0             	movzbl %al,%eax
  800af1:	0f b6 c9             	movzbl %cl,%ecx
  800af4:	29 c8                	sub    %ecx,%eax
  800af6:	eb 09                	jmp    800b01 <memcmp+0x39>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800af8:	39 da                	cmp    %ebx,%edx
  800afa:	75 e2                	jne    800ade <memcmp+0x16>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800afc:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b01:	5b                   	pop    %ebx
  800b02:	5e                   	pop    %esi
  800b03:	5f                   	pop    %edi
  800b04:	5d                   	pop    %ebp
  800b05:	c3                   	ret    

00800b06 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800b06:	55                   	push   %ebp
  800b07:	89 e5                	mov    %esp,%ebp
  800b09:	8b 45 08             	mov    0x8(%ebp),%eax
  800b0c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800b0f:	89 c2                	mov    %eax,%edx
  800b11:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800b14:	eb 07                	jmp    800b1d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800b16:	38 08                	cmp    %cl,(%eax)
  800b18:	74 07                	je     800b21 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800b1a:	83 c0 01             	add    $0x1,%eax
  800b1d:	39 d0                	cmp    %edx,%eax
  800b1f:	72 f5                	jb     800b16 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800b21:	5d                   	pop    %ebp
  800b22:	c3                   	ret    

00800b23 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b23:	55                   	push   %ebp
  800b24:	89 e5                	mov    %esp,%ebp
  800b26:	57                   	push   %edi
  800b27:	56                   	push   %esi
  800b28:	53                   	push   %ebx
  800b29:	8b 55 08             	mov    0x8(%ebp),%edx
  800b2c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b2f:	eb 03                	jmp    800b34 <strtol+0x11>
		s++;
  800b31:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b34:	0f b6 02             	movzbl (%edx),%eax
  800b37:	3c 20                	cmp    $0x20,%al
  800b39:	74 f6                	je     800b31 <strtol+0xe>
  800b3b:	3c 09                	cmp    $0x9,%al
  800b3d:	74 f2                	je     800b31 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b3f:	3c 2b                	cmp    $0x2b,%al
  800b41:	75 0a                	jne    800b4d <strtol+0x2a>
		s++;
  800b43:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b46:	bf 00 00 00 00       	mov    $0x0,%edi
  800b4b:	eb 10                	jmp    800b5d <strtol+0x3a>
  800b4d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b52:	3c 2d                	cmp    $0x2d,%al
  800b54:	75 07                	jne    800b5d <strtol+0x3a>
		s++, neg = 1;
  800b56:	8d 52 01             	lea    0x1(%edx),%edx
  800b59:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b5d:	85 db                	test   %ebx,%ebx
  800b5f:	0f 94 c0             	sete   %al
  800b62:	74 05                	je     800b69 <strtol+0x46>
  800b64:	83 fb 10             	cmp    $0x10,%ebx
  800b67:	75 15                	jne    800b7e <strtol+0x5b>
  800b69:	80 3a 30             	cmpb   $0x30,(%edx)
  800b6c:	75 10                	jne    800b7e <strtol+0x5b>
  800b6e:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800b72:	75 0a                	jne    800b7e <strtol+0x5b>
		s += 2, base = 16;
  800b74:	83 c2 02             	add    $0x2,%edx
  800b77:	bb 10 00 00 00       	mov    $0x10,%ebx
  800b7c:	eb 13                	jmp    800b91 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800b7e:	84 c0                	test   %al,%al
  800b80:	74 0f                	je     800b91 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b82:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b87:	80 3a 30             	cmpb   $0x30,(%edx)
  800b8a:	75 05                	jne    800b91 <strtol+0x6e>
		s++, base = 8;
  800b8c:	83 c2 01             	add    $0x1,%edx
  800b8f:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800b91:	b8 00 00 00 00       	mov    $0x0,%eax
  800b96:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b98:	0f b6 0a             	movzbl (%edx),%ecx
  800b9b:	8d 59 d0             	lea    -0x30(%ecx),%ebx
  800b9e:	80 fb 09             	cmp    $0x9,%bl
  800ba1:	77 08                	ja     800bab <strtol+0x88>
			dig = *s - '0';
  800ba3:	0f be c9             	movsbl %cl,%ecx
  800ba6:	83 e9 30             	sub    $0x30,%ecx
  800ba9:	eb 1e                	jmp    800bc9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800bab:	8d 59 9f             	lea    -0x61(%ecx),%ebx
  800bae:	80 fb 19             	cmp    $0x19,%bl
  800bb1:	77 08                	ja     800bbb <strtol+0x98>
			dig = *s - 'a' + 10;
  800bb3:	0f be c9             	movsbl %cl,%ecx
  800bb6:	83 e9 57             	sub    $0x57,%ecx
  800bb9:	eb 0e                	jmp    800bc9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800bbb:	8d 59 bf             	lea    -0x41(%ecx),%ebx
  800bbe:	80 fb 19             	cmp    $0x19,%bl
  800bc1:	77 14                	ja     800bd7 <strtol+0xb4>
			dig = *s - 'A' + 10;
  800bc3:	0f be c9             	movsbl %cl,%ecx
  800bc6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800bc9:	39 f1                	cmp    %esi,%ecx
  800bcb:	7d 0e                	jge    800bdb <strtol+0xb8>
			break;
		s++, val = (val * base) + dig;
  800bcd:	83 c2 01             	add    $0x1,%edx
  800bd0:	0f af c6             	imul   %esi,%eax
  800bd3:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800bd5:	eb c1                	jmp    800b98 <strtol+0x75>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800bd7:	89 c1                	mov    %eax,%ecx
  800bd9:	eb 02                	jmp    800bdd <strtol+0xba>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800bdb:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800bdd:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800be1:	74 05                	je     800be8 <strtol+0xc5>
		*endptr = (char *) s;
  800be3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800be6:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800be8:	89 ca                	mov    %ecx,%edx
  800bea:	f7 da                	neg    %edx
  800bec:	85 ff                	test   %edi,%edi
  800bee:	0f 45 c2             	cmovne %edx,%eax
}
  800bf1:	5b                   	pop    %ebx
  800bf2:	5e                   	pop    %esi
  800bf3:	5f                   	pop    %edi
  800bf4:	5d                   	pop    %ebp
  800bf5:	c3                   	ret    
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
