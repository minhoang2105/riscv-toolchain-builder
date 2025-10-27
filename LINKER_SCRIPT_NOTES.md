# 📝 GHI CHÚ VỀ LINKER SCRIPT CHO RISC-V TOOLCHAIN

## 🎯 Tóm tắt vấn đề

Khi build RISC-V toolchain cho embedded systems, linker script quyết định cách sắp xếp các sections (code, data, stack, heap) trong bộ nhớ. Nếu cần thay đổi địa chỉ bộ nhớ mặc định (ví dụ: code bắt đầu từ `0x80000000` thay vì `0x00000000`), bạn cần biết nơi sửa linker script trong source code của toolchain.

## 📂 Vị trí các file quan trọng

### 1. **Template chính của linker script**
```
binutils/ld/scripttempl/elf.sc
```
- Đây là template chung cho tất cả kiến trúc ELF
- Định nghĩa cấu trúc chung của linker script

### 2. **Tham số riêng cho RISC-V 32-bit**
```
binutils/ld/emulparams/elf32lriscv.sh
binutils/ld/emulparams/elf32lriscv-defs.sh
```
- Chứa các thông số cụ thể cho RISC-V 32-bit
- Địa chỉ khởi đầu, alignment, v.v.

### 3. **Tham số riêng cho RISC-V 64-bit**
```
binutils/ld/emulparams/elf64lriscv.sh
binutils/ld/emulparams/elf64lriscv-defs.sh
```
- Chứa các thông số cụ thể cho RISC-V 64-bit
- **Đây là file chúng ta đang dùng** (vì build rv64gc)

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

### 1. **Rocket-Chip / SiFive cores**
- Code thường bắt đầu từ: `0x80000000`
- RAM thường ở: `0x80000000 - 0x8FFFFFFF`
- Boot ROM: `0x00001000`

### 2. **Bare-metal embedded**
- Flash ROM: `0x00000000`
- SRAM: `0x20000000`
- Peripherals: `0x40000000`

### 3. **QEMU RISC-V virt machine**
- RAM: `0x80000000` (mặc định 128MB)
- PLIC: `0x0c000000`
- UART: `0x10000000`

## 📋 Checklist khi thay đổi linker script

- [ ] Xác định địa chỉ RAM/ROM của hardware
- [ ] Kiểm tra alignment requirements (thường 4-byte hoặc 8-byte)
- [ ] Đảm bảo stack pointer được khởi tạo đúng
- [ ] Verify các interrupt vectors nằm đúng vị trí
- [ ] Test với simple bare-metal program trước

## 🔗 Tài liệu tham khảo

1. **GNU LD Manual:**
   - https://sourceware.org/binutils/docs/ld/Scripts.html

2. **RISC-V Toolchain GitHub:**
   - https://github.com/riscv-collab/riscv-gnu-toolchain

3. **SiFive Freedom E SDK:**
   - Có sẵn linker scripts cho các boards thực tế

## ⚠️ Lưu ý quan trọng

1. **Địa chỉ phải khớp với hardware:** Nếu hardware bắt đầu RAM từ `0x80000000`, nhưng linker script đặt ở `0x00000000`, chương trình sẽ crash.

2. **AT> directive:** Dùng để load .data section vào ROM nhưng run từ RAM:
   ```ld
   .data : { *(.data*) } > RAM AT> ROM
   ```

3. **Startup code:** File `crt0.S` (C runtime startup) cũng cần khớp với linker script, đặc biệt là địa chỉ stack.

---

**📅 Ngày tạo:** 28/10/2025  
**✅ Trạng thái:** Toolchain đã build thành công với custom instructions  
**🎯 Mục đích:** Ghi chú để tham khảo khi cần customize linker script cho hardware cụ thể
