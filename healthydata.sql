--------checking the whole data
USE Healthy_Analysis;

SELECT *
FROM [dbo].[diabetic_data$];

----------
SELECT *
FROM [dbo].[diabetic_data$];

-------count
select COUNT(*)
FROM [dbo].[diabetic_data$];

-------TOP 10 sql servor not that does not use limit
Select TOP 10*
FROM [dbo].[diabetic_data$]

--------UPDATE

 
-- Change diag_1 to VARCHAR so it can store '?'
ALTER TABLE [dbo].[diabetic_data$]
ALTER COLUMN diag_1 VARCHAR(10);

-- Replace '?' with NULL
UPDATE [dbo].[diabetic_data$]
SET 
    race = NULLIF(race, '?'),
    payer_code = NULLIF(payer_code, '?'),
    medical_specialty = NULLIF(medical_specialty, '?'),
    diag_1 = NULLIF(diag_1, '?'),
    diag_2 = NULLIF(diag_2, '?'),
    diag_3 = NULLIF(diag_3, '?');

-- Check the result
SELECT *
FROM [dbo].[diabetic_data$];

-----checking data type
SELECT 
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'diabetic_data$'
AND COLUMN_NAME IN (
    'race',
    'payer_code',
    'medical_specialty',
    'diag_1',
    'diag_2',
    'diag_3',
    'weight'
);

---------diag 2 and diag 3 are float
ALTER TABLE [dbo].[diabetic_data$]
ALTER COLUMN diag_2 VARCHAR(10);

ALTER TABLE [dbo].[diabetic_data$]
ALTER COLUMN diag_3 VARCHAR(10);
------------lets run now
UPDATE [dbo].[diabetic_data$]
SET 
    race = NULLIF(race, '?'),
    payer_code = NULLIF(payer_code, '?'),
    medical_specialty = NULLIF(medical_specialty, '?'),
    diag_1 = NULLIF(diag_1, '?'),
    diag_2 = NULLIF(diag_2, '?'),
    diag_3 = NULLIF(diag_3, '?');

    SELECT *
FROM [dbo].[diabetic_data$];

ALTER TABLE [dbo].[diabetic_data$]
ALTER COLUMN weight VARCHAR(20);

UPDATE [dbo].[diabetic_data$]
SET weight = NULLIF(weight, '?');

--------yes done now converted to null
--------looking for percentages

SELECT
    ROUND(SUM(CASE WHEN weight IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 0) AS pct_missing_weight,
    ROUND(SUM(CASE WHEN payer_code IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 0) AS pct_payer_code,
    ROUND(SUM(CASE WHEN medical_specialty IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 0) AS pct_medical_specialty
FROM [dbo].[diabetic_data$];


---------duplicates patients
SELECT
    patient_nbr,
    COUNT(*) AS encounter_count
FROM [dbo].[diabetic_data$]
GROUP BY patient_nbr
HAVING COUNT(*) > 1
ORDER BY encounter_count DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
----------
SELECT t.*
INTO diabetic_data_dedup
FROM [dbo].[diabetic_data$] AS t
INNER JOIN (
    SELECT
        patient_nbr,
        MIN(encounter_id) AS first_encounter
    FROM [dbo].[diabetic_data$]
    GROUP BY patient_nbr
) AS first_enc
    ON t.patient_nbr = first_enc.patient_nbr
    AND t.encounter_id = first_enc.first_encounter;

    select
    COUNT(*) from diabetic_data_dedup

    ------patients who cannot be re admitted

    select
       discharge_disposition_id,
       
       COUNT(*) as Encounter_Count
    from [dbo].[diabetic_data$]

    group by discharge_disposition_id
    order by Encounter_Count DESC;

    --------------------
    select*
    from [dbo].[IDS_mapping1$]
    where
    description like '%hospice%'  OR description like '%expired%' OR description like '%decesed%';

    --------11,13,14,19,20,21,26

    delete from diabetic_data_dedup

    where discharge_disposition_id in (11,13,14,19,20,21,26);

    ------------------
    create table discharge_disposition_map
    (
    discharge_disposition_id int,
    description varchar (150)
    );

    create table admission_source_map
    (
    admission_source_id int,
    description varchar (150)
    );

    SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'discharge_disposition_map';

SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'admission_source_map';

--------------------
select*
from [dbo].[diabetic_data_dedup]

ALTER TABLE [dbo].[diabetic_data_dedup]
ADD age_midpoint INT;

UPDATE [dbo].[diabetic_data_dedup]
SET age_midpoint = CASE
    WHEN age = '[0-10)' THEN 5
    WHEN age = '[10-20)' THEN 15
    WHEN age = '[20-30)' THEN 25
    WHEN age = '[30-40)' THEN 35
    WHEN age = '[40-50)' THEN 45
    WHEN age = '[50-60)' THEN 55
    WHEN age = '[60-70)' THEN 65
    WHEN age = '[70-80)' THEN 75
    WHEN age = '[80-90)' THEN 85
    WHEN age = '[90-100)' THEN 95
END;

------------explanatory
SELECT
    readmitted,
    COUNT(*) AS encounter_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM [dbo].[diabetic_data_dedup]), 1) AS pct_total
FROM [dbo].[diabetic_data_dedup]
GROUP BY readmitted
ORDER BY encounter_count DESC;


-------------------------------
SELECT
    age,
    age_midpoint,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) AS readmitted_under30,
    ROUND(
        SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        1
    ) AS readm_pct
FROM [dbo].[diabetic_data_dedup]
GROUP BY age, age_midpoint
ORDER BY age_midpoint;
---------
SELECT   
    m.description AS adm_type, 
    COUNT(*) AS total_encounters, 
    ROUND( 
        SUM(CASE WHEN d.readmitted = '<30' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        1 
    ) AS readmission_pct 
FROM [dbo].[diabetic_data_dedup] AS d 
JOIN [dbo].[IDS_mapping1$] AS m 
    ON d.admission_type_id = m.admission_type_id
GROUP BY m.description 
ORDER BY readmission_pct DESC;

--------------
SELECT TOP 5 *
FROM [dbo].[IDS_mapping1$];
-----with

WITH patient_base_risk AS (
    SELECT
        encounter_id,
        patient_nbr,
        age_midpoint,
        time_in_hospital,
        num_medications,
        num_lab_procedures,
        number_diagnoses,
        number_inpatient,
        number_emergency,
        number_outpatient,
        diag_1,
        readmitted,
        CASE 
            WHEN readmitted = '<30' THEN 1 
            ELSE 0 
        END AS is_readmitted
    FROM [dbo].[diabetic_data_dedup]
)
SELECT TOP 20 *
FROM patient_base_risk;

-------------heaviest workload
WITH patient_base_risk AS (
    SELECT
        encounter_id,
        age_midpoint,
        num_medications,
        readmitted,
        CASE 
            WHEN readmitted = '<30' THEN 1 
            ELSE 0 
        END AS is_readmitted
    FROM [dbo].[diabetic_data_dedup]
)
SELECT
    encounter_id,
    age_midpoint,
    num_medications,
    readmitted,
    RANK() OVER (
        PARTITION BY age_midpoint 
        ORDER BY num_medications DESC
    ) AS medriskage
FROM patient_base_risk
ORDER BY age_midpoint, medriskage;


--------

WITH patient_base_risk AS (
    SELECT 
        encounter_id,
        number_inpatient,
        readmitted,

        CASE 
            WHEN readmitted = '<30' THEN 1 
            ELSE 0 
        END AS is_readmitted_30
    FROM [dbo].[diabetic_data_dedup]
)
SELECT
    encounter_id,
    number_inpatient,
    NTILE(4) OVER (ORDER BY number_inpatient DESC) AS risk_quartile
FROM patient_base_risk;

-----------------------Classifies medication and diagnosis complexity.


SELECT
    encounter_id,
    num_medications,

    CASE 
        WHEN num_medications <= 10 THEN 'low'
        WHEN num_medications BETWEEN 11 AND 20 THEN 'medium'
        ELSE 'HIGH'
    END AS Medication_burden_tier,

    CASE
        WHEN number_diagnoses <= 5 THEN 'low_complexity'
        WHEN number_diagnoses BETWEEN 6 AND 9 THEN 'moderate_complexity'
        ELSE 'high_complexity'
    END AS diagnosis_complexity_tier

FROM [dbo].[diabetic_data_dedup];
---------------------------
----------------diag 1 notes
---------------390-459 :diseases of the circulatory sysytem
----------------460-519:diseases of the respiratory sysytem
----------------520-579:diseases of the digestive system
---------------580-629:diseases of the gentoury system
---------------800-999:injury and poisoning

WITH diag_categorised AS (
    SELECT
        encounter_id,
        readmitted,

        CASE 
            WHEN diag_1 LIKE '250%' THEN 'Diabetes'

            WHEN CAST(LEFT(diag_1, 3) AS INT) BETWEEN 390 AND 459 
                THEN 'circulatory'

            WHEN CAST(LEFT(diag_1, 3) AS INT) BETWEEN 460 AND 519 
                THEN 'respiratory'

            WHEN CAST(LEFT(diag_1, 3) AS INT) BETWEEN 520 AND 579 
                THEN 'digestive'

            WHEN CAST(LEFT(diag_1, 3) AS INT) BETWEEN 580 AND 629 
                THEN 'genitourinary'

            WHEN CAST(LEFT(diag_1, 3) AS INT) BETWEEN 800 AND 999 
                THEN 'injury'

            ELSE 'other'
        END AS diagnosis_categories,

        CASE 
            WHEN readmitted = '<30' THEN 1 
            ELSE 0 
        END AS is_readmitted

    FROM [dbo].[diabetic_data_dedup]
    WHERE diag_1 IS NOT NULL
)

SELECT
    diagnosis_categories,
    COUNT(*) AS total_encounter,
    ROUND(AVG(is_readmitted) * 100, 1) AS readmission_rate_pct

FROM diag_categorised

GROUP BY diagnosis_categories

ORDER BY readmission_rate_pct DESC;
          
        ------------------discharge disposition impact
        SELECT
    m.description AS discharge_disposition,
    COUNT(*) AS total_encounters,

    ROUND(
        SUM(CASE 
                WHEN d.readmitted = '<30' THEN 1 
                ELSE 0 
            END) * 100.0 / COUNT(*),
        1
    ) AS readmission_rate_pct

FROM [dbo].[diabetic_data_dedup] AS d

JOIN [dbo].[discharge_disposition_map] AS m
    ON d.discharge_disposition_id = m.discharge_disposition_id

GROUP BY m.description

HAVING COUNT(*) > 100

ORDER BY readmission_rate_pct DESC;