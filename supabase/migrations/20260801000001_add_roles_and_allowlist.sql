-- Roles, user profiles, and login allowlist for Daily Planner
-- Ported from Freshie's auth model, simplified to a single admin role.

-- 1. Roles
create table public.roles (
  id   uuid primary key default gen_random_uuid(),
  name text not null unique
);

create table public.user_roles (
  id      uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role_id uuid not null references roles(id) on delete cascade,
  unique (user_id, role_id)
);

-- 2. User profiles
create table public.user_profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at   timestamptz not null default now()
);

-- 3. Login allowlist (only these emails may sign in)
create table public.user_login_emails (
  id         uuid primary key default gen_random_uuid(),
  email      text not null unique,
  created_at timestamptz not null default now()
);

-- Seed: admin role
insert into public.roles (name)
values ('admin')
on conflict (name) do nothing;

-- Helper: is the current user an admin?
create or replace function public.is_admin()
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
      and r.name = 'admin'
  );
$$;

-- RPC: fetch email + last_sign_in_at for admin views
create or replace function public.get_auth_user_info(user_ids uuid[])
returns table (user_id uuid, email text, last_sign_in_at timestamptz)
language sql
stable
security definer set search_path = ''
as $$
  select id, email, last_sign_in_at
  from auth.users
  where id = any(user_ids);
$$;

-- Trigger: auto-create a profile on signup, honoring the allowlist.
-- The first user to sign up becomes admin and is added to the allowlist.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
  invite_count integer;
  email_allowed boolean;
  user_count integer;
  admin_role_id uuid;
begin
  select count(*) into invite_count from public.user_login_emails;

  if invite_count > 0 then
    select exists(
      select 1 from public.user_login_emails where email = new.email
    ) into email_allowed;

    if not email_allowed then
      return new;
    end if;
  end if;

  select count(*) into user_count from public.user_profiles;

  insert into public.user_profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.email)
  );

  if user_count = 0 then
    select id into admin_role_id from public.roles where name = 'admin';
    if admin_role_id is not null then
      insert into public.user_roles (user_id, role_id)
      values (new.id, admin_role_id)
      on conflict (user_id, role_id) do nothing;
    end if;
    insert into public.user_login_emails (email)
    values (new.email)
    on conflict (email) do nothing;
  end if;

  return new;
end;
$$;

-- RPC: called by the front-end when no profile exists.
create or replace function public.try_create_profile()
returns boolean
language plpgsql
security definer set search_path = ''
as $$
declare
  user_email text;
  user_display_name text;
  invite_exists boolean;
  profile_exists boolean;
  user_count integer;
  admin_role_id uuid;
begin
  select email, raw_user_meta_data ->> 'full_name'
  into user_email, user_display_name
  from auth.users
  where id = auth.uid();

  if user_email is null then
    return false;
  end if;

  select exists(select 1 from public.user_profiles where id = auth.uid()) into profile_exists;
  if profile_exists then
    return true;
  end if;

  select exists(select 1 from public.user_login_emails where email = user_email) into invite_exists;

  if not invite_exists then
    if exists(select 1 from public.user_login_emails) then
      return false;
    end if;
  end if;

  select count(*) into user_count from public.user_profiles;

  insert into public.user_profiles (id, display_name)
  values (auth.uid(), coalesce(user_display_name, user_email))
  on conflict (id) do nothing;

  if user_count = 0 then
    select id into admin_role_id from public.roles where name = 'admin';
    if admin_role_id is not null then
      insert into public.user_roles (user_id, role_id)
      values (auth.uid(), admin_role_id)
      on conflict (user_id, role_id) do nothing;
    end if;
    insert into public.user_login_emails (email)
    values (user_email)
    on conflict (email) do nothing;
  end if;

  return true;
end;
$$;

-- Trigger on auth.users
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Row Level Security

alter table public.roles enable row level security;

create policy "Anyone can read roles"
  on public.roles for select
  to authenticated
  using (true);

create policy "Only admins can insert roles"
  on public.roles for insert
  to authenticated
  with check (public.is_admin());

create policy "Only admins can update roles"
  on public.roles for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy "Only admins can delete roles"
  on public.roles for delete
  to authenticated
  using (public.is_admin());

alter table public.user_roles enable row level security;

create policy "Users can read own role; admins read all"
  on public.user_roles for select
  to authenticated
  using (user_id = auth.uid() or public.is_admin());

create policy "Only admins can insert user_roles"
  on public.user_roles for insert
  to authenticated
  with check (public.is_admin());

create policy "Only admins can update user_roles"
  on public.user_roles for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy "Only admins can delete user_roles"
  on public.user_roles for delete
  to authenticated
  using (public.is_admin());

alter table public.user_profiles enable row level security;

create policy "Users read own profile; admins all"
  on public.user_profiles for select
  to authenticated
  using (id = auth.uid() or public.is_admin());

create policy "Admin can update any profile"
  on public.user_profiles for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy "Users can update own profile"
  on public.user_profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

create policy "Admin can insert profiles"
  on public.user_profiles for insert
  to authenticated
  with check (public.is_admin());

create policy "Users can insert own profile"
  on public.user_profiles for insert
  to authenticated
  with check (id = auth.uid());

create policy "Admin can delete profiles"
  on public.user_profiles for delete
  to authenticated
  using (public.is_admin());

alter table public.user_login_emails enable row level security;

create policy "Admins can read user_login_emails"
  on public.user_login_emails for select
  to authenticated
  using (public.is_admin());

create policy "Admins can insert user_login_emails"
  on public.user_login_emails for insert
  to authenticated
  with check (public.is_admin());

create policy "Admins can delete user_login_emails"
  on public.user_login_emails for delete
  to authenticated
  using (public.is_admin());

-- Grants for Data API (new Supabase projects need explicit grants)

grant usage on schema public to anon, authenticated, service_role;

grant select, insert, update, delete on public.roles to authenticated;
grant all privileges on public.roles to service_role;

grant select, insert, update, delete on public.user_roles to authenticated;
grant all privileges on public.user_roles to service_role;

grant select, insert, update, delete on public.user_profiles to authenticated;
grant all privileges on public.user_profiles to service_role;

grant select, insert, update, delete on public.user_login_emails to authenticated;
grant all privileges on public.user_login_emails to service_role;

grant execute on function public.is_admin() to anon, authenticated, service_role;
grant execute on function public.get_auth_user_info(uuid[]) to anon, authenticated, service_role;
grant execute on function public.try_create_profile() to anon, authenticated, service_role;
grant execute on function public.handle_new_user() to anon, authenticated, service_role;
