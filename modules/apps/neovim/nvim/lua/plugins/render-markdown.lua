-- kanagawa-dragon は見出しレベルごとの色を定義しておらず，全レベルが
-- @markup.heading.markdown → Function の1色にリンクされるため単調に見える。
-- 見出しレベルごとにkanagawa waveの鮮やかな色を割り当てて色分けする。
local heading_colors = {
  "#E46876", -- H1 waveRed
  "#FFA066", -- H2 surimiOrange
  "#E6C384", -- H3 carpYellow
  "#98BB6C", -- H4 springGreen
  "#7FB4CA", -- H5 springBlue
  "#957FB8", -- H6 oniViolet
}

local function set_heading_highlights()
  for i, color in ipairs(heading_colors) do
    vim.api.nvim_set_hl(0, "RenderMarkdownH" .. i, { fg = color, bold = true })
  end
end

return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
  opts = {},
  config = function(_, opts)
    require('render-markdown').setup(opts)
    set_heading_highlights()
    -- colorscheme切り替え時 (matugen等) にリンクへ戻らないよう再適用する
    vim.api.nvim_create_autocmd("ColorScheme", { callback = set_heading_highlights })
  end,
}
