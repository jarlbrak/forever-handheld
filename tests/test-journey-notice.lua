local combat=false
local frames={}
local M={}
function M:SetScript(k,v)self.scripts[k]=v end
function M:HookScript(k,v)self.hooks[k]=v end
function M:IsShown()return not self.hidden end
function M:Hide()self.hidden=true;self.hides=(self.hides or 0)+1 end
function M:Show()self.hidden=false;if self.hooks.OnShow then self.hooks.OnShow(self)end end
function M:SetText(v)self.text=v end
function M:GetText()return self.text end
function M:SetAlpha(v)self.alpha=v end
function M:SetPoint(...)self.point={...}end
function M:ClearAllPoints()self.point=nil end
function M:EnableMouse(v)self.mouse=v end
function M:SetSize(w,h)self.w=w;self.h=h end
function M:SetHeight(h)self.h=h end
function M:GetHeight()return self.h or 100 end
function M:GetStringHeight()return math.ceil(#(self.text or '')/60)*24 end
function M:SetMinMaxValues(lo,hi)self.lo=lo;self.hi=hi end
function M:GetMinMaxValues()return self.lo,self.hi end
function M:SetValue(v)self.value=v;if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v)end end
function M:GetValue()return self.value or 0 end
function M:SetShown(v)self.hidden=not v end
function M:SetVerticalScroll(v)self.scroll=v end
function M:SetEnabled(v)self.enabled=v end
function CreateFrame(kind,name,parent)
 local f=setmetatable({kind=kind,name=name,parent=parent,scripts={},hooks={}},{__index=function(_,k)
  if M[k] then return M[k] end
  if k:match('^Set') or k:match('^Enable') then return function()end end
 end})
 frames[#frames+1]=f;if name then _G[name]=f end;return f
end
function M:CreateFontString()return CreateFrame('FontString',nil,self)end
function M:GetFontString()self.font=self.font or self:CreateFontString();return self.font end
function M:GetThumbTexture()self.thumb=self.thumb or CreateFrame('Texture');return self.thumb end
function M:GetHighlightTexture()self.highlight=self.highlight or CreateFrame('Texture');return self.highlight end
function hooksecurefunc(owner,key,fn)
 local original=owner[key]
 owner[key]=function(...)local result=original(...);fn(...);return result end
end
function InCombatLockdown()return combat end
UIParent=CreateFrame('Frame');UISpecialFrames={};STANDARD_TEXT_FONT='Font'
local notices={}
ForeverHandheldActivityFeed={StoryNotice=function(t)notices[#notices+1]=t end}

local output,commands={},{}
DEFAULT_CHAT_FRAME={AddMessage=function(_,message)output[#output+1]=message end}
local response='|cffe6cc80[Loreward]|r RestedXP shows no Loreward guide. Open one from its guide menu, and /loreward next says where it leads.'
SlashCmdList={LOREWARD=function(command)commands[#commands+1]=command;if command=='next' then DEFAULT_CHAT_FRAME:AddMessage(response)end end}
function M:RegisterEvent(event)self.event=event end
dofile(arg[1]);local J=ForeverHandheldJourneyNotice
assert(J.run() and #commands==1 and commands[1]=='next' and #output==1,'native command/output not preserved')
local w=J.window;assert(w:IsShown() and w.body:GetText():find('current guide stays selected',1,true),'missing readable no-guide response')
local before=w.body:GetText();DEFAULT_CHAT_FRAME:AddMessage('[Loreward] unrelated later output');assert(w.body:GetText()==before,'later output captured')
w.close.scripts.OnClick();assert(not w:IsShown(),'Close failed')
response='Other addon message';assert(J.run() and not w:IsShown(),'unrelated output opened notice')
response='[Loreward] This is the end of the route.';J.run();assert(w.body:GetText()=='This is the end of the route.','native route explanation lost')
w.plan.scripts.OnClick();assert(not w:IsShown() and commands[#commands]=='plan','planner not opened intentionally')
local count=#commands;combat=true;assert(not J.run() and #commands==count and not J.show('blocked'),'combat changed UI or guide')
combat=false;J.show('notice');combat=true;w.scripts.OnEvent(w,'PLAYER_REGEN_DISABLED');assert(not w:IsShown(),'combat did not close notice');combat=false
LorewardWhereNextBox=CreateFrame('Frame');assert(not J.show('waiting'),'notice covered native chooser');LorewardWhereNextBox:Hide();J.show('waiting');LorewardWhereNextBox:Show();w.scripts.OnUpdate(w);assert(not w:IsShown(),'delayed chooser did not take precedence');LorewardWhereNextBox:Hide()
J.show(string.rep('Readable long guide response. ',200));local lo,hi=w.bar:GetMinMaxValues();assert(hi>0 and w.scroll:GetHeight()==340 and w:GetHeight()==460,'long response not bounded/scrollable');w.bar:SetValue(100);assert(w.scroll.scroll==100,'response scroll broken')
SlashCmdList.LOREWARD=function()error('test failure')end;J.run();assert(ForeverHandheldDB.journeyNoticeError:find('test failure',1,true) and w.body:GetText():find('unavailable',1,true),'command failure not surfaced')
local body=w.body:GetText();DEFAULT_CHAT_FRAME:AddMessage('[Loreward] after failure');assert(w.body:GetText()==body,'capture leaked after command error')
print('PASS: native command/output preserved; scoped Loreward-only capture; readable no-guide/end-route responses; explicit planner action; combat guard/close; native chooser priority; bounded long response; error cleanup.')
