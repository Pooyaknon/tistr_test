-- stg_employee_education.sql

with hris as (
    select * from {{ source('hris_systems', 'stg_employee_education') }}
)

select
    education_id,
    employee_id,
    education_level_id,
    graduated_date,
    degree_id,
    institute_id,
    faculty_name,
    major_name,
    eduminor as minor_name,
    gpa,
    campus_name,
    edudetail as education_detail,
    recruitment as recruitment_path,
    admin_emp_id,
    created_date,
    updated_date,
    education_status,
    
    cast(current_timestamp as timestamp) as load_ts,
    'HRIS' as source_system
from hris