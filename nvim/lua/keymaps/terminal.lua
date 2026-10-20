-- ターミナル関連キーマップ

-- ターミナルモードでESCでノーマルモードに戻る
vim.keymap.set("t", "<ESC>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- ターミナルトグル (snacks.terminal)
vim.keymap.set("n", "<C-t>", function()
	require("snacks").terminal.toggle(nil, {
		cwd = vim.fn.getcwd(),
		count = 1,
		shell = { vim.env.SHELL or vim.o.shell },
	})
end, { desc = "Toggle terminal" })
vim.keymap.set("t", "<C-t>", function()
	local current = vim.b.snacks_terminal
	if current then
		require("snacks").terminal.toggle(current.cmd, {
			cwd = current.cwd,
			count = current.id,
			env = current.env,
		})
		return
	end

	require("snacks").terminal.toggle(nil, {
		cwd = vim.fn.getcwd(),
		count = 1,
		shell = { vim.env.SHELL or vim.o.shell },
	})
end, { desc = "Toggle terminal" })

vim.api.nvim_create_user_command("Ai", function()
	require("snacks").terminal.toggle({
		"codex",
		"--model",
		"gpt-5.3-codex-spark",
		"--config",
		'model_reasoning_effort="high"',
	}, {
		cwd = vim.fn.getcwd(),
		count = 1,
	})
end, { desc = "Open Codex with GPT-5.3 Codex Spark (high reasoning)" })
