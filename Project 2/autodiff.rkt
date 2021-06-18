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

(define (get-value num-list) (cond
    [(list? num-list)(map (lambda (x) (num-value x)) (toStructList num-list))] 
    [(num? num-list)(num-value num-list)]
))

(define (get-grad num-list) (cond
    [(list? num-list)(map (lambda (x) (num-grad x)) (toStructList num-list))] 
    [(num? num-list)(num-grad num-list)]
))

(define add ( lambda args (num (eval(cons + (get-value args))) (eval(cons + (get-grad args))))))
(define (sub num1 num2) (num (eval(- (num-value num1) (num-value num2))) (eval(- (num-grad num1) (num-grad num2) ))))

(define getDerivs (lambda (listOfNums) (map (lambda (mynum)  (* (get-grad  mynum) (apply * (remove (get-value mynum) (get-value  listOfNums)))))  listOfNums)))
(define mul ( lambda args (num (eval(cons * (get-value args))) (eval(cons + (getDerivs  args))))))
(define (mergelists names values var)
        (cons (cons (car names) (num (car values) (if (eq? (car names) var) 1.0 0.0))) (if (null? (cdr names)) '() (mergelists (cdr names) (cdr values) var ))))
(define (create-hash names values var) (make-hash (mergelists names values var) ))

(define (parse hash expr) (cond
    [(null? expr) `()]
    [(list? expr) (cons (parse hash (car expr)) (parse hash (cdr expr)))]
    [(eq? expr '+) 'add]  
    [(eq? expr '*) 'mul]
    [(eq? expr '-) 'sub]
    [(eq? expr 'mse) 'mse]
    [(eq? expr 'relu) 'relu]
    [(number? expr) (num expr 0.0)]
    [else (hash-ref hash expr)]
))

(define (grad names values var expr) (num-grad (eval (parse (create-hash names values var) expr))))
(define (partial-grad names values vars expr) (map (lambda (x) (grad names values (if (member x vars) x `racketIsTheBestLanguageEVERRR___) expr)) names))
(define (gradient-descent names values vars lr expr) (map - values (map (lambda (x) (* x lr)) (partial-grad names values vars expr) )))
(define (optimize names values vars lr k expr) (cond
    [(eq? k 1)(gradient-descent names values vars lr expr)]
    [else (optimize names (gradient-descent names values vars lr expr) vars lr (- k 1) expr)]
 ))