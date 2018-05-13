a0: read charactor count
a1: write charactor position
t8: function parameter
t9: 0xffffffff
v0: serial input data
v1: serial output data
la: return address

ZR: zero
WR: word lenth(4)
PC: pc
SP: stack pointer
FR: flag register

| Bit 0: Writing one to this bit halts the processor.  No further instructions or interrupts execute.    |
| Bit 1: Global Interrupt Enable.  All interrupts enabled when 1.  All interrupts disabled otherwise.    |
| Bit 2: When set to 1, atomically sets bit 1 of FR to 1; bit 2 of FR to 0; PC to [SP]; SP to SP + WR.   |
| Bit 3: TIMER1 interrupt enable.  See TIMER1\_PERIOD.                                                   |
| Bit 4: TIMER1 interrupt asserted.  CPU sets to 1.  User must set to 0.                                 |
| Bit 5: UART1\_OUT interrupt enable.  Used for detecting when bit 9 of FR has been set by CPU.          |
| Bit 6: UART1\_OUT interrupt asserted.  CPU sets to 1.  User must set to 0.                             |
| Bit 7: UART1\_IN interrupt enable.  Used for detecting when bit 10 of FR has been set by CPU.          |
| Bit 8: UART1\_IN interrupt asserted.  CPU sets to 1.  User must set to 0.                              |
| Bit 9: UART1\_OUT ready.  Indicates if UART1\_OUT is ready.  CPU sets to 1.  User must set 0.          |
| Bit 10:UART1\_IN ready.  Indicates if UART1\_IN contains input data.  CPU sets to 1.  User must set 0. |
| Bit 11:DIV\_ZERO interrupt asserted due to a division by 0.  CPU sets to 1.  User must set to 0.       |
| Bit 12:PAGE\_FAULT\_EXCEPTION interrupt asserted.  CPU sets to 1.  User must set to 0.                 |
| Bit 13:PAGE\_FAULT\_EXCEPTION interrupt enabled.  Enables or disables paging.  Ignores FR bit 1 state. |

Handling an interrupt atomically sets bit 1 of FR to 0; SP to SP - WR; [SP] to PC; then PC to IRQ\_HANDLER



t0...: temporatory use


