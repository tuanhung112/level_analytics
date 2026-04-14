{{ config(materialized='table') }}

with starts as (
    select 
        level_number, 
        count(distinct player_id) as started_users
    from {{ ref('stg_level_starts') }}
    group by 1
),

wins as (
    select 
        level_number, 
        count(distinct player_id) as completed_users
    from {{ ref('stg_level_ends') }}
    group by 1
),

ads as (
    select 
        level_number, 
        sum(revenue) as total_revenue
    from {{ ref('stg_revenue_ads') }}
    group by 1
)

select
    s.level_number,
    s.started_users,
    coalesce(w.completed_users, 0) as completed_users,
    coalesce(a.total_revenue, 0) as revenue
from starts s
left join wins w on s.level_number = w.level_number
left join ads a on s.level_number = a.level_number