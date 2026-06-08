-- models/staging/stg_supervisor.sql
select
    supervisor_sk as supervisor_id,
    employee_id,
    employee_level,
    business_group_code,
    office_code,
    division_code,
    directorl1                          as director_id_level1,
    directorl2                          as director_id_level2,
    directorl3                          as director_id_level3,
    directorl4                          as director_id_level4,
    updated_data                        as updated_date,
    year,
    month,
    day
from {{ source('hris_systems', 'stg_supervisor') }}