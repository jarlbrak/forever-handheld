local events = {}
local combat, listening, gamepad = false, false, true
local hint, controllerHook
local cancelClicks = 0
local function frame(isVisible)
    return {
        visible = isVisible,
        IsForbidden = function() return false end,
        IsVisible = function(self) return self.visible end,
    }
end

QuickKeybindFrame = frame(true)
QuickKeybindFrame.CancelButton = frame(true)
QuickKeybindFrame.GetFrameLevel = function() return 2 end
QuickKeybindFrame.HookScript = function(_, event, callback)
    assert(event == 'OnGamePadButtonDown' and not controllerHook)
    controllerHook = callback
end
QuickKeybindFrame.CancelButton.Click = function(_, button)
    assert(button == 'LeftButton')
    cancelClicks = cancelClicks + 1
    QuickKeybindFrame.visible = false
    events['QuickKeybindFrame.QuickKeybindModeDisabled']()
end

InCombatLockdown = function() return combat end
InputUtil = {IsGamepadUIEnabled = function() return gamepad end}
KeybindListener = {IsListening = function() return listening end}
EventRegistry = {RegisterCallback = function(_, event, callback) events[event] = callback end}
CreateFrame = function(_, name)
    local created = frame(false)
    for _, method in ipairs({'RegisterEvent', 'SetScript', 'SetFrameLevel', 'SetSize', 'SetPoint', 'EnableMouse'}) do
        created[method] = function() end
    end
    created.CreateFontString = function() return {SetPoint = function() end, SetText = function() end} end
    created.SetShown = function(self, shown) self.visible = shown end
    if name then hint = created end
    return created
end

dofile(arg[1])
events['QuickKeybindFrame.QuickKeybindModeEnabled']()
assert(hint.visible and controllerHook)
controllerHook(QuickKeybindFrame, 'PAD1')
listening = true
events['KeybindListener.StartedListening']()
assert(not hint.visible)
controllerHook(QuickKeybindFrame, 'PAD2')
listening = false
StaticPopup1 = frame(true)
controllerHook(QuickKeybindFrame, 'PAD2')
StaticPopup1.visible = false
combat = true
controllerHook(QuickKeybindFrame, 'PAD2')
combat = false
gamepad = false
controllerHook(QuickKeybindFrame, 'PAD2')
assert(cancelClicks == 0, 'Cancel fired while another input owner was active')
gamepad = true
events['Gamepad.RefreshFrameFocus']()
assert(hint.visible)
controllerHook(QuickKeybindFrame, 'PAD2')
assert(cancelClicks == 1 and not hint.visible)
assert(ForeverHandheldDB.quickKeybindController and not ForeverHandheldDB.quickKeybindControllerError)
print('PASS: Quick Keybind preserves the listener and popup paths, and idle B invokes native Cancel')
