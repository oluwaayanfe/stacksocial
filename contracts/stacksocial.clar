;; stacksocial.clar
;; A decentralized on-chain social & tipping platform

;; --------------------------------
;; ERRORS
;; --------------------------------
(define-constant ERR_NOT_FOUND u100)
(define-constant ERR_INVALID_AMOUNT u101)
(define-constant ERR_ALREADY_EXISTS u102)
(define-constant ERR_NOT_OWNER u103)
(define-constant ERR_BANNED u104)

;; --------------------------------
;; DATA VARIABLES
;; --------------------------------
(define-data-var owner principal tx-sender)
(define-data-var next-post-id uint u0)
(define-data-var total-users uint u0)
(define-data-var total-tips uint u0)

;; --------------------------------
;; MAPS
;; --------------------------------
(define-map profiles
  principal
  (tuple
    (username (string-ascii 32))
    (bio (string-ascii 128))
    (banned bool)
    (followers uint)
    (tips-received uint)
  )
)

(define-map posts
  uint
  (tuple
    (author principal)
    (content (string-ascii 280))
    (timestamp uint)
    (tips uint)
  )
)

(define-map follows
  (tuple (follower principal) (followed principal))
  bool
)

;; --------------------------------
;; EVENTS (Clarity doesn't have native events)
;; --------------------------------
;; Events are tracked off-chain or via contract state

;; --------------------------------
;; PRIVATE HELPERS
;; --------------------------------
(define-private (only-owner)
  (if (is-eq tx-sender (var-get owner))
      (ok true)
      (err ERR_NOT_OWNER))
)

;; --------------------------------
;; PUBLIC FUNCTIONS
;; --------------------------------

;; 1. Create a user profile
(define-public (create-profile (username (string-ascii 32)) (bio (string-ascii 128)))
  (if (is-none (map-get? profiles tx-sender))
      (begin
        (map-set profiles tx-sender
          (tuple
            (username username)
            (bio bio)
            (banned false)
            (followers u0)
            (tips-received u0)))
        (var-set total-users (+ (var-get total-users) u1))
        (ok "Profile created"))
      (err ERR_ALREADY_EXISTS))
)

;; 2. Create a post
(define-public (create-post (content (string-ascii 280)))
  (let ((p (map-get? profiles tx-sender)))
    (if (is-some p)
        (let ((prof (unwrap-panic p)))
          (if (get banned prof)
              (err ERR_BANNED)
              (let ((id (+ (var-get next-post-id) u1)))
                (map-set posts id
                  (tuple
                    (author tx-sender)
                    (content content)
                    (timestamp u0)
                    (tips u0)))
                (var-set next-post-id id)
                (ok id))))
        (err ERR_NOT_FOUND)))
)

;; 3. Tip a post or creator
(define-public (tip (post-id uint) (amount uint))
  (if (> amount u0)
      (let ((post (map-get? posts post-id)))
        (if (is-some post)
            (let ((p (unwrap-panic post)))
              (let ((receiver (get author p)))
                (let ((profile (map-get? profiles receiver)))
                  (if (is-some profile)
                      (let ((prof (unwrap-panic profile)))
                        (if (get banned prof)
                            (err ERR_BANNED)
                            (begin
                              (try! (stx-transfer? amount tx-sender receiver))
                              (map-set posts post-id
                                (tuple
                                  (author (get author p))
                                  (content (get content p))
                                  (timestamp (get timestamp p))
                                  (tips (+ (get tips p) amount))))
                              (map-set profiles receiver
                                (tuple
                                  (username (get username prof))
                                  (bio (get bio prof))
                                  (banned (get banned prof))
                                  (followers (get followers prof))
                                  (tips-received (+ (get tips-received prof) amount))))
                              (var-set total-tips (+ (var-get total-tips) amount))
                              (ok "Tip successful"))))
                      (err ERR_NOT_FOUND)))))
            (err ERR_NOT_FOUND)))
      (err ERR_INVALID_AMOUNT))
)

;; 4. Follow another user
(define-public (follow (user principal))
  (if (not (is-eq tx-sender user))
      (let ((p (map-get? profiles user)))
        (match p
          prof
            (if (get banned prof)
                (err ERR_BANNED)
                (begin
                  (map-set follows (tuple (follower tx-sender) (followed user)) true)
                  (map-set profiles user
                    (tuple
                      (username (get username prof))
                      (bio (get bio prof))
                      (banned (get banned prof))
                      (followers (+ (get followers prof) u1))
                      (tips-received (get tips-received prof))))
                  (ok "Followed successfully")))
          (err ERR_NOT_FOUND)))
      (err ERR_INVALID_AMOUNT))
)

;; 5. Unfollow a user
(define-public (unfollow (user principal))
  (if (not (is-eq tx-sender user))
      (let ((exists (map-get? follows (tuple (follower tx-sender) (followed user)))))
        (if (is-some exists)
            (let ((p (map-get? profiles user)))
              (if (is-some p)
                  (let ((prof (unwrap-panic p)))
                    (begin
                      (map-set profiles user
                        (tuple
                          (username (get username prof))
                          (bio (get bio prof))
                          (banned (get banned prof))
                          (followers (if (> (get followers prof) u0) (- (get followers prof) u1) u0))
                          (tips-received (get tips-received prof))))
                      (map-delete follows (tuple (follower tx-sender) (followed user)))
                      (ok "Unfollowed")))
                  (err ERR_NOT_FOUND)))
            (err ERR_NOT_FOUND)))
      (err ERR_INVALID_AMOUNT))
)

;; 6. Admin - ban or unban a user
(define-public (set-ban (user principal) (status bool))
  (begin
    (try! (only-owner))
    (let ((p (map-get? profiles user)))
      (if (is-some p)
          (let ((prof (unwrap-panic p)))
            (begin
              (map-set profiles user
                (tuple
                  (username (get username prof))
                  (bio (get bio prof))
                  (banned status)
                  (followers (get followers prof))
                  (tips-received (get tips-received prof))))
              (ok true)))
          (err ERR_NOT_FOUND))))
)

;; --------------------------------
;; READ-ONLY FUNCTIONS
;; --------------------------------
(define-read-only (get-profile (user principal))
  (map-get? profiles user)
)

(define-read-only (get-post (id uint))
  (map-get? posts id)
)

(define-read-only (get-total-users)
  (var-get total-users)
)

(define-read-only (get-total-tips)
  (var-get total-tips)
)
