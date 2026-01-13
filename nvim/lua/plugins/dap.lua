return {
    'mfussenegger/nvim-dap',
    config = function()
        local dap = require('dap')
        dap.configurations.java = {
            {
                javaExec = "java",
                request = "launch",
                type = "java",
            },
            {
                type = 'java',
                request = 'attach',
                name = "Debug (Attach) - Remote",
                hostName = "127.0.0.1",
                port = 5005,
            }
        }
    end
}
