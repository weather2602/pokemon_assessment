-- Sanity check: Overlapping records in staging A and B must agree on all attributes.
-- This assertion uses DuckDB's null-safe "IS DISTINCT FROM" comparison operator.
-- This ensures that any discrepancies (including NULLs vs values) are flagged as a failure rather than silently bypassed.

with sub_a as (
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
        is_legendary
    from {{ ref('stg_pokemon_a') }}
),

sub_b as (
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
        is_legendary
    from {{ ref('stg_pokemon_b') }}
)

select
    a.pokemon_name,

    -- Source A values
    a.pokemon_id as id_a,
    a.primary_type as primary_type_a,
    a.secondary_type as secondary_type_a,
    a.total_stats as total_stats_a,
    a.hp as hp_a,
    a.attack as attack_a,
    a.defense as defense_a,
    a.special_attack as special_attack_a,
    a.special_defense as special_defense_a,
    a.speed as speed_a,
    a.generation as generation_a,
    a.is_legendary as is_legendary_a,

    -- Source B values
    b.pokemon_id as id_b,
    b.primary_type as primary_type_b,
    b.secondary_type as secondary_type_b,
    b.total_stats as total_stats_b,
    b.hp as hp_b,
    b.attack as attack_b,
    b.defense as defense_b,
    b.special_attack as special_attack_b,
    b.special_defense as special_defense_b,
    b.speed as speed_b,
    b.generation as generation_b,
    b.is_legendary as is_legendary_b

from sub_a a
inner join sub_b b on a.pokemon_name = b.pokemon_name
where a.pokemon_id is distinct from b.pokemon_id
   or a.primary_type is distinct from b.primary_type
   or a.secondary_type is distinct from b.secondary_type
   or a.total_stats is distinct from b.total_stats
   or a.hp is distinct from b.hp
   or a.attack is distinct from b.attack
   or a.defense is distinct from b.defense
   or a.special_attack is distinct from b.special_attack
   or a.special_defense is distinct from b.special_defense
   or a.speed is distinct from b.speed
   or a.generation is distinct from b.generation
   or a.is_legendary is distinct from b.is_legendary
