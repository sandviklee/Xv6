
user/_ps:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/stat.h"
#include "user/user.h"
#include <stdarg.h>

int main(int argc, char const *argv[])
{
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
    ps();
   8:	00000097          	auipc	ra,0x0
   c:	350080e7          	jalr	848(ra) # 358 <ps>
    /* code */
    return 0;
}
  10:	4501                	li	a0,0
  12:	60a2                	ld	ra,8(sp)
  14:	6402                	ld	s0,0(sp)
  16:	0141                	addi	sp,sp,16
  18:	8082                	ret

000000000000001a <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  1a:	1141                	addi	sp,sp,-16
  1c:	e406                	sd	ra,8(sp)
  1e:	e022                	sd	s0,0(sp)
  20:	0800                	addi	s0,sp,16
  extern int main();
  main();
  22:	00000097          	auipc	ra,0x0
  26:	fde080e7          	jalr	-34(ra) # 0 <main>
  exit(0);
  2a:	4501                	li	a0,0
  2c:	00000097          	auipc	ra,0x0
  30:	274080e7          	jalr	628(ra) # 2a0 <exit>

0000000000000034 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  34:	1141                	addi	sp,sp,-16
  36:	e422                	sd	s0,8(sp)
  38:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  3a:	87aa                	mv	a5,a0
  3c:	0585                	addi	a1,a1,1
  3e:	0785                	addi	a5,a5,1
  40:	fff5c703          	lbu	a4,-1(a1)
  44:	fee78fa3          	sb	a4,-1(a5)
  48:	fb75                	bnez	a4,3c <strcpy+0x8>
    ;
  return os;
}
  4a:	6422                	ld	s0,8(sp)
  4c:	0141                	addi	sp,sp,16
  4e:	8082                	ret

0000000000000050 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  50:	1141                	addi	sp,sp,-16
  52:	e422                	sd	s0,8(sp)
  54:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  56:	00054783          	lbu	a5,0(a0)
  5a:	cb91                	beqz	a5,6e <strcmp+0x1e>
  5c:	0005c703          	lbu	a4,0(a1)
  60:	00f71763          	bne	a4,a5,6e <strcmp+0x1e>
    p++, q++;
  64:	0505                	addi	a0,a0,1
  66:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  68:	00054783          	lbu	a5,0(a0)
  6c:	fbe5                	bnez	a5,5c <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  6e:	0005c503          	lbu	a0,0(a1)
}
  72:	40a7853b          	subw	a0,a5,a0
  76:	6422                	ld	s0,8(sp)
  78:	0141                	addi	sp,sp,16
  7a:	8082                	ret

000000000000007c <strlen>:

uint
strlen(const char *s)
{
  7c:	1141                	addi	sp,sp,-16
  7e:	e422                	sd	s0,8(sp)
  80:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  82:	00054783          	lbu	a5,0(a0)
  86:	cf91                	beqz	a5,a2 <strlen+0x26>
  88:	0505                	addi	a0,a0,1
  8a:	87aa                	mv	a5,a0
  8c:	86be                	mv	a3,a5
  8e:	0785                	addi	a5,a5,1
  90:	fff7c703          	lbu	a4,-1(a5)
  94:	ff65                	bnez	a4,8c <strlen+0x10>
  96:	40a6853b          	subw	a0,a3,a0
  9a:	2505                	addiw	a0,a0,1
    ;
  return n;
}
  9c:	6422                	ld	s0,8(sp)
  9e:	0141                	addi	sp,sp,16
  a0:	8082                	ret
  for(n = 0; s[n]; n++)
  a2:	4501                	li	a0,0
  a4:	bfe5                	j	9c <strlen+0x20>

00000000000000a6 <memset>:

void*
memset(void *dst, int c, uint n)
{
  a6:	1141                	addi	sp,sp,-16
  a8:	e422                	sd	s0,8(sp)
  aa:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  ac:	ca19                	beqz	a2,c2 <memset+0x1c>
  ae:	87aa                	mv	a5,a0
  b0:	1602                	slli	a2,a2,0x20
  b2:	9201                	srli	a2,a2,0x20
  b4:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  b8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  bc:	0785                	addi	a5,a5,1
  be:	fee79de3          	bne	a5,a4,b8 <memset+0x12>
  }
  return dst;
}
  c2:	6422                	ld	s0,8(sp)
  c4:	0141                	addi	sp,sp,16
  c6:	8082                	ret

00000000000000c8 <strchr>:

char*
strchr(const char *s, char c)
{
  c8:	1141                	addi	sp,sp,-16
  ca:	e422                	sd	s0,8(sp)
  cc:	0800                	addi	s0,sp,16
  for(; *s; s++)
  ce:	00054783          	lbu	a5,0(a0)
  d2:	cb99                	beqz	a5,e8 <strchr+0x20>
    if(*s == c)
  d4:	00f58763          	beq	a1,a5,e2 <strchr+0x1a>
  for(; *s; s++)
  d8:	0505                	addi	a0,a0,1
  da:	00054783          	lbu	a5,0(a0)
  de:	fbfd                	bnez	a5,d4 <strchr+0xc>
      return (char*)s;
  return 0;
  e0:	4501                	li	a0,0
}
  e2:	6422                	ld	s0,8(sp)
  e4:	0141                	addi	sp,sp,16
  e6:	8082                	ret
  return 0;
  e8:	4501                	li	a0,0
  ea:	bfe5                	j	e2 <strchr+0x1a>

00000000000000ec <gets>:

char*
gets(char *buf, int max)
{
  ec:	711d                	addi	sp,sp,-96
  ee:	ec86                	sd	ra,88(sp)
  f0:	e8a2                	sd	s0,80(sp)
  f2:	e4a6                	sd	s1,72(sp)
  f4:	e0ca                	sd	s2,64(sp)
  f6:	fc4e                	sd	s3,56(sp)
  f8:	f852                	sd	s4,48(sp)
  fa:	f456                	sd	s5,40(sp)
  fc:	f05a                	sd	s6,32(sp)
  fe:	ec5e                	sd	s7,24(sp)
 100:	1080                	addi	s0,sp,96
 102:	8baa                	mv	s7,a0
 104:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 106:	892a                	mv	s2,a0
 108:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 10a:	4aa9                	li	s5,10
 10c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 10e:	89a6                	mv	s3,s1
 110:	2485                	addiw	s1,s1,1
 112:	0344d863          	bge	s1,s4,142 <gets+0x56>
    cc = read(0, &c, 1);
 116:	4605                	li	a2,1
 118:	faf40593          	addi	a1,s0,-81
 11c:	4501                	li	a0,0
 11e:	00000097          	auipc	ra,0x0
 122:	19a080e7          	jalr	410(ra) # 2b8 <read>
    if(cc < 1)
 126:	00a05e63          	blez	a0,142 <gets+0x56>
    buf[i++] = c;
 12a:	faf44783          	lbu	a5,-81(s0)
 12e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 132:	01578763          	beq	a5,s5,140 <gets+0x54>
 136:	0905                	addi	s2,s2,1
 138:	fd679be3          	bne	a5,s6,10e <gets+0x22>
  for(i=0; i+1 < max; ){
 13c:	89a6                	mv	s3,s1
 13e:	a011                	j	142 <gets+0x56>
 140:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 142:	99de                	add	s3,s3,s7
 144:	00098023          	sb	zero,0(s3)
  return buf;
}
 148:	855e                	mv	a0,s7
 14a:	60e6                	ld	ra,88(sp)
 14c:	6446                	ld	s0,80(sp)
 14e:	64a6                	ld	s1,72(sp)
 150:	6906                	ld	s2,64(sp)
 152:	79e2                	ld	s3,56(sp)
 154:	7a42                	ld	s4,48(sp)
 156:	7aa2                	ld	s5,40(sp)
 158:	7b02                	ld	s6,32(sp)
 15a:	6be2                	ld	s7,24(sp)
 15c:	6125                	addi	sp,sp,96
 15e:	8082                	ret

0000000000000160 <stat>:

int
stat(const char *n, struct stat *st)
{
 160:	1101                	addi	sp,sp,-32
 162:	ec06                	sd	ra,24(sp)
 164:	e822                	sd	s0,16(sp)
 166:	e426                	sd	s1,8(sp)
 168:	e04a                	sd	s2,0(sp)
 16a:	1000                	addi	s0,sp,32
 16c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 16e:	4581                	li	a1,0
 170:	00000097          	auipc	ra,0x0
 174:	170080e7          	jalr	368(ra) # 2e0 <open>
  if(fd < 0)
 178:	02054563          	bltz	a0,1a2 <stat+0x42>
 17c:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 17e:	85ca                	mv	a1,s2
 180:	00000097          	auipc	ra,0x0
 184:	178080e7          	jalr	376(ra) # 2f8 <fstat>
 188:	892a                	mv	s2,a0
  close(fd);
 18a:	8526                	mv	a0,s1
 18c:	00000097          	auipc	ra,0x0
 190:	13c080e7          	jalr	316(ra) # 2c8 <close>
  return r;
}
 194:	854a                	mv	a0,s2
 196:	60e2                	ld	ra,24(sp)
 198:	6442                	ld	s0,16(sp)
 19a:	64a2                	ld	s1,8(sp)
 19c:	6902                	ld	s2,0(sp)
 19e:	6105                	addi	sp,sp,32
 1a0:	8082                	ret
    return -1;
 1a2:	597d                	li	s2,-1
 1a4:	bfc5                	j	194 <stat+0x34>

00000000000001a6 <atoi>:

int
atoi(const char *s)
{
 1a6:	1141                	addi	sp,sp,-16
 1a8:	e422                	sd	s0,8(sp)
 1aa:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1ac:	00054683          	lbu	a3,0(a0)
 1b0:	fd06879b          	addiw	a5,a3,-48
 1b4:	0ff7f793          	zext.b	a5,a5
 1b8:	4625                	li	a2,9
 1ba:	02f66863          	bltu	a2,a5,1ea <atoi+0x44>
 1be:	872a                	mv	a4,a0
  n = 0;
 1c0:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 1c2:	0705                	addi	a4,a4,1
 1c4:	0025179b          	slliw	a5,a0,0x2
 1c8:	9fa9                	addw	a5,a5,a0
 1ca:	0017979b          	slliw	a5,a5,0x1
 1ce:	9fb5                	addw	a5,a5,a3
 1d0:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1d4:	00074683          	lbu	a3,0(a4)
 1d8:	fd06879b          	addiw	a5,a3,-48
 1dc:	0ff7f793          	zext.b	a5,a5
 1e0:	fef671e3          	bgeu	a2,a5,1c2 <atoi+0x1c>
  return n;
}
 1e4:	6422                	ld	s0,8(sp)
 1e6:	0141                	addi	sp,sp,16
 1e8:	8082                	ret
  n = 0;
 1ea:	4501                	li	a0,0
 1ec:	bfe5                	j	1e4 <atoi+0x3e>

00000000000001ee <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 1ee:	1141                	addi	sp,sp,-16
 1f0:	e422                	sd	s0,8(sp)
 1f2:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 1f4:	02b57463          	bgeu	a0,a1,21c <memmove+0x2e>
    while(n-- > 0)
 1f8:	00c05f63          	blez	a2,216 <memmove+0x28>
 1fc:	1602                	slli	a2,a2,0x20
 1fe:	9201                	srli	a2,a2,0x20
 200:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 204:	872a                	mv	a4,a0
      *dst++ = *src++;
 206:	0585                	addi	a1,a1,1
 208:	0705                	addi	a4,a4,1
 20a:	fff5c683          	lbu	a3,-1(a1)
 20e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 212:	fee79ae3          	bne	a5,a4,206 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 216:	6422                	ld	s0,8(sp)
 218:	0141                	addi	sp,sp,16
 21a:	8082                	ret
    dst += n;
 21c:	00c50733          	add	a4,a0,a2
    src += n;
 220:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 222:	fec05ae3          	blez	a2,216 <memmove+0x28>
 226:	fff6079b          	addiw	a5,a2,-1
 22a:	1782                	slli	a5,a5,0x20
 22c:	9381                	srli	a5,a5,0x20
 22e:	fff7c793          	not	a5,a5
 232:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 234:	15fd                	addi	a1,a1,-1
 236:	177d                	addi	a4,a4,-1
 238:	0005c683          	lbu	a3,0(a1)
 23c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 240:	fee79ae3          	bne	a5,a4,234 <memmove+0x46>
 244:	bfc9                	j	216 <memmove+0x28>

0000000000000246 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 246:	1141                	addi	sp,sp,-16
 248:	e422                	sd	s0,8(sp)
 24a:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 24c:	ca05                	beqz	a2,27c <memcmp+0x36>
 24e:	fff6069b          	addiw	a3,a2,-1
 252:	1682                	slli	a3,a3,0x20
 254:	9281                	srli	a3,a3,0x20
 256:	0685                	addi	a3,a3,1
 258:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 25a:	00054783          	lbu	a5,0(a0)
 25e:	0005c703          	lbu	a4,0(a1)
 262:	00e79863          	bne	a5,a4,272 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 266:	0505                	addi	a0,a0,1
    p2++;
 268:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 26a:	fed518e3          	bne	a0,a3,25a <memcmp+0x14>
  }
  return 0;
 26e:	4501                	li	a0,0
 270:	a019                	j	276 <memcmp+0x30>
      return *p1 - *p2;
 272:	40e7853b          	subw	a0,a5,a4
}
 276:	6422                	ld	s0,8(sp)
 278:	0141                	addi	sp,sp,16
 27a:	8082                	ret
  return 0;
 27c:	4501                	li	a0,0
 27e:	bfe5                	j	276 <memcmp+0x30>

0000000000000280 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 280:	1141                	addi	sp,sp,-16
 282:	e406                	sd	ra,8(sp)
 284:	e022                	sd	s0,0(sp)
 286:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 288:	00000097          	auipc	ra,0x0
 28c:	f66080e7          	jalr	-154(ra) # 1ee <memmove>
}
 290:	60a2                	ld	ra,8(sp)
 292:	6402                	ld	s0,0(sp)
 294:	0141                	addi	sp,sp,16
 296:	8082                	ret

0000000000000298 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 298:	4885                	li	a7,1
 ecall
 29a:	00000073          	ecall
 ret
 29e:	8082                	ret

00000000000002a0 <exit>:
.global exit
exit:
 li a7, SYS_exit
 2a0:	4889                	li	a7,2
 ecall
 2a2:	00000073          	ecall
 ret
 2a6:	8082                	ret

00000000000002a8 <wait>:
.global wait
wait:
 li a7, SYS_wait
 2a8:	488d                	li	a7,3
 ecall
 2aa:	00000073          	ecall
 ret
 2ae:	8082                	ret

00000000000002b0 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2b0:	4891                	li	a7,4
 ecall
 2b2:	00000073          	ecall
 ret
 2b6:	8082                	ret

00000000000002b8 <read>:
.global read
read:
 li a7, SYS_read
 2b8:	4895                	li	a7,5
 ecall
 2ba:	00000073          	ecall
 ret
 2be:	8082                	ret

00000000000002c0 <write>:
.global write
write:
 li a7, SYS_write
 2c0:	48c1                	li	a7,16
 ecall
 2c2:	00000073          	ecall
 ret
 2c6:	8082                	ret

00000000000002c8 <close>:
.global close
close:
 li a7, SYS_close
 2c8:	48d5                	li	a7,21
 ecall
 2ca:	00000073          	ecall
 ret
 2ce:	8082                	ret

00000000000002d0 <kill>:
.global kill
kill:
 li a7, SYS_kill
 2d0:	4899                	li	a7,6
 ecall
 2d2:	00000073          	ecall
 ret
 2d6:	8082                	ret

00000000000002d8 <exec>:
.global exec
exec:
 li a7, SYS_exec
 2d8:	489d                	li	a7,7
 ecall
 2da:	00000073          	ecall
 ret
 2de:	8082                	ret

00000000000002e0 <open>:
.global open
open:
 li a7, SYS_open
 2e0:	48bd                	li	a7,15
 ecall
 2e2:	00000073          	ecall
 ret
 2e6:	8082                	ret

00000000000002e8 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 2e8:	48c5                	li	a7,17
 ecall
 2ea:	00000073          	ecall
 ret
 2ee:	8082                	ret

00000000000002f0 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 2f0:	48c9                	li	a7,18
 ecall
 2f2:	00000073          	ecall
 ret
 2f6:	8082                	ret

00000000000002f8 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 2f8:	48a1                	li	a7,8
 ecall
 2fa:	00000073          	ecall
 ret
 2fe:	8082                	ret

0000000000000300 <link>:
.global link
link:
 li a7, SYS_link
 300:	48cd                	li	a7,19
 ecall
 302:	00000073          	ecall
 ret
 306:	8082                	ret

0000000000000308 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 308:	48d1                	li	a7,20
 ecall
 30a:	00000073          	ecall
 ret
 30e:	8082                	ret

0000000000000310 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 310:	48a5                	li	a7,9
 ecall
 312:	00000073          	ecall
 ret
 316:	8082                	ret

0000000000000318 <dup>:
.global dup
dup:
 li a7, SYS_dup
 318:	48a9                	li	a7,10
 ecall
 31a:	00000073          	ecall
 ret
 31e:	8082                	ret

0000000000000320 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 320:	48ad                	li	a7,11
 ecall
 322:	00000073          	ecall
 ret
 326:	8082                	ret

0000000000000328 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 328:	48b1                	li	a7,12
 ecall
 32a:	00000073          	ecall
 ret
 32e:	8082                	ret

0000000000000330 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 330:	48b5                	li	a7,13
 ecall
 332:	00000073          	ecall
 ret
 336:	8082                	ret

0000000000000338 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 338:	48b9                	li	a7,14
 ecall
 33a:	00000073          	ecall
 ret
 33e:	8082                	ret

0000000000000340 <hello>:
.global hello
hello:
 li a7, SYS_hello
 340:	48d9                	li	a7,22
 ecall
 342:	00000073          	ecall
 ret
 346:	8082                	ret

0000000000000348 <procState>:
.global procState
procState:
 li a7, SYS_procState
 348:	48dd                	li	a7,23
 ecall
 34a:	00000073          	ecall
 ret
 34e:	8082                	ret

0000000000000350 <prarr>:
.global prarr
prarr:
 li a7, SYS_prarr
 350:	48e1                	li	a7,24
 ecall
 352:	00000073          	ecall
 ret
 356:	8082                	ret

0000000000000358 <ps>:
.global ps
ps:
 li a7, SYS_ps
 358:	48e5                	li	a7,25
 ecall
 35a:	00000073          	ecall
 ret
 35e:	8082                	ret

0000000000000360 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 360:	1101                	addi	sp,sp,-32
 362:	ec06                	sd	ra,24(sp)
 364:	e822                	sd	s0,16(sp)
 366:	1000                	addi	s0,sp,32
 368:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 36c:	4605                	li	a2,1
 36e:	fef40593          	addi	a1,s0,-17
 372:	00000097          	auipc	ra,0x0
 376:	f4e080e7          	jalr	-178(ra) # 2c0 <write>
}
 37a:	60e2                	ld	ra,24(sp)
 37c:	6442                	ld	s0,16(sp)
 37e:	6105                	addi	sp,sp,32
 380:	8082                	ret

0000000000000382 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 382:	7139                	addi	sp,sp,-64
 384:	fc06                	sd	ra,56(sp)
 386:	f822                	sd	s0,48(sp)
 388:	f426                	sd	s1,40(sp)
 38a:	f04a                	sd	s2,32(sp)
 38c:	ec4e                	sd	s3,24(sp)
 38e:	0080                	addi	s0,sp,64
 390:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if (sgn && xx < 0)
 392:	c299                	beqz	a3,398 <printint+0x16>
 394:	0805c963          	bltz	a1,426 <printint+0xa4>
    neg = 1;
    x = -xx;
  }
  else
  {
    x = xx;
 398:	2581                	sext.w	a1,a1
  neg = 0;
 39a:	4881                	li	a7,0
 39c:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3a0:	4701                	li	a4,0
  do
  {
    buf[i++] = digits[x % base];
 3a2:	2601                	sext.w	a2,a2
 3a4:	00000517          	auipc	a0,0x0
 3a8:	48c50513          	addi	a0,a0,1164 # 830 <digits>
 3ac:	883a                	mv	a6,a4
 3ae:	2705                	addiw	a4,a4,1
 3b0:	02c5f7bb          	remuw	a5,a1,a2
 3b4:	1782                	slli	a5,a5,0x20
 3b6:	9381                	srli	a5,a5,0x20
 3b8:	97aa                	add	a5,a5,a0
 3ba:	0007c783          	lbu	a5,0(a5)
 3be:	00f68023          	sb	a5,0(a3)
  } while ((x /= base) != 0);
 3c2:	0005879b          	sext.w	a5,a1
 3c6:	02c5d5bb          	divuw	a1,a1,a2
 3ca:	0685                	addi	a3,a3,1
 3cc:	fec7f0e3          	bgeu	a5,a2,3ac <printint+0x2a>
  if (neg)
 3d0:	00088c63          	beqz	a7,3e8 <printint+0x66>
    buf[i++] = '-';
 3d4:	fd070793          	addi	a5,a4,-48
 3d8:	00878733          	add	a4,a5,s0
 3dc:	02d00793          	li	a5,45
 3e0:	fef70823          	sb	a5,-16(a4)
 3e4:	0028071b          	addiw	a4,a6,2

  while (--i >= 0)
 3e8:	02e05863          	blez	a4,418 <printint+0x96>
 3ec:	fc040793          	addi	a5,s0,-64
 3f0:	00e78933          	add	s2,a5,a4
 3f4:	fff78993          	addi	s3,a5,-1
 3f8:	99ba                	add	s3,s3,a4
 3fa:	377d                	addiw	a4,a4,-1
 3fc:	1702                	slli	a4,a4,0x20
 3fe:	9301                	srli	a4,a4,0x20
 400:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 404:	fff94583          	lbu	a1,-1(s2)
 408:	8526                	mv	a0,s1
 40a:	00000097          	auipc	ra,0x0
 40e:	f56080e7          	jalr	-170(ra) # 360 <putc>
  while (--i >= 0)
 412:	197d                	addi	s2,s2,-1
 414:	ff3918e3          	bne	s2,s3,404 <printint+0x82>
}
 418:	70e2                	ld	ra,56(sp)
 41a:	7442                	ld	s0,48(sp)
 41c:	74a2                	ld	s1,40(sp)
 41e:	7902                	ld	s2,32(sp)
 420:	69e2                	ld	s3,24(sp)
 422:	6121                	addi	sp,sp,64
 424:	8082                	ret
    x = -xx;
 426:	40b005bb          	negw	a1,a1
    neg = 1;
 42a:	4885                	li	a7,1
    x = -xx;
 42c:	bf85                	j	39c <printint+0x1a>

000000000000042e <vprintf>:
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void vprintf(int fd, const char *fmt, va_list ap)
{
 42e:	715d                	addi	sp,sp,-80
 430:	e486                	sd	ra,72(sp)
 432:	e0a2                	sd	s0,64(sp)
 434:	fc26                	sd	s1,56(sp)
 436:	f84a                	sd	s2,48(sp)
 438:	f44e                	sd	s3,40(sp)
 43a:	f052                	sd	s4,32(sp)
 43c:	ec56                	sd	s5,24(sp)
 43e:	e85a                	sd	s6,16(sp)
 440:	e45e                	sd	s7,8(sp)
 442:	e062                	sd	s8,0(sp)
 444:	0880                	addi	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for (i = 0; fmt[i]; i++)
 446:	0005c903          	lbu	s2,0(a1)
 44a:	18090c63          	beqz	s2,5e2 <vprintf+0x1b4>
 44e:	8aaa                	mv	s5,a0
 450:	8bb2                	mv	s7,a2
 452:	00158493          	addi	s1,a1,1
  state = 0;
 456:	4981                	li	s3,0
      else
      {
        putc(fd, c);
      }
    }
    else if (state == '%')
 458:	02500a13          	li	s4,37
 45c:	4b55                	li	s6,21
 45e:	a839                	j	47c <vprintf+0x4e>
        putc(fd, c);
 460:	85ca                	mv	a1,s2
 462:	8556                	mv	a0,s5
 464:	00000097          	auipc	ra,0x0
 468:	efc080e7          	jalr	-260(ra) # 360 <putc>
 46c:	a019                	j	472 <vprintf+0x44>
    else if (state == '%')
 46e:	01498d63          	beq	s3,s4,488 <vprintf+0x5a>
  for (i = 0; fmt[i]; i++)
 472:	0485                	addi	s1,s1,1
 474:	fff4c903          	lbu	s2,-1(s1)
 478:	16090563          	beqz	s2,5e2 <vprintf+0x1b4>
    if (state == 0)
 47c:	fe0999e3          	bnez	s3,46e <vprintf+0x40>
      if (c == '%')
 480:	ff4910e3          	bne	s2,s4,460 <vprintf+0x32>
        state = '%';
 484:	89d2                	mv	s3,s4
 486:	b7f5                	j	472 <vprintf+0x44>
    {
      if (c == 'd')
 488:	13490263          	beq	s2,s4,5ac <vprintf+0x17e>
 48c:	f9d9079b          	addiw	a5,s2,-99
 490:	0ff7f793          	zext.b	a5,a5
 494:	12fb6563          	bltu	s6,a5,5be <vprintf+0x190>
 498:	f9d9079b          	addiw	a5,s2,-99
 49c:	0ff7f713          	zext.b	a4,a5
 4a0:	10eb6f63          	bltu	s6,a4,5be <vprintf+0x190>
 4a4:	00271793          	slli	a5,a4,0x2
 4a8:	00000717          	auipc	a4,0x0
 4ac:	33070713          	addi	a4,a4,816 # 7d8 <malloc+0xf8>
 4b0:	97ba                	add	a5,a5,a4
 4b2:	439c                	lw	a5,0(a5)
 4b4:	97ba                	add	a5,a5,a4
 4b6:	8782                	jr	a5
      {
        printint(fd, va_arg(ap, int), 10, 1);
 4b8:	008b8913          	addi	s2,s7,8
 4bc:	4685                	li	a3,1
 4be:	4629                	li	a2,10
 4c0:	000ba583          	lw	a1,0(s7)
 4c4:	8556                	mv	a0,s5
 4c6:	00000097          	auipc	ra,0x0
 4ca:	ebc080e7          	jalr	-324(ra) # 382 <printint>
 4ce:	8bca                	mv	s7,s2
      {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 4d0:	4981                	li	s3,0
 4d2:	b745                	j	472 <vprintf+0x44>
        printint(fd, va_arg(ap, uint64), 10, 0);
 4d4:	008b8913          	addi	s2,s7,8
 4d8:	4681                	li	a3,0
 4da:	4629                	li	a2,10
 4dc:	000ba583          	lw	a1,0(s7)
 4e0:	8556                	mv	a0,s5
 4e2:	00000097          	auipc	ra,0x0
 4e6:	ea0080e7          	jalr	-352(ra) # 382 <printint>
 4ea:	8bca                	mv	s7,s2
      state = 0;
 4ec:	4981                	li	s3,0
 4ee:	b751                	j	472 <vprintf+0x44>
        printint(fd, va_arg(ap, int), 16, 0);
 4f0:	008b8913          	addi	s2,s7,8
 4f4:	4681                	li	a3,0
 4f6:	4641                	li	a2,16
 4f8:	000ba583          	lw	a1,0(s7)
 4fc:	8556                	mv	a0,s5
 4fe:	00000097          	auipc	ra,0x0
 502:	e84080e7          	jalr	-380(ra) # 382 <printint>
 506:	8bca                	mv	s7,s2
      state = 0;
 508:	4981                	li	s3,0
 50a:	b7a5                	j	472 <vprintf+0x44>
        printptr(fd, va_arg(ap, uint64));
 50c:	008b8c13          	addi	s8,s7,8
 510:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 514:	03000593          	li	a1,48
 518:	8556                	mv	a0,s5
 51a:	00000097          	auipc	ra,0x0
 51e:	e46080e7          	jalr	-442(ra) # 360 <putc>
  putc(fd, 'x');
 522:	07800593          	li	a1,120
 526:	8556                	mv	a0,s5
 528:	00000097          	auipc	ra,0x0
 52c:	e38080e7          	jalr	-456(ra) # 360 <putc>
 530:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 532:	00000b97          	auipc	s7,0x0
 536:	2feb8b93          	addi	s7,s7,766 # 830 <digits>
 53a:	03c9d793          	srli	a5,s3,0x3c
 53e:	97de                	add	a5,a5,s7
 540:	0007c583          	lbu	a1,0(a5)
 544:	8556                	mv	a0,s5
 546:	00000097          	auipc	ra,0x0
 54a:	e1a080e7          	jalr	-486(ra) # 360 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 54e:	0992                	slli	s3,s3,0x4
 550:	397d                	addiw	s2,s2,-1
 552:	fe0914e3          	bnez	s2,53a <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 556:	8be2                	mv	s7,s8
      state = 0;
 558:	4981                	li	s3,0
 55a:	bf21                	j	472 <vprintf+0x44>
        s = va_arg(ap, char *);
 55c:	008b8993          	addi	s3,s7,8
 560:	000bb903          	ld	s2,0(s7)
        if (s == 0)
 564:	02090163          	beqz	s2,586 <vprintf+0x158>
        while (*s != 0)
 568:	00094583          	lbu	a1,0(s2)
 56c:	c9a5                	beqz	a1,5dc <vprintf+0x1ae>
          putc(fd, *s);
 56e:	8556                	mv	a0,s5
 570:	00000097          	auipc	ra,0x0
 574:	df0080e7          	jalr	-528(ra) # 360 <putc>
          s++;
 578:	0905                	addi	s2,s2,1
        while (*s != 0)
 57a:	00094583          	lbu	a1,0(s2)
 57e:	f9e5                	bnez	a1,56e <vprintf+0x140>
        s = va_arg(ap, char *);
 580:	8bce                	mv	s7,s3
      state = 0;
 582:	4981                	li	s3,0
 584:	b5fd                	j	472 <vprintf+0x44>
          s = "(null)";
 586:	00000917          	auipc	s2,0x0
 58a:	24a90913          	addi	s2,s2,586 # 7d0 <malloc+0xf0>
        while (*s != 0)
 58e:	02800593          	li	a1,40
 592:	bff1                	j	56e <vprintf+0x140>
        putc(fd, va_arg(ap, uint));
 594:	008b8913          	addi	s2,s7,8
 598:	000bc583          	lbu	a1,0(s7)
 59c:	8556                	mv	a0,s5
 59e:	00000097          	auipc	ra,0x0
 5a2:	dc2080e7          	jalr	-574(ra) # 360 <putc>
 5a6:	8bca                	mv	s7,s2
      state = 0;
 5a8:	4981                	li	s3,0
 5aa:	b5e1                	j	472 <vprintf+0x44>
        putc(fd, c);
 5ac:	02500593          	li	a1,37
 5b0:	8556                	mv	a0,s5
 5b2:	00000097          	auipc	ra,0x0
 5b6:	dae080e7          	jalr	-594(ra) # 360 <putc>
      state = 0;
 5ba:	4981                	li	s3,0
 5bc:	bd5d                	j	472 <vprintf+0x44>
        putc(fd, '%');
 5be:	02500593          	li	a1,37
 5c2:	8556                	mv	a0,s5
 5c4:	00000097          	auipc	ra,0x0
 5c8:	d9c080e7          	jalr	-612(ra) # 360 <putc>
        putc(fd, c);
 5cc:	85ca                	mv	a1,s2
 5ce:	8556                	mv	a0,s5
 5d0:	00000097          	auipc	ra,0x0
 5d4:	d90080e7          	jalr	-624(ra) # 360 <putc>
      state = 0;
 5d8:	4981                	li	s3,0
 5da:	bd61                	j	472 <vprintf+0x44>
        s = va_arg(ap, char *);
 5dc:	8bce                	mv	s7,s3
      state = 0;
 5de:	4981                	li	s3,0
 5e0:	bd49                	j	472 <vprintf+0x44>
    }
  }
}
 5e2:	60a6                	ld	ra,72(sp)
 5e4:	6406                	ld	s0,64(sp)
 5e6:	74e2                	ld	s1,56(sp)
 5e8:	7942                	ld	s2,48(sp)
 5ea:	79a2                	ld	s3,40(sp)
 5ec:	7a02                	ld	s4,32(sp)
 5ee:	6ae2                	ld	s5,24(sp)
 5f0:	6b42                	ld	s6,16(sp)
 5f2:	6ba2                	ld	s7,8(sp)
 5f4:	6c02                	ld	s8,0(sp)
 5f6:	6161                	addi	sp,sp,80
 5f8:	8082                	ret

00000000000005fa <fprintf>:

void fprintf(int fd, const char *fmt, ...)
{
 5fa:	715d                	addi	sp,sp,-80
 5fc:	ec06                	sd	ra,24(sp)
 5fe:	e822                	sd	s0,16(sp)
 600:	1000                	addi	s0,sp,32
 602:	e010                	sd	a2,0(s0)
 604:	e414                	sd	a3,8(s0)
 606:	e818                	sd	a4,16(s0)
 608:	ec1c                	sd	a5,24(s0)
 60a:	03043023          	sd	a6,32(s0)
 60e:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 612:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 616:	8622                	mv	a2,s0
 618:	00000097          	auipc	ra,0x0
 61c:	e16080e7          	jalr	-490(ra) # 42e <vprintf>
}
 620:	60e2                	ld	ra,24(sp)
 622:	6442                	ld	s0,16(sp)
 624:	6161                	addi	sp,sp,80
 626:	8082                	ret

0000000000000628 <printf>:

void printf(const char *fmt, ...)
{
 628:	711d                	addi	sp,sp,-96
 62a:	ec06                	sd	ra,24(sp)
 62c:	e822                	sd	s0,16(sp)
 62e:	1000                	addi	s0,sp,32
 630:	e40c                	sd	a1,8(s0)
 632:	e810                	sd	a2,16(s0)
 634:	ec14                	sd	a3,24(s0)
 636:	f018                	sd	a4,32(s0)
 638:	f41c                	sd	a5,40(s0)
 63a:	03043823          	sd	a6,48(s0)
 63e:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 642:	00840613          	addi	a2,s0,8
 646:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 64a:	85aa                	mv	a1,a0
 64c:	4505                	li	a0,1
 64e:	00000097          	auipc	ra,0x0
 652:	de0080e7          	jalr	-544(ra) # 42e <vprintf>
}
 656:	60e2                	ld	ra,24(sp)
 658:	6442                	ld	s0,16(sp)
 65a:	6125                	addi	sp,sp,96
 65c:	8082                	ret

000000000000065e <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 65e:	1141                	addi	sp,sp,-16
 660:	e422                	sd	s0,8(sp)
 662:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 664:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 668:	00001797          	auipc	a5,0x1
 66c:	9987b783          	ld	a5,-1640(a5) # 1000 <freep>
 670:	a02d                	j	69a <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 672:	4618                	lw	a4,8(a2)
 674:	9f2d                	addw	a4,a4,a1
 676:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 67a:	6398                	ld	a4,0(a5)
 67c:	6310                	ld	a2,0(a4)
 67e:	a83d                	j	6bc <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 680:	ff852703          	lw	a4,-8(a0)
 684:	9f31                	addw	a4,a4,a2
 686:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 688:	ff053683          	ld	a3,-16(a0)
 68c:	a091                	j	6d0 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 68e:	6398                	ld	a4,0(a5)
 690:	00e7e463          	bltu	a5,a4,698 <free+0x3a>
 694:	00e6ea63          	bltu	a3,a4,6a8 <free+0x4a>
{
 698:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 69a:	fed7fae3          	bgeu	a5,a3,68e <free+0x30>
 69e:	6398                	ld	a4,0(a5)
 6a0:	00e6e463          	bltu	a3,a4,6a8 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6a4:	fee7eae3          	bltu	a5,a4,698 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 6a8:	ff852583          	lw	a1,-8(a0)
 6ac:	6390                	ld	a2,0(a5)
 6ae:	02059813          	slli	a6,a1,0x20
 6b2:	01c85713          	srli	a4,a6,0x1c
 6b6:	9736                	add	a4,a4,a3
 6b8:	fae60de3          	beq	a2,a4,672 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 6bc:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6c0:	4790                	lw	a2,8(a5)
 6c2:	02061593          	slli	a1,a2,0x20
 6c6:	01c5d713          	srli	a4,a1,0x1c
 6ca:	973e                	add	a4,a4,a5
 6cc:	fae68ae3          	beq	a3,a4,680 <free+0x22>
    p->s.ptr = bp->s.ptr;
 6d0:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 6d2:	00001717          	auipc	a4,0x1
 6d6:	92f73723          	sd	a5,-1746(a4) # 1000 <freep>
}
 6da:	6422                	ld	s0,8(sp)
 6dc:	0141                	addi	sp,sp,16
 6de:	8082                	ret

00000000000006e0 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 6e0:	7139                	addi	sp,sp,-64
 6e2:	fc06                	sd	ra,56(sp)
 6e4:	f822                	sd	s0,48(sp)
 6e6:	f426                	sd	s1,40(sp)
 6e8:	f04a                	sd	s2,32(sp)
 6ea:	ec4e                	sd	s3,24(sp)
 6ec:	e852                	sd	s4,16(sp)
 6ee:	e456                	sd	s5,8(sp)
 6f0:	e05a                	sd	s6,0(sp)
 6f2:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 6f4:	02051493          	slli	s1,a0,0x20
 6f8:	9081                	srli	s1,s1,0x20
 6fa:	04bd                	addi	s1,s1,15
 6fc:	8091                	srli	s1,s1,0x4
 6fe:	0014899b          	addiw	s3,s1,1
 702:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 704:	00001517          	auipc	a0,0x1
 708:	8fc53503          	ld	a0,-1796(a0) # 1000 <freep>
 70c:	c515                	beqz	a0,738 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 70e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 710:	4798                	lw	a4,8(a5)
 712:	02977f63          	bgeu	a4,s1,750 <malloc+0x70>
  if(nu < 4096)
 716:	8a4e                	mv	s4,s3
 718:	0009871b          	sext.w	a4,s3
 71c:	6685                	lui	a3,0x1
 71e:	00d77363          	bgeu	a4,a3,724 <malloc+0x44>
 722:	6a05                	lui	s4,0x1
 724:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 728:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 72c:	00001917          	auipc	s2,0x1
 730:	8d490913          	addi	s2,s2,-1836 # 1000 <freep>
  if(p == (char*)-1)
 734:	5afd                	li	s5,-1
 736:	a895                	j	7aa <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 738:	00001797          	auipc	a5,0x1
 73c:	8d878793          	addi	a5,a5,-1832 # 1010 <base>
 740:	00001717          	auipc	a4,0x1
 744:	8cf73023          	sd	a5,-1856(a4) # 1000 <freep>
 748:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 74a:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 74e:	b7e1                	j	716 <malloc+0x36>
      if(p->s.size == nunits)
 750:	02e48c63          	beq	s1,a4,788 <malloc+0xa8>
        p->s.size -= nunits;
 754:	4137073b          	subw	a4,a4,s3
 758:	c798                	sw	a4,8(a5)
        p += p->s.size;
 75a:	02071693          	slli	a3,a4,0x20
 75e:	01c6d713          	srli	a4,a3,0x1c
 762:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 764:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 768:	00001717          	auipc	a4,0x1
 76c:	88a73c23          	sd	a0,-1896(a4) # 1000 <freep>
      return (void*)(p + 1);
 770:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 774:	70e2                	ld	ra,56(sp)
 776:	7442                	ld	s0,48(sp)
 778:	74a2                	ld	s1,40(sp)
 77a:	7902                	ld	s2,32(sp)
 77c:	69e2                	ld	s3,24(sp)
 77e:	6a42                	ld	s4,16(sp)
 780:	6aa2                	ld	s5,8(sp)
 782:	6b02                	ld	s6,0(sp)
 784:	6121                	addi	sp,sp,64
 786:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 788:	6398                	ld	a4,0(a5)
 78a:	e118                	sd	a4,0(a0)
 78c:	bff1                	j	768 <malloc+0x88>
  hp->s.size = nu;
 78e:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 792:	0541                	addi	a0,a0,16
 794:	00000097          	auipc	ra,0x0
 798:	eca080e7          	jalr	-310(ra) # 65e <free>
  return freep;
 79c:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7a0:	d971                	beqz	a0,774 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7a2:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7a4:	4798                	lw	a4,8(a5)
 7a6:	fa9775e3          	bgeu	a4,s1,750 <malloc+0x70>
    if(p == freep)
 7aa:	00093703          	ld	a4,0(s2)
 7ae:	853e                	mv	a0,a5
 7b0:	fef719e3          	bne	a4,a5,7a2 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 7b4:	8552                	mv	a0,s4
 7b6:	00000097          	auipc	ra,0x0
 7ba:	b72080e7          	jalr	-1166(ra) # 328 <sbrk>
  if(p == (char*)-1)
 7be:	fd5518e3          	bne	a0,s5,78e <malloc+0xae>
        return 0;
 7c2:	4501                	li	a0,0
 7c4:	bf45                	j	774 <malloc+0x94>
