
#include "stickyasm.h"
#include "stickycode.h"
#include "stickyinstr.h"

// -------------------------
// instruction implementaton
// -------------------------

void loadstore_(uint8_t tag, uint8_t byte, char name[]) {
  if (tag > 3) {
    printf("Warning<%s>: Tag (%u) is too big and will by aligned.\n", name, 
      (uint32_t)tag);
  }
  byte |= ((tag & 0x3) << 1);

  addOper2Bundle(0, byte);
}

void pushoper_(uint8_t type, uint8_t byte) {
  addOper2Bundle(type, byte);
}

void flush_(uint8_t flags, char name[]) {
  flags |= 0b01000000;
  if ((flags & 0b00100011) != 0) {
    printf("Warning<%s>: Operation got undefined flags: %x\n", 
        name, (uint32_t)(flags & 0x3f));
  } 

  addOper2Bundle(0, flags);
}

void jumptrfl_(int8_t pos, uint8_t byte, char name[]) {
  if (((pos & 0xf8) != 0) || ((pos & 0xf8) != 0xf8)) {
    printf("Warning<%s>: Argument (%i) is too big and will by aligned.\n", 
        name, (int32_t)pos);
  }
  
  if (pos < 0) {
    byte |= 0b00100000;
  }

  byte |= ((pos & 0x7) << 2);

  addOper2Bundle(0, byte);
}

void loadeffectiveaddress_(
      uint8_t arg1, uint8_t arg2, uint8_t byte, char name[]) {
  if ((arg1 & 0xf8) == 0x40) { // inc/dec
    byte |= ((arg1 & 0x3) << 5);
    if ((arg2 & 0xf8) == 0x20) { // idx
      byte |= ((byte & 0x3) << 1);
    }
    else {
      printf("Error<%s>: Second argument must by IDX.\n", name);
      exit(2);
    }
  }
  else { // address: treg + idx
    if ((arg1 & 0xf8) == 0x10) { // treg
      byte |= ((arg1 & 0x3) << 3);
      byte |= 0b10100000;
    }
    else if (arg1 != 0xff) { // non zero
      printf("Error<%s>: First argument must by TREG.\n", name);
      exit(2);
    }

    if ((arg2 & 0xf8) == 0x20) { // idx
      byte |= ((arg2 & 0x3) << 1);
      byte |= 0b11000000;
    }
    else if (arg2 != 0xff) { // non zero
      printf("Error<%s>: Second argument must by IDX.\n", name);
      exit(2);
    }
  }

  addOper2Bundle(1, byte);
}

void fcalu_(uint8_t flag, uint8_t cy_mode, uint8_t byte, char name[]) {
  if ((flag & 0xf8) != 0x30) { // flag check
    printf("Error<%s>: Wrong argument was given in flag parameter.\n", name);
    exit(2);
  }
  else {
    byte |= ((flag & 0x7) << 5);
  }

  switch (cy_mode) {
    case 0x30: break;
    case 0x39: byte |= 0b00001000; break;
    case 0x3a: byte |= 0b00010000; break;
    case 0x3b: byte |= 0b00011000; break;
    default:
      printf("Error<%s>: Wrong argument has given in cy_mode parameter.\n", name);
      exit(2);    
  }

  addOper2Bundle(2, byte);
}

void opalu_(uint8_t arg1, uint8_t arg2, uint8_t byte, char name[]) {
  if ((arg1 & 0xf8) != 0x10) {
    printf("Error<%s>: First argument must by TREG.\n", name);
    exit(2);
  }

  if ((arg2 & 0xf8) != 0x10) {
    printf("Error<%s>: Second argument must by TREG.\n", name);
    exit(2);
  }

  byte |= (((arg1 & 0x3) << 3) | ((arg2 & 0x3) << 1));

  addOper2Bundle(3, byte);  
}

void movetrfl_(uint8_t arg1, uint8_t arg2, uint8_t byte, char name[]) {
  bool idx1 = false, treg1 = false, buf1 = false,
       idx2 = false, treg2 = false, buf2 = false;

  movetrfl_reg_(arg1, &idx1, &treg1, &buf1);
  movetrfl_reg_(arg2, &idx2, &treg2, &buf2);

  if (idx1) {
    if (treg2) {
      byte |= ( ((arg1 & 0x3) << 6) | ((arg2 & 0x3) << 3) | 0b00100100 );
    }
    else if (buf2) {
      byte |= ( ((arg1 & 0x3) << 3) | ((arg2 & 0x1) << 6) | 0b10000000 );
    }
    else {
      goto arg_error;
    }
  }
  else if (treg1) {
    if (idx2) {
      byte |= ( ((arg2 & 0x3) << 6) | ((arg1 & 0x3) << 3) | 0b00000100 );
    }
    else if (buf2) {
      byte |= ( ((arg1 & 0x3) << 3) | ((arg2 & 0x1) << 6) );
    }
    else {
      goto arg_error;
    }

    if ((arg1 & 0x3) == 3) {
      printf("Warning<%s>: Cannot use ACC as destination argument. "
             "Operation will be code, but processor may throw an exception...\n",
             name);
    } 
  }
  else if (buf1) {
    if (idx2) {
      byte |= ( ((arg2 & 0x3) << 3) | ((arg1 & 0x1) << 6) | 0b11100000 );
    }
    else if (treg2) {
      byte |= ( ((arg2 & 0x3) << 3) | ((arg1 & 0x1) << 6) | 0b01100000 );
    }
    else {
      goto arg_error;
    }
  }
  else {
    goto arg_error;
  }

  addOper2Bundle(6, byte);
  return;

  arg_error:
  printf("Error<%s>: Wrong argument has given.\n", name);
  exit(2);    
}

void movetrfl_reg_(uint8_t reg, bool *idx, bool *treg, bool *buf) {
  if ((reg & 0xf8) == 0x10) *treg = true;
  else if ((reg & 0xfc) == 0x20) *idx = true;
  else if ((reg & 0xfe) == 0x1e) *buf = true;
}

void movereg(uint8_t arg1, uint8_t arg2, char name[]) {
  uint8_t byte = 0;
  if ((arg1 & 0xf8) == 0x10) {
    if ((arg2 & 0xf8) == 0x50) {
      byte |= ( ((arg1 & 0x3) << 3) | (arg2 & 0x7) | 0b00100000 ); 
    }
    else {
      goto arg_error;
    }

    if ((arg1 & 0x3) == 3) {
      printf("Warning<%s>: Cannot use ACC as destination argument. "
             "Operation will be code, but processor may throw an exception...\n",
             name);
    } 
  }
  else if ((arg1 & 0xf8) == 0x50) {
    if ((arg1 & 0xf8) == 0x10) {
      byte |= ( (arg1 & 0x7) | ((arg2 & 0x3) << 3) );
    }
    else {
      goto arg_error;
    }
  }
  else {
    goto arg_error;
  }

  addOper2Bundle(7, byte);
  return;

  arg_error:
  printf("Error<%s>: Wrong argument has given.\n", name);
  exit(2);
}

// --------------------------------

struct Memory mem = { NULL, 0, NULL };

// memory alloc for bytecode
void bytecodeAlloc(void) {
  uint8_t *tmp_bytecode;
  size_t tmp_sz = mem.bytecode_sz + 4;
  if (mem.bytecode == NULL) {
    tmp_bytecode = (uint8_t*)malloc(4 * sizeof(uint8_t));
  } 
  else {
    tmp_bytecode = (uint8_t*)realloc(mem.bytecode, sizeof(uint8_t) * tmp_sz);
  }

  if (tmp_bytecode == NULL) {
    puts("Memory Error!\n");
    exit(1);
  } 
  else {
    mem.bytecode = tmp_bytecode;
    mem.bytecode_sz = tmp_sz;
    return;
  }
}

// add operation to bundle
void addOper2Bundle(uint8_t otype, uint8_t obyte) {
  printf("-> type: %x | byte: %x\n", (uint32_t)otype, (uint32_t)obyte);
  struct OperationInterior *oper_ptr = malloc(sizeof(struct OperationInterior));
  if (oper_ptr == NULL) {
    puts("Memory Error!\n");
    exit(1);
  }

  oper_ptr->otype = otype;
  oper_ptr->obyte = obyte;

  if (mem.bundle == NULL) {
    mem.bundle = createBundle();
  }

  if (mem.bundle->oper_1 == NULL) {
    mem.bundle->oper_1 = oper_ptr;
  }
  else if (mem.bundle->oper_2 == NULL) {
    mem.bundle->oper_2 = oper_ptr;
  }
  else if (mem.bundle->oper_3 == NULL) {
    mem.bundle->oper_3 = oper_ptr;
  }
  else {
    storeBundle();
    deleteBundle(mem.bundle);
    mem.bundle = createBundle();
    mem.bundle->oper_1 = oper_ptr;
  }  
}

// create operation bundle
struct OperationBundle *createBundle(void) {
  struct OperationBundle *new_bundle = malloc(sizeof(struct OperationBundle));
  if (new_bundle == NULL) {
    puts("Memory Error!\n");
    exit(1);
  }

  new_bundle->oper_1 = NULL;
  new_bundle->oper_2 = NULL;
  new_bundle->oper_3 = NULL;

  return new_bundle;
}

// assemble and store bundle
void storeBundle(void) {
  uint8_t otype_1 = 0, otype_2 = 0, otype_3 = 0, 
          obyte_1 = 0, obyte_2 = 0, obyte_3 = 0;

  if (mem.bundle->oper_1 != NULL) {
    otype_1 = mem.bundle->oper_1->otype;
    obyte_1 = mem.bundle->oper_1->obyte;
  }

  if (mem.bundle->oper_2 != NULL) {
    otype_2 = mem.bundle->oper_2->otype;
    obyte_2 = mem.bundle->oper_2->obyte;
  }

  if (mem.bundle->oper_3 != NULL) {
    otype_3 = mem.bundle->oper_3->otype;
    obyte_3 = mem.bundle->oper_3->obyte;
  }

  uint8_t opcode_byte = 
      ((otype_1 & 0x7) << 5) | ((otype_2 & 0x7) << 2) | (otype_3 & 0x3);

  printf("1: %x 2: %x 3: %x 4: %x\n\n", (uint32_t)opcode_byte, (uint32_t)obyte_1, 
    (uint32_t)obyte_2, (uint32_t)obyte_3);

  mem.bytecode[mem.bytecode_sz - 1] = obyte_3;
  mem.bytecode[mem.bytecode_sz - 2] = obyte_2;
  mem.bytecode[mem.bytecode_sz - 3] = obyte_1;
  mem.bytecode[mem.bytecode_sz - 4] = opcode_byte;

  bytecodeAlloc();

}

// delated operation bundle
void deleteBundle(struct OperationBundle *bundle) {
  if (bundle->oper_1 != NULL) free(bundle->oper_1);
  if (bundle->oper_2 != NULL) free(bundle->oper_2);
  if (bundle->oper_3 != NULL) free(bundle->oper_3);
  free(bundle);
} 


int main(int argc, char *argv[]) {
  if (argc != 2) {
    return 3;
  }

  // create main bytecode array
  bytecodeAlloc();

  // call program code
  code();

  if (mem.bundle == NULL) {
    puts("code() is empty. No binary file generated.\n");
    return 0;
  }
  storeBundle();

  // write bytecode to file
  FILE *f;
  f = fopen(argv[1], "wb");
  if (!f) {
    return 3;
  }

  fwrite(mem.bytecode, 1, mem.bytecode_sz - 4, f);

  fclose(f);
  return 0;

}