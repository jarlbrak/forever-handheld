local driver,combat,opened,chrome
function CreateFrame(_,name,parent)
 if name=='ForeverHandheldQuestMenuBackdrop' then
  chrome={parent=parent,width=0,height=0,widthWrites=0}
  function chrome:EnableMouse(v)assert(v==false)end
  function chrome:SetBackdrop()end
  function chrome:SetBackdropColor()end
  function chrome:SetBackdropBorderColor()end
  function chrome:SetScript(k,v)self[k]=v end
  function chrome:SetParent(p)self.parent=p end
  function chrome:ClearAllPoints()self.points={}end
  function chrome:SetPoint(p,f)self.points[p]=f end
  function chrome:GetFrameLevel()return self.level end
  function chrome:SetFrameLevel(v)self.level=v end
  function chrome:GetFrameStrata()return self.strata end
  function chrome:SetFrameStrata(v)self.strata=v end
  function chrome:GetWidth()return self.width end
  function chrome:SetWidth(w)self.width=w;self.widthWrites=self.widthWrites+1 end
  function chrome:GetHeight()return self.height end
  function chrome:SetHeight(h)self.height=h end
  function chrome:IsShown()return self.shown end
  function chrome:Hide()self.shown=false end
  function chrome:Show()self.shown=true end
  return chrome
 end
 driver={SetScript=function(s,k,v)s[k]=v end};return driver
end
function InCombatLockdown()return combat end
function GetTime()return 100 end
function issecretvalue(v)return type(v)=='table' and v.secret end
UIParent={GetWidth=function()return 1280 end,GetHeight=function()return 800 end,GetEffectiveScale=function()return 1 end}
local function frame(parent)
 local f={parent=parent,children={},regions={},scale=1,w=150,h=200,writes=0}
 function f:IsForbidden()return self.forbidden end
 function f:IsProtected()return self.protected end
 function f:IsShown()return not self.hidden end
 function f:GetParent()return self.parent end
 function f:GetChildren()return unpack(self.children)end
 function f:GetRegions()return unpack(self.regions)end
 function f:GetScale()return self.scale end
 function f:SetScale(v)self.scale=v;self.writes=self.writes+1 end
 function f:GetEffectiveScale()return self.scale end
 function f:GetWidth()return self.w end
 function f:GetHeight()return self.h end
 function f:GetNumPoints()return self.relative and 1 or 0 end
 function f:GetPoint()return 'TOPLEFT',self.relative,'TOPRIGHT',0,0 end
 if parent then table.insert(parent.children,f)end
 return f
end
local function label(size)
 return {IsObjectType=function(_,k)return k=='FontString'end,IsShown=function()return true end,
 GetText=function()return 'Native filter'end,GetFont=function()return 'Native',size,''end,
 SetFont=function()error('native text mutation')end,SetFontObject=function()error('native font mutation')end}
end
ProfessionsFrame=frame();ProfessionsFrame.protected=true
local owner=frame(ProfessionsFrame);owner.protected=true
local world=frame();local root=frame(world);root.owner=owner;root.regions={label(12)}
function root:GetOwnerRegion()return self.owner end
function root:EnumerateElementDescriptions()error('native descriptions accessed')end
local row=frame(root);row.selected=true;row.action=function()error('native action invoked')end;local action=row.action
local sub=frame(world);sub.relative=row;sub.regions={label(12)}
sub.GetOwnerRegion=root.GetOwnerRegion;sub.EnumerateElementDescriptions=root.EnumerateElementDescriptions
local other=frame(world);other.regions={label(12)};other.GetOwnerRegion=root.GetOwnerRegion;other.EnumerateElementDescriptions=root.EnumerateElementDescriptions
opened=root;Menu={GetManager=function()return {GetOpenMenu=function()return opened end}end}
dofile(arg[1]);local function tick()driver.OnUpdate(driver,.1)end;tick()
assert(math.abs(root.scale-4/3)<.001 and math.abs(sub.scale-4/3)<.001,'root/submenu not readable')
assert(other.scale==1 and row.action==action and row.selected and sub.relative==row,'unrelated menu or native interaction changed')
assert(ForeverHandheldDB.professionMenus.count==2,'submenu discovery failed')
local rw,sw=root.writes,sub.writes;tick();assert(root.writes==rw and sub.writes==sw,'settled scale churn')
sub.hidden=true;tick();assert(sub.scale==1,'closed submenu not restored')
root.hidden=true;tick();assert(root.scale==1,'closed root not restored')
root.hidden=false;sub.hidden=false;root.owner=frame();tick();assert(root.scale==1 and sub.scale==1,'other context changed')
root.owner=owner;combat=true;tick();assert(root.scale==1,'combat acquisition');combat=false
root.protected=true;tick();assert(root.scale==1,'protected menu changed');root.protected=false
owner.forbidden=true;tick();assert(root.scale==1,'forbidden owner inspected');owner.forbidden=false
root.w={secret=true};tick();assert(root.scale==1,'secret geometry used');root.w=150
root.h=700;tick();assert(root.scale*700<=760.01 and root.scale>=1,'menu viewport bound failed')
opened=nil;tick();root.h=200;opened=root;tick();root.scale=1.1;tick()
assert(math.abs(root.scale-1.1*4/3)<.001,'native scale reset not respected')
root.scale=1.8;opened=nil;tick();assert(root.scale==1.8,'external scale overwritten on release')
assert(not ForeverHandheldDB.professionMenuError)
print('PASS: public displayed-menu scaling; nested native anchors/actions/selection preserved; unrelated and protected menus excluded; hidden/pool reset, external scale, viewport, combat/forbidden/secret guards and stable writes')

root.parent=nil;sub.parent=nil;root.scale=1;sub.scale=1;opened=root
local focusedRow=frame(sub)
SmartNavigation={GetCurrentButton=function()return focusedRow end}
tick();assert(sub.scale>1,'parentless focused submenu not found')
SmartNavigation=nil;tick();assert(sub.scale>1,'open discovered submenu not retained')
sub.hidden=true;tick();assert(sub.scale==1,'parentless closed submenu not restored')
sub.hidden=false;GetMouseFoci=function()return {focusedRow}end
tick();assert(sub.scale>1,'parentless pointer submenu not found')
opened=nil;tick();assert(root.scale==1 and sub.scale==1,'parentless menus not released')
assert(not ForeverHandheldDB.professionMenuError)
print('PASS: parentless native submenus discovered through read-only gamepad/pointer focus, retained while connected and released on closure')

-- At the native frame-level ceiling, footer art must stay behind icon artwork.
local legend=frame(sub);local protectedLegend=frame(sub);protectedLegend.protected=true
local function texture(parent,atlas)
 local t={layer='ARTWORK',sub=0,writes=0}
 function t:GetParent()return parent end
 function t:GetAtlas()return atlas end
 function t:GetDrawLayer()return self.layer,self.sub end
 function t:SetDrawLayer(layer,sub)self.layer=layer;self.sub=sub;self.writes=self.writes+1 end
 table.insert(parent.regions,t);return t
end
local bg=texture(legend,'gamepad-footer-slot-bg')
local border=texture(legend,'gamepad-footer-slot-frameneutral')
local icon=texture(legend,'Gamepad-Xbox1-ButtonA-Normal')
local guarded=texture(protectedLegend,'gamepad-footer-slot-bg')
opened=root;tick()
assert(bg.layer=='BACKGROUND' and border.layer=='BORDER','footer art can obscure icons')
assert(icon.layer=='ARTWORK' and icon.writes==0 and guarded.writes==0,'native icon or protected legend changed')
local bw=bg.writes;tick();assert(bg.writes==bw,'stable layer churn')
sub.scale=1.1;tick();opened=nil;tick()
assert(bg.layer=='ARTWORK' and border.layer=='ARTWORK','pool release failed after scale reset')
opened=root;tick();bg.layer='OVERLAY';opened=nil;tick()
assert(bg.layer=='OVERLAY','external layer overwritten on release')
assert(not ForeverHandheldDB.professionMenuError)
print('PASS: native legend backgrounds behind icons, no icon/binding/protected writes, stable update, restored pooling and external changes preserved')

CollectionsJournal=frame();CollectionsJournal.protected=true
local collectionOwner=frame(CollectionsJournal);root.owner=collectionOwner;root.scale=1;sub.scale=1;opened=root
tick();assert(root.scale>1 and sub.scale>1 and ForeverHandheldDB.professionMenus.context=='CollectionsJournal','collection menus omitted')
CollectionsJournal.hidden=true;tick();assert(root.scale==1 and sub.scale==1,'hidden collection menus not released')
assert(not ForeverHandheldDB.professionMenuError)
print('PASS: collection-owned root/submenu scaling with protected ancestry read-only and hidden context release')

SocialUIFrame=frame();SocialUIFrame.protected=true
local socialOwner=frame(SocialUIFrame);root.owner=socialOwner;opened=root
tick();assert(root.scale>1 and sub.scale>1 and ForeverHandheldDB.professionMenus.context=='SocialUIFrame','social menu context missing')
SocialUIFrame.hidden=true;tick();assert(root.scale==1 and sub.scale==1,'social menu release missing')
assert(not ForeverHandheldDB.professionMenuError)
print('PASS: social root/submenu scaling and context release retain native actions')

for _,name in ipairs({'LFGParentFrame','CommunitiesFrame'})do
 local context=frame();context.protected=true;_G[name]=context
 root.owner=frame(context);opened=root
 tick();assert(root.scale>1 and sub.scale>1 and ForeverHandheldDB.professionMenus.context==name,'group/guild menus omitted')
 context.hidden=true;tick();assert(root.scale==1 and sub.scale==1,'group/guild menu release failed')
 assert(row.action==action and row.selected and not ForeverHandheldDB.professionMenuError)
end
print('PASS: group finder and guild root/submenu scaling, native selection/actions and context release')

WorldMapFrame=frame()
root.owner=frame(WorldMapFrame);root.w=0;opened=root
root.GetLeft=function()return 400 end
root.GetTop=function()return 640 end
root.GetFrameLevel=function()return 507 end
root.GetFrameStrata=function()return 'FULLSCREEN_DIALOG' end
root.SetWidth=function()error('native layout mutated')end
row.GetRight=function()return 580 end
row.GetTop=function()return 632 end
row.GetBottom=function()return 608 end
row.regions={label(12)}
local rimAlpha=1
root.FrameGlow={GetAlpha=function()return rimAlpha end,SetAlpha=function(_,alpha)rimAlpha=alpha end}
tick()
assert(chrome:IsShown() and chrome.width==188 and chrome.parent==root and chrome.level==508,'collapsed map menu backdrop was not fitted from native rows')
assert(chrome.height==40 and rimAlpha==0,'collapsed native ornament or oversized menu height remained')
assert(root.w==0 and root.scale>1 and row.action==action and row.selected,'native map geometry or actions changed')
tick();assert(chrome.widthWrites==1,'settled map backdrop width is written repeatedly')
chrome:OnHide();assert(not chrome:IsShown(),'inherited hide left backdrop eligible for pooled reuse')
opened=nil;tick();assert(chrome.parent==UIParent and root.scale==1 and rimAlpha==1,'pooled map menu paint not restored')
opened=root;root.w=152;tick();assert(root.w==152 and not chrome:IsShown(),'valid native map backdrop was replaced')
opened=nil;tick();assert(not ForeverHandheldDB.professionMenuError)
print('PASS: owned backdrop fits zero-width quest context; native geometry, actions and pooled reuse preserved')
