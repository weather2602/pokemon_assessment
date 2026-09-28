-- Sanity check: The total_stats column must equal the sum of the 6 individual stat columns.
-- This acts exactly like a Dataform "type: assertion" block. If it returns 0 rows, the test passes.
-- This assertion is completely null-safe; any missing components will be caught and reported as failures.

select
    pokemon_id,
    pokemon_name,
    total_stats,
    (hp + attack + defense + special_attack + special_defense + speed) as calculated_total
from {{ ref('stg_pokemon_unified') }}
where
    total_stats is null
    or hp is null
    or attack is null
    or defense is null
    or special_attack is null
    or special_defense is null
    or speed is null
    or total_stats != (hp + attack + defense + special_attack + special_defense + speed)
