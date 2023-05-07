CREATE TABLE "public.accounts" (
	"group_id" integer NOT NULL,
	"id" serial NOT NULL,
	"NUMBER" integer NOT NULL,
	"payment_due_date" TIMESTAMP NOT NULL,
	"responsible_user_id" integer NOT NULL,
	"created_when" TIMESTAMP NOT NULL,
	"registration_date" TIMESTAMP NOT NULL,
	"billing_id" integer NOT NULL,
	"organization_id" integer NOT NULL,
	"is_testing" BOOLEAN NOT NULL,
	"total_unconsumed_money" integer NOT NULL,
	"nominal_term"  NOT NULL,
	CONSTRAINT "accounts_pk" PRIMARY KEY ("id")
) WITH (
  OIDS=FALSE
);



CREATE TABLE "public.billings" (
	"id" serial NOT NULL,
	"created_when" TIMESTAMP NOT NULL,
	"is_postpaid" BOOLEAN NOT NULL,
	"price_upfront" integer NOT NULL,
	"value_divisor" integer NOT NULL,
	"price_unlock" integer NOT NULL,
	"down_payment_period"  NOT NULL,
	CONSTRAINT "billings_pk" PRIMARY KEY ("id")
) WITH (
  OIDS=FALSE
);



CREATE TABLE "public.payments" (
	"id" serial NOT NULL,
	"network_state" varchar NOT NULL,
	"receipt_id" integer NOT NULL,
	"account_id" integer NOT NULL,
	"category" varchar NOT NULL,
	"is_down_payment"  NOT NULL,
	"is_testing" BOOLEAN NOT NULL,
	CONSTRAINT "payments_pk" PRIMARY KEY ("id")
) WITH (
  OIDS=FALSE
);



CREATE TABLE "public.receipts" (
	"id" serial NOT NULL,
	"currency" varchar NOT NULL,
	"effective_when" TIMESTAMP NOT NULL,
	"TYPE" varchar NOT NULL,
	"amount" integer NOT NULL,
	CONSTRAINT "receipts_pk" PRIMARY KEY ("id")
) WITH (
  OIDS=FALSE
);



CREATE TABLE "public.organizations" (
	"id" serial NOT NULL,
	"name" varchar NOT NULL,
	"agent_app_requires_gps" BOOLEAN NOT NULL,
	"created_when" TIMESTAMP NOT NULL,
	"support_user_id" integer NOT NULL,
	"default_currency" varchar NOT NULL,
	"registration_config_id" integer NOT NULL,
	"tier" varchar NOT NULL,
	CONSTRAINT "organizations_pk" PRIMARY KEY ("id")
) WITH (
  OIDS=FALSE
);



CREATE TABLE "public.groups" (
	"id" serial NOT NULL,
	"archive_id" integer NOT NULL,
	"registration_requires_approval" BOOLEAN NOT NULL,
	"created_when" TIMESTAMP NOT NULL,
	"product_id" integer NOT NULL,
	"currency" varchar NOT NULL,
	"is_testing" BOOLEAN NOT NULL,
	"upgrade_action" varchar NOT NULL,
	CONSTRAINT "groups_pk" PRIMARY KEY ("id")
) WITH (
  OIDS=FALSE
);



CREATE TABLE "public.products" (
	"id" serial NOT NULL,
	"created_when" TIMESTAMP NOT NULL,
	"unit_type" varchar NOT NULL,
	"name" varchar NOT NULL,
	CONSTRAINT "products_pk" PRIMARY KEY ("id")
) WITH (
  OIDS=FALSE
);



ALTER TABLE "accounts" ADD CONSTRAINT "accounts_fk0" FOREIGN KEY ("billing_id") REFERENCES "billings"("id");
ALTER TABLE "accounts" ADD CONSTRAINT "accounts_fk1" FOREIGN KEY ("organization_id") REFERENCES "organizations"("id");


ALTER TABLE "payments" ADD CONSTRAINT "payments_fk0" FOREIGN KEY ("receipt_id") REFERENCES "receipts"("id");
ALTER TABLE "payments" ADD CONSTRAINT "payments_fk1" FOREIGN KEY ("account_id") REFERENCES "accounts"("id");



ALTER TABLE "groups" ADD CONSTRAINT "groups_fk0" FOREIGN KEY ("product_id") REFERENCES "products"("id");









