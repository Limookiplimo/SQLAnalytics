select * from accounts a;
-- billings
select * from billings b;
-- payments
select * from payments p;
-- receipts
select * from receipts r;
-- organizations
select * from organizations o;
-- groups 
select * from "groups" g;
-- products
select * from products p;

-- =========================================HYPOTHESIS===========================================
-- ONE
select id,amount  from receipts r where amount < 0;
--451105420	-99999999
--482758043	-99999999
--425184207	-99999999
--367882624	-99999999
--374972083	-99999999
--474206058	-99999999
--433638048	-99999999
--429698280	-99999999
--484428105	-99999999
--408785220	-99999999
--476801369	-99999999

-- TWO
select distinct currency from "groups" g;
--KES

--THREE
select distinct currency from receipts r;
--KES
--USD

-- FOUR
select distinct DATE_PART('year', a.registration_date::date) from accounts a;
--2022.0
--2023.0

-- FIVE
select price_unlock from billings b where price_unlock < 1;


-- SIX
select a.organization_id  from accounts a where id = 6470896;

-- SEVEN
select distinct DATE_PART('year', r.effective_when::date) from receipts r;
--2023.0
--1900.0
--2022.0

-- EIGHT
select * from receipts r where DATE_PART('year', r.effective_when::date) = 1900;
--471285974	KES	1900-01-01 00:00:00.000000000	ANGAZA_IPN	567
--445826394	KES	1900-01-01 00:00:00.000000000	ANGAZA_IPN	500
--481312706	KES	1900-01-01 00:00:00.000000000	ANGAZA_IPN	70
--387914960	KES	1900-01-01 00:00:00.000000000	ANGAZA_IPN	600
--443968213	KES	1900-01-01 00:00:00.000000000	ANGAZA_IPN	707

-- NINE
select sum(amount) from receipts r where DATE_PART('year', r.effective_when::date) = 1900;
--13806

-- TEN
select
	count(p2.account_id),
	a.organization_id
from payments p2
inner join receipts r on p2 .receipt_id = r.id
inner join accounts a on p2.account_id = a.id 
where DATE_PART('year', r.effective_when::date) = 1900
group by a.organization_id 

-- ================================================================================================
-- Loan Disbursed to each merchant's account
select 
	o.id as merchant_id,
	a.id as account_id,
	b.price_unlock as account_loan  
from organizations o 
inner join accounts a on o.id = a.organization_id
inner join billings b on a.billing_id = b.id
order by o.id;


-- ===============================================================================================
-- Loan amount received received by each merchant
with disbursed_loan as(select 
	o.id as merchant_id,
	a.id as account_id,
	b.price_unlock as total_loan  
from organizations o 
inner join accounts a on o.id = a.organization_id
inner join billings b on a.billing_id = b.id
)
select 
	db.merchant_id as merchant_id,
	sum(db.total_loan) as merchant_loan 
from disbursed_loan db
group by merchant_id
order by sum(db.total_loan) desc;


-- ==============================================================================================
-- Total amount of payments collected from each merchant's account
select
	account_id,
	sum(payment) as collected_payment
from
	(select
	a.id as account_id,
	p.id as payment_id,
	r.id as receipt_id,
	case
        when r.currency = 'USD' and DATE_PART('year', r.effective_when::date) = 2022 then r.amount * 100
        when r.currency = 'USD' and DATE_PART('year', r.effective_when::date) = 2023 then r.amount * 110
        else r.amount
    end as  payment
from payments p
inner join accounts a on p.account_id = a.id
inner join receipts r on p.receipt_id = r.id
where r.amount >= 0) as payment_details
group by account_id
order by sum(payment) desc;


-- ===============================================================================================
-- How does loan disbursement and collections compare overally?
with pms as(
	select
		a.id as account_id,
		o.id as merchant_id,
		p.id as payment_id,
		r.id as receipt_id,
		case
	        when r.currency = 'USD' and DATE_PART('year', r.effective_when::date) = 2022 then r.amount * 100
	        when r.currency = 'USD' and DATE_PART('year', r.effective_when::date) = 2023 then r.amount * 110
	        else r.amount
	    end as  payment
	from payments p
	inner join accounts a on p.account_id = a.id
	inner join organizations o on a.organization_id = o.id 
	inner join receipts r on p.receipt_id = r.id
	where r.amount >= 0
),
lns as(
	select 
		o.id as merchant_id,
		a.id as account_id,
		b.price_unlock as total_loan  
	from organizations o 
	inner join accounts a on o.id = a.organization_id
	inner join billings b on a.billing_id = b.id
)
select 
  (select SUM(total_loan) from lns) as disbursed_loan,
  (select SUM(payment) from pms) as collected_payments;
 
-- ================================================================================================
-- Overall collection per month
select
  	collection_year,
  	collection_month,
  	SUM(collected_payment) AS monthly_collection
FROM
  (
    SELECT
      a.id AS account_id,
      DATE_PART('month', r.effective_when::date) AS month_num,
      to_char(r.effective_when::date, 'Month') as collection_month,
      DATE_PART('year', r.effective_when::date) AS collection_year,
      CASE
        WHEN r.currency = 'USD' AND DATE_PART('year', r.effective_when::date) = 2022 THEN r.amount * 100
        WHEN r.currency = 'USD' AND DATE_PART('year', r.effective_when::date) = 2023 THEN r.amount * 110
        ELSE r.amount
      END AS collected_payment
    FROM
      payments p
      INNER JOIN accounts a ON p.account_id = a.id
      INNER JOIN receipts r ON p.receipt_id = r.id
    WHERE
      r.amount >= 0
      AND DATE_PART('year', r.effective_when::date) IN (2022, 2023)
  ) AS coll
 group by
 collection_year,
 collection_month,
 month_num
ORDER BY
  collection_year,
  month_num;

-- =================================================================================================
 -- Overall disbursment per month
select
	disbursed_month,
	disbursed_year,
	sum(price_unlock) as monthly_disbursement
from(
	select
		a.id as account_id,
		DATE_PART('month', b.created_when::date) AS month_num,
		to_char(b.created_when ::date, 'Month') as disbursed_month,
		DATE_PART('year', b.created_when ::date) AS disbursed_year,
		b.price_unlock as price_unlock,
		substring(a.nominal_term from '"days":[ ]*([0-9]+)[ ]*')::integer AS loan_duration_days,
		round(substring(a.nominal_term from '"days":[ ]*([0-9]+)[ ]*')::numeric / 
		DATE_PART('day', DATE_TRUNC('month', a.registration_date::date + interval '1 month') - DATE_TRUNC('month', a.registration_date::date))::numeric,1)  AS loan_duration_month
	from billings b
	inner join accounts a on a.billing_id = b.id
	) as am_due
group by
 disbursed_year,
 disbursed_month,
 month_num
ORDER BY
  disbursed_year,
  month_num;

 -- =================================================================================================
 -- Monthly disbursement, collection and amount due 
 
WITH dis AS (
    SELECT
        disbursed_month,
        month_num,
        disbursed_year,
        SUM(price_unlock) AS monthly_disbursement
    FROM (
        SELECT
            a.id AS account_id,
            DATE_PART('month', b.created_when::date) AS month_num,
            to_char(b.created_when ::date, 'Month') AS disbursed_month,
            DATE_PART('year', b.created_when ::date) AS disbursed_year,
            b.price_unlock AS price_unlock,
            substring(a.nominal_term FROM '"days":[ ]*([0-9]+)[ ]*')::integer AS loan_duration_days,
            round(substring(a.nominal_term FROM '"days":[ ]*([0-9]+)[ ]*')::numeric /
            DATE_PART('day', DATE_TRUNC('month', a.registration_date::date + INTERVAL '1 MONTH') - DATE_TRUNC('month', a.registration_date::date))::numeric,1) AS loan_duration_month
        FROM
            billings b
            INNER JOIN accounts a ON a.billing_id = b.id
    ) AS am_due
    GROUP BY
        disbursed_year,
        disbursed_month,
        month_num
    ORDER BY
        disbursed_year,
        month_num
), coll AS (
    SELECT
        collection_year,
        collection_month,
        SUM(collected_payment) AS monthly_collection
    FROM (
        SELECT
            a.id AS account_id,
            DATE_PART('month', r.effective_when::date) AS month_num,
            to_char(r.effective_when::date, 'Month') AS collection_month,
            DATE_PART('year', r.effective_when::date) AS collection_year,
            CASE
                WHEN r.currency = 'USD' AND DATE_PART('year', r.effective_when::date) = 2022 THEN r.amount * 100
                WHEN r.currency = 'USD' AND DATE_PART('year', r.effective_when::date) = 2023 THEN r.amount * 110
                ELSE r.amount
            END AS collected_payment
        FROM
            payments p
            INNER JOIN accounts a ON p.account_id = a.id
            INNER JOIN receipts r ON p.receipt_id = r.id
        WHERE
            r.amount >= 0
            AND DATE_PART('year', r.effective_when::date) IN (2022, 2023)
    ) AS coll
    GROUP BY
        collection_year,
        collection_month,
        month_num
    ORDER BY
        collection_year,
        month_num
)
SELECT
    dis.disbursed_month,
    dis.disbursed_year,
    dis.monthly_disbursement,
    coll.monthly_collection,
    CASE
        WHEN coll.monthly_collection IS NULL THEN dis.monthly_disbursement
        WHEN coll.monthly_collection > dis.monthly_disbursement THEN dis.monthly_disbursement
        ELSE dis.monthly_disbursement - coll.monthly_collection
    END AS amount_due
FROM
    coll
    RIGHT JOIN dis ON coll.collection_year = dis.disbursed_year AND coll.collection_month = dis.disbursed_month
ORDER BY
    dis.disbursed_year,
    dis.month_num;
   
   
-- ===============================================================================================
-- Overall collection rate
/*
 * The overall collection rate equals to
 * total amount paid divided by amount due:
 * 
 * OCR = (T_A_P)/(A_D)
 * 
*/
   
 WITH dis AS (
    SELECT
        disbursed_month,
        month_num,
        disbursed_year,
        SUM(price_unlock) AS monthly_disbursement
    FROM (
        SELECT
            a.id AS account_id,
            DATE_PART('month', b.created_when::date) AS month_num,
            to_char(b.created_when ::date, 'Month') AS disbursed_month,
            DATE_PART('year', b.created_when ::date) AS disbursed_year,
            b.price_unlock AS price_unlock,
            substring(a.nominal_term FROM '"days":[ ]*([0-9]+)[ ]*')::integer AS loan_duration_days,
            round(substring(a.nominal_term FROM '"days":[ ]*([0-9]+)[ ]*')::numeric /
            DATE_PART('day', DATE_TRUNC('month', a.registration_date::date + INTERVAL '1 MONTH') - DATE_TRUNC('month', a.registration_date::date))::numeric,1) AS loan_duration_month
        FROM
            billings b
            INNER JOIN accounts a ON a.billing_id = b.id
    ) AS am_due
    GROUP BY
        disbursed_year,
        disbursed_month,
        month_num
    ORDER BY
        disbursed_year,
        month_num
), coll AS (
    SELECT
        collection_year,
        collection_month,
        SUM(collected_payment) AS monthly_collection
    FROM (
        SELECT
            a.id AS account_id,
            DATE_PART('month', r.effective_when::date) AS month_num,
            to_char(r.effective_when::date, 'Month') AS collection_month,
            DATE_PART('year', r.effective_when::date) AS collection_year,
            CASE
                WHEN r.currency = 'USD' AND DATE_PART('year', r.effective_when::date) = 2022 THEN r.amount * 100
                WHEN r.currency = 'USD' AND DATE_PART('year', r.effective_when::date) = 2023 THEN r.amount * 110
                ELSE r.amount
            END AS collected_payment
        FROM
            payments p
            INNER JOIN accounts a ON p.account_id = a.id
            INNER JOIN receipts r ON p.receipt_id = r.id
        WHERE
            r.amount >= 0
            AND DATE_PART('year', r.effective_when::date) IN (2022, 2023)
    ) AS coll
    GROUP BY
        collection_year,
        collection_month,
        month_num
    ORDER BY
        collection_year,
        month_num
),
aggs as (
	select
	    dis.disbursed_month as dm,
	    dis.disbursed_year as dy,
	    dis.monthly_disbursement as dmd,
	    coll.monthly_collection as dmc,
	    CASE
	        WHEN coll.monthly_collection IS NULL THEN dis.monthly_disbursement
	        WHEN coll.monthly_collection > dis.monthly_disbursement THEN dis.monthly_disbursement
	        ELSE dis.monthly_disbursement - coll.monthly_collection
	    END AS amount_due
	FROM
	    coll
	    RIGHT JOIN dis ON coll.collection_year = dis.disbursed_year AND coll.collection_month = dis.disbursed_month
	ORDER BY
	    dis.disbursed_year,
	    dis.month_num
)
select
	aggs.dm,
	aggs.dy,
	round(aggs.dmc / aggs.amount_due, 5) as ocr
from aggs;

-- ==================================================================================================
 -- First payment on time

WITH billing AS (
	SELECT
		a.billing_id,
		b.price_upfront AS downpayment,
		NULLIF(b.created_when, '')::date AS downpayment_date,
		substring(b.down_payment_period FROM '"days":[ ]*([0-9]+)[ ]*')::integer AS downpayment_period
	FROM accounts a
	INNER JOIN billings b ON a.billing_id = b.id
), pms_det AS (
	SELECT
		billing.downpayment_date,
		billing.downpayment_period,
		(billing.downpayment_date + interval '1 day' * billing.downpayment_period)::date AS payment_due
	FROM billing
), payments AS (
	SELECT
		p.receipt_id,
		p.account_id,
		NULLIF(r.effective_when, '')::date AS payment_date
	FROM payments p
	INNER JOIN receipts r ON p.receipt_id = r.id
	WHERE p.receipt_id NOT IN (
		SELECT p2.receipt_id
		FROM payments p2
		INNER JOIN accounts a2 ON p2.account_id = a2.id
		INNER JOIN billings b2 ON a2.billing_id = b2.id
		WHERE p2.receipt_id <> p.receipt_id
	)
)
SELECT
	payments.account_id,
	payments.receipt_id,
	CASE
		WHEN payments.payment_date <= pms_det.payment_due THEN 'YES'
		ELSE 'NO'
	END AS paid_on_time,
	pms_det.payment_due
FROM payments
CROSS JOIN pms_det
group by payments.account_id;


-- ===============================THE END=============================



    







   
   