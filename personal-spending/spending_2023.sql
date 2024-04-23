create database PersonalBanking;
use PersonalBanking;

-- reviewing data
describe transactions_2023;
select * from transactions_2023 limit 10;
/* -- returns
date -> text
transation_details -> text
withdrawals -> text (with `blank` records)
deposits -> text (with `blank` records)

as I'm only interested in my spending, thus only the following is needed
- transaction_date: date
- transaction_details: varchar(1064)
- withdrawals: decimal(7,2)

note: not all transactions were accurately extracted from the bankstatements
thus removing transactions that deem incorrect for this fun project
*/

-- ============================================================================================================
-- create new table
create table transactions_2023_cleaned (
	transaction_date date
    ,transaction_detail varchar(1000)
    ,withdrawal decimal(7,2)
);

-- add data
-- 501 records added
insert into transactions_2023_cleaned
select
	cast(date as date)
    ,transaction_details
    -- convert `blank` to null
	,if(withdrawals = 'blank', null, cast(withdrawals as decimal(7,2)))
from transactions_2023;

-- review cleaned table
select *
from transactions_2023_cleaned
limit 10;

-- as spending is my main focus, let's remove all `null` records in the cleaned table
-- 137 record(s) affected
delete from transactions_2023_cleaned
where withdrawal is null;

-- ============================================================================================================
-- let's check the transaction_detail and see if any transformation is required
select 
	transaction_detail
    ,count(transaction_detail) cnt
from transactions_2023_cleaned
group by transaction_detail
order by 1;

-- at quick glance, both `ANZ Internet Banking Payment` and `ANZ Mobile Banking Payment` are repeated with different 6-digits ref appended
-- ref is not critical in this case thus let's remove those ref numbers
update transactions_2023_cleaned
set transaction_detail = left(transaction_detail, regexp_instr(transaction_detail, '\\d{6}') - 2)
where regexp_instr(transaction_detail, '\\d{6}');

-- let's also remove the last 4 digit showing my card detail
update transactions_2023_cleaned
set transaction_detail = 'VISA DEBIT PURCHASE CARD'
where transaction_detail like '%xxxx';

-- there are 10 records of $1 which are not correct
-- thus removing for better analysis
delete from transactions_2023_cleaned
where withdrawal = 1;


/*
============================================================================================================
Exploratory Data Analysis - let's check out my spending in 2023
============================================================================================================
*/
-- number of withdrawal records
-- 354 records with an average spending of $115 per transaction
select
	count(*) total_records
    ,round(avg(withdrawal)) avg_spent
from transactions_2023_cleaned;

-- let's break it down into months
-- on average, I made about 32 withdrawal transactions each with min and max records were 12 & 48 in September and May respectively
with sub as (
	select
		monthname(transaction_date) month_
        ,count(transaction_date) records
	from transactions_2023_cleaned
    group by 1
    order by 1
)
select
	null
    ,(select month_ from sub where records = (select max(records) from sub)) max_mth
    ,(select month_ from sub where records = (select min(records) from sub)) min_mth
union all
select
    (select round(avg(records)) from sub) avg_records
    ,(select max(records) from sub) max_trans
    ,(select min(records) from sub) min_trans
;

-- based on the data, I spent the highest amount in May and the lowest in November
-- note: not all transactions are included (eg mid-Nov to Dec transactions were excluded)
-- however on average, my average max and min spendings were in Septemeber and January respectively
with cte as (
	select
		monthname(transaction_date) month
		,withdrawal
	from transactions_2023_cleaned
    )
select
	if(grouping(month), 'all months', month) month
    ,count(month) num_of_records
    ,sum(withdrawal) total_spent
    ,round(avg(withdrawal), 2) avg_spent
from cte
group by month with rollup;

-- min/max each month (excluding my rental payments)
select
	distinct monthname(transaction_date) month
    ,min(withdrawal) over (partition by month(transaction_date)) min_spent
    ,max(withdrawal) over (partition by month(transaction_date)) max_spent
from
	transactions_2023_cleaned
where withdrawal not in (530, 560);

-- let divide my spend into 3 categories
select
	case
		when withdrawal < 50 then '< $50'
        when withdrawal between 50 and 100 then 'within $50 - $100'
        when withdrawal > 100 then '> $100'
	end categories
    ,count(*) num_of_trans
    ,round(sum(withdrawal)) total_spent
    ,round(avg(withdrawal)) avg_spent
from transactions_2023_cleaned
where withdrawal not in (530, 560)
group by 1;

-- let look at this on a daily basis or weekday
select
	case
		when weekday(transaction_date) = 0 then 'Monday'
        when weekday(transaction_date) = 1 then 'Tuesday'
        when weekday(transaction_date) = 2 then 'Wednesday'
        when weekday(transaction_date) = 3 then 'Thursday'
        when weekday(transaction_date) = 4 then 'Friday'
        when weekday(transaction_date) = 5 then 'Saturday'
        when weekday(transaction_date) = 6 then 'Sunday'
    end weekday
    ,count(*) trans
from transactions_2023_cleaned
where withdrawal not in (530, 560)
group by 1 with rollup
order by 2 desc;

-- checking my monthly spending
with cte as (
	select
		month(transaction_date) month
		,count(*) trans
		,sum(withdrawal) spending
	from
		transactions_2023_cleaned
	group by 1
    )
select
	month
    ,spending
    ,spending - lag(spending) over () diff_each_month
    ,sum(spending) over (order by month) running_total
from cte;

with cte as (
	select
		month(transaction_date) month
        ,monthname(transaction_date) month_name
		,withdrawal
		,rank() over (partition by month(transaction_date) order by withdrawal desc) max_rank
		,rank() over (partition by month(transaction_date) order by withdrawal) min_rank
	from transactions_2023_cleaned
	where withdrawal not in (530, 560)
)
select
    (case
		when max_rank = 1 then 'max_spend' 
		when min_rank = 1 then 'min_spend'
    end) max_min
    ,max(case when month = 1 then withdrawal end) Jan
    ,max(case when month = 2 then withdrawal end) Feb
    ,max(case when month = 3 then withdrawal end) Mar
    ,max(case when month = 4 then withdrawal end) Apr
    ,max(case when month = 5 then withdrawal end) May
    ,max(case when month = 6 then withdrawal end) Jun
    ,max(case when month = 7 then withdrawal end) Jul
    ,max(case when month = 8 then withdrawal end) Aug
    ,max(case when month = 9 then withdrawal end) Sep
    ,max(case when month = 10 then withdrawal end) Oct
    ,max(case when month = 11 then withdrawal end) Nov
from cte
where max_rank = 1 or min_rank = 1
group by max_min;