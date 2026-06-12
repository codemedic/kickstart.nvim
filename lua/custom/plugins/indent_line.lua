-- Override kickstart indent-blankline: lighter dashed character + dimmed colour
return {
  'lukas-reineke/indent-blankline.nvim',
  opts = {
    indent = {
      char = '┊',
      tab_char = '┊',
      highlight = 'IblIndentDim',
    },
  },
  init = function()
    vim.api.nvim_set_hl(0, 'IblIndentDim', { fg = '#3a3a3a', nocombine = true })
  end,
}
