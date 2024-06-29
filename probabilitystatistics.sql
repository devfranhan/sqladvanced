-- Drop the temporary table if it exists
IF OBJECT_ID('tempdb..#Analytics_AR') IS NOT NULL
    BEGIN DROP TABLE #Analytics_AR END

-- Select and transform data into the temporary table
SELECT *, NULL AS repurchase_time, CAST('' AS varchar(50)) AS age_group,
       CAST(0 AS float) AS onix, CAST(0 AS float) AS tracker, CAST(0 AS float) AS s10, CAST(0 AS FLOAT) AS cruze,
       CAST('' AS varchar(100)) AS most_probable_vehicle,
       CAST(0 AS float) AS probability,
       CAST('' AS varchar(100)) AS probability_range,
       CASE 
           WHEN score <= 200 THEN 'Potential'
           WHEN score BETWEEN 201 AND 350 THEN 'Loyal'
           WHEN score >= 351 THEN 'Brand Lover'
       END AS customer_classification_rfv,
       CAST(0 AS float) AS avg_repurchase_prob,
       CAST(0 AS float) AS avg_repurchase_time,
       CAST(0 AS float) AS avg_repurchase_time_prob
INTO #Analytics_AR
FROM DataLake
WHERE 1=1
AND market LIKE '%ARG%'

-- Drop the temporary table if it exists
IF OBJECT_ID('tempdb..#Analytics_AverageAge') IS NOT NULL
    BEGIN DROP TABLE #Analytics_AverageAge END

-- Calculate average age grouped by gender and region
SELECT client_gender, region, AVG(client_age) AS average_age
INTO #Analytics_AverageAge
FROM #Analytics_AR
WHERE client_age IS NOT NULL
AND client_age BETWEEN 18 AND 70
GROUP BY client_gender, region

-- Update client age to NULL if it's not between 18 and 70
UPDATE A
SET A.client_age = NULL
FROM #Analytics_AR A
WHERE A.client_age NOT BETWEEN 18 AND 70

-- Update client age with the average age calculated
UPDATE A
SET A.client_age = B.average_age
FROM #Analytics_AR A
INNER JOIN #Analytics_AverageAge B ON A.client_gender = B.client_gender AND A.region = B.region
AND ISNULL(A.client_age, '') = ''

-- Calculate repurchase time in months
UPDATE A
SET A.repurchase_time = DATEDIFF(MONTH, previous_vehicle_purchase_date, current_vehicle_purchase_date)
FROM #Analytics_AR A

-- Update age group
UPDATE A
SET age_group = CASE
                    WHEN client_age BETWEEN 18 AND 34 THEN '18 to 34'
                    WHEN client_age BETWEEN 35 AND 40 THEN '35 to 40'
                    WHEN client_age BETWEEN 41 AND 45 THEN '41 to 45'
                    WHEN client_age BETWEEN 46 AND 58 THEN '46 to 58'
                    WHEN client_age BETWEEN 59 AND 70 THEN '59 to 70'
                END 
FROM #Analytics_AR A

-- Calculate probability for Onix
UPDATE A
SET onix = CAST((CAST(1 AS FLOAT)/
           (CAST(1 AS FLOAT) + CAST(EXP(-
           (-1.089 + ( -- Constant 
           -- Gender
            CASE 
                WHEN client_gender = 'Male' THEN -0.455
                WHEN client_gender = 'Female' THEN -1.089
                WHEN client_gender = 'Undefined' THEN -0.107 
                END
           -- Region
            +
            CASE
                WHEN region = 'Cuyo' THEN -1.089
                WHEN region = 'Gran Chaco' THEN 0.084
                WHEN region = 'Mesopotamia' THEN -0.024
                WHEN region = 'Northwest Argentina' THEN 0.479
                WHEN region = 'Pampas' THEN 0.012
                WHEN region = 'Patagonia' THEN 0.381
                WHEN region = 'Undefined' THEN 0.092
                END
           -- Age group:
           +
           CASE
                WHEN age_group = '18 to 34' THEN -1.089
                WHEN age_group = '35 to 40' THEN 0.113
                WHEN age_group = '41 to 45' THEN 0.199
                WHEN age_group = '46 to 58' THEN 0.405
                WHEN age_group = '59 to 70' THEN 0.177
                END
           -- Previous vehicle:
           +
           CASE
                WHEN previous_vehicle_model = 'camaro' THEN -1.089
                WHEN previous_vehicle_model = 'cobalt' THEN 1.43
                WHEN previous_vehicle_model = 'cruze' THEN -0.962
                WHEN previous_vehicle_model = 'Cruze5' THEN -0.666
                WHEN previous_vehicle_model = 'equinox' THEN 0.716
                WHEN previous_vehicle_model = 'onix' THEN 2.553
                WHEN previous_vehicle_model = 'onix plus' THEN 3.839
                WHEN previous_vehicle_model = 'prisma' THEN 0.684
                WHEN previous_vehicle_model = 'S10' THEN 0.774
                WHEN previous_vehicle_model = 'spin' THEN 1.361
                WHEN previous_vehicle_model = 'tracker' THEN 0.561
                WHEN previous_vehicle_model = 'trailblazer' THEN 0.236
                ELSE 0
                END
           -- Repurchase time:
           +
           CASE
                WHEN repurchase_time IS NOT NULL THEN -0.004
                ELSE 0
                END)
                )
                ) AS FLOAT)
                )
                ) AS float
                )
FROM #Analytics_AR A

-- Calculate probability for Cruze
UPDATE A
SET cruze = CAST((CAST(1 AS FLOAT)/
           (CAST(1 AS FLOAT) + CAST(EXP(-
           (0.268 + ( -- Constant 
           -- Gender
            CASE 
                WHEN client_gender = 'Male' THEN 0.44
                WHEN client_gender = 'Female' THEN 0.268
                WHEN client_gender = 'Undefined' THEN 0.296
                END
           -- Region
            +
            CASE
                WHEN region = 'Cuyo' THEN 0.268
                WHEN region = 'Gran Chaco' THEN -0.235
                WHEN region = 'Mesopotamia' THEN -0.001
                WHEN region = 'Northwest Argentina' THEN -0.461
                WHEN region = 'Pampas' THEN 0.221
                WHEN region = 'Patagonia' THEN -0.261
                WHEN region = 'Undefined' THEN 0.091
                END
           -- Age group:
           +
           CASE
                WHEN age_group = '18 to 34' THEN 0.268
                WHEN age_group = '35 to 40' THEN -0.247
                WHEN age_group = '41 to 45' THEN -0.277
                WHEN age_group = '46 to 58' THEN -0.536
                WHEN age_group = '59 to 70' THEN -0.445
                END
           -- Previous vehicle:
           +
           CASE
                WHEN previous_vehicle_model = 'camaro' THEN 0.268
                WHEN previous_vehicle_model = 'cobalt' THEN -1.547
                WHEN previous_vehicle_model = 'cruze' THEN 1.359
                WHEN previous_vehicle_model = 'Cruze5' THEN 1.101
                WHEN previous_vehicle_model = 'equinox' THEN -0.115
                WHEN previous_vehicle_model = 'onix' THEN -2.475
                WHEN previous_vehicle_model = 'onix plus' THEN -3.495
                WHEN previous_vehicle_model = 'prisma' THEN -2.223
                WHEN previous_vehicle_model = 'S10' THEN -0.598
                WHEN previous_vehicle_model = 'spin' THEN -1.692
                WHEN previous_vehicle_model = 'tracker' THEN -0.196
                WHEN previous_vehicle_model = 'trailblazer' THEN 0.216
                ELSE 0
                END
           -- Repurchase time:
           +
           CASE
                WHEN repurchase_time IS NOT NULL THEN 0.013
                ELSE 0
                END)
                )
                ) AS FLOAT)
                )
                ) AS FLOAT
                )
FROM #Analytics_AR A

-- Calculate probability for Tracker
UPDATE A
SET tracker = CAST((CAST(1 AS FLOAT)/
           (CAST(1 AS FLOAT) + CAST(EXP(-
           (-1.500 + ( -- Constant 
           -- Gender
            CASE 
                WHEN client_gender = 'Female' THEN -1.500
                WHEN client_gender = 'Male' THEN -1.529
                WHEN client_gender = 'Undefined' THEN -1.884
                END
           -- Region
            +
            CASE
                WHEN region = 'Cuyo' THEN -1.500
                WHEN region = 'Gran Chaco' THEN -0.522
                WHEN region = 'Mesopotamia' THEN -0.208
                WHEN region = 'Northwest Argentina' THEN -0.415
                WHEN region = 'Pampas' THEN 0.657
                WHEN region = 'Patagonia' THEN -0.177
                WHEN region = 'Undefined' THEN 0.493
                END
           -- Age group:
           +
           CASE
                WHEN age_group = '18 to 34' THEN -1.500
                WHEN age_group = '35 to 40' THEN 1.191
                WHEN age_group = '41 to 45' THEN 1.342
                WHEN age_group = '46 to 58' THEN 1.175
                WHEN age_group = '59 to 70' THEN 1.055
                END
           -- Previous vehicle:
           +
           CASE
                WHEN previous_vehicle_model = 'camaro' THEN -1.500
                WHEN previous_vehicle_model = 'cobalt' THEN 0.874
                WHEN previous_vehicle_model = 'cruze' THEN 1.020
                WHEN previous_vehicle_model = 'Cruze5' THEN 1.184
                WHEN previous_vehicle_model = 'equinox' THEN 0.482
                WHEN previous_vehicle_model = 'onix' THEN 1.663
                WHEN previous_vehicle_model = 'onix plus' THEN 1.016
                WHEN previous_vehicle_model = 'prisma' THEN 1.522
                WHEN previous_vehicle_model = 'S10' THEN -0.827
                WHEN previous_vehicle_model = 'spin' THEN 1.638
                WHEN previous_vehicle_model = 'tracker' THEN 3.256
                WHEN previous_vehicle_model = 'trailblazer' THEN 0.724
                ELSE 0
                END
           -- Repurchase time:
           +
           CASE
                WHEN repurchase_time IS NOT NULL THEN 0.003
                ELSE 0
                END)
                )
                ) AS FLOAT)
                )
                ) AS float
                )
FROM #Analytics_AR A

-- Calculate probability for S10 (no previous_vehicle variable)
UPDATE A
SET s10 = CAST((CAST(1 AS FLOAT)/
           (CAST(1 AS FLOAT) + CAST(EXP(-
           (-0.266 + ( -- Constant 
           -- Gender
            CASE 
                WHEN client_gender = 'Female' THEN -0.266
                WHEN client_gender = 'Male' THEN -1.242
                WHEN client_gender = 'Undefined' THEN -1.682
                END
           -- Region
            +
            CASE
                WHEN region = 'Cuyo' THEN -0.266
                WHEN region = 'Gran Chaco' THEN -0.492
                WHEN region = 'Mesopotamia' THEN -0.307
                WHEN region = 'Northwest Argentina' THEN -0.181
                WHEN region = 'Pampas' THEN 0.014
                WHEN region = 'Patagonia' THEN -0.034
                WHEN region = 'Undefined' THEN 0.662
                END
           -- Age group:
           +
           CASE
                WHEN age_group = '18 to 34' THEN -0.266
                WHEN age_group = '35 to 40' THEN 0.664
                WHEN age_group = '41 to 45' THEN 0.668
                WHEN age_group = '46 to 58' THEN 0.996
                WHEN age_group = '59 to 70' THEN 0.679
                END
           -- Repurchase time:
           +
           CASE
                WHEN repurchase_time IS NOT NULL THEN 0.009
                ELSE 0
                END)
                )
                ) AS FLOAT)
                )
                ) AS float
                )
FROM #Analytics_AR A

-- Update the most probable vehicle and probability
UPDATE A
SET most_probable_vehicle = 
        (
            SELECT TOP 1 model
            FROM
                (
                    SELECT 'Onix' AS model, B.onix AS quantity
                    FROM #Analytics_AR B WHERE A.client_sk = B.client_sk
                        UNION ALL
                    SELECT 'Tracker', C.tracker
                    FROM #Analytics_AR C WHERE A.client_sk = C.client_sk
                        UNION ALL
                    SELECT 'S10', D.s10
                    FROM #Analytics_AR D WHERE A.client_sk = D.client_sk
                        UNION ALL
                    SELECT 'Cruze', E.cruze
                    FROM #Analytics_AR E WHERE A.client_sk = E.client_sk
                ) AS Models
            ORDER BY Models.quantity DESC
        )
    , probability = (
            SELECT TOP 1 quantity
            FROM
                (
                    SELECT 'Onix' AS model, B.onix AS quantity
                    FROM #Analytics_AR B WHERE A.client_sk = B.client_sk
                        UNION ALL
                    SELECT 'Tracker', C.tracker
                    FROM #Analytics_AR C WHERE A.client_sk = C.client_sk
                        UNION ALL
                    SELECT 'S10', D.s10
                    FROM #Analytics_AR D WHERE A.client_sk = D.client_sk
                        UNION ALL
                    SELECT 'Cruze', E.cruze
                    FROM #Analytics_AR E WHERE A.client_sk = E.client_sk
                ) AS Models
            ORDER BY Models.quantity DESC
        )
FROM #Analytics_AR A

-- Update the probability range
UPDATE #Analytics_AR
SET probability_range = 
    CASE
        WHEN probability BETWEEN 0 AND 0.099999 THEN '0 - 10'
        WHEN probability BETWEEN 0.1 AND 0.199999 THEN '10 - 20'
        WHEN probability BETWEEN 0.2 AND 0.299999 THEN '20 - 30'
        WHEN probability BETWEEN 0.3 AND 0.399999 THEN '30 - 40'
        WHEN probability BETWEEN 0.4 AND 0.499999 THEN '40 - 50'
        WHEN probability BETWEEN 0.5 AND 0.599999 THEN '50 - 60'
        WHEN probability BETWEEN 0.6 AND 0.699999 THEN '60 - 70'
        WHEN probability BETWEEN 0.7 AND 0.799999 THEN '70 - 80'
        WHEN probability BETWEEN 0.8 AND 0.899999 THEN '80 - 90'
        WHEN probability BETWEEN 0.9 AND 1.000099 THEN '90 - 100'
    END
    
-- Drop the temporary table if it exists
IF OBJECT_ID('tempdb..#AverageFields') IS NOT NULL 
    BEGIN DROP TABLE #AverageFields END

-- Calculate average probability and repurchase time grouped by most probable vehicle and region
SELECT most_probable_vehicle, region, AVG(probability) AS avg_repurchase_prob, AVG(repurchase_time) AS avg_repurchase_time
INTO #AverageFields
FROM #Analytics_AR
GROUP BY most_probable_vehicle, region

-- Update the average repurchase probability and time
UPDATE A
    SET A.avg_repurchase_prob = B.avg_repurchase_prob,
        A.avg_repurchase_time = B.avg_repurchase_time
FROM #Analytics_AR A
INNER JOIN #AverageFields B ON A.most_probable_vehicle = B.most_probable_vehicle AND A.region = B.region

-- Update the average repurchase time probability
UPDATE A
    SET A.avg_repurchase_time_prob = B.avg_repurchase_time_prob
FROM #Analytics_AR A
INNER JOIN 
(
    SELECT ISNULL(repurchase_time, 0) AS repurchase_time, AVG(probability) AS avg_repurchase_time_prob
    FROM #Analytics_AR
    GROUP BY ISNULL(repurchase_time, 0)
) AS B
    ON ISNULL(A.repurchase_time, 0) = ISNULL(B.repurchase_time, 0)

-- Truncate the target table
TRUNCATE TABLE dbo.Analytics_Calculations

-- Insert the processed data into the target table
INSERT INTO dbo.Analytics_Calculations
SELECT * FROM #Analytics_AR
