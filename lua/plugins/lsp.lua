return {
	"neovim/nvim-lspconfig",
	event = "LazyFile",
	dependencies = {
		{ "folke/neoconf.nvim", cmd = "Neoconf", config = false, dependencies = { "nvim-lspconfig" } },
		{ "folke/neodev.nvim", opts = {} },
		"mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"hrsh7th/cmp-nvim-lsp", -- Add this line
	},
	---@class PluginLspOpts
	opts = {
		-- options for vim.diagnostic.config()
		diagnostics = {
			underline = true,
			update_in_insert = false,
			virtual_text = {
				spacing = 4,
				source = "if_many",
				prefix = "●",
			},
			severity_sort = true,
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = require("lazyvim.config").icons.diagnostics.Error,
					[vim.diagnostic.severity.WARN] = require("lazyvim.config").icons.diagnostics.Warn,
					[vim.diagnostic.severity.HINT] = require("lazyvim.config").icons.diagnostics.Hint,
					[vim.diagnostic.severity.INFO] = require("lazyvim.config").icons.diagnostics.Info,
				},
			},
		},
		inlay_hints = {
			enabled = false,
		},
		codelens = {
			enabled = false,
		},
		-- add any global capabilities here
		capabilities = vim.lsp.protocol.make_client_capabilities(),
		-- options for vim.lsp.buf.format
		format = {
			formatting_options = nil,
			timeout_ms = nil,
		},
		-- LSP Server Settings
		servers = {},
		setup = {
			-- example to setup with typescript.nvim
			-- tsserver = function(_, opts)
			--   require("typescript").setup({ server = opts })
			--   return true
			-- end,
			-- Specify * to use this function as a fallback for any server
			-- ["*"] = function(server, opts) end,
		},
	},
	---@param opts PluginLspOpts
	config = function(_, opts)
		local Util = require("lazyvim.util")

		-- Setup capabilities for nvim-cmp
		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
		-- opts.capabilities = vim.tbl_deep_extend("force", opts.capabilities or {}, capabilities)

		-- Rest of your existing configuration...
		if Util.has("neoconf.nvim") then
			local plugin = require("lazy.core.config").spec.plugins["neoconf.nvim"]
			require("neoconf").setup(require("lazy.core.plugin").values(plugin, "opts", false))
		end

		-- setup autoformat
		Util.format.register(Util.lsp.formatter())

		-- setup keymaps
		Util.lsp.on_attach(function(client, buffer)
			require("lazyvim.plugins.lsp.keymaps").on_attach(client, buffer)
		end)

		-- diagnostics
		for name, icon in pairs(require("lazyvim.config").icons.diagnostics) do
			name = "DiagnosticSign" .. name
			vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
		end

		-- inlay hints
		-- if opts.inlay_hints.enabled and vim.lsp.inlay_hint then
		-- 	Util.lsp.on_attach(function(client, buffer)
		-- 		if client.supports_method("textDocument/inlayHint") then
		-- 			vim.lsp.inlay_hint.enable(buffer, true)
		-- 		end
		-- 	end)
		-- end

		-- configure diagnostic settings
		vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

		-- configure servers
		local servers = opts.servers
		local function setup(server)
			local server_opts = vim.tbl_deep_extend("force", {
				capabilities = vim.deepcopy(opts.capabilities),
			}, servers[server] or {})

			if opts.setup[server] then
				if opts.setup[server](server, server_opts) then
					return
				end
			elseif opts.setup["*"] then
				if opts.setup["*"](server, server_opts) then
					return
				end
			end
			require("lspconfig")[server].setup(server_opts)
		end

		-- get all the servers that are available through mason-lspconfig
		local have_mason, mlsp = pcall(require, "mason-lspconfig")
		local all_mslp_servers = {}
		if have_mason then
			all_mslp_servers = vim.tbl_keys(require("mason-lspconfig.mappings.server").lspconfig_to_package)
		end

		local ensure_installed = {} ---@type string[]
		for server, server_opts in pairs(servers) do
			if server_opts then
				server_opts = server_opts == true and {} or server_opts
				-- run manual setup if mason=false or if this is a server that cannot be installed with mason-lspconfig
				if server_opts.mason == false or not vim.tbl_contains(all_mslp_servers, server) then
					setup(server)
				else
					ensure_installed[#ensure_installed + 1] = server
				end
			end
		end

		if have_mason then
			mlsp.setup({ ensure_installed = ensure_installed, handlers = { setup } })
		end

		if Util.lsp.get_config("denols") and Util.lsp.get_config("tsserver") then
			local is_deno = require("lspconfig.util").root_pattern("deno.json", "deno.jsonc")
			Util.lsp.disable("tsserver", is_deno)
			Util.lsp.disable("denols", function(root_dir)
				return not is_deno(root_dir)
			end)
		end
	end,
}
