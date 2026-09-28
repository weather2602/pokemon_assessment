with unioned as (
    select * from {{ ref('stg_pokemon_a') }}
    union all
    select * from {{ ref('stg_pokemon_b') }}
),

ranked as (
    select
        pokemon_id,
        pokemon_name,
        primary_type,
        secondary_type,
        total_stats,
        hp,
        attack,
        defense,
        special_attack,
        special_defense,
        speed,
        generation,
        is_legendary,
        source_file,
        ingested_at,
        -- No source authority hierarchy was specified in the exercise instructions.
        -- Our EDA profiling verified that overlapping records are mathematically identical.
        -- Therefore, this precedence mapping acts only as a deterministic fallback for reproducibility.
        -- We order by CASE first and then secondary-order by source_file to guarantee absolute determinism.
        row_number() over (
            partition by pokemon_name
            order by
                case
                    when source_file = 'source_b' then 1
                    when source_file = 'source_a' then 2
                    else 99
                end,
                source_file
        ) as row_num
    from unioned
)

select
    pokemon_id,
    pokemon_name,
    primary_type,
    secondary_type,
    total_stats,
    hp,
    attack,
    defense,
    special_attack,
    special_defense,
    speed,
    generation,
    is_legendary,
    source_file,
    -- ingested_at
from ranked
where row_num = 1
order by pokemon_name
