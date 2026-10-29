-- Dashboard-created accounts have no registration form metadata.
-- They still receive the client role; staff promotion is a separate operation.
create or replace function studio_private.on_signup() returns trigger
language plpgsql security definer set search_path=pg_catalog,public,studio_private as $$
declare client_id bigint; full_name text; login_name text;
begin
 full_name:=trim(coalesce(new.raw_user_meta_data->>'fullName','Клиент '||substr(new.id::text,1,8)));
 login_name:=lower(trim(coalesce(new.raw_user_meta_data->>'username','user_'||replace(new.id::text,'-',''))));
 if length(full_name) not between 2 and 100 then perform studio_private.fail('fullName','ФИО от 2 до 100 символов'); end if;
 if login_name !~ '^[a-z0-9_]{3,40}$' then perform studio_private.fail('username','Логин: 3–40 латинских букв, цифр или подчёркиваний'); end if;
 insert into public.clients("fullName",email) values(full_name,new.email) returning id into client_id;
 insert into public.profiles(auth_id,username,"fullName",email,"clientId")
 values(new.id,login_name,full_name,new.email,client_id);
 return new;
end $$;
