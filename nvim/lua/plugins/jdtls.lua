return {
  "mfussenegger/nvim-jdtls",
  ft = { "java" }, -- Load only for Java files
  dependencies = {
    "mfussenegger/nvim-dap",
  },
  config = function()
    -- Nothing heavy here — ftplugin/java.lua will handle setup
    -- You can put minimal config if needed, but generally leave empty.
  end,
}

