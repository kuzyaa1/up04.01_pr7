-- Studio times are Moscow local time. Sort booking clients by their displayed name.
begin;
create or replace function studio_private.save_record(entity text, record_id bigint, payload jsonb) returns jsonb
language plpgsql security definer set search_path=pg_catalog,public,studio_private as $$
declare data jsonb; old_data jsonb; key text; columns_sql text; values_sql text; result_id bigint; related bigint; profile public.profiles;
begin
 profile:=studio_private.current_profile();
 perform pg_advisory_xact_lock(7940401);
 if record_id is not null then
  old_data:=studio_private.row_json(entity,record_id);
  if old_data is null then raise sqlstate 'PT404' using message='Запись не найдена'; end if;
 end if;
 data:=coalesce(old_data,'{}')||payload;
 if entity='bookings' then
  data:=jsonb_build_object('status','active','startTime','10:00','comment','')||data;
  if record_id is null then
   if coalesce(data->>'accessCode','')='' then data:=data||jsonb_build_object('accessCode','FF-'||upper(substr(md5(random()::text),1,12))); end if;
   if profile.role='client' then
    if coalesce((data->>'clientId')::bigint,profile."clientId")<>profile."clientId" then raise sqlstate 'PT403' using message='Можно бронировать только для себя'; end if;
    data:=data||jsonb_build_object('clientId',profile."clientId",'status','active','accessCode','FF-'||upper(substr(md5(random()::text),1,12)));
   end if;
  end if;
  if record_id is null or data->>'date'<>old_data->>'date' or data->>'startTime'<>old_data->>'startTime' then
   if (data->>'date')::date+(data->>'startTime')::time<(now() at time zone 'Europe/Moscow') then perform studio_private.fail('date','Выберите будущее время съёмки'); end if;
  end if;
 end if;
 perform studio_private.validate(entity,data);
 -- Only real editable table columns are accepted. Derived fields and identities
 -- are never copied from the client.
 select string_agg(format('%I',a.attname),',' order by a.attnum),
        string_agg(format('(jsonb_populate_record(null::public.%I,$1)).%I',entity,a.attname),',' order by a.attnum)
 into columns_sql,values_sql
 from pg_attribute a where a.attrelid=format('public.%I',entity)::regclass and a.attnum>0 and not a.attisdropped
  and a.attname not in ('id','deletedAt','totalPrice','costBreakdown') and data ? a.attname;
 if record_id is null then
  execute format('insert into public.%I(%s) select %s returning id',entity,columns_sql,values_sql) into result_id using data;
 else
  execute format('update public.%I set (%s)=(select %s) where id=$2 returning id',entity,columns_sql,values_sql) into result_id using data,record_id;
 end if;
 if entity='photographers' then
  delete from public.photographer_halls where "photographerId"=result_id;
  for related in select distinct value::bigint from jsonb_array_elements_text(coalesce(data->'hallIds','[]')) loop
   if not exists(select 1 from public.halls where id=related and "deletedAt" is null) then perform studio_private.fail('hallIds','Выберите активные залы'); end if;
   insert into public.photographer_halls values(result_id,related);
  end loop;
  if not exists(select 1 from public.photographer_halls where "photographerId"=result_id) then perform studio_private.fail('hallIds','Выберите хотя бы один зал'); end if;
  if exists(select 1 from public.booking_photographers bp join public.bookings b on b.id=bp."bookingId" where bp."photographerId"=result_id and b.status='active' and b."deletedAt" is null and not exists(select 1 from public.photographer_halls ph where ph."photographerId"=result_id and ph."hallId"=b."hallId")) then raise sqlstate 'PT409' using message='В этом зале есть действующие съёмки фотографа'; end if;
 elsif entity='bookings' then
  delete from public.booking_photographers where "bookingId"=result_id;
  for related in select distinct value::bigint from jsonb_array_elements_text(coalesce(data->'photographerIds','[]')) loop insert into public.booking_photographers values(result_id,related); end loop;
  delete from public.booking_services where "bookingId"=result_id;
  for related in select distinct value::bigint from jsonb_array_elements_text(coalesce(data->'serviceIds','[]')) loop insert into public.booking_services values(result_id,related); end loop;
  perform studio_private.check_booking(result_id);
 elsif entity='equipment' then
  if not exists(select 1 from public.halls where id=(data->>'hallId')::bigint and "deletedAt" is null) then perform studio_private.fail('hallId','Выберите активный зал'); end if;
 elsif entity='subscriptions' then
  if not exists(select 1 from public.clients where id=(data->>'clientId')::bigint and "deletedAt" is null) then perform studio_private.fail('clientId','Выберите активного клиента'); end if;
 elsif entity='payments' then
  if not exists(select 1 from public.bookings where id=(data->>'bookingId')::bigint and "deletedAt" is null and status<>'cancelled') then perform studio_private.fail('bookingId','Выберите действующее бронирование'); end if;
  if (select coalesce(sum(amount),0) from public.payments where "bookingId"=(data->>'bookingId')::bigint and status='paid' and "deletedAt" is null)>(select "totalPrice" from public.bookings where id=(data->>'bookingId')::bigint) then raise sqlstate 'PT409' using message='Оплата превышает стоимость бронирования'; end if;
 end if;
 -- Preserve the original client form while keeping subscriptions normalized.
 if entity='clients' and payload ? 'cardNumber' and coalesce(payload->>'cardNumber','')<>'' then
  perform studio_private.save_record('subscriptions',(select id from public.subscriptions where "clientId"=result_id),
   jsonb_build_object('clientId',result_id,'number',payload->>'cardNumber','issuedAt',payload->>'cardIssuedAt','expiresAt',coalesce(nullif(payload->>'cardExpiresAt',''),((payload->>'cardIssuedAt')::date+365)::text),'discountPercent',coalesce((select "discountPercent" from public.subscriptions where "clientId"=result_id),0)));
 end if;
 return studio_private.row_json(entity,result_id);
exception
 when unique_violation then raise sqlstate 'PT409' using message='Такая запись или уникальный код уже существует';
 when foreign_key_violation then raise sqlstate 'PT409' using message='Связанная запись отсутствует или используется';
 when invalid_text_representation or datetime_field_overflow or invalid_datetime_format or numeric_value_out_of_range then
  perform studio_private.fail('date','Проверьте формат даты, времени и числовых значений'); return null;
end $$;

create or replace function public.studio_api(endpoint text, method text default 'GET', query jsonb default '{}', payload jsonb default '{}') returns jsonb
language plpgsql security definer set search_path=pg_catalog,public,studio_private as $$
declare profile public.profiles; entity text; parts text[]; record_id bigint; action text;
 result jsonb; row_data jsonb; items jsonb:='[]'; total integer:=0; page_n integer; size_n integer; sort_field text; sort_expression text; descending boolean;
 candidate record; key text; value text; field text; conditions text:='true'; permission boolean; related bigint;
begin
 profile:=studio_private.current_profile();
 if profile.id is null then raise sqlstate 'PT401' using message='Войдите в систему'; end if;
 if endpoint='/auth/me' then return to_jsonb(profile)-'auth_id'; end if;
 if endpoint='/manager/workspace' or endpoint='/admin/statistics' then
  if (endpoint='/manager/workspace' and profile.role<>'manager') or (endpoint='/admin/statistics' and profile.role<>'admin') then raise sqlstate 'PT403' using message='Этот раздел доступен другой роли'; end if;
  return jsonb_build_object('users',(select count(*) from public.profiles),'halls',(select count(*) from public.halls where "deletedAt" is null),'clients',(select count(*) from public.clients where "deletedAt" is null),'bookings',(select count(*) from public.bookings where "deletedAt" is null),'activeBookings',(select count(*) from public.bookings where "deletedAt" is null and status='active'),'deletedRecords',(select count(*) from public.bookings where "deletedAt" is not null),'revenue',(select coalesce(sum(amount),0) from public.payments where status='paid' and "deletedAt" is null));
 end if;
 if endpoint='/account/bookings' then
  if profile.role<>'client' then raise sqlstate 'PT403' using message='Личный кабинет доступен клиенту'; end if;
  return coalesce((select jsonb_agg(studio_private.row_json('bookings',id) order by date,"startTime") from public.bookings where "clientId"=profile."clientId" and "deletedAt" is null),'[]');
 end if;
 parts:=string_to_array(trim(both '/' from endpoint),'/');entity:=parts[1];
 if entity='users' then
  if profile.role<>'admin' then raise sqlstate 'PT403' using message='Доступ только администратору'; end if;
  if method='GET' then return jsonb_build_object('items',coalesce((select jsonb_agg(to_jsonb(p)-'auth_id' order by id) from public.profiles p),'[]'));end if;
  if method='PATCH' and parts[3]='role' then
   if parts[2]::bigint=profile.id then raise sqlstate 'PT409' using message='Нельзя изменить собственную роль';end if;
   if payload->>'role' not in ('client','manager','admin') then perform studio_private.fail('role','Выберите роль');end if;
   update public.profiles set role=payload->>'role' where id=parts[2]::bigint;return '{}';
  end if;
  raise sqlstate 'PT405' using message='Метод не поддерживается';
 end if;
 if entity not in ('halls','photographers','clients','equipment','bookings','subscriptions','services','payments') then raise sqlstate 'PT404' using message='Раздел не найден';end if;
 if array_length(parts,1)>1 and parts[2] ~ '^\d+$' then record_id:=parts[2]::bigint; action:=parts[3];else action:=parts[2];end if;
 if profile.role='client' and entity in ('clients','subscriptions','payments') then raise sqlstate 'PT403' using message='Раздел недоступен клиенту';end if;
 permission:=profile.role='admin' or (profile.role='manager' and entity in ('clients','bookings','subscriptions','payments'));
 if method<>'GET' and not permission and not (profile.role='client' and entity='bookings' and method='POST' and (record_id is null and action is null or action='extend')) then raise sqlstate 'PT403' using message='Недостаточно прав для изменения';end if;
 if record_id is not null then
  row_data:=studio_private.row_json(entity,record_id);
  if row_data is null then raise sqlstate 'PT404' using message='Запись не найдена';end if;
  if profile.role='client' and entity='bookings' and (row_data->>'clientId')::bigint<>profile."clientId" then raise sqlstate 'PT403' using message='Чужое бронирование недоступно';end if;
 end if;
 if method='GET' then
  if record_id is not null then return row_data;end if;
  page_n:=greatest(1,least(coalesce((query->>'page')::int,1),100000));size_n:=greatest(1,least(coalesce((query->>'size')::int,10),100));
  if coalesce(query->>'includeDeleted','false')<>'true' then conditions:=conditions||' and t."deletedAt" is null';elsif profile.role<>'admin' then raise sqlstate 'PT403' using message='Архив доступен администратору';end if;
  if profile.role='client' and entity='bookings' then conditions:=conditions||format(' and t."clientId"=%L',profile."clientId");end if;
  -- All filters and pagination run in PostgreSQL. Keys/columns are allowlisted;
  -- values are quoted as SQL literals, so URLs cannot inject SQL.
  for key,value in select * from jsonb_each_text(query) loop
   if value is null or value='' or key in ('page','size','sort','includeDeleted') then continue;end if;
   field:=case key when 'priceFrom' then case when entity='equipment' then 'pricePerDay' when entity='services' then 'price' else 'hourlyRate' end when 'priceTo' then case when entity='equipment' then 'pricePerDay' when entity='services' then 'price' else 'hourlyRate' end when 'rateFrom' then 'hourlyRate' when 'rateTo' then 'hourlyRate' when 'experienceFrom' then 'experienceYears' when 'experienceTo' then 'experienceYears' when 'capacityFrom' then 'capacity' when 'capacityTo' then 'capacity' when 'participantsFrom' then 'participants' when 'participantsTo' then 'participants' when 'durationFrom' then 'durationHours' when 'durationTo' then 'durationHours' when 'quantityFrom' then 'quantity' when 'quantityTo' then 'quantity' when 'discountFrom' then 'discountPercent' when 'discountTo' then 'discountPercent' when 'amountFrom' then 'amount' when 'amountTo' then 'amount' when 'dateFrom' then 'date' when 'dateTo' then 'date' else key end;
   if key='search' then conditions:=conditions||format(' and studio_private.row_json(%L,t.id)::text ilike %L',entity,'%'||value||'%');
   elsif entity='photographers' and key='hallId' then conditions:=conditions||format(' and exists(select 1 from public.photographer_halls ph where ph."photographerId"=t.id and ph."hallId"=%L::bigint)',value);
   elsif entity='bookings' and key='photographerId' then conditions:=conditions||format(' and exists(select 1 from public.booking_photographers bp where bp."bookingId"=t.id and bp."photographerId"=%L::bigint)',value);
   elsif entity='clients' and key='hasCard' then conditions:=conditions||case when value='false' then ' and not ' else ' and ' end||'exists(select 1 from public.subscriptions s where s."clientId"=t.id and s."deletedAt" is null)';
   elsif entity='clients' and key in ('yearFrom','yearTo') then conditions:=conditions||format(' and exists(select 1 from public.subscriptions s where s."clientId"=t.id and extract(year from s."issuedAt") %s %L::int)',case when key='yearFrom' then '>=' else '<=' end,value);
   elsif exists(select 1 from pg_attribute where attrelid=format('public.%I',entity)::regclass and attname=field and attnum>0 and not attisdropped) then
    conditions:=conditions||format(' and t.%I %s %L',field,case when key like '%From' then '>=' when key like '%To' then '<=' else '=' end,value);
   end if;
  end loop;
  sort_field:=split_part(coalesce(query->>'sort','id,asc'),',',1);descending:=split_part(query->>'sort',',',2)='desc';
  if entity='bookings' and sort_field='clientName' then
   sort_expression:='(studio_private.row_json(''bookings'',t.id)->>''clientName'')';
  else
   if not exists(select 1 from pg_attribute where attrelid=format('public.%I',entity)::regclass and attname=sort_field and attnum>0 and not attisdropped) then sort_field:='id';end if;
   sort_expression:=format('t.%I',sort_field);
  end if;
  execute format('select count(*) from public.%I t where %s',entity,conditions) into total;
  for candidate in execute format('select t.id from public.%I t where %s order by %s %s,t.id limit %s offset %s',entity,conditions,sort_expression,case when descending then 'desc' else 'asc' end,size_n,(page_n-1)*size_n) loop
   items:=items||jsonb_build_array(studio_private.row_json(entity,candidate.id));
  end loop;
  return jsonb_build_object('items',items,'total',total,'page',page_n,'size',size_n,'totalPages',ceil(total::numeric/size_n));
 elsif action='bulk-delete' then
  if jsonb_array_length(coalesce(payload->'ids','[]')) not between 1 and 100 then perform studio_private.fail('ids','Выберите от 1 до 100 записей');end if;
  if coalesce(query->>'hard','false')='true' and profile.role<>'admin' then raise sqlstate 'PT403' using message='Физическое удаление доступно администратору';end if;
  for related in select distinct value::bigint from jsonb_array_elements_text(payload->'ids') loop perform studio_private.delete_record(entity,related,coalesce(query->>'hard','false')='true');total:=total+1;end loop;
  return jsonb_build_object('deleted',total);
 elsif method='DELETE' and record_id is not null then
  if coalesce(query->>'hard','false')='true' and profile.role<>'admin' then raise sqlstate 'PT403' using message='Физическое удаление доступно администратору';end if;
  perform studio_private.delete_record(entity,record_id,coalesce(query->>'hard','false')='true');return '{}';
 elsif action='restore' and record_id is not null then
  if profile.role<>'admin' then raise sqlstate 'PT403' using message='Восстановление доступно администратору';end if;
  perform pg_advisory_xact_lock(7940401);
  execute format('update public.%I set "deletedAt"=null where id=$1',entity) using record_id;
  result:=studio_private.save_record(entity,record_id,'{}');return result;
 elsif entity='bookings' and action in ('extend','cancel','complete') then
  if row_data->>'status'<>'active' or row_data->>'deletedAt' is not null then raise sqlstate 'PT409' using message='Бронирование уже закрыто или удалено';end if;
  if action='extend' then
   if profile.role<>'client' then raise sqlstate 'PT403' using message='Продление доступно владельцу бронирования';end if;
   return studio_private.save_record(entity,record_id,jsonb_build_object('durationHours',(row_data->>'durationHours')::int+1));
  end if;
  return studio_private.save_record(entity,record_id,jsonb_build_object('status',case when action='cancel' then 'cancelled' else 'completed' end));
 elsif method in ('POST','PUT','PATCH') and action is null then return studio_private.save_record(entity,record_id,payload);
 end if;
 raise sqlstate 'PT405' using message='Метод не поддерживается';
exception when invalid_text_representation or numeric_value_out_of_range then perform studio_private.fail('query','Проверьте параметры запроса');return null;
end $$;
commit;
