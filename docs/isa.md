# 指令集描述

我们项目中使用的基本是 recc 项目的指令集, 但是为了方便增加和修改了若干指令.
修改加入指令的原因有集中

* 这个指令的操作很常用, 并且加入之后能有效缩减 kernel 大小. 如 `addiu`, `lui`

* 这个指令可以被其他指令代替, 且使用其他指令完成这个指令的功能比反过来简单的多. 如 `xor` 替换 `not`

* 对 llvm 的指令选择理解有限, 无法设计从已有指令完成某功能的指令序列. 如 `jsub`, `ori`

未来编译系统方面的一个目标就是消除最后一种指令, 做到最精简的 ISA.

## 寄存器结构
有 17 个 32 位寄存器, 使用惯例参考了 opcpu 和 mips. (参见 Cpu0RegisterInfo.td 文件)
```
+-------+------+-----------------------------------------------------------------------------------------+
| Regno | Name | Usage                                                                                   |
+-------+------+-----------------------------------------------------------------------------------------+
| 0     | pc   | hold's current instruction's address plus 4                                             |
| 1     | sp   | stack pointer                                                                           |
| 2     | fp   | frame pointer, for llvm compiler it's not used. callee-save register (CSR).             |
| 3     | zr   | zero register, always zero even written another value                                   |
| 4     | fr   | flags register. see opcpu document.                                                     |
| 5     | wr   | word register, always 4 even written another value                                      |
| 6     | at   | not used. will be used as GPR                                                           |
| 7     | lr   | link register, holds return address. CSR                                                |
| 8     | gp   | global pointer. not used. will be as GPR                                                |
| 9     | v0   | holds return value                                                                      |
| 10    | v1   | holds return value if v0 is not enough (even bigger return values are stored on stacks) |
| 11    | a0   | holds the first argument (from left to right)                                           |
| 12    | a1   | holds the second argument (from left to right). more args are passed on stack.          |
| 13    | s0   | CSR GPR                                                                                 |
| 14    | s1   | CSR GPR                                                                                 |
| 15    | t0   | GPR                                                                                     |
| 16    | t1   | GPR                                                                                     |
| 17    | t2   | GPR                                                                                     |
+-------+------+-----------------------------------------------------------------------------------------+
```

## 指令格式
指令定长 32 位, 有三种格式, 如下 (参见 Cpu0InstrFormats.td 文件)
```
R-type
 31       26 25     21 20     16 15     11 10                  0
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|  opcode   |   rx    |   ry    |   rz    |      reserved       |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      6          5         5         5              11

I-type
 31       26 25     21 20     16 15                            0
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|  opcode   |   rx    |   ry    |             imm               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      6          5         5                  16       

J-type (is expected to be removed in the future)
 31       26 25                                                0
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|  opcode   |                     offset                        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      6                             26                 
```

## 指令列表
  以下 `$rx` 表示 `rx` 是一个寄存器, `off($rs)` 表示内存地址 `[$rs+off]`.
  (参见 Cpu0InstrInfo.td 文件)
### R-type
```
+-------------------+--------+---------------------+-----------------------+
| Assembly          | Opcode | Semantics           | Others                |
+-------------------+--------+---------------------+-----------------------+
| add $rx, $ry, $rz | 0      | $rx = $ry + $rz;    | no overflow exception |
| sub $rx, $ry, $rz | 1      | $rz = $ry - $rz;    | no overflow exception |
| mul $rx, $ry, $rz | 2      | $rx = $ry * $rz;    | taking lower 32 bits  |
| div $rx, $ry, $rz | 3      | not implemented yet |                       |
| and $rx, $ry, $rz | 4      | $rx = $ry & $rz;    | bitwise and           |
| or $rx, $ry, $rz  | 5      | $rx = $ry | $rz;    | bitwise or            |
| xor $rx, $ry, $rz | 6      | $rx = $ry ^ $rz;    | bitwise exclusive or  |
| shr $rx, $ry, $rz | 9      | $rx = $ry shr $rz;  | logical shift right   |
| shl $rx, $ry, $rz | 10     | $rx = $ry shl $rz;  | logical shift left    |
+-------------------+--------+---------------------+-----------------------+
```
### I-type
```
+---------------------+--------+----------------------------------------------+------------------------------------+
| Assembly            | Opcode | Semantics                                    | Others                             |
+---------------------+--------+----------------------------------------------+------------------------------------+
| loa $rx, imm($ry)   | 7      | $rx = mem<int32>[$ry + sign-extend(imm)];    | must be aligned                    |
| sto $rx, imm($ry)   | 8      | mem<int32>[$ry + sign-extend(imm)] = $rx;    | must be aligned                    |
| beq $rx, $ry, imm   | 11     | if $rx == $ry then $pc += sign-extend(imm);  | for now imm is not multiplied by 4 |
| blt $rx, $ry, imm   | 12     | if $rx u< $ry then $pc += sign-extend(imm);  | unsigned comparison. same as beq.  |
| addiu $rx, $ry, imm | 13     | $rx = $ry + sign-extend(imm);                | no overflow exception              |
| lui $rx, imm        | 14     | $rx = imm << 16, clearing the lower 16 bits; | $ry should be 0b00000              |
| ori $rx, $ry, imm   | 16     | $rx = $ry O zero-extend(imm);                | bitwise or                         | *
| bne $rx, $ry, imm   | 19     | if $rx != $ry then $pc += sign-extend(imm);  | same as beq                        | *
| jr $rx              | 20     | $pc = $rx;                                   |                                    | *
| jalr $rx            | 21     | $lr = $pc; $pc = $rx;                        |                                    |
+---------------------+--------+----------------------------------------------+------------------------------------+
```
### J-type
```
+-------------+--------+---------------------------------------+--------+
| Assembly    | Opcode | Semantics                             | Others |
+-------------+--------+---------------------------------------+--------+
| jsub offset | 22     | $lr = $pc; $pc += sign-extend(offset) |        | *
+-------------+--------+---------------------------------------+--------+
```
以上

* 对于本项目的编译器, 我们不支持算术右移, C 中的 `a >> b` 会被编译成逻辑右移.

* PC 指向下一条指令

* 最后有一个 `*` 的指令表示是计划未来去除的

## ABI
参见寄存器结构.

