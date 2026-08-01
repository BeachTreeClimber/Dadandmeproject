-- Add the edit role and shared access so family members can edit the same planner.

-- 1. Seed the edit role
insert into public.roles (name)
values ('edit')
on conflict (name) do nothing;

-- 2. Helper: does the current user have a given role?
create or replace function public.has_role(role_name text)
returns boolean
language sql
stable
security definer
as $$
  select exists (
    select 1
    from public.user_roles ur
    join public.roles r on r.id = ur.role_id
    where ur.user_id = auth.uid()
      and r.name = role_name
  );
$$;

-- 3. Shared-access policies on planners:
--    admins and editors can read/write any planner row (the shared family planner),
--    while other authenticated users keep access to their own rows only.

create policy "Admins and editors can read all planners"
  on public.planners for select
  to authenticated
  using (public.is_admin() or public.has_role('edit'));

create policy "Admins and editors can insert planners"
  on public.planners for insert
  to authenticated
  with check (public.is_admin() or public.has_role('edit'));

create policy "Admins and editors can update all planners"
  on public.planners for update
  to authenticated
  using (public.is_admin() or public.has_role('edit'))
  with check (public.is_admin() or public.has_role('edit'));

create policy "Admins and editors can delete all planners"
  on public.planners for delete
  to authenticated
  using (public.is_admin() or public.has_role('edit'));

-- 4. Grants for the new helper function
grant execute on function public.has_role(text) to anon, authenticated, service_role;
