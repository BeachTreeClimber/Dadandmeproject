-- 1. Create a table for daily planners
create table public.planners (
  id uuid default gen_random_uuid() primary key,
  planner_date text not null,
  hours jsonb not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Enable Row Level Security (RLS)
alter table public.planners enable row level security;

-- 3. Create a public policy allowing anyone to read/write planners for now (simplest for getting started)
create policy "Allow public access to planners"
  on public.planners
  for all
  using (true)
  with check (true);
