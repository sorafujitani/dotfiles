local M = {}

---@param line string
---@return string? prefix
---@return string? clear
function M.next_item(line)
	local indent, marker, body = line:match("^(%s*)([-+*])%s+(.*)$")
	local number, delimiter

	if not marker then
		indent, number, delimiter, body = line:match("^(%s*)(%d+)([.)])%s+(.*)$")
		if not number then
			return nil, nil
		end
		marker = tostring(tonumber(number) + 1) .. delimiter
	end

	local checkbox, checkbox_body = body:match("^%[([ xX])%]%s*(.*)$")
	if checkbox then
		if checkbox_body == "" then
			return nil, indent
		end
		return indent .. marker .. " [ ] ", nil
	end

	if body == "" then
		return nil, indent
	end

	return indent .. marker .. " ", nil
end

local function in_code_block()
	local ok, node = pcall(vim.treesitter.get_node, { bufnr = 0 })
	if not ok then
		return false
	end

	while node do
		local node_type = node:type()
		if node_type == "fenced_code_block" or node_type == "indented_code_block" then
			return true
		end
		node = node:parent()
	end

	return false
end

---@return boolean|string handled
function M.continue_list()
	if not vim.tbl_contains({ "markdown", "markdown.mdx", "mdx" }, vim.bo.filetype) or in_code_block() then
		return false
	end

	local line = vim.api.nvim_get_current_line()
	local prefix, clear = M.next_item(line)
	if clear ~= nil then
		local keys = string.rep("<BS>", #line - #clear)
		return vim.api.nvim_replace_termcodes(keys, true, false, true)
	end
	if not prefix then
		return false
	end

	local keys = vim.api.nvim_replace_termcodes("<CR>" .. prefix, true, false, true)
	return keys
end

return M
