use autocaredb;

-- REMOVING DUPLICATES(about 1400 rows dropped from here)
CREATE VIEW vw_data AS
WITH CleanData AS (select *, row_number() over 
					(partition by MRD_NO, DOA, DOD
					 order by MRD_NO) as Dup_no 
                     from data)
select * from CleanData where Dup_no = 1 and MRD_NO is not null;

-- Q1)Getting the total discharges
select count(*) as total_discharges 
from vw_data
where OUTCOME = "discharge";

-- Q2)Getting the Avg daily discharge rate 
-- It is the total discharges divided by the total length of stay
select CAST(((count(*)/sum(duration_of_stay)) * 100) as decimal(10,0)) as Avg_DailyDischargeRate 
from vw_data 
where outcome = "discharge";

-- Method 2
select (ROUND((sum(case when outcome = "discharge" then 1 else 0 end)/
		(select sum(duration_of_stay) from vw_data where outcome = "discharge")),2) * 100) as Avg_DailyDischargeRate
from vw_data;

-- Q3)Getting the Avg length of stay(ALOS)
-- It is the total length of stay divided by the total discharges
select Round((select sum(duration_of_stay) from vw_data where outcome = "discharge")/
                                    (select sum(case when outcome = "discharge" then 1 else 0 end) from vw_data),0)
                                    as Avg_length_of_stay;

-- Q4)Distribution of discharges by Age Group
-- age <= 16 - paediatric
-- age >16 and <65 - adult
-- age >= 65 - senior citizen
with temp as (select age,(case when age<=16 then "Paediatric"
                when age between 16 and 65 then "Adult"
                when age>=65 then "Senior Citizen" 
                else "unknown" end) as age_group, outcome
from vw_data where outcome = "discharge")
select age_group, count(*) as age_distribution from temp
group by age_group
order by 2 desc;

-- Q5)Distribution of discharges by gender
select gender, count(*) as gender_distribution
from vw_data
where outcome = "discharge"
group by gender
order by 2 desc;   

-- Q6)Distribution of discharge by day of week
-- Convert to DATE datatype - SELECT DOD, STR_TO_DATE(DOD, '%d/%m/%Y') AS valid_date from vw_data  
SELECT 
    DAYNAME(STR_TO_DATE(DOD, '%d/%m/%Y')) AS Day_of_Week,
    COUNT(*) AS Day_Distribution
FROM vw_data
WHERE OUTCOME = 'DISCHARGE'
GROUP BY Day_of_Week
ORDER BY 2 DESC;                  