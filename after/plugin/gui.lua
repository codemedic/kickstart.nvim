-- GUI / Neovide settings — kept here to avoid merge conflicts with upstream kickstart.nvim.

if vim.fn.has 'gui_running' ~= 1 then return end

vim.g.transparency = 0.95
vim.opt.guifont = {
  'Iosevka Term SS14 Light',
  'Ubuntu Mono',
}

local map = vim.api.nvim_set_keymap

if vim.g.neovide then
  local alpha = function()
    return string.format('%x', math.floor((255 * vim.g.transparency) or 0.8))
  end

  vim.g.neovide_transparency = vim.g.transparency
  vim.g.neovide_background_color = '#0f1117' .. alpha()
  vim.g.neovide_window_blurred = true

  -- Disable various animations
  vim.g.neovide_cursor_animation_length = 0
  vim.g.neovide_scroll_animation_length = 0
  vim.g.neovide_cursor_trail_size = 0
  vim.g.neovide_cursor_animate_in_insert_mode = false

  -- Do keep the fairy dust!
  vim.g.neovide_cursor_vfx_mode = 'pixiedust'
  vim.g.neovide_cursor_vfx_opacity = 300.0

  vim.g.gui_min_scale_factor = 0.4
  vim.g.gui_max_scale_factor = 2.2
  vim.g.gui_default_scale_factor = 0.9
  vim.g.neovide_scale_factor = vim.g.gui_default_scale_factor

  -- Scale UI font
  map('n', '<C-+>', ':lua vim.g.neovide_scale_factor = math.min(vim.g.gui_max_scale_factor, vim.g.neovide_scale_factor + 0.1)<CR>', { silent = true })
  map('n', '<C-->', ':lua vim.g.neovide_scale_factor = math.max(vim.g.gui_min_scale_factor, vim.g.neovide_scale_factor - 0.1)<CR>', { silent = true })
  map('n', '<C-0>', ':lua vim.g.neovide_scale_factor = vim.g.gui_default_scale_factor<CR>', { silent = true })
end

-- Recreate functionality usually provided by the terminal app
map('i', '<S-Insert>',   '<C-r>+', { noremap = true, silent = true })
map('i', '<C-S-Insert>', '<C-r>+', { noremap = true, silent = true })
