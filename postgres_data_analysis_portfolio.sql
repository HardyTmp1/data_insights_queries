

______________________________________________________________ 1.

/*"Identify data-related job postings from companies, along with their 
required skills and salary insights, by combining multiple datasets and 
filtering companies based on skill variety."
*/

WITH company_count as (
    SELECT 
    company_id as ID, 
    COUNT(*) as FREQUENCY
FROM 
    company_dim 
GROUP BY 
    ID 
), 
Required_skills as ( 
    SELECT  
        job.company_id AS ID, 
        job.job_title_short as JOBS,
        string_agg(distinct skill.skills, ' | ') as skillset, 
        AVG(job.salary_year_avg) as AVG_SALARY 
    FROM 
        job_postings_fact as job
    INNER JOIN skills_job_dim as skill_to_job ON job.job_id = skill_to_job.job_id  
    INNER JOIN skills_dim as skill ON skill_to_job.skill_id = skill.skill_id 
    WHERE 
        job.salary_year_avg is not NULL and 
        job.job_title_short LIKE '%Data%'
    GROUP BY 
        ID, JOBS
    HAVING count (distinct skill.skills) = 3
)
SELECT 
    cc.*,
    jpf.job_country, 
    rs.jobs, 
    rs.skillset, 
    CASE
        WHEN job_country = 'Serbia' THEN 'RSD'
        WHEN job_country = 'United States' THEN 'USD'
        WHEN job_country = 'Canada' THEN 'CAD'
        WHEN job_country = 'France' THEN 'EURO'
        ELSE 'N/A'
    END as CURRENCY,
    ROUND(rs.AVG_SALARY,2) as SALARY 
FROM 
    job_postings_fact as jpf 
INNER JOIN company_count as cc ON jpf.job_id = cc.id 
INNER JOIN Required_skills as rs ON cc.id = rs.id;





________________________________________________________________ 2.
/*Find which companies demand the widest variety of skills.
HINTS:
    - Use job_postings_fact, skills_job_dim, and skills_dim.
    - For each company:
        Count how many unique skills appear across all their job postings.
        Calculate the average salary for that company’s jobs (where not null).
    - Only include companies with at least 10 job postings.
    - Sort by skill count descending.
*/ 

SELECT 
    jpf.company_id as ID, 
    COUNT (DISTINCT sd.skills) as COUNT_SKILLS, 
    ROUND(AVG(jpf.salary_year_avg),2) as AVG_SALARY, 
        CASE 
            WHEN COUNT(DISTINCT sd.skills) >= 20 THEN 'Highly Skilled'
            WHEN COUNT(DISTINCT sd.skills) BETWEEN 10 AND 19 THEN 'Moderately Skilled'
        ELSE 'Low Skill Demand'
    END as SKILLS_TYPE
FROM 
    job_postings_fact as jpf 
INNER JOIN skills_job_dim as sjd ON jpf.job_id = sjd.job_id 
INNER JOIN skills_dim as sd ON sjd.skill_id = sd.skill_id 
WHERE 
    jpf.salary_year_avg is not NULL 
GROUP BY 
    ID
HAVING 
    COUNT(jpf.job_id) > 10
ORDER BY 
    COUNT_SKILLS DESC   



______________________________________________________________ 3.

/*Compare average salaries across categories like “Data”, “Engineer”, “Analyst”, etc.
Instructions:
    From job_postings_fact:
    Use a CASE statement to classify each job title into broader categories:
        'Data%' → “Data”
        '%Engineer%' → “Engineer”
        '%Analyst%' → “Analyst”
        else → “Other”
        Then group by those categories.
    Show:
        number of postings,
        average salary,
        country with the most postings in that category.
        This combines CASE + GROUP BY + aggregation logic.
*/

WITH CLASSIFICATION_AND_GROUP as (
    SELECT 
    CASE 
        WHEN job_title_short LIKE 'Data%' THEN 'Data'
        WHEN job_title_short LIKE '%Engineer%' THEN 'Engineer'
        WHEN job_title_short LIKE '%Analyst%' THEN 'Analyst'
        ELSE 'Other'
    END as CLASSIFICATION,
    COUNT(job_id) as COUNT_JOBS, 
    job_country as COUNTRY, 
    ROUND(AVG(salary_year_avg),2) as AVG_SALARY
FROM 
    job_postings_fact 
WHERE 
    salary_year_avg is not NULL
GROUP BY 
    COUNTRY, 
    CASE 
        WHEN job_title_short LIKE 'Data%' THEN 'Data'
        WHEN job_title_short LIKE '%Engineer%' THEN 'Engineer'
        WHEN job_title_short LIKE '%Analyst%' THEN 'Analyst'
        ELSE 'Other'
    END
), 
MAX_JOBS as (
    SELECT 
    CLASSIFICATION, 
    MAX (COUNT_JOBS) AS MAX_JOBS
FROM 
    CLASSIFICATION_AND_GROUP
GROUP BY
    CLASSIFICATION
)
SELECT 
    CAG.CLASSIFICATION, 
    CAG.COUNT_JOBS,
    CAG.COUNTRY,
    CAG.AVG_SALARY
FROM 
    CLASSIFICATION_AND_GROUP as CAG
INNER JOIN MAX_JOBS as MJ ON CAG.CLASSIFICATION = MJ.CLASSIFICATION 
AND CAG.COUNT_JOBS = MJ.MAX_JOBS
ORDER BY 
    COUNT_JOBS DESC


__________________________________________________________________ 4.

/*
Goal: Find which 3 job titles appear most often in each country.

Instructions:
    - Use a CTE to count how many postings exist per (job_country, job_title_short).
    - Then use a subquery (or multiple CTEs) to filter only the top 3 titles per country.
    - Order neatly: country → descending by count.   
*/


WITH COUNTRY_JOBS AS (
    SELECT 
        job_country AS country,
        job_title_short AS job_title,
        COUNT(job_id) AS job_count
    FROM 
        job_postings_fact
    WHERE 
        job_country IS NOT NULL
    GROUP BY 
        job_country, job_title_short
),
TOP_3_TITLES AS (
    SELECT 
        cj1.country,
        cj1.job_title,
        cj1.job_count
    FROM 
        COUNTRY_JOBS cj1
    WHERE 
        3 > (
            SELECT COUNT(*) 
            FROM COUNTRY_JOBS cj2
            WHERE cj2.country = cj1.country 
              AND cj2.job_count > cj1.job_count
        )
)
SELECT 
    country,
    job_title,
    job_count
FROM 
    TOP_3_TITLES
ORDER BY 
    country,
    job_count DESC;



______________________________________________________________ 5. 

/*Goal: Identify companies that hire in multiple countries and pay consistently well.

Instructions:
    Join company_dim and job_postings_fact.
    For each company:
    Count distinct countries they hire in.
    Compute average salary.
    Filter only those hiring in at least 2 countries.

Add a CASE label:

    WHEN avg_salary >= 100000 THEN 'High Paying'
    WHEN avg_salary BETWEEN 70000 AND 99999 THEN 'Mid Range'
    ELSE 'Low Paying'

Sort by average salary descending.
*/


SELECT 
    cd.company_id ID, 
    cd.name NAME,
    COUNT (DISTINCT jpf.job_country) COUNT_COUNTRIES,
    ROUND(AVG(jpf.salary_year_avg),2) AVG_SALARY, 
    CASE 
        WHEN ROUND(AVG(jpf.salary_year_avg),2) >= 100000 THEN 'HIGH PAYING'
        WHEN ROUND(AVG(jpf.salary_year_avg),2) BETWEEN 70000 AND 99999 THEN 'MID RANGE'
        ELSE 'LOW PAYING'
    END SALARY_RATE
FROM 
    job_postings_fact jpf 
JOIN company_dim cd ON jpf.company_id = cd.company_id
WHERE 
    jpf.salary_year_avg is not NULL
GROUP BY 
    ID, NAME, SALARY_RATE 
HAVING 
    COUNT (DISTINCT jpf.job_country) >= 2 
ORDER BY 
    AVG_SALARY DESC 
LIMIT 
    1000




















