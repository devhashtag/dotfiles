local jdtls = require('jdtls')
local root_markers = { 'pom.xml', '.git', 'mvnw', 'gradlew', 'build.gradle' }
local root_dir = require('jdtls.setup').find_root(root_markers)
print(root_dir)
if not root_dir or root_dir == vim.loop.cwd() then
  root_dir = vim.fs.dirname(vim.fs.find(root_markers, { upward = true })[1])
end
root_dir = vim.fs.dirname(vim.fs.find(root_markers, { upward = true })[1])
print(root_dir)
if not root_dir then
    return
end

local home = os.getenv("HOME")
local workspace_dir = home .. "/.local/share/eclipse/" .. vim.fn.fnamemodify(root_dir, ":p:h:t")

local config = {
  cmd = { "jdtls", "-data", workspace_dir },
  root_dir = root_dir,

  on_attach = function(client, bufnr)
    local opts = { noremap = true, silent = true, buffer = bufnr }

    vim.keymap.set('n', '<leader>oi', jdtls.organize_imports, opts)
    vim.keymap.set('n', '<leader>ev', jdtls.extract_variable, opts)
    vim.keymap.set('n', '<leader>ec', jdtls.extract_constant, opts)
    vim.keymap.set('v', '<leader>em', [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]], opts)

    -- 🧩 Initialize DAP for Java
    -- require('jdtls.dap').setup_dap_main_class_configs()

    -- (Optional) You can force reload configs like this:
    -- vim.cmd [[ command! JdtUpdateConfig lua require('jdtls.dap').setup_dap_main_class_configs() ]]
  end,

  init_options = {
    bundles = {
      vim.fn.glob("/Users/peterheijstek/Repositories/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-*.jar", 1)
    },
  },
}

require('jdtls').start_or_attach(config)

