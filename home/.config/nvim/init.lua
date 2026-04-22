vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(event)
        local name, kind = event.data.spec.name, event.data.kind
        if kind == 'install' or kind == 'update' then
            if name == 'avante.nvim' then
                vim.system({ 'make', 'BUILD_FROM_SOURCE=true' }, { cwd = event.data.path })
            end
            if name == 'nvim-treesitter' then
                vim.cmd('TSUpdate')
            end
        end
    end
})

vim.pack.add({
    -- Common Lua Libs
    'https://github.com/nvim-lua/plenary.nvim',
    'https://github.com/MunifTanjim/nui.nvim',
    'https://github.com/folke/snacks.nvim',

    -- Colorschemes
    'https://github.com/rafi/awesome-vim-colorschemes',
    'https://github.com/rktjmp/lush.nvim',
    'https://github.com/zenbones-theme/zenbones.nvim',

    -- QoL
    'https://github.com/nvim-tree/nvim-tree.lua',
    'https://github.com/nvim-lualine/lualine.nvim',
    'https://github.com/mg979/vim-visual-multi',
    'https://github.com/lewis6991/gitsigns.nvim',
    'https://github.com/ntpeters/vim-better-whitespace',

    -- Telescope
    'https://github.com/nvim-telescope/telescope-fzf-native.nvim',
    'https://github.com/nvim-telescope/telescope.nvim',

    -- LSP/DAP
    'https://github.com/neovim/nvim-lspconfig',
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/mfussenegger/nvim-dap',
    'https://github.com/soulis-1256/eagle.nvim',
    'https://github.com/yetone/avante.nvim',
    'https://github.com/github/copilot.vim',

    -- Completion
    'https://github.com/hrsh7th/cmp-nvim-lsp',
    'https://github.com/hrsh7th/cmp-buffer',
    'https://github.com/hrsh7th/cmp-path',
    'https://github.com/hrsh7th/cmp-cmdline',
    'https://github.com/hrsh7th/nvim-cmp',

    -- Java
    'https://github.com/nvim-java/nvim-java',
})

vim.api.nvim_create_user_command('PackUpdate', function() vim.pack.update() end, {})
vim.api.nvim_create_user_command('PackInfo', function()
    local packs = vim.inspect(vim.pack.get())
    vim.cmd('vnew')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(packs, '\n', true))
end, {})

-- Opts
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.clipboard = 'unnamedplus'
vim.opt.termguicolors = true
vim.opt.mousemoveevent = true
vim.opt.wildmenu = true
vim.opt.wildmode = {'longest', 'full'}
vim.opt.modeline = true
vim.opt.backspace = {'indent', 'eol', 'start'}
vim.opt.number = true
vim.opt.wrap = false
vim.opt.colorcolumn = {80, 120}
vim.opt.cmdheight = 2
vim.opt.laststatus = 3
vim.opt.showmode = false
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.lazyredraw = true

vim.cmd.colorscheme('jellybeans')

-- Snacks
require('snacks').setup()

-- Tree
require('nvim-tree').setup({
    renderer = {
        add_trailing = true,
        group_empty = true,
        hidden_display = 'simple',
        highlight_opened_files = 'all',
        icons = {
            symlink_arrow = '->',
            glyphs = {
                default = ' ',
                symlink = ' ',
                bookmark = '!',
                modified = '*',
                hidden = '.',
                folder = {
                    default = '+',
                    arrow_closed = '+',
                    arrow_open = '-',
                    open = '-',
                    empty = '+',
                    empty_open = '-',
                    symlink = '+',
                    symlink_open = '-',
                },
                git = {
                    unstaged = '*',
                    staged = '!',
                    unmerged = '?',
                    untracked = '?',
                    renamed = 'renamed',
                    deleted = 'deleted',
                    ignored = 'ignored',
                },
            },
            show = {
                folder_arrow = false,
            },
            git_placement = "after",
        },
    },
    filters = {
        dotfiles = true,
        git_ignored = true,
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
    },
})

-- Telescope
require('telescope').setup()

vim.api.nvim_create_user_command('Colors', 'Telescope colorscheme', {})
vim.api.nvim_create_user_command('Man', 'Telescope man_pages', {})
vim.api.nvim_create_user_command('Used', 'Telescope lsp_references', {})
vim.api.nvim_create_user_command('Def', 'Telescope lsp_definitions', {})
vim.api.nvim_create_user_command('Files', 'Telescope find_files', {})
vim.api.nvim_create_user_command('Ag', 'Telescope live_grep', {})
vim.api.nvim_create_user_command('Buffers', 'Telescope buffers', {})

-- LSP/DAP
require('eagle').setup()

local ts = require('nvim-treesitter')
ts.setup()
ts.install({
    'yaml', 'java', 'rust', 'typescript', 'c',
})

vim.diagnostic.config({
    float = {
        focusable = true,
        style = 'minimal',
        border = 'single',
        source = 'always',
    },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = '!!',
            [vim.diagnostic.severity.WARN] = '??',
            [vim.diagnostic.severity.INFO] = '>>',
            [vim.diagnostic.severity.HINT] = '>>',
        },
    },
})

vim.api.nvim_create_autocmd('BufWritePre', {
    callback = function(event)
        local bufnr = event.buf
	    local filetype = vim.bo[bufnr].filetype
        if filetype == 'java' then
            return
        end
        local clients = vim.lsp.get_clients({
            bufnr = bufnr,
            effective_capabilities = { documentFormattingProvider = true },
        })
        if #clients > 0 then
          vim.lsp.buf.format({ bufnr = bufnr, async = false })
        end
    end
})

vim.api.nvim_create_user_command('Rename', function() vim.lsp.buf.rename() end, {})
vim.api.nvim_create_user_command('Format', function() vim.lsp.buf.format() end, {})
vim.api.nvim_create_user_command('Doc', function() vim.lsp.buf.hover() end, {})

require('avante').setup({
    behaviour = {
        auto_approve_tool_permissions = true,
        confirmation_ui_style = 'popup',
    },
    mode = 'legacy',
    provider = 'kiro',
    acp_providers = {
        kiro = {
            command = 'kiro-cli',
            args = { 'acp' },
            env = {
                HOME = vim.fn.getenv('HOME'),
            },
        },
    },
    windows = {
        sidebar_header = { rounded = false },
        spinner = {
            editing = { '|', '/', '-', '\\' },
            generating = { '|', '/', '-', '\\' },
            thinking = { '|', '/', '-', '\\' },
        },
    },
    selector = {
        provider = 'telescope',
    },
    input = {
        provider = 'snacks',
    },
})
vim.api.nvim_create_user_command('Chat', 'AvanteChat', {})
vim.api.nvim_create_user_command('ChatStop', 'AvanteStop', {})
vim.api.nvim_create_user_command('ChatHistory', 'AvanteHistory', {})

-- Copilot
vim.g.copilot_enabled = false
vim.g.copilot_no_tab_map = true
vim.keymap.set('i', '<F11>', 'copilot#AcceptWord("")', {
    expr = true,
    replace_keycodes = false,
})
vim.keymap.set('i', '<F12>', 'copilot#Accept("")', {
    expr = true,
    replace_keycodes = false,
})

-- Completion
local cmp = require('cmp')
cmp.setup({
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
        ['<CR>'] = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace }),
    }),
    sources = cmp.config.sources(
        {
            { name = 'nvim_lsp' },
        },
        {
            { name = 'buffer' },
        }
    ),
})
cmp.setup.cmdline(':', {
    matching = { disallow_symbol_nonprefix_matching = false },
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources(
        {
            { name = 'path' },
        },
        {
            { name = 'cmdline' },
        }
    ),
})
cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = { { name = 'buffer' } },
})

local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Java
require('java').setup({
    jdk = {
        auto_install = false,
    },
    spring_boot_tools = { enable = false },
})
vim.lsp.config('jdtls', {
    capabilities = capabilities,
    cmd_env = {
        JAVA_HOME = '/usr/lib/jvm/java-21-amazon-corretto',
        PATH = '/usr/lib/jvm/java-21-amazon-corretto/bin:' .. vim.fn.getenv('PATH'),
    },
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

-- C/C++
vim.lsp.config('clangd', {
    capabilities = capabilities,
})
vim.lsp.enable('clangd')

-- Rust
vim.lsp.config('rust_analyzer', {
    capabilities = capabilities
})
vim.lsp.enable('rust_analyzer')
