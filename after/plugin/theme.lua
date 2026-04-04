require('modus-themes').setup {
  style = 'modus_vivendi',
  styles = {
    comments = { italic = true },
  },
}

vim.cmd.colorscheme 'modus_vivendi'

-- Dim line number gutter text
vim.api.nvim_set_hl(0, 'LineNr', { fg = '#555555' })
vim.api.nvim_set_hl(0, 'LineNrAbove', { fg = '#555555' })
vim.api.nvim_set_hl(0, 'LineNrBelow', { fg = '#555555' })
