use Mysql_Learners;

select * from  jobs_cleaned limit 10;


-- check if the word 'analyst' appears in all job title
select
	sum(jobTitle like '%analyst%' or jobTitle like '%analytics%') check_title
from jobs_cleaned;
# return 320

select
	*
from jobs_cleaned
where jobTitle not like '%analyst%' and jobTitle not like '%analytics%';
# this shows that jobs such as Data Engineer | Data Scientist | Business Intelligence Analyst are often grouped together


-- check job type
select
	employmentType
    ,count(*)
    ,round(count(employmentType) / (select count(*) from jobs_cleaned) * 100, 2) percentage
from jobs_cleaned
group by employmentType
order by count(*) desc;
# about 72% of the jobs are full-time roles and about 25% are contract roles


-- check employment type recruited against each state
select
	case
		when grouping(state) then '_Total'
        else state
    end state
    ,sum(employmentType='Full-time') full_time
    ,sum(employmentType='Part-time') part_time
    ,sum(employmentType='Contract/Temp') contract_temp
    ,sum(employmentType='Casual/Vacation') casual_vacation
from jobs_cleaned
group by state with rollup;


-- check number of jobs posted each day
select
    week(postedDate) weekly
    ,count(*) jobs
from jobs_cleaned
group by week(postedDate) 
order by jobs;
# since I could only extract about 500 jobs out of approx. 9,000 jobs
# I'm interested in seeing the sum of jobs posted and not really checking the average posts each week
# it does show the increase in job posts each week

select count(*)
from jobs_cleaned
where timePosted like '%hour%' or timePosted like '%minute%';
# return 59

select
	dayname(postedDate)
    ,count(*) jobs
from jobs_cleaned
group by dayname(postedDate)
order by jobs desc;
# I'm curious how the results would appear with additional time data for further investigation
# nevertheless, it's apparent that Friday emerges as the favorite day for advertising new roles


-- check job posts per state
select
	-- state
    if(GROUPING(postedDate), '_Total', postedDate) postedDate
    ,sum(state='NSW') NSW
    ,sum(state='VIC') VIC
    ,sum(state='QLD') QLD
    ,sum(state='ACT') ACT
    ,sum(state='TAS') TAS
    ,sum(state='SA') SA
    ,sum(state='WA') WA
    ,sum(state='NT') NT
    ,count(*) jobs
from jobs_cleaned
group by postedDate with rollup
order by postedDate;
# it's not surprising to see that NSW and VIC have the highest number of posted roles, with QLD coming in third
# although there's a heavy concentration of job postings towards the end of April,
# it's worth noting that only 25 pages of results were returned, which might skew the figures somewhat


-- check location
select
	location
	,count(location)
from jobs_cleaned
group by location
order by 2 desc;
# not all jobs posted with a specific location noted down (248 records with no certain location)

select
	area
    ,count(*)
from jobs_cleaned
group by area
order by 2 desc;
# jobs posted appear to be concentrated in the central cities of each state


-- what are the most common job titles?
-- let's check out the top 5 job titles
select
	jobTitle
    ,count(*)
from jobs_cleaned
group by jobTitle
order by 2 desc
limit 5;
# Data Analyst, Business Analyst, Data Engineer, Data and Reporting Analyst, Business Intelligence Analyst

select
	jobTitle
from (
	select
		jobTitle
		,rank() over (order by count(*) desc) ranking
	from jobs_cleaned
    group by 1
	) t
where ranking <= 5;
# this way returns 6 titles
# Data Analyst, Business Analyst, Data Engineer, Data and Reporting Analyst, Business Intelligence Analyst, Senior Data Analyst
# both BI & Senior Data Analysts are in the same ranking


-- check industry
select
	classification
    ,count(*)
from jobs_cleaned
group by 1
order by 2 desc;
