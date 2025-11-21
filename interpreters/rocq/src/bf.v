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

Definition bf_default_fuel := 5000.

Fixpoint interp (p : bf_program) (s : bf_state) (fuel : nat) {struct fuel} : option bf_state :=
  match fuel, p with
  | O, nil => Some s
  | O, _ => None
  | _, nil => Some s
  | S (fuel'), h :: t => match interp_single h s fuel' with
    | Some s' => interp t s' fuel'
    | None => None
    end
  end

with interp_single (c : bf_command) (s : bf_state) (fuel : nat) {struct fuel} : option bf_state :=
  match fuel with
  | O => None
  | S fuel' =>
    match c with
    | bf_inc => Some {| tape := inc_cell (tape s); input := input s; output := output s |}
    | bf_dec => Some {| tape := dec_cell (tape s); input := input s; output := output s |}
    | bf_next => Some {| tape := move_right (tape s); input := input s; output := output s |}
    | bf_prev => Some {| tape := move_left (tape s); input := input s; output := output s |}
    | bf_input => Some (input_cell s)
    | bf_output => Some (output_cell s)
    | bf_loop body => let fix loop (s : bf_state) (fuel : nat) :=
        match fuel with
        | O => None
        | S (fuel') => if (curr (tape s)) =? 0 then Some s else
          match interp body s fuel' with
          | None => None
          | Some s' => loop s' fuel'
          end
        end
        in loop s fuel'
    end
  end.

Definition default_interp (prg : bf_program) :=
  interp prg bf_default_state bf_default_fuel.

Definition get_tape (state : option bf_state) : option bf_tape :=
  match state with
  | Some s => Some (tape s)
  | None => None
  end.

Definition get_curr (state : option bf_state) : option nat :=
  match state with
  | Some s => Some (curr (tape s))
  | None => None
  end.

(* Theorems And Tests *)

Example inc_test :
  get_curr (default_interp [bf_inc]) = Some 1.
Proof. reflexivity. Qed.

Example quadruple_inc_test :
  get_curr (default_interp [bf_inc; bf_inc; bf_inc; bf_inc]) = Some 4.
Proof. reflexivity. Qed.
