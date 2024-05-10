-- check num of records
SELECT COUNT(*) FROM riskdetect;

SELECT * FROM riskdetect LIMIT 10;
SELECT * FROM rawRiskDetect LIMIT 10;

-- convert datetime column from text to date
-- by adding new column
ALTER TABLE riskdetect
ADD COLUMN TransactionDate DATE;

-- update column with values
SET SQL_SAFE_UPDATES = 0;
UPDATE riskdetect
SET TransactionDate = STR_TO_DATE(timestamp, "%d/%m/%Y %H:%i");
SET SQL_SAFE_UPDATES = 1;

-- practice create table
-- keeping raw data
CREATE TABLE rawRiskDetect (
	customerID INT NOT NULL,
	cardNumber INT NOT NULL,
	amount INT NOT NULL,
	transactionTakenTimestamp TEXT NOT NULL
);

-- update data type as cardNumber is out of range
ALTER TABLE rawRiskDetect
MODIFY cardNumber BIGINT NOT NULL;

-- copied data across
INSERT INTO rawRiskDetect
SELECT customerId, cardNumber, amount, timestamp FROM riskdetect;

-- drop unwanted column
ALTER TABLE riskdetect
DROP column timestamp;

-- create view for easy access
-- Q: to identify customers that made > 4 transaction with different accounts
-- on the same day (each transaction is worth > 10mil)
CREATE VIEW TrasactionGreaterThan10Mil
AS
SELECT *
FROM riskdetect
WHERE amount > 10000000;

SELECT * FROM TrasactionGreaterThan10Mil;

SELECT customerId, cardNumber, TransactionDate, COUNT(*) as count_of_transactions
FROM TrasactionGreaterThan10Mil
GROUP BY customerId, cardNumber, TransactionDate
HAVING count_of_transactions > 4;

###############################################################################################################################
show columns from riskdetect; # customerId, cardNumber, amount, TransactionDate
select count(*) from riskdetect; # 1648

-- number of tranx per customer
select
	customerId
    ,count(distinct cardNumber) n_transactions
from riskdetect
group by customerId
order by 2 desc;

-- tranx per day
select
	TransactionDate
    ,count(cardNumber)
from riskdetect
group by TransactionDate
order by 1;

-- check customers
select count(DISTINCT customerId) from riskdetect; # 111
select
	customerId
    ,count(cardNumber)
from riskdetect