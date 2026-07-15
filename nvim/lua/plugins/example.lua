return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "TermExec" },
    -- We bind our own keys (under <localleader>t) to avoid conflicts
    keys = function()
      local function toggle(id, dir)
        return function()
          -- Lazy-load and use our small helper module defined in config()
          require("toggleterm_custom").toggle(id, dir)
        end
      end

      return {
        { "<localleader>t",  function() end,          desc = "+terminal" }, -- which-key group

        -- Floating terminals (default)
        { "<localleader>tt", toggle(1),               desc = "Toggle Terminal 1 (float)" },
        { "<localleader>t1", toggle(1),               desc = "Toggle Terminal 1 (float)" },
        { "<localleader>t2", toggle(2),               desc = "Toggle Terminal 2 (float)" },
        { "<localleader>t3", toggle(3),               desc = "Toggle Terminal 3 (float)" },

        -- Same terminals in other layouts (optional quick access)
        { "<localleader>tv", toggle(1, "vertical"),   desc = "Terminal 1 as Vertical Split" },
        { "<localleader>ts", toggle(1, "horizontal"), desc = "Terminal 1 as Horizontal Split" },
      }
    end,
    opts = {
      -- Size only matters for split layouts; float uses width/height below
      size = function(term)
        if term.direction == "horizontal" then
          return math.floor(vim.o.lines * 0.30)
        elseif term.direction == "vertical" then
          return math.floor(vim.o.columns * 0.35)
        end
        return 20
      end,
      direction = "float",     -- default view
      open_mapping = nil,      -- no default <C-\> mapping (avoid conflicts)
      start_in_insert = true,
      insert_mappings = false, -- we'll set our own key in on_open
      terminal_mappings = false,
      persist_mode = true,
      persist_size = true,
      close_on_exit = true,
      shade_terminals = true,
      float_opts = {
        border = "rounded",
        width = function()
          return math.floor(vim.o.columns * 0.90)
        end,
        height = function()
          return math.floor(vim.o.lines * 0.85)
        end,
        winblend = 0,
      },
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)

      -- Small helper to manage multiple (reusable) terminals
      local Terminal = require("toggleterm.terminal").Terminal
      local terms = {}

      local M = {}

      function M.get(id, direction)
        direction = direction or "float"
        if not terms[id] or terms[id].direction ~= direction then
          terms[id] = Terminal:new({
            id = id,
            direction = direction,
            hidden = true,
            float_opts = opts.float_opts,
            on_open = function(term)
              -- Start in insert and make <Esc> go to normal mode (buffer-local)
              vim.cmd("startinsert!")
              vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = term.bufnr, desc = "Terminal: normal mode" })
            end,
          })
        end
        return terms[id]
      end

      function M.toggle(id, direction)
        M.get(id, direction):toggle()
      end

      -- Expose the helper so our keymaps can require it on demand
      package.loaded["toggleterm_custom"] = M
    end,
  },
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = false,
      style = "storm",
      lualine_bold = true,
    },
  },
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      -- only set the preset you want
      opts.keymap.preset = "super-tab" -- or "enter", "default", etc.
      -- optional completion tweak
      opts.completion = opts.completion or {}
      opts.completion.list = vim.tbl_deep_extend("force", opts.completion.list or {}, {
        selection = { auto_insert = false },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.capabilities = opts.capabilities or vim.lsp.protocol.make_client_capabilities()
      opts.capabilities.textDocument = opts.capabilities.textDocument or {}
      opts.capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      }
    end,
  },
  {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = "BufReadPost",
    opts = {
      provider_selector = function(bufnr, filetype, buftype)
        -- Skip folding for certain buffer types
        if buftype ~= "" then
          return ""
        end

        -- First try LSP if available
        local clients = vim.lsp.get_clients({ bufnr = bufnr })
        if #clients > 0 then
          return { "lsp", "indent" }
        end

        -- For common file types, use treesitter with fallback
        local ts_filetypes = {
          "lua", "python", "javascript", "typescript", "rust", "go",
          "c", "cpp", "java", "html", "css", "json", "yaml", "toml",
          "bash", "sh", "vim", "markdown"
        }

        for _, ft in ipairs(ts_filetypes) do
          if filetype == ft then
            return { "treesitter", "indent" }
          end
        end

        -- Default fallback to indent for unknown file types
        return { "indent" }
      end,
    },
    keys = {
      {
        "zR",
        function()
          require("ufo").openAllFolds()
        end,
        desc = "Open all folds",
      },
      {
        "zM",
        function()
          require("ufo").closeAllFolds()
        end,
        desc = "Close all folds",
      },
      {
        "zr",
        function()
          require("ufo").openFoldsExceptKinds()
        end,
        desc = "Open folds except certain kinds",
      },
      {
        "zm",
        function()
          require("ufo").closeFoldsWith()
        end,
        desc = "Close folds with nesting",
      },
      {
        "zj",
        function()
          require("ufo").goNextClosedFold()
        end,
        desc = "Go to next fold",
      },
      {
        "zk",
        function()
          require("ufo").goPreviousClosedFold()
        end,
        desc = "Go to previous fold",
      },
    },
  },
}
