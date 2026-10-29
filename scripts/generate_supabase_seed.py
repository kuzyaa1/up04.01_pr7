"""Generate initial photo studio records from existing project fixtures."""
import json
from pathlib import Path

root=Path(__file__).resolve().parent.parent
source=json.loads((root/'server/seed-pr3.json').read_text(encoding='utf-8'))
chunks=['-- Apply after 202610290001_studio.sql to a new project.\nbegin;']
def insert(table,records):
    cols=list(records[0])
    quoted=','.join('"'+c+'"' for c in cols)
    chunks.append(f'insert into public.{table}({quoted}) select {quoted} from jsonb_populate_recordset(null::public.{table},$seed${json.dumps(records,ensure_ascii=False)}$seed$::jsonb);')
for table in ['halls','photographers','clients','equipment']:
    rows=[]
    for original in source[table]:
        row=dict(original)
        for key in ['equipmentIds','bookingIds','hallIds','cardNumber','cardIssuedAt','cardExpiresAt']:
            row.pop(key,None)
        if table=='clients':row['fullName']=row.pop('name')
        rows.append(row)
    insert(table,rows)
insert('subscriptions',[dict(id=c['id'],clientId=c['id'],number=c['cardNumber'],issuedAt=c['cardIssuedAt'],expiresAt=c['cardExpiresAt'],discountPercent=10) for c in source['clients']])
insert('services',[
    dict(id=1,name='Макияж перед съёмкой',category='Подготовка',price=2500,description='Подготовка образа визажистом'),
    dict(id=2,name='Ретушь десяти фотографий',category='Обработка',price=1500,description='Цветокоррекция и ретушь'),
    dict(id=3,name='Аренда дополнительного фона',category='Реквизит',price=700,description='Дополнительный бумажный фон'),
])
for p in source['photographers']:
    for hall in p['hallIds']:chunks.append(f'insert into public.photographer_halls values({p["id"]},{hall});')
rows=[]
for b in source['bookings']:
    row={k:v for k,v in b.items() if k not in ['clientName','photographerIds']}
    row['date']=row['date'].split('T')[0]
    row['startTime']='10:00'
    rows.append(row)
insert('bookings',rows)
chunks.append('update public.bookings set date=current_date+id::integer+7;')
for b in source['bookings']:
    for person in b['photographerIds']:chunks.append(f'insert into public.booking_photographers values({b["id"]},{person});')
chunks.append('insert into public.booking_services values (1,1),(2,2),(3,3);')
chunks.append('do $$declare b record;begin for b in select id from public.bookings loop perform studio_private.check_booking(b.id);end loop;end $$;')
chunks.append("insert into public.payments(\"bookingId\",amount,method,status,note) values(1,1000,'Карта','paid','Предоплата'),(2,500,'Перевод','paid','Предоплата');")
for table in ['halls','photographers','clients','equipment','subscriptions','services','bookings','payments']:
    chunks.append(f"select setval(pg_get_serial_sequence('public.{table}','id'),greatest(coalesce((select max(id) from public.{table}),0),1),exists(select 1 from public.{table}));")
chunks.append('commit;')
(root/'supabase/migrations/202610290002_seed.sql').write_text('\n\n'.join(chunks)+'\n',encoding='utf-8')
