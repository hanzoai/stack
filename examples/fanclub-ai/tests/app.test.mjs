import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {createApp,scoreMember} from '../server.mjs';
const base = async () => {const dir=await mkdtemp(join(tmpdir(),'fanclub-test-'));const app=await createApp({dbPath:join(dir,'test.sqlite')});await new Promise(resolve=>app.server.listen(0,'127.0.0.1',resolve));return {app,dir,url:`http://127.0.0.1:${app.server.address().port}`}};
const call=async(url,path,{method='GET',body}={})=>{const r=await fetch(url+path,{method,headers:body?{'Content-Type':'application/json'}:{},body:body?JSON.stringify(body):undefined});return {status:r.status,data:await r.json()}};
const cleanup=async({app,dir})=>{await app.close();await rm(dir,{recursive:true,force:true})};

test('baseline remains deterministic and bounds risk',()=>{
  const m={days_to_renewal:11,visits_90d:0,engagement:13,status:'Active',consent:0};
  assert.deepEqual(scoreMember(m),scoreMember(m));
  assert.ok(scoreMember(m).risk<=98);
  assert.equal(scoreMember(m).nextBest,'No outreach permitted');
});

test('three fictional tenants have isolated records and aggregate metrics',async()=>{
  const ctx=await base();try {
    const a=await call(ctx.url,'/api/members?tenant=northstar');
    const b=await call(ctx.url,'/api/members?tenant=solstice');
    assert.equal(a.status,200);assert.equal(a.data.members.length,90);assert.equal(b.data.members.length,90);
    assert.ok(a.data.members.every(x=>x.id.startsWith('northstar-')));
    assert.ok(b.data.members.every(x=>x.id.startsWith('solstice-')));
    const x=await call(ctx.url,'/api/overview?tenant=harbor');assert.equal(x.data.metrics.members,90);
  }finally{await cleanup(ctx)}
});

test('proposals are human-approved simulations; no external actions',async()=>{
  const ctx=await base();try {
    const made=await call(ctx.url,'/api/proposals/plan?tenant=northstar',{method:'POST',body:{journey:'retention',limit:7}});
    assert.equal(made.status,201);assert.ok(made.data.created>0);
    const a=await call(ctx.url,'/api/proposals?tenant=northstar');assert.ok(a.data.proposals.length>0);
    assert.ok(a.data.proposals.every(p=>p.consent));
    const id=a.data.proposals[0].id;
    const cross=await call(ctx.url,`/api/proposals/${id}/decision?tenant=solstice`,{method:'POST',body:{action:'approve'}});assert.equal(cross.status,404);
    const approved=await call(ctx.url,`/api/proposals/${id}/decision?tenant=northstar`,{method:'POST',body:{action:'approve'}});
    assert.equal(approved.status,200);assert.equal(approved.data.external_side_effects,false);
    const again=await call(ctx.url,`/api/proposals/${id}/decision?tenant=northstar`,{method:'POST',body:{action:'approve'}});assert.equal(again.status,409);
    const audit=await call(ctx.url,'/api/audit?tenant=northstar');assert.ok(audit.data.events.some(x=>x.event==='action.simulated'));
  }finally{await cleanup(ctx)}
});

test('baseline evaluation is computed; assistant discloses local rules',async()=>{
  const ctx=await base();try{
    const e=await call(ctx.url,'/api/evaluation?tenant=harbor');assert.equal(e.status,200);assert.ok(e.data.evaluation.size>0);assert.equal(e.data.evaluation.label,'Deterministic rules baseline');
    const q=await call(ctx.url,'/api/inference?tenant=harbor',{method:'POST',body:{question:'What needs approval?'}});
    assert.equal(q.status,200);assert.equal(q.data.provider,'local-rules');assert.match(q.data.disclaimer,/no ai model/i);
  }finally{await cleanup(ctx)}
});

test('unknown tenant and missing content fail closed',async()=>{
  const ctx=await base();try{
    assert.equal((await call(ctx.url,'/api/overview?tenant=nope')).status,404);
    assert.equal((await call(ctx.url,'/api/nonexistent?tenant=northstar')).status,404);
  }finally{await cleanup(ctx)}
});