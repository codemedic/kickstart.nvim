return {
  'rachartier/tiny-inline-diagnostic.nvim',
  event    = 'VeryLazy',
  priority = 1000,
  config   = function()
    require('tiny-inline-diagnostic').setup {
      options = {
        -- go-updates messages are "level update: mod/path → vX.Y.Z".
        -- The module is already visible on the line itself, so strip it for
        -- inline display. Trouble reads the full message for context.
        format = function(diagnostic)
          if diagnostic.source == 'go-updates' then
            local level, version = diagnostic.message:match '^(%a+ update): %S+ → (%S+)'
            if level and version then return level .. ': ' .. version end
          end
          return diagnostic.message
        end,
      },
    }
  end,
}
