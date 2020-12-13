# mu
An extended Scheme `lambda` with optional and named (destructured) parameters.

It is a proof-of-concept of how Scheme implementations could extend the `lambda` form to parse/destructure its arguments in alternative ways, and allow faster prototyping. 

It is highly inspired on the ideas discussed with Lassi Kortela and Marc Nieper-Wißkirchen on [this issue](https://github.com/justinethier/cyclone/issues/387) and the beautiful idea of extending Scheme core syntax, maybe targeting R8RS ([SRFI-201](https://srfi.schemers.org/srfi-201/srfi-201.html) is highly inspiring in this sense too, although not related to this implementation).

These high-level abstractions implemented in Scheme are very inneficient (almost 20x slower than actual `lambda` in the worst case - tested in [Cyclone Scheme](http://justinethier.github.io/cyclone/)). Maybe if implemented in the compiler it could run much faster.

This extension is proposed mainly for experimentation and research purposes.

## Supported arguments forms and examples

```scheme
;;; Nothing new here ------------------------------
;; NO parameters
;; (mu () body)
> ((mu () 1)) 
1

;; Paramters list
;; (mu args body)
> ((mu x x) 1 2 3)
(1 2 3)

;; POSITIONAL parameters only
;; (mu (a) body)
> ((mu (a) 
     (list a)) 
   1)
(1)

;; POSITIONAL parameters only - with REST
;; (mu (a . rest) body)
> ((mu (a . r) 
     (list a r)) 
   1 2)
(1 (2))


;;; Start of OPTIONAL parameters ----------------------
;; POSITIONAL parameters with OPTIONAL ones
;; (mu (a (b 2)) body)
> ((mu (a (b 2)) 
     (list a b)) 
   1)
(1 2)

> ((mu (a (b 2)) 
     (list a b))
   1 3)
(1 3)

;; POSITIONAL parameters with OPTIONAL ones - with REST
;; (mu (a (b 2) . rest) body)
> ((mu (a (b 2) . r) 
     (list a b r)) 
   1 5 7)
(1 5 (7))

> ((mu (a (b 2) . r) 
     (list a b r)) 
   1)
(1 2 ())

;; OPTIONAL parameters only (they are optional, but still *positional* parameters)
;; (mu ((b 2)) body)
> ((mu ((b 2)) 
     (list b)))
(2)

> ((mu ((b 2)) 
     (list b)) 
   9)
(9)

;; OPTIONAL parameters only (they are optional, but still *positional* parameters) - with REST
;; (mu ((b 2) . rest) body)
> ((mu ((b 2) . r) 
     (list b r)))
(2 ())

> ((mu ((b 2) . r) 
     (list b r)) 
   9)
(9 ())

> ((mu ((b 2) . r) 
     (list b r)) 
   9 7)
(9 (7))


;;; NAMED parameters through single alist -------------
;; It works with proper (eg. '((a . 1) (b . 2)) and 
;; improper (eg. '((a 1) (b 2)) alists.

;; (mu (a) body)
> ((mu (a) 
     (list a)) 
   '((a 1)))
(1)

;; (mu (a . rest) body)
> ((mu (a . r) 
     (list a r)) 
   '((a 1)))
(1 ())

;; (mu (a (b 2)) body)
> ((mu (a (b 2)) 
     (list a b)) 
   '((a 1)))
(1 2)

> ((mu (a (b 2)) 
     (list a b)) 
   '((a 1) (b 3)))
(1 3)

;; (mu (a (b 2) . rest) body)
> ((mu (a (b 2) . r) 
     (list a b r)) 
   '((a 1)))
(1 2 ())

> ((mu (a (b 2) . r) 
     (list a b r)) 
   '((a 1) (b 3)))
(1 3 ())

> ((mu (a (b 2) . r) 
     (list a b r)) 
   '((a 1) (b 3) (r 5)))
(1 3 (5))

> ((mu (a (b 2) . r) 
     (list a b r)) 
   '((a 1) (r 5)))
(1 2 (5))

;; 
> ((mu (a (b 2) . r) 
     (list a b r)) 
   '((r 5) (b 3) (a 1))) ;; the order doesn't matter
(1 3 (5))

```

## Caveats (and comments)

- perfomance penalty: implement it in the compiler?

- confusing syntax for optional parameters: they just add parens (and that's the virtue and curse of LISPs)

- still can't handle passing *some* optional parameters, but not all of them (see [here](https://github.com/arthurmaciel/mu/blob/master/mu.scm#L149)).

- extra step to pass an alist as a parameter content:
```scheme
> (define my-config-alist '((height . 10) (width . 30)))
> ((mu (a) 
     (cdr (assoc 'height a)))
   `((a ,my-config-alist)))
10
```

We see how we could just write procedures for parameter destructuring:
```scheme
> (define get-height 
    (mu (height) 
      height)) ;; do something else with it
> (get-height my-config-alist)
10
```

## Ideas (suggestions are very welcomed!)

- Instead of/in addition to named parameters through an alist, `mu` could provide pattern matching as in  [SRFI-201](https://srfi.schemers.org/srfi-201/srfi-201.html) (defined in section *The pattern matching (destructuring) lambda form*).

- Instead of/in addition to named parameters through an alist, `mu` could allow a property list of [SRFI-88](https://srfi.schemers.org/srfi-88/srfi-88.html) keywords, like proposed in [SRFI-89](https://srfi.schemers.org/srfi-89/srfi-89.html). 
Eg.  `(keyword1: value1 keyword2: value 2 ...)`. Maybe this would make the code cleaner and avoid the extra step when passing a keyword.

