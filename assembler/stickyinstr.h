#pragma once
#include <stdint.h>

// TREGs
#define v0  0x10
#define v1  0x11
#define v2  0x12
#define acc 0x13
#define ab  0x1e
#define db  0x1f

// IDX regs
#define ix 0x20
#define iy 0x21
#define sp 0x22
#define pc 0x23

// flags, cy
#define carry     0x30
#define sign      0x31
#define overflow  0x32
#define zero      0x33
#define halfcarry 0x34
#define less      0x35
#define leq       0x36
#define beq       0x37

#define non   0x30
#define cmccy 0x39
#define clccy 0x3a
#define setcy 0x3b

// lea mode
#define inc1 0x40
#define inc2 0x41
#define dec1 0x42
#define dec2 0x43

// GPRs
#define r0 0x50
#define r1 0x51
#define r2 0x52
#define r3 0x53
#define r4 0x54
#define r5 0x55
#define r6 0x56
#define r7 0x57

#define zptr 0xff

// auxiliary instr functions
void loadstore_(uint8_t tag, uint8_t byte, char name[]);
void jumptrfl_(int8_t pos, uint8_t byte, char name[]);
void flush_(uint8_t flags, char name[]);
void loadeffectiveaddress_(uint8_t arg1, uint8_t arg2, uint8_t byte, 
    char name[]);
void fcalu_(uint8_t flag, uint8_t cy_mode, uint8_t byte, char name[]);
void opalu_(uint8_t arg1, uint8_t arg2, uint8_t byte, char name[]);
void movetrfl_(uint8_t arg1, uint8_t arg2, uint8_t byte, char name[]);

void pushoper_(uint8_t type, uint8_t bytes);

// X TYPE (MISC, SYSTEM, CONTROL INSTRUCTIONS)
//
// LOADW/LOADB - load data from memory from AB address to DB register
#define loadw(tag) loadstore_(tag, 0b11000000, "loadw");
#define loadb(tag) loadstore_(tag, 0b11000001, "loadb");
// STOREW/STOREB - store data from DB register to memory in AB address
#define storew(tag) loadstore_(tag, 0b11100000, "storew");
#define storeb(tag) loadstore_(tag, 0b11100001, "storeb");
// PINW/PINB - read from a port
#define pinw() pushoper_(0, 0b11010000);
#define pinb() pushoper_(0, 0b11010001);
// POUTW/POUTB - write to a port
#define poutw() pushoper_(0, 0b11110000);
#define poutb() pushoper_(0, 0b11110001);
// FLUSH - flush of a processor state 
#define flush(flags) flush_(flags, "flush");
// JUMP/BRTR/BRFL - short quick jump unconditional or conditional
#define jump(pos) jumptrfl_(pos, 0, "jump");
#define brtr(pos) jumptrfl_(pos, 1, "brtr");
#define brfl(pos) jumptrfl_(pos, 3, "brfl");

// L TYPE (LEA INSTRUCTIONS)
//
// LEA - load effective address and write it in AB register
#define lea(arg1, arg2) loadeffectiveaddress_(arg1, arg2, 0, "lea");
// LEAX - load effective address and write it in AB register and write in used 
//        index register
#define leax(arg1, arg2) loadeffectiveaddress_(arg1, arg2, 1, "leax");

// F TYPE (CONTROL ALU FLAGS INSTRUCTIONS)
//
// FAW/FAB - set flag to branch signal, set carry register and set alu 
//           operations bitness
#define faw(flag, cy_mode) fcalu_(flag, cy_mode, 2);
#define fab(flag, cy_mode) fcalu_(flag, cy_mode, 3);
// NAW/NAB - set carry register, set alu operations bitness, but not change 
//           branch signal
#define naw(cy_mode) fcalu_(0x30, cy_mode, 0);
#define nab(cy_mode) fcalu_(0x30, cy_mode, 1);

// A TYPE (ALU INSTRUCTIONS)
//
// ADD - add
#define add(arg1, arg2) opalu_(arg1, arg2, 0b00000000, "add");
// ADC - add with carry
#define adc(arg1, arg2) opalu_(arg1, arg2, 0b00000001, "adc");
// SUB - subtract
#define sub(arg1, arg2) opalu_(arg1, arg2, 0b00100000), "sub"; 
// SBC - subtract with carry
#define sbc(arg1, arg2) opalu_(arg1, arg2, 0b00100001, "sbc");
// BXOR - logical xor
#define bxor(arg1, arg2) opalu_(arg1, arg2, 0b01000000, "bxor");
// BAND - logical and
#define band(arg1, arg2) opalu_(arg1, arg2, 0b01000001, "band");
// BOR - logical or
#define bor(arg1, arg2) opalu_(arg1, arg2, 0b01100000, "bor");
// BNOR - logical nor
#define bnor(arg1, arg2) opalu_(arg1, arg2, 0b01100001, "bnor");
// SLL - shift logical left
#define sll(arg1) opalu_(arg1, 0x10, 0b10000000, "sll");
// SLR - shift logical right
#define slr(arg1) opalu_(arg1, 0x10, 0b10000001, "slr");
// SAL - (alias; shift logical left)
#define sal(arg1) opalu_(arg1, 0x10, 0b10000000, "sal");
// SAR - shift arithmetic right 
#define sar(arg1) opalu_(arg1, 0x10, 0b10000011, "sar");
// ROL - rotate left
#define rol(arg1) opalu_(arg1, 0x10, 0b10000100, "rol");
// ROR - rotate right
#define ror(arg1) opalu_(arg1, 0x10, 0b10000101, "ror");
// RCL - rotate through carry left
#define rcl(arg1) opalu_(arg1, 0x10, 0b10000110, "rcl");
// RCR - rotate through carry right
#define rcr(arg1) opalu_(arg1, 0x10, 0b10000111, "rcr");

// I TYPE (IMMEDIATE VALUE)
//
// VALV0 - write 8-bit immediate value to t-reg; V0. If first in instruction 
//         bundle, writes to high-half v0, else; low-half v0
#define valv0(value) pushoper_(4, value);
// VALV1 - write 8-bit immediate value to t-reg; V1. If first in instruction 
//         bundle, writes to high-half v1, else; low-half v1
#define valv1(value) pushoper_(5, value);

// T TYPE (TEMP REGISTER TRANSFER INSTRUCTIONS)
//
// MOVE/MOVETR/MOVEFL - move data between temporary registers or index 
//                      registers. unconditional or conditional
#define move(arg1, arg2) movetrfl_(arg1, arg2, 0 , "move");
#define mvtr(arg1, arg2) movetrfl_(arg1, arg2, 1 , "mvtr");
#define mvfl(arg1, arg2) movetrfl_(arg1, arg2, 3 , "mvfl");

// R TYPE (REGISTER TRANSFER INSTRUCTION)
// 
// MOVR - move data between general purpose register and t-regs
#define movr(arg1, arg2) movereg_(arg1, arg2, "movr");

// PSEUDO INSTRUCTIONS

