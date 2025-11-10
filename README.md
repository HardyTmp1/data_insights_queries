# Data Jobs SQL Portfolio – README

A compact portfolio of 5 SQL queries demonstrating intermediate-to-advanced skills in joins, CTEs, conditional aggregation, ranking-by-subquery, and business-focused reporting. Built and tested for **PostgreSQL**. Perfect for showcasing on GitHub, Fiverr, and LinkedIn.

---

## 🚀 Quick Start (VS Code)

1. **Prereqs**
   - PostgreSQL (v13+ recommended)
   - VS Code with a SQL extension (e.g., *SQLTools* or *PostgreSQL*), or `psql` CLI

2. **Clone & Open**
   - Put `postgres_data_analysis_portfolio.sql` in your repo root (or keep the provided structure below).
   - Open the folder in VS Code.

3. **Connect to your database**
   - Create a database and load your tables (`job_postings_fact`, `skills_job_dim`, `skills_dim`, `company_dim`).
   - Ensure the column names match those referenced by the queries.

4. **Run the Queries**
   - Open `postgres_data_analysis_portfolio.sql`
   - Each query is separated by a clear header (`____ 1.`, `____ 2.`, etc.).
   - Run the section you need (highlight + “Run Selected Query” in VS Code, or paste into `psql`).

---

## 📁 Suggested Project Structure

```
data-jobs-sql-portfolio/
├─ README.md
└─ postgres_data_analysis_portfolio.sql
```

> You can add a `schema/` folder with create-table scripts, and a `samples/` folder with CSVs if you plan to share the dataset.

---

## 📊 Dataset Assumptions

- **Tables**: `job_postings_fact`, `skills_job_dim`, `skills_dim`, `company_dim`
- **Highlights**:
  - `job_postings_fact(job_id, job_title_short, job_country, company_id, salary_year_avg, ...)`
  - `skills_job_dim(job_id, skill_id)`
  - `skills_dim(skill_id, skills)`
  - `company_dim(company_id, name, ...)`
- Salary fields may contain `NULL`. Countries and titles should be present for ranking and grouping queries to work as intended.

---

## 🔎 Queries at a Glance

### 1) Identify Data-focused roles with required skills and salary insights
**What it shows:**  
- Combines job postings with skills to list **Data%** job titles, their distinct skillset (exactly 3 distinct skills per title/company), and **average salary**.  
- Adds a **currency label** for select countries.  
- Demonstrates multi-CTE workflow and **string_agg** for skills.

**Good for:** tech stack visibility, salary screening, quick “skills + pay” snapshots by company.

---

### 2) Companies by breadth of required skills (w/ salary bands)
**What it shows:**  
- Counts **distinct skills per company** across all postings.  
- Computes **average salary**, filters for companies with **>10 postings**, and classifies into **Highly / Moderately / Low Skill Demand**.  
- Demonstrates **DISTINCT counts**, **CASE** banding, and **HAVING** filters.

**Good for:** finding employers with rich skill expectations and better compensation.

---

### 3) Category-level salary and where each category is strongest
**What it shows:**  
- Classifies job titles using **CASE** into: **Data**, **Engineer**, **Analyst**, **Other**.  
- Aggregates **count of postings** + **average salary** by (category, country).  
- Finds, per category, **the country with the most postings** via a two-CTE approach (group + max).

**Good for:** high-level market mapping and category trends across countries.

---

### 4) Top 3 job titles in each country (by posting count)
**What it shows:**  
- Counts postings per (country, job_title) and selects **the top 3** per country using a **self-correlated subquery** (`WHERE 3 > (...)`).  
- **Ties are included**: if multiple titles share the same rank counts, they all appear (so you might see 4 or 5 items for a country when there are ties).

**Good for:** quick, tie-aware rankings without window functions.

---

### 5) Multi-country employers with consistent pay
**What it shows:**  
- Joins companies with postings to find **employers hiring in ≥ 2 countries**, computes **average salary**, and assigns **High/Mid/Low Paying** bands.  
- Demonstrates **COUNT(DISTINCT)** across countries, **CASE** banding, and `HAVING`.

**Good for:** shortlisting global employers with stronger pay signals.

---

## 🛠️ How to Run (examples)

**In VS Code**  
- Open `postgres_data_analysis_portfolio.sql`, place cursor anywhere in a query block, run the selected query via your SQL extension.

**With `psql` CLI**  
```bash
# Option A: run the whole file (will print all result sets sequentially)
psql -h <host> -U <user> -d <db> -f postgres_data_analysis_portfolio.sql

# Option B: run one query – copy/paste the block between the headers into psql
psql -h <host> -U <user> -d <db>
# then paste the SQL block and end with ;
```

---

## ✅ Notes & Tips

- **Null salaries:** Queries commonly filter `salary_year_avg IS NOT NULL` so results reflect real pay data. Remove this filter if you want pure counts.  
- **Top 3 logic (Query 4):** The condition `3 > (SELECT COUNT(*) ... WHERE job_count > cj1.job_count)` returns rows whose rank (by count) is ≤ 3. **Equal counts** yield ties.  
- **Extensibility:** You can easily swap `job_title_short LIKE 'Data%'` for more targeted roles (e.g., “%Scientist%”).  
- **Currency mapping:** The mapping in Query 1 is illustrative—extend the `CASE` as needed.  
- **Performance:** Add indexes on `job_postings_fact(job_country)`, `job_postings_fact(job_title_short)`, `job_postings_fact(company_id)`, and on the junction `skills_job_dim(job_id, skill_id)` when running at scale.

---

## 📌 Attribution

All queries are bundled in **`postgres_data_analysis_portfolio.sql`**. See that file for exact SQL and in-line comments.

---

## 🧾 License

Choose the license you prefer for this portfolio. If unsure, **MIT** is a good default for public portfolio code.

---

## 💡 What to highlight on Fiverr/LinkedIn

- Real-world **market questions** answered via SQL
- Clean **CTE structure** and **CASE-based** categorization
- Tie-aware top-N selection (without window functions)
- Business-friendly outputs: skills breadth, pay banding, global reach
