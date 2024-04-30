use HR;

select * from py_august_cleansed limit 10;

select distinct paycode from py_august_cleansed
order by paycode;

-- check august
with cte as (
	select
		employeeCode
		,maX(case when payCode = 'Gross Pay' then amount end) grossPay
		,max(case when payCode = 'Salary Sacrifice Super' then amount end) preTaxDeduction_SSS
        ,max(case when payCode = 'Novated Motor Lease' then amount end) preTaxDeduction_MV
		,max(case when payCode = 'Tax' then amount end) payg
        ,max(case when payCode = 'HELP' then amount end) help
		,max(case when payCode = 'Net Pay' then amount end) netPay
		,max(case when payCode = 'Super Guarantee Contribution' then amount end) sgc
	from py_august_cleansed
	group by employeeCode
    ),
    variance_check as (
	select
		employeeCode
		,grossPay - payg - help = netPay as variance_check
	from cte
	where grossPay - payg - help <> netPay
    )
select
	*
    ,netPay - (grossPay - payg - help) variance
from cte
where employeeCode in (select employeeCode from variance_check);

-- check september
with cte as (
	select
		employeeCode
		,maX(case when payCode = 'Gross Pay' then amount end) grossPay
		,max(case when payCode = 'Salary Sacrifice Super' then amount end) preTaxDeduction_SSS
        ,max(case when payCode = 'Novated Motor Lease' then amount end) preTaxDeduction_MV
		,max(case when payCode = 'Tax' then amount end) payg
        ,max(case when payCode = 'HELP' then amount end) help
		,max(case when payCode = 'Net Pay' then amount end) netPay
		,max(case when payCode = 'Super Guarantee Contribution' then amount end) sgc
	from py_september_cleansed
	group by employeeCode
    ),
    variance_check as (
	select
		employeeCode
		,grossPay - payg - help = netPay as variance_check
	from cte
	where grossPay - payg - help <> netPay
    )
select
	*
    ,netPay - (grossPay - payg - help) variance
from cte
where employeeCode in (select employeeCode from variance_check);

-- compare august vs september
with aug as (
	select
		employeeCode
        ,sum(coalesce(hours, 0)) hours
		,maX(case when payCode = 'Gross Pay' then amount end) grossPay
		,max(case when payCode = 'Salary Sacrifice Super' then amount end) preTaxDeduction_SSS
        ,max(case when payCode = 'Novated Motor Lease' then amount end) preTaxDeduction_MV
		,max(case when payCode = 'Tax' then amount end) payg
        ,max(case when payCode = 'HELP' then amount end) help
		,max(case when payCode = 'Net Pay' then amount end) netPay
		,max(case when payCode = 'Super Guarantee Contribution' then amount end) sgc
	from py_august_cleansed
	group by employeeCode
    ),
    sep as (
    select
		employeeCode
        ,sum(coalesce(hours, 0)) hours
		,maX(case when payCode = 'Gross Pay' then amount end) grossPay
		,max(case when payCode = 'Salary Sacrifice Super' then amount end) preTaxDeduction_SSS
        ,max(case when payCode = 'Novated Motor Lease' then amount end) preTaxDeduction_MV
		,max(case when payCode = 'Tax' then amount end) payg
        ,max(case when payCode = 'HELP' then amount end) help
		,max(case when payCode = 'Net Pay' then amount end) netPay
		,max(case when payCode = 'Super Guarantee Contribution' then amount end) sgc
	from py_september_cleansed
	group by employeeCode
    ),
    compare as (
	select
		employeeCode
		,a.hours aug_hrs
        ,0 sep_hrs
		,a.grossPay - s.grossPay variance
	from aug a
	left join sep s using(employeeCode)
	union
	select
		employeeCode
        ,0
		,s.hours
		,a.grossPay - s.grossPay
	from sep s
	left join aug a using(employeeCode)
    order by 1
    )
select
	employeeCode
    ,max(aug_hrs) as aug_hrs
    ,max(sep_hrs) as sep_hrs
    ,max(variance)
from compare
where variance <> 0 or variance is null
group by employeeCode;

-- check leave taken
select
	*
from py_august_cleansed
where payCode like '%leave%'
order by employeeCode;

select *
from py_august_cleansed
where employeeCode = 278;

select *
from py_august
where `Employee Code` = 278;

select
	distinct payCode
from py_august_cleansed
where 	payCode like '%leave%' 
		or payCode like '%lve%' 
        or payCode = 'Bank Holiday';
        
select
	businessUnit
    ,sum(if(payCode = 'Bank Holiday', hours, 0)) as bank_holiday
    ,sum(if(payCode = 'Birthday Leave', hours, 0)) as birthday_leave
    ,sum(if(payCode = 'Pers/Carer''s Lve Pd', hours, 0)) as personal_leave
    ,sum(if(payCode = 'Annual Leave', hours, 0)) as annual_leave
    -- ,sum(if(payCode = 'Govt Pd Parental Lve', hours, 0)) as govt_leave # there's no hours paid, only payment processed
    ,sum(if(payCode = 'Compassionate Leave', hours, 0)) as compassionate_leave
    ,sum(hours)
from py_august_cleansed
group by 1
order by 1;

