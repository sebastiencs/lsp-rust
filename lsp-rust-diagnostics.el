;;; lsp-rust-diagnostics.el --- Rust live diagnostics

;; Copyright (C) 2017 Sebastien Chapuis <sebastien@chapu.is>>

;; Author: Sebastien Chapuis <sebastien@chapu.is>
;; Version: 1.0

;;; Commentary:

;; diagnostics

;;; Code:

(require 'flycheck)
(require 'dash)

(defvar lsp-rust-diagnostics-ovs nil
  "Overlays.")

(defvar lsp-rust-diagnostics-labels nil
  "Labels.")

(defvar lsp-rust-diagnostics-column-start 70
  ".")

(defvar lsp-rust-diagnostics--secondaries nil)

(defun lsp-rust-diagnostics--show-label (line label position max-len)
  "LINE LABEL POSITION MAX-LEN."
  (let* ((pos (save-excursion
                (goto-char (point-min))
                (line-end-position line)))
         (width-line (save-excursion (goto-char pos) (current-column)))
         (string (concat " "
                         ;; (make-string (- (window-text-width) width-line max-len 10) ?\-)
                         (make-string (max (- lsp-rust-diagnostics-column-start width-line) 5) ?\-)
                         " "
                         label))
         (ov (make-overlay pos pos)))
    (add-face-text-property 0 (length string) '(:foreground "orange") nil string)
    (when (and (or (bound-and-true-p hl-line-mode)
                   (bound-and-true-p global-hl-line-mode))
               (= (line-number-at-pos) line))
      (add-face-text-property 0 (length string) 'hl-line t string)
      )
    (overlay-put ov 'after-string string)
    ;; (print (format-message "position: %s" position))
    (when position
      (let ((ov (make-overlay (car position) (cdr position))))
        (overlay-put ov 'face `(:box (:line-width -1 :color "orange") :background ,(frame-parameter nil 'background-color)))
        ;;        (overlay-put ov 'face `(:box (:line-width -1 :color "orange") :foreground "orange" :background ,(frame-parameter nil 'background-color)))
        (overlay-put ov 'priority 1000)
        (push ov lsp-rust-diagnostics-ovs)
        )
      )
    (push ov lsp-rust-diagnostics-ovs)))

(defun lsp-rust-diagnostics-show-primary (err)
  "ERR."
  (let* ((string (flycheck-error-message err))
         (no-label (> (length (split-string string "\n\n\n" t)) 1))
         (strings (split-string string "\n\n" t))
         label)
    (unless no-label
      (setq label (if (>= (length strings) 3)
                      (nth 1 strings)
                    (cadr strings))))

    ;; (dolist (s strings)
    ;;   (princ (format-message "STRINGS: %s\n" s)))

    (setq strings (--map (with-temp-buffer
                           (insert it)
                           (set-face-foreground 'markdown-metadata-value-face "white")
                           (set-face-foreground 'markdown-inline-code-face "sienna")
                           (markdown-view-mode)
                           (font-lock-ensure)
                           (buffer-string))
                         strings))

    (setq strings (--map-first t (propertize it 'face '(:foreground "red" :weight 'ultra-bold)) strings))

    (setq strings
          (cond (no-label (string-join strings "\n"))
                ((>= (length strings) 3) (string-join (-remove-at 1 strings) "\n\n"))
                (t (car strings))))

    (lsp-ui-doc--display 'a strings)
    (push (list :line (flycheck-error-line err) :label label) lsp-rust-diagnostics-labels)
    ))

(defun lsp-rust-diagnostics--list-labels nil
  "."
  (let ((max-len (-max (--map (length (cdr it)) lsp-rust-diagnostics-labels))))
    (dolist (label lsp-rust-diagnostics-labels)
      (-let* (((&plist :line line :position position :label label) label))
        (when (> (length label) 0)
          (lsp-rust-diagnostics--show-label line label position max-len))))))

(defun lsp-rust-diagnostics--range-to-points (range)
  "RANGE."
  (-let* (((&plist :line start-line :column start-col) (plist-get range :start))
          ((&plist :line end-line :column end-col) (plist-get range :end)))
    ;; (message "line: %s col: %s line: %s col: %s" start-line start-col end-line end-col)
    (cons
     (save-excursion
       (widen)
       (goto-char (point-min))
       (goto-char (+ (line-beginning-position (1+ start-line)) start-col))
       (point))
     (save-excursion
       (widen)
       (goto-char (point-min))
       (goto-char (+ (line-beginning-position (1+ end-line)) end-col))
       (point)))))

(defun lsp-rust-diagnostics-show-secondaries (errors)
  "ERRORS."
  (dolist (e errors)
    (let* ((line (1+ (lsp-diagnostic-line e)))
           (label (lsp-diagnostic-message e))
           (range (lsp-diagnostic-range e))
           (strings (split-string label "\n\n" t))
           (label (if (>= (length strings) 2)
                      (string-join (-remove-at 0 strings))
                    (car strings)))
           (pos (lsp-rust-diagnostics--range-to-points range)))
      ;; (print (format-message "position: %s range: %s" pos range))
      (push (list :line line :label label :position pos) lsp-rust-diagnostics-labels)
      ;; (push (cons line label) lsp-rust-diagnostics-labels)
      )
    ))

(defun lsp-rust-diagnostics-display (err)
  "ERR."
  (let* ((group (flycheck-error-group err))
         (secondaries (gethash buffer-file-name lsp-rust-diagnostics--secondaries))
         (secondaries (--filter (= (gethash "group" (lsp-diagnostic-original it)) group) secondaries)))
    (lsp-rust-diagnostics-show-primary err)
    (lsp-rust-diagnostics-show-secondaries secondaries)
    (lsp-rust-diagnostics--list-labels)
    ))

(defun lsp-rust-diagnostics ()
  "."
  (mapc 'delete-overlay lsp-rust-diagnostics-ovs)
  (setq lsp-rust-diagnostics-ovs nil)
  (setq lsp-rust-diagnostics-labels nil)
  (setq lsp-ui-sideline-show-flycheck nil)
  (-if-let (err (car (flycheck-overlay-errors-at (point))))
      (lsp-rust-diagnostics-display err)
    (setq lsp-ui-sideline-show-flycheck t)
    (lsp-ui-doc--hide-frame)
    )
  )

;; (add-hook 'post-command-hook 'lsp-rust-diagnostics)
;; (remove-hook 'post-command-hook 'lsp-ui-doc--make-request)

(provide 'lsp-rust-diagnostics)
;;; lsp-rust-diagnostics.el ends here
