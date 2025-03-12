;; Water Usage Contract
;; Tracks water consumption

(define-map usage
  { source-id: uint, user: principal, period: uint }
  {
    amount: uint,
    verified: bool
  }
)

(define-map admins
  { address: principal }
  { active: bool }
)

;; Initialize contract with first admin
(define-public (initialize)
  (begin
    (map-set admins { address: tx-sender } { active: true })
    (ok true)
  )
)

;; Report water usage
(define-public (report
                (source-id uint)
                (period uint)
                (amount uint))
  (begin
    ;; Store usage
    (map-set usage
      { source-id: source-id, user: tx-sender, period: period }
      {
        amount: amount,
        verified: false
      }
    )

    (ok true)
  )
)

;; Verify usage
(define-public (verify
                (source-id uint)
                (user principal)
                (period uint)
                (verified-amount uint))
  (begin
    ;; Only admins can verify
    (asserts! (is-admin tx-sender) (err u1))

    ;; Usage must be reported
    (asserts! (usage-exists source-id user period) (err u2))

    ;; Update usage
    (map-set usage
      { source-id: source-id, user: user, period: period }
      {
        amount: verified-amount,
        verified: true
      }
    )

    (ok true)
  )
)

;; Add an admin
(define-public (add-admin (address principal))
  (begin
    ;; Only admins can add admins
    (asserts! (is-admin tx-sender) (err u1))

    (map-set admins
      { address: address }
      { active: true }
    )

    (ok true)
  )
)

;; Get usage
(define-read-only (get-usage (source-id uint) (user principal) (period uint))
  (map-get? usage { source-id: source-id, user: user, period: period })
)

;; Check if usage exists
(define-read-only (usage-exists (source-id uint) (user principal) (period uint))
  (is-some (map-get? usage { source-id: source-id, user: user, period: period }))
)

;; Check if address is admin
(define-read-only (is-admin (address principal))
  (default-to false (get active (map-get? admins { address: address })))
)

