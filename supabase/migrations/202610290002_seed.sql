-- Apply after 202610290001_studio.sql to a new project.
begin;

insert into public.halls("id","name","code","style","description","capacity","hourlyRate","deletedAt") select "id","name","code","style","description","capacity","hourlyRate","deletedAt" from jsonb_populate_recordset(null::public.halls,$seed$[{"id": 1, "name": "Белая циклорама", "code": "A-01", "style": "Циклорама", "description": "", "capacity": 8, "hourlyRate": 2500, "deletedAt": null}, {"id": 2, "name": "Loft Factory", "code": "A-02", "style": "Лофт", "description": "", "capacity": 12, "hourlyRate": 3200, "deletedAt": null}, {"id": 3, "name": "Скандинавия", "code": "B-01", "style": "Интерьерный", "description": "", "capacity": 6, "hourlyRate": 2800, "deletedAt": null}, {"id": 4, "name": "Black Room", "code": "B-02", "style": "Тёмный зал", "description": "", "capacity": 5, "hourlyRate": 2700, "deletedAt": null}, {"id": 5, "name": "Оранжерея", "code": "C-01", "style": "Дневной свет", "description": "", "capacity": 10, "hourlyRate": 3500, "deletedAt": null}, {"id": 6, "name": "Minimal", "code": "C-02", "style": "Циклорама", "description": "", "capacity": 4, "hourlyRate": 2100, "deletedAt": null}, {"id": 7, "name": "Кирпич и металл", "code": "D-01", "style": "Лофт", "description": "", "capacity": 14, "hourlyRate": 3900, "deletedAt": null}, {"id": 8, "name": "Гостиная", "code": "D-02", "style": "Интерьерный", "description": "", "capacity": 7, "hourlyRate": 2900, "deletedAt": null}, {"id": 9, "name": "Noir", "code": "E-01", "style": "Тёмный зал", "description": "", "capacity": 6, "hourlyRate": 3000, "deletedAt": null}, {"id": 10, "name": "Панорамный зал", "code": "E-02", "style": "Дневной свет", "description": "", "capacity": 16, "hourlyRate": 4500, "deletedAt": null}, {"id": 11, "name": "White Box", "code": "F-01", "style": "Циклорама", "description": "", "capacity": 9, "hourlyRate": 2600, "deletedAt": null}, {"id": 12, "name": "Винтаж", "code": "F-02", "style": "Интерьерный", "description": "", "capacity": 8, "hourlyRate": 3100, "deletedAt": null}, {"id": 13, "name": "Графит", "code": "G-01", "style": "Тёмный зал", "description": "", "capacity": 4, "hourlyRate": 2300, "deletedAt": null}, {"id": 14, "name": "Brick Hall", "code": "G-02", "style": "Лофт", "description": "", "capacity": 11, "hourlyRate": 3400, "deletedAt": null}, {"id": 15, "name": "Светлая веранда", "code": "H-01", "style": "Дневной свет", "description": "", "capacity": 9, "hourlyRate": 3300, "deletedAt": null}, {"id": 16, "name": "Milk Studio", "code": "H-02", "style": "Циклорама", "description": "", "capacity": 6, "hourlyRate": 2400, "deletedAt": null}, {"id": 17, "name": "Кабинет", "code": "I-01", "style": "Интерьерный", "description": "", "capacity": 4, "hourlyRate": 2200, "deletedAt": null}, {"id": 18, "name": "Industrial", "code": "I-02", "style": "Лофт", "description": "", "capacity": 15, "hourlyRate": 4200, "deletedAt": null}, {"id": 19, "name": "Тёмная комната", "code": "J-01", "style": "Тёмный зал", "description": "", "capacity": 3, "hourlyRate": 2000, "deletedAt": null}, {"id": 20, "name": "Сад", "code": "J-02", "style": "Дневной свет", "description": "", "capacity": 12, "hourlyRate": 3800, "deletedAt": null}, {"id": 21, "name": "Paper Wall", "code": "K-01", "style": "Циклорама", "description": "", "capacity": 7, "hourlyRate": 2550, "deletedAt": null}, {"id": 22, "name": "Ателье", "code": "K-02", "style": "Интерьерный", "description": "", "capacity": 5, "hourlyRate": 2750, "deletedAt": null}, {"id": 23, "name": "Завод", "code": "L-01", "style": "Лофт", "description": "", "capacity": 13, "hourlyRate": 3600, "deletedAt": null}, {"id": 24, "name": "Moonlight", "code": "L-02", "style": "Тёмный зал", "description": "", "capacity": 7, "hourlyRate": 2950, "deletedAt": null}, {"id": 25, "name": "Солнечный зал", "code": "M-01", "style": "Дневной свет", "description": "", "capacity": 8, "hourlyRate": 3150, "deletedAt": null}]$seed$::jsonb);

insert into public.photographers("id","firstName","lastName","specialization","bio","experienceYears","hourlyRate","deletedAt") select "id","firstName","lastName","specialization","bio","experienceYears","hourlyRate","deletedAt" from jsonb_populate_recordset(null::public.photographers,$seed$[{"id": 1, "firstName": "Анна", "lastName": "Волкова", "specialization": "Портрет", "bio": "", "experienceYears": 7, "hourlyRate": 4500, "deletedAt": null}, {"id": 2, "firstName": "Илья", "lastName": "Соколов", "specialization": "Fashion", "bio": "", "experienceYears": 9, "hourlyRate": 6000, "deletedAt": null}, {"id": 3, "firstName": "Мария", "lastName": "Белова", "specialization": "Семейная съёмка", "bio": "", "experienceYears": 5, "hourlyRate": 4000, "deletedAt": null}, {"id": 4, "firstName": "Дмитрий", "lastName": "Орлов", "specialization": "Предметная съёмка", "bio": "", "experienceYears": 8, "hourlyRate": 5500, "deletedAt": null}, {"id": 5, "firstName": "Елена", "lastName": "Кравцова", "specialization": "Контент для брендов", "bio": "", "experienceYears": 6, "hourlyRate": 5000, "deletedAt": null}, {"id": 6, "firstName": "Максим", "lastName": "Лебедев", "specialization": "Портрет", "bio": "", "experienceYears": 4, "hourlyRate": 3500, "deletedAt": null}, {"id": 7, "firstName": "Ольга", "lastName": "Романова", "specialization": "Семейная съёмка", "bio": "", "experienceYears": 10, "hourlyRate": 6500, "deletedAt": null}, {"id": 8, "firstName": "Кирилл", "lastName": "Морозов", "specialization": "Fashion", "bio": "", "experienceYears": 3, "hourlyRate": 3200, "deletedAt": null}, {"id": 9, "firstName": "София", "lastName": "Иванова", "specialization": "Контент для брендов", "bio": "", "experienceYears": 5, "hourlyRate": 4300, "deletedAt": null}, {"id": 10, "firstName": "Павел", "lastName": "Захаров", "specialization": "Предметная съёмка", "bio": "", "experienceYears": 11, "hourlyRate": 7000, "deletedAt": null}]$seed$::jsonb);

insert into public.clients("id","email","phone","clientType","company","notes","deletedAt","fullName") select "id","email","phone","clientType","company","notes","deletedAt","fullName" from jsonb_populate_recordset(null::public.clients,$seed$[{"id": 1, "email": "irina.sokolova@mail.ru", "phone": "+7 903 111-22-33", "clientType": "Частный", "company": "", "notes": "Предпочитает светлый фон", "deletedAt": null, "fullName": "Ирина Соколова"}, {"id": 2, "email": "d.krylov@gmail.com", "phone": "+7 903 222-33-44", "clientType": "Корпоративный", "company": "ООО «Ромашка»", "notes": "Каталожные съёмки одежды", "deletedAt": null, "fullName": "Дмитрий Крылов"}, {"id": 3, "email": "m.fedorova@yandex.ru", "phone": "+7 903 333-44-55", "clientType": "Частный", "company": "", "notes": "", "deletedAt": null, "fullName": "Мария Фёдорова"}, {"id": 4, "email": "a.zhukov@mail.ru", "phone": "+7 903 444-55-66", "clientType": "Корпоративный", "company": "АО «МебельВолга»", "notes": "Съёмки для каталога раз в квартал", "deletedAt": null, "fullName": "Алексей Жуков"}, {"id": 5, "email": "o.nikitina@gmail.com", "phone": "+7 903 555-66-77", "clientType": "Частный", "company": "", "notes": "", "deletedAt": null, "fullName": "Ольга Никитина"}, {"id": 6, "email": "s.belov@yandex.ru", "phone": "+7 903 666-77-88", "clientType": "Корпоративный", "company": "ИП «Белов и Партнёры»", "notes": "", "deletedAt": null, "fullName": "Сергей Белов"}, {"id": 7, "email": "n.gromova@mail.ru", "phone": "+7 903 777-88-99", "clientType": "Частный", "company": "", "notes": "", "deletedAt": null, "fullName": "Наталья Громова"}, {"id": 8, "email": "v.danilov@gmail.com", "phone": "+7 903 888-99-00", "clientType": "Частный", "company": "", "notes": "Съёмка украшений, нужен тёмный фон", "deletedAt": null, "fullName": "Виктор Данилов"}, {"id": 9, "email": "e.litvinova@yandex.ru", "phone": "+7 903 999-00-11", "clientType": "Корпоративный", "company": "ООО «Гардероб Плюс»", "notes": "", "deletedAt": null, "fullName": "Екатерина Литвинова"}, {"id": 10, "email": "p.tarasov@mail.ru", "phone": "+7 903 000-11-22", "clientType": "Частный", "company": "", "notes": "Съёмка с животными, нужна тишина", "deletedAt": null, "fullName": "Павел Тарасов"}]$seed$::jsonb);

insert into public.equipment("id","name","category","manufacturer","hallId","quantity","pricePerDay","deletedAt") select "id","name","category","manufacturer","hallId","quantity","pricePerDay","deletedAt" from jsonb_populate_recordset(null::public.equipment,$seed$[{"id": 1, "name": "Светодиодная панель 60W", "category": "Свет", "manufacturer": "Aputure", "hallId": 1, "quantity": 4, "pricePerDay": 3500, "deletedAt": null}, {"id": 2, "name": "Софтбокс 90×120", "category": "Свет", "manufacturer": "Broncolor", "hallId": 1, "quantity": 6, "pricePerDay": 1200, "deletedAt": null}, {"id": 3, "name": "Тканевый фон 3×6 м", "category": "Фоны", "manufacturer": "Kino Flo", "hallId": 2, "quantity": 3, "pricePerDay": 900, "deletedAt": null}, {"id": 4, "name": "Деревянный столик", "category": "Мебель", "manufacturer": "IKEA", "hallId": 3, "quantity": 5, "pricePerDay": 400, "deletedAt": null}, {"id": 5, "name": "RGB LED-панель", "category": "Свет", "manufacturer": "Nanlite", "hallId": 4, "quantity": 8, "pricePerDay": 1800, "deletedAt": null}, {"id": 6, "name": "Кресло-бергер", "category": "Реквизит", "manufacturer": "Студия", "hallId": 5, "quantity": 2, "pricePerDay": 700, "deletedAt": null}, {"id": 7, "name": "Штатив-монопод", "category": "Реквизит", "manufacturer": "Manfrotto", "hallId": 2, "quantity": 3, "pricePerDay": 500, "deletedAt": null}, {"id": 8, "name": "Банкетка", "category": "Мебель", "manufacturer": "Студия", "hallId": 6, "quantity": 4, "pricePerDay": 600, "deletedAt": null}, {"id": 9, "name": "Проектор 5000 лм", "category": "Свет", "manufacturer": "Epson", "hallId": 7, "quantity": 1, "pricePerDay": 2500, "deletedAt": null}, {"id": 10, "name": "Ковёр и подушки", "category": "Реквизит", "manufacturer": "Студия", "hallId": 8, "quantity": 6, "pricePerDay": 300, "deletedAt": null}]$seed$::jsonb);

insert into public.subscriptions("id","clientId","number","issuedAt","expiresAt","discountPercent") select "id","clientId","number","issuedAt","expiresAt","discountPercent" from jsonb_populate_recordset(null::public.subscriptions,$seed$[{"id": 1, "clientId": 1, "number": "AB-2026-0001", "issuedAt": "2026-01-15", "expiresAt": "2027-01-15", "discountPercent": 10}, {"id": 2, "clientId": 2, "number": "AB-2026-0002", "issuedAt": "2026-02-01", "expiresAt": "2027-02-01", "discountPercent": 10}, {"id": 3, "clientId": 3, "number": "AB-2026-0003", "issuedAt": "2026-02-10", "expiresAt": "2027-02-10", "discountPercent": 10}, {"id": 4, "clientId": 4, "number": "AB-2026-0004", "issuedAt": "2026-02-20", "expiresAt": "2027-02-20", "discountPercent": 10}, {"id": 5, "clientId": 5, "number": "AB-2026-0005", "issuedAt": "2026-03-01", "expiresAt": "2027-03-01", "discountPercent": 10}, {"id": 6, "clientId": 6, "number": "AB-2026-0006", "issuedAt": "2026-03-12", "expiresAt": "2027-03-12", "discountPercent": 10}, {"id": 7, "clientId": 7, "number": "AB-2026-0007", "issuedAt": "2026-03-20", "expiresAt": "2027-03-20", "discountPercent": 10}, {"id": 8, "clientId": 8, "number": "AB-2026-0008", "issuedAt": "2026-04-01", "expiresAt": "2027-04-01", "discountPercent": 10}, {"id": 9, "clientId": 9, "number": "AB-2026-0009", "issuedAt": "2026-04-10", "expiresAt": "2027-04-10", "discountPercent": 10}, {"id": 10, "clientId": 10, "number": "AB-2026-0010", "issuedAt": "2026-04-18", "expiresAt": "2027-04-18", "discountPercent": 10}]$seed$::jsonb);

insert into public.services("id","name","category","price","description") select "id","name","category","price","description" from jsonb_populate_recordset(null::public.services,$seed$[{"id": 1, "name": "Макияж перед съёмкой", "category": "Подготовка", "price": 2500, "description": "Подготовка образа визажистом"}, {"id": 2, "name": "Ретушь десяти фотографий", "category": "Обработка", "price": 1500, "description": "Цветокоррекция и ретушь"}, {"id": 3, "name": "Аренда дополнительного фона", "category": "Реквизит", "price": 700, "description": "Дополнительный бумажный фон"}]$seed$::jsonb);

insert into public.photographer_halls values(1,1);

insert into public.photographer_halls values(1,2);

insert into public.photographer_halls values(1,10);

insert into public.photographer_halls values(1,20);

insert into public.photographer_halls values(2,2);

insert into public.photographer_halls values(2,9);

insert into public.photographer_halls values(2,13);

insert into public.photographer_halls values(2,21);

insert into public.photographer_halls values(3,1);

insert into public.photographer_halls values(3,5);

insert into public.photographer_halls values(3,12);

insert into public.photographer_halls values(3,22);

insert into public.photographer_halls values(4,4);

insert into public.photographer_halls values(4,7);

insert into public.photographer_halls values(4,14);

insert into public.photographer_halls values(4,23);

insert into public.photographer_halls values(5,3);

insert into public.photographer_halls values(5,6);

insert into public.photographer_halls values(5,15);

insert into public.photographer_halls values(5,24);

insert into public.photographer_halls values(6,6);

insert into public.photographer_halls values(6,8);

insert into public.photographer_halls values(6,16);

insert into public.photographer_halls values(6,25);

insert into public.photographer_halls values(7,5);

insert into public.photographer_halls values(7,8);

insert into public.photographer_halls values(7,17);

insert into public.photographer_halls values(8,10);

insert into public.photographer_halls values(8,11);

insert into public.photographer_halls values(8,18);

insert into public.photographer_halls values(9,4);

insert into public.photographer_halls values(9,7);

insert into public.photographer_halls values(9,8);

insert into public.photographer_halls values(10,7);

insert into public.photographer_halls values(10,13);

insert into public.photographer_halls values(10,19);

insert into public.bookings("id","clientId","email","accessCode","hallId","date","durationHours","participants","shootingType","comment","status","deletedAt","startTime") select "id","clientId","email","accessCode","hallId","date","durationHours","participants","shootingType","comment","status","deletedAt","startTime" from jsonb_populate_recordset(null::public.bookings,$seed$[{"id": 1, "clientId": 1, "email": "irina.sokolova@mail.ru", "accessCode": "BR-2026-0001", "hallId": 1, "date": "2026-03-12", "durationHours": 3, "participants": 4, "shootingType": "Портретная", "comment": "Съёмка на светлом фоне", "status": "active", "deletedAt": null, "startTime": "10:00"}, {"id": 2, "clientId": 2, "email": "d.krylov@gmail.com", "accessCode": "BR-2026-0002", "hallId": 2, "date": "2026-03-18", "durationHours": 5, "participants": 2, "shootingType": "Fashion", "comment": "Каталожная съёмка одежды", "status": "active", "deletedAt": null, "startTime": "10:00"}, {"id": 3, "clientId": 3, "email": "m.fedorova@yandex.ru", "accessCode": "BR-2026-0003", "hallId": 5, "date": "2026-04-02", "durationHours": 2, "participants": 6, "shootingType": "Семейная", "comment": "", "status": "active", "deletedAt": null, "startTime": "10:00"}, {"id": 4, "clientId": 4, "email": "a.zhukov@mail.ru", "accessCode": "BR-2026-0004", "hallId": 7, "date": "2026-04-09", "durationHours": 8, "participants": 12, "shootingType": "Рекламная", "comment": "Съёмка для каталога мебели", "status": "active", "deletedAt": null, "startTime": "10:00"}, {"id": 5, "clientId": 5, "email": "o.nikitina@gmail.com", "accessCode": "BR-2026-0005", "hallId": 4, "date": "2026-04-21", "durationHours": 4, "participants": 3, "shootingType": "Предметная", "comment": "Тёмный фон, контрастный свет", "status": "active", "deletedAt": null, "startTime": "10:00"}, {"id": 6, "clientId": 6, "email": "s.belov@yandex.ru", "accessCode": "BR-2026-0006", "hallId": 10, "date": "2026-05-05", "durationHours": 6, "participants": 4, "shootingType": "Fashion", "comment": "", "status": "active", "deletedAt": null, "startTime": "10:00"}, {"id": 7, "clientId": 7, "email": "n.gromova@mail.ru", "accessCode": "BR-2026-0007", "hallId": 3, "date": "2026-05-14", "durationHours": 2, "participants": 2, "shootingType": "Портретная", "comment": "Интерьерная съёмка", "status": "active", "deletedAt": null, "startTime": "10:00"}, {"id": 8, "clientId": 8, "email": "v.danilov@gmail.com", "accessCode": "BR-2026-0008", "hallId": 6, "date": "2026-05-27", "durationHours": 1, "participants": 1, "shootingType": "Предметная", "comment": "Каталожные фото украшений", "status": "active", "deletedAt": null, "startTime": "10:00"}, {"id": 9, "clientId": 9, "email": "e.litvinova@yandex.ru", "accessCode": "BR-2026-0009", "hallId": 13, "date": "2026-06-03", "durationHours": 4, "participants": 4, "shootingType": "Fashion", "comment": "", "status": "active", "deletedAt": null, "startTime": "10:00"}, {"id": 10, "clientId": 10, "email": "p.tarasov@mail.ru", "accessCode": "BR-2026-0010", "hallId": 8, "date": "2026-06-11", "durationHours": 3, "participants": 4, "shootingType": "Семейная", "comment": "Съёмка с домашними животными", "status": "active", "deletedAt": null, "startTime": "10:00"}]$seed$::jsonb);

update public.bookings set date=current_date+id::integer+7;

insert into public.booking_photographers values(1,1);

insert into public.booking_photographers values(1,3);

insert into public.booking_photographers values(2,2);

insert into public.booking_photographers values(3,3);

insert into public.booking_photographers values(3,7);

insert into public.booking_photographers values(4,10);

insert into public.booking_photographers values(5,4);

insert into public.booking_photographers values(5,9);

insert into public.booking_photographers values(6,1);

insert into public.booking_photographers values(6,8);

insert into public.booking_photographers values(7,5);

insert into public.booking_photographers values(8,6);

insert into public.booking_photographers values(9,2);

insert into public.booking_photographers values(9,10);

insert into public.booking_photographers values(10,7);

insert into public.booking_photographers values(10,9);

insert into public.booking_services values (1,1),(2,2),(3,3);

do $$declare b record;begin for b in select id from public.bookings loop perform studio_private.check_booking(b.id);end loop;end $$;

insert into public.payments("bookingId",amount,method,status,note) values(1,1000,'Карта','paid','Предоплата'),(2,500,'Перевод','paid','Предоплата');

select setval(pg_get_serial_sequence('public.halls','id'),greatest(coalesce((select max(id) from public.halls),0),1),exists(select 1 from public.halls));

select setval(pg_get_serial_sequence('public.photographers','id'),greatest(coalesce((select max(id) from public.photographers),0),1),exists(select 1 from public.photographers));

select setval(pg_get_serial_sequence('public.clients','id'),greatest(coalesce((select max(id) from public.clients),0),1),exists(select 1 from public.clients));

select setval(pg_get_serial_sequence('public.equipment','id'),greatest(coalesce((select max(id) from public.equipment),0),1),exists(select 1 from public.equipment));

select setval(pg_get_serial_sequence('public.subscriptions','id'),greatest(coalesce((select max(id) from public.subscriptions),0),1),exists(select 1 from public.subscriptions));

select setval(pg_get_serial_sequence('public.services','id'),greatest(coalesce((select max(id) from public.services),0),1),exists(select 1 from public.services));

select setval(pg_get_serial_sequence('public.bookings','id'),greatest(coalesce((select max(id) from public.bookings),0),1),exists(select 1 from public.bookings));

select setval(pg_get_serial_sequence('public.payments','id'),greatest(coalesce((select max(id) from public.payments),0),1),exists(select 1 from public.payments));

commit;
