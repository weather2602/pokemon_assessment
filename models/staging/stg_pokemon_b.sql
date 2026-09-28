with raw_source as (
    select * from {{ source('raw_sources', 'pokemon_source_b') }}
),

staged as (
    select
        cast(pokemonId as integer) as pokemon_id,
        cast(trim(pokemonName) as varchar) as pokemon_name,
        cast(lower(trim(primaryType)) as varchar) as primary_type,
        cast(lower(trim(secondaryType)) as varchar) as secondary_type,
        cast(totalStats as integer) as total_stats,
        cast(hp as integer) as hp,
        cast(attack as integer) as attack,
        cast(defense as integer) as defense,
        cast(specialAttack as integer) as special_attack,
        cast(specialDefense as integer) as special_defense,
        cast(speed as integer) as speed,
        cast(generation as integer) as generation,
        cast(isLegendary as boolean) as is_legendary, -- Cast directly to propagate potential NULLs
        'source_b' as source_file,
        cast(current_timestamp as timestamp) as ingested_at
    from raw_source
)

-- Note: Source B is verified to contain exact byte-for-byte duplicate payloads for:
--   - 'PumpkabooSmall Size' (appears 2x)
--   - 'PumpkabooLarge Size' (appears 2x)
-- We use DISTINCT to remove physical row duplication at the staging boundary before key-based reconciliation.
select distinct * from staged
