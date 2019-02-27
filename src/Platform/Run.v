Require Import Coq.ZArith.BinInt.
Require Import coqutil.Word.LittleEndian.
Require Import riscv.util.Monads.
Require Import riscv.util.MonadNotations.
Require Import riscv.Decode.
Require Import riscv.Memory. (* should go before Program because both define loadByte etc *)
Require Import riscv.Program.
Require Import riscv.Execute.
Require Import riscv.util.PowerFunc.
Require Import riscv.Utility.

Section Riscv.

  Context {mword: Type}.
  Context {MW: MachineWidth mword}.

  Context {M: Type -> Type}.
  Context {MM: Monad M}.
  Context {RVP: RiscvProgram M mword}.
  Context {RVS: RiscvState M mword}.

  Definition run1(iset: InstructionSet):
    M unit :=
    pc <- getPC;
    inst <- loadWord pc;
    execute (decode iset (combine 4 inst));;
    step.

  Definition run(iset: InstructionSet)(n: nat): M unit :=
    power_func (fun m => run1 iset;; m) n (Return tt).

End Riscv.