;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-abbr-reader.ss" "lang")((modname doudizhu) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
;;
;; ***************************************************
;; Kshaunish Gupta (21203670)
;; CS 135 Winter 2026
;; Assignment 05
;; ***************************************************
;;


;; Data Definition
;; A Card is (anyof 3 4 5 6 7 8 9 10 'Jack 'Queen 'King 'Ace 2 'Black 'Red)

;; card-value: Card -> Nat
;; Purpose: Converts a Card to its relative strength for comparison.

(define (card-value c)
  (cond
    [(and (number? c) (= c 2)) 15]
    [(number? c) c]
    [(symbol=? c 'Jack) 11]
    [(symbol=? c 'Queen) 12]
    [(symbol=? c 'King) 13]
    [(symbol=? c 'Ace) 14]
    [(symbol=? c 'Black) 16]
    [(symbol=? c 'Red) 17]))

;; card<=?: Card Card -> Boolean
;; Purpose: Determines if c1 is less than or equal to c2 in value.

(define (card<=? c1 c2)
  (<= (card-value c1) (card-value c2)))

;; card=?: Card Card -> Boolean
;; Purpose: Determines if c1 and c2 are the same value.

(define (card=? c1 c2)
  (= (card-value c1) (card-value c2)))

;;
;; Question 3 (a) - sort-cards
;;

;; insert-card: Card (listof Card) -> (listof Card)
;; Purpose: Helper to insert a card into a sorted list of cards.

(define (insert-card c loc)
  (cond
    [(empty? loc) (list c)]
    [(card<=? c (first loc)) (cons c loc)]
    [else (cons (first loc) (insert-card c (rest loc)))]))

;; sort-cards: (listof Card) -> Hand
;; Purpose: Consumes a list of Cards and produces a sorted Hand.

(define (sort-cards loc)
  (cond
    [(empty? loc) empty]
    [else (insert-card (first loc) (sort-cards (rest loc)))]))

;; Test:
(check-expect (sort-cards (list 3 'King 6 7 'Jack 'Queen 2 7 3 7 3 'Ace 'Jack 2 3 4 5))
              (list 3 3 3 3 4 5 6 7 7 7 'Jack 'Jack 'Queen 'King 'Ace 2 2))

;;
;; Question 3 (b) - find-kind
;;

;; count-occurrences: Card Hand -> Nat
;; Purpose: Helper to count how many times a card appears continuously in a Hand.

(define (count-occurrences c hand)
  (cond
    [(empty? hand) 0]
    [(card=? c (first hand)) (+ 1 (count-occurrences c (rest hand)))]
    [else 0]))

;; remove-all-cards: Card Hand -> Hand
;; Purpose: Helper to remove all continuous instances of a card from a Hand.

(define (remove-all-cards c hand)
  (cond
    [(empty? hand) empty]
    [(card=? c (first hand)) (remove-all-cards c (rest hand))]
    [else hand]))

;; find-kind: Nat Hand -> Hand
;; Purpose: Produces a sorted list of unique card values that occur at least n times.
;; Requires: n >= 1

(define (find-kind n hand)
  (cond
    [(empty? hand) empty]
    [(>= (count-occurrences (first hand) hand) n)
     (cons (first hand) (find-kind n (remove-all-cards (first hand) hand)))]
    [else
     (find-kind n (remove-all-cards (first hand) hand))]))

;; Test
(check-expect (find-kind 3 (list 3 3 3 3 4 5 6 7 7 7 'Jack 'Jack 'Queen 'King 'Ace 2 2))
              (list 3 7))

;;
;; Question 3 (c) - remove-cards
;;

;; remove-cards: Hand Hand -> Hand
;; Purpose: Removes the cards found in the first Hand from the second Hand.

(define (remove-cards h1 h2)
  (cond
    [(empty? h1) h2]
    [(empty? h2) empty]
    [(card=? (first h1) (first h2))
     (remove-cards (rest h1) (rest h2))]
    [(card<=? (first h1) (first h2))
     (remove-cards (rest h1) h2)]
    [else
     (cons (first h2) (remove-cards h1 (rest h2)))]))

;; Test
(check-expect (remove-cards (list 4 5 6 7 8) (list 3 3 4 5 6 6 6 7 9))
              (list 3 3 6 6 9))

