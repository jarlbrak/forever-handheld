local frames,combat,writes={},false,0
local M={}
function M:IsForbidden()return self.forbidden end
function M:IsProtected()return self.protected end
function M:IsShown()return not self.hidden end
function M:GetParent()return self.parent end
function M:GetWidth()return self.w end
function M:GetHeight()return self.h end
function M:SetHeight(v)self.h=v;writes=writes+1 end
function M:SetWidth(v)self.w=v;writes=writes+1 end
function M:GetText()return self.text end
function M:SetText(v)self.text=v;writes=writes+1 end
function M:GetSpacing()return self.spacing or 9 end
function M:SetSpacing(v)self.spacing=v;writes=writes+1 end
function M:SetWordWrap(v)self.wrap=v end
function M:GetScale()return self.scale or 1 end
function M:SetScale(v)self.scale=v;writes=writes+1 end
function M:GetPoint()return unpack(self.point or {})end
function M:SetPoint(...)self.point={...};writes=writes+1 end
function M:ClearAllPoints()self.point=nil end
function M:GetFrameStrata()return self.strata or 'HIGH'end
function M:GetFrameLevel()return self.level or 20 end
function M:SetFrameStrata(v)self.strata=v end
function M:SetFrameLevel(v)assert(not self.native);self.level=v end
function M:GetRegions()return unpack(self.regions or {})end
function M:GetDrawLayer()return self.drawLayer or 'BACKGROUND'end
function M:GetStringHeight()return self.stringHeight or 32 end
function M:GetChildren()return unpack(self.children or {})end
function M:SetAllPoints()assert(not self.native)end
function M:EnableMouse(v)assert(not self.native);self.mouse=v end
function M:Hide()assert(not self.native);self.hidden=true end
function M:Show()assert(not self.native);self.hidden=false end
function M:SetScript(k,fn)assert(not self.native);self[k]=fn end
function M:IsObjectType(t)return self.kind==t end
function M:GetFont()return 'Font',self.font or 12,''end
function M:SetFont(_,n)self.font=n;writes=writes+1 end
function M:SetColorTexture(...)assert(not self.native);self.color={...}end
local function obj(name,parent,native)
 local f=setmetatable({name=name,parent=parent,native=native,w=100,h=100},{__index=M})
 frames[#frames+1]=f;if name then _G[name]=f end;return f
end
function M:CreateTexture()return obj(nil,self)end
function CreateFrame(_,name,parent)return obj(name,parent,false)end
function InCombatLockdown()return combat end
function GetTime()return 123 end
UIParent=obj('UIParent');UIParent.w=1280;UIParent.h=800
local root=obj('ControllerForeverShoulderSetup',UIParent,true);root.w=870;root.h=598
local detail=obj('ControllerForeverKeybindDetail',root,true);detail.w=240;detail.h=598
local picker=obj('ControllerForeverPicker',root,true);picker.w=588;picker.h=612;picker.hidden=true;picker.level=30
root.children={detail,picker};root.detail=detail
local function fs(parent,size)
 local f=obj(nil,parent,true);f.kind='FontString';f.font=size;parent.regions=parent.regions or {};table.insert(parent.regions,f);return f
end
root.hint=fs(root,12);root.hint.text='A Select        B Close\nDpad Move        L3 Combat sets'
detail.mouseNote=fs(detail,11)
picker.how=fs(picker,10.5)
local cat=obj(nil,picker,true);cat.name=fs(cat,11.5);cat.count=fs(cat,10.5);picker.catRows={cat}
local card=obj(nil,picker,true);card.name=fs(card,11.5);card.kind=fs(card,9.5);picker.cards={card};picker.children={cat,card}

local label=obj(nil,root,true);label.kind='FontString';table.insert(root.regions,label)
local protected=obj(nil,root,true);protected.protected=true;protected.regions={obj(nil,protected,true)};root.children[#root.children+1]=protected
local original=function()error('native action invoked')end
root.OnClick=original;picker.OnClick=original;root.bindings={original}
dofile(arg[1]);local driver=frames[#frames]
local function tick()driver.OnUpdate(driver,.3);assert(not (ForeverHandheldDB and ForeverHandheldDB.keybindWorkspaceError),ForeverHandheldDB and ForeverHandheldDB.keybindWorkspaceError)end
tick()
assert(root.scale>1,'detail-only editor unnecessarily shrunk for hidden picker')
assert((870+232)*root.scale<=1216.01 and 638*root.scale<=704.01,'editor union exceeds margins')
assert(root.point[1]=='TOPLEFT' and root.point[3]=='TOPLEFT','editor not placed as a workspace')
assert(not root.hint.text:find('        ',1,true),'oversized hint gaps remain')
assert(detail.mouseNote.font==13,'mouse instructions overlap buttons')
assert(label.font==14 and not protected.regions[1].font,'readability or protected guards failed')
local before=writes;tick();assert(before==writes,'settled layout repeatedly written')
picker.hidden=false;tick()
assert(card.name.wrap and card.name.h==30 and cat.name.wrap,'long names still truncated')
assert(card.kind.font==11 and picker.how.w==500,'picker secondary labels overflow')
assert(picker.point[1]=='CENTER' and picker.point[2]==UIParent,'picker not centered on screen')
assert(picker:GetScale()*root:GetScale()*612<=720.01,'picker exceeds vertical margin')
assert(ForeverHandheldKeybindShade.mouse==false and not ForeverHandheldKeybindShade.hidden,'missing noninteractive backdrop')
assert(picker:GetFrameStrata()=='DIALOG','picker must cover editor rim')
assert(ForeverHandheldKeybindShade.level<picker.level,'backdrop covers picker')
before=writes;tick();assert(before==writes,'picker layout churn')
picker.hidden=true;tick();assert(ForeverHandheldKeybindShade.hidden,'picker close left backdrop')
picker.hidden=false;root.parent=obj('EmbeddedHost');before=writes;tick()
assert(root.h==598 and picker:GetFrameStrata()=='HIGH' and ForeverHandheldKeybindShade.hidden,'embedded owner layout not restored')
root.parent=UIParent;root.hidden=true;tick();assert(ForeverHandheldKeybindShade.hidden,'editor close left backdrop')
root.hidden=false;combat=true;before=writes;tick();assert(before==writes,'combat presentation mutation')
combat=false;root.protected=true;before=writes;tick();assert(before==writes,'protected editor mutated')
root.protected=false;UIParent.w=800;UIParent.h=600;tick()
assert((870+232)*root.scale<=736.01 and 638*root.scale<=504.01,'smaller viewport does not fit')
assert(root.OnClick==original and picker.OnClick==original and root.bindings[1]==original,'native handlers/bindings changed')
print('PASS: actual visible-pane fit, centered readable picker, stable layout, native actions/bindings preserved, embed/protected/combat guards, viewport adaptation and backdrop close cleanup')

UIParent.w=1280;UIParent.h=800;detail.hidden=true
local edit=obj(nil,picker,true);edit.w=400;edit.h=446;edit.rows={obj(nil,edit,true)};edit.rows[1].text=fs(edit.rows[1],12);edit.title=fs(edit,14);edit.count=fs(edit,10);edit.hint=fs(edit,11);picker.editBox=edit
picker.hidden=false;tick()
assert(edit.w==620 and edit.rows[1].w==596 and edit.rows[1].text.font==14,'nested macro editor remains cramped')
assert(edit.point[1]=='CENTER' and edit.point[2]==UIParent,'nested editor not centered')
assert(edit:GetScale()*picker:GetScale()*root:GetScale()*edit.h<=680.01,'nested editor exceeds viewport')
assert(ForeverHandheldBindingModalShade and not ForeverHandheldBindingModalShade.hidden,'nested shade missing')
assert(edit:GetFrameStrata()=='FULLSCREEN_DIALOG' and ForeverHandheldBindingModalShade:GetFrameStrata()=='FULLSCREEN_DIALOG','parent artwork can cross modal')
before=writes;tick();assert(writes==before,'nested layout churn')
edit.hidden=true;tick();assert(ForeverHandheldBindingModalShade.hidden,'nested shade remains after close');assert(edit:GetFrameStrata()=='HIGH','nested strata not restored')
edit.hidden=false;tick();combat=true;tick();assert(ForeverHandheldBindingModalShade.hidden,'nested shade survives combat defer')
combat=false;root.hidden=true;tick();assert(ForeverHandheldBindingModalShade.hidden,'nested shade survives parent close')
print('PASS: centered nested editor, readable native rows, stable layout, native actions preserved and close/combat cleanup')

root.hidden=false;picker.hidden=true;detail.hidden=false
local cover=obj(nil,root,true);local tab=obj(nil,root,true)
local about,info=fs(cover,16),fs(cover,17);about.stringHeight=108;info.stringHeight=38
local button=obj(nil,cover,true);button.OnClick=original
root.crSide={cover=cover,tab=tab,about=about,info=info,buttons={button}}
local switch=obj(nil,root,true);switch.w=106;switch.point={'CENTER',root,'TOPLEFT',70,-65};root.crCombatSwitch=switch
tick()
assert(about.w==460 and about.point[5]==-190,'Extra Bars paragraph not fitted')
assert(info.point[5]==-312 and button.point[5]==-385,'Extra Bars paragraph, state and action overlap')
assert(switch.point[4]==758 and switch.w==130 and button.OnClick==original,'combat switch overlaps tab or native action changed')
before=writes;tick();assert(writes==before,'settled Extra Bars geometry churn')
tab.hidden=true;cover.hidden=true;tick();assert(switch.point[4]==70 and switch.w==106,'combat switch baseline not restored')
print('PASS: Extra Bars controls, paragraph, selection and tab have separate space with native actions preserved')

root.hidden=true;tick();root.hidden=false
local tutorial=obj('ControllerForeverTutorial',UIParent,true);tutorial.hidden=true
local back='CLICK ControllerForeverTutorialLeave:LeftButton';local cleared=0
function GetBindingAction(key)return key=='PAD2' and back or 'CLICK ControllerForeverPadNavDown:LeftButton'end
ControllerForever={Binds={layer=function(_,owner)
 assert(owner==tutorial,'wrong binding owner')
 return {clear=function()cleared=cleared+1;back='CLICK ControllerForeverPadNavBack:LeftButton';return true end}
end}}
tick();tick();assert(cleared==1 and ForeverHandheldDB.keybindHandoff.back==back,'hidden tutorial override not released once')
root.hidden=true;tick();root.hidden=false;tutorial.hidden=false
back='CLICK ControllerForeverTutorialLeave:LeftButton';tick();assert(cleared==1,'visible tutorial override was cleared')
print('PASS: release only a hidden tutorial override that still owns editor Back')
