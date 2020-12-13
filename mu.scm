(import (scheme base)
        (scheme write)
        (scheme cyclone util)
        ;; (cyclone match)
        )

;; (define-syntax def
;;   (er-macro-transformer
;;    (lambda (expr rename compare)
;;      (let ((name (first expr))
;;            (content (rest expr)))
;;        `(,(rename 'define) ,name ,@content)))))


(define (get-value item lst)
  (let ((result (assoc item lst)))
    (if result
        (if (pair? (cdr result)) ;; improper alist?
            (cadr result)
            (cdr result)) ;; proper alist
        #f)))

;; Handle improper alists, e.g. '((a 1) (b 2)),
;; and proper alista, e.g. '((a . 1) (b . 2))
(define (alist? alist)
  (if (list? alist)
      (cond ((null? alist) #f)
            ((every (lambda (kv) 
                      (and (pair? kv)
                           (or (not (list? kv))
                               (= 2 (length kv)))))
                    alist)))
      #f))


(define-syntax mu
  (er-macro-transformer
   (lambda (expr rename compare)

     (define (proper-list? x)
       (cond ((null? x) #t)
             ((pair? x) (proper-list? (cdr x)))
             (else #f)))

     (define (remove pred lst)
       (filter (lambda (item)
                 (not (pred item)))
               lst))

     ;; (define proper? proper-list?)
     (define (improper-last lst)
       (cond ((null? lst) '())
             ((null? (cdr lst)) (car lst))
             ((and (pair? lst)
                   (not (list? lst))
                   (not (pair? (cdr lst))))
              (cdr lst))
             (else (improper-last (cdr lst)))))

     (define (improper-length lst)
       (let lp ((l lst) (len 0))
         (cond ((null? l) len)
               ((null? (cdr l)) (+ 1 len))
               ;; Handle improper list '(a b . c)...
               ((and (pair? l) 
                     (not (list? l))
                     (not (pair? (cdr l))))
                (+ 2 len))
               (else
                (lp (cdr l) (+ 1 len))))))

     (let* ((args (cadr expr))
            (body (cddr expr))
            (%lambda (rename 'lambda)))
       (if (or (null? args) (identifier? args))
           ;; (mu () body) or (mu args body)
           `(,%lambda ,args ,@body)
           (let* ((args-len (improper-length args))
                  (rest (if (not (proper-list? args))
                            (improper-last args)
                            #f))
                  (optional (filter pair?
                                    (if rest
                                        (take args (- args-len 1))
                                        args)))
                  (optional-len (length optional))
                  (positional (remove pair?
                                      (if rest
                                          (take args (- args-len 1))
                                          args)))
                  (positional-len (length positional))
                  (positional/optional-len (+ positional-len optional-len))                  
                  (%= (rename '=))
                  (%> (rename '>))
                  (%< (rename '<))
                  (%>= (rename '>=))
                  (%<= (rename '<=))
                  (%alist? (rename 'alist?))
                  (%and (rename 'and))
                  ;; (%append (rename 'append))
                  (%apply (rename 'apply))
                  (%car (rename 'car))
                  (%cond (rename 'cond))
                  (%else (rename 'else))
                  (%not (rename 'not))
                  (%if (rename 'if))
                  (%imp-length (rename 'improper-length))
                  (%imp-last (rename 'improper-last))
                  (%lambda (rename 'lambda))
                  (%length (rename 'length))
                  (%let (rename 'let))
                  (%list-tail (rename 'list-tail))
                  (%map (rename 'map))
                  (%take (rename 'take)))
             `(,%lambda
               called-args
               (,%let ((called-args-len (,%length called-args)))
                      (,%cond

                       ((,%and (,%= called-args-len 1) 
                               (,%alist? (car called-args)))
                        (,%let
                         ,(append (map (lambda (opt)
                                         `(,(car opt) (or (get-value ',(car opt) (car called-args))
                                                          ',(cadr opt))))
                                       optional)
                                  (map (lambda (pos)
                                         `(,pos (or (get-value ',pos (car called-args))
                                                    (error "Parameter not defined" ',pos))))
                                       positional)
                                  (if rest
                                      `((,rest (or (get-value ',rest (car called-args)) '())))
                                      '()))
                         ;; (,%apply (,%lambda ,rest ,@body) '())
                         ,@body))

                       ;; (mu (a) body) or (mu (a . rest) body)
                       ((,%= ,optional-len 0)
                        (,%apply (,%lambda (,@positional . ,(or rest '())) ,@body) called-args))

                       ;; From now on we assume THERE ARE optionals params:
                       ;; Eg. (mu (a (b 2)) body), (mu (a (b 2) . rest) body),
                       ;; (mu ((b 2)) body) or (mu ((b 2) . rest) body)

                       ;; Eg. ((mu (a b c (d 4)) (list a b c d)) 1 2 3)
                       ((,%= called-args-len ,positional-len)
                        (,%let ,optional
                               (,%apply (,%lambda (,@positional . ,(or rest '()))
                                                  ,@body)
                                        called-args)))

                       ;; Eg. ((mu (a b c (d 4) . rest) (list a b c d)) 1 2 3 4 5)
                       ((,%>= called-args-len ,positional/optional-len)
                        (,%apply (,%lambda (,@positional ,@(map car optional) . ,(or rest '()))
                                           ,@body)
                                 called-args))

                       ;; Still cannot handle this case...
                       ;; ((,%and (,%> called-args-len ,positional-len)
                       ;;         (,%< called-args-len ,positional/optional-len))
                       ;;  (,%apply (mu (,@positional
                       ;;                (,%apply (lambda (args-len)
                       ;;                           (,%map ,%car (,%take ,optional args-len))
                       ;;                           called-args-len))
                       ;;                (,%list-tail ,optional called-args-len)))
                       ;;           called-args))
                       
                       (,%else
                        (error "Error when calling procedure - arguments mismatch" (list ',args called-args))))))))))))
