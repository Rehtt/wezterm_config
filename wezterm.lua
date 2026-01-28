local wezterm = require("wezterm")
local act = wezterm.action

-- 1. 创建配置对象
local config = {}
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- 2. 辅助变量：检测操作系统
local is_windows = wezterm.target_triple:find("windows") ~= nil
local is_mac = wezterm.target_triple:find("apple") ~= nil

-- =========================================================
--   外观与字体 (Appearance & Fonts)
-- =========================================================

config.color_scheme = "Catppuccin Mocha"

config.font = wezterm.font_with_fallback({
	"JetBrainsMono Nerd Font",
	"Fira Code",
	"Consolas",
})
config.font_size = is_mac and 14.0 or 11.0

-- [修改点 1] 窗口样式：加入 INTEGRATED_BUTTONS
-- 这会在标签栏显示原生按钮，从而支持双击空白区域最大化/还原
config.window_background_opacity = 0.95
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

config.window_padding = {
	left = 10,
	right = 10,
	top = 10,
	bottom = 10,
}

config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false

-- =========================================================
--   Shell 集成 (Shell Integration)
-- =========================================================

if is_windows then
	config.default_prog = { "pwsh.exe", "-NoLogo" }
	config.launch_menu = {
		{ label = "PowerShell Core", args = { "pwsh.exe", "-NoLogo" } },
		{ label = "Windows PowerShell", args = { "powershell.exe", "-NoLogo" } },
		{ label = "WSL (Ubuntu)", args = { "wsl.exe", "--distribution", "Ubuntu" } },
		{ label = "Command Prompt", args = { "cmd.exe" } },
	}
end

-- =========================================================
--   快捷键 (Keybindings)
-- =========================================================

-- 窗口管理类操作：Mac 用 CMD，Windows 用 ALT (避免冲突)
local mod = is_mac and "SUPER" or "ALT"

config.keys = {
	-- [修改点 2] 智能 Ctrl+C (Smart Copy/Interrupt)
	-- 有选中文字 -> 复制；无选中文字 -> 发送 Ctrl+C 中断
	{
		key = "c",
		mods = "CTRL",
		action = wezterm.action_callback(function(window, pane)
			local selection = window:get_selection_text_for_pane(pane)
			if selection ~= "" then
				window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
				window:perform_action(act.ClearSelection, pane)
			else
				window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
			end
		end),
	},

	-- [修改点 3] 强制 Ctrl+V 粘贴
	-- 注意：这会导致在 Vim 中 Ctrl+v 无法进入列编辑模式 (请改用 Ctrl+q)
	{
		key = "v",
		mods = "CTRL",
		action = act.PasteFrom("Clipboard"),
	},

	-- --- 以下是原有的窗口管理快捷键 ---

	-- 标签页管理
	{ key = "t", mods = mod, action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = mod, action = act.CloseCurrentTab({ confirm = true }) },
	{ key = "[", mods = mod, action = act.ActivateTabRelative(-1) },
	{ key = "]", mods = mod, action = act.ActivateTabRelative(1) },
	{ key = "1", mods = mod, action = act.ActivateTab(0) },
	{ key = "2", mods = mod, action = act.ActivateTab(1) },
	{ key = "3", mods = mod, action = act.ActivateTab(2) },
	{ key = "4", mods = mod, action = act.ActivateTab(3) },
	{ key = "5", mods = mod, action = act.ActivateTab(4) },

	-- 分屏操作 (Shift + Mod + \ 或 -)
	{
		key = "\\",
		mods = mod .. "|SHIFT",
		action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "-",
		mods = mod .. "|SHIFT",
		action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
	},

	-- 面板导航
	{ key = "LeftArrow", mods = mod, action = act.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = mod, action = act.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = mod, action = act.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = mod, action = act.ActivatePaneDirection("Down") },

	-- 调整面板大小
	{ key = "LeftArrow", mods = mod .. "|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "RightArrow", mods = mod .. "|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },
	{ key = "UpArrow", mods = mod .. "|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "DownArrow", mods = mod .. "|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },

	-- 命令面板
	{ key = "p", mods = mod .. "|SHIFT", action = act.ActivateCommandPalette },

	-- 按下 Ctrl+Shift+Space 呼出快速选择
	{ key = "Space", mods = "CTRL|SHIFT", action = act.QuickSelect },
	-- 激活复制模式
	{ key = "x", mods = "CTRL|SHIFT", action = act.ActivateCopyMode },
}

-- =========================================================
--   鼠标绑定 (Mouse Bindings)
-- =========================================================
config.mouse_bindings = {
	-- 点击链接打开
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = is_mac and "CMD" or "CTRL",
		action = act.OpenLinkAtMouseCursor,
	},
	-- 右键粘贴逻辑 (选中文字时复制，否则粘贴)
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = wezterm.action_callback(function(window, pane)
			local has_selection = window:get_selection_text_for_pane(pane) ~= ""
			if has_selection then
				window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
				window:perform_action(act.ClearSelection, pane)
			else
				window:perform_action(act.PasteFrom("Clipboard"), pane)
			end
		end),
	},
	-- [新增] 三击左键：选中当前命令的输出 (Semantic Zone)
	-- 只有配置了第一步的 Shell Integration 才会生效
	{
		event = { Down = { streak = 3, button = "Left" } },
		mods = "NONE",
		action = act.SelectTextAtMouseCursor("SemanticZone"),
	},
}

return config
