-- COMPTA TSNT — Exécuter une seule fois dans Supabase > SQL Editor.
create extension if not exists pgcrypto;
create table if not exists public.records (
 id uuid primary key default gen_random_uuid(),
 category text not null check(category in ('stock','transaction','order','ticket','card','activity')),
 data jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 created_by uuid references auth.users(id) default auth.uid()
);
create index if not exists records_category_idx on public.records(category);
alter table public.records enable row level security;
drop policy if exists "members read" on public.records;
create policy "members read" on public.records for select to authenticated using(true);
drop policy if exists "members insert" on public.records;
create policy "members insert" on public.records for insert to authenticated with check(true);
drop policy if exists "members update" on public.records;
create policy "members update" on public.records for update to authenticated using(true) with check(true);
drop policy if exists "members delete" on public.records;
create policy "members delete" on public.records for delete to authenticated using(true);

create or replace function public.tsnt_checkout(p_account text,p_items jsonb)
returns uuid language plpgsql security invoker set search_path=public as $$
declare
 v_order_id uuid:=gen_random_uuid(); v_item jsonb; v_row public.records%rowtype;
 v_qty numeric; v_need numeric; v_total numeric:=0; v_lines jsonb:='[]'::jsonb;
 v_name text; v_price numeric; v_units numeric;
begin
 if p_account not in ('caisse','banque') then raise exception 'Compte invalide'; end if;
 if jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items)=0 then raise exception 'Commande vide'; end if;
 for v_item in select * from jsonb_array_elements(p_items) loop
  select * into v_row from public.records where id=(v_item->>'id')::uuid and category='stock' for update;
  if not found then raise exception 'Produit introuvable'; end if;
  v_qty:=greatest(0,(v_item->>'qty')::numeric); v_units:=coalesce((v_row.data->>'venteUnites')::numeric,1); v_need:=v_qty*v_units;
  if v_qty<=0 or coalesce((v_row.data->>'quantite')::numeric,0)<v_need then raise exception 'Stock insuffisant pour %',v_row.data->>'nom'; end if;
  v_name:=v_row.data->>'nom'; v_price:=coalesce((v_row.data->>'ventePrix')::numeric,0); v_total:=v_total+v_price*v_qty;
  v_lines:=v_lines||jsonb_build_array(jsonb_build_object('id',v_row.id,'name',v_name,'qty',v_qty,'stockUnits',v_need,'unitPrice',v_price));
  update public.records set data=jsonb_set(v_row.data,'{quantite}',to_jsonb((v_row.data->>'quantite')::numeric-v_need)),updated_at=now() where id=v_row.id;
 end loop;
 insert into public.records(id,category,data,created_by) values(v_order_id,'order',jsonb_build_object('date',now(),'payment',p_account,'total',v_total,'items',v_lines,'cancelled',false),auth.uid());
 insert into public.records(category,data,created_by) values('transaction',jsonb_build_object('label','Vente buvette','amount',v_total,'account',p_account,'kind','recette','date',now(),'orderId',v_order_id),auth.uid());
 return v_order_id;
end $$;

create or replace function public.tsnt_cancel_order(p_order_id uuid)
returns void language plpgsql security invoker set search_path=public as $$
declare v_order public.records%rowtype; v_item jsonb; v_stock public.records%rowtype; v_data jsonb;
begin
 select * into v_order from public.records where id=p_order_id and category='order' for update;
 if not found then raise exception 'Commande introuvable'; end if;
 if coalesce((v_order.data->>'cancelled')::boolean,false) then raise exception 'Commande déjà annulée'; end if;
 v_data:=v_order.data;
 for v_item in select * from jsonb_array_elements(v_data->'items') loop
  select * into v_stock from public.records where id=(v_item->>'id')::uuid and category='stock' for update;
  if found then update public.records set data=jsonb_set(v_stock.data,'{quantite}',to_jsonb(coalesce((v_stock.data->>'quantite')::numeric,0)+coalesce((v_item->>'stockUnits')::numeric,0))),updated_at=now() where id=v_stock.id; end if;
 end loop;
 update public.records set data=jsonb_set(v_data,'{cancelled}','true'::jsonb),updated_at=now() where id=p_order_id;
 insert into public.records(category,data,created_by) values('transaction',jsonb_build_object('label','Annulation vente buvette','amount',-coalesce((v_data->>'total')::numeric,0),'account',v_data->>'payment','kind','annulation','date',now(),'orderId',p_order_id),auth.uid());
end $$;
grant execute on function public.tsnt_checkout(text,jsonb) to authenticated;
grant execute on function public.tsnt_cancel_order(uuid) to authenticated;