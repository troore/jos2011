
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
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in i386_vm_init in lab 2.

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
f0100039:	e8 03 01 00 00       	call   f0100141 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
		monitor(NULL);
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
f0100047:	8d 5d 14             	lea    0x14(%ebp),%ebx
{
	va_list ap;

	va_start(ap, fmt);
	cprintf("kernel warning at %s:%d: ", file, line);
f010004a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010004d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100051:	8b 45 08             	mov    0x8(%ebp),%eax
f0100054:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100058:	c7 04 24 20 1b 10 f0 	movl   $0xf0101b20,(%esp)
f010005f:	e8 cf 09 00 00       	call   f0100a33 <cprintf>
	vcprintf(fmt, ap);
f0100064:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100068:	8b 45 10             	mov    0x10(%ebp),%eax
f010006b:	89 04 24             	mov    %eax,(%esp)
f010006e:	e8 8d 09 00 00       	call   f0100a00 <vcprintf>
	cprintf("\n");
f0100073:	c7 04 24 cb 1b 10 f0 	movl   $0xf0101bcb,(%esp)
f010007a:	e8 b4 09 00 00       	call   f0100a33 <cprintf>
	va_end(ap);
}
f010007f:	83 c4 14             	add    $0x14,%esp
f0100082:	5b                   	pop    %ebx
f0100083:	5d                   	pop    %ebp
f0100084:	c3                   	ret    

f0100085 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100085:	55                   	push   %ebp
f0100086:	89 e5                	mov    %esp,%ebp
f0100088:	56                   	push   %esi
f0100089:	53                   	push   %ebx
f010008a:	83 ec 10             	sub    $0x10,%esp
f010008d:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100090:	83 3d 00 23 11 f0 00 	cmpl   $0x0,0xf0112300
f0100097:	75 3d                	jne    f01000d6 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f0100099:	89 35 00 23 11 f0    	mov    %esi,0xf0112300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f010009f:	fa                   	cli    
f01000a0:	fc                   	cld    
/*
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
f01000a1:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");

	va_start(ap, fmt);
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000a7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01000ae:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000b2:	c7 04 24 3a 1b 10 f0 	movl   $0xf0101b3a,(%esp)
f01000b9:	e8 75 09 00 00       	call   f0100a33 <cprintf>
	vcprintf(fmt, ap);
f01000be:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000c2:	89 34 24             	mov    %esi,(%esp)
f01000c5:	e8 36 09 00 00       	call   f0100a00 <vcprintf>
	cprintf("\n");
f01000ca:	c7 04 24 cb 1b 10 f0 	movl   $0xf0101bcb,(%esp)
f01000d1:	e8 5d 09 00 00       	call   f0100a33 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000dd:	e8 de 06 00 00       	call   f01007c0 <monitor>
f01000e2:	eb f2                	jmp    f01000d6 <_panic+0x51>

f01000e4 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f01000e4:	55                   	push   %ebp
f01000e5:	89 e5                	mov    %esp,%ebp
f01000e7:	53                   	push   %ebx
f01000e8:	83 ec 14             	sub    $0x14,%esp
f01000eb:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f01000ee:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000f2:	c7 04 24 52 1b 10 f0 	movl   $0xf0101b52,(%esp)
f01000f9:	e8 35 09 00 00       	call   f0100a33 <cprintf>
	if (x > 0)
f01000fe:	85 db                	test   %ebx,%ebx
f0100100:	7e 0d                	jle    f010010f <test_backtrace+0x2b>
		test_backtrace(x-1);
f0100102:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100105:	89 04 24             	mov    %eax,(%esp)
f0100108:	e8 d7 ff ff ff       	call   f01000e4 <test_backtrace>
f010010d:	eb 1c                	jmp    f010012b <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010010f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100116:	00 
f0100117:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010011e:	00 
f010011f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100126:	e8 cd 07 00 00       	call   f01008f8 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f010012b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010012f:	c7 04 24 6e 1b 10 f0 	movl   $0xf0101b6e,(%esp)
f0100136:	e8 f8 08 00 00       	call   f0100a33 <cprintf>
}
f010013b:	83 c4 14             	add    $0x14,%esp
f010013e:	5b                   	pop    %ebx
f010013f:	5d                   	pop    %ebp
f0100140:	c3                   	ret    

f0100141 <i386_init>:

void
i386_init(void)
{
f0100141:	55                   	push   %ebp
f0100142:	89 e5                	mov    %esp,%ebp
f0100144:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100147:	b8 60 29 11 f0       	mov    $0xf0112960,%eax
f010014c:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f0100151:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100155:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010015c:	00 
f010015d:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f0100164:	e8 dd 14 00 00       	call   f0101646 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100169:	e8 3c 03 00 00       	call   f01004aa <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010016e:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100175:	00 
f0100176:	c7 04 24 89 1b 10 f0 	movl   $0xf0101b89,(%esp)
f010017d:	e8 b1 08 00 00       	call   f0100a33 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f0100182:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f0100189:	e8 56 ff ff ff       	call   f01000e4 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010018e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100195:	e8 26 06 00 00       	call   f01007c0 <monitor>
f010019a:	eb f2                	jmp    f010018e <i386_init+0x4d>
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

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
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
f01001b7:	89 c2                	mov    %eax,%edx
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01001be:	f6 c2 01             	test   $0x1,%dl
f01001c1:	74 09                	je     f01001cc <serial_proc_data+0x1e>
f01001c3:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001c8:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001c9:	0f b6 c0             	movzbl %al,%eax
}
f01001cc:	5d                   	pop    %ebp
f01001cd:	c3                   	ret    

f01001ce <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ce:	55                   	push   %ebp
f01001cf:	89 e5                	mov    %esp,%ebp
f01001d1:	57                   	push   %edi
f01001d2:	56                   	push   %esi
f01001d3:	53                   	push   %ebx
f01001d4:	83 ec 0c             	sub    $0xc,%esp
f01001d7:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
		cons.buf[cons.wpos++] = c;
f01001d9:	bb 44 25 11 f0       	mov    $0xf0112544,%ebx
f01001de:	bf 40 23 11 f0       	mov    $0xf0112340,%edi
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001e3:	eb 1e                	jmp    f0100203 <cons_intr+0x35>
		if (c == 0)
f01001e5:	85 c0                	test   %eax,%eax
f01001e7:	74 1a                	je     f0100203 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001e9:	8b 13                	mov    (%ebx),%edx
f01001eb:	88 04 17             	mov    %al,(%edi,%edx,1)
f01001ee:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01001f1:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01001f6:	0f 94 c2             	sete   %dl
f01001f9:	0f b6 d2             	movzbl %dl,%edx
f01001fc:	83 ea 01             	sub    $0x1,%edx
f01001ff:	21 d0                	and    %edx,%eax
f0100201:	89 03                	mov    %eax,(%ebx)
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100203:	ff d6                	call   *%esi
f0100205:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100208:	75 db                	jne    f01001e5 <cons_intr+0x17>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010020a:	83 c4 0c             	add    $0xc,%esp
f010020d:	5b                   	pop    %ebx
f010020e:	5e                   	pop    %esi
f010020f:	5f                   	pop    %edi
f0100210:	5d                   	pop    %ebp
f0100211:	c3                   	ret    

f0100212 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100212:	55                   	push   %ebp
f0100213:	89 e5                	mov    %esp,%ebp
f0100215:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100218:	b8 9a 05 10 f0       	mov    $0xf010059a,%eax
f010021d:	e8 ac ff ff ff       	call   f01001ce <cons_intr>
}
f0100222:	c9                   	leave  
f0100223:	c3                   	ret    

f0100224 <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100224:	55                   	push   %ebp
f0100225:	89 e5                	mov    %esp,%ebp
f0100227:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f010022a:	83 3d 24 23 11 f0 00 	cmpl   $0x0,0xf0112324
f0100231:	74 0a                	je     f010023d <serial_intr+0x19>
		cons_intr(serial_proc_data);
f0100233:	b8 ae 01 10 f0       	mov    $0xf01001ae,%eax
f0100238:	e8 91 ff ff ff       	call   f01001ce <cons_intr>
}
f010023d:	c9                   	leave  
f010023e:	c3                   	ret    

f010023f <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f010023f:	55                   	push   %ebp
f0100240:	89 e5                	mov    %esp,%ebp
f0100242:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100245:	e8 da ff ff ff       	call   f0100224 <serial_intr>
	kbd_intr();
f010024a:	e8 c3 ff ff ff       	call   f0100212 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010024f:	8b 15 40 25 11 f0    	mov    0xf0112540,%edx
f0100255:	b8 00 00 00 00       	mov    $0x0,%eax
f010025a:	3b 15 44 25 11 f0    	cmp    0xf0112544,%edx
f0100260:	74 21                	je     f0100283 <cons_getc+0x44>
		c = cons.buf[cons.rpos++];
f0100262:	0f b6 82 40 23 11 f0 	movzbl -0xfeedcc0(%edx),%eax
f0100269:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f010026c:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.rpos = 0;
f0100272:	0f 94 c1             	sete   %cl
f0100275:	0f b6 c9             	movzbl %cl,%ecx
f0100278:	83 e9 01             	sub    $0x1,%ecx
f010027b:	21 ca                	and    %ecx,%edx
f010027d:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
		return c;
	}
	return 0;
}
f0100283:	c9                   	leave  
f0100284:	c3                   	ret    

f0100285 <getchar>:
	cons_putc(c);
}

int
getchar(void)
{
f0100285:	55                   	push   %ebp
f0100286:	89 e5                	mov    %esp,%ebp
f0100288:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010028b:	e8 af ff ff ff       	call   f010023f <cons_getc>
f0100290:	85 c0                	test   %eax,%eax
f0100292:	74 f7                	je     f010028b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100294:	c9                   	leave  
f0100295:	c3                   	ret    

f0100296 <iscons>:

int
iscons(int fdnum)
{
f0100296:	55                   	push   %ebp
f0100297:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100299:	b8 01 00 00 00       	mov    $0x1,%eax
f010029e:	5d                   	pop    %ebp
f010029f:	c3                   	ret    

f01002a0 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002a0:	55                   	push   %ebp
f01002a1:	89 e5                	mov    %esp,%ebp
f01002a3:	57                   	push   %edi
f01002a4:	56                   	push   %esi
f01002a5:	53                   	push   %ebx
f01002a6:	83 ec 2c             	sub    $0x2c,%esp
f01002a9:	89 c7                	mov    %eax,%edi
f01002ab:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01002b0:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01002b1:	a8 20                	test   $0x20,%al
f01002b3:	75 21                	jne    f01002d6 <cons_putc+0x36>
f01002b5:	bb 00 00 00 00       	mov    $0x0,%ebx
f01002ba:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01002bf:	e8 dc fe ff ff       	call   f01001a0 <delay>
f01002c4:	89 f2                	mov    %esi,%edx
f01002c6:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01002c7:	a8 20                	test   $0x20,%al
f01002c9:	75 0b                	jne    f01002d6 <cons_putc+0x36>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002cb:	83 c3 01             	add    $0x1,%ebx
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01002ce:	81 fb 00 32 00 00    	cmp    $0x3200,%ebx
f01002d4:	75 e9                	jne    f01002bf <cons_putc+0x1f>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f01002d6:	89 fa                	mov    %edi,%edx
f01002d8:	89 f8                	mov    %edi,%eax
f01002da:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002dd:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002e2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e3:	b2 79                	mov    $0x79,%dl
f01002e5:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002e6:	84 c0                	test   %al,%al
f01002e8:	78 21                	js     f010030b <cons_putc+0x6b>
f01002ea:	bb 00 00 00 00       	mov    $0x0,%ebx
f01002ef:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f01002f4:	e8 a7 fe ff ff       	call   f01001a0 <delay>
f01002f9:	89 f2                	mov    %esi,%edx
f01002fb:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002fc:	84 c0                	test   %al,%al
f01002fe:	78 0b                	js     f010030b <cons_putc+0x6b>
f0100300:	83 c3 01             	add    $0x1,%ebx
f0100303:	81 fb 00 32 00 00    	cmp    $0x3200,%ebx
f0100309:	75 e9                	jne    f01002f4 <cons_putc+0x54>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010030b:	ba 78 03 00 00       	mov    $0x378,%edx
f0100310:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100314:	ee                   	out    %al,(%dx)
f0100315:	b2 7a                	mov    $0x7a,%dl
f0100317:	b8 0d 00 00 00       	mov    $0xd,%eax
f010031c:	ee                   	out    %al,(%dx)
f010031d:	b8 08 00 00 00       	mov    $0x8,%eax
f0100322:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100323:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f0100329:	75 06                	jne    f0100331 <cons_putc+0x91>
		c |= 0x0700;
f010032b:	81 cf 00 07 00 00    	or     $0x700,%edi

	switch (c & 0xff) {
f0100331:	89 f8                	mov    %edi,%eax
f0100333:	25 ff 00 00 00       	and    $0xff,%eax
f0100338:	83 f8 09             	cmp    $0x9,%eax
f010033b:	0f 84 83 00 00 00    	je     f01003c4 <cons_putc+0x124>
f0100341:	83 f8 09             	cmp    $0x9,%eax
f0100344:	7f 0c                	jg     f0100352 <cons_putc+0xb2>
f0100346:	83 f8 08             	cmp    $0x8,%eax
f0100349:	0f 85 a9 00 00 00    	jne    f01003f8 <cons_putc+0x158>
f010034f:	90                   	nop
f0100350:	eb 18                	jmp    f010036a <cons_putc+0xca>
f0100352:	83 f8 0a             	cmp    $0xa,%eax
f0100355:	8d 76 00             	lea    0x0(%esi),%esi
f0100358:	74 40                	je     f010039a <cons_putc+0xfa>
f010035a:	83 f8 0d             	cmp    $0xd,%eax
f010035d:	8d 76 00             	lea    0x0(%esi),%esi
f0100360:	0f 85 92 00 00 00    	jne    f01003f8 <cons_putc+0x158>
f0100366:	66 90                	xchg   %ax,%ax
f0100368:	eb 38                	jmp    f01003a2 <cons_putc+0x102>
	case '\b':
		if (crt_pos > 0) {
f010036a:	0f b7 05 30 23 11 f0 	movzwl 0xf0112330,%eax
f0100371:	66 85 c0             	test   %ax,%ax
f0100374:	0f 84 e8 00 00 00    	je     f0100462 <cons_putc+0x1c2>
			crt_pos--;
f010037a:	83 e8 01             	sub    $0x1,%eax
f010037d:	66 a3 30 23 11 f0    	mov    %ax,0xf0112330
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100383:	0f b7 c0             	movzwl %ax,%eax
f0100386:	66 81 e7 00 ff       	and    $0xff00,%di
f010038b:	83 cf 20             	or     $0x20,%edi
f010038e:	8b 15 2c 23 11 f0    	mov    0xf011232c,%edx
f0100394:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100398:	eb 7b                	jmp    f0100415 <cons_putc+0x175>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010039a:	66 83 05 30 23 11 f0 	addw   $0x50,0xf0112330
f01003a1:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003a2:	0f b7 05 30 23 11 f0 	movzwl 0xf0112330,%eax
f01003a9:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003af:	c1 e8 10             	shr    $0x10,%eax
f01003b2:	66 c1 e8 06          	shr    $0x6,%ax
f01003b6:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b9:	c1 e0 04             	shl    $0x4,%eax
f01003bc:	66 a3 30 23 11 f0    	mov    %ax,0xf0112330
f01003c2:	eb 51                	jmp    f0100415 <cons_putc+0x175>
		break;
	case '\t':
		cons_putc(' ');
f01003c4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c9:	e8 d2 fe ff ff       	call   f01002a0 <cons_putc>
		cons_putc(' ');
f01003ce:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d3:	e8 c8 fe ff ff       	call   f01002a0 <cons_putc>
		cons_putc(' ');
f01003d8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003dd:	e8 be fe ff ff       	call   f01002a0 <cons_putc>
		cons_putc(' ');
f01003e2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e7:	e8 b4 fe ff ff       	call   f01002a0 <cons_putc>
		cons_putc(' ');
f01003ec:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f1:	e8 aa fe ff ff       	call   f01002a0 <cons_putc>
f01003f6:	eb 1d                	jmp    f0100415 <cons_putc+0x175>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003f8:	0f b7 05 30 23 11 f0 	movzwl 0xf0112330,%eax
f01003ff:	0f b7 c8             	movzwl %ax,%ecx
f0100402:	8b 15 2c 23 11 f0    	mov    0xf011232c,%edx
f0100408:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f010040c:	83 c0 01             	add    $0x1,%eax
f010040f:	66 a3 30 23 11 f0    	mov    %ax,0xf0112330
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100415:	66 81 3d 30 23 11 f0 	cmpw   $0x7cf,0xf0112330
f010041c:	cf 07 
f010041e:	76 42                	jbe    f0100462 <cons_putc+0x1c2>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100420:	a1 2c 23 11 f0       	mov    0xf011232c,%eax
f0100425:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010042c:	00 
f010042d:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100433:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100437:	89 04 24             	mov    %eax,(%esp)
f010043a:	e8 66 12 00 00       	call   f01016a5 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010043f:	8b 15 2c 23 11 f0    	mov    0xf011232c,%edx
f0100445:	b8 80 07 00 00       	mov    $0x780,%eax
f010044a:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100450:	83 c0 01             	add    $0x1,%eax
f0100453:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100458:	75 f0                	jne    f010044a <cons_putc+0x1aa>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010045a:	66 83 2d 30 23 11 f0 	subw   $0x50,0xf0112330
f0100461:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100462:	8b 0d 28 23 11 f0    	mov    0xf0112328,%ecx
f0100468:	89 cb                	mov    %ecx,%ebx
f010046a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046f:	89 ca                	mov    %ecx,%edx
f0100471:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100472:	0f b7 35 30 23 11 f0 	movzwl 0xf0112330,%esi
f0100479:	83 c1 01             	add    $0x1,%ecx
f010047c:	89 f0                	mov    %esi,%eax
f010047e:	66 c1 e8 08          	shr    $0x8,%ax
f0100482:	89 ca                	mov    %ecx,%edx
f0100484:	ee                   	out    %al,(%dx)
f0100485:	b8 0f 00 00 00       	mov    $0xf,%eax
f010048a:	89 da                	mov    %ebx,%edx
f010048c:	ee                   	out    %al,(%dx)
f010048d:	89 f0                	mov    %esi,%eax
f010048f:	89 ca                	mov    %ecx,%edx
f0100491:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100492:	83 c4 2c             	add    $0x2c,%esp
f0100495:	5b                   	pop    %ebx
f0100496:	5e                   	pop    %esi
f0100497:	5f                   	pop    %edi
f0100498:	5d                   	pop    %ebp
f0100499:	c3                   	ret    

f010049a <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010049a:	55                   	push   %ebp
f010049b:	89 e5                	mov    %esp,%ebp
f010049d:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01004a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01004a3:	e8 f8 fd ff ff       	call   f01002a0 <cons_putc>
}
f01004a8:	c9                   	leave  
f01004a9:	c3                   	ret    

f01004aa <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004aa:	55                   	push   %ebp
f01004ab:	89 e5                	mov    %esp,%ebp
f01004ad:	57                   	push   %edi
f01004ae:	56                   	push   %esi
f01004af:	53                   	push   %ebx
f01004b0:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004b3:	b8 00 80 0b f0       	mov    $0xf00b8000,%eax
f01004b8:	0f b7 10             	movzwl (%eax),%edx
	*cp = (uint16_t) 0xA55A;
f01004bb:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
f01004c0:	0f b7 00             	movzwl (%eax),%eax
f01004c3:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01004c7:	74 11                	je     f01004da <cons_init+0x30>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01004c9:	c7 05 28 23 11 f0 b4 	movl   $0x3b4,0xf0112328
f01004d0:	03 00 00 
f01004d3:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f01004d8:	eb 16                	jmp    f01004f0 <cons_init+0x46>
	} else {
		*cp = was;
f01004da:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01004e1:	c7 05 28 23 11 f0 d4 	movl   $0x3d4,0xf0112328
f01004e8:	03 00 00 
f01004eb:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01004f0:	8b 0d 28 23 11 f0    	mov    0xf0112328,%ecx
f01004f6:	89 cb                	mov    %ecx,%ebx
f01004f8:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004fd:	89 ca                	mov    %ecx,%edx
f01004ff:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100500:	83 c1 01             	add    $0x1,%ecx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100503:	89 ca                	mov    %ecx,%edx
f0100505:	ec                   	in     (%dx),%al
f0100506:	0f b6 f8             	movzbl %al,%edi
f0100509:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010050c:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100511:	89 da                	mov    %ebx,%edx
f0100513:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100514:	89 ca                	mov    %ecx,%edx
f0100516:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100517:	89 35 2c 23 11 f0    	mov    %esi,0xf011232c
	crt_pos = pos;
f010051d:	0f b6 c8             	movzbl %al,%ecx
f0100520:	09 cf                	or     %ecx,%edi
f0100522:	66 89 3d 30 23 11 f0 	mov    %di,0xf0112330
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100529:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f010052e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100533:	89 da                	mov    %ebx,%edx
f0100535:	ee                   	out    %al,(%dx)
f0100536:	b2 fb                	mov    $0xfb,%dl
f0100538:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010053d:	ee                   	out    %al,(%dx)
f010053e:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f0100543:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100548:	89 ca                	mov    %ecx,%edx
f010054a:	ee                   	out    %al,(%dx)
f010054b:	b2 f9                	mov    $0xf9,%dl
f010054d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100552:	ee                   	out    %al,(%dx)
f0100553:	b2 fb                	mov    $0xfb,%dl
f0100555:	b8 03 00 00 00       	mov    $0x3,%eax
f010055a:	ee                   	out    %al,(%dx)
f010055b:	b2 fc                	mov    $0xfc,%dl
f010055d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100562:	ee                   	out    %al,(%dx)
f0100563:	b2 f9                	mov    $0xf9,%dl
f0100565:	b8 01 00 00 00       	mov    $0x1,%eax
f010056a:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056b:	b2 fd                	mov    $0xfd,%dl
f010056d:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010056e:	3c ff                	cmp    $0xff,%al
f0100570:	0f 95 c0             	setne  %al
f0100573:	0f b6 f0             	movzbl %al,%esi
f0100576:	89 35 24 23 11 f0    	mov    %esi,0xf0112324
f010057c:	89 da                	mov    %ebx,%edx
f010057e:	ec                   	in     (%dx),%al
f010057f:	89 ca                	mov    %ecx,%edx
f0100581:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100582:	85 f6                	test   %esi,%esi
f0100584:	75 0c                	jne    f0100592 <cons_init+0xe8>
		cprintf("Serial port does not exist!\n");
f0100586:	c7 04 24 a4 1b 10 f0 	movl   $0xf0101ba4,(%esp)
f010058d:	e8 a1 04 00 00       	call   f0100a33 <cprintf>
}
f0100592:	83 c4 1c             	add    $0x1c,%esp
f0100595:	5b                   	pop    %ebx
f0100596:	5e                   	pop    %esi
f0100597:	5f                   	pop    %edi
f0100598:	5d                   	pop    %ebp
f0100599:	c3                   	ret    

f010059a <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010059a:	55                   	push   %ebp
f010059b:	89 e5                	mov    %esp,%ebp
f010059d:	53                   	push   %ebx
f010059e:	83 ec 14             	sub    $0x14,%esp
f01005a1:	ba 64 00 00 00       	mov    $0x64,%edx
f01005a6:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01005a7:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01005ac:	a8 01                	test   $0x1,%al
f01005ae:	0f 84 d9 00 00 00    	je     f010068d <kbd_proc_data+0xf3>
f01005b4:	b2 60                	mov    $0x60,%dl
f01005b6:	ec                   	in     (%dx),%al
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01005b7:	3c e0                	cmp    $0xe0,%al
f01005b9:	75 11                	jne    f01005cc <kbd_proc_data+0x32>
		// E0 escape character
		shift |= E0ESC;
f01005bb:	83 0d 20 23 11 f0 40 	orl    $0x40,0xf0112320
f01005c2:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
f01005c7:	e9 c1 00 00 00       	jmp    f010068d <kbd_proc_data+0xf3>
	} else if (data & 0x80) {
f01005cc:	84 c0                	test   %al,%al
f01005ce:	79 32                	jns    f0100602 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01005d0:	8b 15 20 23 11 f0    	mov    0xf0112320,%edx
f01005d6:	f6 c2 40             	test   $0x40,%dl
f01005d9:	75 03                	jne    f01005de <kbd_proc_data+0x44>
f01005db:	83 e0 7f             	and    $0x7f,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f01005de:	0f b6 c0             	movzbl %al,%eax
f01005e1:	0f b6 80 e0 1b 10 f0 	movzbl -0xfefe420(%eax),%eax
f01005e8:	83 c8 40             	or     $0x40,%eax
f01005eb:	0f b6 c0             	movzbl %al,%eax
f01005ee:	f7 d0                	not    %eax
f01005f0:	21 c2                	and    %eax,%edx
f01005f2:	89 15 20 23 11 f0    	mov    %edx,0xf0112320
f01005f8:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
f01005fd:	e9 8b 00 00 00       	jmp    f010068d <kbd_proc_data+0xf3>
	} else if (shift & E0ESC) {
f0100602:	8b 15 20 23 11 f0    	mov    0xf0112320,%edx
f0100608:	f6 c2 40             	test   $0x40,%dl
f010060b:	74 0c                	je     f0100619 <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010060d:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f0100610:	83 e2 bf             	and    $0xffffffbf,%edx
f0100613:	89 15 20 23 11 f0    	mov    %edx,0xf0112320
	}

	shift |= shiftcode[data];
f0100619:	0f b6 c0             	movzbl %al,%eax
	shift ^= togglecode[data];
f010061c:	0f b6 90 e0 1b 10 f0 	movzbl -0xfefe420(%eax),%edx
f0100623:	0b 15 20 23 11 f0    	or     0xf0112320,%edx
f0100629:	0f b6 88 e0 1c 10 f0 	movzbl -0xfefe320(%eax),%ecx
f0100630:	31 ca                	xor    %ecx,%edx
f0100632:	89 15 20 23 11 f0    	mov    %edx,0xf0112320

	c = charcode[shift & (CTL | SHIFT)][data];
f0100638:	89 d1                	mov    %edx,%ecx
f010063a:	83 e1 03             	and    $0x3,%ecx
f010063d:	8b 0c 8d e0 1d 10 f0 	mov    -0xfefe220(,%ecx,4),%ecx
f0100644:	0f b6 1c 01          	movzbl (%ecx,%eax,1),%ebx
	if (shift & CAPSLOCK) {
f0100648:	f6 c2 08             	test   $0x8,%dl
f010064b:	74 1a                	je     f0100667 <kbd_proc_data+0xcd>
		if ('a' <= c && c <= 'z')
f010064d:	89 d9                	mov    %ebx,%ecx
f010064f:	8d 43 9f             	lea    -0x61(%ebx),%eax
f0100652:	83 f8 19             	cmp    $0x19,%eax
f0100655:	77 05                	ja     f010065c <kbd_proc_data+0xc2>
			c += 'A' - 'a';
f0100657:	83 eb 20             	sub    $0x20,%ebx
f010065a:	eb 0b                	jmp    f0100667 <kbd_proc_data+0xcd>
		else if ('A' <= c && c <= 'Z')
f010065c:	83 e9 41             	sub    $0x41,%ecx
f010065f:	83 f9 19             	cmp    $0x19,%ecx
f0100662:	77 03                	ja     f0100667 <kbd_proc_data+0xcd>
			c += 'a' - 'A';
f0100664:	83 c3 20             	add    $0x20,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100667:	f7 d2                	not    %edx
f0100669:	f6 c2 06             	test   $0x6,%dl
f010066c:	75 1f                	jne    f010068d <kbd_proc_data+0xf3>
f010066e:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100674:	75 17                	jne    f010068d <kbd_proc_data+0xf3>
		cprintf("Rebooting!\n");
f0100676:	c7 04 24 c1 1b 10 f0 	movl   $0xf0101bc1,(%esp)
f010067d:	e8 b1 03 00 00       	call   f0100a33 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100682:	ba 92 00 00 00       	mov    $0x92,%edx
f0100687:	b8 03 00 00 00       	mov    $0x3,%eax
f010068c:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010068d:	89 d8                	mov    %ebx,%eax
f010068f:	83 c4 14             	add    $0x14,%esp
f0100692:	5b                   	pop    %ebx
f0100693:	5d                   	pop    %ebp
f0100694:	c3                   	ret    
	...

f01006a0 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f01006a0:	55                   	push   %ebp
f01006a1:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01006a3:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01006a6:	5d                   	pop    %ebp
f01006a7:	c3                   	ret    

f01006a8 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006a8:	55                   	push   %ebp
f01006a9:	89 e5                	mov    %esp,%ebp
f01006ab:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006ae:	c7 04 24 f0 1d 10 f0 	movl   $0xf0101df0,(%esp)
f01006b5:	e8 79 03 00 00       	call   f0100a33 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006ba:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006c1:	00 
f01006c2:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006c9:	f0 
f01006ca:	c7 04 24 d8 1e 10 f0 	movl   $0xf0101ed8,(%esp)
f01006d1:	e8 5d 03 00 00       	call   f0100a33 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d6:	c7 44 24 08 15 1b 10 	movl   $0x101b15,0x8(%esp)
f01006dd:	00 
f01006de:	c7 44 24 04 15 1b 10 	movl   $0xf0101b15,0x4(%esp)
f01006e5:	f0 
f01006e6:	c7 04 24 fc 1e 10 f0 	movl   $0xf0101efc,(%esp)
f01006ed:	e8 41 03 00 00       	call   f0100a33 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006f2:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f01006f9:	00 
f01006fa:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f0100701:	f0 
f0100702:	c7 04 24 20 1f 10 f0 	movl   $0xf0101f20,(%esp)
f0100709:	e8 25 03 00 00       	call   f0100a33 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010070e:	c7 44 24 08 60 29 11 	movl   $0x112960,0x8(%esp)
f0100715:	00 
f0100716:	c7 44 24 04 60 29 11 	movl   $0xf0112960,0x4(%esp)
f010071d:	f0 
f010071e:	c7 04 24 44 1f 10 f0 	movl   $0xf0101f44,(%esp)
f0100725:	e8 09 03 00 00       	call   f0100a33 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010072a:	b8 5f 2d 11 f0       	mov    $0xf0112d5f,%eax
f010072f:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100734:	89 c2                	mov    %eax,%edx
f0100736:	c1 fa 1f             	sar    $0x1f,%edx
f0100739:	c1 ea 16             	shr    $0x16,%edx
f010073c:	8d 04 02             	lea    (%edx,%eax,1),%eax
f010073f:	c1 f8 0a             	sar    $0xa,%eax
f0100742:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100746:	c7 04 24 68 1f 10 f0 	movl   $0xf0101f68,(%esp)
f010074d:	e8 e1 02 00 00       	call   f0100a33 <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f0100752:	b8 00 00 00 00       	mov    $0x0,%eax
f0100757:	c9                   	leave  
f0100758:	c3                   	ret    

f0100759 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100759:	55                   	push   %ebp
f010075a:	89 e5                	mov    %esp,%ebp
f010075c:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010075f:	a1 64 20 10 f0       	mov    0xf0102064,%eax
f0100764:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100768:	a1 60 20 10 f0       	mov    0xf0102060,%eax
f010076d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100771:	c7 04 24 09 1e 10 f0 	movl   $0xf0101e09,(%esp)
f0100778:	e8 b6 02 00 00       	call   f0100a33 <cprintf>
f010077d:	a1 70 20 10 f0       	mov    0xf0102070,%eax
f0100782:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100786:	a1 6c 20 10 f0       	mov    0xf010206c,%eax
f010078b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010078f:	c7 04 24 09 1e 10 f0 	movl   $0xf0101e09,(%esp)
f0100796:	e8 98 02 00 00       	call   f0100a33 <cprintf>
f010079b:	a1 7c 20 10 f0       	mov    0xf010207c,%eax
f01007a0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007a4:	a1 78 20 10 f0       	mov    0xf0102078,%eax
f01007a9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007ad:	c7 04 24 09 1e 10 f0 	movl   $0xf0101e09,(%esp)
f01007b4:	e8 7a 02 00 00       	call   f0100a33 <cprintf>
	return 0;
}
f01007b9:	b8 00 00 00 00       	mov    $0x0,%eax
f01007be:	c9                   	leave  
f01007bf:	c3                   	ret    

f01007c0 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007c0:	55                   	push   %ebp
f01007c1:	89 e5                	mov    %esp,%ebp
f01007c3:	57                   	push   %edi
f01007c4:	56                   	push   %esi
f01007c5:	53                   	push   %ebx
f01007c6:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007c9:	c7 04 24 94 1f 10 f0 	movl   $0xf0101f94,(%esp)
f01007d0:	e8 5e 02 00 00       	call   f0100a33 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007d5:	c7 04 24 b8 1f 10 f0 	movl   $0xf0101fb8,(%esp)
f01007dc:	e8 52 02 00 00       	call   f0100a33 <cprintf>

	while (1) {
		buf = readline("K> ");
f01007e1:	c7 04 24 12 1e 10 f0 	movl   $0xf0101e12,(%esp)
f01007e8:	e8 d3 0b 00 00       	call   f01013c0 <readline>
f01007ed:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007ef:	85 c0                	test   %eax,%eax
f01007f1:	74 ee                	je     f01007e1 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007f3:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
f01007fa:	be 00 00 00 00       	mov    $0x0,%esi
f01007ff:	eb 06                	jmp    f0100807 <monitor+0x47>
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100801:	c6 03 00             	movb   $0x0,(%ebx)
f0100804:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100807:	0f b6 03             	movzbl (%ebx),%eax
f010080a:	84 c0                	test   %al,%al
f010080c:	74 6d                	je     f010087b <monitor+0xbb>
f010080e:	0f be c0             	movsbl %al,%eax
f0100811:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100815:	c7 04 24 16 1e 10 f0 	movl   $0xf0101e16,(%esp)
f010081c:	e8 cd 0d 00 00       	call   f01015ee <strchr>
f0100821:	85 c0                	test   %eax,%eax
f0100823:	75 dc                	jne    f0100801 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100825:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100828:	74 51                	je     f010087b <monitor+0xbb>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010082a:	83 fe 0f             	cmp    $0xf,%esi
f010082d:	8d 76 00             	lea    0x0(%esi),%esi
f0100830:	75 16                	jne    f0100848 <monitor+0x88>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100832:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100839:	00 
f010083a:	c7 04 24 1b 1e 10 f0 	movl   $0xf0101e1b,(%esp)
f0100841:	e8 ed 01 00 00       	call   f0100a33 <cprintf>
f0100846:	eb 99                	jmp    f01007e1 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100848:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010084c:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f010084f:	0f b6 03             	movzbl (%ebx),%eax
f0100852:	84 c0                	test   %al,%al
f0100854:	75 0c                	jne    f0100862 <monitor+0xa2>
f0100856:	eb af                	jmp    f0100807 <monitor+0x47>
			buf++;
f0100858:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010085b:	0f b6 03             	movzbl (%ebx),%eax
f010085e:	84 c0                	test   %al,%al
f0100860:	74 a5                	je     f0100807 <monitor+0x47>
f0100862:	0f be c0             	movsbl %al,%eax
f0100865:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100869:	c7 04 24 16 1e 10 f0 	movl   $0xf0101e16,(%esp)
f0100870:	e8 79 0d 00 00       	call   f01015ee <strchr>
f0100875:	85 c0                	test   %eax,%eax
f0100877:	74 df                	je     f0100858 <monitor+0x98>
f0100879:	eb 8c                	jmp    f0100807 <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f010087b:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100882:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100883:	85 f6                	test   %esi,%esi
f0100885:	0f 84 56 ff ff ff    	je     f01007e1 <monitor+0x21>
f010088b:	bb 60 20 10 f0       	mov    $0xf0102060,%ebx
f0100890:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100895:	8b 03                	mov    (%ebx),%eax
f0100897:	89 44 24 04          	mov    %eax,0x4(%esp)
f010089b:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010089e:	89 04 24             	mov    %eax,(%esp)
f01008a1:	e8 d3 0c 00 00       	call   f0101579 <strcmp>
f01008a6:	85 c0                	test   %eax,%eax
f01008a8:	75 23                	jne    f01008cd <monitor+0x10d>
			return commands[i].func(argc, argv, tf);
f01008aa:	6b ff 0c             	imul   $0xc,%edi,%edi
f01008ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01008b0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008b4:	8d 45 a8             	lea    -0x58(%ebp),%eax
f01008b7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008bb:	89 34 24             	mov    %esi,(%esp)
f01008be:	ff 97 68 20 10 f0    	call   *-0xfefdf98(%edi)
	cprintf("Type 'help' for a list of commands.\n");

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008c4:	85 c0                	test   %eax,%eax
f01008c6:	78 28                	js     f01008f0 <monitor+0x130>
f01008c8:	e9 14 ff ff ff       	jmp    f01007e1 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008cd:	83 c7 01             	add    $0x1,%edi
f01008d0:	83 c3 0c             	add    $0xc,%ebx
f01008d3:	83 ff 03             	cmp    $0x3,%edi
f01008d6:	75 bd                	jne    f0100895 <monitor+0xd5>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008d8:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008db:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008df:	c7 04 24 38 1e 10 f0 	movl   $0xf0101e38,(%esp)
f01008e6:	e8 48 01 00 00       	call   f0100a33 <cprintf>
f01008eb:	e9 f1 fe ff ff       	jmp    f01007e1 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008f0:	83 c4 5c             	add    $0x5c,%esp
f01008f3:	5b                   	pop    %ebx
f01008f4:	5e                   	pop    %esi
f01008f5:	5f                   	pop    %edi
f01008f6:	5d                   	pop    %ebp
f01008f7:	c3                   	ret    

f01008f8 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008f8:	55                   	push   %ebp
f01008f9:	89 e5                	mov    %esp,%ebp
f01008fb:	57                   	push   %edi
f01008fc:	56                   	push   %esi
f01008fd:	53                   	push   %ebx
f01008fe:	83 ec 4c             	sub    $0x4c,%esp
	 * added by troore
	 * */
	uint32_t *ebp, *eip;
	int i;

	cprintf("Stack backtrace:\n");
f0100901:	c7 04 24 4e 1e 10 f0 	movl   $0xf0101e4e,(%esp)
f0100908:	e8 26 01 00 00       	call   f0100a33 <cprintf>

	ebp = (uint32_t *)read_ebp();
f010090d:	89 ee                	mov    %ebp,%esi
	while (ebp)
f010090f:	85 f6                	test   %esi,%esi
f0100911:	0f 84 ca 00 00 00    	je     f01009e1 <mon_backtrace+0xe9>
	{
		struct Eipdebuginfo info;

		eip = (uint32_t *)*(ebp + 1);
f0100917:	8b 7e 04             	mov    0x4(%esi),%edi
		cprintf("  ebp %08x  eip %08x  args ", ebp, eip);
f010091a:	89 7c 24 08          	mov    %edi,0x8(%esp)
f010091e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100922:	c7 04 24 60 1e 10 f0 	movl   $0xf0101e60,(%esp)
f0100929:	e8 05 01 00 00       	call   f0100a33 <cprintf>
		for (i = 1; i <= 5; i++)
		{
			cprintf("%08x", *(ebp + 1 + i));
f010092e:	8b 46 08             	mov    0x8(%esi),%eax
f0100931:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100935:	c7 04 24 7c 1e 10 f0 	movl   $0xf0101e7c,(%esp)
f010093c:	e8 f2 00 00 00       	call   f0100a33 <cprintf>
f0100941:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100946:	eb 1d                	jmp    f0100965 <mon_backtrace+0x6d>
f0100948:	8b 44 9e 04          	mov    0x4(%esi,%ebx,4),%eax
f010094c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100950:	c7 04 24 7c 1e 10 f0 	movl   $0xf0101e7c,(%esp)
f0100957:	e8 d7 00 00 00       	call   f0100a33 <cprintf>
			cprintf((i == 5) ? "\n" : " ");
f010095c:	83 fb 05             	cmp    $0x5,%ebx
f010095f:	0f 84 89 00 00 00    	je     f01009ee <mon_backtrace+0xf6>
f0100965:	c7 04 24 19 1e 10 f0 	movl   $0xf0101e19,(%esp)
f010096c:	e8 c2 00 00 00       	call   f0100a33 <cprintf>
	{
		struct Eipdebuginfo info;

		eip = (uint32_t *)*(ebp + 1);
		cprintf("  ebp %08x  eip %08x  args ", ebp, eip);
		for (i = 1; i <= 5; i++)
f0100971:	83 c3 01             	add    $0x1,%ebx
f0100974:	83 fb 06             	cmp    $0x6,%ebx
f0100977:	75 cf                	jne    f0100948 <mon_backtrace+0x50>
		{
			cprintf("%08x", *(ebp + 1 + i));
			cprintf((i == 5) ? "\n" : " ");
		}
		
		if (debuginfo_eip((uintptr_t)eip, &info) < 0)
f0100979:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010097c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100980:	89 3c 24             	mov    %edi,(%esp)
f0100983:	e8 06 02 00 00       	call   f0100b8e <debuginfo_eip>
f0100988:	85 c0                	test   %eax,%eax
f010098a:	79 1c                	jns    f01009a8 <mon_backtrace+0xb0>
			panic("Invalid address found when backtracing\n");
f010098c:	c7 44 24 08 e0 1f 10 	movl   $0xf0101fe0,0x8(%esp)
f0100993:	f0 
f0100994:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
f010099b:	00 
f010099c:	c7 04 24 81 1e 10 f0 	movl   $0xf0101e81,(%esp)
f01009a3:	e8 dd f6 ff ff       	call   f0100085 <_panic>
		cprintf("\t%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, ((uintptr_t)eip - info.eip_fn_addr));
f01009a8:	2b 7d e0             	sub    -0x20(%ebp),%edi
f01009ab:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01009af:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01009b2:	89 44 24 10          	mov    %eax,0x10(%esp)
f01009b6:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01009b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009bd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01009c0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009c4:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01009c7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009cb:	c7 04 24 90 1e 10 f0 	movl   $0xf0101e90,(%esp)
f01009d2:	e8 5c 00 00 00       	call   f0100a33 <cprintf>

		ebp = (uint32_t *)*ebp;
f01009d7:	8b 36                	mov    (%esi),%esi
	int i;

	cprintf("Stack backtrace:\n");

	ebp = (uint32_t *)read_ebp();
	while (ebp)
f01009d9:	85 f6                	test   %esi,%esi
f01009db:	0f 85 36 ff ff ff    	jne    f0100917 <mon_backtrace+0x1f>
		ebp = (uint32_t *)*ebp;
	}
	/* */

	return 0;
}
f01009e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01009e6:	83 c4 4c             	add    $0x4c,%esp
f01009e9:	5b                   	pop    %ebx
f01009ea:	5e                   	pop    %esi
f01009eb:	5f                   	pop    %edi
f01009ec:	5d                   	pop    %ebp
f01009ed:	c3                   	ret    
		eip = (uint32_t *)*(ebp + 1);
		cprintf("  ebp %08x  eip %08x  args ", ebp, eip);
		for (i = 1; i <= 5; i++)
		{
			cprintf("%08x", *(ebp + 1 + i));
			cprintf((i == 5) ? "\n" : " ");
f01009ee:	c7 04 24 cb 1b 10 f0 	movl   $0xf0101bcb,(%esp)
f01009f5:	e8 39 00 00 00       	call   f0100a33 <cprintf>
f01009fa:	e9 7a ff ff ff       	jmp    f0100979 <mon_backtrace+0x81>
	...

f0100a00 <vcprintf>:
	*cnt++;
}

int
vcprintf(const char *fmt, va_list ap)
{
f0100a00:	55                   	push   %ebp
f0100a01:	89 e5                	mov    %esp,%ebp
f0100a03:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100a06:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a0d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100a10:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a14:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a17:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100a1b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a1e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a22:	c7 04 24 4d 0a 10 f0 	movl   $0xf0100a4d,(%esp)
f0100a29:	e8 cf 04 00 00       	call   f0100efd <vprintfmt>
	return cnt;
}
f0100a2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a31:	c9                   	leave  
f0100a32:	c3                   	ret    

f0100a33 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a33:	55                   	push   %ebp
f0100a34:	89 e5                	mov    %esp,%ebp
f0100a36:	83 ec 18             	sub    $0x18,%esp
	vprintfmt((void*)putch, &cnt, fmt, ap);
	return cnt;
}

int
cprintf(const char *fmt, ...)
f0100a39:	8d 45 0c             	lea    0xc(%ebp),%eax
{
	va_list ap;
	int cnt;

	va_start(ap, fmt);
	cnt = vcprintf(fmt, ap);
f0100a3c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a40:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a43:	89 04 24             	mov    %eax,(%esp)
f0100a46:	e8 b5 ff ff ff       	call   f0100a00 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a4b:	c9                   	leave  
f0100a4c:	c3                   	ret    

f0100a4d <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a4d:	55                   	push   %ebp
f0100a4e:	89 e5                	mov    %esp,%ebp
f0100a50:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100a53:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a56:	89 04 24             	mov    %eax,(%esp)
f0100a59:	e8 3c fa ff ff       	call   f010049a <cputchar>
	*cnt++;
}
f0100a5e:	c9                   	leave  
f0100a5f:	c3                   	ret    

f0100a60 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a60:	55                   	push   %ebp
f0100a61:	89 e5                	mov    %esp,%ebp
f0100a63:	57                   	push   %edi
f0100a64:	56                   	push   %esi
f0100a65:	53                   	push   %ebx
f0100a66:	83 ec 14             	sub    $0x14,%esp
f0100a69:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a6c:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a6f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100a72:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a75:	8b 1a                	mov    (%edx),%ebx
f0100a77:	8b 01                	mov    (%ecx),%eax
f0100a79:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	while (l <= r) {
f0100a7c:	39 c3                	cmp    %eax,%ebx
f0100a7e:	0f 8f 9c 00 00 00    	jg     f0100b20 <stab_binsearch+0xc0>
f0100a84:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		int true_m = (l + r) / 2, m = true_m;
f0100a8b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a8e:	01 d8                	add    %ebx,%eax
f0100a90:	89 c7                	mov    %eax,%edi
f0100a92:	c1 ef 1f             	shr    $0x1f,%edi
f0100a95:	01 c7                	add    %eax,%edi
f0100a97:	d1 ff                	sar    %edi
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a99:	39 df                	cmp    %ebx,%edi
f0100a9b:	7c 33                	jl     f0100ad0 <stab_binsearch+0x70>
f0100a9d:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100aa0:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100aa3:	0f b6 44 82 04       	movzbl 0x4(%edx,%eax,4),%eax
f0100aa8:	39 f0                	cmp    %esi,%eax
f0100aaa:	0f 84 bc 00 00 00    	je     f0100b6c <stab_binsearch+0x10c>
f0100ab0:	8d 44 7f fd          	lea    -0x3(%edi,%edi,2),%eax
f0100ab4:	8d 54 82 04          	lea    0x4(%edx,%eax,4),%edx
f0100ab8:	89 f8                	mov    %edi,%eax
			m--;
f0100aba:	83 e8 01             	sub    $0x1,%eax
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100abd:	39 d8                	cmp    %ebx,%eax
f0100abf:	7c 0f                	jl     f0100ad0 <stab_binsearch+0x70>
f0100ac1:	0f b6 0a             	movzbl (%edx),%ecx
f0100ac4:	83 ea 0c             	sub    $0xc,%edx
f0100ac7:	39 f1                	cmp    %esi,%ecx
f0100ac9:	75 ef                	jne    f0100aba <stab_binsearch+0x5a>
f0100acb:	e9 9e 00 00 00       	jmp    f0100b6e <stab_binsearch+0x10e>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100ad0:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0100ad3:	eb 3c                	jmp    f0100b11 <stab_binsearch+0xb1>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100ad5:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100ad8:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
f0100ada:	8d 5f 01             	lea    0x1(%edi),%ebx
f0100add:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0100ae4:	eb 2b                	jmp    f0100b11 <stab_binsearch+0xb1>
		} else if (stabs[m].n_value > addr) {
f0100ae6:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100ae9:	76 14                	jbe    f0100aff <stab_binsearch+0x9f>
			*region_right = m - 1;
f0100aeb:	83 e8 01             	sub    $0x1,%eax
f0100aee:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100af1:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100af4:	89 02                	mov    %eax,(%edx)
f0100af6:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0100afd:	eb 12                	jmp    f0100b11 <stab_binsearch+0xb1>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100aff:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100b02:	89 01                	mov    %eax,(%ecx)
			l = m;
			addr++;
f0100b04:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100b08:	89 c3                	mov    %eax,%ebx
f0100b0a:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100b11:	39 5d ec             	cmp    %ebx,-0x14(%ebp)
f0100b14:	0f 8d 71 ff ff ff    	jge    f0100a8b <stab_binsearch+0x2b>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100b1a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100b1e:	75 0f                	jne    f0100b2f <stab_binsearch+0xcf>
		*region_right = *region_left - 1;
f0100b20:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100b23:	8b 03                	mov    (%ebx),%eax
f0100b25:	83 e8 01             	sub    $0x1,%eax
f0100b28:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100b2b:	89 02                	mov    %eax,(%edx)
f0100b2d:	eb 57                	jmp    f0100b86 <stab_binsearch+0x126>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b2f:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100b32:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b34:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100b37:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b39:	39 c1                	cmp    %eax,%ecx
f0100b3b:	7d 28                	jge    f0100b65 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0100b3d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b40:	8b 5d f0             	mov    -0x10(%ebp),%ebx
f0100b43:	0f b6 54 93 04       	movzbl 0x4(%ebx,%edx,4),%edx
f0100b48:	39 f2                	cmp    %esi,%edx
f0100b4a:	74 19                	je     f0100b65 <stab_binsearch+0x105>
f0100b4c:	8d 54 40 fd          	lea    -0x3(%eax,%eax,2),%edx
f0100b50:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx
		     l--)
f0100b54:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b57:	39 c1                	cmp    %eax,%ecx
f0100b59:	7d 0a                	jge    f0100b65 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0100b5b:	0f b6 1a             	movzbl (%edx),%ebx
f0100b5e:	83 ea 0c             	sub    $0xc,%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b61:	39 f3                	cmp    %esi,%ebx
f0100b63:	75 ef                	jne    f0100b54 <stab_binsearch+0xf4>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
f0100b65:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b68:	89 02                	mov    %eax,(%edx)
f0100b6a:	eb 1a                	jmp    f0100b86 <stab_binsearch+0x126>
	}
}
f0100b6c:	89 f8                	mov    %edi,%eax
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100b6e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b71:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0100b74:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100b78:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100b7b:	0f 82 54 ff ff ff    	jb     f0100ad5 <stab_binsearch+0x75>
f0100b81:	e9 60 ff ff ff       	jmp    f0100ae6 <stab_binsearch+0x86>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0100b86:	83 c4 14             	add    $0x14,%esp
f0100b89:	5b                   	pop    %ebx
f0100b8a:	5e                   	pop    %esi
f0100b8b:	5f                   	pop    %edi
f0100b8c:	5d                   	pop    %ebp
f0100b8d:	c3                   	ret    

f0100b8e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b8e:	55                   	push   %ebp
f0100b8f:	89 e5                	mov    %esp,%ebp
f0100b91:	83 ec 48             	sub    $0x48,%esp
f0100b94:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100b97:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100b9a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100b9d:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ba0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100ba3:	c7 03 84 20 10 f0    	movl   $0xf0102084,(%ebx)
	info->eip_line = 0;
f0100ba9:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100bb0:	c7 43 08 84 20 10 f0 	movl   $0xf0102084,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100bb7:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100bbe:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100bc1:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100bc8:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100bce:	76 12                	jbe    f0100be2 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bd0:	b8 ed 78 10 f0       	mov    $0xf01078ed,%eax
f0100bd5:	3d bd 5e 10 f0       	cmp    $0xf0105ebd,%eax
f0100bda:	0f 86 92 01 00 00    	jbe    f0100d72 <debuginfo_eip+0x1e4>
f0100be0:	eb 1c                	jmp    f0100bfe <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100be2:	c7 44 24 08 8e 20 10 	movl   $0xf010208e,0x8(%esp)
f0100be9:	f0 
f0100bea:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100bf1:	00 
f0100bf2:	c7 04 24 9b 20 10 f0 	movl   $0xf010209b,(%esp)
f0100bf9:	e8 87 f4 ff ff       	call   f0100085 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bfe:	80 3d ec 78 10 f0 00 	cmpb   $0x0,0xf01078ec
f0100c05:	0f 85 67 01 00 00    	jne    f0100d72 <debuginfo_eip+0x1e4>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100c0b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100c12:	b8 bc 5e 10 f0       	mov    $0xf0105ebc,%eax
f0100c17:	2d bc 22 10 f0       	sub    $0xf01022bc,%eax
f0100c1c:	c1 f8 02             	sar    $0x2,%eax
f0100c1f:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100c25:	83 e8 01             	sub    $0x1,%eax
f0100c28:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100c2b:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100c2e:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100c31:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c35:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100c3c:	b8 bc 22 10 f0       	mov    $0xf01022bc,%eax
f0100c41:	e8 1a fe ff ff       	call   f0100a60 <stab_binsearch>
	if (lfile == 0)
f0100c46:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c49:	85 c0                	test   %eax,%eax
f0100c4b:	0f 84 21 01 00 00    	je     f0100d72 <debuginfo_eip+0x1e4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c51:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100c54:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c57:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c5a:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c5d:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c60:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c64:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100c6b:	b8 bc 22 10 f0       	mov    $0xf01022bc,%eax
f0100c70:	e8 eb fd ff ff       	call   f0100a60 <stab_binsearch>

	if (lfun <= rfun) {
f0100c75:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100c78:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100c7b:	7f 3c                	jg     f0100cb9 <debuginfo_eip+0x12b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c7d:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100c80:	8b 80 bc 22 10 f0    	mov    -0xfefdd44(%eax),%eax
f0100c86:	ba ed 78 10 f0       	mov    $0xf01078ed,%edx
f0100c8b:	81 ea bd 5e 10 f0    	sub    $0xf0105ebd,%edx
f0100c91:	39 d0                	cmp    %edx,%eax
f0100c93:	73 08                	jae    f0100c9d <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c95:	05 bd 5e 10 f0       	add    $0xf0105ebd,%eax
f0100c9a:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c9d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ca0:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100ca3:	8b 92 c4 22 10 f0    	mov    -0xfefdd3c(%edx),%edx
f0100ca9:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100cac:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100cae:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100cb1:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100cb4:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100cb7:	eb 0f                	jmp    f0100cc8 <debuginfo_eip+0x13a>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100cb9:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100cbc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cbf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100cc2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cc5:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100cc8:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100ccf:	00 
f0100cd0:	8b 43 08             	mov    0x8(%ebx),%eax
f0100cd3:	89 04 24             	mov    %eax,(%esp)
f0100cd6:	e8 40 09 00 00       	call   f010161b <strfind>
f0100cdb:	2b 43 08             	sub    0x8(%ebx),%eax
f0100cde:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	which one.
	// Your code here.
	/* *
	 * added by troore
	 * */
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100ce1:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100ce4:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100ce7:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ceb:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100cf2:	b8 bc 22 10 f0       	mov    $0xf01022bc,%eax
f0100cf7:	e8 64 fd ff ff       	call   f0100a60 <stab_binsearch>
	if (lline <= rline)
f0100cfc:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100cff:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0100d02:	7f 6e                	jg     f0100d72 <debuginfo_eip+0x1e4>
		info->eip_line = rline;
f0100d04:	89 43 04             	mov    %eax,0x4(%ebx)
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
f0100d07:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100d0a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d0d:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100d10:	81 c2 c4 22 10 f0    	add    $0xf01022c4,%edx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d16:	eb 06                	jmp    f0100d1e <debuginfo_eip+0x190>
f0100d18:	83 e8 01             	sub    $0x1,%eax
f0100d1b:	83 ea 0c             	sub    $0xc,%edx
f0100d1e:	89 c6                	mov    %eax,%esi
f0100d20:	39 f8                	cmp    %edi,%eax
f0100d22:	7c 1d                	jl     f0100d41 <debuginfo_eip+0x1b3>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100d24:	0f b6 4a fc          	movzbl -0x4(%edx),%ecx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d28:	80 f9 84             	cmp    $0x84,%cl
f0100d2b:	74 5e                	je     f0100d8b <debuginfo_eip+0x1fd>
f0100d2d:	80 f9 64             	cmp    $0x64,%cl
f0100d30:	75 e6                	jne    f0100d18 <debuginfo_eip+0x18a>
f0100d32:	83 3a 00             	cmpl   $0x0,(%edx)
f0100d35:	74 e1                	je     f0100d18 <debuginfo_eip+0x18a>
f0100d37:	90                   	nop
f0100d38:	eb 51                	jmp    f0100d8b <debuginfo_eip+0x1fd>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100d3a:	05 bd 5e 10 f0       	add    $0xf0105ebd,%eax
f0100d3f:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d41:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d44:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100d47:	7d 30                	jge    f0100d79 <debuginfo_eip+0x1eb>
		for (lline = lfun + 1;
f0100d49:	83 c0 01             	add    $0x1,%eax
f0100d4c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d4f:	ba bc 22 10 f0       	mov    $0xf01022bc,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d54:	eb 08                	jmp    f0100d5e <debuginfo_eip+0x1d0>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100d56:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100d5a:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)

	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d5e:	8b 45 d4             	mov    -0x2c(%ebp),%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d61:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100d64:	7d 13                	jge    f0100d79 <debuginfo_eip+0x1eb>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d66:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100d69:	80 7c 10 04 a0       	cmpb   $0xa0,0x4(%eax,%edx,1)
f0100d6e:	74 e6                	je     f0100d56 <debuginfo_eip+0x1c8>
f0100d70:	eb 07                	jmp    f0100d79 <debuginfo_eip+0x1eb>
f0100d72:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d77:	eb 05                	jmp    f0100d7e <debuginfo_eip+0x1f0>
f0100d79:	b8 00 00 00 00       	mov    $0x0,%eax
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
}
f0100d7e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100d81:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100d84:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100d87:	89 ec                	mov    %ebp,%esp
f0100d89:	5d                   	pop    %ebp
f0100d8a:	c3                   	ret    
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100d8b:	6b c6 0c             	imul   $0xc,%esi,%eax
f0100d8e:	8b 80 bc 22 10 f0    	mov    -0xfefdd44(%eax),%eax
f0100d94:	ba ed 78 10 f0       	mov    $0xf01078ed,%edx
f0100d99:	81 ea bd 5e 10 f0    	sub    $0xf0105ebd,%edx
f0100d9f:	39 d0                	cmp    %edx,%eax
f0100da1:	72 97                	jb     f0100d3a <debuginfo_eip+0x1ac>
f0100da3:	eb 9c                	jmp    f0100d41 <debuginfo_eip+0x1b3>
	...

f0100db0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100db0:	55                   	push   %ebp
f0100db1:	89 e5                	mov    %esp,%ebp
f0100db3:	57                   	push   %edi
f0100db4:	56                   	push   %esi
f0100db5:	53                   	push   %ebx
f0100db6:	83 ec 4c             	sub    $0x4c,%esp
f0100db9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100dbc:	89 d6                	mov    %edx,%esi
f0100dbe:	8b 45 08             	mov    0x8(%ebp),%eax
f0100dc1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100dc4:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100dc7:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100dca:	8b 45 10             	mov    0x10(%ebp),%eax
f0100dcd:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100dd0:	8b 7d 18             	mov    0x18(%ebp),%edi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100dd3:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100dd6:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100ddb:	39 d1                	cmp    %edx,%ecx
f0100ddd:	72 15                	jb     f0100df4 <printnum+0x44>
f0100ddf:	77 07                	ja     f0100de8 <printnum+0x38>
f0100de1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100de4:	39 d0                	cmp    %edx,%eax
f0100de6:	76 0c                	jbe    f0100df4 <printnum+0x44>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100de8:	83 eb 01             	sub    $0x1,%ebx
f0100deb:	85 db                	test   %ebx,%ebx
f0100ded:	8d 76 00             	lea    0x0(%esi),%esi
f0100df0:	7f 61                	jg     f0100e53 <printnum+0xa3>
f0100df2:	eb 70                	jmp    f0100e64 <printnum+0xb4>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100df4:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0100df8:	83 eb 01             	sub    $0x1,%ebx
f0100dfb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100dff:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e03:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0100e07:	8b 5c 24 0c          	mov    0xc(%esp),%ebx
f0100e0b:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0100e0e:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0100e11:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100e14:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100e18:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100e1f:	00 
f0100e20:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100e23:	89 04 24             	mov    %eax,(%esp)
f0100e26:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100e29:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100e2d:	e8 7e 0a 00 00       	call   f01018b0 <__udivdi3>
f0100e32:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100e35:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100e38:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100e3c:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100e40:	89 04 24             	mov    %eax,(%esp)
f0100e43:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100e47:	89 f2                	mov    %esi,%edx
f0100e49:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e4c:	e8 5f ff ff ff       	call   f0100db0 <printnum>
f0100e51:	eb 11                	jmp    f0100e64 <printnum+0xb4>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e53:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e57:	89 3c 24             	mov    %edi,(%esp)
f0100e5a:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e5d:	83 eb 01             	sub    $0x1,%ebx
f0100e60:	85 db                	test   %ebx,%ebx
f0100e62:	7f ef                	jg     f0100e53 <printnum+0xa3>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e64:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e68:	8b 74 24 04          	mov    0x4(%esp),%esi
f0100e6c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100e6f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e73:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100e7a:	00 
f0100e7b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100e7e:	89 14 24             	mov    %edx,(%esp)
f0100e81:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100e84:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100e88:	e8 53 0b 00 00       	call   f01019e0 <__umoddi3>
f0100e8d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e91:	0f be 80 a9 20 10 f0 	movsbl -0xfefdf57(%eax),%eax
f0100e98:	89 04 24             	mov    %eax,(%esp)
f0100e9b:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100e9e:	83 c4 4c             	add    $0x4c,%esp
f0100ea1:	5b                   	pop    %ebx
f0100ea2:	5e                   	pop    %esi
f0100ea3:	5f                   	pop    %edi
f0100ea4:	5d                   	pop    %ebp
f0100ea5:	c3                   	ret    

f0100ea6 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100ea6:	55                   	push   %ebp
f0100ea7:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100ea9:	83 fa 01             	cmp    $0x1,%edx
f0100eac:	7e 0e                	jle    f0100ebc <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100eae:	8b 10                	mov    (%eax),%edx
f0100eb0:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100eb3:	89 08                	mov    %ecx,(%eax)
f0100eb5:	8b 02                	mov    (%edx),%eax
f0100eb7:	8b 52 04             	mov    0x4(%edx),%edx
f0100eba:	eb 22                	jmp    f0100ede <getuint+0x38>
	else if (lflag)
f0100ebc:	85 d2                	test   %edx,%edx
f0100ebe:	74 10                	je     f0100ed0 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100ec0:	8b 10                	mov    (%eax),%edx
f0100ec2:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100ec5:	89 08                	mov    %ecx,(%eax)
f0100ec7:	8b 02                	mov    (%edx),%eax
f0100ec9:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ece:	eb 0e                	jmp    f0100ede <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100ed0:	8b 10                	mov    (%eax),%edx
f0100ed2:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100ed5:	89 08                	mov    %ecx,(%eax)
f0100ed7:	8b 02                	mov    (%edx),%eax
f0100ed9:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100ede:	5d                   	pop    %ebp
f0100edf:	c3                   	ret    

f0100ee0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100ee0:	55                   	push   %ebp
f0100ee1:	89 e5                	mov    %esp,%ebp
f0100ee3:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100ee6:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100eea:	8b 10                	mov    (%eax),%edx
f0100eec:	3b 50 04             	cmp    0x4(%eax),%edx
f0100eef:	73 0a                	jae    f0100efb <sprintputch+0x1b>
		*b->buf++ = ch;
f0100ef1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100ef4:	88 0a                	mov    %cl,(%edx)
f0100ef6:	83 c2 01             	add    $0x1,%edx
f0100ef9:	89 10                	mov    %edx,(%eax)
}
f0100efb:	5d                   	pop    %ebp
f0100efc:	c3                   	ret    

f0100efd <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100efd:	55                   	push   %ebp
f0100efe:	89 e5                	mov    %esp,%ebp
f0100f00:	57                   	push   %edi
f0100f01:	56                   	push   %esi
f0100f02:	53                   	push   %ebx
f0100f03:	83 ec 5c             	sub    $0x5c,%esp
f0100f06:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100f09:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100f0c:	8b 5d 10             	mov    0x10(%ebp),%ebx
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100f0f:	c7 45 c8 ff ff ff ff 	movl   $0xffffffff,-0x38(%ebp)
f0100f16:	eb 11                	jmp    f0100f29 <vprintfmt+0x2c>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100f18:	85 c0                	test   %eax,%eax
f0100f1a:	0f 84 ec 03 00 00    	je     f010130c <vprintfmt+0x40f>
				return;
			putch(ch, putdat);
f0100f20:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f24:	89 04 24             	mov    %eax,(%esp)
f0100f27:	ff d7                	call   *%edi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100f29:	0f b6 03             	movzbl (%ebx),%eax
f0100f2c:	83 c3 01             	add    $0x1,%ebx
f0100f2f:	83 f8 25             	cmp    $0x25,%eax
f0100f32:	75 e4                	jne    f0100f18 <vprintfmt+0x1b>
f0100f34:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100f38:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100f3f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100f46:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100f4d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100f52:	eb 06                	jmp    f0100f5a <vprintfmt+0x5d>
f0100f54:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0100f58:	89 c3                	mov    %eax,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f5a:	0f b6 13             	movzbl (%ebx),%edx
f0100f5d:	0f b6 c2             	movzbl %dl,%eax
f0100f60:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f63:	8d 43 01             	lea    0x1(%ebx),%eax
f0100f66:	83 ea 23             	sub    $0x23,%edx
f0100f69:	80 fa 55             	cmp    $0x55,%dl
f0100f6c:	0f 87 7d 03 00 00    	ja     f01012ef <vprintfmt+0x3f2>
f0100f72:	0f b6 d2             	movzbl %dl,%edx
f0100f75:	ff 24 95 38 21 10 f0 	jmp    *-0xfefdec8(,%edx,4)
f0100f7c:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100f80:	eb d6                	jmp    f0100f58 <vprintfmt+0x5b>
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f82:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100f85:	83 ea 30             	sub    $0x30,%edx
f0100f88:	89 55 d0             	mov    %edx,-0x30(%ebp)
				ch = *fmt;
f0100f8b:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0100f8e:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0100f91:	83 fb 09             	cmp    $0x9,%ebx
f0100f94:	77 4c                	ja     f0100fe2 <vprintfmt+0xe5>
f0100f96:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100f99:	8b 4d d0             	mov    -0x30(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f9c:	83 c0 01             	add    $0x1,%eax
				precision = precision * 10 + ch - '0';
f0100f9f:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100fa2:	8d 4c 4a d0          	lea    -0x30(%edx,%ecx,2),%ecx
				ch = *fmt;
f0100fa6:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0100fa9:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0100fac:	83 fb 09             	cmp    $0x9,%ebx
f0100faf:	76 eb                	jbe    f0100f9c <vprintfmt+0x9f>
f0100fb1:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0100fb4:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100fb7:	eb 29                	jmp    f0100fe2 <vprintfmt+0xe5>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100fb9:	8b 55 14             	mov    0x14(%ebp),%edx
f0100fbc:	8d 5a 04             	lea    0x4(%edx),%ebx
f0100fbf:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0100fc2:	8b 12                	mov    (%edx),%edx
f0100fc4:	89 55 d0             	mov    %edx,-0x30(%ebp)
			goto process_precision;
f0100fc7:	eb 19                	jmp    f0100fe2 <vprintfmt+0xe5>

		case '.':
			if (width < 0)
f0100fc9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100fcc:	c1 fa 1f             	sar    $0x1f,%edx
f0100fcf:	f7 d2                	not    %edx
f0100fd1:	21 55 e4             	and    %edx,-0x1c(%ebp)
f0100fd4:	eb 82                	jmp    f0100f58 <vprintfmt+0x5b>
f0100fd6:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
			goto reswitch;
f0100fdd:	e9 76 ff ff ff       	jmp    f0100f58 <vprintfmt+0x5b>

		process_precision:
			if (width < 0)
f0100fe2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100fe6:	0f 89 6c ff ff ff    	jns    f0100f58 <vprintfmt+0x5b>
f0100fec:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100fef:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100ff2:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0100ff5:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100ff8:	e9 5b ff ff ff       	jmp    f0100f58 <vprintfmt+0x5b>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100ffd:	83 c1 01             	add    $0x1,%ecx
			goto reswitch;
f0101000:	e9 53 ff ff ff       	jmp    f0100f58 <vprintfmt+0x5b>
f0101005:	89 45 cc             	mov    %eax,-0x34(%ebp)

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101008:	8b 45 14             	mov    0x14(%ebp),%eax
f010100b:	8d 50 04             	lea    0x4(%eax),%edx
f010100e:	89 55 14             	mov    %edx,0x14(%ebp)
f0101011:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101015:	8b 00                	mov    (%eax),%eax
f0101017:	89 04 24             	mov    %eax,(%esp)
f010101a:	ff d7                	call   *%edi
f010101c:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			break;
f010101f:	e9 05 ff ff ff       	jmp    f0100f29 <vprintfmt+0x2c>
f0101024:	89 45 cc             	mov    %eax,-0x34(%ebp)

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101027:	8b 45 14             	mov    0x14(%ebp),%eax
f010102a:	8d 50 04             	lea    0x4(%eax),%edx
f010102d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101030:	8b 00                	mov    (%eax),%eax
f0101032:	89 c2                	mov    %eax,%edx
f0101034:	c1 fa 1f             	sar    $0x1f,%edx
f0101037:	31 d0                	xor    %edx,%eax
f0101039:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010103b:	83 f8 06             	cmp    $0x6,%eax
f010103e:	7f 0b                	jg     f010104b <vprintfmt+0x14e>
f0101040:	8b 14 85 90 22 10 f0 	mov    -0xfefdd70(,%eax,4),%edx
f0101047:	85 d2                	test   %edx,%edx
f0101049:	75 20                	jne    f010106b <vprintfmt+0x16e>
				printfmt(putch, putdat, "error %d", err);
f010104b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010104f:	c7 44 24 08 ba 20 10 	movl   $0xf01020ba,0x8(%esp)
f0101056:	f0 
f0101057:	89 74 24 04          	mov    %esi,0x4(%esp)
f010105b:	89 3c 24             	mov    %edi,(%esp)
f010105e:	e8 31 03 00 00       	call   f0101394 <printfmt>
f0101063:	8b 5d cc             	mov    -0x34(%ebp),%ebx
		// error message
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101066:	e9 be fe ff ff       	jmp    f0100f29 <vprintfmt+0x2c>
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
f010106b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010106f:	c7 44 24 08 c3 20 10 	movl   $0xf01020c3,0x8(%esp)
f0101076:	f0 
f0101077:	89 74 24 04          	mov    %esi,0x4(%esp)
f010107b:	89 3c 24             	mov    %edi,(%esp)
f010107e:	e8 11 03 00 00       	call   f0101394 <printfmt>
f0101083:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0101086:	e9 9e fe ff ff       	jmp    f0100f29 <vprintfmt+0x2c>
f010108b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010108e:	89 c3                	mov    %eax,%ebx
f0101090:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101093:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101096:	89 45 c4             	mov    %eax,-0x3c(%ebp)
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101099:	8b 45 14             	mov    0x14(%ebp),%eax
f010109c:	8d 50 04             	lea    0x4(%eax),%edx
f010109f:	89 55 14             	mov    %edx,0x14(%ebp)
f01010a2:	8b 00                	mov    (%eax),%eax
f01010a4:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01010a7:	85 c0                	test   %eax,%eax
f01010a9:	75 07                	jne    f01010b2 <vprintfmt+0x1b5>
f01010ab:	c7 45 e0 c6 20 10 f0 	movl   $0xf01020c6,-0x20(%ebp)
				p = "(null)";
			if (width > 0 && padc != '-')
f01010b2:	83 7d c4 00          	cmpl   $0x0,-0x3c(%ebp)
f01010b6:	7e 06                	jle    f01010be <vprintfmt+0x1c1>
f01010b8:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01010bc:	75 13                	jne    f01010d1 <vprintfmt+0x1d4>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010be:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01010c1:	0f be 02             	movsbl (%edx),%eax
f01010c4:	85 c0                	test   %eax,%eax
f01010c6:	0f 85 99 00 00 00    	jne    f0101165 <vprintfmt+0x268>
f01010cc:	e9 86 00 00 00       	jmp    f0101157 <vprintfmt+0x25a>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010d1:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01010d5:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01010d8:	89 0c 24             	mov    %ecx,(%esp)
f01010db:	e8 db 03 00 00       	call   f01014bb <strnlen>
f01010e0:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f01010e3:	29 c2                	sub    %eax,%edx
f01010e5:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01010e8:	85 d2                	test   %edx,%edx
f01010ea:	7e d2                	jle    f01010be <vprintfmt+0x1c1>
					putch(padc, putdat);
f01010ec:	0f be 4d d4          	movsbl -0x2c(%ebp),%ecx
f01010f0:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01010f3:	89 5d c4             	mov    %ebx,-0x3c(%ebp)
f01010f6:	89 d3                	mov    %edx,%ebx
f01010f8:	89 74 24 04          	mov    %esi,0x4(%esp)
f01010fc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01010ff:	89 04 24             	mov    %eax,(%esp)
f0101102:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101104:	83 eb 01             	sub    $0x1,%ebx
f0101107:	85 db                	test   %ebx,%ebx
f0101109:	7f ed                	jg     f01010f8 <vprintfmt+0x1fb>
f010110b:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f010110e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0101115:	eb a7                	jmp    f01010be <vprintfmt+0x1c1>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101117:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010111b:	74 18                	je     f0101135 <vprintfmt+0x238>
f010111d:	8d 50 e0             	lea    -0x20(%eax),%edx
f0101120:	83 fa 5e             	cmp    $0x5e,%edx
f0101123:	76 10                	jbe    f0101135 <vprintfmt+0x238>
					putch('?', putdat);
f0101125:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101129:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101130:	ff 55 e0             	call   *-0x20(%ebp)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101133:	eb 0a                	jmp    f010113f <vprintfmt+0x242>
					putch('?', putdat);
				else
					putch(ch, putdat);
f0101135:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101139:	89 04 24             	mov    %eax,(%esp)
f010113c:	ff 55 e0             	call   *-0x20(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010113f:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f0101143:	0f be 03             	movsbl (%ebx),%eax
f0101146:	85 c0                	test   %eax,%eax
f0101148:	74 05                	je     f010114f <vprintfmt+0x252>
f010114a:	83 c3 01             	add    $0x1,%ebx
f010114d:	eb 29                	jmp    f0101178 <vprintfmt+0x27b>
f010114f:	89 fe                	mov    %edi,%esi
f0101151:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101154:	8b 5d d0             	mov    -0x30(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101157:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010115b:	7f 2e                	jg     f010118b <vprintfmt+0x28e>
f010115d:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0101160:	e9 c4 fd ff ff       	jmp    f0100f29 <vprintfmt+0x2c>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101165:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101168:	83 c2 01             	add    $0x1,%edx
f010116b:	89 7d e0             	mov    %edi,-0x20(%ebp)
f010116e:	89 f7                	mov    %esi,%edi
f0101170:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101173:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0101176:	89 d3                	mov    %edx,%ebx
f0101178:	85 f6                	test   %esi,%esi
f010117a:	78 9b                	js     f0101117 <vprintfmt+0x21a>
f010117c:	83 ee 01             	sub    $0x1,%esi
f010117f:	79 96                	jns    f0101117 <vprintfmt+0x21a>
f0101181:	89 fe                	mov    %edi,%esi
f0101183:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101186:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101189:	eb cc                	jmp    f0101157 <vprintfmt+0x25a>
f010118b:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f010118e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101191:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101195:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010119c:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010119e:	83 eb 01             	sub    $0x1,%ebx
f01011a1:	85 db                	test   %ebx,%ebx
f01011a3:	7f ec                	jg     f0101191 <vprintfmt+0x294>
f01011a5:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01011a8:	e9 7c fd ff ff       	jmp    f0100f29 <vprintfmt+0x2c>
f01011ad:	89 45 cc             	mov    %eax,-0x34(%ebp)
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01011b0:	83 f9 01             	cmp    $0x1,%ecx
f01011b3:	7e 16                	jle    f01011cb <vprintfmt+0x2ce>
		return va_arg(*ap, long long);
f01011b5:	8b 45 14             	mov    0x14(%ebp),%eax
f01011b8:	8d 50 08             	lea    0x8(%eax),%edx
f01011bb:	89 55 14             	mov    %edx,0x14(%ebp)
f01011be:	8b 10                	mov    (%eax),%edx
f01011c0:	8b 48 04             	mov    0x4(%eax),%ecx
f01011c3:	89 55 d8             	mov    %edx,-0x28(%ebp)
f01011c6:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01011c9:	eb 32                	jmp    f01011fd <vprintfmt+0x300>
	else if (lflag)
f01011cb:	85 c9                	test   %ecx,%ecx
f01011cd:	74 18                	je     f01011e7 <vprintfmt+0x2ea>
		return va_arg(*ap, long);
f01011cf:	8b 45 14             	mov    0x14(%ebp),%eax
f01011d2:	8d 50 04             	lea    0x4(%eax),%edx
f01011d5:	89 55 14             	mov    %edx,0x14(%ebp)
f01011d8:	8b 00                	mov    (%eax),%eax
f01011da:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01011dd:	89 c1                	mov    %eax,%ecx
f01011df:	c1 f9 1f             	sar    $0x1f,%ecx
f01011e2:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01011e5:	eb 16                	jmp    f01011fd <vprintfmt+0x300>
	else
		return va_arg(*ap, int);
f01011e7:	8b 45 14             	mov    0x14(%ebp),%eax
f01011ea:	8d 50 04             	lea    0x4(%eax),%edx
f01011ed:	89 55 14             	mov    %edx,0x14(%ebp)
f01011f0:	8b 00                	mov    (%eax),%eax
f01011f2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01011f5:	89 c2                	mov    %eax,%edx
f01011f7:	c1 fa 1f             	sar    $0x1f,%edx
f01011fa:	89 55 dc             	mov    %edx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01011fd:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0101200:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101203:	b8 0a 00 00 00       	mov    $0xa,%eax
			if ((long long) num < 0) {
f0101208:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010120c:	0f 89 9b 00 00 00    	jns    f01012ad <vprintfmt+0x3b0>
				putch('-', putdat);
f0101212:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101216:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010121d:	ff d7                	call   *%edi
				num = -(long long) num;
f010121f:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0101222:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101225:	f7 d9                	neg    %ecx
f0101227:	83 d3 00             	adc    $0x0,%ebx
f010122a:	f7 db                	neg    %ebx
f010122c:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101231:	eb 7a                	jmp    f01012ad <vprintfmt+0x3b0>
f0101233:	89 45 cc             	mov    %eax,-0x34(%ebp)
			base = 10;
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101236:	89 ca                	mov    %ecx,%edx
f0101238:	8d 45 14             	lea    0x14(%ebp),%eax
f010123b:	e8 66 fc ff ff       	call   f0100ea6 <getuint>
f0101240:	89 c1                	mov    %eax,%ecx
f0101242:	89 d3                	mov    %edx,%ebx
f0101244:	b8 0a 00 00 00       	mov    $0xa,%eax
			base = 10;
			goto number;
f0101249:	eb 62                	jmp    f01012ad <vprintfmt+0x3b0>
f010124b:	89 45 cc             	mov    %eax,-0x34(%ebp)
			 * */

			/* *
			 * added by troore
			 * */
			num = getuint(&ap, lflag);
f010124e:	89 ca                	mov    %ecx,%edx
f0101250:	8d 45 14             	lea    0x14(%ebp),%eax
f0101253:	e8 4e fc ff ff       	call   f0100ea6 <getuint>
f0101258:	89 c1                	mov    %eax,%ecx
f010125a:	89 d3                	mov    %edx,%ebx
f010125c:	b8 08 00 00 00       	mov    $0x8,%eax
			base = 8;
			goto number;
f0101261:	eb 4a                	jmp    f01012ad <vprintfmt+0x3b0>
f0101263:	89 45 cc             	mov    %eax,-0x34(%ebp)
			/* */

		// pointer
		case 'p':
			putch('0', putdat);
f0101266:	89 74 24 04          	mov    %esi,0x4(%esp)
f010126a:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101271:	ff d7                	call   *%edi
			putch('x', putdat);
f0101273:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101277:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010127e:	ff d7                	call   *%edi
			num = (unsigned long long)
f0101280:	8b 45 14             	mov    0x14(%ebp),%eax
f0101283:	8d 50 04             	lea    0x4(%eax),%edx
f0101286:	89 55 14             	mov    %edx,0x14(%ebp)
f0101289:	8b 08                	mov    (%eax),%ecx
f010128b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101290:	b8 10 00 00 00       	mov    $0x10,%eax
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101295:	eb 16                	jmp    f01012ad <vprintfmt+0x3b0>
f0101297:	89 45 cc             	mov    %eax,-0x34(%ebp)

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010129a:	89 ca                	mov    %ecx,%edx
f010129c:	8d 45 14             	lea    0x14(%ebp),%eax
f010129f:	e8 02 fc ff ff       	call   f0100ea6 <getuint>
f01012a4:	89 c1                	mov    %eax,%ecx
f01012a6:	89 d3                	mov    %edx,%ebx
f01012a8:	b8 10 00 00 00       	mov    $0x10,%eax
			base = 16;
		number:
			printnum(putch, putdat, num, base, width, padc);
f01012ad:	0f be 55 d4          	movsbl -0x2c(%ebp),%edx
f01012b1:	89 54 24 10          	mov    %edx,0x10(%esp)
f01012b5:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01012b8:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01012bc:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012c0:	89 0c 24             	mov    %ecx,(%esp)
f01012c3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012c7:	89 f2                	mov    %esi,%edx
f01012c9:	89 f8                	mov    %edi,%eax
f01012cb:	e8 e0 fa ff ff       	call   f0100db0 <printnum>
f01012d0:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			break;
f01012d3:	e9 51 fc ff ff       	jmp    f0100f29 <vprintfmt+0x2c>
f01012d8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01012db:	8b 55 e0             	mov    -0x20(%ebp),%edx

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01012de:	89 74 24 04          	mov    %esi,0x4(%esp)
f01012e2:	89 14 24             	mov    %edx,(%esp)
f01012e5:	ff d7                	call   *%edi
f01012e7:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			break;
f01012ea:	e9 3a fc ff ff       	jmp    f0100f29 <vprintfmt+0x2c>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01012ef:	89 74 24 04          	mov    %esi,0x4(%esp)
f01012f3:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01012fa:	ff d7                	call   *%edi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01012fc:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01012ff:	80 38 25             	cmpb   $0x25,(%eax)
f0101302:	0f 84 21 fc ff ff    	je     f0100f29 <vprintfmt+0x2c>
f0101308:	89 c3                	mov    %eax,%ebx
f010130a:	eb f0                	jmp    f01012fc <vprintfmt+0x3ff>
				/* do nothing */;
			break;
		}
	}
}
f010130c:	83 c4 5c             	add    $0x5c,%esp
f010130f:	5b                   	pop    %ebx
f0101310:	5e                   	pop    %esi
f0101311:	5f                   	pop    %edi
f0101312:	5d                   	pop    %ebp
f0101313:	c3                   	ret    

f0101314 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101314:	55                   	push   %ebp
f0101315:	89 e5                	mov    %esp,%ebp
f0101317:	83 ec 28             	sub    $0x28,%esp
f010131a:	8b 45 08             	mov    0x8(%ebp),%eax
f010131d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
f0101320:	85 c0                	test   %eax,%eax
f0101322:	74 04                	je     f0101328 <vsnprintf+0x14>
f0101324:	85 d2                	test   %edx,%edx
f0101326:	7f 07                	jg     f010132f <vsnprintf+0x1b>
f0101328:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010132d:	eb 3b                	jmp    f010136a <vsnprintf+0x56>
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};
f010132f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101332:	8d 44 10 ff          	lea    -0x1(%eax,%edx,1),%eax
f0101336:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101339:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101340:	8b 45 14             	mov    0x14(%ebp),%eax
f0101343:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101347:	8b 45 10             	mov    0x10(%ebp),%eax
f010134a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010134e:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101351:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101355:	c7 04 24 e0 0e 10 f0 	movl   $0xf0100ee0,(%esp)
f010135c:	e8 9c fb ff ff       	call   f0100efd <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101361:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101364:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101367:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f010136a:	c9                   	leave  
f010136b:	c3                   	ret    

f010136c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010136c:	55                   	push   %ebp
f010136d:	89 e5                	mov    %esp,%ebp
f010136f:	83 ec 18             	sub    $0x18,%esp

	return b.cnt;
}

int
snprintf(char *buf, int n, const char *fmt, ...)
f0101372:	8d 45 14             	lea    0x14(%ebp),%eax
{
	va_list ap;
	int rc;

	va_start(ap, fmt);
	rc = vsnprintf(buf, n, fmt, ap);
f0101375:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101379:	8b 45 10             	mov    0x10(%ebp),%eax
f010137c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101380:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101383:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101387:	8b 45 08             	mov    0x8(%ebp),%eax
f010138a:	89 04 24             	mov    %eax,(%esp)
f010138d:	e8 82 ff ff ff       	call   f0101314 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101392:	c9                   	leave  
f0101393:	c3                   	ret    

f0101394 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101394:	55                   	push   %ebp
f0101395:	89 e5                	mov    %esp,%ebp
f0101397:	83 ec 18             	sub    $0x18,%esp
		}
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
f010139a:	8d 45 14             	lea    0x14(%ebp),%eax
{
	va_list ap;

	va_start(ap, fmt);
	vprintfmt(putch, putdat, fmt, ap);
f010139d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01013a1:	8b 45 10             	mov    0x10(%ebp),%eax
f01013a4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01013a8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013ab:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013af:	8b 45 08             	mov    0x8(%ebp),%eax
f01013b2:	89 04 24             	mov    %eax,(%esp)
f01013b5:	e8 43 fb ff ff       	call   f0100efd <vprintfmt>
	va_end(ap);
}
f01013ba:	c9                   	leave  
f01013bb:	c3                   	ret    
f01013bc:	00 00                	add    %al,(%eax)
	...

f01013c0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01013c0:	55                   	push   %ebp
f01013c1:	89 e5                	mov    %esp,%ebp
f01013c3:	57                   	push   %edi
f01013c4:	56                   	push   %esi
f01013c5:	53                   	push   %ebx
f01013c6:	83 ec 1c             	sub    $0x1c,%esp
f01013c9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01013cc:	85 c0                	test   %eax,%eax
f01013ce:	74 10                	je     f01013e0 <readline+0x20>
		cprintf("%s", prompt);
f01013d0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013d4:	c7 04 24 c3 20 10 f0 	movl   $0xf01020c3,(%esp)
f01013db:	e8 53 f6 ff ff       	call   f0100a33 <cprintf>

	i = 0;
	echoing = iscons(0);
f01013e0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013e7:	e8 aa ee ff ff       	call   f0100296 <iscons>
f01013ec:	89 c7                	mov    %eax,%edi
f01013ee:	be 00 00 00 00       	mov    $0x0,%esi
	while (1) {
		c = getchar();
f01013f3:	e8 8d ee ff ff       	call   f0100285 <getchar>
f01013f8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01013fa:	85 c0                	test   %eax,%eax
f01013fc:	79 17                	jns    f0101415 <readline+0x55>
			cprintf("read error: %e\n", c);
f01013fe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101402:	c7 04 24 ac 22 10 f0 	movl   $0xf01022ac,(%esp)
f0101409:	e8 25 f6 ff ff       	call   f0100a33 <cprintf>
f010140e:	b8 00 00 00 00       	mov    $0x0,%eax
			return NULL;
f0101413:	eb 76                	jmp    f010148b <readline+0xcb>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101415:	83 f8 08             	cmp    $0x8,%eax
f0101418:	74 08                	je     f0101422 <readline+0x62>
f010141a:	83 f8 7f             	cmp    $0x7f,%eax
f010141d:	8d 76 00             	lea    0x0(%esi),%esi
f0101420:	75 19                	jne    f010143b <readline+0x7b>
f0101422:	85 f6                	test   %esi,%esi
f0101424:	7e 15                	jle    f010143b <readline+0x7b>
			if (echoing)
f0101426:	85 ff                	test   %edi,%edi
f0101428:	74 0c                	je     f0101436 <readline+0x76>
				cputchar('\b');
f010142a:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0101431:	e8 64 f0 ff ff       	call   f010049a <cputchar>
			i--;
f0101436:	83 ee 01             	sub    $0x1,%esi
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101439:	eb b8                	jmp    f01013f3 <readline+0x33>
			if (echoing)
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
f010143b:	83 fb 1f             	cmp    $0x1f,%ebx
f010143e:	66 90                	xchg   %ax,%ax
f0101440:	7e 23                	jle    f0101465 <readline+0xa5>
f0101442:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101448:	7f 1b                	jg     f0101465 <readline+0xa5>
			if (echoing)
f010144a:	85 ff                	test   %edi,%edi
f010144c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101450:	74 08                	je     f010145a <readline+0x9a>
				cputchar(c);
f0101452:	89 1c 24             	mov    %ebx,(%esp)
f0101455:	e8 40 f0 ff ff       	call   f010049a <cputchar>
			buf[i++] = c;
f010145a:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f0101460:	83 c6 01             	add    $0x1,%esi
f0101463:	eb 8e                	jmp    f01013f3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0101465:	83 fb 0a             	cmp    $0xa,%ebx
f0101468:	74 05                	je     f010146f <readline+0xaf>
f010146a:	83 fb 0d             	cmp    $0xd,%ebx
f010146d:	75 84                	jne    f01013f3 <readline+0x33>
			if (echoing)
f010146f:	85 ff                	test   %edi,%edi
f0101471:	74 0c                	je     f010147f <readline+0xbf>
				cputchar('\n');
f0101473:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f010147a:	e8 1b f0 ff ff       	call   f010049a <cputchar>
			buf[i] = 0;
f010147f:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
f0101486:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
			return buf;
		}
	}
}
f010148b:	83 c4 1c             	add    $0x1c,%esp
f010148e:	5b                   	pop    %ebx
f010148f:	5e                   	pop    %esi
f0101490:	5f                   	pop    %edi
f0101491:	5d                   	pop    %ebp
f0101492:	c3                   	ret    
	...

f01014a0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01014a0:	55                   	push   %ebp
f01014a1:	89 e5                	mov    %esp,%ebp
f01014a3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01014a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01014ab:	80 3a 00             	cmpb   $0x0,(%edx)
f01014ae:	74 09                	je     f01014b9 <strlen+0x19>
		n++;
f01014b0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01014b3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01014b7:	75 f7                	jne    f01014b0 <strlen+0x10>
		n++;
	return n;
}
f01014b9:	5d                   	pop    %ebp
f01014ba:	c3                   	ret    

f01014bb <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01014bb:	55                   	push   %ebp
f01014bc:	89 e5                	mov    %esp,%ebp
f01014be:	53                   	push   %ebx
f01014bf:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01014c2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014c5:	85 c9                	test   %ecx,%ecx
f01014c7:	74 19                	je     f01014e2 <strnlen+0x27>
f01014c9:	80 3b 00             	cmpb   $0x0,(%ebx)
f01014cc:	74 14                	je     f01014e2 <strnlen+0x27>
f01014ce:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01014d3:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014d6:	39 c8                	cmp    %ecx,%eax
f01014d8:	74 0d                	je     f01014e7 <strnlen+0x2c>
f01014da:	80 3c 03 00          	cmpb   $0x0,(%ebx,%eax,1)
f01014de:	75 f3                	jne    f01014d3 <strnlen+0x18>
f01014e0:	eb 05                	jmp    f01014e7 <strnlen+0x2c>
f01014e2:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01014e7:	5b                   	pop    %ebx
f01014e8:	5d                   	pop    %ebp
f01014e9:	c3                   	ret    

f01014ea <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01014ea:	55                   	push   %ebp
f01014eb:	89 e5                	mov    %esp,%ebp
f01014ed:	53                   	push   %ebx
f01014ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01014f1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01014f4:	ba 00 00 00 00       	mov    $0x0,%edx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01014f9:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01014fd:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101500:	83 c2 01             	add    $0x1,%edx
f0101503:	84 c9                	test   %cl,%cl
f0101505:	75 f2                	jne    f01014f9 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0101507:	5b                   	pop    %ebx
f0101508:	5d                   	pop    %ebp
f0101509:	c3                   	ret    

f010150a <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010150a:	55                   	push   %ebp
f010150b:	89 e5                	mov    %esp,%ebp
f010150d:	56                   	push   %esi
f010150e:	53                   	push   %ebx
f010150f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101512:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101515:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101518:	85 f6                	test   %esi,%esi
f010151a:	74 18                	je     f0101534 <strncpy+0x2a>
f010151c:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f0101521:	0f b6 1a             	movzbl (%edx),%ebx
f0101524:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101527:	80 3a 01             	cmpb   $0x1,(%edx)
f010152a:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010152d:	83 c1 01             	add    $0x1,%ecx
f0101530:	39 ce                	cmp    %ecx,%esi
f0101532:	77 ed                	ja     f0101521 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101534:	5b                   	pop    %ebx
f0101535:	5e                   	pop    %esi
f0101536:	5d                   	pop    %ebp
f0101537:	c3                   	ret    

f0101538 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101538:	55                   	push   %ebp
f0101539:	89 e5                	mov    %esp,%ebp
f010153b:	56                   	push   %esi
f010153c:	53                   	push   %ebx
f010153d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101540:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101543:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101546:	89 f0                	mov    %esi,%eax
f0101548:	85 c9                	test   %ecx,%ecx
f010154a:	74 27                	je     f0101573 <strlcpy+0x3b>
		while (--size > 0 && *src != '\0')
f010154c:	83 e9 01             	sub    $0x1,%ecx
f010154f:	74 1d                	je     f010156e <strlcpy+0x36>
f0101551:	0f b6 1a             	movzbl (%edx),%ebx
f0101554:	84 db                	test   %bl,%bl
f0101556:	74 16                	je     f010156e <strlcpy+0x36>
			*dst++ = *src++;
f0101558:	88 18                	mov    %bl,(%eax)
f010155a:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010155d:	83 e9 01             	sub    $0x1,%ecx
f0101560:	74 0e                	je     f0101570 <strlcpy+0x38>
			*dst++ = *src++;
f0101562:	83 c2 01             	add    $0x1,%edx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101565:	0f b6 1a             	movzbl (%edx),%ebx
f0101568:	84 db                	test   %bl,%bl
f010156a:	75 ec                	jne    f0101558 <strlcpy+0x20>
f010156c:	eb 02                	jmp    f0101570 <strlcpy+0x38>
f010156e:	89 f0                	mov    %esi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101570:	c6 00 00             	movb   $0x0,(%eax)
f0101573:	29 f0                	sub    %esi,%eax
	}
	return dst - dst_in;
}
f0101575:	5b                   	pop    %ebx
f0101576:	5e                   	pop    %esi
f0101577:	5d                   	pop    %ebp
f0101578:	c3                   	ret    

f0101579 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101579:	55                   	push   %ebp
f010157a:	89 e5                	mov    %esp,%ebp
f010157c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010157f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101582:	0f b6 01             	movzbl (%ecx),%eax
f0101585:	84 c0                	test   %al,%al
f0101587:	74 15                	je     f010159e <strcmp+0x25>
f0101589:	3a 02                	cmp    (%edx),%al
f010158b:	75 11                	jne    f010159e <strcmp+0x25>
		p++, q++;
f010158d:	83 c1 01             	add    $0x1,%ecx
f0101590:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101593:	0f b6 01             	movzbl (%ecx),%eax
f0101596:	84 c0                	test   %al,%al
f0101598:	74 04                	je     f010159e <strcmp+0x25>
f010159a:	3a 02                	cmp    (%edx),%al
f010159c:	74 ef                	je     f010158d <strcmp+0x14>
f010159e:	0f b6 c0             	movzbl %al,%eax
f01015a1:	0f b6 12             	movzbl (%edx),%edx
f01015a4:	29 d0                	sub    %edx,%eax
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01015a6:	5d                   	pop    %ebp
f01015a7:	c3                   	ret    

f01015a8 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01015a8:	55                   	push   %ebp
f01015a9:	89 e5                	mov    %esp,%ebp
f01015ab:	53                   	push   %ebx
f01015ac:	8b 55 08             	mov    0x8(%ebp),%edx
f01015af:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01015b2:	8b 45 10             	mov    0x10(%ebp),%eax
	while (n > 0 && *p && *p == *q)
f01015b5:	85 c0                	test   %eax,%eax
f01015b7:	74 23                	je     f01015dc <strncmp+0x34>
f01015b9:	0f b6 1a             	movzbl (%edx),%ebx
f01015bc:	84 db                	test   %bl,%bl
f01015be:	74 24                	je     f01015e4 <strncmp+0x3c>
f01015c0:	3a 19                	cmp    (%ecx),%bl
f01015c2:	75 20                	jne    f01015e4 <strncmp+0x3c>
f01015c4:	83 e8 01             	sub    $0x1,%eax
f01015c7:	74 13                	je     f01015dc <strncmp+0x34>
		n--, p++, q++;
f01015c9:	83 c2 01             	add    $0x1,%edx
f01015cc:	83 c1 01             	add    $0x1,%ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01015cf:	0f b6 1a             	movzbl (%edx),%ebx
f01015d2:	84 db                	test   %bl,%bl
f01015d4:	74 0e                	je     f01015e4 <strncmp+0x3c>
f01015d6:	3a 19                	cmp    (%ecx),%bl
f01015d8:	74 ea                	je     f01015c4 <strncmp+0x1c>
f01015da:	eb 08                	jmp    f01015e4 <strncmp+0x3c>
f01015dc:	b8 00 00 00 00       	mov    $0x0,%eax
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01015e1:	5b                   	pop    %ebx
f01015e2:	5d                   	pop    %ebp
f01015e3:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01015e4:	0f b6 02             	movzbl (%edx),%eax
f01015e7:	0f b6 11             	movzbl (%ecx),%edx
f01015ea:	29 d0                	sub    %edx,%eax
f01015ec:	eb f3                	jmp    f01015e1 <strncmp+0x39>

f01015ee <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01015ee:	55                   	push   %ebp
f01015ef:	89 e5                	mov    %esp,%ebp
f01015f1:	8b 45 08             	mov    0x8(%ebp),%eax
f01015f4:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015f8:	0f b6 10             	movzbl (%eax),%edx
f01015fb:	84 d2                	test   %dl,%dl
f01015fd:	74 15                	je     f0101614 <strchr+0x26>
		if (*s == c)
f01015ff:	38 ca                	cmp    %cl,%dl
f0101601:	75 07                	jne    f010160a <strchr+0x1c>
f0101603:	eb 14                	jmp    f0101619 <strchr+0x2b>
f0101605:	38 ca                	cmp    %cl,%dl
f0101607:	90                   	nop
f0101608:	74 0f                	je     f0101619 <strchr+0x2b>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010160a:	83 c0 01             	add    $0x1,%eax
f010160d:	0f b6 10             	movzbl (%eax),%edx
f0101610:	84 d2                	test   %dl,%dl
f0101612:	75 f1                	jne    f0101605 <strchr+0x17>
f0101614:	b8 00 00 00 00       	mov    $0x0,%eax
		if (*s == c)
			return (char *) s;
	return 0;
}
f0101619:	5d                   	pop    %ebp
f010161a:	c3                   	ret    

f010161b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010161b:	55                   	push   %ebp
f010161c:	89 e5                	mov    %esp,%ebp
f010161e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101621:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101625:	0f b6 10             	movzbl (%eax),%edx
f0101628:	84 d2                	test   %dl,%dl
f010162a:	74 18                	je     f0101644 <strfind+0x29>
		if (*s == c)
f010162c:	38 ca                	cmp    %cl,%dl
f010162e:	75 0a                	jne    f010163a <strfind+0x1f>
f0101630:	eb 12                	jmp    f0101644 <strfind+0x29>
f0101632:	38 ca                	cmp    %cl,%dl
f0101634:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101638:	74 0a                	je     f0101644 <strfind+0x29>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010163a:	83 c0 01             	add    $0x1,%eax
f010163d:	0f b6 10             	movzbl (%eax),%edx
f0101640:	84 d2                	test   %dl,%dl
f0101642:	75 ee                	jne    f0101632 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0101644:	5d                   	pop    %ebp
f0101645:	c3                   	ret    

f0101646 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101646:	55                   	push   %ebp
f0101647:	89 e5                	mov    %esp,%ebp
f0101649:	83 ec 0c             	sub    $0xc,%esp
f010164c:	89 1c 24             	mov    %ebx,(%esp)
f010164f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101653:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101657:	8b 7d 08             	mov    0x8(%ebp),%edi
f010165a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010165d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101660:	85 c9                	test   %ecx,%ecx
f0101662:	74 30                	je     f0101694 <memset+0x4e>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101664:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010166a:	75 25                	jne    f0101691 <memset+0x4b>
f010166c:	f6 c1 03             	test   $0x3,%cl
f010166f:	75 20                	jne    f0101691 <memset+0x4b>
		c &= 0xFF;
f0101671:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101674:	89 d3                	mov    %edx,%ebx
f0101676:	c1 e3 08             	shl    $0x8,%ebx
f0101679:	89 d6                	mov    %edx,%esi
f010167b:	c1 e6 18             	shl    $0x18,%esi
f010167e:	89 d0                	mov    %edx,%eax
f0101680:	c1 e0 10             	shl    $0x10,%eax
f0101683:	09 f0                	or     %esi,%eax
f0101685:	09 d0                	or     %edx,%eax
		asm volatile("cld; rep stosl\n"
f0101687:	09 d8                	or     %ebx,%eax
f0101689:	c1 e9 02             	shr    $0x2,%ecx
f010168c:	fc                   	cld    
f010168d:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010168f:	eb 03                	jmp    f0101694 <memset+0x4e>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101691:	fc                   	cld    
f0101692:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101694:	89 f8                	mov    %edi,%eax
f0101696:	8b 1c 24             	mov    (%esp),%ebx
f0101699:	8b 74 24 04          	mov    0x4(%esp),%esi
f010169d:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01016a1:	89 ec                	mov    %ebp,%esp
f01016a3:	5d                   	pop    %ebp
f01016a4:	c3                   	ret    

f01016a5 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01016a5:	55                   	push   %ebp
f01016a6:	89 e5                	mov    %esp,%ebp
f01016a8:	83 ec 08             	sub    $0x8,%esp
f01016ab:	89 34 24             	mov    %esi,(%esp)
f01016ae:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01016b2:	8b 45 08             	mov    0x8(%ebp),%eax
f01016b5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
f01016b8:	8b 75 0c             	mov    0xc(%ebp),%esi
	d = dst;
f01016bb:	89 c7                	mov    %eax,%edi
	if (s < d && s + n > d) {
f01016bd:	39 c6                	cmp    %eax,%esi
f01016bf:	73 35                	jae    f01016f6 <memmove+0x51>
f01016c1:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01016c4:	39 d0                	cmp    %edx,%eax
f01016c6:	73 2e                	jae    f01016f6 <memmove+0x51>
		s += n;
		d += n;
f01016c8:	01 cf                	add    %ecx,%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016ca:	f6 c2 03             	test   $0x3,%dl
f01016cd:	75 1b                	jne    f01016ea <memmove+0x45>
f01016cf:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01016d5:	75 13                	jne    f01016ea <memmove+0x45>
f01016d7:	f6 c1 03             	test   $0x3,%cl
f01016da:	75 0e                	jne    f01016ea <memmove+0x45>
			asm volatile("std; rep movsl\n"
f01016dc:	83 ef 04             	sub    $0x4,%edi
f01016df:	8d 72 fc             	lea    -0x4(%edx),%esi
f01016e2:	c1 e9 02             	shr    $0x2,%ecx
f01016e5:	fd                   	std    
f01016e6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016e8:	eb 09                	jmp    f01016f3 <memmove+0x4e>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01016ea:	83 ef 01             	sub    $0x1,%edi
f01016ed:	8d 72 ff             	lea    -0x1(%edx),%esi
f01016f0:	fd                   	std    
f01016f1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01016f3:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01016f4:	eb 20                	jmp    f0101716 <memmove+0x71>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016f6:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01016fc:	75 15                	jne    f0101713 <memmove+0x6e>
f01016fe:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101704:	75 0d                	jne    f0101713 <memmove+0x6e>
f0101706:	f6 c1 03             	test   $0x3,%cl
f0101709:	75 08                	jne    f0101713 <memmove+0x6e>
			asm volatile("cld; rep movsl\n"
f010170b:	c1 e9 02             	shr    $0x2,%ecx
f010170e:	fc                   	cld    
f010170f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101711:	eb 03                	jmp    f0101716 <memmove+0x71>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101713:	fc                   	cld    
f0101714:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101716:	8b 34 24             	mov    (%esp),%esi
f0101719:	8b 7c 24 04          	mov    0x4(%esp),%edi
f010171d:	89 ec                	mov    %ebp,%esp
f010171f:	5d                   	pop    %ebp
f0101720:	c3                   	ret    

f0101721 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0101721:	55                   	push   %ebp
f0101722:	89 e5                	mov    %esp,%ebp
f0101724:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101727:	8b 45 10             	mov    0x10(%ebp),%eax
f010172a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010172e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101731:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101735:	8b 45 08             	mov    0x8(%ebp),%eax
f0101738:	89 04 24             	mov    %eax,(%esp)
f010173b:	e8 65 ff ff ff       	call   f01016a5 <memmove>
}
f0101740:	c9                   	leave  
f0101741:	c3                   	ret    

f0101742 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101742:	55                   	push   %ebp
f0101743:	89 e5                	mov    %esp,%ebp
f0101745:	57                   	push   %edi
f0101746:	56                   	push   %esi
f0101747:	53                   	push   %ebx
f0101748:	8b 75 08             	mov    0x8(%ebp),%esi
f010174b:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010174e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101751:	85 c9                	test   %ecx,%ecx
f0101753:	74 36                	je     f010178b <memcmp+0x49>
		if (*s1 != *s2)
f0101755:	0f b6 06             	movzbl (%esi),%eax
f0101758:	0f b6 1f             	movzbl (%edi),%ebx
f010175b:	38 d8                	cmp    %bl,%al
f010175d:	74 20                	je     f010177f <memcmp+0x3d>
f010175f:	eb 14                	jmp    f0101775 <memcmp+0x33>
f0101761:	0f b6 44 16 01       	movzbl 0x1(%esi,%edx,1),%eax
f0101766:	0f b6 5c 17 01       	movzbl 0x1(%edi,%edx,1),%ebx
f010176b:	83 c2 01             	add    $0x1,%edx
f010176e:	83 e9 01             	sub    $0x1,%ecx
f0101771:	38 d8                	cmp    %bl,%al
f0101773:	74 12                	je     f0101787 <memcmp+0x45>
			return (int) *s1 - (int) *s2;
f0101775:	0f b6 c0             	movzbl %al,%eax
f0101778:	0f b6 db             	movzbl %bl,%ebx
f010177b:	29 d8                	sub    %ebx,%eax
f010177d:	eb 11                	jmp    f0101790 <memcmp+0x4e>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010177f:	83 e9 01             	sub    $0x1,%ecx
f0101782:	ba 00 00 00 00       	mov    $0x0,%edx
f0101787:	85 c9                	test   %ecx,%ecx
f0101789:	75 d6                	jne    f0101761 <memcmp+0x1f>
f010178b:	b8 00 00 00 00       	mov    $0x0,%eax
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
}
f0101790:	5b                   	pop    %ebx
f0101791:	5e                   	pop    %esi
f0101792:	5f                   	pop    %edi
f0101793:	5d                   	pop    %ebp
f0101794:	c3                   	ret    

f0101795 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101795:	55                   	push   %ebp
f0101796:	89 e5                	mov    %esp,%ebp
f0101798:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010179b:	89 c2                	mov    %eax,%edx
f010179d:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01017a0:	39 d0                	cmp    %edx,%eax
f01017a2:	73 15                	jae    f01017b9 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f01017a4:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f01017a8:	38 08                	cmp    %cl,(%eax)
f01017aa:	75 06                	jne    f01017b2 <memfind+0x1d>
f01017ac:	eb 0b                	jmp    f01017b9 <memfind+0x24>
f01017ae:	38 08                	cmp    %cl,(%eax)
f01017b0:	74 07                	je     f01017b9 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01017b2:	83 c0 01             	add    $0x1,%eax
f01017b5:	39 c2                	cmp    %eax,%edx
f01017b7:	77 f5                	ja     f01017ae <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01017b9:	5d                   	pop    %ebp
f01017ba:	c3                   	ret    

f01017bb <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01017bb:	55                   	push   %ebp
f01017bc:	89 e5                	mov    %esp,%ebp
f01017be:	57                   	push   %edi
f01017bf:	56                   	push   %esi
f01017c0:	53                   	push   %ebx
f01017c1:	83 ec 04             	sub    $0x4,%esp
f01017c4:	8b 55 08             	mov    0x8(%ebp),%edx
f01017c7:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01017ca:	0f b6 02             	movzbl (%edx),%eax
f01017cd:	3c 20                	cmp    $0x20,%al
f01017cf:	74 04                	je     f01017d5 <strtol+0x1a>
f01017d1:	3c 09                	cmp    $0x9,%al
f01017d3:	75 0e                	jne    f01017e3 <strtol+0x28>
		s++;
f01017d5:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01017d8:	0f b6 02             	movzbl (%edx),%eax
f01017db:	3c 20                	cmp    $0x20,%al
f01017dd:	74 f6                	je     f01017d5 <strtol+0x1a>
f01017df:	3c 09                	cmp    $0x9,%al
f01017e1:	74 f2                	je     f01017d5 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f01017e3:	3c 2b                	cmp    $0x2b,%al
f01017e5:	75 0c                	jne    f01017f3 <strtol+0x38>
		s++;
f01017e7:	83 c2 01             	add    $0x1,%edx
f01017ea:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f01017f1:	eb 15                	jmp    f0101808 <strtol+0x4d>
	else if (*s == '-')
f01017f3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f01017fa:	3c 2d                	cmp    $0x2d,%al
f01017fc:	75 0a                	jne    f0101808 <strtol+0x4d>
		s++, neg = 1;
f01017fe:	83 c2 01             	add    $0x1,%edx
f0101801:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101808:	85 db                	test   %ebx,%ebx
f010180a:	0f 94 c0             	sete   %al
f010180d:	74 05                	je     f0101814 <strtol+0x59>
f010180f:	83 fb 10             	cmp    $0x10,%ebx
f0101812:	75 18                	jne    f010182c <strtol+0x71>
f0101814:	80 3a 30             	cmpb   $0x30,(%edx)
f0101817:	75 13                	jne    f010182c <strtol+0x71>
f0101819:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010181d:	8d 76 00             	lea    0x0(%esi),%esi
f0101820:	75 0a                	jne    f010182c <strtol+0x71>
		s += 2, base = 16;
f0101822:	83 c2 02             	add    $0x2,%edx
f0101825:	bb 10 00 00 00       	mov    $0x10,%ebx
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010182a:	eb 15                	jmp    f0101841 <strtol+0x86>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010182c:	84 c0                	test   %al,%al
f010182e:	66 90                	xchg   %ax,%ax
f0101830:	74 0f                	je     f0101841 <strtol+0x86>
f0101832:	bb 0a 00 00 00       	mov    $0xa,%ebx
f0101837:	80 3a 30             	cmpb   $0x30,(%edx)
f010183a:	75 05                	jne    f0101841 <strtol+0x86>
		s++, base = 8;
f010183c:	83 c2 01             	add    $0x1,%edx
f010183f:	b3 08                	mov    $0x8,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101841:	b8 00 00 00 00       	mov    $0x0,%eax
f0101846:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101848:	0f b6 0a             	movzbl (%edx),%ecx
f010184b:	89 cf                	mov    %ecx,%edi
f010184d:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101850:	80 fb 09             	cmp    $0x9,%bl
f0101853:	77 08                	ja     f010185d <strtol+0xa2>
			dig = *s - '0';
f0101855:	0f be c9             	movsbl %cl,%ecx
f0101858:	83 e9 30             	sub    $0x30,%ecx
f010185b:	eb 1e                	jmp    f010187b <strtol+0xc0>
		else if (*s >= 'a' && *s <= 'z')
f010185d:	8d 5f 9f             	lea    -0x61(%edi),%ebx
f0101860:	80 fb 19             	cmp    $0x19,%bl
f0101863:	77 08                	ja     f010186d <strtol+0xb2>
			dig = *s - 'a' + 10;
f0101865:	0f be c9             	movsbl %cl,%ecx
f0101868:	83 e9 57             	sub    $0x57,%ecx
f010186b:	eb 0e                	jmp    f010187b <strtol+0xc0>
		else if (*s >= 'A' && *s <= 'Z')
f010186d:	8d 5f bf             	lea    -0x41(%edi),%ebx
f0101870:	80 fb 19             	cmp    $0x19,%bl
f0101873:	77 15                	ja     f010188a <strtol+0xcf>
			dig = *s - 'A' + 10;
f0101875:	0f be c9             	movsbl %cl,%ecx
f0101878:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f010187b:	39 f1                	cmp    %esi,%ecx
f010187d:	7d 0b                	jge    f010188a <strtol+0xcf>
			break;
		s++, val = (val * base) + dig;
f010187f:	83 c2 01             	add    $0x1,%edx
f0101882:	0f af c6             	imul   %esi,%eax
f0101885:	8d 04 01             	lea    (%ecx,%eax,1),%eax
		// we don't properly detect overflow!
	}
f0101888:	eb be                	jmp    f0101848 <strtol+0x8d>
f010188a:	89 c1                	mov    %eax,%ecx

	if (endptr)
f010188c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101890:	74 05                	je     f0101897 <strtol+0xdc>
		*endptr = (char *) s;
f0101892:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101895:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101897:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f010189b:	74 04                	je     f01018a1 <strtol+0xe6>
f010189d:	89 c8                	mov    %ecx,%eax
f010189f:	f7 d8                	neg    %eax
}
f01018a1:	83 c4 04             	add    $0x4,%esp
f01018a4:	5b                   	pop    %ebx
f01018a5:	5e                   	pop    %esi
f01018a6:	5f                   	pop    %edi
f01018a7:	5d                   	pop    %ebp
f01018a8:	c3                   	ret    
f01018a9:	00 00                	add    %al,(%eax)
f01018ab:	00 00                	add    %al,(%eax)
f01018ad:	00 00                	add    %al,(%eax)
	...

f01018b0 <__udivdi3>:
f01018b0:	55                   	push   %ebp
f01018b1:	89 e5                	mov    %esp,%ebp
f01018b3:	57                   	push   %edi
f01018b4:	56                   	push   %esi
f01018b5:	83 ec 10             	sub    $0x10,%esp
f01018b8:	8b 45 14             	mov    0x14(%ebp),%eax
f01018bb:	8b 55 08             	mov    0x8(%ebp),%edx
f01018be:	8b 75 10             	mov    0x10(%ebp),%esi
f01018c1:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01018c4:	85 c0                	test   %eax,%eax
f01018c6:	89 55 f0             	mov    %edx,-0x10(%ebp)
f01018c9:	75 35                	jne    f0101900 <__udivdi3+0x50>
f01018cb:	39 fe                	cmp    %edi,%esi
f01018cd:	77 61                	ja     f0101930 <__udivdi3+0x80>
f01018cf:	85 f6                	test   %esi,%esi
f01018d1:	75 0b                	jne    f01018de <__udivdi3+0x2e>
f01018d3:	b8 01 00 00 00       	mov    $0x1,%eax
f01018d8:	31 d2                	xor    %edx,%edx
f01018da:	f7 f6                	div    %esi
f01018dc:	89 c6                	mov    %eax,%esi
f01018de:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f01018e1:	31 d2                	xor    %edx,%edx
f01018e3:	89 f8                	mov    %edi,%eax
f01018e5:	f7 f6                	div    %esi
f01018e7:	89 c7                	mov    %eax,%edi
f01018e9:	89 c8                	mov    %ecx,%eax
f01018eb:	f7 f6                	div    %esi
f01018ed:	89 c1                	mov    %eax,%ecx
f01018ef:	89 fa                	mov    %edi,%edx
f01018f1:	89 c8                	mov    %ecx,%eax
f01018f3:	83 c4 10             	add    $0x10,%esp
f01018f6:	5e                   	pop    %esi
f01018f7:	5f                   	pop    %edi
f01018f8:	5d                   	pop    %ebp
f01018f9:	c3                   	ret    
f01018fa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101900:	39 f8                	cmp    %edi,%eax
f0101902:	77 1c                	ja     f0101920 <__udivdi3+0x70>
f0101904:	0f bd d0             	bsr    %eax,%edx
f0101907:	83 f2 1f             	xor    $0x1f,%edx
f010190a:	89 55 f4             	mov    %edx,-0xc(%ebp)
f010190d:	75 39                	jne    f0101948 <__udivdi3+0x98>
f010190f:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0101912:	0f 86 a0 00 00 00    	jbe    f01019b8 <__udivdi3+0x108>
f0101918:	39 f8                	cmp    %edi,%eax
f010191a:	0f 82 98 00 00 00    	jb     f01019b8 <__udivdi3+0x108>
f0101920:	31 ff                	xor    %edi,%edi
f0101922:	31 c9                	xor    %ecx,%ecx
f0101924:	89 c8                	mov    %ecx,%eax
f0101926:	89 fa                	mov    %edi,%edx
f0101928:	83 c4 10             	add    $0x10,%esp
f010192b:	5e                   	pop    %esi
f010192c:	5f                   	pop    %edi
f010192d:	5d                   	pop    %ebp
f010192e:	c3                   	ret    
f010192f:	90                   	nop
f0101930:	89 d1                	mov    %edx,%ecx
f0101932:	89 fa                	mov    %edi,%edx
f0101934:	89 c8                	mov    %ecx,%eax
f0101936:	31 ff                	xor    %edi,%edi
f0101938:	f7 f6                	div    %esi
f010193a:	89 c1                	mov    %eax,%ecx
f010193c:	89 fa                	mov    %edi,%edx
f010193e:	89 c8                	mov    %ecx,%eax
f0101940:	83 c4 10             	add    $0x10,%esp
f0101943:	5e                   	pop    %esi
f0101944:	5f                   	pop    %edi
f0101945:	5d                   	pop    %ebp
f0101946:	c3                   	ret    
f0101947:	90                   	nop
f0101948:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f010194c:	89 f2                	mov    %esi,%edx
f010194e:	d3 e0                	shl    %cl,%eax
f0101950:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101953:	b8 20 00 00 00       	mov    $0x20,%eax
f0101958:	2b 45 f4             	sub    -0xc(%ebp),%eax
f010195b:	89 c1                	mov    %eax,%ecx
f010195d:	d3 ea                	shr    %cl,%edx
f010195f:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f0101963:	0b 55 ec             	or     -0x14(%ebp),%edx
f0101966:	d3 e6                	shl    %cl,%esi
f0101968:	89 c1                	mov    %eax,%ecx
f010196a:	89 75 e8             	mov    %esi,-0x18(%ebp)
f010196d:	89 fe                	mov    %edi,%esi
f010196f:	d3 ee                	shr    %cl,%esi
f0101971:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f0101975:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101978:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010197b:	d3 e7                	shl    %cl,%edi
f010197d:	89 c1                	mov    %eax,%ecx
f010197f:	d3 ea                	shr    %cl,%edx
f0101981:	09 d7                	or     %edx,%edi
f0101983:	89 f2                	mov    %esi,%edx
f0101985:	89 f8                	mov    %edi,%eax
f0101987:	f7 75 ec             	divl   -0x14(%ebp)
f010198a:	89 d6                	mov    %edx,%esi
f010198c:	89 c7                	mov    %eax,%edi
f010198e:	f7 65 e8             	mull   -0x18(%ebp)
f0101991:	39 d6                	cmp    %edx,%esi
f0101993:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101996:	72 30                	jb     f01019c8 <__udivdi3+0x118>
f0101998:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010199b:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f010199f:	d3 e2                	shl    %cl,%edx
f01019a1:	39 c2                	cmp    %eax,%edx
f01019a3:	73 05                	jae    f01019aa <__udivdi3+0xfa>
f01019a5:	3b 75 ec             	cmp    -0x14(%ebp),%esi
f01019a8:	74 1e                	je     f01019c8 <__udivdi3+0x118>
f01019aa:	89 f9                	mov    %edi,%ecx
f01019ac:	31 ff                	xor    %edi,%edi
f01019ae:	e9 71 ff ff ff       	jmp    f0101924 <__udivdi3+0x74>
f01019b3:	90                   	nop
f01019b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019b8:	31 ff                	xor    %edi,%edi
f01019ba:	b9 01 00 00 00       	mov    $0x1,%ecx
f01019bf:	e9 60 ff ff ff       	jmp    f0101924 <__udivdi3+0x74>
f01019c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019c8:	8d 4f ff             	lea    -0x1(%edi),%ecx
f01019cb:	31 ff                	xor    %edi,%edi
f01019cd:	89 c8                	mov    %ecx,%eax
f01019cf:	89 fa                	mov    %edi,%edx
f01019d1:	83 c4 10             	add    $0x10,%esp
f01019d4:	5e                   	pop    %esi
f01019d5:	5f                   	pop    %edi
f01019d6:	5d                   	pop    %ebp
f01019d7:	c3                   	ret    
	...

f01019e0 <__umoddi3>:
f01019e0:	55                   	push   %ebp
f01019e1:	89 e5                	mov    %esp,%ebp
f01019e3:	57                   	push   %edi
f01019e4:	56                   	push   %esi
f01019e5:	83 ec 20             	sub    $0x20,%esp
f01019e8:	8b 55 14             	mov    0x14(%ebp),%edx
f01019eb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01019ee:	8b 7d 10             	mov    0x10(%ebp),%edi
f01019f1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01019f4:	85 d2                	test   %edx,%edx
f01019f6:	89 c8                	mov    %ecx,%eax
f01019f8:	89 4d f4             	mov    %ecx,-0xc(%ebp)
f01019fb:	75 13                	jne    f0101a10 <__umoddi3+0x30>
f01019fd:	39 f7                	cmp    %esi,%edi
f01019ff:	76 3f                	jbe    f0101a40 <__umoddi3+0x60>
f0101a01:	89 f2                	mov    %esi,%edx
f0101a03:	f7 f7                	div    %edi
f0101a05:	89 d0                	mov    %edx,%eax
f0101a07:	31 d2                	xor    %edx,%edx
f0101a09:	83 c4 20             	add    $0x20,%esp
f0101a0c:	5e                   	pop    %esi
f0101a0d:	5f                   	pop    %edi
f0101a0e:	5d                   	pop    %ebp
f0101a0f:	c3                   	ret    
f0101a10:	39 f2                	cmp    %esi,%edx
f0101a12:	77 4c                	ja     f0101a60 <__umoddi3+0x80>
f0101a14:	0f bd ca             	bsr    %edx,%ecx
f0101a17:	83 f1 1f             	xor    $0x1f,%ecx
f0101a1a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101a1d:	75 51                	jne    f0101a70 <__umoddi3+0x90>
f0101a1f:	3b 7d f4             	cmp    -0xc(%ebp),%edi
f0101a22:	0f 87 e0 00 00 00    	ja     f0101b08 <__umoddi3+0x128>
f0101a28:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101a2b:	29 f8                	sub    %edi,%eax
f0101a2d:	19 d6                	sbb    %edx,%esi
f0101a2f:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101a32:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101a35:	89 f2                	mov    %esi,%edx
f0101a37:	83 c4 20             	add    $0x20,%esp
f0101a3a:	5e                   	pop    %esi
f0101a3b:	5f                   	pop    %edi
f0101a3c:	5d                   	pop    %ebp
f0101a3d:	c3                   	ret    
f0101a3e:	66 90                	xchg   %ax,%ax
f0101a40:	85 ff                	test   %edi,%edi
f0101a42:	75 0b                	jne    f0101a4f <__umoddi3+0x6f>
f0101a44:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a49:	31 d2                	xor    %edx,%edx
f0101a4b:	f7 f7                	div    %edi
f0101a4d:	89 c7                	mov    %eax,%edi
f0101a4f:	89 f0                	mov    %esi,%eax
f0101a51:	31 d2                	xor    %edx,%edx
f0101a53:	f7 f7                	div    %edi
f0101a55:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101a58:	f7 f7                	div    %edi
f0101a5a:	eb a9                	jmp    f0101a05 <__umoddi3+0x25>
f0101a5c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a60:	89 c8                	mov    %ecx,%eax
f0101a62:	89 f2                	mov    %esi,%edx
f0101a64:	83 c4 20             	add    $0x20,%esp
f0101a67:	5e                   	pop    %esi
f0101a68:	5f                   	pop    %edi
f0101a69:	5d                   	pop    %ebp
f0101a6a:	c3                   	ret    
f0101a6b:	90                   	nop
f0101a6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a70:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101a74:	d3 e2                	shl    %cl,%edx
f0101a76:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0101a79:	ba 20 00 00 00       	mov    $0x20,%edx
f0101a7e:	2b 55 f0             	sub    -0x10(%ebp),%edx
f0101a81:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101a84:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101a88:	89 fa                	mov    %edi,%edx
f0101a8a:	d3 ea                	shr    %cl,%edx
f0101a8c:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101a90:	0b 55 f4             	or     -0xc(%ebp),%edx
f0101a93:	d3 e7                	shl    %cl,%edi
f0101a95:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101a99:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0101a9c:	89 f2                	mov    %esi,%edx
f0101a9e:	89 7d e8             	mov    %edi,-0x18(%ebp)
f0101aa1:	89 c7                	mov    %eax,%edi
f0101aa3:	d3 ea                	shr    %cl,%edx
f0101aa5:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101aa9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101aac:	89 c2                	mov    %eax,%edx
f0101aae:	d3 e6                	shl    %cl,%esi
f0101ab0:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101ab4:	d3 ea                	shr    %cl,%edx
f0101ab6:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101aba:	09 d6                	or     %edx,%esi
f0101abc:	89 f0                	mov    %esi,%eax
f0101abe:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101ac1:	d3 e7                	shl    %cl,%edi
f0101ac3:	89 f2                	mov    %esi,%edx
f0101ac5:	f7 75 f4             	divl   -0xc(%ebp)
f0101ac8:	89 d6                	mov    %edx,%esi
f0101aca:	f7 65 e8             	mull   -0x18(%ebp)
f0101acd:	39 d6                	cmp    %edx,%esi
f0101acf:	72 2b                	jb     f0101afc <__umoddi3+0x11c>
f0101ad1:	39 c7                	cmp    %eax,%edi
f0101ad3:	72 23                	jb     f0101af8 <__umoddi3+0x118>
f0101ad5:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101ad9:	29 c7                	sub    %eax,%edi
f0101adb:	19 d6                	sbb    %edx,%esi
f0101add:	89 f0                	mov    %esi,%eax
f0101adf:	89 f2                	mov    %esi,%edx
f0101ae1:	d3 ef                	shr    %cl,%edi
f0101ae3:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101ae7:	d3 e0                	shl    %cl,%eax
f0101ae9:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101aed:	09 f8                	or     %edi,%eax
f0101aef:	d3 ea                	shr    %cl,%edx
f0101af1:	83 c4 20             	add    $0x20,%esp
f0101af4:	5e                   	pop    %esi
f0101af5:	5f                   	pop    %edi
f0101af6:	5d                   	pop    %ebp
f0101af7:	c3                   	ret    
f0101af8:	39 d6                	cmp    %edx,%esi
f0101afa:	75 d9                	jne    f0101ad5 <__umoddi3+0xf5>
f0101afc:	2b 45 e8             	sub    -0x18(%ebp),%eax
f0101aff:	1b 55 f4             	sbb    -0xc(%ebp),%edx
f0101b02:	eb d1                	jmp    f0101ad5 <__umoddi3+0xf5>
f0101b04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101b08:	39 f2                	cmp    %esi,%edx
f0101b0a:	0f 82 18 ff ff ff    	jb     f0101a28 <__umoddi3+0x48>
f0101b10:	e9 1d ff ff ff       	jmp    f0101a32 <__umoddi3+0x52>
