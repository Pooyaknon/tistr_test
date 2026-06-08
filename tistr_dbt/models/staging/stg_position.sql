-- stg_position.sql
with hris as (
    select * from {{ source('hris_systems', 'stg_position') }}
),

cms as ( 
    select * from {{ source('cms_systems', 'stg_position') }}
) 

select
    h.main_position_id as main_position_id,
    h.bandcode as band_code,
    h.sub_band_code as sub_band_code,
    h.position_name_th as position_name_th,
    h.position_abb_name as position_abb_name,
    h.position_name_en as position_name_en,
    h.position_type as position_type,
    cast(h.position_created_date as date) as position_created_date,
    h.main_position_id         as hris_position_id,
    c.position_id              as cms_position_id,
    cast(current_timestamp as timestamp)          as load_ts,
    'HRIS'               as source_system
from hris h
left join cms c
    on h.position_name_th = c.position_name -- ต้องตรงกันทั้งคู่ถึงจะติด