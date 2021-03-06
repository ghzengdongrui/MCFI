// RUN: %clang_cc1 -analyze -analyzer-checker=core -analyzer-config suppress-inlined-defensive-checks=true -verify %s

// Perform inline defensive checks.
void idc(int *p) {
	if (p)
		;
}

int test01(int *p) {
  if (p)
    ;
  return *p; // expected-warning {{Dereference of null pointer}}
}

int test02(int *p, int *x) {
  if (p)
    ;
  idc(p);
	if (x)
		;
  return *p; // expected-warning {{Dereference of null pointer}}
}

int test03(int *p, int *x) {
	idc(p);
	if (p)
		;
	return *p; // False negative
}

int deref04(int *p) {
  return *p; // expected-warning {{Dereference of null pointer}}
}

int test04(int *p) {
  if (p)
    ;
  idc(p);
  return deref04(p);
}

int test11(int *q, int *x) {
	int *p = q;
	if (q)
		;
	if (x)
		;
	return *p; // expected-warning{{Dereference of null pointer}}
}

int test12(int *q) {
	int *p = q;
	idc(q);
	return *p;
}

int test13(int *q) {
	int *p = q;
	idc(p);
	return *p;
}

int test21(int *q, int *x) {
	if (q)
		;
	if (x)
		;
	int *p = q;
	return *p; // expected-warning{{Dereference of null pointer}}
}

int test22(int *q, int *x) {
  idc(q);
	if (x)
		;
	int *p = q;
	return *p;
}

int test23(int *q, int *x) {
  idc(q);
	if (x)
		;
	int *p = q;
  if (!p)
    ;
	return *p; // False negative
}

void use(char *p) {
  if (!p)
    return;
  p[0] = 'a';
}

void test24(char *buffer) {
  use(buffer);
  buffer[1] = 'b';
}

// Ensure idc works on pointers with constant offset.
void idcchar(const char *s2) {
  if(s2)
    ;
}
void testConstantOffset(char *value) {
  char *cursor = value + 5;
  idcchar(cursor);
  if (*cursor) {
    cursor++;
  }
}

// Ensure idc works for integer zero values (ex: suppressed div by zero).
void idcZero(int assume) {
  if (assume)
    ;
}

int idcTriggerZeroValue(int m) {
  idcZero(m);
  return 5/m; // no-warning
}

int idcTriggerZeroValueThroughCall(int i) {
  return 5/i; // no-warning
}
void idcTrackZeroValueThroughCall(int x) {
  idcZero(x);
  idcTriggerZeroValueThroughCall(x);
}

int idcTriggerZeroThroughDoubleAssignemnt(int i) {
  return 5/i; // no-warning
}
void idcTrackZeroThroughDoubleAssignemnt(int x) {
  idcZero(x);
  int y = x;
  int z = y;
  idcTriggerZeroValueThroughCall(z);
}
