#lang racket

(require "solver.rkt" "graph.rkt")

(provide
 k-coloring      ; (->* (graph/c natural-number/c) [(is-a? solver%)] (or/c #f coloring/c))
 valid-coloring? ; (-> graph/c coloring/c boolean?)
)

; Returns true iff the given coloring is correct for the specified graph.
(define (valid-coloring? graph coloring)
  (and (coloring/c coloring)
       (= (color-size coloring) (node-count graph))
       (for*/and ([(e n) (in-indexed graph)] [child e])
         (not (= (color-ref coloring n) (color-ref coloring child))))))


; Given a graph with N nodes and K colors, generates a set of CNF clauses
; based upon integer-referenced propositions, for example:
; 0 = node 0 has color 0
; 1 = node 0 has color 1
; ...
; K-1 = node 0 has color K-1
; K = node 1 has color 0
; K+1 = node 1 has color 1
; ...
; n*K+c-1 = node n has color c
;
; A sample clause might be (0 1 2 3 ... K-1) which means that node 1 has to have at least one color.
; We will need one of those for each node
;
; Another clause could be (-1 -(K+1)) which means that node 1 and node 2 cannot both be color 1.
; We would need one of these for every color for every two nodes that share an edge

(define (value-for-node-color node color colors)
  (+ 1 (* node colors) color)
)


(define (require-nodes-have-colors n colors)
  (if (>= n 1)
      ; For this node, n, we need to go through all k colors an assert that the node has at least one of those colors
      ; and we append that to what we get for the rest of the nodes
      (cons
       ; For each color, (range colors), get the variable number for node n-1 (because nodes start with 0)
       (map (lambda (color) (value-for-node-color (- n 1) color colors)) (range colors))
       (require-nodes-have-colors (- n 1) colors)
      )
      (list)
  )
)

; Generates a set of CNF clauses that prevent the two nodes from having the same color
(define (proscribe-same-colors node1 node2 k)
  ; Strategy: Generate a range of all colors, 0 -> (k-1), and then map onto that
  ; range a lambda that replaces each element with a two-element list: (-(node1*K+color) -(node2*K+color))
  (map (lambda (color) (list (- (value-for-node-color node1 color k)) (- (value-for-node-color node2 color k)))) (range k))
)

; Generates a CNF that prevents any adjacent nodes from having the same colors
(define (require-different-colors-on-edges edge-stream k)
  (if (stream-empty? edge-stream)
      (list)
      (append
       (proscribe-same-colors (car (stream-first edge-stream)) (cdr (stream-first edge-stream)) k)
       (require-different-colors-on-edges  (stream-rest  edge-stream) k)
       ))
)

; Takes a list of numbers (each representing true/false for the use of a color) and returns
; the position of the first color that's positive. So, (-1 -2 3 -4) gives 2. (-12 13 -14 15) gives 1.
(define (lookup-color color-list color)
  (if (> (car color-list) 0)
     color
     (lookup-color (cdr color-list) (+ 1 color))
  )
)

; Takes a solution, where, in a 3-color attempt, (-1 -2 3 -4 5 -6 7 -8 -9) would be that node0 is color2,
; node1 is color1, node2 is color0...
; and turns it into a 'coloring' (eg. #( 2 1 0 )
; CAUTION: If this list is not an integer multiple of 'colors', there will be an error
(define (solution->coloring solution colors)
  (if (empty? solution)
      (list)
      (cons
        (lookup-color (take solution colors) 0)
        (solution->coloring (drop solution colors) colors)
      )
  )
)

; Returns a coloring/c if the given graph can 
; be colored with k colors.  Otherwise returns #f.
(define (k-coloring graph k)
  ; 'criteria' will be a CNF with kinds of criteria. We require that each node _have_ a color and
  ; that no two neighbors have the _same_ color. We can actually neglect to require that each node
  ; have _only_ one color since, if the solver is able to assign more than one color to a node, we
  ; can choose any of those colors
  (define criteria
    (append 
      (require-nodes-have-colors (node-count graph) k)
      (require-different-colors-on-edges (edges graph) k)
    )
  )
  (define solution (solve criteria))
  (list->vector (solution->coloring solution k))
)