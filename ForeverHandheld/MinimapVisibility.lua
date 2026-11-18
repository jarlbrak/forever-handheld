-- Native minimap blips can survive UIParent's cinematic alpha fade. Hide the
-- unprotected map only while that fade is complete, then restore our own hide.
-- No binding, focus, native script, pin, or map-layout changes are involved.
local hidden
local driver=CreateFrame('Frame')
local elapsed=0
local function accessible(frame)
 return frame and not (frame.IsForbidden and frame:IsForbidden())
end
local function mutable(frame)
 return accessible(frame) and frame.IsProtected and not frame:IsProtected()
end
local function restore()
 if not hidden then return true end
 if not mutable(hidden) then return false end
 local frame=hidden
 frame:Show()
 hidden=nil
 return true
end
local function shown(frame)
 return accessible(frame) and frame:IsShown()
end
local function update()
 local conversation=shown(_G.ControllerForeverDialogueBand) or shown(_G.ControllerForeverTalkBox)
 local alpha=accessible(UIParent) and UIParent:GetAlpha()
 local faded=type(alpha)=='number' and not (issecretvalue and issecretvalue(alpha)) and alpha<=.01
 local hide=conversation and faded
 if hidden and (not hide or hidden~=_G.Minimap) then
  if not restore() then return end
 end
 local map=_G.Minimap
 if hide and not hidden and mutable(map) and map:IsShown() and not InCombatLockdown() then
  -- Retain ownership before Hide so the error path can also restore it.
  hidden=map
  map:Hide()
 end
end
driver:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt
 if elapsed<.1 then return end
 elapsed=0
 local ok,err=pcall(update)
 if not ok then
  pcall(restore)
  ForeverHandheldDB=ForeverHandheldDB or {}
  ForeverHandheldDB.minimapVisibilityError=tostring(err)
  driver:SetScript('OnUpdate',nil)
 end
end)
