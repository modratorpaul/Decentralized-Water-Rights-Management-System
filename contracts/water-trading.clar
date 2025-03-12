;; Water Trading Contract
;; Enables trading water rights

(define-data-var counter uint u0)

(define-map offers
  { id: uint }
  {
    seller: principal,
    source-id: uint,
    amount: uint,
    price: uint,
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

;; Create offer
(define-public (create-offer
                (source-id uint)
                (amount uint)
                (price uint))
  (begin
    ;; Increment counter
    (var-set counter (+ (var-get counter) u1))

    ;; Store offer
    (map-set offers
      { id: (var-get counter) }
      {
        seller: tx-sender,
        source-id: source-id,
        amount: amount,
        price: price,
        active: true
      }
    )

    (ok (var-get counter))
  )
)

;; Cancel offer
(define-public (cancel-offer (id uint))
  (begin
    ;; Offer must exist
    (asserts! (offer-exists id) (err u1))

    ;; Only seller or admin can cancel
    (asserts! (or
                (is-eq tx-sender (get seller (default-offer (map-get? offers { id: id }))))
                (is-admin tx-sender))
              (err u2))

    ;; Update offer
    (map-set offers
      { id: id }
      {
        seller: (get seller (default-offer (map-get? offers { id: id }))),
        source-id: (get source-id (default-offer (map-get? offers { id: id }))),
        amount: (get amount (default-offer (map-get? offers { id: id }))),
        price: (get price (default-offer (map-get? offers { id: id }))),
        active: false
      }
    )

    (ok true)
  )
)

;; Accept offer
(define-public (accept-offer (id uint))
  (begin
    ;; Offer must exist and be active
    (asserts! (and
                (offer-exists id)
                (get active (default-offer (map-get? offers { id: id }))))
              (err u1))

    ;; Cannot buy from self
    (asserts! (not (is-eq tx-sender (get seller (default-offer (map-get? offers { id: id }))))) (err u2))

    ;; Update offer
    (map-set offers
      { id: id }
      {
        seller: (get seller (default-offer (map-get? offers { id: id }))),
        source-id: (get source-id (default-offer (map-get? offers { id: id }))),
        amount: (get amount (default-offer (map-get? offers { id: id }))),
        price: (get price (default-offer (map-get? offers { id: id }))),
        active: false
      }
    )

    ;; Note: The actual transfer of rights would need to be handled by the water-rights contract
    ;; This contract only manages the offers

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

;; Get offer
(define-read-only (get-offer (id uint))
  (map-get? offers { id: id })
)

;; Check if offer exists
(define-read-only (offer-exists (id uint))
  (is-some (map-get? offers { id: id }))
)

;; Check if address is admin
(define-read-only (is-admin (address principal))
  (default-to false (get active (map-get? admins { address: address })))
)

;; Default offer for safety
(define-read-only (default-offer (offer (optional {
                                          seller: principal,
                                          source-id: uint,
                                          amount: uint,
                                          price: uint,
                                          active: bool
                                        })))
  (default-to {
    seller: tx-sender,
    source-id: u0,
    amount: u0,
    price: u0,
    active: false
  } offer)
)

