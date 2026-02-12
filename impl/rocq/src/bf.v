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
  output := nil;
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

Fixpoint fold_oper (f : bf_tape -> bf_tape) (t : bf_tape) (n : nat) := match n with
| O => t
| S n' => fold_oper f (f t) n'
end.

Definition add_cell := fold_oper inc_cell.
Definition sub_cell := fold_oper dec_cell.
Definition move_left := fold_oper shift_left.
Definition move_right := fold_oper shift_right.

Definition zero_cell (t : bf_tape) : bf_tape := {|
  left := left t;
  curr := O;
  right := right t;
|}.

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

Example opt_zero : opt_is_equiv <[ + + + + [ - !] !]>.
Proof. reflexivity. Qed.

Theorem zero_opt_is_equiv : forall s : bf_state,
  interp default_fuel s <[ [ - !] !]> = opt_interp default_fuel s (bf_opt_cons bf_opt_zero bf_opt_nil).
Proof.
Admitted.

(* Fuel-free big-step semantics *)

(* Unoptimized program semantics *)
Inductive eval : bf_program -> bf_state -> bf_state -> Prop :=
| eval_nil : forall s, eval bf_nil s s
| eval_cons : forall c p s s1 s2,
    eval_cmd c s s1 ->
    eval p s1 s2 ->
    eval (bf_cons c p) s s2

with eval_cmd : bf_command -> bf_state -> bf_state -> Prop :=
| eval_inc : forall s,
    eval_cmd bf_inc s {| tape := inc_cell (tape s); input := input s; output := output s |}
| eval_dec : forall s,
    eval_cmd bf_dec s {| tape := dec_cell (tape s); input := input s; output := output s |}
| eval_next : forall s,
    eval_cmd bf_next s {| tape := shift_right (tape s); input := input s; output := output s |}
| eval_prev : forall s,
    eval_cmd bf_prev s {| tape := shift_left (tape s); input := input s; output := output s |}
| eval_input : forall s,
    eval_cmd bf_input s (input_cell s)
| eval_output : forall s,
    eval_cmd bf_output s (output_cell s)
| eval_loop_zero : forall body s,
    curr (tape s) = 0 ->
    eval_cmd (bf_loop body) s s
| eval_loop_step : forall body s s1 s2,
    curr (tape s) <> 0 ->
    eval body s s1 ->
    eval_cmd (bf_loop body) s1 s2 ->
    eval_cmd (bf_loop body) s s2.

(* Optimized program semantics *)
(* forall s: Generalizations about each starting state *)
Inductive eval_opt : bf_opt_program -> bf_state -> bf_state -> Prop :=
| eval_opt_nil : forall s, eval_opt bf_opt_nil s s
| eval_opt_cons : forall c p s s1 s2,
    eval_opt_cmd c s s1 ->
    eval_opt p s1 s2 ->
    eval_opt (bf_opt_cons c p) s s2

with eval_opt_cmd : bf_opt_command -> bf_state -> bf_state -> Prop :=
| eval_opt_inc : forall s n,
    eval_opt_cmd (bf_opt_inc n) s {| tape := add_cell (tape s) n; input := input s; output := output s |}
| eval_opt_dec : forall s n,
    eval_opt_cmd (bf_opt_dec n) s {| tape := sub_cell (tape s) n; input := input s; output := output s |}
| eval_opt_zero : forall s,
    eval_opt_cmd bf_opt_zero s {| tape := zero_cell (tape s); input := input s; output := output s |}
| eval_opt_next : forall s n,
    eval_opt_cmd (bf_opt_next n) s {| tape := move_right (tape s) n; input := input s; output := output s |}
| eval_opt_prev : forall s n,
    eval_opt_cmd (bf_opt_prev n) s {| tape := move_left (tape s) n; input := input s; output := output s |}
| eval_opt_input : forall s,
    eval_opt_cmd bf_opt_input s (input_cell s)
| eval_opt_output : forall s,
    eval_opt_cmd bf_opt_output s (output_cell s)
| eval_opt_loop_zero : forall body s,
    curr (tape s) = 0 ->
    eval_opt_cmd (bf_opt_loop body) s s
| eval_opt_loop_step : forall body s s1 s2,
    curr (tape s) <> 0 ->
    eval_opt body s s1 ->
    eval_opt_cmd (bf_opt_loop body) s1 s2 ->
    eval_opt_cmd (bf_opt_loop body) s s2.

Scheme eval_ind' := Induction for eval Sort Prop
with eval_cmd_ind' := Induction for eval_cmd Sort Prop.

Scheme eval_opt_ind' := Induction for eval_opt Sort Prop
with eval_opt_cmd_ind' := Induction for eval_opt_cmd Sort Prop.

(* Bridging lemmas between the fueled interpreter and the fuel-free semantics.
   These let us reason “as if fuel were infinite”, and only discharge fuel
   obligations when reusing the executable interpreter. *)

Lemma interp_sound : forall f s p s',
  interp f s p = Some s' -> eval p s s'.
Proof.
  intros. induction f.
  - destruct p; simpl in H.
    + inversion H. constructor.
    + discriminate.
  - cbn in H. destruct p.
    + inversion H. constructor.
    + destruct b.
Admitted.

Lemma opt_interp_sound : forall f s p s',
  opt_interp f s p = Some s' -> eval_opt p s s'.
Proof.
Admitted.

Lemma interp_complete : forall p s s',
  eval p s s' -> exists f, interp f s p = Some s'.
Proof.
Admitted.

Lemma opt_interp_complete : forall p s s',
  eval_opt p s s' -> exists f, opt_interp f s p = Some s'.
Proof.
Admitted.

Lemma interp_monotone : forall f f' s p s',
  f' >= f ->
  interp f s p = Some s' ->
  interp f' s p = Some s'.
Proof.
Admitted.

Lemma opt_interp_monotone : forall f f' s p s',
  f' >= f ->
  opt_interp f s p = Some s' ->
  opt_interp f' s p = Some s'.
Proof.
Admitted.

(* Determinism facts for the optimized state transformers *)

Lemma add_succ_r : forall n m : nat,
  n + S(m) = S(n + m).
Proof.
  intros n m. induction n as [| n' IHn'].
  - simpl. reflexivity.
  - simpl. rewrite -> IHn'. reflexivity.
Qed.

Lemma add_succ_l : forall n m : nat,
  S(n) + m = S(n + m).
Proof.
  intros n m. induction n as [| n' IHn'].
  - simpl. reflexivity.
  - simpl. rewrite <- IHn'. reflexivity.
Qed.

Lemma add_cell_add : forall t n m,
  add_cell t (n + m) = add_cell (add_cell t n) m.
Proof.
  induction n; intros; simpl.
  - reflexivity.
  - admit.
Admitted.

Lemma sub_cell_add : forall t n m,
  sub_cell t (n + m) = sub_cell (sub_cell t n) m.
Proof.
  induction n; intros; simpl.
  - reflexivity.
  - admit.
Admitted.

Lemma move_right_add : forall t n m,
  move_right t (n + m) = move_right (move_right t n) m.
Proof.
  induction n; intros; simpl.
  - reflexivity.
  - admit.
  (* - rewrite Nat.add_succ_l. simpl. apply IHn. *)
Admitted.

Lemma move_left_add : forall t n m,
  move_left t (n + m) = move_left (move_left t n) m.
Proof.
  induction n; intros; simpl.
  - reflexivity.
  - rewrite Nat.add_succ_l. simpl. apply IHn.
Qed.

Lemma eval_opt_cons_inv : forall c p s s',
  eval_opt (bf_opt_cons c p) s s' ->
  exists sm, eval_opt_cmd c s sm /\ eval_opt p sm s'.
Proof.
  intros. inversion H; subst. eauto.
Qed.

(* Specialized lemma for the optimized zeroing loop [-] *)
Lemma loop_minus_zero : forall s s',
  eval_cmd (bf_loop <[ - !]>) s s' ->
  s' = {| tape := zero_cell (tape s); input := input s; output := output s |}.
Proof.
  intros s s' H.
  remember (curr (tape s)) as n eqn:Hn.
  revert s s' Hn H.
  induction n; intros s s' Hn H.
  - (* current cell already zero *)
    inversion H; subst; inversion H3; subst; simpl in *; congruence.
  - (* current cell nonzero, we decrement once and recurse *)
    inversion H; subst; try congruence.
    inversion H6; subst.
    specialize (IHn _ _ eq_refl H10).
    simpl in IHn.
    (* After one decrement, curr decreases by 1; inputs/outputs unchanged *)
    rewrite Hn in H12. simpl in H12.
    injection H12 as <-.
    simpl in IHn.
    assumption.
Qed.

(* Theorems *)

Theorem opt_sound : forall p s s',
  eval p s s' -> eval_opt (bf_optimize p) s s'.
Proof.
  intros.
  induction H.
  - constructor.
  - destruct c.
    + inversion H0; simpl.

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
