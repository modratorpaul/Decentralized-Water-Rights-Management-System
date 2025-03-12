;; Water Rights Contract
;; Manages water rights

(define-map rights
  { source-id: uint, holder: principal }
  {
    amount: uint,
    active: bool
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

;; Allocate water rights
(define-public (allocate
                (source-id uint)
                (holder principal)
                (amount uint))
  (begin
    ;; Only admins can allocate
    (asserts! (is-admin tx-sender) (err u1))

    ;; Store rights
    (map-set rights
      { source-id: source-id, holder: holder }
      {
        amount: amount,
        active: true
      }
    )

    (ok true)
  )
)

;; Update rights
(define-public (update
                (source-id uint)
                (holder principal)
                (amount uint))
  (begin
    ;; Only admins can update
    (asserts! (is-admin tx-sender) (err u1))

    ;; Rights must exist
    (asserts! (rights-exist source-id holder) (err u2))

    ;; Update rights
    (map-set rights
      { source-id: source-id, holder: holder }
      {
        amount: amount,
        active: true
      }
    )

    (ok true)
  )
)

;; Deactivate rights
(define-public (deactivate
                (source-id uint)
                (holder principal))
  (begin
    ;; Only admins can deactivate
    (asserts! (is-admin tx-sender) (err u1))

    ;; Rights must exist
    (asserts! (rights-exist source-id holder) (err u2))

    ;; Update rights
    (map-set rights
      { source-id: source-id, holder: holder }
      {
        amount: (get amount (default-rights (map-get? rights { source-id: source-id, holder: holder }))),
        active: false
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

;; Get rights
(define-read-only (get-rights (source-id uint) (holder principal))
  (map-get? rights { source-id: source-id, holder: holder })
)

;; Check if rights exist
(define-read-only (rights-exist (source-id uint) (holder principal))
  (is-some (map-get? rights { source-id: source-id, holder: holder }))
)

;; Check if address is admin
(define-read-only (is-admin (address principal))
  (default-to false (get active (map-get? admins { address: address })))
)

;; Default rights for safety
(define-read-only (default-rights (right (optional {
                                           amount: uint,
                                           active: bool
                                         })))
  (default-to { amount: u0, active: false } right)
)

