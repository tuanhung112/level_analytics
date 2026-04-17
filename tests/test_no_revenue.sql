
Select *
from {{ ref('stg_revenue_ads')}}  
where revenue < 0