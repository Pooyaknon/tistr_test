-- models/marts/employee/dim_supervisor.sql
{{
  config(
    materialized        = 'incremental',
    incremental_strategy= 'insert_overwrite',
    partitioned_by      = ['load_date'],
    s3_data_location    = 's3://tistr-data-lake/03-curated/dim_supervisor/',
    file_format         = 'parquet'
  )
}}

with src as (
    select * from {{ ref('stg_supervisor') }}
),

-- lookup employee_sk สำหรับตัวพนักงานเอง
emp as (
    select employee_sk, employee_id
    from {{ ref('dim_employee') }}
    where is_current = true
),

-- lookup org_unit_sk จาก org code ที่มี
org as (
    select
        org_unit_sk,
        src_org_code,
        org_unit_type
    from {{ ref('dim_org_unit') }}
    where is_current = true
),

-- lookup employee_sk สำหรับ director แต่ละ level
-- ใช้ emp table เดียวกัน join 4 รอบ
final as (
    select
        -- surrogate key
        {{ dbt_utils.generate_surrogate_key([
            'src.employee_id',
            'src.director_id_level1'
        ]) }}                               as supervisor_sk,

        src.supervisor_id,

        -- employee
        emp.employee_sk,
        src.employee_id,
        src.employee_level,

        -- org unit: ลำดับความสำคัญ division > office > business_group
        coalesce(
            org_div.org_unit_sk,
            org_off.org_unit_sk,
            org_bg.org_unit_sk
        )                                   as org_unit_sk,

        -- director level 1
        d1.employee_sk                      as director_sk_level1,
        src.director_id_level1,

        -- director level 2
        d2.employee_sk                      as director_sk_level2,
        src.director_id_level2,

        -- director level 3
        d3.employee_sk                      as director_sk_level3,
        src.director_id_level3,

        -- director level 4
        d4.employee_sk                      as director_sk_level4,
        src.director_id_level4,

        -- SCD2
        cast(
            date(src.updated_date)
        as date)                            as valid_from,
        date('9999-12-31')                  as valid_to,
        true                                as is_current,
        src.updated_date,

        -- metadata
        cast(
            date_format(current_timestamp, '%Y%m%d%H%i%s')
        as varchar)                         as batch_id,
        cast(current_timestamp as timestamp) as load_ts,
        'HRIS'                              as source_system,
        cast(current_timestamp as date) as load_date

    from src

    -- join ตัวพนักงานเอง
    left join emp
        on src.employee_id = emp.employee_id

    -- join org unit 3 ระดับ แล้วใช้ coalesce
    left join org as org_div
        on src.division_code = org_div.src_org_code
        and org_div.org_unit_type = 'division'

    left join org as org_off
        on src.office_code = org_off.src_org_code
        and org_off.org_unit_type = 'office'

    left join org as org_bg
        on src.business_group_code = org_bg.src_org_code
        and org_bg.org_unit_type = 'business_group'

    -- join director level 1-4 แยกกัน
    left join emp as d1
        on src.director_id_level1 = d1.employee_id
    left join emp as d2
        on src.director_id_level2 = d2.employee_id
    left join emp as d3
        on src.director_id_level3 = d3.employee_id
    left join emp as d4
        on src.director_id_level4 = d4.employee_id
)

select * from final

{% if is_incremental() %}
where updated_date >= (
    select max(updated_date) from {{ this }}
)
{% endif %}