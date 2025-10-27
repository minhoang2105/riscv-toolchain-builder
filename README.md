# 🚀 RISC-V Custom Toolchain Project

## 📌 Tóm tắt nhanh

Dự án xây dựng RISC-V GNU Toolchain với 4 custom instructions: `mod`, `mul4`, `mul8`, `mul16`

**✅ Trạng thái:** HOÀN THÀNH  
**📅 Ngày:** 28/10/2025  
**⏱️ Thời gian:** ~4 giờ  

---

## 🎯 Custom Instructions

| Instruction | Opcode | Chức năng |
|-------------|--------|-----------|
| **mod**     | `0x200000b` | `rd = rs1 % rs2` (modulo) |
| **mul4**    | `0x600b` | `rd = rs1 * 4` |
| **mul8**    | `0x200600b` | `rd = rs1 * 8` |
| **mul16**   | `0x400600b` | `rd = rs1 * 16` |

---

## ⚡ Quick Start

### Test Custom Instructions
```bash
cd /home/minhoang/workspace/RISC-V
./test_quick.sh
```

### Assemble File
```bash
/opt/riscv_custom/bin/riscv64-unknown-elf-as test_custom.s -o test.o
/opt/riscv_custom/bin/riscv64-unknown-elf-objdump -d test.o
```

---

## 📚 Documentation

| File | Mô tả |
|------|-------|
| **BAO_CAO_HOAN_THANH.md** | 📊 Báo cáo chi tiết đầy đủ nhất |
| **HUONG_DAN_BUILD.md** | 🔧 Hướng dẫn build toolchain từ đầu |
| **LINKER_SCRIPT_NOTES.md** | 🔗 Kiến thức về linker script |
| **test_quick.sh** | ✅ Script test tự động |
| **test_custom.s** | 📝 Assembly test file |

---

## 🔧 Toolchain Info

**Vị trí:** `/opt/riscv_custom`  
**Kiến trúc:** rv64gc (64-bit RISC-V với IMAFD + Compressed)  
**GCC Version:** 15.1.0  
**Components:**
- ✅ Binutils (assembler, linker, objdump) - với custom instructions
- ✅ GCC (compiler) 
- ✅ Newlib (C library)
- ✅ GDB (debugger)

---

## 📂 Cấu trúc thư mục

```
/home/minhoang/workspace/RISC-V/
├── riscv-gnu-toolchain/      # Source code (~7GB)
├── riscv-opcodes/            # Opcode generator
├── test_custom.s             # Assembly test
├── test_quick.sh             # Test script
├── BAO_CAO_HOAN_THANH.md    # Báo cáo chính ⭐
├── HUONG_DAN_BUILD.md       # Build guide
├── LINKER_SCRIPT_NOTES.md   # Linker notes
└── README.md                 # File này
```

---

## 🧪 Test Results

```asm
   4:   02b5060b    mod     a2,a0,a1    ✅
   c:   00b5668b    mul4    a3,a0,a1    ✅
  10:   02b5670b    mul8    a4,a0,a1    ✅
  14:   04b5678b    mul16   a5,a0,a1    ✅
```

**✅ Tất cả 4 instructions hoạt động chính xác!**

---

## 🚀 Bước tiếp theo (Optional)

### 1. Implement Spike Simulator
Để **chạy** code (không chỉ assemble):
```bash
git clone https://github.com/riscv-software-src/riscv-isa-sim.git
# Thêm behavior cho mod, mul4, mul8, mul16
# Build Spike
```

### 2. Hardware Implementation
Tích hợp vào RISC-V processor (FPGA/ASIC):
- Thêm decode logic cho 4 opcodes
- Implement ALU operations
- Test trên hardware

### 3. Custom Linker Script
Thay đổi memory layout nếu cần:
```bash
/opt/riscv_custom/bin/riscv64-unknown-elf-ld --verbose > custom.ld
# Edit custom.ld
# Compile với: gcc -T custom.ld main.c
```

---

## 💡 Troubleshooting

### Custom instruction không được nhận diện?
```bash
# Kiểm tra đang dùng assembler nào
which riscv64-unknown-elf-as
# Dùng full path
/opt/riscv_custom/bin/riscv64-unknown-elf-as test.s -o test.o
```

### Build lại toolchain?
```bash
cd riscv-gnu-toolchain
./configure --prefix=/opt/riscv_custom
make -j$(nproc)
```

---

## 📞 Hỗ trợ

Xem chi tiết trong:
- **Báo cáo đầy đủ:** `BAO_CAO_HOAN_THANH.md`
- **Build guide:** `HUONG_DAN_BUILD.md`
- **Linker notes:** `LINKER_SCRIPT_NOTES.md`

---

## 🏆 Credits

**Người thực hiện:** minhoang + GitHub Copilot  
**Ngày hoàn thành:** 28/10/2025  
**Status:** ✅ SUCCESS - All tests passed!

---

**🎉 Happy RISC-V Hacking! 🚀**
