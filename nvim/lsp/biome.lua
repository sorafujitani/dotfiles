-- Nix/Home Managerで管理するグローバルBiomeを優先し、無ければプロジェクトのpnpmにfallbackする
local biome_path = vim.fn.exepath('biome')
local cmd
if biome_path ~= '' then
  cmd = { biome_path, 'lsp-proxy' }
else
  local pnpm_path = vim.fn.exepath('pnpm')
  if pnpm_path == '' then
    pnpm_path = 'pnpm'
  end
  cmd = { pnpm_path, 'biome', 'lsp-proxy' }
end

---@type vim.lsp.Config
return {
  cmd = cmd,
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'json', 'jsonc' },
  root_markers = { 'biome.json', 'biome.jsonc' },
  workspace_required = true,
}
