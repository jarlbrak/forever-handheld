-- Improve native editor typography without touching secure layout state.
-- The game still owns every checkbox, row order, focus target and callback.
local VERSION='3.7.82'
local driver=CreateFrame('Frame')
local elapsed=0
local function public(v)return not (issecretvalue and issecretvalue(v))end
local function ordinary(f)
 return f and not (f.IsForbidden and f:IsForbidden()) and not (f.IsProtected and f:IsProtected())
end
local function number(v)return public(v) and type(v)=='number' and v==v and v>0 end
local function font(f,size)
 if not ordinary(f) or not f.GetFont then return false end
 local face,old,flags=f:GetFont()
 if not public(face) or type(face)~='string' or not number(old) or not public(flags) then return false end
 if old<size then f:SetFont(face,size,flags or '');return true end
 return false
end
local function update()
 if InCombatLockdown() then return end
 local root=_G.EditModeManagerFrame
 if not ordinary(root) or not root:IsShown() then return end
 local account=root.AccountSettings
 local scroll=account and account.SettingsContainer
 local child=scroll and scroll.ScrollChild
 local advanced=child and child.AdvancedOptionsContainer
 local basic=child and child.BasicOptionsContainer
 if not ordinary(account) or not ordinary(scroll) or not ordinary(child) or
    not ordinary(advanced) or not ordinary(basic) or type(account.settingsCheckButtons)~='table' then return end
 -- Never write layout parameters or invoke native layout methods here.
 -- Advanced/collapse callbacks call Layout before updating account settings;
 -- tainted layout fields can leak into subsequent protected preview actions.
 local changed=false
 local function mark(v)changed=v or changed end
 local rows=0
 for _,row in pairs(account.settingsCheckButtons)do
  if ordinary(row) and row:IsShown() and ordinary(row.Label) then
   rows=rows+1
   mark(font(row.Label,16))
   if row.Label.CanWordWrap and not row.Label:CanWordWrap() then row.Label:SetWordWrap(true)end
  end
 end
 for _,name in ipairs({'FramesTitle','CombatTitle','MiscTitle'})do
  local heading=advanced[name]
  if ordinary(heading) then mark(font(heading.Title,16))end
 end
 for _,name in ipairs({'ShowGridCheckButton','EnableSnapCheckButton','EnableAdvancedOptionsCheckButton'})do
  local control=root[name]
  if ordinary(control) then mark(font(control.Label,16))end
 end
 mark(font(root.LayoutLabel,16))
 -- The native dropdown paints above its top edge. Keep the caption clear
 -- of that decoration without moving the dropdown or its focus target.
 local label=root.LayoutLabel
 if ordinary(label) and label.GetPoint and label.SetPoint then
  local point,relative,relativePoint,x,y=label:GetPoint(1)
  if point=='BOTTOMLEFT' and relative==root.LayoutDropdown and relativePoint=='TOPLEFT'
     and public(x) and type(x)=='number' and public(y) and type(y)=='number' and y<8 then
   label:SetPoint(point,relative,relativePoint,x,8);changed=true
  end
 end
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.nativeEditModeError=nil
 local d=ForeverHandheldDB.nativeEditMode or {};ForeverHandheldDB.nativeEditMode=d
 d.version=VERSION;d.seen=GetTime();d.columns=2;d.rows=rows;d.font=16
 d.width=root:GetWidth();d.height=root:GetHeight();d.nativeActions=true;d.nativeLayoutUntouched=true
end
driver:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.25 then return end;elapsed=0
 local ok,err=pcall(update)
 if not ok then
  ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.nativeEditModeError=tostring(err)
 end
end)
