;;; bookmark+-key.el --- Bookmark+ key and menu bindings.
;;
;; Filename: bookmark+-key.el
;; Description: Bookmark+ key and menu bindings.
;; Author: Drew Adams
;; Maintainer: Drew Adams (concat "drew.adams" "@" "oracle" ".com")
;; Copyright (C) 2010-2021, Drew Adams, all rights reserved.
;; Created: Fri Apr  1 15:34:50 2011 (-0700)
;; Last-Updated: Fri Feb 12 12:06:56 2021 (-0800)
;;           By: dradams
;;     Update #: 977
;; URL: https://www.emacswiki.org/emacs/download/bookmark%2b-key.el
;; Doc URL: https://www.emacswiki.org/emacs/BookmarkPlus
;; Keywords: bookmarks, bookmark+, placeholders, annotations, search, info, url, eww, w3m, gnus
;; Compatibility: GNU Emacs: 20.x, 21.x, 22.x, 23.x, 24.x, 25.x, 26.x
;;
;; Features that might be required by this library:
;;
;;   None
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;;    The Bookmark+ libraries are these:
;;
;;    `bookmark+.el'     - main (driver) library
;;    `bookmark+-mac.el' - Lisp macros
;;    `bookmark+-lit.el' - (optional) code for highlighting bookmarks
;;    `bookmark+-bmu.el' - code for the `*Bookmark List*' (bmenu)
;;    `bookmark+-1.el'   - other (non-bmenu) required code
;;    `bookmark+-key.el' - key and menu bindings (this file)
;;
;;    `bookmark+-doc.el' - documentation (comment-only file)
;;    `bookmark+-chg.el' - change log (comment-only file)
;;
;;    The documentation (in `bookmark+-doc.el') includes how to
;;    byte-compile and install Bookmark+.  The documentation is also
;;    available in these ways:
;;
;;    1. From the bookmark list (`C-x r l'):
;;       Use `?' to show the current bookmark-list status and general
;;       help, then click link `Doc in Commentary' or link `Doc on the
;;       Web'.
;;
;;    2. From the Emacs-Wiki Web site:
;;       https://www.emacswiki.org/emacs/BookmarkPlus.
;;
;;    3. From the Bookmark+ group customization buffer:
;;       `M-x customize-group bookmark-plus', then click link
;;       `Commentary'.
;;
;;    (The commentary links in #1 and #3 work only if you have library
;;    `bookmark+-doc.el' in your `load-path'.)
;;
;;
;;  User options defined here:
;;
;;    `bmkp-add-bookmarks-here-menu-flag',
;;    `bmkp-bookmark-map-prefix-key', `bmkp-jump-map-prefix-key',
;;    `bmkp-jump-other-window-map-prefix-key'.
;;
;;  Non-interactive functions defined here:
;;
;;    `bmkp-bookmark-data-from-record',
;;    `bmkp-bookmark-name-from-record',
;;    `bmkp-exists-bookmark-satisfying-p',
;;    `bmkp-exists-this-file/buffer-bookmarks-p',
;;    `bmkp-set-map-prefix-key', `bookmark-name-from-full-record',
;;    `bookmark-name-from-record'.
;;
;;  Internal variables defined here:
;;
;;    `bmkp-annotate-map', `bmkp-annotate-menu', `bmkp-here-menu',
;;    `bmkp-bookmarks-here-menu-command-entries',
;;    `bmkp-find-file-menu', `bmkp-highlight-menu', `bmkp-jump-map',
;;    `bmkp-jump-menu', `bmkp-jump-other-window-map',
;;    `bmkp-jump-tags-menu', `bmkp-set-map', `bmkp-tags-map',
;;    `bmkp-tags-menu'.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; *This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

;;;;;;;;;;;;;;;;;;;;;

(eval-when-compile
  (or (condition-case nil
          (load-library "bookmark+-mac") ; Use load-library to ensure latest .elc.
        (error nil))
      (require 'bookmark+-mac)))         ; Require, so can load separately if not on `load-path'.
;; bmkp-menu-bar-make-toggle

(eval-when-compile (require 'cl)) ;; case

;;;;;;;;;;;;;;;;;;;;;;;

;; Quiet the byte-compiler

(defvar grep-mode-map)


;; Prefix keys.
;;
;; These two maps are always on `bookmark-map', wherever it is: `bmkp-set-map', `bmkp-tags-map'.
;;
(defun bmkp-set-map-prefix-key (pref-keys-option keys)
  "Set prefix key option SYMBOL to key-sequence VALUE."
  (set pref-keys-option keys)
  (let* ((g-map     (current-global-map))
         (b-map     (case pref-keys-option
                      (bmkp-bookmark-map-prefix-keys          'bookmark-map)
                      (bmkp-jump-map-prefix-keys              'bmkp-jump-map)
                      (bmkp-jump-other-window-map-prefix-keys 'bmkp-jump-other-window-map))))
    (dolist (key  (where-is-internal b-map g-map))
      (define-key g-map key nil))
    (dolist (key  keys)
      (define-key g-map key b-map))))

(defcustom bmkp-bookmark-map-prefix-keys (list (kbd "C-x x"))
  "Prefix keys for `bookmark-map' in `current-global-map'.
Each value of the list is a prefix key bound to keymap `bookmark-map'."
  :type (if (> emacs-major-version 21)
            '(repeat (key-sequence :tag "Key" :value [ignore]))
          '(repeat (restricted-sexp
                    :tag "Key"
                    :match-alternatives ((lambda (x) (or (stringp x)  (vectorp x))))
                    :value [ignore])))
  :set 'bmkp-set-map-prefix-key
  :group 'bookmark-plus)

(defcustom bmkp-jump-map-prefix-keys (list (kbd "C-x j"))
  "Prefix keys for `bmkp-jump-map' in `current-global-map'.
Each value of the list is a prefix key bound to keymap
`bmkp-jump-map'."
  :type (if (> emacs-major-version 21)
            '(repeat (key-sequence :tag "Key" :value [ignore]))
          '(repeat (restricted-sexp
                    :tag "Key"
                    :match-alternatives ((lambda (x) (or (stringp x)  (vectorp x))))
                    :value [ignore])))
  :set 'bmkp-set-map-prefix-key
  :group 'bookmark-plus)

(defcustom bmkp-jump-other-window-map-prefix-keys (list (kbd "C-x 4 j"))
  "Prefix keys for `bmkp-jump-other-window-map' in `current-global-map'.
Each value of the list is a prefix key bound to keymap
`bmkp-jump-other-window-map'."
  :type (if (> emacs-major-version 21)
            '(repeat (key-sequence :tag "Key" :value [ignore]))
          '(repeat (restricted-sexp
                    :tag "Key"
                    :match-alternatives ((lambda (x) (or (stringp x)  (vectorp x))))
                    :value [ignore])))
  :set 'bmkp-set-map-prefix-key
  :group 'bookmark-plus)

(defcustom bmkp-add-bookmarks-here-menu-flag nil
  "Non-nil means add a `Bookmarks Here' menu to some menu-bar menus.
The menu is added only if there are in fact bookmarks for the current
buffer or file.  The default value is nil because checking whether
there are such bookmarks can take a little time."
  :type 'boolean :group 'bookmark-plus)



;; Some general Renamings.
;;
;; 1. Fix incompatibility introduced by gratuitous Emacs name change.
;;
(cond ((and (fboundp 'bookmark-name-from-record)  (not (fboundp 'bookmark-name-from-full-record)))
       (defalias 'bookmark-name-from-full-record 'bookmark-name-from-record))
      ((and (fboundp 'bookmark-name-from-full-record)  (not (fboundp 'bookmark-name-from-record)))
       (defalias 'bookmark-name-from-record 'bookmark-name-from-full-record)))

;; 2. The vanilla name of the first is misleading, as it returns only the cdr of the record.
;;    The second is for consistency.
;;
(defalias 'bmkp-bookmark-data-from-record 'bookmark-get-bookmark-record)
(defalias 'bmkp-bookmark-name-from-record 'bookmark-name-from-full-record)


;; Quiet the byte-compiler
(defvar bmkp-bmenu-menubar-menu)        ; In `bookmark+-bmu.el'.
(defvar bmkp-bmenu-toggle-menu)         ; In `bookmark+-bmu.el'.
(defvar bmkp-crosshairs-flag)           ; In `bookmark+-1.el'.
(defvar bmkp-eww-replace-keys-flag)     ; In `bookmark+-1.el' (Emacs 25+).
(defvar bmkp-prompt-for-tags-flag)      ; In `bookmark+-1.el'.
(defvar bmkp-save-new-location-flag)    ; In `bookmark+-1.el'.
(defvar diredp-bookmark-menu)           ; In `dired+.el'.
(defvar eww-mode-map)                   ; In `eww.el' (Emacs 24.4+).
(defvar gnus-summary-mode-map)          ; In `gnus-sum.el'.
(defvar Info-mode-map)                  ; In `info.el'.
(defvar Info-mode-menu)                 ; In `info.el'.
(defvar Man-mode-map)                   ; In `man.el'.
(defvar mouse-wheel-down-event)         ; In `mwheel.el'.
(defvar mouse-wheel-up-event)           ; In `mwheel.el'.
(defvar w3m-minor-mode-map)             ; In `w3m.el'.
(defvar w3m-mode-map)                   ; In `w3m.el'.
(defvar woman-menu)                     ; In `woman.el'.
(defvar woman-mode-map)                 ; In `woman.el'.

;;(@* "Keymaps")
;;; Keymaps ----------------------------------------------------------

;; `help-map'
(define-key help-map "M"  'bmkp-describe-bookmark)

;; `bookmark-map'

;; (define-key ctl-x-map "x" bookmark-map)
;; (define-key ctl-x-map "xj" 'bookmark-jump-other-window)               ; `C-x x j' (also `C-x 4 j j')
(define-key ctl-x-map "rK" 'bmkp-set-desktop-bookmark)        ; `C-x r K' (also `C-x x K', `C-x x c K')

(define-key bookmark-map "0"      'bmkp-empty-file)                                   ; `C-x x 0'
(define-key bookmark-map "2"      'bmkp-clone-bookmark)                               ; `C-x x 2'
(define-key bookmark-map "5"      'bookmark-jump-other-frame)                         ; `C-x x 5'
(define-key bookmark-map "B"      'bmkp-choose-navlist-from-bookmark-list)            ; `C-x x B'
;; `e' is `edit-bookmarks' (aka `bookmark-bmenu-list', from vanilla Emacs.
(define-key bookmark-map "E"      'bmkp-edit-bookmark-record)                         ; `C-x x E'
;; The original `bookmark-insert-location' in `bookmark.el' was `f'.
(define-key bookmark-map "I"      'bookmark-insert-location)                          ; `C-x x I'
(define-key bookmark-map "\C-j"   'bmkp-jump-to-list)                                 ; `C-x x C-j'
(define-key bookmark-map "K"      'bmkp-set-desktop-bookmark) ; `C-x x K' (also `C-x r K', `C-x x c K')
(define-key bookmark-map "L"      'bmkp-switch-bookmark-file-create)                  ; `C-x x L'
(define-key bookmark-map "\C-l"   'bmkp-switch-to-bookmark-file-this-file/buffer)     ; `C-x x C-l'
(define-key bookmark-map "m"      'bmkp-bookmark-set-confirm-overwrite)               ; `C-x x m'
(define-key bookmark-map "N"      'bmkp-navlist-bmenu-list)                           ; `C-x x N'
(define-key bookmark-map "o"      'bookmark-jump-other-window)           ; `C-x x o' (also `C-x 4 j j')
(define-key bookmark-map "q"      'bookmark-jump-other-window)           ; `C-x x q' (also `C-x 4 j j')
(define-key bookmark-map "r"      'bmkp-edit-bookmark-name-and-location)              ; `C-x x r'
(define-key bookmark-map "\C-s"   'bmkp-save-bookmarks-this-file/buffer)              ; `C-x x C-s'
(define-key bookmark-map "\M-w"   'bmkp-set-snippet-bookmark)        ; `C-x x M-w' (also `C-x x c M-w')
(define-key bookmark-map "x"      'bmkp-toggle-autotemp-on-set)                       ; `C-x x x'
(define-key bookmark-map "y"      'bmkp-set-bookmark-file-bookmark)                   ; `C-x x y'
(when (featurep 'bookmark+-lit)
  (define-key bookmark-map "h"    'bmkp-light-bookmark-this-buffer)                   ; `C-x x h'
  (define-key bookmark-map "H"    'bmkp-light-bookmarks)                              ; `C-x x H'
  (define-key bookmark-map "u"    'bmkp-unlight-bookmark-this-buffer)                 ; `C-x x u'
  (define-key bookmark-map "U"    'bmkp-unlight-bookmarks)                            ; `C-x x U'
  (define-key bookmark-map "\C-u" 'bmkp-unlight-bookmark-here)                        ; `C-x x C-u'
  (define-key bookmark-map "="    'bmkp-bookmarks-lighted-at-point))                  ; `C-x x ='
(define-key bookmark-map ","      'bmkp-this-file/buffer-bmenu-list)                  ; `C-x x ,'
(define-key bookmark-map "?"      'bmkp-describe-bookmark-lighted-here)               ; `C-x x ?'
(define-key bookmark-map ":"      'bmkp-choose-navlist-of-type)                       ; `C-x x :'
(define-key bookmark-map "\r"     'bmkp-toggle-autonamed-bookmark-set/delete)         ; `C-x x RET'
(define-key bookmark-map [delete] 'bmkp-delete-bookmarks)                             ; `C-x x delete'

(substitute-key-definition 'kill-line 'bmkp-delete-bookmarks          ; `C-x x C-k', `C-x x deleteline'
                           bookmark-map (current-global-map))
(define-key bookmark-map [deletechar] 'bmkp-delete-bookmarks)                      ; `C-x x deletechar'
;; For Mac Book:
(define-key bookmark-map [kp-delete] 'bmkp-delete-bookmarks)                        ; `C-x x kp-delete'

;; If you use Emacs before Emacs 22, then you will want to bind the commands
;; whose names do *not* end in `-repeat' to keys that are easily repeatable.
;; For example, you might want to bind `bmkp-next-bookmark-this-file/buffer'
;; (not `bmkp-next-bookmark-this-file/buffer-repeat') to a key such as [f2].
;;
(when (> emacs-major-version 21)
  (define-key bookmark-map "n"          'bmkp-next-bookmark-this-file/buffer-repeat) ; `C-x x n'
  (define-key bookmark-map "\C-n"       'bmkp-next-bookmark-this-file/buffer-repeat) ; `C-x x C-n'
  (define-key bookmark-map [down]       'bmkp-next-bookmark-this-file/buffer-repeat) ; `C-x x down'
  (put 'bmkp-next-bookmark-this-file/buffer-repeat :advertised-binding (kbd "C-x x <down>"))

  ;; This requires the fix for Emacs bug #6256, which is in Emacs 23.3 (presumably).
  ;; For older Emacs versions you can bind the wheel event to `bmkp-next-bookmark-this-file/buffer'
  ;; in the global map.  IOW, prior to Emacs 23.3 a mouse event won't work with `repeat'.
  (when (and (boundp 'mouse-wheel-up-event)
             (or (> emacs-major-version 23)
                 (and (= emacs-major-version 23)  (> emacs-minor-version 2))))
    (define-key bookmark-map (vector (list mouse-wheel-up-event))
      'bmkp-next-bookmark-this-file/buffer-repeat))                            ; `C-x x mouse-wheel-up'
  (define-key bookmark-map "p"          'bmkp-previous-bookmark-this-file/buffer-repeat) ; `C-x x p'
  (define-key bookmark-map "\C-p"       'bmkp-previous-bookmark-this-file/buffer-repeat) ; `C-x x C-p'
  (define-key bookmark-map [up]         'bmkp-previous-bookmark-this-file/buffer-repeat) ; `C-x x up'
  (put 'bmkp-previous-bookmark-this-file/buffer-repeat :advertised-binding (kbd "C-x x <up>"))

  ;; This requires the fix for Emacs bug #6256, which is in Emacs 23.3 (presumably).
  ;; For older Emacs versions you can bind the wheel event to `bmkp-previous-bookmark-this-file/buffer'
  ;; in the global map.  IOW, prior to Emacs 23.3 a mouse event won't work with `repeat'.
  (when (and (boundp 'mouse-wheel-down-event)
             (or (> emacs-major-version 23)
                 (and (= emacs-major-version 23)  (> emacs-minor-version 2))))
    (define-key bookmark-map (vector (list mouse-wheel-down-event))
      'bmkp-previous-bookmark-this-file/buffer-repeat))                      ; `C-x x mouse-wheel-down'
  (define-key bookmark-map "f"          'bmkp-next-bookmark-repeat)                  ; `C-x x f'
  (define-key bookmark-map "\C-f"       'bmkp-next-bookmark-repeat)                  ; `C-x x C-f'
  (define-key bookmark-map [right]      'bmkp-next-bookmark-repeat)                  ; `C-x x right'
  (put 'bmkp-next-bookmark-repeat :advertised-binding (kbd "C-x x <right>"))
  (define-key bookmark-map "b"          'bmkp-previous-bookmark-repeat)              ; `C-x x b'
  (define-key bookmark-map "\C-b"       'bmkp-previous-bookmark-repeat)              ; `C-x x C-b'
  (define-key bookmark-map [left]       'bmkp-previous-bookmark-repeat)              ; `C-x x left'
  (put 'bmkp-previous-bookmark-repeat :advertised-binding (kbd "C-x x <left>"))
  (define-key bookmark-map [next]       'bmkp-next-bookmark-w32-repeat)              ; `C-x x next'
  (define-key bookmark-map [prior]      'bmkp-previous-bookmark-w32-repeat)          ; `C-x x prior'
  (when (featurep 'bookmark+-lit)
    (define-key bookmark-map [C-down]   'bmkp-next-lighted-this-buffer-repeat)       ; `C-x x C-down'
    (define-key bookmark-map [C-up]     'bmkp-previous-lighted-this-buffer-repeat))) ; `C-x x C-up'


;; `bmkp-annotate-map': prefix `C-x x a'

(defvar bmkp-annotate-map nil "Keymap containing bindings for bookmark annotation commands.")

(define-prefix-command 'bmkp-annotate-map)
(define-key bookmark-map "a"      bmkp-annotate-map)                           ; `C-x x a' for annotate

(define-key bmkp-annotate-map "a" 'bmkp-annotate-bookmark)                     ; `C-x x a a'
(define-key bmkp-annotate-map "b" 'bmkp-annotate-bookmark-this-file/buffer)    ; `C-x x a b'
(define-key bmkp-annotate-map "B" 'bmkp-annotate-all-bookmarks-this-file/buffer) ; `C-x x a B'
(define-key bmkp-annotate-map "e" 'bookmark-edit-annotation)                   ; `C-x x a e'
(define-key bmkp-annotate-map "s" 'bookmark-show-annotation)                   ; `C-x x a s'
(define-key bmkp-annotate-map "S" 'bookmark-show-all-annotations)              ; `C-x x a S'


;; `bmkp-set-map': prefix `C-x x c'

(defvar bmkp-set-map nil "Keymap containing bindings for bookmark set commands.")

(define-prefix-command 'bmkp-set-map)
(define-key bookmark-map "c"    bmkp-set-map)                                  ; `C-x x c' for create

(define-key bmkp-set-map "a"    'bmkp-autofile-set)                            ; `C-x x c a'
(define-key bmkp-set-map "f"    'bmkp-file-target-set)                         ; `C-x x c f'
(define-key bmkp-set-map "F"    'bmkp-make-function-bookmark)                  ; `C-x x c F'
(define-key bmkp-set-map "K"    'bmkp-set-desktop-bookmark)                    ; `C-x x c K'
(define-key bmkp-set-map "\C-k" 'bmkp-wrap-bookmark-with-last-kbd-macro)       ; `C-x x C-k'
(define-key bmkp-set-map "m"    'bmkp-bookmark-set-confirm-overwrite)          ; `C-x x c m'
(define-key bmkp-set-map "M"    'bookmark-set)                                 ; `C-x x c M'
(define-key bmkp-set-map "s"    'bmkp-set-sequence-bookmark)                   ; `C-x x c s'
(define-key bmkp-set-map "u"    'bmkp-url-target-set)                          ; `C-x x c u'
(define-key bmkp-set-map "\M-w" 'bmkp-set-snippet-bookmark)                    ; `C-x x c M-w'
(define-key bmkp-set-map "y"    'bmkp-set-bookmark-file-bookmark)              ; `C-x x c y'
(define-key bmkp-set-map "\r"   'bmkp-toggle-autonamed-bookmark-set/delete)    ; `C-x x c RET'


;; Add set commands to other keymaps: occur, compilation: `C-c C-b', `C-c C-M-b', `C-c C-M-B'.
;; See `dired+.el' for Dired bookmarking keys, which are different.

(add-hook 'occur-mode-hook
          (lambda ()
            (unless (lookup-key occur-mode-map "\C-c\C-b")
              (define-key occur-mode-map "\C-c\C-b" 'bmkp-occur-target-set)) ; `C-c C-b'
            (unless (lookup-key occur-mode-map "\C-c\C-\M-b")
              (define-key occur-mode-map "\C-c\C-\M-b" 'bmkp-occur-target-set-all)) ; `C-c C-M-b'
            (unless (lookup-key occur-mode-map [(control ?c) (control meta shift ?b)])
              (define-key occur-mode-map [(control ?c) (control meta shift ?b)]
                'bmkp-occur-create-autonamed-bookmarks)))) ; `C-c C-M-B' (aka `C-c C-M-S-b')

(when (fboundp 'bmkp-compilation-target-set) ; Emacs 22+

  (add-hook 'compilation-mode-hook
            (lambda ()
              (unless (lookup-key compilation-mode-map "\C-c\C-b")
                (define-key compilation-mode-map "\C-c\C-b" 'bmkp-compilation-target-set)) ; `C-c C-b'
              (unless (lookup-key compilation-mode-map "\C-c\C-\M-b") ; `C-c C-M-b'
                (define-key compilation-mode-map "\C-c\C-\M-b" 'bmkp-compilation-target-set-all))))

  (when (fboundp 'compilation-minor-mode) ; Emacs 26+

    (add-hook
     'grep-mode-hook
     (lambda ()
       (unless (lookup-key grep-mode-map "\C-c\C-b")
         (define-key grep-mode-map "\C-c\C-b" 'bmkp-compilation-target-set)) ; `C-c C-b'
       (unless (lookup-key grep-mode-map "\C-c\C-\M-b") ; `C-c C-M-b'
         (define-key grep-mode-map "\C-c\C-\M-b" 'bmkp-compilation-target-set-all))))

    (add-hook
     'compilation-minor-mode-hook
     (lambda ()
       (unless (lookup-key compilation-minor-mode-map "\C-c\C-b")
         (define-key compilation-minor-mode-map "\C-c\C-b" 'bmkp-compilation-target-set)) ; `C-c C-b'
       (unless (lookup-key compilation-minor-mode-map "\C-c\C-\M-b") ; `C-c C-M-b'
         (define-key compilation-minor-mode-map "\C-c\C-\M-b" 'bmkp-compilation-target-set-all))))

    (add-hook
     'compilation-shell-minor-mode-hook
     (lambda ()
       (unless (lookup-key compilation-shell-minor-mode-map "\C-c\C-b")
         (define-key compilation-shell-minor-mode-map
           "\C-c\C-b" 'bmkp-compilation-target-set)) ; `C-c C-b'
       (unless (lookup-key compilation-shell-minor-mode-map "\C-c\C-\M-b") ; `C-c C-M-b'
         (define-key compilation-shell-minor-mode-map
           "\C-c\C-\M-b" 'bmkp-compilation-target-set-all))))))


;; `bmkp-tags-map': prefix `C-x x t'

(defvar bmkp-tags-map nil "Keymap containing bindings for bookmark tag commands.")

(define-prefix-command 'bmkp-tags-map)
(define-key bookmark-map "t"  bmkp-tags-map)                                      ; `C-x x t' for tags

(define-key bmkp-tags-map "0"    'bmkp-remove-all-tags)                           ; `C-x x t 0'
(define-key bmkp-tags-map "+"    nil) ; For Emacs 20
(define-key bmkp-tags-map "+b"   'bmkp-add-tags)                                  ; `C-x x t + b'
(define-key bmkp-tags-map "-b"   'bmkp-remove-tags)                               ; `C-x x t - b'
(define-key bmkp-tags-map "+a"   'bmkp-tag-a-file)                                ; `C-x x t + a'
(define-key bmkp-tags-map "-a"   'bmkp-untag-a-file)                              ; `C-x x t - a'
(define-key bmkp-tags-map "c"    'bmkp-copy-tags)                                 ; `C-x x t c'
(define-key bmkp-tags-map "d"    'bmkp-remove-tags-from-all)                      ; `C-x x t d'
(define-key bmkp-tags-map "e"    'bmkp-edit-tags)                                 ; `C-x x t e'
(define-key bmkp-tags-map "l"    'bmkp-list-all-tags)                             ; `C-x x t l'
(define-key bmkp-tags-map "p"    'bmkp-paste-add-tags)                            ; `C-x x t p'
(define-key bmkp-tags-map "q"    'bmkp-paste-replace-tags)                        ; `C-x x t q'
(define-key bmkp-tags-map "r"    'bmkp-rename-tag)                                ; `C-x x t r'
(define-key bmkp-tags-map "v"    'bmkp-set-tag-value)                             ; `C-x x t v'
(define-key bmkp-tags-map "V"    'bmkp-set-tag-value-for-navlist)                 ; `C-x x t V'
(define-key bmkp-tags-map "\M-w" 'bmkp-copy-tags)                                 ; `C-x x t M-w'
(define-key bmkp-tags-map "\C-y" 'bmkp-paste-add-tags)                            ; `C-x x t C-y'


;; `bmkp-jump-map' and `bmkp-jump-other-window-map': prefixes `C-x j' and `C-x 4 j'

(defvar bmkp-jump-map nil "Keymap containing bindings for bookmark jump commands.")

(defvar bmkp-jump-other-window-map nil
  "Keymap containing bindings for bookmark jump other-window commands.")

(define-prefix-command 'bmkp-jump-map)
(define-prefix-command 'bmkp-jump-other-window-map)
;; (define-key ctl-x-map   "j" bmkp-jump-map)
;; (define-key ctl-x-4-map "j" bmkp-jump-other-window-map)
(define-key bookmark-bmenu-mode-map "j"  nil) ; For Emacs 20
(define-key bookmark-bmenu-mode-map "J"  nil) ; For Emacs 20
(define-key bookmark-bmenu-mode-map "J"  bmkp-jump-map)
(define-key bookmark-bmenu-mode-map "j"  bmkp-jump-other-window-map)
(define-key bookmark-bmenu-mode-map "j>" 'bmkp-bmenu-jump-to-marked)                           ; `j >'

(define-key ctl-x-5-map                "B"    'bookmark-jump-other-frame)       ; `C-x j 5', `C-x 5 B'
(define-key bmkp-jump-map              "5"    'bookmark-jump-other-frame )                     ; `J 5'
(define-key bmkp-jump-map              "."    nil) ; For Emacs 20
(define-key bmkp-jump-other-window-map "."    nil) ; For Emacs 20
(define-key bmkp-jump-map              ".d"   'bmkp-dired-this-dir-jump)                 ; `C-x j . d'
(define-key bmkp-jump-other-window-map ".d"   'bmkp-dired-this-dir-jump-other-window)  ; `C-x 4 j . d'
(define-key bmkp-jump-map              ".f"   'bmkp-file-this-dir-jump)                  ; `C-x j . f'
(define-key bmkp-jump-other-window-map ".f"   'bmkp-file-this-dir-jump-other-window)   ; `C-x 4 j . f'

(define-key bmkp-jump-map              ","    nil) ; For Emacs 20
(define-key bmkp-jump-other-window-map ","    nil) ; For Emacs 20
(define-key bmkp-jump-map              ",,"   'bmkp-this-buffer-jump)                    ; `C-x j , ,'
(define-key bmkp-jump-other-window-map ",,"   'bmkp-this-buffer-jump-other-window)     ; `C-x 4 j , ,'
(define-key bmkp-jump-map              ",#"   'bmkp-autonamed-this-buffer-jump)          ; `C-x j , #'
(define-key bmkp-jump-other-window-map ",#"
  'bmkp-autonamed-this-buffer-jump-other-window)                                       ; `C-x 4 j , #'

(define-key bmkp-jump-map              "#"    'bmkp-autonamed-jump)                        ; `C-x j #'
(define-key bmkp-jump-other-window-map "#"    'bmkp-autonamed-jump-other-window)         ; `C-x 4 j #'

(define-key bmkp-jump-map              "="    nil) ; For Emacs 20
(define-key bmkp-jump-other-window-map "="    nil) ; For Emacs 20
(define-key bmkp-jump-map              "=b"   'bmkp-specific-buffers-jump)                ; `C-x j = b'
(define-key bmkp-jump-other-window-map "=b"   'bmkp-specific-buffers-jump-other-window) ; `C-x 4 j = b'
(define-key bmkp-jump-map              "=f"   'bmkp-specific-files-jump)                  ; `C-x j = f'
(define-key bmkp-jump-other-window-map "=f"   'bmkp-specific-files-jump-other-window)   ; `C-x 4 j = f'

(define-key bmkp-jump-map              "a"    'bmkp-autofile-jump)                          ; `C-x j a'
(define-key bmkp-jump-other-window-map "a"    'bmkp-autofile-jump-other-window)           ; `C-x 4 j a'
(define-key bmkp-jump-map              "b"    'bmkp-non-file-jump)                          ; `C-x j b'
(define-key bmkp-jump-other-window-map "b"    'bmkp-non-file-jump-other-window)           ; `C-x 4 j b'
(define-key bmkp-jump-map              "B"    'bmkp-bookmark-list-jump)                     ; `C-x j B'
(define-key bmkp-jump-other-window-map "B"    'bmkp-bookmark-list-jump)     ; SAME COMMAND: `C-x 4 j B'
(define-key bmkp-jump-map              "d"    'bmkp-dired-jump)                             ; `C-x j d'
(define-key bmkp-jump-other-window-map "d"    'bmkp-dired-jump-other-window)              ; `C-x 4 j d'

(eval-after-load "eww"
  '(when (> emacs-major-version 24)     ; Emacs 25+
     (when bmkp-eww-replace-keys-flag
       (bmkp-remap 'eww-add-bookmark       'bookmark-set                eww-mode-map)
       (bmkp-remap 'eww-list-bookmarks     'bookmark-bmenu-list         eww-mode-map)
       (bmkp-remap 'eww-next-bookmark      'bmkp-next-url-bookmark  eww-mode-map)
       (bmkp-remap 'eww-previous-bookmark  'bmkp-previous-url-bookmark  eww-mode-map))
     (define-key bmkp-jump-map              "e"  'bmkp-eww-jump)                             ; `C-x j e'
     (define-key bmkp-jump-other-window-map "e"  'bmkp-eww-jump-other-window)))            ; `C-x 4 j e'

(define-key bmkp-jump-map              "f"    'bmkp-file-jump)                              ; `C-x j f'
(define-key bmkp-jump-other-window-map "f"    'bmkp-file-jump-other-window)               ; `C-x 4 j f'
(define-key bmkp-jump-map              "\C-f" 'bmkp-find-file)                            ; `C-x j C-f'
(define-key bmkp-jump-other-window-map "\C-f" 'bmkp-find-file-other-window)             ; `C-x 4 j C-f'
(define-key bmkp-jump-map              "g"    'bmkp-gnus-jump)                              ; `C-x j g'
(define-key bmkp-jump-other-window-map "g"    'bmkp-gnus-jump-other-window)               ; `C-x 4 j g'
(define-key bmkp-jump-map              "h"    'bmkp-lighted-jump)                           ; `C-x j h'
(define-key bmkp-jump-other-window-map "h"    'bmkp-lighted-jump-other-window)            ; `C-x 4 j h'
(define-key bmkp-jump-map              "i"    'bmkp-info-jump)                              ; `C-x j i'
(define-key bmkp-jump-other-window-map "i"    'bmkp-info-jump-other-window)               ; `C-x 4 j i'
(define-key bmkp-jump-map              "\M-i" 'bmkp-image-jump)                           ; `C-x j M-i'
(define-key bmkp-jump-other-window-map "\M-i" 'bmkp-image-jump-other-window)            ; `C-x 4 j M-i'
(define-key bmkp-jump-map              "j"    'bookmark-jump)                               ; `C-x j j'
(put 'bookmark-jump :advertised-binding "\C-xjj")

(define-key bmkp-jump-other-window-map "j"    'bookmark-jump-other-window)                ; `C-x 4 j j'
(put 'bookmark-jump-other-window :advertised-binding "\C-x4jj")
(put 'jump-other :advertised-binding "\C-x4jj")

(define-key bmkp-jump-map              "\C-j" 'bmkp-jump-to-list)                         ; `C-x j C-j'
(define-key bmkp-jump-map              "K"    'bmkp-desktop-jump)                           ; `C-x j K'
(define-key bmkp-jump-other-window-map "K"    'bmkp-desktop-jump)           ; SAME COMMAND: `C-x 4 j K'
(define-key bmkp-jump-map              "l"    'bmkp-local-file-jump)                        ; `C-x j l'
(define-key bmkp-jump-other-window-map "l"    'bmkp-local-file-jump-other-window)         ; `C-x 4 j l'
(define-key bmkp-jump-map              "m"    'bmkp-man-jump)                               ; `C-x j m'
(define-key bmkp-jump-other-window-map "m"    'bmkp-man-jump-other-window)                ; `C-x 4 j m'
(define-key bmkp-jump-map              "n"    'bmkp-remote-file-jump)         ; `C-x j n' ("_n_etwork")
(define-key bmkp-jump-other-window-map "n"    'bmkp-remote-file-jump-other-window)        ; `C-x 4 j n'
(define-key bmkp-jump-map              "N"    'bmkp-jump-in-navlist)                        ; `C-x j N'
(define-key bmkp-jump-other-window-map "N"    'bmkp-jump-in-navlist-other-window)         ; `C-x 4 j N'
(define-key bmkp-jump-map              "r"    'bmkp-region-jump)                            ; `C-x j r'
(define-key bmkp-jump-other-window-map "r"    'bmkp-region-jump-other-window)             ; `C-x 4 j r'
(define-key bmkp-jump-other-window-map "R"
  'bmkp-region-jump-narrow-indirect-other-window)                                         ; `C-x 4 j R'

(define-key bmkp-jump-map              "t"    nil) ; For Emacs 20
(define-key bmkp-jump-other-window-map "t"    nil) ; For Emacs 20
(define-key bmkp-jump-map              "t*"   'bmkp-all-tags-jump)                        ; `C-x j t *'
(define-key bmkp-jump-other-window-map "t*"   'bmkp-all-tags-jump-other-window)         ; `C-x 4 j t *'
(define-key bmkp-jump-map              "t+"   'bmkp-some-tags-jump)                       ; `C-x j t +'
(define-key bmkp-jump-other-window-map "t+"   'bmkp-some-tags-jump-other-window)        ; `C-x 4 j t +'

(define-key bmkp-jump-map              "t%"   nil) ; For Emacs 20
(define-key bmkp-jump-other-window-map "t%"   nil) ; For Emacs 20
(define-key bmkp-jump-map              "t%*"  'bmkp-all-tags-regexp-jump)               ; `C-x j t % *'
(define-key bmkp-jump-other-window-map "t%*"
  'bmkp-all-tags-regexp-jump-other-window)                                            ; `C-x 4 j t % *'
(define-key bmkp-jump-map              "t%+"  'bmkp-some-tags-regexp-jump)              ; `C-x j t % +'
(define-key bmkp-jump-other-window-map "t%+"
  'bmkp-some-tags-regexp-jump-other-window)                                           ; `C-x 4 j t % +'

(define-key bmkp-jump-map              "t."   nil) ; For Emacs 20
(define-key bmkp-jump-other-window-map "t."   nil) ; For Emacs 20
(define-key bmkp-jump-map              "t.*" 'bmkp-file-this-dir-all-tags-jump)         ; `C-x j t . *'
(define-key bmkp-jump-other-window-map "t.*"
  'bmkp-file-this-dir-all-tags-jump-other-window)                                     ; `C-x 4 j t . *'
(define-key bmkp-jump-map              "t.+" 'bmkp-file-this-dir-some-tags-jump)        ; `C-x j t . +'
(define-key bmkp-jump-other-window-map "t.+"
  'bmkp-file-this-dir-some-tags-jump-other-window)                                    ; `C-x 4 j t . +'

(define-key bmkp-jump-map              "t.%" nil) ; For Emacs 20
(define-key bmkp-jump-other-window-map "t.%" nil) ; For Emacs 20
(define-key bmkp-jump-map              "t.%*"
  'bmkp-file-this-dir-all-tags-regexp-jump)                                           ; `C-x j t . % *'
(define-key bmkp-jump-other-window-map "t.%*"
  'bmkp-file-this-dir-all-tags-regexp-jump-other-window)                            ; `C-x 4 j t . % *'
(define-key bmkp-jump-map              "t.%+"
  'bmkp-file-this-dir-some-tags-regexp-jump)                                          ; `C-x j t . % +'
(define-key bmkp-jump-other-window-map "t.%+"
  'bmkp-file-this-dir-some-tags-regexp-jump-other-window)                           ; `C-x 4 j t . % +'


(define-key bmkp-jump-map              "ta"   nil) ; For Emacs 20
(define-key bmkp-jump-other-window-map "ta"   nil) ; For Emacs 20
(define-key bmkp-jump-map              "ta*"  'bmkp-autofile-all-tags-jump)             ; `C-x j t a *'
(define-key bmkp-jump-other-window-map "ta*"
  'bmkp-autofile-all-tags-jump-other-window)                                          ; `C-x 4 j t a *'
(define-key bmkp-jump-map              "ta+"  'bmkp-autofile-some-tags-jump)            ; `C-x j t a +'
(define-key bmkp-jump-other-window-map "ta+"
  'bmkp-autofile-some-tags-jump-other-window)                                         ; `C-x 4 j t a +'

(define-key bmkp-jump-map              "ta%"  nil) ; For Emacs 20
(define-key bmkp-jump-other-window-map "ta%"  nil) ; For Emacs 20
(define-key bmkp-jump-map              "ta%*" 'bmkp-autofile-all-tags-regexp-jump)    ; `C-x j t a % *'
(define-key bmkp-jump-other-window-map "ta%*"
  'bmkp-autofile-all-tags-regexp-jump-other-window)                                 ; `C-x 4 j t a % *'
(define-key bmkp-jump-map              "ta%+" 'bmkp-autofile-some-tags-regexp-jump)   ; `C-x j t a % +'
(define-key bmkp-jump-other-window-map "ta%+"
  'bmkp-autofile-some-tags-regexp-jump-other-window)                                ; `C-x 4 j t a % +'

(define-key bmkp-jump-map              "tf"   nil) ; For Emacs 20
(define-key bmkp-jump-other-window-map "tf"   nil) ; For Emacs 20
(define-key bmkp-jump-map              "tf*"  'bmkp-file-all-tags-jump)                 ; `C-x j t f *'
(define-key bmkp-jump-other-window-map "tf*"  'bmkp-file-all-tags-jump-other-window)  ; `C-x 4 j t f *'
(define-key bmkp-jump-map              "tf+"  'bmkp-file-some-tags-jump)                ; `C-x j t f +'
(define-key bmkp-jump-other-window-map "tf+"  'bmkp-file-some-tags-jump-other-window) ; `C-x 4 j t f +'

(define-key bmkp-jump-map              "tf%"  nil) ; For Emacs 20
(define-key bmkp-jump-other-window-map "tf%"  nil) ; For Emacs 20
(define-key bmkp-jump-map              "tf%*" 'bmkp-file-all-tags-regexp-jump)        ; `C-x j t f % *'
(define-key bmkp-jump-other-window-map "tf%*"
  'bmkp-file-all-tags-regexp-jump-other-window)                                     ; `C-x 4 j t f % *'
(define-key bmkp-jump-map              "tf%+" 'bmkp-file-some-tags-regexp-jump)       ; `C-x j t f % +'
(define-key bmkp-jump-other-window-map "tf%+"
  'bmkp-file-some-tags-regexp-jump-other-window)                                    ; `C-x 4 j t f % +'

(when (> emacs-major-version 21)        ; Needs `read-file-name' with a PREDICATE arg.
  (define-key bmkp-jump-map              "t\C-f*" 'bmkp-find-file-all-tags)           ; `C-x j t C-f *'
  (define-key bmkp-jump-other-window-map "t\C-f*"
    'bmkp-find-file-all-tags-other-window)                                          ; `C-x 4 j t C-f *'
  (define-key bmkp-jump-map              "t\C-f+" 'bmkp-find-file-some-tags)          ; `C-x j t C-f +'
  (define-key bmkp-jump-other-window-map "t\C-f+"
    'bmkp-find-file-some-tags-other-window)                                         ; `C-x 4 j t C-f +'
  (define-key bmkp-jump-map              "t\C-f%*" 'bmkp-find-file-all-tags-regexp) ; `C-x j t C-f % *'
  (define-key bmkp-jump-other-window-map "t\C-f%*"
    'bmkp-find-file-all-tags-regexp-other-window)                                 ; `C-x 4 j t C-f % *'
  (define-key bmkp-jump-map              "t\C-f%+"
    'bmkp-find-file-some-tags-regexp)                                               ; `C-x j t C-f % +'
  (define-key bmkp-jump-other-window-map "t\C-f%+"
    'bmkp-find-file-some-tags-regexp-other-window))                               ; `C-x 4 j t C-f % +'

(define-key bmkp-jump-map              "u"    'bmkp-url-jump)                               ; `C-x j u'
(define-key bmkp-jump-other-window-map "u"    'bmkp-url-jump-other-window)                ; `C-x 4 j u'
(define-key bmkp-jump-map              "v"    'bmkp-variable-list-jump)                     ; `C-x j v'
(define-key bmkp-jump-map              "w"    'bmkp-w3m-jump)                               ; `C-x j w'
(define-key bmkp-jump-other-window-map "w"    'bmkp-w3m-jump-other-window)                ; `C-x 4 j w'
(define-key bmkp-jump-map              "\M-w" 'bmkp-snippet-to-kill-ring)                 ; `C-x j M-w'
(define-key bmkp-jump-other-window-map "\M-w" 'bmkp-snippet-to-kill-ring)     ; SAME CMD: `C-x 4 j M-w'
(define-key bmkp-jump-map              "x"    'bmkp-temporary-jump)                         ; `C-x j x'
(define-key bmkp-jump-other-window-map "x"    'bmkp-temporary-jump-other-window)          ; `C-x 4 j x'
(define-key bmkp-jump-map              "y"    'bmkp-bookmark-file-jump)                     ; `C-x j y'
(define-key bmkp-jump-map              ":"    'bmkp-jump-to-type)                           ; `C-x j :'
(define-key bmkp-jump-other-window-map ":"    'bmkp-jump-to-type-other-window)            ; `C-x 4 j :'

(defun bmkp-exists-bookmark-satisfying-p (predicate &optional alist)
  "Return t if there is a bookmark in ALIST that satisfies PREDICATE.
Else return nil.  ALIST defaults to `bookmark-alist'.
Put differently, return t iff the filtered alist is non-empty."
  (catch 'bmkp-exists-bookmark-satisfying-p
    (dolist (bmk  (or alist  bookmark-alist))
      (when (funcall predicate bmk) (throw 'bmkp-exists-bookmark-satisfying-p t)))
    nil))

(defun bmkp-exists-this-file/buffer-bookmarks-p (&optional alist)
  "Return t if there is a this-file or this-buffer bookmark in ALIST."
  (bmkp-exists-bookmark-satisfying-p (if (buffer-file-name) #'bmkp-this-file-p #'bmkp-this-buffer-p)))

(defvar bmkp-bookmarks-here-menu-command-entries
  (list (list 'bmkp-next-bookmark-this-file/buffer-repeat
              'menu-item
              "Next Bookmark Here"
              'bmkp-next-bookmark-this-file/buffer-repeat
              :help "Jump to the next bookmark in this buffer")
        (list 'bmkp-previous-bookmark-this-file/buffer-repeat
              'menu-item
              "Previous Bookmark Here"
              'bmkp-previous-bookmark-this-file/buffer-repeat
              :help "Jump to the previous bookmark in this buffer")
        (list 'bmkp-here-sep1 'menu-item "--")
        (list 'bmkp-annotate-bookmark-this-file/buffer
              'menu-item
              "Annotate a Bookmark Here"
              'bmkp-annotate-bookmark-this-file/buffer
              :help "Annotate a bookmark in this buffer")
        (list 'bmkp-annotate-all-bookmarks-this-file/buffer
              'menu-item
              "Annotate All Bookmarks Here"
              'bmkp-annotate-all-bookmarks-this-file/buffer
              :help "Annotate each bookmark in this buffer")
        (list 'bmkp-edit-bookmark-record-file/buffer
              'menu-item
              "Edit a Bookmark Record Here"
              'bmkp-edit-bookmark-record-file/buffer
              :help "Edit the full record (Lisp) of a bookmark in this buffer")
        (list 'bmkp-here-sep2 'menu-item "--")
        (list 'bmkp-describe-bookmark-lighted-here
              'menu-item
              "Describe Highlighted Bookmark This Line (`C-u': internal form)"
              'bmkp-describe-bookmark-lighted-here
              :help "Describe a highlighted bookmark on this line.  `C-u': internal description"
              :enable '(and (fboundp 'bmkp-describe-bookmark-lighted-here)
                            (or (bmkp-a-bookmark-lighted-at-pos (point) 'FULL)
                                (bmkp-a-bookmark-lighted-on-this-line 'FULL))))
        (list 'bmkp-bookmarks-lighted-at-point
              'menu-item
              "List Highlighted Bookmarks at Point"
              'bmkp-bookmarks-lighted-at-point
              :help "List the bookmarks at point that are highlighted"
              :enable '(bmkp-bookmarks-lighted-at-point))
        (list 'bmkp-set-lighting-for-this-buffer
              'menu-item
              "Set Highlighting for All Bookmarks Here"
              'bmkp-set-lighting-for-this-buffer
              :help "Set the `lighting' entry for all of the bookmarks for this buffer"
              :visible (featurep 'bookmark+-lit))
        (list 'bmkp-light-this-buffer
              'menu-item
              "Highlight All Bookmarks Here"
              'bmkp-light-this-buffer
              :help "Highlight the bookmarks in this buffer"
              :keys "(C-x x H)" ; Really bound to `bmkp-light-bookmarks'
              :visible (featurep 'bookmark+-lit))
        (list 'bmkp-unlight-this-buffer
              'menu-item
              "Unhighlight All Bookmarks Here"
              'bmkp-unlight-this-buffer
              :help "Highlight the bookmarks in this buffer"
              :keys "(C-x x U)" ; Really bound to `bmkp-unlight-bookmarks'
              :visible (featurep 'bookmark+-lit))
        (list 'bmkp-light-autonamed-this-buffer
              'menu-item
              "Highlight Autonamed Bookmarks Here"
              'bmkp-light-autonamed-this-buffer
              :help "Highlight the autonamed bookmarks in this buffer"
              :visible (featurep 'bookmark+-lit))
        (list 'bmkp-unlight-autonamed-this-buffer
              'menu-item
              "Unhighlight Autonamed Bookmarks Here"
              'bmkp-unlight-autonamed-this-buffer
              :help "Unhighlight the autonamed bookmarks in this buffer"
              :visible (featurep 'bookmark+-lit))
        (list 'bmkp-light-non-autonamed-this-buffer
              'menu-item
              "Highlight Non-Autonamed Bookmarks Here"
              'bmkp-light-non-autonamed-this-buffer
              :help "Highlight the non-autonamed bookmarks in this buffer"
              :visible (featurep 'bookmark+-lit))
        (list 'bmkp-unlight-non-autonamed-this-buffer
              'menu-item
              "Unhighlight Non-Autonamed Bookmarks Here"
              'bmkp-unlight-non-autonamed-this-buffer
              :help "Unhighlight the non-autonamed bookmarks in this buffer"
              :visible (featurep 'bookmark+-lit))
        (list 'bmkp-here-sep3 'menu-item "--")
        (list 'bmkp-this-file/buffer-bmenu-list
              'menu-item
              "Show Bookmark List for Bookmarks Here"
              'bmkp-this-file/buffer-bmenu-list
              :help "Show the bookmark list for bookmarks in this buffer")
        (list 'bmkp-switch-to-bookmark-file-this-file/buffer
              'menu-item
              "Switch to Bookmark File for Bookmarks Here..."
              'bmkp-switch-to-bookmark-file-this-file/buffer
              :help "Switch to a bookmark file for bookmarks in this buffer")
        (list 'bmkp-save-bookmarks-this-file/buffer
              'menu-item
              "Save Bookmarks Here To Bookmark File..."
              'bmkp-save-bookmarks-this-file/buffer
              :help "Save all bookmarks defined for this file/buffer to a file"))
  "Menu entries for general commands in `Bookmarks' > `Here' menu.")

(progn
  (defvar bmkp-here-menu (make-sparse-keymap)
    "`Here' submenu for menu-bar `Bookmarks' menu.
Menu for bookmarks that target this file or buffer.")
  (define-prefix-command 'bmkp-here-menu)
  (setcdr bmkp-here-menu bmkp-bookmarks-here-menu-command-entries))

;; Add commands to other keymaps: Buffer-menu, Dired, EWW, Gnus, Info, Man, Woman, W3M.

(add-hook (if (boundp 'Buffer-menu-mode-hook) 'Buffer-menu-mode-hook 'buffer-menu-mode-hook)
          (lambda ()
            (unless (lookup-key Buffer-menu-mode-map "j")
              (define-key Buffer-menu-mode-map "j" 'bmkp-non-file-jump)) ; `j'
            (define-key Buffer-menu-mode-map [menu-bar Buffer-menu-mode here]
              `(menu-item "Bookmarks Here" bmkp-here-menu
                          :enable (and bmkp-add-bookmarks-here-menu-flag
                                       (bmkp-exists-this-file/buffer-bookmarks-p))))))

(add-hook 'dired-mode-hook
          (lambda ()
            (let ((now  (lookup-key dired-mode-map "J")))
              ;; Uppercase, since `j' is `dired-goto-file'.
              (unless (and now  (not (eq now 'undefined))) ; `dired+.el' uses `undefined'.
                (define-key dired-mode-map "J" 'bmkp-dired-jump)) ; `j'
              (setq now  (lookup-key dired-mode-map "\C-j"))
              (unless (and now  (not (eq now 'undefined))) ; `dired+.el' uses `undefined'.
                (define-key dired-mode-map "\C-j" 'bmkp-dired-this-dir-jump))) ; `C-j'
            (let ((map   dired-mode-map)
                  (sep   '(menu-bar subdir separator-bmkp))
                  (bdj   '(menu-bar subdir bmkp-dired-jump))
                  (bdjc  '(menu-bar subdir bmkp-dired-this-dir-jump)))
              (cond ((boundp 'diredp-bookmark-menu) ; In `dired+el'.
                     (setq map   diredp-bookmark-menu
                           sep   (cddr sep)
                           bdj   (cddr bdj)
                           bdjc  (cddr bdjc))
                     (define-key map (apply #'vector bdjc)
                       '(menu-item "Jump to a Dired Bookmark For This Dir" bmkp-dired-this-dir-jump
                                   :help "Jump to a bookmarked Dired buffer for this directory"))
                     (define-key map (apply #'vector bdj)
                       '(menu-item "Jump to a Dired Bookmark" bmkp-dired-jump
                                   :help "Jump to a bookmarked Dired buffer"))
                     (define-key map [bookmarks-here]
                       `(menu-item "Here" bmkp-here-menu
                                   :enable (and bmkp-add-bookmarks-here-menu-flag
                                                (bmkp-exists-this-file/buffer-bookmarks-p)))))
                    (t
                     (define-key map (apply #'vector sep) '("--")) ;------------------------
                     (define-key map (apply #'vector bdjc)
                       '(menu-item "Jump to a Dired Bookmark For This Dir" bmkp-dired-this-dir-jump
                                   :help "Jump to a bookmarked Dired buffer for this directory"))
                     (define-key map (apply #'vector bdj)
                       '(menu-item "Jump to a Dired Bookmark" bmkp-dired-jump
                                   :help "Jump to a bookmarked Dired buffer"))
                     (define-key map [bookmarks-here]
                       `(menu-item "Here" bmkp-here-menu
                                   :enable (and bmkp-add-bookmarks-here-menu-flag
                                                (bmkp-exists-this-file/buffer-bookmarks-p)))))))))

(when (fboundp 'bmkp-eww-jump)          ; Emacs 24.4+
  (add-hook 'eww-mode-hook
            (lambda () (unless (lookup-key eww-mode-map "j")
                         (define-key eww-mode-map "j" 'bmkp-eww-jump)))))

(add-hook 'gnus-summary-mode-hook
          (lambda () (unless (lookup-key gnus-summary-mode-map "j")
                       (define-key gnus-summary-mode-map "j" 'bmkp-gnus-jump))))

(add-hook 'Info-mode-hook
          (lambda ()
            (unless (lookup-key Info-mode-map "j")
              (define-key Info-mode-map "j" 'bmkp-info-jump))
            (define-key-after Info-mode-menu [bmkp-info-jump]
              '(menu-item "Jump to an Info Bookmark" bmkp-info-jump
                          :help "Jump to a bookmarked Info node")
              'Go\ to\ Node\.\.\.) ; Used by `info(+).el' - corresponds to `Info-goto-node'.
            (define-key Info-mode-menu [bookmarks-here]
              `(menu-item "Bookmarks Here" bmkp-here-menu
                          :enable (and bmkp-add-bookmarks-here-menu-flag
                                       (bmkp-exists-this-file/buffer-bookmarks-p))))))

(add-hook 'Man-mode-hook
          (lambda () (unless (lookup-key Man-mode-map "j")
                       (define-key Man-mode-map "j" 'bmkp-man-jump))))

(add-hook 'woman-mode-hook
          (lambda ()
            (unless (lookup-key woman-mode-map "j") (define-key woman-mode-map "j" 'bmkp-man-jump))
            (when (boundp 'woman-menu)
              (define-key-after woman-menu [bmkp-man-jump]
                '(menu-item "Jump to a `man'-page Bookmark" bmkp-man-jump
                            :help "Jump to a bookmarked `man' page")
                'WoMan\.\.\.))))        ; Used by `woman.el' - corresponds to command `woman'.

(add-hook 'w3m-minor-mode-hook
          (lambda () (unless (lookup-key w3m-minor-mode-map "j")
                       (define-key w3m-minor-mode-map "j" 'bmkp-w3m-jump))))

(add-hook 'w3m-mode-hook
          (lambda () (unless (lookup-key w3m-mode-map "j")
                       (define-key w3m-mode-map "j" 'bmkp-w3m-jump))))


;;; Vanilla Emacs `Bookmarks' menu (see also [jump] from `Bookmark+' menu, below).

(define-key-after menu-bar-bookmark-map [separator-edit] '("--") ;-------------------------------------
  'jump)
;; Remove this predefined item - we use `bmkp-edit-bookmark-name-and-location' instead.
(define-key menu-bar-bookmark-map [rename] nil)

(define-key-after menu-bar-bookmark-map [bmkp-clone-bookmark]
  '(menu-item "Clone (Duplicate) a Bookmark" bmkp-clone-bookmark
              :help "Clone this bookmark.  (`\\[bmkp-edit-bookmark-record]' to edit.)")
  'separator-edit)
(define-key-after menu-bar-bookmark-map [bmkp-edit-bookmark-name-and-location]
  '(menu-item "Rename or Relocate Bookmark..." bmkp-edit-bookmark-name-and-location
              :help "Rename and/or relocate a bookmark")
  'bmkp-clone-bookmark)
(define-key-after menu-bar-bookmark-map [bmkp-edit-bookmark-record]
  '(menu-item "Edit Bookmark Record (Lisp)..." bmkp-edit-bookmark-record
              :help "Edit the internal record of a bookmark,a Lisp sexp")
  'bmkp-edit-bookmark-name-and-location)

(define-key-after menu-bar-bookmark-map [separator-show] '("--") ;-------------------------------------
  'bmkp-edit-bookmark-record)
(define-key-after menu-bar-bookmark-map [edit]
  '(menu-item "Show Bookmark List" bookmark-bmenu-list
              :help "Open the list of bookmarks in buffer `*Bookmark List*'")
  'separator-show)
(define-key-after menu-bar-bookmark-map [bmkp-this-file/buffer-bmenu-list]
  '(menu-item "Show Bookmark List for This File/Buffer" bmkp-this-file/buffer-bmenu-list
              :help "Open `*Bookmark List*' for the bookmarks in the current buffer (only)")
  'edit)
(define-key-after menu-bar-bookmark-map [bmkp-navlist-bmenu-list]
  '(menu-item "Show Bookmark List for Navlist" bmkp-navlist-bmenu-list
              :help "Open `*Bookmark List*' for bookmarks in navlist (only)")
  'bmkp-this-file/buffer-bmenu-list)

(define-key-after menu-bar-bookmark-map [separator-2] '("--") ;-------------------------------------
  'bmkp-navlist-bmenu-list)
(define-key-after menu-bar-bookmark-map [bmkp-choose-navlist-of-type]
  '(menu-item "Set Navlist to Bookmarks of Type..." bmkp-choose-navlist-of-type
              :help "Set the navigation list to the bookmarks of a certain type")
  'separator-2)
(define-key-after menu-bar-bookmark-map [bmkp-choose-navlist-from-bookmark-list]
  '(menu-item "Set Navlist from Bookmark-List Bookmark..." bmkp-choose-navlist-from-bookmark-list
              :help "Set the navigation list from a bookmark-list bookmark")
  'bmkp-choose-navlist-of-type)
(define-key-after menu-bar-bookmark-map [bmkp-list-defuns-in-commands-file]
  '(menu-item "List User-Defined Bookmark Commands" bmkp-list-defuns-in-commands-file
              :help "List the functions defined in `bmkp-bmenu-commands-file'"
              :enable (and bmkp-bmenu-commands-file  (file-readable-p bmkp-bmenu-commands-file)))
  'bmkp-choose-navlist-from-bookmark-list)

(define-key-after menu-bar-bookmark-map [insert]
  '(menu-item "Insert Bookmark Contents..." bookmark-insert :help "Insert bookmarked text")
  'bmkp-choose-navlist-from-bookmark-list)
(define-key-after menu-bar-bookmark-map [locate]
  '(menu-item "Insert Bookmark Location..." bookmark-locate ; Alias for `bookmark-insert-location'.
              :help "Insert a bookmark's file or buffer name")
  'insert)
(when (fboundp 'advice-add)             ; Emacs 24.4+.
  (define-key-after menu-bar-bookmark-map [bmkp-store-org-link]
    '(menu-item "Store Org Link To..." bmkp-store-org-link
                :help "Store a link to a bookmark for insertion in an Org-mode buffer")
    'locate))

(define-key-after menu-bar-bookmark-map [separator-3] '("--") ;-------------------------------------
  (if (fboundp 'advice-add) 'bmkp-store-org-link 'locate))
(define-key-after menu-bar-bookmark-map [save]
  '(menu-item "Save Bookmarks" bookmark-save :help "Save currently defined bookmarks")
  'separator-3)
(define-key-after menu-bar-bookmark-map [write]
  '(menu-item "Save Bookmarks As..." bookmark-write
              :help "Write current bookmarks to a bookmark file")
  'save)
(define-key-after menu-bar-bookmark-map [bmkp-switch-bookmark-file-create]
  '(menu-item "Switch to Bookmark File..." bmkp-switch-bookmark-file-create
              :help "Switch to a different bookmark file, *replacing* the current set of bookmarks")
  'write)
(define-key-after menu-bar-bookmark-map [load]
  '(menu-item "Add Bookmarks from File..." bookmark-load
              :help "Load additional bookmarks from a bookmark file")
  'bmkp-switch-bookmark-file-create)
(define-key-after menu-bar-bookmark-map [bmkp-empty-file]
  '(menu-item "Empty Bookmark File..." bmkp-empty-file
              :help "Empty an existing bookmark file or create a new, empty bookmark file")
  'load)


;; `bmkp-annotate-menu' of vanilla `Bookmarks' menu: `Annotate'

(defvar bmkp-annotate-menu (make-sparse-keymap)
  "`Annotate' submenu for menu-bar `Bookmarks' menu.")
(define-key menu-bar-bookmark-map [annotate] (cons "Annotate" bmkp-annotate-menu))

(define-key bmkp-annotate-menu [bookmark-show-all-annotations]
  '(menu-item "Show All Annotations" bookmark-show-all-annotations
              :help "Show the annotations for all bookmarks"))
(define-key bmkp-annotate-menu [bookmark-show-annotation]
  '(menu-item "Show an Annotation" bookmark-show-annotation
              :help "Show the annotation for a bookmark, or follow it if external"))
(define-key bmkp-annotate-menu [bmkp-annotate-all-bookmarks-this-file/buffer]
  '(menu-item "Annotate All Bookmarks Here" bmkp-annotate-all-bookmarks-this-file/buffer
              :help "Pop up an annotation-editing buffer for each bookmark in this buffer"))
(define-key bmkp-annotate-menu [bmkp-annotate-bookmark-this-file/buffer]
  '(menu-item "Annotate a Bookmark Here" bmkp-annotate-bookmark-this-file/buffer
              :help "Annotate an existing bookmark in this buffer"))
(define-key bmkp-annotate-menu [bmkp-annotate-bookmark]
  '(menu-item "Annotate a Bookmark" bmkp-annotate-bookmark
              :help "Pop up a buffer to add or edit an annotation for a bookmark"))


;; `bmkp-highlight-menu' of vanilla `Bookmarks' menu: `Highlight'

(when (or (featurep 'bookmark+-lit)
          (and (fboundp 'diredp-highlight-autofiles-mode)  (featurep 'highlight)))
  (defvar bmkp-highlight-menu (make-sparse-keymap)
    "`Highlight' submenu for menu-bar `Bookmarks' menu.")
  (define-key menu-bar-bookmark-map [highlight] (cons "Highlight" bmkp-highlight-menu))

  (when (featurep 'bookmark+-lit)
    (define-key bmkp-highlight-menu [bmkp-unlight-bookmarks]
      '(menu-item "Unhighlight All" bmkp-unlight-bookmarks
                  :help "Unhighlight all bookmarks (everywhere)"))
    (define-key bmkp-highlight-menu [bmkp-unlight-this-buffer]
      '(menu-item "Unhighlight All in Buffer" bmkp-unlight-this-buffer
                  :help "Unhighlight all bookmarks in this buffer"))
    (define-key bmkp-highlight-menu [bmkp-unlight-non-autonamed-this-buffer]
      '(menu-item "Unhighlight All Non-Autonamed in Buffer" bmkp-unlight-non-autonamed-this-buffer
                  :help "Unhighlight all non-autonamed bookmarks in this buffer"))
    (define-key bmkp-highlight-menu [bmkp-unlight-autonamed-this-buffer]
      '(menu-item "Unhighlight All Autonamed in Buffer" bmkp-unlight-autonamed-this-buffer
                  :help "Unhighlight all autonamed bookmarks in this buffer"))
    (define-key bmkp-highlight-menu [bmkp-unlight-bookmark]
      '(menu-item "Unhighlight One..." bmkp-unlight-bookmark
                  :help "Unhighlight a bookmark"))
    (define-key bmkp-highlight-menu [bmkp-unlight-bookmark-this-buffer]
      '(menu-item "Unhighlight One in Buffer..." bmkp-unlight-bookmark-this-buffer
                  :help "Unhighlight a bookmark in this buffer"))
    (define-key bmkp-highlight-menu [bmkp-unlight-bookmark-here]
      '(menu-item "Unhighlight This One" bmkp-unlight-bookmark-here
                  :help "Unhighlight a bookmark at point or on its line"))

    (define-key bmkp-highlight-menu [separator-2] '("--")) ;------------------------------------------
    (define-key bmkp-highlight-menu [bmkp-light-bookmarks-in-region]
      '(menu-item "Highlight All in Region" bmkp-light-bookmarks-in-region
                  :help "Highlight all bookmarks in the region"))
    (define-key bmkp-highlight-menu [bmkp-light-this-buffer]
      '(menu-item "Highlight All in Buffer" bmkp-light-this-buffer
                  :help "Highlight all bookmarks in this buffer"))
    (define-key bmkp-highlight-menu [bmkp-light-non-autonamed-this-buffer]
      '(menu-item "Highlight All Non-Autonamed in Buffer" bmkp-light-non-autonamed-this-buffer
                  :help "Highlight all non-autonamed bookmarks in this buffer"))
    (define-key bmkp-highlight-menu [bmkp-light-autonamed-this-buffer]
      '(menu-item "Highlight All Autonamed in Buffer" bmkp-light-autonamed-this-buffer
                  :help "Highlight all autonamed bookmarks in this buffer"))
    (define-key bmkp-highlight-menu [bmkp-light-navlist-bookmarks]
      '(menu-item "Highlight All in Navigation List" bmkp-light-navlist-bookmarks
                  :help "Highlight all bookmarks in the navigation list"))
    (define-key bmkp-highlight-menu [bmkp-light-bookmark-this-buffer]
      '(menu-item "Highlight One in Buffer..." bmkp-light-bookmark-this-buffer
                  :help "Highlight a bookmark in this buffer"))
    (define-key bmkp-highlight-menu [bmkp-light-bookmark]
      '(menu-item "Highlight One..." bmkp-light-bookmark
                  :help "Highlight a bookmark"))

    (define-key bmkp-highlight-menu [separator-1] '("--")) ;------------------------------------------
    (define-key bmkp-highlight-menu [bmkp-describe-bookmark-lighted-here]
      '(menu-item "Describe Highlighted Here (`C-u': internal form)"
                  bmkp-describe-bookmark-lighted-here
                  :help "Describe a highlighted bookmark on this line."
                  :enable (and (fboundp 'bmkp-describe-bookmark-lighted-here)
                               (or (bmkp-a-bookmark-lighted-at-pos (point) 'FULL)
                                   (bmkp-a-bookmark-lighted-on-this-line 'FULL)))))
    (define-key bmkp-highlight-menu [bmkp-bookmarks-lighted-at-point]
      '(menu-item "List Highlighted at Point" bmkp-bookmarks-lighted-at-point
                  :help "List the bookmarks at point that are highlighted"
                  :enable (bmkp-bookmarks-lighted-at-point)))
    (define-key bmkp-highlight-menu [bmkp-next-lighted-this-buffer]
      '(menu-item "Next in Buffer" bmkp-next-lighted-this-buffer
                  :help "Cycle to the next highlighted bookmark in this buffer"))
    (define-key bmkp-highlight-menu [bmkp-previous-lighted-this-buffer]
      '(menu-item "Previous in Buffer" bmkp-previous-lighted-this-buffer
                  :help "Cycle to the previous highlighted bookmark in this buffer"))
    (define-key bmkp-highlight-menu [separator-0] '("--")) ;------------------------------------------
    )

  (define-key bmkp-highlight-menu [diredp-highlight-autofiles-mode]
    (bmkp-menu-bar-make-toggle diredp-highlight-autofiles-mode
                               diredp-highlight-autofiles-mode
                               "Toggle Autofile Highlighting in Dired"
                               "Whether to highlight autofile bookmarks in Dired us biw %s"
                               "Toggle `diredp-highlight-autofiles-mode'"
                               nil
                               :visible (and (fboundp 'diredp-highlight-autofiles-mode)
                                             (featurep 'highlight))))

  (when (featurep 'bookmark+-lit)
    (define-key bmkp-highlight-menu [bmkp-set-lighting-for-bookmark]
      '(menu-item "Set Highlighting for One..." bmkp-set-lighting-for-bookmark
                  :help "Set individual highlighting for a bookmark"))))


;; `bmkp-here-menu' of vanilla `Bookmarks' menu: `Here'

(define-key menu-bar-bookmark-map [bookmarks-here]
  `(menu-item "Here (This File/Buffer)" bmkp-here-menu
              :enable (and bmkp-add-bookmarks-here-menu-flag
                           (bmkp-exists-this-file/buffer-bookmarks-p))))


;; `bmkp-delete-menu' of vanilla `Bookmarks' menu: `Delete'

(defvar bmkp-delete-menu (make-sparse-keymap)
  "`Delete' submenu for menu-bar `Bookmarks' menu.")
(define-key menu-bar-bookmark-map [delete-menu] (cons "Delete" bmkp-delete-menu))

(define-key bmkp-delete-menu [bmkp-delete-all-temporary-bookmarks]
  '(menu-item "Delete All Temporaries..." bmkp-delete-all-temporary-bookmarks
              :help "Delete the temporary bookmarks, (`X') whether visible here or not"))

;;; $$$$$$ NOTE: Here and below, the definitions with logically correct `:enable' filters are
;;;              commented out.  This is because evaluation of these filters is too slow, especially
;;;              in older Emacs versions.  If you want to try some or all of the definitions with the
;;;              `:enable' conditions, just uncomment them and comment out or remove the corresponding
;;;              definitions without such conditions.

;;;;; (define-key bmkp-delete-menu [bmkp-delete-all-autonamed-for-this-buffer]
;;;;;   '(menu-item "Delete All Autonamed Bookmarks Here..."
;;;;;     bmkp-delete-all-autonamed-for-this-buffer
;;;;;     :help "Delete all autonamed bookmarks for the current buffer"
;;;;;     :enable (mapcar #'bmkp-bookmark-name-from-record (bmkp-autonamed-this-buffer-alist-only))))
(define-key bmkp-delete-menu [bmkp-delete-all-autonamed-for-this-buffer]
  '(menu-item "Delete All Autonamed Bookmarks Here..."
              bmkp-delete-all-autonamed-for-this-buffer
              :help "Delete all autonamed bookmarks for the current buffer"))
(define-key bmkp-delete-menu [bmkp-toggle-autoname-bookmark-delete]
  '(menu-item "Delete Autonamed Bookmark" bmkp-toggle-autonamed-bookmark-set/delete
              :help "Delete the autonamed bookmark at point"
              :visible (bmkp-get-bookmark-in-alist (funcall bmkp-autoname-bookmark-function (point))
                                                   'noerror)))
;;;;; (define-key bmkp-delete-menu [bmkp-delete-bookmarks]
;;;;;   '(menu-item "Delete Bookmarks Here..." bmkp-delete-bookmarks
;;;;;     :help "Delete some bookmarks at point or, with `C-u', all bookmarks in the buffer"
;;;;;     :enable (mapcar #'bmkp-bookmark-name-from-record (bmkp-this-buffer-alist-only))))
(define-key bmkp-delete-menu [bmkp-delete-bookmarks]
  '(menu-item "Delete Bookmarks Here..." bmkp-delete-bookmarks
              :help "Delete some bookmarks at point or, with `C-u', all bookmarks in the buffer"))
(define-key bmkp-delete-menu [delete]
  '(menu-item "Delete Bookmark..." bookmark-delete :help "Delete the bookmark you choose by name"))
(define-key bmkp-delete-menu [bmkp-purge-notags-autofiles]
  '(menu-item "Purge Autofiles with No Tags..." bmkp-purge-notags-autofiles
              :help "Delete all autofile bookmarks that have no tags"))

;; Remove vanilla `bookmark-delete' entry from main `Bookmarks' menu.
(define-key menu-bar-bookmark-map [delete] nil)


;; `bmkp-set-bookmark-menu' of vanilla `Bookmarks' menu: `New/Update'
(defvar bmkp-set-bookmark-menu (make-sparse-keymap)
  "`New/Update' submenu for menu-bar `Bookmarks' menu.")
(define-key menu-bar-bookmark-map [set-bookmark] (cons "New/Update" bmkp-set-bookmark-menu))

(defun bmkp-menu-bar-set-bookmark ()
  "Set a bookmark, prompting for the name."
  (interactive)
  (call-interactively #'bmkp-bookmark-set-confirm-overwrite))

(define-key bmkp-set-bookmark-menu [bmkp-make-function-bookmark]
  '(menu-item "Function Bookmark..." bmkp-make-function-bookmark
              :help "Create a bookmark that will invoke a function when \"jumped\" to"))
(define-key bmkp-set-bookmark-menu [bmkp-toggle-autoname-bookmark-set]
  '(menu-item "Autonamed Bookmark" bmkp-toggle-autonamed-bookmark-set/delete
              :help "Set an autonamed bookmark at point"
              :visible (not (bmkp-get-bookmark-in-alist (funcall bmkp-autoname-bookmark-function (point))
                                                        'NOERROR))))
(define-key bmkp-set-bookmark-menu [bmkp-set-bookmark-file-bookmark]
  '(menu-item "Bookmark-File Bookmark..." bmkp-set-bookmark-file-bookmark
              :help "Set a bookmark that loads a bookmark file when jumped to"))
(define-key bmkp-set-bookmark-menu [bmkp-set-desktop-bookmark]
  '(menu-item "Desktop Bookmark" bmkp-set-desktop-bookmark
              :help "Save the current desktop as a bookmark"))
(define-key bmkp-set-bookmark-menu [bmkp-url-target-set]
  '(menu-item "URL Bookmark..." bmkp-url-target-set
              :help "Set a bookmark for a given URL"))
(define-key bmkp-set-bookmark-menu [bmkp-file-target-set]
  '(menu-item "File Bookmark..." bmkp-file-target-set
              :help "Set a bookmark with a given name for a given file"))
(define-key bmkp-set-bookmark-menu [bmkp-autofile-set]
  '(menu-item "Autofile Bookmark..." bmkp-autofile-set
              :help "Set and automatically name a bookmark for a given file"))
(define-key bmkp-set-bookmark-menu [bmkp-menu-bar-set-bookmark]
  '(menu-item "Ordinary Bookmark..." bmkp-menu-bar-set-bookmark
              :help "Set a bookmark at point" :keys "(C-x x m)")) ; Really bound to `bookmark-set'


;; Remove vanilla `bookmark-set' from main `Bookmarks' menu.
(define-key menu-bar-bookmark-map [set] nil)


;; `bmkp-options-menu' of vanilla `Bookmarks' menu: `Toggle'.  Reuse `bmkp-bmenu-toggle-menu'.
(define-key menu-bar-bookmark-map [options] (cons "Toggle" bmkp-bmenu-toggle-menu))


;; `bmkp-tags-menu' of vanilla `Bookmarks' menu: `Tags'

(defvar bmkp-tags-menu (make-sparse-keymap)
  "`Tags' submenu for menu-bar `Bookmarks' menu.")
(define-key menu-bar-bookmark-map [tags] (cons "Tags" bmkp-tags-menu))

(define-key bmkp-tags-menu [bmkp-list-all-tags]
  '(menu-item "List All Tags" bmkp-list-all-tags :help "List all tags used for any bookmarks"))
(define-key bmkp-tags-menu [bmkp-purge-notags-autofiles]
  '(menu-item "Purge Autofiles with No Tags..." bmkp-purge-notags-autofiles
              :help "Delete all autofile bookmarks that have no tags"))
(define-key bmkp-tags-menu [bmkp-untag-a-file]
  '(menu-item "Untag a File (Remove Some)..." bmkp-untag-a-file
              :help "Remove some tags from autofile bookmark for a file"))
(define-key bmkp-tags-menu [bmkp-tag-a-file]
  '(menu-item "Tag a File (Add Some)..." bmkp-tag-a-file
              :help "Add some tags to the autofile bookmark for a file"))

(define-key bmkp-tags-menu [tags-sep1] '("--")) ;----------------------------------------------
(define-key bmkp-tags-menu [bmkp-rename-tag]
  '(menu-item "Rename Tag..." bmkp-rename-tag :help "Rename a tag in all bookmarks"))
(define-key bmkp-tags-menu [bmkp-set-tag-value]
  '(menu-item "Set Tag Value..." bmkp-set-tag-value :help "Set the tag value for a given bookmark"))
(define-key bmkp-tags-menu [bmkp-remove-tags-from-all]
  '(menu-item "Remove Some Tags from All..." bmkp-remove-tags-from-all
              :help "Remove a set of tags from all bookmarks"))
(define-key bmkp-tags-menu [bmkp-remove-tags]
  '(menu-item "Remove Some Tags..." bmkp-remove-tags :help "Remove a set of tags from a bookmark"))
(define-key bmkp-tags-menu [bmkp-add-tags]
  '(menu-item "Add Some Tags..." bmkp-add-tags :help "Add a set of tags to a bookmark"))
(define-key bmkp-tags-menu [bmkp-paste-replace-tags]
  '(menu-item "Paste Tags (Replace)..." bmkp-paste-replace-tags
              :help "Replace tags for a bookmark with tags copied from another"))
(define-key bmkp-tags-menu [bmkp-paste-add-tags]
  '(menu-item "Paste Tags (Add)..." bmkp-paste-add-tags
              :help "Add tags to a bookmark that were previously copied from another"))
(define-key bmkp-tags-menu [bmkp-copy-tags]
  '(menu-item "Copy Tags..." bmkp-copy-tags
              :help "Copy the tags from a bookmark, so you can paste them to another"))
(define-key bmkp-tags-menu [bmkp-edit-tags]
  '(menu-item "Edit Tags..." bmkp-edit-tags :help "Edit the tags of a bookmark"))


;; `bmkp-jump-menu' of vanilla `Bookmarks' menu: `Jump To'

(defvar bmkp-jump-menu (make-sparse-keymap)
  "`Jump To' submenu for menu-bar `Bookmarks' menu.")
;; Add jump menu to vanilla Emacs `Bookmarks' menu and remove the two jump commands already there.
(define-key menu-bar-bookmark-map [jump] nil)
(define-key menu-bar-bookmark-map [jump-other] nil)
(define-key menu-bar-bookmark-map [bmkp-jump] (cons "Jump To" bmkp-jump-menu))

;; `Jump To': Add jump menu also to the `Bookmark+' menu, and remove the two jump commands there.
(define-key bmkp-bmenu-menubar-menu [jump] (cons "Jump To" bmkp-jump-menu))

(define-key bmkp-jump-menu [bmkp-temporary-jump-other-window]
  '(menu-item "Temporary..." bmkp-temporary-jump-other-window
              :help "Jump to a temporary bookmark"))
(define-key bmkp-jump-menu [bmkp-autofile-jump-other-window]
  '(menu-item "Autofile..." bmkp-autofile-jump-other-window
              :help "Jump to an autofile bookmark"))
(define-key bmkp-jump-menu [bmkp-autonamed-this-buffer-jump]
  '(menu-item "Autonamed for This Buffer..." bmkp-autonamed-this-buffer-jump
              :help "Jump to an autonamed bookmark in this buffer"))
(define-key bmkp-jump-menu [bmkp-autonamed-jump-other-window]
  '(menu-item "Autonamed..." bmkp-autonamed-jump-other-window
              :help "Jump to an autonamed bookmark"))
(define-key bmkp-jump-menu [bmkp-specific-files-jump-other-window]
  '(menu-item "For Specific Files..." bmkp-specific-files-jump-other-window
              :help "Jump to a bookmark for specific files"))
(define-key bmkp-jump-menu [bmkp-specific-buffers-jump-other-window]
  '(menu-item "For Specific Buffers..." bmkp-specific-buffers-jump-other-window
              :help "Jump to a bookmark for specific buffers"))
;;;;; (define-key bmkp-jump-menu [bmkp-this-buffer-jump]
;;;;;   '(menu-item "For This Buffer..." bmkp-this-buffer-jump
;;;;;     :help "Jump to a bookmark for the current buffer"
;;;;;     :enable (mapcar #'bmkp-bookmark-name-from-record (bmkp-this-buffer-alist-only))))
(define-key bmkp-jump-menu [bmkp-this-buffer-jump]
  '(menu-item "For This Buffer..." bmkp-this-buffer-jump
              :help "Jump to a bookmark for the current buffer"))
;;;;; (when (featurep 'bookmark+-lit)
;;;;;   (define-key bmkp-jump-menu [bmkp-lighted-jump-other-window]
;;;;;     '(menu-item "Highlighted..." bmkp-lighted-jump-other-window
;;;;;       :help "Jump to a highlighted bookmark"
;;;;;       :enable (bmkp-lighted-alist-only))))
(when (featurep 'bookmark+-lit)
  (define-key bmkp-jump-menu [bmkp-lighted-jump-other-window]
    '(menu-item "Highlighted..." bmkp-lighted-jump-other-window
                :help "Jump to a highlighted bookmark")))
(define-key bmkp-jump-menu [bmkp-jump-in-navlist-other-window]
  '(menu-item "In Navigation List..." bmkp-jump-in-navlist-other-window
              :help "Jump to a bookmark that is in the navigation list" :enable bmkp-nav-alist))

(define-key bmkp-jump-menu [jump-sep0] '("--")) ;---------------------------------------------------
;;;;; (define-key bmkp-jump-menu [bmkp-url-jump-other-window]
;;;;;   '(menu-item "URL..." bmkp-url-jump-other-window :help "Jump to a URL bookmark"
;;;;;     :enable (bmkp-url-alist-only)))
(define-key bmkp-jump-menu [bmkp-url-jump-other-window]
  '(menu-item "URL..." bmkp-url-jump-other-window :help "Jump to a URL bookmark"))
;;;;; (define-key bmkp-jump-menu [bmkp-gnus-jump-other-window]
;;;;;   '(menu-item "Gnus..." bmkp-gnus-jump-other-window :help "Jump to a Gnus bookmark"
;;;;;     :enable (bmkp-gnus-alist-only)))
(define-key bmkp-jump-menu [bmkp-gnus-jump-other-window]
  '(menu-item "Gnus..." bmkp-gnus-jump-other-window :help "Jump to a Gnus bookmark"))
;;;;; (define-key bmkp-jump-menu [bmkp-man-jump-other-window]
;;;;;   '(menu-item "Man Page..." bmkp-man-jump-other-window :help "Jump to a `man'-page bookmark"
;;;;;     :enable (bmkp-man-alist-only)))
(define-key bmkp-jump-menu [bmkp-man-jump-other-window]
  '(menu-item "Man Page..." bmkp-man-jump-other-window :help "Jump to a `man'-page bookmark"))
;;;;; (define-key bmkp-jump-menu [bmkp-info-jump-other-window]
;;;;;   '(menu-item "Info Node..." bmkp-info-jump-other-window :help "Jump to an Info bookmark"
;;;;;     :enable (bmkp-info-alist-only)))
(define-key bmkp-jump-menu [bmkp-info-jump-other-window]
  '(menu-item "Info Node..." bmkp-info-jump-other-window :help "Jump to an Info bookmark"))
;;;;; (define-key bmkp-jump-menu [bmkp-image-jump-other-window]
;;;;;   '(menu-item "Image..." bmkp-image-jump-other-window :help "Jump to an image-file bookmark"
;;;;;     :enable (bmkp-image-alist-only)))
(define-key bmkp-jump-menu [bmkp-image-jump-other-window]
  '(menu-item "Image..." bmkp-image-jump-other-window :help "Jump to an image-file bookmark"))
;;;;; (define-key bmkp-jump-menu [bmkp-non-file-jump-other-window]
;;;;;   '(menu-item "Buffer (Non-File)..." bmkp-non-file-jump-other-window
;;;;;     :help "Jump to a non-file (buffer) bookmark" :enable (bmkp-non-file-alist-only)))
(define-key bmkp-jump-menu [bmkp-non-file-jump-other-window]
  '(menu-item "Buffer (Non-File)..." bmkp-non-file-jump-other-window
              :help "Jump to a non-file (buffer) bookmark"))
;;;;; (define-key bmkp-jump-menu [bmkp-region-jump-other-window]
;;;;;   '(menu-item "Region..." bmkp-region-jump-other-window
;;;;;     :help "Jump to a bookmark that defines the active region" :enable (bmkp-region-alist-only)))
(define-key bmkp-jump-menu [bmkp-region-jump-other-window]
  '(menu-item "Region..." bmkp-region-jump-other-window
              :help "Jump to a bookmark that defines the active region"))
;;;;; (define-key bmkp-jump-menu [bmkp-remote-file-jump-other-window]
;;;;;   '(menu-item "Remote File..." bmkp-remote-file-jump-other-window
;;;;;     :help "Jump to a remote file or directory bookmark" :enable (bmkp-remote-file-alist-only)))
(define-key bmkp-jump-menu [bmkp-remote-file-jump-other-window]
  '(menu-item "Remote File..." bmkp-remote-file-jump-other-window
              :help "Jump to a remote file or directory bookmark"))
;;;;; (define-key bmkp-jump-menu [bmkp-local-file-jump-other-window]
;;;;;   '(menu-item "Local File..." bmkp-local-file-jump-other-window
;;;;;     :help "Jump to a local file or directory bookmark" :enable (bmkp-local-file-alist-only)))
(define-key bmkp-jump-menu [bmkp-local-file-jump-other-window]
  '(menu-item "Local File..." bmkp-local-file-jump-other-window
              :help "Jump to a local file or directory bookmark"))
;;;;; (define-key bmkp-jump-menu [bmkp-file-this-dir-jump-other-window]
;;;;;   '(menu-item "File in This Dir..." bmkp-file-this-dir-jump-other-window
;;;;;     :help "Jump to a bookmark for a file or subdirectory in the `default-directory'."
;;;;;     :enable (bmkp-file-alist-only)))
(define-key bmkp-jump-menu [bmkp-file-this-dir-jump-other-window]
  '(menu-item "File in This Dir..." bmkp-file-this-dir-jump-other-window
              :help "Jump to a bookmark for a file or subdirectory in the `default-directory'."))
;;;;; (define-key bmkp-jump-menu [bmkp-file-jump-other-window]
;;;;;   '(menu-item "File..." bmkp-file-jump-other-window :help "Jump to a file or directory bookmark"
;;;;;     :enable (bmkp-file-alist-only)))
(define-key bmkp-jump-menu [bmkp-file-jump-other-window]
  '(menu-item "File..." bmkp-file-jump-other-window :help "Jump to a file or directory bookmark"))
;;;;; (define-key bmkp-jump-menu [bmkp-dired-this-dir-jump-other-window]
;;;;;   '(menu-item "Dired for This Dir..." bmkp-dired-this-dir-jump-other-window
;;;;;     :help "Jump to a Dired bookmark for `default-directory', restoring recorded state"
;;;;;     :enable (bmkp-dired-alist-only)))
(define-key bmkp-jump-menu [bmkp-dired-this-dir-jump-other-window]
  '(menu-item "Dired for This Dir..." bmkp-dired-this-dir-jump-other-window
              :help "Jump to a Dired bookmark for `default-directory', restoring recorded state"))
;;;;; (define-key bmkp-jump-menu [bmkp-dired-jump-other-window]
;;;;;   '(menu-item "Dired..." bmkp-dired-jump-other-window
;;;;;     :help "Jump to a Dired bookmark, restoring the recorded Dired state"
;;;;;     :enable (bmkp-dired-alist-only)))
(define-key bmkp-jump-menu [bmkp-dired-jump-other-window]
  '(menu-item "Dired..." bmkp-dired-jump-other-window
              :help "Jump to a Dired bookmark, restoring the recorded Dired state"))
;;;;; (define-key bmkp-jump-menu [bmkp-variable-list-jump]
;;;;;   '(menu-item "Variable List..." bmkp-variable-list-jump :help "Jump to a variable-list bookmark"
;;;;;     :enable (bmkp-variable-list-alist-only)))
(define-key bmkp-jump-menu [bmkp-variable-list-jump]
  '(menu-item "Variable List..." bmkp-variable-list-jump :help "Jump to a variable-list bookmark"))
;;;;; (define-key bmkp-jump-menu [bmkp-bookmark-file-jump]
;;;;;   '(menu-item "Bookmark File..." bmkp-bookmark-file-jump
;;;;;     :help "Jump to (load) a bookmark-file bookmark" :enable (bmkp-bookmark-file-alist-only)))
(define-key bmkp-jump-menu [bmkp-bookmark-file-jump]
  '(menu-item "Bookmark File..." bmkp-bookmark-file-jump
              :help "Jump to (load) a bookmark-file bookmark"))
;;;;; (define-key bmkp-jump-menu [bmkp-bookmark-list-jump]
;;;;;   '(menu-item "Bookmark List..." bmkp-bookmark-list-jump :help "Jump to a bookmark-list bookmark"
;;;;;     :enable (bmkp-bookmark-list-alist-only)))
(define-key bmkp-jump-menu [bmkp-bookmark-list-jump]
  '(menu-item "Bookmark List..." bmkp-bookmark-list-jump :help "Jump to a bookmark-list bookmark"))
;;;;; (define-key bmkp-jump-menu [bmkp-desktop-jump]
;;;;;   '(menu-item "Desktop..." bmkp-desktop-jump :help "Jump to a desktop bookmark"
;;;;;     :enable (bmkp-desktop-alist-only)))
(define-key bmkp-jump-menu [bmkp-desktop-jump]
  '(menu-item "Desktop..." bmkp-desktop-jump :help "Jump to a desktop bookmark"))
(define-key bmkp-jump-menu [bmkp-jump-to-type-other-window]
  '(menu-item "Of Type..." bmkp-jump-to-type-other-window
              :help "Jump to a bookmark of a type that you specify"))

(define-key bmkp-jump-menu [bookmark-jump-other-window]
  '(menu-item "Any in Other Window..." bookmark-jump-other-window
              :help "Jump to a bookmark of any type, in another window"))
(define-key bmkp-jump-menu [bookmark-jump]
  '(menu-item "Any..." bookmark-jump :help "Jump to a bookmark of any type, in this window"))

(define-key bmkp-jump-menu [bmkp-bmenu-jump-to-marked]
  '(menu-item "Marked" bmkp-bmenu-jump-to-marked
              :help "Jump to each bookmark marked `>', in another window"
              :enable (and bmkp-bmenu-marked-bookmarks  (equal (buffer-name (current-buffer))
                                                               bookmark-bmenu-buffer))))


;; `bmkp-jump-tags-menu' of vanilla `Bookmarks' menu: `Jump To' > `With Tags'

(defvar bmkp-jump-tags-menu (make-sparse-keymap)
  "`With Tags' submenu for `Jump To' submenu of `Bookmarks' menu.")
(define-key bmkp-jump-menu [bmkp-tags] (cons "With Tags" bmkp-jump-tags-menu))
(define-key bmkp-jump-tags-menu [bmkp-file-this-dir-all-tags-regexp-jump-other-window]
  '(menu-item "File in This Dir, All Tags Matching Regexp..."
              bmkp-file-this-dir-all-tags-regexp-jump-other-window
              :help "Jump to a file bookmark in this dir where each tag matches a regexp"))
(define-key bmkp-jump-tags-menu [bmkp-file-this-dir-some-tags-regexp-jump-other-window]
  '(menu-item "File in This Dir, Any Tag Matching Regexp..."
              bmkp-file-this-dir-some-tags-regexp-jump-other-window
              :help "Jump to a file bookmark in this dir where at least one tag matches a regexp"))
(define-key bmkp-jump-tags-menu [bmkp-file-this-dir-all-tags-jump-other-window]
  '(menu-item "File in This Dir, All Tags in Set..." bmkp-file-this-dir-all-tags-jump-other-window
              :help "Jump to a file bookmark in this dir that has all of a set of tags that you enter"))
(define-key bmkp-jump-tags-menu [bmkp-file-this-dir-some-tags-jump-other-window]
  '(menu-item "File in This Dir, Any Tag in Set..." bmkp-file-this-dir-some-tags-jump-other-window
              :help "Jump to a file bookmark in this dir that has some of a set of tags that you enter"))

(define-key bmkp-jump-tags-menu [jump-sep5] '("--")) ;----------------------------------------------
(define-key bmkp-jump-tags-menu [bmkp-file-all-tags-regexp-jump-other-window]
  '(menu-item "File, All Tags Matching Regexp..." bmkp-file-all-tags-regexp-jump-other-window
              :help "Jump to a file or dir bookmark where each tag matches a regexp that you enter"))
(define-key bmkp-jump-tags-menu [bmkp-file-some-tags-regexp-jump-other-window]
  '(menu-item "File, Any Tag Matching Regexp..." bmkp-file-some-tags-regexp-jump-other-window
              :help "Jump to a file or dir bookmark where at least one tag matches a regexp that you enter"))
(define-key bmkp-jump-tags-menu [bmkp-file-all-tags-jump-other-window]
  '(menu-item "File, All Tags in Set..." bmkp-file-all-tags-jump-other-window
              :help "Jump to a file or dir bookmark that has all of a set of tags that you enter"))
(define-key bmkp-jump-tags-menu [bmkp-file-some-tags-jump-other-window]
  '(menu-item "File, Any Tag in Set..." bmkp-file-some-tags-jump-other-window
              :help "Jump to a file or dir bookmark that has some of a set of tags that you enter"))

(define-key bmkp-jump-tags-menu [jump-sep4] '("--")) ;----------------------------------------------
(define-key bmkp-jump-tags-menu [bmkp-autofile-all-tags-regexp-jump-other-window]
  '(menu-item "Autofile, All Tags Matching Regexp..."
              bmkp-autofile-all-tags-regexp-jump-other-window
              :help "Jump to an autofile bookmark where each tag matches a regexp that you enter"))
(define-key bmkp-jump-tags-menu [bmkp-autofile-some-tags-regexp-jump-other-window]
  '(menu-item "Autofile, Any Tag Matching Regexp..."
              bmkp-autofile-some-tags-regexp-jump-other-window
              :help "Jump to an autofile bookmark where at least one tag matches a regexp that you enter"))
(define-key bmkp-jump-tags-menu [bmkp-autofile-all-tags-jump-other-window]
  '(menu-item "Autofile, All Tags in Set..."
              bmkp-autofile-all-tags-jump-other-window
              :help "Jump to an autofile bookmark that has all of a set of tags that you enter"))
(define-key bmkp-jump-tags-menu [bmkp-autofile-some-tags-jump-other-window]
  '(menu-item "Autofile, Any Tag in Set..." bmkp-autofile-some-tags-jump-other-window
              :help "Jump to an autofile bookmark that has some of a set of tags that you enter"))

(when (fboundp 'bmkp-find-file-all-tags) ; Emacs 21+
  (define-key bmkp-jump-tags-menu [jump-sep3] '("--")) ;----------------------------------------------
  (define-key bmkp-jump-tags-menu [bmkp-find-file-all-tags-regexp-other-window]
    '(menu-item "Find Autofile, All Tags Matching Regexp..."
                bmkp-find-file-all-tags-regexp-other-window
                :help "Visit a bookmarked file where each tag matches a regexp that you enter"))
  (define-key bmkp-jump-tags-menu [bmkp-find-file-some-tags-regexp-other-window]
    '(menu-item "Find Autofile, Any Tag Matching Regexp..."
                bmkp-find-file-some-tags-regexp-other-window
                :help "Visit a bookmarked file where at least one tag matches a regexp that you enter"))
  (define-key bmkp-jump-tags-menu [bmkp-find-file-all-tags-other-window]
    '(menu-item "Find Autofile, All Tags in Set..."
                bmkp-find-file-all-tags-other-window
                :help "Visit a bookmarked file that has all of a set of tags that you enter"))
  (define-key bmkp-jump-tags-menu [bmkp-find-file-some-tags-other-window]
    '(menu-item "Find Autofile, Any Tag in Set..." bmkp-find-file-some-tags-other-window
                :help "Visit a bookmarked file that has some of a set of tags that you enter")))

(define-key bmkp-jump-tags-menu [jump-sep2] '("--")) ;----------------------------------------------
(define-key bmkp-jump-tags-menu [bmkp-all-tags-regexp-jump-other-window]
  '(menu-item "All Tags Matching Regexp..." bmkp-all-tags-regexp-jump-other-window
              :help "Jump to a bookmark that has each tag matching a regexp that you enter"))
(define-key bmkp-jump-tags-menu [bmkp-some-tags-regexp-jump-other-window]
  '(menu-item "Any Tag Matching Regexp..." bmkp-some-tags-regexp-jump-other-window
              :help "Jump to a bookmark that has at least one tag matching a regexp that you enter"))
(define-key bmkp-jump-tags-menu [bmkp-all-tags-jump-other-window]
  '(menu-item "All Tags in Set..." bmkp-all-tags-jump-other-window
              :help "Jump to a bookmark that has all of a set of tags that you enter"))
(define-key bmkp-jump-tags-menu [bmkp-some-tags-jump-other-window]
  '(menu-item "Any Tag in Set..." bmkp-some-tags-jump-other-window
              :help "Jump to a bookmark that has some of a set of tags that you enter"))


;; `File' > `Find File or Autofile' submenu
;; or, for Emacs 20-21, single item `File' > `Find File or Autofile...'.
(if (not (fboundp 'bmkp-find-file-all-tags))
    (define-key menu-bar-file-menu [bmkp-find-file-other-window] ; Emacs 20-21
      '(menu-item "Find File or Autofile..." bmkp-find-file-other-window))
  (defvar bmkp-find-file-menu (make-sparse-keymap)
    "`Find File or Autofile' submenu for menu-bar `File' menu.")
  (define-key menu-bar-file-menu [bmkp-find-file-menu]
    (list 'menu-item "Find File or Autofile" bmkp-find-file-menu))
  (define-key bmkp-find-file-menu [bmkp-find-file-all-tags-regexp-other-window]
    '(menu-item "All Tags Matching Regexp..." bmkp-find-file-all-tags-regexp-other-window
                :help "Visit a file or dir where each tag matches a regexp that you enter"))
  (define-key bmkp-find-file-menu [bmkp-find-file-some-tags-regexp-other-window]
    '(menu-item "Any Tag Matching Regexp..." bmkp-find-file-some-tags-regexp-other-window
                :help "Jump to a file or dir bookmark where at least one tag matches a regexp that you enter"))
  (define-key bmkp-find-file-menu [bmkp-find-file-all-tags-other-window]
    '(menu-item "All Tags in Set..." bmkp-find-file-all-tags-other-window
                :help "Visit a file or dir that has all of a set of tags that you enter"))
  (define-key bmkp-find-file-menu [bmkp-find-file-some-tags-other-window]
    '(menu-item "Any Tag in Set..." bmkp-find-file-some-tags-other-window
                :help "Visit a file or dir that has some of a set of tags that you enter"))
  (define-key bmkp-find-file-menu [find-file-sep2] '("--")) ;---------
  (define-key bmkp-find-file-menu [bmkp-find-file-other-window]
    '(menu-item "Any File or Autofile..." bmkp-find-file-other-window
                :help "Visit a bookmarked file or directory: an autofile bookmark.")))

;;;;;;;;;;;;;;;;;;;;;

(provide 'bookmark+-key)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; bookmark+-key.el ends here
