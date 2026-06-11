# Lab 02: Execve Shell Trigger — Linux x86 Shellcode

Bu laboratuvar çalışmasında, Linux x86 (32-bit) mimarisi üzerinde doğrudan yerel bir kabuk (`/bin/sh`) tetikleyen, bellek hizalamalı ve tamamen **Null-Free** bir shellcode geliştirilmiş; `execve` sistem çağrısı kullanılarak C harness üzerinden execute edilmiştir.

---

## Sistem Çağrıları (Syscalls) ve Register Dağılımı

Laboratuvarda hedef kabuğu çalıştırmak için `sys_execve` (`0x0b`) çağrısı kullanılmıştır:

| Syscall | `eax` | `ebx` (Arg 1 — Path) | `ecx` (Arg 2 — argv) | `edx` (Arg 3 — envp) | Açıklama |
|---|---|---|---|---|---|
| `sys_execve` | `0x0b` | `esp` (`/bin//sh\0` adresi) | `0` (NULL) | `0` (NULL) | Hedef programı çalıştırır |
| `sys_exit` | `0x01` | `0` | — | — | Programı temiz kapatır |

---

## Düşük Seviyeli Mimari ve Stack Stratejileri

Yazılan Assembly kodunda, kabuk tetiklemenin başarılı olabilmesi ve shellcode kalitesini düşüren kısıtlamaların aşılması için iki kritik low-level tekniği uygulanmıştır:

### 1. Little-Endian ve Ters Push Mantığı

x86 mimarisi **Little-Endian** veri sıralama standardını kullanır; yani bellekteki verinin en önemsiz baytı (least significant byte) en düşük adreste tutulur. Stack yapısı ise yüksek bellek adresinden düşük bellek adresine doğru büyür.

Bu nedenle `/bin//sh` katarı stack'e **tersten** basılmıştır. CPU bu veriyi düzden okuduğunda doğru string dizilimini elde eder.

### 2. Veri Hizalaması (Data Alignment) ve Null-Free Hilesi

32-bit mimaride stack operasyonları **4 byte** genişliğinde hizalanmak zorundadır. `/bin/sh` ifadesi 7 byte olduğundan, 8 byte'a tamamlamak adına dosya yoluna fazladan bir eğik çizgi eklenerek `/bin//sh` haline getirilmiştir. Linux çekirdeği yol çözümlemesinde ardışık çizgileri (`//`) tek çizgi olarak yorumladığından bu durum yürütmeyi bozmaz.

Null terminator (`\0`) byte'ını shellcode içine statik olarak gömmemek için önce `eax` sıfırlanmış, ardından stack'e **dinamik olarak** push'lanmıştır.

**Stack'in Anlık Bellek Görünümü:**

```
ESP ----> [ 0x2f62696e ]  ->  "/bin"
          [ 0x2f2f7368 ]  ->  "//sh"
          [ 0x00000000 ]  ->  "\0"  (string sonlandırıcı)
```

---

## Dosya Yapısı

```
.
├── shell.asm   # 32-bit Linux execve sistem çağrısını barındıran Assembly kaynak kodu
└── poc.c       # Shellcode'u bellek üzerinde pointer manipülasyonu ile tetikleyen C harness kodu
```

---

## Adım Adım Uygulama

### 1. Kaynak Kodun Derlenmesi (Assemble)

`shell.asm` dosyası, NASM derleyicisi kullanılarak 32-bit ELF formatında nesne dosyasına dönüştürüldü:

```bash
nasm -f elf32 shell.asm -o shell.o
```

### 2. Shellcode Oluşturma (Opcode Extraction)

Derlenen nesne dosyasındaki ham makine kodlarını (opcodes) ayıklamak ve C uyumlu `\x` formatına getirmek için `objdump` ve pipeline komutları kullanıldı:

```bash
objdump -d shell.o | grep "^ " | cut -f 2 | tr -d ' ' | tr -d '\n' | sed 's/.\{2\}/\\x&/g'
```

### 3. PoC Derleme ve Bellek Korumalarını Aşma

Elde edilen shellcode `poc.c` içerisine gömülerek stack üzerinde yürütme izni veren GCC bayrakları ile derlendi:

```bash
gcc poc.c -m32 -z execstack
```

---

## Test ve Doğrulama

Oluşturulan PoC çalıştırıldığında, mevcut process'in yerini başarıyla yeni bir `/bin/sh` kabuğuna bıraktığı ve interaktif terminalin açıldığı doğrulandı:

```
ataberk@ataberkpc:~/shellcode0/linux-shc-lab/lab02-shell_open$ ./a.out
calisiyor...
$ whoami
ataberk
$ exit
ataberk@ataberkpc:~/shellcode0/linux-shc-lab/lab02-shell_open$ 
```
