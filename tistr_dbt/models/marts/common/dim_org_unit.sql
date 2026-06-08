{{
  config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/common/dim_org_unit/',
    file_format      = 'parquet'
  )
}}

-- 1. ดึงข้อมูลจาก Staging มาพักไว้
with src as (
    select * from {{ ref('stg_org_unit') }}
),

-- 2. เตรียม Surrogate Key สำหรับ Business Group
bg as (
    select distinct 
        {{ dbt_utils.generate_surrogate_key(['business_group_code']) }} as business_group_sk,
        business_group_code
    from {{ source('hris_systems', 'stg_business_group') }}
),
-- 3. เตรียม Surrogate Key สำหรับ Office
office as (
    select distinct 
        {{ dbt_utils.generate_surrogate_key(['office_code']) }} as office_sk,
        office_code
    from {{ source('hris_systems', 'stg_expert_center_office') }}
),

-- 4. เตรียม Surrogate Key สำหรับ Division
division as (
    select distinct  
        {{ dbt_utils.generate_surrogate_key(['division_code']) }} as division_sk,
        division_code
    from {{ source('hris_systems', 'stg_division') }}
),

-- 5. ประกอบร่างข้อมูลเข้าด้วยกัน
final_data as (
    select
        {{ dbt_utils.generate_surrogate_key(['s.org_unit_type', 's.src_org_code', 's.division_code', 's.office_code']) }} as org_unit_sk,
        s.org_unit_type,
        s.src_org_code,
        b.business_group_sk,
        s.business_group_code,
        o.office_sk,
        s.office_code,
        d.division_sk,
        s.division_code,
        cast(null as varchar) as cluster_sk,
        cast(null as varchar) as cluster_code,
        s.status,
        s.valid_from,
        s.valid_to,
        case
            when s.valid_to is null or s.valid_to = date('9999-12-31') then true
            else false
        end as is_current,
        cast(date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar) as batch_id,
        
        -- แก้ไขแล้ว: แปลงให้เป็น timestamp ธรรมดา (ไม่มี time zone)
        cast(current_timestamp as timestamp) as load_ts, 
        
        s.source_system,
        
        -- แก้ไขแล้ว: load_date อยู่บรรทัดสุดท้ายถูกต้องตามกฎของ Athena
        cast(current_timestamp as date) as load_date 
    from src s
    left join bg b       on s.business_group_code = b.business_group_code
    left join office o   on s.office_code = o.office_code
    left join division d on s.division_code = d.division_code
)

-- 6. Select ผลลัพธ์สุดท้าย
select * from final_data

{% if is_incremental() %}
where src_org_code not in (
    select src_org_code from {{ this }}
    where is_current = true
)
{% endif %}