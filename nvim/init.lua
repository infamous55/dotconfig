-- Options
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.scrolloff = 8
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.smarttab = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.wrapscan = true
vim.opt.showmatch = true
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.conceallevel = 0
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.winborder = "rounded"

-- Keymaps
vim.g.mapleader = " "
vim.g.maplocalleader = ","

vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set({ "n", "v" }, "<leader>d", [["+d]])
vim.keymap.set("n", "<leader>D", [["+D]])

vim.keymap.set("n", "<leader>p", [["+p]])
vim.keymap.set("n", "<leader>P", [["+P]])

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", {})
vim.keymap.set("n", "<leader>b", "<cmd>FzfLua buffers<cr>")
vim.keymap.set("n", "<leader>ff", "<cmd>FzfLua files<cr>")
vim.keymap.set("n", "<leader>lg", "<cmd>FzfLua live_grep<cr>")

vim.keymap.set("n", "gd", vim.lsp.buf.definition)
vim.keymap.set("n", "gD", vim.lsp.buf.type_definition)
vim.keymap.set("n", "gi", vim.lsp.buf.implementation)
vim.keymap.set("n", "gr", vim.lsp.buf.references)
vim.keymap.set("n", "K", vim.lsp.buf.hover)
vim.keymap.set("n", "<space>r", vim.lsp.buf.rename)
vim.keymap.set("n", "<space>f", vim.lsp.buf.format)
vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action)

vim.keymap.set("n", "<space>d", vim.diagnostic.open_float)
vim.keymap.set("n", "[d", function()
	vim.diagnostic.jump({ count = -1 })
end)
vim.keymap.set("n", "]d", function()
	vim.diagnostic.jump({ count = 1 })
end)

-- Plugins
vim.pack.add({
	{ src = "https://github.com/projekt0n/github-nvim-theme" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" },
	{ src = "https://github.com/saghen/blink.cmp", version = vim.version.range("^1") },
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/stevearc/conform.nvim" },
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },
	{ src = "https://github.com/nvim-tree/nvim-tree.lua" },
	{ src = "https://github.com/ibhagwan/fzf-lua" },
	{ src = "https://github.com/nvim-mini/mini.diff" },
	{ src = "https://github.com/nvim-mini/mini.comment" },
	{ src = "https://github.com/kylechui/nvim-surround" },
}, { load = true })

vim.cmd("colorscheme github_dark_colorblind")

require("nvim-treesitter.configs").setup({
	ensure_installed = {
		"lua",
		"c",
		"cpp",
		"meson",
		"rust",
		"go",
		"gomod",
		"gosum",
		"python",
		"bash",
		"sql",
		"dockerfile",
		"just",
		"gitignore",
		"markdown",
		"json",
		"toml",
		"yaml",
		"kdl",
		"typst",
		"diff",
		"regex",
	},
	sync_install = false,
	highlight = { enable = true },
	indent = { enable = true },
})

require("blink.cmp").setup({
	keymap = {
		preset = "enter",
		["<C-u>"] = { "scroll_documentation_up", "fallback" },
		["<C-d>"] = { "scroll_documentation_down", "fallback" },
	},
	completion = {
		documentation = {
			auto_show = true,
			auto_show_delay_ms = 0,
		},
	},
	signature = { enabled = true },
	cmdline = { enabled = false },
})

vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH
require("mason").setup({})

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		c = { "clang-format" },
		cpp = { "clang-format" },
		rust = { "rustfmt" },
		go = { "gofumpt", "goimports", "goimports-reviser", "golines" },
		python = { "ruff_format" },
		bash = { "shfmt" },
		markdown = { "prettier" },
		json = { "prettier" },
		toml = { "taplo" },
		yaml = { "prettier" },
		kdl = { "kdlfmt" },
		typst = { "typstyle" },
	},
	default_format_opts = {
		lsp_format = "fallback",
	},
	format_on_save = { timeout_ms = 1000 },
})

require("nvim-tree").setup({
	filters = { custom = { "^\\.git$" } },
	disable_netrw = true,
	prefer_startup_root = true,
	update_focused_file = { enable = true },
	view = { side = "right" },
	git = { ignore = false },
	renderer = {
		highlight_git = "all",
		indent_markers = { enable = true },
	},
})

require("fzf-lua").setup({
	winopts = { backdrop = 0 },
})

require("mini.diff").setup({})
require("mini.comment").setup({})
require("nvim-surround").setup({})

-- LSP
vim.lsp.enable({
	"lua_ls",
	"clangd",
	"rust_analyzer",
	"gopls",
	"ruff",
	"ty",
	"bashls",
	"taplo",
	"tinymist",
})

-- Diagnostics
vim.diagnostic.config({ severity_sort = true })
