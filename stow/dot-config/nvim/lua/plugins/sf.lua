return {
	{
		"zahidkizmaz/sf.nvim",
		dependencies = { "MunifTanjim/nui.nvim" },
		config = true,
		keys = {
			{ "<leader>sfs", "<cmd>SFShow<cr>", desc = "Show sf.nvim split" },
			{ "<leader>sfh", "<cmd>SFHide<cr>", desc = "Hide sf.nvim split" },
			{ "<leader>sft", "<cmd>SFTest<cr>", desc = "Run test class in current buffer" },
			{ "<leader>sfd", "<cmd>SFDeploy<cr>", desc = "Deploy current buffer to default sf org" },
			{ "<leader>sfT", "<cmd>SFDeployTest<cr>", desc = "Deploy and run tests of the current buffer" },
		},
	},
}
