-- TurnoCero: esquema para perfiles, agenda y administración segura.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '', phone text not null default '',
  role text not null default 'patient' check (role in ('patient', 'admin')),
  created_at timestamptz not null default now()
);
create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  doctor_id text not null, doctor_name text not null, specialty text not null,
  appointment_date date not null, appointment_time text not null,
  status text not null default 'confirmed' check (status in ('confirmed', 'pending', 'cancelled')),
  location text not null, created_at timestamptz not null default now()
);
create unique index if not exists appointments_no_double_booking
  on public.appointments (doctor_id, appointment_date, appointment_time) where status in ('confirmed', 'pending');
create index if not exists appointments_by_patient_date on public.appointments (user_id, appointment_date);
create index if not exists appointments_by_doctor_date on public.appointments (doctor_id, appointment_date) where status in ('confirmed', 'pending');
create or replace function public.create_patient_profile()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, full_name) values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', '')) on conflict (id) do nothing;
  return new;
end;
$$;
insert into public.profiles (id, full_name)
select id, coalesce(raw_user_meta_data ->> 'full_name', '') from auth.users
on conflict (id) do nothing;
drop trigger if exists on_auth_user_created_turnocero on auth.users;
create trigger on_auth_user_created_turnocero after insert on auth.users for each row execute procedure public.create_patient_profile();
create or replace function public.get_unavailable_slots(p_doctor_id text, p_date date)
returns table (appointment_time text) language sql stable security definer set search_path = '' as $$
  select a.appointment_time from public.appointments as a where a.doctor_id = p_doctor_id and a.appointment_date = p_date and a.status in ('confirmed', 'pending');
$$;
revoke all on function public.get_unavailable_slots(text, date) from public;
grant execute on function public.get_unavailable_slots(text, date) to anon, authenticated;
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin');
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;
alter table public.profiles enable row level security;
alter table public.appointments enable row level security;
drop policy if exists "Patients can read their own profile" on public.profiles;
create policy "Patients can read their own profile" on public.profiles for select to authenticated using (auth.uid() = id);
drop policy if exists "Admins can read all profiles" on public.profiles;
create policy "Admins can read all profiles" on public.profiles for select to authenticated using (public.is_admin());
drop policy if exists "Patients can update their own profile" on public.profiles;
create policy "Patients can update their own profile" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);
revoke update on public.profiles from authenticated;
grant update (full_name, phone) on public.profiles to authenticated;
drop policy if exists "Patients can read their own appointments" on public.appointments;
create policy "Patients can read their own appointments" on public.appointments for select to authenticated using (auth.uid() = user_id);
drop policy if exists "Admins can read all appointments" on public.appointments;
create policy "Admins can read all appointments" on public.appointments for select to authenticated using (public.is_admin());
drop policy if exists "Patients can book appointments for themselves" on public.appointments;
create policy "Patients can book appointments for themselves" on public.appointments for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "Patients can cancel their own appointments" on public.appointments;
create policy "Patients can cancel their own appointments" on public.appointments for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "Admins can update appointments" on public.appointments;
create policy "Admins can update appointments" on public.appointments for update to authenticated using (public.is_admin()) with check (public.is_admin());
revoke update on public.appointments from authenticated;
grant update (status) on public.appointments to authenticated;
-- Para otorgar el panel, asigna role = 'admin' a una cuenta en public.profiles.

