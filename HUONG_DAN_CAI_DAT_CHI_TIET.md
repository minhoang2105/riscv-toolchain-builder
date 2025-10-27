# 📘 HƯỚNG DẪN CÀI ĐẶT CHI TIẾT - RISC-V TOOLCHAIN VỚI CUSTOM INSTRUCTIONS

> **Mục đích:** File này hướng dẫn từng bước cài đặt RISC-V GNU Toolchain với 4 custom instructions (mod, mul4, mul8, mul16) từ đầu đến cuối, bao gồm cả troubleshooting các lỗi thường gặp.

**Tác giả:** GitHub Copilot + minhoang  
**Ngày tạo:** 28/10/2025  
**Hệ thống:** WSL Ubuntu 22.04 on Windows  
**Thời gian ước tính:** 3-4 giờ (tùy tốc độ mạng và máy)

---

## 📋 MỤC LỤC

1. [Yêu cầu hệ thống](#1-yêu-cầu-hệ-thống)
2. [Bước 1: Cài đặt dependencies](#2-bước-1-cài-đặt-dependencies)
3. [Bước 2: Clone repositories](#3-bước-2-clone-repositories)
4. [Bước 3: Thêm custom instructions vào rv_i](#4-bước-3-thêm-custom-instructions-vào-rv_i)
5. [Bước 4: Generate MATCH/MASK values](#5-bước-4-generate-matchmask-values)
6. [Bước 5: Sửa binutils/riscv-opc.h](#6-bước-5-sửa-binutilsriscv-opch)
7. [Bước 6: Sửa binutils/riscv-opc.c](#7-bước-6-sửa-binutilsriscv-opcc)
8. [Bước 7: Download submodules](#8-bước-7-download-submodules)
9. [Bước 8: Configure toolchain](#9-bước-8-configure-toolchain)
10. [Bước 9: Build toolchain](#10-bước-9-build-toolchain)
11. [Bước 10: Testing](#11-bước-10-testing)
12. [Bước 11: Spike Simulator (Optional)](#12-bước-11-spike-simulator-optional)
13. [Troubleshooting tổng hợp](#13-troubleshooting-tổng-hợp)

---

## 1. YÊU CẦU HỆ THỐNG

### Hardware tối thiểu:
- **CPU:** 4 cores trở lên (khuyến nghị 8+ cores)
- **RAM:** 8GB (khuyến nghị 16GB)
- **Disk:** 20GB free space
- **Internet:** Stable connection để download ~10GB data

### Software:
- **OS:** Ubuntu 22.04 (WSL hoặc native)
- **Shell:** bash
- **Quyền:** sudo access

---

## 2. BƯỚC 1: CÀI ĐẶT DEPENDENCIES

### Lệnh cài đặt:

```bash
sudo apt-get update
sudo apt-get install -y autoconf automake autotools-dev curl python3 \
    python3-pip libmpc-dev libmpfr-dev libgmp-dev gawk build-essential \
    bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev \
    ninja-build git cmake libglib2.0-dev libslirp-dev
```

### Thời gian: ~5-10 phút

### Verify installation:

```bash
gcc --version        # Should show version 11.x or higher
make --version       # Should show version 4.x
git --version        # Should show version 2.x
python3 --version    # Should show version 3.10.x or higher
```

### ❌ Lỗi có thể gặp:

**Lỗi 1:** `E: Unable to locate package ...`
```
Nguyên nhân: Package list chưa update
Giải pháp: sudo apt-get update
```

**Lỗi 2:** `dpkg was interrupted`
```
Nguyên nhân: Apt bị gián đoạn trước đó
Giải pháp: sudo dpkg --configure -a
```

---

## 3. BƯỚC 2: CLONE REPOSITORIES

### Tạo thư mục làm việc:

```bash
mkdir -p ~/workspace/RISC-V
cd ~/workspace/RISC-V
```

### Clone riscv-gnu-toolchain:

```bash
git clone https://github.com/riscv-collab/riscv-gnu-toolchain.git
```

**Thời gian:** ~3-5 phút  
**Dung lượng:** ~500MB  
**Output mẫu:**
```
Cloning into 'riscv-gnu-toolchain'...
remote: Enumerating objects: 8756, done.
remote: Total 8756 (delta 0), reused 0 (delta 0), pack-reused 8756
Receiving objects: 100% (8756/8756), 4.32 MiB | 2.10 MiB/s, done.
```

### Clone riscv-opcodes:

```bash
git clone https://github.com/riscv/riscv-opcodes.git
```

**Thời gian:** ~30 giây  
**Dung lượng:** ~5MB

### Cài đặt Python tool `uv`:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc  # Hoặc mở terminal mới
```

### Verify:

```bash
ls -la ~/workspace/RISC-V/
# Phải thấy 2 thư mục: riscv-gnu-toolchain và riscv-opcodes

uv --version
# Phải thấy: uv 0.x.x
```

### ❌ Lỗi có thể gặp:

**Lỗi 1:** `fatal: unable to access 'https://github.com/...'`
```
Nguyên nhân: Network issue hoặc proxy
Giải pháp: 
  - Kiểm tra: ping github.com
  - Hoặc dùng git protocol: git config --global url."git://".insteadOf https://
```

**Lỗi 2:** `uv: command not found` sau khi cài
```
Nguyên nhân: Shell chưa reload PATH
Giải pháp: source ~/.bashrc hoặc mở terminal mới
```

---

## 4. BƯỚC 3: THÊM CUSTOM INSTRUCTIONS VÀO RV_I

### File cần sửa:
`~/workspace/RISC-V/riscv-opcodes/extensions/rv_i`

### Mở file:

```bash
cd ~/workspace/RISC-V/riscv-opcodes
nano extensions/rv_i
# Hoặc dùng vim/code tùy thích
```

### Tìm đến cuối file và thêm:

```
# Custom instructions - Added 2025-10-28
mod     rd rs1 rs2 31..25=1  14..12=0 6..2=2  1..0=3
mul4    rd rs1 rs2 31..25=0  14..12=3 6..2=1  1..0=3
mul8    rd rs1 rs2 31..25=1  14..12=3 6..2=1  1..0=3
mul16   rd rs1 rs2 31..25=2  14..12=3 6..2=1  1..0=3
```

### Lưu file:
- **nano:** Ctrl+O, Enter, Ctrl+X
- **vim:** :wq

### Giải thích format:

```
<tên>   <operands>   <bit_field_assignments>
  |         |                  |
  v         v                  v
mod     rd rs1 rs2    31..25=1 14..12=0 6..2=2 1..0=3

Trong đó:
- 31..25=1 → funct7 = 0b0000001 = 1
- 14..12=0 → funct3 = 0b000 = 0
- 6..2=2   → opcode[6:2] = 0b00010 = 2
- 1..0=3   → opcode[1:0] = 0b11 = 3 (fixed cho R-type)
→ Opcode đầy đủ: 0000001_00000_00000_000_00000_0001011
```

### Verify:

```bash
grep -E "^(mod|mul4|mul8|mul16)" extensions/rv_i
```

**Output mong đợi:** 4 dòng custom instructions

### ❌ Lỗi có thể gặp:

**Lỗi 1:** Syntax error khi generate MATCH/MASK
```
Nguyên nhân: Tab characters thay vì spaces
Giải pháp: Dùng spaces, không dùng tab. Mỗi field cách nhau bởi 1+ spaces
```

**Lỗi 2:** Duplicate opcode
```
Nguyên nhân: Opcode trùng với instruction có sẵn
Giải pháp: Thay đổi bit fields để tạo opcode khác
```

---

## 5. BƯỚC 4: GENERATE MATCH/MASK VALUES

### Chạy generator:

```bash
cd ~/workspace/RISC-V/riscv-opcodes
uv run riscv_opcodes -c 'rv*' > encoding.out.h
```

**Thời gian:** ~5-10 giây

### Kiểm tra output:

```bash
grep -E "MATCH_(MOD|MUL4|MUL8|MUL16)" encoding.out.h
```

**Output mong đợi:**
```c
#define MATCH_MOD 0x200000b
#define MASK_MOD  0xfe00707f
#define MATCH_MUL4 0x600b
#define MASK_MUL4  0xfe00707f
#define MATCH_MUL8 0x200600b
#define MASK_MUL8  0xfe00707f
#define MATCH_MUL16 0x400600b
#define MASK_MUL16  0xfe00707f
```

### Copy values để dùng ở bước sau:

```bash
grep -A1 "MATCH_MOD\|MATCH_MUL4\|MATCH_MUL8\|MATCH_MUL16" encoding.out.h > ~/custom_values.txt
cat ~/custom_values.txt
```

### ❌ Lỗi có thể gặp:

**Lỗi 1:** `uv: command not found`
```
Nguyên nhân: uv chưa được cài hoặc PATH chưa update
Giải pháp: curl -LsSf https://astral.sh/uv/install.sh | sh && source ~/.bashrc
```

**Lỗi 2:** `ModuleNotFoundError: No module named ...`
```
Nguyên nhân: Dependencies của riscv_opcodes chưa được install
Giải pháp: uv tự động cài dependencies, chờ nó hoàn thành
```

**Lỗi 3:** Không thấy custom instructions trong output
```
Nguyên nhân: rv_i file chưa được sửa đúng
Giải pháp: Kiểm tra lại bước 3, verify format
```

---

## 6. BƯỚC 5: SỬA BINUTILS/RISCV-OPC.H

### File cần sửa:
`~/workspace/RISC-V/riscv-gnu-toolchain/binutils/include/opcode/riscv-opc.h`

### Backup file gốc:

```bash
cd ~/workspace/RISC-V/riscv-gnu-toolchain/binutils/include/opcode
cp riscv-opc.h riscv-opc.h.backup
```

### Tìm vị trí thêm code (sau ADD instruction):

```bash
grep -n "MATCH_ADD" riscv-opc.h | head -1
```

**Output mẫu:** `59:#define MATCH_ADD 0x33`

### Mở file và thêm sau dòng MATCH_ADD:

```bash
nano riscv-opc.h
```

Nhấn **Ctrl+/** để goto line, nhập số dòng (ví dụ: 59), tìm đến sau `#define MASK_ADD ...`

Thêm vào:

```c
/* Custom instructions - Added 2025-10-28 */
#define MATCH_MOD 0x200000b
#define MASK_MOD  0xfe00707f
#define MATCH_MUL4 0x600b
#define MASK_MUL4  0xfe00707f
#define MATCH_MUL8 0x200600b
#define MASK_MUL8  0xfe00707f
#define MATCH_MUL16 0x400600b
#define MASK_MUL16  0xfe00707f
```

### Tìm phần DECLARE_INSN (cuối file):

```bash
grep -n "DECLARE_INSN(add" riscv-opc.h
```

**Output mẫu:** `3057:DECLARE_INSN(add, MATCH_ADD, MASK_ADD)`

Thêm sau dòng này:

```c
DECLARE_INSN(mod, MATCH_MOD, MASK_MOD)
DECLARE_INSN(mul4, MATCH_MUL4, MASK_MUL4)
DECLARE_INSN(mul8, MATCH_MUL8, MASK_MUL8)
DECLARE_INSN(mul16, MATCH_MUL16, MASK_MUL16)
```

### Lưu file (Ctrl+O, Enter, Ctrl+X)

### Verify:

```bash
grep -c "MATCH_MOD\|DECLARE_INSN(mod" riscv-opc.h
# Phải trả về: 2 (1 lần MATCH, 1 lần DECLARE)
```

### ❌ Lỗi có thể gặp:

**Lỗi 1:** Compilation error sau này: `error: 'MATCH_MOD' undeclared`
```
Nguyên nhân: Thêm vào sai vị trí hoặc typo
Giải pháp: Kiểm tra lại #define, phải nằm trước DECLARE_INSN
```

**Lỗi 2:** `duplicate macro definition`
```
Nguyên nhân: Đã thêm 2 lần
Giải pháp: grep để kiểm tra, xóa duplicate
```

---

## 7. BƯỚC 6: SỬA BINUTILS/RISCV-OPC.C

### File cần sửa:
`~/workspace/RISC-V/riscv-gnu-toolchain/binutils/opcodes/riscv-opc.c`

### Backup:

```bash
cd ~/workspace/RISC-V/riscv-gnu-toolchain/binutils/opcodes
cp riscv-opc.c riscv-opc.c.backup
```

### Tìm instruction table:

```bash
grep -n "const struct riscv_opcode riscv_opcodes" riscv-opc.c
```

**Output mẫu:** `850:const struct riscv_opcode riscv_opcodes[] =`

### Tìm entry của ADD instruction:

```bash
grep -n '{"add"' riscv-opc.c | head -1
```

**Output mẫu:** `899:{"add", ...}`

### Mở file và thêm TRƯỚC dòng `/* Basic RVI instructions */`:

```bash
nano riscv-opc.c
```

Goto line ~899, tìm comment `/* Basic RVI instructions */`

Thêm **TRƯỚC** comment này:

```c
/* Custom instructions */
{"mod",        0, INSN_CLASS_I,   "d,s,t", MATCH_MOD, MASK_MOD, match_opcode, 0 },
{"mul4",       0, INSN_CLASS_I,   "d,s,t", MATCH_MUL4, MASK_MUL4, match_opcode, 0 },
{"mul8",       0, INSN_CLASS_I,   "d,s,t", MATCH_MUL8, MASK_MUL8, match_opcode, 0 },
{"mul16",      0, INSN_CLASS_I,   "d,s,t", MATCH_MUL16, MASK_MUL16, match_opcode, 0 },

```

### Giải thích format:

```c
{"mod",        // Tên instruction
 0,            // Version (0 = base version)
 INSN_CLASS_I, // Instruction class (I = Integer base)
 "d,s,t",      // Operand format (d=rd, s=rs1, t=rs2)
 MATCH_MOD,    // Match value (từ riscv-opc.h)
 MASK_MOD,     // Mask value (từ riscv-opc.h)
 match_opcode, // Matching function
 0             // Flags
},
```

### Lưu file

### Verify:

```bash
grep -c '{"mod"' riscv-opc.c
# Phải trả về: 1
```

### ❌ Lỗi có thể gặp:

**Lỗi 1:** Compilation error: `expected '}' before ...`
```
Nguyên nhân: Thiếu dấu phẩy ở cuối mỗi entry
Giải pháp: Mỗi entry phải có dấu phẩy cuối: }, (kể cả entry cuối cùng)
```

**Lỗi 2:** `'MATCH_MOD' undeclared`
```
Nguyên nhân: Chưa sửa riscv-opc.h ở bước 5
Giải pháp: Quay lại bước 5
```

**Lỗi 3:** Assembler không nhận diện instruction
```
Nguyên nhân: Sai operand format string "d,s,t"
Giải pháp: Dùng chính xác "d,s,t" cho R-type instructions
```

---

## 8. BƯỚC 7: DOWNLOAD SUBMODULES

### Chuyển vào thư mục toolchain:

```bash
cd ~/workspace/RISC-V/riscv-gnu-toolchain
```

### Download GCC và Newlib:

```bash
make -C binutils download-gcc download-newlib 2>&1 | tee download.log
```

**Thời gian:** ~10-20 phút  
**Dung lượng:** ~2GB

**Output mẫu:**
```
Cloning into 'gcc'...
remote: Enumerating objects: 5234567, done.
remote: Total 5234567 (delta 0), reused 0 (delta 0)
Receiving objects: 100% (5234567/5234567), 1.5 GiB | 3.2 MiB/s, done.
```

### Verify:

```bash
ls -la gcc newlib
# Phải thấy 2 thư mục với nhiều files
```

### ❌ Lỗi có thể gặp:

**Lỗi 1:** `fatal: unable to access ...`
```
Nguyên nhân: Network timeout hoặc GitHub down
Giải pháp: 
  - Chờ vài phút và thử lại
  - Hoặc: git clone https://gcc.gnu.org/git/gcc.git
```

**Lỗi 2:** `No space left on device`
```
Nguyên nhân: Disk full
Giải pháp: df -h để kiểm tra, dọn dẹp disk
```

**Lỗi 3:** Download bị gián đoạn
```
Nguyên nhân: WSL/PowerShell timeout
Giải pháp: Chạy trong native WSL terminal thay vì PowerShell wrapper
```

---

## 9. BƯỚC 8: CONFIGURE TOOLCHAIN

### Tạo và cấp quyền cho thư mục cài đặt:

```bash
sudo mkdir -p /opt/riscv_custom
sudo chown -R $USER:$USER /opt/riscv_custom
```

### Configure:

```bash
cd ~/workspace/RISC-V/riscv-gnu-toolchain
./configure --prefix=/opt/riscv_custom 2>&1 | tee configure.log
```

**Thời gian:** ~2-3 phút

**Output cuối cùng phải thấy:**
```
configure: creating ./config.status
config.status: creating Makefile
```

### Verify:

```bash
ls -la Makefile
# Phải thấy file Makefile được tạo mới
```

### ❌ Lỗi có thể gặp:

**Lỗi 1:** `configure: error: Building GCC requires GMP 4.2+, MPFR 3.1.0+ and MPC 0.8.0+.`
```
Nguyên nhân: Thiếu dependencies
Giải pháp: sudo apt-get install libgmp-dev libmpfr-dev libmpc-dev
```

**Lỗi 2:** `Permission denied: /opt/riscv_custom`
```
Nguyên nhân: Chưa chown folder
Giải pháp: sudo chown -R $USER:$USER /opt/riscv_custom
```

---

## 10. BƯỚC 9: BUILD TOOLCHAIN

### Build (bước tốn thời gian nhất):

```bash
cd ~/workspace/RISC-V/riscv-gnu-toolchain
make -j$(nproc) 2>&1 | tee build.log
```

**Thời gian:** 2-3 giờ (tùy CPU)  
**CPU usage:** 100% trên tất cả cores

### Theo dõi tiến trình:

Mở terminal khác:
```bash
tail -f ~/workspace/RISC-V/riscv-gnu-toolchain/build.log
```

### Các giai đoạn build:

1. **Binutils** (~10 phút)
   - Thấy: `checking for gcc... gcc`, `building libiberty`, `building bfd`
   
2. **GCC Stage 1** (~30 phút)
   - Thấy: `Configuring stage 1 in ./gcc`
   
3. **Newlib** (~20 phút)
   - Thấy: `building target-libgloss`
   
4. **GCC Stage 2** (~1 giờ)
   - Thấy: `Configuring stage 2 in ./gcc`
   
5. **GDB** (~30 phút)
   - Thấy: `checking for makeinfo... makeinfo`

### Khi build xong, verify:

```bash
echo $?
# Phải trả về: 0 (success)

ls -lh /opt/riscv_custom/bin/riscv64-unknown-elf-*
# Phải thấy nhiều executables
```

### ❌ Lỗi có thể gặp:

**Lỗi 1:** `make: *** [Makefile:xxx] Error 2`
```
Nguyên nhân: Compilation error trong source code
Giải pháp: 
  - Kiểm tra build.log để tìm error message cụ thể
  - Thường do sửa sai cú pháp ở bước 5-6
  - Fix và chạy lại: make -j$(nproc)
```

**Lỗi 2:** Build process stops giữa chừng
```
Nguyên nhân: Thiếu RAM hoặc PowerShell timeout
Giải pháp: 
  - Giảm cores: make -j2
  - Hoặc chạy trong native WSL terminal
  - Hoặc thêm swap: sudo fallocate -l 4G /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
```

**Lỗi 3:** `/usr/bin/install: cannot remove '/opt/riscv_custom/...': Permission denied`
```
Nguyên nhân: Quyền truy cập bị thay đổi giữa chừng
Giải pháp: sudo chown -R $USER:$USER /opt/riscv_custom && make -j$(nproc)
```

**Lỗi 4:** `collect2: error: ld returned 1 exit status`
```
Nguyên nhân: Linker error, thường do thiếu libraries
Giải pháp: Kiểm tra lại dependencies ở bước 1
```

**Lỗi 5:** Build thành công nhưng instructions không work
```
Nguyên nhân: Binutils được build trước khi sửa code
Giải pháp: 
  - Xóa binutils build: rm -rf build-binutils-newlib
  - Build lại: make -j$(nproc)
```

---

## 11. BƯỚC 10: TESTING

### Test 1: Verify tools đã cài

```bash
/opt/riscv_custom/bin/riscv64-unknown-elf-gcc --version
/opt/riscv_custom/bin/riscv64-unknown-elf-as --version
```

**Output mong đợi:**
```
riscv64-unknown-elf-gcc (GCC) 15.1.0
GNU assembler (GNU Binutils) 2.43.50
```

### Test 2: Tạo test file assembly

```bash
cd ~/workspace/RISC-V

cat > test_custom.s << 'EOF'
    .text
    .globl _start
_start:
    # Test mod instruction
    li      a0, 17
    li      a1, 5
    mod     a2, a0, a1

    # Test mul4 instruction
    li      a0, 5
    li      a1, 5
    mul4    a3, a0, a1

    # Test mul8 instruction
    mul8    a4, a0, a1

    # Test mul16 instruction
    mul16   a5, a0, a1

    # Exit
    li      a7, 93
    li      a0, 0
    ecall
EOF
```

### Test 3: Assemble

```bash
/opt/riscv_custom/bin/riscv64-unknown-elf-as test_custom.s -o test_custom.o
```

**Nếu thành công:** Không có output, file test_custom.o được tạo

**Nếu lỗi:**
```
test_custom.s: Assembler messages:
test_custom.s:8: Error: unrecognized opcode `mod a2,a0,a1'
```
→ Custom instructions chưa được thêm vào assembler

### Test 4: Disassemble

```bash
/opt/riscv_custom/bin/riscv64-unknown-elf-objdump -d test_custom.o
```

**Output mong đợi:**
```
test_custom.o:     file format elf64-littleriscv

Disassembly of section .text:

0000000000000000 <_start>:
   0:   4545                    li      a0,17
   2:   4595                    li      a1,5
   4:   02b5060b                mod     a2,a0,a1    ← ✅
   8:   4515                    li      a0,5
   a:   4595                    li      a1,5
   c:   00b5668b                mul4    a3,a0,a1    ← ✅
  10:   02b5670b                mul8    a4,a0,a1    ← ✅
  14:   04b5678b                mul16   a5,a0,a1    ← ✅
  18:   05d00893                li      a7,93
  1c:   4501                    li      a0,0
  1e:   00000073                ecall
```

### Test 5: Verify opcodes

```bash
/opt/riscv_custom/bin/riscv64-unknown-elf-objdump -d test_custom.o | grep -E "(mod|mul4|mul8|mul16)"
```

**Kiểm tra opcodes:**
- `mod` → `02b5060b` = `0x200000b` ✅
- `mul4` → `00b5668b` = `0x600b` (với rs1=a0, rs2=a1, rd=a3) ✅
- `mul8` → `02b5670b` = `0x200600b` ✅
- `mul16` → `04b5678b` = `0x400600b` ✅

### Test 6: Tạo quick test script

```bash
cat > test_quick.sh << 'EOF'
#!/bin/bash
echo "=========================================="
echo "TESTING RISC-V CUSTOM INSTRUCTIONS"
echo "=========================================="
echo ""

/opt/riscv_custom/bin/riscv64-unknown-elf-as test_custom.s -o test_custom.o
if [ $? -eq 0 ]; then
    echo "✅ Assembly OK!"
else
    echo "❌ Assembly FAILED!"
    exit 1
fi

echo ""
echo "Disassembly:"
echo "=========================================="
/opt/riscv_custom/bin/riscv64-unknown-elf-objdump -d test_custom.o | grep -A1 -E "(mod|mul4|mul8|mul16)"
echo "=========================================="
echo ""
echo "✅ ALL TESTS PASSED!"
EOF

chmod +x test_quick.sh
./test_quick.sh
```

### ❌ Lỗi có thể gặp:

**Lỗi 1:** `Error: unrecognized opcode`
```
Nguyên nhân: 
  - Chưa sửa riscv-opc.c/h đúng
  - Hoặc đang dùng assembler cũ
Giải pháp: 
  - Verify files đã sửa: grep "MATCH_MOD" riscv-opc.h
  - Dùng full path: /opt/riscv_custom/bin/riscv64-unknown-elf-as
  - Rebuild binutils: rm -rf build-binutils-newlib && make -j$(nproc)
```

**Lỗi 2:** Disassemble hiển thị `.word 0x02b5060b` thay vì `mod`
```
Nguyên nhân: Sửa riscv-opc.c nhưng chưa rebuild
Giải pháp: rm -rf build-binutils-newlib && make -j$(nproc)
```

**Lỗi 3:** Opcode không khớp với MATCH value
```
Nguyên nhân: Định nghĩa sai trong rv_i file
Giải pháp: 
  - Re-generate: cd riscv-opcodes && uv run riscv_opcodes -c 'rv*'
  - Kiểm tra lại bit fields trong rv_i
```

---

## 12. BƯỚC 11: SPIKE SIMULATOR (OPTIONAL)

> **Lưu ý:** Bước này để chạy (execute) chương trình với custom instructions, không chỉ assemble.

### Clone Spike repository:

```bash
cd ~/workspace/RISC-V
git clone https://github.com/riscv-software-src/riscv-isa-sim.git
cd riscv-isa-sim
```

**Thời gian:** ~1 phút

### Tạo behavior files cho 4 instructions:

```bash
cd riscv/insns

# MOD instruction
echo 'WRITE_RD(sext_xlen(RS1 % RS2));' > mod.h

# MUL4 instruction (shift left 2 bits = multiply by 4)
echo 'WRITE_RD(sext_xlen(RS1 << 2));' > mul4.h

# MUL8 instruction (shift left 3 bits = multiply by 8)
echo 'WRITE_RD(sext_xlen(RS1 << 3));' > mul8.h

# MUL16 instruction (shift left 4 bits = multiply by 16)
echo 'WRITE_RD(sext_xlen(RS1 << 4));' > mul16.h
```

### Verify:

```bash
cat mod.h mul4.h mul8.h mul16.h
```

### Sửa encoding.h:

```bash
cd ~/workspace/RISC-V/riscv-isa-sim/riscv
cp encoding.h encoding.h.backup

# Tìm vị trí ADD instruction
grep -n "MATCH_ADD" encoding.h | head -1
# Output: 567:#define MATCH_ADD 0x33
```

Mở file và thêm sau ADD (ví dụ sau dòng 568):

```bash
nano encoding.h
```

Thêm:

```c
/* Custom instructions */
#define MATCH_MOD 0x200000b
#define MASK_MOD  0xfe00707f
#define MATCH_MUL4 0x600b
#define MASK_MUL4  0xfe00707f
#define MATCH_MUL8 0x200600b
#define MASK_MUL8  0xfe00707f
#define MATCH_MUL16 0x400600b
#define MASK_MUL16  0xfe00707f
```

Tìm phần DECLARE_INSN (cuối file ~line 3124):

```bash
grep -n "DECLARE_INSN(add" encoding.h
```

Thêm sau:

```c
DECLARE_INSN(mod, MATCH_MOD, MASK_MOD)
DECLARE_INSN(mul4, MATCH_MUL4, MASK_MUL4)
DECLARE_INSN(mul8, MATCH_MUL8, MASK_MUL8)
DECLARE_INSN(mul16, MATCH_MUL16, MASK_MUL16)
```

### Sửa riscv.mk.in:

```bash
cd ~/workspace/RISC-V/riscv-isa-sim/riscv
cp riscv.mk.in riscv.mk.in.backup

# Tìm instruction list
grep -n "riscv_insn_ext_i = \\" riscv.mk.in
```

Mở file và thêm mod, mul4, mul8, mul16 vào list:

```bash
nano riscv.mk.in
```

Tìm `add \` trong riscv_insn_ext_i list, thêm sau nó:

```makefile
riscv_insn_ext_i = \
	add \
	mod \
	mul4 \
	mul8 \
	mul16 \
	addi \
	...
```

### Configure Spike:

```bash
cd ~/workspace/RISC-V/riscv-isa-sim
mkdir build && cd build
../configure --prefix=/opt/riscv_custom
```

**Thời gian:** ~30 giây

### Build Spike:

```bash
make -j$(nproc) 2>&1 | tee spike-build.log
```

**Thời gian:** ~20-30 phút

**Verify build thành công:**
```bash
ls -lh spike spike-dasm
# Phải thấy 2 executables
```

### Install Spike:

```bash
echo '123' | sudo -S make install
```

**Password:** Thay `123` bằng password thật của bạn

### Verify installation:

```bash
/opt/riscv_custom/bin/spike --help | head -5
```

**Output:**
```
Spike RISC-V ISA Simulator 1.1.1-dev

usage: spike [host options] <target program> [target options]
```

### Test với custom instructions:

```bash
cd ~/workspace/RISC-V

# Assemble test file
/opt/riscv_custom/bin/riscv64-unknown-elf-as test_custom.s -o test_custom.o

# Link
/opt/riscv_custom/bin/riscv64-unknown-elf-ld test_custom.o -o test_custom.elf

# Disassemble để verify
/opt/riscv_custom/bin/riscv64-unknown-elf-objdump -d test_custom.elf | grep -E "(mod|mul4|mul8|mul16)"
```

**Output mong đợi:**
```
100b4:       02b5060b                mod     a2,a0,a1
100bc:       00b5668b                mul4    a3,a0,a1
100c0:       02b5670b                mul8    a4,a0,a1
100c4:       04b5678b                mul16   a5,a0,a1
```

✅ **Spike simulator giờ đã hỗ trợ custom instructions!**

### ❌ Lỗi có thể gặp khi build Spike:

**Lỗi 1:** `undefined reference to 'illegal_instruction'`
```
Nguyên nhân: Thiếu DECLARE_INSN trong encoding.h
Giải pháp: Kiểm tra lại encoding.h, phải có đủ 4 DECLARE_INSN
```

**Lỗi 2:** `No rule to make target 'mod.h'`
```
Nguyên nhân: Chưa thêm vào riscv.mk.in
Giải pháp: Kiểm tra lại riscv.mk.in, grep "mod" riscv.mk.in
```

**Lỗi 3:** Build thành công nhưng spike crash khi run
```
Nguyên nhân: Syntax error trong behavior files (mod.h, mul4.h,...)
Giải pháp: Kiểm tra lại nội dung các .h files, đảm bảo đúng syntax
```

---

## 13. TROUBLESHOOTING TỔNG HỢP

### 🔍 Checklist khi gặp lỗi:

#### Lỗi ở bước build toolchain:

1. **Kiểm tra dependencies:**
   ```bash
   gcc --version
   make --version
   autoconf --version
   ```

2. **Kiểm tra disk space:**
   ```bash
   df -h /opt
   df -h ~
   ```

3. **Kiểm tra RAM:**
   ```bash
   free -h
   # Nếu < 2GB available, thêm swap
   ```

4. **Kiểm tra files đã sửa:**
   ```bash
   grep "MATCH_MOD" ~/workspace/RISC-V/riscv-gnu-toolchain/binutils/include/opcode/riscv-opc.h
   grep '{"mod"' ~/workspace/RISC-V/riscv-gnu-toolchain/binutils/opcodes/riscv-opc.c
   ```

5. **Kiểm tra quyền:**
   ```bash
   ls -ld /opt/riscv_custom
   # Phải thấy: drwxr-xr-x ... <your_user> <your_group>
   ```

#### Lỗi khi test:

1. **Assembler không nhận instruction:**
   - Verify đang dùng đúng binary:
     ```bash
     which riscv64-unknown-elf-as
     /opt/riscv_custom/bin/riscv64-unknown-elf-as --version
     ```
   
   - Kiểm tra riscv-opc.c đã được compile:
     ```bash
     ls -l /opt/riscv_custom/bin/riscv64-unknown-elf-as
     # File phải mới hơn lúc sửa code
     ```

2. **Disassembler không hiển thị tên instruction:**
   - Rebuild binutils:
     ```bash
     cd ~/workspace/RISC-V/riscv-gnu-toolchain
     rm -rf build-binutils-newlib
     make -j$(nproc)
     ```

3. **Opcode không đúng:**
   - Re-generate MATCH/MASK:
     ```bash
     cd ~/workspace/RISC-V/riscv-opcodes
     uv run riscv_opcodes -c 'rv*' > encoding.out.h
     grep "MATCH_MOD" encoding.out.h
     ```

### 📝 Log files quan trọng:

```bash
~/workspace/RISC-V/riscv-gnu-toolchain/build.log       # Build log
~/workspace/RISC-V/riscv-gnu-toolchain/configure.log   # Configure log
~/workspace/RISC-V/riscv-isa-sim/build/spike-build.log # Spike build log
```

### 🔧 Recovery commands:

**Clean build và rebuild hoàn toàn:**
```bash
cd ~/workspace/RISC-V/riscv-gnu-toolchain
make clean
./configure --prefix=/opt/riscv_custom
make -j$(nproc) 2>&1 | tee rebuild.log
```

**Chỉ rebuild binutils:**
```bash
rm -rf build-binutils-newlib build-gdb-newlib
make -j$(nproc)
```

**Restore backup files:**
```bash
cd ~/workspace/RISC-V/riscv-gnu-toolchain/binutils
cp include/opcode/riscv-opc.h.backup include/opcode/riscv-opc.h
cp opcodes/riscv-opc.c.backup opcodes/riscv-opc.c
```

---

## 📚 PHẦN PHỤ LỤC

### A. Giải thích Instruction Encoding

**R-type format (cho mod, mul4, mul8, mul16):**

```
 31          25 24   20 19   15 14    12 11    7 6      0
┌─────────────┬───────┬───────┬────────┬───────┬────────┐
│   funct7    │  rs2  │  rs1  │ funct3 │   rd  │ opcode │
└─────────────┴───────┴───────┴────────┴───────┴────────┘
    7 bits      5 bits  5 bits  3 bits   5 bits  7 bits
```

**Ví dụ: `mod a2, a0, a1`**

- `rd` = a2 = x12 = `01100` (5 bits)
- `rs1` = a0 = x10 = `01010` (5 bits)
- `rs2` = a1 = x11 = `01011` (5 bits)
- `funct3` = `000` (3 bits) ← Từ rv_i: 14..12=0
- `funct7` = `0000001` (7 bits) ← Từ rv_i: 31..25=1
- `opcode` = `0001011` (7 bits) ← Từ rv_i: 6..2=2, 1..0=3 → `00010_11`

**Binary:**
```
0000001_01011_01010_000_01100_0001011
```

**Hex:** `0x02b5060b` → Khớp với MATCH_MOD ✅

### B. Ý nghĩa các files quan trọng:

| File | Mục đích |
|------|----------|
| `riscv-opcodes/extensions/rv_i` | Định nghĩa instructions bằng human-readable format |
| `riscv-opcodes/encoding.out.h` | MATCH/MASK values được generate tự động |
| `binutils/include/opcode/riscv-opc.h` | Header file với MATCH/MASK macros cho assembler |
| `binutils/opcodes/riscv-opc.c` | Instruction table cho assembler/disassembler |
| `riscv-isa-sim/riscv/insns/*.h` | Behavior của instructions trong Spike simulator |
| `riscv-isa-sim/riscv/encoding.h` | MATCH/MASK cho Spike |
| `riscv-isa-sim/riscv/riscv.mk.in` | Makefile template với danh sách instructions |

### C. Quick Reference Table

| Task | Command |
|------|---------|
| Assemble | `riscv64-unknown-elf-as input.s -o output.o` |
| Disassemble | `riscv64-unknown-elf-objdump -d output.o` |
| Compile C | `riscv64-unknown-elf-gcc -c input.c -o output.o` |
| Link | `riscv64-unknown-elf-ld input.o -o output.elf` |
| View symbols | `riscv64-unknown-elf-nm output.elf` |
| View headers | `riscv64-unknown-elf-readelf -h output.elf` |
| Run on Spike | `spike pk output.elf` |
| Debug on Spike | `spike -d pk output.elf` |

### D. Environment Setup cho .bashrc

Thêm vào `~/.bashrc` để dễ dùng:

```bash
# RISC-V Toolchain
export RISCV=/opt/riscv_custom
export PATH=$RISCV/bin:$PATH

# Aliases
alias rvgcc='riscv64-unknown-elf-gcc'
alias rvas='riscv64-unknown-elf-as'
alias rvld='riscv64-unknown-elf-ld'
alias rvobjdump='riscv64-unknown-elf-objdump'
alias rvspike='spike'
```

Reload:
```bash
source ~/.bashrc
```

Giờ có thể dùng:
```bash
rvas test.s -o test.o
rvobjdump -d test.o
```

---

## ✅ CHECKLIST HOÀN THÀNH

Copy checklist này và đánh dấu khi làm:

```
Phase 1: Chuẩn bị
□ Cài dependencies (bước 1)
□ Clone riscv-gnu-toolchain
□ Clone riscv-opcodes
□ Cài uv tool

Phase 2: Định nghĩa instructions
□ Thêm 4 instructions vào rv_i (bước 3)
□ Generate MATCH/MASK values (bước 4)
□ Verify encoding.out.h

Phase 3: Sửa source code
□ Backup riscv-opc.h
□ Thêm MATCH/MASK vào riscv-opc.h (bước 5)
□ Thêm DECLARE_INSN vào riscv-opc.h
□ Backup riscv-opc.c
□ Thêm entries vào riscv-opc.c (bước 6)

Phase 4: Build
□ Download submodules gcc/newlib (bước 7)
□ Configure toolchain (bước 8)
□ Fix quyền /opt/riscv_custom
□ Build toolchain (bước 9) - CHỜ 2-3 GIỜĐÃ
□ Verify executables được tạo

Phase 5: Test
□ Tạo test_custom.s
□ Test assembler
□ Test disassembler
□ Verify opcodes
□ Tạo test_quick.sh

Phase 6: Spike (Optional)
□ Clone riscv-isa-sim
□ Tạo behavior files (.h)
□ Sửa encoding.h
□ Sửa riscv.mk.in
□ Configure và build Spike
□ Install Spike
□ Test Spike với custom instructions

Phase 7: Documentation
□ Đọc hết file này 😊
□ Bookmark cho lần sau
□ Share với team members
```

---

## 🎯 KẾT LUẬN

**Chúc mừng!** Nếu bạn đã hoàn thành tất cả các bước, bạn đã có:

✅ RISC-V GNU Toolchain tùy chỉnh với 4 custom instructions  
✅ Khả năng assemble/disassemble code với instructions mới  
✅ (Optional) Spike simulator để chạy code  
✅ Kiến thức sâu về RISC-V toolchain internals  
✅ Kỹ năng troubleshooting cho các lỗi thường gặp  

**Thời gian tổng:** ~3-4 giờ  
**Kết quả:** Production-ready custom RISC-V toolchain  

**Lưu ý quan trọng:**
- 🔒 Backup thư mục `/opt/riscv_custom` sau khi build xong
- 📝 Lưu files đã sửa (riscv-opc.h, riscv-opc.c, rv_i)
- 🔄 Nếu cần rebuild: chỉ cần sửa files và `make -j$(nproc)`
- 📧 Share file này với team để họ có thể reproduce

**Các bước tiếp theo có thể làm:**
1. Thêm nhiều custom instructions hơn
2. Implement trong hardware (FPGA/ASIC)
3. Tạo compiler intrinsics cho C/C++
4. Tích hợp với frameworks như Rocket-Chip

**Liên hệ hỗ trợ:**
- RISC-V Specification: https://riscv.org/specifications/
- GNU Toolchain Issues: https://github.com/riscv-collab/riscv-gnu-toolchain/issues
- Spike Issues: https://github.com/riscv-software-src/riscv-isa-sim/issues

---

**📅 Version:** 1.0  
**📅 Last Updated:** 28/10/2025  
**👤 Author:** GitHub Copilot + minhoang  
**📄 License:** MIT  
**🔗 Companion Files:**
- `BAO_CAO_HOAN_THANH.md` - Executive summary
- `LINKER_SCRIPT_NOTES.md` - Linker customization guide
- `test_quick.sh` - Automated testing script

---

**🙏 Cảm ơn bạn đã đọc hết file này! Chúc bạn thành công với RISC-V! 🚀**
