-- Teach the native stick gesture in the otherwise empty radial hub.
-- No input interception, native state changes, or idle work.
local card
local function createHint()
 local radial=_G.GamepadRadial
 if card or InCombatLockdown() or not radial or
    (radial.IsForbidden and radial:IsForbidden()) or not radial.Background then return end
 local f=CreateFrame('Frame','ForeverHandheldRadialHint',radial)
 f:EnableMouse(false)
 f:SetSize(112,58)
 f:SetPoint('CENTER',radial.Background,'CENTER')
 f:SetFrameLevel(radial:GetFrameLevel()+3)
 local bg=f:CreateTexture(nil,'BACKGROUND')
 bg:SetAllPoints();bg:SetColorTexture(.025,.030,.029,.96)
 for _,side in ipairs({'TOP','BOTTOM'})do
  local line=f:CreateTexture(nil,'BORDER')
  line:SetPoint(side..'LEFT',5,0);line:SetPoint(side..'RIGHT',-5,0)
  line:SetHeight(1);line:SetColorTexture(.72,.60,.39,.85)
 end
 local function label(value,size,y,r,g,b)
  local text=f:CreateFontString(nil,'OVERLAY')
  text:SetFont(STANDARD_TEXT_FONT,size,'');text:SetTextColor(r,g,b)
  text:SetPoint('CENTER',0,y);text:SetText(value)
 end
 label('Right stick',14,16,.88,.75,.52)
 label('Release to open',12,0,.94,.90,.82)
 label('B  Back',12,-16,.88,.75,.52)
 card=f
 -- Diagonal labels have more horizontal room than cardinal labels. Give
 -- long native labels room without changing their anchors or selection area.
 for _,segment in ipairs(radial.SegmentList or {}) do
  local iconLabel=segment.IconLabel
  if iconLabel and segment:GetID()%2==0 and iconLabel:GetWidth()<106 then
   iconLabel:SetWidth(106)
  end
 end
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.radialHintVersion='3.7.104'
end
local function onShow()
 local ok,err=pcall(createHint)
 if not ok then
  ForeverHandheldDB=ForeverHandheldDB or {}
  ForeverHandheldDB.radialHintError=tostring(err)
 end
end
EventRegistry:RegisterCallback('Gamepad.ShowMainMenu',onShow,{})
