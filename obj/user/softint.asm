
obj/user/softint:     file format elf32-i386


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
  80002c:	e8 0b 00 00 00       	call   80003c <libmain>
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
	asm volatile("int $14");	// page fault
  800037:	cd 0e                	int    $0xe
}
  800039:	5d                   	pop    %ebp
  80003a:	c3                   	ret    
	...

0080003c <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80003c:	55                   	push   %ebp
  80003d:	89 e5                	mov    %esp,%ebp
  80003f:	83 ec 18             	sub    $0x18,%esp
  800042:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  800045:	89 75 fc             	mov    %esi,-0x4(%ebp)
  800048:	8b 75 08             	mov    0x8(%ebp),%esi
  80004b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = &envs[ENVX(sys_getenvid())];
  80004e:	e8 0d 01 00 00       	call   800160 <sys_getenvid>
  800053:	25 ff 03 00 00       	and    $0x3ff,%eax
  800058:	8d 04 40             	lea    (%eax,%eax,2),%eax
  80005b:	c1 e0 05             	shl    $0x5,%eax
  80005e:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800063:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800068:	85 f6                	test   %esi,%esi
  80006a:	7e 07                	jle    800073 <libmain+0x37>
		binaryname = argv[0];
  80006c:	8b 03                	mov    (%ebx),%eax
  80006e:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800073:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800077:	89 34 24             	mov    %esi,(%esp)
  80007a:	e8 b5 ff ff ff       	call   800034 <umain>

	// exit gracefully
	exit();
  80007f:	e8 0c 00 00 00       	call   800090 <exit>
}
  800084:	8b 5d f8             	mov    -0x8(%ebp),%ebx
  800087:	8b 75 fc             	mov    -0x4(%ebp),%esi
  80008a:	89 ec                	mov    %ebp,%esp
  80008c:	5d                   	pop    %ebp
  80008d:	c3                   	ret    
	...

00800090 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800090:	55                   	push   %ebp
  800091:	89 e5                	mov    %esp,%ebp
  800093:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  800096:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80009d:	e8 61 00 00 00       	call   800103 <sys_env_destroy>
}
  8000a2:	c9                   	leave  
  8000a3:	c3                   	ret    

008000a4 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000a4:	55                   	push   %ebp
  8000a5:	89 e5                	mov    %esp,%ebp
  8000a7:	83 ec 0c             	sub    $0xc,%esp
  8000aa:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8000ad:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8000b0:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000b3:	b8 00 00 00 00       	mov    $0x0,%eax
  8000b8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000bb:	8b 55 08             	mov    0x8(%ebp),%edx
  8000be:	89 c3                	mov    %eax,%ebx
  8000c0:	89 c7                	mov    %eax,%edi
  8000c2:	89 c6                	mov    %eax,%esi
  8000c4:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000c6:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8000c9:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8000cc:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8000cf:	89 ec                	mov    %ebp,%esp
  8000d1:	5d                   	pop    %ebp
  8000d2:	c3                   	ret    

008000d3 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000d3:	55                   	push   %ebp
  8000d4:	89 e5                	mov    %esp,%ebp
  8000d6:	83 ec 0c             	sub    $0xc,%esp
  8000d9:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8000dc:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8000df:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000e2:	ba 00 00 00 00       	mov    $0x0,%edx
  8000e7:	b8 01 00 00 00       	mov    $0x1,%eax
  8000ec:	89 d1                	mov    %edx,%ecx
  8000ee:	89 d3                	mov    %edx,%ebx
  8000f0:	89 d7                	mov    %edx,%edi
  8000f2:	89 d6                	mov    %edx,%esi
  8000f4:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000f6:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  8000f9:	8b 75 f8             	mov    -0x8(%ebp),%esi
  8000fc:	8b 7d fc             	mov    -0x4(%ebp),%edi
  8000ff:	89 ec                	mov    %ebp,%esp
  800101:	5d                   	pop    %ebp
  800102:	c3                   	ret    

00800103 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800103:	55                   	push   %ebp
  800104:	89 e5                	mov    %esp,%ebp
  800106:	83 ec 38             	sub    $0x38,%esp
  800109:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  80010c:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80010f:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800112:	b9 00 00 00 00       	mov    $0x0,%ecx
  800117:	b8 03 00 00 00       	mov    $0x3,%eax
  80011c:	8b 55 08             	mov    0x8(%ebp),%edx
  80011f:	89 cb                	mov    %ecx,%ebx
  800121:	89 cf                	mov    %ecx,%edi
  800123:	89 ce                	mov    %ecx,%esi
  800125:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800127:	85 c0                	test   %eax,%eax
  800129:	7e 28                	jle    800153 <sys_env_destroy+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  80012b:	89 44 24 10          	mov    %eax,0x10(%esp)
  80012f:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800136:	00 
  800137:	c7 44 24 08 a2 0e 80 	movl   $0x800ea2,0x8(%esp)
  80013e:	00 
  80013f:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800146:	00 
  800147:	c7 04 24 bf 0e 80 00 	movl   $0x800ebf,(%esp)
  80014e:	e8 3d 00 00 00       	call   800190 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800153:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800156:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800159:	8b 7d fc             	mov    -0x4(%ebp),%edi
  80015c:	89 ec                	mov    %ebp,%esp
  80015e:	5d                   	pop    %ebp
  80015f:	c3                   	ret    

00800160 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800160:	55                   	push   %ebp
  800161:	89 e5                	mov    %esp,%ebp
  800163:	83 ec 0c             	sub    $0xc,%esp
  800166:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  800169:	89 75 f8             	mov    %esi,-0x8(%ebp)
  80016c:	89 7d fc             	mov    %edi,-0x4(%ebp)
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80016f:	ba 00 00 00 00       	mov    $0x0,%edx
  800174:	b8 02 00 00 00       	mov    $0x2,%eax
  800179:	89 d1                	mov    %edx,%ecx
  80017b:	89 d3                	mov    %edx,%ebx
  80017d:	89 d7                	mov    %edx,%edi
  80017f:	89 d6                	mov    %edx,%esi
  800181:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800183:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800186:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800189:	8b 7d fc             	mov    -0x4(%ebp),%edi
  80018c:	89 ec                	mov    %ebp,%esp
  80018e:	5d                   	pop    %ebp
  80018f:	c3                   	ret    

00800190 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800190:	55                   	push   %ebp
  800191:	89 e5                	mov    %esp,%ebp
  800193:	56                   	push   %esi
  800194:	53                   	push   %ebx
  800195:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800198:	8d 75 14             	lea    0x14(%ebp),%esi

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80019b:	8b 1d 00 20 80 00    	mov    0x802000,%ebx
  8001a1:	e8 ba ff ff ff       	call   800160 <sys_getenvid>
  8001a6:	8b 55 0c             	mov    0xc(%ebp),%edx
  8001a9:	89 54 24 10          	mov    %edx,0x10(%esp)
  8001ad:	8b 55 08             	mov    0x8(%ebp),%edx
  8001b0:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8001b4:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  8001b8:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001bc:	c7 04 24 d0 0e 80 00 	movl   $0x800ed0,(%esp)
  8001c3:	e8 c3 00 00 00       	call   80028b <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8001c8:	89 74 24 04          	mov    %esi,0x4(%esp)
  8001cc:	8b 45 10             	mov    0x10(%ebp),%eax
  8001cf:	89 04 24             	mov    %eax,(%esp)
  8001d2:	e8 53 00 00 00       	call   80022a <vcprintf>
	cprintf("\n");
  8001d7:	c7 04 24 f4 0e 80 00 	movl   $0x800ef4,(%esp)
  8001de:	e8 a8 00 00 00       	call   80028b <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8001e3:	cc                   	int3   
  8001e4:	eb fd                	jmp    8001e3 <_panic+0x53>
	...

008001e8 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8001e8:	55                   	push   %ebp
  8001e9:	89 e5                	mov    %esp,%ebp
  8001eb:	53                   	push   %ebx
  8001ec:	83 ec 14             	sub    $0x14,%esp
  8001ef:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001f2:	8b 03                	mov    (%ebx),%eax
  8001f4:	8b 55 08             	mov    0x8(%ebp),%edx
  8001f7:	88 54 03 08          	mov    %dl,0x8(%ebx,%eax,1)
  8001fb:	83 c0 01             	add    $0x1,%eax
  8001fe:	89 03                	mov    %eax,(%ebx)
	if (b->idx == 256-1) {
  800200:	3d ff 00 00 00       	cmp    $0xff,%eax
  800205:	75 19                	jne    800220 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  800207:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  80020e:	00 
  80020f:	8d 43 08             	lea    0x8(%ebx),%eax
  800212:	89 04 24             	mov    %eax,(%esp)
  800215:	e8 8a fe ff ff       	call   8000a4 <sys_cputs>
		b->idx = 0;
  80021a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800220:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800224:	83 c4 14             	add    $0x14,%esp
  800227:	5b                   	pop    %ebx
  800228:	5d                   	pop    %ebp
  800229:	c3                   	ret    

0080022a <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80022a:	55                   	push   %ebp
  80022b:	89 e5                	mov    %esp,%ebp
  80022d:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800233:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80023a:	00 00 00 
	b.cnt = 0;
  80023d:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800244:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800247:	8b 45 0c             	mov    0xc(%ebp),%eax
  80024a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80024e:	8b 45 08             	mov    0x8(%ebp),%eax
  800251:	89 44 24 08          	mov    %eax,0x8(%esp)
  800255:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80025b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80025f:	c7 04 24 e8 01 80 00 	movl   $0x8001e8,(%esp)
  800266:	e8 92 01 00 00       	call   8003fd <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80026b:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800271:	89 44 24 04          	mov    %eax,0x4(%esp)
  800275:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80027b:	89 04 24             	mov    %eax,(%esp)
  80027e:	e8 21 fe ff ff       	call   8000a4 <sys_cputs>

	return b.cnt;
}
  800283:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800289:	c9                   	leave  
  80028a:	c3                   	ret    

0080028b <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80028b:	55                   	push   %ebp
  80028c:	89 e5                	mov    %esp,%ebp
  80028e:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800291:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800294:	89 44 24 04          	mov    %eax,0x4(%esp)
  800298:	8b 45 08             	mov    0x8(%ebp),%eax
  80029b:	89 04 24             	mov    %eax,(%esp)
  80029e:	e8 87 ff ff ff       	call   80022a <vcprintf>
	va_end(ap);

	return cnt;
}
  8002a3:	c9                   	leave  
  8002a4:	c3                   	ret    
	...

008002b0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8002b0:	55                   	push   %ebp
  8002b1:	89 e5                	mov    %esp,%ebp
  8002b3:	57                   	push   %edi
  8002b4:	56                   	push   %esi
  8002b5:	53                   	push   %ebx
  8002b6:	83 ec 3c             	sub    $0x3c,%esp
  8002b9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002bc:	89 d7                	mov    %edx,%edi
  8002be:	8b 45 08             	mov    0x8(%ebp),%eax
  8002c1:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8002c4:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002c7:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8002ca:	8b 5d 14             	mov    0x14(%ebp),%ebx
  8002cd:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8002d0:	85 c0                	test   %eax,%eax
  8002d2:	75 08                	jne    8002dc <printnum+0x2c>
  8002d4:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8002d7:	39 45 10             	cmp    %eax,0x10(%ebp)
  8002da:	77 59                	ja     800335 <printnum+0x85>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8002dc:	89 74 24 10          	mov    %esi,0x10(%esp)
  8002e0:	83 eb 01             	sub    $0x1,%ebx
  8002e3:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  8002e7:	8b 45 10             	mov    0x10(%ebp),%eax
  8002ea:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002ee:	8b 5c 24 08          	mov    0x8(%esp),%ebx
  8002f2:	8b 74 24 0c          	mov    0xc(%esp),%esi
  8002f6:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  8002fd:	00 
  8002fe:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800301:	89 04 24             	mov    %eax,(%esp)
  800304:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800307:	89 44 24 04          	mov    %eax,0x4(%esp)
  80030b:	e8 e0 08 00 00       	call   800bf0 <__udivdi3>
  800310:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800314:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800318:	89 04 24             	mov    %eax,(%esp)
  80031b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80031f:	89 fa                	mov    %edi,%edx
  800321:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800324:	e8 87 ff ff ff       	call   8002b0 <printnum>
  800329:	eb 11                	jmp    80033c <printnum+0x8c>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80032b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80032f:	89 34 24             	mov    %esi,(%esp)
  800332:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800335:	83 eb 01             	sub    $0x1,%ebx
  800338:	85 db                	test   %ebx,%ebx
  80033a:	7f ef                	jg     80032b <printnum+0x7b>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80033c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800340:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800344:	8b 45 10             	mov    0x10(%ebp),%eax
  800347:	89 44 24 08          	mov    %eax,0x8(%esp)
  80034b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800352:	00 
  800353:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800356:	89 04 24             	mov    %eax,(%esp)
  800359:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80035c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800360:	e8 bb 09 00 00       	call   800d20 <__umoddi3>
  800365:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800369:	0f be 80 f6 0e 80 00 	movsbl 0x800ef6(%eax),%eax
  800370:	89 04 24             	mov    %eax,(%esp)
  800373:	ff 55 e4             	call   *-0x1c(%ebp)
}
  800376:	83 c4 3c             	add    $0x3c,%esp
  800379:	5b                   	pop    %ebx
  80037a:	5e                   	pop    %esi
  80037b:	5f                   	pop    %edi
  80037c:	5d                   	pop    %ebp
  80037d:	c3                   	ret    

0080037e <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80037e:	55                   	push   %ebp
  80037f:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800381:	83 fa 01             	cmp    $0x1,%edx
  800384:	7e 0e                	jle    800394 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800386:	8b 10                	mov    (%eax),%edx
  800388:	8d 4a 08             	lea    0x8(%edx),%ecx
  80038b:	89 08                	mov    %ecx,(%eax)
  80038d:	8b 02                	mov    (%edx),%eax
  80038f:	8b 52 04             	mov    0x4(%edx),%edx
  800392:	eb 22                	jmp    8003b6 <getuint+0x38>
	else if (lflag)
  800394:	85 d2                	test   %edx,%edx
  800396:	74 10                	je     8003a8 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800398:	8b 10                	mov    (%eax),%edx
  80039a:	8d 4a 04             	lea    0x4(%edx),%ecx
  80039d:	89 08                	mov    %ecx,(%eax)
  80039f:	8b 02                	mov    (%edx),%eax
  8003a1:	ba 00 00 00 00       	mov    $0x0,%edx
  8003a6:	eb 0e                	jmp    8003b6 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8003a8:	8b 10                	mov    (%eax),%edx
  8003aa:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003ad:	89 08                	mov    %ecx,(%eax)
  8003af:	8b 02                	mov    (%edx),%eax
  8003b1:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8003b6:	5d                   	pop    %ebp
  8003b7:	c3                   	ret    

008003b8 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8003b8:	55                   	push   %ebp
  8003b9:	89 e5                	mov    %esp,%ebp
  8003bb:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8003be:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8003c2:	8b 10                	mov    (%eax),%edx
  8003c4:	3b 50 04             	cmp    0x4(%eax),%edx
  8003c7:	73 0a                	jae    8003d3 <sprintputch+0x1b>
		*b->buf++ = ch;
  8003c9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8003cc:	88 0a                	mov    %cl,(%edx)
  8003ce:	83 c2 01             	add    $0x1,%edx
  8003d1:	89 10                	mov    %edx,(%eax)
}
  8003d3:	5d                   	pop    %ebp
  8003d4:	c3                   	ret    

008003d5 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8003d5:	55                   	push   %ebp
  8003d6:	89 e5                	mov    %esp,%ebp
  8003d8:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8003db:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8003de:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8003e2:	8b 45 10             	mov    0x10(%ebp),%eax
  8003e5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8003e9:	8b 45 0c             	mov    0xc(%ebp),%eax
  8003ec:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003f0:	8b 45 08             	mov    0x8(%ebp),%eax
  8003f3:	89 04 24             	mov    %eax,(%esp)
  8003f6:	e8 02 00 00 00       	call   8003fd <vprintfmt>
	va_end(ap);
}
  8003fb:	c9                   	leave  
  8003fc:	c3                   	ret    

008003fd <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8003fd:	55                   	push   %ebp
  8003fe:	89 e5                	mov    %esp,%ebp
  800400:	57                   	push   %edi
  800401:	56                   	push   %esi
  800402:	53                   	push   %ebx
  800403:	83 ec 4c             	sub    $0x4c,%esp
  800406:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800409:	8b 75 10             	mov    0x10(%ebp),%esi
  80040c:	eb 12                	jmp    800420 <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80040e:	85 c0                	test   %eax,%eax
  800410:	0f 84 9f 03 00 00    	je     8007b5 <vprintfmt+0x3b8>
				return;
			putch(ch, putdat);
  800416:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80041a:	89 04 24             	mov    %eax,(%esp)
  80041d:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800420:	0f b6 06             	movzbl (%esi),%eax
  800423:	83 c6 01             	add    $0x1,%esi
  800426:	83 f8 25             	cmp    $0x25,%eax
  800429:	75 e3                	jne    80040e <vprintfmt+0x11>
  80042b:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  80042f:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  800436:	bf ff ff ff ff       	mov    $0xffffffff,%edi
  80043b:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
  800442:	b9 00 00 00 00       	mov    $0x0,%ecx
  800447:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80044a:	eb 2b                	jmp    800477 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80044c:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  80044f:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  800453:	eb 22                	jmp    800477 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800455:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800458:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  80045c:	eb 19                	jmp    800477 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80045e:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
  800461:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  800468:	eb 0d                	jmp    800477 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  80046a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80046d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800470:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800477:	0f b6 16             	movzbl (%esi),%edx
  80047a:	0f b6 c2             	movzbl %dl,%eax
  80047d:	8d 7e 01             	lea    0x1(%esi),%edi
  800480:	89 7d e0             	mov    %edi,-0x20(%ebp)
  800483:	83 ea 23             	sub    $0x23,%edx
  800486:	80 fa 55             	cmp    $0x55,%dl
  800489:	0f 87 08 03 00 00    	ja     800797 <vprintfmt+0x39a>
  80048f:	0f b6 d2             	movzbl %dl,%edx
  800492:	ff 24 95 84 0f 80 00 	jmp    *0x800f84(,%edx,4)
  800499:	8b 75 e0             	mov    -0x20(%ebp),%esi
  80049c:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
  8004a3:	bf 00 00 00 00       	mov    $0x0,%edi
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8004a8:	8d 14 bf             	lea    (%edi,%edi,4),%edx
  8004ab:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
  8004af:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  8004b2:	8d 50 d0             	lea    -0x30(%eax),%edx
  8004b5:	83 fa 09             	cmp    $0x9,%edx
  8004b8:	77 2f                	ja     8004e9 <vprintfmt+0xec>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8004ba:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8004bd:	eb e9                	jmp    8004a8 <vprintfmt+0xab>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8004bf:	8b 45 14             	mov    0x14(%ebp),%eax
  8004c2:	8d 50 04             	lea    0x4(%eax),%edx
  8004c5:	89 55 14             	mov    %edx,0x14(%ebp)
  8004c8:	8b 00                	mov    (%eax),%eax
  8004ca:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004cd:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8004d0:	eb 1a                	jmp    8004ec <vprintfmt+0xef>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004d2:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
  8004d5:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8004d9:	79 9c                	jns    800477 <vprintfmt+0x7a>
  8004db:	eb 81                	jmp    80045e <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004dd:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8004e0:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
  8004e7:	eb 8e                	jmp    800477 <vprintfmt+0x7a>
  8004e9:	89 7d d4             	mov    %edi,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  8004ec:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8004f0:	79 85                	jns    800477 <vprintfmt+0x7a>
  8004f2:	e9 73 ff ff ff       	jmp    80046a <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8004f7:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004fa:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8004fd:	e9 75 ff ff ff       	jmp    800477 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800502:	8b 45 14             	mov    0x14(%ebp),%eax
  800505:	8d 50 04             	lea    0x4(%eax),%edx
  800508:	89 55 14             	mov    %edx,0x14(%ebp)
  80050b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80050f:	8b 00                	mov    (%eax),%eax
  800511:	89 04 24             	mov    %eax,(%esp)
  800514:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800517:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80051a:	e9 01 ff ff ff       	jmp    800420 <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80051f:	8b 45 14             	mov    0x14(%ebp),%eax
  800522:	8d 50 04             	lea    0x4(%eax),%edx
  800525:	89 55 14             	mov    %edx,0x14(%ebp)
  800528:	8b 00                	mov    (%eax),%eax
  80052a:	89 c2                	mov    %eax,%edx
  80052c:	c1 fa 1f             	sar    $0x1f,%edx
  80052f:	31 d0                	xor    %edx,%eax
  800531:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800533:	83 f8 06             	cmp    $0x6,%eax
  800536:	7f 0b                	jg     800543 <vprintfmt+0x146>
  800538:	8b 14 85 dc 10 80 00 	mov    0x8010dc(,%eax,4),%edx
  80053f:	85 d2                	test   %edx,%edx
  800541:	75 23                	jne    800566 <vprintfmt+0x169>
				printfmt(putch, putdat, "error %d", err);
  800543:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800547:	c7 44 24 08 0e 0f 80 	movl   $0x800f0e,0x8(%esp)
  80054e:	00 
  80054f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800553:	8b 7d 08             	mov    0x8(%ebp),%edi
  800556:	89 3c 24             	mov    %edi,(%esp)
  800559:	e8 77 fe ff ff       	call   8003d5 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80055e:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800561:	e9 ba fe ff ff       	jmp    800420 <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
  800566:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80056a:	c7 44 24 08 17 0f 80 	movl   $0x800f17,0x8(%esp)
  800571:	00 
  800572:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800576:	8b 7d 08             	mov    0x8(%ebp),%edi
  800579:	89 3c 24             	mov    %edi,(%esp)
  80057c:	e8 54 fe ff ff       	call   8003d5 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800581:	8b 75 e0             	mov    -0x20(%ebp),%esi
  800584:	e9 97 fe ff ff       	jmp    800420 <vprintfmt+0x23>
  800589:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80058c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80058f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800592:	8b 45 14             	mov    0x14(%ebp),%eax
  800595:	8d 50 04             	lea    0x4(%eax),%edx
  800598:	89 55 14             	mov    %edx,0x14(%ebp)
  80059b:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  80059d:	85 f6                	test   %esi,%esi
  80059f:	ba 07 0f 80 00       	mov    $0x800f07,%edx
  8005a4:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
  8005a7:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  8005ab:	0f 8e 8c 00 00 00    	jle    80063d <vprintfmt+0x240>
  8005b1:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  8005b5:	0f 84 82 00 00 00    	je     80063d <vprintfmt+0x240>
				for (width -= strnlen(p, precision); width > 0; width--)
  8005bb:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005bf:	89 34 24             	mov    %esi,(%esp)
  8005c2:	e8 91 02 00 00       	call   800858 <strnlen>
  8005c7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  8005ca:	29 c2                	sub    %eax,%edx
  8005cc:	89 55 e4             	mov    %edx,-0x1c(%ebp)
					putch(padc, putdat);
  8005cf:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  8005d3:	89 75 d0             	mov    %esi,-0x30(%ebp)
  8005d6:	89 7d cc             	mov    %edi,-0x34(%ebp)
  8005d9:	89 de                	mov    %ebx,%esi
  8005db:	89 d3                	mov    %edx,%ebx
  8005dd:	89 c7                	mov    %eax,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005df:	eb 0d                	jmp    8005ee <vprintfmt+0x1f1>
					putch(padc, putdat);
  8005e1:	89 74 24 04          	mov    %esi,0x4(%esp)
  8005e5:	89 3c 24             	mov    %edi,(%esp)
  8005e8:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005eb:	83 eb 01             	sub    $0x1,%ebx
  8005ee:	85 db                	test   %ebx,%ebx
  8005f0:	7f ef                	jg     8005e1 <vprintfmt+0x1e4>
  8005f2:	8b 7d cc             	mov    -0x34(%ebp),%edi
  8005f5:	89 f3                	mov    %esi,%ebx
  8005f7:	8b 75 d0             	mov    -0x30(%ebp),%esi

// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
  8005fa:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8005fe:	b8 00 00 00 00       	mov    $0x0,%eax
  800603:	0f 49 45 e4          	cmovns -0x1c(%ebp),%eax
  800607:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80060a:	29 c2                	sub    %eax,%edx
  80060c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  80060f:	eb 2c                	jmp    80063d <vprintfmt+0x240>
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800611:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800615:	74 18                	je     80062f <vprintfmt+0x232>
  800617:	8d 50 e0             	lea    -0x20(%eax),%edx
  80061a:	83 fa 5e             	cmp    $0x5e,%edx
  80061d:	76 10                	jbe    80062f <vprintfmt+0x232>
					putch('?', putdat);
  80061f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800623:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  80062a:	ff 55 08             	call   *0x8(%ebp)
  80062d:	eb 0a                	jmp    800639 <vprintfmt+0x23c>
				else
					putch(ch, putdat);
  80062f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800633:	89 04 24             	mov    %eax,(%esp)
  800636:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800639:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
  80063d:	0f be 06             	movsbl (%esi),%eax
  800640:	83 c6 01             	add    $0x1,%esi
  800643:	85 c0                	test   %eax,%eax
  800645:	74 25                	je     80066c <vprintfmt+0x26f>
  800647:	85 ff                	test   %edi,%edi
  800649:	78 c6                	js     800611 <vprintfmt+0x214>
  80064b:	83 ef 01             	sub    $0x1,%edi
  80064e:	79 c1                	jns    800611 <vprintfmt+0x214>
  800650:	8b 7d 08             	mov    0x8(%ebp),%edi
  800653:	89 de                	mov    %ebx,%esi
  800655:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800658:	eb 1a                	jmp    800674 <vprintfmt+0x277>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  80065a:	89 74 24 04          	mov    %esi,0x4(%esp)
  80065e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800665:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800667:	83 eb 01             	sub    $0x1,%ebx
  80066a:	eb 08                	jmp    800674 <vprintfmt+0x277>
  80066c:	8b 7d 08             	mov    0x8(%ebp),%edi
  80066f:	89 de                	mov    %ebx,%esi
  800671:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  800674:	85 db                	test   %ebx,%ebx
  800676:	7f e2                	jg     80065a <vprintfmt+0x25d>
  800678:	89 7d 08             	mov    %edi,0x8(%ebp)
  80067b:	89 f3                	mov    %esi,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80067d:	8b 75 e0             	mov    -0x20(%ebp),%esi
  800680:	e9 9b fd ff ff       	jmp    800420 <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800685:	83 f9 01             	cmp    $0x1,%ecx
  800688:	7e 10                	jle    80069a <vprintfmt+0x29d>
		return va_arg(*ap, long long);
  80068a:	8b 45 14             	mov    0x14(%ebp),%eax
  80068d:	8d 50 08             	lea    0x8(%eax),%edx
  800690:	89 55 14             	mov    %edx,0x14(%ebp)
  800693:	8b 30                	mov    (%eax),%esi
  800695:	8b 78 04             	mov    0x4(%eax),%edi
  800698:	eb 26                	jmp    8006c0 <vprintfmt+0x2c3>
	else if (lflag)
  80069a:	85 c9                	test   %ecx,%ecx
  80069c:	74 12                	je     8006b0 <vprintfmt+0x2b3>
		return va_arg(*ap, long);
  80069e:	8b 45 14             	mov    0x14(%ebp),%eax
  8006a1:	8d 50 04             	lea    0x4(%eax),%edx
  8006a4:	89 55 14             	mov    %edx,0x14(%ebp)
  8006a7:	8b 30                	mov    (%eax),%esi
  8006a9:	89 f7                	mov    %esi,%edi
  8006ab:	c1 ff 1f             	sar    $0x1f,%edi
  8006ae:	eb 10                	jmp    8006c0 <vprintfmt+0x2c3>
	else
		return va_arg(*ap, int);
  8006b0:	8b 45 14             	mov    0x14(%ebp),%eax
  8006b3:	8d 50 04             	lea    0x4(%eax),%edx
  8006b6:	89 55 14             	mov    %edx,0x14(%ebp)
  8006b9:	8b 30                	mov    (%eax),%esi
  8006bb:	89 f7                	mov    %esi,%edi
  8006bd:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8006c0:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8006c5:	85 ff                	test   %edi,%edi
  8006c7:	0f 89 8c 00 00 00    	jns    800759 <vprintfmt+0x35c>
				putch('-', putdat);
  8006cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8006d1:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8006d8:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  8006db:	f7 de                	neg    %esi
  8006dd:	83 d7 00             	adc    $0x0,%edi
  8006e0:	f7 df                	neg    %edi
			}
			base = 10;
  8006e2:	b8 0a 00 00 00       	mov    $0xa,%eax
  8006e7:	eb 70                	jmp    800759 <vprintfmt+0x35c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8006e9:	89 ca                	mov    %ecx,%edx
  8006eb:	8d 45 14             	lea    0x14(%ebp),%eax
  8006ee:	e8 8b fc ff ff       	call   80037e <getuint>
  8006f3:	89 c6                	mov    %eax,%esi
  8006f5:	89 d7                	mov    %edx,%edi
			base = 10;
  8006f7:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
  8006fc:	eb 5b                	jmp    800759 <vprintfmt+0x35c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num=getuint(&ap,lflag);
  8006fe:	89 ca                	mov    %ecx,%edx
  800700:	8d 45 14             	lea    0x14(%ebp),%eax
  800703:	e8 76 fc ff ff       	call   80037e <getuint>
  800708:	89 c6                	mov    %eax,%esi
  80070a:	89 d7                	mov    %edx,%edi
			base = 8;
  80070c:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
  800711:	eb 46                	jmp    800759 <vprintfmt+0x35c>
	
		// pointer
		case 'p':
			putch('0', putdat);
  800713:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800717:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80071e:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800721:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800725:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80072c:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80072f:	8b 45 14             	mov    0x14(%ebp),%eax
  800732:	8d 50 04             	lea    0x4(%eax),%edx
  800735:	89 55 14             	mov    %edx,0x14(%ebp)
	
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800738:	8b 30                	mov    (%eax),%esi
  80073a:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80073f:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
  800744:	eb 13                	jmp    800759 <vprintfmt+0x35c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800746:	89 ca                	mov    %ecx,%edx
  800748:	8d 45 14             	lea    0x14(%ebp),%eax
  80074b:	e8 2e fc ff ff       	call   80037e <getuint>
  800750:	89 c6                	mov    %eax,%esi
  800752:	89 d7                	mov    %edx,%edi
			base = 16;
  800754:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
  800759:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
  80075d:	89 54 24 10          	mov    %edx,0x10(%esp)
  800761:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800764:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800768:	89 44 24 08          	mov    %eax,0x8(%esp)
  80076c:	89 34 24             	mov    %esi,(%esp)
  80076f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800773:	89 da                	mov    %ebx,%edx
  800775:	8b 45 08             	mov    0x8(%ebp),%eax
  800778:	e8 33 fb ff ff       	call   8002b0 <printnum>
			break;
  80077d:	8b 75 e0             	mov    -0x20(%ebp),%esi
  800780:	e9 9b fc ff ff       	jmp    800420 <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800785:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800789:	89 04 24             	mov    %eax,(%esp)
  80078c:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80078f:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800792:	e9 89 fc ff ff       	jmp    800420 <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800797:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80079b:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8007a2:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  8007a5:	eb 03                	jmp    8007aa <vprintfmt+0x3ad>
  8007a7:	83 ee 01             	sub    $0x1,%esi
  8007aa:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
  8007ae:	75 f7                	jne    8007a7 <vprintfmt+0x3aa>
  8007b0:	e9 6b fc ff ff       	jmp    800420 <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
  8007b5:	83 c4 4c             	add    $0x4c,%esp
  8007b8:	5b                   	pop    %ebx
  8007b9:	5e                   	pop    %esi
  8007ba:	5f                   	pop    %edi
  8007bb:	5d                   	pop    %ebp
  8007bc:	c3                   	ret    

008007bd <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8007bd:	55                   	push   %ebp
  8007be:	89 e5                	mov    %esp,%ebp
  8007c0:	83 ec 28             	sub    $0x28,%esp
  8007c3:	8b 45 08             	mov    0x8(%ebp),%eax
  8007c6:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8007c9:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8007cc:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8007d0:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8007d3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8007da:	85 c0                	test   %eax,%eax
  8007dc:	74 30                	je     80080e <vsnprintf+0x51>
  8007de:	85 d2                	test   %edx,%edx
  8007e0:	7e 2c                	jle    80080e <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007e2:	8b 45 14             	mov    0x14(%ebp),%eax
  8007e5:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8007e9:	8b 45 10             	mov    0x10(%ebp),%eax
  8007ec:	89 44 24 08          	mov    %eax,0x8(%esp)
  8007f0:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8007f3:	89 44 24 04          	mov    %eax,0x4(%esp)
  8007f7:	c7 04 24 b8 03 80 00 	movl   $0x8003b8,(%esp)
  8007fe:	e8 fa fb ff ff       	call   8003fd <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800803:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800806:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800809:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80080c:	eb 05                	jmp    800813 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  80080e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800813:	c9                   	leave  
  800814:	c3                   	ret    

00800815 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800815:	55                   	push   %ebp
  800816:	89 e5                	mov    %esp,%ebp
  800818:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80081b:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  80081e:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800822:	8b 45 10             	mov    0x10(%ebp),%eax
  800825:	89 44 24 08          	mov    %eax,0x8(%esp)
  800829:	8b 45 0c             	mov    0xc(%ebp),%eax
  80082c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800830:	8b 45 08             	mov    0x8(%ebp),%eax
  800833:	89 04 24             	mov    %eax,(%esp)
  800836:	e8 82 ff ff ff       	call   8007bd <vsnprintf>
	va_end(ap);

	return rc;
}
  80083b:	c9                   	leave  
  80083c:	c3                   	ret    
  80083d:	00 00                	add    %al,(%eax)
	...

00800840 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800840:	55                   	push   %ebp
  800841:	89 e5                	mov    %esp,%ebp
  800843:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800846:	b8 00 00 00 00       	mov    $0x0,%eax
  80084b:	eb 03                	jmp    800850 <strlen+0x10>
		n++;
  80084d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800850:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800854:	75 f7                	jne    80084d <strlen+0xd>
		n++;
	return n;
}
  800856:	5d                   	pop    %ebp
  800857:	c3                   	ret    

00800858 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800858:	55                   	push   %ebp
  800859:	89 e5                	mov    %esp,%ebp
  80085b:	8b 4d 08             	mov    0x8(%ebp),%ecx
		n++;
	return n;
}

int
strnlen(const char *s, size_t size)
  80085e:	8b 55 0c             	mov    0xc(%ebp),%edx
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800861:	b8 00 00 00 00       	mov    $0x0,%eax
  800866:	eb 03                	jmp    80086b <strnlen+0x13>
		n++;
  800868:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80086b:	39 d0                	cmp    %edx,%eax
  80086d:	74 06                	je     800875 <strnlen+0x1d>
  80086f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800873:	75 f3                	jne    800868 <strnlen+0x10>
		n++;
	return n;
}
  800875:	5d                   	pop    %ebp
  800876:	c3                   	ret    

00800877 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800877:	55                   	push   %ebp
  800878:	89 e5                	mov    %esp,%ebp
  80087a:	53                   	push   %ebx
  80087b:	8b 45 08             	mov    0x8(%ebp),%eax
  80087e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800881:	ba 00 00 00 00       	mov    $0x0,%edx
  800886:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
  80088a:	88 0c 10             	mov    %cl,(%eax,%edx,1)
  80088d:	83 c2 01             	add    $0x1,%edx
  800890:	84 c9                	test   %cl,%cl
  800892:	75 f2                	jne    800886 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
  800894:	5b                   	pop    %ebx
  800895:	5d                   	pop    %ebp
  800896:	c3                   	ret    

00800897 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800897:	55                   	push   %ebp
  800898:	89 e5                	mov    %esp,%ebp
  80089a:	53                   	push   %ebx
  80089b:	83 ec 08             	sub    $0x8,%esp
  80089e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8008a1:	89 1c 24             	mov    %ebx,(%esp)
  8008a4:	e8 97 ff ff ff       	call   800840 <strlen>
	strcpy(dst + len, src);
  8008a9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008ac:	89 54 24 04          	mov    %edx,0x4(%esp)
  8008b0:	01 d8                	add    %ebx,%eax
  8008b2:	89 04 24             	mov    %eax,(%esp)
  8008b5:	e8 bd ff ff ff       	call   800877 <strcpy>
	return dst;
}
  8008ba:	89 d8                	mov    %ebx,%eax
  8008bc:	83 c4 08             	add    $0x8,%esp
  8008bf:	5b                   	pop    %ebx
  8008c0:	5d                   	pop    %ebp
  8008c1:	c3                   	ret    

008008c2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8008c2:	55                   	push   %ebp
  8008c3:	89 e5                	mov    %esp,%ebp
  8008c5:	56                   	push   %esi
  8008c6:	53                   	push   %ebx
  8008c7:	8b 45 08             	mov    0x8(%ebp),%eax
  8008ca:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008cd:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008d0:	b9 00 00 00 00       	mov    $0x0,%ecx
  8008d5:	eb 0f                	jmp    8008e6 <strncpy+0x24>
		*dst++ = *src;
  8008d7:	0f b6 1a             	movzbl (%edx),%ebx
  8008da:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8008dd:	80 3a 01             	cmpb   $0x1,(%edx)
  8008e0:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008e3:	83 c1 01             	add    $0x1,%ecx
  8008e6:	39 f1                	cmp    %esi,%ecx
  8008e8:	75 ed                	jne    8008d7 <strncpy+0x15>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8008ea:	5b                   	pop    %ebx
  8008eb:	5e                   	pop    %esi
  8008ec:	5d                   	pop    %ebp
  8008ed:	c3                   	ret    

008008ee <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8008ee:	55                   	push   %ebp
  8008ef:	89 e5                	mov    %esp,%ebp
  8008f1:	56                   	push   %esi
  8008f2:	53                   	push   %ebx
  8008f3:	8b 75 08             	mov    0x8(%ebp),%esi
  8008f6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8008f9:	8b 55 10             	mov    0x10(%ebp),%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8008fc:	89 f0                	mov    %esi,%eax
  8008fe:	85 d2                	test   %edx,%edx
  800900:	75 0a                	jne    80090c <strlcpy+0x1e>
  800902:	eb 1d                	jmp    800921 <strlcpy+0x33>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800904:	88 18                	mov    %bl,(%eax)
  800906:	83 c0 01             	add    $0x1,%eax
  800909:	83 c1 01             	add    $0x1,%ecx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  80090c:	83 ea 01             	sub    $0x1,%edx
  80090f:	74 0b                	je     80091c <strlcpy+0x2e>
  800911:	0f b6 19             	movzbl (%ecx),%ebx
  800914:	84 db                	test   %bl,%bl
  800916:	75 ec                	jne    800904 <strlcpy+0x16>
  800918:	89 c2                	mov    %eax,%edx
  80091a:	eb 02                	jmp    80091e <strlcpy+0x30>
  80091c:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  80091e:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800921:	29 f0                	sub    %esi,%eax
}
  800923:	5b                   	pop    %ebx
  800924:	5e                   	pop    %esi
  800925:	5d                   	pop    %ebp
  800926:	c3                   	ret    

00800927 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800927:	55                   	push   %ebp
  800928:	89 e5                	mov    %esp,%ebp
  80092a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80092d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800930:	eb 06                	jmp    800938 <strcmp+0x11>
		p++, q++;
  800932:	83 c1 01             	add    $0x1,%ecx
  800935:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800938:	0f b6 01             	movzbl (%ecx),%eax
  80093b:	84 c0                	test   %al,%al
  80093d:	74 04                	je     800943 <strcmp+0x1c>
  80093f:	3a 02                	cmp    (%edx),%al
  800941:	74 ef                	je     800932 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800943:	0f b6 c0             	movzbl %al,%eax
  800946:	0f b6 12             	movzbl (%edx),%edx
  800949:	29 d0                	sub    %edx,%eax
}
  80094b:	5d                   	pop    %ebp
  80094c:	c3                   	ret    

0080094d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80094d:	55                   	push   %ebp
  80094e:	89 e5                	mov    %esp,%ebp
  800950:	53                   	push   %ebx
  800951:	8b 45 08             	mov    0x8(%ebp),%eax
  800954:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800957:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
  80095a:	eb 09                	jmp    800965 <strncmp+0x18>
		n--, p++, q++;
  80095c:	83 ea 01             	sub    $0x1,%edx
  80095f:	83 c0 01             	add    $0x1,%eax
  800962:	83 c1 01             	add    $0x1,%ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800965:	85 d2                	test   %edx,%edx
  800967:	74 15                	je     80097e <strncmp+0x31>
  800969:	0f b6 18             	movzbl (%eax),%ebx
  80096c:	84 db                	test   %bl,%bl
  80096e:	74 04                	je     800974 <strncmp+0x27>
  800970:	3a 19                	cmp    (%ecx),%bl
  800972:	74 e8                	je     80095c <strncmp+0xf>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800974:	0f b6 00             	movzbl (%eax),%eax
  800977:	0f b6 11             	movzbl (%ecx),%edx
  80097a:	29 d0                	sub    %edx,%eax
  80097c:	eb 05                	jmp    800983 <strncmp+0x36>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  80097e:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800983:	5b                   	pop    %ebx
  800984:	5d                   	pop    %ebp
  800985:	c3                   	ret    

00800986 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800986:	55                   	push   %ebp
  800987:	89 e5                	mov    %esp,%ebp
  800989:	8b 45 08             	mov    0x8(%ebp),%eax
  80098c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800990:	eb 07                	jmp    800999 <strchr+0x13>
		if (*s == c)
  800992:	38 ca                	cmp    %cl,%dl
  800994:	74 0f                	je     8009a5 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800996:	83 c0 01             	add    $0x1,%eax
  800999:	0f b6 10             	movzbl (%eax),%edx
  80099c:	84 d2                	test   %dl,%dl
  80099e:	75 f2                	jne    800992 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8009a0:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009a5:	5d                   	pop    %ebp
  8009a6:	c3                   	ret    

008009a7 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8009a7:	55                   	push   %ebp
  8009a8:	89 e5                	mov    %esp,%ebp
  8009aa:	8b 45 08             	mov    0x8(%ebp),%eax
  8009ad:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009b1:	eb 07                	jmp    8009ba <strfind+0x13>
		if (*s == c)
  8009b3:	38 ca                	cmp    %cl,%dl
  8009b5:	74 0a                	je     8009c1 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  8009b7:	83 c0 01             	add    $0x1,%eax
  8009ba:	0f b6 10             	movzbl (%eax),%edx
  8009bd:	84 d2                	test   %dl,%dl
  8009bf:	75 f2                	jne    8009b3 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  8009c1:	5d                   	pop    %ebp
  8009c2:	c3                   	ret    

008009c3 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8009c3:	55                   	push   %ebp
  8009c4:	89 e5                	mov    %esp,%ebp
  8009c6:	83 ec 0c             	sub    $0xc,%esp
  8009c9:	89 5d f4             	mov    %ebx,-0xc(%ebp)
  8009cc:	89 75 f8             	mov    %esi,-0x8(%ebp)
  8009cf:	89 7d fc             	mov    %edi,-0x4(%ebp)
  8009d2:	8b 7d 08             	mov    0x8(%ebp),%edi
  8009d5:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009d8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8009db:	85 c9                	test   %ecx,%ecx
  8009dd:	74 30                	je     800a0f <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8009df:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8009e5:	75 25                	jne    800a0c <memset+0x49>
  8009e7:	f6 c1 03             	test   $0x3,%cl
  8009ea:	75 20                	jne    800a0c <memset+0x49>
		c &= 0xFF;
  8009ec:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8009ef:	89 d3                	mov    %edx,%ebx
  8009f1:	c1 e3 08             	shl    $0x8,%ebx
  8009f4:	89 d6                	mov    %edx,%esi
  8009f6:	c1 e6 18             	shl    $0x18,%esi
  8009f9:	89 d0                	mov    %edx,%eax
  8009fb:	c1 e0 10             	shl    $0x10,%eax
  8009fe:	09 f0                	or     %esi,%eax
  800a00:	09 d0                	or     %edx,%eax
  800a02:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800a04:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800a07:	fc                   	cld    
  800a08:	f3 ab                	rep stos %eax,%es:(%edi)
  800a0a:	eb 03                	jmp    800a0f <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a0c:	fc                   	cld    
  800a0d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800a0f:	89 f8                	mov    %edi,%eax
  800a11:	8b 5d f4             	mov    -0xc(%ebp),%ebx
  800a14:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800a17:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800a1a:	89 ec                	mov    %ebp,%esp
  800a1c:	5d                   	pop    %ebp
  800a1d:	c3                   	ret    

00800a1e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a1e:	55                   	push   %ebp
  800a1f:	89 e5                	mov    %esp,%ebp
  800a21:	83 ec 08             	sub    $0x8,%esp
  800a24:	89 75 f8             	mov    %esi,-0x8(%ebp)
  800a27:	89 7d fc             	mov    %edi,-0x4(%ebp)
  800a2a:	8b 45 08             	mov    0x8(%ebp),%eax
  800a2d:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a30:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a33:	39 c6                	cmp    %eax,%esi
  800a35:	73 36                	jae    800a6d <memmove+0x4f>
  800a37:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a3a:	39 d0                	cmp    %edx,%eax
  800a3c:	73 2f                	jae    800a6d <memmove+0x4f>
		s += n;
		d += n;
  800a3e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a41:	f6 c2 03             	test   $0x3,%dl
  800a44:	75 1b                	jne    800a61 <memmove+0x43>
  800a46:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a4c:	75 13                	jne    800a61 <memmove+0x43>
  800a4e:	f6 c1 03             	test   $0x3,%cl
  800a51:	75 0e                	jne    800a61 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800a53:	83 ef 04             	sub    $0x4,%edi
  800a56:	8d 72 fc             	lea    -0x4(%edx),%esi
  800a59:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800a5c:	fd                   	std    
  800a5d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a5f:	eb 09                	jmp    800a6a <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800a61:	83 ef 01             	sub    $0x1,%edi
  800a64:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800a67:	fd                   	std    
  800a68:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a6a:	fc                   	cld    
  800a6b:	eb 20                	jmp    800a8d <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a6d:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a73:	75 13                	jne    800a88 <memmove+0x6a>
  800a75:	a8 03                	test   $0x3,%al
  800a77:	75 0f                	jne    800a88 <memmove+0x6a>
  800a79:	f6 c1 03             	test   $0x3,%cl
  800a7c:	75 0a                	jne    800a88 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800a7e:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800a81:	89 c7                	mov    %eax,%edi
  800a83:	fc                   	cld    
  800a84:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a86:	eb 05                	jmp    800a8d <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a88:	89 c7                	mov    %eax,%edi
  800a8a:	fc                   	cld    
  800a8b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a8d:	8b 75 f8             	mov    -0x8(%ebp),%esi
  800a90:	8b 7d fc             	mov    -0x4(%ebp),%edi
  800a93:	89 ec                	mov    %ebp,%esp
  800a95:	5d                   	pop    %ebp
  800a96:	c3                   	ret    

00800a97 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a97:	55                   	push   %ebp
  800a98:	89 e5                	mov    %esp,%ebp
  800a9a:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800a9d:	8b 45 10             	mov    0x10(%ebp),%eax
  800aa0:	89 44 24 08          	mov    %eax,0x8(%esp)
  800aa4:	8b 45 0c             	mov    0xc(%ebp),%eax
  800aa7:	89 44 24 04          	mov    %eax,0x4(%esp)
  800aab:	8b 45 08             	mov    0x8(%ebp),%eax
  800aae:	89 04 24             	mov    %eax,(%esp)
  800ab1:	e8 68 ff ff ff       	call   800a1e <memmove>
}
  800ab6:	c9                   	leave  
  800ab7:	c3                   	ret    

00800ab8 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800ab8:	55                   	push   %ebp
  800ab9:	89 e5                	mov    %esp,%ebp
  800abb:	57                   	push   %edi
  800abc:	56                   	push   %esi
  800abd:	53                   	push   %ebx
  800abe:	8b 7d 08             	mov    0x8(%ebp),%edi
  800ac1:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ac4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800ac7:	ba 00 00 00 00       	mov    $0x0,%edx
  800acc:	eb 1a                	jmp    800ae8 <memcmp+0x30>
		if (*s1 != *s2)
  800ace:	0f b6 04 17          	movzbl (%edi,%edx,1),%eax
  800ad2:	83 c2 01             	add    $0x1,%edx
  800ad5:	0f b6 4c 16 ff       	movzbl -0x1(%esi,%edx,1),%ecx
  800ada:	38 c8                	cmp    %cl,%al
  800adc:	74 0a                	je     800ae8 <memcmp+0x30>
			return (int) *s1 - (int) *s2;
  800ade:	0f b6 c0             	movzbl %al,%eax
  800ae1:	0f b6 c9             	movzbl %cl,%ecx
  800ae4:	29 c8                	sub    %ecx,%eax
  800ae6:	eb 09                	jmp    800af1 <memcmp+0x39>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800ae8:	39 da                	cmp    %ebx,%edx
  800aea:	75 e2                	jne    800ace <memcmp+0x16>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800aec:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800af1:	5b                   	pop    %ebx
  800af2:	5e                   	pop    %esi
  800af3:	5f                   	pop    %edi
  800af4:	5d                   	pop    %ebp
  800af5:	c3                   	ret    

00800af6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800af6:	55                   	push   %ebp
  800af7:	89 e5                	mov    %esp,%ebp
  800af9:	8b 45 08             	mov    0x8(%ebp),%eax
  800afc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800aff:	89 c2                	mov    %eax,%edx
  800b01:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800b04:	eb 07                	jmp    800b0d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800b06:	38 08                	cmp    %cl,(%eax)
  800b08:	74 07                	je     800b11 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800b0a:	83 c0 01             	add    $0x1,%eax
  800b0d:	39 d0                	cmp    %edx,%eax
  800b0f:	72 f5                	jb     800b06 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800b11:	5d                   	pop    %ebp
  800b12:	c3                   	ret    

00800b13 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b13:	55                   	push   %ebp
  800b14:	89 e5                	mov    %esp,%ebp
  800b16:	57                   	push   %edi
  800b17:	56                   	push   %esi
  800b18:	53                   	push   %ebx
  800b19:	8b 55 08             	mov    0x8(%ebp),%edx
  800b1c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b1f:	eb 03                	jmp    800b24 <strtol+0x11>
		s++;
  800b21:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b24:	0f b6 02             	movzbl (%edx),%eax
  800b27:	3c 20                	cmp    $0x20,%al
  800b29:	74 f6                	je     800b21 <strtol+0xe>
  800b2b:	3c 09                	cmp    $0x9,%al
  800b2d:	74 f2                	je     800b21 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b2f:	3c 2b                	cmp    $0x2b,%al
  800b31:	75 0a                	jne    800b3d <strtol+0x2a>
		s++;
  800b33:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b36:	bf 00 00 00 00       	mov    $0x0,%edi
  800b3b:	eb 10                	jmp    800b4d <strtol+0x3a>
  800b3d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b42:	3c 2d                	cmp    $0x2d,%al
  800b44:	75 07                	jne    800b4d <strtol+0x3a>
		s++, neg = 1;
  800b46:	8d 52 01             	lea    0x1(%edx),%edx
  800b49:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b4d:	85 db                	test   %ebx,%ebx
  800b4f:	0f 94 c0             	sete   %al
  800b52:	74 05                	je     800b59 <strtol+0x46>
  800b54:	83 fb 10             	cmp    $0x10,%ebx
  800b57:	75 15                	jne    800b6e <strtol+0x5b>
  800b59:	80 3a 30             	cmpb   $0x30,(%edx)
  800b5c:	75 10                	jne    800b6e <strtol+0x5b>
  800b5e:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800b62:	75 0a                	jne    800b6e <strtol+0x5b>
		s += 2, base = 16;
  800b64:	83 c2 02             	add    $0x2,%edx
  800b67:	bb 10 00 00 00       	mov    $0x10,%ebx
  800b6c:	eb 13                	jmp    800b81 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800b6e:	84 c0                	test   %al,%al
  800b70:	74 0f                	je     800b81 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b72:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b77:	80 3a 30             	cmpb   $0x30,(%edx)
  800b7a:	75 05                	jne    800b81 <strtol+0x6e>
		s++, base = 8;
  800b7c:	83 c2 01             	add    $0x1,%edx
  800b7f:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
  800b81:	b8 00 00 00 00       	mov    $0x0,%eax
  800b86:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b88:	0f b6 0a             	movzbl (%edx),%ecx
  800b8b:	8d 59 d0             	lea    -0x30(%ecx),%ebx
  800b8e:	80 fb 09             	cmp    $0x9,%bl
  800b91:	77 08                	ja     800b9b <strtol+0x88>
			dig = *s - '0';
  800b93:	0f be c9             	movsbl %cl,%ecx
  800b96:	83 e9 30             	sub    $0x30,%ecx
  800b99:	eb 1e                	jmp    800bb9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800b9b:	8d 59 9f             	lea    -0x61(%ecx),%ebx
  800b9e:	80 fb 19             	cmp    $0x19,%bl
  800ba1:	77 08                	ja     800bab <strtol+0x98>
			dig = *s - 'a' + 10;
  800ba3:	0f be c9             	movsbl %cl,%ecx
  800ba6:	83 e9 57             	sub    $0x57,%ecx
  800ba9:	eb 0e                	jmp    800bb9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800bab:	8d 59 bf             	lea    -0x41(%ecx),%ebx
  800bae:	80 fb 19             	cmp    $0x19,%bl
  800bb1:	77 14                	ja     800bc7 <strtol+0xb4>
			dig = *s - 'A' + 10;
  800bb3:	0f be c9             	movsbl %cl,%ecx
  800bb6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800bb9:	39 f1                	cmp    %esi,%ecx
  800bbb:	7d 0e                	jge    800bcb <strtol+0xb8>
			break;
		s++, val = (val * base) + dig;
  800bbd:	83 c2 01             	add    $0x1,%edx
  800bc0:	0f af c6             	imul   %esi,%eax
  800bc3:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
  800bc5:	eb c1                	jmp    800b88 <strtol+0x75>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
  800bc7:	89 c1                	mov    %eax,%ecx
  800bc9:	eb 02                	jmp    800bcd <strtol+0xba>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
  800bcb:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800bcd:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800bd1:	74 05                	je     800bd8 <strtol+0xc5>
		*endptr = (char *) s;
  800bd3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800bd6:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
  800bd8:	89 ca                	mov    %ecx,%edx
  800bda:	f7 da                	neg    %edx
  800bdc:	85 ff                	test   %edi,%edi
  800bde:	0f 45 c2             	cmovne %edx,%eax
}
  800be1:	5b                   	pop    %ebx
  800be2:	5e                   	pop    %esi
  800be3:	5f                   	pop    %edi
  800be4:	5d                   	pop    %ebp
  800be5:	c3                   	ret    
	...

00800bf0 <__udivdi3>:
  800bf0:	83 ec 1c             	sub    $0x1c,%esp
  800bf3:	89 7c 24 14          	mov    %edi,0x14(%esp)
  800bf7:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
  800bfb:	8b 44 24 20          	mov    0x20(%esp),%eax
  800bff:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  800c03:	89 74 24 10          	mov    %esi,0x10(%esp)
  800c07:	8b 74 24 24          	mov    0x24(%esp),%esi
  800c0b:	85 ff                	test   %edi,%edi
  800c0d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  800c11:	89 44 24 08          	mov    %eax,0x8(%esp)
  800c15:	89 cd                	mov    %ecx,%ebp
  800c17:	89 44 24 04          	mov    %eax,0x4(%esp)
  800c1b:	75 33                	jne    800c50 <__udivdi3+0x60>
  800c1d:	39 f1                	cmp    %esi,%ecx
  800c1f:	77 57                	ja     800c78 <__udivdi3+0x88>
  800c21:	85 c9                	test   %ecx,%ecx
  800c23:	75 0b                	jne    800c30 <__udivdi3+0x40>
  800c25:	b8 01 00 00 00       	mov    $0x1,%eax
  800c2a:	31 d2                	xor    %edx,%edx
  800c2c:	f7 f1                	div    %ecx
  800c2e:	89 c1                	mov    %eax,%ecx
  800c30:	89 f0                	mov    %esi,%eax
  800c32:	31 d2                	xor    %edx,%edx
  800c34:	f7 f1                	div    %ecx
  800c36:	89 c6                	mov    %eax,%esi
  800c38:	8b 44 24 04          	mov    0x4(%esp),%eax
  800c3c:	f7 f1                	div    %ecx
  800c3e:	89 f2                	mov    %esi,%edx
  800c40:	8b 74 24 10          	mov    0x10(%esp),%esi
  800c44:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800c48:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800c4c:	83 c4 1c             	add    $0x1c,%esp
  800c4f:	c3                   	ret    
  800c50:	31 d2                	xor    %edx,%edx
  800c52:	31 c0                	xor    %eax,%eax
  800c54:	39 f7                	cmp    %esi,%edi
  800c56:	77 e8                	ja     800c40 <__udivdi3+0x50>
  800c58:	0f bd cf             	bsr    %edi,%ecx
  800c5b:	83 f1 1f             	xor    $0x1f,%ecx
  800c5e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800c62:	75 2c                	jne    800c90 <__udivdi3+0xa0>
  800c64:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
  800c68:	76 04                	jbe    800c6e <__udivdi3+0x7e>
  800c6a:	39 f7                	cmp    %esi,%edi
  800c6c:	73 d2                	jae    800c40 <__udivdi3+0x50>
  800c6e:	31 d2                	xor    %edx,%edx
  800c70:	b8 01 00 00 00       	mov    $0x1,%eax
  800c75:	eb c9                	jmp    800c40 <__udivdi3+0x50>
  800c77:	90                   	nop
  800c78:	89 f2                	mov    %esi,%edx
  800c7a:	f7 f1                	div    %ecx
  800c7c:	31 d2                	xor    %edx,%edx
  800c7e:	8b 74 24 10          	mov    0x10(%esp),%esi
  800c82:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800c86:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800c8a:	83 c4 1c             	add    $0x1c,%esp
  800c8d:	c3                   	ret    
  800c8e:	66 90                	xchg   %ax,%ax
  800c90:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800c95:	b8 20 00 00 00       	mov    $0x20,%eax
  800c9a:	89 ea                	mov    %ebp,%edx
  800c9c:	2b 44 24 04          	sub    0x4(%esp),%eax
  800ca0:	d3 e7                	shl    %cl,%edi
  800ca2:	89 c1                	mov    %eax,%ecx
  800ca4:	d3 ea                	shr    %cl,%edx
  800ca6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800cab:	09 fa                	or     %edi,%edx
  800cad:	89 f7                	mov    %esi,%edi
  800caf:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800cb3:	89 f2                	mov    %esi,%edx
  800cb5:	8b 74 24 08          	mov    0x8(%esp),%esi
  800cb9:	d3 e5                	shl    %cl,%ebp
  800cbb:	89 c1                	mov    %eax,%ecx
  800cbd:	d3 ef                	shr    %cl,%edi
  800cbf:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800cc4:	d3 e2                	shl    %cl,%edx
  800cc6:	89 c1                	mov    %eax,%ecx
  800cc8:	d3 ee                	shr    %cl,%esi
  800cca:	09 d6                	or     %edx,%esi
  800ccc:	89 fa                	mov    %edi,%edx
  800cce:	89 f0                	mov    %esi,%eax
  800cd0:	f7 74 24 0c          	divl   0xc(%esp)
  800cd4:	89 d7                	mov    %edx,%edi
  800cd6:	89 c6                	mov    %eax,%esi
  800cd8:	f7 e5                	mul    %ebp
  800cda:	39 d7                	cmp    %edx,%edi
  800cdc:	72 22                	jb     800d00 <__udivdi3+0x110>
  800cde:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  800ce2:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800ce7:	d3 e5                	shl    %cl,%ebp
  800ce9:	39 c5                	cmp    %eax,%ebp
  800ceb:	73 04                	jae    800cf1 <__udivdi3+0x101>
  800ced:	39 d7                	cmp    %edx,%edi
  800cef:	74 0f                	je     800d00 <__udivdi3+0x110>
  800cf1:	89 f0                	mov    %esi,%eax
  800cf3:	31 d2                	xor    %edx,%edx
  800cf5:	e9 46 ff ff ff       	jmp    800c40 <__udivdi3+0x50>
  800cfa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800d00:	8d 46 ff             	lea    -0x1(%esi),%eax
  800d03:	31 d2                	xor    %edx,%edx
  800d05:	8b 74 24 10          	mov    0x10(%esp),%esi
  800d09:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800d0d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800d11:	83 c4 1c             	add    $0x1c,%esp
  800d14:	c3                   	ret    
	...

00800d20 <__umoddi3>:
  800d20:	83 ec 1c             	sub    $0x1c,%esp
  800d23:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  800d27:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
  800d2b:	8b 44 24 20          	mov    0x20(%esp),%eax
  800d2f:	89 74 24 10          	mov    %esi,0x10(%esp)
  800d33:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  800d37:	8b 74 24 24          	mov    0x24(%esp),%esi
  800d3b:	85 ed                	test   %ebp,%ebp
  800d3d:	89 7c 24 14          	mov    %edi,0x14(%esp)
  800d41:	89 44 24 08          	mov    %eax,0x8(%esp)
  800d45:	89 cf                	mov    %ecx,%edi
  800d47:	89 04 24             	mov    %eax,(%esp)
  800d4a:	89 f2                	mov    %esi,%edx
  800d4c:	75 1a                	jne    800d68 <__umoddi3+0x48>
  800d4e:	39 f1                	cmp    %esi,%ecx
  800d50:	76 4e                	jbe    800da0 <__umoddi3+0x80>
  800d52:	f7 f1                	div    %ecx
  800d54:	89 d0                	mov    %edx,%eax
  800d56:	31 d2                	xor    %edx,%edx
  800d58:	8b 74 24 10          	mov    0x10(%esp),%esi
  800d5c:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800d60:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800d64:	83 c4 1c             	add    $0x1c,%esp
  800d67:	c3                   	ret    
  800d68:	39 f5                	cmp    %esi,%ebp
  800d6a:	77 54                	ja     800dc0 <__umoddi3+0xa0>
  800d6c:	0f bd c5             	bsr    %ebp,%eax
  800d6f:	83 f0 1f             	xor    $0x1f,%eax
  800d72:	89 44 24 04          	mov    %eax,0x4(%esp)
  800d76:	75 60                	jne    800dd8 <__umoddi3+0xb8>
  800d78:	3b 0c 24             	cmp    (%esp),%ecx
  800d7b:	0f 87 07 01 00 00    	ja     800e88 <__umoddi3+0x168>
  800d81:	89 f2                	mov    %esi,%edx
  800d83:	8b 34 24             	mov    (%esp),%esi
  800d86:	29 ce                	sub    %ecx,%esi
  800d88:	19 ea                	sbb    %ebp,%edx
  800d8a:	89 34 24             	mov    %esi,(%esp)
  800d8d:	8b 04 24             	mov    (%esp),%eax
  800d90:	8b 74 24 10          	mov    0x10(%esp),%esi
  800d94:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800d98:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800d9c:	83 c4 1c             	add    $0x1c,%esp
  800d9f:	c3                   	ret    
  800da0:	85 c9                	test   %ecx,%ecx
  800da2:	75 0b                	jne    800daf <__umoddi3+0x8f>
  800da4:	b8 01 00 00 00       	mov    $0x1,%eax
  800da9:	31 d2                	xor    %edx,%edx
  800dab:	f7 f1                	div    %ecx
  800dad:	89 c1                	mov    %eax,%ecx
  800daf:	89 f0                	mov    %esi,%eax
  800db1:	31 d2                	xor    %edx,%edx
  800db3:	f7 f1                	div    %ecx
  800db5:	8b 04 24             	mov    (%esp),%eax
  800db8:	f7 f1                	div    %ecx
  800dba:	eb 98                	jmp    800d54 <__umoddi3+0x34>
  800dbc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800dc0:	89 f2                	mov    %esi,%edx
  800dc2:	8b 74 24 10          	mov    0x10(%esp),%esi
  800dc6:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800dca:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800dce:	83 c4 1c             	add    $0x1c,%esp
  800dd1:	c3                   	ret    
  800dd2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800dd8:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800ddd:	89 e8                	mov    %ebp,%eax
  800ddf:	bd 20 00 00 00       	mov    $0x20,%ebp
  800de4:	2b 6c 24 04          	sub    0x4(%esp),%ebp
  800de8:	89 fa                	mov    %edi,%edx
  800dea:	d3 e0                	shl    %cl,%eax
  800dec:	89 e9                	mov    %ebp,%ecx
  800dee:	d3 ea                	shr    %cl,%edx
  800df0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800df5:	09 c2                	or     %eax,%edx
  800df7:	8b 44 24 08          	mov    0x8(%esp),%eax
  800dfb:	89 14 24             	mov    %edx,(%esp)
  800dfe:	89 f2                	mov    %esi,%edx
  800e00:	d3 e7                	shl    %cl,%edi
  800e02:	89 e9                	mov    %ebp,%ecx
  800e04:	d3 ea                	shr    %cl,%edx
  800e06:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800e0b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800e0f:	d3 e6                	shl    %cl,%esi
  800e11:	89 e9                	mov    %ebp,%ecx
  800e13:	d3 e8                	shr    %cl,%eax
  800e15:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800e1a:	09 f0                	or     %esi,%eax
  800e1c:	8b 74 24 08          	mov    0x8(%esp),%esi
  800e20:	f7 34 24             	divl   (%esp)
  800e23:	d3 e6                	shl    %cl,%esi
  800e25:	89 74 24 08          	mov    %esi,0x8(%esp)
  800e29:	89 d6                	mov    %edx,%esi
  800e2b:	f7 e7                	mul    %edi
  800e2d:	39 d6                	cmp    %edx,%esi
  800e2f:	89 c1                	mov    %eax,%ecx
  800e31:	89 d7                	mov    %edx,%edi
  800e33:	72 3f                	jb     800e74 <__umoddi3+0x154>
  800e35:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800e39:	72 35                	jb     800e70 <__umoddi3+0x150>
  800e3b:	8b 44 24 08          	mov    0x8(%esp),%eax
  800e3f:	29 c8                	sub    %ecx,%eax
  800e41:	19 fe                	sbb    %edi,%esi
  800e43:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800e48:	89 f2                	mov    %esi,%edx
  800e4a:	d3 e8                	shr    %cl,%eax
  800e4c:	89 e9                	mov    %ebp,%ecx
  800e4e:	d3 e2                	shl    %cl,%edx
  800e50:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
  800e55:	09 d0                	or     %edx,%eax
  800e57:	89 f2                	mov    %esi,%edx
  800e59:	d3 ea                	shr    %cl,%edx
  800e5b:	8b 74 24 10          	mov    0x10(%esp),%esi
  800e5f:	8b 7c 24 14          	mov    0x14(%esp),%edi
  800e63:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  800e67:	83 c4 1c             	add    $0x1c,%esp
  800e6a:	c3                   	ret    
  800e6b:	90                   	nop
  800e6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e70:	39 d6                	cmp    %edx,%esi
  800e72:	75 c7                	jne    800e3b <__umoddi3+0x11b>
  800e74:	89 d7                	mov    %edx,%edi
  800e76:	89 c1                	mov    %eax,%ecx
  800e78:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
  800e7c:	1b 3c 24             	sbb    (%esp),%edi
  800e7f:	eb ba                	jmp    800e3b <__umoddi3+0x11b>
  800e81:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800e88:	39 f5                	cmp    %esi,%ebp
  800e8a:	0f 82 f1 fe ff ff    	jb     800d81 <__umoddi3+0x61>
  800e90:	e9 f8 fe ff ff       	jmp    800d8d <__umoddi3+0x6d>
