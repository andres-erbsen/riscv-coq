Require Import Coq.ZArith.BinInt.
Require Import bbv.WordScope.
Require Import bbv.DepEqNat.
Require Import riscv.util.NameWithEq.
Require Import riscv.RiscvBitWidths.
Require Import riscv.util.Monads.
Require Import riscv.Decode.
Require Import riscv.Memory. (* should go before Program because both define loadByte etc *)
Require Import riscv.Program.
Require Import riscv.Execute.
Require Import riscv.util.PowerFunc.
Require Import riscv.Utility.
Require Import Coq.Lists.List.

Section Riscv.

  Context {B: RiscvBitWidths}.

  Context {MW: MachineWidth (word wXLEN)}.

  Context {Mem: Set}.

  Context {MemIsMemory: Memory Mem (word wXLEN)}.

  Definition Register := Z.

  Definition Register0: Register := 0%Z.

  Instance ZName: NameWithEq := {|
    name := Z
  |}.

  Record RiscvMachine := mkRiscvMachine {
    machineMem: Mem;
    registers: Register -> word wXLEN;
    pc: word wXLEN;
    nextPC: word wXLEN;
    exceptionHandlerAddr: MachineInt;
  }.

  Definition with_machineMem me ma :=
    mkRiscvMachine me ma.(registers) ma.(pc) ma.(nextPC) ma.(exceptionHandlerAddr).
  Definition with_registers r ma :=
    mkRiscvMachine ma.(machineMem) r ma.(pc) ma.(nextPC) ma.(exceptionHandlerAddr).
  Definition with_pc p ma :=
    mkRiscvMachine ma.(machineMem) ma.(registers) p ma.(nextPC) ma.(exceptionHandlerAddr).
  Definition with_nextPC npc ma :=
    mkRiscvMachine ma.(machineMem) ma.(registers) ma.(pc) npc ma.(exceptionHandlerAddr).
  Definition with_exceptionHandlerAddr eh ma :=
    mkRiscvMachine ma.(machineMem) ma.(registers) ma.(pc) ma.(nextPC) eh.

  Definition liftLoad{sz: nat}(f: Mem -> word wXLEN -> word sz)(a: word wXLEN)
    : OState RiscvMachine (word sz) :=
    m <- gets machineMem; Return (f m a).

  Definition liftStore{sz: nat}(f: Mem -> word wXLEN -> word sz -> Mem)
    (a: word wXLEN)(v: word sz) : OState RiscvMachine unit :=
    m <- get; let mem' := f m.(machineMem) a v in put (with_machineMem mem' m).

  Instance IsRiscvMachine: RiscvState (OState RiscvMachine) :=
  {|
      getRegister := fun (reg: name) =>
        if dec (reg = Register0) then
          Return $0
        else
          machine <- get; Return (machine.(registers) reg);

      setRegister := fun (reg: name) v =>
        if dec (reg = Register0) then
          Return tt
        else
          machine <- get;
          let newRegs := (fun reg2 => if dec (reg = reg2)
                                      then v
                                      else machine.(registers) reg2) in
          put (with_registers newRegs machine);

      getPC := gets pc;

      setPC := fun newPC =>
        machine <- get;
        put (with_nextPC newPC machine);

      loadByte   := liftLoad Memory.loadByte;
      loadHalf   := liftLoad Memory.loadHalf;
      loadWord   := liftLoad Memory.loadWord;
      loadDouble := liftLoad Memory.loadDouble;

      storeByte   := liftStore Memory.storeByte;
      storeHalf   := liftStore Memory.storeHalf;
      storeWord   := liftStore Memory.storeWord;
      storeDouble := liftStore Memory.storeDouble;

      step :=
        m <- get;
        put (with_nextPC (m.(nextPC) ^+ $4) (with_pc m.(nextPC) m));

      getCSRField_MTVecBase :=
        gets exceptionHandlerAddr;

      endCycle A := fun _ => None; (* TODO that's wrong, TODO get monad transformer stuff right *)
  |}.

  (* Puts given program at address 0, and makes pc point to beginning of program, i.e. 0.
     TODO maybe later allow any address?
     Note: Keeps the original exceptionHandlerAddr, and the values of the registers,
     which might contain any undefined garbage values, so the compiler correctness proof
     will show that the program is correct even then, i.e. no initialisation of the registers
     is needed. *)
  Definition putProgram(prog: list (word 32))(m: RiscvMachine): RiscvMachine :=
    match m with
    | mkRiscvMachine m regs _ _ eh =>
        mkRiscvMachine (store_word_list prog $0 m) regs $0 $4 eh
    end.

End Riscv.

Existing Instance IsRiscvMachine. (* needed because it was defined inside a Section *)
