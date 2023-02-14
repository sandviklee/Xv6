
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	ae010113          	addi	sp,sp,-1312 # 80008ae0 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
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
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	95070713          	addi	a4,a4,-1712 # 800089a0 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	c2e78793          	addi	a5,a5,-978 # 80005c90 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc9ef>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dc678793          	addi	a5,a5,-570 # 80000e72 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	382080e7          	jalr	898(ra) # 800024ac <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	780080e7          	jalr	1920(ra) # 800008ba <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	711d                	addi	sp,sp,-96
    80000166:	ec86                	sd	ra,88(sp)
    80000168:	e8a2                	sd	s0,80(sp)
    8000016a:	e4a6                	sd	s1,72(sp)
    8000016c:	e0ca                	sd	s2,64(sp)
    8000016e:	fc4e                	sd	s3,56(sp)
    80000170:	f852                	sd	s4,48(sp)
    80000172:	f456                	sd	s5,40(sp)
    80000174:	f05a                	sd	s6,32(sp)
    80000176:	ec5e                	sd	s7,24(sp)
    80000178:	1080                	addi	s0,sp,96
    8000017a:	8aaa                	mv	s5,a0
    8000017c:	8a2e                	mv	s4,a1
    8000017e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000180:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000184:	00011517          	auipc	a0,0x11
    80000188:	95c50513          	addi	a0,a0,-1700 # 80010ae0 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	a46080e7          	jalr	-1466(ra) # 80000bd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	94c48493          	addi	s1,s1,-1716 # 80010ae0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	9dc90913          	addi	s2,s2,-1572 # 80010b78 <cons+0x98>
  while(n > 0){
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
    while(cons.r == cons.w){
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
      if(killed(myproc())){
    800001b4:	00001097          	auipc	ra,0x1
    800001b8:	7f2080e7          	jalr	2034(ra) # 800019a6 <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	13a080e7          	jalr	314(ra) # 800022f6 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	e84080e7          	jalr	-380(ra) # 8000204e <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	90270713          	addi	a4,a4,-1790 # 80010ae0 <cons>
    800001e6:	0017869b          	addiw	a3,a5,1
    800001ea:	08d72c23          	sw	a3,152(a4)
    800001ee:	07f7f693          	andi	a3,a5,127
    800001f2:	9736                	add	a4,a4,a3
    800001f4:	01874703          	lbu	a4,24(a4)
    800001f8:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001fc:	4691                	li	a3,4
    800001fe:	06db8463          	beq	s7,a3,80000266 <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000202:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	faf40613          	addi	a2,s0,-81
    8000020c:	85d2                	mv	a1,s4
    8000020e:	8556                	mv	a0,s5
    80000210:	00002097          	auipc	ra,0x2
    80000214:	246080e7          	jalr	582(ra) # 80002456 <either_copyout>
    80000218:	57fd                	li	a5,-1
    8000021a:	00f50763          	beq	a0,a5,80000228 <consoleread+0xc4>
      break;

    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    80000222:	47a9                	li	a5,10
    80000224:	f8fb90e3          	bne	s7,a5,800001a4 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	8b850513          	addi	a0,a0,-1864 # 80010ae0 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	8a250513          	addi	a0,a0,-1886 # 80010ae0 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	a40080e7          	jalr	-1472(ra) # 80000c86 <release>
        return -1;
    8000024e:	557d                	li	a0,-1
}
    80000250:	60e6                	ld	ra,88(sp)
    80000252:	6446                	ld	s0,80(sp)
    80000254:	64a6                	ld	s1,72(sp)
    80000256:	6906                	ld	s2,64(sp)
    80000258:	79e2                	ld	s3,56(sp)
    8000025a:	7a42                	ld	s4,48(sp)
    8000025c:	7aa2                	ld	s5,40(sp)
    8000025e:	7b02                	ld	s6,32(sp)
    80000260:	6be2                	ld	s7,24(sp)
    80000262:	6125                	addi	sp,sp,96
    80000264:	8082                	ret
      if(n < target){
    80000266:	0009871b          	sext.w	a4,s3
    8000026a:	fb677fe3          	bgeu	a4,s6,80000228 <consoleread+0xc4>
        cons.r--;
    8000026e:	00011717          	auipc	a4,0x11
    80000272:	90f72523          	sw	a5,-1782(a4) # 80010b78 <cons+0x98>
    80000276:	bf4d                	j	80000228 <consoleread+0xc4>

0000000080000278 <consputc>:
{
    80000278:	1141                	addi	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000280:	10000793          	li	a5,256
    80000284:	00f50a63          	beq	a0,a5,80000298 <consputc+0x20>
    uartputc_sync(c);
    80000288:	00000097          	auipc	ra,0x0
    8000028c:	560080e7          	jalr	1376(ra) # 800007e8 <uartputc_sync>
}
    80000290:	60a2                	ld	ra,8(sp)
    80000292:	6402                	ld	s0,0(sp)
    80000294:	0141                	addi	sp,sp,16
    80000296:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000298:	4521                	li	a0,8
    8000029a:	00000097          	auipc	ra,0x0
    8000029e:	54e080e7          	jalr	1358(ra) # 800007e8 <uartputc_sync>
    800002a2:	02000513          	li	a0,32
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	542080e7          	jalr	1346(ra) # 800007e8 <uartputc_sync>
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	538080e7          	jalr	1336(ra) # 800007e8 <uartputc_sync>
    800002b8:	bfe1                	j	80000290 <consputc+0x18>

00000000800002ba <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002ba:	1101                	addi	sp,sp,-32
    800002bc:	ec06                	sd	ra,24(sp)
    800002be:	e822                	sd	s0,16(sp)
    800002c0:	e426                	sd	s1,8(sp)
    800002c2:	e04a                	sd	s2,0(sp)
    800002c4:	1000                	addi	s0,sp,32
    800002c6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c8:	00011517          	auipc	a0,0x11
    800002cc:	81850513          	addi	a0,a0,-2024 # 80010ae0 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	902080e7          	jalr	-1790(ra) # 80000bd2 <acquire>

  switch(c){
    800002d8:	47d5                	li	a5,21
    800002da:	0af48663          	beq	s1,a5,80000386 <consoleintr+0xcc>
    800002de:	0297ca63          	blt	a5,s1,80000312 <consoleintr+0x58>
    800002e2:	47a1                	li	a5,8
    800002e4:	0ef48763          	beq	s1,a5,800003d2 <consoleintr+0x118>
    800002e8:	47c1                	li	a5,16
    800002ea:	10f49a63          	bne	s1,a5,800003fe <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ee:	00002097          	auipc	ra,0x2
    800002f2:	214080e7          	jalr	532(ra) # 80002502 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	7ea50513          	addi	a0,a0,2026 # 80010ae0 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	988080e7          	jalr	-1656(ra) # 80000c86 <release>
}
    80000306:	60e2                	ld	ra,24(sp)
    80000308:	6442                	ld	s0,16(sp)
    8000030a:	64a2                	ld	s1,8(sp)
    8000030c:	6902                	ld	s2,0(sp)
    8000030e:	6105                	addi	sp,sp,32
    80000310:	8082                	ret
  switch(c){
    80000312:	07f00793          	li	a5,127
    80000316:	0af48e63          	beq	s1,a5,800003d2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031a:	00010717          	auipc	a4,0x10
    8000031e:	7c670713          	addi	a4,a4,1990 # 80010ae0 <cons>
    80000322:	0a072783          	lw	a5,160(a4)
    80000326:	09872703          	lw	a4,152(a4)
    8000032a:	9f99                	subw	a5,a5,a4
    8000032c:	07f00713          	li	a4,127
    80000330:	fcf763e3          	bltu	a4,a5,800002f6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000334:	47b5                	li	a5,13
    80000336:	0cf48763          	beq	s1,a5,80000404 <consoleintr+0x14a>
      consputc(c);
    8000033a:	8526                	mv	a0,s1
    8000033c:	00000097          	auipc	ra,0x0
    80000340:	f3c080e7          	jalr	-196(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000344:	00010797          	auipc	a5,0x10
    80000348:	79c78793          	addi	a5,a5,1948 # 80010ae0 <cons>
    8000034c:	0a07a683          	lw	a3,160(a5)
    80000350:	0016871b          	addiw	a4,a3,1
    80000354:	0007061b          	sext.w	a2,a4
    80000358:	0ae7a023          	sw	a4,160(a5)
    8000035c:	07f6f693          	andi	a3,a3,127
    80000360:	97b6                	add	a5,a5,a3
    80000362:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000366:	47a9                	li	a5,10
    80000368:	0cf48563          	beq	s1,a5,80000432 <consoleintr+0x178>
    8000036c:	4791                	li	a5,4
    8000036e:	0cf48263          	beq	s1,a5,80000432 <consoleintr+0x178>
    80000372:	00011797          	auipc	a5,0x11
    80000376:	8067a783          	lw	a5,-2042(a5) # 80010b78 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	75a70713          	addi	a4,a4,1882 # 80010ae0 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	74a48493          	addi	s1,s1,1866 # 80010ae0 <cons>
    while(cons.e != cons.w &&
    8000039e:	4929                	li	s2,10
    800003a0:	f4f70be3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a4:	37fd                	addiw	a5,a5,-1
    800003a6:	07f7f713          	andi	a4,a5,127
    800003aa:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ac:	01874703          	lbu	a4,24(a4)
    800003b0:	f52703e3          	beq	a4,s2,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003b4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b8:	10000513          	li	a0,256
    800003bc:	00000097          	auipc	ra,0x0
    800003c0:	ebc080e7          	jalr	-324(ra) # 80000278 <consputc>
    while(cons.e != cons.w &&
    800003c4:	0a04a783          	lw	a5,160(s1)
    800003c8:	09c4a703          	lw	a4,156(s1)
    800003cc:	fcf71ce3          	bne	a4,a5,800003a4 <consoleintr+0xea>
    800003d0:	b71d                	j	800002f6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d2:	00010717          	auipc	a4,0x10
    800003d6:	70e70713          	addi	a4,a4,1806 # 80010ae0 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addiw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	78f72c23          	sw	a5,1944(a4) # 80010b80 <cons+0xa0>
      consputc(BACKSPACE);
    800003f0:	10000513          	li	a0,256
    800003f4:	00000097          	auipc	ra,0x0
    800003f8:	e84080e7          	jalr	-380(ra) # 80000278 <consputc>
    800003fc:	bded                	j	800002f6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003fe:	ee048ce3          	beqz	s1,800002f6 <consoleintr+0x3c>
    80000402:	bf21                	j	8000031a <consoleintr+0x60>
      consputc(c);
    80000404:	4529                	li	a0,10
    80000406:	00000097          	auipc	ra,0x0
    8000040a:	e72080e7          	jalr	-398(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000040e:	00010797          	auipc	a5,0x10
    80000412:	6d278793          	addi	a5,a5,1746 # 80010ae0 <cons>
    80000416:	0a07a703          	lw	a4,160(a5)
    8000041a:	0017069b          	addiw	a3,a4,1
    8000041e:	0006861b          	sext.w	a2,a3
    80000422:	0ad7a023          	sw	a3,160(a5)
    80000426:	07f77713          	andi	a4,a4,127
    8000042a:	97ba                	add	a5,a5,a4
    8000042c:	4729                	li	a4,10
    8000042e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000432:	00010797          	auipc	a5,0x10
    80000436:	74c7a523          	sw	a2,1866(a5) # 80010b7c <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	73e50513          	addi	a0,a0,1854 # 80010b78 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	c70080e7          	jalr	-912(ra) # 800020b2 <wakeup>
    8000044a:	b575                	j	800002f6 <consoleintr+0x3c>

000000008000044c <consoleinit>:

void
consoleinit(void)
{
    8000044c:	1141                	addi	sp,sp,-16
    8000044e:	e406                	sd	ra,8(sp)
    80000450:	e022                	sd	s0,0(sp)
    80000452:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000454:	00008597          	auipc	a1,0x8
    80000458:	bbc58593          	addi	a1,a1,-1092 # 80008010 <etext+0x10>
    8000045c:	00010517          	auipc	a0,0x10
    80000460:	68450513          	addi	a0,a0,1668 # 80010ae0 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	6de080e7          	jalr	1758(ra) # 80000b42 <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00021797          	auipc	a5,0x21
    80000478:	80478793          	addi	a5,a5,-2044 # 80020c78 <devsw>
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	ce870713          	addi	a4,a4,-792 # 80000164 <consoleread>
    80000484:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	c7a70713          	addi	a4,a4,-902 # 80000100 <consolewrite>
    8000048e:	ef98                	sd	a4,24(a5)
}
    80000490:	60a2                	ld	ra,8(sp)
    80000492:	6402                	ld	s0,0(sp)
    80000494:	0141                	addi	sp,sp,16
    80000496:	8082                	ret

0000000080000498 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000498:	7179                	addi	sp,sp,-48
    8000049a:	f406                	sd	ra,40(sp)
    8000049c:	f022                	sd	s0,32(sp)
    8000049e:	ec26                	sd	s1,24(sp)
    800004a0:	e84a                	sd	s2,16(sp)
    800004a2:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a4:	c219                	beqz	a2,800004aa <printint+0x12>
    800004a6:	08054763          	bltz	a0,80000534 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004aa:	2501                	sext.w	a0,a0
    800004ac:	4881                	li	a7,0
    800004ae:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b4:	2581                	sext.w	a1,a1
    800004b6:	00008617          	auipc	a2,0x8
    800004ba:	b8a60613          	addi	a2,a2,-1142 # 80008040 <digits>
    800004be:	883a                	mv	a6,a4
    800004c0:	2705                	addiw	a4,a4,1
    800004c2:	02b577bb          	remuw	a5,a0,a1
    800004c6:	1782                	slli	a5,a5,0x20
    800004c8:	9381                	srli	a5,a5,0x20
    800004ca:	97b2                	add	a5,a5,a2
    800004cc:	0007c783          	lbu	a5,0(a5)
    800004d0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d4:	0005079b          	sext.w	a5,a0
    800004d8:	02b5553b          	divuw	a0,a0,a1
    800004dc:	0685                	addi	a3,a3,1
    800004de:	feb7f0e3          	bgeu	a5,a1,800004be <printint+0x26>

  if(sign)
    800004e2:	00088c63          	beqz	a7,800004fa <printint+0x62>
    buf[i++] = '-';
    800004e6:	fe070793          	addi	a5,a4,-32
    800004ea:	00878733          	add	a4,a5,s0
    800004ee:	02d00793          	li	a5,45
    800004f2:	fef70823          	sb	a5,-16(a4)
    800004f6:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fa:	02e05763          	blez	a4,80000528 <printint+0x90>
    800004fe:	fd040793          	addi	a5,s0,-48
    80000502:	00e784b3          	add	s1,a5,a4
    80000506:	fff78913          	addi	s2,a5,-1
    8000050a:	993a                	add	s2,s2,a4
    8000050c:	377d                	addiw	a4,a4,-1
    8000050e:	1702                	slli	a4,a4,0x20
    80000510:	9301                	srli	a4,a4,0x20
    80000512:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000516:	fff4c503          	lbu	a0,-1(s1)
    8000051a:	00000097          	auipc	ra,0x0
    8000051e:	d5e080e7          	jalr	-674(ra) # 80000278 <consputc>
  while(--i >= 0)
    80000522:	14fd                	addi	s1,s1,-1
    80000524:	ff2499e3          	bne	s1,s2,80000516 <printint+0x7e>
}
    80000528:	70a2                	ld	ra,40(sp)
    8000052a:	7402                	ld	s0,32(sp)
    8000052c:	64e2                	ld	s1,24(sp)
    8000052e:	6942                	ld	s2,16(sp)
    80000530:	6145                	addi	sp,sp,48
    80000532:	8082                	ret
    x = -xx;
    80000534:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000538:	4885                	li	a7,1
    x = -xx;
    8000053a:	bf95                	j	800004ae <printint+0x16>

000000008000053c <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053c:	1101                	addi	sp,sp,-32
    8000053e:	ec06                	sd	ra,24(sp)
    80000540:	e822                	sd	s0,16(sp)
    80000542:	e426                	sd	s1,8(sp)
    80000544:	1000                	addi	s0,sp,32
    80000546:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000548:	00010797          	auipc	a5,0x10
    8000054c:	6407ac23          	sw	zero,1624(a5) # 80010ba0 <pr+0x18>
  printf("panic: ");
    80000550:	00008517          	auipc	a0,0x8
    80000554:	ac850513          	addi	a0,a0,-1336 # 80008018 <etext+0x18>
    80000558:	00000097          	auipc	ra,0x0
    8000055c:	02e080e7          	jalr	46(ra) # 80000586 <printf>
  printf(s);
    80000560:	8526                	mv	a0,s1
    80000562:	00000097          	auipc	ra,0x0
    80000566:	024080e7          	jalr	36(ra) # 80000586 <printf>
  printf("\n");
    8000056a:	00008517          	auipc	a0,0x8
    8000056e:	b5e50513          	addi	a0,a0,-1186 # 800080c8 <digits+0x88>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	014080e7          	jalr	20(ra) # 80000586 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057a:	4785                	li	a5,1
    8000057c:	00008717          	auipc	a4,0x8
    80000580:	3ef72223          	sw	a5,996(a4) # 80008960 <panicked>
  for(;;)
    80000584:	a001                	j	80000584 <panic+0x48>

0000000080000586 <printf>:
{
    80000586:	7131                	addi	sp,sp,-192
    80000588:	fc86                	sd	ra,120(sp)
    8000058a:	f8a2                	sd	s0,112(sp)
    8000058c:	f4a6                	sd	s1,104(sp)
    8000058e:	f0ca                	sd	s2,96(sp)
    80000590:	ecce                	sd	s3,88(sp)
    80000592:	e8d2                	sd	s4,80(sp)
    80000594:	e4d6                	sd	s5,72(sp)
    80000596:	e0da                	sd	s6,64(sp)
    80000598:	fc5e                	sd	s7,56(sp)
    8000059a:	f862                	sd	s8,48(sp)
    8000059c:	f466                	sd	s9,40(sp)
    8000059e:	f06a                	sd	s10,32(sp)
    800005a0:	ec6e                	sd	s11,24(sp)
    800005a2:	0100                	addi	s0,sp,128
    800005a4:	8a2a                	mv	s4,a0
    800005a6:	e40c                	sd	a1,8(s0)
    800005a8:	e810                	sd	a2,16(s0)
    800005aa:	ec14                	sd	a3,24(s0)
    800005ac:	f018                	sd	a4,32(s0)
    800005ae:	f41c                	sd	a5,40(s0)
    800005b0:	03043823          	sd	a6,48(s0)
    800005b4:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b8:	00010d97          	auipc	s11,0x10
    800005bc:	5e8dad83          	lw	s11,1512(s11) # 80010ba0 <pr+0x18>
  if(locking)
    800005c0:	020d9b63          	bnez	s11,800005f6 <printf+0x70>
  if (fmt == 0)
    800005c4:	040a0263          	beqz	s4,80000608 <printf+0x82>
  va_start(ap, fmt);
    800005c8:	00840793          	addi	a5,s0,8
    800005cc:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d0:	000a4503          	lbu	a0,0(s4)
    800005d4:	14050f63          	beqz	a0,80000732 <printf+0x1ac>
    800005d8:	4981                	li	s3,0
    if(c != '%'){
    800005da:	02500a93          	li	s5,37
    switch(c){
    800005de:	07000b93          	li	s7,112
  consputc('x');
    800005e2:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e4:	00008b17          	auipc	s6,0x8
    800005e8:	a5cb0b13          	addi	s6,s6,-1444 # 80008040 <digits>
    switch(c){
    800005ec:	07300c93          	li	s9,115
    800005f0:	06400c13          	li	s8,100
    800005f4:	a82d                	j	8000062e <printf+0xa8>
    acquire(&pr.lock);
    800005f6:	00010517          	auipc	a0,0x10
    800005fa:	59250513          	addi	a0,a0,1426 # 80010b88 <pr>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	5d4080e7          	jalr	1492(ra) # 80000bd2 <acquire>
    80000606:	bf7d                	j	800005c4 <printf+0x3e>
    panic("null fmt");
    80000608:	00008517          	auipc	a0,0x8
    8000060c:	a2050513          	addi	a0,a0,-1504 # 80008028 <etext+0x28>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	f2c080e7          	jalr	-212(ra) # 8000053c <panic>
      consputc(c);
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	c60080e7          	jalr	-928(ra) # 80000278 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000620:	2985                	addiw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c503          	lbu	a0,0(a5)
    8000062a:	10050463          	beqz	a0,80000732 <printf+0x1ac>
    if(c != '%'){
    8000062e:	ff5515e3          	bne	a0,s5,80000618 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000632:	2985                	addiw	s3,s3,1
    80000634:	013a07b3          	add	a5,s4,s3
    80000638:	0007c783          	lbu	a5,0(a5)
    8000063c:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000640:	cbed                	beqz	a5,80000732 <printf+0x1ac>
    switch(c){
    80000642:	05778a63          	beq	a5,s7,80000696 <printf+0x110>
    80000646:	02fbf663          	bgeu	s7,a5,80000672 <printf+0xec>
    8000064a:	09978863          	beq	a5,s9,800006da <printf+0x154>
    8000064e:	07800713          	li	a4,120
    80000652:	0ce79563          	bne	a5,a4,8000071c <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000656:	f8843783          	ld	a5,-120(s0)
    8000065a:	00878713          	addi	a4,a5,8
    8000065e:	f8e43423          	sd	a4,-120(s0)
    80000662:	4605                	li	a2,1
    80000664:	85ea                	mv	a1,s10
    80000666:	4388                	lw	a0,0(a5)
    80000668:	00000097          	auipc	ra,0x0
    8000066c:	e30080e7          	jalr	-464(ra) # 80000498 <printint>
      break;
    80000670:	bf45                	j	80000620 <printf+0x9a>
    switch(c){
    80000672:	09578f63          	beq	a5,s5,80000710 <printf+0x18a>
    80000676:	0b879363          	bne	a5,s8,8000071c <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067a:	f8843783          	ld	a5,-120(s0)
    8000067e:	00878713          	addi	a4,a5,8
    80000682:	f8e43423          	sd	a4,-120(s0)
    80000686:	4605                	li	a2,1
    80000688:	45a9                	li	a1,10
    8000068a:	4388                	lw	a0,0(a5)
    8000068c:	00000097          	auipc	ra,0x0
    80000690:	e0c080e7          	jalr	-500(ra) # 80000498 <printint>
      break;
    80000694:	b771                	j	80000620 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	addi	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a6:	03000513          	li	a0,48
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bce080e7          	jalr	-1074(ra) # 80000278 <consputc>
  consputc('x');
    800006b2:	07800513          	li	a0,120
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bc2080e7          	jalr	-1086(ra) # 80000278 <consputc>
    800006be:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c0:	03c95793          	srli	a5,s2,0x3c
    800006c4:	97da                	add	a5,a5,s6
    800006c6:	0007c503          	lbu	a0,0(a5)
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bae080e7          	jalr	-1106(ra) # 80000278 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d2:	0912                	slli	s2,s2,0x4
    800006d4:	34fd                	addiw	s1,s1,-1
    800006d6:	f4ed                	bnez	s1,800006c0 <printf+0x13a>
    800006d8:	b7a1                	j	80000620 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006da:	f8843783          	ld	a5,-120(s0)
    800006de:	00878713          	addi	a4,a5,8
    800006e2:	f8e43423          	sd	a4,-120(s0)
    800006e6:	6384                	ld	s1,0(a5)
    800006e8:	cc89                	beqz	s1,80000702 <printf+0x17c>
      for(; *s; s++)
    800006ea:	0004c503          	lbu	a0,0(s1)
    800006ee:	d90d                	beqz	a0,80000620 <printf+0x9a>
        consputc(*s);
    800006f0:	00000097          	auipc	ra,0x0
    800006f4:	b88080e7          	jalr	-1144(ra) # 80000278 <consputc>
      for(; *s; s++)
    800006f8:	0485                	addi	s1,s1,1
    800006fa:	0004c503          	lbu	a0,0(s1)
    800006fe:	f96d                	bnez	a0,800006f0 <printf+0x16a>
    80000700:	b705                	j	80000620 <printf+0x9a>
        s = "(null)";
    80000702:	00008497          	auipc	s1,0x8
    80000706:	91e48493          	addi	s1,s1,-1762 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070a:	02800513          	li	a0,40
    8000070e:	b7cd                	j	800006f0 <printf+0x16a>
      consputc('%');
    80000710:	8556                	mv	a0,s5
    80000712:	00000097          	auipc	ra,0x0
    80000716:	b66080e7          	jalr	-1178(ra) # 80000278 <consputc>
      break;
    8000071a:	b719                	j	80000620 <printf+0x9a>
      consputc('%');
    8000071c:	8556                	mv	a0,s5
    8000071e:	00000097          	auipc	ra,0x0
    80000722:	b5a080e7          	jalr	-1190(ra) # 80000278 <consputc>
      consputc(c);
    80000726:	8526                	mv	a0,s1
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b50080e7          	jalr	-1200(ra) # 80000278 <consputc>
      break;
    80000730:	bdc5                	j	80000620 <printf+0x9a>
  if(locking)
    80000732:	020d9163          	bnez	s11,80000754 <printf+0x1ce>
}
    80000736:	70e6                	ld	ra,120(sp)
    80000738:	7446                	ld	s0,112(sp)
    8000073a:	74a6                	ld	s1,104(sp)
    8000073c:	7906                	ld	s2,96(sp)
    8000073e:	69e6                	ld	s3,88(sp)
    80000740:	6a46                	ld	s4,80(sp)
    80000742:	6aa6                	ld	s5,72(sp)
    80000744:	6b06                	ld	s6,64(sp)
    80000746:	7be2                	ld	s7,56(sp)
    80000748:	7c42                	ld	s8,48(sp)
    8000074a:	7ca2                	ld	s9,40(sp)
    8000074c:	7d02                	ld	s10,32(sp)
    8000074e:	6de2                	ld	s11,24(sp)
    80000750:	6129                	addi	sp,sp,192
    80000752:	8082                	ret
    release(&pr.lock);
    80000754:	00010517          	auipc	a0,0x10
    80000758:	43450513          	addi	a0,a0,1076 # 80010b88 <pr>
    8000075c:	00000097          	auipc	ra,0x0
    80000760:	52a080e7          	jalr	1322(ra) # 80000c86 <release>
}
    80000764:	bfc9                	j	80000736 <printf+0x1b0>

0000000080000766 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000766:	1101                	addi	sp,sp,-32
    80000768:	ec06                	sd	ra,24(sp)
    8000076a:	e822                	sd	s0,16(sp)
    8000076c:	e426                	sd	s1,8(sp)
    8000076e:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000770:	00010497          	auipc	s1,0x10
    80000774:	41848493          	addi	s1,s1,1048 # 80010b88 <pr>
    80000778:	00008597          	auipc	a1,0x8
    8000077c:	8c058593          	addi	a1,a1,-1856 # 80008038 <etext+0x38>
    80000780:	8526                	mv	a0,s1
    80000782:	00000097          	auipc	ra,0x0
    80000786:	3c0080e7          	jalr	960(ra) # 80000b42 <initlock>
  pr.locking = 1;
    8000078a:	4785                	li	a5,1
    8000078c:	cc9c                	sw	a5,24(s1)
}
    8000078e:	60e2                	ld	ra,24(sp)
    80000790:	6442                	ld	s0,16(sp)
    80000792:	64a2                	ld	s1,8(sp)
    80000794:	6105                	addi	sp,sp,32
    80000796:	8082                	ret

0000000080000798 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000798:	1141                	addi	sp,sp,-16
    8000079a:	e406                	sd	ra,8(sp)
    8000079c:	e022                	sd	s0,0(sp)
    8000079e:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a0:	100007b7          	lui	a5,0x10000
    800007a4:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a8:	f8000713          	li	a4,-128
    800007ac:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b0:	470d                	li	a4,3
    800007b2:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b6:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007ba:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007be:	469d                	li	a3,7
    800007c0:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c4:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c8:	00008597          	auipc	a1,0x8
    800007cc:	89058593          	addi	a1,a1,-1904 # 80008058 <digits+0x18>
    800007d0:	00010517          	auipc	a0,0x10
    800007d4:	3d850513          	addi	a0,a0,984 # 80010ba8 <uart_tx_lock>
    800007d8:	00000097          	auipc	ra,0x0
    800007dc:	36a080e7          	jalr	874(ra) # 80000b42 <initlock>
}
    800007e0:	60a2                	ld	ra,8(sp)
    800007e2:	6402                	ld	s0,0(sp)
    800007e4:	0141                	addi	sp,sp,16
    800007e6:	8082                	ret

00000000800007e8 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e8:	1101                	addi	sp,sp,-32
    800007ea:	ec06                	sd	ra,24(sp)
    800007ec:	e822                	sd	s0,16(sp)
    800007ee:	e426                	sd	s1,8(sp)
    800007f0:	1000                	addi	s0,sp,32
    800007f2:	84aa                	mv	s1,a0
  push_off();
    800007f4:	00000097          	auipc	ra,0x0
    800007f8:	392080e7          	jalr	914(ra) # 80000b86 <push_off>

  if(panicked){
    800007fc:	00008797          	auipc	a5,0x8
    80000800:	1647a783          	lw	a5,356(a5) # 80008960 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000804:	10000737          	lui	a4,0x10000
  if(panicked){
    80000808:	c391                	beqz	a5,8000080c <uartputc_sync+0x24>
    for(;;)
    8000080a:	a001                	j	8000080a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000810:	0207f793          	andi	a5,a5,32
    80000814:	dfe5                	beqz	a5,8000080c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000816:	0ff4f513          	zext.b	a0,s1
    8000081a:	100007b7          	lui	a5,0x10000
    8000081e:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000822:	00000097          	auipc	ra,0x0
    80000826:	404080e7          	jalr	1028(ra) # 80000c26 <pop_off>
}
    8000082a:	60e2                	ld	ra,24(sp)
    8000082c:	6442                	ld	s0,16(sp)
    8000082e:	64a2                	ld	s1,8(sp)
    80000830:	6105                	addi	sp,sp,32
    80000832:	8082                	ret

0000000080000834 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000834:	00008797          	auipc	a5,0x8
    80000838:	1347b783          	ld	a5,308(a5) # 80008968 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	13473703          	ld	a4,308(a4) # 80008970 <uart_tx_w>
    80000844:	06f70a63          	beq	a4,a5,800008b8 <uartstart+0x84>
{
    80000848:	7139                	addi	sp,sp,-64
    8000084a:	fc06                	sd	ra,56(sp)
    8000084c:	f822                	sd	s0,48(sp)
    8000084e:	f426                	sd	s1,40(sp)
    80000850:	f04a                	sd	s2,32(sp)
    80000852:	ec4e                	sd	s3,24(sp)
    80000854:	e852                	sd	s4,16(sp)
    80000856:	e456                	sd	s5,8(sp)
    80000858:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085a:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085e:	00010a17          	auipc	s4,0x10
    80000862:	34aa0a13          	addi	s4,s4,842 # 80010ba8 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	10248493          	addi	s1,s1,258 # 80008968 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	10298993          	addi	s3,s3,258 # 80008970 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000876:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087a:	02077713          	andi	a4,a4,32
    8000087e:	c705                	beqz	a4,800008a6 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000880:	01f7f713          	andi	a4,a5,31
    80000884:	9752                	add	a4,a4,s4
    80000886:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088a:	0785                	addi	a5,a5,1
    8000088c:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088e:	8526                	mv	a0,s1
    80000890:	00002097          	auipc	ra,0x2
    80000894:	822080e7          	jalr	-2014(ra) # 800020b2 <wakeup>
    
    WriteReg(THR, c);
    80000898:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089c:	609c                	ld	a5,0(s1)
    8000089e:	0009b703          	ld	a4,0(s3)
    800008a2:	fcf71ae3          	bne	a4,a5,80000876 <uartstart+0x42>
  }
}
    800008a6:	70e2                	ld	ra,56(sp)
    800008a8:	7442                	ld	s0,48(sp)
    800008aa:	74a2                	ld	s1,40(sp)
    800008ac:	7902                	ld	s2,32(sp)
    800008ae:	69e2                	ld	s3,24(sp)
    800008b0:	6a42                	ld	s4,16(sp)
    800008b2:	6aa2                	ld	s5,8(sp)
    800008b4:	6121                	addi	sp,sp,64
    800008b6:	8082                	ret
    800008b8:	8082                	ret

00000000800008ba <uartputc>:
{
    800008ba:	7179                	addi	sp,sp,-48
    800008bc:	f406                	sd	ra,40(sp)
    800008be:	f022                	sd	s0,32(sp)
    800008c0:	ec26                	sd	s1,24(sp)
    800008c2:	e84a                	sd	s2,16(sp)
    800008c4:	e44e                	sd	s3,8(sp)
    800008c6:	e052                	sd	s4,0(sp)
    800008c8:	1800                	addi	s0,sp,48
    800008ca:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008cc:	00010517          	auipc	a0,0x10
    800008d0:	2dc50513          	addi	a0,a0,732 # 80010ba8 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	2fe080e7          	jalr	766(ra) # 80000bd2 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	0847a783          	lw	a5,132(a5) # 80008960 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	08a73703          	ld	a4,138(a4) # 80008970 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	07a7b783          	ld	a5,122(a5) # 80008968 <uart_tx_r>
    800008f6:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	2ae98993          	addi	s3,s3,686 # 80010ba8 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	06648493          	addi	s1,s1,102 # 80008968 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	06690913          	addi	s2,s2,102 # 80008970 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00001097          	auipc	ra,0x1
    8000091e:	734080e7          	jalr	1844(ra) # 8000204e <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	addi	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	27848493          	addi	s1,s1,632 # 80010ba8 <uart_tx_lock>
    80000938:	01f77793          	andi	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	addi	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	02e7b623          	sd	a4,44(a5) # 80008970 <uart_tx_w>
  uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee8080e7          	jalr	-280(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	330080e7          	jalr	816(ra) # 80000c86 <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	addi	sp,sp,48
    8000096c:	8082                	ret
    for(;;)
    8000096e:	a001                	j	8000096e <uartputc+0xb4>

0000000080000970 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000970:	1141                	addi	sp,sp,-16
    80000972:	e422                	sd	s0,8(sp)
    80000974:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000976:	100007b7          	lui	a5,0x10000
    8000097a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097e:	8b85                	andi	a5,a5,1
    80000980:	cb81                	beqz	a5,80000990 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000982:	100007b7          	lui	a5,0x10000
    80000986:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098a:	6422                	ld	s0,8(sp)
    8000098c:	0141                	addi	sp,sp,16
    8000098e:	8082                	ret
    return -1;
    80000990:	557d                	li	a0,-1
    80000992:	bfe5                	j	8000098a <uartgetc+0x1a>

0000000080000994 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000994:	1101                	addi	sp,sp,-32
    80000996:	ec06                	sd	ra,24(sp)
    80000998:	e822                	sd	s0,16(sp)
    8000099a:	e426                	sd	s1,8(sp)
    8000099c:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099e:	54fd                	li	s1,-1
    800009a0:	a029                	j	800009aa <uartintr+0x16>
      break;
    consoleintr(c);
    800009a2:	00000097          	auipc	ra,0x0
    800009a6:	918080e7          	jalr	-1768(ra) # 800002ba <consoleintr>
    int c = uartgetc();
    800009aa:	00000097          	auipc	ra,0x0
    800009ae:	fc6080e7          	jalr	-58(ra) # 80000970 <uartgetc>
    if(c == -1)
    800009b2:	fe9518e3          	bne	a0,s1,800009a2 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b6:	00010497          	auipc	s1,0x10
    800009ba:	1f248493          	addi	s1,s1,498 # 80010ba8 <uart_tx_lock>
    800009be:	8526                	mv	a0,s1
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	212080e7          	jalr	530(ra) # 80000bd2 <acquire>
  uartstart();
    800009c8:	00000097          	auipc	ra,0x0
    800009cc:	e6c080e7          	jalr	-404(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	2b4080e7          	jalr	692(ra) # 80000c86 <release>
}
    800009da:	60e2                	ld	ra,24(sp)
    800009dc:	6442                	ld	s0,16(sp)
    800009de:	64a2                	ld	s1,8(sp)
    800009e0:	6105                	addi	sp,sp,32
    800009e2:	8082                	ret

00000000800009e4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e4:	1101                	addi	sp,sp,-32
    800009e6:	ec06                	sd	ra,24(sp)
    800009e8:	e822                	sd	s0,16(sp)
    800009ea:	e426                	sd	s1,8(sp)
    800009ec:	e04a                	sd	s2,0(sp)
    800009ee:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f0:	03451793          	slli	a5,a0,0x34
    800009f4:	ebb9                	bnez	a5,80000a4a <kfree+0x66>
    800009f6:	84aa                	mv	s1,a0
    800009f8:	00021797          	auipc	a5,0x21
    800009fc:	41878793          	addi	a5,a5,1048 # 80021e10 <end>
    80000a00:	04f56563          	bltu	a0,a5,80000a4a <kfree+0x66>
    80000a04:	47c5                	li	a5,17
    80000a06:	07ee                	slli	a5,a5,0x1b
    80000a08:	04f57163          	bgeu	a0,a5,80000a4a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0c:	6605                	lui	a2,0x1
    80000a0e:	4585                	li	a1,1
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	2be080e7          	jalr	702(ra) # 80000cce <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a18:	00010917          	auipc	s2,0x10
    80000a1c:	1c890913          	addi	s2,s2,456 # 80010be0 <kmem>
    80000a20:	854a                	mv	a0,s2
    80000a22:	00000097          	auipc	ra,0x0
    80000a26:	1b0080e7          	jalr	432(ra) # 80000bd2 <acquire>
  r->next = kmem.freelist;
    80000a2a:	01893783          	ld	a5,24(s2)
    80000a2e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a30:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	250080e7          	jalr	592(ra) # 80000c86 <release>
}
    80000a3e:	60e2                	ld	ra,24(sp)
    80000a40:	6442                	ld	s0,16(sp)
    80000a42:	64a2                	ld	s1,8(sp)
    80000a44:	6902                	ld	s2,0(sp)
    80000a46:	6105                	addi	sp,sp,32
    80000a48:	8082                	ret
    panic("kfree");
    80000a4a:	00007517          	auipc	a0,0x7
    80000a4e:	61650513          	addi	a0,a0,1558 # 80008060 <digits+0x20>
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	aea080e7          	jalr	-1302(ra) # 8000053c <panic>

0000000080000a5a <freerange>:
{
    80000a5a:	7179                	addi	sp,sp,-48
    80000a5c:	f406                	sd	ra,40(sp)
    80000a5e:	f022                	sd	s0,32(sp)
    80000a60:	ec26                	sd	s1,24(sp)
    80000a62:	e84a                	sd	s2,16(sp)
    80000a64:	e44e                	sd	s3,8(sp)
    80000a66:	e052                	sd	s4,0(sp)
    80000a68:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6a:	6785                	lui	a5,0x1
    80000a6c:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a70:	00e504b3          	add	s1,a0,a4
    80000a74:	777d                	lui	a4,0xfffff
    80000a76:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a78:	94be                	add	s1,s1,a5
    80000a7a:	0095ee63          	bltu	a1,s1,80000a96 <freerange+0x3c>
    80000a7e:	892e                	mv	s2,a1
    kfree(p);
    80000a80:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a82:	6985                	lui	s3,0x1
    kfree(p);
    80000a84:	01448533          	add	a0,s1,s4
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	f5c080e7          	jalr	-164(ra) # 800009e4 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94ce                	add	s1,s1,s3
    80000a92:	fe9979e3          	bgeu	s2,s1,80000a84 <freerange+0x2a>
}
    80000a96:	70a2                	ld	ra,40(sp)
    80000a98:	7402                	ld	s0,32(sp)
    80000a9a:	64e2                	ld	s1,24(sp)
    80000a9c:	6942                	ld	s2,16(sp)
    80000a9e:	69a2                	ld	s3,8(sp)
    80000aa0:	6a02                	ld	s4,0(sp)
    80000aa2:	6145                	addi	sp,sp,48
    80000aa4:	8082                	ret

0000000080000aa6 <kinit>:
{
    80000aa6:	1141                	addi	sp,sp,-16
    80000aa8:	e406                	sd	ra,8(sp)
    80000aaa:	e022                	sd	s0,0(sp)
    80000aac:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aae:	00007597          	auipc	a1,0x7
    80000ab2:	5ba58593          	addi	a1,a1,1466 # 80008068 <digits+0x28>
    80000ab6:	00010517          	auipc	a0,0x10
    80000aba:	12a50513          	addi	a0,a0,298 # 80010be0 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	slli	a1,a1,0x1b
    80000aca:	00021517          	auipc	a0,0x21
    80000ace:	34650513          	addi	a0,a0,838 # 80021e10 <end>
    80000ad2:	00000097          	auipc	ra,0x0
    80000ad6:	f88080e7          	jalr	-120(ra) # 80000a5a <freerange>
}
    80000ada:	60a2                	ld	ra,8(sp)
    80000adc:	6402                	ld	s0,0(sp)
    80000ade:	0141                	addi	sp,sp,16
    80000ae0:	8082                	ret

0000000080000ae2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae2:	1101                	addi	sp,sp,-32
    80000ae4:	ec06                	sd	ra,24(sp)
    80000ae6:	e822                	sd	s0,16(sp)
    80000ae8:	e426                	sd	s1,8(sp)
    80000aea:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aec:	00010497          	auipc	s1,0x10
    80000af0:	0f448493          	addi	s1,s1,244 # 80010be0 <kmem>
    80000af4:	8526                	mv	a0,s1
    80000af6:	00000097          	auipc	ra,0x0
    80000afa:	0dc080e7          	jalr	220(ra) # 80000bd2 <acquire>
  r = kmem.freelist;
    80000afe:	6c84                	ld	s1,24(s1)
  if(r)
    80000b00:	c885                	beqz	s1,80000b30 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b02:	609c                	ld	a5,0(s1)
    80000b04:	00010517          	auipc	a0,0x10
    80000b08:	0dc50513          	addi	a0,a0,220 # 80010be0 <kmem>
    80000b0c:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	178080e7          	jalr	376(ra) # 80000c86 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b16:	6605                	lui	a2,0x1
    80000b18:	4595                	li	a1,5
    80000b1a:	8526                	mv	a0,s1
    80000b1c:	00000097          	auipc	ra,0x0
    80000b20:	1b2080e7          	jalr	434(ra) # 80000cce <memset>
  return (void*)r;
}
    80000b24:	8526                	mv	a0,s1
    80000b26:	60e2                	ld	ra,24(sp)
    80000b28:	6442                	ld	s0,16(sp)
    80000b2a:	64a2                	ld	s1,8(sp)
    80000b2c:	6105                	addi	sp,sp,32
    80000b2e:	8082                	ret
  release(&kmem.lock);
    80000b30:	00010517          	auipc	a0,0x10
    80000b34:	0b050513          	addi	a0,a0,176 # 80010be0 <kmem>
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	14e080e7          	jalr	334(ra) # 80000c86 <release>
  if(r)
    80000b40:	b7d5                	j	80000b24 <kalloc+0x42>

0000000080000b42 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b42:	1141                	addi	sp,sp,-16
    80000b44:	e422                	sd	s0,8(sp)
    80000b46:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b48:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4e:	00053823          	sd	zero,16(a0)
}
    80000b52:	6422                	ld	s0,8(sp)
    80000b54:	0141                	addi	sp,sp,16
    80000b56:	8082                	ret

0000000080000b58 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b58:	411c                	lw	a5,0(a0)
    80000b5a:	e399                	bnez	a5,80000b60 <holding+0x8>
    80000b5c:	4501                	li	a0,0
  return r;
}
    80000b5e:	8082                	ret
{
    80000b60:	1101                	addi	sp,sp,-32
    80000b62:	ec06                	sd	ra,24(sp)
    80000b64:	e822                	sd	s0,16(sp)
    80000b66:	e426                	sd	s1,8(sp)
    80000b68:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	6904                	ld	s1,16(a0)
    80000b6c:	00001097          	auipc	ra,0x1
    80000b70:	e1e080e7          	jalr	-482(ra) # 8000198a <mycpu>
    80000b74:	40a48533          	sub	a0,s1,a0
    80000b78:	00153513          	seqz	a0,a0
}
    80000b7c:	60e2                	ld	ra,24(sp)
    80000b7e:	6442                	ld	s0,16(sp)
    80000b80:	64a2                	ld	s1,8(sp)
    80000b82:	6105                	addi	sp,sp,32
    80000b84:	8082                	ret

0000000080000b86 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b86:	1101                	addi	sp,sp,-32
    80000b88:	ec06                	sd	ra,24(sp)
    80000b8a:	e822                	sd	s0,16(sp)
    80000b8c:	e426                	sd	s1,8(sp)
    80000b8e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b90:	100024f3          	csrr	s1,sstatus
    80000b94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b98:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9e:	00001097          	auipc	ra,0x1
    80000ba2:	dec080e7          	jalr	-532(ra) # 8000198a <mycpu>
    80000ba6:	5d3c                	lw	a5,120(a0)
    80000ba8:	cf89                	beqz	a5,80000bc2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	de0080e7          	jalr	-544(ra) # 8000198a <mycpu>
    80000bb2:	5d3c                	lw	a5,120(a0)
    80000bb4:	2785                	addiw	a5,a5,1
    80000bb6:	dd3c                	sw	a5,120(a0)
}
    80000bb8:	60e2                	ld	ra,24(sp)
    80000bba:	6442                	ld	s0,16(sp)
    80000bbc:	64a2                	ld	s1,8(sp)
    80000bbe:	6105                	addi	sp,sp,32
    80000bc0:	8082                	ret
    mycpu()->intena = old;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	dc8080e7          	jalr	-568(ra) # 8000198a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bca:	8085                	srli	s1,s1,0x1
    80000bcc:	8885                	andi	s1,s1,1
    80000bce:	dd64                	sw	s1,124(a0)
    80000bd0:	bfe9                	j	80000baa <push_off+0x24>

0000000080000bd2 <acquire>:
{
    80000bd2:	1101                	addi	sp,sp,-32
    80000bd4:	ec06                	sd	ra,24(sp)
    80000bd6:	e822                	sd	s0,16(sp)
    80000bd8:	e426                	sd	s1,8(sp)
    80000bda:	1000                	addi	s0,sp,32
    80000bdc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bde:	00000097          	auipc	ra,0x0
    80000be2:	fa8080e7          	jalr	-88(ra) # 80000b86 <push_off>
  if(holding(lk))
    80000be6:	8526                	mv	a0,s1
    80000be8:	00000097          	auipc	ra,0x0
    80000bec:	f70080e7          	jalr	-144(ra) # 80000b58 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf0:	4705                	li	a4,1
  if(holding(lk))
    80000bf2:	e115                	bnez	a0,80000c16 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	87ba                	mv	a5,a4
    80000bf6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfa:	2781                	sext.w	a5,a5
    80000bfc:	ffe5                	bnez	a5,80000bf4 <acquire+0x22>
  __sync_synchronize();
    80000bfe:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c02:	00001097          	auipc	ra,0x1
    80000c06:	d88080e7          	jalr	-632(ra) # 8000198a <mycpu>
    80000c0a:	e888                	sd	a0,16(s1)
}
    80000c0c:	60e2                	ld	ra,24(sp)
    80000c0e:	6442                	ld	s0,16(sp)
    80000c10:	64a2                	ld	s1,8(sp)
    80000c12:	6105                	addi	sp,sp,32
    80000c14:	8082                	ret
    panic("acquire");
    80000c16:	00007517          	auipc	a0,0x7
    80000c1a:	45a50513          	addi	a0,a0,1114 # 80008070 <digits+0x30>
    80000c1e:	00000097          	auipc	ra,0x0
    80000c22:	91e080e7          	jalr	-1762(ra) # 8000053c <panic>

0000000080000c26 <pop_off>:

void
pop_off(void)
{
    80000c26:	1141                	addi	sp,sp,-16
    80000c28:	e406                	sd	ra,8(sp)
    80000c2a:	e022                	sd	s0,0(sp)
    80000c2c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2e:	00001097          	auipc	ra,0x1
    80000c32:	d5c080e7          	jalr	-676(ra) # 8000198a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c36:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3c:	e78d                	bnez	a5,80000c66 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3e:	5d3c                	lw	a5,120(a0)
    80000c40:	02f05b63          	blez	a5,80000c76 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c44:	37fd                	addiw	a5,a5,-1
    80000c46:	0007871b          	sext.w	a4,a5
    80000c4a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4c:	eb09                	bnez	a4,80000c5e <pop_off+0x38>
    80000c4e:	5d7c                	lw	a5,124(a0)
    80000c50:	c799                	beqz	a5,80000c5e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c52:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c56:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5e:	60a2                	ld	ra,8(sp)
    80000c60:	6402                	ld	s0,0(sp)
    80000c62:	0141                	addi	sp,sp,16
    80000c64:	8082                	ret
    panic("pop_off - interruptible");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	41250513          	addi	a0,a0,1042 # 80008078 <digits+0x38>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8ce080e7          	jalr	-1842(ra) # 8000053c <panic>
    panic("pop_off");
    80000c76:	00007517          	auipc	a0,0x7
    80000c7a:	41a50513          	addi	a0,a0,1050 # 80008090 <digits+0x50>
    80000c7e:	00000097          	auipc	ra,0x0
    80000c82:	8be080e7          	jalr	-1858(ra) # 8000053c <panic>

0000000080000c86 <release>:
{
    80000c86:	1101                	addi	sp,sp,-32
    80000c88:	ec06                	sd	ra,24(sp)
    80000c8a:	e822                	sd	s0,16(sp)
    80000c8c:	e426                	sd	s1,8(sp)
    80000c8e:	1000                	addi	s0,sp,32
    80000c90:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c92:	00000097          	auipc	ra,0x0
    80000c96:	ec6080e7          	jalr	-314(ra) # 80000b58 <holding>
    80000c9a:	c115                	beqz	a0,80000cbe <release+0x38>
  lk->cpu = 0;
    80000c9c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca0:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca4:	0f50000f          	fence	iorw,ow
    80000ca8:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	f7a080e7          	jalr	-134(ra) # 80000c26 <pop_off>
}
    80000cb4:	60e2                	ld	ra,24(sp)
    80000cb6:	6442                	ld	s0,16(sp)
    80000cb8:	64a2                	ld	s1,8(sp)
    80000cba:	6105                	addi	sp,sp,32
    80000cbc:	8082                	ret
    panic("release");
    80000cbe:	00007517          	auipc	a0,0x7
    80000cc2:	3da50513          	addi	a0,a0,986 # 80008098 <digits+0x58>
    80000cc6:	00000097          	auipc	ra,0x0
    80000cca:	876080e7          	jalr	-1930(ra) # 8000053c <panic>

0000000080000cce <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cce:	1141                	addi	sp,sp,-16
    80000cd0:	e422                	sd	s0,8(sp)
    80000cd2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd4:	ca19                	beqz	a2,80000cea <memset+0x1c>
    80000cd6:	87aa                	mv	a5,a0
    80000cd8:	1602                	slli	a2,a2,0x20
    80000cda:	9201                	srli	a2,a2,0x20
    80000cdc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce4:	0785                	addi	a5,a5,1
    80000ce6:	fee79de3          	bne	a5,a4,80000ce0 <memset+0x12>
  }
  return dst;
}
    80000cea:	6422                	ld	s0,8(sp)
    80000cec:	0141                	addi	sp,sp,16
    80000cee:	8082                	ret

0000000080000cf0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf0:	1141                	addi	sp,sp,-16
    80000cf2:	e422                	sd	s0,8(sp)
    80000cf4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf6:	ca05                	beqz	a2,80000d26 <memcmp+0x36>
    80000cf8:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cfc:	1682                	slli	a3,a3,0x20
    80000cfe:	9281                	srli	a3,a3,0x20
    80000d00:	0685                	addi	a3,a3,1
    80000d02:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d04:	00054783          	lbu	a5,0(a0)
    80000d08:	0005c703          	lbu	a4,0(a1)
    80000d0c:	00e79863          	bne	a5,a4,80000d1c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d10:	0505                	addi	a0,a0,1
    80000d12:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d14:	fed518e3          	bne	a0,a3,80000d04 <memcmp+0x14>
  }

  return 0;
    80000d18:	4501                	li	a0,0
    80000d1a:	a019                	j	80000d20 <memcmp+0x30>
      return *s1 - *s2;
    80000d1c:	40e7853b          	subw	a0,a5,a4
}
    80000d20:	6422                	ld	s0,8(sp)
    80000d22:	0141                	addi	sp,sp,16
    80000d24:	8082                	ret
  return 0;
    80000d26:	4501                	li	a0,0
    80000d28:	bfe5                	j	80000d20 <memcmp+0x30>

0000000080000d2a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2a:	1141                	addi	sp,sp,-16
    80000d2c:	e422                	sd	s0,8(sp)
    80000d2e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d30:	c205                	beqz	a2,80000d50 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d32:	02a5e263          	bltu	a1,a0,80000d56 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d36:	1602                	slli	a2,a2,0x20
    80000d38:	9201                	srli	a2,a2,0x20
    80000d3a:	00c587b3          	add	a5,a1,a2
{
    80000d3e:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d40:	0585                	addi	a1,a1,1
    80000d42:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd1f1>
    80000d44:	fff5c683          	lbu	a3,-1(a1)
    80000d48:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4c:	fef59ae3          	bne	a1,a5,80000d40 <memmove+0x16>

  return dst;
}
    80000d50:	6422                	ld	s0,8(sp)
    80000d52:	0141                	addi	sp,sp,16
    80000d54:	8082                	ret
  if(s < d && s + n > d){
    80000d56:	02061693          	slli	a3,a2,0x20
    80000d5a:	9281                	srli	a3,a3,0x20
    80000d5c:	00d58733          	add	a4,a1,a3
    80000d60:	fce57be3          	bgeu	a0,a4,80000d36 <memmove+0xc>
    d += n;
    80000d64:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d66:	fff6079b          	addiw	a5,a2,-1
    80000d6a:	1782                	slli	a5,a5,0x20
    80000d6c:	9381                	srli	a5,a5,0x20
    80000d6e:	fff7c793          	not	a5,a5
    80000d72:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d74:	177d                	addi	a4,a4,-1
    80000d76:	16fd                	addi	a3,a3,-1
    80000d78:	00074603          	lbu	a2,0(a4)
    80000d7c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d80:	fee79ae3          	bne	a5,a4,80000d74 <memmove+0x4a>
    80000d84:	b7f1                	j	80000d50 <memmove+0x26>

0000000080000d86 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d86:	1141                	addi	sp,sp,-16
    80000d88:	e406                	sd	ra,8(sp)
    80000d8a:	e022                	sd	s0,0(sp)
    80000d8c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d8e:	00000097          	auipc	ra,0x0
    80000d92:	f9c080e7          	jalr	-100(ra) # 80000d2a <memmove>
}
    80000d96:	60a2                	ld	ra,8(sp)
    80000d98:	6402                	ld	s0,0(sp)
    80000d9a:	0141                	addi	sp,sp,16
    80000d9c:	8082                	ret

0000000080000d9e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9e:	1141                	addi	sp,sp,-16
    80000da0:	e422                	sd	s0,8(sp)
    80000da2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da4:	ce11                	beqz	a2,80000dc0 <strncmp+0x22>
    80000da6:	00054783          	lbu	a5,0(a0)
    80000daa:	cf89                	beqz	a5,80000dc4 <strncmp+0x26>
    80000dac:	0005c703          	lbu	a4,0(a1)
    80000db0:	00f71a63          	bne	a4,a5,80000dc4 <strncmp+0x26>
    n--, p++, q++;
    80000db4:	367d                	addiw	a2,a2,-1
    80000db6:	0505                	addi	a0,a0,1
    80000db8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dba:	f675                	bnez	a2,80000da6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dbc:	4501                	li	a0,0
    80000dbe:	a809                	j	80000dd0 <strncmp+0x32>
    80000dc0:	4501                	li	a0,0
    80000dc2:	a039                	j	80000dd0 <strncmp+0x32>
  if(n == 0)
    80000dc4:	ca09                	beqz	a2,80000dd6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc6:	00054503          	lbu	a0,0(a0)
    80000dca:	0005c783          	lbu	a5,0(a1)
    80000dce:	9d1d                	subw	a0,a0,a5
}
    80000dd0:	6422                	ld	s0,8(sp)
    80000dd2:	0141                	addi	sp,sp,16
    80000dd4:	8082                	ret
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	bfe5                	j	80000dd0 <strncmp+0x32>

0000000080000dda <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dda:	1141                	addi	sp,sp,-16
    80000ddc:	e422                	sd	s0,8(sp)
    80000dde:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de0:	87aa                	mv	a5,a0
    80000de2:	86b2                	mv	a3,a2
    80000de4:	367d                	addiw	a2,a2,-1
    80000de6:	00d05963          	blez	a3,80000df8 <strncpy+0x1e>
    80000dea:	0785                	addi	a5,a5,1
    80000dec:	0005c703          	lbu	a4,0(a1)
    80000df0:	fee78fa3          	sb	a4,-1(a5)
    80000df4:	0585                	addi	a1,a1,1
    80000df6:	f775                	bnez	a4,80000de2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df8:	873e                	mv	a4,a5
    80000dfa:	9fb5                	addw	a5,a5,a3
    80000dfc:	37fd                	addiw	a5,a5,-1
    80000dfe:	00c05963          	blez	a2,80000e10 <strncpy+0x36>
    *s++ = 0;
    80000e02:	0705                	addi	a4,a4,1
    80000e04:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e08:	40e786bb          	subw	a3,a5,a4
    80000e0c:	fed04be3          	bgtz	a3,80000e02 <strncpy+0x28>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addiw	a3,a2,-1
    80000e24:	1682                	slli	a3,a3,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	addi	a1,a1,1
    80000e32:	0785                	addi	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	addi	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	addi	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	86be                	mv	a3,a5
    80000e5a:	0785                	addi	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	ff65                	bnez	a4,80000e58 <strlen+0x10>
    80000e62:	40a6853b          	subw	a0,a3,a0
    80000e66:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	b00080e7          	jalr	-1280(ra) # 8000197a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	af670713          	addi	a4,a4,-1290 # 80008978 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	ae4080e7          	jalr	-1308(ra) # 8000197a <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	addi	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6de080e7          	jalr	1758(ra) # 80000586 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	7f8080e7          	jalr	2040(ra) # 800026b0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	e10080e7          	jalr	-496(ra) # 80005cd0 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	fd4080e7          	jalr	-44(ra) # 80001e9c <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57c080e7          	jalr	1404(ra) # 8000044c <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88e080e7          	jalr	-1906(ra) # 80000766 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	addi	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69e080e7          	jalr	1694(ra) # 80000586 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	addi	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68e080e7          	jalr	1678(ra) # 80000586 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	addi	a0,a0,456 # 800080c8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67e080e7          	jalr	1662(ra) # 80000586 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b96080e7          	jalr	-1130(ra) # 80000aa6 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	326080e7          	jalr	806(ra) # 8000123e <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	99e080e7          	jalr	-1634(ra) # 800018c6 <procinit>
    trapinit();      // trap vectors
    80000f30:	00001097          	auipc	ra,0x1
    80000f34:	758080e7          	jalr	1880(ra) # 80002688 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00001097          	auipc	ra,0x1
    80000f3c:	778080e7          	jalr	1912(ra) # 800026b0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	d7a080e7          	jalr	-646(ra) # 80005cba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	d88080e7          	jalr	-632(ra) # 80005cd0 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	f7a080e7          	jalr	-134(ra) # 80002eca <binit>
    iinit();         // inode table
    80000f58:	00002097          	auipc	ra,0x2
    80000f5c:	618080e7          	jalr	1560(ra) # 80003570 <iinit>
    fileinit();      // file table
    80000f60:	00003097          	auipc	ra,0x3
    80000f64:	58e080e7          	jalr	1422(ra) # 800044ee <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	e70080e7          	jalr	-400(ra) # 80005dd8 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	d0e080e7          	jalr	-754(ra) # 80001c7e <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	9ef72d23          	sw	a5,-1542(a4) # 80008978 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f8e:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f92:	00008797          	auipc	a5,0x8
    80000f96:	9ee7b783          	ld	a5,-1554(a5) # 80008980 <kernel_pagetable>
    80000f9a:	83b1                	srli	a5,a5,0xc
    80000f9c:	577d                	li	a4,-1
    80000f9e:	177e                	slli	a4,a4,0x3f
    80000fa0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa2:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fa6:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000faa:	6422                	ld	s0,8(sp)
    80000fac:	0141                	addi	sp,sp,16
    80000fae:	8082                	ret

0000000080000fb0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb0:	7139                	addi	sp,sp,-64
    80000fb2:	fc06                	sd	ra,56(sp)
    80000fb4:	f822                	sd	s0,48(sp)
    80000fb6:	f426                	sd	s1,40(sp)
    80000fb8:	f04a                	sd	s2,32(sp)
    80000fba:	ec4e                	sd	s3,24(sp)
    80000fbc:	e852                	sd	s4,16(sp)
    80000fbe:	e456                	sd	s5,8(sp)
    80000fc0:	e05a                	sd	s6,0(sp)
    80000fc2:	0080                	addi	s0,sp,64
    80000fc4:	84aa                	mv	s1,a0
    80000fc6:	89ae                	mv	s3,a1
    80000fc8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fca:	57fd                	li	a5,-1
    80000fcc:	83e9                	srli	a5,a5,0x1a
    80000fce:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd2:	04b7f263          	bgeu	a5,a1,80001016 <walk+0x66>
    panic("walk");
    80000fd6:	00007517          	auipc	a0,0x7
    80000fda:	0fa50513          	addi	a0,a0,250 # 800080d0 <digits+0x90>
    80000fde:	fffff097          	auipc	ra,0xfffff
    80000fe2:	55e080e7          	jalr	1374(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe6:	060a8663          	beqz	s5,80001052 <walk+0xa2>
    80000fea:	00000097          	auipc	ra,0x0
    80000fee:	af8080e7          	jalr	-1288(ra) # 80000ae2 <kalloc>
    80000ff2:	84aa                	mv	s1,a0
    80000ff4:	c529                	beqz	a0,8000103e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff6:	6605                	lui	a2,0x1
    80000ff8:	4581                	li	a1,0
    80000ffa:	00000097          	auipc	ra,0x0
    80000ffe:	cd4080e7          	jalr	-812(ra) # 80000cce <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001002:	00c4d793          	srli	a5,s1,0xc
    80001006:	07aa                	slli	a5,a5,0xa
    80001008:	0017e793          	ori	a5,a5,1
    8000100c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001010:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd1e7>
    80001012:	036a0063          	beq	s4,s6,80001032 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001016:	0149d933          	srl	s2,s3,s4
    8000101a:	1ff97913          	andi	s2,s2,511
    8000101e:	090e                	slli	s2,s2,0x3
    80001020:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001022:	00093483          	ld	s1,0(s2)
    80001026:	0014f793          	andi	a5,s1,1
    8000102a:	dfd5                	beqz	a5,80000fe6 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000102c:	80a9                	srli	s1,s1,0xa
    8000102e:	04b2                	slli	s1,s1,0xc
    80001030:	b7c5                	j	80001010 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001032:	00c9d513          	srli	a0,s3,0xc
    80001036:	1ff57513          	andi	a0,a0,511
    8000103a:	050e                	slli	a0,a0,0x3
    8000103c:	9526                	add	a0,a0,s1
}
    8000103e:	70e2                	ld	ra,56(sp)
    80001040:	7442                	ld	s0,48(sp)
    80001042:	74a2                	ld	s1,40(sp)
    80001044:	7902                	ld	s2,32(sp)
    80001046:	69e2                	ld	s3,24(sp)
    80001048:	6a42                	ld	s4,16(sp)
    8000104a:	6aa2                	ld	s5,8(sp)
    8000104c:	6b02                	ld	s6,0(sp)
    8000104e:	6121                	addi	sp,sp,64
    80001050:	8082                	ret
        return 0;
    80001052:	4501                	li	a0,0
    80001054:	b7ed                	j	8000103e <walk+0x8e>

0000000080001056 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001056:	57fd                	li	a5,-1
    80001058:	83e9                	srli	a5,a5,0x1a
    8000105a:	00b7f463          	bgeu	a5,a1,80001062 <walkaddr+0xc>
    return 0;
    8000105e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001060:	8082                	ret
{
    80001062:	1141                	addi	sp,sp,-16
    80001064:	e406                	sd	ra,8(sp)
    80001066:	e022                	sd	s0,0(sp)
    80001068:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000106a:	4601                	li	a2,0
    8000106c:	00000097          	auipc	ra,0x0
    80001070:	f44080e7          	jalr	-188(ra) # 80000fb0 <walk>
  if(pte == 0)
    80001074:	c105                	beqz	a0,80001094 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001076:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001078:	0117f693          	andi	a3,a5,17
    8000107c:	4745                	li	a4,17
    return 0;
    8000107e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001080:	00e68663          	beq	a3,a4,8000108c <walkaddr+0x36>
}
    80001084:	60a2                	ld	ra,8(sp)
    80001086:	6402                	ld	s0,0(sp)
    80001088:	0141                	addi	sp,sp,16
    8000108a:	8082                	ret
  pa = PTE2PA(*pte);
    8000108c:	83a9                	srli	a5,a5,0xa
    8000108e:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001092:	bfcd                	j	80001084 <walkaddr+0x2e>
    return 0;
    80001094:	4501                	li	a0,0
    80001096:	b7fd                	j	80001084 <walkaddr+0x2e>

0000000080001098 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001098:	715d                	addi	sp,sp,-80
    8000109a:	e486                	sd	ra,72(sp)
    8000109c:	e0a2                	sd	s0,64(sp)
    8000109e:	fc26                	sd	s1,56(sp)
    800010a0:	f84a                	sd	s2,48(sp)
    800010a2:	f44e                	sd	s3,40(sp)
    800010a4:	f052                	sd	s4,32(sp)
    800010a6:	ec56                	sd	s5,24(sp)
    800010a8:	e85a                	sd	s6,16(sp)
    800010aa:	e45e                	sd	s7,8(sp)
    800010ac:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ae:	c639                	beqz	a2,800010fc <mappages+0x64>
    800010b0:	8aaa                	mv	s5,a0
    800010b2:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b4:	777d                	lui	a4,0xfffff
    800010b6:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010ba:	fff58993          	addi	s3,a1,-1
    800010be:	99b2                	add	s3,s3,a2
    800010c0:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c4:	893e                	mv	s2,a5
    800010c6:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ca:	6b85                	lui	s7,0x1
    800010cc:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d0:	4605                	li	a2,1
    800010d2:	85ca                	mv	a1,s2
    800010d4:	8556                	mv	a0,s5
    800010d6:	00000097          	auipc	ra,0x0
    800010da:	eda080e7          	jalr	-294(ra) # 80000fb0 <walk>
    800010de:	cd1d                	beqz	a0,8000111c <mappages+0x84>
    if(*pte & PTE_V)
    800010e0:	611c                	ld	a5,0(a0)
    800010e2:	8b85                	andi	a5,a5,1
    800010e4:	e785                	bnez	a5,8000110c <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e6:	80b1                	srli	s1,s1,0xc
    800010e8:	04aa                	slli	s1,s1,0xa
    800010ea:	0164e4b3          	or	s1,s1,s6
    800010ee:	0014e493          	ori	s1,s1,1
    800010f2:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f4:	05390063          	beq	s2,s3,80001134 <mappages+0x9c>
    a += PGSIZE;
    800010f8:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010fa:	bfc9                	j	800010cc <mappages+0x34>
    panic("mappages: size");
    800010fc:	00007517          	auipc	a0,0x7
    80001100:	fdc50513          	addi	a0,a0,-36 # 800080d8 <digits+0x98>
    80001104:	fffff097          	auipc	ra,0xfffff
    80001108:	438080e7          	jalr	1080(ra) # 8000053c <panic>
      panic("mappages: remap");
    8000110c:	00007517          	auipc	a0,0x7
    80001110:	fdc50513          	addi	a0,a0,-36 # 800080e8 <digits+0xa8>
    80001114:	fffff097          	auipc	ra,0xfffff
    80001118:	428080e7          	jalr	1064(ra) # 8000053c <panic>
      return -1;
    8000111c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111e:	60a6                	ld	ra,72(sp)
    80001120:	6406                	ld	s0,64(sp)
    80001122:	74e2                	ld	s1,56(sp)
    80001124:	7942                	ld	s2,48(sp)
    80001126:	79a2                	ld	s3,40(sp)
    80001128:	7a02                	ld	s4,32(sp)
    8000112a:	6ae2                	ld	s5,24(sp)
    8000112c:	6b42                	ld	s6,16(sp)
    8000112e:	6ba2                	ld	s7,8(sp)
    80001130:	6161                	addi	sp,sp,80
    80001132:	8082                	ret
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	b7e5                	j	8000111e <mappages+0x86>

0000000080001138 <kvmmap>:
{
    80001138:	1141                	addi	sp,sp,-16
    8000113a:	e406                	sd	ra,8(sp)
    8000113c:	e022                	sd	s0,0(sp)
    8000113e:	0800                	addi	s0,sp,16
    80001140:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001142:	86b2                	mv	a3,a2
    80001144:	863e                	mv	a2,a5
    80001146:	00000097          	auipc	ra,0x0
    8000114a:	f52080e7          	jalr	-174(ra) # 80001098 <mappages>
    8000114e:	e509                	bnez	a0,80001158 <kvmmap+0x20>
}
    80001150:	60a2                	ld	ra,8(sp)
    80001152:	6402                	ld	s0,0(sp)
    80001154:	0141                	addi	sp,sp,16
    80001156:	8082                	ret
    panic("kvmmap");
    80001158:	00007517          	auipc	a0,0x7
    8000115c:	fa050513          	addi	a0,a0,-96 # 800080f8 <digits+0xb8>
    80001160:	fffff097          	auipc	ra,0xfffff
    80001164:	3dc080e7          	jalr	988(ra) # 8000053c <panic>

0000000080001168 <kvmmake>:
{
    80001168:	1101                	addi	sp,sp,-32
    8000116a:	ec06                	sd	ra,24(sp)
    8000116c:	e822                	sd	s0,16(sp)
    8000116e:	e426                	sd	s1,8(sp)
    80001170:	e04a                	sd	s2,0(sp)
    80001172:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001174:	00000097          	auipc	ra,0x0
    80001178:	96e080e7          	jalr	-1682(ra) # 80000ae2 <kalloc>
    8000117c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117e:	6605                	lui	a2,0x1
    80001180:	4581                	li	a1,0
    80001182:	00000097          	auipc	ra,0x0
    80001186:	b4c080e7          	jalr	-1204(ra) # 80000cce <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000118a:	4719                	li	a4,6
    8000118c:	6685                	lui	a3,0x1
    8000118e:	10000637          	lui	a2,0x10000
    80001192:	100005b7          	lui	a1,0x10000
    80001196:	8526                	mv	a0,s1
    80001198:	00000097          	auipc	ra,0x0
    8000119c:	fa0080e7          	jalr	-96(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a0:	4719                	li	a4,6
    800011a2:	6685                	lui	a3,0x1
    800011a4:	10001637          	lui	a2,0x10001
    800011a8:	100015b7          	lui	a1,0x10001
    800011ac:	8526                	mv	a0,s1
    800011ae:	00000097          	auipc	ra,0x0
    800011b2:	f8a080e7          	jalr	-118(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b6:	4719                	li	a4,6
    800011b8:	004006b7          	lui	a3,0x400
    800011bc:	0c000637          	lui	a2,0xc000
    800011c0:	0c0005b7          	lui	a1,0xc000
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f72080e7          	jalr	-142(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ce:	00007917          	auipc	s2,0x7
    800011d2:	e3290913          	addi	s2,s2,-462 # 80008000 <etext>
    800011d6:	4729                	li	a4,10
    800011d8:	80007697          	auipc	a3,0x80007
    800011dc:	e2868693          	addi	a3,a3,-472 # 8000 <_entry-0x7fff8000>
    800011e0:	4605                	li	a2,1
    800011e2:	067e                	slli	a2,a2,0x1f
    800011e4:	85b2                	mv	a1,a2
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f50080e7          	jalr	-176(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f0:	4719                	li	a4,6
    800011f2:	46c5                	li	a3,17
    800011f4:	06ee                	slli	a3,a3,0x1b
    800011f6:	412686b3          	sub	a3,a3,s2
    800011fa:	864a                	mv	a2,s2
    800011fc:	85ca                	mv	a1,s2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f38080e7          	jalr	-200(ra) # 80001138 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001208:	4729                	li	a4,10
    8000120a:	6685                	lui	a3,0x1
    8000120c:	00006617          	auipc	a2,0x6
    80001210:	df460613          	addi	a2,a2,-524 # 80007000 <_trampoline>
    80001214:	040005b7          	lui	a1,0x4000
    80001218:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000121a:	05b2                	slli	a1,a1,0xc
    8000121c:	8526                	mv	a0,s1
    8000121e:	00000097          	auipc	ra,0x0
    80001222:	f1a080e7          	jalr	-230(ra) # 80001138 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001226:	8526                	mv	a0,s1
    80001228:	00000097          	auipc	ra,0x0
    8000122c:	608080e7          	jalr	1544(ra) # 80001830 <proc_mapstacks>
}
    80001230:	8526                	mv	a0,s1
    80001232:	60e2                	ld	ra,24(sp)
    80001234:	6442                	ld	s0,16(sp)
    80001236:	64a2                	ld	s1,8(sp)
    80001238:	6902                	ld	s2,0(sp)
    8000123a:	6105                	addi	sp,sp,32
    8000123c:	8082                	ret

000000008000123e <kvminit>:
{
    8000123e:	1141                	addi	sp,sp,-16
    80001240:	e406                	sd	ra,8(sp)
    80001242:	e022                	sd	s0,0(sp)
    80001244:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001246:	00000097          	auipc	ra,0x0
    8000124a:	f22080e7          	jalr	-222(ra) # 80001168 <kvmmake>
    8000124e:	00007797          	auipc	a5,0x7
    80001252:	72a7b923          	sd	a0,1842(a5) # 80008980 <kernel_pagetable>
}
    80001256:	60a2                	ld	ra,8(sp)
    80001258:	6402                	ld	s0,0(sp)
    8000125a:	0141                	addi	sp,sp,16
    8000125c:	8082                	ret

000000008000125e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125e:	715d                	addi	sp,sp,-80
    80001260:	e486                	sd	ra,72(sp)
    80001262:	e0a2                	sd	s0,64(sp)
    80001264:	fc26                	sd	s1,56(sp)
    80001266:	f84a                	sd	s2,48(sp)
    80001268:	f44e                	sd	s3,40(sp)
    8000126a:	f052                	sd	s4,32(sp)
    8000126c:	ec56                	sd	s5,24(sp)
    8000126e:	e85a                	sd	s6,16(sp)
    80001270:	e45e                	sd	s7,8(sp)
    80001272:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001274:	03459793          	slli	a5,a1,0x34
    80001278:	e795                	bnez	a5,800012a4 <uvmunmap+0x46>
    8000127a:	8a2a                	mv	s4,a0
    8000127c:	892e                	mv	s2,a1
    8000127e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001280:	0632                	slli	a2,a2,0xc
    80001282:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001286:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001288:	6b05                	lui	s6,0x1
    8000128a:	0735e263          	bltu	a1,s3,800012ee <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128e:	60a6                	ld	ra,72(sp)
    80001290:	6406                	ld	s0,64(sp)
    80001292:	74e2                	ld	s1,56(sp)
    80001294:	7942                	ld	s2,48(sp)
    80001296:	79a2                	ld	s3,40(sp)
    80001298:	7a02                	ld	s4,32(sp)
    8000129a:	6ae2                	ld	s5,24(sp)
    8000129c:	6b42                	ld	s6,16(sp)
    8000129e:	6ba2                	ld	s7,8(sp)
    800012a0:	6161                	addi	sp,sp,80
    800012a2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a4:	00007517          	auipc	a0,0x7
    800012a8:	e5c50513          	addi	a0,a0,-420 # 80008100 <digits+0xc0>
    800012ac:	fffff097          	auipc	ra,0xfffff
    800012b0:	290080e7          	jalr	656(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    800012b4:	00007517          	auipc	a0,0x7
    800012b8:	e6450513          	addi	a0,a0,-412 # 80008118 <digits+0xd8>
    800012bc:	fffff097          	auipc	ra,0xfffff
    800012c0:	280080e7          	jalr	640(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    800012c4:	00007517          	auipc	a0,0x7
    800012c8:	e6450513          	addi	a0,a0,-412 # 80008128 <digits+0xe8>
    800012cc:	fffff097          	auipc	ra,0xfffff
    800012d0:	270080e7          	jalr	624(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    800012d4:	00007517          	auipc	a0,0x7
    800012d8:	e6c50513          	addi	a0,a0,-404 # 80008140 <digits+0x100>
    800012dc:	fffff097          	auipc	ra,0xfffff
    800012e0:	260080e7          	jalr	608(ra) # 8000053c <panic>
    *pte = 0;
    800012e4:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e8:	995a                	add	s2,s2,s6
    800012ea:	fb3972e3          	bgeu	s2,s3,8000128e <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ee:	4601                	li	a2,0
    800012f0:	85ca                	mv	a1,s2
    800012f2:	8552                	mv	a0,s4
    800012f4:	00000097          	auipc	ra,0x0
    800012f8:	cbc080e7          	jalr	-836(ra) # 80000fb0 <walk>
    800012fc:	84aa                	mv	s1,a0
    800012fe:	d95d                	beqz	a0,800012b4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001300:	6108                	ld	a0,0(a0)
    80001302:	00157793          	andi	a5,a0,1
    80001306:	dfdd                	beqz	a5,800012c4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001308:	3ff57793          	andi	a5,a0,1023
    8000130c:	fd7784e3          	beq	a5,s7,800012d4 <uvmunmap+0x76>
    if(do_free){
    80001310:	fc0a8ae3          	beqz	s5,800012e4 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001314:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001316:	0532                	slli	a0,a0,0xc
    80001318:	fffff097          	auipc	ra,0xfffff
    8000131c:	6cc080e7          	jalr	1740(ra) # 800009e4 <kfree>
    80001320:	b7d1                	j	800012e4 <uvmunmap+0x86>

0000000080001322 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001322:	1101                	addi	sp,sp,-32
    80001324:	ec06                	sd	ra,24(sp)
    80001326:	e822                	sd	s0,16(sp)
    80001328:	e426                	sd	s1,8(sp)
    8000132a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000132c:	fffff097          	auipc	ra,0xfffff
    80001330:	7b6080e7          	jalr	1974(ra) # 80000ae2 <kalloc>
    80001334:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001336:	c519                	beqz	a0,80001344 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001338:	6605                	lui	a2,0x1
    8000133a:	4581                	li	a1,0
    8000133c:	00000097          	auipc	ra,0x0
    80001340:	992080e7          	jalr	-1646(ra) # 80000cce <memset>
  return pagetable;
}
    80001344:	8526                	mv	a0,s1
    80001346:	60e2                	ld	ra,24(sp)
    80001348:	6442                	ld	s0,16(sp)
    8000134a:	64a2                	ld	s1,8(sp)
    8000134c:	6105                	addi	sp,sp,32
    8000134e:	8082                	ret

0000000080001350 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001350:	7179                	addi	sp,sp,-48
    80001352:	f406                	sd	ra,40(sp)
    80001354:	f022                	sd	s0,32(sp)
    80001356:	ec26                	sd	s1,24(sp)
    80001358:	e84a                	sd	s2,16(sp)
    8000135a:	e44e                	sd	s3,8(sp)
    8000135c:	e052                	sd	s4,0(sp)
    8000135e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001360:	6785                	lui	a5,0x1
    80001362:	04f67863          	bgeu	a2,a5,800013b2 <uvmfirst+0x62>
    80001366:	8a2a                	mv	s4,a0
    80001368:	89ae                	mv	s3,a1
    8000136a:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000136c:	fffff097          	auipc	ra,0xfffff
    80001370:	776080e7          	jalr	1910(ra) # 80000ae2 <kalloc>
    80001374:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001376:	6605                	lui	a2,0x1
    80001378:	4581                	li	a1,0
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	954080e7          	jalr	-1708(ra) # 80000cce <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001382:	4779                	li	a4,30
    80001384:	86ca                	mv	a3,s2
    80001386:	6605                	lui	a2,0x1
    80001388:	4581                	li	a1,0
    8000138a:	8552                	mv	a0,s4
    8000138c:	00000097          	auipc	ra,0x0
    80001390:	d0c080e7          	jalr	-756(ra) # 80001098 <mappages>
  memmove(mem, src, sz);
    80001394:	8626                	mv	a2,s1
    80001396:	85ce                	mv	a1,s3
    80001398:	854a                	mv	a0,s2
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	990080e7          	jalr	-1648(ra) # 80000d2a <memmove>
}
    800013a2:	70a2                	ld	ra,40(sp)
    800013a4:	7402                	ld	s0,32(sp)
    800013a6:	64e2                	ld	s1,24(sp)
    800013a8:	6942                	ld	s2,16(sp)
    800013aa:	69a2                	ld	s3,8(sp)
    800013ac:	6a02                	ld	s4,0(sp)
    800013ae:	6145                	addi	sp,sp,48
    800013b0:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b2:	00007517          	auipc	a0,0x7
    800013b6:	da650513          	addi	a0,a0,-602 # 80008158 <digits+0x118>
    800013ba:	fffff097          	auipc	ra,0xfffff
    800013be:	182080e7          	jalr	386(ra) # 8000053c <panic>

00000000800013c2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c2:	1101                	addi	sp,sp,-32
    800013c4:	ec06                	sd	ra,24(sp)
    800013c6:	e822                	sd	s0,16(sp)
    800013c8:	e426                	sd	s1,8(sp)
    800013ca:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013cc:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ce:	00b67d63          	bgeu	a2,a1,800013e8 <uvmdealloc+0x26>
    800013d2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d4:	6785                	lui	a5,0x1
    800013d6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013d8:	00f60733          	add	a4,a2,a5
    800013dc:	76fd                	lui	a3,0xfffff
    800013de:	8f75                	and	a4,a4,a3
    800013e0:	97ae                	add	a5,a5,a1
    800013e2:	8ff5                	and	a5,a5,a3
    800013e4:	00f76863          	bltu	a4,a5,800013f4 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e8:	8526                	mv	a0,s1
    800013ea:	60e2                	ld	ra,24(sp)
    800013ec:	6442                	ld	s0,16(sp)
    800013ee:	64a2                	ld	s1,8(sp)
    800013f0:	6105                	addi	sp,sp,32
    800013f2:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f4:	8f99                	sub	a5,a5,a4
    800013f6:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f8:	4685                	li	a3,1
    800013fa:	0007861b          	sext.w	a2,a5
    800013fe:	85ba                	mv	a1,a4
    80001400:	00000097          	auipc	ra,0x0
    80001404:	e5e080e7          	jalr	-418(ra) # 8000125e <uvmunmap>
    80001408:	b7c5                	j	800013e8 <uvmdealloc+0x26>

000000008000140a <uvmalloc>:
  if(newsz < oldsz)
    8000140a:	0ab66563          	bltu	a2,a1,800014b4 <uvmalloc+0xaa>
{
    8000140e:	7139                	addi	sp,sp,-64
    80001410:	fc06                	sd	ra,56(sp)
    80001412:	f822                	sd	s0,48(sp)
    80001414:	f426                	sd	s1,40(sp)
    80001416:	f04a                	sd	s2,32(sp)
    80001418:	ec4e                	sd	s3,24(sp)
    8000141a:	e852                	sd	s4,16(sp)
    8000141c:	e456                	sd	s5,8(sp)
    8000141e:	e05a                	sd	s6,0(sp)
    80001420:	0080                	addi	s0,sp,64
    80001422:	8aaa                	mv	s5,a0
    80001424:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001426:	6785                	lui	a5,0x1
    80001428:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000142a:	95be                	add	a1,a1,a5
    8000142c:	77fd                	lui	a5,0xfffff
    8000142e:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001432:	08c9f363          	bgeu	s3,a2,800014b8 <uvmalloc+0xae>
    80001436:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001438:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000143c:	fffff097          	auipc	ra,0xfffff
    80001440:	6a6080e7          	jalr	1702(ra) # 80000ae2 <kalloc>
    80001444:	84aa                	mv	s1,a0
    if(mem == 0){
    80001446:	c51d                	beqz	a0,80001474 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001448:	6605                	lui	a2,0x1
    8000144a:	4581                	li	a1,0
    8000144c:	00000097          	auipc	ra,0x0
    80001450:	882080e7          	jalr	-1918(ra) # 80000cce <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001454:	875a                	mv	a4,s6
    80001456:	86a6                	mv	a3,s1
    80001458:	6605                	lui	a2,0x1
    8000145a:	85ca                	mv	a1,s2
    8000145c:	8556                	mv	a0,s5
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	c3a080e7          	jalr	-966(ra) # 80001098 <mappages>
    80001466:	e90d                	bnez	a0,80001498 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001468:	6785                	lui	a5,0x1
    8000146a:	993e                	add	s2,s2,a5
    8000146c:	fd4968e3          	bltu	s2,s4,8000143c <uvmalloc+0x32>
  return newsz;
    80001470:	8552                	mv	a0,s4
    80001472:	a809                	j	80001484 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001474:	864e                	mv	a2,s3
    80001476:	85ca                	mv	a1,s2
    80001478:	8556                	mv	a0,s5
    8000147a:	00000097          	auipc	ra,0x0
    8000147e:	f48080e7          	jalr	-184(ra) # 800013c2 <uvmdealloc>
      return 0;
    80001482:	4501                	li	a0,0
}
    80001484:	70e2                	ld	ra,56(sp)
    80001486:	7442                	ld	s0,48(sp)
    80001488:	74a2                	ld	s1,40(sp)
    8000148a:	7902                	ld	s2,32(sp)
    8000148c:	69e2                	ld	s3,24(sp)
    8000148e:	6a42                	ld	s4,16(sp)
    80001490:	6aa2                	ld	s5,8(sp)
    80001492:	6b02                	ld	s6,0(sp)
    80001494:	6121                	addi	sp,sp,64
    80001496:	8082                	ret
      kfree(mem);
    80001498:	8526                	mv	a0,s1
    8000149a:	fffff097          	auipc	ra,0xfffff
    8000149e:	54a080e7          	jalr	1354(ra) # 800009e4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a2:	864e                	mv	a2,s3
    800014a4:	85ca                	mv	a1,s2
    800014a6:	8556                	mv	a0,s5
    800014a8:	00000097          	auipc	ra,0x0
    800014ac:	f1a080e7          	jalr	-230(ra) # 800013c2 <uvmdealloc>
      return 0;
    800014b0:	4501                	li	a0,0
    800014b2:	bfc9                	j	80001484 <uvmalloc+0x7a>
    return oldsz;
    800014b4:	852e                	mv	a0,a1
}
    800014b6:	8082                	ret
  return newsz;
    800014b8:	8532                	mv	a0,a2
    800014ba:	b7e9                	j	80001484 <uvmalloc+0x7a>

00000000800014bc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014bc:	7179                	addi	sp,sp,-48
    800014be:	f406                	sd	ra,40(sp)
    800014c0:	f022                	sd	s0,32(sp)
    800014c2:	ec26                	sd	s1,24(sp)
    800014c4:	e84a                	sd	s2,16(sp)
    800014c6:	e44e                	sd	s3,8(sp)
    800014c8:	e052                	sd	s4,0(sp)
    800014ca:	1800                	addi	s0,sp,48
    800014cc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014ce:	84aa                	mv	s1,a0
    800014d0:	6905                	lui	s2,0x1
    800014d2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014d4:	4985                	li	s3,1
    800014d6:	a829                	j	800014f0 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014d8:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014da:	00c79513          	slli	a0,a5,0xc
    800014de:	00000097          	auipc	ra,0x0
    800014e2:	fde080e7          	jalr	-34(ra) # 800014bc <freewalk>
      pagetable[i] = 0;
    800014e6:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ea:	04a1                	addi	s1,s1,8
    800014ec:	03248163          	beq	s1,s2,8000150e <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f0:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f2:	00f7f713          	andi	a4,a5,15
    800014f6:	ff3701e3          	beq	a4,s3,800014d8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014fa:	8b85                	andi	a5,a5,1
    800014fc:	d7fd                	beqz	a5,800014ea <freewalk+0x2e>
      panic("freewalk: leaf");
    800014fe:	00007517          	auipc	a0,0x7
    80001502:	c7a50513          	addi	a0,a0,-902 # 80008178 <digits+0x138>
    80001506:	fffff097          	auipc	ra,0xfffff
    8000150a:	036080e7          	jalr	54(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    8000150e:	8552                	mv	a0,s4
    80001510:	fffff097          	auipc	ra,0xfffff
    80001514:	4d4080e7          	jalr	1236(ra) # 800009e4 <kfree>
}
    80001518:	70a2                	ld	ra,40(sp)
    8000151a:	7402                	ld	s0,32(sp)
    8000151c:	64e2                	ld	s1,24(sp)
    8000151e:	6942                	ld	s2,16(sp)
    80001520:	69a2                	ld	s3,8(sp)
    80001522:	6a02                	ld	s4,0(sp)
    80001524:	6145                	addi	sp,sp,48
    80001526:	8082                	ret

0000000080001528 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001528:	1101                	addi	sp,sp,-32
    8000152a:	ec06                	sd	ra,24(sp)
    8000152c:	e822                	sd	s0,16(sp)
    8000152e:	e426                	sd	s1,8(sp)
    80001530:	1000                	addi	s0,sp,32
    80001532:	84aa                	mv	s1,a0
  if(sz > 0)
    80001534:	e999                	bnez	a1,8000154a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001536:	8526                	mv	a0,s1
    80001538:	00000097          	auipc	ra,0x0
    8000153c:	f84080e7          	jalr	-124(ra) # 800014bc <freewalk>
}
    80001540:	60e2                	ld	ra,24(sp)
    80001542:	6442                	ld	s0,16(sp)
    80001544:	64a2                	ld	s1,8(sp)
    80001546:	6105                	addi	sp,sp,32
    80001548:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000154a:	6785                	lui	a5,0x1
    8000154c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000154e:	95be                	add	a1,a1,a5
    80001550:	4685                	li	a3,1
    80001552:	00c5d613          	srli	a2,a1,0xc
    80001556:	4581                	li	a1,0
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	d06080e7          	jalr	-762(ra) # 8000125e <uvmunmap>
    80001560:	bfd9                	j	80001536 <uvmfree+0xe>

0000000080001562 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001562:	c679                	beqz	a2,80001630 <uvmcopy+0xce>
{
    80001564:	715d                	addi	sp,sp,-80
    80001566:	e486                	sd	ra,72(sp)
    80001568:	e0a2                	sd	s0,64(sp)
    8000156a:	fc26                	sd	s1,56(sp)
    8000156c:	f84a                	sd	s2,48(sp)
    8000156e:	f44e                	sd	s3,40(sp)
    80001570:	f052                	sd	s4,32(sp)
    80001572:	ec56                	sd	s5,24(sp)
    80001574:	e85a                	sd	s6,16(sp)
    80001576:	e45e                	sd	s7,8(sp)
    80001578:	0880                	addi	s0,sp,80
    8000157a:	8b2a                	mv	s6,a0
    8000157c:	8aae                	mv	s5,a1
    8000157e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001580:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001582:	4601                	li	a2,0
    80001584:	85ce                	mv	a1,s3
    80001586:	855a                	mv	a0,s6
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	a28080e7          	jalr	-1496(ra) # 80000fb0 <walk>
    80001590:	c531                	beqz	a0,800015dc <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001592:	6118                	ld	a4,0(a0)
    80001594:	00177793          	andi	a5,a4,1
    80001598:	cbb1                	beqz	a5,800015ec <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000159a:	00a75593          	srli	a1,a4,0xa
    8000159e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a2:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a6:	fffff097          	auipc	ra,0xfffff
    800015aa:	53c080e7          	jalr	1340(ra) # 80000ae2 <kalloc>
    800015ae:	892a                	mv	s2,a0
    800015b0:	c939                	beqz	a0,80001606 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b2:	6605                	lui	a2,0x1
    800015b4:	85de                	mv	a1,s7
    800015b6:	fffff097          	auipc	ra,0xfffff
    800015ba:	774080e7          	jalr	1908(ra) # 80000d2a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015be:	8726                	mv	a4,s1
    800015c0:	86ca                	mv	a3,s2
    800015c2:	6605                	lui	a2,0x1
    800015c4:	85ce                	mv	a1,s3
    800015c6:	8556                	mv	a0,s5
    800015c8:	00000097          	auipc	ra,0x0
    800015cc:	ad0080e7          	jalr	-1328(ra) # 80001098 <mappages>
    800015d0:	e515                	bnez	a0,800015fc <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d2:	6785                	lui	a5,0x1
    800015d4:	99be                	add	s3,s3,a5
    800015d6:	fb49e6e3          	bltu	s3,s4,80001582 <uvmcopy+0x20>
    800015da:	a081                	j	8000161a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015dc:	00007517          	auipc	a0,0x7
    800015e0:	bac50513          	addi	a0,a0,-1108 # 80008188 <digits+0x148>
    800015e4:	fffff097          	auipc	ra,0xfffff
    800015e8:	f58080e7          	jalr	-168(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    800015ec:	00007517          	auipc	a0,0x7
    800015f0:	bbc50513          	addi	a0,a0,-1092 # 800081a8 <digits+0x168>
    800015f4:	fffff097          	auipc	ra,0xfffff
    800015f8:	f48080e7          	jalr	-184(ra) # 8000053c <panic>
      kfree(mem);
    800015fc:	854a                	mv	a0,s2
    800015fe:	fffff097          	auipc	ra,0xfffff
    80001602:	3e6080e7          	jalr	998(ra) # 800009e4 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001606:	4685                	li	a3,1
    80001608:	00c9d613          	srli	a2,s3,0xc
    8000160c:	4581                	li	a1,0
    8000160e:	8556                	mv	a0,s5
    80001610:	00000097          	auipc	ra,0x0
    80001614:	c4e080e7          	jalr	-946(ra) # 8000125e <uvmunmap>
  return -1;
    80001618:	557d                	li	a0,-1
}
    8000161a:	60a6                	ld	ra,72(sp)
    8000161c:	6406                	ld	s0,64(sp)
    8000161e:	74e2                	ld	s1,56(sp)
    80001620:	7942                	ld	s2,48(sp)
    80001622:	79a2                	ld	s3,40(sp)
    80001624:	7a02                	ld	s4,32(sp)
    80001626:	6ae2                	ld	s5,24(sp)
    80001628:	6b42                	ld	s6,16(sp)
    8000162a:	6ba2                	ld	s7,8(sp)
    8000162c:	6161                	addi	sp,sp,80
    8000162e:	8082                	ret
  return 0;
    80001630:	4501                	li	a0,0
}
    80001632:	8082                	ret

0000000080001634 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001634:	1141                	addi	sp,sp,-16
    80001636:	e406                	sd	ra,8(sp)
    80001638:	e022                	sd	s0,0(sp)
    8000163a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163c:	4601                	li	a2,0
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	972080e7          	jalr	-1678(ra) # 80000fb0 <walk>
  if(pte == 0)
    80001646:	c901                	beqz	a0,80001656 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001648:	611c                	ld	a5,0(a0)
    8000164a:	9bbd                	andi	a5,a5,-17
    8000164c:	e11c                	sd	a5,0(a0)
}
    8000164e:	60a2                	ld	ra,8(sp)
    80001650:	6402                	ld	s0,0(sp)
    80001652:	0141                	addi	sp,sp,16
    80001654:	8082                	ret
    panic("uvmclear");
    80001656:	00007517          	auipc	a0,0x7
    8000165a:	b7250513          	addi	a0,a0,-1166 # 800081c8 <digits+0x188>
    8000165e:	fffff097          	auipc	ra,0xfffff
    80001662:	ede080e7          	jalr	-290(ra) # 8000053c <panic>

0000000080001666 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001666:	c6bd                	beqz	a3,800016d4 <copyout+0x6e>
{
    80001668:	715d                	addi	sp,sp,-80
    8000166a:	e486                	sd	ra,72(sp)
    8000166c:	e0a2                	sd	s0,64(sp)
    8000166e:	fc26                	sd	s1,56(sp)
    80001670:	f84a                	sd	s2,48(sp)
    80001672:	f44e                	sd	s3,40(sp)
    80001674:	f052                	sd	s4,32(sp)
    80001676:	ec56                	sd	s5,24(sp)
    80001678:	e85a                	sd	s6,16(sp)
    8000167a:	e45e                	sd	s7,8(sp)
    8000167c:	e062                	sd	s8,0(sp)
    8000167e:	0880                	addi	s0,sp,80
    80001680:	8b2a                	mv	s6,a0
    80001682:	8c2e                	mv	s8,a1
    80001684:	8a32                	mv	s4,a2
    80001686:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001688:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168a:	6a85                	lui	s5,0x1
    8000168c:	a015                	j	800016b0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000168e:	9562                	add	a0,a0,s8
    80001690:	0004861b          	sext.w	a2,s1
    80001694:	85d2                	mv	a1,s4
    80001696:	41250533          	sub	a0,a0,s2
    8000169a:	fffff097          	auipc	ra,0xfffff
    8000169e:	690080e7          	jalr	1680(ra) # 80000d2a <memmove>

    len -= n;
    800016a2:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a6:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016a8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ac:	02098263          	beqz	s3,800016d0 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b4:	85ca                	mv	a1,s2
    800016b6:	855a                	mv	a0,s6
    800016b8:	00000097          	auipc	ra,0x0
    800016bc:	99e080e7          	jalr	-1634(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    800016c0:	cd01                	beqz	a0,800016d8 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c2:	418904b3          	sub	s1,s2,s8
    800016c6:	94d6                	add	s1,s1,s5
    800016c8:	fc99f3e3          	bgeu	s3,s1,8000168e <copyout+0x28>
    800016cc:	84ce                	mv	s1,s3
    800016ce:	b7c1                	j	8000168e <copyout+0x28>
  }
  return 0;
    800016d0:	4501                	li	a0,0
    800016d2:	a021                	j	800016da <copyout+0x74>
    800016d4:	4501                	li	a0,0
}
    800016d6:	8082                	ret
      return -1;
    800016d8:	557d                	li	a0,-1
}
    800016da:	60a6                	ld	ra,72(sp)
    800016dc:	6406                	ld	s0,64(sp)
    800016de:	74e2                	ld	s1,56(sp)
    800016e0:	7942                	ld	s2,48(sp)
    800016e2:	79a2                	ld	s3,40(sp)
    800016e4:	7a02                	ld	s4,32(sp)
    800016e6:	6ae2                	ld	s5,24(sp)
    800016e8:	6b42                	ld	s6,16(sp)
    800016ea:	6ba2                	ld	s7,8(sp)
    800016ec:	6c02                	ld	s8,0(sp)
    800016ee:	6161                	addi	sp,sp,80
    800016f0:	8082                	ret

00000000800016f2 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f2:	caa5                	beqz	a3,80001762 <copyin+0x70>
{
    800016f4:	715d                	addi	sp,sp,-80
    800016f6:	e486                	sd	ra,72(sp)
    800016f8:	e0a2                	sd	s0,64(sp)
    800016fa:	fc26                	sd	s1,56(sp)
    800016fc:	f84a                	sd	s2,48(sp)
    800016fe:	f44e                	sd	s3,40(sp)
    80001700:	f052                	sd	s4,32(sp)
    80001702:	ec56                	sd	s5,24(sp)
    80001704:	e85a                	sd	s6,16(sp)
    80001706:	e45e                	sd	s7,8(sp)
    80001708:	e062                	sd	s8,0(sp)
    8000170a:	0880                	addi	s0,sp,80
    8000170c:	8b2a                	mv	s6,a0
    8000170e:	8a2e                	mv	s4,a1
    80001710:	8c32                	mv	s8,a2
    80001712:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001714:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001716:	6a85                	lui	s5,0x1
    80001718:	a01d                	j	8000173e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171a:	018505b3          	add	a1,a0,s8
    8000171e:	0004861b          	sext.w	a2,s1
    80001722:	412585b3          	sub	a1,a1,s2
    80001726:	8552                	mv	a0,s4
    80001728:	fffff097          	auipc	ra,0xfffff
    8000172c:	602080e7          	jalr	1538(ra) # 80000d2a <memmove>

    len -= n;
    80001730:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001734:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001736:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173a:	02098263          	beqz	s3,8000175e <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000173e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001742:	85ca                	mv	a1,s2
    80001744:	855a                	mv	a0,s6
    80001746:	00000097          	auipc	ra,0x0
    8000174a:	910080e7          	jalr	-1776(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    8000174e:	cd01                	beqz	a0,80001766 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001750:	418904b3          	sub	s1,s2,s8
    80001754:	94d6                	add	s1,s1,s5
    80001756:	fc99f2e3          	bgeu	s3,s1,8000171a <copyin+0x28>
    8000175a:	84ce                	mv	s1,s3
    8000175c:	bf7d                	j	8000171a <copyin+0x28>
  }
  return 0;
    8000175e:	4501                	li	a0,0
    80001760:	a021                	j	80001768 <copyin+0x76>
    80001762:	4501                	li	a0,0
}
    80001764:	8082                	ret
      return -1;
    80001766:	557d                	li	a0,-1
}
    80001768:	60a6                	ld	ra,72(sp)
    8000176a:	6406                	ld	s0,64(sp)
    8000176c:	74e2                	ld	s1,56(sp)
    8000176e:	7942                	ld	s2,48(sp)
    80001770:	79a2                	ld	s3,40(sp)
    80001772:	7a02                	ld	s4,32(sp)
    80001774:	6ae2                	ld	s5,24(sp)
    80001776:	6b42                	ld	s6,16(sp)
    80001778:	6ba2                	ld	s7,8(sp)
    8000177a:	6c02                	ld	s8,0(sp)
    8000177c:	6161                	addi	sp,sp,80
    8000177e:	8082                	ret

0000000080001780 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001780:	c2dd                	beqz	a3,80001826 <copyinstr+0xa6>
{
    80001782:	715d                	addi	sp,sp,-80
    80001784:	e486                	sd	ra,72(sp)
    80001786:	e0a2                	sd	s0,64(sp)
    80001788:	fc26                	sd	s1,56(sp)
    8000178a:	f84a                	sd	s2,48(sp)
    8000178c:	f44e                	sd	s3,40(sp)
    8000178e:	f052                	sd	s4,32(sp)
    80001790:	ec56                	sd	s5,24(sp)
    80001792:	e85a                	sd	s6,16(sp)
    80001794:	e45e                	sd	s7,8(sp)
    80001796:	0880                	addi	s0,sp,80
    80001798:	8a2a                	mv	s4,a0
    8000179a:	8b2e                	mv	s6,a1
    8000179c:	8bb2                	mv	s7,a2
    8000179e:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a0:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a2:	6985                	lui	s3,0x1
    800017a4:	a02d                	j	800017ce <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a6:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017aa:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ac:	37fd                	addiw	a5,a5,-1
    800017ae:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b2:	60a6                	ld	ra,72(sp)
    800017b4:	6406                	ld	s0,64(sp)
    800017b6:	74e2                	ld	s1,56(sp)
    800017b8:	7942                	ld	s2,48(sp)
    800017ba:	79a2                	ld	s3,40(sp)
    800017bc:	7a02                	ld	s4,32(sp)
    800017be:	6ae2                	ld	s5,24(sp)
    800017c0:	6b42                	ld	s6,16(sp)
    800017c2:	6ba2                	ld	s7,8(sp)
    800017c4:	6161                	addi	sp,sp,80
    800017c6:	8082                	ret
    srcva = va0 + PGSIZE;
    800017c8:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017cc:	c8a9                	beqz	s1,8000181e <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017ce:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d2:	85ca                	mv	a1,s2
    800017d4:	8552                	mv	a0,s4
    800017d6:	00000097          	auipc	ra,0x0
    800017da:	880080e7          	jalr	-1920(ra) # 80001056 <walkaddr>
    if(pa0 == 0)
    800017de:	c131                	beqz	a0,80001822 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e0:	417906b3          	sub	a3,s2,s7
    800017e4:	96ce                	add	a3,a3,s3
    800017e6:	00d4f363          	bgeu	s1,a3,800017ec <copyinstr+0x6c>
    800017ea:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017ec:	955e                	add	a0,a0,s7
    800017ee:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f2:	daf9                	beqz	a3,800017c8 <copyinstr+0x48>
    800017f4:	87da                	mv	a5,s6
    800017f6:	885a                	mv	a6,s6
      if(*p == '\0'){
    800017f8:	41650633          	sub	a2,a0,s6
    while(n > 0){
    800017fc:	96da                	add	a3,a3,s6
    800017fe:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001800:	00f60733          	add	a4,a2,a5
    80001804:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd1f0>
    80001808:	df59                	beqz	a4,800017a6 <copyinstr+0x26>
        *dst = *p;
    8000180a:	00e78023          	sb	a4,0(a5)
      dst++;
    8000180e:	0785                	addi	a5,a5,1
    while(n > 0){
    80001810:	fed797e3          	bne	a5,a3,800017fe <copyinstr+0x7e>
    80001814:	14fd                	addi	s1,s1,-1
    80001816:	94c2                	add	s1,s1,a6
      --max;
    80001818:	8c8d                	sub	s1,s1,a1
      dst++;
    8000181a:	8b3e                	mv	s6,a5
    8000181c:	b775                	j	800017c8 <copyinstr+0x48>
    8000181e:	4781                	li	a5,0
    80001820:	b771                	j	800017ac <copyinstr+0x2c>
      return -1;
    80001822:	557d                	li	a0,-1
    80001824:	b779                	j	800017b2 <copyinstr+0x32>
  int got_null = 0;
    80001826:	4781                	li	a5,0
  if(got_null){
    80001828:	37fd                	addiw	a5,a5,-1
    8000182a:	0007851b          	sext.w	a0,a5
}
    8000182e:	8082                	ret

0000000080001830 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001830:	7139                	addi	sp,sp,-64
    80001832:	fc06                	sd	ra,56(sp)
    80001834:	f822                	sd	s0,48(sp)
    80001836:	f426                	sd	s1,40(sp)
    80001838:	f04a                	sd	s2,32(sp)
    8000183a:	ec4e                	sd	s3,24(sp)
    8000183c:	e852                	sd	s4,16(sp)
    8000183e:	e456                	sd	s5,8(sp)
    80001840:	e05a                	sd	s6,0(sp)
    80001842:	0080                	addi	s0,sp,64
    80001844:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001846:	0000f497          	auipc	s1,0xf
    8000184a:	7ea48493          	addi	s1,s1,2026 # 80011030 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000184e:	8b26                	mv	s6,s1
    80001850:	00006a97          	auipc	s5,0x6
    80001854:	7b0a8a93          	addi	s5,s5,1968 # 80008000 <etext>
    80001858:	04000937          	lui	s2,0x4000
    8000185c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000185e:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001860:	00015a17          	auipc	s4,0x15
    80001864:	1d0a0a13          	addi	s4,s4,464 # 80016a30 <tickslock>
    char *pa = kalloc();
    80001868:	fffff097          	auipc	ra,0xfffff
    8000186c:	27a080e7          	jalr	634(ra) # 80000ae2 <kalloc>
    80001870:	862a                	mv	a2,a0
    if (pa == 0)
    80001872:	c131                	beqz	a0,800018b6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001874:	416485b3          	sub	a1,s1,s6
    80001878:	858d                	srai	a1,a1,0x3
    8000187a:	000ab783          	ld	a5,0(s5)
    8000187e:	02f585b3          	mul	a1,a1,a5
    80001882:	2585                	addiw	a1,a1,1
    80001884:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001888:	4719                	li	a4,6
    8000188a:	6685                	lui	a3,0x1
    8000188c:	40b905b3          	sub	a1,s2,a1
    80001890:	854e                	mv	a0,s3
    80001892:	00000097          	auipc	ra,0x0
    80001896:	8a6080e7          	jalr	-1882(ra) # 80001138 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    8000189a:	16848493          	addi	s1,s1,360
    8000189e:	fd4495e3          	bne	s1,s4,80001868 <proc_mapstacks+0x38>
  }
}
    800018a2:	70e2                	ld	ra,56(sp)
    800018a4:	7442                	ld	s0,48(sp)
    800018a6:	74a2                	ld	s1,40(sp)
    800018a8:	7902                	ld	s2,32(sp)
    800018aa:	69e2                	ld	s3,24(sp)
    800018ac:	6a42                	ld	s4,16(sp)
    800018ae:	6aa2                	ld	s5,8(sp)
    800018b0:	6b02                	ld	s6,0(sp)
    800018b2:	6121                	addi	sp,sp,64
    800018b4:	8082                	ret
      panic("kalloc");
    800018b6:	00007517          	auipc	a0,0x7
    800018ba:	92250513          	addi	a0,a0,-1758 # 800081d8 <digits+0x198>
    800018be:	fffff097          	auipc	ra,0xfffff
    800018c2:	c7e080e7          	jalr	-898(ra) # 8000053c <panic>

00000000800018c6 <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018c6:	7139                	addi	sp,sp,-64
    800018c8:	fc06                	sd	ra,56(sp)
    800018ca:	f822                	sd	s0,48(sp)
    800018cc:	f426                	sd	s1,40(sp)
    800018ce:	f04a                	sd	s2,32(sp)
    800018d0:	ec4e                	sd	s3,24(sp)
    800018d2:	e852                	sd	s4,16(sp)
    800018d4:	e456                	sd	s5,8(sp)
    800018d6:	e05a                	sd	s6,0(sp)
    800018d8:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018da:	00007597          	auipc	a1,0x7
    800018de:	90658593          	addi	a1,a1,-1786 # 800081e0 <digits+0x1a0>
    800018e2:	0000f517          	auipc	a0,0xf
    800018e6:	31e50513          	addi	a0,a0,798 # 80010c00 <pid_lock>
    800018ea:	fffff097          	auipc	ra,0xfffff
    800018ee:	258080e7          	jalr	600(ra) # 80000b42 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f2:	00007597          	auipc	a1,0x7
    800018f6:	8f658593          	addi	a1,a1,-1802 # 800081e8 <digits+0x1a8>
    800018fa:	0000f517          	auipc	a0,0xf
    800018fe:	31e50513          	addi	a0,a0,798 # 80010c18 <wait_lock>
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	240080e7          	jalr	576(ra) # 80000b42 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    8000190a:	0000f497          	auipc	s1,0xf
    8000190e:	72648493          	addi	s1,s1,1830 # 80011030 <proc>
  {
    initlock(&p->lock, "proc");
    80001912:	00007b17          	auipc	s6,0x7
    80001916:	8e6b0b13          	addi	s6,s6,-1818 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    8000191a:	8aa6                	mv	s5,s1
    8000191c:	00006a17          	auipc	s4,0x6
    80001920:	6e4a0a13          	addi	s4,s4,1764 # 80008000 <etext>
    80001924:	04000937          	lui	s2,0x4000
    80001928:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000192a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000192c:	00015997          	auipc	s3,0x15
    80001930:	10498993          	addi	s3,s3,260 # 80016a30 <tickslock>
    initlock(&p->lock, "proc");
    80001934:	85da                	mv	a1,s6
    80001936:	8526                	mv	a0,s1
    80001938:	fffff097          	auipc	ra,0xfffff
    8000193c:	20a080e7          	jalr	522(ra) # 80000b42 <initlock>
    p->state = UNUSED;
    80001940:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001944:	415487b3          	sub	a5,s1,s5
    80001948:	878d                	srai	a5,a5,0x3
    8000194a:	000a3703          	ld	a4,0(s4)
    8000194e:	02e787b3          	mul	a5,a5,a4
    80001952:	2785                	addiw	a5,a5,1
    80001954:	00d7979b          	slliw	a5,a5,0xd
    80001958:	40f907b3          	sub	a5,s2,a5
    8000195c:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    8000195e:	16848493          	addi	s1,s1,360
    80001962:	fd3499e3          	bne	s1,s3,80001934 <procinit+0x6e>
  }
}
    80001966:	70e2                	ld	ra,56(sp)
    80001968:	7442                	ld	s0,48(sp)
    8000196a:	74a2                	ld	s1,40(sp)
    8000196c:	7902                	ld	s2,32(sp)
    8000196e:	69e2                	ld	s3,24(sp)
    80001970:	6a42                	ld	s4,16(sp)
    80001972:	6aa2                	ld	s5,8(sp)
    80001974:	6b02                	ld	s6,0(sp)
    80001976:	6121                	addi	sp,sp,64
    80001978:	8082                	ret

000000008000197a <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    8000197a:	1141                	addi	sp,sp,-16
    8000197c:	e422                	sd	s0,8(sp)
    8000197e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001980:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001982:	2501                	sext.w	a0,a0
    80001984:	6422                	ld	s0,8(sp)
    80001986:	0141                	addi	sp,sp,16
    80001988:	8082                	ret

000000008000198a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    8000198a:	1141                	addi	sp,sp,-16
    8000198c:	e422                	sd	s0,8(sp)
    8000198e:	0800                	addi	s0,sp,16
    80001990:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001992:	2781                	sext.w	a5,a5
    80001994:	079e                	slli	a5,a5,0x7
  return c;
}
    80001996:	0000f517          	auipc	a0,0xf
    8000199a:	29a50513          	addi	a0,a0,666 # 80010c30 <cpus>
    8000199e:	953e                	add	a0,a0,a5
    800019a0:	6422                	ld	s0,8(sp)
    800019a2:	0141                	addi	sp,sp,16
    800019a4:	8082                	ret

00000000800019a6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019a6:	1101                	addi	sp,sp,-32
    800019a8:	ec06                	sd	ra,24(sp)
    800019aa:	e822                	sd	s0,16(sp)
    800019ac:	e426                	sd	s1,8(sp)
    800019ae:	1000                	addi	s0,sp,32
  push_off();
    800019b0:	fffff097          	auipc	ra,0xfffff
    800019b4:	1d6080e7          	jalr	470(ra) # 80000b86 <push_off>
    800019b8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019ba:	2781                	sext.w	a5,a5
    800019bc:	079e                	slli	a5,a5,0x7
    800019be:	0000f717          	auipc	a4,0xf
    800019c2:	24270713          	addi	a4,a4,578 # 80010c00 <pid_lock>
    800019c6:	97ba                	add	a5,a5,a4
    800019c8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	25c080e7          	jalr	604(ra) # 80000c26 <pop_off>
  return p;
}
    800019d2:	8526                	mv	a0,s1
    800019d4:	60e2                	ld	ra,24(sp)
    800019d6:	6442                	ld	s0,16(sp)
    800019d8:	64a2                	ld	s1,8(sp)
    800019da:	6105                	addi	sp,sp,32
    800019dc:	8082                	ret

00000000800019de <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019de:	1141                	addi	sp,sp,-16
    800019e0:	e406                	sd	ra,8(sp)
    800019e2:	e022                	sd	s0,0(sp)
    800019e4:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019e6:	00000097          	auipc	ra,0x0
    800019ea:	fc0080e7          	jalr	-64(ra) # 800019a6 <myproc>
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	298080e7          	jalr	664(ra) # 80000c86 <release>

  if (first)
    800019f6:	00007797          	auipc	a5,0x7
    800019fa:	f1a7a783          	lw	a5,-230(a5) # 80008910 <first.1>
    800019fe:	eb89                	bnez	a5,80001a10 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a00:	00001097          	auipc	ra,0x1
    80001a04:	cc8080e7          	jalr	-824(ra) # 800026c8 <usertrapret>
}
    80001a08:	60a2                	ld	ra,8(sp)
    80001a0a:	6402                	ld	s0,0(sp)
    80001a0c:	0141                	addi	sp,sp,16
    80001a0e:	8082                	ret
    first = 0;
    80001a10:	00007797          	auipc	a5,0x7
    80001a14:	f007a023          	sw	zero,-256(a5) # 80008910 <first.1>
    fsinit(ROOTDEV);
    80001a18:	4505                	li	a0,1
    80001a1a:	00002097          	auipc	ra,0x2
    80001a1e:	ad6080e7          	jalr	-1322(ra) # 800034f0 <fsinit>
    80001a22:	bff9                	j	80001a00 <forkret+0x22>

0000000080001a24 <allocpid>:
{
    80001a24:	1101                	addi	sp,sp,-32
    80001a26:	ec06                	sd	ra,24(sp)
    80001a28:	e822                	sd	s0,16(sp)
    80001a2a:	e426                	sd	s1,8(sp)
    80001a2c:	e04a                	sd	s2,0(sp)
    80001a2e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a30:	0000f917          	auipc	s2,0xf
    80001a34:	1d090913          	addi	s2,s2,464 # 80010c00 <pid_lock>
    80001a38:	854a                	mv	a0,s2
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	198080e7          	jalr	408(ra) # 80000bd2 <acquire>
  pid = nextpid;
    80001a42:	00007797          	auipc	a5,0x7
    80001a46:	ed278793          	addi	a5,a5,-302 # 80008914 <nextpid>
    80001a4a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a4c:	0014871b          	addiw	a4,s1,1
    80001a50:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a52:	854a                	mv	a0,s2
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	232080e7          	jalr	562(ra) # 80000c86 <release>
}
    80001a5c:	8526                	mv	a0,s1
    80001a5e:	60e2                	ld	ra,24(sp)
    80001a60:	6442                	ld	s0,16(sp)
    80001a62:	64a2                	ld	s1,8(sp)
    80001a64:	6902                	ld	s2,0(sp)
    80001a66:	6105                	addi	sp,sp,32
    80001a68:	8082                	ret

0000000080001a6a <proc_pagetable>:
{
    80001a6a:	1101                	addi	sp,sp,-32
    80001a6c:	ec06                	sd	ra,24(sp)
    80001a6e:	e822                	sd	s0,16(sp)
    80001a70:	e426                	sd	s1,8(sp)
    80001a72:	e04a                	sd	s2,0(sp)
    80001a74:	1000                	addi	s0,sp,32
    80001a76:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a78:	00000097          	auipc	ra,0x0
    80001a7c:	8aa080e7          	jalr	-1878(ra) # 80001322 <uvmcreate>
    80001a80:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a82:	c121                	beqz	a0,80001ac2 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a84:	4729                	li	a4,10
    80001a86:	00005697          	auipc	a3,0x5
    80001a8a:	57a68693          	addi	a3,a3,1402 # 80007000 <_trampoline>
    80001a8e:	6605                	lui	a2,0x1
    80001a90:	040005b7          	lui	a1,0x4000
    80001a94:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a96:	05b2                	slli	a1,a1,0xc
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	600080e7          	jalr	1536(ra) # 80001098 <mappages>
    80001aa0:	02054863          	bltz	a0,80001ad0 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aa4:	4719                	li	a4,6
    80001aa6:	05893683          	ld	a3,88(s2)
    80001aaa:	6605                	lui	a2,0x1
    80001aac:	020005b7          	lui	a1,0x2000
    80001ab0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab2:	05b6                	slli	a1,a1,0xd
    80001ab4:	8526                	mv	a0,s1
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	5e2080e7          	jalr	1506(ra) # 80001098 <mappages>
    80001abe:	02054163          	bltz	a0,80001ae0 <proc_pagetable+0x76>
}
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	60e2                	ld	ra,24(sp)
    80001ac6:	6442                	ld	s0,16(sp)
    80001ac8:	64a2                	ld	s1,8(sp)
    80001aca:	6902                	ld	s2,0(sp)
    80001acc:	6105                	addi	sp,sp,32
    80001ace:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad0:	4581                	li	a1,0
    80001ad2:	8526                	mv	a0,s1
    80001ad4:	00000097          	auipc	ra,0x0
    80001ad8:	a54080e7          	jalr	-1452(ra) # 80001528 <uvmfree>
    return 0;
    80001adc:	4481                	li	s1,0
    80001ade:	b7d5                	j	80001ac2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae0:	4681                	li	a3,0
    80001ae2:	4605                	li	a2,1
    80001ae4:	040005b7          	lui	a1,0x4000
    80001ae8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001aea:	05b2                	slli	a1,a1,0xc
    80001aec:	8526                	mv	a0,s1
    80001aee:	fffff097          	auipc	ra,0xfffff
    80001af2:	770080e7          	jalr	1904(ra) # 8000125e <uvmunmap>
    uvmfree(pagetable, 0);
    80001af6:	4581                	li	a1,0
    80001af8:	8526                	mv	a0,s1
    80001afa:	00000097          	auipc	ra,0x0
    80001afe:	a2e080e7          	jalr	-1490(ra) # 80001528 <uvmfree>
    return 0;
    80001b02:	4481                	li	s1,0
    80001b04:	bf7d                	j	80001ac2 <proc_pagetable+0x58>

0000000080001b06 <proc_freepagetable>:
{
    80001b06:	1101                	addi	sp,sp,-32
    80001b08:	ec06                	sd	ra,24(sp)
    80001b0a:	e822                	sd	s0,16(sp)
    80001b0c:	e426                	sd	s1,8(sp)
    80001b0e:	e04a                	sd	s2,0(sp)
    80001b10:	1000                	addi	s0,sp,32
    80001b12:	84aa                	mv	s1,a0
    80001b14:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b16:	4681                	li	a3,0
    80001b18:	4605                	li	a2,1
    80001b1a:	040005b7          	lui	a1,0x4000
    80001b1e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b20:	05b2                	slli	a1,a1,0xc
    80001b22:	fffff097          	auipc	ra,0xfffff
    80001b26:	73c080e7          	jalr	1852(ra) # 8000125e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b2a:	4681                	li	a3,0
    80001b2c:	4605                	li	a2,1
    80001b2e:	020005b7          	lui	a1,0x2000
    80001b32:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b34:	05b6                	slli	a1,a1,0xd
    80001b36:	8526                	mv	a0,s1
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	726080e7          	jalr	1830(ra) # 8000125e <uvmunmap>
  uvmfree(pagetable, sz);
    80001b40:	85ca                	mv	a1,s2
    80001b42:	8526                	mv	a0,s1
    80001b44:	00000097          	auipc	ra,0x0
    80001b48:	9e4080e7          	jalr	-1564(ra) # 80001528 <uvmfree>
}
    80001b4c:	60e2                	ld	ra,24(sp)
    80001b4e:	6442                	ld	s0,16(sp)
    80001b50:	64a2                	ld	s1,8(sp)
    80001b52:	6902                	ld	s2,0(sp)
    80001b54:	6105                	addi	sp,sp,32
    80001b56:	8082                	ret

0000000080001b58 <freeproc>:
{
    80001b58:	1101                	addi	sp,sp,-32
    80001b5a:	ec06                	sd	ra,24(sp)
    80001b5c:	e822                	sd	s0,16(sp)
    80001b5e:	e426                	sd	s1,8(sp)
    80001b60:	1000                	addi	s0,sp,32
    80001b62:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b64:	6d28                	ld	a0,88(a0)
    80001b66:	c509                	beqz	a0,80001b70 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	e7c080e7          	jalr	-388(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001b70:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b74:	68a8                	ld	a0,80(s1)
    80001b76:	c511                	beqz	a0,80001b82 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b78:	64ac                	ld	a1,72(s1)
    80001b7a:	00000097          	auipc	ra,0x0
    80001b7e:	f8c080e7          	jalr	-116(ra) # 80001b06 <proc_freepagetable>
  p->pagetable = 0;
    80001b82:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b86:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b8a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b8e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b92:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b96:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b9a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b9e:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba2:	0004ac23          	sw	zero,24(s1)
}
    80001ba6:	60e2                	ld	ra,24(sp)
    80001ba8:	6442                	ld	s0,16(sp)
    80001baa:	64a2                	ld	s1,8(sp)
    80001bac:	6105                	addi	sp,sp,32
    80001bae:	8082                	ret

0000000080001bb0 <allocproc>:
{
    80001bb0:	1101                	addi	sp,sp,-32
    80001bb2:	ec06                	sd	ra,24(sp)
    80001bb4:	e822                	sd	s0,16(sp)
    80001bb6:	e426                	sd	s1,8(sp)
    80001bb8:	e04a                	sd	s2,0(sp)
    80001bba:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bbc:	0000f497          	auipc	s1,0xf
    80001bc0:	47448493          	addi	s1,s1,1140 # 80011030 <proc>
    80001bc4:	00015917          	auipc	s2,0x15
    80001bc8:	e6c90913          	addi	s2,s2,-404 # 80016a30 <tickslock>
    acquire(&p->lock);
    80001bcc:	8526                	mv	a0,s1
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	004080e7          	jalr	4(ra) # 80000bd2 <acquire>
    if (p->state == UNUSED)
    80001bd6:	4c9c                	lw	a5,24(s1)
    80001bd8:	cf81                	beqz	a5,80001bf0 <allocproc+0x40>
      release(&p->lock);
    80001bda:	8526                	mv	a0,s1
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	0aa080e7          	jalr	170(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001be4:	16848493          	addi	s1,s1,360
    80001be8:	ff2492e3          	bne	s1,s2,80001bcc <allocproc+0x1c>
  return 0;
    80001bec:	4481                	li	s1,0
    80001bee:	a889                	j	80001c40 <allocproc+0x90>
  p->pid = allocpid();
    80001bf0:	00000097          	auipc	ra,0x0
    80001bf4:	e34080e7          	jalr	-460(ra) # 80001a24 <allocpid>
    80001bf8:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001bfa:	4785                	li	a5,1
    80001bfc:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	ee4080e7          	jalr	-284(ra) # 80000ae2 <kalloc>
    80001c06:	892a                	mv	s2,a0
    80001c08:	eca8                	sd	a0,88(s1)
    80001c0a:	c131                	beqz	a0,80001c4e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c0c:	8526                	mv	a0,s1
    80001c0e:	00000097          	auipc	ra,0x0
    80001c12:	e5c080e7          	jalr	-420(ra) # 80001a6a <proc_pagetable>
    80001c16:	892a                	mv	s2,a0
    80001c18:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c1a:	c531                	beqz	a0,80001c66 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c1c:	07000613          	li	a2,112
    80001c20:	4581                	li	a1,0
    80001c22:	06048513          	addi	a0,s1,96
    80001c26:	fffff097          	auipc	ra,0xfffff
    80001c2a:	0a8080e7          	jalr	168(ra) # 80000cce <memset>
  p->context.ra = (uint64)forkret;
    80001c2e:	00000797          	auipc	a5,0x0
    80001c32:	db078793          	addi	a5,a5,-592 # 800019de <forkret>
    80001c36:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c38:	60bc                	ld	a5,64(s1)
    80001c3a:	6705                	lui	a4,0x1
    80001c3c:	97ba                	add	a5,a5,a4
    80001c3e:	f4bc                	sd	a5,104(s1)
}
    80001c40:	8526                	mv	a0,s1
    80001c42:	60e2                	ld	ra,24(sp)
    80001c44:	6442                	ld	s0,16(sp)
    80001c46:	64a2                	ld	s1,8(sp)
    80001c48:	6902                	ld	s2,0(sp)
    80001c4a:	6105                	addi	sp,sp,32
    80001c4c:	8082                	ret
    freeproc(p);
    80001c4e:	8526                	mv	a0,s1
    80001c50:	00000097          	auipc	ra,0x0
    80001c54:	f08080e7          	jalr	-248(ra) # 80001b58 <freeproc>
    release(&p->lock);
    80001c58:	8526                	mv	a0,s1
    80001c5a:	fffff097          	auipc	ra,0xfffff
    80001c5e:	02c080e7          	jalr	44(ra) # 80000c86 <release>
    return 0;
    80001c62:	84ca                	mv	s1,s2
    80001c64:	bff1                	j	80001c40 <allocproc+0x90>
    freeproc(p);
    80001c66:	8526                	mv	a0,s1
    80001c68:	00000097          	auipc	ra,0x0
    80001c6c:	ef0080e7          	jalr	-272(ra) # 80001b58 <freeproc>
    release(&p->lock);
    80001c70:	8526                	mv	a0,s1
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	014080e7          	jalr	20(ra) # 80000c86 <release>
    return 0;
    80001c7a:	84ca                	mv	s1,s2
    80001c7c:	b7d1                	j	80001c40 <allocproc+0x90>

0000000080001c7e <userinit>:
{
    80001c7e:	1101                	addi	sp,sp,-32
    80001c80:	ec06                	sd	ra,24(sp)
    80001c82:	e822                	sd	s0,16(sp)
    80001c84:	e426                	sd	s1,8(sp)
    80001c86:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c88:	00000097          	auipc	ra,0x0
    80001c8c:	f28080e7          	jalr	-216(ra) # 80001bb0 <allocproc>
    80001c90:	84aa                	mv	s1,a0
  initproc = p;
    80001c92:	00007797          	auipc	a5,0x7
    80001c96:	cea7bb23          	sd	a0,-778(a5) # 80008988 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001c9a:	03400613          	li	a2,52
    80001c9e:	00007597          	auipc	a1,0x7
    80001ca2:	c8258593          	addi	a1,a1,-894 # 80008920 <initcode>
    80001ca6:	6928                	ld	a0,80(a0)
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	6a8080e7          	jalr	1704(ra) # 80001350 <uvmfirst>
  p->sz = PGSIZE;
    80001cb0:	6785                	lui	a5,0x1
    80001cb2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cb4:	6cb8                	ld	a4,88(s1)
    80001cb6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cba:	6cb8                	ld	a4,88(s1)
    80001cbc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cbe:	4641                	li	a2,16
    80001cc0:	00006597          	auipc	a1,0x6
    80001cc4:	54058593          	addi	a1,a1,1344 # 80008200 <digits+0x1c0>
    80001cc8:	15848513          	addi	a0,s1,344
    80001ccc:	fffff097          	auipc	ra,0xfffff
    80001cd0:	14a080e7          	jalr	330(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001cd4:	00006517          	auipc	a0,0x6
    80001cd8:	53c50513          	addi	a0,a0,1340 # 80008210 <digits+0x1d0>
    80001cdc:	00002097          	auipc	ra,0x2
    80001ce0:	232080e7          	jalr	562(ra) # 80003f0e <namei>
    80001ce4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001ce8:	478d                	li	a5,3
    80001cea:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cec:	8526                	mv	a0,s1
    80001cee:	fffff097          	auipc	ra,0xfffff
    80001cf2:	f98080e7          	jalr	-104(ra) # 80000c86 <release>
}
    80001cf6:	60e2                	ld	ra,24(sp)
    80001cf8:	6442                	ld	s0,16(sp)
    80001cfa:	64a2                	ld	s1,8(sp)
    80001cfc:	6105                	addi	sp,sp,32
    80001cfe:	8082                	ret

0000000080001d00 <growproc>:
{
    80001d00:	1101                	addi	sp,sp,-32
    80001d02:	ec06                	sd	ra,24(sp)
    80001d04:	e822                	sd	s0,16(sp)
    80001d06:	e426                	sd	s1,8(sp)
    80001d08:	e04a                	sd	s2,0(sp)
    80001d0a:	1000                	addi	s0,sp,32
    80001d0c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d0e:	00000097          	auipc	ra,0x0
    80001d12:	c98080e7          	jalr	-872(ra) # 800019a6 <myproc>
    80001d16:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d18:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d1a:	01204c63          	bgtz	s2,80001d32 <growproc+0x32>
  else if (n < 0)
    80001d1e:	02094663          	bltz	s2,80001d4a <growproc+0x4a>
  p->sz = sz;
    80001d22:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d24:	4501                	li	a0,0
}
    80001d26:	60e2                	ld	ra,24(sp)
    80001d28:	6442                	ld	s0,16(sp)
    80001d2a:	64a2                	ld	s1,8(sp)
    80001d2c:	6902                	ld	s2,0(sp)
    80001d2e:	6105                	addi	sp,sp,32
    80001d30:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d32:	4691                	li	a3,4
    80001d34:	00b90633          	add	a2,s2,a1
    80001d38:	6928                	ld	a0,80(a0)
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	6d0080e7          	jalr	1744(ra) # 8000140a <uvmalloc>
    80001d42:	85aa                	mv	a1,a0
    80001d44:	fd79                	bnez	a0,80001d22 <growproc+0x22>
      return -1;
    80001d46:	557d                	li	a0,-1
    80001d48:	bff9                	j	80001d26 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d4a:	00b90633          	add	a2,s2,a1
    80001d4e:	6928                	ld	a0,80(a0)
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	672080e7          	jalr	1650(ra) # 800013c2 <uvmdealloc>
    80001d58:	85aa                	mv	a1,a0
    80001d5a:	b7e1                	j	80001d22 <growproc+0x22>

0000000080001d5c <fork>:
{
    80001d5c:	7139                	addi	sp,sp,-64
    80001d5e:	fc06                	sd	ra,56(sp)
    80001d60:	f822                	sd	s0,48(sp)
    80001d62:	f426                	sd	s1,40(sp)
    80001d64:	f04a                	sd	s2,32(sp)
    80001d66:	ec4e                	sd	s3,24(sp)
    80001d68:	e852                	sd	s4,16(sp)
    80001d6a:	e456                	sd	s5,8(sp)
    80001d6c:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d6e:	00000097          	auipc	ra,0x0
    80001d72:	c38080e7          	jalr	-968(ra) # 800019a6 <myproc>
    80001d76:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001d78:	00000097          	auipc	ra,0x0
    80001d7c:	e38080e7          	jalr	-456(ra) # 80001bb0 <allocproc>
    80001d80:	10050c63          	beqz	a0,80001e98 <fork+0x13c>
    80001d84:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001d86:	048ab603          	ld	a2,72(s5)
    80001d8a:	692c                	ld	a1,80(a0)
    80001d8c:	050ab503          	ld	a0,80(s5)
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	7d2080e7          	jalr	2002(ra) # 80001562 <uvmcopy>
    80001d98:	04054863          	bltz	a0,80001de8 <fork+0x8c>
  np->sz = p->sz;
    80001d9c:	048ab783          	ld	a5,72(s5)
    80001da0:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001da4:	058ab683          	ld	a3,88(s5)
    80001da8:	87b6                	mv	a5,a3
    80001daa:	058a3703          	ld	a4,88(s4)
    80001dae:	12068693          	addi	a3,a3,288
    80001db2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001db6:	6788                	ld	a0,8(a5)
    80001db8:	6b8c                	ld	a1,16(a5)
    80001dba:	6f90                	ld	a2,24(a5)
    80001dbc:	01073023          	sd	a6,0(a4)
    80001dc0:	e708                	sd	a0,8(a4)
    80001dc2:	eb0c                	sd	a1,16(a4)
    80001dc4:	ef10                	sd	a2,24(a4)
    80001dc6:	02078793          	addi	a5,a5,32
    80001dca:	02070713          	addi	a4,a4,32
    80001dce:	fed792e3          	bne	a5,a3,80001db2 <fork+0x56>
  np->trapframe->a0 = 0;
    80001dd2:	058a3783          	ld	a5,88(s4)
    80001dd6:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001dda:	0d0a8493          	addi	s1,s5,208
    80001dde:	0d0a0913          	addi	s2,s4,208
    80001de2:	150a8993          	addi	s3,s5,336
    80001de6:	a00d                	j	80001e08 <fork+0xac>
    freeproc(np);
    80001de8:	8552                	mv	a0,s4
    80001dea:	00000097          	auipc	ra,0x0
    80001dee:	d6e080e7          	jalr	-658(ra) # 80001b58 <freeproc>
    release(&np->lock);
    80001df2:	8552                	mv	a0,s4
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	e92080e7          	jalr	-366(ra) # 80000c86 <release>
    return -1;
    80001dfc:	597d                	li	s2,-1
    80001dfe:	a059                	j	80001e84 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e00:	04a1                	addi	s1,s1,8
    80001e02:	0921                	addi	s2,s2,8
    80001e04:	01348b63          	beq	s1,s3,80001e1a <fork+0xbe>
    if (p->ofile[i])
    80001e08:	6088                	ld	a0,0(s1)
    80001e0a:	d97d                	beqz	a0,80001e00 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e0c:	00002097          	auipc	ra,0x2
    80001e10:	774080e7          	jalr	1908(ra) # 80004580 <filedup>
    80001e14:	00a93023          	sd	a0,0(s2)
    80001e18:	b7e5                	j	80001e00 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e1a:	150ab503          	ld	a0,336(s5)
    80001e1e:	00002097          	auipc	ra,0x2
    80001e22:	90c080e7          	jalr	-1780(ra) # 8000372a <idup>
    80001e26:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e2a:	4641                	li	a2,16
    80001e2c:	158a8593          	addi	a1,s5,344
    80001e30:	158a0513          	addi	a0,s4,344
    80001e34:	fffff097          	auipc	ra,0xfffff
    80001e38:	fe2080e7          	jalr	-30(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001e3c:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e40:	8552                	mv	a0,s4
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	e44080e7          	jalr	-444(ra) # 80000c86 <release>
  acquire(&wait_lock);
    80001e4a:	0000f497          	auipc	s1,0xf
    80001e4e:	dce48493          	addi	s1,s1,-562 # 80010c18 <wait_lock>
    80001e52:	8526                	mv	a0,s1
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	d7e080e7          	jalr	-642(ra) # 80000bd2 <acquire>
  np->parent = p;
    80001e5c:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e60:	8526                	mv	a0,s1
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	e24080e7          	jalr	-476(ra) # 80000c86 <release>
  acquire(&np->lock);
    80001e6a:	8552                	mv	a0,s4
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	d66080e7          	jalr	-666(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    80001e74:	478d                	li	a5,3
    80001e76:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e7a:	8552                	mv	a0,s4
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	e0a080e7          	jalr	-502(ra) # 80000c86 <release>
}
    80001e84:	854a                	mv	a0,s2
    80001e86:	70e2                	ld	ra,56(sp)
    80001e88:	7442                	ld	s0,48(sp)
    80001e8a:	74a2                	ld	s1,40(sp)
    80001e8c:	7902                	ld	s2,32(sp)
    80001e8e:	69e2                	ld	s3,24(sp)
    80001e90:	6a42                	ld	s4,16(sp)
    80001e92:	6aa2                	ld	s5,8(sp)
    80001e94:	6121                	addi	sp,sp,64
    80001e96:	8082                	ret
    return -1;
    80001e98:	597d                	li	s2,-1
    80001e9a:	b7ed                	j	80001e84 <fork+0x128>

0000000080001e9c <scheduler>:
{
    80001e9c:	7139                	addi	sp,sp,-64
    80001e9e:	fc06                	sd	ra,56(sp)
    80001ea0:	f822                	sd	s0,48(sp)
    80001ea2:	f426                	sd	s1,40(sp)
    80001ea4:	f04a                	sd	s2,32(sp)
    80001ea6:	ec4e                	sd	s3,24(sp)
    80001ea8:	e852                	sd	s4,16(sp)
    80001eaa:	e456                	sd	s5,8(sp)
    80001eac:	e05a                	sd	s6,0(sp)
    80001eae:	0080                	addi	s0,sp,64
    80001eb0:	8792                	mv	a5,tp
  int id = r_tp();
    80001eb2:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eb4:	00779a93          	slli	s5,a5,0x7
    80001eb8:	0000f717          	auipc	a4,0xf
    80001ebc:	d4870713          	addi	a4,a4,-696 # 80010c00 <pid_lock>
    80001ec0:	9756                	add	a4,a4,s5
    80001ec2:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ec6:	0000f717          	auipc	a4,0xf
    80001eca:	d7270713          	addi	a4,a4,-654 # 80010c38 <cpus+0x8>
    80001ece:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001ed0:	498d                	li	s3,3
        p->state = RUNNING;
    80001ed2:	4b11                	li	s6,4
        c->proc = p;
    80001ed4:	079e                	slli	a5,a5,0x7
    80001ed6:	0000fa17          	auipc	s4,0xf
    80001eda:	d2aa0a13          	addi	s4,s4,-726 # 80010c00 <pid_lock>
    80001ede:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001ee0:	00015917          	auipc	s2,0x15
    80001ee4:	b5090913          	addi	s2,s2,-1200 # 80016a30 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ee8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001eec:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef0:	10079073          	csrw	sstatus,a5
    80001ef4:	0000f497          	auipc	s1,0xf
    80001ef8:	13c48493          	addi	s1,s1,316 # 80011030 <proc>
    80001efc:	a811                	j	80001f10 <scheduler+0x74>
      release(&p->lock);
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	d86080e7          	jalr	-634(ra) # 80000c86 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f08:	16848493          	addi	s1,s1,360
    80001f0c:	fd248ee3          	beq	s1,s2,80001ee8 <scheduler+0x4c>
      acquire(&p->lock);
    80001f10:	8526                	mv	a0,s1
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	cc0080e7          	jalr	-832(ra) # 80000bd2 <acquire>
      if (p->state == RUNNABLE)
    80001f1a:	4c9c                	lw	a5,24(s1)
    80001f1c:	ff3791e3          	bne	a5,s3,80001efe <scheduler+0x62>
        p->state = RUNNING;
    80001f20:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f24:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f28:	06048593          	addi	a1,s1,96
    80001f2c:	8556                	mv	a0,s5
    80001f2e:	00000097          	auipc	ra,0x0
    80001f32:	6f0080e7          	jalr	1776(ra) # 8000261e <swtch>
        c->proc = 0;
    80001f36:	020a3823          	sd	zero,48(s4)
    80001f3a:	b7d1                	j	80001efe <scheduler+0x62>

0000000080001f3c <sched>:
{
    80001f3c:	7179                	addi	sp,sp,-48
    80001f3e:	f406                	sd	ra,40(sp)
    80001f40:	f022                	sd	s0,32(sp)
    80001f42:	ec26                	sd	s1,24(sp)
    80001f44:	e84a                	sd	s2,16(sp)
    80001f46:	e44e                	sd	s3,8(sp)
    80001f48:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f4a:	00000097          	auipc	ra,0x0
    80001f4e:	a5c080e7          	jalr	-1444(ra) # 800019a6 <myproc>
    80001f52:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	c04080e7          	jalr	-1020(ra) # 80000b58 <holding>
    80001f5c:	c93d                	beqz	a0,80001fd2 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f5e:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001f60:	2781                	sext.w	a5,a5
    80001f62:	079e                	slli	a5,a5,0x7
    80001f64:	0000f717          	auipc	a4,0xf
    80001f68:	c9c70713          	addi	a4,a4,-868 # 80010c00 <pid_lock>
    80001f6c:	97ba                	add	a5,a5,a4
    80001f6e:	0a87a703          	lw	a4,168(a5)
    80001f72:	4785                	li	a5,1
    80001f74:	06f71763          	bne	a4,a5,80001fe2 <sched+0xa6>
  if (p->state == RUNNING)
    80001f78:	4c98                	lw	a4,24(s1)
    80001f7a:	4791                	li	a5,4
    80001f7c:	06f70b63          	beq	a4,a5,80001ff2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f80:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f84:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001f86:	efb5                	bnez	a5,80002002 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f88:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f8a:	0000f917          	auipc	s2,0xf
    80001f8e:	c7690913          	addi	s2,s2,-906 # 80010c00 <pid_lock>
    80001f92:	2781                	sext.w	a5,a5
    80001f94:	079e                	slli	a5,a5,0x7
    80001f96:	97ca                	add	a5,a5,s2
    80001f98:	0ac7a983          	lw	s3,172(a5)
    80001f9c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f9e:	2781                	sext.w	a5,a5
    80001fa0:	079e                	slli	a5,a5,0x7
    80001fa2:	0000f597          	auipc	a1,0xf
    80001fa6:	c9658593          	addi	a1,a1,-874 # 80010c38 <cpus+0x8>
    80001faa:	95be                	add	a1,a1,a5
    80001fac:	06048513          	addi	a0,s1,96
    80001fb0:	00000097          	auipc	ra,0x0
    80001fb4:	66e080e7          	jalr	1646(ra) # 8000261e <swtch>
    80001fb8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fba:	2781                	sext.w	a5,a5
    80001fbc:	079e                	slli	a5,a5,0x7
    80001fbe:	993e                	add	s2,s2,a5
    80001fc0:	0b392623          	sw	s3,172(s2)
}
    80001fc4:	70a2                	ld	ra,40(sp)
    80001fc6:	7402                	ld	s0,32(sp)
    80001fc8:	64e2                	ld	s1,24(sp)
    80001fca:	6942                	ld	s2,16(sp)
    80001fcc:	69a2                	ld	s3,8(sp)
    80001fce:	6145                	addi	sp,sp,48
    80001fd0:	8082                	ret
    panic("sched p->lock");
    80001fd2:	00006517          	auipc	a0,0x6
    80001fd6:	24650513          	addi	a0,a0,582 # 80008218 <digits+0x1d8>
    80001fda:	ffffe097          	auipc	ra,0xffffe
    80001fde:	562080e7          	jalr	1378(ra) # 8000053c <panic>
    panic("sched locks");
    80001fe2:	00006517          	auipc	a0,0x6
    80001fe6:	24650513          	addi	a0,a0,582 # 80008228 <digits+0x1e8>
    80001fea:	ffffe097          	auipc	ra,0xffffe
    80001fee:	552080e7          	jalr	1362(ra) # 8000053c <panic>
    panic("sched running");
    80001ff2:	00006517          	auipc	a0,0x6
    80001ff6:	24650513          	addi	a0,a0,582 # 80008238 <digits+0x1f8>
    80001ffa:	ffffe097          	auipc	ra,0xffffe
    80001ffe:	542080e7          	jalr	1346(ra) # 8000053c <panic>
    panic("sched interruptible");
    80002002:	00006517          	auipc	a0,0x6
    80002006:	24650513          	addi	a0,a0,582 # 80008248 <digits+0x208>
    8000200a:	ffffe097          	auipc	ra,0xffffe
    8000200e:	532080e7          	jalr	1330(ra) # 8000053c <panic>

0000000080002012 <yield>:
{
    80002012:	1101                	addi	sp,sp,-32
    80002014:	ec06                	sd	ra,24(sp)
    80002016:	e822                	sd	s0,16(sp)
    80002018:	e426                	sd	s1,8(sp)
    8000201a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000201c:	00000097          	auipc	ra,0x0
    80002020:	98a080e7          	jalr	-1654(ra) # 800019a6 <myproc>
    80002024:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002026:	fffff097          	auipc	ra,0xfffff
    8000202a:	bac080e7          	jalr	-1108(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    8000202e:	478d                	li	a5,3
    80002030:	cc9c                	sw	a5,24(s1)
  sched();
    80002032:	00000097          	auipc	ra,0x0
    80002036:	f0a080e7          	jalr	-246(ra) # 80001f3c <sched>
  release(&p->lock);
    8000203a:	8526                	mv	a0,s1
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	c4a080e7          	jalr	-950(ra) # 80000c86 <release>
}
    80002044:	60e2                	ld	ra,24(sp)
    80002046:	6442                	ld	s0,16(sp)
    80002048:	64a2                	ld	s1,8(sp)
    8000204a:	6105                	addi	sp,sp,32
    8000204c:	8082                	ret

000000008000204e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000204e:	7179                	addi	sp,sp,-48
    80002050:	f406                	sd	ra,40(sp)
    80002052:	f022                	sd	s0,32(sp)
    80002054:	ec26                	sd	s1,24(sp)
    80002056:	e84a                	sd	s2,16(sp)
    80002058:	e44e                	sd	s3,8(sp)
    8000205a:	1800                	addi	s0,sp,48
    8000205c:	89aa                	mv	s3,a0
    8000205e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002060:	00000097          	auipc	ra,0x0
    80002064:	946080e7          	jalr	-1722(ra) # 800019a6 <myproc>
    80002068:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	b68080e7          	jalr	-1176(ra) # 80000bd2 <acquire>
  release(lk);
    80002072:	854a                	mv	a0,s2
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	c12080e7          	jalr	-1006(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    8000207c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002080:	4789                	li	a5,2
    80002082:	cc9c                	sw	a5,24(s1)

  sched();
    80002084:	00000097          	auipc	ra,0x0
    80002088:	eb8080e7          	jalr	-328(ra) # 80001f3c <sched>

  // Tidy up.
  p->chan = 0;
    8000208c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002090:	8526                	mv	a0,s1
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	bf4080e7          	jalr	-1036(ra) # 80000c86 <release>
  acquire(lk);
    8000209a:	854a                	mv	a0,s2
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	b36080e7          	jalr	-1226(ra) # 80000bd2 <acquire>
}
    800020a4:	70a2                	ld	ra,40(sp)
    800020a6:	7402                	ld	s0,32(sp)
    800020a8:	64e2                	ld	s1,24(sp)
    800020aa:	6942                	ld	s2,16(sp)
    800020ac:	69a2                	ld	s3,8(sp)
    800020ae:	6145                	addi	sp,sp,48
    800020b0:	8082                	ret

00000000800020b2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800020b2:	7139                	addi	sp,sp,-64
    800020b4:	fc06                	sd	ra,56(sp)
    800020b6:	f822                	sd	s0,48(sp)
    800020b8:	f426                	sd	s1,40(sp)
    800020ba:	f04a                	sd	s2,32(sp)
    800020bc:	ec4e                	sd	s3,24(sp)
    800020be:	e852                	sd	s4,16(sp)
    800020c0:	e456                	sd	s5,8(sp)
    800020c2:	0080                	addi	s0,sp,64
    800020c4:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800020c6:	0000f497          	auipc	s1,0xf
    800020ca:	f6a48493          	addi	s1,s1,-150 # 80011030 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800020ce:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800020d0:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800020d2:	00015917          	auipc	s2,0x15
    800020d6:	95e90913          	addi	s2,s2,-1698 # 80016a30 <tickslock>
    800020da:	a811                	j	800020ee <wakeup+0x3c>
      }
      release(&p->lock);
    800020dc:	8526                	mv	a0,s1
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	ba8080e7          	jalr	-1112(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800020e6:	16848493          	addi	s1,s1,360
    800020ea:	03248663          	beq	s1,s2,80002116 <wakeup+0x64>
    if (p != myproc())
    800020ee:	00000097          	auipc	ra,0x0
    800020f2:	8b8080e7          	jalr	-1864(ra) # 800019a6 <myproc>
    800020f6:	fea488e3          	beq	s1,a0,800020e6 <wakeup+0x34>
      acquire(&p->lock);
    800020fa:	8526                	mv	a0,s1
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	ad6080e7          	jalr	-1322(ra) # 80000bd2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002104:	4c9c                	lw	a5,24(s1)
    80002106:	fd379be3          	bne	a5,s3,800020dc <wakeup+0x2a>
    8000210a:	709c                	ld	a5,32(s1)
    8000210c:	fd4798e3          	bne	a5,s4,800020dc <wakeup+0x2a>
        p->state = RUNNABLE;
    80002110:	0154ac23          	sw	s5,24(s1)
    80002114:	b7e1                	j	800020dc <wakeup+0x2a>
    }
  }
}
    80002116:	70e2                	ld	ra,56(sp)
    80002118:	7442                	ld	s0,48(sp)
    8000211a:	74a2                	ld	s1,40(sp)
    8000211c:	7902                	ld	s2,32(sp)
    8000211e:	69e2                	ld	s3,24(sp)
    80002120:	6a42                	ld	s4,16(sp)
    80002122:	6aa2                	ld	s5,8(sp)
    80002124:	6121                	addi	sp,sp,64
    80002126:	8082                	ret

0000000080002128 <reparent>:
{
    80002128:	7179                	addi	sp,sp,-48
    8000212a:	f406                	sd	ra,40(sp)
    8000212c:	f022                	sd	s0,32(sp)
    8000212e:	ec26                	sd	s1,24(sp)
    80002130:	e84a                	sd	s2,16(sp)
    80002132:	e44e                	sd	s3,8(sp)
    80002134:	e052                	sd	s4,0(sp)
    80002136:	1800                	addi	s0,sp,48
    80002138:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000213a:	0000f497          	auipc	s1,0xf
    8000213e:	ef648493          	addi	s1,s1,-266 # 80011030 <proc>
      pp->parent = initproc;
    80002142:	00007a17          	auipc	s4,0x7
    80002146:	846a0a13          	addi	s4,s4,-1978 # 80008988 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000214a:	00015997          	auipc	s3,0x15
    8000214e:	8e698993          	addi	s3,s3,-1818 # 80016a30 <tickslock>
    80002152:	a029                	j	8000215c <reparent+0x34>
    80002154:	16848493          	addi	s1,s1,360
    80002158:	01348d63          	beq	s1,s3,80002172 <reparent+0x4a>
    if (pp->parent == p)
    8000215c:	7c9c                	ld	a5,56(s1)
    8000215e:	ff279be3          	bne	a5,s2,80002154 <reparent+0x2c>
      pp->parent = initproc;
    80002162:	000a3503          	ld	a0,0(s4)
    80002166:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002168:	00000097          	auipc	ra,0x0
    8000216c:	f4a080e7          	jalr	-182(ra) # 800020b2 <wakeup>
    80002170:	b7d5                	j	80002154 <reparent+0x2c>
}
    80002172:	70a2                	ld	ra,40(sp)
    80002174:	7402                	ld	s0,32(sp)
    80002176:	64e2                	ld	s1,24(sp)
    80002178:	6942                	ld	s2,16(sp)
    8000217a:	69a2                	ld	s3,8(sp)
    8000217c:	6a02                	ld	s4,0(sp)
    8000217e:	6145                	addi	sp,sp,48
    80002180:	8082                	ret

0000000080002182 <exit>:
{
    80002182:	7179                	addi	sp,sp,-48
    80002184:	f406                	sd	ra,40(sp)
    80002186:	f022                	sd	s0,32(sp)
    80002188:	ec26                	sd	s1,24(sp)
    8000218a:	e84a                	sd	s2,16(sp)
    8000218c:	e44e                	sd	s3,8(sp)
    8000218e:	e052                	sd	s4,0(sp)
    80002190:	1800                	addi	s0,sp,48
    80002192:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002194:	00000097          	auipc	ra,0x0
    80002198:	812080e7          	jalr	-2030(ra) # 800019a6 <myproc>
    8000219c:	89aa                	mv	s3,a0
  if (p == initproc)
    8000219e:	00006797          	auipc	a5,0x6
    800021a2:	7ea7b783          	ld	a5,2026(a5) # 80008988 <initproc>
    800021a6:	0d050493          	addi	s1,a0,208
    800021aa:	15050913          	addi	s2,a0,336
    800021ae:	02a79363          	bne	a5,a0,800021d4 <exit+0x52>
    panic("init exiting");
    800021b2:	00006517          	auipc	a0,0x6
    800021b6:	0ae50513          	addi	a0,a0,174 # 80008260 <digits+0x220>
    800021ba:	ffffe097          	auipc	ra,0xffffe
    800021be:	382080e7          	jalr	898(ra) # 8000053c <panic>
      fileclose(f);
    800021c2:	00002097          	auipc	ra,0x2
    800021c6:	410080e7          	jalr	1040(ra) # 800045d2 <fileclose>
      p->ofile[fd] = 0;
    800021ca:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800021ce:	04a1                	addi	s1,s1,8
    800021d0:	01248563          	beq	s1,s2,800021da <exit+0x58>
    if (p->ofile[fd])
    800021d4:	6088                	ld	a0,0(s1)
    800021d6:	f575                	bnez	a0,800021c2 <exit+0x40>
    800021d8:	bfdd                	j	800021ce <exit+0x4c>
  begin_op();
    800021da:	00002097          	auipc	ra,0x2
    800021de:	f34080e7          	jalr	-204(ra) # 8000410e <begin_op>
  iput(p->cwd);
    800021e2:	1509b503          	ld	a0,336(s3)
    800021e6:	00001097          	auipc	ra,0x1
    800021ea:	73c080e7          	jalr	1852(ra) # 80003922 <iput>
  end_op();
    800021ee:	00002097          	auipc	ra,0x2
    800021f2:	f9a080e7          	jalr	-102(ra) # 80004188 <end_op>
  p->cwd = 0;
    800021f6:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800021fa:	0000f497          	auipc	s1,0xf
    800021fe:	a1e48493          	addi	s1,s1,-1506 # 80010c18 <wait_lock>
    80002202:	8526                	mv	a0,s1
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	9ce080e7          	jalr	-1586(ra) # 80000bd2 <acquire>
  reparent(p);
    8000220c:	854e                	mv	a0,s3
    8000220e:	00000097          	auipc	ra,0x0
    80002212:	f1a080e7          	jalr	-230(ra) # 80002128 <reparent>
  wakeup(p->parent);
    80002216:	0389b503          	ld	a0,56(s3)
    8000221a:	00000097          	auipc	ra,0x0
    8000221e:	e98080e7          	jalr	-360(ra) # 800020b2 <wakeup>
  acquire(&p->lock);
    80002222:	854e                	mv	a0,s3
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	9ae080e7          	jalr	-1618(ra) # 80000bd2 <acquire>
  p->xstate = status;
    8000222c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002230:	4795                	li	a5,5
    80002232:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002236:	8526                	mv	a0,s1
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	a4e080e7          	jalr	-1458(ra) # 80000c86 <release>
  sched();
    80002240:	00000097          	auipc	ra,0x0
    80002244:	cfc080e7          	jalr	-772(ra) # 80001f3c <sched>
  panic("zombie exit");
    80002248:	00006517          	auipc	a0,0x6
    8000224c:	02850513          	addi	a0,a0,40 # 80008270 <digits+0x230>
    80002250:	ffffe097          	auipc	ra,0xffffe
    80002254:	2ec080e7          	jalr	748(ra) # 8000053c <panic>

0000000080002258 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002258:	7179                	addi	sp,sp,-48
    8000225a:	f406                	sd	ra,40(sp)
    8000225c:	f022                	sd	s0,32(sp)
    8000225e:	ec26                	sd	s1,24(sp)
    80002260:	e84a                	sd	s2,16(sp)
    80002262:	e44e                	sd	s3,8(sp)
    80002264:	1800                	addi	s0,sp,48
    80002266:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002268:	0000f497          	auipc	s1,0xf
    8000226c:	dc848493          	addi	s1,s1,-568 # 80011030 <proc>
    80002270:	00014997          	auipc	s3,0x14
    80002274:	7c098993          	addi	s3,s3,1984 # 80016a30 <tickslock>
  {
    acquire(&p->lock);
    80002278:	8526                	mv	a0,s1
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	958080e7          	jalr	-1704(ra) # 80000bd2 <acquire>
    if (p->pid == pid)
    80002282:	589c                	lw	a5,48(s1)
    80002284:	01278d63          	beq	a5,s2,8000229e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002288:	8526                	mv	a0,s1
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	9fc080e7          	jalr	-1540(ra) # 80000c86 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002292:	16848493          	addi	s1,s1,360
    80002296:	ff3491e3          	bne	s1,s3,80002278 <kill+0x20>
  }
  return -1;
    8000229a:	557d                	li	a0,-1
    8000229c:	a829                	j	800022b6 <kill+0x5e>
      p->killed = 1;
    8000229e:	4785                	li	a5,1
    800022a0:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800022a2:	4c98                	lw	a4,24(s1)
    800022a4:	4789                	li	a5,2
    800022a6:	00f70f63          	beq	a4,a5,800022c4 <kill+0x6c>
      release(&p->lock);
    800022aa:	8526                	mv	a0,s1
    800022ac:	fffff097          	auipc	ra,0xfffff
    800022b0:	9da080e7          	jalr	-1574(ra) # 80000c86 <release>
      return 0;
    800022b4:	4501                	li	a0,0
}
    800022b6:	70a2                	ld	ra,40(sp)
    800022b8:	7402                	ld	s0,32(sp)
    800022ba:	64e2                	ld	s1,24(sp)
    800022bc:	6942                	ld	s2,16(sp)
    800022be:	69a2                	ld	s3,8(sp)
    800022c0:	6145                	addi	sp,sp,48
    800022c2:	8082                	ret
        p->state = RUNNABLE;
    800022c4:	478d                	li	a5,3
    800022c6:	cc9c                	sw	a5,24(s1)
    800022c8:	b7cd                	j	800022aa <kill+0x52>

00000000800022ca <setkilled>:

void setkilled(struct proc *p)
{
    800022ca:	1101                	addi	sp,sp,-32
    800022cc:	ec06                	sd	ra,24(sp)
    800022ce:	e822                	sd	s0,16(sp)
    800022d0:	e426                	sd	s1,8(sp)
    800022d2:	1000                	addi	s0,sp,32
    800022d4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	8fc080e7          	jalr	-1796(ra) # 80000bd2 <acquire>
  p->killed = 1;
    800022de:	4785                	li	a5,1
    800022e0:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022e2:	8526                	mv	a0,s1
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	9a2080e7          	jalr	-1630(ra) # 80000c86 <release>
}
    800022ec:	60e2                	ld	ra,24(sp)
    800022ee:	6442                	ld	s0,16(sp)
    800022f0:	64a2                	ld	s1,8(sp)
    800022f2:	6105                	addi	sp,sp,32
    800022f4:	8082                	ret

00000000800022f6 <killed>:

int killed(struct proc *p)
{
    800022f6:	1101                	addi	sp,sp,-32
    800022f8:	ec06                	sd	ra,24(sp)
    800022fa:	e822                	sd	s0,16(sp)
    800022fc:	e426                	sd	s1,8(sp)
    800022fe:	e04a                	sd	s2,0(sp)
    80002300:	1000                	addi	s0,sp,32
    80002302:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	8ce080e7          	jalr	-1842(ra) # 80000bd2 <acquire>
  k = p->killed;
    8000230c:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002310:	8526                	mv	a0,s1
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	974080e7          	jalr	-1676(ra) # 80000c86 <release>
  return k;
}
    8000231a:	854a                	mv	a0,s2
    8000231c:	60e2                	ld	ra,24(sp)
    8000231e:	6442                	ld	s0,16(sp)
    80002320:	64a2                	ld	s1,8(sp)
    80002322:	6902                	ld	s2,0(sp)
    80002324:	6105                	addi	sp,sp,32
    80002326:	8082                	ret

0000000080002328 <wait>:
{
    80002328:	715d                	addi	sp,sp,-80
    8000232a:	e486                	sd	ra,72(sp)
    8000232c:	e0a2                	sd	s0,64(sp)
    8000232e:	fc26                	sd	s1,56(sp)
    80002330:	f84a                	sd	s2,48(sp)
    80002332:	f44e                	sd	s3,40(sp)
    80002334:	f052                	sd	s4,32(sp)
    80002336:	ec56                	sd	s5,24(sp)
    80002338:	e85a                	sd	s6,16(sp)
    8000233a:	e45e                	sd	s7,8(sp)
    8000233c:	e062                	sd	s8,0(sp)
    8000233e:	0880                	addi	s0,sp,80
    80002340:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	664080e7          	jalr	1636(ra) # 800019a6 <myproc>
    8000234a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000234c:	0000f517          	auipc	a0,0xf
    80002350:	8cc50513          	addi	a0,a0,-1844 # 80010c18 <wait_lock>
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	87e080e7          	jalr	-1922(ra) # 80000bd2 <acquire>
    havekids = 0;
    8000235c:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    8000235e:	4a15                	li	s4,5
        havekids = 1;
    80002360:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002362:	00014997          	auipc	s3,0x14
    80002366:	6ce98993          	addi	s3,s3,1742 # 80016a30 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000236a:	0000fc17          	auipc	s8,0xf
    8000236e:	8aec0c13          	addi	s8,s8,-1874 # 80010c18 <wait_lock>
    80002372:	a0d1                	j	80002436 <wait+0x10e>
          pid = pp->pid;
    80002374:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002378:	000b0e63          	beqz	s6,80002394 <wait+0x6c>
    8000237c:	4691                	li	a3,4
    8000237e:	02c48613          	addi	a2,s1,44
    80002382:	85da                	mv	a1,s6
    80002384:	05093503          	ld	a0,80(s2)
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	2de080e7          	jalr	734(ra) # 80001666 <copyout>
    80002390:	04054163          	bltz	a0,800023d2 <wait+0xaa>
          freeproc(pp);
    80002394:	8526                	mv	a0,s1
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	7c2080e7          	jalr	1986(ra) # 80001b58 <freeproc>
          release(&pp->lock);
    8000239e:	8526                	mv	a0,s1
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	8e6080e7          	jalr	-1818(ra) # 80000c86 <release>
          release(&wait_lock);
    800023a8:	0000f517          	auipc	a0,0xf
    800023ac:	87050513          	addi	a0,a0,-1936 # 80010c18 <wait_lock>
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8d6080e7          	jalr	-1834(ra) # 80000c86 <release>
}
    800023b8:	854e                	mv	a0,s3
    800023ba:	60a6                	ld	ra,72(sp)
    800023bc:	6406                	ld	s0,64(sp)
    800023be:	74e2                	ld	s1,56(sp)
    800023c0:	7942                	ld	s2,48(sp)
    800023c2:	79a2                	ld	s3,40(sp)
    800023c4:	7a02                	ld	s4,32(sp)
    800023c6:	6ae2                	ld	s5,24(sp)
    800023c8:	6b42                	ld	s6,16(sp)
    800023ca:	6ba2                	ld	s7,8(sp)
    800023cc:	6c02                	ld	s8,0(sp)
    800023ce:	6161                	addi	sp,sp,80
    800023d0:	8082                	ret
            release(&pp->lock);
    800023d2:	8526                	mv	a0,s1
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	8b2080e7          	jalr	-1870(ra) # 80000c86 <release>
            release(&wait_lock);
    800023dc:	0000f517          	auipc	a0,0xf
    800023e0:	83c50513          	addi	a0,a0,-1988 # 80010c18 <wait_lock>
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	8a2080e7          	jalr	-1886(ra) # 80000c86 <release>
            return -1;
    800023ec:	59fd                	li	s3,-1
    800023ee:	b7e9                	j	800023b8 <wait+0x90>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023f0:	16848493          	addi	s1,s1,360
    800023f4:	03348463          	beq	s1,s3,8000241c <wait+0xf4>
      if (pp->parent == p)
    800023f8:	7c9c                	ld	a5,56(s1)
    800023fa:	ff279be3          	bne	a5,s2,800023f0 <wait+0xc8>
        acquire(&pp->lock);
    800023fe:	8526                	mv	a0,s1
    80002400:	ffffe097          	auipc	ra,0xffffe
    80002404:	7d2080e7          	jalr	2002(ra) # 80000bd2 <acquire>
        if (pp->state == ZOMBIE)
    80002408:	4c9c                	lw	a5,24(s1)
    8000240a:	f74785e3          	beq	a5,s4,80002374 <wait+0x4c>
        release(&pp->lock);
    8000240e:	8526                	mv	a0,s1
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	876080e7          	jalr	-1930(ra) # 80000c86 <release>
        havekids = 1;
    80002418:	8756                	mv	a4,s5
    8000241a:	bfd9                	j	800023f0 <wait+0xc8>
    if (!havekids || killed(p))
    8000241c:	c31d                	beqz	a4,80002442 <wait+0x11a>
    8000241e:	854a                	mv	a0,s2
    80002420:	00000097          	auipc	ra,0x0
    80002424:	ed6080e7          	jalr	-298(ra) # 800022f6 <killed>
    80002428:	ed09                	bnez	a0,80002442 <wait+0x11a>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000242a:	85e2                	mv	a1,s8
    8000242c:	854a                	mv	a0,s2
    8000242e:	00000097          	auipc	ra,0x0
    80002432:	c20080e7          	jalr	-992(ra) # 8000204e <sleep>
    havekids = 0;
    80002436:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002438:	0000f497          	auipc	s1,0xf
    8000243c:	bf848493          	addi	s1,s1,-1032 # 80011030 <proc>
    80002440:	bf65                	j	800023f8 <wait+0xd0>
      release(&wait_lock);
    80002442:	0000e517          	auipc	a0,0xe
    80002446:	7d650513          	addi	a0,a0,2006 # 80010c18 <wait_lock>
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	83c080e7          	jalr	-1988(ra) # 80000c86 <release>
      return -1;
    80002452:	59fd                	li	s3,-1
    80002454:	b795                	j	800023b8 <wait+0x90>

0000000080002456 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002456:	7179                	addi	sp,sp,-48
    80002458:	f406                	sd	ra,40(sp)
    8000245a:	f022                	sd	s0,32(sp)
    8000245c:	ec26                	sd	s1,24(sp)
    8000245e:	e84a                	sd	s2,16(sp)
    80002460:	e44e                	sd	s3,8(sp)
    80002462:	e052                	sd	s4,0(sp)
    80002464:	1800                	addi	s0,sp,48
    80002466:	84aa                	mv	s1,a0
    80002468:	892e                	mv	s2,a1
    8000246a:	89b2                	mv	s3,a2
    8000246c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	538080e7          	jalr	1336(ra) # 800019a6 <myproc>
  if (user_dst)
    80002476:	c08d                	beqz	s1,80002498 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002478:	86d2                	mv	a3,s4
    8000247a:	864e                	mv	a2,s3
    8000247c:	85ca                	mv	a1,s2
    8000247e:	6928                	ld	a0,80(a0)
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	1e6080e7          	jalr	486(ra) # 80001666 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002488:	70a2                	ld	ra,40(sp)
    8000248a:	7402                	ld	s0,32(sp)
    8000248c:	64e2                	ld	s1,24(sp)
    8000248e:	6942                	ld	s2,16(sp)
    80002490:	69a2                	ld	s3,8(sp)
    80002492:	6a02                	ld	s4,0(sp)
    80002494:	6145                	addi	sp,sp,48
    80002496:	8082                	ret
    memmove((char *)dst, src, len);
    80002498:	000a061b          	sext.w	a2,s4
    8000249c:	85ce                	mv	a1,s3
    8000249e:	854a                	mv	a0,s2
    800024a0:	fffff097          	auipc	ra,0xfffff
    800024a4:	88a080e7          	jalr	-1910(ra) # 80000d2a <memmove>
    return 0;
    800024a8:	8526                	mv	a0,s1
    800024aa:	bff9                	j	80002488 <either_copyout+0x32>

00000000800024ac <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024ac:	7179                	addi	sp,sp,-48
    800024ae:	f406                	sd	ra,40(sp)
    800024b0:	f022                	sd	s0,32(sp)
    800024b2:	ec26                	sd	s1,24(sp)
    800024b4:	e84a                	sd	s2,16(sp)
    800024b6:	e44e                	sd	s3,8(sp)
    800024b8:	e052                	sd	s4,0(sp)
    800024ba:	1800                	addi	s0,sp,48
    800024bc:	892a                	mv	s2,a0
    800024be:	84ae                	mv	s1,a1
    800024c0:	89b2                	mv	s3,a2
    800024c2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c4:	fffff097          	auipc	ra,0xfffff
    800024c8:	4e2080e7          	jalr	1250(ra) # 800019a6 <myproc>
  if (user_src)
    800024cc:	c08d                	beqz	s1,800024ee <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800024ce:	86d2                	mv	a3,s4
    800024d0:	864e                	mv	a2,s3
    800024d2:	85ca                	mv	a1,s2
    800024d4:	6928                	ld	a0,80(a0)
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	21c080e7          	jalr	540(ra) # 800016f2 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800024de:	70a2                	ld	ra,40(sp)
    800024e0:	7402                	ld	s0,32(sp)
    800024e2:	64e2                	ld	s1,24(sp)
    800024e4:	6942                	ld	s2,16(sp)
    800024e6:	69a2                	ld	s3,8(sp)
    800024e8:	6a02                	ld	s4,0(sp)
    800024ea:	6145                	addi	sp,sp,48
    800024ec:	8082                	ret
    memmove(dst, (char *)src, len);
    800024ee:	000a061b          	sext.w	a2,s4
    800024f2:	85ce                	mv	a1,s3
    800024f4:	854a                	mv	a0,s2
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	834080e7          	jalr	-1996(ra) # 80000d2a <memmove>
    return 0;
    800024fe:	8526                	mv	a0,s1
    80002500:	bff9                	j	800024de <either_copyin+0x32>

0000000080002502 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002502:	715d                	addi	sp,sp,-80
    80002504:	e486                	sd	ra,72(sp)
    80002506:	e0a2                	sd	s0,64(sp)
    80002508:	fc26                	sd	s1,56(sp)
    8000250a:	f84a                	sd	s2,48(sp)
    8000250c:	f44e                	sd	s3,40(sp)
    8000250e:	f052                	sd	s4,32(sp)
    80002510:	ec56                	sd	s5,24(sp)
    80002512:	e85a                	sd	s6,16(sp)
    80002514:	e45e                	sd	s7,8(sp)
    80002516:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002518:	00006517          	auipc	a0,0x6
    8000251c:	bb050513          	addi	a0,a0,-1104 # 800080c8 <digits+0x88>
    80002520:	ffffe097          	auipc	ra,0xffffe
    80002524:	066080e7          	jalr	102(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002528:	0000f497          	auipc	s1,0xf
    8000252c:	c6048493          	addi	s1,s1,-928 # 80011188 <proc+0x158>
    80002530:	00014917          	auipc	s2,0x14
    80002534:	65890913          	addi	s2,s2,1624 # 80016b88 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002538:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000253a:	00006997          	auipc	s3,0x6
    8000253e:	d4698993          	addi	s3,s3,-698 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002542:	00006a97          	auipc	s5,0x6
    80002546:	d46a8a93          	addi	s5,s5,-698 # 80008288 <digits+0x248>
    printf("\n");
    8000254a:	00006a17          	auipc	s4,0x6
    8000254e:	b7ea0a13          	addi	s4,s4,-1154 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002552:	00006b97          	auipc	s7,0x6
    80002556:	d86b8b93          	addi	s7,s7,-634 # 800082d8 <states.0>
    8000255a:	a00d                	j	8000257c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000255c:	ed86a583          	lw	a1,-296(a3)
    80002560:	8556                	mv	a0,s5
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	024080e7          	jalr	36(ra) # 80000586 <printf>
    printf("\n");
    8000256a:	8552                	mv	a0,s4
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	01a080e7          	jalr	26(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002574:	16848493          	addi	s1,s1,360
    80002578:	03248263          	beq	s1,s2,8000259c <procdump+0x9a>
    if (p->state == UNUSED)
    8000257c:	86a6                	mv	a3,s1
    8000257e:	ec04a783          	lw	a5,-320(s1)
    80002582:	dbed                	beqz	a5,80002574 <procdump+0x72>
      state = "???";
    80002584:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002586:	fcfb6be3          	bltu	s6,a5,8000255c <procdump+0x5a>
    8000258a:	02079713          	slli	a4,a5,0x20
    8000258e:	01d75793          	srli	a5,a4,0x1d
    80002592:	97de                	add	a5,a5,s7
    80002594:	6390                	ld	a2,0(a5)
    80002596:	f279                	bnez	a2,8000255c <procdump+0x5a>
      state = "???";
    80002598:	864e                	mv	a2,s3
    8000259a:	b7c9                	j	8000255c <procdump+0x5a>
  }
}
    8000259c:	60a6                	ld	ra,72(sp)
    8000259e:	6406                	ld	s0,64(sp)
    800025a0:	74e2                	ld	s1,56(sp)
    800025a2:	7942                	ld	s2,48(sp)
    800025a4:	79a2                	ld	s3,40(sp)
    800025a6:	7a02                	ld	s4,32(sp)
    800025a8:	6ae2                	ld	s5,24(sp)
    800025aa:	6b42                	ld	s6,16(sp)
    800025ac:	6ba2                	ld	s7,8(sp)
    800025ae:	6161                	addi	sp,sp,80
    800025b0:	8082                	ret

00000000800025b2 <proctest>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
// Similar to procdump, but with other syntaxing when printing.
void proctest(void)
{
    800025b2:	7179                	addi	sp,sp,-48
    800025b4:	f406                	sd	ra,40(sp)
    800025b6:	f022                	sd	s0,32(sp)
    800025b8:	ec26                	sd	s1,24(sp)
    800025ba:	e84a                	sd	s2,16(sp)
    800025bc:	e44e                	sd	s3,8(sp)
    800025be:	e052                	sd	s4,0(sp)
    800025c0:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    800025c2:	0000f497          	auipc	s1,0xf
    800025c6:	bc648493          	addi	s1,s1,-1082 # 80011188 <proc+0x158>
    800025ca:	00014917          	auipc	s2,0x14
    800025ce:	5be90913          	addi	s2,s2,1470 # 80016b88 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    printf("%s (%d): %d", p->name, p->pid, p->state);
    800025d2:	00006a17          	auipc	s4,0x6
    800025d6:	cc6a0a13          	addi	s4,s4,-826 # 80008298 <digits+0x258>
    printf("\n");
    800025da:	00006997          	auipc	s3,0x6
    800025de:	aee98993          	addi	s3,s3,-1298 # 800080c8 <digits+0x88>
    800025e2:	a029                	j	800025ec <proctest+0x3a>
  for (p = proc; p < &proc[NPROC]; p++)
    800025e4:	16848493          	addi	s1,s1,360
    800025e8:	03248363          	beq	s1,s2,8000260e <proctest+0x5c>
    if (p->state == UNUSED)
    800025ec:	ec04a683          	lw	a3,-320(s1)
    800025f0:	daf5                	beqz	a3,800025e4 <proctest+0x32>
    printf("%s (%d): %d", p->name, p->pid, p->state);
    800025f2:	ed84a603          	lw	a2,-296(s1)
    800025f6:	85a6                	mv	a1,s1
    800025f8:	8552                	mv	a0,s4
    800025fa:	ffffe097          	auipc	ra,0xffffe
    800025fe:	f8c080e7          	jalr	-116(ra) # 80000586 <printf>
    printf("\n");
    80002602:	854e                	mv	a0,s3
    80002604:	ffffe097          	auipc	ra,0xffffe
    80002608:	f82080e7          	jalr	-126(ra) # 80000586 <printf>
    8000260c:	bfe1                	j	800025e4 <proctest+0x32>
  }
}
    8000260e:	70a2                	ld	ra,40(sp)
    80002610:	7402                	ld	s0,32(sp)
    80002612:	64e2                	ld	s1,24(sp)
    80002614:	6942                	ld	s2,16(sp)
    80002616:	69a2                	ld	s3,8(sp)
    80002618:	6a02                	ld	s4,0(sp)
    8000261a:	6145                	addi	sp,sp,48
    8000261c:	8082                	ret

000000008000261e <swtch>:
    8000261e:	00153023          	sd	ra,0(a0)
    80002622:	00253423          	sd	sp,8(a0)
    80002626:	e900                	sd	s0,16(a0)
    80002628:	ed04                	sd	s1,24(a0)
    8000262a:	03253023          	sd	s2,32(a0)
    8000262e:	03353423          	sd	s3,40(a0)
    80002632:	03453823          	sd	s4,48(a0)
    80002636:	03553c23          	sd	s5,56(a0)
    8000263a:	05653023          	sd	s6,64(a0)
    8000263e:	05753423          	sd	s7,72(a0)
    80002642:	05853823          	sd	s8,80(a0)
    80002646:	05953c23          	sd	s9,88(a0)
    8000264a:	07a53023          	sd	s10,96(a0)
    8000264e:	07b53423          	sd	s11,104(a0)
    80002652:	0005b083          	ld	ra,0(a1)
    80002656:	0085b103          	ld	sp,8(a1)
    8000265a:	6980                	ld	s0,16(a1)
    8000265c:	6d84                	ld	s1,24(a1)
    8000265e:	0205b903          	ld	s2,32(a1)
    80002662:	0285b983          	ld	s3,40(a1)
    80002666:	0305ba03          	ld	s4,48(a1)
    8000266a:	0385ba83          	ld	s5,56(a1)
    8000266e:	0405bb03          	ld	s6,64(a1)
    80002672:	0485bb83          	ld	s7,72(a1)
    80002676:	0505bc03          	ld	s8,80(a1)
    8000267a:	0585bc83          	ld	s9,88(a1)
    8000267e:	0605bd03          	ld	s10,96(a1)
    80002682:	0685bd83          	ld	s11,104(a1)
    80002686:	8082                	ret

0000000080002688 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002688:	1141                	addi	sp,sp,-16
    8000268a:	e406                	sd	ra,8(sp)
    8000268c:	e022                	sd	s0,0(sp)
    8000268e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002690:	00006597          	auipc	a1,0x6
    80002694:	c7858593          	addi	a1,a1,-904 # 80008308 <states.0+0x30>
    80002698:	00014517          	auipc	a0,0x14
    8000269c:	39850513          	addi	a0,a0,920 # 80016a30 <tickslock>
    800026a0:	ffffe097          	auipc	ra,0xffffe
    800026a4:	4a2080e7          	jalr	1186(ra) # 80000b42 <initlock>
}
    800026a8:	60a2                	ld	ra,8(sp)
    800026aa:	6402                	ld	s0,0(sp)
    800026ac:	0141                	addi	sp,sp,16
    800026ae:	8082                	ret

00000000800026b0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026b0:	1141                	addi	sp,sp,-16
    800026b2:	e422                	sd	s0,8(sp)
    800026b4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026b6:	00003797          	auipc	a5,0x3
    800026ba:	54a78793          	addi	a5,a5,1354 # 80005c00 <kernelvec>
    800026be:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026c2:	6422                	ld	s0,8(sp)
    800026c4:	0141                	addi	sp,sp,16
    800026c6:	8082                	ret

00000000800026c8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026c8:	1141                	addi	sp,sp,-16
    800026ca:	e406                	sd	ra,8(sp)
    800026cc:	e022                	sd	s0,0(sp)
    800026ce:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026d0:	fffff097          	auipc	ra,0xfffff
    800026d4:	2d6080e7          	jalr	726(ra) # 800019a6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026d8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026dc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026de:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800026e2:	00005697          	auipc	a3,0x5
    800026e6:	91e68693          	addi	a3,a3,-1762 # 80007000 <_trampoline>
    800026ea:	00005717          	auipc	a4,0x5
    800026ee:	91670713          	addi	a4,a4,-1770 # 80007000 <_trampoline>
    800026f2:	8f15                	sub	a4,a4,a3
    800026f4:	040007b7          	lui	a5,0x4000
    800026f8:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800026fa:	07b2                	slli	a5,a5,0xc
    800026fc:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026fe:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002702:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002704:	18002673          	csrr	a2,satp
    80002708:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000270a:	6d30                	ld	a2,88(a0)
    8000270c:	6138                	ld	a4,64(a0)
    8000270e:	6585                	lui	a1,0x1
    80002710:	972e                	add	a4,a4,a1
    80002712:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002714:	6d38                	ld	a4,88(a0)
    80002716:	00000617          	auipc	a2,0x0
    8000271a:	13460613          	addi	a2,a2,308 # 8000284a <usertrap>
    8000271e:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002720:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002722:	8612                	mv	a2,tp
    80002724:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002726:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000272a:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000272e:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002732:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002736:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002738:	6f18                	ld	a4,24(a4)
    8000273a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000273e:	6928                	ld	a0,80(a0)
    80002740:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002742:	00005717          	auipc	a4,0x5
    80002746:	95a70713          	addi	a4,a4,-1702 # 8000709c <userret>
    8000274a:	8f15                	sub	a4,a4,a3
    8000274c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000274e:	577d                	li	a4,-1
    80002750:	177e                	slli	a4,a4,0x3f
    80002752:	8d59                	or	a0,a0,a4
    80002754:	9782                	jalr	a5
}
    80002756:	60a2                	ld	ra,8(sp)
    80002758:	6402                	ld	s0,0(sp)
    8000275a:	0141                	addi	sp,sp,16
    8000275c:	8082                	ret

000000008000275e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000275e:	1101                	addi	sp,sp,-32
    80002760:	ec06                	sd	ra,24(sp)
    80002762:	e822                	sd	s0,16(sp)
    80002764:	e426                	sd	s1,8(sp)
    80002766:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002768:	00014497          	auipc	s1,0x14
    8000276c:	2c848493          	addi	s1,s1,712 # 80016a30 <tickslock>
    80002770:	8526                	mv	a0,s1
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	460080e7          	jalr	1120(ra) # 80000bd2 <acquire>
  ticks++;
    8000277a:	00006517          	auipc	a0,0x6
    8000277e:	21650513          	addi	a0,a0,534 # 80008990 <ticks>
    80002782:	411c                	lw	a5,0(a0)
    80002784:	2785                	addiw	a5,a5,1
    80002786:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002788:	00000097          	auipc	ra,0x0
    8000278c:	92a080e7          	jalr	-1750(ra) # 800020b2 <wakeup>
  release(&tickslock);
    80002790:	8526                	mv	a0,s1
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	4f4080e7          	jalr	1268(ra) # 80000c86 <release>
}
    8000279a:	60e2                	ld	ra,24(sp)
    8000279c:	6442                	ld	s0,16(sp)
    8000279e:	64a2                	ld	s1,8(sp)
    800027a0:	6105                	addi	sp,sp,32
    800027a2:	8082                	ret

00000000800027a4 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027a4:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027a8:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    800027aa:	0807df63          	bgez	a5,80002848 <devintr+0xa4>
{
    800027ae:	1101                	addi	sp,sp,-32
    800027b0:	ec06                	sd	ra,24(sp)
    800027b2:	e822                	sd	s0,16(sp)
    800027b4:	e426                	sd	s1,8(sp)
    800027b6:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    800027b8:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    800027bc:	46a5                	li	a3,9
    800027be:	00d70d63          	beq	a4,a3,800027d8 <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    800027c2:	577d                	li	a4,-1
    800027c4:	177e                	slli	a4,a4,0x3f
    800027c6:	0705                	addi	a4,a4,1
    return 0;
    800027c8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027ca:	04e78e63          	beq	a5,a4,80002826 <devintr+0x82>
  }
}
    800027ce:	60e2                	ld	ra,24(sp)
    800027d0:	6442                	ld	s0,16(sp)
    800027d2:	64a2                	ld	s1,8(sp)
    800027d4:	6105                	addi	sp,sp,32
    800027d6:	8082                	ret
    int irq = plic_claim();
    800027d8:	00003097          	auipc	ra,0x3
    800027dc:	530080e7          	jalr	1328(ra) # 80005d08 <plic_claim>
    800027e0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027e2:	47a9                	li	a5,10
    800027e4:	02f50763          	beq	a0,a5,80002812 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    800027e8:	4785                	li	a5,1
    800027ea:	02f50963          	beq	a0,a5,8000281c <devintr+0x78>
    return 1;
    800027ee:	4505                	li	a0,1
    } else if(irq){
    800027f0:	dcf9                	beqz	s1,800027ce <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    800027f2:	85a6                	mv	a1,s1
    800027f4:	00006517          	auipc	a0,0x6
    800027f8:	b1c50513          	addi	a0,a0,-1252 # 80008310 <states.0+0x38>
    800027fc:	ffffe097          	auipc	ra,0xffffe
    80002800:	d8a080e7          	jalr	-630(ra) # 80000586 <printf>
      plic_complete(irq);
    80002804:	8526                	mv	a0,s1
    80002806:	00003097          	auipc	ra,0x3
    8000280a:	526080e7          	jalr	1318(ra) # 80005d2c <plic_complete>
    return 1;
    8000280e:	4505                	li	a0,1
    80002810:	bf7d                	j	800027ce <devintr+0x2a>
      uartintr();
    80002812:	ffffe097          	auipc	ra,0xffffe
    80002816:	182080e7          	jalr	386(ra) # 80000994 <uartintr>
    if(irq)
    8000281a:	b7ed                	j	80002804 <devintr+0x60>
      virtio_disk_intr();
    8000281c:	00004097          	auipc	ra,0x4
    80002820:	9d6080e7          	jalr	-1578(ra) # 800061f2 <virtio_disk_intr>
    if(irq)
    80002824:	b7c5                	j	80002804 <devintr+0x60>
    if(cpuid() == 0){
    80002826:	fffff097          	auipc	ra,0xfffff
    8000282a:	154080e7          	jalr	340(ra) # 8000197a <cpuid>
    8000282e:	c901                	beqz	a0,8000283e <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002830:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002834:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002836:	14479073          	csrw	sip,a5
    return 2;
    8000283a:	4509                	li	a0,2
    8000283c:	bf49                	j	800027ce <devintr+0x2a>
      clockintr();
    8000283e:	00000097          	auipc	ra,0x0
    80002842:	f20080e7          	jalr	-224(ra) # 8000275e <clockintr>
    80002846:	b7ed                	j	80002830 <devintr+0x8c>
}
    80002848:	8082                	ret

000000008000284a <usertrap>:
{
    8000284a:	1101                	addi	sp,sp,-32
    8000284c:	ec06                	sd	ra,24(sp)
    8000284e:	e822                	sd	s0,16(sp)
    80002850:	e426                	sd	s1,8(sp)
    80002852:	e04a                	sd	s2,0(sp)
    80002854:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002856:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000285a:	1007f793          	andi	a5,a5,256
    8000285e:	e3b1                	bnez	a5,800028a2 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002860:	00003797          	auipc	a5,0x3
    80002864:	3a078793          	addi	a5,a5,928 # 80005c00 <kernelvec>
    80002868:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000286c:	fffff097          	auipc	ra,0xfffff
    80002870:	13a080e7          	jalr	314(ra) # 800019a6 <myproc>
    80002874:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002876:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002878:	14102773          	csrr	a4,sepc
    8000287c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000287e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002882:	47a1                	li	a5,8
    80002884:	02f70763          	beq	a4,a5,800028b2 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002888:	00000097          	auipc	ra,0x0
    8000288c:	f1c080e7          	jalr	-228(ra) # 800027a4 <devintr>
    80002890:	892a                	mv	s2,a0
    80002892:	c151                	beqz	a0,80002916 <usertrap+0xcc>
  if(killed(p))
    80002894:	8526                	mv	a0,s1
    80002896:	00000097          	auipc	ra,0x0
    8000289a:	a60080e7          	jalr	-1440(ra) # 800022f6 <killed>
    8000289e:	c929                	beqz	a0,800028f0 <usertrap+0xa6>
    800028a0:	a099                	j	800028e6 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    800028a2:	00006517          	auipc	a0,0x6
    800028a6:	a8e50513          	addi	a0,a0,-1394 # 80008330 <states.0+0x58>
    800028aa:	ffffe097          	auipc	ra,0xffffe
    800028ae:	c92080e7          	jalr	-878(ra) # 8000053c <panic>
    if(killed(p))
    800028b2:	00000097          	auipc	ra,0x0
    800028b6:	a44080e7          	jalr	-1468(ra) # 800022f6 <killed>
    800028ba:	e921                	bnez	a0,8000290a <usertrap+0xc0>
    p->trapframe->epc += 4;
    800028bc:	6cb8                	ld	a4,88(s1)
    800028be:	6f1c                	ld	a5,24(a4)
    800028c0:	0791                	addi	a5,a5,4
    800028c2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028c8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028cc:	10079073          	csrw	sstatus,a5
    syscall();
    800028d0:	00000097          	auipc	ra,0x0
    800028d4:	2d4080e7          	jalr	724(ra) # 80002ba4 <syscall>
  if(killed(p))
    800028d8:	8526                	mv	a0,s1
    800028da:	00000097          	auipc	ra,0x0
    800028de:	a1c080e7          	jalr	-1508(ra) # 800022f6 <killed>
    800028e2:	c911                	beqz	a0,800028f6 <usertrap+0xac>
    800028e4:	4901                	li	s2,0
    exit(-1);
    800028e6:	557d                	li	a0,-1
    800028e8:	00000097          	auipc	ra,0x0
    800028ec:	89a080e7          	jalr	-1894(ra) # 80002182 <exit>
  if(which_dev == 2)
    800028f0:	4789                	li	a5,2
    800028f2:	04f90f63          	beq	s2,a5,80002950 <usertrap+0x106>
  usertrapret();
    800028f6:	00000097          	auipc	ra,0x0
    800028fa:	dd2080e7          	jalr	-558(ra) # 800026c8 <usertrapret>
}
    800028fe:	60e2                	ld	ra,24(sp)
    80002900:	6442                	ld	s0,16(sp)
    80002902:	64a2                	ld	s1,8(sp)
    80002904:	6902                	ld	s2,0(sp)
    80002906:	6105                	addi	sp,sp,32
    80002908:	8082                	ret
      exit(-1);
    8000290a:	557d                	li	a0,-1
    8000290c:	00000097          	auipc	ra,0x0
    80002910:	876080e7          	jalr	-1930(ra) # 80002182 <exit>
    80002914:	b765                	j	800028bc <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002916:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000291a:	5890                	lw	a2,48(s1)
    8000291c:	00006517          	auipc	a0,0x6
    80002920:	a3450513          	addi	a0,a0,-1484 # 80008350 <states.0+0x78>
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	c62080e7          	jalr	-926(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000292c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002930:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002934:	00006517          	auipc	a0,0x6
    80002938:	a4c50513          	addi	a0,a0,-1460 # 80008380 <states.0+0xa8>
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	c4a080e7          	jalr	-950(ra) # 80000586 <printf>
    setkilled(p);
    80002944:	8526                	mv	a0,s1
    80002946:	00000097          	auipc	ra,0x0
    8000294a:	984080e7          	jalr	-1660(ra) # 800022ca <setkilled>
    8000294e:	b769                	j	800028d8 <usertrap+0x8e>
    yield();
    80002950:	fffff097          	auipc	ra,0xfffff
    80002954:	6c2080e7          	jalr	1730(ra) # 80002012 <yield>
    80002958:	bf79                	j	800028f6 <usertrap+0xac>

000000008000295a <kerneltrap>:
{
    8000295a:	7179                	addi	sp,sp,-48
    8000295c:	f406                	sd	ra,40(sp)
    8000295e:	f022                	sd	s0,32(sp)
    80002960:	ec26                	sd	s1,24(sp)
    80002962:	e84a                	sd	s2,16(sp)
    80002964:	e44e                	sd	s3,8(sp)
    80002966:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002968:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000296c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002970:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002974:	1004f793          	andi	a5,s1,256
    80002978:	cb85                	beqz	a5,800029a8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000297a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000297e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002980:	ef85                	bnez	a5,800029b8 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002982:	00000097          	auipc	ra,0x0
    80002986:	e22080e7          	jalr	-478(ra) # 800027a4 <devintr>
    8000298a:	cd1d                	beqz	a0,800029c8 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000298c:	4789                	li	a5,2
    8000298e:	06f50a63          	beq	a0,a5,80002a02 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002992:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002996:	10049073          	csrw	sstatus,s1
}
    8000299a:	70a2                	ld	ra,40(sp)
    8000299c:	7402                	ld	s0,32(sp)
    8000299e:	64e2                	ld	s1,24(sp)
    800029a0:	6942                	ld	s2,16(sp)
    800029a2:	69a2                	ld	s3,8(sp)
    800029a4:	6145                	addi	sp,sp,48
    800029a6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029a8:	00006517          	auipc	a0,0x6
    800029ac:	9f850513          	addi	a0,a0,-1544 # 800083a0 <states.0+0xc8>
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	b8c080e7          	jalr	-1140(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    800029b8:	00006517          	auipc	a0,0x6
    800029bc:	a1050513          	addi	a0,a0,-1520 # 800083c8 <states.0+0xf0>
    800029c0:	ffffe097          	auipc	ra,0xffffe
    800029c4:	b7c080e7          	jalr	-1156(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    800029c8:	85ce                	mv	a1,s3
    800029ca:	00006517          	auipc	a0,0x6
    800029ce:	a1e50513          	addi	a0,a0,-1506 # 800083e8 <states.0+0x110>
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	bb4080e7          	jalr	-1100(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029da:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029de:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029e2:	00006517          	auipc	a0,0x6
    800029e6:	a1650513          	addi	a0,a0,-1514 # 800083f8 <states.0+0x120>
    800029ea:	ffffe097          	auipc	ra,0xffffe
    800029ee:	b9c080e7          	jalr	-1124(ra) # 80000586 <printf>
    panic("kerneltrap");
    800029f2:	00006517          	auipc	a0,0x6
    800029f6:	a1e50513          	addi	a0,a0,-1506 # 80008410 <states.0+0x138>
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	b42080e7          	jalr	-1214(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a02:	fffff097          	auipc	ra,0xfffff
    80002a06:	fa4080e7          	jalr	-92(ra) # 800019a6 <myproc>
    80002a0a:	d541                	beqz	a0,80002992 <kerneltrap+0x38>
    80002a0c:	fffff097          	auipc	ra,0xfffff
    80002a10:	f9a080e7          	jalr	-102(ra) # 800019a6 <myproc>
    80002a14:	4d18                	lw	a4,24(a0)
    80002a16:	4791                	li	a5,4
    80002a18:	f6f71de3          	bne	a4,a5,80002992 <kerneltrap+0x38>
    yield();
    80002a1c:	fffff097          	auipc	ra,0xfffff
    80002a20:	5f6080e7          	jalr	1526(ra) # 80002012 <yield>
    80002a24:	b7bd                	j	80002992 <kerneltrap+0x38>

0000000080002a26 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a26:	1101                	addi	sp,sp,-32
    80002a28:	ec06                	sd	ra,24(sp)
    80002a2a:	e822                	sd	s0,16(sp)
    80002a2c:	e426                	sd	s1,8(sp)
    80002a2e:	1000                	addi	s0,sp,32
    80002a30:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a32:	fffff097          	auipc	ra,0xfffff
    80002a36:	f74080e7          	jalr	-140(ra) # 800019a6 <myproc>
  switch (n)
    80002a3a:	4795                	li	a5,5
    80002a3c:	0497e163          	bltu	a5,s1,80002a7e <argraw+0x58>
    80002a40:	048a                	slli	s1,s1,0x2
    80002a42:	00006717          	auipc	a4,0x6
    80002a46:	a0670713          	addi	a4,a4,-1530 # 80008448 <states.0+0x170>
    80002a4a:	94ba                	add	s1,s1,a4
    80002a4c:	409c                	lw	a5,0(s1)
    80002a4e:	97ba                	add	a5,a5,a4
    80002a50:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002a52:	6d3c                	ld	a5,88(a0)
    80002a54:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a56:	60e2                	ld	ra,24(sp)
    80002a58:	6442                	ld	s0,16(sp)
    80002a5a:	64a2                	ld	s1,8(sp)
    80002a5c:	6105                	addi	sp,sp,32
    80002a5e:	8082                	ret
    return p->trapframe->a1;
    80002a60:	6d3c                	ld	a5,88(a0)
    80002a62:	7fa8                	ld	a0,120(a5)
    80002a64:	bfcd                	j	80002a56 <argraw+0x30>
    return p->trapframe->a2;
    80002a66:	6d3c                	ld	a5,88(a0)
    80002a68:	63c8                	ld	a0,128(a5)
    80002a6a:	b7f5                	j	80002a56 <argraw+0x30>
    return p->trapframe->a3;
    80002a6c:	6d3c                	ld	a5,88(a0)
    80002a6e:	67c8                	ld	a0,136(a5)
    80002a70:	b7dd                	j	80002a56 <argraw+0x30>
    return p->trapframe->a4;
    80002a72:	6d3c                	ld	a5,88(a0)
    80002a74:	6bc8                	ld	a0,144(a5)
    80002a76:	b7c5                	j	80002a56 <argraw+0x30>
    return p->trapframe->a5;
    80002a78:	6d3c                	ld	a5,88(a0)
    80002a7a:	6fc8                	ld	a0,152(a5)
    80002a7c:	bfe9                	j	80002a56 <argraw+0x30>
  panic("argraw");
    80002a7e:	00006517          	auipc	a0,0x6
    80002a82:	9a250513          	addi	a0,a0,-1630 # 80008420 <states.0+0x148>
    80002a86:	ffffe097          	auipc	ra,0xffffe
    80002a8a:	ab6080e7          	jalr	-1354(ra) # 8000053c <panic>

0000000080002a8e <fetchaddr>:
{
    80002a8e:	1101                	addi	sp,sp,-32
    80002a90:	ec06                	sd	ra,24(sp)
    80002a92:	e822                	sd	s0,16(sp)
    80002a94:	e426                	sd	s1,8(sp)
    80002a96:	e04a                	sd	s2,0(sp)
    80002a98:	1000                	addi	s0,sp,32
    80002a9a:	84aa                	mv	s1,a0
    80002a9c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a9e:	fffff097          	auipc	ra,0xfffff
    80002aa2:	f08080e7          	jalr	-248(ra) # 800019a6 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002aa6:	653c                	ld	a5,72(a0)
    80002aa8:	02f4f863          	bgeu	s1,a5,80002ad8 <fetchaddr+0x4a>
    80002aac:	00848713          	addi	a4,s1,8
    80002ab0:	02e7e663          	bltu	a5,a4,80002adc <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ab4:	46a1                	li	a3,8
    80002ab6:	8626                	mv	a2,s1
    80002ab8:	85ca                	mv	a1,s2
    80002aba:	6928                	ld	a0,80(a0)
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	c36080e7          	jalr	-970(ra) # 800016f2 <copyin>
    80002ac4:	00a03533          	snez	a0,a0
    80002ac8:	40a00533          	neg	a0,a0
}
    80002acc:	60e2                	ld	ra,24(sp)
    80002ace:	6442                	ld	s0,16(sp)
    80002ad0:	64a2                	ld	s1,8(sp)
    80002ad2:	6902                	ld	s2,0(sp)
    80002ad4:	6105                	addi	sp,sp,32
    80002ad6:	8082                	ret
    return -1;
    80002ad8:	557d                	li	a0,-1
    80002ada:	bfcd                	j	80002acc <fetchaddr+0x3e>
    80002adc:	557d                	li	a0,-1
    80002ade:	b7fd                	j	80002acc <fetchaddr+0x3e>

0000000080002ae0 <fetchstr>:
{
    80002ae0:	7179                	addi	sp,sp,-48
    80002ae2:	f406                	sd	ra,40(sp)
    80002ae4:	f022                	sd	s0,32(sp)
    80002ae6:	ec26                	sd	s1,24(sp)
    80002ae8:	e84a                	sd	s2,16(sp)
    80002aea:	e44e                	sd	s3,8(sp)
    80002aec:	1800                	addi	s0,sp,48
    80002aee:	892a                	mv	s2,a0
    80002af0:	84ae                	mv	s1,a1
    80002af2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002af4:	fffff097          	auipc	ra,0xfffff
    80002af8:	eb2080e7          	jalr	-334(ra) # 800019a6 <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002afc:	86ce                	mv	a3,s3
    80002afe:	864a                	mv	a2,s2
    80002b00:	85a6                	mv	a1,s1
    80002b02:	6928                	ld	a0,80(a0)
    80002b04:	fffff097          	auipc	ra,0xfffff
    80002b08:	c7c080e7          	jalr	-900(ra) # 80001780 <copyinstr>
    80002b0c:	00054e63          	bltz	a0,80002b28 <fetchstr+0x48>
  return strlen(buf);
    80002b10:	8526                	mv	a0,s1
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	336080e7          	jalr	822(ra) # 80000e48 <strlen>
}
    80002b1a:	70a2                	ld	ra,40(sp)
    80002b1c:	7402                	ld	s0,32(sp)
    80002b1e:	64e2                	ld	s1,24(sp)
    80002b20:	6942                	ld	s2,16(sp)
    80002b22:	69a2                	ld	s3,8(sp)
    80002b24:	6145                	addi	sp,sp,48
    80002b26:	8082                	ret
    return -1;
    80002b28:	557d                	li	a0,-1
    80002b2a:	bfc5                	j	80002b1a <fetchstr+0x3a>

0000000080002b2c <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002b2c:	1101                	addi	sp,sp,-32
    80002b2e:	ec06                	sd	ra,24(sp)
    80002b30:	e822                	sd	s0,16(sp)
    80002b32:	e426                	sd	s1,8(sp)
    80002b34:	1000                	addi	s0,sp,32
    80002b36:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b38:	00000097          	auipc	ra,0x0
    80002b3c:	eee080e7          	jalr	-274(ra) # 80002a26 <argraw>
    80002b40:	c088                	sw	a0,0(s1)
}
    80002b42:	60e2                	ld	ra,24(sp)
    80002b44:	6442                	ld	s0,16(sp)
    80002b46:	64a2                	ld	s1,8(sp)
    80002b48:	6105                	addi	sp,sp,32
    80002b4a:	8082                	ret

0000000080002b4c <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002b4c:	1101                	addi	sp,sp,-32
    80002b4e:	ec06                	sd	ra,24(sp)
    80002b50:	e822                	sd	s0,16(sp)
    80002b52:	e426                	sd	s1,8(sp)
    80002b54:	1000                	addi	s0,sp,32
    80002b56:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b58:	00000097          	auipc	ra,0x0
    80002b5c:	ece080e7          	jalr	-306(ra) # 80002a26 <argraw>
    80002b60:	e088                	sd	a0,0(s1)
}
    80002b62:	60e2                	ld	ra,24(sp)
    80002b64:	6442                	ld	s0,16(sp)
    80002b66:	64a2                	ld	s1,8(sp)
    80002b68:	6105                	addi	sp,sp,32
    80002b6a:	8082                	ret

0000000080002b6c <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002b6c:	7179                	addi	sp,sp,-48
    80002b6e:	f406                	sd	ra,40(sp)
    80002b70:	f022                	sd	s0,32(sp)
    80002b72:	ec26                	sd	s1,24(sp)
    80002b74:	e84a                	sd	s2,16(sp)
    80002b76:	1800                	addi	s0,sp,48
    80002b78:	84ae                	mv	s1,a1
    80002b7a:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b7c:	fd840593          	addi	a1,s0,-40
    80002b80:	00000097          	auipc	ra,0x0
    80002b84:	fcc080e7          	jalr	-52(ra) # 80002b4c <argaddr>
  return fetchstr(addr, buf, max);
    80002b88:	864a                	mv	a2,s2
    80002b8a:	85a6                	mv	a1,s1
    80002b8c:	fd843503          	ld	a0,-40(s0)
    80002b90:	00000097          	auipc	ra,0x0
    80002b94:	f50080e7          	jalr	-176(ra) # 80002ae0 <fetchstr>
}
    80002b98:	70a2                	ld	ra,40(sp)
    80002b9a:	7402                	ld	s0,32(sp)
    80002b9c:	64e2                	ld	s1,24(sp)
    80002b9e:	6942                	ld	s2,16(sp)
    80002ba0:	6145                	addi	sp,sp,48
    80002ba2:	8082                	ret

0000000080002ba4 <syscall>:
    [SYS_prarr] sys_prarr,
    [SYS_ps] sys_ps,
};

void syscall(void)
{
    80002ba4:	1101                	addi	sp,sp,-32
    80002ba6:	ec06                	sd	ra,24(sp)
    80002ba8:	e822                	sd	s0,16(sp)
    80002baa:	e426                	sd	s1,8(sp)
    80002bac:	e04a                	sd	s2,0(sp)
    80002bae:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bb0:	fffff097          	auipc	ra,0xfffff
    80002bb4:	df6080e7          	jalr	-522(ra) # 800019a6 <myproc>
    80002bb8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bba:	05853903          	ld	s2,88(a0)
    80002bbe:	0a893783          	ld	a5,168(s2)
    80002bc2:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002bc6:	37fd                	addiw	a5,a5,-1
    80002bc8:	4761                	li	a4,24
    80002bca:	00f76f63          	bltu	a4,a5,80002be8 <syscall+0x44>
    80002bce:	00369713          	slli	a4,a3,0x3
    80002bd2:	00006797          	auipc	a5,0x6
    80002bd6:	88e78793          	addi	a5,a5,-1906 # 80008460 <syscalls>
    80002bda:	97ba                	add	a5,a5,a4
    80002bdc:	639c                	ld	a5,0(a5)
    80002bde:	c789                	beqz	a5,80002be8 <syscall+0x44>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002be0:	9782                	jalr	a5
    80002be2:	06a93823          	sd	a0,112(s2)
    80002be6:	a839                	j	80002c04 <syscall+0x60>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002be8:	15848613          	addi	a2,s1,344
    80002bec:	588c                	lw	a1,48(s1)
    80002bee:	00006517          	auipc	a0,0x6
    80002bf2:	83a50513          	addi	a0,a0,-1990 # 80008428 <states.0+0x150>
    80002bf6:	ffffe097          	auipc	ra,0xffffe
    80002bfa:	990080e7          	jalr	-1648(ra) # 80000586 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002bfe:	6cbc                	ld	a5,88(s1)
    80002c00:	577d                	li	a4,-1
    80002c02:	fbb8                	sd	a4,112(a5)
  }
}
    80002c04:	60e2                	ld	ra,24(sp)
    80002c06:	6442                	ld	s0,16(sp)
    80002c08:	64a2                	ld	s1,8(sp)
    80002c0a:	6902                	ld	s2,0(sp)
    80002c0c:	6105                	addi	sp,sp,32
    80002c0e:	8082                	ret

0000000080002c10 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c10:	1101                	addi	sp,sp,-32
    80002c12:	ec06                	sd	ra,24(sp)
    80002c14:	e822                	sd	s0,16(sp)
    80002c16:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002c18:	fec40593          	addi	a1,s0,-20
    80002c1c:	4501                	li	a0,0
    80002c1e:	00000097          	auipc	ra,0x0
    80002c22:	f0e080e7          	jalr	-242(ra) # 80002b2c <argint>
  exit(n);
    80002c26:	fec42503          	lw	a0,-20(s0)
    80002c2a:	fffff097          	auipc	ra,0xfffff
    80002c2e:	558080e7          	jalr	1368(ra) # 80002182 <exit>
  return 0; // not reached
}
    80002c32:	4501                	li	a0,0
    80002c34:	60e2                	ld	ra,24(sp)
    80002c36:	6442                	ld	s0,16(sp)
    80002c38:	6105                	addi	sp,sp,32
    80002c3a:	8082                	ret

0000000080002c3c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c3c:	1141                	addi	sp,sp,-16
    80002c3e:	e406                	sd	ra,8(sp)
    80002c40:	e022                	sd	s0,0(sp)
    80002c42:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c44:	fffff097          	auipc	ra,0xfffff
    80002c48:	d62080e7          	jalr	-670(ra) # 800019a6 <myproc>
}
    80002c4c:	5908                	lw	a0,48(a0)
    80002c4e:	60a2                	ld	ra,8(sp)
    80002c50:	6402                	ld	s0,0(sp)
    80002c52:	0141                	addi	sp,sp,16
    80002c54:	8082                	ret

0000000080002c56 <sys_fork>:

uint64
sys_fork(void)
{
    80002c56:	1141                	addi	sp,sp,-16
    80002c58:	e406                	sd	ra,8(sp)
    80002c5a:	e022                	sd	s0,0(sp)
    80002c5c:	0800                	addi	s0,sp,16
  return fork();
    80002c5e:	fffff097          	auipc	ra,0xfffff
    80002c62:	0fe080e7          	jalr	254(ra) # 80001d5c <fork>
}
    80002c66:	60a2                	ld	ra,8(sp)
    80002c68:	6402                	ld	s0,0(sp)
    80002c6a:	0141                	addi	sp,sp,16
    80002c6c:	8082                	ret

0000000080002c6e <sys_wait>:

uint64
sys_wait(void)
{
    80002c6e:	1101                	addi	sp,sp,-32
    80002c70:	ec06                	sd	ra,24(sp)
    80002c72:	e822                	sd	s0,16(sp)
    80002c74:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002c76:	fe840593          	addi	a1,s0,-24
    80002c7a:	4501                	li	a0,0
    80002c7c:	00000097          	auipc	ra,0x0
    80002c80:	ed0080e7          	jalr	-304(ra) # 80002b4c <argaddr>
  return wait(p);
    80002c84:	fe843503          	ld	a0,-24(s0)
    80002c88:	fffff097          	auipc	ra,0xfffff
    80002c8c:	6a0080e7          	jalr	1696(ra) # 80002328 <wait>
}
    80002c90:	60e2                	ld	ra,24(sp)
    80002c92:	6442                	ld	s0,16(sp)
    80002c94:	6105                	addi	sp,sp,32
    80002c96:	8082                	ret

0000000080002c98 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c98:	7179                	addi	sp,sp,-48
    80002c9a:	f406                	sd	ra,40(sp)
    80002c9c:	f022                	sd	s0,32(sp)
    80002c9e:	ec26                	sd	s1,24(sp)
    80002ca0:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002ca2:	fdc40593          	addi	a1,s0,-36
    80002ca6:	4501                	li	a0,0
    80002ca8:	00000097          	auipc	ra,0x0
    80002cac:	e84080e7          	jalr	-380(ra) # 80002b2c <argint>
  addr = myproc()->sz;
    80002cb0:	fffff097          	auipc	ra,0xfffff
    80002cb4:	cf6080e7          	jalr	-778(ra) # 800019a6 <myproc>
    80002cb8:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002cba:	fdc42503          	lw	a0,-36(s0)
    80002cbe:	fffff097          	auipc	ra,0xfffff
    80002cc2:	042080e7          	jalr	66(ra) # 80001d00 <growproc>
    80002cc6:	00054863          	bltz	a0,80002cd6 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002cca:	8526                	mv	a0,s1
    80002ccc:	70a2                	ld	ra,40(sp)
    80002cce:	7402                	ld	s0,32(sp)
    80002cd0:	64e2                	ld	s1,24(sp)
    80002cd2:	6145                	addi	sp,sp,48
    80002cd4:	8082                	ret
    return -1;
    80002cd6:	54fd                	li	s1,-1
    80002cd8:	bfcd                	j	80002cca <sys_sbrk+0x32>

0000000080002cda <sys_sleep>:

uint64
sys_sleep(void)
{
    80002cda:	7139                	addi	sp,sp,-64
    80002cdc:	fc06                	sd	ra,56(sp)
    80002cde:	f822                	sd	s0,48(sp)
    80002ce0:	f426                	sd	s1,40(sp)
    80002ce2:	f04a                	sd	s2,32(sp)
    80002ce4:	ec4e                	sd	s3,24(sp)
    80002ce6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002ce8:	fcc40593          	addi	a1,s0,-52
    80002cec:	4501                	li	a0,0
    80002cee:	00000097          	auipc	ra,0x0
    80002cf2:	e3e080e7          	jalr	-450(ra) # 80002b2c <argint>
  acquire(&tickslock);
    80002cf6:	00014517          	auipc	a0,0x14
    80002cfa:	d3a50513          	addi	a0,a0,-710 # 80016a30 <tickslock>
    80002cfe:	ffffe097          	auipc	ra,0xffffe
    80002d02:	ed4080e7          	jalr	-300(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    80002d06:	00006917          	auipc	s2,0x6
    80002d0a:	c8a92903          	lw	s2,-886(s2) # 80008990 <ticks>
  while (ticks - ticks0 < n)
    80002d0e:	fcc42783          	lw	a5,-52(s0)
    80002d12:	cf9d                	beqz	a5,80002d50 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d14:	00014997          	auipc	s3,0x14
    80002d18:	d1c98993          	addi	s3,s3,-740 # 80016a30 <tickslock>
    80002d1c:	00006497          	auipc	s1,0x6
    80002d20:	c7448493          	addi	s1,s1,-908 # 80008990 <ticks>
    if (killed(myproc()))
    80002d24:	fffff097          	auipc	ra,0xfffff
    80002d28:	c82080e7          	jalr	-894(ra) # 800019a6 <myproc>
    80002d2c:	fffff097          	auipc	ra,0xfffff
    80002d30:	5ca080e7          	jalr	1482(ra) # 800022f6 <killed>
    80002d34:	ed15                	bnez	a0,80002d70 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002d36:	85ce                	mv	a1,s3
    80002d38:	8526                	mv	a0,s1
    80002d3a:	fffff097          	auipc	ra,0xfffff
    80002d3e:	314080e7          	jalr	788(ra) # 8000204e <sleep>
  while (ticks - ticks0 < n)
    80002d42:	409c                	lw	a5,0(s1)
    80002d44:	412787bb          	subw	a5,a5,s2
    80002d48:	fcc42703          	lw	a4,-52(s0)
    80002d4c:	fce7ece3          	bltu	a5,a4,80002d24 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002d50:	00014517          	auipc	a0,0x14
    80002d54:	ce050513          	addi	a0,a0,-800 # 80016a30 <tickslock>
    80002d58:	ffffe097          	auipc	ra,0xffffe
    80002d5c:	f2e080e7          	jalr	-210(ra) # 80000c86 <release>
  return 0;
    80002d60:	4501                	li	a0,0
}
    80002d62:	70e2                	ld	ra,56(sp)
    80002d64:	7442                	ld	s0,48(sp)
    80002d66:	74a2                	ld	s1,40(sp)
    80002d68:	7902                	ld	s2,32(sp)
    80002d6a:	69e2                	ld	s3,24(sp)
    80002d6c:	6121                	addi	sp,sp,64
    80002d6e:	8082                	ret
      release(&tickslock);
    80002d70:	00014517          	auipc	a0,0x14
    80002d74:	cc050513          	addi	a0,a0,-832 # 80016a30 <tickslock>
    80002d78:	ffffe097          	auipc	ra,0xffffe
    80002d7c:	f0e080e7          	jalr	-242(ra) # 80000c86 <release>
      return -1;
    80002d80:	557d                	li	a0,-1
    80002d82:	b7c5                	j	80002d62 <sys_sleep+0x88>

0000000080002d84 <sys_kill>:

uint64
sys_kill(void)
{
    80002d84:	1101                	addi	sp,sp,-32
    80002d86:	ec06                	sd	ra,24(sp)
    80002d88:	e822                	sd	s0,16(sp)
    80002d8a:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002d8c:	fec40593          	addi	a1,s0,-20
    80002d90:	4501                	li	a0,0
    80002d92:	00000097          	auipc	ra,0x0
    80002d96:	d9a080e7          	jalr	-614(ra) # 80002b2c <argint>
  return kill(pid);
    80002d9a:	fec42503          	lw	a0,-20(s0)
    80002d9e:	fffff097          	auipc	ra,0xfffff
    80002da2:	4ba080e7          	jalr	1210(ra) # 80002258 <kill>
}
    80002da6:	60e2                	ld	ra,24(sp)
    80002da8:	6442                	ld	s0,16(sp)
    80002daa:	6105                	addi	sp,sp,32
    80002dac:	8082                	ret

0000000080002dae <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002dae:	1101                	addi	sp,sp,-32
    80002db0:	ec06                	sd	ra,24(sp)
    80002db2:	e822                	sd	s0,16(sp)
    80002db4:	e426                	sd	s1,8(sp)
    80002db6:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002db8:	00014517          	auipc	a0,0x14
    80002dbc:	c7850513          	addi	a0,a0,-904 # 80016a30 <tickslock>
    80002dc0:	ffffe097          	auipc	ra,0xffffe
    80002dc4:	e12080e7          	jalr	-494(ra) # 80000bd2 <acquire>
  xticks = ticks;
    80002dc8:	00006497          	auipc	s1,0x6
    80002dcc:	bc84a483          	lw	s1,-1080(s1) # 80008990 <ticks>
  release(&tickslock);
    80002dd0:	00014517          	auipc	a0,0x14
    80002dd4:	c6050513          	addi	a0,a0,-928 # 80016a30 <tickslock>
    80002dd8:	ffffe097          	auipc	ra,0xffffe
    80002ddc:	eae080e7          	jalr	-338(ra) # 80000c86 <release>
  return xticks;
}
    80002de0:	02049513          	slli	a0,s1,0x20
    80002de4:	9101                	srli	a0,a0,0x20
    80002de6:	60e2                	ld	ra,24(sp)
    80002de8:	6442                	ld	s0,16(sp)
    80002dea:	64a2                	ld	s1,8(sp)
    80002dec:	6105                	addi	sp,sp,32
    80002dee:	8082                	ret

0000000080002df0 <sys_hello>:
// return hello statement hello world
// Added as a lab1 excercise.

uint64
sys_hello(void)
{
    80002df0:	1141                	addi	sp,sp,-16
    80002df2:	e406                	sd	ra,8(sp)
    80002df4:	e022                	sd	s0,0(sp)
    80002df6:	0800                	addi	s0,sp,16
  printf("Hello World\n");
    80002df8:	00005517          	auipc	a0,0x5
    80002dfc:	73850513          	addi	a0,a0,1848 # 80008530 <syscalls+0xd0>
    80002e00:	ffffd097          	auipc	ra,0xffffd
    80002e04:	786080e7          	jalr	1926(ra) # 80000586 <printf>
  return 22;
}
    80002e08:	4559                	li	a0,22
    80002e0a:	60a2                	ld	ra,8(sp)
    80002e0c:	6402                	ld	s0,0(sp)
    80002e0e:	0141                	addi	sp,sp,16
    80002e10:	8082                	ret

0000000080002e12 <sys_procState>:

uint64
sys_procState(void)
{
    80002e12:	1141                	addi	sp,sp,-16
    80002e14:	e406                	sd	ra,8(sp)
    80002e16:	e022                	sd	s0,0(sp)
    80002e18:	0800                	addi	s0,sp,16
  static const char *stateString[] = {
      "UNUSED", "USED", "SLEEPING", "RUNNABLE", "RUNNING", "ZOMBIE"};
  printf("PID: %d\n", myproc()->pid);
    80002e1a:	fffff097          	auipc	ra,0xfffff
    80002e1e:	b8c080e7          	jalr	-1140(ra) # 800019a6 <myproc>
    80002e22:	590c                	lw	a1,48(a0)
    80002e24:	00005517          	auipc	a0,0x5
    80002e28:	71c50513          	addi	a0,a0,1820 # 80008540 <syscalls+0xe0>
    80002e2c:	ffffd097          	auipc	ra,0xffffd
    80002e30:	75a080e7          	jalr	1882(ra) # 80000586 <printf>
  int i = myproc()->state;
    80002e34:	fffff097          	auipc	ra,0xfffff
    80002e38:	b72080e7          	jalr	-1166(ra) # 800019a6 <myproc>
  printf("State: %s\n", stateString[i]);
    80002e3c:	4d18                	lw	a4,24(a0)
    80002e3e:	070e                	slli	a4,a4,0x3
    80002e40:	00005797          	auipc	a5,0x5
    80002e44:	76078793          	addi	a5,a5,1888 # 800085a0 <stateString.0>
    80002e48:	97ba                	add	a5,a5,a4
    80002e4a:	638c                	ld	a1,0(a5)
    80002e4c:	00005517          	auipc	a0,0x5
    80002e50:	70450513          	addi	a0,a0,1796 # 80008550 <syscalls+0xf0>
    80002e54:	ffffd097          	auipc	ra,0xffffd
    80002e58:	732080e7          	jalr	1842(ra) # 80000586 <printf>

  return 23;
}
    80002e5c:	455d                	li	a0,23
    80002e5e:	60a2                	ld	ra,8(sp)
    80002e60:	6402                	ld	s0,0(sp)
    80002e62:	0141                	addi	sp,sp,16
    80002e64:	8082                	ret

0000000080002e66 <sys_prarr>:

// Prints arrays
uint64
sys_prarr(char *array[])
{
    80002e66:	7179                	addi	sp,sp,-48
    80002e68:	f406                	sd	ra,40(sp)
    80002e6a:	f022                	sd	s0,32(sp)
    80002e6c:	ec26                	sd	s1,24(sp)
    80002e6e:	e84a                	sd	s2,16(sp)
    80002e70:	e44e                	sd	s3,8(sp)
    80002e72:	1800                	addi	s0,sp,48
  int count = strlen(*array);
    80002e74:	6108                	ld	a0,0(a0)
    80002e76:	ffffe097          	auipc	ra,0xffffe
    80002e7a:	fd2080e7          	jalr	-46(ra) # 80000e48 <strlen>
  for (int i = 0; i < count; i++)
    80002e7e:	02a05163          	blez	a0,80002ea0 <sys_prarr+0x3a>
    80002e82:	892a                	mv	s2,a0
    80002e84:	4481                	li	s1,0
  {
    /* code */
    // printf("%s\n", array[i]);
    printf("%d\n", count);
    80002e86:	00005997          	auipc	s3,0x5
    80002e8a:	5ba98993          	addi	s3,s3,1466 # 80008440 <states.0+0x168>
    80002e8e:	85ca                	mv	a1,s2
    80002e90:	854e                	mv	a0,s3
    80002e92:	ffffd097          	auipc	ra,0xffffd
    80002e96:	6f4080e7          	jalr	1780(ra) # 80000586 <printf>
  for (int i = 0; i < count; i++)
    80002e9a:	2485                	addiw	s1,s1,1
    80002e9c:	fe9919e3          	bne	s2,s1,80002e8e <sys_prarr+0x28>
  }

  return 24;
}
    80002ea0:	4561                	li	a0,24
    80002ea2:	70a2                	ld	ra,40(sp)
    80002ea4:	7402                	ld	s0,32(sp)
    80002ea6:	64e2                	ld	s1,24(sp)
    80002ea8:	6942                	ld	s2,16(sp)
    80002eaa:	69a2                	ld	s3,8(sp)
    80002eac:	6145                	addi	sp,sp,48
    80002eae:	8082                	ret

0000000080002eb0 <sys_ps>:

// Prints the ongoing system processes
uint64
sys_ps(void)
{
    80002eb0:	1141                	addi	sp,sp,-16
    80002eb2:	e406                	sd	ra,8(sp)
    80002eb4:	e022                	sd	s0,0(sp)
    80002eb6:	0800                	addi	s0,sp,16
  proctest();
    80002eb8:	fffff097          	auipc	ra,0xfffff
    80002ebc:	6fa080e7          	jalr	1786(ra) # 800025b2 <proctest>
  return 25;
    80002ec0:	4565                	li	a0,25
    80002ec2:	60a2                	ld	ra,8(sp)
    80002ec4:	6402                	ld	s0,0(sp)
    80002ec6:	0141                	addi	sp,sp,16
    80002ec8:	8082                	ret

0000000080002eca <binit>:
  // head.next is most recent, head.prev is least.
  struct buf head;
} bcache;

void binit(void)
{
    80002eca:	7179                	addi	sp,sp,-48
    80002ecc:	f406                	sd	ra,40(sp)
    80002ece:	f022                	sd	s0,32(sp)
    80002ed0:	ec26                	sd	s1,24(sp)
    80002ed2:	e84a                	sd	s2,16(sp)
    80002ed4:	e44e                	sd	s3,8(sp)
    80002ed6:	e052                	sd	s4,0(sp)
    80002ed8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002eda:	00005597          	auipc	a1,0x5
    80002ede:	6f658593          	addi	a1,a1,1782 # 800085d0 <stateString.0+0x30>
    80002ee2:	00014517          	auipc	a0,0x14
    80002ee6:	b6650513          	addi	a0,a0,-1178 # 80016a48 <bcache>
    80002eea:	ffffe097          	auipc	ra,0xffffe
    80002eee:	c58080e7          	jalr	-936(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ef2:	0001c797          	auipc	a5,0x1c
    80002ef6:	b5678793          	addi	a5,a5,-1194 # 8001ea48 <bcache+0x8000>
    80002efa:	0001c717          	auipc	a4,0x1c
    80002efe:	db670713          	addi	a4,a4,-586 # 8001ecb0 <bcache+0x8268>
    80002f02:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f06:	2ae7bc23          	sd	a4,696(a5)
  for (b = bcache.buf; b < bcache.buf + NBUF; b++)
    80002f0a:	00014497          	auipc	s1,0x14
    80002f0e:	b5648493          	addi	s1,s1,-1194 # 80016a60 <bcache+0x18>
  {
    b->next = bcache.head.next;
    80002f12:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f14:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f16:	00005a17          	auipc	s4,0x5
    80002f1a:	6c2a0a13          	addi	s4,s4,1730 # 800085d8 <stateString.0+0x38>
    b->next = bcache.head.next;
    80002f1e:	2b893783          	ld	a5,696(s2)
    80002f22:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f24:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f28:	85d2                	mv	a1,s4
    80002f2a:	01048513          	addi	a0,s1,16
    80002f2e:	00001097          	auipc	ra,0x1
    80002f32:	496080e7          	jalr	1174(ra) # 800043c4 <initsleeplock>
    bcache.head.next->prev = b;
    80002f36:	2b893783          	ld	a5,696(s2)
    80002f3a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f3c:	2a993c23          	sd	s1,696(s2)
  for (b = bcache.buf; b < bcache.buf + NBUF; b++)
    80002f40:	45848493          	addi	s1,s1,1112
    80002f44:	fd349de3          	bne	s1,s3,80002f1e <binit+0x54>
  }
}
    80002f48:	70a2                	ld	ra,40(sp)
    80002f4a:	7402                	ld	s0,32(sp)
    80002f4c:	64e2                	ld	s1,24(sp)
    80002f4e:	6942                	ld	s2,16(sp)
    80002f50:	69a2                	ld	s3,8(sp)
    80002f52:	6a02                	ld	s4,0(sp)
    80002f54:	6145                	addi	sp,sp,48
    80002f56:	8082                	ret

0000000080002f58 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf *
bread(uint dev, uint blockno)
{
    80002f58:	7179                	addi	sp,sp,-48
    80002f5a:	f406                	sd	ra,40(sp)
    80002f5c:	f022                	sd	s0,32(sp)
    80002f5e:	ec26                	sd	s1,24(sp)
    80002f60:	e84a                	sd	s2,16(sp)
    80002f62:	e44e                	sd	s3,8(sp)
    80002f64:	1800                	addi	s0,sp,48
    80002f66:	892a                	mv	s2,a0
    80002f68:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f6a:	00014517          	auipc	a0,0x14
    80002f6e:	ade50513          	addi	a0,a0,-1314 # 80016a48 <bcache>
    80002f72:	ffffe097          	auipc	ra,0xffffe
    80002f76:	c60080e7          	jalr	-928(ra) # 80000bd2 <acquire>
  for (b = bcache.head.next; b != &bcache.head; b = b->next)
    80002f7a:	0001c497          	auipc	s1,0x1c
    80002f7e:	d864b483          	ld	s1,-634(s1) # 8001ed00 <bcache+0x82b8>
    80002f82:	0001c797          	auipc	a5,0x1c
    80002f86:	d2e78793          	addi	a5,a5,-722 # 8001ecb0 <bcache+0x8268>
    80002f8a:	02f48f63          	beq	s1,a5,80002fc8 <bread+0x70>
    80002f8e:	873e                	mv	a4,a5
    80002f90:	a021                	j	80002f98 <bread+0x40>
    80002f92:	68a4                	ld	s1,80(s1)
    80002f94:	02e48a63          	beq	s1,a4,80002fc8 <bread+0x70>
    if (b->dev == dev && b->blockno == blockno)
    80002f98:	449c                	lw	a5,8(s1)
    80002f9a:	ff279ce3          	bne	a5,s2,80002f92 <bread+0x3a>
    80002f9e:	44dc                	lw	a5,12(s1)
    80002fa0:	ff3799e3          	bne	a5,s3,80002f92 <bread+0x3a>
      b->refcnt++;
    80002fa4:	40bc                	lw	a5,64(s1)
    80002fa6:	2785                	addiw	a5,a5,1
    80002fa8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002faa:	00014517          	auipc	a0,0x14
    80002fae:	a9e50513          	addi	a0,a0,-1378 # 80016a48 <bcache>
    80002fb2:	ffffe097          	auipc	ra,0xffffe
    80002fb6:	cd4080e7          	jalr	-812(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80002fba:	01048513          	addi	a0,s1,16
    80002fbe:	00001097          	auipc	ra,0x1
    80002fc2:	440080e7          	jalr	1088(ra) # 800043fe <acquiresleep>
      return b;
    80002fc6:	a8b9                	j	80003024 <bread+0xcc>
  for (b = bcache.head.prev; b != &bcache.head; b = b->prev)
    80002fc8:	0001c497          	auipc	s1,0x1c
    80002fcc:	d304b483          	ld	s1,-720(s1) # 8001ecf8 <bcache+0x82b0>
    80002fd0:	0001c797          	auipc	a5,0x1c
    80002fd4:	ce078793          	addi	a5,a5,-800 # 8001ecb0 <bcache+0x8268>
    80002fd8:	00f48863          	beq	s1,a5,80002fe8 <bread+0x90>
    80002fdc:	873e                	mv	a4,a5
    if (b->refcnt == 0)
    80002fde:	40bc                	lw	a5,64(s1)
    80002fe0:	cf81                	beqz	a5,80002ff8 <bread+0xa0>
  for (b = bcache.head.prev; b != &bcache.head; b = b->prev)
    80002fe2:	64a4                	ld	s1,72(s1)
    80002fe4:	fee49de3          	bne	s1,a4,80002fde <bread+0x86>
  panic("bget: no buffers");
    80002fe8:	00005517          	auipc	a0,0x5
    80002fec:	5f850513          	addi	a0,a0,1528 # 800085e0 <stateString.0+0x40>
    80002ff0:	ffffd097          	auipc	ra,0xffffd
    80002ff4:	54c080e7          	jalr	1356(ra) # 8000053c <panic>
      b->dev = dev;
    80002ff8:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002ffc:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003000:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003004:	4785                	li	a5,1
    80003006:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003008:	00014517          	auipc	a0,0x14
    8000300c:	a4050513          	addi	a0,a0,-1472 # 80016a48 <bcache>
    80003010:	ffffe097          	auipc	ra,0xffffe
    80003014:	c76080e7          	jalr	-906(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003018:	01048513          	addi	a0,s1,16
    8000301c:	00001097          	auipc	ra,0x1
    80003020:	3e2080e7          	jalr	994(ra) # 800043fe <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if (!b->valid)
    80003024:	409c                	lw	a5,0(s1)
    80003026:	cb89                	beqz	a5,80003038 <bread+0xe0>
  {
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003028:	8526                	mv	a0,s1
    8000302a:	70a2                	ld	ra,40(sp)
    8000302c:	7402                	ld	s0,32(sp)
    8000302e:	64e2                	ld	s1,24(sp)
    80003030:	6942                	ld	s2,16(sp)
    80003032:	69a2                	ld	s3,8(sp)
    80003034:	6145                	addi	sp,sp,48
    80003036:	8082                	ret
    virtio_disk_rw(b, 0);
    80003038:	4581                	li	a1,0
    8000303a:	8526                	mv	a0,s1
    8000303c:	00003097          	auipc	ra,0x3
    80003040:	f86080e7          	jalr	-122(ra) # 80005fc2 <virtio_disk_rw>
    b->valid = 1;
    80003044:	4785                	li	a5,1
    80003046:	c09c                	sw	a5,0(s1)
  return b;
    80003048:	b7c5                	j	80003028 <bread+0xd0>

000000008000304a <bwrite>:

// Write b's contents to disk.  Must be locked.
void bwrite(struct buf *b)
{
    8000304a:	1101                	addi	sp,sp,-32
    8000304c:	ec06                	sd	ra,24(sp)
    8000304e:	e822                	sd	s0,16(sp)
    80003050:	e426                	sd	s1,8(sp)
    80003052:	1000                	addi	s0,sp,32
    80003054:	84aa                	mv	s1,a0
  if (!holdingsleep(&b->lock))
    80003056:	0541                	addi	a0,a0,16
    80003058:	00001097          	auipc	ra,0x1
    8000305c:	440080e7          	jalr	1088(ra) # 80004498 <holdingsleep>
    80003060:	cd01                	beqz	a0,80003078 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003062:	4585                	li	a1,1
    80003064:	8526                	mv	a0,s1
    80003066:	00003097          	auipc	ra,0x3
    8000306a:	f5c080e7          	jalr	-164(ra) # 80005fc2 <virtio_disk_rw>
}
    8000306e:	60e2                	ld	ra,24(sp)
    80003070:	6442                	ld	s0,16(sp)
    80003072:	64a2                	ld	s1,8(sp)
    80003074:	6105                	addi	sp,sp,32
    80003076:	8082                	ret
    panic("bwrite");
    80003078:	00005517          	auipc	a0,0x5
    8000307c:	58050513          	addi	a0,a0,1408 # 800085f8 <stateString.0+0x58>
    80003080:	ffffd097          	auipc	ra,0xffffd
    80003084:	4bc080e7          	jalr	1212(ra) # 8000053c <panic>

0000000080003088 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void brelse(struct buf *b)
{
    80003088:	1101                	addi	sp,sp,-32
    8000308a:	ec06                	sd	ra,24(sp)
    8000308c:	e822                	sd	s0,16(sp)
    8000308e:	e426                	sd	s1,8(sp)
    80003090:	e04a                	sd	s2,0(sp)
    80003092:	1000                	addi	s0,sp,32
    80003094:	84aa                	mv	s1,a0
  if (!holdingsleep(&b->lock))
    80003096:	01050913          	addi	s2,a0,16
    8000309a:	854a                	mv	a0,s2
    8000309c:	00001097          	auipc	ra,0x1
    800030a0:	3fc080e7          	jalr	1020(ra) # 80004498 <holdingsleep>
    800030a4:	c925                	beqz	a0,80003114 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800030a6:	854a                	mv	a0,s2
    800030a8:	00001097          	auipc	ra,0x1
    800030ac:	3ac080e7          	jalr	940(ra) # 80004454 <releasesleep>

  acquire(&bcache.lock);
    800030b0:	00014517          	auipc	a0,0x14
    800030b4:	99850513          	addi	a0,a0,-1640 # 80016a48 <bcache>
    800030b8:	ffffe097          	auipc	ra,0xffffe
    800030bc:	b1a080e7          	jalr	-1254(ra) # 80000bd2 <acquire>
  b->refcnt--;
    800030c0:	40bc                	lw	a5,64(s1)
    800030c2:	37fd                	addiw	a5,a5,-1
    800030c4:	0007871b          	sext.w	a4,a5
    800030c8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0)
    800030ca:	e71d                	bnez	a4,800030f8 <brelse+0x70>
  {
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030cc:	68b8                	ld	a4,80(s1)
    800030ce:	64bc                	ld	a5,72(s1)
    800030d0:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800030d2:	68b8                	ld	a4,80(s1)
    800030d4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030d6:	0001c797          	auipc	a5,0x1c
    800030da:	97278793          	addi	a5,a5,-1678 # 8001ea48 <bcache+0x8000>
    800030de:	2b87b703          	ld	a4,696(a5)
    800030e2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030e4:	0001c717          	auipc	a4,0x1c
    800030e8:	bcc70713          	addi	a4,a4,-1076 # 8001ecb0 <bcache+0x8268>
    800030ec:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030ee:	2b87b703          	ld	a4,696(a5)
    800030f2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030f4:	2a97bc23          	sd	s1,696(a5)
  }

  release(&bcache.lock);
    800030f8:	00014517          	auipc	a0,0x14
    800030fc:	95050513          	addi	a0,a0,-1712 # 80016a48 <bcache>
    80003100:	ffffe097          	auipc	ra,0xffffe
    80003104:	b86080e7          	jalr	-1146(ra) # 80000c86 <release>
}
    80003108:	60e2                	ld	ra,24(sp)
    8000310a:	6442                	ld	s0,16(sp)
    8000310c:	64a2                	ld	s1,8(sp)
    8000310e:	6902                	ld	s2,0(sp)
    80003110:	6105                	addi	sp,sp,32
    80003112:	8082                	ret
    panic("brelse");
    80003114:	00005517          	auipc	a0,0x5
    80003118:	4ec50513          	addi	a0,a0,1260 # 80008600 <stateString.0+0x60>
    8000311c:	ffffd097          	auipc	ra,0xffffd
    80003120:	420080e7          	jalr	1056(ra) # 8000053c <panic>

0000000080003124 <bpin>:

void bpin(struct buf *b)
{
    80003124:	1101                	addi	sp,sp,-32
    80003126:	ec06                	sd	ra,24(sp)
    80003128:	e822                	sd	s0,16(sp)
    8000312a:	e426                	sd	s1,8(sp)
    8000312c:	1000                	addi	s0,sp,32
    8000312e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003130:	00014517          	auipc	a0,0x14
    80003134:	91850513          	addi	a0,a0,-1768 # 80016a48 <bcache>
    80003138:	ffffe097          	auipc	ra,0xffffe
    8000313c:	a9a080e7          	jalr	-1382(ra) # 80000bd2 <acquire>
  b->refcnt++;
    80003140:	40bc                	lw	a5,64(s1)
    80003142:	2785                	addiw	a5,a5,1
    80003144:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003146:	00014517          	auipc	a0,0x14
    8000314a:	90250513          	addi	a0,a0,-1790 # 80016a48 <bcache>
    8000314e:	ffffe097          	auipc	ra,0xffffe
    80003152:	b38080e7          	jalr	-1224(ra) # 80000c86 <release>
}
    80003156:	60e2                	ld	ra,24(sp)
    80003158:	6442                	ld	s0,16(sp)
    8000315a:	64a2                	ld	s1,8(sp)
    8000315c:	6105                	addi	sp,sp,32
    8000315e:	8082                	ret

0000000080003160 <bunpin>:

void bunpin(struct buf *b)
{
    80003160:	1101                	addi	sp,sp,-32
    80003162:	ec06                	sd	ra,24(sp)
    80003164:	e822                	sd	s0,16(sp)
    80003166:	e426                	sd	s1,8(sp)
    80003168:	1000                	addi	s0,sp,32
    8000316a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000316c:	00014517          	auipc	a0,0x14
    80003170:	8dc50513          	addi	a0,a0,-1828 # 80016a48 <bcache>
    80003174:	ffffe097          	auipc	ra,0xffffe
    80003178:	a5e080e7          	jalr	-1442(ra) # 80000bd2 <acquire>
  b->refcnt--;
    8000317c:	40bc                	lw	a5,64(s1)
    8000317e:	37fd                	addiw	a5,a5,-1
    80003180:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003182:	00014517          	auipc	a0,0x14
    80003186:	8c650513          	addi	a0,a0,-1850 # 80016a48 <bcache>
    8000318a:	ffffe097          	auipc	ra,0xffffe
    8000318e:	afc080e7          	jalr	-1284(ra) # 80000c86 <release>
}
    80003192:	60e2                	ld	ra,24(sp)
    80003194:	6442                	ld	s0,16(sp)
    80003196:	64a2                	ld	s1,8(sp)
    80003198:	6105                	addi	sp,sp,32
    8000319a:	8082                	ret

000000008000319c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000319c:	1101                	addi	sp,sp,-32
    8000319e:	ec06                	sd	ra,24(sp)
    800031a0:	e822                	sd	s0,16(sp)
    800031a2:	e426                	sd	s1,8(sp)
    800031a4:	e04a                	sd	s2,0(sp)
    800031a6:	1000                	addi	s0,sp,32
    800031a8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031aa:	00d5d59b          	srliw	a1,a1,0xd
    800031ae:	0001c797          	auipc	a5,0x1c
    800031b2:	f767a783          	lw	a5,-138(a5) # 8001f124 <sb+0x1c>
    800031b6:	9dbd                	addw	a1,a1,a5
    800031b8:	00000097          	auipc	ra,0x0
    800031bc:	da0080e7          	jalr	-608(ra) # 80002f58 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031c0:	0074f713          	andi	a4,s1,7
    800031c4:	4785                	li	a5,1
    800031c6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031ca:	14ce                	slli	s1,s1,0x33
    800031cc:	90d9                	srli	s1,s1,0x36
    800031ce:	00950733          	add	a4,a0,s1
    800031d2:	05874703          	lbu	a4,88(a4)
    800031d6:	00e7f6b3          	and	a3,a5,a4
    800031da:	c69d                	beqz	a3,80003208 <bfree+0x6c>
    800031dc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031de:	94aa                	add	s1,s1,a0
    800031e0:	fff7c793          	not	a5,a5
    800031e4:	8f7d                	and	a4,a4,a5
    800031e6:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800031ea:	00001097          	auipc	ra,0x1
    800031ee:	0f6080e7          	jalr	246(ra) # 800042e0 <log_write>
  brelse(bp);
    800031f2:	854a                	mv	a0,s2
    800031f4:	00000097          	auipc	ra,0x0
    800031f8:	e94080e7          	jalr	-364(ra) # 80003088 <brelse>
}
    800031fc:	60e2                	ld	ra,24(sp)
    800031fe:	6442                	ld	s0,16(sp)
    80003200:	64a2                	ld	s1,8(sp)
    80003202:	6902                	ld	s2,0(sp)
    80003204:	6105                	addi	sp,sp,32
    80003206:	8082                	ret
    panic("freeing free block");
    80003208:	00005517          	auipc	a0,0x5
    8000320c:	40050513          	addi	a0,a0,1024 # 80008608 <stateString.0+0x68>
    80003210:	ffffd097          	auipc	ra,0xffffd
    80003214:	32c080e7          	jalr	812(ra) # 8000053c <panic>

0000000080003218 <balloc>:
{
    80003218:	711d                	addi	sp,sp,-96
    8000321a:	ec86                	sd	ra,88(sp)
    8000321c:	e8a2                	sd	s0,80(sp)
    8000321e:	e4a6                	sd	s1,72(sp)
    80003220:	e0ca                	sd	s2,64(sp)
    80003222:	fc4e                	sd	s3,56(sp)
    80003224:	f852                	sd	s4,48(sp)
    80003226:	f456                	sd	s5,40(sp)
    80003228:	f05a                	sd	s6,32(sp)
    8000322a:	ec5e                	sd	s7,24(sp)
    8000322c:	e862                	sd	s8,16(sp)
    8000322e:	e466                	sd	s9,8(sp)
    80003230:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003232:	0001c797          	auipc	a5,0x1c
    80003236:	eda7a783          	lw	a5,-294(a5) # 8001f10c <sb+0x4>
    8000323a:	cff5                	beqz	a5,80003336 <balloc+0x11e>
    8000323c:	8baa                	mv	s7,a0
    8000323e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003240:	0001cb17          	auipc	s6,0x1c
    80003244:	ec8b0b13          	addi	s6,s6,-312 # 8001f108 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003248:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000324a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000324c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000324e:	6c89                	lui	s9,0x2
    80003250:	a061                	j	800032d8 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003252:	97ca                	add	a5,a5,s2
    80003254:	8e55                	or	a2,a2,a3
    80003256:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000325a:	854a                	mv	a0,s2
    8000325c:	00001097          	auipc	ra,0x1
    80003260:	084080e7          	jalr	132(ra) # 800042e0 <log_write>
        brelse(bp);
    80003264:	854a                	mv	a0,s2
    80003266:	00000097          	auipc	ra,0x0
    8000326a:	e22080e7          	jalr	-478(ra) # 80003088 <brelse>
  bp = bread(dev, bno);
    8000326e:	85a6                	mv	a1,s1
    80003270:	855e                	mv	a0,s7
    80003272:	00000097          	auipc	ra,0x0
    80003276:	ce6080e7          	jalr	-794(ra) # 80002f58 <bread>
    8000327a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000327c:	40000613          	li	a2,1024
    80003280:	4581                	li	a1,0
    80003282:	05850513          	addi	a0,a0,88
    80003286:	ffffe097          	auipc	ra,0xffffe
    8000328a:	a48080e7          	jalr	-1464(ra) # 80000cce <memset>
  log_write(bp);
    8000328e:	854a                	mv	a0,s2
    80003290:	00001097          	auipc	ra,0x1
    80003294:	050080e7          	jalr	80(ra) # 800042e0 <log_write>
  brelse(bp);
    80003298:	854a                	mv	a0,s2
    8000329a:	00000097          	auipc	ra,0x0
    8000329e:	dee080e7          	jalr	-530(ra) # 80003088 <brelse>
}
    800032a2:	8526                	mv	a0,s1
    800032a4:	60e6                	ld	ra,88(sp)
    800032a6:	6446                	ld	s0,80(sp)
    800032a8:	64a6                	ld	s1,72(sp)
    800032aa:	6906                	ld	s2,64(sp)
    800032ac:	79e2                	ld	s3,56(sp)
    800032ae:	7a42                	ld	s4,48(sp)
    800032b0:	7aa2                	ld	s5,40(sp)
    800032b2:	7b02                	ld	s6,32(sp)
    800032b4:	6be2                	ld	s7,24(sp)
    800032b6:	6c42                	ld	s8,16(sp)
    800032b8:	6ca2                	ld	s9,8(sp)
    800032ba:	6125                	addi	sp,sp,96
    800032bc:	8082                	ret
    brelse(bp);
    800032be:	854a                	mv	a0,s2
    800032c0:	00000097          	auipc	ra,0x0
    800032c4:	dc8080e7          	jalr	-568(ra) # 80003088 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032c8:	015c87bb          	addw	a5,s9,s5
    800032cc:	00078a9b          	sext.w	s5,a5
    800032d0:	004b2703          	lw	a4,4(s6)
    800032d4:	06eaf163          	bgeu	s5,a4,80003336 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800032d8:	41fad79b          	sraiw	a5,s5,0x1f
    800032dc:	0137d79b          	srliw	a5,a5,0x13
    800032e0:	015787bb          	addw	a5,a5,s5
    800032e4:	40d7d79b          	sraiw	a5,a5,0xd
    800032e8:	01cb2583          	lw	a1,28(s6)
    800032ec:	9dbd                	addw	a1,a1,a5
    800032ee:	855e                	mv	a0,s7
    800032f0:	00000097          	auipc	ra,0x0
    800032f4:	c68080e7          	jalr	-920(ra) # 80002f58 <bread>
    800032f8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032fa:	004b2503          	lw	a0,4(s6)
    800032fe:	000a849b          	sext.w	s1,s5
    80003302:	8762                	mv	a4,s8
    80003304:	faa4fde3          	bgeu	s1,a0,800032be <balloc+0xa6>
      m = 1 << (bi % 8);
    80003308:	00777693          	andi	a3,a4,7
    8000330c:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003310:	41f7579b          	sraiw	a5,a4,0x1f
    80003314:	01d7d79b          	srliw	a5,a5,0x1d
    80003318:	9fb9                	addw	a5,a5,a4
    8000331a:	4037d79b          	sraiw	a5,a5,0x3
    8000331e:	00f90633          	add	a2,s2,a5
    80003322:	05864603          	lbu	a2,88(a2)
    80003326:	00c6f5b3          	and	a1,a3,a2
    8000332a:	d585                	beqz	a1,80003252 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000332c:	2705                	addiw	a4,a4,1
    8000332e:	2485                	addiw	s1,s1,1
    80003330:	fd471ae3          	bne	a4,s4,80003304 <balloc+0xec>
    80003334:	b769                	j	800032be <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003336:	00005517          	auipc	a0,0x5
    8000333a:	2ea50513          	addi	a0,a0,746 # 80008620 <stateString.0+0x80>
    8000333e:	ffffd097          	auipc	ra,0xffffd
    80003342:	248080e7          	jalr	584(ra) # 80000586 <printf>
  return 0;
    80003346:	4481                	li	s1,0
    80003348:	bfa9                	j	800032a2 <balloc+0x8a>

000000008000334a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000334a:	7179                	addi	sp,sp,-48
    8000334c:	f406                	sd	ra,40(sp)
    8000334e:	f022                	sd	s0,32(sp)
    80003350:	ec26                	sd	s1,24(sp)
    80003352:	e84a                	sd	s2,16(sp)
    80003354:	e44e                	sd	s3,8(sp)
    80003356:	e052                	sd	s4,0(sp)
    80003358:	1800                	addi	s0,sp,48
    8000335a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000335c:	47ad                	li	a5,11
    8000335e:	02b7e863          	bltu	a5,a1,8000338e <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003362:	02059793          	slli	a5,a1,0x20
    80003366:	01e7d593          	srli	a1,a5,0x1e
    8000336a:	00b504b3          	add	s1,a0,a1
    8000336e:	0504a903          	lw	s2,80(s1)
    80003372:	06091e63          	bnez	s2,800033ee <bmap+0xa4>
      addr = balloc(ip->dev);
    80003376:	4108                	lw	a0,0(a0)
    80003378:	00000097          	auipc	ra,0x0
    8000337c:	ea0080e7          	jalr	-352(ra) # 80003218 <balloc>
    80003380:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003384:	06090563          	beqz	s2,800033ee <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003388:	0524a823          	sw	s2,80(s1)
    8000338c:	a08d                	j	800033ee <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000338e:	ff45849b          	addiw	s1,a1,-12
    80003392:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003396:	0ff00793          	li	a5,255
    8000339a:	08e7e563          	bltu	a5,a4,80003424 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000339e:	08052903          	lw	s2,128(a0)
    800033a2:	00091d63          	bnez	s2,800033bc <bmap+0x72>
      addr = balloc(ip->dev);
    800033a6:	4108                	lw	a0,0(a0)
    800033a8:	00000097          	auipc	ra,0x0
    800033ac:	e70080e7          	jalr	-400(ra) # 80003218 <balloc>
    800033b0:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033b4:	02090d63          	beqz	s2,800033ee <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800033b8:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800033bc:	85ca                	mv	a1,s2
    800033be:	0009a503          	lw	a0,0(s3)
    800033c2:	00000097          	auipc	ra,0x0
    800033c6:	b96080e7          	jalr	-1130(ra) # 80002f58 <bread>
    800033ca:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033cc:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033d0:	02049713          	slli	a4,s1,0x20
    800033d4:	01e75593          	srli	a1,a4,0x1e
    800033d8:	00b784b3          	add	s1,a5,a1
    800033dc:	0004a903          	lw	s2,0(s1)
    800033e0:	02090063          	beqz	s2,80003400 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800033e4:	8552                	mv	a0,s4
    800033e6:	00000097          	auipc	ra,0x0
    800033ea:	ca2080e7          	jalr	-862(ra) # 80003088 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033ee:	854a                	mv	a0,s2
    800033f0:	70a2                	ld	ra,40(sp)
    800033f2:	7402                	ld	s0,32(sp)
    800033f4:	64e2                	ld	s1,24(sp)
    800033f6:	6942                	ld	s2,16(sp)
    800033f8:	69a2                	ld	s3,8(sp)
    800033fa:	6a02                	ld	s4,0(sp)
    800033fc:	6145                	addi	sp,sp,48
    800033fe:	8082                	ret
      addr = balloc(ip->dev);
    80003400:	0009a503          	lw	a0,0(s3)
    80003404:	00000097          	auipc	ra,0x0
    80003408:	e14080e7          	jalr	-492(ra) # 80003218 <balloc>
    8000340c:	0005091b          	sext.w	s2,a0
      if(addr){
    80003410:	fc090ae3          	beqz	s2,800033e4 <bmap+0x9a>
        a[bn] = addr;
    80003414:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003418:	8552                	mv	a0,s4
    8000341a:	00001097          	auipc	ra,0x1
    8000341e:	ec6080e7          	jalr	-314(ra) # 800042e0 <log_write>
    80003422:	b7c9                	j	800033e4 <bmap+0x9a>
  panic("bmap: out of range");
    80003424:	00005517          	auipc	a0,0x5
    80003428:	21450513          	addi	a0,a0,532 # 80008638 <stateString.0+0x98>
    8000342c:	ffffd097          	auipc	ra,0xffffd
    80003430:	110080e7          	jalr	272(ra) # 8000053c <panic>

0000000080003434 <iget>:
{
    80003434:	7179                	addi	sp,sp,-48
    80003436:	f406                	sd	ra,40(sp)
    80003438:	f022                	sd	s0,32(sp)
    8000343a:	ec26                	sd	s1,24(sp)
    8000343c:	e84a                	sd	s2,16(sp)
    8000343e:	e44e                	sd	s3,8(sp)
    80003440:	e052                	sd	s4,0(sp)
    80003442:	1800                	addi	s0,sp,48
    80003444:	89aa                	mv	s3,a0
    80003446:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003448:	0001c517          	auipc	a0,0x1c
    8000344c:	ce050513          	addi	a0,a0,-800 # 8001f128 <itable>
    80003450:	ffffd097          	auipc	ra,0xffffd
    80003454:	782080e7          	jalr	1922(ra) # 80000bd2 <acquire>
  empty = 0;
    80003458:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000345a:	0001c497          	auipc	s1,0x1c
    8000345e:	ce648493          	addi	s1,s1,-794 # 8001f140 <itable+0x18>
    80003462:	0001d697          	auipc	a3,0x1d
    80003466:	76e68693          	addi	a3,a3,1902 # 80020bd0 <log>
    8000346a:	a039                	j	80003478 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000346c:	02090b63          	beqz	s2,800034a2 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003470:	08848493          	addi	s1,s1,136
    80003474:	02d48a63          	beq	s1,a3,800034a8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003478:	449c                	lw	a5,8(s1)
    8000347a:	fef059e3          	blez	a5,8000346c <iget+0x38>
    8000347e:	4098                	lw	a4,0(s1)
    80003480:	ff3716e3          	bne	a4,s3,8000346c <iget+0x38>
    80003484:	40d8                	lw	a4,4(s1)
    80003486:	ff4713e3          	bne	a4,s4,8000346c <iget+0x38>
      ip->ref++;
    8000348a:	2785                	addiw	a5,a5,1
    8000348c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000348e:	0001c517          	auipc	a0,0x1c
    80003492:	c9a50513          	addi	a0,a0,-870 # 8001f128 <itable>
    80003496:	ffffd097          	auipc	ra,0xffffd
    8000349a:	7f0080e7          	jalr	2032(ra) # 80000c86 <release>
      return ip;
    8000349e:	8926                	mv	s2,s1
    800034a0:	a03d                	j	800034ce <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034a2:	f7f9                	bnez	a5,80003470 <iget+0x3c>
    800034a4:	8926                	mv	s2,s1
    800034a6:	b7e9                	j	80003470 <iget+0x3c>
  if(empty == 0)
    800034a8:	02090c63          	beqz	s2,800034e0 <iget+0xac>
  ip->dev = dev;
    800034ac:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034b0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034b4:	4785                	li	a5,1
    800034b6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034ba:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034be:	0001c517          	auipc	a0,0x1c
    800034c2:	c6a50513          	addi	a0,a0,-918 # 8001f128 <itable>
    800034c6:	ffffd097          	auipc	ra,0xffffd
    800034ca:	7c0080e7          	jalr	1984(ra) # 80000c86 <release>
}
    800034ce:	854a                	mv	a0,s2
    800034d0:	70a2                	ld	ra,40(sp)
    800034d2:	7402                	ld	s0,32(sp)
    800034d4:	64e2                	ld	s1,24(sp)
    800034d6:	6942                	ld	s2,16(sp)
    800034d8:	69a2                	ld	s3,8(sp)
    800034da:	6a02                	ld	s4,0(sp)
    800034dc:	6145                	addi	sp,sp,48
    800034de:	8082                	ret
    panic("iget: no inodes");
    800034e0:	00005517          	auipc	a0,0x5
    800034e4:	17050513          	addi	a0,a0,368 # 80008650 <stateString.0+0xb0>
    800034e8:	ffffd097          	auipc	ra,0xffffd
    800034ec:	054080e7          	jalr	84(ra) # 8000053c <panic>

00000000800034f0 <fsinit>:
fsinit(int dev) {
    800034f0:	7179                	addi	sp,sp,-48
    800034f2:	f406                	sd	ra,40(sp)
    800034f4:	f022                	sd	s0,32(sp)
    800034f6:	ec26                	sd	s1,24(sp)
    800034f8:	e84a                	sd	s2,16(sp)
    800034fa:	e44e                	sd	s3,8(sp)
    800034fc:	1800                	addi	s0,sp,48
    800034fe:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003500:	4585                	li	a1,1
    80003502:	00000097          	auipc	ra,0x0
    80003506:	a56080e7          	jalr	-1450(ra) # 80002f58 <bread>
    8000350a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000350c:	0001c997          	auipc	s3,0x1c
    80003510:	bfc98993          	addi	s3,s3,-1028 # 8001f108 <sb>
    80003514:	02000613          	li	a2,32
    80003518:	05850593          	addi	a1,a0,88
    8000351c:	854e                	mv	a0,s3
    8000351e:	ffffe097          	auipc	ra,0xffffe
    80003522:	80c080e7          	jalr	-2036(ra) # 80000d2a <memmove>
  brelse(bp);
    80003526:	8526                	mv	a0,s1
    80003528:	00000097          	auipc	ra,0x0
    8000352c:	b60080e7          	jalr	-1184(ra) # 80003088 <brelse>
  if(sb.magic != FSMAGIC)
    80003530:	0009a703          	lw	a4,0(s3)
    80003534:	102037b7          	lui	a5,0x10203
    80003538:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000353c:	02f71263          	bne	a4,a5,80003560 <fsinit+0x70>
  initlog(dev, &sb);
    80003540:	0001c597          	auipc	a1,0x1c
    80003544:	bc858593          	addi	a1,a1,-1080 # 8001f108 <sb>
    80003548:	854a                	mv	a0,s2
    8000354a:	00001097          	auipc	ra,0x1
    8000354e:	b2c080e7          	jalr	-1236(ra) # 80004076 <initlog>
}
    80003552:	70a2                	ld	ra,40(sp)
    80003554:	7402                	ld	s0,32(sp)
    80003556:	64e2                	ld	s1,24(sp)
    80003558:	6942                	ld	s2,16(sp)
    8000355a:	69a2                	ld	s3,8(sp)
    8000355c:	6145                	addi	sp,sp,48
    8000355e:	8082                	ret
    panic("invalid file system");
    80003560:	00005517          	auipc	a0,0x5
    80003564:	10050513          	addi	a0,a0,256 # 80008660 <stateString.0+0xc0>
    80003568:	ffffd097          	auipc	ra,0xffffd
    8000356c:	fd4080e7          	jalr	-44(ra) # 8000053c <panic>

0000000080003570 <iinit>:
{
    80003570:	7179                	addi	sp,sp,-48
    80003572:	f406                	sd	ra,40(sp)
    80003574:	f022                	sd	s0,32(sp)
    80003576:	ec26                	sd	s1,24(sp)
    80003578:	e84a                	sd	s2,16(sp)
    8000357a:	e44e                	sd	s3,8(sp)
    8000357c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000357e:	00005597          	auipc	a1,0x5
    80003582:	0fa58593          	addi	a1,a1,250 # 80008678 <stateString.0+0xd8>
    80003586:	0001c517          	auipc	a0,0x1c
    8000358a:	ba250513          	addi	a0,a0,-1118 # 8001f128 <itable>
    8000358e:	ffffd097          	auipc	ra,0xffffd
    80003592:	5b4080e7          	jalr	1460(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003596:	0001c497          	auipc	s1,0x1c
    8000359a:	bba48493          	addi	s1,s1,-1094 # 8001f150 <itable+0x28>
    8000359e:	0001d997          	auipc	s3,0x1d
    800035a2:	64298993          	addi	s3,s3,1602 # 80020be0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035a6:	00005917          	auipc	s2,0x5
    800035aa:	0da90913          	addi	s2,s2,218 # 80008680 <stateString.0+0xe0>
    800035ae:	85ca                	mv	a1,s2
    800035b0:	8526                	mv	a0,s1
    800035b2:	00001097          	auipc	ra,0x1
    800035b6:	e12080e7          	jalr	-494(ra) # 800043c4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035ba:	08848493          	addi	s1,s1,136
    800035be:	ff3498e3          	bne	s1,s3,800035ae <iinit+0x3e>
}
    800035c2:	70a2                	ld	ra,40(sp)
    800035c4:	7402                	ld	s0,32(sp)
    800035c6:	64e2                	ld	s1,24(sp)
    800035c8:	6942                	ld	s2,16(sp)
    800035ca:	69a2                	ld	s3,8(sp)
    800035cc:	6145                	addi	sp,sp,48
    800035ce:	8082                	ret

00000000800035d0 <ialloc>:
{
    800035d0:	7139                	addi	sp,sp,-64
    800035d2:	fc06                	sd	ra,56(sp)
    800035d4:	f822                	sd	s0,48(sp)
    800035d6:	f426                	sd	s1,40(sp)
    800035d8:	f04a                	sd	s2,32(sp)
    800035da:	ec4e                	sd	s3,24(sp)
    800035dc:	e852                	sd	s4,16(sp)
    800035de:	e456                	sd	s5,8(sp)
    800035e0:	e05a                	sd	s6,0(sp)
    800035e2:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800035e4:	0001c717          	auipc	a4,0x1c
    800035e8:	b3072703          	lw	a4,-1232(a4) # 8001f114 <sb+0xc>
    800035ec:	4785                	li	a5,1
    800035ee:	04e7f863          	bgeu	a5,a4,8000363e <ialloc+0x6e>
    800035f2:	8aaa                	mv	s5,a0
    800035f4:	8b2e                	mv	s6,a1
    800035f6:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035f8:	0001ca17          	auipc	s4,0x1c
    800035fc:	b10a0a13          	addi	s4,s4,-1264 # 8001f108 <sb>
    80003600:	00495593          	srli	a1,s2,0x4
    80003604:	018a2783          	lw	a5,24(s4)
    80003608:	9dbd                	addw	a1,a1,a5
    8000360a:	8556                	mv	a0,s5
    8000360c:	00000097          	auipc	ra,0x0
    80003610:	94c080e7          	jalr	-1716(ra) # 80002f58 <bread>
    80003614:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003616:	05850993          	addi	s3,a0,88
    8000361a:	00f97793          	andi	a5,s2,15
    8000361e:	079a                	slli	a5,a5,0x6
    80003620:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003622:	00099783          	lh	a5,0(s3)
    80003626:	cf9d                	beqz	a5,80003664 <ialloc+0x94>
    brelse(bp);
    80003628:	00000097          	auipc	ra,0x0
    8000362c:	a60080e7          	jalr	-1440(ra) # 80003088 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003630:	0905                	addi	s2,s2,1
    80003632:	00ca2703          	lw	a4,12(s4)
    80003636:	0009079b          	sext.w	a5,s2
    8000363a:	fce7e3e3          	bltu	a5,a4,80003600 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    8000363e:	00005517          	auipc	a0,0x5
    80003642:	04a50513          	addi	a0,a0,74 # 80008688 <stateString.0+0xe8>
    80003646:	ffffd097          	auipc	ra,0xffffd
    8000364a:	f40080e7          	jalr	-192(ra) # 80000586 <printf>
  return 0;
    8000364e:	4501                	li	a0,0
}
    80003650:	70e2                	ld	ra,56(sp)
    80003652:	7442                	ld	s0,48(sp)
    80003654:	74a2                	ld	s1,40(sp)
    80003656:	7902                	ld	s2,32(sp)
    80003658:	69e2                	ld	s3,24(sp)
    8000365a:	6a42                	ld	s4,16(sp)
    8000365c:	6aa2                	ld	s5,8(sp)
    8000365e:	6b02                	ld	s6,0(sp)
    80003660:	6121                	addi	sp,sp,64
    80003662:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003664:	04000613          	li	a2,64
    80003668:	4581                	li	a1,0
    8000366a:	854e                	mv	a0,s3
    8000366c:	ffffd097          	auipc	ra,0xffffd
    80003670:	662080e7          	jalr	1634(ra) # 80000cce <memset>
      dip->type = type;
    80003674:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003678:	8526                	mv	a0,s1
    8000367a:	00001097          	auipc	ra,0x1
    8000367e:	c66080e7          	jalr	-922(ra) # 800042e0 <log_write>
      brelse(bp);
    80003682:	8526                	mv	a0,s1
    80003684:	00000097          	auipc	ra,0x0
    80003688:	a04080e7          	jalr	-1532(ra) # 80003088 <brelse>
      return iget(dev, inum);
    8000368c:	0009059b          	sext.w	a1,s2
    80003690:	8556                	mv	a0,s5
    80003692:	00000097          	auipc	ra,0x0
    80003696:	da2080e7          	jalr	-606(ra) # 80003434 <iget>
    8000369a:	bf5d                	j	80003650 <ialloc+0x80>

000000008000369c <iupdate>:
{
    8000369c:	1101                	addi	sp,sp,-32
    8000369e:	ec06                	sd	ra,24(sp)
    800036a0:	e822                	sd	s0,16(sp)
    800036a2:	e426                	sd	s1,8(sp)
    800036a4:	e04a                	sd	s2,0(sp)
    800036a6:	1000                	addi	s0,sp,32
    800036a8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036aa:	415c                	lw	a5,4(a0)
    800036ac:	0047d79b          	srliw	a5,a5,0x4
    800036b0:	0001c597          	auipc	a1,0x1c
    800036b4:	a705a583          	lw	a1,-1424(a1) # 8001f120 <sb+0x18>
    800036b8:	9dbd                	addw	a1,a1,a5
    800036ba:	4108                	lw	a0,0(a0)
    800036bc:	00000097          	auipc	ra,0x0
    800036c0:	89c080e7          	jalr	-1892(ra) # 80002f58 <bread>
    800036c4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036c6:	05850793          	addi	a5,a0,88
    800036ca:	40d8                	lw	a4,4(s1)
    800036cc:	8b3d                	andi	a4,a4,15
    800036ce:	071a                	slli	a4,a4,0x6
    800036d0:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800036d2:	04449703          	lh	a4,68(s1)
    800036d6:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800036da:	04649703          	lh	a4,70(s1)
    800036de:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800036e2:	04849703          	lh	a4,72(s1)
    800036e6:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800036ea:	04a49703          	lh	a4,74(s1)
    800036ee:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800036f2:	44f8                	lw	a4,76(s1)
    800036f4:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036f6:	03400613          	li	a2,52
    800036fa:	05048593          	addi	a1,s1,80
    800036fe:	00c78513          	addi	a0,a5,12
    80003702:	ffffd097          	auipc	ra,0xffffd
    80003706:	628080e7          	jalr	1576(ra) # 80000d2a <memmove>
  log_write(bp);
    8000370a:	854a                	mv	a0,s2
    8000370c:	00001097          	auipc	ra,0x1
    80003710:	bd4080e7          	jalr	-1068(ra) # 800042e0 <log_write>
  brelse(bp);
    80003714:	854a                	mv	a0,s2
    80003716:	00000097          	auipc	ra,0x0
    8000371a:	972080e7          	jalr	-1678(ra) # 80003088 <brelse>
}
    8000371e:	60e2                	ld	ra,24(sp)
    80003720:	6442                	ld	s0,16(sp)
    80003722:	64a2                	ld	s1,8(sp)
    80003724:	6902                	ld	s2,0(sp)
    80003726:	6105                	addi	sp,sp,32
    80003728:	8082                	ret

000000008000372a <idup>:
{
    8000372a:	1101                	addi	sp,sp,-32
    8000372c:	ec06                	sd	ra,24(sp)
    8000372e:	e822                	sd	s0,16(sp)
    80003730:	e426                	sd	s1,8(sp)
    80003732:	1000                	addi	s0,sp,32
    80003734:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003736:	0001c517          	auipc	a0,0x1c
    8000373a:	9f250513          	addi	a0,a0,-1550 # 8001f128 <itable>
    8000373e:	ffffd097          	auipc	ra,0xffffd
    80003742:	494080e7          	jalr	1172(ra) # 80000bd2 <acquire>
  ip->ref++;
    80003746:	449c                	lw	a5,8(s1)
    80003748:	2785                	addiw	a5,a5,1
    8000374a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000374c:	0001c517          	auipc	a0,0x1c
    80003750:	9dc50513          	addi	a0,a0,-1572 # 8001f128 <itable>
    80003754:	ffffd097          	auipc	ra,0xffffd
    80003758:	532080e7          	jalr	1330(ra) # 80000c86 <release>
}
    8000375c:	8526                	mv	a0,s1
    8000375e:	60e2                	ld	ra,24(sp)
    80003760:	6442                	ld	s0,16(sp)
    80003762:	64a2                	ld	s1,8(sp)
    80003764:	6105                	addi	sp,sp,32
    80003766:	8082                	ret

0000000080003768 <ilock>:
{
    80003768:	1101                	addi	sp,sp,-32
    8000376a:	ec06                	sd	ra,24(sp)
    8000376c:	e822                	sd	s0,16(sp)
    8000376e:	e426                	sd	s1,8(sp)
    80003770:	e04a                	sd	s2,0(sp)
    80003772:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003774:	c115                	beqz	a0,80003798 <ilock+0x30>
    80003776:	84aa                	mv	s1,a0
    80003778:	451c                	lw	a5,8(a0)
    8000377a:	00f05f63          	blez	a5,80003798 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000377e:	0541                	addi	a0,a0,16
    80003780:	00001097          	auipc	ra,0x1
    80003784:	c7e080e7          	jalr	-898(ra) # 800043fe <acquiresleep>
  if(ip->valid == 0){
    80003788:	40bc                	lw	a5,64(s1)
    8000378a:	cf99                	beqz	a5,800037a8 <ilock+0x40>
}
    8000378c:	60e2                	ld	ra,24(sp)
    8000378e:	6442                	ld	s0,16(sp)
    80003790:	64a2                	ld	s1,8(sp)
    80003792:	6902                	ld	s2,0(sp)
    80003794:	6105                	addi	sp,sp,32
    80003796:	8082                	ret
    panic("ilock");
    80003798:	00005517          	auipc	a0,0x5
    8000379c:	f0850513          	addi	a0,a0,-248 # 800086a0 <stateString.0+0x100>
    800037a0:	ffffd097          	auipc	ra,0xffffd
    800037a4:	d9c080e7          	jalr	-612(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037a8:	40dc                	lw	a5,4(s1)
    800037aa:	0047d79b          	srliw	a5,a5,0x4
    800037ae:	0001c597          	auipc	a1,0x1c
    800037b2:	9725a583          	lw	a1,-1678(a1) # 8001f120 <sb+0x18>
    800037b6:	9dbd                	addw	a1,a1,a5
    800037b8:	4088                	lw	a0,0(s1)
    800037ba:	fffff097          	auipc	ra,0xfffff
    800037be:	79e080e7          	jalr	1950(ra) # 80002f58 <bread>
    800037c2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037c4:	05850593          	addi	a1,a0,88
    800037c8:	40dc                	lw	a5,4(s1)
    800037ca:	8bbd                	andi	a5,a5,15
    800037cc:	079a                	slli	a5,a5,0x6
    800037ce:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037d0:	00059783          	lh	a5,0(a1)
    800037d4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037d8:	00259783          	lh	a5,2(a1)
    800037dc:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037e0:	00459783          	lh	a5,4(a1)
    800037e4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037e8:	00659783          	lh	a5,6(a1)
    800037ec:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037f0:	459c                	lw	a5,8(a1)
    800037f2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037f4:	03400613          	li	a2,52
    800037f8:	05b1                	addi	a1,a1,12
    800037fa:	05048513          	addi	a0,s1,80
    800037fe:	ffffd097          	auipc	ra,0xffffd
    80003802:	52c080e7          	jalr	1324(ra) # 80000d2a <memmove>
    brelse(bp);
    80003806:	854a                	mv	a0,s2
    80003808:	00000097          	auipc	ra,0x0
    8000380c:	880080e7          	jalr	-1920(ra) # 80003088 <brelse>
    ip->valid = 1;
    80003810:	4785                	li	a5,1
    80003812:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003814:	04449783          	lh	a5,68(s1)
    80003818:	fbb5                	bnez	a5,8000378c <ilock+0x24>
      panic("ilock: no type");
    8000381a:	00005517          	auipc	a0,0x5
    8000381e:	e8e50513          	addi	a0,a0,-370 # 800086a8 <stateString.0+0x108>
    80003822:	ffffd097          	auipc	ra,0xffffd
    80003826:	d1a080e7          	jalr	-742(ra) # 8000053c <panic>

000000008000382a <iunlock>:
{
    8000382a:	1101                	addi	sp,sp,-32
    8000382c:	ec06                	sd	ra,24(sp)
    8000382e:	e822                	sd	s0,16(sp)
    80003830:	e426                	sd	s1,8(sp)
    80003832:	e04a                	sd	s2,0(sp)
    80003834:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003836:	c905                	beqz	a0,80003866 <iunlock+0x3c>
    80003838:	84aa                	mv	s1,a0
    8000383a:	01050913          	addi	s2,a0,16
    8000383e:	854a                	mv	a0,s2
    80003840:	00001097          	auipc	ra,0x1
    80003844:	c58080e7          	jalr	-936(ra) # 80004498 <holdingsleep>
    80003848:	cd19                	beqz	a0,80003866 <iunlock+0x3c>
    8000384a:	449c                	lw	a5,8(s1)
    8000384c:	00f05d63          	blez	a5,80003866 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003850:	854a                	mv	a0,s2
    80003852:	00001097          	auipc	ra,0x1
    80003856:	c02080e7          	jalr	-1022(ra) # 80004454 <releasesleep>
}
    8000385a:	60e2                	ld	ra,24(sp)
    8000385c:	6442                	ld	s0,16(sp)
    8000385e:	64a2                	ld	s1,8(sp)
    80003860:	6902                	ld	s2,0(sp)
    80003862:	6105                	addi	sp,sp,32
    80003864:	8082                	ret
    panic("iunlock");
    80003866:	00005517          	auipc	a0,0x5
    8000386a:	e5250513          	addi	a0,a0,-430 # 800086b8 <stateString.0+0x118>
    8000386e:	ffffd097          	auipc	ra,0xffffd
    80003872:	cce080e7          	jalr	-818(ra) # 8000053c <panic>

0000000080003876 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003876:	7179                	addi	sp,sp,-48
    80003878:	f406                	sd	ra,40(sp)
    8000387a:	f022                	sd	s0,32(sp)
    8000387c:	ec26                	sd	s1,24(sp)
    8000387e:	e84a                	sd	s2,16(sp)
    80003880:	e44e                	sd	s3,8(sp)
    80003882:	e052                	sd	s4,0(sp)
    80003884:	1800                	addi	s0,sp,48
    80003886:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003888:	05050493          	addi	s1,a0,80
    8000388c:	08050913          	addi	s2,a0,128
    80003890:	a021                	j	80003898 <itrunc+0x22>
    80003892:	0491                	addi	s1,s1,4
    80003894:	01248d63          	beq	s1,s2,800038ae <itrunc+0x38>
    if(ip->addrs[i]){
    80003898:	408c                	lw	a1,0(s1)
    8000389a:	dde5                	beqz	a1,80003892 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000389c:	0009a503          	lw	a0,0(s3)
    800038a0:	00000097          	auipc	ra,0x0
    800038a4:	8fc080e7          	jalr	-1796(ra) # 8000319c <bfree>
      ip->addrs[i] = 0;
    800038a8:	0004a023          	sw	zero,0(s1)
    800038ac:	b7dd                	j	80003892 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038ae:	0809a583          	lw	a1,128(s3)
    800038b2:	e185                	bnez	a1,800038d2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038b4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038b8:	854e                	mv	a0,s3
    800038ba:	00000097          	auipc	ra,0x0
    800038be:	de2080e7          	jalr	-542(ra) # 8000369c <iupdate>
}
    800038c2:	70a2                	ld	ra,40(sp)
    800038c4:	7402                	ld	s0,32(sp)
    800038c6:	64e2                	ld	s1,24(sp)
    800038c8:	6942                	ld	s2,16(sp)
    800038ca:	69a2                	ld	s3,8(sp)
    800038cc:	6a02                	ld	s4,0(sp)
    800038ce:	6145                	addi	sp,sp,48
    800038d0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038d2:	0009a503          	lw	a0,0(s3)
    800038d6:	fffff097          	auipc	ra,0xfffff
    800038da:	682080e7          	jalr	1666(ra) # 80002f58 <bread>
    800038de:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038e0:	05850493          	addi	s1,a0,88
    800038e4:	45850913          	addi	s2,a0,1112
    800038e8:	a021                	j	800038f0 <itrunc+0x7a>
    800038ea:	0491                	addi	s1,s1,4
    800038ec:	01248b63          	beq	s1,s2,80003902 <itrunc+0x8c>
      if(a[j])
    800038f0:	408c                	lw	a1,0(s1)
    800038f2:	dde5                	beqz	a1,800038ea <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800038f4:	0009a503          	lw	a0,0(s3)
    800038f8:	00000097          	auipc	ra,0x0
    800038fc:	8a4080e7          	jalr	-1884(ra) # 8000319c <bfree>
    80003900:	b7ed                	j	800038ea <itrunc+0x74>
    brelse(bp);
    80003902:	8552                	mv	a0,s4
    80003904:	fffff097          	auipc	ra,0xfffff
    80003908:	784080e7          	jalr	1924(ra) # 80003088 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000390c:	0809a583          	lw	a1,128(s3)
    80003910:	0009a503          	lw	a0,0(s3)
    80003914:	00000097          	auipc	ra,0x0
    80003918:	888080e7          	jalr	-1912(ra) # 8000319c <bfree>
    ip->addrs[NDIRECT] = 0;
    8000391c:	0809a023          	sw	zero,128(s3)
    80003920:	bf51                	j	800038b4 <itrunc+0x3e>

0000000080003922 <iput>:
{
    80003922:	1101                	addi	sp,sp,-32
    80003924:	ec06                	sd	ra,24(sp)
    80003926:	e822                	sd	s0,16(sp)
    80003928:	e426                	sd	s1,8(sp)
    8000392a:	e04a                	sd	s2,0(sp)
    8000392c:	1000                	addi	s0,sp,32
    8000392e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003930:	0001b517          	auipc	a0,0x1b
    80003934:	7f850513          	addi	a0,a0,2040 # 8001f128 <itable>
    80003938:	ffffd097          	auipc	ra,0xffffd
    8000393c:	29a080e7          	jalr	666(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003940:	4498                	lw	a4,8(s1)
    80003942:	4785                	li	a5,1
    80003944:	02f70363          	beq	a4,a5,8000396a <iput+0x48>
  ip->ref--;
    80003948:	449c                	lw	a5,8(s1)
    8000394a:	37fd                	addiw	a5,a5,-1
    8000394c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000394e:	0001b517          	auipc	a0,0x1b
    80003952:	7da50513          	addi	a0,a0,2010 # 8001f128 <itable>
    80003956:	ffffd097          	auipc	ra,0xffffd
    8000395a:	330080e7          	jalr	816(ra) # 80000c86 <release>
}
    8000395e:	60e2                	ld	ra,24(sp)
    80003960:	6442                	ld	s0,16(sp)
    80003962:	64a2                	ld	s1,8(sp)
    80003964:	6902                	ld	s2,0(sp)
    80003966:	6105                	addi	sp,sp,32
    80003968:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000396a:	40bc                	lw	a5,64(s1)
    8000396c:	dff1                	beqz	a5,80003948 <iput+0x26>
    8000396e:	04a49783          	lh	a5,74(s1)
    80003972:	fbf9                	bnez	a5,80003948 <iput+0x26>
    acquiresleep(&ip->lock);
    80003974:	01048913          	addi	s2,s1,16
    80003978:	854a                	mv	a0,s2
    8000397a:	00001097          	auipc	ra,0x1
    8000397e:	a84080e7          	jalr	-1404(ra) # 800043fe <acquiresleep>
    release(&itable.lock);
    80003982:	0001b517          	auipc	a0,0x1b
    80003986:	7a650513          	addi	a0,a0,1958 # 8001f128 <itable>
    8000398a:	ffffd097          	auipc	ra,0xffffd
    8000398e:	2fc080e7          	jalr	764(ra) # 80000c86 <release>
    itrunc(ip);
    80003992:	8526                	mv	a0,s1
    80003994:	00000097          	auipc	ra,0x0
    80003998:	ee2080e7          	jalr	-286(ra) # 80003876 <itrunc>
    ip->type = 0;
    8000399c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039a0:	8526                	mv	a0,s1
    800039a2:	00000097          	auipc	ra,0x0
    800039a6:	cfa080e7          	jalr	-774(ra) # 8000369c <iupdate>
    ip->valid = 0;
    800039aa:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039ae:	854a                	mv	a0,s2
    800039b0:	00001097          	auipc	ra,0x1
    800039b4:	aa4080e7          	jalr	-1372(ra) # 80004454 <releasesleep>
    acquire(&itable.lock);
    800039b8:	0001b517          	auipc	a0,0x1b
    800039bc:	77050513          	addi	a0,a0,1904 # 8001f128 <itable>
    800039c0:	ffffd097          	auipc	ra,0xffffd
    800039c4:	212080e7          	jalr	530(ra) # 80000bd2 <acquire>
    800039c8:	b741                	j	80003948 <iput+0x26>

00000000800039ca <iunlockput>:
{
    800039ca:	1101                	addi	sp,sp,-32
    800039cc:	ec06                	sd	ra,24(sp)
    800039ce:	e822                	sd	s0,16(sp)
    800039d0:	e426                	sd	s1,8(sp)
    800039d2:	1000                	addi	s0,sp,32
    800039d4:	84aa                	mv	s1,a0
  iunlock(ip);
    800039d6:	00000097          	auipc	ra,0x0
    800039da:	e54080e7          	jalr	-428(ra) # 8000382a <iunlock>
  iput(ip);
    800039de:	8526                	mv	a0,s1
    800039e0:	00000097          	auipc	ra,0x0
    800039e4:	f42080e7          	jalr	-190(ra) # 80003922 <iput>
}
    800039e8:	60e2                	ld	ra,24(sp)
    800039ea:	6442                	ld	s0,16(sp)
    800039ec:	64a2                	ld	s1,8(sp)
    800039ee:	6105                	addi	sp,sp,32
    800039f0:	8082                	ret

00000000800039f2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039f2:	1141                	addi	sp,sp,-16
    800039f4:	e422                	sd	s0,8(sp)
    800039f6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039f8:	411c                	lw	a5,0(a0)
    800039fa:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039fc:	415c                	lw	a5,4(a0)
    800039fe:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a00:	04451783          	lh	a5,68(a0)
    80003a04:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a08:	04a51783          	lh	a5,74(a0)
    80003a0c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a10:	04c56783          	lwu	a5,76(a0)
    80003a14:	e99c                	sd	a5,16(a1)
}
    80003a16:	6422                	ld	s0,8(sp)
    80003a18:	0141                	addi	sp,sp,16
    80003a1a:	8082                	ret

0000000080003a1c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a1c:	457c                	lw	a5,76(a0)
    80003a1e:	0ed7e963          	bltu	a5,a3,80003b10 <readi+0xf4>
{
    80003a22:	7159                	addi	sp,sp,-112
    80003a24:	f486                	sd	ra,104(sp)
    80003a26:	f0a2                	sd	s0,96(sp)
    80003a28:	eca6                	sd	s1,88(sp)
    80003a2a:	e8ca                	sd	s2,80(sp)
    80003a2c:	e4ce                	sd	s3,72(sp)
    80003a2e:	e0d2                	sd	s4,64(sp)
    80003a30:	fc56                	sd	s5,56(sp)
    80003a32:	f85a                	sd	s6,48(sp)
    80003a34:	f45e                	sd	s7,40(sp)
    80003a36:	f062                	sd	s8,32(sp)
    80003a38:	ec66                	sd	s9,24(sp)
    80003a3a:	e86a                	sd	s10,16(sp)
    80003a3c:	e46e                	sd	s11,8(sp)
    80003a3e:	1880                	addi	s0,sp,112
    80003a40:	8b2a                	mv	s6,a0
    80003a42:	8bae                	mv	s7,a1
    80003a44:	8a32                	mv	s4,a2
    80003a46:	84b6                	mv	s1,a3
    80003a48:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a4a:	9f35                	addw	a4,a4,a3
    return 0;
    80003a4c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a4e:	0ad76063          	bltu	a4,a3,80003aee <readi+0xd2>
  if(off + n > ip->size)
    80003a52:	00e7f463          	bgeu	a5,a4,80003a5a <readi+0x3e>
    n = ip->size - off;
    80003a56:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a5a:	0a0a8963          	beqz	s5,80003b0c <readi+0xf0>
    80003a5e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a60:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a64:	5c7d                	li	s8,-1
    80003a66:	a82d                	j	80003aa0 <readi+0x84>
    80003a68:	020d1d93          	slli	s11,s10,0x20
    80003a6c:	020ddd93          	srli	s11,s11,0x20
    80003a70:	05890613          	addi	a2,s2,88
    80003a74:	86ee                	mv	a3,s11
    80003a76:	963a                	add	a2,a2,a4
    80003a78:	85d2                	mv	a1,s4
    80003a7a:	855e                	mv	a0,s7
    80003a7c:	fffff097          	auipc	ra,0xfffff
    80003a80:	9da080e7          	jalr	-1574(ra) # 80002456 <either_copyout>
    80003a84:	05850d63          	beq	a0,s8,80003ade <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a88:	854a                	mv	a0,s2
    80003a8a:	fffff097          	auipc	ra,0xfffff
    80003a8e:	5fe080e7          	jalr	1534(ra) # 80003088 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a92:	013d09bb          	addw	s3,s10,s3
    80003a96:	009d04bb          	addw	s1,s10,s1
    80003a9a:	9a6e                	add	s4,s4,s11
    80003a9c:	0559f763          	bgeu	s3,s5,80003aea <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003aa0:	00a4d59b          	srliw	a1,s1,0xa
    80003aa4:	855a                	mv	a0,s6
    80003aa6:	00000097          	auipc	ra,0x0
    80003aaa:	8a4080e7          	jalr	-1884(ra) # 8000334a <bmap>
    80003aae:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003ab2:	cd85                	beqz	a1,80003aea <readi+0xce>
    bp = bread(ip->dev, addr);
    80003ab4:	000b2503          	lw	a0,0(s6)
    80003ab8:	fffff097          	auipc	ra,0xfffff
    80003abc:	4a0080e7          	jalr	1184(ra) # 80002f58 <bread>
    80003ac0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ac2:	3ff4f713          	andi	a4,s1,1023
    80003ac6:	40ec87bb          	subw	a5,s9,a4
    80003aca:	413a86bb          	subw	a3,s5,s3
    80003ace:	8d3e                	mv	s10,a5
    80003ad0:	2781                	sext.w	a5,a5
    80003ad2:	0006861b          	sext.w	a2,a3
    80003ad6:	f8f679e3          	bgeu	a2,a5,80003a68 <readi+0x4c>
    80003ada:	8d36                	mv	s10,a3
    80003adc:	b771                	j	80003a68 <readi+0x4c>
      brelse(bp);
    80003ade:	854a                	mv	a0,s2
    80003ae0:	fffff097          	auipc	ra,0xfffff
    80003ae4:	5a8080e7          	jalr	1448(ra) # 80003088 <brelse>
      tot = -1;
    80003ae8:	59fd                	li	s3,-1
  }
  return tot;
    80003aea:	0009851b          	sext.w	a0,s3
}
    80003aee:	70a6                	ld	ra,104(sp)
    80003af0:	7406                	ld	s0,96(sp)
    80003af2:	64e6                	ld	s1,88(sp)
    80003af4:	6946                	ld	s2,80(sp)
    80003af6:	69a6                	ld	s3,72(sp)
    80003af8:	6a06                	ld	s4,64(sp)
    80003afa:	7ae2                	ld	s5,56(sp)
    80003afc:	7b42                	ld	s6,48(sp)
    80003afe:	7ba2                	ld	s7,40(sp)
    80003b00:	7c02                	ld	s8,32(sp)
    80003b02:	6ce2                	ld	s9,24(sp)
    80003b04:	6d42                	ld	s10,16(sp)
    80003b06:	6da2                	ld	s11,8(sp)
    80003b08:	6165                	addi	sp,sp,112
    80003b0a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b0c:	89d6                	mv	s3,s5
    80003b0e:	bff1                	j	80003aea <readi+0xce>
    return 0;
    80003b10:	4501                	li	a0,0
}
    80003b12:	8082                	ret

0000000080003b14 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b14:	457c                	lw	a5,76(a0)
    80003b16:	10d7e863          	bltu	a5,a3,80003c26 <writei+0x112>
{
    80003b1a:	7159                	addi	sp,sp,-112
    80003b1c:	f486                	sd	ra,104(sp)
    80003b1e:	f0a2                	sd	s0,96(sp)
    80003b20:	eca6                	sd	s1,88(sp)
    80003b22:	e8ca                	sd	s2,80(sp)
    80003b24:	e4ce                	sd	s3,72(sp)
    80003b26:	e0d2                	sd	s4,64(sp)
    80003b28:	fc56                	sd	s5,56(sp)
    80003b2a:	f85a                	sd	s6,48(sp)
    80003b2c:	f45e                	sd	s7,40(sp)
    80003b2e:	f062                	sd	s8,32(sp)
    80003b30:	ec66                	sd	s9,24(sp)
    80003b32:	e86a                	sd	s10,16(sp)
    80003b34:	e46e                	sd	s11,8(sp)
    80003b36:	1880                	addi	s0,sp,112
    80003b38:	8aaa                	mv	s5,a0
    80003b3a:	8bae                	mv	s7,a1
    80003b3c:	8a32                	mv	s4,a2
    80003b3e:	8936                	mv	s2,a3
    80003b40:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b42:	00e687bb          	addw	a5,a3,a4
    80003b46:	0ed7e263          	bltu	a5,a3,80003c2a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b4a:	00043737          	lui	a4,0x43
    80003b4e:	0ef76063          	bltu	a4,a5,80003c2e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b52:	0c0b0863          	beqz	s6,80003c22 <writei+0x10e>
    80003b56:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b58:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b5c:	5c7d                	li	s8,-1
    80003b5e:	a091                	j	80003ba2 <writei+0x8e>
    80003b60:	020d1d93          	slli	s11,s10,0x20
    80003b64:	020ddd93          	srli	s11,s11,0x20
    80003b68:	05848513          	addi	a0,s1,88
    80003b6c:	86ee                	mv	a3,s11
    80003b6e:	8652                	mv	a2,s4
    80003b70:	85de                	mv	a1,s7
    80003b72:	953a                	add	a0,a0,a4
    80003b74:	fffff097          	auipc	ra,0xfffff
    80003b78:	938080e7          	jalr	-1736(ra) # 800024ac <either_copyin>
    80003b7c:	07850263          	beq	a0,s8,80003be0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b80:	8526                	mv	a0,s1
    80003b82:	00000097          	auipc	ra,0x0
    80003b86:	75e080e7          	jalr	1886(ra) # 800042e0 <log_write>
    brelse(bp);
    80003b8a:	8526                	mv	a0,s1
    80003b8c:	fffff097          	auipc	ra,0xfffff
    80003b90:	4fc080e7          	jalr	1276(ra) # 80003088 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b94:	013d09bb          	addw	s3,s10,s3
    80003b98:	012d093b          	addw	s2,s10,s2
    80003b9c:	9a6e                	add	s4,s4,s11
    80003b9e:	0569f663          	bgeu	s3,s6,80003bea <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003ba2:	00a9559b          	srliw	a1,s2,0xa
    80003ba6:	8556                	mv	a0,s5
    80003ba8:	fffff097          	auipc	ra,0xfffff
    80003bac:	7a2080e7          	jalr	1954(ra) # 8000334a <bmap>
    80003bb0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003bb4:	c99d                	beqz	a1,80003bea <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003bb6:	000aa503          	lw	a0,0(s5)
    80003bba:	fffff097          	auipc	ra,0xfffff
    80003bbe:	39e080e7          	jalr	926(ra) # 80002f58 <bread>
    80003bc2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bc4:	3ff97713          	andi	a4,s2,1023
    80003bc8:	40ec87bb          	subw	a5,s9,a4
    80003bcc:	413b06bb          	subw	a3,s6,s3
    80003bd0:	8d3e                	mv	s10,a5
    80003bd2:	2781                	sext.w	a5,a5
    80003bd4:	0006861b          	sext.w	a2,a3
    80003bd8:	f8f674e3          	bgeu	a2,a5,80003b60 <writei+0x4c>
    80003bdc:	8d36                	mv	s10,a3
    80003bde:	b749                	j	80003b60 <writei+0x4c>
      brelse(bp);
    80003be0:	8526                	mv	a0,s1
    80003be2:	fffff097          	auipc	ra,0xfffff
    80003be6:	4a6080e7          	jalr	1190(ra) # 80003088 <brelse>
  }

  if(off > ip->size)
    80003bea:	04caa783          	lw	a5,76(s5)
    80003bee:	0127f463          	bgeu	a5,s2,80003bf6 <writei+0xe2>
    ip->size = off;
    80003bf2:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bf6:	8556                	mv	a0,s5
    80003bf8:	00000097          	auipc	ra,0x0
    80003bfc:	aa4080e7          	jalr	-1372(ra) # 8000369c <iupdate>

  return tot;
    80003c00:	0009851b          	sext.w	a0,s3
}
    80003c04:	70a6                	ld	ra,104(sp)
    80003c06:	7406                	ld	s0,96(sp)
    80003c08:	64e6                	ld	s1,88(sp)
    80003c0a:	6946                	ld	s2,80(sp)
    80003c0c:	69a6                	ld	s3,72(sp)
    80003c0e:	6a06                	ld	s4,64(sp)
    80003c10:	7ae2                	ld	s5,56(sp)
    80003c12:	7b42                	ld	s6,48(sp)
    80003c14:	7ba2                	ld	s7,40(sp)
    80003c16:	7c02                	ld	s8,32(sp)
    80003c18:	6ce2                	ld	s9,24(sp)
    80003c1a:	6d42                	ld	s10,16(sp)
    80003c1c:	6da2                	ld	s11,8(sp)
    80003c1e:	6165                	addi	sp,sp,112
    80003c20:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c22:	89da                	mv	s3,s6
    80003c24:	bfc9                	j	80003bf6 <writei+0xe2>
    return -1;
    80003c26:	557d                	li	a0,-1
}
    80003c28:	8082                	ret
    return -1;
    80003c2a:	557d                	li	a0,-1
    80003c2c:	bfe1                	j	80003c04 <writei+0xf0>
    return -1;
    80003c2e:	557d                	li	a0,-1
    80003c30:	bfd1                	j	80003c04 <writei+0xf0>

0000000080003c32 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c32:	1141                	addi	sp,sp,-16
    80003c34:	e406                	sd	ra,8(sp)
    80003c36:	e022                	sd	s0,0(sp)
    80003c38:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c3a:	4639                	li	a2,14
    80003c3c:	ffffd097          	auipc	ra,0xffffd
    80003c40:	162080e7          	jalr	354(ra) # 80000d9e <strncmp>
}
    80003c44:	60a2                	ld	ra,8(sp)
    80003c46:	6402                	ld	s0,0(sp)
    80003c48:	0141                	addi	sp,sp,16
    80003c4a:	8082                	ret

0000000080003c4c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c4c:	7139                	addi	sp,sp,-64
    80003c4e:	fc06                	sd	ra,56(sp)
    80003c50:	f822                	sd	s0,48(sp)
    80003c52:	f426                	sd	s1,40(sp)
    80003c54:	f04a                	sd	s2,32(sp)
    80003c56:	ec4e                	sd	s3,24(sp)
    80003c58:	e852                	sd	s4,16(sp)
    80003c5a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c5c:	04451703          	lh	a4,68(a0)
    80003c60:	4785                	li	a5,1
    80003c62:	00f71a63          	bne	a4,a5,80003c76 <dirlookup+0x2a>
    80003c66:	892a                	mv	s2,a0
    80003c68:	89ae                	mv	s3,a1
    80003c6a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c6c:	457c                	lw	a5,76(a0)
    80003c6e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c70:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c72:	e79d                	bnez	a5,80003ca0 <dirlookup+0x54>
    80003c74:	a8a5                	j	80003cec <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c76:	00005517          	auipc	a0,0x5
    80003c7a:	a4a50513          	addi	a0,a0,-1462 # 800086c0 <stateString.0+0x120>
    80003c7e:	ffffd097          	auipc	ra,0xffffd
    80003c82:	8be080e7          	jalr	-1858(ra) # 8000053c <panic>
      panic("dirlookup read");
    80003c86:	00005517          	auipc	a0,0x5
    80003c8a:	a5250513          	addi	a0,a0,-1454 # 800086d8 <stateString.0+0x138>
    80003c8e:	ffffd097          	auipc	ra,0xffffd
    80003c92:	8ae080e7          	jalr	-1874(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c96:	24c1                	addiw	s1,s1,16
    80003c98:	04c92783          	lw	a5,76(s2)
    80003c9c:	04f4f763          	bgeu	s1,a5,80003cea <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ca0:	4741                	li	a4,16
    80003ca2:	86a6                	mv	a3,s1
    80003ca4:	fc040613          	addi	a2,s0,-64
    80003ca8:	4581                	li	a1,0
    80003caa:	854a                	mv	a0,s2
    80003cac:	00000097          	auipc	ra,0x0
    80003cb0:	d70080e7          	jalr	-656(ra) # 80003a1c <readi>
    80003cb4:	47c1                	li	a5,16
    80003cb6:	fcf518e3          	bne	a0,a5,80003c86 <dirlookup+0x3a>
    if(de.inum == 0)
    80003cba:	fc045783          	lhu	a5,-64(s0)
    80003cbe:	dfe1                	beqz	a5,80003c96 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cc0:	fc240593          	addi	a1,s0,-62
    80003cc4:	854e                	mv	a0,s3
    80003cc6:	00000097          	auipc	ra,0x0
    80003cca:	f6c080e7          	jalr	-148(ra) # 80003c32 <namecmp>
    80003cce:	f561                	bnez	a0,80003c96 <dirlookup+0x4a>
      if(poff)
    80003cd0:	000a0463          	beqz	s4,80003cd8 <dirlookup+0x8c>
        *poff = off;
    80003cd4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cd8:	fc045583          	lhu	a1,-64(s0)
    80003cdc:	00092503          	lw	a0,0(s2)
    80003ce0:	fffff097          	auipc	ra,0xfffff
    80003ce4:	754080e7          	jalr	1876(ra) # 80003434 <iget>
    80003ce8:	a011                	j	80003cec <dirlookup+0xa0>
  return 0;
    80003cea:	4501                	li	a0,0
}
    80003cec:	70e2                	ld	ra,56(sp)
    80003cee:	7442                	ld	s0,48(sp)
    80003cf0:	74a2                	ld	s1,40(sp)
    80003cf2:	7902                	ld	s2,32(sp)
    80003cf4:	69e2                	ld	s3,24(sp)
    80003cf6:	6a42                	ld	s4,16(sp)
    80003cf8:	6121                	addi	sp,sp,64
    80003cfa:	8082                	ret

0000000080003cfc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cfc:	711d                	addi	sp,sp,-96
    80003cfe:	ec86                	sd	ra,88(sp)
    80003d00:	e8a2                	sd	s0,80(sp)
    80003d02:	e4a6                	sd	s1,72(sp)
    80003d04:	e0ca                	sd	s2,64(sp)
    80003d06:	fc4e                	sd	s3,56(sp)
    80003d08:	f852                	sd	s4,48(sp)
    80003d0a:	f456                	sd	s5,40(sp)
    80003d0c:	f05a                	sd	s6,32(sp)
    80003d0e:	ec5e                	sd	s7,24(sp)
    80003d10:	e862                	sd	s8,16(sp)
    80003d12:	e466                	sd	s9,8(sp)
    80003d14:	1080                	addi	s0,sp,96
    80003d16:	84aa                	mv	s1,a0
    80003d18:	8b2e                	mv	s6,a1
    80003d1a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d1c:	00054703          	lbu	a4,0(a0)
    80003d20:	02f00793          	li	a5,47
    80003d24:	02f70263          	beq	a4,a5,80003d48 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d28:	ffffe097          	auipc	ra,0xffffe
    80003d2c:	c7e080e7          	jalr	-898(ra) # 800019a6 <myproc>
    80003d30:	15053503          	ld	a0,336(a0)
    80003d34:	00000097          	auipc	ra,0x0
    80003d38:	9f6080e7          	jalr	-1546(ra) # 8000372a <idup>
    80003d3c:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003d3e:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003d42:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d44:	4b85                	li	s7,1
    80003d46:	a875                	j	80003e02 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003d48:	4585                	li	a1,1
    80003d4a:	4505                	li	a0,1
    80003d4c:	fffff097          	auipc	ra,0xfffff
    80003d50:	6e8080e7          	jalr	1768(ra) # 80003434 <iget>
    80003d54:	8a2a                	mv	s4,a0
    80003d56:	b7e5                	j	80003d3e <namex+0x42>
      iunlockput(ip);
    80003d58:	8552                	mv	a0,s4
    80003d5a:	00000097          	auipc	ra,0x0
    80003d5e:	c70080e7          	jalr	-912(ra) # 800039ca <iunlockput>
      return 0;
    80003d62:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d64:	8552                	mv	a0,s4
    80003d66:	60e6                	ld	ra,88(sp)
    80003d68:	6446                	ld	s0,80(sp)
    80003d6a:	64a6                	ld	s1,72(sp)
    80003d6c:	6906                	ld	s2,64(sp)
    80003d6e:	79e2                	ld	s3,56(sp)
    80003d70:	7a42                	ld	s4,48(sp)
    80003d72:	7aa2                	ld	s5,40(sp)
    80003d74:	7b02                	ld	s6,32(sp)
    80003d76:	6be2                	ld	s7,24(sp)
    80003d78:	6c42                	ld	s8,16(sp)
    80003d7a:	6ca2                	ld	s9,8(sp)
    80003d7c:	6125                	addi	sp,sp,96
    80003d7e:	8082                	ret
      iunlock(ip);
    80003d80:	8552                	mv	a0,s4
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	aa8080e7          	jalr	-1368(ra) # 8000382a <iunlock>
      return ip;
    80003d8a:	bfe9                	j	80003d64 <namex+0x68>
      iunlockput(ip);
    80003d8c:	8552                	mv	a0,s4
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	c3c080e7          	jalr	-964(ra) # 800039ca <iunlockput>
      return 0;
    80003d96:	8a4e                	mv	s4,s3
    80003d98:	b7f1                	j	80003d64 <namex+0x68>
  len = path - s;
    80003d9a:	40998633          	sub	a2,s3,s1
    80003d9e:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003da2:	099c5863          	bge	s8,s9,80003e32 <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003da6:	4639                	li	a2,14
    80003da8:	85a6                	mv	a1,s1
    80003daa:	8556                	mv	a0,s5
    80003dac:	ffffd097          	auipc	ra,0xffffd
    80003db0:	f7e080e7          	jalr	-130(ra) # 80000d2a <memmove>
    80003db4:	84ce                	mv	s1,s3
  while(*path == '/')
    80003db6:	0004c783          	lbu	a5,0(s1)
    80003dba:	01279763          	bne	a5,s2,80003dc8 <namex+0xcc>
    path++;
    80003dbe:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dc0:	0004c783          	lbu	a5,0(s1)
    80003dc4:	ff278de3          	beq	a5,s2,80003dbe <namex+0xc2>
    ilock(ip);
    80003dc8:	8552                	mv	a0,s4
    80003dca:	00000097          	auipc	ra,0x0
    80003dce:	99e080e7          	jalr	-1634(ra) # 80003768 <ilock>
    if(ip->type != T_DIR){
    80003dd2:	044a1783          	lh	a5,68(s4)
    80003dd6:	f97791e3          	bne	a5,s7,80003d58 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80003dda:	000b0563          	beqz	s6,80003de4 <namex+0xe8>
    80003dde:	0004c783          	lbu	a5,0(s1)
    80003de2:	dfd9                	beqz	a5,80003d80 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003de4:	4601                	li	a2,0
    80003de6:	85d6                	mv	a1,s5
    80003de8:	8552                	mv	a0,s4
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	e62080e7          	jalr	-414(ra) # 80003c4c <dirlookup>
    80003df2:	89aa                	mv	s3,a0
    80003df4:	dd41                	beqz	a0,80003d8c <namex+0x90>
    iunlockput(ip);
    80003df6:	8552                	mv	a0,s4
    80003df8:	00000097          	auipc	ra,0x0
    80003dfc:	bd2080e7          	jalr	-1070(ra) # 800039ca <iunlockput>
    ip = next;
    80003e00:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003e02:	0004c783          	lbu	a5,0(s1)
    80003e06:	01279763          	bne	a5,s2,80003e14 <namex+0x118>
    path++;
    80003e0a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e0c:	0004c783          	lbu	a5,0(s1)
    80003e10:	ff278de3          	beq	a5,s2,80003e0a <namex+0x10e>
  if(*path == 0)
    80003e14:	cb9d                	beqz	a5,80003e4a <namex+0x14e>
  while(*path != '/' && *path != 0)
    80003e16:	0004c783          	lbu	a5,0(s1)
    80003e1a:	89a6                	mv	s3,s1
  len = path - s;
    80003e1c:	4c81                	li	s9,0
    80003e1e:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003e20:	01278963          	beq	a5,s2,80003e32 <namex+0x136>
    80003e24:	dbbd                	beqz	a5,80003d9a <namex+0x9e>
    path++;
    80003e26:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003e28:	0009c783          	lbu	a5,0(s3)
    80003e2c:	ff279ce3          	bne	a5,s2,80003e24 <namex+0x128>
    80003e30:	b7ad                	j	80003d9a <namex+0x9e>
    memmove(name, s, len);
    80003e32:	2601                	sext.w	a2,a2
    80003e34:	85a6                	mv	a1,s1
    80003e36:	8556                	mv	a0,s5
    80003e38:	ffffd097          	auipc	ra,0xffffd
    80003e3c:	ef2080e7          	jalr	-270(ra) # 80000d2a <memmove>
    name[len] = 0;
    80003e40:	9cd6                	add	s9,s9,s5
    80003e42:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003e46:	84ce                	mv	s1,s3
    80003e48:	b7bd                	j	80003db6 <namex+0xba>
  if(nameiparent){
    80003e4a:	f00b0de3          	beqz	s6,80003d64 <namex+0x68>
    iput(ip);
    80003e4e:	8552                	mv	a0,s4
    80003e50:	00000097          	auipc	ra,0x0
    80003e54:	ad2080e7          	jalr	-1326(ra) # 80003922 <iput>
    return 0;
    80003e58:	4a01                	li	s4,0
    80003e5a:	b729                	j	80003d64 <namex+0x68>

0000000080003e5c <dirlink>:
{
    80003e5c:	7139                	addi	sp,sp,-64
    80003e5e:	fc06                	sd	ra,56(sp)
    80003e60:	f822                	sd	s0,48(sp)
    80003e62:	f426                	sd	s1,40(sp)
    80003e64:	f04a                	sd	s2,32(sp)
    80003e66:	ec4e                	sd	s3,24(sp)
    80003e68:	e852                	sd	s4,16(sp)
    80003e6a:	0080                	addi	s0,sp,64
    80003e6c:	892a                	mv	s2,a0
    80003e6e:	8a2e                	mv	s4,a1
    80003e70:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e72:	4601                	li	a2,0
    80003e74:	00000097          	auipc	ra,0x0
    80003e78:	dd8080e7          	jalr	-552(ra) # 80003c4c <dirlookup>
    80003e7c:	e93d                	bnez	a0,80003ef2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e7e:	04c92483          	lw	s1,76(s2)
    80003e82:	c49d                	beqz	s1,80003eb0 <dirlink+0x54>
    80003e84:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e86:	4741                	li	a4,16
    80003e88:	86a6                	mv	a3,s1
    80003e8a:	fc040613          	addi	a2,s0,-64
    80003e8e:	4581                	li	a1,0
    80003e90:	854a                	mv	a0,s2
    80003e92:	00000097          	auipc	ra,0x0
    80003e96:	b8a080e7          	jalr	-1142(ra) # 80003a1c <readi>
    80003e9a:	47c1                	li	a5,16
    80003e9c:	06f51163          	bne	a0,a5,80003efe <dirlink+0xa2>
    if(de.inum == 0)
    80003ea0:	fc045783          	lhu	a5,-64(s0)
    80003ea4:	c791                	beqz	a5,80003eb0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ea6:	24c1                	addiw	s1,s1,16
    80003ea8:	04c92783          	lw	a5,76(s2)
    80003eac:	fcf4ede3          	bltu	s1,a5,80003e86 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003eb0:	4639                	li	a2,14
    80003eb2:	85d2                	mv	a1,s4
    80003eb4:	fc240513          	addi	a0,s0,-62
    80003eb8:	ffffd097          	auipc	ra,0xffffd
    80003ebc:	f22080e7          	jalr	-222(ra) # 80000dda <strncpy>
  de.inum = inum;
    80003ec0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ec4:	4741                	li	a4,16
    80003ec6:	86a6                	mv	a3,s1
    80003ec8:	fc040613          	addi	a2,s0,-64
    80003ecc:	4581                	li	a1,0
    80003ece:	854a                	mv	a0,s2
    80003ed0:	00000097          	auipc	ra,0x0
    80003ed4:	c44080e7          	jalr	-956(ra) # 80003b14 <writei>
    80003ed8:	1541                	addi	a0,a0,-16
    80003eda:	00a03533          	snez	a0,a0
    80003ede:	40a00533          	neg	a0,a0
}
    80003ee2:	70e2                	ld	ra,56(sp)
    80003ee4:	7442                	ld	s0,48(sp)
    80003ee6:	74a2                	ld	s1,40(sp)
    80003ee8:	7902                	ld	s2,32(sp)
    80003eea:	69e2                	ld	s3,24(sp)
    80003eec:	6a42                	ld	s4,16(sp)
    80003eee:	6121                	addi	sp,sp,64
    80003ef0:	8082                	ret
    iput(ip);
    80003ef2:	00000097          	auipc	ra,0x0
    80003ef6:	a30080e7          	jalr	-1488(ra) # 80003922 <iput>
    return -1;
    80003efa:	557d                	li	a0,-1
    80003efc:	b7dd                	j	80003ee2 <dirlink+0x86>
      panic("dirlink read");
    80003efe:	00004517          	auipc	a0,0x4
    80003f02:	7ea50513          	addi	a0,a0,2026 # 800086e8 <stateString.0+0x148>
    80003f06:	ffffc097          	auipc	ra,0xffffc
    80003f0a:	636080e7          	jalr	1590(ra) # 8000053c <panic>

0000000080003f0e <namei>:

struct inode*
namei(char *path)
{
    80003f0e:	1101                	addi	sp,sp,-32
    80003f10:	ec06                	sd	ra,24(sp)
    80003f12:	e822                	sd	s0,16(sp)
    80003f14:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f16:	fe040613          	addi	a2,s0,-32
    80003f1a:	4581                	li	a1,0
    80003f1c:	00000097          	auipc	ra,0x0
    80003f20:	de0080e7          	jalr	-544(ra) # 80003cfc <namex>
}
    80003f24:	60e2                	ld	ra,24(sp)
    80003f26:	6442                	ld	s0,16(sp)
    80003f28:	6105                	addi	sp,sp,32
    80003f2a:	8082                	ret

0000000080003f2c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f2c:	1141                	addi	sp,sp,-16
    80003f2e:	e406                	sd	ra,8(sp)
    80003f30:	e022                	sd	s0,0(sp)
    80003f32:	0800                	addi	s0,sp,16
    80003f34:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f36:	4585                	li	a1,1
    80003f38:	00000097          	auipc	ra,0x0
    80003f3c:	dc4080e7          	jalr	-572(ra) # 80003cfc <namex>
}
    80003f40:	60a2                	ld	ra,8(sp)
    80003f42:	6402                	ld	s0,0(sp)
    80003f44:	0141                	addi	sp,sp,16
    80003f46:	8082                	ret

0000000080003f48 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f48:	1101                	addi	sp,sp,-32
    80003f4a:	ec06                	sd	ra,24(sp)
    80003f4c:	e822                	sd	s0,16(sp)
    80003f4e:	e426                	sd	s1,8(sp)
    80003f50:	e04a                	sd	s2,0(sp)
    80003f52:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f54:	0001d917          	auipc	s2,0x1d
    80003f58:	c7c90913          	addi	s2,s2,-900 # 80020bd0 <log>
    80003f5c:	01892583          	lw	a1,24(s2)
    80003f60:	02892503          	lw	a0,40(s2)
    80003f64:	fffff097          	auipc	ra,0xfffff
    80003f68:	ff4080e7          	jalr	-12(ra) # 80002f58 <bread>
    80003f6c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f6e:	02c92603          	lw	a2,44(s2)
    80003f72:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f74:	00c05f63          	blez	a2,80003f92 <write_head+0x4a>
    80003f78:	0001d717          	auipc	a4,0x1d
    80003f7c:	c8870713          	addi	a4,a4,-888 # 80020c00 <log+0x30>
    80003f80:	87aa                	mv	a5,a0
    80003f82:	060a                	slli	a2,a2,0x2
    80003f84:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003f86:	4314                	lw	a3,0(a4)
    80003f88:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003f8a:	0711                	addi	a4,a4,4
    80003f8c:	0791                	addi	a5,a5,4
    80003f8e:	fec79ce3          	bne	a5,a2,80003f86 <write_head+0x3e>
  }
  bwrite(buf);
    80003f92:	8526                	mv	a0,s1
    80003f94:	fffff097          	auipc	ra,0xfffff
    80003f98:	0b6080e7          	jalr	182(ra) # 8000304a <bwrite>
  brelse(buf);
    80003f9c:	8526                	mv	a0,s1
    80003f9e:	fffff097          	auipc	ra,0xfffff
    80003fa2:	0ea080e7          	jalr	234(ra) # 80003088 <brelse>
}
    80003fa6:	60e2                	ld	ra,24(sp)
    80003fa8:	6442                	ld	s0,16(sp)
    80003faa:	64a2                	ld	s1,8(sp)
    80003fac:	6902                	ld	s2,0(sp)
    80003fae:	6105                	addi	sp,sp,32
    80003fb0:	8082                	ret

0000000080003fb2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fb2:	0001d797          	auipc	a5,0x1d
    80003fb6:	c4a7a783          	lw	a5,-950(a5) # 80020bfc <log+0x2c>
    80003fba:	0af05d63          	blez	a5,80004074 <install_trans+0xc2>
{
    80003fbe:	7139                	addi	sp,sp,-64
    80003fc0:	fc06                	sd	ra,56(sp)
    80003fc2:	f822                	sd	s0,48(sp)
    80003fc4:	f426                	sd	s1,40(sp)
    80003fc6:	f04a                	sd	s2,32(sp)
    80003fc8:	ec4e                	sd	s3,24(sp)
    80003fca:	e852                	sd	s4,16(sp)
    80003fcc:	e456                	sd	s5,8(sp)
    80003fce:	e05a                	sd	s6,0(sp)
    80003fd0:	0080                	addi	s0,sp,64
    80003fd2:	8b2a                	mv	s6,a0
    80003fd4:	0001da97          	auipc	s5,0x1d
    80003fd8:	c2ca8a93          	addi	s5,s5,-980 # 80020c00 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fdc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fde:	0001d997          	auipc	s3,0x1d
    80003fe2:	bf298993          	addi	s3,s3,-1038 # 80020bd0 <log>
    80003fe6:	a00d                	j	80004008 <install_trans+0x56>
    brelse(lbuf);
    80003fe8:	854a                	mv	a0,s2
    80003fea:	fffff097          	auipc	ra,0xfffff
    80003fee:	09e080e7          	jalr	158(ra) # 80003088 <brelse>
    brelse(dbuf);
    80003ff2:	8526                	mv	a0,s1
    80003ff4:	fffff097          	auipc	ra,0xfffff
    80003ff8:	094080e7          	jalr	148(ra) # 80003088 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ffc:	2a05                	addiw	s4,s4,1
    80003ffe:	0a91                	addi	s5,s5,4
    80004000:	02c9a783          	lw	a5,44(s3)
    80004004:	04fa5e63          	bge	s4,a5,80004060 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004008:	0189a583          	lw	a1,24(s3)
    8000400c:	014585bb          	addw	a1,a1,s4
    80004010:	2585                	addiw	a1,a1,1
    80004012:	0289a503          	lw	a0,40(s3)
    80004016:	fffff097          	auipc	ra,0xfffff
    8000401a:	f42080e7          	jalr	-190(ra) # 80002f58 <bread>
    8000401e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004020:	000aa583          	lw	a1,0(s5)
    80004024:	0289a503          	lw	a0,40(s3)
    80004028:	fffff097          	auipc	ra,0xfffff
    8000402c:	f30080e7          	jalr	-208(ra) # 80002f58 <bread>
    80004030:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004032:	40000613          	li	a2,1024
    80004036:	05890593          	addi	a1,s2,88
    8000403a:	05850513          	addi	a0,a0,88
    8000403e:	ffffd097          	auipc	ra,0xffffd
    80004042:	cec080e7          	jalr	-788(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004046:	8526                	mv	a0,s1
    80004048:	fffff097          	auipc	ra,0xfffff
    8000404c:	002080e7          	jalr	2(ra) # 8000304a <bwrite>
    if(recovering == 0)
    80004050:	f80b1ce3          	bnez	s6,80003fe8 <install_trans+0x36>
      bunpin(dbuf);
    80004054:	8526                	mv	a0,s1
    80004056:	fffff097          	auipc	ra,0xfffff
    8000405a:	10a080e7          	jalr	266(ra) # 80003160 <bunpin>
    8000405e:	b769                	j	80003fe8 <install_trans+0x36>
}
    80004060:	70e2                	ld	ra,56(sp)
    80004062:	7442                	ld	s0,48(sp)
    80004064:	74a2                	ld	s1,40(sp)
    80004066:	7902                	ld	s2,32(sp)
    80004068:	69e2                	ld	s3,24(sp)
    8000406a:	6a42                	ld	s4,16(sp)
    8000406c:	6aa2                	ld	s5,8(sp)
    8000406e:	6b02                	ld	s6,0(sp)
    80004070:	6121                	addi	sp,sp,64
    80004072:	8082                	ret
    80004074:	8082                	ret

0000000080004076 <initlog>:
{
    80004076:	7179                	addi	sp,sp,-48
    80004078:	f406                	sd	ra,40(sp)
    8000407a:	f022                	sd	s0,32(sp)
    8000407c:	ec26                	sd	s1,24(sp)
    8000407e:	e84a                	sd	s2,16(sp)
    80004080:	e44e                	sd	s3,8(sp)
    80004082:	1800                	addi	s0,sp,48
    80004084:	892a                	mv	s2,a0
    80004086:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004088:	0001d497          	auipc	s1,0x1d
    8000408c:	b4848493          	addi	s1,s1,-1208 # 80020bd0 <log>
    80004090:	00004597          	auipc	a1,0x4
    80004094:	66858593          	addi	a1,a1,1640 # 800086f8 <stateString.0+0x158>
    80004098:	8526                	mv	a0,s1
    8000409a:	ffffd097          	auipc	ra,0xffffd
    8000409e:	aa8080e7          	jalr	-1368(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    800040a2:	0149a583          	lw	a1,20(s3)
    800040a6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040a8:	0109a783          	lw	a5,16(s3)
    800040ac:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040ae:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040b2:	854a                	mv	a0,s2
    800040b4:	fffff097          	auipc	ra,0xfffff
    800040b8:	ea4080e7          	jalr	-348(ra) # 80002f58 <bread>
  log.lh.n = lh->n;
    800040bc:	4d30                	lw	a2,88(a0)
    800040be:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040c0:	00c05f63          	blez	a2,800040de <initlog+0x68>
    800040c4:	87aa                	mv	a5,a0
    800040c6:	0001d717          	auipc	a4,0x1d
    800040ca:	b3a70713          	addi	a4,a4,-1222 # 80020c00 <log+0x30>
    800040ce:	060a                	slli	a2,a2,0x2
    800040d0:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800040d2:	4ff4                	lw	a3,92(a5)
    800040d4:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040d6:	0791                	addi	a5,a5,4
    800040d8:	0711                	addi	a4,a4,4
    800040da:	fec79ce3          	bne	a5,a2,800040d2 <initlog+0x5c>
  brelse(buf);
    800040de:	fffff097          	auipc	ra,0xfffff
    800040e2:	faa080e7          	jalr	-86(ra) # 80003088 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040e6:	4505                	li	a0,1
    800040e8:	00000097          	auipc	ra,0x0
    800040ec:	eca080e7          	jalr	-310(ra) # 80003fb2 <install_trans>
  log.lh.n = 0;
    800040f0:	0001d797          	auipc	a5,0x1d
    800040f4:	b007a623          	sw	zero,-1268(a5) # 80020bfc <log+0x2c>
  write_head(); // clear the log
    800040f8:	00000097          	auipc	ra,0x0
    800040fc:	e50080e7          	jalr	-432(ra) # 80003f48 <write_head>
}
    80004100:	70a2                	ld	ra,40(sp)
    80004102:	7402                	ld	s0,32(sp)
    80004104:	64e2                	ld	s1,24(sp)
    80004106:	6942                	ld	s2,16(sp)
    80004108:	69a2                	ld	s3,8(sp)
    8000410a:	6145                	addi	sp,sp,48
    8000410c:	8082                	ret

000000008000410e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000410e:	1101                	addi	sp,sp,-32
    80004110:	ec06                	sd	ra,24(sp)
    80004112:	e822                	sd	s0,16(sp)
    80004114:	e426                	sd	s1,8(sp)
    80004116:	e04a                	sd	s2,0(sp)
    80004118:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000411a:	0001d517          	auipc	a0,0x1d
    8000411e:	ab650513          	addi	a0,a0,-1354 # 80020bd0 <log>
    80004122:	ffffd097          	auipc	ra,0xffffd
    80004126:	ab0080e7          	jalr	-1360(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    8000412a:	0001d497          	auipc	s1,0x1d
    8000412e:	aa648493          	addi	s1,s1,-1370 # 80020bd0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004132:	4979                	li	s2,30
    80004134:	a039                	j	80004142 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004136:	85a6                	mv	a1,s1
    80004138:	8526                	mv	a0,s1
    8000413a:	ffffe097          	auipc	ra,0xffffe
    8000413e:	f14080e7          	jalr	-236(ra) # 8000204e <sleep>
    if(log.committing){
    80004142:	50dc                	lw	a5,36(s1)
    80004144:	fbed                	bnez	a5,80004136 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004146:	5098                	lw	a4,32(s1)
    80004148:	2705                	addiw	a4,a4,1
    8000414a:	0027179b          	slliw	a5,a4,0x2
    8000414e:	9fb9                	addw	a5,a5,a4
    80004150:	0017979b          	slliw	a5,a5,0x1
    80004154:	54d4                	lw	a3,44(s1)
    80004156:	9fb5                	addw	a5,a5,a3
    80004158:	00f95963          	bge	s2,a5,8000416a <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000415c:	85a6                	mv	a1,s1
    8000415e:	8526                	mv	a0,s1
    80004160:	ffffe097          	auipc	ra,0xffffe
    80004164:	eee080e7          	jalr	-274(ra) # 8000204e <sleep>
    80004168:	bfe9                	j	80004142 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000416a:	0001d517          	auipc	a0,0x1d
    8000416e:	a6650513          	addi	a0,a0,-1434 # 80020bd0 <log>
    80004172:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004174:	ffffd097          	auipc	ra,0xffffd
    80004178:	b12080e7          	jalr	-1262(ra) # 80000c86 <release>
      break;
    }
  }
}
    8000417c:	60e2                	ld	ra,24(sp)
    8000417e:	6442                	ld	s0,16(sp)
    80004180:	64a2                	ld	s1,8(sp)
    80004182:	6902                	ld	s2,0(sp)
    80004184:	6105                	addi	sp,sp,32
    80004186:	8082                	ret

0000000080004188 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004188:	7139                	addi	sp,sp,-64
    8000418a:	fc06                	sd	ra,56(sp)
    8000418c:	f822                	sd	s0,48(sp)
    8000418e:	f426                	sd	s1,40(sp)
    80004190:	f04a                	sd	s2,32(sp)
    80004192:	ec4e                	sd	s3,24(sp)
    80004194:	e852                	sd	s4,16(sp)
    80004196:	e456                	sd	s5,8(sp)
    80004198:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000419a:	0001d497          	auipc	s1,0x1d
    8000419e:	a3648493          	addi	s1,s1,-1482 # 80020bd0 <log>
    800041a2:	8526                	mv	a0,s1
    800041a4:	ffffd097          	auipc	ra,0xffffd
    800041a8:	a2e080e7          	jalr	-1490(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    800041ac:	509c                	lw	a5,32(s1)
    800041ae:	37fd                	addiw	a5,a5,-1
    800041b0:	0007891b          	sext.w	s2,a5
    800041b4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041b6:	50dc                	lw	a5,36(s1)
    800041b8:	e7b9                	bnez	a5,80004206 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041ba:	04091e63          	bnez	s2,80004216 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800041be:	0001d497          	auipc	s1,0x1d
    800041c2:	a1248493          	addi	s1,s1,-1518 # 80020bd0 <log>
    800041c6:	4785                	li	a5,1
    800041c8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041ca:	8526                	mv	a0,s1
    800041cc:	ffffd097          	auipc	ra,0xffffd
    800041d0:	aba080e7          	jalr	-1350(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041d4:	54dc                	lw	a5,44(s1)
    800041d6:	06f04763          	bgtz	a5,80004244 <end_op+0xbc>
    acquire(&log.lock);
    800041da:	0001d497          	auipc	s1,0x1d
    800041de:	9f648493          	addi	s1,s1,-1546 # 80020bd0 <log>
    800041e2:	8526                	mv	a0,s1
    800041e4:	ffffd097          	auipc	ra,0xffffd
    800041e8:	9ee080e7          	jalr	-1554(ra) # 80000bd2 <acquire>
    log.committing = 0;
    800041ec:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041f0:	8526                	mv	a0,s1
    800041f2:	ffffe097          	auipc	ra,0xffffe
    800041f6:	ec0080e7          	jalr	-320(ra) # 800020b2 <wakeup>
    release(&log.lock);
    800041fa:	8526                	mv	a0,s1
    800041fc:	ffffd097          	auipc	ra,0xffffd
    80004200:	a8a080e7          	jalr	-1398(ra) # 80000c86 <release>
}
    80004204:	a03d                	j	80004232 <end_op+0xaa>
    panic("log.committing");
    80004206:	00004517          	auipc	a0,0x4
    8000420a:	4fa50513          	addi	a0,a0,1274 # 80008700 <stateString.0+0x160>
    8000420e:	ffffc097          	auipc	ra,0xffffc
    80004212:	32e080e7          	jalr	814(ra) # 8000053c <panic>
    wakeup(&log);
    80004216:	0001d497          	auipc	s1,0x1d
    8000421a:	9ba48493          	addi	s1,s1,-1606 # 80020bd0 <log>
    8000421e:	8526                	mv	a0,s1
    80004220:	ffffe097          	auipc	ra,0xffffe
    80004224:	e92080e7          	jalr	-366(ra) # 800020b2 <wakeup>
  release(&log.lock);
    80004228:	8526                	mv	a0,s1
    8000422a:	ffffd097          	auipc	ra,0xffffd
    8000422e:	a5c080e7          	jalr	-1444(ra) # 80000c86 <release>
}
    80004232:	70e2                	ld	ra,56(sp)
    80004234:	7442                	ld	s0,48(sp)
    80004236:	74a2                	ld	s1,40(sp)
    80004238:	7902                	ld	s2,32(sp)
    8000423a:	69e2                	ld	s3,24(sp)
    8000423c:	6a42                	ld	s4,16(sp)
    8000423e:	6aa2                	ld	s5,8(sp)
    80004240:	6121                	addi	sp,sp,64
    80004242:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004244:	0001da97          	auipc	s5,0x1d
    80004248:	9bca8a93          	addi	s5,s5,-1604 # 80020c00 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000424c:	0001da17          	auipc	s4,0x1d
    80004250:	984a0a13          	addi	s4,s4,-1660 # 80020bd0 <log>
    80004254:	018a2583          	lw	a1,24(s4)
    80004258:	012585bb          	addw	a1,a1,s2
    8000425c:	2585                	addiw	a1,a1,1
    8000425e:	028a2503          	lw	a0,40(s4)
    80004262:	fffff097          	auipc	ra,0xfffff
    80004266:	cf6080e7          	jalr	-778(ra) # 80002f58 <bread>
    8000426a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000426c:	000aa583          	lw	a1,0(s5)
    80004270:	028a2503          	lw	a0,40(s4)
    80004274:	fffff097          	auipc	ra,0xfffff
    80004278:	ce4080e7          	jalr	-796(ra) # 80002f58 <bread>
    8000427c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000427e:	40000613          	li	a2,1024
    80004282:	05850593          	addi	a1,a0,88
    80004286:	05848513          	addi	a0,s1,88
    8000428a:	ffffd097          	auipc	ra,0xffffd
    8000428e:	aa0080e7          	jalr	-1376(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    80004292:	8526                	mv	a0,s1
    80004294:	fffff097          	auipc	ra,0xfffff
    80004298:	db6080e7          	jalr	-586(ra) # 8000304a <bwrite>
    brelse(from);
    8000429c:	854e                	mv	a0,s3
    8000429e:	fffff097          	auipc	ra,0xfffff
    800042a2:	dea080e7          	jalr	-534(ra) # 80003088 <brelse>
    brelse(to);
    800042a6:	8526                	mv	a0,s1
    800042a8:	fffff097          	auipc	ra,0xfffff
    800042ac:	de0080e7          	jalr	-544(ra) # 80003088 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042b0:	2905                	addiw	s2,s2,1
    800042b2:	0a91                	addi	s5,s5,4
    800042b4:	02ca2783          	lw	a5,44(s4)
    800042b8:	f8f94ee3          	blt	s2,a5,80004254 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042bc:	00000097          	auipc	ra,0x0
    800042c0:	c8c080e7          	jalr	-884(ra) # 80003f48 <write_head>
    install_trans(0); // Now install writes to home locations
    800042c4:	4501                	li	a0,0
    800042c6:	00000097          	auipc	ra,0x0
    800042ca:	cec080e7          	jalr	-788(ra) # 80003fb2 <install_trans>
    log.lh.n = 0;
    800042ce:	0001d797          	auipc	a5,0x1d
    800042d2:	9207a723          	sw	zero,-1746(a5) # 80020bfc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042d6:	00000097          	auipc	ra,0x0
    800042da:	c72080e7          	jalr	-910(ra) # 80003f48 <write_head>
    800042de:	bdf5                	j	800041da <end_op+0x52>

00000000800042e0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042e0:	1101                	addi	sp,sp,-32
    800042e2:	ec06                	sd	ra,24(sp)
    800042e4:	e822                	sd	s0,16(sp)
    800042e6:	e426                	sd	s1,8(sp)
    800042e8:	e04a                	sd	s2,0(sp)
    800042ea:	1000                	addi	s0,sp,32
    800042ec:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042ee:	0001d917          	auipc	s2,0x1d
    800042f2:	8e290913          	addi	s2,s2,-1822 # 80020bd0 <log>
    800042f6:	854a                	mv	a0,s2
    800042f8:	ffffd097          	auipc	ra,0xffffd
    800042fc:	8da080e7          	jalr	-1830(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004300:	02c92603          	lw	a2,44(s2)
    80004304:	47f5                	li	a5,29
    80004306:	06c7c563          	blt	a5,a2,80004370 <log_write+0x90>
    8000430a:	0001d797          	auipc	a5,0x1d
    8000430e:	8e27a783          	lw	a5,-1822(a5) # 80020bec <log+0x1c>
    80004312:	37fd                	addiw	a5,a5,-1
    80004314:	04f65e63          	bge	a2,a5,80004370 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004318:	0001d797          	auipc	a5,0x1d
    8000431c:	8d87a783          	lw	a5,-1832(a5) # 80020bf0 <log+0x20>
    80004320:	06f05063          	blez	a5,80004380 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004324:	4781                	li	a5,0
    80004326:	06c05563          	blez	a2,80004390 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000432a:	44cc                	lw	a1,12(s1)
    8000432c:	0001d717          	auipc	a4,0x1d
    80004330:	8d470713          	addi	a4,a4,-1836 # 80020c00 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004334:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004336:	4314                	lw	a3,0(a4)
    80004338:	04b68c63          	beq	a3,a1,80004390 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000433c:	2785                	addiw	a5,a5,1
    8000433e:	0711                	addi	a4,a4,4
    80004340:	fef61be3          	bne	a2,a5,80004336 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004344:	0621                	addi	a2,a2,8
    80004346:	060a                	slli	a2,a2,0x2
    80004348:	0001d797          	auipc	a5,0x1d
    8000434c:	88878793          	addi	a5,a5,-1912 # 80020bd0 <log>
    80004350:	97b2                	add	a5,a5,a2
    80004352:	44d8                	lw	a4,12(s1)
    80004354:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004356:	8526                	mv	a0,s1
    80004358:	fffff097          	auipc	ra,0xfffff
    8000435c:	dcc080e7          	jalr	-564(ra) # 80003124 <bpin>
    log.lh.n++;
    80004360:	0001d717          	auipc	a4,0x1d
    80004364:	87070713          	addi	a4,a4,-1936 # 80020bd0 <log>
    80004368:	575c                	lw	a5,44(a4)
    8000436a:	2785                	addiw	a5,a5,1
    8000436c:	d75c                	sw	a5,44(a4)
    8000436e:	a82d                	j	800043a8 <log_write+0xc8>
    panic("too big a transaction");
    80004370:	00004517          	auipc	a0,0x4
    80004374:	3a050513          	addi	a0,a0,928 # 80008710 <stateString.0+0x170>
    80004378:	ffffc097          	auipc	ra,0xffffc
    8000437c:	1c4080e7          	jalr	452(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004380:	00004517          	auipc	a0,0x4
    80004384:	3a850513          	addi	a0,a0,936 # 80008728 <stateString.0+0x188>
    80004388:	ffffc097          	auipc	ra,0xffffc
    8000438c:	1b4080e7          	jalr	436(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004390:	00878693          	addi	a3,a5,8
    80004394:	068a                	slli	a3,a3,0x2
    80004396:	0001d717          	auipc	a4,0x1d
    8000439a:	83a70713          	addi	a4,a4,-1990 # 80020bd0 <log>
    8000439e:	9736                	add	a4,a4,a3
    800043a0:	44d4                	lw	a3,12(s1)
    800043a2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043a4:	faf609e3          	beq	a2,a5,80004356 <log_write+0x76>
  }
  release(&log.lock);
    800043a8:	0001d517          	auipc	a0,0x1d
    800043ac:	82850513          	addi	a0,a0,-2008 # 80020bd0 <log>
    800043b0:	ffffd097          	auipc	ra,0xffffd
    800043b4:	8d6080e7          	jalr	-1834(ra) # 80000c86 <release>
}
    800043b8:	60e2                	ld	ra,24(sp)
    800043ba:	6442                	ld	s0,16(sp)
    800043bc:	64a2                	ld	s1,8(sp)
    800043be:	6902                	ld	s2,0(sp)
    800043c0:	6105                	addi	sp,sp,32
    800043c2:	8082                	ret

00000000800043c4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043c4:	1101                	addi	sp,sp,-32
    800043c6:	ec06                	sd	ra,24(sp)
    800043c8:	e822                	sd	s0,16(sp)
    800043ca:	e426                	sd	s1,8(sp)
    800043cc:	e04a                	sd	s2,0(sp)
    800043ce:	1000                	addi	s0,sp,32
    800043d0:	84aa                	mv	s1,a0
    800043d2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043d4:	00004597          	auipc	a1,0x4
    800043d8:	37458593          	addi	a1,a1,884 # 80008748 <stateString.0+0x1a8>
    800043dc:	0521                	addi	a0,a0,8
    800043de:	ffffc097          	auipc	ra,0xffffc
    800043e2:	764080e7          	jalr	1892(ra) # 80000b42 <initlock>
  lk->name = name;
    800043e6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043ea:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043ee:	0204a423          	sw	zero,40(s1)
}
    800043f2:	60e2                	ld	ra,24(sp)
    800043f4:	6442                	ld	s0,16(sp)
    800043f6:	64a2                	ld	s1,8(sp)
    800043f8:	6902                	ld	s2,0(sp)
    800043fa:	6105                	addi	sp,sp,32
    800043fc:	8082                	ret

00000000800043fe <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043fe:	1101                	addi	sp,sp,-32
    80004400:	ec06                	sd	ra,24(sp)
    80004402:	e822                	sd	s0,16(sp)
    80004404:	e426                	sd	s1,8(sp)
    80004406:	e04a                	sd	s2,0(sp)
    80004408:	1000                	addi	s0,sp,32
    8000440a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000440c:	00850913          	addi	s2,a0,8
    80004410:	854a                	mv	a0,s2
    80004412:	ffffc097          	auipc	ra,0xffffc
    80004416:	7c0080e7          	jalr	1984(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    8000441a:	409c                	lw	a5,0(s1)
    8000441c:	cb89                	beqz	a5,8000442e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000441e:	85ca                	mv	a1,s2
    80004420:	8526                	mv	a0,s1
    80004422:	ffffe097          	auipc	ra,0xffffe
    80004426:	c2c080e7          	jalr	-980(ra) # 8000204e <sleep>
  while (lk->locked) {
    8000442a:	409c                	lw	a5,0(s1)
    8000442c:	fbed                	bnez	a5,8000441e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000442e:	4785                	li	a5,1
    80004430:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004432:	ffffd097          	auipc	ra,0xffffd
    80004436:	574080e7          	jalr	1396(ra) # 800019a6 <myproc>
    8000443a:	591c                	lw	a5,48(a0)
    8000443c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000443e:	854a                	mv	a0,s2
    80004440:	ffffd097          	auipc	ra,0xffffd
    80004444:	846080e7          	jalr	-1978(ra) # 80000c86 <release>
}
    80004448:	60e2                	ld	ra,24(sp)
    8000444a:	6442                	ld	s0,16(sp)
    8000444c:	64a2                	ld	s1,8(sp)
    8000444e:	6902                	ld	s2,0(sp)
    80004450:	6105                	addi	sp,sp,32
    80004452:	8082                	ret

0000000080004454 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004454:	1101                	addi	sp,sp,-32
    80004456:	ec06                	sd	ra,24(sp)
    80004458:	e822                	sd	s0,16(sp)
    8000445a:	e426                	sd	s1,8(sp)
    8000445c:	e04a                	sd	s2,0(sp)
    8000445e:	1000                	addi	s0,sp,32
    80004460:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004462:	00850913          	addi	s2,a0,8
    80004466:	854a                	mv	a0,s2
    80004468:	ffffc097          	auipc	ra,0xffffc
    8000446c:	76a080e7          	jalr	1898(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    80004470:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004474:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004478:	8526                	mv	a0,s1
    8000447a:	ffffe097          	auipc	ra,0xffffe
    8000447e:	c38080e7          	jalr	-968(ra) # 800020b2 <wakeup>
  release(&lk->lk);
    80004482:	854a                	mv	a0,s2
    80004484:	ffffd097          	auipc	ra,0xffffd
    80004488:	802080e7          	jalr	-2046(ra) # 80000c86 <release>
}
    8000448c:	60e2                	ld	ra,24(sp)
    8000448e:	6442                	ld	s0,16(sp)
    80004490:	64a2                	ld	s1,8(sp)
    80004492:	6902                	ld	s2,0(sp)
    80004494:	6105                	addi	sp,sp,32
    80004496:	8082                	ret

0000000080004498 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004498:	7179                	addi	sp,sp,-48
    8000449a:	f406                	sd	ra,40(sp)
    8000449c:	f022                	sd	s0,32(sp)
    8000449e:	ec26                	sd	s1,24(sp)
    800044a0:	e84a                	sd	s2,16(sp)
    800044a2:	e44e                	sd	s3,8(sp)
    800044a4:	1800                	addi	s0,sp,48
    800044a6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044a8:	00850913          	addi	s2,a0,8
    800044ac:	854a                	mv	a0,s2
    800044ae:	ffffc097          	auipc	ra,0xffffc
    800044b2:	724080e7          	jalr	1828(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044b6:	409c                	lw	a5,0(s1)
    800044b8:	ef99                	bnez	a5,800044d6 <holdingsleep+0x3e>
    800044ba:	4481                	li	s1,0
  release(&lk->lk);
    800044bc:	854a                	mv	a0,s2
    800044be:	ffffc097          	auipc	ra,0xffffc
    800044c2:	7c8080e7          	jalr	1992(ra) # 80000c86 <release>
  return r;
}
    800044c6:	8526                	mv	a0,s1
    800044c8:	70a2                	ld	ra,40(sp)
    800044ca:	7402                	ld	s0,32(sp)
    800044cc:	64e2                	ld	s1,24(sp)
    800044ce:	6942                	ld	s2,16(sp)
    800044d0:	69a2                	ld	s3,8(sp)
    800044d2:	6145                	addi	sp,sp,48
    800044d4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044d6:	0284a983          	lw	s3,40(s1)
    800044da:	ffffd097          	auipc	ra,0xffffd
    800044de:	4cc080e7          	jalr	1228(ra) # 800019a6 <myproc>
    800044e2:	5904                	lw	s1,48(a0)
    800044e4:	413484b3          	sub	s1,s1,s3
    800044e8:	0014b493          	seqz	s1,s1
    800044ec:	bfc1                	j	800044bc <holdingsleep+0x24>

00000000800044ee <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044ee:	1141                	addi	sp,sp,-16
    800044f0:	e406                	sd	ra,8(sp)
    800044f2:	e022                	sd	s0,0(sp)
    800044f4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044f6:	00004597          	auipc	a1,0x4
    800044fa:	26258593          	addi	a1,a1,610 # 80008758 <stateString.0+0x1b8>
    800044fe:	0001d517          	auipc	a0,0x1d
    80004502:	81a50513          	addi	a0,a0,-2022 # 80020d18 <ftable>
    80004506:	ffffc097          	auipc	ra,0xffffc
    8000450a:	63c080e7          	jalr	1596(ra) # 80000b42 <initlock>
}
    8000450e:	60a2                	ld	ra,8(sp)
    80004510:	6402                	ld	s0,0(sp)
    80004512:	0141                	addi	sp,sp,16
    80004514:	8082                	ret

0000000080004516 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004516:	1101                	addi	sp,sp,-32
    80004518:	ec06                	sd	ra,24(sp)
    8000451a:	e822                	sd	s0,16(sp)
    8000451c:	e426                	sd	s1,8(sp)
    8000451e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004520:	0001c517          	auipc	a0,0x1c
    80004524:	7f850513          	addi	a0,a0,2040 # 80020d18 <ftable>
    80004528:	ffffc097          	auipc	ra,0xffffc
    8000452c:	6aa080e7          	jalr	1706(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004530:	0001d497          	auipc	s1,0x1d
    80004534:	80048493          	addi	s1,s1,-2048 # 80020d30 <ftable+0x18>
    80004538:	0001d717          	auipc	a4,0x1d
    8000453c:	79870713          	addi	a4,a4,1944 # 80021cd0 <disk>
    if(f->ref == 0){
    80004540:	40dc                	lw	a5,4(s1)
    80004542:	cf99                	beqz	a5,80004560 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004544:	02848493          	addi	s1,s1,40
    80004548:	fee49ce3          	bne	s1,a4,80004540 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000454c:	0001c517          	auipc	a0,0x1c
    80004550:	7cc50513          	addi	a0,a0,1996 # 80020d18 <ftable>
    80004554:	ffffc097          	auipc	ra,0xffffc
    80004558:	732080e7          	jalr	1842(ra) # 80000c86 <release>
  return 0;
    8000455c:	4481                	li	s1,0
    8000455e:	a819                	j	80004574 <filealloc+0x5e>
      f->ref = 1;
    80004560:	4785                	li	a5,1
    80004562:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004564:	0001c517          	auipc	a0,0x1c
    80004568:	7b450513          	addi	a0,a0,1972 # 80020d18 <ftable>
    8000456c:	ffffc097          	auipc	ra,0xffffc
    80004570:	71a080e7          	jalr	1818(ra) # 80000c86 <release>
}
    80004574:	8526                	mv	a0,s1
    80004576:	60e2                	ld	ra,24(sp)
    80004578:	6442                	ld	s0,16(sp)
    8000457a:	64a2                	ld	s1,8(sp)
    8000457c:	6105                	addi	sp,sp,32
    8000457e:	8082                	ret

0000000080004580 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004580:	1101                	addi	sp,sp,-32
    80004582:	ec06                	sd	ra,24(sp)
    80004584:	e822                	sd	s0,16(sp)
    80004586:	e426                	sd	s1,8(sp)
    80004588:	1000                	addi	s0,sp,32
    8000458a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000458c:	0001c517          	auipc	a0,0x1c
    80004590:	78c50513          	addi	a0,a0,1932 # 80020d18 <ftable>
    80004594:	ffffc097          	auipc	ra,0xffffc
    80004598:	63e080e7          	jalr	1598(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    8000459c:	40dc                	lw	a5,4(s1)
    8000459e:	02f05263          	blez	a5,800045c2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045a2:	2785                	addiw	a5,a5,1
    800045a4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045a6:	0001c517          	auipc	a0,0x1c
    800045aa:	77250513          	addi	a0,a0,1906 # 80020d18 <ftable>
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	6d8080e7          	jalr	1752(ra) # 80000c86 <release>
  return f;
}
    800045b6:	8526                	mv	a0,s1
    800045b8:	60e2                	ld	ra,24(sp)
    800045ba:	6442                	ld	s0,16(sp)
    800045bc:	64a2                	ld	s1,8(sp)
    800045be:	6105                	addi	sp,sp,32
    800045c0:	8082                	ret
    panic("filedup");
    800045c2:	00004517          	auipc	a0,0x4
    800045c6:	19e50513          	addi	a0,a0,414 # 80008760 <stateString.0+0x1c0>
    800045ca:	ffffc097          	auipc	ra,0xffffc
    800045ce:	f72080e7          	jalr	-142(ra) # 8000053c <panic>

00000000800045d2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045d2:	7139                	addi	sp,sp,-64
    800045d4:	fc06                	sd	ra,56(sp)
    800045d6:	f822                	sd	s0,48(sp)
    800045d8:	f426                	sd	s1,40(sp)
    800045da:	f04a                	sd	s2,32(sp)
    800045dc:	ec4e                	sd	s3,24(sp)
    800045de:	e852                	sd	s4,16(sp)
    800045e0:	e456                	sd	s5,8(sp)
    800045e2:	0080                	addi	s0,sp,64
    800045e4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045e6:	0001c517          	auipc	a0,0x1c
    800045ea:	73250513          	addi	a0,a0,1842 # 80020d18 <ftable>
    800045ee:	ffffc097          	auipc	ra,0xffffc
    800045f2:	5e4080e7          	jalr	1508(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    800045f6:	40dc                	lw	a5,4(s1)
    800045f8:	06f05163          	blez	a5,8000465a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045fc:	37fd                	addiw	a5,a5,-1
    800045fe:	0007871b          	sext.w	a4,a5
    80004602:	c0dc                	sw	a5,4(s1)
    80004604:	06e04363          	bgtz	a4,8000466a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004608:	0004a903          	lw	s2,0(s1)
    8000460c:	0094ca83          	lbu	s5,9(s1)
    80004610:	0104ba03          	ld	s4,16(s1)
    80004614:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004618:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000461c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004620:	0001c517          	auipc	a0,0x1c
    80004624:	6f850513          	addi	a0,a0,1784 # 80020d18 <ftable>
    80004628:	ffffc097          	auipc	ra,0xffffc
    8000462c:	65e080e7          	jalr	1630(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    80004630:	4785                	li	a5,1
    80004632:	04f90d63          	beq	s2,a5,8000468c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004636:	3979                	addiw	s2,s2,-2
    80004638:	4785                	li	a5,1
    8000463a:	0527e063          	bltu	a5,s2,8000467a <fileclose+0xa8>
    begin_op();
    8000463e:	00000097          	auipc	ra,0x0
    80004642:	ad0080e7          	jalr	-1328(ra) # 8000410e <begin_op>
    iput(ff.ip);
    80004646:	854e                	mv	a0,s3
    80004648:	fffff097          	auipc	ra,0xfffff
    8000464c:	2da080e7          	jalr	730(ra) # 80003922 <iput>
    end_op();
    80004650:	00000097          	auipc	ra,0x0
    80004654:	b38080e7          	jalr	-1224(ra) # 80004188 <end_op>
    80004658:	a00d                	j	8000467a <fileclose+0xa8>
    panic("fileclose");
    8000465a:	00004517          	auipc	a0,0x4
    8000465e:	10e50513          	addi	a0,a0,270 # 80008768 <stateString.0+0x1c8>
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	eda080e7          	jalr	-294(ra) # 8000053c <panic>
    release(&ftable.lock);
    8000466a:	0001c517          	auipc	a0,0x1c
    8000466e:	6ae50513          	addi	a0,a0,1710 # 80020d18 <ftable>
    80004672:	ffffc097          	auipc	ra,0xffffc
    80004676:	614080e7          	jalr	1556(ra) # 80000c86 <release>
  }
}
    8000467a:	70e2                	ld	ra,56(sp)
    8000467c:	7442                	ld	s0,48(sp)
    8000467e:	74a2                	ld	s1,40(sp)
    80004680:	7902                	ld	s2,32(sp)
    80004682:	69e2                	ld	s3,24(sp)
    80004684:	6a42                	ld	s4,16(sp)
    80004686:	6aa2                	ld	s5,8(sp)
    80004688:	6121                	addi	sp,sp,64
    8000468a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000468c:	85d6                	mv	a1,s5
    8000468e:	8552                	mv	a0,s4
    80004690:	00000097          	auipc	ra,0x0
    80004694:	348080e7          	jalr	840(ra) # 800049d8 <pipeclose>
    80004698:	b7cd                	j	8000467a <fileclose+0xa8>

000000008000469a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000469a:	715d                	addi	sp,sp,-80
    8000469c:	e486                	sd	ra,72(sp)
    8000469e:	e0a2                	sd	s0,64(sp)
    800046a0:	fc26                	sd	s1,56(sp)
    800046a2:	f84a                	sd	s2,48(sp)
    800046a4:	f44e                	sd	s3,40(sp)
    800046a6:	0880                	addi	s0,sp,80
    800046a8:	84aa                	mv	s1,a0
    800046aa:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046ac:	ffffd097          	auipc	ra,0xffffd
    800046b0:	2fa080e7          	jalr	762(ra) # 800019a6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046b4:	409c                	lw	a5,0(s1)
    800046b6:	37f9                	addiw	a5,a5,-2
    800046b8:	4705                	li	a4,1
    800046ba:	04f76763          	bltu	a4,a5,80004708 <filestat+0x6e>
    800046be:	892a                	mv	s2,a0
    ilock(f->ip);
    800046c0:	6c88                	ld	a0,24(s1)
    800046c2:	fffff097          	auipc	ra,0xfffff
    800046c6:	0a6080e7          	jalr	166(ra) # 80003768 <ilock>
    stati(f->ip, &st);
    800046ca:	fb840593          	addi	a1,s0,-72
    800046ce:	6c88                	ld	a0,24(s1)
    800046d0:	fffff097          	auipc	ra,0xfffff
    800046d4:	322080e7          	jalr	802(ra) # 800039f2 <stati>
    iunlock(f->ip);
    800046d8:	6c88                	ld	a0,24(s1)
    800046da:	fffff097          	auipc	ra,0xfffff
    800046de:	150080e7          	jalr	336(ra) # 8000382a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046e2:	46e1                	li	a3,24
    800046e4:	fb840613          	addi	a2,s0,-72
    800046e8:	85ce                	mv	a1,s3
    800046ea:	05093503          	ld	a0,80(s2)
    800046ee:	ffffd097          	auipc	ra,0xffffd
    800046f2:	f78080e7          	jalr	-136(ra) # 80001666 <copyout>
    800046f6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046fa:	60a6                	ld	ra,72(sp)
    800046fc:	6406                	ld	s0,64(sp)
    800046fe:	74e2                	ld	s1,56(sp)
    80004700:	7942                	ld	s2,48(sp)
    80004702:	79a2                	ld	s3,40(sp)
    80004704:	6161                	addi	sp,sp,80
    80004706:	8082                	ret
  return -1;
    80004708:	557d                	li	a0,-1
    8000470a:	bfc5                	j	800046fa <filestat+0x60>

000000008000470c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000470c:	7179                	addi	sp,sp,-48
    8000470e:	f406                	sd	ra,40(sp)
    80004710:	f022                	sd	s0,32(sp)
    80004712:	ec26                	sd	s1,24(sp)
    80004714:	e84a                	sd	s2,16(sp)
    80004716:	e44e                	sd	s3,8(sp)
    80004718:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000471a:	00854783          	lbu	a5,8(a0)
    8000471e:	c3d5                	beqz	a5,800047c2 <fileread+0xb6>
    80004720:	84aa                	mv	s1,a0
    80004722:	89ae                	mv	s3,a1
    80004724:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004726:	411c                	lw	a5,0(a0)
    80004728:	4705                	li	a4,1
    8000472a:	04e78963          	beq	a5,a4,8000477c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000472e:	470d                	li	a4,3
    80004730:	04e78d63          	beq	a5,a4,8000478a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004734:	4709                	li	a4,2
    80004736:	06e79e63          	bne	a5,a4,800047b2 <fileread+0xa6>
    ilock(f->ip);
    8000473a:	6d08                	ld	a0,24(a0)
    8000473c:	fffff097          	auipc	ra,0xfffff
    80004740:	02c080e7          	jalr	44(ra) # 80003768 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004744:	874a                	mv	a4,s2
    80004746:	5094                	lw	a3,32(s1)
    80004748:	864e                	mv	a2,s3
    8000474a:	4585                	li	a1,1
    8000474c:	6c88                	ld	a0,24(s1)
    8000474e:	fffff097          	auipc	ra,0xfffff
    80004752:	2ce080e7          	jalr	718(ra) # 80003a1c <readi>
    80004756:	892a                	mv	s2,a0
    80004758:	00a05563          	blez	a0,80004762 <fileread+0x56>
      f->off += r;
    8000475c:	509c                	lw	a5,32(s1)
    8000475e:	9fa9                	addw	a5,a5,a0
    80004760:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004762:	6c88                	ld	a0,24(s1)
    80004764:	fffff097          	auipc	ra,0xfffff
    80004768:	0c6080e7          	jalr	198(ra) # 8000382a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000476c:	854a                	mv	a0,s2
    8000476e:	70a2                	ld	ra,40(sp)
    80004770:	7402                	ld	s0,32(sp)
    80004772:	64e2                	ld	s1,24(sp)
    80004774:	6942                	ld	s2,16(sp)
    80004776:	69a2                	ld	s3,8(sp)
    80004778:	6145                	addi	sp,sp,48
    8000477a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000477c:	6908                	ld	a0,16(a0)
    8000477e:	00000097          	auipc	ra,0x0
    80004782:	3c2080e7          	jalr	962(ra) # 80004b40 <piperead>
    80004786:	892a                	mv	s2,a0
    80004788:	b7d5                	j	8000476c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000478a:	02451783          	lh	a5,36(a0)
    8000478e:	03079693          	slli	a3,a5,0x30
    80004792:	92c1                	srli	a3,a3,0x30
    80004794:	4725                	li	a4,9
    80004796:	02d76863          	bltu	a4,a3,800047c6 <fileread+0xba>
    8000479a:	0792                	slli	a5,a5,0x4
    8000479c:	0001c717          	auipc	a4,0x1c
    800047a0:	4dc70713          	addi	a4,a4,1244 # 80020c78 <devsw>
    800047a4:	97ba                	add	a5,a5,a4
    800047a6:	639c                	ld	a5,0(a5)
    800047a8:	c38d                	beqz	a5,800047ca <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047aa:	4505                	li	a0,1
    800047ac:	9782                	jalr	a5
    800047ae:	892a                	mv	s2,a0
    800047b0:	bf75                	j	8000476c <fileread+0x60>
    panic("fileread");
    800047b2:	00004517          	auipc	a0,0x4
    800047b6:	fc650513          	addi	a0,a0,-58 # 80008778 <stateString.0+0x1d8>
    800047ba:	ffffc097          	auipc	ra,0xffffc
    800047be:	d82080e7          	jalr	-638(ra) # 8000053c <panic>
    return -1;
    800047c2:	597d                	li	s2,-1
    800047c4:	b765                	j	8000476c <fileread+0x60>
      return -1;
    800047c6:	597d                	li	s2,-1
    800047c8:	b755                	j	8000476c <fileread+0x60>
    800047ca:	597d                	li	s2,-1
    800047cc:	b745                	j	8000476c <fileread+0x60>

00000000800047ce <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800047ce:	00954783          	lbu	a5,9(a0)
    800047d2:	10078e63          	beqz	a5,800048ee <filewrite+0x120>
{
    800047d6:	715d                	addi	sp,sp,-80
    800047d8:	e486                	sd	ra,72(sp)
    800047da:	e0a2                	sd	s0,64(sp)
    800047dc:	fc26                	sd	s1,56(sp)
    800047de:	f84a                	sd	s2,48(sp)
    800047e0:	f44e                	sd	s3,40(sp)
    800047e2:	f052                	sd	s4,32(sp)
    800047e4:	ec56                	sd	s5,24(sp)
    800047e6:	e85a                	sd	s6,16(sp)
    800047e8:	e45e                	sd	s7,8(sp)
    800047ea:	e062                	sd	s8,0(sp)
    800047ec:	0880                	addi	s0,sp,80
    800047ee:	892a                	mv	s2,a0
    800047f0:	8b2e                	mv	s6,a1
    800047f2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047f4:	411c                	lw	a5,0(a0)
    800047f6:	4705                	li	a4,1
    800047f8:	02e78263          	beq	a5,a4,8000481c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047fc:	470d                	li	a4,3
    800047fe:	02e78563          	beq	a5,a4,80004828 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004802:	4709                	li	a4,2
    80004804:	0ce79d63          	bne	a5,a4,800048de <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004808:	0ac05b63          	blez	a2,800048be <filewrite+0xf0>
    int i = 0;
    8000480c:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    8000480e:	6b85                	lui	s7,0x1
    80004810:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004814:	6c05                	lui	s8,0x1
    80004816:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    8000481a:	a851                	j	800048ae <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    8000481c:	6908                	ld	a0,16(a0)
    8000481e:	00000097          	auipc	ra,0x0
    80004822:	22a080e7          	jalr	554(ra) # 80004a48 <pipewrite>
    80004826:	a045                	j	800048c6 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004828:	02451783          	lh	a5,36(a0)
    8000482c:	03079693          	slli	a3,a5,0x30
    80004830:	92c1                	srli	a3,a3,0x30
    80004832:	4725                	li	a4,9
    80004834:	0ad76f63          	bltu	a4,a3,800048f2 <filewrite+0x124>
    80004838:	0792                	slli	a5,a5,0x4
    8000483a:	0001c717          	auipc	a4,0x1c
    8000483e:	43e70713          	addi	a4,a4,1086 # 80020c78 <devsw>
    80004842:	97ba                	add	a5,a5,a4
    80004844:	679c                	ld	a5,8(a5)
    80004846:	cbc5                	beqz	a5,800048f6 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004848:	4505                	li	a0,1
    8000484a:	9782                	jalr	a5
    8000484c:	a8ad                	j	800048c6 <filewrite+0xf8>
      if(n1 > max)
    8000484e:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004852:	00000097          	auipc	ra,0x0
    80004856:	8bc080e7          	jalr	-1860(ra) # 8000410e <begin_op>
      ilock(f->ip);
    8000485a:	01893503          	ld	a0,24(s2)
    8000485e:	fffff097          	auipc	ra,0xfffff
    80004862:	f0a080e7          	jalr	-246(ra) # 80003768 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004866:	8756                	mv	a4,s5
    80004868:	02092683          	lw	a3,32(s2)
    8000486c:	01698633          	add	a2,s3,s6
    80004870:	4585                	li	a1,1
    80004872:	01893503          	ld	a0,24(s2)
    80004876:	fffff097          	auipc	ra,0xfffff
    8000487a:	29e080e7          	jalr	670(ra) # 80003b14 <writei>
    8000487e:	84aa                	mv	s1,a0
    80004880:	00a05763          	blez	a0,8000488e <filewrite+0xc0>
        f->off += r;
    80004884:	02092783          	lw	a5,32(s2)
    80004888:	9fa9                	addw	a5,a5,a0
    8000488a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000488e:	01893503          	ld	a0,24(s2)
    80004892:	fffff097          	auipc	ra,0xfffff
    80004896:	f98080e7          	jalr	-104(ra) # 8000382a <iunlock>
      end_op();
    8000489a:	00000097          	auipc	ra,0x0
    8000489e:	8ee080e7          	jalr	-1810(ra) # 80004188 <end_op>

      if(r != n1){
    800048a2:	009a9f63          	bne	s5,s1,800048c0 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    800048a6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048aa:	0149db63          	bge	s3,s4,800048c0 <filewrite+0xf2>
      int n1 = n - i;
    800048ae:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    800048b2:	0004879b          	sext.w	a5,s1
    800048b6:	f8fbdce3          	bge	s7,a5,8000484e <filewrite+0x80>
    800048ba:	84e2                	mv	s1,s8
    800048bc:	bf49                	j	8000484e <filewrite+0x80>
    int i = 0;
    800048be:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800048c0:	033a1d63          	bne	s4,s3,800048fa <filewrite+0x12c>
    800048c4:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048c6:	60a6                	ld	ra,72(sp)
    800048c8:	6406                	ld	s0,64(sp)
    800048ca:	74e2                	ld	s1,56(sp)
    800048cc:	7942                	ld	s2,48(sp)
    800048ce:	79a2                	ld	s3,40(sp)
    800048d0:	7a02                	ld	s4,32(sp)
    800048d2:	6ae2                	ld	s5,24(sp)
    800048d4:	6b42                	ld	s6,16(sp)
    800048d6:	6ba2                	ld	s7,8(sp)
    800048d8:	6c02                	ld	s8,0(sp)
    800048da:	6161                	addi	sp,sp,80
    800048dc:	8082                	ret
    panic("filewrite");
    800048de:	00004517          	auipc	a0,0x4
    800048e2:	eaa50513          	addi	a0,a0,-342 # 80008788 <stateString.0+0x1e8>
    800048e6:	ffffc097          	auipc	ra,0xffffc
    800048ea:	c56080e7          	jalr	-938(ra) # 8000053c <panic>
    return -1;
    800048ee:	557d                	li	a0,-1
}
    800048f0:	8082                	ret
      return -1;
    800048f2:	557d                	li	a0,-1
    800048f4:	bfc9                	j	800048c6 <filewrite+0xf8>
    800048f6:	557d                	li	a0,-1
    800048f8:	b7f9                	j	800048c6 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    800048fa:	557d                	li	a0,-1
    800048fc:	b7e9                	j	800048c6 <filewrite+0xf8>

00000000800048fe <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048fe:	7179                	addi	sp,sp,-48
    80004900:	f406                	sd	ra,40(sp)
    80004902:	f022                	sd	s0,32(sp)
    80004904:	ec26                	sd	s1,24(sp)
    80004906:	e84a                	sd	s2,16(sp)
    80004908:	e44e                	sd	s3,8(sp)
    8000490a:	e052                	sd	s4,0(sp)
    8000490c:	1800                	addi	s0,sp,48
    8000490e:	84aa                	mv	s1,a0
    80004910:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004912:	0005b023          	sd	zero,0(a1)
    80004916:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000491a:	00000097          	auipc	ra,0x0
    8000491e:	bfc080e7          	jalr	-1028(ra) # 80004516 <filealloc>
    80004922:	e088                	sd	a0,0(s1)
    80004924:	c551                	beqz	a0,800049b0 <pipealloc+0xb2>
    80004926:	00000097          	auipc	ra,0x0
    8000492a:	bf0080e7          	jalr	-1040(ra) # 80004516 <filealloc>
    8000492e:	00aa3023          	sd	a0,0(s4)
    80004932:	c92d                	beqz	a0,800049a4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	1ae080e7          	jalr	430(ra) # 80000ae2 <kalloc>
    8000493c:	892a                	mv	s2,a0
    8000493e:	c125                	beqz	a0,8000499e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004940:	4985                	li	s3,1
    80004942:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004946:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000494a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000494e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004952:	00004597          	auipc	a1,0x4
    80004956:	e4658593          	addi	a1,a1,-442 # 80008798 <stateString.0+0x1f8>
    8000495a:	ffffc097          	auipc	ra,0xffffc
    8000495e:	1e8080e7          	jalr	488(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80004962:	609c                	ld	a5,0(s1)
    80004964:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004968:	609c                	ld	a5,0(s1)
    8000496a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000496e:	609c                	ld	a5,0(s1)
    80004970:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004974:	609c                	ld	a5,0(s1)
    80004976:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000497a:	000a3783          	ld	a5,0(s4)
    8000497e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004982:	000a3783          	ld	a5,0(s4)
    80004986:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000498a:	000a3783          	ld	a5,0(s4)
    8000498e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004992:	000a3783          	ld	a5,0(s4)
    80004996:	0127b823          	sd	s2,16(a5)
  return 0;
    8000499a:	4501                	li	a0,0
    8000499c:	a025                	j	800049c4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000499e:	6088                	ld	a0,0(s1)
    800049a0:	e501                	bnez	a0,800049a8 <pipealloc+0xaa>
    800049a2:	a039                	j	800049b0 <pipealloc+0xb2>
    800049a4:	6088                	ld	a0,0(s1)
    800049a6:	c51d                	beqz	a0,800049d4 <pipealloc+0xd6>
    fileclose(*f0);
    800049a8:	00000097          	auipc	ra,0x0
    800049ac:	c2a080e7          	jalr	-982(ra) # 800045d2 <fileclose>
  if(*f1)
    800049b0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049b4:	557d                	li	a0,-1
  if(*f1)
    800049b6:	c799                	beqz	a5,800049c4 <pipealloc+0xc6>
    fileclose(*f1);
    800049b8:	853e                	mv	a0,a5
    800049ba:	00000097          	auipc	ra,0x0
    800049be:	c18080e7          	jalr	-1000(ra) # 800045d2 <fileclose>
  return -1;
    800049c2:	557d                	li	a0,-1
}
    800049c4:	70a2                	ld	ra,40(sp)
    800049c6:	7402                	ld	s0,32(sp)
    800049c8:	64e2                	ld	s1,24(sp)
    800049ca:	6942                	ld	s2,16(sp)
    800049cc:	69a2                	ld	s3,8(sp)
    800049ce:	6a02                	ld	s4,0(sp)
    800049d0:	6145                	addi	sp,sp,48
    800049d2:	8082                	ret
  return -1;
    800049d4:	557d                	li	a0,-1
    800049d6:	b7fd                	j	800049c4 <pipealloc+0xc6>

00000000800049d8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049d8:	1101                	addi	sp,sp,-32
    800049da:	ec06                	sd	ra,24(sp)
    800049dc:	e822                	sd	s0,16(sp)
    800049de:	e426                	sd	s1,8(sp)
    800049e0:	e04a                	sd	s2,0(sp)
    800049e2:	1000                	addi	s0,sp,32
    800049e4:	84aa                	mv	s1,a0
    800049e6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049e8:	ffffc097          	auipc	ra,0xffffc
    800049ec:	1ea080e7          	jalr	490(ra) # 80000bd2 <acquire>
  if(writable){
    800049f0:	02090d63          	beqz	s2,80004a2a <pipeclose+0x52>
    pi->writeopen = 0;
    800049f4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049f8:	21848513          	addi	a0,s1,536
    800049fc:	ffffd097          	auipc	ra,0xffffd
    80004a00:	6b6080e7          	jalr	1718(ra) # 800020b2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a04:	2204b783          	ld	a5,544(s1)
    80004a08:	eb95                	bnez	a5,80004a3c <pipeclose+0x64>
    release(&pi->lock);
    80004a0a:	8526                	mv	a0,s1
    80004a0c:	ffffc097          	auipc	ra,0xffffc
    80004a10:	27a080e7          	jalr	634(ra) # 80000c86 <release>
    kfree((char*)pi);
    80004a14:	8526                	mv	a0,s1
    80004a16:	ffffc097          	auipc	ra,0xffffc
    80004a1a:	fce080e7          	jalr	-50(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004a1e:	60e2                	ld	ra,24(sp)
    80004a20:	6442                	ld	s0,16(sp)
    80004a22:	64a2                	ld	s1,8(sp)
    80004a24:	6902                	ld	s2,0(sp)
    80004a26:	6105                	addi	sp,sp,32
    80004a28:	8082                	ret
    pi->readopen = 0;
    80004a2a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a2e:	21c48513          	addi	a0,s1,540
    80004a32:	ffffd097          	auipc	ra,0xffffd
    80004a36:	680080e7          	jalr	1664(ra) # 800020b2 <wakeup>
    80004a3a:	b7e9                	j	80004a04 <pipeclose+0x2c>
    release(&pi->lock);
    80004a3c:	8526                	mv	a0,s1
    80004a3e:	ffffc097          	auipc	ra,0xffffc
    80004a42:	248080e7          	jalr	584(ra) # 80000c86 <release>
}
    80004a46:	bfe1                	j	80004a1e <pipeclose+0x46>

0000000080004a48 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a48:	711d                	addi	sp,sp,-96
    80004a4a:	ec86                	sd	ra,88(sp)
    80004a4c:	e8a2                	sd	s0,80(sp)
    80004a4e:	e4a6                	sd	s1,72(sp)
    80004a50:	e0ca                	sd	s2,64(sp)
    80004a52:	fc4e                	sd	s3,56(sp)
    80004a54:	f852                	sd	s4,48(sp)
    80004a56:	f456                	sd	s5,40(sp)
    80004a58:	f05a                	sd	s6,32(sp)
    80004a5a:	ec5e                	sd	s7,24(sp)
    80004a5c:	e862                	sd	s8,16(sp)
    80004a5e:	1080                	addi	s0,sp,96
    80004a60:	84aa                	mv	s1,a0
    80004a62:	8aae                	mv	s5,a1
    80004a64:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a66:	ffffd097          	auipc	ra,0xffffd
    80004a6a:	f40080e7          	jalr	-192(ra) # 800019a6 <myproc>
    80004a6e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a70:	8526                	mv	a0,s1
    80004a72:	ffffc097          	auipc	ra,0xffffc
    80004a76:	160080e7          	jalr	352(ra) # 80000bd2 <acquire>
  while(i < n){
    80004a7a:	0b405663          	blez	s4,80004b26 <pipewrite+0xde>
  int i = 0;
    80004a7e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a80:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a82:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a86:	21c48b93          	addi	s7,s1,540
    80004a8a:	a089                	j	80004acc <pipewrite+0x84>
      release(&pi->lock);
    80004a8c:	8526                	mv	a0,s1
    80004a8e:	ffffc097          	auipc	ra,0xffffc
    80004a92:	1f8080e7          	jalr	504(ra) # 80000c86 <release>
      return -1;
    80004a96:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a98:	854a                	mv	a0,s2
    80004a9a:	60e6                	ld	ra,88(sp)
    80004a9c:	6446                	ld	s0,80(sp)
    80004a9e:	64a6                	ld	s1,72(sp)
    80004aa0:	6906                	ld	s2,64(sp)
    80004aa2:	79e2                	ld	s3,56(sp)
    80004aa4:	7a42                	ld	s4,48(sp)
    80004aa6:	7aa2                	ld	s5,40(sp)
    80004aa8:	7b02                	ld	s6,32(sp)
    80004aaa:	6be2                	ld	s7,24(sp)
    80004aac:	6c42                	ld	s8,16(sp)
    80004aae:	6125                	addi	sp,sp,96
    80004ab0:	8082                	ret
      wakeup(&pi->nread);
    80004ab2:	8562                	mv	a0,s8
    80004ab4:	ffffd097          	auipc	ra,0xffffd
    80004ab8:	5fe080e7          	jalr	1534(ra) # 800020b2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004abc:	85a6                	mv	a1,s1
    80004abe:	855e                	mv	a0,s7
    80004ac0:	ffffd097          	auipc	ra,0xffffd
    80004ac4:	58e080e7          	jalr	1422(ra) # 8000204e <sleep>
  while(i < n){
    80004ac8:	07495063          	bge	s2,s4,80004b28 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004acc:	2204a783          	lw	a5,544(s1)
    80004ad0:	dfd5                	beqz	a5,80004a8c <pipewrite+0x44>
    80004ad2:	854e                	mv	a0,s3
    80004ad4:	ffffe097          	auipc	ra,0xffffe
    80004ad8:	822080e7          	jalr	-2014(ra) # 800022f6 <killed>
    80004adc:	f945                	bnez	a0,80004a8c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ade:	2184a783          	lw	a5,536(s1)
    80004ae2:	21c4a703          	lw	a4,540(s1)
    80004ae6:	2007879b          	addiw	a5,a5,512
    80004aea:	fcf704e3          	beq	a4,a5,80004ab2 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004aee:	4685                	li	a3,1
    80004af0:	01590633          	add	a2,s2,s5
    80004af4:	faf40593          	addi	a1,s0,-81
    80004af8:	0509b503          	ld	a0,80(s3)
    80004afc:	ffffd097          	auipc	ra,0xffffd
    80004b00:	bf6080e7          	jalr	-1034(ra) # 800016f2 <copyin>
    80004b04:	03650263          	beq	a0,s6,80004b28 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b08:	21c4a783          	lw	a5,540(s1)
    80004b0c:	0017871b          	addiw	a4,a5,1
    80004b10:	20e4ae23          	sw	a4,540(s1)
    80004b14:	1ff7f793          	andi	a5,a5,511
    80004b18:	97a6                	add	a5,a5,s1
    80004b1a:	faf44703          	lbu	a4,-81(s0)
    80004b1e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b22:	2905                	addiw	s2,s2,1
    80004b24:	b755                	j	80004ac8 <pipewrite+0x80>
  int i = 0;
    80004b26:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b28:	21848513          	addi	a0,s1,536
    80004b2c:	ffffd097          	auipc	ra,0xffffd
    80004b30:	586080e7          	jalr	1414(ra) # 800020b2 <wakeup>
  release(&pi->lock);
    80004b34:	8526                	mv	a0,s1
    80004b36:	ffffc097          	auipc	ra,0xffffc
    80004b3a:	150080e7          	jalr	336(ra) # 80000c86 <release>
  return i;
    80004b3e:	bfa9                	j	80004a98 <pipewrite+0x50>

0000000080004b40 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b40:	715d                	addi	sp,sp,-80
    80004b42:	e486                	sd	ra,72(sp)
    80004b44:	e0a2                	sd	s0,64(sp)
    80004b46:	fc26                	sd	s1,56(sp)
    80004b48:	f84a                	sd	s2,48(sp)
    80004b4a:	f44e                	sd	s3,40(sp)
    80004b4c:	f052                	sd	s4,32(sp)
    80004b4e:	ec56                	sd	s5,24(sp)
    80004b50:	e85a                	sd	s6,16(sp)
    80004b52:	0880                	addi	s0,sp,80
    80004b54:	84aa                	mv	s1,a0
    80004b56:	892e                	mv	s2,a1
    80004b58:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b5a:	ffffd097          	auipc	ra,0xffffd
    80004b5e:	e4c080e7          	jalr	-436(ra) # 800019a6 <myproc>
    80004b62:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b64:	8526                	mv	a0,s1
    80004b66:	ffffc097          	auipc	ra,0xffffc
    80004b6a:	06c080e7          	jalr	108(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b6e:	2184a703          	lw	a4,536(s1)
    80004b72:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b76:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b7a:	02f71763          	bne	a4,a5,80004ba8 <piperead+0x68>
    80004b7e:	2244a783          	lw	a5,548(s1)
    80004b82:	c39d                	beqz	a5,80004ba8 <piperead+0x68>
    if(killed(pr)){
    80004b84:	8552                	mv	a0,s4
    80004b86:	ffffd097          	auipc	ra,0xffffd
    80004b8a:	770080e7          	jalr	1904(ra) # 800022f6 <killed>
    80004b8e:	e949                	bnez	a0,80004c20 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b90:	85a6                	mv	a1,s1
    80004b92:	854e                	mv	a0,s3
    80004b94:	ffffd097          	auipc	ra,0xffffd
    80004b98:	4ba080e7          	jalr	1210(ra) # 8000204e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b9c:	2184a703          	lw	a4,536(s1)
    80004ba0:	21c4a783          	lw	a5,540(s1)
    80004ba4:	fcf70de3          	beq	a4,a5,80004b7e <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ba8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004baa:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bac:	05505463          	blez	s5,80004bf4 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004bb0:	2184a783          	lw	a5,536(s1)
    80004bb4:	21c4a703          	lw	a4,540(s1)
    80004bb8:	02f70e63          	beq	a4,a5,80004bf4 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bbc:	0017871b          	addiw	a4,a5,1
    80004bc0:	20e4ac23          	sw	a4,536(s1)
    80004bc4:	1ff7f793          	andi	a5,a5,511
    80004bc8:	97a6                	add	a5,a5,s1
    80004bca:	0187c783          	lbu	a5,24(a5)
    80004bce:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bd2:	4685                	li	a3,1
    80004bd4:	fbf40613          	addi	a2,s0,-65
    80004bd8:	85ca                	mv	a1,s2
    80004bda:	050a3503          	ld	a0,80(s4)
    80004bde:	ffffd097          	auipc	ra,0xffffd
    80004be2:	a88080e7          	jalr	-1400(ra) # 80001666 <copyout>
    80004be6:	01650763          	beq	a0,s6,80004bf4 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bea:	2985                	addiw	s3,s3,1
    80004bec:	0905                	addi	s2,s2,1
    80004bee:	fd3a91e3          	bne	s5,s3,80004bb0 <piperead+0x70>
    80004bf2:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bf4:	21c48513          	addi	a0,s1,540
    80004bf8:	ffffd097          	auipc	ra,0xffffd
    80004bfc:	4ba080e7          	jalr	1210(ra) # 800020b2 <wakeup>
  release(&pi->lock);
    80004c00:	8526                	mv	a0,s1
    80004c02:	ffffc097          	auipc	ra,0xffffc
    80004c06:	084080e7          	jalr	132(ra) # 80000c86 <release>
  return i;
}
    80004c0a:	854e                	mv	a0,s3
    80004c0c:	60a6                	ld	ra,72(sp)
    80004c0e:	6406                	ld	s0,64(sp)
    80004c10:	74e2                	ld	s1,56(sp)
    80004c12:	7942                	ld	s2,48(sp)
    80004c14:	79a2                	ld	s3,40(sp)
    80004c16:	7a02                	ld	s4,32(sp)
    80004c18:	6ae2                	ld	s5,24(sp)
    80004c1a:	6b42                	ld	s6,16(sp)
    80004c1c:	6161                	addi	sp,sp,80
    80004c1e:	8082                	ret
      release(&pi->lock);
    80004c20:	8526                	mv	a0,s1
    80004c22:	ffffc097          	auipc	ra,0xffffc
    80004c26:	064080e7          	jalr	100(ra) # 80000c86 <release>
      return -1;
    80004c2a:	59fd                	li	s3,-1
    80004c2c:	bff9                	j	80004c0a <piperead+0xca>

0000000080004c2e <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004c2e:	1141                	addi	sp,sp,-16
    80004c30:	e422                	sd	s0,8(sp)
    80004c32:	0800                	addi	s0,sp,16
    80004c34:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004c36:	8905                	andi	a0,a0,1
    80004c38:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004c3a:	8b89                	andi	a5,a5,2
    80004c3c:	c399                	beqz	a5,80004c42 <flags2perm+0x14>
      perm |= PTE_W;
    80004c3e:	00456513          	ori	a0,a0,4
    return perm;
}
    80004c42:	6422                	ld	s0,8(sp)
    80004c44:	0141                	addi	sp,sp,16
    80004c46:	8082                	ret

0000000080004c48 <exec>:

int
exec(char *path, char **argv)
{
    80004c48:	df010113          	addi	sp,sp,-528
    80004c4c:	20113423          	sd	ra,520(sp)
    80004c50:	20813023          	sd	s0,512(sp)
    80004c54:	ffa6                	sd	s1,504(sp)
    80004c56:	fbca                	sd	s2,496(sp)
    80004c58:	f7ce                	sd	s3,488(sp)
    80004c5a:	f3d2                	sd	s4,480(sp)
    80004c5c:	efd6                	sd	s5,472(sp)
    80004c5e:	ebda                	sd	s6,464(sp)
    80004c60:	e7de                	sd	s7,456(sp)
    80004c62:	e3e2                	sd	s8,448(sp)
    80004c64:	ff66                	sd	s9,440(sp)
    80004c66:	fb6a                	sd	s10,432(sp)
    80004c68:	f76e                	sd	s11,424(sp)
    80004c6a:	0c00                	addi	s0,sp,528
    80004c6c:	892a                	mv	s2,a0
    80004c6e:	dea43c23          	sd	a0,-520(s0)
    80004c72:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c76:	ffffd097          	auipc	ra,0xffffd
    80004c7a:	d30080e7          	jalr	-720(ra) # 800019a6 <myproc>
    80004c7e:	84aa                	mv	s1,a0

  begin_op();
    80004c80:	fffff097          	auipc	ra,0xfffff
    80004c84:	48e080e7          	jalr	1166(ra) # 8000410e <begin_op>

  if((ip = namei(path)) == 0){
    80004c88:	854a                	mv	a0,s2
    80004c8a:	fffff097          	auipc	ra,0xfffff
    80004c8e:	284080e7          	jalr	644(ra) # 80003f0e <namei>
    80004c92:	c92d                	beqz	a0,80004d04 <exec+0xbc>
    80004c94:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c96:	fffff097          	auipc	ra,0xfffff
    80004c9a:	ad2080e7          	jalr	-1326(ra) # 80003768 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c9e:	04000713          	li	a4,64
    80004ca2:	4681                	li	a3,0
    80004ca4:	e5040613          	addi	a2,s0,-432
    80004ca8:	4581                	li	a1,0
    80004caa:	8552                	mv	a0,s4
    80004cac:	fffff097          	auipc	ra,0xfffff
    80004cb0:	d70080e7          	jalr	-656(ra) # 80003a1c <readi>
    80004cb4:	04000793          	li	a5,64
    80004cb8:	00f51a63          	bne	a0,a5,80004ccc <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004cbc:	e5042703          	lw	a4,-432(s0)
    80004cc0:	464c47b7          	lui	a5,0x464c4
    80004cc4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004cc8:	04f70463          	beq	a4,a5,80004d10 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ccc:	8552                	mv	a0,s4
    80004cce:	fffff097          	auipc	ra,0xfffff
    80004cd2:	cfc080e7          	jalr	-772(ra) # 800039ca <iunlockput>
    end_op();
    80004cd6:	fffff097          	auipc	ra,0xfffff
    80004cda:	4b2080e7          	jalr	1202(ra) # 80004188 <end_op>
  }
  return -1;
    80004cde:	557d                	li	a0,-1
}
    80004ce0:	20813083          	ld	ra,520(sp)
    80004ce4:	20013403          	ld	s0,512(sp)
    80004ce8:	74fe                	ld	s1,504(sp)
    80004cea:	795e                	ld	s2,496(sp)
    80004cec:	79be                	ld	s3,488(sp)
    80004cee:	7a1e                	ld	s4,480(sp)
    80004cf0:	6afe                	ld	s5,472(sp)
    80004cf2:	6b5e                	ld	s6,464(sp)
    80004cf4:	6bbe                	ld	s7,456(sp)
    80004cf6:	6c1e                	ld	s8,448(sp)
    80004cf8:	7cfa                	ld	s9,440(sp)
    80004cfa:	7d5a                	ld	s10,432(sp)
    80004cfc:	7dba                	ld	s11,424(sp)
    80004cfe:	21010113          	addi	sp,sp,528
    80004d02:	8082                	ret
    end_op();
    80004d04:	fffff097          	auipc	ra,0xfffff
    80004d08:	484080e7          	jalr	1156(ra) # 80004188 <end_op>
    return -1;
    80004d0c:	557d                	li	a0,-1
    80004d0e:	bfc9                	j	80004ce0 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d10:	8526                	mv	a0,s1
    80004d12:	ffffd097          	auipc	ra,0xffffd
    80004d16:	d58080e7          	jalr	-680(ra) # 80001a6a <proc_pagetable>
    80004d1a:	8b2a                	mv	s6,a0
    80004d1c:	d945                	beqz	a0,80004ccc <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d1e:	e7042d03          	lw	s10,-400(s0)
    80004d22:	e8845783          	lhu	a5,-376(s0)
    80004d26:	10078463          	beqz	a5,80004e2e <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d2a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d2c:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004d2e:	6c85                	lui	s9,0x1
    80004d30:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d34:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004d38:	6a85                	lui	s5,0x1
    80004d3a:	a0b5                	j	80004da6 <exec+0x15e>
      panic("loadseg: address should exist");
    80004d3c:	00004517          	auipc	a0,0x4
    80004d40:	a6450513          	addi	a0,a0,-1436 # 800087a0 <stateString.0+0x200>
    80004d44:	ffffb097          	auipc	ra,0xffffb
    80004d48:	7f8080e7          	jalr	2040(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80004d4c:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d4e:	8726                	mv	a4,s1
    80004d50:	012c06bb          	addw	a3,s8,s2
    80004d54:	4581                	li	a1,0
    80004d56:	8552                	mv	a0,s4
    80004d58:	fffff097          	auipc	ra,0xfffff
    80004d5c:	cc4080e7          	jalr	-828(ra) # 80003a1c <readi>
    80004d60:	2501                	sext.w	a0,a0
    80004d62:	24a49863          	bne	s1,a0,80004fb2 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    80004d66:	012a893b          	addw	s2,s5,s2
    80004d6a:	03397563          	bgeu	s2,s3,80004d94 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80004d6e:	02091593          	slli	a1,s2,0x20
    80004d72:	9181                	srli	a1,a1,0x20
    80004d74:	95de                	add	a1,a1,s7
    80004d76:	855a                	mv	a0,s6
    80004d78:	ffffc097          	auipc	ra,0xffffc
    80004d7c:	2de080e7          	jalr	734(ra) # 80001056 <walkaddr>
    80004d80:	862a                	mv	a2,a0
    if(pa == 0)
    80004d82:	dd4d                	beqz	a0,80004d3c <exec+0xf4>
    if(sz - i < PGSIZE)
    80004d84:	412984bb          	subw	s1,s3,s2
    80004d88:	0004879b          	sext.w	a5,s1
    80004d8c:	fcfcf0e3          	bgeu	s9,a5,80004d4c <exec+0x104>
    80004d90:	84d6                	mv	s1,s5
    80004d92:	bf6d                	j	80004d4c <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004d94:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d98:	2d85                	addiw	s11,s11,1
    80004d9a:	038d0d1b          	addiw	s10,s10,56
    80004d9e:	e8845783          	lhu	a5,-376(s0)
    80004da2:	08fdd763          	bge	s11,a5,80004e30 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004da6:	2d01                	sext.w	s10,s10
    80004da8:	03800713          	li	a4,56
    80004dac:	86ea                	mv	a3,s10
    80004dae:	e1840613          	addi	a2,s0,-488
    80004db2:	4581                	li	a1,0
    80004db4:	8552                	mv	a0,s4
    80004db6:	fffff097          	auipc	ra,0xfffff
    80004dba:	c66080e7          	jalr	-922(ra) # 80003a1c <readi>
    80004dbe:	03800793          	li	a5,56
    80004dc2:	1ef51663          	bne	a0,a5,80004fae <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    80004dc6:	e1842783          	lw	a5,-488(s0)
    80004dca:	4705                	li	a4,1
    80004dcc:	fce796e3          	bne	a5,a4,80004d98 <exec+0x150>
    if(ph.memsz < ph.filesz)
    80004dd0:	e4043483          	ld	s1,-448(s0)
    80004dd4:	e3843783          	ld	a5,-456(s0)
    80004dd8:	1ef4e863          	bltu	s1,a5,80004fc8 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004ddc:	e2843783          	ld	a5,-472(s0)
    80004de0:	94be                	add	s1,s1,a5
    80004de2:	1ef4e663          	bltu	s1,a5,80004fce <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    80004de6:	df043703          	ld	a4,-528(s0)
    80004dea:	8ff9                	and	a5,a5,a4
    80004dec:	1e079463          	bnez	a5,80004fd4 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004df0:	e1c42503          	lw	a0,-484(s0)
    80004df4:	00000097          	auipc	ra,0x0
    80004df8:	e3a080e7          	jalr	-454(ra) # 80004c2e <flags2perm>
    80004dfc:	86aa                	mv	a3,a0
    80004dfe:	8626                	mv	a2,s1
    80004e00:	85ca                	mv	a1,s2
    80004e02:	855a                	mv	a0,s6
    80004e04:	ffffc097          	auipc	ra,0xffffc
    80004e08:	606080e7          	jalr	1542(ra) # 8000140a <uvmalloc>
    80004e0c:	e0a43423          	sd	a0,-504(s0)
    80004e10:	1c050563          	beqz	a0,80004fda <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004e14:	e2843b83          	ld	s7,-472(s0)
    80004e18:	e2042c03          	lw	s8,-480(s0)
    80004e1c:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004e20:	00098463          	beqz	s3,80004e28 <exec+0x1e0>
    80004e24:	4901                	li	s2,0
    80004e26:	b7a1                	j	80004d6e <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004e28:	e0843903          	ld	s2,-504(s0)
    80004e2c:	b7b5                	j	80004d98 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e2e:	4901                	li	s2,0
  iunlockput(ip);
    80004e30:	8552                	mv	a0,s4
    80004e32:	fffff097          	auipc	ra,0xfffff
    80004e36:	b98080e7          	jalr	-1128(ra) # 800039ca <iunlockput>
  end_op();
    80004e3a:	fffff097          	auipc	ra,0xfffff
    80004e3e:	34e080e7          	jalr	846(ra) # 80004188 <end_op>
  p = myproc();
    80004e42:	ffffd097          	auipc	ra,0xffffd
    80004e46:	b64080e7          	jalr	-1180(ra) # 800019a6 <myproc>
    80004e4a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e4c:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004e50:	6985                	lui	s3,0x1
    80004e52:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004e54:	99ca                	add	s3,s3,s2
    80004e56:	77fd                	lui	a5,0xfffff
    80004e58:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e5c:	4691                	li	a3,4
    80004e5e:	6609                	lui	a2,0x2
    80004e60:	964e                	add	a2,a2,s3
    80004e62:	85ce                	mv	a1,s3
    80004e64:	855a                	mv	a0,s6
    80004e66:	ffffc097          	auipc	ra,0xffffc
    80004e6a:	5a4080e7          	jalr	1444(ra) # 8000140a <uvmalloc>
    80004e6e:	892a                	mv	s2,a0
    80004e70:	e0a43423          	sd	a0,-504(s0)
    80004e74:	e509                	bnez	a0,80004e7e <exec+0x236>
  if(pagetable)
    80004e76:	e1343423          	sd	s3,-504(s0)
    80004e7a:	4a01                	li	s4,0
    80004e7c:	aa1d                	j	80004fb2 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e7e:	75f9                	lui	a1,0xffffe
    80004e80:	95aa                	add	a1,a1,a0
    80004e82:	855a                	mv	a0,s6
    80004e84:	ffffc097          	auipc	ra,0xffffc
    80004e88:	7b0080e7          	jalr	1968(ra) # 80001634 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e8c:	7bfd                	lui	s7,0xfffff
    80004e8e:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004e90:	e0043783          	ld	a5,-512(s0)
    80004e94:	6388                	ld	a0,0(a5)
    80004e96:	c52d                	beqz	a0,80004f00 <exec+0x2b8>
    80004e98:	e9040993          	addi	s3,s0,-368
    80004e9c:	f9040c13          	addi	s8,s0,-112
    80004ea0:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004ea2:	ffffc097          	auipc	ra,0xffffc
    80004ea6:	fa6080e7          	jalr	-90(ra) # 80000e48 <strlen>
    80004eaa:	0015079b          	addiw	a5,a0,1
    80004eae:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004eb2:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004eb6:	13796563          	bltu	s2,s7,80004fe0 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004eba:	e0043d03          	ld	s10,-512(s0)
    80004ebe:	000d3a03          	ld	s4,0(s10)
    80004ec2:	8552                	mv	a0,s4
    80004ec4:	ffffc097          	auipc	ra,0xffffc
    80004ec8:	f84080e7          	jalr	-124(ra) # 80000e48 <strlen>
    80004ecc:	0015069b          	addiw	a3,a0,1
    80004ed0:	8652                	mv	a2,s4
    80004ed2:	85ca                	mv	a1,s2
    80004ed4:	855a                	mv	a0,s6
    80004ed6:	ffffc097          	auipc	ra,0xffffc
    80004eda:	790080e7          	jalr	1936(ra) # 80001666 <copyout>
    80004ede:	10054363          	bltz	a0,80004fe4 <exec+0x39c>
    ustack[argc] = sp;
    80004ee2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ee6:	0485                	addi	s1,s1,1
    80004ee8:	008d0793          	addi	a5,s10,8
    80004eec:	e0f43023          	sd	a5,-512(s0)
    80004ef0:	008d3503          	ld	a0,8(s10)
    80004ef4:	c909                	beqz	a0,80004f06 <exec+0x2be>
    if(argc >= MAXARG)
    80004ef6:	09a1                	addi	s3,s3,8
    80004ef8:	fb8995e3          	bne	s3,s8,80004ea2 <exec+0x25a>
  ip = 0;
    80004efc:	4a01                	li	s4,0
    80004efe:	a855                	j	80004fb2 <exec+0x36a>
  sp = sz;
    80004f00:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004f04:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f06:	00349793          	slli	a5,s1,0x3
    80004f0a:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdd180>
    80004f0e:	97a2                	add	a5,a5,s0
    80004f10:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004f14:	00148693          	addi	a3,s1,1
    80004f18:	068e                	slli	a3,a3,0x3
    80004f1a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f1e:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80004f22:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004f26:	f57968e3          	bltu	s2,s7,80004e76 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f2a:	e9040613          	addi	a2,s0,-368
    80004f2e:	85ca                	mv	a1,s2
    80004f30:	855a                	mv	a0,s6
    80004f32:	ffffc097          	auipc	ra,0xffffc
    80004f36:	734080e7          	jalr	1844(ra) # 80001666 <copyout>
    80004f3a:	0a054763          	bltz	a0,80004fe8 <exec+0x3a0>
  p->trapframe->a1 = sp;
    80004f3e:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004f42:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f46:	df843783          	ld	a5,-520(s0)
    80004f4a:	0007c703          	lbu	a4,0(a5)
    80004f4e:	cf11                	beqz	a4,80004f6a <exec+0x322>
    80004f50:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f52:	02f00693          	li	a3,47
    80004f56:	a039                	j	80004f64 <exec+0x31c>
      last = s+1;
    80004f58:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f5c:	0785                	addi	a5,a5,1
    80004f5e:	fff7c703          	lbu	a4,-1(a5)
    80004f62:	c701                	beqz	a4,80004f6a <exec+0x322>
    if(*s == '/')
    80004f64:	fed71ce3          	bne	a4,a3,80004f5c <exec+0x314>
    80004f68:	bfc5                	j	80004f58 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f6a:	4641                	li	a2,16
    80004f6c:	df843583          	ld	a1,-520(s0)
    80004f70:	158a8513          	addi	a0,s5,344
    80004f74:	ffffc097          	auipc	ra,0xffffc
    80004f78:	ea2080e7          	jalr	-350(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f7c:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f80:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80004f84:	e0843783          	ld	a5,-504(s0)
    80004f88:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f8c:	058ab783          	ld	a5,88(s5)
    80004f90:	e6843703          	ld	a4,-408(s0)
    80004f94:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f96:	058ab783          	ld	a5,88(s5)
    80004f9a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f9e:	85e6                	mv	a1,s9
    80004fa0:	ffffd097          	auipc	ra,0xffffd
    80004fa4:	b66080e7          	jalr	-1178(ra) # 80001b06 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fa8:	0004851b          	sext.w	a0,s1
    80004fac:	bb15                	j	80004ce0 <exec+0x98>
    80004fae:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004fb2:	e0843583          	ld	a1,-504(s0)
    80004fb6:	855a                	mv	a0,s6
    80004fb8:	ffffd097          	auipc	ra,0xffffd
    80004fbc:	b4e080e7          	jalr	-1202(ra) # 80001b06 <proc_freepagetable>
  return -1;
    80004fc0:	557d                	li	a0,-1
  if(ip){
    80004fc2:	d00a0fe3          	beqz	s4,80004ce0 <exec+0x98>
    80004fc6:	b319                	j	80004ccc <exec+0x84>
    80004fc8:	e1243423          	sd	s2,-504(s0)
    80004fcc:	b7dd                	j	80004fb2 <exec+0x36a>
    80004fce:	e1243423          	sd	s2,-504(s0)
    80004fd2:	b7c5                	j	80004fb2 <exec+0x36a>
    80004fd4:	e1243423          	sd	s2,-504(s0)
    80004fd8:	bfe9                	j	80004fb2 <exec+0x36a>
    80004fda:	e1243423          	sd	s2,-504(s0)
    80004fde:	bfd1                	j	80004fb2 <exec+0x36a>
  ip = 0;
    80004fe0:	4a01                	li	s4,0
    80004fe2:	bfc1                	j	80004fb2 <exec+0x36a>
    80004fe4:	4a01                	li	s4,0
  if(pagetable)
    80004fe6:	b7f1                	j	80004fb2 <exec+0x36a>
  sz = sz1;
    80004fe8:	e0843983          	ld	s3,-504(s0)
    80004fec:	b569                	j	80004e76 <exec+0x22e>

0000000080004fee <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004fee:	7179                	addi	sp,sp,-48
    80004ff0:	f406                	sd	ra,40(sp)
    80004ff2:	f022                	sd	s0,32(sp)
    80004ff4:	ec26                	sd	s1,24(sp)
    80004ff6:	e84a                	sd	s2,16(sp)
    80004ff8:	1800                	addi	s0,sp,48
    80004ffa:	892e                	mv	s2,a1
    80004ffc:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004ffe:	fdc40593          	addi	a1,s0,-36
    80005002:	ffffe097          	auipc	ra,0xffffe
    80005006:	b2a080e7          	jalr	-1238(ra) # 80002b2c <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000500a:	fdc42703          	lw	a4,-36(s0)
    8000500e:	47bd                	li	a5,15
    80005010:	02e7eb63          	bltu	a5,a4,80005046 <argfd+0x58>
    80005014:	ffffd097          	auipc	ra,0xffffd
    80005018:	992080e7          	jalr	-1646(ra) # 800019a6 <myproc>
    8000501c:	fdc42703          	lw	a4,-36(s0)
    80005020:	01a70793          	addi	a5,a4,26
    80005024:	078e                	slli	a5,a5,0x3
    80005026:	953e                	add	a0,a0,a5
    80005028:	611c                	ld	a5,0(a0)
    8000502a:	c385                	beqz	a5,8000504a <argfd+0x5c>
    return -1;
  if(pfd)
    8000502c:	00090463          	beqz	s2,80005034 <argfd+0x46>
    *pfd = fd;
    80005030:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005034:	4501                	li	a0,0
  if(pf)
    80005036:	c091                	beqz	s1,8000503a <argfd+0x4c>
    *pf = f;
    80005038:	e09c                	sd	a5,0(s1)
}
    8000503a:	70a2                	ld	ra,40(sp)
    8000503c:	7402                	ld	s0,32(sp)
    8000503e:	64e2                	ld	s1,24(sp)
    80005040:	6942                	ld	s2,16(sp)
    80005042:	6145                	addi	sp,sp,48
    80005044:	8082                	ret
    return -1;
    80005046:	557d                	li	a0,-1
    80005048:	bfcd                	j	8000503a <argfd+0x4c>
    8000504a:	557d                	li	a0,-1
    8000504c:	b7fd                	j	8000503a <argfd+0x4c>

000000008000504e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000504e:	1101                	addi	sp,sp,-32
    80005050:	ec06                	sd	ra,24(sp)
    80005052:	e822                	sd	s0,16(sp)
    80005054:	e426                	sd	s1,8(sp)
    80005056:	1000                	addi	s0,sp,32
    80005058:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000505a:	ffffd097          	auipc	ra,0xffffd
    8000505e:	94c080e7          	jalr	-1716(ra) # 800019a6 <myproc>
    80005062:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005064:	0d050793          	addi	a5,a0,208
    80005068:	4501                	li	a0,0
    8000506a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000506c:	6398                	ld	a4,0(a5)
    8000506e:	cb19                	beqz	a4,80005084 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005070:	2505                	addiw	a0,a0,1
    80005072:	07a1                	addi	a5,a5,8
    80005074:	fed51ce3          	bne	a0,a3,8000506c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005078:	557d                	li	a0,-1
}
    8000507a:	60e2                	ld	ra,24(sp)
    8000507c:	6442                	ld	s0,16(sp)
    8000507e:	64a2                	ld	s1,8(sp)
    80005080:	6105                	addi	sp,sp,32
    80005082:	8082                	ret
      p->ofile[fd] = f;
    80005084:	01a50793          	addi	a5,a0,26
    80005088:	078e                	slli	a5,a5,0x3
    8000508a:	963e                	add	a2,a2,a5
    8000508c:	e204                	sd	s1,0(a2)
      return fd;
    8000508e:	b7f5                	j	8000507a <fdalloc+0x2c>

0000000080005090 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005090:	715d                	addi	sp,sp,-80
    80005092:	e486                	sd	ra,72(sp)
    80005094:	e0a2                	sd	s0,64(sp)
    80005096:	fc26                	sd	s1,56(sp)
    80005098:	f84a                	sd	s2,48(sp)
    8000509a:	f44e                	sd	s3,40(sp)
    8000509c:	f052                	sd	s4,32(sp)
    8000509e:	ec56                	sd	s5,24(sp)
    800050a0:	e85a                	sd	s6,16(sp)
    800050a2:	0880                	addi	s0,sp,80
    800050a4:	8b2e                	mv	s6,a1
    800050a6:	89b2                	mv	s3,a2
    800050a8:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050aa:	fb040593          	addi	a1,s0,-80
    800050ae:	fffff097          	auipc	ra,0xfffff
    800050b2:	e7e080e7          	jalr	-386(ra) # 80003f2c <nameiparent>
    800050b6:	84aa                	mv	s1,a0
    800050b8:	14050b63          	beqz	a0,8000520e <create+0x17e>
    return 0;

  ilock(dp);
    800050bc:	ffffe097          	auipc	ra,0xffffe
    800050c0:	6ac080e7          	jalr	1708(ra) # 80003768 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050c4:	4601                	li	a2,0
    800050c6:	fb040593          	addi	a1,s0,-80
    800050ca:	8526                	mv	a0,s1
    800050cc:	fffff097          	auipc	ra,0xfffff
    800050d0:	b80080e7          	jalr	-1152(ra) # 80003c4c <dirlookup>
    800050d4:	8aaa                	mv	s5,a0
    800050d6:	c921                	beqz	a0,80005126 <create+0x96>
    iunlockput(dp);
    800050d8:	8526                	mv	a0,s1
    800050da:	fffff097          	auipc	ra,0xfffff
    800050de:	8f0080e7          	jalr	-1808(ra) # 800039ca <iunlockput>
    ilock(ip);
    800050e2:	8556                	mv	a0,s5
    800050e4:	ffffe097          	auipc	ra,0xffffe
    800050e8:	684080e7          	jalr	1668(ra) # 80003768 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050ec:	4789                	li	a5,2
    800050ee:	02fb1563          	bne	s6,a5,80005118 <create+0x88>
    800050f2:	044ad783          	lhu	a5,68(s5)
    800050f6:	37f9                	addiw	a5,a5,-2
    800050f8:	17c2                	slli	a5,a5,0x30
    800050fa:	93c1                	srli	a5,a5,0x30
    800050fc:	4705                	li	a4,1
    800050fe:	00f76d63          	bltu	a4,a5,80005118 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005102:	8556                	mv	a0,s5
    80005104:	60a6                	ld	ra,72(sp)
    80005106:	6406                	ld	s0,64(sp)
    80005108:	74e2                	ld	s1,56(sp)
    8000510a:	7942                	ld	s2,48(sp)
    8000510c:	79a2                	ld	s3,40(sp)
    8000510e:	7a02                	ld	s4,32(sp)
    80005110:	6ae2                	ld	s5,24(sp)
    80005112:	6b42                	ld	s6,16(sp)
    80005114:	6161                	addi	sp,sp,80
    80005116:	8082                	ret
    iunlockput(ip);
    80005118:	8556                	mv	a0,s5
    8000511a:	fffff097          	auipc	ra,0xfffff
    8000511e:	8b0080e7          	jalr	-1872(ra) # 800039ca <iunlockput>
    return 0;
    80005122:	4a81                	li	s5,0
    80005124:	bff9                	j	80005102 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005126:	85da                	mv	a1,s6
    80005128:	4088                	lw	a0,0(s1)
    8000512a:	ffffe097          	auipc	ra,0xffffe
    8000512e:	4a6080e7          	jalr	1190(ra) # 800035d0 <ialloc>
    80005132:	8a2a                	mv	s4,a0
    80005134:	c529                	beqz	a0,8000517e <create+0xee>
  ilock(ip);
    80005136:	ffffe097          	auipc	ra,0xffffe
    8000513a:	632080e7          	jalr	1586(ra) # 80003768 <ilock>
  ip->major = major;
    8000513e:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005142:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005146:	4905                	li	s2,1
    80005148:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000514c:	8552                	mv	a0,s4
    8000514e:	ffffe097          	auipc	ra,0xffffe
    80005152:	54e080e7          	jalr	1358(ra) # 8000369c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005156:	032b0b63          	beq	s6,s2,8000518c <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000515a:	004a2603          	lw	a2,4(s4)
    8000515e:	fb040593          	addi	a1,s0,-80
    80005162:	8526                	mv	a0,s1
    80005164:	fffff097          	auipc	ra,0xfffff
    80005168:	cf8080e7          	jalr	-776(ra) # 80003e5c <dirlink>
    8000516c:	06054f63          	bltz	a0,800051ea <create+0x15a>
  iunlockput(dp);
    80005170:	8526                	mv	a0,s1
    80005172:	fffff097          	auipc	ra,0xfffff
    80005176:	858080e7          	jalr	-1960(ra) # 800039ca <iunlockput>
  return ip;
    8000517a:	8ad2                	mv	s5,s4
    8000517c:	b759                	j	80005102 <create+0x72>
    iunlockput(dp);
    8000517e:	8526                	mv	a0,s1
    80005180:	fffff097          	auipc	ra,0xfffff
    80005184:	84a080e7          	jalr	-1974(ra) # 800039ca <iunlockput>
    return 0;
    80005188:	8ad2                	mv	s5,s4
    8000518a:	bfa5                	j	80005102 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000518c:	004a2603          	lw	a2,4(s4)
    80005190:	00003597          	auipc	a1,0x3
    80005194:	63058593          	addi	a1,a1,1584 # 800087c0 <stateString.0+0x220>
    80005198:	8552                	mv	a0,s4
    8000519a:	fffff097          	auipc	ra,0xfffff
    8000519e:	cc2080e7          	jalr	-830(ra) # 80003e5c <dirlink>
    800051a2:	04054463          	bltz	a0,800051ea <create+0x15a>
    800051a6:	40d0                	lw	a2,4(s1)
    800051a8:	00003597          	auipc	a1,0x3
    800051ac:	62058593          	addi	a1,a1,1568 # 800087c8 <stateString.0+0x228>
    800051b0:	8552                	mv	a0,s4
    800051b2:	fffff097          	auipc	ra,0xfffff
    800051b6:	caa080e7          	jalr	-854(ra) # 80003e5c <dirlink>
    800051ba:	02054863          	bltz	a0,800051ea <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    800051be:	004a2603          	lw	a2,4(s4)
    800051c2:	fb040593          	addi	a1,s0,-80
    800051c6:	8526                	mv	a0,s1
    800051c8:	fffff097          	auipc	ra,0xfffff
    800051cc:	c94080e7          	jalr	-876(ra) # 80003e5c <dirlink>
    800051d0:	00054d63          	bltz	a0,800051ea <create+0x15a>
    dp->nlink++;  // for ".."
    800051d4:	04a4d783          	lhu	a5,74(s1)
    800051d8:	2785                	addiw	a5,a5,1
    800051da:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800051de:	8526                	mv	a0,s1
    800051e0:	ffffe097          	auipc	ra,0xffffe
    800051e4:	4bc080e7          	jalr	1212(ra) # 8000369c <iupdate>
    800051e8:	b761                	j	80005170 <create+0xe0>
  ip->nlink = 0;
    800051ea:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800051ee:	8552                	mv	a0,s4
    800051f0:	ffffe097          	auipc	ra,0xffffe
    800051f4:	4ac080e7          	jalr	1196(ra) # 8000369c <iupdate>
  iunlockput(ip);
    800051f8:	8552                	mv	a0,s4
    800051fa:	ffffe097          	auipc	ra,0xffffe
    800051fe:	7d0080e7          	jalr	2000(ra) # 800039ca <iunlockput>
  iunlockput(dp);
    80005202:	8526                	mv	a0,s1
    80005204:	ffffe097          	auipc	ra,0xffffe
    80005208:	7c6080e7          	jalr	1990(ra) # 800039ca <iunlockput>
  return 0;
    8000520c:	bddd                	j	80005102 <create+0x72>
    return 0;
    8000520e:	8aaa                	mv	s5,a0
    80005210:	bdcd                	j	80005102 <create+0x72>

0000000080005212 <sys_dup>:
{
    80005212:	7179                	addi	sp,sp,-48
    80005214:	f406                	sd	ra,40(sp)
    80005216:	f022                	sd	s0,32(sp)
    80005218:	ec26                	sd	s1,24(sp)
    8000521a:	e84a                	sd	s2,16(sp)
    8000521c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000521e:	fd840613          	addi	a2,s0,-40
    80005222:	4581                	li	a1,0
    80005224:	4501                	li	a0,0
    80005226:	00000097          	auipc	ra,0x0
    8000522a:	dc8080e7          	jalr	-568(ra) # 80004fee <argfd>
    return -1;
    8000522e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005230:	02054363          	bltz	a0,80005256 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005234:	fd843903          	ld	s2,-40(s0)
    80005238:	854a                	mv	a0,s2
    8000523a:	00000097          	auipc	ra,0x0
    8000523e:	e14080e7          	jalr	-492(ra) # 8000504e <fdalloc>
    80005242:	84aa                	mv	s1,a0
    return -1;
    80005244:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005246:	00054863          	bltz	a0,80005256 <sys_dup+0x44>
  filedup(f);
    8000524a:	854a                	mv	a0,s2
    8000524c:	fffff097          	auipc	ra,0xfffff
    80005250:	334080e7          	jalr	820(ra) # 80004580 <filedup>
  return fd;
    80005254:	87a6                	mv	a5,s1
}
    80005256:	853e                	mv	a0,a5
    80005258:	70a2                	ld	ra,40(sp)
    8000525a:	7402                	ld	s0,32(sp)
    8000525c:	64e2                	ld	s1,24(sp)
    8000525e:	6942                	ld	s2,16(sp)
    80005260:	6145                	addi	sp,sp,48
    80005262:	8082                	ret

0000000080005264 <sys_read>:
{
    80005264:	7179                	addi	sp,sp,-48
    80005266:	f406                	sd	ra,40(sp)
    80005268:	f022                	sd	s0,32(sp)
    8000526a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000526c:	fd840593          	addi	a1,s0,-40
    80005270:	4505                	li	a0,1
    80005272:	ffffe097          	auipc	ra,0xffffe
    80005276:	8da080e7          	jalr	-1830(ra) # 80002b4c <argaddr>
  argint(2, &n);
    8000527a:	fe440593          	addi	a1,s0,-28
    8000527e:	4509                	li	a0,2
    80005280:	ffffe097          	auipc	ra,0xffffe
    80005284:	8ac080e7          	jalr	-1876(ra) # 80002b2c <argint>
  if(argfd(0, 0, &f) < 0)
    80005288:	fe840613          	addi	a2,s0,-24
    8000528c:	4581                	li	a1,0
    8000528e:	4501                	li	a0,0
    80005290:	00000097          	auipc	ra,0x0
    80005294:	d5e080e7          	jalr	-674(ra) # 80004fee <argfd>
    80005298:	87aa                	mv	a5,a0
    return -1;
    8000529a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000529c:	0007cc63          	bltz	a5,800052b4 <sys_read+0x50>
  return fileread(f, p, n);
    800052a0:	fe442603          	lw	a2,-28(s0)
    800052a4:	fd843583          	ld	a1,-40(s0)
    800052a8:	fe843503          	ld	a0,-24(s0)
    800052ac:	fffff097          	auipc	ra,0xfffff
    800052b0:	460080e7          	jalr	1120(ra) # 8000470c <fileread>
}
    800052b4:	70a2                	ld	ra,40(sp)
    800052b6:	7402                	ld	s0,32(sp)
    800052b8:	6145                	addi	sp,sp,48
    800052ba:	8082                	ret

00000000800052bc <sys_write>:
{
    800052bc:	7179                	addi	sp,sp,-48
    800052be:	f406                	sd	ra,40(sp)
    800052c0:	f022                	sd	s0,32(sp)
    800052c2:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052c4:	fd840593          	addi	a1,s0,-40
    800052c8:	4505                	li	a0,1
    800052ca:	ffffe097          	auipc	ra,0xffffe
    800052ce:	882080e7          	jalr	-1918(ra) # 80002b4c <argaddr>
  argint(2, &n);
    800052d2:	fe440593          	addi	a1,s0,-28
    800052d6:	4509                	li	a0,2
    800052d8:	ffffe097          	auipc	ra,0xffffe
    800052dc:	854080e7          	jalr	-1964(ra) # 80002b2c <argint>
  if(argfd(0, 0, &f) < 0)
    800052e0:	fe840613          	addi	a2,s0,-24
    800052e4:	4581                	li	a1,0
    800052e6:	4501                	li	a0,0
    800052e8:	00000097          	auipc	ra,0x0
    800052ec:	d06080e7          	jalr	-762(ra) # 80004fee <argfd>
    800052f0:	87aa                	mv	a5,a0
    return -1;
    800052f2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800052f4:	0007cc63          	bltz	a5,8000530c <sys_write+0x50>
  return filewrite(f, p, n);
    800052f8:	fe442603          	lw	a2,-28(s0)
    800052fc:	fd843583          	ld	a1,-40(s0)
    80005300:	fe843503          	ld	a0,-24(s0)
    80005304:	fffff097          	auipc	ra,0xfffff
    80005308:	4ca080e7          	jalr	1226(ra) # 800047ce <filewrite>
}
    8000530c:	70a2                	ld	ra,40(sp)
    8000530e:	7402                	ld	s0,32(sp)
    80005310:	6145                	addi	sp,sp,48
    80005312:	8082                	ret

0000000080005314 <sys_close>:
{
    80005314:	1101                	addi	sp,sp,-32
    80005316:	ec06                	sd	ra,24(sp)
    80005318:	e822                	sd	s0,16(sp)
    8000531a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000531c:	fe040613          	addi	a2,s0,-32
    80005320:	fec40593          	addi	a1,s0,-20
    80005324:	4501                	li	a0,0
    80005326:	00000097          	auipc	ra,0x0
    8000532a:	cc8080e7          	jalr	-824(ra) # 80004fee <argfd>
    return -1;
    8000532e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005330:	02054463          	bltz	a0,80005358 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005334:	ffffc097          	auipc	ra,0xffffc
    80005338:	672080e7          	jalr	1650(ra) # 800019a6 <myproc>
    8000533c:	fec42783          	lw	a5,-20(s0)
    80005340:	07e9                	addi	a5,a5,26
    80005342:	078e                	slli	a5,a5,0x3
    80005344:	953e                	add	a0,a0,a5
    80005346:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000534a:	fe043503          	ld	a0,-32(s0)
    8000534e:	fffff097          	auipc	ra,0xfffff
    80005352:	284080e7          	jalr	644(ra) # 800045d2 <fileclose>
  return 0;
    80005356:	4781                	li	a5,0
}
    80005358:	853e                	mv	a0,a5
    8000535a:	60e2                	ld	ra,24(sp)
    8000535c:	6442                	ld	s0,16(sp)
    8000535e:	6105                	addi	sp,sp,32
    80005360:	8082                	ret

0000000080005362 <sys_fstat>:
{
    80005362:	1101                	addi	sp,sp,-32
    80005364:	ec06                	sd	ra,24(sp)
    80005366:	e822                	sd	s0,16(sp)
    80005368:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000536a:	fe040593          	addi	a1,s0,-32
    8000536e:	4505                	li	a0,1
    80005370:	ffffd097          	auipc	ra,0xffffd
    80005374:	7dc080e7          	jalr	2012(ra) # 80002b4c <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005378:	fe840613          	addi	a2,s0,-24
    8000537c:	4581                	li	a1,0
    8000537e:	4501                	li	a0,0
    80005380:	00000097          	auipc	ra,0x0
    80005384:	c6e080e7          	jalr	-914(ra) # 80004fee <argfd>
    80005388:	87aa                	mv	a5,a0
    return -1;
    8000538a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000538c:	0007ca63          	bltz	a5,800053a0 <sys_fstat+0x3e>
  return filestat(f, st);
    80005390:	fe043583          	ld	a1,-32(s0)
    80005394:	fe843503          	ld	a0,-24(s0)
    80005398:	fffff097          	auipc	ra,0xfffff
    8000539c:	302080e7          	jalr	770(ra) # 8000469a <filestat>
}
    800053a0:	60e2                	ld	ra,24(sp)
    800053a2:	6442                	ld	s0,16(sp)
    800053a4:	6105                	addi	sp,sp,32
    800053a6:	8082                	ret

00000000800053a8 <sys_link>:
{
    800053a8:	7169                	addi	sp,sp,-304
    800053aa:	f606                	sd	ra,296(sp)
    800053ac:	f222                	sd	s0,288(sp)
    800053ae:	ee26                	sd	s1,280(sp)
    800053b0:	ea4a                	sd	s2,272(sp)
    800053b2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053b4:	08000613          	li	a2,128
    800053b8:	ed040593          	addi	a1,s0,-304
    800053bc:	4501                	li	a0,0
    800053be:	ffffd097          	auipc	ra,0xffffd
    800053c2:	7ae080e7          	jalr	1966(ra) # 80002b6c <argstr>
    return -1;
    800053c6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053c8:	10054e63          	bltz	a0,800054e4 <sys_link+0x13c>
    800053cc:	08000613          	li	a2,128
    800053d0:	f5040593          	addi	a1,s0,-176
    800053d4:	4505                	li	a0,1
    800053d6:	ffffd097          	auipc	ra,0xffffd
    800053da:	796080e7          	jalr	1942(ra) # 80002b6c <argstr>
    return -1;
    800053de:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053e0:	10054263          	bltz	a0,800054e4 <sys_link+0x13c>
  begin_op();
    800053e4:	fffff097          	auipc	ra,0xfffff
    800053e8:	d2a080e7          	jalr	-726(ra) # 8000410e <begin_op>
  if((ip = namei(old)) == 0){
    800053ec:	ed040513          	addi	a0,s0,-304
    800053f0:	fffff097          	auipc	ra,0xfffff
    800053f4:	b1e080e7          	jalr	-1250(ra) # 80003f0e <namei>
    800053f8:	84aa                	mv	s1,a0
    800053fa:	c551                	beqz	a0,80005486 <sys_link+0xde>
  ilock(ip);
    800053fc:	ffffe097          	auipc	ra,0xffffe
    80005400:	36c080e7          	jalr	876(ra) # 80003768 <ilock>
  if(ip->type == T_DIR){
    80005404:	04449703          	lh	a4,68(s1)
    80005408:	4785                	li	a5,1
    8000540a:	08f70463          	beq	a4,a5,80005492 <sys_link+0xea>
  ip->nlink++;
    8000540e:	04a4d783          	lhu	a5,74(s1)
    80005412:	2785                	addiw	a5,a5,1
    80005414:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005418:	8526                	mv	a0,s1
    8000541a:	ffffe097          	auipc	ra,0xffffe
    8000541e:	282080e7          	jalr	642(ra) # 8000369c <iupdate>
  iunlock(ip);
    80005422:	8526                	mv	a0,s1
    80005424:	ffffe097          	auipc	ra,0xffffe
    80005428:	406080e7          	jalr	1030(ra) # 8000382a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000542c:	fd040593          	addi	a1,s0,-48
    80005430:	f5040513          	addi	a0,s0,-176
    80005434:	fffff097          	auipc	ra,0xfffff
    80005438:	af8080e7          	jalr	-1288(ra) # 80003f2c <nameiparent>
    8000543c:	892a                	mv	s2,a0
    8000543e:	c935                	beqz	a0,800054b2 <sys_link+0x10a>
  ilock(dp);
    80005440:	ffffe097          	auipc	ra,0xffffe
    80005444:	328080e7          	jalr	808(ra) # 80003768 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005448:	00092703          	lw	a4,0(s2)
    8000544c:	409c                	lw	a5,0(s1)
    8000544e:	04f71d63          	bne	a4,a5,800054a8 <sys_link+0x100>
    80005452:	40d0                	lw	a2,4(s1)
    80005454:	fd040593          	addi	a1,s0,-48
    80005458:	854a                	mv	a0,s2
    8000545a:	fffff097          	auipc	ra,0xfffff
    8000545e:	a02080e7          	jalr	-1534(ra) # 80003e5c <dirlink>
    80005462:	04054363          	bltz	a0,800054a8 <sys_link+0x100>
  iunlockput(dp);
    80005466:	854a                	mv	a0,s2
    80005468:	ffffe097          	auipc	ra,0xffffe
    8000546c:	562080e7          	jalr	1378(ra) # 800039ca <iunlockput>
  iput(ip);
    80005470:	8526                	mv	a0,s1
    80005472:	ffffe097          	auipc	ra,0xffffe
    80005476:	4b0080e7          	jalr	1200(ra) # 80003922 <iput>
  end_op();
    8000547a:	fffff097          	auipc	ra,0xfffff
    8000547e:	d0e080e7          	jalr	-754(ra) # 80004188 <end_op>
  return 0;
    80005482:	4781                	li	a5,0
    80005484:	a085                	j	800054e4 <sys_link+0x13c>
    end_op();
    80005486:	fffff097          	auipc	ra,0xfffff
    8000548a:	d02080e7          	jalr	-766(ra) # 80004188 <end_op>
    return -1;
    8000548e:	57fd                	li	a5,-1
    80005490:	a891                	j	800054e4 <sys_link+0x13c>
    iunlockput(ip);
    80005492:	8526                	mv	a0,s1
    80005494:	ffffe097          	auipc	ra,0xffffe
    80005498:	536080e7          	jalr	1334(ra) # 800039ca <iunlockput>
    end_op();
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	cec080e7          	jalr	-788(ra) # 80004188 <end_op>
    return -1;
    800054a4:	57fd                	li	a5,-1
    800054a6:	a83d                	j	800054e4 <sys_link+0x13c>
    iunlockput(dp);
    800054a8:	854a                	mv	a0,s2
    800054aa:	ffffe097          	auipc	ra,0xffffe
    800054ae:	520080e7          	jalr	1312(ra) # 800039ca <iunlockput>
  ilock(ip);
    800054b2:	8526                	mv	a0,s1
    800054b4:	ffffe097          	auipc	ra,0xffffe
    800054b8:	2b4080e7          	jalr	692(ra) # 80003768 <ilock>
  ip->nlink--;
    800054bc:	04a4d783          	lhu	a5,74(s1)
    800054c0:	37fd                	addiw	a5,a5,-1
    800054c2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054c6:	8526                	mv	a0,s1
    800054c8:	ffffe097          	auipc	ra,0xffffe
    800054cc:	1d4080e7          	jalr	468(ra) # 8000369c <iupdate>
  iunlockput(ip);
    800054d0:	8526                	mv	a0,s1
    800054d2:	ffffe097          	auipc	ra,0xffffe
    800054d6:	4f8080e7          	jalr	1272(ra) # 800039ca <iunlockput>
  end_op();
    800054da:	fffff097          	auipc	ra,0xfffff
    800054de:	cae080e7          	jalr	-850(ra) # 80004188 <end_op>
  return -1;
    800054e2:	57fd                	li	a5,-1
}
    800054e4:	853e                	mv	a0,a5
    800054e6:	70b2                	ld	ra,296(sp)
    800054e8:	7412                	ld	s0,288(sp)
    800054ea:	64f2                	ld	s1,280(sp)
    800054ec:	6952                	ld	s2,272(sp)
    800054ee:	6155                	addi	sp,sp,304
    800054f0:	8082                	ret

00000000800054f2 <sys_unlink>:
{
    800054f2:	7151                	addi	sp,sp,-240
    800054f4:	f586                	sd	ra,232(sp)
    800054f6:	f1a2                	sd	s0,224(sp)
    800054f8:	eda6                	sd	s1,216(sp)
    800054fa:	e9ca                	sd	s2,208(sp)
    800054fc:	e5ce                	sd	s3,200(sp)
    800054fe:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005500:	08000613          	li	a2,128
    80005504:	f3040593          	addi	a1,s0,-208
    80005508:	4501                	li	a0,0
    8000550a:	ffffd097          	auipc	ra,0xffffd
    8000550e:	662080e7          	jalr	1634(ra) # 80002b6c <argstr>
    80005512:	18054163          	bltz	a0,80005694 <sys_unlink+0x1a2>
  begin_op();
    80005516:	fffff097          	auipc	ra,0xfffff
    8000551a:	bf8080e7          	jalr	-1032(ra) # 8000410e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000551e:	fb040593          	addi	a1,s0,-80
    80005522:	f3040513          	addi	a0,s0,-208
    80005526:	fffff097          	auipc	ra,0xfffff
    8000552a:	a06080e7          	jalr	-1530(ra) # 80003f2c <nameiparent>
    8000552e:	84aa                	mv	s1,a0
    80005530:	c979                	beqz	a0,80005606 <sys_unlink+0x114>
  ilock(dp);
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	236080e7          	jalr	566(ra) # 80003768 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000553a:	00003597          	auipc	a1,0x3
    8000553e:	28658593          	addi	a1,a1,646 # 800087c0 <stateString.0+0x220>
    80005542:	fb040513          	addi	a0,s0,-80
    80005546:	ffffe097          	auipc	ra,0xffffe
    8000554a:	6ec080e7          	jalr	1772(ra) # 80003c32 <namecmp>
    8000554e:	14050a63          	beqz	a0,800056a2 <sys_unlink+0x1b0>
    80005552:	00003597          	auipc	a1,0x3
    80005556:	27658593          	addi	a1,a1,630 # 800087c8 <stateString.0+0x228>
    8000555a:	fb040513          	addi	a0,s0,-80
    8000555e:	ffffe097          	auipc	ra,0xffffe
    80005562:	6d4080e7          	jalr	1748(ra) # 80003c32 <namecmp>
    80005566:	12050e63          	beqz	a0,800056a2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000556a:	f2c40613          	addi	a2,s0,-212
    8000556e:	fb040593          	addi	a1,s0,-80
    80005572:	8526                	mv	a0,s1
    80005574:	ffffe097          	auipc	ra,0xffffe
    80005578:	6d8080e7          	jalr	1752(ra) # 80003c4c <dirlookup>
    8000557c:	892a                	mv	s2,a0
    8000557e:	12050263          	beqz	a0,800056a2 <sys_unlink+0x1b0>
  ilock(ip);
    80005582:	ffffe097          	auipc	ra,0xffffe
    80005586:	1e6080e7          	jalr	486(ra) # 80003768 <ilock>
  if(ip->nlink < 1)
    8000558a:	04a91783          	lh	a5,74(s2)
    8000558e:	08f05263          	blez	a5,80005612 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005592:	04491703          	lh	a4,68(s2)
    80005596:	4785                	li	a5,1
    80005598:	08f70563          	beq	a4,a5,80005622 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000559c:	4641                	li	a2,16
    8000559e:	4581                	li	a1,0
    800055a0:	fc040513          	addi	a0,s0,-64
    800055a4:	ffffb097          	auipc	ra,0xffffb
    800055a8:	72a080e7          	jalr	1834(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055ac:	4741                	li	a4,16
    800055ae:	f2c42683          	lw	a3,-212(s0)
    800055b2:	fc040613          	addi	a2,s0,-64
    800055b6:	4581                	li	a1,0
    800055b8:	8526                	mv	a0,s1
    800055ba:	ffffe097          	auipc	ra,0xffffe
    800055be:	55a080e7          	jalr	1370(ra) # 80003b14 <writei>
    800055c2:	47c1                	li	a5,16
    800055c4:	0af51563          	bne	a0,a5,8000566e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055c8:	04491703          	lh	a4,68(s2)
    800055cc:	4785                	li	a5,1
    800055ce:	0af70863          	beq	a4,a5,8000567e <sys_unlink+0x18c>
  iunlockput(dp);
    800055d2:	8526                	mv	a0,s1
    800055d4:	ffffe097          	auipc	ra,0xffffe
    800055d8:	3f6080e7          	jalr	1014(ra) # 800039ca <iunlockput>
  ip->nlink--;
    800055dc:	04a95783          	lhu	a5,74(s2)
    800055e0:	37fd                	addiw	a5,a5,-1
    800055e2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055e6:	854a                	mv	a0,s2
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	0b4080e7          	jalr	180(ra) # 8000369c <iupdate>
  iunlockput(ip);
    800055f0:	854a                	mv	a0,s2
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	3d8080e7          	jalr	984(ra) # 800039ca <iunlockput>
  end_op();
    800055fa:	fffff097          	auipc	ra,0xfffff
    800055fe:	b8e080e7          	jalr	-1138(ra) # 80004188 <end_op>
  return 0;
    80005602:	4501                	li	a0,0
    80005604:	a84d                	j	800056b6 <sys_unlink+0x1c4>
    end_op();
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	b82080e7          	jalr	-1150(ra) # 80004188 <end_op>
    return -1;
    8000560e:	557d                	li	a0,-1
    80005610:	a05d                	j	800056b6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005612:	00003517          	auipc	a0,0x3
    80005616:	1be50513          	addi	a0,a0,446 # 800087d0 <stateString.0+0x230>
    8000561a:	ffffb097          	auipc	ra,0xffffb
    8000561e:	f22080e7          	jalr	-222(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005622:	04c92703          	lw	a4,76(s2)
    80005626:	02000793          	li	a5,32
    8000562a:	f6e7f9e3          	bgeu	a5,a4,8000559c <sys_unlink+0xaa>
    8000562e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005632:	4741                	li	a4,16
    80005634:	86ce                	mv	a3,s3
    80005636:	f1840613          	addi	a2,s0,-232
    8000563a:	4581                	li	a1,0
    8000563c:	854a                	mv	a0,s2
    8000563e:	ffffe097          	auipc	ra,0xffffe
    80005642:	3de080e7          	jalr	990(ra) # 80003a1c <readi>
    80005646:	47c1                	li	a5,16
    80005648:	00f51b63          	bne	a0,a5,8000565e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000564c:	f1845783          	lhu	a5,-232(s0)
    80005650:	e7a1                	bnez	a5,80005698 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005652:	29c1                	addiw	s3,s3,16
    80005654:	04c92783          	lw	a5,76(s2)
    80005658:	fcf9ede3          	bltu	s3,a5,80005632 <sys_unlink+0x140>
    8000565c:	b781                	j	8000559c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000565e:	00003517          	auipc	a0,0x3
    80005662:	18a50513          	addi	a0,a0,394 # 800087e8 <stateString.0+0x248>
    80005666:	ffffb097          	auipc	ra,0xffffb
    8000566a:	ed6080e7          	jalr	-298(ra) # 8000053c <panic>
    panic("unlink: writei");
    8000566e:	00003517          	auipc	a0,0x3
    80005672:	19250513          	addi	a0,a0,402 # 80008800 <stateString.0+0x260>
    80005676:	ffffb097          	auipc	ra,0xffffb
    8000567a:	ec6080e7          	jalr	-314(ra) # 8000053c <panic>
    dp->nlink--;
    8000567e:	04a4d783          	lhu	a5,74(s1)
    80005682:	37fd                	addiw	a5,a5,-1
    80005684:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005688:	8526                	mv	a0,s1
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	012080e7          	jalr	18(ra) # 8000369c <iupdate>
    80005692:	b781                	j	800055d2 <sys_unlink+0xe0>
    return -1;
    80005694:	557d                	li	a0,-1
    80005696:	a005                	j	800056b6 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005698:	854a                	mv	a0,s2
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	330080e7          	jalr	816(ra) # 800039ca <iunlockput>
  iunlockput(dp);
    800056a2:	8526                	mv	a0,s1
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	326080e7          	jalr	806(ra) # 800039ca <iunlockput>
  end_op();
    800056ac:	fffff097          	auipc	ra,0xfffff
    800056b0:	adc080e7          	jalr	-1316(ra) # 80004188 <end_op>
  return -1;
    800056b4:	557d                	li	a0,-1
}
    800056b6:	70ae                	ld	ra,232(sp)
    800056b8:	740e                	ld	s0,224(sp)
    800056ba:	64ee                	ld	s1,216(sp)
    800056bc:	694e                	ld	s2,208(sp)
    800056be:	69ae                	ld	s3,200(sp)
    800056c0:	616d                	addi	sp,sp,240
    800056c2:	8082                	ret

00000000800056c4 <sys_open>:

uint64
sys_open(void)
{
    800056c4:	7131                	addi	sp,sp,-192
    800056c6:	fd06                	sd	ra,184(sp)
    800056c8:	f922                	sd	s0,176(sp)
    800056ca:	f526                	sd	s1,168(sp)
    800056cc:	f14a                	sd	s2,160(sp)
    800056ce:	ed4e                	sd	s3,152(sp)
    800056d0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800056d2:	f4c40593          	addi	a1,s0,-180
    800056d6:	4505                	li	a0,1
    800056d8:	ffffd097          	auipc	ra,0xffffd
    800056dc:	454080e7          	jalr	1108(ra) # 80002b2c <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800056e0:	08000613          	li	a2,128
    800056e4:	f5040593          	addi	a1,s0,-176
    800056e8:	4501                	li	a0,0
    800056ea:	ffffd097          	auipc	ra,0xffffd
    800056ee:	482080e7          	jalr	1154(ra) # 80002b6c <argstr>
    800056f2:	87aa                	mv	a5,a0
    return -1;
    800056f4:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800056f6:	0a07c863          	bltz	a5,800057a6 <sys_open+0xe2>

  begin_op();
    800056fa:	fffff097          	auipc	ra,0xfffff
    800056fe:	a14080e7          	jalr	-1516(ra) # 8000410e <begin_op>

  if(omode & O_CREATE){
    80005702:	f4c42783          	lw	a5,-180(s0)
    80005706:	2007f793          	andi	a5,a5,512
    8000570a:	cbdd                	beqz	a5,800057c0 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    8000570c:	4681                	li	a3,0
    8000570e:	4601                	li	a2,0
    80005710:	4589                	li	a1,2
    80005712:	f5040513          	addi	a0,s0,-176
    80005716:	00000097          	auipc	ra,0x0
    8000571a:	97a080e7          	jalr	-1670(ra) # 80005090 <create>
    8000571e:	84aa                	mv	s1,a0
    if(ip == 0){
    80005720:	c951                	beqz	a0,800057b4 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005722:	04449703          	lh	a4,68(s1)
    80005726:	478d                	li	a5,3
    80005728:	00f71763          	bne	a4,a5,80005736 <sys_open+0x72>
    8000572c:	0464d703          	lhu	a4,70(s1)
    80005730:	47a5                	li	a5,9
    80005732:	0ce7ec63          	bltu	a5,a4,8000580a <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	de0080e7          	jalr	-544(ra) # 80004516 <filealloc>
    8000573e:	892a                	mv	s2,a0
    80005740:	c56d                	beqz	a0,8000582a <sys_open+0x166>
    80005742:	00000097          	auipc	ra,0x0
    80005746:	90c080e7          	jalr	-1780(ra) # 8000504e <fdalloc>
    8000574a:	89aa                	mv	s3,a0
    8000574c:	0c054a63          	bltz	a0,80005820 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005750:	04449703          	lh	a4,68(s1)
    80005754:	478d                	li	a5,3
    80005756:	0ef70563          	beq	a4,a5,80005840 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000575a:	4789                	li	a5,2
    8000575c:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005760:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005764:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005768:	f4c42783          	lw	a5,-180(s0)
    8000576c:	0017c713          	xori	a4,a5,1
    80005770:	8b05                	andi	a4,a4,1
    80005772:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005776:	0037f713          	andi	a4,a5,3
    8000577a:	00e03733          	snez	a4,a4
    8000577e:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005782:	4007f793          	andi	a5,a5,1024
    80005786:	c791                	beqz	a5,80005792 <sys_open+0xce>
    80005788:	04449703          	lh	a4,68(s1)
    8000578c:	4789                	li	a5,2
    8000578e:	0cf70063          	beq	a4,a5,8000584e <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005792:	8526                	mv	a0,s1
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	096080e7          	jalr	150(ra) # 8000382a <iunlock>
  end_op();
    8000579c:	fffff097          	auipc	ra,0xfffff
    800057a0:	9ec080e7          	jalr	-1556(ra) # 80004188 <end_op>

  return fd;
    800057a4:	854e                	mv	a0,s3
}
    800057a6:	70ea                	ld	ra,184(sp)
    800057a8:	744a                	ld	s0,176(sp)
    800057aa:	74aa                	ld	s1,168(sp)
    800057ac:	790a                	ld	s2,160(sp)
    800057ae:	69ea                	ld	s3,152(sp)
    800057b0:	6129                	addi	sp,sp,192
    800057b2:	8082                	ret
      end_op();
    800057b4:	fffff097          	auipc	ra,0xfffff
    800057b8:	9d4080e7          	jalr	-1580(ra) # 80004188 <end_op>
      return -1;
    800057bc:	557d                	li	a0,-1
    800057be:	b7e5                	j	800057a6 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    800057c0:	f5040513          	addi	a0,s0,-176
    800057c4:	ffffe097          	auipc	ra,0xffffe
    800057c8:	74a080e7          	jalr	1866(ra) # 80003f0e <namei>
    800057cc:	84aa                	mv	s1,a0
    800057ce:	c905                	beqz	a0,800057fe <sys_open+0x13a>
    ilock(ip);
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	f98080e7          	jalr	-104(ra) # 80003768 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057d8:	04449703          	lh	a4,68(s1)
    800057dc:	4785                	li	a5,1
    800057de:	f4f712e3          	bne	a4,a5,80005722 <sys_open+0x5e>
    800057e2:	f4c42783          	lw	a5,-180(s0)
    800057e6:	dba1                	beqz	a5,80005736 <sys_open+0x72>
      iunlockput(ip);
    800057e8:	8526                	mv	a0,s1
    800057ea:	ffffe097          	auipc	ra,0xffffe
    800057ee:	1e0080e7          	jalr	480(ra) # 800039ca <iunlockput>
      end_op();
    800057f2:	fffff097          	auipc	ra,0xfffff
    800057f6:	996080e7          	jalr	-1642(ra) # 80004188 <end_op>
      return -1;
    800057fa:	557d                	li	a0,-1
    800057fc:	b76d                	j	800057a6 <sys_open+0xe2>
      end_op();
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	98a080e7          	jalr	-1654(ra) # 80004188 <end_op>
      return -1;
    80005806:	557d                	li	a0,-1
    80005808:	bf79                	j	800057a6 <sys_open+0xe2>
    iunlockput(ip);
    8000580a:	8526                	mv	a0,s1
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	1be080e7          	jalr	446(ra) # 800039ca <iunlockput>
    end_op();
    80005814:	fffff097          	auipc	ra,0xfffff
    80005818:	974080e7          	jalr	-1676(ra) # 80004188 <end_op>
    return -1;
    8000581c:	557d                	li	a0,-1
    8000581e:	b761                	j	800057a6 <sys_open+0xe2>
      fileclose(f);
    80005820:	854a                	mv	a0,s2
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	db0080e7          	jalr	-592(ra) # 800045d2 <fileclose>
    iunlockput(ip);
    8000582a:	8526                	mv	a0,s1
    8000582c:	ffffe097          	auipc	ra,0xffffe
    80005830:	19e080e7          	jalr	414(ra) # 800039ca <iunlockput>
    end_op();
    80005834:	fffff097          	auipc	ra,0xfffff
    80005838:	954080e7          	jalr	-1708(ra) # 80004188 <end_op>
    return -1;
    8000583c:	557d                	li	a0,-1
    8000583e:	b7a5                	j	800057a6 <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005840:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005844:	04649783          	lh	a5,70(s1)
    80005848:	02f91223          	sh	a5,36(s2)
    8000584c:	bf21                	j	80005764 <sys_open+0xa0>
    itrunc(ip);
    8000584e:	8526                	mv	a0,s1
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	026080e7          	jalr	38(ra) # 80003876 <itrunc>
    80005858:	bf2d                	j	80005792 <sys_open+0xce>

000000008000585a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000585a:	7175                	addi	sp,sp,-144
    8000585c:	e506                	sd	ra,136(sp)
    8000585e:	e122                	sd	s0,128(sp)
    80005860:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	8ac080e7          	jalr	-1876(ra) # 8000410e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000586a:	08000613          	li	a2,128
    8000586e:	f7040593          	addi	a1,s0,-144
    80005872:	4501                	li	a0,0
    80005874:	ffffd097          	auipc	ra,0xffffd
    80005878:	2f8080e7          	jalr	760(ra) # 80002b6c <argstr>
    8000587c:	02054963          	bltz	a0,800058ae <sys_mkdir+0x54>
    80005880:	4681                	li	a3,0
    80005882:	4601                	li	a2,0
    80005884:	4585                	li	a1,1
    80005886:	f7040513          	addi	a0,s0,-144
    8000588a:	00000097          	auipc	ra,0x0
    8000588e:	806080e7          	jalr	-2042(ra) # 80005090 <create>
    80005892:	cd11                	beqz	a0,800058ae <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	136080e7          	jalr	310(ra) # 800039ca <iunlockput>
  end_op();
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	8ec080e7          	jalr	-1812(ra) # 80004188 <end_op>
  return 0;
    800058a4:	4501                	li	a0,0
}
    800058a6:	60aa                	ld	ra,136(sp)
    800058a8:	640a                	ld	s0,128(sp)
    800058aa:	6149                	addi	sp,sp,144
    800058ac:	8082                	ret
    end_op();
    800058ae:	fffff097          	auipc	ra,0xfffff
    800058b2:	8da080e7          	jalr	-1830(ra) # 80004188 <end_op>
    return -1;
    800058b6:	557d                	li	a0,-1
    800058b8:	b7fd                	j	800058a6 <sys_mkdir+0x4c>

00000000800058ba <sys_mknod>:

uint64
sys_mknod(void)
{
    800058ba:	7135                	addi	sp,sp,-160
    800058bc:	ed06                	sd	ra,152(sp)
    800058be:	e922                	sd	s0,144(sp)
    800058c0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	84c080e7          	jalr	-1972(ra) # 8000410e <begin_op>
  argint(1, &major);
    800058ca:	f6c40593          	addi	a1,s0,-148
    800058ce:	4505                	li	a0,1
    800058d0:	ffffd097          	auipc	ra,0xffffd
    800058d4:	25c080e7          	jalr	604(ra) # 80002b2c <argint>
  argint(2, &minor);
    800058d8:	f6840593          	addi	a1,s0,-152
    800058dc:	4509                	li	a0,2
    800058de:	ffffd097          	auipc	ra,0xffffd
    800058e2:	24e080e7          	jalr	590(ra) # 80002b2c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058e6:	08000613          	li	a2,128
    800058ea:	f7040593          	addi	a1,s0,-144
    800058ee:	4501                	li	a0,0
    800058f0:	ffffd097          	auipc	ra,0xffffd
    800058f4:	27c080e7          	jalr	636(ra) # 80002b6c <argstr>
    800058f8:	02054b63          	bltz	a0,8000592e <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058fc:	f6841683          	lh	a3,-152(s0)
    80005900:	f6c41603          	lh	a2,-148(s0)
    80005904:	458d                	li	a1,3
    80005906:	f7040513          	addi	a0,s0,-144
    8000590a:	fffff097          	auipc	ra,0xfffff
    8000590e:	786080e7          	jalr	1926(ra) # 80005090 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005912:	cd11                	beqz	a0,8000592e <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005914:	ffffe097          	auipc	ra,0xffffe
    80005918:	0b6080e7          	jalr	182(ra) # 800039ca <iunlockput>
  end_op();
    8000591c:	fffff097          	auipc	ra,0xfffff
    80005920:	86c080e7          	jalr	-1940(ra) # 80004188 <end_op>
  return 0;
    80005924:	4501                	li	a0,0
}
    80005926:	60ea                	ld	ra,152(sp)
    80005928:	644a                	ld	s0,144(sp)
    8000592a:	610d                	addi	sp,sp,160
    8000592c:	8082                	ret
    end_op();
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	85a080e7          	jalr	-1958(ra) # 80004188 <end_op>
    return -1;
    80005936:	557d                	li	a0,-1
    80005938:	b7fd                	j	80005926 <sys_mknod+0x6c>

000000008000593a <sys_chdir>:

uint64
sys_chdir(void)
{
    8000593a:	7135                	addi	sp,sp,-160
    8000593c:	ed06                	sd	ra,152(sp)
    8000593e:	e922                	sd	s0,144(sp)
    80005940:	e526                	sd	s1,136(sp)
    80005942:	e14a                	sd	s2,128(sp)
    80005944:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005946:	ffffc097          	auipc	ra,0xffffc
    8000594a:	060080e7          	jalr	96(ra) # 800019a6 <myproc>
    8000594e:	892a                	mv	s2,a0
  
  begin_op();
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	7be080e7          	jalr	1982(ra) # 8000410e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005958:	08000613          	li	a2,128
    8000595c:	f6040593          	addi	a1,s0,-160
    80005960:	4501                	li	a0,0
    80005962:	ffffd097          	auipc	ra,0xffffd
    80005966:	20a080e7          	jalr	522(ra) # 80002b6c <argstr>
    8000596a:	04054b63          	bltz	a0,800059c0 <sys_chdir+0x86>
    8000596e:	f6040513          	addi	a0,s0,-160
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	59c080e7          	jalr	1436(ra) # 80003f0e <namei>
    8000597a:	84aa                	mv	s1,a0
    8000597c:	c131                	beqz	a0,800059c0 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	dea080e7          	jalr	-534(ra) # 80003768 <ilock>
  if(ip->type != T_DIR){
    80005986:	04449703          	lh	a4,68(s1)
    8000598a:	4785                	li	a5,1
    8000598c:	04f71063          	bne	a4,a5,800059cc <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005990:	8526                	mv	a0,s1
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	e98080e7          	jalr	-360(ra) # 8000382a <iunlock>
  iput(p->cwd);
    8000599a:	15093503          	ld	a0,336(s2)
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	f84080e7          	jalr	-124(ra) # 80003922 <iput>
  end_op();
    800059a6:	ffffe097          	auipc	ra,0xffffe
    800059aa:	7e2080e7          	jalr	2018(ra) # 80004188 <end_op>
  p->cwd = ip;
    800059ae:	14993823          	sd	s1,336(s2)
  return 0;
    800059b2:	4501                	li	a0,0
}
    800059b4:	60ea                	ld	ra,152(sp)
    800059b6:	644a                	ld	s0,144(sp)
    800059b8:	64aa                	ld	s1,136(sp)
    800059ba:	690a                	ld	s2,128(sp)
    800059bc:	610d                	addi	sp,sp,160
    800059be:	8082                	ret
    end_op();
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	7c8080e7          	jalr	1992(ra) # 80004188 <end_op>
    return -1;
    800059c8:	557d                	li	a0,-1
    800059ca:	b7ed                	j	800059b4 <sys_chdir+0x7a>
    iunlockput(ip);
    800059cc:	8526                	mv	a0,s1
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	ffc080e7          	jalr	-4(ra) # 800039ca <iunlockput>
    end_op();
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	7b2080e7          	jalr	1970(ra) # 80004188 <end_op>
    return -1;
    800059de:	557d                	li	a0,-1
    800059e0:	bfd1                	j	800059b4 <sys_chdir+0x7a>

00000000800059e2 <sys_exec>:

uint64
sys_exec(void)
{
    800059e2:	7121                	addi	sp,sp,-448
    800059e4:	ff06                	sd	ra,440(sp)
    800059e6:	fb22                	sd	s0,432(sp)
    800059e8:	f726                	sd	s1,424(sp)
    800059ea:	f34a                	sd	s2,416(sp)
    800059ec:	ef4e                	sd	s3,408(sp)
    800059ee:	eb52                	sd	s4,400(sp)
    800059f0:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800059f2:	e4840593          	addi	a1,s0,-440
    800059f6:	4505                	li	a0,1
    800059f8:	ffffd097          	auipc	ra,0xffffd
    800059fc:	154080e7          	jalr	340(ra) # 80002b4c <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a00:	08000613          	li	a2,128
    80005a04:	f5040593          	addi	a1,s0,-176
    80005a08:	4501                	li	a0,0
    80005a0a:	ffffd097          	auipc	ra,0xffffd
    80005a0e:	162080e7          	jalr	354(ra) # 80002b6c <argstr>
    80005a12:	87aa                	mv	a5,a0
    return -1;
    80005a14:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a16:	0c07c263          	bltz	a5,80005ada <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005a1a:	10000613          	li	a2,256
    80005a1e:	4581                	li	a1,0
    80005a20:	e5040513          	addi	a0,s0,-432
    80005a24:	ffffb097          	auipc	ra,0xffffb
    80005a28:	2aa080e7          	jalr	682(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a2c:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005a30:	89a6                	mv	s3,s1
    80005a32:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a34:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a38:	00391513          	slli	a0,s2,0x3
    80005a3c:	e4040593          	addi	a1,s0,-448
    80005a40:	e4843783          	ld	a5,-440(s0)
    80005a44:	953e                	add	a0,a0,a5
    80005a46:	ffffd097          	auipc	ra,0xffffd
    80005a4a:	048080e7          	jalr	72(ra) # 80002a8e <fetchaddr>
    80005a4e:	02054a63          	bltz	a0,80005a82 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005a52:	e4043783          	ld	a5,-448(s0)
    80005a56:	c3b9                	beqz	a5,80005a9c <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a58:	ffffb097          	auipc	ra,0xffffb
    80005a5c:	08a080e7          	jalr	138(ra) # 80000ae2 <kalloc>
    80005a60:	85aa                	mv	a1,a0
    80005a62:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a66:	cd11                	beqz	a0,80005a82 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a68:	6605                	lui	a2,0x1
    80005a6a:	e4043503          	ld	a0,-448(s0)
    80005a6e:	ffffd097          	auipc	ra,0xffffd
    80005a72:	072080e7          	jalr	114(ra) # 80002ae0 <fetchstr>
    80005a76:	00054663          	bltz	a0,80005a82 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005a7a:	0905                	addi	s2,s2,1
    80005a7c:	09a1                	addi	s3,s3,8
    80005a7e:	fb491de3          	bne	s2,s4,80005a38 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a82:	f5040913          	addi	s2,s0,-176
    80005a86:	6088                	ld	a0,0(s1)
    80005a88:	c921                	beqz	a0,80005ad8 <sys_exec+0xf6>
    kfree(argv[i]);
    80005a8a:	ffffb097          	auipc	ra,0xffffb
    80005a8e:	f5a080e7          	jalr	-166(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a92:	04a1                	addi	s1,s1,8
    80005a94:	ff2499e3          	bne	s1,s2,80005a86 <sys_exec+0xa4>
  return -1;
    80005a98:	557d                	li	a0,-1
    80005a9a:	a081                	j	80005ada <sys_exec+0xf8>
      argv[i] = 0;
    80005a9c:	0009079b          	sext.w	a5,s2
    80005aa0:	078e                	slli	a5,a5,0x3
    80005aa2:	fd078793          	addi	a5,a5,-48
    80005aa6:	97a2                	add	a5,a5,s0
    80005aa8:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005aac:	e5040593          	addi	a1,s0,-432
    80005ab0:	f5040513          	addi	a0,s0,-176
    80005ab4:	fffff097          	auipc	ra,0xfffff
    80005ab8:	194080e7          	jalr	404(ra) # 80004c48 <exec>
    80005abc:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005abe:	f5040993          	addi	s3,s0,-176
    80005ac2:	6088                	ld	a0,0(s1)
    80005ac4:	c901                	beqz	a0,80005ad4 <sys_exec+0xf2>
    kfree(argv[i]);
    80005ac6:	ffffb097          	auipc	ra,0xffffb
    80005aca:	f1e080e7          	jalr	-226(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ace:	04a1                	addi	s1,s1,8
    80005ad0:	ff3499e3          	bne	s1,s3,80005ac2 <sys_exec+0xe0>
  return ret;
    80005ad4:	854a                	mv	a0,s2
    80005ad6:	a011                	j	80005ada <sys_exec+0xf8>
  return -1;
    80005ad8:	557d                	li	a0,-1
}
    80005ada:	70fa                	ld	ra,440(sp)
    80005adc:	745a                	ld	s0,432(sp)
    80005ade:	74ba                	ld	s1,424(sp)
    80005ae0:	791a                	ld	s2,416(sp)
    80005ae2:	69fa                	ld	s3,408(sp)
    80005ae4:	6a5a                	ld	s4,400(sp)
    80005ae6:	6139                	addi	sp,sp,448
    80005ae8:	8082                	ret

0000000080005aea <sys_pipe>:

uint64
sys_pipe(void)
{
    80005aea:	7139                	addi	sp,sp,-64
    80005aec:	fc06                	sd	ra,56(sp)
    80005aee:	f822                	sd	s0,48(sp)
    80005af0:	f426                	sd	s1,40(sp)
    80005af2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005af4:	ffffc097          	auipc	ra,0xffffc
    80005af8:	eb2080e7          	jalr	-334(ra) # 800019a6 <myproc>
    80005afc:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005afe:	fd840593          	addi	a1,s0,-40
    80005b02:	4501                	li	a0,0
    80005b04:	ffffd097          	auipc	ra,0xffffd
    80005b08:	048080e7          	jalr	72(ra) # 80002b4c <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b0c:	fc840593          	addi	a1,s0,-56
    80005b10:	fd040513          	addi	a0,s0,-48
    80005b14:	fffff097          	auipc	ra,0xfffff
    80005b18:	dea080e7          	jalr	-534(ra) # 800048fe <pipealloc>
    return -1;
    80005b1c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b1e:	0c054463          	bltz	a0,80005be6 <sys_pipe+0xfc>
  fd0 = -1;
    80005b22:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b26:	fd043503          	ld	a0,-48(s0)
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	524080e7          	jalr	1316(ra) # 8000504e <fdalloc>
    80005b32:	fca42223          	sw	a0,-60(s0)
    80005b36:	08054b63          	bltz	a0,80005bcc <sys_pipe+0xe2>
    80005b3a:	fc843503          	ld	a0,-56(s0)
    80005b3e:	fffff097          	auipc	ra,0xfffff
    80005b42:	510080e7          	jalr	1296(ra) # 8000504e <fdalloc>
    80005b46:	fca42023          	sw	a0,-64(s0)
    80005b4a:	06054863          	bltz	a0,80005bba <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b4e:	4691                	li	a3,4
    80005b50:	fc440613          	addi	a2,s0,-60
    80005b54:	fd843583          	ld	a1,-40(s0)
    80005b58:	68a8                	ld	a0,80(s1)
    80005b5a:	ffffc097          	auipc	ra,0xffffc
    80005b5e:	b0c080e7          	jalr	-1268(ra) # 80001666 <copyout>
    80005b62:	02054063          	bltz	a0,80005b82 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b66:	4691                	li	a3,4
    80005b68:	fc040613          	addi	a2,s0,-64
    80005b6c:	fd843583          	ld	a1,-40(s0)
    80005b70:	0591                	addi	a1,a1,4
    80005b72:	68a8                	ld	a0,80(s1)
    80005b74:	ffffc097          	auipc	ra,0xffffc
    80005b78:	af2080e7          	jalr	-1294(ra) # 80001666 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b7c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b7e:	06055463          	bgez	a0,80005be6 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005b82:	fc442783          	lw	a5,-60(s0)
    80005b86:	07e9                	addi	a5,a5,26
    80005b88:	078e                	slli	a5,a5,0x3
    80005b8a:	97a6                	add	a5,a5,s1
    80005b8c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b90:	fc042783          	lw	a5,-64(s0)
    80005b94:	07e9                	addi	a5,a5,26
    80005b96:	078e                	slli	a5,a5,0x3
    80005b98:	94be                	add	s1,s1,a5
    80005b9a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005b9e:	fd043503          	ld	a0,-48(s0)
    80005ba2:	fffff097          	auipc	ra,0xfffff
    80005ba6:	a30080e7          	jalr	-1488(ra) # 800045d2 <fileclose>
    fileclose(wf);
    80005baa:	fc843503          	ld	a0,-56(s0)
    80005bae:	fffff097          	auipc	ra,0xfffff
    80005bb2:	a24080e7          	jalr	-1500(ra) # 800045d2 <fileclose>
    return -1;
    80005bb6:	57fd                	li	a5,-1
    80005bb8:	a03d                	j	80005be6 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005bba:	fc442783          	lw	a5,-60(s0)
    80005bbe:	0007c763          	bltz	a5,80005bcc <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005bc2:	07e9                	addi	a5,a5,26
    80005bc4:	078e                	slli	a5,a5,0x3
    80005bc6:	97a6                	add	a5,a5,s1
    80005bc8:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005bcc:	fd043503          	ld	a0,-48(s0)
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	a02080e7          	jalr	-1534(ra) # 800045d2 <fileclose>
    fileclose(wf);
    80005bd8:	fc843503          	ld	a0,-56(s0)
    80005bdc:	fffff097          	auipc	ra,0xfffff
    80005be0:	9f6080e7          	jalr	-1546(ra) # 800045d2 <fileclose>
    return -1;
    80005be4:	57fd                	li	a5,-1
}
    80005be6:	853e                	mv	a0,a5
    80005be8:	70e2                	ld	ra,56(sp)
    80005bea:	7442                	ld	s0,48(sp)
    80005bec:	74a2                	ld	s1,40(sp)
    80005bee:	6121                	addi	sp,sp,64
    80005bf0:	8082                	ret
	...

0000000080005c00 <kernelvec>:
    80005c00:	7111                	addi	sp,sp,-256
    80005c02:	e006                	sd	ra,0(sp)
    80005c04:	e40a                	sd	sp,8(sp)
    80005c06:	e80e                	sd	gp,16(sp)
    80005c08:	ec12                	sd	tp,24(sp)
    80005c0a:	f016                	sd	t0,32(sp)
    80005c0c:	f41a                	sd	t1,40(sp)
    80005c0e:	f81e                	sd	t2,48(sp)
    80005c10:	fc22                	sd	s0,56(sp)
    80005c12:	e0a6                	sd	s1,64(sp)
    80005c14:	e4aa                	sd	a0,72(sp)
    80005c16:	e8ae                	sd	a1,80(sp)
    80005c18:	ecb2                	sd	a2,88(sp)
    80005c1a:	f0b6                	sd	a3,96(sp)
    80005c1c:	f4ba                	sd	a4,104(sp)
    80005c1e:	f8be                	sd	a5,112(sp)
    80005c20:	fcc2                	sd	a6,120(sp)
    80005c22:	e146                	sd	a7,128(sp)
    80005c24:	e54a                	sd	s2,136(sp)
    80005c26:	e94e                	sd	s3,144(sp)
    80005c28:	ed52                	sd	s4,152(sp)
    80005c2a:	f156                	sd	s5,160(sp)
    80005c2c:	f55a                	sd	s6,168(sp)
    80005c2e:	f95e                	sd	s7,176(sp)
    80005c30:	fd62                	sd	s8,184(sp)
    80005c32:	e1e6                	sd	s9,192(sp)
    80005c34:	e5ea                	sd	s10,200(sp)
    80005c36:	e9ee                	sd	s11,208(sp)
    80005c38:	edf2                	sd	t3,216(sp)
    80005c3a:	f1f6                	sd	t4,224(sp)
    80005c3c:	f5fa                	sd	t5,232(sp)
    80005c3e:	f9fe                	sd	t6,240(sp)
    80005c40:	d1bfc0ef          	jal	ra,8000295a <kerneltrap>
    80005c44:	6082                	ld	ra,0(sp)
    80005c46:	6122                	ld	sp,8(sp)
    80005c48:	61c2                	ld	gp,16(sp)
    80005c4a:	7282                	ld	t0,32(sp)
    80005c4c:	7322                	ld	t1,40(sp)
    80005c4e:	73c2                	ld	t2,48(sp)
    80005c50:	7462                	ld	s0,56(sp)
    80005c52:	6486                	ld	s1,64(sp)
    80005c54:	6526                	ld	a0,72(sp)
    80005c56:	65c6                	ld	a1,80(sp)
    80005c58:	6666                	ld	a2,88(sp)
    80005c5a:	7686                	ld	a3,96(sp)
    80005c5c:	7726                	ld	a4,104(sp)
    80005c5e:	77c6                	ld	a5,112(sp)
    80005c60:	7866                	ld	a6,120(sp)
    80005c62:	688a                	ld	a7,128(sp)
    80005c64:	692a                	ld	s2,136(sp)
    80005c66:	69ca                	ld	s3,144(sp)
    80005c68:	6a6a                	ld	s4,152(sp)
    80005c6a:	7a8a                	ld	s5,160(sp)
    80005c6c:	7b2a                	ld	s6,168(sp)
    80005c6e:	7bca                	ld	s7,176(sp)
    80005c70:	7c6a                	ld	s8,184(sp)
    80005c72:	6c8e                	ld	s9,192(sp)
    80005c74:	6d2e                	ld	s10,200(sp)
    80005c76:	6dce                	ld	s11,208(sp)
    80005c78:	6e6e                	ld	t3,216(sp)
    80005c7a:	7e8e                	ld	t4,224(sp)
    80005c7c:	7f2e                	ld	t5,232(sp)
    80005c7e:	7fce                	ld	t6,240(sp)
    80005c80:	6111                	addi	sp,sp,256
    80005c82:	10200073          	sret
    80005c86:	00000013          	nop
    80005c8a:	00000013          	nop
    80005c8e:	0001                	nop

0000000080005c90 <timervec>:
    80005c90:	34051573          	csrrw	a0,mscratch,a0
    80005c94:	e10c                	sd	a1,0(a0)
    80005c96:	e510                	sd	a2,8(a0)
    80005c98:	e914                	sd	a3,16(a0)
    80005c9a:	6d0c                	ld	a1,24(a0)
    80005c9c:	7110                	ld	a2,32(a0)
    80005c9e:	6194                	ld	a3,0(a1)
    80005ca0:	96b2                	add	a3,a3,a2
    80005ca2:	e194                	sd	a3,0(a1)
    80005ca4:	4589                	li	a1,2
    80005ca6:	14459073          	csrw	sip,a1
    80005caa:	6914                	ld	a3,16(a0)
    80005cac:	6510                	ld	a2,8(a0)
    80005cae:	610c                	ld	a1,0(a0)
    80005cb0:	34051573          	csrrw	a0,mscratch,a0
    80005cb4:	30200073          	mret
	...

0000000080005cba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cba:	1141                	addi	sp,sp,-16
    80005cbc:	e422                	sd	s0,8(sp)
    80005cbe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cc0:	0c0007b7          	lui	a5,0xc000
    80005cc4:	4705                	li	a4,1
    80005cc6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cc8:	c3d8                	sw	a4,4(a5)
}
    80005cca:	6422                	ld	s0,8(sp)
    80005ccc:	0141                	addi	sp,sp,16
    80005cce:	8082                	ret

0000000080005cd0 <plicinithart>:

void
plicinithart(void)
{
    80005cd0:	1141                	addi	sp,sp,-16
    80005cd2:	e406                	sd	ra,8(sp)
    80005cd4:	e022                	sd	s0,0(sp)
    80005cd6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cd8:	ffffc097          	auipc	ra,0xffffc
    80005cdc:	ca2080e7          	jalr	-862(ra) # 8000197a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ce0:	0085171b          	slliw	a4,a0,0x8
    80005ce4:	0c0027b7          	lui	a5,0xc002
    80005ce8:	97ba                	add	a5,a5,a4
    80005cea:	40200713          	li	a4,1026
    80005cee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005cf2:	00d5151b          	slliw	a0,a0,0xd
    80005cf6:	0c2017b7          	lui	a5,0xc201
    80005cfa:	97aa                	add	a5,a5,a0
    80005cfc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005d00:	60a2                	ld	ra,8(sp)
    80005d02:	6402                	ld	s0,0(sp)
    80005d04:	0141                	addi	sp,sp,16
    80005d06:	8082                	ret

0000000080005d08 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d08:	1141                	addi	sp,sp,-16
    80005d0a:	e406                	sd	ra,8(sp)
    80005d0c:	e022                	sd	s0,0(sp)
    80005d0e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d10:	ffffc097          	auipc	ra,0xffffc
    80005d14:	c6a080e7          	jalr	-918(ra) # 8000197a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d18:	00d5151b          	slliw	a0,a0,0xd
    80005d1c:	0c2017b7          	lui	a5,0xc201
    80005d20:	97aa                	add	a5,a5,a0
  return irq;
}
    80005d22:	43c8                	lw	a0,4(a5)
    80005d24:	60a2                	ld	ra,8(sp)
    80005d26:	6402                	ld	s0,0(sp)
    80005d28:	0141                	addi	sp,sp,16
    80005d2a:	8082                	ret

0000000080005d2c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d2c:	1101                	addi	sp,sp,-32
    80005d2e:	ec06                	sd	ra,24(sp)
    80005d30:	e822                	sd	s0,16(sp)
    80005d32:	e426                	sd	s1,8(sp)
    80005d34:	1000                	addi	s0,sp,32
    80005d36:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d38:	ffffc097          	auipc	ra,0xffffc
    80005d3c:	c42080e7          	jalr	-958(ra) # 8000197a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d40:	00d5151b          	slliw	a0,a0,0xd
    80005d44:	0c2017b7          	lui	a5,0xc201
    80005d48:	97aa                	add	a5,a5,a0
    80005d4a:	c3c4                	sw	s1,4(a5)
}
    80005d4c:	60e2                	ld	ra,24(sp)
    80005d4e:	6442                	ld	s0,16(sp)
    80005d50:	64a2                	ld	s1,8(sp)
    80005d52:	6105                	addi	sp,sp,32
    80005d54:	8082                	ret

0000000080005d56 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d56:	1141                	addi	sp,sp,-16
    80005d58:	e406                	sd	ra,8(sp)
    80005d5a:	e022                	sd	s0,0(sp)
    80005d5c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d5e:	479d                	li	a5,7
    80005d60:	04a7cc63          	blt	a5,a0,80005db8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005d64:	0001c797          	auipc	a5,0x1c
    80005d68:	f6c78793          	addi	a5,a5,-148 # 80021cd0 <disk>
    80005d6c:	97aa                	add	a5,a5,a0
    80005d6e:	0187c783          	lbu	a5,24(a5)
    80005d72:	ebb9                	bnez	a5,80005dc8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d74:	00451693          	slli	a3,a0,0x4
    80005d78:	0001c797          	auipc	a5,0x1c
    80005d7c:	f5878793          	addi	a5,a5,-168 # 80021cd0 <disk>
    80005d80:	6398                	ld	a4,0(a5)
    80005d82:	9736                	add	a4,a4,a3
    80005d84:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005d88:	6398                	ld	a4,0(a5)
    80005d8a:	9736                	add	a4,a4,a3
    80005d8c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005d90:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005d94:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005d98:	97aa                	add	a5,a5,a0
    80005d9a:	4705                	li	a4,1
    80005d9c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005da0:	0001c517          	auipc	a0,0x1c
    80005da4:	f4850513          	addi	a0,a0,-184 # 80021ce8 <disk+0x18>
    80005da8:	ffffc097          	auipc	ra,0xffffc
    80005dac:	30a080e7          	jalr	778(ra) # 800020b2 <wakeup>
}
    80005db0:	60a2                	ld	ra,8(sp)
    80005db2:	6402                	ld	s0,0(sp)
    80005db4:	0141                	addi	sp,sp,16
    80005db6:	8082                	ret
    panic("free_desc 1");
    80005db8:	00003517          	auipc	a0,0x3
    80005dbc:	a5850513          	addi	a0,a0,-1448 # 80008810 <stateString.0+0x270>
    80005dc0:	ffffa097          	auipc	ra,0xffffa
    80005dc4:	77c080e7          	jalr	1916(ra) # 8000053c <panic>
    panic("free_desc 2");
    80005dc8:	00003517          	auipc	a0,0x3
    80005dcc:	a5850513          	addi	a0,a0,-1448 # 80008820 <stateString.0+0x280>
    80005dd0:	ffffa097          	auipc	ra,0xffffa
    80005dd4:	76c080e7          	jalr	1900(ra) # 8000053c <panic>

0000000080005dd8 <virtio_disk_init>:
{
    80005dd8:	1101                	addi	sp,sp,-32
    80005dda:	ec06                	sd	ra,24(sp)
    80005ddc:	e822                	sd	s0,16(sp)
    80005dde:	e426                	sd	s1,8(sp)
    80005de0:	e04a                	sd	s2,0(sp)
    80005de2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005de4:	00003597          	auipc	a1,0x3
    80005de8:	a4c58593          	addi	a1,a1,-1460 # 80008830 <stateString.0+0x290>
    80005dec:	0001c517          	auipc	a0,0x1c
    80005df0:	00c50513          	addi	a0,a0,12 # 80021df8 <disk+0x128>
    80005df4:	ffffb097          	auipc	ra,0xffffb
    80005df8:	d4e080e7          	jalr	-690(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005dfc:	100017b7          	lui	a5,0x10001
    80005e00:	4398                	lw	a4,0(a5)
    80005e02:	2701                	sext.w	a4,a4
    80005e04:	747277b7          	lui	a5,0x74727
    80005e08:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e0c:	14f71b63          	bne	a4,a5,80005f62 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e10:	100017b7          	lui	a5,0x10001
    80005e14:	43dc                	lw	a5,4(a5)
    80005e16:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e18:	4709                	li	a4,2
    80005e1a:	14e79463          	bne	a5,a4,80005f62 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e1e:	100017b7          	lui	a5,0x10001
    80005e22:	479c                	lw	a5,8(a5)
    80005e24:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e26:	12e79e63          	bne	a5,a4,80005f62 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e2a:	100017b7          	lui	a5,0x10001
    80005e2e:	47d8                	lw	a4,12(a5)
    80005e30:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e32:	554d47b7          	lui	a5,0x554d4
    80005e36:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e3a:	12f71463          	bne	a4,a5,80005f62 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e3e:	100017b7          	lui	a5,0x10001
    80005e42:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e46:	4705                	li	a4,1
    80005e48:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e4a:	470d                	li	a4,3
    80005e4c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e4e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e50:	c7ffe6b7          	lui	a3,0xc7ffe
    80005e54:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc94f>
    80005e58:	8f75                	and	a4,a4,a3
    80005e5a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e5c:	472d                	li	a4,11
    80005e5e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005e60:	5bbc                	lw	a5,112(a5)
    80005e62:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005e66:	8ba1                	andi	a5,a5,8
    80005e68:	10078563          	beqz	a5,80005f72 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e6c:	100017b7          	lui	a5,0x10001
    80005e70:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005e74:	43fc                	lw	a5,68(a5)
    80005e76:	2781                	sext.w	a5,a5
    80005e78:	10079563          	bnez	a5,80005f82 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e7c:	100017b7          	lui	a5,0x10001
    80005e80:	5bdc                	lw	a5,52(a5)
    80005e82:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e84:	10078763          	beqz	a5,80005f92 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005e88:	471d                	li	a4,7
    80005e8a:	10f77c63          	bgeu	a4,a5,80005fa2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005e8e:	ffffb097          	auipc	ra,0xffffb
    80005e92:	c54080e7          	jalr	-940(ra) # 80000ae2 <kalloc>
    80005e96:	0001c497          	auipc	s1,0x1c
    80005e9a:	e3a48493          	addi	s1,s1,-454 # 80021cd0 <disk>
    80005e9e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005ea0:	ffffb097          	auipc	ra,0xffffb
    80005ea4:	c42080e7          	jalr	-958(ra) # 80000ae2 <kalloc>
    80005ea8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005eaa:	ffffb097          	auipc	ra,0xffffb
    80005eae:	c38080e7          	jalr	-968(ra) # 80000ae2 <kalloc>
    80005eb2:	87aa                	mv	a5,a0
    80005eb4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005eb6:	6088                	ld	a0,0(s1)
    80005eb8:	cd6d                	beqz	a0,80005fb2 <virtio_disk_init+0x1da>
    80005eba:	0001c717          	auipc	a4,0x1c
    80005ebe:	e1e73703          	ld	a4,-482(a4) # 80021cd8 <disk+0x8>
    80005ec2:	cb65                	beqz	a4,80005fb2 <virtio_disk_init+0x1da>
    80005ec4:	c7fd                	beqz	a5,80005fb2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005ec6:	6605                	lui	a2,0x1
    80005ec8:	4581                	li	a1,0
    80005eca:	ffffb097          	auipc	ra,0xffffb
    80005ece:	e04080e7          	jalr	-508(ra) # 80000cce <memset>
  memset(disk.avail, 0, PGSIZE);
    80005ed2:	0001c497          	auipc	s1,0x1c
    80005ed6:	dfe48493          	addi	s1,s1,-514 # 80021cd0 <disk>
    80005eda:	6605                	lui	a2,0x1
    80005edc:	4581                	li	a1,0
    80005ede:	6488                	ld	a0,8(s1)
    80005ee0:	ffffb097          	auipc	ra,0xffffb
    80005ee4:	dee080e7          	jalr	-530(ra) # 80000cce <memset>
  memset(disk.used, 0, PGSIZE);
    80005ee8:	6605                	lui	a2,0x1
    80005eea:	4581                	li	a1,0
    80005eec:	6888                	ld	a0,16(s1)
    80005eee:	ffffb097          	auipc	ra,0xffffb
    80005ef2:	de0080e7          	jalr	-544(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ef6:	100017b7          	lui	a5,0x10001
    80005efa:	4721                	li	a4,8
    80005efc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005efe:	4098                	lw	a4,0(s1)
    80005f00:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f04:	40d8                	lw	a4,4(s1)
    80005f06:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f0a:	6498                	ld	a4,8(s1)
    80005f0c:	0007069b          	sext.w	a3,a4
    80005f10:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f14:	9701                	srai	a4,a4,0x20
    80005f16:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f1a:	6898                	ld	a4,16(s1)
    80005f1c:	0007069b          	sext.w	a3,a4
    80005f20:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005f24:	9701                	srai	a4,a4,0x20
    80005f26:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005f2a:	4705                	li	a4,1
    80005f2c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005f2e:	00e48c23          	sb	a4,24(s1)
    80005f32:	00e48ca3          	sb	a4,25(s1)
    80005f36:	00e48d23          	sb	a4,26(s1)
    80005f3a:	00e48da3          	sb	a4,27(s1)
    80005f3e:	00e48e23          	sb	a4,28(s1)
    80005f42:	00e48ea3          	sb	a4,29(s1)
    80005f46:	00e48f23          	sb	a4,30(s1)
    80005f4a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005f4e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f52:	0727a823          	sw	s2,112(a5)
}
    80005f56:	60e2                	ld	ra,24(sp)
    80005f58:	6442                	ld	s0,16(sp)
    80005f5a:	64a2                	ld	s1,8(sp)
    80005f5c:	6902                	ld	s2,0(sp)
    80005f5e:	6105                	addi	sp,sp,32
    80005f60:	8082                	ret
    panic("could not find virtio disk");
    80005f62:	00003517          	auipc	a0,0x3
    80005f66:	8de50513          	addi	a0,a0,-1826 # 80008840 <stateString.0+0x2a0>
    80005f6a:	ffffa097          	auipc	ra,0xffffa
    80005f6e:	5d2080e7          	jalr	1490(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80005f72:	00003517          	auipc	a0,0x3
    80005f76:	8ee50513          	addi	a0,a0,-1810 # 80008860 <stateString.0+0x2c0>
    80005f7a:	ffffa097          	auipc	ra,0xffffa
    80005f7e:	5c2080e7          	jalr	1474(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80005f82:	00003517          	auipc	a0,0x3
    80005f86:	8fe50513          	addi	a0,a0,-1794 # 80008880 <stateString.0+0x2e0>
    80005f8a:	ffffa097          	auipc	ra,0xffffa
    80005f8e:	5b2080e7          	jalr	1458(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80005f92:	00003517          	auipc	a0,0x3
    80005f96:	90e50513          	addi	a0,a0,-1778 # 800088a0 <stateString.0+0x300>
    80005f9a:	ffffa097          	auipc	ra,0xffffa
    80005f9e:	5a2080e7          	jalr	1442(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80005fa2:	00003517          	auipc	a0,0x3
    80005fa6:	91e50513          	addi	a0,a0,-1762 # 800088c0 <stateString.0+0x320>
    80005faa:	ffffa097          	auipc	ra,0xffffa
    80005fae:	592080e7          	jalr	1426(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80005fb2:	00003517          	auipc	a0,0x3
    80005fb6:	92e50513          	addi	a0,a0,-1746 # 800088e0 <stateString.0+0x340>
    80005fba:	ffffa097          	auipc	ra,0xffffa
    80005fbe:	582080e7          	jalr	1410(ra) # 8000053c <panic>

0000000080005fc2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005fc2:	7159                	addi	sp,sp,-112
    80005fc4:	f486                	sd	ra,104(sp)
    80005fc6:	f0a2                	sd	s0,96(sp)
    80005fc8:	eca6                	sd	s1,88(sp)
    80005fca:	e8ca                	sd	s2,80(sp)
    80005fcc:	e4ce                	sd	s3,72(sp)
    80005fce:	e0d2                	sd	s4,64(sp)
    80005fd0:	fc56                	sd	s5,56(sp)
    80005fd2:	f85a                	sd	s6,48(sp)
    80005fd4:	f45e                	sd	s7,40(sp)
    80005fd6:	f062                	sd	s8,32(sp)
    80005fd8:	ec66                	sd	s9,24(sp)
    80005fda:	e86a                	sd	s10,16(sp)
    80005fdc:	1880                	addi	s0,sp,112
    80005fde:	8a2a                	mv	s4,a0
    80005fe0:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fe2:	00c52c83          	lw	s9,12(a0)
    80005fe6:	001c9c9b          	slliw	s9,s9,0x1
    80005fea:	1c82                	slli	s9,s9,0x20
    80005fec:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005ff0:	0001c517          	auipc	a0,0x1c
    80005ff4:	e0850513          	addi	a0,a0,-504 # 80021df8 <disk+0x128>
    80005ff8:	ffffb097          	auipc	ra,0xffffb
    80005ffc:	bda080e7          	jalr	-1062(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80006000:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006002:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006004:	0001cb17          	auipc	s6,0x1c
    80006008:	cccb0b13          	addi	s6,s6,-820 # 80021cd0 <disk>
  for(int i = 0; i < 3; i++){
    8000600c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000600e:	0001cc17          	auipc	s8,0x1c
    80006012:	deac0c13          	addi	s8,s8,-534 # 80021df8 <disk+0x128>
    80006016:	a095                	j	8000607a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006018:	00fb0733          	add	a4,s6,a5
    8000601c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006020:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006022:	0207c563          	bltz	a5,8000604c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006026:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006028:	0591                	addi	a1,a1,4
    8000602a:	05560d63          	beq	a2,s5,80006084 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000602e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006030:	0001c717          	auipc	a4,0x1c
    80006034:	ca070713          	addi	a4,a4,-864 # 80021cd0 <disk>
    80006038:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000603a:	01874683          	lbu	a3,24(a4)
    8000603e:	fee9                	bnez	a3,80006018 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006040:	2785                	addiw	a5,a5,1
    80006042:	0705                	addi	a4,a4,1
    80006044:	fe979be3          	bne	a5,s1,8000603a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006048:	57fd                	li	a5,-1
    8000604a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000604c:	00c05e63          	blez	a2,80006068 <virtio_disk_rw+0xa6>
    80006050:	060a                	slli	a2,a2,0x2
    80006052:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006056:	0009a503          	lw	a0,0(s3)
    8000605a:	00000097          	auipc	ra,0x0
    8000605e:	cfc080e7          	jalr	-772(ra) # 80005d56 <free_desc>
      for(int j = 0; j < i; j++)
    80006062:	0991                	addi	s3,s3,4
    80006064:	ffa999e3          	bne	s3,s10,80006056 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006068:	85e2                	mv	a1,s8
    8000606a:	0001c517          	auipc	a0,0x1c
    8000606e:	c7e50513          	addi	a0,a0,-898 # 80021ce8 <disk+0x18>
    80006072:	ffffc097          	auipc	ra,0xffffc
    80006076:	fdc080e7          	jalr	-36(ra) # 8000204e <sleep>
  for(int i = 0; i < 3; i++){
    8000607a:	f9040993          	addi	s3,s0,-112
{
    8000607e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006080:	864a                	mv	a2,s2
    80006082:	b775                	j	8000602e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006084:	f9042503          	lw	a0,-112(s0)
    80006088:	00a50713          	addi	a4,a0,10
    8000608c:	0712                	slli	a4,a4,0x4

  if(write)
    8000608e:	0001c797          	auipc	a5,0x1c
    80006092:	c4278793          	addi	a5,a5,-958 # 80021cd0 <disk>
    80006096:	00e786b3          	add	a3,a5,a4
    8000609a:	01703633          	snez	a2,s7
    8000609e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800060a0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800060a4:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800060a8:	f6070613          	addi	a2,a4,-160
    800060ac:	6394                	ld	a3,0(a5)
    800060ae:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060b0:	00870593          	addi	a1,a4,8
    800060b4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800060b6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800060b8:	0007b803          	ld	a6,0(a5)
    800060bc:	9642                	add	a2,a2,a6
    800060be:	46c1                	li	a3,16
    800060c0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060c2:	4585                	li	a1,1
    800060c4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800060c8:	f9442683          	lw	a3,-108(s0)
    800060cc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060d0:	0692                	slli	a3,a3,0x4
    800060d2:	9836                	add	a6,a6,a3
    800060d4:	058a0613          	addi	a2,s4,88
    800060d8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800060dc:	0007b803          	ld	a6,0(a5)
    800060e0:	96c2                	add	a3,a3,a6
    800060e2:	40000613          	li	a2,1024
    800060e6:	c690                	sw	a2,8(a3)
  if(write)
    800060e8:	001bb613          	seqz	a2,s7
    800060ec:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060f0:	00166613          	ori	a2,a2,1
    800060f4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800060f8:	f9842603          	lw	a2,-104(s0)
    800060fc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006100:	00250693          	addi	a3,a0,2
    80006104:	0692                	slli	a3,a3,0x4
    80006106:	96be                	add	a3,a3,a5
    80006108:	58fd                	li	a7,-1
    8000610a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000610e:	0612                	slli	a2,a2,0x4
    80006110:	9832                	add	a6,a6,a2
    80006112:	f9070713          	addi	a4,a4,-112
    80006116:	973e                	add	a4,a4,a5
    80006118:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000611c:	6398                	ld	a4,0(a5)
    8000611e:	9732                	add	a4,a4,a2
    80006120:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006122:	4609                	li	a2,2
    80006124:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006128:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000612c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006130:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006134:	6794                	ld	a3,8(a5)
    80006136:	0026d703          	lhu	a4,2(a3)
    8000613a:	8b1d                	andi	a4,a4,7
    8000613c:	0706                	slli	a4,a4,0x1
    8000613e:	96ba                	add	a3,a3,a4
    80006140:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006144:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006148:	6798                	ld	a4,8(a5)
    8000614a:	00275783          	lhu	a5,2(a4)
    8000614e:	2785                	addiw	a5,a5,1
    80006150:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006154:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006158:	100017b7          	lui	a5,0x10001
    8000615c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006160:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006164:	0001c917          	auipc	s2,0x1c
    80006168:	c9490913          	addi	s2,s2,-876 # 80021df8 <disk+0x128>
  while(b->disk == 1) {
    8000616c:	4485                	li	s1,1
    8000616e:	00b79c63          	bne	a5,a1,80006186 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006172:	85ca                	mv	a1,s2
    80006174:	8552                	mv	a0,s4
    80006176:	ffffc097          	auipc	ra,0xffffc
    8000617a:	ed8080e7          	jalr	-296(ra) # 8000204e <sleep>
  while(b->disk == 1) {
    8000617e:	004a2783          	lw	a5,4(s4)
    80006182:	fe9788e3          	beq	a5,s1,80006172 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006186:	f9042903          	lw	s2,-112(s0)
    8000618a:	00290713          	addi	a4,s2,2
    8000618e:	0712                	slli	a4,a4,0x4
    80006190:	0001c797          	auipc	a5,0x1c
    80006194:	b4078793          	addi	a5,a5,-1216 # 80021cd0 <disk>
    80006198:	97ba                	add	a5,a5,a4
    8000619a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000619e:	0001c997          	auipc	s3,0x1c
    800061a2:	b3298993          	addi	s3,s3,-1230 # 80021cd0 <disk>
    800061a6:	00491713          	slli	a4,s2,0x4
    800061aa:	0009b783          	ld	a5,0(s3)
    800061ae:	97ba                	add	a5,a5,a4
    800061b0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800061b4:	854a                	mv	a0,s2
    800061b6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800061ba:	00000097          	auipc	ra,0x0
    800061be:	b9c080e7          	jalr	-1124(ra) # 80005d56 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800061c2:	8885                	andi	s1,s1,1
    800061c4:	f0ed                	bnez	s1,800061a6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061c6:	0001c517          	auipc	a0,0x1c
    800061ca:	c3250513          	addi	a0,a0,-974 # 80021df8 <disk+0x128>
    800061ce:	ffffb097          	auipc	ra,0xffffb
    800061d2:	ab8080e7          	jalr	-1352(ra) # 80000c86 <release>
}
    800061d6:	70a6                	ld	ra,104(sp)
    800061d8:	7406                	ld	s0,96(sp)
    800061da:	64e6                	ld	s1,88(sp)
    800061dc:	6946                	ld	s2,80(sp)
    800061de:	69a6                	ld	s3,72(sp)
    800061e0:	6a06                	ld	s4,64(sp)
    800061e2:	7ae2                	ld	s5,56(sp)
    800061e4:	7b42                	ld	s6,48(sp)
    800061e6:	7ba2                	ld	s7,40(sp)
    800061e8:	7c02                	ld	s8,32(sp)
    800061ea:	6ce2                	ld	s9,24(sp)
    800061ec:	6d42                	ld	s10,16(sp)
    800061ee:	6165                	addi	sp,sp,112
    800061f0:	8082                	ret

00000000800061f2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061f2:	1101                	addi	sp,sp,-32
    800061f4:	ec06                	sd	ra,24(sp)
    800061f6:	e822                	sd	s0,16(sp)
    800061f8:	e426                	sd	s1,8(sp)
    800061fa:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061fc:	0001c497          	auipc	s1,0x1c
    80006200:	ad448493          	addi	s1,s1,-1324 # 80021cd0 <disk>
    80006204:	0001c517          	auipc	a0,0x1c
    80006208:	bf450513          	addi	a0,a0,-1036 # 80021df8 <disk+0x128>
    8000620c:	ffffb097          	auipc	ra,0xffffb
    80006210:	9c6080e7          	jalr	-1594(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006214:	10001737          	lui	a4,0x10001
    80006218:	533c                	lw	a5,96(a4)
    8000621a:	8b8d                	andi	a5,a5,3
    8000621c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000621e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006222:	689c                	ld	a5,16(s1)
    80006224:	0204d703          	lhu	a4,32(s1)
    80006228:	0027d783          	lhu	a5,2(a5)
    8000622c:	04f70863          	beq	a4,a5,8000627c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006230:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006234:	6898                	ld	a4,16(s1)
    80006236:	0204d783          	lhu	a5,32(s1)
    8000623a:	8b9d                	andi	a5,a5,7
    8000623c:	078e                	slli	a5,a5,0x3
    8000623e:	97ba                	add	a5,a5,a4
    80006240:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006242:	00278713          	addi	a4,a5,2
    80006246:	0712                	slli	a4,a4,0x4
    80006248:	9726                	add	a4,a4,s1
    8000624a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000624e:	e721                	bnez	a4,80006296 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006250:	0789                	addi	a5,a5,2
    80006252:	0792                	slli	a5,a5,0x4
    80006254:	97a6                	add	a5,a5,s1
    80006256:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006258:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000625c:	ffffc097          	auipc	ra,0xffffc
    80006260:	e56080e7          	jalr	-426(ra) # 800020b2 <wakeup>

    disk.used_idx += 1;
    80006264:	0204d783          	lhu	a5,32(s1)
    80006268:	2785                	addiw	a5,a5,1
    8000626a:	17c2                	slli	a5,a5,0x30
    8000626c:	93c1                	srli	a5,a5,0x30
    8000626e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006272:	6898                	ld	a4,16(s1)
    80006274:	00275703          	lhu	a4,2(a4)
    80006278:	faf71ce3          	bne	a4,a5,80006230 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000627c:	0001c517          	auipc	a0,0x1c
    80006280:	b7c50513          	addi	a0,a0,-1156 # 80021df8 <disk+0x128>
    80006284:	ffffb097          	auipc	ra,0xffffb
    80006288:	a02080e7          	jalr	-1534(ra) # 80000c86 <release>
}
    8000628c:	60e2                	ld	ra,24(sp)
    8000628e:	6442                	ld	s0,16(sp)
    80006290:	64a2                	ld	s1,8(sp)
    80006292:	6105                	addi	sp,sp,32
    80006294:	8082                	ret
      panic("virtio_disk_intr status");
    80006296:	00002517          	auipc	a0,0x2
    8000629a:	66250513          	addi	a0,a0,1634 # 800088f8 <stateString.0+0x358>
    8000629e:	ffffa097          	auipc	ra,0xffffa
    800062a2:	29e080e7          	jalr	670(ra) # 8000053c <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
