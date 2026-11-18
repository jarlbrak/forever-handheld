-- Complete native item text and comparison ownership survive margin placement.
local M,frames={},{}
function M:GetName()return self.name end
function M:GetParent()return self.parent end
function M:IsShown()return not self.hidden end
function M:IsVisible()return self:IsShown() end
function M:IsForbidden()return false end
function M:IsProtected()return self.protected or false end
function M:IsTooltipType(k)return self.item and k==3 end
function M:GetOwner()return self.owner end
function M:SetOwner(owner,anchor)
 self.owner=owner;self.anchorType=anchor;self.points={{'BOTTOMLEFT',owner,'TOPRIGHT',5,10}}
end
function hooksecurefunc(obj,key,hook)
 local native=obj[key];obj[key]=function(self,...)native(self,...);hook(self,...)end
end
function M:GetAnchorType()return self.anchorType or 'ANCHOR_RIGHT'end
function M:SetAnchorType(v)self.anchorType=v;self.points={}end
function M:GetSize()return self.w or 300,self.h or 220 end
function M:GetWidth()return self.w or 1280 end
function M:GetHeight()return self.h or 800 end
function M:GetEffectiveScale()return self.scale or 1 end
function M:GetRight()return self.right or 810 end
function M:GetLeft()return self.left or 470 end
function M:GetTop()return self.top or 650 end
function M:GetBottom()return self.bottom or 185 end
function M:GetFrameStrata()return 'TOOLTIP' end
function M:GetFrameLevel()return 20 end
function M:GetNumPoints()return #self.points end
function M:GetPoint(i)if self.points[i] then return unpack(self.points[i])end end
function M:ClearAllPoints()self.points={}end
function M:SetPoint(...)self.points[#self.points+1]={...}end
function M:SetScript(k,v)assert(not self.native,'native scripts replaced');self[k]=v end
function M:RegisterEvent(k)self.event=k end
function M:UnregisterEvent(k)assert(self.event==k);self.event=nil end
function M:Show()assert(not self.native);self.hidden=false end
function M:Hide()assert(not self.native);self.hidden=true end
function M:SetShown(v)assert(not self.native);self.hidden=not v end
local function obj(name,parent,native)
 local x=setmetatable({name=name,parent=parent,native=native,points={}},{__index=function(_,k)
  if M[k]then return M[k]end
  if k:match('^Set') or k:match('^Enable')then return function(self)assert(not self.native,'native behavior changed: '..k)end end
 end});frames[#frames+1]=x;return x
end
function CreateFrame(_,n,p)return obj(n,p)end
UIParent=obj('UIParent');UIParent.w=1280;UIParent.h=800
InspectFrame=obj('InspectFrame',UIParent,true)
local item=obj('InspectHeadSlot',InspectFrame,true)
GameTooltip=obj('GameTooltip',UIParent,true);GameTooltip.owner=item;GameTooltip.item=true
GameTooltip.points={{'BOTTOMLEFT',item,'TOPRIGHT',5,10}};GameTooltip.contents='all original stats and addon details'
ShoppingTooltip1=obj('ShoppingTooltip1',UIParent,true);ShoppingTooltip1.hidden=true;ShoppingTooltip1.points={{'TOPLEFT',GameTooltip,'TOPRIGHT',0,0}}
ShoppingTooltip2=obj('ShoppingTooltip2',UIParent,true);ShoppingTooltip2.hidden=true
Enum={TooltipDataType={Item=3}}
local combat=false
function InCombatLockdown()return combat end
function GetTime()return 20 end
C_TooltipComparison={CompareItem=function(_,tip)
 ShoppingTooltip1:SetAnchorType('ANCHOR_LEFT')
 ShoppingTooltip1:SetPoint('TOPRIGHT',tip,'TOPLEFT',0,0)
end}
local original=GameTooltip.points[1]
dofile(arg[1]);local driver=frames[#frames]
local function tick()driver.OnUpdate(driver,.2);assert(not ForeverHandheldDB.itemDetailError,ForeverHandheldDB.itemDetailError)end
tick();assert(GameTooltip.points[1][1]=='TOPRIGHT' and GameTooltip.points[1][5]==-330,'item did not dock below map');assert(GameTooltip:GetAnchorType()=='ANCHOR_NONE','engine anchoring still fights explicit placement')
GameTooltip:SetOwner(item,'ANCHOR_RIGHT')
assert(GameTooltip.points[1][1]=='TOPRIGHT' and GameTooltip:GetAnchorType()=='ANCHOR_NONE','native Inspect refresh overwrote validated anchor')
assert(GameTooltip.contents=='all original stats and addon details','native content changed')
local bg=frames[#frames];assert(not bg.hidden,'detail backing missing')
tick();assert(#GameTooltip.points==1,'repeated tick accumulates anchors')
ShoppingTooltip1.hidden=false;tick();assert(ShoppingTooltip1.points[1][1]=='TOPLEFT' and ShoppingTooltip1.points[1][2]==UIParent and GameTooltip.points[1][1]=='TOPRIGHT','comparison did not separate across margins')
C_TooltipComparison.CompareItem({},GameTooltip)
assert(ShoppingTooltip1.points[1][1]=='TOPLEFT' and ShoppingTooltip1.points[1][2]==UIParent,'native comparison refresh overwrote margin placement')
ShoppingTooltip2.hidden=false;tick();assert(GameTooltip.points[1][2]==item and ShoppingTooltip1.points[1][2]==GameTooltip and bg.hidden,'multiple comparisons did not restore native placement');assert(GameTooltip:GetAnchorType()=='ANCHOR_RIGHT','native owner anchor not restored')
ShoppingTooltip2.hidden=true
ShoppingTooltip1.hidden=true;GameTooltip.h=400;tick();assert(GameTooltip.points[1][2]==item,'oversized tooltip moved over dock')
GameTooltip.h=220;InspectFrame.right=1100;tick();assert(GameTooltip.points[1][2]==item,'tooltip overlaps adjacent panel')
InspectFrame.right=810;tick();assert(not bg.hidden)
GameTooltip.hidden=true;tick();assert(bg.hidden and GameTooltip.points[1][2]==item,'closed detail remains visible')
GameTooltip.hidden=false;combat=true;tick();assert(GameTooltip.points[1][2]==item,'combat changed native geometry')
GameTooltip:SetOwner(item,'ANCHOR_RIGHT');assert(GameTooltip.points[1][2]==item,'owner hook moved tooltip in combat')
combat=false;GameTooltip.scale=.8;tick();assert(GameTooltip.points[1][2]==item,'scaled tooltip changed without verified geometry')
GameTooltip.scale=1;tick();assert(not bg.hidden)
GameTooltip.owner=obj('Other',UIParent,true);GameTooltip.points={{'CENTER',UIParent,'CENTER',0,0}};tick()
assert(bg.hidden and GameTooltip.points[1][1]=='CENTER','new native owner placement overwritten')
print('PASS: native item content, margin fit, stable anchors, comparison restore, oversized/overlap/scale/combat fallback, hidden/new owner cleanup.')

MerchantFrame=obj('MerchantFrame',UIParent,true);MerchantFrame.right=350
local vendorItem=obj('MerchantItem1ItemButton',MerchantFrame,true)
local activeFrame=MerchantFrame
SmartNavigation={GetActiveFrame=function()return activeFrame end}
local detail=obj('BagsDetails',UIParent);detail.scale=.75;detail.top=800;detail.bottom=230
local bags={open=true,away='visit',zones={detail=detail}}
ControllerForever={Kit={live={bags=bags}}}
GameTooltip.w=300;GameTooltip.h=130;GameTooltip:SetOwner(vendorItem,'ANCHOR_RIGHT')
tick();assert(GameTooltip.points[1][4]==-22 and GameTooltip.points[1][5]==-200,'merchant tooltip did not use the fitted companion column')
assert(GameTooltip.contents=='all original stats and addon details' and GameTooltip.owner==vendorItem and ForeverHandheldDB.itemDetails.merchant)
GameTooltip:SetOwner(vendorItem,'ANCHOR_RIGHT')
assert(GameTooltip.points[1][5]==-200,'native merchant owner update defeated the validated placement')
ShoppingTooltip1.w=280;ShoppingTooltip1.h=160;ShoppingTooltip1.hidden=false;tick()
assert(ShoppingTooltip1.points[1][4]==-334 and ShoppingTooltip1.points[1][5]==-200,'comparison overlaps primary or leaves detail area')
ShoppingTooltip1.w=800;tick();assert(GameTooltip.points[1][2]==vendorItem and bg.hidden,'oversized merchant comparison lost its native fallback')
ShoppingTooltip1.hidden=true;tick()
local stable=GameTooltip.points[1];tick();assert(GameTooltip.points[1]==stable,'settled merchant anchor was rewritten')
activeFrame=InspectFrame;tick();assert(GameTooltip.points[1][2]==vendorItem and bg.hidden,'leaving vendor focus did not restore native anchor')
activeFrame=MerchantFrame;tick();bags.away=nil;tick()
assert(GameTooltip.points[1][2]==vendorItem and bg.hidden,'old native focus kept a blank background over active Bags')
bags.away='visit';tick();ControllerForever.Kit.fades={[GameTooltip]={on=true}};driver.OnUpdate(driver,1/60)
assert(bg.hidden,'a faded native tooltip left its backing visible')
ControllerForever.Kit.fades=nil
activeFrame=MerchantFrame;tick();ForeverHandheldComms={active=true};tick()
assert(GameTooltip.points[1][2]==vendorItem and bg.hidden,'merchant detail consumed the chat rail')
print('PASS: merchant tooltip and fitting comparison use the companion detail area, preserving data and restoring native anchors on focus loss, chat or overflow.')

local gamepad,group=true,false
InputUtil={IsGamepadUIEnabled=function()return gamepad end}
function IsInGroup()return group end
ForeverHandheldComms.active=false
LootFrame=obj('LootFrame',UIParent,true)
LootFrame.w,LootFrame.h,LootFrame.right=224,110,244
function LootFrame:Open()
 self:ClearAllPoints();self:SetPoint('CENTER',UIParent,'CENTER',0,0)
end
local lootRow=obj(nil,LootFrame,true)
function lootRow:GetSlotIndex()return 1 end
RXPFrame=obj('RXPFrame',UIParent,true);RXPFrame.bottom=550
assert(driver.event=='PLAYER_LOGIN')
driver.OnEvent()
LootFrame:Open()
assert(LootFrame.points[1][1]=='TOPLEFT' and LootFrame.points[1][4]==20 and LootFrame.points[1][5]==-286,'loot covered the guide or center')
group=true;LootFrame:Open();assert(LootFrame.points[1][1]=='CENTER','grouped loot covered party frames')
group=false;LootFrame.isInEditMode=true;LootFrame:Open();assert(LootFrame.points[1][1]=='CENTER','loot Edit Mode lost its preview anchor')
LootFrame.isInEditMode=false;LootFrame.acquiredFromItem=true;LootFrame:Open();assert(LootFrame.points[1][1]=='CENTER','bag loot was moved away from its parent')
LootFrame.acquiredFromItem=false;combat=true;LootFrame:Open();assert(LootFrame.points[1][1]=='CENTER','loot repositioned in combat')
combat=false;LootFrame:Open()
activeFrame=LootFrame;GameTooltip.item=false;GameTooltip:SetOwner(lootRow,'ANCHOR_RIGHT')
tick();assert(GameTooltip.points[1][5]==-330 and GameTooltip:GetOwner()==lootRow and ForeverHandheldDB.itemDetails.loot)
GameTooltip:SetOwner(lootRow,'ANCHOR_RIGHT');assert(GameTooltip.points[1][5]==-330,'native loot refresh moved the detail back to the center')
ShoppingTooltip1.hidden=false;ShoppingTooltip1.w=240;ShoppingTooltip1.h=110
GameTooltip.w=190;GameTooltip.h=90;tick()
assert(GameTooltip.points[1][4]==-19 and ShoppingTooltip1.points[1][4]==-19 and ShoppingTooltip1.points[1][5]==-448,'fitting loot comparison did not stack below the item')
ShoppingTooltip1.h=180;tick()
assert(ShoppingTooltip1.points[1][4]==-221 and ShoppingTooltip1.points[1][5]==-330,'tall loot comparison spilled out of the right rail')
C_TooltipComparison.CompareItem({},GameTooltip)
assert(ShoppingTooltip1.points[1][4]==-221,'native comparison refresh moved the loot comparison back over the world')
ShoppingTooltip1.w=400;tick()
assert(GameTooltip.points[1][2]==lootRow and ShoppingTooltip1.points[1][2]==GameTooltip and bg.hidden,'loot comparison that cannot fit did not restore its native layout')
ShoppingTooltip1.w=240;tick();group=true;tick()
assert(GameTooltip.points[1][2]==lootRow and ShoppingTooltip1.points[1][2]==GameTooltip,'grouped loot comparison replaced native geometry')
group=false;ShoppingTooltip1.hidden=true;tick()
gamepad=false;tick();assert(bg.hidden and GameTooltip.points[1][2]==lootRow,'switching from gamepad retained the loot detail anchor')
print('PASS: solo corpse loot stays below the guide, with fitted native comparisons stacked or side by side in the right rail. Overflow, grouped, bag, Edit Mode, keyboard and combat preserve native geometry.')
