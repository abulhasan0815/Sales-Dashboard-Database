-- TO RESET THE Schema of database
-- Dropping any existing tables
DROP TABLE IF EXISTS 'sales_team';
DROP TABLE IF EXISTS 'sales_targets';
DROP TABLE IF EXISTS 'orders';
DROP TABLE IF EXISTS 'order_details';
DROP TABLE IF EXISTS 'products';
DROP TABLE IF EXISTS "customers";
-- Dropping any existing indexes
DROP INDEX IF EXISTS 'idx_orders_date';
DROP INDEX IF EXISTS 'idx_orders_customer';
DROP INDEX IF EXISTS 'idx_orders_rep';
DROP INDEX IF EXISTS 'idx_products_category';
DROP INDEX IF EXISTS 'idx_customers_region';
DROP INDEX IF EXISTS 'idx_order_details_product';

-- Dropping any existing views
DROP VIEW IF EXISTS 'monthly_sales_summary';
DROP VIEW IF EXISTS 'sales_team_performance';
DROP VIEW IF EXISTS 'customer_lifetime_value';
DROP VIEW IF EXISTS 'product_performance';

-- Cleaning  up unused space
VACUUM;

-- Represents any customers with the company
CREATE TABLE "customers" (
    "customer_id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "company_name" TEXT NOT NULL DEFAULT 'Individual',
    "contact_name" TEXT,
    "email" TEXT UNIQUE NOT NULL,
    "phone" TEXT,
    "address" TEXT,
    "city" TEXT,
    "province" TEXT,
    "postal_code" TEXT NOT NULL,
    "country" TEXT NOT NULL,
    "customer_type" TEXT CHECK("customer_type" IN ('Enterprise', 'SMB', 'Individual')) DEFAULT 'Individual',
    "created_date" NUMERIC DEFAULT CURRENT_DATE,
    "status" TEXT CHECK("status" IN ('Active', 'Inactive')) DEFAULT 'Active'
);

-- Represents the sales team of the company
CREATE TABLE "sales_team" (
    "sales_rep_id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "email" TEXT UNIQUE NOT NULL,
    "phone" TEXT,
    "hire_date" DATE NOT NULL,
    "province" TEXT NOT NULL,
    "manager_id" INTEGER,
    "order_id" INTEGER,
    "base_salary" REAL DEFAULT 0,
    "commission_rate" REAL DEFAULT 0.0,
    "is_active" BOOLEAN DEFAULT 1
    -- FOREIGN KEY ("manager_id") REFERENCES "sales_team"("sales_rep_id") ON DELETE CASCADE
);

-- Represents the products of the company
CREATE TABLE "products" (
    "product_id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "product_name" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "subcategory" TEXT,
    "unit_price" NUMERIC(10,2) NOT NULL CHECK("unit_price" >= 0),
    "cost_price" NUMERIC(10,2) NOT NULL CHECK("cost_price" >= 0),
    "description" TEXT,
    "is_active" BOOLEAN DEFAULT 1
);

-- Represents the orders of the company
CREATE TABLE "orders" (
    "order_id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "customer_id" INTEGER,
    "sales_rep_id" INTEGER,
    "order_date" NUMERIC DEFAULT CURRENT_DATE,
    "required_date" NUMERIC,
    "shipped_date" NUMERIC,
    "order_status" TEXT CHECK("order_status" IN ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled')) DEFAULT 'Pending',
    "payment_method" TEXT CHECK("payment_method" IN ('Credit Card', 'Bank Transfer', 'Cash', 'Other')),
    "payment_status" TEXT CHECK("payment_status" IN ('Pending', 'Completed', 'Failed', 'Refunded')) DEFAULT 'Pending',
    FOREIGN KEY ("sales_rep_id") REFERENCES "sales_team"("sales_rep_id") ON DELETE CASCADE,
    FOREIGN KEY ("customer_id") REFERENCES "customers"("customer_id") ON DELETE CASCADE
);

-- Represents the orders details of the company
CREATE TABLE "order_details" (
    "order_detail_id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "order_id" INTEGER,
    "product_id" INTEGER,
    "quantity" INTEGER NOT NULL CHECK("quantity" > 0),
    "unit_price" NUMERIC(10,2) NOT NULL CHECK("unit_price" >= 0),
    "discount" REAL DEFAULT 0.0 CHECK("discount" BETWEEN 0 AND 100),
    FOREIGN KEY ("order_id") REFERENCES "orders"("order_id") ON DELETE CASCADE,
    FOREIGN KEY ("product_id") REFERENCES "products"("product_id") ON DELETE CASCADE
);

-- Represents the sales targets of the company
CREATE TABLE "sales_targets" (
    "target_id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "sales_rep_id" INTEGER,
    "target_period" TEXT NOT NULL CHECK("target_period" IN ('Daily', 'Monthly', 'Quarterly', 'Annual')),
    "start_date" NUMERIC NOT NULL,
    "end_date" NUMERIC NOT NULL,
    "revenue_target" NUMERIC(12, 2) NOT NULL,
    "product_category" TEXT,
    FOREIGN KEY ("sales_rep_id") REFERENCES "sales_team"("sales_rep_id") ON DELETE CASCADE
);

-- Created indexes to speed common searches
CREATE INDEX "idx_orders_date" ON "orders"("order_date");
CREATE INDEX "idx_orders_customer" ON "orders"("customer_id");
CREATE INDEX "idx_orders_rep" ON "orders"("sales_rep_id");
CREATE INDEX "idx_products_category" ON "products"("category");
CREATE INDEX "idx_customers_region" ON "customers"("country", "province");
CREATE INDEX "idx_order_details_product" ON "order_details"("product_id");

-- Created common views often requested
CREATE VIEW "monthly_sales_summary" AS
SELECT strftime('%Y-%m', "order_date") as 'year_month', "products"."category", "customers"."country", "customers"."province",
       SUM("quantity" * "order_details"."unit_price" * (1 - "discount"/100)) AS 'total_sales',
       SUM("quantity" * ("order_details"."unit_price" * (1 - "discount"/100) - "cost_price")) AS 'total_profit',
       COUNT(DISTINCT "orders"."order_id") as 'order_count',
       COUNT(DISTINCT "orders"."customer_id") as 'customer_count'
FROM "orders"
JOIN "order_details" ON "orders"."order_id" = "order_details"."order_id"
JOIN "products" ON "order_details"."product_id" = "products"."product_id"
JOIN "customers" ON "orders"."customer_id" = "customers"."customer_id"
WHERE "order_status" != 'Cancelled'
GROUP BY "year_month", "products"."category", "customers"."province", "customers"."country";

CREATE VIEW "sales_team_performance" AS
SELECT "sales_team"."sales_rep_id",
       "first_name" || ' ' || "last_name" AS 'sales_rep_name',
       "sales_team"."province",
       COUNT(DISTINCT "orders"."order_id") AS 'total_orders',
       COUNT(DISTINCT "orders"."customer_id") as 'unique_customers',
       SUM("quantity" * "order_details"."unit_price" * (1 - "discount"/100)) AS 'total_sales',
       SUM("quantity" * ("order_details"."unit_price" * (1 - "discount"/100) - "cost_price")) AS 'total_profit',
       ROUND(AVG("quantity" * "order_details"."unit_price" * (1 - "discount"/100)), 2) AS 'avg_order_value',
       "commission_rate",
       (SUM("quantity" * "order_details"."unit_price" * (1 - "discount"/100)) * "commission_rate") AS 'estimated_commission'
FROM "sales_team"
LEFT JOIN "orders" ON "sales_team"."sales_rep_id" = "orders"."sales_rep_id"
LEFT JOIN "order_details" ON "orders"."order_id" = "order_details"."order_id"
LEFT JOIN "products" ON "order_details"."product_id" = "products"."product_id"
WHERE "orders"."order_status" != 'Cancelled' OR "orders"."order_status" IS NULL
GROUP BY "sales_team"."sales_rep_id", "sales_team"."first_name", "sales_team"."last_name", "sales_team"."province";

CREATE VIEW "customer_lifetime_value" AS
SELECT "customers"."customer_id",
       "company_name",
       "contact_name",
       "customer_type",
       "country",
       "state",
       COUNT(DISTINCT "orders"."order_id") AS 'total_orders',
       SUM("quantity" * "order_details"."unit_price" * (1 - "discount"/100)) AS 'total_spent',
       ROUND(AVG("quantity" * "order_details"."unit_price" * (1 - "discount"/100)), 2) AS 'avg_order_value',
       MIN("order_date") AS 'first_order_date',
       MAX("order_date") AS 'last_order_date',
       CASE
        WHEN COUNT(DISTINCT "orders"."order_id") >= 5 THEN 'VIP'
        WHEN COUNT(DISTINCT "orders"."order_id") >= 2 THEN 'Regular'
        ELSE 'New'
       END AS customer_tier
FROM "customers"
LEFT JOIN "orders" ON "customers"."customer_id" = "orders"."customer_id"
LEFT JOIN "order_details" ON "orders"."order_id" = "order_details"."order_id"
WHERE "orders"."order_status" != 'Cancelled' OR "orders"."order_status" IS NULL
GROUP BY "customers"."customer_id", "company_name", "contact_name", "customer_type", "country", "state";

CREATE VIEW "product_performance" AS
SELECT
    "products"."product_id",
    "product_name",
    "category",
    "subcategory",
    "products"."unit_price",
    "cost_price",
    ("products"."unit_price" - "cost_price") as 'unit_margin',
    SUM("order_details"."quantity") as 'total_units_sold',
    SUM("quantity" * "order_details"."unit_price" * (1 - "discount"/100)) AS 'total_revenue',
    SUM("quantity" * ("order_details"."unit_price" * (1 - "discount"/100) - "cost_price")) AS 'total_profit',
    COUNT(DISTINCT "orders"."order_id") AS 'times_ordered',
    COUNT(DISTINCT "orders"."customer_id") as 'unique_customers'
FROM "products"
LEFT JOIN "order_details" ON "products"."product_id" = "order_details"."product_id"
LEFT JOIN "orders" ON "order_details"."order_id" = "orders"."order_id"
WHERE "order"."order_status" != 'Cancelled' OR "order"."order_status" IS NULL
GROUP BY "products"."product_id", "product_name", "category", "subcategory", "products"."unit_price", "cost_price";
