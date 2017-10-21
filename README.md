[![MELPA](https://melpa.org/packages/lsp-rust-badge.svg)](https://melpa.org/#/lsp-rust)

Rust support for lsp-mode using the [Rust Language Server](https://github.com/rust-lang-nursery/rls).

*Warning: RLS is currently very unstable, which can make Emacs hang
indefinitely. Using this in production isn't recommended.*

# Setup

First, [install the RLS](https://github.com/rust-lang-nursery/rls).

Then you should just load `lsp-rust` after `lsp-mode` by adding the following to
your init file:

```emacs-lisp
(with-eval-after-load 'lsp-mode
  (setq lsp-rust-rls-command '("rustup" "run" "nightly" "rls"))
  (require 'lsp-rust))
```

If you installed the RLS via `rustup' (the recommended way), then the `setq`
line tells `lsp-rust` how to launch the RLS.  If you would rather use the
`RLS_ROOT` variable to locate the RLS, then set `lsp-rust-rls-command` to `nil`.

Now, you can activate `lsp-mode` in a Rust buffer, and you should have all the
benefits of the RLS as handled by `lsp-mode`.

If you want on-the-fly syntax checking, first make sure that `lsp-flycheck` is
loaded (see [lsp-mode
installation](https://github.com/emacs-lsp/lsp-mode#installation)), then simply
turn on `flycheck-mode`.

If you want to automatically launch `lsp-mode` and `flycheck-mode` whenever you
open a rust buffer, you can add the following to your init file:

```emacs-lisp
(add-hook 'rust-mode-hook #'lsp-rust-enable)
(add-hook 'rust-mode-hook #'flycheck-mode)
```
