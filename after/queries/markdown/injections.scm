; Empty override — Neovim 0.12's bundled markdown injection queries can throw
; `node:range()` nil errors in the decoration provider. Using a no-op injections
; file prevents the injection subsystem from running on markdown entirely,
; which is the only reliable fix until the parser/query stack is updated.
