
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 00 1a 10 f0 	movl   $0xf0101a00,(%esp)
f0100055:	e8 ac 09 00 00       	call   f0100a06 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 02 07 00 00       	call   f0100789 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 1c 1a 10 f0 	movl   $0xf0101a1c,(%esp)
f0100092:	e8 6f 09 00 00       	call   f0100a06 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 5e 14 00 00       	call   f0101523 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 8d 04 00 00       	call   f0100557 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 37 1a 10 f0 	movl   $0xf0101a37,(%esp)
f01000d9:	e8 28 09 00 00       	call   f0100a06 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 3f 07 00 00       	call   f0100835 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 52 1a 10 f0 	movl   $0xf0101a52,(%esp)
f010012c:	e8 d5 08 00 00       	call   f0100a06 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 96 08 00 00       	call   f01009d3 <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 8e 1a 10 f0 	movl   $0xf0101a8e,(%esp)
f0100144:	e8 bd 08 00 00       	call   f0100a06 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 e0 06 00 00       	call   f0100835 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 6a 1a 10 f0 	movl   $0xf0101a6a,(%esp)
f0100176:	e8 8b 08 00 00       	call   f0100a06 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 49 08 00 00       	call   f01009d3 <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 8e 1a 10 f0 	movl   $0xf0101a8e,(%esp)
f0100191:	e8 70 08 00 00       	call   f0100a06 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	00 00                	add    %al,(%eax)
	...

f01001a0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a8:	ec                   	in     (%dx),%al
f01001a9:	ec                   	in     (%dx),%al
f01001aa:	ec                   	in     (%dx),%al
f01001ab:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001ac:	5d                   	pop    %ebp
f01001ad:	c3                   	ret    

f01001ae <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001ae:	55                   	push   %ebp
f01001af:	89 e5                	mov    %esp,%ebp
f01001b1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b6:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b7:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001bc:	a8 01                	test   $0x1,%al
f01001be:	74 06                	je     f01001c6 <serial_proc_data+0x18>
f01001c0:	b2 f8                	mov    $0xf8,%dl
f01001c2:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001c3:	0f b6 c8             	movzbl %al,%ecx
}
f01001c6:	89 c8                	mov    %ecx,%eax
f01001c8:	5d                   	pop    %ebp
f01001c9:	c3                   	ret    

f01001ca <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ca:	55                   	push   %ebp
f01001cb:	89 e5                	mov    %esp,%ebp
f01001cd:	53                   	push   %ebx
f01001ce:	83 ec 04             	sub    $0x4,%esp
f01001d1:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001d3:	eb 25                	jmp    f01001fa <cons_intr+0x30>
		if (c == 0)
f01001d5:	85 c0                	test   %eax,%eax
f01001d7:	74 21                	je     f01001fa <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f01001d9:	8b 15 24 25 11 f0    	mov    0xf0112524,%edx
f01001df:	88 82 20 23 11 f0    	mov    %al,-0xfeedce0(%edx)
f01001e5:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01001e8:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01001ed:	ba 00 00 00 00       	mov    $0x0,%edx
f01001f2:	0f 44 c2             	cmove  %edx,%eax
f01001f5:	a3 24 25 11 f0       	mov    %eax,0xf0112524
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001fa:	ff d3                	call   *%ebx
f01001fc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001ff:	75 d4                	jne    f01001d5 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100201:	83 c4 04             	add    $0x4,%esp
f0100204:	5b                   	pop    %ebx
f0100205:	5d                   	pop    %ebp
f0100206:	c3                   	ret    

f0100207 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100207:	55                   	push   %ebp
f0100208:	89 e5                	mov    %esp,%ebp
f010020a:	57                   	push   %edi
f010020b:	56                   	push   %esi
f010020c:	53                   	push   %ebx
f010020d:	83 ec 2c             	sub    $0x2c,%esp
f0100210:	89 c7                	mov    %eax,%edi
f0100212:	bb 01 32 00 00       	mov    $0x3201,%ebx
f0100217:	be fd 03 00 00       	mov    $0x3fd,%esi
f010021c:	eb 05                	jmp    f0100223 <cons_putc+0x1c>
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f010021e:	e8 7d ff ff ff       	call   f01001a0 <delay>
f0100223:	89 f2                	mov    %esi,%edx
f0100225:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100226:	a8 20                	test   $0x20,%al
f0100228:	75 05                	jne    f010022f <cons_putc+0x28>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010022a:	83 eb 01             	sub    $0x1,%ebx
f010022d:	75 ef                	jne    f010021e <cons_putc+0x17>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f010022f:	89 fa                	mov    %edi,%edx
f0100231:	89 f8                	mov    %edi,%eax
f0100233:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100236:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010023b:	ee                   	out    %al,(%dx)
f010023c:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100241:	be 79 03 00 00       	mov    $0x379,%esi
f0100246:	eb 05                	jmp    f010024d <cons_putc+0x46>
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
		delay();
f0100248:	e8 53 ff ff ff       	call   f01001a0 <delay>
f010024d:	89 f2                	mov    %esi,%edx
f010024f:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100250:	84 c0                	test   %al,%al
f0100252:	78 05                	js     f0100259 <cons_putc+0x52>
f0100254:	83 eb 01             	sub    $0x1,%ebx
f0100257:	75 ef                	jne    f0100248 <cons_putc+0x41>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100259:	ba 78 03 00 00       	mov    $0x378,%edx
f010025e:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100262:	ee                   	out    %al,(%dx)
f0100263:	b2 7a                	mov    $0x7a,%dl
f0100265:	b8 0d 00 00 00       	mov    $0xd,%eax
f010026a:	ee                   	out    %al,(%dx)
f010026b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100270:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100271:	89 fa                	mov    %edi,%edx
f0100273:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100279:	89 f8                	mov    %edi,%eax
f010027b:	80 cc 07             	or     $0x7,%ah
f010027e:	85 d2                	test   %edx,%edx
f0100280:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100283:	89 f8                	mov    %edi,%eax
f0100285:	25 ff 00 00 00       	and    $0xff,%eax
f010028a:	83 f8 09             	cmp    $0x9,%eax
f010028d:	74 79                	je     f0100308 <cons_putc+0x101>
f010028f:	83 f8 09             	cmp    $0x9,%eax
f0100292:	7f 0e                	jg     f01002a2 <cons_putc+0x9b>
f0100294:	83 f8 08             	cmp    $0x8,%eax
f0100297:	0f 85 9f 00 00 00    	jne    f010033c <cons_putc+0x135>
f010029d:	8d 76 00             	lea    0x0(%esi),%esi
f01002a0:	eb 10                	jmp    f01002b2 <cons_putc+0xab>
f01002a2:	83 f8 0a             	cmp    $0xa,%eax
f01002a5:	74 3b                	je     f01002e2 <cons_putc+0xdb>
f01002a7:	83 f8 0d             	cmp    $0xd,%eax
f01002aa:	0f 85 8c 00 00 00    	jne    f010033c <cons_putc+0x135>
f01002b0:	eb 38                	jmp    f01002ea <cons_putc+0xe3>
	case '\b':
		if (crt_pos > 0) {
f01002b2:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f01002b9:	66 85 c0             	test   %ax,%ax
f01002bc:	0f 84 e4 00 00 00    	je     f01003a6 <cons_putc+0x19f>
			crt_pos--;
f01002c2:	83 e8 01             	sub    $0x1,%eax
f01002c5:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002cb:	0f b7 c0             	movzwl %ax,%eax
f01002ce:	66 81 e7 00 ff       	and    $0xff00,%di
f01002d3:	83 cf 20             	or     $0x20,%edi
f01002d6:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f01002dc:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002e0:	eb 77                	jmp    f0100359 <cons_putc+0x152>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002e2:	66 83 05 34 25 11 f0 	addw   $0x50,0xf0112534
f01002e9:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002ea:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f01002f1:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002f7:	c1 e8 16             	shr    $0x16,%eax
f01002fa:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002fd:	c1 e0 04             	shl    $0x4,%eax
f0100300:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
f0100306:	eb 51                	jmp    f0100359 <cons_putc+0x152>
		break;
	case '\t':
		cons_putc(' ');
f0100308:	b8 20 00 00 00       	mov    $0x20,%eax
f010030d:	e8 f5 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100312:	b8 20 00 00 00       	mov    $0x20,%eax
f0100317:	e8 eb fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f010031c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100321:	e8 e1 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100326:	b8 20 00 00 00       	mov    $0x20,%eax
f010032b:	e8 d7 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100330:	b8 20 00 00 00       	mov    $0x20,%eax
f0100335:	e8 cd fe ff ff       	call   f0100207 <cons_putc>
f010033a:	eb 1d                	jmp    f0100359 <cons_putc+0x152>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010033c:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f0100343:	0f b7 c8             	movzwl %ax,%ecx
f0100346:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f010034c:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100350:	83 c0 01             	add    $0x1,%eax
f0100353:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100359:	66 81 3d 34 25 11 f0 	cmpw   $0x7cf,0xf0112534
f0100360:	cf 07 
f0100362:	76 42                	jbe    f01003a6 <cons_putc+0x19f>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100364:	a1 30 25 11 f0       	mov    0xf0112530,%eax
f0100369:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100370:	00 
f0100371:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100377:	89 54 24 04          	mov    %edx,0x4(%esp)
f010037b:	89 04 24             	mov    %eax,(%esp)
f010037e:	e8 fb 11 00 00       	call   f010157e <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100383:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100389:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010038e:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100394:	83 c0 01             	add    $0x1,%eax
f0100397:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f010039c:	75 f0                	jne    f010038e <cons_putc+0x187>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010039e:	66 83 2d 34 25 11 f0 	subw   $0x50,0xf0112534
f01003a5:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01003a6:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01003ac:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003b1:	89 ca                	mov    %ecx,%edx
f01003b3:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003b4:	0f b7 35 34 25 11 f0 	movzwl 0xf0112534,%esi
f01003bb:	8d 59 01             	lea    0x1(%ecx),%ebx
f01003be:	89 f0                	mov    %esi,%eax
f01003c0:	66 c1 e8 08          	shr    $0x8,%ax
f01003c4:	89 da                	mov    %ebx,%edx
f01003c6:	ee                   	out    %al,(%dx)
f01003c7:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003cc:	89 ca                	mov    %ecx,%edx
f01003ce:	ee                   	out    %al,(%dx)
f01003cf:	89 f0                	mov    %esi,%eax
f01003d1:	89 da                	mov    %ebx,%edx
f01003d3:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003d4:	83 c4 2c             	add    $0x2c,%esp
f01003d7:	5b                   	pop    %ebx
f01003d8:	5e                   	pop    %esi
f01003d9:	5f                   	pop    %edi
f01003da:	5d                   	pop    %ebp
f01003db:	c3                   	ret    

f01003dc <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003dc:	55                   	push   %ebp
f01003dd:	89 e5                	mov    %esp,%ebp
f01003df:	53                   	push   %ebx
f01003e0:	83 ec 14             	sub    $0x14,%esp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003e3:	ba 64 00 00 00       	mov    $0x64,%edx
f01003e8:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01003e9:	0f b6 c0             	movzbl %al,%eax
		return -1;
f01003ec:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01003f1:	a8 01                	test   $0x1,%al
f01003f3:	0f 84 e6 00 00 00    	je     f01004df <kbd_proc_data+0x103>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01003f9:	a8 20                	test   $0x20,%al
f01003fb:	0f 85 de 00 00 00    	jne    f01004df <kbd_proc_data+0x103>
f0100401:	b2 60                	mov    $0x60,%dl
f0100403:	ec                   	in     (%dx),%al
f0100404:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100406:	3c e0                	cmp    $0xe0,%al
f0100408:	75 11                	jne    f010041b <kbd_proc_data+0x3f>
		// E0 escape character
		shift |= E0ESC;
f010040a:	83 0d 28 25 11 f0 40 	orl    $0x40,0xf0112528
		return 0;
f0100411:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100416:	e9 c4 00 00 00       	jmp    f01004df <kbd_proc_data+0x103>
	} else if (data & 0x80) {
f010041b:	84 c0                	test   %al,%al
f010041d:	79 37                	jns    f0100456 <kbd_proc_data+0x7a>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010041f:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f0100425:	89 cb                	mov    %ecx,%ebx
f0100427:	83 e3 40             	and    $0x40,%ebx
f010042a:	83 e0 7f             	and    $0x7f,%eax
f010042d:	85 db                	test   %ebx,%ebx
f010042f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100432:	0f b6 d2             	movzbl %dl,%edx
f0100435:	0f b6 82 c0 1a 10 f0 	movzbl -0xfefe540(%edx),%eax
f010043c:	83 c8 40             	or     $0x40,%eax
f010043f:	0f b6 c0             	movzbl %al,%eax
f0100442:	f7 d0                	not    %eax
f0100444:	21 c1                	and    %eax,%ecx
f0100446:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
		return 0;
f010044c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100451:	e9 89 00 00 00       	jmp    f01004df <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100456:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f010045c:	f6 c1 40             	test   $0x40,%cl
f010045f:	74 0e                	je     f010046f <kbd_proc_data+0x93>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100461:	89 c2                	mov    %eax,%edx
f0100463:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100466:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100469:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
	}

	shift |= shiftcode[data];
f010046f:	0f b6 d2             	movzbl %dl,%edx
f0100472:	0f b6 82 c0 1a 10 f0 	movzbl -0xfefe540(%edx),%eax
f0100479:	0b 05 28 25 11 f0    	or     0xf0112528,%eax
	shift ^= togglecode[data];
f010047f:	0f b6 8a c0 1b 10 f0 	movzbl -0xfefe440(%edx),%ecx
f0100486:	31 c8                	xor    %ecx,%eax
f0100488:	a3 28 25 11 f0       	mov    %eax,0xf0112528

	c = charcode[shift & (CTL | SHIFT)][data];
f010048d:	89 c1                	mov    %eax,%ecx
f010048f:	83 e1 03             	and    $0x3,%ecx
f0100492:	8b 0c 8d c0 1c 10 f0 	mov    -0xfefe340(,%ecx,4),%ecx
f0100499:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f010049d:	a8 08                	test   $0x8,%al
f010049f:	74 19                	je     f01004ba <kbd_proc_data+0xde>
		if ('a' <= c && c <= 'z')
f01004a1:	8d 53 9f             	lea    -0x61(%ebx),%edx
f01004a4:	83 fa 19             	cmp    $0x19,%edx
f01004a7:	77 05                	ja     f01004ae <kbd_proc_data+0xd2>
			c += 'A' - 'a';
f01004a9:	83 eb 20             	sub    $0x20,%ebx
f01004ac:	eb 0c                	jmp    f01004ba <kbd_proc_data+0xde>
		else if ('A' <= c && c <= 'Z')
f01004ae:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f01004b1:	8d 53 20             	lea    0x20(%ebx),%edx
f01004b4:	83 f9 19             	cmp    $0x19,%ecx
f01004b7:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01004ba:	f7 d0                	not    %eax
f01004bc:	a8 06                	test   $0x6,%al
f01004be:	75 1f                	jne    f01004df <kbd_proc_data+0x103>
f01004c0:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004c6:	75 17                	jne    f01004df <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01004c8:	c7 04 24 84 1a 10 f0 	movl   $0xf0101a84,(%esp)
f01004cf:	e8 32 05 00 00       	call   f0100a06 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004d4:	ba 92 00 00 00       	mov    $0x92,%edx
f01004d9:	b8 03 00 00 00       	mov    $0x3,%eax
f01004de:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004df:	89 d8                	mov    %ebx,%eax
f01004e1:	83 c4 14             	add    $0x14,%esp
f01004e4:	5b                   	pop    %ebx
f01004e5:	5d                   	pop    %ebp
f01004e6:	c3                   	ret    

f01004e7 <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004e7:	55                   	push   %ebp
f01004e8:	89 e5                	mov    %esp,%ebp
f01004ea:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f01004ed:	80 3d 00 23 11 f0 00 	cmpb   $0x0,0xf0112300
f01004f4:	74 0a                	je     f0100500 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f01004f6:	b8 ae 01 10 f0       	mov    $0xf01001ae,%eax
f01004fb:	e8 ca fc ff ff       	call   f01001ca <cons_intr>
}
f0100500:	c9                   	leave  
f0100501:	c3                   	ret    

f0100502 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100502:	55                   	push   %ebp
f0100503:	89 e5                	mov    %esp,%ebp
f0100505:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100508:	b8 dc 03 10 f0       	mov    $0xf01003dc,%eax
f010050d:	e8 b8 fc ff ff       	call   f01001ca <cons_intr>
}
f0100512:	c9                   	leave  
f0100513:	c3                   	ret    

f0100514 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100514:	55                   	push   %ebp
f0100515:	89 e5                	mov    %esp,%ebp
f0100517:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010051a:	e8 c8 ff ff ff       	call   f01004e7 <serial_intr>
	kbd_intr();
f010051f:	e8 de ff ff ff       	call   f0100502 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100524:	8b 15 20 25 11 f0    	mov    0xf0112520,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f010052a:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010052f:	3b 15 24 25 11 f0    	cmp    0xf0112524,%edx
f0100535:	74 1e                	je     f0100555 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f0100537:	0f b6 82 20 23 11 f0 	movzbl -0xfeedce0(%edx),%eax
f010053e:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f0100541:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100547:	b9 00 00 00 00       	mov    $0x0,%ecx
f010054c:	0f 44 d1             	cmove  %ecx,%edx
f010054f:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
		return c;
	}
	return 0;
}
f0100555:	c9                   	leave  
f0100556:	c3                   	ret    

f0100557 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100557:	55                   	push   %ebp
f0100558:	89 e5                	mov    %esp,%ebp
f010055a:	57                   	push   %edi
f010055b:	56                   	push   %esi
f010055c:	53                   	push   %ebx
f010055d:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100560:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100567:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010056e:	5a a5 
	if (*cp != 0xA55A) {
f0100570:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100577:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010057b:	74 11                	je     f010058e <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010057d:	c7 05 2c 25 11 f0 b4 	movl   $0x3b4,0xf011252c
f0100584:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100587:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010058c:	eb 16                	jmp    f01005a4 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010058e:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100595:	c7 05 2c 25 11 f0 d4 	movl   $0x3d4,0xf011252c
f010059c:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010059f:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005a4:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01005aa:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005af:	89 ca                	mov    %ecx,%edx
f01005b1:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005b2:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b5:	89 da                	mov    %ebx,%edx
f01005b7:	ec                   	in     (%dx),%al
f01005b8:	0f b6 f8             	movzbl %al,%edi
f01005bb:	c1 e7 08             	shl    $0x8,%edi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005be:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005c3:	89 ca                	mov    %ecx,%edx
f01005c5:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c6:	89 da                	mov    %ebx,%edx
f01005c8:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005c9:	89 35 30 25 11 f0    	mov    %esi,0xf0112530

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005cf:	0f b6 d8             	movzbl %al,%ebx
f01005d2:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005d4:	66 89 3d 34 25 11 f0 	mov    %di,0xf0112534
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005db:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005e0:	b8 00 00 00 00       	mov    $0x0,%eax
f01005e5:	89 da                	mov    %ebx,%edx
f01005e7:	ee                   	out    %al,(%dx)
f01005e8:	b2 fb                	mov    $0xfb,%dl
f01005ea:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005ef:	ee                   	out    %al,(%dx)
f01005f0:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f01005f5:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005fa:	89 ca                	mov    %ecx,%edx
f01005fc:	ee                   	out    %al,(%dx)
f01005fd:	b2 f9                	mov    $0xf9,%dl
f01005ff:	b8 00 00 00 00       	mov    $0x0,%eax
f0100604:	ee                   	out    %al,(%dx)
f0100605:	b2 fb                	mov    $0xfb,%dl
f0100607:	b8 03 00 00 00       	mov    $0x3,%eax
f010060c:	ee                   	out    %al,(%dx)
f010060d:	b2 fc                	mov    $0xfc,%dl
f010060f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 f9                	mov    $0xf9,%dl
f0100617:	b8 01 00 00 00       	mov    $0x1,%eax
f010061c:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010061d:	b2 fd                	mov    $0xfd,%dl
f010061f:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100620:	3c ff                	cmp    $0xff,%al
f0100622:	0f 95 c0             	setne  %al
f0100625:	89 c6                	mov    %eax,%esi
f0100627:	a2 00 23 11 f0       	mov    %al,0xf0112300
f010062c:	89 da                	mov    %ebx,%edx
f010062e:	ec                   	in     (%dx),%al
f010062f:	89 ca                	mov    %ecx,%edx
f0100631:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100632:	89 f0                	mov    %esi,%eax
f0100634:	84 c0                	test   %al,%al
f0100636:	75 0c                	jne    f0100644 <cons_init+0xed>
		cprintf("Serial port does not exist!\n");
f0100638:	c7 04 24 90 1a 10 f0 	movl   $0xf0101a90,(%esp)
f010063f:	e8 c2 03 00 00       	call   f0100a06 <cprintf>
}
f0100644:	83 c4 1c             	add    $0x1c,%esp
f0100647:	5b                   	pop    %ebx
f0100648:	5e                   	pop    %esi
f0100649:	5f                   	pop    %edi
f010064a:	5d                   	pop    %ebp
f010064b:	c3                   	ret    

f010064c <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010064c:	55                   	push   %ebp
f010064d:	89 e5                	mov    %esp,%ebp
f010064f:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100652:	8b 45 08             	mov    0x8(%ebp),%eax
f0100655:	e8 ad fb ff ff       	call   f0100207 <cons_putc>
}
f010065a:	c9                   	leave  
f010065b:	c3                   	ret    

f010065c <getchar>:

int
getchar(void)
{
f010065c:	55                   	push   %ebp
f010065d:	89 e5                	mov    %esp,%ebp
f010065f:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100662:	e8 ad fe ff ff       	call   f0100514 <cons_getc>
f0100667:	85 c0                	test   %eax,%eax
f0100669:	74 f7                	je     f0100662 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010066b:	c9                   	leave  
f010066c:	c3                   	ret    

f010066d <iscons>:

int
iscons(int fdnum)
{
f010066d:	55                   	push   %ebp
f010066e:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100670:	b8 01 00 00 00       	mov    $0x1,%eax
f0100675:	5d                   	pop    %ebp
f0100676:	c3                   	ret    
	...

f0100680 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100680:	55                   	push   %ebp
f0100681:	89 e5                	mov    %esp,%ebp
f0100683:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100686:	c7 04 24 d0 1c 10 f0 	movl   $0xf0101cd0,(%esp)
f010068d:	e8 74 03 00 00       	call   f0100a06 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100692:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100699:	00 
f010069a:	c7 04 24 b8 1d 10 f0 	movl   $0xf0101db8,(%esp)
f01006a1:	e8 60 03 00 00       	call   f0100a06 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006a6:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006ad:	00 
f01006ae:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006b5:	f0 
f01006b6:	c7 04 24 e0 1d 10 f0 	movl   $0xf0101de0,(%esp)
f01006bd:	e8 44 03 00 00       	call   f0100a06 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006c2:	c7 44 24 08 f5 19 10 	movl   $0x1019f5,0x8(%esp)
f01006c9:	00 
f01006ca:	c7 44 24 04 f5 19 10 	movl   $0xf01019f5,0x4(%esp)
f01006d1:	f0 
f01006d2:	c7 04 24 04 1e 10 f0 	movl   $0xf0101e04,(%esp)
f01006d9:	e8 28 03 00 00       	call   f0100a06 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006de:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f01006e5:	00 
f01006e6:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f01006ed:	f0 
f01006ee:	c7 04 24 28 1e 10 f0 	movl   $0xf0101e28,(%esp)
f01006f5:	e8 0c 03 00 00       	call   f0100a06 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006fa:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100701:	00 
f0100702:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f0100709:	f0 
f010070a:	c7 04 24 4c 1e 10 f0 	movl   $0xf0101e4c,(%esp)
f0100711:	e8 f0 02 00 00       	call   f0100a06 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100716:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010071b:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100720:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100725:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010072b:	85 c0                	test   %eax,%eax
f010072d:	0f 48 c2             	cmovs  %edx,%eax
f0100730:	c1 f8 0a             	sar    $0xa,%eax
f0100733:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100737:	c7 04 24 70 1e 10 f0 	movl   $0xf0101e70,(%esp)
f010073e:	e8 c3 02 00 00       	call   f0100a06 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100743:	b8 00 00 00 00       	mov    $0x0,%eax
f0100748:	c9                   	leave  
f0100749:	c3                   	ret    

f010074a <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010074a:	55                   	push   %ebp
f010074b:	89 e5                	mov    %esp,%ebp
f010074d:	53                   	push   %ebx
f010074e:	83 ec 14             	sub    $0x14,%esp
f0100751:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100756:	8b 83 84 1f 10 f0    	mov    -0xfefe07c(%ebx),%eax
f010075c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100760:	8b 83 80 1f 10 f0    	mov    -0xfefe080(%ebx),%eax
f0100766:	89 44 24 04          	mov    %eax,0x4(%esp)
f010076a:	c7 04 24 e9 1c 10 f0 	movl   $0xf0101ce9,(%esp)
f0100771:	e8 90 02 00 00       	call   f0100a06 <cprintf>
f0100776:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
f0100779:	83 fb 24             	cmp    $0x24,%ebx
f010077c:	75 d8                	jne    f0100756 <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f010077e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100783:	83 c4 14             	add    $0x14,%esp
f0100786:	5b                   	pop    %ebx
f0100787:	5d                   	pop    %ebp
f0100788:	c3                   	ret    

f0100789 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100789:	55                   	push   %ebp
f010078a:	89 e5                	mov    %esp,%ebp
f010078c:	56                   	push   %esi
f010078d:	53                   	push   %ebx
f010078e:	83 ec 40             	sub    $0x40,%esp
	// Your code here.
	struct Eipdebuginfo info;
	int *ebp = (int*)read_ebp();
f0100791:	89 eb                	mov    %ebp,%ebx
	cprintf("Stack backtrace:\n");
f0100793:	c7 04 24 f2 1c 10 f0 	movl   $0xf0101cf2,(%esp)
f010079a:	e8 67 02 00 00       	call   f0100a06 <cprintf>
	while (ebp != 0)
	{
		cprintf("ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, *(ebp+1), *(ebp+2), *(ebp+3), *(ebp+4), *(ebp+5), *(ebp+6));
		debuginfo_eip(*(ebp+1), &info);
f010079f:	8d 75 e0             	lea    -0x20(%ebp),%esi
{
	// Your code here.
	struct Eipdebuginfo info;
	int *ebp = (int*)read_ebp();
	cprintf("Stack backtrace:\n");
	while (ebp != 0)
f01007a2:	eb 7d                	jmp    f0100821 <mon_backtrace+0x98>
	{
		cprintf("ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, *(ebp+1), *(ebp+2), *(ebp+3), *(ebp+4), *(ebp+5), *(ebp+6));
f01007a4:	8b 43 18             	mov    0x18(%ebx),%eax
f01007a7:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f01007ab:	8b 43 14             	mov    0x14(%ebx),%eax
f01007ae:	89 44 24 18          	mov    %eax,0x18(%esp)
f01007b2:	8b 43 10             	mov    0x10(%ebx),%eax
f01007b5:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007b9:	8b 43 0c             	mov    0xc(%ebx),%eax
f01007bc:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007c0:	8b 43 08             	mov    0x8(%ebx),%eax
f01007c3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007c7:	8b 43 04             	mov    0x4(%ebx),%eax
f01007ca:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007ce:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01007d2:	c7 04 24 9c 1e 10 f0 	movl   $0xf0101e9c,(%esp)
f01007d9:	e8 28 02 00 00       	call   f0100a06 <cprintf>
		debuginfo_eip(*(ebp+1), &info);
f01007de:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007e2:	8b 43 04             	mov    0x4(%ebx),%eax
f01007e5:	89 04 24             	mov    %eax,(%esp)
f01007e8:	e8 13 03 00 00       	call   f0100b00 <debuginfo_eip>
		cprintf("       %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, *(ebp+1)-info.eip_fn_addr);
f01007ed:	8b 43 04             	mov    0x4(%ebx),%eax
f01007f0:	2b 45 f0             	sub    -0x10(%ebp),%eax
f01007f3:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007f7:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01007fa:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007fe:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100801:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100805:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100808:	89 44 24 08          	mov    %eax,0x8(%esp)
f010080c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010080f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100813:	c7 04 24 04 1d 10 f0 	movl   $0xf0101d04,(%esp)
f010081a:	e8 e7 01 00 00       	call   f0100a06 <cprintf>
		ebp = (int*)*ebp;
f010081f:	8b 1b                	mov    (%ebx),%ebx
{
	// Your code here.
	struct Eipdebuginfo info;
	int *ebp = (int*)read_ebp();
	cprintf("Stack backtrace:\n");
	while (ebp != 0)
f0100821:	85 db                	test   %ebx,%ebx
f0100823:	0f 85 7b ff ff ff    	jne    f01007a4 <mon_backtrace+0x1b>
		debuginfo_eip(*(ebp+1), &info);
		cprintf("       %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, *(ebp+1)-info.eip_fn_addr);
		ebp = (int*)*ebp;
	}
	return 0;
}
f0100829:	b8 00 00 00 00       	mov    $0x0,%eax
f010082e:	83 c4 40             	add    $0x40,%esp
f0100831:	5b                   	pop    %ebx
f0100832:	5e                   	pop    %esi
f0100833:	5d                   	pop    %ebp
f0100834:	c3                   	ret    

f0100835 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100835:	55                   	push   %ebp
f0100836:	89 e5                	mov    %esp,%ebp
f0100838:	57                   	push   %edi
f0100839:	56                   	push   %esi
f010083a:	53                   	push   %ebx
f010083b:	83 ec 6c             	sub    $0x6c,%esp
	char *buf;
	int x = 1, y = 3, z = 4;
	cprintf("x %d y %x z %d\n", x, y, z);
f010083e:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0100845:	00 
f0100846:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
f010084d:	00 
f010084e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0100855:	00 
f0100856:	c7 04 24 1b 1d 10 f0 	movl   $0xf0101d1b,(%esp)
f010085d:	e8 a4 01 00 00       	call   f0100a06 <cprintf>
	unsigned int i = 0x00646c72;
f0100862:	c7 45 e4 72 6c 64 00 	movl   $0x646c72,-0x1c(%ebp)
	cprintf("H%x Wo%s\n", 57616, &i);
f0100869:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010086c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100870:	c7 44 24 04 10 e1 00 	movl   $0xe110,0x4(%esp)
f0100877:	00 
f0100878:	c7 04 24 2b 1d 10 f0 	movl   $0xf0101d2b,(%esp)
f010087f:	e8 82 01 00 00       	call   f0100a06 <cprintf>
	cprintf("x=%d y=%d\n",3);
f0100884:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f010088b:	00 
f010088c:	c7 04 24 35 1d 10 f0 	movl   $0xf0101d35,(%esp)
f0100893:	e8 6e 01 00 00       	call   f0100a06 <cprintf>
	cprintf("Welcome to the JOS kernel monitor!\n");
f0100898:	c7 04 24 d0 1e 10 f0 	movl   $0xf0101ed0,(%esp)
f010089f:	e8 62 01 00 00       	call   f0100a06 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008a4:	c7 04 24 f4 1e 10 f0 	movl   $0xf0101ef4,(%esp)
f01008ab:	e8 56 01 00 00       	call   f0100a06 <cprintf>


	while (1) {
		buf = readline("K> ");
f01008b0:	c7 04 24 40 1d 10 f0 	movl   $0xf0101d40,(%esp)
f01008b7:	e8 14 0a 00 00       	call   f01012d0 <readline>
f01008bc:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01008be:	85 c0                	test   %eax,%eax
f01008c0:	74 ee                	je     f01008b0 <monitor+0x7b>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008c2:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008c9:	be 00 00 00 00       	mov    $0x0,%esi
f01008ce:	eb 06                	jmp    f01008d6 <monitor+0xa1>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008d0:	c6 03 00             	movb   $0x0,(%ebx)
f01008d3:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008d6:	0f b6 03             	movzbl (%ebx),%eax
f01008d9:	84 c0                	test   %al,%al
f01008db:	74 63                	je     f0100940 <monitor+0x10b>
f01008dd:	0f be c0             	movsbl %al,%eax
f01008e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008e4:	c7 04 24 44 1d 10 f0 	movl   $0xf0101d44,(%esp)
f01008eb:	e8 f6 0b 00 00       	call   f01014e6 <strchr>
f01008f0:	85 c0                	test   %eax,%eax
f01008f2:	75 dc                	jne    f01008d0 <monitor+0x9b>
			*buf++ = 0;
		if (*buf == 0)
f01008f4:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008f7:	74 47                	je     f0100940 <monitor+0x10b>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008f9:	83 fe 0f             	cmp    $0xf,%esi
f01008fc:	75 16                	jne    f0100914 <monitor+0xdf>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008fe:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100905:	00 
f0100906:	c7 04 24 49 1d 10 f0 	movl   $0xf0101d49,(%esp)
f010090d:	e8 f4 00 00 00       	call   f0100a06 <cprintf>
f0100912:	eb 9c                	jmp    f01008b0 <monitor+0x7b>
			return 0;
		}
		argv[argc++] = buf;
f0100914:	89 5c b5 a4          	mov    %ebx,-0x5c(%ebp,%esi,4)
f0100918:	83 c6 01             	add    $0x1,%esi
f010091b:	eb 03                	jmp    f0100920 <monitor+0xeb>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010091d:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100920:	0f b6 03             	movzbl (%ebx),%eax
f0100923:	84 c0                	test   %al,%al
f0100925:	74 af                	je     f01008d6 <monitor+0xa1>
f0100927:	0f be c0             	movsbl %al,%eax
f010092a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010092e:	c7 04 24 44 1d 10 f0 	movl   $0xf0101d44,(%esp)
f0100935:	e8 ac 0b 00 00       	call   f01014e6 <strchr>
f010093a:	85 c0                	test   %eax,%eax
f010093c:	74 df                	je     f010091d <monitor+0xe8>
f010093e:	eb 96                	jmp    f01008d6 <monitor+0xa1>
			buf++;
	}
	argv[argc] = 0;
f0100940:	c7 44 b5 a4 00 00 00 	movl   $0x0,-0x5c(%ebp,%esi,4)
f0100947:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100948:	85 f6                	test   %esi,%esi
f010094a:	0f 84 60 ff ff ff    	je     f01008b0 <monitor+0x7b>
f0100950:	bb 80 1f 10 f0       	mov    $0xf0101f80,%ebx
f0100955:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010095a:	8b 03                	mov    (%ebx),%eax
f010095c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100960:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100963:	89 04 24             	mov    %eax,(%esp)
f0100966:	e8 1c 0b 00 00       	call   f0101487 <strcmp>
f010096b:	85 c0                	test   %eax,%eax
f010096d:	75 24                	jne    f0100993 <monitor+0x15e>
			return commands[i].func(argc, argv, tf);
f010096f:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100972:	8b 55 08             	mov    0x8(%ebp),%edx
f0100975:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100979:	8d 55 a4             	lea    -0x5c(%ebp),%edx
f010097c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100980:	89 34 24             	mov    %esi,(%esp)
f0100983:	ff 14 85 88 1f 10 f0 	call   *-0xfefe078(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010098a:	85 c0                	test   %eax,%eax
f010098c:	78 28                	js     f01009b6 <monitor+0x181>
f010098e:	e9 1d ff ff ff       	jmp    f01008b0 <monitor+0x7b>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100993:	83 c7 01             	add    $0x1,%edi
f0100996:	83 c3 0c             	add    $0xc,%ebx
f0100999:	83 ff 03             	cmp    $0x3,%edi
f010099c:	75 bc                	jne    f010095a <monitor+0x125>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010099e:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009a1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009a5:	c7 04 24 66 1d 10 f0 	movl   $0xf0101d66,(%esp)
f01009ac:	e8 55 00 00 00       	call   f0100a06 <cprintf>
f01009b1:	e9 fa fe ff ff       	jmp    f01008b0 <monitor+0x7b>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01009b6:	83 c4 6c             	add    $0x6c,%esp
f01009b9:	5b                   	pop    %ebx
f01009ba:	5e                   	pop    %esi
f01009bb:	5f                   	pop    %edi
f01009bc:	5d                   	pop    %ebp
f01009bd:	c3                   	ret    
	...

f01009c0 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01009c0:	55                   	push   %ebp
f01009c1:	89 e5                	mov    %esp,%ebp
f01009c3:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01009c6:	8b 45 08             	mov    0x8(%ebp),%eax
f01009c9:	89 04 24             	mov    %eax,(%esp)
f01009cc:	e8 7b fc ff ff       	call   f010064c <cputchar>
	*cnt++;
}
f01009d1:	c9                   	leave  
f01009d2:	c3                   	ret    

f01009d3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009d3:	55                   	push   %ebp
f01009d4:	89 e5                	mov    %esp,%ebp
f01009d6:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009d9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009e0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009e3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01009ea:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009ee:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009f1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009f5:	c7 04 24 c0 09 10 f0 	movl   $0xf01009c0,(%esp)
f01009fc:	e8 8c 04 00 00       	call   f0100e8d <vprintfmt>
	return cnt;
}
f0100a01:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a04:	c9                   	leave  
f0100a05:	c3                   	ret    

f0100a06 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a06:	55                   	push   %ebp
f0100a07:	89 e5                	mov    %esp,%ebp
f0100a09:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a0c:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a0f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a13:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a16:	89 04 24             	mov    %eax,(%esp)
f0100a19:	e8 b5 ff ff ff       	call   f01009d3 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a1e:	c9                   	leave  
f0100a1f:	c3                   	ret    

f0100a20 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a20:	55                   	push   %ebp
f0100a21:	89 e5                	mov    %esp,%ebp
f0100a23:	57                   	push   %edi
f0100a24:	56                   	push   %esi
f0100a25:	53                   	push   %ebx
f0100a26:	83 ec 10             	sub    $0x10,%esp
f0100a29:	89 c3                	mov    %eax,%ebx
f0100a2b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a2e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a31:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a34:	8b 0a                	mov    (%edx),%ecx
f0100a36:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a39:	8b 00                	mov    (%eax),%eax
f0100a3b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a3e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100a45:	eb 77                	jmp    f0100abe <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0100a47:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a4a:	01 c8                	add    %ecx,%eax
f0100a4c:	bf 02 00 00 00       	mov    $0x2,%edi
f0100a51:	99                   	cltd   
f0100a52:	f7 ff                	idiv   %edi
f0100a54:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a56:	eb 01                	jmp    f0100a59 <stab_binsearch+0x39>
			m--;
f0100a58:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a59:	39 ca                	cmp    %ecx,%edx
f0100a5b:	7c 1d                	jl     f0100a7a <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100a5d:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a60:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0100a65:	39 f7                	cmp    %esi,%edi
f0100a67:	75 ef                	jne    f0100a58 <stab_binsearch+0x38>
f0100a69:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a6c:	6b fa 0c             	imul   $0xc,%edx,%edi
f0100a6f:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0100a73:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100a76:	73 18                	jae    f0100a90 <stab_binsearch+0x70>
f0100a78:	eb 05                	jmp    f0100a7f <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a7a:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0100a7d:	eb 3f                	jmp    f0100abe <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a7f:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100a82:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0100a84:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a87:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a8e:	eb 2e                	jmp    f0100abe <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a90:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100a93:	76 15                	jbe    f0100aaa <stab_binsearch+0x8a>
			*region_right = m - 1;
f0100a95:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100a98:	4f                   	dec    %edi
f0100a99:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0100a9c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a9f:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100aa1:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100aa8:	eb 14                	jmp    f0100abe <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100aaa:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100aad:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100ab0:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0100ab2:	ff 45 0c             	incl   0xc(%ebp)
f0100ab5:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100ab7:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100abe:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0100ac1:	7e 84                	jle    f0100a47 <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100ac3:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100ac7:	75 0d                	jne    f0100ad6 <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0100ac9:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100acc:	8b 02                	mov    (%edx),%eax
f0100ace:	48                   	dec    %eax
f0100acf:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100ad2:	89 01                	mov    %eax,(%ecx)
f0100ad4:	eb 22                	jmp    f0100af8 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ad6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100ad9:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100adb:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100ade:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ae0:	eb 01                	jmp    f0100ae3 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100ae2:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ae3:	39 c1                	cmp    %eax,%ecx
f0100ae5:	7d 0c                	jge    f0100af3 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100ae7:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100aea:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0100aef:	39 f2                	cmp    %esi,%edx
f0100af1:	75 ef                	jne    f0100ae2 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100af3:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100af6:	89 02                	mov    %eax,(%edx)
	}
}
f0100af8:	83 c4 10             	add    $0x10,%esp
f0100afb:	5b                   	pop    %ebx
f0100afc:	5e                   	pop    %esi
f0100afd:	5f                   	pop    %edi
f0100afe:	5d                   	pop    %ebp
f0100aff:	c3                   	ret    

f0100b00 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b00:	55                   	push   %ebp
f0100b01:	89 e5                	mov    %esp,%ebp
f0100b03:	83 ec 58             	sub    $0x58,%esp
f0100b06:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100b09:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100b0c:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100b0f:	8b 75 08             	mov    0x8(%ebp),%esi
f0100b12:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b15:	c7 03 a4 1f 10 f0    	movl   $0xf0101fa4,(%ebx)
	info->eip_line = 0;
f0100b1b:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b22:	c7 43 08 a4 1f 10 f0 	movl   $0xf0101fa4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b29:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b30:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b33:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b3a:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b40:	76 12                	jbe    f0100b54 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b42:	b8 dd 76 10 f0       	mov    $0xf01076dd,%eax
f0100b47:	3d 89 5d 10 f0       	cmp    $0xf0105d89,%eax
f0100b4c:	0f 86 b2 01 00 00    	jbe    f0100d04 <debuginfo_eip+0x204>
f0100b52:	eb 1c                	jmp    f0100b70 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b54:	c7 44 24 08 ae 1f 10 	movl   $0xf0101fae,0x8(%esp)
f0100b5b:	f0 
f0100b5c:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b63:	00 
f0100b64:	c7 04 24 bb 1f 10 f0 	movl   $0xf0101fbb,(%esp)
f0100b6b:	e8 88 f5 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100b70:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b75:	80 3d dc 76 10 f0 00 	cmpb   $0x0,0xf01076dc
f0100b7c:	0f 85 8e 01 00 00    	jne    f0100d10 <debuginfo_eip+0x210>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b82:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b89:	b8 88 5d 10 f0       	mov    $0xf0105d88,%eax
f0100b8e:	2d dc 21 10 f0       	sub    $0xf01021dc,%eax
f0100b93:	c1 f8 02             	sar    $0x2,%eax
f0100b96:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b9c:	83 e8 01             	sub    $0x1,%eax
f0100b9f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100ba2:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ba6:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100bad:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100bb0:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100bb3:	b8 dc 21 10 f0       	mov    $0xf01021dc,%eax
f0100bb8:	e8 63 fe ff ff       	call   f0100a20 <stab_binsearch>
	if (lfile == 0)
f0100bbd:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0100bc0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100bc5:	85 d2                	test   %edx,%edx
f0100bc7:	0f 84 43 01 00 00    	je     f0100d10 <debuginfo_eip+0x210>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100bcd:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100bd0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bd3:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100bd6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bda:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100be1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100be4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100be7:	b8 dc 21 10 f0       	mov    $0xf01021dc,%eax
f0100bec:	e8 2f fe ff ff       	call   f0100a20 <stab_binsearch>

	if (lfun <= rfun) {
f0100bf1:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100bf4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100bf7:	39 d0                	cmp    %edx,%eax
f0100bf9:	7f 3d                	jg     f0100c38 <debuginfo_eip+0x138>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bfb:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100bfe:	8d b9 dc 21 10 f0    	lea    -0xfefde24(%ecx),%edi
f0100c04:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0100c07:	8b 89 dc 21 10 f0    	mov    -0xfefde24(%ecx),%ecx
f0100c0d:	bf dd 76 10 f0       	mov    $0xf01076dd,%edi
f0100c12:	81 ef 89 5d 10 f0    	sub    $0xf0105d89,%edi
f0100c18:	39 f9                	cmp    %edi,%ecx
f0100c1a:	73 09                	jae    f0100c25 <debuginfo_eip+0x125>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c1c:	81 c1 89 5d 10 f0    	add    $0xf0105d89,%ecx
f0100c22:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c25:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100c28:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100c2b:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100c2e:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100c30:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100c33:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100c36:	eb 0f                	jmp    f0100c47 <debuginfo_eip+0x147>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c38:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c3b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c3e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c41:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c44:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c47:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c4e:	00 
f0100c4f:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c52:	89 04 24             	mov    %eax,(%esp)
f0100c55:	e8 ad 08 00 00       	call   f0101507 <strfind>
f0100c5a:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c5d:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100c60:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c64:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100c6b:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c6e:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c71:	b8 dc 21 10 f0       	mov    $0xf01021dc,%eax
f0100c76:	e8 a5 fd ff ff       	call   f0100a20 <stab_binsearch>
	if (lline <= rline)
f0100c7b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
		info->eip_line = stabs[lline].n_desc;
	else
		return -1;
f0100c7e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if (lline <= rline)
f0100c83:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100c86:	0f 8f 84 00 00 00    	jg     f0100d10 <debuginfo_eip+0x210>
		info->eip_line = stabs[lline].n_desc;
f0100c8c:	6b d2 0c             	imul   $0xc,%edx,%edx
f0100c8f:	0f b7 82 e2 21 10 f0 	movzwl -0xfefde1e(%edx),%eax
f0100c96:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c99:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c9c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c9f:	eb 03                	jmp    f0100ca4 <debuginfo_eip+0x1a4>
f0100ca1:	83 e8 01             	sub    $0x1,%eax
f0100ca4:	89 c6                	mov    %eax,%esi
f0100ca6:	39 c7                	cmp    %eax,%edi
f0100ca8:	7f 27                	jg     f0100cd1 <debuginfo_eip+0x1d1>
	       && stabs[lline].n_type != N_SOL
f0100caa:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100cad:	8d 0c 95 dc 21 10 f0 	lea    -0xfefde24(,%edx,4),%ecx
f0100cb4:	0f b6 51 04          	movzbl 0x4(%ecx),%edx
f0100cb8:	80 fa 84             	cmp    $0x84,%dl
f0100cbb:	74 60                	je     f0100d1d <debuginfo_eip+0x21d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100cbd:	80 fa 64             	cmp    $0x64,%dl
f0100cc0:	75 df                	jne    f0100ca1 <debuginfo_eip+0x1a1>
f0100cc2:	83 79 08 00          	cmpl   $0x0,0x8(%ecx)
f0100cc6:	74 d9                	je     f0100ca1 <debuginfo_eip+0x1a1>
f0100cc8:	eb 53                	jmp    f0100d1d <debuginfo_eip+0x21d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100cca:	05 89 5d 10 f0       	add    $0xf0105d89,%eax
f0100ccf:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cd1:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100cd4:	8b 55 d8             	mov    -0x28(%ebp),%edx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cd7:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cdc:	39 d1                	cmp    %edx,%ecx
f0100cde:	7d 30                	jge    f0100d10 <debuginfo_eip+0x210>
		for (lline = lfun + 1;
f0100ce0:	8d 41 01             	lea    0x1(%ecx),%eax
f0100ce3:	eb 04                	jmp    f0100ce9 <debuginfo_eip+0x1e9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100ce5:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100ce9:	39 d0                	cmp    %edx,%eax
f0100ceb:	7d 1e                	jge    f0100d0b <debuginfo_eip+0x20b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100ced:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100cf0:	83 c0 01             	add    $0x1,%eax
f0100cf3:	80 3c 8d e0 21 10 f0 	cmpb   $0xa0,-0xfefde20(,%ecx,4)
f0100cfa:	a0 
f0100cfb:	74 e8                	je     f0100ce5 <debuginfo_eip+0x1e5>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cfd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d02:	eb 0c                	jmp    f0100d10 <debuginfo_eip+0x210>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100d04:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d09:	eb 05                	jmp    f0100d10 <debuginfo_eip+0x210>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d0b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d10:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100d13:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100d16:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100d19:	89 ec                	mov    %ebp,%esp
f0100d1b:	5d                   	pop    %ebp
f0100d1c:	c3                   	ret    
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100d1d:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100d20:	8b 86 dc 21 10 f0    	mov    -0xfefde24(%esi),%eax
f0100d26:	ba dd 76 10 f0       	mov    $0xf01076dd,%edx
f0100d2b:	81 ea 89 5d 10 f0    	sub    $0xf0105d89,%edx
f0100d31:	39 d0                	cmp    %edx,%eax
f0100d33:	72 95                	jb     f0100cca <debuginfo_eip+0x1ca>
f0100d35:	eb 9a                	jmp    f0100cd1 <debuginfo_eip+0x1d1>
	...

f0100d40 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d40:	55                   	push   %ebp
f0100d41:	89 e5                	mov    %esp,%ebp
f0100d43:	57                   	push   %edi
f0100d44:	56                   	push   %esi
f0100d45:	53                   	push   %ebx
f0100d46:	83 ec 3c             	sub    $0x3c,%esp
f0100d49:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d4c:	89 d7                	mov    %edx,%edi
f0100d4e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d51:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100d54:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d57:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d5a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100d5d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d60:	85 c0                	test   %eax,%eax
f0100d62:	75 08                	jne    f0100d6c <printnum+0x2c>
f0100d64:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d67:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100d6a:	77 59                	ja     f0100dc5 <printnum+0x85>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d6c:	89 74 24 10          	mov    %esi,0x10(%esp)
f0100d70:	83 eb 01             	sub    $0x1,%ebx
f0100d73:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100d77:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d7a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d7e:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0100d82:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0100d86:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100d8d:	00 
f0100d8e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d91:	89 04 24             	mov    %eax,(%esp)
f0100d94:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d97:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d9b:	e8 b0 09 00 00       	call   f0101750 <__udivdi3>
f0100da0:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100da4:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100da8:	89 04 24             	mov    %eax,(%esp)
f0100dab:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100daf:	89 fa                	mov    %edi,%edx
f0100db1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100db4:	e8 87 ff ff ff       	call   f0100d40 <printnum>
f0100db9:	eb 11                	jmp    f0100dcc <printnum+0x8c>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100dbb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dbf:	89 34 24             	mov    %esi,(%esp)
f0100dc2:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100dc5:	83 eb 01             	sub    $0x1,%ebx
f0100dc8:	85 db                	test   %ebx,%ebx
f0100dca:	7f ef                	jg     f0100dbb <printnum+0x7b>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100dcc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dd0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100dd4:	8b 45 10             	mov    0x10(%ebp),%eax
f0100dd7:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100ddb:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100de2:	00 
f0100de3:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100de6:	89 04 24             	mov    %eax,(%esp)
f0100de9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100dec:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100df0:	e8 8b 0a 00 00       	call   f0101880 <__umoddi3>
f0100df5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100df9:	0f be 80 c9 1f 10 f0 	movsbl -0xfefe037(%eax),%eax
f0100e00:	89 04 24             	mov    %eax,(%esp)
f0100e03:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100e06:	83 c4 3c             	add    $0x3c,%esp
f0100e09:	5b                   	pop    %ebx
f0100e0a:	5e                   	pop    %esi
f0100e0b:	5f                   	pop    %edi
f0100e0c:	5d                   	pop    %ebp
f0100e0d:	c3                   	ret    

f0100e0e <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e0e:	55                   	push   %ebp
f0100e0f:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e11:	83 fa 01             	cmp    $0x1,%edx
f0100e14:	7e 0e                	jle    f0100e24 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e16:	8b 10                	mov    (%eax),%edx
f0100e18:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e1b:	89 08                	mov    %ecx,(%eax)
f0100e1d:	8b 02                	mov    (%edx),%eax
f0100e1f:	8b 52 04             	mov    0x4(%edx),%edx
f0100e22:	eb 22                	jmp    f0100e46 <getuint+0x38>
	else if (lflag)
f0100e24:	85 d2                	test   %edx,%edx
f0100e26:	74 10                	je     f0100e38 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e28:	8b 10                	mov    (%eax),%edx
f0100e2a:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e2d:	89 08                	mov    %ecx,(%eax)
f0100e2f:	8b 02                	mov    (%edx),%eax
f0100e31:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e36:	eb 0e                	jmp    f0100e46 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e38:	8b 10                	mov    (%eax),%edx
f0100e3a:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e3d:	89 08                	mov    %ecx,(%eax)
f0100e3f:	8b 02                	mov    (%edx),%eax
f0100e41:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e46:	5d                   	pop    %ebp
f0100e47:	c3                   	ret    

f0100e48 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e48:	55                   	push   %ebp
f0100e49:	89 e5                	mov    %esp,%ebp
f0100e4b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e4e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e52:	8b 10                	mov    (%eax),%edx
f0100e54:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e57:	73 0a                	jae    f0100e63 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e59:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100e5c:	88 0a                	mov    %cl,(%edx)
f0100e5e:	83 c2 01             	add    $0x1,%edx
f0100e61:	89 10                	mov    %edx,(%eax)
}
f0100e63:	5d                   	pop    %ebp
f0100e64:	c3                   	ret    

f0100e65 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e65:	55                   	push   %ebp
f0100e66:	89 e5                	mov    %esp,%ebp
f0100e68:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e6b:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e6e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e72:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e75:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e79:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e7c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e80:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e83:	89 04 24             	mov    %eax,(%esp)
f0100e86:	e8 02 00 00 00       	call   f0100e8d <vprintfmt>
	va_end(ap);
}
f0100e8b:	c9                   	leave  
f0100e8c:	c3                   	ret    

f0100e8d <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100e8d:	55                   	push   %ebp
f0100e8e:	89 e5                	mov    %esp,%ebp
f0100e90:	57                   	push   %edi
f0100e91:	56                   	push   %esi
f0100e92:	53                   	push   %ebx
f0100e93:	83 ec 4c             	sub    $0x4c,%esp
f0100e96:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100e99:	8b 75 10             	mov    0x10(%ebp),%esi
f0100e9c:	eb 12                	jmp    f0100eb0 <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100e9e:	85 c0                	test   %eax,%eax
f0100ea0:	0f 84 9f 03 00 00    	je     f0101245 <vprintfmt+0x3b8>
				return;
			putch(ch, putdat);
f0100ea6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100eaa:	89 04 24             	mov    %eax,(%esp)
f0100ead:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100eb0:	0f b6 06             	movzbl (%esi),%eax
f0100eb3:	83 c6 01             	add    $0x1,%esi
f0100eb6:	83 f8 25             	cmp    $0x25,%eax
f0100eb9:	75 e3                	jne    f0100e9e <vprintfmt+0x11>
f0100ebb:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100ebf:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100ec6:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0100ecb:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100ed2:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100ed7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100eda:	eb 2b                	jmp    f0100f07 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100edc:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100edf:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100ee3:	eb 22                	jmp    f0100f07 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ee5:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100ee8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100eec:	eb 19                	jmp    f0100f07 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eee:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100ef1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100ef8:	eb 0d                	jmp    f0100f07 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100efa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100efd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f00:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f07:	0f b6 16             	movzbl (%esi),%edx
f0100f0a:	0f b6 c2             	movzbl %dl,%eax
f0100f0d:	8d 7e 01             	lea    0x1(%esi),%edi
f0100f10:	89 7d e0             	mov    %edi,-0x20(%ebp)
f0100f13:	83 ea 23             	sub    $0x23,%edx
f0100f16:	80 fa 55             	cmp    $0x55,%dl
f0100f19:	0f 87 08 03 00 00    	ja     f0101227 <vprintfmt+0x39a>
f0100f1f:	0f b6 d2             	movzbl %dl,%edx
f0100f22:	ff 24 95 58 20 10 f0 	jmp    *-0xfefdfa8(,%edx,4)
f0100f29:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100f2c:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f0100f33:	bf 00 00 00 00       	mov    $0x0,%edi
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f38:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f0100f3b:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0100f3f:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100f42:	8d 50 d0             	lea    -0x30(%eax),%edx
f0100f45:	83 fa 09             	cmp    $0x9,%edx
f0100f48:	77 2f                	ja     f0100f79 <vprintfmt+0xec>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f4a:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100f4d:	eb e9                	jmp    f0100f38 <vprintfmt+0xab>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f4f:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f52:	8d 50 04             	lea    0x4(%eax),%edx
f0100f55:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f58:	8b 00                	mov    (%eax),%eax
f0100f5a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f5d:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f60:	eb 1a                	jmp    f0100f7c <vprintfmt+0xef>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f62:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f0100f65:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100f69:	79 9c                	jns    f0100f07 <vprintfmt+0x7a>
f0100f6b:	eb 81                	jmp    f0100eee <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f6d:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f70:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0100f77:	eb 8e                	jmp    f0100f07 <vprintfmt+0x7a>
f0100f79:	89 7d d4             	mov    %edi,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f0100f7c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100f80:	79 85                	jns    f0100f07 <vprintfmt+0x7a>
f0100f82:	e9 73 ff ff ff       	jmp    f0100efa <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100f87:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f8a:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100f8d:	e9 75 ff ff ff       	jmp    f0100f07 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100f92:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f95:	8d 50 04             	lea    0x4(%eax),%edx
f0100f98:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f9b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f9f:	8b 00                	mov    (%eax),%eax
f0100fa1:	89 04 24             	mov    %eax,(%esp)
f0100fa4:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fa7:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100faa:	e9 01 ff ff ff       	jmp    f0100eb0 <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100faf:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fb2:	8d 50 04             	lea    0x4(%eax),%edx
f0100fb5:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fb8:	8b 00                	mov    (%eax),%eax
f0100fba:	89 c2                	mov    %eax,%edx
f0100fbc:	c1 fa 1f             	sar    $0x1f,%edx
f0100fbf:	31 d0                	xor    %edx,%eax
f0100fc1:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100fc3:	83 f8 06             	cmp    $0x6,%eax
f0100fc6:	7f 0b                	jg     f0100fd3 <vprintfmt+0x146>
f0100fc8:	8b 14 85 b0 21 10 f0 	mov    -0xfefde50(,%eax,4),%edx
f0100fcf:	85 d2                	test   %edx,%edx
f0100fd1:	75 23                	jne    f0100ff6 <vprintfmt+0x169>
				printfmt(putch, putdat, "error %d", err);
f0100fd3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fd7:	c7 44 24 08 e1 1f 10 	movl   $0xf0101fe1,0x8(%esp)
f0100fde:	f0 
f0100fdf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fe3:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100fe6:	89 3c 24             	mov    %edi,(%esp)
f0100fe9:	e8 77 fe ff ff       	call   f0100e65 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fee:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100ff1:	e9 ba fe ff ff       	jmp    f0100eb0 <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0100ff6:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100ffa:	c7 44 24 08 ea 1f 10 	movl   $0xf0101fea,0x8(%esp)
f0101001:	f0 
f0101002:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101006:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101009:	89 3c 24             	mov    %edi,(%esp)
f010100c:	e8 54 fe ff ff       	call   f0100e65 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101011:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101014:	e9 97 fe ff ff       	jmp    f0100eb0 <vprintfmt+0x23>
f0101019:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010101c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010101f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101022:	8b 45 14             	mov    0x14(%ebp),%eax
f0101025:	8d 50 04             	lea    0x4(%eax),%edx
f0101028:	89 55 14             	mov    %edx,0x14(%ebp)
f010102b:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010102d:	85 f6                	test   %esi,%esi
f010102f:	ba da 1f 10 f0       	mov    $0xf0101fda,%edx
f0101034:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f0101037:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f010103b:	0f 8e 8c 00 00 00    	jle    f01010cd <vprintfmt+0x240>
f0101041:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0101045:	0f 84 82 00 00 00    	je     f01010cd <vprintfmt+0x240>
				for (width -= strnlen(p, precision); width > 0; width--)
f010104b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010104f:	89 34 24             	mov    %esi,(%esp)
f0101052:	e8 61 03 00 00       	call   f01013b8 <strnlen>
f0101057:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010105a:	29 c2                	sub    %eax,%edx
f010105c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
					putch(padc, putdat);
f010105f:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0101063:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0101066:	89 7d cc             	mov    %edi,-0x34(%ebp)
f0101069:	89 de                	mov    %ebx,%esi
f010106b:	89 d3                	mov    %edx,%ebx
f010106d:	89 c7                	mov    %eax,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010106f:	eb 0d                	jmp    f010107e <vprintfmt+0x1f1>
					putch(padc, putdat);
f0101071:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101075:	89 3c 24             	mov    %edi,(%esp)
f0101078:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010107b:	83 eb 01             	sub    $0x1,%ebx
f010107e:	85 db                	test   %ebx,%ebx
f0101080:	7f ef                	jg     f0101071 <vprintfmt+0x1e4>
f0101082:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0101085:	89 f3                	mov    %esi,%ebx
f0101087:	8b 75 d0             	mov    -0x30(%ebp),%esi

// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
f010108a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010108e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101093:	0f 49 45 e4          	cmovns -0x1c(%ebp),%eax
f0101097:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010109a:	29 c2                	sub    %eax,%edx
f010109c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010109f:	eb 2c                	jmp    f01010cd <vprintfmt+0x240>
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01010a1:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01010a5:	74 18                	je     f01010bf <vprintfmt+0x232>
f01010a7:	8d 50 e0             	lea    -0x20(%eax),%edx
f01010aa:	83 fa 5e             	cmp    $0x5e,%edx
f01010ad:	76 10                	jbe    f01010bf <vprintfmt+0x232>
					putch('?', putdat);
f01010af:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010b3:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01010ba:	ff 55 08             	call   *0x8(%ebp)
f01010bd:	eb 0a                	jmp    f01010c9 <vprintfmt+0x23c>
				else
					putch(ch, putdat);
f01010bf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010c3:	89 04 24             	mov    %eax,(%esp)
f01010c6:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010c9:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f01010cd:	0f be 06             	movsbl (%esi),%eax
f01010d0:	83 c6 01             	add    $0x1,%esi
f01010d3:	85 c0                	test   %eax,%eax
f01010d5:	74 25                	je     f01010fc <vprintfmt+0x26f>
f01010d7:	85 ff                	test   %edi,%edi
f01010d9:	78 c6                	js     f01010a1 <vprintfmt+0x214>
f01010db:	83 ef 01             	sub    $0x1,%edi
f01010de:	79 c1                	jns    f01010a1 <vprintfmt+0x214>
f01010e0:	8b 7d 08             	mov    0x8(%ebp),%edi
f01010e3:	89 de                	mov    %ebx,%esi
f01010e5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01010e8:	eb 1a                	jmp    f0101104 <vprintfmt+0x277>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01010ea:	89 74 24 04          	mov    %esi,0x4(%esp)
f01010ee:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01010f5:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01010f7:	83 eb 01             	sub    $0x1,%ebx
f01010fa:	eb 08                	jmp    f0101104 <vprintfmt+0x277>
f01010fc:	8b 7d 08             	mov    0x8(%ebp),%edi
f01010ff:	89 de                	mov    %ebx,%esi
f0101101:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101104:	85 db                	test   %ebx,%ebx
f0101106:	7f e2                	jg     f01010ea <vprintfmt+0x25d>
f0101108:	89 7d 08             	mov    %edi,0x8(%ebp)
f010110b:	89 f3                	mov    %esi,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010110d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101110:	e9 9b fd ff ff       	jmp    f0100eb0 <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101115:	83 f9 01             	cmp    $0x1,%ecx
f0101118:	7e 10                	jle    f010112a <vprintfmt+0x29d>
		return va_arg(*ap, long long);
f010111a:	8b 45 14             	mov    0x14(%ebp),%eax
f010111d:	8d 50 08             	lea    0x8(%eax),%edx
f0101120:	89 55 14             	mov    %edx,0x14(%ebp)
f0101123:	8b 30                	mov    (%eax),%esi
f0101125:	8b 78 04             	mov    0x4(%eax),%edi
f0101128:	eb 26                	jmp    f0101150 <vprintfmt+0x2c3>
	else if (lflag)
f010112a:	85 c9                	test   %ecx,%ecx
f010112c:	74 12                	je     f0101140 <vprintfmt+0x2b3>
		return va_arg(*ap, long);
f010112e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101131:	8d 50 04             	lea    0x4(%eax),%edx
f0101134:	89 55 14             	mov    %edx,0x14(%ebp)
f0101137:	8b 30                	mov    (%eax),%esi
f0101139:	89 f7                	mov    %esi,%edi
f010113b:	c1 ff 1f             	sar    $0x1f,%edi
f010113e:	eb 10                	jmp    f0101150 <vprintfmt+0x2c3>
	else
		return va_arg(*ap, int);
f0101140:	8b 45 14             	mov    0x14(%ebp),%eax
f0101143:	8d 50 04             	lea    0x4(%eax),%edx
f0101146:	89 55 14             	mov    %edx,0x14(%ebp)
f0101149:	8b 30                	mov    (%eax),%esi
f010114b:	89 f7                	mov    %esi,%edi
f010114d:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101150:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101155:	85 ff                	test   %edi,%edi
f0101157:	0f 89 8c 00 00 00    	jns    f01011e9 <vprintfmt+0x35c>
				putch('-', putdat);
f010115d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101161:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101168:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010116b:	f7 de                	neg    %esi
f010116d:	83 d7 00             	adc    $0x0,%edi
f0101170:	f7 df                	neg    %edi
			}
			base = 10;
f0101172:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101177:	eb 70                	jmp    f01011e9 <vprintfmt+0x35c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101179:	89 ca                	mov    %ecx,%edx
f010117b:	8d 45 14             	lea    0x14(%ebp),%eax
f010117e:	e8 8b fc ff ff       	call   f0100e0e <getuint>
f0101183:	89 c6                	mov    %eax,%esi
f0101185:	89 d7                	mov    %edx,%edi
			base = 10;
f0101187:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010118c:	eb 5b                	jmp    f01011e9 <vprintfmt+0x35c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num=getuint(&ap,lflag);
f010118e:	89 ca                	mov    %ecx,%edx
f0101190:	8d 45 14             	lea    0x14(%ebp),%eax
f0101193:	e8 76 fc ff ff       	call   f0100e0e <getuint>
f0101198:	89 c6                	mov    %eax,%esi
f010119a:	89 d7                	mov    %edx,%edi
			base = 8;
f010119c:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f01011a1:	eb 46                	jmp    f01011e9 <vprintfmt+0x35c>
	
		// pointer
		case 'p':
			putch('0', putdat);
f01011a3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011a7:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01011ae:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01011b1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011b5:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01011bc:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01011bf:	8b 45 14             	mov    0x14(%ebp),%eax
f01011c2:	8d 50 04             	lea    0x4(%eax),%edx
f01011c5:	89 55 14             	mov    %edx,0x14(%ebp)
	
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01011c8:	8b 30                	mov    (%eax),%esi
f01011ca:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01011cf:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01011d4:	eb 13                	jmp    f01011e9 <vprintfmt+0x35c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01011d6:	89 ca                	mov    %ecx,%edx
f01011d8:	8d 45 14             	lea    0x14(%ebp),%eax
f01011db:	e8 2e fc ff ff       	call   f0100e0e <getuint>
f01011e0:	89 c6                	mov    %eax,%esi
f01011e2:	89 d7                	mov    %edx,%edi
			base = 16;
f01011e4:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01011e9:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f01011ed:	89 54 24 10          	mov    %edx,0x10(%esp)
f01011f1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01011f4:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01011f8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011fc:	89 34 24             	mov    %esi,(%esp)
f01011ff:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101203:	89 da                	mov    %ebx,%edx
f0101205:	8b 45 08             	mov    0x8(%ebp),%eax
f0101208:	e8 33 fb ff ff       	call   f0100d40 <printnum>
			break;
f010120d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101210:	e9 9b fc ff ff       	jmp    f0100eb0 <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101215:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101219:	89 04 24             	mov    %eax,(%esp)
f010121c:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010121f:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101222:	e9 89 fc ff ff       	jmp    f0100eb0 <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101227:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010122b:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101232:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101235:	eb 03                	jmp    f010123a <vprintfmt+0x3ad>
f0101237:	83 ee 01             	sub    $0x1,%esi
f010123a:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f010123e:	75 f7                	jne    f0101237 <vprintfmt+0x3aa>
f0101240:	e9 6b fc ff ff       	jmp    f0100eb0 <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f0101245:	83 c4 4c             	add    $0x4c,%esp
f0101248:	5b                   	pop    %ebx
f0101249:	5e                   	pop    %esi
f010124a:	5f                   	pop    %edi
f010124b:	5d                   	pop    %ebp
f010124c:	c3                   	ret    

f010124d <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010124d:	55                   	push   %ebp
f010124e:	89 e5                	mov    %esp,%ebp
f0101250:	83 ec 28             	sub    $0x28,%esp
f0101253:	8b 45 08             	mov    0x8(%ebp),%eax
f0101256:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101259:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010125c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101260:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101263:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010126a:	85 c0                	test   %eax,%eax
f010126c:	74 30                	je     f010129e <vsnprintf+0x51>
f010126e:	85 d2                	test   %edx,%edx
f0101270:	7e 2c                	jle    f010129e <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101272:	8b 45 14             	mov    0x14(%ebp),%eax
f0101275:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101279:	8b 45 10             	mov    0x10(%ebp),%eax
f010127c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101280:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101283:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101287:	c7 04 24 48 0e 10 f0 	movl   $0xf0100e48,(%esp)
f010128e:	e8 fa fb ff ff       	call   f0100e8d <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101293:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101296:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101299:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010129c:	eb 05                	jmp    f01012a3 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010129e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01012a3:	c9                   	leave  
f01012a4:	c3                   	ret    

f01012a5 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01012a5:	55                   	push   %ebp
f01012a6:	89 e5                	mov    %esp,%ebp
f01012a8:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01012ab:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01012ae:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012b2:	8b 45 10             	mov    0x10(%ebp),%eax
f01012b5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012b9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012bc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012c0:	8b 45 08             	mov    0x8(%ebp),%eax
f01012c3:	89 04 24             	mov    %eax,(%esp)
f01012c6:	e8 82 ff ff ff       	call   f010124d <vsnprintf>
	va_end(ap);

	return rc;
}
f01012cb:	c9                   	leave  
f01012cc:	c3                   	ret    
f01012cd:	00 00                	add    %al,(%eax)
	...

f01012d0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01012d0:	55                   	push   %ebp
f01012d1:	89 e5                	mov    %esp,%ebp
f01012d3:	57                   	push   %edi
f01012d4:	56                   	push   %esi
f01012d5:	53                   	push   %ebx
f01012d6:	83 ec 1c             	sub    $0x1c,%esp
f01012d9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01012dc:	85 c0                	test   %eax,%eax
f01012de:	74 10                	je     f01012f0 <readline+0x20>
		cprintf("%s", prompt);
f01012e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012e4:	c7 04 24 ea 1f 10 f0 	movl   $0xf0101fea,(%esp)
f01012eb:	e8 16 f7 ff ff       	call   f0100a06 <cprintf>

	i = 0;
	echoing = iscons(0);
f01012f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012f7:	e8 71 f3 ff ff       	call   f010066d <iscons>
f01012fc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01012fe:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101303:	e8 54 f3 ff ff       	call   f010065c <getchar>
f0101308:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010130a:	85 c0                	test   %eax,%eax
f010130c:	79 17                	jns    f0101325 <readline+0x55>
			cprintf("read error: %e\n", c);
f010130e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101312:	c7 04 24 cc 21 10 f0 	movl   $0xf01021cc,(%esp)
f0101319:	e8 e8 f6 ff ff       	call   f0100a06 <cprintf>
			return NULL;
f010131e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101323:	eb 6d                	jmp    f0101392 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101325:	83 f8 08             	cmp    $0x8,%eax
f0101328:	74 05                	je     f010132f <readline+0x5f>
f010132a:	83 f8 7f             	cmp    $0x7f,%eax
f010132d:	75 19                	jne    f0101348 <readline+0x78>
f010132f:	85 f6                	test   %esi,%esi
f0101331:	7e 15                	jle    f0101348 <readline+0x78>
			if (echoing)
f0101333:	85 ff                	test   %edi,%edi
f0101335:	74 0c                	je     f0101343 <readline+0x73>
				cputchar('\b');
f0101337:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010133e:	e8 09 f3 ff ff       	call   f010064c <cputchar>
			i--;
f0101343:	83 ee 01             	sub    $0x1,%esi
f0101346:	eb bb                	jmp    f0101303 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101348:	83 fb 1f             	cmp    $0x1f,%ebx
f010134b:	7e 1f                	jle    f010136c <readline+0x9c>
f010134d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101353:	7f 17                	jg     f010136c <readline+0x9c>
			if (echoing)
f0101355:	85 ff                	test   %edi,%edi
f0101357:	74 08                	je     f0101361 <readline+0x91>
				cputchar(c);
f0101359:	89 1c 24             	mov    %ebx,(%esp)
f010135c:	e8 eb f2 ff ff       	call   f010064c <cputchar>
			buf[i++] = c;
f0101361:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101367:	83 c6 01             	add    $0x1,%esi
f010136a:	eb 97                	jmp    f0101303 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010136c:	83 fb 0a             	cmp    $0xa,%ebx
f010136f:	74 05                	je     f0101376 <readline+0xa6>
f0101371:	83 fb 0d             	cmp    $0xd,%ebx
f0101374:	75 8d                	jne    f0101303 <readline+0x33>
			if (echoing)
f0101376:	85 ff                	test   %edi,%edi
f0101378:	74 0c                	je     f0101386 <readline+0xb6>
				cputchar('\n');
f010137a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101381:	e8 c6 f2 ff ff       	call   f010064c <cputchar>
			buf[i] = 0;
f0101386:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010138d:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101392:	83 c4 1c             	add    $0x1c,%esp
f0101395:	5b                   	pop    %ebx
f0101396:	5e                   	pop    %esi
f0101397:	5f                   	pop    %edi
f0101398:	5d                   	pop    %ebp
f0101399:	c3                   	ret    
f010139a:	00 00                	add    %al,(%eax)
f010139c:	00 00                	add    %al,(%eax)
	...

f01013a0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01013a0:	55                   	push   %ebp
f01013a1:	89 e5                	mov    %esp,%ebp
f01013a3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01013a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01013ab:	eb 03                	jmp    f01013b0 <strlen+0x10>
		n++;
f01013ad:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01013b0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01013b4:	75 f7                	jne    f01013ad <strlen+0xd>
		n++;
	return n;
}
f01013b6:	5d                   	pop    %ebp
f01013b7:	c3                   	ret    

f01013b8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01013b8:	55                   	push   %ebp
f01013b9:	89 e5                	mov    %esp,%ebp
f01013bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
		n++;
	return n;
}

int
strnlen(const char *s, size_t size)
f01013be:	8b 55 0c             	mov    0xc(%ebp),%edx
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013c1:	b8 00 00 00 00       	mov    $0x0,%eax
f01013c6:	eb 03                	jmp    f01013cb <strnlen+0x13>
		n++;
f01013c8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013cb:	39 d0                	cmp    %edx,%eax
f01013cd:	74 06                	je     f01013d5 <strnlen+0x1d>
f01013cf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01013d3:	75 f3                	jne    f01013c8 <strnlen+0x10>
		n++;
	return n;
}
f01013d5:	5d                   	pop    %ebp
f01013d6:	c3                   	ret    

f01013d7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01013d7:	55                   	push   %ebp
f01013d8:	89 e5                	mov    %esp,%ebp
f01013da:	53                   	push   %ebx
f01013db:	8b 45 08             	mov    0x8(%ebp),%eax
f01013de:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01013e1:	ba 00 00 00 00       	mov    $0x0,%edx
f01013e6:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01013ea:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01013ed:	83 c2 01             	add    $0x1,%edx
f01013f0:	84 c9                	test   %cl,%cl
f01013f2:	75 f2                	jne    f01013e6 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01013f4:	5b                   	pop    %ebx
f01013f5:	5d                   	pop    %ebp
f01013f6:	c3                   	ret    

f01013f7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01013f7:	55                   	push   %ebp
f01013f8:	89 e5                	mov    %esp,%ebp
f01013fa:	53                   	push   %ebx
f01013fb:	83 ec 08             	sub    $0x8,%esp
f01013fe:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101401:	89 1c 24             	mov    %ebx,(%esp)
f0101404:	e8 97 ff ff ff       	call   f01013a0 <strlen>
	strcpy(dst + len, src);
f0101409:	8b 55 0c             	mov    0xc(%ebp),%edx
f010140c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101410:	01 d8                	add    %ebx,%eax
f0101412:	89 04 24             	mov    %eax,(%esp)
f0101415:	e8 bd ff ff ff       	call   f01013d7 <strcpy>
	return dst;
}
f010141a:	89 d8                	mov    %ebx,%eax
f010141c:	83 c4 08             	add    $0x8,%esp
f010141f:	5b                   	pop    %ebx
f0101420:	5d                   	pop    %ebp
f0101421:	c3                   	ret    

f0101422 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101422:	55                   	push   %ebp
f0101423:	89 e5                	mov    %esp,%ebp
f0101425:	56                   	push   %esi
f0101426:	53                   	push   %ebx
f0101427:	8b 45 08             	mov    0x8(%ebp),%eax
f010142a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010142d:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101430:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101435:	eb 0f                	jmp    f0101446 <strncpy+0x24>
		*dst++ = *src;
f0101437:	0f b6 1a             	movzbl (%edx),%ebx
f010143a:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010143d:	80 3a 01             	cmpb   $0x1,(%edx)
f0101440:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101443:	83 c1 01             	add    $0x1,%ecx
f0101446:	39 f1                	cmp    %esi,%ecx
f0101448:	75 ed                	jne    f0101437 <strncpy+0x15>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010144a:	5b                   	pop    %ebx
f010144b:	5e                   	pop    %esi
f010144c:	5d                   	pop    %ebp
f010144d:	c3                   	ret    

f010144e <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010144e:	55                   	push   %ebp
f010144f:	89 e5                	mov    %esp,%ebp
f0101451:	56                   	push   %esi
f0101452:	53                   	push   %ebx
f0101453:	8b 75 08             	mov    0x8(%ebp),%esi
f0101456:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101459:	8b 55 10             	mov    0x10(%ebp),%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010145c:	89 f0                	mov    %esi,%eax
f010145e:	85 d2                	test   %edx,%edx
f0101460:	75 0a                	jne    f010146c <strlcpy+0x1e>
f0101462:	eb 1d                	jmp    f0101481 <strlcpy+0x33>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101464:	88 18                	mov    %bl,(%eax)
f0101466:	83 c0 01             	add    $0x1,%eax
f0101469:	83 c1 01             	add    $0x1,%ecx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010146c:	83 ea 01             	sub    $0x1,%edx
f010146f:	74 0b                	je     f010147c <strlcpy+0x2e>
f0101471:	0f b6 19             	movzbl (%ecx),%ebx
f0101474:	84 db                	test   %bl,%bl
f0101476:	75 ec                	jne    f0101464 <strlcpy+0x16>
f0101478:	89 c2                	mov    %eax,%edx
f010147a:	eb 02                	jmp    f010147e <strlcpy+0x30>
f010147c:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f010147e:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0101481:	29 f0                	sub    %esi,%eax
}
f0101483:	5b                   	pop    %ebx
f0101484:	5e                   	pop    %esi
f0101485:	5d                   	pop    %ebp
f0101486:	c3                   	ret    

f0101487 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101487:	55                   	push   %ebp
f0101488:	89 e5                	mov    %esp,%ebp
f010148a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010148d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101490:	eb 06                	jmp    f0101498 <strcmp+0x11>
		p++, q++;
f0101492:	83 c1 01             	add    $0x1,%ecx
f0101495:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101498:	0f b6 01             	movzbl (%ecx),%eax
f010149b:	84 c0                	test   %al,%al
f010149d:	74 04                	je     f01014a3 <strcmp+0x1c>
f010149f:	3a 02                	cmp    (%edx),%al
f01014a1:	74 ef                	je     f0101492 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01014a3:	0f b6 c0             	movzbl %al,%eax
f01014a6:	0f b6 12             	movzbl (%edx),%edx
f01014a9:	29 d0                	sub    %edx,%eax
}
f01014ab:	5d                   	pop    %ebp
f01014ac:	c3                   	ret    

f01014ad <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01014ad:	55                   	push   %ebp
f01014ae:	89 e5                	mov    %esp,%ebp
f01014b0:	53                   	push   %ebx
f01014b1:	8b 45 08             	mov    0x8(%ebp),%eax
f01014b4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01014b7:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
f01014ba:	eb 09                	jmp    f01014c5 <strncmp+0x18>
		n--, p++, q++;
f01014bc:	83 ea 01             	sub    $0x1,%edx
f01014bf:	83 c0 01             	add    $0x1,%eax
f01014c2:	83 c1 01             	add    $0x1,%ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01014c5:	85 d2                	test   %edx,%edx
f01014c7:	74 15                	je     f01014de <strncmp+0x31>
f01014c9:	0f b6 18             	movzbl (%eax),%ebx
f01014cc:	84 db                	test   %bl,%bl
f01014ce:	74 04                	je     f01014d4 <strncmp+0x27>
f01014d0:	3a 19                	cmp    (%ecx),%bl
f01014d2:	74 e8                	je     f01014bc <strncmp+0xf>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01014d4:	0f b6 00             	movzbl (%eax),%eax
f01014d7:	0f b6 11             	movzbl (%ecx),%edx
f01014da:	29 d0                	sub    %edx,%eax
f01014dc:	eb 05                	jmp    f01014e3 <strncmp+0x36>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01014de:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01014e3:	5b                   	pop    %ebx
f01014e4:	5d                   	pop    %ebp
f01014e5:	c3                   	ret    

f01014e6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01014e6:	55                   	push   %ebp
f01014e7:	89 e5                	mov    %esp,%ebp
f01014e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01014ec:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01014f0:	eb 07                	jmp    f01014f9 <strchr+0x13>
		if (*s == c)
f01014f2:	38 ca                	cmp    %cl,%dl
f01014f4:	74 0f                	je     f0101505 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01014f6:	83 c0 01             	add    $0x1,%eax
f01014f9:	0f b6 10             	movzbl (%eax),%edx
f01014fc:	84 d2                	test   %dl,%dl
f01014fe:	75 f2                	jne    f01014f2 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101500:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101505:	5d                   	pop    %ebp
f0101506:	c3                   	ret    

f0101507 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101507:	55                   	push   %ebp
f0101508:	89 e5                	mov    %esp,%ebp
f010150a:	8b 45 08             	mov    0x8(%ebp),%eax
f010150d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101511:	eb 07                	jmp    f010151a <strfind+0x13>
		if (*s == c)
f0101513:	38 ca                	cmp    %cl,%dl
f0101515:	74 0a                	je     f0101521 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101517:	83 c0 01             	add    $0x1,%eax
f010151a:	0f b6 10             	movzbl (%eax),%edx
f010151d:	84 d2                	test   %dl,%dl
f010151f:	75 f2                	jne    f0101513 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0101521:	5d                   	pop    %ebp
f0101522:	c3                   	ret    

f0101523 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101523:	55                   	push   %ebp
f0101524:	89 e5                	mov    %esp,%ebp
f0101526:	83 ec 0c             	sub    $0xc,%esp
f0101529:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010152c:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010152f:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101532:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101535:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101538:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010153b:	85 c9                	test   %ecx,%ecx
f010153d:	74 30                	je     f010156f <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010153f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101545:	75 25                	jne    f010156c <memset+0x49>
f0101547:	f6 c1 03             	test   $0x3,%cl
f010154a:	75 20                	jne    f010156c <memset+0x49>
		c &= 0xFF;
f010154c:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010154f:	89 d3                	mov    %edx,%ebx
f0101551:	c1 e3 08             	shl    $0x8,%ebx
f0101554:	89 d6                	mov    %edx,%esi
f0101556:	c1 e6 18             	shl    $0x18,%esi
f0101559:	89 d0                	mov    %edx,%eax
f010155b:	c1 e0 10             	shl    $0x10,%eax
f010155e:	09 f0                	or     %esi,%eax
f0101560:	09 d0                	or     %edx,%eax
f0101562:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101564:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101567:	fc                   	cld    
f0101568:	f3 ab                	rep stos %eax,%es:(%edi)
f010156a:	eb 03                	jmp    f010156f <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010156c:	fc                   	cld    
f010156d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010156f:	89 f8                	mov    %edi,%eax
f0101571:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101574:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101577:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010157a:	89 ec                	mov    %ebp,%esp
f010157c:	5d                   	pop    %ebp
f010157d:	c3                   	ret    

f010157e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010157e:	55                   	push   %ebp
f010157f:	89 e5                	mov    %esp,%ebp
f0101581:	83 ec 08             	sub    $0x8,%esp
f0101584:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101587:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010158a:	8b 45 08             	mov    0x8(%ebp),%eax
f010158d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101590:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101593:	39 c6                	cmp    %eax,%esi
f0101595:	73 36                	jae    f01015cd <memmove+0x4f>
f0101597:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010159a:	39 d0                	cmp    %edx,%eax
f010159c:	73 2f                	jae    f01015cd <memmove+0x4f>
		s += n;
		d += n;
f010159e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015a1:	f6 c2 03             	test   $0x3,%dl
f01015a4:	75 1b                	jne    f01015c1 <memmove+0x43>
f01015a6:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015ac:	75 13                	jne    f01015c1 <memmove+0x43>
f01015ae:	f6 c1 03             	test   $0x3,%cl
f01015b1:	75 0e                	jne    f01015c1 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01015b3:	83 ef 04             	sub    $0x4,%edi
f01015b6:	8d 72 fc             	lea    -0x4(%edx),%esi
f01015b9:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01015bc:	fd                   	std    
f01015bd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015bf:	eb 09                	jmp    f01015ca <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01015c1:	83 ef 01             	sub    $0x1,%edi
f01015c4:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01015c7:	fd                   	std    
f01015c8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01015ca:	fc                   	cld    
f01015cb:	eb 20                	jmp    f01015ed <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015cd:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01015d3:	75 13                	jne    f01015e8 <memmove+0x6a>
f01015d5:	a8 03                	test   $0x3,%al
f01015d7:	75 0f                	jne    f01015e8 <memmove+0x6a>
f01015d9:	f6 c1 03             	test   $0x3,%cl
f01015dc:	75 0a                	jne    f01015e8 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01015de:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01015e1:	89 c7                	mov    %eax,%edi
f01015e3:	fc                   	cld    
f01015e4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015e6:	eb 05                	jmp    f01015ed <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01015e8:	89 c7                	mov    %eax,%edi
f01015ea:	fc                   	cld    
f01015eb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01015ed:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01015f0:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01015f3:	89 ec                	mov    %ebp,%esp
f01015f5:	5d                   	pop    %ebp
f01015f6:	c3                   	ret    

f01015f7 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01015f7:	55                   	push   %ebp
f01015f8:	89 e5                	mov    %esp,%ebp
f01015fa:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01015fd:	8b 45 10             	mov    0x10(%ebp),%eax
f0101600:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101604:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101607:	89 44 24 04          	mov    %eax,0x4(%esp)
f010160b:	8b 45 08             	mov    0x8(%ebp),%eax
f010160e:	89 04 24             	mov    %eax,(%esp)
f0101611:	e8 68 ff ff ff       	call   f010157e <memmove>
}
f0101616:	c9                   	leave  
f0101617:	c3                   	ret    

f0101618 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101618:	55                   	push   %ebp
f0101619:	89 e5                	mov    %esp,%ebp
f010161b:	57                   	push   %edi
f010161c:	56                   	push   %esi
f010161d:	53                   	push   %ebx
f010161e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101621:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101624:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101627:	ba 00 00 00 00       	mov    $0x0,%edx
f010162c:	eb 1a                	jmp    f0101648 <memcmp+0x30>
		if (*s1 != *s2)
f010162e:	0f b6 04 17          	movzbl (%edi,%edx,1),%eax
f0101632:	83 c2 01             	add    $0x1,%edx
f0101635:	0f b6 4c 16 ff       	movzbl -0x1(%esi,%edx,1),%ecx
f010163a:	38 c8                	cmp    %cl,%al
f010163c:	74 0a                	je     f0101648 <memcmp+0x30>
			return (int) *s1 - (int) *s2;
f010163e:	0f b6 c0             	movzbl %al,%eax
f0101641:	0f b6 c9             	movzbl %cl,%ecx
f0101644:	29 c8                	sub    %ecx,%eax
f0101646:	eb 09                	jmp    f0101651 <memcmp+0x39>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101648:	39 da                	cmp    %ebx,%edx
f010164a:	75 e2                	jne    f010162e <memcmp+0x16>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010164c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101651:	5b                   	pop    %ebx
f0101652:	5e                   	pop    %esi
f0101653:	5f                   	pop    %edi
f0101654:	5d                   	pop    %ebp
f0101655:	c3                   	ret    

f0101656 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101656:	55                   	push   %ebp
f0101657:	89 e5                	mov    %esp,%ebp
f0101659:	8b 45 08             	mov    0x8(%ebp),%eax
f010165c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010165f:	89 c2                	mov    %eax,%edx
f0101661:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101664:	eb 07                	jmp    f010166d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101666:	38 08                	cmp    %cl,(%eax)
f0101668:	74 07                	je     f0101671 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010166a:	83 c0 01             	add    $0x1,%eax
f010166d:	39 d0                	cmp    %edx,%eax
f010166f:	72 f5                	jb     f0101666 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101671:	5d                   	pop    %ebp
f0101672:	c3                   	ret    

f0101673 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101673:	55                   	push   %ebp
f0101674:	89 e5                	mov    %esp,%ebp
f0101676:	57                   	push   %edi
f0101677:	56                   	push   %esi
f0101678:	53                   	push   %ebx
f0101679:	8b 55 08             	mov    0x8(%ebp),%edx
f010167c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010167f:	eb 03                	jmp    f0101684 <strtol+0x11>
		s++;
f0101681:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101684:	0f b6 02             	movzbl (%edx),%eax
f0101687:	3c 20                	cmp    $0x20,%al
f0101689:	74 f6                	je     f0101681 <strtol+0xe>
f010168b:	3c 09                	cmp    $0x9,%al
f010168d:	74 f2                	je     f0101681 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010168f:	3c 2b                	cmp    $0x2b,%al
f0101691:	75 0a                	jne    f010169d <strtol+0x2a>
		s++;
f0101693:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101696:	bf 00 00 00 00       	mov    $0x0,%edi
f010169b:	eb 10                	jmp    f01016ad <strtol+0x3a>
f010169d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01016a2:	3c 2d                	cmp    $0x2d,%al
f01016a4:	75 07                	jne    f01016ad <strtol+0x3a>
		s++, neg = 1;
f01016a6:	8d 52 01             	lea    0x1(%edx),%edx
f01016a9:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01016ad:	85 db                	test   %ebx,%ebx
f01016af:	0f 94 c0             	sete   %al
f01016b2:	74 05                	je     f01016b9 <strtol+0x46>
f01016b4:	83 fb 10             	cmp    $0x10,%ebx
f01016b7:	75 15                	jne    f01016ce <strtol+0x5b>
f01016b9:	80 3a 30             	cmpb   $0x30,(%edx)
f01016bc:	75 10                	jne    f01016ce <strtol+0x5b>
f01016be:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01016c2:	75 0a                	jne    f01016ce <strtol+0x5b>
		s += 2, base = 16;
f01016c4:	83 c2 02             	add    $0x2,%edx
f01016c7:	bb 10 00 00 00       	mov    $0x10,%ebx
f01016cc:	eb 13                	jmp    f01016e1 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01016ce:	84 c0                	test   %al,%al
f01016d0:	74 0f                	je     f01016e1 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01016d2:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01016d7:	80 3a 30             	cmpb   $0x30,(%edx)
f01016da:	75 05                	jne    f01016e1 <strtol+0x6e>
		s++, base = 8;
f01016dc:	83 c2 01             	add    $0x1,%edx
f01016df:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f01016e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01016e6:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01016e8:	0f b6 0a             	movzbl (%edx),%ecx
f01016eb:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f01016ee:	80 fb 09             	cmp    $0x9,%bl
f01016f1:	77 08                	ja     f01016fb <strtol+0x88>
			dig = *s - '0';
f01016f3:	0f be c9             	movsbl %cl,%ecx
f01016f6:	83 e9 30             	sub    $0x30,%ecx
f01016f9:	eb 1e                	jmp    f0101719 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f01016fb:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f01016fe:	80 fb 19             	cmp    $0x19,%bl
f0101701:	77 08                	ja     f010170b <strtol+0x98>
			dig = *s - 'a' + 10;
f0101703:	0f be c9             	movsbl %cl,%ecx
f0101706:	83 e9 57             	sub    $0x57,%ecx
f0101709:	eb 0e                	jmp    f0101719 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010170b:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f010170e:	80 fb 19             	cmp    $0x19,%bl
f0101711:	77 14                	ja     f0101727 <strtol+0xb4>
			dig = *s - 'A' + 10;
f0101713:	0f be c9             	movsbl %cl,%ecx
f0101716:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101719:	39 f1                	cmp    %esi,%ecx
f010171b:	7d 0e                	jge    f010172b <strtol+0xb8>
			break;
		s++, val = (val * base) + dig;
f010171d:	83 c2 01             	add    $0x1,%edx
f0101720:	0f af c6             	imul   %esi,%eax
f0101723:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0101725:	eb c1                	jmp    f01016e8 <strtol+0x75>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0101727:	89 c1                	mov    %eax,%ecx
f0101729:	eb 02                	jmp    f010172d <strtol+0xba>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f010172b:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f010172d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101731:	74 05                	je     f0101738 <strtol+0xc5>
		*endptr = (char *) s;
f0101733:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101736:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101738:	89 ca                	mov    %ecx,%edx
f010173a:	f7 da                	neg    %edx
f010173c:	85 ff                	test   %edi,%edi
f010173e:	0f 45 c2             	cmovne %edx,%eax
}
f0101741:	5b                   	pop    %ebx
f0101742:	5e                   	pop    %esi
f0101743:	5f                   	pop    %edi
f0101744:	5d                   	pop    %ebp
f0101745:	c3                   	ret    
	...

f0101750 <__udivdi3>:
f0101750:	83 ec 1c             	sub    $0x1c,%esp
f0101753:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101757:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f010175b:	8b 44 24 20          	mov    0x20(%esp),%eax
f010175f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101763:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101767:	8b 74 24 24          	mov    0x24(%esp),%esi
f010176b:	85 ff                	test   %edi,%edi
f010176d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101771:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101775:	89 cd                	mov    %ecx,%ebp
f0101777:	89 44 24 04          	mov    %eax,0x4(%esp)
f010177b:	75 33                	jne    f01017b0 <__udivdi3+0x60>
f010177d:	39 f1                	cmp    %esi,%ecx
f010177f:	77 57                	ja     f01017d8 <__udivdi3+0x88>
f0101781:	85 c9                	test   %ecx,%ecx
f0101783:	75 0b                	jne    f0101790 <__udivdi3+0x40>
f0101785:	b8 01 00 00 00       	mov    $0x1,%eax
f010178a:	31 d2                	xor    %edx,%edx
f010178c:	f7 f1                	div    %ecx
f010178e:	89 c1                	mov    %eax,%ecx
f0101790:	89 f0                	mov    %esi,%eax
f0101792:	31 d2                	xor    %edx,%edx
f0101794:	f7 f1                	div    %ecx
f0101796:	89 c6                	mov    %eax,%esi
f0101798:	8b 44 24 04          	mov    0x4(%esp),%eax
f010179c:	f7 f1                	div    %ecx
f010179e:	89 f2                	mov    %esi,%edx
f01017a0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01017a4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01017a8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01017ac:	83 c4 1c             	add    $0x1c,%esp
f01017af:	c3                   	ret    
f01017b0:	31 d2                	xor    %edx,%edx
f01017b2:	31 c0                	xor    %eax,%eax
f01017b4:	39 f7                	cmp    %esi,%edi
f01017b6:	77 e8                	ja     f01017a0 <__udivdi3+0x50>
f01017b8:	0f bd cf             	bsr    %edi,%ecx
f01017bb:	83 f1 1f             	xor    $0x1f,%ecx
f01017be:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01017c2:	75 2c                	jne    f01017f0 <__udivdi3+0xa0>
f01017c4:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f01017c8:	76 04                	jbe    f01017ce <__udivdi3+0x7e>
f01017ca:	39 f7                	cmp    %esi,%edi
f01017cc:	73 d2                	jae    f01017a0 <__udivdi3+0x50>
f01017ce:	31 d2                	xor    %edx,%edx
f01017d0:	b8 01 00 00 00       	mov    $0x1,%eax
f01017d5:	eb c9                	jmp    f01017a0 <__udivdi3+0x50>
f01017d7:	90                   	nop
f01017d8:	89 f2                	mov    %esi,%edx
f01017da:	f7 f1                	div    %ecx
f01017dc:	31 d2                	xor    %edx,%edx
f01017de:	8b 74 24 10          	mov    0x10(%esp),%esi
f01017e2:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01017e6:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01017ea:	83 c4 1c             	add    $0x1c,%esp
f01017ed:	c3                   	ret    
f01017ee:	66 90                	xchg   %ax,%ax
f01017f0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01017f5:	b8 20 00 00 00       	mov    $0x20,%eax
f01017fa:	89 ea                	mov    %ebp,%edx
f01017fc:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101800:	d3 e7                	shl    %cl,%edi
f0101802:	89 c1                	mov    %eax,%ecx
f0101804:	d3 ea                	shr    %cl,%edx
f0101806:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010180b:	09 fa                	or     %edi,%edx
f010180d:	89 f7                	mov    %esi,%edi
f010180f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101813:	89 f2                	mov    %esi,%edx
f0101815:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101819:	d3 e5                	shl    %cl,%ebp
f010181b:	89 c1                	mov    %eax,%ecx
f010181d:	d3 ef                	shr    %cl,%edi
f010181f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101824:	d3 e2                	shl    %cl,%edx
f0101826:	89 c1                	mov    %eax,%ecx
f0101828:	d3 ee                	shr    %cl,%esi
f010182a:	09 d6                	or     %edx,%esi
f010182c:	89 fa                	mov    %edi,%edx
f010182e:	89 f0                	mov    %esi,%eax
f0101830:	f7 74 24 0c          	divl   0xc(%esp)
f0101834:	89 d7                	mov    %edx,%edi
f0101836:	89 c6                	mov    %eax,%esi
f0101838:	f7 e5                	mul    %ebp
f010183a:	39 d7                	cmp    %edx,%edi
f010183c:	72 22                	jb     f0101860 <__udivdi3+0x110>
f010183e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0101842:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101847:	d3 e5                	shl    %cl,%ebp
f0101849:	39 c5                	cmp    %eax,%ebp
f010184b:	73 04                	jae    f0101851 <__udivdi3+0x101>
f010184d:	39 d7                	cmp    %edx,%edi
f010184f:	74 0f                	je     f0101860 <__udivdi3+0x110>
f0101851:	89 f0                	mov    %esi,%eax
f0101853:	31 d2                	xor    %edx,%edx
f0101855:	e9 46 ff ff ff       	jmp    f01017a0 <__udivdi3+0x50>
f010185a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101860:	8d 46 ff             	lea    -0x1(%esi),%eax
f0101863:	31 d2                	xor    %edx,%edx
f0101865:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101869:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010186d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101871:	83 c4 1c             	add    $0x1c,%esp
f0101874:	c3                   	ret    
	...

f0101880 <__umoddi3>:
f0101880:	83 ec 1c             	sub    $0x1c,%esp
f0101883:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101887:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f010188b:	8b 44 24 20          	mov    0x20(%esp),%eax
f010188f:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101893:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101897:	8b 74 24 24          	mov    0x24(%esp),%esi
f010189b:	85 ed                	test   %ebp,%ebp
f010189d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01018a1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01018a5:	89 cf                	mov    %ecx,%edi
f01018a7:	89 04 24             	mov    %eax,(%esp)
f01018aa:	89 f2                	mov    %esi,%edx
f01018ac:	75 1a                	jne    f01018c8 <__umoddi3+0x48>
f01018ae:	39 f1                	cmp    %esi,%ecx
f01018b0:	76 4e                	jbe    f0101900 <__umoddi3+0x80>
f01018b2:	f7 f1                	div    %ecx
f01018b4:	89 d0                	mov    %edx,%eax
f01018b6:	31 d2                	xor    %edx,%edx
f01018b8:	8b 74 24 10          	mov    0x10(%esp),%esi
f01018bc:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01018c0:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01018c4:	83 c4 1c             	add    $0x1c,%esp
f01018c7:	c3                   	ret    
f01018c8:	39 f5                	cmp    %esi,%ebp
f01018ca:	77 54                	ja     f0101920 <__umoddi3+0xa0>
f01018cc:	0f bd c5             	bsr    %ebp,%eax
f01018cf:	83 f0 1f             	xor    $0x1f,%eax
f01018d2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018d6:	75 60                	jne    f0101938 <__umoddi3+0xb8>
f01018d8:	3b 0c 24             	cmp    (%esp),%ecx
f01018db:	0f 87 07 01 00 00    	ja     f01019e8 <__umoddi3+0x168>
f01018e1:	89 f2                	mov    %esi,%edx
f01018e3:	8b 34 24             	mov    (%esp),%esi
f01018e6:	29 ce                	sub    %ecx,%esi
f01018e8:	19 ea                	sbb    %ebp,%edx
f01018ea:	89 34 24             	mov    %esi,(%esp)
f01018ed:	8b 04 24             	mov    (%esp),%eax
f01018f0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01018f4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01018f8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01018fc:	83 c4 1c             	add    $0x1c,%esp
f01018ff:	c3                   	ret    
f0101900:	85 c9                	test   %ecx,%ecx
f0101902:	75 0b                	jne    f010190f <__umoddi3+0x8f>
f0101904:	b8 01 00 00 00       	mov    $0x1,%eax
f0101909:	31 d2                	xor    %edx,%edx
f010190b:	f7 f1                	div    %ecx
f010190d:	89 c1                	mov    %eax,%ecx
f010190f:	89 f0                	mov    %esi,%eax
f0101911:	31 d2                	xor    %edx,%edx
f0101913:	f7 f1                	div    %ecx
f0101915:	8b 04 24             	mov    (%esp),%eax
f0101918:	f7 f1                	div    %ecx
f010191a:	eb 98                	jmp    f01018b4 <__umoddi3+0x34>
f010191c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101920:	89 f2                	mov    %esi,%edx
f0101922:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101926:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010192a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010192e:	83 c4 1c             	add    $0x1c,%esp
f0101931:	c3                   	ret    
f0101932:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101938:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010193d:	89 e8                	mov    %ebp,%eax
f010193f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0101944:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0101948:	89 fa                	mov    %edi,%edx
f010194a:	d3 e0                	shl    %cl,%eax
f010194c:	89 e9                	mov    %ebp,%ecx
f010194e:	d3 ea                	shr    %cl,%edx
f0101950:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101955:	09 c2                	or     %eax,%edx
f0101957:	8b 44 24 08          	mov    0x8(%esp),%eax
f010195b:	89 14 24             	mov    %edx,(%esp)
f010195e:	89 f2                	mov    %esi,%edx
f0101960:	d3 e7                	shl    %cl,%edi
f0101962:	89 e9                	mov    %ebp,%ecx
f0101964:	d3 ea                	shr    %cl,%edx
f0101966:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010196b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010196f:	d3 e6                	shl    %cl,%esi
f0101971:	89 e9                	mov    %ebp,%ecx
f0101973:	d3 e8                	shr    %cl,%eax
f0101975:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010197a:	09 f0                	or     %esi,%eax
f010197c:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101980:	f7 34 24             	divl   (%esp)
f0101983:	d3 e6                	shl    %cl,%esi
f0101985:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101989:	89 d6                	mov    %edx,%esi
f010198b:	f7 e7                	mul    %edi
f010198d:	39 d6                	cmp    %edx,%esi
f010198f:	89 c1                	mov    %eax,%ecx
f0101991:	89 d7                	mov    %edx,%edi
f0101993:	72 3f                	jb     f01019d4 <__umoddi3+0x154>
f0101995:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101999:	72 35                	jb     f01019d0 <__umoddi3+0x150>
f010199b:	8b 44 24 08          	mov    0x8(%esp),%eax
f010199f:	29 c8                	sub    %ecx,%eax
f01019a1:	19 fe                	sbb    %edi,%esi
f01019a3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01019a8:	89 f2                	mov    %esi,%edx
f01019aa:	d3 e8                	shr    %cl,%eax
f01019ac:	89 e9                	mov    %ebp,%ecx
f01019ae:	d3 e2                	shl    %cl,%edx
f01019b0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01019b5:	09 d0                	or     %edx,%eax
f01019b7:	89 f2                	mov    %esi,%edx
f01019b9:	d3 ea                	shr    %cl,%edx
f01019bb:	8b 74 24 10          	mov    0x10(%esp),%esi
f01019bf:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01019c3:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01019c7:	83 c4 1c             	add    $0x1c,%esp
f01019ca:	c3                   	ret    
f01019cb:	90                   	nop
f01019cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019d0:	39 d6                	cmp    %edx,%esi
f01019d2:	75 c7                	jne    f010199b <__umoddi3+0x11b>
f01019d4:	89 d7                	mov    %edx,%edi
f01019d6:	89 c1                	mov    %eax,%ecx
f01019d8:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f01019dc:	1b 3c 24             	sbb    (%esp),%edi
f01019df:	eb ba                	jmp    f010199b <__umoddi3+0x11b>
f01019e1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01019e8:	39 f5                	cmp    %esi,%ebp
f01019ea:	0f 82 f1 fe ff ff    	jb     f01018e1 <__umoddi3+0x61>
f01019f0:	e9 f8 fe ff ff       	jmp    f01018ed <__umoddi3+0x6d>
