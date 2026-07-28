-- ブラウザでのMarkdownライブプレビュー (Mermaid図もmermaid.js経由で描画される)
-- ターミナル内蔵の render-markdown.nvim では任意グラフィックス (Mermaid等) を
-- 描画できないため，本物のレンダリングが必要な時だけ :MarkdownPreview でブラウザを開く。
return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  ft = { "markdown" },
  -- vim.fn["mkdp#util#install"]() はプラグインが未ロードだと関数が
  -- 見つからず失敗することがあるため，install.sh を直接叩く
  build = "cd app && ./install.sh",
  init = function()
    vim.g.mkdp_filetypes = { "markdown" }
    vim.g.mkdp_theme = "dark"
    -- app/lib/util/opener.js は WSL を検知すると常に cmd.exe 経由で開こうとするが，
    -- Nix管理のPATHには /mnt/c/Windows/System32 が含まれず cmd.exe が見つからず失敗する。
    -- jobstart({...}) (リスト形式) はシェルを介さず直接execするため PATH解決に失敗する。
    -- シェル経由 (文字列コマンド) + 絶対パスで jobstart することで解決する。
    vim.g.mkdp_browserfunc = "OpenMarkdownPreview"
    vim.cmd([[
      function! OpenMarkdownPreview(url)
        call jobstart("/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Command Start-Process '" . a:url . "'", {'detach': v:true})
      endfunction
    ]])
  end,
  keys = {
    { "<leader>m", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview Toggle (Mermaid対応)", ft = "markdown" },
  },
}
