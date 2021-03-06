#pragma once
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

struct Memory {
  uint8_t *bytecode;
  size_t bytecode_sz;
  struct OperationBundle *bundle;
};


struct OperationInterior {
  uint8_t otype;
  uint8_t obyte;
};

struct OperationBundle {
  struct OperationInterior *oper_1;
  struct OperationInterior *oper_2;
  struct OperationInterior *oper_3;
};

void bytecodeAlloc(void);

void addOper2Bundle(uint8_t otype, uint8_t obyte);
struct OperationBundle *createBundle(void);
void storeBundle(void);
void deleteBundle(struct OperationBundle *bundle);

void movetrfl_reg_(uint8_t reg, bool *idx, bool *treg, bool *buf);



