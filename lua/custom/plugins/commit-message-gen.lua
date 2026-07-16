-- AI-assisted commit message generation.
-- Uses antigravity for personal projects and claude for work repos.
-- Triggered by <leader>ai in gitcommit buffers (Neogit, fugitive).

local work_prefix = vim.fn.expand '~' .. '/development/github.com/redmatter'

local function get_agent()
  local cwd = vim.fn.getcwd()
  if cwd:sub(1, #work_prefix) == work_prefix then
    return 'claude'
  end
  return 'antigravity'
end

local function generate_commit_message(bufnr)
  vim.fn.jobstart('git diff --staged', {
    stdout_buffered = true,
    on_stdout = function(_, diff_lines)
      local diff = table.concat(diff_lines, '\n')
      if diff:match '^%s*$' then
        vim.notify('No staged changes — nothing to generate a message from.', vim.log.levels.WARN)
        return
      end

      local agent = get_agent()
      local prompt = 'Write a git commit message for this diff. '
        .. 'Follow conventional commits format: type(scope): description. '
        .. 'Output only the commit message, no explanation.\n\n'
        .. diff

      vim.notify('Generating commit message with ' .. agent .. '...', vim.log.levels.INFO)

      local result = {}
      vim.fn.jobstart({ agent, '--print', prompt }, {
        stdout_buffered = true,
        on_stdout = function(_, lines)
          vim.list_extend(result, lines)
        end,
        on_exit = function(_, code)
          if code ~= 0 then
            vim.notify('Agent exited with code ' .. code, vim.log.levels.ERROR)
            return
          end

          -- Strip markdown code fences if the agent wrapped the message
          local msg = table.concat(result, '\n'):match '^%s*```[^\n]*\n(.-)```%s*$' or table.concat(result, '\n')
          msg = msg:match '^%s*(.-)%s*$' -- trim

          vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(bufnr) then
              return
            end
            local lines_to_insert = vim.split(msg, '\n', { plain = true })
            vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, lines_to_insert)
            vim.api.nvim_win_set_cursor(0, { 1, #lines_to_insert[1] })
            vim.cmd 'echo ""'
          end)
        end,
      })
    end,
  })
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'gitcommit',
  callback = function(ev)
    vim.keymap.set('n', '<leader>ai', function()
      generate_commit_message(ev.buf)
    end, { buffer = ev.buf, desc = '[AI] Generate commit message' })
  end,
})

return {}
