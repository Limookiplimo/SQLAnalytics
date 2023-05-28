


> [Introduction](https://github.com/Limookiplimo/Data-analytics-interview/tree/master#introduction) <br>
> [Data Assessment](https://github.com/Limookiplimo/Data-analytics-interview/tree/master#dataset-assessment)<br>
> [Data Model](https://github.com/Limookiplimo/Data-analytics-interview/tree/master#data-model) <br>
> [Exploratory Data Analysis](https://github.com/Limookiplimo/Data-analytics-interview/tree/master#exploratory-data-analysis) <br>
> [Problem Statement](https://github.com/Limookiplimo/Data-analytics-interview/tree/master#problem-statement) <br>
> [SQL Analysis](https://github.com/Limookiplimo/Data-analytics-interview/blob/master/exploratory_analysis.sql) <br>
> [Assumptions](https://github.com/Limookiplimo/Data-analytics-interview/tree/master#assumptions) <br>


### Introduction
The dataset comprises of seven csv files that represent tables in a relational database. The problem statement is centered around understanding customer behaviour and products' portfolio, a mandatory focus for business if they are to remain afloat and thrive in the market. With good understanding of product performance and their consumption trends, businesses are able to create robust marketing campaigns that deliver personalized experienced to each individual customer.
It is therefore of essence that a thorough analysis is conducted in to identify key metrics and powerful insights for data driven decision making.

### Dataset Assessment
Before deep dive into analysis, I took time to assess the dataset's viability to delivering desired insights. Apart from issues with  attribute naming conventions and some missing data entries, the dataset had minimal details about products' transaction details. To ensure data integrity, I maintained the naming convention while designing its data model.

Since each dataset has a unique ID, I utilized conditional formatting to identify and highlight any duplicate ID numbers that may have occurred as a result of data collection or entry errors. Fortunately,there were no duplicate IDs. I used DBeaver to perform data validations such as ensuring data accuracy and consistency.

### Data Model
* Designing and implementation of data model

After designing the model below with `ERD Lab` for the relational database;
![Data model](data_model/angaza.png)

I implemented the model on postgresql database using [this](data_model/angaza.sql) sql script. With tables created, I populated the database with the dataset to begin my exploratory analysis.

###  Exploratory Data Analysis

* Are there receipt entries with negative amounts? How many are they?

```
select
	id,
	amount
from receipts r
where amount < 0;
```
The above query returns entries of receipt IDs registering distinct negative values of `-99999999`:

|id|amount|
|---|---|
|451105420|	-99999999|
|482758043|	-99999999|
|425184207|	-99999999|

There are _43_ entries of negative amounts. When aggregating payment collctions, knowledge about these negative amounts would prevent the mistake of manifesting false collections portfolio.

***

* What fiscal year does the data cover?
```
select
    distinct DATE_PART('year', r.effective_when::date) as year
from receipts r;
```
|year|
|---|
|2023.0|
|1900.0|
|2022.0|

The dataset captures transaction details from  the year `1900` which does not make sense for accounting purposes. There is need to consult reconciliation team for correction inorder to adjust overall callection rate.
```
select 
    count(r.id)
from receipts r 
where DATE_PART('year', r.effective_when::date) = 1900;
```
There are `30` counts of these entries amounting to `KES 13806`.

***

* What currencies are payments made on?
```
select 
	distinct currency 
from receipts r;
```
There are two distinct currencies captured.

|currency|
|---|
|KES|
|USD|

This should be taken into account when performing any aggregations involving payments.

***

* How much loan was disbursed to each merchant's account?
```
select 
	o.id as merchant_id,
	a.id as account_id,
	b.price_unlock as account_loan  
from organizations o 
inner join accounts a on o.id = a.organization_id
inner join billings b on a.billing_id = b.id
order by o.id; 
```

|merchant_id|account_id|account_loan
|---|---|---|
|1049|	5952204|	28050|
|1049|	5806425|	28005|
|1049|	5832935|	33189|
|1049|	5816465|	21550|
|1049|	5823812|	28005|

There are `1961` entries returned in the above format. It is evident from this output that a merchant can have multiple acoounts. This prompted me to check  each merchant's account_id count.

```
select 
	count(id) as count,
	organization_id as merchant_id 
from accounts a
group by organization_id
order by count(id) desc
limit 5;
```

|count|merchant_id|
|---|---|
|409|	1062|
|379|	1092|
|203|	1064|
|184|	1063|
|134|	1086|

The top five merchants with maximum count of loan accounts.

***

* What is the cumulative loan amount received received by each merchant?
```
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
order by sum(db.total_loan) desc
limit 5;
```
|merchant_id|merchant_loan|
|---|---|
|1062|	8886443|
|1092|	7988025|
|1063|	3819500|
|1086|	2785050|

Overally, there are `22` merchants who have received loan products from Angaza. The query above returns the first five customers with max cumulated loan disbursement.

***

* What is the total amount of payments received from each account?
```
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
```
The first five max account payments are:
|account_id|collected_payment|
|---|---|
|5905337	|119338|
|6040852	|115240|
|5969680	|104650|
|5929037	|90425|
|5796858	|85442|

***

* How do loan disbursement and collections compare overally?
```
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
```
|collected_payments|disbursed_loans|
|---|---|
|35163303|	42127670|

Overally, the amount of loaned products is higher than collected payments. This is fairly a normal scenario in institutions offering financial services.

***

* What is the overall collection per month?

```
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
  ```
The first month to register payment collection is August 2022 while the latest is April 2023.

|collection_year| collection_month| monthly_collection|
|---|---|---|
|2022.0|	August|   	3420711|
|2022.0|	September|	8101145|
|2022.0|	October|  	4796920|
|2022.0|	November| 	4136630|
|2022.0|	December| 	4639369|
|2023.0|	January|  	3941135|
|2023.0|	February| 	3236114|
|2023.0|	March|    	2278913|
|2023.0|	April|    	598560|

*** 

* Overall disbursment per month
```
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
```
|disbursed_month| disbursed_year| monthly_disbursement|
|---|---|---|
|June     	|2022.0|	286605|
|July     	|2022.0|	10374843|
|August   	|2022.0|	18353139|
|September	|2022.0|	5180796|
|October  	|2022.0|	1325850|
|November 	|2022.0|	4156159|
|December 	|2022.0|	121125|
|January  	|2023.0|	285425|
|February 	|2023.0|	699725|
|March    	|2023.0|	1261003|
|April    	|2023.0|	83000|

Unlike collections which began on August, disbursements are registered as from June 2022.

***




### Problem Statement
With datasets provided, I provided explicit answers to the following business problems:
1. Prepare a `sales dashboard` (aggregated on a monthly basis) to show loan portfolio
performance. Include at least the following key metrics: Overall Collection Rate (OCR)
and First Payment on Time (FPOT). Definitions for these metrics can be found in the
Data Dictionary below.

#### Sales Dashboard
I prepared a vizualization dashboard to show some key metrics on tableau.
![Dashboard](data_model/Dashboard.png)

The interactive dashboard can be found [here](https://public.tableau.com/app/profile/kiplimo.cornelius/viz/Angaza_16836926306780/Dashboard1)

2. Share your `insights` based on the previous step's dashboard.
	##### Insights
	I deduced the following insights after analyzing the data:
	* Price of a loan product does not affect purchase behavior of the product. It is evident that customers affiliate value of a product to their quality or ROI. While the average price of a product is `Kes.21482`, prices of about `65%` of the loan products purchased are above the average price.
	* The overall sales performance is in decline. The customers purchase power has seen a downfall of approximately `70%` from as from `July 2022` to `November 2022`. After a minimal slight incline in December, thhe turmoil continued at an average rate of `30%` to `April 2023`. This can be attributed to the global crisis affecting the financial economy.
	* The projection of overall collection rate is in tandem with sales. The inital collection was a success as the company registered `85%` collection between `August 2022` and `September 2022`. As from `October 2022` to `April 2023`, the collection rate has seen a decline of `75%`. It is important to note that reduction of collection rate does not necessarily mean a fail in debt collection since __you only collect what you sell__.
	* From `61854` registered payments, `15%` of the payments were within the agreed payment time. The `85%` payments though late, have been received. High prices could be a reason for late payments as customers are trying to convince consumers to try their products.
	* There are two customers whose purchases have been prolific all through. Customer id `1062` and `1092` combined purchases registered a significant figure of `40%` out of total sales between `August 2022` and `April 2023`. These could be among the initial customers who benefited greatly from the business and or their vision and mission align with the companies model from onset and thus their loyalty.


3. We are interested in forming new or improved partnerships with Merchants that sell
products that positively impact portfolio health performance. Identify the products and
merchants that have the `best portfolio health performance`. 

##### Product Portfolio
```
select
	g.product_id as product_id,
	count(g.product_id) as product_count,
	sum(b.price_unlock) as sales
from accounts a
inner join "groups" g on a.group_id  = g.id
inner join billings b on a.billing_id = b.id 
group by product_id
order by product_count desc;
```
 
 There is good number of products that have registered great sales within this period. The top ten of the products are:

|id |sales_count| total_sales|
|---|---|---|
|2954|	290|	6556462|
|2434|	194|	3692107|
|3112|	168|	2947315|
|2427|	130|	1978600|
|2435|	116|	2668330|
|2958|	104|	1935875|
|2948|	100|	2076514|
|2947|	95|	1396965|
|2945|	95|	1352536|
|3141|	|90|	2490449|

These products are are associated with different groups. since groups determines pricing of a product, the performance of top products could only be associated with values their consumers have placed on them. I believe the price factor has minimal impact on their sales performance.

4. What other data would you like to have to provide more detailed insights? What
`questions arose` during the analysis?
#### Arising Challenges
* Customer location
I strongly believe that given customers' premises location, the business can be able to analyze all market factors surrounding the customerrs. This makes it easy to tune key experiences for the customers thus improving on service delivery.
* Database issues
There is conflicting conventional naming system for some entities in the database. Date entities though in different tables are descriptive enough, some are even identically name. Proper data audit could also result in migrating some attributes to entites that are strongly related.
* Attrinute values
A few attributes have large fugures with negative values. There are receipts with dates dating back to __1900__. There is need to conduct database cleaning in order to eliminate analytical errors that can arise from these issues.

***

### Assumptions
The following assumptions were made during data analytics process:
* `5%` interest rate per annum was charged on peayments. This is because I needed to calculate total payments a customer is expected to pay which basically should be higher than the principal amount, which in this case is the loan amount.
* I also considered an assumption that customer is expected to make `Monthly payments` for the loan product purchased.
* While generating insights, I took an assumption that all customers face similar market conditions. This might render some bias in a real world market scenario.
