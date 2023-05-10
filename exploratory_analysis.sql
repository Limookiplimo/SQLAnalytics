-- ====================================== ENTITIES AND ATTRIBUTES =========================================
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


-- ===================================== EXPLORATORY ANALYSIS ==============================================
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

 -- Monthly disbursement and collection 
with dis as (
    select
        disbursed_month,
        month_num,
        disbursed_year,
        SUM(price_unlock) as monthly_disbursement
    from (
        select
            a.id as account_id,
            DATE_PART('month', b.created_when::date) as month_num,
            to_char(b.created_when ::date, 'Month') as disbursed_month,
            DATE_PART('year', b.created_when ::date) as disbursed_year,
            b.price_unlock as price_unlock,
            substring(a.nominal_term from '"days":[ ]*([0-9]+)[ ]*')::integer as loan_duration_days,
            round(substring(a.nominal_term FROM '"days":[ ]*([0-9]+)[ ]*')::numeric /
            DATE_PART('day', DATE_TRUNC('month', a.registration_date::date + INTERVAL '1 MONTH') - DATE_TRUNC('month', a.registration_date::date))::numeric,1) as loan_duration_month
        from billings b
        inner join accounts a on a.billing_id = b.id
    ) as dis
    group by disbursed_year,disbursed_month,month_num
    order by disbursed_year,month_num
), 
coll as (
    select
        collection_year,
        collection_month,
        SUM(collected_payment) AS monthly_collection
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
        from payments p
        inner join accounts a on p.account_id = a.id
        inner join receipts r on p.receipt_id = r.id
        where
            r.amount >= 0
            and DATE_PART('year', r.effective_when::date) in (2022, 2023)
    ) as coll
    group by collection_year,collection_month,month_num
    order by collection_year,month_num
)
select
    dis.disbursed_month,
    dis.disbursed_year,
    dis.monthly_disbursement,
    coll.monthly_collection
from
    coll
right join dis on coll.collection_year = dis.disbursed_year and coll.collection_month = dis.disbursed_month
order by dis.disbursed_year,dis.month_num;

-- Product performance
select
	a.group_id as product_group,
	count(g.product_id) as product_id,
	sum(b.price_unlock) as sales
from accounts a
inner join "groups" g on a.group_id  = g.id
inner join billings b on a.billing_id = b.id 
group by product_group;

 -- ================================================ OVERALL COLLECTION RATE ======================================================
-- Thought Process
-- Principal balance
select price_unlock - price_upfront as principal_rem_balance
from billings b;

--Interest amount - (Assumption: daily rate 5% of 5% interest)
select round(rem_balance * (0.05/365) * down_payment_period,1) as interest_on_downpayment
from(
	select price_unlock - price_upfront as rem_balance,
	substring(b.down_payment_period from '"days":[ ]*([0-9]+)[ ]*')::integer as down_payment_period
	from billings b 
) as sub;

-- Remaning balance after downpayment
select round(rem_balance + down_payment_interest,0) as amount_due
from(
select
	price_unlock - price_upfront as rem_balance,
	substring(down_payment_period from '"days":[ ]*([0-9]+)[ ]*')::integer as down_payment_period,
	(price_unlock - price_upfront)  * (0.05/365) * (substring(down_payment_period from '"days":[ ]*([0-9]+)[ ]*')::integer) as down_payment_interest
from billings b2 
) as sub;

-- Number of Installments - (Assumption:monthly payment of installments)
select
	ceiling ((substring(a.nominal_term from '"days":[ ]*([0-9]+)[ ]*')::integer) / 30) as num_installments
from accounts a;

-- Next installment amount
select round(amount_due / (ceiling (loan_duration /30))) as first_installment_amount
from(
	select
		round(loan_amount - down_payment_amount + (rem_balance * (0.05/365) * down_payment_period),0) as amount_due,
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

-- Overall Collection Rate
with m_coll as (
	select
	  	collection_year,
	  	collection_month,
	  	SUM(collected_payment) AS monthly_collection
	from
	  (
	    select
	      DATE_PART('month', r.effective_when::date) as month_num,
	      to_char(r.effective_when::date, 'Month') as collection_month,
	      DATE_PART('year', r.effective_when::date) AS collection_year,
	      case
	        when r.currency = 'USD' and DATE_PART('year', r.effective_when::date) = 2022 then r.amount * 100
	        when r.currency = 'USD' and DATE_PART('year', r.effective_when::date) = 2023 then r.amount * 110
	        else r.amount
	      end as collected_payment
	    from payments p
	    inner join receipts r on p.receipt_id = r.id
	    where
	      r.amount >= 0
	      and DATE_PART('year', r.effective_when::date) in (2022, 2023)
	      and r.id not in (select
	      						p.receipt_id
							from payments p
							inner join receipts r on p.receipt_id  = r.id
							where r.amount not in (select b.price_upfront from billings b))
		) as sub
	group by collection_year,collection_month,month_num
	 order by collection_year,month_num
),
am_due as(
	select
		month_num,
		next_payment_month,
		next_payment_year,
		sum(round(amount_due / (ceiling (loan_duration /30)))) as monthly_due
	from(
		select
			next_payment_month,
			month_num,
			next_payment_year,
			round(loan_amount - down_payment_amount + (rem_balance * (0.05/365) * down_payment_period),0) as amount_due,
			loan_duration,			(rem_balance * (0.05/365) * down_payment_period) as down_payment_interest
		from(
			select
				DATE_PART('month', b.created_when::date) AS month_num,
				to_char(b.created_when ::date, 'Month') AS next_payment_month,
				DATE_PART('year', b.created_when ::date) AS next_payment_year,
				price_unlock as loan_amount,
				substring(a.nominal_term from '"days":[ ]*([0-9]+)[ ]*')::integer as loan_duration,
				price_upfront as down_payment_amount,
				price_unlock - price_upfront as rem_balance,
				substring(down_payment_period from '"days":[ ]*([0-9]+)[ ]*')::integer as down_payment_period
			from accounts a
			inner join billings b on a.billing_id = b.id
			) as sub1
		) as sub2
	group by next_payment_year,next_payment_month,month_num
	ORDER by next_payment_year,month_num
),
aggs as (
	select
		am_due.month_num,
	    m_coll.collection_year as year,
	  	m_coll.collection_month as month,
	  	m_coll.monthly_collection as monthly_collection,
	    am_due.monthly_due
	from m_coll
	right join am_due on m_coll.collection_year = am_due.next_payment_year and m_coll.collection_month = am_due.next_payment_month
	order by am_due.next_payment_year,am_due.next_payment_month
)
select
	aggs.year,
	aggs.month,
	round(aggs.monthly_collection/monthly_due) as collection_rate
from aggs
group by monthly_collection,monthly_due,year,month,month_num 
order by year,month_num;


-- ================================================== FIRST PAYMENT ON TIME =================================================
-- Thought Process
-- First installment date
select 
	created_when::date as down_payment_date,
	(NULLIF(created_when, '')::date + INTERVAL '30 DAY')::date as first_payment_date
from billings;

-- First installment amount
select round(amount_due / (ceiling (loan_duration /30))) as first_installment_amount
from(
	select
		round(loan_amount - down_payment_amount + (rem_balance * (0.05/365) * down_payment_period),0) as amount_due,
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


-- First payment on time
select
	account_id,
	first_installment_amount,
	first_payment_date,
	case 
		when actual_payment_date <= first_payment_date then 'On time' else 'Late'
	end as first_payment_status 
from(
	select
		account_id,
		round(amount_due / (ceiling (loan_duration /30))) as first_installment_amount,
		first_payment_date,
		actual_payment_date
from(
	select
		account_id,
		round(loan_amount - down_payment_amount + (rem_balance * (0.05/365) * down_payment_period),0) as amount_due,
		loan_duration,
		(rem_balance * (0.05/365) * down_payment_period) as down_payment_interest,
		actual_payment_date,
		first_payment_date
	from(
		select
			a.id as account_id,
			NULLIF(r.effective_when, '')::date as actual_payment_date,
			price_unlock as loan_amount,
			substring(a.nominal_term from '"days":[ ]*([0-9]+)[ ]*')::integer as loan_duration,
			price_upfront as down_payment_amount,
			price_unlock - price_upfront as rem_balance,
			substring(down_payment_period from '"days":[ ]*([0-9]+)[ ]*')::integer as down_payment_period,
			(NULLIF(b.created_when, '')::date + INTERVAL '30 DAY')::date as first_payment_date
		from payments p
		inner join receipts r on p.receipt_id = r.id
		inner join accounts a on p.account_id = a.id 
		inner join billings b on a.billing_id = b.id
		where r.amount <> b.price_upfront
		) as sub1
	) as sub2
) as sub3;


-- ===================================== THE END ==================================================



    







   
   