{{
    config(
        materialized='incremental',
        unique_key='user_pseudo_id', 
        partition_by={
            "field": "event_date",
            "data_type": "date",
            "granularity": "day"
        },
        cluster_by=["platform", "level_number"]
    )
}}

with raw_level_starts as (
    -- 1. Pull data from the source we defined in our YAML
    select * from {{ source('level_monitization_raw', 'level_end') }}

    {% if is_incremental() %}
        -- 2. The Incremental Filter
        -- This ensures we only scan new data in BigQuery, saving money.
        -- '{{ this }}' refers to this very table (stg_level_ends)
        where event_date >= (select max(event_date) from {{ this }})
    {% endif %}
)

select
    user_pseudo_id as player_id,
    platform,
    country,
    version as game_version,
 
    -- Ensuring data types are correct for BigQuery
    cast(event_date as date) as event_date,
    cast(install_date as date) as install_date,
    AB_test ,
    level as level_number,
    level_type,
    rday as retention_day

from raw_level_starts
