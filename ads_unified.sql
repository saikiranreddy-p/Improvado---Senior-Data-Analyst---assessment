WITH
fb AS (
  SELECT
    SAFE_CAST(date AS DATE) AS date,
    'Facebook' AS platform,
    CAST(campaign_id AS STRING) AS campaign_id,
    CAST(campaign_name AS STRING) AS campaign_name,
    CAST(ad_set_id AS STRING) AS ad_group_id,
    CAST(ad_set_name AS STRING) AS ad_group_name,

    SAFE_CAST(impressions AS INT64) AS impressions,
    SAFE_CAST(clicks AS INT64) AS clicks,
    SAFE_CAST(spend AS FLOAT64) AS spend,
    SAFE_CAST(conversions AS INT64) AS conversions,

    SAFE_CAST(video_views AS INT64) AS video_views,

    SAFE_CAST(engagement_rate AS FLOAT64) AS engagement_rate,
    SAFE_CAST(reach AS INT64) AS reach,
    SAFE_CAST(frequency AS FLOAT64) AS frequency,

    -- Google-only fields
    CAST(NULL AS FLOAT64) AS conversion_value,
    CAST(NULL AS FLOAT64) AS ctr_reported,
    CAST(NULL AS FLOAT64) AS avg_cpc_reported,
    CAST(NULL AS INT64)  AS quality_score,
    CAST(NULL AS FLOAT64) AS search_impression_share,

    -- TikTok-only fields
    CAST(NULL AS INT64) AS video_watch_25,
    CAST(NULL AS INT64) AS video_watch_50,
    CAST(NULL AS INT64) AS video_watch_75,
    CAST(NULL AS INT64) AS video_watch_100,
    CAST(NULL AS INT64) AS likes,
    CAST(NULL AS INT64) AS shares,
    CAST(NULL AS INT64) AS comments,
    CAST(NULL AS INT64) AS engagements
  FROM `marketing_ads.facebook_ads_raw`
),
gg AS (
  SELECT
    SAFE_CAST(date AS DATE) AS date,
    'Google' AS platform,
    CAST(campaign_id AS STRING) AS campaign_id,
    CAST(campaign_name AS STRING) AS campaign_name,
    CAST(ad_group_id AS STRING) AS ad_group_id,
    CAST(ad_group_name AS STRING) AS ad_group_name,

    SAFE_CAST(impressions AS INT64) AS impressions,
    SAFE_CAST(clicks AS INT64) AS clicks,
    SAFE_CAST(cost AS FLOAT64) AS spend,
    SAFE_CAST(conversions AS INT64) AS conversions,

    CAST(NULL AS INT64) AS video_views,

    -- Facebook-only fields
    CAST(NULL AS FLOAT64) AS engagement_rate,
    CAST(NULL AS INT64) AS reach,
    CAST(NULL AS FLOAT64) AS frequency,

    -- Google-only fields
    SAFE_CAST(conversion_value AS FLOAT64) AS conversion_value,
    SAFE_CAST(ctr AS FLOAT64) AS ctr_reported,
    SAFE_CAST(avg_cpc AS FLOAT64) AS avg_cpc_reported,
    SAFE_CAST(quality_score AS INT64) AS quality_score,
    SAFE_CAST(search_impression_share AS FLOAT64) AS search_impression_share,

    -- TikTok-only fields
    CAST(NULL AS INT64) AS video_watch_25,
    CAST(NULL AS INT64) AS video_watch_50,
    CAST(NULL AS INT64) AS video_watch_75,
    CAST(NULL AS INT64) AS video_watch_100,
    CAST(NULL AS INT64) AS likes,
    CAST(NULL AS INT64) AS shares,
    CAST(NULL AS INT64) AS comments,
    CAST(NULL AS INT64) AS engagements
  FROM `marketing_ads.google_ads_raw`
),
tt AS (
  SELECT
    SAFE_CAST(date AS DATE) AS date,
    'TikTok' AS platform,
    CAST(campaign_id AS STRING) AS campaign_id,
    CAST(campaign_name AS STRING) AS campaign_name,
    CAST(adgroup_id AS STRING) AS ad_group_id,
    CAST(adgroup_name AS STRING) AS ad_group_name,

    SAFE_CAST(impressions AS INT64) AS impressions,
    SAFE_CAST(clicks AS INT64) AS clicks,
    SAFE_CAST(cost AS FLOAT64) AS spend,
    SAFE_CAST(conversions AS INT64) AS conversions,

    SAFE_CAST(video_views AS INT64) AS video_views,

    -- Facebook-only fields
    CAST(NULL AS FLOAT64) AS engagement_rate,
    CAST(NULL AS INT64) AS reach,
    CAST(NULL AS FLOAT64) AS frequency,

    -- Google-only fields
    CAST(NULL AS FLOAT64) AS conversion_value,
    CAST(NULL AS FLOAT64) AS ctr_reported,
    CAST(NULL AS FLOAT64) AS avg_cpc_reported,
    CAST(NULL AS INT64)  AS quality_score,
    CAST(NULL AS FLOAT64) AS search_impression_share,

    -- TikTok-only fields
    SAFE_CAST(video_watch_25 AS INT64) AS video_watch_25,
    SAFE_CAST(video_watch_50 AS INT64) AS video_watch_50,
    SAFE_CAST(video_watch_75 AS INT64) AS video_watch_75,
    SAFE_CAST(video_watch_100 AS INT64) AS video_watch_100,
    SAFE_CAST(likes AS INT64) AS likes,
    SAFE_CAST(shares AS INT64) AS shares,
    SAFE_CAST(comments AS INT64) AS comments,
    (SAFE_CAST(likes AS INT64) + SAFE_CAST(shares AS INT64) + SAFE_CAST(comments AS INT64)) AS engagements
  FROM `marketing_ads.tiktok_ads_raw`
),
base AS (
  SELECT * FROM fb
  UNION ALL SELECT * FROM gg
  UNION ALL SELECT * FROM tt
)

SELECT
  *,
  -- Availability flag
  (conversion_value IS NOT NULL OR ctr_reported IS NOT NULL OR avg_cpc_reported IS NOT NULL OR quality_score IS NOT NULL OR search_impression_share IS NOT NULL) AS has_google_fields,
  (engagement_rate IS NOT NULL OR reach IS NOT NULL OR frequency IS NOT NULL) AS has_facebook_fields,
  (engagements IS NOT NULL OR video_watch_25 IS NOT NULL OR video_watch_50 IS NOT NULL OR video_watch_75 IS NOT NULL OR video_watch_100 IS NOT NULL) AS has_tiktok_fields,

  COALESCE(conversion_value, 0.0) AS conversion_value_filled,
  COALESCE(video_views, 0) AS video_views_filled,
  COALESCE(engagements, 0) AS engagements_filled,
  COALESCE(likes, 0) AS likes_filled,
  COALESCE(shares, 0) AS shares_filled,
  COALESCE(comments, 0) AS comments_filled,

  -- Cross-platform calculated metrics (from universal fields)
  SAFE_DIVIDE(clicks, NULLIF(impressions, 0)) AS ctr_calc,
  SAFE_DIVIDE(spend, NULLIF(clicks, 0)) AS cpc_calc,
  SAFE_DIVIDE(spend * 1000, NULLIF(impressions, 0)) AS cpm_calc,
  SAFE_DIVIDE(conversions, NULLIF(clicks, 0)) AS cvr_calc
FROM base