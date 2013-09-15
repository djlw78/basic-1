#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdint.h>
#include <inttypes.h>
#include <string.h>
#include <stddef.h>

#define SYM 1
#define INT 2
#define STR 3
#define CHR 4
#define FUN 5
#define TSTR 6
#define STRL 7
#define LZ 0xffff0000

typedef uint32_t hash_t;
typedef struct { char c; } cval;
typedef struct { int64_t i; } ival;
typedef struct { double d; } dval;
typedef struct { char *s; } sval;
typedef struct { void (*f)(char **); } fval;
typedef struct { hash_t h; } hval;
typedef union { ival iv; dval dv; sval sv; fval fv; hval hv; cval cv; } uval;
typedef struct { int t; uval uv; } val;
typedef struct { hash_t k; val v; } ent;
typedef struct { size_t s; ent t[256]; } tab;

val chrv (char c) {
 val v; v.t = CHR; v.uv.cv.c = c; return v;
}

val funv (void (*f)(char **)) {
 val v; v.t = FUN; v.uv.fv.f = f; return v;
}

val nulv () {
 val v; v.t = 0; return v;
}

val strv (int t, char *s) {
 val v; v.t = t; v.uv.sv.s = s; return v;
}

val intv (int64_t i) {
 val v; v.t = INT; v.uv.iv.i = i; return v;
}

val hashv (hash_t h) {
 val v; v.t = SYM; v.uv.hv.h = h; return v;
}

int mnt (char **);
val gnt (char **);
val gs (char **);
void tput (tab *, hash_t, val);
val tget (tab *, hash_t);
hash_t hash (char **);
hash_t hashs (char *);
val intop (val, val, char);
val strop (sval, val, char);
val gne (char **);
val gnv (char **);
void setl (int64_t, char *);
ent *tfind (tab *, hash_t);
void ex (char *);
void del (val);

void Print (char **);
void Let (char **);
void List (char **);
void Goto (char **);
void End (char **);
void Run (char **);

char buf[256];
tab st;
char heap[65536];
size_t hp;
char *ops = "+-*/|&%^=<>";
int mc = 0;
int li;

int main () {
 printf("BASIC3\n\n");
 tput(&st, hashs("print"), funv(Print));
 tput(&st, hashs("let"), funv(Let));
 tput(&st, hashs("list"), funv(List));
 tput(&st, hashs("end"), funv(End));
 tput(&st, hashs("run"), funv(Run));
 tput(&st, hashs("goto"), funv(Goto));
 tput(&st, LZ, strv(STRL, NULL));
 hp = 0;
 while (1) {
  if (mc != 0)
   printf("%d",mc);
  printf(">");
  fflush(stdout);
  fgets(buf, 256, stdin);
  int l = strlen(buf);
  buf[l - 1] = 0;
  char *s = buf;
  ex(s);
 }
 return 0;
}

void ex (char *s) {
 char *s2 = s;
 val v = gnt(&s);
 if (v.t == SYM) {
  val v2 = tget(&st, v.uv.hv.h);
  if (v2.t == FUN) {
   v2.uv.fv.f(&s);
  } else {
   Let(&s2);
  }
 } else if (v.t == INT) {
  setl(v.uv.iv.i, s);
 }
}

void setl (int64_t l, char *s) {
 if (l <= 0 || l >= LZ) {
  printf("invalid line\n");
  return;
 }
 int t = mnt(&s);
 if (t != 0) {
  hash_t h = LZ | (hash_t) l;
  int l = strlen(s);
  char *s2 = memcpy(malloc(l + 1), s, l);
  mc++;
  s2[l] = 0;
  tput(&st, h, strv(STRL, s2));
 } else {
  // remove 
 }
}

void end() {
 End(NULL);
}

void End (char **s) {
 li = st.s;
}

void Goto (char **s) {
 val v = gne(s);
 if (v.t != INT) {
  printf("goto: bad exp\n");
  end();
  return;
 }
 hash_t h = LZ | (hash_t) v.uv.iv.i;
 ent *e = tfind(&st, h);
 if (!e) {
  printf("goto: bad line\n");
  end();
 }
 li = e - &st.t[0];
}

void Run (char **s) {
 ent *e1 = tfind(&st, LZ);
 li = e1 - &st.t[0];
 while (li < st.s) {
  ent e = st.t[li++];
  if (e.v.t == STRL && e.v.uv.sv.s != NULL) {
   printf("%-4d %s\n", e.k & ~LZ, e.v.uv.sv.s);
   ex(e.v.uv.sv.s);
  }
 }
}

void List (char **s) {
 ent *e1 = tfind(&st, LZ);
 int i = e1 - &st.t[0];
 while (i < st.s) {
  ent e = st.t[i];
  if (e.v.t == STRL && e.v.uv.sv.s != NULL) {
   printf("%-4d %s\n", e.k & ~LZ, e.v.uv.sv.s);
  }
  i++;
 }
}

void Let (char **s) {
 val v = gnt(s);
 if (v.t != SYM) {
  printf("let: symbol expected\n");
  end();
  return;
 }
 val v2 = gnt(s);
 if (v2.t != CHR || v2.uv.cv.c != '=') {
  printf("let: assignment expected\n");
  end();
  return;
 }
 val v3 = gne(s);
 if (v3.t == 0) {
  printf("let: expression expected\n");
  end();
  return;
 }
 if (v3.t == TSTR) {
  v3.t = STR;
 }
 tput(&st, v.uv.hv.h, v3);
}

void Print (char **s) {
 val v;
 while ((v = gne(s)).t != 0) {
  switch (v.t) {
   case INT: printf("%" PRId64 " ", v.uv.iv.i); break;
   case TSTR:
   case STR: printf("%s ", v.uv.sv.s); break;
   case FUN: printf("%p ", v.uv.fv.f); break;
   default: printf("<%d> ", v.t);
  }
  del(v);
 }
 printf("\n");
}

val gne (char **s) {
 // exp = val [chr exp]
 val v = gnv(s);
 if (v.t == 0)
  return v;
 int t = mnt(s);
 if (t != CHR)
  return v;
 char *s2 = *s;
 val c = gnt(s);
 if (!strchr(ops, c.uv.cv.c)) {
  *s = s2;
  return v;
 }
 val v2 = gne(s);
 if (v2.t == 0) {
  printf("gne: bad exp\n");
  end();
  del(v);
  return nulv();
 }
 val r;
 if (v.t == INT && v2.t == INT) {
  r = intop(v, v2, c.uv.cv.c);
 } else if ((v.t == STR || v.t == TSTR)) {
  r = strop(v.uv.sv, v2, c.uv.cv.c);
 } else {
  printf("gne: bad types in exp\n");
  end();
  r = nulv();
 }
 del(v);
 del(v2);
 return r;
}

val strop (sval sv1, val v2, char c) {
 if ((v2.t == STR || v2.t == TSTR)) {
  if (c == '+') {
   int l1 = strlen(sv1.s);
   int l2 = strlen(v2.uv.sv.s);
   char *s = memcpy(malloc(l1 + l2 + 1), sv1.s, l1);
   mc++;
   memcpy(s + l1, v2.uv.sv.s, l2);
   s[l1 + l2] = 0;
   return strv(TSTR, s);
  } else {
   printf("unknown str-str op %c\n", c);
   end();
  }
 } else if (v2.t == INT) {
  if (c == '*') {
   int i = (int) v2.uv.iv.i;
   if (i > 0 && i <= 10000) {
    int l = strlen(sv1.s);
    char *s = malloc((l * i) + 1);
    mc++;
    for (int n = 0; n < i; n++)
     memcpy(s + (l * n), sv1.s, l);
    s[(l * i) + 1] = 0;
    return strv(TSTR, s);
   } else {
    printf("invalid str multiplicand %d\n", i);
    end();
   }
  } else {
   printf("invalid str-int op %c\n", c);
   end();
  }
 }
 return nulv();
}

val intop (val v1, val v2, char c) {
 int64_t i1 = v1.uv.iv.i;
 int64_t i2 = v2.uv.iv.i;
 int64_t i;
 switch (c) {
  case '+': i = i1 + i2; break;
  case '-': i = i1 - i2; break;
  case '*': i = i1 * i2; break;
  case '/': i = i1 / i2; break;
  case '|': i = i1 | i2; break;
  case '&': i = i1 & i2; break;
  case '%': i = i1 % i2; break;
  case '^': i = i1 ^ i2; break;
  case '=': i = i1 == i2; break;
  case '>': i = i1 > i2; break;
  case '<': i = i1 < i2; break;
  default: printf("unknown int op %c\n", c); end(); return nulv();
 }
 return intv(i);
}

val gnv (char **s) {
 // val = int | str | sym | (exp) | sym (exp)
 val v = gnt(s);
 switch (v.t) {
  case 0:
  case INT:
  case TSTR:
  case STR: return v;
  case SYM: return tget(&st, v.uv.hv.h);
  case CHR: {
   if (v.uv.cv.c != '(') {
    printf("gnv: unexpected character %c\n", v.uv.cv.c);
    end();
    return nulv();
   }
   val v2 = gne(s);
   if (v2.t == 0) {
    printf("gnv: missing expression\n");
    end();
    return nulv();
   }
   val v3 = gnt(s);
   if (v3.uv.cv.c != ')') {
    printf("gnv: missing bracket\n");
    end();
    del(v2);
    return nulv();
   }
   return v2;
  }
 }
 printf("gnv: unknown type %d\n", v.t);
 end();
 return nulv();
}

val gnt (char **s) {
 int t = mnt(s);
 switch (t) {
  case SYM: return hashv(hash(s));
  case INT: return intv(strtol(*s, s, 10));
  case CHR: return chrv(*(*s)++);
  case STR: return gs(s);
  default: return nulv();
 }
}

hash_t hashs (char *s) {
 return hash(&s);
}

hash_t hash (char **s) {
 hash_t h = 0;
 char c;
 while (isalnum(c = *(*s)++)) {
  h = ((h << 7) | c) | (h >> 25);
 }
 return h;
}

void del (val v) {
 if (v.t == TSTR) {
  free(v.uv.sv.s);
  mc--;
 }
}

val gs (char **s) {
 char *s1 = ++(*s);
 size_t l = 0;
 char c;
 while ((c = *(*s)++)) {
  if (c == '"') {
   char *s2 = memcpy(malloc(l + 1), s1, l);
   mc++;
   s2[l] = 0;
   return strv(TSTR, s2);
  }
  l++;
 }
 return nulv();
}

int mnt (char **s) {
 char c;
 while (isspace(c = **s)) {
  s[0]++;
 }
 if (c == 0)
  return 0;
 if (c == '"')
  return STR;
 if (isdigit(c))
  return INT;
 if (isalpha(c))
  return SYM;
 return CHR;
}

int cmp (const void *kp, const void *ep) {
 hash_t k = * (hash_t *) kp;
 ent e = * (ent *) ep;
 int c = k > e.k ? 1 : k == e.k ? 0 : -1;
 return c;
}

ent *tfind (tab *t, hash_t k) {
 return bsearch(&k, &t->t, t->s, sizeof (ent), cmp);
}

val tget (tab *t, hash_t k) {
 ent *e = tfind(t, k);
 return e ? e->v : nulv();
}

void tput (tab *t, hash_t k, val v) {
 ent *e = tfind(t, k);
 if (e) {
  val vo = e->v;
  if (vo.t == STR || vo.t == STRL) {
   vo.t = TSTR;
   del(vo);
  }
  e->v = v;
 } else if (t->s >= 256) {
  printf("table overflow\n");
  exit(EXIT_FAILURE);
 } else {
  ent e;
  e.k = k;
  e.v = v;
  t->t[t->s++] = e;
  qsort(&t->t, t->s, sizeof (ent), cmp);
 }
}

