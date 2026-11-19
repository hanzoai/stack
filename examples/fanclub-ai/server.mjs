/**
 * FanClub AI / Hanzo OS reference app — a SYNTHETIC-DATA PROTOTYPE.
 *
 * HTTP, SQLite and the in-process baseline are temporary local demo adapters.
 * The production migration is to Hanzo Cloud + Framework/Base, IAM, Engine, MCP.
 * No authentication in demo mode: NEVER expose this server on a public interface.
 */
import { createServer } from 'node:http';
import { DatabaseSync } from 'node:sqlite';
import { randomUUID } from 'node:crypto';
import { readFile, mkdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { join, extname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('.', import.meta.url));
const publicRoot = join(root, 'public');
const port = Number(process.env.PORT || 4377);
const databasePath = process.env.FANCLUB_DB || join(root, '.data', 'fanclub.sqlite');
const ENGINE_URL = (process.env.HANZO_ENGINE_URL || '').replace(/\/$/, '');
const ENGINE_MODEL = process.env.HANZO_ENGINE_MODEL || 'zen6-nano';
const tenants = [
  { id:'northstar', name:'Northstar United', industry:'Sports & community', noun:'supporters', color:'#c5f579', plan:'Club Intelligence' },
  { id:'solstice', name:'Solstice Museum', industry:'Arts & culture', noun:'patrons', color:'#acb9ff', plan:'Patron Intelligence' },
  { id:'harbor', name:'Harbor Alliance', industry:'Membership association', noun:'members', color:'#f7c69b', plan:'Association Intelligence' }
];
const journeys = [
  { id:'retention', title:'Renewal Radar', subtitle:'Identify upcoming renewals with elevated lapse risk', metric:'renewal', icon:'shield' },
  { id:'return', title:'Second Visit', subtitle:'Engage first-time attendees with consent-based follow-ups', metric:'return', icon:'repeat' },
  { id:'growth', title:'Membership Growth', subtitle:'Identify appropriate upgrade or participation opportunities', metric:'growth', icon:'trending-up' }
];
const firstNames=['Avery','Jordan','Morgan','Reese','Riley','Taylor','Sam','Jamie','Alex','Casey','Charlie','Drew','Hayden','Quinn','Robin','Sage','Kai','Dakota','Blair','Skyler','Emery','Rowan','Parker','Finley'];
const lastNames=['Carter','Rivera','Chen','Patel','Stewart','Williams','Lopez','Kim','Shaw','Martin','Davis','Sato','Clark','Murphy','Ali','Stone','Miller','Singh','Brown','Nguyen'];
const toJson = x => JSON.stringify(x);
const fromJson = x => {try{return JSON.parse(x)}catch{return null}};
const clamp = (v,a,b) => Math.max(a,Math.min(b,v));
const round = n => Math.round(n);

/** Deterministic transparent baseline, NOT a trained model. */
export function scoreMember(member) {
  const days = Number(member.days_to_renewal);
  const visits = Number(member.visits_90d);
  const engagement = Number(member.engagement);
  const atRisk = clamp(round(27 + (days < 45 ? 21 : 0) + (visits === 0 ? 23 : visits < 3 ? 13 : -9) + (engagement < 35 ? 26 : engagement > 80 ? -20 : 0) + (member.status === 'Lapsed' ? 29 : 0)), 4, 98);
  const nextBest = !member.consent ? 'No outreach permitted' : atRisk >= 70 ? 'Human review: renewal follow-up' : visits <= 1 ? 'Offer a second experience' : engagement > 72 ? 'Consider membership upgrade' : 'Monitor engagement';
  return { risk: atRisk, priority: atRisk >= 70 ? 'High' : atRisk >= 43 ? 'Medium' : 'Low', nextBest, reason: [visits <= 1?'Low recent participation':'Recent participation',days < 45?'Renewal approaching':'Renewal not imminent',engagement < 35?'Low engagement':'Engagement observed'] };
}

async function makeDb(dbFile=databasePath) {
  await mkdir(resolve(dbFile,'..'), { recursive:true });
  const db = new DatabaseSync(dbFile);
  db.exec(`PRAGMA journal_mode=WAL; PRAGMA foreign_keys=ON;
    CREATE TABLE IF NOT EXISTS members (
      id TEXT PRIMARY KEY, tenant TEXT NOT NULL, name TEXT NOT NULL, tier TEXT NOT NULL,
      segment TEXT NOT NULL, status TEXT NOT NULL, consent INTEGER NOT NULL CHECK(consent IN (0,1)),
      visits_90d INTEGER NOT NULL, engagement INTEGER NOT NULL, days_to_renewal INTEGER NOT NULL,
      lifetime_value INTEGER NOT NULL, observed_lapse INTEGER NOT NULL,
      created_at TEXT NOT NULL
    );
    CREATE INDEX IF NOT EXISTS members_tenant ON members(tenant);
    CREATE TABLE IF NOT EXISTS proposals (
      id TEXT PRIMARY KEY, tenant TEXT NOT NULL, member_id TEXT NOT NULL, journey TEXT NOT NULL,
      action TEXT NOT NULL, reason TEXT NOT NULL, status TEXT NOT NULL,
      created_at TEXT NOT NULL, decided_at TEXT,
      FOREIGN KEY(member_id) REFERENCES members(id)
    );
    CREATE INDEX IF NOT EXISTS proposals_tenant ON proposals(tenant);
    CREATE TABLE IF NOT EXISTS audit (
      id TEXT PRIMARY KEY, tenant TEXT NOT NULL, actor TEXT NOT NULL, event TEXT NOT NULL,
      subject TEXT, details TEXT NOT NULL, created_at TEXT NOT NULL
    );
    CREATE INDEX IF NOT EXISTS audit_tenant ON audit(tenant);
  `);
  for (const t of tenants) {
    const existing = db.prepare('SELECT count(*) n FROM members WHERE tenant=?').get(t.id).n;
    if (existing) continue;
    const insert = db.prepare(`INSERT INTO members VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)`);
    for (let i=0; i<90; i++) {
      const seed = (i * 19 + t.id.length * 23) % 101;
      const visits = (i * 7 + t.id.length) % 14;
      const engagement = clamp(18 + ((i*31 + t.id.length*11) % 77),0,100);
      const days = 8 + ((i*11 + t.id.length) % 158);
      const consent = i % 9 !== 0 ? 1 : 0;
      const status = i%17===0?'Lapsed':i%11===0?'Trial':'Active';
      const m = { visits_90d:visits, engagement, days_to_renewal:days, status, consent };
      const risk=scoreMember(m).risk;
      const observed=(risk > 55 && i%5!==0) || (risk <= 55 && i%23===0) ? 1:0;
      const id=`${t.id}-${String(i+1).padStart(3,'0')}`;
      const name=`${firstNames[i%firstNames.length]} ${lastNames[(i*3+t.id.length)%lastNames.length]}`;
      insert.run(id,t.id,name, i%6===0?'Premium':i%4===0?'Plus':'Core', i%5===0?'New':i%6===0?'Advocate':'Established',status,consent,visits,engagement,days,80+seed*25,observed,new Date(Date.now()-(i*5+2)*86400000).toISOString());
    }
    db.prepare('INSERT INTO audit VALUES (?,?,?,?,?,?,?)').run(randomUUID(),t.id,'system','tenant.seeded',null,toJson({count:90,source:'fictional deterministic fixtures'}),new Date().toISOString());
  }
  return db;
}

function send(res,status,data,headers={}) {
  const body = toJson(data);
  res.writeHead(status,{'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store','X-Content-Type-Options':'nosniff',...headers}); res.end(body);
}
function err(res,status,message){send(res,status,{error:message});}
async function readBody(req) {
  let data=''; for await (const chunk of req) {data+=chunk;if(data.length>30000)throw new Error('Request too large');}
  if (!data.trim()) return {};
  let obj; try{obj=JSON.parse(data)}catch{throw new Error('Invalid JSON')}
  if(!obj||Array.isArray(obj)||typeof obj!=='object')throw new Error('Expected JSON object');
  return obj;
}
function tenantOf(url){
  const t=url.searchParams.get('tenant') || 'northstar';
  if(!tenants.find(x=>x.id===t))throw Object.assign(new Error('Unknown fictional tenant'),{status:404});
  return t;
}
function audit(db, tenant, actor, event, subject, details){db.prepare('INSERT INTO audit VALUES(?,?,?,?,?,?,?)').run(randomUUID(),tenant,actor,event,subject||null,toJson(details),new Date().toISOString());}
function rows(db,sql,...p){return db.prepare(sql).all(...p);}
function enrichMember(m){return {...m, consent:!!m.consent, score:scoreMember(m)};}
function metrics(db,tenant){
  const ms=rows(db,'SELECT * FROM members WHERE tenant=?',tenant);
  const risks=ms.filter(m=>scoreMember(m).risk>=70);
  const proposals=rows(db,'SELECT * FROM proposals WHERE tenant=?',tenant);
  return {
    members:ms.length,atRisk:risks.length,consented:ms.filter(m=>m.consent).length,
    valueAtRisk:risks.reduce((a,m)=>a+m.lifetime_value,0),
    engagement:round(ms.reduce((a,m)=>a+m.engagement,0)/ms.length),
    pending:proposals.filter(p=>p.status==='Pending').length,
    approved:proposals.filter(p=>p.status==='Approved (simulation)').length,
    weeklyActivity:[...Array(7)].map((_,i)=>({day:['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][i],value:9+((i*19+tenant.length*13)%27)}))
  };
}
function evalBaseline(db,tenant){
  const ms=rows(db,'SELECT * FROM members WHERE tenant=? ORDER BY id ASC',tenant).filter((_,i)=>i%3===0);
  let tp=0,tn=0,fp=0,fn=0;
  for(const m of ms){const pred=scoreMember(m).risk>=55; if(pred&&m.observed_lapse)tp++;else if(pred&&!m.observed_lapse)fp++;else if(!pred&&m.observed_lapse)fn++;else tn++;}
  return {label:'Deterministic rules baseline',data:'Synthetic held-out rows (index modulo 3)',size:ms.length,precision:tp+fp?round(100*tp/(tp+fp)):0,recall:tp+fn?round(100*tp/(tp+fn)):0,accuracy:round(100*(tp+tn)/ms.length),confusion:{tp,fp,fn,tn},caution:'Synthetic demonstration metric only — not evidence of commercial uplift or model quality in production.'};
}
async function engineRequest(question,summary) {
  if(!ENGINE_URL)return {provider:'local-rules',text:ruleAnswer(question,summary),disclaimer:'Deterministic demo response. No AI model was invoked.'};
  // Only aggregated synthetic data is forwarded; no real customer/person records.
  const ctl=new AbortController();const timeout=setTimeout(()=>ctl.abort(),12000);
  try {
    const payload={model:ENGINE_MODEL,messages:[{role:'system',content:'You are a private analytics assistant in a fictional demo. Answer only from supplied aggregate metrics. Never invent individual member facts, statistical significance, or causal uplift. Keep under 100 words.'},{role:'user',content:`Metrics: ${toJson(summary)}\nQuestion: ${question}`}],stream:false,max_tokens:160,temperature:0.2};
    const response=await fetch(`${ENGINE_URL}/v1/chat/completions`,{method:'POST',signal:ctl.signal,headers:{'Content-Type':'application/json',...(process.env.HANZO_ENGINE_TOKEN?{Authorization:`Bearer ${process.env.HANZO_ENGINE_TOKEN}`}:{})},body:toJson(payload)});
    if(!response.ok)throw new Error(`Engine HTTP ${response.status}`);
    const json=await response.json();const text=json.choices?.[0]?.message?.content;
    if(typeof text!=='string'||!text.trim())throw new Error('No text from Engine');
    return {provider:'hanzo-engine',model:json.model||ENGINE_MODEL,text,disclaimer:'Local inference; answer grounded on synthetic aggregate metrics.'};
  }finally{clearTimeout(timeout);}
}
function ruleAnswer(question,m){
  const q=question.toLowerCase();
  if(/risk|renew|lapse|churn/.test(q))return `${m.atRisk} of ${m.members} fictional members have elevated renewal risk. Estimated lifetime value of this cohort is ${m.valueAtRisk.toLocaleString('en-US')} demo credits. Review eligibility and consent before any outreach.`;
  if(/approval|pending|action/.test(q))return `${m.pending} actions await human review. ${m.approved} have been approved for simulation only. No external messages or changes have been sent.`;
  if(/consent|privacy/.test(q))return `${m.consented} of ${m.members} fictional members are marked eligible for outreach. Consent is enforced before creating proposals; live data is not loaded.`;
  return `This fictional tenant has ${m.members} members, ${m.atRisk} elevated-risk members, and ${m.pending} pending approvals. Choose a journey to generate a reviewable action. Model training and causal impact require further validation.`;
}
function plan(db,tenant,journeyId,limit=6){
  if(!journeys.find(j=>j.id===journeyId))throw Object.assign(new Error('Unknown journey'),{status:400});
  const ms=rows(db,'SELECT * FROM members WHERE tenant=? ORDER BY id ASC',tenant);
  const eligible=ms.filter(m=>m.consent && m.status==='Active' && (journeyId==='retention'?scoreMember(m).risk>=65:journeyId==='return'?m.visits_90d<=2:m.engagement>72 && m.tier==='Core'));
  const add=db.prepare('INSERT INTO proposals VALUES(?,?,?,?,?,?,?,?,?)');
  let created=0;
  for(const m of eligible){if(created>=limit)break;
    const existing=db.prepare('SELECT id FROM proposals WHERE tenant=? AND member_id=? AND journey=? AND status=?').get(tenant,m.id,journeyId,'Pending');
    if(existing)continue;
    const action=journeyId==='retention'?'Review renewal check-in':journeyId==='return'?'Suggest second experience':'Review appropriate upgrade';
    add.run(randomUUID(),tenant,m.id,journeyId,action,scoreMember(m).reason.join(' · '),'Pending',new Date().toISOString(),null);
    created++;
  }
  audit(db,tenant,'operator','journey.planned',journeyId,{created,eligible:eligible.length,mode:'simulation-only'});
  return {created,eligible:eligible.length,mode:'simulation-only'};
}
async function serveStatic(req,res,url){
  let name=url.pathname==='/'?'index.html':url.pathname.slice(1);
  if(name.includes('..')||name.startsWith('.'))return err(res,404,'Not found');
  const path=resolve(publicRoot,name);if(!(path===publicRoot||path.startsWith(publicRoot+'/')))return err(res,404,'Not found');
  if(!existsSync(path))return err(res,404,'Not found');
  const data=await readFile(path);
  const mime={'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.js':'text/javascript; charset=utf-8','.svg':'image/svg+xml','.png':'image/png'}[extname(path)]||'application/octet-stream';
  res.writeHead(200,{'Content-Type':mime,'X-Content-Type-Options':'nosniff','Content-Security-Policy':"default-src 'self'; img-src 'self' data:; style-src 'self'; script-src 'self'; connect-src 'self'"});res.end(data);
}
export async function createApp({dbPath=databasePath}={}) {
  const db=await makeDb(dbPath);
  const server=createServer(async(req,res)=>{
    const url=new URL(req.url,'http://127.0.0.1');
    try {
      if(url.pathname==='/healthz')return send(res,200,{status:'ok',mode:'synthetic-demo',db:'sqlite'});
      if(url.pathname==='/api/tenants'&&req.method==='GET')return send(res,200,{tenants,mode:'synthetic-demo'});
      if(url.pathname.startsWith('/api/')) {
        const tenant=tenantOf(url);
        if(url.pathname==='/api/overview'&&req.method==='GET')return send(res,200,{tenant,metrics:metrics(db,tenant),journeys});
        if(url.pathname==='/api/journeys'&&req.method==='GET')return send(res,200,{journeys});
        if(url.pathname==='/api/members'&&req.method==='GET'){
          const query=(url.searchParams.get('q')||'').slice(0,80).toLowerCase();
          const all=rows(db,'SELECT * FROM members WHERE tenant=? ORDER BY name ASC',tenant).map(enrichMember);
          return send(res,200,{members:all.filter(m=>!query||`${m.name} ${m.tier} ${m.segment}`.toLowerCase().includes(query)),total:all.length});
        }
        if(url.pathname==='/api/proposals'&&req.method==='GET')return send(res,200,{proposals:rows(db,`SELECT p.*,m.name member_name,m.consent FROM proposals p JOIN members m ON m.id=p.member_id AND m.tenant=p.tenant WHERE p.tenant=? ORDER BY p.created_at DESC`,tenant).map(p=>({...p,consent:!!p.consent}))});
        if(url.pathname==='/api/proposals/plan'&&req.method==='POST'){
          const b=await readBody(req);return send(res,201,plan(db,tenant,String(b.journey||''),clamp(Number(b.limit)||6,1,15)));
        }
        const decision=url.pathname.match(/^\/api\/proposals\/([a-f0-9-]{36})\/decision$/);
        if(decision&&req.method==='POST'){
          const b=await readBody(req);if(!['approve','reject'].includes(b.action))return err(res,400,'Expected approve or reject');
          const p=db.prepare('SELECT * FROM proposals WHERE id=? AND tenant=?').get(decision[1],tenant);if(!p)return err(res,404,'Proposal not found');
          if(p.status!=='Pending')return err(res,409,'Proposal already resolved');
          const m=db.prepare('SELECT * FROM members WHERE tenant=? AND id=?').get(tenant,p.member_id);
          if(b.action==='approve'&&!m.consent)return err(res,403,'Consent not present');
          const status=b.action==='approve'?'Approved (simulation)':'Rejected';
          db.prepare('UPDATE proposals SET status=?,decided_at=? WHERE id=? AND tenant=?').run(status,new Date().toISOString(),p.id,tenant);
          audit(db,tenant,'demo.operator',b.action==='approve'?'action.simulated':'action.rejected',p.id,{member_id:p.member_id,journey:p.journey,external_side_effects:false});
          return send(res,200,{id:p.id,status,mode:'simulation-only',external_side_effects:false});
        }
        if(url.pathname==='/api/audit'&&req.method==='GET')return send(res,200,{events:rows(db,'SELECT * FROM audit WHERE tenant=? ORDER BY created_at DESC LIMIT 70',tenant).map(e=>({...e,details:fromJson(e.details)}))});
        if(url.pathname==='/api/evaluation'&&req.method==='GET')return send(res,200,{evaluation:evalBaseline(db,tenant)});
        if(url.pathname==='/api/stack'&&req.method==='GET')return send(res,200,{mode:'synthetic reference app',components:[
          {name:'Hanzo OS deployment',status:'Target',detail:'hanzo up / manifest integration pending verification'},
          {name:'Hanzo Cloud + Framework',status:'Adapter required',detail:'Current demo uses local SQLite; production migrates to tenant-scoped authoritative records'},
          {name:'Hanzo IAM',status:'Adapter required',detail:'Demo identity only. Do not expose this server publicly'},
          {name:'Hanzo Engine',status:ENGINE_URL?'Configured':'Optional',detail:ENGINE_URL?'Configured local URL; verify readiness with AI Studio':'Set HANZO_ENGINE_URL for local OpenAI-compatible inference'},
          {name:'Hanzo MCP + Sandboxes',status:'Adapter required',detail:'No external actions; approval executes only a simulation'},
          {name:'Hanzo ML training',status:'Research / integration',detail:'Actual customer model training requires separate data, rights, evaluation and train-to-serve gates'}
        ]});
        if(url.pathname==='/api/inference'&&req.method==='POST'){
          const b=await readBody(req);if(typeof b.question!=='string'||!b.question.trim()||b.question.length>400)return err(res,400,'Question length must be 1–400 characters');
          const answer=await engineRequest(b.question,metrics(db,tenant));
          audit(db,tenant,'demo.operator','assistant.queried',null,{provider:answer.provider,question:b.question.slice(0,120),data:'aggregates-only'});
          return send(res,200,answer);
        }
        return err(res,404,'Unknown API endpoint');
      }
      if(req.method==='GET')return serveStatic(req,res,url);
      return err(res,405,'Method not allowed');
    }catch(e){const code=e.status||(/Request too large/.test(e.message)?413:400);err(res,code,e.message||'Unexpected error');}
  });
  return {server,db,close:()=>new Promise((resolve,reject)=>server.close(e=>{db.close();e?reject(e):resolve()}))};
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  const app=await createApp();
  app.server.listen(port,'127.0.0.1',()=>console.log(`FanClub AI synthetic demo: http://127.0.0.1:${port}\nNo external network binding; no production authentication.`));
}