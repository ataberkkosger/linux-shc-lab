# Lab 01: Echo PoC — Linux x86 Shellcode

Bu laboratuvar çalışmasında, Linux x86 (32-bit) mimarisi üzerinde standart girdi alıp (`sys_read`), alınan girdiyi ekrana basan (`sys_write`) ve ardından temiz bir şekilde sonlanan (`sys_exit`) ham bir shellcode geliştirilmiş ve C harness üzerinden test edilmiştir.

---

## Sistem Çağrıları (Syscalls) ve Akış

| Syscall | Numara | Açıklama |
|---|---|---|
| `sys_read` | `0x03` | Kullanıcıdan girdi almak için tetiklendi |
| `sys_write` | `0x04` | Girdiyi `stdout` üzerine basmak için tetiklendi |
| `sys_exit` | `0x01` | Programın `SIGSEGV` almadan temiz kapanması için tetiklendi |

> **Kritik:** Syscall register'ları (`eax`, `ebx`, `ecx`, `edx`) her sistem çağrısından önce **yeniden set edilmelidir** — bir önceki çağrının bıraktığı değerler sonraki çağrıyı bozar. `ESP` ise asla yeniden tanımlanmaz; yalnızca okunur.

---

## Dosya Yapısı

```
.
├── echo.asm    # 32-bit Linux sistem çağrılarını barındıran Assembly kaynak kodu
└── poc.c       # Shellcode'u bellek üzerinde pointer manipülasyonu ile tetikleyen C harness kodu
```

---

## Adım Adım Uygulama

### 1. Kaynak Kodun Derlenmesi (Assemble)

`echo.asm` dosyası, NASM derleyicisi kullanılarak 32-bit ELF formatında nesne dosyasına dönüştürüldü:

```bash
nasm -f elf32 echo.asm -o echo.o
```

### 2. Shellcode Oluşturma (Opcode Extraction)

Derlenen nesne dosyasındaki ham makine kodlarını (opcodes) ayıklamak ve C uyumlu `\x` formatına getirmek için `objdump` ve pipeline komutları kullanıldı:

```bash
objdump -d echo.o | grep "^ " | cut -f 2 | tr -d ' ' | tr -d '\n' | sed 's/.\{2\}/\\x&/g'
```

### 3. Proof of Concept (PoC) İmplementasyonu

Elde edilen shellcode çıktısı, `poc.c` içerisindeki bir karakter dizisine (`unsigned char code[]`) aktarıldı.

### 4. PoC Derleme ve Bellek Korumalarını Aşma

Modern işletim sistemlerinde veri segmentlerinin (stack) çalıştırılmasını engelleyen **NX (No-Execute)** korumasını devre dışı bırakmak ve kodu 32-bit mimaride derlemek için GCC'de `-z execstack` ve `-m32` bayrakları kullanıldı:

```bash
gcc poc.c -m32 -z execstack
```

---

## Test ve Doğrulama

Derleme sonrası oluşan binary test edildiğinde, programın girdiyi başarıyla alıp ekrana yansıttığı ve temiz biçimde sonlandığı doğrulandı:

```
ataberk@ataberkpc:~/shellcode0/linux-shc-lab/lab01-echo$ ./a.out
calisiyor...
deneme
deneme
ataberk@ataberkpc:~/shellcode0/linux-shc-lab/lab01-echo$
```
