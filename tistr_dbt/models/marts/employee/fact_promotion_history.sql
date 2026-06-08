{{ config(
    materialized     = 'table',
    file_format      = 'parquet'
) }}

WITH src as (
    SELECT * FROM {{ source('hris_systems', 'stg_promotion_history') }}
)

SELECT
    -- สร้าง Surrogate Key
    {{ dbt_utils.generate_surrogate_key(['promotion_id']) }} as promotion_sk,
    
    promotion_id,
    employee_id,
    CAST(start_date as DATE) as start_date,
    CAST(end_date as DATE) as end_date,
    promotion_description, 
    remarks,
    promotion_status,

    CAST(DATE_FORMAT(CURRENT_TIMESTAMP, '%Y%m%d%H%i%s') as VARCHAR) as batch_id,
    CAST(CURRENT_TIMESTAMP as TIMESTAMP) as load_ts,
    'HRIS' as source_system
FROM src