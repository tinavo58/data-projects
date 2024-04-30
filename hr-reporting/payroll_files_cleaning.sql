use HR;

show tables;

-- alter table payrollaugust
-- rename py_august;

describe py_august;

-- delete from py_august;
-- truncate table py_august;
-- drop table py_september_cleansed;

show full columns from py_august;

select * from py_august limit 10;
select count(*) from py_august limit 10;

/*
since data provided/imported is not in the right the data type
let's transform the data so that it can be used for further reporting
	- create new tables with desired columns
    - data cleaning/transforming
    - insert data into the newly created table
*/

create table HR.py_august_cleansed (
	accountingDate date
    ,employeeCode int
    ,payCode varchar(30)
    ,rate decimal(10,2)
    ,hours decimal(8,2)
    ,amount decimal(7,2)
    ,businessUnit int
    ,costCentre INT
    ,location varchar(3)
);

-- check date
select
	DISTINCT str_to_date(`Accounting Date`, '%d/%m/%Y')
from py_august;

-- check paycode
select
	distinct Paycode
from py_august
order by 1;

select
	DISTINCT case
		when paycode like 'SG Contribution%' then 'Super Guarantee Contribution'
        when paycode like 'Super Fulfilment%' then 'Salary Sacrifice Super'
        when paycode like 'Deduction - Salary Sacrifice (Novated Motor Lease)' then 'Novated Motor Lease'
        else paycode
    end paycode
from py_august;

-- check rate
select
	max(len_rate)
from (
	select
		distinct rate
		,length(rate) len_rate
	from py_august
	where rate is not null
    ) t;

-- [test] update rate from blank '' to null to convert data type
update py_august
set rate = null
where rate='';

alter table py_august
modify rate decimal(8,2);

-- check max len paycode
select
	max(length(paycode))
    ,length('super guarantee contribution')
    ,length('salary sacrifice super')
from py_august;

-- check units
select
	units
from py_august
group by 1;

-- check amount
select
	replace(amount, '$', '') amount
from py_august;

select max(length(amount)) from py_august;

-- create function
drop function if exists remove_symbol;

delimiter $$
create function remove_symbol (text varchar(13))
-- returns decimal(7,2)
returns varchar(13)
deterministic
begin
	-- declare output decimal(7,2);
    declare output varchar(13);
    set output = replace(replace(replace(replace(text, '$', ''), ',', ''), '(', ''), ')', '');
    return output;
end$$
delimiter ;

select
	`PayCode`
	,amount
    ,case
		when amount=' ' then null
        else remove_symbol(amount)
	end
from py_august;

select
	DISTINCT amount
from py_august
order by 1 desc;

select * from py_august;
show columns from py_august_cleansed;

-- insert data into temp table
insert into py_august_cleansed(accountingDate, employeeCode, payCode, rate, hours, amount, businessUnit, costCentre, location)
select
	str_to_date(`Accounting Date`, '%d/%m/%Y')
    -- ,cast(`Employee Code` as unsigned)
    ,`Employee Code`
    ,case
		when paycode like 'SG Contribution%' then 'Super Guarantee Contribution'
        when paycode like 'Super Fulfilment%' then 'Salary Sacrifice Super'
        when paycode like 'Deduction - Salary Sacrifice (Novated Motor Lease)' then 'Novated Motor Lease'
        else paycode
    end
    ,case
		when rate='' then null
        else rate
    end
    ,case
		when hour='' then null
        else remove_symbol(hour)
    end
    ,case
		when amount=' ' then null # this is blank space
        else remove_symbol(amount)
	end
    ,substr(`Cost Centre`, 6, 4)
    ,substr(`Cost Centre`, 11, 4)
    ,location
from py_august;

-- check if inserted successfully
select * from py_august_cleansed limit 10;
select count(*) from py_august_cleansed;

/*
lets practice for another month
*/
drop table if exists py_september_cleansed;

create table py_september_cleansed
like py_august_cleansed;

show full columns from py_september_cleansed;

-- update paycode col
alter table py_september_cleansed
modify payCode varchar(35);

insert into py_september_cleansed
select
	str_to_date(`Accounting Date`, '%d/%m/%Y')
    -- ,cast(`Employee Code` as unsigned)
    ,`Employee Code`
    ,case
		when paycode like 'SG Contribution%' then 'Super Guarantee Contribution'
        when paycode like 'Super Fulfilment%' then 'Salary Sacrifice Super'
        when paycode like 'Deduction - Salary Sacrifice (Novated Motor Lease)' then 'Novated Motor Lease'
        else paycode
    end
    ,case
		when rate='' then null
        else rate
    end
    ,case
		when hour='' then null
        else remove_symbol(hour)
    end
    ,case
		when amount=' ' then null # this is blank space
        else remove_symbol(amount)
	end
    ,substr(`Cost Centre`, 6, 4)
    ,substr(`Cost Centre`, 11, 4)
    ,location
from py_september;

select distinct paycode, length(paycode) from py_september order by 2 desc;
select * from py_september_cleansed;

-- check if records are copied across
select
	'original' original_tbl
    ,count(*)
from py_september
union all
select
	'cleansed_records'
    ,count(*)
from py_september_cleansed;
    