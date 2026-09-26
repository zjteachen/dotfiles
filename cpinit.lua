```lua
-- ~/.config/nvim/init.lua

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

-- UI / editing
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.scrolloff = 4
opt.sidescrolloff = 4
opt.wrap = false
opt.termguicolors = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

-- Indentation
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true

-- Files / undo
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.autowrite = true

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Faster interaction
opt.updatetime = 200
opt.timeoutlen = 300

-- Completion behavior
opt.completeopt = { "menu", "menuone", "noselect" }

-- Useful keymaps
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>")
vim.keymap.set("n", "<leader>q", "<cmd>q<CR>")

-- Move selected lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Keep cursor centered
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- C / C++
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "cpp", "c" },
    callback = function()
        vim.opt_local.shiftwidth = 4
        vim.opt_local.tabstop = 4
        vim.opt_local.commentstring = "// %s"
    end,
})

-- Python
vim.api.nvim_create_autocmd("FileType", {
    pattern = "python",
    callback = function()
        vim.opt_local.shiftwidth = 4
        vim.opt_local.tabstop = 4
    end,
})

-- <leader>r = compile + run
vim.keymap.set("n", "<leader>r", function()
    vim.cmd("write")

    if vim.bo.filetype == "cpp" then
        local src = vim.fn.shellescape(vim.fn.expand("%"))
        local out = vim.fn.shellescape(vim.fn.expand("%:r"))

        vim.cmd(
            "split | terminal g++ -std=c++20 -O2 -Wall -Wextra "
            .. src .. " -o " .. out
            .. " && " .. out
        )

    elseif vim.bo.filetype == "c" then
        local src = vim.fn.shellescape(vim.fn.expand("%"))
        local out = vim.fn.shellescape(vim.fn.expand("%:r"))

        vim.cmd(
            "split | terminal gcc -std=c17 -O2 -Wall -Wextra "
            .. src .. " -o " .. out
            .. " && " .. out
        )

    elseif vim.bo.filetype == "python" then
        local src = vim.fn.shellescape(vim.fn.expand("%"))
        vim.cmd("split | terminal python3 " .. src)
    end
end)

-- <leader>i = compile/run using input.txt
vim.keymap.set("n", "<leader>i", function()
    vim.cmd("write")

    if vim.bo.filetype == "cpp" then
        local src = vim.fn.shellescape(vim.fn.expand("%"))
        local out = vim.fn.shellescape(vim.fn.expand("%:r"))

        vim.cmd(
            "split | terminal g++ -std=c++20 -O2 -Wall -Wextra "
            .. src .. " -o " .. out
            .. " && " .. out .. " < input.txt"
        )

    elseif vim.bo.filetype == "python" then
        local src = vim.fn.shellescape(vim.fn.expand("%"))
        vim.cmd("split | terminal python3 " .. src .. " < input.txt")
    end
end)

-- Quick terminal
vim.keymap.set("n", "<leader>t", "<cmd>split | terminal<CR>")

-- Leave terminal mode with Esc Esc
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>")
```

For Caps → Esc on X11:

```bash
setxkbmap -option caps:escape
```
