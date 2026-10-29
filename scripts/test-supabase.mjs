import fs from 'node:fs';
import assert from 'node:assert/strict';
const cfg=JSON.parse(fs.readFileSync('config/supabase.public.json','utf8'));
const base=cfg.SUPABASE_URL, key=cfg.SUPABASE_PUBLISHABLE_KEY;
const sessions={};
for(const role of ['ADMIN','MANAGER','CLIENT']) if(!process.env['DEMO_'+role]) throw new Error('Set DEMO_'+role+' before running cloud tests');
async function request(path,body,token){const r=await fetch(base+path,{method:'POST',headers:{apikey:key,'Content-Type':'application/json',...(token?{Authorization:'Bearer '+token}:{})},body:JSON.stringify(body)});const text=await r.text();return {status:r.status,data:text?JSON.parse(text):{}};}
async function rpc(role,endpoint,method='GET',payload={},query={},expected=200){const r=await request('/rest/v1/rpc/studio_api',{endpoint,method,payload,query},sessions[role].access_token);assert.equal(r.status,expected,endpoint+' '+JSON.stringify(r.data));return r.data;}
for(const role of ['admin','manager','client']){
 const r=await request('/auth/v1/token?grant_type=password',{email:role+'@focusframe.local',password:process.env['DEMO_'+role.toUpperCase()]});
 assert.equal(r.status,200,'Login '+role+': '+JSON.stringify(r.data));sessions[role]=r.data;
 const me=await rpc(role,'/auth/me'); assert.equal(me.role,role);sessions[role].profile=me;console.log('PASS login/profile',role);
}
await rpc('client','/admin/statistics','GET',{}, {},403);
await rpc('manager','/admin/statistics','GET',{}, {},403);
await rpc('admin','/manager/workspace','GET',{}, {},403);
await rpc('admin','/account/bookings','GET',{}, {},403);
await rpc('client','/halls','POST',{}, {},403);
await rpc('manager','/services','POST',{}, {},403);
console.log('PASS exclusive role sections and write permissions');
const stamp=Date.now(); const created=[];
async function create(entity,data,role='admin'){const r=await rpc(role,'/'+entity,'POST',data);created.push([entity,r.id]);return r;}
try{
 const hall=await create('halls',{name:'Тестовая студия '+stamp,code:'T-'+stamp,style:'Лофт',capacity:6,hourlyRate:2000,description:''});
 const photo=await create('photographers',{firstName:'Тестовый',lastName:'Фотограф',specialization:'Портрет',bio:'',experienceYears:3,hourlyRate:1000,hallIds:[hall.id]});
 const equipment=await create('equipment',{name:'Тестовый свет',category:'Свет',manufacturer:'',hallId:hall.id,quantity:2,pricePerDay:300});
 const service=await create('services',{name:'Тестовая услуга '+stamp,category:'Подготовка',price:500,description:''});
 const extraClient=await create('clients',{fullName:'Тестовый клиент',email:'test-'+stamp+'@example.com',phone:'',clientType:'Частный',company:'',notes:''});
 const date=new Date(Date.now()+86400000*100).toISOString().slice(0,10);
 const subscription=await create('subscriptions',{clientId:sessions.client.profile.clientId,number:'TEST-'+stamp,issuedAt:new Date().toISOString().slice(0,10),expiresAt:date,discountPercent:10},'manager');
 const b={hallId:hall.id,email:'client@focusframe.local',date,startTime:'10:00',durationHours:2,participants:2,shootingType:'Портретная',comment:'',photographerIds:[photo.id],serviceIds:[service.id]};
 const booking=await create('bookings',b,'client');assert.equal(Number(booking.totalPrice),6100);
 await rpc('client','/bookings','POST',b,{},409);
 await rpc('admin','/halls/'+hall.id,'DELETE',{}, {},409);
 await rpc('admin','/services','POST',{name:'A',category:'X',price:-1,description:''},{},422);
 console.log('PASS cloud 422, 409, overlap, discount total 6100');
 const payment=await create('payments',{bookingId:booking.id,amount:1000,method:'Карта',status:'paid',paidAt:new Date().toISOString().slice(0,10),note:''},'manager');
 await rpc('manager','/payments/'+payment.id,'PUT',{amount:900});
 assert.equal(Number((await rpc('manager','/payments/'+payment.id)).amount),900);
 for(const [entity,id] of created){
  await rpc('admin','/'+entity+'/'+id,'PUT',{});
  assert.equal((await rpc('admin','/'+entity+'/'+id)).id,id);
 }
 const q=await rpc('admin','/halls','GET',{}, {search:'Тестовая студия '+stamp,capacityFrom:5,capacityTo:7,priceTo:2500,size:1,page:1,sort:'name,desc'});assert.equal(q.total,1);assert.equal(q.items.length,1);
 const pq=await rpc('manager','/payments','GET',{}, {amountFrom:901});assert(!pq.items.some(x=>x.id===payment.id));
 console.log('PASS CRUD read/update all 8 entities and server filters');
}finally{
 // Remove only records created by this test, in foreign-key dependency order.
 const priority=['payments','bookings','subscriptions','equipment','photographers','services','clients','halls'];
 created.sort((a,b)=>priority.indexOf(a[0])-priority.indexOf(b[0]));
 for(const [entity,id] of created){
  await rpc('admin','/'+entity+'/'+id,'DELETE');
  await rpc('admin','/'+entity+'/'+id+'/restore','POST');
  await rpc('admin','/'+entity+'/'+id,'DELETE',{}, {hard:true});
 }
 console.log('PASS soft delete, restore, physical delete all test records');
}
const refreshed=await request('/auth/v1/token?grant_type=refresh_token',{refresh_token:sessions.client.refresh_token});assert.equal(refreshed.status,200);console.log('PASS real Supabase token refresh');
for(const role of ['admin','manager']){await request('/auth/v1/logout?scope=local',{},sessions[role].access_token);}
await request('/auth/v1/logout?scope=local',{},refreshed.data.access_token);
console.log('ALL CLOUD CHECKS PASSED');
