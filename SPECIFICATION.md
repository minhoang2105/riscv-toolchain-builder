# 📋 SPECIFICATION: HỆ THỐNG MÃ HÓA AES-256

## 📌 THÔNG TIN DỰ ÁN

| Thuộc tính | Giá trị |
|------------|---------|
| **Tên dự án** | AES-256 Encryption/Decryption System |
| **Phiên bản** | 1.0 |
| **Ngày** | 2025-10-13 |
| **Tác giả** | [Nguyễn Đức Thạo] |
| **Mục đích** | Implementation AES-256 cho FPGA |
| **Chuẩn tham chiếu** | FIPS-197 (Advanced Encryption Standard) |

---

## 1. TỔNG QUAN HỆ THỐNG (SYSTEM OVERVIEW)

### 1.1. Mô tả chức năng

Hệ thống mã hóa AES-256 là một **block cipher đối xứng** thực hiện:
- Mã hóa (Encryption): Chuyển plaintext thành ciphertext
- Giải mã (Decryption): Chuyển ciphertext về plaintext gốc
- Sử dụng khóa bí mật 256-bit
- Hoạt động trên block dữ liệu 128-bit

### 1.2. Ứng dụng

- Bảo mật dữ liệu truyền thông
- Mã hóa dữ liệu lưu trữ
- Hệ thống nhúng yêu cầu bảo mật cao
- FPGA-based cryptographic accelerator

### 1.3. Yêu cầu bảo mật

- Tuân thủ chuẩn FIPS-197
- Khả năng chống các tấn công:
  - Brute-force attack
  - Differential cryptanalysis
  - Linear cryptanalysis
- Key không được lưu trữ dạng plaintext trong memory

---

## 2. THÔNG SỐ KỸ THUẬT (TECHNICAL SPECIFICATIONS)

### 2.1. Thông số đầu vào/đầu ra

| Thông số | Mô tả | Kích thước | Định dạng |
|----------|-------|------------|-----------|
| **Plaintext** | Dữ liệu gốc cần mã hóa | 128 bits (16 bytes) | Binary/Hex |
| **Key** | Khóa bí mật | 256 bits (32 bytes) | Binary/Hex |
| **Ciphertext** | Dữ liệu đã mã hóa | 128 bits (16 bytes) | Binary/Hex |

### 2.2. Cấu trúc thuật toán

```
Block Size:    128 bits (4×4 bytes state matrix)
Key Size:      256 bits (8 words × 4 bytes)
Rounds:        14 rounds
Round Keys:    15 round keys (Round 0 to Round 14)
```

### 2.3. Yêu cầu timing

| Thao tác | Mục tiêu | Ghi chú |
|----------|----------|---------|
| **Latency** | < 100 clock cycles | Cho 1 block 16 bytes |
| **Throughput** | > 1 Gbps | Ở clock 100 MHz |
| **Key setup time** | < 50 clock cycles | Expand key 256-bit |

### 2.4. Yêu cầu tài nguyên (cho FPGA)

```
Logic Elements:     ~5000 - 10000 LEs
Memory (RAM):       ~10 KB (cho S-box, round keys)
DSP blocks:         Không yêu cầu
Clock frequency:    ≥ 100 MHz
Power:              < 500 mW
```

---

## 3. KIẾN TRÚC HỆ THỐNG (SYSTEM ARCHITECTURE)

### 3.1. Sơ đồ khối tổng quan

```
                    ┌─────────────────────────────────────┐
                    │         AES-256 CORE                │
                    └─────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           ▼
┌───────────────┐          ┌────────────────┐         ┌─────────────────┐
│ Key Expansion │          │ Encryption     │         │ Decryption      │
│    Module     │          │    Module      │         │    Module       │
└───────────────┘          └────────────────┘         └─────────────────┘
        │                           │                           │
        └───────────────────────────┴───────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
                    ▼                               ▼
            ┌──────────────┐              ┌──────────────────┐
            │  S-box       │              │  Galois Field    │
            │  Lookup      │              │  Multiplier      │
            └──────────────┘              └──────────────────┘
```

### 3.2. Các module chính

#### Module 1: Key Expansion
```
Input:  256-bit master key
Output: 15 round keys (240 bytes total)
Function: Tạo các round key từ master key
Algorithm: 
  - Expand 8 words thành 60 words
  - Apply RotWord, SubWord, Rcon
  - Special: SubWord tại i%8==4 (AES-256)
```

#### Module 2: Encryption Engine
```
Input:  128-bit plaintext, 15 round keys
Output: 128-bit ciphertext
Rounds: 14 rounds
Operations:
  - Round 0: AddRoundKey
  - Rounds 1-13: SubBytes, ShiftRows, MixColumns, AddRoundKey
  - Round 14: SubBytes, ShiftRows, AddRoundKey (NO MixColumns)
```

#### Module 3: Decryption Engine
```
Input:  128-bit ciphertext, 15 round keys
Output: 128-bit plaintext
Rounds: 14 rounds (inverse order)
Operations:
  - Round 14: AddRoundKey
  - Rounds 13-1: InvShiftRows, InvSubBytes, AddRoundKey, InvMixColumns
  - Round 0: InvShiftRows, InvSubBytes, AddRoundKey (NO InvMixColumns)
```

---

## 4. CHI TIẾT CÁC PHÉP TOÁN (OPERATIONS DETAILS)

### 4.1. SubBytes Transformation

**Mô tả:** Thay thế từng byte bằng giá trị trong S-box

**Input:** State matrix 4×4 bytes  
**Output:** State matrix 4×4 bytes  
**Algorithm:**
```
For i = 0 to 3:
    For j = 0 to 3:
        state[i][j] = S-box[state[i][j]]
```

**Implementation:**
- Sử dụng lookup table (256 bytes)
- S-box định nghĩa trong FIPS-197
- Có thể implement bằng ROM hoặc combinational logic

**Timing:** 1 clock cycle (parallel) hoặc 16 clock cycles (sequential)

---

### 4.2. ShiftRows Transformation

**Mô tả:** Dịch các hàng của state matrix

**Input:** State matrix 4×4  
**Output:** State matrix 4×4  
**Algorithm:**
```
Row 0: Không dịch
Row 1: Dịch trái 1 byte   [a b c d] → [b c d a]
Row 2: Dịch trái 2 bytes  [a b c d] → [c d a b]
Row 3: Dịch trái 3 bytes  [a b c d] → [d a b c]
```

**Implementation:**
- Wiring/routing only (không cần logic)
- Zero latency

**Inverse (InvShiftRows):**
```
Row 1: Dịch phải 1 byte
Row 2: Dịch phải 2 bytes
Row 3: Dịch phải 3 bytes
```

---

### 4.3. MixColumns Transformation

**Mô tả:** Nhân ma trận state với ma trận cố định trong GF(2^8)

**Input:** State matrix 4×4  
**Output:** State matrix 4×4  

**Algorithm:**
```
Ma trận MixColumns:
    [02 03 01 01]
    [01 02 03 01]
    [01 01 02 03]
    [03 01 01 02]

For each column c:
    out[0] = 02•in[0] ⊕ 03•in[1] ⊕ 01•in[2] ⊕ 01•in[3]
    out[1] = 01•in[0] ⊕ 02•in[1] ⊕ 03•in[2] ⊕ 01•in[3]
    out[2] = 01•in[0] ⊕ 01•in[1] ⊕ 02•in[2] ⊕ 03•in[3]
    out[3] = 03•in[0] ⊕ 01•in[1] ⊕ 01•in[2] ⊕ 02•in[3]
```

**Phép nhân Galois Field:**
```
02 • x = xtime(x) = (x << 1) ⊕ (0x1b if x[7]==1 else 0)
03 • x = 02•x ⊕ x
```

**Implementation:**
- 4 columns có thể xử lý song song
- Mỗi column cần 4 XOR và 2-3 xtime operations
- Timing: 2-3 clock cycles

**Inverse (InvMixColumns):**
```
Ma trận:
    [0e 0b 0d 09]
    [09 0e 0b 0d]
    [0d 09 0e 0b]
    [0b 0d 09 0e]
```

---

### 4.4. AddRoundKey Transformation

**Mô tả:** XOR state với round key

**Input:** State matrix 4×4, Round key 4×4  
**Output:** State matrix 4×4  
**Algorithm:**
```
For i = 0 to 3:
    For j = 0 to 3:
        state[i][j] = state[i][j] ⊕ roundkey[i][j]
```

**Implementation:**
- 16 XOR gates (parallel)
- Timing: Combinational (0 clock cycles) hoặc 1 clock cycle

---

### 4.5. Key Expansion

**Mô tả:** Tạo 15 round keys từ 256-bit master key

**Input:** 256-bit key (8 words)  
**Output:** 60 words (15 round keys × 4 words)  

**Algorithm:**
```
Initial: w[0..7] = key[0..31] (8 words from master key)

For i = 8 to 59:
    temp = w[i-1]
    
    If i % 8 == 0:
        temp = SubWord(RotWord(temp)) ⊕ Rcon[i/8]
    Else if i % 8 == 4:  // ĐẶC BIỆT cho AES-256
        temp = SubWord(temp)
    
    w[i] = w[i-8] ⊕ temp
```

**Các hàm phụ:**
```
RotWord([a,b,c,d]) = [b,c,d,a]
SubWord([a,b,c,d]) = [S-box[a], S-box[b], S-box[c], S-box[d]]
Rcon[i] = [x^(i-1), 0, 0, 0] trong GF(2^8)
```

**Rcon values:**
```
Rcon[1..7] = [01, 02, 04, 08, 10, 20, 40]
```

---

## 5. BẢNG TRA CỨU (LOOKUP TABLES)

### 5.1. S-box (256 bytes)

```
Kích thước: 256 bytes
Mục đích: SubBytes transformation
Implementation: ROM hoặc combinational logic
Access time: 1 clock cycle
```

### 5.2. Inverse S-box (256 bytes)

```
Kích thước: 256 bytes
Mục đích: InvSubBytes transformation
Implementation: ROM
Quan hệ: INV_SBOX[SBOX[x]] = x
```

### 5.3. Round Keys Storage

```
Kích thước: 240 bytes (15 keys × 16 bytes)
Mục đích: Lưu trữ round keys
Implementation: RAM hoặc registers
Access: Sequential (round 0→14 hoặc 14→0)
```

---

## 6. CONTROL FLOW

### 6.1. Encryption Flow

```
START
  ↓
[Load Plaintext & Key]
  ↓
[Key Expansion] → Generate 15 round keys
  ↓
[Round 0] → AddRoundKey(state, key[0])
  ↓
┌─────────────────────┐
│ FOR round = 1 to 13 │
│   ↓                 │
│   SubBytes          │
│   ↓                 │
│   ShiftRows         │
│   ↓                 │
│   MixColumns        │
│   ↓                 │
│   AddRoundKey       │
└─────────────────────┘
  ↓
[Round 14]
  ↓
  SubBytes
  ↓
  ShiftRows
  ↓
  AddRoundKey(state, key[14])
  ↓
[Output Ciphertext]
  ↓
END
```

### 6.2. Decryption Flow

```
START
  ↓
[Load Ciphertext & Key]
  ↓
[Key Expansion] → Generate 15 round keys
  ↓
[Round 14] → AddRoundKey(state, key[14])
  ↓
┌─────────────────────┐
│ FOR round = 13 to 1 │
│   ↓                 │
│   InvShiftRows      │
│   ↓                 │
│   InvSubBytes       │
│   ↓                 │
│   AddRoundKey       │
│   ↓                 │
│   InvMixColumns     │
└─────────────────────┘
  ↓
[Round 0]
  ↓
  InvShiftRows
  ↓
  InvSubBytes
  ↓
  AddRoundKey(state, key[0])
  ↓
[Output Plaintext]
  ↓
END
```

---

## 7. STATE MACHINE

### 7.1. Main Controller States

```
IDLE           → Chờ input
KEY_EXPAND     → Thực hiện key expansion
ENCRYPT_INIT   → Khởi tạo encryption
ENCRYPT_ROUND  → Thực hiện round 1-13
ENCRYPT_FINAL  → Round 14 (no MixColumns)
DECRYPT_INIT   → Khởi tạo decryption
DECRYPT_ROUND  → Thực hiện round 13-1
DECRYPT_FINAL  → Round 0 (no InvMixColumns)
OUTPUT         → Output kết quả
```

### 7.2. State Transition Diagram

```
       ┌─────┐
       │IDLE │◄────────────────────────┐
       └──┬──┘                         │
          │ start                      │
          ▼                            │
    ┌───────────┐                      │
    │KEY_EXPAND │                      │
    └─────┬─────┘                      │
          │                            │
    ┌─────┴─────┐                      │
    │           │                      │
    ▼           ▼                      │
┌────────┐  ┌────────┐                 │
│ENCRYPT │  │DECRYPT │                 │
│ _INIT  │  │ _INIT  │                 │
└───┬────┘  └────┬───┘                 │
    │            │                     │
    ▼            ▼                     │
┌────────┐  ┌────────┐                 │
│ENCRYPT │  │DECRYPT │                 │
│ _ROUND │  │ _ROUND │                 │
└───┬────┘  └────┬───┘                 │
    │            │                     │
    ▼            ▼                     │
┌────────┐  ┌────────┐                 │
│ENCRYPT │  │DECRYPT │                 │
│ _FINAL │  │ _FINAL │                 │
└───┬────┘  └────┬───┘                 │
    │            │                     │
    └─────┬──────┘                     │
          ▼                            │
      ┌────────┐                       │
      │OUTPUT  │───────────────────────┘
      └────────┘
```

---

## 8. INTERFACE SPECIFICATION

### 8.1. Top-level Entity (Verilog/VHDL)

```verilog
module aes256_core (
    // Clock and Reset
    input  wire         clk,
    input  wire         rst_n,
    
    // Control signals
    input  wire         start,          // Bắt đầu operation
    input  wire         mode,           // 0=Encrypt, 1=Decrypt
    output wire         done,           // Hoàn thành
    output wire         busy,           // Đang xử lý
    
    // Data inputs
    input  wire [127:0] data_in,        // Plaintext hoặc Ciphertext
    input  wire [255:0] key_in,         // 256-bit key
    
    // Data output
    output wire [127:0] data_out,       // Ciphertext hoặc Plaintext
    output wire         valid           // Output valid
);
```

### 8.2. Signal Timing Diagram

```
       ____      ____      ____      ____      ____
clk   |    |____|    |____|    |____|    |____|    |____

            ___________________________________
start _____|                                   |_______

      _____________________________________________
busy               |_______________________________|____

                                                   ____
done  _____________________________________________|    |

            [===================================]
data_in     |     Valid Input Data             |

                                                [=====]
data_out    ____________________________________| Out |

                                                   ____
valid _____________________________________________|    |
```

---

## 9. TEST & VERIFICATION

### 9.1. Test Vectors

**Test Case 1: FIPS-197 Appendix C.3**
```
Plaintext:  00112233445566778899aabbccddeeff
Key:        000102030405060708090a0b0c0d0e0f
            101112131415161718191a1b1c1d1e1f
Expected:   8ea2b7ca516745bfeafc49904b496089
```

**Test Case 2: All Zeros**
```
Plaintext:  00000000000000000000000000000000
Key:        00000000000000000000000000000000
            00000000000000000000000000000000
Expected:   dc95c078a2408989ad48a21492842087
```

**Test Case 3: All Ones**
```
Plaintext:  ffffffffffffffffffffffffffffffff
Key:        ffffffffffffffffffffffffffffffff
            ffffffffffffffffffffffffffffffff
Expected:   [Tự tính toán và verify]
```

### 9.2. Verification Checklist

- [ ] **Functional Tests**
  - [ ] Encryption với FIPS-197 test vectors
  - [ ] Decryption với FIPS-197 test vectors
  - [ ] Round-trip (encrypt → decrypt)
  - [ ] Key expansion correctness
  - [ ] Từng transformation (SubBytes, ShiftRows, etc.)

- [ ] **Performance Tests**
  - [ ] Latency measurement
  - [ ] Throughput measurement
  - [ ] Clock frequency achievable
  - [ ] Resource utilization

- [ ] **Security Tests**
  - [ ] Key không leak qua side-channels
  - [ ] Timing attack resistance
  - [ ] Power analysis resistance

- [ ] **Corner Cases**
  - [ ] All zeros input
  - [ ] All ones input
  - [ ] Random data
  - [ ] Back-to-back operations

---

## 10. IMPLEMENTATION NOTES

### 10.1. Optimization Strategies

**1. Pipeline Architecture**
```
- Chia encryption thành các stages
- Mỗi round là 1 pipeline stage
- Throughput: 1 block mỗi clock cycle
- Latency: 14-15 clock cycles
```

**2. Area Optimization**
```
- Share S-box giữa encryption và decryption
- Sequential processing (1 round/cycle)
- On-the-fly key expansion
- Reduced throughput, nhỏ area
```

**3. Speed Optimization**
```
- Parallel S-box lookups (16 instances)
- Unrolled rounds
- Pipelined datapath
- Increased area, high throughput
```

### 10.2. Trade-offs

| Metric | Sequential | Pipelined | Fully Unrolled |
|--------|-----------|-----------|----------------|
| **Latency** | ~200 cycles | ~20 cycles | ~1 cycle |
| **Throughput** | Low | Medium | High |
| **Area** | Small | Medium | Large |
| **Power** | Low | Medium | High |

### 10.3. FPGA-specific Considerations

**Block RAM Usage:**
- S-box: 256 bytes → 1 BRAM
- INV_S-box: 256 bytes → 1 BRAM
- Round keys: 240 bytes → 1 BRAM

**DSP Blocks:**
- Không cần DSP cho AES
- Tất cả operations là XOR và table lookup

**I/O Pins:**
- Minimum: 392 pins (128 data_in + 256 key + 128 data_out + control)
- Có thể giảm bằng serial interface

---

## 11. SAFETY & SECURITY

### 11.1. Security Requirements

1. **Key Protection**
   - Key không được đọc ra ngoài
   - Clear key sau khi sử dụng
   - No debug access to key

2. **Side-channel Protection**
   - Constant-time operations
   - Power analysis countermeasures
   - Timing attack prevention

3. **Fault Injection Protection**
   - Parity checks
   - Redundant computation
   - Error detection

### 11.2. Safety Mechanisms

1. **Error Detection**
   - Parity bits trên data paths
   - CRC trên key expansion
   - Timeout mechanisms

2. **Reset Behavior**
   - Clear all sensitive data on reset
   - Return to known good state
   - No residual key material

---

## 12. DOCUMENTATION

### 12.1. Required Documents

- [ ] Design Specification (document này)
- [ ] User Manual
- [ ] Test Plan
- [ ] Test Report
- [ ] Synthesis Report
- [ ] Timing Analysis Report
- [ ] Power Analysis Report

### 12.2. Code Documentation

```verilog
// Mỗi module cần có:
// - Purpose/description
// - Interface explanation
// - Algorithm overview
// - Timing diagrams
// - Example usage
```

---

## 13. REFERENCES

1. **FIPS-197**: Advanced Encryption Standard (AES)
   - https://csrc.nist.gov/publications/detail/fips/197/final

2. **NIST Test Vectors**
   - https://csrc.nist.gov/projects/cryptographic-algorithm-validation-program

3. **AES Implementations**
   - OpenSSL AES implementation
   - Reference implementations

---

## PHỤ LỤC A: QUICK REFERENCE

### Bảng tóm tắt thông số

```
┌─────────────────────────────────────────────────────┐
│             AES-256 QUICK REFERENCE                 │
├─────────────────────────────────────────────────────┤
│ Block Size:        128 bits (16 bytes)              │
│ Key Size:          256 bits (32 bytes)              │
│ Rounds:            14 rounds                        │
│ Round Keys:        15 keys (0-14)                   │
│ State:             4×4 byte matrix                  │
├─────────────────────────────────────────────────────┤
│ Key Expansion:     8 words → 60 words               │
│ Total Round Keys:  240 bytes                        │
├─────────────────────────────────────────────────────┤
│ Operations:                                         │
│  - SubBytes        (S-box lookup)                   │
│  - ShiftRows       (Row rotation)                   │
│  - MixColumns      (GF(2^8) matrix multiply)        │
│  - AddRoundKey     (XOR with round key)             │
├─────────────────────────────────────────────────────┤
│ Special Note:      Final round NO MixColumns        │
└─────────────────────────────────────────────────────┘
```

---

**END OF SPECIFICATION**

*Document Version: 1.0*  
*Last Updated: 2025-10-13*
