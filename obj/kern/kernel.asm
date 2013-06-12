
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
f0100058:	c7 04 24 00 1b 10 f0 	movl   $0xf0101b00,(%esp)
f010005f:	e8 a7 09 00 00       	call   f0100a0b <cprintf>
	vcprintf(fmt, ap);
f0100064:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100068:	8b 45 10             	mov    0x10(%ebp),%eax
f010006b:	89 04 24             	mov    %eax,(%esp)
f010006e:	e8 65 09 00 00       	call   f01009d8 <vcprintf>
	cprintf("\n");
f0100073:	c7 04 24 ab 1b 10 f0 	movl   $0xf0101bab,(%esp)
f010007a:	e8 8c 09 00 00       	call   f0100a0b <cprintf>
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
f01000b2:	c7 04 24 1a 1b 10 f0 	movl   $0xf0101b1a,(%esp)
f01000b9:	e8 4d 09 00 00       	call   f0100a0b <cprintf>
	vcprintf(fmt, ap);
f01000be:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000c2:	89 34 24             	mov    %esi,(%esp)
f01000c5:	e8 0e 09 00 00       	call   f01009d8 <vcprintf>
	cprintf("\n");
f01000ca:	c7 04 24 ab 1b 10 f0 	movl   $0xf0101bab,(%esp)
f01000d1:	e8 35 09 00 00       	call   f0100a0b <cprintf>
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
f01000f2:	c7 04 24 32 1b 10 f0 	movl   $0xf0101b32,(%esp)
f01000f9:	e8 0d 09 00 00       	call   f0100a0b <cprintf>
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
f010012f:	c7 04 24 4e 1b 10 f0 	movl   $0xf0101b4e,(%esp)
f0100136:	e8 d0 08 00 00       	call   f0100a0b <cprintf>
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
f0100164:	e8 bd 14 00 00       	call   f0101626 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100169:	e8 3c 03 00 00       	call   f01004aa <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010016e:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100175:	00 
f0100176:	c7 04 24 69 1b 10 f0 	movl   $0xf0101b69,(%esp)
f010017d:	e8 89 08 00 00       	call   f0100a0b <cprintf>

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
f010043a:	e8 46 12 00 00       	call   f0101685 <memmove>
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
f0100586:	c7 04 24 84 1b 10 f0 	movl   $0xf0101b84,(%esp)
f010058d:	e8 79 04 00 00       	call   f0100a0b <cprintf>
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
f01005e1:	0f b6 80 c0 1b 10 f0 	movzbl -0xfefe440(%eax),%eax
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
f010061c:	0f b6 90 c0 1b 10 f0 	movzbl -0xfefe440(%eax),%edx
f0100623:	0b 15 20 23 11 f0    	or     0xf0112320,%edx
f0100629:	0f b6 88 c0 1c 10 f0 	movzbl -0xfefe340(%eax),%ecx
f0100630:	31 ca                	xor    %ecx,%edx
f0100632:	89 15 20 23 11 f0    	mov    %edx,0xf0112320

	c = charcode[shift & (CTL | SHIFT)][data];
f0100638:	89 d1                	mov    %edx,%ecx
f010063a:	83 e1 03             	and    $0x3,%ecx
f010063d:	8b 0c 8d c0 1d 10 f0 	mov    -0xfefe240(,%ecx,4),%ecx
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
f0100676:	c7 04 24 a1 1b 10 f0 	movl   $0xf0101ba1,(%esp)
f010067d:	e8 89 03 00 00       	call   f0100a0b <cprintf>
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
f01006ae:	c7 04 24 d0 1d 10 f0 	movl   $0xf0101dd0,(%esp)
f01006b5:	e8 51 03 00 00       	call   f0100a0b <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006ba:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006c1:	00 
f01006c2:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006c9:	f0 
f01006ca:	c7 04 24 a8 1e 10 f0 	movl   $0xf0101ea8,(%esp)
f01006d1:	e8 35 03 00 00       	call   f0100a0b <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d6:	c7 44 24 08 f5 1a 10 	movl   $0x101af5,0x8(%esp)
f01006dd:	00 
f01006de:	c7 44 24 04 f5 1a 10 	movl   $0xf0101af5,0x4(%esp)
f01006e5:	f0 
f01006e6:	c7 04 24 cc 1e 10 f0 	movl   $0xf0101ecc,(%esp)
f01006ed:	e8 19 03 00 00       	call   f0100a0b <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006f2:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f01006f9:	00 
f01006fa:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f0100701:	f0 
f0100702:	c7 04 24 f0 1e 10 f0 	movl   $0xf0101ef0,(%esp)
f0100709:	e8 fd 02 00 00       	call   f0100a0b <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010070e:	c7 44 24 08 60 29 11 	movl   $0x112960,0x8(%esp)
f0100715:	00 
f0100716:	c7 44 24 04 60 29 11 	movl   $0xf0112960,0x4(%esp)
f010071d:	f0 
f010071e:	c7 04 24 14 1f 10 f0 	movl   $0xf0101f14,(%esp)
f0100725:	e8 e1 02 00 00       	call   f0100a0b <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010072a:	b8 5f 2d 11 f0       	mov    $0xf0112d5f,%eax
f010072f:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100734:	89 c2                	mov    %eax,%edx
f0100736:	c1 fa 1f             	sar    $0x1f,%edx
f0100739:	c1 ea 16             	shr    $0x16,%edx
f010073c:	8d 04 02             	lea    (%edx,%eax,1),%eax
f010073f:	c1 f8 0a             	sar    $0xa,%eax
f0100742:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100746:	c7 04 24 38 1f 10 f0 	movl   $0xf0101f38,(%esp)
f010074d:	e8 b9 02 00 00       	call   f0100a0b <cprintf>
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
f010075f:	a1 24 20 10 f0       	mov    0xf0102024,%eax
f0100764:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100768:	a1 20 20 10 f0       	mov    0xf0102020,%eax
f010076d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100771:	c7 04 24 e9 1d 10 f0 	movl   $0xf0101de9,(%esp)
f0100778:	e8 8e 02 00 00       	call   f0100a0b <cprintf>
f010077d:	a1 30 20 10 f0       	mov    0xf0102030,%eax
f0100782:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100786:	a1 2c 20 10 f0       	mov    0xf010202c,%eax
f010078b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010078f:	c7 04 24 e9 1d 10 f0 	movl   $0xf0101de9,(%esp)
f0100796:	e8 70 02 00 00       	call   f0100a0b <cprintf>
f010079b:	a1 3c 20 10 f0       	mov    0xf010203c,%eax
f01007a0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007a4:	a1 38 20 10 f0       	mov    0xf0102038,%eax
f01007a9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007ad:	c7 04 24 e9 1d 10 f0 	movl   $0xf0101de9,(%esp)
f01007b4:	e8 52 02 00 00       	call   f0100a0b <cprintf>
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
f01007c9:	c7 04 24 64 1f 10 f0 	movl   $0xf0101f64,(%esp)
f01007d0:	e8 36 02 00 00       	call   f0100a0b <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007d5:	c7 04 24 88 1f 10 f0 	movl   $0xf0101f88,(%esp)
f01007dc:	e8 2a 02 00 00       	call   f0100a0b <cprintf>

	while (1) {
		buf = readline("K> ");
f01007e1:	c7 04 24 f2 1d 10 f0 	movl   $0xf0101df2,(%esp)
f01007e8:	e8 b3 0b 00 00       	call   f01013a0 <readline>
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
f0100815:	c7 04 24 f6 1d 10 f0 	movl   $0xf0101df6,(%esp)
f010081c:	e8 ad 0d 00 00       	call   f01015ce <strchr>
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
f010083a:	c7 04 24 fb 1d 10 f0 	movl   $0xf0101dfb,(%esp)
f0100841:	e8 c5 01 00 00       	call   f0100a0b <cprintf>
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
f0100869:	c7 04 24 f6 1d 10 f0 	movl   $0xf0101df6,(%esp)
f0100870:	e8 59 0d 00 00       	call   f01015ce <strchr>
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
f010088b:	bb 20 20 10 f0       	mov    $0xf0102020,%ebx
f0100890:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100895:	8b 03                	mov    (%ebx),%eax
f0100897:	89 44 24 04          	mov    %eax,0x4(%esp)
f010089b:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010089e:	89 04 24             	mov    %eax,(%esp)
f01008a1:	e8 b3 0c 00 00       	call   f0101559 <strcmp>
f01008a6:	85 c0                	test   %eax,%eax
f01008a8:	75 23                	jne    f01008cd <monitor+0x10d>
			return commands[i].func(argc, argv, tf);
f01008aa:	6b ff 0c             	imul   $0xc,%edi,%edi
f01008ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01008b0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008b4:	8d 45 a8             	lea    -0x58(%ebp),%eax
f01008b7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008bb:	89 34 24             	mov    %esi,(%esp)
f01008be:	ff 97 28 20 10 f0    	call   *-0xfefdfd8(%edi)
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
f01008df:	c7 04 24 18 1e 10 f0 	movl   $0xf0101e18,(%esp)
f01008e6:	e8 20 01 00 00       	call   f0100a0b <cprintf>
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
	// Your code here.
	uint32_t *ebp, *eip;
	int i;

	cprintf("Stack backtrace:\n");
f0100901:	c7 04 24 2e 1e 10 f0 	movl   $0xf0101e2e,(%esp)
f0100908:	e8 fe 00 00 00       	call   f0100a0b <cprintf>

	ebp = (uint32_t *)read_ebp();
f010090d:	89 ee                	mov    %ebp,%esi
	while (ebp)
f010090f:	85 f6                	test   %esi,%esi
f0100911:	0f 84 a6 00 00 00    	je     f01009bd <mon_backtrace+0xc5>
	{
		struct Eipdebuginfo info;

		eip = (uint32_t *)*(ebp + 1);
f0100917:	8b 7e 04             	mov    0x4(%esi),%edi
		cprintf("  ebp %08x  eip %08x  args ", ebp, eip);
f010091a:	89 7c 24 08          	mov    %edi,0x8(%esp)
f010091e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100922:	c7 04 24 40 1e 10 f0 	movl   $0xf0101e40,(%esp)
f0100929:	e8 dd 00 00 00       	call   f0100a0b <cprintf>
		for (i = 1; i <= 5; i++)
		{
			cprintf("%08x", *(ebp + 1 + i));
f010092e:	8b 46 08             	mov    0x8(%esi),%eax
f0100931:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100935:	c7 04 24 5c 1e 10 f0 	movl   $0xf0101e5c,(%esp)
f010093c:	e8 ca 00 00 00       	call   f0100a0b <cprintf>
f0100941:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100946:	eb 19                	jmp    f0100961 <mon_backtrace+0x69>
f0100948:	8b 44 9e 04          	mov    0x4(%esi,%ebx,4),%eax
f010094c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100950:	c7 04 24 5c 1e 10 f0 	movl   $0xf0101e5c,(%esp)
f0100957:	e8 af 00 00 00       	call   f0100a0b <cprintf>
			cprintf((i == 5) ? "\n" : " ");
f010095c:	83 fb 05             	cmp    $0x5,%ebx
f010095f:	74 69                	je     f01009ca <mon_backtrace+0xd2>
f0100961:	c7 04 24 f9 1d 10 f0 	movl   $0xf0101df9,(%esp)
f0100968:	e8 9e 00 00 00       	call   f0100a0b <cprintf>
	{
		struct Eipdebuginfo info;

		eip = (uint32_t *)*(ebp + 1);
		cprintf("  ebp %08x  eip %08x  args ", ebp, eip);
		for (i = 1; i <= 5; i++)
f010096d:	83 c3 01             	add    $0x1,%ebx
f0100970:	83 fb 06             	cmp    $0x6,%ebx
f0100973:	75 d3                	jne    f0100948 <mon_backtrace+0x50>
		{
			cprintf("%08x", *(ebp + 1 + i));
			cprintf((i == 5) ? "\n" : " ");
		}
		
		debuginfo_eip((uintptr_t)eip, &info);
f0100975:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100978:	89 44 24 04          	mov    %eax,0x4(%esp)
f010097c:	89 3c 24             	mov    %edi,(%esp)
f010097f:	e8 ea 01 00 00       	call   f0100b6e <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, ((uintptr_t)eip - info.eip_fn_addr));
f0100984:	2b 7d e0             	sub    -0x20(%ebp),%edi
f0100987:	89 7c 24 14          	mov    %edi,0x14(%esp)
f010098b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010098e:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100992:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100995:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100999:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010099c:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009a0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01009a3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009a7:	c7 04 24 61 1e 10 f0 	movl   $0xf0101e61,(%esp)
f01009ae:	e8 58 00 00 00       	call   f0100a0b <cprintf>

		ebp = (uint32_t *)*ebp;
f01009b3:	8b 36                	mov    (%esi),%esi
	int i;

	cprintf("Stack backtrace:\n");

	ebp = (uint32_t *)read_ebp();
	while (ebp)
f01009b5:	85 f6                	test   %esi,%esi
f01009b7:	0f 85 5a ff ff ff    	jne    f0100917 <mon_backtrace+0x1f>

		ebp = (uint32_t *)*ebp;
	}

	return 0;
}
f01009bd:	b8 00 00 00 00       	mov    $0x0,%eax
f01009c2:	83 c4 4c             	add    $0x4c,%esp
f01009c5:	5b                   	pop    %ebx
f01009c6:	5e                   	pop    %esi
f01009c7:	5f                   	pop    %edi
f01009c8:	5d                   	pop    %ebp
f01009c9:	c3                   	ret    
		eip = (uint32_t *)*(ebp + 1);
		cprintf("  ebp %08x  eip %08x  args ", ebp, eip);
		for (i = 1; i <= 5; i++)
		{
			cprintf("%08x", *(ebp + 1 + i));
			cprintf((i == 5) ? "\n" : " ");
f01009ca:	c7 04 24 ab 1b 10 f0 	movl   $0xf0101bab,(%esp)
f01009d1:	e8 35 00 00 00       	call   f0100a0b <cprintf>
f01009d6:	eb 9d                	jmp    f0100975 <mon_backtrace+0x7d>

f01009d8 <vcprintf>:
	*cnt++;
}

int
vcprintf(const char *fmt, va_list ap)
{
f01009d8:	55                   	push   %ebp
f01009d9:	89 e5                	mov    %esp,%ebp
f01009db:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009de:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009e5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009e8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009ec:	8b 45 08             	mov    0x8(%ebp),%eax
f01009ef:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009f3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009f6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009fa:	c7 04 24 25 0a 10 f0 	movl   $0xf0100a25,(%esp)
f0100a01:	e8 d7 04 00 00       	call   f0100edd <vprintfmt>
	return cnt;
}
f0100a06:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a09:	c9                   	leave  
f0100a0a:	c3                   	ret    

f0100a0b <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a0b:	55                   	push   %ebp
f0100a0c:	89 e5                	mov    %esp,%ebp
f0100a0e:	83 ec 18             	sub    $0x18,%esp
	vprintfmt((void*)putch, &cnt, fmt, ap);
	return cnt;
}

int
cprintf(const char *fmt, ...)
f0100a11:	8d 45 0c             	lea    0xc(%ebp),%eax
{
	va_list ap;
	int cnt;

	va_start(ap, fmt);
	cnt = vcprintf(fmt, ap);
f0100a14:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a18:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a1b:	89 04 24             	mov    %eax,(%esp)
f0100a1e:	e8 b5 ff ff ff       	call   f01009d8 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a23:	c9                   	leave  
f0100a24:	c3                   	ret    

f0100a25 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a25:	55                   	push   %ebp
f0100a26:	89 e5                	mov    %esp,%ebp
f0100a28:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100a2b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a2e:	89 04 24             	mov    %eax,(%esp)
f0100a31:	e8 64 fa ff ff       	call   f010049a <cputchar>
	*cnt++;
}
f0100a36:	c9                   	leave  
f0100a37:	c3                   	ret    
	...

f0100a40 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a40:	55                   	push   %ebp
f0100a41:	89 e5                	mov    %esp,%ebp
f0100a43:	57                   	push   %edi
f0100a44:	56                   	push   %esi
f0100a45:	53                   	push   %ebx
f0100a46:	83 ec 14             	sub    $0x14,%esp
f0100a49:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a4c:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a4f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100a52:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a55:	8b 1a                	mov    (%edx),%ebx
f0100a57:	8b 01                	mov    (%ecx),%eax
f0100a59:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	while (l <= r) {
f0100a5c:	39 c3                	cmp    %eax,%ebx
f0100a5e:	0f 8f 9c 00 00 00    	jg     f0100b00 <stab_binsearch+0xc0>
f0100a64:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		int true_m = (l + r) / 2, m = true_m;
f0100a6b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a6e:	01 d8                	add    %ebx,%eax
f0100a70:	89 c7                	mov    %eax,%edi
f0100a72:	c1 ef 1f             	shr    $0x1f,%edi
f0100a75:	01 c7                	add    %eax,%edi
f0100a77:	d1 ff                	sar    %edi
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a79:	39 df                	cmp    %ebx,%edi
f0100a7b:	7c 33                	jl     f0100ab0 <stab_binsearch+0x70>
f0100a7d:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100a80:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100a83:	0f b6 44 82 04       	movzbl 0x4(%edx,%eax,4),%eax
f0100a88:	39 f0                	cmp    %esi,%eax
f0100a8a:	0f 84 bc 00 00 00    	je     f0100b4c <stab_binsearch+0x10c>
f0100a90:	8d 44 7f fd          	lea    -0x3(%edi,%edi,2),%eax
f0100a94:	8d 54 82 04          	lea    0x4(%edx,%eax,4),%edx
f0100a98:	89 f8                	mov    %edi,%eax
			m--;
f0100a9a:	83 e8 01             	sub    $0x1,%eax
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a9d:	39 d8                	cmp    %ebx,%eax
f0100a9f:	7c 0f                	jl     f0100ab0 <stab_binsearch+0x70>
f0100aa1:	0f b6 0a             	movzbl (%edx),%ecx
f0100aa4:	83 ea 0c             	sub    $0xc,%edx
f0100aa7:	39 f1                	cmp    %esi,%ecx
f0100aa9:	75 ef                	jne    f0100a9a <stab_binsearch+0x5a>
f0100aab:	e9 9e 00 00 00       	jmp    f0100b4e <stab_binsearch+0x10e>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100ab0:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0100ab3:	eb 3c                	jmp    f0100af1 <stab_binsearch+0xb1>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100ab5:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100ab8:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
f0100aba:	8d 5f 01             	lea    0x1(%edi),%ebx
f0100abd:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0100ac4:	eb 2b                	jmp    f0100af1 <stab_binsearch+0xb1>
		} else if (stabs[m].n_value > addr) {
f0100ac6:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100ac9:	76 14                	jbe    f0100adf <stab_binsearch+0x9f>
			*region_right = m - 1;
f0100acb:	83 e8 01             	sub    $0x1,%eax
f0100ace:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100ad1:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100ad4:	89 02                	mov    %eax,(%edx)
f0100ad6:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0100add:	eb 12                	jmp    f0100af1 <stab_binsearch+0xb1>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100adf:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100ae2:	89 01                	mov    %eax,(%ecx)
			l = m;
			addr++;
f0100ae4:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100ae8:	89 c3                	mov    %eax,%ebx
f0100aea:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100af1:	39 5d ec             	cmp    %ebx,-0x14(%ebp)
f0100af4:	0f 8d 71 ff ff ff    	jge    f0100a6b <stab_binsearch+0x2b>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100afa:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100afe:	75 0f                	jne    f0100b0f <stab_binsearch+0xcf>
		*region_right = *region_left - 1;
f0100b00:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100b03:	8b 03                	mov    (%ebx),%eax
f0100b05:	83 e8 01             	sub    $0x1,%eax
f0100b08:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100b0b:	89 02                	mov    %eax,(%edx)
f0100b0d:	eb 57                	jmp    f0100b66 <stab_binsearch+0x126>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b0f:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100b12:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b14:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100b17:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b19:	39 c1                	cmp    %eax,%ecx
f0100b1b:	7d 28                	jge    f0100b45 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0100b1d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b20:	8b 5d f0             	mov    -0x10(%ebp),%ebx
f0100b23:	0f b6 54 93 04       	movzbl 0x4(%ebx,%edx,4),%edx
f0100b28:	39 f2                	cmp    %esi,%edx
f0100b2a:	74 19                	je     f0100b45 <stab_binsearch+0x105>
f0100b2c:	8d 54 40 fd          	lea    -0x3(%eax,%eax,2),%edx
f0100b30:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx
		     l--)
f0100b34:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b37:	39 c1                	cmp    %eax,%ecx
f0100b39:	7d 0a                	jge    f0100b45 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0100b3b:	0f b6 1a             	movzbl (%edx),%ebx
f0100b3e:	83 ea 0c             	sub    $0xc,%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b41:	39 f3                	cmp    %esi,%ebx
f0100b43:	75 ef                	jne    f0100b34 <stab_binsearch+0xf4>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
f0100b45:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b48:	89 02                	mov    %eax,(%edx)
f0100b4a:	eb 1a                	jmp    f0100b66 <stab_binsearch+0x126>
	}
}
f0100b4c:	89 f8                	mov    %edi,%eax
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100b4e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b51:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0100b54:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100b58:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100b5b:	0f 82 54 ff ff ff    	jb     f0100ab5 <stab_binsearch+0x75>
f0100b61:	e9 60 ff ff ff       	jmp    f0100ac6 <stab_binsearch+0x86>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0100b66:	83 c4 14             	add    $0x14,%esp
f0100b69:	5b                   	pop    %ebx
f0100b6a:	5e                   	pop    %esi
f0100b6b:	5f                   	pop    %edi
f0100b6c:	5d                   	pop    %ebp
f0100b6d:	c3                   	ret    

f0100b6e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b6e:	55                   	push   %ebp
f0100b6f:	89 e5                	mov    %esp,%ebp
f0100b71:	83 ec 48             	sub    $0x48,%esp
f0100b74:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100b77:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100b7a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100b7d:	8b 75 08             	mov    0x8(%ebp),%esi
f0100b80:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b83:	c7 03 44 20 10 f0    	movl   $0xf0102044,(%ebx)
	info->eip_line = 0;
f0100b89:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b90:	c7 43 08 44 20 10 f0 	movl   $0xf0102044,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b97:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b9e:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100ba1:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ba8:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100bae:	76 12                	jbe    f0100bc2 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bb0:	b8 a1 78 10 f0       	mov    $0xf01078a1,%eax
f0100bb5:	3d 71 5e 10 f0       	cmp    $0xf0105e71,%eax
f0100bba:	0f 86 92 01 00 00    	jbe    f0100d52 <debuginfo_eip+0x1e4>
f0100bc0:	eb 1c                	jmp    f0100bde <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100bc2:	c7 44 24 08 4e 20 10 	movl   $0xf010204e,0x8(%esp)
f0100bc9:	f0 
f0100bca:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100bd1:	00 
f0100bd2:	c7 04 24 5b 20 10 f0 	movl   $0xf010205b,(%esp)
f0100bd9:	e8 a7 f4 ff ff       	call   f0100085 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bde:	80 3d a0 78 10 f0 00 	cmpb   $0x0,0xf01078a0
f0100be5:	0f 85 67 01 00 00    	jne    f0100d52 <debuginfo_eip+0x1e4>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100beb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100bf2:	b8 70 5e 10 f0       	mov    $0xf0105e70,%eax
f0100bf7:	2d 7c 22 10 f0       	sub    $0xf010227c,%eax
f0100bfc:	c1 f8 02             	sar    $0x2,%eax
f0100bff:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100c05:	83 e8 01             	sub    $0x1,%eax
f0100c08:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100c0b:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100c0e:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100c11:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c15:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100c1c:	b8 7c 22 10 f0       	mov    $0xf010227c,%eax
f0100c21:	e8 1a fe ff ff       	call   f0100a40 <stab_binsearch>
	if (lfile == 0)
f0100c26:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c29:	85 c0                	test   %eax,%eax
f0100c2b:	0f 84 21 01 00 00    	je     f0100d52 <debuginfo_eip+0x1e4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c31:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100c34:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c37:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c3a:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c3d:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c40:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c44:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100c4b:	b8 7c 22 10 f0       	mov    $0xf010227c,%eax
f0100c50:	e8 eb fd ff ff       	call   f0100a40 <stab_binsearch>

	if (lfun <= rfun) {
f0100c55:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100c58:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100c5b:	7f 3c                	jg     f0100c99 <debuginfo_eip+0x12b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c5d:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100c60:	8b 80 7c 22 10 f0    	mov    -0xfefdd84(%eax),%eax
f0100c66:	ba a1 78 10 f0       	mov    $0xf01078a1,%edx
f0100c6b:	81 ea 71 5e 10 f0    	sub    $0xf0105e71,%edx
f0100c71:	39 d0                	cmp    %edx,%eax
f0100c73:	73 08                	jae    f0100c7d <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c75:	05 71 5e 10 f0       	add    $0xf0105e71,%eax
f0100c7a:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c7d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100c80:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100c83:	8b 92 84 22 10 f0    	mov    -0xfefdd7c(%edx),%edx
f0100c89:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100c8c:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100c8e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100c91:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100c94:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100c97:	eb 0f                	jmp    f0100ca8 <debuginfo_eip+0x13a>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c99:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c9c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c9f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100ca2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ca5:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100ca8:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100caf:	00 
f0100cb0:	8b 43 08             	mov    0x8(%ebx),%eax
f0100cb3:	89 04 24             	mov    %eax,(%esp)
f0100cb6:	e8 40 09 00 00       	call   f01015fb <strfind>
f0100cbb:	2b 43 08             	sub    0x8(%ebx),%eax
f0100cbe:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100cc1:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100cc4:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100cc7:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ccb:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100cd2:	b8 7c 22 10 f0       	mov    $0xf010227c,%eax
f0100cd7:	e8 64 fd ff ff       	call   f0100a40 <stab_binsearch>
	if (lline <= rline)
f0100cdc:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100cdf:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0100ce2:	7f 6e                	jg     f0100d52 <debuginfo_eip+0x1e4>
		info->eip_line = rline;
f0100ce4:	89 43 04             	mov    %eax,0x4(%ebx)
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
f0100ce7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100cea:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ced:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100cf0:	81 c2 84 22 10 f0    	add    $0xf0102284,%edx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100cf6:	eb 06                	jmp    f0100cfe <debuginfo_eip+0x190>
f0100cf8:	83 e8 01             	sub    $0x1,%eax
f0100cfb:	83 ea 0c             	sub    $0xc,%edx
f0100cfe:	89 c6                	mov    %eax,%esi
f0100d00:	39 f8                	cmp    %edi,%eax
f0100d02:	7c 1d                	jl     f0100d21 <debuginfo_eip+0x1b3>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100d04:	0f b6 4a fc          	movzbl -0x4(%edx),%ecx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d08:	80 f9 84             	cmp    $0x84,%cl
f0100d0b:	74 5e                	je     f0100d6b <debuginfo_eip+0x1fd>
f0100d0d:	80 f9 64             	cmp    $0x64,%cl
f0100d10:	75 e6                	jne    f0100cf8 <debuginfo_eip+0x18a>
f0100d12:	83 3a 00             	cmpl   $0x0,(%edx)
f0100d15:	74 e1                	je     f0100cf8 <debuginfo_eip+0x18a>
f0100d17:	90                   	nop
f0100d18:	eb 51                	jmp    f0100d6b <debuginfo_eip+0x1fd>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100d1a:	05 71 5e 10 f0       	add    $0xf0105e71,%eax
f0100d1f:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d21:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d24:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100d27:	7d 30                	jge    f0100d59 <debuginfo_eip+0x1eb>
		for (lline = lfun + 1;
f0100d29:	83 c0 01             	add    $0x1,%eax
f0100d2c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d2f:	ba 7c 22 10 f0       	mov    $0xf010227c,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d34:	eb 08                	jmp    f0100d3e <debuginfo_eip+0x1d0>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100d36:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100d3a:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)

	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d3e:	8b 45 d4             	mov    -0x2c(%ebp),%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d41:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100d44:	7d 13                	jge    f0100d59 <debuginfo_eip+0x1eb>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d46:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100d49:	80 7c 10 04 a0       	cmpb   $0xa0,0x4(%eax,%edx,1)
f0100d4e:	74 e6                	je     f0100d36 <debuginfo_eip+0x1c8>
f0100d50:	eb 07                	jmp    f0100d59 <debuginfo_eip+0x1eb>
f0100d52:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d57:	eb 05                	jmp    f0100d5e <debuginfo_eip+0x1f0>
f0100d59:	b8 00 00 00 00       	mov    $0x0,%eax
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
}
f0100d5e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100d61:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100d64:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100d67:	89 ec                	mov    %ebp,%esp
f0100d69:	5d                   	pop    %ebp
f0100d6a:	c3                   	ret    
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100d6b:	6b c6 0c             	imul   $0xc,%esi,%eax
f0100d6e:	8b 80 7c 22 10 f0    	mov    -0xfefdd84(%eax),%eax
f0100d74:	ba a1 78 10 f0       	mov    $0xf01078a1,%edx
f0100d79:	81 ea 71 5e 10 f0    	sub    $0xf0105e71,%edx
f0100d7f:	39 d0                	cmp    %edx,%eax
f0100d81:	72 97                	jb     f0100d1a <debuginfo_eip+0x1ac>
f0100d83:	eb 9c                	jmp    f0100d21 <debuginfo_eip+0x1b3>
	...

f0100d90 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d90:	55                   	push   %ebp
f0100d91:	89 e5                	mov    %esp,%ebp
f0100d93:	57                   	push   %edi
f0100d94:	56                   	push   %esi
f0100d95:	53                   	push   %ebx
f0100d96:	83 ec 4c             	sub    $0x4c,%esp
f0100d99:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d9c:	89 d6                	mov    %edx,%esi
f0100d9e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100da1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100da4:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100da7:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100daa:	8b 45 10             	mov    0x10(%ebp),%eax
f0100dad:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100db0:	8b 7d 18             	mov    0x18(%ebp),%edi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100db3:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100db6:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100dbb:	39 d1                	cmp    %edx,%ecx
f0100dbd:	72 15                	jb     f0100dd4 <printnum+0x44>
f0100dbf:	77 07                	ja     f0100dc8 <printnum+0x38>
f0100dc1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100dc4:	39 d0                	cmp    %edx,%eax
f0100dc6:	76 0c                	jbe    f0100dd4 <printnum+0x44>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100dc8:	83 eb 01             	sub    $0x1,%ebx
f0100dcb:	85 db                	test   %ebx,%ebx
f0100dcd:	8d 76 00             	lea    0x0(%esi),%esi
f0100dd0:	7f 61                	jg     f0100e33 <printnum+0xa3>
f0100dd2:	eb 70                	jmp    f0100e44 <printnum+0xb4>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100dd4:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0100dd8:	83 eb 01             	sub    $0x1,%ebx
f0100ddb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100ddf:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100de3:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0100de7:	8b 5c 24 0c          	mov    0xc(%esp),%ebx
f0100deb:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0100dee:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0100df1:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100df4:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100df8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100dff:	00 
f0100e00:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100e03:	89 04 24             	mov    %eax,(%esp)
f0100e06:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100e09:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100e0d:	e8 7e 0a 00 00       	call   f0101890 <__udivdi3>
f0100e12:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100e15:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100e18:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100e1c:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100e20:	89 04 24             	mov    %eax,(%esp)
f0100e23:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100e27:	89 f2                	mov    %esi,%edx
f0100e29:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e2c:	e8 5f ff ff ff       	call   f0100d90 <printnum>
f0100e31:	eb 11                	jmp    f0100e44 <printnum+0xb4>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e33:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e37:	89 3c 24             	mov    %edi,(%esp)
f0100e3a:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e3d:	83 eb 01             	sub    $0x1,%ebx
f0100e40:	85 db                	test   %ebx,%ebx
f0100e42:	7f ef                	jg     f0100e33 <printnum+0xa3>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e44:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e48:	8b 74 24 04          	mov    0x4(%esp),%esi
f0100e4c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100e4f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e53:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100e5a:	00 
f0100e5b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100e5e:	89 14 24             	mov    %edx,(%esp)
f0100e61:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100e64:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100e68:	e8 53 0b 00 00       	call   f01019c0 <__umoddi3>
f0100e6d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e71:	0f be 80 69 20 10 f0 	movsbl -0xfefdf97(%eax),%eax
f0100e78:	89 04 24             	mov    %eax,(%esp)
f0100e7b:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100e7e:	83 c4 4c             	add    $0x4c,%esp
f0100e81:	5b                   	pop    %ebx
f0100e82:	5e                   	pop    %esi
f0100e83:	5f                   	pop    %edi
f0100e84:	5d                   	pop    %ebp
f0100e85:	c3                   	ret    

f0100e86 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e86:	55                   	push   %ebp
f0100e87:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e89:	83 fa 01             	cmp    $0x1,%edx
f0100e8c:	7e 0e                	jle    f0100e9c <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e8e:	8b 10                	mov    (%eax),%edx
f0100e90:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e93:	89 08                	mov    %ecx,(%eax)
f0100e95:	8b 02                	mov    (%edx),%eax
f0100e97:	8b 52 04             	mov    0x4(%edx),%edx
f0100e9a:	eb 22                	jmp    f0100ebe <getuint+0x38>
	else if (lflag)
f0100e9c:	85 d2                	test   %edx,%edx
f0100e9e:	74 10                	je     f0100eb0 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100ea0:	8b 10                	mov    (%eax),%edx
f0100ea2:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100ea5:	89 08                	mov    %ecx,(%eax)
f0100ea7:	8b 02                	mov    (%edx),%eax
f0100ea9:	ba 00 00 00 00       	mov    $0x0,%edx
f0100eae:	eb 0e                	jmp    f0100ebe <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100eb0:	8b 10                	mov    (%eax),%edx
f0100eb2:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100eb5:	89 08                	mov    %ecx,(%eax)
f0100eb7:	8b 02                	mov    (%edx),%eax
f0100eb9:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100ebe:	5d                   	pop    %ebp
f0100ebf:	c3                   	ret    

f0100ec0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100ec0:	55                   	push   %ebp
f0100ec1:	89 e5                	mov    %esp,%ebp
f0100ec3:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100ec6:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100eca:	8b 10                	mov    (%eax),%edx
f0100ecc:	3b 50 04             	cmp    0x4(%eax),%edx
f0100ecf:	73 0a                	jae    f0100edb <sprintputch+0x1b>
		*b->buf++ = ch;
f0100ed1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100ed4:	88 0a                	mov    %cl,(%edx)
f0100ed6:	83 c2 01             	add    $0x1,%edx
f0100ed9:	89 10                	mov    %edx,(%eax)
}
f0100edb:	5d                   	pop    %ebp
f0100edc:	c3                   	ret    

f0100edd <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100edd:	55                   	push   %ebp
f0100ede:	89 e5                	mov    %esp,%ebp
f0100ee0:	57                   	push   %edi
f0100ee1:	56                   	push   %esi
f0100ee2:	53                   	push   %ebx
f0100ee3:	83 ec 5c             	sub    $0x5c,%esp
f0100ee6:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100ee9:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100eec:	8b 5d 10             	mov    0x10(%ebp),%ebx
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100eef:	c7 45 c8 ff ff ff ff 	movl   $0xffffffff,-0x38(%ebp)
f0100ef6:	eb 11                	jmp    f0100f09 <vprintfmt+0x2c>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100ef8:	85 c0                	test   %eax,%eax
f0100efa:	0f 84 ec 03 00 00    	je     f01012ec <vprintfmt+0x40f>
				return;
			putch(ch, putdat);
f0100f00:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f04:	89 04 24             	mov    %eax,(%esp)
f0100f07:	ff d7                	call   *%edi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100f09:	0f b6 03             	movzbl (%ebx),%eax
f0100f0c:	83 c3 01             	add    $0x1,%ebx
f0100f0f:	83 f8 25             	cmp    $0x25,%eax
f0100f12:	75 e4                	jne    f0100ef8 <vprintfmt+0x1b>
f0100f14:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100f18:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100f1f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100f26:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100f2d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100f32:	eb 06                	jmp    f0100f3a <vprintfmt+0x5d>
f0100f34:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0100f38:	89 c3                	mov    %eax,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f3a:	0f b6 13             	movzbl (%ebx),%edx
f0100f3d:	0f b6 c2             	movzbl %dl,%eax
f0100f40:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f43:	8d 43 01             	lea    0x1(%ebx),%eax
f0100f46:	83 ea 23             	sub    $0x23,%edx
f0100f49:	80 fa 55             	cmp    $0x55,%dl
f0100f4c:	0f 87 7d 03 00 00    	ja     f01012cf <vprintfmt+0x3f2>
f0100f52:	0f b6 d2             	movzbl %dl,%edx
f0100f55:	ff 24 95 f8 20 10 f0 	jmp    *-0xfefdf08(,%edx,4)
f0100f5c:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100f60:	eb d6                	jmp    f0100f38 <vprintfmt+0x5b>
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f62:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100f65:	83 ea 30             	sub    $0x30,%edx
f0100f68:	89 55 d0             	mov    %edx,-0x30(%ebp)
				ch = *fmt;
f0100f6b:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0100f6e:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0100f71:	83 fb 09             	cmp    $0x9,%ebx
f0100f74:	77 4c                	ja     f0100fc2 <vprintfmt+0xe5>
f0100f76:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100f79:	8b 4d d0             	mov    -0x30(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f7c:	83 c0 01             	add    $0x1,%eax
				precision = precision * 10 + ch - '0';
f0100f7f:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100f82:	8d 4c 4a d0          	lea    -0x30(%edx,%ecx,2),%ecx
				ch = *fmt;
f0100f86:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f0100f89:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0100f8c:	83 fb 09             	cmp    $0x9,%ebx
f0100f8f:	76 eb                	jbe    f0100f7c <vprintfmt+0x9f>
f0100f91:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0100f94:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f97:	eb 29                	jmp    f0100fc2 <vprintfmt+0xe5>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f99:	8b 55 14             	mov    0x14(%ebp),%edx
f0100f9c:	8d 5a 04             	lea    0x4(%edx),%ebx
f0100f9f:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0100fa2:	8b 12                	mov    (%edx),%edx
f0100fa4:	89 55 d0             	mov    %edx,-0x30(%ebp)
			goto process_precision;
f0100fa7:	eb 19                	jmp    f0100fc2 <vprintfmt+0xe5>

		case '.':
			if (width < 0)
f0100fa9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100fac:	c1 fa 1f             	sar    $0x1f,%edx
f0100faf:	f7 d2                	not    %edx
f0100fb1:	21 55 e4             	and    %edx,-0x1c(%ebp)
f0100fb4:	eb 82                	jmp    f0100f38 <vprintfmt+0x5b>
f0100fb6:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
			goto reswitch;
f0100fbd:	e9 76 ff ff ff       	jmp    f0100f38 <vprintfmt+0x5b>

		process_precision:
			if (width < 0)
f0100fc2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100fc6:	0f 89 6c ff ff ff    	jns    f0100f38 <vprintfmt+0x5b>
f0100fcc:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100fcf:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100fd2:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0100fd5:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100fd8:	e9 5b ff ff ff       	jmp    f0100f38 <vprintfmt+0x5b>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100fdd:	83 c1 01             	add    $0x1,%ecx
			goto reswitch;
f0100fe0:	e9 53 ff ff ff       	jmp    f0100f38 <vprintfmt+0x5b>
f0100fe5:	89 45 cc             	mov    %eax,-0x34(%ebp)

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100fe8:	8b 45 14             	mov    0x14(%ebp),%eax
f0100feb:	8d 50 04             	lea    0x4(%eax),%edx
f0100fee:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ff1:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ff5:	8b 00                	mov    (%eax),%eax
f0100ff7:	89 04 24             	mov    %eax,(%esp)
f0100ffa:	ff d7                	call   *%edi
f0100ffc:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			break;
f0100fff:	e9 05 ff ff ff       	jmp    f0100f09 <vprintfmt+0x2c>
f0101004:	89 45 cc             	mov    %eax,-0x34(%ebp)

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101007:	8b 45 14             	mov    0x14(%ebp),%eax
f010100a:	8d 50 04             	lea    0x4(%eax),%edx
f010100d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101010:	8b 00                	mov    (%eax),%eax
f0101012:	89 c2                	mov    %eax,%edx
f0101014:	c1 fa 1f             	sar    $0x1f,%edx
f0101017:	31 d0                	xor    %edx,%eax
f0101019:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010101b:	83 f8 06             	cmp    $0x6,%eax
f010101e:	7f 0b                	jg     f010102b <vprintfmt+0x14e>
f0101020:	8b 14 85 50 22 10 f0 	mov    -0xfefddb0(,%eax,4),%edx
f0101027:	85 d2                	test   %edx,%edx
f0101029:	75 20                	jne    f010104b <vprintfmt+0x16e>
				printfmt(putch, putdat, "error %d", err);
f010102b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010102f:	c7 44 24 08 7a 20 10 	movl   $0xf010207a,0x8(%esp)
f0101036:	f0 
f0101037:	89 74 24 04          	mov    %esi,0x4(%esp)
f010103b:	89 3c 24             	mov    %edi,(%esp)
f010103e:	e8 31 03 00 00       	call   f0101374 <printfmt>
f0101043:	8b 5d cc             	mov    -0x34(%ebp),%ebx
		// error message
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101046:	e9 be fe ff ff       	jmp    f0100f09 <vprintfmt+0x2c>
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
f010104b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010104f:	c7 44 24 08 83 20 10 	movl   $0xf0102083,0x8(%esp)
f0101056:	f0 
f0101057:	89 74 24 04          	mov    %esi,0x4(%esp)
f010105b:	89 3c 24             	mov    %edi,(%esp)
f010105e:	e8 11 03 00 00       	call   f0101374 <printfmt>
f0101063:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0101066:	e9 9e fe ff ff       	jmp    f0100f09 <vprintfmt+0x2c>
f010106b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010106e:	89 c3                	mov    %eax,%ebx
f0101070:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101073:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101076:	89 45 c4             	mov    %eax,-0x3c(%ebp)
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101079:	8b 45 14             	mov    0x14(%ebp),%eax
f010107c:	8d 50 04             	lea    0x4(%eax),%edx
f010107f:	89 55 14             	mov    %edx,0x14(%ebp)
f0101082:	8b 00                	mov    (%eax),%eax
f0101084:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101087:	85 c0                	test   %eax,%eax
f0101089:	75 07                	jne    f0101092 <vprintfmt+0x1b5>
f010108b:	c7 45 e0 86 20 10 f0 	movl   $0xf0102086,-0x20(%ebp)
				p = "(null)";
			if (width > 0 && padc != '-')
f0101092:	83 7d c4 00          	cmpl   $0x0,-0x3c(%ebp)
f0101096:	7e 06                	jle    f010109e <vprintfmt+0x1c1>
f0101098:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f010109c:	75 13                	jne    f01010b1 <vprintfmt+0x1d4>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010109e:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01010a1:	0f be 02             	movsbl (%edx),%eax
f01010a4:	85 c0                	test   %eax,%eax
f01010a6:	0f 85 99 00 00 00    	jne    f0101145 <vprintfmt+0x268>
f01010ac:	e9 86 00 00 00       	jmp    f0101137 <vprintfmt+0x25a>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010b1:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01010b5:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01010b8:	89 0c 24             	mov    %ecx,(%esp)
f01010bb:	e8 db 03 00 00       	call   f010149b <strnlen>
f01010c0:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f01010c3:	29 c2                	sub    %eax,%edx
f01010c5:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01010c8:	85 d2                	test   %edx,%edx
f01010ca:	7e d2                	jle    f010109e <vprintfmt+0x1c1>
					putch(padc, putdat);
f01010cc:	0f be 4d d4          	movsbl -0x2c(%ebp),%ecx
f01010d0:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01010d3:	89 5d c4             	mov    %ebx,-0x3c(%ebp)
f01010d6:	89 d3                	mov    %edx,%ebx
f01010d8:	89 74 24 04          	mov    %esi,0x4(%esp)
f01010dc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01010df:	89 04 24             	mov    %eax,(%esp)
f01010e2:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010e4:	83 eb 01             	sub    $0x1,%ebx
f01010e7:	85 db                	test   %ebx,%ebx
f01010e9:	7f ed                	jg     f01010d8 <vprintfmt+0x1fb>
f01010eb:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01010ee:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01010f5:	eb a7                	jmp    f010109e <vprintfmt+0x1c1>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01010f7:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01010fb:	74 18                	je     f0101115 <vprintfmt+0x238>
f01010fd:	8d 50 e0             	lea    -0x20(%eax),%edx
f0101100:	83 fa 5e             	cmp    $0x5e,%edx
f0101103:	76 10                	jbe    f0101115 <vprintfmt+0x238>
					putch('?', putdat);
f0101105:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101109:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101110:	ff 55 e0             	call   *-0x20(%ebp)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101113:	eb 0a                	jmp    f010111f <vprintfmt+0x242>
					putch('?', putdat);
				else
					putch(ch, putdat);
f0101115:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101119:	89 04 24             	mov    %eax,(%esp)
f010111c:	ff 55 e0             	call   *-0x20(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010111f:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f0101123:	0f be 03             	movsbl (%ebx),%eax
f0101126:	85 c0                	test   %eax,%eax
f0101128:	74 05                	je     f010112f <vprintfmt+0x252>
f010112a:	83 c3 01             	add    $0x1,%ebx
f010112d:	eb 29                	jmp    f0101158 <vprintfmt+0x27b>
f010112f:	89 fe                	mov    %edi,%esi
f0101131:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101134:	8b 5d d0             	mov    -0x30(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101137:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010113b:	7f 2e                	jg     f010116b <vprintfmt+0x28e>
f010113d:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0101140:	e9 c4 fd ff ff       	jmp    f0100f09 <vprintfmt+0x2c>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101145:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101148:	83 c2 01             	add    $0x1,%edx
f010114b:	89 7d e0             	mov    %edi,-0x20(%ebp)
f010114e:	89 f7                	mov    %esi,%edi
f0101150:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101153:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0101156:	89 d3                	mov    %edx,%ebx
f0101158:	85 f6                	test   %esi,%esi
f010115a:	78 9b                	js     f01010f7 <vprintfmt+0x21a>
f010115c:	83 ee 01             	sub    $0x1,%esi
f010115f:	79 96                	jns    f01010f7 <vprintfmt+0x21a>
f0101161:	89 fe                	mov    %edi,%esi
f0101163:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101166:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101169:	eb cc                	jmp    f0101137 <vprintfmt+0x25a>
f010116b:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f010116e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101171:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101175:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010117c:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010117e:	83 eb 01             	sub    $0x1,%ebx
f0101181:	85 db                	test   %ebx,%ebx
f0101183:	7f ec                	jg     f0101171 <vprintfmt+0x294>
f0101185:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0101188:	e9 7c fd ff ff       	jmp    f0100f09 <vprintfmt+0x2c>
f010118d:	89 45 cc             	mov    %eax,-0x34(%ebp)
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101190:	83 f9 01             	cmp    $0x1,%ecx
f0101193:	7e 16                	jle    f01011ab <vprintfmt+0x2ce>
		return va_arg(*ap, long long);
f0101195:	8b 45 14             	mov    0x14(%ebp),%eax
f0101198:	8d 50 08             	lea    0x8(%eax),%edx
f010119b:	89 55 14             	mov    %edx,0x14(%ebp)
f010119e:	8b 10                	mov    (%eax),%edx
f01011a0:	8b 48 04             	mov    0x4(%eax),%ecx
f01011a3:	89 55 d8             	mov    %edx,-0x28(%ebp)
f01011a6:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01011a9:	eb 32                	jmp    f01011dd <vprintfmt+0x300>
	else if (lflag)
f01011ab:	85 c9                	test   %ecx,%ecx
f01011ad:	74 18                	je     f01011c7 <vprintfmt+0x2ea>
		return va_arg(*ap, long);
f01011af:	8b 45 14             	mov    0x14(%ebp),%eax
f01011b2:	8d 50 04             	lea    0x4(%eax),%edx
f01011b5:	89 55 14             	mov    %edx,0x14(%ebp)
f01011b8:	8b 00                	mov    (%eax),%eax
f01011ba:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01011bd:	89 c1                	mov    %eax,%ecx
f01011bf:	c1 f9 1f             	sar    $0x1f,%ecx
f01011c2:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01011c5:	eb 16                	jmp    f01011dd <vprintfmt+0x300>
	else
		return va_arg(*ap, int);
f01011c7:	8b 45 14             	mov    0x14(%ebp),%eax
f01011ca:	8d 50 04             	lea    0x4(%eax),%edx
f01011cd:	89 55 14             	mov    %edx,0x14(%ebp)
f01011d0:	8b 00                	mov    (%eax),%eax
f01011d2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01011d5:	89 c2                	mov    %eax,%edx
f01011d7:	c1 fa 1f             	sar    $0x1f,%edx
f01011da:	89 55 dc             	mov    %edx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01011dd:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01011e0:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01011e3:	b8 0a 00 00 00       	mov    $0xa,%eax
			if ((long long) num < 0) {
f01011e8:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01011ec:	0f 89 9b 00 00 00    	jns    f010128d <vprintfmt+0x3b0>
				putch('-', putdat);
f01011f2:	89 74 24 04          	mov    %esi,0x4(%esp)
f01011f6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01011fd:	ff d7                	call   *%edi
				num = -(long long) num;
f01011ff:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0101202:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101205:	f7 d9                	neg    %ecx
f0101207:	83 d3 00             	adc    $0x0,%ebx
f010120a:	f7 db                	neg    %ebx
f010120c:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101211:	eb 7a                	jmp    f010128d <vprintfmt+0x3b0>
f0101213:	89 45 cc             	mov    %eax,-0x34(%ebp)
			base = 10;
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101216:	89 ca                	mov    %ecx,%edx
f0101218:	8d 45 14             	lea    0x14(%ebp),%eax
f010121b:	e8 66 fc ff ff       	call   f0100e86 <getuint>
f0101220:	89 c1                	mov    %eax,%ecx
f0101222:	89 d3                	mov    %edx,%ebx
f0101224:	b8 0a 00 00 00       	mov    $0xa,%eax
			base = 10;
			goto number;
f0101229:	eb 62                	jmp    f010128d <vprintfmt+0x3b0>
f010122b:	89 45 cc             	mov    %eax,-0x34(%ebp)
			 * */

			/* *
			 * added by troore
			 * */
			num = getuint(&ap, lflag);
f010122e:	89 ca                	mov    %ecx,%edx
f0101230:	8d 45 14             	lea    0x14(%ebp),%eax
f0101233:	e8 4e fc ff ff       	call   f0100e86 <getuint>
f0101238:	89 c1                	mov    %eax,%ecx
f010123a:	89 d3                	mov    %edx,%ebx
f010123c:	b8 08 00 00 00       	mov    $0x8,%eax
			base = 8;
			goto number;
f0101241:	eb 4a                	jmp    f010128d <vprintfmt+0x3b0>
f0101243:	89 45 cc             	mov    %eax,-0x34(%ebp)
			/* */

		// pointer
		case 'p':
			putch('0', putdat);
f0101246:	89 74 24 04          	mov    %esi,0x4(%esp)
f010124a:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101251:	ff d7                	call   *%edi
			putch('x', putdat);
f0101253:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101257:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010125e:	ff d7                	call   *%edi
			num = (unsigned long long)
f0101260:	8b 45 14             	mov    0x14(%ebp),%eax
f0101263:	8d 50 04             	lea    0x4(%eax),%edx
f0101266:	89 55 14             	mov    %edx,0x14(%ebp)
f0101269:	8b 08                	mov    (%eax),%ecx
f010126b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101270:	b8 10 00 00 00       	mov    $0x10,%eax
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101275:	eb 16                	jmp    f010128d <vprintfmt+0x3b0>
f0101277:	89 45 cc             	mov    %eax,-0x34(%ebp)

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010127a:	89 ca                	mov    %ecx,%edx
f010127c:	8d 45 14             	lea    0x14(%ebp),%eax
f010127f:	e8 02 fc ff ff       	call   f0100e86 <getuint>
f0101284:	89 c1                	mov    %eax,%ecx
f0101286:	89 d3                	mov    %edx,%ebx
f0101288:	b8 10 00 00 00       	mov    $0x10,%eax
			base = 16;
		number:
			printnum(putch, putdat, num, base, width, padc);
f010128d:	0f be 55 d4          	movsbl -0x2c(%ebp),%edx
f0101291:	89 54 24 10          	mov    %edx,0x10(%esp)
f0101295:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101298:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010129c:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012a0:	89 0c 24             	mov    %ecx,(%esp)
f01012a3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012a7:	89 f2                	mov    %esi,%edx
f01012a9:	89 f8                	mov    %edi,%eax
f01012ab:	e8 e0 fa ff ff       	call   f0100d90 <printnum>
f01012b0:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			break;
f01012b3:	e9 51 fc ff ff       	jmp    f0100f09 <vprintfmt+0x2c>
f01012b8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01012bb:	8b 55 e0             	mov    -0x20(%ebp),%edx

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01012be:	89 74 24 04          	mov    %esi,0x4(%esp)
f01012c2:	89 14 24             	mov    %edx,(%esp)
f01012c5:	ff d7                	call   *%edi
f01012c7:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			break;
f01012ca:	e9 3a fc ff ff       	jmp    f0100f09 <vprintfmt+0x2c>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01012cf:	89 74 24 04          	mov    %esi,0x4(%esp)
f01012d3:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01012da:	ff d7                	call   *%edi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01012dc:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01012df:	80 38 25             	cmpb   $0x25,(%eax)
f01012e2:	0f 84 21 fc ff ff    	je     f0100f09 <vprintfmt+0x2c>
f01012e8:	89 c3                	mov    %eax,%ebx
f01012ea:	eb f0                	jmp    f01012dc <vprintfmt+0x3ff>
				/* do nothing */;
			break;
		}
	}
}
f01012ec:	83 c4 5c             	add    $0x5c,%esp
f01012ef:	5b                   	pop    %ebx
f01012f0:	5e                   	pop    %esi
f01012f1:	5f                   	pop    %edi
f01012f2:	5d                   	pop    %ebp
f01012f3:	c3                   	ret    

f01012f4 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01012f4:	55                   	push   %ebp
f01012f5:	89 e5                	mov    %esp,%ebp
f01012f7:	83 ec 28             	sub    $0x28,%esp
f01012fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01012fd:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
f0101300:	85 c0                	test   %eax,%eax
f0101302:	74 04                	je     f0101308 <vsnprintf+0x14>
f0101304:	85 d2                	test   %edx,%edx
f0101306:	7f 07                	jg     f010130f <vsnprintf+0x1b>
f0101308:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010130d:	eb 3b                	jmp    f010134a <vsnprintf+0x56>
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};
f010130f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101312:	8d 44 10 ff          	lea    -0x1(%eax,%edx,1),%eax
f0101316:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101319:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101320:	8b 45 14             	mov    0x14(%ebp),%eax
f0101323:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101327:	8b 45 10             	mov    0x10(%ebp),%eax
f010132a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010132e:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101331:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101335:	c7 04 24 c0 0e 10 f0 	movl   $0xf0100ec0,(%esp)
f010133c:	e8 9c fb ff ff       	call   f0100edd <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101341:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101344:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101347:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
f010134a:	c9                   	leave  
f010134b:	c3                   	ret    

f010134c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010134c:	55                   	push   %ebp
f010134d:	89 e5                	mov    %esp,%ebp
f010134f:	83 ec 18             	sub    $0x18,%esp

	return b.cnt;
}

int
snprintf(char *buf, int n, const char *fmt, ...)
f0101352:	8d 45 14             	lea    0x14(%ebp),%eax
{
	va_list ap;
	int rc;

	va_start(ap, fmt);
	rc = vsnprintf(buf, n, fmt, ap);
f0101355:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101359:	8b 45 10             	mov    0x10(%ebp),%eax
f010135c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101360:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101363:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101367:	8b 45 08             	mov    0x8(%ebp),%eax
f010136a:	89 04 24             	mov    %eax,(%esp)
f010136d:	e8 82 ff ff ff       	call   f01012f4 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101372:	c9                   	leave  
f0101373:	c3                   	ret    

f0101374 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101374:	55                   	push   %ebp
f0101375:	89 e5                	mov    %esp,%ebp
f0101377:	83 ec 18             	sub    $0x18,%esp
		}
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
f010137a:	8d 45 14             	lea    0x14(%ebp),%eax
{
	va_list ap;

	va_start(ap, fmt);
	vprintfmt(putch, putdat, fmt, ap);
f010137d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101381:	8b 45 10             	mov    0x10(%ebp),%eax
f0101384:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101388:	8b 45 0c             	mov    0xc(%ebp),%eax
f010138b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010138f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101392:	89 04 24             	mov    %eax,(%esp)
f0101395:	e8 43 fb ff ff       	call   f0100edd <vprintfmt>
	va_end(ap);
}
f010139a:	c9                   	leave  
f010139b:	c3                   	ret    
f010139c:	00 00                	add    %al,(%eax)
	...

f01013a0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01013a0:	55                   	push   %ebp
f01013a1:	89 e5                	mov    %esp,%ebp
f01013a3:	57                   	push   %edi
f01013a4:	56                   	push   %esi
f01013a5:	53                   	push   %ebx
f01013a6:	83 ec 1c             	sub    $0x1c,%esp
f01013a9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01013ac:	85 c0                	test   %eax,%eax
f01013ae:	74 10                	je     f01013c0 <readline+0x20>
		cprintf("%s", prompt);
f01013b0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013b4:	c7 04 24 83 20 10 f0 	movl   $0xf0102083,(%esp)
f01013bb:	e8 4b f6 ff ff       	call   f0100a0b <cprintf>

	i = 0;
	echoing = iscons(0);
f01013c0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013c7:	e8 ca ee ff ff       	call   f0100296 <iscons>
f01013cc:	89 c7                	mov    %eax,%edi
f01013ce:	be 00 00 00 00       	mov    $0x0,%esi
	while (1) {
		c = getchar();
f01013d3:	e8 ad ee ff ff       	call   f0100285 <getchar>
f01013d8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01013da:	85 c0                	test   %eax,%eax
f01013dc:	79 17                	jns    f01013f5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01013de:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013e2:	c7 04 24 6c 22 10 f0 	movl   $0xf010226c,(%esp)
f01013e9:	e8 1d f6 ff ff       	call   f0100a0b <cprintf>
f01013ee:	b8 00 00 00 00       	mov    $0x0,%eax
			return NULL;
f01013f3:	eb 76                	jmp    f010146b <readline+0xcb>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01013f5:	83 f8 08             	cmp    $0x8,%eax
f01013f8:	74 08                	je     f0101402 <readline+0x62>
f01013fa:	83 f8 7f             	cmp    $0x7f,%eax
f01013fd:	8d 76 00             	lea    0x0(%esi),%esi
f0101400:	75 19                	jne    f010141b <readline+0x7b>
f0101402:	85 f6                	test   %esi,%esi
f0101404:	7e 15                	jle    f010141b <readline+0x7b>
			if (echoing)
f0101406:	85 ff                	test   %edi,%edi
f0101408:	74 0c                	je     f0101416 <readline+0x76>
				cputchar('\b');
f010140a:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0101411:	e8 84 f0 ff ff       	call   f010049a <cputchar>
			i--;
f0101416:	83 ee 01             	sub    $0x1,%esi
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101419:	eb b8                	jmp    f01013d3 <readline+0x33>
			if (echoing)
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
f010141b:	83 fb 1f             	cmp    $0x1f,%ebx
f010141e:	66 90                	xchg   %ax,%ax
f0101420:	7e 23                	jle    f0101445 <readline+0xa5>
f0101422:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101428:	7f 1b                	jg     f0101445 <readline+0xa5>
			if (echoing)
f010142a:	85 ff                	test   %edi,%edi
f010142c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101430:	74 08                	je     f010143a <readline+0x9a>
				cputchar(c);
f0101432:	89 1c 24             	mov    %ebx,(%esp)
f0101435:	e8 60 f0 ff ff       	call   f010049a <cputchar>
			buf[i++] = c;
f010143a:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f0101440:	83 c6 01             	add    $0x1,%esi
f0101443:	eb 8e                	jmp    f01013d3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0101445:	83 fb 0a             	cmp    $0xa,%ebx
f0101448:	74 05                	je     f010144f <readline+0xaf>
f010144a:	83 fb 0d             	cmp    $0xd,%ebx
f010144d:	75 84                	jne    f01013d3 <readline+0x33>
			if (echoing)
f010144f:	85 ff                	test   %edi,%edi
f0101451:	74 0c                	je     f010145f <readline+0xbf>
				cputchar('\n');
f0101453:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f010145a:	e8 3b f0 ff ff       	call   f010049a <cputchar>
			buf[i] = 0;
f010145f:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
f0101466:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
			return buf;
		}
	}
}
f010146b:	83 c4 1c             	add    $0x1c,%esp
f010146e:	5b                   	pop    %ebx
f010146f:	5e                   	pop    %esi
f0101470:	5f                   	pop    %edi
f0101471:	5d                   	pop    %ebp
f0101472:	c3                   	ret    
	...

f0101480 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101480:	55                   	push   %ebp
f0101481:	89 e5                	mov    %esp,%ebp
f0101483:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101486:	b8 00 00 00 00       	mov    $0x0,%eax
f010148b:	80 3a 00             	cmpb   $0x0,(%edx)
f010148e:	74 09                	je     f0101499 <strlen+0x19>
		n++;
f0101490:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101493:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101497:	75 f7                	jne    f0101490 <strlen+0x10>
		n++;
	return n;
}
f0101499:	5d                   	pop    %ebp
f010149a:	c3                   	ret    

f010149b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010149b:	55                   	push   %ebp
f010149c:	89 e5                	mov    %esp,%ebp
f010149e:	53                   	push   %ebx
f010149f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01014a2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014a5:	85 c9                	test   %ecx,%ecx
f01014a7:	74 19                	je     f01014c2 <strnlen+0x27>
f01014a9:	80 3b 00             	cmpb   $0x0,(%ebx)
f01014ac:	74 14                	je     f01014c2 <strnlen+0x27>
f01014ae:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01014b3:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014b6:	39 c8                	cmp    %ecx,%eax
f01014b8:	74 0d                	je     f01014c7 <strnlen+0x2c>
f01014ba:	80 3c 03 00          	cmpb   $0x0,(%ebx,%eax,1)
f01014be:	75 f3                	jne    f01014b3 <strnlen+0x18>
f01014c0:	eb 05                	jmp    f01014c7 <strnlen+0x2c>
f01014c2:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01014c7:	5b                   	pop    %ebx
f01014c8:	5d                   	pop    %ebp
f01014c9:	c3                   	ret    

f01014ca <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01014ca:	55                   	push   %ebp
f01014cb:	89 e5                	mov    %esp,%ebp
f01014cd:	53                   	push   %ebx
f01014ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01014d1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01014d4:	ba 00 00 00 00       	mov    $0x0,%edx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01014d9:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01014dd:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01014e0:	83 c2 01             	add    $0x1,%edx
f01014e3:	84 c9                	test   %cl,%cl
f01014e5:	75 f2                	jne    f01014d9 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01014e7:	5b                   	pop    %ebx
f01014e8:	5d                   	pop    %ebp
f01014e9:	c3                   	ret    

f01014ea <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01014ea:	55                   	push   %ebp
f01014eb:	89 e5                	mov    %esp,%ebp
f01014ed:	56                   	push   %esi
f01014ee:	53                   	push   %ebx
f01014ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01014f2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014f5:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01014f8:	85 f6                	test   %esi,%esi
f01014fa:	74 18                	je     f0101514 <strncpy+0x2a>
f01014fc:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f0101501:	0f b6 1a             	movzbl (%edx),%ebx
f0101504:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101507:	80 3a 01             	cmpb   $0x1,(%edx)
f010150a:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010150d:	83 c1 01             	add    $0x1,%ecx
f0101510:	39 ce                	cmp    %ecx,%esi
f0101512:	77 ed                	ja     f0101501 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101514:	5b                   	pop    %ebx
f0101515:	5e                   	pop    %esi
f0101516:	5d                   	pop    %ebp
f0101517:	c3                   	ret    

f0101518 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101518:	55                   	push   %ebp
f0101519:	89 e5                	mov    %esp,%ebp
f010151b:	56                   	push   %esi
f010151c:	53                   	push   %ebx
f010151d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101520:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101523:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101526:	89 f0                	mov    %esi,%eax
f0101528:	85 c9                	test   %ecx,%ecx
f010152a:	74 27                	je     f0101553 <strlcpy+0x3b>
		while (--size > 0 && *src != '\0')
f010152c:	83 e9 01             	sub    $0x1,%ecx
f010152f:	74 1d                	je     f010154e <strlcpy+0x36>
f0101531:	0f b6 1a             	movzbl (%edx),%ebx
f0101534:	84 db                	test   %bl,%bl
f0101536:	74 16                	je     f010154e <strlcpy+0x36>
			*dst++ = *src++;
f0101538:	88 18                	mov    %bl,(%eax)
f010153a:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010153d:	83 e9 01             	sub    $0x1,%ecx
f0101540:	74 0e                	je     f0101550 <strlcpy+0x38>
			*dst++ = *src++;
f0101542:	83 c2 01             	add    $0x1,%edx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101545:	0f b6 1a             	movzbl (%edx),%ebx
f0101548:	84 db                	test   %bl,%bl
f010154a:	75 ec                	jne    f0101538 <strlcpy+0x20>
f010154c:	eb 02                	jmp    f0101550 <strlcpy+0x38>
f010154e:	89 f0                	mov    %esi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101550:	c6 00 00             	movb   $0x0,(%eax)
f0101553:	29 f0                	sub    %esi,%eax
	}
	return dst - dst_in;
}
f0101555:	5b                   	pop    %ebx
f0101556:	5e                   	pop    %esi
f0101557:	5d                   	pop    %ebp
f0101558:	c3                   	ret    

f0101559 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101559:	55                   	push   %ebp
f010155a:	89 e5                	mov    %esp,%ebp
f010155c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010155f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101562:	0f b6 01             	movzbl (%ecx),%eax
f0101565:	84 c0                	test   %al,%al
f0101567:	74 15                	je     f010157e <strcmp+0x25>
f0101569:	3a 02                	cmp    (%edx),%al
f010156b:	75 11                	jne    f010157e <strcmp+0x25>
		p++, q++;
f010156d:	83 c1 01             	add    $0x1,%ecx
f0101570:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101573:	0f b6 01             	movzbl (%ecx),%eax
f0101576:	84 c0                	test   %al,%al
f0101578:	74 04                	je     f010157e <strcmp+0x25>
f010157a:	3a 02                	cmp    (%edx),%al
f010157c:	74 ef                	je     f010156d <strcmp+0x14>
f010157e:	0f b6 c0             	movzbl %al,%eax
f0101581:	0f b6 12             	movzbl (%edx),%edx
f0101584:	29 d0                	sub    %edx,%eax
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101586:	5d                   	pop    %ebp
f0101587:	c3                   	ret    

f0101588 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101588:	55                   	push   %ebp
f0101589:	89 e5                	mov    %esp,%ebp
f010158b:	53                   	push   %ebx
f010158c:	8b 55 08             	mov    0x8(%ebp),%edx
f010158f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101592:	8b 45 10             	mov    0x10(%ebp),%eax
	while (n > 0 && *p && *p == *q)
f0101595:	85 c0                	test   %eax,%eax
f0101597:	74 23                	je     f01015bc <strncmp+0x34>
f0101599:	0f b6 1a             	movzbl (%edx),%ebx
f010159c:	84 db                	test   %bl,%bl
f010159e:	74 24                	je     f01015c4 <strncmp+0x3c>
f01015a0:	3a 19                	cmp    (%ecx),%bl
f01015a2:	75 20                	jne    f01015c4 <strncmp+0x3c>
f01015a4:	83 e8 01             	sub    $0x1,%eax
f01015a7:	74 13                	je     f01015bc <strncmp+0x34>
		n--, p++, q++;
f01015a9:	83 c2 01             	add    $0x1,%edx
f01015ac:	83 c1 01             	add    $0x1,%ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01015af:	0f b6 1a             	movzbl (%edx),%ebx
f01015b2:	84 db                	test   %bl,%bl
f01015b4:	74 0e                	je     f01015c4 <strncmp+0x3c>
f01015b6:	3a 19                	cmp    (%ecx),%bl
f01015b8:	74 ea                	je     f01015a4 <strncmp+0x1c>
f01015ba:	eb 08                	jmp    f01015c4 <strncmp+0x3c>
f01015bc:	b8 00 00 00 00       	mov    $0x0,%eax
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01015c1:	5b                   	pop    %ebx
f01015c2:	5d                   	pop    %ebp
f01015c3:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01015c4:	0f b6 02             	movzbl (%edx),%eax
f01015c7:	0f b6 11             	movzbl (%ecx),%edx
f01015ca:	29 d0                	sub    %edx,%eax
f01015cc:	eb f3                	jmp    f01015c1 <strncmp+0x39>

f01015ce <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01015ce:	55                   	push   %ebp
f01015cf:	89 e5                	mov    %esp,%ebp
f01015d1:	8b 45 08             	mov    0x8(%ebp),%eax
f01015d4:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015d8:	0f b6 10             	movzbl (%eax),%edx
f01015db:	84 d2                	test   %dl,%dl
f01015dd:	74 15                	je     f01015f4 <strchr+0x26>
		if (*s == c)
f01015df:	38 ca                	cmp    %cl,%dl
f01015e1:	75 07                	jne    f01015ea <strchr+0x1c>
f01015e3:	eb 14                	jmp    f01015f9 <strchr+0x2b>
f01015e5:	38 ca                	cmp    %cl,%dl
f01015e7:	90                   	nop
f01015e8:	74 0f                	je     f01015f9 <strchr+0x2b>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01015ea:	83 c0 01             	add    $0x1,%eax
f01015ed:	0f b6 10             	movzbl (%eax),%edx
f01015f0:	84 d2                	test   %dl,%dl
f01015f2:	75 f1                	jne    f01015e5 <strchr+0x17>
f01015f4:	b8 00 00 00 00       	mov    $0x0,%eax
		if (*s == c)
			return (char *) s;
	return 0;
}
f01015f9:	5d                   	pop    %ebp
f01015fa:	c3                   	ret    

f01015fb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01015fb:	55                   	push   %ebp
f01015fc:	89 e5                	mov    %esp,%ebp
f01015fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0101601:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101605:	0f b6 10             	movzbl (%eax),%edx
f0101608:	84 d2                	test   %dl,%dl
f010160a:	74 18                	je     f0101624 <strfind+0x29>
		if (*s == c)
f010160c:	38 ca                	cmp    %cl,%dl
f010160e:	75 0a                	jne    f010161a <strfind+0x1f>
f0101610:	eb 12                	jmp    f0101624 <strfind+0x29>
f0101612:	38 ca                	cmp    %cl,%dl
f0101614:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101618:	74 0a                	je     f0101624 <strfind+0x29>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010161a:	83 c0 01             	add    $0x1,%eax
f010161d:	0f b6 10             	movzbl (%eax),%edx
f0101620:	84 d2                	test   %dl,%dl
f0101622:	75 ee                	jne    f0101612 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0101624:	5d                   	pop    %ebp
f0101625:	c3                   	ret    

f0101626 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101626:	55                   	push   %ebp
f0101627:	89 e5                	mov    %esp,%ebp
f0101629:	83 ec 0c             	sub    $0xc,%esp
f010162c:	89 1c 24             	mov    %ebx,(%esp)
f010162f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101633:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101637:	8b 7d 08             	mov    0x8(%ebp),%edi
f010163a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010163d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101640:	85 c9                	test   %ecx,%ecx
f0101642:	74 30                	je     f0101674 <memset+0x4e>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101644:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010164a:	75 25                	jne    f0101671 <memset+0x4b>
f010164c:	f6 c1 03             	test   $0x3,%cl
f010164f:	75 20                	jne    f0101671 <memset+0x4b>
		c &= 0xFF;
f0101651:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101654:	89 d3                	mov    %edx,%ebx
f0101656:	c1 e3 08             	shl    $0x8,%ebx
f0101659:	89 d6                	mov    %edx,%esi
f010165b:	c1 e6 18             	shl    $0x18,%esi
f010165e:	89 d0                	mov    %edx,%eax
f0101660:	c1 e0 10             	shl    $0x10,%eax
f0101663:	09 f0                	or     %esi,%eax
f0101665:	09 d0                	or     %edx,%eax
		asm volatile("cld; rep stosl\n"
f0101667:	09 d8                	or     %ebx,%eax
f0101669:	c1 e9 02             	shr    $0x2,%ecx
f010166c:	fc                   	cld    
f010166d:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010166f:	eb 03                	jmp    f0101674 <memset+0x4e>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101671:	fc                   	cld    
f0101672:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101674:	89 f8                	mov    %edi,%eax
f0101676:	8b 1c 24             	mov    (%esp),%ebx
f0101679:	8b 74 24 04          	mov    0x4(%esp),%esi
f010167d:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101681:	89 ec                	mov    %ebp,%esp
f0101683:	5d                   	pop    %ebp
f0101684:	c3                   	ret    

f0101685 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101685:	55                   	push   %ebp
f0101686:	89 e5                	mov    %esp,%ebp
f0101688:	83 ec 08             	sub    $0x8,%esp
f010168b:	89 34 24             	mov    %esi,(%esp)
f010168e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101692:	8b 45 08             	mov    0x8(%ebp),%eax
f0101695:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
f0101698:	8b 75 0c             	mov    0xc(%ebp),%esi
	d = dst;
f010169b:	89 c7                	mov    %eax,%edi
	if (s < d && s + n > d) {
f010169d:	39 c6                	cmp    %eax,%esi
f010169f:	73 35                	jae    f01016d6 <memmove+0x51>
f01016a1:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01016a4:	39 d0                	cmp    %edx,%eax
f01016a6:	73 2e                	jae    f01016d6 <memmove+0x51>
		s += n;
		d += n;
f01016a8:	01 cf                	add    %ecx,%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016aa:	f6 c2 03             	test   $0x3,%dl
f01016ad:	75 1b                	jne    f01016ca <memmove+0x45>
f01016af:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01016b5:	75 13                	jne    f01016ca <memmove+0x45>
f01016b7:	f6 c1 03             	test   $0x3,%cl
f01016ba:	75 0e                	jne    f01016ca <memmove+0x45>
			asm volatile("std; rep movsl\n"
f01016bc:	83 ef 04             	sub    $0x4,%edi
f01016bf:	8d 72 fc             	lea    -0x4(%edx),%esi
f01016c2:	c1 e9 02             	shr    $0x2,%ecx
f01016c5:	fd                   	std    
f01016c6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016c8:	eb 09                	jmp    f01016d3 <memmove+0x4e>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01016ca:	83 ef 01             	sub    $0x1,%edi
f01016cd:	8d 72 ff             	lea    -0x1(%edx),%esi
f01016d0:	fd                   	std    
f01016d1:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01016d3:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01016d4:	eb 20                	jmp    f01016f6 <memmove+0x71>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016d6:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01016dc:	75 15                	jne    f01016f3 <memmove+0x6e>
f01016de:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01016e4:	75 0d                	jne    f01016f3 <memmove+0x6e>
f01016e6:	f6 c1 03             	test   $0x3,%cl
f01016e9:	75 08                	jne    f01016f3 <memmove+0x6e>
			asm volatile("cld; rep movsl\n"
f01016eb:	c1 e9 02             	shr    $0x2,%ecx
f01016ee:	fc                   	cld    
f01016ef:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016f1:	eb 03                	jmp    f01016f6 <memmove+0x71>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01016f3:	fc                   	cld    
f01016f4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01016f6:	8b 34 24             	mov    (%esp),%esi
f01016f9:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01016fd:	89 ec                	mov    %ebp,%esp
f01016ff:	5d                   	pop    %ebp
f0101700:	c3                   	ret    

f0101701 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0101701:	55                   	push   %ebp
f0101702:	89 e5                	mov    %esp,%ebp
f0101704:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101707:	8b 45 10             	mov    0x10(%ebp),%eax
f010170a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010170e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101711:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101715:	8b 45 08             	mov    0x8(%ebp),%eax
f0101718:	89 04 24             	mov    %eax,(%esp)
f010171b:	e8 65 ff ff ff       	call   f0101685 <memmove>
}
f0101720:	c9                   	leave  
f0101721:	c3                   	ret    

f0101722 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101722:	55                   	push   %ebp
f0101723:	89 e5                	mov    %esp,%ebp
f0101725:	57                   	push   %edi
f0101726:	56                   	push   %esi
f0101727:	53                   	push   %ebx
f0101728:	8b 75 08             	mov    0x8(%ebp),%esi
f010172b:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010172e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101731:	85 c9                	test   %ecx,%ecx
f0101733:	74 36                	je     f010176b <memcmp+0x49>
		if (*s1 != *s2)
f0101735:	0f b6 06             	movzbl (%esi),%eax
f0101738:	0f b6 1f             	movzbl (%edi),%ebx
f010173b:	38 d8                	cmp    %bl,%al
f010173d:	74 20                	je     f010175f <memcmp+0x3d>
f010173f:	eb 14                	jmp    f0101755 <memcmp+0x33>
f0101741:	0f b6 44 16 01       	movzbl 0x1(%esi,%edx,1),%eax
f0101746:	0f b6 5c 17 01       	movzbl 0x1(%edi,%edx,1),%ebx
f010174b:	83 c2 01             	add    $0x1,%edx
f010174e:	83 e9 01             	sub    $0x1,%ecx
f0101751:	38 d8                	cmp    %bl,%al
f0101753:	74 12                	je     f0101767 <memcmp+0x45>
			return (int) *s1 - (int) *s2;
f0101755:	0f b6 c0             	movzbl %al,%eax
f0101758:	0f b6 db             	movzbl %bl,%ebx
f010175b:	29 d8                	sub    %ebx,%eax
f010175d:	eb 11                	jmp    f0101770 <memcmp+0x4e>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010175f:	83 e9 01             	sub    $0x1,%ecx
f0101762:	ba 00 00 00 00       	mov    $0x0,%edx
f0101767:	85 c9                	test   %ecx,%ecx
f0101769:	75 d6                	jne    f0101741 <memcmp+0x1f>
f010176b:	b8 00 00 00 00       	mov    $0x0,%eax
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
}
f0101770:	5b                   	pop    %ebx
f0101771:	5e                   	pop    %esi
f0101772:	5f                   	pop    %edi
f0101773:	5d                   	pop    %ebp
f0101774:	c3                   	ret    

f0101775 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101775:	55                   	push   %ebp
f0101776:	89 e5                	mov    %esp,%ebp
f0101778:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010177b:	89 c2                	mov    %eax,%edx
f010177d:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101780:	39 d0                	cmp    %edx,%eax
f0101782:	73 15                	jae    f0101799 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101784:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0101788:	38 08                	cmp    %cl,(%eax)
f010178a:	75 06                	jne    f0101792 <memfind+0x1d>
f010178c:	eb 0b                	jmp    f0101799 <memfind+0x24>
f010178e:	38 08                	cmp    %cl,(%eax)
f0101790:	74 07                	je     f0101799 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101792:	83 c0 01             	add    $0x1,%eax
f0101795:	39 c2                	cmp    %eax,%edx
f0101797:	77 f5                	ja     f010178e <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101799:	5d                   	pop    %ebp
f010179a:	c3                   	ret    

f010179b <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010179b:	55                   	push   %ebp
f010179c:	89 e5                	mov    %esp,%ebp
f010179e:	57                   	push   %edi
f010179f:	56                   	push   %esi
f01017a0:	53                   	push   %ebx
f01017a1:	83 ec 04             	sub    $0x4,%esp
f01017a4:	8b 55 08             	mov    0x8(%ebp),%edx
f01017a7:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01017aa:	0f b6 02             	movzbl (%edx),%eax
f01017ad:	3c 20                	cmp    $0x20,%al
f01017af:	74 04                	je     f01017b5 <strtol+0x1a>
f01017b1:	3c 09                	cmp    $0x9,%al
f01017b3:	75 0e                	jne    f01017c3 <strtol+0x28>
		s++;
f01017b5:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01017b8:	0f b6 02             	movzbl (%edx),%eax
f01017bb:	3c 20                	cmp    $0x20,%al
f01017bd:	74 f6                	je     f01017b5 <strtol+0x1a>
f01017bf:	3c 09                	cmp    $0x9,%al
f01017c1:	74 f2                	je     f01017b5 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f01017c3:	3c 2b                	cmp    $0x2b,%al
f01017c5:	75 0c                	jne    f01017d3 <strtol+0x38>
		s++;
f01017c7:	83 c2 01             	add    $0x1,%edx
f01017ca:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f01017d1:	eb 15                	jmp    f01017e8 <strtol+0x4d>
	else if (*s == '-')
f01017d3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f01017da:	3c 2d                	cmp    $0x2d,%al
f01017dc:	75 0a                	jne    f01017e8 <strtol+0x4d>
		s++, neg = 1;
f01017de:	83 c2 01             	add    $0x1,%edx
f01017e1:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01017e8:	85 db                	test   %ebx,%ebx
f01017ea:	0f 94 c0             	sete   %al
f01017ed:	74 05                	je     f01017f4 <strtol+0x59>
f01017ef:	83 fb 10             	cmp    $0x10,%ebx
f01017f2:	75 18                	jne    f010180c <strtol+0x71>
f01017f4:	80 3a 30             	cmpb   $0x30,(%edx)
f01017f7:	75 13                	jne    f010180c <strtol+0x71>
f01017f9:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01017fd:	8d 76 00             	lea    0x0(%esi),%esi
f0101800:	75 0a                	jne    f010180c <strtol+0x71>
		s += 2, base = 16;
f0101802:	83 c2 02             	add    $0x2,%edx
f0101805:	bb 10 00 00 00       	mov    $0x10,%ebx
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010180a:	eb 15                	jmp    f0101821 <strtol+0x86>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010180c:	84 c0                	test   %al,%al
f010180e:	66 90                	xchg   %ax,%ax
f0101810:	74 0f                	je     f0101821 <strtol+0x86>
f0101812:	bb 0a 00 00 00       	mov    $0xa,%ebx
f0101817:	80 3a 30             	cmpb   $0x30,(%edx)
f010181a:	75 05                	jne    f0101821 <strtol+0x86>
		s++, base = 8;
f010181c:	83 c2 01             	add    $0x1,%edx
f010181f:	b3 08                	mov    $0x8,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101821:	b8 00 00 00 00       	mov    $0x0,%eax
f0101826:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101828:	0f b6 0a             	movzbl (%edx),%ecx
f010182b:	89 cf                	mov    %ecx,%edi
f010182d:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101830:	80 fb 09             	cmp    $0x9,%bl
f0101833:	77 08                	ja     f010183d <strtol+0xa2>
			dig = *s - '0';
f0101835:	0f be c9             	movsbl %cl,%ecx
f0101838:	83 e9 30             	sub    $0x30,%ecx
f010183b:	eb 1e                	jmp    f010185b <strtol+0xc0>
		else if (*s >= 'a' && *s <= 'z')
f010183d:	8d 5f 9f             	lea    -0x61(%edi),%ebx
f0101840:	80 fb 19             	cmp    $0x19,%bl
f0101843:	77 08                	ja     f010184d <strtol+0xb2>
			dig = *s - 'a' + 10;
f0101845:	0f be c9             	movsbl %cl,%ecx
f0101848:	83 e9 57             	sub    $0x57,%ecx
f010184b:	eb 0e                	jmp    f010185b <strtol+0xc0>
		else if (*s >= 'A' && *s <= 'Z')
f010184d:	8d 5f bf             	lea    -0x41(%edi),%ebx
f0101850:	80 fb 19             	cmp    $0x19,%bl
f0101853:	77 15                	ja     f010186a <strtol+0xcf>
			dig = *s - 'A' + 10;
f0101855:	0f be c9             	movsbl %cl,%ecx
f0101858:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f010185b:	39 f1                	cmp    %esi,%ecx
f010185d:	7d 0b                	jge    f010186a <strtol+0xcf>
			break;
		s++, val = (val * base) + dig;
f010185f:	83 c2 01             	add    $0x1,%edx
f0101862:	0f af c6             	imul   %esi,%eax
f0101865:	8d 04 01             	lea    (%ecx,%eax,1),%eax
		// we don't properly detect overflow!
	}
f0101868:	eb be                	jmp    f0101828 <strtol+0x8d>
f010186a:	89 c1                	mov    %eax,%ecx

	if (endptr)
f010186c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101870:	74 05                	je     f0101877 <strtol+0xdc>
		*endptr = (char *) s;
f0101872:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101875:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101877:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f010187b:	74 04                	je     f0101881 <strtol+0xe6>
f010187d:	89 c8                	mov    %ecx,%eax
f010187f:	f7 d8                	neg    %eax
}
f0101881:	83 c4 04             	add    $0x4,%esp
f0101884:	5b                   	pop    %ebx
f0101885:	5e                   	pop    %esi
f0101886:	5f                   	pop    %edi
f0101887:	5d                   	pop    %ebp
f0101888:	c3                   	ret    
f0101889:	00 00                	add    %al,(%eax)
f010188b:	00 00                	add    %al,(%eax)
f010188d:	00 00                	add    %al,(%eax)
	...

f0101890 <__udivdi3>:
f0101890:	55                   	push   %ebp
f0101891:	89 e5                	mov    %esp,%ebp
f0101893:	57                   	push   %edi
f0101894:	56                   	push   %esi
f0101895:	83 ec 10             	sub    $0x10,%esp
f0101898:	8b 45 14             	mov    0x14(%ebp),%eax
f010189b:	8b 55 08             	mov    0x8(%ebp),%edx
f010189e:	8b 75 10             	mov    0x10(%ebp),%esi
f01018a1:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01018a4:	85 c0                	test   %eax,%eax
f01018a6:	89 55 f0             	mov    %edx,-0x10(%ebp)
f01018a9:	75 35                	jne    f01018e0 <__udivdi3+0x50>
f01018ab:	39 fe                	cmp    %edi,%esi
f01018ad:	77 61                	ja     f0101910 <__udivdi3+0x80>
f01018af:	85 f6                	test   %esi,%esi
f01018b1:	75 0b                	jne    f01018be <__udivdi3+0x2e>
f01018b3:	b8 01 00 00 00       	mov    $0x1,%eax
f01018b8:	31 d2                	xor    %edx,%edx
f01018ba:	f7 f6                	div    %esi
f01018bc:	89 c6                	mov    %eax,%esi
f01018be:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f01018c1:	31 d2                	xor    %edx,%edx
f01018c3:	89 f8                	mov    %edi,%eax
f01018c5:	f7 f6                	div    %esi
f01018c7:	89 c7                	mov    %eax,%edi
f01018c9:	89 c8                	mov    %ecx,%eax
f01018cb:	f7 f6                	div    %esi
f01018cd:	89 c1                	mov    %eax,%ecx
f01018cf:	89 fa                	mov    %edi,%edx
f01018d1:	89 c8                	mov    %ecx,%eax
f01018d3:	83 c4 10             	add    $0x10,%esp
f01018d6:	5e                   	pop    %esi
f01018d7:	5f                   	pop    %edi
f01018d8:	5d                   	pop    %ebp
f01018d9:	c3                   	ret    
f01018da:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01018e0:	39 f8                	cmp    %edi,%eax
f01018e2:	77 1c                	ja     f0101900 <__udivdi3+0x70>
f01018e4:	0f bd d0             	bsr    %eax,%edx
f01018e7:	83 f2 1f             	xor    $0x1f,%edx
f01018ea:	89 55 f4             	mov    %edx,-0xc(%ebp)
f01018ed:	75 39                	jne    f0101928 <__udivdi3+0x98>
f01018ef:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f01018f2:	0f 86 a0 00 00 00    	jbe    f0101998 <__udivdi3+0x108>
f01018f8:	39 f8                	cmp    %edi,%eax
f01018fa:	0f 82 98 00 00 00    	jb     f0101998 <__udivdi3+0x108>
f0101900:	31 ff                	xor    %edi,%edi
f0101902:	31 c9                	xor    %ecx,%ecx
f0101904:	89 c8                	mov    %ecx,%eax
f0101906:	89 fa                	mov    %edi,%edx
f0101908:	83 c4 10             	add    $0x10,%esp
f010190b:	5e                   	pop    %esi
f010190c:	5f                   	pop    %edi
f010190d:	5d                   	pop    %ebp
f010190e:	c3                   	ret    
f010190f:	90                   	nop
f0101910:	89 d1                	mov    %edx,%ecx
f0101912:	89 fa                	mov    %edi,%edx
f0101914:	89 c8                	mov    %ecx,%eax
f0101916:	31 ff                	xor    %edi,%edi
f0101918:	f7 f6                	div    %esi
f010191a:	89 c1                	mov    %eax,%ecx
f010191c:	89 fa                	mov    %edi,%edx
f010191e:	89 c8                	mov    %ecx,%eax
f0101920:	83 c4 10             	add    $0x10,%esp
f0101923:	5e                   	pop    %esi
f0101924:	5f                   	pop    %edi
f0101925:	5d                   	pop    %ebp
f0101926:	c3                   	ret    
f0101927:	90                   	nop
f0101928:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f010192c:	89 f2                	mov    %esi,%edx
f010192e:	d3 e0                	shl    %cl,%eax
f0101930:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101933:	b8 20 00 00 00       	mov    $0x20,%eax
f0101938:	2b 45 f4             	sub    -0xc(%ebp),%eax
f010193b:	89 c1                	mov    %eax,%ecx
f010193d:	d3 ea                	shr    %cl,%edx
f010193f:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f0101943:	0b 55 ec             	or     -0x14(%ebp),%edx
f0101946:	d3 e6                	shl    %cl,%esi
f0101948:	89 c1                	mov    %eax,%ecx
f010194a:	89 75 e8             	mov    %esi,-0x18(%ebp)
f010194d:	89 fe                	mov    %edi,%esi
f010194f:	d3 ee                	shr    %cl,%esi
f0101951:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f0101955:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101958:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010195b:	d3 e7                	shl    %cl,%edi
f010195d:	89 c1                	mov    %eax,%ecx
f010195f:	d3 ea                	shr    %cl,%edx
f0101961:	09 d7                	or     %edx,%edi
f0101963:	89 f2                	mov    %esi,%edx
f0101965:	89 f8                	mov    %edi,%eax
f0101967:	f7 75 ec             	divl   -0x14(%ebp)
f010196a:	89 d6                	mov    %edx,%esi
f010196c:	89 c7                	mov    %eax,%edi
f010196e:	f7 65 e8             	mull   -0x18(%ebp)
f0101971:	39 d6                	cmp    %edx,%esi
f0101973:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101976:	72 30                	jb     f01019a8 <__udivdi3+0x118>
f0101978:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010197b:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
f010197f:	d3 e2                	shl    %cl,%edx
f0101981:	39 c2                	cmp    %eax,%edx
f0101983:	73 05                	jae    f010198a <__udivdi3+0xfa>
f0101985:	3b 75 ec             	cmp    -0x14(%ebp),%esi
f0101988:	74 1e                	je     f01019a8 <__udivdi3+0x118>
f010198a:	89 f9                	mov    %edi,%ecx
f010198c:	31 ff                	xor    %edi,%edi
f010198e:	e9 71 ff ff ff       	jmp    f0101904 <__udivdi3+0x74>
f0101993:	90                   	nop
f0101994:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101998:	31 ff                	xor    %edi,%edi
f010199a:	b9 01 00 00 00       	mov    $0x1,%ecx
f010199f:	e9 60 ff ff ff       	jmp    f0101904 <__udivdi3+0x74>
f01019a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019a8:	8d 4f ff             	lea    -0x1(%edi),%ecx
f01019ab:	31 ff                	xor    %edi,%edi
f01019ad:	89 c8                	mov    %ecx,%eax
f01019af:	89 fa                	mov    %edi,%edx
f01019b1:	83 c4 10             	add    $0x10,%esp
f01019b4:	5e                   	pop    %esi
f01019b5:	5f                   	pop    %edi
f01019b6:	5d                   	pop    %ebp
f01019b7:	c3                   	ret    
	...

f01019c0 <__umoddi3>:
f01019c0:	55                   	push   %ebp
f01019c1:	89 e5                	mov    %esp,%ebp
f01019c3:	57                   	push   %edi
f01019c4:	56                   	push   %esi
f01019c5:	83 ec 20             	sub    $0x20,%esp
f01019c8:	8b 55 14             	mov    0x14(%ebp),%edx
f01019cb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01019ce:	8b 7d 10             	mov    0x10(%ebp),%edi
f01019d1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01019d4:	85 d2                	test   %edx,%edx
f01019d6:	89 c8                	mov    %ecx,%eax
f01019d8:	89 4d f4             	mov    %ecx,-0xc(%ebp)
f01019db:	75 13                	jne    f01019f0 <__umoddi3+0x30>
f01019dd:	39 f7                	cmp    %esi,%edi
f01019df:	76 3f                	jbe    f0101a20 <__umoddi3+0x60>
f01019e1:	89 f2                	mov    %esi,%edx
f01019e3:	f7 f7                	div    %edi
f01019e5:	89 d0                	mov    %edx,%eax
f01019e7:	31 d2                	xor    %edx,%edx
f01019e9:	83 c4 20             	add    $0x20,%esp
f01019ec:	5e                   	pop    %esi
f01019ed:	5f                   	pop    %edi
f01019ee:	5d                   	pop    %ebp
f01019ef:	c3                   	ret    
f01019f0:	39 f2                	cmp    %esi,%edx
f01019f2:	77 4c                	ja     f0101a40 <__umoddi3+0x80>
f01019f4:	0f bd ca             	bsr    %edx,%ecx
f01019f7:	83 f1 1f             	xor    $0x1f,%ecx
f01019fa:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01019fd:	75 51                	jne    f0101a50 <__umoddi3+0x90>
f01019ff:	3b 7d f4             	cmp    -0xc(%ebp),%edi
f0101a02:	0f 87 e0 00 00 00    	ja     f0101ae8 <__umoddi3+0x128>
f0101a08:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101a0b:	29 f8                	sub    %edi,%eax
f0101a0d:	19 d6                	sbb    %edx,%esi
f0101a0f:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101a12:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101a15:	89 f2                	mov    %esi,%edx
f0101a17:	83 c4 20             	add    $0x20,%esp
f0101a1a:	5e                   	pop    %esi
f0101a1b:	5f                   	pop    %edi
f0101a1c:	5d                   	pop    %ebp
f0101a1d:	c3                   	ret    
f0101a1e:	66 90                	xchg   %ax,%ax
f0101a20:	85 ff                	test   %edi,%edi
f0101a22:	75 0b                	jne    f0101a2f <__umoddi3+0x6f>
f0101a24:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a29:	31 d2                	xor    %edx,%edx
f0101a2b:	f7 f7                	div    %edi
f0101a2d:	89 c7                	mov    %eax,%edi
f0101a2f:	89 f0                	mov    %esi,%eax
f0101a31:	31 d2                	xor    %edx,%edx
f0101a33:	f7 f7                	div    %edi
f0101a35:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101a38:	f7 f7                	div    %edi
f0101a3a:	eb a9                	jmp    f01019e5 <__umoddi3+0x25>
f0101a3c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a40:	89 c8                	mov    %ecx,%eax
f0101a42:	89 f2                	mov    %esi,%edx
f0101a44:	83 c4 20             	add    $0x20,%esp
f0101a47:	5e                   	pop    %esi
f0101a48:	5f                   	pop    %edi
f0101a49:	5d                   	pop    %ebp
f0101a4a:	c3                   	ret    
f0101a4b:	90                   	nop
f0101a4c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a50:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101a54:	d3 e2                	shl    %cl,%edx
f0101a56:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0101a59:	ba 20 00 00 00       	mov    $0x20,%edx
f0101a5e:	2b 55 f0             	sub    -0x10(%ebp),%edx
f0101a61:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101a64:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101a68:	89 fa                	mov    %edi,%edx
f0101a6a:	d3 ea                	shr    %cl,%edx
f0101a6c:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101a70:	0b 55 f4             	or     -0xc(%ebp),%edx
f0101a73:	d3 e7                	shl    %cl,%edi
f0101a75:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101a79:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0101a7c:	89 f2                	mov    %esi,%edx
f0101a7e:	89 7d e8             	mov    %edi,-0x18(%ebp)
f0101a81:	89 c7                	mov    %eax,%edi
f0101a83:	d3 ea                	shr    %cl,%edx
f0101a85:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101a89:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101a8c:	89 c2                	mov    %eax,%edx
f0101a8e:	d3 e6                	shl    %cl,%esi
f0101a90:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101a94:	d3 ea                	shr    %cl,%edx
f0101a96:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101a9a:	09 d6                	or     %edx,%esi
f0101a9c:	89 f0                	mov    %esi,%eax
f0101a9e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101aa1:	d3 e7                	shl    %cl,%edi
f0101aa3:	89 f2                	mov    %esi,%edx
f0101aa5:	f7 75 f4             	divl   -0xc(%ebp)
f0101aa8:	89 d6                	mov    %edx,%esi
f0101aaa:	f7 65 e8             	mull   -0x18(%ebp)
f0101aad:	39 d6                	cmp    %edx,%esi
f0101aaf:	72 2b                	jb     f0101adc <__umoddi3+0x11c>
f0101ab1:	39 c7                	cmp    %eax,%edi
f0101ab3:	72 23                	jb     f0101ad8 <__umoddi3+0x118>
f0101ab5:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101ab9:	29 c7                	sub    %eax,%edi
f0101abb:	19 d6                	sbb    %edx,%esi
f0101abd:	89 f0                	mov    %esi,%eax
f0101abf:	89 f2                	mov    %esi,%edx
f0101ac1:	d3 ef                	shr    %cl,%edi
f0101ac3:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f0101ac7:	d3 e0                	shl    %cl,%eax
f0101ac9:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101acd:	09 f8                	or     %edi,%eax
f0101acf:	d3 ea                	shr    %cl,%edx
f0101ad1:	83 c4 20             	add    $0x20,%esp
f0101ad4:	5e                   	pop    %esi
f0101ad5:	5f                   	pop    %edi
f0101ad6:	5d                   	pop    %ebp
f0101ad7:	c3                   	ret    
f0101ad8:	39 d6                	cmp    %edx,%esi
f0101ada:	75 d9                	jne    f0101ab5 <__umoddi3+0xf5>
f0101adc:	2b 45 e8             	sub    -0x18(%ebp),%eax
f0101adf:	1b 55 f4             	sbb    -0xc(%ebp),%edx
f0101ae2:	eb d1                	jmp    f0101ab5 <__umoddi3+0xf5>
f0101ae4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ae8:	39 f2                	cmp    %esi,%edx
f0101aea:	0f 82 18 ff ff ff    	jb     f0101a08 <__umoddi3+0x48>
f0101af0:	e9 1d ff ff ff       	jmp    f0101a12 <__umoddi3+0x52>
