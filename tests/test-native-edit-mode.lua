-- Regression: typography must never taint the native layout/configuration state.
local writes=0
local combat=false
local state=setmetatable({},{__mode='k'})
local M={}
function M:IsForbidden()return state[self].forbidden or false end
function M:IsProtected()return state[self].protected or false end
function M:IsShown()return not state[self].hidden end
function M:GetWidth()return 510 end
function M:GetHeight()return 840 end
function M:GetFont()return 'NativeFont',state[self].size or 13,'OUTLINE' end
function M:SetFont(f,n,flags)assert(f=='NativeFont' and flags=='OUTLINE');writes=writes+1;state[self].size=n end
function M:GetPoint()return 'BOTTOMLEFT',state[self].relative,'TOPLEFT',0,state[self].offset or 0 end
function M:SetPoint(p,r,rp,x,y)assert(p=='BOTTOMLEFT' and r==state[self].relative and rp=='TOPLEFT' and x==0);state[self].offset=y;writes=writes+1 end
function M:CanWordWrap()return state[self].wrap or false end
function M:SetWordWrap(v)state[self].wrap=v;writes=writes+1 end
function M:Layout()error('must not invoke native layout')end
function M:SetWidth()error('must not override native width')end
local function obj(t)local o=setmetatable({},{__index=function(self,k)return state[self][k] or M[k]end,__newindex=function(_,k)error('native Lua field mutated: '..k)end});state[o]=t or {};return o end
local advanced=obj{FramesTitle=obj{Title=obj()},CombatTitle=obj{Title=obj()},MiscTitle=obj{Title=obj()}}
local child=obj{AdvancedOptionsContainer=advanced,BasicOptionsContainer=obj()}
local account=obj{SettingsContainer=obj{ScrollChild=child},settingsCheckButtons={}}
local action=function()error('native action invoked')end
for i=1,25 do account.settingsCheckButtons[i]=obj{Label=obj(),OnClick=action,layoutIndex=i,fixedWidth=225}end
local dropdown=obj()
local root=obj{AccountSettings=account,LayoutLabel=obj{relative=dropdown},LayoutDropdown=dropdown,fixedWidth=510,OnClick=action}
for _,k in ipairs({'ShowGridCheckButton','EnableSnapCheckButton','EnableAdvancedOptionsCheckButton'})do state[root][k]=obj{Label=obj()}end
EditModeManagerFrame=root
function InCombatLockdown()return combat end
function GetTime()return 20 end
local driver
function CreateFrame()driver={SetScript=function(self,k,v)self[k]=v end};return driver end
dofile(arg[1]);driver.OnUpdate(driver,.3)
assert(not ForeverHandheldDB.nativeEditModeError,ForeverHandheldDB.nativeEditModeError)
assert(root.fixedWidth==510 and state[root.LayoutLabel].offset==8)
for i,row in ipairs(account.settingsCheckButtons)do assert(state[row.Label].size==16 and state[row.Label].wrap and row.fixedWidth==225 and row.layoutIndex==i and row.OnClick==action)end
local a=writes;for i=1,50 do driver.OnUpdate(driver,.3)end;assert(writes==a,'settled editor repainted')
local row=account.settingsCheckButtons[1]
for _,condition in ipairs({'protected','forbidden','hidden'})do
 state[row][condition]=true;state[row.Label].size=13;a=writes;driver.OnUpdate(driver,.3);assert(writes==a and state[row.Label].size==13);state[row][condition]=false
end
state[root].protected=true;a=writes;driver.OnUpdate(driver,.3);assert(writes==a);state[root].protected=false
combat=true;driver.OnUpdate(driver,.3);assert(writes==a);combat=false
state[root].hidden=true;driver.OnUpdate(driver,.3);assert(writes==a);state[root].hidden=false
state[child].AdvancedOptionsContainer=nil;driver.OnUpdate(driver,.3);assert(writes==a);state[child].AdvancedOptionsContainer=advanced
driver.OnUpdate(driver,.3);assert(state[row.Label].size==16)
assert(not ForeverHandheldDB.nativeEditModeError and ForeverHandheldDB.nativeEditMode.nativeLayoutUntouched)
print('PASS: 25 native labels readable; no native Lua field writes/layout calls/width changes/actions; settled zero writes; hidden/protected/forbidden/combat/incomplete-tree recovery')
