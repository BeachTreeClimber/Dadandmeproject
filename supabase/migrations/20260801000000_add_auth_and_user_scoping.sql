-- Auth + planner schema for Daily Planner.
-- Creates the planners table if it does not exist, then scopes it to signed-in users.

-- 1. Create the base planners table if missing
create table if not exists public.planners (
  id uuid default gen_random_uuid() primary key,
  planner_date text not null,
  hours jsonb not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Add user_id column to existing planners table
alter table public.planners add column if not exists user_id uuid references auth.users(id) on delete cascade;

-- 3. Index for fast lookups by user
create index if not exists planners_user_id_idx on public.planners (user_id);

-- 4. Enable Row Level Security
alter table public.planners enable row level security;

-- 5. Drop the old permissive public policy from the first schema
drop policy if exists "Allow public access to planners" on public.planners;

-- 6. User-scoped policies (each user only sees their own planners)
create policy "Users read own planners"
  on public.planners for select
  to authenticated
  using (user_id = auth.uid());

create policy "Users insert own planners"
  on public.planners for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "Users update own planners"
  on public.planners for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "Users delete own planners"
  on public.planners for delete
  to authenticated
  using (user_id = auth.uid());

-- 7. Grant Data API access (new Supabase projects no longer auto-expose tables)
grant usage on schema public to anon, authenticated, service_role;
grant select, insert, update, delete on public.planners to authenticated;
grant all privileges on public.planners to service_role;
