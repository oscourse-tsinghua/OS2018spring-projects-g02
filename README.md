# OS2018spring-projects-g02
项目是清华大学操作系统课的 [课程项目](http://os.cs.tsinghua.edu.cn/oscourse/OS2018spring/projects/g02),
基本目的是在一块非常小的 FPGA 上完成一个非常 RISC 的 CPU, 并且提供 (x86平台上) 的交叉编译器,
在此基础上, 运行一块基于 Robert Elder 的 recc项目的操作系统.

现阶段可以在模拟器上运行操作系统.

------------------------------------------------------------------------------

# 构建项目
推荐使用 Linux 环境. 要求 
* cmake: 3.5.1
* clang: 3.9.0 or 3.8.0, 注意 clang 更新和更老的版本都不行
* make: 4.1
* GNU binutils: 2.26.1

视机器配置, 构建过程可能花费二十分钟到一小时不等.

## 构建编译器
编译器基于 llvm (3.9.0) 和 lld(3.9.0), 参考了 [Cpu0](https://github.com/jonathan2251/lbd) 和其他后端的实现.

在仓库目录 `OS2018spring-projects-g02/` 下, 执行
```
$ cd llvm-3.9.0.src
$ mkdir build && cd build
$ cmake -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang -DCMAKE_BUILD_TYPE=Debug -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF -G "Unix Makefiles" ..
$ make llc llvm-mc lld      # 机器性能允许则可以 -jX 并行构建
$ ls bin/
ld.lld  llc  lld  lld-link  llvm-lit  llvm-mc  llvm-tblgen
```

希望加速构建的话, 可以参考 [使用其他链接器](https://github.com/AndroidNewsHomework/lightweight-os-dev-docs/blob/master/memo.md#%E5%8A%A0%E9%80%9F%E6%9E%84%E5%BB%BA%E8%BF%87%E7%A8%8B).

## 构建模拟器
这个模拟器是我们写的, 不是 Robert Elder 的模拟器. 它更方便模拟真实 FPGA 环境.
其 ISA 是 op-cpu 的 ISA 加入了一些实用指令 (尤其是 `addiu`), 另外还有一些未来准备删除的指令.

在仓库目录 `OS2018spring-projects-g02/` 下, 执行
```
$ cd cpu0-emulator
$ mkdir build && cd build
$ cmake ..
$ make
$ ls cpu0emu
cpu0emu
```

## 构建操作系统
操作系统基于 Robert Elder, 但是为了迎合我们的系统做了改动.
现在这个操作系统还缺少很多特性, 虚存和保护都待实现.

在仓库目录 `OS2018spring-projects-g02/` 下, 执行
```
$ cd recc-kernel-llvm
$ make
$ ls build/a.*
build/a.img  build/a.out
```

## 在模拟器上运行操作系统
完成以上构建之后, 可以开始在模拟器上运行操作系统了.

模拟器支持运行两种文件

* `a.out`: 可执行的 elf 文件.

* `a.img`: 从 0 开始的内存镜像.

希望运行 `a.out`, 则需要在 `OS2018spring-projects-g02/` 下
```
$ cp recc-kernel-llvm/build/a.out cpu0-emulator/build/
$ cd cpu0-emulator/build
$ ./cpu0emu a.out 0
```

希望运行 `a.img`, 则需要在 `OS2018spring-projects-g02/` 下
```
$ cp recc-kernel-llvm/build/a.img cpu0-emulator/build/
$ cd cpu0-emulator/build
$ ./cpu0emu a.img 0 2
```

执行 `./cpu0emu ...` 后, 应当看到如下的输出
```
e_flags=00000000
e_entry=000017bc
region FFFF0000 - FFFF00F4 (244): rwx=100
region 00000000 - 00001CF8 (7416): rwx=101
region 00001D00 - 00001FA1 (673): rwx=100
region 00001FA4 - 0000AA10 (35436): rwx=110
io port 00300000 - 00300100 (256)


> uart direct out: 0000004B    (d=        75)
> uart direct out: 00000045    (d=        69)
> uart direct out: 00000052    (d=        82)
> uart direct out: 00000053    (d=        83)
> uart direct out: 00000055    (d=        85)
> uart direct out: 00000043    (d=        67)
You're currently running a very simple microkernel that was built
for the purposes of demonstrating the 'One Page CPU' design, and
cross compiler collection.  This microkernel implements inter-process
communication, premptive context switching, interrupt based I/O, along
with a very simple timer that counts simulated clock ticks.

Some single-character commands include:

t -  Prints the number of simulated clock ticks since kernel start.
s -  Prints the stack pointer values of each task.
p -  Prints the priority of each task.
```

目前只支持以上三个单字符命令. 命令输出应当类似如下内容
```
t -  Prints the number of simulated clock ticks since kernel start.
s -  Prints the stack pointer values of each task.
p -  Prints the priority of each task.
t
0x2e
s
Task 0x0 SP: 0x0
Task 0x1 SP: 0x34D8
Task 0x2 SP: 0x44E8
Task 0x3 SP: 0x54D8
Task 0x4 SP: 0x6440
Task 0x5 SP: 0x74D8
Task 0x6 SP: 0x84B0
Task 0x7 SP: 0x9478
p
Task 0x0 Priority: 0x5
Task 0x1 Priority: 0x5
Task 0x2 Priority: 0x2
Task 0x3 Priority: 0x0
Task 0x4 Priority: 0x1
Task 0x5 Priority: 0x0
Task 0x6 Priority: 0x1
Task 0x7 Priority: 0x3
t
0x1e2
```

任何时刻, 按下 Ctrl-C 终止模拟器.
