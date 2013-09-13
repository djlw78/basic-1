#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdint.h>

#define SYM 1
#define NUM 2
#define STR 3
#define CHR 4
#define FUN 5
#define VAL(a,b,c) (val){a,b,c}
#define NVAL VAL(0,0,0)
#define ENT(a,b) (ent){a,b}

typedef struct { int t; int h; int l; } val;
typedef struct { int k; val v; } ent;
typedef struct { int s; ent t[256]; } tab;
typedef void(*F)(char **);
int mnt(char **s);
val gnt(char **s);
val gs(char **s);
void tput(tab *t, int k, val v);
val tget(tab *t, int k);
int hash(char **s);
int hashs(char *s);
void Print(char **s);

char buf[256];
tab st;

int main() {
 printf("BASIC3\n\n");
 tput(&st, hashs("print"), VAL(FUN, 0, (int)Print));
 while (1) {
  printf(">");
  fflush(stdout);
  fgets(buf, 256, stdin);
  char *s = buf;
  val v;
  while ((v = gnt(&s)).t != 0) {
   printf("%d %d %d\n", v.t, v.h, v.l);
   if (v.t == SYM) {
    val v2 = tget(&st, v.l);
    printf("=> %d %d %d\n", v2.t, v2.h, v2.l);
    if (v2.t == FUN) {
     F f = (F) v2.l;
     f(&s);
    }
   }
  }
 }
 return 0;
}

void Print(char **s) {
  printf("PRINT\n");
}

val gnt(char **s) {
 // (NUM,n) (SYM,h) (CHR,c) (STRL,s,e)
 int t = mnt(s);
 switch (t) {
  case SYM: return VAL(SYM, 0, hash(s));
  case NUM: return VAL(NUM, 0, strtol(*s, s, 10));
  case CHR: return VAL(CHR, 0, *(*s)++);
  case STR: return gs(s);
  default: return NVAL;
 }
}

int hashs(char *s) {
 return hash(&s);
}

int hash(char **s) {
 uint32_t h = 0;
 while (isalpha(**s)) {
  h = ((h << 7) | **s) | (h >> 25);
  (*s)++;
 }
 return h;
}

val gs(char **s) {
 char *s1 = *s++;
 int l = 0;
 while (**s != '"') {
  if (**s == 0)
    return NVAL;
  l++;
 }
 return VAL(STR, (int) s1, l);
}

int mnt(char **s) {
while (isspace(**s))
  (*s)++;
if (**s == 0)
  return 0;
if (**s == '"')
  return STR;
if (**s >= '0' && **s <= '9')
  return NUM;
if (**s >= 'a' && **s <= 'z')
  return SYM;
return CHR;
}

int cmp1(int *k, ent *e) {
 return (*k) - e->k;
}

int cmp(const void *k, const void *e) {
 int *k2 = (int *) k;
 ent *e2 = (ent *) e;
 return (*k2) - e2->k;
}

ent *tfind(tab *t, int k) {
 return bsearch(&k, &t->t, t->s, sizeof (ent), cmp);
}

val tget(tab *t, int k) {
 ent *e = tfind(t, k);
 return e ? e->v : NVAL;
}

void tput(tab *t, int k, val v) {
 ent *e = tfind(t, k);
 if (e) {
  e->v = v;
 } else if (t->s >= 256) {
  printf("so\n");
  exit(EXIT_FAILURE);
 } else {
  t->t[t->s++] = ENT(k, v);
  qsort(&t->t, t->s, sizeof (ent), cmp);
 }
}

