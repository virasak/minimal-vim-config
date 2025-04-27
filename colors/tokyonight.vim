vim9script
# -----------------------------------------------------------------------------
# Name:         Tokyo Night
# Description:  A clean, dark Vim theme that celebrates the lights of downtown Tokyo at night (Based on the VS Code version of the theme)
# Author:       Ghifari Taqiuddin <mghifarit53@gmail.com>
# Website:      https://github.com/ghifarit53/tokyonight.vim/
# License:      MIT
# -----------------------------------------------------------------------------

# Initialization: {{{
highlight clear
if exists('syntax_on')
  syntax reset
endif
set background=dark

var t_Co = exists('&t_Co') && !empty(&t_Co) && str2nr(&t_Co) > 1 ? str2nr(&t_Co) : 2
var tmux = executable('tmux') && $TMUX !=# ''

g:colors_name = 'tokyonight'
# }}}
# Configuration: {{{
var configuration = {}
configuration.style = get(g:, 'tokyonight_style', 'night')
configuration.transparent_background = get(g:, 'tokyonight_transparent_background', 0)
configuration.menu_selection_background = get(g:, 'tokyonight_menu_selection_background', 'green')
configuration.disable_italic_comment = get(g:, 'tokyonight_disable_italic_comment', 0)
configuration.enable_italic = get(g:, 'tokyonight_enable_italic', 0)
configuration.cursor = get(g:, 'tokyonight_cursor', 'auto')
configuration.current_word = get(g:, 'tokyonight_current_word', get(g:, 'tokyonight_transparent_background', 0) == 0 ? 'grey background' : 'bold')
# }}}
# Palette: {{{
#
var palette = {}
if configuration.style ==# 'night'
  palette = {
        'black':      ['#06080a',   '237',  'DarkGrey'],
        'bg0':        ['#1a1b26',   '235',  'Black'],
        'bg1':        ['#232433',   '236',  'DarkGrey'],
        'bg2':        ['#2a2b3d',   '236',  'DarkGrey'],
        'bg3':        ['#32344a',   '237',  'DarkGrey'],
        'bg4':        ['#3b3d57',   '237',  'Grey'],
        'bg_red':     ['#ff7a93',   '203',  'Red'],
        'diff_red':   ['#803d49',   '52',   'DarkRed'],
        'bg_green':   ['#b9f27c',   '107',  'Green'],
        'diff_green': ['#618041',   '22',   'DarkGreen'],
        'bg_blue':    ['#7da6ff',   '110',  'Blue'],
        'diff_blue':  ['#3e5380',   '17',   'DarkBlue'],
        'fg':         ['#a9b1d6',   '250',  'White'],
        'red':        ['#F7768E',   '203',  'Red'],
        'orange':     ['#FF9E64',   '215',  'Orange'],
        'yellow':     ['#E0AF68',   '179',  'Yellow'],
        'green':      ['#9ECE6A',   '107',  'Green'],
        'blue':       ['#7AA2F7',   '110',  'Blue'],
        'purple':     ['#ad8ee6',   '176',  'Magenta'],
        'grey':       ['#444B6A',   '246',  'LightGrey'],
        'none':       ['NONE',      'NONE', 'NONE']
        }
elseif configuration.style ==# 'storm'
  palette = {
        'black':      ['#06080a',   '237',  'DarkGrey'],
        'bg0':        ['#24283b',   '235',  'Black'],
        'bg1':        ['#282d42',   '236',  'DarkGrey'],
        'bg2':        ['#2f344d',   '236',  'DarkGrey'],
        'bg3':        ['#333954',   '237',  'DarkGrey'],
        'bg4':        ['#3a405e',   '237',  'Grey'],
        'bg_red':     ['#ff7a93',   '203',  'Red'],
        'diff_red':   ['#803d49',   '52',   'DarkRed'],
        'bg_green':   ['#b9f27c',   '107',  'Green'],
        'diff_green': ['#618041',   '22',   'DarkGreen'],
        'bg_blue':    ['#7da6ff',   '110',  'Blue'],
        'diff_blue':  ['#3e5380',   '17',   'DarkBlue'],
        'fg':         ['#a9b1d6',   '250',  'White'],
        'red':        ['#F7768E',   '203',  'Red'],
        'orange':     ['#FF9E64',   '215',  'Orange'],
        'yellow':     ['#E0AF68',   '179',  'Yellow'],
        'green':      ['#9ECE6A',   '107',  'Green'],
        'blue':       ['#7AA2F7',   '110',  'Blue'],
        'purple':     ['#ad8ee6',   '176',  'Magenta'],
        'grey':       ['#444B6A',   '246',  'LightGrey'],
        'none':       ['NONE',      'NONE', 'NONE']
        }
endif

# }}}
# Function: {{{
# HL(group, foreground, background)
# HL(group, foreground, background, gui, guisp)
#
# E.g.:
# HL('Normal', palette.fg, palette.bg0)

if (has('termguicolors') && &termguicolors) || has('gui_running')  # guifg guibg gui cterm guisp
  def HL(group: string, fg: list<string>, bg: list<string>, ...args: list<any>): void
    var hl_string = [
          'highlight', group,
          'guifg=' .. fg[0],
          'guibg=' .. bg[0],
          ]
    if args->len() >= 1
      if args[0] ==# 'undercurl'
        if !tmux
          hl_string->add('gui=undercurl')
        else
          hl_string->add('gui=underline')
        endif
        hl_string->add('cterm=underline')
      else
        hl_string->add('gui=' .. args[0])
        hl_string->add('cterm=' .. args[0])
      endif
    else
      hl_string->add('gui=NONE')
      hl_string->add('cterm=NONE')
    endif
    if args->len() >= 2
      hl_string->add('guisp=' .. args[1][0])
    endif
    execute join(hl_string, ' ')
  enddef
elseif t_Co >= 256  # ctermfg ctermbg cterm
  def HL(group: string, fg: list<string>, bg: list<string>, ...args: list<any>): void
    var hl_string = [
          'highlight', group,
          'ctermfg=' .. fg[1],
          'ctermbg=' .. bg[1],
          ]
    if args->len() >= 1
      if args[0] ==# 'undercurl'
        hl_string->add('cterm=underline')
      else
        hl_string->add('cterm=' .. args[0])
      endif
    else
      hl_string->add('cterm=NONE')
    endif
    execute join(hl_string, ' ')
  enddef
else  # ctermfg ctermbg cterm
  def HL(group: string, fg: list<string>, bg: list<string>, ...args: list<any>): void
    var hl_string = [
          'highlight', group,
          'ctermfg=' .. fg[2],
          'ctermbg=' .. bg[2],
          ]
    if args->len() >= 1
      if args[0] ==# 'undercurl'
        hl_string->add('cterm=underline')
      else
        hl_string->add('cterm=' .. args[0])
      endif
    else
      hl_string->add('cterm=NONE')
    endif
    execute join(hl_string, ' ')
  enddef
endif
# }}}

# Common Highlight Groups: {{{
# UI: {{{
if configuration.transparent_background
  HL('Normal', palette.fg, palette.none)
  HL('Terminal', palette.fg, palette.none)
  HL('EndOfBuffer', palette.bg0, palette.none)
  HL('FoldColumn', palette.grey, palette.none)
  HL('Folded', palette.grey, palette.none)
  HL('SignColumn', palette.fg, palette.none)
  HL('ToolbarLine', palette.fg, palette.none)
else
  HL('Normal', palette.fg, palette.bg0)
  HL('Terminal', palette.fg, palette.bg0)
  HL('EndOfBuffer', palette.bg0, palette.bg0)
  HL('FoldColumn', palette.grey, palette.bg1)
  HL('Folded', palette.grey, palette.bg1)
  HL('SignColumn', palette.fg, palette.bg1)
  HL('ToolbarLine', palette.fg, palette.bg2)
endif
HL('ColorColumn', palette.none, palette.bg1)
HL('Conceal', palette.grey, palette.none)
if configuration.cursor ==# 'auto'
  HL('Cursor', palette.none, palette.none, 'reverse')
elseif configuration.cursor ==# 'red'
  HL('Cursor', palette.bg0, palette.red)
elseif configuration.cursor ==# 'green'
  HL('Cursor', palette.bg0, palette.green)
elseif configuration.cursor ==# 'blue'
  HL('Cursor', palette.bg0, palette.blue)
endif
highlight! link vCursor Cursor
highlight! link iCursor Cursor
highlight! link lCursor Cursor
highlight! link CursorIM Cursor
HL('CursorColumn', palette.none, palette.bg1)
HL('CursorLine', palette.none, palette.bg1)
HL('LineNr', palette.grey, palette.none)
if &relativenumber && !&cursorline
  HL('CursorLineNr', palette.fg, palette.none)
else
  HL('CursorLineNr', palette.fg, palette.bg1)
endif
HL('DiffAdd', palette.none, palette.diff_green)
HL('DiffChange', palette.none, palette.diff_blue)
HL('DiffDelete', palette.none, palette.diff_red)
HL('DiffText', palette.none, palette.none, 'reverse')
HL('Directory', palette.green, palette.none)
HL('ErrorMsg', palette.red, palette.none, 'bold,underline')
HL('WarningMsg', palette.yellow, palette.none, 'bold')
HL('ModeMsg', palette.fg, palette.none, 'bold')
HL('MoreMsg', palette.blue, palette.none, 'bold')
HL('IncSearch', palette.bg0, palette.bg_red)
HL('Search', palette.bg0, palette.bg_green)
HL('MatchParen', palette.none, palette.bg4)
HL('NonText', palette.bg4, palette.none)
HL('Whitespace', palette.bg4, palette.none)
HL('SpecialKey', palette.bg4, palette.none)
HL('Pmenu', palette.fg, palette.bg2)
HL('PmenuSbar', palette.none, palette.bg2)
if configuration.menu_selection_background ==# 'blue'
  HL('PmenuSel', palette.bg0, palette.bg_blue)
  HL('WildMenu', palette.bg0, palette.bg_blue)
elseif configuration.menu_selection_background ==# 'green'
  HL('PmenuSel', palette.bg0, palette.bg_green)
  HL('WildMenu', palette.bg0, palette.bg_green)
elseif configuration.menu_selection_background ==# 'red'
  HL('PmenuSel', palette.bg0, palette.bg_red)
  HL('WildMenu', palette.bg0, palette.bg_red)
endif
HL('PmenuThumb', palette.none, palette.grey)
HL('Question', palette.yellow, palette.none)
HL('SpellBad', palette.red, palette.none, 'undercurl', palette.red)
HL('SpellCap', palette.yellow, palette.none, 'undercurl', palette.yellow)
HL('SpellLocal', palette.blue, palette.none, 'undercurl', palette.blue)
HL('SpellRare', palette.purple, palette.none, 'undercurl', palette.purple)
HL('StatusLine', palette.fg, palette.bg3)
HL('StatusLineTerm', palette.fg, palette.bg3)
HL('StatusLineNC', palette.grey, palette.bg1)
HL('StatusLineTermNC', palette.grey, palette.bg1)
HL('TabLine', palette.fg, palette.bg4)
HL('TabLineFill', palette.grey, palette.bg1)
HL('TabLineSel', palette.bg0, palette.bg_red)
HL('VertSplit', palette.black, palette.none)
HL('Visual', palette.none, palette.bg3)
HL('VisualNOS', palette.none, palette.bg3, 'underline')
HL('QuickFixLine', palette.blue, palette.none, 'bold')
HL('Debug', palette.yellow, palette.none)
HL('debugPC', palette.bg0, palette.green)
HL('debugBreakpoint', palette.bg0, palette.red)
HL('ToolbarButton', palette.bg0, palette.bg_blue)
if has('nvim')
  highlight! link healthError Red
  highlight! link healthSuccess Green
  highlight! link healthWarning Yellow
  highlight! link LspDiagnosticsError Grey
  highlight! link LspDiagnosticsWarning Grey
  highlight! link LspDiagnosticsInformation Grey
  highlight! link LspDiagnosticsHint Grey
  highlight! link LspReferenceText CocHighlightText
  highlight! link LspReferenceRead CocHighlightText
  highlight! link LspReferenceWrite CocHighlightText
endif
#
# }}}
# Syntax: {{{
if configuration.enable_italic
  HL('Type', palette.blue, palette.none, 'italic')
  HL('Structure', palette.blue, palette.none, 'italic')
  HL('StorageClass', palette.blue, palette.none, 'italic')
  HL('Identifier', palette.orange, palette.none, 'italic')
  HL('Constant', palette.orange, palette.none, 'italic')
else
  HL('Type', palette.blue, palette.none)
  HL('Structure', palette.blue, palette.none)
  HL('StorageClass', palette.blue, palette.none)
  HL('Identifier', palette.orange, palette.none)
  HL('Constant', palette.orange, palette.none)
endif
HL('PreProc', palette.red, palette.none)
HL('PreCondit', palette.red, palette.none)
HL('Include', palette.red, palette.none)
HL('Keyword', palette.red, palette.none)
HL('Define', palette.red, palette.none)
HL('Typedef', palette.red, palette.none)
HL('Exception', palette.red, palette.none)
HL('Conditional', palette.red, palette.none)
HL('Repeat', palette.red, palette.none)
HL('Statement', palette.red, palette.none)
HL('Macro', palette.purple, palette.none)
HL('Error', palette.red, palette.none)
HL('Label', palette.purple, palette.none)
HL('Special', palette.purple, palette.none)
HL('SpecialChar', palette.purple, palette.none)
HL('Boolean', palette.purple, palette.none)
HL('String', palette.yellow, palette.none)
HL('Character', palette.yellow, palette.none)
HL('Number', palette.purple, palette.none)
HL('Float', palette.purple, palette.none)
HL('Function', palette.green, palette.none)
HL('Operator', palette.red, palette.none)
HL('Title', palette.red, palette.none, 'bold')
HL('Tag', palette.orange, palette.none)
HL('Delimiter', palette.fg, palette.none)
if configuration.disable_italic_comment
  HL('Comment', palette.grey, palette.none)
  HL('SpecialComment', palette.grey, palette.none)
  HL('Todo', palette.blue, palette.none)
else
  HL('Comment', palette.grey, palette.none, 'italic')
  HL('SpecialComment', palette.grey, palette.none, 'italic')
  HL('Todo', palette.blue, palette.none, 'italic')
endif
HL('Ignore', palette.grey, palette.none)
HL('Underlined', palette.none, palette.none, 'underline')
# }}}
# Predefined Highlight Groups: {{{
HL('Fg', palette.fg, palette.none)
HL('Grey', palette.grey, palette.none)
HL('Red', palette.red, palette.none)
HL('Orange', palette.orange, palette.none)
HL('Yellow', palette.yellow, palette.none)
HL('Green', palette.green, palette.none)
HL('Blue', palette.blue, palette.none)
HL('Purple', palette.purple, palette.none)
if configuration.enable_italic
  HL('RedItalic', palette.red, palette.none, 'italic')
  HL('BlueItalic', palette.blue, palette.none, 'italic')
  HL('OrangeItalic', palette.orange, palette.none, 'italic')
else
  HL('RedItalic', palette.red, palette.none)
  HL('BlueItalic', palette.blue, palette.none)
  HL('OrangeItalic', palette.orange, palette.none)
endif
# }}}
#
# }}}
# Extended File Types: {{{
# Markdown: {{{
# builtin: {{{
HL('markdownH1', palette.red, palette.none, 'bold')
HL('markdownH2', palette.orange, palette.none, 'bold')
HL('markdownH3', palette.yellow, palette.none, 'bold')
HL('markdownH4', palette.green, palette.none, 'bold')
HL('markdownH5', palette.blue, palette.none, 'bold')
HL('markdownH6', palette.purple, palette.none, 'bold')
HL('markdownUrl', palette.blue, palette.none, 'underline')
HL('markdownItalic', palette.none, palette.none, 'italic')
HL('markdownBold', palette.none, palette.none, 'bold')
HL('markdownItalicDelimiter', palette.grey, palette.none, 'italic')
highlight! link markdownCode Green
highlight! link markdownCodeBlock Green
highlight! link markdownCodeDelimiter Green
highlight! link markdownBlockquote Grey
highlight! link markdownListMarker Red
highlight! link markdownOrderedListMarker Red
highlight! link markdownRule Purple
highlight! link markdownHeadingRule Grey
highlight! link markdownUrlDelimiter Grey
highlight! link markdownLinkDelimiter Grey
highlight! link markdownLinkTextDelimiter Grey
highlight! link markdownHeadingDelimiter Grey
highlight! link markdownLinkText Red
highlight! link markdownUrlTitleDelimiter Green
highlight! link markdownIdDeclaration markdownLinkText
highlight! link markdownBoldDelimiter Grey
highlight! link markdownId Yellow
# }}}
# vim-markdown: https://github.com/gabrielelana/vim-markdown{{{
HL('mkdURL', palette.blue, palette.none, 'underline')
HL('mkdInlineURL', palette.blue, palette.none, 'underline')
HL('mkdItalic', palette.grey, palette.none, 'italic')
highlight! link mkdCodeDelimiter Green
highlight! link mkdBold Grey
highlight! link mkdLink Red
highlight! link mkdHeading Grey
highlight! link mkdListItem Red
highlight! link mkdRule Purple
highlight! link mkdDelimiter Grey
highlight! link mkdId Yellow
# }}}
# }}}
# ReStructuredText: {{{
# builtin: https://github.com/marshallward/vim-restructuredtext{{{
HL('rstStandaloneHyperlink', palette.purple, palette.none, 'underline')
HL('rstEmphasis', palette.none, palette.none, 'italic')
HL('rstStrongEmphasis', palette.none, palette.none, 'bold')
HL('rstStandaloneHyperlink', palette.blue, palette.none, 'underline')
HL('rstHyperlinkTarget', palette.blue, palette.none, 'underline')
highlight! link rstSubstitutionReference Blue
highlight! link rstInterpretedTextOrHyperlinkReference Green
highlight! link rstTableLines Grey
highlight! link rstInlineLiteral Green
highlight! link rstLiteralBlock Green
highlight! link rstQuotedLiteralBlock Green
# }}}
# }}}
# LaTex: {{{
# builtin: http://www.drchip.org/astronaut/vim/index.html#SYNTAX_TEX{{{
highlight! link texStatement BlueItalic
highlight! link texOnlyMath Grey
highlight! link texDefName Yellow
highlight! link texNewCmd Orange
highlight! link texCmdName Blue
highlight! link texBeginEnd Red
highlight! link texBeginEndName Green
highlight! link texDocType RedItalic
highlight! link texDocTypeArgs Orange
highlight! link texInputFile Green
# }}}
# }}}
# Html: {{{
# builtin: https://notabug.org/jorgesumle/vim-html-syntax{{{
HL('htmlH1', palette.red, palette.none, 'bold')
HL('htmlH2', palette.orange, palette.none, 'bold')
HL('htmlH3', palette.yellow, palette.none, 'bold')
HL('htmlH4', palette.green, palette.none, 'bold')
HL('htmlH5', palette.blue, palette.none, 'bold')
HL('htmlH6', palette.purple, palette.none, 'bold')
HL('htmlLink', palette.none, palette.none, 'underline')
HL('htmlBold', palette.none, palette.none, 'bold')
HL('htmlBoldUnderline', palette.none, palette.none, 'bold,underline')
HL('htmlBoldItalic', palette.none, palette.none, 'bold,italic')
HL('htmlBoldUnderlineItalic', palette.none, palette.none, 'bold,underline,italic')
HL('htmlUnderline', palette.none, palette.none, 'underline')
HL('htmlUnderlineItalic', palette.none, palette.none, 'underline,italic')
HL('htmlItalic', palette.none, palette.none, 'italic')
highlight! link htmlTag Green
highlight! link htmlEndTag Blue
highlight! link htmlTagN RedItalic
highlight! link htmlTagName RedItalic
highlight! link htmlArg Blue
highlight! link htmlScriptTag Purple
highlight! link htmlSpecialTagName RedItalic
highlight! link htmlString Green
# }}}
# }}}
# Xml: {{{
# builtin: https://github.com/chrisbra/vim-xml-ftplugin{{{
highlight! link xmlTag Green
highlight! link xmlEndTag Blue
highlight! link xmlTagName RedItalic
highlight! link xmlEqual Orange
highlight! link xmlAttrib Blue
highlight! link xmlEntity Red
highlight! link xmlEntityPunct Red
highlight! link xmlDocTypeDecl Grey
highlight! link xmlDocTypeKeyword RedItalic
highlight! link xmlCdataStart Grey
highlight! link xmlCdataCdata Purple
highlight! link xmlString Green
# }}}
# }}}
# CSS: {{{
# builtin: https://github.com/JulesWang/css.vim{{{
highlight! link cssStringQ Green
highlight! link cssStringQQ Green
highlight! link cssAttrComma Grey
highlight! link cssBraces Grey
highlight! link cssTagName Purple
highlight! link cssClassNameDot Orange
highlight! link cssClassName Red
highlight! link cssFunctionName Orange
highlight! link cssAttr Green
highlight! link cssCommonAttr Green
highlight! link cssProp Blue
highlight! link cssPseudoClassId Yellow
highlight! link cssPseudoClassFn Green
highlight! link cssPseudoClass Yellow
highlight! link cssImportant Red
highlight! link cssSelectorOp Orange
highlight! link cssSelectorOp2 Orange
highlight! link cssColor Green
highlight! link cssUnitDecorators Orange
highlight! link cssValueLength Green
highlight! link cssValueInteger Green
highlight! link cssValueNumber Green
highlight! link cssValueAngle Green
highlight! link cssValueTime Green
highlight! link cssValueFrequency Green
highlight! link cssVendor Grey
highlight! link cssNoise Grey
# }}}
# }}}
# SASS: {{{
# scss-syntax: https://github.com/cakebaker/scss-syntax.vim{{{
highlight! link scssMixinName Orange
highlight! link scssSelectorChar Orange
highlight! link scssSelectorName Red
highlight! link scssInterpolationDelimiter Yellow
highlight! link scssVariableValue Green
highlight! link scssNull Purple
highlight! link scssBoolean Purple
highlight! link scssVariableAssignment Grey
highlight! link scssAttribute Green
highlight! link scssFunctionName Orange
highlight! link scssVariable Fg
highlight! link scssAmpersand Purple
# }}}
# }}}
# LESS: {{{
# vim-less: https://github.com/groenewege/vim-less{{{
highlight! link lessMixinChar Grey
highlight! link lessClass Red
highlight! link lessFunction Orange
# }}}
# }}}
# JavaScript: {{{
# builtin: http://www.fleiner.com/vim/syntax/javascript.vim{{{
highlight! link javaScriptNull OrangeItalic
highlight! link javaScriptIdentifier BlueItalic
highlight! link javaScriptParens Fg
highlight! link javaScriptBraces Fg
highlight! link javaScriptNumber Purple
highlight! link javaScriptLabel Red
highlight! link javaScriptGlobal BlueItalic
highlight! link javaScriptMessage BlueItalic
# }}}
# vim-javascript: https://github.com/pangloss/vim-javascript{{{
highlight! link jsNoise Fg
highlight! link Noise Fg
highlight! link jsParens Fg
highlight! link jsBrackets Fg
highlight! link jsObjectBraces Fg
highlight! link jsThis BlueItalic
highlight! link jsUndefined OrangeItalic
highlight! link jsNull OrangeItalic
highlight! link jsNan OrangeItalic
highlight! link jsSuper OrangeItalic
highlight! link jsPrototype OrangeItalic
highlight! link jsFunction Red
highlight! link jsGlobalNodeObjects BlueItalic
highlight! link jsGlobalObjects BlueItalic
highlight! link jsArrowFunction Red
highlight! link jsArrowFuncArgs Fg
highlight! link jsFuncArgs Fg
highlight! link jsObjectProp Fg
highlight! link jsVariableDef Fg
highlight! link jsObjectKey Fg
highlight! link jsParen Fg
highlight! link jsParenIfElse Fg
highlight! link jsParenRepeat Fg
highlight! link jsParenSwitch Fg
highlight! link jsParenCatch Fg
highlight! link jsBracket Fg
highlight! link jsObjectValue Fg
highlight! link jsDestructuringBlock Fg
highlight! link jsBlockLabel Purple
highlight! link jsFunctionKey Green
highlight! link jsClassDefinition BlueItalic
highlight! link jsDot Orange
highlight! link jsSpreadExpression Purple
highlight! link jsSpreadOperator Green
highlight! link jsModuleKeyword BlueItalic
highlight! link jsTemplateExpression Purple
highlight! link jsTemplateBraces Purple
highlight! link jsClassMethodType BlueItalic
highlight! link jsExceptions BlueItalic
# }}}
# yajs: https://github.com/othree/yajs.vim{{{
highlight! link javascriptOpSymbol Red
highlight! link javascriptOpSymbols Red
highlight! link javascriptIdentifierName Fg
highlight! link javascriptVariable BlueItalic
highlight! link javascriptObjectLabel Fg
highlight! link javascriptPropertyNameString Fg
highlight! link javascriptFuncArg Fg
highlight! link javascriptObjectLiteral Green
highlight! link javascriptIdentifier OrangeItalic
highlight! link javascriptArrowFunc Red
highlight! link javascriptTemplate Purple
highlight! link javascriptTemplateSubstitution Purple
highlight! link javascriptTemplateSB Purple
highlight! link javascriptNodeGlobal BlueItalic
highlight! link javascriptDocTags RedItalic
highlight! link javascriptDocNotation Blue
highlight! link javascriptClassSuper OrangeItalic
highlight! link javascriptClassName BlueItalic
highlight! link javascriptClassSuperName BlueItalic
highlight! link javascriptOperator Red
highlight! link javascriptBrackets Fg
highlight! link javascriptBraces Fg
highlight! link javascriptLabel Purple
highlight! link javascriptEndColons Grey
highlight! link javascriptObjectLabelColon Grey
highlight! link javascriptDotNotation Orange
highlight! link javascriptGlobalArrayDot Orange
highlight! link javascriptGlobalBigIntDot Orange
highlight! link javascriptGlobalDateDot Orange
highlight! link javascriptGlobalJSONDot Orange
highlight! link javascriptGlobalMathDot Orange
highlight! link javascriptGlobalNumberDot Orange
highlight! link javascriptGlobalObjectDot Orange
highlight! link javascriptGlobalPromiseDot Orange
highlight! link javascriptGlobalRegExpDot Orange
highlight! link javascriptGlobalStringDot Orange
highlight! link javascriptGlobalSymbolDot Orange
highlight! link javascriptGlobalURLDot Orange
highlight! link javascriptMethod Green
highlight! link javascriptMethodName Green
highlight! link javascriptObjectMethodName Green
highlight! link javascriptGlobalMethod Green
highlight! link javascriptDOMStorageMethod Green
highlight! link javascriptFileMethod Green
highlight! link javascriptFileReaderMethod Green
highlight! link javascriptFileListMethod Green
highlight! link javascriptBlobMethod Green
highlight! link javascriptURLStaticMethod Green
highlight! link javascriptNumberStaticMethod Green
highlight! link javascriptNumberMethod Green
highlight! link javascriptDOMNodeMethod Green
highlight! link javascriptES6BigIntStaticMethod Green
highlight! link javascriptBOMWindowMethod Green
highlight! link javascriptHeadersMethod Green
highlight! link javascriptRequestMethod Green
highlight! link javascriptResponseMethod Green
highlight! link javascriptES6SetMethod Green
highlight! link javascriptReflectMethod Green
highlight! link javascriptPaymentMethod Green
highlight! link javascriptPaymentResponseMethod Green
highlight! link javascriptTypedArrayStaticMethod Green
highlight! link javascriptGeolocationMethod Green
highlight! link javascriptES6MapMethod Green
highlight! link javascriptServiceWorkerMethod Green
highlight! link javascriptCacheMethod Green
highlight! link javascriptFunctionMethod Green
highlight! link javascriptXHRMethod Green
highlight! link javascriptBOMNavigatorMethod Green
highlight! link javascriptServiceWorkerMethod Green
highlight! link javascriptDOMEventTargetMethod Green
highlight! link javascriptDOMEventMethod Green
highlight! link javascriptIntlMethod Green
highlight! link javascriptDOMDocMethod Green
highlight! link javascriptStringStaticMethod Green
highlight! link javascriptStringMethod Green
highlight! link javascriptSymbolStaticMethod Green
highlight! link javascriptRegExpMethod Green
highlight! link javascriptObjectStaticMethod Green
highlight! link javascriptObjectMethod Green
highlight! link javascriptBOMLocationMethod Green
highlight! link javascriptJSONStaticMethod Green
highlight! link javascriptGeneratorMethod Green
highlight! link javascriptEncodingMethod Green
highlight! link javascriptPromiseStaticMethod Green
highlight! link javascriptPromiseMethod Green
highlight! link javascriptBOMHistoryMethod Green
highlight! link javascriptDOMFormMethod Green
highlight! link javascriptClipboardMethod Green
highlight! link javascriptTypedArrayStaticMethod Green
highlight! link javascriptBroadcastMethod Green
highlight! link javascriptDateStaticMethod Green
highlight! link javascriptDateMethod Green
highlight! link javascriptConsoleMethod Green
highlight! link javascriptArrayStaticMethod Green
highlight! link javascriptArrayMethod Green
highlight! link javascriptMathStaticMethod Green
highlight! link javascriptSubtleCryptoMethod Green
highlight! link javascriptCryptoMethod Green
highlight! link javascriptProp Fg
highlight! link javascriptBOMWindowProp Fg
highlight! link javascriptDOMStorageProp Fg
highlight! link javascriptFileReaderProp Fg
highlight! link javascriptURLUtilsProp Fg
highlight! link javascriptNumberStaticProp Fg
highlight! link javascriptDOMNodeProp Fg
highlight! link javascriptRequestProp Fg
highlight! link javascriptResponseProp Fg
highlight! link javascriptES6SetProp Fg
highlight! link javascriptPaymentProp Fg
highlight! link javascriptPaymentResponseProp Fg
highlight! link javascriptPaymentAddressProp Fg
highlight! link javascriptPaymentShippingOptionProp Fg
highlight! link javascriptTypedArrayStaticProp Fg
highlight! link javascriptServiceWorkerProp Fg
highlight! link javascriptES6MapProp Fg
highlight! link javascriptRegExpStaticProp Fg
highlight! link javascriptRegExpProp Fg
highlight! link javascriptXHRProp Fg
highlight! link javascriptBOMNavigatorProp Green
highlight! link javascriptDOMEventProp Fg
highlight! link javascriptBOMNetworkProp Fg
highlight! link javascriptDOMDocProp Fg
highlight! link javascriptSymbolStaticProp Fg
highlight! link javascriptSymbolProp Fg
highlight! link javascriptBOMLocationProp Fg
highlight! link javascriptEncodingProp Fg
highlight! link javascriptCryptoProp Fg
highlight! link javascriptBOMHistoryProp Fg
highlight! link javascriptDOMFormProp Fg
highlight! link javascriptDataViewProp Fg
highlight! link javascriptBroadcastProp Fg
highlight! link javascriptMathStaticProp Fg
#  }}}
#  }}}
#  JavaScript React: {{{
#  vim-jsx-pretty: https://github.com/maxmellon/vim-jsx-pretty{{{
highlight! link jsxTagName RedItalic
highlight! link jsxOpenPunct Green
highlight! link jsxClosePunct Blue
highlight! link jsxEscapeJs Purple
highlight! link jsxAttrib Blue
#  }}}
#  }}}
#  TypeScript: {{{
#  vim-typescript: https://github.com/leafgarland/typescript-vim{{{
highlight! link typescriptStorageClass Red
highlight! link typescriptEndColons Fg
highlight! link typescriptSource BlueItalic
highlight! link typescriptMessage Green
highlight! link typescriptGlobalObjects BlueItalic
highlight! link typescriptInterpolation Purple
highlight! link typescriptInterpolationDelimiter Purple
highlight! link typescriptBraces Fg
highlight! link typescriptParens Fg
#  }}}
#  yats: https:github.com/HerringtonDarkholme/yats.vim{{{
highlight! link typescriptMethodAccessor Red
highlight! link typescriptVariable Red
highlight! link typescriptVariableDeclaration Fg
highlight! link typescriptTypeReference BlueItalic
highlight! link typescriptBraces Fg
highlight! link typescriptEnumKeyword Red
highlight! link typescriptEnum BlueItalic
highlight! link typescriptIdentifierName Fg
highlight! link typescriptProp Fg
highlight! link typescriptCall Fg
highlight! link typescriptInterfaceName BlueItalic
highlight! link typescriptEndColons Fg
highlight! link typescriptMember Fg
highlight! link typescriptMemberOptionality Red
highlight! link typescriptObjectLabel Fg
highlight! link typescriptDefaultParam Fg
highlight! link typescriptArrowFunc Red
highlight! link typescriptAbstract Red
highlight! link typescriptObjectColon Grey
highlight! link typescriptTypeAnnotation Grey
highlight! link typescriptAssign Red
highlight! link typescriptBinaryOp Red
highlight! link typescriptUnaryOp Red
highlight! link typescriptFuncComma Fg
highlight! link typescriptClassName BlueItalic
highlight! link typescriptClassHeritage BlueItalic
highlight! link typescriptInterfaceHeritage BlueItalic
highlight! link typescriptIdentifier OrangeItalic
highlight! link typescriptGlobal BlueItalic
highlight! link typescriptOperator Red
highlight! link typescriptNodeGlobal BlueItalic
highlight! link typescriptExport Red
highlight! link typescriptImport Red
highlight! link typescriptTypeParameter BlueItalic
highlight! link typescriptReadonlyModifier Red
highlight! link typescriptAccessibilityModifier Red
highlight! link typescriptAmbientDeclaration Red
highlight! link typescriptTemplateSubstitution Purple
highlight! link typescriptTemplateSB Purple
highlight! link typescriptExceptions Red
highlight! link typescriptCastKeyword Red
highlight! link typescriptOptionalMark Red
highlight! link typescriptNull OrangeItalic
highlight! link typescriptMappedIn Red
highlight! link typescriptFuncTypeArrow Red
highlight! link typescriptTernaryOp Red
highlight! link typescriptParenExp Fg
highlight! link typescriptIndexExpr Fg
highlight! link typescriptDotNotation Orange
highlight! link typescriptGlobalNumberDot Orange
highlight! link typescriptGlobalStringDot Orange
highlight! link typescriptGlobalArrayDot Orange
highlight! link typescriptGlobalObjectDot Orange
highlight! link typescriptGlobalSymbolDot Orange
highlight! link typescriptGlobalMathDot Orange
highlight! link typescriptGlobalDateDot Orange
highlight! link typescriptGlobalJSONDot Orange
highlight! link typescriptGlobalRegExpDot Orange
highlight! link typescriptGlobalPromiseDot Orange
highlight! link typescriptGlobalURLDot Orange
highlight! link typescriptGlobalMethod Green
highlight! link typescriptDOMStorageMethod Green
highlight! link typescriptFileMethod Green
highlight! link typescriptFileReaderMethod Green
highlight! link typescriptFileListMethod Green
highlight! link typescriptBlobMethod Green
highlight! link typescriptURLStaticMethod Green
highlight! link typescriptNumberStaticMethod Green
highlight! link typescriptNumberMethod Green
highlight! link typescriptDOMNodeMethod Green
highlight! link typescriptPaymentMethod Green
highlight! link typescriptPaymentResponseMethod Green
highlight! link typescriptHeadersMethod Green
highlight! link typescriptRequestMethod Green
highlight! link typescriptResponseMethod Green
highlight! link typescriptES6SetMethod Green
highlight! link typescriptReflectMethod Green
highlight! link typescriptBOMWindowMethod Green
highlight! link typescriptGeolocationMethod Green
highlight! link typescriptServiceWorkerMethod Green
highlight! link typescriptCacheMethod Green
highlight! link typescriptES6MapMethod Green
highlight! link typescriptFunctionMethod Green
highlight! link typescriptRegExpMethod Green
highlight! link typescriptXHRMethod Green
highlight! link typescriptBOMNavigatorMethod Green
highlight! link typescriptServiceWorkerMethod Green
highlight! link typescriptIntlMethod Green
highlight! link typescriptDOMEventTargetMethod Green
highlight! link typescriptDOMEventMethod Green
highlight! link typescriptDOMDocMethod Green
highlight! link typescriptStringStaticMethod Green
highlight! link typescriptStringMethod Green
highlight! link typescriptSymbolStaticMethod Green
highlight! link typescriptObjectStaticMethod Green
highlight! link typescriptObjectMethod Green
highlight! link typescriptJSONStaticMethod Green
highlight! link typescriptEncodingMethod Green
highlight! link typescriptBOMLocationMethod Green
highlight! link typescriptPromiseStaticMethod Green
highlight! link typescriptPromiseMethod Green
highlight! link typescriptSubtleCryptoMethod Green
highlight! link typescriptCryptoMethod Green
highlight! link typescriptBOMHistoryMethod Green
highlight! link typescriptDOMFormMethod Green
highlight! link typescriptConsoleMethod Green
highlight! link typescriptDateStaticMethod Green
highlight! link typescriptDateMethod Green
highlight! link typescriptArrayStaticMethod Green
highlight! link typescriptArrayMethod Green
highlight! link typescriptMathStaticMethod Green
highlight! link typescriptStringProperty Fg
highlight! link typescriptDOMStorageProp Fg
highlight! link typescriptFileReaderProp Fg
highlight! link typescriptURLUtilsProp Fg
highlight! link typescriptNumberStaticProp Fg
highlight! link typescriptDOMNodeProp Fg
highlight! link typescriptBOMWindowProp Fg
highlight! link typescriptRequestProp Fg
highlight! link typescriptResponseProp Fg
highlight! link typescriptPaymentProp Fg
highlight! link typescriptPaymentResponseProp Fg
highlight! link typescriptPaymentAddressProp Fg
highlight! link typescriptPaymentShippingOptionProp Fg
highlight! link typescriptES6SetProp Fg
highlight! link typescriptServiceWorkerProp Fg
highlight! link typescriptES6MapProp Fg
highlight! link typescriptRegExpStaticProp Fg
highlight! link typescriptRegExpProp Fg
highlight! link typescriptBOMNavigatorProp Green
highlight! link typescriptXHRProp Fg
highlight! link typescriptDOMEventProp Fg
highlight! link typescriptDOMDocProp Fg
highlight! link typescriptBOMNetworkProp Fg
highlight! link typescriptSymbolStaticProp Fg
highlight! link typescriptEncodingProp Fg
highlight! link typescriptBOMLocationProp Fg
highlight! link typescriptCryptoProp Fg
highlight! link typescriptDOMFormProp Fg
highlight! link typescriptBOMHistoryProp Fg
highlight! link typescriptMathStaticProp Fg
#  }}}
#  }}}
#  Dart: {{{
#  dart-lang: https://github.com/dart-lang/dart-vim-plugin{{{
highlight! link dartCoreClasses BlueItalic
highlight! link dartTypeName BlueItalic
highlight! link dartInterpolation Purple
highlight! link dartTypeDef Red
highlight! link dartClassDecl Red
highlight! link dartLibrary Red
highlight! link dartMetadata OrangeItalic
#  }}}
#  }}}
#  C/C++: {{{
#  vim-cpp-enhanced-highlight: https://github.com/octol/vim-cpp-enhanced-highlight{{{
highlight! link cLabel Red
highlight! link cppSTLnamespace BlueItalic
highlight! link cppSTLtype BlueItalic
highlight! link cppAccess Red
highlight! link cppStructure Red
highlight! link cppSTLios BlueItalic
highlight! link cppSTLiterator BlueItalic
highlight! link cppSTLexception Red
#  }}}
#  vim-cpp-modern: https://github.com/bfrg/vim-cpp-modern{{{
highlight! link cppSTLVariable BlueItalic
#  }}}
#  chromatica: https://github.com/arakashic/chromatica.nvim{{{
highlight! link Member OrangeItalic
highlight! link Variable Fg
highlight! link Namespace BlueItalic
highlight! link EnumConstant OrangeItalic
highlight! link chromaticaException Red
highlight! link chromaticaCast Red
highlight! link OperatorOverload Red
highlight! link AccessQual Red
highlight! link Linkage Red
highlight! link AutoType BlueItalic
#  }}}
#  vim-lsp-cxx-highlight https://github.com/jackguo380/vim-lsp-cxx-highlight{{{
highlight! link LspCxxHlSkippedRegion Grey
highlight! link LspCxxHlSkippedRegionBeginEnd Red
highlight! link LspCxxHlGroupEnumConstant OrangeItalic
highlight! link LspCxxHlGroupNamespace BlueItalic
highlight! link LspCxxHlGroupMemberVariable OrangeItalic
#  }}}
#  }}}
#  ObjectiveC: {{{
#  builtin: {{{
highlight! link objcModuleImport Red
highlight! link objcException Red
highlight! link objcProtocolList Fg
highlight! link objcDirective Red
highlight! link objcPropertyAttribute Purple
highlight! link objcHiddenArgument Fg
#  }}}
#  }}}
#  C#: {{{
#  builtin: https://github.com/nickspoons/vim-cs{{{
highlight! link csUnspecifiedStatement Red
highlight! link csStorage Red
highlight! link csClass Red
highlight! link csNewType BlueItalic
highlight! link csContextualStatement Red
highlight! link csInterpolationDelimiter Purple
highlight! link csInterpolation Purple
highlight! link csEndColon Fg
#  }}}
#  }}}
#  Python: {{{
#  builtin: {{{
highlight! link pythonBuiltin BlueItalic
highlight! link pythonExceptions Red
highlight! link pythonDecoratorName OrangeItalic
#  }}}
#  python-syntax: https://github.com/vim-python/python-syntax{{{
highlight! link pythonExClass BlueItalic
highlight! link pythonBuiltinType BlueItalic
highlight! link pythonBuiltinObj OrangeItalic
highlight! link pythonDottedName OrangeItalic
highlight! link pythonBuiltinFunc Green
highlight! link pythonFunction Green
highlight! link pythonDecorator OrangeItalic
highlight! link pythonInclude Include
highlight! link pythonImport PreProc
highlight! link pythonOperator Red
highlight! link pythonConditional Red
highlight! link pythonRepeat Red
highlight! link pythonException Red
highlight! link pythonNone OrangeItalic
highlight! link pythonCoding Grey
highlight! link pythonDot Grey
#  }}}
#  semshi: https://github.com/numirias/semshi{{{
HL('semshiUnresolved', palette.orange, palette.none, 'undercurl')
highlight! link semshiImported BlueItalic
highlight! link semshiParameter OrangeItalic
highlight! link semshiParameterUnused Grey
highlight! link semshiSelf BlueItalic
highlight! link semshiGlobal Green
highlight! link semshiBuiltin Green
highlight! link semshiAttribute OrangeItalic
highlight! link semshiLocal Red
highlight! link semshiFree Red
highlight! link semshiSelected CocHighlightText
highlight! link semshiErrorSign ALEErrorSign
highlight! link semshiErrorChar ALEErrorSign
#  }}}
#  }}}
#  Lua: {{{
#  builtin: {{{
highlight! link luaFunc Green
highlight! link luaFunction Red
highlight! link luaTable Fg
highlight! link luaIn Red
#  }}}
#  vim-lua: https://github.com/tbastos/vim-lua{{{
highlight! link luaFuncCall Green
highlight! link luaLocal Red
highlight! link luaSpecialValue Green
highlight! link luaBraces Fg
highlight! link luaBuiltIn BlueItalic
highlight! link luaNoise Grey
highlight! link luaLabel Purple
highlight! link luaFuncTable BlueItalic
highlight! link luaFuncArgName Fg
highlight! link luaEllipsis Red
highlight! link luaDocTag Green
#  }}}
#  }}}
#  Java: {{{
#  builtin: {{{
highlight! link javaClassDecl Red
highlight! link javaMethodDecl Red
highlight! link javaVarArg Fg
highlight! link javaAnnotation Purple
highlight! link javaUserLabel Purple
highlight! link javaTypedef OrangeItalic
highlight! link javaParen Fg
highlight! link javaParen1 Fg
highlight! link javaParen2 Fg
highlight! link javaParen3 Fg
highlight! link javaParen4 Fg
highlight! link javaParen5 Fg
#  }}}
#  }}}
#  Kotlin: {{{
#  kotlin-vim: https://github.com/udalov/kotlin-vim{{{
highlight! link ktSimpleInterpolation Purple
highlight! link ktComplexInterpolation Purple
highlight! link ktComplexInterpolationBrace Purple
highlight! link ktStructure Red
highlight! link ktKeyword OrangeItalic
#  }}}
#  }}}
#  Scala: {{{
#  builtin: https://github.com/derekwyatt/vim-scala{{{
highlight! link scalaNameDefinition Fg
highlight! link scalaInterpolationBoundary Purple
highlight! link scalaInterpolation Purple
highlight! link scalaTypeOperator Red
highlight! link scalaOperator Red
highlight! link scalaKeywordModifier Red
#  }}}
#  }}}
#  Go: {{{
#  builtin: https://github.com/google/vim-ft-go{{{
highlight! link goDirective Red
highlight! link goConstants OrangeItalic
highlight! link goDeclType Red
#  }}}
#  polyglot: {{{
highlight! link goPackage Red
highlight! link goImport Red
highlight! link goBuiltins Green
highlight! link goPredefinedIdentifiers OrangeItalic
highlight! link goVar Red
#  }}}
#  }}}
#  Rust: {{{
#  builtin: https://github.com/rust-lang/rust.vim{{{
highlight! link rustStructure Red
highlight! link rustIdentifier OrangeItalic
highlight! link rustModPath BlueItalic
highlight! link rustModPathSep Grey
highlight! link rustSelf OrangeItalic
highlight! link rustSuper OrangeItalic
highlight! link rustDeriveTrait Purple
highlight! link rustEnumVariant Purple
highlight! link rustMacroVariable OrangeItalic
highlight! link rustAssert Green
highlight! link rustPanic Green
highlight! link rustPubScopeCrate BlueItalic
highlight! link rustAttribute Purple
#  }}}
#  }}}
#  Swift: {{{
#  swift.vim: https://github.com/keith/swift.vim{{{
highlight! link swiftInterpolatedWrapper Purple
highlight! link swiftInterpolatedString Purple
highlight! link swiftProperty Fg
highlight! link swiftTypeDeclaration Red
highlight! link swiftClosureArgument OrangeItalic
highlight! link swiftStructure Red
#  }}}
#  }}}
#  PHP: {{{
#  builtin: https://jasonwoof.com/gitweb/?p=vim-syntax.git;a=blob;f=php.vim;hb=HEAD{{{
highlight! link phpVarSelector Fg
highlight! link phpIdentifier Fg
highlight! link phpDefine Green
highlight! link phpStructure Red
highlight! link phpSpecialFunction Green
highlight! link phpInterpSimpleCurly Purple
highlight! link phpComparison Red
highlight! link phpMethodsVar Fg
highlight! link phpInterpVarname Fg
highlight! link phpMemberSelector Red
highlight! link phpLabel Red
#  }}}
#  php.vim: https://github.com/StanAngeloff/php.vim{{{
highlight! link phpParent Fg
highlight! link phpNowDoc Yellow
highlight! link phpFunction Green
highlight! link phpMethod Green
highlight! link phpClass BlueItalic
highlight! link phpSuperglobals BlueItalic
highlight! link phpNullValue OrangeItalic
#  }}}
#  }}}
#  Ruby: {{{
#  builtin: https://github.com/vim-ruby/vim-ruby{{{
highlight! link rubyKeywordAsMethod Green
highlight! link rubyInterpolation Purple
highlight! link rubyInterpolationDelimiter Purple
highlight! link rubyStringDelimiter Yellow
highlight! link rubyBlockParameterList Fg
highlight! link rubyDefine Red
highlight! link rubyModuleName Red
highlight! link rubyAccess Red
highlight! link rubyMacro Red
highlight! link rubySymbol Fg
#  }}}
#  }}}
#  Haskell: {{{
#  haskell-vim: https://github.com/neovimhaskell/haskell-vim{{{
highlight! link haskellBrackets Fg
highlight! link haskellIdentifier OrangeItalic
highlight! link haskellDecl Red
highlight! link haskellType BlueItalic
highlight! link haskellDeclKeyword Red
highlight! link haskellWhere Red
highlight! link haskellDeriving Red
highlight! link haskellForeignKeywords Red
#  }}}
#  }}}
#  Perl: {{{
#  builtin: https://github.com/vim-perl/vim-perl{{{
highlight! link perlStatementPackage Red
highlight! link perlStatementInclude Red
highlight! link perlStatementStorage Red
highlight! link perlStatementList Red
highlight! link perlMatchStartEnd Red
highlight! link perlVarSimpleMemberName Green
highlight! link perlVarSimpleMember Fg
highlight! link perlMethod Green
highlight! link podVerbatimLine Green
highlight! link podCmdText Yellow
highlight! link perlVarPlain Fg
highlight! link perlVarPlain2 Fg
#  }}}
#  }}}
#  OCaml: {{{
#  builtin: https://github.com/rgrinberg/vim-ocaml{{{
highlight! link ocamlArrow Red
highlight! link ocamlEqual Red
highlight! link ocamlOperator Red
highlight! link ocamlKeyChar Red
highlight! link ocamlModPath Green
highlight! link ocamlFullMod Green
highlight! link ocamlModule BlueItalic
highlight! link ocamlConstructor Orange
highlight! link ocamlModParam Fg
highlight! link ocamlModParam1 Fg
highlight! link ocamlAnyVar Fg #  aqua
highlight! link ocamlPpxEncl Red
highlight! link ocamlPpxIdentifier Fg
highlight! link ocamlSigEncl Red
highlight! link ocamlModParam1 Fg
#  }}}
#  }}}
#  Erlang: {{{
#  builtin: https://github.com/vim-erlang/vim-erlang-runtime{{{
highlight! link erlangAtom Fg
highlight! link erlangVariable Fg
highlight! link erlangLocalFuncRef Green
highlight! link erlangLocalFuncCall Green
highlight! link erlangGlobalFuncRef Green
highlight! link erlangGlobalFuncCall Green
highlight! link erlangAttribute BlueItalic
highlight! link erlangPipe Red
#  }}}
#  }}}
#  Elixir: {{{
#  vim-elixir: https://github.com/elixir-editors/vim-elixir{{{
highlight! link elixirStringDelimiter Yellow
highlight! link elixirKeyword Red
highlight! link elixirInterpolation Purple
highlight! link elixirInterpolationDelimiter Purple
highlight! link elixirSelf BlueItalic
highlight! link elixirPseudoVariable OrangeItalic
highlight! link elixirModuleDefine Red
highlight! link elixirBlockDefinition Red
highlight! link elixirDefine Red
highlight! link elixirPrivateDefine Red
highlight! link elixirGuard Red
highlight! link elixirPrivateGuard Red
highlight! link elixirProtocolDefine Red
highlight! link elixirImplDefine Red
highlight! link elixirRecordDefine Red
highlight! link elixirPrivateRecordDefine Red
highlight! link elixirMacroDefine Red
highlight! link elixirPrivateMacroDefine Red
highlight! link elixirDelegateDefine Red
highlight! link elixirOverridableDefine Red
highlight! link elixirExceptionDefine Red
highlight! link elixirCallbackDefine Red
highlight! link elixirStructDefine Red
highlight! link elixirExUnitMacro Red
#  }}}
#  }}}
#  Common Lisp: {{{
#  builtin: http://www.drchip.org/astronaut/vim/index.html#SYNTAX_LISP{{{
highlight! link lispAtomMark Purple
highlight! link lispKey Orange
highlight! link lispFunc Green
#  }}}
#  }}}
#  Clojure: {{{
#  builtin: https://github.com/guns/vim-clojure-static{{{
highlight! link clojureMacro Red
highlight! link clojureFunc Green
highlight! link clojureConstant OrangeItalic
highlight! link clojureSpecial Red
highlight! link clojureDefine Red
highlight! link clojureKeyword Blue
highlight! link clojureVariable Fg
highlight! link clojureMeta Purple
highlight! link clojureDeref Purple
#  }}}
#  }}}
#  Matlab: {{{
#  builtin: {{{
highlight! link matlabSemicolon Fg
highlight! link matlabFunction RedItalic
highlight! link matlabImplicit Green
highlight! link matlabDelimiter Fg
highlight! link matlabOperator Green
highlight! link matlabArithmeticOperator Red
highlight! link matlabArithmeticOperator Red
highlight! link matlabRelationalOperator Red
highlight! link matlabRelationalOperator Red
highlight! link matlabLogicalOperator Red
#  }}}
#  }}}
#  Shell: {{{
#  builtin: http://www.drchip.org/astronaut/vim/index.html#SYNTAX_SH{{{
highlight! link shRange Fg
highlight! link shOption Purple
highlight! link shQuote Yellow
highlight! link shVariable BlueItalic
highlight! link shDerefSimple BlueItalic
highlight! link shDerefVar BlueItalic
highlight! link shDerefSpecial BlueItalic
highlight! link shDerefOff BlueItalic
highlight! link shVarAssign Red
highlight! link shFunctionOne Green
highlight! link shFunctionKey Red
#  }}}
#  }}}
#  Zsh: {{{
#  builtin: https://github.com/chrisbra/vim-zsh{{{
highlight! link zshOption BlueItalic
highlight! link zshSubst Orange
highlight! link zshFunction Green
#  }}}
#  }}}
#  PowerShell: {{{
#  vim-ps1: https://github.com/PProvost/vim-ps1{{{
highlight! link ps1FunctionInvocation Green
highlight! link ps1FunctionDeclaration Green
highlight! link ps1InterpolationDelimiter Purple
highlight! link ps1BuiltIn BlueItalic
#  }}}
#  }}}
#  VimL: {{{
highlight! link vimLet Red
highlight! link vimFunction Green
highlight! link vimIsCommand Fg
highlight! link vimUserFunc Green
highlight! link vimFuncName Green
highlight! link vimMap BlueItalic
highlight! link vimNotation Purple
highlight! link vimMapLhs Green
highlight! link vimMapRhs Green
highlight! link vimSetEqual BlueItalic
highlight! link vimSetSep Fg
highlight! link vimOption BlueItalic
highlight! link vimUserAttrbKey BlueItalic
highlight! link vimUserAttrb Green
highlight! link vimAutoCmdSfxList Orange
highlight! link vimSynType Orange
highlight! link vimHiBang Orange
highlight! link vimSet BlueItalic
highlight! link vimSetSep Grey
#  }}}
#  Makefile: {{{
highlight! link makeIdent Purple
highlight! link makeSpecTarget BlueItalic
highlight! link makeTarget Orange
highlight! link makeCommands Red
#  }}}
#  CMake: {{{
highlight! link cmakeCommand Red
highlight! link cmakeKWconfigure_package_config_file BlueItalic
highlight! link cmakeKWwrite_basic_package_version_file BlueItalic
highlight! link cmakeKWExternalProject Green
highlight! link cmakeKWadd_compile_definitions Green
highlight! link cmakeKWadd_compile_options Green
highlight! link cmakeKWadd_custom_command Green
highlight! link cmakeKWadd_custom_target Green
highlight! link cmakeKWadd_definitions Green
highlight! link cmakeKWadd_dependencies Green
highlight! link cmakeKWadd_executable Green
highlight! link cmakeKWadd_library Green
highlight! link cmakeKWadd_link_options Green
highlight! link cmakeKWadd_subdirectory Green
highlight! link cmakeKWadd_test Green
highlight! link cmakeKWbuild_command Green
highlight! link cmakeKWcmake_host_system_information Green
highlight! link cmakeKWcmake_minimum_required Green
highlight! link cmakeKWcmake_parse_arguments Green
highlight! link cmakeKWcmake_policy Green
highlight! link cmakeKWconfigure_file Green
highlight! link cmakeKWcreate_test_sourcelist Green
highlight! link cmakeKWctest_build Green
highlight! link cmakeKWctest_configure Green
highlight! link cmakeKWctest_coverage Green
highlight! link cmakeKWctest_memcheck Green
highlight! link cmakeKWctest_run_script Green
highlight! link cmakeKWctest_start Green
highlight! link cmakeKWctest_submit Green
highlight! link cmakeKWctest_test Green
highlight! link cmakeKWctest_update Green
highlight! link cmakeKWctest_upload Green
highlight! link cmakeKWdefine_property Green
highlight! link cmakeKWdoxygen_add_docs Green
highlight! link cmakeKWenable_language Green
highlight! link cmakeKWenable_testing Green
highlight! link cmakeKWexec_program Green
highlight! link cmakeKWexecute_process Green
highlight! link cmakeKWexport Green
highlight! link cmakeKWexport_library_dependencies Green
highlight! link cmakeKWfile Green
highlight! link cmakeKWfind_file Green
highlight! link cmakeKWfind_library Green
highlight! link cmakeKWfind_package Green
highlight! link cmakeKWfind_path Green
highlight! link cmakeKWfind_program Green
highlight! link cmakeKWfltk_wrap_ui Green
highlight! link cmakeKWforeach Green
highlight! link cmakeKWfunction Green
highlight! link cmakeKWget_cmake_property Green
highlight! link cmakeKWget_directory_property Green
highlight! link cmakeKWget_filename_component Green
highlight! link cmakeKWget_property Green
highlight! link cmakeKWget_source_file_property Green
highlight! link cmakeKWget_target_property Green
highlight! link cmakeKWget_test_property Green
highlight! link cmakeKWif Green
highlight! link cmakeKWinclude Green
highlight! link cmakeKWinclude_directories Green
highlight! link cmakeKWinclude_external_msproject Green
highlight! link cmakeKWinclude_guard Green
highlight! link cmakeKWinstall Green
highlight! link cmakeKWinstall_files Green
highlight! link cmakeKWinstall_programs Green
highlight! link cmakeKWinstall_targets Green
highlight! link cmakeKWlink_directories Green
highlight! link cmakeKWlist Green
highlight! link cmakeKWload_cache Green
highlight! link cmakeKWload_command Green
highlight! link cmakeKWmacro Green
highlight! link cmakeKWmark_as_advanced Green
highlight! link cmakeKWmath Green
highlight! link cmakeKWmessage Green
highlight! link cmakeKWoption Green
highlight! link cmakeKWproject Green
highlight! link cmakeKWqt_wrap_cpp Green
highlight! link cmakeKWqt_wrap_ui Green
highlight! link cmakeKWremove Green
highlight! link cmakeKWseparate_arguments Green
highlight! link cmakeKWset Green
highlight! link cmakeKWset_directory_properties Green
highlight! link cmakeKWset_property Green
highlight! link cmakeKWset_source_files_properties Green
highlight! link cmakeKWset_target_properties Green
highlight! link cmakeKWset_tests_properties Green
highlight! link cmakeKWsource_group Green
highlight! link cmakeKWstring Green
highlight! link cmakeKWsubdirs Green
highlight! link cmakeKWtarget_compile_definitions Green
highlight! link cmakeKWtarget_compile_features Green
highlight! link cmakeKWtarget_compile_options Green
highlight! link cmakeKWtarget_include_directories Green
highlight! link cmakeKWtarget_link_directories Green
highlight! link cmakeKWtarget_link_libraries Green
highlight! link cmakeKWtarget_link_options Green
highlight! link cmakeKWtarget_precompile_headers Green
highlight! link cmakeKWtarget_sources Green
highlight! link cmakeKWtry_compile Green
highlight! link cmakeKWtry_run Green
highlight! link cmakeKWunset Green
highlight! link cmakeKWuse_mangled_mesa Green
highlight! link cmakeKWvariable_requires Green
highlight! link cmakeKWvariable_watch Green
highlight! link cmakeKWwrite_file Green
#  }}}
#  Json: {{{
highlight! link jsonKeyword Red
highlight! link jsonString Green
highlight! link jsonBoolean Blue
highlight! link jsonNoise Grey
highlight! link jsonQuote Grey
highlight! link jsonBraces Fg
#  }}}
#  Yaml: {{{
highlight! link yamlKey Red
highlight! link yamlConstant BlueItalic
highlight! link yamlString Green
#  }}}
#  Toml: {{{
HL('tomlTable', palette.purple, palette.none, 'bold')
highlight! link tomlKey Red
highlight! link tomlBoolean Blue
highlight! link tomlString Green
highlight! link tomlTableArray tomlTable
#  }}}
#  Diff: {{{
highlight! link diffAdded Green
highlight! link diffRemoved Red
highlight! link diffChanged Blue
highlight! link diffOldFile Yellow
highlight! link diffNewFile Orange
highlight! link diffFile Purple
highlight! link diffLine Grey
highlight! link diffIndexLine Purple
#  }}}
#  Git Commit: {{{
highlight! link gitcommitSummary Red
highlight! link gitcommitUntracked Grey
highlight! link gitcommitDiscarded Grey
highlight! link gitcommitSelected Grey
highlight! link gitcommitUnmerged Grey
highlight! link gitcommitOnBranch Grey
highlight! link gitcommitArrow Grey
highlight! link gitcommitFile Green
#  }}}
#  INI: {{{
HL('dosiniHeader', palette.red, palette.none, 'bold')
highlight! link dosiniLabel Blue
highlight! link dosiniValue Green
highlight! link dosiniNumber Green
#  }}}
#  Help: {{{
HL('helpNote', palette.purple, palette.none, 'bold')
HL('helpHeadline', palette.red, palette.none, 'bold')
HL('helpHeader', palette.orange, palette.none, 'bold')
HL('helpURL', palette.green, palette.none, 'underline')
HL('helpHyperTextEntry', palette.blue, palette.none, 'bold')
highlight! link helpHyperTextJump Blue
highlight! link helpCommand Yellow
highlight! link helpExample Green
highlight! link helpSpecial Purple
highlight! link helpSectionDelim Grey
#  }}}
#  }}}
#  Plugins: {{{
#  junegunn/vim-plug{{{
HL('plug1', palette.red, palette.none, 'bold')
HL('plugNumber', palette.yellow, palette.none, 'bold')
highlight! link plug2 Blue
highlight! link plugBracket Blue
highlight! link plugName Green
highlight! link plugDash Red
highlight! link plugNotLoaded Grey
highlight! link plugH2 Purple
highlight! link plugMessage Purple
highlight! link plugError Red
highlight! link plugRelDate Grey
highlight! link plugStar Purple
highlight! link plugUpdate Blue
highlight! link plugDeleted Grey
highlight! link plugEdge Purple
#  }}}
#  neoclide/coc.nvim{{{
if configuration.current_word ==# 'bold'
  HL('CocHighlightText', palette.none, palette.none, 'bold')
elseif configuration.current_word ==# 'underline'
  HL('CocHighlightText', palette.none, palette.none, 'underline')
elseif configuration.current_word ==# 'italic'
  HL('CocHighlightText', palette.none, palette.none, 'italic')
elseif configuration.current_word ==# 'grey background'
  HL('CocHighlightText', palette.none, palette.bg1)
endif
HL('CocHoverRange', palette.none, palette.none, 'bold,underline')
HL('CocHintHighlight', palette.none, palette.none, 'undercurl', palette.green)
HL('CocErrorFloat', palette.red, palette.bg2)
HL('CocWarningFloat', palette.yellow, palette.bg2)
HL('CocInfoFloat', palette.blue, palette.bg2)
HL('CocHintFloat', palette.green, palette.bg2)
if configuration.transparent_background
  HL('CocHintSign', palette.purple, palette.none)
else
  HL('CocHintSign', palette.purple, palette.bg1)
endif
highlight! link CocCodeLens Grey
highlight! link CocErrorSign ALEErrorSign
highlight! link CocWarningSign ALEWarningSign
highlight! link CocInfoSign ALEInfoSign
highlight! link CocHintSign Label
highlight! link CocErrorHighlight ALEError
highlight! link CocWarningHighlight ALEWarning
highlight! link CocInfoHighlight ALEInfo
highlight! link CocWarningVirtualText ALEVirtualTextWarning
highlight! link CocErrorVirtualText ALEVirtualTextError
highlight! link CocInfoVirtualText ALEVirtualTextInfo
highlight! link CocHintVirtualText ALEVirtualTextInfo
highlight! link CocGitAddedSign GitGutterAdd
highlight! link CocGitChangeRemovedSign GitGutterChangeDelete
highlight! link CocGitChangedSign GitGutterChange
highlight! link CocGitRemovedSign GitGutterDelete
highlight! link CocGitTopRemovedSign GitGutterDelete
highlight! link CocExplorerBufferRoot Red
highlight! link CocExplorerBufferExpandIcon Blue
highlight! link CocExplorerBufferBufnr Yellow
highlight! link CocExplorerBufferModified Red
highlight! link CocExplorerBufferBufname Grey
highlight! link CocExplorerBufferFullpath Grey
highlight! link CocExplorerFileRoot Red
highlight! link CocExplorerFileExpandIcon Blue
highlight! link CocExplorerFileFullpath Grey
highlight! link CocExplorerFileDirectory Green
highlight! link CocExplorerFileGitStage Blue
highlight! link CocExplorerFileGitUnstage Yellow
highlight! link CocExplorerFileSize Blue
highlight! link CocExplorerTimeAccessed Purple
highlight! link CocExplorerTimeCreated Purple
highlight! link CocExplorerTimeModified Purple
highlight! link CocExplorerFileRootName Orange
highlight! link CocExplorerBufferNameVisible Green
#  }}}
#  dense-analysis/ale{{{
HL('ALEError', palette.none, palette.none, 'undercurl', palette.red)
HL('ALEWarning', palette.none, palette.none, 'undercurl', palette.yellow)
HL('ALEInfo', palette.none, palette.none, 'undercurl', palette.blue)
if configuration.transparent_background
  HL('ALEErrorSign', palette.red, palette.none)
  HL('ALEWarningSign', palette.yellow, palette.none)
  HL('ALEInfoSign', palette.blue, palette.none)
else
  HL('ALEErrorSign', palette.red, palette.bg1)
  HL('ALEWarningSign', palette.yellow, palette.bg1)
  HL('ALEInfoSign', palette.blue, palette.bg1)
endif
highlight! link ALEVirtualTextError Grey
highlight! link ALEVirtualTextWarning Grey
highlight! link ALEVirtualTextInfo Grey
highlight! link ALEVirtualTextStyleError ALEVirtualTextError
highlight! link ALEVirtualTextStyleWarning ALEVirtualTextWarning
#  }}}
#  neomake/neomake{{{
highlight! link NeomakeError ALEError
highlight! link NeomakeErrorSign ALEErrorSign
highlight! link NeomakeWarning ALEWarning
highlight! link NeomakeWarningSign ALEWarningSign
highlight! link NeomakeInfo ALEInfo
highlight! link NeomakeInfoSign ALEInfoSign
highlight! link NeomakeMessage ALEInfo
highlight! link NeomakeMessageSign CocHintSign
highlight! link NeomakeVirtualtextError Grey
highlight! link NeomakeVirtualtextWarning Grey
highlight! link NeomakeVirtualtextInfo Grey
highlight! link NeomakeVirtualtextMessag Grey
#  }}}
#  vim-syntastic/syntastic{{{
highlight! link SyntasticError ALEError
highlight! link SyntasticWarning ALEWarning
highlight! link SyntasticErrorSign ALEErrorSign
highlight! link SyntasticWarningSign ALEWarningSign
#  }}}
#  Yggdroot/LeaderF{{{
if !exists('g:Lf_StlColorscheme')
  g:Lf_StlColorscheme = 'one'
endif
HL('Lf_hl_match', palette.green, palette.none, 'bold')
HL('Lf_hl_match0', palette.green, palette.none, 'bold')
HL('Lf_hl_match1', palette.blue, palette.none, 'bold')
HL('Lf_hl_match2', palette.red, palette.none, 'bold')
HL('Lf_hl_match3', palette.yellow, palette.none, 'bold')
HL('Lf_hl_match4', palette.purple, palette.none, 'bold')
HL('Lf_hl_matchRefine', palette.yellow, palette.none, 'bold')
highlight! link Lf_hl_cursorline Fg
highlight! link Lf_hl_selection DiffAdd
highlight! link Lf_hl_rgHighlight Visual
highlight! link Lf_hl_gtagsHighlight Visual
#  }}}
#  junegunn/fzf.vim{{{
g:fzf_colors = {
      'fg': ['fg', 'Normal'],
      'bg': ['bg', 'Normal'],
      'hl': ['fg', 'Green'],
      'fg+': ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
      'bg+': ['bg', 'CursorLine', 'CursorColumn'],
      'hl+': ['fg', 'Green'],
      'info': ['fg', 'Yellow'],
      'prompt': ['fg', 'Red'],
      'pointer': ['fg', 'Blue'],
      'marker': ['fg', 'Blue'],
      'spinner': ['fg', 'Yellow'],
      'header': ['fg', 'Blue']
      }
#  }}}
#  Shougo/denite.nvim{{{
HL('deniteMatchedChar', palette.green, palette.none, 'bold')
HL('deniteMatchedRange', palette.green, palette.none, 'bold,underline')
HL('deniteInput', palette.green, palette.bg1, 'bold')
HL('deniteStatusLineNumber', palette.purple, palette.bg1)
HL('deniteStatusLinePath', palette.fg, palette.bg1)
highlight! link deniteSelectedLine Green
#  }}}
#  kien/ctrlp.vim{{{
HL('CtrlPMatch', palette.green, palette.none, 'bold')
HL('CtrlPPrtBase', palette.grey, palette.none)
HL('CtrlPLinePre', palette.grey, palette.none)
HL('CtrlPMode1', palette.blue, palette.bg1, 'bold')
HL('CtrlPMode2', palette.bg1, palette.blue, 'bold')
HL('CtrlPStats', palette.grey, palette.bg1, 'bold')
highlight! link CtrlPNoEntries Red
highlight! link CtrlPPrtCursor Blue
#  }}}
#  majutsushi/tagbar{{{
highlight! link TagbarFoldIcon Blue
highlight! link TagbarSignature Green
highlight! link TagbarKind Red
highlight! link TagbarScope Orange
highlight! link TagbarNestedKind Blue
highlight! link TagbarVisibilityPrivate Red
highlight! link TagbarVisibilityPublic Blue
#  }}}
#  liuchengxu/vista.vim{{{
highlight! link VistaBracket Grey
highlight! link VistaChildrenNr Yellow
highlight! link VistaScope Red
highlight! link VistaTag Green
highlight! link VistaPrefix Grey
highlight! link VistaColon Green
highlight! link VistaIcon Purple
highlight! link VistaLineNr Fg
#  }}}
#  airblade/vim-gitgutter{{{
if configuration.transparent_background
  HL('GitGutterAdd', palette.green, palette.none)
  HL('GitGutterChange', palette.blue, palette.none)
  HL('GitGutterDelete', palette.red, palette.none)
  HL('GitGutterChangeDelete', palette.purple, palette.none)
else
  HL('GitGutterAdd', palette.green, palette.bg1)
  HL('GitGutterChange', palette.blue, palette.bg1)
  HL('GitGutterDelete', palette.red, palette.bg1)
  HL('GitGutterChangeDelete', palette.purple, palette.bg1)
endif
#  }}}
#  mhinz/vim-signify{{{
highlight! link SignifySignAdd GitGutterAdd
highlight! link SignifySignChange GitGutterChange
highlight! link SignifySignDelete GitGutterDelete
highlight! link SignifySignChangeDelete GitGutterChangeDelete
#  }}}
#  scrooloose/nerdtree{{{
highlight! link NERDTreeDir Green
highlight! link NERDTreeDirSlash Green
highlight! link NERDTreeOpenable Blue
highlight! link NERDTreeClosable Blue
highlight! link NERDTreeFile Fg
highlight! link NERDTreeExecFile Red
highlight! link NERDTreeUp Grey
highlight! link NERDTreeCWD Purple
highlight! link NERDTreeHelp Grey
highlight! link NERDTreeToggleOn Green
highlight! link NERDTreeToggleOff Red
highlight! link NERDTreeFlags Blue
highlight! link NERDTreeLinkFile Grey
highlight! link NERDTreeLinkTarget Green
#  }}}
#  justinmk/vim-dirvish{{{
highlight! link DirvishPathTail Blue
highlight! link DirvishArg Yellow
#  }}}
#  vim.org/netrw {{{
#  https://www.vim.org/scripts/script.php?script_id=1075
highlight! link netrwDir Green
highlight! link netrwClassify Green
highlight! link netrwLink Grey
highlight! link netrwSymLink Fg
highlight! link netrwExe Red
highlight! link netrwComment Grey
highlight! link netrwList Yellow
highlight! link netrwHelpCmd Blue
highlight! link netrwCmdSep Grey
highlight! link netrwVersion Purple
#  }}}
#  andymass/vim-matchup{{{
HL('MatchParenCur', palette.none, palette.none, 'bold')
HL('MatchWord', palette.none, palette.none, 'underline')
HL('MatchWordCur', palette.none, palette.none, 'underline')
#  }}}
#  easymotion/vim-easymotion {{{
highlight! link EasyMotionTarget Search
highlight! link EasyMotionShade Grey
#  }}}
#  justinmk/vim-sneak {{{
highlight! link Sneak Cursor
highlight! link SneakLabel Cursor
highlight! link SneakScope DiffAdd
#  }}}
#  terryma/vim-multiple-cursors{{{
highlight! link multiple_cursors_cursor Cursor
highlight! link multiple_cursors_visual Visual
#  }}}
#  mg979/vim-visual-multi{{{
g:VM_Mono_hl = 'Cursor'
g:VM_Extend_hl = 'Visual'
g:VM_Cursor_hl = 'Cursor'
g:VM_Insert_hl = 'Cursor'
#  }}}
#  dominikduda/vim_current_word{{{
highlight! link CurrentWord CocHighlightText
highlight! link CurrentWordTwins CocHighlightText
#  }}}
#  RRethy/vim-illuminate{{{
highlight! link illuminatedWord CocHighlightText
#  }}}
#  itchyny/vim-cursorword{{{
highlight! link CursorWord0 CocHighlightText
highlight! link CursorWord1 CocHighlightText
#  }}}
#  Yggdroot/indentLine{{{
g:indentLine_color_gui = palette.grey[0]
g:indentLine_color_term = palette.grey[1]
#  }}}
#  nathanaelkane/vim-indent-guides{{{
if get(g:, 'indent_guides_auto_colors', 1) == 0
  HL('IndentGuidesOdd', palette.bg0, palette.bg1)
  HL('IndentGuidesEven', palette.bg0, palette.bg2)
endif
#  }}}
#  kshenoy/vim-signature {{{
if configuration.transparent_background
  HL('SignatureMarkText', palette.blue, palette.none)
  HL('SignatureMarkerText', palette.red, palette.none)
else
  HL('SignatureMarkText', palette.blue, palette.bg1)
  HL('SignatureMarkerText', palette.red, palette.bg1)
endif
#  }}}
#  mhinz/vim-startify{{{
highlight! link StartifyBracket Grey
highlight! link StartifyFile Green
highlight! link StartifyNumber Orange
highlight! link StartifyPath Grey
highlight! link StartifySlash Grey
highlight! link StartifySection Blue
highlight! link StartifyHeader Red
highlight! link StartifySpecial Grey
#  }}}
#  ap/vim-buftabline{{{
highlight! link BufTabLineCurrent TabLineSel
highlight! link BufTabLineActive TabLine
highlight! link BufTabLineHidden TabLineFill
highlight! link BufTabLineFill TabLineFill
#  }}}
#  liuchengxu/vim-which-key{{{
highlight! link WhichKey Red
highlight! link WhichKeySeperator Green
highlight! link WhichKeyGroup Orange
highlight! link WhichKeyDesc Blue
#  }}}
#  skywind3000/quickmenu.vim{{{
highlight! link QuickmenuOption Green
highlight! link QuickmenuNumber Orange
highlight! link QuickmenuBracket Grey
highlight! link QuickmenuHelp Blue
highlight! link QuickmenuSpecial Grey
highlight! link QuickmenuHeader Purple
#  }}}
#  mbbill/undotree{{{
HL('UndotreeSavedBig', palette.red, palette.none, 'bold')
highlight! link UndotreeNode Blue
highlight! link UndotreeNodeCurrent Purple
highlight! link UndotreeSeq Green
highlight! link UndotreeCurrent Blue
highlight! link UndotreeNext Yellow
highlight! link UndotreeTimeStamp Grey
highlight! link UndotreeHead Purple
highlight! link UndotreeBranch Blue
highlight! link UndotreeSavedSmall Red
#  }}}
#  unblevable/quick-scope {{{
HL('QuickScopePrimary', palette.green, palette.none, 'underline')
HL('QuickScopeSecondary', palette.blue, palette.none, 'underline')
#  }}}
#  APZelos/blamer.nvim {{{
highlight! link Blamer Grey
#  }}}
#  cohama/agit.vim {{{
highlight! link agitTree Grey
highlight! link agitDate Green
highlight! link agitRemote Red
highlight! link agitHead Blue
highlight! link agitRef Orange
highlight! link agitTag Blue
highlight! link agitStatFile Blue
highlight! link agitStatRemoved Red
highlight! link agitStatAdded Green
highlight! link agitStatMessage Orange
highlight! link agitDiffRemove diffRemoved
highlight! link agitDiffAdd diffAdded
highlight! link agitDiffHeader Blue
highlight! link agitAuthor Yellow
#  }}}
#  }}}
#  Terminal: {{{
if (has('termguicolors') && &termguicolors) || has('gui_running')
  #  Definition
  var terminal = {
        'black':    palette.black,
        'red':      palette.red,
        'yellow':   palette.yellow,
        'green':    palette.green,
        'cyan':     palette.orange,
        'blue':     palette.blue,
        'purple':   palette.purple,
        'white':    palette.fg
        }
  #  Implementation: {{{
  if !has('nvim')
    g:terminal_ansi_colors = [terminal.black[0], terminal.red[0], terminal.green[0], terminal.yellow[0],
          terminal.blue[0], terminal.purple[0], terminal.cyan[0], terminal.white[0], terminal.black[0], terminal.red[0],
          terminal.green[0], terminal.yellow[0], terminal.blue[0], terminal.purple[0], terminal.cyan[0], terminal.white[0]]
  else
    g:terminal_color_0 = terminal.black[0]
    g:terminal_color_1 = terminal.red[0]
    g:terminal_color_2 = terminal.green[0]
    g:terminal_color_3 = terminal.yellow[0]
    g:terminal_color_4 = terminal.blue[0]
    g:terminal_color_5 = terminal.purple[0]
    g:terminal_color_6 = terminal.cyan[0]
    g:terminal_color_7 = terminal.white[0]
    g:terminal_color_8 = terminal.black[0]
    g:terminal_color_9 = terminal.red[0]
    g:terminal_color_10 = terminal.green[0]
    g:terminal_color_11 = terminal.yellow[0]
    g:terminal_color_12 = terminal.blue[0]
    g:terminal_color_13 = terminal.purple[0]
    g:terminal_color_14 = terminal.cyan[0]
    g:terminal_color_15 = terminal.white[0]
  endif
  #  }}}
endif
#  }}}

#  vim: set sw=2 ts=2 sts=2 et tw=80 ft=vim fdm=marker fmr={{{,}}}:
