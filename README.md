# Linux Shellcode Development Laboratory

Bu depo, Linux işletim sistemi üzerinde alt seviye (low-level) sistem programlama, sistem çağrıları (syscalls) ve shellcode geliştirme pratiklerini içeren kişisel bir laboratuvardır. Öğrenme amacıyla başladım; repo sürekli güncellenecektir. Henüz öğrenme aşamasında olduğumdan yanlış veya eksik bilgi varsa lütfen benimle iletişime geçmekten çekinmeyin.

---

## Shellcode Nedir?

**Shellcode**, binary exploitation veya malware development süreçlerinde kullanılan; doğrudan CPU'nun anlayabileceği makine koduna (opcodes) dönüştürülmüş Assembly kodlarıdır.

Üretim kaliteli bir shellcode genellikle iki temel özelliği karşılamalıdır:

| Özellik | Açıklama |
|---|---|
| **PIC** (Position Independent Code) | Kodun bellekte hangi adrese yüklendiğinden bağımsız olarak çalışabilmesi; kendi kendine yetebilmesi |
| **Null-Free** | Shellcode içinde `0x00` byte bulunmaması — aksi hâlde `strcpy` gibi C string fonksiyonları kopyalamayı erken keser |

---

## Laboratuvar İndeksi

| Lab | Açıklama |
|---|---|
| [**`lab01-echo`**](./lab01-echo) | Linux x86 mimarisinde `sys_read` / `sys_write` döngüsü içeren ilk temel shellcode ve C PoC çalışması |
| [**`lab02-shell_open`**](./lab02-shell_open) | Linux x86 mimarisinde `sys_execve` ile `/bin/sh` tetikleyen, Null-Free ve bellek hizalamalı shellcode çalışması |
| [**`lab03-tcp_rev_sh`**](./lab03-tcp_rev_sh) | Linux x86 mimarisinde `socketcall` + `dup2` + `execve` zinciriyle TCP reverse shell oluşturan shellcode çalışması |
| [**`lab04-encoder`**](./lab04-encoder): Kısıtlı karakterlerden (bad characters) kaçınma, Self-Modifying Code (SMC), JMP-CALL-POP tekniği ve XOR tabanlı dekoder mimarisi. |
---

## Sorumluluk Reddi Beyanı

Bu proje yalnızca **eğitim ve araştırma** amaçlıdır. Geliştirilen shellcode'lar ve laboratuvar çalışmaları, düşük seviyeli sistem programlama ve güvenlik araştırmalarına giriş niteliğindedir. İzinsiz sistemler üzerinde kullanılması yasadışıdır. Yazar, bu kodların kötüye kullanımından doğabilecek herhangi bir zarardan sorumlu tutulamaz.
