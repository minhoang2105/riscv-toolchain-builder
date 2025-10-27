    .text
    .globl _start
_start:
    # Test mod instruction
    li      a0, 17      # Load 17 into a0
    li      a1, 5       # Load 5 into a1
    mod     a2, a0, a1  # a2 = 17 % 5 = 2
    
    # Test mul4 instruction
    li      a0, 5       # Load 5 into a0
    li      a1, 5       # Load 5 into a1 (dummy)
    mul4    a3, a0, a1  # a3 = 5 * 4 = 20
    
    # Test mul8 instruction
    mul8    a4, a0, a1  # a4 = 5 * 8 = 40
    
    # Test mul16 instruction
    mul16   a5, a0, a1  # a5 = 5 * 16 = 80
    
    # Exit
    li      a7, 93      # syscall exit
    li      a0, 0       # exit code 0
    ecall
