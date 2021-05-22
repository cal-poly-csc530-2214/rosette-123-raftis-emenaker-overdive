#lang rosette

; We'll use this from Q1.1 to prove that the conversion to CNF was correct
(define (classify F)
  (if (sat? (solve (assert F)))
      (if (sat? (solve (assert (! F))))
          "CONTINGENCY"
          "TAUTOLOGY"
          ) "CONTRADICTION"))

; Objective, convert:
;            ¬(¬r → ¬(p ∧ q))
; to CNF via Tseitin' encoding
;
; Auxillary variables:
;  x0 = (p ∧ q)
;  x1 = ¬r → ¬(p ∧ q) = ¬r → ¬x0

; Rewrite as a conjunction:
;
;    ¬(¬r → ¬(p ∧ q))
; becomes... (assume all lines are conjuncted):
;    ¬x1
;    x1 ↔ (¬r → ¬x0)
;    x0 ↔ (p ∧ q)

; split bi-directional implications into two uni-directional
;    ¬x1
;    x1 → (¬r → ¬x0)
;    (¬r → ¬x0) → x1
;    x0 → (p ∧ q)
;    (p ∧ q) → x0

; remove implications
;    ¬x1
;    ¬x1 ∨ (r ∨ ¬x0) 
;    ¬(r ∨ ¬x0) ∨ x1
;    ¬x0 ∨ (p ∧ q)
;    ¬(p ∧ q) ∨ x0

; distribute negations per DeMorgan (and remove redundant parens)
;    ¬x1
;    ¬x1 ∨ r ∨ ¬x0 
;    (¬r ∧ x0) ∨ x1
;    ¬x0 ∨ (p ∧ q)
;    ¬p ∨ ¬q ∨ x0

; distribute disjunctions inward, conjunctions outward
;    ¬x1
;    ¬x1 ∨ r ∨ ¬x0 
;    (¬r ∨ x1) ∧ (x0 ∨ x1)
;    (¬x0 ∨ p) ∧ (¬x0 ∨ q)
;    ¬p ∨ ¬q ∨ x0

; split remaining disjunctions to separate lines
;    ¬x1
;    ¬x1 ∨ r  ∨ ¬x0 
;     ¬r ∨ x1
;     x0 ∨ x1
;    ¬x0 ∨ p
;    ¬x0 ∨ q
;     ¬p ∨ ¬q ∨ x0


; Original expression
(define-symbolic* p q r boolean?)

(define old_exp (! (=> (! r) (! (&& p q)))))

; New CNF expression
(define-symbolic* x0 x1 boolean?)

(define new_exp0 (! x1))
(define new_exp1 (|| (! x1) r (! x0)))
(define new_exp2 (|| (! r) x1))
(define new_exp3 (|| x0 x1))
(define new_exp4 (|| (! x0) p))
(define new_exp5 (|| (! x0) q))
(define new_exp6 (|| (! p) (! q) x0))
(define new_exp  (&& new_exp0 new_exp1 new_exp2 new_exp3 new_exp4 new_exp5 new_exp6))

; Let's see if they're the same
(define comparison1 (<=> new_exp old_exp))
(classify comparison1)  ; This produces CONTINGENCY. Why?

; The reason we get CONTINGENCY (I think) is because x0 and x1 are unconstrained
; in the given expression, so rosette can assign those whatever it wants to make the old
; and new expressions either match or not. We need to attach definitions of x0 and x1
; to the given expression...

;  include  x0 <=> (p ∧ q)    x1 <=> ¬r → ¬(p ∧ q)
(define old_exp_w_x0_x1 (&& old_exp (<=> x0 (&& p q)) (<=> x1 (=> (! r) (! (&& p q))))))  

(define comparison2 (<=> new_exp old_exp_w_x0_x1))
(classify comparison2) ; <-- THIS will give TAUTOLOGY

