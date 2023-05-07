# Data Dictionary

### Definitions that develop the data model
● An entry in `accounts` represents a loan between Angaza and a customer (started on
the `registration_date`) to finance a retail sale of a smartphone.
○ Contains foreign keys to
■ organizations via `organization_id`
■ groups via `group_id`
■ billings via `billing_id`

● An entry in `organizations` represents a Merchant able to offer Angaza financing on
their products.
○ No foreign keys
● An entry in `groups` represents a pricing offer available to customers.
○ Contains foreign keys to:
■ products via `product_id`

● Records in `billings` represent the detailed payment rules of the account such as down
payment amount (`price_upfront`), how much time the down payment pays for
(`down_payment_period`) and the total amount of the loan (`price_unlock`)
○ No foreign keys
● An entry in `products` refers to a product SKU that can be sold on the platform
○ No foreign keys
● An entry in `payments` refers to an individual payment by our customers towards an
Account.
○ Contains foreign keys to:
■ accounts via `account_id`
■ receipts via `receipt_id`

● An entry in `receipts` contains information on the financial details of each payment.
○ No foreign keys
● A typical account pattern:
○ An Account is registered to a customer by an agent of one of our merchant
organizations. Upon registration, the agent sets the loan terms (including the
duration of the loan or the `nominal_term`), collects a down payment (or
`price_upfront`) and gives the client the device and their initial keycode, which
“enables” the device for a defined period of time.
○ Once the initial down payment period expires, the device shuts off and the
Account is said to be “disabled”.
○ Clients then make subsequent payments on their own schedule. Each
subsequent payment entitles the client to another keycode that enables their
device for a period of time defined by the formula above.
○ When a client makes a payment which causes their lifetime `amount` paid to
exceed the `price_unlock` value in the billings record, we send them a special
keycode which “unlocks” the device indefinitely.


## Key metrics
There are some Key Metrics that are asked about in the prompt. Here is how we define these
metrics:
● Overall Collection Rate (OCR): this is equal to the total amount paid divided by the
amount due on an ongoing basis based on the payment terms.
○ Amount due can be calculated by dividing the `price_unlock` with the duration of
the loan.

● First Payment on Time: this is a boolean field representing whether an account has
made the first payment (exclusive of the down payment) when it was due.
○ Date of expected payment can be calculated using the loan start date and the
down payment period.
○ Amount due can be calculated by dividing the `price_unlock` with the duration of
the loan.