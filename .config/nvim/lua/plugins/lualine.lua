return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    init = function()
      vim.g.lualine_laststatus = vim.o.laststatus
      if vim.fn.argc(-1) > 0 then
        -- set an empty statusline till lualine loads
        vim.o.statusline = " "
      else
        -- hide the statusline on the starter page
        vim.o.laststatus = 0
      end
    end,
    opts = function()
      -- PERF: we don't need this lualine require madness 🤷
      local lualine_require = require("lualine_require")
      lualine_require.require = require

      local icons = LazyVim.config.icons

      vim.o.laststatus = vim.g.lualine_laststatus

      -- Définir une fonction de secours pour Snacks.util.color si elle n'existe pas
      local function get_color(name)
        if Snacks and Snacks.util and type(Snacks.util.color) == "function" then
          return Snacks.util.color(name)
        end
        return "#ffffff" -- Couleur par défaut
      end

      local opts = {
        options = {
          theme = "auto",
          globalstatus = vim.o.laststatus == 3,
          disabled_filetypes = { statusline = { "dashboard", "alpha", "ministarter" } },
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch" },

          lualine_c = {
            LazyVim.lualine.root_dir(),
            {
              "diagnostics",
              symbols = {
                error = icons.diagnostics.Error,
                warn = icons.diagnostics.Warn,
                info = icons.diagnostics.Info,
                hint = icons.diagnostics.Hint,
              },
            },
            { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
            { LazyVim.lualine.pretty_path() },
          },
          lualine_x = {
                -- stylua: ignore
                {
                  function() return package.loaded["noice"] and require("noice").api.status.command() or "" end,
                  cond = function() return package.loaded["noice"] and require("noice").api.status.command ~= nil end,
                  color = { fg = get_color("Statement") },
                },
                -- stylua: ignore
                {
                  function() return package.loaded["noice"] and require("noice").api.status.mode.get() or "" end,
                  cond = function() return package.loaded["noice"] and require("noice").api.status.mode and require("noice").api.status.mode.has() end,
                  color = { fg = get_color("Constant") },
                },
                -- stylua: ignore
                {
                  function() return "  " .. require("dap").status() end,
                  cond = function() return package.loaded["dap"] and require("dap").status and require("dap").status() ~= "" end,
                  color = { fg = get_color("Debug")},
                },
                -- stylua: ignore
                {
                  require("lazy.status").updates,
                  cond = function() return package.loaded["lazy.status"] and require("lazy.status").has_updates() end,
                  color = { fg = get_color("Special") },
                },
            {
              "diff",
              symbols = {
                added = icons.git.added,
                modified = icons.git.modified,
                removed = icons.git.removed,
              },
              source = function()
                local gitsigns = vim.b.gitsigns_status_dict
                if gitsigns then
                  return {
                    added = gitsigns.added,
                    modified = gitsigns.changed,
                    removed = gitsigns.removed,
                  }
                end
              end,
            },
          },
          lualine_y = {
            { "progress", separator = " ", padding = { left = 1, right = 0 } },
            { "location", padding = { left = 0, right = 1 } },
          },
          lualine_z = {
            function()
              return " " .. os.date("%R")
            end,
          },
        },
        extensions = { "neo-tree", "lazy" },
      }

      -- Vérifier si trouble.nvim est disponible avant de l'utiliser
      if vim.g.trouble_lualine and LazyVim.has("trouble.nvim") and package.loaded["trouble"] then
        local ok, trouble = pcall(require, "trouble")
        if ok then
          local symbols = trouble.statusline({
            mode = "symbols",
            groups = {},
            title = false,
            filter = { range = true },
            format = "{kind_icon}{symbol.name:Normal}",
            hl_group = "lualine_c_normal",
          })

          if
            symbols
            and type(symbols) == "table"
            and type(symbols.get) == "function"
            and type(symbols.has) == "function"
          then
            table.insert(opts.sections.lualine_c, {
              symbols.get,
              cond = function()
                return vim.b.trouble_lualine ~= false and symbols.has()
              end,
            })
          end
        end
      end

      return opts
    end,
  },
}

