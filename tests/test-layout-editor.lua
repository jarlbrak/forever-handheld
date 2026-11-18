local frames,combat,writes={},false,0
local M={}
function M:IsForbidden()return self.forbidden end
function M:IsProtected()return self.protected end
function M:IsShown()return not self.hidden end
function M:GetWidth()return self.w or 100 end
function M:GetHeight()return self.h or 20 end
function M:GetFont()return 'Font',self.font or 11,''end
function M:GetPoint()return unpack(self.point or {})end
local function changed(self)assert(not combat,'combat mutation');assert(not self.forbidden and not self.protected,'restricted mutation');writes=writes+1 end
function M:SetPoint(...)changed(self);self.point={...}end
function M:ClearAllPoints()changed(self);self.point=nil end
function M:SetWidth(v)changed(self);self.w=v end
function M:SetHeight(v)changed(self);self.h=v end
function M:SetFont(_,n)changed(self);self.font=n end
function M:SetWordWrap(v)changed(self);self.wrap=v end
function M:SetJustifyH(v)changed(self);self.justifyH=v end
function M:SetJustifyV(v)changed(self);self.justifyV=v end
function M:SetSpacing(v)changed(self);self.spacing=v end
function M:SetColorTexture(...)changed(self);self.color={...}end
function M:IsClampedToScreen()return self.clamped end
function M:SetClampedToScreen(v)changed(self);self.clamped=v end
function M:GetStringHeight()
 local n=0;for line in ((self.text or '')..'\n'):gmatch('(.-)\n')do n=n+math.max(1,math.ceil(#line/(self:GetWidth()/((self.font or 11)*.5))))end
 return n*((self.font or 11)+(self.spacing or 0))
end
local function obj(name)
 local f=setmetatable({},{__index=M});frames[#frames+1]=f;if name then _G[name]=f end;return f
end
function M:SetScript(k,v)assert(not self.native,'native handler replaced');self[k]=v end
function CreateFrame(_,name)return obj(name)end
function InCombatLockdown()return combat end
function GetTime()return 10 end
local p=obj('ControllerForeverEditPanel');p.w=1264;p.h=54;p.title=obj();p.hint=obj();p.bg=obj()
p.title.text='EDIT LAYOUT MOVE SIMPLE Whole Layout (1/37) Step 5 Grid On'
p.hint.text=string.rep('native controller glyphs and actions ',10)..'\nKeyboard hints retained'
local o=obj('ControllerForeverEditOptions');o.w=300;o.h=190;o.title=obj();o.body=obj();o.bg=obj();o.title.text='WHOLE LAYOUT';o.body.text=string.rep('Native action information\n',8)
local callback=function()error('native action invoked')end
p.native=true;o.native=true;p.OnKeyDown=callback;p.bindings={callback};o.OnClick=callback
local nativeTitle,nativeHint,nativeBody=p.title.text,p.hint.text,o.body.text
local originalPosition={'TOPLEFT','UIParent','BOTTOMLEFT',0,300};o.point=originalPosition
dofile(arg[1]);local driver=frames[#frames]
local function tick()driver.OnUpdate(driver,.2);assert(not (ForeverHandheldDB and ForeverHandheldDB.layoutEditorError),ForeverHandheldDB and ForeverHandheldDB.layoutEditorError)end
tick()
assert(p.h>54 and p.hint.font==15 and p.title.font==17,'toolbar not readable')
assert(o.w==360 and o.body.font==16 and o.body.wrap and o.clamped,'options not bounded/readable')
assert(o.point==originalPosition,'native selected-part position replaced')
assert(p.title.text==nativeTitle and p.hint.text==nativeHint and o.body.text==nativeBody,'native text changed')
assert(p.hint.point[5]+-p.hint.h>=-p.h+10,'toolbar clipped')
local n=writes;tick();assert(writes==n,'stable layout churn')
o.body.text=string.rep('long part note ',60);tick();assert(o.h>190 and o.h==o.title.h+o.body.h+40,'long note clipped')
o.body.text='short';tick();assert(o.h<190,'stale panel height')
combat=true;n=writes;tick();assert(n==writes,'combat write');combat=false
p.hidden=true;n=writes;tick();assert(n==writes,'hidden editor write');p.hidden=false
p.protected=true;n=writes;tick();assert(n==writes,'protected root write');p.protected=false
p.hint.forbidden=true;n=writes;tick();assert(n==writes,'forbidden hint write');p.hint.forbidden=false
-- Recycled native dimensions are corrected without changing selected item/input.
o.w=300;o.h=190;tick();assert(o.w==360 and o.h<190,'native redraw not handled')
assert(p.OnKeyDown==callback and p.bindings[1]==callback and o.OnClick==callback,'native actions changed')
print('PASS: readable wrapped toolbar/options, long-note sizing, stable writes, preserved native text/position/actions, redraw handling and hidden/combat/protected/forbidden guards')
-- The native All Parts/Copy Size list keeps its own rows, focus and colors.
function M:SetVertexColor(...)changed(self);self.tint={...}end
local list=obj('ControllerForeverEditList');list.w=990;list.h=336;list.bg=obj();list.title=obj();list.tabs=obj();list.footer=obj();list.tiles={}
list.title.text='ALL PARTS';list.tabs.text='LT Controller Forever Unit Frames Info Bars and Other RT';list.footer.text='A Go to that part  D-pad Pick a tile  B Back'
list.native=true;list.OnKeyDown=callback
for i=1,12 do
 local tile=obj();tile.native=true;tile.w=230;tile.h=62;tile.point={'TOPLEFT',list,'TOPLEFT',15+((i-1)%4)*240,-82-math.floor((i-1)/4)*72};tile.name=obj();tile.state=obj();tile.bg=obj();tile.name.text=i==1 and 'Personal Resource Display' or 'Native part';tile.state.text=i==1 and 'Not Showing' or '100%';tile.OnClick=callback;list.tiles[i]=tile
end
local originalTilePoint=list.tiles[1].point;tick()
assert(list.title.font==20 and list.tabs.font==16 and list.footer.font==15,'list heading/hints remain small')
assert(list.tiles[1].name:GetStringHeight()<=32,'two-line native name clipped')
for _,tile in ipairs(list.tiles)do
 assert(tile.name.font==16 and tile.state.font==15,'tile text too small')
 assert(-tile.name.point[5]+tile.name.h<=-tile.state.point[5],'name overlaps state')
 assert(-tile.state.point[5]+tile.state.h<=tile.h-3,'state clips tile')
 assert(tile.w==230 and tile.h==62 and tile.OnClick==callback,'native tile or handler changed')
 assert(tile.bg.tint[1]==.5 and tile.bg.tint[2]==.4 and tile.bg.tint[3]==.25,'neutral tint missing')
end
assert(list.tiles[1].point==originalTilePoint and list.OnKeyDown==callback,'native focus geometry changed')
n=writes;tick();assert(writes==n,'stable grid churn')
-- Recycled native colors and labels stay under native ownership; tint is separate.
list.tiles[1].bg.color={.2,.16,.06,.95};list.tiles[1].name.text='Selected native part';list.title.text='COPY SIZE TO WHOLE LAYOUT';tick()
assert(list.tiles[1].bg.color[1]==.2 and list.tiles[1].name.text=='Selected native part','selection data overwritten')
list.hidden=true;n=writes;tick();assert(writes==n,'hidden grid write');list.hidden=false
combat=true;n=writes;tick();assert(writes==n,'grid combat write');combat=false
list.protected=true;n=writes;tick();assert(writes==n,'protected grid write');list.protected=false
print('PASS: native grid typography, two-line names, state clearance, selection tint, unchanged geometry/text/handlers, no stable/hidden/combat/protected writes')
