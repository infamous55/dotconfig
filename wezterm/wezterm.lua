local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

local config = wezterm.config_builder()

config.font_size = 18
config.font = wezterm.font("Monaspace Neon NF")

config.color_scheme = "GitHub Dark Tritanopia"
config.colors = {
	tab_bar = {
		inactive_tab_edge = "#6e7681",
	},
}

config.window_frame = {
	font = wezterm.font({ family = "Monaspace Neon NF", weight = "Bold" }),
	font_size = 14.0,
	active_titlebar_bg = "#0d1117",
	inactive_titlebar_bg = "#484f58",
}

config.tab_and_split_indices_are_zero_based = true

local SearchDirection = {
	Backward = 0,
	Forward = 1,
}

wezterm.GLOBAL.tmux_search_directions = {}

local CustomActions = {}
CustomActions = {
	ClearPattern = wezterm.action_callback(function(window, pane)
		wezterm.GLOBAL.tmux_search_directions[tostring(pane)] = nil
		window:perform_action(
			act.Multiple({
				act.CopyMode("ClearPattern"),
				act.CopyMode("AcceptPattern"),
			}),
			pane
		)
	end),

	ClearSelectionOrClearPatternOrClose = wezterm.action_callback(function(window, pane)
		local action

		if window:get_selection_text_for_pane(pane) ~= "" then
			action = act.Multiple({
				act.ClearSelection,
				act.CopyMode("ClearSelectionMode"),
			})
		elseif wezterm.GLOBAL.tmux_search_directions[tostring(pane)] then
			action = CustomActions.ClearPattern
		else
			action = act.CopyMode("Close")
		end

		window:perform_action(action, pane)
	end),

	NextMatch = wezterm.action_callback(function(window, pane)
		local direction = wezterm.GLOBAL.tmux_search_directions[tostring(pane)]
		local action

		if not direction then
			return
		end

		if direction == SearchDirection.Backward then
			action = act.Multiple({
				act.CopyMode("PriorMatch"),
				act.ClearSelection,
				act.CopyMode("ClearSelectionMode"),
			})
		elseif direction == SearchDirection.Forward then
			action = act.Multiple({
				act.CopyMode("NextMatch"),
				act.ClearSelection,
				act.CopyMode("ClearSelectionMode"),
			})
		end

		window:perform_action(action, pane)
	end),

	PriorMatch = wezterm.action_callback(function(window, pane)
		local direction = wezterm.GLOBAL.tmux_search_directions[tostring(pane)]
		local action

		if not direction then
			return
		end

		if direction == SearchDirection.Backward then
			action = act.Multiple({
				act.CopyMode("NextMatch"),
				act.ClearSelection,
				act.CopyMode("ClearSelectionMode"),
			})
		elseif direction == SearchDirection.Forward then
			action = act.Multiple({
				act.CopyMode("PriorMatch"),
				act.ClearSelection,
				act.CopyMode("ClearSelectionMode"),
			})
		end

		window:perform_action(action, pane)
	end),

	MovePaneToNewTab = wezterm.action_callback(function(_, pane)
		pane:move_to_new_tab()
	end),

	RenameWorkspace = wezterm.action_callback(function(window, pane)
		window:perform_action(
			act.PromptInputLine({
				description = "rename workspace: ",
				action = wezterm.action_callback(function(_, _, line)
					if not line or line == "" then
						return
					end

					mux.rename_workspace(mux.get_active_workspace(), line)
				end),
			}),
			pane
		)
	end),

	SearchBackward = wezterm.action_callback(function(window, pane)
		wezterm.GLOBAL.tmux_search_directions[tostring(pane)] = SearchDirection.Backward

		window:perform_action(
			act.Multiple({
				act.CopyMode("ClearPattern"),
				act.CopyMode("EditPattern"),
			}),
			pane
		)
	end),

	SearchForward = wezterm.action_callback(function(window, pane)
		wezterm.GLOBAL.tmux_search_directions[tostring(pane)] = SearchDirection.Forward

		window:perform_action(
			act.Multiple({
				act.CopyMode("ClearPattern"),
				act.CopyMode("EditPattern"),
			}),
			pane
		)
	end),

	WorkspaceSelect = wezterm.action_callback(function(window, pane)
		local active_workspace = mux.get_active_workspace()
		local workspaces = mux.get_workspace_names()
		local num_tabs_by_workspace = {}

		for _, mux_window in ipairs(mux.all_windows()) do
			local workspace = mux_window:get_workspace()
			local num_tabs = #mux_window:tabs()

			if num_tabs_by_workspace[workspace] then
				num_tabs_by_workspace[workspace] = num_tabs_by_workspace[workspace] + num_tabs
			else
				num_tabs_by_workspace[workspace] = num_tabs
			end
		end

		local choices = {
			{
				id = active_workspace,
				label = active_workspace .. ": " .. num_tabs_by_workspace[active_workspace] .. " tabs (active)",
			},
		}

		for _, workspace in ipairs(workspaces) do
			if workspace ~= active_workspace then
				table.insert(choices, {
					id = workspace,
					label = workspace .. ": " .. num_tabs_by_workspace[workspace] .. " tabs",
				})
			end
		end

		window:perform_action(
			act.InputSelector({
				title = "select workspace",
				choices = choices,
				action = wezterm.action_callback(function(_, _, id, _)
					if not id then
						return
					end

					mux.set_active_workspace(id)
				end),
			}),
			pane
		)
	end),
}

config.disable_default_key_bindings = true

config.leader = { key = "Space", mods = "CTRL" }

config.keys = {
	{ key = "F11", action = act.ToggleFullScreen },

	{ key = "$", mods = "LEADER | SHIFT", action = CustomActions.RenameWorkspace },
	{ key = "s", mods = "LEADER", action = CustomActions.WorkspaceSelect },

	{ key = "(", mods = "LEADER", action = act.SwitchWorkspaceRelative(-1) },
	{ key = ")", mods = "LEADER", action = act.SwitchWorkspaceRelative(1) },

	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "P", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{ key = "N", mods = "LEADER", action = act.ActivateTabRelative(1) },

	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "C", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "d", mods = "LEADER", action = act.CloseCurrentTab({ confirm = true }) },
	{ key = "D", mods = "LEADER", action = act.CloseCurrentTab({ confirm = true }) },

	{ key = "0", mods = "LEADER", action = act.ActivateTab(0) },
	{ key = "1", mods = "LEADER", action = act.ActivateTab(1) },
	{ key = "2", mods = "LEADER", action = act.ActivateTab(2) },
	{ key = "3", mods = "LEADER", action = act.ActivateTab(3) },
	{ key = "4", mods = "LEADER", action = act.ActivateTab(4) },
	{ key = "5", mods = "LEADER", action = act.ActivateTab(5) },
	{ key = "6", mods = "LEADER", action = act.ActivateTab(6) },
	{ key = "7", mods = "LEADER", action = act.ActivateTab(7) },
	{ key = "8", mods = "LEADER", action = act.ActivateTab(8) },
	{ key = "9", mods = "LEADER", action = act.ActivateTab(9) },

	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "\\", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },

	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "X", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },

	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "H", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "J", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "K", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "L", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

	{ key = "LeftArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "DownArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Down", 5 }) },
	{ key = "UpArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "RightArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Right", 5 }) },

	{ key = "r", mods = "LEADER", action = act.ReloadConfiguration },
	{ key = "R", mods = "LEADER", action = act.ReloadConfiguration },

	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },

	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "Z", mods = "LEADER", action = act.TogglePaneZoomState },

	{ key = "q", mods = "LEADER", action = act.PaneSelect({ mode = "Activate" }) },

	{ key = "!", mods = "LEADER | SHIFT", action = CustomActions.MovePaneToNewTab },

	{ key = "{", mods = "LEADER | SHIFT", action = act.RotatePanes("CounterClockwise") },
	{ key = "}", mods = "LEADER | SHIFT", action = act.RotatePanes("Clockwise") },

	{ key = "0", mods = "CTRL", action = act.ResetFontSize },

	{ key = "=", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "+", mods = "CTRL | SHIFT", action = act.IncreaseFontSize },

	{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
	{ key = "_", mods = "CTRL | SHIFT", action = act.DecreaseFontSize },

	{ key = "c", mods = "SHIFT | CTRL", action = act.CopyTo("Clipboard") },
	{ key = "Copy", mods = "NONE", action = act.CopyTo("Clipboard") },

	{ key = "v", mods = "SHIFT | CTRL", action = act.PasteFrom("Clipboard") },
	{ key = "Paste", mods = "NONE", action = act.PasteFrom("Clipboard") },

	{ key = "p", mods = "SHIFT | CTRL", action = act.ActivateCommandPalette },
	{ key = "l", mods = "SHIFT | CTRL", action = act.ShowDebugOverlay },
	{ key = "n", mods = "SHIFT | CTRL", action = act.SpawnWindow },
	{ key = "m", mods = "SHIFT | CTRL", action = act.Hide },

	{ key = "phys:Space", mods = "LEADER", action = act.QuickSelect },

	{ key = "PageUp", mods = "SHIFT | CTRL", action = act.MoveTabRelative(-1) },
	{ key = "PageDown", mods = "SHIFT | CTRL", action = act.MoveTabRelative(1) },

	{ key = "k", mods = "SHIFT | CTRL", action = act.ClearScrollback("ScrollbackOnly") },

	{ key = "PageUp", mods = "SHIFT", action = act.ScrollByPage(-1) },
	{ key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(1) },
}

config.key_tables = {
	copy_mode = {
		{
			key = "y",
			mods = "NONE",
			action = act.Multiple({
				act.CopyTo("Clipboard"),
				act.ClearSelection,
				act.CopyMode("ClearSelectionMode"),
			}),
		},
		{
			key = "Y",
			mods = "NONE",
			action = act.Multiple({
				act.CopyTo("Clipboard"),
				act.ClearSelection,
				act.CopyMode("ClearSelectionMode"),
			}),
		},
		{ key = "Escape", mods = "NONE", action = CustomActions.ClearSelectionOrClearPatternOrClose },

		{ key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
		{ key = "V", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },

		{ key = "v", mods = "SHIFT", action = act.CopyMode({ SetSelectionMode = "Line" }) },
		{ key = "V", mods = "SHIFT", action = act.CopyMode({ SetSelectionMode = "Line" }) },

		{ key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
		{ key = "V", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },

		{ key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
		{ key = "H", mods = "NONE", action = act.CopyMode("MoveLeft") },
		{ key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
		{ key = "J", mods = "NONE", action = act.CopyMode("MoveDown") },
		{ key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
		{ key = "K", mods = "NONE", action = act.CopyMode("MoveUp") },
		{ key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },
		{ key = "L", mods = "NONE", action = act.CopyMode("MoveRight") },

		{ key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
		{ key = "W", mods = "NONE", action = act.CopyMode("MoveForwardWord") },

		{ key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
		{ key = "B", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },

		{ key = "e", mods = "NONE", action = act.CopyMode("MoveForwardWordEnd") },
		{ key = "E", mods = "NONE", action = act.CopyMode("MoveForwardWordEnd") },

		{ key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
		{ key = "$", mods = "SHIFT", action = act.CopyMode("MoveToEndOfLineContent") },
		{ key = "^", mods = "SHIFT", action = act.CopyMode("MoveToStartOfLineContent") },

		{ key = "g", mods = "NONE", action = act.CopyMode("MoveToScrollbackBottom") },
		{ key = "G", mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },

		{ key = "h", mods = "SHIFT", action = act.CopyMode("MoveToViewportTop") },
		{ key = "m", mods = "SHIFT", action = act.CopyMode("MoveToViewportMiddle") },
		{ key = "l", mods = "SHIFT", action = act.CopyMode("MoveToViewportBottom") },

		{ key = "b", mods = "CTRL", action = act.CopyMode("PageUp") },
		{ key = "B", mods = "CTRL", action = act.CopyMode("PageUp") },

		{ key = "u", mods = "CTRL", action = act.CopyMode({ MoveByPage = -0.5 }) },
		{ key = "U", mods = "CTRL", action = act.CopyMode({ MoveByPage = -0.5 }) },

		{ key = "f", mods = "CTRL", action = act.CopyMode("PageDown") },
		{ key = "F", mods = "CTRL", action = act.CopyMode("PageDown") },

		{ key = "d", mods = "CTRL", action = act.CopyMode({ MoveByPage = 0.5 }) },
		{ key = "D", mods = "CTRL", action = act.CopyMode({ MoveByPage = 0.5 }) },

		{ key = "f", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = false } }) },
		{ key = "F", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = false } }) },
		{ key = "f", mods = "SHIFT", action = act.CopyMode({ JumpBackward = { prev_char = false } }) },

		{ key = "t", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = true } }) },
		{ key = "T", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = true } }) },
		{ key = "t", mods = "SHIFT", action = act.CopyMode({ JumpBackward = { prev_char = true } }) },

		{ key = ",", mods = "NONE", action = act.CopyMode("JumpReverse") },
		{ key = ";", mods = "NONE", action = act.CopyMode("JumpAgain") },

		{ key = "/", mods = "NONE", action = CustomActions.SearchForward },
		{ key = "?", mods = "SHIFT", action = CustomActions.SearchBackward },

		{ key = "n", mods = "NONE", action = CustomActions.NextMatch },
		{ key = "N", mods = "NONE", action = CustomActions.NextMatch },
		{ key = "n", mods = "SHIFT", action = CustomActions.PriorMatch },
	},

	search_mode = {
		{
			key = "Enter",
			action = act.Multiple({
				act.CopyMode("AcceptPattern"),
				act.ClearSelection,
				act.CopyMode("ClearSelectionMode"),
			}),
		},
		{ key = "Escape", action = CustomActions.ClearPattern },
	},
}

return config

