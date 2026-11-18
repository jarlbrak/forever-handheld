-- Read-only progress display. Native faction selection and secure input stay native.
local M={};ForeverHandheldProgress=M
local VERSION='3.7.85'
local WHITE='Interface\\Buttons\\WHITE8X8'
local function readable(v,kind)
 return type(v)==kind and not (issecretvalue and issecretvalue(v))
end
local function number(v) return readable(v,'number') and v==v and math.abs(v)<math.huge end
local function fraction(value,minimum,maximum)
 if not number(value) or not number(minimum) or not number(maximum) then return end
 local span=maximum-minimum
 if span<=0 then return value>=maximum and 1 or 0 end
 return math.max(0,math.min(1,(value-minimum)/span))
end
function M.ReadState()
 local s={}
 local xp=UnitXP and UnitXP('player');local maximum=UnitXPMax and UnitXPMax('player')
 if number(xp) and number(maximum) and maximum>0 then s.xp=fraction(xp,0,maximum) end
 local name,minimum,maximum,value
 if C_Reputation and C_Reputation.GetWatchedFactionData then
  local d=C_Reputation.GetWatchedFactionData()
  if type(d)=='table' then name,minimum,maximum,value=d.name,d.currentReactionThreshold,d.nextReactionThreshold,d.currentStanding end
 elseif GetWatchedFactionInfo then
  local standing;name,standing,minimum,maximum,value=GetWatchedFactionInfo()
 end
 if readable(name,'string') and name~='' then
  s.rep=fraction(value,minimum,maximum)
  if s.rep then s.name=name end
 end
 return s
end
local function track(parent,color)
 local f=CreateFrame('StatusBar',nil,parent);f:SetHeight(3);f:SetStatusBarTexture(WHITE);f:SetStatusBarColor(unpack(color));f:SetMinMaxValues(0,1);f:EnableMouse(false)
 local bg=f:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints(f);bg:SetColorTexture(.20,.22,.20,.7)
 f.label=parent:CreateFontString(nil,'OVERLAY');f.label:SetFont('Fonts\\ARIALN.TTF',14,'OUTLINE');f.label:SetTextColor(.87,.84,.76);f.label:SetJustifyH('CENTER');f.label:SetMaxLines(1);f.label:SetWordWrap(false)
 return f
end
local function place(f,width,x,y,label)
 f:ClearAllPoints();f:SetWidth(width);f:SetPoint('BOTTOM',f:GetParent(),'BOTTOM',x,y)
 f.label:ClearAllPoints();f.label:SetWidth(width);f.label:SetPoint('BOTTOM',f:GetParent(),'BOTTOM',x,1);f.label:SetShown(label)
end
function M.Update()
 if not M.enabled or not M.root then return end
 local s=M.ReadState();local old=M.state
 if old and old.xp==s.xp and old.rep==s.rep and old.name==s.name then return end
 M.state=s
 local xp,rep=M.root.xp,M.root.rep
 if s.rep then
  local split=s.xp~=nil
  place(rep,split and 352 or 720,split and 184 or 0,19,true)
  rep:SetValue(s.rep);rep.label:SetText(s.name..'  '..math.floor(s.rep*100)..'%');rep:Show()
  if split then
   place(xp,352,-184,19,true);xp:SetValue(s.xp);xp.label:SetText('XP  '..math.floor(s.xp*100)..'%');xp:Show()
  else xp:Hide();xp.label:Hide() end
 else
  rep:Hide();rep.label:Hide()
  if s.xp then place(xp,720,0,10,false);xp:SetValue(s.xp);xp:Show() else xp:Hide();xp.label:Hide() end
 end
 ForeverHandheldDB=ForeverHandheldDB or {}
 ForeverHandheldDB.progress={version=VERSION,watched=s.name,xp=s.xp,reputation=s.rep,eventDriven=true,seen=GetTime()}
end
local function refresh()
 local ok,err=pcall(M.Update)
 if not ok then
  ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.progressError=tostring(err)
  M.Stop()
 end
end
function M.Create(parent)
 if M.root then return M.root end
 local f=CreateFrame('Frame','ForeverHandheldProgressRail',parent);f:SetSize(720,22);f:SetPoint('BOTTOM',0,0);f:SetFrameStrata('LOW');f:EnableMouse(false)
 f.xp=track(f,{.35,.57,.73,.9});f.rep=track(f,{.74,.63,.39,.95})
 M.root=f;M.enabled=true
 for _,event in ipairs({'PLAYER_ENTERING_WORLD','PLAYER_XP_UPDATE','PLAYER_LEVEL_UP','UPDATE_FACTION','ENABLE_XP_GAIN','DISABLE_XP_GAIN'}) do f:RegisterEvent(event) end
 f:SetScript('OnEvent',refresh)
 ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.progressError=nil
 refresh();return f
end
function M.Stop()
 M.enabled=false
 if M.root then M.root:Hide();M.root:UnregisterAllEvents() end
end
