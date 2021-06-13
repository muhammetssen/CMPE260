; Muhammet Şen
; 2018400192
; compiling: yes
; complete: yes

#lang racket
(provide (all-defined-out))
(struct num (value grad)
    #:property prop:custom-write
    (lambda (num port write?)
        (fprintf port (if write? "(num ~s ~s)" "(num ~a ~a)")
            (num-value num) (num-grad num))))
(define relu (lambda (x) (if (> (num-value x) 0) x (num 0.0 0.0))))
(define mse (lambda (x y) (mul (sub x y) (sub x y))))

(define (toStructList num-list) (map (lambda (x) (eval x)) num-list))
(define (get-value num-list) (
    cond
     [ 
        (list? num-list)
        (map (lambda (x) (num-value x)) (toStructList num-list))
    ] 
    [
        (num? num-list)
        (num-value num-list)
    ]
))
(define (get-grad num-list) (
    cond
     [ 
        (list? num-list)
        (map (lambda (x) (num-grad x)) (toStructList num-list))
    ] 
    [
        (num? num-list)
        (num-grad num-list)
    ]
))

(define isEqual ( lambda (num1 num2) (and (eq?(num-value num1) (num-value num2)) (eq?(num-grad num1) (num-grad num2 )))))

(define add (
              lambda args
              (num (eval(cons + (get-value args))) (eval(cons + (get-grad args))))
))

(define (multiplier me allOfUs)(
    cond 
    [
        (null? allOfUs) 1 ; End of the list, return 1 since it is neutral element in multiplication
    ]
    [
        #t
        (* (num-value (eval(car allOfUs))) (multiplier me (cdr allOfUs))) ; 
    ]
))
(define (deleteItem lst item)(deleteItemHelper (toStructList lst) item))

(define (deleteItemHelper lst item)
  (cond ((null? lst)
         '())
        ((isEqual item (car lst))
         (cdr lst))
        (else
         (cons (car lst) 
               (deleteItem (cdr lst) item)))))

(define getDerivs (lambda (listOfNums) (map (lambda (mynum)  (* (num-grad (eval mynum)) (multiplier mynum (deleteItem listOfNums mynum))))  listOfNums)))
(define mul (
              lambda args
              (num (eval(cons * (get-value args))) (eval(cons + (getDerivs  args))))
))

(define (sub num1 num2) (num (eval(- (num-value num1) (num-value num2))) (eval(- (num-grad num1) (num-grad num2) ))))

(define (mergelists list1 list2 wanted) (
    cond
     [
         (or (null? list1) (null? list2))
         `()
     ]
     [
         #t
        (cons (cons (car list1) (num (car list2) (if (eq? (car list1) wanted) 1.0 0.0))) (mergelists (cdr list1) (cdr list2) wanted ))
     ]
))
(define (create-hash names values var) (make-hash (mergelists names values var) ))

(define (subst lst rep new)(
        if (not(list? lst))
            (car (subst (list lst) rep new))
            (map (lambda (x)(
                        if (list? x)
                            (subst x rep new)
                            (if (eq? rep x) new x)
                            )) lst)
))
(define mse_ mse)
(define relu_ relu)

(define (replaceExpr expr) 
    (subst (subst (subst (subst (subst expr '+ 'add ) '- 'sub ) '* 'mul ) 'mse 'mse_ ) 'relu 'relu_ )
)
(define (parse hash expr) (
    cond
        [
            (null? expr)
            `()
        ]
        [
            (list? expr)
            (cons (parse hash (car expr)) (parse hash (cdr expr)))
        ]
        [
            (not(equal? (replaceExpr expr) expr))
            (replaceExpr expr)
        ]
        [
            (number? expr)
            (num expr 0.0)
        ]
        [
            #t
            (hash-ref hash expr)
        ]
    
))

(define (grad names values var expr) (num-grad (eval (parse (create-hash names values var) expr))))

(define (partial-grad names values vars expr) (map (lambda (x) (grad names values (if (member x vars) x `racketIsTheBestLanguageEVERRR___) expr)) names))

(define (gradient-descent names values vars lr expr) (map - values (map (lambda (x) (* x lr)) (partial-grad names values vars expr) )))

(define (optimize names values vars lr k expr) (cond
 [
     (eq? k 1)
     (gradient-descent names values vars lr expr)
 ]
 [
     #t
    (optimize names (gradient-descent names values vars lr expr) vars lr (- k 1) expr)
     
 ]
 ))