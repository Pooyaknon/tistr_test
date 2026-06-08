-- models/marts/portfolio/fact_project_budget_item.sql
{{ config(
    materialized     = 'table',
    partitioned_by   = ['load_date'],
    s3_data_location = 's3://tistr-data-lake/03-curated/fact_project_budget_item/',
    file_format      = 'parquet'
) }}
with src as (
    select * from {{ source('rdms_systems', 'stg_project_budget_item') }}
)

select
    itemid as item_id,
    project_id,
    subcategoryid as sub_category_id,
    name as item_name,
    price as unit_price,
    amount as quantity,
    unit as unit_name,
    person as person_count,
    frequency as purchase_frequency,
    cast(date_format(current_timestamp, '%Y%m%d%H%i%s') as varchar)  as batch_id,
    cast(current_timestamp as timestamp) as load_ts,
    'RDMS' as source_system,
    
    cast(current_timestamp as date) as load_date
from src