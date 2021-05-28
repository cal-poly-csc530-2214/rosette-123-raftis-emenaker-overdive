#lang rosette

(provide (all-defined-out))

; Takes as input a propositional formula and returns
; * 'TAUTOLOGY if every interpretation I satisfies F;
; * 'CONTRADICTION if no interpretation I satisfies F;
; * 'CONTINGENCY if there are two interpretations I and I′ such that I satisfies F and I' does not.

; Strategy:
; If we cannot find a solution for F, then it's a CONTRADICTION
; If we CAN find a solution, and we can ALSO find a solution for !F, then it's a CONTIGENCY
; If we can ONLY find a solution for F, but NOT for !F, then it's a TAUTOLOGY
(define (classify F)
  (if (sat? (solve (assert F)))
      (if (sat? (solve (assert (! F))))
          "CONTINGENCY"
          "TAUTOLOGY"
          ) "CONTRADICTION"))

(define-symbolic* p q r boolean?)

; (p → (q → r)) → (¬r → (¬q → ¬p))
(define f0 (=> (=> p (=> q r)) (=> (! r) (=> (! q) (! p)))))

; (p ∧ q) → (p → q)
(define f1 (=> (&& p q) (=> p q)))

; (p ↔ q) ∧ (q → r) ∧ ¬(¬r → ¬p)
(define f2 (&& (<=> p q) (=> q r) (! (=> (! r) (! q)))))

; Tests:
; f0 is a CONTINGENCY (p,q,r)=(f,f,f) yields #t  while (p,q,r)=(t,f,f) yields #f
; f1 is a TAUTOLOGY (always true)
; f2 is a CONTRADICTION (always false)

(classify f0)
(classify f1)
(classify f2)
  
