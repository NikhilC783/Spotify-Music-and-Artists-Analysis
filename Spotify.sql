use Spotify_youtube;

select *from Spotify;


-- 1. Data Understanding & Cleaning

-- Total tracks, artists, genres
SELECT 
    COUNT(*) AS total_tracks,
    COUNT(DISTINCT Artist) AS total_artists,
    COUNT(DISTINCT Album_type) AS total_genres
FROM spotify;


-- Duplicate tracks
SELECT Track, Artist, COUNT(*) AS duplicate_count
FROM spotify
GROUP BY Track, Artist
HAVING COUNT(*) > 1;


-- Tracks with missing audio features
SELECT *
FROM spotify
WHERE Danceability IS NULL
   OR Energy IS NULL
   OR Tempo IS NULL;


-- Tracks shorter than 60s or longer than 15 min
SELECT *
FROM spotify
WHERE Duration_ms < 60000
   OR Duration_ms > 900000;


--2. Descriptive Analysis

-- Popularity statistics
SELECT 
    AVG(Stream) AS avg_popularity,
    MIN(Stream) AS min_popularity,
    MAX(Stream) AS max_popularity
FROM spotify;


-- Number of tracks per artist
SELECT Artist, COUNT(*) AS total_tracks
FROM spotify
GROUP BY Artist
ORDER BY total_tracks DESC;


-- Average duration by genre
SELECT Album_type,
       AVG(Duration_ms / 1000) AS avg_duration_seconds
FROM spotify
GROUP BY Album_type;


-- Percentage of explicit tracks (NOT AVAILABLE)
-- Column not present in dataset


--3. Popularity Analysis

-- Top 10 most popular tracks
SELECT Track, Artist, Stream
FROM spotify
ORDER BY Stream DESC
OFFSET 0 ROWS
FETCH NEXT 10 ROWS ONLY;

-- Artists with highest average popularity
SELECT Artist, AVG(Stream) AS avg_popularity
FROM spotify
GROUP BY Artist
ORDER BY avg_popularity DESC;

-- Tracks with popularity greater than 80th percentile
SELECT COUNT(*) AS highly_popular_tracks
FROM (
    SELECT Stream,
           PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY Stream) OVER () AS percentile_80
    FROM spotify
) AS t
WHERE Stream > percentile_80;

-- Least popular genres
SELECT Album_type, AVG(Stream) AS avg_popularity
FROM spotify
GROUP BY Album_type
ORDER BY avg_popularity ASC;

-- 5. Artist Performance Analysis

-- Artists with most tracks
SELECT Artist, COUNT(*) AS total_tracks
FROM spotify
GROUP BY Artist
ORDER BY total_tracks DESC;


-- Artists with above-average popularity
SELECT Artist, AVG(Stream) AS avg_popularity
FROM spotify
GROUP BY Artist
HAVING AVG(Stream) > (SELECT AVG(Stream) FROM spotify);

-- One-hit wonder artists (only one hit track)
SELECT Artist
FROM spotify
WHERE Stream > 70000000
GROUP BY Artist
HAVING COUNT(*) = 1;


-- Popularity improvement over time (NOT POSSIBLE)
-- No release date/year available


-- 6. Audio Feature Analysis

-- Average audio features
SELECT 
    AVG(Danceability) AS avg_danceability,
    AVG(Energy) AS avg_energy,
    AVG(Tempo) AS avg_tempo
FROM spotify


-- High vs Low popularity comparison
SELECT 
    popularity_group,
    AVG(Danceability) AS avg_danceability,
    AVG(Energy) AS avg_energy,
    AVG(Tempo) AS avg_tempo
FROM (
    SELECT *,
        CASE 
            WHEN Stream >= (SELECT AVG(Stream) FROM spotify)
            THEN 'High Popularity'
            ELSE 'Low Popularity'
        END AS popularity_group
    FROM spotify
) AS sub
GROUP BY popularity_group;


-- Genres with highest energy
SELECT Album_type, AVG(Energy) AS avg_energy
FROM spotify
GROUP BY Album_type
ORDER BY avg_energy DESC;


-- Tracks with unusually high tempo
SELECT *
FROM spotify
WHERE Tempo > 
      (SELECT AVG(Tempo) + 2 * STDEV(Tempo)
       FROM spotify);


--7. Segmentation Using CASE

-- Popularity segments
SELECT 
    popularity_group,
    COUNT(*) AS track_count
FROM (
    SELECT *,
        CASE
            WHEN Stream < 20000000 THEN 'Low'
            WHEN Stream BETWEEN 20000000 AND 70000000 THEN 'Medium'
            ELSE 'High'
        END AS popularity_group
    FROM spotify
) AS sub
GROUP BY popularity_group;


-- Artist segmentation by track count
SELECT Artist,
       COUNT(*) AS track_count,
       CASE
           WHEN COUNT(*) < 5 THEN 'Low Output'
           WHEN COUNT(*) BETWEEN 5 AND 20 THEN 'Medium Output'
           ELSE 'High Output'
       END AS artist_segment
FROM spotify
GROUP BY Artist;


-- 8. Ranking & Window Functions

-- Rank tracks by popularity within genre
SELECT *,
       RANK() OVER (PARTITION BY Album_type ORDER BY Stream DESC) AS genre_rank
FROM spotify;


---- Top 3 tracks per artist
SELECT *
FROM (
    SELECT *,
           RANK() OVER (PARTITION BY Artist ORDER BY Stream DESC) AS rnk
    FROM spotify
) t
WHERE rnk <= 3;


-- Rank artists by average popularity
SELECT Artist,
       AVG(Stream) AS avg_popularity,
       RANK() OVER (ORDER BY AVG(Stream) DESC) AS artist_rank
FROM spotify
GROUP BY Artist;


--9. Advanced SQL Analysis

-- Contribution of top 10% tracks
SELECT 
    SUM(Stream) * 100.0 / (SELECT SUM(Stream) FROM spotify) AS top_10_percent_contribution
FROM (
    SELECT TOP 10 PERCENT Stream
    FROM spotify
    ORDER BY Stream DESC
) AS t;


-- Tracks outperforming genre average
SELECT s.*
FROM spotify s
JOIN (
    SELECT Album_type, AVG(Stream) AS avg_stream
    FROM spotify
    GROUP BY Album_type
) g
ON s.Album_type = g.Album_type
WHERE s.Stream > g.avg_stream;


-- 10. Business Metrics

---- Hit rate
SELECT 
    COUNT(CASE WHEN Stream > 70000000 THEN 1 END) * 100.0 / COUNT(*) AS hit_rate
FROM spotify;

-- Artist success rate
SELECT Artist,
       COUNT(CASE WHEN Stream > 70000000 THEN 1 END) * 1.0 / COUNT(*) AS success_rate
FROM spotify
GROUP BY Artist;

-- Top genres contributing to popularity
SELECT Album_type,
       SUM(Stream) AS total_popularity
FROM spotify
GROUP BY Album_type
ORDER BY total_popularity DESC;


















