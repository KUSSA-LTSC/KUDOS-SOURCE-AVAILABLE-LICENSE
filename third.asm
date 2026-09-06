; Copyright (c) 2026-8086 KUSSA (KUSSA_LTSC)
; All rights reserved.
;
; SPDX-License-Identifier: LicenseRef-scancode-kudos-sal-2.5

bits    64
default rel

;目录Content：

;编译bash
;发牢骚
;宏引入
;外部api声明
;常量参考
;数据段
;代码段
;README.MD内容
;后记

;编译bash:
;确保你已经安装了 NASM 和 GCC（MinGW 或 Cygwin 环境）。
;nasm -f win64 third.asm -o .\third.obj
;gcc -o .\third.exe .\third.obj -mwindows -lkernel32 -luser32 -nostdlib -e duck

;发牢骚：
;如果没有测试文件.txt的话会自己创建的
;你可以自己修改文件内容，太长的话会报错，缓冲区多少我也忘了，自己看吧
;这只是个演示程序
;该死的微软

%include 'third.inc'
;这里只留下一个小的专门的文件来放宏
;当然你启用文件里的宏并且注释掉上面这个inc也是一样
; %include 'kmarco.inc'
; %include 'inc.inc'

extern  ExitProcess
extern  MessageBoxW
extern  CreateFileW
extern  ReadFile
extern  CloseHandle
extern  MultiByteToWideChar

    ; GENERIC_READ          equ 0x80000000
    ; FILE_SHARE_READ       equ 0x00000001
    ; OPEN_EXISTING         equ 3
    ; OPEN_ALWAYS           equ 4
    ; FILE_ATTRIBUTE_NORMAL equ 0x80
    ; CP_UTF8               equ 65001
    ; MB_OK                 equ 0

;宏展开放这里了别再问我啦！
;就是开头的宏文件里面的，我自己写的
;看到这两行不用纠结，看不懂没关系
;默认栈对齐16自己就行

; %macro adod 0
;     push rbp
;     mov rbp , rsp
;     and rsp , -16
; %endmacro

; %macro pdod 0
;     mov rsp,rbp
;     pop rbp
; %endmacro        

section .data
    filename dw __?utf16?__('测试文件.txt'),0,0
    ;必须两个字节的0，不然会出错
    title    dw __?utf16?__('文件内容'),0,0
    err      dw __?utf16?__('出错了o(╥﹏╥)o'),0,0
    errmsg   dw __?utf16?__('缓冲区不够大'),0,0

    hFile     dq 0
    bytesRead dd 0

;这波稳一把直接暴力留下2048字节当缓冲区
    bufr times 2048 db 0
    bufw times 2048 db 0

section .text
    global duck

duck:
    
    adod;对齐16字节
;参数的注释我本来只表明了参数序号，参数名字和常量的注释用AI补的
;其它的所有注释都是我写的

    push rax                 ;占位垃圾
    push 0                   ;参数7：模板文件句柄（NULL）
    push 0x80                ;参数6：文件属性（FILE_ATTRIBUTE_NORMAL）
    push 4                   ;参数5：创建方式（OPEN_ALWAYS）
    lea  rcx,     [filename] ;参数1：文件名（LPCWSTR）
    mov  rdx,     0x80000000 ;参数2：访问权限（GENERIC_READ）
    mov  r8,      1          ;参数3：共享模式（FILE_SHARE_READ）
    xor  r9,      r9         ;参数4：安全属性（NULL）
    sub  rsp,     32         ;影子空间
    call CreateFileW
    cmp  rax,     -1         ;如果是-1就代表失败（没做报错）
    jz   exit
    mov  [hFile], rax        ;存入文件句柄

    pdod;恢复adod

;现在栈恢复成adod之前

    adod
    push rax              ;填充对齐的垃圾，是个寄存器就行
    push 0                ;参数5：重叠结构（NULL）
    lea  rbx, [bufr]      ;???不管了肯定有用
    sub  rsp, 32          ;影子空间
    mov  rcx, [hFile]     ;参数1：文件句柄
    mov  rdx, rbx         ;参数2：缓冲区指针       
    mov  r8,  2046        ;参数3：要读取的字节数
    lea  r9,  [bytesRead] ;参数4：实际读取字节数指针
    call ReadFile         ;注意参数5在栈上
;先检查有没成功读取
    or rax, rax
    jz mgd      ;不够大
;末尾补上'\0\0'
    mov edx,        [bytesRead]
    lea rdx,        [rdx+rbx]   ;现在知道rbx有用了
    mov word [rdx], 0
;显示
    pdod
;现在恢复到最开始的，也就是栈上没有任何东西
    adod
;双数参数个数不用额外压栈
    push 0                   ;参数6：宽字符缓冲区大小（0）
    push 0                   ;参数5：宽字符缓冲区（NULL）
    mov  rcx, 65001          ;参数1：代码页（CP_UTF8）
    xor  rdx, rdx            ;参数2：标志（0）
    lea  r8,  [bufr]         ;参数3：多字节字符串指针
    mov  r9d, [bytesRead]    ;参数4：多字节字符串长度（字节数）
    sub  rsp, 32             ;影子空间
    call MultiByteToWideChar
    pdod

;现在加上判断，如果rax*2比2046大就退出
    cmp rax, 1023
    ja  mgd
    ;奢侈的跳转
;缓冲区足够大就继续
    adod
    push 1024        ;参数6：宽字符缓冲区大小（1024个word）
    lea  r10, [bufw]
    push r10         ;参数5：宽字符缓冲区（bufw）
    sub  rsp, 32
;我去了差点成为野生代码，这Windows的64位居然有易失寄存器    
;还要重置一次寄存器参数，栈的参数还在
    mov  rcx, 65001          ;参数1：代码页（CP_UTF8）
    xor  rdx, rdx            ;参数2：标志（0）
    lea  r8,  [bufr]         ;参数3：多字节字符串指针
    mov  r9d, [bytesRead]    ;参数4：多字节字符串长度（字节数）
    call MultiByteToWideChar
    pdod
    adod
    sub  rsp, 32
    xor  rcx, rcx            ;参数1：父窗口句柄（NULL）
    lea  rdx, [bufw]         ;参数2：消息文本
    lea  r8,  title          ;参数3：标题
    xor  r9,  r9             ;参数4：按钮类型（MB_OK）
    call MessageBoxW
    mov  rcx, [hFile]        ;参数1：文件句柄
    call CloseHandle         ;注意：影子空间还在
;目前还没有pdod

exit:
    xor  rcx, rcx
    adod
    sub  rsp, 32
    call ExitProcess ;参数1：退出代码（0）
;如果缓冲区不够大的话
mgd:
    adod
    sub  rsp, 32
    xor  rcx, rcx      ;参数1：父窗口句柄（NULL）
    lea  rdx, [errmsg] ;参数2：错误消息文本
    lea  r8,  err      ;参数3：标题
    xor  r9,  r9       ;参数4：按钮类型（MB_OK）
    call MessageBoxW
    mov  rcx, [hFile]  ;参数1：文件句柄
    call CloseHandle   ;影子空间还在
    jmp  exit          ;不回收了，浪费一点栈也无所谓，反正要退出



;README.MD的内容（已过时）

    ; 我学习 NASM Win64 开发第六天做的教学 demo

    ; 打开“测试文件.txt”并且输出utf8转utf16le文本，如果文档不存在就创建

    ; 敢承诺代码百分百纯手工制作
    ; 敢承诺不用 AI 生成
    ; 敢承诺不用复制粘贴
    ; 敢承诺不看 Intel 白皮书

    ; （虽然也许只是但是仅仅不过是函数和参数的时候用 AI，因为我记不住）

    ; 不要被编译器压榨，要慢手写十倍的古法栈帧。
    ; 只取第一道 RBP 定海神针，稳如老狗，不掺 RSP 偏移。
    ; 私房宏全自动对齐十六字节，没有 MSVC 污染，纯手工封装，非工业化生产。

    ; 好消息！好消息！特大好消息！

    ; 我学习 NASM Win64 开发第六天做的教学 demo，今天（2026年8月28日）正式正式开源，永久免费开源，随便看随便用。

    ; 前多少名免费？不搞那套了，来了就全免费，过了今天也免费，明年也免费，永远免费。

    ; 错过今天，再等一年？骗你的，代码就在这，你什么时候来都行。

    ; 我不像电视广告那么“善解人意”，我“善解人衣”，爱看不看，反正注释写那了，自己悟。

    ; 协议：GPL v3。经过自由软件基金会（FSF）权威认证，GPL v3 证书真实有效。
    ; （注意：已经过时，仅供留档参考用，自从2026年9月6日起改用KUDOS而不再遵循GPL协议）

    ; 编译：
    ; nasm -f win64 third.asm -o third.obj
    ; gcc -o third.exe third.obj -mwindows -lkernel32 -luser32 -nostdlib -e duck
    ; 按照宏的说明来决定编译方法
    ; 这里只留下一个小的专门的文件third.inc来放宏
    ; 当然你启用文件里的宏并且注释掉上面这个inc也是一样

;README.MD内容结束

;后记（已过时）：

    ;真服了这注释有不少居然是写给笨蛋AI的，我自己都用不上这么详细
    ;写完啦，虽然只是个演示，O(∩_∩)O哈哈~
    ;也不知道下次再打开是啥时候咯
    ;呜呜呜要开学了o(╥﹏╥)o
    ;再见了我的暑假，悲
    ;KUSSA/KUSSA_LTSC
    ;2026年8月28日

;后记结束

;“我们做了个艰难的决定”：

;自从2026年9月6日起，这个教学demo不再遵循GPL协议，改用KUDOS
;原来已经用GPL协议发布的版本不受影响
;因为要使用闭源库或者是源码可见的库，不符合GPL要求

;2026年9月6日