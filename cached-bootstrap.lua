local P=assert(loadfile('C:/Users/Administrator/Documents/Codex/2026-11-22/1-2-rea-3-4-computeruse/outputs/offline-login/original-patcher.ljbc'))()
local out=assert(io.open('C:/Users/Administrator/Documents/Codex/2026-11-22/1-2-rea-3-4-computeruse/outputs/offline-login/bootstrap.log','w'))
local function emit(x)out:write(tostring(x)..string.char(10));out:flush()end
local init=P.Init;local updater
local original=P.OnUpdate;local ticks=0;local complete=false
P.OnUpdate=function(...)
 local g=updater
  ticks=ticks+1
  if not complete and ticks>3 then complete=true;local ok,e=xpcall(function()
   xlua.private_accessible(typeof(CS.NSLGame.Patcher.GameUpdater))
   emit('RESOURCE_INIT');CS.NSLGame.ResSystem.ResourceMgr.Init(true);g.InitedResMgr=true
   emit('UPDATE_COMPLETE');g:StartCoroutine(g:InvokeOnUpdateDoneAfterWarmUp());emit('UPDATE_COMPLETE_SCHEDULED')
  end,debug.traceback);emit(tostring(ok)..' '..tostring(e)) end
  return original(...)
end
P.Init=function(g) updater=g;emit('INIT_BEGIN');local r=init(g);emit('INIT_DONE');return r end
return P
