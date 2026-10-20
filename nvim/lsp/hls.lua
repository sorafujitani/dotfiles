---@type vim.lsp.Config
return {
  cmd = { 'haskell-language-server-wrapper', '--lsp' },
  filetypes = { 'haskell', 'lhaskell', 'cabal' },
  root_markers = { 'hie.yaml', 'cabal.project', 'stack.yaml', 'flake.nix', '.git' },
}
