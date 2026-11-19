const $ = s => document.querySelector(s);
const state = { tenant: 'northstar', view: 'overview', tenants: [], members: [], proposals: [], audit: [], filter: 'all', search: '', chat: [] };
const html = text => String(text ?? '').replace(/[&<>"']/g, c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const num = n => Number(n || 0).toLocaleString('en-US');
const money = n => `${num(n)} cr`;
const dt = iso => iso ? new Date(iso).toLocaleString('en-US',{month:'short',day:'numeric',hour:'numeric',minute:'2-digit'}):'—';
const icons={retention:'◎',return:'↻',growth:'↗'};
const navLabels={overview:'OVERVIEW',members:'PEOPLE & RECORDS',journeys:'JOURNEYS',approvals:'APPROVALS',assistant:'AI STUDIO',evaluation:'MODEL LAB',stack:'HANZO OS STACK',audit:'AUDIT TRAIL'};
const escapeAttr = html;
let toTimer;
function toast(message){const el=$('#toast');el.textContent=message;el.classList.add('show');clearTimeout(toTimer);toTimer=setTimeout(()=>el.classList.remove('show'),2800)}
async function api(path,{method='GET',body}={}){
  const u=new URL(path,location.origin);if(u.pathname.startsWith('/api/')&&!u.searchParams.has('tenant'))u.searchParams.set('tenant',state.tenant);
  const r=await fetch(u.toString(),{method,headers:body?{'Content-Type':'application/json'}:{},body:body?JSON.stringify(body):undefined});
  const x=await r.json();if(!r.ok)throw new Error(x.error||`HTTP ${r.status}`);return x;
}
function section(title,description='',actions=''){
  return `<div class="section-header"><div><div class="eyebrow">${html(state.tenants.find(x=>x.id===state.tenant)?.name||'Reference workspace')}</div><h1 class="section-title">${html(title)}</h1><p class="section-description">${html(description)}</p></div>${actions?`<div class="section-cta">${actions}</div>`:''}</div>`;
}
function badge(text){return `<span class="pill ${text==='High'?'pill-high':text==='Medium'?'pill-medium':text==='Low'?'pill-low':text?.startsWith('Approved')?'pill-approved':text==='Pending'?'pill-pending':'pill-rejected'}">${html(text)}</span>`}
function metric(title,value,footer,icon='◈',warning=false){return `<div class="metric-card"><div class="metric-caption">${html(title)}<span class="metric-ikon">${icon}</span></div><div class="metric-value">${html(value)}</div><div class="metric-foot ${warning?'warning':''}">${footer}</div></div>`}
function topMembers(ms,limit=5){
  return `<div class="table-scroller"><table class="data-table"><thead><tr><th>Person</th><th>Tier</th><th>Risk</th><th>Next step</th></tr></thead><tbody>${ms.slice(0,limit).map(m=>`<tr><td><div class="member-name">${html(m.name)}</div><div class="member-id">${html(m.id)}</div></td><td><span class="tag">${html(m.tier)}</span></td><td>${badge(m.score.priority)}</td><td class="muted">${html(m.score.nextBest)}</td></tr>`).join('')}</tbody></table></div>`;
}
async function renderOverview(){
  const [{metrics:m,journeys},people]=await Promise.all([api('/api/overview'),api('/api/members')]);
  state.members=people.members;
  const high=[...people.members].sort((a,b)=>b.score.risk-a.score.risk);
  const chartMax=Math.max(...m.weeklyActivity.map(x=>x.value));
  $('#content').innerHTML=`${section('Intelligence overview','Your fictional organization, one private command center.',`<button class="btn btn-primary" data-go="journeys">Explore journeys &nbsp; ↗</button>`)}
    <div class="hero"><div class="hero-copy"><div class="eyebrow">A PRIVATE AI OPERATING SYSTEM</div><h1>Own your audience.<br><em>Activate your intelligence.</em></h1><p>Understand who matters, make measured decisions, act with human approval and retain control of your data—all in your own environment.</p></div><div class="hero-visual"><div class="hero-step"><b>◫</b>Understand</div><span class="hero-connector"></span><div class="hero-step"><b>◈</b>Decide</div><span class="hero-connector"></span><div class="hero-step"><b>✓</b>Approve</div><span class="hero-connector"></span><div class="hero-step"><b>↗</b>Measure</div></div></div>
    <div class="grid-four">
    ${metric('People in this organization',num(m.members),'<b>Synthetic</b> records in an isolated tenant','♙')}
    ${metric('Renewal attention',num(m.atRisk),'<b>Rules baseline</b> · elevated risk','↗',true)}
    ${metric('Value in risk cohort',money(m.valueAtRisk),'<b>Demo credits</b>, not booked revenue','◈')}
    ${metric('Pending approvals',num(m.pending),'<b>Human control</b> over all actions','✓')}</div>
    <div class="two-column"><section class="panel"><div class="panel-head"><div><h2>Participation activity</h2><p class="panel-sub">Illustrative weekly event counts · deterministic fixtures</p></div><span class="tag">SYNTHETIC</span></div><div class="chart">${m.weeklyActivity.map(x=>`<div class="chartbar"><i style="height:${Math.round(x.value/chartMax*100)}%"></i><span>${x.day}</span></div>`).join('')}</div><div class="chart-caption">Charts are fictional and do not represent live analytics or measured commercial uplift.</div></section>
      <section class="panel"><div class="panel-head"><div><h2>Next best decisions</h2><p class="panel-sub">Risk-prioritized, never auto-sent</p></div><button class="link" data-go="approvals">Review actions ↗</button></div>${topMembers(high,4)}<div style="margin-top:14px"><button class="btn btn-sm btn-ghost" data-go="members">Explore people →</button></div></section></div>
    <div class="note" style="margin-top:18px"><strong>Product principle:</strong> This is a fictional, multi-industry reference application. The baseline decisions run locally. Live integrations, customer data, training and production deployment require separate verification and security gates.</div>`;
  $('#approval-count').textContent=String(m.pending);
}
async function renderMembers(){
  const {members}=await api('/api/members');state.members=members;
  $('#content').innerHTML=`${section('People & records','One authoritative view of your organization. All records are deterministic synthetic examples.',`<button class="btn btn-ghost" data-go="audit">View data audit →</button>`)}
  <div class="note"><strong>Reusable across industries:</strong> This same person, account, consent and engagement contract can represent supporters, patrons, alumni, residents or association members. Production storage migrates to Hanzo Cloud + Framework/Base.</div>
  <div class="panel"><div class="filter-row"><input id="member-search" class="search-field" type="search" value="${escapeAttr(state.search)}" placeholder="Search name, tier or segment" aria-label="Search members"><div class="toggle-group"><button data-filter="all" class="${state.filter==='all'?'on':''}">All</button><button data-filter="high" class="${state.filter==='high'?'on':''}">At risk</button><button data-filter="consented" class="${state.filter==='consented'?'on':''}">Consented</button></div><span class="counts" id="member-count">${members.length} records</span></div><div class="table-scroller"><table class="data-table"><thead><tr><th>Person</th><th>Membership</th><th>Engagement</th><th>Renewal</th><th>Risk</th><th>Outreach</th></tr></thead><tbody id="member-body"></tbody></table></div></div>`;
  updateMemberRows();
}
function updateMemberRows(){
  const filtered=state.members.filter(m=>`${m.name} ${m.tier} ${m.segment}`.toLowerCase().includes(state.search.toLowerCase())&&(state.filter==='all'||state.filter==='high'&&m.score.priority==='High'||state.filter==='consented'&&m.consent));
  $('#member-count').textContent=`${filtered.length} / ${state.members.length} records`;
  $('#member-body').innerHTML=filtered.map(m=>`<tr><td><div class="member-name">${html(m.name)}</div><div class="member-id">${html(m.id)} · ${html(m.segment)}</div></td><td>${html(m.tier)}</td><td><span>${html(m.engagement)} / 100</span><div class="statbar"><span style="width:${m.engagement}%"></span></div></td><td>${m.days_to_renewal} days</td><td>${badge(m.score.priority)} <span class="small">${m.score.risk}</span></td><td><span class="tag">${m.consent?'✓ Allowed':'× Not allowed'}</span></td></tr>`).join('')||`<tr><td colspan="6" class="muted" style="padding:30px;text-align:center">No matching records</td></tr>`;
}
async function renderJourneys(){
  const {journeys}=await api('/api/journeys');
  $('#content').innerHTML=`${section('Decision journeys','Reusable business processes that convert evidence into safe, reviewable actions.',`<button class="btn btn-ghost" data-go="approvals">Approval queue →</button>`)}
  <div class="note"><strong>Simulation only.</strong> Generating a journey creates proposed actions. Every action needs human approval, and approving it records a simulated outcome—no messages, payments or price changes are sent.</div>
  <div class="journey-grid">${journeys.map((j,i)=>`<div class="journey-card"><div class="journey-symbol">${icons[j.id]}</div><div class="eyebrow">JOURNEY 0${i+1}</div><h3>${html(j.title)}</h3><p>${html(j.subtitle)}</p><div class="journey-steps"><span>DATA</span><span class="step-arrow">→</span><span>DECISION</span><span class="step-arrow">→</span><span>HUMAN APPROVAL</span></div><button class="btn btn-primary" data-plan="${j.id}">Generate review actions ↗</button></div>`).join('')}</div>
  <section class="panel" style="margin-top:18px"><div class="panel-head"><h2>What makes a journey production-ready?</h2></div><div class="tech-map"><div><b>Inputs & rights</b><p class="explain">Verified records, identity resolution, lawful purpose, consent and compatible system connectors.</p></div><div><b>Decision evaluation</b><p class="explain">Time-split testing, baseline comparison, calibration, false positives and human override.</p></div><div><b>Measured outcomes</b><p class="explain">Holdout groups, cost accounting, incremental contribution and documented uncertainty.</p></div></div></section>`;
}
async function renderApprovals(){
  const {proposals}=await api('/api/proposals');state.proposals=proposals;
  $('#content').innerHTML=`${section('Human approvals','Proposals are evidence-based recommendations, not autonomous customer outreach.',`<button class="btn btn-primary" data-go="journeys">Generate proposals +</button>`)}
  <div class="note"><strong>Hard safety boundary:</strong> Even after approval, this prototype performs only a simulated action and writes an audit entry. A live connector would require authenticated IAM identity, consent, action-scoped MCP permission and a separate rollout gate.</div>
  <div class="panel">${!proposals.length?`<div class="empty-state"><div class="empty-icon">✓</div><h3>No decisions waiting</h3><p>Generate a journey to create human-review tasks from fictional records.</p><button class="btn btn-primary" data-go="journeys">Explore journeys</button></div>`:
  `<div class="table-scroller"><table class="data-table"><thead><tr><th>Person & action</th><th>Why</th><th>Journey</th><th>Status</th><th>Review</th></tr></thead><tbody>${proposals.map(p=>`<tr><td><div class="member-name">${html(p.member_name)}</div><div class="member-id">${html(p.action)}</div></td><td class="muted">${html(p.reason)}</td><td>${html(p.journey)}</td><td>${badge(p.status)}</td><td>${p.status==='Pending'?`<div style="display:flex;gap:7px"><button class="btn btn-sm btn-primary" data-decision="${p.id}" data-action="approve">Approve</button><button class="btn btn-sm btn-danger" data-decision="${p.id}" data-action="reject">Reject</button></div>`:'<span class="small">Reviewed</span>'}</td></tr>`).join('')}</tbody></table></div>`}</div>`;
  $('#approval-count').textContent=String(proposals.filter(x=>x.status==='Pending').length);
}
async function renderAssistant(){
  const {metrics:m}=await api('/api/overview');
  if(!state.chat.length)state.chat=[{role:'assistant',text:`Welcome to your private intelligence workspace. I can summarize synthetic aggregate metrics, explain the decision baseline and help you find the right workflow. This prototype does not access real club or customer data.`,provider:'reference'}];
  $('#content').innerHTML=`${section('AI Studio','A lightweight natural-language interface on top of private, structured intelligence.',`<button class="btn btn-ghost" data-go="stack">Inspect local stack ↗</button>`)}
  <div class="chat-shell"><section class="panel conversation"><div class="panel-head"><div><h2>Ask your organization</h2><p class="panel-sub">Aggregate data only · local baseline or configured private Hanzo Engine</p></div><span class="tag">PRIVATE DEMO</span></div><div class="message-stream" id="chat-messages"></div><form class="chat-input" id="chat-form"><label for="chat-question" class="sr-only">Your question</label><input id="chat-question" autocomplete="off" maxlength="400" placeholder="Ask about retention, approvals or engagement…" required><button class="btn btn-primary" type="submit">Ask ↗</button></form></section>
  <aside class="panel"><div class="panel-head"><h2>Try a question</h2></div><button class="suggestion" data-question="How many members are at risk of not renewing?">How many members are at risk of not renewing?</button><button class="suggestion" data-question="What needs human approval?">What needs human approval?</button><button class="suggestion" data-question="How do we respect marketing consent?">How do we respect marketing consent?</button><div class="note" style="margin-top:22px"><strong>${m.members} fictional records.</strong> This interface never sends real personal data to the inference adapter. Without a configured Engine URL, responses are transparently rules-based.</div><p class="explain">For production, tools, datasets and outbound actions must be authorized by IAM and routed through approved MCP capabilities.</p></aside></div>`;
  const list=$('#chat-messages');list.innerHTML=state.chat.map(m=>`<div class="message ${m.role}">${html(m.text)}${m.provider&&m.role==='assistant'?`<div class="small" style="margin-top:8px;color:#9fbc9a">${html(m.provider)}</div>`:''}</div>`).join('');list.scrollTop=list.scrollHeight;
}
async function renderEvaluation(){
  const {evaluation:e}=await api('/api/evaluation');
  $('#content').innerHTML=`${section('Model evaluation','Choose a decision method through evidence, not vendor branding.',`<button class="btn btn-ghost" data-go="stack">See integration gates →</button>`)}
  <div class="note warning"><strong>Evidence disclosure:</strong> These results are computed on deterministic fictional rows. They are not trained-model benchmarks, commercial-uplift results or proof of generalization to real organizations.</div>
  <section class="panel"><div class="panel-head"><div><h2>${html(e.label)}</h2><p class="panel-sub">${html(e.data)} · n = ${e.size}</p></div><span class="tag">ACTUALLY COMPUTED</span></div>
  <div class="model-stats"><div class="model-stat"><span>Classification accuracy</span><b>${e.accuracy}%</b><span>Held-out synthetic fixture rows</span></div><div class="model-stat"><span>Positive precision</span><b>${e.precision}%</b><span>Correct elevated-risk flags</span></div><div class="model-stat"><span>Positive recall</span><b>${e.recall}%</b><span>Known simulated lapses found</span></div></div><p class="explain" style="margin-top:18px">Confusion matrix: ${e.confusion.tp} TP · ${e.confusion.fp} FP · ${e.confusion.fn} FN · ${e.confusion.tn} TN. ${html(e.caution)}</p></section>
  <div class="evaluation-box"><section class="panel"><div class="panel-head"><h2>Model selection ladder</h2></div><div class="explain" style="font-size:12px;line-height:2.15"><b style="color:#d9f4d2">01 &nbsp; Policy rules</b> — explicit, cheap and auditable<br><b style="color:#d9f4d2">02 &nbsp; Statistical baseline</b> — regression or gradient boosting<br><b style="color:#d9f4d2">03 &nbsp; Specialized private model</b> — only after benchmark and data rights<br><b style="color:#d9f4d2">04 &nbsp; Language model</b> — optional drafting and Q&A</div></section><section class="panel"><div class="panel-head"><h2>Custom AI lifecycle</h2></div><div class="explain" style="font-size:12px;line-height:2.15">Dataset approval → training job → checkpoint<br>Offline holdout evaluation → signed registry<br>Authorized promotion → private Engine serving<br>Drift monitoring → rollback / retraining</div><div class="note" style="margin-top:16px"><strong>Not wired in this prototype.</strong> These are G1 integration/qualification gates; no custom weights have been trained or delivered.</div></section></div>`;
}
async function renderStack(){
  const {components}=await api('/api/stack');
  $('#content').innerHTML=`${section('Hanzo OS architecture','Open-source framework components assembled into a customer-owned private AI solution.',`<a class="btn btn-ghost" href="https://github.com/hanzoai/stack" target="_blank" rel="noopener noreferrer">Hanzo Stack repository ↗</a>`)}
  <div class="note"><strong>Hanzo AI</strong> is the technology and engineering partner. <strong>Hanzo OS</strong> is the framework and standards. The blocks below distinguish working demo adapters from integrations that still need qualification.</div>
  <div class="tech-map">${components.map(x=>`<div class="tech-card"><h3>${html(x.name)}</h3><span class="tech-state ${x.status==='Adapter required'||x.status==='Research / integration'?'dim':''}">${html(x.status)}</span><p>${html(x.detail)}</p></div>`).join('')}</div>
  <div class="two-column"><section class="panel"><div class="panel-head"><h2>Target private runtime</h2></div><div class="explain" style="line-height:2.3">Application manifest → <b>hanzo up</b><br>Hanzo Cloud / Framework / Base / IAM<br>Hanzo Engine — private inference<br>Hanzo MCP — authorized, typed tools<br>Sandbox — event-driven invocation<br>Insights / observability — evidence and audit</div></section><section class="panel"><div class="panel-head"><h2>Portability contract</h2></div><div class="explain" style="line-height:2.3">Export: member and activity records<br>Artifacts: pinned models + applicable licences<br>Interfaces: typed schemas and API versions<br>Deployment: private EU / on-prem / clusters<br>Ownership: commissioned IP vs background IP<br>Controls: privacy, audit, backups and recovery</div></section></div>
  <div class="note warning" style="margin-top:17px"><strong>Security qualification:</strong> The localhost reference server has no production authentication. Do not expose it to the internet or load personal data. Native IAM/Cloud/Framework integration and an offline end-to-end acceptance test are required before production use.</div>`;
}
async function renderAudit(){
  const {events}=await api('/api/audit');state.audit=events;
  $('#content').innerHTML=`${section('Audit & provenance','Every simulated decision is attributable to a tenant, actor, event and timestamp.',`<button class="btn btn-ghost" data-go="approvals">Approval queue →</button>`)}
  <div class="note"><strong>Local ledger:</strong> Events persist in SQLite for prototype inspection. This is <em>not</em> an append-only tamper-evident production audit service or a verified privacy compliance control.</div>
  <section class="panel"><div class="table-scroller"><table class="data-table"><thead><tr><th>Recorded</th><th>Event</th><th>Actor</th><th>Subject</th><th>Details</th></tr></thead><tbody>${events.map(e=>`<tr><td>${dt(e.created_at)}</td><td><b>${html(e.event)}</b></td><td>${html(e.actor)}</td><td class="muted">${html(e.subject||'—')}</td><td class="muted">${html(JSON.stringify(e.details))}</td></tr>`).join('')}</tbody></table></div></section>`;
}
const views={overview:renderOverview,members:renderMembers,journeys:renderJourneys,approvals:renderApprovals,assistant:renderAssistant,evaluation:renderEvaluation,stack:renderStack,audit:renderAudit};
async function navigate(view){
  if(!views[view])return;
  state.view=view;state.search='';state.filter='all';
  for(const b of document.querySelectorAll('[data-view]'))b.classList.toggle('selected',b.dataset.view===view);
  $('#top-current').textContent=navLabels[view];
  $('#content').innerHTML='<div class="loading-state">Loading private workspace…</div>';
  try{await views[view]()}catch(e){$('#content').innerHTML=`<div class="note warning"><strong>Unable to load workspace.</strong> ${html(e.message)}</div>`}
  window.scrollTo?.(0,0);
}
async function ask(question){if(!question?.trim())return;state.chat.push({role:'user',text:question});await renderAssistant();try{const answer=await api('/api/inference',{method:'POST',body:{question}});state.chat.push({role:'assistant',text:answer.text,provider:answer.provider==='hanzo-engine'?`Hanzo Engine · ${answer.model}`:'Deterministic demo baseline'});}catch(e){state.chat.push({role:'assistant',text:`Inference unavailable: ${e.message}`,provider:'error'});}await renderAssistant()}
document.addEventListener('click',async e=>{
  const nav=e.target.closest('[data-view],[data-go]');if(nav){await navigate(nav.dataset.view||nav.dataset.go);return;}
  const filter=e.target.closest('[data-filter]');if(filter){state.filter=filter.dataset.filter;document.querySelectorAll('[data-filter]').forEach(x=>x.classList.toggle('on',x===filter));updateMemberRows();return;}
  const plan=e.target.closest('[data-plan]');if(plan){plan.disabled=true;try{const out=await api('/api/proposals/plan',{method:'POST',body:{journey:plan.dataset.plan,limit:6}});toast(`${out.created} proposals created for human review`);await navigate('approvals')}catch(er){toast(er.message)}finally{plan.disabled=false}return;}
  const decision=e.target.closest('[data-decision]');if(decision){decision.disabled=true;try{const out=await api(`/api/proposals/${decision.dataset.decision}/decision`,{method:'POST',body:{action:decision.dataset.action}});toast(`Decision recorded: ${out.status}`);await navigate('approvals')}catch(er){toast(er.message);decision.disabled=false}return;}
  const question=e.target.closest('[data-question]');if(question)await ask(question.dataset.question);
});
document.addEventListener('input',e=>{if(e.target.id==='member-search'){state.search=e.target.value;updateMemberRows();}});
document.addEventListener('submit',async e=>{if(e.target.id==='chat-form'){e.preventDefault();const input=$('#chat-question');const q=input.value;input.value='';await ask(q)}});
$('#tenant-select').addEventListener('change',async e=>{state.tenant=e.target.value;state.chat=[];const org=state.tenants.find(x=>x.id===state.tenant);$('#tenant-name').textContent=org.name;$('#tenant-sector').textContent=org.industry;$('#tenant-dot').style.background=org.color;await navigate(state.view)});
async function init(){try{const {tenants}=await api('/api/tenants');state.tenants=tenants;await navigate('overview');}catch(e){$('#content').innerHTML=`<div class="note warning"><strong>Backend unavailable.</strong> ${html(e.message)}. Run <code>npm start</code> from the reference-app directory.</div>`}}
init();