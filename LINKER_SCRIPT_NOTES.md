# 📝 GHI CHÚ VỀ LINKER SCRIPT CHO RISC-V TOOLCHAIN

> **Phần của dự án:** RISC-V Toolchain với 4 Custom Instructions (mod, mul4, mul8, mul16)  
> **Toolchain:** rv64gc, lp64d ABI, GCC 15.1.0  
> **Spike Simulator:** Đã tích hợp support cho custom instructions  
> **Last Updated:** 28/10/2025

---

## 🎯 Tóm tắt vấn đề

Khi build RISC-V toolchain cho embedded systems, linker script quyết định cách sắp xếp các sections (code, data, stack, heap) trong bộ nhớ. Nếu cần thay đổi địa chỉ bộ nhớ mặc định (ví dụ: code bắt đầu từ `0x80000000` thay vì `0x00000000`), bạn cần biết nơi sửa linker script trong source code của toolchain.

**Trong dự án này:**
- ✅ Toolchain đã build với custom instructions
- ✅ Spike simulator hỗ trợ execution testing
- ℹ️ Linker script mặc định phù hợp cho testing
- 📝 Guide này để customize cho hardware thực tế

## 📂 Vị trí các file quan trọng

### 1. **Template chính của linker script**
```
riscv-gnu-toolchain/binutils/ld/scripttempl/elf.sc
```
- Template chung cho tất cả kiến trúc ELF
- Định nghĩa cấu trúc chung của linker script
- **Location:** `/home/minhoang/workspace/RISC-V/riscv-gnu-toolchain/binutils/ld/scripttempl/elf.sc`

### 2. **Tham số riêng cho RISC-V 32-bit**
```
riscv-gnu-toolchain/binutils/ld/emulparams/elf32lriscv.sh
riscv-gnu-toolchain/binutils/ld/emulparams/elf32lriscv-defs.sh
```
- Chứa các thông số cụ thể cho RISC-V 32-bit
- Địa chỉ khởi đầu, alignment, v.v.

### 3. **Tham số riêng cho RISC-V 64-bit** ⭐
```
riscv-gnu-toolchain/binutils/ld/emulparams/elf64lriscv.sh
riscv-gnu-toolchain/binutils/ld/emulparams/elf64lriscv-defs.sh
```
- Chứa các thông số cụ thể cho RISC-V 64-bit
- **Đây là file chúng ta đang dùng** (vì build rv64gc)
- **Full path:** `/home/minhoang/workspace/RISC-V/riscv-gnu-toolchain/binutils/ld/emulparams/elf64lriscv.sh`

### 4. **Generated linker scripts (sau khi build)**
```
/opt/riscv_custom/riscv64-unknown-elf/lib/ldscripts/
```
- Chứa các linker scripts đã được generate
- Ví dụ: `elf64lriscv.x`, `elf64lriscv.xn`, `elf64lriscv.xr`, etc.
- Đây là scripts thực tế mà `ld` sử dụng khi link

## 🔍 Xem linker script hiện tại

### Lệnh xem linker script mặc định:
```bash
/opt/riscv_custom/bin/riscv64-unknown-elf-ld --verbose
```

Output sẽ hiển thị linker script đầy đủ mà `ld` đang sử dụng, bao gồm:
- MEMORY regions (RAM, ROM, Flash)
- SECTIONS layout (.text, .data, .bss, .rodata, v.v.)
- Địa chỉ khởi đầu của từng section
- Alignment requirements

### Ví dụ output quan trọng:
```
MEMORY
{
  RAM (xrw) : ORIGIN = 0x80000000, LENGTH = 128M
  ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 64M
}

SECTIONS
{
  .text : { *(.text*) } > ROM
  .data : { *(.data*) } > RAM
  ...
}
```

## ⚙️ Cách thay đổi địa chỉ bộ nhớ

### **Phương pháp 1: Sửa trong source code (trước khi build)**

1. **Tìm file emulparams:**
```bash
cd /home/minhoang/workspace/RISC-V/riscv-gnu-toolchain/binutils/ld/emulparams
nano elf64lriscv.sh
```

2. **Tìm và sửa các biến:**
```bash
TEXT_START_ADDR=0x80000000    # Địa chỉ bắt đầu của .text section
DATA_START_ADDR=0x80100000    # Địa chỉ bắt đầu của .data section
```

3. **Rebuild binutils:**
```bash
cd /home/minhoang/workspace/RISC-V/riscv-gnu-toolchain
make clean-binutils-newlib
make -j$(nproc)
```

### **Phương pháp 2: Dùng custom linker script (không cần rebuild)**

1. **Xem linker script mặc định:**
```bash
/opt/riscv_custom/bin/riscv64-unknown-elf-ld --verbose > default.ld
```

2. **Chỉnh sửa file `default.ld`:**
```ld
MEMORY
{
  /* Thay đổi địa chỉ theo hardware của bạn */
  RAM (xrw) : ORIGIN = 0x80000000, LENGTH = 512M
  ROM (rx)  : ORIGIN = 0x20000000, LENGTH = 128M
}

SECTIONS
{
  .text : { *(.text*) } > ROM
  .rodata : { *(.rodata*) } > ROM
  .data : { *(.data*) } > RAM AT> ROM
  .bss : { *(.bss*) } > RAM
  ...
}
```

3. **Sử dụng custom linker script khi compile:**
```bash
/opt/riscv_custom/bin/riscv64-unknown-elf-gcc -T custom.ld main.c -o program.elf
```

## 🎯 Use cases phổ biến

### 1. **Spike Simulator (Our Setup)** ⭐
```ld
MEMORY
{
  RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 128M
}

SECTIONS
{
  .text : { *(.text*) } > RAM
  .rodata : { *(.rodata*) } > RAM
  .data : { *(.data*) } > RAM
  .bss : { *(.bss*) } > RAM
}
```
- **Dùng cho:** Testing với Spike simulator và proxy kernel (pk)
- **Custom instructions:** mod, mul4, mul8, mul16 hoạt động bình thường
- **Entry point:** Spike tự động load từ ELF header

### 2. **Rocket-Chip / SiFive cores**
```ld
MEMORY
{
  ROM (rx)  : ORIGIN = 0x00001000, LENGTH = 16K    /* Boot ROM */
  RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 512M   /* Main RAM */
}
```
- Code thường bắt đầu từ: `0x80000000`
- RAM thường ở: `0x80000000 - 0x9FFFFFFF`
- Boot ROM: `0x00001000`
- **Use case:** FPGA implementations, SiFive HiFive boards

### 3. **Bare-metal embedded**
```ld
MEMORY
{
  FLASH (rx)  : ORIGIN = 0x00000000, LENGTH = 256K
  SRAM (rwx)  : ORIGIN = 0x20000000, LENGTH = 64K
  PERIPH (rw) : ORIGIN = 0x40000000, LENGTH = 512M
}

SECTIONS
{
  .text : { *(.text*) } > FLASH
  .rodata : { *(.rodata*) } > FLASH
  .data : { *(.data*) } > SRAM AT> FLASH
  .bss : { *(.bss*) } > SRAM
}
```
- Flash ROM: `0x00000000` (code stored here)
- SRAM: `0x20000000` (runtime data)
- Peripherals: `0x40000000` (UART, GPIO, etc.)
- **Use case:** Microcontrollers, custom ASIC

### 4. **QEMU RISC-V virt machine**
```ld
MEMORY
{
  RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 128M
  PLIC      : ORIGIN = 0x0c000000, LENGTH = 0x4000000
  UART      : ORIGIN = 0x10000000, LENGTH = 0x100
}
```
- RAM: `0x80000000` (mặc định 128MB, configurable)
- PLIC (interrupt controller): `0x0c000000`
- UART: `0x10000000`
- **Use case:** QEMU emulation, OS development

## 📋 Checklist khi thay đổi linker script

### Trước khi sửa:
- [ ] Xác định địa chỉ RAM/ROM của hardware target
- [ ] Backup linker script hiện tại: `cp custom.ld custom.ld.backup`
- [ ] Đọc datasheet của hardware để biết memory map

### Khi sửa:
- [ ] Kiểm tra alignment requirements (thường 4-byte hoặc 8-byte cho RISC-V)
- [ ] Đảm bảo các sections không overlap
- [ ] Verify ORIGIN + LENGTH không vượt quá physical memory
- [ ] Check stack size đủ lớn (khuyến nghị >= 4KB)

### Sau khi sửa:
- [ ] Compile test program: `riscv64-unknown-elf-gcc -T custom.ld test.c -o test.elf`
- [ ] Check memory layout: `riscv64-unknown-elf-objdump -h test.elf`
- [ ] Verify addresses: `riscv64-unknown-elf-nm test.elf`
- [ ] Test trên simulator trước (Spike, QEMU)
- [ ] Test trên hardware thực tế

### Đặc biệt cho custom instructions:
- [ ] Ensure .text section có đủ không gian cho instructions
- [ ] Verify custom instructions (mod, mul4, mul8, mul16) được link đúng
- [ ] Test execution trên Spike: `spike pk test.elf`

## 🔗 Tài liệu tham khảo

### Official Documentation:
1. **GNU LD Manual:**
   - https://sourceware.org/binutils/docs/ld/Scripts.html
   - Section: "Linker Scripts"

2. **RISC-V Toolchain GitHub:**
   - https://github.com/riscv-collab/riscv-gnu-toolchain
   - Example linker scripts in tests/

3. **RISC-V ISA Specification:**
   - https://riscv.org/specifications/
   - Memory model and addressing

### Practical Examples:
4. **SiFive Freedom E SDK:**
   - https://github.com/sifive/freedom-e-sdk
   - Real-world linker scripts cho HiFive1, HiFive Unleashed

5. **Spike Simulator:**
   - https://github.com/riscv-software-src/riscv-isa-sim
   - Memory layout documentation

6. **QEMU RISC-V:**
   - https://www.qemu.org/docs/master/system/target-riscv.html
   - Virtual machine memory maps

### Our Project Files:
- **Installation Guide:** `HUONG_DAN_CAI_DAT_CHI_TIET.md`
- **Project Report:** `BAO_CAO_HOAN_THANH.md`
- **Test Scripts:** `test_quick.sh`

## ⚠️ Lưu ý quan trọng

### 1. **Địa chỉ phải khớp với hardware**
Nếu hardware bắt đầu RAM từ `0x80000000`, nhưng linker script đặt ở `0x00000000`, chương trình sẽ crash.

**Example:**
```c
// Hardware: RAM ở 0x80000000
// Linker script sai: ORIGIN = 0x00000000
// Result: ❌ Crash khi access memory
```

### 2. **AT> directive cho .data section**
Dùng để load .data section vào ROM nhưng run từ RAM:
```ld
.data : { 
    *(.data*) 
} > RAM AT> ROM
```

**Giải thích:**
- Code sẽ copy .data từ ROM (non-volatile) sang RAM (faster access)
- Startup code (crt0.S) phải implement copy này

### 3. **Startup code (crt0.S) phải khớp với linker script**
Linker script định nghĩa symbols như `_start`, `__bss_start`, `__bss_end`.  
Startup code phải dùng đúng các symbols này.

### 4. **Stack pointer initialization**
```ld
/* Trong linker script */
__stack_top = ORIGIN(RAM) + LENGTH(RAM);

/* Trong startup code (crt0.S) */
la sp, __stack_top
```

### 5. **Custom instructions không ảnh hưởng linker script**
Các custom instructions (mod, mul4, mul8, mul16) chỉ là opcodes mới.  
Linker script không cần thay đổi để support chúng.

**Chỉ cần:**
- ✅ Assembler nhận diện instructions (đã có)
- ✅ Linker biết cách link code section bình thường
- ✅ Simulator/hardware support execution

### 6. **Testing trên Spike vs Hardware**
- **Spike:** Flexible memory, có thể run code ở bất kỳ địa chỉ nào
- **Hardware:** Strict memory map, phải match datasheet

**Recommendation:** Test trên Spike trước, sau đó customize cho hardware.

### 7. **Sections order matters**
```ld
SECTIONS {
    .text   : { ... } > ROM   /* Code first */
    .rodata : { ... } > ROM   /* Read-only data */
    .data   : { ... } > RAM   /* Initialized data */
    .bss    : { ... } > RAM   /* Uninitialized data last */
}
```

Thứ tự này quan trọng vì:
- .bss không chiếm không gian trong ELF file
- .data cần copy từ ROM sang RAM
- .text và .rodata immutable, có thể run-in-place

---

## 🧪 Testing Linker Script Changes

### Test 1: Simple Program
```c
// test_linker.c
int global_var = 42;        // .data
int uninitialized;          // .bss
const int readonly = 100;   // .rodata

int main() {
    return global_var + readonly;  // .text
}
```

**Compile và check:**
```bash
riscv64-unknown-elf-gcc -T custom.ld test_linker.c -o test.elf
riscv64-unknown-elf-objdump -h test.elf  # Check section addresses
riscv64-unknown-elf-nm test.elf          # Check symbol addresses
```

### Test 2: Với Custom Instructions
```asm
; test_custom_linker.s
.text
.globl _start
_start:
    li a0, 17
    li a1, 5
    mod a2, a0, a1      # Custom instruction
    mul4 a3, a0, a1     # Custom instruction
```

**Build và verify:**
```bash
riscv64-unknown-elf-as test_custom_linker.s -o test.o
riscv64-unknown-elf-ld -T custom.ld test.o -o test.elf
riscv64-unknown-elf-objdump -d test.elf
spike pk test.elf  # Test execution
```

### Test 3: Memory Layout Verification
```bash
# Xem tất cả sections và addresses
riscv64-unknown-elf-readelf -S test.elf

# Check nếu sections overlap
riscv64-unknown-elf-size test.elf

# Verify entry point
riscv64-unknown-elf-readelf -h test.elf | grep Entry
```

---

## 💡 Advanced Topics

### 1. **Multi-Region Linking**
Khi có nhiều memory regions (Flash, SRAM, External RAM):

```ld
MEMORY {
    FLASH (rx)   : ORIGIN = 0x00000000, LENGTH = 512K
    SRAM (rwx)   : ORIGIN = 0x20000000, LENGTH = 128K
    EXTRAM (rwx) : ORIGIN = 0x60000000, LENGTH = 8M
}

SECTIONS {
    .text     : { *(.text*) } > FLASH
    .rodata   : { *(.rodata*) } > FLASH
    
    .data     : { *(.data*) } > SRAM AT> FLASH
    .bss      : { *(.bss*) } > SRAM
    
    .extdata  : { *(.extdata*) } > EXTRAM
}
```

**Use case:** Large buffers, DMA regions

### 2. **Section Attributes**
Đặt specific functions/variables vào specific sections:

```c
// C code
__attribute__((section(".fast_code")))
void critical_function() { ... }

__attribute__((section(".ext_data")))
uint8_t large_buffer[1024*1024];
```

```ld
/* Linker script */
SECTIONS {
    .fast_code : { *(.fast_code*) } > SRAM
    .ext_data  : { *(.ext_data*) } > EXTRAM
}
```

### 3. **Alignment và Padding**
```ld
.data : ALIGN(8) {
    *(.data*)
    . = ALIGN(16);  /* Pad to 16-byte boundary */
} > RAM
```

### 4. **Keep Unused Sections**
```ld
SECTIONS {
    .text : {
        KEEP(*(.isr_vector))  /* Don't optimize away interrupt vectors */
        *(.text*)
    } > FLASH
}
```

---

## 📊 Example: Complete Linker Script for Custom RISC-V Board

```ld
/* custom_board.ld - Complete example */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY {
    FLASH (rx)   : ORIGIN = 0x00000000, LENGTH = 1M
    RAM (rwx)    : ORIGIN = 0x80000000, LENGTH = 256K
}

SECTIONS {
    /* Code section */
    .text : {
        KEEP(*(.isr_vector))
        *(.text.startup)
        *(.text*)
        *(.gnu.linkonce.t*)
    } > FLASH

    /* Read-only data */
    .rodata : {
        *(.rodata*)
        *(.gnu.linkonce.r*)
    } > FLASH
    
    /* Initialized data (load in FLASH, run in RAM) */
    .data : {
        __data_start__ = .;
        *(.data*)
        *(.gnu.linkonce.d*)
        . = ALIGN(8);
        __data_end__ = .;
    } > RAM AT> FLASH
    
    __data_load_start__ = LOADADDR(.data);
    
    /* Uninitialized data */
    .bss : {
        __bss_start__ = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(8);
        __bss_end__ = .;
    } > RAM
    
    /* Stack (grows downward) */
    .stack : {
        . = ALIGN(16);
        . += 4K;  /* 4KB stack */
        __stack_top__ = .;
    } > RAM
    
    /* Heap (optional) */
    .heap : {
        __heap_start__ = .;
        . += 8K;  /* 8KB heap */
        __heap_end__ = .;
    } > RAM
}
```

**Startup code tương ứng (crt0.S):**
```asm
.section .text.startup
.globl _start
_start:
    # Setup stack
    la sp, __stack_top__
    
    # Copy .data from FLASH to RAM
    la t0, __data_load_start__
    la t1, __data_start__
    la t2, __data_end__
1:
    beq t1, t2, 2f
    lw t3, 0(t0)
    sw t3, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4
    j 1b
2:
    # Clear .bss
    la t0, __bss_start__
    la t1, __bss_end__
3:
    beq t0, t1, 4f
    sw zero, 0(t0)
    addi t0, t0, 4
    j 3b
4:
    # Call main
    call main
    
    # Infinite loop if main returns
5:  j 5b
```

---

**📅 Ngày cập nhật:** 28/10/2025  
**✅ Trạng thái:** 
- Toolchain build hoàn thành với 4 custom instructions
- Spike simulator đã tích hợp support
- Linker script mặc định hoạt động tốt cho testing
- Guide này cho advanced customization

**🎯 Mục đích:** 
- Tham khảo khi deploy lên hardware thực tế
- Customize memory layout cho boards cụ thể
- Optimize performance với section placement

**🔗 Related Files:**
- [Installation Guide](HUONG_DAN_CAI_DAT_CHI_TIET.md) - Complete setup từ đầu
- [Project Report](BAO_CAO_HOAN_THANH.md) - Executive summary
- [Push Guide](PUSH_TO_GITHUB.md) - How to share this project

---

**📧 Questions?** Check troubleshooting section trong `HUONG_DAN_CAI_DAT_CHI_TIET.md`
