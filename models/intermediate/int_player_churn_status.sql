{{ config(materialized='table') }}

with player_activity as (
    select 
        player_id,
        max(level_number) as furthest_level,
        max(event_date) as last_active_date
    from {{ ref('stg_level_starts') }}
    group by 1
),

dataset_metadata as (
    -- We find the 'current' date of the data to calculate 2-day inactivity
    select max(event_date) as max_date from {{ ref('stg_level_starts') }}
)

select 
    pa.player_id,
    pa.furthest_level,
    -- Logic: If they haven't played in 2+ days relative to the latest data, they are 'dropped'
    case 
        when date_diff(dm.max_date, pa.last_active_date, day) >= 2 then 1 
        else 0 
    end as is_dropped
from player_activity pa
cross join dataset_metadata dm