-- accounts
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


-- ===================================== EXPLORATORY ANALYSIS ============================================
-- Neg amounts
select 
    id,
    amount  
from receipts r 
where amount < 0;


-- Currencies
select 
    distinct currency 
from receipts r;


-- Registration year
select 
    distinct DATE_PART('year', a.registration_date::date) as registration_year
from accounts a;


-- Fiscal years
select 
    distinct DATE_PART('year', r.effective_when::date) as year
from receipts r;


-- 1900's transactions
select * 
from receipts r 
where DATE_PART('year', r.effective_when::date) = 1900;

-- Currency for transactions in the year '1900'
select 
	distinct currency 
from receipts r
where DATE_PART('year', r.effective_when::date) = 1900;


-- Total amount for 1900  
select 
    sum(amount)
from receipts r where DATE_PART('year', r.effective_when::date) = 1900;



-- Loan Disbursed to each merchant's account
select 
	o.id as merchant_id,
	a.id as account_id,
	b.price_unlock as account_loan  
from organizations o 
inner join accounts a on o.id = a.organization_id
inner join billings b on a.billing_id = b.id
order by o.id;


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
	(select SUM(payment) from pms) as collected_payments,
 	(select SUM(total_loan) from lns) as disbursed_loan;
 

-- Overall collection per month
select
  	collection_year,
  	collection_month,
  	SUM(collected_payment) AS monthly_collection
from
  (
    select
      a.id as account_id,
      DATE_PART('month', r.effective_when::date) as month_num,
      to_char(r.effective_when::date, 'Month') as collection_month,
      DATE_PART('year', r.effective_when::date) AS collection_year,
      case
        when r.currency = 'USD' and DATE_PART('year', r.effective_when::date) = 2022 then r.amount * 100
        when r.currency = 'USD' and DATE_PART('year', r.effective_when::date) = 2023 then r.amount * 110
        else r.amount
      end as collected_payment
    from
      payments p
      inner join accounts a on p.account_id = a.id
      inner join receipts r on p.receipt_id = r.id
    where
      r.amount >= 0
      and DATE_PART('year', r.effective_when::date) in (2022, 2023)
  ) as coll
 group by
 collection_year,
 collection_month,
 month_num
order by
  collection_year,
  month_num;


 -- Overall disbursment per month
select
	disbursed_month,
	disbursed_year,
	sum(price_unlock) as monthly_disbursement
from(
	select
		a.id as account_id,
		DATE_PART('month', b.created_when::date) as month_num,
		to_char(b.created_when ::date, 'Month') as disbursed_month,
		DATE_PART('year', b.created_when ::date) as disbursed_year,
		b.price_unlock as price_unlock,
		substring(a.nominal_term from '"days":[ ]*([0-9]+)[ ]*')::integer AS loan_duration_days,
		round(substring(a.nominal_term from '"days":[ ]*([0-9]+)[ ]*')::numeric / 
		DATE_PART('day', DATE_TRUNC('month', a.registration_date::date + interval '1 month') - DATE_TRUNC('month', a.registration_date::date))::numeric,1)  as loan_duration_month
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


 -- Monthly disbursement, collection and amount due 
 
with dis as (
    select
        disbursed_month,
        month_num,
        disbursed_year,
        SUM(price_unlock) AS monthly_disbursement
    from (
        select
            a.id as account_id,
            DATE_PART('month', b.created_when::date) as month_num,
            to_char(b.created_when ::date, 'Month') as disbursed_month,
            DATE_PART('year', b.created_when ::date) as disbursed_year,
            b.price_unlock as price_unlock,
            substring(a.nominal_term from '"days":[ ]*([0-9]+)[ ]*')::integer as loan_duration_days,
            round(substring(a.nominal_term from '"days":[ ]*([0-9]+)[ ]*')::numeric /
            DATE_PART('day', DATE_TRUNC('month', a.registration_date::date + INTERVAL '1 MONTH') - DATE_TRUNC('month', a.registration_date::date))::numeric,1) as loan_duration_month
        from
            billings b
            inner join accounts a on a.billing_id = b.id
    ) as am_due
    group by
        disbursed_year,
        disbursed_month,
        month_num
    order by
        disbursed_year,
        month_num
), coll as (
    select
        collection_year,
        collection_month,
        SUM(collected_payment) as monthly_collection
    from (
        select
            a.id as account_id,
            DATE_PART('month', r.effective_when::date) as month_num,
            to_char(r.effective_when::date, 'Month') as collection_month,
            DATE_PART('year', r.effective_when::date) as collection_year,
            case
                when r.currency = 'USD' and DATE_PART('year', r.effective_when::date) = 2022 then r.amount * 100
                when r.currency = 'USD' and DATE_PART('year', r.effective_when::date) = 2023 then r.amount * 110
                else r.amount
            end as collected_payment
        from
            payments p
            inner join accounts a on p.account_id = a.id
            inner join receipts r on p.receipt_id = r.id
        where
            r.amount >= 0
            and DATE_PART('year', r.effective_when::date) in (2022, 2023)
    ) as coll
    group by
        collection_year,
        collection_month,
        month_num
    order by
        collection_year,
        month_num
)
select
    dis.disbursed_month,
    dis.disbursed_year,
    dis.monthly_disbursement,
    coll.monthly_collection,
    case
        when coll.monthly_collection is null then dis.monthly_disbursement
        when coll.monthly_collection > dis.monthly_disbursement then dis.monthly_disbursement
        else dis.monthly_disbursement - coll.monthly_collection
    end as amount_due
from
    coll
    right join dis on coll.collection_year = dis.disbursed_year and coll.collection_month = dis.disbursed_month
order by
    dis.disbursed_year,
    dis.month_num;
   
 -- ==================================================== OCR ======================================================  
-- Overall collection rate

-- Principal balance
select price_unlock - price_upfront as principal_rem_balance
from billings b;

--Interest amount - assumptions(daily rate is 5%)
select round(rem_balance * (0.05/365) * down_payment_period,1) as interest_on_downpayment
from(
	select price_unlock - price_upfront as rem_balance,
	substring(b.down_payment_period from '"days":[ ]*([0-9]+)[ ]*')::integer as down_payment_period
	from billings b 
) as sub;

-- Remaning balance after downpayment
select round(price_unlock - price_upfront + down_payment_interest,0) as amount_due
from(
select
	price_unlock,
	price_upfront,
	price_unlock - price_upfront as rem_balance,
	substring(down_payment_period from '"days":[ ]*([0-9]+)[ ]*')::integer as down_payment_period,
	(price_unlock - price_upfront)  * (0.05/365) * (substring(down_payment_period from '"days":[ ]*([0-9]+)[ ]*')::integer) as down_payment_interest
from billings b2 
) as sub;

-- Installments - assumption(monthly installments)
select
	ceiling ((substring(a.nominal_term from '"days":[ ]*([0-9]+)[ ]*')::integer)/30) as num_installments
from accounts a;

-- Intallment amount(amount_due)
select round((loan_amount - down_payment_amount + down_payment_interest) / (ceiling (loan_duration /30))) as intallment_amount
from(
	select
		loan_amount,
		down_payment_amount,
		down_payment_period,
		loan_duration,
		(rem_balance * (0.05/365) * down_payment_period) as down_payment_interest
	from(
		select
			price_unlock as loan_amount,
			substring(a.nominal_term from '"days":[ ]*([0-9]+)[ ]*')::integer as loan_duration,
			price_upfront as down_payment_amount,
			price_unlock - price_upfront as rem_balance,
			substring(down_payment_period from '"days":[ ]*([0-9]+)[ ]*')::integer as down_payment_period
		from accounts a
		inner join billings b on a.billing_id = b.id 
		) as sub1
	) as sub2;

-- First due_payment after downpaymnet is paid
select 
	created_when::date as down_payment_date,
	(NULLIF(created_when, '')::date + INTERVAL '30 DAY')::date as first_payment_date
from billings;

-- ==================================================== FPOT ===========================================================
 -- First payment on time

-- First due_payment after downpaymnet is paid
select 
	created_when::date as down_payment_date,
	(NULLIF(created_when, '')::date + INTERVAL '30 DAY')::date as first_payment_date
from billings;




-- ===================================== THE END ==================================================



    







   
   