-- Quick Keybind receives raw gamepad input before normal key bindings.
-- Offer its native Cancel action while no action button is listening.
local hookedDialog, hint
local function visible(frame)
    return frame and not frame:IsForbidden() and frame:IsVisible()
end

local function canCancel(dialog)
    if InCombatLockdown() or not visible(dialog) or not visible(dialog.CancelButton) or
        not InputUtil or not InputUtil.IsGamepadUIEnabled() or
        not KeybindListener or KeybindListener:IsListening() then
        return false
    end
    for index = 1, 4 do
        if visible(_G['StaticPopup' .. index]) then return false end
    end
    return true
end

local function refresh()
    local dialog = _G.QuickKeybindFrame
    if visible(dialog) and hookedDialog ~= dialog and not InCombatLockdown() then
        dialog:HookScript('OnGamePadButtonDown', function(frame, button)
            if button == 'PAD2' and canCancel(frame) then
                local ok, err = pcall(frame.CancelButton.Click, frame.CancelButton, 'LeftButton')
                ForeverHandheldDB = ForeverHandheldDB or {}
                if ok and not frame:IsVisible() then
                    ForeverHandheldDB.quickKeybindController = '3.7.102'
                elseif not ok then
                    ForeverHandheldDB.quickKeybindControllerError = tostring(err)
                end
            end
        end)
        hookedDialog = dialog
        hint = CreateFrame('Frame', 'ForeverHandheldQuickKeybindHint', dialog)
        hint:SetFrameLevel(dialog:GetFrameLevel() + 2)
        hint:SetSize(128, 22)
        hint:SetPoint('TOPRIGHT', dialog, 'BOTTOMRIGHT', -8, -5)
        hint:EnableMouse(false)
        local label = hint:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
        label:SetPoint('CENTER')
        label:SetText('B  Cancel')
    end
    if hint then hint:SetShown(canCancel(dialog)) end
end

local function checkedRefresh()
    local ok, err = pcall(refresh)
    if not ok then
        ForeverHandheldDB = ForeverHandheldDB or {}
        ForeverHandheldDB.quickKeybindControllerError = tostring(err)
    end
end

local events = CreateFrame('Frame')
events:RegisterEvent('PLAYER_REGEN_DISABLED')
events:RegisterEvent('PLAYER_REGEN_ENABLED')
events:SetScript('OnEvent', checkedRefresh)
for _, event in ipairs({
    'QuickKeybindFrame.QuickKeybindModeEnabled',
    'QuickKeybindFrame.QuickKeybindModeDisabled',
    'Gamepad.RefreshFrameFocus',
    'KeybindListener.StartedListening',
    'KeybindListener.StoppedListening',
}) do
    EventRegistry:RegisterCallback(event, checkedRefresh, {})
end
