-- Markdown は文章として読みやすい表示を優先する。
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.breakindent = true
vim.opt_local.breakindentopt = { "shift:2", "min:20" }
vim.opt_local.showbreak = ""

local function toggle_todo()
	local line = vim.api.nvim_get_current_line()
	local prefix, state, suffix = line:match("^(%s*[-+*]%s+)%[([ xX]?)%](.*)$")
	if not prefix then
		prefix, state, suffix = line:match("^(%s*%d+[.)]%s+)%[([ xX]?)%](.*)$")
	end
	if not prefix then
		return
	end

	local checked = state == "x" or state == "X"
	vim.api.nvim_set_current_line(prefix .. (checked and "[]" or "[x]") .. suffix)
end

vim.api.nvim_buf_create_user_command(0, "Todo", toggle_todo, { desc = "Toggle Markdown TODO checkbox" })
vim.keymap.set("n", "<leader>x", toggle_todo, { buffer = true, desc = "Toggle Markdown TODO checkbox" })
