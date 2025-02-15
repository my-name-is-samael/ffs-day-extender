---@class DayExtender : ModModule
local M = {
    Author = "TontonSamael",
    Version = 1,

    -- CONSTANTS
    DURATION = {
        MIN = 8,
        MAX = 120,
    },

    -- DATA
    duration = 8,
}

local function GetDurationMultiplier()
    return (12 * 60) / M.duration
end

---@param ModManager ModManager
---@param Parameters string[]
---@param Ar any
local function DayCommand(ModManager, Parameters, Ar)
    if #Parameters == 0 then
        Log(M, LOG.INFO,
            string.format("Current workday duration is %d minutes (mult = %f)", M.duration, GetDurationMultiplier()),
            Ar)
        Log(M, LOG.INFO, string.format("To update, type \"day <duration_in_minutes>\""), Ar)
    elseif #Parameters == 1 then
        local dayDuration = tonumber(Parameters[1])
        if not dayDuration then
            Log(M, LOG.INFO, "Invalid day duration value", Ar)
            return
        elseif dayDuration < M.DURATION.MIN or dayDuration > M.DURATION.MAX then
            Log(M, LOG.INFO, string.format("Workday duration must be between %d and %d", M.DURATION.MIN, M.DURATION.MAX),
                Ar)
            return
        end

        M.duration = math.round(dayDuration)
        Log(M, LOG.INFO,
            string.format("Updated workday duration to %d minutes (mult = %f)", M.duration, GetDurationMultiplier()),
            Ar)
        if ModManager.GameState:IsValid() then
            ModManager.GameState.GameTimeMultiplier = GetDurationMultiplier()
        end
    else
        Log(M, LOG.INFO, "Too much parameters", Ar)
    end
end

---@param ModManager ModManager
function M.Init(ModManager)
    ModManager.AddCommand(M, "day", DayCommand)

    ModManager.AddHook(M, "OnPlayBtnPressed",
        "/Game/UI/MainMenu/W_CreateGame.W_CreateGame_C:BndEvt__W_CreateGame_PlayBtn_K2Node_ComponentBoundEvent_3_OnButtonPressed__DelegateSignature",
        function(M2, WinCreateGame)
            ---@type USlider
            local slider = WinCreateGame:get().DayDurationSlider.Slider_1
            slider:SetMinValue(M.DURATION.MIN)
            slider:SetMaxValue(M.DURATION.MAX)
            M.duration = math.round(slider.Value)
        end,
        function(M2)
            return M2.AppState == APP_STATES.MAIN_MENU
        end)

    ModManager.AddHook(M, "OnDayDurationChanged",
        "/Game/UI/MainMenu/Settings/Elements/W_SettingsElementSlider.W_SettingsElementSlider_C:BndEvt__W_SettingsElementSlider_Slider_1_K2Node_ComponentBoundEvent_0_OnFloatValueChangedEvent__DelegateSignature",
        function(M2, WinSettingsElementSlider, Value)
            ---@class UW_SettingsElementSlider_C
            local slider = WinSettingsElementSlider:get()
            if slider:GetFullName():find("DayDuration") then
                M.duration = math.round(Value:get())
            end
        end,
        function(M2)
            return M2.AppState == APP_STATES.MAIN_MENU
        end)

    ModManager.AddHook(M, "GetGameTimeMultiplier",
        "/Game/Blueprints/GameMode/GameState/BP_BakeryGameState_Ingame.BP_BakeryGameState_Ingame_C:GetGameTimeMultiplier",
        function() return GetDurationMultiplier() end,
        function(M2)
            return M2.AppState == APP_STATES.IN_GAME
        end)

    -- load current duration
    if ModManager.GameState:IsValid() then
        M.duration = (12 * 60) / ModManager.GameState.GameTimeMultiplier
        Log(M, LOG.INFO,
            string.format("Loaded workday duration is %d minutes (mult = %f)", M.duration, GetDurationMultiplier()))
    end
end

return M
