From Stdlib Require Import List Arith.
Import ListNotations.

Inductive bf_command : Type :=
| bf_inc
| bf_dec
| bf_next
| bf_prev
| bf_input
| bf_output
| bf_loop (loop : list bf_command).

Definition bf_program := list bf_command.

Record bf_tape : Type := {
  left : list nat;
  curr : nat;
  right : list nat;
}.

Record bf_state : Type := {
  tape : bf_tape;
  input : list nat;
  output : list nat;
}.

Definition bf_default_state := {|
  tape := {| left := nil; curr := 0; right := nil |};
  input := nil;
  output := nil
|}.

(* Interpretation Commands *)

Definition move_left (tape : bf_tape) : bf_tape :=
  match left tape with
  | nil => {| left := nil; curr := 0; right := (curr tape) :: (right tape) |}
  | h :: t => {| left := t; curr := h; right := (curr tape) :: (right tape) |}
  end.

Definition move_right (tape : bf_tape) : bf_tape :=
  match right tape with
  | nil => {| left := (curr tape) :: (left tape); curr := 0; right := nil |}
  | h :: t => {| left := (curr tape) :: (left tape); curr := h; right := t |}
  end.

Definition inc_cell (t : bf_tape) : bf_tape := {|
  left := left t;
  curr := S (curr t);
  right := right t;
|}.

Definition dec_cell (t : bf_tape) : bf_tape := {|
  left := left t;
  curr := match curr t with | 0 => 0 | S n' => n' end;
  right := right t;
|}.

(* Puts the head value of the input list into the current cell *)
Definition input_cell (s : bf_state) : bf_state := 
  match input s with
  | nil => s
  | h :: t => {|
    tape := {| left := left (tape s); curr := h; right := right (tape s) |};
    input := t;
    output := output s
  |}
  end.

(* Reads the current cell value into the output list *)
Definition output_cell (s : bf_state) : bf_state := {|
  tape := tape s;
  input := input s;
  output := curr (tape s) :: output s
|}.

Fixpoint interp (p : bf_program) (s : bf_state) (fuel : nat) : bf_state :=
  match fuel, p with
  | O, nil => s
  | O, _ => s
  | _, nil => s
  | S (fuel'), h :: t => match h with
    | bf_inc => interp t {| tape := inc_cell (tape s); input := input s; output := output s |} fuel'
    | bf_dec => interp t {| tape := dec_cell (tape s); input := input s; output := output s |} fuel'
    | bf_next => interp t {| tape := move_right (tape s); input := input s; output := output s |} fuel'
    | bf_prev => interp t {| tape := move_left (tape s); input := input s; output := output s |} fuel'
    | bf_input => interp t (input_cell s) fuel'
    | bf_output => interp t (output_cell s) fuel'
    | bf_loop _ => interp t s fuel' (* TODO *)
    end
  end.

Definition bf_default_fuel := 5000.

Definition default_interp (prg : bf_program) :=
  interp prg bf_default_state bf_default_fuel.

Example inc_test :
  curr (tape (default_interp [bf_inc])) = 1.
Proof. reflexivity. Qed.

Example quidruple_inc_test :
  curr (tape (default_interp [bf_inc; bf_inc; bf_inc; bf_inc])) = 4.
Proof. reflexivity. Qed.
