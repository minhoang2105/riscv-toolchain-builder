# 🚀 ACTION PLAN: RISC-V AES-256 ACCELERATOR

**Mục tiêu:** Xây dựng PicoRV32 với AES-256 custom instructions, deploy lên Tang Mega 60K FPGA  
**Thời gian:** 5-7 ngày (làm xuyên suốt)  
**Ngày bắt đầu:** 2025-10-28  
**Trạng thái:** 🟡 IN PROGRESS

---

## 📊 TỔNG QUAN TIẾN ĐỘ

```
[▓▓▓░░░░░░░░░░░░░░░░░] 15% Complete

Phase 1: Toolchain Setup        [░░░░░░░░░░] 0%  ← BẮT ĐẦU TỪ ĐÂY
Phase 2: Custom Instructions     [░░░░░░░░░░] 0%
Phase 3: Hardware Design         [░░░░░░░░░░] 0%
Phase 4: PicoRV32 Integration    [░░░░░░░░░░] 0%
Phase 5: FPGA Deployment         [░░░░░░░░░░] 0%
Phase 6: Firmware & Testing      [░░░░░░░░░░] 0%
```

---

## ⚡ PHASE 1: TOOLCHAIN SETUP (2-3 giờ)

### 🎯 Mục tiêu
Rebuild RISC-V toolchain từ RV64GC → **RV32IMC** (32-bit cho PicoRV32)

### 📋 Tasks

#### ✅ Task 1.1: Backup toolchain cũ (5 phút)
- [ ] Backup RV64GC toolchain
- [ ] Tạo thư mục mới cho RV32IMC

**Commands:**
```bash
cd /home/minhoang/workspace/RISC-V

# Backup toolchain cũ (nếu cần)
if [ -d "riscv-gnu-toolchain-rv64" ]; then
    mv riscv-gnu-toolchain riscv-gnu-toolchain-rv64-backup
fi

# Tạo thư mục làm việc
mkdir -p toolchain_logs
```

**Verify:**
```bash
ls -la | grep riscv-gnu-toolchain
# Nếu thấy backup → OK
```

---

#### ✅ Task 1.2: Clone fresh toolchain (10 phút)
- [ ] Clone riscv-gnu-toolchain repo
- [ ] Checkout stable branch

**Commands:**
```bash
cd /home/minhoang/workspace/RISC-V

# Clone nếu chưa có
if [ ! -d "riscv-gnu-toolchain" ]; then
    git clone https://github.com/riscv-collab/riscv-gnu-toolchain.git
fi

cd riscv-gnu-toolchain

# Checkout stable tag (2024.09.03 release)
git checkout 2024.09.03

# Update submodules
git submodule update --init --recursive
```

**Verify:**
```bash
git status
# Nên thấy: HEAD detached at 2024.09.03
ls -la
# Nên thấy: binutils/, gcc/, newlib/, gdb/
```

---

#### ✅ Task 1.3: Configure cho RV32IMC (5 phút)
- [ ] Tạo build directory
- [ ] Configure với đúng arch và ABI

**Commands:**
```bash
cd /home/minhoang/workspace/RISC-V/riscv-gnu-toolchain

# Tạo quyền cho /opt
sudo mkdir -p /opt/riscv32_aes
sudo chown -R $USER:$USER /opt/riscv32_aes

# Configure
./configure \
    --prefix=/opt/riscv32_aes \
    --with-arch=rv32imc \
    --with-abi=ilp32 \
    --enable-multilib

# Lưu log
echo "Configured at: $(date)" > ../toolchain_logs/configure.log
```

**Verify:**
```bash
ls -la Makefile
# Nên thấy Makefile được tạo

grep "rv32imc" Makefile
# Nên thấy rv32imc trong config
```

---

#### ✅ Task 1.4: Build toolchain (2-3 giờ) ⏱️
- [ ] Build binutils, gcc, newlib
- [ ] Monitor progress

**Commands:**
```bash
cd /home/minhoang/workspace/RISC-V/riscv-gnu-toolchain

# Start build (sử dụng tất cả cores)
nproc  # Xem có bao nhiêu cores
make -j$(nproc) 2>&1 | tee ../toolchain_logs/build.log

# Nếu muốn giảm cores để tránh quá nóng:
# make -j4 2>&1 | tee ../toolchain_logs/build.log
```

**⚠️ Troubleshooting:**
```bash
# Nếu gặp lỗi permission:
sudo chown -R $USER:$USER /opt/riscv32_aes

# Nếu gặp lỗi missing dependencies:
sudo apt-get update
sudo apt-get install -y autoconf automake autotools-dev curl \
    python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential \
    bison flex texinfo gperf libtool patchutils bc zlib1g-dev \
    libexpat-dev ninja-build

# Nếu build bị dừng giữa chừng:
make -j$(nproc)  # Tiếp tục build
```

**Verify (sau khi build xong):**
```bash
# Check executables
ls -lh /opt/riscv32_aes/bin/

# Test compiler
/opt/riscv32_aes/bin/riscv32-unknown-elf-gcc --version
# Nên thấy: riscv32-unknown-elf-gcc ... 14.2.0 hoặc tương tự

# Test assembler
/opt/riscv32_aes/bin/riscv32-unknown-elf-as --version

# Test objdump
/opt/riscv32_aes/bin/riscv32-unknown-elf-objdump --version
```

---

#### ✅ Task 1.5: Add to PATH (2 phút)
- [ ] Export PATH
- [ ] Test từ bất kỳ đâu

**Commands:**
```bash
# Add to ~/.bashrc
echo 'export PATH="/opt/riscv32_aes/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Hoặc nếu dùng zsh:
# echo 'export PATH="/opt/riscv32_aes/bin:$PATH"' >> ~/.zshrc
# source ~/.zshrc
```

**Verify:**
```bash
which riscv32-unknown-elf-gcc
# Nên thấy: /opt/riscv32_aes/bin/riscv32-unknown-elf-gcc

riscv32-unknown-elf-gcc --version
# Không cần gõ full path nữa
```

---

#### ✅ Task 1.6: Test với simple program (5 phút)
- [ ] Viết test.c
- [ ] Compile và verify

**Commands:**
```bash
cd /home/minhoang/workspace/RISC-V
mkdir -p tests
cd tests

# Tạo test file
cat > test.c << 'EOF'
int main() {
    int a = 5;
    int b = 10;
    return a + b;
}
EOF

# Compile
riscv32-unknown-elf-gcc -march=rv32imc -mabi=ilp32 -o test.elf test.c

# Disassemble
riscv32-unknown-elf-objdump -d test.elf > test.dis

# Xem kết quả
cat test.dis | grep "<main>:" -A 20
```

**Verify:**
```bash
file test.elf
# Nên thấy: ELF 32-bit LSB executable, UCB RISC-V

readelf -h test.elf | grep Machine
# Nên thấy: Machine: RISC-V
```

---

### 🎉 Checkpoint Phase 1
```bash
# Checklist:
[ ] Toolchain RV32IMC compiled thành công
[ ] Có thể chạy riscv32-unknown-elf-gcc từ bất kỳ đâu
[ ] Test program compile và disassemble OK
[ ] File test.elf là RV32 (32-bit)

# Nếu tất cả đều OK → Chuyển sang Phase 2
```

---

## ⚡ PHASE 2: CUSTOM AES INSTRUCTIONS (2-3 giờ)

### 🎯 Mục tiêu
Thêm 5 custom instructions cho AES vào toolchain

### 📋 Tasks

#### ✅ Task 2.1: Clone riscv-opcodes (5 phút)
- [ ] Clone repo
- [ ] Install UV package manager

**Commands:**
```bash
cd /home/minhoang/workspace/RISC-V

# Clone riscv-opcodes (nếu chưa có)
if [ ! -d "riscv-opcodes" ]; then
    git clone https://github.com/riscv/riscv-opcodes.git
fi

cd riscv-opcodes

# Install UV (nếu chưa có)
if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source $HOME/.cargo/env
fi
```

**Verify:**
```bash
uv --version
# Nên thấy version number

ls extensions/rv_i
# Nên thấy file rv_i
```

---

#### ✅ Task 2.2: Định nghĩa AES instructions (10 phút)
- [ ] Sửa file rv_i
- [ ] Thêm 5 AES instructions

**Commands:**
```bash
cd /home/minhoang/workspace/RISC-V/riscv-opcodes

# Backup original
cp extensions/rv_i extensions/rv_i.backup

# Thêm AES instructions vào cuối file rv_i
cat >> extensions/rv_i << 'EOF'

# AES-256 Custom Instructions
aes_subbytes    rd rs1      31..25=1  14..12=0 6..2=0x0e 1..0=3
aes_mixcol      rd rs1      31..25=2  14..12=0 6..2=0x0e 1..0=3
aes_keyexp      rd rs1 rs2  31..25=3  14..12=0 6..2=0x0e 1..0=3
aes_invsubbytes rd rs1      31..25=4  14..12=0 6..2=0x0e 1..0=3
aes_invmixcol   rd rs1      31..25=5  14..12=0 6..2=0x0e 1..0=3
EOF
```

**Verify:**
```bash
tail -10 extensions/rv_i
# Nên thấy 5 dòng AES instructions ở cuối

# Kiểm tra format
grep "aes_" extensions/rv_i
```

---

#### ✅ Task 2.3: Generate MATCH/MASK values (5 phút)
- [ ] Chạy riscv_opcodes tool
- [ ] Extract AES opcodes

**Commands:**
```bash
cd /home/minhoang/workspace/RISC-V/riscv-opcodes

# Generate opcodes
uv run riscv_opcodes -c 'rv*' > encoding.out.h

# Extract AES opcodes
grep "MATCH_AES" encoding.out.h | tee ../aes_opcodes.txt
grep "MASK_AES" encoding.out.h | tee -a ../aes_opcodes.txt

# Display results
echo "=== AES OPCODES ==="
cat ../aes_opcodes.txt
```

**Verify:**
```bash
cat ../aes_opcodes.txt
# Nên thấy:
# #define MATCH_AES_SUBBYTES 0x...
# #define MASK_AES_SUBBYTES  0xfe00707f
# ... (10 dòng total: 5 MATCH + 5 MASK)
```

---

#### ✅ Task 2.4: Sửa binutils - riscv-opc.h (15 phút)
- [ ] Backup file gốc
- [ ] Thêm MATCH/MASK macros
- [ ] Thêm DECLARE_INSN

**Commands:**
```bash
cd /home/minhoang/workspace/RISC-V

# File cần sửa
OPC_H="riscv-gnu-toolchain/binutils/include/opcode/riscv-opc.h"

# Backup
cp "$OPC_H" "$OPC_H.backup"

# Lấy opcodes từ file đã generate
MATCH_AES_SUBBYTES=$(grep "MATCH_AES_SUBBYTES" aes_opcodes.txt | awk '{print $3}')
MASK_AES_SUBBYTES=$(grep "MASK_AES_SUBBYTES" aes_opcodes.txt | awk '{print $3}')
# ... (tương tự cho 4 instructions khác)

# Tạo file patch
cat > binutils_patch.txt << 'EOF'
/* AES-256 Custom Instructions */
#define MATCH_AES_SUBBYTES    0x200003b
#define MASK_AES_SUBBYTES     0xfe00707f
#define MATCH_AES_MIXCOL      0x400003b
#define MASK_AES_MIXCOL       0xfe00707f
#define MATCH_AES_KEYEXP      0x600003b
#define MASK_AES_KEYEXP       0xfe00707f
#define MATCH_AES_INVSUBBYTES 0x800003b
#define MASK_AES_INVSUBBYTES  0xfe00707f
#define MATCH_AES_INVMIXCOL   0xa00003b
#define MASK_AES_INVMIXCOL    0xfe00707f
EOF
```

**Sửa file thủ công (quan trọng!):**
```bash
# Mở file bằng editor
vim "$OPC_H"
# Hoặc: code "$OPC_H"

# Tìm dòng "#define MATCH_C_SWSP" (hoặc instruction cuối cùng)
# Thêm vào TRƯỚC dòng "#endif" cuối file:

/* AES-256 Custom Instructions - Added 2025-10-28 */
#define MATCH_AES_SUBBYTES    0x200003b
#define MASK_AES_SUBBYTES     0xfe00707f
#define MATCH_AES_MIXCOL      0x400003b
#define MASK_AES_MIXCOL       0xfe00707f
#define MATCH_AES_KEYEXP      0x600003b
#define MASK_AES_KEYEXP       0xfe00707f
#define MATCH_AES_INVSUBBYTES 0x800003b
#define MASK_AES_INVSUBBYTES  0xfe00707f
#define MATCH_AES_INVMIXCOL   0xa00003b
#define MASK_AES_INVMIXCOL    0xfe00707f

# Cuộn xuống cuối file, tìm các dòng DECLARE_INSN
# Thêm TRƯỚC #endif cuối cùng:

DECLARE_INSN(aes_subbytes, MATCH_AES_SUBBYTES, MASK_AES_SUBBYTES)
DECLARE_INSN(aes_mixcol, MATCH_AES_MIXCOL, MASK_AES_MIXCOL)
DECLARE_INSN(aes_keyexp, MATCH_AES_KEYEXP, MASK_AES_KEYEXP)
DECLARE_INSN(aes_invsubbytes, MATCH_AES_INVSUBBYTES, MASK_AES_INVSUBBYTES)
DECLARE_INSN(aes_invmixcol, MATCH_AES_INVMIXCOL, MASK_AES_INVMIXCOL)

# Lưu file (:wq trong vim)
```

**Verify:**
```bash
grep "AES" "$OPC_H"
# Nên thấy 10 dòng #define và 5 dòng DECLARE_INSN
```

---

#### ✅ Task 2.5: Sửa binutils - riscv-opc.c (15 phút)
- [ ] Backup file gốc
- [ ] Thêm vào instruction table

**Commands:**
```bash
cd /home/minhoang/workspace/RISC-V

# File cần sửa
OPC_C="riscv-gnu-toolchain/binutils/opcodes/riscv-opc.c"

# Backup
cp "$OPC_C" "$OPC_C.backup"

# Mở file
vim "$OPC_C"
# Hoặc: code "$OPC_C"

# Tìm dòng "const struct riscv_opcode riscv_opcodes[] ="
# Cuộn xuống tìm section "/* Terminate the list.  */"
# Thêm TRƯỚC dòng {0, 0, INSN_CLASS_NONE, 0, 0, 0, 0, 0}:

/* AES-256 Custom Instructions */
{"aes_subbytes",    0, INSN_CLASS_I, "d,s",   MATCH_AES_SUBBYTES, MASK_AES_SUBBYTES, match_opcode, 0},
{"aes_mixcol",      0, INSN_CLASS_I, "d,s",   MATCH_AES_MIXCOL, MASK_AES_MIXCOL, match_opcode, 0},
{"aes_keyexp",      0, INSN_CLASS_I, "d,s,t", MATCH_AES_KEYEXP, MASK_AES_KEYEXP, match_opcode, 0},
{"aes_invsubbytes", 0, INSN_CLASS_I, "d,s",   MATCH_AES_INVSUBBYTES, MASK_AES_INVSUBBYTES, match_opcode, 0},
{"aes_invmixcol",   0, INSN_CLASS_I, "d,s",   MATCH_AES_INVMIXCOL, MASK_AES_INVMIXCOL, match_opcode, 0},

# Lưu file
```

**Verify:**
```bash
grep "aes_" "$OPC_C"
# Nên thấy 5 dòng instruction entries
```

---

#### ✅ Task 2.6: Rebuild binutils (30-45 phút)
- [ ] Clean build cũ
- [ ] Rebuild binutils only

**Commands:**
```bash
cd /home/minhoang/workspace/RISC-V/riscv-gnu-toolchain

# Remove binutils build
rm -rf build-binutils-newlib

# Rebuild chỉ binutils (nhanh hơn full build)
make -j$(nproc) build-binutils-newlib 2>&1 | tee ../toolchain_logs/rebuild_binutils.log

# Copy sang install dir
make install-binutils-newlib
```

**Verify:**
```bash
# Test assembler nhận diện instruction mới
echo "aes_subbytes a0, a1" > /tmp/test_aes_insn.s
riscv32-unknown-elf-as /tmp/test_aes_insn.s -o /tmp/test_aes_insn.o

# Nếu không có lỗi → OK!

# Disassemble
riscv32-unknown-elf-objdump -d /tmp/test_aes_insn.o
# Nên thấy: aes_subbytes a0,a1
```

---

#### ✅ Task 2.7: Test assembly với AES instructions (10 phút)
- [ ] Viết test assembly
- [ ] Assemble và disassemble
- [ ] Verify opcodes

**Commands:**
```bash
cd /home/minhoang/workspace/RISC-V/tests

# Tạo test file
cat > test_aes_instructions.s << 'EOF'
.text
.globl _start

_start:
    # Load test data
    li      a0, 0x12345678
    li      a1, 0x9abcdef0
    li      a2, 0x11111111
    
    # Test AES instructions
    aes_subbytes    a3, a0      # S-box lookup
    aes_mixcol      a4, a1      # MixColumns
    aes_keyexp      a5, a0, a1  # Key expansion
    aes_invsubbytes a6, a3      # Inverse S-box
    aes_invmixcol   a7, a4      # Inverse MixColumns
    
    # End
    nop
EOF

# Assemble
riscv32-unknown-elf-as -march=rv32imc test_aes_instructions.s -o test_aes_instructions.o

# Disassemble
riscv32-unknown-elf-objdump -d test_aes_instructions.o > test_aes_instructions.dis

# View result
cat test_aes_instructions.dis
```

**Verify:**
```bash
grep "aes_" test_aes_instructions.dis
# Nên thấy:
#   ...:  0200b6b3    aes_subbytes a3,a0
#   ...:  0400b73b    aes_mixcol   a4,a1
#   ...:  06b507bb    aes_keyexp   a5,a0,a1
#   ...:  0800b83b    aes_invsubbytes a6,a3
#   ...:  0a00b8bb    aes_invmixcol a7,a4

# Check opcodes match MATCH values
grep "200003b\|400003b\|600003b\|800003b\|a00003b" test_aes_instructions.dis
```

---

### 🎉 Checkpoint Phase 2
```bash
# Checklist:
[ ] riscv-opcodes có 5 AES instructions
[ ] binutils rebuilt successfully
[ ] Assembler nhận diện aes_* instructions
[ ] Disassembler hiển thị đúng mnemonics
[ ] Opcodes match với MATCH values

# Nếu tất cả đều OK → Chuyển sang Phase 3
```

---

## ⚡ PHASE 3: HARDWARE DESIGN (1-2 ngày)

### 🎯 Mục tiêu
Thiết kế Verilog modules cho AES operations

### 📋 Tasks

#### ✅ Task 3.1: Setup hardware workspace (5 phút)
- [ ] Tạo thư mục hardware
- [ ] Clone PicoRV32

**Commands:**
```bash
cd /home/minhoang/workspace/RISC-V
mkdir -p hardware
cd hardware

# Clone PicoRV32
git clone https://github.com/YosysHQ/picorv32.git

# Tạo thư mục cho AES modules
mkdir -p aes_modules
mkdir -p testbenches
mkdir -p simulation_results
```

**Verify:**
```bash
ls picorv32/
# Nên thấy: picorv32.v, README.md, ...

ls -la
# Nên thấy: aes_modules/, testbenches/, picorv32/
```

---

#### ✅ Task 3.2: Tạo S-box lookup table (15 phút)
- [ ] Generate S-box hex file
- [ ] Generate inverse S-box

**Commands:**
```bash
cd /home/minhoang/workspace/RISC-V/hardware/aes_modules

# Tạo S-box table
cat > generate_sbox.py << 'EOF'
#!/usr/bin/env python3
"""Generate AES S-box and Inverse S-box"""

# AES S-box (from FIPS-197)
sbox = [
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
]

# Generate inverse S-box
inv_sbox = [0] * 256
for i in range(256):
    inv_sbox[sbox[i]] = i

# Write S-box
with open('sbox.hex', 'w') as f:
    for i, val in enumerate(sbox):
        f.write(f"{val:02x}\n")

# Write inverse S-box
with open('inv_sbox.hex', 'w') as f:
    for i, val in enumerate(inv_sbox):
        f.write(f"{val:02x}\n")

print("✅ Generated sbox.hex and inv_sbox.hex")
EOF

chmod +x generate_sbox.py
python3 generate_sbox.py
```

**Verify:**
```bash
wc -l sbox.hex inv_sbox.hex
# Nên thấy: 256 sbox.hex, 256 inv_sbox.hex

head -5 sbox.hex
# Nên thấy: 63, 7c, 77, 7b, f2
```

---

#### ✅ Task 3.3: Thiết kế AES SubBytes module (30 phút)
- [ ] Viết Verilog module
- [ ] Add comments

**File sẽ tạo:** `aes_subbytes_unit.v`

---

#### ✅ Task 3.4: Thiết kế AES MixColumns module (45 phút)
- [ ] Implement Galois Field multiplication
- [ ] Matrix multiplication

**File sẽ tạo:** `aes_mixcolumn_unit.v`

---

#### ✅ Task 3.5: Thiết kế Key Expansion module (45 phút)
- [ ] RotWord, SubWord functions
- [ ] Rcon handling

**File sẽ tạo:** `aes_keyexp_unit.v`

---

#### ✅ Task 3.6: Testbench cho từng module (1-2 giờ)
- [ ] Test S-box với FIPS vectors
- [ ] Test MixColumns
- [ ] Test Key Expansion

---

#### ✅ Task 3.7: Simulation với Icarus Verilog (30 phút)
- [ ] Install Icarus Verilog
- [ ] Run simulations
- [ ] Verify outputs

**Commands:**
```bash
# Install Icarus Verilog
sudo apt-get install -y iverilog gtkwave

# Compile và simulate
cd /home/minhoang/workspace/RISC-V/hardware/testbenches
iverilog -o sim_sbox testbench_sbox.v ../aes_modules/aes_subbytes_unit.v
vvp sim_sbox

# View waveform
gtkwave sbox.vcd
```

---

### 🎉 Checkpoint Phase 3
```bash
# Checklist:
[ ] S-box module implemented và tested
[ ] MixColumn module implemented và tested
[ ] KeyExp module implemented và tested
[ ] All simulations passed
[ ] Waveforms verified

# Nếu tất cả OK → Chuyển sang Phase 4
```

---

## ⚡ PHASE 4: PICORV32 INTEGRATION (1-2 ngày)

### 🎯 Mục tiêu
Tích hợp AES modules vào PicoRV32 core

### 📋 Tasks

#### ✅ Task 4.1: Study PicoRV32 architecture (1 giờ)
- [ ] Đọc picorv32.v
- [ ] Hiểu instruction decode
- [ ] Hiểu register file

**Commands:**
```bash
cd /home/minhoang/workspace/RISC-V/hardware/picorv32

# Xem cấu trúc module
grep "module picorv32" picorv32.v -A 100

# Tìm instruction decode section
grep "instr_" picorv32.v | head -20
```

---

#### ✅ Task 4.2: Modify instruction decoder (2 giờ)
- [ ] Add AES opcode detection
- [ ] Decode funct7 field

---

#### ✅ Task 4.3: Instantiate AES modules (1 giờ)
- [ ] Add AES units vào picorv32.v
- [ ] Wire signals

---

#### ✅ Task 4.4: Connect to register file (1 giờ)
- [ ] Read from rs1, rs2
- [ ] Write back to rd

---

#### ✅ Task 4.5: Testbench integration (2 giờ)
- [ ] Viết test program (assembly)
- [ ] Convert to hex
- [ ] Simulate

---

### 🎉 Checkpoint Phase 4
```bash
# Checklist:
[ ] PicoRV32 decode AES instructions
[ ] AES modules integrated
[ ] Simulation với firmware passed
[ ] Register writeback correct

# Nếu tất cả OK → Chuyển sang Phase 5
```

---

## ⚡ PHASE 5: FPGA DEPLOYMENT (1 ngày)

### 🎯 Mục tiêu
Synthesize và deploy lên Tang Mega 60K

### 📋 Tasks

#### ✅ Task 5.1: Setup Gowin project (30 phút)
- [ ] Tạo project mới
- [ ] Add Verilog files
- [ ] Set device

---

#### ✅ Task 5.2: Constraints files (30 phút)
- [ ] Pin assignment (.cst)
- [ ] Timing constraints (.sdc)

---

#### ✅ Task 5.3: Synthesize (30 phút)
- [ ] Run synthesis
- [ ] Check resource usage
- [ ] Fix errors

---

#### ✅ Task 5.4: Place & Route (1 giờ)
- [ ] Run P&R
- [ ] Check timing
- [ ] Meet 50 MHz constraint

---

#### ✅ Task 5.5: Generate bitstream (15 phút)
- [ ] Generate .fs file
- [ ] Verify file size

---

#### ✅ Task 5.6: Program FPGA (15 phút)
- [ ] Connect board
- [ ] Upload bitstream
- [ ] Verify LED blink

---

### 🎉 Checkpoint Phase 5
```bash
# Checklist:
[ ] Synthesis successful (no errors)
[ ] Timing met (≥50 MHz)
[ ] Resource usage OK (<50% LUTs)
[ ] Bitstream generated
[ ] FPGA programmed successfully

# Nếu tất cả OK → Chuyển sang Phase 6
```

---

## ⚡ PHASE 6: FIRMWARE & TESTING (1 ngày)

### 🎯 Mục tiêu
Viết firmware, test AES trên hardware

### 📋 Tasks

#### ✅ Task 6.1: Write AES driver (2 giờ)
- [ ] Inline assembly wrappers
- [ ] AES encrypt function
- [ ] AES decrypt function

---

#### ✅ Task 6.2: Write main firmware (1 giờ)
- [ ] UART initialization
- [ ] AES test với FIPS vectors
- [ ] Output via UART

---

#### ✅ Task 6.3: Compile firmware (15 phút)
- [ ] Compile với toolchain
- [ ] Generate .hex file
- [ ] Link với linker script

---

#### ✅ Task 6.4: Load firmware to FPGA (30 phút)
- [ ] Embed trong bitstream, hoặc
- [ ] Upload qua UART bootloader

---

#### ✅ Task 6.5: Test trên board (1 giờ)
- [ ] Kết nối serial monitor
- [ ] Run test
- [ ] Verify output

---

#### ✅ Task 6.6: Performance benchmark (1 giờ)
- [ ] Measure cycle count
- [ ] Compare với software-only
- [ ] Calculate speedup

---

### 🎉 Checkpoint Phase 6 (FINAL!)
```bash
# Checklist:
[ ] Firmware compiled successfully
[ ] Loaded to FPGA
[ ] UART output correct
[ ] AES encryption matches FIPS vectors
[ ] Performance gain measured (>20x speedup)
[ ] Demo video recorded

# 🎊 PROJECT COMPLETE! 🎊
```

---

## 📊 PROGRESS TRACKING

### Session Log Template
```
Date: ____________________
Time started: ____________
Phase/Task: ______________
Status: [ ] Not started  [ ] In progress  [ ] Completed  [ ] Blocked
Notes:



Issues encountered:



Solutions:



Time spent: ______________
```

---

## 🚨 TROUBLESHOOTING GUIDE

### Issue 1: Toolchain build fails
**Symptoms:** Make errors, missing files  
**Solutions:**
- Check dependencies: `sudo apt-get install -y build-essential ...`
- Check disk space: `df -h`
- Reduce cores: `make -j2` instead of `-j$(nproc)`

### Issue 2: Instruction not recognized
**Symptoms:** `Error: unrecognized opcode 'aes_subbytes'`  
**Solutions:**
- Verify riscv-opc.h và riscv-opc.c edits
- Rebuild binutils: `rm -rf build-binutils-newlib && make`
- Check PATH: `which riscv32-unknown-elf-as`

### Issue 3: Simulation fails
**Symptoms:** Testbench errors, wrong outputs  
**Solutions:**
- Check S-box values: `cat sbox.hex | head`
- Verify module connections
- Add debug prints: `$display(...)`

### Issue 4: Timing not met
**Symptoms:** Gowin reports timing violations  
**Solutions:**
- Reduce clock frequency: 50 MHz → 40 MHz
- Add pipeline registers
- Optimize critical path

### Issue 5: FPGA programming fails
**Symptoms:** Gowin Programmer errors  
**Solutions:**
- Check USB connection
- Try different USB port
- Reinstall Gowin driver
- Check board power

---

## 📁 FILE STRUCTURE TỔNG QUÁT

```
/home/minhoang/workspace/RISC-V/
├── ACTION_PLAN_AES.md              # ← File này
├── SPECIFICATION.md                # Spec AES-256
├── BAO_CAO_HOAN_THANH.md          # Báo cáo cũ (RV64)
│
├── riscv-gnu-toolchain/            # Toolchain source
│   ├── binutils/
│   │   ├── include/opcode/riscv-opc.h    # ✏️ MODIFIED
│   │   └── opcodes/riscv-opc.c           # ✏️ MODIFIED
│   └── ...
│
├── riscv-opcodes/                  # Opcode generator
│   └── extensions/rv_i             # ✏️ MODIFIED (AES instructions)
│
├── hardware/                       # ← NEW: Hardware design
│   ├── picorv32/                   # PicoRV32 core
│   ├── aes_modules/                # AES Verilog modules
│   │   ├── aes_subbytes_unit.v
│   │   ├── aes_mixcolumn_unit.v
│   │   ├── aes_keyexp_unit.v
│   │   ├── sbox.hex
│   │   └── inv_sbox.hex
│   ├── testbenches/                # Testbenches
│   └── simulation_results/         # Waveforms, logs
│
├── firmware/                       # ← NEW: Firmware code
│   ├── aes_driver.c
│   ├── aes_driver.h
│   ├── main.c
│   ├── uart.c
│   ├── linker.ld
│   └── Makefile
│
├── fpga_project/                   # ← NEW: Gowin project
│   ├── aes_picorv32.gprj
│   ├── constraints/
│   │   ├── tang_mega_60k.cst
│   │   └── timing.sdc
│   └── outputs/
│       └── aes_picorv32.fs         # Bitstream
│
├── tests/                          # Test files
│   ├── test_aes_instructions.s
│   ├── test_aes_instructions.dis
│   └── ...
│
└── toolchain_logs/                 # Build logs
    ├── configure.log
    ├── build.log
    └── rebuild_binutils.log
```

---

## 🎯 NEXT ACTIONS (BẮT ĐẦU TỪ ĐÂY!)

### ✅ Bước đầu tiên ngay bây giờ:

```bash
# 1. Mở terminal trong WSL
cd /home/minhoang/workspace/RISC-V

# 2. Kiểm tra trạng thái hiện tại
ls -la

# 3. Bắt đầu Phase 1, Task 1.1
# (Xem phần PHASE 1 phía trên)
```

### 📝 Báo cáo tiến độ:

Sau mỗi task hoàn thành, comment vào đây:
```
✅ Task X.Y completed at [TIME]
   - Duration: [XX minutes]
   - Issues: [None / ...]
   - Next: Task X.Y+1
```

---

## 🏆 EXPECTED FINAL RESULTS

```
┌──────────────────────────────────────────────────────┐
│  DELIVERABLES                                        │
├──────────────────────────────────────────────────────┤
│  ✅ RV32IMC Toolchain với 5 AES custom instructions  │
│  ✅ 5 Verilog modules cho AES operations             │
│  ✅ Modified PicoRV32 với AES support                │
│  ✅ FPGA bitstream cho Tang Mega 60K                 │
│  ✅ Firmware demo chạy AES-256                       │
│  ✅ Performance report (speedup vs software)         │
│  ✅ Video demo trên hardware                         │
│  ✅ Documentation đầy đủ                             │
└──────────────────────────────────────────────────────┘

Performance Target:
  • Latency:     < 100 cycles per AES block
  • Throughput:  > 1 Gbps @ 100 MHz
  • Speedup:     > 20x vs software-only
  • Resource:    < 15K LUTs (< 30% of 60K)
```

---

**🚀 SẴN SÀNG BẮT ĐẦU! LET'S DO THIS! 💪**

**Bước tiếp theo:** 
1. Đọc kỹ Phase 1
2. Execute Task 1.1
3. Báo cáo progress
4. Tiếp tục Task 1.2...

Chúc bạn thành công! Tôi sẽ đồng hành cùng bạn từng bước! 🎉
