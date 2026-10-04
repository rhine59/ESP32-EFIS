const menus={boot:["START EFIS","FULL TEST","FAULT LOG","LICENSE","FIRMWARE UPDATE"],license:["STATUS","GET / REFRESH","INSTALL / REPLACE","RESET LICENCE","BACK"],firmware:["MAINTENANCE WI-FI","CHECK FOR UPDATE","DOWNLOAD + VERIFY","STAGE VERIFIED IMAGE","ACTIVATE & REBOOT","BACK"]};
let page="boot",sel=0,state={},manifest=null,events=[];
const $=x=>document.getElementById(x); function log(s){events.unshift(new Date().toLocaleTimeString()+"  "+s);$("log").textContent=events.slice(0,40).join("\n")}
async function api(path,opt){let r=await fetch(path,opt);let j=await r.json();if(!r.ok)throw Error(j.error||r.status);return j}
async function refresh(){state=await api("/api/state");render()}
function lines(items){return items.map((x,i)=>(i===sel?"> ":"  ")+x).join("\n")}
function render(){let t="      EFIS BOOT\n   "+state.device_id+"\n\n";
 if(page==="boot")t+=lines(menus.boot);
 if(page==="license")t="       LICENSE\n\nDevice: "+state.device_id+"\nStatus: "+state.license.status+"\n\n"+lines(menus.license);
 if(page==="firmware")t="   FIRMWARE UPDATE\n\nHorizon  "+state.firmware+"\nCached   "+(state.offline_cache.ready?state.offline_cache.release+" ✓":"NO")+"\nStaged   "+(state.staged||"-")+"\nWi-Fi    "+state.network.toUpperCase()+"\n\n"+lines(menus.firmware);
 $("screen").textContent=t;$("summary").textContent="Device "+state.device_id+" • firmware "+state.firmware+" • licence "+state.license.status+" • network "+state.network}
function move(d){let a=menus[page];sel=(sel+d+a.length)%a.length;render()}
async function choose(){let x=menus[page][sel];log(page+": "+x);
 if(page==="boot"){if(x==="LICENSE"){page="license";sel=0}else if(x==="FIRMWARE UPDATE"){page="firmware";sel=0}else if(x==="START EFIS")log("START EFIS simulated");else log(x+" simulated")}
 else if(page==="license"){if(x==="BACK"){page="boot";sel=0}else if(x==="STATUS"){let j=await api("/api/license/status");log("licence: "+JSON.stringify(j))}else if(x==="GET / REFRESH"){state.license=await api("/api/license/refresh",{method:"POST",body:"{}"});log("signed licence retrieved and Ed25519 verified: "+state.license.class)}else if(x==="INSTALL / REPLACE"){state=await api("/api/license/mock-install",{method:"POST",body:'{"class":"DEVELOPMENT"}'});log("mock licence installed")}else if(x==="RESET LICENCE"){state=await api("/api/license/mock-reset",{method:"POST",body:"{}"});log("licence reset")}}
 else if(page==="firmware"){if(x==="BACK"){page="boot";sel=0}else if(x==="MAINTENANCE WI-FI"){log("local maintenance Wi-Fi is "+state.network)}else if(x==="CHECK FOR UPDATE"){manifest=await api("/api/firmware/check");log("manifest: "+JSON.stringify(manifest))}else if(x==="DOWNLOAD + VERIFY"){state=await api("/api/firmware/cache",{method:"POST",body:"{}"});log("download verified SHA-256; "+state.offline_cache.bytes+" bytes cached")}else if(x==="STAGE VERIFIED IMAGE"){state=await api("/api/firmware/stage",{method:"POST",body:"{}"});log("verified image staged: "+state.staged)}else if(x==="ACTIVATE & REBOOT"){state=await api("/api/firmware/activate",{method:"POST",body:"{}"});log("Horizon image activated; simulated reboot")}}
 render()}
$("up").onclick=()=>move(-1);$("down").onclick=()=>move(1);$("press").onclick=()=>choose().catch(e=>log("ERROR "+e));$("back").onclick=()=>{page="boot";sel=0;render()};
document.onkeydown=e=>{if(e.key==="ArrowUp")move(-1);if(e.key==="ArrowDown")move(1);if(e.key==="Enter")choose().catch(x=>log("ERROR "+x));if(e.key==="Escape"){$("back").click()}};
document.querySelectorAll("[data-net]").forEach(b=>b.onclick=async()=>{state=await api("/api/sim/network",{method:"POST",body:JSON.stringify({state:b.dataset.net})});log("network "+b.dataset.net);render()});
$("lic").onclick=async()=>{state=await api("/api/license/mock-install",{method:"POST",body:'{"class":"DEVELOPMENT"}'});render()};$("unlic").onclick=async()=>{state=await api("/api/license/mock-reset",{method:"POST",body:"{}"});render()};$("reset").onclick=async()=>{state=await api("/api/sim/reset",{method:"POST",body:"{}"});page="boot";sel=0;log("reset");render()};refresh();
