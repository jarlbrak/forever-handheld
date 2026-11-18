-- Journey stops use an addon-owned marker on the native map canvas. No user
-- waypoint, supertracking or native map-provider state is changed.
local R={version='3.7.163'}
ForeverHandheldRouteMap=R
local pending,marker,elapsed,driver,update
local function safe(v)return not (issecretvalue and issecretvalue(v)) end
local function number(v)return safe(v) and type(v)=='number' and v==v and v>-math.huge and v<math.huge end
function R.parse(links)
 local out,seen={},{}
 if type(links)~='table' then return out end
 for _,link in ipairs(links)do
  if safe(link) and type(link)=='string' then
   local map,x,y,label=link:match('|Hworldmap:(%d+):(%d+):(%d+)|h%[([^%]]+)%]|h')
   map,x,y=tonumber(map),tonumber(x),tonumber(y)
   if map and map>0 and x and y and x<=10000 and y<=10000 then
    local key=map..':'..x..':'..y
    if not seen[key] then
     seen[key]=true;out[#out+1]={map=map,x=x/10000,y=y/10000,label=label:gsub('^Map pin: ','')}
    end
   end
  end
  if #out>=6 then break end
 end
 return out
end
function R.clear()
 pending=nil;elapsed=0
 if driver then driver:SetScript('OnUpdate',nil) end
 if marker then marker:Hide() end
end
function R.open(root,stop)
 local openMap=C_Map and C_Map.OpenWorldMap
 if InCombatLockdown() or not root or not root:IsShown() or not stop or type(openMap)~='function' then return false end
 R.clear()
 root:Hide() -- releases Journey's controller claim before native map navigation
 -- The engine emits WORLD_MAP_OPEN with the requested map ID. Its native
 -- event handler owns map/footer updates; calling the global Lua wrapper
 -- here can taint the bindings it rebuilds when changing to another zone.
 local ok=pcall(openMap,stop.map)
 local map=WorldMapFrame
 if not ok or not map or not map:IsShown() then root:Show();return false end
 pending={root=root,stop=stop,map=map}
 driver:SetScript('OnUpdate',update)
 R.tick()
 return true
end
function R.tick()
 if not pending then return end
 local p=pending
 if not p.map:IsShown() then
  R.clear()
  if not InCombatLockdown() then p.root:Show() end
  return
 end
 if InCombatLockdown() then R.clear();return end
 local canvas=p.map.GetCanvas and p.map:GetCanvas()
 local mapID=p.map:GetMapID()
 if not canvas or not safe(mapID) or mapID~=p.stop.map then if marker then marker:Hide() end;return end
 local level,mapScale,canvasScale=canvas:GetFrameLevel(),p.map:GetEffectiveScale(),canvas:GetEffectiveScale()
 local width,height,x,y=canvas:GetWidth(),canvas:GetHeight(),p.stop.x,p.stop.y
 -- Native map geometry may briefly be unavailable during a canvas change.
 -- Keep the pending handoff, but never compare or calculate restricted data.
 if not number(level) or not number(mapScale) or not number(canvasScale) or not number(width) or not number(height) or
  not number(x) or not number(y) or mapScale<=0 or canvasScale<=0 or width<=0 or height<=0 then
  if marker then marker:Hide() end;return
 end
 local scale=mapScale/canvasScale
 local px,py=width*x/scale,-height*y/scale
 if not marker then
  marker=CreateFrame('Frame','ForeverHandheldJourneyMapMarker',canvas,'BackdropTemplate')
  marker:EnableMouse(false);marker:SetSize(32,32)
  marker:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=2})
  marker:SetBackdropColor(.025,.03,.029,1);marker:SetBackdropBorderColor(.95,.78,.38,1)
  local icon=marker:CreateTexture(nil,'ARTWORK');icon:SetPoint('TOPLEFT',4,-4);icon:SetPoint('BOTTOMRIGHT',-4,4)
  icon:SetTexture('Interface\\Icons\\INV_Misc_Map_01')
  local card=CreateFrame('Frame',nil,marker,'BackdropTemplate');card:EnableMouse(false)
  card:SetPoint('TOP',marker,'BOTTOM',0,-3);card:SetSize(224,45)
  card:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
  card:SetBackdropColor(.025,.03,.029,.96);card:SetBackdropBorderColor(.5,.42,.25,1)
  marker.label=card:CreateFontString(nil,'OVERLAY');marker.label:SetFont(STANDARD_TEXT_FONT,14,'')
  marker.label:SetPoint('TOPLEFT',6,-5);marker.label:SetPoint('BOTTOMRIGHT',-6,5);marker.label:SetTextColor(.95,.85,.6)
 end
 -- Only this module paints the marker. Continue reading native geometry,
 -- but avoid rebuilding its layout and caption while the map is stationary.
 if marker.routeCanvas~=canvas then marker:SetParent(canvas) end
 if marker.routeCanvas~=canvas or marker.routeLevel~=level then marker:SetFrameLevel(level+30);marker.routeLevel=level end
 if marker.routeScale~=scale then marker:SetScale(scale);marker.routeScale=scale end
 if marker.routeCanvas~=canvas or marker.routePX~=px or marker.routePY~=py then
  marker:ClearAllPoints();marker:SetPoint('CENTER',canvas,'TOPLEFT',px,py)
  marker.routeCanvas,marker.routePX,marker.routePY=canvas,px,py
 end
 if marker.routeCaption~=p.stop.label or marker.routeX~=x or marker.routeY~=y then
  marker.label:SetText(p.stop.label..string.format('\n%.1f, %.1f',x*100,y*100))
  marker.routeCaption,marker.routeX,marker.routeY=p.stop.label,x,y
 end
 if not marker:IsShown() then marker:Show() end
end
function R.layout(root,info,y)
 local ok,links=false,nil
 if type(root.GetRoutePins)=='function' then ok,links=pcall(root.GetRoutePins,root) end
 local stops=R.parse(ok and links)
 info.stopButtons=info.stopButtons or {}
 for i,stop in ipairs(stops)do
  local b=info.stopButtons[i]
  if not b then
   b=CreateFrame('Button',nil,info.content,'UIPanelButtonNoTooltipTemplate')
   b:SetScript('OnClick',function(self)root.foreverJourneyResumeChoice=self;R.open(root,self.stop)end);info.stopButtons[i]=b
  end
  b.stop=stop;b:SetSize(268,40);b:ClearAllPoints();b:SetPoint('TOPLEFT',info.content,'TOPLEFT',10,-y)
  b:SetText('Map: '..stop.label)
  local fs=b:GetFontString();if fs then fs:SetFont(STANDARD_TEXT_FONT,14,'');fs:SetWidth(248) end
  b.foreverJourneyLabel='View '..stop.label;b.foreverJourneyScroll=info.frame
  b:Show();y=y+48
 end
 for i=#stops+1,#info.stopButtons do info.stopButtons[i]:Hide() end
 return y
end
driver=CreateFrame('Frame')
elapsed=0
update=function(_,dt)
 if not pending then return end
 elapsed=elapsed+dt;if elapsed<.1 then return end;elapsed=0
 local ok,err=pcall(R.tick)
 if not ok then R.clear();ForeverHandheldDB=ForeverHandheldDB or {};ForeverHandheldDB.routeMapError=tostring(err) end
end
