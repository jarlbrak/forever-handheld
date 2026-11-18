local combat=true
local mutations=0
local nativeShows=0
local events={}
local methods={}
local function region(t)return setmetatable(t or {},{__index=methods})end
function methods:IsForbidden()return false end
function methods:IsShown()return self.shown end
function methods:RegisterEvent(name)events[name]=true end
function methods:SetScript(k,v)self[k]=v end
function methods:HookScript(k,v)self.hooks=self.hooks or {};self.hooks[k]=v end
function methods:GetRegions()return region({texture='Interface\\AchievementFrame\\UI-Achievement-RecentHeader'})end
function methods:GetNormalTexture()return self.normal end
function methods:GetTexture()return self.texture end
function methods:GetPoint()return 'TOPLEFT',self.header end
function methods:IsObjectType(kind)return kind=='Texture' end
for _,method in ipairs({'SetIgnoreParentScale','SetScale','ClearAllPoints','SetPoint','SetSize','SetBackdrop','SetBackdropColor','SetBackdropBorderColor','SetAlpha','SetFont','SetTextColor','SetJustifyH','SetMaxLines'})do
 methods[method]=function(self,...)assert(not combat,'protected mutation during combat: '..method);mutations=mutations+1;self[method..'Args']={...}end
end
local driver
function CreateFrame()driver=region();return driver end
function InCombatLockdown()return combat end
C_Timer={After=function(_,fn)fn()end};UIParent={}
function hooksecurefunc(obj,key,fn)local old=obj[key];obj[key]=function(...)old(...);fn(...)end end
local click=function()error('native action must not be invoked by style')end
RARESCANNER_BUTTON=region({normal=region(),Title=region(),Description_text=region(),PostClick=click,attributes={type1='macro',macrotext='original'},shown=false})
function RARESCANNER_BUTTON:ShowButton()nativeShows=nativeShows+1;if not combat then self:SetScale(.8)end;self.shown=true end
local b=RARESCANNER_BUTTON
b.Title.header=region()
dofile(arg[1]);driver.OnEvent(driver,'PLAYER_ENTERING_WORLD');assert(mutations==0,'combat login changed frame')
combat=false;driver.OnEvent(driver,'PLAYER_REGEN_ENABLED');assert(b.SetPointArgs[1]=='TOPRIGHT' and b.SetPointArgs[5]==-450,'alert not in reserved rail');assert(b.PostClick==click and b.attributes.macrotext=='original','native behavior replaced');assert(b.Title.header.SetAlphaArgs[1]==0,'native header not suppressed')
b:ShowButton();assert(nativeShows==1 and b.SetScaleArgs[1]==1,'repeat native show lost dock scale');assert(ForeverHandheldDB.rareAlertStyle.seen)
combat=true;local before=mutations;b.hooks.OnShow();b:ShowButton();assert(mutations==before,'combat reshow mutated secure button')
combat=false;driver.OnEvent(driver,'PLAYER_REGEN_ENABLED');assert(not ForeverHandheldDB.rareAlertError,ForeverHandheldDB.rareAlertError)
print('PASS: combat deferral, repeated native show, placement, native callback and action preservation')
