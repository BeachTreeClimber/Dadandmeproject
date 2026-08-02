-- Make planner_date a real date column so each day has its own planner.

-- 1. Add a temporary date column
alter table public.planners add column planner_day date;

-- 2. Backfill from the old text column, falling back to today if unparseable
do $$
declare
  r record;
  d date;
begin
  for r in select id, planner_date from public.planners loop
    begin
      d := to_date(r.planner_date, 'Day, FMMonth FMDD, YYYY');
    exception when others then
      d := null;
    end;
    update public.planners set planner_day = coalesce(d, current_date) where id = r.id;
  end loop;
end $$;

-- 3. Keep only one planner per day (earliest kept)
delete from public.planners a
using public.planners b
where a.id <> b.id
  and a.planner_day = b.planner_day
  and a.created_at > b.created_at;

-- 4. Enforce not null + uniqueness
alter table public.planners alter column planner_day set not null;
alter table public.planners add constraint planners_planner_day_key unique (planner_day);

-- 5. Swap columns
alter table public.planners drop column planner_date;
alter table public.planners rename column planner_day to planner_date;
