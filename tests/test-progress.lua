local writes=0
local methods={}
local function node(parent)return setmetatable({parent=parent,shown=true},{__index=methods})end
function methods:GetParent()return self.parent end
function methods:CreateTexture()return node(self)end
function methods:CreateFontString()return node(self)end
function methods:SetScript(k,v)self[k]=v end
function methods:RegisterEvent(k)self.events=self.events or {};self.events[k]=true end
function methods:UnregisterAllEvents()self.events={} end
function methods:Show()writes=writes+1;self.shown=true end
function methods:Hide()writes=writes+1;self.shown=false end
function methods:SetShown(v)writes=writes+1;self.shown=v end
function methods:SetValue(v)assert(type(v)=='number' and v>=0 and v<=1);writes=writes+1;self.value=v end
function methods:SetWidth(v)writes=writes+1;self.width=v end
function methods:SetPoint(...)writes=writes+1;self.point={...}end
function methods:SetText(v)writes=writes+1;self.text=v end
for _,k in ipairs({'SetHeight','SetSize','SetStatusBarTexture','SetStatusBarColor','SetMinMaxValues','EnableMouse','SetAllPoints','SetColorTexture','SetFont','SetTextColor','SetJustifyH','SetMaxLines','SetWordWrap','ClearAllPoints','SetFrameStrata'}) do methods[k]=function()writes=writes+1 end end
function CreateFrame(_,_,parent)return node(parent)end
UIParent=node();function GetTime()return 1 end
local xp,max=50,100
function UnitXP()return xp end;function UnitXPMax()return max end
local watched
C_Reputation={GetWatchedFactionData=function()return watched end}
function issecretvalue(v)return v==12345 end
local forbidden=function()error('Native state must not be mutated')end
C_Reputation.SetWatchedFactionByID=forbidden
StatusTrackingBarManager={Hide=forbidden,SetAlpha=forbidden};SecondaryStatusTrackingBarContainer=StatusTrackingBarManager
function InCombatLockdown()return true end
dofile(arg[1]);local m=ForeverHandheldProgress;local root=m.Create(UIParent)
assert(root.xp.value==.5 and root.xp.width==720 and not root.xp.label.shown and not root.rep.shown)
assert(not root.OnUpdate,'must not add per-frame polling')
watched={name='Darkspear Trolls',currentReactionThreshold=0,nextReactionThreshold=3000,currentStanding=2050}
root.OnEvent(root,'UPDATE_FACTION');assert(root.rep.shown and root.rep.label.text=='Darkspear Trolls  68%' and root.xp.label.text=='XP  50%')
assert(root.xp.width==352 and root.rep.width==352 and root.xp.point[4]==-184 and root.rep.point[4]==184)
local n=writes;for i=1,50 do root.OnEvent(root,'UPDATE_FACTION')end;assert(writes==n,'settled events wrote UI')
watched.currentReactionThreshold=3000;watched.nextReactionThreshold=9000;watched.currentStanding=6000
root.OnEvent();assert(root.rep.value==.5,'standing threshold not subtracted')
watched.currentStanding=20000;root.OnEvent();assert(root.rep.value==1)
watched.currentStanding=0;root.OnEvent();assert(root.rep.value==0)
watched.currentStanding=12345;root.OnEvent();assert(not root.rep.shown,'secret data rendered')
watched.currentStanding=0/0;root.OnEvent();assert(not root.rep.shown)
watched.currentStanding=math.huge;root.OnEvent();assert(not root.rep.shown)
watched.currentStanding=42000;watched.currentReactionThreshold=42000;watched.nextReactionThreshold=42000
max=0;root.OnEvent();assert(root.rep.value==1 and root.rep.width==720 and not root.xp.shown)
C_Reputation=nil;function GetWatchedFactionInfo()return 'Undercity',5,3000,9000,6000 end
root.OnEvent();assert(root.rep.label.text=='Undercity  50%')
GetWatchedFactionInfo=nil;root.OnEvent();assert(not root.xp.shown and not root.rep.shown)
xp,max=25,100;root.OnEvent();assert(root.xp.value==.25 and root.xp.width==720)
m.Stop();n=writes;root.OnEvent();assert(not root.shown and not next(root.events) and writes==n)
assert(not ForeverHandheldDB.progressError)
print('PASS: real threshold math, live XP/reputation transitions, cap/invalid/secret inputs, legacy API, no native mutation, combat-safe owned frames, event-only updates, settled zero writes, shutdown')
