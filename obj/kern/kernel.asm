
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
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 79 11 f0       	mov    $0xf0117970,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 73 11 f0 	movl   $0xf0117300,(%esp)
f0100063:	e8 9b 38 00 00       	call   f0103903 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 8a 04 00 00       	call   f01004f7 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 e0 3d 10 f0 	movl   $0xf0103de0,(%esp)
f010007c:	e8 5d 2d 00 00       	call   f0102dde <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 1b 11 00 00       	call   f01011a1 <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 43 07 00 00       	call   f01007d5 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 60 79 11 f0 00 	cmpl   $0x0,0xf0117960
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 60 79 11 f0    	mov    %esi,0xf0117960

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 fb 3d 10 f0 	movl   $0xf0103dfb,(%esp)
f01000c8:	e8 11 2d 00 00       	call   f0102dde <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 d2 2c 00 00       	call   f0102dab <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 72 4d 10 f0 	movl   $0xf0104d72,(%esp)
f01000e0:	e8 f9 2c 00 00       	call   f0102dde <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 e4 06 00 00       	call   f01007d5 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 13 3e 10 f0 	movl   $0xf0103e13,(%esp)
f0100112:	e8 c7 2c 00 00       	call   f0102dde <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 85 2c 00 00       	call   f0102dab <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 72 4d 10 f0 	movl   $0xf0104d72,(%esp)
f010012d:	e8 ac 2c 00 00       	call   f0102dde <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
	...

f0100140 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba 84 00 00 00       	mov    $0x84,%edx
f0100148:	ec                   	in     (%dx),%al
f0100149:	ec                   	in     (%dx),%al
f010014a:	ec                   	in     (%dx),%al
f010014b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010014c:	5d                   	pop    %ebp
f010014d:	c3                   	ret    

f010014e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010014e:	55                   	push   %ebp
f010014f:	89 e5                	mov    %esp,%ebp
f0100151:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100156:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100157:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010015c:	a8 01                	test   $0x1,%al
f010015e:	74 06                	je     f0100166 <serial_proc_data+0x18>
f0100160:	b2 f8                	mov    $0xf8,%dl
f0100162:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100163:	0f b6 c8             	movzbl %al,%ecx
}
f0100166:	89 c8                	mov    %ecx,%eax
f0100168:	5d                   	pop    %ebp
f0100169:	c3                   	ret    

f010016a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010016a:	55                   	push   %ebp
f010016b:	89 e5                	mov    %esp,%ebp
f010016d:	53                   	push   %ebx
f010016e:	83 ec 04             	sub    $0x4,%esp
f0100171:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100173:	eb 25                	jmp    f010019a <cons_intr+0x30>
		if (c == 0)
f0100175:	85 c0                	test   %eax,%eax
f0100177:	74 21                	je     f010019a <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f0100179:	8b 15 24 75 11 f0    	mov    0xf0117524,%edx
f010017f:	88 82 20 73 11 f0    	mov    %al,-0xfee8ce0(%edx)
f0100185:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f0100188:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f010018d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100192:	0f 44 c2             	cmove  %edx,%eax
f0100195:	a3 24 75 11 f0       	mov    %eax,0xf0117524
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f010019a:	ff d3                	call   *%ebx
f010019c:	83 f8 ff             	cmp    $0xffffffff,%eax
f010019f:	75 d4                	jne    f0100175 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001a1:	83 c4 04             	add    $0x4,%esp
f01001a4:	5b                   	pop    %ebx
f01001a5:	5d                   	pop    %ebp
f01001a6:	c3                   	ret    

f01001a7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001a7:	55                   	push   %ebp
f01001a8:	89 e5                	mov    %esp,%ebp
f01001aa:	57                   	push   %edi
f01001ab:	56                   	push   %esi
f01001ac:	53                   	push   %ebx
f01001ad:	83 ec 2c             	sub    $0x2c,%esp
f01001b0:	89 c7                	mov    %eax,%edi
f01001b2:	bb 01 32 00 00       	mov    $0x3201,%ebx
f01001b7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01001bc:	eb 05                	jmp    f01001c3 <cons_putc+0x1c>
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001be:	e8 7d ff ff ff       	call   f0100140 <delay>
f01001c3:	89 f2                	mov    %esi,%edx
f01001c5:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01001c6:	a8 20                	test   $0x20,%al
f01001c8:	75 05                	jne    f01001cf <cons_putc+0x28>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001ca:	83 eb 01             	sub    $0x1,%ebx
f01001cd:	75 ef                	jne    f01001be <cons_putc+0x17>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01001cf:	89 fa                	mov    %edi,%edx
f01001d1:	89 f8                	mov    %edi,%eax
f01001d3:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001d6:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001db:	ee                   	out    %al,(%dx)
f01001dc:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001e1:	be 79 03 00 00       	mov    $0x379,%esi
f01001e6:	eb 05                	jmp    f01001ed <cons_putc+0x46>
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
		delay();
f01001e8:	e8 53 ff ff ff       	call   f0100140 <delay>
f01001ed:	89 f2                	mov    %esi,%edx
f01001ef:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001f0:	84 c0                	test   %al,%al
f01001f2:	78 05                	js     f01001f9 <cons_putc+0x52>
f01001f4:	83 eb 01             	sub    $0x1,%ebx
f01001f7:	75 ef                	jne    f01001e8 <cons_putc+0x41>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001f9:	ba 78 03 00 00       	mov    $0x378,%edx
f01001fe:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100202:	ee                   	out    %al,(%dx)
f0100203:	b2 7a                	mov    $0x7a,%dl
f0100205:	b8 0d 00 00 00       	mov    $0xd,%eax
f010020a:	ee                   	out    %al,(%dx)
f010020b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100210:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100211:	89 fa                	mov    %edi,%edx
f0100213:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100219:	89 f8                	mov    %edi,%eax
f010021b:	80 cc 07             	or     $0x7,%ah
f010021e:	85 d2                	test   %edx,%edx
f0100220:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100223:	89 f8                	mov    %edi,%eax
f0100225:	25 ff 00 00 00       	and    $0xff,%eax
f010022a:	83 f8 09             	cmp    $0x9,%eax
f010022d:	74 79                	je     f01002a8 <cons_putc+0x101>
f010022f:	83 f8 09             	cmp    $0x9,%eax
f0100232:	7f 0e                	jg     f0100242 <cons_putc+0x9b>
f0100234:	83 f8 08             	cmp    $0x8,%eax
f0100237:	0f 85 9f 00 00 00    	jne    f01002dc <cons_putc+0x135>
f010023d:	8d 76 00             	lea    0x0(%esi),%esi
f0100240:	eb 10                	jmp    f0100252 <cons_putc+0xab>
f0100242:	83 f8 0a             	cmp    $0xa,%eax
f0100245:	74 3b                	je     f0100282 <cons_putc+0xdb>
f0100247:	83 f8 0d             	cmp    $0xd,%eax
f010024a:	0f 85 8c 00 00 00    	jne    f01002dc <cons_putc+0x135>
f0100250:	eb 38                	jmp    f010028a <cons_putc+0xe3>
	case '\b':
		if (crt_pos > 0) {
f0100252:	0f b7 05 34 75 11 f0 	movzwl 0xf0117534,%eax
f0100259:	66 85 c0             	test   %ax,%ax
f010025c:	0f 84 e4 00 00 00    	je     f0100346 <cons_putc+0x19f>
			crt_pos--;
f0100262:	83 e8 01             	sub    $0x1,%eax
f0100265:	66 a3 34 75 11 f0    	mov    %ax,0xf0117534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010026b:	0f b7 c0             	movzwl %ax,%eax
f010026e:	66 81 e7 00 ff       	and    $0xff00,%di
f0100273:	83 cf 20             	or     $0x20,%edi
f0100276:	8b 15 30 75 11 f0    	mov    0xf0117530,%edx
f010027c:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100280:	eb 77                	jmp    f01002f9 <cons_putc+0x152>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100282:	66 83 05 34 75 11 f0 	addw   $0x50,0xf0117534
f0100289:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010028a:	0f b7 05 34 75 11 f0 	movzwl 0xf0117534,%eax
f0100291:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100297:	c1 e8 16             	shr    $0x16,%eax
f010029a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010029d:	c1 e0 04             	shl    $0x4,%eax
f01002a0:	66 a3 34 75 11 f0    	mov    %ax,0xf0117534
f01002a6:	eb 51                	jmp    f01002f9 <cons_putc+0x152>
		break;
	case '\t':
		cons_putc(' ');
f01002a8:	b8 20 00 00 00       	mov    $0x20,%eax
f01002ad:	e8 f5 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002b2:	b8 20 00 00 00       	mov    $0x20,%eax
f01002b7:	e8 eb fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002bc:	b8 20 00 00 00       	mov    $0x20,%eax
f01002c1:	e8 e1 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002c6:	b8 20 00 00 00       	mov    $0x20,%eax
f01002cb:	e8 d7 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002d0:	b8 20 00 00 00       	mov    $0x20,%eax
f01002d5:	e8 cd fe ff ff       	call   f01001a7 <cons_putc>
f01002da:	eb 1d                	jmp    f01002f9 <cons_putc+0x152>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01002dc:	0f b7 05 34 75 11 f0 	movzwl 0xf0117534,%eax
f01002e3:	0f b7 c8             	movzwl %ax,%ecx
f01002e6:	8b 15 30 75 11 f0    	mov    0xf0117530,%edx
f01002ec:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f01002f0:	83 c0 01             	add    $0x1,%eax
f01002f3:	66 a3 34 75 11 f0    	mov    %ax,0xf0117534
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01002f9:	66 81 3d 34 75 11 f0 	cmpw   $0x7cf,0xf0117534
f0100300:	cf 07 
f0100302:	76 42                	jbe    f0100346 <cons_putc+0x19f>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100304:	a1 30 75 11 f0       	mov    0xf0117530,%eax
f0100309:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100310:	00 
f0100311:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100317:	89 54 24 04          	mov    %edx,0x4(%esp)
f010031b:	89 04 24             	mov    %eax,(%esp)
f010031e:	e8 3b 36 00 00       	call   f010395e <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100323:	8b 15 30 75 11 f0    	mov    0xf0117530,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100329:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010032e:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100334:	83 c0 01             	add    $0x1,%eax
f0100337:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f010033c:	75 f0                	jne    f010032e <cons_putc+0x187>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010033e:	66 83 2d 34 75 11 f0 	subw   $0x50,0xf0117534
f0100345:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100346:	8b 0d 2c 75 11 f0    	mov    0xf011752c,%ecx
f010034c:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100351:	89 ca                	mov    %ecx,%edx
f0100353:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100354:	0f b7 35 34 75 11 f0 	movzwl 0xf0117534,%esi
f010035b:	8d 59 01             	lea    0x1(%ecx),%ebx
f010035e:	89 f0                	mov    %esi,%eax
f0100360:	66 c1 e8 08          	shr    $0x8,%ax
f0100364:	89 da                	mov    %ebx,%edx
f0100366:	ee                   	out    %al,(%dx)
f0100367:	b8 0f 00 00 00       	mov    $0xf,%eax
f010036c:	89 ca                	mov    %ecx,%edx
f010036e:	ee                   	out    %al,(%dx)
f010036f:	89 f0                	mov    %esi,%eax
f0100371:	89 da                	mov    %ebx,%edx
f0100373:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100374:	83 c4 2c             	add    $0x2c,%esp
f0100377:	5b                   	pop    %ebx
f0100378:	5e                   	pop    %esi
f0100379:	5f                   	pop    %edi
f010037a:	5d                   	pop    %ebp
f010037b:	c3                   	ret    

f010037c <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010037c:	55                   	push   %ebp
f010037d:	89 e5                	mov    %esp,%ebp
f010037f:	53                   	push   %ebx
f0100380:	83 ec 14             	sub    $0x14,%esp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100383:	ba 64 00 00 00       	mov    $0x64,%edx
f0100388:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100389:	0f b6 c0             	movzbl %al,%eax
		return -1;
f010038c:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100391:	a8 01                	test   $0x1,%al
f0100393:	0f 84 e6 00 00 00    	je     f010047f <kbd_proc_data+0x103>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f0100399:	a8 20                	test   $0x20,%al
f010039b:	0f 85 de 00 00 00    	jne    f010047f <kbd_proc_data+0x103>
f01003a1:	b2 60                	mov    $0x60,%dl
f01003a3:	ec                   	in     (%dx),%al
f01003a4:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01003a6:	3c e0                	cmp    $0xe0,%al
f01003a8:	75 11                	jne    f01003bb <kbd_proc_data+0x3f>
		// E0 escape character
		shift |= E0ESC;
f01003aa:	83 0d 28 75 11 f0 40 	orl    $0x40,0xf0117528
		return 0;
f01003b1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003b6:	e9 c4 00 00 00       	jmp    f010047f <kbd_proc_data+0x103>
	} else if (data & 0x80) {
f01003bb:	84 c0                	test   %al,%al
f01003bd:	79 37                	jns    f01003f6 <kbd_proc_data+0x7a>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003bf:	8b 0d 28 75 11 f0    	mov    0xf0117528,%ecx
f01003c5:	89 cb                	mov    %ecx,%ebx
f01003c7:	83 e3 40             	and    $0x40,%ebx
f01003ca:	83 e0 7f             	and    $0x7f,%eax
f01003cd:	85 db                	test   %ebx,%ebx
f01003cf:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003d2:	0f b6 d2             	movzbl %dl,%edx
f01003d5:	0f b6 82 60 3e 10 f0 	movzbl -0xfefc1a0(%edx),%eax
f01003dc:	83 c8 40             	or     $0x40,%eax
f01003df:	0f b6 c0             	movzbl %al,%eax
f01003e2:	f7 d0                	not    %eax
f01003e4:	21 c1                	and    %eax,%ecx
f01003e6:	89 0d 28 75 11 f0    	mov    %ecx,0xf0117528
		return 0;
f01003ec:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003f1:	e9 89 00 00 00       	jmp    f010047f <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f01003f6:	8b 0d 28 75 11 f0    	mov    0xf0117528,%ecx
f01003fc:	f6 c1 40             	test   $0x40,%cl
f01003ff:	74 0e                	je     f010040f <kbd_proc_data+0x93>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100401:	89 c2                	mov    %eax,%edx
f0100403:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100406:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100409:	89 0d 28 75 11 f0    	mov    %ecx,0xf0117528
	}

	shift |= shiftcode[data];
f010040f:	0f b6 d2             	movzbl %dl,%edx
f0100412:	0f b6 82 60 3e 10 f0 	movzbl -0xfefc1a0(%edx),%eax
f0100419:	0b 05 28 75 11 f0    	or     0xf0117528,%eax
	shift ^= togglecode[data];
f010041f:	0f b6 8a 60 3f 10 f0 	movzbl -0xfefc0a0(%edx),%ecx
f0100426:	31 c8                	xor    %ecx,%eax
f0100428:	a3 28 75 11 f0       	mov    %eax,0xf0117528

	c = charcode[shift & (CTL | SHIFT)][data];
f010042d:	89 c1                	mov    %eax,%ecx
f010042f:	83 e1 03             	and    $0x3,%ecx
f0100432:	8b 0c 8d 60 40 10 f0 	mov    -0xfefbfa0(,%ecx,4),%ecx
f0100439:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f010043d:	a8 08                	test   $0x8,%al
f010043f:	74 19                	je     f010045a <kbd_proc_data+0xde>
		if ('a' <= c && c <= 'z')
f0100441:	8d 53 9f             	lea    -0x61(%ebx),%edx
f0100444:	83 fa 19             	cmp    $0x19,%edx
f0100447:	77 05                	ja     f010044e <kbd_proc_data+0xd2>
			c += 'A' - 'a';
f0100449:	83 eb 20             	sub    $0x20,%ebx
f010044c:	eb 0c                	jmp    f010045a <kbd_proc_data+0xde>
		else if ('A' <= c && c <= 'Z')
f010044e:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f0100451:	8d 53 20             	lea    0x20(%ebx),%edx
f0100454:	83 f9 19             	cmp    $0x19,%ecx
f0100457:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010045a:	f7 d0                	not    %eax
f010045c:	a8 06                	test   $0x6,%al
f010045e:	75 1f                	jne    f010047f <kbd_proc_data+0x103>
f0100460:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100466:	75 17                	jne    f010047f <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f0100468:	c7 04 24 2d 3e 10 f0 	movl   $0xf0103e2d,(%esp)
f010046f:	e8 6a 29 00 00       	call   f0102dde <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100474:	ba 92 00 00 00       	mov    $0x92,%edx
f0100479:	b8 03 00 00 00       	mov    $0x3,%eax
f010047e:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010047f:	89 d8                	mov    %ebx,%eax
f0100481:	83 c4 14             	add    $0x14,%esp
f0100484:	5b                   	pop    %ebx
f0100485:	5d                   	pop    %ebp
f0100486:	c3                   	ret    

f0100487 <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100487:	55                   	push   %ebp
f0100488:	89 e5                	mov    %esp,%ebp
f010048a:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f010048d:	80 3d 00 73 11 f0 00 	cmpb   $0x0,0xf0117300
f0100494:	74 0a                	je     f01004a0 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f0100496:	b8 4e 01 10 f0       	mov    $0xf010014e,%eax
f010049b:	e8 ca fc ff ff       	call   f010016a <cons_intr>
}
f01004a0:	c9                   	leave  
f01004a1:	c3                   	ret    

f01004a2 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004a2:	55                   	push   %ebp
f01004a3:	89 e5                	mov    %esp,%ebp
f01004a5:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a8:	b8 7c 03 10 f0       	mov    $0xf010037c,%eax
f01004ad:	e8 b8 fc ff ff       	call   f010016a <cons_intr>
}
f01004b2:	c9                   	leave  
f01004b3:	c3                   	ret    

f01004b4 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004b4:	55                   	push   %ebp
f01004b5:	89 e5                	mov    %esp,%ebp
f01004b7:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004ba:	e8 c8 ff ff ff       	call   f0100487 <serial_intr>
	kbd_intr();
f01004bf:	e8 de ff ff ff       	call   f01004a2 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004c4:	8b 15 20 75 11 f0    	mov    0xf0117520,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f01004ca:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004cf:	3b 15 24 75 11 f0    	cmp    0xf0117524,%edx
f01004d5:	74 1e                	je     f01004f5 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f01004d7:	0f b6 82 20 73 11 f0 	movzbl -0xfee8ce0(%edx),%eax
f01004de:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f01004e1:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004e7:	b9 00 00 00 00       	mov    $0x0,%ecx
f01004ec:	0f 44 d1             	cmove  %ecx,%edx
f01004ef:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
		return c;
	}
	return 0;
}
f01004f5:	c9                   	leave  
f01004f6:	c3                   	ret    

f01004f7 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004f7:	55                   	push   %ebp
f01004f8:	89 e5                	mov    %esp,%ebp
f01004fa:	57                   	push   %edi
f01004fb:	56                   	push   %esi
f01004fc:	53                   	push   %ebx
f01004fd:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100500:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100507:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010050e:	5a a5 
	if (*cp != 0xA55A) {
f0100510:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100517:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010051b:	74 11                	je     f010052e <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010051d:	c7 05 2c 75 11 f0 b4 	movl   $0x3b4,0xf011752c
f0100524:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100527:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010052c:	eb 16                	jmp    f0100544 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010052e:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100535:	c7 05 2c 75 11 f0 d4 	movl   $0x3d4,0xf011752c
f010053c:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010053f:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100544:	8b 0d 2c 75 11 f0    	mov    0xf011752c,%ecx
f010054a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010054f:	89 ca                	mov    %ecx,%edx
f0100551:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100552:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100555:	89 da                	mov    %ebx,%edx
f0100557:	ec                   	in     (%dx),%al
f0100558:	0f b6 f8             	movzbl %al,%edi
f010055b:	c1 e7 08             	shl    $0x8,%edi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055e:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100563:	89 ca                	mov    %ecx,%edx
f0100565:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100566:	89 da                	mov    %ebx,%edx
f0100568:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100569:	89 35 30 75 11 f0    	mov    %esi,0xf0117530

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010056f:	0f b6 d8             	movzbl %al,%ebx
f0100572:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100574:	66 89 3d 34 75 11 f0 	mov    %di,0xf0117534
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010057b:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f0100580:	b8 00 00 00 00       	mov    $0x0,%eax
f0100585:	89 da                	mov    %ebx,%edx
f0100587:	ee                   	out    %al,(%dx)
f0100588:	b2 fb                	mov    $0xfb,%dl
f010058a:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010058f:	ee                   	out    %al,(%dx)
f0100590:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f0100595:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059a:	89 ca                	mov    %ecx,%edx
f010059c:	ee                   	out    %al,(%dx)
f010059d:	b2 f9                	mov    $0xf9,%dl
f010059f:	b8 00 00 00 00       	mov    $0x0,%eax
f01005a4:	ee                   	out    %al,(%dx)
f01005a5:	b2 fb                	mov    $0xfb,%dl
f01005a7:	b8 03 00 00 00       	mov    $0x3,%eax
f01005ac:	ee                   	out    %al,(%dx)
f01005ad:	b2 fc                	mov    $0xfc,%dl
f01005af:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	b2 f9                	mov    $0xf9,%dl
f01005b7:	b8 01 00 00 00       	mov    $0x1,%eax
f01005bc:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005bd:	b2 fd                	mov    $0xfd,%dl
f01005bf:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c0:	3c ff                	cmp    $0xff,%al
f01005c2:	0f 95 c0             	setne  %al
f01005c5:	89 c6                	mov    %eax,%esi
f01005c7:	a2 00 73 11 f0       	mov    %al,0xf0117300
f01005cc:	89 da                	mov    %ebx,%edx
f01005ce:	ec                   	in     (%dx),%al
f01005cf:	89 ca                	mov    %ecx,%edx
f01005d1:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005d2:	89 f0                	mov    %esi,%eax
f01005d4:	84 c0                	test   %al,%al
f01005d6:	75 0c                	jne    f01005e4 <cons_init+0xed>
		cprintf("Serial port does not exist!\n");
f01005d8:	c7 04 24 39 3e 10 f0 	movl   $0xf0103e39,(%esp)
f01005df:	e8 fa 27 00 00       	call   f0102dde <cprintf>
}
f01005e4:	83 c4 1c             	add    $0x1c,%esp
f01005e7:	5b                   	pop    %ebx
f01005e8:	5e                   	pop    %esi
f01005e9:	5f                   	pop    %edi
f01005ea:	5d                   	pop    %ebp
f01005eb:	c3                   	ret    

f01005ec <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005ec:	55                   	push   %ebp
f01005ed:	89 e5                	mov    %esp,%ebp
f01005ef:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005f2:	8b 45 08             	mov    0x8(%ebp),%eax
f01005f5:	e8 ad fb ff ff       	call   f01001a7 <cons_putc>
}
f01005fa:	c9                   	leave  
f01005fb:	c3                   	ret    

f01005fc <getchar>:

int
getchar(void)
{
f01005fc:	55                   	push   %ebp
f01005fd:	89 e5                	mov    %esp,%ebp
f01005ff:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100602:	e8 ad fe ff ff       	call   f01004b4 <cons_getc>
f0100607:	85 c0                	test   %eax,%eax
f0100609:	74 f7                	je     f0100602 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010060b:	c9                   	leave  
f010060c:	c3                   	ret    

f010060d <iscons>:

int
iscons(int fdnum)
{
f010060d:	55                   	push   %ebp
f010060e:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100610:	b8 01 00 00 00       	mov    $0x1,%eax
f0100615:	5d                   	pop    %ebp
f0100616:	c3                   	ret    
	...

f0100620 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100620:	55                   	push   %ebp
f0100621:	89 e5                	mov    %esp,%ebp
f0100623:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100626:	c7 04 24 70 40 10 f0 	movl   $0xf0104070,(%esp)
f010062d:	e8 ac 27 00 00       	call   f0102dde <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100632:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100639:	00 
f010063a:	c7 04 24 34 41 10 f0 	movl   $0xf0104134,(%esp)
f0100641:	e8 98 27 00 00       	call   f0102dde <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100646:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010064d:	00 
f010064e:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100655:	f0 
f0100656:	c7 04 24 5c 41 10 f0 	movl   $0xf010415c,(%esp)
f010065d:	e8 7c 27 00 00       	call   f0102dde <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100662:	c7 44 24 08 d5 3d 10 	movl   $0x103dd5,0x8(%esp)
f0100669:	00 
f010066a:	c7 44 24 04 d5 3d 10 	movl   $0xf0103dd5,0x4(%esp)
f0100671:	f0 
f0100672:	c7 04 24 80 41 10 f0 	movl   $0xf0104180,(%esp)
f0100679:	e8 60 27 00 00       	call   f0102dde <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010067e:	c7 44 24 08 00 73 11 	movl   $0x117300,0x8(%esp)
f0100685:	00 
f0100686:	c7 44 24 04 00 73 11 	movl   $0xf0117300,0x4(%esp)
f010068d:	f0 
f010068e:	c7 04 24 a4 41 10 f0 	movl   $0xf01041a4,(%esp)
f0100695:	e8 44 27 00 00       	call   f0102dde <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010069a:	c7 44 24 08 70 79 11 	movl   $0x117970,0x8(%esp)
f01006a1:	00 
f01006a2:	c7 44 24 04 70 79 11 	movl   $0xf0117970,0x4(%esp)
f01006a9:	f0 
f01006aa:	c7 04 24 c8 41 10 f0 	movl   $0xf01041c8,(%esp)
f01006b1:	e8 28 27 00 00       	call   f0102dde <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006b6:	b8 6f 7d 11 f0       	mov    $0xf0117d6f,%eax
f01006bb:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01006c0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006c5:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006cb:	85 c0                	test   %eax,%eax
f01006cd:	0f 48 c2             	cmovs  %edx,%eax
f01006d0:	c1 f8 0a             	sar    $0xa,%eax
f01006d3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006d7:	c7 04 24 ec 41 10 f0 	movl   $0xf01041ec,(%esp)
f01006de:	e8 fb 26 00 00       	call   f0102dde <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01006e3:	b8 00 00 00 00       	mov    $0x0,%eax
f01006e8:	c9                   	leave  
f01006e9:	c3                   	ret    

f01006ea <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006ea:	55                   	push   %ebp
f01006eb:	89 e5                	mov    %esp,%ebp
f01006ed:	53                   	push   %ebx
f01006ee:	83 ec 14             	sub    $0x14,%esp
f01006f1:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006f6:	8b 83 04 43 10 f0    	mov    -0xfefbcfc(%ebx),%eax
f01006fc:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100700:	8b 83 00 43 10 f0    	mov    -0xfefbd00(%ebx),%eax
f0100706:	89 44 24 04          	mov    %eax,0x4(%esp)
f010070a:	c7 04 24 89 40 10 f0 	movl   $0xf0104089,(%esp)
f0100711:	e8 c8 26 00 00       	call   f0102dde <cprintf>
f0100716:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
f0100719:	83 fb 24             	cmp    $0x24,%ebx
f010071c:	75 d8                	jne    f01006f6 <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f010071e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100723:	83 c4 14             	add    $0x14,%esp
f0100726:	5b                   	pop    %ebx
f0100727:	5d                   	pop    %ebp
f0100728:	c3                   	ret    

f0100729 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100729:	55                   	push   %ebp
f010072a:	89 e5                	mov    %esp,%ebp
f010072c:	56                   	push   %esi
f010072d:	53                   	push   %ebx
f010072e:	83 ec 40             	sub    $0x40,%esp
	// Your code here.
	struct Eipdebuginfo info;
	int *ebp = (int*)read_ebp();
f0100731:	89 eb                	mov    %ebp,%ebx
	cprintf("Stack backtrace:\n");
f0100733:	c7 04 24 92 40 10 f0 	movl   $0xf0104092,(%esp)
f010073a:	e8 9f 26 00 00       	call   f0102dde <cprintf>
	while (ebp != 0)
	{
		cprintf("ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, *(ebp+1), *(ebp+2), *(ebp+3), *(ebp+4), *(ebp+5), *(ebp+6));
		debuginfo_eip(*(ebp+1), &info);
f010073f:	8d 75 e0             	lea    -0x20(%ebp),%esi
{
	// Your code here.
	struct Eipdebuginfo info;
	int *ebp = (int*)read_ebp();
	cprintf("Stack backtrace:\n");
	while (ebp != 0)
f0100742:	eb 7d                	jmp    f01007c1 <mon_backtrace+0x98>
	{
		cprintf("ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, *(ebp+1), *(ebp+2), *(ebp+3), *(ebp+4), *(ebp+5), *(ebp+6));
f0100744:	8b 43 18             	mov    0x18(%ebx),%eax
f0100747:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f010074b:	8b 43 14             	mov    0x14(%ebx),%eax
f010074e:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100752:	8b 43 10             	mov    0x10(%ebx),%eax
f0100755:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100759:	8b 43 0c             	mov    0xc(%ebx),%eax
f010075c:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100760:	8b 43 08             	mov    0x8(%ebx),%eax
f0100763:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100767:	8b 43 04             	mov    0x4(%ebx),%eax
f010076a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010076e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100772:	c7 04 24 18 42 10 f0 	movl   $0xf0104218,(%esp)
f0100779:	e8 60 26 00 00       	call   f0102dde <cprintf>
		debuginfo_eip(*(ebp+1), &info);
f010077e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100782:	8b 43 04             	mov    0x4(%ebx),%eax
f0100785:	89 04 24             	mov    %eax,(%esp)
f0100788:	e8 53 27 00 00       	call   f0102ee0 <debuginfo_eip>
		cprintf("       %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, *(ebp+1)-info.eip_fn_addr);
f010078d:	8b 43 04             	mov    0x4(%ebx),%eax
f0100790:	2b 45 f0             	sub    -0x10(%ebp),%eax
f0100793:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100797:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010079a:	89 44 24 10          	mov    %eax,0x10(%esp)
f010079e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01007a1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007a5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01007a8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007ac:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01007af:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007b3:	c7 04 24 a4 40 10 f0 	movl   $0xf01040a4,(%esp)
f01007ba:	e8 1f 26 00 00       	call   f0102dde <cprintf>
		ebp = (int*)*ebp;
f01007bf:	8b 1b                	mov    (%ebx),%ebx
{
	// Your code here.
	struct Eipdebuginfo info;
	int *ebp = (int*)read_ebp();
	cprintf("Stack backtrace:\n");
	while (ebp != 0)
f01007c1:	85 db                	test   %ebx,%ebx
f01007c3:	0f 85 7b ff ff ff    	jne    f0100744 <mon_backtrace+0x1b>
		debuginfo_eip(*(ebp+1), &info);
		cprintf("       %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, *(ebp+1)-info.eip_fn_addr);
		ebp = (int*)*ebp;
	}
	return 0;
}
f01007c9:	b8 00 00 00 00       	mov    $0x0,%eax
f01007ce:	83 c4 40             	add    $0x40,%esp
f01007d1:	5b                   	pop    %ebx
f01007d2:	5e                   	pop    %esi
f01007d3:	5d                   	pop    %ebp
f01007d4:	c3                   	ret    

f01007d5 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007d5:	55                   	push   %ebp
f01007d6:	89 e5                	mov    %esp,%ebp
f01007d8:	57                   	push   %edi
f01007d9:	56                   	push   %esi
f01007da:	53                   	push   %ebx
f01007db:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;
	cprintf("Welcome to the JOS kernel monitor!\n");
f01007de:	c7 04 24 4c 42 10 f0 	movl   $0xf010424c,(%esp)
f01007e5:	e8 f4 25 00 00       	call   f0102dde <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007ea:	c7 04 24 70 42 10 f0 	movl   $0xf0104270,(%esp)
f01007f1:	e8 e8 25 00 00       	call   f0102dde <cprintf>


	while (1) {
		buf = readline("K> ");
f01007f6:	c7 04 24 bb 40 10 f0 	movl   $0xf01040bb,(%esp)
f01007fd:	e8 ae 2e 00 00       	call   f01036b0 <readline>
f0100802:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100804:	85 c0                	test   %eax,%eax
f0100806:	74 ee                	je     f01007f6 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100808:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010080f:	be 00 00 00 00       	mov    $0x0,%esi
f0100814:	eb 06                	jmp    f010081c <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100816:	c6 03 00             	movb   $0x0,(%ebx)
f0100819:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010081c:	0f b6 03             	movzbl (%ebx),%eax
f010081f:	84 c0                	test   %al,%al
f0100821:	74 63                	je     f0100886 <monitor+0xb1>
f0100823:	0f be c0             	movsbl %al,%eax
f0100826:	89 44 24 04          	mov    %eax,0x4(%esp)
f010082a:	c7 04 24 bf 40 10 f0 	movl   $0xf01040bf,(%esp)
f0100831:	e8 90 30 00 00       	call   f01038c6 <strchr>
f0100836:	85 c0                	test   %eax,%eax
f0100838:	75 dc                	jne    f0100816 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f010083a:	80 3b 00             	cmpb   $0x0,(%ebx)
f010083d:	74 47                	je     f0100886 <monitor+0xb1>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010083f:	83 fe 0f             	cmp    $0xf,%esi
f0100842:	75 16                	jne    f010085a <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100844:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010084b:	00 
f010084c:	c7 04 24 c4 40 10 f0 	movl   $0xf01040c4,(%esp)
f0100853:	e8 86 25 00 00       	call   f0102dde <cprintf>
f0100858:	eb 9c                	jmp    f01007f6 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f010085a:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010085e:	83 c6 01             	add    $0x1,%esi
f0100861:	eb 03                	jmp    f0100866 <monitor+0x91>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100863:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100866:	0f b6 03             	movzbl (%ebx),%eax
f0100869:	84 c0                	test   %al,%al
f010086b:	74 af                	je     f010081c <monitor+0x47>
f010086d:	0f be c0             	movsbl %al,%eax
f0100870:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100874:	c7 04 24 bf 40 10 f0 	movl   $0xf01040bf,(%esp)
f010087b:	e8 46 30 00 00       	call   f01038c6 <strchr>
f0100880:	85 c0                	test   %eax,%eax
f0100882:	74 df                	je     f0100863 <monitor+0x8e>
f0100884:	eb 96                	jmp    f010081c <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f0100886:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010088d:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010088e:	85 f6                	test   %esi,%esi
f0100890:	0f 84 60 ff ff ff    	je     f01007f6 <monitor+0x21>
f0100896:	bb 00 43 10 f0       	mov    $0xf0104300,%ebx
f010089b:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008a0:	8b 03                	mov    (%ebx),%eax
f01008a2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008a6:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008a9:	89 04 24             	mov    %eax,(%esp)
f01008ac:	e8 b6 2f 00 00       	call   f0103867 <strcmp>
f01008b1:	85 c0                	test   %eax,%eax
f01008b3:	75 24                	jne    f01008d9 <monitor+0x104>
			return commands[i].func(argc, argv, tf);
f01008b5:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01008b8:	8b 55 08             	mov    0x8(%ebp),%edx
f01008bb:	89 54 24 08          	mov    %edx,0x8(%esp)
f01008bf:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008c2:	89 54 24 04          	mov    %edx,0x4(%esp)
f01008c6:	89 34 24             	mov    %esi,(%esp)
f01008c9:	ff 14 85 08 43 10 f0 	call   *-0xfefbcf8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008d0:	85 c0                	test   %eax,%eax
f01008d2:	78 28                	js     f01008fc <monitor+0x127>
f01008d4:	e9 1d ff ff ff       	jmp    f01007f6 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01008d9:	83 c7 01             	add    $0x1,%edi
f01008dc:	83 c3 0c             	add    $0xc,%ebx
f01008df:	83 ff 03             	cmp    $0x3,%edi
f01008e2:	75 bc                	jne    f01008a0 <monitor+0xcb>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008e4:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008eb:	c7 04 24 e1 40 10 f0 	movl   $0xf01040e1,(%esp)
f01008f2:	e8 e7 24 00 00       	call   f0102dde <cprintf>
f01008f7:	e9 fa fe ff ff       	jmp    f01007f6 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008fc:	83 c4 5c             	add    $0x5c,%esp
f01008ff:	5b                   	pop    %ebx
f0100900:	5e                   	pop    %esi
f0100901:	5f                   	pop    %edi
f0100902:	5d                   	pop    %ebp
f0100903:	c3                   	ret    

f0100904 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100904:	55                   	push   %ebp
f0100905:	89 e5                	mov    %esp,%ebp
f0100907:	83 ec 18             	sub    $0x18,%esp
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f010090a:	89 d1                	mov    %edx,%ecx
f010090c:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f010090f:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
		return ~0;
f0100912:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100917:	f6 c1 01             	test   $0x1,%cl
f010091a:	74 57                	je     f0100973 <check_va2pa+0x6f>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f010091c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100922:	89 c8                	mov    %ecx,%eax
f0100924:	c1 e8 0c             	shr    $0xc,%eax
f0100927:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f010092d:	72 20                	jb     f010094f <check_va2pa+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010092f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100933:	c7 44 24 08 24 43 10 	movl   $0xf0104324,0x8(%esp)
f010093a:	f0 
f010093b:	c7 44 24 04 db 02 00 	movl   $0x2db,0x4(%esp)
f0100942:	00 
f0100943:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f010094a:	e8 45 f7 ff ff       	call   f0100094 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f010094f:	c1 ea 0c             	shr    $0xc,%edx
f0100952:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100958:	8b 84 91 00 00 00 f0 	mov    -0x10000000(%ecx,%edx,4),%eax
f010095f:	89 c2                	mov    %eax,%edx
f0100961:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100964:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100969:	85 d2                	test   %edx,%edx
f010096b:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100970:	0f 44 c2             	cmove  %edx,%eax
}
f0100973:	c9                   	leave  
f0100974:	c3                   	ret    

f0100975 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100975:	55                   	push   %ebp
f0100976:	89 e5                	mov    %esp,%ebp
f0100978:	83 ec 18             	sub    $0x18,%esp
f010097b:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f010097d:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100984:	75 0f                	jne    f0100995 <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100986:	b8 6f 89 11 f0       	mov    $0xf011896f,%eax
f010098b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100990:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100995:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
	if (n > 0)
f010099a:	85 d2                	test   %edx,%edx
f010099c:	74 42                	je     f01009e0 <boot_alloc+0x6b>
	{
		nextfree = ROUNDUP(nextfree+n, PGSIZE);
f010099e:	8d 94 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edx
f01009a5:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009ab:	89 15 3c 75 11 f0    	mov    %edx,0xf011753c
		if ((uint32_t)nextfree-KERNBASE > npages*PGSIZE)
f01009b1:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f01009b7:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f01009bd:	c1 e1 0c             	shl    $0xc,%ecx
f01009c0:	39 ca                	cmp    %ecx,%edx
f01009c2:	76 1c                	jbe    f01009e0 <boot_alloc+0x6b>
			panic("Out of memory.\n");
f01009c4:	c7 44 24 08 a8 4a 10 	movl   $0xf0104aa8,0x8(%esp)
f01009cb:	f0 
f01009cc:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
f01009d3:	00 
f01009d4:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01009db:	e8 b4 f6 ff ff       	call   f0100094 <_panic>
	}
	return result;
}
f01009e0:	c9                   	leave  
f01009e1:	c3                   	ret    

f01009e2 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01009e2:	55                   	push   %ebp
f01009e3:	89 e5                	mov    %esp,%ebp
f01009e5:	83 ec 18             	sub    $0x18,%esp
f01009e8:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f01009eb:	89 75 fc             	mov    %esi,-0x4(%ebp)
f01009ee:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01009f0:	89 04 24             	mov    %eax,(%esp)
f01009f3:	e8 78 23 00 00       	call   f0102d70 <mc146818_read>
f01009f8:	89 c6                	mov    %eax,%esi
f01009fa:	83 c3 01             	add    $0x1,%ebx
f01009fd:	89 1c 24             	mov    %ebx,(%esp)
f0100a00:	e8 6b 23 00 00       	call   f0102d70 <mc146818_read>
f0100a05:	c1 e0 08             	shl    $0x8,%eax
f0100a08:	09 f0                	or     %esi,%eax
}
f0100a0a:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100a0d:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100a10:	89 ec                	mov    %ebp,%esp
f0100a12:	5d                   	pop    %ebp
f0100a13:	c3                   	ret    

f0100a14 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a14:	55                   	push   %ebp
f0100a15:	89 e5                	mov    %esp,%ebp
f0100a17:	57                   	push   %edi
f0100a18:	56                   	push   %esi
f0100a19:	53                   	push   %ebx
f0100a1a:	83 ec 4c             	sub    $0x4c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a1d:	3c 01                	cmp    $0x1,%al
f0100a1f:	19 f6                	sbb    %esi,%esi
f0100a21:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100a27:	83 c6 01             	add    $0x1,%esi
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100a2a:	8b 15 40 75 11 f0    	mov    0xf0117540,%edx
f0100a30:	85 d2                	test   %edx,%edx
f0100a32:	75 1c                	jne    f0100a50 <check_page_free_list+0x3c>
		panic("'page_free_list' is a null pointer!");
f0100a34:	c7 44 24 08 48 43 10 	movl   $0xf0104348,0x8(%esp)
f0100a3b:	f0 
f0100a3c:	c7 44 24 04 1c 02 00 	movl   $0x21c,0x4(%esp)
f0100a43:	00 
f0100a44:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0100a4b:	e8 44 f6 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
f0100a50:	84 c0                	test   %al,%al
f0100a52:	74 4b                	je     f0100a9f <check_page_free_list+0x8b>
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a54:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0100a57:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100a5a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100a5d:	89 45 dc             	mov    %eax,-0x24(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a60:	89 d0                	mov    %edx,%eax
f0100a62:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100a68:	c1 e0 09             	shl    $0x9,%eax
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a6b:	c1 e8 16             	shr    $0x16,%eax
f0100a6e:	39 c6                	cmp    %eax,%esi
f0100a70:	0f 96 c0             	setbe  %al
f0100a73:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100a76:	8b 4c 85 d8          	mov    -0x28(%ebp,%eax,4),%ecx
f0100a7a:	89 11                	mov    %edx,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a7c:	89 54 85 d8          	mov    %edx,-0x28(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a80:	8b 12                	mov    (%edx),%edx
f0100a82:	85 d2                	test   %edx,%edx
f0100a84:	75 da                	jne    f0100a60 <check_page_free_list+0x4c>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a86:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100a89:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a8f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a92:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100a95:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a97:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a9a:	a3 40 75 11 f0       	mov    %eax,0xf0117540
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a9f:	8b 1d 40 75 11 f0    	mov    0xf0117540,%ebx
f0100aa5:	eb 63                	jmp    f0100b0a <check_page_free_list+0xf6>
f0100aa7:	89 d8                	mov    %ebx,%eax
f0100aa9:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100aaf:	c1 f8 03             	sar    $0x3,%eax
f0100ab2:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100ab5:	89 c2                	mov    %eax,%edx
f0100ab7:	c1 ea 16             	shr    $0x16,%edx
f0100aba:	39 d6                	cmp    %edx,%esi
f0100abc:	76 4a                	jbe    f0100b08 <check_page_free_list+0xf4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100abe:	89 c2                	mov    %eax,%edx
f0100ac0:	c1 ea 0c             	shr    $0xc,%edx
f0100ac3:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100ac9:	72 20                	jb     f0100aeb <check_page_free_list+0xd7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100acb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100acf:	c7 44 24 08 24 43 10 	movl   $0xf0104324,0x8(%esp)
f0100ad6:	f0 
f0100ad7:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100ade:	00 
f0100adf:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0100ae6:	e8 a9 f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100aeb:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100af2:	00 
f0100af3:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100afa:	00 
	return (void *)(pa + KERNBASE);
f0100afb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b00:	89 04 24             	mov    %eax,(%esp)
f0100b03:	e8 fb 2d 00 00       	call   f0103903 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b08:	8b 1b                	mov    (%ebx),%ebx
f0100b0a:	85 db                	test   %ebx,%ebx
f0100b0c:	75 99                	jne    f0100aa7 <check_page_free_list+0x93>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b0e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b13:	e8 5d fe ff ff       	call   f0100975 <boot_alloc>
f0100b18:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b1b:	8b 15 40 75 11 f0    	mov    0xf0117540,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b21:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
		assert(pp < pages + npages);
f0100b27:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0100b2c:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b2f:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100b32:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b35:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b38:	be 00 00 00 00       	mov    $0x0,%esi
f0100b3d:	89 4d c0             	mov    %ecx,-0x40(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b40:	e9 97 01 00 00       	jmp    f0100cdc <check_page_free_list+0x2c8>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b45:	3b 55 c0             	cmp    -0x40(%ebp),%edx
f0100b48:	73 24                	jae    f0100b6e <check_page_free_list+0x15a>
f0100b4a:	c7 44 24 0c c6 4a 10 	movl   $0xf0104ac6,0xc(%esp)
f0100b51:	f0 
f0100b52:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0100b59:	f0 
f0100b5a:	c7 44 24 04 36 02 00 	movl   $0x236,0x4(%esp)
f0100b61:	00 
f0100b62:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0100b69:	e8 26 f5 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100b6e:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100b71:	72 24                	jb     f0100b97 <check_page_free_list+0x183>
f0100b73:	c7 44 24 0c e7 4a 10 	movl   $0xf0104ae7,0xc(%esp)
f0100b7a:	f0 
f0100b7b:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0100b82:	f0 
f0100b83:	c7 44 24 04 37 02 00 	movl   $0x237,0x4(%esp)
f0100b8a:	00 
f0100b8b:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0100b92:	e8 fd f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b97:	89 d0                	mov    %edx,%eax
f0100b99:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100b9c:	a8 07                	test   $0x7,%al
f0100b9e:	74 24                	je     f0100bc4 <check_page_free_list+0x1b0>
f0100ba0:	c7 44 24 0c 6c 43 10 	movl   $0xf010436c,0xc(%esp)
f0100ba7:	f0 
f0100ba8:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0100baf:	f0 
f0100bb0:	c7 44 24 04 38 02 00 	movl   $0x238,0x4(%esp)
f0100bb7:	00 
f0100bb8:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0100bbf:	e8 d0 f4 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100bc4:	c1 f8 03             	sar    $0x3,%eax
f0100bc7:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100bca:	85 c0                	test   %eax,%eax
f0100bcc:	75 24                	jne    f0100bf2 <check_page_free_list+0x1de>
f0100bce:	c7 44 24 0c fb 4a 10 	movl   $0xf0104afb,0xc(%esp)
f0100bd5:	f0 
f0100bd6:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0100bdd:	f0 
f0100bde:	c7 44 24 04 3b 02 00 	movl   $0x23b,0x4(%esp)
f0100be5:	00 
f0100be6:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0100bed:	e8 a2 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bf2:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bf7:	75 24                	jne    f0100c1d <check_page_free_list+0x209>
f0100bf9:	c7 44 24 0c 0c 4b 10 	movl   $0xf0104b0c,0xc(%esp)
f0100c00:	f0 
f0100c01:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0100c08:	f0 
f0100c09:	c7 44 24 04 3c 02 00 	movl   $0x23c,0x4(%esp)
f0100c10:	00 
f0100c11:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0100c18:	e8 77 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c1d:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c22:	75 24                	jne    f0100c48 <check_page_free_list+0x234>
f0100c24:	c7 44 24 0c a0 43 10 	movl   $0xf01043a0,0xc(%esp)
f0100c2b:	f0 
f0100c2c:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0100c33:	f0 
f0100c34:	c7 44 24 04 3d 02 00 	movl   $0x23d,0x4(%esp)
f0100c3b:	00 
f0100c3c:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0100c43:	e8 4c f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c48:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c4d:	75 24                	jne    f0100c73 <check_page_free_list+0x25f>
f0100c4f:	c7 44 24 0c 25 4b 10 	movl   $0xf0104b25,0xc(%esp)
f0100c56:	f0 
f0100c57:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0100c5e:	f0 
f0100c5f:	c7 44 24 04 3e 02 00 	movl   $0x23e,0x4(%esp)
f0100c66:	00 
f0100c67:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0100c6e:	e8 21 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100c73:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100c78:	76 58                	jbe    f0100cd2 <check_page_free_list+0x2be>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c7a:	89 c1                	mov    %eax,%ecx
f0100c7c:	c1 e9 0c             	shr    $0xc,%ecx
f0100c7f:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100c82:	77 20                	ja     f0100ca4 <check_page_free_list+0x290>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c84:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100c88:	c7 44 24 08 24 43 10 	movl   $0xf0104324,0x8(%esp)
f0100c8f:	f0 
f0100c90:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100c97:	00 
f0100c98:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0100c9f:	e8 f0 f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100ca4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ca9:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0100cac:	76 29                	jbe    f0100cd7 <check_page_free_list+0x2c3>
f0100cae:	c7 44 24 0c c4 43 10 	movl   $0xf01043c4,0xc(%esp)
f0100cb5:	f0 
f0100cb6:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0100cbd:	f0 
f0100cbe:	c7 44 24 04 3f 02 00 	movl   $0x23f,0x4(%esp)
f0100cc5:	00 
f0100cc6:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0100ccd:	e8 c2 f3 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100cd2:	83 c6 01             	add    $0x1,%esi
f0100cd5:	eb 03                	jmp    f0100cda <check_page_free_list+0x2c6>
		else
			++nfree_extmem;
f0100cd7:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cda:	8b 12                	mov    (%edx),%edx
f0100cdc:	85 d2                	test   %edx,%edx
f0100cde:	0f 85 61 fe ff ff    	jne    f0100b45 <check_page_free_list+0x131>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100ce4:	85 f6                	test   %esi,%esi
f0100ce6:	7f 24                	jg     f0100d0c <check_page_free_list+0x2f8>
f0100ce8:	c7 44 24 0c 3f 4b 10 	movl   $0xf0104b3f,0xc(%esp)
f0100cef:	f0 
f0100cf0:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0100cf7:	f0 
f0100cf8:	c7 44 24 04 47 02 00 	movl   $0x247,0x4(%esp)
f0100cff:	00 
f0100d00:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0100d07:	e8 88 f3 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100d0c:	85 db                	test   %ebx,%ebx
f0100d0e:	7f 24                	jg     f0100d34 <check_page_free_list+0x320>
f0100d10:	c7 44 24 0c 51 4b 10 	movl   $0xf0104b51,0xc(%esp)
f0100d17:	f0 
f0100d18:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0100d1f:	f0 
f0100d20:	c7 44 24 04 48 02 00 	movl   $0x248,0x4(%esp)
f0100d27:	00 
f0100d28:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0100d2f:	e8 60 f3 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100d34:	c7 04 24 0c 44 10 f0 	movl   $0xf010440c,(%esp)
f0100d3b:	e8 9e 20 00 00       	call   f0102dde <cprintf>
}
f0100d40:	83 c4 4c             	add    $0x4c,%esp
f0100d43:	5b                   	pop    %ebx
f0100d44:	5e                   	pop    %esi
f0100d45:	5f                   	pop    %edi
f0100d46:	5d                   	pop    %ebp
f0100d47:	c3                   	ret    

f0100d48 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100d48:	55                   	push   %ebp
f0100d49:	89 e5                	mov    %esp,%ebp
f0100d4b:	56                   	push   %esi
f0100d4c:	53                   	push   %ebx
f0100d4d:	83 ec 10             	sub    $0x10,%esp
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	size_t low_pgnum = PGNUM(IOPHYSMEM);
	size_t high_pgnum = PGNUM(PADDR(boot_alloc(0)));
f0100d50:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d55:	e8 1b fc ff ff       	call   f0100975 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100d5a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100d5f:	77 20                	ja     f0100d81 <page_init+0x39>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100d61:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d65:	c7 44 24 08 30 44 10 	movl   $0xf0104430,0x8(%esp)
f0100d6c:	f0 
f0100d6d:	c7 44 24 04 0e 01 00 	movl   $0x10e,0x4(%esp)
f0100d74:	00 
f0100d75:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0100d7c:	e8 13 f3 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100d81:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f0100d87:	c1 eb 0c             	shr    $0xc,%ebx
f0100d8a:	a1 40 75 11 f0       	mov    0xf0117540,%eax
	for (i = 0; i < npages; i++) 
f0100d8f:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d94:	eb 4d                	jmp    f0100de3 <page_init+0x9b>
	{
		if (i == 0 || (i >= low_pgnum && i < high_pgnum))
f0100d96:	85 d2                	test   %edx,%edx
f0100d98:	74 0c                	je     f0100da6 <page_init+0x5e>
f0100d9a:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f0100da0:	76 1f                	jbe    f0100dc1 <page_init+0x79>
f0100da2:	39 da                	cmp    %ebx,%edx
f0100da4:	73 1b                	jae    f0100dc1 <page_init+0x79>
		{
			pages[i].pp_ref = 1;
f0100da6:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f0100dad:	03 0d 6c 79 11 f0    	add    0xf011796c,%ecx
f0100db3:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
			pages[i].pp_link = NULL;
f0100db9:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
			continue;
f0100dbf:	eb 1f                	jmp    f0100de0 <page_init+0x98>
		}
		else
		{
			pages[i].pp_ref = 0;
f0100dc1:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f0100dc8:	89 ce                	mov    %ecx,%esi
f0100dca:	03 35 6c 79 11 f0    	add    0xf011796c,%esi
f0100dd0:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
			pages[i].pp_link = page_free_list;
f0100dd6:	89 06                	mov    %eax,(%esi)
			page_free_list = &pages[i];
f0100dd8:	89 c8                	mov    %ecx,%eax
f0100dda:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	size_t low_pgnum = PGNUM(IOPHYSMEM);
	size_t high_pgnum = PGNUM(PADDR(boot_alloc(0)));
	for (i = 0; i < npages; i++) 
f0100de0:	83 c2 01             	add    $0x1,%edx
f0100de3:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100de9:	72 ab                	jb     f0100d96 <page_init+0x4e>
f0100deb:	a3 40 75 11 f0       	mov    %eax,0xf0117540
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0100df0:	83 c4 10             	add    $0x10,%esp
f0100df3:	5b                   	pop    %ebx
f0100df4:	5e                   	pop    %esi
f0100df5:	5d                   	pop    %ebp
f0100df6:	c3                   	ret    

f0100df7 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100df7:	55                   	push   %ebp
f0100df8:	89 e5                	mov    %esp,%ebp
f0100dfa:	53                   	push   %ebx
f0100dfb:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	struct PageInfo *pp;
	if (page_free_list == NULL)
f0100dfe:	8b 1d 40 75 11 f0    	mov    0xf0117540,%ebx
f0100e04:	85 db                	test   %ebx,%ebx
f0100e06:	74 6b                	je     f0100e73 <page_alloc+0x7c>
		pp = NULL;
	else
	{
		pp = page_free_list;
		page_free_list = pp->pp_link;
f0100e08:	8b 03                	mov    (%ebx),%eax
f0100e0a:	a3 40 75 11 f0       	mov    %eax,0xf0117540
		pp->pp_link = NULL;
f0100e0f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		if (alloc_flags & ALLOC_ZERO)
f0100e15:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100e19:	74 58                	je     f0100e73 <page_alloc+0x7c>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e1b:	89 d8                	mov    %ebx,%eax
f0100e1d:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100e23:	c1 f8 03             	sar    $0x3,%eax
f0100e26:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e29:	89 c2                	mov    %eax,%edx
f0100e2b:	c1 ea 0c             	shr    $0xc,%edx
f0100e2e:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100e34:	72 20                	jb     f0100e56 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e36:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e3a:	c7 44 24 08 24 43 10 	movl   $0xf0104324,0x8(%esp)
f0100e41:	f0 
f0100e42:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100e49:	00 
f0100e4a:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0100e51:	e8 3e f2 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0, PGSIZE);
f0100e56:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100e5d:	00 
f0100e5e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100e65:	00 
	return (void *)(pa + KERNBASE);
f0100e66:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e6b:	89 04 24             	mov    %eax,(%esp)
f0100e6e:	e8 90 2a 00 00       	call   f0103903 <memset>
	}
	return pp;
}
f0100e73:	89 d8                	mov    %ebx,%eax
f0100e75:	83 c4 14             	add    $0x14,%esp
f0100e78:	5b                   	pop    %ebx
f0100e79:	5d                   	pop    %ebp
f0100e7a:	c3                   	ret    

f0100e7b <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100e7b:	55                   	push   %ebp
f0100e7c:	89 e5                	mov    %esp,%ebp
f0100e7e:	83 ec 18             	sub    $0x18,%esp
f0100e81:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref || pp->pp_link)
f0100e84:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e89:	75 05                	jne    f0100e90 <page_free+0x15>
f0100e8b:	83 38 00             	cmpl   $0x0,(%eax)
f0100e8e:	74 1c                	je     f0100eac <page_free+0x31>
		panic("error in page_free!\n");
f0100e90:	c7 44 24 08 62 4b 10 	movl   $0xf0104b62,0x8(%esp)
f0100e97:	f0 
f0100e98:	c7 44 24 04 49 01 00 	movl   $0x149,0x4(%esp)
f0100e9f:	00 
f0100ea0:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0100ea7:	e8 e8 f1 ff ff       	call   f0100094 <_panic>
	pp->pp_link = page_free_list;
f0100eac:	8b 15 40 75 11 f0    	mov    0xf0117540,%edx
f0100eb2:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100eb4:	a3 40 75 11 f0       	mov    %eax,0xf0117540
}
f0100eb9:	c9                   	leave  
f0100eba:	c3                   	ret    

f0100ebb <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100ebb:	55                   	push   %ebp
f0100ebc:	89 e5                	mov    %esp,%ebp
f0100ebe:	83 ec 18             	sub    $0x18,%esp
f0100ec1:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100ec4:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0100ec8:	83 ea 01             	sub    $0x1,%edx
f0100ecb:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100ecf:	66 85 d2             	test   %dx,%dx
f0100ed2:	75 08                	jne    f0100edc <page_decref+0x21>
		page_free(pp);
f0100ed4:	89 04 24             	mov    %eax,(%esp)
f0100ed7:	e8 9f ff ff ff       	call   f0100e7b <page_free>
}
f0100edc:	c9                   	leave  
f0100edd:	c3                   	ret    

f0100ede <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100ede:	55                   	push   %ebp
f0100edf:	89 e5                	mov    %esp,%ebp
f0100ee1:	56                   	push   %esi
f0100ee2:	53                   	push   %ebx
f0100ee3:	83 ec 10             	sub    $0x10,%esp
f0100ee6:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pde_t *pdentry = pgdir + PDX(va);
f0100ee9:	89 f3                	mov    %esi,%ebx
f0100eeb:	c1 eb 16             	shr    $0x16,%ebx
f0100eee:	c1 e3 02             	shl    $0x2,%ebx
f0100ef1:	03 5d 08             	add    0x8(%ebp),%ebx
	if (*pdentry & PTE_P)
f0100ef4:	8b 03                	mov    (%ebx),%eax
f0100ef6:	a8 01                	test   $0x1,%al
f0100ef8:	74 47                	je     f0100f41 <pgdir_walk+0x63>
	{
		void *pt = (void*)KADDR(PTE_ADDR(*pdentry));
f0100efa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eff:	89 c2                	mov    %eax,%edx
f0100f01:	c1 ea 0c             	shr    $0xc,%edx
f0100f04:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100f0a:	72 20                	jb     f0100f2c <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f0c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f10:	c7 44 24 08 24 43 10 	movl   $0xf0104324,0x8(%esp)
f0100f17:	f0 
f0100f18:	c7 44 24 04 76 01 00 	movl   $0x176,0x4(%esp)
f0100f1f:	00 
f0100f20:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0100f27:	e8 68 f1 ff ff       	call   f0100094 <_panic>
		return (pte_t*)pt + PTX(va);
f0100f2c:	c1 ee 0a             	shr    $0xa,%esi
f0100f2f:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100f35:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100f3c:	e9 85 00 00 00       	jmp    f0100fc6 <pgdir_walk+0xe8>
	}
	else
	{
		if (create == 0)
f0100f41:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100f45:	74 73                	je     f0100fba <pgdir_walk+0xdc>
			return NULL;
		struct PageInfo *newpg = page_alloc(1);
f0100f47:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100f4e:	e8 a4 fe ff ff       	call   f0100df7 <page_alloc>
		if (newpg == NULL)
f0100f53:	85 c0                	test   %eax,%eax
f0100f55:	74 6a                	je     f0100fc1 <pgdir_walk+0xe3>
			return NULL;
		newpg->pp_ref++;
f0100f57:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f5c:	89 c2                	mov    %eax,%edx
f0100f5e:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0100f64:	c1 fa 03             	sar    $0x3,%edx
f0100f67:	c1 e2 0c             	shl    $0xc,%edx
		*pdentry = page2pa(newpg) | PTE_W | PTE_P | PTE_U;
f0100f6a:	83 ca 07             	or     $0x7,%edx
f0100f6d:	89 13                	mov    %edx,(%ebx)
f0100f6f:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100f75:	c1 f8 03             	sar    $0x3,%eax
f0100f78:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f7b:	89 c2                	mov    %eax,%edx
f0100f7d:	c1 ea 0c             	shr    $0xc,%edx
f0100f80:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100f86:	72 20                	jb     f0100fa8 <pgdir_walk+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f88:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f8c:	c7 44 24 08 24 43 10 	movl   $0xf0104324,0x8(%esp)
f0100f93:	f0 
f0100f94:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100f9b:	00 
f0100f9c:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0100fa3:	e8 ec f0 ff ff       	call   f0100094 <_panic>
		return (pte_t*)page2kva(newpg) + PTX(va);
f0100fa8:	c1 ee 0a             	shr    $0xa,%esi
f0100fab:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100fb1:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100fb8:	eb 0c                	jmp    f0100fc6 <pgdir_walk+0xe8>
		return (pte_t*)pt + PTX(va);
	}
	else
	{
		if (create == 0)
			return NULL;
f0100fba:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fbf:	eb 05                	jmp    f0100fc6 <pgdir_walk+0xe8>
		struct PageInfo *newpg = page_alloc(1);
		if (newpg == NULL)
			return NULL;
f0100fc1:	b8 00 00 00 00       	mov    $0x0,%eax
		newpg->pp_ref++;
		*pdentry = page2pa(newpg) | PTE_W | PTE_P | PTE_U;
		return (pte_t*)page2kva(newpg) + PTX(va);
	}
}
f0100fc6:	83 c4 10             	add    $0x10,%esp
f0100fc9:	5b                   	pop    %ebx
f0100fca:	5e                   	pop    %esi
f0100fcb:	5d                   	pop    %ebp
f0100fcc:	c3                   	ret    

f0100fcd <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100fcd:	55                   	push   %ebp
f0100fce:	89 e5                	mov    %esp,%ebp
f0100fd0:	57                   	push   %edi
f0100fd1:	56                   	push   %esi
f0100fd2:	53                   	push   %ebx
f0100fd3:	83 ec 2c             	sub    $0x2c,%esp
f0100fd6:	89 c7                	mov    %eax,%edi
f0100fd8:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100fdb:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	for (size_t bytes = 0; bytes < size; bytes+=PGSIZE, pa+=PGSIZE, va+=PGSIZE)
f0100fde:	bb 00 00 00 00       	mov    $0x0,%ebx
	{
		pte_t *ptentry = pgdir_walk(pgdir, (void*)va, 1);
		*ptentry = (pa | perm | PTE_P);
f0100fe3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fe6:	83 c8 01             	or     $0x1,%eax
f0100fe9:	89 45 dc             	mov    %eax,-0x24(%ebp)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	for (size_t bytes = 0; bytes < size; bytes+=PGSIZE, pa+=PGSIZE, va+=PGSIZE)
f0100fec:	eb 24                	jmp    f0101012 <boot_map_region+0x45>
	{
		pte_t *ptentry = pgdir_walk(pgdir, (void*)va, 1);
f0100fee:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0100ff5:	00 
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f0100ff6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ff9:	01 d8                	add    %ebx,%eax
{
	// Fill this function in
	for (size_t bytes = 0; bytes < size; bytes+=PGSIZE, pa+=PGSIZE, va+=PGSIZE)
	{
		pte_t *ptentry = pgdir_walk(pgdir, (void*)va, 1);
f0100ffb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100fff:	89 3c 24             	mov    %edi,(%esp)
f0101002:	e8 d7 fe ff ff       	call   f0100ede <pgdir_walk>
		*ptentry = (pa | perm | PTE_P);
f0101007:	0b 75 dc             	or     -0x24(%ebp),%esi
f010100a:	89 30                	mov    %esi,(%eax)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	for (size_t bytes = 0; bytes < size; bytes+=PGSIZE, pa+=PGSIZE, va+=PGSIZE)
f010100c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f0101012:	8b 75 08             	mov    0x8(%ebp),%esi
f0101015:	01 de                	add    %ebx,%esi
{
	// Fill this function in
	for (size_t bytes = 0; bytes < size; bytes+=PGSIZE, pa+=PGSIZE, va+=PGSIZE)
f0101017:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f010101a:	72 d2                	jb     f0100fee <boot_map_region+0x21>
	{
		pte_t *ptentry = pgdir_walk(pgdir, (void*)va, 1);
		*ptentry = (pa | perm | PTE_P);
	}
}
f010101c:	83 c4 2c             	add    $0x2c,%esp
f010101f:	5b                   	pop    %ebx
f0101020:	5e                   	pop    %esi
f0101021:	5f                   	pop    %edi
f0101022:	5d                   	pop    %ebp
f0101023:	c3                   	ret    

f0101024 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101024:	55                   	push   %ebp
f0101025:	89 e5                	mov    %esp,%ebp
f0101027:	53                   	push   %ebx
f0101028:	83 ec 14             	sub    $0x14,%esp
f010102b:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, (void*)va, 0);
f010102e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101035:	00 
f0101036:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101039:	89 44 24 04          	mov    %eax,0x4(%esp)
f010103d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101040:	89 04 24             	mov    %eax,(%esp)
f0101043:	e8 96 fe ff ff       	call   f0100ede <pgdir_walk>
	if (pte_store)
f0101048:	85 db                	test   %ebx,%ebx
f010104a:	74 02                	je     f010104e <page_lookup+0x2a>
		*pte_store = pte;
f010104c:	89 03                	mov    %eax,(%ebx)
	if (pte && (*pte & PTE_P))
f010104e:	85 c0                	test   %eax,%eax
f0101050:	74 38                	je     f010108a <page_lookup+0x66>
f0101052:	8b 00                	mov    (%eax),%eax
f0101054:	a8 01                	test   $0x1,%al
f0101056:	74 39                	je     f0101091 <page_lookup+0x6d>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101058:	c1 e8 0c             	shr    $0xc,%eax
f010105b:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0101061:	72 1c                	jb     f010107f <page_lookup+0x5b>
		panic("pa2page called with invalid pa");
f0101063:	c7 44 24 08 54 44 10 	movl   $0xf0104454,0x8(%esp)
f010106a:	f0 
f010106b:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f0101072:	00 
f0101073:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f010107a:	e8 15 f0 ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f010107f:	c1 e0 03             	shl    $0x3,%eax
f0101082:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
		return pa2page(PTE_ADDR(*pte));
f0101088:	eb 0c                	jmp    f0101096 <page_lookup+0x72>
	return NULL;
f010108a:	b8 00 00 00 00       	mov    $0x0,%eax
f010108f:	eb 05                	jmp    f0101096 <page_lookup+0x72>
f0101091:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101096:	83 c4 14             	add    $0x14,%esp
f0101099:	5b                   	pop    %ebx
f010109a:	5d                   	pop    %ebp
f010109b:	c3                   	ret    

f010109c <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010109c:	55                   	push   %ebp
f010109d:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010109f:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010a2:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01010a5:	5d                   	pop    %ebp
f01010a6:	c3                   	ret    

f01010a7 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01010a7:	55                   	push   %ebp
f01010a8:	89 e5                	mov    %esp,%ebp
f01010aa:	83 ec 28             	sub    $0x28,%esp
f01010ad:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f01010b0:	89 75 fc             	mov    %esi,-0x4(%ebp)
f01010b3:	8b 75 08             	mov    0x8(%ebp),%esi
f01010b6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	struct PageInfo *oldpg = page_lookup(pgdir, va, &pte);
f01010b9:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01010bc:	89 44 24 08          	mov    %eax,0x8(%esp)
f01010c0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010c4:	89 34 24             	mov    %esi,(%esp)
f01010c7:	e8 58 ff ff ff       	call   f0101024 <page_lookup>
	if (oldpg)
f01010cc:	85 c0                	test   %eax,%eax
f01010ce:	74 1d                	je     f01010ed <page_remove+0x46>
	{
		page_decref(oldpg);
f01010d0:	89 04 24             	mov    %eax,(%esp)
f01010d3:	e8 e3 fd ff ff       	call   f0100ebb <page_decref>
		*pte = 0;
f01010d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01010db:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		tlb_invalidate(pgdir, va);
f01010e1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010e5:	89 34 24             	mov    %esi,(%esp)
f01010e8:	e8 af ff ff ff       	call   f010109c <tlb_invalidate>
	}
}
f01010ed:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f01010f0:	8b 75 fc             	mov    -0x4(%ebp),%esi
f01010f3:	89 ec                	mov    %ebp,%esp
f01010f5:	5d                   	pop    %ebp
f01010f6:	c3                   	ret    

f01010f7 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01010f7:	55                   	push   %ebp
f01010f8:	89 e5                	mov    %esp,%ebp
f01010fa:	83 ec 28             	sub    $0x28,%esp
f01010fd:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0101100:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101103:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101106:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101109:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *ptentry = pgdir_walk(pgdir, (void*)va, 1);
f010110c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101113:	00 
f0101114:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101118:	8b 45 08             	mov    0x8(%ebp),%eax
f010111b:	89 04 24             	mov    %eax,(%esp)
f010111e:	e8 bb fd ff ff       	call   f0100ede <pgdir_walk>
f0101123:	89 c3                	mov    %eax,%ebx
	if (ptentry == NULL)
f0101125:	85 c0                	test   %eax,%eax
f0101127:	74 66                	je     f010118f <page_insert+0x98>
		return -E_NO_MEM;
	if (*ptentry & PTE_P)
f0101129:	8b 00                	mov    (%eax),%eax
f010112b:	a8 01                	test   $0x1,%al
f010112d:	74 3c                	je     f010116b <page_insert+0x74>
	{
		if (PTE_ADDR(*ptentry) == page2pa(pp))
f010112f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101134:	89 f2                	mov    %esi,%edx
f0101136:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f010113c:	c1 fa 03             	sar    $0x3,%edx
f010113f:	c1 e2 0c             	shl    $0xc,%edx
f0101142:	39 d0                	cmp    %edx,%eax
f0101144:	75 16                	jne    f010115c <page_insert+0x65>
		{
			tlb_invalidate(pgdir, va);
f0101146:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010114a:	8b 45 08             	mov    0x8(%ebp),%eax
f010114d:	89 04 24             	mov    %eax,(%esp)
f0101150:	e8 47 ff ff ff       	call   f010109c <tlb_invalidate>
			pp->pp_ref--;
f0101155:	66 83 6e 04 01       	subw   $0x1,0x4(%esi)
f010115a:	eb 0f                	jmp    f010116b <page_insert+0x74>
		}
		else
			page_remove(pgdir, va);
f010115c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101160:	8b 45 08             	mov    0x8(%ebp),%eax
f0101163:	89 04 24             	mov    %eax,(%esp)
f0101166:	e8 3c ff ff ff       	call   f01010a7 <page_remove>
	}
	*ptentry = page2pa(pp) | perm | PTE_P;
f010116b:	8b 45 14             	mov    0x14(%ebp),%eax
f010116e:	83 c8 01             	or     $0x1,%eax
f0101171:	89 f2                	mov    %esi,%edx
f0101173:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101179:	c1 fa 03             	sar    $0x3,%edx
f010117c:	c1 e2 0c             	shl    $0xc,%edx
f010117f:	09 d0                	or     %edx,%eax
f0101181:	89 03                	mov    %eax,(%ebx)
	pp->pp_ref++;
f0101183:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	return 0;
f0101188:	b8 00 00 00 00       	mov    $0x0,%eax
f010118d:	eb 05                	jmp    f0101194 <page_insert+0x9d>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t *ptentry = pgdir_walk(pgdir, (void*)va, 1);
	if (ptentry == NULL)
		return -E_NO_MEM;
f010118f:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
			page_remove(pgdir, va);
	}
	*ptentry = page2pa(pp) | perm | PTE_P;
	pp->pp_ref++;
	return 0;
}
f0101194:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101197:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010119a:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010119d:	89 ec                	mov    %ebp,%esp
f010119f:	5d                   	pop    %ebp
f01011a0:	c3                   	ret    

f01011a1 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01011a1:	55                   	push   %ebp
f01011a2:	89 e5                	mov    %esp,%ebp
f01011a4:	57                   	push   %edi
f01011a5:	56                   	push   %esi
f01011a6:	53                   	push   %ebx
f01011a7:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f01011aa:	b8 15 00 00 00       	mov    $0x15,%eax
f01011af:	e8 2e f8 ff ff       	call   f01009e2 <nvram_read>
f01011b4:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01011b6:	b8 17 00 00 00       	mov    $0x17,%eax
f01011bb:	e8 22 f8 ff ff       	call   f01009e2 <nvram_read>
f01011c0:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01011c2:	b8 34 00 00 00       	mov    $0x34,%eax
f01011c7:	e8 16 f8 ff ff       	call   f01009e2 <nvram_read>
f01011cc:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f01011cf:	85 c0                	test   %eax,%eax
f01011d1:	74 07                	je     f01011da <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f01011d3:	05 00 40 00 00       	add    $0x4000,%eax
f01011d8:	eb 0b                	jmp    f01011e5 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f01011da:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01011e0:	85 f6                	test   %esi,%esi
f01011e2:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f01011e5:	89 c2                	mov    %eax,%edx
f01011e7:	c1 ea 02             	shr    $0x2,%edx
f01011ea:	89 15 64 79 11 f0    	mov    %edx,0xf0117964
	npages_basemem = basemem / (PGSIZE / 1024);
f01011f0:	89 da                	mov    %ebx,%edx
f01011f2:	c1 ea 02             	shr    $0x2,%edx
f01011f5:	89 15 38 75 11 f0    	mov    %edx,0xf0117538

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01011fb:	89 c2                	mov    %eax,%edx
f01011fd:	29 da                	sub    %ebx,%edx
f01011ff:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101203:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101207:	89 44 24 04          	mov    %eax,0x4(%esp)
f010120b:	c7 04 24 74 44 10 f0 	movl   $0xf0104474,(%esp)
f0101212:	e8 c7 1b 00 00       	call   f0102dde <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101217:	b8 00 10 00 00       	mov    $0x1000,%eax
f010121c:	e8 54 f7 ff ff       	call   f0100975 <boot_alloc>
f0101221:	a3 68 79 11 f0       	mov    %eax,0xf0117968
	memset(kern_pgdir, 0, PGSIZE);
f0101226:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010122d:	00 
f010122e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101235:	00 
f0101236:	89 04 24             	mov    %eax,(%esp)
f0101239:	e8 c5 26 00 00       	call   f0103903 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010123e:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101243:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101248:	77 20                	ja     f010126a <mem_init+0xc9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010124a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010124e:	c7 44 24 08 30 44 10 	movl   $0xf0104430,0x8(%esp)
f0101255:	f0 
f0101256:	c7 44 24 04 94 00 00 	movl   $0x94,0x4(%esp)
f010125d:	00 
f010125e:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101265:	e8 2a ee ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010126a:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101270:	83 ca 05             	or     $0x5,%edx
f0101273:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*)boot_alloc(npages*sizeof(struct PageInfo));
f0101279:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f010127e:	c1 e0 03             	shl    $0x3,%eax
f0101281:	e8 ef f6 ff ff       	call   f0100975 <boot_alloc>
f0101286:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
	memset(pages, 0, npages*sizeof(struct PageInfo));
f010128b:	8b 15 64 79 11 f0    	mov    0xf0117964,%edx
f0101291:	c1 e2 03             	shl    $0x3,%edx
f0101294:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101298:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010129f:	00 
f01012a0:	89 04 24             	mov    %eax,(%esp)
f01012a3:	e8 5b 26 00 00       	call   f0103903 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01012a8:	e8 9b fa ff ff       	call   f0100d48 <page_init>

	check_page_free_list(1);
f01012ad:	b8 01 00 00 00       	mov    $0x1,%eax
f01012b2:	e8 5d f7 ff ff       	call   f0100a14 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01012b7:	83 3d 6c 79 11 f0 00 	cmpl   $0x0,0xf011796c
f01012be:	75 1c                	jne    f01012dc <mem_init+0x13b>
		panic("'pages' is a null pointer!");
f01012c0:	c7 44 24 08 77 4b 10 	movl   $0xf0104b77,0x8(%esp)
f01012c7:	f0 
f01012c8:	c7 44 24 04 5b 02 00 	movl   $0x25b,0x4(%esp)
f01012cf:	00 
f01012d0:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01012d7:	e8 b8 ed ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01012dc:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f01012e1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01012e6:	eb 05                	jmp    f01012ed <mem_init+0x14c>
		++nfree;
f01012e8:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01012eb:	8b 00                	mov    (%eax),%eax
f01012ed:	85 c0                	test   %eax,%eax
f01012ef:	75 f7                	jne    f01012e8 <mem_init+0x147>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01012f1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012f8:	e8 fa fa ff ff       	call   f0100df7 <page_alloc>
f01012fd:	89 c6                	mov    %eax,%esi
f01012ff:	85 c0                	test   %eax,%eax
f0101301:	75 24                	jne    f0101327 <mem_init+0x186>
f0101303:	c7 44 24 0c 92 4b 10 	movl   $0xf0104b92,0xc(%esp)
f010130a:	f0 
f010130b:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101312:	f0 
f0101313:	c7 44 24 04 63 02 00 	movl   $0x263,0x4(%esp)
f010131a:	00 
f010131b:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101322:	e8 6d ed ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101327:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010132e:	e8 c4 fa ff ff       	call   f0100df7 <page_alloc>
f0101333:	89 c7                	mov    %eax,%edi
f0101335:	85 c0                	test   %eax,%eax
f0101337:	75 24                	jne    f010135d <mem_init+0x1bc>
f0101339:	c7 44 24 0c a8 4b 10 	movl   $0xf0104ba8,0xc(%esp)
f0101340:	f0 
f0101341:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101348:	f0 
f0101349:	c7 44 24 04 64 02 00 	movl   $0x264,0x4(%esp)
f0101350:	00 
f0101351:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101358:	e8 37 ed ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010135d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101364:	e8 8e fa ff ff       	call   f0100df7 <page_alloc>
f0101369:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010136c:	85 c0                	test   %eax,%eax
f010136e:	75 24                	jne    f0101394 <mem_init+0x1f3>
f0101370:	c7 44 24 0c be 4b 10 	movl   $0xf0104bbe,0xc(%esp)
f0101377:	f0 
f0101378:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f010137f:	f0 
f0101380:	c7 44 24 04 65 02 00 	movl   $0x265,0x4(%esp)
f0101387:	00 
f0101388:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f010138f:	e8 00 ed ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101394:	39 fe                	cmp    %edi,%esi
f0101396:	75 24                	jne    f01013bc <mem_init+0x21b>
f0101398:	c7 44 24 0c d4 4b 10 	movl   $0xf0104bd4,0xc(%esp)
f010139f:	f0 
f01013a0:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01013a7:	f0 
f01013a8:	c7 44 24 04 68 02 00 	movl   $0x268,0x4(%esp)
f01013af:	00 
f01013b0:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01013b7:	e8 d8 ec ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013bc:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01013bf:	74 05                	je     f01013c6 <mem_init+0x225>
f01013c1:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01013c4:	75 24                	jne    f01013ea <mem_init+0x249>
f01013c6:	c7 44 24 0c b0 44 10 	movl   $0xf01044b0,0xc(%esp)
f01013cd:	f0 
f01013ce:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01013d5:	f0 
f01013d6:	c7 44 24 04 69 02 00 	movl   $0x269,0x4(%esp)
f01013dd:	00 
f01013de:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01013e5:	e8 aa ec ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01013ea:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f01013f0:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01013f5:	c1 e0 0c             	shl    $0xc,%eax
f01013f8:	89 f1                	mov    %esi,%ecx
f01013fa:	29 d1                	sub    %edx,%ecx
f01013fc:	c1 f9 03             	sar    $0x3,%ecx
f01013ff:	c1 e1 0c             	shl    $0xc,%ecx
f0101402:	39 c1                	cmp    %eax,%ecx
f0101404:	72 24                	jb     f010142a <mem_init+0x289>
f0101406:	c7 44 24 0c e6 4b 10 	movl   $0xf0104be6,0xc(%esp)
f010140d:	f0 
f010140e:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101415:	f0 
f0101416:	c7 44 24 04 6a 02 00 	movl   $0x26a,0x4(%esp)
f010141d:	00 
f010141e:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101425:	e8 6a ec ff ff       	call   f0100094 <_panic>
f010142a:	89 f9                	mov    %edi,%ecx
f010142c:	29 d1                	sub    %edx,%ecx
f010142e:	c1 f9 03             	sar    $0x3,%ecx
f0101431:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101434:	39 c8                	cmp    %ecx,%eax
f0101436:	77 24                	ja     f010145c <mem_init+0x2bb>
f0101438:	c7 44 24 0c 03 4c 10 	movl   $0xf0104c03,0xc(%esp)
f010143f:	f0 
f0101440:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101447:	f0 
f0101448:	c7 44 24 04 6b 02 00 	movl   $0x26b,0x4(%esp)
f010144f:	00 
f0101450:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101457:	e8 38 ec ff ff       	call   f0100094 <_panic>
f010145c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010145f:	29 d1                	sub    %edx,%ecx
f0101461:	89 ca                	mov    %ecx,%edx
f0101463:	c1 fa 03             	sar    $0x3,%edx
f0101466:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101469:	39 d0                	cmp    %edx,%eax
f010146b:	77 24                	ja     f0101491 <mem_init+0x2f0>
f010146d:	c7 44 24 0c 20 4c 10 	movl   $0xf0104c20,0xc(%esp)
f0101474:	f0 
f0101475:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f010147c:	f0 
f010147d:	c7 44 24 04 6c 02 00 	movl   $0x26c,0x4(%esp)
f0101484:	00 
f0101485:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f010148c:	e8 03 ec ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101491:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f0101496:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101499:	c7 05 40 75 11 f0 00 	movl   $0x0,0xf0117540
f01014a0:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01014a3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014aa:	e8 48 f9 ff ff       	call   f0100df7 <page_alloc>
f01014af:	85 c0                	test   %eax,%eax
f01014b1:	74 24                	je     f01014d7 <mem_init+0x336>
f01014b3:	c7 44 24 0c 3d 4c 10 	movl   $0xf0104c3d,0xc(%esp)
f01014ba:	f0 
f01014bb:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01014c2:	f0 
f01014c3:	c7 44 24 04 73 02 00 	movl   $0x273,0x4(%esp)
f01014ca:	00 
f01014cb:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01014d2:	e8 bd eb ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01014d7:	89 34 24             	mov    %esi,(%esp)
f01014da:	e8 9c f9 ff ff       	call   f0100e7b <page_free>
	page_free(pp1);
f01014df:	89 3c 24             	mov    %edi,(%esp)
f01014e2:	e8 94 f9 ff ff       	call   f0100e7b <page_free>
	page_free(pp2);
f01014e7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014ea:	89 04 24             	mov    %eax,(%esp)
f01014ed:	e8 89 f9 ff ff       	call   f0100e7b <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01014f2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014f9:	e8 f9 f8 ff ff       	call   f0100df7 <page_alloc>
f01014fe:	89 c6                	mov    %eax,%esi
f0101500:	85 c0                	test   %eax,%eax
f0101502:	75 24                	jne    f0101528 <mem_init+0x387>
f0101504:	c7 44 24 0c 92 4b 10 	movl   $0xf0104b92,0xc(%esp)
f010150b:	f0 
f010150c:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101513:	f0 
f0101514:	c7 44 24 04 7a 02 00 	movl   $0x27a,0x4(%esp)
f010151b:	00 
f010151c:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101523:	e8 6c eb ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101528:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010152f:	e8 c3 f8 ff ff       	call   f0100df7 <page_alloc>
f0101534:	89 c7                	mov    %eax,%edi
f0101536:	85 c0                	test   %eax,%eax
f0101538:	75 24                	jne    f010155e <mem_init+0x3bd>
f010153a:	c7 44 24 0c a8 4b 10 	movl   $0xf0104ba8,0xc(%esp)
f0101541:	f0 
f0101542:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101549:	f0 
f010154a:	c7 44 24 04 7b 02 00 	movl   $0x27b,0x4(%esp)
f0101551:	00 
f0101552:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101559:	e8 36 eb ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010155e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101565:	e8 8d f8 ff ff       	call   f0100df7 <page_alloc>
f010156a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010156d:	85 c0                	test   %eax,%eax
f010156f:	75 24                	jne    f0101595 <mem_init+0x3f4>
f0101571:	c7 44 24 0c be 4b 10 	movl   $0xf0104bbe,0xc(%esp)
f0101578:	f0 
f0101579:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101580:	f0 
f0101581:	c7 44 24 04 7c 02 00 	movl   $0x27c,0x4(%esp)
f0101588:	00 
f0101589:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101590:	e8 ff ea ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101595:	39 fe                	cmp    %edi,%esi
f0101597:	75 24                	jne    f01015bd <mem_init+0x41c>
f0101599:	c7 44 24 0c d4 4b 10 	movl   $0xf0104bd4,0xc(%esp)
f01015a0:	f0 
f01015a1:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01015a8:	f0 
f01015a9:	c7 44 24 04 7e 02 00 	movl   $0x27e,0x4(%esp)
f01015b0:	00 
f01015b1:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01015b8:	e8 d7 ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015bd:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01015c0:	74 05                	je     f01015c7 <mem_init+0x426>
f01015c2:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01015c5:	75 24                	jne    f01015eb <mem_init+0x44a>
f01015c7:	c7 44 24 0c b0 44 10 	movl   $0xf01044b0,0xc(%esp)
f01015ce:	f0 
f01015cf:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01015d6:	f0 
f01015d7:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
f01015de:	00 
f01015df:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01015e6:	e8 a9 ea ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f01015eb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015f2:	e8 00 f8 ff ff       	call   f0100df7 <page_alloc>
f01015f7:	85 c0                	test   %eax,%eax
f01015f9:	74 24                	je     f010161f <mem_init+0x47e>
f01015fb:	c7 44 24 0c 3d 4c 10 	movl   $0xf0104c3d,0xc(%esp)
f0101602:	f0 
f0101603:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f010160a:	f0 
f010160b:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f0101612:	00 
f0101613:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f010161a:	e8 75 ea ff ff       	call   f0100094 <_panic>
f010161f:	89 f0                	mov    %esi,%eax
f0101621:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101627:	c1 f8 03             	sar    $0x3,%eax
f010162a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010162d:	89 c2                	mov    %eax,%edx
f010162f:	c1 ea 0c             	shr    $0xc,%edx
f0101632:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0101638:	72 20                	jb     f010165a <mem_init+0x4b9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010163a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010163e:	c7 44 24 08 24 43 10 	movl   $0xf0104324,0x8(%esp)
f0101645:	f0 
f0101646:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010164d:	00 
f010164e:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101655:	e8 3a ea ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010165a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101661:	00 
f0101662:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101669:	00 
	return (void *)(pa + KERNBASE);
f010166a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010166f:	89 04 24             	mov    %eax,(%esp)
f0101672:	e8 8c 22 00 00       	call   f0103903 <memset>
	page_free(pp0);
f0101677:	89 34 24             	mov    %esi,(%esp)
f010167a:	e8 fc f7 ff ff       	call   f0100e7b <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010167f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101686:	e8 6c f7 ff ff       	call   f0100df7 <page_alloc>
f010168b:	85 c0                	test   %eax,%eax
f010168d:	75 24                	jne    f01016b3 <mem_init+0x512>
f010168f:	c7 44 24 0c 4c 4c 10 	movl   $0xf0104c4c,0xc(%esp)
f0101696:	f0 
f0101697:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f010169e:	f0 
f010169f:	c7 44 24 04 85 02 00 	movl   $0x285,0x4(%esp)
f01016a6:	00 
f01016a7:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01016ae:	e8 e1 e9 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f01016b3:	39 c6                	cmp    %eax,%esi
f01016b5:	74 24                	je     f01016db <mem_init+0x53a>
f01016b7:	c7 44 24 0c 6a 4c 10 	movl   $0xf0104c6a,0xc(%esp)
f01016be:	f0 
f01016bf:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01016c6:	f0 
f01016c7:	c7 44 24 04 86 02 00 	movl   $0x286,0x4(%esp)
f01016ce:	00 
f01016cf:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01016d6:	e8 b9 e9 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01016db:	89 f2                	mov    %esi,%edx
f01016dd:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01016e3:	c1 fa 03             	sar    $0x3,%edx
f01016e6:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016e9:	89 d0                	mov    %edx,%eax
f01016eb:	c1 e8 0c             	shr    $0xc,%eax
f01016ee:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f01016f4:	72 20                	jb     f0101716 <mem_init+0x575>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01016f6:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01016fa:	c7 44 24 08 24 43 10 	movl   $0xf0104324,0x8(%esp)
f0101701:	f0 
f0101702:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101709:	00 
f010170a:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101711:	e8 7e e9 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101716:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010171c:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101722:	80 38 00             	cmpb   $0x0,(%eax)
f0101725:	74 24                	je     f010174b <mem_init+0x5aa>
f0101727:	c7 44 24 0c 7a 4c 10 	movl   $0xf0104c7a,0xc(%esp)
f010172e:	f0 
f010172f:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101736:	f0 
f0101737:	c7 44 24 04 89 02 00 	movl   $0x289,0x4(%esp)
f010173e:	00 
f010173f:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101746:	e8 49 e9 ff ff       	call   f0100094 <_panic>
f010174b:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010174e:	39 d0                	cmp    %edx,%eax
f0101750:	75 d0                	jne    f0101722 <mem_init+0x581>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101752:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101755:	89 15 40 75 11 f0    	mov    %edx,0xf0117540

	// free the pages we took
	page_free(pp0);
f010175b:	89 34 24             	mov    %esi,(%esp)
f010175e:	e8 18 f7 ff ff       	call   f0100e7b <page_free>
	page_free(pp1);
f0101763:	89 3c 24             	mov    %edi,(%esp)
f0101766:	e8 10 f7 ff ff       	call   f0100e7b <page_free>
	page_free(pp2);
f010176b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010176e:	89 04 24             	mov    %eax,(%esp)
f0101771:	e8 05 f7 ff ff       	call   f0100e7b <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101776:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f010177b:	eb 05                	jmp    f0101782 <mem_init+0x5e1>
		--nfree;
f010177d:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101780:	8b 00                	mov    (%eax),%eax
f0101782:	85 c0                	test   %eax,%eax
f0101784:	75 f7                	jne    f010177d <mem_init+0x5dc>
		--nfree;
	assert(nfree == 0);
f0101786:	85 db                	test   %ebx,%ebx
f0101788:	74 24                	je     f01017ae <mem_init+0x60d>
f010178a:	c7 44 24 0c 84 4c 10 	movl   $0xf0104c84,0xc(%esp)
f0101791:	f0 
f0101792:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101799:	f0 
f010179a:	c7 44 24 04 96 02 00 	movl   $0x296,0x4(%esp)
f01017a1:	00 
f01017a2:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01017a9:	e8 e6 e8 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01017ae:	c7 04 24 d0 44 10 f0 	movl   $0xf01044d0,(%esp)
f01017b5:	e8 24 16 00 00       	call   f0102dde <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01017ba:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017c1:	e8 31 f6 ff ff       	call   f0100df7 <page_alloc>
f01017c6:	89 c7                	mov    %eax,%edi
f01017c8:	85 c0                	test   %eax,%eax
f01017ca:	75 24                	jne    f01017f0 <mem_init+0x64f>
f01017cc:	c7 44 24 0c 92 4b 10 	movl   $0xf0104b92,0xc(%esp)
f01017d3:	f0 
f01017d4:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01017db:	f0 
f01017dc:	c7 44 24 04 ef 02 00 	movl   $0x2ef,0x4(%esp)
f01017e3:	00 
f01017e4:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01017eb:	e8 a4 e8 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01017f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017f7:	e8 fb f5 ff ff       	call   f0100df7 <page_alloc>
f01017fc:	89 c6                	mov    %eax,%esi
f01017fe:	85 c0                	test   %eax,%eax
f0101800:	75 24                	jne    f0101826 <mem_init+0x685>
f0101802:	c7 44 24 0c a8 4b 10 	movl   $0xf0104ba8,0xc(%esp)
f0101809:	f0 
f010180a:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101811:	f0 
f0101812:	c7 44 24 04 f0 02 00 	movl   $0x2f0,0x4(%esp)
f0101819:	00 
f010181a:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101821:	e8 6e e8 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101826:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010182d:	e8 c5 f5 ff ff       	call   f0100df7 <page_alloc>
f0101832:	89 c3                	mov    %eax,%ebx
f0101834:	85 c0                	test   %eax,%eax
f0101836:	75 24                	jne    f010185c <mem_init+0x6bb>
f0101838:	c7 44 24 0c be 4b 10 	movl   $0xf0104bbe,0xc(%esp)
f010183f:	f0 
f0101840:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101847:	f0 
f0101848:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
f010184f:	00 
f0101850:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101857:	e8 38 e8 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010185c:	39 f7                	cmp    %esi,%edi
f010185e:	75 24                	jne    f0101884 <mem_init+0x6e3>
f0101860:	c7 44 24 0c d4 4b 10 	movl   $0xf0104bd4,0xc(%esp)
f0101867:	f0 
f0101868:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f010186f:	f0 
f0101870:	c7 44 24 04 f4 02 00 	movl   $0x2f4,0x4(%esp)
f0101877:	00 
f0101878:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f010187f:	e8 10 e8 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101884:	39 c6                	cmp    %eax,%esi
f0101886:	74 04                	je     f010188c <mem_init+0x6eb>
f0101888:	39 c7                	cmp    %eax,%edi
f010188a:	75 24                	jne    f01018b0 <mem_init+0x70f>
f010188c:	c7 44 24 0c b0 44 10 	movl   $0xf01044b0,0xc(%esp)
f0101893:	f0 
f0101894:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f010189b:	f0 
f010189c:	c7 44 24 04 f5 02 00 	movl   $0x2f5,0x4(%esp)
f01018a3:	00 
f01018a4:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01018ab:	e8 e4 e7 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01018b0:	8b 15 40 75 11 f0    	mov    0xf0117540,%edx
f01018b6:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f01018b9:	c7 05 40 75 11 f0 00 	movl   $0x0,0xf0117540
f01018c0:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01018c3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018ca:	e8 28 f5 ff ff       	call   f0100df7 <page_alloc>
f01018cf:	85 c0                	test   %eax,%eax
f01018d1:	74 24                	je     f01018f7 <mem_init+0x756>
f01018d3:	c7 44 24 0c 3d 4c 10 	movl   $0xf0104c3d,0xc(%esp)
f01018da:	f0 
f01018db:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01018e2:	f0 
f01018e3:	c7 44 24 04 fc 02 00 	movl   $0x2fc,0x4(%esp)
f01018ea:	00 
f01018eb:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01018f2:	e8 9d e7 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01018f7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01018fa:	89 44 24 08          	mov    %eax,0x8(%esp)
f01018fe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101905:	00 
f0101906:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010190b:	89 04 24             	mov    %eax,(%esp)
f010190e:	e8 11 f7 ff ff       	call   f0101024 <page_lookup>
f0101913:	85 c0                	test   %eax,%eax
f0101915:	74 24                	je     f010193b <mem_init+0x79a>
f0101917:	c7 44 24 0c f0 44 10 	movl   $0xf01044f0,0xc(%esp)
f010191e:	f0 
f010191f:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101926:	f0 
f0101927:	c7 44 24 04 ff 02 00 	movl   $0x2ff,0x4(%esp)
f010192e:	00 
f010192f:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101936:	e8 59 e7 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010193b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101942:	00 
f0101943:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010194a:	00 
f010194b:	89 74 24 04          	mov    %esi,0x4(%esp)
f010194f:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101954:	89 04 24             	mov    %eax,(%esp)
f0101957:	e8 9b f7 ff ff       	call   f01010f7 <page_insert>
f010195c:	85 c0                	test   %eax,%eax
f010195e:	78 24                	js     f0101984 <mem_init+0x7e3>
f0101960:	c7 44 24 0c 28 45 10 	movl   $0xf0104528,0xc(%esp)
f0101967:	f0 
f0101968:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f010196f:	f0 
f0101970:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
f0101977:	00 
f0101978:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f010197f:	e8 10 e7 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101984:	89 3c 24             	mov    %edi,(%esp)
f0101987:	e8 ef f4 ff ff       	call   f0100e7b <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010198c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101993:	00 
f0101994:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010199b:	00 
f010199c:	89 74 24 04          	mov    %esi,0x4(%esp)
f01019a0:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01019a5:	89 04 24             	mov    %eax,(%esp)
f01019a8:	e8 4a f7 ff ff       	call   f01010f7 <page_insert>
f01019ad:	85 c0                	test   %eax,%eax
f01019af:	74 24                	je     f01019d5 <mem_init+0x834>
f01019b1:	c7 44 24 0c 58 45 10 	movl   $0xf0104558,0xc(%esp)
f01019b8:	f0 
f01019b9:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01019c0:	f0 
f01019c1:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f01019c8:	00 
f01019c9:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01019d0:	e8 bf e6 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01019d5:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f01019db:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01019de:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01019e3:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01019e6:	8b 11                	mov    (%ecx),%edx
f01019e8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01019ee:	89 f8                	mov    %edi,%eax
f01019f0:	2b 45 d0             	sub    -0x30(%ebp),%eax
f01019f3:	c1 f8 03             	sar    $0x3,%eax
f01019f6:	c1 e0 0c             	shl    $0xc,%eax
f01019f9:	39 c2                	cmp    %eax,%edx
f01019fb:	74 24                	je     f0101a21 <mem_init+0x880>
f01019fd:	c7 44 24 0c 88 45 10 	movl   $0xf0104588,0xc(%esp)
f0101a04:	f0 
f0101a05:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101a0c:	f0 
f0101a0d:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
f0101a14:	00 
f0101a15:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101a1c:	e8 73 e6 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a21:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a26:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a29:	e8 d6 ee ff ff       	call   f0100904 <check_va2pa>
f0101a2e:	89 f2                	mov    %esi,%edx
f0101a30:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101a33:	c1 fa 03             	sar    $0x3,%edx
f0101a36:	c1 e2 0c             	shl    $0xc,%edx
f0101a39:	39 d0                	cmp    %edx,%eax
f0101a3b:	74 24                	je     f0101a61 <mem_init+0x8c0>
f0101a3d:	c7 44 24 0c b0 45 10 	movl   $0xf01045b0,0xc(%esp)
f0101a44:	f0 
f0101a45:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101a4c:	f0 
f0101a4d:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
f0101a54:	00 
f0101a55:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101a5c:	e8 33 e6 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101a61:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a66:	74 24                	je     f0101a8c <mem_init+0x8eb>
f0101a68:	c7 44 24 0c 8f 4c 10 	movl   $0xf0104c8f,0xc(%esp)
f0101a6f:	f0 
f0101a70:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101a77:	f0 
f0101a78:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f0101a7f:	00 
f0101a80:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101a87:	e8 08 e6 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101a8c:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101a91:	74 24                	je     f0101ab7 <mem_init+0x916>
f0101a93:	c7 44 24 0c a0 4c 10 	movl   $0xf0104ca0,0xc(%esp)
f0101a9a:	f0 
f0101a9b:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101aa2:	f0 
f0101aa3:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f0101aaa:	00 
f0101aab:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101ab2:	e8 dd e5 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ab7:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101abe:	00 
f0101abf:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ac6:	00 
f0101ac7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101acb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101ace:	89 14 24             	mov    %edx,(%esp)
f0101ad1:	e8 21 f6 ff ff       	call   f01010f7 <page_insert>
f0101ad6:	85 c0                	test   %eax,%eax
f0101ad8:	74 24                	je     f0101afe <mem_init+0x95d>
f0101ada:	c7 44 24 0c e0 45 10 	movl   $0xf01045e0,0xc(%esp)
f0101ae1:	f0 
f0101ae2:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101ae9:	f0 
f0101aea:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
f0101af1:	00 
f0101af2:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101af9:	e8 96 e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101afe:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b03:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101b08:	e8 f7 ed ff ff       	call   f0100904 <check_va2pa>
f0101b0d:	89 da                	mov    %ebx,%edx
f0101b0f:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101b15:	c1 fa 03             	sar    $0x3,%edx
f0101b18:	c1 e2 0c             	shl    $0xc,%edx
f0101b1b:	39 d0                	cmp    %edx,%eax
f0101b1d:	74 24                	je     f0101b43 <mem_init+0x9a2>
f0101b1f:	c7 44 24 0c 1c 46 10 	movl   $0xf010461c,0xc(%esp)
f0101b26:	f0 
f0101b27:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101b2e:	f0 
f0101b2f:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f0101b36:	00 
f0101b37:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101b3e:	e8 51 e5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101b43:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b48:	74 24                	je     f0101b6e <mem_init+0x9cd>
f0101b4a:	c7 44 24 0c b1 4c 10 	movl   $0xf0104cb1,0xc(%esp)
f0101b51:	f0 
f0101b52:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101b59:	f0 
f0101b5a:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f0101b61:	00 
f0101b62:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101b69:	e8 26 e5 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101b6e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b75:	e8 7d f2 ff ff       	call   f0100df7 <page_alloc>
f0101b7a:	85 c0                	test   %eax,%eax
f0101b7c:	74 24                	je     f0101ba2 <mem_init+0xa01>
f0101b7e:	c7 44 24 0c 3d 4c 10 	movl   $0xf0104c3d,0xc(%esp)
f0101b85:	f0 
f0101b86:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101b8d:	f0 
f0101b8e:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f0101b95:	00 
f0101b96:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101b9d:	e8 f2 e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ba2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ba9:	00 
f0101baa:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101bb1:	00 
f0101bb2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101bb6:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101bbb:	89 04 24             	mov    %eax,(%esp)
f0101bbe:	e8 34 f5 ff ff       	call   f01010f7 <page_insert>
f0101bc3:	85 c0                	test   %eax,%eax
f0101bc5:	74 24                	je     f0101beb <mem_init+0xa4a>
f0101bc7:	c7 44 24 0c e0 45 10 	movl   $0xf01045e0,0xc(%esp)
f0101bce:	f0 
f0101bcf:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101bd6:	f0 
f0101bd7:	c7 44 24 04 15 03 00 	movl   $0x315,0x4(%esp)
f0101bde:	00 
f0101bdf:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101be6:	e8 a9 e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101beb:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bf0:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101bf5:	e8 0a ed ff ff       	call   f0100904 <check_va2pa>
f0101bfa:	89 da                	mov    %ebx,%edx
f0101bfc:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101c02:	c1 fa 03             	sar    $0x3,%edx
f0101c05:	c1 e2 0c             	shl    $0xc,%edx
f0101c08:	39 d0                	cmp    %edx,%eax
f0101c0a:	74 24                	je     f0101c30 <mem_init+0xa8f>
f0101c0c:	c7 44 24 0c 1c 46 10 	movl   $0xf010461c,0xc(%esp)
f0101c13:	f0 
f0101c14:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101c1b:	f0 
f0101c1c:	c7 44 24 04 16 03 00 	movl   $0x316,0x4(%esp)
f0101c23:	00 
f0101c24:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101c2b:	e8 64 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101c30:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c35:	74 24                	je     f0101c5b <mem_init+0xaba>
f0101c37:	c7 44 24 0c b1 4c 10 	movl   $0xf0104cb1,0xc(%esp)
f0101c3e:	f0 
f0101c3f:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101c46:	f0 
f0101c47:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0101c4e:	00 
f0101c4f:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101c56:	e8 39 e4 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c5b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c62:	e8 90 f1 ff ff       	call   f0100df7 <page_alloc>
f0101c67:	85 c0                	test   %eax,%eax
f0101c69:	74 24                	je     f0101c8f <mem_init+0xaee>
f0101c6b:	c7 44 24 0c 3d 4c 10 	movl   $0xf0104c3d,0xc(%esp)
f0101c72:	f0 
f0101c73:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101c7a:	f0 
f0101c7b:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0101c82:	00 
f0101c83:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101c8a:	e8 05 e4 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c8f:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f0101c95:	8b 02                	mov    (%edx),%eax
f0101c97:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101c9c:	89 c1                	mov    %eax,%ecx
f0101c9e:	c1 e9 0c             	shr    $0xc,%ecx
f0101ca1:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0101ca7:	72 20                	jb     f0101cc9 <mem_init+0xb28>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ca9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101cad:	c7 44 24 08 24 43 10 	movl   $0xf0104324,0x8(%esp)
f0101cb4:	f0 
f0101cb5:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f0101cbc:	00 
f0101cbd:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101cc4:	e8 cb e3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101cc9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101cce:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101cd1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101cd8:	00 
f0101cd9:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101ce0:	00 
f0101ce1:	89 14 24             	mov    %edx,(%esp)
f0101ce4:	e8 f5 f1 ff ff       	call   f0100ede <pgdir_walk>
f0101ce9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101cec:	83 c2 04             	add    $0x4,%edx
f0101cef:	39 d0                	cmp    %edx,%eax
f0101cf1:	74 24                	je     f0101d17 <mem_init+0xb76>
f0101cf3:	c7 44 24 0c 4c 46 10 	movl   $0xf010464c,0xc(%esp)
f0101cfa:	f0 
f0101cfb:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101d02:	f0 
f0101d03:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f0101d0a:	00 
f0101d0b:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101d12:	e8 7d e3 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d17:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101d1e:	00 
f0101d1f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d26:	00 
f0101d27:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101d2b:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101d30:	89 04 24             	mov    %eax,(%esp)
f0101d33:	e8 bf f3 ff ff       	call   f01010f7 <page_insert>
f0101d38:	85 c0                	test   %eax,%eax
f0101d3a:	74 24                	je     f0101d60 <mem_init+0xbbf>
f0101d3c:	c7 44 24 0c 8c 46 10 	movl   $0xf010468c,0xc(%esp)
f0101d43:	f0 
f0101d44:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101d4b:	f0 
f0101d4c:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0101d53:	00 
f0101d54:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101d5b:	e8 34 e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d60:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f0101d66:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101d69:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d6e:	89 c8                	mov    %ecx,%eax
f0101d70:	e8 8f eb ff ff       	call   f0100904 <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101d75:	89 da                	mov    %ebx,%edx
f0101d77:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101d7d:	c1 fa 03             	sar    $0x3,%edx
f0101d80:	c1 e2 0c             	shl    $0xc,%edx
f0101d83:	39 d0                	cmp    %edx,%eax
f0101d85:	74 24                	je     f0101dab <mem_init+0xc0a>
f0101d87:	c7 44 24 0c 1c 46 10 	movl   $0xf010461c,0xc(%esp)
f0101d8e:	f0 
f0101d8f:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101d96:	f0 
f0101d97:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0101d9e:	00 
f0101d9f:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101da6:	e8 e9 e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101dab:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101db0:	74 24                	je     f0101dd6 <mem_init+0xc35>
f0101db2:	c7 44 24 0c b1 4c 10 	movl   $0xf0104cb1,0xc(%esp)
f0101db9:	f0 
f0101dba:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101dc1:	f0 
f0101dc2:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f0101dc9:	00 
f0101dca:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101dd1:	e8 be e2 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101dd6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101ddd:	00 
f0101dde:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101de5:	00 
f0101de6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101de9:	89 04 24             	mov    %eax,(%esp)
f0101dec:	e8 ed f0 ff ff       	call   f0100ede <pgdir_walk>
f0101df1:	f6 00 04             	testb  $0x4,(%eax)
f0101df4:	75 24                	jne    f0101e1a <mem_init+0xc79>
f0101df6:	c7 44 24 0c cc 46 10 	movl   $0xf01046cc,0xc(%esp)
f0101dfd:	f0 
f0101dfe:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101e05:	f0 
f0101e06:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0101e0d:	00 
f0101e0e:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101e15:	e8 7a e2 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101e1a:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101e1f:	f6 00 04             	testb  $0x4,(%eax)
f0101e22:	75 24                	jne    f0101e48 <mem_init+0xca7>
f0101e24:	c7 44 24 0c c2 4c 10 	movl   $0xf0104cc2,0xc(%esp)
f0101e2b:	f0 
f0101e2c:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101e33:	f0 
f0101e34:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f0101e3b:	00 
f0101e3c:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101e43:	e8 4c e2 ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e48:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e4f:	00 
f0101e50:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e57:	00 
f0101e58:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101e5c:	89 04 24             	mov    %eax,(%esp)
f0101e5f:	e8 93 f2 ff ff       	call   f01010f7 <page_insert>
f0101e64:	85 c0                	test   %eax,%eax
f0101e66:	74 24                	je     f0101e8c <mem_init+0xceb>
f0101e68:	c7 44 24 0c e0 45 10 	movl   $0xf01045e0,0xc(%esp)
f0101e6f:	f0 
f0101e70:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101e77:	f0 
f0101e78:	c7 44 24 04 29 03 00 	movl   $0x329,0x4(%esp)
f0101e7f:	00 
f0101e80:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101e87:	e8 08 e2 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101e8c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e93:	00 
f0101e94:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e9b:	00 
f0101e9c:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101ea1:	89 04 24             	mov    %eax,(%esp)
f0101ea4:	e8 35 f0 ff ff       	call   f0100ede <pgdir_walk>
f0101ea9:	f6 00 02             	testb  $0x2,(%eax)
f0101eac:	75 24                	jne    f0101ed2 <mem_init+0xd31>
f0101eae:	c7 44 24 0c 00 47 10 	movl   $0xf0104700,0xc(%esp)
f0101eb5:	f0 
f0101eb6:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101ebd:	f0 
f0101ebe:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f0101ec5:	00 
f0101ec6:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101ecd:	e8 c2 e1 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ed2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101ed9:	00 
f0101eda:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101ee1:	00 
f0101ee2:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101ee7:	89 04 24             	mov    %eax,(%esp)
f0101eea:	e8 ef ef ff ff       	call   f0100ede <pgdir_walk>
f0101eef:	f6 00 04             	testb  $0x4,(%eax)
f0101ef2:	74 24                	je     f0101f18 <mem_init+0xd77>
f0101ef4:	c7 44 24 0c 34 47 10 	movl   $0xf0104734,0xc(%esp)
f0101efb:	f0 
f0101efc:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101f03:	f0 
f0101f04:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0101f0b:	00 
f0101f0c:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101f13:	e8 7c e1 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f18:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f1f:	00 
f0101f20:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101f27:	00 
f0101f28:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101f2c:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101f31:	89 04 24             	mov    %eax,(%esp)
f0101f34:	e8 be f1 ff ff       	call   f01010f7 <page_insert>
f0101f39:	85 c0                	test   %eax,%eax
f0101f3b:	78 24                	js     f0101f61 <mem_init+0xdc0>
f0101f3d:	c7 44 24 0c 6c 47 10 	movl   $0xf010476c,0xc(%esp)
f0101f44:	f0 
f0101f45:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101f4c:	f0 
f0101f4d:	c7 44 24 04 2e 03 00 	movl   $0x32e,0x4(%esp)
f0101f54:	00 
f0101f55:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101f5c:	e8 33 e1 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101f61:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f68:	00 
f0101f69:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f70:	00 
f0101f71:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f75:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101f7a:	89 04 24             	mov    %eax,(%esp)
f0101f7d:	e8 75 f1 ff ff       	call   f01010f7 <page_insert>
f0101f82:	85 c0                	test   %eax,%eax
f0101f84:	74 24                	je     f0101faa <mem_init+0xe09>
f0101f86:	c7 44 24 0c a4 47 10 	movl   $0xf01047a4,0xc(%esp)
f0101f8d:	f0 
f0101f8e:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101f95:	f0 
f0101f96:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f0101f9d:	00 
f0101f9e:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101fa5:	e8 ea e0 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101faa:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101fb1:	00 
f0101fb2:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101fb9:	00 
f0101fba:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101fbf:	89 04 24             	mov    %eax,(%esp)
f0101fc2:	e8 17 ef ff ff       	call   f0100ede <pgdir_walk>
f0101fc7:	f6 00 04             	testb  $0x4,(%eax)
f0101fca:	74 24                	je     f0101ff0 <mem_init+0xe4f>
f0101fcc:	c7 44 24 0c 34 47 10 	movl   $0xf0104734,0xc(%esp)
f0101fd3:	f0 
f0101fd4:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0101fdb:	f0 
f0101fdc:	c7 44 24 04 32 03 00 	movl   $0x332,0x4(%esp)
f0101fe3:	00 
f0101fe4:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0101feb:	e8 a4 e0 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101ff0:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101ff5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101ff8:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ffd:	e8 02 e9 ff ff       	call   f0100904 <check_va2pa>
f0102002:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102005:	89 f0                	mov    %esi,%eax
f0102007:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010200d:	c1 f8 03             	sar    $0x3,%eax
f0102010:	c1 e0 0c             	shl    $0xc,%eax
f0102013:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102016:	74 24                	je     f010203c <mem_init+0xe9b>
f0102018:	c7 44 24 0c e0 47 10 	movl   $0xf01047e0,0xc(%esp)
f010201f:	f0 
f0102020:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0102027:	f0 
f0102028:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f010202f:	00 
f0102030:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102037:	e8 58 e0 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010203c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102041:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102044:	e8 bb e8 ff ff       	call   f0100904 <check_va2pa>
f0102049:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010204c:	74 24                	je     f0102072 <mem_init+0xed1>
f010204e:	c7 44 24 0c 0c 48 10 	movl   $0xf010480c,0xc(%esp)
f0102055:	f0 
f0102056:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f010205d:	f0 
f010205e:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
f0102065:	00 
f0102066:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f010206d:	e8 22 e0 ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102072:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f0102077:	74 24                	je     f010209d <mem_init+0xefc>
f0102079:	c7 44 24 0c d8 4c 10 	movl   $0xf0104cd8,0xc(%esp)
f0102080:	f0 
f0102081:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0102088:	f0 
f0102089:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f0102090:	00 
f0102091:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102098:	e8 f7 df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f010209d:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01020a2:	74 24                	je     f01020c8 <mem_init+0xf27>
f01020a4:	c7 44 24 0c e9 4c 10 	movl   $0xf0104ce9,0xc(%esp)
f01020ab:	f0 
f01020ac:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01020b3:	f0 
f01020b4:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f01020bb:	00 
f01020bc:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01020c3:	e8 cc df ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01020c8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01020cf:	e8 23 ed ff ff       	call   f0100df7 <page_alloc>
f01020d4:	85 c0                	test   %eax,%eax
f01020d6:	74 04                	je     f01020dc <mem_init+0xf3b>
f01020d8:	39 c3                	cmp    %eax,%ebx
f01020da:	74 24                	je     f0102100 <mem_init+0xf5f>
f01020dc:	c7 44 24 0c 3c 48 10 	movl   $0xf010483c,0xc(%esp)
f01020e3:	f0 
f01020e4:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01020eb:	f0 
f01020ec:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f01020f3:	00 
f01020f4:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01020fb:	e8 94 df ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102100:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102107:	00 
f0102108:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010210d:	89 04 24             	mov    %eax,(%esp)
f0102110:	e8 92 ef ff ff       	call   f01010a7 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102115:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f010211b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010211e:	ba 00 00 00 00       	mov    $0x0,%edx
f0102123:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102126:	e8 d9 e7 ff ff       	call   f0100904 <check_va2pa>
f010212b:	83 f8 ff             	cmp    $0xffffffff,%eax
f010212e:	74 24                	je     f0102154 <mem_init+0xfb3>
f0102130:	c7 44 24 0c 60 48 10 	movl   $0xf0104860,0xc(%esp)
f0102137:	f0 
f0102138:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f010213f:	f0 
f0102140:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0102147:	00 
f0102148:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f010214f:	e8 40 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102154:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102159:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010215c:	e8 a3 e7 ff ff       	call   f0100904 <check_va2pa>
f0102161:	89 f2                	mov    %esi,%edx
f0102163:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0102169:	c1 fa 03             	sar    $0x3,%edx
f010216c:	c1 e2 0c             	shl    $0xc,%edx
f010216f:	39 d0                	cmp    %edx,%eax
f0102171:	74 24                	je     f0102197 <mem_init+0xff6>
f0102173:	c7 44 24 0c 0c 48 10 	movl   $0xf010480c,0xc(%esp)
f010217a:	f0 
f010217b:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0102182:	f0 
f0102183:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f010218a:	00 
f010218b:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102192:	e8 fd de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0102197:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010219c:	74 24                	je     f01021c2 <mem_init+0x1021>
f010219e:	c7 44 24 0c 8f 4c 10 	movl   $0xf0104c8f,0xc(%esp)
f01021a5:	f0 
f01021a6:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01021ad:	f0 
f01021ae:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f01021b5:	00 
f01021b6:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01021bd:	e8 d2 de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01021c2:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01021c7:	74 24                	je     f01021ed <mem_init+0x104c>
f01021c9:	c7 44 24 0c e9 4c 10 	movl   $0xf0104ce9,0xc(%esp)
f01021d0:	f0 
f01021d1:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01021d8:	f0 
f01021d9:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f01021e0:	00 
f01021e1:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01021e8:	e8 a7 de ff ff       	call   f0100094 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01021ed:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01021f4:	00 
f01021f5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01021fc:	00 
f01021fd:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102201:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102204:	89 0c 24             	mov    %ecx,(%esp)
f0102207:	e8 eb ee ff ff       	call   f01010f7 <page_insert>
f010220c:	85 c0                	test   %eax,%eax
f010220e:	74 24                	je     f0102234 <mem_init+0x1093>
f0102210:	c7 44 24 0c 84 48 10 	movl   $0xf0104884,0xc(%esp)
f0102217:	f0 
f0102218:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f010221f:	f0 
f0102220:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f0102227:	00 
f0102228:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f010222f:	e8 60 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref);
f0102234:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102239:	75 24                	jne    f010225f <mem_init+0x10be>
f010223b:	c7 44 24 0c fa 4c 10 	movl   $0xf0104cfa,0xc(%esp)
f0102242:	f0 
f0102243:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f010224a:	f0 
f010224b:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f0102252:	00 
f0102253:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f010225a:	e8 35 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_link == NULL);
f010225f:	83 3e 00             	cmpl   $0x0,(%esi)
f0102262:	74 24                	je     f0102288 <mem_init+0x10e7>
f0102264:	c7 44 24 0c 06 4d 10 	movl   $0xf0104d06,0xc(%esp)
f010226b:	f0 
f010226c:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0102273:	f0 
f0102274:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f010227b:	00 
f010227c:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102283:	e8 0c de ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102288:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010228f:	00 
f0102290:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102295:	89 04 24             	mov    %eax,(%esp)
f0102298:	e8 0a ee ff ff       	call   f01010a7 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010229d:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01022a2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01022a5:	ba 00 00 00 00       	mov    $0x0,%edx
f01022aa:	e8 55 e6 ff ff       	call   f0100904 <check_va2pa>
f01022af:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022b2:	74 24                	je     f01022d8 <mem_init+0x1137>
f01022b4:	c7 44 24 0c 60 48 10 	movl   $0xf0104860,0xc(%esp)
f01022bb:	f0 
f01022bc:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01022c3:	f0 
f01022c4:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f01022cb:	00 
f01022cc:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01022d3:	e8 bc dd ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01022d8:	ba 00 10 00 00       	mov    $0x1000,%edx
f01022dd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022e0:	e8 1f e6 ff ff       	call   f0100904 <check_va2pa>
f01022e5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022e8:	74 24                	je     f010230e <mem_init+0x116d>
f01022ea:	c7 44 24 0c bc 48 10 	movl   $0xf01048bc,0xc(%esp)
f01022f1:	f0 
f01022f2:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01022f9:	f0 
f01022fa:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f0102301:	00 
f0102302:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102309:	e8 86 dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f010230e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102313:	74 24                	je     f0102339 <mem_init+0x1198>
f0102315:	c7 44 24 0c 1b 4d 10 	movl   $0xf0104d1b,0xc(%esp)
f010231c:	f0 
f010231d:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0102324:	f0 
f0102325:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f010232c:	00 
f010232d:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102334:	e8 5b dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102339:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010233e:	74 24                	je     f0102364 <mem_init+0x11c3>
f0102340:	c7 44 24 0c e9 4c 10 	movl   $0xf0104ce9,0xc(%esp)
f0102347:	f0 
f0102348:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f010234f:	f0 
f0102350:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f0102357:	00 
f0102358:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f010235f:	e8 30 dd ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102364:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010236b:	e8 87 ea ff ff       	call   f0100df7 <page_alloc>
f0102370:	85 c0                	test   %eax,%eax
f0102372:	74 04                	je     f0102378 <mem_init+0x11d7>
f0102374:	39 c6                	cmp    %eax,%esi
f0102376:	74 24                	je     f010239c <mem_init+0x11fb>
f0102378:	c7 44 24 0c e4 48 10 	movl   $0xf01048e4,0xc(%esp)
f010237f:	f0 
f0102380:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0102387:	f0 
f0102388:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f010238f:	00 
f0102390:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102397:	e8 f8 dc ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010239c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01023a3:	e8 4f ea ff ff       	call   f0100df7 <page_alloc>
f01023a8:	85 c0                	test   %eax,%eax
f01023aa:	74 24                	je     f01023d0 <mem_init+0x122f>
f01023ac:	c7 44 24 0c 3d 4c 10 	movl   $0xf0104c3d,0xc(%esp)
f01023b3:	f0 
f01023b4:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01023bb:	f0 
f01023bc:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f01023c3:	00 
f01023c4:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01023cb:	e8 c4 dc ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01023d0:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01023d5:	8b 08                	mov    (%eax),%ecx
f01023d7:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01023dd:	89 fa                	mov    %edi,%edx
f01023df:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01023e5:	c1 fa 03             	sar    $0x3,%edx
f01023e8:	c1 e2 0c             	shl    $0xc,%edx
f01023eb:	39 d1                	cmp    %edx,%ecx
f01023ed:	74 24                	je     f0102413 <mem_init+0x1272>
f01023ef:	c7 44 24 0c 88 45 10 	movl   $0xf0104588,0xc(%esp)
f01023f6:	f0 
f01023f7:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01023fe:	f0 
f01023ff:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f0102406:	00 
f0102407:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f010240e:	e8 81 dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102413:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102419:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010241e:	74 24                	je     f0102444 <mem_init+0x12a3>
f0102420:	c7 44 24 0c a0 4c 10 	movl   $0xf0104ca0,0xc(%esp)
f0102427:	f0 
f0102428:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f010242f:	f0 
f0102430:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f0102437:	00 
f0102438:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f010243f:	e8 50 dc ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102444:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010244a:	89 3c 24             	mov    %edi,(%esp)
f010244d:	e8 29 ea ff ff       	call   f0100e7b <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102452:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102459:	00 
f010245a:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102461:	00 
f0102462:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102467:	89 04 24             	mov    %eax,(%esp)
f010246a:	e8 6f ea ff ff       	call   f0100ede <pgdir_walk>
f010246f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102472:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f0102478:	8b 51 04             	mov    0x4(%ecx),%edx
f010247b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102481:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102484:	8b 15 64 79 11 f0    	mov    0xf0117964,%edx
f010248a:	89 55 c8             	mov    %edx,-0x38(%ebp)
f010248d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102490:	c1 ea 0c             	shr    $0xc,%edx
f0102493:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102496:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102499:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f010249c:	72 23                	jb     f01024c1 <mem_init+0x1320>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010249e:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01024a1:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01024a5:	c7 44 24 08 24 43 10 	movl   $0xf0104324,0x8(%esp)
f01024ac:	f0 
f01024ad:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f01024b4:	00 
f01024b5:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01024bc:	e8 d3 db ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01024c1:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01024c4:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f01024ca:	39 d0                	cmp    %edx,%eax
f01024cc:	74 24                	je     f01024f2 <mem_init+0x1351>
f01024ce:	c7 44 24 0c 2c 4d 10 	movl   $0xf0104d2c,0xc(%esp)
f01024d5:	f0 
f01024d6:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01024dd:	f0 
f01024de:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f01024e5:	00 
f01024e6:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01024ed:	e8 a2 db ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01024f2:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f01024f9:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024ff:	89 f8                	mov    %edi,%eax
f0102501:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102507:	c1 f8 03             	sar    $0x3,%eax
f010250a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010250d:	89 c1                	mov    %eax,%ecx
f010250f:	c1 e9 0c             	shr    $0xc,%ecx
f0102512:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0102515:	77 20                	ja     f0102537 <mem_init+0x1396>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102517:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010251b:	c7 44 24 08 24 43 10 	movl   $0xf0104324,0x8(%esp)
f0102522:	f0 
f0102523:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010252a:	00 
f010252b:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102532:	e8 5d db ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102537:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010253e:	00 
f010253f:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102546:	00 
	return (void *)(pa + KERNBASE);
f0102547:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010254c:	89 04 24             	mov    %eax,(%esp)
f010254f:	e8 af 13 00 00       	call   f0103903 <memset>
	page_free(pp0);
f0102554:	89 3c 24             	mov    %edi,(%esp)
f0102557:	e8 1f e9 ff ff       	call   f0100e7b <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010255c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102563:	00 
f0102564:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010256b:	00 
f010256c:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102571:	89 04 24             	mov    %eax,(%esp)
f0102574:	e8 65 e9 ff ff       	call   f0100ede <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102579:	89 fa                	mov    %edi,%edx
f010257b:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0102581:	c1 fa 03             	sar    $0x3,%edx
f0102584:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102587:	89 d0                	mov    %edx,%eax
f0102589:	c1 e8 0c             	shr    $0xc,%eax
f010258c:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0102592:	72 20                	jb     f01025b4 <mem_init+0x1413>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102594:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102598:	c7 44 24 08 24 43 10 	movl   $0xf0104324,0x8(%esp)
f010259f:	f0 
f01025a0:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01025a7:	00 
f01025a8:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01025af:	e8 e0 da ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01025b4:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01025ba:	89 45 e4             	mov    %eax,-0x1c(%ebp)
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01025bd:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01025c3:	f6 00 01             	testb  $0x1,(%eax)
f01025c6:	74 24                	je     f01025ec <mem_init+0x144b>
f01025c8:	c7 44 24 0c 44 4d 10 	movl   $0xf0104d44,0xc(%esp)
f01025cf:	f0 
f01025d0:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01025d7:	f0 
f01025d8:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
f01025df:	00 
f01025e0:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01025e7:	e8 a8 da ff ff       	call   f0100094 <_panic>
f01025ec:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01025ef:	39 d0                	cmp    %edx,%eax
f01025f1:	75 d0                	jne    f01025c3 <mem_init+0x1422>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01025f3:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01025f8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01025fe:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// give free list back
	page_free_list = fl;
f0102604:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102607:	89 0d 40 75 11 f0    	mov    %ecx,0xf0117540

	// free the pages we took
	page_free(pp0);
f010260d:	89 3c 24             	mov    %edi,(%esp)
f0102610:	e8 66 e8 ff ff       	call   f0100e7b <page_free>
	page_free(pp1);
f0102615:	89 34 24             	mov    %esi,(%esp)
f0102618:	e8 5e e8 ff ff       	call   f0100e7b <page_free>
	page_free(pp2);
f010261d:	89 1c 24             	mov    %ebx,(%esp)
f0102620:	e8 56 e8 ff ff       	call   f0100e7b <page_free>

	cprintf("check_page() succeeded!\n");
f0102625:	c7 04 24 5b 4d 10 f0 	movl   $0xf0104d5b,(%esp)
f010262c:	e8 ad 07 00 00       	call   f0102dde <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, 
f0102631:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102636:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010263b:	77 20                	ja     f010265d <mem_init+0x14bc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010263d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102641:	c7 44 24 08 30 44 10 	movl   $0xf0104430,0x8(%esp)
f0102648:	f0 
f0102649:	c7 44 24 04 b8 00 00 	movl   $0xb8,0x4(%esp)
f0102650:	00 
f0102651:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102658:	e8 37 da ff ff       	call   f0100094 <_panic>
			ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE), 
f010265d:	8b 15 64 79 11 f0    	mov    0xf0117964,%edx
f0102663:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f010266a:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, 
f0102670:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f0102677:	00 
	return (physaddr_t)kva - KERNBASE;
f0102678:	05 00 00 00 10       	add    $0x10000000,%eax
f010267d:	89 04 24             	mov    %eax,(%esp)
f0102680:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102685:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010268a:	e8 3e e9 ff ff       	call   f0100fcd <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010268f:	be 00 d0 10 f0       	mov    $0xf010d000,%esi
f0102694:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f010269a:	77 20                	ja     f01026bc <mem_init+0x151b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010269c:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01026a0:	c7 44 24 08 30 44 10 	movl   $0xf0104430,0x8(%esp)
f01026a7:	f0 
f01026a8:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
f01026af:	00 
f01026b0:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01026b7:	e8 d8 d9 ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE,
f01026bc:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01026c3:	00 
f01026c4:	c7 04 24 00 d0 10 00 	movl   $0x10d000,(%esp)
f01026cb:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01026d0:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01026d5:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01026da:	e8 ee e8 ff ff       	call   f0100fcd <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE,
f01026df:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01026e6:	00 
f01026e7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01026ee:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01026f3:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01026f8:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01026fd:	e8 cb e8 ff ff       	call   f0100fcd <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102702:	8b 1d 68 79 11 f0    	mov    0xf0117968,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102708:	8b 35 64 79 11 f0    	mov    0xf0117964,%esi
f010270e:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102711:	8d 3c f5 ff 0f 00 00 	lea    0xfff(,%esi,8),%edi
f0102718:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	for (i = 0; i < n; i += PGSIZE)
f010271e:	be 00 00 00 00       	mov    $0x0,%esi
f0102723:	eb 70                	jmp    f0102795 <mem_init+0x15f4>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102725:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010272b:	89 d8                	mov    %ebx,%eax
f010272d:	e8 d2 e1 ff ff       	call   f0100904 <check_va2pa>
f0102732:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102738:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f010273e:	77 20                	ja     f0102760 <mem_init+0x15bf>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102740:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102744:	c7 44 24 08 30 44 10 	movl   $0xf0104430,0x8(%esp)
f010274b:	f0 
f010274c:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f0102753:	00 
f0102754:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f010275b:	e8 34 d9 ff ff       	call   f0100094 <_panic>
f0102760:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f0102767:	39 d0                	cmp    %edx,%eax
f0102769:	74 24                	je     f010278f <mem_init+0x15ee>
f010276b:	c7 44 24 0c 08 49 10 	movl   $0xf0104908,0xc(%esp)
f0102772:	f0 
f0102773:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f010277a:	f0 
f010277b:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f0102782:	00 
f0102783:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f010278a:	e8 05 d9 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010278f:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102795:	39 f7                	cmp    %esi,%edi
f0102797:	77 8c                	ja     f0102725 <mem_init+0x1584>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102799:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010279c:	c1 e7 0c             	shl    $0xc,%edi
f010279f:	be 00 00 00 00       	mov    $0x0,%esi
f01027a4:	eb 3b                	jmp    f01027e1 <mem_init+0x1640>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01027a6:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01027ac:	89 d8                	mov    %ebx,%eax
f01027ae:	e8 51 e1 ff ff       	call   f0100904 <check_va2pa>
f01027b3:	39 c6                	cmp    %eax,%esi
f01027b5:	74 24                	je     f01027db <mem_init+0x163a>
f01027b7:	c7 44 24 0c 3c 49 10 	movl   $0xf010493c,0xc(%esp)
f01027be:	f0 
f01027bf:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01027c6:	f0 
f01027c7:	c7 44 24 04 b3 02 00 	movl   $0x2b3,0x4(%esp)
f01027ce:	00 
f01027cf:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01027d6:	e8 b9 d8 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01027db:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01027e1:	39 fe                	cmp    %edi,%esi
f01027e3:	72 c1                	jb     f01027a6 <mem_init+0x1605>
f01027e5:	be 00 80 ff ef       	mov    $0xefff8000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01027ea:	bf 00 d0 10 f0       	mov    $0xf010d000,%edi
f01027ef:	81 c7 00 80 00 20    	add    $0x20008000,%edi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01027f5:	89 f2                	mov    %esi,%edx
f01027f7:	89 d8                	mov    %ebx,%eax
f01027f9:	e8 06 e1 ff ff       	call   f0100904 <check_va2pa>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01027fe:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102801:	39 d0                	cmp    %edx,%eax
f0102803:	74 24                	je     f0102829 <mem_init+0x1688>
f0102805:	c7 44 24 0c 64 49 10 	movl   $0xf0104964,0xc(%esp)
f010280c:	f0 
f010280d:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0102814:	f0 
f0102815:	c7 44 24 04 b7 02 00 	movl   $0x2b7,0x4(%esp)
f010281c:	00 
f010281d:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102824:	e8 6b d8 ff ff       	call   f0100094 <_panic>
f0102829:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010282f:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102835:	75 be                	jne    f01027f5 <mem_init+0x1654>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102837:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f010283c:	89 d8                	mov    %ebx,%eax
f010283e:	e8 c1 e0 ff ff       	call   f0100904 <check_va2pa>
f0102843:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102846:	74 24                	je     f010286c <mem_init+0x16cb>
f0102848:	c7 44 24 0c ac 49 10 	movl   $0xf01049ac,0xc(%esp)
f010284f:	f0 
f0102850:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0102857:	f0 
f0102858:	c7 44 24 04 b8 02 00 	movl   $0x2b8,0x4(%esp)
f010285f:	00 
f0102860:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102867:	e8 28 d8 ff ff       	call   f0100094 <_panic>
f010286c:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102871:	ba 01 00 00 00       	mov    $0x1,%edx
f0102876:	8d 88 44 fc ff ff    	lea    -0x3bc(%eax),%ecx
f010287c:	83 f9 03             	cmp    $0x3,%ecx
f010287f:	77 39                	ja     f01028ba <mem_init+0x1719>
f0102881:	89 d6                	mov    %edx,%esi
f0102883:	d3 e6                	shl    %cl,%esi
f0102885:	89 f1                	mov    %esi,%ecx
f0102887:	f6 c1 0b             	test   $0xb,%cl
f010288a:	74 2e                	je     f01028ba <mem_init+0x1719>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f010288c:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102890:	0f 85 aa 00 00 00    	jne    f0102940 <mem_init+0x179f>
f0102896:	c7 44 24 0c 74 4d 10 	movl   $0xf0104d74,0xc(%esp)
f010289d:	f0 
f010289e:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01028a5:	f0 
f01028a6:	c7 44 24 04 c0 02 00 	movl   $0x2c0,0x4(%esp)
f01028ad:	00 
f01028ae:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01028b5:	e8 da d7 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01028ba:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01028bf:	76 55                	jbe    f0102916 <mem_init+0x1775>
				assert(pgdir[i] & PTE_P);
f01028c1:	8b 0c 83             	mov    (%ebx,%eax,4),%ecx
f01028c4:	f6 c1 01             	test   $0x1,%cl
f01028c7:	75 24                	jne    f01028ed <mem_init+0x174c>
f01028c9:	c7 44 24 0c 74 4d 10 	movl   $0xf0104d74,0xc(%esp)
f01028d0:	f0 
f01028d1:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01028d8:	f0 
f01028d9:	c7 44 24 04 c4 02 00 	movl   $0x2c4,0x4(%esp)
f01028e0:	00 
f01028e1:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01028e8:	e8 a7 d7 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f01028ed:	f6 c1 02             	test   $0x2,%cl
f01028f0:	75 4e                	jne    f0102940 <mem_init+0x179f>
f01028f2:	c7 44 24 0c 85 4d 10 	movl   $0xf0104d85,0xc(%esp)
f01028f9:	f0 
f01028fa:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0102901:	f0 
f0102902:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
f0102909:	00 
f010290a:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102911:	e8 7e d7 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102916:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f010291a:	74 24                	je     f0102940 <mem_init+0x179f>
f010291c:	c7 44 24 0c 96 4d 10 	movl   $0xf0104d96,0xc(%esp)
f0102923:	f0 
f0102924:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f010292b:	f0 
f010292c:	c7 44 24 04 c7 02 00 	movl   $0x2c7,0x4(%esp)
f0102933:	00 
f0102934:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f010293b:	e8 54 d7 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102940:	83 c0 01             	add    $0x1,%eax
f0102943:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102948:	0f 85 28 ff ff ff    	jne    f0102876 <mem_init+0x16d5>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010294e:	c7 04 24 dc 49 10 f0 	movl   $0xf01049dc,(%esp)
f0102955:	e8 84 04 00 00       	call   f0102dde <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010295a:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010295f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102964:	77 20                	ja     f0102986 <mem_init+0x17e5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102966:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010296a:	c7 44 24 08 30 44 10 	movl   $0xf0104430,0x8(%esp)
f0102971:	f0 
f0102972:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
f0102979:	00 
f010297a:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102981:	e8 0e d7 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102986:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010298b:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010298e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102993:	e8 7c e0 ff ff       	call   f0100a14 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102998:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f010299b:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f01029a0:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01029a3:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01029a6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01029ad:	e8 45 e4 ff ff       	call   f0100df7 <page_alloc>
f01029b2:	89 c6                	mov    %eax,%esi
f01029b4:	85 c0                	test   %eax,%eax
f01029b6:	75 24                	jne    f01029dc <mem_init+0x183b>
f01029b8:	c7 44 24 0c 92 4b 10 	movl   $0xf0104b92,0xc(%esp)
f01029bf:	f0 
f01029c0:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01029c7:	f0 
f01029c8:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f01029cf:	00 
f01029d0:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f01029d7:	e8 b8 d6 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01029dc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01029e3:	e8 0f e4 ff ff       	call   f0100df7 <page_alloc>
f01029e8:	89 c7                	mov    %eax,%edi
f01029ea:	85 c0                	test   %eax,%eax
f01029ec:	75 24                	jne    f0102a12 <mem_init+0x1871>
f01029ee:	c7 44 24 0c a8 4b 10 	movl   $0xf0104ba8,0xc(%esp)
f01029f5:	f0 
f01029f6:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f01029fd:	f0 
f01029fe:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f0102a05:	00 
f0102a06:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102a0d:	e8 82 d6 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102a12:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a19:	e8 d9 e3 ff ff       	call   f0100df7 <page_alloc>
f0102a1e:	89 c3                	mov    %eax,%ebx
f0102a20:	85 c0                	test   %eax,%eax
f0102a22:	75 24                	jne    f0102a48 <mem_init+0x18a7>
f0102a24:	c7 44 24 0c be 4b 10 	movl   $0xf0104bbe,0xc(%esp)
f0102a2b:	f0 
f0102a2c:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0102a33:	f0 
f0102a34:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f0102a3b:	00 
f0102a3c:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102a43:	e8 4c d6 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0102a48:	89 34 24             	mov    %esi,(%esp)
f0102a4b:	e8 2b e4 ff ff       	call   f0100e7b <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a50:	89 f8                	mov    %edi,%eax
f0102a52:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102a58:	c1 f8 03             	sar    $0x3,%eax
f0102a5b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a5e:	89 c2                	mov    %eax,%edx
f0102a60:	c1 ea 0c             	shr    $0xc,%edx
f0102a63:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0102a69:	72 20                	jb     f0102a8b <mem_init+0x18ea>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a6b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a6f:	c7 44 24 08 24 43 10 	movl   $0xf0104324,0x8(%esp)
f0102a76:	f0 
f0102a77:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102a7e:	00 
f0102a7f:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102a86:	e8 09 d6 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102a8b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a92:	00 
f0102a93:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102a9a:	00 
	return (void *)(pa + KERNBASE);
f0102a9b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102aa0:	89 04 24             	mov    %eax,(%esp)
f0102aa3:	e8 5b 0e 00 00       	call   f0103903 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102aa8:	89 d8                	mov    %ebx,%eax
f0102aaa:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102ab0:	c1 f8 03             	sar    $0x3,%eax
f0102ab3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ab6:	89 c2                	mov    %eax,%edx
f0102ab8:	c1 ea 0c             	shr    $0xc,%edx
f0102abb:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0102ac1:	72 20                	jb     f0102ae3 <mem_init+0x1942>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ac3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102ac7:	c7 44 24 08 24 43 10 	movl   $0xf0104324,0x8(%esp)
f0102ace:	f0 
f0102acf:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102ad6:	00 
f0102ad7:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102ade:	e8 b1 d5 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102ae3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102aea:	00 
f0102aeb:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102af2:	00 
	return (void *)(pa + KERNBASE);
f0102af3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102af8:	89 04 24             	mov    %eax,(%esp)
f0102afb:	e8 03 0e 00 00       	call   f0103903 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102b00:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102b07:	00 
f0102b08:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b0f:	00 
f0102b10:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102b14:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102b19:	89 04 24             	mov    %eax,(%esp)
f0102b1c:	e8 d6 e5 ff ff       	call   f01010f7 <page_insert>
	assert(pp1->pp_ref == 1);
f0102b21:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102b26:	74 24                	je     f0102b4c <mem_init+0x19ab>
f0102b28:	c7 44 24 0c 8f 4c 10 	movl   $0xf0104c8f,0xc(%esp)
f0102b2f:	f0 
f0102b30:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0102b37:	f0 
f0102b38:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f0102b3f:	00 
f0102b40:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102b47:	e8 48 d5 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102b4c:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102b53:	01 01 01 
f0102b56:	74 24                	je     f0102b7c <mem_init+0x19db>
f0102b58:	c7 44 24 0c fc 49 10 	movl   $0xf01049fc,0xc(%esp)
f0102b5f:	f0 
f0102b60:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0102b67:	f0 
f0102b68:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f0102b6f:	00 
f0102b70:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102b77:	e8 18 d5 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102b7c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102b83:	00 
f0102b84:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b8b:	00 
f0102b8c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102b90:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102b95:	89 04 24             	mov    %eax,(%esp)
f0102b98:	e8 5a e5 ff ff       	call   f01010f7 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102b9d:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102ba4:	02 02 02 
f0102ba7:	74 24                	je     f0102bcd <mem_init+0x1a2c>
f0102ba9:	c7 44 24 0c 20 4a 10 	movl   $0xf0104a20,0xc(%esp)
f0102bb0:	f0 
f0102bb1:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0102bb8:	f0 
f0102bb9:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f0102bc0:	00 
f0102bc1:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102bc8:	e8 c7 d4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102bcd:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102bd2:	74 24                	je     f0102bf8 <mem_init+0x1a57>
f0102bd4:	c7 44 24 0c b1 4c 10 	movl   $0xf0104cb1,0xc(%esp)
f0102bdb:	f0 
f0102bdc:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0102be3:	f0 
f0102be4:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f0102beb:	00 
f0102bec:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102bf3:	e8 9c d4 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102bf8:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102bfd:	74 24                	je     f0102c23 <mem_init+0x1a82>
f0102bff:	c7 44 24 0c 1b 4d 10 	movl   $0xf0104d1b,0xc(%esp)
f0102c06:	f0 
f0102c07:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0102c0e:	f0 
f0102c0f:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f0102c16:	00 
f0102c17:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102c1e:	e8 71 d4 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102c23:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102c2a:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c2d:	89 d8                	mov    %ebx,%eax
f0102c2f:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102c35:	c1 f8 03             	sar    $0x3,%eax
f0102c38:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c3b:	89 c2                	mov    %eax,%edx
f0102c3d:	c1 ea 0c             	shr    $0xc,%edx
f0102c40:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0102c46:	72 20                	jb     f0102c68 <mem_init+0x1ac7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c48:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c4c:	c7 44 24 08 24 43 10 	movl   $0xf0104324,0x8(%esp)
f0102c53:	f0 
f0102c54:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102c5b:	00 
f0102c5c:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102c63:	e8 2c d4 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102c68:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102c6f:	03 03 03 
f0102c72:	74 24                	je     f0102c98 <mem_init+0x1af7>
f0102c74:	c7 44 24 0c 44 4a 10 	movl   $0xf0104a44,0xc(%esp)
f0102c7b:	f0 
f0102c7c:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0102c83:	f0 
f0102c84:	c7 44 24 04 95 03 00 	movl   $0x395,0x4(%esp)
f0102c8b:	00 
f0102c8c:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102c93:	e8 fc d3 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102c98:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102c9f:	00 
f0102ca0:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102ca5:	89 04 24             	mov    %eax,(%esp)
f0102ca8:	e8 fa e3 ff ff       	call   f01010a7 <page_remove>
	assert(pp2->pp_ref == 0);
f0102cad:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102cb2:	74 24                	je     f0102cd8 <mem_init+0x1b37>
f0102cb4:	c7 44 24 0c e9 4c 10 	movl   $0xf0104ce9,0xc(%esp)
f0102cbb:	f0 
f0102cbc:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0102cc3:	f0 
f0102cc4:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f0102ccb:	00 
f0102ccc:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102cd3:	e8 bc d3 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102cd8:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102cdd:	8b 08                	mov    (%eax),%ecx
f0102cdf:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102ce5:	89 f2                	mov    %esi,%edx
f0102ce7:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0102ced:	c1 fa 03             	sar    $0x3,%edx
f0102cf0:	c1 e2 0c             	shl    $0xc,%edx
f0102cf3:	39 d1                	cmp    %edx,%ecx
f0102cf5:	74 24                	je     f0102d1b <mem_init+0x1b7a>
f0102cf7:	c7 44 24 0c 88 45 10 	movl   $0xf0104588,0xc(%esp)
f0102cfe:	f0 
f0102cff:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0102d06:	f0 
f0102d07:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f0102d0e:	00 
f0102d0f:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102d16:	e8 79 d3 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102d1b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102d21:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102d26:	74 24                	je     f0102d4c <mem_init+0x1bab>
f0102d28:	c7 44 24 0c a0 4c 10 	movl   $0xf0104ca0,0xc(%esp)
f0102d2f:	f0 
f0102d30:	c7 44 24 08 d2 4a 10 	movl   $0xf0104ad2,0x8(%esp)
f0102d37:	f0 
f0102d38:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f0102d3f:	00 
f0102d40:	c7 04 24 9c 4a 10 f0 	movl   $0xf0104a9c,(%esp)
f0102d47:	e8 48 d3 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102d4c:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102d52:	89 34 24             	mov    %esi,(%esp)
f0102d55:	e8 21 e1 ff ff       	call   f0100e7b <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102d5a:	c7 04 24 70 4a 10 f0 	movl   $0xf0104a70,(%esp)
f0102d61:	e8 78 00 00 00       	call   f0102dde <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102d66:	83 c4 3c             	add    $0x3c,%esp
f0102d69:	5b                   	pop    %ebx
f0102d6a:	5e                   	pop    %esi
f0102d6b:	5f                   	pop    %edi
f0102d6c:	5d                   	pop    %ebp
f0102d6d:	c3                   	ret    
	...

f0102d70 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102d70:	55                   	push   %ebp
f0102d71:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102d73:	ba 70 00 00 00       	mov    $0x70,%edx
f0102d78:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d7b:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102d7c:	b2 71                	mov    $0x71,%dl
f0102d7e:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102d7f:	0f b6 c0             	movzbl %al,%eax
}
f0102d82:	5d                   	pop    %ebp
f0102d83:	c3                   	ret    

f0102d84 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102d84:	55                   	push   %ebp
f0102d85:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102d87:	ba 70 00 00 00       	mov    $0x70,%edx
f0102d8c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d8f:	ee                   	out    %al,(%dx)
f0102d90:	b2 71                	mov    $0x71,%dl
f0102d92:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d95:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102d96:	5d                   	pop    %ebp
f0102d97:	c3                   	ret    

f0102d98 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102d98:	55                   	push   %ebp
f0102d99:	89 e5                	mov    %esp,%ebp
f0102d9b:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102d9e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102da1:	89 04 24             	mov    %eax,(%esp)
f0102da4:	e8 43 d8 ff ff       	call   f01005ec <cputchar>
	*cnt++;
}
f0102da9:	c9                   	leave  
f0102daa:	c3                   	ret    

f0102dab <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102dab:	55                   	push   %ebp
f0102dac:	89 e5                	mov    %esp,%ebp
f0102dae:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102db1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102db8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102dbb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102dbf:	8b 45 08             	mov    0x8(%ebp),%eax
f0102dc2:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102dc6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102dc9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102dcd:	c7 04 24 98 2d 10 f0 	movl   $0xf0102d98,(%esp)
f0102dd4:	e8 94 04 00 00       	call   f010326d <vprintfmt>
	return cnt;
}
f0102dd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102ddc:	c9                   	leave  
f0102ddd:	c3                   	ret    

f0102dde <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102dde:	55                   	push   %ebp
f0102ddf:	89 e5                	mov    %esp,%ebp
f0102de1:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102de4:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102de7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102deb:	8b 45 08             	mov    0x8(%ebp),%eax
f0102dee:	89 04 24             	mov    %eax,(%esp)
f0102df1:	e8 b5 ff ff ff       	call   f0102dab <vcprintf>
	va_end(ap);

	return cnt;
}
f0102df6:	c9                   	leave  
f0102df7:	c3                   	ret    
	...

f0102e00 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102e00:	55                   	push   %ebp
f0102e01:	89 e5                	mov    %esp,%ebp
f0102e03:	57                   	push   %edi
f0102e04:	56                   	push   %esi
f0102e05:	53                   	push   %ebx
f0102e06:	83 ec 10             	sub    $0x10,%esp
f0102e09:	89 c3                	mov    %eax,%ebx
f0102e0b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102e0e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102e11:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102e14:	8b 0a                	mov    (%edx),%ecx
f0102e16:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102e19:	8b 00                	mov    (%eax),%eax
f0102e1b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102e1e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0102e25:	eb 77                	jmp    f0102e9e <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0102e27:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102e2a:	01 c8                	add    %ecx,%eax
f0102e2c:	bf 02 00 00 00       	mov    $0x2,%edi
f0102e31:	99                   	cltd   
f0102e32:	f7 ff                	idiv   %edi
f0102e34:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102e36:	eb 01                	jmp    f0102e39 <stab_binsearch+0x39>
			m--;
f0102e38:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102e39:	39 ca                	cmp    %ecx,%edx
f0102e3b:	7c 1d                	jl     f0102e5a <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102e3d:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102e40:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0102e45:	39 f7                	cmp    %esi,%edi
f0102e47:	75 ef                	jne    f0102e38 <stab_binsearch+0x38>
f0102e49:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102e4c:	6b fa 0c             	imul   $0xc,%edx,%edi
f0102e4f:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0102e53:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102e56:	73 18                	jae    f0102e70 <stab_binsearch+0x70>
f0102e58:	eb 05                	jmp    f0102e5f <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102e5a:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0102e5d:	eb 3f                	jmp    f0102e9e <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102e5f:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102e62:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0102e64:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102e67:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102e6e:	eb 2e                	jmp    f0102e9e <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102e70:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102e73:	76 15                	jbe    f0102e8a <stab_binsearch+0x8a>
			*region_right = m - 1;
f0102e75:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102e78:	4f                   	dec    %edi
f0102e79:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0102e7c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102e7f:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102e81:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102e88:	eb 14                	jmp    f0102e9e <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102e8a:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102e8d:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102e90:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0102e92:	ff 45 0c             	incl   0xc(%ebp)
f0102e95:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102e97:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102e9e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0102ea1:	7e 84                	jle    f0102e27 <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102ea3:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102ea7:	75 0d                	jne    f0102eb6 <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0102ea9:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102eac:	8b 02                	mov    (%edx),%eax
f0102eae:	48                   	dec    %eax
f0102eaf:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102eb2:	89 01                	mov    %eax,(%ecx)
f0102eb4:	eb 22                	jmp    f0102ed8 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102eb6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102eb9:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102ebb:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102ebe:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102ec0:	eb 01                	jmp    f0102ec3 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102ec2:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102ec3:	39 c1                	cmp    %eax,%ecx
f0102ec5:	7d 0c                	jge    f0102ed3 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102ec7:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0102eca:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0102ecf:	39 f2                	cmp    %esi,%edx
f0102ed1:	75 ef                	jne    f0102ec2 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102ed3:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102ed6:	89 02                	mov    %eax,(%edx)
	}
}
f0102ed8:	83 c4 10             	add    $0x10,%esp
f0102edb:	5b                   	pop    %ebx
f0102edc:	5e                   	pop    %esi
f0102edd:	5f                   	pop    %edi
f0102ede:	5d                   	pop    %ebp
f0102edf:	c3                   	ret    

f0102ee0 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102ee0:	55                   	push   %ebp
f0102ee1:	89 e5                	mov    %esp,%ebp
f0102ee3:	83 ec 58             	sub    $0x58,%esp
f0102ee6:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0102ee9:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0102eec:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0102eef:	8b 75 08             	mov    0x8(%ebp),%esi
f0102ef2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102ef5:	c7 03 a4 4d 10 f0    	movl   $0xf0104da4,(%ebx)
	info->eip_line = 0;
f0102efb:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102f02:	c7 43 08 a4 4d 10 f0 	movl   $0xf0104da4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102f09:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102f10:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102f13:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102f1a:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102f20:	76 12                	jbe    f0102f34 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102f22:	b8 e3 ce 10 f0       	mov    $0xf010cee3,%eax
f0102f27:	3d 75 b0 10 f0       	cmp    $0xf010b075,%eax
f0102f2c:	0f 86 b2 01 00 00    	jbe    f01030e4 <debuginfo_eip+0x204>
f0102f32:	eb 1c                	jmp    f0102f50 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102f34:	c7 44 24 08 ae 4d 10 	movl   $0xf0104dae,0x8(%esp)
f0102f3b:	f0 
f0102f3c:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0102f43:	00 
f0102f44:	c7 04 24 bb 4d 10 f0 	movl   $0xf0104dbb,(%esp)
f0102f4b:	e8 44 d1 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102f50:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102f55:	80 3d e2 ce 10 f0 00 	cmpb   $0x0,0xf010cee2
f0102f5c:	0f 85 8e 01 00 00    	jne    f01030f0 <debuginfo_eip+0x210>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102f62:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102f69:	b8 74 b0 10 f0       	mov    $0xf010b074,%eax
f0102f6e:	2d d8 4f 10 f0       	sub    $0xf0104fd8,%eax
f0102f73:	c1 f8 02             	sar    $0x2,%eax
f0102f76:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102f7c:	83 e8 01             	sub    $0x1,%eax
f0102f7f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102f82:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f86:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102f8d:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102f90:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102f93:	b8 d8 4f 10 f0       	mov    $0xf0104fd8,%eax
f0102f98:	e8 63 fe ff ff       	call   f0102e00 <stab_binsearch>
	if (lfile == 0)
f0102f9d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0102fa0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0102fa5:	85 d2                	test   %edx,%edx
f0102fa7:	0f 84 43 01 00 00    	je     f01030f0 <debuginfo_eip+0x210>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102fad:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0102fb0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102fb3:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102fb6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102fba:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102fc1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102fc4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102fc7:	b8 d8 4f 10 f0       	mov    $0xf0104fd8,%eax
f0102fcc:	e8 2f fe ff ff       	call   f0102e00 <stab_binsearch>

	if (lfun <= rfun) {
f0102fd1:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102fd4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102fd7:	39 d0                	cmp    %edx,%eax
f0102fd9:	7f 3d                	jg     f0103018 <debuginfo_eip+0x138>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102fdb:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0102fde:	8d b9 d8 4f 10 f0    	lea    -0xfefb028(%ecx),%edi
f0102fe4:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0102fe7:	8b 89 d8 4f 10 f0    	mov    -0xfefb028(%ecx),%ecx
f0102fed:	bf e3 ce 10 f0       	mov    $0xf010cee3,%edi
f0102ff2:	81 ef 75 b0 10 f0    	sub    $0xf010b075,%edi
f0102ff8:	39 f9                	cmp    %edi,%ecx
f0102ffa:	73 09                	jae    f0103005 <debuginfo_eip+0x125>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102ffc:	81 c1 75 b0 10 f0    	add    $0xf010b075,%ecx
f0103002:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103005:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103008:	8b 4f 08             	mov    0x8(%edi),%ecx
f010300b:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f010300e:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103010:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103013:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0103016:	eb 0f                	jmp    f0103027 <debuginfo_eip+0x147>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103018:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f010301b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010301e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103021:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103024:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103027:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f010302e:	00 
f010302f:	8b 43 08             	mov    0x8(%ebx),%eax
f0103032:	89 04 24             	mov    %eax,(%esp)
f0103035:	e8 ad 08 00 00       	call   f01038e7 <strfind>
f010303a:	2b 43 08             	sub    0x8(%ebx),%eax
f010303d:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103040:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103044:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f010304b:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010304e:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103051:	b8 d8 4f 10 f0       	mov    $0xf0104fd8,%eax
f0103056:	e8 a5 fd ff ff       	call   f0102e00 <stab_binsearch>
	if (lline <= rline)
f010305b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
		info->eip_line = stabs[lline].n_desc;
	else
		return -1;
f010305e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if (lline <= rline)
f0103063:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0103066:	0f 8f 84 00 00 00    	jg     f01030f0 <debuginfo_eip+0x210>
		info->eip_line = stabs[lline].n_desc;
f010306c:	6b d2 0c             	imul   $0xc,%edx,%edx
f010306f:	0f b7 82 de 4f 10 f0 	movzwl -0xfefb022(%edx),%eax
f0103076:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103079:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010307c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010307f:	eb 03                	jmp    f0103084 <debuginfo_eip+0x1a4>
f0103081:	83 e8 01             	sub    $0x1,%eax
f0103084:	89 c6                	mov    %eax,%esi
f0103086:	39 c7                	cmp    %eax,%edi
f0103088:	7f 27                	jg     f01030b1 <debuginfo_eip+0x1d1>
	       && stabs[lline].n_type != N_SOL
f010308a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010308d:	8d 0c 95 d8 4f 10 f0 	lea    -0xfefb028(,%edx,4),%ecx
f0103094:	0f b6 51 04          	movzbl 0x4(%ecx),%edx
f0103098:	80 fa 84             	cmp    $0x84,%dl
f010309b:	74 60                	je     f01030fd <debuginfo_eip+0x21d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010309d:	80 fa 64             	cmp    $0x64,%dl
f01030a0:	75 df                	jne    f0103081 <debuginfo_eip+0x1a1>
f01030a2:	83 79 08 00          	cmpl   $0x0,0x8(%ecx)
f01030a6:	74 d9                	je     f0103081 <debuginfo_eip+0x1a1>
f01030a8:	eb 53                	jmp    f01030fd <debuginfo_eip+0x21d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f01030aa:	05 75 b0 10 f0       	add    $0xf010b075,%eax
f01030af:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01030b1:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01030b4:	8b 55 d8             	mov    -0x28(%ebp),%edx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01030b7:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01030bc:	39 d1                	cmp    %edx,%ecx
f01030be:	7d 30                	jge    f01030f0 <debuginfo_eip+0x210>
		for (lline = lfun + 1;
f01030c0:	8d 41 01             	lea    0x1(%ecx),%eax
f01030c3:	eb 04                	jmp    f01030c9 <debuginfo_eip+0x1e9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01030c5:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01030c9:	39 d0                	cmp    %edx,%eax
f01030cb:	7d 1e                	jge    f01030eb <debuginfo_eip+0x20b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01030cd:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01030d0:	83 c0 01             	add    $0x1,%eax
f01030d3:	80 3c 8d dc 4f 10 f0 	cmpb   $0xa0,-0xfefb024(,%ecx,4)
f01030da:	a0 
f01030db:	74 e8                	je     f01030c5 <debuginfo_eip+0x1e5>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01030dd:	b8 00 00 00 00       	mov    $0x0,%eax
f01030e2:	eb 0c                	jmp    f01030f0 <debuginfo_eip+0x210>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01030e4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01030e9:	eb 05                	jmp    f01030f0 <debuginfo_eip+0x210>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01030eb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01030f0:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01030f3:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01030f6:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01030f9:	89 ec                	mov    %ebp,%esp
f01030fb:	5d                   	pop    %ebp
f01030fc:	c3                   	ret    
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01030fd:	6b f6 0c             	imul   $0xc,%esi,%esi
f0103100:	8b 86 d8 4f 10 f0    	mov    -0xfefb028(%esi),%eax
f0103106:	ba e3 ce 10 f0       	mov    $0xf010cee3,%edx
f010310b:	81 ea 75 b0 10 f0    	sub    $0xf010b075,%edx
f0103111:	39 d0                	cmp    %edx,%eax
f0103113:	72 95                	jb     f01030aa <debuginfo_eip+0x1ca>
f0103115:	eb 9a                	jmp    f01030b1 <debuginfo_eip+0x1d1>
	...

f0103120 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103120:	55                   	push   %ebp
f0103121:	89 e5                	mov    %esp,%ebp
f0103123:	57                   	push   %edi
f0103124:	56                   	push   %esi
f0103125:	53                   	push   %ebx
f0103126:	83 ec 3c             	sub    $0x3c,%esp
f0103129:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010312c:	89 d7                	mov    %edx,%edi
f010312e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103131:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103134:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103137:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010313a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010313d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103140:	85 c0                	test   %eax,%eax
f0103142:	75 08                	jne    f010314c <printnum+0x2c>
f0103144:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103147:	39 45 10             	cmp    %eax,0x10(%ebp)
f010314a:	77 59                	ja     f01031a5 <printnum+0x85>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010314c:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103150:	83 eb 01             	sub    $0x1,%ebx
f0103153:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103157:	8b 45 10             	mov    0x10(%ebp),%eax
f010315a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010315e:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0103162:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0103166:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010316d:	00 
f010316e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103171:	89 04 24             	mov    %eax,(%esp)
f0103174:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103177:	89 44 24 04          	mov    %eax,0x4(%esp)
f010317b:	e8 b0 09 00 00       	call   f0103b30 <__udivdi3>
f0103180:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103184:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103188:	89 04 24             	mov    %eax,(%esp)
f010318b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010318f:	89 fa                	mov    %edi,%edx
f0103191:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103194:	e8 87 ff ff ff       	call   f0103120 <printnum>
f0103199:	eb 11                	jmp    f01031ac <printnum+0x8c>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010319b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010319f:	89 34 24             	mov    %esi,(%esp)
f01031a2:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01031a5:	83 eb 01             	sub    $0x1,%ebx
f01031a8:	85 db                	test   %ebx,%ebx
f01031aa:	7f ef                	jg     f010319b <printnum+0x7b>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01031ac:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01031b0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01031b4:	8b 45 10             	mov    0x10(%ebp),%eax
f01031b7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01031bb:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01031c2:	00 
f01031c3:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01031c6:	89 04 24             	mov    %eax,(%esp)
f01031c9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01031cc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01031d0:	e8 8b 0a 00 00       	call   f0103c60 <__umoddi3>
f01031d5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01031d9:	0f be 80 c9 4d 10 f0 	movsbl -0xfefb237(%eax),%eax
f01031e0:	89 04 24             	mov    %eax,(%esp)
f01031e3:	ff 55 e4             	call   *-0x1c(%ebp)
}
f01031e6:	83 c4 3c             	add    $0x3c,%esp
f01031e9:	5b                   	pop    %ebx
f01031ea:	5e                   	pop    %esi
f01031eb:	5f                   	pop    %edi
f01031ec:	5d                   	pop    %ebp
f01031ed:	c3                   	ret    

f01031ee <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01031ee:	55                   	push   %ebp
f01031ef:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01031f1:	83 fa 01             	cmp    $0x1,%edx
f01031f4:	7e 0e                	jle    f0103204 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01031f6:	8b 10                	mov    (%eax),%edx
f01031f8:	8d 4a 08             	lea    0x8(%edx),%ecx
f01031fb:	89 08                	mov    %ecx,(%eax)
f01031fd:	8b 02                	mov    (%edx),%eax
f01031ff:	8b 52 04             	mov    0x4(%edx),%edx
f0103202:	eb 22                	jmp    f0103226 <getuint+0x38>
	else if (lflag)
f0103204:	85 d2                	test   %edx,%edx
f0103206:	74 10                	je     f0103218 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103208:	8b 10                	mov    (%eax),%edx
f010320a:	8d 4a 04             	lea    0x4(%edx),%ecx
f010320d:	89 08                	mov    %ecx,(%eax)
f010320f:	8b 02                	mov    (%edx),%eax
f0103211:	ba 00 00 00 00       	mov    $0x0,%edx
f0103216:	eb 0e                	jmp    f0103226 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103218:	8b 10                	mov    (%eax),%edx
f010321a:	8d 4a 04             	lea    0x4(%edx),%ecx
f010321d:	89 08                	mov    %ecx,(%eax)
f010321f:	8b 02                	mov    (%edx),%eax
f0103221:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103226:	5d                   	pop    %ebp
f0103227:	c3                   	ret    

f0103228 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103228:	55                   	push   %ebp
f0103229:	89 e5                	mov    %esp,%ebp
f010322b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010322e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103232:	8b 10                	mov    (%eax),%edx
f0103234:	3b 50 04             	cmp    0x4(%eax),%edx
f0103237:	73 0a                	jae    f0103243 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103239:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010323c:	88 0a                	mov    %cl,(%edx)
f010323e:	83 c2 01             	add    $0x1,%edx
f0103241:	89 10                	mov    %edx,(%eax)
}
f0103243:	5d                   	pop    %ebp
f0103244:	c3                   	ret    

f0103245 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103245:	55                   	push   %ebp
f0103246:	89 e5                	mov    %esp,%ebp
f0103248:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010324b:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010324e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103252:	8b 45 10             	mov    0x10(%ebp),%eax
f0103255:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103259:	8b 45 0c             	mov    0xc(%ebp),%eax
f010325c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103260:	8b 45 08             	mov    0x8(%ebp),%eax
f0103263:	89 04 24             	mov    %eax,(%esp)
f0103266:	e8 02 00 00 00       	call   f010326d <vprintfmt>
	va_end(ap);
}
f010326b:	c9                   	leave  
f010326c:	c3                   	ret    

f010326d <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010326d:	55                   	push   %ebp
f010326e:	89 e5                	mov    %esp,%ebp
f0103270:	57                   	push   %edi
f0103271:	56                   	push   %esi
f0103272:	53                   	push   %ebx
f0103273:	83 ec 4c             	sub    $0x4c,%esp
f0103276:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103279:	8b 75 10             	mov    0x10(%ebp),%esi
f010327c:	eb 12                	jmp    f0103290 <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010327e:	85 c0                	test   %eax,%eax
f0103280:	0f 84 9f 03 00 00    	je     f0103625 <vprintfmt+0x3b8>
				return;
			putch(ch, putdat);
f0103286:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010328a:	89 04 24             	mov    %eax,(%esp)
f010328d:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103290:	0f b6 06             	movzbl (%esi),%eax
f0103293:	83 c6 01             	add    $0x1,%esi
f0103296:	83 f8 25             	cmp    $0x25,%eax
f0103299:	75 e3                	jne    f010327e <vprintfmt+0x11>
f010329b:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f010329f:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01032a6:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f01032ab:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f01032b2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01032b7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01032ba:	eb 2b                	jmp    f01032e7 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032bc:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f01032bf:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f01032c3:	eb 22                	jmp    f01032e7 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032c5:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01032c8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f01032cc:	eb 19                	jmp    f01032e7 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032ce:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f01032d1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01032d8:	eb 0d                	jmp    f01032e7 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01032da:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01032dd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01032e0:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032e7:	0f b6 16             	movzbl (%esi),%edx
f01032ea:	0f b6 c2             	movzbl %dl,%eax
f01032ed:	8d 7e 01             	lea    0x1(%esi),%edi
f01032f0:	89 7d e0             	mov    %edi,-0x20(%ebp)
f01032f3:	83 ea 23             	sub    $0x23,%edx
f01032f6:	80 fa 55             	cmp    $0x55,%dl
f01032f9:	0f 87 08 03 00 00    	ja     f0103607 <vprintfmt+0x39a>
f01032ff:	0f b6 d2             	movzbl %dl,%edx
f0103302:	ff 24 95 54 4e 10 f0 	jmp    *-0xfefb1ac(,%edx,4)
f0103309:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010330c:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f0103313:	bf 00 00 00 00       	mov    $0x0,%edi
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103318:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f010331b:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f010331f:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0103322:	8d 50 d0             	lea    -0x30(%eax),%edx
f0103325:	83 fa 09             	cmp    $0x9,%edx
f0103328:	77 2f                	ja     f0103359 <vprintfmt+0xec>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010332a:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f010332d:	eb e9                	jmp    f0103318 <vprintfmt+0xab>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010332f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103332:	8d 50 04             	lea    0x4(%eax),%edx
f0103335:	89 55 14             	mov    %edx,0x14(%ebp)
f0103338:	8b 00                	mov    (%eax),%eax
f010333a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010333d:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103340:	eb 1a                	jmp    f010335c <vprintfmt+0xef>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103342:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f0103345:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103349:	79 9c                	jns    f01032e7 <vprintfmt+0x7a>
f010334b:	eb 81                	jmp    f01032ce <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010334d:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103350:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0103357:	eb 8e                	jmp    f01032e7 <vprintfmt+0x7a>
f0103359:	89 7d d4             	mov    %edi,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f010335c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103360:	79 85                	jns    f01032e7 <vprintfmt+0x7a>
f0103362:	e9 73 ff ff ff       	jmp    f01032da <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103367:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010336a:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010336d:	e9 75 ff ff ff       	jmp    f01032e7 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103372:	8b 45 14             	mov    0x14(%ebp),%eax
f0103375:	8d 50 04             	lea    0x4(%eax),%edx
f0103378:	89 55 14             	mov    %edx,0x14(%ebp)
f010337b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010337f:	8b 00                	mov    (%eax),%eax
f0103381:	89 04 24             	mov    %eax,(%esp)
f0103384:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103387:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f010338a:	e9 01 ff ff ff       	jmp    f0103290 <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010338f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103392:	8d 50 04             	lea    0x4(%eax),%edx
f0103395:	89 55 14             	mov    %edx,0x14(%ebp)
f0103398:	8b 00                	mov    (%eax),%eax
f010339a:	89 c2                	mov    %eax,%edx
f010339c:	c1 fa 1f             	sar    $0x1f,%edx
f010339f:	31 d0                	xor    %edx,%eax
f01033a1:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01033a3:	83 f8 06             	cmp    $0x6,%eax
f01033a6:	7f 0b                	jg     f01033b3 <vprintfmt+0x146>
f01033a8:	8b 14 85 ac 4f 10 f0 	mov    -0xfefb054(,%eax,4),%edx
f01033af:	85 d2                	test   %edx,%edx
f01033b1:	75 23                	jne    f01033d6 <vprintfmt+0x169>
				printfmt(putch, putdat, "error %d", err);
f01033b3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01033b7:	c7 44 24 08 e1 4d 10 	movl   $0xf0104de1,0x8(%esp)
f01033be:	f0 
f01033bf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01033c3:	8b 7d 08             	mov    0x8(%ebp),%edi
f01033c6:	89 3c 24             	mov    %edi,(%esp)
f01033c9:	e8 77 fe ff ff       	call   f0103245 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01033ce:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01033d1:	e9 ba fe ff ff       	jmp    f0103290 <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f01033d6:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01033da:	c7 44 24 08 e4 4a 10 	movl   $0xf0104ae4,0x8(%esp)
f01033e1:	f0 
f01033e2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01033e6:	8b 7d 08             	mov    0x8(%ebp),%edi
f01033e9:	89 3c 24             	mov    %edi,(%esp)
f01033ec:	e8 54 fe ff ff       	call   f0103245 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01033f1:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01033f4:	e9 97 fe ff ff       	jmp    f0103290 <vprintfmt+0x23>
f01033f9:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01033fc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01033ff:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103402:	8b 45 14             	mov    0x14(%ebp),%eax
f0103405:	8d 50 04             	lea    0x4(%eax),%edx
f0103408:	89 55 14             	mov    %edx,0x14(%ebp)
f010340b:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010340d:	85 f6                	test   %esi,%esi
f010340f:	ba da 4d 10 f0       	mov    $0xf0104dda,%edx
f0103414:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f0103417:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f010341b:	0f 8e 8c 00 00 00    	jle    f01034ad <vprintfmt+0x240>
f0103421:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0103425:	0f 84 82 00 00 00    	je     f01034ad <vprintfmt+0x240>
				for (width -= strnlen(p, precision); width > 0; width--)
f010342b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010342f:	89 34 24             	mov    %esi,(%esp)
f0103432:	e8 61 03 00 00       	call   f0103798 <strnlen>
f0103437:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010343a:	29 c2                	sub    %eax,%edx
f010343c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
					putch(padc, putdat);
f010343f:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0103443:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0103446:	89 7d cc             	mov    %edi,-0x34(%ebp)
f0103449:	89 de                	mov    %ebx,%esi
f010344b:	89 d3                	mov    %edx,%ebx
f010344d:	89 c7                	mov    %eax,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010344f:	eb 0d                	jmp    f010345e <vprintfmt+0x1f1>
					putch(padc, putdat);
f0103451:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103455:	89 3c 24             	mov    %edi,(%esp)
f0103458:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010345b:	83 eb 01             	sub    $0x1,%ebx
f010345e:	85 db                	test   %ebx,%ebx
f0103460:	7f ef                	jg     f0103451 <vprintfmt+0x1e4>
f0103462:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0103465:	89 f3                	mov    %esi,%ebx
f0103467:	8b 75 d0             	mov    -0x30(%ebp),%esi

// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
f010346a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010346e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103473:	0f 49 45 e4          	cmovns -0x1c(%ebp),%eax
f0103477:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010347a:	29 c2                	sub    %eax,%edx
f010347c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010347f:	eb 2c                	jmp    f01034ad <vprintfmt+0x240>
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103481:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103485:	74 18                	je     f010349f <vprintfmt+0x232>
f0103487:	8d 50 e0             	lea    -0x20(%eax),%edx
f010348a:	83 fa 5e             	cmp    $0x5e,%edx
f010348d:	76 10                	jbe    f010349f <vprintfmt+0x232>
					putch('?', putdat);
f010348f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103493:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f010349a:	ff 55 08             	call   *0x8(%ebp)
f010349d:	eb 0a                	jmp    f01034a9 <vprintfmt+0x23c>
				else
					putch(ch, putdat);
f010349f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01034a3:	89 04 24             	mov    %eax,(%esp)
f01034a6:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01034a9:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f01034ad:	0f be 06             	movsbl (%esi),%eax
f01034b0:	83 c6 01             	add    $0x1,%esi
f01034b3:	85 c0                	test   %eax,%eax
f01034b5:	74 25                	je     f01034dc <vprintfmt+0x26f>
f01034b7:	85 ff                	test   %edi,%edi
f01034b9:	78 c6                	js     f0103481 <vprintfmt+0x214>
f01034bb:	83 ef 01             	sub    $0x1,%edi
f01034be:	79 c1                	jns    f0103481 <vprintfmt+0x214>
f01034c0:	8b 7d 08             	mov    0x8(%ebp),%edi
f01034c3:	89 de                	mov    %ebx,%esi
f01034c5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01034c8:	eb 1a                	jmp    f01034e4 <vprintfmt+0x277>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01034ca:	89 74 24 04          	mov    %esi,0x4(%esp)
f01034ce:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01034d5:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01034d7:	83 eb 01             	sub    $0x1,%ebx
f01034da:	eb 08                	jmp    f01034e4 <vprintfmt+0x277>
f01034dc:	8b 7d 08             	mov    0x8(%ebp),%edi
f01034df:	89 de                	mov    %ebx,%esi
f01034e1:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01034e4:	85 db                	test   %ebx,%ebx
f01034e6:	7f e2                	jg     f01034ca <vprintfmt+0x25d>
f01034e8:	89 7d 08             	mov    %edi,0x8(%ebp)
f01034eb:	89 f3                	mov    %esi,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034ed:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01034f0:	e9 9b fd ff ff       	jmp    f0103290 <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01034f5:	83 f9 01             	cmp    $0x1,%ecx
f01034f8:	7e 10                	jle    f010350a <vprintfmt+0x29d>
		return va_arg(*ap, long long);
f01034fa:	8b 45 14             	mov    0x14(%ebp),%eax
f01034fd:	8d 50 08             	lea    0x8(%eax),%edx
f0103500:	89 55 14             	mov    %edx,0x14(%ebp)
f0103503:	8b 30                	mov    (%eax),%esi
f0103505:	8b 78 04             	mov    0x4(%eax),%edi
f0103508:	eb 26                	jmp    f0103530 <vprintfmt+0x2c3>
	else if (lflag)
f010350a:	85 c9                	test   %ecx,%ecx
f010350c:	74 12                	je     f0103520 <vprintfmt+0x2b3>
		return va_arg(*ap, long);
f010350e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103511:	8d 50 04             	lea    0x4(%eax),%edx
f0103514:	89 55 14             	mov    %edx,0x14(%ebp)
f0103517:	8b 30                	mov    (%eax),%esi
f0103519:	89 f7                	mov    %esi,%edi
f010351b:	c1 ff 1f             	sar    $0x1f,%edi
f010351e:	eb 10                	jmp    f0103530 <vprintfmt+0x2c3>
	else
		return va_arg(*ap, int);
f0103520:	8b 45 14             	mov    0x14(%ebp),%eax
f0103523:	8d 50 04             	lea    0x4(%eax),%edx
f0103526:	89 55 14             	mov    %edx,0x14(%ebp)
f0103529:	8b 30                	mov    (%eax),%esi
f010352b:	89 f7                	mov    %esi,%edi
f010352d:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103530:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103535:	85 ff                	test   %edi,%edi
f0103537:	0f 89 8c 00 00 00    	jns    f01035c9 <vprintfmt+0x35c>
				putch('-', putdat);
f010353d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103541:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0103548:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010354b:	f7 de                	neg    %esi
f010354d:	83 d7 00             	adc    $0x0,%edi
f0103550:	f7 df                	neg    %edi
			}
			base = 10;
f0103552:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103557:	eb 70                	jmp    f01035c9 <vprintfmt+0x35c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103559:	89 ca                	mov    %ecx,%edx
f010355b:	8d 45 14             	lea    0x14(%ebp),%eax
f010355e:	e8 8b fc ff ff       	call   f01031ee <getuint>
f0103563:	89 c6                	mov    %eax,%esi
f0103565:	89 d7                	mov    %edx,%edi
			base = 10;
f0103567:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010356c:	eb 5b                	jmp    f01035c9 <vprintfmt+0x35c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num=getuint(&ap,lflag);
f010356e:	89 ca                	mov    %ecx,%edx
f0103570:	8d 45 14             	lea    0x14(%ebp),%eax
f0103573:	e8 76 fc ff ff       	call   f01031ee <getuint>
f0103578:	89 c6                	mov    %eax,%esi
f010357a:	89 d7                	mov    %edx,%edi
			base = 8;
f010357c:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0103581:	eb 46                	jmp    f01035c9 <vprintfmt+0x35c>
	
		// pointer
		case 'p':
			putch('0', putdat);
f0103583:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103587:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010358e:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103591:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103595:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010359c:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010359f:	8b 45 14             	mov    0x14(%ebp),%eax
f01035a2:	8d 50 04             	lea    0x4(%eax),%edx
f01035a5:	89 55 14             	mov    %edx,0x14(%ebp)
	
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01035a8:	8b 30                	mov    (%eax),%esi
f01035aa:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01035af:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01035b4:	eb 13                	jmp    f01035c9 <vprintfmt+0x35c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01035b6:	89 ca                	mov    %ecx,%edx
f01035b8:	8d 45 14             	lea    0x14(%ebp),%eax
f01035bb:	e8 2e fc ff ff       	call   f01031ee <getuint>
f01035c0:	89 c6                	mov    %eax,%esi
f01035c2:	89 d7                	mov    %edx,%edi
			base = 16;
f01035c4:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01035c9:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f01035cd:	89 54 24 10          	mov    %edx,0x10(%esp)
f01035d1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01035d4:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01035d8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01035dc:	89 34 24             	mov    %esi,(%esp)
f01035df:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01035e3:	89 da                	mov    %ebx,%edx
f01035e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01035e8:	e8 33 fb ff ff       	call   f0103120 <printnum>
			break;
f01035ed:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01035f0:	e9 9b fc ff ff       	jmp    f0103290 <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01035f5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01035f9:	89 04 24             	mov    %eax,(%esp)
f01035fc:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035ff:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103602:	e9 89 fc ff ff       	jmp    f0103290 <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103607:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010360b:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103612:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103615:	eb 03                	jmp    f010361a <vprintfmt+0x3ad>
f0103617:	83 ee 01             	sub    $0x1,%esi
f010361a:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f010361e:	75 f7                	jne    f0103617 <vprintfmt+0x3aa>
f0103620:	e9 6b fc ff ff       	jmp    f0103290 <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f0103625:	83 c4 4c             	add    $0x4c,%esp
f0103628:	5b                   	pop    %ebx
f0103629:	5e                   	pop    %esi
f010362a:	5f                   	pop    %edi
f010362b:	5d                   	pop    %ebp
f010362c:	c3                   	ret    

f010362d <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010362d:	55                   	push   %ebp
f010362e:	89 e5                	mov    %esp,%ebp
f0103630:	83 ec 28             	sub    $0x28,%esp
f0103633:	8b 45 08             	mov    0x8(%ebp),%eax
f0103636:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103639:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010363c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103640:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103643:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010364a:	85 c0                	test   %eax,%eax
f010364c:	74 30                	je     f010367e <vsnprintf+0x51>
f010364e:	85 d2                	test   %edx,%edx
f0103650:	7e 2c                	jle    f010367e <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103652:	8b 45 14             	mov    0x14(%ebp),%eax
f0103655:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103659:	8b 45 10             	mov    0x10(%ebp),%eax
f010365c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103660:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103663:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103667:	c7 04 24 28 32 10 f0 	movl   $0xf0103228,(%esp)
f010366e:	e8 fa fb ff ff       	call   f010326d <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103673:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103676:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103679:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010367c:	eb 05                	jmp    f0103683 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010367e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103683:	c9                   	leave  
f0103684:	c3                   	ret    

f0103685 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103685:	55                   	push   %ebp
f0103686:	89 e5                	mov    %esp,%ebp
f0103688:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010368b:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010368e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103692:	8b 45 10             	mov    0x10(%ebp),%eax
f0103695:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103699:	8b 45 0c             	mov    0xc(%ebp),%eax
f010369c:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01036a3:	89 04 24             	mov    %eax,(%esp)
f01036a6:	e8 82 ff ff ff       	call   f010362d <vsnprintf>
	va_end(ap);

	return rc;
}
f01036ab:	c9                   	leave  
f01036ac:	c3                   	ret    
f01036ad:	00 00                	add    %al,(%eax)
	...

f01036b0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01036b0:	55                   	push   %ebp
f01036b1:	89 e5                	mov    %esp,%ebp
f01036b3:	57                   	push   %edi
f01036b4:	56                   	push   %esi
f01036b5:	53                   	push   %ebx
f01036b6:	83 ec 1c             	sub    $0x1c,%esp
f01036b9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01036bc:	85 c0                	test   %eax,%eax
f01036be:	74 10                	je     f01036d0 <readline+0x20>
		cprintf("%s", prompt);
f01036c0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036c4:	c7 04 24 e4 4a 10 f0 	movl   $0xf0104ae4,(%esp)
f01036cb:	e8 0e f7 ff ff       	call   f0102dde <cprintf>

	i = 0;
	echoing = iscons(0);
f01036d0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01036d7:	e8 31 cf ff ff       	call   f010060d <iscons>
f01036dc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01036de:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01036e3:	e8 14 cf ff ff       	call   f01005fc <getchar>
f01036e8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01036ea:	85 c0                	test   %eax,%eax
f01036ec:	79 17                	jns    f0103705 <readline+0x55>
			cprintf("read error: %e\n", c);
f01036ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036f2:	c7 04 24 c8 4f 10 f0 	movl   $0xf0104fc8,(%esp)
f01036f9:	e8 e0 f6 ff ff       	call   f0102dde <cprintf>
			return NULL;
f01036fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0103703:	eb 6d                	jmp    f0103772 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103705:	83 f8 08             	cmp    $0x8,%eax
f0103708:	74 05                	je     f010370f <readline+0x5f>
f010370a:	83 f8 7f             	cmp    $0x7f,%eax
f010370d:	75 19                	jne    f0103728 <readline+0x78>
f010370f:	85 f6                	test   %esi,%esi
f0103711:	7e 15                	jle    f0103728 <readline+0x78>
			if (echoing)
f0103713:	85 ff                	test   %edi,%edi
f0103715:	74 0c                	je     f0103723 <readline+0x73>
				cputchar('\b');
f0103717:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010371e:	e8 c9 ce ff ff       	call   f01005ec <cputchar>
			i--;
f0103723:	83 ee 01             	sub    $0x1,%esi
f0103726:	eb bb                	jmp    f01036e3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103728:	83 fb 1f             	cmp    $0x1f,%ebx
f010372b:	7e 1f                	jle    f010374c <readline+0x9c>
f010372d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103733:	7f 17                	jg     f010374c <readline+0x9c>
			if (echoing)
f0103735:	85 ff                	test   %edi,%edi
f0103737:	74 08                	je     f0103741 <readline+0x91>
				cputchar(c);
f0103739:	89 1c 24             	mov    %ebx,(%esp)
f010373c:	e8 ab ce ff ff       	call   f01005ec <cputchar>
			buf[i++] = c;
f0103741:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f0103747:	83 c6 01             	add    $0x1,%esi
f010374a:	eb 97                	jmp    f01036e3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010374c:	83 fb 0a             	cmp    $0xa,%ebx
f010374f:	74 05                	je     f0103756 <readline+0xa6>
f0103751:	83 fb 0d             	cmp    $0xd,%ebx
f0103754:	75 8d                	jne    f01036e3 <readline+0x33>
			if (echoing)
f0103756:	85 ff                	test   %edi,%edi
f0103758:	74 0c                	je     f0103766 <readline+0xb6>
				cputchar('\n');
f010375a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103761:	e8 86 ce ff ff       	call   f01005ec <cputchar>
			buf[i] = 0;
f0103766:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f010376d:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f0103772:	83 c4 1c             	add    $0x1c,%esp
f0103775:	5b                   	pop    %ebx
f0103776:	5e                   	pop    %esi
f0103777:	5f                   	pop    %edi
f0103778:	5d                   	pop    %ebp
f0103779:	c3                   	ret    
f010377a:	00 00                	add    %al,(%eax)
f010377c:	00 00                	add    %al,(%eax)
	...

f0103780 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103780:	55                   	push   %ebp
f0103781:	89 e5                	mov    %esp,%ebp
f0103783:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103786:	b8 00 00 00 00       	mov    $0x0,%eax
f010378b:	eb 03                	jmp    f0103790 <strlen+0x10>
		n++;
f010378d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103790:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103794:	75 f7                	jne    f010378d <strlen+0xd>
		n++;
	return n;
}
f0103796:	5d                   	pop    %ebp
f0103797:	c3                   	ret    

f0103798 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103798:	55                   	push   %ebp
f0103799:	89 e5                	mov    %esp,%ebp
f010379b:	8b 4d 08             	mov    0x8(%ebp),%ecx
		n++;
	return n;
}

int
strnlen(const char *s, size_t size)
f010379e:	8b 55 0c             	mov    0xc(%ebp),%edx
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01037a1:	b8 00 00 00 00       	mov    $0x0,%eax
f01037a6:	eb 03                	jmp    f01037ab <strnlen+0x13>
		n++;
f01037a8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01037ab:	39 d0                	cmp    %edx,%eax
f01037ad:	74 06                	je     f01037b5 <strnlen+0x1d>
f01037af:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01037b3:	75 f3                	jne    f01037a8 <strnlen+0x10>
		n++;
	return n;
}
f01037b5:	5d                   	pop    %ebp
f01037b6:	c3                   	ret    

f01037b7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01037b7:	55                   	push   %ebp
f01037b8:	89 e5                	mov    %esp,%ebp
f01037ba:	53                   	push   %ebx
f01037bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01037be:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01037c1:	ba 00 00 00 00       	mov    $0x0,%edx
f01037c6:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01037ca:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01037cd:	83 c2 01             	add    $0x1,%edx
f01037d0:	84 c9                	test   %cl,%cl
f01037d2:	75 f2                	jne    f01037c6 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01037d4:	5b                   	pop    %ebx
f01037d5:	5d                   	pop    %ebp
f01037d6:	c3                   	ret    

f01037d7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01037d7:	55                   	push   %ebp
f01037d8:	89 e5                	mov    %esp,%ebp
f01037da:	53                   	push   %ebx
f01037db:	83 ec 08             	sub    $0x8,%esp
f01037de:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01037e1:	89 1c 24             	mov    %ebx,(%esp)
f01037e4:	e8 97 ff ff ff       	call   f0103780 <strlen>
	strcpy(dst + len, src);
f01037e9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01037ec:	89 54 24 04          	mov    %edx,0x4(%esp)
f01037f0:	01 d8                	add    %ebx,%eax
f01037f2:	89 04 24             	mov    %eax,(%esp)
f01037f5:	e8 bd ff ff ff       	call   f01037b7 <strcpy>
	return dst;
}
f01037fa:	89 d8                	mov    %ebx,%eax
f01037fc:	83 c4 08             	add    $0x8,%esp
f01037ff:	5b                   	pop    %ebx
f0103800:	5d                   	pop    %ebp
f0103801:	c3                   	ret    

f0103802 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103802:	55                   	push   %ebp
f0103803:	89 e5                	mov    %esp,%ebp
f0103805:	56                   	push   %esi
f0103806:	53                   	push   %ebx
f0103807:	8b 45 08             	mov    0x8(%ebp),%eax
f010380a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010380d:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103810:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103815:	eb 0f                	jmp    f0103826 <strncpy+0x24>
		*dst++ = *src;
f0103817:	0f b6 1a             	movzbl (%edx),%ebx
f010381a:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010381d:	80 3a 01             	cmpb   $0x1,(%edx)
f0103820:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103823:	83 c1 01             	add    $0x1,%ecx
f0103826:	39 f1                	cmp    %esi,%ecx
f0103828:	75 ed                	jne    f0103817 <strncpy+0x15>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010382a:	5b                   	pop    %ebx
f010382b:	5e                   	pop    %esi
f010382c:	5d                   	pop    %ebp
f010382d:	c3                   	ret    

f010382e <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010382e:	55                   	push   %ebp
f010382f:	89 e5                	mov    %esp,%ebp
f0103831:	56                   	push   %esi
f0103832:	53                   	push   %ebx
f0103833:	8b 75 08             	mov    0x8(%ebp),%esi
f0103836:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103839:	8b 55 10             	mov    0x10(%ebp),%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010383c:	89 f0                	mov    %esi,%eax
f010383e:	85 d2                	test   %edx,%edx
f0103840:	75 0a                	jne    f010384c <strlcpy+0x1e>
f0103842:	eb 1d                	jmp    f0103861 <strlcpy+0x33>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103844:	88 18                	mov    %bl,(%eax)
f0103846:	83 c0 01             	add    $0x1,%eax
f0103849:	83 c1 01             	add    $0x1,%ecx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010384c:	83 ea 01             	sub    $0x1,%edx
f010384f:	74 0b                	je     f010385c <strlcpy+0x2e>
f0103851:	0f b6 19             	movzbl (%ecx),%ebx
f0103854:	84 db                	test   %bl,%bl
f0103856:	75 ec                	jne    f0103844 <strlcpy+0x16>
f0103858:	89 c2                	mov    %eax,%edx
f010385a:	eb 02                	jmp    f010385e <strlcpy+0x30>
f010385c:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f010385e:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0103861:	29 f0                	sub    %esi,%eax
}
f0103863:	5b                   	pop    %ebx
f0103864:	5e                   	pop    %esi
f0103865:	5d                   	pop    %ebp
f0103866:	c3                   	ret    

f0103867 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103867:	55                   	push   %ebp
f0103868:	89 e5                	mov    %esp,%ebp
f010386a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010386d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103870:	eb 06                	jmp    f0103878 <strcmp+0x11>
		p++, q++;
f0103872:	83 c1 01             	add    $0x1,%ecx
f0103875:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103878:	0f b6 01             	movzbl (%ecx),%eax
f010387b:	84 c0                	test   %al,%al
f010387d:	74 04                	je     f0103883 <strcmp+0x1c>
f010387f:	3a 02                	cmp    (%edx),%al
f0103881:	74 ef                	je     f0103872 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103883:	0f b6 c0             	movzbl %al,%eax
f0103886:	0f b6 12             	movzbl (%edx),%edx
f0103889:	29 d0                	sub    %edx,%eax
}
f010388b:	5d                   	pop    %ebp
f010388c:	c3                   	ret    

f010388d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010388d:	55                   	push   %ebp
f010388e:	89 e5                	mov    %esp,%ebp
f0103890:	53                   	push   %ebx
f0103891:	8b 45 08             	mov    0x8(%ebp),%eax
f0103894:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103897:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
f010389a:	eb 09                	jmp    f01038a5 <strncmp+0x18>
		n--, p++, q++;
f010389c:	83 ea 01             	sub    $0x1,%edx
f010389f:	83 c0 01             	add    $0x1,%eax
f01038a2:	83 c1 01             	add    $0x1,%ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01038a5:	85 d2                	test   %edx,%edx
f01038a7:	74 15                	je     f01038be <strncmp+0x31>
f01038a9:	0f b6 18             	movzbl (%eax),%ebx
f01038ac:	84 db                	test   %bl,%bl
f01038ae:	74 04                	je     f01038b4 <strncmp+0x27>
f01038b0:	3a 19                	cmp    (%ecx),%bl
f01038b2:	74 e8                	je     f010389c <strncmp+0xf>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01038b4:	0f b6 00             	movzbl (%eax),%eax
f01038b7:	0f b6 11             	movzbl (%ecx),%edx
f01038ba:	29 d0                	sub    %edx,%eax
f01038bc:	eb 05                	jmp    f01038c3 <strncmp+0x36>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01038be:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01038c3:	5b                   	pop    %ebx
f01038c4:	5d                   	pop    %ebp
f01038c5:	c3                   	ret    

f01038c6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01038c6:	55                   	push   %ebp
f01038c7:	89 e5                	mov    %esp,%ebp
f01038c9:	8b 45 08             	mov    0x8(%ebp),%eax
f01038cc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01038d0:	eb 07                	jmp    f01038d9 <strchr+0x13>
		if (*s == c)
f01038d2:	38 ca                	cmp    %cl,%dl
f01038d4:	74 0f                	je     f01038e5 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01038d6:	83 c0 01             	add    $0x1,%eax
f01038d9:	0f b6 10             	movzbl (%eax),%edx
f01038dc:	84 d2                	test   %dl,%dl
f01038de:	75 f2                	jne    f01038d2 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01038e0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01038e5:	5d                   	pop    %ebp
f01038e6:	c3                   	ret    

f01038e7 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01038e7:	55                   	push   %ebp
f01038e8:	89 e5                	mov    %esp,%ebp
f01038ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01038ed:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01038f1:	eb 07                	jmp    f01038fa <strfind+0x13>
		if (*s == c)
f01038f3:	38 ca                	cmp    %cl,%dl
f01038f5:	74 0a                	je     f0103901 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01038f7:	83 c0 01             	add    $0x1,%eax
f01038fa:	0f b6 10             	movzbl (%eax),%edx
f01038fd:	84 d2                	test   %dl,%dl
f01038ff:	75 f2                	jne    f01038f3 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0103901:	5d                   	pop    %ebp
f0103902:	c3                   	ret    

f0103903 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103903:	55                   	push   %ebp
f0103904:	89 e5                	mov    %esp,%ebp
f0103906:	83 ec 0c             	sub    $0xc,%esp
f0103909:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010390c:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010390f:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103912:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103915:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103918:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010391b:	85 c9                	test   %ecx,%ecx
f010391d:	74 30                	je     f010394f <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010391f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103925:	75 25                	jne    f010394c <memset+0x49>
f0103927:	f6 c1 03             	test   $0x3,%cl
f010392a:	75 20                	jne    f010394c <memset+0x49>
		c &= 0xFF;
f010392c:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010392f:	89 d3                	mov    %edx,%ebx
f0103931:	c1 e3 08             	shl    $0x8,%ebx
f0103934:	89 d6                	mov    %edx,%esi
f0103936:	c1 e6 18             	shl    $0x18,%esi
f0103939:	89 d0                	mov    %edx,%eax
f010393b:	c1 e0 10             	shl    $0x10,%eax
f010393e:	09 f0                	or     %esi,%eax
f0103940:	09 d0                	or     %edx,%eax
f0103942:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103944:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0103947:	fc                   	cld    
f0103948:	f3 ab                	rep stos %eax,%es:(%edi)
f010394a:	eb 03                	jmp    f010394f <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010394c:	fc                   	cld    
f010394d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010394f:	89 f8                	mov    %edi,%eax
f0103951:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103954:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103957:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010395a:	89 ec                	mov    %ebp,%esp
f010395c:	5d                   	pop    %ebp
f010395d:	c3                   	ret    

f010395e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010395e:	55                   	push   %ebp
f010395f:	89 e5                	mov    %esp,%ebp
f0103961:	83 ec 08             	sub    $0x8,%esp
f0103964:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103967:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010396a:	8b 45 08             	mov    0x8(%ebp),%eax
f010396d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103970:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103973:	39 c6                	cmp    %eax,%esi
f0103975:	73 36                	jae    f01039ad <memmove+0x4f>
f0103977:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010397a:	39 d0                	cmp    %edx,%eax
f010397c:	73 2f                	jae    f01039ad <memmove+0x4f>
		s += n;
		d += n;
f010397e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103981:	f6 c2 03             	test   $0x3,%dl
f0103984:	75 1b                	jne    f01039a1 <memmove+0x43>
f0103986:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010398c:	75 13                	jne    f01039a1 <memmove+0x43>
f010398e:	f6 c1 03             	test   $0x3,%cl
f0103991:	75 0e                	jne    f01039a1 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103993:	83 ef 04             	sub    $0x4,%edi
f0103996:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103999:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010399c:	fd                   	std    
f010399d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010399f:	eb 09                	jmp    f01039aa <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01039a1:	83 ef 01             	sub    $0x1,%edi
f01039a4:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01039a7:	fd                   	std    
f01039a8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01039aa:	fc                   	cld    
f01039ab:	eb 20                	jmp    f01039cd <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01039ad:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01039b3:	75 13                	jne    f01039c8 <memmove+0x6a>
f01039b5:	a8 03                	test   $0x3,%al
f01039b7:	75 0f                	jne    f01039c8 <memmove+0x6a>
f01039b9:	f6 c1 03             	test   $0x3,%cl
f01039bc:	75 0a                	jne    f01039c8 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01039be:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01039c1:	89 c7                	mov    %eax,%edi
f01039c3:	fc                   	cld    
f01039c4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01039c6:	eb 05                	jmp    f01039cd <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01039c8:	89 c7                	mov    %eax,%edi
f01039ca:	fc                   	cld    
f01039cb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01039cd:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01039d0:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01039d3:	89 ec                	mov    %ebp,%esp
f01039d5:	5d                   	pop    %ebp
f01039d6:	c3                   	ret    

f01039d7 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01039d7:	55                   	push   %ebp
f01039d8:	89 e5                	mov    %esp,%ebp
f01039da:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01039dd:	8b 45 10             	mov    0x10(%ebp),%eax
f01039e0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01039e4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01039e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01039ee:	89 04 24             	mov    %eax,(%esp)
f01039f1:	e8 68 ff ff ff       	call   f010395e <memmove>
}
f01039f6:	c9                   	leave  
f01039f7:	c3                   	ret    

f01039f8 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01039f8:	55                   	push   %ebp
f01039f9:	89 e5                	mov    %esp,%ebp
f01039fb:	57                   	push   %edi
f01039fc:	56                   	push   %esi
f01039fd:	53                   	push   %ebx
f01039fe:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103a01:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103a04:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103a07:	ba 00 00 00 00       	mov    $0x0,%edx
f0103a0c:	eb 1a                	jmp    f0103a28 <memcmp+0x30>
		if (*s1 != *s2)
f0103a0e:	0f b6 04 17          	movzbl (%edi,%edx,1),%eax
f0103a12:	83 c2 01             	add    $0x1,%edx
f0103a15:	0f b6 4c 16 ff       	movzbl -0x1(%esi,%edx,1),%ecx
f0103a1a:	38 c8                	cmp    %cl,%al
f0103a1c:	74 0a                	je     f0103a28 <memcmp+0x30>
			return (int) *s1 - (int) *s2;
f0103a1e:	0f b6 c0             	movzbl %al,%eax
f0103a21:	0f b6 c9             	movzbl %cl,%ecx
f0103a24:	29 c8                	sub    %ecx,%eax
f0103a26:	eb 09                	jmp    f0103a31 <memcmp+0x39>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103a28:	39 da                	cmp    %ebx,%edx
f0103a2a:	75 e2                	jne    f0103a0e <memcmp+0x16>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103a2c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103a31:	5b                   	pop    %ebx
f0103a32:	5e                   	pop    %esi
f0103a33:	5f                   	pop    %edi
f0103a34:	5d                   	pop    %ebp
f0103a35:	c3                   	ret    

f0103a36 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103a36:	55                   	push   %ebp
f0103a37:	89 e5                	mov    %esp,%ebp
f0103a39:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a3c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103a3f:	89 c2                	mov    %eax,%edx
f0103a41:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103a44:	eb 07                	jmp    f0103a4d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103a46:	38 08                	cmp    %cl,(%eax)
f0103a48:	74 07                	je     f0103a51 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103a4a:	83 c0 01             	add    $0x1,%eax
f0103a4d:	39 d0                	cmp    %edx,%eax
f0103a4f:	72 f5                	jb     f0103a46 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103a51:	5d                   	pop    %ebp
f0103a52:	c3                   	ret    

f0103a53 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103a53:	55                   	push   %ebp
f0103a54:	89 e5                	mov    %esp,%ebp
f0103a56:	57                   	push   %edi
f0103a57:	56                   	push   %esi
f0103a58:	53                   	push   %ebx
f0103a59:	8b 55 08             	mov    0x8(%ebp),%edx
f0103a5c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103a5f:	eb 03                	jmp    f0103a64 <strtol+0x11>
		s++;
f0103a61:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103a64:	0f b6 02             	movzbl (%edx),%eax
f0103a67:	3c 20                	cmp    $0x20,%al
f0103a69:	74 f6                	je     f0103a61 <strtol+0xe>
f0103a6b:	3c 09                	cmp    $0x9,%al
f0103a6d:	74 f2                	je     f0103a61 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103a6f:	3c 2b                	cmp    $0x2b,%al
f0103a71:	75 0a                	jne    f0103a7d <strtol+0x2a>
		s++;
f0103a73:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103a76:	bf 00 00 00 00       	mov    $0x0,%edi
f0103a7b:	eb 10                	jmp    f0103a8d <strtol+0x3a>
f0103a7d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103a82:	3c 2d                	cmp    $0x2d,%al
f0103a84:	75 07                	jne    f0103a8d <strtol+0x3a>
		s++, neg = 1;
f0103a86:	8d 52 01             	lea    0x1(%edx),%edx
f0103a89:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103a8d:	85 db                	test   %ebx,%ebx
f0103a8f:	0f 94 c0             	sete   %al
f0103a92:	74 05                	je     f0103a99 <strtol+0x46>
f0103a94:	83 fb 10             	cmp    $0x10,%ebx
f0103a97:	75 15                	jne    f0103aae <strtol+0x5b>
f0103a99:	80 3a 30             	cmpb   $0x30,(%edx)
f0103a9c:	75 10                	jne    f0103aae <strtol+0x5b>
f0103a9e:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103aa2:	75 0a                	jne    f0103aae <strtol+0x5b>
		s += 2, base = 16;
f0103aa4:	83 c2 02             	add    $0x2,%edx
f0103aa7:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103aac:	eb 13                	jmp    f0103ac1 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103aae:	84 c0                	test   %al,%al
f0103ab0:	74 0f                	je     f0103ac1 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103ab2:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103ab7:	80 3a 30             	cmpb   $0x30,(%edx)
f0103aba:	75 05                	jne    f0103ac1 <strtol+0x6e>
		s++, base = 8;
f0103abc:	83 c2 01             	add    $0x1,%edx
f0103abf:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0103ac1:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ac6:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103ac8:	0f b6 0a             	movzbl (%edx),%ecx
f0103acb:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0103ace:	80 fb 09             	cmp    $0x9,%bl
f0103ad1:	77 08                	ja     f0103adb <strtol+0x88>
			dig = *s - '0';
f0103ad3:	0f be c9             	movsbl %cl,%ecx
f0103ad6:	83 e9 30             	sub    $0x30,%ecx
f0103ad9:	eb 1e                	jmp    f0103af9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0103adb:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0103ade:	80 fb 19             	cmp    $0x19,%bl
f0103ae1:	77 08                	ja     f0103aeb <strtol+0x98>
			dig = *s - 'a' + 10;
f0103ae3:	0f be c9             	movsbl %cl,%ecx
f0103ae6:	83 e9 57             	sub    $0x57,%ecx
f0103ae9:	eb 0e                	jmp    f0103af9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0103aeb:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0103aee:	80 fb 19             	cmp    $0x19,%bl
f0103af1:	77 14                	ja     f0103b07 <strtol+0xb4>
			dig = *s - 'A' + 10;
f0103af3:	0f be c9             	movsbl %cl,%ecx
f0103af6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103af9:	39 f1                	cmp    %esi,%ecx
f0103afb:	7d 0e                	jge    f0103b0b <strtol+0xb8>
			break;
		s++, val = (val * base) + dig;
f0103afd:	83 c2 01             	add    $0x1,%edx
f0103b00:	0f af c6             	imul   %esi,%eax
f0103b03:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0103b05:	eb c1                	jmp    f0103ac8 <strtol+0x75>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0103b07:	89 c1                	mov    %eax,%ecx
f0103b09:	eb 02                	jmp    f0103b0d <strtol+0xba>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103b0b:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0103b0d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103b11:	74 05                	je     f0103b18 <strtol+0xc5>
		*endptr = (char *) s;
f0103b13:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103b16:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0103b18:	89 ca                	mov    %ecx,%edx
f0103b1a:	f7 da                	neg    %edx
f0103b1c:	85 ff                	test   %edi,%edi
f0103b1e:	0f 45 c2             	cmovne %edx,%eax
}
f0103b21:	5b                   	pop    %ebx
f0103b22:	5e                   	pop    %esi
f0103b23:	5f                   	pop    %edi
f0103b24:	5d                   	pop    %ebp
f0103b25:	c3                   	ret    
	...

f0103b30 <__udivdi3>:
f0103b30:	83 ec 1c             	sub    $0x1c,%esp
f0103b33:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103b37:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0103b3b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103b3f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103b43:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103b47:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103b4b:	85 ff                	test   %edi,%edi
f0103b4d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103b51:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103b55:	89 cd                	mov    %ecx,%ebp
f0103b57:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b5b:	75 33                	jne    f0103b90 <__udivdi3+0x60>
f0103b5d:	39 f1                	cmp    %esi,%ecx
f0103b5f:	77 57                	ja     f0103bb8 <__udivdi3+0x88>
f0103b61:	85 c9                	test   %ecx,%ecx
f0103b63:	75 0b                	jne    f0103b70 <__udivdi3+0x40>
f0103b65:	b8 01 00 00 00       	mov    $0x1,%eax
f0103b6a:	31 d2                	xor    %edx,%edx
f0103b6c:	f7 f1                	div    %ecx
f0103b6e:	89 c1                	mov    %eax,%ecx
f0103b70:	89 f0                	mov    %esi,%eax
f0103b72:	31 d2                	xor    %edx,%edx
f0103b74:	f7 f1                	div    %ecx
f0103b76:	89 c6                	mov    %eax,%esi
f0103b78:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103b7c:	f7 f1                	div    %ecx
f0103b7e:	89 f2                	mov    %esi,%edx
f0103b80:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103b84:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103b88:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103b8c:	83 c4 1c             	add    $0x1c,%esp
f0103b8f:	c3                   	ret    
f0103b90:	31 d2                	xor    %edx,%edx
f0103b92:	31 c0                	xor    %eax,%eax
f0103b94:	39 f7                	cmp    %esi,%edi
f0103b96:	77 e8                	ja     f0103b80 <__udivdi3+0x50>
f0103b98:	0f bd cf             	bsr    %edi,%ecx
f0103b9b:	83 f1 1f             	xor    $0x1f,%ecx
f0103b9e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103ba2:	75 2c                	jne    f0103bd0 <__udivdi3+0xa0>
f0103ba4:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0103ba8:	76 04                	jbe    f0103bae <__udivdi3+0x7e>
f0103baa:	39 f7                	cmp    %esi,%edi
f0103bac:	73 d2                	jae    f0103b80 <__udivdi3+0x50>
f0103bae:	31 d2                	xor    %edx,%edx
f0103bb0:	b8 01 00 00 00       	mov    $0x1,%eax
f0103bb5:	eb c9                	jmp    f0103b80 <__udivdi3+0x50>
f0103bb7:	90                   	nop
f0103bb8:	89 f2                	mov    %esi,%edx
f0103bba:	f7 f1                	div    %ecx
f0103bbc:	31 d2                	xor    %edx,%edx
f0103bbe:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103bc2:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103bc6:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103bca:	83 c4 1c             	add    $0x1c,%esp
f0103bcd:	c3                   	ret    
f0103bce:	66 90                	xchg   %ax,%ax
f0103bd0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103bd5:	b8 20 00 00 00       	mov    $0x20,%eax
f0103bda:	89 ea                	mov    %ebp,%edx
f0103bdc:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103be0:	d3 e7                	shl    %cl,%edi
f0103be2:	89 c1                	mov    %eax,%ecx
f0103be4:	d3 ea                	shr    %cl,%edx
f0103be6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103beb:	09 fa                	or     %edi,%edx
f0103bed:	89 f7                	mov    %esi,%edi
f0103bef:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103bf3:	89 f2                	mov    %esi,%edx
f0103bf5:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103bf9:	d3 e5                	shl    %cl,%ebp
f0103bfb:	89 c1                	mov    %eax,%ecx
f0103bfd:	d3 ef                	shr    %cl,%edi
f0103bff:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c04:	d3 e2                	shl    %cl,%edx
f0103c06:	89 c1                	mov    %eax,%ecx
f0103c08:	d3 ee                	shr    %cl,%esi
f0103c0a:	09 d6                	or     %edx,%esi
f0103c0c:	89 fa                	mov    %edi,%edx
f0103c0e:	89 f0                	mov    %esi,%eax
f0103c10:	f7 74 24 0c          	divl   0xc(%esp)
f0103c14:	89 d7                	mov    %edx,%edi
f0103c16:	89 c6                	mov    %eax,%esi
f0103c18:	f7 e5                	mul    %ebp
f0103c1a:	39 d7                	cmp    %edx,%edi
f0103c1c:	72 22                	jb     f0103c40 <__udivdi3+0x110>
f0103c1e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0103c22:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c27:	d3 e5                	shl    %cl,%ebp
f0103c29:	39 c5                	cmp    %eax,%ebp
f0103c2b:	73 04                	jae    f0103c31 <__udivdi3+0x101>
f0103c2d:	39 d7                	cmp    %edx,%edi
f0103c2f:	74 0f                	je     f0103c40 <__udivdi3+0x110>
f0103c31:	89 f0                	mov    %esi,%eax
f0103c33:	31 d2                	xor    %edx,%edx
f0103c35:	e9 46 ff ff ff       	jmp    f0103b80 <__udivdi3+0x50>
f0103c3a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103c40:	8d 46 ff             	lea    -0x1(%esi),%eax
f0103c43:	31 d2                	xor    %edx,%edx
f0103c45:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103c49:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103c4d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103c51:	83 c4 1c             	add    $0x1c,%esp
f0103c54:	c3                   	ret    
	...

f0103c60 <__umoddi3>:
f0103c60:	83 ec 1c             	sub    $0x1c,%esp
f0103c63:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103c67:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0103c6b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103c6f:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103c73:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103c77:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103c7b:	85 ed                	test   %ebp,%ebp
f0103c7d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103c81:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103c85:	89 cf                	mov    %ecx,%edi
f0103c87:	89 04 24             	mov    %eax,(%esp)
f0103c8a:	89 f2                	mov    %esi,%edx
f0103c8c:	75 1a                	jne    f0103ca8 <__umoddi3+0x48>
f0103c8e:	39 f1                	cmp    %esi,%ecx
f0103c90:	76 4e                	jbe    f0103ce0 <__umoddi3+0x80>
f0103c92:	f7 f1                	div    %ecx
f0103c94:	89 d0                	mov    %edx,%eax
f0103c96:	31 d2                	xor    %edx,%edx
f0103c98:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103c9c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103ca0:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103ca4:	83 c4 1c             	add    $0x1c,%esp
f0103ca7:	c3                   	ret    
f0103ca8:	39 f5                	cmp    %esi,%ebp
f0103caa:	77 54                	ja     f0103d00 <__umoddi3+0xa0>
f0103cac:	0f bd c5             	bsr    %ebp,%eax
f0103caf:	83 f0 1f             	xor    $0x1f,%eax
f0103cb2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cb6:	75 60                	jne    f0103d18 <__umoddi3+0xb8>
f0103cb8:	3b 0c 24             	cmp    (%esp),%ecx
f0103cbb:	0f 87 07 01 00 00    	ja     f0103dc8 <__umoddi3+0x168>
f0103cc1:	89 f2                	mov    %esi,%edx
f0103cc3:	8b 34 24             	mov    (%esp),%esi
f0103cc6:	29 ce                	sub    %ecx,%esi
f0103cc8:	19 ea                	sbb    %ebp,%edx
f0103cca:	89 34 24             	mov    %esi,(%esp)
f0103ccd:	8b 04 24             	mov    (%esp),%eax
f0103cd0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103cd4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103cd8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103cdc:	83 c4 1c             	add    $0x1c,%esp
f0103cdf:	c3                   	ret    
f0103ce0:	85 c9                	test   %ecx,%ecx
f0103ce2:	75 0b                	jne    f0103cef <__umoddi3+0x8f>
f0103ce4:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ce9:	31 d2                	xor    %edx,%edx
f0103ceb:	f7 f1                	div    %ecx
f0103ced:	89 c1                	mov    %eax,%ecx
f0103cef:	89 f0                	mov    %esi,%eax
f0103cf1:	31 d2                	xor    %edx,%edx
f0103cf3:	f7 f1                	div    %ecx
f0103cf5:	8b 04 24             	mov    (%esp),%eax
f0103cf8:	f7 f1                	div    %ecx
f0103cfa:	eb 98                	jmp    f0103c94 <__umoddi3+0x34>
f0103cfc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d00:	89 f2                	mov    %esi,%edx
f0103d02:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103d06:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103d0a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103d0e:	83 c4 1c             	add    $0x1c,%esp
f0103d11:	c3                   	ret    
f0103d12:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103d18:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103d1d:	89 e8                	mov    %ebp,%eax
f0103d1f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0103d24:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0103d28:	89 fa                	mov    %edi,%edx
f0103d2a:	d3 e0                	shl    %cl,%eax
f0103d2c:	89 e9                	mov    %ebp,%ecx
f0103d2e:	d3 ea                	shr    %cl,%edx
f0103d30:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103d35:	09 c2                	or     %eax,%edx
f0103d37:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103d3b:	89 14 24             	mov    %edx,(%esp)
f0103d3e:	89 f2                	mov    %esi,%edx
f0103d40:	d3 e7                	shl    %cl,%edi
f0103d42:	89 e9                	mov    %ebp,%ecx
f0103d44:	d3 ea                	shr    %cl,%edx
f0103d46:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103d4b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103d4f:	d3 e6                	shl    %cl,%esi
f0103d51:	89 e9                	mov    %ebp,%ecx
f0103d53:	d3 e8                	shr    %cl,%eax
f0103d55:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103d5a:	09 f0                	or     %esi,%eax
f0103d5c:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103d60:	f7 34 24             	divl   (%esp)
f0103d63:	d3 e6                	shl    %cl,%esi
f0103d65:	89 74 24 08          	mov    %esi,0x8(%esp)
f0103d69:	89 d6                	mov    %edx,%esi
f0103d6b:	f7 e7                	mul    %edi
f0103d6d:	39 d6                	cmp    %edx,%esi
f0103d6f:	89 c1                	mov    %eax,%ecx
f0103d71:	89 d7                	mov    %edx,%edi
f0103d73:	72 3f                	jb     f0103db4 <__umoddi3+0x154>
f0103d75:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0103d79:	72 35                	jb     f0103db0 <__umoddi3+0x150>
f0103d7b:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103d7f:	29 c8                	sub    %ecx,%eax
f0103d81:	19 fe                	sbb    %edi,%esi
f0103d83:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103d88:	89 f2                	mov    %esi,%edx
f0103d8a:	d3 e8                	shr    %cl,%eax
f0103d8c:	89 e9                	mov    %ebp,%ecx
f0103d8e:	d3 e2                	shl    %cl,%edx
f0103d90:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103d95:	09 d0                	or     %edx,%eax
f0103d97:	89 f2                	mov    %esi,%edx
f0103d99:	d3 ea                	shr    %cl,%edx
f0103d9b:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103d9f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103da3:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103da7:	83 c4 1c             	add    $0x1c,%esp
f0103daa:	c3                   	ret    
f0103dab:	90                   	nop
f0103dac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103db0:	39 d6                	cmp    %edx,%esi
f0103db2:	75 c7                	jne    f0103d7b <__umoddi3+0x11b>
f0103db4:	89 d7                	mov    %edx,%edi
f0103db6:	89 c1                	mov    %eax,%ecx
f0103db8:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0103dbc:	1b 3c 24             	sbb    (%esp),%edi
f0103dbf:	eb ba                	jmp    f0103d7b <__umoddi3+0x11b>
f0103dc1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103dc8:	39 f5                	cmp    %esi,%ebp
f0103dca:	0f 82 f1 fe ff ff    	jb     f0103cc1 <__umoddi3+0x61>
f0103dd0:	e9 f8 fe ff ff       	jmp    f0103ccd <__umoddi3+0x6d>
