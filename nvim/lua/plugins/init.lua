return require('packer').startup(function()
    use 'wbthomason/packer.nvim'
    use {
        'kyazdani42/nvim-tree.lua',
        requires = {
            'kyazdani42/nvim-web-devicons'
        },
        tag = 'nightly',
        config = function()
            require('nvim-tree').setup()
            -- require('nvim-web-devicons').setup()
        end
    }
    use {
        'neovim/nvim-lspconfig',
        config = function()
            require('lspconfig').pyright.setup{} 
        end
    }
    use 'hrsh7th/cmp-nvim-lsp'
    use 'hrsh7th/cmp-buffer'
    use 'hrsh7th/cmp-path'
    use 'hrsh7th/cmp-cmdline'
    use 'hrsh7th/nvim-cmp'
end)
