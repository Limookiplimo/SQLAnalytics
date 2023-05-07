# Take Home Assignement

## Data Analytics Engineer

### Problem Statement
With datasets provided, I am required to answer atleast the following business problems.
1. Prepare a `sales dashboard` (aggregated on a monthly basis) to show loan portfolio
performance. Include at least the following key metrics: `Overall Collection Rate` (OCR)
and `First Payment on Time` (FPOT). Definitions for these metrics can be found in the
Data Dictionary below.
2. Share your `insights` based on the previous step's dashboard.
3. We are interested in forming new or improved partnerships with Merchants that sell
products that positively impact portfolio health performance. Identify the `products` and
`merchants` that have the `best portfolio health performance`.
4. What `other data `would you like to have to provide more detailed insights? What
`questions arose` during the analysis?

### Introduction
In this interview, I have been tasked with analyzing Angaza's dataset about customer loaning transaction details. The dataset comprise of seven csv files that represent tables in a relational database. The problem statement is centered around understanding customer behaviour and product portfolio, a mandatory focus for business if they are to remain afloat and thrive in the market. With good understanding of product performance and their consumption trends, businesses are able to create robust marketing campaigns that deliver personalized experienced to each indicidual customer.

It is therefore of essence that a thorough analysis is conducted in to identify key metrics and powerful insights for data driven decision making.

### Dataset Assessment
Before deep dive into analysis, I took time to assess the dataset's viability to delivering desired insights. Apart from issues with  attribute naming conventions and some missing data entries, the dataset had minimal details about products' transaction details. .To ensure data integrity, I maintained the naming convention while designing its data model.

Since each dataset has a unique ID, I utilized conditional formatting to identify and highlight any duplicate ID numbers that may have occurred as a result of data collection or entry errors. Fortunately,there were no duplicate IDs.I used DBeaver to perform data validations such as ensuring data accuracy and consistency.

### Data Analysis
* Designing and implementation of data model
After designing a model with `ERD Lab` for the relational database;
![Data model](data_model/angaza.png)

I implemented the model on postgresql database using [this](data_model/angaza.sql) sql script.




