-- Idempotent initial academic structure for AcadMind.
-- Year 1 is active; Years 2-4 remain visible as Coming Soon.
insert into public.academic_years (name_ar,name_en,code,status,display_order)
values
 ('الفرقة الأولى','First Year','year_1','active',1),
 ('الفرقة الثانية','Second Year','year_2','coming_soon',2),
 ('الفرقة الثالثة','Third Year','year_3','coming_soon',3),
 ('الفرقة الرابعة','Fourth Year','year_4','coming_soon',4)
on conflict (code) do update set name_ar=excluded.name_ar,name_en=excluded.name_en,status=excluded.status,display_order=excluded.display_order,deleted_at=null;

insert into public.groups (academic_year_id,name,code,display_order,is_active)
select y.id,g.name,g.code,g.ord,true
from public.academic_years y
cross join (values ('Group 1','G1',1),('Group 2','G2',2)) as g(name,code,ord)
where y.code='year_1'
on conflict (academic_year_id,code) do update set name=excluded.name,display_order=excluded.display_order,is_active=true,deleted_at=null;

insert into public.sections (academic_year_id,group_id,name,code,display_order,is_active)
select g.academic_year_id,g.id,'Section '||s.n,'Sec '||s.n,s.n,true
from public.groups g cross join generate_series(1,6) as s(n)
where g.code in ('G1','G2')
on conflict (group_id,code) do update set name=excluded.name,display_order=excluded.display_order,is_active=true,deleted_at=null;
