---@type vim.lsp.Config
return {
  cmd = { 'moon-lsp', '--stdio' },
  filetypes = { 'moonbit' },
  -- workspace 構成では member の moon.mod.json より moon.work を優先する
  root_markers = { { 'moon.work' }, { 'moon.mod.json' }, { '.git' } },
}
