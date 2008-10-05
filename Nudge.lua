if select(2, UnitClass("player")) ~= "HUNTER" then return end

Nudge = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceDB-2.0", "AceConsole-2.0")
local Nudge, self = Nudge, Nudge

local localeTables = {}
function Nudge:L(name, defaultTable)
	if not localeTables[name] then
		localeTables[name] = setmetatable(defaultTable or {}, {__index = function(self, key)
			self[key] = key
			return key
		end})
	end
	return localeTables[name]
end

local localization = (GetLocale() == "koKR") and {
	["Auto Shot"] = "자동 사격",
	["In Range"] = "원거리",
	["Melee"] = "근접",
	["Out of Range"] = "거리 벗어남",
	["Wing Clip"] = "날개 절단",
} or (GetLocale() == "deDE") and {
	["Auto Shot"] = "Automatischer Schuss",
	["In Range"] = "Fernkampf",
	["Melee"] = "Nahkampf",
	["Out of Range"] = "Ausser Reichweite",
	["Wing Clip"] = "Zurechtstutzen",
} or (GetLocale() == "frFR") and {
	["Auto Shot"] = "Tir automatique",
	["In Range"] = "A port\195\169e",
	["Melee"] = "M\195\169lee",
	["Out of Range"] = "Hors de port\195\169e",
	["Wing Clip"] = "Coupure d'ailes",
} or (GetLocale() == "esES") and {
	["Auto Shot"] = "Disparo autom\195\161tico",
	["In Range"] = "Dentro del Alcance",
	["Melee"] = "Cuerpo a cuerpo",
	["Out of Range"] = "Fuera de Alcance",
	["Wing Clip"] = "Cortar alas",
} or (GetLocale() == "zhTW") and {
	["Auto Shot"] = "自動射擊",
	["In Range"] = "射程內",
	["Melee"] = "近戰",
	["Out of Range"] = "射程外",
	["Wing Clip"] = "摔絆",
} or (GetLocale() == "zhCN") and {
	["Auto Shot"] = "自动射击",
	["In Range"] = "射程内",
	["Melee"] = "近战",
	["Out of Range"] = "射程外",
	["Wing Clip"] = "摔绊",
} or {}

local L = Nudge:L("Nudge", localization)

local locked = true
local index

local defaults = {
	width		= 135,
	height		= 35,
	textSize	= 12,
	pos			= {},
	text		= true,
	colors		= {
		melee = {0,1,0,0.7},
		range = {0,0,1,0.7},
		oorange = {1,0,0,0.7}
	}
}

local options = {
	type = "group",
	args = {
		lock = {
			name = "lock",
			desc = "Lock/Unlock the button.",
			type = "toggle",
			get = function() return locked end,
			set = function( v ) locked = v end,
			map = {[false] = "Unlocked", [true] = "Locked"},
		},
		width = {
			name = "width",
			desc = "Set the width of the button.",
			type = 'range',
			min = 10,
			max = 5000,
			step = 1,
			get = function() return Nudge.db.profile.width end,
			set = function( v )
				Nudge.db.profile.width = v
				Nudge:Layout()
			end
		},
		height = {
			name = "height",
			desc = "Set the height of the button.",
			type = 'range',
			min = 5,
			max = 50,
			step = 1,
			get = function() return Nudge.db.profile.height end,
			set = function( v )
				Nudge.db.profile.height = v
				Nudge:Layout()
			end
		},
		font = {
			name = "font",
			desc = "Set the font size.",
			type = 'group',
			args = {
				text = {
					name = "text",
					desc = "Set the font size on the button.",
					type = 'range',
					min = 6,
					max = 32,
					step = 1,
					get = function() return Nudge.db.profile.textSize end,
					set = function( v )
						Nudge.db.profile.textSize = v
						Nudge:Layout()
					end
				}
			}
		},
		text = {
			name = "text",
			desc = "Toggle displaying text on the button.",
			type = 'toggle',
			get = function() return Nudge.db.profile.text end,
			set = function( v )
				Nudge.db.profile.text = v
				Nudge.frame.Range:SetText("")
			end,
			map = {[false] = "Off", [true] = "On"},
		},
		color = {
			name = "color",
			desc = "Set the color of the different button states.",
			type = 'group',
			order = 4,
			args = {
				range = {
					name = "range",
					desc = "Set the color of the in range state.",
					type = 'color',
					get = function()
						local v = Nudge.db.profile.colors.range
						return v.r, v.g, v.b, v.a
					end,
					set = function(r,g,b,a)
						Nudge.db.profile.colors.range = {r,g,b,a}
					end
				},
				oorange = {
					name = "oorange",
					desc = "Set the color of the out of range state.",
					type = 'color',
					get = function()
						local v = Nudge.db.profile.colors.oorange
						return v.r, v.g, v.b, v.a
					end,
					set = function(r,g,b,a)
						Nudge.db.profile.colors.oorange = {r,g,b,a}
					end
				},
				melee = {
					name = "melee",
					desc = "Set the color of the melee state.",
					type = 'color',
					get = function()
						local v = Nudge.db.profile.colors.melee
						return v.r, v.g, v.b, v.a
					end,
					set = function(r,g,b,a)
						Nudge.db.profile.colors.melee = {r,g,b,a}
					end
				},
			}
		}
	}
}

Nudge:RegisterDB("NudgeDB")
Nudge:RegisterDefaults('profile', defaults)
Nudge:RegisterChatCommand( {"/nudge"}, options )

function Nudge:OnEnable()
	self:CreateFrameWork()
	self:RegisterEvent("UNIT_FACTION", "TargetChanged")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "TargetChanged")
end

function Nudge:CreateFrameWork()	
	local frame = CreateFrame("Frame", "NudgeFrame", UIParent)
	self.frame = frame
	frame:Hide()
	
	local pos = self.db.profile.pos

	if pos.x and pos.y then
		local uis = UIParent:GetScale()
		local s = frame:GetEffectiveScale()
		frame:SetPoint("CENTER", pos.x*uis/s, pos.y*uis/s)
	else
		frame:SetPoint("CENTER", 0, 50)
	end

	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function() if not locked then this:StartMoving() end end)
	frame:SetScript("OnDragStop", function(this)
		this:StopMovingOrSizing()
		local pos = self.db.profile.pos
		local x, y = this:GetCenter()
		local s = this:GetEffectiveScale()
		local uis = UIParent:GetScale()
		this:ClearAllPoints()
		x = x*s - GetScreenWidth()*uis/2
		y = y*s - GetScreenHeight()*uis/2
		pos.x, pos.y = x/uis, y/uis
		this:SetPoint("CENTER", UIParent, "CENTER", x/s, y/s)
	end)

	frame:SetClampedToScreen(true)

	frame.Range = frame:CreateFontString("NudgeFontStringText", "OVERLAY")

	self:Layout()
end

function Nudge:Layout()
	local db = self.db.profile
	
	local frame = self.frame
	frame:SetWidth( db.width )
	frame:SetHeight( db.height )

	frame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 8,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		edgeSize = 16,
		insets = {left = 4, right = 4, top = 4, bottom = 4},
	})
	
	frame:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b)
	frame:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b)
	
	local gameFont, _, _ = GameFontHighlightSmall:GetFont()
	
	frame.Range:SetJustifyH("CENTER")
	frame.Range:SetFont( gameFont, db.textSize )
	frame.Range:ClearAllPoints()
	frame.Range:SetPoint("CENTER", frame, "CENTER",0,0)
	frame.Range:SetTextColor( 1,1,1 )
end

function Nudge:TargetChanged()
	if UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target") then
		index = nil
		self:ScheduleRepeatingEvent("Nudge", self.OnUpdate, 0.2, self)
		self.OnUpdate()
		self.frame:Show()
	else
		self:CancelScheduledEvent("Nudge")
		self.frame:Hide()
	end
end

function Nudge:OnUpdate()
	local text
	if IsSpellInRange(L["Wing Clip"]) == 1 then
		if index ~= "melee" then
			text = L["Melee"]
			index = "melee"
		else return end
	elseif IsSpellInRange(L["Auto Shot"]) == 1 then
		if index ~= "range" then
			text = L["In Range"]
			index = "range"
		else return end
	else
		if index ~= "oorange" then
			text = L["Out of Range"]
			index = "oorange"
		else return end
	end

	local db = Nudge.db.profile
	local color = db.colors[index]
	
	local frame = Nudge.frame
	frame:SetBackdropColor(unpack(color))
	frame:SetBackdropBorderColor(unpack(color))

	if db.text then
		Nudge.frame.Range:SetText( text )
	end
end