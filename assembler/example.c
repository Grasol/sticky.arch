#include "stickycode.h"
#include "stickyinstr.h"

void code(void) {
  valv0(0);
  valv0(4);
  move(v1, pc);

  valv0(0);
  valv0(0);
  add(v0, v1);

  move(db, acc);
  add(v0, v1);
  leax(dec2, sp);

  storew(3);
  move(pc, acc);
  flush(0b00011100);
}

