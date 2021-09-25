#define HIGH 0x1
#define LOW 0x0

// D11, D10, A5-A0 - to cpu
int data_out_pin[8] = {11, 10, A0, A1, A2, A3, A4, A5}; 
// D0-D7 - from cpu
int data_in_pin[8] = {9, 8, 7, 6, 5, 4, 3, 2};
// D8 - sync_out (to cpu)
int sync_out_pin = 13;
// D9 - sync_in (from cpu)
int sync_in_pin = 12;

// 0B  -  63B | 64B   9b 10b       15b 
// CACHE_LINE | ADDRESS | - A A C D S
// ---64 B--- | --10b-- | ----6 b----
byte cache_line[8][66] = {0};
byte cache_segemnt[3] = {0}; // 0=C; 1=D; 2=S 

int segf2idx(byte seg_flags) {
  switch (seg_flags) {
    case 0b001: return 2;
    case 0b010: return 1;
    default: return 0;
  }
}


void store64(int idx) {
  byte segment = cache_segemnt[segf2idx(cache_line[idx][65] & 0b111)];
  byte header[4] = {segment, cache_line[idx][64], cache_line[idx][65], 1};

  Serial.write(header, 4);
  delayMicroseconds(1000);
  Serial.write(cache_line[idx], 64);
}

void load64(int idx, byte seg_flags, byte segment, word addr) {
  byte header[4] = {0};
  header[0] = segment;
  header[1] = (byte)((addr >> 8) & 0xff);
  header[2] = (byte)(addr & 0xff);

  Serial.write(header, 4);
  cache_line[idx][64] = header[1];
  cache_line[idx][65] = (byte)(addr & 0xc0) | 0x20 | seg_flags;
  while (!Serial.available());
  Serial.readBytes(cache_line[idx], 64);
}


int searchCacheLine(byte seg_flags, byte seg, word addr) {
  if (cache_segemnt[segf2idx(seg_flags)] != seg) {
    return -1;
  }
  
  for (int i = 0; i < 8; i++) {
    if ((cache_line[i][65] & 0b111) == 0) {
      return i;
    }
    else if ((cache_line[i][65] & 0b111) == seg_flags) {
      if ((cache_line[i][64] == (addr >> 8)) &&
          ((cache_line[i][65] & 0xc0) == (addr & 0xc0))) {
        return i;
      }
    }
  }

  return -2;
}

void flushCache(byte seg_flags) {
  for (int i = 0; i < 8; i++) {
    if ((cache_line[i][65] & 0b111) == seg_flags) {
      store64(i);
      cache_line[i][65] = 0;
    }
  }
}

/*
byte bit2analog(byte data, byte pin) {
  if ((data >> pin) & 1) 
    return 255;

  else 
    return 0;
}*/

int getCacheIdx(byte seg_flags, byte segment, word addr) {
  int idx = searchCacheLine(seg_flags, segment, addr);
  byte tmpa = 0xff;
  if (idx < 0) {
    if (idx == -1) {
      flushCache(seg_flags);
    }
    for (int i = 0; i < 8; i++) {
      if (cache_line[i][65] & 0b111 == 0) {
        return i;
      }
      if (cache_line[i][65] & 0b111 == seg_flags) {
        if (cache_line[i][65] & 0b11000 < tmpa) {
          tmpa = cache_line[i][65] & 0b11000;
          idx = i;
        }
      }
    }
    if (tmpa != 0xff) {
      store64(idx);
    }
    load64(idx, seg_flags, segment, addr);
  }

  return idx;
}

void sendByteToCPU(byte data) {
  digitalWrite(data_out_pin[0], (data) & 1);
  digitalWrite(data_out_pin[1], (data >> 1) & 1);
  digitalWrite(data_out_pin[2], (data >> 2) & 1);
  digitalWrite(data_out_pin[3], (data >> 3) & 1);
  digitalWrite(data_out_pin[4], (data >> 4) & 1);
  digitalWrite(data_out_pin[5], (data >> 5) & 1);
  digitalWrite(data_out_pin[6], (data >> 6) & 1);
  digitalWrite(data_out_pin[7], (data >> 7) & 1);
}

byte recvByteFromCPU() {
  byte data = 0;
  data |= digitalRead(data_in_pin[0]);
  data |= digitalRead(data_in_pin[1]) << 1;
  data |= digitalRead(data_in_pin[2]) << 2;
  data |= digitalRead(data_in_pin[3]) << 3;
  data |= digitalRead(data_in_pin[4]) << 4;
  data |= digitalRead(data_in_pin[5]) << 5;
  data |= digitalRead(data_in_pin[6]) << 6;
  data |= digitalRead(data_in_pin[7]) << 7;
  return data;
}

void communication() {
  delay(10000);
  digitalWrite(sync_out_pin, LOW);
  while (digitalRead(sync_in_pin) == LOW);

  delay(1000);
  byte header = recvByteFromCPU(); // recv header | cpu => cache
  digitalWrite(sync_out_pin, HIGH);
  byte seg_flags = header & 0b111;
  if (seg_flags == 0) {
    delay(5000);
  }
  while (digitalRead(sync_in_pin) == HIGH);

  delay(1000);
  byte segment = recvByteFromCPU(); // recv segment | cpu => cache
  digitalWrite(sync_out_pin, LOW);
  while (digitalRead(sync_in_pin) == LOW);

  delay(1000);
  word address = recvByteFromCPU(); // recv addressh | cpu => cache
  digitalWrite(sync_out_pin, HIGH);
  address <<= 8;
  while (digitalRead(sync_in_pin) == HIGH);

  delay(1000);
  address |= recvByteFromCPU(); // recv addressl | cpu => cache

  int idx = getCacheIdx(seg_flags, segment, address);
  cache_segemnt[segf2idx(seg_flags)] = segment;

  int i = 0;
  switch ((header & 0x60) >> 5) {
    case 0b00: i = 2; break; 
    case 0b01: i = 4; break;
    case 0b10: i = 1; break;
    default:   i = 4; break;
  }
  word temp_addr = address;
  bool pin_state = LOW;
  if ((header & 0x80) > 0) { // recv data | cpu => cache
    for (; i != 0; i--) {
      digitalWrite(sync_out_pin, pin_state);
      while (pin_state == digitalRead(sync_in_pin));

      delay(1000);
      cache_line[idx][temp_addr & 0x3f] = recvByteFromCPU();
      pin_state = ~pin_state;
      if (i > 1) {
        temp_addr++;
        if ((address & 0xffc0) != (temp_addr & 0xffc0)) {
          idx = getCacheIdx(seg_flags, segment, temp_addr);
        }
      }
      digitalWrite(sync_out_pin, pin_state);
    }
  }
  else { // send data | cpu <= cache
    for (; i != 0; i--) {
      delay(1000);
      sendByteToCPU(cache_line[idx][temp_addr & 0x3f]);
      digitalWrite(sync_out_pin, pin_state);
      if (i > 1) {
        temp_addr++;
        if (address & 0xffc0 != temp_addr & 0xffc0) {
          idx = getCacheIdx(seg_flags, segment, temp_addr);
        }
      }
      while (pin_state == digitalRead(sync_in_pin));
      pin_state = ~pin_state;
    }
  }

  digitalWrite(sync_out_pin, LOW);

  for (int i = 0; i < 8; i++) {
    if (cache_line[i][65] & 0b111000 != 0) {
      cache_line[i][65] -= 0b1000;
    }
  }
}


void setup() {
  Serial.begin(115200);

  pinMode(data_out_pin[0], OUTPUT);
  pinMode(data_out_pin[1], OUTPUT);
  pinMode(data_out_pin[2], OUTPUT);
  pinMode(data_out_pin[3], OUTPUT);
  pinMode(data_out_pin[4], OUTPUT);
  pinMode(data_out_pin[5], OUTPUT);
  pinMode(data_out_pin[6], OUTPUT);
  pinMode(data_out_pin[7], OUTPUT);

  pinMode(data_in_pin[0], INPUT);
  pinMode(data_in_pin[1], INPUT);
  pinMode(data_in_pin[2], INPUT);
  pinMode(data_in_pin[3], INPUT);
  pinMode(data_in_pin[4], INPUT);
  pinMode(data_in_pin[5], INPUT);
  pinMode(data_in_pin[6], INPUT);
  pinMode(data_in_pin[7], INPUT);

  pinMode(sync_out_pin, OUTPUT);
  pinMode(sync_in_pin, INPUT);
}

void loop() {
  communication();
}
