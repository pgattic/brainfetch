From Stdlib Require Import List Arith.

Inductive bf_program : Type :=
| bf_nil : bf_program
| bf_cons : bf_command -> bf_program -> bf_program

with bf_command : Type :=
| bf_inc
| bf_dec
| bf_next
| bf_prev
| bf_input
| bf_output
| bf_loop (body : bf_program).

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

Definition bf_default_state : bf_state := {|
  tape := {| left := nil; curr := 0; right := nil |};
  input := nil;
  output := nil
|}.

(* Interpretation Commands *)

Definition inc_cell (t : bf_tape) : bf_tape := {|
  left := left t;
  curr := S (curr t) mod 256;
  right := right t;
|}.

Definition dec_cell (t : bf_tape) : bf_tape := {|
  left := left t;
  curr := match curr t with | 0 => 255 | S n' => n' end;
  right := right t;
|}.

Definition shift_left (tape : bf_tape) : bf_tape :=
  match left tape with
  | nil => {| left := nil; curr := 0; right := (curr tape) :: (right tape) |}
  | h :: t => {| left := t; curr := h; right := (curr tape) :: (right tape) |}
  end.

Definition shift_right (tape : bf_tape) : bf_tape :=
  match right tape with
  | nil => {| left := (curr tape) :: (left tape); curr := 0; right := nil |}
  | h :: t => {| left := (curr tape) :: (left tape); curr := h; right := t |}
  end.

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

Fixpoint interp (fuel : nat) (s : bf_state) (p : bf_program) : option bf_state :=
  match fuel, p with
  | O, bf_nil => Some s
  | O, _ => None
  | _, bf_nil => Some s
  | S (fuel'), bf_cons h t => match interp_single fuel' s h with
    | Some s' => interp fuel' s' t
    | None => None
    end
  end

with interp_single (loop_fuel : nat) (s : bf_state) (c : bf_command) : option bf_state :=
  match c with
  | bf_inc => Some {| tape := inc_cell (tape s); input := input s; output := output s |}
  | bf_dec => Some {| tape := dec_cell (tape s); input := input s; output := output s |}
  | bf_next => Some {| tape := shift_right (tape s); input := input s; output := output s |}
  | bf_prev => Some {| tape := shift_left (tape s); input := input s; output := output s |}
  | bf_input => Some (input_cell s)
  | bf_output => Some (output_cell s)
  | bf_loop body => let fix loop (fuel : nat) (s : bf_state) := match fuel with
    | O => None
    | S (fuel') => if (curr (tape s)) =? 0 then Some s else
      match interp fuel' s body with
      | None => None
      | Some s' => loop fuel' s'
      end
    end
    in loop loop_fuel s
  end.

Definition default_fuel := 5000.

(* Helper functions *)
Definition default_interp := interp default_fuel bf_default_state.

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


(* Notation *)

Declare Custom Entry bf.

(* Write BF programs as: <[ ... ]> *)
Notation "<[ p ]>" := p
  (p custom bf at level 0).

(* End-of-program marker *)
Notation "!" := bf_nil
  (in custom bf at level 0).

(* Sequencing: "cmd rest" means bf_cons cmd rest *)
Notation "c p" := (bf_cons c p)
  (in custom bf at level 0,
      right associativity).

(* Basic commands (BF-style) *)
Notation "+" := bf_inc    (in custom bf at level 0).
Notation "-" := bf_dec    (in custom bf at level 0).
Notation ">" := bf_next   (in custom bf at level 0).
Notation "<" := bf_prev   (in custom bf at level 0).
Notation "," := bf_input  (in custom bf at level 0).

(* Output command: use '@' instead of '.' to avoid conflicts *)
Notation "@" := bf_output (in custom bf at level 0).

(* Loops: [ body ] rest *)
Notation "[ p ']' q" :=
  (bf_cons (bf_loop p) q)
  (in custom bf at level 0,
      right associativity).


(* Tests *)

Example inc_test :
  get_curr (default_interp <[ + !]>) = Some 1.
Proof. reflexivity. Qed.

Example quadruple_inc_test :
  get_curr (default_interp <[ + + + + !]>) = Some 4.
Proof. reflexivity. Qed.

Definition hello_world : bf_program :=
  <[ + + + + + + + + [ > + + + + [ > + + > + + + > + + + > + < < < < - ! ] > + > + > - > > + [ < ! ] < - ! ] > > @ > - - - @ + + + + + + + @ @ + + + @ > > @ < - @ < @ + + + @ - - - - - - @ - - - - - - - - @ > > + @ > + + @ ! ]>.

From Stdlib Require Import Ascii String List.

Definition output_text (state : option bf_state) : option string :=
  match state with
  | None => None
  | Some s => Some (string_of_list_ascii (map ascii_of_nat (rev (output s))))
  end.

(* Works!!! *)
Eval compute in output_text (default_interp hello_world).


(* Optimization *)

Inductive bf_opt_program : Type :=
| bf_opt_nil : bf_opt_program
| bf_opt_cons : bf_opt_command -> bf_opt_program -> bf_opt_program

with bf_opt_command : Type :=
| bf_opt_inc (count : nat)
| bf_opt_dec (count : nat)
| bf_opt_zero (* Meant for instances of `[-]` *)
| bf_opt_next (count : nat)
| bf_opt_prev (count : nat)
| bf_opt_input
| bf_opt_output
| bf_opt_loop (body : bf_opt_program).

Definition merge_command (cmd : bf_opt_command) (rest : bf_opt_program) : bf_opt_program :=
  match cmd, rest with
  | bf_opt_inc n,  bf_opt_cons (bf_opt_inc m) t =>  bf_opt_cons (bf_opt_inc (n + m)) t
  | bf_opt_dec n,  bf_opt_cons (bf_opt_dec m) t =>  bf_opt_cons (bf_opt_dec (n + m)) t
  | bf_opt_next n, bf_opt_cons (bf_opt_next m) t => bf_opt_cons (bf_opt_next (n + m)) t
  | bf_opt_prev n, bf_opt_cons (bf_opt_prev m) t => bf_opt_cons (bf_opt_prev (n + m)) t
  | _, _ => bf_opt_cons cmd rest
  end.

Fixpoint bf_optimize (p : bf_program) : bf_opt_program :=
  match p with
  | bf_nil => bf_opt_nil
  | bf_cons c t =>
      (* optimize a single command, using bf_optimize recursively for loops *)
      let optimized_c :=
        match c with
        | bf_inc => bf_opt_inc 1
        | bf_dec => bf_opt_dec 1
        | bf_next => bf_opt_next 1
        | bf_prev => bf_opt_prev 1
        | bf_input => bf_opt_input
        | bf_output => bf_opt_output
        | bf_loop body =>
            let optimized_body := bf_optimize body in
            match optimized_body with
            | bf_opt_cons (bf_opt_dec 1) bf_opt_nil => bf_opt_zero
            | _ => bf_opt_loop optimized_body
            end
        end in
      merge_command optimized_c (bf_optimize t)
  end.


(* Interpreting Optimized Programs *)

Fixpoint add_cell (t : bf_tape) (n : nat) : bf_tape := match n with
| O => t
| S n' => add_cell (inc_cell t) n'
end.

Fixpoint sub_cell (t : bf_tape) (n : nat) : bf_tape := match n with
| O => t
| S n' => sub_cell (dec_cell t) n'
end.

Definition zero_cell (t : bf_tape) : bf_tape := {|
  left := left t;
  curr := O;
  right := right t;
|}.

Fixpoint move_left (t : bf_tape) (n : nat) : bf_tape := match n with
| O => t
| S n' => move_left (shift_left t) n'
end.

Fixpoint move_right (t : bf_tape) (n : nat) : bf_tape := match n with
| O => t
| S n' => move_right (shift_right t) n'
end.

Fixpoint opt_interp (fuel : nat) (s : bf_state) (p : bf_opt_program) : option bf_state :=
  match fuel, p with
  | O, bf_opt_nil => Some s
  | O, _ => None
  | _, bf_opt_nil => Some s
  | S (fuel'), bf_opt_cons h t => match opt_interp_single fuel' s h with
    | Some s' => opt_interp fuel' s' t
    | None => None
    end
  end

with opt_interp_single (loop_fuel : nat) (s : bf_state) (c : bf_opt_command) : option bf_state :=
  match c with
  | bf_opt_inc n => Some {| tape := add_cell (tape s) n; input := input s; output := output s |}
  | bf_opt_dec n => Some {| tape := sub_cell (tape s) n; input := input s; output := output s |}
  | bf_opt_zero => Some {| tape := zero_cell (tape s); input := input s; output := output s |}
  | bf_opt_next n => Some {| tape := move_right (tape s) n; input := input s; output := output s |}
  | bf_opt_prev n => Some {| tape := move_left (tape s) n; input := input s; output := output s |}
  | bf_opt_input => Some (input_cell s)
  | bf_opt_output => Some (output_cell s)
  | bf_opt_loop body => let fix loop (fuel : nat) (s : bf_state) := match fuel with
    | O => None
    | S (fuel') => if (curr (tape s)) =? 0 then Some s else
      match opt_interp fuel' s body with
      | None => None
      | Some s' => loop fuel' s'
      end
    end
    in loop loop_fuel s
  end.

Definition default_opt_interp := opt_interp default_fuel bf_default_state.

(* Optimization tests *)

Definition opt_is_equiv (p : bf_program) : Prop := default_interp p = default_opt_interp (bf_optimize p).

Example opt_single_inc : opt_is_equiv <[ + !]>.
Proof. reflexivity. Qed.

Example opt_multi_inc : opt_is_equiv <[ + + + !]>.
Proof. reflexivity. Qed.



(* Theorems *)

(* For any amount of fuel, there exists a program that will use it all up *)

Theorem fuel_necessary : forall (f : nat) (s : bf_state),
  exists (p : bf_program), interp f s p = None.
Proof.
  intros. induction f.
  - simpl. exists <[ + !]>. reflexivity.
  - simpl. admit.
Admitted.

Lemma option_equality : forall (X : Type) (x y : X),
  Some x = Some y -> x = y.
Proof.
  intros.
  injection H. intros.
  apply H0.
Qed.

Theorem cell_max_single : forall (f : nat) (s : bf_state) (c : bf_command),
  interp_single f s c = Some s -> curr (tape s) < 255.
Proof.
  intros. induction c.
  - unfold interp_single in H. simpl in H. admit.
Admitted.

(* Prove that all cells stay between 0..=255 *)
Theorem cell_max : forall (p : bf_program) (s : bf_state),
  default_interp p = Some s -> curr (tape s) <= 255.
Proof.
  intros. induction p.
  - simpl in H. apply option_equality in H. rewrite <- H. simpl. apply le_0_n.
  - intros. induction s.
Admitted. (* DO NOT try `simpl in H` *)
