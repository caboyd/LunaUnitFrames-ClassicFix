LUF = select(2, ...)

LUF.Game = {
    CLASSIC = 1,
    TBC = 2,
    SOD = 3,
    FOREVER = 4,
}

do
    local game

    if WOW_PROJECT_ID == (WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5)
        or (WOW_PROJECT_ID == (WOW_PROJECT_CLASSIC or 2)
            and LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_BURNING_CRUSADE) then
        game = LUF.Game.TBC

    elseif WOW_PROJECT_ID == (WOW_PROJECT_CLASSIC or 2)
        and C_Seasons.HasActiveSeason()
        and C_Seasons.GetActiveSeason() == Enum.SeasonID.SeasonOfDiscovery then
        game = LUF.Game.SOD

    -- TODO: Add WoW Forever detection.
    else
        game = LUF.Game.CLASSIC
    end

    LUF.Game.current = game
end

LUF.isClassic = LUF.Game.current == LUF.Game.CLASSIC
LUF.isClassicSoD = LUF.Game.current == LUF.Game.SOD
LUF.isTBC = LUF.Game.current == LUF.Game.TBC
LUF.isForever = LUF.Game.current == LUF.Game.FOREVER

-- LibClassicDurations must be lazy loaded because it is not available when this file is loaded.
function LUF.UnitAura(unit, index, filter)
	local LCD = LibStub and LibStub("LibClassicDurations", true)
	if LCD and LCD.UnitAura then
		LUF.UnitAura = function(u, i, f) return LCD:UnitAura(u, i, f) end
	else
		LUF.UnitAura = _G.UnitAura
	end
	return LUF.UnitAura(unit, index, filter)
end
