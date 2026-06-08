-- models/marts/portfolio/fact_project_expected_output.sql
{{ config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/fact_project_expected_output/',
    file_format      = 'parquet'
) }}

with src as (
    select * from {{ source('rdms_systems', 'stg_project_expected_output') }}
),

out as (
    select outcome_sk, outcome_id
    from {{ ref('fact_project_expected_outcome') }}
    where is_current = true
)

select
    {{ dbt_utils.generate_surrogate_key(['src.output_id']) }}  as output_sk,
    cast(src.output_id as int) as output_id,
    Coalesce(out.outcome_sk, 'unknown') as outcome_sk,
    src.outcome_id,
    src.product_id,
    src.product_sub_id,
    src.output_name,
    src.output_type,
    src.quantity_number,
    src.quantity_unit,
    src.description,
    src.operational_progress,
    src.actual_productivity,
    evidence,
    attachment_path,
    qualitative,
    -- SCD2 tracking
    cast(src.created_date as timestamp) as created_date,
    cast(src.updated_date as timestamp) as updated_date,

    cast(date_format(current_timestamp, '%Y%m%d%H%i%s')as varchar)       as batch_id,
    cast(current_timestamp as timestamp) as load_ts,
    'RDMS' as source_system,
    
    cast(current_timestamp as date) as load_date
from src
left join out on src.outcome_id = out.outcome_id