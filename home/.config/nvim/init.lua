vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(event)
        local name, kind = event.data.spec.name, event.data.kind
        if name == 'avante.nvim' and (kind == 'install' or kind == 'update') then
            vim.system({ 'make', 'BUILD_FROM_SOURCE=true' }, { cwd = event.data.path })
        end
    end
})

vim.pack.add({
    -- Common Lua Libs
    'https://github.com/nvim-lua/plenary.nvim',
    'https://github.com/MunifTanjim/nui.nvim',

    -- QoL
    'https://github.com/nvim-tree/nvim-tree.lua',
    'https://github.com/nvim-lualine/lualine.nvim',
    'https://github.com/mg979/vim-visual-multi',
    'https://github.com/rafi/awesome-vim-colorschemes',
    'https://github.com/MeanderingProgrammer/render-markdown.nvim',

    -- Telescope
    'https://github.com/nvim-telescope/telescope-fzf-native.nvim',
    'https://github.com/nvim-telescope/telescope.nvim',

    -- LSP/DAP
    'https://github.com/neovim/nvim-lspconfig',
    'https://github.com/mfussenegger/nvim-dap',
    'https://github.com/soulis-1256/eagle.nvim',
    'https://github.com/yetone/avante.nvim',

    -- Completion
    'https://github.com/hrsh7th/cmp-nvim-lsp',
    'https://github.com/hrsh7th/nvim-cmp',

    -- Java
    'https://github.com/nvim-java/nvim-java',
})

vim.api.nvim_create_user_command('PackUpdate', function() vim.pack.update() end, {})
vim.api.nvim_create_user_command('PackInfo', function() vim.notify(vim.inspect(vim.pack.get())) end, {})

-- Opts
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true
vim.opt.mousemoveevent = true
vim.opt.wildmenu = true
vim.opt.wildmode = {'longest', 'full'}
vim.opt.modeline = true
vim.opt.backspace = {'indent', 'eol', 'start'}
vim.opt.number = true
vim.opt.wrap = false
vim.opt.colorcolumn = {80}
vim.opt.cmdheight = 2
vim.opt.laststatus = 3
vim.opt.showmode = false
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

vim.cmd.colorscheme('jellybeans')

-- Tree
require("nvim-tree").setup({
    renderer = {
        add_trailing = true,
        group_empty = true,
        hidden_display = 'all',
        icons = {
            glyphs = {
                default = ' ',
                modified = '*',
                folder = {
                    default = '+',
                    arrow_closed = '+',
                    arrow_open = '-',
                    open = '-',
                },
                git = {
                    unstaged = '?',
                    staged = '!',
                    unmerged = '?',
                    untracked = '?',
                    renamed = '(renamed)',
                    deleted = '(deleted)',
                    ignored = '(ignored)',
                },
            },
            show = { folder_arrow = false },
        },
    },
    filters = {
        dotfiles = true,
    },
    on_attach = function(buffer)
        local api = require('nvim-tree.api')
        api.map.on_attach.default(buffer)
        vim.keymap.set('n', '?', api.tree.toggle_help, { buffer = buffer })
    end,
})

vim.keymap.set('n', '<F1>', ':NvimTreeToggle<CR>', {})

-- Line
require('lualine').setup({
    options = {
        icons_enabled = false,
        theme = 'jellybeans',
        component_separators = { left = '|', right = '|'},
        section_separators = { left = '', right = ''},
        disabled_filetypes = {
            'NvimTree',
            'Avante',
            'AvanteSelectedFiles',
            'AvanteInput',
            'AvanteTodos',
        },
    },
})

-- Telescope
require('telescope').setup()

vim.api.nvim_create_user_command('Colors', 'Telescope colorscheme', {})
vim.api.nvim_create_user_command('Man', 'Telescope man_pages', {})
vim.api.nvim_create_user_command('Used', 'Telescope lsp_references', {})
vim.api.nvim_create_user_command('Def', 'Telescope lsp_definitions', {})
vim.api.nvim_create_user_command('Files', 'Telescope find_files', {})
vim.api.nvim_create_user_command('Grep', 'Telescope find_string', {})
vim.api.nvim_create_user_command('Buffers', 'Telescope buffers', {})

-- LSP/DAP
require('eagle').setup()

vim.diagnostic.config({
    float = {
        focusable = true,
        style = 'minimal',
        border = 'single',
        source = 'always',
    },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "!!",
            [vim.diagnostic.severity.WARN] = "??",
            [vim.diagnostic.severity.INFO] = "~~",
            [vim.diagnostic.severity.HINT] = "~~",
        },
    },
})

require('render-markdown').setup({
    completions = { lsp = { enabled = true } },
    file_types = {
        'markdown',
        'Avante',
    },
})

require('avante').setup({
    windows = {
        sidebar_header = { enabled = false },
        spinner = {
            editing = { '|', '/', '-', '\\' },
            generating = { '|', '/', '-', '\\' },
            thinking = { '|', '/', '-', '\\' },
        },
    },
    input = {
        provider = 'native',
    },
    --[[
    provider = 'bedrock',
    providers = {
        bedrock = {
            aws_region = 'us-west-2',
            aws_profile = 'avante-bedrock',
        },
    },
    --]]
    provider = 'kiro',
    acp_providers = {
        kiro = {
            command = 'kiro-cli',
            args = { 'acp' },
        },
    },
    behavior = {
        auto_approve_tool_permissions = false,
    },
})
vim.api.nvim_create_user_command('Chat', 'AvanteChat', {})

-- Completion
local cmp = require('cmp')
cmp.setup({
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
    sources = cmp.config.sources(
        {
            { name = 'nvim_lsp' },
        },
        {
            { name = 'buffer' },
        }
    ),
    mapping = cmp.mapping.preset.insert({
        ['<CR>'] = cmp.mapping.confirm({ select = true })
    }),
})

local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Java
require('java').setup({
    jdk = { auto_install = false },
    spring_boot_tools = { enable = false },
})
vim.lsp.config('jdtls', {
    capabilities = capabilities,
    settings = {
        java = {
            configuration = {
                runtimes = {
                    {
                        name = 'JavaSE-21',
                        path = '/usr/lib/jvm/java-21-amazon-corretto',
                        default = true,
                    },
                },
            },
        },
    },
})
vim.lsp.enable('jdtls')

-- TypeScript
vim.lsp.config('ts_ls', {
    capabilities = capabilities,
})
vim.lsp.enable('ts_ls')
