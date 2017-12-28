
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
f0100015:	b8 00 a0 11 00       	mov    $0x11a000,%eax
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
f0100034:	bc 00 a0 11 f0       	mov    $0xf011a000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


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
f0100046:	b8 30 ec 17 f0       	mov    $0xf017ec30,%eax
f010004b:	2d 2f dd 17 f0       	sub    $0xf017dd2f,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 2f dd 17 f0 	movl   $0xf017dd2f,(%esp)
f0100063:	e8 db 4b 00 00       	call   f0104c43 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 aa 04 00 00       	call   f0100517 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 20 51 10 f0 	movl   $0xf0105120,(%esp)
f010007c:	e8 a5 36 00 00       	call   f0103726 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 4f 11 00 00       	call   f01011d5 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100086:	e8 1f 30 00 00       	call   f01030aa <env_init>
	trap_init();
f010008b:	90                   	nop
f010008c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100090:	e8 11 37 00 00       	call   f01037a6 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100095:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010009c:	00 
f010009d:	c7 04 24 cb 2b 13 f0 	movl   $0xf0132bcb,(%esp)
f01000a4:	e8 fa 31 00 00       	call   f01032a3 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a9:	a1 8c df 17 f0       	mov    0xf017df8c,%eax
f01000ae:	89 04 24             	mov    %eax,(%esp)
f01000b1:	e8 aa 35 00 00       	call   f0103660 <env_run>

f01000b6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000b6:	55                   	push   %ebp
f01000b7:	89 e5                	mov    %esp,%ebp
f01000b9:	56                   	push   %esi
f01000ba:	53                   	push   %ebx
f01000bb:	83 ec 10             	sub    $0x10,%esp
f01000be:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000c1:	83 3d 20 ec 17 f0 00 	cmpl   $0x0,0xf017ec20
f01000c8:	75 3d                	jne    f0100107 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000ca:	89 35 20 ec 17 f0    	mov    %esi,0xf017ec20

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000d0:	fa                   	cli    
f01000d1:	fc                   	cld    

	va_start(ap, fmt);
f01000d2:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000d5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000d8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01000df:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000e3:	c7 04 24 3b 51 10 f0 	movl   $0xf010513b,(%esp)
f01000ea:	e8 37 36 00 00       	call   f0103726 <cprintf>
	vcprintf(fmt, ap);
f01000ef:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000f3:	89 34 24             	mov    %esi,(%esp)
f01000f6:	e8 f8 35 00 00       	call   f01036f3 <vcprintf>
	cprintf("\n");
f01000fb:	c7 04 24 1b 61 10 f0 	movl   $0xf010611b,(%esp)
f0100102:	e8 1f 36 00 00       	call   f0103726 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100107:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010010e:	e8 e2 06 00 00       	call   f01007f5 <monitor>
f0100113:	eb f2                	jmp    f0100107 <_panic+0x51>

f0100115 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100115:	55                   	push   %ebp
f0100116:	89 e5                	mov    %esp,%ebp
f0100118:	53                   	push   %ebx
f0100119:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010011c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010011f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100122:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100126:	8b 45 08             	mov    0x8(%ebp),%eax
f0100129:	89 44 24 04          	mov    %eax,0x4(%esp)
f010012d:	c7 04 24 53 51 10 f0 	movl   $0xf0105153,(%esp)
f0100134:	e8 ed 35 00 00       	call   f0103726 <cprintf>
	vcprintf(fmt, ap);
f0100139:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010013d:	8b 45 10             	mov    0x10(%ebp),%eax
f0100140:	89 04 24             	mov    %eax,(%esp)
f0100143:	e8 ab 35 00 00       	call   f01036f3 <vcprintf>
	cprintf("\n");
f0100148:	c7 04 24 1b 61 10 f0 	movl   $0xf010611b,(%esp)
f010014f:	e8 d2 35 00 00       	call   f0103726 <cprintf>
	va_end(ap);
}
f0100154:	83 c4 14             	add    $0x14,%esp
f0100157:	5b                   	pop    %ebx
f0100158:	5d                   	pop    %ebp
f0100159:	c3                   	ret    
f010015a:	00 00                	add    %al,(%eax)
f010015c:	00 00                	add    %al,(%eax)
	...

f0100160 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100160:	55                   	push   %ebp
f0100161:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100163:	ba 84 00 00 00       	mov    $0x84,%edx
f0100168:	ec                   	in     (%dx),%al
f0100169:	ec                   	in     (%dx),%al
f010016a:	ec                   	in     (%dx),%al
f010016b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010016c:	5d                   	pop    %ebp
f010016d:	c3                   	ret    

f010016e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010016e:	55                   	push   %ebp
f010016f:	89 e5                	mov    %esp,%ebp
f0100171:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100176:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100177:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010017c:	a8 01                	test   $0x1,%al
f010017e:	74 06                	je     f0100186 <serial_proc_data+0x18>
f0100180:	b2 f8                	mov    $0xf8,%dl
f0100182:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100183:	0f b6 c8             	movzbl %al,%ecx
}
f0100186:	89 c8                	mov    %ecx,%eax
f0100188:	5d                   	pop    %ebp
f0100189:	c3                   	ret    

f010018a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010018a:	55                   	push   %ebp
f010018b:	89 e5                	mov    %esp,%ebp
f010018d:	53                   	push   %ebx
f010018e:	83 ec 04             	sub    $0x4,%esp
f0100191:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100193:	eb 25                	jmp    f01001ba <cons_intr+0x30>
		if (c == 0)
f0100195:	85 c0                	test   %eax,%eax
f0100197:	74 21                	je     f01001ba <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f0100199:	8b 15 64 df 17 f0    	mov    0xf017df64,%edx
f010019f:	88 82 60 dd 17 f0    	mov    %al,-0xfe822a0(%edx)
f01001a5:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01001a8:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01001ad:	ba 00 00 00 00       	mov    $0x0,%edx
f01001b2:	0f 44 c2             	cmove  %edx,%eax
f01001b5:	a3 64 df 17 f0       	mov    %eax,0xf017df64
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001ba:	ff d3                	call   *%ebx
f01001bc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001bf:	75 d4                	jne    f0100195 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001c1:	83 c4 04             	add    $0x4,%esp
f01001c4:	5b                   	pop    %ebx
f01001c5:	5d                   	pop    %ebp
f01001c6:	c3                   	ret    

f01001c7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001c7:	55                   	push   %ebp
f01001c8:	89 e5                	mov    %esp,%ebp
f01001ca:	57                   	push   %edi
f01001cb:	56                   	push   %esi
f01001cc:	53                   	push   %ebx
f01001cd:	83 ec 2c             	sub    $0x2c,%esp
f01001d0:	89 c7                	mov    %eax,%edi
f01001d2:	bb 01 32 00 00       	mov    $0x3201,%ebx
f01001d7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01001dc:	eb 05                	jmp    f01001e3 <cons_putc+0x1c>
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001de:	e8 7d ff ff ff       	call   f0100160 <delay>
f01001e3:	89 f2                	mov    %esi,%edx
f01001e5:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01001e6:	a8 20                	test   $0x20,%al
f01001e8:	75 05                	jne    f01001ef <cons_putc+0x28>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001ea:	83 eb 01             	sub    $0x1,%ebx
f01001ed:	75 ef                	jne    f01001de <cons_putc+0x17>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01001ef:	89 fa                	mov    %edi,%edx
f01001f1:	89 f8                	mov    %edi,%eax
f01001f3:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001f6:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001fb:	ee                   	out    %al,(%dx)
f01001fc:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100201:	be 79 03 00 00       	mov    $0x379,%esi
f0100206:	eb 05                	jmp    f010020d <cons_putc+0x46>
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
		delay();
f0100208:	e8 53 ff ff ff       	call   f0100160 <delay>
f010020d:	89 f2                	mov    %esi,%edx
f010020f:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100210:	84 c0                	test   %al,%al
f0100212:	78 05                	js     f0100219 <cons_putc+0x52>
f0100214:	83 eb 01             	sub    $0x1,%ebx
f0100217:	75 ef                	jne    f0100208 <cons_putc+0x41>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100219:	ba 78 03 00 00       	mov    $0x378,%edx
f010021e:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100222:	ee                   	out    %al,(%dx)
f0100223:	b2 7a                	mov    $0x7a,%dl
f0100225:	b8 0d 00 00 00       	mov    $0xd,%eax
f010022a:	ee                   	out    %al,(%dx)
f010022b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100230:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100231:	89 fa                	mov    %edi,%edx
f0100233:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100239:	89 f8                	mov    %edi,%eax
f010023b:	80 cc 07             	or     $0x7,%ah
f010023e:	85 d2                	test   %edx,%edx
f0100240:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100243:	89 f8                	mov    %edi,%eax
f0100245:	25 ff 00 00 00       	and    $0xff,%eax
f010024a:	83 f8 09             	cmp    $0x9,%eax
f010024d:	74 79                	je     f01002c8 <cons_putc+0x101>
f010024f:	83 f8 09             	cmp    $0x9,%eax
f0100252:	7f 0e                	jg     f0100262 <cons_putc+0x9b>
f0100254:	83 f8 08             	cmp    $0x8,%eax
f0100257:	0f 85 9f 00 00 00    	jne    f01002fc <cons_putc+0x135>
f010025d:	8d 76 00             	lea    0x0(%esi),%esi
f0100260:	eb 10                	jmp    f0100272 <cons_putc+0xab>
f0100262:	83 f8 0a             	cmp    $0xa,%eax
f0100265:	74 3b                	je     f01002a2 <cons_putc+0xdb>
f0100267:	83 f8 0d             	cmp    $0xd,%eax
f010026a:	0f 85 8c 00 00 00    	jne    f01002fc <cons_putc+0x135>
f0100270:	eb 38                	jmp    f01002aa <cons_putc+0xe3>
	case '\b':
		if (crt_pos > 0) {
f0100272:	0f b7 05 74 df 17 f0 	movzwl 0xf017df74,%eax
f0100279:	66 85 c0             	test   %ax,%ax
f010027c:	0f 84 e4 00 00 00    	je     f0100366 <cons_putc+0x19f>
			crt_pos--;
f0100282:	83 e8 01             	sub    $0x1,%eax
f0100285:	66 a3 74 df 17 f0    	mov    %ax,0xf017df74
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010028b:	0f b7 c0             	movzwl %ax,%eax
f010028e:	66 81 e7 00 ff       	and    $0xff00,%di
f0100293:	83 cf 20             	or     $0x20,%edi
f0100296:	8b 15 70 df 17 f0    	mov    0xf017df70,%edx
f010029c:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002a0:	eb 77                	jmp    f0100319 <cons_putc+0x152>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002a2:	66 83 05 74 df 17 f0 	addw   $0x50,0xf017df74
f01002a9:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002aa:	0f b7 05 74 df 17 f0 	movzwl 0xf017df74,%eax
f01002b1:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002b7:	c1 e8 16             	shr    $0x16,%eax
f01002ba:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002bd:	c1 e0 04             	shl    $0x4,%eax
f01002c0:	66 a3 74 df 17 f0    	mov    %ax,0xf017df74
f01002c6:	eb 51                	jmp    f0100319 <cons_putc+0x152>
		break;
	case '\t':
		cons_putc(' ');
f01002c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01002cd:	e8 f5 fe ff ff       	call   f01001c7 <cons_putc>
		cons_putc(' ');
f01002d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01002d7:	e8 eb fe ff ff       	call   f01001c7 <cons_putc>
		cons_putc(' ');
f01002dc:	b8 20 00 00 00       	mov    $0x20,%eax
f01002e1:	e8 e1 fe ff ff       	call   f01001c7 <cons_putc>
		cons_putc(' ');
f01002e6:	b8 20 00 00 00       	mov    $0x20,%eax
f01002eb:	e8 d7 fe ff ff       	call   f01001c7 <cons_putc>
		cons_putc(' ');
f01002f0:	b8 20 00 00 00       	mov    $0x20,%eax
f01002f5:	e8 cd fe ff ff       	call   f01001c7 <cons_putc>
f01002fa:	eb 1d                	jmp    f0100319 <cons_putc+0x152>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01002fc:	0f b7 05 74 df 17 f0 	movzwl 0xf017df74,%eax
f0100303:	0f b7 c8             	movzwl %ax,%ecx
f0100306:	8b 15 70 df 17 f0    	mov    0xf017df70,%edx
f010030c:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100310:	83 c0 01             	add    $0x1,%eax
f0100313:	66 a3 74 df 17 f0    	mov    %ax,0xf017df74
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100319:	66 81 3d 74 df 17 f0 	cmpw   $0x7cf,0xf017df74
f0100320:	cf 07 
f0100322:	76 42                	jbe    f0100366 <cons_putc+0x19f>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100324:	a1 70 df 17 f0       	mov    0xf017df70,%eax
f0100329:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100330:	00 
f0100331:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100337:	89 54 24 04          	mov    %edx,0x4(%esp)
f010033b:	89 04 24             	mov    %eax,(%esp)
f010033e:	e8 5b 49 00 00       	call   f0104c9e <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100343:	8b 15 70 df 17 f0    	mov    0xf017df70,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100349:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010034e:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100354:	83 c0 01             	add    $0x1,%eax
f0100357:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f010035c:	75 f0                	jne    f010034e <cons_putc+0x187>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010035e:	66 83 2d 74 df 17 f0 	subw   $0x50,0xf017df74
f0100365:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100366:	8b 0d 6c df 17 f0    	mov    0xf017df6c,%ecx
f010036c:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100371:	89 ca                	mov    %ecx,%edx
f0100373:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100374:	0f b7 35 74 df 17 f0 	movzwl 0xf017df74,%esi
f010037b:	8d 59 01             	lea    0x1(%ecx),%ebx
f010037e:	89 f0                	mov    %esi,%eax
f0100380:	66 c1 e8 08          	shr    $0x8,%ax
f0100384:	89 da                	mov    %ebx,%edx
f0100386:	ee                   	out    %al,(%dx)
f0100387:	b8 0f 00 00 00       	mov    $0xf,%eax
f010038c:	89 ca                	mov    %ecx,%edx
f010038e:	ee                   	out    %al,(%dx)
f010038f:	89 f0                	mov    %esi,%eax
f0100391:	89 da                	mov    %ebx,%edx
f0100393:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100394:	83 c4 2c             	add    $0x2c,%esp
f0100397:	5b                   	pop    %ebx
f0100398:	5e                   	pop    %esi
f0100399:	5f                   	pop    %edi
f010039a:	5d                   	pop    %ebp
f010039b:	c3                   	ret    

f010039c <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010039c:	55                   	push   %ebp
f010039d:	89 e5                	mov    %esp,%ebp
f010039f:	53                   	push   %ebx
f01003a0:	83 ec 14             	sub    $0x14,%esp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003a3:	ba 64 00 00 00       	mov    $0x64,%edx
f01003a8:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01003a9:	0f b6 c0             	movzbl %al,%eax
		return -1;
f01003ac:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01003b1:	a8 01                	test   $0x1,%al
f01003b3:	0f 84 e6 00 00 00    	je     f010049f <kbd_proc_data+0x103>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01003b9:	a8 20                	test   $0x20,%al
f01003bb:	0f 85 de 00 00 00    	jne    f010049f <kbd_proc_data+0x103>
f01003c1:	b2 60                	mov    $0x60,%dl
f01003c3:	ec                   	in     (%dx),%al
f01003c4:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01003c6:	3c e0                	cmp    $0xe0,%al
f01003c8:	75 11                	jne    f01003db <kbd_proc_data+0x3f>
		// E0 escape character
		shift |= E0ESC;
f01003ca:	83 0d 68 df 17 f0 40 	orl    $0x40,0xf017df68
		return 0;
f01003d1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003d6:	e9 c4 00 00 00       	jmp    f010049f <kbd_proc_data+0x103>
	} else if (data & 0x80) {
f01003db:	84 c0                	test   %al,%al
f01003dd:	79 37                	jns    f0100416 <kbd_proc_data+0x7a>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003df:	8b 0d 68 df 17 f0    	mov    0xf017df68,%ecx
f01003e5:	89 cb                	mov    %ecx,%ebx
f01003e7:	83 e3 40             	and    $0x40,%ebx
f01003ea:	83 e0 7f             	and    $0x7f,%eax
f01003ed:	85 db                	test   %ebx,%ebx
f01003ef:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003f2:	0f b6 d2             	movzbl %dl,%edx
f01003f5:	0f b6 82 a0 51 10 f0 	movzbl -0xfefae60(%edx),%eax
f01003fc:	83 c8 40             	or     $0x40,%eax
f01003ff:	0f b6 c0             	movzbl %al,%eax
f0100402:	f7 d0                	not    %eax
f0100404:	21 c1                	and    %eax,%ecx
f0100406:	89 0d 68 df 17 f0    	mov    %ecx,0xf017df68
		return 0;
f010040c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100411:	e9 89 00 00 00       	jmp    f010049f <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100416:	8b 0d 68 df 17 f0    	mov    0xf017df68,%ecx
f010041c:	f6 c1 40             	test   $0x40,%cl
f010041f:	74 0e                	je     f010042f <kbd_proc_data+0x93>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100421:	89 c2                	mov    %eax,%edx
f0100423:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100426:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100429:	89 0d 68 df 17 f0    	mov    %ecx,0xf017df68
	}

	shift |= shiftcode[data];
f010042f:	0f b6 d2             	movzbl %dl,%edx
f0100432:	0f b6 82 a0 51 10 f0 	movzbl -0xfefae60(%edx),%eax
f0100439:	0b 05 68 df 17 f0    	or     0xf017df68,%eax
	shift ^= togglecode[data];
f010043f:	0f b6 8a a0 52 10 f0 	movzbl -0xfefad60(%edx),%ecx
f0100446:	31 c8                	xor    %ecx,%eax
f0100448:	a3 68 df 17 f0       	mov    %eax,0xf017df68

	c = charcode[shift & (CTL | SHIFT)][data];
f010044d:	89 c1                	mov    %eax,%ecx
f010044f:	83 e1 03             	and    $0x3,%ecx
f0100452:	8b 0c 8d a0 53 10 f0 	mov    -0xfefac60(,%ecx,4),%ecx
f0100459:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f010045d:	a8 08                	test   $0x8,%al
f010045f:	74 19                	je     f010047a <kbd_proc_data+0xde>
		if ('a' <= c && c <= 'z')
f0100461:	8d 53 9f             	lea    -0x61(%ebx),%edx
f0100464:	83 fa 19             	cmp    $0x19,%edx
f0100467:	77 05                	ja     f010046e <kbd_proc_data+0xd2>
			c += 'A' - 'a';
f0100469:	83 eb 20             	sub    $0x20,%ebx
f010046c:	eb 0c                	jmp    f010047a <kbd_proc_data+0xde>
		else if ('A' <= c && c <= 'Z')
f010046e:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f0100471:	8d 53 20             	lea    0x20(%ebx),%edx
f0100474:	83 f9 19             	cmp    $0x19,%ecx
f0100477:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010047a:	f7 d0                	not    %eax
f010047c:	a8 06                	test   $0x6,%al
f010047e:	75 1f                	jne    f010049f <kbd_proc_data+0x103>
f0100480:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100486:	75 17                	jne    f010049f <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f0100488:	c7 04 24 6d 51 10 f0 	movl   $0xf010516d,(%esp)
f010048f:	e8 92 32 00 00       	call   f0103726 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100494:	ba 92 00 00 00       	mov    $0x92,%edx
f0100499:	b8 03 00 00 00       	mov    $0x3,%eax
f010049e:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010049f:	89 d8                	mov    %ebx,%eax
f01004a1:	83 c4 14             	add    $0x14,%esp
f01004a4:	5b                   	pop    %ebx
f01004a5:	5d                   	pop    %ebp
f01004a6:	c3                   	ret    

f01004a7 <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004a7:	55                   	push   %ebp
f01004a8:	89 e5                	mov    %esp,%ebp
f01004aa:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f01004ad:	80 3d 40 dd 17 f0 00 	cmpb   $0x0,0xf017dd40
f01004b4:	74 0a                	je     f01004c0 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f01004b6:	b8 6e 01 10 f0       	mov    $0xf010016e,%eax
f01004bb:	e8 ca fc ff ff       	call   f010018a <cons_intr>
}
f01004c0:	c9                   	leave  
f01004c1:	c3                   	ret    

f01004c2 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004c2:	55                   	push   %ebp
f01004c3:	89 e5                	mov    %esp,%ebp
f01004c5:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004c8:	b8 9c 03 10 f0       	mov    $0xf010039c,%eax
f01004cd:	e8 b8 fc ff ff       	call   f010018a <cons_intr>
}
f01004d2:	c9                   	leave  
f01004d3:	c3                   	ret    

f01004d4 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004d4:	55                   	push   %ebp
f01004d5:	89 e5                	mov    %esp,%ebp
f01004d7:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004da:	e8 c8 ff ff ff       	call   f01004a7 <serial_intr>
	kbd_intr();
f01004df:	e8 de ff ff ff       	call   f01004c2 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004e4:	8b 15 60 df 17 f0    	mov    0xf017df60,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f01004ea:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004ef:	3b 15 64 df 17 f0    	cmp    0xf017df64,%edx
f01004f5:	74 1e                	je     f0100515 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f01004f7:	0f b6 82 60 dd 17 f0 	movzbl -0xfe822a0(%edx),%eax
f01004fe:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f0100501:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100507:	b9 00 00 00 00       	mov    $0x0,%ecx
f010050c:	0f 44 d1             	cmove  %ecx,%edx
f010050f:	89 15 60 df 17 f0    	mov    %edx,0xf017df60
		return c;
	}
	return 0;
}
f0100515:	c9                   	leave  
f0100516:	c3                   	ret    

f0100517 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100517:	55                   	push   %ebp
f0100518:	89 e5                	mov    %esp,%ebp
f010051a:	57                   	push   %edi
f010051b:	56                   	push   %esi
f010051c:	53                   	push   %ebx
f010051d:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100520:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100527:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010052e:	5a a5 
	if (*cp != 0xA55A) {
f0100530:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100537:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010053b:	74 11                	je     f010054e <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010053d:	c7 05 6c df 17 f0 b4 	movl   $0x3b4,0xf017df6c
f0100544:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100547:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010054c:	eb 16                	jmp    f0100564 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010054e:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100555:	c7 05 6c df 17 f0 d4 	movl   $0x3d4,0xf017df6c
f010055c:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010055f:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100564:	8b 0d 6c df 17 f0    	mov    0xf017df6c,%ecx
f010056a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010056f:	89 ca                	mov    %ecx,%edx
f0100571:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100572:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100575:	89 da                	mov    %ebx,%edx
f0100577:	ec                   	in     (%dx),%al
f0100578:	0f b6 f8             	movzbl %al,%edi
f010057b:	c1 e7 08             	shl    $0x8,%edi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010057e:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100583:	89 ca                	mov    %ecx,%edx
f0100585:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100586:	89 da                	mov    %ebx,%edx
f0100588:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100589:	89 35 70 df 17 f0    	mov    %esi,0xf017df70

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010058f:	0f b6 d8             	movzbl %al,%ebx
f0100592:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100594:	66 89 3d 74 df 17 f0 	mov    %di,0xf017df74
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010059b:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005a0:	b8 00 00 00 00       	mov    $0x0,%eax
f01005a5:	89 da                	mov    %ebx,%edx
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	b2 fb                	mov    $0xfb,%dl
f01005aa:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005af:	ee                   	out    %al,(%dx)
f01005b0:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f01005b5:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005ba:	89 ca                	mov    %ecx,%edx
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	b2 f9                	mov    $0xf9,%dl
f01005bf:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c4:	ee                   	out    %al,(%dx)
f01005c5:	b2 fb                	mov    $0xfb,%dl
f01005c7:	b8 03 00 00 00       	mov    $0x3,%eax
f01005cc:	ee                   	out    %al,(%dx)
f01005cd:	b2 fc                	mov    $0xfc,%dl
f01005cf:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d4:	ee                   	out    %al,(%dx)
f01005d5:	b2 f9                	mov    $0xf9,%dl
f01005d7:	b8 01 00 00 00       	mov    $0x1,%eax
f01005dc:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005dd:	b2 fd                	mov    $0xfd,%dl
f01005df:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005e0:	3c ff                	cmp    $0xff,%al
f01005e2:	0f 95 c0             	setne  %al
f01005e5:	89 c6                	mov    %eax,%esi
f01005e7:	a2 40 dd 17 f0       	mov    %al,0xf017dd40
f01005ec:	89 da                	mov    %ebx,%edx
f01005ee:	ec                   	in     (%dx),%al
f01005ef:	89 ca                	mov    %ecx,%edx
f01005f1:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005f2:	89 f0                	mov    %esi,%eax
f01005f4:	84 c0                	test   %al,%al
f01005f6:	75 0c                	jne    f0100604 <cons_init+0xed>
		cprintf("Serial port does not exist!\n");
f01005f8:	c7 04 24 79 51 10 f0 	movl   $0xf0105179,(%esp)
f01005ff:	e8 22 31 00 00       	call   f0103726 <cprintf>
}
f0100604:	83 c4 1c             	add    $0x1c,%esp
f0100607:	5b                   	pop    %ebx
f0100608:	5e                   	pop    %esi
f0100609:	5f                   	pop    %edi
f010060a:	5d                   	pop    %ebp
f010060b:	c3                   	ret    

f010060c <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010060c:	55                   	push   %ebp
f010060d:	89 e5                	mov    %esp,%ebp
f010060f:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100612:	8b 45 08             	mov    0x8(%ebp),%eax
f0100615:	e8 ad fb ff ff       	call   f01001c7 <cons_putc>
}
f010061a:	c9                   	leave  
f010061b:	c3                   	ret    

f010061c <getchar>:

int
getchar(void)
{
f010061c:	55                   	push   %ebp
f010061d:	89 e5                	mov    %esp,%ebp
f010061f:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100622:	e8 ad fe ff ff       	call   f01004d4 <cons_getc>
f0100627:	85 c0                	test   %eax,%eax
f0100629:	74 f7                	je     f0100622 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010062b:	c9                   	leave  
f010062c:	c3                   	ret    

f010062d <iscons>:

int
iscons(int fdnum)
{
f010062d:	55                   	push   %ebp
f010062e:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100630:	b8 01 00 00 00       	mov    $0x1,%eax
f0100635:	5d                   	pop    %ebp
f0100636:	c3                   	ret    
	...

f0100640 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100640:	55                   	push   %ebp
f0100641:	89 e5                	mov    %esp,%ebp
f0100643:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100646:	c7 04 24 b0 53 10 f0 	movl   $0xf01053b0,(%esp)
f010064d:	e8 d4 30 00 00       	call   f0103726 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100652:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100659:	00 
f010065a:	c7 04 24 74 54 10 f0 	movl   $0xf0105474,(%esp)
f0100661:	e8 c0 30 00 00       	call   f0103726 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100666:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010066d:	00 
f010066e:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100675:	f0 
f0100676:	c7 04 24 9c 54 10 f0 	movl   $0xf010549c,(%esp)
f010067d:	e8 a4 30 00 00       	call   f0103726 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100682:	c7 44 24 08 15 51 10 	movl   $0x105115,0x8(%esp)
f0100689:	00 
f010068a:	c7 44 24 04 15 51 10 	movl   $0xf0105115,0x4(%esp)
f0100691:	f0 
f0100692:	c7 04 24 c0 54 10 f0 	movl   $0xf01054c0,(%esp)
f0100699:	e8 88 30 00 00       	call   f0103726 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010069e:	c7 44 24 08 2f dd 17 	movl   $0x17dd2f,0x8(%esp)
f01006a5:	00 
f01006a6:	c7 44 24 04 2f dd 17 	movl   $0xf017dd2f,0x4(%esp)
f01006ad:	f0 
f01006ae:	c7 04 24 e4 54 10 f0 	movl   $0xf01054e4,(%esp)
f01006b5:	e8 6c 30 00 00       	call   f0103726 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006ba:	c7 44 24 08 30 ec 17 	movl   $0x17ec30,0x8(%esp)
f01006c1:	00 
f01006c2:	c7 44 24 04 30 ec 17 	movl   $0xf017ec30,0x4(%esp)
f01006c9:	f0 
f01006ca:	c7 04 24 08 55 10 f0 	movl   $0xf0105508,(%esp)
f01006d1:	e8 50 30 00 00       	call   f0103726 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006d6:	b8 2f f0 17 f0       	mov    $0xf017f02f,%eax
f01006db:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01006e0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006e5:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006eb:	85 c0                	test   %eax,%eax
f01006ed:	0f 48 c2             	cmovs  %edx,%eax
f01006f0:	c1 f8 0a             	sar    $0xa,%eax
f01006f3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006f7:	c7 04 24 2c 55 10 f0 	movl   $0xf010552c,(%esp)
f01006fe:	e8 23 30 00 00       	call   f0103726 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100703:	b8 00 00 00 00       	mov    $0x0,%eax
f0100708:	c9                   	leave  
f0100709:	c3                   	ret    

f010070a <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010070a:	55                   	push   %ebp
f010070b:	89 e5                	mov    %esp,%ebp
f010070d:	53                   	push   %ebx
f010070e:	83 ec 14             	sub    $0x14,%esp
f0100711:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100716:	8b 83 44 56 10 f0    	mov    -0xfefa9bc(%ebx),%eax
f010071c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100720:	8b 83 40 56 10 f0    	mov    -0xfefa9c0(%ebx),%eax
f0100726:	89 44 24 04          	mov    %eax,0x4(%esp)
f010072a:	c7 04 24 c9 53 10 f0 	movl   $0xf01053c9,(%esp)
f0100731:	e8 f0 2f 00 00       	call   f0103726 <cprintf>
f0100736:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
f0100739:	83 fb 24             	cmp    $0x24,%ebx
f010073c:	75 d8                	jne    f0100716 <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f010073e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100743:	83 c4 14             	add    $0x14,%esp
f0100746:	5b                   	pop    %ebx
f0100747:	5d                   	pop    %ebp
f0100748:	c3                   	ret    

f0100749 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100749:	55                   	push   %ebp
f010074a:	89 e5                	mov    %esp,%ebp
f010074c:	56                   	push   %esi
f010074d:	53                   	push   %ebx
f010074e:	83 ec 40             	sub    $0x40,%esp
	// Your code here.
	struct Eipdebuginfo info;
	int *ebp = (int*)read_ebp();
f0100751:	89 eb                	mov    %ebp,%ebx
	cprintf("Stack backtrace:\n");
f0100753:	c7 04 24 d2 53 10 f0 	movl   $0xf01053d2,(%esp)
f010075a:	e8 c7 2f 00 00       	call   f0103726 <cprintf>
	while (ebp != 0)
	{
		cprintf("ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, *(ebp+1), *(ebp+2), *(ebp+3), *(ebp+4), *(ebp+5), *(ebp+6));
		debuginfo_eip(*(ebp+1), &info);
f010075f:	8d 75 e0             	lea    -0x20(%ebp),%esi
{
	// Your code here.
	struct Eipdebuginfo info;
	int *ebp = (int*)read_ebp();
	cprintf("Stack backtrace:\n");
	while (ebp != 0)
f0100762:	eb 7d                	jmp    f01007e1 <mon_backtrace+0x98>
	{
		cprintf("ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, *(ebp+1), *(ebp+2), *(ebp+3), *(ebp+4), *(ebp+5), *(ebp+6));
f0100764:	8b 43 18             	mov    0x18(%ebx),%eax
f0100767:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f010076b:	8b 43 14             	mov    0x14(%ebx),%eax
f010076e:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100772:	8b 43 10             	mov    0x10(%ebx),%eax
f0100775:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100779:	8b 43 0c             	mov    0xc(%ebx),%eax
f010077c:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100780:	8b 43 08             	mov    0x8(%ebx),%eax
f0100783:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100787:	8b 43 04             	mov    0x4(%ebx),%eax
f010078a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010078e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100792:	c7 04 24 58 55 10 f0 	movl   $0xf0105558,(%esp)
f0100799:	e8 88 2f 00 00       	call   f0103726 <cprintf>
		debuginfo_eip(*(ebp+1), &info);
f010079e:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007a2:	8b 43 04             	mov    0x4(%ebx),%eax
f01007a5:	89 04 24             	mov    %eax,(%esp)
f01007a8:	e8 b9 39 00 00       	call   f0104166 <debuginfo_eip>
		cprintf("       %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, *(ebp+1)-info.eip_fn_addr);
f01007ad:	8b 43 04             	mov    0x4(%ebx),%eax
f01007b0:	2b 45 f0             	sub    -0x10(%ebp),%eax
f01007b3:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007b7:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01007ba:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007be:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01007c1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007c5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01007c8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007cc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01007cf:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007d3:	c7 04 24 e4 53 10 f0 	movl   $0xf01053e4,(%esp)
f01007da:	e8 47 2f 00 00       	call   f0103726 <cprintf>
		ebp = (int*)*ebp;
f01007df:	8b 1b                	mov    (%ebx),%ebx
{
	// Your code here.
	struct Eipdebuginfo info;
	int *ebp = (int*)read_ebp();
	cprintf("Stack backtrace:\n");
	while (ebp != 0)
f01007e1:	85 db                	test   %ebx,%ebx
f01007e3:	0f 85 7b ff ff ff    	jne    f0100764 <mon_backtrace+0x1b>
		debuginfo_eip(*(ebp+1), &info);
		cprintf("       %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, *(ebp+1)-info.eip_fn_addr);
		ebp = (int*)*ebp;
	}
	return 0;
}
f01007e9:	b8 00 00 00 00       	mov    $0x0,%eax
f01007ee:	83 c4 40             	add    $0x40,%esp
f01007f1:	5b                   	pop    %ebx
f01007f2:	5e                   	pop    %esi
f01007f3:	5d                   	pop    %ebp
f01007f4:	c3                   	ret    

f01007f5 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007f5:	55                   	push   %ebp
f01007f6:	89 e5                	mov    %esp,%ebp
f01007f8:	57                   	push   %edi
f01007f9:	56                   	push   %esi
f01007fa:	53                   	push   %ebx
f01007fb:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;
	cprintf("Welcome to the JOS kernel monitor!\n");
f01007fe:	c7 04 24 8c 55 10 f0 	movl   $0xf010558c,(%esp)
f0100805:	e8 1c 2f 00 00       	call   f0103726 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010080a:	c7 04 24 b0 55 10 f0 	movl   $0xf01055b0,(%esp)
f0100811:	e8 10 2f 00 00       	call   f0103726 <cprintf>

	if (tf != NULL)
f0100816:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010081a:	74 0b                	je     f0100827 <monitor+0x32>
		print_trapframe(tf);
f010081c:	8b 45 08             	mov    0x8(%ebp),%eax
f010081f:	89 04 24             	mov    %eax,(%esp)
f0100822:	e8 61 33 00 00       	call   f0103b88 <print_trapframe>

	while (1) {
		buf = readline("K> ");
f0100827:	c7 04 24 fb 53 10 f0 	movl   $0xf01053fb,(%esp)
f010082e:	e8 bd 41 00 00       	call   f01049f0 <readline>
f0100833:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100835:	85 c0                	test   %eax,%eax
f0100837:	74 ee                	je     f0100827 <monitor+0x32>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100839:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100840:	be 00 00 00 00       	mov    $0x0,%esi
f0100845:	eb 06                	jmp    f010084d <monitor+0x58>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100847:	c6 03 00             	movb   $0x0,(%ebx)
f010084a:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010084d:	0f b6 03             	movzbl (%ebx),%eax
f0100850:	84 c0                	test   %al,%al
f0100852:	74 63                	je     f01008b7 <monitor+0xc2>
f0100854:	0f be c0             	movsbl %al,%eax
f0100857:	89 44 24 04          	mov    %eax,0x4(%esp)
f010085b:	c7 04 24 ff 53 10 f0 	movl   $0xf01053ff,(%esp)
f0100862:	e8 9f 43 00 00       	call   f0104c06 <strchr>
f0100867:	85 c0                	test   %eax,%eax
f0100869:	75 dc                	jne    f0100847 <monitor+0x52>
			*buf++ = 0;
		if (*buf == 0)
f010086b:	80 3b 00             	cmpb   $0x0,(%ebx)
f010086e:	74 47                	je     f01008b7 <monitor+0xc2>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100870:	83 fe 0f             	cmp    $0xf,%esi
f0100873:	75 16                	jne    f010088b <monitor+0x96>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100875:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010087c:	00 
f010087d:	c7 04 24 04 54 10 f0 	movl   $0xf0105404,(%esp)
f0100884:	e8 9d 2e 00 00       	call   f0103726 <cprintf>
f0100889:	eb 9c                	jmp    f0100827 <monitor+0x32>
			return 0;
		}
		argv[argc++] = buf;
f010088b:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010088f:	83 c6 01             	add    $0x1,%esi
f0100892:	eb 03                	jmp    f0100897 <monitor+0xa2>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100894:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100897:	0f b6 03             	movzbl (%ebx),%eax
f010089a:	84 c0                	test   %al,%al
f010089c:	74 af                	je     f010084d <monitor+0x58>
f010089e:	0f be c0             	movsbl %al,%eax
f01008a1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008a5:	c7 04 24 ff 53 10 f0 	movl   $0xf01053ff,(%esp)
f01008ac:	e8 55 43 00 00       	call   f0104c06 <strchr>
f01008b1:	85 c0                	test   %eax,%eax
f01008b3:	74 df                	je     f0100894 <monitor+0x9f>
f01008b5:	eb 96                	jmp    f010084d <monitor+0x58>
			buf++;
	}
	argv[argc] = 0;
f01008b7:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008be:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008bf:	85 f6                	test   %esi,%esi
f01008c1:	0f 84 60 ff ff ff    	je     f0100827 <monitor+0x32>
f01008c7:	bb 40 56 10 f0       	mov    $0xf0105640,%ebx
f01008cc:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008d1:	8b 03                	mov    (%ebx),%eax
f01008d3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008d7:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008da:	89 04 24             	mov    %eax,(%esp)
f01008dd:	e8 c5 42 00 00       	call   f0104ba7 <strcmp>
f01008e2:	85 c0                	test   %eax,%eax
f01008e4:	75 24                	jne    f010090a <monitor+0x115>
			return commands[i].func(argc, argv, tf);
f01008e6:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01008e9:	8b 55 08             	mov    0x8(%ebp),%edx
f01008ec:	89 54 24 08          	mov    %edx,0x8(%esp)
f01008f0:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008f3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01008f7:	89 34 24             	mov    %esi,(%esp)
f01008fa:	ff 14 85 48 56 10 f0 	call   *-0xfefa9b8(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100901:	85 c0                	test   %eax,%eax
f0100903:	78 28                	js     f010092d <monitor+0x138>
f0100905:	e9 1d ff ff ff       	jmp    f0100827 <monitor+0x32>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010090a:	83 c7 01             	add    $0x1,%edi
f010090d:	83 c3 0c             	add    $0xc,%ebx
f0100910:	83 ff 03             	cmp    $0x3,%edi
f0100913:	75 bc                	jne    f01008d1 <monitor+0xdc>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100915:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100918:	89 44 24 04          	mov    %eax,0x4(%esp)
f010091c:	c7 04 24 21 54 10 f0 	movl   $0xf0105421,(%esp)
f0100923:	e8 fe 2d 00 00       	call   f0103726 <cprintf>
f0100928:	e9 fa fe ff ff       	jmp    f0100827 <monitor+0x32>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010092d:	83 c4 5c             	add    $0x5c,%esp
f0100930:	5b                   	pop    %ebx
f0100931:	5e                   	pop    %esi
f0100932:	5f                   	pop    %edi
f0100933:	5d                   	pop    %ebp
f0100934:	c3                   	ret    
f0100935:	00 00                	add    %al,(%eax)
	...

f0100938 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100938:	55                   	push   %ebp
f0100939:	89 e5                	mov    %esp,%ebp
f010093b:	83 ec 18             	sub    $0x18,%esp
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f010093e:	89 d1                	mov    %edx,%ecx
f0100940:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100943:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
		return ~0;
f0100946:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f010094b:	f6 c1 01             	test   $0x1,%cl
f010094e:	74 57                	je     f01009a7 <check_va2pa+0x6f>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100950:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100956:	89 c8                	mov    %ecx,%eax
f0100958:	c1 e8 0c             	shr    $0xc,%eax
f010095b:	3b 05 24 ec 17 f0    	cmp    0xf017ec24,%eax
f0100961:	72 20                	jb     f0100983 <check_va2pa+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100963:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100967:	c7 44 24 08 64 56 10 	movl   $0xf0105664,0x8(%esp)
f010096e:	f0 
f010096f:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0100976:	00 
f0100977:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f010097e:	e8 33 f7 ff ff       	call   f01000b6 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100983:	c1 ea 0c             	shr    $0xc,%edx
f0100986:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010098c:	8b 84 91 00 00 00 f0 	mov    -0x10000000(%ecx,%edx,4),%eax
f0100993:	89 c2                	mov    %eax,%edx
f0100995:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100998:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010099d:	85 d2                	test   %edx,%edx
f010099f:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009a4:	0f 44 c2             	cmove  %edx,%eax
}
f01009a7:	c9                   	leave  
f01009a8:	c3                   	ret    

f01009a9 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009a9:	55                   	push   %ebp
f01009aa:	89 e5                	mov    %esp,%ebp
f01009ac:	83 ec 18             	sub    $0x18,%esp
f01009af:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01009b1:	83 3d 7c df 17 f0 00 	cmpl   $0x0,0xf017df7c
f01009b8:	75 0f                	jne    f01009c9 <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009ba:	b8 2f fc 17 f0       	mov    $0xf017fc2f,%eax
f01009bf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009c4:	a3 7c df 17 f0       	mov    %eax,0xf017df7c
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f01009c9:	a1 7c df 17 f0       	mov    0xf017df7c,%eax
	if (n > 0)
f01009ce:	85 d2                	test   %edx,%edx
f01009d0:	74 42                	je     f0100a14 <boot_alloc+0x6b>
	{
		nextfree = ROUNDUP(nextfree+n, PGSIZE);
f01009d2:	8d 94 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edx
f01009d9:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009df:	89 15 7c df 17 f0    	mov    %edx,0xf017df7c
		if ((uint32_t)nextfree-KERNBASE > npages*PGSIZE)
f01009e5:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f01009eb:	8b 0d 24 ec 17 f0    	mov    0xf017ec24,%ecx
f01009f1:	c1 e1 0c             	shl    $0xc,%ecx
f01009f4:	39 ca                	cmp    %ecx,%edx
f01009f6:	76 1c                	jbe    f0100a14 <boot_alloc+0x6b>
			panic("Out of memory.\n");
f01009f8:	c7 44 24 08 51 5e 10 	movl   $0xf0105e51,0x8(%esp)
f01009ff:	f0 
f0100a00:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
f0100a07:	00 
f0100a08:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0100a0f:	e8 a2 f6 ff ff       	call   f01000b6 <_panic>
	}
	return result;
}
f0100a14:	c9                   	leave  
f0100a15:	c3                   	ret    

f0100a16 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a16:	55                   	push   %ebp
f0100a17:	89 e5                	mov    %esp,%ebp
f0100a19:	83 ec 18             	sub    $0x18,%esp
f0100a1c:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100a1f:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100a22:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a24:	89 04 24             	mov    %eax,(%esp)
f0100a27:	e8 8c 2c 00 00       	call   f01036b8 <mc146818_read>
f0100a2c:	89 c6                	mov    %eax,%esi
f0100a2e:	83 c3 01             	add    $0x1,%ebx
f0100a31:	89 1c 24             	mov    %ebx,(%esp)
f0100a34:	e8 7f 2c 00 00       	call   f01036b8 <mc146818_read>
f0100a39:	c1 e0 08             	shl    $0x8,%eax
f0100a3c:	09 f0                	or     %esi,%eax
}
f0100a3e:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100a41:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100a44:	89 ec                	mov    %ebp,%esp
f0100a46:	5d                   	pop    %ebp
f0100a47:	c3                   	ret    

f0100a48 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a48:	55                   	push   %ebp
f0100a49:	89 e5                	mov    %esp,%ebp
f0100a4b:	57                   	push   %edi
f0100a4c:	56                   	push   %esi
f0100a4d:	53                   	push   %ebx
f0100a4e:	83 ec 4c             	sub    $0x4c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a51:	3c 01                	cmp    $0x1,%al
f0100a53:	19 f6                	sbb    %esi,%esi
f0100a55:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100a5b:	83 c6 01             	add    $0x1,%esi
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100a5e:	8b 15 80 df 17 f0    	mov    0xf017df80,%edx
f0100a64:	85 d2                	test   %edx,%edx
f0100a66:	75 1c                	jne    f0100a84 <check_page_free_list+0x3c>
		panic("'page_free_list' is a null pointer!");
f0100a68:	c7 44 24 08 88 56 10 	movl   $0xf0105688,0x8(%esp)
f0100a6f:	f0 
f0100a70:	c7 44 24 04 67 02 00 	movl   $0x267,0x4(%esp)
f0100a77:	00 
f0100a78:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0100a7f:	e8 32 f6 ff ff       	call   f01000b6 <_panic>

	if (only_low_memory) {
f0100a84:	84 c0                	test   %al,%al
f0100a86:	74 4b                	je     f0100ad3 <check_page_free_list+0x8b>
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a88:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0100a8b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100a8e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100a91:	89 45 dc             	mov    %eax,-0x24(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a94:	89 d0                	mov    %edx,%eax
f0100a96:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0100a9c:	c1 e0 09             	shl    $0x9,%eax
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a9f:	c1 e8 16             	shr    $0x16,%eax
f0100aa2:	39 c6                	cmp    %eax,%esi
f0100aa4:	0f 96 c0             	setbe  %al
f0100aa7:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100aaa:	8b 4c 85 d8          	mov    -0x28(%ebp,%eax,4),%ecx
f0100aae:	89 11                	mov    %edx,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ab0:	89 54 85 d8          	mov    %edx,-0x28(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ab4:	8b 12                	mov    (%edx),%edx
f0100ab6:	85 d2                	test   %edx,%edx
f0100ab8:	75 da                	jne    f0100a94 <check_page_free_list+0x4c>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100aba:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100abd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100ac3:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ac6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100ac9:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100acb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ace:	a3 80 df 17 f0       	mov    %eax,0xf017df80
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ad3:	8b 1d 80 df 17 f0    	mov    0xf017df80,%ebx
f0100ad9:	eb 63                	jmp    f0100b3e <check_page_free_list+0xf6>
f0100adb:	89 d8                	mov    %ebx,%eax
f0100add:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0100ae3:	c1 f8 03             	sar    $0x3,%eax
f0100ae6:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100ae9:	89 c2                	mov    %eax,%edx
f0100aeb:	c1 ea 16             	shr    $0x16,%edx
f0100aee:	39 d6                	cmp    %edx,%esi
f0100af0:	76 4a                	jbe    f0100b3c <check_page_free_list+0xf4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100af2:	89 c2                	mov    %eax,%edx
f0100af4:	c1 ea 0c             	shr    $0xc,%edx
f0100af7:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0100afd:	72 20                	jb     f0100b1f <check_page_free_list+0xd7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100aff:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b03:	c7 44 24 08 64 56 10 	movl   $0xf0105664,0x8(%esp)
f0100b0a:	f0 
f0100b0b:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100b12:	00 
f0100b13:	c7 04 24 61 5e 10 f0 	movl   $0xf0105e61,(%esp)
f0100b1a:	e8 97 f5 ff ff       	call   f01000b6 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b1f:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b26:	00 
f0100b27:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b2e:	00 
	return (void *)(pa + KERNBASE);
f0100b2f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b34:	89 04 24             	mov    %eax,(%esp)
f0100b37:	e8 07 41 00 00       	call   f0104c43 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b3c:	8b 1b                	mov    (%ebx),%ebx
f0100b3e:	85 db                	test   %ebx,%ebx
f0100b40:	75 99                	jne    f0100adb <check_page_free_list+0x93>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b42:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b47:	e8 5d fe ff ff       	call   f01009a9 <boot_alloc>
f0100b4c:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b4f:	8b 15 80 df 17 f0    	mov    0xf017df80,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b55:	8b 0d 2c ec 17 f0    	mov    0xf017ec2c,%ecx
		assert(pp < pages + npages);
f0100b5b:	a1 24 ec 17 f0       	mov    0xf017ec24,%eax
f0100b60:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b63:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100b66:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b69:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b6c:	be 00 00 00 00       	mov    $0x0,%esi
f0100b71:	89 4d c0             	mov    %ecx,-0x40(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b74:	e9 97 01 00 00       	jmp    f0100d10 <check_page_free_list+0x2c8>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b79:	3b 55 c0             	cmp    -0x40(%ebp),%edx
f0100b7c:	73 24                	jae    f0100ba2 <check_page_free_list+0x15a>
f0100b7e:	c7 44 24 0c 6f 5e 10 	movl   $0xf0105e6f,0xc(%esp)
f0100b85:	f0 
f0100b86:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0100b8d:	f0 
f0100b8e:	c7 44 24 04 81 02 00 	movl   $0x281,0x4(%esp)
f0100b95:	00 
f0100b96:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0100b9d:	e8 14 f5 ff ff       	call   f01000b6 <_panic>
		assert(pp < pages + npages);
f0100ba2:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100ba5:	72 24                	jb     f0100bcb <check_page_free_list+0x183>
f0100ba7:	c7 44 24 0c 90 5e 10 	movl   $0xf0105e90,0xc(%esp)
f0100bae:	f0 
f0100baf:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0100bb6:	f0 
f0100bb7:	c7 44 24 04 82 02 00 	movl   $0x282,0x4(%esp)
f0100bbe:	00 
f0100bbf:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0100bc6:	e8 eb f4 ff ff       	call   f01000b6 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bcb:	89 d0                	mov    %edx,%eax
f0100bcd:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100bd0:	a8 07                	test   $0x7,%al
f0100bd2:	74 24                	je     f0100bf8 <check_page_free_list+0x1b0>
f0100bd4:	c7 44 24 0c ac 56 10 	movl   $0xf01056ac,0xc(%esp)
f0100bdb:	f0 
f0100bdc:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0100be3:	f0 
f0100be4:	c7 44 24 04 83 02 00 	movl   $0x283,0x4(%esp)
f0100beb:	00 
f0100bec:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0100bf3:	e8 be f4 ff ff       	call   f01000b6 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100bf8:	c1 f8 03             	sar    $0x3,%eax
f0100bfb:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100bfe:	85 c0                	test   %eax,%eax
f0100c00:	75 24                	jne    f0100c26 <check_page_free_list+0x1de>
f0100c02:	c7 44 24 0c a4 5e 10 	movl   $0xf0105ea4,0xc(%esp)
f0100c09:	f0 
f0100c0a:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0100c11:	f0 
f0100c12:	c7 44 24 04 86 02 00 	movl   $0x286,0x4(%esp)
f0100c19:	00 
f0100c1a:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0100c21:	e8 90 f4 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c26:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c2b:	75 24                	jne    f0100c51 <check_page_free_list+0x209>
f0100c2d:	c7 44 24 0c b5 5e 10 	movl   $0xf0105eb5,0xc(%esp)
f0100c34:	f0 
f0100c35:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0100c3c:	f0 
f0100c3d:	c7 44 24 04 87 02 00 	movl   $0x287,0x4(%esp)
f0100c44:	00 
f0100c45:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0100c4c:	e8 65 f4 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c51:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c56:	75 24                	jne    f0100c7c <check_page_free_list+0x234>
f0100c58:	c7 44 24 0c e0 56 10 	movl   $0xf01056e0,0xc(%esp)
f0100c5f:	f0 
f0100c60:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0100c67:	f0 
f0100c68:	c7 44 24 04 88 02 00 	movl   $0x288,0x4(%esp)
f0100c6f:	00 
f0100c70:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0100c77:	e8 3a f4 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c7c:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c81:	75 24                	jne    f0100ca7 <check_page_free_list+0x25f>
f0100c83:	c7 44 24 0c ce 5e 10 	movl   $0xf0105ece,0xc(%esp)
f0100c8a:	f0 
f0100c8b:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0100c92:	f0 
f0100c93:	c7 44 24 04 89 02 00 	movl   $0x289,0x4(%esp)
f0100c9a:	00 
f0100c9b:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0100ca2:	e8 0f f4 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100ca7:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cac:	76 58                	jbe    f0100d06 <check_page_free_list+0x2be>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cae:	89 c1                	mov    %eax,%ecx
f0100cb0:	c1 e9 0c             	shr    $0xc,%ecx
f0100cb3:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100cb6:	77 20                	ja     f0100cd8 <check_page_free_list+0x290>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cb8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100cbc:	c7 44 24 08 64 56 10 	movl   $0xf0105664,0x8(%esp)
f0100cc3:	f0 
f0100cc4:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100ccb:	00 
f0100ccc:	c7 04 24 61 5e 10 f0 	movl   $0xf0105e61,(%esp)
f0100cd3:	e8 de f3 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0100cd8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100cdd:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0100ce0:	76 29                	jbe    f0100d0b <check_page_free_list+0x2c3>
f0100ce2:	c7 44 24 0c 04 57 10 	movl   $0xf0105704,0xc(%esp)
f0100ce9:	f0 
f0100cea:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0100cf1:	f0 
f0100cf2:	c7 44 24 04 8a 02 00 	movl   $0x28a,0x4(%esp)
f0100cf9:	00 
f0100cfa:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0100d01:	e8 b0 f3 ff ff       	call   f01000b6 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d06:	83 c6 01             	add    $0x1,%esi
f0100d09:	eb 03                	jmp    f0100d0e <check_page_free_list+0x2c6>
		else
			++nfree_extmem;
f0100d0b:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d0e:	8b 12                	mov    (%edx),%edx
f0100d10:	85 d2                	test   %edx,%edx
f0100d12:	0f 85 61 fe ff ff    	jne    f0100b79 <check_page_free_list+0x131>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d18:	85 f6                	test   %esi,%esi
f0100d1a:	7f 24                	jg     f0100d40 <check_page_free_list+0x2f8>
f0100d1c:	c7 44 24 0c e8 5e 10 	movl   $0xf0105ee8,0xc(%esp)
f0100d23:	f0 
f0100d24:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0100d2b:	f0 
f0100d2c:	c7 44 24 04 92 02 00 	movl   $0x292,0x4(%esp)
f0100d33:	00 
f0100d34:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0100d3b:	e8 76 f3 ff ff       	call   f01000b6 <_panic>
	assert(nfree_extmem > 0);
f0100d40:	85 db                	test   %ebx,%ebx
f0100d42:	7f 24                	jg     f0100d68 <check_page_free_list+0x320>
f0100d44:	c7 44 24 0c fa 5e 10 	movl   $0xf0105efa,0xc(%esp)
f0100d4b:	f0 
f0100d4c:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0100d53:	f0 
f0100d54:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f0100d5b:	00 
f0100d5c:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0100d63:	e8 4e f3 ff ff       	call   f01000b6 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100d68:	c7 04 24 4c 57 10 f0 	movl   $0xf010574c,(%esp)
f0100d6f:	e8 b2 29 00 00       	call   f0103726 <cprintf>
}
f0100d74:	83 c4 4c             	add    $0x4c,%esp
f0100d77:	5b                   	pop    %ebx
f0100d78:	5e                   	pop    %esi
f0100d79:	5f                   	pop    %edi
f0100d7a:	5d                   	pop    %ebp
f0100d7b:	c3                   	ret    

f0100d7c <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100d7c:	55                   	push   %ebp
f0100d7d:	89 e5                	mov    %esp,%ebp
f0100d7f:	56                   	push   %esi
f0100d80:	53                   	push   %ebx
f0100d81:	83 ec 10             	sub    $0x10,%esp
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	size_t low_pgnum = PGNUM(IOPHYSMEM);
	size_t high_pgnum = PGNUM(PADDR(boot_alloc(0)));
f0100d84:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d89:	e8 1b fc ff ff       	call   f01009a9 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100d8e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100d93:	77 20                	ja     f0100db5 <page_init+0x39>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100d95:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d99:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f0100da0:	f0 
f0100da1:	c7 44 24 04 20 01 00 	movl   $0x120,0x4(%esp)
f0100da8:	00 
f0100da9:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0100db0:	e8 01 f3 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100db5:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f0100dbb:	c1 eb 0c             	shr    $0xc,%ebx
f0100dbe:	a1 80 df 17 f0       	mov    0xf017df80,%eax
	for (i = 0; i < npages; i++) 
f0100dc3:	ba 00 00 00 00       	mov    $0x0,%edx
f0100dc8:	eb 4d                	jmp    f0100e17 <page_init+0x9b>
	{
		if (i == 0 || (i >= low_pgnum && i < high_pgnum))
f0100dca:	85 d2                	test   %edx,%edx
f0100dcc:	74 0c                	je     f0100dda <page_init+0x5e>
f0100dce:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f0100dd4:	76 1f                	jbe    f0100df5 <page_init+0x79>
f0100dd6:	39 da                	cmp    %ebx,%edx
f0100dd8:	73 1b                	jae    f0100df5 <page_init+0x79>
		{
			pages[i].pp_ref = 1;
f0100dda:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f0100de1:	03 0d 2c ec 17 f0    	add    0xf017ec2c,%ecx
f0100de7:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
			pages[i].pp_link = NULL;
f0100ded:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
			continue;
f0100df3:	eb 1f                	jmp    f0100e14 <page_init+0x98>
		}
		else
		{
			pages[i].pp_ref = 0;
f0100df5:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f0100dfc:	89 ce                	mov    %ecx,%esi
f0100dfe:	03 35 2c ec 17 f0    	add    0xf017ec2c,%esi
f0100e04:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
			pages[i].pp_link = page_free_list;
f0100e0a:	89 06                	mov    %eax,(%esi)
			page_free_list = &pages[i];
f0100e0c:	89 c8                	mov    %ecx,%eax
f0100e0e:	03 05 2c ec 17 f0    	add    0xf017ec2c,%eax
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	size_t low_pgnum = PGNUM(IOPHYSMEM);
	size_t high_pgnum = PGNUM(PADDR(boot_alloc(0)));
	for (i = 0; i < npages; i++) 
f0100e14:	83 c2 01             	add    $0x1,%edx
f0100e17:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0100e1d:	72 ab                	jb     f0100dca <page_init+0x4e>
f0100e1f:	a3 80 df 17 f0       	mov    %eax,0xf017df80
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0100e24:	83 c4 10             	add    $0x10,%esp
f0100e27:	5b                   	pop    %ebx
f0100e28:	5e                   	pop    %esi
f0100e29:	5d                   	pop    %ebp
f0100e2a:	c3                   	ret    

f0100e2b <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100e2b:	55                   	push   %ebp
f0100e2c:	89 e5                	mov    %esp,%ebp
f0100e2e:	53                   	push   %ebx
f0100e2f:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	struct PageInfo *pp;
	if (page_free_list == NULL)
f0100e32:	8b 1d 80 df 17 f0    	mov    0xf017df80,%ebx
f0100e38:	85 db                	test   %ebx,%ebx
f0100e3a:	74 6b                	je     f0100ea7 <page_alloc+0x7c>
		pp = NULL;
	else
	{
		pp = page_free_list;
		page_free_list = pp->pp_link;
f0100e3c:	8b 03                	mov    (%ebx),%eax
f0100e3e:	a3 80 df 17 f0       	mov    %eax,0xf017df80
		pp->pp_link = NULL;
f0100e43:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		if (alloc_flags & ALLOC_ZERO)
f0100e49:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100e4d:	74 58                	je     f0100ea7 <page_alloc+0x7c>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e4f:	89 d8                	mov    %ebx,%eax
f0100e51:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0100e57:	c1 f8 03             	sar    $0x3,%eax
f0100e5a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e5d:	89 c2                	mov    %eax,%edx
f0100e5f:	c1 ea 0c             	shr    $0xc,%edx
f0100e62:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0100e68:	72 20                	jb     f0100e8a <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e6a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e6e:	c7 44 24 08 64 56 10 	movl   $0xf0105664,0x8(%esp)
f0100e75:	f0 
f0100e76:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100e7d:	00 
f0100e7e:	c7 04 24 61 5e 10 f0 	movl   $0xf0105e61,(%esp)
f0100e85:	e8 2c f2 ff ff       	call   f01000b6 <_panic>
			memset(page2kva(pp), 0, PGSIZE);
f0100e8a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100e91:	00 
f0100e92:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100e99:	00 
	return (void *)(pa + KERNBASE);
f0100e9a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e9f:	89 04 24             	mov    %eax,(%esp)
f0100ea2:	e8 9c 3d 00 00       	call   f0104c43 <memset>
	}
	return pp;
}
f0100ea7:	89 d8                	mov    %ebx,%eax
f0100ea9:	83 c4 14             	add    $0x14,%esp
f0100eac:	5b                   	pop    %ebx
f0100ead:	5d                   	pop    %ebp
f0100eae:	c3                   	ret    

f0100eaf <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100eaf:	55                   	push   %ebp
f0100eb0:	89 e5                	mov    %esp,%ebp
f0100eb2:	83 ec 18             	sub    $0x18,%esp
f0100eb5:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref || pp->pp_link)
f0100eb8:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100ebd:	75 05                	jne    f0100ec4 <page_free+0x15>
f0100ebf:	83 38 00             	cmpl   $0x0,(%eax)
f0100ec2:	74 1c                	je     f0100ee0 <page_free+0x31>
		panic("error in page_free!\n");
f0100ec4:	c7 44 24 08 0b 5f 10 	movl   $0xf0105f0b,0x8(%esp)
f0100ecb:	f0 
f0100ecc:	c7 44 24 04 5b 01 00 	movl   $0x15b,0x4(%esp)
f0100ed3:	00 
f0100ed4:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0100edb:	e8 d6 f1 ff ff       	call   f01000b6 <_panic>
	pp->pp_link = page_free_list;
f0100ee0:	8b 15 80 df 17 f0    	mov    0xf017df80,%edx
f0100ee6:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100ee8:	a3 80 df 17 f0       	mov    %eax,0xf017df80
}
f0100eed:	c9                   	leave  
f0100eee:	c3                   	ret    

f0100eef <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100eef:	55                   	push   %ebp
f0100ef0:	89 e5                	mov    %esp,%ebp
f0100ef2:	83 ec 18             	sub    $0x18,%esp
f0100ef5:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100ef8:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0100efc:	83 ea 01             	sub    $0x1,%edx
f0100eff:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100f03:	66 85 d2             	test   %dx,%dx
f0100f06:	75 08                	jne    f0100f10 <page_decref+0x21>
		page_free(pp);
f0100f08:	89 04 24             	mov    %eax,(%esp)
f0100f0b:	e8 9f ff ff ff       	call   f0100eaf <page_free>
}
f0100f10:	c9                   	leave  
f0100f11:	c3                   	ret    

f0100f12 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f12:	55                   	push   %ebp
f0100f13:	89 e5                	mov    %esp,%ebp
f0100f15:	56                   	push   %esi
f0100f16:	53                   	push   %ebx
f0100f17:	83 ec 10             	sub    $0x10,%esp
f0100f1a:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pde_t *pdentry = pgdir + PDX(va);
f0100f1d:	89 f3                	mov    %esi,%ebx
f0100f1f:	c1 eb 16             	shr    $0x16,%ebx
f0100f22:	c1 e3 02             	shl    $0x2,%ebx
f0100f25:	03 5d 08             	add    0x8(%ebp),%ebx
	if (*pdentry & PTE_P)
f0100f28:	8b 03                	mov    (%ebx),%eax
f0100f2a:	a8 01                	test   $0x1,%al
f0100f2c:	74 47                	je     f0100f75 <pgdir_walk+0x63>
	{
		void *pt = (void*)KADDR(PTE_ADDR(*pdentry));
f0100f2e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f33:	89 c2                	mov    %eax,%edx
f0100f35:	c1 ea 0c             	shr    $0xc,%edx
f0100f38:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0100f3e:	72 20                	jb     f0100f60 <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f40:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f44:	c7 44 24 08 64 56 10 	movl   $0xf0105664,0x8(%esp)
f0100f4b:	f0 
f0100f4c:	c7 44 24 04 88 01 00 	movl   $0x188,0x4(%esp)
f0100f53:	00 
f0100f54:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0100f5b:	e8 56 f1 ff ff       	call   f01000b6 <_panic>
		return (pte_t*)pt + PTX(va);
f0100f60:	c1 ee 0a             	shr    $0xa,%esi
f0100f63:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100f69:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100f70:	e9 85 00 00 00       	jmp    f0100ffa <pgdir_walk+0xe8>
	}
	else
	{
		if (create == 0)
f0100f75:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100f79:	74 73                	je     f0100fee <pgdir_walk+0xdc>
			return NULL;
		struct PageInfo *newpg = page_alloc(1);
f0100f7b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100f82:	e8 a4 fe ff ff       	call   f0100e2b <page_alloc>
		if (newpg == NULL)
f0100f87:	85 c0                	test   %eax,%eax
f0100f89:	74 6a                	je     f0100ff5 <pgdir_walk+0xe3>
			return NULL;
		newpg->pp_ref++;
f0100f8b:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f90:	89 c2                	mov    %eax,%edx
f0100f92:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f0100f98:	c1 fa 03             	sar    $0x3,%edx
f0100f9b:	c1 e2 0c             	shl    $0xc,%edx
		*pdentry = page2pa(newpg) | PTE_W | PTE_P | PTE_U;
f0100f9e:	83 ca 07             	or     $0x7,%edx
f0100fa1:	89 13                	mov    %edx,(%ebx)
f0100fa3:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0100fa9:	c1 f8 03             	sar    $0x3,%eax
f0100fac:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100faf:	89 c2                	mov    %eax,%edx
f0100fb1:	c1 ea 0c             	shr    $0xc,%edx
f0100fb4:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0100fba:	72 20                	jb     f0100fdc <pgdir_walk+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fbc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fc0:	c7 44 24 08 64 56 10 	movl   $0xf0105664,0x8(%esp)
f0100fc7:	f0 
f0100fc8:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100fcf:	00 
f0100fd0:	c7 04 24 61 5e 10 f0 	movl   $0xf0105e61,(%esp)
f0100fd7:	e8 da f0 ff ff       	call   f01000b6 <_panic>
		return (pte_t*)page2kva(newpg) + PTX(va);
f0100fdc:	c1 ee 0a             	shr    $0xa,%esi
f0100fdf:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100fe5:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100fec:	eb 0c                	jmp    f0100ffa <pgdir_walk+0xe8>
		return (pte_t*)pt + PTX(va);
	}
	else
	{
		if (create == 0)
			return NULL;
f0100fee:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ff3:	eb 05                	jmp    f0100ffa <pgdir_walk+0xe8>
		struct PageInfo *newpg = page_alloc(1);
		if (newpg == NULL)
			return NULL;
f0100ff5:	b8 00 00 00 00       	mov    $0x0,%eax
		newpg->pp_ref++;
		*pdentry = page2pa(newpg) | PTE_W | PTE_P | PTE_U;
		return (pte_t*)page2kva(newpg) + PTX(va);
	}
}
f0100ffa:	83 c4 10             	add    $0x10,%esp
f0100ffd:	5b                   	pop    %ebx
f0100ffe:	5e                   	pop    %esi
f0100fff:	5d                   	pop    %ebp
f0101000:	c3                   	ret    

f0101001 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101001:	55                   	push   %ebp
f0101002:	89 e5                	mov    %esp,%ebp
f0101004:	57                   	push   %edi
f0101005:	56                   	push   %esi
f0101006:	53                   	push   %ebx
f0101007:	83 ec 2c             	sub    $0x2c,%esp
f010100a:	89 c7                	mov    %eax,%edi
f010100c:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010100f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	for (size_t bytes = 0; bytes < size; bytes+=PGSIZE, pa+=PGSIZE, va+=PGSIZE)
f0101012:	bb 00 00 00 00       	mov    $0x0,%ebx
	{
		pte_t *ptentry = pgdir_walk(pgdir, (void*)va, 1);
		*ptentry = (pa | perm | PTE_P);
f0101017:	8b 45 0c             	mov    0xc(%ebp),%eax
f010101a:	83 c8 01             	or     $0x1,%eax
f010101d:	89 45 dc             	mov    %eax,-0x24(%ebp)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	for (size_t bytes = 0; bytes < size; bytes+=PGSIZE, pa+=PGSIZE, va+=PGSIZE)
f0101020:	eb 24                	jmp    f0101046 <boot_map_region+0x45>
	{
		pte_t *ptentry = pgdir_walk(pgdir, (void*)va, 1);
f0101022:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101029:	00 
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f010102a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010102d:	01 d8                	add    %ebx,%eax
{
	// Fill this function in
	for (size_t bytes = 0; bytes < size; bytes+=PGSIZE, pa+=PGSIZE, va+=PGSIZE)
	{
		pte_t *ptentry = pgdir_walk(pgdir, (void*)va, 1);
f010102f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101033:	89 3c 24             	mov    %edi,(%esp)
f0101036:	e8 d7 fe ff ff       	call   f0100f12 <pgdir_walk>
		*ptentry = (pa | perm | PTE_P);
f010103b:	0b 75 dc             	or     -0x24(%ebp),%esi
f010103e:	89 30                	mov    %esi,(%eax)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	for (size_t bytes = 0; bytes < size; bytes+=PGSIZE, pa+=PGSIZE, va+=PGSIZE)
f0101040:	81 c3 00 10 00 00    	add    $0x1000,%ebx
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f0101046:	8b 75 08             	mov    0x8(%ebp),%esi
f0101049:	01 de                	add    %ebx,%esi
{
	// Fill this function in
	for (size_t bytes = 0; bytes < size; bytes+=PGSIZE, pa+=PGSIZE, va+=PGSIZE)
f010104b:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f010104e:	72 d2                	jb     f0101022 <boot_map_region+0x21>
	{
		pte_t *ptentry = pgdir_walk(pgdir, (void*)va, 1);
		*ptentry = (pa | perm | PTE_P);
	}
}
f0101050:	83 c4 2c             	add    $0x2c,%esp
f0101053:	5b                   	pop    %ebx
f0101054:	5e                   	pop    %esi
f0101055:	5f                   	pop    %edi
f0101056:	5d                   	pop    %ebp
f0101057:	c3                   	ret    

f0101058 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101058:	55                   	push   %ebp
f0101059:	89 e5                	mov    %esp,%ebp
f010105b:	53                   	push   %ebx
f010105c:	83 ec 14             	sub    $0x14,%esp
f010105f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, (void*)va, 0);
f0101062:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101069:	00 
f010106a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010106d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101071:	8b 45 08             	mov    0x8(%ebp),%eax
f0101074:	89 04 24             	mov    %eax,(%esp)
f0101077:	e8 96 fe ff ff       	call   f0100f12 <pgdir_walk>
	if (pte_store)
f010107c:	85 db                	test   %ebx,%ebx
f010107e:	74 02                	je     f0101082 <page_lookup+0x2a>
		*pte_store = pte;
f0101080:	89 03                	mov    %eax,(%ebx)
	if (pte && (*pte & PTE_P))
f0101082:	85 c0                	test   %eax,%eax
f0101084:	74 38                	je     f01010be <page_lookup+0x66>
f0101086:	8b 00                	mov    (%eax),%eax
f0101088:	a8 01                	test   $0x1,%al
f010108a:	74 39                	je     f01010c5 <page_lookup+0x6d>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010108c:	c1 e8 0c             	shr    $0xc,%eax
f010108f:	3b 05 24 ec 17 f0    	cmp    0xf017ec24,%eax
f0101095:	72 1c                	jb     f01010b3 <page_lookup+0x5b>
		panic("pa2page called with invalid pa");
f0101097:	c7 44 24 08 94 57 10 	movl   $0xf0105794,0x8(%esp)
f010109e:	f0 
f010109f:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f01010a6:	00 
f01010a7:	c7 04 24 61 5e 10 f0 	movl   $0xf0105e61,(%esp)
f01010ae:	e8 03 f0 ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f01010b3:	c1 e0 03             	shl    $0x3,%eax
f01010b6:	03 05 2c ec 17 f0    	add    0xf017ec2c,%eax
		return pa2page(PTE_ADDR(*pte));
f01010bc:	eb 0c                	jmp    f01010ca <page_lookup+0x72>
	return NULL;
f01010be:	b8 00 00 00 00       	mov    $0x0,%eax
f01010c3:	eb 05                	jmp    f01010ca <page_lookup+0x72>
f01010c5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01010ca:	83 c4 14             	add    $0x14,%esp
f01010cd:	5b                   	pop    %ebx
f01010ce:	5d                   	pop    %ebp
f01010cf:	c3                   	ret    

f01010d0 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01010d0:	55                   	push   %ebp
f01010d1:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01010d3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010d6:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01010d9:	5d                   	pop    %ebp
f01010da:	c3                   	ret    

f01010db <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01010db:	55                   	push   %ebp
f01010dc:	89 e5                	mov    %esp,%ebp
f01010de:	83 ec 28             	sub    $0x28,%esp
f01010e1:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f01010e4:	89 75 fc             	mov    %esi,-0x4(%ebp)
f01010e7:	8b 75 08             	mov    0x8(%ebp),%esi
f01010ea:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	struct PageInfo *oldpg = page_lookup(pgdir, va, &pte);
f01010ed:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01010f0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01010f4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010f8:	89 34 24             	mov    %esi,(%esp)
f01010fb:	e8 58 ff ff ff       	call   f0101058 <page_lookup>
	if (oldpg)
f0101100:	85 c0                	test   %eax,%eax
f0101102:	74 1d                	je     f0101121 <page_remove+0x46>
	{
		page_decref(oldpg);
f0101104:	89 04 24             	mov    %eax,(%esp)
f0101107:	e8 e3 fd ff ff       	call   f0100eef <page_decref>
		*pte = 0;
f010110c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010110f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		tlb_invalidate(pgdir, va);
f0101115:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101119:	89 34 24             	mov    %esi,(%esp)
f010111c:	e8 af ff ff ff       	call   f01010d0 <tlb_invalidate>
	}
}
f0101121:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0101124:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0101127:	89 ec                	mov    %ebp,%esp
f0101129:	5d                   	pop    %ebp
f010112a:	c3                   	ret    

f010112b <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010112b:	55                   	push   %ebp
f010112c:	89 e5                	mov    %esp,%ebp
f010112e:	83 ec 28             	sub    $0x28,%esp
f0101131:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0101134:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101137:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010113a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010113d:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *ptentry = pgdir_walk(pgdir, (void*)va, 1);
f0101140:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101147:	00 
f0101148:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010114c:	8b 45 08             	mov    0x8(%ebp),%eax
f010114f:	89 04 24             	mov    %eax,(%esp)
f0101152:	e8 bb fd ff ff       	call   f0100f12 <pgdir_walk>
f0101157:	89 c3                	mov    %eax,%ebx
	if (ptentry == NULL)
f0101159:	85 c0                	test   %eax,%eax
f010115b:	74 66                	je     f01011c3 <page_insert+0x98>
		return -E_NO_MEM;
	if (*ptentry & PTE_P)
f010115d:	8b 00                	mov    (%eax),%eax
f010115f:	a8 01                	test   $0x1,%al
f0101161:	74 3c                	je     f010119f <page_insert+0x74>
	{
		if (PTE_ADDR(*ptentry) == page2pa(pp))
f0101163:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101168:	89 f2                	mov    %esi,%edx
f010116a:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f0101170:	c1 fa 03             	sar    $0x3,%edx
f0101173:	c1 e2 0c             	shl    $0xc,%edx
f0101176:	39 d0                	cmp    %edx,%eax
f0101178:	75 16                	jne    f0101190 <page_insert+0x65>
		{
			tlb_invalidate(pgdir, va);
f010117a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010117e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101181:	89 04 24             	mov    %eax,(%esp)
f0101184:	e8 47 ff ff ff       	call   f01010d0 <tlb_invalidate>
			pp->pp_ref--;
f0101189:	66 83 6e 04 01       	subw   $0x1,0x4(%esi)
f010118e:	eb 0f                	jmp    f010119f <page_insert+0x74>
		}
		else
			page_remove(pgdir, va);
f0101190:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101194:	8b 45 08             	mov    0x8(%ebp),%eax
f0101197:	89 04 24             	mov    %eax,(%esp)
f010119a:	e8 3c ff ff ff       	call   f01010db <page_remove>
	}
	*ptentry = page2pa(pp) | perm | PTE_P;
f010119f:	8b 45 14             	mov    0x14(%ebp),%eax
f01011a2:	83 c8 01             	or     $0x1,%eax
f01011a5:	89 f2                	mov    %esi,%edx
f01011a7:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f01011ad:	c1 fa 03             	sar    $0x3,%edx
f01011b0:	c1 e2 0c             	shl    $0xc,%edx
f01011b3:	09 d0                	or     %edx,%eax
f01011b5:	89 03                	mov    %eax,(%ebx)
	pp->pp_ref++;
f01011b7:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	return 0;
f01011bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01011c1:	eb 05                	jmp    f01011c8 <page_insert+0x9d>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t *ptentry = pgdir_walk(pgdir, (void*)va, 1);
	if (ptentry == NULL)
		return -E_NO_MEM;
f01011c3:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
			page_remove(pgdir, va);
	}
	*ptentry = page2pa(pp) | perm | PTE_P;
	pp->pp_ref++;
	return 0;
}
f01011c8:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01011cb:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01011ce:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01011d1:	89 ec                	mov    %ebp,%esp
f01011d3:	5d                   	pop    %ebp
f01011d4:	c3                   	ret    

f01011d5 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01011d5:	55                   	push   %ebp
f01011d6:	89 e5                	mov    %esp,%ebp
f01011d8:	57                   	push   %edi
f01011d9:	56                   	push   %esi
f01011da:	53                   	push   %ebx
f01011db:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f01011de:	b8 15 00 00 00       	mov    $0x15,%eax
f01011e3:	e8 2e f8 ff ff       	call   f0100a16 <nvram_read>
f01011e8:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01011ea:	b8 17 00 00 00       	mov    $0x17,%eax
f01011ef:	e8 22 f8 ff ff       	call   f0100a16 <nvram_read>
f01011f4:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01011f6:	b8 34 00 00 00       	mov    $0x34,%eax
f01011fb:	e8 16 f8 ff ff       	call   f0100a16 <nvram_read>
f0101200:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0101203:	85 c0                	test   %eax,%eax
f0101205:	74 07                	je     f010120e <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0101207:	05 00 40 00 00       	add    $0x4000,%eax
f010120c:	eb 0b                	jmp    f0101219 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f010120e:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101214:	85 f6                	test   %esi,%esi
f0101216:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0101219:	89 c2                	mov    %eax,%edx
f010121b:	c1 ea 02             	shr    $0x2,%edx
f010121e:	89 15 24 ec 17 f0    	mov    %edx,0xf017ec24
	npages_basemem = basemem / (PGSIZE / 1024);
f0101224:	89 da                	mov    %ebx,%edx
f0101226:	c1 ea 02             	shr    $0x2,%edx
f0101229:	89 15 78 df 17 f0    	mov    %edx,0xf017df78

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010122f:	89 c2                	mov    %eax,%edx
f0101231:	29 da                	sub    %ebx,%edx
f0101233:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101237:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010123b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010123f:	c7 04 24 b4 57 10 f0 	movl   $0xf01057b4,(%esp)
f0101246:	e8 db 24 00 00       	call   f0103726 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010124b:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101250:	e8 54 f7 ff ff       	call   f01009a9 <boot_alloc>
f0101255:	a3 28 ec 17 f0       	mov    %eax,0xf017ec28
	memset(kern_pgdir, 0, PGSIZE);
f010125a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101261:	00 
f0101262:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101269:	00 
f010126a:	89 04 24             	mov    %eax,(%esp)
f010126d:	e8 d1 39 00 00       	call   f0104c43 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101272:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101277:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010127c:	77 20                	ja     f010129e <mem_init+0xc9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010127e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101282:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f0101289:	f0 
f010128a:	c7 44 24 04 95 00 00 	movl   $0x95,0x4(%esp)
f0101291:	00 
f0101292:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101299:	e8 18 ee ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010129e:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01012a4:	83 ca 05             	or     $0x5,%edx
f01012a7:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*)boot_alloc(npages*sizeof(struct PageInfo));
f01012ad:	a1 24 ec 17 f0       	mov    0xf017ec24,%eax
f01012b2:	c1 e0 03             	shl    $0x3,%eax
f01012b5:	e8 ef f6 ff ff       	call   f01009a9 <boot_alloc>
f01012ba:	a3 2c ec 17 f0       	mov    %eax,0xf017ec2c
	memset(pages, 0, npages*sizeof(struct PageInfo));
f01012bf:	8b 15 24 ec 17 f0    	mov    0xf017ec24,%edx
f01012c5:	c1 e2 03             	shl    $0x3,%edx
f01012c8:	89 54 24 08          	mov    %edx,0x8(%esp)
f01012cc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01012d3:	00 
f01012d4:	89 04 24             	mov    %eax,(%esp)
f01012d7:	e8 67 39 00 00       	call   f0104c43 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*)boot_alloc(NENV*sizeof(struct Env));
f01012dc:	b8 00 80 01 00       	mov    $0x18000,%eax
f01012e1:	e8 c3 f6 ff ff       	call   f01009a9 <boot_alloc>
f01012e6:	a3 8c df 17 f0       	mov    %eax,0xf017df8c
	memset(envs, 0, NENV*sizeof(struct Env));
f01012eb:	c7 44 24 08 00 80 01 	movl   $0x18000,0x8(%esp)
f01012f2:	00 
f01012f3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01012fa:	00 
f01012fb:	89 04 24             	mov    %eax,(%esp)
f01012fe:	e8 40 39 00 00       	call   f0104c43 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101303:	e8 74 fa ff ff       	call   f0100d7c <page_init>

	check_page_free_list(1);
f0101308:	b8 01 00 00 00       	mov    $0x1,%eax
f010130d:	e8 36 f7 ff ff       	call   f0100a48 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101312:	83 3d 2c ec 17 f0 00 	cmpl   $0x0,0xf017ec2c
f0101319:	75 1c                	jne    f0101337 <mem_init+0x162>
		panic("'pages' is a null pointer!");
f010131b:	c7 44 24 08 20 5f 10 	movl   $0xf0105f20,0x8(%esp)
f0101322:	f0 
f0101323:	c7 44 24 04 a6 02 00 	movl   $0x2a6,0x4(%esp)
f010132a:	00 
f010132b:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101332:	e8 7f ed ff ff       	call   f01000b6 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101337:	a1 80 df 17 f0       	mov    0xf017df80,%eax
f010133c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101341:	eb 05                	jmp    f0101348 <mem_init+0x173>
		++nfree;
f0101343:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101346:	8b 00                	mov    (%eax),%eax
f0101348:	85 c0                	test   %eax,%eax
f010134a:	75 f7                	jne    f0101343 <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010134c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101353:	e8 d3 fa ff ff       	call   f0100e2b <page_alloc>
f0101358:	89 c6                	mov    %eax,%esi
f010135a:	85 c0                	test   %eax,%eax
f010135c:	75 24                	jne    f0101382 <mem_init+0x1ad>
f010135e:	c7 44 24 0c 3b 5f 10 	movl   $0xf0105f3b,0xc(%esp)
f0101365:	f0 
f0101366:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f010136d:	f0 
f010136e:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f0101375:	00 
f0101376:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f010137d:	e8 34 ed ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101382:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101389:	e8 9d fa ff ff       	call   f0100e2b <page_alloc>
f010138e:	89 c7                	mov    %eax,%edi
f0101390:	85 c0                	test   %eax,%eax
f0101392:	75 24                	jne    f01013b8 <mem_init+0x1e3>
f0101394:	c7 44 24 0c 51 5f 10 	movl   $0xf0105f51,0xc(%esp)
f010139b:	f0 
f010139c:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f01013a3:	f0 
f01013a4:	c7 44 24 04 af 02 00 	movl   $0x2af,0x4(%esp)
f01013ab:	00 
f01013ac:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01013b3:	e8 fe ec ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f01013b8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013bf:	e8 67 fa ff ff       	call   f0100e2b <page_alloc>
f01013c4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013c7:	85 c0                	test   %eax,%eax
f01013c9:	75 24                	jne    f01013ef <mem_init+0x21a>
f01013cb:	c7 44 24 0c 67 5f 10 	movl   $0xf0105f67,0xc(%esp)
f01013d2:	f0 
f01013d3:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f01013da:	f0 
f01013db:	c7 44 24 04 b0 02 00 	movl   $0x2b0,0x4(%esp)
f01013e2:	00 
f01013e3:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01013ea:	e8 c7 ec ff ff       	call   f01000b6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013ef:	39 fe                	cmp    %edi,%esi
f01013f1:	75 24                	jne    f0101417 <mem_init+0x242>
f01013f3:	c7 44 24 0c 7d 5f 10 	movl   $0xf0105f7d,0xc(%esp)
f01013fa:	f0 
f01013fb:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101402:	f0 
f0101403:	c7 44 24 04 b3 02 00 	movl   $0x2b3,0x4(%esp)
f010140a:	00 
f010140b:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101412:	e8 9f ec ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101417:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f010141a:	74 05                	je     f0101421 <mem_init+0x24c>
f010141c:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010141f:	75 24                	jne    f0101445 <mem_init+0x270>
f0101421:	c7 44 24 0c f0 57 10 	movl   $0xf01057f0,0xc(%esp)
f0101428:	f0 
f0101429:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101430:	f0 
f0101431:	c7 44 24 04 b4 02 00 	movl   $0x2b4,0x4(%esp)
f0101438:	00 
f0101439:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101440:	e8 71 ec ff ff       	call   f01000b6 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101445:	8b 15 2c ec 17 f0    	mov    0xf017ec2c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f010144b:	a1 24 ec 17 f0       	mov    0xf017ec24,%eax
f0101450:	c1 e0 0c             	shl    $0xc,%eax
f0101453:	89 f1                	mov    %esi,%ecx
f0101455:	29 d1                	sub    %edx,%ecx
f0101457:	c1 f9 03             	sar    $0x3,%ecx
f010145a:	c1 e1 0c             	shl    $0xc,%ecx
f010145d:	39 c1                	cmp    %eax,%ecx
f010145f:	72 24                	jb     f0101485 <mem_init+0x2b0>
f0101461:	c7 44 24 0c 8f 5f 10 	movl   $0xf0105f8f,0xc(%esp)
f0101468:	f0 
f0101469:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101470:	f0 
f0101471:	c7 44 24 04 b5 02 00 	movl   $0x2b5,0x4(%esp)
f0101478:	00 
f0101479:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101480:	e8 31 ec ff ff       	call   f01000b6 <_panic>
f0101485:	89 f9                	mov    %edi,%ecx
f0101487:	29 d1                	sub    %edx,%ecx
f0101489:	c1 f9 03             	sar    $0x3,%ecx
f010148c:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f010148f:	39 c8                	cmp    %ecx,%eax
f0101491:	77 24                	ja     f01014b7 <mem_init+0x2e2>
f0101493:	c7 44 24 0c ac 5f 10 	movl   $0xf0105fac,0xc(%esp)
f010149a:	f0 
f010149b:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f01014a2:	f0 
f01014a3:	c7 44 24 04 b6 02 00 	movl   $0x2b6,0x4(%esp)
f01014aa:	00 
f01014ab:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01014b2:	e8 ff eb ff ff       	call   f01000b6 <_panic>
f01014b7:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01014ba:	29 d1                	sub    %edx,%ecx
f01014bc:	89 ca                	mov    %ecx,%edx
f01014be:	c1 fa 03             	sar    $0x3,%edx
f01014c1:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01014c4:	39 d0                	cmp    %edx,%eax
f01014c6:	77 24                	ja     f01014ec <mem_init+0x317>
f01014c8:	c7 44 24 0c c9 5f 10 	movl   $0xf0105fc9,0xc(%esp)
f01014cf:	f0 
f01014d0:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f01014d7:	f0 
f01014d8:	c7 44 24 04 b7 02 00 	movl   $0x2b7,0x4(%esp)
f01014df:	00 
f01014e0:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01014e7:	e8 ca eb ff ff       	call   f01000b6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01014ec:	a1 80 df 17 f0       	mov    0xf017df80,%eax
f01014f1:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01014f4:	c7 05 80 df 17 f0 00 	movl   $0x0,0xf017df80
f01014fb:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01014fe:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101505:	e8 21 f9 ff ff       	call   f0100e2b <page_alloc>
f010150a:	85 c0                	test   %eax,%eax
f010150c:	74 24                	je     f0101532 <mem_init+0x35d>
f010150e:	c7 44 24 0c e6 5f 10 	movl   $0xf0105fe6,0xc(%esp)
f0101515:	f0 
f0101516:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f010151d:	f0 
f010151e:	c7 44 24 04 be 02 00 	movl   $0x2be,0x4(%esp)
f0101525:	00 
f0101526:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f010152d:	e8 84 eb ff ff       	call   f01000b6 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101532:	89 34 24             	mov    %esi,(%esp)
f0101535:	e8 75 f9 ff ff       	call   f0100eaf <page_free>
	page_free(pp1);
f010153a:	89 3c 24             	mov    %edi,(%esp)
f010153d:	e8 6d f9 ff ff       	call   f0100eaf <page_free>
	page_free(pp2);
f0101542:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101545:	89 04 24             	mov    %eax,(%esp)
f0101548:	e8 62 f9 ff ff       	call   f0100eaf <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010154d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101554:	e8 d2 f8 ff ff       	call   f0100e2b <page_alloc>
f0101559:	89 c6                	mov    %eax,%esi
f010155b:	85 c0                	test   %eax,%eax
f010155d:	75 24                	jne    f0101583 <mem_init+0x3ae>
f010155f:	c7 44 24 0c 3b 5f 10 	movl   $0xf0105f3b,0xc(%esp)
f0101566:	f0 
f0101567:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f010156e:	f0 
f010156f:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
f0101576:	00 
f0101577:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f010157e:	e8 33 eb ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101583:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010158a:	e8 9c f8 ff ff       	call   f0100e2b <page_alloc>
f010158f:	89 c7                	mov    %eax,%edi
f0101591:	85 c0                	test   %eax,%eax
f0101593:	75 24                	jne    f01015b9 <mem_init+0x3e4>
f0101595:	c7 44 24 0c 51 5f 10 	movl   $0xf0105f51,0xc(%esp)
f010159c:	f0 
f010159d:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f01015a4:	f0 
f01015a5:	c7 44 24 04 c6 02 00 	movl   $0x2c6,0x4(%esp)
f01015ac:	00 
f01015ad:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01015b4:	e8 fd ea ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f01015b9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015c0:	e8 66 f8 ff ff       	call   f0100e2b <page_alloc>
f01015c5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015c8:	85 c0                	test   %eax,%eax
f01015ca:	75 24                	jne    f01015f0 <mem_init+0x41b>
f01015cc:	c7 44 24 0c 67 5f 10 	movl   $0xf0105f67,0xc(%esp)
f01015d3:	f0 
f01015d4:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f01015db:	f0 
f01015dc:	c7 44 24 04 c7 02 00 	movl   $0x2c7,0x4(%esp)
f01015e3:	00 
f01015e4:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01015eb:	e8 c6 ea ff ff       	call   f01000b6 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015f0:	39 fe                	cmp    %edi,%esi
f01015f2:	75 24                	jne    f0101618 <mem_init+0x443>
f01015f4:	c7 44 24 0c 7d 5f 10 	movl   $0xf0105f7d,0xc(%esp)
f01015fb:	f0 
f01015fc:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101603:	f0 
f0101604:	c7 44 24 04 c9 02 00 	movl   $0x2c9,0x4(%esp)
f010160b:	00 
f010160c:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101613:	e8 9e ea ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101618:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f010161b:	74 05                	je     f0101622 <mem_init+0x44d>
f010161d:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101620:	75 24                	jne    f0101646 <mem_init+0x471>
f0101622:	c7 44 24 0c f0 57 10 	movl   $0xf01057f0,0xc(%esp)
f0101629:	f0 
f010162a:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101631:	f0 
f0101632:	c7 44 24 04 ca 02 00 	movl   $0x2ca,0x4(%esp)
f0101639:	00 
f010163a:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101641:	e8 70 ea ff ff       	call   f01000b6 <_panic>
	assert(!page_alloc(0));
f0101646:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010164d:	e8 d9 f7 ff ff       	call   f0100e2b <page_alloc>
f0101652:	85 c0                	test   %eax,%eax
f0101654:	74 24                	je     f010167a <mem_init+0x4a5>
f0101656:	c7 44 24 0c e6 5f 10 	movl   $0xf0105fe6,0xc(%esp)
f010165d:	f0 
f010165e:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101665:	f0 
f0101666:	c7 44 24 04 cb 02 00 	movl   $0x2cb,0x4(%esp)
f010166d:	00 
f010166e:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101675:	e8 3c ea ff ff       	call   f01000b6 <_panic>
f010167a:	89 f0                	mov    %esi,%eax
f010167c:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0101682:	c1 f8 03             	sar    $0x3,%eax
f0101685:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101688:	89 c2                	mov    %eax,%edx
f010168a:	c1 ea 0c             	shr    $0xc,%edx
f010168d:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0101693:	72 20                	jb     f01016b5 <mem_init+0x4e0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101695:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101699:	c7 44 24 08 64 56 10 	movl   $0xf0105664,0x8(%esp)
f01016a0:	f0 
f01016a1:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01016a8:	00 
f01016a9:	c7 04 24 61 5e 10 f0 	movl   $0xf0105e61,(%esp)
f01016b0:	e8 01 ea ff ff       	call   f01000b6 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01016b5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01016bc:	00 
f01016bd:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01016c4:	00 
	return (void *)(pa + KERNBASE);
f01016c5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01016ca:	89 04 24             	mov    %eax,(%esp)
f01016cd:	e8 71 35 00 00       	call   f0104c43 <memset>
	page_free(pp0);
f01016d2:	89 34 24             	mov    %esi,(%esp)
f01016d5:	e8 d5 f7 ff ff       	call   f0100eaf <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016da:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016e1:	e8 45 f7 ff ff       	call   f0100e2b <page_alloc>
f01016e6:	85 c0                	test   %eax,%eax
f01016e8:	75 24                	jne    f010170e <mem_init+0x539>
f01016ea:	c7 44 24 0c f5 5f 10 	movl   $0xf0105ff5,0xc(%esp)
f01016f1:	f0 
f01016f2:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f01016f9:	f0 
f01016fa:	c7 44 24 04 d0 02 00 	movl   $0x2d0,0x4(%esp)
f0101701:	00 
f0101702:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101709:	e8 a8 e9 ff ff       	call   f01000b6 <_panic>
	assert(pp && pp0 == pp);
f010170e:	39 c6                	cmp    %eax,%esi
f0101710:	74 24                	je     f0101736 <mem_init+0x561>
f0101712:	c7 44 24 0c 13 60 10 	movl   $0xf0106013,0xc(%esp)
f0101719:	f0 
f010171a:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101721:	f0 
f0101722:	c7 44 24 04 d1 02 00 	movl   $0x2d1,0x4(%esp)
f0101729:	00 
f010172a:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101731:	e8 80 e9 ff ff       	call   f01000b6 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101736:	89 f2                	mov    %esi,%edx
f0101738:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f010173e:	c1 fa 03             	sar    $0x3,%edx
f0101741:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101744:	89 d0                	mov    %edx,%eax
f0101746:	c1 e8 0c             	shr    $0xc,%eax
f0101749:	3b 05 24 ec 17 f0    	cmp    0xf017ec24,%eax
f010174f:	72 20                	jb     f0101771 <mem_init+0x59c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101751:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101755:	c7 44 24 08 64 56 10 	movl   $0xf0105664,0x8(%esp)
f010175c:	f0 
f010175d:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101764:	00 
f0101765:	c7 04 24 61 5e 10 f0 	movl   $0xf0105e61,(%esp)
f010176c:	e8 45 e9 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0101771:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
// will be set up later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0101777:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010177d:	80 38 00             	cmpb   $0x0,(%eax)
f0101780:	74 24                	je     f01017a6 <mem_init+0x5d1>
f0101782:	c7 44 24 0c 23 60 10 	movl   $0xf0106023,0xc(%esp)
f0101789:	f0 
f010178a:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101791:	f0 
f0101792:	c7 44 24 04 d4 02 00 	movl   $0x2d4,0x4(%esp)
f0101799:	00 
f010179a:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01017a1:	e8 10 e9 ff ff       	call   f01000b6 <_panic>
f01017a6:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01017a9:	39 d0                	cmp    %edx,%eax
f01017ab:	75 d0                	jne    f010177d <mem_init+0x5a8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01017ad:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01017b0:	89 15 80 df 17 f0    	mov    %edx,0xf017df80

	// free the pages we took
	page_free(pp0);
f01017b6:	89 34 24             	mov    %esi,(%esp)
f01017b9:	e8 f1 f6 ff ff       	call   f0100eaf <page_free>
	page_free(pp1);
f01017be:	89 3c 24             	mov    %edi,(%esp)
f01017c1:	e8 e9 f6 ff ff       	call   f0100eaf <page_free>
	page_free(pp2);
f01017c6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017c9:	89 04 24             	mov    %eax,(%esp)
f01017cc:	e8 de f6 ff ff       	call   f0100eaf <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017d1:	a1 80 df 17 f0       	mov    0xf017df80,%eax
f01017d6:	eb 05                	jmp    f01017dd <mem_init+0x608>
		--nfree;
f01017d8:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017db:	8b 00                	mov    (%eax),%eax
f01017dd:	85 c0                	test   %eax,%eax
f01017df:	75 f7                	jne    f01017d8 <mem_init+0x603>
		--nfree;
	assert(nfree == 0);
f01017e1:	85 db                	test   %ebx,%ebx
f01017e3:	74 24                	je     f0101809 <mem_init+0x634>
f01017e5:	c7 44 24 0c 2d 60 10 	movl   $0xf010602d,0xc(%esp)
f01017ec:	f0 
f01017ed:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f01017f4:	f0 
f01017f5:	c7 44 24 04 e1 02 00 	movl   $0x2e1,0x4(%esp)
f01017fc:	00 
f01017fd:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101804:	e8 ad e8 ff ff       	call   f01000b6 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101809:	c7 04 24 10 58 10 f0 	movl   $0xf0105810,(%esp)
f0101810:	e8 11 1f 00 00       	call   f0103726 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101815:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010181c:	e8 0a f6 ff ff       	call   f0100e2b <page_alloc>
f0101821:	89 c7                	mov    %eax,%edi
f0101823:	85 c0                	test   %eax,%eax
f0101825:	75 24                	jne    f010184b <mem_init+0x676>
f0101827:	c7 44 24 0c 3b 5f 10 	movl   $0xf0105f3b,0xc(%esp)
f010182e:	f0 
f010182f:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101836:	f0 
f0101837:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f010183e:	00 
f010183f:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101846:	e8 6b e8 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f010184b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101852:	e8 d4 f5 ff ff       	call   f0100e2b <page_alloc>
f0101857:	89 c6                	mov    %eax,%esi
f0101859:	85 c0                	test   %eax,%eax
f010185b:	75 24                	jne    f0101881 <mem_init+0x6ac>
f010185d:	c7 44 24 0c 51 5f 10 	movl   $0xf0105f51,0xc(%esp)
f0101864:	f0 
f0101865:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f010186c:	f0 
f010186d:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0101874:	00 
f0101875:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f010187c:	e8 35 e8 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0101881:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101888:	e8 9e f5 ff ff       	call   f0100e2b <page_alloc>
f010188d:	89 c3                	mov    %eax,%ebx
f010188f:	85 c0                	test   %eax,%eax
f0101891:	75 24                	jne    f01018b7 <mem_init+0x6e2>
f0101893:	c7 44 24 0c 67 5f 10 	movl   $0xf0105f67,0xc(%esp)
f010189a:	f0 
f010189b:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f01018a2:	f0 
f01018a3:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f01018aa:	00 
f01018ab:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01018b2:	e8 ff e7 ff ff       	call   f01000b6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018b7:	39 f7                	cmp    %esi,%edi
f01018b9:	75 24                	jne    f01018df <mem_init+0x70a>
f01018bb:	c7 44 24 0c 7d 5f 10 	movl   $0xf0105f7d,0xc(%esp)
f01018c2:	f0 
f01018c3:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f01018ca:	f0 
f01018cb:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f01018d2:	00 
f01018d3:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01018da:	e8 d7 e7 ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018df:	39 c6                	cmp    %eax,%esi
f01018e1:	74 04                	je     f01018e7 <mem_init+0x712>
f01018e3:	39 c7                	cmp    %eax,%edi
f01018e5:	75 24                	jne    f010190b <mem_init+0x736>
f01018e7:	c7 44 24 0c f0 57 10 	movl   $0xf01057f0,0xc(%esp)
f01018ee:	f0 
f01018ef:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f01018f6:	f0 
f01018f7:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
f01018fe:	00 
f01018ff:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101906:	e8 ab e7 ff ff       	call   f01000b6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010190b:	8b 15 80 df 17 f0    	mov    0xf017df80,%edx
f0101911:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f0101914:	c7 05 80 df 17 f0 00 	movl   $0x0,0xf017df80
f010191b:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010191e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101925:	e8 01 f5 ff ff       	call   f0100e2b <page_alloc>
f010192a:	85 c0                	test   %eax,%eax
f010192c:	74 24                	je     f0101952 <mem_init+0x77d>
f010192e:	c7 44 24 0c e6 5f 10 	movl   $0xf0105fe6,0xc(%esp)
f0101935:	f0 
f0101936:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f010193d:	f0 
f010193e:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0101945:	00 
f0101946:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f010194d:	e8 64 e7 ff ff       	call   f01000b6 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101952:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101955:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101959:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101960:	00 
f0101961:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101966:	89 04 24             	mov    %eax,(%esp)
f0101969:	e8 ea f6 ff ff       	call   f0101058 <page_lookup>
f010196e:	85 c0                	test   %eax,%eax
f0101970:	74 24                	je     f0101996 <mem_init+0x7c1>
f0101972:	c7 44 24 0c 30 58 10 	movl   $0xf0105830,0xc(%esp)
f0101979:	f0 
f010197a:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101981:	f0 
f0101982:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f0101989:	00 
f010198a:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101991:	e8 20 e7 ff ff       	call   f01000b6 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101996:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010199d:	00 
f010199e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01019a5:	00 
f01019a6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01019aa:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f01019af:	89 04 24             	mov    %eax,(%esp)
f01019b2:	e8 74 f7 ff ff       	call   f010112b <page_insert>
f01019b7:	85 c0                	test   %eax,%eax
f01019b9:	78 24                	js     f01019df <mem_init+0x80a>
f01019bb:	c7 44 24 0c 68 58 10 	movl   $0xf0105868,0xc(%esp)
f01019c2:	f0 
f01019c3:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f01019ca:	f0 
f01019cb:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f01019d2:	00 
f01019d3:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01019da:	e8 d7 e6 ff ff       	call   f01000b6 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019df:	89 3c 24             	mov    %edi,(%esp)
f01019e2:	e8 c8 f4 ff ff       	call   f0100eaf <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019e7:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01019ee:	00 
f01019ef:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01019f6:	00 
f01019f7:	89 74 24 04          	mov    %esi,0x4(%esp)
f01019fb:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101a00:	89 04 24             	mov    %eax,(%esp)
f0101a03:	e8 23 f7 ff ff       	call   f010112b <page_insert>
f0101a08:	85 c0                	test   %eax,%eax
f0101a0a:	74 24                	je     f0101a30 <mem_init+0x85b>
f0101a0c:	c7 44 24 0c 98 58 10 	movl   $0xf0105898,0xc(%esp)
f0101a13:	f0 
f0101a14:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101a1b:	f0 
f0101a1c:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f0101a23:	00 
f0101a24:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101a2b:	e8 86 e6 ff ff       	call   f01000b6 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a30:	8b 0d 28 ec 17 f0    	mov    0xf017ec28,%ecx
f0101a36:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a39:	a1 2c ec 17 f0       	mov    0xf017ec2c,%eax
f0101a3e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101a41:	8b 11                	mov    (%ecx),%edx
f0101a43:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a49:	89 f8                	mov    %edi,%eax
f0101a4b:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101a4e:	c1 f8 03             	sar    $0x3,%eax
f0101a51:	c1 e0 0c             	shl    $0xc,%eax
f0101a54:	39 c2                	cmp    %eax,%edx
f0101a56:	74 24                	je     f0101a7c <mem_init+0x8a7>
f0101a58:	c7 44 24 0c c8 58 10 	movl   $0xf01058c8,0xc(%esp)
f0101a5f:	f0 
f0101a60:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101a67:	f0 
f0101a68:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f0101a6f:	00 
f0101a70:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101a77:	e8 3a e6 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a7c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a81:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a84:	e8 af ee ff ff       	call   f0100938 <check_va2pa>
f0101a89:	89 f2                	mov    %esi,%edx
f0101a8b:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101a8e:	c1 fa 03             	sar    $0x3,%edx
f0101a91:	c1 e2 0c             	shl    $0xc,%edx
f0101a94:	39 d0                	cmp    %edx,%eax
f0101a96:	74 24                	je     f0101abc <mem_init+0x8e7>
f0101a98:	c7 44 24 0c f0 58 10 	movl   $0xf01058f0,0xc(%esp)
f0101a9f:	f0 
f0101aa0:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101aa7:	f0 
f0101aa8:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f0101aaf:	00 
f0101ab0:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101ab7:	e8 fa e5 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f0101abc:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ac1:	74 24                	je     f0101ae7 <mem_init+0x912>
f0101ac3:	c7 44 24 0c 38 60 10 	movl   $0xf0106038,0xc(%esp)
f0101aca:	f0 
f0101acb:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101ad2:	f0 
f0101ad3:	c7 44 24 04 59 03 00 	movl   $0x359,0x4(%esp)
f0101ada:	00 
f0101adb:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101ae2:	e8 cf e5 ff ff       	call   f01000b6 <_panic>
	assert(pp0->pp_ref == 1);
f0101ae7:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101aec:	74 24                	je     f0101b12 <mem_init+0x93d>
f0101aee:	c7 44 24 0c 49 60 10 	movl   $0xf0106049,0xc(%esp)
f0101af5:	f0 
f0101af6:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101afd:	f0 
f0101afe:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f0101b05:	00 
f0101b06:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101b0d:	e8 a4 e5 ff ff       	call   f01000b6 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b12:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b19:	00 
f0101b1a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101b21:	00 
f0101b22:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101b26:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101b29:	89 14 24             	mov    %edx,(%esp)
f0101b2c:	e8 fa f5 ff ff       	call   f010112b <page_insert>
f0101b31:	85 c0                	test   %eax,%eax
f0101b33:	74 24                	je     f0101b59 <mem_init+0x984>
f0101b35:	c7 44 24 0c 20 59 10 	movl   $0xf0105920,0xc(%esp)
f0101b3c:	f0 
f0101b3d:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101b44:	f0 
f0101b45:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f0101b4c:	00 
f0101b4d:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101b54:	e8 5d e5 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b59:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b5e:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101b63:	e8 d0 ed ff ff       	call   f0100938 <check_va2pa>
f0101b68:	89 da                	mov    %ebx,%edx
f0101b6a:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f0101b70:	c1 fa 03             	sar    $0x3,%edx
f0101b73:	c1 e2 0c             	shl    $0xc,%edx
f0101b76:	39 d0                	cmp    %edx,%eax
f0101b78:	74 24                	je     f0101b9e <mem_init+0x9c9>
f0101b7a:	c7 44 24 0c 5c 59 10 	movl   $0xf010595c,0xc(%esp)
f0101b81:	f0 
f0101b82:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101b89:	f0 
f0101b8a:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f0101b91:	00 
f0101b92:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101b99:	e8 18 e5 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101b9e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ba3:	74 24                	je     f0101bc9 <mem_init+0x9f4>
f0101ba5:	c7 44 24 0c 5a 60 10 	movl   $0xf010605a,0xc(%esp)
f0101bac:	f0 
f0101bad:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101bb4:	f0 
f0101bb5:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f0101bbc:	00 
f0101bbd:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101bc4:	e8 ed e4 ff ff       	call   f01000b6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101bc9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bd0:	e8 56 f2 ff ff       	call   f0100e2b <page_alloc>
f0101bd5:	85 c0                	test   %eax,%eax
f0101bd7:	74 24                	je     f0101bfd <mem_init+0xa28>
f0101bd9:	c7 44 24 0c e6 5f 10 	movl   $0xf0105fe6,0xc(%esp)
f0101be0:	f0 
f0101be1:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101be8:	f0 
f0101be9:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f0101bf0:	00 
f0101bf1:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101bf8:	e8 b9 e4 ff ff       	call   f01000b6 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bfd:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c04:	00 
f0101c05:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c0c:	00 
f0101c0d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101c11:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101c16:	89 04 24             	mov    %eax,(%esp)
f0101c19:	e8 0d f5 ff ff       	call   f010112b <page_insert>
f0101c1e:	85 c0                	test   %eax,%eax
f0101c20:	74 24                	je     f0101c46 <mem_init+0xa71>
f0101c22:	c7 44 24 0c 20 59 10 	movl   $0xf0105920,0xc(%esp)
f0101c29:	f0 
f0101c2a:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101c31:	f0 
f0101c32:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f0101c39:	00 
f0101c3a:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101c41:	e8 70 e4 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c46:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c4b:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101c50:	e8 e3 ec ff ff       	call   f0100938 <check_va2pa>
f0101c55:	89 da                	mov    %ebx,%edx
f0101c57:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f0101c5d:	c1 fa 03             	sar    $0x3,%edx
f0101c60:	c1 e2 0c             	shl    $0xc,%edx
f0101c63:	39 d0                	cmp    %edx,%eax
f0101c65:	74 24                	je     f0101c8b <mem_init+0xab6>
f0101c67:	c7 44 24 0c 5c 59 10 	movl   $0xf010595c,0xc(%esp)
f0101c6e:	f0 
f0101c6f:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101c76:	f0 
f0101c77:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f0101c7e:	00 
f0101c7f:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101c86:	e8 2b e4 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101c8b:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c90:	74 24                	je     f0101cb6 <mem_init+0xae1>
f0101c92:	c7 44 24 0c 5a 60 10 	movl   $0xf010605a,0xc(%esp)
f0101c99:	f0 
f0101c9a:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101ca1:	f0 
f0101ca2:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f0101ca9:	00 
f0101caa:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101cb1:	e8 00 e4 ff ff       	call   f01000b6 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101cb6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101cbd:	e8 69 f1 ff ff       	call   f0100e2b <page_alloc>
f0101cc2:	85 c0                	test   %eax,%eax
f0101cc4:	74 24                	je     f0101cea <mem_init+0xb15>
f0101cc6:	c7 44 24 0c e6 5f 10 	movl   $0xf0105fe6,0xc(%esp)
f0101ccd:	f0 
f0101cce:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101cd5:	f0 
f0101cd6:	c7 44 24 04 6b 03 00 	movl   $0x36b,0x4(%esp)
f0101cdd:	00 
f0101cde:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101ce5:	e8 cc e3 ff ff       	call   f01000b6 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101cea:	8b 15 28 ec 17 f0    	mov    0xf017ec28,%edx
f0101cf0:	8b 02                	mov    (%edx),%eax
f0101cf2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101cf7:	89 c1                	mov    %eax,%ecx
f0101cf9:	c1 e9 0c             	shr    $0xc,%ecx
f0101cfc:	3b 0d 24 ec 17 f0    	cmp    0xf017ec24,%ecx
f0101d02:	72 20                	jb     f0101d24 <mem_init+0xb4f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d04:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101d08:	c7 44 24 08 64 56 10 	movl   $0xf0105664,0x8(%esp)
f0101d0f:	f0 
f0101d10:	c7 44 24 04 6e 03 00 	movl   $0x36e,0x4(%esp)
f0101d17:	00 
f0101d18:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101d1f:	e8 92 e3 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0101d24:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d29:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d2c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d33:	00 
f0101d34:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101d3b:	00 
f0101d3c:	89 14 24             	mov    %edx,(%esp)
f0101d3f:	e8 ce f1 ff ff       	call   f0100f12 <pgdir_walk>
f0101d44:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101d47:	83 c2 04             	add    $0x4,%edx
f0101d4a:	39 d0                	cmp    %edx,%eax
f0101d4c:	74 24                	je     f0101d72 <mem_init+0xb9d>
f0101d4e:	c7 44 24 0c 8c 59 10 	movl   $0xf010598c,0xc(%esp)
f0101d55:	f0 
f0101d56:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101d5d:	f0 
f0101d5e:	c7 44 24 04 6f 03 00 	movl   $0x36f,0x4(%esp)
f0101d65:	00 
f0101d66:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101d6d:	e8 44 e3 ff ff       	call   f01000b6 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d72:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101d79:	00 
f0101d7a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d81:	00 
f0101d82:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101d86:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101d8b:	89 04 24             	mov    %eax,(%esp)
f0101d8e:	e8 98 f3 ff ff       	call   f010112b <page_insert>
f0101d93:	85 c0                	test   %eax,%eax
f0101d95:	74 24                	je     f0101dbb <mem_init+0xbe6>
f0101d97:	c7 44 24 0c cc 59 10 	movl   $0xf01059cc,0xc(%esp)
f0101d9e:	f0 
f0101d9f:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101da6:	f0 
f0101da7:	c7 44 24 04 72 03 00 	movl   $0x372,0x4(%esp)
f0101dae:	00 
f0101daf:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101db6:	e8 fb e2 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101dbb:	8b 0d 28 ec 17 f0    	mov    0xf017ec28,%ecx
f0101dc1:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101dc4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dc9:	89 c8                	mov    %ecx,%eax
f0101dcb:	e8 68 eb ff ff       	call   f0100938 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101dd0:	89 da                	mov    %ebx,%edx
f0101dd2:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f0101dd8:	c1 fa 03             	sar    $0x3,%edx
f0101ddb:	c1 e2 0c             	shl    $0xc,%edx
f0101dde:	39 d0                	cmp    %edx,%eax
f0101de0:	74 24                	je     f0101e06 <mem_init+0xc31>
f0101de2:	c7 44 24 0c 5c 59 10 	movl   $0xf010595c,0xc(%esp)
f0101de9:	f0 
f0101dea:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101df1:	f0 
f0101df2:	c7 44 24 04 73 03 00 	movl   $0x373,0x4(%esp)
f0101df9:	00 
f0101dfa:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101e01:	e8 b0 e2 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101e06:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101e0b:	74 24                	je     f0101e31 <mem_init+0xc5c>
f0101e0d:	c7 44 24 0c 5a 60 10 	movl   $0xf010605a,0xc(%esp)
f0101e14:	f0 
f0101e15:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101e1c:	f0 
f0101e1d:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f0101e24:	00 
f0101e25:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101e2c:	e8 85 e2 ff ff       	call   f01000b6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101e31:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e38:	00 
f0101e39:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e40:	00 
f0101e41:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e44:	89 04 24             	mov    %eax,(%esp)
f0101e47:	e8 c6 f0 ff ff       	call   f0100f12 <pgdir_walk>
f0101e4c:	f6 00 04             	testb  $0x4,(%eax)
f0101e4f:	75 24                	jne    f0101e75 <mem_init+0xca0>
f0101e51:	c7 44 24 0c 0c 5a 10 	movl   $0xf0105a0c,0xc(%esp)
f0101e58:	f0 
f0101e59:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101e60:	f0 
f0101e61:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f0101e68:	00 
f0101e69:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101e70:	e8 41 e2 ff ff       	call   f01000b6 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101e75:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101e7a:	f6 00 04             	testb  $0x4,(%eax)
f0101e7d:	75 24                	jne    f0101ea3 <mem_init+0xcce>
f0101e7f:	c7 44 24 0c 6b 60 10 	movl   $0xf010606b,0xc(%esp)
f0101e86:	f0 
f0101e87:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101e8e:	f0 
f0101e8f:	c7 44 24 04 76 03 00 	movl   $0x376,0x4(%esp)
f0101e96:	00 
f0101e97:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101e9e:	e8 13 e2 ff ff       	call   f01000b6 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ea3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101eaa:	00 
f0101eab:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101eb2:	00 
f0101eb3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101eb7:	89 04 24             	mov    %eax,(%esp)
f0101eba:	e8 6c f2 ff ff       	call   f010112b <page_insert>
f0101ebf:	85 c0                	test   %eax,%eax
f0101ec1:	74 24                	je     f0101ee7 <mem_init+0xd12>
f0101ec3:	c7 44 24 0c 20 59 10 	movl   $0xf0105920,0xc(%esp)
f0101eca:	f0 
f0101ecb:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101ed2:	f0 
f0101ed3:	c7 44 24 04 79 03 00 	movl   $0x379,0x4(%esp)
f0101eda:	00 
f0101edb:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101ee2:	e8 cf e1 ff ff       	call   f01000b6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101ee7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101eee:	00 
f0101eef:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101ef6:	00 
f0101ef7:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101efc:	89 04 24             	mov    %eax,(%esp)
f0101eff:	e8 0e f0 ff ff       	call   f0100f12 <pgdir_walk>
f0101f04:	f6 00 02             	testb  $0x2,(%eax)
f0101f07:	75 24                	jne    f0101f2d <mem_init+0xd58>
f0101f09:	c7 44 24 0c 40 5a 10 	movl   $0xf0105a40,0xc(%esp)
f0101f10:	f0 
f0101f11:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101f18:	f0 
f0101f19:	c7 44 24 04 7a 03 00 	movl   $0x37a,0x4(%esp)
f0101f20:	00 
f0101f21:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101f28:	e8 89 e1 ff ff       	call   f01000b6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f2d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f34:	00 
f0101f35:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f3c:	00 
f0101f3d:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101f42:	89 04 24             	mov    %eax,(%esp)
f0101f45:	e8 c8 ef ff ff       	call   f0100f12 <pgdir_walk>
f0101f4a:	f6 00 04             	testb  $0x4,(%eax)
f0101f4d:	74 24                	je     f0101f73 <mem_init+0xd9e>
f0101f4f:	c7 44 24 0c 74 5a 10 	movl   $0xf0105a74,0xc(%esp)
f0101f56:	f0 
f0101f57:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101f5e:	f0 
f0101f5f:	c7 44 24 04 7b 03 00 	movl   $0x37b,0x4(%esp)
f0101f66:	00 
f0101f67:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101f6e:	e8 43 e1 ff ff       	call   f01000b6 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f73:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f7a:	00 
f0101f7b:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101f82:	00 
f0101f83:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101f87:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101f8c:	89 04 24             	mov    %eax,(%esp)
f0101f8f:	e8 97 f1 ff ff       	call   f010112b <page_insert>
f0101f94:	85 c0                	test   %eax,%eax
f0101f96:	78 24                	js     f0101fbc <mem_init+0xde7>
f0101f98:	c7 44 24 0c ac 5a 10 	movl   $0xf0105aac,0xc(%esp)
f0101f9f:	f0 
f0101fa0:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101fa7:	f0 
f0101fa8:	c7 44 24 04 7e 03 00 	movl   $0x37e,0x4(%esp)
f0101faf:	00 
f0101fb0:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0101fb7:	e8 fa e0 ff ff       	call   f01000b6 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101fbc:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101fc3:	00 
f0101fc4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101fcb:	00 
f0101fcc:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101fd0:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0101fd5:	89 04 24             	mov    %eax,(%esp)
f0101fd8:	e8 4e f1 ff ff       	call   f010112b <page_insert>
f0101fdd:	85 c0                	test   %eax,%eax
f0101fdf:	74 24                	je     f0102005 <mem_init+0xe30>
f0101fe1:	c7 44 24 0c e4 5a 10 	movl   $0xf0105ae4,0xc(%esp)
f0101fe8:	f0 
f0101fe9:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0101ff0:	f0 
f0101ff1:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f0101ff8:	00 
f0101ff9:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102000:	e8 b1 e0 ff ff       	call   f01000b6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102005:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010200c:	00 
f010200d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102014:	00 
f0102015:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f010201a:	89 04 24             	mov    %eax,(%esp)
f010201d:	e8 f0 ee ff ff       	call   f0100f12 <pgdir_walk>
f0102022:	f6 00 04             	testb  $0x4,(%eax)
f0102025:	74 24                	je     f010204b <mem_init+0xe76>
f0102027:	c7 44 24 0c 74 5a 10 	movl   $0xf0105a74,0xc(%esp)
f010202e:	f0 
f010202f:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102036:	f0 
f0102037:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f010203e:	00 
f010203f:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102046:	e8 6b e0 ff ff       	call   f01000b6 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010204b:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102050:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102053:	ba 00 00 00 00       	mov    $0x0,%edx
f0102058:	e8 db e8 ff ff       	call   f0100938 <check_va2pa>
f010205d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102060:	89 f0                	mov    %esi,%eax
f0102062:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0102068:	c1 f8 03             	sar    $0x3,%eax
f010206b:	c1 e0 0c             	shl    $0xc,%eax
f010206e:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102071:	74 24                	je     f0102097 <mem_init+0xec2>
f0102073:	c7 44 24 0c 20 5b 10 	movl   $0xf0105b20,0xc(%esp)
f010207a:	f0 
f010207b:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102082:	f0 
f0102083:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f010208a:	00 
f010208b:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102092:	e8 1f e0 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102097:	ba 00 10 00 00       	mov    $0x1000,%edx
f010209c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010209f:	e8 94 e8 ff ff       	call   f0100938 <check_va2pa>
f01020a4:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01020a7:	74 24                	je     f01020cd <mem_init+0xef8>
f01020a9:	c7 44 24 0c 4c 5b 10 	movl   $0xf0105b4c,0xc(%esp)
f01020b0:	f0 
f01020b1:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f01020b8:	f0 
f01020b9:	c7 44 24 04 86 03 00 	movl   $0x386,0x4(%esp)
f01020c0:	00 
f01020c1:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01020c8:	e8 e9 df ff ff       	call   f01000b6 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01020cd:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f01020d2:	74 24                	je     f01020f8 <mem_init+0xf23>
f01020d4:	c7 44 24 0c 81 60 10 	movl   $0xf0106081,0xc(%esp)
f01020db:	f0 
f01020dc:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f01020e3:	f0 
f01020e4:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f01020eb:	00 
f01020ec:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01020f3:	e8 be df ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f01020f8:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01020fd:	74 24                	je     f0102123 <mem_init+0xf4e>
f01020ff:	c7 44 24 0c 92 60 10 	movl   $0xf0106092,0xc(%esp)
f0102106:	f0 
f0102107:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f010210e:	f0 
f010210f:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f0102116:	00 
f0102117:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f010211e:	e8 93 df ff ff       	call   f01000b6 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102123:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010212a:	e8 fc ec ff ff       	call   f0100e2b <page_alloc>
f010212f:	85 c0                	test   %eax,%eax
f0102131:	74 04                	je     f0102137 <mem_init+0xf62>
f0102133:	39 c3                	cmp    %eax,%ebx
f0102135:	74 24                	je     f010215b <mem_init+0xf86>
f0102137:	c7 44 24 0c 7c 5b 10 	movl   $0xf0105b7c,0xc(%esp)
f010213e:	f0 
f010213f:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102146:	f0 
f0102147:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f010214e:	00 
f010214f:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102156:	e8 5b df ff ff       	call   f01000b6 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010215b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102162:	00 
f0102163:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102168:	89 04 24             	mov    %eax,(%esp)
f010216b:	e8 6b ef ff ff       	call   f01010db <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102170:	8b 15 28 ec 17 f0    	mov    0xf017ec28,%edx
f0102176:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0102179:	ba 00 00 00 00       	mov    $0x0,%edx
f010217e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102181:	e8 b2 e7 ff ff       	call   f0100938 <check_va2pa>
f0102186:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102189:	74 24                	je     f01021af <mem_init+0xfda>
f010218b:	c7 44 24 0c a0 5b 10 	movl   $0xf0105ba0,0xc(%esp)
f0102192:	f0 
f0102193:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f010219a:	f0 
f010219b:	c7 44 24 04 90 03 00 	movl   $0x390,0x4(%esp)
f01021a2:	00 
f01021a3:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01021aa:	e8 07 df ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01021af:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021b4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021b7:	e8 7c e7 ff ff       	call   f0100938 <check_va2pa>
f01021bc:	89 f2                	mov    %esi,%edx
f01021be:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f01021c4:	c1 fa 03             	sar    $0x3,%edx
f01021c7:	c1 e2 0c             	shl    $0xc,%edx
f01021ca:	39 d0                	cmp    %edx,%eax
f01021cc:	74 24                	je     f01021f2 <mem_init+0x101d>
f01021ce:	c7 44 24 0c 4c 5b 10 	movl   $0xf0105b4c,0xc(%esp)
f01021d5:	f0 
f01021d6:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f01021dd:	f0 
f01021de:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f01021e5:	00 
f01021e6:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01021ed:	e8 c4 de ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f01021f2:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01021f7:	74 24                	je     f010221d <mem_init+0x1048>
f01021f9:	c7 44 24 0c 38 60 10 	movl   $0xf0106038,0xc(%esp)
f0102200:	f0 
f0102201:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102208:	f0 
f0102209:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f0102210:	00 
f0102211:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102218:	e8 99 de ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f010221d:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102222:	74 24                	je     f0102248 <mem_init+0x1073>
f0102224:	c7 44 24 0c 92 60 10 	movl   $0xf0106092,0xc(%esp)
f010222b:	f0 
f010222c:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102233:	f0 
f0102234:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f010223b:	00 
f010223c:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102243:	e8 6e de ff ff       	call   f01000b6 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102248:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010224f:	00 
f0102250:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102257:	00 
f0102258:	89 74 24 04          	mov    %esi,0x4(%esp)
f010225c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010225f:	89 0c 24             	mov    %ecx,(%esp)
f0102262:	e8 c4 ee ff ff       	call   f010112b <page_insert>
f0102267:	85 c0                	test   %eax,%eax
f0102269:	74 24                	je     f010228f <mem_init+0x10ba>
f010226b:	c7 44 24 0c c4 5b 10 	movl   $0xf0105bc4,0xc(%esp)
f0102272:	f0 
f0102273:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f010227a:	f0 
f010227b:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f0102282:	00 
f0102283:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f010228a:	e8 27 de ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref);
f010228f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102294:	75 24                	jne    f01022ba <mem_init+0x10e5>
f0102296:	c7 44 24 0c a3 60 10 	movl   $0xf01060a3,0xc(%esp)
f010229d:	f0 
f010229e:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f01022a5:	f0 
f01022a6:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f01022ad:	00 
f01022ae:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01022b5:	e8 fc dd ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_link == NULL);
f01022ba:	83 3e 00             	cmpl   $0x0,(%esi)
f01022bd:	74 24                	je     f01022e3 <mem_init+0x110e>
f01022bf:	c7 44 24 0c af 60 10 	movl   $0xf01060af,0xc(%esp)
f01022c6:	f0 
f01022c7:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f01022ce:	f0 
f01022cf:	c7 44 24 04 98 03 00 	movl   $0x398,0x4(%esp)
f01022d6:	00 
f01022d7:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01022de:	e8 d3 dd ff ff       	call   f01000b6 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01022e3:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01022ea:	00 
f01022eb:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f01022f0:	89 04 24             	mov    %eax,(%esp)
f01022f3:	e8 e3 ed ff ff       	call   f01010db <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01022f8:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f01022fd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102300:	ba 00 00 00 00       	mov    $0x0,%edx
f0102305:	e8 2e e6 ff ff       	call   f0100938 <check_va2pa>
f010230a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010230d:	74 24                	je     f0102333 <mem_init+0x115e>
f010230f:	c7 44 24 0c a0 5b 10 	movl   $0xf0105ba0,0xc(%esp)
f0102316:	f0 
f0102317:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f010231e:	f0 
f010231f:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f0102326:	00 
f0102327:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f010232e:	e8 83 dd ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102333:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102338:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010233b:	e8 f8 e5 ff ff       	call   f0100938 <check_va2pa>
f0102340:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102343:	74 24                	je     f0102369 <mem_init+0x1194>
f0102345:	c7 44 24 0c fc 5b 10 	movl   $0xf0105bfc,0xc(%esp)
f010234c:	f0 
f010234d:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102354:	f0 
f0102355:	c7 44 24 04 9d 03 00 	movl   $0x39d,0x4(%esp)
f010235c:	00 
f010235d:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102364:	e8 4d dd ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f0102369:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010236e:	74 24                	je     f0102394 <mem_init+0x11bf>
f0102370:	c7 44 24 0c c4 60 10 	movl   $0xf01060c4,0xc(%esp)
f0102377:	f0 
f0102378:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f010237f:	f0 
f0102380:	c7 44 24 04 9e 03 00 	movl   $0x39e,0x4(%esp)
f0102387:	00 
f0102388:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f010238f:	e8 22 dd ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f0102394:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102399:	74 24                	je     f01023bf <mem_init+0x11ea>
f010239b:	c7 44 24 0c 92 60 10 	movl   $0xf0106092,0xc(%esp)
f01023a2:	f0 
f01023a3:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f01023aa:	f0 
f01023ab:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f01023b2:	00 
f01023b3:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01023ba:	e8 f7 dc ff ff       	call   f01000b6 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01023bf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01023c6:	e8 60 ea ff ff       	call   f0100e2b <page_alloc>
f01023cb:	85 c0                	test   %eax,%eax
f01023cd:	74 04                	je     f01023d3 <mem_init+0x11fe>
f01023cf:	39 c6                	cmp    %eax,%esi
f01023d1:	74 24                	je     f01023f7 <mem_init+0x1222>
f01023d3:	c7 44 24 0c 24 5c 10 	movl   $0xf0105c24,0xc(%esp)
f01023da:	f0 
f01023db:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f01023e2:	f0 
f01023e3:	c7 44 24 04 a2 03 00 	movl   $0x3a2,0x4(%esp)
f01023ea:	00 
f01023eb:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01023f2:	e8 bf dc ff ff       	call   f01000b6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01023f7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01023fe:	e8 28 ea ff ff       	call   f0100e2b <page_alloc>
f0102403:	85 c0                	test   %eax,%eax
f0102405:	74 24                	je     f010242b <mem_init+0x1256>
f0102407:	c7 44 24 0c e6 5f 10 	movl   $0xf0105fe6,0xc(%esp)
f010240e:	f0 
f010240f:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102416:	f0 
f0102417:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f010241e:	00 
f010241f:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102426:	e8 8b dc ff ff       	call   f01000b6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010242b:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102430:	8b 08                	mov    (%eax),%ecx
f0102432:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102438:	89 fa                	mov    %edi,%edx
f010243a:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f0102440:	c1 fa 03             	sar    $0x3,%edx
f0102443:	c1 e2 0c             	shl    $0xc,%edx
f0102446:	39 d1                	cmp    %edx,%ecx
f0102448:	74 24                	je     f010246e <mem_init+0x1299>
f010244a:	c7 44 24 0c c8 58 10 	movl   $0xf01058c8,0xc(%esp)
f0102451:	f0 
f0102452:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102459:	f0 
f010245a:	c7 44 24 04 a8 03 00 	movl   $0x3a8,0x4(%esp)
f0102461:	00 
f0102462:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102469:	e8 48 dc ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f010246e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102474:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102479:	74 24                	je     f010249f <mem_init+0x12ca>
f010247b:	c7 44 24 0c 49 60 10 	movl   $0xf0106049,0xc(%esp)
f0102482:	f0 
f0102483:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f010248a:	f0 
f010248b:	c7 44 24 04 aa 03 00 	movl   $0x3aa,0x4(%esp)
f0102492:	00 
f0102493:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f010249a:	e8 17 dc ff ff       	call   f01000b6 <_panic>
	pp0->pp_ref = 0;
f010249f:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01024a5:	89 3c 24             	mov    %edi,(%esp)
f01024a8:	e8 02 ea ff ff       	call   f0100eaf <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01024ad:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01024b4:	00 
f01024b5:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01024bc:	00 
f01024bd:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f01024c2:	89 04 24             	mov    %eax,(%esp)
f01024c5:	e8 48 ea ff ff       	call   f0100f12 <pgdir_walk>
f01024ca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01024cd:	8b 0d 28 ec 17 f0    	mov    0xf017ec28,%ecx
f01024d3:	8b 51 04             	mov    0x4(%ecx),%edx
f01024d6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01024dc:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024df:	8b 15 24 ec 17 f0    	mov    0xf017ec24,%edx
f01024e5:	89 55 c8             	mov    %edx,-0x38(%ebp)
f01024e8:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01024eb:	c1 ea 0c             	shr    $0xc,%edx
f01024ee:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01024f1:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01024f4:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f01024f7:	72 23                	jb     f010251c <mem_init+0x1347>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024f9:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01024fc:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102500:	c7 44 24 08 64 56 10 	movl   $0xf0105664,0x8(%esp)
f0102507:	f0 
f0102508:	c7 44 24 04 b1 03 00 	movl   $0x3b1,0x4(%esp)
f010250f:	00 
f0102510:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102517:	e8 9a db ff ff       	call   f01000b6 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010251c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010251f:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102525:	39 d0                	cmp    %edx,%eax
f0102527:	74 24                	je     f010254d <mem_init+0x1378>
f0102529:	c7 44 24 0c d5 60 10 	movl   $0xf01060d5,0xc(%esp)
f0102530:	f0 
f0102531:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102538:	f0 
f0102539:	c7 44 24 04 b2 03 00 	movl   $0x3b2,0x4(%esp)
f0102540:	00 
f0102541:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102548:	e8 69 db ff ff       	call   f01000b6 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010254d:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0102554:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010255a:	89 f8                	mov    %edi,%eax
f010255c:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0102562:	c1 f8 03             	sar    $0x3,%eax
f0102565:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102568:	89 c1                	mov    %eax,%ecx
f010256a:	c1 e9 0c             	shr    $0xc,%ecx
f010256d:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0102570:	77 20                	ja     f0102592 <mem_init+0x13bd>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102572:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102576:	c7 44 24 08 64 56 10 	movl   $0xf0105664,0x8(%esp)
f010257d:	f0 
f010257e:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102585:	00 
f0102586:	c7 04 24 61 5e 10 f0 	movl   $0xf0105e61,(%esp)
f010258d:	e8 24 db ff ff       	call   f01000b6 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102592:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102599:	00 
f010259a:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01025a1:	00 
	return (void *)(pa + KERNBASE);
f01025a2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025a7:	89 04 24             	mov    %eax,(%esp)
f01025aa:	e8 94 26 00 00       	call   f0104c43 <memset>
	page_free(pp0);
f01025af:	89 3c 24             	mov    %edi,(%esp)
f01025b2:	e8 f8 e8 ff ff       	call   f0100eaf <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01025b7:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01025be:	00 
f01025bf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01025c6:	00 
f01025c7:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f01025cc:	89 04 24             	mov    %eax,(%esp)
f01025cf:	e8 3e e9 ff ff       	call   f0100f12 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025d4:	89 fa                	mov    %edi,%edx
f01025d6:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f01025dc:	c1 fa 03             	sar    $0x3,%edx
f01025df:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025e2:	89 d0                	mov    %edx,%eax
f01025e4:	c1 e8 0c             	shr    $0xc,%eax
f01025e7:	3b 05 24 ec 17 f0    	cmp    0xf017ec24,%eax
f01025ed:	72 20                	jb     f010260f <mem_init+0x143a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025ef:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01025f3:	c7 44 24 08 64 56 10 	movl   $0xf0105664,0x8(%esp)
f01025fa:	f0 
f01025fb:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102602:	00 
f0102603:	c7 04 24 61 5e 10 f0 	movl   $0xf0105e61,(%esp)
f010260a:	e8 a7 da ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f010260f:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102615:	89 45 e4             	mov    %eax,-0x1c(%ebp)
// will be set up later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102618:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010261e:	f6 00 01             	testb  $0x1,(%eax)
f0102621:	74 24                	je     f0102647 <mem_init+0x1472>
f0102623:	c7 44 24 0c ed 60 10 	movl   $0xf01060ed,0xc(%esp)
f010262a:	f0 
f010262b:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102632:	f0 
f0102633:	c7 44 24 04 bc 03 00 	movl   $0x3bc,0x4(%esp)
f010263a:	00 
f010263b:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102642:	e8 6f da ff ff       	call   f01000b6 <_panic>
f0102647:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010264a:	39 d0                	cmp    %edx,%eax
f010264c:	75 d0                	jne    f010261e <mem_init+0x1449>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010264e:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102653:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102659:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// give free list back
	page_free_list = fl;
f010265f:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102662:	89 0d 80 df 17 f0    	mov    %ecx,0xf017df80

	// free the pages we took
	page_free(pp0);
f0102668:	89 3c 24             	mov    %edi,(%esp)
f010266b:	e8 3f e8 ff ff       	call   f0100eaf <page_free>
	page_free(pp1);
f0102670:	89 34 24             	mov    %esi,(%esp)
f0102673:	e8 37 e8 ff ff       	call   f0100eaf <page_free>
	page_free(pp2);
f0102678:	89 1c 24             	mov    %ebx,(%esp)
f010267b:	e8 2f e8 ff ff       	call   f0100eaf <page_free>

	cprintf("check_page() succeeded!\n");
f0102680:	c7 04 24 04 61 10 f0 	movl   $0xf0106104,(%esp)
f0102687:	e8 9a 10 00 00       	call   f0103726 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, 
f010268c:	a1 2c ec 17 f0       	mov    0xf017ec2c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102691:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102696:	77 20                	ja     f01026b8 <mem_init+0x14e3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102698:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010269c:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f01026a3:	f0 
f01026a4:	c7 44 24 04 bf 00 00 	movl   $0xbf,0x4(%esp)
f01026ab:	00 
f01026ac:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01026b3:	e8 fe d9 ff ff       	call   f01000b6 <_panic>
			ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE), 
f01026b8:	8b 15 24 ec 17 f0    	mov    0xf017ec24,%edx
f01026be:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f01026c5:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, 
f01026cb:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f01026d2:	00 
	return (physaddr_t)kva - KERNBASE;
f01026d3:	05 00 00 00 10       	add    $0x10000000,%eax
f01026d8:	89 04 24             	mov    %eax,(%esp)
f01026db:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01026e0:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f01026e5:	e8 17 e9 ff ff       	call   f0101001 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS,
f01026ea:	a1 8c df 17 f0       	mov    0xf017df8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026ef:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026f4:	77 20                	ja     f0102716 <mem_init+0x1541>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026f6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01026fa:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f0102701:	f0 
f0102702:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
f0102709:	00 
f010270a:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102711:	e8 a0 d9 ff ff       	call   f01000b6 <_panic>
f0102716:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f010271d:	00 
	return (physaddr_t)kva - KERNBASE;
f010271e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102723:	89 04 24             	mov    %eax,(%esp)
f0102726:	b9 00 80 01 00       	mov    $0x18000,%ecx
f010272b:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102730:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102735:	e8 c7 e8 ff ff       	call   f0101001 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010273a:	be 00 20 11 f0       	mov    $0xf0112000,%esi
f010273f:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102745:	77 20                	ja     f0102767 <mem_init+0x1592>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102747:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010274b:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f0102752:	f0 
f0102753:	c7 44 24 04 d8 00 00 	movl   $0xd8,0x4(%esp)
f010275a:	00 
f010275b:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102762:	e8 4f d9 ff ff       	call   f01000b6 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE,
f0102767:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010276e:	00 
f010276f:	c7 04 24 00 20 11 00 	movl   $0x112000,(%esp)
f0102776:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010277b:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102780:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102785:	e8 77 e8 ff ff       	call   f0101001 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE,
f010278a:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102791:	00 
f0102792:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102799:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010279e:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01027a3:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f01027a8:	e8 54 e8 ff ff       	call   f0101001 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01027ad:	8b 1d 28 ec 17 f0    	mov    0xf017ec28,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01027b3:	8b 35 24 ec 17 f0    	mov    0xf017ec24,%esi
f01027b9:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01027bc:	8d 3c f5 ff 0f 00 00 	lea    0xfff(,%esi,8),%edi
f01027c3:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	for (i = 0; i < n; i += PGSIZE)
f01027c9:	be 00 00 00 00       	mov    $0x0,%esi
f01027ce:	eb 70                	jmp    f0102840 <mem_init+0x166b>
// will be set up later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01027d0:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01027d6:	89 d8                	mov    %ebx,%eax
f01027d8:	e8 5b e1 ff ff       	call   f0100938 <check_va2pa>
f01027dd:	8b 15 2c ec 17 f0    	mov    0xf017ec2c,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027e3:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01027e9:	77 20                	ja     f010280b <mem_init+0x1636>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027eb:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01027ef:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f01027f6:	f0 
f01027f7:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
f01027fe:	00 
f01027ff:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102806:	e8 ab d8 ff ff       	call   f01000b6 <_panic>
f010280b:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f0102812:	39 d0                	cmp    %edx,%eax
f0102814:	74 24                	je     f010283a <mem_init+0x1665>
f0102816:	c7 44 24 0c 48 5c 10 	movl   $0xf0105c48,0xc(%esp)
f010281d:	f0 
f010281e:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102825:	f0 
f0102826:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
f010282d:	00 
f010282e:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102835:	e8 7c d8 ff ff       	call   f01000b6 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010283a:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102840:	39 f7                	cmp    %esi,%edi
f0102842:	77 8c                	ja     f01027d0 <mem_init+0x15fb>
f0102844:	be 00 00 00 00       	mov    $0x0,%esi
// will be set up later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102849:	8d 96 00 00 c0 ee    	lea    -0x11400000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f010284f:	89 d8                	mov    %ebx,%eax
f0102851:	e8 e2 e0 ff ff       	call   f0100938 <check_va2pa>
f0102856:	8b 15 8c df 17 f0    	mov    0xf017df8c,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010285c:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102862:	77 20                	ja     f0102884 <mem_init+0x16af>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102864:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102868:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f010286f:	f0 
f0102870:	c7 44 24 04 fe 02 00 	movl   $0x2fe,0x4(%esp)
f0102877:	00 
f0102878:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f010287f:	e8 32 d8 ff ff       	call   f01000b6 <_panic>
f0102884:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f010288b:	39 d0                	cmp    %edx,%eax
f010288d:	74 24                	je     f01028b3 <mem_init+0x16de>
f010288f:	c7 44 24 0c 7c 5c 10 	movl   $0xf0105c7c,0xc(%esp)
f0102896:	f0 
f0102897:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f010289e:	f0 
f010289f:	c7 44 24 04 fe 02 00 	movl   $0x2fe,0x4(%esp)
f01028a6:	00 
f01028a7:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01028ae:	e8 03 d8 ff ff       	call   f01000b6 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01028b3:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01028b9:	81 fe 00 80 01 00    	cmp    $0x18000,%esi
f01028bf:	75 88                	jne    f0102849 <mem_init+0x1674>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01028c1:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01028c4:	c1 e7 0c             	shl    $0xc,%edi
f01028c7:	be 00 00 00 00       	mov    $0x0,%esi
f01028cc:	eb 3b                	jmp    f0102909 <mem_init+0x1734>
// will be set up later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01028ce:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01028d4:	89 d8                	mov    %ebx,%eax
f01028d6:	e8 5d e0 ff ff       	call   f0100938 <check_va2pa>
f01028db:	39 c6                	cmp    %eax,%esi
f01028dd:	74 24                	je     f0102903 <mem_init+0x172e>
f01028df:	c7 44 24 0c b0 5c 10 	movl   $0xf0105cb0,0xc(%esp)
f01028e6:	f0 
f01028e7:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f01028ee:	f0 
f01028ef:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
f01028f6:	00 
f01028f7:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01028fe:	e8 b3 d7 ff ff       	call   f01000b6 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102903:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102909:	39 fe                	cmp    %edi,%esi
f010290b:	72 c1                	jb     f01028ce <mem_init+0x16f9>
f010290d:	be 00 80 ff ef       	mov    $0xefff8000,%esi
// will be set up later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102912:	bf 00 20 11 f0       	mov    $0xf0112000,%edi
f0102917:	81 c7 00 80 00 20    	add    $0x20008000,%edi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010291d:	89 f2                	mov    %esi,%edx
f010291f:	89 d8                	mov    %ebx,%eax
f0102921:	e8 12 e0 ff ff       	call   f0100938 <check_va2pa>
// will be set up later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102926:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102929:	39 d0                	cmp    %edx,%eax
f010292b:	74 24                	je     f0102951 <mem_init+0x177c>
f010292d:	c7 44 24 0c d8 5c 10 	movl   $0xf0105cd8,0xc(%esp)
f0102934:	f0 
f0102935:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f010293c:	f0 
f010293d:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0102944:	00 
f0102945:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f010294c:	e8 65 d7 ff ff       	call   f01000b6 <_panic>
f0102951:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102957:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f010295d:	75 be                	jne    f010291d <mem_init+0x1748>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010295f:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102964:	89 d8                	mov    %ebx,%eax
f0102966:	e8 cd df ff ff       	call   f0100938 <check_va2pa>
f010296b:	83 f8 ff             	cmp    $0xffffffff,%eax
f010296e:	74 24                	je     f0102994 <mem_init+0x17bf>
f0102970:	c7 44 24 0c 20 5d 10 	movl   $0xf0105d20,0xc(%esp)
f0102977:	f0 
f0102978:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f010297f:	f0 
f0102980:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
f0102987:	00 
f0102988:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f010298f:	e8 22 d7 ff ff       	call   f01000b6 <_panic>
f0102994:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102999:	ba 01 00 00 00       	mov    $0x1,%edx
f010299e:	8d 88 45 fc ff ff    	lea    -0x3bb(%eax),%ecx
f01029a4:	83 f9 04             	cmp    $0x4,%ecx
f01029a7:	77 39                	ja     f01029e2 <mem_init+0x180d>
f01029a9:	89 d6                	mov    %edx,%esi
f01029ab:	d3 e6                	shl    %cl,%esi
f01029ad:	89 f1                	mov    %esi,%ecx
f01029af:	f6 c1 17             	test   $0x17,%cl
f01029b2:	74 2e                	je     f01029e2 <mem_init+0x180d>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f01029b4:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01029b8:	0f 85 aa 00 00 00    	jne    f0102a68 <mem_init+0x1893>
f01029be:	c7 44 24 0c 1d 61 10 	movl   $0xf010611d,0xc(%esp)
f01029c5:	f0 
f01029c6:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f01029cd:	f0 
f01029ce:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f01029d5:	00 
f01029d6:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f01029dd:	e8 d4 d6 ff ff       	call   f01000b6 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01029e2:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01029e7:	76 55                	jbe    f0102a3e <mem_init+0x1869>
				assert(pgdir[i] & PTE_P);
f01029e9:	8b 0c 83             	mov    (%ebx,%eax,4),%ecx
f01029ec:	f6 c1 01             	test   $0x1,%cl
f01029ef:	75 24                	jne    f0102a15 <mem_init+0x1840>
f01029f1:	c7 44 24 0c 1d 61 10 	movl   $0xf010611d,0xc(%esp)
f01029f8:	f0 
f01029f9:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102a00:	f0 
f0102a01:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0102a08:	00 
f0102a09:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102a10:	e8 a1 d6 ff ff       	call   f01000b6 <_panic>
				assert(pgdir[i] & PTE_W);
f0102a15:	f6 c1 02             	test   $0x2,%cl
f0102a18:	75 4e                	jne    f0102a68 <mem_init+0x1893>
f0102a1a:	c7 44 24 0c 2e 61 10 	movl   $0xf010612e,0xc(%esp)
f0102a21:	f0 
f0102a22:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102a29:	f0 
f0102a2a:	c7 44 24 04 15 03 00 	movl   $0x315,0x4(%esp)
f0102a31:	00 
f0102a32:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102a39:	e8 78 d6 ff ff       	call   f01000b6 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102a3e:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102a42:	74 24                	je     f0102a68 <mem_init+0x1893>
f0102a44:	c7 44 24 0c 3f 61 10 	movl   $0xf010613f,0xc(%esp)
f0102a4b:	f0 
f0102a4c:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102a53:	f0 
f0102a54:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0102a5b:	00 
f0102a5c:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102a63:	e8 4e d6 ff ff       	call   f01000b6 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102a68:	83 c0 01             	add    $0x1,%eax
f0102a6b:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102a70:	0f 85 28 ff ff ff    	jne    f010299e <mem_init+0x17c9>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102a76:	c7 04 24 50 5d 10 f0 	movl   $0xf0105d50,(%esp)
f0102a7d:	e8 a4 0c 00 00       	call   f0103726 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102a82:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a87:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a8c:	77 20                	ja     f0102aae <mem_init+0x18d9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a8e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a92:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f0102a99:	f0 
f0102a9a:	c7 44 24 04 ef 00 00 	movl   $0xef,0x4(%esp)
f0102aa1:	00 
f0102aa2:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102aa9:	e8 08 d6 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102aae:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102ab3:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102ab6:	b8 00 00 00 00       	mov    $0x0,%eax
f0102abb:	e8 88 df ff ff       	call   f0100a48 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102ac0:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f0102ac3:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102ac8:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102acb:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102ace:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102ad5:	e8 51 e3 ff ff       	call   f0100e2b <page_alloc>
f0102ada:	89 c6                	mov    %eax,%esi
f0102adc:	85 c0                	test   %eax,%eax
f0102ade:	75 24                	jne    f0102b04 <mem_init+0x192f>
f0102ae0:	c7 44 24 0c 3b 5f 10 	movl   $0xf0105f3b,0xc(%esp)
f0102ae7:	f0 
f0102ae8:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102aef:	f0 
f0102af0:	c7 44 24 04 d7 03 00 	movl   $0x3d7,0x4(%esp)
f0102af7:	00 
f0102af8:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102aff:	e8 b2 d5 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0102b04:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b0b:	e8 1b e3 ff ff       	call   f0100e2b <page_alloc>
f0102b10:	89 c7                	mov    %eax,%edi
f0102b12:	85 c0                	test   %eax,%eax
f0102b14:	75 24                	jne    f0102b3a <mem_init+0x1965>
f0102b16:	c7 44 24 0c 51 5f 10 	movl   $0xf0105f51,0xc(%esp)
f0102b1d:	f0 
f0102b1e:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102b25:	f0 
f0102b26:	c7 44 24 04 d8 03 00 	movl   $0x3d8,0x4(%esp)
f0102b2d:	00 
f0102b2e:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102b35:	e8 7c d5 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0102b3a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b41:	e8 e5 e2 ff ff       	call   f0100e2b <page_alloc>
f0102b46:	89 c3                	mov    %eax,%ebx
f0102b48:	85 c0                	test   %eax,%eax
f0102b4a:	75 24                	jne    f0102b70 <mem_init+0x199b>
f0102b4c:	c7 44 24 0c 67 5f 10 	movl   $0xf0105f67,0xc(%esp)
f0102b53:	f0 
f0102b54:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102b5b:	f0 
f0102b5c:	c7 44 24 04 d9 03 00 	movl   $0x3d9,0x4(%esp)
f0102b63:	00 
f0102b64:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102b6b:	e8 46 d5 ff ff       	call   f01000b6 <_panic>
	page_free(pp0);
f0102b70:	89 34 24             	mov    %esi,(%esp)
f0102b73:	e8 37 e3 ff ff       	call   f0100eaf <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b78:	89 f8                	mov    %edi,%eax
f0102b7a:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0102b80:	c1 f8 03             	sar    $0x3,%eax
f0102b83:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b86:	89 c2                	mov    %eax,%edx
f0102b88:	c1 ea 0c             	shr    $0xc,%edx
f0102b8b:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0102b91:	72 20                	jb     f0102bb3 <mem_init+0x19de>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b93:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b97:	c7 44 24 08 64 56 10 	movl   $0xf0105664,0x8(%esp)
f0102b9e:	f0 
f0102b9f:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102ba6:	00 
f0102ba7:	c7 04 24 61 5e 10 f0 	movl   $0xf0105e61,(%esp)
f0102bae:	e8 03 d5 ff ff       	call   f01000b6 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102bb3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102bba:	00 
f0102bbb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102bc2:	00 
	return (void *)(pa + KERNBASE);
f0102bc3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102bc8:	89 04 24             	mov    %eax,(%esp)
f0102bcb:	e8 73 20 00 00       	call   f0104c43 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102bd0:	89 d8                	mov    %ebx,%eax
f0102bd2:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0102bd8:	c1 f8 03             	sar    $0x3,%eax
f0102bdb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bde:	89 c2                	mov    %eax,%edx
f0102be0:	c1 ea 0c             	shr    $0xc,%edx
f0102be3:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0102be9:	72 20                	jb     f0102c0b <mem_init+0x1a36>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102beb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102bef:	c7 44 24 08 64 56 10 	movl   $0xf0105664,0x8(%esp)
f0102bf6:	f0 
f0102bf7:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102bfe:	00 
f0102bff:	c7 04 24 61 5e 10 f0 	movl   $0xf0105e61,(%esp)
f0102c06:	e8 ab d4 ff ff       	call   f01000b6 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102c0b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c12:	00 
f0102c13:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102c1a:	00 
	return (void *)(pa + KERNBASE);
f0102c1b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c20:	89 04 24             	mov    %eax,(%esp)
f0102c23:	e8 1b 20 00 00       	call   f0104c43 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102c28:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102c2f:	00 
f0102c30:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c37:	00 
f0102c38:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102c3c:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102c41:	89 04 24             	mov    %eax,(%esp)
f0102c44:	e8 e2 e4 ff ff       	call   f010112b <page_insert>
	assert(pp1->pp_ref == 1);
f0102c49:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102c4e:	74 24                	je     f0102c74 <mem_init+0x1a9f>
f0102c50:	c7 44 24 0c 38 60 10 	movl   $0xf0106038,0xc(%esp)
f0102c57:	f0 
f0102c58:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102c5f:	f0 
f0102c60:	c7 44 24 04 de 03 00 	movl   $0x3de,0x4(%esp)
f0102c67:	00 
f0102c68:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102c6f:	e8 42 d4 ff ff       	call   f01000b6 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102c74:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102c7b:	01 01 01 
f0102c7e:	74 24                	je     f0102ca4 <mem_init+0x1acf>
f0102c80:	c7 44 24 0c 70 5d 10 	movl   $0xf0105d70,0xc(%esp)
f0102c87:	f0 
f0102c88:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102c8f:	f0 
f0102c90:	c7 44 24 04 df 03 00 	movl   $0x3df,0x4(%esp)
f0102c97:	00 
f0102c98:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102c9f:	e8 12 d4 ff ff       	call   f01000b6 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102ca4:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102cab:	00 
f0102cac:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102cb3:	00 
f0102cb4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102cb8:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102cbd:	89 04 24             	mov    %eax,(%esp)
f0102cc0:	e8 66 e4 ff ff       	call   f010112b <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102cc5:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102ccc:	02 02 02 
f0102ccf:	74 24                	je     f0102cf5 <mem_init+0x1b20>
f0102cd1:	c7 44 24 0c 94 5d 10 	movl   $0xf0105d94,0xc(%esp)
f0102cd8:	f0 
f0102cd9:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102ce0:	f0 
f0102ce1:	c7 44 24 04 e1 03 00 	movl   $0x3e1,0x4(%esp)
f0102ce8:	00 
f0102ce9:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102cf0:	e8 c1 d3 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0102cf5:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102cfa:	74 24                	je     f0102d20 <mem_init+0x1b4b>
f0102cfc:	c7 44 24 0c 5a 60 10 	movl   $0xf010605a,0xc(%esp)
f0102d03:	f0 
f0102d04:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102d0b:	f0 
f0102d0c:	c7 44 24 04 e2 03 00 	movl   $0x3e2,0x4(%esp)
f0102d13:	00 
f0102d14:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102d1b:	e8 96 d3 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f0102d20:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102d25:	74 24                	je     f0102d4b <mem_init+0x1b76>
f0102d27:	c7 44 24 0c c4 60 10 	movl   $0xf01060c4,0xc(%esp)
f0102d2e:	f0 
f0102d2f:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102d36:	f0 
f0102d37:	c7 44 24 04 e3 03 00 	movl   $0x3e3,0x4(%esp)
f0102d3e:	00 
f0102d3f:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102d46:	e8 6b d3 ff ff       	call   f01000b6 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102d4b:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102d52:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102d55:	89 d8                	mov    %ebx,%eax
f0102d57:	2b 05 2c ec 17 f0    	sub    0xf017ec2c,%eax
f0102d5d:	c1 f8 03             	sar    $0x3,%eax
f0102d60:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d63:	89 c2                	mov    %eax,%edx
f0102d65:	c1 ea 0c             	shr    $0xc,%edx
f0102d68:	3b 15 24 ec 17 f0    	cmp    0xf017ec24,%edx
f0102d6e:	72 20                	jb     f0102d90 <mem_init+0x1bbb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d70:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d74:	c7 44 24 08 64 56 10 	movl   $0xf0105664,0x8(%esp)
f0102d7b:	f0 
f0102d7c:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102d83:	00 
f0102d84:	c7 04 24 61 5e 10 f0 	movl   $0xf0105e61,(%esp)
f0102d8b:	e8 26 d3 ff ff       	call   f01000b6 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d90:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102d97:	03 03 03 
f0102d9a:	74 24                	je     f0102dc0 <mem_init+0x1beb>
f0102d9c:	c7 44 24 0c b8 5d 10 	movl   $0xf0105db8,0xc(%esp)
f0102da3:	f0 
f0102da4:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102dab:	f0 
f0102dac:	c7 44 24 04 e5 03 00 	movl   $0x3e5,0x4(%esp)
f0102db3:	00 
f0102db4:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102dbb:	e8 f6 d2 ff ff       	call   f01000b6 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102dc0:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102dc7:	00 
f0102dc8:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102dcd:	89 04 24             	mov    %eax,(%esp)
f0102dd0:	e8 06 e3 ff ff       	call   f01010db <page_remove>
	assert(pp2->pp_ref == 0);
f0102dd5:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102dda:	74 24                	je     f0102e00 <mem_init+0x1c2b>
f0102ddc:	c7 44 24 0c 92 60 10 	movl   $0xf0106092,0xc(%esp)
f0102de3:	f0 
f0102de4:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102deb:	f0 
f0102dec:	c7 44 24 04 e7 03 00 	movl   $0x3e7,0x4(%esp)
f0102df3:	00 
f0102df4:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102dfb:	e8 b6 d2 ff ff       	call   f01000b6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102e00:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0102e05:	8b 08                	mov    (%eax),%ecx
f0102e07:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102e0d:	89 f2                	mov    %esi,%edx
f0102e0f:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f0102e15:	c1 fa 03             	sar    $0x3,%edx
f0102e18:	c1 e2 0c             	shl    $0xc,%edx
f0102e1b:	39 d1                	cmp    %edx,%ecx
f0102e1d:	74 24                	je     f0102e43 <mem_init+0x1c6e>
f0102e1f:	c7 44 24 0c c8 58 10 	movl   $0xf01058c8,0xc(%esp)
f0102e26:	f0 
f0102e27:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102e2e:	f0 
f0102e2f:	c7 44 24 04 ea 03 00 	movl   $0x3ea,0x4(%esp)
f0102e36:	00 
f0102e37:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102e3e:	e8 73 d2 ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f0102e43:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102e49:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102e4e:	74 24                	je     f0102e74 <mem_init+0x1c9f>
f0102e50:	c7 44 24 0c 49 60 10 	movl   $0xf0106049,0xc(%esp)
f0102e57:	f0 
f0102e58:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0102e5f:	f0 
f0102e60:	c7 44 24 04 ec 03 00 	movl   $0x3ec,0x4(%esp)
f0102e67:	00 
f0102e68:	c7 04 24 45 5e 10 f0 	movl   $0xf0105e45,(%esp)
f0102e6f:	e8 42 d2 ff ff       	call   f01000b6 <_panic>
	pp0->pp_ref = 0;
f0102e74:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102e7a:	89 34 24             	mov    %esi,(%esp)
f0102e7d:	e8 2d e0 ff ff       	call   f0100eaf <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102e82:	c7 04 24 e4 5d 10 f0 	movl   $0xf0105de4,(%esp)
f0102e89:	e8 98 08 00 00       	call   f0103726 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102e8e:	83 c4 3c             	add    $0x3c,%esp
f0102e91:	5b                   	pop    %ebx
f0102e92:	5e                   	pop    %esi
f0102e93:	5f                   	pop    %edi
f0102e94:	5d                   	pop    %ebp
f0102e95:	c3                   	ret    

f0102e96 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102e96:	55                   	push   %ebp
f0102e97:	89 e5                	mov    %esp,%ebp
f0102e99:	57                   	push   %edi
f0102e9a:	56                   	push   %esi
f0102e9b:	53                   	push   %ebx
f0102e9c:	83 ec 2c             	sub    $0x2c,%esp
f0102e9f:	8b 75 08             	mov    0x8(%ebp),%esi
f0102ea2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// LAB 3: Your code here.
	uintptr_t lowva = (uintptr_t)va;
	uintptr_t highva = (uintptr_t)(va+len-1);
f0102ea5:	8b 45 10             	mov    0x10(%ebp),%eax
f0102ea8:	8d 44 03 ff          	lea    -0x1(%ebx,%eax,1),%eax
f0102eac:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	perm = perm | PTE_P;
f0102eaf:	8b 7d 14             	mov    0x14(%ebp),%edi
f0102eb2:	83 cf 01             	or     $0x1,%edi
	for (uintptr_t addr = lowva; addr <= highva; addr += PGSIZE)
f0102eb5:	eb 44                	jmp    f0102efb <user_mem_check+0x65>
	{
		pte_t *pte = pgdir_walk(env->env_pgdir, (void*)addr, 0);
f0102eb7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102ebe:	00 
f0102ebf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102ec3:	8b 46 5c             	mov    0x5c(%esi),%eax
f0102ec6:	89 04 24             	mov    %eax,(%esp)
f0102ec9:	e8 44 e0 ff ff       	call   f0100f12 <pgdir_walk>
		if (addr >= ULIM || !pte || (*pte & perm) != perm)
f0102ece:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102ed4:	77 0c                	ja     f0102ee2 <user_mem_check+0x4c>
f0102ed6:	85 c0                	test   %eax,%eax
f0102ed8:	74 08                	je     f0102ee2 <user_mem_check+0x4c>
f0102eda:	8b 00                	mov    (%eax),%eax
f0102edc:	21 f8                	and    %edi,%eax
f0102ede:	39 c7                	cmp    %eax,%edi
f0102ee0:	74 0d                	je     f0102eef <user_mem_check+0x59>
		{
			user_mem_check_addr = addr;
f0102ee2:	89 1d 84 df 17 f0    	mov    %ebx,0xf017df84
			return -E_FAULT;
f0102ee8:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102eed:	eb 16                	jmp    f0102f05 <user_mem_check+0x6f>
		}
		addr = ROUNDDOWN(addr, PGSIZE);
f0102eef:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
{
	// LAB 3: Your code here.
	uintptr_t lowva = (uintptr_t)va;
	uintptr_t highva = (uintptr_t)(va+len-1);
	perm = perm | PTE_P;
	for (uintptr_t addr = lowva; addr <= highva; addr += PGSIZE)
f0102ef5:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102efb:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102efe:	76 b7                	jbe    f0102eb7 <user_mem_check+0x21>
			user_mem_check_addr = addr;
			return -E_FAULT;
		}
		addr = ROUNDDOWN(addr, PGSIZE);
	}
	return 0;
f0102f00:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102f05:	83 c4 2c             	add    $0x2c,%esp
f0102f08:	5b                   	pop    %ebx
f0102f09:	5e                   	pop    %esi
f0102f0a:	5f                   	pop    %edi
f0102f0b:	5d                   	pop    %ebp
f0102f0c:	c3                   	ret    

f0102f0d <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102f0d:	55                   	push   %ebp
f0102f0e:	89 e5                	mov    %esp,%ebp
f0102f10:	53                   	push   %ebx
f0102f11:	83 ec 14             	sub    $0x14,%esp
f0102f14:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102f17:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f1a:	83 c8 04             	or     $0x4,%eax
f0102f1d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102f21:	8b 45 10             	mov    0x10(%ebp),%eax
f0102f24:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102f28:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f2b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f2f:	89 1c 24             	mov    %ebx,(%esp)
f0102f32:	e8 5f ff ff ff       	call   f0102e96 <user_mem_check>
f0102f37:	85 c0                	test   %eax,%eax
f0102f39:	79 24                	jns    f0102f5f <user_mem_assert+0x52>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102f3b:	a1 84 df 17 f0       	mov    0xf017df84,%eax
f0102f40:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102f44:	8b 43 48             	mov    0x48(%ebx),%eax
f0102f47:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f4b:	c7 04 24 10 5e 10 f0 	movl   $0xf0105e10,(%esp)
f0102f52:	e8 cf 07 00 00       	call   f0103726 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102f57:	89 1c 24             	mov    %ebx,(%esp)
f0102f5a:	e8 aa 06 00 00       	call   f0103609 <env_destroy>
	}
}
f0102f5f:	83 c4 14             	add    $0x14,%esp
f0102f62:	5b                   	pop    %ebx
f0102f63:	5d                   	pop    %ebp
f0102f64:	c3                   	ret    
f0102f65:	00 00                	add    %al,(%eax)
	...

f0102f68 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102f68:	55                   	push   %ebp
f0102f69:	89 e5                	mov    %esp,%ebp
f0102f6b:	57                   	push   %edi
f0102f6c:	56                   	push   %esi
f0102f6d:	53                   	push   %ebx
f0102f6e:	83 ec 1c             	sub    $0x1c,%esp
f0102f71:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	va = ROUNDDOWN(va, PGSIZE);
f0102f73:	89 d6                	mov    %edx,%esi
f0102f75:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	len = ROUNDUP(len, PGSIZE);
f0102f7b:	8d 99 ff 0f 00 00    	lea    0xfff(%ecx),%ebx
f0102f81:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	while(len > 0)
f0102f87:	eb 73                	jmp    f0102ffc <region_alloc+0x94>
	{
		struct PageInfo *pp = page_alloc(0);
f0102f89:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102f90:	e8 96 de ff ff       	call   f0100e2b <page_alloc>
		if (!pp)
f0102f95:	85 c0                	test   %eax,%eax
f0102f97:	75 1c                	jne    f0102fb5 <region_alloc+0x4d>
			panic("page_alloc failed in region_alloc");
f0102f99:	c7 44 24 08 50 61 10 	movl   $0xf0106150,0x8(%esp)
f0102fa0:	f0 
f0102fa1:	c7 44 24 04 1f 01 00 	movl   $0x11f,0x4(%esp)
f0102fa8:	00 
f0102fa9:	c7 04 24 16 62 10 f0 	movl   $0xf0106216,(%esp)
f0102fb0:	e8 01 d1 ff ff       	call   f01000b6 <_panic>
		if (page_insert(e->env_pgdir, pp, va, PTE_W|PTE_U))
f0102fb5:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0102fbc:	00 
f0102fbd:	89 74 24 08          	mov    %esi,0x8(%esp)
f0102fc1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102fc5:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102fc8:	89 04 24             	mov    %eax,(%esp)
f0102fcb:	e8 5b e1 ff ff       	call   f010112b <page_insert>
f0102fd0:	85 c0                	test   %eax,%eax
f0102fd2:	74 1c                	je     f0102ff0 <region_alloc+0x88>
			panic("page_insert failed in region_alloc");
f0102fd4:	c7 44 24 08 74 61 10 	movl   $0xf0106174,0x8(%esp)
f0102fdb:	f0 
f0102fdc:	c7 44 24 04 21 01 00 	movl   $0x121,0x4(%esp)
f0102fe3:	00 
f0102fe4:	c7 04 24 16 62 10 f0 	movl   $0xf0106216,(%esp)
f0102feb:	e8 c6 d0 ff ff       	call   f01000b6 <_panic>
		va += PGSIZE;
f0102ff0:	81 c6 00 10 00 00    	add    $0x1000,%esi
		len -= PGSIZE;
f0102ff6:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	va = ROUNDDOWN(va, PGSIZE);
	len = ROUNDUP(len, PGSIZE);
	while(len > 0)
f0102ffc:	85 db                	test   %ebx,%ebx
f0102ffe:	75 89                	jne    f0102f89 <region_alloc+0x21>
		if (page_insert(e->env_pgdir, pp, va, PTE_W|PTE_U))
			panic("page_insert failed in region_alloc");
		va += PGSIZE;
		len -= PGSIZE;
	}
}
f0103000:	83 c4 1c             	add    $0x1c,%esp
f0103003:	5b                   	pop    %ebx
f0103004:	5e                   	pop    %esi
f0103005:	5f                   	pop    %edi
f0103006:	5d                   	pop    %ebp
f0103007:	c3                   	ret    

f0103008 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0103008:	55                   	push   %ebp
f0103009:	89 e5                	mov    %esp,%ebp
f010300b:	53                   	push   %ebx
f010300c:	8b 45 08             	mov    0x8(%ebp),%eax
f010300f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103012:	0f b6 5d 10          	movzbl 0x10(%ebp),%ebx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0103016:	85 c0                	test   %eax,%eax
f0103018:	75 0e                	jne    f0103028 <envid2env+0x20>
		*env_store = curenv;
f010301a:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f010301f:	89 01                	mov    %eax,(%ecx)
		return 0;
f0103021:	b8 00 00 00 00       	mov    $0x0,%eax
f0103026:	eb 55                	jmp    f010307d <envid2env+0x75>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0103028:	89 c2                	mov    %eax,%edx
f010302a:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0103030:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103033:	c1 e2 05             	shl    $0x5,%edx
f0103036:	03 15 8c df 17 f0    	add    0xf017df8c,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f010303c:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f0103040:	74 05                	je     f0103047 <envid2env+0x3f>
f0103042:	39 42 48             	cmp    %eax,0x48(%edx)
f0103045:	74 0d                	je     f0103054 <envid2env+0x4c>
		*env_store = 0;
f0103047:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		return -E_BAD_ENV;
f010304d:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103052:	eb 29                	jmp    f010307d <envid2env+0x75>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103054:	84 db                	test   %bl,%bl
f0103056:	74 1e                	je     f0103076 <envid2env+0x6e>
f0103058:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f010305d:	39 c2                	cmp    %eax,%edx
f010305f:	74 15                	je     f0103076 <envid2env+0x6e>
f0103061:	8b 58 48             	mov    0x48(%eax),%ebx
f0103064:	39 5a 4c             	cmp    %ebx,0x4c(%edx)
f0103067:	74 0d                	je     f0103076 <envid2env+0x6e>
		*env_store = 0;
f0103069:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		return -E_BAD_ENV;
f010306f:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103074:	eb 07                	jmp    f010307d <envid2env+0x75>
	}

	*env_store = e;
f0103076:	89 11                	mov    %edx,(%ecx)
	return 0;
f0103078:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010307d:	5b                   	pop    %ebx
f010307e:	5d                   	pop    %ebp
f010307f:	c3                   	ret    

f0103080 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0103080:	55                   	push   %ebp
f0103081:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f0103083:	b8 00 c3 11 f0       	mov    $0xf011c300,%eax
f0103088:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f010308b:	b8 23 00 00 00       	mov    $0x23,%eax
f0103090:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0103092:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0103094:	b0 10                	mov    $0x10,%al
f0103096:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0103098:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f010309a:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f010309c:	ea a3 30 10 f0 08 00 	ljmp   $0x8,$0xf01030a3
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f01030a3:	b0 00                	mov    $0x0,%al
f01030a5:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01030a8:	5d                   	pop    %ebp
f01030a9:	c3                   	ret    

f01030aa <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01030aa:	55                   	push   %ebp
f01030ab:	89 e5                	mov    %esp,%ebp
f01030ad:	56                   	push   %esi
f01030ae:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	env_free_list = NULL;
	for (int i = NENV-1; i >= 0; --i)
	{
		envs[i].env_status = ENV_FREE;
f01030af:	8b 35 8c df 17 f0    	mov    0xf017df8c,%esi
// Make sure the environments are in the free list in the same order
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
f01030b5:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f01030bb:	b9 00 00 00 00       	mov    $0x0,%ecx
{
	// Set up envs array
	// LAB 3: Your code here.
	env_free_list = NULL;
	for (int i = NENV-1; i >= 0; --i)
f01030c0:	ba ff 03 00 00       	mov    $0x3ff,%edx
f01030c5:	eb 02                	jmp    f01030c9 <env_init+0x1f>
	{
		envs[i].env_status = ENV_FREE;
		envs[i].env_id = 0;
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
f01030c7:	89 d9                	mov    %ebx,%ecx
	// Set up envs array
	// LAB 3: Your code here.
	env_free_list = NULL;
	for (int i = NENV-1; i >= 0; --i)
	{
		envs[i].env_status = ENV_FREE;
f01030c9:	89 c3                	mov    %eax,%ebx
f01030cb:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_id = 0;
f01030d2:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f01030d9:	89 48 44             	mov    %ecx,0x44(%eax)
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	env_free_list = NULL;
	for (int i = NENV-1; i >= 0; --i)
f01030dc:	83 ea 01             	sub    $0x1,%edx
f01030df:	83 e8 60             	sub    $0x60,%eax
f01030e2:	83 fa ff             	cmp    $0xffffffff,%edx
f01030e5:	75 e0                	jne    f01030c7 <env_init+0x1d>
f01030e7:	89 35 90 df 17 f0    	mov    %esi,0xf017df90
		envs[i].env_id = 0;
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f01030ed:	e8 8e ff ff ff       	call   f0103080 <env_init_percpu>
}
f01030f2:	5b                   	pop    %ebx
f01030f3:	5e                   	pop    %esi
f01030f4:	5d                   	pop    %ebp
f01030f5:	c3                   	ret    

f01030f6 <env_alloc>:
//	-E_NO_FREE_ENV if all NENV environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01030f6:	55                   	push   %ebp
f01030f7:	89 e5                	mov    %esp,%ebp
f01030f9:	53                   	push   %ebx
f01030fa:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01030fd:	8b 1d 90 df 17 f0    	mov    0xf017df90,%ebx
f0103103:	85 db                	test   %ebx,%ebx
f0103105:	0f 84 86 01 00 00    	je     f0103291 <env_alloc+0x19b>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f010310b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0103112:	e8 14 dd ff ff       	call   f0100e2b <page_alloc>
f0103117:	85 c0                	test   %eax,%eax
f0103119:	0f 84 79 01 00 00    	je     f0103298 <env_alloc+0x1a2>
f010311f:	89 c2                	mov    %eax,%edx
f0103121:	2b 15 2c ec 17 f0    	sub    0xf017ec2c,%edx
f0103127:	c1 fa 03             	sar    $0x3,%edx
f010312a:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010312d:	89 d1                	mov    %edx,%ecx
f010312f:	c1 e9 0c             	shr    $0xc,%ecx
f0103132:	3b 0d 24 ec 17 f0    	cmp    0xf017ec24,%ecx
f0103138:	72 20                	jb     f010315a <env_alloc+0x64>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010313a:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010313e:	c7 44 24 08 64 56 10 	movl   $0xf0105664,0x8(%esp)
f0103145:	f0 
f0103146:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010314d:	00 
f010314e:	c7 04 24 61 5e 10 f0 	movl   $0xf0105e61,(%esp)
f0103155:	e8 5c cf ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f010315a:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0103160:	89 53 5c             	mov    %edx,0x5c(%ebx)
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir = page2kva(p);
	p->pp_ref++;
f0103163:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f0103168:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010316f:	00 
f0103170:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
f0103175:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103179:	8b 43 5c             	mov    0x5c(%ebx),%eax
f010317c:	89 04 24             	mov    %eax,(%esp)
f010317f:	e8 93 1b 00 00       	call   f0104d17 <memcpy>
	memset(e->env_pgdir, 0, sizeof(pde_t)*PDX(UTOP));
f0103184:	c7 44 24 08 ec 0e 00 	movl   $0xeec,0x8(%esp)
f010318b:	00 
f010318c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103193:	00 
f0103194:	8b 43 5c             	mov    0x5c(%ebx),%eax
f0103197:	89 04 24             	mov    %eax,(%esp)
f010319a:	e8 a4 1a 00 00       	call   f0104c43 <memset>

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f010319f:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031a2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031a7:	77 20                	ja     f01031c9 <env_alloc+0xd3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031a9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01031ad:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f01031b4:	f0 
f01031b5:	c7 44 24 04 c4 00 00 	movl   $0xc4,0x4(%esp)
f01031bc:	00 
f01031bd:	c7 04 24 16 62 10 f0 	movl   $0xf0106216,(%esp)
f01031c4:	e8 ed ce ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01031c9:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01031cf:	83 ca 05             	or     $0x5,%edx
f01031d2:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01031d8:	8b 43 48             	mov    0x48(%ebx),%eax
f01031db:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01031e0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01031e5:	ba 00 10 00 00       	mov    $0x1000,%edx
f01031ea:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01031ed:	89 da                	mov    %ebx,%edx
f01031ef:	2b 15 8c df 17 f0    	sub    0xf017df8c,%edx
f01031f5:	c1 fa 05             	sar    $0x5,%edx
f01031f8:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01031fe:	09 d0                	or     %edx,%eax
f0103200:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103203:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103206:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103209:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103210:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0103217:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010321e:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0103225:	00 
f0103226:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010322d:	00 
f010322e:	89 1c 24             	mov    %ebx,(%esp)
f0103231:	e8 0d 1a 00 00       	call   f0104c43 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103236:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f010323c:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103242:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103248:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f010324f:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0103255:	8b 43 44             	mov    0x44(%ebx),%eax
f0103258:	a3 90 df 17 f0       	mov    %eax,0xf017df90
	*newenv_store = e;
f010325d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103260:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103262:	8b 4b 48             	mov    0x48(%ebx),%ecx
f0103265:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f010326a:	ba 00 00 00 00       	mov    $0x0,%edx
f010326f:	85 c0                	test   %eax,%eax
f0103271:	74 03                	je     f0103276 <env_alloc+0x180>
f0103273:	8b 50 48             	mov    0x48(%eax),%edx
f0103276:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010327a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010327e:	c7 04 24 21 62 10 f0 	movl   $0xf0106221,(%esp)
f0103285:	e8 9c 04 00 00       	call   f0103726 <cprintf>
	return 0;
f010328a:	b8 00 00 00 00       	mov    $0x0,%eax
f010328f:	eb 0c                	jmp    f010329d <env_alloc+0x1a7>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103291:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103296:	eb 05                	jmp    f010329d <env_alloc+0x1a7>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103298:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f010329d:	83 c4 14             	add    $0x14,%esp
f01032a0:	5b                   	pop    %ebx
f01032a1:	5d                   	pop    %ebp
f01032a2:	c3                   	ret    

f01032a3 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f01032a3:	55                   	push   %ebp
f01032a4:	89 e5                	mov    %esp,%ebp
f01032a6:	57                   	push   %edi
f01032a7:	56                   	push   %esi
f01032a8:	53                   	push   %ebx
f01032a9:	83 ec 3c             	sub    $0x3c,%esp
f01032ac:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	if (env_alloc(&e, 0) < 0)
f01032af:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01032b6:	00 
f01032b7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01032ba:	89 04 24             	mov    %eax,(%esp)
f01032bd:	e8 34 fe ff ff       	call   f01030f6 <env_alloc>
f01032c2:	85 c0                	test   %eax,%eax
f01032c4:	79 1c                	jns    f01032e2 <env_create+0x3f>
		panic("env_create failed");
f01032c6:	c7 44 24 08 36 62 10 	movl   $0xf0106236,0x8(%esp)
f01032cd:	f0 
f01032ce:	c7 44 24 04 85 01 00 	movl   $0x185,0x4(%esp)
f01032d5:	00 
f01032d6:	c7 04 24 16 62 10 f0 	movl   $0xf0106216,(%esp)
f01032dd:	e8 d4 cd ff ff       	call   f01000b6 <_panic>
	load_icode(e, binary);
f01032e2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032e5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	struct Elf* ELFHDR = (struct Elf*)binary;
	struct Proghdr *ph, *eph;
	if (ELFHDR->e_magic != ELF_MAGIC)
f01032e8:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01032ee:	74 1c                	je     f010330c <env_create+0x69>
		panic("user program format is not ELF");
f01032f0:	c7 44 24 08 98 61 10 	movl   $0xf0106198,0x8(%esp)
f01032f7:	f0 
f01032f8:	c7 44 24 04 60 01 00 	movl   $0x160,0x4(%esp)
f01032ff:	00 
f0103300:	c7 04 24 16 62 10 f0 	movl   $0xf0106216,(%esp)
f0103307:	e8 aa cd ff ff       	call   f01000b6 <_panic>
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
f010330c:	89 fb                	mov    %edi,%ebx
f010330e:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + ELFHDR->e_phnum;
f0103311:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103315:	c1 e6 05             	shl    $0x5,%esi
f0103318:	01 de                	add    %ebx,%esi
	lcr3(PADDR(e->env_pgdir));
f010331a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010331d:	8b 42 5c             	mov    0x5c(%edx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103320:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103325:	77 20                	ja     f0103347 <env_create+0xa4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103327:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010332b:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f0103332:	f0 
f0103333:	c7 44 24 04 63 01 00 	movl   $0x163,0x4(%esp)
f010333a:	00 
f010333b:	c7 04 24 16 62 10 f0 	movl   $0xf0106216,(%esp)
f0103342:	e8 6f cd ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103347:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010334c:	0f 22 d8             	mov    %eax,%cr3
f010334f:	eb 6c                	jmp    f01033bd <env_create+0x11a>
	for (; ph < eph; ph++)
	{
		if (ph->p_type == ELF_PROG_LOAD)
f0103351:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103354:	75 64                	jne    f01033ba <env_create+0x117>
		{
			if (ph->p_filesz > ph->p_memsz)
f0103356:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103359:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f010335c:	76 1c                	jbe    f010337a <env_create+0xd7>
				panic("p_filesz > p_memsz, load_icode failed");
f010335e:	c7 44 24 08 b8 61 10 	movl   $0xf01061b8,0x8(%esp)
f0103365:	f0 
f0103366:	c7 44 24 04 69 01 00 	movl   $0x169,0x4(%esp)
f010336d:	00 
f010336e:	c7 04 24 16 62 10 f0 	movl   $0xf0106216,(%esp)
f0103375:	e8 3c cd ff ff       	call   f01000b6 <_panic>
			region_alloc(e, (void*)ph->p_va, ph->p_memsz);
f010337a:	8b 53 08             	mov    0x8(%ebx),%edx
f010337d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103380:	e8 e3 fb ff ff       	call   f0102f68 <region_alloc>
			memset((void*)ph->p_va, 0, ph->p_memsz);
f0103385:	8b 43 14             	mov    0x14(%ebx),%eax
f0103388:	89 44 24 08          	mov    %eax,0x8(%esp)
f010338c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103393:	00 
f0103394:	8b 43 08             	mov    0x8(%ebx),%eax
f0103397:	89 04 24             	mov    %eax,(%esp)
f010339a:	e8 a4 18 00 00       	call   f0104c43 <memset>
			memcpy((void*)ph->p_va, binary+ph->p_offset, ph->p_filesz);
f010339f:	8b 43 10             	mov    0x10(%ebx),%eax
f01033a2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01033a6:	89 f8                	mov    %edi,%eax
f01033a8:	03 43 04             	add    0x4(%ebx),%eax
f01033ab:	89 44 24 04          	mov    %eax,0x4(%esp)
f01033af:	8b 43 08             	mov    0x8(%ebx),%eax
f01033b2:	89 04 24             	mov    %eax,(%esp)
f01033b5:	e8 5d 19 00 00       	call   f0104d17 <memcpy>
	if (ELFHDR->e_magic != ELF_MAGIC)
		panic("user program format is not ELF");
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;
	lcr3(PADDR(e->env_pgdir));
	for (; ph < eph; ph++)
f01033ba:	83 c3 20             	add    $0x20,%ebx
f01033bd:	39 de                	cmp    %ebx,%esi
f01033bf:	77 90                	ja     f0103351 <env_create+0xae>
			region_alloc(e, (void*)ph->p_va, ph->p_memsz);
			memset((void*)ph->p_va, 0, ph->p_memsz);
			memcpy((void*)ph->p_va, binary+ph->p_offset, ph->p_filesz);
		}
	}
	lcr3(PADDR(kern_pgdir));
f01033c1:	a1 28 ec 17 f0       	mov    0xf017ec28,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01033c6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033cb:	77 20                	ja     f01033ed <env_create+0x14a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033cd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01033d1:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f01033d8:	f0 
f01033d9:	c7 44 24 04 6f 01 00 	movl   $0x16f,0x4(%esp)
f01033e0:	00 
f01033e1:	c7 04 24 16 62 10 f0 	movl   $0xf0106216,(%esp)
f01033e8:	e8 c9 cc ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01033ed:	05 00 00 00 10       	add    $0x10000000,%eax
f01033f2:	0f 22 d8             	mov    %eax,%cr3
	e->env_tf.tf_eip = ELFHDR->e_entry;
f01033f5:	8b 47 18             	mov    0x18(%edi),%eax
f01033f8:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01033fb:	89 42 30             	mov    %eax,0x30(%edx)

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	// LAB 3: Your code here.
	region_alloc(e, (void*)(USTACKTOP-PGSIZE), PGSIZE);
f01033fe:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103403:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103408:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010340b:	e8 58 fb ff ff       	call   f0102f68 <region_alloc>
	// LAB 3: Your code here.
	struct Env *e;
	if (env_alloc(&e, 0) < 0)
		panic("env_create failed");
	load_icode(e, binary);
	e->env_type = type;
f0103410:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103413:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103416:	89 50 50             	mov    %edx,0x50(%eax)
}
f0103419:	83 c4 3c             	add    $0x3c,%esp
f010341c:	5b                   	pop    %ebx
f010341d:	5e                   	pop    %esi
f010341e:	5f                   	pop    %edi
f010341f:	5d                   	pop    %ebp
f0103420:	c3                   	ret    

f0103421 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103421:	55                   	push   %ebp
f0103422:	89 e5                	mov    %esp,%ebp
f0103424:	57                   	push   %edi
f0103425:	56                   	push   %esi
f0103426:	53                   	push   %ebx
f0103427:	83 ec 2c             	sub    $0x2c,%esp
f010342a:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f010342d:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0103432:	39 c7                	cmp    %eax,%edi
f0103434:	75 37                	jne    f010346d <env_free+0x4c>
		lcr3(PADDR(kern_pgdir));
f0103436:	8b 15 28 ec 17 f0    	mov    0xf017ec28,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010343c:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103442:	77 20                	ja     f0103464 <env_free+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103444:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103448:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f010344f:	f0 
f0103450:	c7 44 24 04 98 01 00 	movl   $0x198,0x4(%esp)
f0103457:	00 
f0103458:	c7 04 24 16 62 10 f0 	movl   $0xf0106216,(%esp)
f010345f:	e8 52 cc ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103464:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f010346a:	0f 22 da             	mov    %edx,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010346d:	8b 4f 48             	mov    0x48(%edi),%ecx
f0103470:	ba 00 00 00 00       	mov    $0x0,%edx
f0103475:	85 c0                	test   %eax,%eax
f0103477:	74 03                	je     f010347c <env_free+0x5b>
f0103479:	8b 50 48             	mov    0x48(%eax),%edx
f010347c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103480:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103484:	c7 04 24 48 62 10 f0 	movl   $0xf0106248,(%esp)
f010348b:	e8 96 02 00 00       	call   f0103726 <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103490:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103497:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010349a:	c1 e0 02             	shl    $0x2,%eax
f010349d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01034a0:	8b 47 5c             	mov    0x5c(%edi),%eax
f01034a3:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01034a6:	8b 34 90             	mov    (%eax,%edx,4),%esi
f01034a9:	f7 c6 01 00 00 00    	test   $0x1,%esi
f01034af:	0f 84 b8 00 00 00    	je     f010356d <env_free+0x14c>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01034b5:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01034bb:	89 f0                	mov    %esi,%eax
f01034bd:	c1 e8 0c             	shr    $0xc,%eax
f01034c0:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01034c3:	3b 05 24 ec 17 f0    	cmp    0xf017ec24,%eax
f01034c9:	72 20                	jb     f01034eb <env_free+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01034cb:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01034cf:	c7 44 24 08 64 56 10 	movl   $0xf0105664,0x8(%esp)
f01034d6:	f0 
f01034d7:	c7 44 24 04 a7 01 00 	movl   $0x1a7,0x4(%esp)
f01034de:	00 
f01034df:	c7 04 24 16 62 10 f0 	movl   $0xf0106216,(%esp)
f01034e6:	e8 cb cb ff ff       	call   f01000b6 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01034eb:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01034ee:	c1 e2 16             	shl    $0x16,%edx
f01034f1:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01034f4:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01034f9:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103500:	01 
f0103501:	74 17                	je     f010351a <env_free+0xf9>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103503:	89 d8                	mov    %ebx,%eax
f0103505:	c1 e0 0c             	shl    $0xc,%eax
f0103508:	0b 45 e4             	or     -0x1c(%ebp),%eax
f010350b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010350f:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103512:	89 04 24             	mov    %eax,(%esp)
f0103515:	e8 c1 db ff ff       	call   f01010db <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010351a:	83 c3 01             	add    $0x1,%ebx
f010351d:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103523:	75 d4                	jne    f01034f9 <env_free+0xd8>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103525:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103528:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010352b:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103532:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103535:	3b 05 24 ec 17 f0    	cmp    0xf017ec24,%eax
f010353b:	72 1c                	jb     f0103559 <env_free+0x138>
		panic("pa2page called with invalid pa");
f010353d:	c7 44 24 08 94 57 10 	movl   $0xf0105794,0x8(%esp)
f0103544:	f0 
f0103545:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f010354c:	00 
f010354d:	c7 04 24 61 5e 10 f0 	movl   $0xf0105e61,(%esp)
f0103554:	e8 5d cb ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f0103559:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010355c:	c1 e0 03             	shl    $0x3,%eax
f010355f:	03 05 2c ec 17 f0    	add    0xf017ec2c,%eax
		page_decref(pa2page(pa));
f0103565:	89 04 24             	mov    %eax,(%esp)
f0103568:	e8 82 d9 ff ff       	call   f0100eef <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010356d:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103571:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0103578:	0f 85 19 ff ff ff    	jne    f0103497 <env_free+0x76>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f010357e:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103581:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103586:	77 20                	ja     f01035a8 <env_free+0x187>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103588:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010358c:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f0103593:	f0 
f0103594:	c7 44 24 04 b5 01 00 	movl   $0x1b5,0x4(%esp)
f010359b:	00 
f010359c:	c7 04 24 16 62 10 f0 	movl   $0xf0106216,(%esp)
f01035a3:	e8 0e cb ff ff       	call   f01000b6 <_panic>
	e->env_pgdir = 0;
f01035a8:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f01035af:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01035b4:	c1 e8 0c             	shr    $0xc,%eax
f01035b7:	3b 05 24 ec 17 f0    	cmp    0xf017ec24,%eax
f01035bd:	72 1c                	jb     f01035db <env_free+0x1ba>
		panic("pa2page called with invalid pa");
f01035bf:	c7 44 24 08 94 57 10 	movl   $0xf0105794,0x8(%esp)
f01035c6:	f0 
f01035c7:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f01035ce:	00 
f01035cf:	c7 04 24 61 5e 10 f0 	movl   $0xf0105e61,(%esp)
f01035d6:	e8 db ca ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f01035db:	c1 e0 03             	shl    $0x3,%eax
f01035de:	03 05 2c ec 17 f0    	add    0xf017ec2c,%eax
	page_decref(pa2page(pa));
f01035e4:	89 04 24             	mov    %eax,(%esp)
f01035e7:	e8 03 d9 ff ff       	call   f0100eef <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f01035ec:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f01035f3:	a1 90 df 17 f0       	mov    0xf017df90,%eax
f01035f8:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f01035fb:	89 3d 90 df 17 f0    	mov    %edi,0xf017df90
}
f0103601:	83 c4 2c             	add    $0x2c,%esp
f0103604:	5b                   	pop    %ebx
f0103605:	5e                   	pop    %esi
f0103606:	5f                   	pop    %edi
f0103607:	5d                   	pop    %ebp
f0103608:	c3                   	ret    

f0103609 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0103609:	55                   	push   %ebp
f010360a:	89 e5                	mov    %esp,%ebp
f010360c:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f010360f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103612:	89 04 24             	mov    %eax,(%esp)
f0103615:	e8 07 fe ff ff       	call   f0103421 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f010361a:	c7 04 24 e0 61 10 f0 	movl   $0xf01061e0,(%esp)
f0103621:	e8 00 01 00 00       	call   f0103726 <cprintf>
	while (1)
		monitor(NULL);
f0103626:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010362d:	e8 c3 d1 ff ff       	call   f01007f5 <monitor>
f0103632:	eb f2                	jmp    f0103626 <env_destroy+0x1d>

f0103634 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103634:	55                   	push   %ebp
f0103635:	89 e5                	mov    %esp,%ebp
f0103637:	83 ec 18             	sub    $0x18,%esp
	asm volatile(
f010363a:	8b 65 08             	mov    0x8(%ebp),%esp
f010363d:	61                   	popa   
f010363e:	07                   	pop    %es
f010363f:	1f                   	pop    %ds
f0103640:	83 c4 08             	add    $0x8,%esp
f0103643:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103644:	c7 44 24 08 5e 62 10 	movl   $0xf010625e,0x8(%esp)
f010364b:	f0 
f010364c:	c7 44 24 04 de 01 00 	movl   $0x1de,0x4(%esp)
f0103653:	00 
f0103654:	c7 04 24 16 62 10 f0 	movl   $0xf0106216,(%esp)
f010365b:	e8 56 ca ff ff       	call   f01000b6 <_panic>

f0103660 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103660:	55                   	push   %ebp
f0103661:	89 e5                	mov    %esp,%ebp
f0103663:	83 ec 18             	sub    $0x18,%esp
f0103666:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if (curenv && curenv->env_status == ENV_RUNNING)
		curenv->env_status == ENV_RUNNABLE;
	curenv = e;
f0103669:	a3 88 df 17 f0       	mov    %eax,0xf017df88
	curenv->env_status = ENV_RUNNING;
f010366e:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f0103675:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(curenv->env_pgdir));
f0103679:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010367c:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103682:	77 20                	ja     f01036a4 <env_run+0x44>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103684:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103688:	c7 44 24 08 70 57 10 	movl   $0xf0105770,0x8(%esp)
f010368f:	f0 
f0103690:	c7 44 24 04 01 02 00 	movl   $0x201,0x4(%esp)
f0103697:	00 
f0103698:	c7 04 24 16 62 10 f0 	movl   $0xf0106216,(%esp)
f010369f:	e8 12 ca ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01036a4:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f01036aa:	0f 22 da             	mov    %edx,%cr3
	env_pop_tf(&(curenv->env_tf));
f01036ad:	89 04 24             	mov    %eax,(%esp)
f01036b0:	e8 7f ff ff ff       	call   f0103634 <env_pop_tf>
f01036b5:	00 00                	add    %al,(%eax)
	...

f01036b8 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01036b8:	55                   	push   %ebp
f01036b9:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01036bb:	ba 70 00 00 00       	mov    $0x70,%edx
f01036c0:	8b 45 08             	mov    0x8(%ebp),%eax
f01036c3:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01036c4:	b2 71                	mov    $0x71,%dl
f01036c6:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01036c7:	0f b6 c0             	movzbl %al,%eax
}
f01036ca:	5d                   	pop    %ebp
f01036cb:	c3                   	ret    

f01036cc <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01036cc:	55                   	push   %ebp
f01036cd:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01036cf:	ba 70 00 00 00       	mov    $0x70,%edx
f01036d4:	8b 45 08             	mov    0x8(%ebp),%eax
f01036d7:	ee                   	out    %al,(%dx)
f01036d8:	b2 71                	mov    $0x71,%dl
f01036da:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036dd:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01036de:	5d                   	pop    %ebp
f01036df:	c3                   	ret    

f01036e0 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01036e0:	55                   	push   %ebp
f01036e1:	89 e5                	mov    %esp,%ebp
f01036e3:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01036e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01036e9:	89 04 24             	mov    %eax,(%esp)
f01036ec:	e8 1b cf ff ff       	call   f010060c <cputchar>
	*cnt++;
}
f01036f1:	c9                   	leave  
f01036f2:	c3                   	ret    

f01036f3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01036f3:	55                   	push   %ebp
f01036f4:	89 e5                	mov    %esp,%ebp
f01036f6:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01036f9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103700:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103703:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103707:	8b 45 08             	mov    0x8(%ebp),%eax
f010370a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010370e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103711:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103715:	c7 04 24 e0 36 10 f0 	movl   $0xf01036e0,(%esp)
f010371c:	e8 8c 0e 00 00       	call   f01045ad <vprintfmt>
	return cnt;
}
f0103721:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103724:	c9                   	leave  
f0103725:	c3                   	ret    

f0103726 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103726:	55                   	push   %ebp
f0103727:	89 e5                	mov    %esp,%ebp
f0103729:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010372c:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010372f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103733:	8b 45 08             	mov    0x8(%ebp),%eax
f0103736:	89 04 24             	mov    %eax,(%esp)
f0103739:	e8 b5 ff ff ff       	call   f01036f3 <vcprintf>
	va_end(ap);

	return cnt;
}
f010373e:	c9                   	leave  
f010373f:	c3                   	ret    

f0103740 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103740:	55                   	push   %ebp
f0103741:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103743:	c7 05 a4 e7 17 f0 00 	movl   $0xf0000000,0xf017e7a4
f010374a:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f010374d:	66 c7 05 a8 e7 17 f0 	movw   $0x10,0xf017e7a8
f0103754:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
f0103756:	66 c7 05 06 e8 17 f0 	movw   $0x68,0xf017e806
f010375d:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f010375f:	66 c7 05 48 c3 11 f0 	movw   $0x67,0xf011c348
f0103766:	67 00 
f0103768:	b8 a0 e7 17 f0       	mov    $0xf017e7a0,%eax
f010376d:	66 a3 4a c3 11 f0    	mov    %ax,0xf011c34a
f0103773:	89 c2                	mov    %eax,%edx
f0103775:	c1 ea 10             	shr    $0x10,%edx
f0103778:	88 15 4c c3 11 f0    	mov    %dl,0xf011c34c
f010377e:	c6 05 4e c3 11 f0 40 	movb   $0x40,0xf011c34e
f0103785:	c1 e8 18             	shr    $0x18,%eax
f0103788:	a2 4f c3 11 f0       	mov    %al,0xf011c34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f010378d:	c6 05 4d c3 11 f0 89 	movb   $0x89,0xf011c34d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0103794:	b8 28 00 00 00       	mov    $0x28,%eax
f0103799:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f010379c:	b8 50 c3 11 f0       	mov    $0xf011c350,%eax
f01037a1:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f01037a4:	5d                   	pop    %ebp
f01037a5:	c3                   	ret    

f01037a6 <trap_init>:
}


void
trap_init(void)
{
f01037a6:	55                   	push   %ebp
f01037a7:	89 e5                	mov    %esp,%ebp
	extern void fperr();
	extern void align();
	extern void mchk();
	extern void simderr();
	extern void systemcall();
	SETGATE(idt[T_DIVIDE], 0, GD_KT, divide, 0);
f01037a9:	b8 e4 3e 10 f0       	mov    $0xf0103ee4,%eax
f01037ae:	66 a3 a0 df 17 f0    	mov    %ax,0xf017dfa0
f01037b4:	66 c7 05 a2 df 17 f0 	movw   $0x8,0xf017dfa2
f01037bb:	08 00 
f01037bd:	c6 05 a4 df 17 f0 00 	movb   $0x0,0xf017dfa4
f01037c4:	c6 05 a5 df 17 f0 8e 	movb   $0x8e,0xf017dfa5
f01037cb:	c1 e8 10             	shr    $0x10,%eax
f01037ce:	66 a3 a6 df 17 f0    	mov    %ax,0xf017dfa6
	SETGATE(idt[T_DEBUG], 0, GD_KT, debug, 0);
f01037d4:	b8 ea 3e 10 f0       	mov    $0xf0103eea,%eax
f01037d9:	66 a3 a8 df 17 f0    	mov    %ax,0xf017dfa8
f01037df:	66 c7 05 aa df 17 f0 	movw   $0x8,0xf017dfaa
f01037e6:	08 00 
f01037e8:	c6 05 ac df 17 f0 00 	movb   $0x0,0xf017dfac
f01037ef:	c6 05 ad df 17 f0 8e 	movb   $0x8e,0xf017dfad
f01037f6:	c1 e8 10             	shr    $0x10,%eax
f01037f9:	66 a3 ae df 17 f0    	mov    %ax,0xf017dfae
	SETGATE(idt[T_NMI], 0, GD_KT, nmi, 0);
f01037ff:	b8 f0 3e 10 f0       	mov    $0xf0103ef0,%eax
f0103804:	66 a3 b0 df 17 f0    	mov    %ax,0xf017dfb0
f010380a:	66 c7 05 b2 df 17 f0 	movw   $0x8,0xf017dfb2
f0103811:	08 00 
f0103813:	c6 05 b4 df 17 f0 00 	movb   $0x0,0xf017dfb4
f010381a:	c6 05 b5 df 17 f0 8e 	movb   $0x8e,0xf017dfb5
f0103821:	c1 e8 10             	shr    $0x10,%eax
f0103824:	66 a3 b6 df 17 f0    	mov    %ax,0xf017dfb6
	SETGATE(idt[T_BRKPT], 0, GD_KT, brkpt, 3);
f010382a:	b8 f6 3e 10 f0       	mov    $0xf0103ef6,%eax
f010382f:	66 a3 b8 df 17 f0    	mov    %ax,0xf017dfb8
f0103835:	66 c7 05 ba df 17 f0 	movw   $0x8,0xf017dfba
f010383c:	08 00 
f010383e:	c6 05 bc df 17 f0 00 	movb   $0x0,0xf017dfbc
f0103845:	c6 05 bd df 17 f0 ee 	movb   $0xee,0xf017dfbd
f010384c:	c1 e8 10             	shr    $0x10,%eax
f010384f:	66 a3 be df 17 f0    	mov    %ax,0xf017dfbe
	SETGATE(idt[T_OFLOW], 0, GD_KT, oflow, 0);
f0103855:	b8 fc 3e 10 f0       	mov    $0xf0103efc,%eax
f010385a:	66 a3 c0 df 17 f0    	mov    %ax,0xf017dfc0
f0103860:	66 c7 05 c2 df 17 f0 	movw   $0x8,0xf017dfc2
f0103867:	08 00 
f0103869:	c6 05 c4 df 17 f0 00 	movb   $0x0,0xf017dfc4
f0103870:	c6 05 c5 df 17 f0 8e 	movb   $0x8e,0xf017dfc5
f0103877:	c1 e8 10             	shr    $0x10,%eax
f010387a:	66 a3 c6 df 17 f0    	mov    %ax,0xf017dfc6
	SETGATE(idt[T_BOUND], 0, GD_KT, bound, 0);
f0103880:	b8 02 3f 10 f0       	mov    $0xf0103f02,%eax
f0103885:	66 a3 c8 df 17 f0    	mov    %ax,0xf017dfc8
f010388b:	66 c7 05 ca df 17 f0 	movw   $0x8,0xf017dfca
f0103892:	08 00 
f0103894:	c6 05 cc df 17 f0 00 	movb   $0x0,0xf017dfcc
f010389b:	c6 05 cd df 17 f0 8e 	movb   $0x8e,0xf017dfcd
f01038a2:	c1 e8 10             	shr    $0x10,%eax
f01038a5:	66 a3 ce df 17 f0    	mov    %ax,0xf017dfce
	SETGATE(idt[T_ILLOP], 0, GD_KT, illop, 0);
f01038ab:	b8 08 3f 10 f0       	mov    $0xf0103f08,%eax
f01038b0:	66 a3 d0 df 17 f0    	mov    %ax,0xf017dfd0
f01038b6:	66 c7 05 d2 df 17 f0 	movw   $0x8,0xf017dfd2
f01038bd:	08 00 
f01038bf:	c6 05 d4 df 17 f0 00 	movb   $0x0,0xf017dfd4
f01038c6:	c6 05 d5 df 17 f0 8e 	movb   $0x8e,0xf017dfd5
f01038cd:	c1 e8 10             	shr    $0x10,%eax
f01038d0:	66 a3 d6 df 17 f0    	mov    %ax,0xf017dfd6
	SETGATE(idt[T_DEVICE], 0, GD_KT, device, 0);
f01038d6:	b8 0e 3f 10 f0       	mov    $0xf0103f0e,%eax
f01038db:	66 a3 d8 df 17 f0    	mov    %ax,0xf017dfd8
f01038e1:	66 c7 05 da df 17 f0 	movw   $0x8,0xf017dfda
f01038e8:	08 00 
f01038ea:	c6 05 dc df 17 f0 00 	movb   $0x0,0xf017dfdc
f01038f1:	c6 05 dd df 17 f0 8e 	movb   $0x8e,0xf017dfdd
f01038f8:	c1 e8 10             	shr    $0x10,%eax
f01038fb:	66 a3 de df 17 f0    	mov    %ax,0xf017dfde
	SETGATE(idt[T_DBLFLT], 0, GD_KT, dblflt, 0);
f0103901:	b8 14 3f 10 f0       	mov    $0xf0103f14,%eax
f0103906:	66 a3 e0 df 17 f0    	mov    %ax,0xf017dfe0
f010390c:	66 c7 05 e2 df 17 f0 	movw   $0x8,0xf017dfe2
f0103913:	08 00 
f0103915:	c6 05 e4 df 17 f0 00 	movb   $0x0,0xf017dfe4
f010391c:	c6 05 e5 df 17 f0 8e 	movb   $0x8e,0xf017dfe5
f0103923:	c1 e8 10             	shr    $0x10,%eax
f0103926:	66 a3 e6 df 17 f0    	mov    %ax,0xf017dfe6
	SETGATE(idt[T_TSS], 0, GD_KT, tss, 0);
f010392c:	b8 18 3f 10 f0       	mov    $0xf0103f18,%eax
f0103931:	66 a3 f0 df 17 f0    	mov    %ax,0xf017dff0
f0103937:	66 c7 05 f2 df 17 f0 	movw   $0x8,0xf017dff2
f010393e:	08 00 
f0103940:	c6 05 f4 df 17 f0 00 	movb   $0x0,0xf017dff4
f0103947:	c6 05 f5 df 17 f0 8e 	movb   $0x8e,0xf017dff5
f010394e:	c1 e8 10             	shr    $0x10,%eax
f0103951:	66 a3 f6 df 17 f0    	mov    %ax,0xf017dff6
	SETGATE(idt[T_SEGNP], 0, GD_KT, segnp, 0);
f0103957:	b8 1c 3f 10 f0       	mov    $0xf0103f1c,%eax
f010395c:	66 a3 f8 df 17 f0    	mov    %ax,0xf017dff8
f0103962:	66 c7 05 fa df 17 f0 	movw   $0x8,0xf017dffa
f0103969:	08 00 
f010396b:	c6 05 fc df 17 f0 00 	movb   $0x0,0xf017dffc
f0103972:	c6 05 fd df 17 f0 8e 	movb   $0x8e,0xf017dffd
f0103979:	c1 e8 10             	shr    $0x10,%eax
f010397c:	66 a3 fe df 17 f0    	mov    %ax,0xf017dffe
	SETGATE(idt[T_STACK], 0, GD_KT, stack, 0);
f0103982:	b8 20 3f 10 f0       	mov    $0xf0103f20,%eax
f0103987:	66 a3 00 e0 17 f0    	mov    %ax,0xf017e000
f010398d:	66 c7 05 02 e0 17 f0 	movw   $0x8,0xf017e002
f0103994:	08 00 
f0103996:	c6 05 04 e0 17 f0 00 	movb   $0x0,0xf017e004
f010399d:	c6 05 05 e0 17 f0 8e 	movb   $0x8e,0xf017e005
f01039a4:	c1 e8 10             	shr    $0x10,%eax
f01039a7:	66 a3 06 e0 17 f0    	mov    %ax,0xf017e006
	SETGATE(idt[T_GPFLT], 0, GD_KT, gpflt, 0);
f01039ad:	b8 24 3f 10 f0       	mov    $0xf0103f24,%eax
f01039b2:	66 a3 08 e0 17 f0    	mov    %ax,0xf017e008
f01039b8:	66 c7 05 0a e0 17 f0 	movw   $0x8,0xf017e00a
f01039bf:	08 00 
f01039c1:	c6 05 0c e0 17 f0 00 	movb   $0x0,0xf017e00c
f01039c8:	c6 05 0d e0 17 f0 8e 	movb   $0x8e,0xf017e00d
f01039cf:	c1 e8 10             	shr    $0x10,%eax
f01039d2:	66 a3 0e e0 17 f0    	mov    %ax,0xf017e00e
	SETGATE(idt[T_PGFLT], 0, GD_KT, pgflt, 0);
f01039d8:	b8 28 3f 10 f0       	mov    $0xf0103f28,%eax
f01039dd:	66 a3 10 e0 17 f0    	mov    %ax,0xf017e010
f01039e3:	66 c7 05 12 e0 17 f0 	movw   $0x8,0xf017e012
f01039ea:	08 00 
f01039ec:	c6 05 14 e0 17 f0 00 	movb   $0x0,0xf017e014
f01039f3:	c6 05 15 e0 17 f0 8e 	movb   $0x8e,0xf017e015
f01039fa:	c1 e8 10             	shr    $0x10,%eax
f01039fd:	66 a3 16 e0 17 f0    	mov    %ax,0xf017e016
	SETGATE(idt[T_FPERR], 0, GD_KT, fperr, 0);
f0103a03:	b8 2c 3f 10 f0       	mov    $0xf0103f2c,%eax
f0103a08:	66 a3 20 e0 17 f0    	mov    %ax,0xf017e020
f0103a0e:	66 c7 05 22 e0 17 f0 	movw   $0x8,0xf017e022
f0103a15:	08 00 
f0103a17:	c6 05 24 e0 17 f0 00 	movb   $0x0,0xf017e024
f0103a1e:	c6 05 25 e0 17 f0 8e 	movb   $0x8e,0xf017e025
f0103a25:	c1 e8 10             	shr    $0x10,%eax
f0103a28:	66 a3 26 e0 17 f0    	mov    %ax,0xf017e026
	SETGATE(idt[T_ALIGN], 0, GD_KT, align, 0);
f0103a2e:	b8 32 3f 10 f0       	mov    $0xf0103f32,%eax
f0103a33:	66 a3 28 e0 17 f0    	mov    %ax,0xf017e028
f0103a39:	66 c7 05 2a e0 17 f0 	movw   $0x8,0xf017e02a
f0103a40:	08 00 
f0103a42:	c6 05 2c e0 17 f0 00 	movb   $0x0,0xf017e02c
f0103a49:	c6 05 2d e0 17 f0 8e 	movb   $0x8e,0xf017e02d
f0103a50:	c1 e8 10             	shr    $0x10,%eax
f0103a53:	66 a3 2e e0 17 f0    	mov    %ax,0xf017e02e
	SETGATE(idt[T_MCHK], 0, GD_KT, mchk, 0);
f0103a59:	b8 36 3f 10 f0       	mov    $0xf0103f36,%eax
f0103a5e:	66 a3 30 e0 17 f0    	mov    %ax,0xf017e030
f0103a64:	66 c7 05 32 e0 17 f0 	movw   $0x8,0xf017e032
f0103a6b:	08 00 
f0103a6d:	c6 05 34 e0 17 f0 00 	movb   $0x0,0xf017e034
f0103a74:	c6 05 35 e0 17 f0 8e 	movb   $0x8e,0xf017e035
f0103a7b:	c1 e8 10             	shr    $0x10,%eax
f0103a7e:	66 a3 36 e0 17 f0    	mov    %ax,0xf017e036
	SETGATE(idt[T_SIMDERR], 0, GD_KT, simderr, 0);
f0103a84:	b8 3c 3f 10 f0       	mov    $0xf0103f3c,%eax
f0103a89:	66 a3 38 e0 17 f0    	mov    %ax,0xf017e038
f0103a8f:	66 c7 05 3a e0 17 f0 	movw   $0x8,0xf017e03a
f0103a96:	08 00 
f0103a98:	c6 05 3c e0 17 f0 00 	movb   $0x0,0xf017e03c
f0103a9f:	c6 05 3d e0 17 f0 8e 	movb   $0x8e,0xf017e03d
f0103aa6:	c1 e8 10             	shr    $0x10,%eax
f0103aa9:	66 a3 3e e0 17 f0    	mov    %ax,0xf017e03e
	SETGATE(idt[T_SYSCALL], 0, GD_KT, systemcall, 3);
f0103aaf:	b8 42 3f 10 f0       	mov    $0xf0103f42,%eax
f0103ab4:	66 a3 20 e1 17 f0    	mov    %ax,0xf017e120
f0103aba:	66 c7 05 22 e1 17 f0 	movw   $0x8,0xf017e122
f0103ac1:	08 00 
f0103ac3:	c6 05 24 e1 17 f0 00 	movb   $0x0,0xf017e124
f0103aca:	c6 05 25 e1 17 f0 ee 	movb   $0xee,0xf017e125
f0103ad1:	c1 e8 10             	shr    $0x10,%eax
f0103ad4:	66 a3 26 e1 17 f0    	mov    %ax,0xf017e126
	// Per-CPU setup 
	trap_init_percpu();
f0103ada:	e8 61 fc ff ff       	call   f0103740 <trap_init_percpu>
}
f0103adf:	5d                   	pop    %ebp
f0103ae0:	c3                   	ret    

f0103ae1 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103ae1:	55                   	push   %ebp
f0103ae2:	89 e5                	mov    %esp,%ebp
f0103ae4:	53                   	push   %ebx
f0103ae5:	83 ec 14             	sub    $0x14,%esp
f0103ae8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103aeb:	8b 03                	mov    (%ebx),%eax
f0103aed:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103af1:	c7 04 24 6a 62 10 f0 	movl   $0xf010626a,(%esp)
f0103af8:	e8 29 fc ff ff       	call   f0103726 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103afd:	8b 43 04             	mov    0x4(%ebx),%eax
f0103b00:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b04:	c7 04 24 79 62 10 f0 	movl   $0xf0106279,(%esp)
f0103b0b:	e8 16 fc ff ff       	call   f0103726 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103b10:	8b 43 08             	mov    0x8(%ebx),%eax
f0103b13:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b17:	c7 04 24 88 62 10 f0 	movl   $0xf0106288,(%esp)
f0103b1e:	e8 03 fc ff ff       	call   f0103726 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103b23:	8b 43 0c             	mov    0xc(%ebx),%eax
f0103b26:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b2a:	c7 04 24 97 62 10 f0 	movl   $0xf0106297,(%esp)
f0103b31:	e8 f0 fb ff ff       	call   f0103726 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103b36:	8b 43 10             	mov    0x10(%ebx),%eax
f0103b39:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b3d:	c7 04 24 a6 62 10 f0 	movl   $0xf01062a6,(%esp)
f0103b44:	e8 dd fb ff ff       	call   f0103726 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103b49:	8b 43 14             	mov    0x14(%ebx),%eax
f0103b4c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b50:	c7 04 24 b5 62 10 f0 	movl   $0xf01062b5,(%esp)
f0103b57:	e8 ca fb ff ff       	call   f0103726 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103b5c:	8b 43 18             	mov    0x18(%ebx),%eax
f0103b5f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b63:	c7 04 24 c4 62 10 f0 	movl   $0xf01062c4,(%esp)
f0103b6a:	e8 b7 fb ff ff       	call   f0103726 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103b6f:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0103b72:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b76:	c7 04 24 d3 62 10 f0 	movl   $0xf01062d3,(%esp)
f0103b7d:	e8 a4 fb ff ff       	call   f0103726 <cprintf>
}
f0103b82:	83 c4 14             	add    $0x14,%esp
f0103b85:	5b                   	pop    %ebx
f0103b86:	5d                   	pop    %ebp
f0103b87:	c3                   	ret    

f0103b88 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103b88:	55                   	push   %ebp
f0103b89:	89 e5                	mov    %esp,%ebp
f0103b8b:	56                   	push   %esi
f0103b8c:	53                   	push   %ebx
f0103b8d:	83 ec 10             	sub    $0x10,%esp
f0103b90:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103b93:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103b97:	c7 04 24 1e 64 10 f0 	movl   $0xf010641e,(%esp)
f0103b9e:	e8 83 fb ff ff       	call   f0103726 <cprintf>
	print_regs(&tf->tf_regs);
f0103ba3:	89 1c 24             	mov    %ebx,(%esp)
f0103ba6:	e8 36 ff ff ff       	call   f0103ae1 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103bab:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103baf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bb3:	c7 04 24 24 63 10 f0 	movl   $0xf0106324,(%esp)
f0103bba:	e8 67 fb ff ff       	call   f0103726 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103bbf:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103bc3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bc7:	c7 04 24 37 63 10 f0 	movl   $0xf0106337,(%esp)
f0103bce:	e8 53 fb ff ff       	call   f0103726 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103bd3:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0103bd6:	83 f8 13             	cmp    $0x13,%eax
f0103bd9:	77 09                	ja     f0103be4 <print_trapframe+0x5c>
		return excnames[trapno];
f0103bdb:	8b 14 85 00 66 10 f0 	mov    -0xfef9a00(,%eax,4),%edx
f0103be2:	eb 10                	jmp    f0103bf4 <print_trapframe+0x6c>
	if (trapno == T_SYSCALL)
		return "System call";
f0103be4:	83 f8 30             	cmp    $0x30,%eax
f0103be7:	ba e2 62 10 f0       	mov    $0xf01062e2,%edx
f0103bec:	b9 ee 62 10 f0       	mov    $0xf01062ee,%ecx
f0103bf1:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103bf4:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103bf8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bfc:	c7 04 24 4a 63 10 f0 	movl   $0xf010634a,(%esp)
f0103c03:	e8 1e fb ff ff       	call   f0103726 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103c08:	3b 1d 08 e8 17 f0    	cmp    0xf017e808,%ebx
f0103c0e:	75 19                	jne    f0103c29 <print_trapframe+0xa1>
f0103c10:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103c14:	75 13                	jne    f0103c29 <print_trapframe+0xa1>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103c16:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103c19:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c1d:	c7 04 24 5c 63 10 f0 	movl   $0xf010635c,(%esp)
f0103c24:	e8 fd fa ff ff       	call   f0103726 <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0103c29:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103c2c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c30:	c7 04 24 6b 63 10 f0 	movl   $0xf010636b,(%esp)
f0103c37:	e8 ea fa ff ff       	call   f0103726 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103c3c:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103c40:	75 51                	jne    f0103c93 <print_trapframe+0x10b>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103c42:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103c45:	89 c2                	mov    %eax,%edx
f0103c47:	83 e2 01             	and    $0x1,%edx
f0103c4a:	ba fd 62 10 f0       	mov    $0xf01062fd,%edx
f0103c4f:	b9 08 63 10 f0       	mov    $0xf0106308,%ecx
f0103c54:	0f 45 ca             	cmovne %edx,%ecx
f0103c57:	89 c2                	mov    %eax,%edx
f0103c59:	83 e2 02             	and    $0x2,%edx
f0103c5c:	ba 14 63 10 f0       	mov    $0xf0106314,%edx
f0103c61:	be 1a 63 10 f0       	mov    $0xf010631a,%esi
f0103c66:	0f 44 d6             	cmove  %esi,%edx
f0103c69:	83 e0 04             	and    $0x4,%eax
f0103c6c:	b8 1f 63 10 f0       	mov    $0xf010631f,%eax
f0103c71:	be 49 64 10 f0       	mov    $0xf0106449,%esi
f0103c76:	0f 44 c6             	cmove  %esi,%eax
f0103c79:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103c7d:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103c81:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c85:	c7 04 24 79 63 10 f0 	movl   $0xf0106379,(%esp)
f0103c8c:	e8 95 fa ff ff       	call   f0103726 <cprintf>
f0103c91:	eb 0c                	jmp    f0103c9f <print_trapframe+0x117>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103c93:	c7 04 24 1b 61 10 f0 	movl   $0xf010611b,(%esp)
f0103c9a:	e8 87 fa ff ff       	call   f0103726 <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103c9f:	8b 43 30             	mov    0x30(%ebx),%eax
f0103ca2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ca6:	c7 04 24 88 63 10 f0 	movl   $0xf0106388,(%esp)
f0103cad:	e8 74 fa ff ff       	call   f0103726 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103cb2:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103cb6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cba:	c7 04 24 97 63 10 f0 	movl   $0xf0106397,(%esp)
f0103cc1:	e8 60 fa ff ff       	call   f0103726 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103cc6:	8b 43 38             	mov    0x38(%ebx),%eax
f0103cc9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ccd:	c7 04 24 aa 63 10 f0 	movl   $0xf01063aa,(%esp)
f0103cd4:	e8 4d fa ff ff       	call   f0103726 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103cd9:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103cdd:	74 27                	je     f0103d06 <print_trapframe+0x17e>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103cdf:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103ce2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ce6:	c7 04 24 b9 63 10 f0 	movl   $0xf01063b9,(%esp)
f0103ced:	e8 34 fa ff ff       	call   f0103726 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103cf2:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103cf6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cfa:	c7 04 24 c8 63 10 f0 	movl   $0xf01063c8,(%esp)
f0103d01:	e8 20 fa ff ff       	call   f0103726 <cprintf>
	}
}
f0103d06:	83 c4 10             	add    $0x10,%esp
f0103d09:	5b                   	pop    %ebx
f0103d0a:	5e                   	pop    %esi
f0103d0b:	5d                   	pop    %ebp
f0103d0c:	c3                   	ret    

f0103d0d <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103d0d:	55                   	push   %ebp
f0103d0e:	89 e5                	mov    %esp,%ebp
f0103d10:	53                   	push   %ebx
f0103d11:	83 ec 14             	sub    $0x14,%esp
f0103d14:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103d17:	0f 20 d0             	mov    %cr2,%eax
	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();

	// Handle kernel-mode page faults.
	// LAB 3: Your code here.
	if ((tf->tf_cs & 3) == 0)
f0103d1a:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103d1e:	75 20                	jne    f0103d40 <page_fault_handler+0x33>
		panic("kernel fault va %08x", fault_va);
f0103d20:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103d24:	c7 44 24 08 db 63 10 	movl   $0xf01063db,0x8(%esp)
f0103d2b:	f0 
f0103d2c:	c7 44 24 04 06 01 00 	movl   $0x106,0x4(%esp)
f0103d33:	00 
f0103d34:	c7 04 24 f0 63 10 f0 	movl   $0xf01063f0,(%esp)
f0103d3b:	e8 76 c3 ff ff       	call   f01000b6 <_panic>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103d40:	8b 53 30             	mov    0x30(%ebx),%edx
f0103d43:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103d47:	89 44 24 08          	mov    %eax,0x8(%esp)
		curenv->env_id, fault_va, tf->tf_eip);
f0103d4b:	a1 88 df 17 f0       	mov    0xf017df88,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103d50:	8b 40 48             	mov    0x48(%eax),%eax
f0103d53:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d57:	c7 04 24 94 65 10 f0 	movl   $0xf0106594,(%esp)
f0103d5e:	e8 c3 f9 ff ff       	call   f0103726 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103d63:	89 1c 24             	mov    %ebx,(%esp)
f0103d66:	e8 1d fe ff ff       	call   f0103b88 <print_trapframe>
	env_destroy(curenv);
f0103d6b:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0103d70:	89 04 24             	mov    %eax,(%esp)
f0103d73:	e8 91 f8 ff ff       	call   f0103609 <env_destroy>
}
f0103d78:	83 c4 14             	add    $0x14,%esp
f0103d7b:	5b                   	pop    %ebx
f0103d7c:	5d                   	pop    %ebp
f0103d7d:	c3                   	ret    

f0103d7e <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103d7e:	55                   	push   %ebp
f0103d7f:	89 e5                	mov    %esp,%ebp
f0103d81:	57                   	push   %edi
f0103d82:	56                   	push   %esi
f0103d83:	83 ec 20             	sub    $0x20,%esp
f0103d86:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103d89:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103d8a:	9c                   	pushf  
f0103d8b:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103d8c:	f6 c4 02             	test   $0x2,%ah
f0103d8f:	74 24                	je     f0103db5 <trap+0x37>
f0103d91:	c7 44 24 0c fc 63 10 	movl   $0xf01063fc,0xc(%esp)
f0103d98:	f0 
f0103d99:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0103da0:	f0 
f0103da1:	c7 44 24 04 de 00 00 	movl   $0xde,0x4(%esp)
f0103da8:	00 
f0103da9:	c7 04 24 f0 63 10 f0 	movl   $0xf01063f0,(%esp)
f0103db0:	e8 01 c3 ff ff       	call   f01000b6 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103db5:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103db9:	c7 04 24 15 64 10 f0 	movl   $0xf0106415,(%esp)
f0103dc0:	e8 61 f9 ff ff       	call   f0103726 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103dc5:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103dc9:	83 e0 03             	and    $0x3,%eax
f0103dcc:	83 f8 03             	cmp    $0x3,%eax
f0103dcf:	75 3c                	jne    f0103e0d <trap+0x8f>
		// Trapped from user mode.
		assert(curenv);
f0103dd1:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0103dd6:	85 c0                	test   %eax,%eax
f0103dd8:	75 24                	jne    f0103dfe <trap+0x80>
f0103dda:	c7 44 24 0c 30 64 10 	movl   $0xf0106430,0xc(%esp)
f0103de1:	f0 
f0103de2:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0103de9:	f0 
f0103dea:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
f0103df1:	00 
f0103df2:	c7 04 24 f0 63 10 f0 	movl   $0xf01063f0,(%esp)
f0103df9:	e8 b8 c2 ff ff       	call   f01000b6 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103dfe:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103e03:	89 c7                	mov    %eax,%edi
f0103e05:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103e07:	8b 35 88 df 17 f0    	mov    0xf017df88,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103e0d:	89 35 08 e8 17 f0    	mov    %esi,0xf017e808
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch (tf->tf_trapno)
f0103e13:	8b 46 28             	mov    0x28(%esi),%eax
f0103e16:	83 f8 0e             	cmp    $0xe,%eax
f0103e19:	74 0c                	je     f0103e27 <trap+0xa9>
f0103e1b:	83 f8 30             	cmp    $0x30,%eax
f0103e1e:	74 1c                	je     f0103e3c <trap+0xbe>
f0103e20:	83 f8 03             	cmp    $0x3,%eax
f0103e23:	75 49                	jne    f0103e6e <trap+0xf0>
f0103e25:	eb 0b                	jmp    f0103e32 <trap+0xb4>
	{
		case (T_PGFLT):
			page_fault_handler(tf);
f0103e27:	89 34 24             	mov    %esi,(%esp)
f0103e2a:	e8 de fe ff ff       	call   f0103d0d <page_fault_handler>
f0103e2f:	90                   	nop
f0103e30:	eb 74                	jmp    f0103ea6 <trap+0x128>
			break;
		case (T_BRKPT):
			monitor(tf);
f0103e32:	89 34 24             	mov    %esi,(%esp)
f0103e35:	e8 bb c9 ff ff       	call   f01007f5 <monitor>
f0103e3a:	eb 6a                	jmp    f0103ea6 <trap+0x128>
			break;
		case (T_SYSCALL):
			tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,
f0103e3c:	8b 46 04             	mov    0x4(%esi),%eax
f0103e3f:	89 44 24 14          	mov    %eax,0x14(%esp)
f0103e43:	8b 06                	mov    (%esi),%eax
f0103e45:	89 44 24 10          	mov    %eax,0x10(%esp)
f0103e49:	8b 46 10             	mov    0x10(%esi),%eax
f0103e4c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103e50:	8b 46 18             	mov    0x18(%esi),%eax
f0103e53:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103e57:	8b 46 14             	mov    0x14(%esi),%eax
f0103e5a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e5e:	8b 46 1c             	mov    0x1c(%esi),%eax
f0103e61:	89 04 24             	mov    %eax,(%esp)
f0103e64:	e8 07 01 00 00       	call   f0103f70 <syscall>
f0103e69:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103e6c:	eb 38                	jmp    f0103ea6 <trap+0x128>
						      tf->tf_regs.reg_edi,
						      tf->tf_regs.reg_esi);
			break;
		default:
			// Unexpected trap: The user process or the kernel has a bug.
			print_trapframe(tf);
f0103e6e:	89 34 24             	mov    %esi,(%esp)
f0103e71:	e8 12 fd ff ff       	call   f0103b88 <print_trapframe>
			if (tf->tf_cs == GD_KT)
f0103e76:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103e7b:	75 1c                	jne    f0103e99 <trap+0x11b>
				panic("unhandled trap in kernel");
f0103e7d:	c7 44 24 08 37 64 10 	movl   $0xf0106437,0x8(%esp)
f0103e84:	f0 
f0103e85:	c7 44 24 04 cb 00 00 	movl   $0xcb,0x4(%esp)
f0103e8c:	00 
f0103e8d:	c7 04 24 f0 63 10 f0 	movl   $0xf01063f0,(%esp)
f0103e94:	e8 1d c2 ff ff       	call   f01000b6 <_panic>
			else 
			{
				env_destroy(curenv);
f0103e99:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0103e9e:	89 04 24             	mov    %eax,(%esp)
f0103ea1:	e8 63 f7 ff ff       	call   f0103609 <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103ea6:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0103eab:	85 c0                	test   %eax,%eax
f0103ead:	74 06                	je     f0103eb5 <trap+0x137>
f0103eaf:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103eb3:	74 24                	je     f0103ed9 <trap+0x15b>
f0103eb5:	c7 44 24 0c b8 65 10 	movl   $0xf01065b8,0xc(%esp)
f0103ebc:	f0 
f0103ebd:	c7 44 24 08 7b 5e 10 	movl   $0xf0105e7b,0x8(%esp)
f0103ec4:	f0 
f0103ec5:	c7 44 24 04 f6 00 00 	movl   $0xf6,0x4(%esp)
f0103ecc:	00 
f0103ecd:	c7 04 24 f0 63 10 f0 	movl   $0xf01063f0,(%esp)
f0103ed4:	e8 dd c1 ff ff       	call   f01000b6 <_panic>
	env_run(curenv);
f0103ed9:	89 04 24             	mov    %eax,(%esp)
f0103edc:	e8 7f f7 ff ff       	call   f0103660 <env_run>
f0103ee1:	00 00                	add    %al,(%eax)
	...

f0103ee4 <divide>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(divide, T_DIVIDE)
f0103ee4:	6a 00                	push   $0x0
f0103ee6:	6a 00                	push   $0x0
f0103ee8:	eb 5e                	jmp    f0103f48 <_alltraps>

f0103eea <debug>:
TRAPHANDLER_NOEC(debug, T_DEBUG)
f0103eea:	6a 00                	push   $0x0
f0103eec:	6a 01                	push   $0x1
f0103eee:	eb 58                	jmp    f0103f48 <_alltraps>

f0103ef0 <nmi>:
TRAPHANDLER_NOEC(nmi, T_NMI)
f0103ef0:	6a 00                	push   $0x0
f0103ef2:	6a 02                	push   $0x2
f0103ef4:	eb 52                	jmp    f0103f48 <_alltraps>

f0103ef6 <brkpt>:
TRAPHANDLER_NOEC(brkpt, T_BRKPT)
f0103ef6:	6a 00                	push   $0x0
f0103ef8:	6a 03                	push   $0x3
f0103efa:	eb 4c                	jmp    f0103f48 <_alltraps>

f0103efc <oflow>:
TRAPHANDLER_NOEC(oflow, T_OFLOW)
f0103efc:	6a 00                	push   $0x0
f0103efe:	6a 04                	push   $0x4
f0103f00:	eb 46                	jmp    f0103f48 <_alltraps>

f0103f02 <bound>:
TRAPHANDLER_NOEC(bound, T_BOUND)
f0103f02:	6a 00                	push   $0x0
f0103f04:	6a 05                	push   $0x5
f0103f06:	eb 40                	jmp    f0103f48 <_alltraps>

f0103f08 <illop>:
TRAPHANDLER_NOEC(illop, T_ILLOP)
f0103f08:	6a 00                	push   $0x0
f0103f0a:	6a 06                	push   $0x6
f0103f0c:	eb 3a                	jmp    f0103f48 <_alltraps>

f0103f0e <device>:
TRAPHANDLER_NOEC(device, T_DEVICE)
f0103f0e:	6a 00                	push   $0x0
f0103f10:	6a 07                	push   $0x7
f0103f12:	eb 34                	jmp    f0103f48 <_alltraps>

f0103f14 <dblflt>:
TRAPHANDLER(dblflt, T_DBLFLT)
f0103f14:	6a 08                	push   $0x8
f0103f16:	eb 30                	jmp    f0103f48 <_alltraps>

f0103f18 <tss>:
TRAPHANDLER(tss, T_TSS)
f0103f18:	6a 0a                	push   $0xa
f0103f1a:	eb 2c                	jmp    f0103f48 <_alltraps>

f0103f1c <segnp>:
TRAPHANDLER(segnp, T_SEGNP)
f0103f1c:	6a 0b                	push   $0xb
f0103f1e:	eb 28                	jmp    f0103f48 <_alltraps>

f0103f20 <stack>:
TRAPHANDLER(stack, T_STACK)
f0103f20:	6a 0c                	push   $0xc
f0103f22:	eb 24                	jmp    f0103f48 <_alltraps>

f0103f24 <gpflt>:
TRAPHANDLER(gpflt, T_GPFLT)
f0103f24:	6a 0d                	push   $0xd
f0103f26:	eb 20                	jmp    f0103f48 <_alltraps>

f0103f28 <pgflt>:
TRAPHANDLER(pgflt, T_PGFLT)
f0103f28:	6a 0e                	push   $0xe
f0103f2a:	eb 1c                	jmp    f0103f48 <_alltraps>

f0103f2c <fperr>:
TRAPHANDLER_NOEC(fperr, T_FPERR)
f0103f2c:	6a 00                	push   $0x0
f0103f2e:	6a 10                	push   $0x10
f0103f30:	eb 16                	jmp    f0103f48 <_alltraps>

f0103f32 <align>:
TRAPHANDLER(align, T_ALIGN)
f0103f32:	6a 11                	push   $0x11
f0103f34:	eb 12                	jmp    f0103f48 <_alltraps>

f0103f36 <mchk>:
TRAPHANDLER_NOEC(mchk, T_MCHK)
f0103f36:	6a 00                	push   $0x0
f0103f38:	6a 12                	push   $0x12
f0103f3a:	eb 0c                	jmp    f0103f48 <_alltraps>

f0103f3c <simderr>:
TRAPHANDLER_NOEC(simderr, T_SIMDERR)
f0103f3c:	6a 00                	push   $0x0
f0103f3e:	6a 13                	push   $0x13
f0103f40:	eb 06                	jmp    f0103f48 <_alltraps>

f0103f42 <systemcall>:
TRAPHANDLER_NOEC(systemcall, T_SYSCALL)
f0103f42:	6a 00                	push   $0x0
f0103f44:	6a 30                	push   $0x30
f0103f46:	eb 00                	jmp    f0103f48 <_alltraps>

f0103f48 <_alltraps>:

/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushw $0x0
f0103f48:	66 6a 00             	pushw  $0x0
	pushw %ds
f0103f4b:	66 1e                	pushw  %ds
	pushw $0x0
f0103f4d:	66 6a 00             	pushw  $0x0
	pushw %es
f0103f50:	66 06                	pushw  %es
	pushal
f0103f52:	60                   	pusha  
	movl $GD_KD,%eax
f0103f53:	b8 10 00 00 00       	mov    $0x10,%eax
	movw %ax,%ds
f0103f58:	8e d8                	mov    %eax,%ds
	movw %ax,%es
f0103f5a:	8e c0                	mov    %eax,%es
	pushl %esp
f0103f5c:	54                   	push   %esp
	call trap
f0103f5d:	e8 1c fe ff ff       	call   f0103d7e <trap>
	...

f0103f70 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0103f70:	55                   	push   %ebp
f0103f71:	89 e5                	mov    %esp,%ebp
f0103f73:	83 ec 28             	sub    $0x28,%esp
f0103f76:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0103f79:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0103f7c:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f7f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103f82:	8b 75 10             	mov    0x10(%ebp),%esi
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.
	//panic("syscall not implemented");
	switch (syscallno) 
f0103f85:	83 f8 01             	cmp    $0x1,%eax
f0103f88:	74 51                	je     f0103fdb <syscall+0x6b>
f0103f8a:	83 f8 01             	cmp    $0x1,%eax
f0103f8d:	72 14                	jb     f0103fa3 <syscall+0x33>
f0103f8f:	83 f8 02             	cmp    $0x2,%eax
f0103f92:	0f 84 b3 00 00 00    	je     f010404b <syscall+0xdb>
f0103f98:	83 f8 03             	cmp    $0x3,%eax
f0103f9b:	0f 85 b4 00 00 00    	jne    f0104055 <syscall+0xe5>
f0103fa1:	eb 3f                	jmp    f0103fe2 <syscall+0x72>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U);
f0103fa3:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0103faa:	00 
f0103fab:	89 74 24 08          	mov    %esi,0x8(%esp)
f0103faf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103fb3:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0103fb8:	89 04 24             	mov    %eax,(%esp)
f0103fbb:	e8 4d ef ff ff       	call   f0102f0d <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0103fc0:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103fc4:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103fc8:	c7 04 24 50 66 10 f0 	movl   $0xf0106650,(%esp)
f0103fcf:	e8 52 f7 ff ff       	call   f0103726 <cprintf>
	//panic("syscall not implemented");
	switch (syscallno) 
	{
		case (SYS_cputs):
			sys_cputs((const char*)a1, a2);
			return 0;
f0103fd4:	b8 00 00 00 00       	mov    $0x0,%eax
f0103fd9:	eb 7f                	jmp    f010405a <syscall+0xea>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0103fdb:	e8 f4 c4 ff ff       	call   f01004d4 <cons_getc>
	{
		case (SYS_cputs):
			sys_cputs((const char*)a1, a2);
			return 0;
		case (SYS_cgetc):
			return sys_cgetc();
f0103fe0:	eb 78                	jmp    f010405a <syscall+0xea>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0103fe2:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0103fe9:	00 
f0103fea:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103fed:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ff1:	89 1c 24             	mov    %ebx,(%esp)
f0103ff4:	e8 0f f0 ff ff       	call   f0103008 <envid2env>
f0103ff9:	85 c0                	test   %eax,%eax
f0103ffb:	78 5d                	js     f010405a <syscall+0xea>
		return r;
	if (e == curenv)
f0103ffd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104000:	8b 15 88 df 17 f0    	mov    0xf017df88,%edx
f0104006:	39 d0                	cmp    %edx,%eax
f0104008:	75 15                	jne    f010401f <syscall+0xaf>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f010400a:	8b 40 48             	mov    0x48(%eax),%eax
f010400d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104011:	c7 04 24 55 66 10 f0 	movl   $0xf0106655,(%esp)
f0104018:	e8 09 f7 ff ff       	call   f0103726 <cprintf>
f010401d:	eb 1a                	jmp    f0104039 <syscall+0xc9>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010401f:	8b 40 48             	mov    0x48(%eax),%eax
f0104022:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104026:	8b 42 48             	mov    0x48(%edx),%eax
f0104029:	89 44 24 04          	mov    %eax,0x4(%esp)
f010402d:	c7 04 24 70 66 10 f0 	movl   $0xf0106670,(%esp)
f0104034:	e8 ed f6 ff ff       	call   f0103726 <cprintf>
	env_destroy(e);
f0104039:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010403c:	89 04 24             	mov    %eax,(%esp)
f010403f:	e8 c5 f5 ff ff       	call   f0103609 <env_destroy>
	return 0;
f0104044:	b8 00 00 00 00       	mov    $0x0,%eax
			sys_cputs((const char*)a1, a2);
			return 0;
		case (SYS_cgetc):
			return sys_cgetc();
		case (SYS_env_destroy):
			return sys_env_destroy(a1);
f0104049:	eb 0f                	jmp    f010405a <syscall+0xea>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f010404b:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0104050:	8b 40 48             	mov    0x48(%eax),%eax
		case (SYS_cgetc):
			return sys_cgetc();
		case (SYS_env_destroy):
			return sys_env_destroy(a1);
		case (SYS_getenvid):
			return sys_getenvid();
f0104053:	eb 05                	jmp    f010405a <syscall+0xea>
		default:
			return -E_INVAL;
f0104055:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
}
f010405a:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f010405d:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0104060:	89 ec                	mov    %ebp,%esp
f0104062:	5d                   	pop    %ebp
f0104063:	c3                   	ret    

f0104064 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104064:	55                   	push   %ebp
f0104065:	89 e5                	mov    %esp,%ebp
f0104067:	57                   	push   %edi
f0104068:	56                   	push   %esi
f0104069:	53                   	push   %ebx
f010406a:	83 ec 14             	sub    $0x14,%esp
f010406d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104070:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0104073:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104076:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104079:	8b 1a                	mov    (%edx),%ebx
f010407b:	8b 01                	mov    (%ecx),%eax
f010407d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104080:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)

	while (l <= r) {
f0104087:	e9 88 00 00 00       	jmp    f0104114 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f010408c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010408f:	01 d8                	add    %ebx,%eax
f0104091:	89 c7                	mov    %eax,%edi
f0104093:	c1 ef 1f             	shr    $0x1f,%edi
f0104096:	01 c7                	add    %eax,%edi
f0104098:	d1 ff                	sar    %edi

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010409a:	8d 04 7f             	lea    (%edi,%edi,2),%eax
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f010409d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01040a0:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f01040a4:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01040a6:	eb 03                	jmp    f01040ab <stab_binsearch+0x47>
			m--;
f01040a8:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01040ab:	39 c3                	cmp    %eax,%ebx
f01040ad:	7f 1e                	jg     f01040cd <stab_binsearch+0x69>
f01040af:	0f b6 0a             	movzbl (%edx),%ecx
f01040b2:	83 ea 0c             	sub    $0xc,%edx
f01040b5:	39 f1                	cmp    %esi,%ecx
f01040b7:	75 ef                	jne    f01040a8 <stab_binsearch+0x44>
f01040b9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01040bc:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01040bf:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01040c2:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01040c6:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01040c9:	76 18                	jbe    f01040e3 <stab_binsearch+0x7f>
f01040cb:	eb 05                	jmp    f01040d2 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01040cd:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f01040d0:	eb 42                	jmp    f0104114 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01040d2:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01040d5:	89 02                	mov    %eax,(%edx)
			l = true_m + 1;
f01040d7:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01040da:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f01040e1:	eb 31                	jmp    f0104114 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01040e3:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01040e6:	73 17                	jae    f01040ff <stab_binsearch+0x9b>
			*region_right = m - 1;
f01040e8:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01040eb:	83 e9 01             	sub    $0x1,%ecx
f01040ee:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01040f1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01040f4:	89 08                	mov    %ecx,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01040f6:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f01040fd:	eb 15                	jmp    f0104114 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01040ff:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0104102:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0104105:	89 0a                	mov    %ecx,(%edx)
			l = m;
			addr++;
f0104107:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010410b:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010410d:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104114:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104117:	0f 8e 6f ff ff ff    	jle    f010408c <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010411d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104121:	75 0f                	jne    f0104132 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0104123:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0104126:	8b 02                	mov    (%edx),%eax
f0104128:	83 e8 01             	sub    $0x1,%eax
f010412b:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010412e:	89 01                	mov    %eax,(%ecx)
f0104130:	eb 2c                	jmp    f010415e <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104132:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104135:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104137:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010413a:	8b 0a                	mov    (%edx),%ecx
f010413c:	8d 14 40             	lea    (%eax,%eax,2),%edx
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f010413f:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0104142:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104146:	eb 03                	jmp    f010414b <stab_binsearch+0xe7>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104148:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010414b:	39 c8                	cmp    %ecx,%eax
f010414d:	7e 0a                	jle    f0104159 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f010414f:	0f b6 1a             	movzbl (%edx),%ebx
f0104152:	83 ea 0c             	sub    $0xc,%edx
f0104155:	39 f3                	cmp    %esi,%ebx
f0104157:	75 ef                	jne    f0104148 <stab_binsearch+0xe4>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104159:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010415c:	89 02                	mov    %eax,(%edx)
	}
}
f010415e:	83 c4 14             	add    $0x14,%esp
f0104161:	5b                   	pop    %ebx
f0104162:	5e                   	pop    %esi
f0104163:	5f                   	pop    %edi
f0104164:	5d                   	pop    %ebp
f0104165:	c3                   	ret    

f0104166 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104166:	55                   	push   %ebp
f0104167:	89 e5                	mov    %esp,%ebp
f0104169:	57                   	push   %edi
f010416a:	56                   	push   %esi
f010416b:	53                   	push   %ebx
f010416c:	83 ec 5c             	sub    $0x5c,%esp
f010416f:	8b 75 08             	mov    0x8(%ebp),%esi
f0104172:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104175:	c7 03 88 66 10 f0    	movl   $0xf0106688,(%ebx)
	info->eip_line = 0;
f010417b:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0104182:	c7 43 08 88 66 10 f0 	movl   $0xf0106688,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0104189:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0104190:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0104193:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010419a:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01041a0:	0f 87 c0 00 00 00    	ja     f0104266 <debuginfo_eip+0x100>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U) < 0)
f01041a6:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f01041ad:	00 
f01041ae:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f01041b5:	00 
f01041b6:	c7 44 24 04 00 00 20 	movl   $0x200000,0x4(%esp)
f01041bd:	00 
f01041be:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f01041c3:	89 04 24             	mov    %eax,(%esp)
f01041c6:	e8 cb ec ff ff       	call   f0102e96 <user_mem_check>
f01041cb:	89 c2                	mov    %eax,%edx
			return -1;
f01041cd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U) < 0)
f01041d2:	85 d2                	test   %edx,%edx
f01041d4:	0f 88 54 02 00 00    	js     f010442e <debuginfo_eip+0x2c8>
			return -1;

		stabs = usd->stabs;
f01041da:	8b 3d 00 00 20 00    	mov    0x200000,%edi
f01041e0:	89 7d c4             	mov    %edi,-0x3c(%ebp)
		stab_end = usd->stab_end;
f01041e3:	8b 3d 04 00 20 00    	mov    0x200004,%edi
		stabstr = usd->stabstr;
f01041e9:	a1 08 00 20 00       	mov    0x200008,%eax
f01041ee:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stabstr_end = usd->stabstr_end;
f01041f1:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f01041f7:	89 55 c0             	mov    %edx,-0x40(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, stabs, stab_end-stabs, PTE_U) < 0)
f01041fa:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0104201:	00 
f0104202:	89 f8                	mov    %edi,%eax
f0104204:	2b 45 c4             	sub    -0x3c(%ebp),%eax
f0104207:	c1 f8 02             	sar    $0x2,%eax
f010420a:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0104210:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104214:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0104217:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010421b:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0104220:	89 04 24             	mov    %eax,(%esp)
f0104223:	e8 6e ec ff ff       	call   f0102e96 <user_mem_check>
f0104228:	89 c2                	mov    %eax,%edx
			return -1;
f010422a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		stabstr = usd->stabstr;
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, stabs, stab_end-stabs, PTE_U) < 0)
f010422f:	85 d2                	test   %edx,%edx
f0104231:	0f 88 f7 01 00 00    	js     f010442e <debuginfo_eip+0x2c8>
			return -1;
		if (user_mem_check(curenv, stabstr, stabstr_end-stabstr, PTE_U) < 0)
f0104237:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f010423e:	00 
f010423f:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0104242:	2b 45 bc             	sub    -0x44(%ebp),%eax
f0104245:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104249:	8b 45 bc             	mov    -0x44(%ebp),%eax
f010424c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104250:	a1 88 df 17 f0       	mov    0xf017df88,%eax
f0104255:	89 04 24             	mov    %eax,(%esp)
f0104258:	e8 39 ec ff ff       	call   f0102e96 <user_mem_check>
f010425d:	85 c0                	test   %eax,%eax
f010425f:	79 1f                	jns    f0104280 <debuginfo_eip+0x11a>
f0104261:	e9 bc 01 00 00       	jmp    f0104422 <debuginfo_eip+0x2bc>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104266:	c7 45 c0 23 15 11 f0 	movl   $0xf0111523,-0x40(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f010426d:	c7 45 bc d1 e9 10 f0 	movl   $0xf010e9d1,-0x44(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104274:	bf d0 e9 10 f0       	mov    $0xf010e9d0,%edi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104279:	c7 45 c4 a0 68 10 f0 	movl   $0xf01068a0,-0x3c(%ebp)
			return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104280:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		if (user_mem_check(curenv, stabstr, stabstr_end-stabstr, PTE_U) < 0)
			return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104285:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0104288:	39 55 bc             	cmp    %edx,-0x44(%ebp)
f010428b:	0f 83 9d 01 00 00    	jae    f010442e <debuginfo_eip+0x2c8>
f0104291:	80 7a ff 00          	cmpb   $0x0,-0x1(%edx)
f0104295:	0f 85 93 01 00 00    	jne    f010442e <debuginfo_eip+0x2c8>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010429b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01042a2:	2b 7d c4             	sub    -0x3c(%ebp),%edi
f01042a5:	c1 ff 02             	sar    $0x2,%edi
f01042a8:	69 c7 ab aa aa aa    	imul   $0xaaaaaaab,%edi,%eax
f01042ae:	83 e8 01             	sub    $0x1,%eax
f01042b1:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01042b4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01042b8:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01042bf:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01042c2:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01042c5:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01042c8:	e8 97 fd ff ff       	call   f0104064 <stab_binsearch>
	if (lfile == 0)
f01042cd:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f01042d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f01042d5:	85 d2                	test   %edx,%edx
f01042d7:	0f 84 51 01 00 00    	je     f010442e <debuginfo_eip+0x2c8>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01042dd:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f01042e0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01042e3:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01042e6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01042ea:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f01042f1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01042f4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01042f7:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01042fa:	e8 65 fd ff ff       	call   f0104064 <stab_binsearch>

	if (lfun <= rfun) {
f01042ff:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104302:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104305:	39 d0                	cmp    %edx,%eax
f0104307:	7f 32                	jg     f010433b <debuginfo_eip+0x1d5>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104309:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f010430c:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010430f:	8d 0c 8f             	lea    (%edi,%ecx,4),%ecx
f0104312:	8b 39                	mov    (%ecx),%edi
f0104314:	89 7d b4             	mov    %edi,-0x4c(%ebp)
f0104317:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010431a:	2b 7d bc             	sub    -0x44(%ebp),%edi
f010431d:	39 7d b4             	cmp    %edi,-0x4c(%ebp)
f0104320:	73 09                	jae    f010432b <debuginfo_eip+0x1c5>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104322:	8b 7d b4             	mov    -0x4c(%ebp),%edi
f0104325:	03 7d bc             	add    -0x44(%ebp),%edi
f0104328:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010432b:	8b 49 08             	mov    0x8(%ecx),%ecx
f010432e:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0104331:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0104333:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104336:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0104339:	eb 0f                	jmp    f010434a <debuginfo_eip+0x1e4>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010433b:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f010433e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104341:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104344:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104347:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010434a:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0104351:	00 
f0104352:	8b 43 08             	mov    0x8(%ebx),%eax
f0104355:	89 04 24             	mov    %eax,(%esp)
f0104358:	e8 ca 08 00 00       	call   f0104c27 <strfind>
f010435d:	2b 43 08             	sub    0x8(%ebx),%eax
f0104360:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0104363:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104367:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f010436e:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104371:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104374:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0104377:	e8 e8 fc ff ff       	call   f0104064 <stab_binsearch>
	if (lline <= rline)
f010437c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
		info->eip_line = stabs[lline].n_desc;
	else
		return -1;
f010437f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if (lline <= rline)
f0104384:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0104387:	0f 8f a1 00 00 00    	jg     f010442e <debuginfo_eip+0x2c8>
		info->eip_line = stabs[lline].n_desc;
f010438d:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0104390:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104393:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0104398:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010439b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010439e:	89 d0                	mov    %edx,%eax
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01043a0:	8d 14 52             	lea    (%edx,%edx,2),%edx
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f01043a3:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01043a6:	8d 54 97 08          	lea    0x8(%edi,%edx,4),%edx
f01043aa:	89 5d b8             	mov    %ebx,-0x48(%ebp)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01043ad:	eb 06                	jmp    f01043b5 <debuginfo_eip+0x24f>
f01043af:	83 e8 01             	sub    $0x1,%eax
f01043b2:	83 ea 0c             	sub    $0xc,%edx
f01043b5:	89 c7                	mov    %eax,%edi
f01043b7:	39 c6                	cmp    %eax,%esi
f01043b9:	7f 22                	jg     f01043dd <debuginfo_eip+0x277>
	       && stabs[lline].n_type != N_SOL
f01043bb:	0f b6 4a fc          	movzbl -0x4(%edx),%ecx
f01043bf:	80 f9 84             	cmp    $0x84,%cl
f01043c2:	74 72                	je     f0104436 <debuginfo_eip+0x2d0>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01043c4:	80 f9 64             	cmp    $0x64,%cl
f01043c7:	75 e6                	jne    f01043af <debuginfo_eip+0x249>
f01043c9:	83 3a 00             	cmpl   $0x0,(%edx)
f01043cc:	74 e1                	je     f01043af <debuginfo_eip+0x249>
f01043ce:	8b 5d b8             	mov    -0x48(%ebp),%ebx
f01043d1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01043d4:	eb 66                	jmp    f010443c <debuginfo_eip+0x2d6>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f01043d6:	03 45 bc             	add    -0x44(%ebp),%eax
f01043d9:	89 03                	mov    %eax,(%ebx)
f01043db:	eb 03                	jmp    f01043e0 <debuginfo_eip+0x27a>
f01043dd:	8b 5d b8             	mov    -0x48(%ebp),%ebx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01043e0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01043e3:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01043e6:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01043eb:	39 ca                	cmp    %ecx,%edx
f01043ed:	7d 3f                	jge    f010442e <debuginfo_eip+0x2c8>
		for (lline = lfun + 1;
f01043ef:	83 c2 01             	add    $0x1,%edx
f01043f2:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01043f5:	89 d0                	mov    %edx,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01043f7:	8d 14 52             	lea    (%edx,%edx,2),%edx
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f01043fa:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01043fd:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
f0104401:	89 ce                	mov    %ecx,%esi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104403:	eb 04                	jmp    f0104409 <debuginfo_eip+0x2a3>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104405:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104409:	39 f0                	cmp    %esi,%eax
f010440b:	7d 1c                	jge    f0104429 <debuginfo_eip+0x2c3>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010440d:	0f b6 0a             	movzbl (%edx),%ecx
f0104410:	83 c0 01             	add    $0x1,%eax
f0104413:	83 c2 0c             	add    $0xc,%edx
f0104416:	80 f9 a0             	cmp    $0xa0,%cl
f0104419:	74 ea                	je     f0104405 <debuginfo_eip+0x29f>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010441b:	b8 00 00 00 00       	mov    $0x0,%eax
f0104420:	eb 0c                	jmp    f010442e <debuginfo_eip+0x2c8>
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, stabs, stab_end-stabs, PTE_U) < 0)
			return -1;
		if (user_mem_check(curenv, stabstr, stabstr_end-stabstr, PTE_U) < 0)
			return -1;
f0104422:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104427:	eb 05                	jmp    f010442e <debuginfo_eip+0x2c8>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104429:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010442e:	83 c4 5c             	add    $0x5c,%esp
f0104431:	5b                   	pop    %ebx
f0104432:	5e                   	pop    %esi
f0104433:	5f                   	pop    %edi
f0104434:	5d                   	pop    %ebp
f0104435:	c3                   	ret    
f0104436:	8b 5d b8             	mov    -0x48(%ebp),%ebx

	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104439:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010443c:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f010443f:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0104442:	8b 04 87             	mov    (%edi,%eax,4),%eax
f0104445:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0104448:	2b 55 bc             	sub    -0x44(%ebp),%edx
f010444b:	39 d0                	cmp    %edx,%eax
f010444d:	72 87                	jb     f01043d6 <debuginfo_eip+0x270>
f010444f:	eb 8f                	jmp    f01043e0 <debuginfo_eip+0x27a>
	...

f0104460 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104460:	55                   	push   %ebp
f0104461:	89 e5                	mov    %esp,%ebp
f0104463:	57                   	push   %edi
f0104464:	56                   	push   %esi
f0104465:	53                   	push   %ebx
f0104466:	83 ec 3c             	sub    $0x3c,%esp
f0104469:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010446c:	89 d7                	mov    %edx,%edi
f010446e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104471:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0104474:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104477:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010447a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010447d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104480:	85 c0                	test   %eax,%eax
f0104482:	75 08                	jne    f010448c <printnum+0x2c>
f0104484:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104487:	39 45 10             	cmp    %eax,0x10(%ebp)
f010448a:	77 59                	ja     f01044e5 <printnum+0x85>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010448c:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104490:	83 eb 01             	sub    $0x1,%ebx
f0104493:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0104497:	8b 45 10             	mov    0x10(%ebp),%eax
f010449a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010449e:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f01044a2:	8b 74 24 0c          	mov    0xc(%esp),%esi
f01044a6:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01044ad:	00 
f01044ae:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01044b1:	89 04 24             	mov    %eax,(%esp)
f01044b4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01044b7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01044bb:	e8 b0 09 00 00       	call   f0104e70 <__udivdi3>
f01044c0:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01044c4:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01044c8:	89 04 24             	mov    %eax,(%esp)
f01044cb:	89 54 24 04          	mov    %edx,0x4(%esp)
f01044cf:	89 fa                	mov    %edi,%edx
f01044d1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01044d4:	e8 87 ff ff ff       	call   f0104460 <printnum>
f01044d9:	eb 11                	jmp    f01044ec <printnum+0x8c>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01044db:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01044df:	89 34 24             	mov    %esi,(%esp)
f01044e2:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01044e5:	83 eb 01             	sub    $0x1,%ebx
f01044e8:	85 db                	test   %ebx,%ebx
f01044ea:	7f ef                	jg     f01044db <printnum+0x7b>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01044ec:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01044f0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01044f4:	8b 45 10             	mov    0x10(%ebp),%eax
f01044f7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01044fb:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0104502:	00 
f0104503:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104506:	89 04 24             	mov    %eax,(%esp)
f0104509:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010450c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104510:	e8 8b 0a 00 00       	call   f0104fa0 <__umoddi3>
f0104515:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104519:	0f be 80 92 66 10 f0 	movsbl -0xfef996e(%eax),%eax
f0104520:	89 04 24             	mov    %eax,(%esp)
f0104523:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0104526:	83 c4 3c             	add    $0x3c,%esp
f0104529:	5b                   	pop    %ebx
f010452a:	5e                   	pop    %esi
f010452b:	5f                   	pop    %edi
f010452c:	5d                   	pop    %ebp
f010452d:	c3                   	ret    

f010452e <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010452e:	55                   	push   %ebp
f010452f:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104531:	83 fa 01             	cmp    $0x1,%edx
f0104534:	7e 0e                	jle    f0104544 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104536:	8b 10                	mov    (%eax),%edx
f0104538:	8d 4a 08             	lea    0x8(%edx),%ecx
f010453b:	89 08                	mov    %ecx,(%eax)
f010453d:	8b 02                	mov    (%edx),%eax
f010453f:	8b 52 04             	mov    0x4(%edx),%edx
f0104542:	eb 22                	jmp    f0104566 <getuint+0x38>
	else if (lflag)
f0104544:	85 d2                	test   %edx,%edx
f0104546:	74 10                	je     f0104558 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104548:	8b 10                	mov    (%eax),%edx
f010454a:	8d 4a 04             	lea    0x4(%edx),%ecx
f010454d:	89 08                	mov    %ecx,(%eax)
f010454f:	8b 02                	mov    (%edx),%eax
f0104551:	ba 00 00 00 00       	mov    $0x0,%edx
f0104556:	eb 0e                	jmp    f0104566 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104558:	8b 10                	mov    (%eax),%edx
f010455a:	8d 4a 04             	lea    0x4(%edx),%ecx
f010455d:	89 08                	mov    %ecx,(%eax)
f010455f:	8b 02                	mov    (%edx),%eax
f0104561:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104566:	5d                   	pop    %ebp
f0104567:	c3                   	ret    

f0104568 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104568:	55                   	push   %ebp
f0104569:	89 e5                	mov    %esp,%ebp
f010456b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010456e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104572:	8b 10                	mov    (%eax),%edx
f0104574:	3b 50 04             	cmp    0x4(%eax),%edx
f0104577:	73 0a                	jae    f0104583 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104579:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010457c:	88 0a                	mov    %cl,(%edx)
f010457e:	83 c2 01             	add    $0x1,%edx
f0104581:	89 10                	mov    %edx,(%eax)
}
f0104583:	5d                   	pop    %ebp
f0104584:	c3                   	ret    

f0104585 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104585:	55                   	push   %ebp
f0104586:	89 e5                	mov    %esp,%ebp
f0104588:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010458b:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010458e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104592:	8b 45 10             	mov    0x10(%ebp),%eax
f0104595:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104599:	8b 45 0c             	mov    0xc(%ebp),%eax
f010459c:	89 44 24 04          	mov    %eax,0x4(%esp)
f01045a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01045a3:	89 04 24             	mov    %eax,(%esp)
f01045a6:	e8 02 00 00 00       	call   f01045ad <vprintfmt>
	va_end(ap);
}
f01045ab:	c9                   	leave  
f01045ac:	c3                   	ret    

f01045ad <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01045ad:	55                   	push   %ebp
f01045ae:	89 e5                	mov    %esp,%ebp
f01045b0:	57                   	push   %edi
f01045b1:	56                   	push   %esi
f01045b2:	53                   	push   %ebx
f01045b3:	83 ec 4c             	sub    $0x4c,%esp
f01045b6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01045b9:	8b 75 10             	mov    0x10(%ebp),%esi
f01045bc:	eb 12                	jmp    f01045d0 <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01045be:	85 c0                	test   %eax,%eax
f01045c0:	0f 84 9f 03 00 00    	je     f0104965 <vprintfmt+0x3b8>
				return;
			putch(ch, putdat);
f01045c6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01045ca:	89 04 24             	mov    %eax,(%esp)
f01045cd:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01045d0:	0f b6 06             	movzbl (%esi),%eax
f01045d3:	83 c6 01             	add    $0x1,%esi
f01045d6:	83 f8 25             	cmp    $0x25,%eax
f01045d9:	75 e3                	jne    f01045be <vprintfmt+0x11>
f01045db:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f01045df:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01045e6:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f01045eb:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f01045f2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01045f7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01045fa:	eb 2b                	jmp    f0104627 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01045fc:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f01045ff:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0104603:	eb 22                	jmp    f0104627 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104605:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104608:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010460c:	eb 19                	jmp    f0104627 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010460e:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0104611:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0104618:	eb 0d                	jmp    f0104627 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010461a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010461d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104620:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104627:	0f b6 16             	movzbl (%esi),%edx
f010462a:	0f b6 c2             	movzbl %dl,%eax
f010462d:	8d 7e 01             	lea    0x1(%esi),%edi
f0104630:	89 7d e0             	mov    %edi,-0x20(%ebp)
f0104633:	83 ea 23             	sub    $0x23,%edx
f0104636:	80 fa 55             	cmp    $0x55,%dl
f0104639:	0f 87 08 03 00 00    	ja     f0104947 <vprintfmt+0x39a>
f010463f:	0f b6 d2             	movzbl %dl,%edx
f0104642:	ff 24 95 1c 67 10 f0 	jmp    *-0xfef98e4(,%edx,4)
f0104649:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010464c:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f0104653:	bf 00 00 00 00       	mov    $0x0,%edi
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104658:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f010465b:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f010465f:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0104662:	8d 50 d0             	lea    -0x30(%eax),%edx
f0104665:	83 fa 09             	cmp    $0x9,%edx
f0104668:	77 2f                	ja     f0104699 <vprintfmt+0xec>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010466a:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f010466d:	eb e9                	jmp    f0104658 <vprintfmt+0xab>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010466f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104672:	8d 50 04             	lea    0x4(%eax),%edx
f0104675:	89 55 14             	mov    %edx,0x14(%ebp)
f0104678:	8b 00                	mov    (%eax),%eax
f010467a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010467d:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104680:	eb 1a                	jmp    f010469c <vprintfmt+0xef>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104682:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f0104685:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104689:	79 9c                	jns    f0104627 <vprintfmt+0x7a>
f010468b:	eb 81                	jmp    f010460e <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010468d:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104690:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0104697:	eb 8e                	jmp    f0104627 <vprintfmt+0x7a>
f0104699:	89 7d d4             	mov    %edi,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f010469c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01046a0:	79 85                	jns    f0104627 <vprintfmt+0x7a>
f01046a2:	e9 73 ff ff ff       	jmp    f010461a <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01046a7:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046aa:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01046ad:	e9 75 ff ff ff       	jmp    f0104627 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01046b2:	8b 45 14             	mov    0x14(%ebp),%eax
f01046b5:	8d 50 04             	lea    0x4(%eax),%edx
f01046b8:	89 55 14             	mov    %edx,0x14(%ebp)
f01046bb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01046bf:	8b 00                	mov    (%eax),%eax
f01046c1:	89 04 24             	mov    %eax,(%esp)
f01046c4:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046c7:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01046ca:	e9 01 ff ff ff       	jmp    f01045d0 <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01046cf:	8b 45 14             	mov    0x14(%ebp),%eax
f01046d2:	8d 50 04             	lea    0x4(%eax),%edx
f01046d5:	89 55 14             	mov    %edx,0x14(%ebp)
f01046d8:	8b 00                	mov    (%eax),%eax
f01046da:	89 c2                	mov    %eax,%edx
f01046dc:	c1 fa 1f             	sar    $0x1f,%edx
f01046df:	31 d0                	xor    %edx,%eax
f01046e1:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01046e3:	83 f8 06             	cmp    $0x6,%eax
f01046e6:	7f 0b                	jg     f01046f3 <vprintfmt+0x146>
f01046e8:	8b 14 85 74 68 10 f0 	mov    -0xfef978c(,%eax,4),%edx
f01046ef:	85 d2                	test   %edx,%edx
f01046f1:	75 23                	jne    f0104716 <vprintfmt+0x169>
				printfmt(putch, putdat, "error %d", err);
f01046f3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01046f7:	c7 44 24 08 aa 66 10 	movl   $0xf01066aa,0x8(%esp)
f01046fe:	f0 
f01046ff:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104703:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104706:	89 3c 24             	mov    %edi,(%esp)
f0104709:	e8 77 fe ff ff       	call   f0104585 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010470e:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104711:	e9 ba fe ff ff       	jmp    f01045d0 <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0104716:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010471a:	c7 44 24 08 8d 5e 10 	movl   $0xf0105e8d,0x8(%esp)
f0104721:	f0 
f0104722:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104726:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104729:	89 3c 24             	mov    %edi,(%esp)
f010472c:	e8 54 fe ff ff       	call   f0104585 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104731:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104734:	e9 97 fe ff ff       	jmp    f01045d0 <vprintfmt+0x23>
f0104739:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010473c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010473f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104742:	8b 45 14             	mov    0x14(%ebp),%eax
f0104745:	8d 50 04             	lea    0x4(%eax),%edx
f0104748:	89 55 14             	mov    %edx,0x14(%ebp)
f010474b:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010474d:	85 f6                	test   %esi,%esi
f010474f:	ba a3 66 10 f0       	mov    $0xf01066a3,%edx
f0104754:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f0104757:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f010475b:	0f 8e 8c 00 00 00    	jle    f01047ed <vprintfmt+0x240>
f0104761:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0104765:	0f 84 82 00 00 00    	je     f01047ed <vprintfmt+0x240>
				for (width -= strnlen(p, precision); width > 0; width--)
f010476b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010476f:	89 34 24             	mov    %esi,(%esp)
f0104772:	e8 61 03 00 00       	call   f0104ad8 <strnlen>
f0104777:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010477a:	29 c2                	sub    %eax,%edx
f010477c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
					putch(padc, putdat);
f010477f:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0104783:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0104786:	89 7d cc             	mov    %edi,-0x34(%ebp)
f0104789:	89 de                	mov    %ebx,%esi
f010478b:	89 d3                	mov    %edx,%ebx
f010478d:	89 c7                	mov    %eax,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010478f:	eb 0d                	jmp    f010479e <vprintfmt+0x1f1>
					putch(padc, putdat);
f0104791:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104795:	89 3c 24             	mov    %edi,(%esp)
f0104798:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010479b:	83 eb 01             	sub    $0x1,%ebx
f010479e:	85 db                	test   %ebx,%ebx
f01047a0:	7f ef                	jg     f0104791 <vprintfmt+0x1e4>
f01047a2:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01047a5:	89 f3                	mov    %esi,%ebx
f01047a7:	8b 75 d0             	mov    -0x30(%ebp),%esi

// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
f01047aa:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01047ae:	b8 00 00 00 00       	mov    $0x0,%eax
f01047b3:	0f 49 45 e4          	cmovns -0x1c(%ebp),%eax
f01047b7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01047ba:	29 c2                	sub    %eax,%edx
f01047bc:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01047bf:	eb 2c                	jmp    f01047ed <vprintfmt+0x240>
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01047c1:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01047c5:	74 18                	je     f01047df <vprintfmt+0x232>
f01047c7:	8d 50 e0             	lea    -0x20(%eax),%edx
f01047ca:	83 fa 5e             	cmp    $0x5e,%edx
f01047cd:	76 10                	jbe    f01047df <vprintfmt+0x232>
					putch('?', putdat);
f01047cf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01047d3:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01047da:	ff 55 08             	call   *0x8(%ebp)
f01047dd:	eb 0a                	jmp    f01047e9 <vprintfmt+0x23c>
				else
					putch(ch, putdat);
f01047df:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01047e3:	89 04 24             	mov    %eax,(%esp)
f01047e6:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01047e9:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f01047ed:	0f be 06             	movsbl (%esi),%eax
f01047f0:	83 c6 01             	add    $0x1,%esi
f01047f3:	85 c0                	test   %eax,%eax
f01047f5:	74 25                	je     f010481c <vprintfmt+0x26f>
f01047f7:	85 ff                	test   %edi,%edi
f01047f9:	78 c6                	js     f01047c1 <vprintfmt+0x214>
f01047fb:	83 ef 01             	sub    $0x1,%edi
f01047fe:	79 c1                	jns    f01047c1 <vprintfmt+0x214>
f0104800:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104803:	89 de                	mov    %ebx,%esi
f0104805:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104808:	eb 1a                	jmp    f0104824 <vprintfmt+0x277>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010480a:	89 74 24 04          	mov    %esi,0x4(%esp)
f010480e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0104815:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104817:	83 eb 01             	sub    $0x1,%ebx
f010481a:	eb 08                	jmp    f0104824 <vprintfmt+0x277>
f010481c:	8b 7d 08             	mov    0x8(%ebp),%edi
f010481f:	89 de                	mov    %ebx,%esi
f0104821:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104824:	85 db                	test   %ebx,%ebx
f0104826:	7f e2                	jg     f010480a <vprintfmt+0x25d>
f0104828:	89 7d 08             	mov    %edi,0x8(%ebp)
f010482b:	89 f3                	mov    %esi,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010482d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104830:	e9 9b fd ff ff       	jmp    f01045d0 <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104835:	83 f9 01             	cmp    $0x1,%ecx
f0104838:	7e 10                	jle    f010484a <vprintfmt+0x29d>
		return va_arg(*ap, long long);
f010483a:	8b 45 14             	mov    0x14(%ebp),%eax
f010483d:	8d 50 08             	lea    0x8(%eax),%edx
f0104840:	89 55 14             	mov    %edx,0x14(%ebp)
f0104843:	8b 30                	mov    (%eax),%esi
f0104845:	8b 78 04             	mov    0x4(%eax),%edi
f0104848:	eb 26                	jmp    f0104870 <vprintfmt+0x2c3>
	else if (lflag)
f010484a:	85 c9                	test   %ecx,%ecx
f010484c:	74 12                	je     f0104860 <vprintfmt+0x2b3>
		return va_arg(*ap, long);
f010484e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104851:	8d 50 04             	lea    0x4(%eax),%edx
f0104854:	89 55 14             	mov    %edx,0x14(%ebp)
f0104857:	8b 30                	mov    (%eax),%esi
f0104859:	89 f7                	mov    %esi,%edi
f010485b:	c1 ff 1f             	sar    $0x1f,%edi
f010485e:	eb 10                	jmp    f0104870 <vprintfmt+0x2c3>
	else
		return va_arg(*ap, int);
f0104860:	8b 45 14             	mov    0x14(%ebp),%eax
f0104863:	8d 50 04             	lea    0x4(%eax),%edx
f0104866:	89 55 14             	mov    %edx,0x14(%ebp)
f0104869:	8b 30                	mov    (%eax),%esi
f010486b:	89 f7                	mov    %esi,%edi
f010486d:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104870:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104875:	85 ff                	test   %edi,%edi
f0104877:	0f 89 8c 00 00 00    	jns    f0104909 <vprintfmt+0x35c>
				putch('-', putdat);
f010487d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104881:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0104888:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010488b:	f7 de                	neg    %esi
f010488d:	83 d7 00             	adc    $0x0,%edi
f0104890:	f7 df                	neg    %edi
			}
			base = 10;
f0104892:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104897:	eb 70                	jmp    f0104909 <vprintfmt+0x35c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104899:	89 ca                	mov    %ecx,%edx
f010489b:	8d 45 14             	lea    0x14(%ebp),%eax
f010489e:	e8 8b fc ff ff       	call   f010452e <getuint>
f01048a3:	89 c6                	mov    %eax,%esi
f01048a5:	89 d7                	mov    %edx,%edi
			base = 10;
f01048a7:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f01048ac:	eb 5b                	jmp    f0104909 <vprintfmt+0x35c>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num=getuint(&ap,lflag);
f01048ae:	89 ca                	mov    %ecx,%edx
f01048b0:	8d 45 14             	lea    0x14(%ebp),%eax
f01048b3:	e8 76 fc ff ff       	call   f010452e <getuint>
f01048b8:	89 c6                	mov    %eax,%esi
f01048ba:	89 d7                	mov    %edx,%edi
			base = 8;
f01048bc:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f01048c1:	eb 46                	jmp    f0104909 <vprintfmt+0x35c>
	
		// pointer
		case 'p':
			putch('0', putdat);
f01048c3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01048c7:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01048ce:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01048d1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01048d5:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01048dc:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01048df:	8b 45 14             	mov    0x14(%ebp),%eax
f01048e2:	8d 50 04             	lea    0x4(%eax),%edx
f01048e5:	89 55 14             	mov    %edx,0x14(%ebp)
	
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01048e8:	8b 30                	mov    (%eax),%esi
f01048ea:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01048ef:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01048f4:	eb 13                	jmp    f0104909 <vprintfmt+0x35c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01048f6:	89 ca                	mov    %ecx,%edx
f01048f8:	8d 45 14             	lea    0x14(%ebp),%eax
f01048fb:	e8 2e fc ff ff       	call   f010452e <getuint>
f0104900:	89 c6                	mov    %eax,%esi
f0104902:	89 d7                	mov    %edx,%edi
			base = 16;
f0104904:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104909:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f010490d:	89 54 24 10          	mov    %edx,0x10(%esp)
f0104911:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104914:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104918:	89 44 24 08          	mov    %eax,0x8(%esp)
f010491c:	89 34 24             	mov    %esi,(%esp)
f010491f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104923:	89 da                	mov    %ebx,%edx
f0104925:	8b 45 08             	mov    0x8(%ebp),%eax
f0104928:	e8 33 fb ff ff       	call   f0104460 <printnum>
			break;
f010492d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104930:	e9 9b fc ff ff       	jmp    f01045d0 <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104935:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104939:	89 04 24             	mov    %eax,(%esp)
f010493c:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010493f:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0104942:	e9 89 fc ff ff       	jmp    f01045d0 <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104947:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010494b:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0104952:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104955:	eb 03                	jmp    f010495a <vprintfmt+0x3ad>
f0104957:	83 ee 01             	sub    $0x1,%esi
f010495a:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f010495e:	75 f7                	jne    f0104957 <vprintfmt+0x3aa>
f0104960:	e9 6b fc ff ff       	jmp    f01045d0 <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f0104965:	83 c4 4c             	add    $0x4c,%esp
f0104968:	5b                   	pop    %ebx
f0104969:	5e                   	pop    %esi
f010496a:	5f                   	pop    %edi
f010496b:	5d                   	pop    %ebp
f010496c:	c3                   	ret    

f010496d <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010496d:	55                   	push   %ebp
f010496e:	89 e5                	mov    %esp,%ebp
f0104970:	83 ec 28             	sub    $0x28,%esp
f0104973:	8b 45 08             	mov    0x8(%ebp),%eax
f0104976:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104979:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010497c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104980:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104983:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010498a:	85 c0                	test   %eax,%eax
f010498c:	74 30                	je     f01049be <vsnprintf+0x51>
f010498e:	85 d2                	test   %edx,%edx
f0104990:	7e 2c                	jle    f01049be <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104992:	8b 45 14             	mov    0x14(%ebp),%eax
f0104995:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104999:	8b 45 10             	mov    0x10(%ebp),%eax
f010499c:	89 44 24 08          	mov    %eax,0x8(%esp)
f01049a0:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01049a3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01049a7:	c7 04 24 68 45 10 f0 	movl   $0xf0104568,(%esp)
f01049ae:	e8 fa fb ff ff       	call   f01045ad <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01049b3:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01049b6:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01049b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01049bc:	eb 05                	jmp    f01049c3 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01049be:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01049c3:	c9                   	leave  
f01049c4:	c3                   	ret    

f01049c5 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01049c5:	55                   	push   %ebp
f01049c6:	89 e5                	mov    %esp,%ebp
f01049c8:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01049cb:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01049ce:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01049d2:	8b 45 10             	mov    0x10(%ebp),%eax
f01049d5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01049d9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01049dc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01049e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01049e3:	89 04 24             	mov    %eax,(%esp)
f01049e6:	e8 82 ff ff ff       	call   f010496d <vsnprintf>
	va_end(ap);

	return rc;
}
f01049eb:	c9                   	leave  
f01049ec:	c3                   	ret    
f01049ed:	00 00                	add    %al,(%eax)
	...

f01049f0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01049f0:	55                   	push   %ebp
f01049f1:	89 e5                	mov    %esp,%ebp
f01049f3:	57                   	push   %edi
f01049f4:	56                   	push   %esi
f01049f5:	53                   	push   %ebx
f01049f6:	83 ec 1c             	sub    $0x1c,%esp
f01049f9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01049fc:	85 c0                	test   %eax,%eax
f01049fe:	74 10                	je     f0104a10 <readline+0x20>
		cprintf("%s", prompt);
f0104a00:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104a04:	c7 04 24 8d 5e 10 f0 	movl   $0xf0105e8d,(%esp)
f0104a0b:	e8 16 ed ff ff       	call   f0103726 <cprintf>

	i = 0;
	echoing = iscons(0);
f0104a10:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104a17:	e8 11 bc ff ff       	call   f010062d <iscons>
f0104a1c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104a1e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104a23:	e8 f4 bb ff ff       	call   f010061c <getchar>
f0104a28:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104a2a:	85 c0                	test   %eax,%eax
f0104a2c:	79 17                	jns    f0104a45 <readline+0x55>
			cprintf("read error: %e\n", c);
f0104a2e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104a32:	c7 04 24 90 68 10 f0 	movl   $0xf0106890,(%esp)
f0104a39:	e8 e8 ec ff ff       	call   f0103726 <cprintf>
			return NULL;
f0104a3e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a43:	eb 6d                	jmp    f0104ab2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104a45:	83 f8 08             	cmp    $0x8,%eax
f0104a48:	74 05                	je     f0104a4f <readline+0x5f>
f0104a4a:	83 f8 7f             	cmp    $0x7f,%eax
f0104a4d:	75 19                	jne    f0104a68 <readline+0x78>
f0104a4f:	85 f6                	test   %esi,%esi
f0104a51:	7e 15                	jle    f0104a68 <readline+0x78>
			if (echoing)
f0104a53:	85 ff                	test   %edi,%edi
f0104a55:	74 0c                	je     f0104a63 <readline+0x73>
				cputchar('\b');
f0104a57:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0104a5e:	e8 a9 bb ff ff       	call   f010060c <cputchar>
			i--;
f0104a63:	83 ee 01             	sub    $0x1,%esi
f0104a66:	eb bb                	jmp    f0104a23 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104a68:	83 fb 1f             	cmp    $0x1f,%ebx
f0104a6b:	7e 1f                	jle    f0104a8c <readline+0x9c>
f0104a6d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104a73:	7f 17                	jg     f0104a8c <readline+0x9c>
			if (echoing)
f0104a75:	85 ff                	test   %edi,%edi
f0104a77:	74 08                	je     f0104a81 <readline+0x91>
				cputchar(c);
f0104a79:	89 1c 24             	mov    %ebx,(%esp)
f0104a7c:	e8 8b bb ff ff       	call   f010060c <cputchar>
			buf[i++] = c;
f0104a81:	88 9e 20 e8 17 f0    	mov    %bl,-0xfe817e0(%esi)
f0104a87:	83 c6 01             	add    $0x1,%esi
f0104a8a:	eb 97                	jmp    f0104a23 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0104a8c:	83 fb 0a             	cmp    $0xa,%ebx
f0104a8f:	74 05                	je     f0104a96 <readline+0xa6>
f0104a91:	83 fb 0d             	cmp    $0xd,%ebx
f0104a94:	75 8d                	jne    f0104a23 <readline+0x33>
			if (echoing)
f0104a96:	85 ff                	test   %edi,%edi
f0104a98:	74 0c                	je     f0104aa6 <readline+0xb6>
				cputchar('\n');
f0104a9a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0104aa1:	e8 66 bb ff ff       	call   f010060c <cputchar>
			buf[i] = 0;
f0104aa6:	c6 86 20 e8 17 f0 00 	movb   $0x0,-0xfe817e0(%esi)
			return buf;
f0104aad:	b8 20 e8 17 f0       	mov    $0xf017e820,%eax
		}
	}
}
f0104ab2:	83 c4 1c             	add    $0x1c,%esp
f0104ab5:	5b                   	pop    %ebx
f0104ab6:	5e                   	pop    %esi
f0104ab7:	5f                   	pop    %edi
f0104ab8:	5d                   	pop    %ebp
f0104ab9:	c3                   	ret    
f0104aba:	00 00                	add    %al,(%eax)
f0104abc:	00 00                	add    %al,(%eax)
	...

f0104ac0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104ac0:	55                   	push   %ebp
f0104ac1:	89 e5                	mov    %esp,%ebp
f0104ac3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104ac6:	b8 00 00 00 00       	mov    $0x0,%eax
f0104acb:	eb 03                	jmp    f0104ad0 <strlen+0x10>
		n++;
f0104acd:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104ad0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104ad4:	75 f7                	jne    f0104acd <strlen+0xd>
		n++;
	return n;
}
f0104ad6:	5d                   	pop    %ebp
f0104ad7:	c3                   	ret    

f0104ad8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104ad8:	55                   	push   %ebp
f0104ad9:	89 e5                	mov    %esp,%ebp
f0104adb:	8b 4d 08             	mov    0x8(%ebp),%ecx
		n++;
	return n;
}

int
strnlen(const char *s, size_t size)
f0104ade:	8b 55 0c             	mov    0xc(%ebp),%edx
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104ae1:	b8 00 00 00 00       	mov    $0x0,%eax
f0104ae6:	eb 03                	jmp    f0104aeb <strnlen+0x13>
		n++;
f0104ae8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104aeb:	39 d0                	cmp    %edx,%eax
f0104aed:	74 06                	je     f0104af5 <strnlen+0x1d>
f0104aef:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0104af3:	75 f3                	jne    f0104ae8 <strnlen+0x10>
		n++;
	return n;
}
f0104af5:	5d                   	pop    %ebp
f0104af6:	c3                   	ret    

f0104af7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104af7:	55                   	push   %ebp
f0104af8:	89 e5                	mov    %esp,%ebp
f0104afa:	53                   	push   %ebx
f0104afb:	8b 45 08             	mov    0x8(%ebp),%eax
f0104afe:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104b01:	ba 00 00 00 00       	mov    $0x0,%edx
f0104b06:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0104b0a:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0104b0d:	83 c2 01             	add    $0x1,%edx
f0104b10:	84 c9                	test   %cl,%cl
f0104b12:	75 f2                	jne    f0104b06 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0104b14:	5b                   	pop    %ebx
f0104b15:	5d                   	pop    %ebp
f0104b16:	c3                   	ret    

f0104b17 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104b17:	55                   	push   %ebp
f0104b18:	89 e5                	mov    %esp,%ebp
f0104b1a:	53                   	push   %ebx
f0104b1b:	83 ec 08             	sub    $0x8,%esp
f0104b1e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104b21:	89 1c 24             	mov    %ebx,(%esp)
f0104b24:	e8 97 ff ff ff       	call   f0104ac0 <strlen>
	strcpy(dst + len, src);
f0104b29:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104b2c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104b30:	01 d8                	add    %ebx,%eax
f0104b32:	89 04 24             	mov    %eax,(%esp)
f0104b35:	e8 bd ff ff ff       	call   f0104af7 <strcpy>
	return dst;
}
f0104b3a:	89 d8                	mov    %ebx,%eax
f0104b3c:	83 c4 08             	add    $0x8,%esp
f0104b3f:	5b                   	pop    %ebx
f0104b40:	5d                   	pop    %ebp
f0104b41:	c3                   	ret    

f0104b42 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104b42:	55                   	push   %ebp
f0104b43:	89 e5                	mov    %esp,%ebp
f0104b45:	56                   	push   %esi
f0104b46:	53                   	push   %ebx
f0104b47:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b4a:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104b4d:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104b50:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104b55:	eb 0f                	jmp    f0104b66 <strncpy+0x24>
		*dst++ = *src;
f0104b57:	0f b6 1a             	movzbl (%edx),%ebx
f0104b5a:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104b5d:	80 3a 01             	cmpb   $0x1,(%edx)
f0104b60:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104b63:	83 c1 01             	add    $0x1,%ecx
f0104b66:	39 f1                	cmp    %esi,%ecx
f0104b68:	75 ed                	jne    f0104b57 <strncpy+0x15>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104b6a:	5b                   	pop    %ebx
f0104b6b:	5e                   	pop    %esi
f0104b6c:	5d                   	pop    %ebp
f0104b6d:	c3                   	ret    

f0104b6e <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104b6e:	55                   	push   %ebp
f0104b6f:	89 e5                	mov    %esp,%ebp
f0104b71:	56                   	push   %esi
f0104b72:	53                   	push   %ebx
f0104b73:	8b 75 08             	mov    0x8(%ebp),%esi
f0104b76:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104b79:	8b 55 10             	mov    0x10(%ebp),%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104b7c:	89 f0                	mov    %esi,%eax
f0104b7e:	85 d2                	test   %edx,%edx
f0104b80:	75 0a                	jne    f0104b8c <strlcpy+0x1e>
f0104b82:	eb 1d                	jmp    f0104ba1 <strlcpy+0x33>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104b84:	88 18                	mov    %bl,(%eax)
f0104b86:	83 c0 01             	add    $0x1,%eax
f0104b89:	83 c1 01             	add    $0x1,%ecx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104b8c:	83 ea 01             	sub    $0x1,%edx
f0104b8f:	74 0b                	je     f0104b9c <strlcpy+0x2e>
f0104b91:	0f b6 19             	movzbl (%ecx),%ebx
f0104b94:	84 db                	test   %bl,%bl
f0104b96:	75 ec                	jne    f0104b84 <strlcpy+0x16>
f0104b98:	89 c2                	mov    %eax,%edx
f0104b9a:	eb 02                	jmp    f0104b9e <strlcpy+0x30>
f0104b9c:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0104b9e:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0104ba1:	29 f0                	sub    %esi,%eax
}
f0104ba3:	5b                   	pop    %ebx
f0104ba4:	5e                   	pop    %esi
f0104ba5:	5d                   	pop    %ebp
f0104ba6:	c3                   	ret    

f0104ba7 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104ba7:	55                   	push   %ebp
f0104ba8:	89 e5                	mov    %esp,%ebp
f0104baa:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104bad:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104bb0:	eb 06                	jmp    f0104bb8 <strcmp+0x11>
		p++, q++;
f0104bb2:	83 c1 01             	add    $0x1,%ecx
f0104bb5:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104bb8:	0f b6 01             	movzbl (%ecx),%eax
f0104bbb:	84 c0                	test   %al,%al
f0104bbd:	74 04                	je     f0104bc3 <strcmp+0x1c>
f0104bbf:	3a 02                	cmp    (%edx),%al
f0104bc1:	74 ef                	je     f0104bb2 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104bc3:	0f b6 c0             	movzbl %al,%eax
f0104bc6:	0f b6 12             	movzbl (%edx),%edx
f0104bc9:	29 d0                	sub    %edx,%eax
}
f0104bcb:	5d                   	pop    %ebp
f0104bcc:	c3                   	ret    

f0104bcd <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104bcd:	55                   	push   %ebp
f0104bce:	89 e5                	mov    %esp,%ebp
f0104bd0:	53                   	push   %ebx
f0104bd1:	8b 45 08             	mov    0x8(%ebp),%eax
f0104bd4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104bd7:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
f0104bda:	eb 09                	jmp    f0104be5 <strncmp+0x18>
		n--, p++, q++;
f0104bdc:	83 ea 01             	sub    $0x1,%edx
f0104bdf:	83 c0 01             	add    $0x1,%eax
f0104be2:	83 c1 01             	add    $0x1,%ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104be5:	85 d2                	test   %edx,%edx
f0104be7:	74 15                	je     f0104bfe <strncmp+0x31>
f0104be9:	0f b6 18             	movzbl (%eax),%ebx
f0104bec:	84 db                	test   %bl,%bl
f0104bee:	74 04                	je     f0104bf4 <strncmp+0x27>
f0104bf0:	3a 19                	cmp    (%ecx),%bl
f0104bf2:	74 e8                	je     f0104bdc <strncmp+0xf>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104bf4:	0f b6 00             	movzbl (%eax),%eax
f0104bf7:	0f b6 11             	movzbl (%ecx),%edx
f0104bfa:	29 d0                	sub    %edx,%eax
f0104bfc:	eb 05                	jmp    f0104c03 <strncmp+0x36>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104bfe:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104c03:	5b                   	pop    %ebx
f0104c04:	5d                   	pop    %ebp
f0104c05:	c3                   	ret    

f0104c06 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104c06:	55                   	push   %ebp
f0104c07:	89 e5                	mov    %esp,%ebp
f0104c09:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c0c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104c10:	eb 07                	jmp    f0104c19 <strchr+0x13>
		if (*s == c)
f0104c12:	38 ca                	cmp    %cl,%dl
f0104c14:	74 0f                	je     f0104c25 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104c16:	83 c0 01             	add    $0x1,%eax
f0104c19:	0f b6 10             	movzbl (%eax),%edx
f0104c1c:	84 d2                	test   %dl,%dl
f0104c1e:	75 f2                	jne    f0104c12 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104c20:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104c25:	5d                   	pop    %ebp
f0104c26:	c3                   	ret    

f0104c27 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104c27:	55                   	push   %ebp
f0104c28:	89 e5                	mov    %esp,%ebp
f0104c2a:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c2d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104c31:	eb 07                	jmp    f0104c3a <strfind+0x13>
		if (*s == c)
f0104c33:	38 ca                	cmp    %cl,%dl
f0104c35:	74 0a                	je     f0104c41 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0104c37:	83 c0 01             	add    $0x1,%eax
f0104c3a:	0f b6 10             	movzbl (%eax),%edx
f0104c3d:	84 d2                	test   %dl,%dl
f0104c3f:	75 f2                	jne    f0104c33 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0104c41:	5d                   	pop    %ebp
f0104c42:	c3                   	ret    

f0104c43 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104c43:	55                   	push   %ebp
f0104c44:	89 e5                	mov    %esp,%ebp
f0104c46:	83 ec 0c             	sub    $0xc,%esp
f0104c49:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0104c4c:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0104c4f:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104c52:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104c55:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104c58:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104c5b:	85 c9                	test   %ecx,%ecx
f0104c5d:	74 30                	je     f0104c8f <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104c5f:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104c65:	75 25                	jne    f0104c8c <memset+0x49>
f0104c67:	f6 c1 03             	test   $0x3,%cl
f0104c6a:	75 20                	jne    f0104c8c <memset+0x49>
		c &= 0xFF;
f0104c6c:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104c6f:	89 d3                	mov    %edx,%ebx
f0104c71:	c1 e3 08             	shl    $0x8,%ebx
f0104c74:	89 d6                	mov    %edx,%esi
f0104c76:	c1 e6 18             	shl    $0x18,%esi
f0104c79:	89 d0                	mov    %edx,%eax
f0104c7b:	c1 e0 10             	shl    $0x10,%eax
f0104c7e:	09 f0                	or     %esi,%eax
f0104c80:	09 d0                	or     %edx,%eax
f0104c82:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104c84:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104c87:	fc                   	cld    
f0104c88:	f3 ab                	rep stos %eax,%es:(%edi)
f0104c8a:	eb 03                	jmp    f0104c8f <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104c8c:	fc                   	cld    
f0104c8d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104c8f:	89 f8                	mov    %edi,%eax
f0104c91:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0104c94:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0104c97:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104c9a:	89 ec                	mov    %ebp,%esp
f0104c9c:	5d                   	pop    %ebp
f0104c9d:	c3                   	ret    

f0104c9e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104c9e:	55                   	push   %ebp
f0104c9f:	89 e5                	mov    %esp,%ebp
f0104ca1:	83 ec 08             	sub    $0x8,%esp
f0104ca4:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0104ca7:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104caa:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cad:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104cb0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104cb3:	39 c6                	cmp    %eax,%esi
f0104cb5:	73 36                	jae    f0104ced <memmove+0x4f>
f0104cb7:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104cba:	39 d0                	cmp    %edx,%eax
f0104cbc:	73 2f                	jae    f0104ced <memmove+0x4f>
		s += n;
		d += n;
f0104cbe:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104cc1:	f6 c2 03             	test   $0x3,%dl
f0104cc4:	75 1b                	jne    f0104ce1 <memmove+0x43>
f0104cc6:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104ccc:	75 13                	jne    f0104ce1 <memmove+0x43>
f0104cce:	f6 c1 03             	test   $0x3,%cl
f0104cd1:	75 0e                	jne    f0104ce1 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104cd3:	83 ef 04             	sub    $0x4,%edi
f0104cd6:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104cd9:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0104cdc:	fd                   	std    
f0104cdd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104cdf:	eb 09                	jmp    f0104cea <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0104ce1:	83 ef 01             	sub    $0x1,%edi
f0104ce4:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104ce7:	fd                   	std    
f0104ce8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104cea:	fc                   	cld    
f0104ceb:	eb 20                	jmp    f0104d0d <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104ced:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104cf3:	75 13                	jne    f0104d08 <memmove+0x6a>
f0104cf5:	a8 03                	test   $0x3,%al
f0104cf7:	75 0f                	jne    f0104d08 <memmove+0x6a>
f0104cf9:	f6 c1 03             	test   $0x3,%cl
f0104cfc:	75 0a                	jne    f0104d08 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0104cfe:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0104d01:	89 c7                	mov    %eax,%edi
f0104d03:	fc                   	cld    
f0104d04:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104d06:	eb 05                	jmp    f0104d0d <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104d08:	89 c7                	mov    %eax,%edi
f0104d0a:	fc                   	cld    
f0104d0b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104d0d:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0104d10:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104d13:	89 ec                	mov    %ebp,%esp
f0104d15:	5d                   	pop    %ebp
f0104d16:	c3                   	ret    

f0104d17 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104d17:	55                   	push   %ebp
f0104d18:	89 e5                	mov    %esp,%ebp
f0104d1a:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0104d1d:	8b 45 10             	mov    0x10(%ebp),%eax
f0104d20:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104d24:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104d27:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104d2b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d2e:	89 04 24             	mov    %eax,(%esp)
f0104d31:	e8 68 ff ff ff       	call   f0104c9e <memmove>
}
f0104d36:	c9                   	leave  
f0104d37:	c3                   	ret    

f0104d38 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104d38:	55                   	push   %ebp
f0104d39:	89 e5                	mov    %esp,%ebp
f0104d3b:	57                   	push   %edi
f0104d3c:	56                   	push   %esi
f0104d3d:	53                   	push   %ebx
f0104d3e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104d41:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104d44:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104d47:	ba 00 00 00 00       	mov    $0x0,%edx
f0104d4c:	eb 1a                	jmp    f0104d68 <memcmp+0x30>
		if (*s1 != *s2)
f0104d4e:	0f b6 04 17          	movzbl (%edi,%edx,1),%eax
f0104d52:	83 c2 01             	add    $0x1,%edx
f0104d55:	0f b6 4c 16 ff       	movzbl -0x1(%esi,%edx,1),%ecx
f0104d5a:	38 c8                	cmp    %cl,%al
f0104d5c:	74 0a                	je     f0104d68 <memcmp+0x30>
			return (int) *s1 - (int) *s2;
f0104d5e:	0f b6 c0             	movzbl %al,%eax
f0104d61:	0f b6 c9             	movzbl %cl,%ecx
f0104d64:	29 c8                	sub    %ecx,%eax
f0104d66:	eb 09                	jmp    f0104d71 <memcmp+0x39>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104d68:	39 da                	cmp    %ebx,%edx
f0104d6a:	75 e2                	jne    f0104d4e <memcmp+0x16>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104d6c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104d71:	5b                   	pop    %ebx
f0104d72:	5e                   	pop    %esi
f0104d73:	5f                   	pop    %edi
f0104d74:	5d                   	pop    %ebp
f0104d75:	c3                   	ret    

f0104d76 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104d76:	55                   	push   %ebp
f0104d77:	89 e5                	mov    %esp,%ebp
f0104d79:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d7c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0104d7f:	89 c2                	mov    %eax,%edx
f0104d81:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104d84:	eb 07                	jmp    f0104d8d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104d86:	38 08                	cmp    %cl,(%eax)
f0104d88:	74 07                	je     f0104d91 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104d8a:	83 c0 01             	add    $0x1,%eax
f0104d8d:	39 d0                	cmp    %edx,%eax
f0104d8f:	72 f5                	jb     f0104d86 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104d91:	5d                   	pop    %ebp
f0104d92:	c3                   	ret    

f0104d93 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104d93:	55                   	push   %ebp
f0104d94:	89 e5                	mov    %esp,%ebp
f0104d96:	57                   	push   %edi
f0104d97:	56                   	push   %esi
f0104d98:	53                   	push   %ebx
f0104d99:	8b 55 08             	mov    0x8(%ebp),%edx
f0104d9c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104d9f:	eb 03                	jmp    f0104da4 <strtol+0x11>
		s++;
f0104da1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104da4:	0f b6 02             	movzbl (%edx),%eax
f0104da7:	3c 20                	cmp    $0x20,%al
f0104da9:	74 f6                	je     f0104da1 <strtol+0xe>
f0104dab:	3c 09                	cmp    $0x9,%al
f0104dad:	74 f2                	je     f0104da1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104daf:	3c 2b                	cmp    $0x2b,%al
f0104db1:	75 0a                	jne    f0104dbd <strtol+0x2a>
		s++;
f0104db3:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104db6:	bf 00 00 00 00       	mov    $0x0,%edi
f0104dbb:	eb 10                	jmp    f0104dcd <strtol+0x3a>
f0104dbd:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104dc2:	3c 2d                	cmp    $0x2d,%al
f0104dc4:	75 07                	jne    f0104dcd <strtol+0x3a>
		s++, neg = 1;
f0104dc6:	8d 52 01             	lea    0x1(%edx),%edx
f0104dc9:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104dcd:	85 db                	test   %ebx,%ebx
f0104dcf:	0f 94 c0             	sete   %al
f0104dd2:	74 05                	je     f0104dd9 <strtol+0x46>
f0104dd4:	83 fb 10             	cmp    $0x10,%ebx
f0104dd7:	75 15                	jne    f0104dee <strtol+0x5b>
f0104dd9:	80 3a 30             	cmpb   $0x30,(%edx)
f0104ddc:	75 10                	jne    f0104dee <strtol+0x5b>
f0104dde:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0104de2:	75 0a                	jne    f0104dee <strtol+0x5b>
		s += 2, base = 16;
f0104de4:	83 c2 02             	add    $0x2,%edx
f0104de7:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104dec:	eb 13                	jmp    f0104e01 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0104dee:	84 c0                	test   %al,%al
f0104df0:	74 0f                	je     f0104e01 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104df2:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104df7:	80 3a 30             	cmpb   $0x30,(%edx)
f0104dfa:	75 05                	jne    f0104e01 <strtol+0x6e>
		s++, base = 8;
f0104dfc:	83 c2 01             	add    $0x1,%edx
f0104dff:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0104e01:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e06:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104e08:	0f b6 0a             	movzbl (%edx),%ecx
f0104e0b:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0104e0e:	80 fb 09             	cmp    $0x9,%bl
f0104e11:	77 08                	ja     f0104e1b <strtol+0x88>
			dig = *s - '0';
f0104e13:	0f be c9             	movsbl %cl,%ecx
f0104e16:	83 e9 30             	sub    $0x30,%ecx
f0104e19:	eb 1e                	jmp    f0104e39 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0104e1b:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0104e1e:	80 fb 19             	cmp    $0x19,%bl
f0104e21:	77 08                	ja     f0104e2b <strtol+0x98>
			dig = *s - 'a' + 10;
f0104e23:	0f be c9             	movsbl %cl,%ecx
f0104e26:	83 e9 57             	sub    $0x57,%ecx
f0104e29:	eb 0e                	jmp    f0104e39 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0104e2b:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0104e2e:	80 fb 19             	cmp    $0x19,%bl
f0104e31:	77 14                	ja     f0104e47 <strtol+0xb4>
			dig = *s - 'A' + 10;
f0104e33:	0f be c9             	movsbl %cl,%ecx
f0104e36:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0104e39:	39 f1                	cmp    %esi,%ecx
f0104e3b:	7d 0e                	jge    f0104e4b <strtol+0xb8>
			break;
		s++, val = (val * base) + dig;
f0104e3d:	83 c2 01             	add    $0x1,%edx
f0104e40:	0f af c6             	imul   %esi,%eax
f0104e43:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0104e45:	eb c1                	jmp    f0104e08 <strtol+0x75>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0104e47:	89 c1                	mov    %eax,%ecx
f0104e49:	eb 02                	jmp    f0104e4d <strtol+0xba>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0104e4b:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0104e4d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104e51:	74 05                	je     f0104e58 <strtol+0xc5>
		*endptr = (char *) s;
f0104e53:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104e56:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0104e58:	89 ca                	mov    %ecx,%edx
f0104e5a:	f7 da                	neg    %edx
f0104e5c:	85 ff                	test   %edi,%edi
f0104e5e:	0f 45 c2             	cmovne %edx,%eax
}
f0104e61:	5b                   	pop    %ebx
f0104e62:	5e                   	pop    %esi
f0104e63:	5f                   	pop    %edi
f0104e64:	5d                   	pop    %ebp
f0104e65:	c3                   	ret    
	...

f0104e70 <__udivdi3>:
f0104e70:	83 ec 1c             	sub    $0x1c,%esp
f0104e73:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0104e77:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0104e7b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0104e7f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0104e83:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104e87:	8b 74 24 24          	mov    0x24(%esp),%esi
f0104e8b:	85 ff                	test   %edi,%edi
f0104e8d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0104e91:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104e95:	89 cd                	mov    %ecx,%ebp
f0104e97:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104e9b:	75 33                	jne    f0104ed0 <__udivdi3+0x60>
f0104e9d:	39 f1                	cmp    %esi,%ecx
f0104e9f:	77 57                	ja     f0104ef8 <__udivdi3+0x88>
f0104ea1:	85 c9                	test   %ecx,%ecx
f0104ea3:	75 0b                	jne    f0104eb0 <__udivdi3+0x40>
f0104ea5:	b8 01 00 00 00       	mov    $0x1,%eax
f0104eaa:	31 d2                	xor    %edx,%edx
f0104eac:	f7 f1                	div    %ecx
f0104eae:	89 c1                	mov    %eax,%ecx
f0104eb0:	89 f0                	mov    %esi,%eax
f0104eb2:	31 d2                	xor    %edx,%edx
f0104eb4:	f7 f1                	div    %ecx
f0104eb6:	89 c6                	mov    %eax,%esi
f0104eb8:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104ebc:	f7 f1                	div    %ecx
f0104ebe:	89 f2                	mov    %esi,%edx
f0104ec0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104ec4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104ec8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104ecc:	83 c4 1c             	add    $0x1c,%esp
f0104ecf:	c3                   	ret    
f0104ed0:	31 d2                	xor    %edx,%edx
f0104ed2:	31 c0                	xor    %eax,%eax
f0104ed4:	39 f7                	cmp    %esi,%edi
f0104ed6:	77 e8                	ja     f0104ec0 <__udivdi3+0x50>
f0104ed8:	0f bd cf             	bsr    %edi,%ecx
f0104edb:	83 f1 1f             	xor    $0x1f,%ecx
f0104ede:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104ee2:	75 2c                	jne    f0104f10 <__udivdi3+0xa0>
f0104ee4:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0104ee8:	76 04                	jbe    f0104eee <__udivdi3+0x7e>
f0104eea:	39 f7                	cmp    %esi,%edi
f0104eec:	73 d2                	jae    f0104ec0 <__udivdi3+0x50>
f0104eee:	31 d2                	xor    %edx,%edx
f0104ef0:	b8 01 00 00 00       	mov    $0x1,%eax
f0104ef5:	eb c9                	jmp    f0104ec0 <__udivdi3+0x50>
f0104ef7:	90                   	nop
f0104ef8:	89 f2                	mov    %esi,%edx
f0104efa:	f7 f1                	div    %ecx
f0104efc:	31 d2                	xor    %edx,%edx
f0104efe:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104f02:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104f06:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104f0a:	83 c4 1c             	add    $0x1c,%esp
f0104f0d:	c3                   	ret    
f0104f0e:	66 90                	xchg   %ax,%ax
f0104f10:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104f15:	b8 20 00 00 00       	mov    $0x20,%eax
f0104f1a:	89 ea                	mov    %ebp,%edx
f0104f1c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104f20:	d3 e7                	shl    %cl,%edi
f0104f22:	89 c1                	mov    %eax,%ecx
f0104f24:	d3 ea                	shr    %cl,%edx
f0104f26:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104f2b:	09 fa                	or     %edi,%edx
f0104f2d:	89 f7                	mov    %esi,%edi
f0104f2f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104f33:	89 f2                	mov    %esi,%edx
f0104f35:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104f39:	d3 e5                	shl    %cl,%ebp
f0104f3b:	89 c1                	mov    %eax,%ecx
f0104f3d:	d3 ef                	shr    %cl,%edi
f0104f3f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104f44:	d3 e2                	shl    %cl,%edx
f0104f46:	89 c1                	mov    %eax,%ecx
f0104f48:	d3 ee                	shr    %cl,%esi
f0104f4a:	09 d6                	or     %edx,%esi
f0104f4c:	89 fa                	mov    %edi,%edx
f0104f4e:	89 f0                	mov    %esi,%eax
f0104f50:	f7 74 24 0c          	divl   0xc(%esp)
f0104f54:	89 d7                	mov    %edx,%edi
f0104f56:	89 c6                	mov    %eax,%esi
f0104f58:	f7 e5                	mul    %ebp
f0104f5a:	39 d7                	cmp    %edx,%edi
f0104f5c:	72 22                	jb     f0104f80 <__udivdi3+0x110>
f0104f5e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0104f62:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104f67:	d3 e5                	shl    %cl,%ebp
f0104f69:	39 c5                	cmp    %eax,%ebp
f0104f6b:	73 04                	jae    f0104f71 <__udivdi3+0x101>
f0104f6d:	39 d7                	cmp    %edx,%edi
f0104f6f:	74 0f                	je     f0104f80 <__udivdi3+0x110>
f0104f71:	89 f0                	mov    %esi,%eax
f0104f73:	31 d2                	xor    %edx,%edx
f0104f75:	e9 46 ff ff ff       	jmp    f0104ec0 <__udivdi3+0x50>
f0104f7a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104f80:	8d 46 ff             	lea    -0x1(%esi),%eax
f0104f83:	31 d2                	xor    %edx,%edx
f0104f85:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104f89:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104f8d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104f91:	83 c4 1c             	add    $0x1c,%esp
f0104f94:	c3                   	ret    
	...

f0104fa0 <__umoddi3>:
f0104fa0:	83 ec 1c             	sub    $0x1c,%esp
f0104fa3:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0104fa7:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0104fab:	8b 44 24 20          	mov    0x20(%esp),%eax
f0104faf:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104fb3:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0104fb7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0104fbb:	85 ed                	test   %ebp,%ebp
f0104fbd:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0104fc1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104fc5:	89 cf                	mov    %ecx,%edi
f0104fc7:	89 04 24             	mov    %eax,(%esp)
f0104fca:	89 f2                	mov    %esi,%edx
f0104fcc:	75 1a                	jne    f0104fe8 <__umoddi3+0x48>
f0104fce:	39 f1                	cmp    %esi,%ecx
f0104fd0:	76 4e                	jbe    f0105020 <__umoddi3+0x80>
f0104fd2:	f7 f1                	div    %ecx
f0104fd4:	89 d0                	mov    %edx,%eax
f0104fd6:	31 d2                	xor    %edx,%edx
f0104fd8:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104fdc:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104fe0:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104fe4:	83 c4 1c             	add    $0x1c,%esp
f0104fe7:	c3                   	ret    
f0104fe8:	39 f5                	cmp    %esi,%ebp
f0104fea:	77 54                	ja     f0105040 <__umoddi3+0xa0>
f0104fec:	0f bd c5             	bsr    %ebp,%eax
f0104fef:	83 f0 1f             	xor    $0x1f,%eax
f0104ff2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104ff6:	75 60                	jne    f0105058 <__umoddi3+0xb8>
f0104ff8:	3b 0c 24             	cmp    (%esp),%ecx
f0104ffb:	0f 87 07 01 00 00    	ja     f0105108 <__umoddi3+0x168>
f0105001:	89 f2                	mov    %esi,%edx
f0105003:	8b 34 24             	mov    (%esp),%esi
f0105006:	29 ce                	sub    %ecx,%esi
f0105008:	19 ea                	sbb    %ebp,%edx
f010500a:	89 34 24             	mov    %esi,(%esp)
f010500d:	8b 04 24             	mov    (%esp),%eax
f0105010:	8b 74 24 10          	mov    0x10(%esp),%esi
f0105014:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0105018:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010501c:	83 c4 1c             	add    $0x1c,%esp
f010501f:	c3                   	ret    
f0105020:	85 c9                	test   %ecx,%ecx
f0105022:	75 0b                	jne    f010502f <__umoddi3+0x8f>
f0105024:	b8 01 00 00 00       	mov    $0x1,%eax
f0105029:	31 d2                	xor    %edx,%edx
f010502b:	f7 f1                	div    %ecx
f010502d:	89 c1                	mov    %eax,%ecx
f010502f:	89 f0                	mov    %esi,%eax
f0105031:	31 d2                	xor    %edx,%edx
f0105033:	f7 f1                	div    %ecx
f0105035:	8b 04 24             	mov    (%esp),%eax
f0105038:	f7 f1                	div    %ecx
f010503a:	eb 98                	jmp    f0104fd4 <__umoddi3+0x34>
f010503c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105040:	89 f2                	mov    %esi,%edx
f0105042:	8b 74 24 10          	mov    0x10(%esp),%esi
f0105046:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010504a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010504e:	83 c4 1c             	add    $0x1c,%esp
f0105051:	c3                   	ret    
f0105052:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105058:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010505d:	89 e8                	mov    %ebp,%eax
f010505f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0105064:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0105068:	89 fa                	mov    %edi,%edx
f010506a:	d3 e0                	shl    %cl,%eax
f010506c:	89 e9                	mov    %ebp,%ecx
f010506e:	d3 ea                	shr    %cl,%edx
f0105070:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0105075:	09 c2                	or     %eax,%edx
f0105077:	8b 44 24 08          	mov    0x8(%esp),%eax
f010507b:	89 14 24             	mov    %edx,(%esp)
f010507e:	89 f2                	mov    %esi,%edx
f0105080:	d3 e7                	shl    %cl,%edi
f0105082:	89 e9                	mov    %ebp,%ecx
f0105084:	d3 ea                	shr    %cl,%edx
f0105086:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010508b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010508f:	d3 e6                	shl    %cl,%esi
f0105091:	89 e9                	mov    %ebp,%ecx
f0105093:	d3 e8                	shr    %cl,%eax
f0105095:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010509a:	09 f0                	or     %esi,%eax
f010509c:	8b 74 24 08          	mov    0x8(%esp),%esi
f01050a0:	f7 34 24             	divl   (%esp)
f01050a3:	d3 e6                	shl    %cl,%esi
f01050a5:	89 74 24 08          	mov    %esi,0x8(%esp)
f01050a9:	89 d6                	mov    %edx,%esi
f01050ab:	f7 e7                	mul    %edi
f01050ad:	39 d6                	cmp    %edx,%esi
f01050af:	89 c1                	mov    %eax,%ecx
f01050b1:	89 d7                	mov    %edx,%edi
f01050b3:	72 3f                	jb     f01050f4 <__umoddi3+0x154>
f01050b5:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01050b9:	72 35                	jb     f01050f0 <__umoddi3+0x150>
f01050bb:	8b 44 24 08          	mov    0x8(%esp),%eax
f01050bf:	29 c8                	sub    %ecx,%eax
f01050c1:	19 fe                	sbb    %edi,%esi
f01050c3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01050c8:	89 f2                	mov    %esi,%edx
f01050ca:	d3 e8                	shr    %cl,%eax
f01050cc:	89 e9                	mov    %ebp,%ecx
f01050ce:	d3 e2                	shl    %cl,%edx
f01050d0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01050d5:	09 d0                	or     %edx,%eax
f01050d7:	89 f2                	mov    %esi,%edx
f01050d9:	d3 ea                	shr    %cl,%edx
f01050db:	8b 74 24 10          	mov    0x10(%esp),%esi
f01050df:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01050e3:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01050e7:	83 c4 1c             	add    $0x1c,%esp
f01050ea:	c3                   	ret    
f01050eb:	90                   	nop
f01050ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01050f0:	39 d6                	cmp    %edx,%esi
f01050f2:	75 c7                	jne    f01050bb <__umoddi3+0x11b>
f01050f4:	89 d7                	mov    %edx,%edi
f01050f6:	89 c1                	mov    %eax,%ecx
f01050f8:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f01050fc:	1b 3c 24             	sbb    (%esp),%edi
f01050ff:	eb ba                	jmp    f01050bb <__umoddi3+0x11b>
f0105101:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105108:	39 f5                	cmp    %esi,%ebp
f010510a:	0f 82 f1 fe ff ff    	jb     f0105001 <__umoddi3+0x61>
f0105110:	e9 f8 fe ff ff       	jmp    f010500d <__umoddi3+0x6d>
