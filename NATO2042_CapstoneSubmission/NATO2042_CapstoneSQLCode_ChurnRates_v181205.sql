-- STEP01: Data investigation 1 (Segments = 2 (30, 87) | Records: 2000)

SELECT *
FROM subscriptions
LIMIT 100;

SELECT COUNT(*)
FROM subscriptions;

SELECT DISTINCT segment
FROM subscriptions;

--STEP02: Data investigation 2 (Month start: Dec-2016 | Month End: Mar-2017)

SELECT MIN(subscription_start),  MAX(subscription_start)
FROM subscriptions;

SELECT  MIN(subscription_end), MAX(subscription_start)
FROM subscriptions;

-- STEP03: Temp table 1 (manual created data ranges)

WITH months AS 
	(SELECT 
    '2017-01-01' AS first_day,
    '2017-01-31' AS last_day
  	UNION
    SELECT
    '2017-02-01' AS first_day,
    '2017-02-28' AS last_day
   	UNION
    SELECT
    '2017-03-01' AS first_day,
    '2017-03-30' AS last_day),
/*
SELECT *
FROM months;
*/

-- STEP04: Temp table 2 (CROSS JOIN merge subscriptions | months)

cross_join AS
	(
    SELECT * 
    FROM subscriptions
    CROSS JOIN months
    ), 
/*
SELECT *
FROM cross_join
LIMIT 10;
*/

--STEP05: Temp table 3A (show active months)

status AS 
	(SELECT id,
  		    first_day AS month,
   
        CASE
          	WHEN segment = 30
            AND (subscription_start < first_day)
            AND ((subscription_end > first_day)
          	OR (subscription_end IS NULL))
            THEN 1
            ELSE 0
		END AS is_active_30,

   		CASE
          	WHEN segment = 87
            AND (subscription_start < first_day)
            AND ((subscription_end > first_day)
          	OR (subscription_end IS NULL))
            THEN 1
            ELSE 0
		END AS is_active_87,
   
--STEP06: Temp table 3B (show cancelled months)

   		CASE
          	WHEN segment = 30
            AND (subscription_end 
            BETWEEN first_day 
            AND last_day)
            THEN 1
            ELSE 0
		END AS is_cancelled_30,

   		CASE
          	WHEN segment = 87
            AND (subscription_end 
            BETWEEN first_day 
            AND last_day)
            THEN 1
            ELSE 0
		END AS is_cancelled_87
  
	FROM cross_join),
/*  
SELECT *
FROM status 
LIMIT 50;
*/
  
--STEP07: Temp table 4 (aggregates - summing segements groups by active and cancelled)

status_aggregate AS 
  	(SELECT month,
    		SUM(is_active_30) AS sum_active_30,
        	SUM(is_active_87) AS sum_active_87,
            SUM(is_cancelled_30) AS sum_cancelled_30,
            SUM(is_cancelled_87) AS sum_cancelled_87
     FROM status
     GROUP BY month)
/*
SELECT *
FROM  status_aggregate;
*/

--STEP08: FINAL CHURN RATE (calculating churn - segment 30 has the lower churn rate @ 11.3% for 3 cumulative months, whereas segment 87 is at 46.5% over the same period)

SELECT month, 
       1.0 * sum_cancelled_30 / sum_active_30 AS seg30_churn_rate,
       1.0 * sum_cancelled_87 / sum_active_87 AS seg87_churn_rate
FROM status_aggregate;

--STEP09: Don't hardcode segments e.g. 30 & 87 as per steps 5 and 6, we could have just specified active and cancelled in the CASE-END AS and added 'segment' column to the SELECT. Then in Step 7 condensed the aggregrate functions added 'segment' to the GROUP BY. As per below. 
/*
status AS 
	(SELECT id, 
   				segment,
  				first_day AS month,
   
          CASE
            WHEN (subscription_start < first_day)
            AND ((subscription_end > first_day)
          	OR (subscription_end IS NULL))
            THEN 1
            ELSE 0
					END AS is_active,
   
   				CASE
            WHEN subscription_end 
            BETWEEN first_day 
            AND last_day
            THEN 1
            ELSE 0
					END AS is_cancelled
	FROM cross_join),
  
--SELECT *
--FROM status 
--LIMIT 50;

status_aggregate AS 
  	(SELECT month, segment,
    				SUM(is_active) AS sum_active,
            SUM(is_cancelled) AS sum_cancelled
     FROM status
     GROUP BY month, segment)

--SELECT *
--FROM  status_aggregate;

SELECT month, segment,
       1.0 * sum_cancelled / sum_active AS churn_rate
FROM status_aggregate;
*/