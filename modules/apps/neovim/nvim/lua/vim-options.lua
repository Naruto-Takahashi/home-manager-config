-- ==========================================================================
--  基本設定 (vim-options.lua)
-- ==========================================================================

vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.cmd("set number")
vim.cmd("set relativenumber") -- 動画では relative number を使うことが多いので合わせますが、お好みで変えてください
vim.cmd("set clipboard=unnamedplus")
vim.cmd("set mouse=a")
vim.cmd("set cursorline")  -- カーソル行をハイライト
vim.g.mapleader = " "       -- スペースキーをリーダーキーにする（Typecraft推奨）
vim.opt.showmode = false    -- "-- INSERT --" 表示はステータスバーにあるため不要
vim.opt.cmdheight = 0       -- コマンドライン行を隠して本文領域を1行広げる (入力時のみ出現)
vim.o.winborder = "rounded" -- hover等、border未指定のfloatにも一括で枠を付ける (nvim 0.11+)

-- matugen 配色 (フォールバック付き)
local mc = require("matugen")

-- Transparency settings (背景透過設定)
vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function()
        local hl = vim.api.nvim_set_hl
        local no_bg = { bg = "none" }
        -- Normal/NormalFloatも{bg="none"}のみだとfgまで消えて透明になり，
        -- Normalのfgを参照する他プラグイン(snacks.nvimのgh連携など)が
        -- 色取得に失敗してエラーになるため，fgを明示する
        hl(0, "Normal", { bg = "none", fg = mc.text })
        hl(0, "NormalFloat", { bg = "none", fg = mc.text })
        -- 枠線色を明示指定 (未指定だとkanagawaの既定色が背景に埋もれて見づらいことがある)
        hl(0, "FloatBorder", { bg = "none", fg = mc.muted })
        hl(0, "FloatTitle", { bg = "none", fg = mc.accent, bold = true })
        hl(0, "FloatFooter", { bg = "none", fg = mc.muted })
        -- nvim_set_hlは部分テーブルでも「置き換え」であり「マージ」ではないため、
        -- bg=noneだけ指定すると元々リンクで得ていたfgまで消えて透明→文字が
        -- 背景と同化して見えなくなる (neo-treeのファイル作成/詳細ポップアップ等)。
        -- 必ずfgも明示する
        hl(0, "NeoTreeFloatBorder", { bg = "none", fg = mc.muted })
        hl(0, "NeoTreeFloatTitle", { bg = "none", fg = mc.accent, bold = true })
        hl(0, "NeoTreeFloatNormal", { bg = "none", fg = mc.text })
        -- NeoTreeTitleBarはポップアップ上辺の罫線ではなく、空白を背景色で
        -- 塗りつぶして帯状に見せる仕組み (popup_border_style = "NC")。
        -- bg=noneにすると帯そのものが消えて上辺が丸ごと無くなるため、
        -- ここだけは不透明な背景を与える
        hl(0, "NeoTreeTitleBar", { bg = mc.muted, fg = mc.surface, bold = true })
        hl(0, "NeoTreePreview", { bg = "none", fg = mc.text })
        -- フォルダのアイコンと名前は matugen の secondary (2番めの色)
        hl(0, "NeoTreeDirectoryIcon", { fg = mc.secondary })
        hl(0, "NeoTreeDirectoryName", { fg = mc.secondary })
        hl(0, "NeoTreeRootName", { fg = mc.secondary, bold = true })
        -- snacks.nvim の input (vim.ui.inputを担う。neo-treeのファイル作成/
        -- 詳細プロンプト等もこれ経由) は独自ハイライト群を持ち、上記の
        -- NormalFloat/FloatTitle 等ではカバーされない。fgを明示しないと
        -- 既定色が背景と同化して読めなくなるため個別に設定する
        hl(0, "SnacksInputNormal", { bg = "none", fg = mc.text })
        hl(0, "SnacksInputBorder", { bg = "none", fg = mc.muted })
        hl(0, "SnacksInputTitle", { bg = "none", fg = mc.accent, bold = true })
        hl(0, "SnacksInputIcon", { bg = "none", fg = mc.accent })
        hl(0, "NormalNC", no_bg)
        hl(0, "SignColumn", no_bg)

        -- コマンドラインTAB補完(wildmenu)や補完ポップアップは既定でkanagawaの
        -- 青みがかった配色のままになっており，他を透過・matugen配色に揃えた
        -- 中で浮いて見えるため，surface/accentに揃える。
        -- CmdlineポップアップやNormalFloatと同様にbg="none"にして
        -- ターミナルの背景透過をそのまま活かす (fgはNormalFloat同様に明示)
        hl(0, "Pmenu", { bg = "none", fg = mc.text })
        hl(0, "PmenuSel", { bg = mc.accent, fg = mc.on_accent, bold = true })
        -- スクロールバー(溝/つまみ)はbg=noneにすると視認できなくなるため
        -- 不透明のまま残す
        hl(0, "PmenuSbar", { bg = mc.surface })
        hl(0, "PmenuThumb", { bg = mc.muted })
        hl(0, "PmenuBorder", { bg = "none", fg = mc.muted })
        hl(0, "WildMenu", { bg = mc.accent, fg = mc.on_accent, bold = true })
        -- 補完メニュー内でマッチした文字列部分 (nvim-cmp)
        hl(0, "CmpItemAbbrMatch", { fg = mc.accent, bold = true })
        hl(0, "CmpItemAbbrMatchFuzzy", { fg = mc.accent, bold = true })

        -- Visual選択・検索ハイライトもkanagawaの生の青/オレンジ配色のままだった
        -- ため，matugenパレットに揃える (Pmenuと同じ理由)
        -- VisualはWezTermのカーソル色 (tertiary) と揃える。文字色もWezTermの
        -- cursor_fgと同じsurfaceにして濃い背景の上でも読めるようにする
        hl(0, "Visual", { bg = mc.tertiary, fg = mc.surface })
        hl(0, "Search", { bg = mc.tertiary, fg = mc.on_accent })
        hl(0, "CurSearch", { bg = mc.accent, fg = mc.on_accent, bold = true })
        hl(0, "IncSearch", { bg = mc.accent, fg = mc.on_accent, bold = true })
        hl(0, "Substitute", { bg = mc.error, fg = mc.on_accent })

        -- ウィンドウ分割線がkanagawaの生の黒(#0d0c0c)のままで，透過背景の上で
        -- 不自然な黒帯になっていたため，他の枠線色 (FloatBorder等) と揃える
        hl(0, "WinSeparator", { fg = mc.muted, bg = "none" })

        -- "-- More --"/確認プロンプト(y/n)がkanagawaの生の青のままだった
        hl(0, "MoreMsg", { fg = mc.accent, bold = true })
        hl(0, "Question", { fg = mc.accent, bold = true })

        -- netrw等のディレクトリ表示，:h や diff 見出し等の汎用タイトル
        hl(0, "Directory", { fg = mc.secondary })
        hl(0, "Title", { fg = mc.accent, bold = true })

        -- コマンドライン入力はtreesitterの vim パーサーでリアルタイムハイライト
        -- されており，コマンド名(command_name)は @function.macro → Macro →
        -- PreProc にリンクしている。dragon_overrides で PreProc(operator/
        -- preproc/regex)を赤系にしているため，コード中のプリプロセッサ的な
        -- 用途では意図通りでも，コマンドライン入力まで赤くなってしまう。
        -- vim言語専用キャプチャだけ個別に配色し直す (他言語のMacroには影響しない)
        hl(0, "@function.macro.vim", { fg = mc.accent, bold = true })
        hl(0, "@keyword.vim", { fg = mc.tertiary })
        -- lualine の透過セクションは StatusLine にフォールバックするため、ここも透過必須
        hl(0, "StatusLine", no_bg)
        hl(0, "StatusLineNC", no_bg)
        hl(0, "LineNr", { bg = "none" })
        hl(0, "CursorLineNr", { bg = "none", bold = true })
        hl(0, "CursorLine", { bg = mc.selection_bg })
        hl(0, "CursorColumn", { bg = mc.selection_bg })
        -- hl(0, "CursorLine", { bg = "none", underline = true }) -- カーソル行の背景を表示するためにコメントアウト

        -- Telescope Transparency (Telescope の背景透過)
        hl(0, "TelescopeNormal", no_bg)
        hl(0, "TelescopeBorder", no_bg)
        hl(0, "TelescopePromptNormal", no_bg)
        hl(0, "TelescopePromptBorder", no_bg)
        hl(0, "TelescopeResultsNormal", no_bg)
        hl(0, "TelescopeResultsBorder", no_bg)
        hl(0, "TelescopePreviewNormal", no_bg)
        hl(0, "TelescopePreviewBorder", no_bg)
        -- 以下3つはkanagawaの生色(Identifier/TelescopeTitle/Special)に
        -- リンクされたままでmatugenパレットを追従していなかったため明示する
        hl(0, "TelescopePromptPrefix", { fg = mc.accent })
        hl(0, "TelescopeTitle", { fg = mc.muted, bold = true })
        hl(0, "TelescopeMatching", { fg = mc.accent, bold = true })

        -- Diagnostic Colors (エラーを赤，警告・情報・ヒントをゴールド化)
        hl(0, "DiagnosticError", { fg = mc.error })
        hl(0, "DiagnosticWarn", { fg = mc.accent })
        hl(0, "DiagnosticInfo", { fg = mc.accent })
        hl(0, "DiagnosticHint", { fg = mc.accent })
        hl(0, "DiagnosticFloatingError", { fg = mc.error })
        hl(0, "DiagnosticFloatingWarn", { fg = mc.accent })
        hl(0, "DiagnosticFloatingInfo", { fg = mc.accent })
        hl(0, "DiagnosticFloatingHint", { fg = mc.accent })
        hl(0, "DiagnosticSignError", { fg = mc.error })
        hl(0, "DiagnosticSignWarn", { fg = mc.accent })
        hl(0, "DiagnosticSignInfo", { fg = mc.accent })
        hl(0, "DiagnosticSignHint", { fg = mc.accent })
        hl(0, "DiagnosticUnderlineError", { sp = mc.error, undercurl = true })
        hl(0, "DiagnosticUnderlineWarn", { sp = mc.accent, undercurl = true })
        hl(0, "DiagnosticUnderlineInfo", { sp = mc.accent, undercurl = true })
        hl(0, "DiagnosticUnderlineHint", { sp = mc.accent, undercurl = true })

        -- Mode Message (-- INSERT -- などのモード表示をゴールド化)
        hl(0, "ModeMsg", { fg = mc.accent, bold = true })

        -- Lazygit のアクティブ枠色
        hl(0, "LazygitActiveBorder", { fg = mc.accent, bold = true })

        -- Dashboard: matugen パレット
        --   ロゴ/起動メッセージ = secondary，アイコン = accent，メニュー文字 = text，
        --   キー割当 = tertiary，Quit = 赤系
        -- snacks は行別指定が効かない場合に基底グループで描くため、基底も上書きする
        hl(0, "SnacksDashboardHeader", { fg = mc.secondary, bold = true })
        for i = 1, 6 do
            hl(0, "SnacksDashboardHeader" .. i, { fg = mc.secondary, bold = true })
        end
        hl(0, "SnacksDashboardIcon", { fg = mc.accent })
        hl(0, "SnacksDashboardWhite", { fg = mc.text })
        hl(0, "SnacksDashboardKeyHint", { fg = mc.tertiary, bold = true })
        hl(0, "SnacksDashboardIconRed", { fg = mc.error })
        hl(0, "SnacksDashboardFooter", { fg = mc.secondary })
        hl(0, "SnacksDashboardSpecial", { fg = mc.secondary })

        -- 対応する括弧を WezTerm のカーソル色 (matugen の tertiary) で塗りつぶす
        -- (他プラグインが同じ ColorScheme イベントで後からデフォルト色を
        --  再適用することがあるため，イベントループの最後に回して確実に勝たせる)
        vim.schedule(function()
            hl(0, "MatchParen", { bg = mc.tertiary, fg = mc.surface, bold = true })
        end)
    end,
})

-- キーマップ
vim.keymap.set("n", "<leader>cd", ":Ex<CR>", { desc = "Open Netrw Explorer" })

-- OS 別設定
if vim.fn.has("win32") == 1 then
    vim.opt.makeprg = "mingw32-make"
    -- Windows: シェルを PowerShell にする
    vim.opt.shell = "powershell.exe"
    vim.opt.shellcmdflag = "-NoProfile -NoLogo -NonInteractive -Command"
    vim.opt.shellquote = ""
    vim.opt.shellxquote = ""
else
    vim.opt.makeprg = "make"
    -- Linux / WSL: シェルは既定 (bash/zsh) のまま
end

-- ウィンドウ間の移動 (Ctrl+HJKL)
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Navigate Left" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Navigate Down" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Navigate Up" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Navigate Right" })

-- ビジュアルモードでインデント後も選択を維持
vim.keymap.set("v", "<", "<gv", { desc = "Indent Left and Stay" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent Right and Stay" })

-- jk でインサートモードを抜ける
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit Insert Mode" })

-- 検索ハイライトの消去
vim.keymap.set("n", "<Esc>", ":nohlsearch<CR>", { desc = "Clear Highlight" })

-- スクロール/ジャンプ後にカーソルを画面中央へ (毎回zzを打たなくて済むようにする)
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half Page Down (Centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half Page Up (Centered)" })
-- 検索ジャンプ後も同様に中央へ (zvで折り畳みも開く)
vim.keymap.set("n", "n", "nzzzv", { desc = "Next Search Result (Centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev Search Result (Centered)" })
-- ジャンプリスト移動後も中央へ
vim.keymap.set("n", "<C-o>", "<C-o>zz", { desc = "Jump Back (Centered)" })
vim.keymap.set("n", "<C-i>", "<C-i>zz", { desc = "Jump Forward (Centered)" })

-- J (行結合) でカーソル位置が動かないようにする (結合後も同じ場所を見続けられる)
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join Lines (Keep Cursor Position)" })

-- ビジュアルモードでのペーストで、貼り付けた内容でレジスタを上書きしない
-- (直前にヤンクした内容を連続でペーストできる)
vim.keymap.set("v", "p", '"_dP', { desc = "Paste Without Overwriting Register" })

-- ==========================================================================
--  Zenn Tools (Custom)
-- ==========================================================================
-- 既存の get-clip-img スクリプトを利用して、Windowsクリップボードの画像を
-- 現在のZenn記事プロジェクトの images ディレクトリに保存し、Markdownリンクを挿入します。

local function paste_zenn_image()
    -- プロジェクトルート検出（.gitがある場所、なければカレント）
    local root = vim.fs.dirname(vim.fs.find(".git", { path = vim.fn.expand("%:p:h"), upward = true })[1]) or
        vim.fn.getcwd()

    -- 現在のファイル名（拡張子なし）をslugとして取得
    local slug = vim.fn.expand("%:t:r")

    -- デフォルトファイル名の生成
    local date = os.date("%Y%m%d%H%M%S")
    local default_name

    -- slugが取得できればフォルダ分けする
    if slug and slug ~= "" then
        default_name = slug .. "/image-" .. date
    else
        default_name = "image-" .. date
    end

    -- ファイル名（パス）の入力
    vim.ui.input({ prompt = "Image name (under /images/): ", default = default_name }, function(input)
        if not input or input == "" then
            return -- キャンセルまたは空入力
        end

        -- 拡張子 .png がなければ付与（get-clip-imgがpngを出力するため）
        if not input:match("%.png$") then
            input = input .. ".png"
        end

        -- Zenn推奨の images ディレクトリ配下に保存
        local img_rel_path = "/images/" .. input
        local fullpath = root .. img_rel_path
        local img_dir = vim.fs.dirname(fullpath)

        -- ディレクトリが存在しない場合は作成
        if vim.fn.isdirectory(img_dir) == 0 then
            vim.fn.mkdir(img_dir, "p")
        end

        -- スクリプト実行
        local cmd = "get-clip-img " .. vim.fn.shellescape(fullpath)

        vim.notify("Saving image to " .. img_rel_path .. " ...", vim.log.levels.INFO)
        local result = vim.fn.system(cmd)

        if vim.v.shell_error == 0 then
            -- 成功時: 相対パスでMarkdownリンクを挿入
            local insert_text = "![](" .. img_rel_path .. ")"
            vim.api.nvim_put({ insert_text }, "c", true, true)
            vim.notify("Saved: " .. img_rel_path, vim.log.levels.INFO)
        else
            -- 失敗時
            vim.notify("Failed: " .. result, vim.log.levels.ERROR)
        end
    end)
end

-- キーバインド設定: <leader>ip
vim.keymap.set("n", "<leader>ip", paste_zenn_image, { desc = "Paste Image (Zenn/Custom)" })

-- ==========================================================================
--  TOhtml Auto-Save
-- ==========================================================================
vim.api.nvim_create_user_command("ToHtmlSave", function()
    -- 現在のファイルパスを取得
    local current_file = vim.fn.expand("%:p")
    local current_dir = vim.fn.expand("%:p:h")
    local file_name = vim.fn.expand("%:t")

    if current_file == "" then
        vim.notify("No file associated with this buffer.", vim.log.levels.ERROR)
        return
    end

    -- HTMLファイル名を決定 (拡張子を .html に変更、なければ追加)
    local html_name = file_name:gsub("%.%w+$", "") .. ".html"
    if html_name == file_name then html_name = file_name .. ".html" end
    local output_path = current_dir .. "/" .. html_name

    -- TOhtml実行
    vim.cmd("TOhtml")

    -- 生成されたHTMLバッファで保存を実行
    vim.cmd("w! " .. vim.fn.fnameescape(output_path))

    -- HTMLバッファを閉じる（今のバッファがHTMLになっているので）
    vim.cmd("bd")

    vim.notify("HTML saved to: " .. output_path, vim.log.levels.INFO)
end, { desc = "Convert to HTML and save in the same directory" })

vim.keymap.set("n", "<leader>th", ":ToHtmlSave<CR>", { desc = "TOhtml and Save" })

-- ==========================================================================
--  Rich Preview (<leader>r) — yaziのrich-preview.yaziと全く同じrich-cli呼び出し
-- ==========================================================================
-- render-markdown.nvim は行内の記号を差し替えるだけ (conceal) で，
-- rich-cli (yaziのmd/csv/json/ipynb/rstプレビューが使っているのと同じ実体、
-- modules/apps/yazi/default.nix参照) のような「独立したレンダラーによる
-- 本格的な描画」とは別物で見劣りする。ブラウザ版(<leader>m、Mermaid対応)を
-- 開くほどでもない時に、フローティング端末でyaziと同じ見た目のプレビューを
-- 出せるようにする。オプションはyaziのrich-preview.yazi/main.luaと同一
-- (-j 除く。あちらはyazi側でJSON行ごとに読むための指定で、ここでは
-- ターミナルへ直接描画するだけなので不要)。
local function rich_preview()
  if vim.fn.executable("rich") == 0 then
    vim.notify("rich-cli (`rich`コマンド) が見つかりません", vim.log.levels.WARN)
    return
  end
  local file = vim.fn.expand("%:p")
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Rich Preview ",
    title_pos = "center",
  })
  vim.fn.termopen({
    "rich",
    "--left",
    "--line-numbers",
    "--force-terminal",
    "--panel=rounded",
    "--guides",
    "--max-width",
    tostring(width - 2),
    file,
  })
  local close_opts = { buffer = buf, silent = true, nowait = true }
  vim.keymap.set({ "n", "t" }, "q", "<cmd>close<CR>", close_opts)
  vim.keymap.set({ "n", "t" }, "<Esc>", "<cmd>close<CR>", close_opts)
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "csv", "json", "rst" },
  callback = function(args)
    vim.keymap.set("n", "<leader>r", rich_preview, { buffer = args.buf, desc = "Rich Preview (yazi同等)" })
  end,
})

-- render-markdown.nvimの表(罫線)はウィンドウ幅で切り詰める機能を持たないため，
-- wrap有効のままだと幅が足りない時に罫線が折り返されてボックス構造ごと
-- 崩れて見える。markdownだけnowrapにして横スクロール(zL/zH、マウスホイール
-- 横スワイプ等)に倒すことで、崩れず表の形を保ったまま確認できる。
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = false
    vim.opt_local.sidescrolloff = 4
  end,
})
