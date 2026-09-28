with raw_source as (
    select * from {{ source('raw_sources', 'pokemon_source_a') }}
),

staged as (
    select
        cast(id as integer) as pokemon_id,
        cast(trim(name) as varchar) as pokemon_name,
        cast(lower(trim(type_1)) as varchar) as primary_type,
        cast(lower(trim(type_2)) as varchar) as secondary_type,
        cast(total as integer) as total_stats,
        cast(hp as integer) as hp,
        cast(attack as integer) as attack,
        cast(defense as integer) as defense,
        cast(sp_atk as integer) as special_attack,
        cast(sp_def as integer) as special_defense,
        cast(speed as integer) as speed,
        cast(generation as integer) as generation,
        case
            when lower(trim(legendary)) = 'true' then true
            when lower(trim(legendary)) = 'false' then false
            else null -- Unexpected strings resolve to NULL to trigger schema data quality tests
        end as is_legendary,
        'source_a' as source_file,
        cast(current_timestamp as timestamp) as ingested_at
    from raw_source
)

-- Note: Source A contains 0 exact duplicate row payloads.
-- We select DISTINCT as a standardized defensive boundary for both feeds.
select distinct * from staged
