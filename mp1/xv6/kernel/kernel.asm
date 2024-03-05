
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	85013103          	ld	sp,-1968(sp) # 80008850 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fde70713          	addi	a4,a4,-34 # 80009030 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	b4c78793          	addi	a5,a5,-1204 # 80005bb0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	e1878793          	addi	a5,a5,-488 # 80000ec6 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
    80000106:	8a2a                	mv	s4,a0
    80000108:	84ae                	mv	s1,a1
    8000010a:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    8000010c:	00011517          	auipc	a0,0x11
    80000110:	06450513          	addi	a0,a0,100 # 80011170 <cons>
    80000114:	00001097          	auipc	ra,0x1
    80000118:	b04080e7          	jalr	-1276(ra) # 80000c18 <acquire>
  for(i = 0; i < n; i++){
    8000011c:	05305b63          	blez	s3,80000172 <consolewrite+0x7e>
    80000120:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000122:	5afd                	li	s5,-1
    80000124:	4685                	li	a3,1
    80000126:	8626                	mv	a2,s1
    80000128:	85d2                	mv	a1,s4
    8000012a:	fbf40513          	addi	a0,s0,-65
    8000012e:	00002097          	auipc	ra,0x2
    80000132:	378080e7          	jalr	888(ra) # 800024a6 <either_copyin>
    80000136:	01550c63          	beq	a0,s5,8000014e <consolewrite+0x5a>
      break;
    uartputc(c);
    8000013a:	fbf44503          	lbu	a0,-65(s0)
    8000013e:	00000097          	auipc	ra,0x0
    80000142:	7aa080e7          	jalr	1962(ra) # 800008e8 <uartputc>
  for(i = 0; i < n; i++){
    80000146:	2905                	addiw	s2,s2,1
    80000148:	0485                	addi	s1,s1,1
    8000014a:	fd299de3          	bne	s3,s2,80000124 <consolewrite+0x30>
  }
  release(&cons.lock);
    8000014e:	00011517          	auipc	a0,0x11
    80000152:	02250513          	addi	a0,a0,34 # 80011170 <cons>
    80000156:	00001097          	auipc	ra,0x1
    8000015a:	b76080e7          	jalr	-1162(ra) # 80000ccc <release>

  return i;
}
    8000015e:	854a                	mv	a0,s2
    80000160:	60a6                	ld	ra,72(sp)
    80000162:	6406                	ld	s0,64(sp)
    80000164:	74e2                	ld	s1,56(sp)
    80000166:	7942                	ld	s2,48(sp)
    80000168:	79a2                	ld	s3,40(sp)
    8000016a:	7a02                	ld	s4,32(sp)
    8000016c:	6ae2                	ld	s5,24(sp)
    8000016e:	6161                	addi	sp,sp,80
    80000170:	8082                	ret
  for(i = 0; i < n; i++){
    80000172:	4901                	li	s2,0
    80000174:	bfe9                	j	8000014e <consolewrite+0x5a>

0000000080000176 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000176:	7119                	addi	sp,sp,-128
    80000178:	fc86                	sd	ra,120(sp)
    8000017a:	f8a2                	sd	s0,112(sp)
    8000017c:	f4a6                	sd	s1,104(sp)
    8000017e:	f0ca                	sd	s2,96(sp)
    80000180:	ecce                	sd	s3,88(sp)
    80000182:	e8d2                	sd	s4,80(sp)
    80000184:	e4d6                	sd	s5,72(sp)
    80000186:	e0da                	sd	s6,64(sp)
    80000188:	fc5e                	sd	s7,56(sp)
    8000018a:	f862                	sd	s8,48(sp)
    8000018c:	f466                	sd	s9,40(sp)
    8000018e:	f06a                	sd	s10,32(sp)
    80000190:	ec6e                	sd	s11,24(sp)
    80000192:	0100                	addi	s0,sp,128
    80000194:	8b2a                	mv	s6,a0
    80000196:	8aae                	mv	s5,a1
    80000198:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000019a:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000019e:	00011517          	auipc	a0,0x11
    800001a2:	fd250513          	addi	a0,a0,-46 # 80011170 <cons>
    800001a6:	00001097          	auipc	ra,0x1
    800001aa:	a72080e7          	jalr	-1422(ra) # 80000c18 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001ae:	00011497          	auipc	s1,0x11
    800001b2:	fc248493          	addi	s1,s1,-62 # 80011170 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001b6:	89a6                	mv	s3,s1
    800001b8:	00011917          	auipc	s2,0x11
    800001bc:	05090913          	addi	s2,s2,80 # 80011208 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001c0:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001c2:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001c4:	4da9                	li	s11,10
  while(n > 0){
    800001c6:	07405863          	blez	s4,80000236 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	02f71463          	bne	a4,a5,800001fa <consoleread+0x84>
      if(myproc()->killed){
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	82c080e7          	jalr	-2004(ra) # 80001a02 <myproc>
    800001de:	591c                	lw	a5,48(a0)
    800001e0:	e7b5                	bnez	a5,8000024c <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001e2:	85ce                	mv	a1,s3
    800001e4:	854a                	mv	a0,s2
    800001e6:	00002097          	auipc	ra,0x2
    800001ea:	008080e7          	jalr	8(ra) # 800021ee <sleep>
    while(cons.r == cons.w){
    800001ee:	0984a783          	lw	a5,152(s1)
    800001f2:	09c4a703          	lw	a4,156(s1)
    800001f6:	fef700e3          	beq	a4,a5,800001d6 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001fa:	0017871b          	addiw	a4,a5,1
    800001fe:	08e4ac23          	sw	a4,152(s1)
    80000202:	07f7f713          	andi	a4,a5,127
    80000206:	9726                	add	a4,a4,s1
    80000208:	01874703          	lbu	a4,24(a4)
    8000020c:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000210:	079c0663          	beq	s8,s9,8000027c <consoleread+0x106>
    cbuf = c;
    80000214:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000218:	4685                	li	a3,1
    8000021a:	f8f40613          	addi	a2,s0,-113
    8000021e:	85d6                	mv	a1,s5
    80000220:	855a                	mv	a0,s6
    80000222:	00002097          	auipc	ra,0x2
    80000226:	22e080e7          	jalr	558(ra) # 80002450 <either_copyout>
    8000022a:	01a50663          	beq	a0,s10,80000236 <consoleread+0xc0>
    dst++;
    8000022e:	0a85                	addi	s5,s5,1
    --n;
    80000230:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000232:	f9bc1ae3          	bne	s8,s11,800001c6 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f3a50513          	addi	a0,a0,-198 # 80011170 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	a8e080e7          	jalr	-1394(ra) # 80000ccc <release>

  return target - n;
    80000246:	414b853b          	subw	a0,s7,s4
    8000024a:	a811                	j	8000025e <consoleread+0xe8>
        release(&cons.lock);
    8000024c:	00011517          	auipc	a0,0x11
    80000250:	f2450513          	addi	a0,a0,-220 # 80011170 <cons>
    80000254:	00001097          	auipc	ra,0x1
    80000258:	a78080e7          	jalr	-1416(ra) # 80000ccc <release>
        return -1;
    8000025c:	557d                	li	a0,-1
}
    8000025e:	70e6                	ld	ra,120(sp)
    80000260:	7446                	ld	s0,112(sp)
    80000262:	74a6                	ld	s1,104(sp)
    80000264:	7906                	ld	s2,96(sp)
    80000266:	69e6                	ld	s3,88(sp)
    80000268:	6a46                	ld	s4,80(sp)
    8000026a:	6aa6                	ld	s5,72(sp)
    8000026c:	6b06                	ld	s6,64(sp)
    8000026e:	7be2                	ld	s7,56(sp)
    80000270:	7c42                	ld	s8,48(sp)
    80000272:	7ca2                	ld	s9,40(sp)
    80000274:	7d02                	ld	s10,32(sp)
    80000276:	6de2                	ld	s11,24(sp)
    80000278:	6109                	addi	sp,sp,128
    8000027a:	8082                	ret
      if(n < target){
    8000027c:	000a071b          	sext.w	a4,s4
    80000280:	fb777be3          	bgeu	a4,s7,80000236 <consoleread+0xc0>
        cons.r--;
    80000284:	00011717          	auipc	a4,0x11
    80000288:	f8f72223          	sw	a5,-124(a4) # 80011208 <cons+0x98>
    8000028c:	b76d                	j	80000236 <consoleread+0xc0>

000000008000028e <consputc>:
{
    8000028e:	1141                	addi	sp,sp,-16
    80000290:	e406                	sd	ra,8(sp)
    80000292:	e022                	sd	s0,0(sp)
    80000294:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000296:	10000793          	li	a5,256
    8000029a:	00f50a63          	beq	a0,a5,800002ae <consputc+0x20>
    uartputc_sync(c);
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	564080e7          	jalr	1380(ra) # 80000802 <uartputc_sync>
}
    800002a6:	60a2                	ld	ra,8(sp)
    800002a8:	6402                	ld	s0,0(sp)
    800002aa:	0141                	addi	sp,sp,16
    800002ac:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	552080e7          	jalr	1362(ra) # 80000802 <uartputc_sync>
    800002b8:	02000513          	li	a0,32
    800002bc:	00000097          	auipc	ra,0x0
    800002c0:	546080e7          	jalr	1350(ra) # 80000802 <uartputc_sync>
    800002c4:	4521                	li	a0,8
    800002c6:	00000097          	auipc	ra,0x0
    800002ca:	53c080e7          	jalr	1340(ra) # 80000802 <uartputc_sync>
    800002ce:	bfe1                	j	800002a6 <consputc+0x18>

00000000800002d0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002d0:	1101                	addi	sp,sp,-32
    800002d2:	ec06                	sd	ra,24(sp)
    800002d4:	e822                	sd	s0,16(sp)
    800002d6:	e426                	sd	s1,8(sp)
    800002d8:	e04a                	sd	s2,0(sp)
    800002da:	1000                	addi	s0,sp,32
    800002dc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002de:	00011517          	auipc	a0,0x11
    800002e2:	e9250513          	addi	a0,a0,-366 # 80011170 <cons>
    800002e6:	00001097          	auipc	ra,0x1
    800002ea:	932080e7          	jalr	-1742(ra) # 80000c18 <acquire>

  switch(c){
    800002ee:	47d5                	li	a5,21
    800002f0:	0af48663          	beq	s1,a5,8000039c <consoleintr+0xcc>
    800002f4:	0297ca63          	blt	a5,s1,80000328 <consoleintr+0x58>
    800002f8:	47a1                	li	a5,8
    800002fa:	0ef48763          	beq	s1,a5,800003e8 <consoleintr+0x118>
    800002fe:	47c1                	li	a5,16
    80000300:	10f49a63          	bne	s1,a5,80000414 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    80000304:	00002097          	auipc	ra,0x2
    80000308:	1f8080e7          	jalr	504(ra) # 800024fc <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    8000030c:	00011517          	auipc	a0,0x11
    80000310:	e6450513          	addi	a0,a0,-412 # 80011170 <cons>
    80000314:	00001097          	auipc	ra,0x1
    80000318:	9b8080e7          	jalr	-1608(ra) # 80000ccc <release>
}
    8000031c:	60e2                	ld	ra,24(sp)
    8000031e:	6442                	ld	s0,16(sp)
    80000320:	64a2                	ld	s1,8(sp)
    80000322:	6902                	ld	s2,0(sp)
    80000324:	6105                	addi	sp,sp,32
    80000326:	8082                	ret
  switch(c){
    80000328:	07f00793          	li	a5,127
    8000032c:	0af48e63          	beq	s1,a5,800003e8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000330:	00011717          	auipc	a4,0x11
    80000334:	e4070713          	addi	a4,a4,-448 # 80011170 <cons>
    80000338:	0a072783          	lw	a5,160(a4)
    8000033c:	09872703          	lw	a4,152(a4)
    80000340:	9f99                	subw	a5,a5,a4
    80000342:	07f00713          	li	a4,127
    80000346:	fcf763e3          	bltu	a4,a5,8000030c <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000034a:	47b5                	li	a5,13
    8000034c:	0cf48763          	beq	s1,a5,8000041a <consoleintr+0x14a>
      consputc(c);
    80000350:	8526                	mv	a0,s1
    80000352:	00000097          	auipc	ra,0x0
    80000356:	f3c080e7          	jalr	-196(ra) # 8000028e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000035a:	00011797          	auipc	a5,0x11
    8000035e:	e1678793          	addi	a5,a5,-490 # 80011170 <cons>
    80000362:	0a07a703          	lw	a4,160(a5)
    80000366:	0017069b          	addiw	a3,a4,1
    8000036a:	0006861b          	sext.w	a2,a3
    8000036e:	0ad7a023          	sw	a3,160(a5)
    80000372:	07f77713          	andi	a4,a4,127
    80000376:	97ba                	add	a5,a5,a4
    80000378:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000037c:	47a9                	li	a5,10
    8000037e:	0cf48563          	beq	s1,a5,80000448 <consoleintr+0x178>
    80000382:	4791                	li	a5,4
    80000384:	0cf48263          	beq	s1,a5,80000448 <consoleintr+0x178>
    80000388:	00011797          	auipc	a5,0x11
    8000038c:	e807a783          	lw	a5,-384(a5) # 80011208 <cons+0x98>
    80000390:	0807879b          	addiw	a5,a5,128
    80000394:	f6f61ce3          	bne	a2,a5,8000030c <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000398:	863e                	mv	a2,a5
    8000039a:	a07d                	j	80000448 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000039c:	00011717          	auipc	a4,0x11
    800003a0:	dd470713          	addi	a4,a4,-556 # 80011170 <cons>
    800003a4:	0a072783          	lw	a5,160(a4)
    800003a8:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ac:	00011497          	auipc	s1,0x11
    800003b0:	dc448493          	addi	s1,s1,-572 # 80011170 <cons>
    while(cons.e != cons.w &&
    800003b4:	4929                	li	s2,10
    800003b6:	f4f70be3          	beq	a4,a5,8000030c <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ba:	37fd                	addiw	a5,a5,-1
    800003bc:	07f7f713          	andi	a4,a5,127
    800003c0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003c2:	01874703          	lbu	a4,24(a4)
    800003c6:	f52703e3          	beq	a4,s2,8000030c <consoleintr+0x3c>
      cons.e--;
    800003ca:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003ce:	10000513          	li	a0,256
    800003d2:	00000097          	auipc	ra,0x0
    800003d6:	ebc080e7          	jalr	-324(ra) # 8000028e <consputc>
    while(cons.e != cons.w &&
    800003da:	0a04a783          	lw	a5,160(s1)
    800003de:	09c4a703          	lw	a4,156(s1)
    800003e2:	fcf71ce3          	bne	a4,a5,800003ba <consoleintr+0xea>
    800003e6:	b71d                	j	8000030c <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e8:	00011717          	auipc	a4,0x11
    800003ec:	d8870713          	addi	a4,a4,-632 # 80011170 <cons>
    800003f0:	0a072783          	lw	a5,160(a4)
    800003f4:	09c72703          	lw	a4,156(a4)
    800003f8:	f0f70ae3          	beq	a4,a5,8000030c <consoleintr+0x3c>
      cons.e--;
    800003fc:	37fd                	addiw	a5,a5,-1
    800003fe:	00011717          	auipc	a4,0x11
    80000402:	e0f72923          	sw	a5,-494(a4) # 80011210 <cons+0xa0>
      consputc(BACKSPACE);
    80000406:	10000513          	li	a0,256
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e84080e7          	jalr	-380(ra) # 8000028e <consputc>
    80000412:	bded                	j	8000030c <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000414:	ee048ce3          	beqz	s1,8000030c <consoleintr+0x3c>
    80000418:	bf21                	j	80000330 <consoleintr+0x60>
      consputc(c);
    8000041a:	4529                	li	a0,10
    8000041c:	00000097          	auipc	ra,0x0
    80000420:	e72080e7          	jalr	-398(ra) # 8000028e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000424:	00011797          	auipc	a5,0x11
    80000428:	d4c78793          	addi	a5,a5,-692 # 80011170 <cons>
    8000042c:	0a07a703          	lw	a4,160(a5)
    80000430:	0017069b          	addiw	a3,a4,1
    80000434:	0006861b          	sext.w	a2,a3
    80000438:	0ad7a023          	sw	a3,160(a5)
    8000043c:	07f77713          	andi	a4,a4,127
    80000440:	97ba                	add	a5,a5,a4
    80000442:	4729                	li	a4,10
    80000444:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000448:	00011797          	auipc	a5,0x11
    8000044c:	dcc7a223          	sw	a2,-572(a5) # 8001120c <cons+0x9c>
        wakeup(&cons.r);
    80000450:	00011517          	auipc	a0,0x11
    80000454:	db850513          	addi	a0,a0,-584 # 80011208 <cons+0x98>
    80000458:	00002097          	auipc	ra,0x2
    8000045c:	f1c080e7          	jalr	-228(ra) # 80002374 <wakeup>
    80000460:	b575                	j	8000030c <consoleintr+0x3c>

0000000080000462 <consoleinit>:

void
consoleinit(void)
{
    80000462:	1141                	addi	sp,sp,-16
    80000464:	e406                	sd	ra,8(sp)
    80000466:	e022                	sd	s0,0(sp)
    80000468:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000046a:	00008597          	auipc	a1,0x8
    8000046e:	ba658593          	addi	a1,a1,-1114 # 80008010 <etext+0x10>
    80000472:	00011517          	auipc	a0,0x11
    80000476:	cfe50513          	addi	a0,a0,-770 # 80011170 <cons>
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	70e080e7          	jalr	1806(ra) # 80000b88 <initlock>

  uartinit();
    80000482:	00000097          	auipc	ra,0x0
    80000486:	330080e7          	jalr	816(ra) # 800007b2 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000048a:	00021797          	auipc	a5,0x21
    8000048e:	e6678793          	addi	a5,a5,-410 # 800212f0 <devsw>
    80000492:	00000717          	auipc	a4,0x0
    80000496:	ce470713          	addi	a4,a4,-796 # 80000176 <consoleread>
    8000049a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000049c:	00000717          	auipc	a4,0x0
    800004a0:	c5870713          	addi	a4,a4,-936 # 800000f4 <consolewrite>
    800004a4:	ef98                	sd	a4,24(a5)
}
    800004a6:	60a2                	ld	ra,8(sp)
    800004a8:	6402                	ld	s0,0(sp)
    800004aa:	0141                	addi	sp,sp,16
    800004ac:	8082                	ret

00000000800004ae <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004ae:	7179                	addi	sp,sp,-48
    800004b0:	f406                	sd	ra,40(sp)
    800004b2:	f022                	sd	s0,32(sp)
    800004b4:	ec26                	sd	s1,24(sp)
    800004b6:	e84a                	sd	s2,16(sp)
    800004b8:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ba:	c219                	beqz	a2,800004c0 <printint+0x12>
    800004bc:	08054663          	bltz	a0,80000548 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004c0:	2501                	sext.w	a0,a0
    800004c2:	4881                	li	a7,0
    800004c4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004ca:	2581                	sext.w	a1,a1
    800004cc:	00008617          	auipc	a2,0x8
    800004d0:	b7460613          	addi	a2,a2,-1164 # 80008040 <digits>
    800004d4:	883a                	mv	a6,a4
    800004d6:	2705                	addiw	a4,a4,1
    800004d8:	02b577bb          	remuw	a5,a0,a1
    800004dc:	1782                	slli	a5,a5,0x20
    800004de:	9381                	srli	a5,a5,0x20
    800004e0:	97b2                	add	a5,a5,a2
    800004e2:	0007c783          	lbu	a5,0(a5)
    800004e6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004ea:	0005079b          	sext.w	a5,a0
    800004ee:	02b5553b          	divuw	a0,a0,a1
    800004f2:	0685                	addi	a3,a3,1
    800004f4:	feb7f0e3          	bgeu	a5,a1,800004d4 <printint+0x26>

  if(sign)
    800004f8:	00088b63          	beqz	a7,8000050e <printint+0x60>
    buf[i++] = '-';
    800004fc:	fe040793          	addi	a5,s0,-32
    80000500:	973e                	add	a4,a4,a5
    80000502:	02d00793          	li	a5,45
    80000506:	fef70823          	sb	a5,-16(a4)
    8000050a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    8000050e:	02e05763          	blez	a4,8000053c <printint+0x8e>
    80000512:	fd040793          	addi	a5,s0,-48
    80000516:	00e784b3          	add	s1,a5,a4
    8000051a:	fff78913          	addi	s2,a5,-1
    8000051e:	993a                	add	s2,s2,a4
    80000520:	377d                	addiw	a4,a4,-1
    80000522:	1702                	slli	a4,a4,0x20
    80000524:	9301                	srli	a4,a4,0x20
    80000526:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000052a:	fff4c503          	lbu	a0,-1(s1)
    8000052e:	00000097          	auipc	ra,0x0
    80000532:	d60080e7          	jalr	-672(ra) # 8000028e <consputc>
  while(--i >= 0)
    80000536:	14fd                	addi	s1,s1,-1
    80000538:	ff2499e3          	bne	s1,s2,8000052a <printint+0x7c>
}
    8000053c:	70a2                	ld	ra,40(sp)
    8000053e:	7402                	ld	s0,32(sp)
    80000540:	64e2                	ld	s1,24(sp)
    80000542:	6942                	ld	s2,16(sp)
    80000544:	6145                	addi	sp,sp,48
    80000546:	8082                	ret
    x = -xx;
    80000548:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000054c:	4885                	li	a7,1
    x = -xx;
    8000054e:	bf9d                	j	800004c4 <printint+0x16>

0000000080000550 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000550:	1101                	addi	sp,sp,-32
    80000552:	ec06                	sd	ra,24(sp)
    80000554:	e822                	sd	s0,16(sp)
    80000556:	e426                	sd	s1,8(sp)
    80000558:	1000                	addi	s0,sp,32
    8000055a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000055c:	00011797          	auipc	a5,0x11
    80000560:	cc07aa23          	sw	zero,-812(a5) # 80011230 <pr+0x18>
  printf("panic: ");
    80000564:	00008517          	auipc	a0,0x8
    80000568:	ab450513          	addi	a0,a0,-1356 # 80008018 <etext+0x18>
    8000056c:	00000097          	auipc	ra,0x0
    80000570:	02e080e7          	jalr	46(ra) # 8000059a <printf>
  printf(s);
    80000574:	8526                	mv	a0,s1
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	024080e7          	jalr	36(ra) # 8000059a <printf>
  printf("\n");
    8000057e:	00008517          	auipc	a0,0x8
    80000582:	b4a50513          	addi	a0,a0,-1206 # 800080c8 <digits+0x88>
    80000586:	00000097          	auipc	ra,0x0
    8000058a:	014080e7          	jalr	20(ra) # 8000059a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000058e:	4785                	li	a5,1
    80000590:	00009717          	auipc	a4,0x9
    80000594:	a6f72823          	sw	a5,-1424(a4) # 80009000 <panicked>
  for(;;)
    80000598:	a001                	j	80000598 <panic+0x48>

000000008000059a <printf>:
{
    8000059a:	7131                	addi	sp,sp,-192
    8000059c:	fc86                	sd	ra,120(sp)
    8000059e:	f8a2                	sd	s0,112(sp)
    800005a0:	f4a6                	sd	s1,104(sp)
    800005a2:	f0ca                	sd	s2,96(sp)
    800005a4:	ecce                	sd	s3,88(sp)
    800005a6:	e8d2                	sd	s4,80(sp)
    800005a8:	e4d6                	sd	s5,72(sp)
    800005aa:	e0da                	sd	s6,64(sp)
    800005ac:	fc5e                	sd	s7,56(sp)
    800005ae:	f862                	sd	s8,48(sp)
    800005b0:	f466                	sd	s9,40(sp)
    800005b2:	f06a                	sd	s10,32(sp)
    800005b4:	ec6e                	sd	s11,24(sp)
    800005b6:	0100                	addi	s0,sp,128
    800005b8:	8a2a                	mv	s4,a0
    800005ba:	e40c                	sd	a1,8(s0)
    800005bc:	e810                	sd	a2,16(s0)
    800005be:	ec14                	sd	a3,24(s0)
    800005c0:	f018                	sd	a4,32(s0)
    800005c2:	f41c                	sd	a5,40(s0)
    800005c4:	03043823          	sd	a6,48(s0)
    800005c8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005cc:	00011d97          	auipc	s11,0x11
    800005d0:	c64dad83          	lw	s11,-924(s11) # 80011230 <pr+0x18>
  if(locking)
    800005d4:	020d9b63          	bnez	s11,8000060a <printf+0x70>
  if (fmt == 0)
    800005d8:	040a0263          	beqz	s4,8000061c <printf+0x82>
  va_start(ap, fmt);
    800005dc:	00840793          	addi	a5,s0,8
    800005e0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005e4:	000a4503          	lbu	a0,0(s4)
    800005e8:	16050263          	beqz	a0,8000074c <printf+0x1b2>
    800005ec:	4481                	li	s1,0
    if(c != '%'){
    800005ee:	02500a93          	li	s5,37
    switch(c){
    800005f2:	07000b13          	li	s6,112
  consputc('x');
    800005f6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f8:	00008b97          	auipc	s7,0x8
    800005fc:	a48b8b93          	addi	s7,s7,-1464 # 80008040 <digits>
    switch(c){
    80000600:	07300c93          	li	s9,115
    80000604:	06400c13          	li	s8,100
    80000608:	a82d                	j	80000642 <printf+0xa8>
    acquire(&pr.lock);
    8000060a:	00011517          	auipc	a0,0x11
    8000060e:	c0e50513          	addi	a0,a0,-1010 # 80011218 <pr>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	606080e7          	jalr	1542(ra) # 80000c18 <acquire>
    8000061a:	bf7d                	j	800005d8 <printf+0x3e>
    panic("null fmt");
    8000061c:	00008517          	auipc	a0,0x8
    80000620:	a0c50513          	addi	a0,a0,-1524 # 80008028 <etext+0x28>
    80000624:	00000097          	auipc	ra,0x0
    80000628:	f2c080e7          	jalr	-212(ra) # 80000550 <panic>
      consputc(c);
    8000062c:	00000097          	auipc	ra,0x0
    80000630:	c62080e7          	jalr	-926(ra) # 8000028e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c503          	lbu	a0,0(a5)
    8000063e:	10050763          	beqz	a0,8000074c <printf+0x1b2>
    if(c != '%'){
    80000642:	ff5515e3          	bne	a0,s5,8000062c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000646:	2485                	addiw	s1,s1,1
    80000648:	009a07b3          	add	a5,s4,s1
    8000064c:	0007c783          	lbu	a5,0(a5)
    80000650:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000654:	cfe5                	beqz	a5,8000074c <printf+0x1b2>
    switch(c){
    80000656:	05678a63          	beq	a5,s6,800006aa <printf+0x110>
    8000065a:	02fb7663          	bgeu	s6,a5,80000686 <printf+0xec>
    8000065e:	09978963          	beq	a5,s9,800006f0 <printf+0x156>
    80000662:	07800713          	li	a4,120
    80000666:	0ce79863          	bne	a5,a4,80000736 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000066a:	f8843783          	ld	a5,-120(s0)
    8000066e:	00878713          	addi	a4,a5,8
    80000672:	f8e43423          	sd	a4,-120(s0)
    80000676:	4605                	li	a2,1
    80000678:	85ea                	mv	a1,s10
    8000067a:	4388                	lw	a0,0(a5)
    8000067c:	00000097          	auipc	ra,0x0
    80000680:	e32080e7          	jalr	-462(ra) # 800004ae <printint>
      break;
    80000684:	bf45                	j	80000634 <printf+0x9a>
    switch(c){
    80000686:	0b578263          	beq	a5,s5,8000072a <printf+0x190>
    8000068a:	0b879663          	bne	a5,s8,80000736 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000068e:	f8843783          	ld	a5,-120(s0)
    80000692:	00878713          	addi	a4,a5,8
    80000696:	f8e43423          	sd	a4,-120(s0)
    8000069a:	4605                	li	a2,1
    8000069c:	45a9                	li	a1,10
    8000069e:	4388                	lw	a0,0(a5)
    800006a0:	00000097          	auipc	ra,0x0
    800006a4:	e0e080e7          	jalr	-498(ra) # 800004ae <printint>
      break;
    800006a8:	b771                	j	80000634 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006aa:	f8843783          	ld	a5,-120(s0)
    800006ae:	00878713          	addi	a4,a5,8
    800006b2:	f8e43423          	sd	a4,-120(s0)
    800006b6:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ba:	03000513          	li	a0,48
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bd0080e7          	jalr	-1072(ra) # 8000028e <consputc>
  consputc('x');
    800006c6:	07800513          	li	a0,120
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bc4080e7          	jalr	-1084(ra) # 8000028e <consputc>
    800006d2:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006d4:	03c9d793          	srli	a5,s3,0x3c
    800006d8:	97de                	add	a5,a5,s7
    800006da:	0007c503          	lbu	a0,0(a5)
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	bb0080e7          	jalr	-1104(ra) # 8000028e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e6:	0992                	slli	s3,s3,0x4
    800006e8:	397d                	addiw	s2,s2,-1
    800006ea:	fe0915e3          	bnez	s2,800006d4 <printf+0x13a>
    800006ee:	b799                	j	80000634 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006f0:	f8843783          	ld	a5,-120(s0)
    800006f4:	00878713          	addi	a4,a5,8
    800006f8:	f8e43423          	sd	a4,-120(s0)
    800006fc:	0007b903          	ld	s2,0(a5)
    80000700:	00090e63          	beqz	s2,8000071c <printf+0x182>
      for(; *s; s++)
    80000704:	00094503          	lbu	a0,0(s2)
    80000708:	d515                	beqz	a0,80000634 <printf+0x9a>
        consputc(*s);
    8000070a:	00000097          	auipc	ra,0x0
    8000070e:	b84080e7          	jalr	-1148(ra) # 8000028e <consputc>
      for(; *s; s++)
    80000712:	0905                	addi	s2,s2,1
    80000714:	00094503          	lbu	a0,0(s2)
    80000718:	f96d                	bnez	a0,8000070a <printf+0x170>
    8000071a:	bf29                	j	80000634 <printf+0x9a>
        s = "(null)";
    8000071c:	00008917          	auipc	s2,0x8
    80000720:	90490913          	addi	s2,s2,-1788 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000724:	02800513          	li	a0,40
    80000728:	b7cd                	j	8000070a <printf+0x170>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b62080e7          	jalr	-1182(ra) # 8000028e <consputc>
      break;
    80000734:	b701                	j	80000634 <printf+0x9a>
      consputc('%');
    80000736:	8556                	mv	a0,s5
    80000738:	00000097          	auipc	ra,0x0
    8000073c:	b56080e7          	jalr	-1194(ra) # 8000028e <consputc>
      consputc(c);
    80000740:	854a                	mv	a0,s2
    80000742:	00000097          	auipc	ra,0x0
    80000746:	b4c080e7          	jalr	-1204(ra) # 8000028e <consputc>
      break;
    8000074a:	b5ed                	j	80000634 <printf+0x9a>
  if(locking)
    8000074c:	020d9163          	bnez	s11,8000076e <printf+0x1d4>
}
    80000750:	70e6                	ld	ra,120(sp)
    80000752:	7446                	ld	s0,112(sp)
    80000754:	74a6                	ld	s1,104(sp)
    80000756:	7906                	ld	s2,96(sp)
    80000758:	69e6                	ld	s3,88(sp)
    8000075a:	6a46                	ld	s4,80(sp)
    8000075c:	6aa6                	ld	s5,72(sp)
    8000075e:	6b06                	ld	s6,64(sp)
    80000760:	7be2                	ld	s7,56(sp)
    80000762:	7c42                	ld	s8,48(sp)
    80000764:	7ca2                	ld	s9,40(sp)
    80000766:	7d02                	ld	s10,32(sp)
    80000768:	6de2                	ld	s11,24(sp)
    8000076a:	6129                	addi	sp,sp,192
    8000076c:	8082                	ret
    release(&pr.lock);
    8000076e:	00011517          	auipc	a0,0x11
    80000772:	aaa50513          	addi	a0,a0,-1366 # 80011218 <pr>
    80000776:	00000097          	auipc	ra,0x0
    8000077a:	556080e7          	jalr	1366(ra) # 80000ccc <release>
}
    8000077e:	bfc9                	j	80000750 <printf+0x1b6>

0000000080000780 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000780:	1101                	addi	sp,sp,-32
    80000782:	ec06                	sd	ra,24(sp)
    80000784:	e822                	sd	s0,16(sp)
    80000786:	e426                	sd	s1,8(sp)
    80000788:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000078a:	00011497          	auipc	s1,0x11
    8000078e:	a8e48493          	addi	s1,s1,-1394 # 80011218 <pr>
    80000792:	00008597          	auipc	a1,0x8
    80000796:	8a658593          	addi	a1,a1,-1882 # 80008038 <etext+0x38>
    8000079a:	8526                	mv	a0,s1
    8000079c:	00000097          	auipc	ra,0x0
    800007a0:	3ec080e7          	jalr	1004(ra) # 80000b88 <initlock>
  pr.locking = 1;
    800007a4:	4785                	li	a5,1
    800007a6:	cc9c                	sw	a5,24(s1)
}
    800007a8:	60e2                	ld	ra,24(sp)
    800007aa:	6442                	ld	s0,16(sp)
    800007ac:	64a2                	ld	s1,8(sp)
    800007ae:	6105                	addi	sp,sp,32
    800007b0:	8082                	ret

00000000800007b2 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007b2:	1141                	addi	sp,sp,-16
    800007b4:	e406                	sd	ra,8(sp)
    800007b6:	e022                	sd	s0,0(sp)
    800007b8:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ba:	100007b7          	lui	a5,0x10000
    800007be:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007c2:	f8000713          	li	a4,-128
    800007c6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ca:	470d                	li	a4,3
    800007cc:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007d0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007d4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d8:	469d                	li	a3,7
    800007da:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007de:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007e2:	00008597          	auipc	a1,0x8
    800007e6:	87658593          	addi	a1,a1,-1930 # 80008058 <digits+0x18>
    800007ea:	00011517          	auipc	a0,0x11
    800007ee:	a4e50513          	addi	a0,a0,-1458 # 80011238 <uart_tx_lock>
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	396080e7          	jalr	918(ra) # 80000b88 <initlock>
}
    800007fa:	60a2                	ld	ra,8(sp)
    800007fc:	6402                	ld	s0,0(sp)
    800007fe:	0141                	addi	sp,sp,16
    80000800:	8082                	ret

0000000080000802 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000802:	1101                	addi	sp,sp,-32
    80000804:	ec06                	sd	ra,24(sp)
    80000806:	e822                	sd	s0,16(sp)
    80000808:	e426                	sd	s1,8(sp)
    8000080a:	1000                	addi	s0,sp,32
    8000080c:	84aa                	mv	s1,a0
  push_off();
    8000080e:	00000097          	auipc	ra,0x0
    80000812:	3be080e7          	jalr	958(ra) # 80000bcc <push_off>

  if(panicked){
    80000816:	00008797          	auipc	a5,0x8
    8000081a:	7ea7a783          	lw	a5,2026(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	10000737          	lui	a4,0x10000
  if(panicked){
    80000822:	c391                	beqz	a5,80000826 <uartputc_sync+0x24>
    for(;;)
    80000824:	a001                	j	80000824 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000826:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000082a:	0ff7f793          	andi	a5,a5,255
    8000082e:	0207f793          	andi	a5,a5,32
    80000832:	dbf5                	beqz	a5,80000826 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000834:	0ff4f793          	andi	a5,s1,255
    80000838:	10000737          	lui	a4,0x10000
    8000083c:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000840:	00000097          	auipc	ra,0x0
    80000844:	42c080e7          	jalr	1068(ra) # 80000c6c <pop_off>
}
    80000848:	60e2                	ld	ra,24(sp)
    8000084a:	6442                	ld	s0,16(sp)
    8000084c:	64a2                	ld	s1,8(sp)
    8000084e:	6105                	addi	sp,sp,32
    80000850:	8082                	ret

0000000080000852 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000852:	00008797          	auipc	a5,0x8
    80000856:	7b27a783          	lw	a5,1970(a5) # 80009004 <uart_tx_r>
    8000085a:	00008717          	auipc	a4,0x8
    8000085e:	7ae72703          	lw	a4,1966(a4) # 80009008 <uart_tx_w>
    80000862:	08f70263          	beq	a4,a5,800008e6 <uartstart+0x94>
{
    80000866:	7139                	addi	sp,sp,-64
    80000868:	fc06                	sd	ra,56(sp)
    8000086a:	f822                	sd	s0,48(sp)
    8000086c:	f426                	sd	s1,40(sp)
    8000086e:	f04a                	sd	s2,32(sp)
    80000870:	ec4e                	sd	s3,24(sp)
    80000872:	e852                	sd	s4,16(sp)
    80000874:	e456                	sd	s5,8(sp)
    80000876:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    8000087c:	00011a17          	auipc	s4,0x11
    80000880:	9bca0a13          	addi	s4,s4,-1604 # 80011238 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000884:	00008497          	auipc	s1,0x8
    80000888:	78048493          	addi	s1,s1,1920 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000088c:	00008997          	auipc	s3,0x8
    80000890:	77c98993          	addi	s3,s3,1916 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000894:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000898:	0ff77713          	andi	a4,a4,255
    8000089c:	02077713          	andi	a4,a4,32
    800008a0:	cb15                	beqz	a4,800008d4 <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    800008a2:	00fa0733          	add	a4,s4,a5
    800008a6:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008aa:	2785                	addiw	a5,a5,1
    800008ac:	41f7d71b          	sraiw	a4,a5,0x1f
    800008b0:	01b7571b          	srliw	a4,a4,0x1b
    800008b4:	9fb9                	addw	a5,a5,a4
    800008b6:	8bfd                	andi	a5,a5,31
    800008b8:	9f99                	subw	a5,a5,a4
    800008ba:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008bc:	8526                	mv	a0,s1
    800008be:	00002097          	auipc	ra,0x2
    800008c2:	ab6080e7          	jalr	-1354(ra) # 80002374 <wakeup>
    
    WriteReg(THR, c);
    800008c6:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ca:	409c                	lw	a5,0(s1)
    800008cc:	0009a703          	lw	a4,0(s3)
    800008d0:	fcf712e3          	bne	a4,a5,80000894 <uartstart+0x42>
  }
}
    800008d4:	70e2                	ld	ra,56(sp)
    800008d6:	7442                	ld	s0,48(sp)
    800008d8:	74a2                	ld	s1,40(sp)
    800008da:	7902                	ld	s2,32(sp)
    800008dc:	69e2                	ld	s3,24(sp)
    800008de:	6a42                	ld	s4,16(sp)
    800008e0:	6aa2                	ld	s5,8(sp)
    800008e2:	6121                	addi	sp,sp,64
    800008e4:	8082                	ret
    800008e6:	8082                	ret

00000000800008e8 <uartputc>:
{
    800008e8:	7179                	addi	sp,sp,-48
    800008ea:	f406                	sd	ra,40(sp)
    800008ec:	f022                	sd	s0,32(sp)
    800008ee:	ec26                	sd	s1,24(sp)
    800008f0:	e84a                	sd	s2,16(sp)
    800008f2:	e44e                	sd	s3,8(sp)
    800008f4:	e052                	sd	s4,0(sp)
    800008f6:	1800                	addi	s0,sp,48
    800008f8:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008fa:	00011517          	auipc	a0,0x11
    800008fe:	93e50513          	addi	a0,a0,-1730 # 80011238 <uart_tx_lock>
    80000902:	00000097          	auipc	ra,0x0
    80000906:	316080e7          	jalr	790(ra) # 80000c18 <acquire>
  if(panicked){
    8000090a:	00008797          	auipc	a5,0x8
    8000090e:	6f67a783          	lw	a5,1782(a5) # 80009000 <panicked>
    80000912:	c391                	beqz	a5,80000916 <uartputc+0x2e>
    for(;;)
    80000914:	a001                	j	80000914 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000916:	00008717          	auipc	a4,0x8
    8000091a:	6f272703          	lw	a4,1778(a4) # 80009008 <uart_tx_w>
    8000091e:	0017079b          	addiw	a5,a4,1
    80000922:	41f7d69b          	sraiw	a3,a5,0x1f
    80000926:	01b6d69b          	srliw	a3,a3,0x1b
    8000092a:	9fb5                	addw	a5,a5,a3
    8000092c:	8bfd                	andi	a5,a5,31
    8000092e:	9f95                	subw	a5,a5,a3
    80000930:	00008697          	auipc	a3,0x8
    80000934:	6d46a683          	lw	a3,1748(a3) # 80009004 <uart_tx_r>
    80000938:	04f69263          	bne	a3,a5,8000097c <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000093c:	00011a17          	auipc	s4,0x11
    80000940:	8fca0a13          	addi	s4,s4,-1796 # 80011238 <uart_tx_lock>
    80000944:	00008497          	auipc	s1,0x8
    80000948:	6c048493          	addi	s1,s1,1728 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000094c:	00008917          	auipc	s2,0x8
    80000950:	6bc90913          	addi	s2,s2,1724 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000954:	85d2                	mv	a1,s4
    80000956:	8526                	mv	a0,s1
    80000958:	00002097          	auipc	ra,0x2
    8000095c:	896080e7          	jalr	-1898(ra) # 800021ee <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000960:	00092703          	lw	a4,0(s2)
    80000964:	0017079b          	addiw	a5,a4,1
    80000968:	41f7d69b          	sraiw	a3,a5,0x1f
    8000096c:	01b6d69b          	srliw	a3,a3,0x1b
    80000970:	9fb5                	addw	a5,a5,a3
    80000972:	8bfd                	andi	a5,a5,31
    80000974:	9f95                	subw	a5,a5,a3
    80000976:	4094                	lw	a3,0(s1)
    80000978:	fcf68ee3          	beq	a3,a5,80000954 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    8000097c:	00011497          	auipc	s1,0x11
    80000980:	8bc48493          	addi	s1,s1,-1860 # 80011238 <uart_tx_lock>
    80000984:	9726                	add	a4,a4,s1
    80000986:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    8000098a:	00008717          	auipc	a4,0x8
    8000098e:	66f72f23          	sw	a5,1662(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000992:	00000097          	auipc	ra,0x0
    80000996:	ec0080e7          	jalr	-320(ra) # 80000852 <uartstart>
      release(&uart_tx_lock);
    8000099a:	8526                	mv	a0,s1
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	330080e7          	jalr	816(ra) # 80000ccc <release>
}
    800009a4:	70a2                	ld	ra,40(sp)
    800009a6:	7402                	ld	s0,32(sp)
    800009a8:	64e2                	ld	s1,24(sp)
    800009aa:	6942                	ld	s2,16(sp)
    800009ac:	69a2                	ld	s3,8(sp)
    800009ae:	6a02                	ld	s4,0(sp)
    800009b0:	6145                	addi	sp,sp,48
    800009b2:	8082                	ret

00000000800009b4 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009b4:	1141                	addi	sp,sp,-16
    800009b6:	e422                	sd	s0,8(sp)
    800009b8:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009ba:	100007b7          	lui	a5,0x10000
    800009be:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009c2:	8b85                	andi	a5,a5,1
    800009c4:	cb91                	beqz	a5,800009d8 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009c6:	100007b7          	lui	a5,0x10000
    800009ca:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009ce:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009d2:	6422                	ld	s0,8(sp)
    800009d4:	0141                	addi	sp,sp,16
    800009d6:	8082                	ret
    return -1;
    800009d8:	557d                	li	a0,-1
    800009da:	bfe5                	j	800009d2 <uartgetc+0x1e>

00000000800009dc <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009dc:	1101                	addi	sp,sp,-32
    800009de:	ec06                	sd	ra,24(sp)
    800009e0:	e822                	sd	s0,16(sp)
    800009e2:	e426                	sd	s1,8(sp)
    800009e4:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009e6:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e8:	00000097          	auipc	ra,0x0
    800009ec:	fcc080e7          	jalr	-52(ra) # 800009b4 <uartgetc>
    if(c == -1)
    800009f0:	00950763          	beq	a0,s1,800009fe <uartintr+0x22>
      break;
    consoleintr(c);
    800009f4:	00000097          	auipc	ra,0x0
    800009f8:	8dc080e7          	jalr	-1828(ra) # 800002d0 <consoleintr>
  while(1){
    800009fc:	b7f5                	j	800009e8 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009fe:	00011497          	auipc	s1,0x11
    80000a02:	83a48493          	addi	s1,s1,-1990 # 80011238 <uart_tx_lock>
    80000a06:	8526                	mv	a0,s1
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	210080e7          	jalr	528(ra) # 80000c18 <acquire>
  uartstart();
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	e42080e7          	jalr	-446(ra) # 80000852 <uartstart>
  release(&uart_tx_lock);
    80000a18:	8526                	mv	a0,s1
    80000a1a:	00000097          	auipc	ra,0x0
    80000a1e:	2b2080e7          	jalr	690(ra) # 80000ccc <release>
}
    80000a22:	60e2                	ld	ra,24(sp)
    80000a24:	6442                	ld	s0,16(sp)
    80000a26:	64a2                	ld	s1,8(sp)
    80000a28:	6105                	addi	sp,sp,32
    80000a2a:	8082                	ret

0000000080000a2c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a2c:	1101                	addi	sp,sp,-32
    80000a2e:	ec06                	sd	ra,24(sp)
    80000a30:	e822                	sd	s0,16(sp)
    80000a32:	e426                	sd	s1,8(sp)
    80000a34:	e04a                	sd	s2,0(sp)
    80000a36:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a38:	03451793          	slli	a5,a0,0x34
    80000a3c:	ebb9                	bnez	a5,80000a92 <kfree+0x66>
    80000a3e:	84aa                	mv	s1,a0
    80000a40:	00025797          	auipc	a5,0x25
    80000a44:	5c078793          	addi	a5,a5,1472 # 80026000 <end>
    80000a48:	04f56563          	bltu	a0,a5,80000a92 <kfree+0x66>
    80000a4c:	47c5                	li	a5,17
    80000a4e:	07ee                	slli	a5,a5,0x1b
    80000a50:	04f57163          	bgeu	a0,a5,80000a92 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a54:	6605                	lui	a2,0x1
    80000a56:	4585                	li	a1,1
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	2bc080e7          	jalr	700(ra) # 80000d14 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a60:	00011917          	auipc	s2,0x11
    80000a64:	81090913          	addi	s2,s2,-2032 # 80011270 <kmem>
    80000a68:	854a                	mv	a0,s2
    80000a6a:	00000097          	auipc	ra,0x0
    80000a6e:	1ae080e7          	jalr	430(ra) # 80000c18 <acquire>
  r->next = kmem.freelist;
    80000a72:	01893783          	ld	a5,24(s2)
    80000a76:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a78:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a7c:	854a                	mv	a0,s2
    80000a7e:	00000097          	auipc	ra,0x0
    80000a82:	24e080e7          	jalr	590(ra) # 80000ccc <release>
}
    80000a86:	60e2                	ld	ra,24(sp)
    80000a88:	6442                	ld	s0,16(sp)
    80000a8a:	64a2                	ld	s1,8(sp)
    80000a8c:	6902                	ld	s2,0(sp)
    80000a8e:	6105                	addi	sp,sp,32
    80000a90:	8082                	ret
    panic("kfree");
    80000a92:	00007517          	auipc	a0,0x7
    80000a96:	5ce50513          	addi	a0,a0,1486 # 80008060 <digits+0x20>
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	ab6080e7          	jalr	-1354(ra) # 80000550 <panic>

0000000080000aa2 <freerange>:
{
    80000aa2:	7179                	addi	sp,sp,-48
    80000aa4:	f406                	sd	ra,40(sp)
    80000aa6:	f022                	sd	s0,32(sp)
    80000aa8:	ec26                	sd	s1,24(sp)
    80000aaa:	e84a                	sd	s2,16(sp)
    80000aac:	e44e                	sd	s3,8(sp)
    80000aae:	e052                	sd	s4,0(sp)
    80000ab0:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ab2:	6785                	lui	a5,0x1
    80000ab4:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ab8:	94aa                	add	s1,s1,a0
    80000aba:	757d                	lui	a0,0xfffff
    80000abc:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000abe:	94be                	add	s1,s1,a5
    80000ac0:	0095ee63          	bltu	a1,s1,80000adc <freerange+0x3a>
    80000ac4:	892e                	mv	s2,a1
    kfree(p);
    80000ac6:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac8:	6985                	lui	s3,0x1
    kfree(p);
    80000aca:	01448533          	add	a0,s1,s4
    80000ace:	00000097          	auipc	ra,0x0
    80000ad2:	f5e080e7          	jalr	-162(ra) # 80000a2c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ad6:	94ce                	add	s1,s1,s3
    80000ad8:	fe9979e3          	bgeu	s2,s1,80000aca <freerange+0x28>
}
    80000adc:	70a2                	ld	ra,40(sp)
    80000ade:	7402                	ld	s0,32(sp)
    80000ae0:	64e2                	ld	s1,24(sp)
    80000ae2:	6942                	ld	s2,16(sp)
    80000ae4:	69a2                	ld	s3,8(sp)
    80000ae6:	6a02                	ld	s4,0(sp)
    80000ae8:	6145                	addi	sp,sp,48
    80000aea:	8082                	ret

0000000080000aec <kinit>:
{
    80000aec:	1141                	addi	sp,sp,-16
    80000aee:	e406                	sd	ra,8(sp)
    80000af0:	e022                	sd	s0,0(sp)
    80000af2:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000af4:	00007597          	auipc	a1,0x7
    80000af8:	57458593          	addi	a1,a1,1396 # 80008068 <digits+0x28>
    80000afc:	00010517          	auipc	a0,0x10
    80000b00:	77450513          	addi	a0,a0,1908 # 80011270 <kmem>
    80000b04:	00000097          	auipc	ra,0x0
    80000b08:	084080e7          	jalr	132(ra) # 80000b88 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b0c:	45c5                	li	a1,17
    80000b0e:	05ee                	slli	a1,a1,0x1b
    80000b10:	00025517          	auipc	a0,0x25
    80000b14:	4f050513          	addi	a0,a0,1264 # 80026000 <end>
    80000b18:	00000097          	auipc	ra,0x0
    80000b1c:	f8a080e7          	jalr	-118(ra) # 80000aa2 <freerange>
}
    80000b20:	60a2                	ld	ra,8(sp)
    80000b22:	6402                	ld	s0,0(sp)
    80000b24:	0141                	addi	sp,sp,16
    80000b26:	8082                	ret

0000000080000b28 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b28:	1101                	addi	sp,sp,-32
    80000b2a:	ec06                	sd	ra,24(sp)
    80000b2c:	e822                	sd	s0,16(sp)
    80000b2e:	e426                	sd	s1,8(sp)
    80000b30:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b32:	00010497          	auipc	s1,0x10
    80000b36:	73e48493          	addi	s1,s1,1854 # 80011270 <kmem>
    80000b3a:	8526                	mv	a0,s1
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	0dc080e7          	jalr	220(ra) # 80000c18 <acquire>
  r = kmem.freelist;
    80000b44:	6c84                	ld	s1,24(s1)
  if(r)
    80000b46:	c885                	beqz	s1,80000b76 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b48:	609c                	ld	a5,0(s1)
    80000b4a:	00010517          	auipc	a0,0x10
    80000b4e:	72650513          	addi	a0,a0,1830 # 80011270 <kmem>
    80000b52:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b54:	00000097          	auipc	ra,0x0
    80000b58:	178080e7          	jalr	376(ra) # 80000ccc <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b5c:	6605                	lui	a2,0x1
    80000b5e:	4595                	li	a1,5
    80000b60:	8526                	mv	a0,s1
    80000b62:	00000097          	auipc	ra,0x0
    80000b66:	1b2080e7          	jalr	434(ra) # 80000d14 <memset>
  return (void*)r;
}
    80000b6a:	8526                	mv	a0,s1
    80000b6c:	60e2                	ld	ra,24(sp)
    80000b6e:	6442                	ld	s0,16(sp)
    80000b70:	64a2                	ld	s1,8(sp)
    80000b72:	6105                	addi	sp,sp,32
    80000b74:	8082                	ret
  release(&kmem.lock);
    80000b76:	00010517          	auipc	a0,0x10
    80000b7a:	6fa50513          	addi	a0,a0,1786 # 80011270 <kmem>
    80000b7e:	00000097          	auipc	ra,0x0
    80000b82:	14e080e7          	jalr	334(ra) # 80000ccc <release>
  if(r)
    80000b86:	b7d5                	j	80000b6a <kalloc+0x42>

0000000080000b88 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b88:	1141                	addi	sp,sp,-16
    80000b8a:	e422                	sd	s0,8(sp)
    80000b8c:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b8e:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b90:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b94:	00053823          	sd	zero,16(a0)
}
    80000b98:	6422                	ld	s0,8(sp)
    80000b9a:	0141                	addi	sp,sp,16
    80000b9c:	8082                	ret

0000000080000b9e <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b9e:	411c                	lw	a5,0(a0)
    80000ba0:	e399                	bnez	a5,80000ba6 <holding+0x8>
    80000ba2:	4501                	li	a0,0
  return r;
}
    80000ba4:	8082                	ret
{
    80000ba6:	1101                	addi	sp,sp,-32
    80000ba8:	ec06                	sd	ra,24(sp)
    80000baa:	e822                	sd	s0,16(sp)
    80000bac:	e426                	sd	s1,8(sp)
    80000bae:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bb0:	6904                	ld	s1,16(a0)
    80000bb2:	00001097          	auipc	ra,0x1
    80000bb6:	e34080e7          	jalr	-460(ra) # 800019e6 <mycpu>
    80000bba:	40a48533          	sub	a0,s1,a0
    80000bbe:	00153513          	seqz	a0,a0
}
    80000bc2:	60e2                	ld	ra,24(sp)
    80000bc4:	6442                	ld	s0,16(sp)
    80000bc6:	64a2                	ld	s1,8(sp)
    80000bc8:	6105                	addi	sp,sp,32
    80000bca:	8082                	ret

0000000080000bcc <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bcc:	1101                	addi	sp,sp,-32
    80000bce:	ec06                	sd	ra,24(sp)
    80000bd0:	e822                	sd	s0,16(sp)
    80000bd2:	e426                	sd	s1,8(sp)
    80000bd4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bd6:	100024f3          	csrr	s1,sstatus
    80000bda:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bde:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000be0:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000be4:	00001097          	auipc	ra,0x1
    80000be8:	e02080e7          	jalr	-510(ra) # 800019e6 <mycpu>
    80000bec:	5d3c                	lw	a5,120(a0)
    80000bee:	cf89                	beqz	a5,80000c08 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bf0:	00001097          	auipc	ra,0x1
    80000bf4:	df6080e7          	jalr	-522(ra) # 800019e6 <mycpu>
    80000bf8:	5d3c                	lw	a5,120(a0)
    80000bfa:	2785                	addiw	a5,a5,1
    80000bfc:	dd3c                	sw	a5,120(a0)
}
    80000bfe:	60e2                	ld	ra,24(sp)
    80000c00:	6442                	ld	s0,16(sp)
    80000c02:	64a2                	ld	s1,8(sp)
    80000c04:	6105                	addi	sp,sp,32
    80000c06:	8082                	ret
    mycpu()->intena = old;
    80000c08:	00001097          	auipc	ra,0x1
    80000c0c:	dde080e7          	jalr	-546(ra) # 800019e6 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c10:	8085                	srli	s1,s1,0x1
    80000c12:	8885                	andi	s1,s1,1
    80000c14:	dd64                	sw	s1,124(a0)
    80000c16:	bfe9                	j	80000bf0 <push_off+0x24>

0000000080000c18 <acquire>:
{
    80000c18:	1101                	addi	sp,sp,-32
    80000c1a:	ec06                	sd	ra,24(sp)
    80000c1c:	e822                	sd	s0,16(sp)
    80000c1e:	e426                	sd	s1,8(sp)
    80000c20:	1000                	addi	s0,sp,32
    80000c22:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c24:	00000097          	auipc	ra,0x0
    80000c28:	fa8080e7          	jalr	-88(ra) # 80000bcc <push_off>
  if(holding(lk))
    80000c2c:	8526                	mv	a0,s1
    80000c2e:	00000097          	auipc	ra,0x0
    80000c32:	f70080e7          	jalr	-144(ra) # 80000b9e <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c36:	4705                	li	a4,1
  if(holding(lk))
    80000c38:	e115                	bnez	a0,80000c5c <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c3a:	87ba                	mv	a5,a4
    80000c3c:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c40:	2781                	sext.w	a5,a5
    80000c42:	ffe5                	bnez	a5,80000c3a <acquire+0x22>
  __sync_synchronize();
    80000c44:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c48:	00001097          	auipc	ra,0x1
    80000c4c:	d9e080e7          	jalr	-610(ra) # 800019e6 <mycpu>
    80000c50:	e888                	sd	a0,16(s1)
}
    80000c52:	60e2                	ld	ra,24(sp)
    80000c54:	6442                	ld	s0,16(sp)
    80000c56:	64a2                	ld	s1,8(sp)
    80000c58:	6105                	addi	sp,sp,32
    80000c5a:	8082                	ret
    panic("acquire");
    80000c5c:	00007517          	auipc	a0,0x7
    80000c60:	41450513          	addi	a0,a0,1044 # 80008070 <digits+0x30>
    80000c64:	00000097          	auipc	ra,0x0
    80000c68:	8ec080e7          	jalr	-1812(ra) # 80000550 <panic>

0000000080000c6c <pop_off>:

void
pop_off(void)
{
    80000c6c:	1141                	addi	sp,sp,-16
    80000c6e:	e406                	sd	ra,8(sp)
    80000c70:	e022                	sd	s0,0(sp)
    80000c72:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c74:	00001097          	auipc	ra,0x1
    80000c78:	d72080e7          	jalr	-654(ra) # 800019e6 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c7c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c80:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c82:	e78d                	bnez	a5,80000cac <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c84:	5d3c                	lw	a5,120(a0)
    80000c86:	02f05b63          	blez	a5,80000cbc <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c8a:	37fd                	addiw	a5,a5,-1
    80000c8c:	0007871b          	sext.w	a4,a5
    80000c90:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c92:	eb09                	bnez	a4,80000ca4 <pop_off+0x38>
    80000c94:	5d7c                	lw	a5,124(a0)
    80000c96:	c799                	beqz	a5,80000ca4 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c9c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ca0:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000ca4:	60a2                	ld	ra,8(sp)
    80000ca6:	6402                	ld	s0,0(sp)
    80000ca8:	0141                	addi	sp,sp,16
    80000caa:	8082                	ret
    panic("pop_off - interruptible");
    80000cac:	00007517          	auipc	a0,0x7
    80000cb0:	3cc50513          	addi	a0,a0,972 # 80008078 <digits+0x38>
    80000cb4:	00000097          	auipc	ra,0x0
    80000cb8:	89c080e7          	jalr	-1892(ra) # 80000550 <panic>
    panic("pop_off");
    80000cbc:	00007517          	auipc	a0,0x7
    80000cc0:	3d450513          	addi	a0,a0,980 # 80008090 <digits+0x50>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	88c080e7          	jalr	-1908(ra) # 80000550 <panic>

0000000080000ccc <release>:
{
    80000ccc:	1101                	addi	sp,sp,-32
    80000cce:	ec06                	sd	ra,24(sp)
    80000cd0:	e822                	sd	s0,16(sp)
    80000cd2:	e426                	sd	s1,8(sp)
    80000cd4:	1000                	addi	s0,sp,32
    80000cd6:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	ec6080e7          	jalr	-314(ra) # 80000b9e <holding>
    80000ce0:	c115                	beqz	a0,80000d04 <release+0x38>
  lk->cpu = 0;
    80000ce2:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ce6:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cea:	0f50000f          	fence	iorw,ow
    80000cee:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cf2:	00000097          	auipc	ra,0x0
    80000cf6:	f7a080e7          	jalr	-134(ra) # 80000c6c <pop_off>
}
    80000cfa:	60e2                	ld	ra,24(sp)
    80000cfc:	6442                	ld	s0,16(sp)
    80000cfe:	64a2                	ld	s1,8(sp)
    80000d00:	6105                	addi	sp,sp,32
    80000d02:	8082                	ret
    panic("release");
    80000d04:	00007517          	auipc	a0,0x7
    80000d08:	39450513          	addi	a0,a0,916 # 80008098 <digits+0x58>
    80000d0c:	00000097          	auipc	ra,0x0
    80000d10:	844080e7          	jalr	-1980(ra) # 80000550 <panic>

0000000080000d14 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d14:	1141                	addi	sp,sp,-16
    80000d16:	e422                	sd	s0,8(sp)
    80000d18:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d1a:	ce09                	beqz	a2,80000d34 <memset+0x20>
    80000d1c:	87aa                	mv	a5,a0
    80000d1e:	fff6071b          	addiw	a4,a2,-1
    80000d22:	1702                	slli	a4,a4,0x20
    80000d24:	9301                	srli	a4,a4,0x20
    80000d26:	0705                	addi	a4,a4,1
    80000d28:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d2a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d2e:	0785                	addi	a5,a5,1
    80000d30:	fee79de3          	bne	a5,a4,80000d2a <memset+0x16>
  }
  return dst;
}
    80000d34:	6422                	ld	s0,8(sp)
    80000d36:	0141                	addi	sp,sp,16
    80000d38:	8082                	ret

0000000080000d3a <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d3a:	1141                	addi	sp,sp,-16
    80000d3c:	e422                	sd	s0,8(sp)
    80000d3e:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d40:	ca05                	beqz	a2,80000d70 <memcmp+0x36>
    80000d42:	fff6069b          	addiw	a3,a2,-1
    80000d46:	1682                	slli	a3,a3,0x20
    80000d48:	9281                	srli	a3,a3,0x20
    80000d4a:	0685                	addi	a3,a3,1
    80000d4c:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d4e:	00054783          	lbu	a5,0(a0)
    80000d52:	0005c703          	lbu	a4,0(a1)
    80000d56:	00e79863          	bne	a5,a4,80000d66 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d5a:	0505                	addi	a0,a0,1
    80000d5c:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d5e:	fed518e3          	bne	a0,a3,80000d4e <memcmp+0x14>
  }

  return 0;
    80000d62:	4501                	li	a0,0
    80000d64:	a019                	j	80000d6a <memcmp+0x30>
      return *s1 - *s2;
    80000d66:	40e7853b          	subw	a0,a5,a4
}
    80000d6a:	6422                	ld	s0,8(sp)
    80000d6c:	0141                	addi	sp,sp,16
    80000d6e:	8082                	ret
  return 0;
    80000d70:	4501                	li	a0,0
    80000d72:	bfe5                	j	80000d6a <memcmp+0x30>

0000000080000d74 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d74:	1141                	addi	sp,sp,-16
    80000d76:	e422                	sd	s0,8(sp)
    80000d78:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d7a:	00a5f963          	bgeu	a1,a0,80000d8c <memmove+0x18>
    80000d7e:	02061713          	slli	a4,a2,0x20
    80000d82:	9301                	srli	a4,a4,0x20
    80000d84:	00e587b3          	add	a5,a1,a4
    80000d88:	02f56563          	bltu	a0,a5,80000db2 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d8c:	fff6069b          	addiw	a3,a2,-1
    80000d90:	ce11                	beqz	a2,80000dac <memmove+0x38>
    80000d92:	1682                	slli	a3,a3,0x20
    80000d94:	9281                	srli	a3,a3,0x20
    80000d96:	0685                	addi	a3,a3,1
    80000d98:	96ae                	add	a3,a3,a1
    80000d9a:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d9c:	0585                	addi	a1,a1,1
    80000d9e:	0785                	addi	a5,a5,1
    80000da0:	fff5c703          	lbu	a4,-1(a1)
    80000da4:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000da8:	fed59ae3          	bne	a1,a3,80000d9c <memmove+0x28>

  return dst;
}
    80000dac:	6422                	ld	s0,8(sp)
    80000dae:	0141                	addi	sp,sp,16
    80000db0:	8082                	ret
    d += n;
    80000db2:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000db4:	fff6069b          	addiw	a3,a2,-1
    80000db8:	da75                	beqz	a2,80000dac <memmove+0x38>
    80000dba:	02069613          	slli	a2,a3,0x20
    80000dbe:	9201                	srli	a2,a2,0x20
    80000dc0:	fff64613          	not	a2,a2
    80000dc4:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dc6:	17fd                	addi	a5,a5,-1
    80000dc8:	177d                	addi	a4,a4,-1
    80000dca:	0007c683          	lbu	a3,0(a5)
    80000dce:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dd2:	fec79ae3          	bne	a5,a2,80000dc6 <memmove+0x52>
    80000dd6:	bfd9                	j	80000dac <memmove+0x38>

0000000080000dd8 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e406                	sd	ra,8(sp)
    80000ddc:	e022                	sd	s0,0(sp)
    80000dde:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000de0:	00000097          	auipc	ra,0x0
    80000de4:	f94080e7          	jalr	-108(ra) # 80000d74 <memmove>
}
    80000de8:	60a2                	ld	ra,8(sp)
    80000dea:	6402                	ld	s0,0(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret

0000000080000df0 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000df0:	1141                	addi	sp,sp,-16
    80000df2:	e422                	sd	s0,8(sp)
    80000df4:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000df6:	ce11                	beqz	a2,80000e12 <strncmp+0x22>
    80000df8:	00054783          	lbu	a5,0(a0)
    80000dfc:	cf89                	beqz	a5,80000e16 <strncmp+0x26>
    80000dfe:	0005c703          	lbu	a4,0(a1)
    80000e02:	00f71a63          	bne	a4,a5,80000e16 <strncmp+0x26>
    n--, p++, q++;
    80000e06:	367d                	addiw	a2,a2,-1
    80000e08:	0505                	addi	a0,a0,1
    80000e0a:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e0c:	f675                	bnez	a2,80000df8 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e0e:	4501                	li	a0,0
    80000e10:	a809                	j	80000e22 <strncmp+0x32>
    80000e12:	4501                	li	a0,0
    80000e14:	a039                	j	80000e22 <strncmp+0x32>
  if(n == 0)
    80000e16:	ca09                	beqz	a2,80000e28 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e18:	00054503          	lbu	a0,0(a0)
    80000e1c:	0005c783          	lbu	a5,0(a1)
    80000e20:	9d1d                	subw	a0,a0,a5
}
    80000e22:	6422                	ld	s0,8(sp)
    80000e24:	0141                	addi	sp,sp,16
    80000e26:	8082                	ret
    return 0;
    80000e28:	4501                	li	a0,0
    80000e2a:	bfe5                	j	80000e22 <strncmp+0x32>

0000000080000e2c <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e2c:	1141                	addi	sp,sp,-16
    80000e2e:	e422                	sd	s0,8(sp)
    80000e30:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e32:	872a                	mv	a4,a0
    80000e34:	8832                	mv	a6,a2
    80000e36:	367d                	addiw	a2,a2,-1
    80000e38:	01005963          	blez	a6,80000e4a <strncpy+0x1e>
    80000e3c:	0705                	addi	a4,a4,1
    80000e3e:	0005c783          	lbu	a5,0(a1)
    80000e42:	fef70fa3          	sb	a5,-1(a4)
    80000e46:	0585                	addi	a1,a1,1
    80000e48:	f7f5                	bnez	a5,80000e34 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e4a:	00c05d63          	blez	a2,80000e64 <strncpy+0x38>
    80000e4e:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e50:	0685                	addi	a3,a3,1
    80000e52:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e56:	fff6c793          	not	a5,a3
    80000e5a:	9fb9                	addw	a5,a5,a4
    80000e5c:	010787bb          	addw	a5,a5,a6
    80000e60:	fef048e3          	bgtz	a5,80000e50 <strncpy+0x24>
  return os;
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret

0000000080000e6a <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e70:	02c05363          	blez	a2,80000e96 <safestrcpy+0x2c>
    80000e74:	fff6069b          	addiw	a3,a2,-1
    80000e78:	1682                	slli	a3,a3,0x20
    80000e7a:	9281                	srli	a3,a3,0x20
    80000e7c:	96ae                	add	a3,a3,a1
    80000e7e:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e80:	00d58963          	beq	a1,a3,80000e92 <safestrcpy+0x28>
    80000e84:	0585                	addi	a1,a1,1
    80000e86:	0785                	addi	a5,a5,1
    80000e88:	fff5c703          	lbu	a4,-1(a1)
    80000e8c:	fee78fa3          	sb	a4,-1(a5)
    80000e90:	fb65                	bnez	a4,80000e80 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e92:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e96:	6422                	ld	s0,8(sp)
    80000e98:	0141                	addi	sp,sp,16
    80000e9a:	8082                	ret

0000000080000e9c <strlen>:

int
strlen(const char *s)
{
    80000e9c:	1141                	addi	sp,sp,-16
    80000e9e:	e422                	sd	s0,8(sp)
    80000ea0:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ea2:	00054783          	lbu	a5,0(a0)
    80000ea6:	cf91                	beqz	a5,80000ec2 <strlen+0x26>
    80000ea8:	0505                	addi	a0,a0,1
    80000eaa:	87aa                	mv	a5,a0
    80000eac:	4685                	li	a3,1
    80000eae:	9e89                	subw	a3,a3,a0
    80000eb0:	00f6853b          	addw	a0,a3,a5
    80000eb4:	0785                	addi	a5,a5,1
    80000eb6:	fff7c703          	lbu	a4,-1(a5)
    80000eba:	fb7d                	bnez	a4,80000eb0 <strlen+0x14>
    ;
  return n;
}
    80000ebc:	6422                	ld	s0,8(sp)
    80000ebe:	0141                	addi	sp,sp,16
    80000ec0:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ec2:	4501                	li	a0,0
    80000ec4:	bfe5                	j	80000ebc <strlen+0x20>

0000000080000ec6 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ec6:	1141                	addi	sp,sp,-16
    80000ec8:	e406                	sd	ra,8(sp)
    80000eca:	e022                	sd	s0,0(sp)
    80000ecc:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	b08080e7          	jalr	-1272(ra) # 800019d6 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ed6:	00008717          	auipc	a4,0x8
    80000eda:	13670713          	addi	a4,a4,310 # 8000900c <started>
  if(cpuid() == 0){
    80000ede:	c139                	beqz	a0,80000f24 <main+0x5e>
    while(started == 0)
    80000ee0:	431c                	lw	a5,0(a4)
    80000ee2:	2781                	sext.w	a5,a5
    80000ee4:	dff5                	beqz	a5,80000ee0 <main+0x1a>
      ;
    __sync_synchronize();
    80000ee6:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	aec080e7          	jalr	-1300(ra) # 800019d6 <cpuid>
    80000ef2:	85aa                	mv	a1,a0
    80000ef4:	00007517          	auipc	a0,0x7
    80000ef8:	1c450513          	addi	a0,a0,452 # 800080b8 <digits+0x78>
    80000efc:	fffff097          	auipc	ra,0xfffff
    80000f00:	69e080e7          	jalr	1694(ra) # 8000059a <printf>
    kvminithart();    // turn on paging
    80000f04:	00000097          	auipc	ra,0x0
    80000f08:	0d8080e7          	jalr	216(ra) # 80000fdc <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f0c:	00001097          	auipc	ra,0x1
    80000f10:	730080e7          	jalr	1840(ra) # 8000263c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f14:	00005097          	auipc	ra,0x5
    80000f18:	cdc080e7          	jalr	-804(ra) # 80005bf0 <plicinithart>
  }

  scheduler();        
    80000f1c:	00001097          	auipc	ra,0x1
    80000f20:	016080e7          	jalr	22(ra) # 80001f32 <scheduler>
    consoleinit();
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	53e080e7          	jalr	1342(ra) # 80000462 <consoleinit>
    printfinit();
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	854080e7          	jalr	-1964(ra) # 80000780 <printfinit>
    printf("\n");
    80000f34:	00007517          	auipc	a0,0x7
    80000f38:	19450513          	addi	a0,a0,404 # 800080c8 <digits+0x88>
    80000f3c:	fffff097          	auipc	ra,0xfffff
    80000f40:	65e080e7          	jalr	1630(ra) # 8000059a <printf>
    printf("xv6 kernel is booting\n");
    80000f44:	00007517          	auipc	a0,0x7
    80000f48:	15c50513          	addi	a0,a0,348 # 800080a0 <digits+0x60>
    80000f4c:	fffff097          	auipc	ra,0xfffff
    80000f50:	64e080e7          	jalr	1614(ra) # 8000059a <printf>
    printf("\n");
    80000f54:	00007517          	auipc	a0,0x7
    80000f58:	17450513          	addi	a0,a0,372 # 800080c8 <digits+0x88>
    80000f5c:	fffff097          	auipc	ra,0xfffff
    80000f60:	63e080e7          	jalr	1598(ra) # 8000059a <printf>
    kinit();         // physical page allocator
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	b88080e7          	jalr	-1144(ra) # 80000aec <kinit>
    kvminit();       // create kernel page table
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	310080e7          	jalr	784(ra) # 8000127c <kvminit>
    kvminithart();   // turn on paging
    80000f74:	00000097          	auipc	ra,0x0
    80000f78:	068080e7          	jalr	104(ra) # 80000fdc <kvminithart>
    procinit();      // process table
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	9c2080e7          	jalr	-1598(ra) # 8000193e <procinit>
    trapinit();      // trap vectors
    80000f84:	00001097          	auipc	ra,0x1
    80000f88:	690080e7          	jalr	1680(ra) # 80002614 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	6b0080e7          	jalr	1712(ra) # 8000263c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	c46080e7          	jalr	-954(ra) # 80005bda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f9c:	00005097          	auipc	ra,0x5
    80000fa0:	c54080e7          	jalr	-940(ra) # 80005bf0 <plicinithart>
    binit();         // buffer cache
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	dda080e7          	jalr	-550(ra) # 80002d7e <binit>
    iinit();         // inode cache
    80000fac:	00002097          	auipc	ra,0x2
    80000fb0:	46a080e7          	jalr	1130(ra) # 80003416 <iinit>
    fileinit();      // file table
    80000fb4:	00003097          	auipc	ra,0x3
    80000fb8:	41a080e7          	jalr	1050(ra) # 800043ce <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fbc:	00005097          	auipc	ra,0x5
    80000fc0:	d56080e7          	jalr	-682(ra) # 80005d12 <virtio_disk_init>
    userinit();      // first user process
    80000fc4:	00001097          	auipc	ra,0x1
    80000fc8:	d08080e7          	jalr	-760(ra) # 80001ccc <userinit>
    __sync_synchronize();
    80000fcc:	0ff0000f          	fence
    started = 1;
    80000fd0:	4785                	li	a5,1
    80000fd2:	00008717          	auipc	a4,0x8
    80000fd6:	02f72d23          	sw	a5,58(a4) # 8000900c <started>
    80000fda:	b789                	j	80000f1c <main+0x56>

0000000080000fdc <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fdc:	1141                	addi	sp,sp,-16
    80000fde:	e422                	sd	s0,8(sp)
    80000fe0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fe2:	00008797          	auipc	a5,0x8
    80000fe6:	02e7b783          	ld	a5,46(a5) # 80009010 <kernel_pagetable>
    80000fea:	83b1                	srli	a5,a5,0xc
    80000fec:	577d                	li	a4,-1
    80000fee:	177e                	slli	a4,a4,0x3f
    80000ff0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000ff2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ff6:	12000073          	sfence.vma
  sfence_vma();
}
    80000ffa:	6422                	ld	s0,8(sp)
    80000ffc:	0141                	addi	sp,sp,16
    80000ffe:	8082                	ret

0000000080001000 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001000:	7139                	addi	sp,sp,-64
    80001002:	fc06                	sd	ra,56(sp)
    80001004:	f822                	sd	s0,48(sp)
    80001006:	f426                	sd	s1,40(sp)
    80001008:	f04a                	sd	s2,32(sp)
    8000100a:	ec4e                	sd	s3,24(sp)
    8000100c:	e852                	sd	s4,16(sp)
    8000100e:	e456                	sd	s5,8(sp)
    80001010:	e05a                	sd	s6,0(sp)
    80001012:	0080                	addi	s0,sp,64
    80001014:	84aa                	mv	s1,a0
    80001016:	89ae                	mv	s3,a1
    80001018:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000101a:	57fd                	li	a5,-1
    8000101c:	83e9                	srli	a5,a5,0x1a
    8000101e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001020:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001022:	04b7f263          	bgeu	a5,a1,80001066 <walk+0x66>
    panic("walk");
    80001026:	00007517          	auipc	a0,0x7
    8000102a:	0aa50513          	addi	a0,a0,170 # 800080d0 <digits+0x90>
    8000102e:	fffff097          	auipc	ra,0xfffff
    80001032:	522080e7          	jalr	1314(ra) # 80000550 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001036:	060a8663          	beqz	s5,800010a2 <walk+0xa2>
    8000103a:	00000097          	auipc	ra,0x0
    8000103e:	aee080e7          	jalr	-1298(ra) # 80000b28 <kalloc>
    80001042:	84aa                	mv	s1,a0
    80001044:	c529                	beqz	a0,8000108e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001046:	6605                	lui	a2,0x1
    80001048:	4581                	li	a1,0
    8000104a:	00000097          	auipc	ra,0x0
    8000104e:	cca080e7          	jalr	-822(ra) # 80000d14 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001052:	00c4d793          	srli	a5,s1,0xc
    80001056:	07aa                	slli	a5,a5,0xa
    80001058:	0017e793          	ori	a5,a5,1
    8000105c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001060:	3a5d                	addiw	s4,s4,-9
    80001062:	036a0063          	beq	s4,s6,80001082 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001066:	0149d933          	srl	s2,s3,s4
    8000106a:	1ff97913          	andi	s2,s2,511
    8000106e:	090e                	slli	s2,s2,0x3
    80001070:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001072:	00093483          	ld	s1,0(s2)
    80001076:	0014f793          	andi	a5,s1,1
    8000107a:	dfd5                	beqz	a5,80001036 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000107c:	80a9                	srli	s1,s1,0xa
    8000107e:	04b2                	slli	s1,s1,0xc
    80001080:	b7c5                	j	80001060 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001082:	00c9d513          	srli	a0,s3,0xc
    80001086:	1ff57513          	andi	a0,a0,511
    8000108a:	050e                	slli	a0,a0,0x3
    8000108c:	9526                	add	a0,a0,s1
}
    8000108e:	70e2                	ld	ra,56(sp)
    80001090:	7442                	ld	s0,48(sp)
    80001092:	74a2                	ld	s1,40(sp)
    80001094:	7902                	ld	s2,32(sp)
    80001096:	69e2                	ld	s3,24(sp)
    80001098:	6a42                	ld	s4,16(sp)
    8000109a:	6aa2                	ld	s5,8(sp)
    8000109c:	6b02                	ld	s6,0(sp)
    8000109e:	6121                	addi	sp,sp,64
    800010a0:	8082                	ret
        return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7ed                	j	8000108e <walk+0x8e>

00000000800010a6 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010a6:	57fd                	li	a5,-1
    800010a8:	83e9                	srli	a5,a5,0x1a
    800010aa:	00b7f463          	bgeu	a5,a1,800010b2 <walkaddr+0xc>
    return 0;
    800010ae:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010b0:	8082                	ret
{
    800010b2:	1141                	addi	sp,sp,-16
    800010b4:	e406                	sd	ra,8(sp)
    800010b6:	e022                	sd	s0,0(sp)
    800010b8:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010ba:	4601                	li	a2,0
    800010bc:	00000097          	auipc	ra,0x0
    800010c0:	f44080e7          	jalr	-188(ra) # 80001000 <walk>
  if(pte == 0)
    800010c4:	c105                	beqz	a0,800010e4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010c6:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010c8:	0117f693          	andi	a3,a5,17
    800010cc:	4745                	li	a4,17
    return 0;
    800010ce:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010d0:	00e68663          	beq	a3,a4,800010dc <walkaddr+0x36>
}
    800010d4:	60a2                	ld	ra,8(sp)
    800010d6:	6402                	ld	s0,0(sp)
    800010d8:	0141                	addi	sp,sp,16
    800010da:	8082                	ret
  pa = PTE2PA(*pte);
    800010dc:	00a7d513          	srli	a0,a5,0xa
    800010e0:	0532                	slli	a0,a0,0xc
  return pa;
    800010e2:	bfcd                	j	800010d4 <walkaddr+0x2e>
    return 0;
    800010e4:	4501                	li	a0,0
    800010e6:	b7fd                	j	800010d4 <walkaddr+0x2e>

00000000800010e8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010e8:	715d                	addi	sp,sp,-80
    800010ea:	e486                	sd	ra,72(sp)
    800010ec:	e0a2                	sd	s0,64(sp)
    800010ee:	fc26                	sd	s1,56(sp)
    800010f0:	f84a                	sd	s2,48(sp)
    800010f2:	f44e                	sd	s3,40(sp)
    800010f4:	f052                	sd	s4,32(sp)
    800010f6:	ec56                	sd	s5,24(sp)
    800010f8:	e85a                	sd	s6,16(sp)
    800010fa:	e45e                	sd	s7,8(sp)
    800010fc:	0880                	addi	s0,sp,80
    800010fe:	8aaa                	mv	s5,a0
    80001100:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001102:	777d                	lui	a4,0xfffff
    80001104:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001108:	167d                	addi	a2,a2,-1
    8000110a:	00b609b3          	add	s3,a2,a1
    8000110e:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001112:	893e                	mv	s2,a5
    80001114:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001118:	6b85                	lui	s7,0x1
    8000111a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000111e:	4605                	li	a2,1
    80001120:	85ca                	mv	a1,s2
    80001122:	8556                	mv	a0,s5
    80001124:	00000097          	auipc	ra,0x0
    80001128:	edc080e7          	jalr	-292(ra) # 80001000 <walk>
    8000112c:	c51d                	beqz	a0,8000115a <mappages+0x72>
    if(*pte & PTE_V)
    8000112e:	611c                	ld	a5,0(a0)
    80001130:	8b85                	andi	a5,a5,1
    80001132:	ef81                	bnez	a5,8000114a <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001134:	80b1                	srli	s1,s1,0xc
    80001136:	04aa                	slli	s1,s1,0xa
    80001138:	0164e4b3          	or	s1,s1,s6
    8000113c:	0014e493          	ori	s1,s1,1
    80001140:	e104                	sd	s1,0(a0)
    if(a == last)
    80001142:	03390863          	beq	s2,s3,80001172 <mappages+0x8a>
    a += PGSIZE;
    80001146:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001148:	bfc9                	j	8000111a <mappages+0x32>
      panic("remap");
    8000114a:	00007517          	auipc	a0,0x7
    8000114e:	f8e50513          	addi	a0,a0,-114 # 800080d8 <digits+0x98>
    80001152:	fffff097          	auipc	ra,0xfffff
    80001156:	3fe080e7          	jalr	1022(ra) # 80000550 <panic>
      return -1;
    8000115a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000115c:	60a6                	ld	ra,72(sp)
    8000115e:	6406                	ld	s0,64(sp)
    80001160:	74e2                	ld	s1,56(sp)
    80001162:	7942                	ld	s2,48(sp)
    80001164:	79a2                	ld	s3,40(sp)
    80001166:	7a02                	ld	s4,32(sp)
    80001168:	6ae2                	ld	s5,24(sp)
    8000116a:	6b42                	ld	s6,16(sp)
    8000116c:	6ba2                	ld	s7,8(sp)
    8000116e:	6161                	addi	sp,sp,80
    80001170:	8082                	ret
  return 0;
    80001172:	4501                	li	a0,0
    80001174:	b7e5                	j	8000115c <mappages+0x74>

0000000080001176 <kvmmap>:
{
    80001176:	1141                	addi	sp,sp,-16
    80001178:	e406                	sd	ra,8(sp)
    8000117a:	e022                	sd	s0,0(sp)
    8000117c:	0800                	addi	s0,sp,16
    8000117e:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001180:	86b2                	mv	a3,a2
    80001182:	863e                	mv	a2,a5
    80001184:	00000097          	auipc	ra,0x0
    80001188:	f64080e7          	jalr	-156(ra) # 800010e8 <mappages>
    8000118c:	e509                	bnez	a0,80001196 <kvmmap+0x20>
}
    8000118e:	60a2                	ld	ra,8(sp)
    80001190:	6402                	ld	s0,0(sp)
    80001192:	0141                	addi	sp,sp,16
    80001194:	8082                	ret
    panic("kvmmap");
    80001196:	00007517          	auipc	a0,0x7
    8000119a:	f4a50513          	addi	a0,a0,-182 # 800080e0 <digits+0xa0>
    8000119e:	fffff097          	auipc	ra,0xfffff
    800011a2:	3b2080e7          	jalr	946(ra) # 80000550 <panic>

00000000800011a6 <kvmmake>:
{
    800011a6:	1101                	addi	sp,sp,-32
    800011a8:	ec06                	sd	ra,24(sp)
    800011aa:	e822                	sd	s0,16(sp)
    800011ac:	e426                	sd	s1,8(sp)
    800011ae:	e04a                	sd	s2,0(sp)
    800011b0:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011b2:	00000097          	auipc	ra,0x0
    800011b6:	976080e7          	jalr	-1674(ra) # 80000b28 <kalloc>
    800011ba:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011bc:	6605                	lui	a2,0x1
    800011be:	4581                	li	a1,0
    800011c0:	00000097          	auipc	ra,0x0
    800011c4:	b54080e7          	jalr	-1196(ra) # 80000d14 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011c8:	4719                	li	a4,6
    800011ca:	6685                	lui	a3,0x1
    800011cc:	10000637          	lui	a2,0x10000
    800011d0:	100005b7          	lui	a1,0x10000
    800011d4:	8526                	mv	a0,s1
    800011d6:	00000097          	auipc	ra,0x0
    800011da:	fa0080e7          	jalr	-96(ra) # 80001176 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011de:	4719                	li	a4,6
    800011e0:	6685                	lui	a3,0x1
    800011e2:	10001637          	lui	a2,0x10001
    800011e6:	100015b7          	lui	a1,0x10001
    800011ea:	8526                	mv	a0,s1
    800011ec:	00000097          	auipc	ra,0x0
    800011f0:	f8a080e7          	jalr	-118(ra) # 80001176 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011f4:	4719                	li	a4,6
    800011f6:	004006b7          	lui	a3,0x400
    800011fa:	0c000637          	lui	a2,0xc000
    800011fe:	0c0005b7          	lui	a1,0xc000
    80001202:	8526                	mv	a0,s1
    80001204:	00000097          	auipc	ra,0x0
    80001208:	f72080e7          	jalr	-142(ra) # 80001176 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000120c:	00007917          	auipc	s2,0x7
    80001210:	df490913          	addi	s2,s2,-524 # 80008000 <etext>
    80001214:	4729                	li	a4,10
    80001216:	80007697          	auipc	a3,0x80007
    8000121a:	dea68693          	addi	a3,a3,-534 # 8000 <_entry-0x7fff8000>
    8000121e:	4605                	li	a2,1
    80001220:	067e                	slli	a2,a2,0x1f
    80001222:	85b2                	mv	a1,a2
    80001224:	8526                	mv	a0,s1
    80001226:	00000097          	auipc	ra,0x0
    8000122a:	f50080e7          	jalr	-176(ra) # 80001176 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000122e:	4719                	li	a4,6
    80001230:	46c5                	li	a3,17
    80001232:	06ee                	slli	a3,a3,0x1b
    80001234:	412686b3          	sub	a3,a3,s2
    80001238:	864a                	mv	a2,s2
    8000123a:	85ca                	mv	a1,s2
    8000123c:	8526                	mv	a0,s1
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	f38080e7          	jalr	-200(ra) # 80001176 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001246:	4729                	li	a4,10
    80001248:	6685                	lui	a3,0x1
    8000124a:	00006617          	auipc	a2,0x6
    8000124e:	db660613          	addi	a2,a2,-586 # 80007000 <_trampoline>
    80001252:	040005b7          	lui	a1,0x4000
    80001256:	15fd                	addi	a1,a1,-1
    80001258:	05b2                	slli	a1,a1,0xc
    8000125a:	8526                	mv	a0,s1
    8000125c:	00000097          	auipc	ra,0x0
    80001260:	f1a080e7          	jalr	-230(ra) # 80001176 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001264:	8526                	mv	a0,s1
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	642080e7          	jalr	1602(ra) # 800018a8 <proc_mapstacks>
}
    8000126e:	8526                	mv	a0,s1
    80001270:	60e2                	ld	ra,24(sp)
    80001272:	6442                	ld	s0,16(sp)
    80001274:	64a2                	ld	s1,8(sp)
    80001276:	6902                	ld	s2,0(sp)
    80001278:	6105                	addi	sp,sp,32
    8000127a:	8082                	ret

000000008000127c <kvminit>:
{
    8000127c:	1141                	addi	sp,sp,-16
    8000127e:	e406                	sd	ra,8(sp)
    80001280:	e022                	sd	s0,0(sp)
    80001282:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001284:	00000097          	auipc	ra,0x0
    80001288:	f22080e7          	jalr	-222(ra) # 800011a6 <kvmmake>
    8000128c:	00008797          	auipc	a5,0x8
    80001290:	d8a7b223          	sd	a0,-636(a5) # 80009010 <kernel_pagetable>
}
    80001294:	60a2                	ld	ra,8(sp)
    80001296:	6402                	ld	s0,0(sp)
    80001298:	0141                	addi	sp,sp,16
    8000129a:	8082                	ret

000000008000129c <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000129c:	715d                	addi	sp,sp,-80
    8000129e:	e486                	sd	ra,72(sp)
    800012a0:	e0a2                	sd	s0,64(sp)
    800012a2:	fc26                	sd	s1,56(sp)
    800012a4:	f84a                	sd	s2,48(sp)
    800012a6:	f44e                	sd	s3,40(sp)
    800012a8:	f052                	sd	s4,32(sp)
    800012aa:	ec56                	sd	s5,24(sp)
    800012ac:	e85a                	sd	s6,16(sp)
    800012ae:	e45e                	sd	s7,8(sp)
    800012b0:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012b2:	03459793          	slli	a5,a1,0x34
    800012b6:	e795                	bnez	a5,800012e2 <uvmunmap+0x46>
    800012b8:	8a2a                	mv	s4,a0
    800012ba:	892e                	mv	s2,a1
    800012bc:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012be:	0632                	slli	a2,a2,0xc
    800012c0:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012c4:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012c6:	6b05                	lui	s6,0x1
    800012c8:	0735e863          	bltu	a1,s3,80001338 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012cc:	60a6                	ld	ra,72(sp)
    800012ce:	6406                	ld	s0,64(sp)
    800012d0:	74e2                	ld	s1,56(sp)
    800012d2:	7942                	ld	s2,48(sp)
    800012d4:	79a2                	ld	s3,40(sp)
    800012d6:	7a02                	ld	s4,32(sp)
    800012d8:	6ae2                	ld	s5,24(sp)
    800012da:	6b42                	ld	s6,16(sp)
    800012dc:	6ba2                	ld	s7,8(sp)
    800012de:	6161                	addi	sp,sp,80
    800012e0:	8082                	ret
    panic("uvmunmap: not aligned");
    800012e2:	00007517          	auipc	a0,0x7
    800012e6:	e0650513          	addi	a0,a0,-506 # 800080e8 <digits+0xa8>
    800012ea:	fffff097          	auipc	ra,0xfffff
    800012ee:	266080e7          	jalr	614(ra) # 80000550 <panic>
      panic("uvmunmap: walk");
    800012f2:	00007517          	auipc	a0,0x7
    800012f6:	e0e50513          	addi	a0,a0,-498 # 80008100 <digits+0xc0>
    800012fa:	fffff097          	auipc	ra,0xfffff
    800012fe:	256080e7          	jalr	598(ra) # 80000550 <panic>
      panic("uvmunmap: not mapped");
    80001302:	00007517          	auipc	a0,0x7
    80001306:	e0e50513          	addi	a0,a0,-498 # 80008110 <digits+0xd0>
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	246080e7          	jalr	582(ra) # 80000550 <panic>
      panic("uvmunmap: not a leaf");
    80001312:	00007517          	auipc	a0,0x7
    80001316:	e1650513          	addi	a0,a0,-490 # 80008128 <digits+0xe8>
    8000131a:	fffff097          	auipc	ra,0xfffff
    8000131e:	236080e7          	jalr	566(ra) # 80000550 <panic>
      uint64 pa = PTE2PA(*pte);
    80001322:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001324:	0532                	slli	a0,a0,0xc
    80001326:	fffff097          	auipc	ra,0xfffff
    8000132a:	706080e7          	jalr	1798(ra) # 80000a2c <kfree>
    *pte = 0;
    8000132e:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001332:	995a                	add	s2,s2,s6
    80001334:	f9397ce3          	bgeu	s2,s3,800012cc <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001338:	4601                	li	a2,0
    8000133a:	85ca                	mv	a1,s2
    8000133c:	8552                	mv	a0,s4
    8000133e:	00000097          	auipc	ra,0x0
    80001342:	cc2080e7          	jalr	-830(ra) # 80001000 <walk>
    80001346:	84aa                	mv	s1,a0
    80001348:	d54d                	beqz	a0,800012f2 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000134a:	6108                	ld	a0,0(a0)
    8000134c:	00157793          	andi	a5,a0,1
    80001350:	dbcd                	beqz	a5,80001302 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001352:	3ff57793          	andi	a5,a0,1023
    80001356:	fb778ee3          	beq	a5,s7,80001312 <uvmunmap+0x76>
    if(do_free){
    8000135a:	fc0a8ae3          	beqz	s5,8000132e <uvmunmap+0x92>
    8000135e:	b7d1                	j	80001322 <uvmunmap+0x86>

0000000080001360 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001360:	1101                	addi	sp,sp,-32
    80001362:	ec06                	sd	ra,24(sp)
    80001364:	e822                	sd	s0,16(sp)
    80001366:	e426                	sd	s1,8(sp)
    80001368:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000136a:	fffff097          	auipc	ra,0xfffff
    8000136e:	7be080e7          	jalr	1982(ra) # 80000b28 <kalloc>
    80001372:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001374:	c519                	beqz	a0,80001382 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001376:	6605                	lui	a2,0x1
    80001378:	4581                	li	a1,0
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	99a080e7          	jalr	-1638(ra) # 80000d14 <memset>
  return pagetable;
}
    80001382:	8526                	mv	a0,s1
    80001384:	60e2                	ld	ra,24(sp)
    80001386:	6442                	ld	s0,16(sp)
    80001388:	64a2                	ld	s1,8(sp)
    8000138a:	6105                	addi	sp,sp,32
    8000138c:	8082                	ret

000000008000138e <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000138e:	7179                	addi	sp,sp,-48
    80001390:	f406                	sd	ra,40(sp)
    80001392:	f022                	sd	s0,32(sp)
    80001394:	ec26                	sd	s1,24(sp)
    80001396:	e84a                	sd	s2,16(sp)
    80001398:	e44e                	sd	s3,8(sp)
    8000139a:	e052                	sd	s4,0(sp)
    8000139c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000139e:	6785                	lui	a5,0x1
    800013a0:	04f67863          	bgeu	a2,a5,800013f0 <uvminit+0x62>
    800013a4:	8a2a                	mv	s4,a0
    800013a6:	89ae                	mv	s3,a1
    800013a8:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013aa:	fffff097          	auipc	ra,0xfffff
    800013ae:	77e080e7          	jalr	1918(ra) # 80000b28 <kalloc>
    800013b2:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013b4:	6605                	lui	a2,0x1
    800013b6:	4581                	li	a1,0
    800013b8:	00000097          	auipc	ra,0x0
    800013bc:	95c080e7          	jalr	-1700(ra) # 80000d14 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013c0:	4779                	li	a4,30
    800013c2:	86ca                	mv	a3,s2
    800013c4:	6605                	lui	a2,0x1
    800013c6:	4581                	li	a1,0
    800013c8:	8552                	mv	a0,s4
    800013ca:	00000097          	auipc	ra,0x0
    800013ce:	d1e080e7          	jalr	-738(ra) # 800010e8 <mappages>
  memmove(mem, src, sz);
    800013d2:	8626                	mv	a2,s1
    800013d4:	85ce                	mv	a1,s3
    800013d6:	854a                	mv	a0,s2
    800013d8:	00000097          	auipc	ra,0x0
    800013dc:	99c080e7          	jalr	-1636(ra) # 80000d74 <memmove>
}
    800013e0:	70a2                	ld	ra,40(sp)
    800013e2:	7402                	ld	s0,32(sp)
    800013e4:	64e2                	ld	s1,24(sp)
    800013e6:	6942                	ld	s2,16(sp)
    800013e8:	69a2                	ld	s3,8(sp)
    800013ea:	6a02                	ld	s4,0(sp)
    800013ec:	6145                	addi	sp,sp,48
    800013ee:	8082                	ret
    panic("inituvm: more than a page");
    800013f0:	00007517          	auipc	a0,0x7
    800013f4:	d5050513          	addi	a0,a0,-688 # 80008140 <digits+0x100>
    800013f8:	fffff097          	auipc	ra,0xfffff
    800013fc:	158080e7          	jalr	344(ra) # 80000550 <panic>

0000000080001400 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001400:	1101                	addi	sp,sp,-32
    80001402:	ec06                	sd	ra,24(sp)
    80001404:	e822                	sd	s0,16(sp)
    80001406:	e426                	sd	s1,8(sp)
    80001408:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000140a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000140c:	00b67d63          	bgeu	a2,a1,80001426 <uvmdealloc+0x26>
    80001410:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001412:	6785                	lui	a5,0x1
    80001414:	17fd                	addi	a5,a5,-1
    80001416:	00f60733          	add	a4,a2,a5
    8000141a:	767d                	lui	a2,0xfffff
    8000141c:	8f71                	and	a4,a4,a2
    8000141e:	97ae                	add	a5,a5,a1
    80001420:	8ff1                	and	a5,a5,a2
    80001422:	00f76863          	bltu	a4,a5,80001432 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001426:	8526                	mv	a0,s1
    80001428:	60e2                	ld	ra,24(sp)
    8000142a:	6442                	ld	s0,16(sp)
    8000142c:	64a2                	ld	s1,8(sp)
    8000142e:	6105                	addi	sp,sp,32
    80001430:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001432:	8f99                	sub	a5,a5,a4
    80001434:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001436:	4685                	li	a3,1
    80001438:	0007861b          	sext.w	a2,a5
    8000143c:	85ba                	mv	a1,a4
    8000143e:	00000097          	auipc	ra,0x0
    80001442:	e5e080e7          	jalr	-418(ra) # 8000129c <uvmunmap>
    80001446:	b7c5                	j	80001426 <uvmdealloc+0x26>

0000000080001448 <uvmalloc>:
  if(newsz < oldsz)
    80001448:	0ab66163          	bltu	a2,a1,800014ea <uvmalloc+0xa2>
{
    8000144c:	7139                	addi	sp,sp,-64
    8000144e:	fc06                	sd	ra,56(sp)
    80001450:	f822                	sd	s0,48(sp)
    80001452:	f426                	sd	s1,40(sp)
    80001454:	f04a                	sd	s2,32(sp)
    80001456:	ec4e                	sd	s3,24(sp)
    80001458:	e852                	sd	s4,16(sp)
    8000145a:	e456                	sd	s5,8(sp)
    8000145c:	0080                	addi	s0,sp,64
    8000145e:	8aaa                	mv	s5,a0
    80001460:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001462:	6985                	lui	s3,0x1
    80001464:	19fd                	addi	s3,s3,-1
    80001466:	95ce                	add	a1,a1,s3
    80001468:	79fd                	lui	s3,0xfffff
    8000146a:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	08c9f063          	bgeu	s3,a2,800014ee <uvmalloc+0xa6>
    80001472:	894e                	mv	s2,s3
    mem = kalloc();
    80001474:	fffff097          	auipc	ra,0xfffff
    80001478:	6b4080e7          	jalr	1716(ra) # 80000b28 <kalloc>
    8000147c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000147e:	c51d                	beqz	a0,800014ac <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001480:	6605                	lui	a2,0x1
    80001482:	4581                	li	a1,0
    80001484:	00000097          	auipc	ra,0x0
    80001488:	890080e7          	jalr	-1904(ra) # 80000d14 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000148c:	4779                	li	a4,30
    8000148e:	86a6                	mv	a3,s1
    80001490:	6605                	lui	a2,0x1
    80001492:	85ca                	mv	a1,s2
    80001494:	8556                	mv	a0,s5
    80001496:	00000097          	auipc	ra,0x0
    8000149a:	c52080e7          	jalr	-942(ra) # 800010e8 <mappages>
    8000149e:	e905                	bnez	a0,800014ce <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014a0:	6785                	lui	a5,0x1
    800014a2:	993e                	add	s2,s2,a5
    800014a4:	fd4968e3          	bltu	s2,s4,80001474 <uvmalloc+0x2c>
  return newsz;
    800014a8:	8552                	mv	a0,s4
    800014aa:	a809                	j	800014bc <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014ac:	864e                	mv	a2,s3
    800014ae:	85ca                	mv	a1,s2
    800014b0:	8556                	mv	a0,s5
    800014b2:	00000097          	auipc	ra,0x0
    800014b6:	f4e080e7          	jalr	-178(ra) # 80001400 <uvmdealloc>
      return 0;
    800014ba:	4501                	li	a0,0
}
    800014bc:	70e2                	ld	ra,56(sp)
    800014be:	7442                	ld	s0,48(sp)
    800014c0:	74a2                	ld	s1,40(sp)
    800014c2:	7902                	ld	s2,32(sp)
    800014c4:	69e2                	ld	s3,24(sp)
    800014c6:	6a42                	ld	s4,16(sp)
    800014c8:	6aa2                	ld	s5,8(sp)
    800014ca:	6121                	addi	sp,sp,64
    800014cc:	8082                	ret
      kfree(mem);
    800014ce:	8526                	mv	a0,s1
    800014d0:	fffff097          	auipc	ra,0xfffff
    800014d4:	55c080e7          	jalr	1372(ra) # 80000a2c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014d8:	864e                	mv	a2,s3
    800014da:	85ca                	mv	a1,s2
    800014dc:	8556                	mv	a0,s5
    800014de:	00000097          	auipc	ra,0x0
    800014e2:	f22080e7          	jalr	-222(ra) # 80001400 <uvmdealloc>
      return 0;
    800014e6:	4501                	li	a0,0
    800014e8:	bfd1                	j	800014bc <uvmalloc+0x74>
    return oldsz;
    800014ea:	852e                	mv	a0,a1
}
    800014ec:	8082                	ret
  return newsz;
    800014ee:	8532                	mv	a0,a2
    800014f0:	b7f1                	j	800014bc <uvmalloc+0x74>

00000000800014f2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014f2:	7179                	addi	sp,sp,-48
    800014f4:	f406                	sd	ra,40(sp)
    800014f6:	f022                	sd	s0,32(sp)
    800014f8:	ec26                	sd	s1,24(sp)
    800014fa:	e84a                	sd	s2,16(sp)
    800014fc:	e44e                	sd	s3,8(sp)
    800014fe:	e052                	sd	s4,0(sp)
    80001500:	1800                	addi	s0,sp,48
    80001502:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001504:	84aa                	mv	s1,a0
    80001506:	6905                	lui	s2,0x1
    80001508:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000150a:	4985                	li	s3,1
    8000150c:	a821                	j	80001524 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000150e:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001510:	0532                	slli	a0,a0,0xc
    80001512:	00000097          	auipc	ra,0x0
    80001516:	fe0080e7          	jalr	-32(ra) # 800014f2 <freewalk>
      pagetable[i] = 0;
    8000151a:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000151e:	04a1                	addi	s1,s1,8
    80001520:	03248163          	beq	s1,s2,80001542 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001524:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001526:	00f57793          	andi	a5,a0,15
    8000152a:	ff3782e3          	beq	a5,s3,8000150e <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000152e:	8905                	andi	a0,a0,1
    80001530:	d57d                	beqz	a0,8000151e <freewalk+0x2c>
      panic("freewalk: leaf");
    80001532:	00007517          	auipc	a0,0x7
    80001536:	c2e50513          	addi	a0,a0,-978 # 80008160 <digits+0x120>
    8000153a:	fffff097          	auipc	ra,0xfffff
    8000153e:	016080e7          	jalr	22(ra) # 80000550 <panic>
    }
  }
  kfree((void*)pagetable);
    80001542:	8552                	mv	a0,s4
    80001544:	fffff097          	auipc	ra,0xfffff
    80001548:	4e8080e7          	jalr	1256(ra) # 80000a2c <kfree>
}
    8000154c:	70a2                	ld	ra,40(sp)
    8000154e:	7402                	ld	s0,32(sp)
    80001550:	64e2                	ld	s1,24(sp)
    80001552:	6942                	ld	s2,16(sp)
    80001554:	69a2                	ld	s3,8(sp)
    80001556:	6a02                	ld	s4,0(sp)
    80001558:	6145                	addi	sp,sp,48
    8000155a:	8082                	ret

000000008000155c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000155c:	1101                	addi	sp,sp,-32
    8000155e:	ec06                	sd	ra,24(sp)
    80001560:	e822                	sd	s0,16(sp)
    80001562:	e426                	sd	s1,8(sp)
    80001564:	1000                	addi	s0,sp,32
    80001566:	84aa                	mv	s1,a0
  if(sz > 0)
    80001568:	e999                	bnez	a1,8000157e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000156a:	8526                	mv	a0,s1
    8000156c:	00000097          	auipc	ra,0x0
    80001570:	f86080e7          	jalr	-122(ra) # 800014f2 <freewalk>
}
    80001574:	60e2                	ld	ra,24(sp)
    80001576:	6442                	ld	s0,16(sp)
    80001578:	64a2                	ld	s1,8(sp)
    8000157a:	6105                	addi	sp,sp,32
    8000157c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000157e:	6605                	lui	a2,0x1
    80001580:	167d                	addi	a2,a2,-1
    80001582:	962e                	add	a2,a2,a1
    80001584:	4685                	li	a3,1
    80001586:	8231                	srli	a2,a2,0xc
    80001588:	4581                	li	a1,0
    8000158a:	00000097          	auipc	ra,0x0
    8000158e:	d12080e7          	jalr	-750(ra) # 8000129c <uvmunmap>
    80001592:	bfe1                	j	8000156a <uvmfree+0xe>

0000000080001594 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001594:	c679                	beqz	a2,80001662 <uvmcopy+0xce>
{
    80001596:	715d                	addi	sp,sp,-80
    80001598:	e486                	sd	ra,72(sp)
    8000159a:	e0a2                	sd	s0,64(sp)
    8000159c:	fc26                	sd	s1,56(sp)
    8000159e:	f84a                	sd	s2,48(sp)
    800015a0:	f44e                	sd	s3,40(sp)
    800015a2:	f052                	sd	s4,32(sp)
    800015a4:	ec56                	sd	s5,24(sp)
    800015a6:	e85a                	sd	s6,16(sp)
    800015a8:	e45e                	sd	s7,8(sp)
    800015aa:	0880                	addi	s0,sp,80
    800015ac:	8b2a                	mv	s6,a0
    800015ae:	8aae                	mv	s5,a1
    800015b0:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015b2:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015b4:	4601                	li	a2,0
    800015b6:	85ce                	mv	a1,s3
    800015b8:	855a                	mv	a0,s6
    800015ba:	00000097          	auipc	ra,0x0
    800015be:	a46080e7          	jalr	-1466(ra) # 80001000 <walk>
    800015c2:	c531                	beqz	a0,8000160e <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015c4:	6118                	ld	a4,0(a0)
    800015c6:	00177793          	andi	a5,a4,1
    800015ca:	cbb1                	beqz	a5,8000161e <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015cc:	00a75593          	srli	a1,a4,0xa
    800015d0:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015d4:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	550080e7          	jalr	1360(ra) # 80000b28 <kalloc>
    800015e0:	892a                	mv	s2,a0
    800015e2:	c939                	beqz	a0,80001638 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015e4:	6605                	lui	a2,0x1
    800015e6:	85de                	mv	a1,s7
    800015e8:	fffff097          	auipc	ra,0xfffff
    800015ec:	78c080e7          	jalr	1932(ra) # 80000d74 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015f0:	8726                	mv	a4,s1
    800015f2:	86ca                	mv	a3,s2
    800015f4:	6605                	lui	a2,0x1
    800015f6:	85ce                	mv	a1,s3
    800015f8:	8556                	mv	a0,s5
    800015fa:	00000097          	auipc	ra,0x0
    800015fe:	aee080e7          	jalr	-1298(ra) # 800010e8 <mappages>
    80001602:	e515                	bnez	a0,8000162e <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001604:	6785                	lui	a5,0x1
    80001606:	99be                	add	s3,s3,a5
    80001608:	fb49e6e3          	bltu	s3,s4,800015b4 <uvmcopy+0x20>
    8000160c:	a081                	j	8000164c <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000160e:	00007517          	auipc	a0,0x7
    80001612:	b6250513          	addi	a0,a0,-1182 # 80008170 <digits+0x130>
    80001616:	fffff097          	auipc	ra,0xfffff
    8000161a:	f3a080e7          	jalr	-198(ra) # 80000550 <panic>
      panic("uvmcopy: page not present");
    8000161e:	00007517          	auipc	a0,0x7
    80001622:	b7250513          	addi	a0,a0,-1166 # 80008190 <digits+0x150>
    80001626:	fffff097          	auipc	ra,0xfffff
    8000162a:	f2a080e7          	jalr	-214(ra) # 80000550 <panic>
      kfree(mem);
    8000162e:	854a                	mv	a0,s2
    80001630:	fffff097          	auipc	ra,0xfffff
    80001634:	3fc080e7          	jalr	1020(ra) # 80000a2c <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001638:	4685                	li	a3,1
    8000163a:	00c9d613          	srli	a2,s3,0xc
    8000163e:	4581                	li	a1,0
    80001640:	8556                	mv	a0,s5
    80001642:	00000097          	auipc	ra,0x0
    80001646:	c5a080e7          	jalr	-934(ra) # 8000129c <uvmunmap>
  return -1;
    8000164a:	557d                	li	a0,-1
}
    8000164c:	60a6                	ld	ra,72(sp)
    8000164e:	6406                	ld	s0,64(sp)
    80001650:	74e2                	ld	s1,56(sp)
    80001652:	7942                	ld	s2,48(sp)
    80001654:	79a2                	ld	s3,40(sp)
    80001656:	7a02                	ld	s4,32(sp)
    80001658:	6ae2                	ld	s5,24(sp)
    8000165a:	6b42                	ld	s6,16(sp)
    8000165c:	6ba2                	ld	s7,8(sp)
    8000165e:	6161                	addi	sp,sp,80
    80001660:	8082                	ret
  return 0;
    80001662:	4501                	li	a0,0
}
    80001664:	8082                	ret

0000000080001666 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001666:	1141                	addi	sp,sp,-16
    80001668:	e406                	sd	ra,8(sp)
    8000166a:	e022                	sd	s0,0(sp)
    8000166c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000166e:	4601                	li	a2,0
    80001670:	00000097          	auipc	ra,0x0
    80001674:	990080e7          	jalr	-1648(ra) # 80001000 <walk>
  if(pte == 0)
    80001678:	c901                	beqz	a0,80001688 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000167a:	611c                	ld	a5,0(a0)
    8000167c:	9bbd                	andi	a5,a5,-17
    8000167e:	e11c                	sd	a5,0(a0)
}
    80001680:	60a2                	ld	ra,8(sp)
    80001682:	6402                	ld	s0,0(sp)
    80001684:	0141                	addi	sp,sp,16
    80001686:	8082                	ret
    panic("uvmclear");
    80001688:	00007517          	auipc	a0,0x7
    8000168c:	b2850513          	addi	a0,a0,-1240 # 800081b0 <digits+0x170>
    80001690:	fffff097          	auipc	ra,0xfffff
    80001694:	ec0080e7          	jalr	-320(ra) # 80000550 <panic>

0000000080001698 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001698:	c6bd                	beqz	a3,80001706 <copyout+0x6e>
{
    8000169a:	715d                	addi	sp,sp,-80
    8000169c:	e486                	sd	ra,72(sp)
    8000169e:	e0a2                	sd	s0,64(sp)
    800016a0:	fc26                	sd	s1,56(sp)
    800016a2:	f84a                	sd	s2,48(sp)
    800016a4:	f44e                	sd	s3,40(sp)
    800016a6:	f052                	sd	s4,32(sp)
    800016a8:	ec56                	sd	s5,24(sp)
    800016aa:	e85a                	sd	s6,16(sp)
    800016ac:	e45e                	sd	s7,8(sp)
    800016ae:	e062                	sd	s8,0(sp)
    800016b0:	0880                	addi	s0,sp,80
    800016b2:	8b2a                	mv	s6,a0
    800016b4:	8c2e                	mv	s8,a1
    800016b6:	8a32                	mv	s4,a2
    800016b8:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016ba:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016bc:	6a85                	lui	s5,0x1
    800016be:	a015                	j	800016e2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016c0:	9562                	add	a0,a0,s8
    800016c2:	0004861b          	sext.w	a2,s1
    800016c6:	85d2                	mv	a1,s4
    800016c8:	41250533          	sub	a0,a0,s2
    800016cc:	fffff097          	auipc	ra,0xfffff
    800016d0:	6a8080e7          	jalr	1704(ra) # 80000d74 <memmove>

    len -= n;
    800016d4:	409989b3          	sub	s3,s3,s1
    src += n;
    800016d8:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016da:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016de:	02098263          	beqz	s3,80001702 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016e2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016e6:	85ca                	mv	a1,s2
    800016e8:	855a                	mv	a0,s6
    800016ea:	00000097          	auipc	ra,0x0
    800016ee:	9bc080e7          	jalr	-1604(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    800016f2:	cd01                	beqz	a0,8000170a <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016f4:	418904b3          	sub	s1,s2,s8
    800016f8:	94d6                	add	s1,s1,s5
    if(n > len)
    800016fa:	fc99f3e3          	bgeu	s3,s1,800016c0 <copyout+0x28>
    800016fe:	84ce                	mv	s1,s3
    80001700:	b7c1                	j	800016c0 <copyout+0x28>
  }
  return 0;
    80001702:	4501                	li	a0,0
    80001704:	a021                	j	8000170c <copyout+0x74>
    80001706:	4501                	li	a0,0
}
    80001708:	8082                	ret
      return -1;
    8000170a:	557d                	li	a0,-1
}
    8000170c:	60a6                	ld	ra,72(sp)
    8000170e:	6406                	ld	s0,64(sp)
    80001710:	74e2                	ld	s1,56(sp)
    80001712:	7942                	ld	s2,48(sp)
    80001714:	79a2                	ld	s3,40(sp)
    80001716:	7a02                	ld	s4,32(sp)
    80001718:	6ae2                	ld	s5,24(sp)
    8000171a:	6b42                	ld	s6,16(sp)
    8000171c:	6ba2                	ld	s7,8(sp)
    8000171e:	6c02                	ld	s8,0(sp)
    80001720:	6161                	addi	sp,sp,80
    80001722:	8082                	ret

0000000080001724 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001724:	c6bd                	beqz	a3,80001792 <copyin+0x6e>
{
    80001726:	715d                	addi	sp,sp,-80
    80001728:	e486                	sd	ra,72(sp)
    8000172a:	e0a2                	sd	s0,64(sp)
    8000172c:	fc26                	sd	s1,56(sp)
    8000172e:	f84a                	sd	s2,48(sp)
    80001730:	f44e                	sd	s3,40(sp)
    80001732:	f052                	sd	s4,32(sp)
    80001734:	ec56                	sd	s5,24(sp)
    80001736:	e85a                	sd	s6,16(sp)
    80001738:	e45e                	sd	s7,8(sp)
    8000173a:	e062                	sd	s8,0(sp)
    8000173c:	0880                	addi	s0,sp,80
    8000173e:	8b2a                	mv	s6,a0
    80001740:	8a2e                	mv	s4,a1
    80001742:	8c32                	mv	s8,a2
    80001744:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001746:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001748:	6a85                	lui	s5,0x1
    8000174a:	a015                	j	8000176e <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000174c:	9562                	add	a0,a0,s8
    8000174e:	0004861b          	sext.w	a2,s1
    80001752:	412505b3          	sub	a1,a0,s2
    80001756:	8552                	mv	a0,s4
    80001758:	fffff097          	auipc	ra,0xfffff
    8000175c:	61c080e7          	jalr	1564(ra) # 80000d74 <memmove>

    len -= n;
    80001760:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001764:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001766:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000176a:	02098263          	beqz	s3,8000178e <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000176e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001772:	85ca                	mv	a1,s2
    80001774:	855a                	mv	a0,s6
    80001776:	00000097          	auipc	ra,0x0
    8000177a:	930080e7          	jalr	-1744(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    8000177e:	cd01                	beqz	a0,80001796 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001780:	418904b3          	sub	s1,s2,s8
    80001784:	94d6                	add	s1,s1,s5
    if(n > len)
    80001786:	fc99f3e3          	bgeu	s3,s1,8000174c <copyin+0x28>
    8000178a:	84ce                	mv	s1,s3
    8000178c:	b7c1                	j	8000174c <copyin+0x28>
  }
  return 0;
    8000178e:	4501                	li	a0,0
    80001790:	a021                	j	80001798 <copyin+0x74>
    80001792:	4501                	li	a0,0
}
    80001794:	8082                	ret
      return -1;
    80001796:	557d                	li	a0,-1
}
    80001798:	60a6                	ld	ra,72(sp)
    8000179a:	6406                	ld	s0,64(sp)
    8000179c:	74e2                	ld	s1,56(sp)
    8000179e:	7942                	ld	s2,48(sp)
    800017a0:	79a2                	ld	s3,40(sp)
    800017a2:	7a02                	ld	s4,32(sp)
    800017a4:	6ae2                	ld	s5,24(sp)
    800017a6:	6b42                	ld	s6,16(sp)
    800017a8:	6ba2                	ld	s7,8(sp)
    800017aa:	6c02                	ld	s8,0(sp)
    800017ac:	6161                	addi	sp,sp,80
    800017ae:	8082                	ret

00000000800017b0 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017b0:	c6c5                	beqz	a3,80001858 <copyinstr+0xa8>
{
    800017b2:	715d                	addi	sp,sp,-80
    800017b4:	e486                	sd	ra,72(sp)
    800017b6:	e0a2                	sd	s0,64(sp)
    800017b8:	fc26                	sd	s1,56(sp)
    800017ba:	f84a                	sd	s2,48(sp)
    800017bc:	f44e                	sd	s3,40(sp)
    800017be:	f052                	sd	s4,32(sp)
    800017c0:	ec56                	sd	s5,24(sp)
    800017c2:	e85a                	sd	s6,16(sp)
    800017c4:	e45e                	sd	s7,8(sp)
    800017c6:	0880                	addi	s0,sp,80
    800017c8:	8a2a                	mv	s4,a0
    800017ca:	8b2e                	mv	s6,a1
    800017cc:	8bb2                	mv	s7,a2
    800017ce:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017d0:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017d2:	6985                	lui	s3,0x1
    800017d4:	a035                	j	80001800 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017d6:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017da:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017dc:	0017b793          	seqz	a5,a5
    800017e0:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017e4:	60a6                	ld	ra,72(sp)
    800017e6:	6406                	ld	s0,64(sp)
    800017e8:	74e2                	ld	s1,56(sp)
    800017ea:	7942                	ld	s2,48(sp)
    800017ec:	79a2                	ld	s3,40(sp)
    800017ee:	7a02                	ld	s4,32(sp)
    800017f0:	6ae2                	ld	s5,24(sp)
    800017f2:	6b42                	ld	s6,16(sp)
    800017f4:	6ba2                	ld	s7,8(sp)
    800017f6:	6161                	addi	sp,sp,80
    800017f8:	8082                	ret
    srcva = va0 + PGSIZE;
    800017fa:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017fe:	c8a9                	beqz	s1,80001850 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001800:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001804:	85ca                	mv	a1,s2
    80001806:	8552                	mv	a0,s4
    80001808:	00000097          	auipc	ra,0x0
    8000180c:	89e080e7          	jalr	-1890(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    80001810:	c131                	beqz	a0,80001854 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001812:	41790833          	sub	a6,s2,s7
    80001816:	984e                	add	a6,a6,s3
    if(n > max)
    80001818:	0104f363          	bgeu	s1,a6,8000181e <copyinstr+0x6e>
    8000181c:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000181e:	955e                	add	a0,a0,s7
    80001820:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001824:	fc080be3          	beqz	a6,800017fa <copyinstr+0x4a>
    80001828:	985a                	add	a6,a6,s6
    8000182a:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000182c:	41650633          	sub	a2,a0,s6
    80001830:	14fd                	addi	s1,s1,-1
    80001832:	9b26                	add	s6,s6,s1
    80001834:	00f60733          	add	a4,a2,a5
    80001838:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    8000183c:	df49                	beqz	a4,800017d6 <copyinstr+0x26>
        *dst = *p;
    8000183e:	00e78023          	sb	a4,0(a5)
      --max;
    80001842:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001846:	0785                	addi	a5,a5,1
    while(n > 0){
    80001848:	ff0796e3          	bne	a5,a6,80001834 <copyinstr+0x84>
      dst++;
    8000184c:	8b42                	mv	s6,a6
    8000184e:	b775                	j	800017fa <copyinstr+0x4a>
    80001850:	4781                	li	a5,0
    80001852:	b769                	j	800017dc <copyinstr+0x2c>
      return -1;
    80001854:	557d                	li	a0,-1
    80001856:	b779                	j	800017e4 <copyinstr+0x34>
  int got_null = 0;
    80001858:	4781                	li	a5,0
  if(got_null){
    8000185a:	0017b793          	seqz	a5,a5
    8000185e:	40f00533          	neg	a0,a5
}
    80001862:	8082                	ret

0000000080001864 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001864:	1101                	addi	sp,sp,-32
    80001866:	ec06                	sd	ra,24(sp)
    80001868:	e822                	sd	s0,16(sp)
    8000186a:	e426                	sd	s1,8(sp)
    8000186c:	1000                	addi	s0,sp,32
    8000186e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001870:	fffff097          	auipc	ra,0xfffff
    80001874:	32e080e7          	jalr	814(ra) # 80000b9e <holding>
    80001878:	c909                	beqz	a0,8000188a <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    8000187a:	749c                	ld	a5,40(s1)
    8000187c:	00978f63          	beq	a5,s1,8000189a <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001880:	60e2                	ld	ra,24(sp)
    80001882:	6442                	ld	s0,16(sp)
    80001884:	64a2                	ld	s1,8(sp)
    80001886:	6105                	addi	sp,sp,32
    80001888:	8082                	ret
    panic("wakeup1");
    8000188a:	00007517          	auipc	a0,0x7
    8000188e:	93650513          	addi	a0,a0,-1738 # 800081c0 <digits+0x180>
    80001892:	fffff097          	auipc	ra,0xfffff
    80001896:	cbe080e7          	jalr	-834(ra) # 80000550 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    8000189a:	4c98                	lw	a4,24(s1)
    8000189c:	4785                	li	a5,1
    8000189e:	fef711e3          	bne	a4,a5,80001880 <wakeup1+0x1c>
    p->state = RUNNABLE;
    800018a2:	4789                	li	a5,2
    800018a4:	cc9c                	sw	a5,24(s1)
}
    800018a6:	bfe9                	j	80001880 <wakeup1+0x1c>

00000000800018a8 <proc_mapstacks>:
proc_mapstacks(pagetable_t kpgtbl) {
    800018a8:	7139                	addi	sp,sp,-64
    800018aa:	fc06                	sd	ra,56(sp)
    800018ac:	f822                	sd	s0,48(sp)
    800018ae:	f426                	sd	s1,40(sp)
    800018b0:	f04a                	sd	s2,32(sp)
    800018b2:	ec4e                	sd	s3,24(sp)
    800018b4:	e852                	sd	s4,16(sp)
    800018b6:	e456                	sd	s5,8(sp)
    800018b8:	e05a                	sd	s6,0(sp)
    800018ba:	0080                	addi	s0,sp,64
    800018bc:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800018be:	00010497          	auipc	s1,0x10
    800018c2:	dea48493          	addi	s1,s1,-534 # 800116a8 <proc>
    uint64 va = KSTACK((int) (p - proc));
    800018c6:	8b26                	mv	s6,s1
    800018c8:	00006a97          	auipc	s5,0x6
    800018cc:	738a8a93          	addi	s5,s5,1848 # 80008000 <etext>
    800018d0:	04000937          	lui	s2,0x4000
    800018d4:	197d                	addi	s2,s2,-1
    800018d6:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018d8:	00015a17          	auipc	s4,0x15
    800018dc:	7d0a0a13          	addi	s4,s4,2000 # 800170a8 <tickslock>
    char *pa = kalloc();
    800018e0:	fffff097          	auipc	ra,0xfffff
    800018e4:	248080e7          	jalr	584(ra) # 80000b28 <kalloc>
    800018e8:	862a                	mv	a2,a0
    if(pa == 0)
    800018ea:	c131                	beqz	a0,8000192e <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018ec:	416485b3          	sub	a1,s1,s6
    800018f0:	858d                	srai	a1,a1,0x3
    800018f2:	000ab783          	ld	a5,0(s5)
    800018f6:	02f585b3          	mul	a1,a1,a5
    800018fa:	2585                	addiw	a1,a1,1
    800018fc:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001900:	4719                	li	a4,6
    80001902:	6685                	lui	a3,0x1
    80001904:	40b905b3          	sub	a1,s2,a1
    80001908:	854e                	mv	a0,s3
    8000190a:	00000097          	auipc	ra,0x0
    8000190e:	86c080e7          	jalr	-1940(ra) # 80001176 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001912:	16848493          	addi	s1,s1,360
    80001916:	fd4495e3          	bne	s1,s4,800018e0 <proc_mapstacks+0x38>
}
    8000191a:	70e2                	ld	ra,56(sp)
    8000191c:	7442                	ld	s0,48(sp)
    8000191e:	74a2                	ld	s1,40(sp)
    80001920:	7902                	ld	s2,32(sp)
    80001922:	69e2                	ld	s3,24(sp)
    80001924:	6a42                	ld	s4,16(sp)
    80001926:	6aa2                	ld	s5,8(sp)
    80001928:	6b02                	ld	s6,0(sp)
    8000192a:	6121                	addi	sp,sp,64
    8000192c:	8082                	ret
      panic("kalloc");
    8000192e:	00007517          	auipc	a0,0x7
    80001932:	89a50513          	addi	a0,a0,-1894 # 800081c8 <digits+0x188>
    80001936:	fffff097          	auipc	ra,0xfffff
    8000193a:	c1a080e7          	jalr	-998(ra) # 80000550 <panic>

000000008000193e <procinit>:
{
    8000193e:	7139                	addi	sp,sp,-64
    80001940:	fc06                	sd	ra,56(sp)
    80001942:	f822                	sd	s0,48(sp)
    80001944:	f426                	sd	s1,40(sp)
    80001946:	f04a                	sd	s2,32(sp)
    80001948:	ec4e                	sd	s3,24(sp)
    8000194a:	e852                	sd	s4,16(sp)
    8000194c:	e456                	sd	s5,8(sp)
    8000194e:	e05a                	sd	s6,0(sp)
    80001950:	0080                	addi	s0,sp,64
  initlock(&pid_lock, "nextpid");
    80001952:	00007597          	auipc	a1,0x7
    80001956:	87e58593          	addi	a1,a1,-1922 # 800081d0 <digits+0x190>
    8000195a:	00010517          	auipc	a0,0x10
    8000195e:	93650513          	addi	a0,a0,-1738 # 80011290 <pid_lock>
    80001962:	fffff097          	auipc	ra,0xfffff
    80001966:	226080e7          	jalr	550(ra) # 80000b88 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196a:	00010497          	auipc	s1,0x10
    8000196e:	d3e48493          	addi	s1,s1,-706 # 800116a8 <proc>
      initlock(&p->lock, "proc");
    80001972:	00007b17          	auipc	s6,0x7
    80001976:	866b0b13          	addi	s6,s6,-1946 # 800081d8 <digits+0x198>
      p->kstack = KSTACK((int) (p - proc));
    8000197a:	8aa6                	mv	s5,s1
    8000197c:	00006a17          	auipc	s4,0x6
    80001980:	684a0a13          	addi	s4,s4,1668 # 80008000 <etext>
    80001984:	04000937          	lui	s2,0x4000
    80001988:	197d                	addi	s2,s2,-1
    8000198a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000198c:	00015997          	auipc	s3,0x15
    80001990:	71c98993          	addi	s3,s3,1820 # 800170a8 <tickslock>
      initlock(&p->lock, "proc");
    80001994:	85da                	mv	a1,s6
    80001996:	8526                	mv	a0,s1
    80001998:	fffff097          	auipc	ra,0xfffff
    8000199c:	1f0080e7          	jalr	496(ra) # 80000b88 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    800019a0:	415487b3          	sub	a5,s1,s5
    800019a4:	878d                	srai	a5,a5,0x3
    800019a6:	000a3703          	ld	a4,0(s4)
    800019aa:	02e787b3          	mul	a5,a5,a4
    800019ae:	2785                	addiw	a5,a5,1
    800019b0:	00d7979b          	slliw	a5,a5,0xd
    800019b4:	40f907b3          	sub	a5,s2,a5
    800019b8:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ba:	16848493          	addi	s1,s1,360
    800019be:	fd349be3          	bne	s1,s3,80001994 <procinit+0x56>
}
    800019c2:	70e2                	ld	ra,56(sp)
    800019c4:	7442                	ld	s0,48(sp)
    800019c6:	74a2                	ld	s1,40(sp)
    800019c8:	7902                	ld	s2,32(sp)
    800019ca:	69e2                	ld	s3,24(sp)
    800019cc:	6a42                	ld	s4,16(sp)
    800019ce:	6aa2                	ld	s5,8(sp)
    800019d0:	6b02                	ld	s6,0(sp)
    800019d2:	6121                	addi	sp,sp,64
    800019d4:	8082                	ret

00000000800019d6 <cpuid>:
{
    800019d6:	1141                	addi	sp,sp,-16
    800019d8:	e422                	sd	s0,8(sp)
    800019da:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019dc:	8512                	mv	a0,tp
}
    800019de:	2501                	sext.w	a0,a0
    800019e0:	6422                	ld	s0,8(sp)
    800019e2:	0141                	addi	sp,sp,16
    800019e4:	8082                	ret

00000000800019e6 <mycpu>:
mycpu(void) {
    800019e6:	1141                	addi	sp,sp,-16
    800019e8:	e422                	sd	s0,8(sp)
    800019ea:	0800                	addi	s0,sp,16
    800019ec:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800019ee:	2781                	sext.w	a5,a5
    800019f0:	079e                	slli	a5,a5,0x7
}
    800019f2:	00010517          	auipc	a0,0x10
    800019f6:	8b650513          	addi	a0,a0,-1866 # 800112a8 <cpus>
    800019fa:	953e                	add	a0,a0,a5
    800019fc:	6422                	ld	s0,8(sp)
    800019fe:	0141                	addi	sp,sp,16
    80001a00:	8082                	ret

0000000080001a02 <myproc>:
myproc(void) {
    80001a02:	1101                	addi	sp,sp,-32
    80001a04:	ec06                	sd	ra,24(sp)
    80001a06:	e822                	sd	s0,16(sp)
    80001a08:	e426                	sd	s1,8(sp)
    80001a0a:	1000                	addi	s0,sp,32
  push_off();
    80001a0c:	fffff097          	auipc	ra,0xfffff
    80001a10:	1c0080e7          	jalr	448(ra) # 80000bcc <push_off>
    80001a14:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a16:	2781                	sext.w	a5,a5
    80001a18:	079e                	slli	a5,a5,0x7
    80001a1a:	00010717          	auipc	a4,0x10
    80001a1e:	87670713          	addi	a4,a4,-1930 # 80011290 <pid_lock>
    80001a22:	97ba                	add	a5,a5,a4
    80001a24:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	246080e7          	jalr	582(ra) # 80000c6c <pop_off>
}
    80001a2e:	8526                	mv	a0,s1
    80001a30:	60e2                	ld	ra,24(sp)
    80001a32:	6442                	ld	s0,16(sp)
    80001a34:	64a2                	ld	s1,8(sp)
    80001a36:	6105                	addi	sp,sp,32
    80001a38:	8082                	ret

0000000080001a3a <forkret>:
{
    80001a3a:	1141                	addi	sp,sp,-16
    80001a3c:	e406                	sd	ra,8(sp)
    80001a3e:	e022                	sd	s0,0(sp)
    80001a40:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a42:	00000097          	auipc	ra,0x0
    80001a46:	fc0080e7          	jalr	-64(ra) # 80001a02 <myproc>
    80001a4a:	fffff097          	auipc	ra,0xfffff
    80001a4e:	282080e7          	jalr	642(ra) # 80000ccc <release>
  if (first) {
    80001a52:	00007797          	auipc	a5,0x7
    80001a56:	dae7a783          	lw	a5,-594(a5) # 80008800 <first.1669>
    80001a5a:	eb89                	bnez	a5,80001a6c <forkret+0x32>
  usertrapret();
    80001a5c:	00001097          	auipc	ra,0x1
    80001a60:	bf8080e7          	jalr	-1032(ra) # 80002654 <usertrapret>
}
    80001a64:	60a2                	ld	ra,8(sp)
    80001a66:	6402                	ld	s0,0(sp)
    80001a68:	0141                	addi	sp,sp,16
    80001a6a:	8082                	ret
    first = 0;
    80001a6c:	00007797          	auipc	a5,0x7
    80001a70:	d807aa23          	sw	zero,-620(a5) # 80008800 <first.1669>
    fsinit(ROOTDEV);
    80001a74:	4505                	li	a0,1
    80001a76:	00002097          	auipc	ra,0x2
    80001a7a:	920080e7          	jalr	-1760(ra) # 80003396 <fsinit>
    80001a7e:	bff9                	j	80001a5c <forkret+0x22>

0000000080001a80 <allocpid>:
allocpid() {
    80001a80:	1101                	addi	sp,sp,-32
    80001a82:	ec06                	sd	ra,24(sp)
    80001a84:	e822                	sd	s0,16(sp)
    80001a86:	e426                	sd	s1,8(sp)
    80001a88:	e04a                	sd	s2,0(sp)
    80001a8a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a8c:	00010917          	auipc	s2,0x10
    80001a90:	80490913          	addi	s2,s2,-2044 # 80011290 <pid_lock>
    80001a94:	854a                	mv	a0,s2
    80001a96:	fffff097          	auipc	ra,0xfffff
    80001a9a:	182080e7          	jalr	386(ra) # 80000c18 <acquire>
  pid = nextpid;
    80001a9e:	00007797          	auipc	a5,0x7
    80001aa2:	d6678793          	addi	a5,a5,-666 # 80008804 <nextpid>
    80001aa6:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001aa8:	0014871b          	addiw	a4,s1,1
    80001aac:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aae:	854a                	mv	a0,s2
    80001ab0:	fffff097          	auipc	ra,0xfffff
    80001ab4:	21c080e7          	jalr	540(ra) # 80000ccc <release>
}
    80001ab8:	8526                	mv	a0,s1
    80001aba:	60e2                	ld	ra,24(sp)
    80001abc:	6442                	ld	s0,16(sp)
    80001abe:	64a2                	ld	s1,8(sp)
    80001ac0:	6902                	ld	s2,0(sp)
    80001ac2:	6105                	addi	sp,sp,32
    80001ac4:	8082                	ret

0000000080001ac6 <proc_pagetable>:
{
    80001ac6:	1101                	addi	sp,sp,-32
    80001ac8:	ec06                	sd	ra,24(sp)
    80001aca:	e822                	sd	s0,16(sp)
    80001acc:	e426                	sd	s1,8(sp)
    80001ace:	e04a                	sd	s2,0(sp)
    80001ad0:	1000                	addi	s0,sp,32
    80001ad2:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ad4:	00000097          	auipc	ra,0x0
    80001ad8:	88c080e7          	jalr	-1908(ra) # 80001360 <uvmcreate>
    80001adc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ade:	c121                	beqz	a0,80001b1e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ae0:	4729                	li	a4,10
    80001ae2:	00005697          	auipc	a3,0x5
    80001ae6:	51e68693          	addi	a3,a3,1310 # 80007000 <_trampoline>
    80001aea:	6605                	lui	a2,0x1
    80001aec:	040005b7          	lui	a1,0x4000
    80001af0:	15fd                	addi	a1,a1,-1
    80001af2:	05b2                	slli	a1,a1,0xc
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	5f4080e7          	jalr	1524(ra) # 800010e8 <mappages>
    80001afc:	02054863          	bltz	a0,80001b2c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b00:	4719                	li	a4,6
    80001b02:	05893683          	ld	a3,88(s2)
    80001b06:	6605                	lui	a2,0x1
    80001b08:	020005b7          	lui	a1,0x2000
    80001b0c:	15fd                	addi	a1,a1,-1
    80001b0e:	05b6                	slli	a1,a1,0xd
    80001b10:	8526                	mv	a0,s1
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	5d6080e7          	jalr	1494(ra) # 800010e8 <mappages>
    80001b1a:	02054163          	bltz	a0,80001b3c <proc_pagetable+0x76>
}
    80001b1e:	8526                	mv	a0,s1
    80001b20:	60e2                	ld	ra,24(sp)
    80001b22:	6442                	ld	s0,16(sp)
    80001b24:	64a2                	ld	s1,8(sp)
    80001b26:	6902                	ld	s2,0(sp)
    80001b28:	6105                	addi	sp,sp,32
    80001b2a:	8082                	ret
    uvmfree(pagetable, 0);
    80001b2c:	4581                	li	a1,0
    80001b2e:	8526                	mv	a0,s1
    80001b30:	00000097          	auipc	ra,0x0
    80001b34:	a2c080e7          	jalr	-1492(ra) # 8000155c <uvmfree>
    return 0;
    80001b38:	4481                	li	s1,0
    80001b3a:	b7d5                	j	80001b1e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b3c:	4681                	li	a3,0
    80001b3e:	4605                	li	a2,1
    80001b40:	040005b7          	lui	a1,0x4000
    80001b44:	15fd                	addi	a1,a1,-1
    80001b46:	05b2                	slli	a1,a1,0xc
    80001b48:	8526                	mv	a0,s1
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	752080e7          	jalr	1874(ra) # 8000129c <uvmunmap>
    uvmfree(pagetable, 0);
    80001b52:	4581                	li	a1,0
    80001b54:	8526                	mv	a0,s1
    80001b56:	00000097          	auipc	ra,0x0
    80001b5a:	a06080e7          	jalr	-1530(ra) # 8000155c <uvmfree>
    return 0;
    80001b5e:	4481                	li	s1,0
    80001b60:	bf7d                	j	80001b1e <proc_pagetable+0x58>

0000000080001b62 <proc_freepagetable>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	e04a                	sd	s2,0(sp)
    80001b6c:	1000                	addi	s0,sp,32
    80001b6e:	84aa                	mv	s1,a0
    80001b70:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b72:	4681                	li	a3,0
    80001b74:	4605                	li	a2,1
    80001b76:	040005b7          	lui	a1,0x4000
    80001b7a:	15fd                	addi	a1,a1,-1
    80001b7c:	05b2                	slli	a1,a1,0xc
    80001b7e:	fffff097          	auipc	ra,0xfffff
    80001b82:	71e080e7          	jalr	1822(ra) # 8000129c <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b86:	4681                	li	a3,0
    80001b88:	4605                	li	a2,1
    80001b8a:	020005b7          	lui	a1,0x2000
    80001b8e:	15fd                	addi	a1,a1,-1
    80001b90:	05b6                	slli	a1,a1,0xd
    80001b92:	8526                	mv	a0,s1
    80001b94:	fffff097          	auipc	ra,0xfffff
    80001b98:	708080e7          	jalr	1800(ra) # 8000129c <uvmunmap>
  uvmfree(pagetable, sz);
    80001b9c:	85ca                	mv	a1,s2
    80001b9e:	8526                	mv	a0,s1
    80001ba0:	00000097          	auipc	ra,0x0
    80001ba4:	9bc080e7          	jalr	-1604(ra) # 8000155c <uvmfree>
}
    80001ba8:	60e2                	ld	ra,24(sp)
    80001baa:	6442                	ld	s0,16(sp)
    80001bac:	64a2                	ld	s1,8(sp)
    80001bae:	6902                	ld	s2,0(sp)
    80001bb0:	6105                	addi	sp,sp,32
    80001bb2:	8082                	ret

0000000080001bb4 <freeproc>:
{
    80001bb4:	1101                	addi	sp,sp,-32
    80001bb6:	ec06                	sd	ra,24(sp)
    80001bb8:	e822                	sd	s0,16(sp)
    80001bba:	e426                	sd	s1,8(sp)
    80001bbc:	1000                	addi	s0,sp,32
    80001bbe:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bc0:	6d28                	ld	a0,88(a0)
    80001bc2:	c509                	beqz	a0,80001bcc <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bc4:	fffff097          	auipc	ra,0xfffff
    80001bc8:	e68080e7          	jalr	-408(ra) # 80000a2c <kfree>
  p->trapframe = 0;
    80001bcc:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bd0:	68a8                	ld	a0,80(s1)
    80001bd2:	c511                	beqz	a0,80001bde <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bd4:	64ac                	ld	a1,72(s1)
    80001bd6:	00000097          	auipc	ra,0x0
    80001bda:	f8c080e7          	jalr	-116(ra) # 80001b62 <proc_freepagetable>
  p->pagetable = 0;
    80001bde:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001be2:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001be6:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001bea:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001bee:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bf2:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001bf6:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001bfa:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001bfe:	0004ac23          	sw	zero,24(s1)
}
    80001c02:	60e2                	ld	ra,24(sp)
    80001c04:	6442                	ld	s0,16(sp)
    80001c06:	64a2                	ld	s1,8(sp)
    80001c08:	6105                	addi	sp,sp,32
    80001c0a:	8082                	ret

0000000080001c0c <allocproc>:
{
    80001c0c:	1101                	addi	sp,sp,-32
    80001c0e:	ec06                	sd	ra,24(sp)
    80001c10:	e822                	sd	s0,16(sp)
    80001c12:	e426                	sd	s1,8(sp)
    80001c14:	e04a                	sd	s2,0(sp)
    80001c16:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c18:	00010497          	auipc	s1,0x10
    80001c1c:	a9048493          	addi	s1,s1,-1392 # 800116a8 <proc>
    80001c20:	00015917          	auipc	s2,0x15
    80001c24:	48890913          	addi	s2,s2,1160 # 800170a8 <tickslock>
    acquire(&p->lock);
    80001c28:	8526                	mv	a0,s1
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	fee080e7          	jalr	-18(ra) # 80000c18 <acquire>
    if(p->state == UNUSED) {
    80001c32:	4c9c                	lw	a5,24(s1)
    80001c34:	cf81                	beqz	a5,80001c4c <allocproc+0x40>
      release(&p->lock);
    80001c36:	8526                	mv	a0,s1
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	094080e7          	jalr	148(ra) # 80000ccc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c40:	16848493          	addi	s1,s1,360
    80001c44:	ff2492e3          	bne	s1,s2,80001c28 <allocproc+0x1c>
  return 0;
    80001c48:	4481                	li	s1,0
    80001c4a:	a0b9                	j	80001c98 <allocproc+0x8c>
  p->pid = allocpid();
    80001c4c:	00000097          	auipc	ra,0x0
    80001c50:	e34080e7          	jalr	-460(ra) # 80001a80 <allocpid>
    80001c54:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	ed2080e7          	jalr	-302(ra) # 80000b28 <kalloc>
    80001c5e:	892a                	mv	s2,a0
    80001c60:	eca8                	sd	a0,88(s1)
    80001c62:	c131                	beqz	a0,80001ca6 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c64:	8526                	mv	a0,s1
    80001c66:	00000097          	auipc	ra,0x0
    80001c6a:	e60080e7          	jalr	-416(ra) # 80001ac6 <proc_pagetable>
    80001c6e:	892a                	mv	s2,a0
    80001c70:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c72:	c129                	beqz	a0,80001cb4 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c74:	07000613          	li	a2,112
    80001c78:	4581                	li	a1,0
    80001c7a:	06048513          	addi	a0,s1,96
    80001c7e:	fffff097          	auipc	ra,0xfffff
    80001c82:	096080e7          	jalr	150(ra) # 80000d14 <memset>
  p->context.ra = (uint64)forkret;
    80001c86:	00000797          	auipc	a5,0x0
    80001c8a:	db478793          	addi	a5,a5,-588 # 80001a3a <forkret>
    80001c8e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c90:	60bc                	ld	a5,64(s1)
    80001c92:	6705                	lui	a4,0x1
    80001c94:	97ba                	add	a5,a5,a4
    80001c96:	f4bc                	sd	a5,104(s1)
}
    80001c98:	8526                	mv	a0,s1
    80001c9a:	60e2                	ld	ra,24(sp)
    80001c9c:	6442                	ld	s0,16(sp)
    80001c9e:	64a2                	ld	s1,8(sp)
    80001ca0:	6902                	ld	s2,0(sp)
    80001ca2:	6105                	addi	sp,sp,32
    80001ca4:	8082                	ret
    release(&p->lock);
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	024080e7          	jalr	36(ra) # 80000ccc <release>
    return 0;
    80001cb0:	84ca                	mv	s1,s2
    80001cb2:	b7dd                	j	80001c98 <allocproc+0x8c>
    freeproc(p);
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	efe080e7          	jalr	-258(ra) # 80001bb4 <freeproc>
    release(&p->lock);
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	00c080e7          	jalr	12(ra) # 80000ccc <release>
    return 0;
    80001cc8:	84ca                	mv	s1,s2
    80001cca:	b7f9                	j	80001c98 <allocproc+0x8c>

0000000080001ccc <userinit>:
{
    80001ccc:	1101                	addi	sp,sp,-32
    80001cce:	ec06                	sd	ra,24(sp)
    80001cd0:	e822                	sd	s0,16(sp)
    80001cd2:	e426                	sd	s1,8(sp)
    80001cd4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cd6:	00000097          	auipc	ra,0x0
    80001cda:	f36080e7          	jalr	-202(ra) # 80001c0c <allocproc>
    80001cde:	84aa                	mv	s1,a0
  initproc = p;
    80001ce0:	00007797          	auipc	a5,0x7
    80001ce4:	32a7bc23          	sd	a0,824(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ce8:	03400613          	li	a2,52
    80001cec:	00007597          	auipc	a1,0x7
    80001cf0:	b2458593          	addi	a1,a1,-1244 # 80008810 <initcode>
    80001cf4:	6928                	ld	a0,80(a0)
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	698080e7          	jalr	1688(ra) # 8000138e <uvminit>
  p->sz = PGSIZE;
    80001cfe:	6785                	lui	a5,0x1
    80001d00:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d02:	6cb8                	ld	a4,88(s1)
    80001d04:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d08:	6cb8                	ld	a4,88(s1)
    80001d0a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d0c:	4641                	li	a2,16
    80001d0e:	00006597          	auipc	a1,0x6
    80001d12:	4d258593          	addi	a1,a1,1234 # 800081e0 <digits+0x1a0>
    80001d16:	15848513          	addi	a0,s1,344
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	150080e7          	jalr	336(ra) # 80000e6a <safestrcpy>
  p->cwd = namei("/");
    80001d22:	00006517          	auipc	a0,0x6
    80001d26:	4ce50513          	addi	a0,a0,1230 # 800081f0 <digits+0x1b0>
    80001d2a:	00002097          	auipc	ra,0x2
    80001d2e:	098080e7          	jalr	152(ra) # 80003dc2 <namei>
    80001d32:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d36:	4789                	li	a5,2
    80001d38:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d3a:	8526                	mv	a0,s1
    80001d3c:	fffff097          	auipc	ra,0xfffff
    80001d40:	f90080e7          	jalr	-112(ra) # 80000ccc <release>
}
    80001d44:	60e2                	ld	ra,24(sp)
    80001d46:	6442                	ld	s0,16(sp)
    80001d48:	64a2                	ld	s1,8(sp)
    80001d4a:	6105                	addi	sp,sp,32
    80001d4c:	8082                	ret

0000000080001d4e <growproc>:
{
    80001d4e:	1101                	addi	sp,sp,-32
    80001d50:	ec06                	sd	ra,24(sp)
    80001d52:	e822                	sd	s0,16(sp)
    80001d54:	e426                	sd	s1,8(sp)
    80001d56:	e04a                	sd	s2,0(sp)
    80001d58:	1000                	addi	s0,sp,32
    80001d5a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d5c:	00000097          	auipc	ra,0x0
    80001d60:	ca6080e7          	jalr	-858(ra) # 80001a02 <myproc>
    80001d64:	892a                	mv	s2,a0
  sz = p->sz;
    80001d66:	652c                	ld	a1,72(a0)
    80001d68:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d6c:	00904f63          	bgtz	s1,80001d8a <growproc+0x3c>
  } else if(n < 0){
    80001d70:	0204cc63          	bltz	s1,80001da8 <growproc+0x5a>
  p->sz = sz;
    80001d74:	1602                	slli	a2,a2,0x20
    80001d76:	9201                	srli	a2,a2,0x20
    80001d78:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d7c:	4501                	li	a0,0
}
    80001d7e:	60e2                	ld	ra,24(sp)
    80001d80:	6442                	ld	s0,16(sp)
    80001d82:	64a2                	ld	s1,8(sp)
    80001d84:	6902                	ld	s2,0(sp)
    80001d86:	6105                	addi	sp,sp,32
    80001d88:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d8a:	9e25                	addw	a2,a2,s1
    80001d8c:	1602                	slli	a2,a2,0x20
    80001d8e:	9201                	srli	a2,a2,0x20
    80001d90:	1582                	slli	a1,a1,0x20
    80001d92:	9181                	srli	a1,a1,0x20
    80001d94:	6928                	ld	a0,80(a0)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	6b2080e7          	jalr	1714(ra) # 80001448 <uvmalloc>
    80001d9e:	0005061b          	sext.w	a2,a0
    80001da2:	fa69                	bnez	a2,80001d74 <growproc+0x26>
      return -1;
    80001da4:	557d                	li	a0,-1
    80001da6:	bfe1                	j	80001d7e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001da8:	9e25                	addw	a2,a2,s1
    80001daa:	1602                	slli	a2,a2,0x20
    80001dac:	9201                	srli	a2,a2,0x20
    80001dae:	1582                	slli	a1,a1,0x20
    80001db0:	9181                	srli	a1,a1,0x20
    80001db2:	6928                	ld	a0,80(a0)
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	64c080e7          	jalr	1612(ra) # 80001400 <uvmdealloc>
    80001dbc:	0005061b          	sext.w	a2,a0
    80001dc0:	bf55                	j	80001d74 <growproc+0x26>

0000000080001dc2 <fork>:
{
    80001dc2:	7179                	addi	sp,sp,-48
    80001dc4:	f406                	sd	ra,40(sp)
    80001dc6:	f022                	sd	s0,32(sp)
    80001dc8:	ec26                	sd	s1,24(sp)
    80001dca:	e84a                	sd	s2,16(sp)
    80001dcc:	e44e                	sd	s3,8(sp)
    80001dce:	e052                	sd	s4,0(sp)
    80001dd0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dd2:	00000097          	auipc	ra,0x0
    80001dd6:	c30080e7          	jalr	-976(ra) # 80001a02 <myproc>
    80001dda:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001ddc:	00000097          	auipc	ra,0x0
    80001de0:	e30080e7          	jalr	-464(ra) # 80001c0c <allocproc>
    80001de4:	c175                	beqz	a0,80001ec8 <fork+0x106>
    80001de6:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001de8:	04893603          	ld	a2,72(s2)
    80001dec:	692c                	ld	a1,80(a0)
    80001dee:	05093503          	ld	a0,80(s2)
    80001df2:	fffff097          	auipc	ra,0xfffff
    80001df6:	7a2080e7          	jalr	1954(ra) # 80001594 <uvmcopy>
    80001dfa:	04054863          	bltz	a0,80001e4a <fork+0x88>
  np->sz = p->sz;
    80001dfe:	04893783          	ld	a5,72(s2)
    80001e02:	04f9b423          	sd	a5,72(s3)
  np->parent = p;
    80001e06:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e0a:	05893683          	ld	a3,88(s2)
    80001e0e:	87b6                	mv	a5,a3
    80001e10:	0589b703          	ld	a4,88(s3)
    80001e14:	12068693          	addi	a3,a3,288
    80001e18:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e1c:	6788                	ld	a0,8(a5)
    80001e1e:	6b8c                	ld	a1,16(a5)
    80001e20:	6f90                	ld	a2,24(a5)
    80001e22:	01073023          	sd	a6,0(a4)
    80001e26:	e708                	sd	a0,8(a4)
    80001e28:	eb0c                	sd	a1,16(a4)
    80001e2a:	ef10                	sd	a2,24(a4)
    80001e2c:	02078793          	addi	a5,a5,32
    80001e30:	02070713          	addi	a4,a4,32
    80001e34:	fed792e3          	bne	a5,a3,80001e18 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e38:	0589b783          	ld	a5,88(s3)
    80001e3c:	0607b823          	sd	zero,112(a5)
    80001e40:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e44:	15000a13          	li	s4,336
    80001e48:	a03d                	j	80001e76 <fork+0xb4>
    freeproc(np);
    80001e4a:	854e                	mv	a0,s3
    80001e4c:	00000097          	auipc	ra,0x0
    80001e50:	d68080e7          	jalr	-664(ra) # 80001bb4 <freeproc>
    release(&np->lock);
    80001e54:	854e                	mv	a0,s3
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	e76080e7          	jalr	-394(ra) # 80000ccc <release>
    return -1;
    80001e5e:	54fd                	li	s1,-1
    80001e60:	a899                	j	80001eb6 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e62:	00002097          	auipc	ra,0x2
    80001e66:	5fe080e7          	jalr	1534(ra) # 80004460 <filedup>
    80001e6a:	009987b3          	add	a5,s3,s1
    80001e6e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e70:	04a1                	addi	s1,s1,8
    80001e72:	01448763          	beq	s1,s4,80001e80 <fork+0xbe>
    if(p->ofile[i])
    80001e76:	009907b3          	add	a5,s2,s1
    80001e7a:	6388                	ld	a0,0(a5)
    80001e7c:	f17d                	bnez	a0,80001e62 <fork+0xa0>
    80001e7e:	bfcd                	j	80001e70 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001e80:	15093503          	ld	a0,336(s2)
    80001e84:	00001097          	auipc	ra,0x1
    80001e88:	74c080e7          	jalr	1868(ra) # 800035d0 <idup>
    80001e8c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e90:	4641                	li	a2,16
    80001e92:	15890593          	addi	a1,s2,344
    80001e96:	15898513          	addi	a0,s3,344
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	fd0080e7          	jalr	-48(ra) # 80000e6a <safestrcpy>
  pid = np->pid;
    80001ea2:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001ea6:	4789                	li	a5,2
    80001ea8:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eac:	854e                	mv	a0,s3
    80001eae:	fffff097          	auipc	ra,0xfffff
    80001eb2:	e1e080e7          	jalr	-482(ra) # 80000ccc <release>
}
    80001eb6:	8526                	mv	a0,s1
    80001eb8:	70a2                	ld	ra,40(sp)
    80001eba:	7402                	ld	s0,32(sp)
    80001ebc:	64e2                	ld	s1,24(sp)
    80001ebe:	6942                	ld	s2,16(sp)
    80001ec0:	69a2                	ld	s3,8(sp)
    80001ec2:	6a02                	ld	s4,0(sp)
    80001ec4:	6145                	addi	sp,sp,48
    80001ec6:	8082                	ret
    return -1;
    80001ec8:	54fd                	li	s1,-1
    80001eca:	b7f5                	j	80001eb6 <fork+0xf4>

0000000080001ecc <reparent>:
{
    80001ecc:	7179                	addi	sp,sp,-48
    80001ece:	f406                	sd	ra,40(sp)
    80001ed0:	f022                	sd	s0,32(sp)
    80001ed2:	ec26                	sd	s1,24(sp)
    80001ed4:	e84a                	sd	s2,16(sp)
    80001ed6:	e44e                	sd	s3,8(sp)
    80001ed8:	e052                	sd	s4,0(sp)
    80001eda:	1800                	addi	s0,sp,48
    80001edc:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ede:	0000f497          	auipc	s1,0xf
    80001ee2:	7ca48493          	addi	s1,s1,1994 # 800116a8 <proc>
      pp->parent = initproc;
    80001ee6:	00007a17          	auipc	s4,0x7
    80001eea:	132a0a13          	addi	s4,s4,306 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001eee:	00015997          	auipc	s3,0x15
    80001ef2:	1ba98993          	addi	s3,s3,442 # 800170a8 <tickslock>
    80001ef6:	a029                	j	80001f00 <reparent+0x34>
    80001ef8:	16848493          	addi	s1,s1,360
    80001efc:	03348363          	beq	s1,s3,80001f22 <reparent+0x56>
    if(pp->parent == p){
    80001f00:	709c                	ld	a5,32(s1)
    80001f02:	ff279be3          	bne	a5,s2,80001ef8 <reparent+0x2c>
      acquire(&pp->lock);
    80001f06:	8526                	mv	a0,s1
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	d10080e7          	jalr	-752(ra) # 80000c18 <acquire>
      pp->parent = initproc;
    80001f10:	000a3783          	ld	a5,0(s4)
    80001f14:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	db4080e7          	jalr	-588(ra) # 80000ccc <release>
    80001f20:	bfe1                	j	80001ef8 <reparent+0x2c>
}
    80001f22:	70a2                	ld	ra,40(sp)
    80001f24:	7402                	ld	s0,32(sp)
    80001f26:	64e2                	ld	s1,24(sp)
    80001f28:	6942                	ld	s2,16(sp)
    80001f2a:	69a2                	ld	s3,8(sp)
    80001f2c:	6a02                	ld	s4,0(sp)
    80001f2e:	6145                	addi	sp,sp,48
    80001f30:	8082                	ret

0000000080001f32 <scheduler>:
{
    80001f32:	7139                	addi	sp,sp,-64
    80001f34:	fc06                	sd	ra,56(sp)
    80001f36:	f822                	sd	s0,48(sp)
    80001f38:	f426                	sd	s1,40(sp)
    80001f3a:	f04a                	sd	s2,32(sp)
    80001f3c:	ec4e                	sd	s3,24(sp)
    80001f3e:	e852                	sd	s4,16(sp)
    80001f40:	e456                	sd	s5,8(sp)
    80001f42:	e05a                	sd	s6,0(sp)
    80001f44:	0080                	addi	s0,sp,64
    80001f46:	8792                	mv	a5,tp
  int id = r_tp();
    80001f48:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f4a:	00779a93          	slli	s5,a5,0x7
    80001f4e:	0000f717          	auipc	a4,0xf
    80001f52:	34270713          	addi	a4,a4,834 # 80011290 <pid_lock>
    80001f56:	9756                	add	a4,a4,s5
    80001f58:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f5c:	0000f717          	auipc	a4,0xf
    80001f60:	35470713          	addi	a4,a4,852 # 800112b0 <cpus+0x8>
    80001f64:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f66:	4989                	li	s3,2
        p->state = RUNNING;
    80001f68:	4b0d                	li	s6,3
        c->proc = p;
    80001f6a:	079e                	slli	a5,a5,0x7
    80001f6c:	0000fa17          	auipc	s4,0xf
    80001f70:	324a0a13          	addi	s4,s4,804 # 80011290 <pid_lock>
    80001f74:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f76:	00015917          	auipc	s2,0x15
    80001f7a:	13290913          	addi	s2,s2,306 # 800170a8 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f7e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f82:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f86:	10079073          	csrw	sstatus,a5
    80001f8a:	0000f497          	auipc	s1,0xf
    80001f8e:	71e48493          	addi	s1,s1,1822 # 800116a8 <proc>
    80001f92:	a03d                	j	80001fc0 <scheduler+0x8e>
        p->state = RUNNING;
    80001f94:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f98:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001f9c:	06048593          	addi	a1,s1,96
    80001fa0:	8556                	mv	a0,s5
    80001fa2:	00000097          	auipc	ra,0x0
    80001fa6:	608080e7          	jalr	1544(ra) # 800025aa <swtch>
        c->proc = 0;
    80001faa:	000a3c23          	sd	zero,24(s4)
      release(&p->lock);
    80001fae:	8526                	mv	a0,s1
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	d1c080e7          	jalr	-740(ra) # 80000ccc <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fb8:	16848493          	addi	s1,s1,360
    80001fbc:	fd2481e3          	beq	s1,s2,80001f7e <scheduler+0x4c>
      acquire(&p->lock);
    80001fc0:	8526                	mv	a0,s1
    80001fc2:	fffff097          	auipc	ra,0xfffff
    80001fc6:	c56080e7          	jalr	-938(ra) # 80000c18 <acquire>
      if(p->state == RUNNABLE) {
    80001fca:	4c9c                	lw	a5,24(s1)
    80001fcc:	ff3791e3          	bne	a5,s3,80001fae <scheduler+0x7c>
    80001fd0:	b7d1                	j	80001f94 <scheduler+0x62>

0000000080001fd2 <sched>:
{
    80001fd2:	7179                	addi	sp,sp,-48
    80001fd4:	f406                	sd	ra,40(sp)
    80001fd6:	f022                	sd	s0,32(sp)
    80001fd8:	ec26                	sd	s1,24(sp)
    80001fda:	e84a                	sd	s2,16(sp)
    80001fdc:	e44e                	sd	s3,8(sp)
    80001fde:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fe0:	00000097          	auipc	ra,0x0
    80001fe4:	a22080e7          	jalr	-1502(ra) # 80001a02 <myproc>
    80001fe8:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fea:	fffff097          	auipc	ra,0xfffff
    80001fee:	bb4080e7          	jalr	-1100(ra) # 80000b9e <holding>
    80001ff2:	c93d                	beqz	a0,80002068 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ff4:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ff6:	2781                	sext.w	a5,a5
    80001ff8:	079e                	slli	a5,a5,0x7
    80001ffa:	0000f717          	auipc	a4,0xf
    80001ffe:	29670713          	addi	a4,a4,662 # 80011290 <pid_lock>
    80002002:	97ba                	add	a5,a5,a4
    80002004:	0907a703          	lw	a4,144(a5)
    80002008:	4785                	li	a5,1
    8000200a:	06f71763          	bne	a4,a5,80002078 <sched+0xa6>
  if(p->state == RUNNING)
    8000200e:	4c98                	lw	a4,24(s1)
    80002010:	478d                	li	a5,3
    80002012:	06f70b63          	beq	a4,a5,80002088 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002016:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000201a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000201c:	efb5                	bnez	a5,80002098 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000201e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002020:	0000f917          	auipc	s2,0xf
    80002024:	27090913          	addi	s2,s2,624 # 80011290 <pid_lock>
    80002028:	2781                	sext.w	a5,a5
    8000202a:	079e                	slli	a5,a5,0x7
    8000202c:	97ca                	add	a5,a5,s2
    8000202e:	0947a983          	lw	s3,148(a5)
    80002032:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002034:	2781                	sext.w	a5,a5
    80002036:	079e                	slli	a5,a5,0x7
    80002038:	0000f597          	auipc	a1,0xf
    8000203c:	27858593          	addi	a1,a1,632 # 800112b0 <cpus+0x8>
    80002040:	95be                	add	a1,a1,a5
    80002042:	06048513          	addi	a0,s1,96
    80002046:	00000097          	auipc	ra,0x0
    8000204a:	564080e7          	jalr	1380(ra) # 800025aa <swtch>
    8000204e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002050:	2781                	sext.w	a5,a5
    80002052:	079e                	slli	a5,a5,0x7
    80002054:	97ca                	add	a5,a5,s2
    80002056:	0937aa23          	sw	s3,148(a5)
}
    8000205a:	70a2                	ld	ra,40(sp)
    8000205c:	7402                	ld	s0,32(sp)
    8000205e:	64e2                	ld	s1,24(sp)
    80002060:	6942                	ld	s2,16(sp)
    80002062:	69a2                	ld	s3,8(sp)
    80002064:	6145                	addi	sp,sp,48
    80002066:	8082                	ret
    panic("sched p->lock");
    80002068:	00006517          	auipc	a0,0x6
    8000206c:	19050513          	addi	a0,a0,400 # 800081f8 <digits+0x1b8>
    80002070:	ffffe097          	auipc	ra,0xffffe
    80002074:	4e0080e7          	jalr	1248(ra) # 80000550 <panic>
    panic("sched locks");
    80002078:	00006517          	auipc	a0,0x6
    8000207c:	19050513          	addi	a0,a0,400 # 80008208 <digits+0x1c8>
    80002080:	ffffe097          	auipc	ra,0xffffe
    80002084:	4d0080e7          	jalr	1232(ra) # 80000550 <panic>
    panic("sched running");
    80002088:	00006517          	auipc	a0,0x6
    8000208c:	19050513          	addi	a0,a0,400 # 80008218 <digits+0x1d8>
    80002090:	ffffe097          	auipc	ra,0xffffe
    80002094:	4c0080e7          	jalr	1216(ra) # 80000550 <panic>
    panic("sched interruptible");
    80002098:	00006517          	auipc	a0,0x6
    8000209c:	19050513          	addi	a0,a0,400 # 80008228 <digits+0x1e8>
    800020a0:	ffffe097          	auipc	ra,0xffffe
    800020a4:	4b0080e7          	jalr	1200(ra) # 80000550 <panic>

00000000800020a8 <exit>:
{
    800020a8:	7179                	addi	sp,sp,-48
    800020aa:	f406                	sd	ra,40(sp)
    800020ac:	f022                	sd	s0,32(sp)
    800020ae:	ec26                	sd	s1,24(sp)
    800020b0:	e84a                	sd	s2,16(sp)
    800020b2:	e44e                	sd	s3,8(sp)
    800020b4:	e052                	sd	s4,0(sp)
    800020b6:	1800                	addi	s0,sp,48
    800020b8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800020ba:	00000097          	auipc	ra,0x0
    800020be:	948080e7          	jalr	-1720(ra) # 80001a02 <myproc>
    800020c2:	89aa                	mv	s3,a0
  if(p == initproc)
    800020c4:	00007797          	auipc	a5,0x7
    800020c8:	f547b783          	ld	a5,-172(a5) # 80009018 <initproc>
    800020cc:	0d050493          	addi	s1,a0,208
    800020d0:	15050913          	addi	s2,a0,336
    800020d4:	02a79363          	bne	a5,a0,800020fa <exit+0x52>
    panic("init exiting");
    800020d8:	00006517          	auipc	a0,0x6
    800020dc:	16850513          	addi	a0,a0,360 # 80008240 <digits+0x200>
    800020e0:	ffffe097          	auipc	ra,0xffffe
    800020e4:	470080e7          	jalr	1136(ra) # 80000550 <panic>
      fileclose(f);
    800020e8:	00002097          	auipc	ra,0x2
    800020ec:	3ca080e7          	jalr	970(ra) # 800044b2 <fileclose>
      p->ofile[fd] = 0;
    800020f0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800020f4:	04a1                	addi	s1,s1,8
    800020f6:	01248563          	beq	s1,s2,80002100 <exit+0x58>
    if(p->ofile[fd]){
    800020fa:	6088                	ld	a0,0(s1)
    800020fc:	f575                	bnez	a0,800020e8 <exit+0x40>
    800020fe:	bfdd                	j	800020f4 <exit+0x4c>
  begin_op();
    80002100:	00002097          	auipc	ra,0x2
    80002104:	ede080e7          	jalr	-290(ra) # 80003fde <begin_op>
  iput(p->cwd);
    80002108:	1509b503          	ld	a0,336(s3)
    8000210c:	00001097          	auipc	ra,0x1
    80002110:	6bc080e7          	jalr	1724(ra) # 800037c8 <iput>
  end_op();
    80002114:	00002097          	auipc	ra,0x2
    80002118:	f4a080e7          	jalr	-182(ra) # 8000405e <end_op>
  p->cwd = 0;
    8000211c:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002120:	00007497          	auipc	s1,0x7
    80002124:	ef848493          	addi	s1,s1,-264 # 80009018 <initproc>
    80002128:	6088                	ld	a0,0(s1)
    8000212a:	fffff097          	auipc	ra,0xfffff
    8000212e:	aee080e7          	jalr	-1298(ra) # 80000c18 <acquire>
  wakeup1(initproc);
    80002132:	6088                	ld	a0,0(s1)
    80002134:	fffff097          	auipc	ra,0xfffff
    80002138:	730080e7          	jalr	1840(ra) # 80001864 <wakeup1>
  release(&initproc->lock);
    8000213c:	6088                	ld	a0,0(s1)
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	b8e080e7          	jalr	-1138(ra) # 80000ccc <release>
  acquire(&p->lock);
    80002146:	854e                	mv	a0,s3
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	ad0080e7          	jalr	-1328(ra) # 80000c18 <acquire>
  struct proc *original_parent = p->parent;
    80002150:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002154:	854e                	mv	a0,s3
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	b76080e7          	jalr	-1162(ra) # 80000ccc <release>
  acquire(&original_parent->lock);
    8000215e:	8526                	mv	a0,s1
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	ab8080e7          	jalr	-1352(ra) # 80000c18 <acquire>
  acquire(&p->lock);
    80002168:	854e                	mv	a0,s3
    8000216a:	fffff097          	auipc	ra,0xfffff
    8000216e:	aae080e7          	jalr	-1362(ra) # 80000c18 <acquire>
  reparent(p);
    80002172:	854e                	mv	a0,s3
    80002174:	00000097          	auipc	ra,0x0
    80002178:	d58080e7          	jalr	-680(ra) # 80001ecc <reparent>
  wakeup1(original_parent);
    8000217c:	8526                	mv	a0,s1
    8000217e:	fffff097          	auipc	ra,0xfffff
    80002182:	6e6080e7          	jalr	1766(ra) # 80001864 <wakeup1>
  p->xstate = status;
    80002186:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000218a:	4791                	li	a5,4
    8000218c:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002190:	8526                	mv	a0,s1
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	b3a080e7          	jalr	-1222(ra) # 80000ccc <release>
  sched();
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	e38080e7          	jalr	-456(ra) # 80001fd2 <sched>
  panic("zombie exit");
    800021a2:	00006517          	auipc	a0,0x6
    800021a6:	0ae50513          	addi	a0,a0,174 # 80008250 <digits+0x210>
    800021aa:	ffffe097          	auipc	ra,0xffffe
    800021ae:	3a6080e7          	jalr	934(ra) # 80000550 <panic>

00000000800021b2 <yield>:
{
    800021b2:	1101                	addi	sp,sp,-32
    800021b4:	ec06                	sd	ra,24(sp)
    800021b6:	e822                	sd	s0,16(sp)
    800021b8:	e426                	sd	s1,8(sp)
    800021ba:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021bc:	00000097          	auipc	ra,0x0
    800021c0:	846080e7          	jalr	-1978(ra) # 80001a02 <myproc>
    800021c4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021c6:	fffff097          	auipc	ra,0xfffff
    800021ca:	a52080e7          	jalr	-1454(ra) # 80000c18 <acquire>
  p->state = RUNNABLE;
    800021ce:	4789                	li	a5,2
    800021d0:	cc9c                	sw	a5,24(s1)
  sched();
    800021d2:	00000097          	auipc	ra,0x0
    800021d6:	e00080e7          	jalr	-512(ra) # 80001fd2 <sched>
  release(&p->lock);
    800021da:	8526                	mv	a0,s1
    800021dc:	fffff097          	auipc	ra,0xfffff
    800021e0:	af0080e7          	jalr	-1296(ra) # 80000ccc <release>
}
    800021e4:	60e2                	ld	ra,24(sp)
    800021e6:	6442                	ld	s0,16(sp)
    800021e8:	64a2                	ld	s1,8(sp)
    800021ea:	6105                	addi	sp,sp,32
    800021ec:	8082                	ret

00000000800021ee <sleep>:
{
    800021ee:	7179                	addi	sp,sp,-48
    800021f0:	f406                	sd	ra,40(sp)
    800021f2:	f022                	sd	s0,32(sp)
    800021f4:	ec26                	sd	s1,24(sp)
    800021f6:	e84a                	sd	s2,16(sp)
    800021f8:	e44e                	sd	s3,8(sp)
    800021fa:	1800                	addi	s0,sp,48
    800021fc:	89aa                	mv	s3,a0
    800021fe:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002200:	00000097          	auipc	ra,0x0
    80002204:	802080e7          	jalr	-2046(ra) # 80001a02 <myproc>
    80002208:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000220a:	05250663          	beq	a0,s2,80002256 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	a0a080e7          	jalr	-1526(ra) # 80000c18 <acquire>
    release(lk);
    80002216:	854a                	mv	a0,s2
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	ab4080e7          	jalr	-1356(ra) # 80000ccc <release>
  p->chan = chan;
    80002220:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002224:	4785                	li	a5,1
    80002226:	cc9c                	sw	a5,24(s1)
  sched();
    80002228:	00000097          	auipc	ra,0x0
    8000222c:	daa080e7          	jalr	-598(ra) # 80001fd2 <sched>
  p->chan = 0;
    80002230:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002234:	8526                	mv	a0,s1
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	a96080e7          	jalr	-1386(ra) # 80000ccc <release>
    acquire(lk);
    8000223e:	854a                	mv	a0,s2
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	9d8080e7          	jalr	-1576(ra) # 80000c18 <acquire>
}
    80002248:	70a2                	ld	ra,40(sp)
    8000224a:	7402                	ld	s0,32(sp)
    8000224c:	64e2                	ld	s1,24(sp)
    8000224e:	6942                	ld	s2,16(sp)
    80002250:	69a2                	ld	s3,8(sp)
    80002252:	6145                	addi	sp,sp,48
    80002254:	8082                	ret
  p->chan = chan;
    80002256:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000225a:	4785                	li	a5,1
    8000225c:	cd1c                	sw	a5,24(a0)
  sched();
    8000225e:	00000097          	auipc	ra,0x0
    80002262:	d74080e7          	jalr	-652(ra) # 80001fd2 <sched>
  p->chan = 0;
    80002266:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000226a:	bff9                	j	80002248 <sleep+0x5a>

000000008000226c <wait>:
{
    8000226c:	715d                	addi	sp,sp,-80
    8000226e:	e486                	sd	ra,72(sp)
    80002270:	e0a2                	sd	s0,64(sp)
    80002272:	fc26                	sd	s1,56(sp)
    80002274:	f84a                	sd	s2,48(sp)
    80002276:	f44e                	sd	s3,40(sp)
    80002278:	f052                	sd	s4,32(sp)
    8000227a:	ec56                	sd	s5,24(sp)
    8000227c:	e85a                	sd	s6,16(sp)
    8000227e:	e45e                	sd	s7,8(sp)
    80002280:	e062                	sd	s8,0(sp)
    80002282:	0880                	addi	s0,sp,80
    80002284:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	77c080e7          	jalr	1916(ra) # 80001a02 <myproc>
    8000228e:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002290:	8c2a                	mv	s8,a0
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	986080e7          	jalr	-1658(ra) # 80000c18 <acquire>
    havekids = 0;
    8000229a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000229c:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    8000229e:	00015997          	auipc	s3,0x15
    800022a2:	e0a98993          	addi	s3,s3,-502 # 800170a8 <tickslock>
        havekids = 1;
    800022a6:	4a85                	li	s5,1
    havekids = 0;
    800022a8:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022aa:	0000f497          	auipc	s1,0xf
    800022ae:	3fe48493          	addi	s1,s1,1022 # 800116a8 <proc>
    800022b2:	a08d                	j	80002314 <wait+0xa8>
          pid = np->pid;
    800022b4:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022b8:	000b0e63          	beqz	s6,800022d4 <wait+0x68>
    800022bc:	4691                	li	a3,4
    800022be:	03448613          	addi	a2,s1,52
    800022c2:	85da                	mv	a1,s6
    800022c4:	05093503          	ld	a0,80(s2)
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	3d0080e7          	jalr	976(ra) # 80001698 <copyout>
    800022d0:	02054263          	bltz	a0,800022f4 <wait+0x88>
          freeproc(np);
    800022d4:	8526                	mv	a0,s1
    800022d6:	00000097          	auipc	ra,0x0
    800022da:	8de080e7          	jalr	-1826(ra) # 80001bb4 <freeproc>
          release(&np->lock);
    800022de:	8526                	mv	a0,s1
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	9ec080e7          	jalr	-1556(ra) # 80000ccc <release>
          release(&p->lock);
    800022e8:	854a                	mv	a0,s2
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	9e2080e7          	jalr	-1566(ra) # 80000ccc <release>
          return pid;
    800022f2:	a8a9                	j	8000234c <wait+0xe0>
            release(&np->lock);
    800022f4:	8526                	mv	a0,s1
    800022f6:	fffff097          	auipc	ra,0xfffff
    800022fa:	9d6080e7          	jalr	-1578(ra) # 80000ccc <release>
            release(&p->lock);
    800022fe:	854a                	mv	a0,s2
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	9cc080e7          	jalr	-1588(ra) # 80000ccc <release>
            return -1;
    80002308:	59fd                	li	s3,-1
    8000230a:	a089                	j	8000234c <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    8000230c:	16848493          	addi	s1,s1,360
    80002310:	03348463          	beq	s1,s3,80002338 <wait+0xcc>
      if(np->parent == p){
    80002314:	709c                	ld	a5,32(s1)
    80002316:	ff279be3          	bne	a5,s2,8000230c <wait+0xa0>
        acquire(&np->lock);
    8000231a:	8526                	mv	a0,s1
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	8fc080e7          	jalr	-1796(ra) # 80000c18 <acquire>
        if(np->state == ZOMBIE){
    80002324:	4c9c                	lw	a5,24(s1)
    80002326:	f94787e3          	beq	a5,s4,800022b4 <wait+0x48>
        release(&np->lock);
    8000232a:	8526                	mv	a0,s1
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	9a0080e7          	jalr	-1632(ra) # 80000ccc <release>
        havekids = 1;
    80002334:	8756                	mv	a4,s5
    80002336:	bfd9                	j	8000230c <wait+0xa0>
    if(!havekids || p->killed){
    80002338:	c701                	beqz	a4,80002340 <wait+0xd4>
    8000233a:	03092783          	lw	a5,48(s2)
    8000233e:	c785                	beqz	a5,80002366 <wait+0xfa>
      release(&p->lock);
    80002340:	854a                	mv	a0,s2
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	98a080e7          	jalr	-1654(ra) # 80000ccc <release>
      return -1;
    8000234a:	59fd                	li	s3,-1
}
    8000234c:	854e                	mv	a0,s3
    8000234e:	60a6                	ld	ra,72(sp)
    80002350:	6406                	ld	s0,64(sp)
    80002352:	74e2                	ld	s1,56(sp)
    80002354:	7942                	ld	s2,48(sp)
    80002356:	79a2                	ld	s3,40(sp)
    80002358:	7a02                	ld	s4,32(sp)
    8000235a:	6ae2                	ld	s5,24(sp)
    8000235c:	6b42                	ld	s6,16(sp)
    8000235e:	6ba2                	ld	s7,8(sp)
    80002360:	6c02                	ld	s8,0(sp)
    80002362:	6161                	addi	sp,sp,80
    80002364:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002366:	85e2                	mv	a1,s8
    80002368:	854a                	mv	a0,s2
    8000236a:	00000097          	auipc	ra,0x0
    8000236e:	e84080e7          	jalr	-380(ra) # 800021ee <sleep>
    havekids = 0;
    80002372:	bf1d                	j	800022a8 <wait+0x3c>

0000000080002374 <wakeup>:
{
    80002374:	7139                	addi	sp,sp,-64
    80002376:	fc06                	sd	ra,56(sp)
    80002378:	f822                	sd	s0,48(sp)
    8000237a:	f426                	sd	s1,40(sp)
    8000237c:	f04a                	sd	s2,32(sp)
    8000237e:	ec4e                	sd	s3,24(sp)
    80002380:	e852                	sd	s4,16(sp)
    80002382:	e456                	sd	s5,8(sp)
    80002384:	0080                	addi	s0,sp,64
    80002386:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002388:	0000f497          	auipc	s1,0xf
    8000238c:	32048493          	addi	s1,s1,800 # 800116a8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002390:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002392:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002394:	00015917          	auipc	s2,0x15
    80002398:	d1490913          	addi	s2,s2,-748 # 800170a8 <tickslock>
    8000239c:	a821                	j	800023b4 <wakeup+0x40>
      p->state = RUNNABLE;
    8000239e:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800023a2:	8526                	mv	a0,s1
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	928080e7          	jalr	-1752(ra) # 80000ccc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023ac:	16848493          	addi	s1,s1,360
    800023b0:	01248e63          	beq	s1,s2,800023cc <wakeup+0x58>
    acquire(&p->lock);
    800023b4:	8526                	mv	a0,s1
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	862080e7          	jalr	-1950(ra) # 80000c18 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800023be:	4c9c                	lw	a5,24(s1)
    800023c0:	ff3791e3          	bne	a5,s3,800023a2 <wakeup+0x2e>
    800023c4:	749c                	ld	a5,40(s1)
    800023c6:	fd479ee3          	bne	a5,s4,800023a2 <wakeup+0x2e>
    800023ca:	bfd1                	j	8000239e <wakeup+0x2a>
}
    800023cc:	70e2                	ld	ra,56(sp)
    800023ce:	7442                	ld	s0,48(sp)
    800023d0:	74a2                	ld	s1,40(sp)
    800023d2:	7902                	ld	s2,32(sp)
    800023d4:	69e2                	ld	s3,24(sp)
    800023d6:	6a42                	ld	s4,16(sp)
    800023d8:	6aa2                	ld	s5,8(sp)
    800023da:	6121                	addi	sp,sp,64
    800023dc:	8082                	ret

00000000800023de <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023de:	7179                	addi	sp,sp,-48
    800023e0:	f406                	sd	ra,40(sp)
    800023e2:	f022                	sd	s0,32(sp)
    800023e4:	ec26                	sd	s1,24(sp)
    800023e6:	e84a                	sd	s2,16(sp)
    800023e8:	e44e                	sd	s3,8(sp)
    800023ea:	1800                	addi	s0,sp,48
    800023ec:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023ee:	0000f497          	auipc	s1,0xf
    800023f2:	2ba48493          	addi	s1,s1,698 # 800116a8 <proc>
    800023f6:	00015997          	auipc	s3,0x15
    800023fa:	cb298993          	addi	s3,s3,-846 # 800170a8 <tickslock>
    acquire(&p->lock);
    800023fe:	8526                	mv	a0,s1
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	818080e7          	jalr	-2024(ra) # 80000c18 <acquire>
    if(p->pid == pid){
    80002408:	5c9c                	lw	a5,56(s1)
    8000240a:	01278d63          	beq	a5,s2,80002424 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000240e:	8526                	mv	a0,s1
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	8bc080e7          	jalr	-1860(ra) # 80000ccc <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002418:	16848493          	addi	s1,s1,360
    8000241c:	ff3491e3          	bne	s1,s3,800023fe <kill+0x20>
  }
  return -1;
    80002420:	557d                	li	a0,-1
    80002422:	a829                	j	8000243c <kill+0x5e>
      p->killed = 1;
    80002424:	4785                	li	a5,1
    80002426:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002428:	4c98                	lw	a4,24(s1)
    8000242a:	4785                	li	a5,1
    8000242c:	00f70f63          	beq	a4,a5,8000244a <kill+0x6c>
      release(&p->lock);
    80002430:	8526                	mv	a0,s1
    80002432:	fffff097          	auipc	ra,0xfffff
    80002436:	89a080e7          	jalr	-1894(ra) # 80000ccc <release>
      return 0;
    8000243a:	4501                	li	a0,0
}
    8000243c:	70a2                	ld	ra,40(sp)
    8000243e:	7402                	ld	s0,32(sp)
    80002440:	64e2                	ld	s1,24(sp)
    80002442:	6942                	ld	s2,16(sp)
    80002444:	69a2                	ld	s3,8(sp)
    80002446:	6145                	addi	sp,sp,48
    80002448:	8082                	ret
        p->state = RUNNABLE;
    8000244a:	4789                	li	a5,2
    8000244c:	cc9c                	sw	a5,24(s1)
    8000244e:	b7cd                	j	80002430 <kill+0x52>

0000000080002450 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002450:	7179                	addi	sp,sp,-48
    80002452:	f406                	sd	ra,40(sp)
    80002454:	f022                	sd	s0,32(sp)
    80002456:	ec26                	sd	s1,24(sp)
    80002458:	e84a                	sd	s2,16(sp)
    8000245a:	e44e                	sd	s3,8(sp)
    8000245c:	e052                	sd	s4,0(sp)
    8000245e:	1800                	addi	s0,sp,48
    80002460:	84aa                	mv	s1,a0
    80002462:	892e                	mv	s2,a1
    80002464:	89b2                	mv	s3,a2
    80002466:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	59a080e7          	jalr	1434(ra) # 80001a02 <myproc>
  if(user_dst){
    80002470:	c08d                	beqz	s1,80002492 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002472:	86d2                	mv	a3,s4
    80002474:	864e                	mv	a2,s3
    80002476:	85ca                	mv	a1,s2
    80002478:	6928                	ld	a0,80(a0)
    8000247a:	fffff097          	auipc	ra,0xfffff
    8000247e:	21e080e7          	jalr	542(ra) # 80001698 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002482:	70a2                	ld	ra,40(sp)
    80002484:	7402                	ld	s0,32(sp)
    80002486:	64e2                	ld	s1,24(sp)
    80002488:	6942                	ld	s2,16(sp)
    8000248a:	69a2                	ld	s3,8(sp)
    8000248c:	6a02                	ld	s4,0(sp)
    8000248e:	6145                	addi	sp,sp,48
    80002490:	8082                	ret
    memmove((char *)dst, src, len);
    80002492:	000a061b          	sext.w	a2,s4
    80002496:	85ce                	mv	a1,s3
    80002498:	854a                	mv	a0,s2
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	8da080e7          	jalr	-1830(ra) # 80000d74 <memmove>
    return 0;
    800024a2:	8526                	mv	a0,s1
    800024a4:	bff9                	j	80002482 <either_copyout+0x32>

00000000800024a6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024a6:	7179                	addi	sp,sp,-48
    800024a8:	f406                	sd	ra,40(sp)
    800024aa:	f022                	sd	s0,32(sp)
    800024ac:	ec26                	sd	s1,24(sp)
    800024ae:	e84a                	sd	s2,16(sp)
    800024b0:	e44e                	sd	s3,8(sp)
    800024b2:	e052                	sd	s4,0(sp)
    800024b4:	1800                	addi	s0,sp,48
    800024b6:	892a                	mv	s2,a0
    800024b8:	84ae                	mv	s1,a1
    800024ba:	89b2                	mv	s3,a2
    800024bc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024be:	fffff097          	auipc	ra,0xfffff
    800024c2:	544080e7          	jalr	1348(ra) # 80001a02 <myproc>
  if(user_src){
    800024c6:	c08d                	beqz	s1,800024e8 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024c8:	86d2                	mv	a3,s4
    800024ca:	864e                	mv	a2,s3
    800024cc:	85ca                	mv	a1,s2
    800024ce:	6928                	ld	a0,80(a0)
    800024d0:	fffff097          	auipc	ra,0xfffff
    800024d4:	254080e7          	jalr	596(ra) # 80001724 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024d8:	70a2                	ld	ra,40(sp)
    800024da:	7402                	ld	s0,32(sp)
    800024dc:	64e2                	ld	s1,24(sp)
    800024de:	6942                	ld	s2,16(sp)
    800024e0:	69a2                	ld	s3,8(sp)
    800024e2:	6a02                	ld	s4,0(sp)
    800024e4:	6145                	addi	sp,sp,48
    800024e6:	8082                	ret
    memmove(dst, (char*)src, len);
    800024e8:	000a061b          	sext.w	a2,s4
    800024ec:	85ce                	mv	a1,s3
    800024ee:	854a                	mv	a0,s2
    800024f0:	fffff097          	auipc	ra,0xfffff
    800024f4:	884080e7          	jalr	-1916(ra) # 80000d74 <memmove>
    return 0;
    800024f8:	8526                	mv	a0,s1
    800024fa:	bff9                	j	800024d8 <either_copyin+0x32>

00000000800024fc <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024fc:	715d                	addi	sp,sp,-80
    800024fe:	e486                	sd	ra,72(sp)
    80002500:	e0a2                	sd	s0,64(sp)
    80002502:	fc26                	sd	s1,56(sp)
    80002504:	f84a                	sd	s2,48(sp)
    80002506:	f44e                	sd	s3,40(sp)
    80002508:	f052                	sd	s4,32(sp)
    8000250a:	ec56                	sd	s5,24(sp)
    8000250c:	e85a                	sd	s6,16(sp)
    8000250e:	e45e                	sd	s7,8(sp)
    80002510:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002512:	00006517          	auipc	a0,0x6
    80002516:	bb650513          	addi	a0,a0,-1098 # 800080c8 <digits+0x88>
    8000251a:	ffffe097          	auipc	ra,0xffffe
    8000251e:	080080e7          	jalr	128(ra) # 8000059a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002522:	0000f497          	auipc	s1,0xf
    80002526:	2de48493          	addi	s1,s1,734 # 80011800 <proc+0x158>
    8000252a:	00015917          	auipc	s2,0x15
    8000252e:	cd690913          	addi	s2,s2,-810 # 80017200 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002532:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002534:	00006997          	auipc	s3,0x6
    80002538:	d2c98993          	addi	s3,s3,-724 # 80008260 <digits+0x220>
    printf("%d %s %s", p->pid, state, p->name);
    8000253c:	00006a97          	auipc	s5,0x6
    80002540:	d2ca8a93          	addi	s5,s5,-724 # 80008268 <digits+0x228>
    printf("\n");
    80002544:	00006a17          	auipc	s4,0x6
    80002548:	b84a0a13          	addi	s4,s4,-1148 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000254c:	00006b97          	auipc	s7,0x6
    80002550:	d54b8b93          	addi	s7,s7,-684 # 800082a0 <states.1709>
    80002554:	a00d                	j	80002576 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002556:	ee06a583          	lw	a1,-288(a3)
    8000255a:	8556                	mv	a0,s5
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	03e080e7          	jalr	62(ra) # 8000059a <printf>
    printf("\n");
    80002564:	8552                	mv	a0,s4
    80002566:	ffffe097          	auipc	ra,0xffffe
    8000256a:	034080e7          	jalr	52(ra) # 8000059a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000256e:	16848493          	addi	s1,s1,360
    80002572:	03248163          	beq	s1,s2,80002594 <procdump+0x98>
    if(p->state == UNUSED)
    80002576:	86a6                	mv	a3,s1
    80002578:	ec04a783          	lw	a5,-320(s1)
    8000257c:	dbed                	beqz	a5,8000256e <procdump+0x72>
      state = "???";
    8000257e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002580:	fcfb6be3          	bltu	s6,a5,80002556 <procdump+0x5a>
    80002584:	1782                	slli	a5,a5,0x20
    80002586:	9381                	srli	a5,a5,0x20
    80002588:	078e                	slli	a5,a5,0x3
    8000258a:	97de                	add	a5,a5,s7
    8000258c:	6390                	ld	a2,0(a5)
    8000258e:	f661                	bnez	a2,80002556 <procdump+0x5a>
      state = "???";
    80002590:	864e                	mv	a2,s3
    80002592:	b7d1                	j	80002556 <procdump+0x5a>
  }
}
    80002594:	60a6                	ld	ra,72(sp)
    80002596:	6406                	ld	s0,64(sp)
    80002598:	74e2                	ld	s1,56(sp)
    8000259a:	7942                	ld	s2,48(sp)
    8000259c:	79a2                	ld	s3,40(sp)
    8000259e:	7a02                	ld	s4,32(sp)
    800025a0:	6ae2                	ld	s5,24(sp)
    800025a2:	6b42                	ld	s6,16(sp)
    800025a4:	6ba2                	ld	s7,8(sp)
    800025a6:	6161                	addi	sp,sp,80
    800025a8:	8082                	ret

00000000800025aa <swtch>:
    800025aa:	00153023          	sd	ra,0(a0)
    800025ae:	00253423          	sd	sp,8(a0)
    800025b2:	e900                	sd	s0,16(a0)
    800025b4:	ed04                	sd	s1,24(a0)
    800025b6:	03253023          	sd	s2,32(a0)
    800025ba:	03353423          	sd	s3,40(a0)
    800025be:	03453823          	sd	s4,48(a0)
    800025c2:	03553c23          	sd	s5,56(a0)
    800025c6:	05653023          	sd	s6,64(a0)
    800025ca:	05753423          	sd	s7,72(a0)
    800025ce:	05853823          	sd	s8,80(a0)
    800025d2:	05953c23          	sd	s9,88(a0)
    800025d6:	07a53023          	sd	s10,96(a0)
    800025da:	07b53423          	sd	s11,104(a0)
    800025de:	0005b083          	ld	ra,0(a1)
    800025e2:	0085b103          	ld	sp,8(a1)
    800025e6:	6980                	ld	s0,16(a1)
    800025e8:	6d84                	ld	s1,24(a1)
    800025ea:	0205b903          	ld	s2,32(a1)
    800025ee:	0285b983          	ld	s3,40(a1)
    800025f2:	0305ba03          	ld	s4,48(a1)
    800025f6:	0385ba83          	ld	s5,56(a1)
    800025fa:	0405bb03          	ld	s6,64(a1)
    800025fe:	0485bb83          	ld	s7,72(a1)
    80002602:	0505bc03          	ld	s8,80(a1)
    80002606:	0585bc83          	ld	s9,88(a1)
    8000260a:	0605bd03          	ld	s10,96(a1)
    8000260e:	0685bd83          	ld	s11,104(a1)
    80002612:	8082                	ret

0000000080002614 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002614:	1141                	addi	sp,sp,-16
    80002616:	e406                	sd	ra,8(sp)
    80002618:	e022                	sd	s0,0(sp)
    8000261a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000261c:	00006597          	auipc	a1,0x6
    80002620:	cac58593          	addi	a1,a1,-852 # 800082c8 <states.1709+0x28>
    80002624:	00015517          	auipc	a0,0x15
    80002628:	a8450513          	addi	a0,a0,-1404 # 800170a8 <tickslock>
    8000262c:	ffffe097          	auipc	ra,0xffffe
    80002630:	55c080e7          	jalr	1372(ra) # 80000b88 <initlock>
}
    80002634:	60a2                	ld	ra,8(sp)
    80002636:	6402                	ld	s0,0(sp)
    80002638:	0141                	addi	sp,sp,16
    8000263a:	8082                	ret

000000008000263c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000263c:	1141                	addi	sp,sp,-16
    8000263e:	e422                	sd	s0,8(sp)
    80002640:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002642:	00003797          	auipc	a5,0x3
    80002646:	4de78793          	addi	a5,a5,1246 # 80005b20 <kernelvec>
    8000264a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000264e:	6422                	ld	s0,8(sp)
    80002650:	0141                	addi	sp,sp,16
    80002652:	8082                	ret

0000000080002654 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002654:	1141                	addi	sp,sp,-16
    80002656:	e406                	sd	ra,8(sp)
    80002658:	e022                	sd	s0,0(sp)
    8000265a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000265c:	fffff097          	auipc	ra,0xfffff
    80002660:	3a6080e7          	jalr	934(ra) # 80001a02 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002664:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002668:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000266a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000266e:	00005617          	auipc	a2,0x5
    80002672:	99260613          	addi	a2,a2,-1646 # 80007000 <_trampoline>
    80002676:	00005697          	auipc	a3,0x5
    8000267a:	98a68693          	addi	a3,a3,-1654 # 80007000 <_trampoline>
    8000267e:	8e91                	sub	a3,a3,a2
    80002680:	040007b7          	lui	a5,0x4000
    80002684:	17fd                	addi	a5,a5,-1
    80002686:	07b2                	slli	a5,a5,0xc
    80002688:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000268a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000268e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002690:	180026f3          	csrr	a3,satp
    80002694:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002696:	6d38                	ld	a4,88(a0)
    80002698:	6134                	ld	a3,64(a0)
    8000269a:	6585                	lui	a1,0x1
    8000269c:	96ae                	add	a3,a3,a1
    8000269e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026a0:	6d38                	ld	a4,88(a0)
    800026a2:	00000697          	auipc	a3,0x0
    800026a6:	13868693          	addi	a3,a3,312 # 800027da <usertrap>
    800026aa:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026ac:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026ae:	8692                	mv	a3,tp
    800026b0:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026b2:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026b6:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026ba:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026be:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026c2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026c4:	6f18                	ld	a4,24(a4)
    800026c6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026ca:	692c                	ld	a1,80(a0)
    800026cc:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026ce:	00005717          	auipc	a4,0x5
    800026d2:	9c270713          	addi	a4,a4,-1598 # 80007090 <userret>
    800026d6:	8f11                	sub	a4,a4,a2
    800026d8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026da:	577d                	li	a4,-1
    800026dc:	177e                	slli	a4,a4,0x3f
    800026de:	8dd9                	or	a1,a1,a4
    800026e0:	02000537          	lui	a0,0x2000
    800026e4:	157d                	addi	a0,a0,-1
    800026e6:	0536                	slli	a0,a0,0xd
    800026e8:	9782                	jalr	a5
}
    800026ea:	60a2                	ld	ra,8(sp)
    800026ec:	6402                	ld	s0,0(sp)
    800026ee:	0141                	addi	sp,sp,16
    800026f0:	8082                	ret

00000000800026f2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026f2:	1101                	addi	sp,sp,-32
    800026f4:	ec06                	sd	ra,24(sp)
    800026f6:	e822                	sd	s0,16(sp)
    800026f8:	e426                	sd	s1,8(sp)
    800026fa:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026fc:	00015497          	auipc	s1,0x15
    80002700:	9ac48493          	addi	s1,s1,-1620 # 800170a8 <tickslock>
    80002704:	8526                	mv	a0,s1
    80002706:	ffffe097          	auipc	ra,0xffffe
    8000270a:	512080e7          	jalr	1298(ra) # 80000c18 <acquire>
  ticks++;
    8000270e:	00007517          	auipc	a0,0x7
    80002712:	91250513          	addi	a0,a0,-1774 # 80009020 <ticks>
    80002716:	411c                	lw	a5,0(a0)
    80002718:	2785                	addiw	a5,a5,1
    8000271a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000271c:	00000097          	auipc	ra,0x0
    80002720:	c58080e7          	jalr	-936(ra) # 80002374 <wakeup>
  release(&tickslock);
    80002724:	8526                	mv	a0,s1
    80002726:	ffffe097          	auipc	ra,0xffffe
    8000272a:	5a6080e7          	jalr	1446(ra) # 80000ccc <release>
}
    8000272e:	60e2                	ld	ra,24(sp)
    80002730:	6442                	ld	s0,16(sp)
    80002732:	64a2                	ld	s1,8(sp)
    80002734:	6105                	addi	sp,sp,32
    80002736:	8082                	ret

0000000080002738 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002738:	1101                	addi	sp,sp,-32
    8000273a:	ec06                	sd	ra,24(sp)
    8000273c:	e822                	sd	s0,16(sp)
    8000273e:	e426                	sd	s1,8(sp)
    80002740:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002742:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002746:	00074d63          	bltz	a4,80002760 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000274a:	57fd                	li	a5,-1
    8000274c:	17fe                	slli	a5,a5,0x3f
    8000274e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002750:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002752:	06f70363          	beq	a4,a5,800027b8 <devintr+0x80>
  }
}
    80002756:	60e2                	ld	ra,24(sp)
    80002758:	6442                	ld	s0,16(sp)
    8000275a:	64a2                	ld	s1,8(sp)
    8000275c:	6105                	addi	sp,sp,32
    8000275e:	8082                	ret
     (scause & 0xff) == 9){
    80002760:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002764:	46a5                	li	a3,9
    80002766:	fed792e3          	bne	a5,a3,8000274a <devintr+0x12>
    int irq = plic_claim();
    8000276a:	00003097          	auipc	ra,0x3
    8000276e:	4be080e7          	jalr	1214(ra) # 80005c28 <plic_claim>
    80002772:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002774:	47a9                	li	a5,10
    80002776:	02f50763          	beq	a0,a5,800027a4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000277a:	4785                	li	a5,1
    8000277c:	02f50963          	beq	a0,a5,800027ae <devintr+0x76>
    return 1;
    80002780:	4505                	li	a0,1
    } else if(irq){
    80002782:	d8f1                	beqz	s1,80002756 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002784:	85a6                	mv	a1,s1
    80002786:	00006517          	auipc	a0,0x6
    8000278a:	b4a50513          	addi	a0,a0,-1206 # 800082d0 <states.1709+0x30>
    8000278e:	ffffe097          	auipc	ra,0xffffe
    80002792:	e0c080e7          	jalr	-500(ra) # 8000059a <printf>
      plic_complete(irq);
    80002796:	8526                	mv	a0,s1
    80002798:	00003097          	auipc	ra,0x3
    8000279c:	4b4080e7          	jalr	1204(ra) # 80005c4c <plic_complete>
    return 1;
    800027a0:	4505                	li	a0,1
    800027a2:	bf55                	j	80002756 <devintr+0x1e>
      uartintr();
    800027a4:	ffffe097          	auipc	ra,0xffffe
    800027a8:	238080e7          	jalr	568(ra) # 800009dc <uartintr>
    800027ac:	b7ed                	j	80002796 <devintr+0x5e>
      virtio_disk_intr();
    800027ae:	00004097          	auipc	ra,0x4
    800027b2:	97e080e7          	jalr	-1666(ra) # 8000612c <virtio_disk_intr>
    800027b6:	b7c5                	j	80002796 <devintr+0x5e>
    if(cpuid() == 0){
    800027b8:	fffff097          	auipc	ra,0xfffff
    800027bc:	21e080e7          	jalr	542(ra) # 800019d6 <cpuid>
    800027c0:	c901                	beqz	a0,800027d0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027c2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027c6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027c8:	14479073          	csrw	sip,a5
    return 2;
    800027cc:	4509                	li	a0,2
    800027ce:	b761                	j	80002756 <devintr+0x1e>
      clockintr();
    800027d0:	00000097          	auipc	ra,0x0
    800027d4:	f22080e7          	jalr	-222(ra) # 800026f2 <clockintr>
    800027d8:	b7ed                	j	800027c2 <devintr+0x8a>

00000000800027da <usertrap>:
{
    800027da:	1101                	addi	sp,sp,-32
    800027dc:	ec06                	sd	ra,24(sp)
    800027de:	e822                	sd	s0,16(sp)
    800027e0:	e426                	sd	s1,8(sp)
    800027e2:	e04a                	sd	s2,0(sp)
    800027e4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027e6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027ea:	1007f793          	andi	a5,a5,256
    800027ee:	e3ad                	bnez	a5,80002850 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027f0:	00003797          	auipc	a5,0x3
    800027f4:	33078793          	addi	a5,a5,816 # 80005b20 <kernelvec>
    800027f8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027fc:	fffff097          	auipc	ra,0xfffff
    80002800:	206080e7          	jalr	518(ra) # 80001a02 <myproc>
    80002804:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002806:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002808:	14102773          	csrr	a4,sepc
    8000280c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000280e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002812:	47a1                	li	a5,8
    80002814:	04f71c63          	bne	a4,a5,8000286c <usertrap+0x92>
    if(p->killed)
    80002818:	591c                	lw	a5,48(a0)
    8000281a:	e3b9                	bnez	a5,80002860 <usertrap+0x86>
    p->trapframe->epc += 4;
    8000281c:	6cb8                	ld	a4,88(s1)
    8000281e:	6f1c                	ld	a5,24(a4)
    80002820:	0791                	addi	a5,a5,4
    80002822:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002824:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002828:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000282c:	10079073          	csrw	sstatus,a5
    syscall();
    80002830:	00000097          	auipc	ra,0x0
    80002834:	2e0080e7          	jalr	736(ra) # 80002b10 <syscall>
  if(p->killed)
    80002838:	589c                	lw	a5,48(s1)
    8000283a:	ebc1                	bnez	a5,800028ca <usertrap+0xf0>
  usertrapret();
    8000283c:	00000097          	auipc	ra,0x0
    80002840:	e18080e7          	jalr	-488(ra) # 80002654 <usertrapret>
}
    80002844:	60e2                	ld	ra,24(sp)
    80002846:	6442                	ld	s0,16(sp)
    80002848:	64a2                	ld	s1,8(sp)
    8000284a:	6902                	ld	s2,0(sp)
    8000284c:	6105                	addi	sp,sp,32
    8000284e:	8082                	ret
    panic("usertrap: not from user mode");
    80002850:	00006517          	auipc	a0,0x6
    80002854:	aa050513          	addi	a0,a0,-1376 # 800082f0 <states.1709+0x50>
    80002858:	ffffe097          	auipc	ra,0xffffe
    8000285c:	cf8080e7          	jalr	-776(ra) # 80000550 <panic>
      exit(-1);
    80002860:	557d                	li	a0,-1
    80002862:	00000097          	auipc	ra,0x0
    80002866:	846080e7          	jalr	-1978(ra) # 800020a8 <exit>
    8000286a:	bf4d                	j	8000281c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000286c:	00000097          	auipc	ra,0x0
    80002870:	ecc080e7          	jalr	-308(ra) # 80002738 <devintr>
    80002874:	892a                	mv	s2,a0
    80002876:	c501                	beqz	a0,8000287e <usertrap+0xa4>
  if(p->killed)
    80002878:	589c                	lw	a5,48(s1)
    8000287a:	c3a1                	beqz	a5,800028ba <usertrap+0xe0>
    8000287c:	a815                	j	800028b0 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000287e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002882:	5c90                	lw	a2,56(s1)
    80002884:	00006517          	auipc	a0,0x6
    80002888:	a8c50513          	addi	a0,a0,-1396 # 80008310 <states.1709+0x70>
    8000288c:	ffffe097          	auipc	ra,0xffffe
    80002890:	d0e080e7          	jalr	-754(ra) # 8000059a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002894:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002898:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000289c:	00006517          	auipc	a0,0x6
    800028a0:	aa450513          	addi	a0,a0,-1372 # 80008340 <states.1709+0xa0>
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	cf6080e7          	jalr	-778(ra) # 8000059a <printf>
    p->killed = 1;
    800028ac:	4785                	li	a5,1
    800028ae:	d89c                	sw	a5,48(s1)
    exit(-1);
    800028b0:	557d                	li	a0,-1
    800028b2:	fffff097          	auipc	ra,0xfffff
    800028b6:	7f6080e7          	jalr	2038(ra) # 800020a8 <exit>
  if(which_dev == 2)
    800028ba:	4789                	li	a5,2
    800028bc:	f8f910e3          	bne	s2,a5,8000283c <usertrap+0x62>
    yield();
    800028c0:	00000097          	auipc	ra,0x0
    800028c4:	8f2080e7          	jalr	-1806(ra) # 800021b2 <yield>
    800028c8:	bf95                	j	8000283c <usertrap+0x62>
  int which_dev = 0;
    800028ca:	4901                	li	s2,0
    800028cc:	b7d5                	j	800028b0 <usertrap+0xd6>

00000000800028ce <kerneltrap>:
{
    800028ce:	7179                	addi	sp,sp,-48
    800028d0:	f406                	sd	ra,40(sp)
    800028d2:	f022                	sd	s0,32(sp)
    800028d4:	ec26                	sd	s1,24(sp)
    800028d6:	e84a                	sd	s2,16(sp)
    800028d8:	e44e                	sd	s3,8(sp)
    800028da:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028dc:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028e4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028e8:	1004f793          	andi	a5,s1,256
    800028ec:	cb85                	beqz	a5,8000291c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ee:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028f2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028f4:	ef85                	bnez	a5,8000292c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028f6:	00000097          	auipc	ra,0x0
    800028fa:	e42080e7          	jalr	-446(ra) # 80002738 <devintr>
    800028fe:	cd1d                	beqz	a0,8000293c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002900:	4789                	li	a5,2
    80002902:	06f50a63          	beq	a0,a5,80002976 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002906:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000290a:	10049073          	csrw	sstatus,s1
}
    8000290e:	70a2                	ld	ra,40(sp)
    80002910:	7402                	ld	s0,32(sp)
    80002912:	64e2                	ld	s1,24(sp)
    80002914:	6942                	ld	s2,16(sp)
    80002916:	69a2                	ld	s3,8(sp)
    80002918:	6145                	addi	sp,sp,48
    8000291a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000291c:	00006517          	auipc	a0,0x6
    80002920:	a4450513          	addi	a0,a0,-1468 # 80008360 <states.1709+0xc0>
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	c2c080e7          	jalr	-980(ra) # 80000550 <panic>
    panic("kerneltrap: interrupts enabled");
    8000292c:	00006517          	auipc	a0,0x6
    80002930:	a5c50513          	addi	a0,a0,-1444 # 80008388 <states.1709+0xe8>
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	c1c080e7          	jalr	-996(ra) # 80000550 <panic>
    printf("scause %p\n", scause);
    8000293c:	85ce                	mv	a1,s3
    8000293e:	00006517          	auipc	a0,0x6
    80002942:	a6a50513          	addi	a0,a0,-1430 # 800083a8 <states.1709+0x108>
    80002946:	ffffe097          	auipc	ra,0xffffe
    8000294a:	c54080e7          	jalr	-940(ra) # 8000059a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000294e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002952:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002956:	00006517          	auipc	a0,0x6
    8000295a:	a6250513          	addi	a0,a0,-1438 # 800083b8 <states.1709+0x118>
    8000295e:	ffffe097          	auipc	ra,0xffffe
    80002962:	c3c080e7          	jalr	-964(ra) # 8000059a <printf>
    panic("kerneltrap");
    80002966:	00006517          	auipc	a0,0x6
    8000296a:	a6a50513          	addi	a0,a0,-1430 # 800083d0 <states.1709+0x130>
    8000296e:	ffffe097          	auipc	ra,0xffffe
    80002972:	be2080e7          	jalr	-1054(ra) # 80000550 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002976:	fffff097          	auipc	ra,0xfffff
    8000297a:	08c080e7          	jalr	140(ra) # 80001a02 <myproc>
    8000297e:	d541                	beqz	a0,80002906 <kerneltrap+0x38>
    80002980:	fffff097          	auipc	ra,0xfffff
    80002984:	082080e7          	jalr	130(ra) # 80001a02 <myproc>
    80002988:	4d18                	lw	a4,24(a0)
    8000298a:	478d                	li	a5,3
    8000298c:	f6f71de3          	bne	a4,a5,80002906 <kerneltrap+0x38>
    yield();
    80002990:	00000097          	auipc	ra,0x0
    80002994:	822080e7          	jalr	-2014(ra) # 800021b2 <yield>
    80002998:	b7bd                	j	80002906 <kerneltrap+0x38>

000000008000299a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000299a:	1101                	addi	sp,sp,-32
    8000299c:	ec06                	sd	ra,24(sp)
    8000299e:	e822                	sd	s0,16(sp)
    800029a0:	e426                	sd	s1,8(sp)
    800029a2:	1000                	addi	s0,sp,32
    800029a4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029a6:	fffff097          	auipc	ra,0xfffff
    800029aa:	05c080e7          	jalr	92(ra) # 80001a02 <myproc>
  switch (n) {
    800029ae:	4795                	li	a5,5
    800029b0:	0497e163          	bltu	a5,s1,800029f2 <argraw+0x58>
    800029b4:	048a                	slli	s1,s1,0x2
    800029b6:	00006717          	auipc	a4,0x6
    800029ba:	a5270713          	addi	a4,a4,-1454 # 80008408 <states.1709+0x168>
    800029be:	94ba                	add	s1,s1,a4
    800029c0:	409c                	lw	a5,0(s1)
    800029c2:	97ba                	add	a5,a5,a4
    800029c4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029c6:	6d3c                	ld	a5,88(a0)
    800029c8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029ca:	60e2                	ld	ra,24(sp)
    800029cc:	6442                	ld	s0,16(sp)
    800029ce:	64a2                	ld	s1,8(sp)
    800029d0:	6105                	addi	sp,sp,32
    800029d2:	8082                	ret
    return p->trapframe->a1;
    800029d4:	6d3c                	ld	a5,88(a0)
    800029d6:	7fa8                	ld	a0,120(a5)
    800029d8:	bfcd                	j	800029ca <argraw+0x30>
    return p->trapframe->a2;
    800029da:	6d3c                	ld	a5,88(a0)
    800029dc:	63c8                	ld	a0,128(a5)
    800029de:	b7f5                	j	800029ca <argraw+0x30>
    return p->trapframe->a3;
    800029e0:	6d3c                	ld	a5,88(a0)
    800029e2:	67c8                	ld	a0,136(a5)
    800029e4:	b7dd                	j	800029ca <argraw+0x30>
    return p->trapframe->a4;
    800029e6:	6d3c                	ld	a5,88(a0)
    800029e8:	6bc8                	ld	a0,144(a5)
    800029ea:	b7c5                	j	800029ca <argraw+0x30>
    return p->trapframe->a5;
    800029ec:	6d3c                	ld	a5,88(a0)
    800029ee:	6fc8                	ld	a0,152(a5)
    800029f0:	bfe9                	j	800029ca <argraw+0x30>
  panic("argraw");
    800029f2:	00006517          	auipc	a0,0x6
    800029f6:	9ee50513          	addi	a0,a0,-1554 # 800083e0 <states.1709+0x140>
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	b56080e7          	jalr	-1194(ra) # 80000550 <panic>

0000000080002a02 <fetchaddr>:
{
    80002a02:	1101                	addi	sp,sp,-32
    80002a04:	ec06                	sd	ra,24(sp)
    80002a06:	e822                	sd	s0,16(sp)
    80002a08:	e426                	sd	s1,8(sp)
    80002a0a:	e04a                	sd	s2,0(sp)
    80002a0c:	1000                	addi	s0,sp,32
    80002a0e:	84aa                	mv	s1,a0
    80002a10:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a12:	fffff097          	auipc	ra,0xfffff
    80002a16:	ff0080e7          	jalr	-16(ra) # 80001a02 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a1a:	653c                	ld	a5,72(a0)
    80002a1c:	02f4f863          	bgeu	s1,a5,80002a4c <fetchaddr+0x4a>
    80002a20:	00848713          	addi	a4,s1,8
    80002a24:	02e7e663          	bltu	a5,a4,80002a50 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a28:	46a1                	li	a3,8
    80002a2a:	8626                	mv	a2,s1
    80002a2c:	85ca                	mv	a1,s2
    80002a2e:	6928                	ld	a0,80(a0)
    80002a30:	fffff097          	auipc	ra,0xfffff
    80002a34:	cf4080e7          	jalr	-780(ra) # 80001724 <copyin>
    80002a38:	00a03533          	snez	a0,a0
    80002a3c:	40a00533          	neg	a0,a0
}
    80002a40:	60e2                	ld	ra,24(sp)
    80002a42:	6442                	ld	s0,16(sp)
    80002a44:	64a2                	ld	s1,8(sp)
    80002a46:	6902                	ld	s2,0(sp)
    80002a48:	6105                	addi	sp,sp,32
    80002a4a:	8082                	ret
    return -1;
    80002a4c:	557d                	li	a0,-1
    80002a4e:	bfcd                	j	80002a40 <fetchaddr+0x3e>
    80002a50:	557d                	li	a0,-1
    80002a52:	b7fd                	j	80002a40 <fetchaddr+0x3e>

0000000080002a54 <fetchstr>:
{
    80002a54:	7179                	addi	sp,sp,-48
    80002a56:	f406                	sd	ra,40(sp)
    80002a58:	f022                	sd	s0,32(sp)
    80002a5a:	ec26                	sd	s1,24(sp)
    80002a5c:	e84a                	sd	s2,16(sp)
    80002a5e:	e44e                	sd	s3,8(sp)
    80002a60:	1800                	addi	s0,sp,48
    80002a62:	892a                	mv	s2,a0
    80002a64:	84ae                	mv	s1,a1
    80002a66:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a68:	fffff097          	auipc	ra,0xfffff
    80002a6c:	f9a080e7          	jalr	-102(ra) # 80001a02 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a70:	86ce                	mv	a3,s3
    80002a72:	864a                	mv	a2,s2
    80002a74:	85a6                	mv	a1,s1
    80002a76:	6928                	ld	a0,80(a0)
    80002a78:	fffff097          	auipc	ra,0xfffff
    80002a7c:	d38080e7          	jalr	-712(ra) # 800017b0 <copyinstr>
  if(err < 0)
    80002a80:	00054763          	bltz	a0,80002a8e <fetchstr+0x3a>
  return strlen(buf);
    80002a84:	8526                	mv	a0,s1
    80002a86:	ffffe097          	auipc	ra,0xffffe
    80002a8a:	416080e7          	jalr	1046(ra) # 80000e9c <strlen>
}
    80002a8e:	70a2                	ld	ra,40(sp)
    80002a90:	7402                	ld	s0,32(sp)
    80002a92:	64e2                	ld	s1,24(sp)
    80002a94:	6942                	ld	s2,16(sp)
    80002a96:	69a2                	ld	s3,8(sp)
    80002a98:	6145                	addi	sp,sp,48
    80002a9a:	8082                	ret

0000000080002a9c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a9c:	1101                	addi	sp,sp,-32
    80002a9e:	ec06                	sd	ra,24(sp)
    80002aa0:	e822                	sd	s0,16(sp)
    80002aa2:	e426                	sd	s1,8(sp)
    80002aa4:	1000                	addi	s0,sp,32
    80002aa6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aa8:	00000097          	auipc	ra,0x0
    80002aac:	ef2080e7          	jalr	-270(ra) # 8000299a <argraw>
    80002ab0:	c088                	sw	a0,0(s1)
  return 0;
}
    80002ab2:	4501                	li	a0,0
    80002ab4:	60e2                	ld	ra,24(sp)
    80002ab6:	6442                	ld	s0,16(sp)
    80002ab8:	64a2                	ld	s1,8(sp)
    80002aba:	6105                	addi	sp,sp,32
    80002abc:	8082                	ret

0000000080002abe <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002abe:	1101                	addi	sp,sp,-32
    80002ac0:	ec06                	sd	ra,24(sp)
    80002ac2:	e822                	sd	s0,16(sp)
    80002ac4:	e426                	sd	s1,8(sp)
    80002ac6:	1000                	addi	s0,sp,32
    80002ac8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aca:	00000097          	auipc	ra,0x0
    80002ace:	ed0080e7          	jalr	-304(ra) # 8000299a <argraw>
    80002ad2:	e088                	sd	a0,0(s1)
  return 0;
}
    80002ad4:	4501                	li	a0,0
    80002ad6:	60e2                	ld	ra,24(sp)
    80002ad8:	6442                	ld	s0,16(sp)
    80002ada:	64a2                	ld	s1,8(sp)
    80002adc:	6105                	addi	sp,sp,32
    80002ade:	8082                	ret

0000000080002ae0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ae0:	1101                	addi	sp,sp,-32
    80002ae2:	ec06                	sd	ra,24(sp)
    80002ae4:	e822                	sd	s0,16(sp)
    80002ae6:	e426                	sd	s1,8(sp)
    80002ae8:	e04a                	sd	s2,0(sp)
    80002aea:	1000                	addi	s0,sp,32
    80002aec:	84ae                	mv	s1,a1
    80002aee:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002af0:	00000097          	auipc	ra,0x0
    80002af4:	eaa080e7          	jalr	-342(ra) # 8000299a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002af8:	864a                	mv	a2,s2
    80002afa:	85a6                	mv	a1,s1
    80002afc:	00000097          	auipc	ra,0x0
    80002b00:	f58080e7          	jalr	-168(ra) # 80002a54 <fetchstr>
}
    80002b04:	60e2                	ld	ra,24(sp)
    80002b06:	6442                	ld	s0,16(sp)
    80002b08:	64a2                	ld	s1,8(sp)
    80002b0a:	6902                	ld	s2,0(sp)
    80002b0c:	6105                	addi	sp,sp,32
    80002b0e:	8082                	ret

0000000080002b10 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002b10:	1101                	addi	sp,sp,-32
    80002b12:	ec06                	sd	ra,24(sp)
    80002b14:	e822                	sd	s0,16(sp)
    80002b16:	e426                	sd	s1,8(sp)
    80002b18:	e04a                	sd	s2,0(sp)
    80002b1a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b1c:	fffff097          	auipc	ra,0xfffff
    80002b20:	ee6080e7          	jalr	-282(ra) # 80001a02 <myproc>
    80002b24:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b26:	05853903          	ld	s2,88(a0)
    80002b2a:	0a893783          	ld	a5,168(s2)
    80002b2e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b32:	37fd                	addiw	a5,a5,-1
    80002b34:	4751                	li	a4,20
    80002b36:	00f76f63          	bltu	a4,a5,80002b54 <syscall+0x44>
    80002b3a:	00369713          	slli	a4,a3,0x3
    80002b3e:	00006797          	auipc	a5,0x6
    80002b42:	8e278793          	addi	a5,a5,-1822 # 80008420 <syscalls>
    80002b46:	97ba                	add	a5,a5,a4
    80002b48:	639c                	ld	a5,0(a5)
    80002b4a:	c789                	beqz	a5,80002b54 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002b4c:	9782                	jalr	a5
    80002b4e:	06a93823          	sd	a0,112(s2)
    80002b52:	a839                	j	80002b70 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b54:	15848613          	addi	a2,s1,344
    80002b58:	5c8c                	lw	a1,56(s1)
    80002b5a:	00006517          	auipc	a0,0x6
    80002b5e:	88e50513          	addi	a0,a0,-1906 # 800083e8 <states.1709+0x148>
    80002b62:	ffffe097          	auipc	ra,0xffffe
    80002b66:	a38080e7          	jalr	-1480(ra) # 8000059a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b6a:	6cbc                	ld	a5,88(s1)
    80002b6c:	577d                	li	a4,-1
    80002b6e:	fbb8                	sd	a4,112(a5)
  }
}
    80002b70:	60e2                	ld	ra,24(sp)
    80002b72:	6442                	ld	s0,16(sp)
    80002b74:	64a2                	ld	s1,8(sp)
    80002b76:	6902                	ld	s2,0(sp)
    80002b78:	6105                	addi	sp,sp,32
    80002b7a:	8082                	ret

0000000080002b7c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b7c:	1101                	addi	sp,sp,-32
    80002b7e:	ec06                	sd	ra,24(sp)
    80002b80:	e822                	sd	s0,16(sp)
    80002b82:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b84:	fec40593          	addi	a1,s0,-20
    80002b88:	4501                	li	a0,0
    80002b8a:	00000097          	auipc	ra,0x0
    80002b8e:	f12080e7          	jalr	-238(ra) # 80002a9c <argint>
    return -1;
    80002b92:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002b94:	00054963          	bltz	a0,80002ba6 <sys_exit+0x2a>
  exit(n);
    80002b98:	fec42503          	lw	a0,-20(s0)
    80002b9c:	fffff097          	auipc	ra,0xfffff
    80002ba0:	50c080e7          	jalr	1292(ra) # 800020a8 <exit>
  return 0;  // not reached
    80002ba4:	4781                	li	a5,0
}
    80002ba6:	853e                	mv	a0,a5
    80002ba8:	60e2                	ld	ra,24(sp)
    80002baa:	6442                	ld	s0,16(sp)
    80002bac:	6105                	addi	sp,sp,32
    80002bae:	8082                	ret

0000000080002bb0 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bb0:	1141                	addi	sp,sp,-16
    80002bb2:	e406                	sd	ra,8(sp)
    80002bb4:	e022                	sd	s0,0(sp)
    80002bb6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002bb8:	fffff097          	auipc	ra,0xfffff
    80002bbc:	e4a080e7          	jalr	-438(ra) # 80001a02 <myproc>
}
    80002bc0:	5d08                	lw	a0,56(a0)
    80002bc2:	60a2                	ld	ra,8(sp)
    80002bc4:	6402                	ld	s0,0(sp)
    80002bc6:	0141                	addi	sp,sp,16
    80002bc8:	8082                	ret

0000000080002bca <sys_fork>:

uint64
sys_fork(void)
{
    80002bca:	1141                	addi	sp,sp,-16
    80002bcc:	e406                	sd	ra,8(sp)
    80002bce:	e022                	sd	s0,0(sp)
    80002bd0:	0800                	addi	s0,sp,16
  return fork();
    80002bd2:	fffff097          	auipc	ra,0xfffff
    80002bd6:	1f0080e7          	jalr	496(ra) # 80001dc2 <fork>
}
    80002bda:	60a2                	ld	ra,8(sp)
    80002bdc:	6402                	ld	s0,0(sp)
    80002bde:	0141                	addi	sp,sp,16
    80002be0:	8082                	ret

0000000080002be2 <sys_wait>:

uint64
sys_wait(void)
{
    80002be2:	1101                	addi	sp,sp,-32
    80002be4:	ec06                	sd	ra,24(sp)
    80002be6:	e822                	sd	s0,16(sp)
    80002be8:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002bea:	fe840593          	addi	a1,s0,-24
    80002bee:	4501                	li	a0,0
    80002bf0:	00000097          	auipc	ra,0x0
    80002bf4:	ece080e7          	jalr	-306(ra) # 80002abe <argaddr>
    80002bf8:	87aa                	mv	a5,a0
    return -1;
    80002bfa:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002bfc:	0007c863          	bltz	a5,80002c0c <sys_wait+0x2a>
  return wait(p);
    80002c00:	fe843503          	ld	a0,-24(s0)
    80002c04:	fffff097          	auipc	ra,0xfffff
    80002c08:	668080e7          	jalr	1640(ra) # 8000226c <wait>
}
    80002c0c:	60e2                	ld	ra,24(sp)
    80002c0e:	6442                	ld	s0,16(sp)
    80002c10:	6105                	addi	sp,sp,32
    80002c12:	8082                	ret

0000000080002c14 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c14:	7179                	addi	sp,sp,-48
    80002c16:	f406                	sd	ra,40(sp)
    80002c18:	f022                	sd	s0,32(sp)
    80002c1a:	ec26                	sd	s1,24(sp)
    80002c1c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002c1e:	fdc40593          	addi	a1,s0,-36
    80002c22:	4501                	li	a0,0
    80002c24:	00000097          	auipc	ra,0x0
    80002c28:	e78080e7          	jalr	-392(ra) # 80002a9c <argint>
    80002c2c:	87aa                	mv	a5,a0
    return -1;
    80002c2e:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002c30:	0207c063          	bltz	a5,80002c50 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002c34:	fffff097          	auipc	ra,0xfffff
    80002c38:	dce080e7          	jalr	-562(ra) # 80001a02 <myproc>
    80002c3c:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002c3e:	fdc42503          	lw	a0,-36(s0)
    80002c42:	fffff097          	auipc	ra,0xfffff
    80002c46:	10c080e7          	jalr	268(ra) # 80001d4e <growproc>
    80002c4a:	00054863          	bltz	a0,80002c5a <sys_sbrk+0x46>
    return -1;
  return addr;
    80002c4e:	8526                	mv	a0,s1
}
    80002c50:	70a2                	ld	ra,40(sp)
    80002c52:	7402                	ld	s0,32(sp)
    80002c54:	64e2                	ld	s1,24(sp)
    80002c56:	6145                	addi	sp,sp,48
    80002c58:	8082                	ret
    return -1;
    80002c5a:	557d                	li	a0,-1
    80002c5c:	bfd5                	j	80002c50 <sys_sbrk+0x3c>

0000000080002c5e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c5e:	7139                	addi	sp,sp,-64
    80002c60:	fc06                	sd	ra,56(sp)
    80002c62:	f822                	sd	s0,48(sp)
    80002c64:	f426                	sd	s1,40(sp)
    80002c66:	f04a                	sd	s2,32(sp)
    80002c68:	ec4e                	sd	s3,24(sp)
    80002c6a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c6c:	fcc40593          	addi	a1,s0,-52
    80002c70:	4501                	li	a0,0
    80002c72:	00000097          	auipc	ra,0x0
    80002c76:	e2a080e7          	jalr	-470(ra) # 80002a9c <argint>
    return -1;
    80002c7a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c7c:	06054563          	bltz	a0,80002ce6 <sys_sleep+0x88>
  acquire(&tickslock);
    80002c80:	00014517          	auipc	a0,0x14
    80002c84:	42850513          	addi	a0,a0,1064 # 800170a8 <tickslock>
    80002c88:	ffffe097          	auipc	ra,0xffffe
    80002c8c:	f90080e7          	jalr	-112(ra) # 80000c18 <acquire>
  ticks0 = ticks;
    80002c90:	00006917          	auipc	s2,0x6
    80002c94:	39092903          	lw	s2,912(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002c98:	fcc42783          	lw	a5,-52(s0)
    80002c9c:	cf85                	beqz	a5,80002cd4 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002c9e:	00014997          	auipc	s3,0x14
    80002ca2:	40a98993          	addi	s3,s3,1034 # 800170a8 <tickslock>
    80002ca6:	00006497          	auipc	s1,0x6
    80002caa:	37a48493          	addi	s1,s1,890 # 80009020 <ticks>
    if(myproc()->killed){
    80002cae:	fffff097          	auipc	ra,0xfffff
    80002cb2:	d54080e7          	jalr	-684(ra) # 80001a02 <myproc>
    80002cb6:	591c                	lw	a5,48(a0)
    80002cb8:	ef9d                	bnez	a5,80002cf6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002cba:	85ce                	mv	a1,s3
    80002cbc:	8526                	mv	a0,s1
    80002cbe:	fffff097          	auipc	ra,0xfffff
    80002cc2:	530080e7          	jalr	1328(ra) # 800021ee <sleep>
  while(ticks - ticks0 < n){
    80002cc6:	409c                	lw	a5,0(s1)
    80002cc8:	412787bb          	subw	a5,a5,s2
    80002ccc:	fcc42703          	lw	a4,-52(s0)
    80002cd0:	fce7efe3          	bltu	a5,a4,80002cae <sys_sleep+0x50>
  }
  release(&tickslock);
    80002cd4:	00014517          	auipc	a0,0x14
    80002cd8:	3d450513          	addi	a0,a0,980 # 800170a8 <tickslock>
    80002cdc:	ffffe097          	auipc	ra,0xffffe
    80002ce0:	ff0080e7          	jalr	-16(ra) # 80000ccc <release>
  return 0;
    80002ce4:	4781                	li	a5,0
}
    80002ce6:	853e                	mv	a0,a5
    80002ce8:	70e2                	ld	ra,56(sp)
    80002cea:	7442                	ld	s0,48(sp)
    80002cec:	74a2                	ld	s1,40(sp)
    80002cee:	7902                	ld	s2,32(sp)
    80002cf0:	69e2                	ld	s3,24(sp)
    80002cf2:	6121                	addi	sp,sp,64
    80002cf4:	8082                	ret
      release(&tickslock);
    80002cf6:	00014517          	auipc	a0,0x14
    80002cfa:	3b250513          	addi	a0,a0,946 # 800170a8 <tickslock>
    80002cfe:	ffffe097          	auipc	ra,0xffffe
    80002d02:	fce080e7          	jalr	-50(ra) # 80000ccc <release>
      return -1;
    80002d06:	57fd                	li	a5,-1
    80002d08:	bff9                	j	80002ce6 <sys_sleep+0x88>

0000000080002d0a <sys_kill>:

uint64
sys_kill(void)
{
    80002d0a:	1101                	addi	sp,sp,-32
    80002d0c:	ec06                	sd	ra,24(sp)
    80002d0e:	e822                	sd	s0,16(sp)
    80002d10:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002d12:	fec40593          	addi	a1,s0,-20
    80002d16:	4501                	li	a0,0
    80002d18:	00000097          	auipc	ra,0x0
    80002d1c:	d84080e7          	jalr	-636(ra) # 80002a9c <argint>
    80002d20:	87aa                	mv	a5,a0
    return -1;
    80002d22:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002d24:	0007c863          	bltz	a5,80002d34 <sys_kill+0x2a>
  return kill(pid);
    80002d28:	fec42503          	lw	a0,-20(s0)
    80002d2c:	fffff097          	auipc	ra,0xfffff
    80002d30:	6b2080e7          	jalr	1714(ra) # 800023de <kill>
}
    80002d34:	60e2                	ld	ra,24(sp)
    80002d36:	6442                	ld	s0,16(sp)
    80002d38:	6105                	addi	sp,sp,32
    80002d3a:	8082                	ret

0000000080002d3c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d3c:	1101                	addi	sp,sp,-32
    80002d3e:	ec06                	sd	ra,24(sp)
    80002d40:	e822                	sd	s0,16(sp)
    80002d42:	e426                	sd	s1,8(sp)
    80002d44:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d46:	00014517          	auipc	a0,0x14
    80002d4a:	36250513          	addi	a0,a0,866 # 800170a8 <tickslock>
    80002d4e:	ffffe097          	auipc	ra,0xffffe
    80002d52:	eca080e7          	jalr	-310(ra) # 80000c18 <acquire>
  xticks = ticks;
    80002d56:	00006497          	auipc	s1,0x6
    80002d5a:	2ca4a483          	lw	s1,714(s1) # 80009020 <ticks>
  release(&tickslock);
    80002d5e:	00014517          	auipc	a0,0x14
    80002d62:	34a50513          	addi	a0,a0,842 # 800170a8 <tickslock>
    80002d66:	ffffe097          	auipc	ra,0xffffe
    80002d6a:	f66080e7          	jalr	-154(ra) # 80000ccc <release>
  return xticks;
}
    80002d6e:	02049513          	slli	a0,s1,0x20
    80002d72:	9101                	srli	a0,a0,0x20
    80002d74:	60e2                	ld	ra,24(sp)
    80002d76:	6442                	ld	s0,16(sp)
    80002d78:	64a2                	ld	s1,8(sp)
    80002d7a:	6105                	addi	sp,sp,32
    80002d7c:	8082                	ret

0000000080002d7e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d7e:	7179                	addi	sp,sp,-48
    80002d80:	f406                	sd	ra,40(sp)
    80002d82:	f022                	sd	s0,32(sp)
    80002d84:	ec26                	sd	s1,24(sp)
    80002d86:	e84a                	sd	s2,16(sp)
    80002d88:	e44e                	sd	s3,8(sp)
    80002d8a:	e052                	sd	s4,0(sp)
    80002d8c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d8e:	00005597          	auipc	a1,0x5
    80002d92:	74258593          	addi	a1,a1,1858 # 800084d0 <syscalls+0xb0>
    80002d96:	00014517          	auipc	a0,0x14
    80002d9a:	32a50513          	addi	a0,a0,810 # 800170c0 <bcache>
    80002d9e:	ffffe097          	auipc	ra,0xffffe
    80002da2:	dea080e7          	jalr	-534(ra) # 80000b88 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002da6:	0001c797          	auipc	a5,0x1c
    80002daa:	31a78793          	addi	a5,a5,794 # 8001f0c0 <bcache+0x8000>
    80002dae:	0001c717          	auipc	a4,0x1c
    80002db2:	57a70713          	addi	a4,a4,1402 # 8001f328 <bcache+0x8268>
    80002db6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002dba:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002dbe:	00014497          	auipc	s1,0x14
    80002dc2:	31a48493          	addi	s1,s1,794 # 800170d8 <bcache+0x18>
    b->next = bcache.head.next;
    80002dc6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002dc8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002dca:	00005a17          	auipc	s4,0x5
    80002dce:	70ea0a13          	addi	s4,s4,1806 # 800084d8 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002dd2:	2b893783          	ld	a5,696(s2)
    80002dd6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002dd8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ddc:	85d2                	mv	a1,s4
    80002dde:	01048513          	addi	a0,s1,16
    80002de2:	00001097          	auipc	ra,0x1
    80002de6:	4c2080e7          	jalr	1218(ra) # 800042a4 <initsleeplock>
    bcache.head.next->prev = b;
    80002dea:	2b893783          	ld	a5,696(s2)
    80002dee:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002df0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002df4:	45848493          	addi	s1,s1,1112
    80002df8:	fd349de3          	bne	s1,s3,80002dd2 <binit+0x54>
  }
}
    80002dfc:	70a2                	ld	ra,40(sp)
    80002dfe:	7402                	ld	s0,32(sp)
    80002e00:	64e2                	ld	s1,24(sp)
    80002e02:	6942                	ld	s2,16(sp)
    80002e04:	69a2                	ld	s3,8(sp)
    80002e06:	6a02                	ld	s4,0(sp)
    80002e08:	6145                	addi	sp,sp,48
    80002e0a:	8082                	ret

0000000080002e0c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e0c:	7179                	addi	sp,sp,-48
    80002e0e:	f406                	sd	ra,40(sp)
    80002e10:	f022                	sd	s0,32(sp)
    80002e12:	ec26                	sd	s1,24(sp)
    80002e14:	e84a                	sd	s2,16(sp)
    80002e16:	e44e                	sd	s3,8(sp)
    80002e18:	1800                	addi	s0,sp,48
    80002e1a:	89aa                	mv	s3,a0
    80002e1c:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002e1e:	00014517          	auipc	a0,0x14
    80002e22:	2a250513          	addi	a0,a0,674 # 800170c0 <bcache>
    80002e26:	ffffe097          	auipc	ra,0xffffe
    80002e2a:	df2080e7          	jalr	-526(ra) # 80000c18 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e2e:	0001c497          	auipc	s1,0x1c
    80002e32:	54a4b483          	ld	s1,1354(s1) # 8001f378 <bcache+0x82b8>
    80002e36:	0001c797          	auipc	a5,0x1c
    80002e3a:	4f278793          	addi	a5,a5,1266 # 8001f328 <bcache+0x8268>
    80002e3e:	02f48f63          	beq	s1,a5,80002e7c <bread+0x70>
    80002e42:	873e                	mv	a4,a5
    80002e44:	a021                	j	80002e4c <bread+0x40>
    80002e46:	68a4                	ld	s1,80(s1)
    80002e48:	02e48a63          	beq	s1,a4,80002e7c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e4c:	449c                	lw	a5,8(s1)
    80002e4e:	ff379ce3          	bne	a5,s3,80002e46 <bread+0x3a>
    80002e52:	44dc                	lw	a5,12(s1)
    80002e54:	ff2799e3          	bne	a5,s2,80002e46 <bread+0x3a>
      b->refcnt++;
    80002e58:	40bc                	lw	a5,64(s1)
    80002e5a:	2785                	addiw	a5,a5,1
    80002e5c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e5e:	00014517          	auipc	a0,0x14
    80002e62:	26250513          	addi	a0,a0,610 # 800170c0 <bcache>
    80002e66:	ffffe097          	auipc	ra,0xffffe
    80002e6a:	e66080e7          	jalr	-410(ra) # 80000ccc <release>
      acquiresleep(&b->lock);
    80002e6e:	01048513          	addi	a0,s1,16
    80002e72:	00001097          	auipc	ra,0x1
    80002e76:	46c080e7          	jalr	1132(ra) # 800042de <acquiresleep>
      return b;
    80002e7a:	a8b9                	j	80002ed8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e7c:	0001c497          	auipc	s1,0x1c
    80002e80:	4f44b483          	ld	s1,1268(s1) # 8001f370 <bcache+0x82b0>
    80002e84:	0001c797          	auipc	a5,0x1c
    80002e88:	4a478793          	addi	a5,a5,1188 # 8001f328 <bcache+0x8268>
    80002e8c:	00f48863          	beq	s1,a5,80002e9c <bread+0x90>
    80002e90:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e92:	40bc                	lw	a5,64(s1)
    80002e94:	cf81                	beqz	a5,80002eac <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e96:	64a4                	ld	s1,72(s1)
    80002e98:	fee49de3          	bne	s1,a4,80002e92 <bread+0x86>
  panic("bget: no buffers");
    80002e9c:	00005517          	auipc	a0,0x5
    80002ea0:	64450513          	addi	a0,a0,1604 # 800084e0 <syscalls+0xc0>
    80002ea4:	ffffd097          	auipc	ra,0xffffd
    80002ea8:	6ac080e7          	jalr	1708(ra) # 80000550 <panic>
      b->dev = dev;
    80002eac:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002eb0:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002eb4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002eb8:	4785                	li	a5,1
    80002eba:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ebc:	00014517          	auipc	a0,0x14
    80002ec0:	20450513          	addi	a0,a0,516 # 800170c0 <bcache>
    80002ec4:	ffffe097          	auipc	ra,0xffffe
    80002ec8:	e08080e7          	jalr	-504(ra) # 80000ccc <release>
      acquiresleep(&b->lock);
    80002ecc:	01048513          	addi	a0,s1,16
    80002ed0:	00001097          	auipc	ra,0x1
    80002ed4:	40e080e7          	jalr	1038(ra) # 800042de <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002ed8:	409c                	lw	a5,0(s1)
    80002eda:	cb89                	beqz	a5,80002eec <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002edc:	8526                	mv	a0,s1
    80002ede:	70a2                	ld	ra,40(sp)
    80002ee0:	7402                	ld	s0,32(sp)
    80002ee2:	64e2                	ld	s1,24(sp)
    80002ee4:	6942                	ld	s2,16(sp)
    80002ee6:	69a2                	ld	s3,8(sp)
    80002ee8:	6145                	addi	sp,sp,48
    80002eea:	8082                	ret
    virtio_disk_rw(b, 0);
    80002eec:	4581                	li	a1,0
    80002eee:	8526                	mv	a0,s1
    80002ef0:	00003097          	auipc	ra,0x3
    80002ef4:	f66080e7          	jalr	-154(ra) # 80005e56 <virtio_disk_rw>
    b->valid = 1;
    80002ef8:	4785                	li	a5,1
    80002efa:	c09c                	sw	a5,0(s1)
  return b;
    80002efc:	b7c5                	j	80002edc <bread+0xd0>

0000000080002efe <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002efe:	1101                	addi	sp,sp,-32
    80002f00:	ec06                	sd	ra,24(sp)
    80002f02:	e822                	sd	s0,16(sp)
    80002f04:	e426                	sd	s1,8(sp)
    80002f06:	1000                	addi	s0,sp,32
    80002f08:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f0a:	0541                	addi	a0,a0,16
    80002f0c:	00001097          	auipc	ra,0x1
    80002f10:	46c080e7          	jalr	1132(ra) # 80004378 <holdingsleep>
    80002f14:	cd01                	beqz	a0,80002f2c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f16:	4585                	li	a1,1
    80002f18:	8526                	mv	a0,s1
    80002f1a:	00003097          	auipc	ra,0x3
    80002f1e:	f3c080e7          	jalr	-196(ra) # 80005e56 <virtio_disk_rw>
}
    80002f22:	60e2                	ld	ra,24(sp)
    80002f24:	6442                	ld	s0,16(sp)
    80002f26:	64a2                	ld	s1,8(sp)
    80002f28:	6105                	addi	sp,sp,32
    80002f2a:	8082                	ret
    panic("bwrite");
    80002f2c:	00005517          	auipc	a0,0x5
    80002f30:	5cc50513          	addi	a0,a0,1484 # 800084f8 <syscalls+0xd8>
    80002f34:	ffffd097          	auipc	ra,0xffffd
    80002f38:	61c080e7          	jalr	1564(ra) # 80000550 <panic>

0000000080002f3c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f3c:	1101                	addi	sp,sp,-32
    80002f3e:	ec06                	sd	ra,24(sp)
    80002f40:	e822                	sd	s0,16(sp)
    80002f42:	e426                	sd	s1,8(sp)
    80002f44:	e04a                	sd	s2,0(sp)
    80002f46:	1000                	addi	s0,sp,32
    80002f48:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f4a:	01050913          	addi	s2,a0,16
    80002f4e:	854a                	mv	a0,s2
    80002f50:	00001097          	auipc	ra,0x1
    80002f54:	428080e7          	jalr	1064(ra) # 80004378 <holdingsleep>
    80002f58:	c92d                	beqz	a0,80002fca <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f5a:	854a                	mv	a0,s2
    80002f5c:	00001097          	auipc	ra,0x1
    80002f60:	3d8080e7          	jalr	984(ra) # 80004334 <releasesleep>

  acquire(&bcache.lock);
    80002f64:	00014517          	auipc	a0,0x14
    80002f68:	15c50513          	addi	a0,a0,348 # 800170c0 <bcache>
    80002f6c:	ffffe097          	auipc	ra,0xffffe
    80002f70:	cac080e7          	jalr	-852(ra) # 80000c18 <acquire>
  b->refcnt--;
    80002f74:	40bc                	lw	a5,64(s1)
    80002f76:	37fd                	addiw	a5,a5,-1
    80002f78:	0007871b          	sext.w	a4,a5
    80002f7c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f7e:	eb05                	bnez	a4,80002fae <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f80:	68bc                	ld	a5,80(s1)
    80002f82:	64b8                	ld	a4,72(s1)
    80002f84:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f86:	64bc                	ld	a5,72(s1)
    80002f88:	68b8                	ld	a4,80(s1)
    80002f8a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f8c:	0001c797          	auipc	a5,0x1c
    80002f90:	13478793          	addi	a5,a5,308 # 8001f0c0 <bcache+0x8000>
    80002f94:	2b87b703          	ld	a4,696(a5)
    80002f98:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f9a:	0001c717          	auipc	a4,0x1c
    80002f9e:	38e70713          	addi	a4,a4,910 # 8001f328 <bcache+0x8268>
    80002fa2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002fa4:	2b87b703          	ld	a4,696(a5)
    80002fa8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002faa:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002fae:	00014517          	auipc	a0,0x14
    80002fb2:	11250513          	addi	a0,a0,274 # 800170c0 <bcache>
    80002fb6:	ffffe097          	auipc	ra,0xffffe
    80002fba:	d16080e7          	jalr	-746(ra) # 80000ccc <release>
}
    80002fbe:	60e2                	ld	ra,24(sp)
    80002fc0:	6442                	ld	s0,16(sp)
    80002fc2:	64a2                	ld	s1,8(sp)
    80002fc4:	6902                	ld	s2,0(sp)
    80002fc6:	6105                	addi	sp,sp,32
    80002fc8:	8082                	ret
    panic("brelse");
    80002fca:	00005517          	auipc	a0,0x5
    80002fce:	53650513          	addi	a0,a0,1334 # 80008500 <syscalls+0xe0>
    80002fd2:	ffffd097          	auipc	ra,0xffffd
    80002fd6:	57e080e7          	jalr	1406(ra) # 80000550 <panic>

0000000080002fda <bpin>:

void
bpin(struct buf *b) {
    80002fda:	1101                	addi	sp,sp,-32
    80002fdc:	ec06                	sd	ra,24(sp)
    80002fde:	e822                	sd	s0,16(sp)
    80002fe0:	e426                	sd	s1,8(sp)
    80002fe2:	1000                	addi	s0,sp,32
    80002fe4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fe6:	00014517          	auipc	a0,0x14
    80002fea:	0da50513          	addi	a0,a0,218 # 800170c0 <bcache>
    80002fee:	ffffe097          	auipc	ra,0xffffe
    80002ff2:	c2a080e7          	jalr	-982(ra) # 80000c18 <acquire>
  b->refcnt++;
    80002ff6:	40bc                	lw	a5,64(s1)
    80002ff8:	2785                	addiw	a5,a5,1
    80002ffa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002ffc:	00014517          	auipc	a0,0x14
    80003000:	0c450513          	addi	a0,a0,196 # 800170c0 <bcache>
    80003004:	ffffe097          	auipc	ra,0xffffe
    80003008:	cc8080e7          	jalr	-824(ra) # 80000ccc <release>
}
    8000300c:	60e2                	ld	ra,24(sp)
    8000300e:	6442                	ld	s0,16(sp)
    80003010:	64a2                	ld	s1,8(sp)
    80003012:	6105                	addi	sp,sp,32
    80003014:	8082                	ret

0000000080003016 <bunpin>:

void
bunpin(struct buf *b) {
    80003016:	1101                	addi	sp,sp,-32
    80003018:	ec06                	sd	ra,24(sp)
    8000301a:	e822                	sd	s0,16(sp)
    8000301c:	e426                	sd	s1,8(sp)
    8000301e:	1000                	addi	s0,sp,32
    80003020:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003022:	00014517          	auipc	a0,0x14
    80003026:	09e50513          	addi	a0,a0,158 # 800170c0 <bcache>
    8000302a:	ffffe097          	auipc	ra,0xffffe
    8000302e:	bee080e7          	jalr	-1042(ra) # 80000c18 <acquire>
  b->refcnt--;
    80003032:	40bc                	lw	a5,64(s1)
    80003034:	37fd                	addiw	a5,a5,-1
    80003036:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003038:	00014517          	auipc	a0,0x14
    8000303c:	08850513          	addi	a0,a0,136 # 800170c0 <bcache>
    80003040:	ffffe097          	auipc	ra,0xffffe
    80003044:	c8c080e7          	jalr	-884(ra) # 80000ccc <release>
}
    80003048:	60e2                	ld	ra,24(sp)
    8000304a:	6442                	ld	s0,16(sp)
    8000304c:	64a2                	ld	s1,8(sp)
    8000304e:	6105                	addi	sp,sp,32
    80003050:	8082                	ret

0000000080003052 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003052:	1101                	addi	sp,sp,-32
    80003054:	ec06                	sd	ra,24(sp)
    80003056:	e822                	sd	s0,16(sp)
    80003058:	e426                	sd	s1,8(sp)
    8000305a:	e04a                	sd	s2,0(sp)
    8000305c:	1000                	addi	s0,sp,32
    8000305e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003060:	00d5d59b          	srliw	a1,a1,0xd
    80003064:	0001c797          	auipc	a5,0x1c
    80003068:	7387a783          	lw	a5,1848(a5) # 8001f79c <sb+0x1c>
    8000306c:	9dbd                	addw	a1,a1,a5
    8000306e:	00000097          	auipc	ra,0x0
    80003072:	d9e080e7          	jalr	-610(ra) # 80002e0c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003076:	0074f713          	andi	a4,s1,7
    8000307a:	4785                	li	a5,1
    8000307c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003080:	14ce                	slli	s1,s1,0x33
    80003082:	90d9                	srli	s1,s1,0x36
    80003084:	00950733          	add	a4,a0,s1
    80003088:	05874703          	lbu	a4,88(a4)
    8000308c:	00e7f6b3          	and	a3,a5,a4
    80003090:	c69d                	beqz	a3,800030be <bfree+0x6c>
    80003092:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003094:	94aa                	add	s1,s1,a0
    80003096:	fff7c793          	not	a5,a5
    8000309a:	8ff9                	and	a5,a5,a4
    8000309c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800030a0:	00001097          	auipc	ra,0x1
    800030a4:	116080e7          	jalr	278(ra) # 800041b6 <log_write>
  brelse(bp);
    800030a8:	854a                	mv	a0,s2
    800030aa:	00000097          	auipc	ra,0x0
    800030ae:	e92080e7          	jalr	-366(ra) # 80002f3c <brelse>
}
    800030b2:	60e2                	ld	ra,24(sp)
    800030b4:	6442                	ld	s0,16(sp)
    800030b6:	64a2                	ld	s1,8(sp)
    800030b8:	6902                	ld	s2,0(sp)
    800030ba:	6105                	addi	sp,sp,32
    800030bc:	8082                	ret
    panic("freeing free block");
    800030be:	00005517          	auipc	a0,0x5
    800030c2:	44a50513          	addi	a0,a0,1098 # 80008508 <syscalls+0xe8>
    800030c6:	ffffd097          	auipc	ra,0xffffd
    800030ca:	48a080e7          	jalr	1162(ra) # 80000550 <panic>

00000000800030ce <balloc>:
{
    800030ce:	711d                	addi	sp,sp,-96
    800030d0:	ec86                	sd	ra,88(sp)
    800030d2:	e8a2                	sd	s0,80(sp)
    800030d4:	e4a6                	sd	s1,72(sp)
    800030d6:	e0ca                	sd	s2,64(sp)
    800030d8:	fc4e                	sd	s3,56(sp)
    800030da:	f852                	sd	s4,48(sp)
    800030dc:	f456                	sd	s5,40(sp)
    800030de:	f05a                	sd	s6,32(sp)
    800030e0:	ec5e                	sd	s7,24(sp)
    800030e2:	e862                	sd	s8,16(sp)
    800030e4:	e466                	sd	s9,8(sp)
    800030e6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800030e8:	0001c797          	auipc	a5,0x1c
    800030ec:	69c7a783          	lw	a5,1692(a5) # 8001f784 <sb+0x4>
    800030f0:	cbd1                	beqz	a5,80003184 <balloc+0xb6>
    800030f2:	8baa                	mv	s7,a0
    800030f4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800030f6:	0001cb17          	auipc	s6,0x1c
    800030fa:	68ab0b13          	addi	s6,s6,1674 # 8001f780 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030fe:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003100:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003102:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003104:	6c89                	lui	s9,0x2
    80003106:	a831                	j	80003122 <balloc+0x54>
    brelse(bp);
    80003108:	854a                	mv	a0,s2
    8000310a:	00000097          	auipc	ra,0x0
    8000310e:	e32080e7          	jalr	-462(ra) # 80002f3c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003112:	015c87bb          	addw	a5,s9,s5
    80003116:	00078a9b          	sext.w	s5,a5
    8000311a:	004b2703          	lw	a4,4(s6)
    8000311e:	06eaf363          	bgeu	s5,a4,80003184 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003122:	41fad79b          	sraiw	a5,s5,0x1f
    80003126:	0137d79b          	srliw	a5,a5,0x13
    8000312a:	015787bb          	addw	a5,a5,s5
    8000312e:	40d7d79b          	sraiw	a5,a5,0xd
    80003132:	01cb2583          	lw	a1,28(s6)
    80003136:	9dbd                	addw	a1,a1,a5
    80003138:	855e                	mv	a0,s7
    8000313a:	00000097          	auipc	ra,0x0
    8000313e:	cd2080e7          	jalr	-814(ra) # 80002e0c <bread>
    80003142:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003144:	004b2503          	lw	a0,4(s6)
    80003148:	000a849b          	sext.w	s1,s5
    8000314c:	8662                	mv	a2,s8
    8000314e:	faa4fde3          	bgeu	s1,a0,80003108 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003152:	41f6579b          	sraiw	a5,a2,0x1f
    80003156:	01d7d69b          	srliw	a3,a5,0x1d
    8000315a:	00c6873b          	addw	a4,a3,a2
    8000315e:	00777793          	andi	a5,a4,7
    80003162:	9f95                	subw	a5,a5,a3
    80003164:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003168:	4037571b          	sraiw	a4,a4,0x3
    8000316c:	00e906b3          	add	a3,s2,a4
    80003170:	0586c683          	lbu	a3,88(a3)
    80003174:	00d7f5b3          	and	a1,a5,a3
    80003178:	cd91                	beqz	a1,80003194 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000317a:	2605                	addiw	a2,a2,1
    8000317c:	2485                	addiw	s1,s1,1
    8000317e:	fd4618e3          	bne	a2,s4,8000314e <balloc+0x80>
    80003182:	b759                	j	80003108 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003184:	00005517          	auipc	a0,0x5
    80003188:	39c50513          	addi	a0,a0,924 # 80008520 <syscalls+0x100>
    8000318c:	ffffd097          	auipc	ra,0xffffd
    80003190:	3c4080e7          	jalr	964(ra) # 80000550 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003194:	974a                	add	a4,a4,s2
    80003196:	8fd5                	or	a5,a5,a3
    80003198:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000319c:	854a                	mv	a0,s2
    8000319e:	00001097          	auipc	ra,0x1
    800031a2:	018080e7          	jalr	24(ra) # 800041b6 <log_write>
        brelse(bp);
    800031a6:	854a                	mv	a0,s2
    800031a8:	00000097          	auipc	ra,0x0
    800031ac:	d94080e7          	jalr	-620(ra) # 80002f3c <brelse>
  bp = bread(dev, bno);
    800031b0:	85a6                	mv	a1,s1
    800031b2:	855e                	mv	a0,s7
    800031b4:	00000097          	auipc	ra,0x0
    800031b8:	c58080e7          	jalr	-936(ra) # 80002e0c <bread>
    800031bc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031be:	40000613          	li	a2,1024
    800031c2:	4581                	li	a1,0
    800031c4:	05850513          	addi	a0,a0,88
    800031c8:	ffffe097          	auipc	ra,0xffffe
    800031cc:	b4c080e7          	jalr	-1204(ra) # 80000d14 <memset>
  log_write(bp);
    800031d0:	854a                	mv	a0,s2
    800031d2:	00001097          	auipc	ra,0x1
    800031d6:	fe4080e7          	jalr	-28(ra) # 800041b6 <log_write>
  brelse(bp);
    800031da:	854a                	mv	a0,s2
    800031dc:	00000097          	auipc	ra,0x0
    800031e0:	d60080e7          	jalr	-672(ra) # 80002f3c <brelse>
}
    800031e4:	8526                	mv	a0,s1
    800031e6:	60e6                	ld	ra,88(sp)
    800031e8:	6446                	ld	s0,80(sp)
    800031ea:	64a6                	ld	s1,72(sp)
    800031ec:	6906                	ld	s2,64(sp)
    800031ee:	79e2                	ld	s3,56(sp)
    800031f0:	7a42                	ld	s4,48(sp)
    800031f2:	7aa2                	ld	s5,40(sp)
    800031f4:	7b02                	ld	s6,32(sp)
    800031f6:	6be2                	ld	s7,24(sp)
    800031f8:	6c42                	ld	s8,16(sp)
    800031fa:	6ca2                	ld	s9,8(sp)
    800031fc:	6125                	addi	sp,sp,96
    800031fe:	8082                	ret

0000000080003200 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003200:	7179                	addi	sp,sp,-48
    80003202:	f406                	sd	ra,40(sp)
    80003204:	f022                	sd	s0,32(sp)
    80003206:	ec26                	sd	s1,24(sp)
    80003208:	e84a                	sd	s2,16(sp)
    8000320a:	e44e                	sd	s3,8(sp)
    8000320c:	e052                	sd	s4,0(sp)
    8000320e:	1800                	addi	s0,sp,48
    80003210:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003212:	47ad                	li	a5,11
    80003214:	04b7fe63          	bgeu	a5,a1,80003270 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003218:	ff45849b          	addiw	s1,a1,-12
    8000321c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003220:	0ff00793          	li	a5,255
    80003224:	0ae7e363          	bltu	a5,a4,800032ca <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003228:	08052583          	lw	a1,128(a0)
    8000322c:	c5ad                	beqz	a1,80003296 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000322e:	00092503          	lw	a0,0(s2)
    80003232:	00000097          	auipc	ra,0x0
    80003236:	bda080e7          	jalr	-1062(ra) # 80002e0c <bread>
    8000323a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000323c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003240:	02049593          	slli	a1,s1,0x20
    80003244:	9181                	srli	a1,a1,0x20
    80003246:	058a                	slli	a1,a1,0x2
    80003248:	00b784b3          	add	s1,a5,a1
    8000324c:	0004a983          	lw	s3,0(s1)
    80003250:	04098d63          	beqz	s3,800032aa <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003254:	8552                	mv	a0,s4
    80003256:	00000097          	auipc	ra,0x0
    8000325a:	ce6080e7          	jalr	-794(ra) # 80002f3c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000325e:	854e                	mv	a0,s3
    80003260:	70a2                	ld	ra,40(sp)
    80003262:	7402                	ld	s0,32(sp)
    80003264:	64e2                	ld	s1,24(sp)
    80003266:	6942                	ld	s2,16(sp)
    80003268:	69a2                	ld	s3,8(sp)
    8000326a:	6a02                	ld	s4,0(sp)
    8000326c:	6145                	addi	sp,sp,48
    8000326e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003270:	02059493          	slli	s1,a1,0x20
    80003274:	9081                	srli	s1,s1,0x20
    80003276:	048a                	slli	s1,s1,0x2
    80003278:	94aa                	add	s1,s1,a0
    8000327a:	0504a983          	lw	s3,80(s1)
    8000327e:	fe0990e3          	bnez	s3,8000325e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003282:	4108                	lw	a0,0(a0)
    80003284:	00000097          	auipc	ra,0x0
    80003288:	e4a080e7          	jalr	-438(ra) # 800030ce <balloc>
    8000328c:	0005099b          	sext.w	s3,a0
    80003290:	0534a823          	sw	s3,80(s1)
    80003294:	b7e9                	j	8000325e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003296:	4108                	lw	a0,0(a0)
    80003298:	00000097          	auipc	ra,0x0
    8000329c:	e36080e7          	jalr	-458(ra) # 800030ce <balloc>
    800032a0:	0005059b          	sext.w	a1,a0
    800032a4:	08b92023          	sw	a1,128(s2)
    800032a8:	b759                	j	8000322e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800032aa:	00092503          	lw	a0,0(s2)
    800032ae:	00000097          	auipc	ra,0x0
    800032b2:	e20080e7          	jalr	-480(ra) # 800030ce <balloc>
    800032b6:	0005099b          	sext.w	s3,a0
    800032ba:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800032be:	8552                	mv	a0,s4
    800032c0:	00001097          	auipc	ra,0x1
    800032c4:	ef6080e7          	jalr	-266(ra) # 800041b6 <log_write>
    800032c8:	b771                	j	80003254 <bmap+0x54>
  panic("bmap: out of range");
    800032ca:	00005517          	auipc	a0,0x5
    800032ce:	26e50513          	addi	a0,a0,622 # 80008538 <syscalls+0x118>
    800032d2:	ffffd097          	auipc	ra,0xffffd
    800032d6:	27e080e7          	jalr	638(ra) # 80000550 <panic>

00000000800032da <iget>:
{
    800032da:	7179                	addi	sp,sp,-48
    800032dc:	f406                	sd	ra,40(sp)
    800032de:	f022                	sd	s0,32(sp)
    800032e0:	ec26                	sd	s1,24(sp)
    800032e2:	e84a                	sd	s2,16(sp)
    800032e4:	e44e                	sd	s3,8(sp)
    800032e6:	e052                	sd	s4,0(sp)
    800032e8:	1800                	addi	s0,sp,48
    800032ea:	89aa                	mv	s3,a0
    800032ec:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800032ee:	0001c517          	auipc	a0,0x1c
    800032f2:	4b250513          	addi	a0,a0,1202 # 8001f7a0 <icache>
    800032f6:	ffffe097          	auipc	ra,0xffffe
    800032fa:	922080e7          	jalr	-1758(ra) # 80000c18 <acquire>
  empty = 0;
    800032fe:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003300:	0001c497          	auipc	s1,0x1c
    80003304:	4b848493          	addi	s1,s1,1208 # 8001f7b8 <icache+0x18>
    80003308:	0001e697          	auipc	a3,0x1e
    8000330c:	f4068693          	addi	a3,a3,-192 # 80021248 <log>
    80003310:	a039                	j	8000331e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003312:	02090b63          	beqz	s2,80003348 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003316:	08848493          	addi	s1,s1,136
    8000331a:	02d48a63          	beq	s1,a3,8000334e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000331e:	449c                	lw	a5,8(s1)
    80003320:	fef059e3          	blez	a5,80003312 <iget+0x38>
    80003324:	4098                	lw	a4,0(s1)
    80003326:	ff3716e3          	bne	a4,s3,80003312 <iget+0x38>
    8000332a:	40d8                	lw	a4,4(s1)
    8000332c:	ff4713e3          	bne	a4,s4,80003312 <iget+0x38>
      ip->ref++;
    80003330:	2785                	addiw	a5,a5,1
    80003332:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003334:	0001c517          	auipc	a0,0x1c
    80003338:	46c50513          	addi	a0,a0,1132 # 8001f7a0 <icache>
    8000333c:	ffffe097          	auipc	ra,0xffffe
    80003340:	990080e7          	jalr	-1648(ra) # 80000ccc <release>
      return ip;
    80003344:	8926                	mv	s2,s1
    80003346:	a03d                	j	80003374 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003348:	f7f9                	bnez	a5,80003316 <iget+0x3c>
    8000334a:	8926                	mv	s2,s1
    8000334c:	b7e9                	j	80003316 <iget+0x3c>
  if(empty == 0)
    8000334e:	02090c63          	beqz	s2,80003386 <iget+0xac>
  ip->dev = dev;
    80003352:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003356:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000335a:	4785                	li	a5,1
    8000335c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003360:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003364:	0001c517          	auipc	a0,0x1c
    80003368:	43c50513          	addi	a0,a0,1084 # 8001f7a0 <icache>
    8000336c:	ffffe097          	auipc	ra,0xffffe
    80003370:	960080e7          	jalr	-1696(ra) # 80000ccc <release>
}
    80003374:	854a                	mv	a0,s2
    80003376:	70a2                	ld	ra,40(sp)
    80003378:	7402                	ld	s0,32(sp)
    8000337a:	64e2                	ld	s1,24(sp)
    8000337c:	6942                	ld	s2,16(sp)
    8000337e:	69a2                	ld	s3,8(sp)
    80003380:	6a02                	ld	s4,0(sp)
    80003382:	6145                	addi	sp,sp,48
    80003384:	8082                	ret
    panic("iget: no inodes");
    80003386:	00005517          	auipc	a0,0x5
    8000338a:	1ca50513          	addi	a0,a0,458 # 80008550 <syscalls+0x130>
    8000338e:	ffffd097          	auipc	ra,0xffffd
    80003392:	1c2080e7          	jalr	450(ra) # 80000550 <panic>

0000000080003396 <fsinit>:
fsinit(int dev) {
    80003396:	7179                	addi	sp,sp,-48
    80003398:	f406                	sd	ra,40(sp)
    8000339a:	f022                	sd	s0,32(sp)
    8000339c:	ec26                	sd	s1,24(sp)
    8000339e:	e84a                	sd	s2,16(sp)
    800033a0:	e44e                	sd	s3,8(sp)
    800033a2:	1800                	addi	s0,sp,48
    800033a4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800033a6:	4585                	li	a1,1
    800033a8:	00000097          	auipc	ra,0x0
    800033ac:	a64080e7          	jalr	-1436(ra) # 80002e0c <bread>
    800033b0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033b2:	0001c997          	auipc	s3,0x1c
    800033b6:	3ce98993          	addi	s3,s3,974 # 8001f780 <sb>
    800033ba:	02000613          	li	a2,32
    800033be:	05850593          	addi	a1,a0,88
    800033c2:	854e                	mv	a0,s3
    800033c4:	ffffe097          	auipc	ra,0xffffe
    800033c8:	9b0080e7          	jalr	-1616(ra) # 80000d74 <memmove>
  brelse(bp);
    800033cc:	8526                	mv	a0,s1
    800033ce:	00000097          	auipc	ra,0x0
    800033d2:	b6e080e7          	jalr	-1170(ra) # 80002f3c <brelse>
  if(sb.magic != FSMAGIC)
    800033d6:	0009a703          	lw	a4,0(s3)
    800033da:	102037b7          	lui	a5,0x10203
    800033de:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800033e2:	02f71263          	bne	a4,a5,80003406 <fsinit+0x70>
  initlog(dev, &sb);
    800033e6:	0001c597          	auipc	a1,0x1c
    800033ea:	39a58593          	addi	a1,a1,922 # 8001f780 <sb>
    800033ee:	854a                	mv	a0,s2
    800033f0:	00001097          	auipc	ra,0x1
    800033f4:	b4a080e7          	jalr	-1206(ra) # 80003f3a <initlog>
}
    800033f8:	70a2                	ld	ra,40(sp)
    800033fa:	7402                	ld	s0,32(sp)
    800033fc:	64e2                	ld	s1,24(sp)
    800033fe:	6942                	ld	s2,16(sp)
    80003400:	69a2                	ld	s3,8(sp)
    80003402:	6145                	addi	sp,sp,48
    80003404:	8082                	ret
    panic("invalid file system");
    80003406:	00005517          	auipc	a0,0x5
    8000340a:	15a50513          	addi	a0,a0,346 # 80008560 <syscalls+0x140>
    8000340e:	ffffd097          	auipc	ra,0xffffd
    80003412:	142080e7          	jalr	322(ra) # 80000550 <panic>

0000000080003416 <iinit>:
{
    80003416:	7179                	addi	sp,sp,-48
    80003418:	f406                	sd	ra,40(sp)
    8000341a:	f022                	sd	s0,32(sp)
    8000341c:	ec26                	sd	s1,24(sp)
    8000341e:	e84a                	sd	s2,16(sp)
    80003420:	e44e                	sd	s3,8(sp)
    80003422:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003424:	00005597          	auipc	a1,0x5
    80003428:	15458593          	addi	a1,a1,340 # 80008578 <syscalls+0x158>
    8000342c:	0001c517          	auipc	a0,0x1c
    80003430:	37450513          	addi	a0,a0,884 # 8001f7a0 <icache>
    80003434:	ffffd097          	auipc	ra,0xffffd
    80003438:	754080e7          	jalr	1876(ra) # 80000b88 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000343c:	0001c497          	auipc	s1,0x1c
    80003440:	38c48493          	addi	s1,s1,908 # 8001f7c8 <icache+0x28>
    80003444:	0001e997          	auipc	s3,0x1e
    80003448:	e1498993          	addi	s3,s3,-492 # 80021258 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000344c:	00005917          	auipc	s2,0x5
    80003450:	13490913          	addi	s2,s2,308 # 80008580 <syscalls+0x160>
    80003454:	85ca                	mv	a1,s2
    80003456:	8526                	mv	a0,s1
    80003458:	00001097          	auipc	ra,0x1
    8000345c:	e4c080e7          	jalr	-436(ra) # 800042a4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003460:	08848493          	addi	s1,s1,136
    80003464:	ff3498e3          	bne	s1,s3,80003454 <iinit+0x3e>
}
    80003468:	70a2                	ld	ra,40(sp)
    8000346a:	7402                	ld	s0,32(sp)
    8000346c:	64e2                	ld	s1,24(sp)
    8000346e:	6942                	ld	s2,16(sp)
    80003470:	69a2                	ld	s3,8(sp)
    80003472:	6145                	addi	sp,sp,48
    80003474:	8082                	ret

0000000080003476 <ialloc>:
{
    80003476:	715d                	addi	sp,sp,-80
    80003478:	e486                	sd	ra,72(sp)
    8000347a:	e0a2                	sd	s0,64(sp)
    8000347c:	fc26                	sd	s1,56(sp)
    8000347e:	f84a                	sd	s2,48(sp)
    80003480:	f44e                	sd	s3,40(sp)
    80003482:	f052                	sd	s4,32(sp)
    80003484:	ec56                	sd	s5,24(sp)
    80003486:	e85a                	sd	s6,16(sp)
    80003488:	e45e                	sd	s7,8(sp)
    8000348a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000348c:	0001c717          	auipc	a4,0x1c
    80003490:	30072703          	lw	a4,768(a4) # 8001f78c <sb+0xc>
    80003494:	4785                	li	a5,1
    80003496:	04e7fa63          	bgeu	a5,a4,800034ea <ialloc+0x74>
    8000349a:	8aaa                	mv	s5,a0
    8000349c:	8bae                	mv	s7,a1
    8000349e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800034a0:	0001ca17          	auipc	s4,0x1c
    800034a4:	2e0a0a13          	addi	s4,s4,736 # 8001f780 <sb>
    800034a8:	00048b1b          	sext.w	s6,s1
    800034ac:	0044d593          	srli	a1,s1,0x4
    800034b0:	018a2783          	lw	a5,24(s4)
    800034b4:	9dbd                	addw	a1,a1,a5
    800034b6:	8556                	mv	a0,s5
    800034b8:	00000097          	auipc	ra,0x0
    800034bc:	954080e7          	jalr	-1708(ra) # 80002e0c <bread>
    800034c0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800034c2:	05850993          	addi	s3,a0,88
    800034c6:	00f4f793          	andi	a5,s1,15
    800034ca:	079a                	slli	a5,a5,0x6
    800034cc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800034ce:	00099783          	lh	a5,0(s3)
    800034d2:	c785                	beqz	a5,800034fa <ialloc+0x84>
    brelse(bp);
    800034d4:	00000097          	auipc	ra,0x0
    800034d8:	a68080e7          	jalr	-1432(ra) # 80002f3c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800034dc:	0485                	addi	s1,s1,1
    800034de:	00ca2703          	lw	a4,12(s4)
    800034e2:	0004879b          	sext.w	a5,s1
    800034e6:	fce7e1e3          	bltu	a5,a4,800034a8 <ialloc+0x32>
  panic("ialloc: no inodes");
    800034ea:	00005517          	auipc	a0,0x5
    800034ee:	09e50513          	addi	a0,a0,158 # 80008588 <syscalls+0x168>
    800034f2:	ffffd097          	auipc	ra,0xffffd
    800034f6:	05e080e7          	jalr	94(ra) # 80000550 <panic>
      memset(dip, 0, sizeof(*dip));
    800034fa:	04000613          	li	a2,64
    800034fe:	4581                	li	a1,0
    80003500:	854e                	mv	a0,s3
    80003502:	ffffe097          	auipc	ra,0xffffe
    80003506:	812080e7          	jalr	-2030(ra) # 80000d14 <memset>
      dip->type = type;
    8000350a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000350e:	854a                	mv	a0,s2
    80003510:	00001097          	auipc	ra,0x1
    80003514:	ca6080e7          	jalr	-858(ra) # 800041b6 <log_write>
      brelse(bp);
    80003518:	854a                	mv	a0,s2
    8000351a:	00000097          	auipc	ra,0x0
    8000351e:	a22080e7          	jalr	-1502(ra) # 80002f3c <brelse>
      return iget(dev, inum);
    80003522:	85da                	mv	a1,s6
    80003524:	8556                	mv	a0,s5
    80003526:	00000097          	auipc	ra,0x0
    8000352a:	db4080e7          	jalr	-588(ra) # 800032da <iget>
}
    8000352e:	60a6                	ld	ra,72(sp)
    80003530:	6406                	ld	s0,64(sp)
    80003532:	74e2                	ld	s1,56(sp)
    80003534:	7942                	ld	s2,48(sp)
    80003536:	79a2                	ld	s3,40(sp)
    80003538:	7a02                	ld	s4,32(sp)
    8000353a:	6ae2                	ld	s5,24(sp)
    8000353c:	6b42                	ld	s6,16(sp)
    8000353e:	6ba2                	ld	s7,8(sp)
    80003540:	6161                	addi	sp,sp,80
    80003542:	8082                	ret

0000000080003544 <iupdate>:
{
    80003544:	1101                	addi	sp,sp,-32
    80003546:	ec06                	sd	ra,24(sp)
    80003548:	e822                	sd	s0,16(sp)
    8000354a:	e426                	sd	s1,8(sp)
    8000354c:	e04a                	sd	s2,0(sp)
    8000354e:	1000                	addi	s0,sp,32
    80003550:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003552:	415c                	lw	a5,4(a0)
    80003554:	0047d79b          	srliw	a5,a5,0x4
    80003558:	0001c597          	auipc	a1,0x1c
    8000355c:	2405a583          	lw	a1,576(a1) # 8001f798 <sb+0x18>
    80003560:	9dbd                	addw	a1,a1,a5
    80003562:	4108                	lw	a0,0(a0)
    80003564:	00000097          	auipc	ra,0x0
    80003568:	8a8080e7          	jalr	-1880(ra) # 80002e0c <bread>
    8000356c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000356e:	05850793          	addi	a5,a0,88
    80003572:	40c8                	lw	a0,4(s1)
    80003574:	893d                	andi	a0,a0,15
    80003576:	051a                	slli	a0,a0,0x6
    80003578:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000357a:	04449703          	lh	a4,68(s1)
    8000357e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003582:	04649703          	lh	a4,70(s1)
    80003586:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000358a:	04849703          	lh	a4,72(s1)
    8000358e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003592:	04a49703          	lh	a4,74(s1)
    80003596:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000359a:	44f8                	lw	a4,76(s1)
    8000359c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000359e:	03400613          	li	a2,52
    800035a2:	05048593          	addi	a1,s1,80
    800035a6:	0531                	addi	a0,a0,12
    800035a8:	ffffd097          	auipc	ra,0xffffd
    800035ac:	7cc080e7          	jalr	1996(ra) # 80000d74 <memmove>
  log_write(bp);
    800035b0:	854a                	mv	a0,s2
    800035b2:	00001097          	auipc	ra,0x1
    800035b6:	c04080e7          	jalr	-1020(ra) # 800041b6 <log_write>
  brelse(bp);
    800035ba:	854a                	mv	a0,s2
    800035bc:	00000097          	auipc	ra,0x0
    800035c0:	980080e7          	jalr	-1664(ra) # 80002f3c <brelse>
}
    800035c4:	60e2                	ld	ra,24(sp)
    800035c6:	6442                	ld	s0,16(sp)
    800035c8:	64a2                	ld	s1,8(sp)
    800035ca:	6902                	ld	s2,0(sp)
    800035cc:	6105                	addi	sp,sp,32
    800035ce:	8082                	ret

00000000800035d0 <idup>:
{
    800035d0:	1101                	addi	sp,sp,-32
    800035d2:	ec06                	sd	ra,24(sp)
    800035d4:	e822                	sd	s0,16(sp)
    800035d6:	e426                	sd	s1,8(sp)
    800035d8:	1000                	addi	s0,sp,32
    800035da:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800035dc:	0001c517          	auipc	a0,0x1c
    800035e0:	1c450513          	addi	a0,a0,452 # 8001f7a0 <icache>
    800035e4:	ffffd097          	auipc	ra,0xffffd
    800035e8:	634080e7          	jalr	1588(ra) # 80000c18 <acquire>
  ip->ref++;
    800035ec:	449c                	lw	a5,8(s1)
    800035ee:	2785                	addiw	a5,a5,1
    800035f0:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800035f2:	0001c517          	auipc	a0,0x1c
    800035f6:	1ae50513          	addi	a0,a0,430 # 8001f7a0 <icache>
    800035fa:	ffffd097          	auipc	ra,0xffffd
    800035fe:	6d2080e7          	jalr	1746(ra) # 80000ccc <release>
}
    80003602:	8526                	mv	a0,s1
    80003604:	60e2                	ld	ra,24(sp)
    80003606:	6442                	ld	s0,16(sp)
    80003608:	64a2                	ld	s1,8(sp)
    8000360a:	6105                	addi	sp,sp,32
    8000360c:	8082                	ret

000000008000360e <ilock>:
{
    8000360e:	1101                	addi	sp,sp,-32
    80003610:	ec06                	sd	ra,24(sp)
    80003612:	e822                	sd	s0,16(sp)
    80003614:	e426                	sd	s1,8(sp)
    80003616:	e04a                	sd	s2,0(sp)
    80003618:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000361a:	c115                	beqz	a0,8000363e <ilock+0x30>
    8000361c:	84aa                	mv	s1,a0
    8000361e:	451c                	lw	a5,8(a0)
    80003620:	00f05f63          	blez	a5,8000363e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003624:	0541                	addi	a0,a0,16
    80003626:	00001097          	auipc	ra,0x1
    8000362a:	cb8080e7          	jalr	-840(ra) # 800042de <acquiresleep>
  if(ip->valid == 0){
    8000362e:	40bc                	lw	a5,64(s1)
    80003630:	cf99                	beqz	a5,8000364e <ilock+0x40>
}
    80003632:	60e2                	ld	ra,24(sp)
    80003634:	6442                	ld	s0,16(sp)
    80003636:	64a2                	ld	s1,8(sp)
    80003638:	6902                	ld	s2,0(sp)
    8000363a:	6105                	addi	sp,sp,32
    8000363c:	8082                	ret
    panic("ilock");
    8000363e:	00005517          	auipc	a0,0x5
    80003642:	f6250513          	addi	a0,a0,-158 # 800085a0 <syscalls+0x180>
    80003646:	ffffd097          	auipc	ra,0xffffd
    8000364a:	f0a080e7          	jalr	-246(ra) # 80000550 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000364e:	40dc                	lw	a5,4(s1)
    80003650:	0047d79b          	srliw	a5,a5,0x4
    80003654:	0001c597          	auipc	a1,0x1c
    80003658:	1445a583          	lw	a1,324(a1) # 8001f798 <sb+0x18>
    8000365c:	9dbd                	addw	a1,a1,a5
    8000365e:	4088                	lw	a0,0(s1)
    80003660:	fffff097          	auipc	ra,0xfffff
    80003664:	7ac080e7          	jalr	1964(ra) # 80002e0c <bread>
    80003668:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000366a:	05850593          	addi	a1,a0,88
    8000366e:	40dc                	lw	a5,4(s1)
    80003670:	8bbd                	andi	a5,a5,15
    80003672:	079a                	slli	a5,a5,0x6
    80003674:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003676:	00059783          	lh	a5,0(a1)
    8000367a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000367e:	00259783          	lh	a5,2(a1)
    80003682:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003686:	00459783          	lh	a5,4(a1)
    8000368a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000368e:	00659783          	lh	a5,6(a1)
    80003692:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003696:	459c                	lw	a5,8(a1)
    80003698:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000369a:	03400613          	li	a2,52
    8000369e:	05b1                	addi	a1,a1,12
    800036a0:	05048513          	addi	a0,s1,80
    800036a4:	ffffd097          	auipc	ra,0xffffd
    800036a8:	6d0080e7          	jalr	1744(ra) # 80000d74 <memmove>
    brelse(bp);
    800036ac:	854a                	mv	a0,s2
    800036ae:	00000097          	auipc	ra,0x0
    800036b2:	88e080e7          	jalr	-1906(ra) # 80002f3c <brelse>
    ip->valid = 1;
    800036b6:	4785                	li	a5,1
    800036b8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800036ba:	04449783          	lh	a5,68(s1)
    800036be:	fbb5                	bnez	a5,80003632 <ilock+0x24>
      panic("ilock: no type");
    800036c0:	00005517          	auipc	a0,0x5
    800036c4:	ee850513          	addi	a0,a0,-280 # 800085a8 <syscalls+0x188>
    800036c8:	ffffd097          	auipc	ra,0xffffd
    800036cc:	e88080e7          	jalr	-376(ra) # 80000550 <panic>

00000000800036d0 <iunlock>:
{
    800036d0:	1101                	addi	sp,sp,-32
    800036d2:	ec06                	sd	ra,24(sp)
    800036d4:	e822                	sd	s0,16(sp)
    800036d6:	e426                	sd	s1,8(sp)
    800036d8:	e04a                	sd	s2,0(sp)
    800036da:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800036dc:	c905                	beqz	a0,8000370c <iunlock+0x3c>
    800036de:	84aa                	mv	s1,a0
    800036e0:	01050913          	addi	s2,a0,16
    800036e4:	854a                	mv	a0,s2
    800036e6:	00001097          	auipc	ra,0x1
    800036ea:	c92080e7          	jalr	-878(ra) # 80004378 <holdingsleep>
    800036ee:	cd19                	beqz	a0,8000370c <iunlock+0x3c>
    800036f0:	449c                	lw	a5,8(s1)
    800036f2:	00f05d63          	blez	a5,8000370c <iunlock+0x3c>
  releasesleep(&ip->lock);
    800036f6:	854a                	mv	a0,s2
    800036f8:	00001097          	auipc	ra,0x1
    800036fc:	c3c080e7          	jalr	-964(ra) # 80004334 <releasesleep>
}
    80003700:	60e2                	ld	ra,24(sp)
    80003702:	6442                	ld	s0,16(sp)
    80003704:	64a2                	ld	s1,8(sp)
    80003706:	6902                	ld	s2,0(sp)
    80003708:	6105                	addi	sp,sp,32
    8000370a:	8082                	ret
    panic("iunlock");
    8000370c:	00005517          	auipc	a0,0x5
    80003710:	eac50513          	addi	a0,a0,-340 # 800085b8 <syscalls+0x198>
    80003714:	ffffd097          	auipc	ra,0xffffd
    80003718:	e3c080e7          	jalr	-452(ra) # 80000550 <panic>

000000008000371c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000371c:	7179                	addi	sp,sp,-48
    8000371e:	f406                	sd	ra,40(sp)
    80003720:	f022                	sd	s0,32(sp)
    80003722:	ec26                	sd	s1,24(sp)
    80003724:	e84a                	sd	s2,16(sp)
    80003726:	e44e                	sd	s3,8(sp)
    80003728:	e052                	sd	s4,0(sp)
    8000372a:	1800                	addi	s0,sp,48
    8000372c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000372e:	05050493          	addi	s1,a0,80
    80003732:	08050913          	addi	s2,a0,128
    80003736:	a021                	j	8000373e <itrunc+0x22>
    80003738:	0491                	addi	s1,s1,4
    8000373a:	01248d63          	beq	s1,s2,80003754 <itrunc+0x38>
    if(ip->addrs[i]){
    8000373e:	408c                	lw	a1,0(s1)
    80003740:	dde5                	beqz	a1,80003738 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003742:	0009a503          	lw	a0,0(s3)
    80003746:	00000097          	auipc	ra,0x0
    8000374a:	90c080e7          	jalr	-1780(ra) # 80003052 <bfree>
      ip->addrs[i] = 0;
    8000374e:	0004a023          	sw	zero,0(s1)
    80003752:	b7dd                	j	80003738 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003754:	0809a583          	lw	a1,128(s3)
    80003758:	e185                	bnez	a1,80003778 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000375a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000375e:	854e                	mv	a0,s3
    80003760:	00000097          	auipc	ra,0x0
    80003764:	de4080e7          	jalr	-540(ra) # 80003544 <iupdate>
}
    80003768:	70a2                	ld	ra,40(sp)
    8000376a:	7402                	ld	s0,32(sp)
    8000376c:	64e2                	ld	s1,24(sp)
    8000376e:	6942                	ld	s2,16(sp)
    80003770:	69a2                	ld	s3,8(sp)
    80003772:	6a02                	ld	s4,0(sp)
    80003774:	6145                	addi	sp,sp,48
    80003776:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003778:	0009a503          	lw	a0,0(s3)
    8000377c:	fffff097          	auipc	ra,0xfffff
    80003780:	690080e7          	jalr	1680(ra) # 80002e0c <bread>
    80003784:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003786:	05850493          	addi	s1,a0,88
    8000378a:	45850913          	addi	s2,a0,1112
    8000378e:	a811                	j	800037a2 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003790:	0009a503          	lw	a0,0(s3)
    80003794:	00000097          	auipc	ra,0x0
    80003798:	8be080e7          	jalr	-1858(ra) # 80003052 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000379c:	0491                	addi	s1,s1,4
    8000379e:	01248563          	beq	s1,s2,800037a8 <itrunc+0x8c>
      if(a[j])
    800037a2:	408c                	lw	a1,0(s1)
    800037a4:	dde5                	beqz	a1,8000379c <itrunc+0x80>
    800037a6:	b7ed                	j	80003790 <itrunc+0x74>
    brelse(bp);
    800037a8:	8552                	mv	a0,s4
    800037aa:	fffff097          	auipc	ra,0xfffff
    800037ae:	792080e7          	jalr	1938(ra) # 80002f3c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800037b2:	0809a583          	lw	a1,128(s3)
    800037b6:	0009a503          	lw	a0,0(s3)
    800037ba:	00000097          	auipc	ra,0x0
    800037be:	898080e7          	jalr	-1896(ra) # 80003052 <bfree>
    ip->addrs[NDIRECT] = 0;
    800037c2:	0809a023          	sw	zero,128(s3)
    800037c6:	bf51                	j	8000375a <itrunc+0x3e>

00000000800037c8 <iput>:
{
    800037c8:	1101                	addi	sp,sp,-32
    800037ca:	ec06                	sd	ra,24(sp)
    800037cc:	e822                	sd	s0,16(sp)
    800037ce:	e426                	sd	s1,8(sp)
    800037d0:	e04a                	sd	s2,0(sp)
    800037d2:	1000                	addi	s0,sp,32
    800037d4:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800037d6:	0001c517          	auipc	a0,0x1c
    800037da:	fca50513          	addi	a0,a0,-54 # 8001f7a0 <icache>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	43a080e7          	jalr	1082(ra) # 80000c18 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037e6:	4498                	lw	a4,8(s1)
    800037e8:	4785                	li	a5,1
    800037ea:	02f70363          	beq	a4,a5,80003810 <iput+0x48>
  ip->ref--;
    800037ee:	449c                	lw	a5,8(s1)
    800037f0:	37fd                	addiw	a5,a5,-1
    800037f2:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800037f4:	0001c517          	auipc	a0,0x1c
    800037f8:	fac50513          	addi	a0,a0,-84 # 8001f7a0 <icache>
    800037fc:	ffffd097          	auipc	ra,0xffffd
    80003800:	4d0080e7          	jalr	1232(ra) # 80000ccc <release>
}
    80003804:	60e2                	ld	ra,24(sp)
    80003806:	6442                	ld	s0,16(sp)
    80003808:	64a2                	ld	s1,8(sp)
    8000380a:	6902                	ld	s2,0(sp)
    8000380c:	6105                	addi	sp,sp,32
    8000380e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003810:	40bc                	lw	a5,64(s1)
    80003812:	dff1                	beqz	a5,800037ee <iput+0x26>
    80003814:	04a49783          	lh	a5,74(s1)
    80003818:	fbf9                	bnez	a5,800037ee <iput+0x26>
    acquiresleep(&ip->lock);
    8000381a:	01048913          	addi	s2,s1,16
    8000381e:	854a                	mv	a0,s2
    80003820:	00001097          	auipc	ra,0x1
    80003824:	abe080e7          	jalr	-1346(ra) # 800042de <acquiresleep>
    release(&icache.lock);
    80003828:	0001c517          	auipc	a0,0x1c
    8000382c:	f7850513          	addi	a0,a0,-136 # 8001f7a0 <icache>
    80003830:	ffffd097          	auipc	ra,0xffffd
    80003834:	49c080e7          	jalr	1180(ra) # 80000ccc <release>
    itrunc(ip);
    80003838:	8526                	mv	a0,s1
    8000383a:	00000097          	auipc	ra,0x0
    8000383e:	ee2080e7          	jalr	-286(ra) # 8000371c <itrunc>
    ip->type = 0;
    80003842:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003846:	8526                	mv	a0,s1
    80003848:	00000097          	auipc	ra,0x0
    8000384c:	cfc080e7          	jalr	-772(ra) # 80003544 <iupdate>
    ip->valid = 0;
    80003850:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003854:	854a                	mv	a0,s2
    80003856:	00001097          	auipc	ra,0x1
    8000385a:	ade080e7          	jalr	-1314(ra) # 80004334 <releasesleep>
    acquire(&icache.lock);
    8000385e:	0001c517          	auipc	a0,0x1c
    80003862:	f4250513          	addi	a0,a0,-190 # 8001f7a0 <icache>
    80003866:	ffffd097          	auipc	ra,0xffffd
    8000386a:	3b2080e7          	jalr	946(ra) # 80000c18 <acquire>
    8000386e:	b741                	j	800037ee <iput+0x26>

0000000080003870 <iunlockput>:
{
    80003870:	1101                	addi	sp,sp,-32
    80003872:	ec06                	sd	ra,24(sp)
    80003874:	e822                	sd	s0,16(sp)
    80003876:	e426                	sd	s1,8(sp)
    80003878:	1000                	addi	s0,sp,32
    8000387a:	84aa                	mv	s1,a0
  iunlock(ip);
    8000387c:	00000097          	auipc	ra,0x0
    80003880:	e54080e7          	jalr	-428(ra) # 800036d0 <iunlock>
  iput(ip);
    80003884:	8526                	mv	a0,s1
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	f42080e7          	jalr	-190(ra) # 800037c8 <iput>
}
    8000388e:	60e2                	ld	ra,24(sp)
    80003890:	6442                	ld	s0,16(sp)
    80003892:	64a2                	ld	s1,8(sp)
    80003894:	6105                	addi	sp,sp,32
    80003896:	8082                	ret

0000000080003898 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003898:	1141                	addi	sp,sp,-16
    8000389a:	e422                	sd	s0,8(sp)
    8000389c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000389e:	411c                	lw	a5,0(a0)
    800038a0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800038a2:	415c                	lw	a5,4(a0)
    800038a4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800038a6:	04451783          	lh	a5,68(a0)
    800038aa:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800038ae:	04a51783          	lh	a5,74(a0)
    800038b2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800038b6:	04c56783          	lwu	a5,76(a0)
    800038ba:	e99c                	sd	a5,16(a1)
}
    800038bc:	6422                	ld	s0,8(sp)
    800038be:	0141                	addi	sp,sp,16
    800038c0:	8082                	ret

00000000800038c2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800038c2:	457c                	lw	a5,76(a0)
    800038c4:	0ed7e963          	bltu	a5,a3,800039b6 <readi+0xf4>
{
    800038c8:	7159                	addi	sp,sp,-112
    800038ca:	f486                	sd	ra,104(sp)
    800038cc:	f0a2                	sd	s0,96(sp)
    800038ce:	eca6                	sd	s1,88(sp)
    800038d0:	e8ca                	sd	s2,80(sp)
    800038d2:	e4ce                	sd	s3,72(sp)
    800038d4:	e0d2                	sd	s4,64(sp)
    800038d6:	fc56                	sd	s5,56(sp)
    800038d8:	f85a                	sd	s6,48(sp)
    800038da:	f45e                	sd	s7,40(sp)
    800038dc:	f062                	sd	s8,32(sp)
    800038de:	ec66                	sd	s9,24(sp)
    800038e0:	e86a                	sd	s10,16(sp)
    800038e2:	e46e                	sd	s11,8(sp)
    800038e4:	1880                	addi	s0,sp,112
    800038e6:	8baa                	mv	s7,a0
    800038e8:	8c2e                	mv	s8,a1
    800038ea:	8ab2                	mv	s5,a2
    800038ec:	84b6                	mv	s1,a3
    800038ee:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800038f0:	9f35                	addw	a4,a4,a3
    return 0;
    800038f2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800038f4:	0ad76063          	bltu	a4,a3,80003994 <readi+0xd2>
  if(off + n > ip->size)
    800038f8:	00e7f463          	bgeu	a5,a4,80003900 <readi+0x3e>
    n = ip->size - off;
    800038fc:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003900:	0a0b0963          	beqz	s6,800039b2 <readi+0xf0>
    80003904:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003906:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000390a:	5cfd                	li	s9,-1
    8000390c:	a82d                	j	80003946 <readi+0x84>
    8000390e:	020a1d93          	slli	s11,s4,0x20
    80003912:	020ddd93          	srli	s11,s11,0x20
    80003916:	05890613          	addi	a2,s2,88
    8000391a:	86ee                	mv	a3,s11
    8000391c:	963a                	add	a2,a2,a4
    8000391e:	85d6                	mv	a1,s5
    80003920:	8562                	mv	a0,s8
    80003922:	fffff097          	auipc	ra,0xfffff
    80003926:	b2e080e7          	jalr	-1234(ra) # 80002450 <either_copyout>
    8000392a:	05950d63          	beq	a0,s9,80003984 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000392e:	854a                	mv	a0,s2
    80003930:	fffff097          	auipc	ra,0xfffff
    80003934:	60c080e7          	jalr	1548(ra) # 80002f3c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003938:	013a09bb          	addw	s3,s4,s3
    8000393c:	009a04bb          	addw	s1,s4,s1
    80003940:	9aee                	add	s5,s5,s11
    80003942:	0569f763          	bgeu	s3,s6,80003990 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003946:	000ba903          	lw	s2,0(s7)
    8000394a:	00a4d59b          	srliw	a1,s1,0xa
    8000394e:	855e                	mv	a0,s7
    80003950:	00000097          	auipc	ra,0x0
    80003954:	8b0080e7          	jalr	-1872(ra) # 80003200 <bmap>
    80003958:	0005059b          	sext.w	a1,a0
    8000395c:	854a                	mv	a0,s2
    8000395e:	fffff097          	auipc	ra,0xfffff
    80003962:	4ae080e7          	jalr	1198(ra) # 80002e0c <bread>
    80003966:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003968:	3ff4f713          	andi	a4,s1,1023
    8000396c:	40ed07bb          	subw	a5,s10,a4
    80003970:	413b06bb          	subw	a3,s6,s3
    80003974:	8a3e                	mv	s4,a5
    80003976:	2781                	sext.w	a5,a5
    80003978:	0006861b          	sext.w	a2,a3
    8000397c:	f8f679e3          	bgeu	a2,a5,8000390e <readi+0x4c>
    80003980:	8a36                	mv	s4,a3
    80003982:	b771                	j	8000390e <readi+0x4c>
      brelse(bp);
    80003984:	854a                	mv	a0,s2
    80003986:	fffff097          	auipc	ra,0xfffff
    8000398a:	5b6080e7          	jalr	1462(ra) # 80002f3c <brelse>
      tot = -1;
    8000398e:	59fd                	li	s3,-1
  }
  return tot;
    80003990:	0009851b          	sext.w	a0,s3
}
    80003994:	70a6                	ld	ra,104(sp)
    80003996:	7406                	ld	s0,96(sp)
    80003998:	64e6                	ld	s1,88(sp)
    8000399a:	6946                	ld	s2,80(sp)
    8000399c:	69a6                	ld	s3,72(sp)
    8000399e:	6a06                	ld	s4,64(sp)
    800039a0:	7ae2                	ld	s5,56(sp)
    800039a2:	7b42                	ld	s6,48(sp)
    800039a4:	7ba2                	ld	s7,40(sp)
    800039a6:	7c02                	ld	s8,32(sp)
    800039a8:	6ce2                	ld	s9,24(sp)
    800039aa:	6d42                	ld	s10,16(sp)
    800039ac:	6da2                	ld	s11,8(sp)
    800039ae:	6165                	addi	sp,sp,112
    800039b0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039b2:	89da                	mv	s3,s6
    800039b4:	bff1                	j	80003990 <readi+0xce>
    return 0;
    800039b6:	4501                	li	a0,0
}
    800039b8:	8082                	ret

00000000800039ba <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039ba:	457c                	lw	a5,76(a0)
    800039bc:	10d7e763          	bltu	a5,a3,80003aca <writei+0x110>
{
    800039c0:	7159                	addi	sp,sp,-112
    800039c2:	f486                	sd	ra,104(sp)
    800039c4:	f0a2                	sd	s0,96(sp)
    800039c6:	eca6                	sd	s1,88(sp)
    800039c8:	e8ca                	sd	s2,80(sp)
    800039ca:	e4ce                	sd	s3,72(sp)
    800039cc:	e0d2                	sd	s4,64(sp)
    800039ce:	fc56                	sd	s5,56(sp)
    800039d0:	f85a                	sd	s6,48(sp)
    800039d2:	f45e                	sd	s7,40(sp)
    800039d4:	f062                	sd	s8,32(sp)
    800039d6:	ec66                	sd	s9,24(sp)
    800039d8:	e86a                	sd	s10,16(sp)
    800039da:	e46e                	sd	s11,8(sp)
    800039dc:	1880                	addi	s0,sp,112
    800039de:	8baa                	mv	s7,a0
    800039e0:	8c2e                	mv	s8,a1
    800039e2:	8ab2                	mv	s5,a2
    800039e4:	8936                	mv	s2,a3
    800039e6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039e8:	00e687bb          	addw	a5,a3,a4
    800039ec:	0ed7e163          	bltu	a5,a3,80003ace <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800039f0:	00043737          	lui	a4,0x43
    800039f4:	0cf76f63          	bltu	a4,a5,80003ad2 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800039f8:	0a0b0863          	beqz	s6,80003aa8 <writei+0xee>
    800039fc:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039fe:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a02:	5cfd                	li	s9,-1
    80003a04:	a091                	j	80003a48 <writei+0x8e>
    80003a06:	02099d93          	slli	s11,s3,0x20
    80003a0a:	020ddd93          	srli	s11,s11,0x20
    80003a0e:	05848513          	addi	a0,s1,88
    80003a12:	86ee                	mv	a3,s11
    80003a14:	8656                	mv	a2,s5
    80003a16:	85e2                	mv	a1,s8
    80003a18:	953a                	add	a0,a0,a4
    80003a1a:	fffff097          	auipc	ra,0xfffff
    80003a1e:	a8c080e7          	jalr	-1396(ra) # 800024a6 <either_copyin>
    80003a22:	07950263          	beq	a0,s9,80003a86 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003a26:	8526                	mv	a0,s1
    80003a28:	00000097          	auipc	ra,0x0
    80003a2c:	78e080e7          	jalr	1934(ra) # 800041b6 <log_write>
    brelse(bp);
    80003a30:	8526                	mv	a0,s1
    80003a32:	fffff097          	auipc	ra,0xfffff
    80003a36:	50a080e7          	jalr	1290(ra) # 80002f3c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a3a:	01498a3b          	addw	s4,s3,s4
    80003a3e:	0129893b          	addw	s2,s3,s2
    80003a42:	9aee                	add	s5,s5,s11
    80003a44:	056a7763          	bgeu	s4,s6,80003a92 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a48:	000ba483          	lw	s1,0(s7)
    80003a4c:	00a9559b          	srliw	a1,s2,0xa
    80003a50:	855e                	mv	a0,s7
    80003a52:	fffff097          	auipc	ra,0xfffff
    80003a56:	7ae080e7          	jalr	1966(ra) # 80003200 <bmap>
    80003a5a:	0005059b          	sext.w	a1,a0
    80003a5e:	8526                	mv	a0,s1
    80003a60:	fffff097          	auipc	ra,0xfffff
    80003a64:	3ac080e7          	jalr	940(ra) # 80002e0c <bread>
    80003a68:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a6a:	3ff97713          	andi	a4,s2,1023
    80003a6e:	40ed07bb          	subw	a5,s10,a4
    80003a72:	414b06bb          	subw	a3,s6,s4
    80003a76:	89be                	mv	s3,a5
    80003a78:	2781                	sext.w	a5,a5
    80003a7a:	0006861b          	sext.w	a2,a3
    80003a7e:	f8f674e3          	bgeu	a2,a5,80003a06 <writei+0x4c>
    80003a82:	89b6                	mv	s3,a3
    80003a84:	b749                	j	80003a06 <writei+0x4c>
      brelse(bp);
    80003a86:	8526                	mv	a0,s1
    80003a88:	fffff097          	auipc	ra,0xfffff
    80003a8c:	4b4080e7          	jalr	1204(ra) # 80002f3c <brelse>
      n = -1;
    80003a90:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003a92:	04cba783          	lw	a5,76(s7)
    80003a96:	0127f463          	bgeu	a5,s2,80003a9e <writei+0xe4>
      ip->size = off;
    80003a9a:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003a9e:	855e                	mv	a0,s7
    80003aa0:	00000097          	auipc	ra,0x0
    80003aa4:	aa4080e7          	jalr	-1372(ra) # 80003544 <iupdate>
  }

  return n;
    80003aa8:	000b051b          	sext.w	a0,s6
}
    80003aac:	70a6                	ld	ra,104(sp)
    80003aae:	7406                	ld	s0,96(sp)
    80003ab0:	64e6                	ld	s1,88(sp)
    80003ab2:	6946                	ld	s2,80(sp)
    80003ab4:	69a6                	ld	s3,72(sp)
    80003ab6:	6a06                	ld	s4,64(sp)
    80003ab8:	7ae2                	ld	s5,56(sp)
    80003aba:	7b42                	ld	s6,48(sp)
    80003abc:	7ba2                	ld	s7,40(sp)
    80003abe:	7c02                	ld	s8,32(sp)
    80003ac0:	6ce2                	ld	s9,24(sp)
    80003ac2:	6d42                	ld	s10,16(sp)
    80003ac4:	6da2                	ld	s11,8(sp)
    80003ac6:	6165                	addi	sp,sp,112
    80003ac8:	8082                	ret
    return -1;
    80003aca:	557d                	li	a0,-1
}
    80003acc:	8082                	ret
    return -1;
    80003ace:	557d                	li	a0,-1
    80003ad0:	bff1                	j	80003aac <writei+0xf2>
    return -1;
    80003ad2:	557d                	li	a0,-1
    80003ad4:	bfe1                	j	80003aac <writei+0xf2>

0000000080003ad6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ad6:	1141                	addi	sp,sp,-16
    80003ad8:	e406                	sd	ra,8(sp)
    80003ada:	e022                	sd	s0,0(sp)
    80003adc:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ade:	4639                	li	a2,14
    80003ae0:	ffffd097          	auipc	ra,0xffffd
    80003ae4:	310080e7          	jalr	784(ra) # 80000df0 <strncmp>
}
    80003ae8:	60a2                	ld	ra,8(sp)
    80003aea:	6402                	ld	s0,0(sp)
    80003aec:	0141                	addi	sp,sp,16
    80003aee:	8082                	ret

0000000080003af0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003af0:	7139                	addi	sp,sp,-64
    80003af2:	fc06                	sd	ra,56(sp)
    80003af4:	f822                	sd	s0,48(sp)
    80003af6:	f426                	sd	s1,40(sp)
    80003af8:	f04a                	sd	s2,32(sp)
    80003afa:	ec4e                	sd	s3,24(sp)
    80003afc:	e852                	sd	s4,16(sp)
    80003afe:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b00:	04451703          	lh	a4,68(a0)
    80003b04:	4785                	li	a5,1
    80003b06:	00f71a63          	bne	a4,a5,80003b1a <dirlookup+0x2a>
    80003b0a:	892a                	mv	s2,a0
    80003b0c:	89ae                	mv	s3,a1
    80003b0e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b10:	457c                	lw	a5,76(a0)
    80003b12:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b14:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b16:	e79d                	bnez	a5,80003b44 <dirlookup+0x54>
    80003b18:	a8a5                	j	80003b90 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b1a:	00005517          	auipc	a0,0x5
    80003b1e:	aa650513          	addi	a0,a0,-1370 # 800085c0 <syscalls+0x1a0>
    80003b22:	ffffd097          	auipc	ra,0xffffd
    80003b26:	a2e080e7          	jalr	-1490(ra) # 80000550 <panic>
      panic("dirlookup read");
    80003b2a:	00005517          	auipc	a0,0x5
    80003b2e:	aae50513          	addi	a0,a0,-1362 # 800085d8 <syscalls+0x1b8>
    80003b32:	ffffd097          	auipc	ra,0xffffd
    80003b36:	a1e080e7          	jalr	-1506(ra) # 80000550 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b3a:	24c1                	addiw	s1,s1,16
    80003b3c:	04c92783          	lw	a5,76(s2)
    80003b40:	04f4f763          	bgeu	s1,a5,80003b8e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b44:	4741                	li	a4,16
    80003b46:	86a6                	mv	a3,s1
    80003b48:	fc040613          	addi	a2,s0,-64
    80003b4c:	4581                	li	a1,0
    80003b4e:	854a                	mv	a0,s2
    80003b50:	00000097          	auipc	ra,0x0
    80003b54:	d72080e7          	jalr	-654(ra) # 800038c2 <readi>
    80003b58:	47c1                	li	a5,16
    80003b5a:	fcf518e3          	bne	a0,a5,80003b2a <dirlookup+0x3a>
    if(de.inum == 0)
    80003b5e:	fc045783          	lhu	a5,-64(s0)
    80003b62:	dfe1                	beqz	a5,80003b3a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003b64:	fc240593          	addi	a1,s0,-62
    80003b68:	854e                	mv	a0,s3
    80003b6a:	00000097          	auipc	ra,0x0
    80003b6e:	f6c080e7          	jalr	-148(ra) # 80003ad6 <namecmp>
    80003b72:	f561                	bnez	a0,80003b3a <dirlookup+0x4a>
      if(poff)
    80003b74:	000a0463          	beqz	s4,80003b7c <dirlookup+0x8c>
        *poff = off;
    80003b78:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003b7c:	fc045583          	lhu	a1,-64(s0)
    80003b80:	00092503          	lw	a0,0(s2)
    80003b84:	fffff097          	auipc	ra,0xfffff
    80003b88:	756080e7          	jalr	1878(ra) # 800032da <iget>
    80003b8c:	a011                	j	80003b90 <dirlookup+0xa0>
  return 0;
    80003b8e:	4501                	li	a0,0
}
    80003b90:	70e2                	ld	ra,56(sp)
    80003b92:	7442                	ld	s0,48(sp)
    80003b94:	74a2                	ld	s1,40(sp)
    80003b96:	7902                	ld	s2,32(sp)
    80003b98:	69e2                	ld	s3,24(sp)
    80003b9a:	6a42                	ld	s4,16(sp)
    80003b9c:	6121                	addi	sp,sp,64
    80003b9e:	8082                	ret

0000000080003ba0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ba0:	711d                	addi	sp,sp,-96
    80003ba2:	ec86                	sd	ra,88(sp)
    80003ba4:	e8a2                	sd	s0,80(sp)
    80003ba6:	e4a6                	sd	s1,72(sp)
    80003ba8:	e0ca                	sd	s2,64(sp)
    80003baa:	fc4e                	sd	s3,56(sp)
    80003bac:	f852                	sd	s4,48(sp)
    80003bae:	f456                	sd	s5,40(sp)
    80003bb0:	f05a                	sd	s6,32(sp)
    80003bb2:	ec5e                	sd	s7,24(sp)
    80003bb4:	e862                	sd	s8,16(sp)
    80003bb6:	e466                	sd	s9,8(sp)
    80003bb8:	1080                	addi	s0,sp,96
    80003bba:	84aa                	mv	s1,a0
    80003bbc:	8b2e                	mv	s6,a1
    80003bbe:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003bc0:	00054703          	lbu	a4,0(a0)
    80003bc4:	02f00793          	li	a5,47
    80003bc8:	02f70363          	beq	a4,a5,80003bee <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003bcc:	ffffe097          	auipc	ra,0xffffe
    80003bd0:	e36080e7          	jalr	-458(ra) # 80001a02 <myproc>
    80003bd4:	15053503          	ld	a0,336(a0)
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	9f8080e7          	jalr	-1544(ra) # 800035d0 <idup>
    80003be0:	89aa                	mv	s3,a0
  while(*path == '/')
    80003be2:	02f00913          	li	s2,47
  len = path - s;
    80003be6:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003be8:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003bea:	4c05                	li	s8,1
    80003bec:	a865                	j	80003ca4 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003bee:	4585                	li	a1,1
    80003bf0:	4505                	li	a0,1
    80003bf2:	fffff097          	auipc	ra,0xfffff
    80003bf6:	6e8080e7          	jalr	1768(ra) # 800032da <iget>
    80003bfa:	89aa                	mv	s3,a0
    80003bfc:	b7dd                	j	80003be2 <namex+0x42>
      iunlockput(ip);
    80003bfe:	854e                	mv	a0,s3
    80003c00:	00000097          	auipc	ra,0x0
    80003c04:	c70080e7          	jalr	-912(ra) # 80003870 <iunlockput>
      return 0;
    80003c08:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c0a:	854e                	mv	a0,s3
    80003c0c:	60e6                	ld	ra,88(sp)
    80003c0e:	6446                	ld	s0,80(sp)
    80003c10:	64a6                	ld	s1,72(sp)
    80003c12:	6906                	ld	s2,64(sp)
    80003c14:	79e2                	ld	s3,56(sp)
    80003c16:	7a42                	ld	s4,48(sp)
    80003c18:	7aa2                	ld	s5,40(sp)
    80003c1a:	7b02                	ld	s6,32(sp)
    80003c1c:	6be2                	ld	s7,24(sp)
    80003c1e:	6c42                	ld	s8,16(sp)
    80003c20:	6ca2                	ld	s9,8(sp)
    80003c22:	6125                	addi	sp,sp,96
    80003c24:	8082                	ret
      iunlock(ip);
    80003c26:	854e                	mv	a0,s3
    80003c28:	00000097          	auipc	ra,0x0
    80003c2c:	aa8080e7          	jalr	-1368(ra) # 800036d0 <iunlock>
      return ip;
    80003c30:	bfe9                	j	80003c0a <namex+0x6a>
      iunlockput(ip);
    80003c32:	854e                	mv	a0,s3
    80003c34:	00000097          	auipc	ra,0x0
    80003c38:	c3c080e7          	jalr	-964(ra) # 80003870 <iunlockput>
      return 0;
    80003c3c:	89d2                	mv	s3,s4
    80003c3e:	b7f1                	j	80003c0a <namex+0x6a>
  len = path - s;
    80003c40:	40b48633          	sub	a2,s1,a1
    80003c44:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003c48:	094cd463          	bge	s9,s4,80003cd0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003c4c:	4639                	li	a2,14
    80003c4e:	8556                	mv	a0,s5
    80003c50:	ffffd097          	auipc	ra,0xffffd
    80003c54:	124080e7          	jalr	292(ra) # 80000d74 <memmove>
  while(*path == '/')
    80003c58:	0004c783          	lbu	a5,0(s1)
    80003c5c:	01279763          	bne	a5,s2,80003c6a <namex+0xca>
    path++;
    80003c60:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c62:	0004c783          	lbu	a5,0(s1)
    80003c66:	ff278de3          	beq	a5,s2,80003c60 <namex+0xc0>
    ilock(ip);
    80003c6a:	854e                	mv	a0,s3
    80003c6c:	00000097          	auipc	ra,0x0
    80003c70:	9a2080e7          	jalr	-1630(ra) # 8000360e <ilock>
    if(ip->type != T_DIR){
    80003c74:	04499783          	lh	a5,68(s3)
    80003c78:	f98793e3          	bne	a5,s8,80003bfe <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003c7c:	000b0563          	beqz	s6,80003c86 <namex+0xe6>
    80003c80:	0004c783          	lbu	a5,0(s1)
    80003c84:	d3cd                	beqz	a5,80003c26 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003c86:	865e                	mv	a2,s7
    80003c88:	85d6                	mv	a1,s5
    80003c8a:	854e                	mv	a0,s3
    80003c8c:	00000097          	auipc	ra,0x0
    80003c90:	e64080e7          	jalr	-412(ra) # 80003af0 <dirlookup>
    80003c94:	8a2a                	mv	s4,a0
    80003c96:	dd51                	beqz	a0,80003c32 <namex+0x92>
    iunlockput(ip);
    80003c98:	854e                	mv	a0,s3
    80003c9a:	00000097          	auipc	ra,0x0
    80003c9e:	bd6080e7          	jalr	-1066(ra) # 80003870 <iunlockput>
    ip = next;
    80003ca2:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ca4:	0004c783          	lbu	a5,0(s1)
    80003ca8:	05279763          	bne	a5,s2,80003cf6 <namex+0x156>
    path++;
    80003cac:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cae:	0004c783          	lbu	a5,0(s1)
    80003cb2:	ff278de3          	beq	a5,s2,80003cac <namex+0x10c>
  if(*path == 0)
    80003cb6:	c79d                	beqz	a5,80003ce4 <namex+0x144>
    path++;
    80003cb8:	85a6                	mv	a1,s1
  len = path - s;
    80003cba:	8a5e                	mv	s4,s7
    80003cbc:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003cbe:	01278963          	beq	a5,s2,80003cd0 <namex+0x130>
    80003cc2:	dfbd                	beqz	a5,80003c40 <namex+0xa0>
    path++;
    80003cc4:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003cc6:	0004c783          	lbu	a5,0(s1)
    80003cca:	ff279ce3          	bne	a5,s2,80003cc2 <namex+0x122>
    80003cce:	bf8d                	j	80003c40 <namex+0xa0>
    memmove(name, s, len);
    80003cd0:	2601                	sext.w	a2,a2
    80003cd2:	8556                	mv	a0,s5
    80003cd4:	ffffd097          	auipc	ra,0xffffd
    80003cd8:	0a0080e7          	jalr	160(ra) # 80000d74 <memmove>
    name[len] = 0;
    80003cdc:	9a56                	add	s4,s4,s5
    80003cde:	000a0023          	sb	zero,0(s4)
    80003ce2:	bf9d                	j	80003c58 <namex+0xb8>
  if(nameiparent){
    80003ce4:	f20b03e3          	beqz	s6,80003c0a <namex+0x6a>
    iput(ip);
    80003ce8:	854e                	mv	a0,s3
    80003cea:	00000097          	auipc	ra,0x0
    80003cee:	ade080e7          	jalr	-1314(ra) # 800037c8 <iput>
    return 0;
    80003cf2:	4981                	li	s3,0
    80003cf4:	bf19                	j	80003c0a <namex+0x6a>
  if(*path == 0)
    80003cf6:	d7fd                	beqz	a5,80003ce4 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003cf8:	0004c783          	lbu	a5,0(s1)
    80003cfc:	85a6                	mv	a1,s1
    80003cfe:	b7d1                	j	80003cc2 <namex+0x122>

0000000080003d00 <dirlink>:
{
    80003d00:	7139                	addi	sp,sp,-64
    80003d02:	fc06                	sd	ra,56(sp)
    80003d04:	f822                	sd	s0,48(sp)
    80003d06:	f426                	sd	s1,40(sp)
    80003d08:	f04a                	sd	s2,32(sp)
    80003d0a:	ec4e                	sd	s3,24(sp)
    80003d0c:	e852                	sd	s4,16(sp)
    80003d0e:	0080                	addi	s0,sp,64
    80003d10:	892a                	mv	s2,a0
    80003d12:	8a2e                	mv	s4,a1
    80003d14:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d16:	4601                	li	a2,0
    80003d18:	00000097          	auipc	ra,0x0
    80003d1c:	dd8080e7          	jalr	-552(ra) # 80003af0 <dirlookup>
    80003d20:	e93d                	bnez	a0,80003d96 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d22:	04c92483          	lw	s1,76(s2)
    80003d26:	c49d                	beqz	s1,80003d54 <dirlink+0x54>
    80003d28:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d2a:	4741                	li	a4,16
    80003d2c:	86a6                	mv	a3,s1
    80003d2e:	fc040613          	addi	a2,s0,-64
    80003d32:	4581                	li	a1,0
    80003d34:	854a                	mv	a0,s2
    80003d36:	00000097          	auipc	ra,0x0
    80003d3a:	b8c080e7          	jalr	-1140(ra) # 800038c2 <readi>
    80003d3e:	47c1                	li	a5,16
    80003d40:	06f51163          	bne	a0,a5,80003da2 <dirlink+0xa2>
    if(de.inum == 0)
    80003d44:	fc045783          	lhu	a5,-64(s0)
    80003d48:	c791                	beqz	a5,80003d54 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d4a:	24c1                	addiw	s1,s1,16
    80003d4c:	04c92783          	lw	a5,76(s2)
    80003d50:	fcf4ede3          	bltu	s1,a5,80003d2a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d54:	4639                	li	a2,14
    80003d56:	85d2                	mv	a1,s4
    80003d58:	fc240513          	addi	a0,s0,-62
    80003d5c:	ffffd097          	auipc	ra,0xffffd
    80003d60:	0d0080e7          	jalr	208(ra) # 80000e2c <strncpy>
  de.inum = inum;
    80003d64:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d68:	4741                	li	a4,16
    80003d6a:	86a6                	mv	a3,s1
    80003d6c:	fc040613          	addi	a2,s0,-64
    80003d70:	4581                	li	a1,0
    80003d72:	854a                	mv	a0,s2
    80003d74:	00000097          	auipc	ra,0x0
    80003d78:	c46080e7          	jalr	-954(ra) # 800039ba <writei>
    80003d7c:	872a                	mv	a4,a0
    80003d7e:	47c1                	li	a5,16
  return 0;
    80003d80:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d82:	02f71863          	bne	a4,a5,80003db2 <dirlink+0xb2>
}
    80003d86:	70e2                	ld	ra,56(sp)
    80003d88:	7442                	ld	s0,48(sp)
    80003d8a:	74a2                	ld	s1,40(sp)
    80003d8c:	7902                	ld	s2,32(sp)
    80003d8e:	69e2                	ld	s3,24(sp)
    80003d90:	6a42                	ld	s4,16(sp)
    80003d92:	6121                	addi	sp,sp,64
    80003d94:	8082                	ret
    iput(ip);
    80003d96:	00000097          	auipc	ra,0x0
    80003d9a:	a32080e7          	jalr	-1486(ra) # 800037c8 <iput>
    return -1;
    80003d9e:	557d                	li	a0,-1
    80003da0:	b7dd                	j	80003d86 <dirlink+0x86>
      panic("dirlink read");
    80003da2:	00005517          	auipc	a0,0x5
    80003da6:	84650513          	addi	a0,a0,-1978 # 800085e8 <syscalls+0x1c8>
    80003daa:	ffffc097          	auipc	ra,0xffffc
    80003dae:	7a6080e7          	jalr	1958(ra) # 80000550 <panic>
    panic("dirlink");
    80003db2:	00005517          	auipc	a0,0x5
    80003db6:	95650513          	addi	a0,a0,-1706 # 80008708 <syscalls+0x2e8>
    80003dba:	ffffc097          	auipc	ra,0xffffc
    80003dbe:	796080e7          	jalr	1942(ra) # 80000550 <panic>

0000000080003dc2 <namei>:

struct inode*
namei(char *path)
{
    80003dc2:	1101                	addi	sp,sp,-32
    80003dc4:	ec06                	sd	ra,24(sp)
    80003dc6:	e822                	sd	s0,16(sp)
    80003dc8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003dca:	fe040613          	addi	a2,s0,-32
    80003dce:	4581                	li	a1,0
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	dd0080e7          	jalr	-560(ra) # 80003ba0 <namex>
}
    80003dd8:	60e2                	ld	ra,24(sp)
    80003dda:	6442                	ld	s0,16(sp)
    80003ddc:	6105                	addi	sp,sp,32
    80003dde:	8082                	ret

0000000080003de0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003de0:	1141                	addi	sp,sp,-16
    80003de2:	e406                	sd	ra,8(sp)
    80003de4:	e022                	sd	s0,0(sp)
    80003de6:	0800                	addi	s0,sp,16
    80003de8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003dea:	4585                	li	a1,1
    80003dec:	00000097          	auipc	ra,0x0
    80003df0:	db4080e7          	jalr	-588(ra) # 80003ba0 <namex>
}
    80003df4:	60a2                	ld	ra,8(sp)
    80003df6:	6402                	ld	s0,0(sp)
    80003df8:	0141                	addi	sp,sp,16
    80003dfa:	8082                	ret

0000000080003dfc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003dfc:	1101                	addi	sp,sp,-32
    80003dfe:	ec06                	sd	ra,24(sp)
    80003e00:	e822                	sd	s0,16(sp)
    80003e02:	e426                	sd	s1,8(sp)
    80003e04:	e04a                	sd	s2,0(sp)
    80003e06:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e08:	0001d917          	auipc	s2,0x1d
    80003e0c:	44090913          	addi	s2,s2,1088 # 80021248 <log>
    80003e10:	01892583          	lw	a1,24(s2)
    80003e14:	02892503          	lw	a0,40(s2)
    80003e18:	fffff097          	auipc	ra,0xfffff
    80003e1c:	ff4080e7          	jalr	-12(ra) # 80002e0c <bread>
    80003e20:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e22:	02c92683          	lw	a3,44(s2)
    80003e26:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e28:	02d05763          	blez	a3,80003e56 <write_head+0x5a>
    80003e2c:	0001d797          	auipc	a5,0x1d
    80003e30:	44c78793          	addi	a5,a5,1100 # 80021278 <log+0x30>
    80003e34:	05c50713          	addi	a4,a0,92
    80003e38:	36fd                	addiw	a3,a3,-1
    80003e3a:	1682                	slli	a3,a3,0x20
    80003e3c:	9281                	srli	a3,a3,0x20
    80003e3e:	068a                	slli	a3,a3,0x2
    80003e40:	0001d617          	auipc	a2,0x1d
    80003e44:	43c60613          	addi	a2,a2,1084 # 8002127c <log+0x34>
    80003e48:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e4a:	4390                	lw	a2,0(a5)
    80003e4c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e4e:	0791                	addi	a5,a5,4
    80003e50:	0711                	addi	a4,a4,4
    80003e52:	fed79ce3          	bne	a5,a3,80003e4a <write_head+0x4e>
  }
  bwrite(buf);
    80003e56:	8526                	mv	a0,s1
    80003e58:	fffff097          	auipc	ra,0xfffff
    80003e5c:	0a6080e7          	jalr	166(ra) # 80002efe <bwrite>
  brelse(buf);
    80003e60:	8526                	mv	a0,s1
    80003e62:	fffff097          	auipc	ra,0xfffff
    80003e66:	0da080e7          	jalr	218(ra) # 80002f3c <brelse>
}
    80003e6a:	60e2                	ld	ra,24(sp)
    80003e6c:	6442                	ld	s0,16(sp)
    80003e6e:	64a2                	ld	s1,8(sp)
    80003e70:	6902                	ld	s2,0(sp)
    80003e72:	6105                	addi	sp,sp,32
    80003e74:	8082                	ret

0000000080003e76 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e76:	0001d797          	auipc	a5,0x1d
    80003e7a:	3fe7a783          	lw	a5,1022(a5) # 80021274 <log+0x2c>
    80003e7e:	0af05d63          	blez	a5,80003f38 <install_trans+0xc2>
{
    80003e82:	7139                	addi	sp,sp,-64
    80003e84:	fc06                	sd	ra,56(sp)
    80003e86:	f822                	sd	s0,48(sp)
    80003e88:	f426                	sd	s1,40(sp)
    80003e8a:	f04a                	sd	s2,32(sp)
    80003e8c:	ec4e                	sd	s3,24(sp)
    80003e8e:	e852                	sd	s4,16(sp)
    80003e90:	e456                	sd	s5,8(sp)
    80003e92:	e05a                	sd	s6,0(sp)
    80003e94:	0080                	addi	s0,sp,64
    80003e96:	8b2a                	mv	s6,a0
    80003e98:	0001da97          	auipc	s5,0x1d
    80003e9c:	3e0a8a93          	addi	s5,s5,992 # 80021278 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ea0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003ea2:	0001d997          	auipc	s3,0x1d
    80003ea6:	3a698993          	addi	s3,s3,934 # 80021248 <log>
    80003eaa:	a035                	j	80003ed6 <install_trans+0x60>
      bunpin(dbuf);
    80003eac:	8526                	mv	a0,s1
    80003eae:	fffff097          	auipc	ra,0xfffff
    80003eb2:	168080e7          	jalr	360(ra) # 80003016 <bunpin>
    brelse(lbuf);
    80003eb6:	854a                	mv	a0,s2
    80003eb8:	fffff097          	auipc	ra,0xfffff
    80003ebc:	084080e7          	jalr	132(ra) # 80002f3c <brelse>
    brelse(dbuf);
    80003ec0:	8526                	mv	a0,s1
    80003ec2:	fffff097          	auipc	ra,0xfffff
    80003ec6:	07a080e7          	jalr	122(ra) # 80002f3c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003eca:	2a05                	addiw	s4,s4,1
    80003ecc:	0a91                	addi	s5,s5,4
    80003ece:	02c9a783          	lw	a5,44(s3)
    80003ed2:	04fa5963          	bge	s4,a5,80003f24 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003ed6:	0189a583          	lw	a1,24(s3)
    80003eda:	014585bb          	addw	a1,a1,s4
    80003ede:	2585                	addiw	a1,a1,1
    80003ee0:	0289a503          	lw	a0,40(s3)
    80003ee4:	fffff097          	auipc	ra,0xfffff
    80003ee8:	f28080e7          	jalr	-216(ra) # 80002e0c <bread>
    80003eec:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003eee:	000aa583          	lw	a1,0(s5)
    80003ef2:	0289a503          	lw	a0,40(s3)
    80003ef6:	fffff097          	auipc	ra,0xfffff
    80003efa:	f16080e7          	jalr	-234(ra) # 80002e0c <bread>
    80003efe:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f00:	40000613          	li	a2,1024
    80003f04:	05890593          	addi	a1,s2,88
    80003f08:	05850513          	addi	a0,a0,88
    80003f0c:	ffffd097          	auipc	ra,0xffffd
    80003f10:	e68080e7          	jalr	-408(ra) # 80000d74 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f14:	8526                	mv	a0,s1
    80003f16:	fffff097          	auipc	ra,0xfffff
    80003f1a:	fe8080e7          	jalr	-24(ra) # 80002efe <bwrite>
    if(recovering == 0)
    80003f1e:	f80b1ce3          	bnez	s6,80003eb6 <install_trans+0x40>
    80003f22:	b769                	j	80003eac <install_trans+0x36>
}
    80003f24:	70e2                	ld	ra,56(sp)
    80003f26:	7442                	ld	s0,48(sp)
    80003f28:	74a2                	ld	s1,40(sp)
    80003f2a:	7902                	ld	s2,32(sp)
    80003f2c:	69e2                	ld	s3,24(sp)
    80003f2e:	6a42                	ld	s4,16(sp)
    80003f30:	6aa2                	ld	s5,8(sp)
    80003f32:	6b02                	ld	s6,0(sp)
    80003f34:	6121                	addi	sp,sp,64
    80003f36:	8082                	ret
    80003f38:	8082                	ret

0000000080003f3a <initlog>:
{
    80003f3a:	7179                	addi	sp,sp,-48
    80003f3c:	f406                	sd	ra,40(sp)
    80003f3e:	f022                	sd	s0,32(sp)
    80003f40:	ec26                	sd	s1,24(sp)
    80003f42:	e84a                	sd	s2,16(sp)
    80003f44:	e44e                	sd	s3,8(sp)
    80003f46:	1800                	addi	s0,sp,48
    80003f48:	892a                	mv	s2,a0
    80003f4a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f4c:	0001d497          	auipc	s1,0x1d
    80003f50:	2fc48493          	addi	s1,s1,764 # 80021248 <log>
    80003f54:	00004597          	auipc	a1,0x4
    80003f58:	6a458593          	addi	a1,a1,1700 # 800085f8 <syscalls+0x1d8>
    80003f5c:	8526                	mv	a0,s1
    80003f5e:	ffffd097          	auipc	ra,0xffffd
    80003f62:	c2a080e7          	jalr	-982(ra) # 80000b88 <initlock>
  log.start = sb->logstart;
    80003f66:	0149a583          	lw	a1,20(s3)
    80003f6a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003f6c:	0109a783          	lw	a5,16(s3)
    80003f70:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003f72:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003f76:	854a                	mv	a0,s2
    80003f78:	fffff097          	auipc	ra,0xfffff
    80003f7c:	e94080e7          	jalr	-364(ra) # 80002e0c <bread>
  log.lh.n = lh->n;
    80003f80:	4d3c                	lw	a5,88(a0)
    80003f82:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003f84:	02f05563          	blez	a5,80003fae <initlog+0x74>
    80003f88:	05c50713          	addi	a4,a0,92
    80003f8c:	0001d697          	auipc	a3,0x1d
    80003f90:	2ec68693          	addi	a3,a3,748 # 80021278 <log+0x30>
    80003f94:	37fd                	addiw	a5,a5,-1
    80003f96:	1782                	slli	a5,a5,0x20
    80003f98:	9381                	srli	a5,a5,0x20
    80003f9a:	078a                	slli	a5,a5,0x2
    80003f9c:	06050613          	addi	a2,a0,96
    80003fa0:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80003fa2:	4310                	lw	a2,0(a4)
    80003fa4:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80003fa6:	0711                	addi	a4,a4,4
    80003fa8:	0691                	addi	a3,a3,4
    80003faa:	fef71ce3          	bne	a4,a5,80003fa2 <initlog+0x68>
  brelse(buf);
    80003fae:	fffff097          	auipc	ra,0xfffff
    80003fb2:	f8e080e7          	jalr	-114(ra) # 80002f3c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003fb6:	4505                	li	a0,1
    80003fb8:	00000097          	auipc	ra,0x0
    80003fbc:	ebe080e7          	jalr	-322(ra) # 80003e76 <install_trans>
  log.lh.n = 0;
    80003fc0:	0001d797          	auipc	a5,0x1d
    80003fc4:	2a07aa23          	sw	zero,692(a5) # 80021274 <log+0x2c>
  write_head(); // clear the log
    80003fc8:	00000097          	auipc	ra,0x0
    80003fcc:	e34080e7          	jalr	-460(ra) # 80003dfc <write_head>
}
    80003fd0:	70a2                	ld	ra,40(sp)
    80003fd2:	7402                	ld	s0,32(sp)
    80003fd4:	64e2                	ld	s1,24(sp)
    80003fd6:	6942                	ld	s2,16(sp)
    80003fd8:	69a2                	ld	s3,8(sp)
    80003fda:	6145                	addi	sp,sp,48
    80003fdc:	8082                	ret

0000000080003fde <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003fde:	1101                	addi	sp,sp,-32
    80003fe0:	ec06                	sd	ra,24(sp)
    80003fe2:	e822                	sd	s0,16(sp)
    80003fe4:	e426                	sd	s1,8(sp)
    80003fe6:	e04a                	sd	s2,0(sp)
    80003fe8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003fea:	0001d517          	auipc	a0,0x1d
    80003fee:	25e50513          	addi	a0,a0,606 # 80021248 <log>
    80003ff2:	ffffd097          	auipc	ra,0xffffd
    80003ff6:	c26080e7          	jalr	-986(ra) # 80000c18 <acquire>
  while(1){
    if(log.committing){
    80003ffa:	0001d497          	auipc	s1,0x1d
    80003ffe:	24e48493          	addi	s1,s1,590 # 80021248 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004002:	4979                	li	s2,30
    80004004:	a039                	j	80004012 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004006:	85a6                	mv	a1,s1
    80004008:	8526                	mv	a0,s1
    8000400a:	ffffe097          	auipc	ra,0xffffe
    8000400e:	1e4080e7          	jalr	484(ra) # 800021ee <sleep>
    if(log.committing){
    80004012:	50dc                	lw	a5,36(s1)
    80004014:	fbed                	bnez	a5,80004006 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004016:	509c                	lw	a5,32(s1)
    80004018:	0017871b          	addiw	a4,a5,1
    8000401c:	0007069b          	sext.w	a3,a4
    80004020:	0027179b          	slliw	a5,a4,0x2
    80004024:	9fb9                	addw	a5,a5,a4
    80004026:	0017979b          	slliw	a5,a5,0x1
    8000402a:	54d8                	lw	a4,44(s1)
    8000402c:	9fb9                	addw	a5,a5,a4
    8000402e:	00f95963          	bge	s2,a5,80004040 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004032:	85a6                	mv	a1,s1
    80004034:	8526                	mv	a0,s1
    80004036:	ffffe097          	auipc	ra,0xffffe
    8000403a:	1b8080e7          	jalr	440(ra) # 800021ee <sleep>
    8000403e:	bfd1                	j	80004012 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004040:	0001d517          	auipc	a0,0x1d
    80004044:	20850513          	addi	a0,a0,520 # 80021248 <log>
    80004048:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000404a:	ffffd097          	auipc	ra,0xffffd
    8000404e:	c82080e7          	jalr	-894(ra) # 80000ccc <release>
      break;
    }
  }
}
    80004052:	60e2                	ld	ra,24(sp)
    80004054:	6442                	ld	s0,16(sp)
    80004056:	64a2                	ld	s1,8(sp)
    80004058:	6902                	ld	s2,0(sp)
    8000405a:	6105                	addi	sp,sp,32
    8000405c:	8082                	ret

000000008000405e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000405e:	7139                	addi	sp,sp,-64
    80004060:	fc06                	sd	ra,56(sp)
    80004062:	f822                	sd	s0,48(sp)
    80004064:	f426                	sd	s1,40(sp)
    80004066:	f04a                	sd	s2,32(sp)
    80004068:	ec4e                	sd	s3,24(sp)
    8000406a:	e852                	sd	s4,16(sp)
    8000406c:	e456                	sd	s5,8(sp)
    8000406e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004070:	0001d497          	auipc	s1,0x1d
    80004074:	1d848493          	addi	s1,s1,472 # 80021248 <log>
    80004078:	8526                	mv	a0,s1
    8000407a:	ffffd097          	auipc	ra,0xffffd
    8000407e:	b9e080e7          	jalr	-1122(ra) # 80000c18 <acquire>
  log.outstanding -= 1;
    80004082:	509c                	lw	a5,32(s1)
    80004084:	37fd                	addiw	a5,a5,-1
    80004086:	0007891b          	sext.w	s2,a5
    8000408a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000408c:	50dc                	lw	a5,36(s1)
    8000408e:	efb9                	bnez	a5,800040ec <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004090:	06091663          	bnez	s2,800040fc <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004094:	0001d497          	auipc	s1,0x1d
    80004098:	1b448493          	addi	s1,s1,436 # 80021248 <log>
    8000409c:	4785                	li	a5,1
    8000409e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800040a0:	8526                	mv	a0,s1
    800040a2:	ffffd097          	auipc	ra,0xffffd
    800040a6:	c2a080e7          	jalr	-982(ra) # 80000ccc <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800040aa:	54dc                	lw	a5,44(s1)
    800040ac:	06f04763          	bgtz	a5,8000411a <end_op+0xbc>
    acquire(&log.lock);
    800040b0:	0001d497          	auipc	s1,0x1d
    800040b4:	19848493          	addi	s1,s1,408 # 80021248 <log>
    800040b8:	8526                	mv	a0,s1
    800040ba:	ffffd097          	auipc	ra,0xffffd
    800040be:	b5e080e7          	jalr	-1186(ra) # 80000c18 <acquire>
    log.committing = 0;
    800040c2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800040c6:	8526                	mv	a0,s1
    800040c8:	ffffe097          	auipc	ra,0xffffe
    800040cc:	2ac080e7          	jalr	684(ra) # 80002374 <wakeup>
    release(&log.lock);
    800040d0:	8526                	mv	a0,s1
    800040d2:	ffffd097          	auipc	ra,0xffffd
    800040d6:	bfa080e7          	jalr	-1030(ra) # 80000ccc <release>
}
    800040da:	70e2                	ld	ra,56(sp)
    800040dc:	7442                	ld	s0,48(sp)
    800040de:	74a2                	ld	s1,40(sp)
    800040e0:	7902                	ld	s2,32(sp)
    800040e2:	69e2                	ld	s3,24(sp)
    800040e4:	6a42                	ld	s4,16(sp)
    800040e6:	6aa2                	ld	s5,8(sp)
    800040e8:	6121                	addi	sp,sp,64
    800040ea:	8082                	ret
    panic("log.committing");
    800040ec:	00004517          	auipc	a0,0x4
    800040f0:	51450513          	addi	a0,a0,1300 # 80008600 <syscalls+0x1e0>
    800040f4:	ffffc097          	auipc	ra,0xffffc
    800040f8:	45c080e7          	jalr	1116(ra) # 80000550 <panic>
    wakeup(&log);
    800040fc:	0001d497          	auipc	s1,0x1d
    80004100:	14c48493          	addi	s1,s1,332 # 80021248 <log>
    80004104:	8526                	mv	a0,s1
    80004106:	ffffe097          	auipc	ra,0xffffe
    8000410a:	26e080e7          	jalr	622(ra) # 80002374 <wakeup>
  release(&log.lock);
    8000410e:	8526                	mv	a0,s1
    80004110:	ffffd097          	auipc	ra,0xffffd
    80004114:	bbc080e7          	jalr	-1092(ra) # 80000ccc <release>
  if(do_commit){
    80004118:	b7c9                	j	800040da <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000411a:	0001da97          	auipc	s5,0x1d
    8000411e:	15ea8a93          	addi	s5,s5,350 # 80021278 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004122:	0001da17          	auipc	s4,0x1d
    80004126:	126a0a13          	addi	s4,s4,294 # 80021248 <log>
    8000412a:	018a2583          	lw	a1,24(s4)
    8000412e:	012585bb          	addw	a1,a1,s2
    80004132:	2585                	addiw	a1,a1,1
    80004134:	028a2503          	lw	a0,40(s4)
    80004138:	fffff097          	auipc	ra,0xfffff
    8000413c:	cd4080e7          	jalr	-812(ra) # 80002e0c <bread>
    80004140:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004142:	000aa583          	lw	a1,0(s5)
    80004146:	028a2503          	lw	a0,40(s4)
    8000414a:	fffff097          	auipc	ra,0xfffff
    8000414e:	cc2080e7          	jalr	-830(ra) # 80002e0c <bread>
    80004152:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004154:	40000613          	li	a2,1024
    80004158:	05850593          	addi	a1,a0,88
    8000415c:	05848513          	addi	a0,s1,88
    80004160:	ffffd097          	auipc	ra,0xffffd
    80004164:	c14080e7          	jalr	-1004(ra) # 80000d74 <memmove>
    bwrite(to);  // write the log
    80004168:	8526                	mv	a0,s1
    8000416a:	fffff097          	auipc	ra,0xfffff
    8000416e:	d94080e7          	jalr	-620(ra) # 80002efe <bwrite>
    brelse(from);
    80004172:	854e                	mv	a0,s3
    80004174:	fffff097          	auipc	ra,0xfffff
    80004178:	dc8080e7          	jalr	-568(ra) # 80002f3c <brelse>
    brelse(to);
    8000417c:	8526                	mv	a0,s1
    8000417e:	fffff097          	auipc	ra,0xfffff
    80004182:	dbe080e7          	jalr	-578(ra) # 80002f3c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004186:	2905                	addiw	s2,s2,1
    80004188:	0a91                	addi	s5,s5,4
    8000418a:	02ca2783          	lw	a5,44(s4)
    8000418e:	f8f94ee3          	blt	s2,a5,8000412a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004192:	00000097          	auipc	ra,0x0
    80004196:	c6a080e7          	jalr	-918(ra) # 80003dfc <write_head>
    install_trans(0); // Now install writes to home locations
    8000419a:	4501                	li	a0,0
    8000419c:	00000097          	auipc	ra,0x0
    800041a0:	cda080e7          	jalr	-806(ra) # 80003e76 <install_trans>
    log.lh.n = 0;
    800041a4:	0001d797          	auipc	a5,0x1d
    800041a8:	0c07a823          	sw	zero,208(a5) # 80021274 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800041ac:	00000097          	auipc	ra,0x0
    800041b0:	c50080e7          	jalr	-944(ra) # 80003dfc <write_head>
    800041b4:	bdf5                	j	800040b0 <end_op+0x52>

00000000800041b6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800041b6:	1101                	addi	sp,sp,-32
    800041b8:	ec06                	sd	ra,24(sp)
    800041ba:	e822                	sd	s0,16(sp)
    800041bc:	e426                	sd	s1,8(sp)
    800041be:	e04a                	sd	s2,0(sp)
    800041c0:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800041c2:	0001d717          	auipc	a4,0x1d
    800041c6:	0b272703          	lw	a4,178(a4) # 80021274 <log+0x2c>
    800041ca:	47f5                	li	a5,29
    800041cc:	08e7c063          	blt	a5,a4,8000424c <log_write+0x96>
    800041d0:	84aa                	mv	s1,a0
    800041d2:	0001d797          	auipc	a5,0x1d
    800041d6:	0927a783          	lw	a5,146(a5) # 80021264 <log+0x1c>
    800041da:	37fd                	addiw	a5,a5,-1
    800041dc:	06f75863          	bge	a4,a5,8000424c <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800041e0:	0001d797          	auipc	a5,0x1d
    800041e4:	0887a783          	lw	a5,136(a5) # 80021268 <log+0x20>
    800041e8:	06f05a63          	blez	a5,8000425c <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800041ec:	0001d917          	auipc	s2,0x1d
    800041f0:	05c90913          	addi	s2,s2,92 # 80021248 <log>
    800041f4:	854a                	mv	a0,s2
    800041f6:	ffffd097          	auipc	ra,0xffffd
    800041fa:	a22080e7          	jalr	-1502(ra) # 80000c18 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800041fe:	02c92603          	lw	a2,44(s2)
    80004202:	06c05563          	blez	a2,8000426c <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004206:	44cc                	lw	a1,12(s1)
    80004208:	0001d717          	auipc	a4,0x1d
    8000420c:	07070713          	addi	a4,a4,112 # 80021278 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004210:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004212:	4314                	lw	a3,0(a4)
    80004214:	04b68d63          	beq	a3,a1,8000426e <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004218:	2785                	addiw	a5,a5,1
    8000421a:	0711                	addi	a4,a4,4
    8000421c:	fec79be3          	bne	a5,a2,80004212 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004220:	0621                	addi	a2,a2,8
    80004222:	060a                	slli	a2,a2,0x2
    80004224:	0001d797          	auipc	a5,0x1d
    80004228:	02478793          	addi	a5,a5,36 # 80021248 <log>
    8000422c:	963e                	add	a2,a2,a5
    8000422e:	44dc                	lw	a5,12(s1)
    80004230:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004232:	8526                	mv	a0,s1
    80004234:	fffff097          	auipc	ra,0xfffff
    80004238:	da6080e7          	jalr	-602(ra) # 80002fda <bpin>
    log.lh.n++;
    8000423c:	0001d717          	auipc	a4,0x1d
    80004240:	00c70713          	addi	a4,a4,12 # 80021248 <log>
    80004244:	575c                	lw	a5,44(a4)
    80004246:	2785                	addiw	a5,a5,1
    80004248:	d75c                	sw	a5,44(a4)
    8000424a:	a83d                	j	80004288 <log_write+0xd2>
    panic("too big a transaction");
    8000424c:	00004517          	auipc	a0,0x4
    80004250:	3c450513          	addi	a0,a0,964 # 80008610 <syscalls+0x1f0>
    80004254:	ffffc097          	auipc	ra,0xffffc
    80004258:	2fc080e7          	jalr	764(ra) # 80000550 <panic>
    panic("log_write outside of trans");
    8000425c:	00004517          	auipc	a0,0x4
    80004260:	3cc50513          	addi	a0,a0,972 # 80008628 <syscalls+0x208>
    80004264:	ffffc097          	auipc	ra,0xffffc
    80004268:	2ec080e7          	jalr	748(ra) # 80000550 <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000426c:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000426e:	00878713          	addi	a4,a5,8
    80004272:	00271693          	slli	a3,a4,0x2
    80004276:	0001d717          	auipc	a4,0x1d
    8000427a:	fd270713          	addi	a4,a4,-46 # 80021248 <log>
    8000427e:	9736                	add	a4,a4,a3
    80004280:	44d4                	lw	a3,12(s1)
    80004282:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004284:	faf607e3          	beq	a2,a5,80004232 <log_write+0x7c>
  }
  release(&log.lock);
    80004288:	0001d517          	auipc	a0,0x1d
    8000428c:	fc050513          	addi	a0,a0,-64 # 80021248 <log>
    80004290:	ffffd097          	auipc	ra,0xffffd
    80004294:	a3c080e7          	jalr	-1476(ra) # 80000ccc <release>
}
    80004298:	60e2                	ld	ra,24(sp)
    8000429a:	6442                	ld	s0,16(sp)
    8000429c:	64a2                	ld	s1,8(sp)
    8000429e:	6902                	ld	s2,0(sp)
    800042a0:	6105                	addi	sp,sp,32
    800042a2:	8082                	ret

00000000800042a4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800042a4:	1101                	addi	sp,sp,-32
    800042a6:	ec06                	sd	ra,24(sp)
    800042a8:	e822                	sd	s0,16(sp)
    800042aa:	e426                	sd	s1,8(sp)
    800042ac:	e04a                	sd	s2,0(sp)
    800042ae:	1000                	addi	s0,sp,32
    800042b0:	84aa                	mv	s1,a0
    800042b2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800042b4:	00004597          	auipc	a1,0x4
    800042b8:	39458593          	addi	a1,a1,916 # 80008648 <syscalls+0x228>
    800042bc:	0521                	addi	a0,a0,8
    800042be:	ffffd097          	auipc	ra,0xffffd
    800042c2:	8ca080e7          	jalr	-1846(ra) # 80000b88 <initlock>
  lk->name = name;
    800042c6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800042ca:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800042ce:	0204a423          	sw	zero,40(s1)
}
    800042d2:	60e2                	ld	ra,24(sp)
    800042d4:	6442                	ld	s0,16(sp)
    800042d6:	64a2                	ld	s1,8(sp)
    800042d8:	6902                	ld	s2,0(sp)
    800042da:	6105                	addi	sp,sp,32
    800042dc:	8082                	ret

00000000800042de <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800042de:	1101                	addi	sp,sp,-32
    800042e0:	ec06                	sd	ra,24(sp)
    800042e2:	e822                	sd	s0,16(sp)
    800042e4:	e426                	sd	s1,8(sp)
    800042e6:	e04a                	sd	s2,0(sp)
    800042e8:	1000                	addi	s0,sp,32
    800042ea:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800042ec:	00850913          	addi	s2,a0,8
    800042f0:	854a                	mv	a0,s2
    800042f2:	ffffd097          	auipc	ra,0xffffd
    800042f6:	926080e7          	jalr	-1754(ra) # 80000c18 <acquire>
  while (lk->locked) {
    800042fa:	409c                	lw	a5,0(s1)
    800042fc:	cb89                	beqz	a5,8000430e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800042fe:	85ca                	mv	a1,s2
    80004300:	8526                	mv	a0,s1
    80004302:	ffffe097          	auipc	ra,0xffffe
    80004306:	eec080e7          	jalr	-276(ra) # 800021ee <sleep>
  while (lk->locked) {
    8000430a:	409c                	lw	a5,0(s1)
    8000430c:	fbed                	bnez	a5,800042fe <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000430e:	4785                	li	a5,1
    80004310:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004312:	ffffd097          	auipc	ra,0xffffd
    80004316:	6f0080e7          	jalr	1776(ra) # 80001a02 <myproc>
    8000431a:	5d1c                	lw	a5,56(a0)
    8000431c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000431e:	854a                	mv	a0,s2
    80004320:	ffffd097          	auipc	ra,0xffffd
    80004324:	9ac080e7          	jalr	-1620(ra) # 80000ccc <release>
}
    80004328:	60e2                	ld	ra,24(sp)
    8000432a:	6442                	ld	s0,16(sp)
    8000432c:	64a2                	ld	s1,8(sp)
    8000432e:	6902                	ld	s2,0(sp)
    80004330:	6105                	addi	sp,sp,32
    80004332:	8082                	ret

0000000080004334 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004334:	1101                	addi	sp,sp,-32
    80004336:	ec06                	sd	ra,24(sp)
    80004338:	e822                	sd	s0,16(sp)
    8000433a:	e426                	sd	s1,8(sp)
    8000433c:	e04a                	sd	s2,0(sp)
    8000433e:	1000                	addi	s0,sp,32
    80004340:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004342:	00850913          	addi	s2,a0,8
    80004346:	854a                	mv	a0,s2
    80004348:	ffffd097          	auipc	ra,0xffffd
    8000434c:	8d0080e7          	jalr	-1840(ra) # 80000c18 <acquire>
  lk->locked = 0;
    80004350:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004354:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004358:	8526                	mv	a0,s1
    8000435a:	ffffe097          	auipc	ra,0xffffe
    8000435e:	01a080e7          	jalr	26(ra) # 80002374 <wakeup>
  release(&lk->lk);
    80004362:	854a                	mv	a0,s2
    80004364:	ffffd097          	auipc	ra,0xffffd
    80004368:	968080e7          	jalr	-1688(ra) # 80000ccc <release>
}
    8000436c:	60e2                	ld	ra,24(sp)
    8000436e:	6442                	ld	s0,16(sp)
    80004370:	64a2                	ld	s1,8(sp)
    80004372:	6902                	ld	s2,0(sp)
    80004374:	6105                	addi	sp,sp,32
    80004376:	8082                	ret

0000000080004378 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004378:	7179                	addi	sp,sp,-48
    8000437a:	f406                	sd	ra,40(sp)
    8000437c:	f022                	sd	s0,32(sp)
    8000437e:	ec26                	sd	s1,24(sp)
    80004380:	e84a                	sd	s2,16(sp)
    80004382:	e44e                	sd	s3,8(sp)
    80004384:	1800                	addi	s0,sp,48
    80004386:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004388:	00850913          	addi	s2,a0,8
    8000438c:	854a                	mv	a0,s2
    8000438e:	ffffd097          	auipc	ra,0xffffd
    80004392:	88a080e7          	jalr	-1910(ra) # 80000c18 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004396:	409c                	lw	a5,0(s1)
    80004398:	ef99                	bnez	a5,800043b6 <holdingsleep+0x3e>
    8000439a:	4481                	li	s1,0
  release(&lk->lk);
    8000439c:	854a                	mv	a0,s2
    8000439e:	ffffd097          	auipc	ra,0xffffd
    800043a2:	92e080e7          	jalr	-1746(ra) # 80000ccc <release>
  return r;
}
    800043a6:	8526                	mv	a0,s1
    800043a8:	70a2                	ld	ra,40(sp)
    800043aa:	7402                	ld	s0,32(sp)
    800043ac:	64e2                	ld	s1,24(sp)
    800043ae:	6942                	ld	s2,16(sp)
    800043b0:	69a2                	ld	s3,8(sp)
    800043b2:	6145                	addi	sp,sp,48
    800043b4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800043b6:	0284a983          	lw	s3,40(s1)
    800043ba:	ffffd097          	auipc	ra,0xffffd
    800043be:	648080e7          	jalr	1608(ra) # 80001a02 <myproc>
    800043c2:	5d04                	lw	s1,56(a0)
    800043c4:	413484b3          	sub	s1,s1,s3
    800043c8:	0014b493          	seqz	s1,s1
    800043cc:	bfc1                	j	8000439c <holdingsleep+0x24>

00000000800043ce <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800043ce:	1141                	addi	sp,sp,-16
    800043d0:	e406                	sd	ra,8(sp)
    800043d2:	e022                	sd	s0,0(sp)
    800043d4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800043d6:	00004597          	auipc	a1,0x4
    800043da:	28258593          	addi	a1,a1,642 # 80008658 <syscalls+0x238>
    800043de:	0001d517          	auipc	a0,0x1d
    800043e2:	fb250513          	addi	a0,a0,-78 # 80021390 <ftable>
    800043e6:	ffffc097          	auipc	ra,0xffffc
    800043ea:	7a2080e7          	jalr	1954(ra) # 80000b88 <initlock>
}
    800043ee:	60a2                	ld	ra,8(sp)
    800043f0:	6402                	ld	s0,0(sp)
    800043f2:	0141                	addi	sp,sp,16
    800043f4:	8082                	ret

00000000800043f6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800043f6:	1101                	addi	sp,sp,-32
    800043f8:	ec06                	sd	ra,24(sp)
    800043fa:	e822                	sd	s0,16(sp)
    800043fc:	e426                	sd	s1,8(sp)
    800043fe:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004400:	0001d517          	auipc	a0,0x1d
    80004404:	f9050513          	addi	a0,a0,-112 # 80021390 <ftable>
    80004408:	ffffd097          	auipc	ra,0xffffd
    8000440c:	810080e7          	jalr	-2032(ra) # 80000c18 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004410:	0001d497          	auipc	s1,0x1d
    80004414:	f9848493          	addi	s1,s1,-104 # 800213a8 <ftable+0x18>
    80004418:	0001e717          	auipc	a4,0x1e
    8000441c:	f3070713          	addi	a4,a4,-208 # 80022348 <ftable+0xfb8>
    if(f->ref == 0){
    80004420:	40dc                	lw	a5,4(s1)
    80004422:	cf99                	beqz	a5,80004440 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004424:	02848493          	addi	s1,s1,40
    80004428:	fee49ce3          	bne	s1,a4,80004420 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000442c:	0001d517          	auipc	a0,0x1d
    80004430:	f6450513          	addi	a0,a0,-156 # 80021390 <ftable>
    80004434:	ffffd097          	auipc	ra,0xffffd
    80004438:	898080e7          	jalr	-1896(ra) # 80000ccc <release>
  return 0;
    8000443c:	4481                	li	s1,0
    8000443e:	a819                	j	80004454 <filealloc+0x5e>
      f->ref = 1;
    80004440:	4785                	li	a5,1
    80004442:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004444:	0001d517          	auipc	a0,0x1d
    80004448:	f4c50513          	addi	a0,a0,-180 # 80021390 <ftable>
    8000444c:	ffffd097          	auipc	ra,0xffffd
    80004450:	880080e7          	jalr	-1920(ra) # 80000ccc <release>
}
    80004454:	8526                	mv	a0,s1
    80004456:	60e2                	ld	ra,24(sp)
    80004458:	6442                	ld	s0,16(sp)
    8000445a:	64a2                	ld	s1,8(sp)
    8000445c:	6105                	addi	sp,sp,32
    8000445e:	8082                	ret

0000000080004460 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004460:	1101                	addi	sp,sp,-32
    80004462:	ec06                	sd	ra,24(sp)
    80004464:	e822                	sd	s0,16(sp)
    80004466:	e426                	sd	s1,8(sp)
    80004468:	1000                	addi	s0,sp,32
    8000446a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000446c:	0001d517          	auipc	a0,0x1d
    80004470:	f2450513          	addi	a0,a0,-220 # 80021390 <ftable>
    80004474:	ffffc097          	auipc	ra,0xffffc
    80004478:	7a4080e7          	jalr	1956(ra) # 80000c18 <acquire>
  if(f->ref < 1)
    8000447c:	40dc                	lw	a5,4(s1)
    8000447e:	02f05263          	blez	a5,800044a2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004482:	2785                	addiw	a5,a5,1
    80004484:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004486:	0001d517          	auipc	a0,0x1d
    8000448a:	f0a50513          	addi	a0,a0,-246 # 80021390 <ftable>
    8000448e:	ffffd097          	auipc	ra,0xffffd
    80004492:	83e080e7          	jalr	-1986(ra) # 80000ccc <release>
  return f;
}
    80004496:	8526                	mv	a0,s1
    80004498:	60e2                	ld	ra,24(sp)
    8000449a:	6442                	ld	s0,16(sp)
    8000449c:	64a2                	ld	s1,8(sp)
    8000449e:	6105                	addi	sp,sp,32
    800044a0:	8082                	ret
    panic("filedup");
    800044a2:	00004517          	auipc	a0,0x4
    800044a6:	1be50513          	addi	a0,a0,446 # 80008660 <syscalls+0x240>
    800044aa:	ffffc097          	auipc	ra,0xffffc
    800044ae:	0a6080e7          	jalr	166(ra) # 80000550 <panic>

00000000800044b2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800044b2:	7139                	addi	sp,sp,-64
    800044b4:	fc06                	sd	ra,56(sp)
    800044b6:	f822                	sd	s0,48(sp)
    800044b8:	f426                	sd	s1,40(sp)
    800044ba:	f04a                	sd	s2,32(sp)
    800044bc:	ec4e                	sd	s3,24(sp)
    800044be:	e852                	sd	s4,16(sp)
    800044c0:	e456                	sd	s5,8(sp)
    800044c2:	0080                	addi	s0,sp,64
    800044c4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800044c6:	0001d517          	auipc	a0,0x1d
    800044ca:	eca50513          	addi	a0,a0,-310 # 80021390 <ftable>
    800044ce:	ffffc097          	auipc	ra,0xffffc
    800044d2:	74a080e7          	jalr	1866(ra) # 80000c18 <acquire>
  if(f->ref < 1)
    800044d6:	40dc                	lw	a5,4(s1)
    800044d8:	06f05163          	blez	a5,8000453a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800044dc:	37fd                	addiw	a5,a5,-1
    800044de:	0007871b          	sext.w	a4,a5
    800044e2:	c0dc                	sw	a5,4(s1)
    800044e4:	06e04363          	bgtz	a4,8000454a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800044e8:	0004a903          	lw	s2,0(s1)
    800044ec:	0094ca83          	lbu	s5,9(s1)
    800044f0:	0104ba03          	ld	s4,16(s1)
    800044f4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800044f8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800044fc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004500:	0001d517          	auipc	a0,0x1d
    80004504:	e9050513          	addi	a0,a0,-368 # 80021390 <ftable>
    80004508:	ffffc097          	auipc	ra,0xffffc
    8000450c:	7c4080e7          	jalr	1988(ra) # 80000ccc <release>

  if(ff.type == FD_PIPE){
    80004510:	4785                	li	a5,1
    80004512:	04f90d63          	beq	s2,a5,8000456c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004516:	3979                	addiw	s2,s2,-2
    80004518:	4785                	li	a5,1
    8000451a:	0527e063          	bltu	a5,s2,8000455a <fileclose+0xa8>
    begin_op();
    8000451e:	00000097          	auipc	ra,0x0
    80004522:	ac0080e7          	jalr	-1344(ra) # 80003fde <begin_op>
    iput(ff.ip);
    80004526:	854e                	mv	a0,s3
    80004528:	fffff097          	auipc	ra,0xfffff
    8000452c:	2a0080e7          	jalr	672(ra) # 800037c8 <iput>
    end_op();
    80004530:	00000097          	auipc	ra,0x0
    80004534:	b2e080e7          	jalr	-1234(ra) # 8000405e <end_op>
    80004538:	a00d                	j	8000455a <fileclose+0xa8>
    panic("fileclose");
    8000453a:	00004517          	auipc	a0,0x4
    8000453e:	12e50513          	addi	a0,a0,302 # 80008668 <syscalls+0x248>
    80004542:	ffffc097          	auipc	ra,0xffffc
    80004546:	00e080e7          	jalr	14(ra) # 80000550 <panic>
    release(&ftable.lock);
    8000454a:	0001d517          	auipc	a0,0x1d
    8000454e:	e4650513          	addi	a0,a0,-442 # 80021390 <ftable>
    80004552:	ffffc097          	auipc	ra,0xffffc
    80004556:	77a080e7          	jalr	1914(ra) # 80000ccc <release>
  }
}
    8000455a:	70e2                	ld	ra,56(sp)
    8000455c:	7442                	ld	s0,48(sp)
    8000455e:	74a2                	ld	s1,40(sp)
    80004560:	7902                	ld	s2,32(sp)
    80004562:	69e2                	ld	s3,24(sp)
    80004564:	6a42                	ld	s4,16(sp)
    80004566:	6aa2                	ld	s5,8(sp)
    80004568:	6121                	addi	sp,sp,64
    8000456a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000456c:	85d6                	mv	a1,s5
    8000456e:	8552                	mv	a0,s4
    80004570:	00000097          	auipc	ra,0x0
    80004574:	372080e7          	jalr	882(ra) # 800048e2 <pipeclose>
    80004578:	b7cd                	j	8000455a <fileclose+0xa8>

000000008000457a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000457a:	715d                	addi	sp,sp,-80
    8000457c:	e486                	sd	ra,72(sp)
    8000457e:	e0a2                	sd	s0,64(sp)
    80004580:	fc26                	sd	s1,56(sp)
    80004582:	f84a                	sd	s2,48(sp)
    80004584:	f44e                	sd	s3,40(sp)
    80004586:	0880                	addi	s0,sp,80
    80004588:	84aa                	mv	s1,a0
    8000458a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000458c:	ffffd097          	auipc	ra,0xffffd
    80004590:	476080e7          	jalr	1142(ra) # 80001a02 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004594:	409c                	lw	a5,0(s1)
    80004596:	37f9                	addiw	a5,a5,-2
    80004598:	4705                	li	a4,1
    8000459a:	04f76763          	bltu	a4,a5,800045e8 <filestat+0x6e>
    8000459e:	892a                	mv	s2,a0
    ilock(f->ip);
    800045a0:	6c88                	ld	a0,24(s1)
    800045a2:	fffff097          	auipc	ra,0xfffff
    800045a6:	06c080e7          	jalr	108(ra) # 8000360e <ilock>
    stati(f->ip, &st);
    800045aa:	fb840593          	addi	a1,s0,-72
    800045ae:	6c88                	ld	a0,24(s1)
    800045b0:	fffff097          	auipc	ra,0xfffff
    800045b4:	2e8080e7          	jalr	744(ra) # 80003898 <stati>
    iunlock(f->ip);
    800045b8:	6c88                	ld	a0,24(s1)
    800045ba:	fffff097          	auipc	ra,0xfffff
    800045be:	116080e7          	jalr	278(ra) # 800036d0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800045c2:	46e1                	li	a3,24
    800045c4:	fb840613          	addi	a2,s0,-72
    800045c8:	85ce                	mv	a1,s3
    800045ca:	05093503          	ld	a0,80(s2)
    800045ce:	ffffd097          	auipc	ra,0xffffd
    800045d2:	0ca080e7          	jalr	202(ra) # 80001698 <copyout>
    800045d6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800045da:	60a6                	ld	ra,72(sp)
    800045dc:	6406                	ld	s0,64(sp)
    800045de:	74e2                	ld	s1,56(sp)
    800045e0:	7942                	ld	s2,48(sp)
    800045e2:	79a2                	ld	s3,40(sp)
    800045e4:	6161                	addi	sp,sp,80
    800045e6:	8082                	ret
  return -1;
    800045e8:	557d                	li	a0,-1
    800045ea:	bfc5                	j	800045da <filestat+0x60>

00000000800045ec <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800045ec:	7179                	addi	sp,sp,-48
    800045ee:	f406                	sd	ra,40(sp)
    800045f0:	f022                	sd	s0,32(sp)
    800045f2:	ec26                	sd	s1,24(sp)
    800045f4:	e84a                	sd	s2,16(sp)
    800045f6:	e44e                	sd	s3,8(sp)
    800045f8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800045fa:	00854783          	lbu	a5,8(a0)
    800045fe:	c3d5                	beqz	a5,800046a2 <fileread+0xb6>
    80004600:	84aa                	mv	s1,a0
    80004602:	89ae                	mv	s3,a1
    80004604:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004606:	411c                	lw	a5,0(a0)
    80004608:	4705                	li	a4,1
    8000460a:	04e78963          	beq	a5,a4,8000465c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000460e:	470d                	li	a4,3
    80004610:	04e78d63          	beq	a5,a4,8000466a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004614:	4709                	li	a4,2
    80004616:	06e79e63          	bne	a5,a4,80004692 <fileread+0xa6>
    ilock(f->ip);
    8000461a:	6d08                	ld	a0,24(a0)
    8000461c:	fffff097          	auipc	ra,0xfffff
    80004620:	ff2080e7          	jalr	-14(ra) # 8000360e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004624:	874a                	mv	a4,s2
    80004626:	5094                	lw	a3,32(s1)
    80004628:	864e                	mv	a2,s3
    8000462a:	4585                	li	a1,1
    8000462c:	6c88                	ld	a0,24(s1)
    8000462e:	fffff097          	auipc	ra,0xfffff
    80004632:	294080e7          	jalr	660(ra) # 800038c2 <readi>
    80004636:	892a                	mv	s2,a0
    80004638:	00a05563          	blez	a0,80004642 <fileread+0x56>
      f->off += r;
    8000463c:	509c                	lw	a5,32(s1)
    8000463e:	9fa9                	addw	a5,a5,a0
    80004640:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004642:	6c88                	ld	a0,24(s1)
    80004644:	fffff097          	auipc	ra,0xfffff
    80004648:	08c080e7          	jalr	140(ra) # 800036d0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000464c:	854a                	mv	a0,s2
    8000464e:	70a2                	ld	ra,40(sp)
    80004650:	7402                	ld	s0,32(sp)
    80004652:	64e2                	ld	s1,24(sp)
    80004654:	6942                	ld	s2,16(sp)
    80004656:	69a2                	ld	s3,8(sp)
    80004658:	6145                	addi	sp,sp,48
    8000465a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000465c:	6908                	ld	a0,16(a0)
    8000465e:	00000097          	auipc	ra,0x0
    80004662:	418080e7          	jalr	1048(ra) # 80004a76 <piperead>
    80004666:	892a                	mv	s2,a0
    80004668:	b7d5                	j	8000464c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000466a:	02451783          	lh	a5,36(a0)
    8000466e:	03079693          	slli	a3,a5,0x30
    80004672:	92c1                	srli	a3,a3,0x30
    80004674:	4725                	li	a4,9
    80004676:	02d76863          	bltu	a4,a3,800046a6 <fileread+0xba>
    8000467a:	0792                	slli	a5,a5,0x4
    8000467c:	0001d717          	auipc	a4,0x1d
    80004680:	c7470713          	addi	a4,a4,-908 # 800212f0 <devsw>
    80004684:	97ba                	add	a5,a5,a4
    80004686:	639c                	ld	a5,0(a5)
    80004688:	c38d                	beqz	a5,800046aa <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000468a:	4505                	li	a0,1
    8000468c:	9782                	jalr	a5
    8000468e:	892a                	mv	s2,a0
    80004690:	bf75                	j	8000464c <fileread+0x60>
    panic("fileread");
    80004692:	00004517          	auipc	a0,0x4
    80004696:	fe650513          	addi	a0,a0,-26 # 80008678 <syscalls+0x258>
    8000469a:	ffffc097          	auipc	ra,0xffffc
    8000469e:	eb6080e7          	jalr	-330(ra) # 80000550 <panic>
    return -1;
    800046a2:	597d                	li	s2,-1
    800046a4:	b765                	j	8000464c <fileread+0x60>
      return -1;
    800046a6:	597d                	li	s2,-1
    800046a8:	b755                	j	8000464c <fileread+0x60>
    800046aa:	597d                	li	s2,-1
    800046ac:	b745                	j	8000464c <fileread+0x60>

00000000800046ae <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800046ae:	00954783          	lbu	a5,9(a0)
    800046b2:	14078563          	beqz	a5,800047fc <filewrite+0x14e>
{
    800046b6:	715d                	addi	sp,sp,-80
    800046b8:	e486                	sd	ra,72(sp)
    800046ba:	e0a2                	sd	s0,64(sp)
    800046bc:	fc26                	sd	s1,56(sp)
    800046be:	f84a                	sd	s2,48(sp)
    800046c0:	f44e                	sd	s3,40(sp)
    800046c2:	f052                	sd	s4,32(sp)
    800046c4:	ec56                	sd	s5,24(sp)
    800046c6:	e85a                	sd	s6,16(sp)
    800046c8:	e45e                	sd	s7,8(sp)
    800046ca:	e062                	sd	s8,0(sp)
    800046cc:	0880                	addi	s0,sp,80
    800046ce:	892a                	mv	s2,a0
    800046d0:	8aae                	mv	s5,a1
    800046d2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800046d4:	411c                	lw	a5,0(a0)
    800046d6:	4705                	li	a4,1
    800046d8:	02e78263          	beq	a5,a4,800046fc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046dc:	470d                	li	a4,3
    800046de:	02e78563          	beq	a5,a4,80004708 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800046e2:	4709                	li	a4,2
    800046e4:	10e79463          	bne	a5,a4,800047ec <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800046e8:	0ec05e63          	blez	a2,800047e4 <filewrite+0x136>
    int i = 0;
    800046ec:	4981                	li	s3,0
    800046ee:	6b05                	lui	s6,0x1
    800046f0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800046f4:	6b85                	lui	s7,0x1
    800046f6:	c00b8b9b          	addiw	s7,s7,-1024
    800046fa:	a851                	j	8000478e <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800046fc:	6908                	ld	a0,16(a0)
    800046fe:	00000097          	auipc	ra,0x0
    80004702:	254080e7          	jalr	596(ra) # 80004952 <pipewrite>
    80004706:	a85d                	j	800047bc <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004708:	02451783          	lh	a5,36(a0)
    8000470c:	03079693          	slli	a3,a5,0x30
    80004710:	92c1                	srli	a3,a3,0x30
    80004712:	4725                	li	a4,9
    80004714:	0ed76663          	bltu	a4,a3,80004800 <filewrite+0x152>
    80004718:	0792                	slli	a5,a5,0x4
    8000471a:	0001d717          	auipc	a4,0x1d
    8000471e:	bd670713          	addi	a4,a4,-1066 # 800212f0 <devsw>
    80004722:	97ba                	add	a5,a5,a4
    80004724:	679c                	ld	a5,8(a5)
    80004726:	cff9                	beqz	a5,80004804 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004728:	4505                	li	a0,1
    8000472a:	9782                	jalr	a5
    8000472c:	a841                	j	800047bc <filewrite+0x10e>
    8000472e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004732:	00000097          	auipc	ra,0x0
    80004736:	8ac080e7          	jalr	-1876(ra) # 80003fde <begin_op>
      ilock(f->ip);
    8000473a:	01893503          	ld	a0,24(s2)
    8000473e:	fffff097          	auipc	ra,0xfffff
    80004742:	ed0080e7          	jalr	-304(ra) # 8000360e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004746:	8762                	mv	a4,s8
    80004748:	02092683          	lw	a3,32(s2)
    8000474c:	01598633          	add	a2,s3,s5
    80004750:	4585                	li	a1,1
    80004752:	01893503          	ld	a0,24(s2)
    80004756:	fffff097          	auipc	ra,0xfffff
    8000475a:	264080e7          	jalr	612(ra) # 800039ba <writei>
    8000475e:	84aa                	mv	s1,a0
    80004760:	02a05f63          	blez	a0,8000479e <filewrite+0xf0>
        f->off += r;
    80004764:	02092783          	lw	a5,32(s2)
    80004768:	9fa9                	addw	a5,a5,a0
    8000476a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000476e:	01893503          	ld	a0,24(s2)
    80004772:	fffff097          	auipc	ra,0xfffff
    80004776:	f5e080e7          	jalr	-162(ra) # 800036d0 <iunlock>
      end_op();
    8000477a:	00000097          	auipc	ra,0x0
    8000477e:	8e4080e7          	jalr	-1820(ra) # 8000405e <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004782:	049c1963          	bne	s8,s1,800047d4 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004786:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000478a:	0349d663          	bge	s3,s4,800047b6 <filewrite+0x108>
      int n1 = n - i;
    8000478e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004792:	84be                	mv	s1,a5
    80004794:	2781                	sext.w	a5,a5
    80004796:	f8fb5ce3          	bge	s6,a5,8000472e <filewrite+0x80>
    8000479a:	84de                	mv	s1,s7
    8000479c:	bf49                	j	8000472e <filewrite+0x80>
      iunlock(f->ip);
    8000479e:	01893503          	ld	a0,24(s2)
    800047a2:	fffff097          	auipc	ra,0xfffff
    800047a6:	f2e080e7          	jalr	-210(ra) # 800036d0 <iunlock>
      end_op();
    800047aa:	00000097          	auipc	ra,0x0
    800047ae:	8b4080e7          	jalr	-1868(ra) # 8000405e <end_op>
      if(r < 0)
    800047b2:	fc04d8e3          	bgez	s1,80004782 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800047b6:	8552                	mv	a0,s4
    800047b8:	033a1863          	bne	s4,s3,800047e8 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800047bc:	60a6                	ld	ra,72(sp)
    800047be:	6406                	ld	s0,64(sp)
    800047c0:	74e2                	ld	s1,56(sp)
    800047c2:	7942                	ld	s2,48(sp)
    800047c4:	79a2                	ld	s3,40(sp)
    800047c6:	7a02                	ld	s4,32(sp)
    800047c8:	6ae2                	ld	s5,24(sp)
    800047ca:	6b42                	ld	s6,16(sp)
    800047cc:	6ba2                	ld	s7,8(sp)
    800047ce:	6c02                	ld	s8,0(sp)
    800047d0:	6161                	addi	sp,sp,80
    800047d2:	8082                	ret
        panic("short filewrite");
    800047d4:	00004517          	auipc	a0,0x4
    800047d8:	eb450513          	addi	a0,a0,-332 # 80008688 <syscalls+0x268>
    800047dc:	ffffc097          	auipc	ra,0xffffc
    800047e0:	d74080e7          	jalr	-652(ra) # 80000550 <panic>
    int i = 0;
    800047e4:	4981                	li	s3,0
    800047e6:	bfc1                	j	800047b6 <filewrite+0x108>
    ret = (i == n ? n : -1);
    800047e8:	557d                	li	a0,-1
    800047ea:	bfc9                	j	800047bc <filewrite+0x10e>
    panic("filewrite");
    800047ec:	00004517          	auipc	a0,0x4
    800047f0:	eac50513          	addi	a0,a0,-340 # 80008698 <syscalls+0x278>
    800047f4:	ffffc097          	auipc	ra,0xffffc
    800047f8:	d5c080e7          	jalr	-676(ra) # 80000550 <panic>
    return -1;
    800047fc:	557d                	li	a0,-1
}
    800047fe:	8082                	ret
      return -1;
    80004800:	557d                	li	a0,-1
    80004802:	bf6d                	j	800047bc <filewrite+0x10e>
    80004804:	557d                	li	a0,-1
    80004806:	bf5d                	j	800047bc <filewrite+0x10e>

0000000080004808 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004808:	7179                	addi	sp,sp,-48
    8000480a:	f406                	sd	ra,40(sp)
    8000480c:	f022                	sd	s0,32(sp)
    8000480e:	ec26                	sd	s1,24(sp)
    80004810:	e84a                	sd	s2,16(sp)
    80004812:	e44e                	sd	s3,8(sp)
    80004814:	e052                	sd	s4,0(sp)
    80004816:	1800                	addi	s0,sp,48
    80004818:	84aa                	mv	s1,a0
    8000481a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000481c:	0005b023          	sd	zero,0(a1)
    80004820:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004824:	00000097          	auipc	ra,0x0
    80004828:	bd2080e7          	jalr	-1070(ra) # 800043f6 <filealloc>
    8000482c:	e088                	sd	a0,0(s1)
    8000482e:	c551                	beqz	a0,800048ba <pipealloc+0xb2>
    80004830:	00000097          	auipc	ra,0x0
    80004834:	bc6080e7          	jalr	-1082(ra) # 800043f6 <filealloc>
    80004838:	00aa3023          	sd	a0,0(s4)
    8000483c:	c92d                	beqz	a0,800048ae <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	2ea080e7          	jalr	746(ra) # 80000b28 <kalloc>
    80004846:	892a                	mv	s2,a0
    80004848:	c125                	beqz	a0,800048a8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000484a:	4985                	li	s3,1
    8000484c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004850:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004854:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004858:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000485c:	00004597          	auipc	a1,0x4
    80004860:	e4c58593          	addi	a1,a1,-436 # 800086a8 <syscalls+0x288>
    80004864:	ffffc097          	auipc	ra,0xffffc
    80004868:	324080e7          	jalr	804(ra) # 80000b88 <initlock>
  (*f0)->type = FD_PIPE;
    8000486c:	609c                	ld	a5,0(s1)
    8000486e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004872:	609c                	ld	a5,0(s1)
    80004874:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004878:	609c                	ld	a5,0(s1)
    8000487a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000487e:	609c                	ld	a5,0(s1)
    80004880:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004884:	000a3783          	ld	a5,0(s4)
    80004888:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000488c:	000a3783          	ld	a5,0(s4)
    80004890:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004894:	000a3783          	ld	a5,0(s4)
    80004898:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000489c:	000a3783          	ld	a5,0(s4)
    800048a0:	0127b823          	sd	s2,16(a5)
  return 0;
    800048a4:	4501                	li	a0,0
    800048a6:	a025                	j	800048ce <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800048a8:	6088                	ld	a0,0(s1)
    800048aa:	e501                	bnez	a0,800048b2 <pipealloc+0xaa>
    800048ac:	a039                	j	800048ba <pipealloc+0xb2>
    800048ae:	6088                	ld	a0,0(s1)
    800048b0:	c51d                	beqz	a0,800048de <pipealloc+0xd6>
    fileclose(*f0);
    800048b2:	00000097          	auipc	ra,0x0
    800048b6:	c00080e7          	jalr	-1024(ra) # 800044b2 <fileclose>
  if(*f1)
    800048ba:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800048be:	557d                	li	a0,-1
  if(*f1)
    800048c0:	c799                	beqz	a5,800048ce <pipealloc+0xc6>
    fileclose(*f1);
    800048c2:	853e                	mv	a0,a5
    800048c4:	00000097          	auipc	ra,0x0
    800048c8:	bee080e7          	jalr	-1042(ra) # 800044b2 <fileclose>
  return -1;
    800048cc:	557d                	li	a0,-1
}
    800048ce:	70a2                	ld	ra,40(sp)
    800048d0:	7402                	ld	s0,32(sp)
    800048d2:	64e2                	ld	s1,24(sp)
    800048d4:	6942                	ld	s2,16(sp)
    800048d6:	69a2                	ld	s3,8(sp)
    800048d8:	6a02                	ld	s4,0(sp)
    800048da:	6145                	addi	sp,sp,48
    800048dc:	8082                	ret
  return -1;
    800048de:	557d                	li	a0,-1
    800048e0:	b7fd                	j	800048ce <pipealloc+0xc6>

00000000800048e2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800048e2:	1101                	addi	sp,sp,-32
    800048e4:	ec06                	sd	ra,24(sp)
    800048e6:	e822                	sd	s0,16(sp)
    800048e8:	e426                	sd	s1,8(sp)
    800048ea:	e04a                	sd	s2,0(sp)
    800048ec:	1000                	addi	s0,sp,32
    800048ee:	84aa                	mv	s1,a0
    800048f0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800048f2:	ffffc097          	auipc	ra,0xffffc
    800048f6:	326080e7          	jalr	806(ra) # 80000c18 <acquire>
  if(writable){
    800048fa:	02090d63          	beqz	s2,80004934 <pipeclose+0x52>
    pi->writeopen = 0;
    800048fe:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004902:	21848513          	addi	a0,s1,536
    80004906:	ffffe097          	auipc	ra,0xffffe
    8000490a:	a6e080e7          	jalr	-1426(ra) # 80002374 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000490e:	2204b783          	ld	a5,544(s1)
    80004912:	eb95                	bnez	a5,80004946 <pipeclose+0x64>
    release(&pi->lock);
    80004914:	8526                	mv	a0,s1
    80004916:	ffffc097          	auipc	ra,0xffffc
    8000491a:	3b6080e7          	jalr	950(ra) # 80000ccc <release>
    kfree((char*)pi);
    8000491e:	8526                	mv	a0,s1
    80004920:	ffffc097          	auipc	ra,0xffffc
    80004924:	10c080e7          	jalr	268(ra) # 80000a2c <kfree>
  } else
    release(&pi->lock);
}
    80004928:	60e2                	ld	ra,24(sp)
    8000492a:	6442                	ld	s0,16(sp)
    8000492c:	64a2                	ld	s1,8(sp)
    8000492e:	6902                	ld	s2,0(sp)
    80004930:	6105                	addi	sp,sp,32
    80004932:	8082                	ret
    pi->readopen = 0;
    80004934:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004938:	21c48513          	addi	a0,s1,540
    8000493c:	ffffe097          	auipc	ra,0xffffe
    80004940:	a38080e7          	jalr	-1480(ra) # 80002374 <wakeup>
    80004944:	b7e9                	j	8000490e <pipeclose+0x2c>
    release(&pi->lock);
    80004946:	8526                	mv	a0,s1
    80004948:	ffffc097          	auipc	ra,0xffffc
    8000494c:	384080e7          	jalr	900(ra) # 80000ccc <release>
}
    80004950:	bfe1                	j	80004928 <pipeclose+0x46>

0000000080004952 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004952:	7119                	addi	sp,sp,-128
    80004954:	fc86                	sd	ra,120(sp)
    80004956:	f8a2                	sd	s0,112(sp)
    80004958:	f4a6                	sd	s1,104(sp)
    8000495a:	f0ca                	sd	s2,96(sp)
    8000495c:	ecce                	sd	s3,88(sp)
    8000495e:	e8d2                	sd	s4,80(sp)
    80004960:	e4d6                	sd	s5,72(sp)
    80004962:	e0da                	sd	s6,64(sp)
    80004964:	fc5e                	sd	s7,56(sp)
    80004966:	f862                	sd	s8,48(sp)
    80004968:	f466                	sd	s9,40(sp)
    8000496a:	f06a                	sd	s10,32(sp)
    8000496c:	ec6e                	sd	s11,24(sp)
    8000496e:	0100                	addi	s0,sp,128
    80004970:	84aa                	mv	s1,a0
    80004972:	8cae                	mv	s9,a1
    80004974:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004976:	ffffd097          	auipc	ra,0xffffd
    8000497a:	08c080e7          	jalr	140(ra) # 80001a02 <myproc>
    8000497e:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004980:	8526                	mv	a0,s1
    80004982:	ffffc097          	auipc	ra,0xffffc
    80004986:	296080e7          	jalr	662(ra) # 80000c18 <acquire>
  for(i = 0; i < n; i++){
    8000498a:	0d605963          	blez	s6,80004a5c <pipewrite+0x10a>
    8000498e:	89a6                	mv	s3,s1
    80004990:	3b7d                	addiw	s6,s6,-1
    80004992:	1b02                	slli	s6,s6,0x20
    80004994:	020b5b13          	srli	s6,s6,0x20
    80004998:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    8000499a:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000499e:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049a2:	5dfd                	li	s11,-1
    800049a4:	000b8d1b          	sext.w	s10,s7
    800049a8:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    800049aa:	2184a783          	lw	a5,536(s1)
    800049ae:	21c4a703          	lw	a4,540(s1)
    800049b2:	2007879b          	addiw	a5,a5,512
    800049b6:	02f71b63          	bne	a4,a5,800049ec <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    800049ba:	2204a783          	lw	a5,544(s1)
    800049be:	cbad                	beqz	a5,80004a30 <pipewrite+0xde>
    800049c0:	03092783          	lw	a5,48(s2)
    800049c4:	e7b5                	bnez	a5,80004a30 <pipewrite+0xde>
      wakeup(&pi->nread);
    800049c6:	8556                	mv	a0,s5
    800049c8:	ffffe097          	auipc	ra,0xffffe
    800049cc:	9ac080e7          	jalr	-1620(ra) # 80002374 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800049d0:	85ce                	mv	a1,s3
    800049d2:	8552                	mv	a0,s4
    800049d4:	ffffe097          	auipc	ra,0xffffe
    800049d8:	81a080e7          	jalr	-2022(ra) # 800021ee <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    800049dc:	2184a783          	lw	a5,536(s1)
    800049e0:	21c4a703          	lw	a4,540(s1)
    800049e4:	2007879b          	addiw	a5,a5,512
    800049e8:	fcf709e3          	beq	a4,a5,800049ba <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049ec:	4685                	li	a3,1
    800049ee:	019b8633          	add	a2,s7,s9
    800049f2:	f8f40593          	addi	a1,s0,-113
    800049f6:	05093503          	ld	a0,80(s2)
    800049fa:	ffffd097          	auipc	ra,0xffffd
    800049fe:	d2a080e7          	jalr	-726(ra) # 80001724 <copyin>
    80004a02:	05b50e63          	beq	a0,s11,80004a5e <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a06:	21c4a783          	lw	a5,540(s1)
    80004a0a:	0017871b          	addiw	a4,a5,1
    80004a0e:	20e4ae23          	sw	a4,540(s1)
    80004a12:	1ff7f793          	andi	a5,a5,511
    80004a16:	97a6                	add	a5,a5,s1
    80004a18:	f8f44703          	lbu	a4,-113(s0)
    80004a1c:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004a20:	001d0c1b          	addiw	s8,s10,1
    80004a24:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004a28:	036b8b63          	beq	s7,s6,80004a5e <pipewrite+0x10c>
    80004a2c:	8bbe                	mv	s7,a5
    80004a2e:	bf9d                	j	800049a4 <pipewrite+0x52>
        release(&pi->lock);
    80004a30:	8526                	mv	a0,s1
    80004a32:	ffffc097          	auipc	ra,0xffffc
    80004a36:	29a080e7          	jalr	666(ra) # 80000ccc <release>
        return -1;
    80004a3a:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004a3c:	8562                	mv	a0,s8
    80004a3e:	70e6                	ld	ra,120(sp)
    80004a40:	7446                	ld	s0,112(sp)
    80004a42:	74a6                	ld	s1,104(sp)
    80004a44:	7906                	ld	s2,96(sp)
    80004a46:	69e6                	ld	s3,88(sp)
    80004a48:	6a46                	ld	s4,80(sp)
    80004a4a:	6aa6                	ld	s5,72(sp)
    80004a4c:	6b06                	ld	s6,64(sp)
    80004a4e:	7be2                	ld	s7,56(sp)
    80004a50:	7c42                	ld	s8,48(sp)
    80004a52:	7ca2                	ld	s9,40(sp)
    80004a54:	7d02                	ld	s10,32(sp)
    80004a56:	6de2                	ld	s11,24(sp)
    80004a58:	6109                	addi	sp,sp,128
    80004a5a:	8082                	ret
  for(i = 0; i < n; i++){
    80004a5c:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004a5e:	21848513          	addi	a0,s1,536
    80004a62:	ffffe097          	auipc	ra,0xffffe
    80004a66:	912080e7          	jalr	-1774(ra) # 80002374 <wakeup>
  release(&pi->lock);
    80004a6a:	8526                	mv	a0,s1
    80004a6c:	ffffc097          	auipc	ra,0xffffc
    80004a70:	260080e7          	jalr	608(ra) # 80000ccc <release>
  return i;
    80004a74:	b7e1                	j	80004a3c <pipewrite+0xea>

0000000080004a76 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a76:	715d                	addi	sp,sp,-80
    80004a78:	e486                	sd	ra,72(sp)
    80004a7a:	e0a2                	sd	s0,64(sp)
    80004a7c:	fc26                	sd	s1,56(sp)
    80004a7e:	f84a                	sd	s2,48(sp)
    80004a80:	f44e                	sd	s3,40(sp)
    80004a82:	f052                	sd	s4,32(sp)
    80004a84:	ec56                	sd	s5,24(sp)
    80004a86:	e85a                	sd	s6,16(sp)
    80004a88:	0880                	addi	s0,sp,80
    80004a8a:	84aa                	mv	s1,a0
    80004a8c:	892e                	mv	s2,a1
    80004a8e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a90:	ffffd097          	auipc	ra,0xffffd
    80004a94:	f72080e7          	jalr	-142(ra) # 80001a02 <myproc>
    80004a98:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a9a:	8b26                	mv	s6,s1
    80004a9c:	8526                	mv	a0,s1
    80004a9e:	ffffc097          	auipc	ra,0xffffc
    80004aa2:	17a080e7          	jalr	378(ra) # 80000c18 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004aa6:	2184a703          	lw	a4,536(s1)
    80004aaa:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004aae:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ab2:	02f71463          	bne	a4,a5,80004ada <piperead+0x64>
    80004ab6:	2244a783          	lw	a5,548(s1)
    80004aba:	c385                	beqz	a5,80004ada <piperead+0x64>
    if(pr->killed){
    80004abc:	030a2783          	lw	a5,48(s4)
    80004ac0:	ebc1                	bnez	a5,80004b50 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ac2:	85da                	mv	a1,s6
    80004ac4:	854e                	mv	a0,s3
    80004ac6:	ffffd097          	auipc	ra,0xffffd
    80004aca:	728080e7          	jalr	1832(ra) # 800021ee <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ace:	2184a703          	lw	a4,536(s1)
    80004ad2:	21c4a783          	lw	a5,540(s1)
    80004ad6:	fef700e3          	beq	a4,a5,80004ab6 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ada:	09505263          	blez	s5,80004b5e <piperead+0xe8>
    80004ade:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ae0:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004ae2:	2184a783          	lw	a5,536(s1)
    80004ae6:	21c4a703          	lw	a4,540(s1)
    80004aea:	02f70d63          	beq	a4,a5,80004b24 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004aee:	0017871b          	addiw	a4,a5,1
    80004af2:	20e4ac23          	sw	a4,536(s1)
    80004af6:	1ff7f793          	andi	a5,a5,511
    80004afa:	97a6                	add	a5,a5,s1
    80004afc:	0187c783          	lbu	a5,24(a5)
    80004b00:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b04:	4685                	li	a3,1
    80004b06:	fbf40613          	addi	a2,s0,-65
    80004b0a:	85ca                	mv	a1,s2
    80004b0c:	050a3503          	ld	a0,80(s4)
    80004b10:	ffffd097          	auipc	ra,0xffffd
    80004b14:	b88080e7          	jalr	-1144(ra) # 80001698 <copyout>
    80004b18:	01650663          	beq	a0,s6,80004b24 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b1c:	2985                	addiw	s3,s3,1
    80004b1e:	0905                	addi	s2,s2,1
    80004b20:	fd3a91e3          	bne	s5,s3,80004ae2 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b24:	21c48513          	addi	a0,s1,540
    80004b28:	ffffe097          	auipc	ra,0xffffe
    80004b2c:	84c080e7          	jalr	-1972(ra) # 80002374 <wakeup>
  release(&pi->lock);
    80004b30:	8526                	mv	a0,s1
    80004b32:	ffffc097          	auipc	ra,0xffffc
    80004b36:	19a080e7          	jalr	410(ra) # 80000ccc <release>
  return i;
}
    80004b3a:	854e                	mv	a0,s3
    80004b3c:	60a6                	ld	ra,72(sp)
    80004b3e:	6406                	ld	s0,64(sp)
    80004b40:	74e2                	ld	s1,56(sp)
    80004b42:	7942                	ld	s2,48(sp)
    80004b44:	79a2                	ld	s3,40(sp)
    80004b46:	7a02                	ld	s4,32(sp)
    80004b48:	6ae2                	ld	s5,24(sp)
    80004b4a:	6b42                	ld	s6,16(sp)
    80004b4c:	6161                	addi	sp,sp,80
    80004b4e:	8082                	ret
      release(&pi->lock);
    80004b50:	8526                	mv	a0,s1
    80004b52:	ffffc097          	auipc	ra,0xffffc
    80004b56:	17a080e7          	jalr	378(ra) # 80000ccc <release>
      return -1;
    80004b5a:	59fd                	li	s3,-1
    80004b5c:	bff9                	j	80004b3a <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b5e:	4981                	li	s3,0
    80004b60:	b7d1                	j	80004b24 <piperead+0xae>

0000000080004b62 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004b62:	df010113          	addi	sp,sp,-528
    80004b66:	20113423          	sd	ra,520(sp)
    80004b6a:	20813023          	sd	s0,512(sp)
    80004b6e:	ffa6                	sd	s1,504(sp)
    80004b70:	fbca                	sd	s2,496(sp)
    80004b72:	f7ce                	sd	s3,488(sp)
    80004b74:	f3d2                	sd	s4,480(sp)
    80004b76:	efd6                	sd	s5,472(sp)
    80004b78:	ebda                	sd	s6,464(sp)
    80004b7a:	e7de                	sd	s7,456(sp)
    80004b7c:	e3e2                	sd	s8,448(sp)
    80004b7e:	ff66                	sd	s9,440(sp)
    80004b80:	fb6a                	sd	s10,432(sp)
    80004b82:	f76e                	sd	s11,424(sp)
    80004b84:	0c00                	addi	s0,sp,528
    80004b86:	84aa                	mv	s1,a0
    80004b88:	dea43c23          	sd	a0,-520(s0)
    80004b8c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b90:	ffffd097          	auipc	ra,0xffffd
    80004b94:	e72080e7          	jalr	-398(ra) # 80001a02 <myproc>
    80004b98:	892a                	mv	s2,a0

  begin_op();
    80004b9a:	fffff097          	auipc	ra,0xfffff
    80004b9e:	444080e7          	jalr	1092(ra) # 80003fde <begin_op>

  if((ip = namei(path)) == 0){
    80004ba2:	8526                	mv	a0,s1
    80004ba4:	fffff097          	auipc	ra,0xfffff
    80004ba8:	21e080e7          	jalr	542(ra) # 80003dc2 <namei>
    80004bac:	c92d                	beqz	a0,80004c1e <exec+0xbc>
    80004bae:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004bb0:	fffff097          	auipc	ra,0xfffff
    80004bb4:	a5e080e7          	jalr	-1442(ra) # 8000360e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004bb8:	04000713          	li	a4,64
    80004bbc:	4681                	li	a3,0
    80004bbe:	e4840613          	addi	a2,s0,-440
    80004bc2:	4581                	li	a1,0
    80004bc4:	8526                	mv	a0,s1
    80004bc6:	fffff097          	auipc	ra,0xfffff
    80004bca:	cfc080e7          	jalr	-772(ra) # 800038c2 <readi>
    80004bce:	04000793          	li	a5,64
    80004bd2:	00f51a63          	bne	a0,a5,80004be6 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004bd6:	e4842703          	lw	a4,-440(s0)
    80004bda:	464c47b7          	lui	a5,0x464c4
    80004bde:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004be2:	04f70463          	beq	a4,a5,80004c2a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004be6:	8526                	mv	a0,s1
    80004be8:	fffff097          	auipc	ra,0xfffff
    80004bec:	c88080e7          	jalr	-888(ra) # 80003870 <iunlockput>
    end_op();
    80004bf0:	fffff097          	auipc	ra,0xfffff
    80004bf4:	46e080e7          	jalr	1134(ra) # 8000405e <end_op>
  }
  return -1;
    80004bf8:	557d                	li	a0,-1
}
    80004bfa:	20813083          	ld	ra,520(sp)
    80004bfe:	20013403          	ld	s0,512(sp)
    80004c02:	74fe                	ld	s1,504(sp)
    80004c04:	795e                	ld	s2,496(sp)
    80004c06:	79be                	ld	s3,488(sp)
    80004c08:	7a1e                	ld	s4,480(sp)
    80004c0a:	6afe                	ld	s5,472(sp)
    80004c0c:	6b5e                	ld	s6,464(sp)
    80004c0e:	6bbe                	ld	s7,456(sp)
    80004c10:	6c1e                	ld	s8,448(sp)
    80004c12:	7cfa                	ld	s9,440(sp)
    80004c14:	7d5a                	ld	s10,432(sp)
    80004c16:	7dba                	ld	s11,424(sp)
    80004c18:	21010113          	addi	sp,sp,528
    80004c1c:	8082                	ret
    end_op();
    80004c1e:	fffff097          	auipc	ra,0xfffff
    80004c22:	440080e7          	jalr	1088(ra) # 8000405e <end_op>
    return -1;
    80004c26:	557d                	li	a0,-1
    80004c28:	bfc9                	j	80004bfa <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c2a:	854a                	mv	a0,s2
    80004c2c:	ffffd097          	auipc	ra,0xffffd
    80004c30:	e9a080e7          	jalr	-358(ra) # 80001ac6 <proc_pagetable>
    80004c34:	8baa                	mv	s7,a0
    80004c36:	d945                	beqz	a0,80004be6 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c38:	e6842983          	lw	s3,-408(s0)
    80004c3c:	e8045783          	lhu	a5,-384(s0)
    80004c40:	c7ad                	beqz	a5,80004caa <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004c42:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c44:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004c46:	6c85                	lui	s9,0x1
    80004c48:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004c4c:	def43823          	sd	a5,-528(s0)
    80004c50:	a42d                	j	80004e7a <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004c52:	00004517          	auipc	a0,0x4
    80004c56:	a5e50513          	addi	a0,a0,-1442 # 800086b0 <syscalls+0x290>
    80004c5a:	ffffc097          	auipc	ra,0xffffc
    80004c5e:	8f6080e7          	jalr	-1802(ra) # 80000550 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c62:	8756                	mv	a4,s5
    80004c64:	012d86bb          	addw	a3,s11,s2
    80004c68:	4581                	li	a1,0
    80004c6a:	8526                	mv	a0,s1
    80004c6c:	fffff097          	auipc	ra,0xfffff
    80004c70:	c56080e7          	jalr	-938(ra) # 800038c2 <readi>
    80004c74:	2501                	sext.w	a0,a0
    80004c76:	1aaa9963          	bne	s5,a0,80004e28 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004c7a:	6785                	lui	a5,0x1
    80004c7c:	0127893b          	addw	s2,a5,s2
    80004c80:	77fd                	lui	a5,0xfffff
    80004c82:	01478a3b          	addw	s4,a5,s4
    80004c86:	1f897163          	bgeu	s2,s8,80004e68 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004c8a:	02091593          	slli	a1,s2,0x20
    80004c8e:	9181                	srli	a1,a1,0x20
    80004c90:	95ea                	add	a1,a1,s10
    80004c92:	855e                	mv	a0,s7
    80004c94:	ffffc097          	auipc	ra,0xffffc
    80004c98:	412080e7          	jalr	1042(ra) # 800010a6 <walkaddr>
    80004c9c:	862a                	mv	a2,a0
    if(pa == 0)
    80004c9e:	d955                	beqz	a0,80004c52 <exec+0xf0>
      n = PGSIZE;
    80004ca0:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004ca2:	fd9a70e3          	bgeu	s4,s9,80004c62 <exec+0x100>
      n = sz - i;
    80004ca6:	8ad2                	mv	s5,s4
    80004ca8:	bf6d                	j	80004c62 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004caa:	4901                	li	s2,0
  iunlockput(ip);
    80004cac:	8526                	mv	a0,s1
    80004cae:	fffff097          	auipc	ra,0xfffff
    80004cb2:	bc2080e7          	jalr	-1086(ra) # 80003870 <iunlockput>
  end_op();
    80004cb6:	fffff097          	auipc	ra,0xfffff
    80004cba:	3a8080e7          	jalr	936(ra) # 8000405e <end_op>
  p = myproc();
    80004cbe:	ffffd097          	auipc	ra,0xffffd
    80004cc2:	d44080e7          	jalr	-700(ra) # 80001a02 <myproc>
    80004cc6:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004cc8:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004ccc:	6785                	lui	a5,0x1
    80004cce:	17fd                	addi	a5,a5,-1
    80004cd0:	993e                	add	s2,s2,a5
    80004cd2:	757d                	lui	a0,0xfffff
    80004cd4:	00a977b3          	and	a5,s2,a0
    80004cd8:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004cdc:	6609                	lui	a2,0x2
    80004cde:	963e                	add	a2,a2,a5
    80004ce0:	85be                	mv	a1,a5
    80004ce2:	855e                	mv	a0,s7
    80004ce4:	ffffc097          	auipc	ra,0xffffc
    80004ce8:	764080e7          	jalr	1892(ra) # 80001448 <uvmalloc>
    80004cec:	8b2a                	mv	s6,a0
  ip = 0;
    80004cee:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004cf0:	12050c63          	beqz	a0,80004e28 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004cf4:	75f9                	lui	a1,0xffffe
    80004cf6:	95aa                	add	a1,a1,a0
    80004cf8:	855e                	mv	a0,s7
    80004cfa:	ffffd097          	auipc	ra,0xffffd
    80004cfe:	96c080e7          	jalr	-1684(ra) # 80001666 <uvmclear>
  stackbase = sp - PGSIZE;
    80004d02:	7c7d                	lui	s8,0xfffff
    80004d04:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004d06:	e0043783          	ld	a5,-512(s0)
    80004d0a:	6388                	ld	a0,0(a5)
    80004d0c:	c535                	beqz	a0,80004d78 <exec+0x216>
    80004d0e:	e8840993          	addi	s3,s0,-376
    80004d12:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004d16:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004d18:	ffffc097          	auipc	ra,0xffffc
    80004d1c:	184080e7          	jalr	388(ra) # 80000e9c <strlen>
    80004d20:	2505                	addiw	a0,a0,1
    80004d22:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d26:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004d2a:	13896363          	bltu	s2,s8,80004e50 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d2e:	e0043d83          	ld	s11,-512(s0)
    80004d32:	000dba03          	ld	s4,0(s11)
    80004d36:	8552                	mv	a0,s4
    80004d38:	ffffc097          	auipc	ra,0xffffc
    80004d3c:	164080e7          	jalr	356(ra) # 80000e9c <strlen>
    80004d40:	0015069b          	addiw	a3,a0,1
    80004d44:	8652                	mv	a2,s4
    80004d46:	85ca                	mv	a1,s2
    80004d48:	855e                	mv	a0,s7
    80004d4a:	ffffd097          	auipc	ra,0xffffd
    80004d4e:	94e080e7          	jalr	-1714(ra) # 80001698 <copyout>
    80004d52:	10054363          	bltz	a0,80004e58 <exec+0x2f6>
    ustack[argc] = sp;
    80004d56:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004d5a:	0485                	addi	s1,s1,1
    80004d5c:	008d8793          	addi	a5,s11,8
    80004d60:	e0f43023          	sd	a5,-512(s0)
    80004d64:	008db503          	ld	a0,8(s11)
    80004d68:	c911                	beqz	a0,80004d7c <exec+0x21a>
    if(argc >= MAXARG)
    80004d6a:	09a1                	addi	s3,s3,8
    80004d6c:	fb3c96e3          	bne	s9,s3,80004d18 <exec+0x1b6>
  sz = sz1;
    80004d70:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004d74:	4481                	li	s1,0
    80004d76:	a84d                	j	80004e28 <exec+0x2c6>
  sp = sz;
    80004d78:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004d7a:	4481                	li	s1,0
  ustack[argc] = 0;
    80004d7c:	00349793          	slli	a5,s1,0x3
    80004d80:	f9040713          	addi	a4,s0,-112
    80004d84:	97ba                	add	a5,a5,a4
    80004d86:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004d8a:	00148693          	addi	a3,s1,1
    80004d8e:	068e                	slli	a3,a3,0x3
    80004d90:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004d94:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004d98:	01897663          	bgeu	s2,s8,80004da4 <exec+0x242>
  sz = sz1;
    80004d9c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004da0:	4481                	li	s1,0
    80004da2:	a059                	j	80004e28 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004da4:	e8840613          	addi	a2,s0,-376
    80004da8:	85ca                	mv	a1,s2
    80004daa:	855e                	mv	a0,s7
    80004dac:	ffffd097          	auipc	ra,0xffffd
    80004db0:	8ec080e7          	jalr	-1812(ra) # 80001698 <copyout>
    80004db4:	0a054663          	bltz	a0,80004e60 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004db8:	058ab783          	ld	a5,88(s5)
    80004dbc:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004dc0:	df843783          	ld	a5,-520(s0)
    80004dc4:	0007c703          	lbu	a4,0(a5)
    80004dc8:	cf11                	beqz	a4,80004de4 <exec+0x282>
    80004dca:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004dcc:	02f00693          	li	a3,47
    80004dd0:	a029                	j	80004dda <exec+0x278>
  for(last=s=path; *s; s++)
    80004dd2:	0785                	addi	a5,a5,1
    80004dd4:	fff7c703          	lbu	a4,-1(a5)
    80004dd8:	c711                	beqz	a4,80004de4 <exec+0x282>
    if(*s == '/')
    80004dda:	fed71ce3          	bne	a4,a3,80004dd2 <exec+0x270>
      last = s+1;
    80004dde:	def43c23          	sd	a5,-520(s0)
    80004de2:	bfc5                	j	80004dd2 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004de4:	4641                	li	a2,16
    80004de6:	df843583          	ld	a1,-520(s0)
    80004dea:	158a8513          	addi	a0,s5,344
    80004dee:	ffffc097          	auipc	ra,0xffffc
    80004df2:	07c080e7          	jalr	124(ra) # 80000e6a <safestrcpy>
  oldpagetable = p->pagetable;
    80004df6:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004dfa:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004dfe:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e02:	058ab783          	ld	a5,88(s5)
    80004e06:	e6043703          	ld	a4,-416(s0)
    80004e0a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e0c:	058ab783          	ld	a5,88(s5)
    80004e10:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e14:	85ea                	mv	a1,s10
    80004e16:	ffffd097          	auipc	ra,0xffffd
    80004e1a:	d4c080e7          	jalr	-692(ra) # 80001b62 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e1e:	0004851b          	sext.w	a0,s1
    80004e22:	bbe1                	j	80004bfa <exec+0x98>
    80004e24:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004e28:	e0843583          	ld	a1,-504(s0)
    80004e2c:	855e                	mv	a0,s7
    80004e2e:	ffffd097          	auipc	ra,0xffffd
    80004e32:	d34080e7          	jalr	-716(ra) # 80001b62 <proc_freepagetable>
  if(ip){
    80004e36:	da0498e3          	bnez	s1,80004be6 <exec+0x84>
  return -1;
    80004e3a:	557d                	li	a0,-1
    80004e3c:	bb7d                	j	80004bfa <exec+0x98>
    80004e3e:	e1243423          	sd	s2,-504(s0)
    80004e42:	b7dd                	j	80004e28 <exec+0x2c6>
    80004e44:	e1243423          	sd	s2,-504(s0)
    80004e48:	b7c5                	j	80004e28 <exec+0x2c6>
    80004e4a:	e1243423          	sd	s2,-504(s0)
    80004e4e:	bfe9                	j	80004e28 <exec+0x2c6>
  sz = sz1;
    80004e50:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e54:	4481                	li	s1,0
    80004e56:	bfc9                	j	80004e28 <exec+0x2c6>
  sz = sz1;
    80004e58:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e5c:	4481                	li	s1,0
    80004e5e:	b7e9                	j	80004e28 <exec+0x2c6>
  sz = sz1;
    80004e60:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e64:	4481                	li	s1,0
    80004e66:	b7c9                	j	80004e28 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e68:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e6c:	2b05                	addiw	s6,s6,1
    80004e6e:	0389899b          	addiw	s3,s3,56
    80004e72:	e8045783          	lhu	a5,-384(s0)
    80004e76:	e2fb5be3          	bge	s6,a5,80004cac <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e7a:	2981                	sext.w	s3,s3
    80004e7c:	03800713          	li	a4,56
    80004e80:	86ce                	mv	a3,s3
    80004e82:	e1040613          	addi	a2,s0,-496
    80004e86:	4581                	li	a1,0
    80004e88:	8526                	mv	a0,s1
    80004e8a:	fffff097          	auipc	ra,0xfffff
    80004e8e:	a38080e7          	jalr	-1480(ra) # 800038c2 <readi>
    80004e92:	03800793          	li	a5,56
    80004e96:	f8f517e3          	bne	a0,a5,80004e24 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004e9a:	e1042783          	lw	a5,-496(s0)
    80004e9e:	4705                	li	a4,1
    80004ea0:	fce796e3          	bne	a5,a4,80004e6c <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004ea4:	e3843603          	ld	a2,-456(s0)
    80004ea8:	e3043783          	ld	a5,-464(s0)
    80004eac:	f8f669e3          	bltu	a2,a5,80004e3e <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004eb0:	e2043783          	ld	a5,-480(s0)
    80004eb4:	963e                	add	a2,a2,a5
    80004eb6:	f8f667e3          	bltu	a2,a5,80004e44 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004eba:	85ca                	mv	a1,s2
    80004ebc:	855e                	mv	a0,s7
    80004ebe:	ffffc097          	auipc	ra,0xffffc
    80004ec2:	58a080e7          	jalr	1418(ra) # 80001448 <uvmalloc>
    80004ec6:	e0a43423          	sd	a0,-504(s0)
    80004eca:	d141                	beqz	a0,80004e4a <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80004ecc:	e2043d03          	ld	s10,-480(s0)
    80004ed0:	df043783          	ld	a5,-528(s0)
    80004ed4:	00fd77b3          	and	a5,s10,a5
    80004ed8:	fba1                	bnez	a5,80004e28 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004eda:	e1842d83          	lw	s11,-488(s0)
    80004ede:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004ee2:	f80c03e3          	beqz	s8,80004e68 <exec+0x306>
    80004ee6:	8a62                	mv	s4,s8
    80004ee8:	4901                	li	s2,0
    80004eea:	b345                	j	80004c8a <exec+0x128>

0000000080004eec <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004eec:	7179                	addi	sp,sp,-48
    80004eee:	f406                	sd	ra,40(sp)
    80004ef0:	f022                	sd	s0,32(sp)
    80004ef2:	ec26                	sd	s1,24(sp)
    80004ef4:	e84a                	sd	s2,16(sp)
    80004ef6:	1800                	addi	s0,sp,48
    80004ef8:	892e                	mv	s2,a1
    80004efa:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004efc:	fdc40593          	addi	a1,s0,-36
    80004f00:	ffffe097          	auipc	ra,0xffffe
    80004f04:	b9c080e7          	jalr	-1124(ra) # 80002a9c <argint>
    80004f08:	04054063          	bltz	a0,80004f48 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f0c:	fdc42703          	lw	a4,-36(s0)
    80004f10:	47bd                	li	a5,15
    80004f12:	02e7ed63          	bltu	a5,a4,80004f4c <argfd+0x60>
    80004f16:	ffffd097          	auipc	ra,0xffffd
    80004f1a:	aec080e7          	jalr	-1300(ra) # 80001a02 <myproc>
    80004f1e:	fdc42703          	lw	a4,-36(s0)
    80004f22:	01a70793          	addi	a5,a4,26
    80004f26:	078e                	slli	a5,a5,0x3
    80004f28:	953e                	add	a0,a0,a5
    80004f2a:	611c                	ld	a5,0(a0)
    80004f2c:	c395                	beqz	a5,80004f50 <argfd+0x64>
    return -1;
  if(pfd)
    80004f2e:	00090463          	beqz	s2,80004f36 <argfd+0x4a>
    *pfd = fd;
    80004f32:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004f36:	4501                	li	a0,0
  if(pf)
    80004f38:	c091                	beqz	s1,80004f3c <argfd+0x50>
    *pf = f;
    80004f3a:	e09c                	sd	a5,0(s1)
}
    80004f3c:	70a2                	ld	ra,40(sp)
    80004f3e:	7402                	ld	s0,32(sp)
    80004f40:	64e2                	ld	s1,24(sp)
    80004f42:	6942                	ld	s2,16(sp)
    80004f44:	6145                	addi	sp,sp,48
    80004f46:	8082                	ret
    return -1;
    80004f48:	557d                	li	a0,-1
    80004f4a:	bfcd                	j	80004f3c <argfd+0x50>
    return -1;
    80004f4c:	557d                	li	a0,-1
    80004f4e:	b7fd                	j	80004f3c <argfd+0x50>
    80004f50:	557d                	li	a0,-1
    80004f52:	b7ed                	j	80004f3c <argfd+0x50>

0000000080004f54 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f54:	1101                	addi	sp,sp,-32
    80004f56:	ec06                	sd	ra,24(sp)
    80004f58:	e822                	sd	s0,16(sp)
    80004f5a:	e426                	sd	s1,8(sp)
    80004f5c:	1000                	addi	s0,sp,32
    80004f5e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004f60:	ffffd097          	auipc	ra,0xffffd
    80004f64:	aa2080e7          	jalr	-1374(ra) # 80001a02 <myproc>
    80004f68:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f6a:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80004f6e:	4501                	li	a0,0
    80004f70:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004f72:	6398                	ld	a4,0(a5)
    80004f74:	cb19                	beqz	a4,80004f8a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004f76:	2505                	addiw	a0,a0,1
    80004f78:	07a1                	addi	a5,a5,8
    80004f7a:	fed51ce3          	bne	a0,a3,80004f72 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004f7e:	557d                	li	a0,-1
}
    80004f80:	60e2                	ld	ra,24(sp)
    80004f82:	6442                	ld	s0,16(sp)
    80004f84:	64a2                	ld	s1,8(sp)
    80004f86:	6105                	addi	sp,sp,32
    80004f88:	8082                	ret
      p->ofile[fd] = f;
    80004f8a:	01a50793          	addi	a5,a0,26
    80004f8e:	078e                	slli	a5,a5,0x3
    80004f90:	963e                	add	a2,a2,a5
    80004f92:	e204                	sd	s1,0(a2)
      return fd;
    80004f94:	b7f5                	j	80004f80 <fdalloc+0x2c>

0000000080004f96 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f96:	715d                	addi	sp,sp,-80
    80004f98:	e486                	sd	ra,72(sp)
    80004f9a:	e0a2                	sd	s0,64(sp)
    80004f9c:	fc26                	sd	s1,56(sp)
    80004f9e:	f84a                	sd	s2,48(sp)
    80004fa0:	f44e                	sd	s3,40(sp)
    80004fa2:	f052                	sd	s4,32(sp)
    80004fa4:	ec56                	sd	s5,24(sp)
    80004fa6:	0880                	addi	s0,sp,80
    80004fa8:	89ae                	mv	s3,a1
    80004faa:	8ab2                	mv	s5,a2
    80004fac:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004fae:	fb040593          	addi	a1,s0,-80
    80004fb2:	fffff097          	auipc	ra,0xfffff
    80004fb6:	e2e080e7          	jalr	-466(ra) # 80003de0 <nameiparent>
    80004fba:	892a                	mv	s2,a0
    80004fbc:	12050f63          	beqz	a0,800050fa <create+0x164>
    return 0;

  ilock(dp);
    80004fc0:	ffffe097          	auipc	ra,0xffffe
    80004fc4:	64e080e7          	jalr	1614(ra) # 8000360e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004fc8:	4601                	li	a2,0
    80004fca:	fb040593          	addi	a1,s0,-80
    80004fce:	854a                	mv	a0,s2
    80004fd0:	fffff097          	auipc	ra,0xfffff
    80004fd4:	b20080e7          	jalr	-1248(ra) # 80003af0 <dirlookup>
    80004fd8:	84aa                	mv	s1,a0
    80004fda:	c921                	beqz	a0,8000502a <create+0x94>
    iunlockput(dp);
    80004fdc:	854a                	mv	a0,s2
    80004fde:	fffff097          	auipc	ra,0xfffff
    80004fe2:	892080e7          	jalr	-1902(ra) # 80003870 <iunlockput>
    ilock(ip);
    80004fe6:	8526                	mv	a0,s1
    80004fe8:	ffffe097          	auipc	ra,0xffffe
    80004fec:	626080e7          	jalr	1574(ra) # 8000360e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004ff0:	2981                	sext.w	s3,s3
    80004ff2:	4789                	li	a5,2
    80004ff4:	02f99463          	bne	s3,a5,8000501c <create+0x86>
    80004ff8:	0444d783          	lhu	a5,68(s1)
    80004ffc:	37f9                	addiw	a5,a5,-2
    80004ffe:	17c2                	slli	a5,a5,0x30
    80005000:	93c1                	srli	a5,a5,0x30
    80005002:	4705                	li	a4,1
    80005004:	00f76c63          	bltu	a4,a5,8000501c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005008:	8526                	mv	a0,s1
    8000500a:	60a6                	ld	ra,72(sp)
    8000500c:	6406                	ld	s0,64(sp)
    8000500e:	74e2                	ld	s1,56(sp)
    80005010:	7942                	ld	s2,48(sp)
    80005012:	79a2                	ld	s3,40(sp)
    80005014:	7a02                	ld	s4,32(sp)
    80005016:	6ae2                	ld	s5,24(sp)
    80005018:	6161                	addi	sp,sp,80
    8000501a:	8082                	ret
    iunlockput(ip);
    8000501c:	8526                	mv	a0,s1
    8000501e:	fffff097          	auipc	ra,0xfffff
    80005022:	852080e7          	jalr	-1966(ra) # 80003870 <iunlockput>
    return 0;
    80005026:	4481                	li	s1,0
    80005028:	b7c5                	j	80005008 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000502a:	85ce                	mv	a1,s3
    8000502c:	00092503          	lw	a0,0(s2)
    80005030:	ffffe097          	auipc	ra,0xffffe
    80005034:	446080e7          	jalr	1094(ra) # 80003476 <ialloc>
    80005038:	84aa                	mv	s1,a0
    8000503a:	c529                	beqz	a0,80005084 <create+0xee>
  ilock(ip);
    8000503c:	ffffe097          	auipc	ra,0xffffe
    80005040:	5d2080e7          	jalr	1490(ra) # 8000360e <ilock>
  ip->major = major;
    80005044:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005048:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000504c:	4785                	li	a5,1
    8000504e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005052:	8526                	mv	a0,s1
    80005054:	ffffe097          	auipc	ra,0xffffe
    80005058:	4f0080e7          	jalr	1264(ra) # 80003544 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000505c:	2981                	sext.w	s3,s3
    8000505e:	4785                	li	a5,1
    80005060:	02f98a63          	beq	s3,a5,80005094 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005064:	40d0                	lw	a2,4(s1)
    80005066:	fb040593          	addi	a1,s0,-80
    8000506a:	854a                	mv	a0,s2
    8000506c:	fffff097          	auipc	ra,0xfffff
    80005070:	c94080e7          	jalr	-876(ra) # 80003d00 <dirlink>
    80005074:	06054b63          	bltz	a0,800050ea <create+0x154>
  iunlockput(dp);
    80005078:	854a                	mv	a0,s2
    8000507a:	ffffe097          	auipc	ra,0xffffe
    8000507e:	7f6080e7          	jalr	2038(ra) # 80003870 <iunlockput>
  return ip;
    80005082:	b759                	j	80005008 <create+0x72>
    panic("create: ialloc");
    80005084:	00003517          	auipc	a0,0x3
    80005088:	64c50513          	addi	a0,a0,1612 # 800086d0 <syscalls+0x2b0>
    8000508c:	ffffb097          	auipc	ra,0xffffb
    80005090:	4c4080e7          	jalr	1220(ra) # 80000550 <panic>
    dp->nlink++;  // for ".."
    80005094:	04a95783          	lhu	a5,74(s2)
    80005098:	2785                	addiw	a5,a5,1
    8000509a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000509e:	854a                	mv	a0,s2
    800050a0:	ffffe097          	auipc	ra,0xffffe
    800050a4:	4a4080e7          	jalr	1188(ra) # 80003544 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800050a8:	40d0                	lw	a2,4(s1)
    800050aa:	00003597          	auipc	a1,0x3
    800050ae:	63658593          	addi	a1,a1,1590 # 800086e0 <syscalls+0x2c0>
    800050b2:	8526                	mv	a0,s1
    800050b4:	fffff097          	auipc	ra,0xfffff
    800050b8:	c4c080e7          	jalr	-948(ra) # 80003d00 <dirlink>
    800050bc:	00054f63          	bltz	a0,800050da <create+0x144>
    800050c0:	00492603          	lw	a2,4(s2)
    800050c4:	00003597          	auipc	a1,0x3
    800050c8:	62458593          	addi	a1,a1,1572 # 800086e8 <syscalls+0x2c8>
    800050cc:	8526                	mv	a0,s1
    800050ce:	fffff097          	auipc	ra,0xfffff
    800050d2:	c32080e7          	jalr	-974(ra) # 80003d00 <dirlink>
    800050d6:	f80557e3          	bgez	a0,80005064 <create+0xce>
      panic("create dots");
    800050da:	00003517          	auipc	a0,0x3
    800050de:	61650513          	addi	a0,a0,1558 # 800086f0 <syscalls+0x2d0>
    800050e2:	ffffb097          	auipc	ra,0xffffb
    800050e6:	46e080e7          	jalr	1134(ra) # 80000550 <panic>
    panic("create: dirlink");
    800050ea:	00003517          	auipc	a0,0x3
    800050ee:	61650513          	addi	a0,a0,1558 # 80008700 <syscalls+0x2e0>
    800050f2:	ffffb097          	auipc	ra,0xffffb
    800050f6:	45e080e7          	jalr	1118(ra) # 80000550 <panic>
    return 0;
    800050fa:	84aa                	mv	s1,a0
    800050fc:	b731                	j	80005008 <create+0x72>

00000000800050fe <sys_dup>:
{
    800050fe:	7179                	addi	sp,sp,-48
    80005100:	f406                	sd	ra,40(sp)
    80005102:	f022                	sd	s0,32(sp)
    80005104:	ec26                	sd	s1,24(sp)
    80005106:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005108:	fd840613          	addi	a2,s0,-40
    8000510c:	4581                	li	a1,0
    8000510e:	4501                	li	a0,0
    80005110:	00000097          	auipc	ra,0x0
    80005114:	ddc080e7          	jalr	-548(ra) # 80004eec <argfd>
    return -1;
    80005118:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000511a:	02054363          	bltz	a0,80005140 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000511e:	fd843503          	ld	a0,-40(s0)
    80005122:	00000097          	auipc	ra,0x0
    80005126:	e32080e7          	jalr	-462(ra) # 80004f54 <fdalloc>
    8000512a:	84aa                	mv	s1,a0
    return -1;
    8000512c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000512e:	00054963          	bltz	a0,80005140 <sys_dup+0x42>
  filedup(f);
    80005132:	fd843503          	ld	a0,-40(s0)
    80005136:	fffff097          	auipc	ra,0xfffff
    8000513a:	32a080e7          	jalr	810(ra) # 80004460 <filedup>
  return fd;
    8000513e:	87a6                	mv	a5,s1
}
    80005140:	853e                	mv	a0,a5
    80005142:	70a2                	ld	ra,40(sp)
    80005144:	7402                	ld	s0,32(sp)
    80005146:	64e2                	ld	s1,24(sp)
    80005148:	6145                	addi	sp,sp,48
    8000514a:	8082                	ret

000000008000514c <sys_read>:
{
    8000514c:	7179                	addi	sp,sp,-48
    8000514e:	f406                	sd	ra,40(sp)
    80005150:	f022                	sd	s0,32(sp)
    80005152:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005154:	fe840613          	addi	a2,s0,-24
    80005158:	4581                	li	a1,0
    8000515a:	4501                	li	a0,0
    8000515c:	00000097          	auipc	ra,0x0
    80005160:	d90080e7          	jalr	-624(ra) # 80004eec <argfd>
    return -1;
    80005164:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005166:	04054163          	bltz	a0,800051a8 <sys_read+0x5c>
    8000516a:	fe440593          	addi	a1,s0,-28
    8000516e:	4509                	li	a0,2
    80005170:	ffffe097          	auipc	ra,0xffffe
    80005174:	92c080e7          	jalr	-1748(ra) # 80002a9c <argint>
    return -1;
    80005178:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000517a:	02054763          	bltz	a0,800051a8 <sys_read+0x5c>
    8000517e:	fd840593          	addi	a1,s0,-40
    80005182:	4505                	li	a0,1
    80005184:	ffffe097          	auipc	ra,0xffffe
    80005188:	93a080e7          	jalr	-1734(ra) # 80002abe <argaddr>
    return -1;
    8000518c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000518e:	00054d63          	bltz	a0,800051a8 <sys_read+0x5c>
  return fileread(f, p, n);
    80005192:	fe442603          	lw	a2,-28(s0)
    80005196:	fd843583          	ld	a1,-40(s0)
    8000519a:	fe843503          	ld	a0,-24(s0)
    8000519e:	fffff097          	auipc	ra,0xfffff
    800051a2:	44e080e7          	jalr	1102(ra) # 800045ec <fileread>
    800051a6:	87aa                	mv	a5,a0
}
    800051a8:	853e                	mv	a0,a5
    800051aa:	70a2                	ld	ra,40(sp)
    800051ac:	7402                	ld	s0,32(sp)
    800051ae:	6145                	addi	sp,sp,48
    800051b0:	8082                	ret

00000000800051b2 <sys_write>:
{
    800051b2:	7179                	addi	sp,sp,-48
    800051b4:	f406                	sd	ra,40(sp)
    800051b6:	f022                	sd	s0,32(sp)
    800051b8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051ba:	fe840613          	addi	a2,s0,-24
    800051be:	4581                	li	a1,0
    800051c0:	4501                	li	a0,0
    800051c2:	00000097          	auipc	ra,0x0
    800051c6:	d2a080e7          	jalr	-726(ra) # 80004eec <argfd>
    return -1;
    800051ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051cc:	04054163          	bltz	a0,8000520e <sys_write+0x5c>
    800051d0:	fe440593          	addi	a1,s0,-28
    800051d4:	4509                	li	a0,2
    800051d6:	ffffe097          	auipc	ra,0xffffe
    800051da:	8c6080e7          	jalr	-1850(ra) # 80002a9c <argint>
    return -1;
    800051de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051e0:	02054763          	bltz	a0,8000520e <sys_write+0x5c>
    800051e4:	fd840593          	addi	a1,s0,-40
    800051e8:	4505                	li	a0,1
    800051ea:	ffffe097          	auipc	ra,0xffffe
    800051ee:	8d4080e7          	jalr	-1836(ra) # 80002abe <argaddr>
    return -1;
    800051f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051f4:	00054d63          	bltz	a0,8000520e <sys_write+0x5c>
  return filewrite(f, p, n);
    800051f8:	fe442603          	lw	a2,-28(s0)
    800051fc:	fd843583          	ld	a1,-40(s0)
    80005200:	fe843503          	ld	a0,-24(s0)
    80005204:	fffff097          	auipc	ra,0xfffff
    80005208:	4aa080e7          	jalr	1194(ra) # 800046ae <filewrite>
    8000520c:	87aa                	mv	a5,a0
}
    8000520e:	853e                	mv	a0,a5
    80005210:	70a2                	ld	ra,40(sp)
    80005212:	7402                	ld	s0,32(sp)
    80005214:	6145                	addi	sp,sp,48
    80005216:	8082                	ret

0000000080005218 <sys_close>:
{
    80005218:	1101                	addi	sp,sp,-32
    8000521a:	ec06                	sd	ra,24(sp)
    8000521c:	e822                	sd	s0,16(sp)
    8000521e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005220:	fe040613          	addi	a2,s0,-32
    80005224:	fec40593          	addi	a1,s0,-20
    80005228:	4501                	li	a0,0
    8000522a:	00000097          	auipc	ra,0x0
    8000522e:	cc2080e7          	jalr	-830(ra) # 80004eec <argfd>
    return -1;
    80005232:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005234:	02054463          	bltz	a0,8000525c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005238:	ffffc097          	auipc	ra,0xffffc
    8000523c:	7ca080e7          	jalr	1994(ra) # 80001a02 <myproc>
    80005240:	fec42783          	lw	a5,-20(s0)
    80005244:	07e9                	addi	a5,a5,26
    80005246:	078e                	slli	a5,a5,0x3
    80005248:	97aa                	add	a5,a5,a0
    8000524a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000524e:	fe043503          	ld	a0,-32(s0)
    80005252:	fffff097          	auipc	ra,0xfffff
    80005256:	260080e7          	jalr	608(ra) # 800044b2 <fileclose>
  return 0;
    8000525a:	4781                	li	a5,0
}
    8000525c:	853e                	mv	a0,a5
    8000525e:	60e2                	ld	ra,24(sp)
    80005260:	6442                	ld	s0,16(sp)
    80005262:	6105                	addi	sp,sp,32
    80005264:	8082                	ret

0000000080005266 <sys_fstat>:
{
    80005266:	1101                	addi	sp,sp,-32
    80005268:	ec06                	sd	ra,24(sp)
    8000526a:	e822                	sd	s0,16(sp)
    8000526c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000526e:	fe840613          	addi	a2,s0,-24
    80005272:	4581                	li	a1,0
    80005274:	4501                	li	a0,0
    80005276:	00000097          	auipc	ra,0x0
    8000527a:	c76080e7          	jalr	-906(ra) # 80004eec <argfd>
    return -1;
    8000527e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005280:	02054563          	bltz	a0,800052aa <sys_fstat+0x44>
    80005284:	fe040593          	addi	a1,s0,-32
    80005288:	4505                	li	a0,1
    8000528a:	ffffe097          	auipc	ra,0xffffe
    8000528e:	834080e7          	jalr	-1996(ra) # 80002abe <argaddr>
    return -1;
    80005292:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005294:	00054b63          	bltz	a0,800052aa <sys_fstat+0x44>
  return filestat(f, st);
    80005298:	fe043583          	ld	a1,-32(s0)
    8000529c:	fe843503          	ld	a0,-24(s0)
    800052a0:	fffff097          	auipc	ra,0xfffff
    800052a4:	2da080e7          	jalr	730(ra) # 8000457a <filestat>
    800052a8:	87aa                	mv	a5,a0
}
    800052aa:	853e                	mv	a0,a5
    800052ac:	60e2                	ld	ra,24(sp)
    800052ae:	6442                	ld	s0,16(sp)
    800052b0:	6105                	addi	sp,sp,32
    800052b2:	8082                	ret

00000000800052b4 <sys_link>:
{
    800052b4:	7169                	addi	sp,sp,-304
    800052b6:	f606                	sd	ra,296(sp)
    800052b8:	f222                	sd	s0,288(sp)
    800052ba:	ee26                	sd	s1,280(sp)
    800052bc:	ea4a                	sd	s2,272(sp)
    800052be:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052c0:	08000613          	li	a2,128
    800052c4:	ed040593          	addi	a1,s0,-304
    800052c8:	4501                	li	a0,0
    800052ca:	ffffe097          	auipc	ra,0xffffe
    800052ce:	816080e7          	jalr	-2026(ra) # 80002ae0 <argstr>
    return -1;
    800052d2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052d4:	10054e63          	bltz	a0,800053f0 <sys_link+0x13c>
    800052d8:	08000613          	li	a2,128
    800052dc:	f5040593          	addi	a1,s0,-176
    800052e0:	4505                	li	a0,1
    800052e2:	ffffd097          	auipc	ra,0xffffd
    800052e6:	7fe080e7          	jalr	2046(ra) # 80002ae0 <argstr>
    return -1;
    800052ea:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052ec:	10054263          	bltz	a0,800053f0 <sys_link+0x13c>
  begin_op();
    800052f0:	fffff097          	auipc	ra,0xfffff
    800052f4:	cee080e7          	jalr	-786(ra) # 80003fde <begin_op>
  if((ip = namei(old)) == 0){
    800052f8:	ed040513          	addi	a0,s0,-304
    800052fc:	fffff097          	auipc	ra,0xfffff
    80005300:	ac6080e7          	jalr	-1338(ra) # 80003dc2 <namei>
    80005304:	84aa                	mv	s1,a0
    80005306:	c551                	beqz	a0,80005392 <sys_link+0xde>
  ilock(ip);
    80005308:	ffffe097          	auipc	ra,0xffffe
    8000530c:	306080e7          	jalr	774(ra) # 8000360e <ilock>
  if(ip->type == T_DIR){
    80005310:	04449703          	lh	a4,68(s1)
    80005314:	4785                	li	a5,1
    80005316:	08f70463          	beq	a4,a5,8000539e <sys_link+0xea>
  ip->nlink++;
    8000531a:	04a4d783          	lhu	a5,74(s1)
    8000531e:	2785                	addiw	a5,a5,1
    80005320:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005324:	8526                	mv	a0,s1
    80005326:	ffffe097          	auipc	ra,0xffffe
    8000532a:	21e080e7          	jalr	542(ra) # 80003544 <iupdate>
  iunlock(ip);
    8000532e:	8526                	mv	a0,s1
    80005330:	ffffe097          	auipc	ra,0xffffe
    80005334:	3a0080e7          	jalr	928(ra) # 800036d0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005338:	fd040593          	addi	a1,s0,-48
    8000533c:	f5040513          	addi	a0,s0,-176
    80005340:	fffff097          	auipc	ra,0xfffff
    80005344:	aa0080e7          	jalr	-1376(ra) # 80003de0 <nameiparent>
    80005348:	892a                	mv	s2,a0
    8000534a:	c935                	beqz	a0,800053be <sys_link+0x10a>
  ilock(dp);
    8000534c:	ffffe097          	auipc	ra,0xffffe
    80005350:	2c2080e7          	jalr	706(ra) # 8000360e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005354:	00092703          	lw	a4,0(s2)
    80005358:	409c                	lw	a5,0(s1)
    8000535a:	04f71d63          	bne	a4,a5,800053b4 <sys_link+0x100>
    8000535e:	40d0                	lw	a2,4(s1)
    80005360:	fd040593          	addi	a1,s0,-48
    80005364:	854a                	mv	a0,s2
    80005366:	fffff097          	auipc	ra,0xfffff
    8000536a:	99a080e7          	jalr	-1638(ra) # 80003d00 <dirlink>
    8000536e:	04054363          	bltz	a0,800053b4 <sys_link+0x100>
  iunlockput(dp);
    80005372:	854a                	mv	a0,s2
    80005374:	ffffe097          	auipc	ra,0xffffe
    80005378:	4fc080e7          	jalr	1276(ra) # 80003870 <iunlockput>
  iput(ip);
    8000537c:	8526                	mv	a0,s1
    8000537e:	ffffe097          	auipc	ra,0xffffe
    80005382:	44a080e7          	jalr	1098(ra) # 800037c8 <iput>
  end_op();
    80005386:	fffff097          	auipc	ra,0xfffff
    8000538a:	cd8080e7          	jalr	-808(ra) # 8000405e <end_op>
  return 0;
    8000538e:	4781                	li	a5,0
    80005390:	a085                	j	800053f0 <sys_link+0x13c>
    end_op();
    80005392:	fffff097          	auipc	ra,0xfffff
    80005396:	ccc080e7          	jalr	-820(ra) # 8000405e <end_op>
    return -1;
    8000539a:	57fd                	li	a5,-1
    8000539c:	a891                	j	800053f0 <sys_link+0x13c>
    iunlockput(ip);
    8000539e:	8526                	mv	a0,s1
    800053a0:	ffffe097          	auipc	ra,0xffffe
    800053a4:	4d0080e7          	jalr	1232(ra) # 80003870 <iunlockput>
    end_op();
    800053a8:	fffff097          	auipc	ra,0xfffff
    800053ac:	cb6080e7          	jalr	-842(ra) # 8000405e <end_op>
    return -1;
    800053b0:	57fd                	li	a5,-1
    800053b2:	a83d                	j	800053f0 <sys_link+0x13c>
    iunlockput(dp);
    800053b4:	854a                	mv	a0,s2
    800053b6:	ffffe097          	auipc	ra,0xffffe
    800053ba:	4ba080e7          	jalr	1210(ra) # 80003870 <iunlockput>
  ilock(ip);
    800053be:	8526                	mv	a0,s1
    800053c0:	ffffe097          	auipc	ra,0xffffe
    800053c4:	24e080e7          	jalr	590(ra) # 8000360e <ilock>
  ip->nlink--;
    800053c8:	04a4d783          	lhu	a5,74(s1)
    800053cc:	37fd                	addiw	a5,a5,-1
    800053ce:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053d2:	8526                	mv	a0,s1
    800053d4:	ffffe097          	auipc	ra,0xffffe
    800053d8:	170080e7          	jalr	368(ra) # 80003544 <iupdate>
  iunlockput(ip);
    800053dc:	8526                	mv	a0,s1
    800053de:	ffffe097          	auipc	ra,0xffffe
    800053e2:	492080e7          	jalr	1170(ra) # 80003870 <iunlockput>
  end_op();
    800053e6:	fffff097          	auipc	ra,0xfffff
    800053ea:	c78080e7          	jalr	-904(ra) # 8000405e <end_op>
  return -1;
    800053ee:	57fd                	li	a5,-1
}
    800053f0:	853e                	mv	a0,a5
    800053f2:	70b2                	ld	ra,296(sp)
    800053f4:	7412                	ld	s0,288(sp)
    800053f6:	64f2                	ld	s1,280(sp)
    800053f8:	6952                	ld	s2,272(sp)
    800053fa:	6155                	addi	sp,sp,304
    800053fc:	8082                	ret

00000000800053fe <sys_unlink>:
{
    800053fe:	7151                	addi	sp,sp,-240
    80005400:	f586                	sd	ra,232(sp)
    80005402:	f1a2                	sd	s0,224(sp)
    80005404:	eda6                	sd	s1,216(sp)
    80005406:	e9ca                	sd	s2,208(sp)
    80005408:	e5ce                	sd	s3,200(sp)
    8000540a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000540c:	08000613          	li	a2,128
    80005410:	f3040593          	addi	a1,s0,-208
    80005414:	4501                	li	a0,0
    80005416:	ffffd097          	auipc	ra,0xffffd
    8000541a:	6ca080e7          	jalr	1738(ra) # 80002ae0 <argstr>
    8000541e:	18054163          	bltz	a0,800055a0 <sys_unlink+0x1a2>
  begin_op();
    80005422:	fffff097          	auipc	ra,0xfffff
    80005426:	bbc080e7          	jalr	-1092(ra) # 80003fde <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000542a:	fb040593          	addi	a1,s0,-80
    8000542e:	f3040513          	addi	a0,s0,-208
    80005432:	fffff097          	auipc	ra,0xfffff
    80005436:	9ae080e7          	jalr	-1618(ra) # 80003de0 <nameiparent>
    8000543a:	84aa                	mv	s1,a0
    8000543c:	c979                	beqz	a0,80005512 <sys_unlink+0x114>
  ilock(dp);
    8000543e:	ffffe097          	auipc	ra,0xffffe
    80005442:	1d0080e7          	jalr	464(ra) # 8000360e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005446:	00003597          	auipc	a1,0x3
    8000544a:	29a58593          	addi	a1,a1,666 # 800086e0 <syscalls+0x2c0>
    8000544e:	fb040513          	addi	a0,s0,-80
    80005452:	ffffe097          	auipc	ra,0xffffe
    80005456:	684080e7          	jalr	1668(ra) # 80003ad6 <namecmp>
    8000545a:	14050a63          	beqz	a0,800055ae <sys_unlink+0x1b0>
    8000545e:	00003597          	auipc	a1,0x3
    80005462:	28a58593          	addi	a1,a1,650 # 800086e8 <syscalls+0x2c8>
    80005466:	fb040513          	addi	a0,s0,-80
    8000546a:	ffffe097          	auipc	ra,0xffffe
    8000546e:	66c080e7          	jalr	1644(ra) # 80003ad6 <namecmp>
    80005472:	12050e63          	beqz	a0,800055ae <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005476:	f2c40613          	addi	a2,s0,-212
    8000547a:	fb040593          	addi	a1,s0,-80
    8000547e:	8526                	mv	a0,s1
    80005480:	ffffe097          	auipc	ra,0xffffe
    80005484:	670080e7          	jalr	1648(ra) # 80003af0 <dirlookup>
    80005488:	892a                	mv	s2,a0
    8000548a:	12050263          	beqz	a0,800055ae <sys_unlink+0x1b0>
  ilock(ip);
    8000548e:	ffffe097          	auipc	ra,0xffffe
    80005492:	180080e7          	jalr	384(ra) # 8000360e <ilock>
  if(ip->nlink < 1)
    80005496:	04a91783          	lh	a5,74(s2)
    8000549a:	08f05263          	blez	a5,8000551e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000549e:	04491703          	lh	a4,68(s2)
    800054a2:	4785                	li	a5,1
    800054a4:	08f70563          	beq	a4,a5,8000552e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800054a8:	4641                	li	a2,16
    800054aa:	4581                	li	a1,0
    800054ac:	fc040513          	addi	a0,s0,-64
    800054b0:	ffffc097          	auipc	ra,0xffffc
    800054b4:	864080e7          	jalr	-1948(ra) # 80000d14 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054b8:	4741                	li	a4,16
    800054ba:	f2c42683          	lw	a3,-212(s0)
    800054be:	fc040613          	addi	a2,s0,-64
    800054c2:	4581                	li	a1,0
    800054c4:	8526                	mv	a0,s1
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	4f4080e7          	jalr	1268(ra) # 800039ba <writei>
    800054ce:	47c1                	li	a5,16
    800054d0:	0af51563          	bne	a0,a5,8000557a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800054d4:	04491703          	lh	a4,68(s2)
    800054d8:	4785                	li	a5,1
    800054da:	0af70863          	beq	a4,a5,8000558a <sys_unlink+0x18c>
  iunlockput(dp);
    800054de:	8526                	mv	a0,s1
    800054e0:	ffffe097          	auipc	ra,0xffffe
    800054e4:	390080e7          	jalr	912(ra) # 80003870 <iunlockput>
  ip->nlink--;
    800054e8:	04a95783          	lhu	a5,74(s2)
    800054ec:	37fd                	addiw	a5,a5,-1
    800054ee:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800054f2:	854a                	mv	a0,s2
    800054f4:	ffffe097          	auipc	ra,0xffffe
    800054f8:	050080e7          	jalr	80(ra) # 80003544 <iupdate>
  iunlockput(ip);
    800054fc:	854a                	mv	a0,s2
    800054fe:	ffffe097          	auipc	ra,0xffffe
    80005502:	372080e7          	jalr	882(ra) # 80003870 <iunlockput>
  end_op();
    80005506:	fffff097          	auipc	ra,0xfffff
    8000550a:	b58080e7          	jalr	-1192(ra) # 8000405e <end_op>
  return 0;
    8000550e:	4501                	li	a0,0
    80005510:	a84d                	j	800055c2 <sys_unlink+0x1c4>
    end_op();
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	b4c080e7          	jalr	-1204(ra) # 8000405e <end_op>
    return -1;
    8000551a:	557d                	li	a0,-1
    8000551c:	a05d                	j	800055c2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000551e:	00003517          	auipc	a0,0x3
    80005522:	1f250513          	addi	a0,a0,498 # 80008710 <syscalls+0x2f0>
    80005526:	ffffb097          	auipc	ra,0xffffb
    8000552a:	02a080e7          	jalr	42(ra) # 80000550 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000552e:	04c92703          	lw	a4,76(s2)
    80005532:	02000793          	li	a5,32
    80005536:	f6e7f9e3          	bgeu	a5,a4,800054a8 <sys_unlink+0xaa>
    8000553a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000553e:	4741                	li	a4,16
    80005540:	86ce                	mv	a3,s3
    80005542:	f1840613          	addi	a2,s0,-232
    80005546:	4581                	li	a1,0
    80005548:	854a                	mv	a0,s2
    8000554a:	ffffe097          	auipc	ra,0xffffe
    8000554e:	378080e7          	jalr	888(ra) # 800038c2 <readi>
    80005552:	47c1                	li	a5,16
    80005554:	00f51b63          	bne	a0,a5,8000556a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005558:	f1845783          	lhu	a5,-232(s0)
    8000555c:	e7a1                	bnez	a5,800055a4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000555e:	29c1                	addiw	s3,s3,16
    80005560:	04c92783          	lw	a5,76(s2)
    80005564:	fcf9ede3          	bltu	s3,a5,8000553e <sys_unlink+0x140>
    80005568:	b781                	j	800054a8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000556a:	00003517          	auipc	a0,0x3
    8000556e:	1be50513          	addi	a0,a0,446 # 80008728 <syscalls+0x308>
    80005572:	ffffb097          	auipc	ra,0xffffb
    80005576:	fde080e7          	jalr	-34(ra) # 80000550 <panic>
    panic("unlink: writei");
    8000557a:	00003517          	auipc	a0,0x3
    8000557e:	1c650513          	addi	a0,a0,454 # 80008740 <syscalls+0x320>
    80005582:	ffffb097          	auipc	ra,0xffffb
    80005586:	fce080e7          	jalr	-50(ra) # 80000550 <panic>
    dp->nlink--;
    8000558a:	04a4d783          	lhu	a5,74(s1)
    8000558e:	37fd                	addiw	a5,a5,-1
    80005590:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005594:	8526                	mv	a0,s1
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	fae080e7          	jalr	-82(ra) # 80003544 <iupdate>
    8000559e:	b781                	j	800054de <sys_unlink+0xe0>
    return -1;
    800055a0:	557d                	li	a0,-1
    800055a2:	a005                	j	800055c2 <sys_unlink+0x1c4>
    iunlockput(ip);
    800055a4:	854a                	mv	a0,s2
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	2ca080e7          	jalr	714(ra) # 80003870 <iunlockput>
  iunlockput(dp);
    800055ae:	8526                	mv	a0,s1
    800055b0:	ffffe097          	auipc	ra,0xffffe
    800055b4:	2c0080e7          	jalr	704(ra) # 80003870 <iunlockput>
  end_op();
    800055b8:	fffff097          	auipc	ra,0xfffff
    800055bc:	aa6080e7          	jalr	-1370(ra) # 8000405e <end_op>
  return -1;
    800055c0:	557d                	li	a0,-1
}
    800055c2:	70ae                	ld	ra,232(sp)
    800055c4:	740e                	ld	s0,224(sp)
    800055c6:	64ee                	ld	s1,216(sp)
    800055c8:	694e                	ld	s2,208(sp)
    800055ca:	69ae                	ld	s3,200(sp)
    800055cc:	616d                	addi	sp,sp,240
    800055ce:	8082                	ret

00000000800055d0 <sys_open>:

uint64
sys_open(void)
{
    800055d0:	7131                	addi	sp,sp,-192
    800055d2:	fd06                	sd	ra,184(sp)
    800055d4:	f922                	sd	s0,176(sp)
    800055d6:	f526                	sd	s1,168(sp)
    800055d8:	f14a                	sd	s2,160(sp)
    800055da:	ed4e                	sd	s3,152(sp)
    800055dc:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800055de:	08000613          	li	a2,128
    800055e2:	f5040593          	addi	a1,s0,-176
    800055e6:	4501                	li	a0,0
    800055e8:	ffffd097          	auipc	ra,0xffffd
    800055ec:	4f8080e7          	jalr	1272(ra) # 80002ae0 <argstr>
    return -1;
    800055f0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800055f2:	0c054163          	bltz	a0,800056b4 <sys_open+0xe4>
    800055f6:	f4c40593          	addi	a1,s0,-180
    800055fa:	4505                	li	a0,1
    800055fc:	ffffd097          	auipc	ra,0xffffd
    80005600:	4a0080e7          	jalr	1184(ra) # 80002a9c <argint>
    80005604:	0a054863          	bltz	a0,800056b4 <sys_open+0xe4>

  begin_op();
    80005608:	fffff097          	auipc	ra,0xfffff
    8000560c:	9d6080e7          	jalr	-1578(ra) # 80003fde <begin_op>

  if(omode & O_CREATE){
    80005610:	f4c42783          	lw	a5,-180(s0)
    80005614:	2007f793          	andi	a5,a5,512
    80005618:	cbdd                	beqz	a5,800056ce <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000561a:	4681                	li	a3,0
    8000561c:	4601                	li	a2,0
    8000561e:	4589                	li	a1,2
    80005620:	f5040513          	addi	a0,s0,-176
    80005624:	00000097          	auipc	ra,0x0
    80005628:	972080e7          	jalr	-1678(ra) # 80004f96 <create>
    8000562c:	892a                	mv	s2,a0
    if(ip == 0){
    8000562e:	c959                	beqz	a0,800056c4 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005630:	04491703          	lh	a4,68(s2)
    80005634:	478d                	li	a5,3
    80005636:	00f71763          	bne	a4,a5,80005644 <sys_open+0x74>
    8000563a:	04695703          	lhu	a4,70(s2)
    8000563e:	47a5                	li	a5,9
    80005640:	0ce7ec63          	bltu	a5,a4,80005718 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005644:	fffff097          	auipc	ra,0xfffff
    80005648:	db2080e7          	jalr	-590(ra) # 800043f6 <filealloc>
    8000564c:	89aa                	mv	s3,a0
    8000564e:	10050263          	beqz	a0,80005752 <sys_open+0x182>
    80005652:	00000097          	auipc	ra,0x0
    80005656:	902080e7          	jalr	-1790(ra) # 80004f54 <fdalloc>
    8000565a:	84aa                	mv	s1,a0
    8000565c:	0e054663          	bltz	a0,80005748 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005660:	04491703          	lh	a4,68(s2)
    80005664:	478d                	li	a5,3
    80005666:	0cf70463          	beq	a4,a5,8000572e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000566a:	4789                	li	a5,2
    8000566c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005670:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005674:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005678:	f4c42783          	lw	a5,-180(s0)
    8000567c:	0017c713          	xori	a4,a5,1
    80005680:	8b05                	andi	a4,a4,1
    80005682:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005686:	0037f713          	andi	a4,a5,3
    8000568a:	00e03733          	snez	a4,a4
    8000568e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005692:	4007f793          	andi	a5,a5,1024
    80005696:	c791                	beqz	a5,800056a2 <sys_open+0xd2>
    80005698:	04491703          	lh	a4,68(s2)
    8000569c:	4789                	li	a5,2
    8000569e:	08f70f63          	beq	a4,a5,8000573c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800056a2:	854a                	mv	a0,s2
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	02c080e7          	jalr	44(ra) # 800036d0 <iunlock>
  end_op();
    800056ac:	fffff097          	auipc	ra,0xfffff
    800056b0:	9b2080e7          	jalr	-1614(ra) # 8000405e <end_op>

  return fd;
}
    800056b4:	8526                	mv	a0,s1
    800056b6:	70ea                	ld	ra,184(sp)
    800056b8:	744a                	ld	s0,176(sp)
    800056ba:	74aa                	ld	s1,168(sp)
    800056bc:	790a                	ld	s2,160(sp)
    800056be:	69ea                	ld	s3,152(sp)
    800056c0:	6129                	addi	sp,sp,192
    800056c2:	8082                	ret
      end_op();
    800056c4:	fffff097          	auipc	ra,0xfffff
    800056c8:	99a080e7          	jalr	-1638(ra) # 8000405e <end_op>
      return -1;
    800056cc:	b7e5                	j	800056b4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800056ce:	f5040513          	addi	a0,s0,-176
    800056d2:	ffffe097          	auipc	ra,0xffffe
    800056d6:	6f0080e7          	jalr	1776(ra) # 80003dc2 <namei>
    800056da:	892a                	mv	s2,a0
    800056dc:	c905                	beqz	a0,8000570c <sys_open+0x13c>
    ilock(ip);
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	f30080e7          	jalr	-208(ra) # 8000360e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800056e6:	04491703          	lh	a4,68(s2)
    800056ea:	4785                	li	a5,1
    800056ec:	f4f712e3          	bne	a4,a5,80005630 <sys_open+0x60>
    800056f0:	f4c42783          	lw	a5,-180(s0)
    800056f4:	dba1                	beqz	a5,80005644 <sys_open+0x74>
      iunlockput(ip);
    800056f6:	854a                	mv	a0,s2
    800056f8:	ffffe097          	auipc	ra,0xffffe
    800056fc:	178080e7          	jalr	376(ra) # 80003870 <iunlockput>
      end_op();
    80005700:	fffff097          	auipc	ra,0xfffff
    80005704:	95e080e7          	jalr	-1698(ra) # 8000405e <end_op>
      return -1;
    80005708:	54fd                	li	s1,-1
    8000570a:	b76d                	j	800056b4 <sys_open+0xe4>
      end_op();
    8000570c:	fffff097          	auipc	ra,0xfffff
    80005710:	952080e7          	jalr	-1710(ra) # 8000405e <end_op>
      return -1;
    80005714:	54fd                	li	s1,-1
    80005716:	bf79                	j	800056b4 <sys_open+0xe4>
    iunlockput(ip);
    80005718:	854a                	mv	a0,s2
    8000571a:	ffffe097          	auipc	ra,0xffffe
    8000571e:	156080e7          	jalr	342(ra) # 80003870 <iunlockput>
    end_op();
    80005722:	fffff097          	auipc	ra,0xfffff
    80005726:	93c080e7          	jalr	-1732(ra) # 8000405e <end_op>
    return -1;
    8000572a:	54fd                	li	s1,-1
    8000572c:	b761                	j	800056b4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000572e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005732:	04691783          	lh	a5,70(s2)
    80005736:	02f99223          	sh	a5,36(s3)
    8000573a:	bf2d                	j	80005674 <sys_open+0xa4>
    itrunc(ip);
    8000573c:	854a                	mv	a0,s2
    8000573e:	ffffe097          	auipc	ra,0xffffe
    80005742:	fde080e7          	jalr	-34(ra) # 8000371c <itrunc>
    80005746:	bfb1                	j	800056a2 <sys_open+0xd2>
      fileclose(f);
    80005748:	854e                	mv	a0,s3
    8000574a:	fffff097          	auipc	ra,0xfffff
    8000574e:	d68080e7          	jalr	-664(ra) # 800044b2 <fileclose>
    iunlockput(ip);
    80005752:	854a                	mv	a0,s2
    80005754:	ffffe097          	auipc	ra,0xffffe
    80005758:	11c080e7          	jalr	284(ra) # 80003870 <iunlockput>
    end_op();
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	902080e7          	jalr	-1790(ra) # 8000405e <end_op>
    return -1;
    80005764:	54fd                	li	s1,-1
    80005766:	b7b9                	j	800056b4 <sys_open+0xe4>

0000000080005768 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005768:	7175                	addi	sp,sp,-144
    8000576a:	e506                	sd	ra,136(sp)
    8000576c:	e122                	sd	s0,128(sp)
    8000576e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005770:	fffff097          	auipc	ra,0xfffff
    80005774:	86e080e7          	jalr	-1938(ra) # 80003fde <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005778:	08000613          	li	a2,128
    8000577c:	f7040593          	addi	a1,s0,-144
    80005780:	4501                	li	a0,0
    80005782:	ffffd097          	auipc	ra,0xffffd
    80005786:	35e080e7          	jalr	862(ra) # 80002ae0 <argstr>
    8000578a:	02054963          	bltz	a0,800057bc <sys_mkdir+0x54>
    8000578e:	4681                	li	a3,0
    80005790:	4601                	li	a2,0
    80005792:	4585                	li	a1,1
    80005794:	f7040513          	addi	a0,s0,-144
    80005798:	fffff097          	auipc	ra,0xfffff
    8000579c:	7fe080e7          	jalr	2046(ra) # 80004f96 <create>
    800057a0:	cd11                	beqz	a0,800057bc <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	0ce080e7          	jalr	206(ra) # 80003870 <iunlockput>
  end_op();
    800057aa:	fffff097          	auipc	ra,0xfffff
    800057ae:	8b4080e7          	jalr	-1868(ra) # 8000405e <end_op>
  return 0;
    800057b2:	4501                	li	a0,0
}
    800057b4:	60aa                	ld	ra,136(sp)
    800057b6:	640a                	ld	s0,128(sp)
    800057b8:	6149                	addi	sp,sp,144
    800057ba:	8082                	ret
    end_op();
    800057bc:	fffff097          	auipc	ra,0xfffff
    800057c0:	8a2080e7          	jalr	-1886(ra) # 8000405e <end_op>
    return -1;
    800057c4:	557d                	li	a0,-1
    800057c6:	b7fd                	j	800057b4 <sys_mkdir+0x4c>

00000000800057c8 <sys_mknod>:

uint64
sys_mknod(void)
{
    800057c8:	7135                	addi	sp,sp,-160
    800057ca:	ed06                	sd	ra,152(sp)
    800057cc:	e922                	sd	s0,144(sp)
    800057ce:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800057d0:	fffff097          	auipc	ra,0xfffff
    800057d4:	80e080e7          	jalr	-2034(ra) # 80003fde <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800057d8:	08000613          	li	a2,128
    800057dc:	f7040593          	addi	a1,s0,-144
    800057e0:	4501                	li	a0,0
    800057e2:	ffffd097          	auipc	ra,0xffffd
    800057e6:	2fe080e7          	jalr	766(ra) # 80002ae0 <argstr>
    800057ea:	04054a63          	bltz	a0,8000583e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800057ee:	f6c40593          	addi	a1,s0,-148
    800057f2:	4505                	li	a0,1
    800057f4:	ffffd097          	auipc	ra,0xffffd
    800057f8:	2a8080e7          	jalr	680(ra) # 80002a9c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800057fc:	04054163          	bltz	a0,8000583e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005800:	f6840593          	addi	a1,s0,-152
    80005804:	4509                	li	a0,2
    80005806:	ffffd097          	auipc	ra,0xffffd
    8000580a:	296080e7          	jalr	662(ra) # 80002a9c <argint>
     argint(1, &major) < 0 ||
    8000580e:	02054863          	bltz	a0,8000583e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005812:	f6841683          	lh	a3,-152(s0)
    80005816:	f6c41603          	lh	a2,-148(s0)
    8000581a:	458d                	li	a1,3
    8000581c:	f7040513          	addi	a0,s0,-144
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	776080e7          	jalr	1910(ra) # 80004f96 <create>
     argint(2, &minor) < 0 ||
    80005828:	c919                	beqz	a0,8000583e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	046080e7          	jalr	70(ra) # 80003870 <iunlockput>
  end_op();
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	82c080e7          	jalr	-2004(ra) # 8000405e <end_op>
  return 0;
    8000583a:	4501                	li	a0,0
    8000583c:	a031                	j	80005848 <sys_mknod+0x80>
    end_op();
    8000583e:	fffff097          	auipc	ra,0xfffff
    80005842:	820080e7          	jalr	-2016(ra) # 8000405e <end_op>
    return -1;
    80005846:	557d                	li	a0,-1
}
    80005848:	60ea                	ld	ra,152(sp)
    8000584a:	644a                	ld	s0,144(sp)
    8000584c:	610d                	addi	sp,sp,160
    8000584e:	8082                	ret

0000000080005850 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005850:	7135                	addi	sp,sp,-160
    80005852:	ed06                	sd	ra,152(sp)
    80005854:	e922                	sd	s0,144(sp)
    80005856:	e526                	sd	s1,136(sp)
    80005858:	e14a                	sd	s2,128(sp)
    8000585a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000585c:	ffffc097          	auipc	ra,0xffffc
    80005860:	1a6080e7          	jalr	422(ra) # 80001a02 <myproc>
    80005864:	892a                	mv	s2,a0
  
  begin_op();
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	778080e7          	jalr	1912(ra) # 80003fde <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000586e:	08000613          	li	a2,128
    80005872:	f6040593          	addi	a1,s0,-160
    80005876:	4501                	li	a0,0
    80005878:	ffffd097          	auipc	ra,0xffffd
    8000587c:	268080e7          	jalr	616(ra) # 80002ae0 <argstr>
    80005880:	04054b63          	bltz	a0,800058d6 <sys_chdir+0x86>
    80005884:	f6040513          	addi	a0,s0,-160
    80005888:	ffffe097          	auipc	ra,0xffffe
    8000588c:	53a080e7          	jalr	1338(ra) # 80003dc2 <namei>
    80005890:	84aa                	mv	s1,a0
    80005892:	c131                	beqz	a0,800058d6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	d7a080e7          	jalr	-646(ra) # 8000360e <ilock>
  if(ip->type != T_DIR){
    8000589c:	04449703          	lh	a4,68(s1)
    800058a0:	4785                	li	a5,1
    800058a2:	04f71063          	bne	a4,a5,800058e2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800058a6:	8526                	mv	a0,s1
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	e28080e7          	jalr	-472(ra) # 800036d0 <iunlock>
  iput(p->cwd);
    800058b0:	15093503          	ld	a0,336(s2)
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	f14080e7          	jalr	-236(ra) # 800037c8 <iput>
  end_op();
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	7a2080e7          	jalr	1954(ra) # 8000405e <end_op>
  p->cwd = ip;
    800058c4:	14993823          	sd	s1,336(s2)
  return 0;
    800058c8:	4501                	li	a0,0
}
    800058ca:	60ea                	ld	ra,152(sp)
    800058cc:	644a                	ld	s0,144(sp)
    800058ce:	64aa                	ld	s1,136(sp)
    800058d0:	690a                	ld	s2,128(sp)
    800058d2:	610d                	addi	sp,sp,160
    800058d4:	8082                	ret
    end_op();
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	788080e7          	jalr	1928(ra) # 8000405e <end_op>
    return -1;
    800058de:	557d                	li	a0,-1
    800058e0:	b7ed                	j	800058ca <sys_chdir+0x7a>
    iunlockput(ip);
    800058e2:	8526                	mv	a0,s1
    800058e4:	ffffe097          	auipc	ra,0xffffe
    800058e8:	f8c080e7          	jalr	-116(ra) # 80003870 <iunlockput>
    end_op();
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	772080e7          	jalr	1906(ra) # 8000405e <end_op>
    return -1;
    800058f4:	557d                	li	a0,-1
    800058f6:	bfd1                	j	800058ca <sys_chdir+0x7a>

00000000800058f8 <sys_exec>:

uint64
sys_exec(void)
{
    800058f8:	7145                	addi	sp,sp,-464
    800058fa:	e786                	sd	ra,456(sp)
    800058fc:	e3a2                	sd	s0,448(sp)
    800058fe:	ff26                	sd	s1,440(sp)
    80005900:	fb4a                	sd	s2,432(sp)
    80005902:	f74e                	sd	s3,424(sp)
    80005904:	f352                	sd	s4,416(sp)
    80005906:	ef56                	sd	s5,408(sp)
    80005908:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000590a:	08000613          	li	a2,128
    8000590e:	f4040593          	addi	a1,s0,-192
    80005912:	4501                	li	a0,0
    80005914:	ffffd097          	auipc	ra,0xffffd
    80005918:	1cc080e7          	jalr	460(ra) # 80002ae0 <argstr>
    return -1;
    8000591c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000591e:	0c054a63          	bltz	a0,800059f2 <sys_exec+0xfa>
    80005922:	e3840593          	addi	a1,s0,-456
    80005926:	4505                	li	a0,1
    80005928:	ffffd097          	auipc	ra,0xffffd
    8000592c:	196080e7          	jalr	406(ra) # 80002abe <argaddr>
    80005930:	0c054163          	bltz	a0,800059f2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005934:	10000613          	li	a2,256
    80005938:	4581                	li	a1,0
    8000593a:	e4040513          	addi	a0,s0,-448
    8000593e:	ffffb097          	auipc	ra,0xffffb
    80005942:	3d6080e7          	jalr	982(ra) # 80000d14 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005946:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000594a:	89a6                	mv	s3,s1
    8000594c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000594e:	02000a13          	li	s4,32
    80005952:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005956:	00391513          	slli	a0,s2,0x3
    8000595a:	e3040593          	addi	a1,s0,-464
    8000595e:	e3843783          	ld	a5,-456(s0)
    80005962:	953e                	add	a0,a0,a5
    80005964:	ffffd097          	auipc	ra,0xffffd
    80005968:	09e080e7          	jalr	158(ra) # 80002a02 <fetchaddr>
    8000596c:	02054a63          	bltz	a0,800059a0 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005970:	e3043783          	ld	a5,-464(s0)
    80005974:	c3b9                	beqz	a5,800059ba <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005976:	ffffb097          	auipc	ra,0xffffb
    8000597a:	1b2080e7          	jalr	434(ra) # 80000b28 <kalloc>
    8000597e:	85aa                	mv	a1,a0
    80005980:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005984:	cd11                	beqz	a0,800059a0 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005986:	6605                	lui	a2,0x1
    80005988:	e3043503          	ld	a0,-464(s0)
    8000598c:	ffffd097          	auipc	ra,0xffffd
    80005990:	0c8080e7          	jalr	200(ra) # 80002a54 <fetchstr>
    80005994:	00054663          	bltz	a0,800059a0 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005998:	0905                	addi	s2,s2,1
    8000599a:	09a1                	addi	s3,s3,8
    8000599c:	fb491be3          	bne	s2,s4,80005952 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059a0:	10048913          	addi	s2,s1,256
    800059a4:	6088                	ld	a0,0(s1)
    800059a6:	c529                	beqz	a0,800059f0 <sys_exec+0xf8>
    kfree(argv[i]);
    800059a8:	ffffb097          	auipc	ra,0xffffb
    800059ac:	084080e7          	jalr	132(ra) # 80000a2c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059b0:	04a1                	addi	s1,s1,8
    800059b2:	ff2499e3          	bne	s1,s2,800059a4 <sys_exec+0xac>
  return -1;
    800059b6:	597d                	li	s2,-1
    800059b8:	a82d                	j	800059f2 <sys_exec+0xfa>
      argv[i] = 0;
    800059ba:	0a8e                	slli	s5,s5,0x3
    800059bc:	fc040793          	addi	a5,s0,-64
    800059c0:	9abe                	add	s5,s5,a5
    800059c2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800059c6:	e4040593          	addi	a1,s0,-448
    800059ca:	f4040513          	addi	a0,s0,-192
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	194080e7          	jalr	404(ra) # 80004b62 <exec>
    800059d6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059d8:	10048993          	addi	s3,s1,256
    800059dc:	6088                	ld	a0,0(s1)
    800059de:	c911                	beqz	a0,800059f2 <sys_exec+0xfa>
    kfree(argv[i]);
    800059e0:	ffffb097          	auipc	ra,0xffffb
    800059e4:	04c080e7          	jalr	76(ra) # 80000a2c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059e8:	04a1                	addi	s1,s1,8
    800059ea:	ff3499e3          	bne	s1,s3,800059dc <sys_exec+0xe4>
    800059ee:	a011                	j	800059f2 <sys_exec+0xfa>
  return -1;
    800059f0:	597d                	li	s2,-1
}
    800059f2:	854a                	mv	a0,s2
    800059f4:	60be                	ld	ra,456(sp)
    800059f6:	641e                	ld	s0,448(sp)
    800059f8:	74fa                	ld	s1,440(sp)
    800059fa:	795a                	ld	s2,432(sp)
    800059fc:	79ba                	ld	s3,424(sp)
    800059fe:	7a1a                	ld	s4,416(sp)
    80005a00:	6afa                	ld	s5,408(sp)
    80005a02:	6179                	addi	sp,sp,464
    80005a04:	8082                	ret

0000000080005a06 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a06:	7139                	addi	sp,sp,-64
    80005a08:	fc06                	sd	ra,56(sp)
    80005a0a:	f822                	sd	s0,48(sp)
    80005a0c:	f426                	sd	s1,40(sp)
    80005a0e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a10:	ffffc097          	auipc	ra,0xffffc
    80005a14:	ff2080e7          	jalr	-14(ra) # 80001a02 <myproc>
    80005a18:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005a1a:	fd840593          	addi	a1,s0,-40
    80005a1e:	4501                	li	a0,0
    80005a20:	ffffd097          	auipc	ra,0xffffd
    80005a24:	09e080e7          	jalr	158(ra) # 80002abe <argaddr>
    return -1;
    80005a28:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005a2a:	0e054063          	bltz	a0,80005b0a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005a2e:	fc840593          	addi	a1,s0,-56
    80005a32:	fd040513          	addi	a0,s0,-48
    80005a36:	fffff097          	auipc	ra,0xfffff
    80005a3a:	dd2080e7          	jalr	-558(ra) # 80004808 <pipealloc>
    return -1;
    80005a3e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005a40:	0c054563          	bltz	a0,80005b0a <sys_pipe+0x104>
  fd0 = -1;
    80005a44:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005a48:	fd043503          	ld	a0,-48(s0)
    80005a4c:	fffff097          	auipc	ra,0xfffff
    80005a50:	508080e7          	jalr	1288(ra) # 80004f54 <fdalloc>
    80005a54:	fca42223          	sw	a0,-60(s0)
    80005a58:	08054c63          	bltz	a0,80005af0 <sys_pipe+0xea>
    80005a5c:	fc843503          	ld	a0,-56(s0)
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	4f4080e7          	jalr	1268(ra) # 80004f54 <fdalloc>
    80005a68:	fca42023          	sw	a0,-64(s0)
    80005a6c:	06054863          	bltz	a0,80005adc <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a70:	4691                	li	a3,4
    80005a72:	fc440613          	addi	a2,s0,-60
    80005a76:	fd843583          	ld	a1,-40(s0)
    80005a7a:	68a8                	ld	a0,80(s1)
    80005a7c:	ffffc097          	auipc	ra,0xffffc
    80005a80:	c1c080e7          	jalr	-996(ra) # 80001698 <copyout>
    80005a84:	02054063          	bltz	a0,80005aa4 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a88:	4691                	li	a3,4
    80005a8a:	fc040613          	addi	a2,s0,-64
    80005a8e:	fd843583          	ld	a1,-40(s0)
    80005a92:	0591                	addi	a1,a1,4
    80005a94:	68a8                	ld	a0,80(s1)
    80005a96:	ffffc097          	auipc	ra,0xffffc
    80005a9a:	c02080e7          	jalr	-1022(ra) # 80001698 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005a9e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005aa0:	06055563          	bgez	a0,80005b0a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005aa4:	fc442783          	lw	a5,-60(s0)
    80005aa8:	07e9                	addi	a5,a5,26
    80005aaa:	078e                	slli	a5,a5,0x3
    80005aac:	97a6                	add	a5,a5,s1
    80005aae:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ab2:	fc042503          	lw	a0,-64(s0)
    80005ab6:	0569                	addi	a0,a0,26
    80005ab8:	050e                	slli	a0,a0,0x3
    80005aba:	9526                	add	a0,a0,s1
    80005abc:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ac0:	fd043503          	ld	a0,-48(s0)
    80005ac4:	fffff097          	auipc	ra,0xfffff
    80005ac8:	9ee080e7          	jalr	-1554(ra) # 800044b2 <fileclose>
    fileclose(wf);
    80005acc:	fc843503          	ld	a0,-56(s0)
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	9e2080e7          	jalr	-1566(ra) # 800044b2 <fileclose>
    return -1;
    80005ad8:	57fd                	li	a5,-1
    80005ada:	a805                	j	80005b0a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005adc:	fc442783          	lw	a5,-60(s0)
    80005ae0:	0007c863          	bltz	a5,80005af0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005ae4:	01a78513          	addi	a0,a5,26
    80005ae8:	050e                	slli	a0,a0,0x3
    80005aea:	9526                	add	a0,a0,s1
    80005aec:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005af0:	fd043503          	ld	a0,-48(s0)
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	9be080e7          	jalr	-1602(ra) # 800044b2 <fileclose>
    fileclose(wf);
    80005afc:	fc843503          	ld	a0,-56(s0)
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	9b2080e7          	jalr	-1614(ra) # 800044b2 <fileclose>
    return -1;
    80005b08:	57fd                	li	a5,-1
}
    80005b0a:	853e                	mv	a0,a5
    80005b0c:	70e2                	ld	ra,56(sp)
    80005b0e:	7442                	ld	s0,48(sp)
    80005b10:	74a2                	ld	s1,40(sp)
    80005b12:	6121                	addi	sp,sp,64
    80005b14:	8082                	ret
	...

0000000080005b20 <kernelvec>:
    80005b20:	7111                	addi	sp,sp,-256
    80005b22:	e006                	sd	ra,0(sp)
    80005b24:	e40a                	sd	sp,8(sp)
    80005b26:	e80e                	sd	gp,16(sp)
    80005b28:	ec12                	sd	tp,24(sp)
    80005b2a:	f016                	sd	t0,32(sp)
    80005b2c:	f41a                	sd	t1,40(sp)
    80005b2e:	f81e                	sd	t2,48(sp)
    80005b30:	fc22                	sd	s0,56(sp)
    80005b32:	e0a6                	sd	s1,64(sp)
    80005b34:	e4aa                	sd	a0,72(sp)
    80005b36:	e8ae                	sd	a1,80(sp)
    80005b38:	ecb2                	sd	a2,88(sp)
    80005b3a:	f0b6                	sd	a3,96(sp)
    80005b3c:	f4ba                	sd	a4,104(sp)
    80005b3e:	f8be                	sd	a5,112(sp)
    80005b40:	fcc2                	sd	a6,120(sp)
    80005b42:	e146                	sd	a7,128(sp)
    80005b44:	e54a                	sd	s2,136(sp)
    80005b46:	e94e                	sd	s3,144(sp)
    80005b48:	ed52                	sd	s4,152(sp)
    80005b4a:	f156                	sd	s5,160(sp)
    80005b4c:	f55a                	sd	s6,168(sp)
    80005b4e:	f95e                	sd	s7,176(sp)
    80005b50:	fd62                	sd	s8,184(sp)
    80005b52:	e1e6                	sd	s9,192(sp)
    80005b54:	e5ea                	sd	s10,200(sp)
    80005b56:	e9ee                	sd	s11,208(sp)
    80005b58:	edf2                	sd	t3,216(sp)
    80005b5a:	f1f6                	sd	t4,224(sp)
    80005b5c:	f5fa                	sd	t5,232(sp)
    80005b5e:	f9fe                	sd	t6,240(sp)
    80005b60:	d6ffc0ef          	jal	ra,800028ce <kerneltrap>
    80005b64:	6082                	ld	ra,0(sp)
    80005b66:	6122                	ld	sp,8(sp)
    80005b68:	61c2                	ld	gp,16(sp)
    80005b6a:	7282                	ld	t0,32(sp)
    80005b6c:	7322                	ld	t1,40(sp)
    80005b6e:	73c2                	ld	t2,48(sp)
    80005b70:	7462                	ld	s0,56(sp)
    80005b72:	6486                	ld	s1,64(sp)
    80005b74:	6526                	ld	a0,72(sp)
    80005b76:	65c6                	ld	a1,80(sp)
    80005b78:	6666                	ld	a2,88(sp)
    80005b7a:	7686                	ld	a3,96(sp)
    80005b7c:	7726                	ld	a4,104(sp)
    80005b7e:	77c6                	ld	a5,112(sp)
    80005b80:	7866                	ld	a6,120(sp)
    80005b82:	688a                	ld	a7,128(sp)
    80005b84:	692a                	ld	s2,136(sp)
    80005b86:	69ca                	ld	s3,144(sp)
    80005b88:	6a6a                	ld	s4,152(sp)
    80005b8a:	7a8a                	ld	s5,160(sp)
    80005b8c:	7b2a                	ld	s6,168(sp)
    80005b8e:	7bca                	ld	s7,176(sp)
    80005b90:	7c6a                	ld	s8,184(sp)
    80005b92:	6c8e                	ld	s9,192(sp)
    80005b94:	6d2e                	ld	s10,200(sp)
    80005b96:	6dce                	ld	s11,208(sp)
    80005b98:	6e6e                	ld	t3,216(sp)
    80005b9a:	7e8e                	ld	t4,224(sp)
    80005b9c:	7f2e                	ld	t5,232(sp)
    80005b9e:	7fce                	ld	t6,240(sp)
    80005ba0:	6111                	addi	sp,sp,256
    80005ba2:	10200073          	sret
    80005ba6:	00000013          	nop
    80005baa:	00000013          	nop
    80005bae:	0001                	nop

0000000080005bb0 <timervec>:
    80005bb0:	34051573          	csrrw	a0,mscratch,a0
    80005bb4:	e10c                	sd	a1,0(a0)
    80005bb6:	e510                	sd	a2,8(a0)
    80005bb8:	e914                	sd	a3,16(a0)
    80005bba:	6d0c                	ld	a1,24(a0)
    80005bbc:	7110                	ld	a2,32(a0)
    80005bbe:	6194                	ld	a3,0(a1)
    80005bc0:	96b2                	add	a3,a3,a2
    80005bc2:	e194                	sd	a3,0(a1)
    80005bc4:	4589                	li	a1,2
    80005bc6:	14459073          	csrw	sip,a1
    80005bca:	6914                	ld	a3,16(a0)
    80005bcc:	6510                	ld	a2,8(a0)
    80005bce:	610c                	ld	a1,0(a0)
    80005bd0:	34051573          	csrrw	a0,mscratch,a0
    80005bd4:	30200073          	mret
	...

0000000080005bda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005bda:	1141                	addi	sp,sp,-16
    80005bdc:	e422                	sd	s0,8(sp)
    80005bde:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005be0:	0c0007b7          	lui	a5,0xc000
    80005be4:	4705                	li	a4,1
    80005be6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005be8:	c3d8                	sw	a4,4(a5)
}
    80005bea:	6422                	ld	s0,8(sp)
    80005bec:	0141                	addi	sp,sp,16
    80005bee:	8082                	ret

0000000080005bf0 <plicinithart>:

void
plicinithart(void)
{
    80005bf0:	1141                	addi	sp,sp,-16
    80005bf2:	e406                	sd	ra,8(sp)
    80005bf4:	e022                	sd	s0,0(sp)
    80005bf6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005bf8:	ffffc097          	auipc	ra,0xffffc
    80005bfc:	dde080e7          	jalr	-546(ra) # 800019d6 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c00:	0085171b          	slliw	a4,a0,0x8
    80005c04:	0c0027b7          	lui	a5,0xc002
    80005c08:	97ba                	add	a5,a5,a4
    80005c0a:	40200713          	li	a4,1026
    80005c0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c12:	00d5151b          	slliw	a0,a0,0xd
    80005c16:	0c2017b7          	lui	a5,0xc201
    80005c1a:	953e                	add	a0,a0,a5
    80005c1c:	00052023          	sw	zero,0(a0)
}
    80005c20:	60a2                	ld	ra,8(sp)
    80005c22:	6402                	ld	s0,0(sp)
    80005c24:	0141                	addi	sp,sp,16
    80005c26:	8082                	ret

0000000080005c28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c28:	1141                	addi	sp,sp,-16
    80005c2a:	e406                	sd	ra,8(sp)
    80005c2c:	e022                	sd	s0,0(sp)
    80005c2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c30:	ffffc097          	auipc	ra,0xffffc
    80005c34:	da6080e7          	jalr	-602(ra) # 800019d6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c38:	00d5179b          	slliw	a5,a0,0xd
    80005c3c:	0c201537          	lui	a0,0xc201
    80005c40:	953e                	add	a0,a0,a5
  return irq;
}
    80005c42:	4148                	lw	a0,4(a0)
    80005c44:	60a2                	ld	ra,8(sp)
    80005c46:	6402                	ld	s0,0(sp)
    80005c48:	0141                	addi	sp,sp,16
    80005c4a:	8082                	ret

0000000080005c4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005c4c:	1101                	addi	sp,sp,-32
    80005c4e:	ec06                	sd	ra,24(sp)
    80005c50:	e822                	sd	s0,16(sp)
    80005c52:	e426                	sd	s1,8(sp)
    80005c54:	1000                	addi	s0,sp,32
    80005c56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005c58:	ffffc097          	auipc	ra,0xffffc
    80005c5c:	d7e080e7          	jalr	-642(ra) # 800019d6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005c60:	00d5151b          	slliw	a0,a0,0xd
    80005c64:	0c2017b7          	lui	a5,0xc201
    80005c68:	97aa                	add	a5,a5,a0
    80005c6a:	c3c4                	sw	s1,4(a5)
}
    80005c6c:	60e2                	ld	ra,24(sp)
    80005c6e:	6442                	ld	s0,16(sp)
    80005c70:	64a2                	ld	s1,8(sp)
    80005c72:	6105                	addi	sp,sp,32
    80005c74:	8082                	ret

0000000080005c76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005c76:	1141                	addi	sp,sp,-16
    80005c78:	e406                	sd	ra,8(sp)
    80005c7a:	e022                	sd	s0,0(sp)
    80005c7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005c7e:	479d                	li	a5,7
    80005c80:	06a7c963          	blt	a5,a0,80005cf2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005c84:	0001d797          	auipc	a5,0x1d
    80005c88:	37c78793          	addi	a5,a5,892 # 80023000 <disk>
    80005c8c:	00a78733          	add	a4,a5,a0
    80005c90:	6789                	lui	a5,0x2
    80005c92:	97ba                	add	a5,a5,a4
    80005c94:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005c98:	e7ad                	bnez	a5,80005d02 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005c9a:	00451793          	slli	a5,a0,0x4
    80005c9e:	0001f717          	auipc	a4,0x1f
    80005ca2:	36270713          	addi	a4,a4,866 # 80025000 <disk+0x2000>
    80005ca6:	6314                	ld	a3,0(a4)
    80005ca8:	96be                	add	a3,a3,a5
    80005caa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005cae:	6314                	ld	a3,0(a4)
    80005cb0:	96be                	add	a3,a3,a5
    80005cb2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005cb6:	6314                	ld	a3,0(a4)
    80005cb8:	96be                	add	a3,a3,a5
    80005cba:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005cbe:	6318                	ld	a4,0(a4)
    80005cc0:	97ba                	add	a5,a5,a4
    80005cc2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005cc6:	0001d797          	auipc	a5,0x1d
    80005cca:	33a78793          	addi	a5,a5,826 # 80023000 <disk>
    80005cce:	97aa                	add	a5,a5,a0
    80005cd0:	6509                	lui	a0,0x2
    80005cd2:	953e                	add	a0,a0,a5
    80005cd4:	4785                	li	a5,1
    80005cd6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005cda:	0001f517          	auipc	a0,0x1f
    80005cde:	33e50513          	addi	a0,a0,830 # 80025018 <disk+0x2018>
    80005ce2:	ffffc097          	auipc	ra,0xffffc
    80005ce6:	692080e7          	jalr	1682(ra) # 80002374 <wakeup>
}
    80005cea:	60a2                	ld	ra,8(sp)
    80005cec:	6402                	ld	s0,0(sp)
    80005cee:	0141                	addi	sp,sp,16
    80005cf0:	8082                	ret
    panic("free_desc 1");
    80005cf2:	00003517          	auipc	a0,0x3
    80005cf6:	a5e50513          	addi	a0,a0,-1442 # 80008750 <syscalls+0x330>
    80005cfa:	ffffb097          	auipc	ra,0xffffb
    80005cfe:	856080e7          	jalr	-1962(ra) # 80000550 <panic>
    panic("free_desc 2");
    80005d02:	00003517          	auipc	a0,0x3
    80005d06:	a5e50513          	addi	a0,a0,-1442 # 80008760 <syscalls+0x340>
    80005d0a:	ffffb097          	auipc	ra,0xffffb
    80005d0e:	846080e7          	jalr	-1978(ra) # 80000550 <panic>

0000000080005d12 <virtio_disk_init>:
{
    80005d12:	1101                	addi	sp,sp,-32
    80005d14:	ec06                	sd	ra,24(sp)
    80005d16:	e822                	sd	s0,16(sp)
    80005d18:	e426                	sd	s1,8(sp)
    80005d1a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d1c:	00003597          	auipc	a1,0x3
    80005d20:	a5458593          	addi	a1,a1,-1452 # 80008770 <syscalls+0x350>
    80005d24:	0001f517          	auipc	a0,0x1f
    80005d28:	40450513          	addi	a0,a0,1028 # 80025128 <disk+0x2128>
    80005d2c:	ffffb097          	auipc	ra,0xffffb
    80005d30:	e5c080e7          	jalr	-420(ra) # 80000b88 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d34:	100017b7          	lui	a5,0x10001
    80005d38:	4398                	lw	a4,0(a5)
    80005d3a:	2701                	sext.w	a4,a4
    80005d3c:	747277b7          	lui	a5,0x74727
    80005d40:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d44:	0ef71163          	bne	a4,a5,80005e26 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d48:	100017b7          	lui	a5,0x10001
    80005d4c:	43dc                	lw	a5,4(a5)
    80005d4e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d50:	4705                	li	a4,1
    80005d52:	0ce79a63          	bne	a5,a4,80005e26 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d56:	100017b7          	lui	a5,0x10001
    80005d5a:	479c                	lw	a5,8(a5)
    80005d5c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d5e:	4709                	li	a4,2
    80005d60:	0ce79363          	bne	a5,a4,80005e26 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d64:	100017b7          	lui	a5,0x10001
    80005d68:	47d8                	lw	a4,12(a5)
    80005d6a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d6c:	554d47b7          	lui	a5,0x554d4
    80005d70:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005d74:	0af71963          	bne	a4,a5,80005e26 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d78:	100017b7          	lui	a5,0x10001
    80005d7c:	4705                	li	a4,1
    80005d7e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d80:	470d                	li	a4,3
    80005d82:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005d84:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005d86:	c7ffe737          	lui	a4,0xc7ffe
    80005d8a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005d8e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d90:	2701                	sext.w	a4,a4
    80005d92:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d94:	472d                	li	a4,11
    80005d96:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d98:	473d                	li	a4,15
    80005d9a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005d9c:	6705                	lui	a4,0x1
    80005d9e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005da0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005da4:	5bdc                	lw	a5,52(a5)
    80005da6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005da8:	c7d9                	beqz	a5,80005e36 <virtio_disk_init+0x124>
  if(max < NUM)
    80005daa:	471d                	li	a4,7
    80005dac:	08f77d63          	bgeu	a4,a5,80005e46 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005db0:	100014b7          	lui	s1,0x10001
    80005db4:	47a1                	li	a5,8
    80005db6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005db8:	6609                	lui	a2,0x2
    80005dba:	4581                	li	a1,0
    80005dbc:	0001d517          	auipc	a0,0x1d
    80005dc0:	24450513          	addi	a0,a0,580 # 80023000 <disk>
    80005dc4:	ffffb097          	auipc	ra,0xffffb
    80005dc8:	f50080e7          	jalr	-176(ra) # 80000d14 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005dcc:	0001d717          	auipc	a4,0x1d
    80005dd0:	23470713          	addi	a4,a4,564 # 80023000 <disk>
    80005dd4:	00c75793          	srli	a5,a4,0xc
    80005dd8:	2781                	sext.w	a5,a5
    80005dda:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005ddc:	0001f797          	auipc	a5,0x1f
    80005de0:	22478793          	addi	a5,a5,548 # 80025000 <disk+0x2000>
    80005de4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005de6:	0001d717          	auipc	a4,0x1d
    80005dea:	29a70713          	addi	a4,a4,666 # 80023080 <disk+0x80>
    80005dee:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005df0:	0001e717          	auipc	a4,0x1e
    80005df4:	21070713          	addi	a4,a4,528 # 80024000 <disk+0x1000>
    80005df8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005dfa:	4705                	li	a4,1
    80005dfc:	00e78c23          	sb	a4,24(a5)
    80005e00:	00e78ca3          	sb	a4,25(a5)
    80005e04:	00e78d23          	sb	a4,26(a5)
    80005e08:	00e78da3          	sb	a4,27(a5)
    80005e0c:	00e78e23          	sb	a4,28(a5)
    80005e10:	00e78ea3          	sb	a4,29(a5)
    80005e14:	00e78f23          	sb	a4,30(a5)
    80005e18:	00e78fa3          	sb	a4,31(a5)
}
    80005e1c:	60e2                	ld	ra,24(sp)
    80005e1e:	6442                	ld	s0,16(sp)
    80005e20:	64a2                	ld	s1,8(sp)
    80005e22:	6105                	addi	sp,sp,32
    80005e24:	8082                	ret
    panic("could not find virtio disk");
    80005e26:	00003517          	auipc	a0,0x3
    80005e2a:	95a50513          	addi	a0,a0,-1702 # 80008780 <syscalls+0x360>
    80005e2e:	ffffa097          	auipc	ra,0xffffa
    80005e32:	722080e7          	jalr	1826(ra) # 80000550 <panic>
    panic("virtio disk has no queue 0");
    80005e36:	00003517          	auipc	a0,0x3
    80005e3a:	96a50513          	addi	a0,a0,-1686 # 800087a0 <syscalls+0x380>
    80005e3e:	ffffa097          	auipc	ra,0xffffa
    80005e42:	712080e7          	jalr	1810(ra) # 80000550 <panic>
    panic("virtio disk max queue too short");
    80005e46:	00003517          	auipc	a0,0x3
    80005e4a:	97a50513          	addi	a0,a0,-1670 # 800087c0 <syscalls+0x3a0>
    80005e4e:	ffffa097          	auipc	ra,0xffffa
    80005e52:	702080e7          	jalr	1794(ra) # 80000550 <panic>

0000000080005e56 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005e56:	7159                	addi	sp,sp,-112
    80005e58:	f486                	sd	ra,104(sp)
    80005e5a:	f0a2                	sd	s0,96(sp)
    80005e5c:	eca6                	sd	s1,88(sp)
    80005e5e:	e8ca                	sd	s2,80(sp)
    80005e60:	e4ce                	sd	s3,72(sp)
    80005e62:	e0d2                	sd	s4,64(sp)
    80005e64:	fc56                	sd	s5,56(sp)
    80005e66:	f85a                	sd	s6,48(sp)
    80005e68:	f45e                	sd	s7,40(sp)
    80005e6a:	f062                	sd	s8,32(sp)
    80005e6c:	ec66                	sd	s9,24(sp)
    80005e6e:	e86a                	sd	s10,16(sp)
    80005e70:	1880                	addi	s0,sp,112
    80005e72:	892a                	mv	s2,a0
    80005e74:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005e76:	00c52c83          	lw	s9,12(a0)
    80005e7a:	001c9c9b          	slliw	s9,s9,0x1
    80005e7e:	1c82                	slli	s9,s9,0x20
    80005e80:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005e84:	0001f517          	auipc	a0,0x1f
    80005e88:	2a450513          	addi	a0,a0,676 # 80025128 <disk+0x2128>
    80005e8c:	ffffb097          	auipc	ra,0xffffb
    80005e90:	d8c080e7          	jalr	-628(ra) # 80000c18 <acquire>
  for(int i = 0; i < 3; i++){
    80005e94:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005e96:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005e98:	0001db97          	auipc	s7,0x1d
    80005e9c:	168b8b93          	addi	s7,s7,360 # 80023000 <disk>
    80005ea0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005ea2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005ea4:	8a4e                	mv	s4,s3
    80005ea6:	a051                	j	80005f2a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005ea8:	00fb86b3          	add	a3,s7,a5
    80005eac:	96da                	add	a3,a3,s6
    80005eae:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005eb2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005eb4:	0207c563          	bltz	a5,80005ede <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005eb8:	2485                	addiw	s1,s1,1
    80005eba:	0711                	addi	a4,a4,4
    80005ebc:	25548063          	beq	s1,s5,800060fc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80005ec0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005ec2:	0001f697          	auipc	a3,0x1f
    80005ec6:	15668693          	addi	a3,a3,342 # 80025018 <disk+0x2018>
    80005eca:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005ecc:	0006c583          	lbu	a1,0(a3)
    80005ed0:	fde1                	bnez	a1,80005ea8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005ed2:	2785                	addiw	a5,a5,1
    80005ed4:	0685                	addi	a3,a3,1
    80005ed6:	ff879be3          	bne	a5,s8,80005ecc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005eda:	57fd                	li	a5,-1
    80005edc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005ede:	02905a63          	blez	s1,80005f12 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ee2:	f9042503          	lw	a0,-112(s0)
    80005ee6:	00000097          	auipc	ra,0x0
    80005eea:	d90080e7          	jalr	-624(ra) # 80005c76 <free_desc>
      for(int j = 0; j < i; j++)
    80005eee:	4785                	li	a5,1
    80005ef0:	0297d163          	bge	a5,s1,80005f12 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ef4:	f9442503          	lw	a0,-108(s0)
    80005ef8:	00000097          	auipc	ra,0x0
    80005efc:	d7e080e7          	jalr	-642(ra) # 80005c76 <free_desc>
      for(int j = 0; j < i; j++)
    80005f00:	4789                	li	a5,2
    80005f02:	0097d863          	bge	a5,s1,80005f12 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f06:	f9842503          	lw	a0,-104(s0)
    80005f0a:	00000097          	auipc	ra,0x0
    80005f0e:	d6c080e7          	jalr	-660(ra) # 80005c76 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f12:	0001f597          	auipc	a1,0x1f
    80005f16:	21658593          	addi	a1,a1,534 # 80025128 <disk+0x2128>
    80005f1a:	0001f517          	auipc	a0,0x1f
    80005f1e:	0fe50513          	addi	a0,a0,254 # 80025018 <disk+0x2018>
    80005f22:	ffffc097          	auipc	ra,0xffffc
    80005f26:	2cc080e7          	jalr	716(ra) # 800021ee <sleep>
  for(int i = 0; i < 3; i++){
    80005f2a:	f9040713          	addi	a4,s0,-112
    80005f2e:	84ce                	mv	s1,s3
    80005f30:	bf41                	j	80005ec0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80005f32:	20058713          	addi	a4,a1,512
    80005f36:	00471693          	slli	a3,a4,0x4
    80005f3a:	0001d717          	auipc	a4,0x1d
    80005f3e:	0c670713          	addi	a4,a4,198 # 80023000 <disk>
    80005f42:	9736                	add	a4,a4,a3
    80005f44:	4685                	li	a3,1
    80005f46:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005f4a:	20058713          	addi	a4,a1,512
    80005f4e:	00471693          	slli	a3,a4,0x4
    80005f52:	0001d717          	auipc	a4,0x1d
    80005f56:	0ae70713          	addi	a4,a4,174 # 80023000 <disk>
    80005f5a:	9736                	add	a4,a4,a3
    80005f5c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80005f60:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005f64:	7679                	lui	a2,0xffffe
    80005f66:	963e                	add	a2,a2,a5
    80005f68:	0001f697          	auipc	a3,0x1f
    80005f6c:	09868693          	addi	a3,a3,152 # 80025000 <disk+0x2000>
    80005f70:	6298                	ld	a4,0(a3)
    80005f72:	9732                	add	a4,a4,a2
    80005f74:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005f76:	6298                	ld	a4,0(a3)
    80005f78:	9732                	add	a4,a4,a2
    80005f7a:	4541                	li	a0,16
    80005f7c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005f7e:	6298                	ld	a4,0(a3)
    80005f80:	9732                	add	a4,a4,a2
    80005f82:	4505                	li	a0,1
    80005f84:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80005f88:	f9442703          	lw	a4,-108(s0)
    80005f8c:	6288                	ld	a0,0(a3)
    80005f8e:	962a                	add	a2,a2,a0
    80005f90:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005f94:	0712                	slli	a4,a4,0x4
    80005f96:	6290                	ld	a2,0(a3)
    80005f98:	963a                	add	a2,a2,a4
    80005f9a:	05890513          	addi	a0,s2,88
    80005f9e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005fa0:	6294                	ld	a3,0(a3)
    80005fa2:	96ba                	add	a3,a3,a4
    80005fa4:	40000613          	li	a2,1024
    80005fa8:	c690                	sw	a2,8(a3)
  if(write)
    80005faa:	140d0063          	beqz	s10,800060ea <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005fae:	0001f697          	auipc	a3,0x1f
    80005fb2:	0526b683          	ld	a3,82(a3) # 80025000 <disk+0x2000>
    80005fb6:	96ba                	add	a3,a3,a4
    80005fb8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005fbc:	0001d817          	auipc	a6,0x1d
    80005fc0:	04480813          	addi	a6,a6,68 # 80023000 <disk>
    80005fc4:	0001f517          	auipc	a0,0x1f
    80005fc8:	03c50513          	addi	a0,a0,60 # 80025000 <disk+0x2000>
    80005fcc:	6114                	ld	a3,0(a0)
    80005fce:	96ba                	add	a3,a3,a4
    80005fd0:	00c6d603          	lhu	a2,12(a3)
    80005fd4:	00166613          	ori	a2,a2,1
    80005fd8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80005fdc:	f9842683          	lw	a3,-104(s0)
    80005fe0:	6110                	ld	a2,0(a0)
    80005fe2:	9732                	add	a4,a4,a2
    80005fe4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005fe8:	20058613          	addi	a2,a1,512
    80005fec:	0612                	slli	a2,a2,0x4
    80005fee:	9642                	add	a2,a2,a6
    80005ff0:	577d                	li	a4,-1
    80005ff2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005ff6:	00469713          	slli	a4,a3,0x4
    80005ffa:	6114                	ld	a3,0(a0)
    80005ffc:	96ba                	add	a3,a3,a4
    80005ffe:	03078793          	addi	a5,a5,48
    80006002:	97c2                	add	a5,a5,a6
    80006004:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006006:	611c                	ld	a5,0(a0)
    80006008:	97ba                	add	a5,a5,a4
    8000600a:	4685                	li	a3,1
    8000600c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000600e:	611c                	ld	a5,0(a0)
    80006010:	97ba                	add	a5,a5,a4
    80006012:	4809                	li	a6,2
    80006014:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006018:	611c                	ld	a5,0(a0)
    8000601a:	973e                	add	a4,a4,a5
    8000601c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006020:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006024:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006028:	6518                	ld	a4,8(a0)
    8000602a:	00275783          	lhu	a5,2(a4)
    8000602e:	8b9d                	andi	a5,a5,7
    80006030:	0786                	slli	a5,a5,0x1
    80006032:	97ba                	add	a5,a5,a4
    80006034:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006038:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000603c:	6518                	ld	a4,8(a0)
    8000603e:	00275783          	lhu	a5,2(a4)
    80006042:	2785                	addiw	a5,a5,1
    80006044:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006048:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000604c:	100017b7          	lui	a5,0x10001
    80006050:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006054:	00492703          	lw	a4,4(s2)
    80006058:	4785                	li	a5,1
    8000605a:	02f71163          	bne	a4,a5,8000607c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000605e:	0001f997          	auipc	s3,0x1f
    80006062:	0ca98993          	addi	s3,s3,202 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006066:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006068:	85ce                	mv	a1,s3
    8000606a:	854a                	mv	a0,s2
    8000606c:	ffffc097          	auipc	ra,0xffffc
    80006070:	182080e7          	jalr	386(ra) # 800021ee <sleep>
  while(b->disk == 1) {
    80006074:	00492783          	lw	a5,4(s2)
    80006078:	fe9788e3          	beq	a5,s1,80006068 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000607c:	f9042903          	lw	s2,-112(s0)
    80006080:	20090793          	addi	a5,s2,512
    80006084:	00479713          	slli	a4,a5,0x4
    80006088:	0001d797          	auipc	a5,0x1d
    8000608c:	f7878793          	addi	a5,a5,-136 # 80023000 <disk>
    80006090:	97ba                	add	a5,a5,a4
    80006092:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006096:	0001f997          	auipc	s3,0x1f
    8000609a:	f6a98993          	addi	s3,s3,-150 # 80025000 <disk+0x2000>
    8000609e:	00491713          	slli	a4,s2,0x4
    800060a2:	0009b783          	ld	a5,0(s3)
    800060a6:	97ba                	add	a5,a5,a4
    800060a8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800060ac:	854a                	mv	a0,s2
    800060ae:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800060b2:	00000097          	auipc	ra,0x0
    800060b6:	bc4080e7          	jalr	-1084(ra) # 80005c76 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800060ba:	8885                	andi	s1,s1,1
    800060bc:	f0ed                	bnez	s1,8000609e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800060be:	0001f517          	auipc	a0,0x1f
    800060c2:	06a50513          	addi	a0,a0,106 # 80025128 <disk+0x2128>
    800060c6:	ffffb097          	auipc	ra,0xffffb
    800060ca:	c06080e7          	jalr	-1018(ra) # 80000ccc <release>
}
    800060ce:	70a6                	ld	ra,104(sp)
    800060d0:	7406                	ld	s0,96(sp)
    800060d2:	64e6                	ld	s1,88(sp)
    800060d4:	6946                	ld	s2,80(sp)
    800060d6:	69a6                	ld	s3,72(sp)
    800060d8:	6a06                	ld	s4,64(sp)
    800060da:	7ae2                	ld	s5,56(sp)
    800060dc:	7b42                	ld	s6,48(sp)
    800060de:	7ba2                	ld	s7,40(sp)
    800060e0:	7c02                	ld	s8,32(sp)
    800060e2:	6ce2                	ld	s9,24(sp)
    800060e4:	6d42                	ld	s10,16(sp)
    800060e6:	6165                	addi	sp,sp,112
    800060e8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800060ea:	0001f697          	auipc	a3,0x1f
    800060ee:	f166b683          	ld	a3,-234(a3) # 80025000 <disk+0x2000>
    800060f2:	96ba                	add	a3,a3,a4
    800060f4:	4609                	li	a2,2
    800060f6:	00c69623          	sh	a2,12(a3)
    800060fa:	b5c9                	j	80005fbc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060fc:	f9042583          	lw	a1,-112(s0)
    80006100:	20058793          	addi	a5,a1,512
    80006104:	0792                	slli	a5,a5,0x4
    80006106:	0001d517          	auipc	a0,0x1d
    8000610a:	fa250513          	addi	a0,a0,-94 # 800230a8 <disk+0xa8>
    8000610e:	953e                	add	a0,a0,a5
  if(write)
    80006110:	e20d11e3          	bnez	s10,80005f32 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006114:	20058713          	addi	a4,a1,512
    80006118:	00471693          	slli	a3,a4,0x4
    8000611c:	0001d717          	auipc	a4,0x1d
    80006120:	ee470713          	addi	a4,a4,-284 # 80023000 <disk>
    80006124:	9736                	add	a4,a4,a3
    80006126:	0a072423          	sw	zero,168(a4)
    8000612a:	b505                	j	80005f4a <virtio_disk_rw+0xf4>

000000008000612c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000612c:	1101                	addi	sp,sp,-32
    8000612e:	ec06                	sd	ra,24(sp)
    80006130:	e822                	sd	s0,16(sp)
    80006132:	e426                	sd	s1,8(sp)
    80006134:	e04a                	sd	s2,0(sp)
    80006136:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006138:	0001f517          	auipc	a0,0x1f
    8000613c:	ff050513          	addi	a0,a0,-16 # 80025128 <disk+0x2128>
    80006140:	ffffb097          	auipc	ra,0xffffb
    80006144:	ad8080e7          	jalr	-1320(ra) # 80000c18 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006148:	10001737          	lui	a4,0x10001
    8000614c:	533c                	lw	a5,96(a4)
    8000614e:	8b8d                	andi	a5,a5,3
    80006150:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006152:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006156:	0001f797          	auipc	a5,0x1f
    8000615a:	eaa78793          	addi	a5,a5,-342 # 80025000 <disk+0x2000>
    8000615e:	6b94                	ld	a3,16(a5)
    80006160:	0207d703          	lhu	a4,32(a5)
    80006164:	0026d783          	lhu	a5,2(a3)
    80006168:	06f70163          	beq	a4,a5,800061ca <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000616c:	0001d917          	auipc	s2,0x1d
    80006170:	e9490913          	addi	s2,s2,-364 # 80023000 <disk>
    80006174:	0001f497          	auipc	s1,0x1f
    80006178:	e8c48493          	addi	s1,s1,-372 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000617c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006180:	6898                	ld	a4,16(s1)
    80006182:	0204d783          	lhu	a5,32(s1)
    80006186:	8b9d                	andi	a5,a5,7
    80006188:	078e                	slli	a5,a5,0x3
    8000618a:	97ba                	add	a5,a5,a4
    8000618c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000618e:	20078713          	addi	a4,a5,512
    80006192:	0712                	slli	a4,a4,0x4
    80006194:	974a                	add	a4,a4,s2
    80006196:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000619a:	e731                	bnez	a4,800061e6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000619c:	20078793          	addi	a5,a5,512
    800061a0:	0792                	slli	a5,a5,0x4
    800061a2:	97ca                	add	a5,a5,s2
    800061a4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800061a6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800061aa:	ffffc097          	auipc	ra,0xffffc
    800061ae:	1ca080e7          	jalr	458(ra) # 80002374 <wakeup>

    disk.used_idx += 1;
    800061b2:	0204d783          	lhu	a5,32(s1)
    800061b6:	2785                	addiw	a5,a5,1
    800061b8:	17c2                	slli	a5,a5,0x30
    800061ba:	93c1                	srli	a5,a5,0x30
    800061bc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800061c0:	6898                	ld	a4,16(s1)
    800061c2:	00275703          	lhu	a4,2(a4)
    800061c6:	faf71be3          	bne	a4,a5,8000617c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800061ca:	0001f517          	auipc	a0,0x1f
    800061ce:	f5e50513          	addi	a0,a0,-162 # 80025128 <disk+0x2128>
    800061d2:	ffffb097          	auipc	ra,0xffffb
    800061d6:	afa080e7          	jalr	-1286(ra) # 80000ccc <release>
}
    800061da:	60e2                	ld	ra,24(sp)
    800061dc:	6442                	ld	s0,16(sp)
    800061de:	64a2                	ld	s1,8(sp)
    800061e0:	6902                	ld	s2,0(sp)
    800061e2:	6105                	addi	sp,sp,32
    800061e4:	8082                	ret
      panic("virtio_disk_intr status");
    800061e6:	00002517          	auipc	a0,0x2
    800061ea:	5fa50513          	addi	a0,a0,1530 # 800087e0 <syscalls+0x3c0>
    800061ee:	ffffa097          	auipc	ra,0xffffa
    800061f2:	362080e7          	jalr	866(ra) # 80000550 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
