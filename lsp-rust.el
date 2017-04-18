;;; lsp-rust.el --- Rust support for lsp-mode

;; Copyright (C) 2017 Vibhav Pant <vibhavp@gmail.com>

;; Author: Vibhav Pant <vibhavp@gmail.com>
;; Version: 1.0
;; Package-Requires: ((lsp-mode "2.0") (rust-mode "0.3.0"))
;; Keywords: rust
;; URL: https://github.com/emacs-lsp/lsp-rust

(require 'rust-mode)
(require 'lsp-mode)

(defun lsp--rust-rls-command ()
  (let ((rls-root (getenv "RLS_ROOT")))
    (if rls-root
	`("cargo" "+nightly" "run" "--quiet" ,(concat
					       "--manifest-path="
					       (concat
                                                (file-name-as-directory
						 (expand-file-name rls-root))
                                                "Cargo.toml"))
	  "--release")
      "rls")))

(lsp-client-on-notification 'rust-mode "rustDocument/diagnosticsBegin"
			    #'(lambda (_w _p)))
(lsp-client-on-notification 'rust-mode "rustDocument/diagnosticsEnd"
			    #'(lambda (_w _p)))

;;;###autoload
(lsp-define-client 'rust-mode "rust" 'stdio
		   #'(lambda ()
		       (read-directory-name
			"Workspace root (should contain Cargo.toml): "
			default-directory))
		   :command (lsp--rust-rls-command)
		   :name "Rust Language Server")

(provide 'lsp-rust)
