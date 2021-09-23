# sticky.arch

Projekt sticky.arch zakłada stworzenie procesora sticky.arch wraz z środowiskiem wykonywalnym.
Elementy projektu znajdują się na FPGA, Arduino oraz na PC. Są nimi:
- FPGA:
  1. CPU
  2. IO controller 

- Arduino:
  1. Cache
  
- PC:
  1. RAM
  2. Urządzenia podpięte do RAMu (np. prosty wyświetlacz tekstowy; klawiatura)
  
## Procesor sticky.arch

Pierwsze prace nad procesorem ogólnego przeznaczenia zaczeły się pod koniec 2020r, kiedy zaznajomiłem się z projektem [Mill Architecture](https://millcomputing.com/). 
Zainspirowany tymi pomysłami, zacząłem według nich projektować swoją konstrukcje.
Jednak podczas tworzenia kolejnych aspektów cpu, co raz bardziej rezygnowałem z pierwotnych założeń. Zastępywałem je innymi pomysłami.<br>
Drugą inspiracją był [microcode 8086](https://www.reenigne.org/blog/8086-microcode-disassembled/). 
A konkretniej: gdyby microcode był natywnym kodem maszynowym procesora, nie musiał by mieć dekodera.
Czy to założenie udało się spełnić? Z dzisiejszej perspektywy mogę powiedzieć, że nie...
Natomiast takie (często bardzo wewnętrzne i proste) instrukcje trzeba jakoś zakodować. 
Dlatego trzecią inspiracją był sposób kodowania instrukcji Intel Itanium. Lecz z tych pomysłów, po wielu zmianach i uproszczeniach nie wiele zostało.

Dzisiejsze założenia cpu:
- 16-bit
- ISA: sticky.arch
- model ISA: RISC (Reduce Instruction Set Computing) / VLIW (Very Long Instruction Word)
- Jeden Rdzeń 
- Jedno ALU
- 16-bitowa szyna Danych
- 24-bitowa szyna adresowa (gdzie górne 8bit to segment)
- 2-krokowy pipelining: FETCH -> EXECUTE (lecz pobieranie następnej instrukcji odbywa się po tym jak obecna się wykona)
- Brak wsparcia dla operacji atomowych
- Przerwania są na papierze, lecz obecnie nie są zaimplementowane

TODO: uzupełnić, operacja, kodowanie instrukcji, rejestry, ogólna wewnętrzna budowa


## IO controller
TODO

## Cache
TODO

## Środowisko na PC
TODO
