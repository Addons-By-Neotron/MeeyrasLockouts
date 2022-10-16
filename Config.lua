local mod = LibStub("AceAddon-3.0"):GetAddon("Meeyra's Lockout Tracker")
local L = LibStub("AceLocale-3.0"):GetLocale("MeeyrasLockouts", false)
local R = LibStub("AceConfigRegistry-3.0")
local C = LibStub("AceConfigDialog-3.0")
local DBOpt = LibStub("AceDBOptions-3.0")

mod.defaults = {
	profile = {
		minimapIcon = {}
	}
}

mod.options = {
	main = {
		type = "group",
		name = L["Meeyra's Lockout Tracker"],
		handler = mod,
		set = "SetProfileParam",
		get = "GetProfileParam",
		args = {
			minimapIcon = {
				type = "toggle",
				name = L["Show Minimap Icon"],
				desc = L["Whether or not to show an icon on the minimap in addition or instead of using an LDB display"],
				set = function(_, value)
					mod.gdb.minimapIcon.hide = not value
					mod:ApplyProfile()
				end,
				get = function() return not mod.gdb.minimapIcon.hide  end
			},
		}
	}
}

function mod:InitializeConfig()
	local DBOpt = LibStub("AceDBOptions-3.0")
	mod.options.profile = DBOpt:GetOptionsTable(self.db)

	mod.main = mod:OptReg("Meeyra's Lockout Tracker", mod.options.main)
	mod.text = mod:OptReg(": Profiles", mod.options.profile, L["Profiles"])

	mod:OptReg("Meeyra's Lockout Tracker", {
		name = L["Command Line"],
		type = "group",
		args = {
			icon = {
				type = "execute",
				name = L["Toggle display of minimap button"],
				func = function()
					self.gdb.minimapIcon.hide = not self.gdb.minimapIcon.hide
					mod:ApplyProfile(true)
				end,
				dialogHidden = true
			},
			list = {
				type = "execute",
				name = L["List lockouts in chat window."],
				func = function()
					mod:PrintLockouts()
				end
			},
			announce = {
				type = "execute",
				name = L["List lockouts in party or raid chat."],
				func = function()
					mod:SendLockoutsToChat()
				end

			}
		}
	}, nil, { "lockouts", "meeyra" })

	mod:ApplyProfile(true)
end
