\set ON_ERROR_STOP on
begin;
create function pg_temp.check_that(ok boolean, label text) returns void language plpgsql as $$
begin if ok is distinct from true then raise exception 'FAIL: %',label;end if; raise notice 'PASS: %',label;end $$;
create function pg_temp.expect_error(statement text, expected text,label text) returns void language plpgsql as $$
begin
 begin execute statement;exception when others then
  if sqlstate=expected then raise notice 'PASS: % (%)',label,expected;return;end if;
  raise exception 'FAIL: % expected %, received %: %',label,expected,sqlstate,sqlerrm;
 end;
 raise exception 'FAIL: % did not reject the request',label;
end $$;
insert into auth.users(id,email,raw_user_meta_data) values
 ('00000000-0000-0000-0000-000000000001','admin@test.local','{"username":"test_admin","fullName":"Администратор тестов"}'),
 ('00000000-0000-0000-0000-000000000002','manager@test.local','{"username":"test_manager","fullName":"Менеджер тестов"}'),
 ('00000000-0000-0000-0000-000000000003','client@test.local','{"username":"test_client","fullName":"Клиент тестов","role":"admin"}'),
 ('00000000-0000-0000-0000-000000000004','other@test.local','{"username":"test_other","fullName":"Другой клиент"}');
update public.profiles set role='admin' where username='test_admin';
update public.profiles set role='manager' where username='test_manager';
select pg_temp.check_that((select role='client' from public.profiles where username='test_client'),'registration ignores requested admin role');
select pg_temp.check_that(not has_function_privilege('anon','public.studio_api(text,text,jsonb,jsonb)','execute'),'anonymous RPC denied');
select pg_temp.check_that(not has_table_privilege('authenticated','public.bookings','insert'),'direct write cannot bypass validation');
select pg_temp.check_that((select bool_and(relrowsecurity) from pg_class where oid in ('public.halls'::regclass,'public.bookings'::regclass,'public.clients'::regclass,'public.photographers'::regclass,'public.equipment'::regclass,'public.subscriptions'::regclass,'public.services'::regclass,'public.payments'::regclass)),'RLS enabled on all eight entities');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
create temp table fixture(name text primary key,id bigint);
insert into fixture values ('hall',(public.studio_api('/halls','POST','{}','{"name":"Тестовый зал","code":"T01","style":"Лофт","capacity":6,"hourlyRate":2000,"description":""}')->>'id')::bigint);
insert into fixture values ('hall2',(public.studio_api('/halls','POST','{}','{"name":"Второй зал","code":"T02","style":"Светлый","capacity":8,"hourlyRate":3000,"description":""}')->>'id')::bigint);
insert into fixture values ('photo',(public.studio_api('/photographers','POST','{}',jsonb_build_object('firstName','Анна','lastName','Тестовая','specialization','Портрет','bio','','experienceYears',3,'hourlyRate',1000,'hallIds',(select jsonb_agg(id) from fixture where name in ('hall','hall2'))))->>'id')::bigint);
insert into fixture values ('service',(public.studio_api('/services','POST','{}','{"name":"Макияж тестовый","category":"Подготовка","price":500,"description":""}')->>'id')::bigint);
select public.studio_api('/subscriptions','POST','{}',jsonb_build_object('clientId',(select "clientId" from public.profiles where username='test_client'),'number','TEST-SUB','issuedAt',current_date,'expiresAt',current_date+365,'discountPercent',10));
select pg_temp.expect_error($s$select public.studio_api('/halls','POST','{}','{"name":"A","code":"BAD","style":"Лофт","capacity":0,"hourlyRate":1,"description":""}')$s$,'PT422','validation returns field error 422');
select pg_temp.expect_error($s$select public.studio_api('/services','POST','{}','{"name":"Макияж тестовый","category":"Подготовка","price":500,"description":""}')$s$,'PT409','duplicate returns conflict 409');
select pg_temp.check_that((public.studio_api('/halls','GET','{"search":"Тестовый","capacityFrom":5,"priceTo":2500,"page":1,"size":1,"sort":"name,desc"}')->>'total')::int=1,'search three filters sorting pagination on server');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
select pg_temp.expect_error($s$select public.studio_api('/admin/statistics')$s$,'PT403','manager excluded from admin section');
select pg_temp.expect_error($s$select public.studio_api('/halls','POST','{}','{}')$s$,'PT403','manager cannot modify reference catalogs');
select pg_temp.check_that(public.studio_api('/manager/workspace') ? 'bookings','manager has exclusive workspace');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000003',true);
select pg_temp.expect_error($s$select public.studio_api('/manager/workspace')$s$,'PT403','client excluded from manager workspace');
select pg_temp.expect_error($s$select public.studio_api('/users')$s$,'PT403','client excluded from users');
insert into fixture values ('booking',(public.studio_api('/bookings','POST','{}',jsonb_build_object('clientId',(select "clientId" from public.profiles where username='test_client'),'hallId',(select id from fixture where name='hall'),'email','client@test.local','date',current_date+100,'startTime','10:00','durationHours',2,'participants',2,'shootingType','Портретная','photographerIds',jsonb_build_array((select id from fixture where name='photo')),'serviceIds',jsonb_build_array((select id from fixture where name='service'))))->>'id')::bigint);
select pg_temp.check_that((public.studio_api('/bookings/'||(select id from fixture where name='booking'))->>'totalPrice')::numeric=6100,'price uses hall discount plus photographer and services');
select pg_temp.expect_error($s$select public.studio_api('/bookings','POST','{}',jsonb_build_object('clientId',(select "clientId" from public.profiles where username='test_other')))$s$,'PT403','owner spoofing rejected');
select pg_temp.expect_error($s$select public.studio_api('/bookings','POST','{}',jsonb_build_object('hallId',(select id from fixture where name='hall2'),'email','client@test.local','date',current_date+100,'startTime','11:00','durationHours',2,'participants',2,'shootingType','Портретная','photographerIds',jsonb_build_array((select id from fixture where name='photo'))))$s$,'PT409','photographer overlap across different halls rejected');
insert into fixture values ('adjacent',(public.studio_api('/bookings','POST','{}',jsonb_build_object('hallId',(select id from fixture where name='hall'),'email','client@test.local','date',current_date+100,'startTime','12:00','durationHours',1,'participants',2,'shootingType','Портретная','photographerIds',jsonb_build_array((select id from fixture where name='photo'))))->>'id')::bigint);
select pg_temp.check_that((public.studio_api('/bookings','GET')->>'total')::int=2,'adjacent half-open intervals allowed');
select pg_temp.expect_error($s$select public.studio_api('/bookings/'||(select id from fixture where name='booking')||'/extend','POST')$s$,'PT409','extension conflict rejected atomically');
select pg_temp.check_that((public.studio_api('/bookings/'||(select id from fixture where name='booking'))->>'durationHours')::int=2,'failed extension preserves original booking');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000004',true);
select pg_temp.check_that(public.studio_api('/account/bookings')='[]'::jsonb,'client sees own bookings only');
select pg_temp.expect_error($s$select public.studio_api('/bookings/'||(select id from fixture where name='booking'))$s$,'PT403','client cannot read another booking by id');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
select pg_temp.expect_error($s$select public.studio_api('/halls/'||(select id from fixture where name='hall'),'DELETE')$s$,'PT409','linked hall deletion rejected');
select pg_temp.expect_error($s$select public.studio_api('/users/'||(select id from public.profiles where username='test_admin')||'/role','PATCH','{}','{"role":"client"}')$s$,'PT409','administrator cannot demote self');
insert into fixture values ('payment',(public.studio_api('/payments','POST','{}',jsonb_build_object('bookingId',(select id from fixture where name='booking'),'amount',1000,'method','Карта','status','paid','paidAt',current_date,'note',''))->>'id')::bigint);
select pg_temp.expect_error($s$select public.studio_api('/payments','POST','{}',jsonb_build_object('bookingId',(select id from fixture where name='booking'),'amount',10000,'method','Карта','status','paid','paidAt',current_date,'note',''))$s$,'PT409','overpayment rejected');
select public.studio_api('/payments/'||(select id from fixture where name='payment'),'PUT','{}','{"amount":900}');
select public.studio_api('/payments/'||(select id from fixture where name='payment'),'DELETE');
select public.studio_api('/payments/'||(select id from fixture where name='payment')||'/restore','POST');
select public.studio_api('/payments/'||(select id from fixture where name='payment'),'DELETE','{"hard":true}');
select pg_temp.check_that(not exists(select 1 from public.payments where id=(select id from fixture where name='payment')),'payment CRUD restore hard delete');
select public.studio_api('/equipment','POST','{}',jsonb_build_object('name','Софтбокс тестовый','category','Свет','manufacturer','','hallId',(select id from fixture where name='hall'),'quantity',2,'pricePerDay',300));
select public.studio_api('/services/'||(select id from fixture where name='service'),'PUT','{}','{"price":600}');
select pg_temp.check_that((public.studio_api('/services/'||(select id from fixture where name='service'))->>'price')::int=600,'service update and read');
rollback;
\echo All database integration checks passed
