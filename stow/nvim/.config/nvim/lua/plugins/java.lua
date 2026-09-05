return {
	-- Drop spotless (slow Maven invocation); jdtls LSP formats Java directly.
	-- Indent settings are synced from the Eclipse formatter XML on LSP attach
	-- (see autocmds.lua) as a workaround for eclipse.jdt.ls#1207.
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				java = { lsp_format = "prefer" },
			},
		},
	},

	-- Wire neotest-java into neotest (provided by the test.core extra).
	-- jdtls opts.test = false below frees <leader>tt/<leader>tr/<leader>tT
	-- so neotest owns them in Java buffers too.
	--
	-- config: monkey-patches ClasspathProvider to fix E5560.
	-- The original calls client:request() directly from a nio coroutine, which
	-- causes nvim_buf_is_valid to be invoked in a fast-event context. Wrapping
	-- both calls in vim.schedule() defers them to the main loop.
	-- This override is set in package.loaded before neotest-java lazily requires
	-- the module, so no files are modified on disk and updates work normally.
	{
		"rcasia/neotest-java",
		config = function()
			local mod = "neotest-java.core.spec_builder.compiler.classpath_provider"
			package.loaded[mod] = function(deps)
				local nio = require("nio")
				return {
					get_classpath = function(base_dir, additional_classpath_entries)
						additional_classpath_entries = additional_classpath_entries or {}
						local base_dir_uri = vim.uri_from_fname(base_dir:to_string())
						local client = deps.client_provider(base_dir)
						local bufnr = vim.tbl_keys(client.attached_buffers)[1]
						local runtime_fut = nio.control.future()
						local test_fut = nio.control.future()

						vim.schedule(function()
							client:request("workspace/executeCommand", {
								command = "java.project.getClasspaths",
								arguments = { base_dir_uri, vim.json.encode({ scope = "runtime" }) },
							}, function(err, result)
								if err then
									runtime_fut.set_error(err)
								else
									runtime_fut.set(result.classpaths)
								end
							end, bufnr)
						end)

						vim.schedule(function()
							client:request("workspace/executeCommand", {
								command = "java.project.getClasspaths",
								arguments = { base_dir_uri, vim.json.encode({ scope = "test" }) },
							}, function(err, result)
								if err then
									test_fut.set_error(err)
								else
									test_fut.set(result.classpaths)
								end
							end, bufnr)
						end)

						local additional_strings = vim.iter(additional_classpath_entries)
							:map(function(path)
								return path:to_string()
							end)
							:totable()

						return vim.iter({ runtime_fut.wait(), test_fut.wait(), additional_strings }):flatten():join(":")
					end,
				}
			end
		end,
	},
	{
		"nvim-neotest/neotest",
		optional = true,
		dependencies = { "rcasia/neotest-java" },
		opts = function(_, opts)
			opts.adapters = opts.adapters or {}
			table.insert(opts.adapters, require("neotest-java")({ ignore_wrapper = false }))
		end,
	},

	-- Dynamically pick the Eclipse formatter XML for each project.
	--
	-- jdtls detects root_dir as the nearest pom.xml (a submodule), not the real
	-- project root. We use .git to find the actual project root, then look for
	-- formatter.xml there. Falls back to ~/.config/java/formatter.xml if absent.
	--
	-- opts.test = false disables the built-in jdtls test keymaps so neotest-java
	-- can own <leader>tt / <leader>tr / <leader>tT. The java-test JARs are added
	-- manually in opts.jdtls because LazyVim normally only bundles them when
	-- opts.test = true; neotest-java needs them for LSP-based test discovery.
	--
	-- opts.jdtls runs inside LazyVim's attach_jdtls() with root_dir already set.
	-- DAP adapter setup and main-class config discovery are handled by LazyVim's
	-- lang.java extra (opts.dap / opts.dap_main) when dap.core is active.
	{
		"mfussenegger/nvim-jdtls",
		opts = {
			-- Disable built-in jdtls test keymaps; neotest-java owns <leader>t* now.
			test = false,

			jdtls = function(config)
				-- ── 1. Formatter / import order ────────────────────────────────
				local git_root = vim.fs.root(config.root_dir or "", { ".git" })
				local xml_path = git_root
						and vim.fn.filereadable(git_root .. "/formatter.xml") == 1
						and (git_root .. "/formatter.xml")
					or vim.fn.expand("~/.java/formatter.xml")

				local profile = "meta"
				local f = io.open(xml_path, "r")
				if f then
					local content = f:read("*all")
					f:close()
					profile = content:match('<profile[^>]+name="([^"]+)"') or profile
				end

				-- ── 2. java-test JARs (LSP test discovery for neotest-java) ────
				-- LazyVim skips these when opts.test = false, so we add them here.
				local ok, mason_registry = pcall(require, "mason-registry")
				if ok and mason_registry.is_installed("java-test") then
					local test_jars = vim.tbl_filter(function(jar)
						local name = vim.fn.fnamemodify(jar, ":t")
						return name ~= "jacocoagent.jar"
							and not name:match("runner%-jar%-with%-dependencies")
					end, vim.fn.glob("$MASON/share/java-test/*.jar", false, true))
					config.init_options = config.init_options or {}
					config.init_options.bundles = config.init_options.bundles or {}
					vim.list_extend(config.init_options.bundles, test_jars)
				end

				return vim.tbl_deep_extend("force", config, {
					settings = {
						java = {
							-- Matches IntelliJ IDEA's default import layout:
							--   everything else → javax.* → java.* → static imports
							completion = {
								importOrder = { "", "javax", "java", "#" },
							},
							format = {
								settings = { url = "file://" .. xml_path, profile = profile },
							},
						},
					},
				})
			end,
		},

		-- Discover main classes via jdtls and immediately launch with DAP.
		-- on_ready fires after the async LSP query populates dap.configurations.java,
		-- so dap.continue() shows a picker (multiple mains) or runs directly (one).
		keys = {
			{
				"<leader>jM",
				function()
					require("jdtls.dap").setup_dap_main_class_configs({
						on_ready = function()
							require("dap").continue()
						end,
					})
				end,
				desc = "Java: Run Main Class",
				ft = "java",
			},
		},
	},
}
