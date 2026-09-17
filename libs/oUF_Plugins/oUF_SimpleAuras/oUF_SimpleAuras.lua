--[[
# Element: Simple Auras

Handles creation and updating of aura icons.

## Widget

SimpleAuras   - A frame that goes over the unitframe with "SetAllPoints".

## Notes

Yawt.

## Options

.buffs              - Show Buffs (boolean)
.debuffs            - Show Debuffs (boolean)
.weapons            - Show weapon buffs. Works on player only (boolean)
.buffAnchor         - Valid anchors are: "TOP", "BOTTOM", "LEFT", "RIGHT", "INSIDE", "INSIDECENTER"
.debuffAnchor       - Valid anchors are: "TOP", "BOTTOM", "LEFT", "RIGHT", "INSIDE", "INSIDECENTER"
.buffOffset         - Y axis offset for "inside" anchors for buffs
.debuffOffset       - Y axis offset for "inside" anchors for debuffs
.timer              - Show cooldown spiral (string)
                      "all"        - All auras have timers
                      "self"       - Only own auras have timers
                      nil, "none"  - Timers disabled
.disableOCC         - Disables the cooldown count of omnicc (boolean)
.disableBCC         - Disables the blizzard cooldown count (boolean)
.buffSize           - Buff icon size. Defaults to 16 (number)
.debuffSize         - Buff icon size. Defaults to 16 (number)
.largeBuffSize......- Make your own bigger by this amount (number)
.largeDebuffSize....- Make your own bigger by this amount (number)
.onlyShowPlayer     - Shows only auras created by player/vehicle (boolean)
.showType           - Colors the border in the magic type color (boolean)
.showSteal          - Display the white border around stealable buffs (boolean)
.spacing            - Spacing between each icon. Defaults to 0 (number)
.Anchor             - Anchor point for the icons. Defaults to 'BOTTOMLEFT' (string)
                      ""
.buffFilter         - Filter for buffs to display. (string)
.debuffFilter       - Filter for debuffs to display. (string)
.wrapBuffSide       - This works on buffs/debuffs with the "TOP" or "BOTTOM" anchor.
                      "LEFT" or "RIGHT" (string)
.wrapBuff           - Percentage by how much to adjust the side (number, 1 = 100%)
.wrapDebuffSide     - This works on buffs/debuffs with the "TOP" or "BOTTOM" anchor.
                      "LEFT" or "RIGHT" (string)
.wrapDebuff         - Percentage by how much to adjust the side (number, 1 = 100%)
.forceShow          - Show dummy auras (boolean)
.overlay            - Texture for the overlay (string or number)
.maxBuffs           - Maximum number of positive effects to display (default = 32)
.maxDebuffs         - Maximum number of negative effects to display (default = 40)
.buffSpellFilter    - Compiled spell lookup { ids = {}, names = {} } or nil
.buffSpellFilterMode- "disabled", "whitelist", or "blacklist"
.buffSpellFilterMatch- "id" or "name"
.debuffSpellFilter  - Compiled spell lookup { ids = {}, names = {} } or nil
.debuffSpellFilterMode- "disabled", "whitelist", or "blacklist"
.debuffSpellFilterMatch- "id" or "name"

## Attributes

button.caster   - the unit who cast the aura (string)
button.filter   - the filter list used to determine the visibility of the aura (string)
button.isDebuff - indicates if the button holds a debuff (boolean)
button.isPlayer - indicates if the aura caster is the player or their vehicle (boolean)

## Examples

	-- Position and size
	local SimpleAuras = CreateFrame('Frame', nil, self)
	SimpleAuras:SetAllPoints(self)

	-- Register with oUF
	self.SimpleAuras = SimpleAuras
--]]

local _, ns = ...
local oUF = ns.oUF
local AuraCache = ns.AuraCache

local LCD = LibStub("LibClassicDurations", true)
if LCD then
	LCD:Register("LunaUnitFrames")
end
local weaponWatchTimer
local mainHandEnd, mainHandDuration, mainHandCharges, offHandEnd, offHandDuration, offHandCharges

local weaponEnchantData;

-- Things in this table have a duration other than 30 min
if ns.isClassic then 
	weaponEnchantData = {
		[2684] = 3600, -- +100 Attack Power vs Undead (60 min)
		[2685] = 3600, -- +60 Spell Power vs Undead (60 min)
		[263] = 600,   -- Fishing +25 (10 min)
		[264] = 600,   -- Fishing +50 (10 min)
		[265] = 600,   -- Fishing +75 (10 min)
		[266] = 300,   -- Fishing +100 (5 min)
		[5] = 300,     -- Flametongue 1 (5 min)
		[4] = 300,     -- Flametongue 2 (5 min)
		[3] = 300,     -- Flametongue 3 (5 min)
		[523] = 300,   -- Flametongue 4 (5 min)
		[1665] = 300,  -- Flametongue 5 (5 min)
		[1666] = 300,  -- Flametongue 6 (5 min)
		[124] = 10,    -- Flametongue Totem 1 (10 sec)
		[285] = 10,    -- Flametongue Totem 2 (10 sec)
		[543] = 10,    -- Flametongue Totem 3 (10 sec)
		[1683] = 10,   -- Flametongue Totem 4 (10 sec)
		[2] = 300,     -- Frostbrand 1 (5 min)
		[12] = 300,    -- Frostbrand 2 (5 min)
		[524] = 300,   -- Frostbrand 3 (5 min)
		[1667] = 300,  -- Frostbrand 4 (5 min)
		[1668] = 300,  -- Frostbrand 5 (5 min)
		[29] = 300,    -- Rockbiter 1 (5 min)
		[6] = 300,     -- Rockbiter 2 (5 min)
		[1] = 300,     -- Rockbiter 3 (5 min)
		[503] = 300,   -- Rockbiter 4 (5 min)
		[1663] = 300,  -- Rockbiter 5 (5 min)
		[683] = 300,   -- Rockbiter 6 (5 min)
		[1664] = 300,  -- Rockbiter 7 (5 min)
		[283] = 300,   -- Windfury 1 (5 min)
		[284] = 300,   -- Windfury 2 (5 min)
		[525] = 300,   -- Windfury 3 (5 min)
		[1669] = 300,  -- Windfury 4 (5 min)
		[1783] = 10,   -- Windfury Totem 1 (10 sec)
		[563] = 10,    -- Windfury Totem 2 (10 sec)
		[564] = 10,    -- Windfury Totem 3 (10 sec)
		[1003] = 300,  -- Venomhide Poison (5 min)
	}
else
	--TBC
	-- Things in this table have a duration other than 60 min
	weaponEnchantData = {
		[25] = 1800,   -- Shadow Oil (30 min)
		[263] = 600,   -- Fishing +25 (10 min)
		[264] = 600,   -- Fishing +50 (10 min)
		[265] = 600,   -- Fishing +75 (10 min)
		[266] = 600,   -- Fishing +100 (10 min)
		[5] = 1800,     -- Flametongue 1 (30 min)
		[4] = 1800,     -- Flametongue 2 (30 min)
		[3] = 1800,     -- Flametongue 3 (30 min)
		[523] = 1800,   -- Flametongue 4 (30 min)
		[1665] = 1800,  -- Flametongue 5 (30 min)
		[1666] = 1800,  -- Flametongue 6 (30 min)
		[2634] = 1800,  -- Flametongue 7 (30 min)
		[2] = 1800,     -- Frostbrand 1 (30 min)
		[12] = 1800,    -- Frostbrand 2 (30 min)
		[524] = 1800,   -- Frostbrand 3 (30 min)
		[1667] = 1800,  -- Frostbrand 4 (30 min)
		[1668] = 1800,  -- Frostbrand 5 (30 min)
		[2635] = 1800,  -- Frostbrand 6 (30 min)
		[29] = 1800,    -- Rockbiter 1 (30 min)
		[6] = 1800,     -- Rockbiter 2 (30 min)
		[3029] = 1800,  -- Rockbiter 3 (30 min)
		[3032] = 1800,  -- Rockbiter 4 (30 min)
		[3035] = 1800,  -- Rockbiter 5 (30 min)
		[3038] = 1800,  -- Rockbiter 6 (30 min)
		[3041] = 1800,  -- Rockbiter 7 (30 min)
		[3044] = 1800,  -- Rockbiter 8 (30 min)
		[2633] = 1800,  -- Rockbiter 9 (30 min)
		[283] = 1800,   -- Windfury 1 (30 min)
		[284] = 1800,   -- Windfury 2 (30 min)
		[525] = 1800,   -- Windfury 3 (30 min)
		[1669] = 1800,  -- Windfury 4 (30 min)
		[2636] = 1800,  -- Windfury 5 (30 min)
		[124] = 10,    -- Flametongue Totem 1 (10 sec)
		[285] = 10,    -- Flametongue Totem 2 (10 sec)
		[543] = 10,    -- Flametongue Totem 3 (10 sec)
		[1683] = 10,   -- Flametongue Totem 4 (10 sec)
		[2637] = 10,   -- Flametongue Totem 5 (10 sec)
		[1783] = 10,   -- Windfury Totem 1 (10 sec)
		[563] = 10,    -- Windfury Totem 2 (10 sec)
		[564] = 10,    -- Windfury Totem 3 (10 sec)
		[2638] = 10,   -- Windfury Totem 4 (10 sec)
		[2639] = 10,   -- Windfury Totem 5 (10 sec)
		[1003] = 300,  -- Venomhide Poison (5 min)
		[3093] = 300,  -- Scourgebane (5 min)
		[3102] = 1800, -- Bloodboil Poison (30 min)
	}
end

local WHITE_COLOR = { 1, 1, 1 }
local STEAL_TEX = "Interface\\TargetingFrame\\UI-TargetingFrame-Stealable"
local DEFAULT_OVERLAY_TEX = [[Interface\Buttons\UI-Debuff-Overlays]]

local function setShown(button, shown)
	if button._shown ~= shown then
		button._shown = shown
		if shown then
			button:Show()
		else
			button:Hide()
		end
	end
end

local function setCooldown(button, element, shown, start, duration)
	if button._cdShown ~= shown then
		button._cdShown = shown
		if shown then
			button.cd.noCooldownCount = element.disableOCC
			button.cd:SetHideCountdownNumbers(element.disableBCC)
			button.cd:Show()
		else
			button.cd:Hide()
		end
	end
	if shown and (button._cdStart ~= start or button._cdDur ~= duration) then
		button._cdStart = start
		button._cdDur = duration
		button.cd:SetCooldown(start, duration)
		if not element.disableBCC and not (_G.OmniCC and not element.disableOCC) then
			button._bccSize = nil
		end
	end
end

local function setIconTexture(button, texture)
	if button._iconTex ~= texture then
		button._iconTex = texture
		button.icon:SetTexture(texture)
	end
end

local function setOverlay(button, element, isStealable, debuffType)
	local mode = isStealable and element.showSteal and "steal"
		or element.showType and debuffType and ("type:" .. debuffType)
		or element.overlay and "custom"
		or "default"
	if button._overlayMode ~= mode then
		button._overlayMode = mode
		if mode == "steal" then
			button.overlay:SetVertexColor(1, 1, 1)
			button.overlay:SetTexture(STEAL_TEX)
			button.overlay:SetTexCoord(0.1, 0.95, 0.1, 0.95)
			button.overlay:SetBlendMode("ADD")
		else
			local color = element.showType and oUF.colors.dispel[debuffType] or WHITE_COLOR
			button.overlay:SetVertexColor(color[1], color[2], color[3])
			button.overlay:SetBlendMode("BLEND")
			if element.overlay then
				button.overlay:SetTexture(element.overlay)
				button.overlay:SetTexCoord(0, 1, 0, 1)
			else
				button.overlay:SetTexture(DEFAULT_OVERLAY_TEX)
				button.overlay:SetTexCoord(0.306875, 0.5703125, 0, 0.515625)
			end
		end
	end
end

local function setCount(button, count, fontSize)
	local text = count > 1 and count or ""
	if button._countText ~= text then
		button._countText = text
		button.count:SetText(text)
	end
	if fontSize and button.buffcountfontsize ~= fontSize then
		button.count:SetFont(button.count:GetFont(), fontSize, "OUTLINE")
		button.buffcountfontsize = fontSize
	end
end

local function setButtonSize(button, size)
	if button._size ~= size then
		button._size = size
		button:SetSize(size, size)
	end
end

local function CheckBlizzardCooldownTextOverflow(element, button)
	--OmniCC always prevents blizzard timers so we dont need to do
	-- this if it's installed and not disabled
    if element.disableBCC or (_G.OmniCC and not element.disableOCC) then return end

	local button_width = button._size or button:GetWidth()
	if button._bccSize == button_width then return end
	button._bccSize = button_width

	if not button.cdFontString then
		-- Cache the cooldown text font string
		for _, region in ipairs({ button.cd:GetRegions() }) do
			if region:GetObjectType() == "FontString" then
				button.cdFontString = region
				break
			end
		end
	end

	local fs = button.cdFontString

	local _, oldFontSize, _ = fs:GetFont()
	local fontSize = math.max(8, button_width^0.95 * 0.42)

	if(oldFontSize ~= fontSize) then
		--only update when font size changed
		local fontName = fs:GetFont()
		fs:SetFont(fontName, fontSize, 'OUTLINE')
	end

	local text_width = fs:GetStringWidth()

    if (button_width < 18.5)  then
        button.cd:SetHideCountdownNumbers(true)
    else
        button.cd:SetHideCountdownNumbers(false)
    end
end

local function UpdateTooltip(self)
	if GameTooltip:IsForbidden() then return end
	if self.filter == "TEMP" then
		GameTooltip:SetInventoryItem("player", self:GetID())
	else
		GameTooltip:SetUnitAura(self:GetParent():GetParent().__owner.unit, self:GetID(), self.filter)
	end
end

local function onEnter(self)
	if GameTooltip:IsForbidden() or not self:IsVisible() then return end
	GameTooltip:SetOwner(self, self:GetParent():GetParent().tooltipAnchor)
	self:UpdateTooltip()
end

local function onLeave()
	if GameTooltip:IsForbidden() then return end
	GameTooltip:Hide()
end

local function cancelAura(self, button)
	local unit = self:GetParent():GetParent().__owner.unit
	if button ~= "RightButton" or InCombatLockdown() or self.filter ~= "HELPFUL" or not UnitIsUnit("player", unit) then
		return
	end
	CancelUnitBuff(unit, self:GetID(), self.filter)
end

local function createAuraIcon(element, index)
	local button = CreateFrame("Button", element:GetName() .. "Button" .. index, element)
	button:RegisterForClicks("RightButtonUp")

	local cd = CreateFrame("Cooldown", "$parentCooldown", button, "CooldownFrameTemplate")
	cd:SetDrawEdge(false)
	cd:SetDrawSwipe(true)
	cd:SetReverse(true)
	cd:SetSwipeColor(0, 0, 0, 0.8)
	cd:SetAllPoints()

	local icon = button:CreateTexture(nil, 'BORDER')
	icon:SetAllPoints()

	local countFrame = CreateFrame('Frame', nil, button)
	countFrame:SetAllPoints(button)
	countFrame:SetFrameLevel(cd:GetFrameLevel() + 1)

	local count = countFrame:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal')
	local fontName = count:GetFont()
	count:SetFont(fontName, 10, "OUTLINE")
	count:SetPoint('BOTTOMRIGHT', countFrame, 'BOTTOMRIGHT', 3, 0)

	local overlay = button:CreateTexture(nil, 'OVERLAY')
	overlay:SetAllPoints()
	button.overlay = overlay

	button.UpdateTooltip = UpdateTooltip
	button:SetScript('OnEnter', onEnter)
	button:SetScript('OnLeave', onLeave)

	button.icon = icon
	button.count = count
	button.cd = cd
	--[[ Callback: SimpleAuras:PostCreateIcon(button)
	Called after a new aura button has been created.

	* self   - the widget holding the aura buttons
	* button - the newly created aura button (Button)
	--]]
	if(element:GetParent().PostCreateIcon) then element:GetParent():PostCreateIcon(button) end

	return button
end

local function getIconSize(element, isDebuff, isPlayer)
	local preventGrowth
	if isDebuff then
		preventGrowth = element.debuffAnchor == "INFRAME" or element.debuffAnchor == "INFRAMECENTER"
		if not preventGrowth and element.largeDebuffSize ~= 0 and isPlayer then
			return element.debuffSize + element.largeDebuffSize
		end
		return element.debuffSize or 16
	end
	preventGrowth = element.buffAnchor == "INFRAME" or element.buffAnchor == "INFRAMECENTER"
	if not preventGrowth and element.largeBuffSize ~= 0 and isPlayer then
		return element.buffSize + element.largeBuffSize
	end
	return element.buffSize or 16
end

local function updateIcon(element, unit, record, position, filter, isDebuff, index)
	local auras = isDebuff and element.debuffFrame or element.buffFrame
	local name, texture, count, debuffType, duration, expiration, caster, isStealable

	if filter == "TEMP" then
		if index == 16 then
			name, texture, count, debuffType, duration, expiration, caster = "MainHandEnchant", GetInventoryItemTexture("player", index), mainHandCharges, nil, mainHandDuration, mainHandEnd, "player"
		else
			name, texture, count, debuffType, duration, expiration, caster = "OffHandEnchant", GetInventoryItemTexture("player", index), offHandCharges, nil, offHandDuration, offHandEnd, "player"
		end
	elseif record then
		name = record.name
		texture = record.icon
		count = record.count
		debuffType = record.debuffType
		duration = record.duration
		expiration = record.expirationTime
		caster = record.caster
		isStealable = record.isStealable
		index = record.index or index
	else
		name, texture, count, debuffType, duration, expiration, caster, isStealable = ns.UnitAura(unit, index, filter)
	end

	if element.forceShow or element.forceCreate then
		local spellID = filter == "HELPFUL" and 28059 or filter == "TEMP" and 13852 or 28084
		name = C_Spell.GetSpellName(spellID)
		texture = C_Spell.GetSpellTexture(spellID)

		if element.forceShow then
			count, debuffType, duration, expiration, caster, isStealable = filter == "TEMP" and 1 or index, "Magic", 0, 60, (math.random(0, 1) > 0) and "player", nil
		end
	end

	if not name then return end

	local button = auras[position]
	if not button then
		auras.createdIcons = auras.createdIcons + 1
		button = (element.CreateIcon or createAuraIcon)(auras, position)
		auras[auras.createdIcons] = button
		if not auras[auras.createdIcons] then
			auras.createdIcons = auras.createdIcons - 1
		end
	end

	if not button then return end

	local isPlayer = caster == "player" or caster == "vehicle"
	if button._spellID == (record and record.spellID)
		and button._countVal == (count or 0)
		and button._exp == expiration
		and button._iconTex == texture
		and button.caster == caster
		and button._debuffType == debuffType
		and button._auraIndex == index
		and button._shown
	then
		return
	end

	button.caster = caster
	button.filter = filter
	button.isDebuff = isDebuff
	button.isPlayer = isPlayer
	button._spellID = record and record.spellID
	button._countVal = count or 0
	button._exp = expiration
	button._debuffType = debuffType
	button._auraIndex = index
	if not button._hasCancel then
		button._hasCancel = true
		button:SetScript("OnClick", cancelAura)
	end

	local showTimer = expiration and expiration > 0 and duration and duration > 0
		and (element.timer == "all" or element.timer == "self" and isPlayer)
	if button.cd then
		if showTimer then
			setCooldown(button, element, true, expiration - duration, duration)
		else
			setCooldown(button, element, false)
		end
	end

	if button.overlay then
		setOverlay(button, element, isStealable, debuffType)
	end

	if button.icon then
		setIconTexture(button, texture)
	end

	setCount(button, count or 0, element.buffcountfontsize or 10)
	setButtonSize(button, getIconSize(element, isDebuff, isPlayer))

	if button:GetID() ~= index then
		button:SetID(index)
	end
	setShown(button, true)

	if element.PostUpdateIcon then
		element:PostUpdateIcon(unit, button, index, position, duration, expiration, debuffType, isStealable)
	end
	CheckBlizzardCooldownTextOverflow(element, button)
end

local function hideTrailingAuras(auraFrame, currentSlot)
	while auraFrame[currentSlot] do
		setShown(auraFrame[currentSlot], false)
		currentSlot = currentSlot + 1
	end
end

local function passesPlayerFilter(filterMode, record)
	return filterMode ~= 2 or record.caster == "player" or record.isPlayer
end

local function passesSpellFilter(spellFilter, spellMode, matchBy, spellID, lowerName)
	if not spellFilter or spellMode == "disabled" then
		return true
	end
	local inList
	if matchBy == "name" then
		inList = lowerName and spellFilter.names[lowerName]
	else
		inList = spellID and spellFilter.ids[spellID]
	end
	if spellMode == "whitelist" then
		return inList
	end
	if spellMode == "blacklist" then
		return not inList
	end
	return true
end

local function updateAurasFromSnapshot(element, unit, list, count, isDebuff, filterMode, maxAuras, filter, currentSlot)
	local spellFilter = isDebuff and element.debuffSpellFilter or element.buffSpellFilter
	local spellMode = isDebuff and element.debuffSpellFilterMode or element.buffSpellFilterMode
	local matchBy = isDebuff and element.debuffSpellFilterMatch or element.buffSpellFilterMatch
	local visibleCap = maxAuras or count
	for i = 1, count do
		if currentSlot > visibleCap then
			break
		end
		local record = list[i]
		if passesPlayerFilter(filterMode, record)
			and passesSpellFilter(spellFilter, spellMode, matchBy, record.spellID, record.lowerName)
		then
			updateIcon(element, unit, record, currentSlot, filter, isDebuff, record.index)
			currentSlot = currentSlot + 1
		end
	end
	return currentSlot
end

local function UpdateAuras(self, event, unit)
	if self.unit ~= unit then return end

	local element = self.SimpleAuras
	if not element then return end

	if element.PreUpdate then element:PreUpdate(unit) end

	local snap = AuraCache:Touch(unit, { classFilter = element.buffFilter == 3 })
	if not AuraCache:IsReady(unit) and not element._waitingCache then
		element._waitingCache = true
		AuraCache:WhenReady(unit, function()
			element._waitingCache = nil
			if element.ForceUpdate then
				element:ForceUpdate()
			end
		end)
	end
	local maxBuffs = element.maxBuffs or 32
	local maxDebuffs = element.maxDebuffs or 40
	local buffFilter = "HELPFUL"
	local debuffFilter = "HARMFUL"
	local buffs = element.buffFrame
	local currentSlot = 1

	if element.buffs then
		if element.forceShow then
			for i = 1, maxBuffs do
				updateIcon(element, unit, nil, currentSlot, buffFilter, false, i)
				currentSlot = currentSlot + 1
			end
		elseif element.buffFilter == 3 and snap.status ~= "empty"
			and (snap.canAssist or not snap.isVisible) then
			currentSlot = updateAurasFromSnapshot(element, unit, snap.classHelpful, snap.classHelpfulCount or 0, false, 3, maxBuffs, buffFilter, currentSlot)
		else
			currentSlot = updateAurasFromSnapshot(element, unit, snap.helpful, snap.helpfulCount, false, element.buffFilter, maxBuffs, buffFilter, currentSlot)
		end
	end

	if element.weapons then
		if mainHandDuration or element.forceShow then
			updateIcon(element, "player", nil, currentSlot, "TEMP", false, 16)
			currentSlot = currentSlot + 1
		end
		if offHandDuration or element.forceShow then
			updateIcon(element, "player", nil, currentSlot, "TEMP", false, 17)
			currentSlot = currentSlot + 1
		end
	end

	element._visibleBuffs = currentSlot - 1
	hideTrailingAuras(buffs, currentSlot)

	local debuffs = element.debuffFrame
	currentSlot = 1
	if element.debuffs then
		if element.forceShow then
			for i = 1, maxDebuffs do
				updateIcon(element, unit, nil, currentSlot, debuffFilter, true, i)
				currentSlot = currentSlot + 1
			end
		elseif element.debuffFilter == 3 then
			currentSlot = updateAurasFromSnapshot(element, unit, snap.dispels, snap.dispelCount or 0, true, 3, maxDebuffs, debuffFilter, currentSlot)
		else
			currentSlot = updateAurasFromSnapshot(element, unit, snap.harmful, snap.harmfulCount, true, element.debuffFilter, maxDebuffs, debuffFilter, currentSlot)
		end
	end

	element._visibleDebuffs = currentSlot - 1
	hideTrailingAuras(debuffs, currentSlot)

	if element.PostUpdate then element:PostUpdate(unit) end
end

local function Update(self, event, unit)
	if self.unit ~= unit then return end

	if self.SimpleAuras.forceShow and event == "OnUpdate" then return end

	UpdateAuras(self, event, unit)

	local element = self.SimpleAuras
	local frameWidth = self:GetWidth() - 2
	local frameHeight, rowHeight = 1, 0
	local button, firstButton, lastButton, rowLenght, buttonSize
	local buffOffset, debuffOffset = 0, 0
	local visibleBuffs = element._visibleBuffs or 0
	local visibleDebuffs = element._visibleDebuffs or 0

	if element.wrapBuffSide == "LEFT" then
		if element.wrapBuff > 1 then
			buffOffset = -((element.wrapBuff - 1) * frameWidth)
		else
			buffOffset = frameWidth * (1 - element.wrapBuff)
		end
	end
	if element.wrapDebuffSide == "LEFT" then
		if element.wrapDebuff > 1 then
			debuffOffset = -((element.wrapDebuff - 1) * frameWidth)
		else
			debuffOffset = frameWidth * (1 - element.wrapDebuff)
		end
	end
	
	local buffs = element.buffFrame
	local buffLayoutKey = string.format(
		"%d:%d:%s:%s:%d:%d:%d:%s:%f:%f:%d:%d",
		visibleBuffs, frameWidth, element.buffAnchor or "", element.wrapBuffSide or "",
		element.spacing or 0, element.buffSize or 16, element.largeBuffSize or 0,
		tostring(element.buffs), element.wrapBuff or 1, buffOffset, element.buffOffset or 0,
		element.weapons and 1 or 0, element.buffcountfontsize or 10
	)
	local debuffLayoutKey = string.format(
		"%d:%d:%s:%s:%d:%d:%d:%s:%f:%f:%d:%s",
		visibleDebuffs, frameWidth, element.debuffAnchor or "", element.wrapDebuffSide or "",
		element.spacing or 0, element.debuffSize or 16, element.largeDebuffSize or 0,
		tostring(element.debuffs), element.wrapDebuff or 1, debuffOffset, element.debuffOffset or 0,
		element.buffAnchor == element.debuffAnchor and 1 or 0, element.buffAnchor or ""
	)

	local layoutBuff = element._buffLayoutKey ~= buffLayoutKey
	local layoutDebuff = element._debuffLayoutKey ~= debuffLayoutKey
	if not layoutBuff and not layoutDebuff then
		return
	end

	if layoutBuff then
		element._buffLayoutKey = buffLayoutKey
		buffs:ClearAllPoints()
	if element.buffs or element.weapons then
		if element.buffAnchor == "BOTTOM" then
			buffs:SetPoint("TOP", element, "BOTTOM", 1 + buffOffset, -1)
			for i=1, buffs.createdIcons do
				button = buffs[i]
				button:EnableMouse(true)
				buttonSize = button:GetWidth()
				if not button:IsVisible() then break end
				button:ClearAllPoints()
				if i == 1 then
					button:SetPoint("TOPLEFT", buffs, "TOPLEFT")
					rowLenght = buttonSize
					rowHeight = buttonSize
					firstButton = button
				elseif (rowLenght + buttonSize + element.spacing) > (frameWidth * element.wrapBuff) then
					rowLenght = buttonSize
					button:SetPoint("TOPLEFT", firstButton, "TOPLEFT", 0, (-(element.spacing)-rowHeight))
					firstButton = button
					frameHeight = frameHeight + element.spacing + rowHeight
					rowHeight = buttonSize
				else
					button:SetPoint("TOPLEFT", lastButton, "TOPRIGHT", element.spacing, 0)
					rowLenght = rowLenght + buttonSize + element.spacing
					rowHeight = math.max(rowHeight, buttonSize)
				end
				lastButton = button
			end
			frameHeight = frameHeight + rowHeight
		elseif element.buffAnchor == "TOP" then
			buffs:SetPoint("BOTTOM", element, "TOP", 1 + buffOffset, 1)
			for i=1, buffs.createdIcons do
				button = buffs[i]
				button:EnableMouse(true)
				if not button:IsVisible() then break end
				buttonSize = button:GetWidth()
				button:ClearAllPoints()
				if i == 1 then
					button:SetPoint("BOTTOMLEFT", buffs, "BOTTOMLEFT")
					rowLenght = buttonSize
					rowHeight = buttonSize
					firstButton = button
				elseif (rowLenght + buttonSize + element.spacing) > (frameWidth * element.wrapBuff) then
					rowLenght = buttonSize
					button:SetPoint("BOTTOMLEFT", firstButton, "BOTTOMLEFT", 0, (element.spacing+rowHeight))
					firstButton = button
					frameHeight = frameHeight + element.spacing + rowHeight
					rowHeight = buttonSize
				else
					button:SetPoint("BOTTOMLEFT", lastButton, "BOTTOMRIGHT", element.spacing, 0)
					rowLenght = rowLenght + buttonSize + element.spacing
					rowHeight = math.max(rowHeight, buttonSize)
				end
				lastButton = button
			end
			frameHeight = frameHeight + rowHeight
		elseif element.buffAnchor == "LEFT" then
			buffs:SetPoint("BOTTOMRIGHT", element, "LEFT", -1, 0.5)
			for i=1, buffs.createdIcons do
				button = buffs[i]
				button:EnableMouse(true)
				if not button:IsVisible() then break end
				buttonSize = button:GetWidth()
				button:ClearAllPoints()
				if i == 1 then
					button:SetPoint("BOTTOMRIGHT", buffs, "BOTTOMRIGHT")
					rowLenght = buttonSize
					rowHeight = buttonSize
					firstButton = button
				elseif (rowLenght + buttonSize + element.spacing) > (frameWidth * element.wrapBuff) then
					rowLenght = buttonSize
					button:SetPoint("BOTTOMRIGHT", firstButton, "BOTTOMRIGHT", 0, (element.spacing+rowHeight))
					firstButton = button
					frameHeight = frameHeight + element.spacing + rowHeight
					rowHeight = buttonSize
				else
					button:SetPoint("BOTTOMRIGHT", lastButton, "BOTTOMLEFT", -(element.spacing), 0)
					rowLenght = rowLenght + buttonSize + element.spacing
					rowHeight = math.max(rowHeight, buttonSize)
				end
				lastButton = button
			end
			frameHeight = frameHeight + rowHeight
		elseif element.buffAnchor == "RIGHT" then
			buffs:SetPoint("BOTTOMLEFT", element, "RIGHT", 1, 0.5)
			for i=1, buffs.createdIcons do
				button = buffs[i]
				button:EnableMouse(true)
				if not button:IsVisible() then break end
				buttonSize = button:GetWidth()
				button:ClearAllPoints()
				if i == 1 then
					button:SetPoint("BOTTOMLEFT", buffs, "BOTTOMLEFT")
					rowLenght = buttonSize
					rowHeight = buttonSize
					firstButton = button
				elseif (rowLenght + buttonSize + element.spacing) > (frameWidth * element.wrapBuff) then
					rowLenght = buttonSize
					button:SetPoint("BOTTOMLEFT", firstButton, "BOTTOMLEFT", 0, (element.spacing+rowHeight))
					firstButton = button
					frameHeight = frameHeight + element.spacing + rowHeight
					rowHeight = buttonSize
				else
					button:SetPoint("BOTTOMLEFT", lastButton, "BOTTOMRIGHT", element.spacing, 0)
					rowLenght = rowLenght + buttonSize + element.spacing
					rowHeight = math.max(rowHeight, buttonSize)
				end
				lastButton = button
			end
			frameHeight = frameHeight + rowHeight
		elseif element.buffAnchor == "INFRAME" then
			frameHeight = self:GetHeight() / 2
			for i=1, buffs.createdIcons do
				button = buffs[i]
				button:EnableMouse(false)
				if not button:IsVisible() then break end
				button:ClearAllPoints()
				if i == 1 then
					button:SetPoint("TOPLEFT", element, "TOPLEFT", 1, -1 + (element.buffOffset or 0))
					rowLenght = element.buffSize + element.spacing
					firstButton = button
				elseif (rowLenght + element.buffSize) <= frameWidth then
					rowLenght = rowLenght + element.buffSize + element.spacing
					button:SetPoint("LEFT", firstButton, "RIGHT", element.spacing, 0)
					firstButton = button
				else
					button:Hide()
				end
			end
		else
			frameHeight = self:GetHeight() / 2
			for i=1, buffs.createdIcons do
				button = buffs[i]
				button:EnableMouse(false)
				if not button:IsVisible() then break end
				button:ClearAllPoints()
				if i == 1 then
					button:SetPoint("BOTTOMLEFT", element, "LEFT", 1, (element.buffOffset or 0))
					rowLenght = element.buffSize + element.spacing
					firstButton = button
				elseif (rowLenght + element.buffSize) <= frameWidth then
					rowLenght = rowLenght + element.buffSize + element.spacing
					button:SetPoint("BOTTOMLEFT", firstButton, "BOTTOMRIGHT", element.spacing, 0)
					firstButton = button
				else
					button:Hide()
				end
			end
		end
	end
		buffs:SetSize(frameWidth, frameHeight)
	end

	local debuffs = element.debuffFrame
	local anchorFrame = (element.buffs or element.weapons) and element.buffAnchor == element.debuffAnchor and buffs or element
	local offset = element.buffAnchor ~= element.debuffAnchor and 1 or 0
	frameHeight = 1
	rowHeight = 0

	if layoutDebuff then
		element._debuffLayoutKey = debuffLayoutKey
	debuffs:ClearAllPoints()
	if element.debuffs then
		if element.debuffAnchor == "BOTTOM" then
			debuffs:SetPoint("TOP", anchorFrame, "BOTTOM", offset + debuffOffset , -1)
			for i=1, debuffs.createdIcons do
				button = debuffs[i]
				button:EnableMouse(true)
				if not button:IsVisible() then break end
				buttonSize = button:GetWidth()
				button:ClearAllPoints()
				if i == 1 then
					button:SetPoint("TOPLEFT", debuffs, "TOPLEFT")
					rowLenght = buttonSize
					rowHeight = buttonSize
					firstButton = button
				elseif (rowLenght + buttonSize + element.spacing) > (frameWidth * element.wrapDebuff) then
					rowLenght = buttonSize
					button:SetPoint("TOPLEFT", firstButton, "TOPLEFT", 0, (-(element.spacing)-rowHeight))
					firstButton = button
					frameHeight = frameHeight + element.spacing + rowHeight
					rowHeight = buttonSize
				else
					button:SetPoint("TOPLEFT", lastButton, "TOPRIGHT", element.spacing, 0)
					rowLenght = rowLenght + buttonSize + element.spacing
					rowHeight = math.max(rowHeight, buttonSize)
				end
				lastButton = button
			end
			frameHeight = frameHeight + rowHeight
		elseif element.debuffAnchor == "TOP" then
			debuffs:SetPoint("BOTTOM", anchorFrame, "TOP", offset + debuffOffset , 1)
			for i=1, debuffs.createdIcons do
				button = debuffs[i]
				button:EnableMouse(true)
				if not button:IsVisible() then break end
				buttonSize = button:GetWidth()
				button:ClearAllPoints()
				if i == 1 then
					button:SetPoint("BOTTOMLEFT", debuffs, "BOTTOMLEFT")
					rowLenght = buttonSize
					rowHeight = buttonSize
					firstButton = button
				elseif (rowLenght + buttonSize + element.spacing) > (frameWidth * element.wrapDebuff) then
					rowLenght = buttonSize
					button:SetPoint("BOTTOMLEFT", firstButton, "BOTTOMLEFT", 0, (element.spacing+rowHeight))
					firstButton = button
					frameHeight = frameHeight + element.spacing + rowHeight
					rowHeight = buttonSize
				else
					button:SetPoint("BOTTOMLEFT", lastButton, "BOTTOMRIGHT", element.spacing, 0)
					rowLenght = rowLenght + buttonSize + element.spacing
					rowHeight = math.max(rowHeight, buttonSize)
				end
				lastButton = button
			end
			frameHeight = frameHeight + rowHeight
		elseif element.debuffAnchor == "LEFT" then
			debuffs:SetPoint("TOPRIGHT", element, "LEFT", -1, -0.5)
			for i=1, debuffs.createdIcons do
				button = debuffs[i]
				button:EnableMouse(true)
				if not button:IsVisible() then break end
				buttonSize = button:GetWidth()
				button:ClearAllPoints()
				if i == 1 then
					button:SetPoint("TOPRIGHT", debuffs, "TOPRIGHT")
					rowLenght = buttonSize
					rowHeight = buttonSize
					firstButton = button
				elseif (rowLenght + buttonSize + element.spacing) > (frameWidth * element.wrapDebuff) then
					rowLenght = buttonSize
					button:SetPoint("TOPRIGHT", firstButton, "TOPRIGHT", 0, (-(element.spacing)-rowHeight))
					firstButton = button
					frameHeight = frameHeight + element.spacing + rowHeight
					rowHeight = buttonSize
				else
					button:SetPoint("TOPRIGHT", lastButton, "TOPLEFT", -(element.spacing), 0)
					rowLenght = rowLenght + buttonSize + element.spacing
					rowHeight = math.max(rowHeight, buttonSize)
				end
				lastButton = button
			end
			frameHeight = frameHeight + rowHeight
		elseif element.debuffAnchor == "RIGHT" then
			debuffs:SetPoint("TOPLEFT", element, "RIGHT", 1, -0.5)
			for i=1, debuffs.createdIcons do
				button = debuffs[i]
				button:EnableMouse(true)
				if not button:IsVisible() then break end
				buttonSize = button:GetWidth()
				button:ClearAllPoints()
				if i == 1 then
					button:SetPoint("TOPLEFT", debuffs, "TOPLEFT")
					rowLenght = buttonSize
					rowHeight = buttonSize
					firstButton = button
				elseif (rowLenght + buttonSize + element.spacing) > (frameWidth * element.wrapDebuff) then
					rowLenght = buttonSize
					button:SetPoint("TOPLEFT", firstButton, "TOPLEFT", 0, (-(element.spacing)-rowHeight))
					firstButton = button
					frameHeight = frameHeight + element.spacing + rowHeight
					rowHeight = buttonSize
				else
					button:SetPoint("TOPLEFT", lastButton, "TOPRIGHT", element.spacing, 0)
					rowLenght = rowLenght + buttonSize + element.spacing
					rowHeight = math.max(rowHeight, buttonSize)
				end
				lastButton = button
			end
			frameHeight = frameHeight + rowHeight
		elseif element.debuffAnchor == "INFRAME" then
			for i=1, debuffs.createdIcons do
				button = debuffs[i]
				button:EnableMouse(false)
				if not button:IsVisible() then break end
				button:ClearAllPoints()
				if i == 1 then
					button:SetPoint("BOTTOMLEFT", element, "BOTTOMLEFT", 1, 1 + (element.debuffOffset or 0))
					rowLenght = element.debuffSize + element.spacing
					firstButton = button
				elseif (rowLenght + element.debuffSize) <= frameWidth then
					rowLenght = rowLenght + element.debuffSize + element.spacing
					button:SetPoint("LEFT", firstButton, "RIGHT", element.spacing, 0)
					firstButton = button
				else
					button:Hide()
				end
			end
		else
			for i=1, debuffs.createdIcons do
				button = debuffs[i]
				button:EnableMouse(false)
				if not button:IsVisible() then break end
				button:ClearAllPoints()
				if i == 1 then
					button:SetPoint("TOPLEFT", element, "LEFT", 1, (element.debuffOffset or 0))
					rowLenght = element.debuffSize + element.spacing
					firstButton = button
				elseif (rowLenght + element.debuffSize) <= frameWidth then
					rowLenght = rowLenght + element.debuffSize + element.spacing
					button:SetPoint("TOPLEFT", firstButton, "TOPRIGHT", element.spacing, 0)
					firstButton = button
				else
					button:Hide()
				end
			end
		end
	end
		debuffs:SetSize(frameWidth, frameHeight)
	end
end

local function ForceUpdate(element)
	return Update(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local playerFrames = {}
local function UpdateWeaponEnchants(self, silent)
	weaponWatchTimer = nil
	local defaultDuration = ns.isClassic and 1800 or 3600
	
	local hasMainHandEnchant, mainHandExpiration, mainHandChargeNum, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandChargeNum, offHandEnchantId = GetWeaponEnchantInfo()
	if hasMainHandEnchant then
		mainHandEnd = GetTime() + (mainHandExpiration / 1000)
		mainHandDuration = weaponEnchantData[mainHandEnchantID] or defaultDuration
		mainHandCharges = mainHandChargeNum
	else
		mainHandEnd = nil
		mainHandDuration = nil
		mainHandCharges = nil
	end
	if hasOffHandEnchant then
		offHandEnd = GetTime() + (offHandExpiration / 1000)
		offHandDuration = weaponEnchantData[offHandEnchantId] or defaultDuration
		offHandCharges = offHandChargeNum
	else
		offHandEnd = nil
		offHandDuration = nil
		offHandCharges = nil
	end
	
	if silent then return end
	for _, frame in pairs(playerFrames) do
		Update(frame, "UNIT_AURA", "player")
	end
end

local function SetWeaponUpdateTimer(self, event, unit)
	if unit ~= "player" then return end
	if not weaponWatchTimer then
		weaponWatchTimer = true
		C_Timer.After(1, UpdateWeaponEnchants)
	end
end

local function OnSizeChanged(self)
	local frame = self:GetParent()
	Update(frame, "OnSizeChanged", frame.unit)
end

local function Enable(self)

	if self.SimpleAuras then
		local element = self.SimpleAuras

		element.__owner = self
		element.ForceUpdate = ForceUpdate

		-- Avoid parenting GameTooltip to frames with anchoring restrictions,
		-- otherwise it'll inherit said restrictions which will cause issues
		-- with its further positioning, clamping, etc
		if(not pcall(self.GetCenter, self)) then
			element.tooltipAnchor = "ANCHOR_CURSOR"
		else
			element.tooltipAnchor = element.tooltipAnchor or 'ANCHOR_BOTTOMRIGHT'
		end

		self:RegisterEvent("UNIT_AURA", Update)
		self:RegisterEvent("UNIT_CONNECTION", Update)
		self:RegisterEvent("PARTY_MEMBER_ENABLE", Update)
		self:RegisterEvent("PARTY_MEMBER_DISABLE", Update)
		
		if self.unit == "player" and not self.__eventless then
			playerFrames[self] = self
			self:RegisterEvent("UNIT_INVENTORY_CHANGED", SetWeaponUpdateTimer)
			UpdateWeaponEnchants(self, true)
		elseif self.unit ~= "player" then
			if LCD and LCD.RegisterCallback then
				LCD.RegisterCallback("LUF", "UNIT_BUFF", function(event, unit)
					UpdateAuras(element, "UNIT_AURA", unit)
				end)
			end
		end

		element.buffFrame = element.buffFrame or CreateFrame("Frame", "$parentBuffFrame", element)
		element.buffFrame.createdIcons = element.buffFrame.createdIcons or 0
		element.debuffFrame = element.debuffFrame or CreateFrame("Frame", "$parentDebuffFrame", element)
		element.debuffFrame.createdIcons = element.debuffFrame.createdIcons or 0

		element:Show()

		element:SetScript("OnSizeChanged", OnSizeChanged)

		return true
	end
end

local function Disable(self)
	if(self.SimpleAuras) then
		self:UnregisterEvent("UNIT_AURA", Update)
		self:UnregisterEvent("UNIT_CONNECTION", Update)
		self:UnregisterEvent("PARTY_MEMBER_ENABLE", Update)
		self:UnregisterEvent("PARTY_MEMBER_DISABLE", Update)
		self:UnregisterEvent("UNIT_INVENTORY_CHANGED", SetWeaponUpdateTimer)
		playerFrames[self] = nil

		self.SimpleAuras:Hide()
	end
end

oUF:AddElement("SimpleAuras", Update, Enable, Disable)