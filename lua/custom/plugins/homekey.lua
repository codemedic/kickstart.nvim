-- Home key to behave like popular IDEs
return {
  'bwpge/homekey.nvim',
  event = 'VeryLazy',
  opts = {
    -- set keymaps for <Home> and <C-Home> when `require("homekey").setup` is called
    set_keymaps = true,
    -- do not use plugin behavior on these filetypes;
    -- can be exact filetype or lua pattern
    exclude_filetypes = {
      'neo-tree',
      'NvimTree',
    },
  },
}
