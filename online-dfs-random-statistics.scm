#!/usr/bin/env chicken-scheme

;; [[file:~/prg/scm/aima/aima.org::*Non-determinism%20and%20random-walk][Non-determinism-and-random-walk:1]]

(include "online-navigation.scm")

(use heap)

(define (make-agent-random-walk start next-frame)
  (make-agent
   start
   0
   (let ((state->action->states (make-hash-table))
         (previous-state #f)
         (previous-action #f)
         (expectations 0)
         (met-expectations 0))
     (lambda (state goal? score)
       (when (and previous-action previous-state)
         (hash-table-update!
          state->action->states
          previous-state
          (lambda (action->states)
            (hash-table-update!
             action->states
             previous-action
             (lambda (states)
               (if (heap-member? states state)
                   (heap-change-key! states
                                     state
                                     (add1 (heap-key states state)))
                   (heap-insert! states
                                 1
                                 state))
               states)
             (lambda () (make-max-heap)))
            action->states)
          ;; Too bad we don't have multi-dimensional hash-tables.
          (lambda () (make-hash-table)))
         (inc! expectations)
         ;; Given that we just added a key corresponding to
         ;; state, previous-state and previous-action; this should
         ;; always return at least something.
         ;;
         ;; The question is whether it defies our expectations.
         (let ((expected-state
                (heap-extremum
                 (hash-table-ref/default
                  (hash-table-ref/default
                   state->action->states
                   previous-state
                   (make-hash-table))
                  previous-action
                  (make-max-heap)))))
           ;; (debug state
           ;;        expected-state
           ;;        (equal? state expected-state))
           (when (equal? state expected-state)
             (inc! met-expectations)))
         (debug (exact->inexact (/ met-expectations expectations))))
       (let ((action
              (if goal?
                  (begin
                    (set! previous-state #f)
                    (set! previous-action #f)
                    (hash-table-walk state->action->states
                      (lambda (state action->states)
                        (hash-table-walk action->states
                          (lambda (action states)
                            ;; (debug state action (heap-extremum states))
                            2))))
                    zero-motion)
                  (list-ref state (random (length state))))))
         (set! previous-state state)
         (set! previous-action action)
         action)))))

(simulate-navigation make-agent-random-walk
                     n-points: 10
                     n-steps: 10000
                     p-slippage: 0.3
                     animation-file: #f)

;; Non-determinism-and-random-walk:1 ends here