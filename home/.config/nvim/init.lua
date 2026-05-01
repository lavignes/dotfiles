vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(event)
        local name, kind = event.data.spec.name, event.data.kind
        if kind == 'install' or kind == 'update' then
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
    'https://github.com/github/copilot.vim',
    'https://github.com/carlos-algms/agentic.nvim',

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
vim.api.nvim_create_user_command('PackClean', function()
    local inactive = vim.iter(vim.pack.get())
        :filter(function(p) return not p.active end)
        :map(function(p) return p.spec.name end)
        :totable()
    if #inactive == 0 then
        vim.notify('PackClean: nothing to remove')
        return
    end
    vim.pack.del(inactive)
    vim.notify('PackClean: removed ' .. table.concat(inactive, ', '))
end, {})
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
vim.opt.wildmode = { 'longest', 'full' }
vim.opt.modeline = true
vim.opt.backspace = { 'indent', 'eol', 'start' }
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
vim.opt.splitright = true

vim.cmd.colorscheme('jellybeans')

-- Snacks
require('snacks').setup({
    picker = {
        ui_select = true,
        layout = { preset = 'select', layout = { width = 0.8 } },
    },
})

-- Tree
require('nvim-tree').setup({
    renderer = {
        add_trailing = true,
        group_empty = true,
        hidden_display = 'all',
        icons = {
            symlink_arrow = '->',
            glyphs = {
                default = ' ',
                modified = '*',
                folder = {
                    default = '+',
                    arrow_closed = '+',
                    arrow_open = '-',
                    open = '-',
                    empty = '+',
                    empty_open = '-',
                },
                git = {
                    unstaged = '?',
                    staged = '!',
                    unmerged = '?',
                    untracked = '?',
                    renamed = 'renamed',
                    deleted = 'deleted',
                    ignored = 'ignored',
                },
            },
            show = { folder_arrow = false },
        },
    },
    filters = {
        dotfiles = true,
        git_ignored = false,
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
        if filetype == 'java' or filetype == 'typescript' then
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

-- Agentic
local agentic_provider = vim.fn.executable('copilot') == 1 and 'copilotacp' or 'kiro-cli'

local agentic = require('agentic')
agentic.setup({
    provider = agentic_provider,
    acp_providers = {
        ['kiro-cli'] = {
            name = 'Kiro',
            command = vim.fn.expand('~/bin/kiro-acp-proxy'),
            args = { '--trust-all-tools' },
            env = {
                HOME = vim.fn.getenv('HOME'),
            },
        },
        ['copilotacp'] = {
            command = 'copilot',
            args = { '--acp', '--allow-all-tools' },
            env = {
                HOME = vim.fn.getenv('HOME'),
                COPILOT_GITHUB_TOKEN = vim.fn.getenv('COPILOT_GITHUB_TOKEN'),
            },
            auth_method = 'copilot-login',
        }
    },
    windows = {
        width = '30%',
    },
    headers = {
        chat = { title = 'Chat' },
        todos = { title = 'Todos' },
        code = { title = 'Code' },
        files = { title = 'Files' },
        input = { title = 'Input' },
        diagnostics = { title = 'Diagnostics' },
    },
    spinner_chars = {
        generating = { '/', '-', '\\', '|' },
        thinking = { '/', '-', '\\', '|' },
        searching = { '   ', '.  ', '.. ', '...' },
        busy = { '   ', '.  ', '.. ', '...' },
    },
    diagnostic_icons = {
        error = '!!',
        warn = '??',
        info = '>>',
        hint = '>>',
    },
    status_icons = {
        pending = ':|',
        in_progress = ':P',
        completed = ':D',
        failed = ':(',
    },
    chat_icons = {
        user = '[user]',
        agent = '[agent]',
    },
    message_icons = {
        thinking = '[thinking]',
        finished = '[finished]',
        stopped = '[stopped]',
        error = '[error]',
    },
})

-- Force-replace spinner arrays; deep_merge_into merges by index so shorter
-- user arrays leave leftover default braille chars at higher indices.
local agentic_config = require('agentic.config')
agentic_config.spinner_chars.generating = { '/', '-', '\\', '|' }
agentic_config.spinner_chars.busy = { '   ', '.  ', '.. ', '...' }

vim.api.nvim_create_user_command('Chat', function() agentic.toggle() end, {})
vim.api.nvim_create_user_command('ChatStop', function() agentic.stop_generation() end, {})
vim.api.nvim_create_user_command('ChatRestore', function() agentic.restore_session() end, {})

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

-- DAP
local dap = require('dap')
dap.adapters.java_dbg = function(callback)
    local clients = vim.lsp.get_clients({ name = 'jdtls' })
    if #clients == 0 then
        vim.notify('jdtls not running', vim.log.levels.ERROR)
        return
    end
    clients[1]:exec_cmd(
        { command = 'vscode.java.startDebugSession' },
        { bufnr = 0 },
        function(err, port)
            if err then
                vim.notify('Debug session failed: ' .. tostring(err), vim.log.levels.ERROR)
                return
            end
            callback({ type = 'server', host = '127.0.0.1', port = port })
        end
    )
end
dap.configurations.java = {
    {
        type = 'java_dbg',
        request = 'attach',
        name = 'Attach to localhost:9005',
        hostName = '127.0.0.1',
        port = 9005,
    },
}
vim.api.nvim_set_hl(0, 'DapStoppedLine', { bg = '#3a3a00' })
vim.fn.sign_define('DapStopped', { text = '→', texthl = 'DapStopped', linehl = 'DapStoppedLine' })

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
