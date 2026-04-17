select
    e.player_id,
    e.level_number
from {{ ref('stg_level_ends') }} e
left join {{ ref('stg_level_starts') }} s 
    on e.player_id = s.player_id and e.level_number = s.level_number
where s.player_id is null