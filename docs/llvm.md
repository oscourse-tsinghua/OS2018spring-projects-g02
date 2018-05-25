# 编译系统实现
编译系统由戴臻旸同学实现.

本次作业中, 编译系统主要参考了 Cpu0 项目的[编译器后段](http://jonathan2251.github.io/lbd/),
[链接器](http://jonathan2251.github.io/lbt/). 编译系统基于 llvm 框架.

# 编译过程简述
llvm 中, 编译过程分三段:
1. clang 前端解析 C 代码 (或者其他语言), 将其转换成一种中间表示 IR.
IR 就类似 AST / 三地址码, 和具体的机器 ISA 无关. 一个 IR 的例子如下
```
define i32 @add2(i32 %a, i32 %b) {
entry:
  %tmp1 = icmp eq i32 %a, 0br i1 %tmp1, label %done, label %recurse
recurse:
  %tmp2 = sub i32 %a, 1
  %tmp3 = add i32 %b, 1
  %tmp4 = call i32 @add2(i32 %tmp2, i32 %tmp3)
  ret i32 %tmp4
done:
  ret i32 %b
}
```
2. 存在一个针对中间代码的通用优化器, 优化中间代码.
3. llvm 后段 `llc` 将中间代码转换成最终的汇编代码, 或者等价地二进制目标文件.

我的工作基本就在第三部分. 接下来叙述一下第三部分进一步的流程.
从 IR 转换成最终的目标代码, 需要完成如下的步骤
1. Instruction Selection (ISel) 指令选择: 使用目标 ISA 的指令来完成 IR 中的操作,
如对于 IR 中的 `add`, 我们可以选择 `add` 和 `addiu`.
2. Pre-RA Instruction Scheduling 指令调度: 将指令排序, 减少依赖和冲突造成的停顿. 我们没有使用.
之后的描述里面也不提这部分相关的东西.
3. Register Allocation (RA) 寄存器分配: 直到这一步, 寄存器都是虚拟寄存器.
这一步使用寄存器分配算法, 对每个虚拟寄存器都对应一个目标 ISA 的物理寄存器.
这一部分我们直接使用 LLVM 自己的算法即可. 之后的描述里面也不提这部分相关的东西.
4. Post-RA Instruction Scheduling 指令调度: 同上, 但是考虑物理寄存器的依赖和冲突. 我们不使用.
之后的描述里面也不提这部分相关的东西.
5. 优化: 不使用.
6. 代码发射: 把上面得到的结果用文本形式或者二进制目标文件形式打印出来.

## 指令选择
LLVM 使用的是一种类似 Tree Rewriting (参见龙书 Instruction Selection by Tree Rewriting) 的指令选择模式,
对于每个基本块他在生成的 DAG 上做重写而已.

### 基本块和流分析
编译课讲过.

### Rewriting 算法
为了简便下面叙述 Rewriting 算法在树上的情况, DAG 类似.
简单的说, 就是每条指令对应一个树上的重写模式, 如 `add r1, r2, r3` 可以把子树
```
        +
       / \
      /   \
     v     v
    r2     r3
```
替换成单个节点
```
        r1
```
同时发射一条指令 `add r1 r2 r3`.

对于每个基本块, 做完数据流分析之后我们得到一颗树 (编译课上讲是 DAG, 不过是等价的),
按照这样的替换规则, 寻找这颗树中能替换的部分, 将其替换并且发射指令
直到没有能替换的部分, 我们就可以宣告成功或者失败 (如没有 `add` 类的指令但是树中有 `+` 结点).

### LLVM 的 DAG 相关的模型
中间代码产生的 IR 还不能直接应用到我们的指令选择, 因为

所以 DAG 还要经历所谓的 Lowering. 包括
* 操作本身: 将高层次的操作变得更低层次, 如把 IR 的 `call` 变成加载目标地址和 `jalr`
* 操作数: 目标架构支持的数据类型有限, 如 1 位的 bool 需要被拓展到 32 位.

# 使用 tablegen 描述目标架构
LLVM 的设计非常好, 只需要在称为 tablegen 的一种 DSL 中描述目标 ISA,
之后就只用写 "一点" C++ 代码就能完成上述步骤. (还是需要几千行)

DSL 描述 ISA (称为一个 Target) 我们需要描述的有

* 寄存器结构:
  - 有多少寄存器
  - 每个是什么名字
  - 有那些寄存器类别
  - 其他包括 dwarf 调试信息等

* 指令信息:
  - 指令有哪几种编码, 都是什么样的
  - 指令的操作数描述, 如 16 位立即数, 如 `imm($ra)`
  - 每条指令的功能: 他的操作对应 IR 中那个操作 (如 `add` 和 `addiu` 对应 IR 中的 `add`)
  - 每条指令的编码
  - 每条指令的额外信息, 如是否是跳转, 有那些输入的操作数, 输出又是那些操作数
  - ISel 中使用的 DAG 模式 (后文细述)

* Calling Conventions 调用约定:
  - 那些寄存器是 caller save? 那些是 callee save
  - 参数和返回值是放到寄存器里还是栈上, 分别又是放到哪里

之后对于每个 Subtarget (同一个 Target, 但是有不同的变种如 Mips16, Mips32) 把信息综合起来到一个 tablegen 里面.

# 工作步骤
构建一个 llvm 后端, 参考 Cpu0 文档的设计, 完成如下步骤

1. 在 llvm 框架中注册后端, 此时如果编译会得到错误 `cannot allocate TargetMachine`
2. 加入寄存器描述 `XXXRegisterInfo.td`, 指令描述 `XXXInstrInfo.td` 和 `XXXInstrFormat.td`

# 参考文献
* Getting Started with LLVM Core Libraries.pdf
* Cpu0 两篇文档
* tricore\_llvm.pdf
* Cormack-BuildingAnLLVMBackend.pdf
