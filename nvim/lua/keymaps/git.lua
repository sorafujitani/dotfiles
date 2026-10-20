-- Git関連キーマップ

-- LazyGit (snacks.lazygit)
vim.keymap.set("n", "<leader>gg", function()
	require("snacks").lazygit()
end, { desc = "LazyGit" })

-- GitBrowse (snacks.gitbrowse)
vim.keymap.set("n", "<leader>go", function()
	require("snacks").gitbrowse()
end, { desc = "Git browse (open in browser)" })

-- Git blame (git.nvim)
vim.keymap.set("n", "<leader>gb", "<cmd>GitBlame<CR>", { desc = "Git blame" })

-- Neogit / Diffview
vim.keymap.set("n", "<leader>gd", "<cmd>Neogit<CR>", { desc = "Neogit" })
vim.keymap.set("n", "<leader>gD", "<cmd>DiffviewOpen<CR>", { desc = "Diffview open" })

-- NotePush
vim.keymap.set("n", "<leader>np", "<cmd>NotePush<CR>", { desc = "Note push (git add/commit/push)" })
