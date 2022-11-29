--[[
	core.lua
		The primary core of the addon.
--]]

local ADDON_NAME, addon = ...
if not addon.core then addon.core = CreateFrame("frame", ADDON_NAME, UIParent) end

local Core = addon.core

Core:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
if IsLoggedIn() then Core:PLAYER_LOGIN() else Core:RegisterEvent("PLAYER_LOGIN") end

local debugf = tekDebug and tekDebug:GetFrame("xanTank-O-Matic")
local function Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

local xCP = LibStub and LibStub("xCombatParser-1.0", true)
if not xCP then print(ADDON_NAME..": Something went wrong. Please inform the author.") end

local WOW_PROJECT_ID = _G.WOW_PROJECT_ID
local WOW_PROJECT_MAINLINE = _G.WOW_PROJECT_MAINLINE
local WOW_PROJECT_CLASSIC = _G.WOW_PROJECT_CLASSIC
--local WOW_PROJECT_BURNING_CRUSADE_CLASSIC = _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local WOW_PROJECT_WRATH_CLASSIC = _G.WOW_PROJECT_WRATH_CLASSIC

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local IsClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local IsWLK_C = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

Core.data = {}

----------------------	
--Utility
----------------------

local function SaveLayout(frame)
	if not xanTOM_DB then xanTOM_DB = {} end
	local opt = xanTOM_DB[frame:GetName()] or {}

	opt.width = frame:GetWidth()
	opt.height = frame:GetHeight()

	local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
	opt.point = point
	opt.relativePoint = relativePoint
	opt.xOfs = xOfs
	opt.yOfs = yOfs
	
	return opt
end

local function RestoreLayout(frame)
	if not xanTOM_DB then xanTOM_DB = {} end
	local opt = xanTOM_DB[frame:GetName()] or SaveLayout(frame)

	frame:SetWidth(opt.width)
	frame:SetHeight(opt.height)
	frame:ClearAllPoints()
	frame:SetPoint(opt.point, UIParent, opt.relativePoint, opt.xOfs, opt.yOfs)
end

----------------------	
--Core
----------------------

function Core:AddFrame(opts)

	local frame = CreateFrame("ScrollingMessageFrame", "xanTank-O-Matic"..opts.title, UIParent, "BackdropTemplate")
	frame.locked = true
	
	frame.xfont = "Interface\\AddOns\\xanTank-O-Matic\\media\\HOOGE.TTF" --setting
	frame.xfontsize = 16 --setting
	frame.xfontstyle = "OUTLINE" --seting
	
	frame:SetFont(frame.xfont, frame.xfontsize, frame.xfontstyle)
	frame:SetShadowColor(0, 0, 0, 0)
	frame:SetFading(false)
	frame:SetFadeDuration(0.5)
	frame:SetTimeVisible(3) --seting
	frame:SetFadeDuration(3)
	frame:SetMaxLines(64) --setting
	frame:SetSpacing(2)
	frame:SetWidth(opts.width)
	frame:SetHeight(opts.height)
	frame:SetPoint(opts.point, opts.xOfs, opts.yOfs)
	frame:SetMovable(true)
	frame:SetResizable(true)
	if not IsRetail then
		frame:SetMinResize(64, 64)
		frame:SetMaxResize(768, 768)
	else
		frame:SetResizeBounds(64, 64, 768, 768)
	end
	frame:SetClampedToScreen(true)
	frame:SetClampRectInsets(0, 0, frame.xfontsize, 0)
	frame:SetJustifyH(opts.justify)
	frame:SetInsertMode(opts.insertmode)

	-- frame:SetBackdrop(
		-- {bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		-- edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		-- tile = false, tileSize = 0, edgeSize = 2,
		-- insets = {left = 0, right = 0, top = 0, bottom = 0}}
		-- )
				
	-- scroll frame title
	frame.title = frame:CreateFontString(nil, "OVERLAY")
	frame.title:SetFont(frame.xfont, frame.xfontsize, frame.xfontstyle)
	frame.title:SetPoint("BOTTOM", frame , "TOP", 0, 0)
	frame.title:SetText(opts.title)
	frame.title:SetTextColor(1, 1, 0, .9) --setting
	frame.title:Hide()
	
	--create anchor
	frame.anchor = CreateFrame("Frame", "xanTank-O-Matic"..opts.title.."Anchor", frame, "BackdropTemplate")
	
	frame.anchor:SetWidth(25)
	frame.anchor:SetHeight(25)
	frame.anchor:SetMovable(true)
	frame.anchor:SetClampedToScreen(true)
	frame.anchor:EnableMouse(true)

	frame.anchor:ClearAllPoints()
	frame.anchor:SetPoint("TOPLEFT", "xanTank-O-Matic"..opts.title, "TOPLEFT", -25, 0)
	frame.anchor:SetFrameStrata("DIALOG")
	
	frame.anchor:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 5, right = 5, top = 5, bottom = 5 }
	})
	frame.anchor:SetBackdropColor(0.75, 0, 0, 1)
	frame.anchor:SetBackdropBorderColor(0.75, 0, 0, 1)

	frame.anchor:SetScript("OnMouseDown", function(frame, button)
		if frame:GetParent():IsMovable() then
			frame:GetParent().isMoving = true
			frame:GetParent():StartMoving()
		end
	end)

	frame.anchor:SetScript("OnMouseUp", function(frame, button) 
		if ( frame:GetParent().isMoving ) then
			frame:GetParent().isMoving = nil
			frame:GetParent():StopMovingOrSizing()
			SaveLayout(frame:GetParent():GetName())
		end
	end)

	frame.anchor:Hide()
	frame:Show()
	
	Core.frame = frame
end

local function StartConfigmode()

	if not InCombatLockdown() then
		
		Core.configuring = true
		
		local f = Core.frame
		f:SetBackdrop(
			{bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = false, tileSize = 0, edgeSize = 2,
			insets = {left = 0, right = 0, top = 0, bottom = 0}}
			)
		f:SetBackdropColor(.1, .1 , .1, .8)
		f:SetBackdropBorderColor(.1, .1 , .1, .5)

		f.fs = f:CreateFontString(nil, "OVERLAY")
		f.fs:SetFont(f.xfont, f.xfontsize, f.xfontstyle)
		f.fs:SetPoint("BOTTOM", f , "TOP", 0, 0)

		f.fs:SetText(DAMAGE)
		f.fs:SetTextColor(1, .1, .1, .9)

		f.t = f:CreateTexture("ARTWORK")
		f.t:SetPoint("TOPLEFT", f , "TOPLEFT", 1, -1)
		f.t:SetPoint("TOPRIGHT", f , "TOPRIGHT", -1, -19)
		f.t:SetHeight(20)
		f.t:SetTexture( .5, .5, .5)
		f.t:SetAlpha(.3)

		f.d = f:CreateTexture("ARTWORK")
		f.d:SetHeight(16)
		f.d:SetWidth(16)
		f.d:SetPoint("BOTTOMRIGHT", f , "BOTTOMRIGHT",-1, 1)
		f.d:SetTexture( .5, .5, .5)
		f.d:SetAlpha(.3)

		f:EnableMouse(true)
		f:RegisterForDrag("LeftButton")
		f:SetScript("OnDragStart", function(self, button)
			if self.isMoving then return end
			self:StartSizing()
		end)
		if not (Core.scrollable) then
			f:SetScript("OnSizeChanged", function(self)
				if self.isMoving then return end
				self:SetMaxLines(self:GetHeight() / f.xfontsize)
				self:Clear()
			end)
		end
		f:SetScript("OnDragStop", function(self)
			if self.isMoving then return end
			self:StopMovingOrSizing()
			SaveLayout(self:GetName())
		end)
		
		f.anchor:Show()
		Core.grid:Show()
		
	else
		print("can't be configured in combat.")
	end
end

local function EndConfigMode()

	if not InCombatLockdown() then
		
		Core.configuring = false
		
		local f = Core.frame

		f:SetBackdrop(nil)
		f.fs:Hide()
		f.fs=nil
		f.t:Hide()
		f.t=nil
		f.d:Hide()
		f.d=nil

		f:EnableMouse(false)
		f:SetScript("OnDragStart",nil)
		f:SetScript("OnDragStop",nil)

		f.anchor:Hide()
	else
		print("can't be configured in combat.")
	end
end

----------------------	
--Events
----------------------

local function RGBPercToHex(r, g, b)
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end

local missTypeAllowed = {
	--['MISS'] = { 0.50, 0.50, 0.50 },
	['DODGE'] = { 0.50, 0.50, 0.50 },
	['PARRY'] = { 0.50, 0.50, 0.50 },
	--['EVADE'] = { 0.50, 0.50, 0.50 },
	--['IMMUNE'] = { 0.50, 0.50, 0.50 },
	--['DEFLECT'] = { 0.50, 0.50, 0.50 },
	--['REFLECT'] = { 0.50, 0.50, 0.50 },
}

local function AddMessage(message, color)
	if not message or not color then return end

	local r, g, b = 1, 1, 1
	r, g, b = unpack(color)
	
	Core.frame:AddMessage(message, r, g, b)
end

local function IncomingMiss(args)
	if args.missType and not missTypeAllowed[args.missType] then return end
	
	local message = _G["COMBAT_TEXT_"..args.missType]
	
	AddMessage(message, missTypeAllowed[args.missType])
end

local format_resist = "-%s |cFF%s(%s %s)|r"

local function DamageIncoming(args)
	local message

	local resistedAmount, resistType, color

	-- Check for resists (full and partials)
	if (args.blocked or 0) > 0 then
		resistType, resistedAmount = BLOCK, args.amount > 0 and args.blocked
		color = resistedAmount and { 0.60, 0.65, 1.00 } or { 0.75, 0.50, 0.50 } --show color based on full or partial block
		
		if resistType then

			if resistedAmount then
				message = string.format(format_resist, args.amount, RGBPercToHex(unpack(color)), resistType, resistedAmount)
			else
				message = resistType
			end
			
			AddMessage(message, { 0.60, 0.65, 1.00 } )
		end
	end
end

function Core.CombatLogEvent(args)
	--incoming
	if args.atPlayer or args:IsDestinationMyVehicle() then
		if args.suffix == "_MISSED" then
			IncomingMiss(args)
		elseif args.suffix == "_DAMAGE" then
			DamageIncoming(args)
		end
	end
end

function XanTankOMatic_SlashCommand(cmd)

	local a,b,c=strfind(cmd, "(%S+)"); --contiguous string of non-space characters
	
	if a then
		if c and c:lower() == "config" then
			if Core.configuring then
				EndConfigMode()
			else
				StartConfigmode()
			end
			return true
		end
	end

	DEFAULT_CHAT_FRAME:AddMessage(ADDON_NAME, 64/255, 224/255, 208/255)
	DEFAULT_CHAT_FRAME:AddMessage("/xtom config - Display config screen")
end

function Core:PLAYER_LOGIN()
	self.data.playerName = UnitName("player")
	self.data.playerClass = select(2, UnitClass("player"))
	
	--load our grid
	self.grid = self:LoadAlignGrid()

	--create our frame
	self:AddFrame( { title = "MissFrame", point="CENTER", justify="LEFT", xOfs=453, yOfs=131, width=169, height=256, insertmode="BOTTOM" } )

	--register the combat parser
	xCP:RegisterCombat(self.CombatLogEvent)
	
	--restore our frame layouts
	RestoreLayout("xanTank-O-MaticMissFrame")
	
	Debug("Loaded", self.data.playerName, self:GetName())
	
	SLASH_XANTANKOMATIC1 = "/xtom";
	SlashCmdList["XANTANKOMATIC"] = XanTankOMatic_SlashCommand;
	
	local ver = GetAddOnMetadata(ADDON_NAME,"Version") or '1.0'
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF99CC33%s|r [v|cFF20ff20%s|r] loaded:   /xtom", ADDON_NAME, ver or "1.0"))
end
