# Linux Shellcode Development Laboratory (linux-shc-lab)

Bu depo, Linux işletim sistemi üzerinde alt seviye (low-level) sistem programlama, sistem çağrıları (syscalls) ve özel shellcode(shc) geliştirme pratiklerini içeren kişisel bir laboratuvardır. Projeye shc öğrenme amacı ile başladım repo sürekli güncellenecektir. Henüz öğrenme aşamasında olduğumdan yanlış yada eksik bilgi var ise lütfen benimle iletişime geçmekten çekinmeyin.

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

* [**`lab01-echo`**](./lab01-echo): Linux x86 mimarisinde standart girdi (`sys_read`) ve çıktı (`sys_write`) döngüsü içeren ilk temel shellcode ve C PoC çalışması.

---

## Sorumluluk Reddi Beyanı

Bu proje yalnızca **eğitim ve araştırma** amaçlıdır. Geliştirilen shellcode'lar ve laboratuvar çalışmaları, düşük seviyeli sistem programlama ve güvenlik araştırmalarına giriş niteliğindedir. İzinsiz sistemler üzerinde kullanılması yasadışıdır. Yazar, bu kodların kötüye kullanımından doğabilecek herhangi bir zarardan sorumlu tutulamaz.
