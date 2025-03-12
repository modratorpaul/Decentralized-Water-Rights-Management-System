;; Water Source Contract
;; Records water sources

(define-data-var counter uint u0)

(define-map sources
  { id: uint }
  {
    name: (string-ascii 64),
    capacity: uint,
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

;; Register a new water source
(define-public (register
                (name (string-ascii 64))
                (capacity uint))
  (begin
    ;; Only admins can add sources
    (asserts! (is-admin tx-sender) (err u1))

    ;; Increment counter
    (var-set counter (+ (var-get counter) u1))

    ;; Store source data
    (map-set sources
      { id: (var-get counter) }
      {
        name: name,
        capacity: capacity,
        active: true
      }
    )

    (ok (var-get counter))
  )
)

;; Update source capacity
(define-public (update
                (id uint)
                (capacity uint))
  (begin
    ;; Only admins can update
    (asserts! (is-admin tx-sender) (err u1))

    ;; Source must exist
    (asserts! (source-exists id) (err u2))

    ;; Update source
    (map-set sources
      { id: id }
      {
        name: (get name (default-source (map-get? sources { id: id }))),
        capacity: capacity,
        active: true
      }
    )

    (ok true)
  )
)

;; Deactivate a source
(define-public (deactivate (id uint))
  (begin
    ;; Only admins can deactivate
    (asserts! (is-admin tx-sender) (err u1))

    ;; Source must exist
    (asserts! (source-exists id) (err u2))

    ;; Update source
    (map-set sources
      { id: id }
      {
        name: (get name (default-source (map-get? sources { id: id }))),
        capacity: (get capacity (default-source (map-get? sources { id: id }))),
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

;; Get source details
(define-read-only (get-source (id uint))
  (map-get? sources { id: id })
)

;; Check if source exists
(define-read-only (source-exists (id uint))
  (is-some (map-get? sources { id: id }))
)

;; Check if address is admin
(define-read-only (is-admin (address principal))
  (default-to false (get active (map-get? admins { address: address })))
)

;; Default source for safety
(define-read-only (default-source (source (optional {
                                            name: (string-ascii 64),
                                            capacity: uint,
                                            active: bool
                                          })))
  (default-to { name: "", capacity: u0, active: false } source)
)

