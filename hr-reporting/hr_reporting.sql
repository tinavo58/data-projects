use HR;

show tables;

create table employees (
	employeeId int primary key
    ,gender varchar(10)
    ,dob date
    ,startDate date
    ,termDate date
    ,rate decimal(5,2)
    ,paymentGroup varchar(50)
    ,costCentre varchar(45)
    ,hours decimal(5,2)
    ,state varchar(3)
    ,status varchar(15)
);

select * from employees limit 10;

describe employees;

-- create table costCentre
create table costCentre
select
	distinct substr(costCentre, 6, 4) businessUnit
	,substring(costCentre, 11, 4) costCentre
    ,right(costCentre, length(costCentre) - instr(costCentre, ' ')) ccDescription
from employees
order by 1;

describe costCentre;

select distinct businessUnit, ccDescription
from costCentre
order by 1;

-- update table to have the correct data types
alter table costCentre
modify businessUnit int,
modify costCentre int primary key;

alter table costCentre
rename column costCentre to id;

-- create table buisnessUnit
create table businessUnit (
	businessUnit int primary key
    ,buDescription varchar(45)
);

alter table businessUnit
rename column businessUnit to id;

insert into businessUnit values
(1000, 'Corporate (CEO Office)'),
(1200, 'Finance'),
(1300, 'Capital'),
(1400, 'Risk'),
(1500, 'Technology'),
(1600, 'Operations'),
(1700, 'Customer'),
(1800, 'Data Analytics'),
(2000, 'People & Culture'),
(2200, 'Partnerships'),
(2400, 'Platform (Portfolio Services)');

insert into businessUnit values
(1100, 'Deputy CEO'),
(2300, 'Program Management Office');

alter table costCentre
add constraint bu_fk foreign key (businessUnit) references businessUnit(id) on delete set null on update cascade;

describe businessUnit;

select * from businessUnit;

/*
======================================================================================================
ANALYSIS
period target: September 2021
*/
-- max start date is 30/09/2021
select max(startDate)
from employees;

select distinct paymentGroup
from employees;

set @eom := '2021-10-01',
	@f := 'Female',
    @m := 'Male',
    @c := 'Contractors';

-- headcount in September 2021: 123 (excl Contractors)
-- new_hires: 7
-- leavers: 4
select
	count(*) all_staff
    ,(select count(*) from employees where startDate between @eom - interval 1 month and @eom - interval 1 day) new_hires
    ,(select count(*) from employees where termDate between @eom - interval 1 month and @eom - interval 1 day) leavers
from employees
where startDate < @eom
	and termDate is null
    and paymentGroup <> @c;
     
-- check turnover rate: 3.35%
select @eom - interval 1 month;
with cte as (
	select
		(select count(*)
			from employees
			where startDate < @eom - interval 1 month and termDate is null and paymentGroup <> @c) start_of_mth
		,(select count(*)
			from employees
			where startDate < @eom and termDate is null and paymentGroup <> @c) end_of_mth
		,(select count(*)
			from employees
			where termDate >= @eom - interval 1 month and termDate is not null and paymentGroup <> @c) term
	)
select
	concat(round(term / ((start_of_mth + end_of_mth) / 2) * 100, 2), '%')
from cte;

-- check tenure
set @sep_eom = '2021-09-30';

with cte as (
	select 
		case
			when startDate between @sep_eom - interval 6 month and @sep_eom then '< 6 mths'
			when startDate between @sep_eom - interval 1 year and @sep_eom - interval 6 month then '< 6 mths - 1 yr'
			when startDate between @sep_eom - interval 2 year and @sep_eom - interval 1 year then '< 1 - 2 yrs'
			when startDate between @sep_eom - interval 3 year and @sep_eom - interval 2 year then '< 2 - 3 yrs'
			when startDate between @sep_eom - interval 4 year and @sep_eom - interval 3 year then '< 3 - 4 yrs'
		end tenure
        ,case
			when startDate between @sep_eom - interval 6 month and @sep_eom then 1
			when startDate between @sep_eom - interval 1 year and @sep_eom - interval 6 month then 2
			when startDate between @sep_eom - interval 2 year and @sep_eom - interval 1 year then 3
			when startDate between @sep_eom - interval 3 year and @sep_eom - interval 2 year then 4
			when startDate between @sep_eom - interval 4 year and @sep_eom - interval 3 year then 5
		end tenure_ranking
		,count(*) employees
	from employees
	where
		startDate < @eom
		and termDate is null
		and paymentGroup <> @c
	group by 1, 2
	)
select
	tenure
    ,employees
    ,round(employees / (select count(*) from employees where startDate < @eom and termDate is null and paymentGroup <> @c) * 100) tenure_percentage
from cte
order by tenure_ranking;

-- check age profile
with age as (
	select
		year(from_days(datediff(@sep_eom, dob))) age
	from employees
    where startDate < @eom and termDate is null and paymentGroup <> @c
    ), 
    cte as (
	select
		case
			when age <= 35 then 1
			when age between 36 and 45 then 2
			else 3
		end age_ranking
		,case
			when age <= 35 then '> 20 - 35 yrs'
			when age between 36 and 45 then '> 35 - 45 yrs'
			else '> 45 yrs'
		end age_profile
		,count(*) employees
	from age
	group by 1, 2
    )
select
	age_profile
    ,employees
    ,round(employees / (select sum(employees) from cte) * 100)
from cte;

-- check overall gender
select
	sum(gender=@f) as female
    ,sum(gender=@m) as male
from employees
where startDate < @eom
	and termDate is null
    and paymentGroup <> @c
union
select
	concat(round(sum(gender=@f)/count(*) * 100), '%')
    ,concat(round(sum(gender=@m)/count(*) * 100), '%')
from employees
where startDate < @eom
	and termDate is null
    and paymentGroup <> @c;

-- check gender per business unit
select
	substring(costCentre, 6, 4) businessUnit
    ,buDescription
    ,sum(gender='Male') as male_count
    ,sum(gender='Female') as female_count
    ,round(sum(gender = 'Male') / (sum(gender = 'Female') + sum(gender = 'Male')) * 100) as male_perc
    ,round(sum(gender = 'Female') / (sum(gender = 'Female') + sum(gender = 'Male')) * 100) as female_perc
from employees e
join businessUnit b on b.id = substring(costCentre, 6, 4)
where
	startDate < '2020-10-01'
    and termDate is null
    and paymentGroup <> 'Contractors'
group by 1, 2
order by 2 desc;
	
-- check new hires count each month
select
	year(startDate) as year
    ,month(startDate) as month
    ,count(startDate) new_hires
    ,count(term)
from ( 
	select
		year(termDate) as year
        ,month(termDate) as month
        ,count(termDate) term
	from employees
    where termDate > '2020-09-30'
    group by year(termDate), month(termDate)
) t
join employees e on year(e.startDate) = t.year and month(e.startDate) = t.month
where startDate > '2020-09-30'
group by
	year(startDate)
    ,month(startDate)
order by year, month;
