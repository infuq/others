%include "boot.inc"
SECTION LOADER vstart=LOADER_BASE_ADDR

jmp protect_mode

gdt:
;0描述符
	dd	0x00000000
	dd	0x00000000
;1描述符(4GB代码段描述符)
	dd	0x0000ffff
	dd	0x00cf9800
;2描述符(4GB数据段描述符)
	dd	0x0000ffff
	dd	0x00cf9200
;3描述符(28Kb的视频段描述符)
	dd	0x80000007
	dd	0x00c0920b

lgdt_value:
	dw $-gdt-1	;高16位表示表的最后一个字节的偏移(表的大小-1)
	dd gdt			;低32位表示起始位置(GDT的物理地址)

SELECTOR_CODE	equ	0x0001<<3
SELECTOR_DATA	equ	0x0002<<3
SELECTOR_VIDEO	equ	0x0003<<3

protect_mode:
;进入32位
	lgdt [lgdt_value]
	in al,0x92
	or al,0000_0010b
	out 0x92,al
	cli
	mov eax,cr0
	or eax,1
	mov cr0,eax
	
	jmp dword SELECTOR_CODE:main
	
[bits 32]
;正式进入32位
main:
mov ax,SELECTOR_DATA
mov ds,ax
mov es,ax
mov ss,ax
mov esp,LOADER_STACK_TOP
mov ax,SELECTOR_VIDEO
mov gs,ax

mov byte [gs:0xa0],'P'
mov byte [gs:0xa2],'r'
mov byte [gs:0xa4],'o'
mov byte [gs:0xa6],'t'
mov byte [gs:0xa8],'e'
mov byte [gs:0xaa],'c'
mov byte [gs:0xac],'t'
mov byte [gs:0xb0],'O'
mov byte [gs:0xb2],'N'
mov byte [gs:0xb4],'('
mov byte [gs:0xb6],'3'
mov byte [gs:0xb8],'2'
mov byte [gs:0xba],'M'
mov byte [gs:0xbc],'O'
mov byte [gs:0xbe],'D'
mov byte [gs:0xc0],')'



;创建页表并初始化(页目录和页表)
PAGE_DIR_TABLE_POS equ 0x100000
call setup_page

;重新加载 gdt,因为已经变成了虚拟地址方式
sgdt [lgdt_value]
mov ebx,[lgdt_value+2]
or dword [ebx+0x18+4],0xc0000000
add dword [lgdt_value+2],0xc0000000
add esp,0xc0000000

;页目录表起始地址存入 cr3 寄存器
mov eax,PAGE_DIR_TABLE_POS
mov cr3,eax

;开启分页
mov eax,cr0
or eax,0x80000000
mov cr0,eax

;重新加载 gdt
lgdt [lgdt_value]

mov byte [gs:0x1e0],'P'
mov byte [gs:0x1e2],'A'
mov byte [gs:0x1e4],'G'
mov byte [gs:0x1e6],'E'
mov byte [gs:0x1ea],'O'
mov byte [gs:0x1ec],'N'

jmp $

setup_page:
;先把页目录占用的空间逐字清零
	mov ecx,4096
	mov esi,0
.clear_page_dir:
	mov byte [PAGE_DIR_TABLE_POS+esi],0
	inc esi
	loop .clear_page_dir
	
;开始创建页目录项(PDE)
.create_pde:
	mov eax,PAGE_DIR_TABLE_POS
	add eax,0x1000; 此时eax为第一个页表的位置及属性
	mov ebx,eax
	or eax,111b
	mov [PAGE_DIR_TABLE_POS],eax
	mov [PAGE_DIR_TABLE_POS+0xc00],eax
	sub eax,0x1000
	mov [PAGE_DIR_TABLE_POS+4*1023],eax

;开始创建页表项(PTE)
	mov ecx,256
	mov esi,0
	mov edx,111b
.create_pte:
	mov [ebx+esi*4],edx
	add edx,4096
	inc esi
	loop .create_pte
	
;创建内核其他页表的页目录项(PDE)
	mov eax,PAGE_DIR_TABLE_POS
	add eax,0x2000
	or eax,111b
	mov ebx,PAGE_DIR_TABLE_POS
	mov ecx,254
	mov esi,769
.create_kernel_pde:
	mov [ebx+esi*4],eax
	inc esi
	add eax,0x1000
	loop .create_kernel_pde
	ret