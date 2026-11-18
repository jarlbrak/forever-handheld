local combat,openCalls=false,0
local M={}
local created={}
local function write(self,key)self.writes=self.writes or {};self.writes[key]=(self.writes[key] or 0)+1 end
function M:IsShown()return not self.hidden end
function M:Show()write(self,'show');self.hidden=false end
function M:Hide()self.hidden=true end
function M:SetShown(v)self.hidden=not v end
function M:SetParent(p)write(self,'parent');self.parent=p;self.level=p:GetFrameLevel()+1 end
function M:SetSize(w,h)self.w=w;self.h=h end
function M:GetWidth()return self.w or 1000 end
function M:GetHeight()return self.h or 700 end
function M:SetScale(v)write(self,'scale');self.scale=v end
function M:GetEffectiveScale()return self.scale or 1 end
function M:SetPoint(...)write(self,'point');self.point={...}end
function M:ClearAllPoints()write(self,'clear')end
function M:SetFrameLevel(v)write(self,'level');self.level=v end
function M:SetText(v)write(self,'text');self.text=v end
function M:GetFrameLevel()return self.level or 10 end
function M:SetScript(k,v)self.scripts[k]=v end
function M:GetFontString()return self.font end
function M:Click()self.scripts.OnClick(self)end
local function frame()
 return setmetatable({scripts={}},{__index=function(t,k)if M[k]then return M[k]end;if k:match('^Set')or k=='ClearAllPoints'or k=='EnableMouse'then return function()end end end})
end
function M:CreateTexture()return frame()end
function M:CreateFontString()return frame()end
function CreateFrame(_,name,parent)
 local f=frame();created[#created+1]=f;f.parent=parent;f.font=frame();if name then _G[name]=f end;return f
end
function InCombatLockdown()return combat end
function issecretvalue(v)return v=='SECRET'end
STANDARD_TEXT_FONT='Font'
local root,canvas=frame(),frame();canvas.w=1000;canvas.h=700;canvas.scale=2
WorldMapFrame=frame();WorldMapFrame.hidden=true
function WorldMapFrame:GetCanvas()return canvas end
function WorldMapFrame:GetMapID()return self.map end
function OpenWorldMap()error('global Lua map wrapper must not be called by route code')end
local function nativeOpen(map)openCalls=openCalls+1;WorldMapFrame.map=map;WorldMapFrame:Show()end
C_Map={OpenWorldMap=nativeOpen,SetUserWaypoint=function()error('native waypoint mutated')end}
C_SuperTrack={SetSuperTrackedUserWaypoint=function()error('native tracking mutated')end}
dofile(arg[1]);local R=ForeverHandheldRouteMap
local driver=created[#created]
if arg[2]~='baseline' then assert(not driver.scripts.OnUpdate,'idle route map keeps a per-render callback') end
local a='|cffffff00|Hworldmap:90:6320:4890|h[Map pin: Michael Garrett]|h|r'
local b='|Hworldmap:90:2700:5400|h[Map pin: Bank]|h'
local stops=R.parse({a,a,b,'|Hworldmap:90:99999:1|h[Bad]|h','SECRET','garbage'})
assert(#stops==2 and stops[1].label=='Michael Garrett' and stops[1].x==.632,'pin decoding/dedupe/bounds')
assert(#R.parse(false)==0,'missing bridge')
local info={content=frame(),frame=frame()}
function root:GetRoutePins()return {a,b}end
assert(R.layout(root,info,100)==196 and #info.stopButtons==2,'route layout height')
info.stopButtons[1]:Click();assert(openCalls==1 and root.hidden,'map did not own navigation')
assert(WorldMapFrame.map==90,'engine map-open handoff changed requested destination')
local marker=ForeverHandheldJourneyMapMarker
assert(driver.scripts.OnUpdate,'successful map handoff did not start tracking')
assert(marker and not marker.hidden and marker.parent==canvas,'marker not on canvas')
assert(marker.scale==.5 and marker.point[4]==1264 and marker.point[5]==-684.6,'map coordinate scaling')
assert(marker.label.text=='Michael Garrett\n63.2, 48.9','selected stop caption')
local function writes(f)local n=0;for _,v in pairs(f.writes or {})do n=n+v end;return n end
local before=writes(marker)+writes(marker.label)
for i=1,600 do R.tick()end
local added=writes(marker)+writes(marker.label)-before
print('Stationary marker writes over 600 ticks: '..added)
if arg[2]=='baseline' then return end
assert(added==0,'stationary map marker repeats layout or caption writes')
local function close(a,b)return math.abs(a-b)<.00001 end
canvas.scale=4;R.tick()
assert(marker.scale==.25 and close(marker.point[4],2528) and close(marker.point[5],-1369.2),'zoom left stale marker scale or position')
canvas.w=1200;canvas.h=800;R.tick()
assert(close(marker.point[4],3033.6) and close(marker.point[5],-1564.8),'canvas resize left stale marker position')
local activeStop=info.stopButtons[1].stop
activeStop.x=.25;activeStop.y=.4;activeStop.label='Harbor';R.tick()
assert(marker.point[4]==1200 and marker.point[5]==-1280 and marker.label.text=='Harbor\n25.0, 40.0','changed stop did not refresh coordinates and caption')
local anchors=marker.writes.point
activeStop.label='New harbor';R.tick()
assert(marker.label.text=='New harbor\n25.0, 40.0' and marker.writes.point==anchors,'label change rebuilt position or retained caption')
canvas.level=20;R.tick();assert(marker.level==50 and marker.writes.point==anchors,'level change rebuilt anchors or retained layering')
WorldMapFrame.scale=2;R.tick()
assert(marker.scale==.5 and marker.point[4]==600 and marker.point[5]==-640,'map scale change did not adjust screen-sized marker')
WorldMapFrame.scale=1
local replacement=frame();replacement.w=900;replacement.h=600;replacement.scale=3;replacement.level=30
canvas=replacement;R.tick()
assert(marker.parent==replacement and marker.level==60 and marker.scale==1/3 and marker.point[2]==replacement and close(marker.point[4],675) and close(marker.point[5],-720),'replacement canvas retained parent, layer or coordinates')
local sameLevel=frame();sameLevel.w=900;sameLevel.h=600;sameLevel.scale=3;sameLevel.level=30
local levelWrites=marker.writes.level
canvas=sameLevel;R.tick()
assert(marker.parent==sameLevel and marker.level==60 and marker.writes.level==levelWrites+1,'reparent to equal-level canvas did not restore marker layering')
local width=canvas.w;canvas.w='SECRET';R.tick()
assert(marker.hidden and driver.scripts.OnUpdate,'restricted geometry did not hide temporarily')
canvas.w=width;R.tick();assert(not marker.hidden,'public geometry did not recover marker')
canvas.scale=0;R.tick();assert(marker.hidden,'zero scale used in marker geometry')
canvas.scale=3;R.tick();assert(not marker.hidden,'scale recovery left marker hidden')
WorldMapFrame.map='SECRET';R.tick();assert(marker.hidden,'restricted map identity leaked marker')
WorldMapFrame.map=90;R.tick();assert(not marker.hidden,'map identity recovery failed')
print('PASS: stationary paint skipped; zoom, resize, coordinates, label, level, map scale and canvas replacement stay live; restricted/zero geometry hides and recovers.')

WorldMapFrame.map=1;R.tick();assert(marker.hidden,'marker leaked to another map')
WorldMapFrame.map=90;R.tick();assert(not marker.hidden,'marker did not return')
WorldMapFrame:Hide();R.tick();assert(not root.hidden and marker.hidden,'map close did not return to route');assert(not driver.scripts.OnUpdate,'map close retained render callback')
combat=true;assert(not R.open(root,stops[1]) and openCalls==1,'combat opened map')
combat=false
C_Map.OpenWorldMap=function()error('native map unavailable')end
assert(not R.open(root,stops[1]) and not root.hidden,'failed map open lost route');assert(not driver.scripts.OnUpdate,'failed open retained render callback')
function root:GetRoutePins()return {}end
assert(R.layout(root,info,100)==100 and info.stopButtons[1].hidden and info.stopButtons[2].hidden,'stale stop buttons retained')
function root:GetRoutePins()return {b}end
R.layout(root,info,100);assert(info.stopButtons[1].stop.label=='Bank','recycled stop retained destination')
C_Map.OpenWorldMap=nativeOpen
R.open(root,stops[1]);combat=true;R.tick();assert(marker.hidden,'combat retained marker state');assert(not driver.scripts.OnUpdate,'combat retained render callback')
WorldMapFrame:Hide();R.tick();assert(root.hidden,'combat opened route unexpectedly')
print('Route map passed: validated stops, recycling, native map handoff, scale/coordinates, map changes, return, failure and combat cleanup; no waypoint or tracking mutation.')

combat=false;root:Show();R.open(root,info.stopButtons[1].stop)
assert(marker.label.text=='Bank\n27.0, 54.0' and driver.scripts.OnUpdate,'recycled destination did not start with current caption')
driver.scripts.OnUpdate(driver,.08);R.clear()
assert(not driver.scripts.OnUpdate and marker.hidden,'explicit clear retained marker or driver')
root:Show();R.open(root,stops[1]);WorldMapFrame:Hide()
driver.scripts.OnUpdate(driver,.03)
assert(root.hidden and driver.scripts.OnUpdate,'elapsed time leaked across clear/reopen')
driver.scripts.OnUpdate(driver,.08)
assert(not root.hidden and not driver.scripts.OnUpdate,'active driver did not handle map close')
root:Show();R.open(root,stops[1]);local realCanvas=WorldMapFrame.GetCanvas
WorldMapFrame.GetCanvas=function()error('canvas unavailable')end
driver.scripts.OnUpdate(driver,.2)
assert(not driver.scripts.OnUpdate and marker.hidden and ForeverHandheldDB.routeMapError,'failed update did not stop tracking and record diagnostic')
WorldMapFrame.GetCanvas=realCanvas
print('PASS: idle/start/close/failure/combat/clear/reopen/recycled destination lifecycle; timer reset and update-error cleanup.')

root:Show();local open=C_Map.OpenWorldMap;C_Map.OpenWorldMap=nil
local calls=openCalls
assert(not R.open(root,stops[1]) and not root.hidden and not driver.scripts.OnUpdate and openCalls==calls,'missing engine map API attempted global fallback or lost root')
C_Map.OpenWorldMap=function()end;WorldMapFrame:Hide()
assert(not R.open(root,stops[1]) and not root.hidden and not driver.scripts.OnUpdate,'ignored map-open request lost route or left tracking active')
C_Map.OpenWorldMap=open
root:Show();R.open(root,stops[1]);WorldMapFrame:Hide();R.tick();R.open(root,stops[2])
assert(WorldMapFrame.map==90 and marker.label.text=='Bank\n27.0, 54.0','second native handoff retained stale stop')
WorldMapFrame:Hide();R.tick()
local otherZone={map=85,x=.5,y=.25,label='Another zone'}
R.open(root,otherZone)
assert(WorldMapFrame.map==85 and marker.label.text=='Another zone\n50.0, 25.0','cross-zone engine handoff lost map ID or caption')
WorldMapFrame:Hide();R.tick()
print('PASS: engine C_Map.OpenWorldMap handoff preserves destination, restores root on failure/no-show, and refuses missing-API/global-Lua fallback.')
