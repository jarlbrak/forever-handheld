-- Keep RareScanner's secure button and native actions; only dress/position it.
-- No polling, synthetic clicks, binding replacement or combat-time mutation.
local driver=CreateFrame('Frame')
local hooked
local safeApply
local WHITE='Interface\\Buttons\\WHITE8X8'
local function apply()
 if InCombatLockdown() then return end
 local b=_G.RARESCANNER_BUTTON
 if not b or b:IsForbidden() then return end
 if not hooked then
  hooked=b
  -- GetTexture may return a numeric file ID. Capture the native title's
  -- actual background before replacing its anchors instead of guessing IDs.
  if b.Title then
   local _,header=b.Title:GetPoint(1)
   if header and header.IsObjectType and header:IsObjectType('Texture') then header:SetAlpha(0)end
  end
  b:HookScript('OnShow',function() safeApply() end)
  if b.ShowButton then hooksecurefunc(b,'ShowButton',function() safeApply() end)end
  b:HookScript('OnLeave',function(self)
   if not InCombatLockdown() then self:SetBackdropBorderColor(.68,.56,.36,1) end
  end)
 end
 b:SetIgnoreParentScale(false);b:SetScale(1)
 b:ClearAllPoints();b:SetPoint('TOPRIGHT',UIParent,'TOPRIGHT',-19,-450)
 b:SetSize(242,62)
 b:SetBackdrop({bgFile=WHITE,edgeFile=WHITE,edgeSize=1})
 b:SetBackdropColor(.025,.030,.025,.96);b:SetBackdropBorderColor(.68,.56,.36,1)
 local normal=b:GetNormalTexture();if normal then normal:SetAlpha(0) end
 for _,r in ipairs({b:GetRegions()})do
  if r.GetTexture and r:GetTexture()=='Interface\\AchievementFrame\\UI-Achievement-RecentHeader' then r:SetAlpha(0) end
 end
 if b.Title then
  b.Title:ClearAllPoints();b.Title:SetPoint('TOPLEFT',b,'TOPLEFT',10,-7)
  b.Title:SetPoint('TOPRIGHT',b,'TOPRIGHT',-10,-7)
  b.Title:SetFont('Fonts\\ARIALN.TTF',16,'OUTLINE');b.Title:SetTextColor(.94,.88,.72)
  b.Title:SetJustifyH('LEFT');b.Title:SetMaxLines(1)
 end
 if b.Description_text then
  b.Description_text:ClearAllPoints();b.Description_text:SetPoint('TOPLEFT',b,'TOPLEFT',28,-29)
  b.Description_text:SetPoint('TOPRIGHT',b,'TOPRIGHT',-76,-29)
  b.Description_text:SetFont('Fonts\\ARIALN.TTF',12,'');b.Description_text:SetTextColor(.86,.83,.76)
  b.Description_text:SetJustifyH('LEFT');b.Description_text:SetMaxLines(2)
 end
 -- The native arrows normally extend outside either edge. Keep them inside
 -- this corner card; its native ten 21px loot icons fit in the 31px gap below.
 for i,name in ipairs({'NextButton','PreviousButton'})do
  local nav=b[name]
  if nav then nav:ClearAllPoints();nav:SetPoint('BOTTOMRIGHT',b,'BOTTOMRIGHT',-24-(i-1)*26,2);nav:SetSize(20,20)end
 end
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.rareAlertStyle={version='3.7.32',applied=true,seen=b:IsShown() or (ForeverHandheldDB.rareAlertStyle or {}).seen}
end
safeApply=function()
 local ok,err=pcall(apply)
 if not ok then ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.rareAlertError=tostring(err)end
end
driver:RegisterEvent('PLAYER_ENTERING_WORLD');driver:RegisterEvent('PLAYER_REGEN_ENABLED')
driver:RegisterEvent('ADDON_LOADED')
driver:SetScript('OnEvent',function(_,event,name)
 if event~='ADDON_LOADED' or name=='RareScanner' then C_Timer.After(0,safeApply)end
end)
