-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)



-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.tabstop = 4
vim.opt.softtabstop = 4     -- backspace and autoindent
vim.opt.shiftwidth = 4      -- autoindent, << and >> commands
vim.opt.expandtab = true    -- expand tabs to spaces

vim.opt.number = true
vim.opt.termguicolors = true

vim.diagnostic.config({virtual_text=true})


-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- import your plugins
    { import = "plugins" },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "habamax" } },
  -- automatically check for plugin updates
  checker = { enabled = false },
})

vim.cmd('colorscheme everforest')

local lspconfig = require('lspconfig')
local util = require('lspconfig.util')
-- PHP LSP
lspconfig.intelephense.setup {
    root_dir = util.root_pattern('.git', 'composer.json') or vim.fn.getcwd

}
lspconfig.pyright.setup {
    root_dir = util.root_pattern('.git') or vim.fn.getcwd,
    on_attach = function(client, bufnr)
        local opts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set('n', 'L', vim.lsp.buf.type_definition, opts)
    end
}

local allowed_symbol_kinds = {
  [vim.lsp.protocol.SymbolKind.File] = true,       -- Often the top-level document
  [vim.lsp.protocol.SymbolKind.Module] = true,     -- Can represent namespaces or top-level code blocks
  [vim.lsp.protocol.SymbolKind.Namespace] = true,
  [vim.lsp.protocol.SymbolKind.Package] = true,    -- Similar to module/namespace
  [vim.lsp.protocol.SymbolKind.Class] = true,
  [vim.lsp.protocol.SymbolKind.Method] = true,
  [vim.lsp.protocol.SymbolKind.Property] = true,   -- Class properties/attributes
  -- [vim.lsp.protocol.SymbolKind.Field] = true,   -- Sometimes synonymous with Property, include if needed
  [vim.lsp.protocol.SymbolKind.Constructor] = true,
  [vim.lsp.protocol.SymbolKind.Enum] = true,
  [vim.lsp.protocol.SymbolKind.Interface] = true,
  [vim.lsp.protocol.SymbolKind.Function] = true,
  [vim.lsp.protocol.SymbolKind.Constant] = true,   -- Class constants or global constants
  [vim.lsp.protocol.SymbolKind.Variable] = false,
  -- [vim.lsp.protocol.SymbolKind.Struct] = true,  -- For languages with structs (less common in pure PHP)
  -- Exclude: Variable, Parameter, String, Number, Boolean, Array, Object, Key, etc.
}

function show_outline()
    local bufnr = vim.api.nvim_get_current_buf()
    local client = vim.lsp.get_active_clients({bufnr = bufnr})[1]

    if not client then
        vim.notify('No active LSP client for this buffer')
        return
    end

    vim.lsp.buf.document_symbol({bufnr = bufnr}, function(err, result, ctx, config)
        if err then
          vim.notify("Error getting document symbols: " .. tostring(err), vim.log.levels.ERROR, { title = "LSP" })
          return
        end

        if not result or #result == 0 then
          vim.notify("No document symbols found for this file.", vim.log.levels.INFO, { title = "LSP" })
          vim.fn.setqflist({}) -- Clear quickfix if no symbols
          vim.cmd("cclose")    -- Close quickfix window
          return
        end

        local qf_items = {}
        local bufname = vim.api.nvim_buf_get_name(bufnr)

        -- Helper to map LSP kind enum (number) to a readable string (e.g., 1 -> "File", 2 -> "Module")
        local lsp_kinds = vim.lsp.protocol.SymbolKind
        local kind_map = {}
        for k, v in pairs(lsp_kinds) do
          kind_map[v] = k
        end

        -- Recursive function to format and collect symbols, handling nested structures
        local function format_symbol(symbol, level)
          -- --- This is the key change ---
          -- ONLY add to qf_items if the symbol's kind is in our allowed_symbol_kinds whitelist
          if allowed_symbol_kinds[symbol.kind] then
            local kind_str = kind_map[symbol.kind] or "Unknown"
            local prefix = string.rep("  ", level) -- Indent nested symbols for readability

            local item = {
              filename = bufname,
              lnum = symbol.range.start.line + 1,       -- LSP lines are 0-indexed
              col = symbol.range.start.character + 1,   -- LSP columns are 0-indexed
              text = string.format("%s[%s] %s", prefix, kind_str, symbol.name),
              type = "I", -- Information type for quickfix
            }
            table.insert(qf_items, item)
          end

          -- IMPORTANT: Always recurse into children, regardless of whether the parent symbol was included.
          -- This ensures that a relevant child (e.g., a method) is included even if its direct parent
          -- (e.g., a variable or a file symbol you chose to exclude) was filtered out.
          if symbol.children then
            for _, child in ipairs(symbol.children) do
              format_symbol(child, level + 1)
            end
          end
        end

        -- Start formatting from top-level symbols
        for _, symbol in ipairs(result) do
          format_symbol(symbol, 0)
        end

        vim.fn.setqflist({}, 'r', qf_items)
        vim.cmd("copen")
        vim.cmd("normal! zt") -- Scroll to top of quickfix list (optional)

    end)
end

-- Telescope config
local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>o', show_outline , { desc = 'Show file outline in the quickfix list'})

-- nvim-dap + nvim-dap-ui setup
local dap = require("dap")
local dapui = require("dapui")

dap.adapters.python = {
    type = 'executable',
    command = 'python3',
    args = {'-m', 'debugpy.adapter'}
}
dap.configurations.python = {
    {
        type = 'python',
        request = 'launch',
        name = 'Launch file',
        program = '${file}',
        pythonPath = function()
            return '/usr/bin/python3'
        end
    }
}

-- General keymaps

-- Quickfix navigation
vim.keymap.set("n", "]q", ":cnext<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "[q", ":cprev<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>r", function()
  local cmd = 'python3 problem7.py'
  local bufname = "Command Output"

  -- Find existing buffer
  local bufnr
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and vim.api.nvim_buf_get_name(b):match(bufname .. "$") then
      bufnr = b
      break
    end
  end

  -- Find existing window showing it
  local winid = nil
  if bufnr then
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(w) == bufnr then
        winid = w
        break
      end
    end
  end

  -- If no window is showing it, open a vertical split on the right
  if winid then
    vim.api.nvim_set_current_win(winid)
  else
    vim.cmd("vsplit")          -- open vertical split
    vim.cmd("wincmd L")        -- move it to the rightmost position
    vim.cmd("enew")        -- move it to the rightmost position
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "hide"
    vim.bo.swapfile = false
    vim.api.nvim_buf_set_name(0, bufname)
    bufnr = vim.api.nvim_get_current_buf()
  end

  -- Run command and fill output
  local output = vim.fn.systemlist(cmd)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, output)
  vim.bo.modifiable = true
  vim.bo.readonly = false
  -- vim.cmd("normal! G") -- scroll to bottom
end, { desc = "Run shell command (right split, reusable)", noremap = true, silent = true })


vim.lsp.enable('jdtls')
