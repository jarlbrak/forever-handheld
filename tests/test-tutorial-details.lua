local frames,combat,writes={},false,0
local M={}
function M:IsForbidden()return self.forbidden end
function M:IsProtected()return self.protected end
function M:IsShown()return not self.hidden end
function M:GetParent()return self.parent end
function M:GetWidth()return self.w or 100 end
function M:GetHeight()return self.h or 50 end
function M:GetLeft()return self.left or 100 end
function M:GetTop()return self.top or 770 end
function M:GetBottom()return self.bottom or 400 end
function M:GetEffectiveScale()return 1 end
function M:GetText()return self.text end
function M:GetFont()return 'Font',self.font or 11,''end
function M:GetAlpha()return self.alpha or 0 end
function M:SetAlpha(v)error('native alpha mutation')end
function M:GetFrameLevel()return self.level or 20 end
function M:SetFrameLevel(v)assert(not self.native);self.level=v;writes=writes+1 end
function M:GetPoint()return unpack(self.point or {})end
function M:SetPoint(...)assert(not self.native);self.point={...};writes=writes+1 end
function M:ClearAllPoints()assert(not self.native);self.point=nil;writes=writes+1 end
function M:SetSize(w,h)assert(not self.native);self.w=w;self.h=h;writes=writes+1 end
function M:SetWidth(v)assert(not self.native);self.w=v;writes=writes+1 end
function M:SetHeight(v)assert(not self.native);self.h=v;writes=writes+1 end
function M:SetFont(_,n)assert(not self.native);self.font=n;writes=writes+1 end
function M:SetText(v)assert(not self.native);assert(not self.isFontString or self.font,'font must be initialized before SetText');self.text=v;writes=writes+1 end
function M:SetParent(v)assert(not self.native);self.parent=v end
function M:SetAllPoints()assert(not self.native)end
function M:SetColorTexture()assert(not self.native)end
function M:GetTextColor()return .9,.7,.3,1 end
function M:SetTextColor(...)assert(not self.native);self.color={...}end
function M:SetWordWrap()assert(not self.native)end
function M:SetSpacing()assert(not self.native)end
function M:SetJustifyH(v)assert(not self.native);self.justifyH=v end
function M:SetJustifyV(v)assert(not self.native);self.justifyV=v end
function M:EnableMouse(v)assert(not self.native);self.mouse=v end
function M:Show()assert(not self.native);self.hidden=false end
function M:Hide()assert(not self.native);self.hidden=true end
function M:SetScript(k,v)assert(not self.native);self[k]=v end
function M:GetStringWidth()return #(self.text or '')*(self.font or 11)*.5 end
function M:GetStringHeight()return math.ceil(#(self.text or '')/(self.w/(self.font*.5)))*(self.font+2)end
local function obj(name,parent,native)
 local o=setmetatable({parent=parent,native=native,alpha=1},{__index=M});frames[#frames+1]=o;if name then _G[name]=o end;return o
end
function M:CreateTexture()return obj(nil,self)end
function M:CreateFontString()local f=obj(nil,self);f.isFontString=true;return f end
function CreateFrame(_,name,parent)return obj(name,parent)end
function InCombatLockdown()return combat end
function GetTime()return 1 end
UIParent=obj('UIParent');local root=obj('ControllerForeverTutorial',UIParent,true);root.w=1100;root.h=700
root.info=obj(nil,root,true);root.info.allowAlpha=true
root.desc=obj(nil,root.info,true);root.desc.text=string.rep('word ',50)
local chapter=obj(nil,root,true);chapter.w=266;chapter.left=114;chapter.bottom=420;root.chapters={chapter}
local action=function()error('native action called')end;root.OnClick=action;root.bindings={action}
dofile(arg[1]);local driver=frames[#frames]
local function tick()driver.OnUpdate(driver,.2);assert(not (ForeverHandheldDB and ForeverHandheldDB.tutorialDetailsError),ForeverHandheldDB and ForeverHandheldDB.tutorialDetailsError)end
tick();local panel=ForeverHandheldTutorialDetails
assert(panel and panel.mouse==false and not panel.hidden,'details panel absent or interactive')
assert(root.info.alpha==1 and panel.text.text==root.desc.text and not ForeverHandheldTutorialDetailsMask.hidden,'native explanation not retained in reader')
assert(panel.text.justifyH=='LEFT' and panel.text.justifyV=='TOP','reader paragraph alignment')
assert(panel.text.font==16 and panel.h+368<=676,'readable text does not fit free column')
local before=writes;tick();assert(writes==before,'settled reader produces layout/measurement churn')
root.desc.text='new explanation';tick();assert(panel.text.text==root.desc.text,'stale explanation')
root.desc.font=16;tick();assert(root.info.alpha==1 and panel.hidden,'ordinary readable explanation not restored')
root.desc.font=11;root.desc.text=string.rep('word ',200);tick();assert(root.info.alpha==1 and panel.hidden,'oversized explanation clipped')
root.desc.text='short';chapter.hidden=true;tick();assert(root.info.alpha==1 and panel.hidden,'slim page lost native explanation')
chapter.hidden=false;tick();root.hidden=true;tick();assert(root.info.alpha==1 and panel.hidden,'closure left native alpha hidden')
root.hidden=false;combat=true;before=writes;tick();assert(writes==before,'combat mutation')
combat=false;root.protected=true;tick();assert(not panel.hidden,'read-only protected ancestor inspection blocked')
root.info.protected=true;tick();assert(not panel.hidden and root.info.alpha==1,'protected presentation was mutated');root.info.protected=false
root.hidden=true;tick();assert(root.info.alpha==1,'deferred restoration lost original alpha');root.hidden=false
root.protected=false;root.desc.forbidden=true;before=writes;tick();assert(writes==before and panel.hidden and ForeverHandheldTutorialDetailsMask.hidden,'forbidden text changed')
root.desc.forbidden=false;tick();root.info.alpha=.6;root.hidden=true;tick();assert(root.info.alpha==.6,'external alpha overwritten on release')
assert(root.OnClick==action and root.bindings[1]==action,'native actions changed')
root.hidden=false;root.desc.text='short'
root.head=obj(nil,root,true);root.head.left=188;root.head.top=743;root.head.w=450;root.head.h=24;root.head.font=20;root.head.text=string.rep('T',44)
local segment=obj(nil,root,true);segment.left=640;root.segments={segment}
tick();local header=ForeverHandheldTutorialHeader
assert(header and not header.hidden and header.mouse==false,'cramped header not replaced')
assert(header.text.text==root.head.text and header.text.font==18,'native title text changed')
assert(ForeverHandheldDB.tutorialHeader.gap>=20,'header still cramped')
assert(header.text.color[1]==.9 and header.text.color[2]==.7,'native title color changed')
assert(root.head.font==20 and root.head.text==string.rep('T',44),'native title mutated')
before=writes;tick();assert(writes==before,'settled header churn')
segment.left=700;tick();assert(header.hidden,'ordinary title unnecessarily replaced')
segment.left=630;tick();assert(header.hidden,'native progress would be masked')
segment.left=640;root.head.text=string.rep('T',100);tick();assert(header.hidden,'replacement title clipped')
root.head.text=string.rep('T',44);tick();assert(not header.hidden,'header did not recover')
segment.hidden=true;tick();assert(header.hidden,'docked page retained stale header')
segment.hidden=false;tick();root.hidden=true;tick();assert(header.hidden,'closed header retained')
root.hidden=false;root.head.forbidden=true;tick();assert(header.hidden,'forbidden title read')
root.head.forbidden=false;combat=true;before=writes;tick();assert(writes==before,'combat header mutation');combat=false
assert(root.OnClick==action and root.bindings[1]==action,'header changed native actions')
print('PASS: readable exact native explanation, bounded chapter placement, stable cached measurement, fallback, cleanup, native alpha preservation, combat/protected/forbidden guards and native action preservation')

root.rowsStep={title='Your Layout'};chapter.hidden=true
root.desc.text='Left / right picks one: your buttons below change at once.'
ForeverHandheldDock=obj('ForeverHandheldDock',UIParent,true)
tick();local caption=ForeverHandheldTutorialLayoutHint
assert(caption and not caption.hidden and caption.mouse==false,'dock guidance missing from Layout step')
assert(root.desc.text:find('below change',1,true) and panel.hidden,'native caption changed or a second reader is visible')
before=writes;tick();assert(writes==before,'stable layout caption churn')
root.rowsStep.title='Another Step';tick();assert(caption.hidden,'layout caption escaped its own step')
print('PASS: truthful handheld dock guidance leaves the native layout row and tutorial text untouched')
