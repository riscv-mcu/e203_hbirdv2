# See LICENSE for license details.

# Test machine interrupt priority: external, software, then timer.

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32M
RVTEST_CODE_BEGIN

  csrci mstatus, MSTATUS_MIE
  csrwi mie, 0
  la t0, irq_handler
  csrw mtvec, t0

  # Raise GPIOA source 15 through the PLIC (pin 0 is low in tb_top).
  li t0, 0x10012000
  li t1, 1
  sw t1, 0x10(t0)       # input enable
  sw t1, 0x0c(t0)       # level-low interrupt enable
  li t0, 0x0c00003c
  sw t1, 0(t0)          # source 15 priority
  li t0, 0x0c002000
  li t1, 0x8000
  sw t1, 0(t0)          # source 15 enable
  li t0, 0x0c200000
  sw zero, 0(t0)        # threshold

  # Raise software and timer interrupts through the CLINT.
  li t0, 0x02000000
  li t1, 1
  sw t1, 0(t0)          # msip
  li t0, 0x02004000
  sw zero, 4(t0)
  sw zero, 0(t0)        # mtimecmp = 0
  li t0, 0x888
wait_pending:
  csrr t1, mip
  bne t1, t0, wait_pending

  # Keep all sources pending and vary mie to check priority and masking.
#define IRQ_TEST(testnum, mask, cause) \
  li TESTNUM, testnum; \
  li s1, cause; \
  li t0, mask; \
  csrw mie, t0; \
  la s0, 1f; \
  csrsi mstatus, MSTATUS_MIE; \
0: j 0b; \
1:

  IRQ_TEST(2, 0x888, CAUSE_IRQ_M_EXT)
  IRQ_TEST(3, 0x880, CAUSE_IRQ_M_EXT)
  IRQ_TEST(4, 0x808, CAUSE_IRQ_M_EXT)
  IRQ_TEST(5, 0x088, CAUSE_IRQ_M_SFT)
  IRQ_TEST(6, 0x800, CAUSE_IRQ_M_EXT)
  IRQ_TEST(7, 0x008, CAUSE_IRQ_M_SFT)
  IRQ_TEST(8, 0x080, CAUSE_IRQ_M_TMR)
  j test_done

  .align 2
irq_handler:
  csrwi mie, 0
  csrr t0, mcause
  bne t0, s1, test_fail
  csrr t0, mbadaddr
  bnez t0, test_fail
  li t0, MSTATUS_MPIE
  csrc mstatus, t0       # return with global interrupts disabled
  csrw mepc, s0
  mret

test_fail:
  la t0, trap_vector
  csrw mtvec, t0
  j fail
test_done:
  la t0, trap_vector
  csrw mtvec, t0
  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN
  TEST_DATA
RVTEST_DATA_END
