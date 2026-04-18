{{ config(materialized='table') }}

with raw_starts as (
    select 
        level_number, 
        player_id
    from {{ ref('stg_level_starts') }}
    -- It is good practice to deduplicate here if a player can start the same level twice
    group by 1, 2
),

raw_wins as (
    select 
        level_number, 
        player_id
    from {{ ref('stg_level_ends') }}
    group by 1, 2
),

-- Here is the fix: We join at the player level BEFORE counting.
-- This ensures 'completed_users' is a subset of 'started_users'.
joined_player_progress as (
    select
        s.level_number,
        s.player_id,
        case when w.player_id is not null then 1 else 0 end as has_completed
    from raw_starts s
    left join raw_wins w 
        on s.level_number = w.level_number 
        and s.player_id = w.player_id
),

agg_metrics as (
    select
        level_number,
        count(distinct player_id) as started_users,
        sum(has_completed) as completed_users
    from joined_player_progress
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
    a.level_number,
    a.started_users,
    a.completed_users,
    coalesce(ads.total_revenue, 0) as revenue
from agg_metrics a
left join ads on a.level_number = ads.level_number