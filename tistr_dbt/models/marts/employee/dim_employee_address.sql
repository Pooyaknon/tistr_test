{{ config(
    materialized     = 'table',
    file_format      = 'parquet'
) }}

WITH src as (
    SELECT * FROM {{ source('hris_systems', 'stg_employee_address') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['emp_address_id']) }} as employee_address_sk,
    
    emp_address_id,
    employee_id,
    address_type,
    house_no,
    village,
    street,
    subdistrict,
    district,
    province,
    zipcode,
    mobile_contact,
    home_phone,
    address_status,

    CAST(DATE_FORMAT(CURRENT_TIMESTAMP, '%Y%m%d%H%i%s') as VARCHAR) as batch_id,
    CAST(CURRENT_TIMESTAMP as TIMESTAMP) as load_ts,
    'HRIS' as source_system
FROM src