Require Import Coq.Lists.List.
Require Import Coq.ZArith.ZArith.
Require Import coqutil.Word.Interface.
Require Import coqutil.Word.Properties.
Require Import coqutil.Datatypes.HList.
Require Import coqutil.Datatypes.PrimitivePair.
Require Import coqutil.Map.Interface.
Require Import coqutil.Tactics.Tactics.
Require Import coqutil.sanity.
Require Import coqutil.Z.Lia.

Local Open Scope Z_scope.


Section MemAccess.
  Context {byte: word 8} {width: Z} {word: word width} {mem: map.map word byte}.

  Definition footprint(a: word)(sz: nat): tuple word sz :=
    tuple.unfoldn (fun w => word.add w (word.of_Z 1)) sz a.

  Definition load_bytes(sz: nat)(m: mem)(addr: word): option (tuple byte sz) :=
    map.getmany_of_tuple m (footprint addr sz).

  Definition unchecked_store_bytes(sz: nat)(m: mem)(a: word)(bs: tuple byte sz): mem :=
    map.putmany_of_tuple (footprint a sz) bs m.

  Definition store_bytes(sz: nat)(m: mem)(a: word)(v: tuple byte sz): option mem :=
    match load_bytes sz m a with
    | Some _ => Some (unchecked_store_bytes sz m a v)
    | None => None (* some addresses were invalid *)
    end.

  Definition unchecked_store_byte_list(a: word)(l: list byte)(m: mem): mem :=
    unchecked_store_bytes (length l) m a (tuple.of_list l).

  Lemma unchecked_store_byte_list_cons: forall a x (l: list byte) m,
      unchecked_store_byte_list a (x :: l) m =
      map.put (unchecked_store_byte_list (word.add a (word.of_Z 1)) l m) a x.
  Proof.
    intros. reflexivity.
  Qed.

End MemAccess.


Require Import riscv.Utility.Utility.

Section MemAccess2.
  Context {W: Words} {mem: map.map word byte}.

  Definition loadByte:   mem -> word -> option w8  := load_bytes 1.
  Definition loadHalf:   mem -> word -> option w16 := load_bytes 2.
  Definition loadWord:   mem -> word -> option w32 := load_bytes 4.
  Definition loadDouble: mem -> word -> option w64 := load_bytes 8.

  Definition storeByte  : mem -> word -> w8  -> option mem := store_bytes 1.
  Definition storeHalf  : mem -> word -> w16 -> option mem := store_bytes 2.
  Definition storeWord  : mem -> word -> w32 -> option mem := store_bytes 4.
  Definition storeDouble: mem -> word -> w64 -> option mem := store_bytes 8.
End MemAccess2.


Local Unset Universe Polymorphism.

Section MemoryHelpers.
  Context {W: Words}.
  Add Ring wring: (@word.ring_theory width word word_ok).

  Goal forall (a: word), word.add a (word.of_Z 0) = a. intros. ring. Qed.

  Lemma regToZ_unsigned_add: forall (a b: word),
      0 <= word.unsigned a + word.unsigned b < 2 ^ width ->
      word.unsigned (word.add a b) = word.unsigned a + word.unsigned b.
  Proof.
    intros.
    rewrite word.unsigned_add.
    apply Z.mod_small. assumption.
  Qed.

  Lemma regToZ_unsigned_add_l: forall (a: Z) (b: word),
      0 <= a ->
      0 <= a + word.unsigned b < 2 ^ width ->
      word.unsigned (word.add (word.of_Z a) b) = a + word.unsigned b.
  Proof.
    intros.
    rewrite word.unsigned_add.
    rewrite word.unsigned_of_Z.
    pose proof (word.unsigned_range b).
    unfold word.wrap.
    rewrite (Z.mod_small a) by bomega.
    rewrite Z.mod_small by assumption.
    reflexivity.
  Qed.

  Lemma regToZ_unsigned_add_r: forall (a: word) (b: Z),
      0 <= b ->
      0 <= word.unsigned a + b < 2 ^ width ->
      word.unsigned (word.add a (word.of_Z b)) = word.unsigned a + b.
  Proof.
    intros.
    rewrite word.unsigned_add.
    rewrite word.unsigned_of_Z.
    pose proof (word.unsigned_range a).
    unfold word.wrap.
    rewrite (Z.mod_small b) by bomega.
    rewrite Z.mod_small by assumption.
    reflexivity.
  Qed.
End MemoryHelpers.
