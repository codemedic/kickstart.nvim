-- ---------------------------------------------------------------------------
-- P1FANSI: fansi2 adapted to the p1-sage Ghostty phosphor palette
-- ---------------------------------------------------------------------------
-- Structure by rombrom/fansi2; palette replaced with p1-sage colours.
-- Each palette entry: { cterm_index, gui_hex } — cterm follows terminal
-- colours automatically; gui_hex matches the p1-sage Ghostty definitions.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Utils (verbatim from fansi2)
-- ---------------------------------------------------------------------------
local function reduce(list, reducer, initial)
  local accumulator = initial
  for _, value in ipairs(list) do
    accumulator = reducer(accumulator, value)
  end
  return accumulator
end

local function get_attrs(definition)
  if not definition.attrs then return {} end
  return reduce(definition.attrs, function(attrs, value)
    attrs[value] = true
    return attrs
  end, {})
end

local function get_colors(definition)
  local colors = {}
  if definition.bg then
    colors.ctermbg = definition.bg[1]
    colors.bg = definition.bg[2]
  end
  if definition.fg then
    colors.ctermfg = definition.fg[1]
    colors.fg = definition.fg[2]
  end
  if definition.sp then
    colors.sp = definition.sp[2]
  end
  return colors
end

local function get_group(definition)
  if type(definition) == 'string' then return { link = definition } end
  local attrs = get_attrs(definition)
  local colors = get_colors(definition)
  return vim.tbl_extend('force', attrs, colors)
end

-- ---------------------------------------------------------------------------
-- Palette — p1-sage colours mapped to fansi2 roles
-- ---------------------------------------------------------------------------
local palette = {
  bg           = { 'none', '#040503' }, -- tube black
  fg           = { 'none', '#76A676' }, -- electric sage
  black        = { 0,  '#1A2010' },     -- dark olive-green
  blackLight   = { 8,  '#323D24' },     -- dim warm olive (bright black / comments)
  red          = { 1,  '#D14D4D' },     -- warm red
  redLight     = { 9,  '#FF6E6E' },     -- vivid coral-red
  green        = { 2,  '#22CC22' },     -- active P1 phosphor green
  greenLight   = { 10, '#33FF33' },     -- vivid P1 green
  yellow       = { 3,  '#C9A31E' },     -- vintage amber-gold
  yellowLight  = { 11, '#FFD733' },     -- vivid gold
  blue         = { 4,  '#4D8FD1' },     -- steel blue
  blueLight    = { 12, '#7DBBFF' },     -- vivid sky blue
  magenta      = { 5,  '#B35FB3' },     -- muted orchid
  magentaLight = { 13, '#FF79FF' },     -- vivid pink-magenta
  cyan         = { 6,  '#22AAAA' },     -- teal
  cyanLight    = { 14, '#33FFFF' },     -- vivid aqua
  grey         = { 7,  '#A8C4A8' },     -- sage phosphor (white)
  greyLight    = { 15, '#D8F2D8' },     -- mint flare (bright white)
}

-- ---------------------------------------------------------------------------
-- Definitions (verbatim from fansi2, palette references unchanged)
-- ---------------------------------------------------------------------------
local definitions = {
  -- Reusable groups
  TextBg = { fg = palette.bg },
  TextFg = { fg = palette.fg },
  TextBlack = { fg = palette.black },
  TextBlackLight = { fg = palette.blackLight },
  TextRed = { fg = palette.red },
  TextRedLight = { fg = palette.redLight },
  TextGreen = { fg = palette.green },
  TextGreenLight = { fg = palette.greenLight },
  TextYellow = { fg = palette.yellow },
  TextYellowLight = { fg = palette.yellowLight },
  TextBlue = { fg = palette.blue },
  TextBlueLight = { fg = palette.blueLight },
  TextMagenta = { fg = palette.magenta },
  TextMagentaLight = { fg = palette.magentaLight },
  TextCyan = { fg = palette.cyan },
  TextCyanLight = { fg = palette.cyanLight },
  TextGrey = { fg = palette.grey },
  TextGreyLight = { fg = palette.greyLight },

  -- Normal
  Normal = { fg = palette.fg },

  -- Cursor
  Cursor = { fg = palette.fg, bg = palette.black, attrs = { 'reverse' } },
  iCursor = 'Cursor',
  lCursor = 'Cursor',
  vCursor = 'Cursor',
  MatchParen = { bg = palette.black, attrs = { 'underline' } },

  -- Selection
  Visual = { bg = palette.black, fg = palette.fg },
  VisualNOS = 'Visual',

  -- Errors, warnings, info
  Error = { fg = palette.red, attrs = { 'bold', 'reverse' } },
  Info = { fg = palette.blue, attrs = { 'reverse' } },
  Warning = { fg = palette.yellow, attrs = { 'reverse' } },
  ErrorMsg = { bg = palette.red, attrs = { 'bold' } },
  ModeMsg = { fg = palette.blue, attrs = { 'bold' } },
  MoreMsg = { fg = palette.yellow, attrs = { 'bold' } },
  OkMsg = { fg = palette.green, attrs = { 'bold' } },
  WarningMsg = { fg = palette.redLight, attrs = { 'bold' } },
  Question = { fg = palette.redLight, attrs = { 'bold' } },
  Title = { fg = palette.green, attrs = { 'bold' } },

  -- Menus
  Pmenu = { bg = palette.black },
  PmenuBorder = { fg = palette.blackLight },
  PmenuSel = { fg = palette.blue, attrs = { 'reverse' } },
  PmenuSbar = { fg = palette.grey },
  PmenuThumb = { fg = palette.greyLight },
  QuickFixLine = { fg = palette.blue, attrs = { 'reverse' } },
  WildMenu = 'PmenuSel',

  -- Floating windows
  NormalFloat = { bg = 'none' },

  -- Statusline
  StatusLine = 'StatusLineBackground',
  StatusLineNC = 'StatusLineGrey',
  StatusLineTerm = 'StatusLine',
  StatusLineTermNC = 'StatusLineNC',
  StatusLineBackground = { bg = palette.black },
  StatusLineBlue = { fg = palette.blue, bg = palette.black },
  StatusLineBlueLight = { fg = palette.blueLight, bg = palette.black, attrs = { 'bold' } },
  StatusLineCyan = { fg = palette.cyan, bg = palette.black },
  StatusLineGreen = { fg = palette.green, bg = palette.black },
  StatusLineGrey = { fg = palette.grey, bg = palette.black },
  StatusLineRed = { fg = palette.red, bg = palette.black, attrs = { 'bold' } },
  StatusLineYellow = { fg = palette.yellow, bg = palette.black, attrs = { 'bold' } },

  -- Tabline
  TabLine = { fg = palette.blueLight },
  TabLineFill = { fg = palette.black, attrs = { 'underline' } },
  TabLineSel = { fg = palette.blueLight, attrs = { 'bold', 'reverse' } },

  -- Window dressing
  ColorColumn = { bg = palette.black },
  Conceal = 'TextBlue',
  SpecialKey = 'TextBlackLight',
  NonText = 'TextBlack',
  CursorColumn = 'ColorColumn',
  CursorLine = 'CursorColumn',
  CursorLineNr = 'TextGrey',
  FloatBorder = 'TextBlack',
  Folded = 'TextBlackLight',
  FoldColumn = 'Folded',
  LineNr = 'TextBlackLight',
  LineNrAbove = 'LineNr',
  LineNrBelow = 'LineNr',
  SignColumn = 'TextBlack',
  WinSeparator = 'TextBlack',

  -- Search
  CurSearch = { fg = palette.yellowLight, attrs = { 'reverse' } },
  IncSearch = 'CurSearch',
  Search = { fg = palette.yellow, attrs = { 'reverse' } },
  Substitute = 'Search',

  -- Diffs
  Added = 'TextGreen',
  Changed = 'TextBlue',
  Removed = 'TextRed',
  DiffAdd = 'Added',
  DiffChange = 'Changed',
  DiffDelete = 'Removed',
  DiffText = { fg = palette.blueLight, attrs = { 'reverse' } },
  diffAdded = 'TextGreen',
  diffFile = 'TextYellowLight',
  diffIndexLine = 'TextYellowLight',
  diffLine = 'TextMagentaLight',
  diffRemoved = 'TextRed',
  diffSubname = 'Normal',

  -- Spelling
  SpellBad = { attrs = { 'undercurl' }, sp = palette.red },
  SpellCap = { attrs = { 'undercurl' }, sp = palette.yellow },
  SpellLocal = { attrs = { 'undercurl' }, sp = palette.cyan },
  SpellRare = { attrs = { 'undercurl' }, sp = palette.magenta },

  -- Code
  Boolean = 'TextMagenta',
  Character = 'TextRedLight',
  Conditional = 'TextRed',
  Constant = 'TextGreyLight',
  Debug = 'TextGreenLight',
  Define = 'TextCyan',
  Delimiter = 'TextGrey',
  Directory = 'TextBlue',
  Exception = 'TextRedLight',
  Float = 'TextMagentaLight',
  Function = 'TextYellow',
  Identifier = 'TextFg',
  Ignore = { fg = palette.black },
  Include = 'TextRedLight',
  Keyword = 'TextRed',
  Label = 'TextRed',
  Macro = 'TextCyan',
  Number = 'TextMagentaLight',
  Operator = 'TextGreyLight',
  PreCondit = 'TextCyanLight',
  PreProc = 'TextCyan',
  Repeat = 'TextRedLight',
  Special = 'TextRedLight',
  SpecialChar = 'TextGreenLight',
  Statement = 'TextRed',
  StorageClass = 'TextBlueLight',
  String = 'TextGreen',
  Structure = 'TextCyan',
  Type = 'TextBlue',
  Typedef = 'TextBlue',
  Underlined = { attrs = { 'underline' } },

  -- Comments
  Comment = { fg = palette.blackLight, attrs = { 'italic' } },
  SpecialComment = { fg = palette.fg, attrs = { 'bold', 'italic' } },
  Todo = { fg = palette.fg, attrs = { 'bold', 'italic' } },

  -- LSP diagnostics
  DiagnosticError = 'TextRed',
  DiagnosticSignError = { fg = palette.red, attrs = { 'bold' } },
  DiagnosticUnderlineError = { attrs = { 'undercurl' }, sp = palette.red },
  DiagnosticWarn = 'TextYellow',
  DiagnosticSignWarn = { fg = palette.yellow, attrs = { 'bold' } },
  DiagnosticUnderlineWarn = { attrs = { 'undercurl' }, sp = palette.yellow },
  DiagnosticInfo = 'TextBlue',
  DiagnosticSignInfo = { fg = palette.blue, attrs = { 'bold' } },
  DiagnosticUnderlineInfo = { attrs = { 'undercurl' }, sp = palette.blue },
  DiagnosticHint = 'TextCyan',
  DiagnosticSignHint = { fg = palette.cyan, attrs = { 'bold' } },
  DiagnosticUnderlineHint = { attrs = { 'undercurl' }, sp = palette.cyan },
  DiagnosticFloatingError = 'TextRed',
  DiagnosticFloatingWarn = 'TextYellow',
  DiagnosticFloatingInfo = 'TextBlue',
  DiagnosticFloatingHint = 'TextCyan',
  DiagnosticVirtualTextError = 'TextRed',
  DiagnosticVirtualTextWarn = 'TextYellow',
  DiagnosticVirtualTextInfo = 'TextBlue',
  DiagnosticVirtualTextHint = 'TextCyan',
  LspReferenceRead = { bg = palette.black },
  LspReferenceText = { bg = palette.black },
  LspReferenceWrite = { bg = palette.black },
  LspCodeLens = 'TextGrey',
  LspSignatureActiveParameter = 'CurSearch',

  -- Treesitter
  ['@comment.note'] = 'Todo',
  ['@comment.todo'] = 'Todo',
  ['@comment.warning'] = { fg = palette.yellow, attrs = { 'bold' } },
  ['@error'] = 'Error',
  ['@none'] = { fg = 'none', bg = 'none' },
  ['@punctuation'] = 'Delimiter',
  ['@punctuation.delimiter'] = 'Delimiter',
  ['@punctuation.bracket'] = 'Delimiter',
  ['@punctuation.special'] = 'Delimiter',
  ['@string.regex'] = 'String',
  ['@parameter'] = 'TextYellowLight',
  ['@keyword.exception'] = 'Include',
  ['@keyword.function'] = 'Keyword',
  ['@keyword.import'] = 'Include',
  ['@keyword.operator'] = 'Operator',
  ['@keyword.return'] = 'Statement',
  ['@markup.heading'] = 'Title',
  ['@markup.italic'] = { attrs = { 'italic' } },
  ['@markup.link'] = 'Delimiter',
  ['@markup.link.label'] = { fg = palette.blue, attrs = { 'underline' } },
  ['@markup.link.url'] = 'TextYellowLight',
  ['@markup.quote'] = 'TextCyanLight',
  ['@markup.raw'] = 'Constant',
  ['@markup.strong'] = { attrs = { 'bold' } },
  ['@type.builtin'] = 'TextBlueLight',
  ['@type.qualifier'] = 'TextCyanLight',
  ['@attribute'] = 'PreProc',
  ['@property'] = 'TextCyan',
  ['@variable'] = 'Normal',
  ['@variable.builtin'] = 'TextCyanLight',
  ['@variable.member'] = 'TextCyan',
  ['@variable.parameter'] = 'TextYellowLight',
  ['@symbol'] = 'Identifier',
  ['@text'] = 'TextFg',
  ['@text.strong'] = { attrs = { 'bold' } },
  ['@text.emphasis'] = { attrs = { 'italic' } },
  ['@text.strike'] = { attrs = { 'strikethrough' } },
  ['@text.math'] = 'Special',
  ['@text.environment'] = 'Macro',
  ['@text.environment.name'] = 'Type',
  ['@text.reference'] = 'Constant',
  ['@text.literal'] = 'String',
  ['@text.note'] = 'SpecialComment',
  ['@text.warning'] = 'SpecialComment',
  ['@text.danger'] = 'SpecialComment',
  ['@text.diff.add'] = 'DiffAdd',
  ['@text.diff.delete'] = 'DiffDelete',
  ['@tag'] = 'Function',
  ['@tag.attribute'] = '@property',
  ['@tag.delimiter'] = 'Delimiter',
  ['@diff.plus'] = 'diffAdded',
  ['@diff.minus'] = 'diffRemoved',

  -- Gitsigns
  GitSignsAdd = 'TextGreen',
  GitSignsChange = 'TextYellow',
  GitSignsDelete = 'TextRed',
  GitSignsUntracked = 'TextMagenta',

  -- Fugitive
  fugitiveHash = 'TextYellow',
  fugitiveStagedHeading = 'TextGreen',
  fugitiveStagedModifier = 'TextGreen',
  fugitiveSymbolicRef = { fg = palette.blueLight, attrs = { 'bold' } },
  fugitiveUnstagedHeading = 'TextYellow',
  fugitiveUnstagedModifier = 'TextYellow',
  fugitiveUntrackedHeading = 'TextMagenta',
  fugitiveUntrackedModifier = 'TextMagenta',

  -- fzf-lua
  FzfLuaBorder = 'FloatBorder',

  -- JSON
  jsonKeyword = '@property',
  jsonQuote = 'Delimiter',

  -- netrw
  netrwExe = 'Function',
  netrwLink = 'Underlined',
  netrwSymLink = 'netrwLink',
  netrwTreeBar = 'Delimiter',
}

-- ---------------------------------------------------------------------------
-- Apply
-- ---------------------------------------------------------------------------
vim.g.colors_name = 'p1fansi'
vim.o.background = 'dark'
vim.cmd.hi 'clear'

for _, group in ipairs(vim.fn.getcompletion('@lsp', 'highlight')) do
  vim.api.nvim_set_hl(0, group, {})
end

for name, definition in pairs(definitions) do
  vim.api.nvim_set_hl(0, name, get_group(definition))
end
