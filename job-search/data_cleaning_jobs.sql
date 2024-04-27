use Mysql_Learners;

-- create table with cols as placeholders
-- data types to be varchar for all
create table Jobs (
	jobTitle varchar(100)
    ,jobCompany varchar(80)
    ,jobType varchar(50)
    ,jobLocation varchar(50)
    ,jobSalary varchar(50)
    ,classification varchar(50)
    ,subClassification varchar(50)
    ,jobShortDescription varchar(200)
    ,timePosted varchar(50)
);

alter table Jobs
modify jobLocation varchar(100);

select * from Jobs;
select count(*) from Jobs; # 502

/*
DATA CLEANING & EDA
*/

select * from Jobs;

-- checking null records in each column
select
	count(*) all_records
    ,sum(jobTitle is null) missing_title
    ,sum(jobCompany is null) missing_commpany
    ,sum(jobType is null) missing_status
    ,sum(jobLocation is null) missing_location
    ,sum(jobSalary is null) missing_salary
    ,sum(classification is null) missing_classification
    ,sum(subClassification is null) missing_subClass
    ,sum(jobShortDescription is null) missing_description
    ,sum(timePosted is null) missing_timePost
from Jobs;
# all records = 502
# company = 2 null values
# salary = 270 null values

-- check duplicates
create table jobs_no_duplicates
select
	jobTitle
	,jobCompany
	,jobType
	,jobLocation
	,classification
	,subClassification
	,timePosted
from (
	select
		*
		,row_number() over (partition by 
			jobTitle
			,jobCompany
			,jobType
			,jobLocation
			,jobSalary
			,classification
			,subClassification
			,jobShortDescription
			,timePosted) rn
	from Jobs
	) t
where rn = 1;


# 96 duplicate rows
with cte as (
	select
		*
		,row_number() over (partition by 
			jobTitle
			,jobCompany
			,jobType
			,jobLocation
			,jobSalary
			,classification
			,subClassification
			,jobShortDescription
			,timePosted) rn
	from Jobs
	)
SELECT
	count(*)
FROM cte
WHERE rn > 1;

-- check distinct jobType
select distinct jobType
from Jobs;
# Full time, Contract/Temp, Part time, Casual/Vacation
select
	jobType
    ,case
		when jobType like '%Full time%' then 'Full-time'
        when jobType like '%Part time%' then 'Part-time'
        when jobType like '%Contract/Temp%' then 'Contract/Temp'
        when jobType like '%Casual/Vacation%' then 'Casual/Vacation'
	end employment
from Jobs;

-- check jobLocation
select
	jobLocation
	,left(jobLocation, instr(jobLocation, ', ')-1) location
    ,case
		when instr(jobLocation, ',') <> 0 then right(jobLocation, length(jobLocation) - instr(jobLocation, ',')-1)
        else jobLocation
	end area
    ,case
		when jobLocation like '%NSW' then 'NSW'
        when jobLocation like '%VIC' then 'VIC'
        when jobLocation like '%QLD' then 'QLD'
        when jobLocation like '%WA' then 'WA'
        when jobLocation like '%TAS' then 'TAS'
        when jobLocation like '%ACT' then 'ACT'
        when jobLocation like '%SA' then 'SA'
        when jobLocation like '%NT' then 'NT'
    end state
from Jobs
order by state;

-- check salary
select
	jobSalary
from Jobs
where jobSalary is not null;

-- check classification
select
	classification
    ,count(*)
from (
	select
		replace(replace(classification, '(', ''),  ')', '') classification
	from Jobs) t
group by 1
order by 2 desc;

-- check subClass
select
	subClassification
    ,count(*)
from Jobs
group by 1
order by 2 desc;

-- check time when jobs got posted
-- all started with `Listed `
-- set date extracted as at 26 April 2024
set @d = '2024-04-26';

select
	jobs.timePosted
    ,num
    ,case
		when num = 'eight' then @d - interval 8 day
		when num = 'eighteen' then @d - interval 18 day
		when num = 'eleven' then @d - interval 11 day
		when num = 'fifteen' then @d - interval 15 day
		when num = 'four' then @d - interval 4 day
		when num = 'fourteen' then @d - interval 14 day
		when num = 'nine' then @d - interval 9 day
		when num = 'nineteen' then @d - interval 19 day
		when num = 'one' then @d - interval 1 day
		when num = 'seven' then @d - interval 7 day
		when num = 'seventeen' then @d - interval 17 day
		when num = 'six' then @d - interval 6 day
		when num = 'sixteen' then @d - interval 16 day
		when num = 'ten' then @d - interval 10 day
		when num = 'thirteen' then @d - interval 13 day
		when num = 'three' then @d - interval 3 day
		when num = 'twenty' then @d - interval 20 day
		when num = 'twenty one' then @d - interval 21 day
		when num = 'twenty three' then @d - interval 23 day
		when num = 'twenty two' then @d - interval 22 day
		when num = 'two' then @d - interval 2 day
		when num is null then @d
    end
from (
	select
		timePosted
		,trim(case
			when timePosted like '%day%' then substring_index(substr(timePosted, 8), 'day', 1)
		end) num
	from Jobs
) t
right join Jobs on t.timePosted = jobs.timePosted;

select * from Jobs;
drop table jobs_cleaned;
-- transform data for analysis
create table jobs_cleaned
select
	jobTitle
    ,jobCompany
    ,case
		when jobType like '%Full time%' then 'Full-time'
        when jobType like '%Part time%' then 'Part-time'
        when jobType like '%Contract/Temp%' then 'Contract/Temp'
        when jobType like '%Casual/Vacation%' then 'Casual/Vacation'
	end employmentType
    ,left(jobLocation, instr(jobLocation, ', ')-1) location
    ,case
		when instr(jobLocation, ',') <> 0 then right(jobLocation, length(jobLocation) - instr(jobLocation, ',')-1)
        else jobLocation
	end area
    ,case
		when jobLocation like '%NSW' then 'NSW'
        when jobLocation like '%VIC' then 'VIC'
        when jobLocation like '%QLD' then 'QLD'
        when jobLocation like '%WA' then 'WA'
        when jobLocation like '%TAS' then 'TAS'
        when jobLocation like '%ACT' then 'ACT'
        when jobLocation like '%SA' then 'SA'
        when jobLocation like '%NT' then 'NT'
    end state
    ,replace(replace(classification, '(', ''),  ')', '') classification
    ,subClassification
    ,j.timePosted
    ,case
		when num = 'eight' then @d - interval 8 day
		when num = 'eighteen' then @d - interval 18 day
		when num = 'eleven' then @d - interval 11 day
		when num = 'fifteen' then @d - interval 15 day
		when num = 'four' then @d - interval 4 day
		when num = 'fourteen' then @d - interval 14 day
		when num = 'nine' then @d - interval 9 day
		when num = 'nineteen' then @d - interval 19 day
		when num = 'one' then @d - interval 1 day
		when num = 'seven' then @d - interval 7 day
		when num = 'seventeen' then @d - interval 17 day
		when num = 'six' then @d - interval 6 day
		when num = 'sixteen' then @d - interval 16 day
		when num = 'ten' then @d - interval 10 day
		when num = 'thirteen' then @d - interval 13 day
		when num = 'three' then @d - interval 3 day
		when num = 'twenty' then @d - interval 20 day
		when num = 'twenty one' then @d - interval 21 day
		when num = 'twenty three' then @d - interval 23 day
		when num = 'twenty two' then @d - interval 22 day
		when num = 'two' then @d - interval 2 day
		when num is null then @d
    end postedDate
from (
	select
		timePosted
        ,jobTitle
        ,jobCompany
        ,jobLocation
        ,jobType
        ,classification
        ,subClassification
		,trim(case
			when timePosted like '%day%' then substring_index(substr(timePosted, 8), 'day', 1)
		end) num
	from jobs_no_duplicates
	) t
join jobs_no_duplicates j using(timePosted, jobTitle, jobCompany, jobLocation, jobType, classification, subClassification);
# return 405 rows

-- let's check if our data was imported nicely
select * from jobs_cleaned limit 10;
select count(*) from jobs_cleaned;
