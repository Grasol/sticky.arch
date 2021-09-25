# sticky.arch

Projekt sticky.arch zakłada stworzenie procesora sticky.arch wraz z środowiskiem wykonywalnym.
Elementy projektu znajdują się na FPGA, Arduino oraz na PC. Są nimi:
- FPGA
  - CPU
  - IO controller 

- Arduino
  - Cache
  
- PC
  - RAM
  - Urządzenia podpięte do RAMu (np. prosty wyświetlacz tekstowy; klawiatura)
  - Assembler, debugger, itp.
![System](/s1.png)
## Procesor sticky.arch

Pierwsze prace nad procesorem ogólnego przeznaczenia zaczeły się pod koniec 2020r, kiedy zaznajomiłem się z projektem [Mill Architecture](https://millcomputing.com/). 
Zainspirowany tymi pomysłami, zacząłem według nich projektować swoją konstrukcje.<br>
Drugą inspiracją był [microcode 8086](https://www.reenigne.org/blog/8086-microcode-disassembled/). 
A konkretniej: gdyby microcode był natywnym kodem maszynowym procesora, nie musiał by mieć dekodera.
Czy to założenie udało się spełnić? Z dzisiejszej perspektywy mogę powiedzieć, że nie...
Natomiast takie (często bardzo wewnętrzne i proste) instrukcje trzeba jakoś zakodować.<br>
Dlatego trzecią inspiracją był sposób kodowania instrukcji Intel Itanium. Lecz z tych pomysłów, po wielu zmianach i uproszczeniach nie wiele zostało. Podczas tworzenia kolejnych aspektów cpu, co raz bardziej rezygnowałem z pierwotnych założeń...

**Specyfikacja cpu**
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

![cpu_uarcg](/Untitled2.png)

**Podstawowe środowisko wynonawcze**<br>
Procesor nie ma żandego podziału na tryby, czy na poziomy uprzywilejowania. 
Program jest po prostu wykonywany, bez pilnowania czy to kod firmware'u czy aplikacji usera.
Adres fizyczny jest 24-bitowy. Górne 8-bit to segment, których wartości zapisane są w rejestrach segmentowych.
Pozostałe 16-bit to offset.

**Rejestry**<br>
W procesorze jest kilka typów rejestrów:
- Tymczasowe (TREG) (16-bit)
  - V0
  - V1
  - V2 - Rejestr transferu danych między pamięcią.
  - ACC - Accumulator. Wynik ALU zapisuje się do tego rejestru. Używany do trzymania offsetu (dolnego 16-bit adresu fizycznego) do pamięci. 
- Indeksowe (IDX) (16-bit)
  - IX
  - IY
  - SP - Stack Pointer
  - PC - Program Counter
- Ogólnego Przenaczenia (GPR) (16-bit)
  - R0-R7
- Segmentowe (8-bit) (górne 8 bit adresu fizycznego)
  - CS - Code Segment
  - DS - Data Segment
  - SS - Stack Segment

**Instrukcje**<br>
Każda instrukcja składa się z 4 bajtów. 
Dokładny opis ich kodowania znajduje się [tutaj](https://docs.google.com/spreadsheets/d/1010_0g59zPH0YjnZFvEePfx06E-xwZjjbiEDYnZvK1s/edit?usp=sharing).
TODO

## IO controller
IO controller znajduje się wraz z CPU na FPGA. 
Umożliwia komunikacje, między CPU a ledami/przyciskami, jednocześnie wymieniać dane z Cachem, który znajduje się na Arduino.
Transfer danych między IO a Cachem odbywa się przez SPI.

## Cache
Rozwiązanie, gdzie cache nie znajduje się na jednym układzie, na FPGA wraz z cpu było podyktowane ilością bloków logicznych, jakie moje FPGA posiada. 
Nie wiedziałem ile zasobów tak naprawdę zajmie cały projekt. Dlatego podjołem decyzje, gdzie cache, będzie programem na arduino. 
Jednocześnie arduino stanowi buffer komunikacyjny z PCtem. 

## Środowisko na PC
Według mnie, RAM jest najbardziej kontrowersyjną rzeczą w całym tym projekcie. 
Ponieważ znajnduje się on na realnym komputerze x86. 
Jest programem, napisanym w Pythonie, który tworzy bytearray wielkości 2<sup>24</sup>. 
Natomiast ma to również swoje zalety. np: Łatwość w ładowaniu programów, czy mapowania pod RAM jakiś dodaków, np: Ekranu tekstowego, czy buffera klawiatury.<br>
Oprócz tego projekt zakłada takie programy jak assembler, disassembler czy debugger, lecz owe aplikacje, są dopiero w tworzeniu.  


