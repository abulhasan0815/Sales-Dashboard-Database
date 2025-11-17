-- =========================================
-- queries.sql — Common Queries for the CRM
-- =========================================

-- ============================================================
-- 1. Find a customer by contact name (first or last name match)
-- ============================================================
SELECT *
FROM "customers"
WHERE "contact_name" LIKE '%John%';

-- ============================================================
-- 2. Find all customers from a specific province and country
-- ============================================================
SELECT *
FROM "customers"
WHERE "country" = 'Canada'
AND ("province" = 'NL' OR "province" = 'Newfoundland and Labrador');

-- ============================================================
-- 3. Find all orders for a given customer (by e-mail)
-- ============================================================
SELECT *
FROM "orders"
WHERE "customer_id" = (
    SELECT "customer_id"
    FROM "customers"
    WHERE "email" = 'alice17@gmail.com'
);

-- ============================================================
-- 4. Retrieve order details for a specific order
-- ============================================================
SELECT *
FROM "order_details"
WHERE "order_id" = 1;

-- ============================================================
-- 5. List all products in a specific category
-- ============================================================
SELECT *
FROM "products"
WHERE "category" = 'Electronics';

-- ============================================================
-- 6. View monthly sales summary (from the view)
-- ============================================================
SELECT *
FROM "monthly_sales_summary"
WHERE "year_month" = '2025-01';

-- ============================================================
-- 7. Find all order-details for a given product (by product name)
-- ============================================================
SELECT *
FROM "order_details"
WHERE "product_id" = (
    SELECT "product_id"
    FROM "products"
    WHERE "product_name" = 'Widget A'
);

-- ============================================================
-- 8. View performance of a specific sales rep
-- ============================================================
SELECT *
FROM "sales_team_performance"
WHERE "sales_rep_id" = 3;


-- ============================================================
-- 9. Get lifetime value for a specific customer
-- ============================================================
SELECT *
FROM "customer_lifetime_value"
WHERE "customer_id" = 5;


-- ============================================================
-- 10. Find total monthly sales per category
-- ============================================================
SELECT
    strftime('%Y-%m', "order_date") AS "month",
    "category",
    SUM("quantity" * "order_details"."unit_price" * (1 - "discount"/100)) AS "total_sales"
FROM "orders"
JOIN "order_details" ON "orders"."order_id" = "order_details"."order_id"
JOIN "products" ON "order_details"."product_id" = "products"."product_id"
WHERE "order_status" != 'Cancelled'
GROUP BY "month", "category"
ORDER BY "month", "category";

-- ============================================================
-- 11. Find top-performing sales reps by total revenue (last 30 days)
-- ============================================================
SELECT
    "sales_team"."sales_rep_id",
    "first_name",
    "last_name",
    SUM("quantity" * "order_details"."unit_price" * (1 - "discount"/100)) AS "total_revenue"
FROM "sales_team"
JOIN "orders" ON "sales_team"."sales_rep_id" = "orders"."sales_rep_id"
JOIN "order_details" ON "orders"."order_id" = "order_details"."order_id"
WHERE "order_status" != 'Cancelled'
  AND "order_date" >= DATE('now', '-30 days')
GROUP BY "sales_team"."sales_rep_id", "first_name", "last_name"
ORDER BY "total_revenue" DESC
LIMIT 10;

-- ============================================================
-- 12. Insert a new customer
-- ============================================================
INSERT INTO "customers"
("company_name", "contact_name", "email", "phone", "address",
 "city", "province", "postal_code", "country", "customer_type")
VALUES
('Acme Corp', 'John Doe', 'john.doe@acme.com', '555-1234', '123 Main St',
 'Toronto', 'Ontario', 'M4B 1B3', 'Canada', 'Enterprise');


-- ============================================================
-- 13. Insert a new sales representative
-- ============================================================
INSERT INTO "sales_team"
("first_name", "last_name", "email", "phone", "hire_date", "province",
 "manager_id", "base_salary", "commission_rate", "is_active")
VALUES
('Sarah', 'Collins', 'scollins@example.com', '555-9876',
 '2024-03-01', 'Ontario', NULL, 55000, 0.05, 1);


-- ============================================================
-- 14. Insert a new product
-- ============================================================
INSERT INTO "products"
("product_name", "category", "subcategory", "unit_price", "cost_price", "description")
VALUES
('Business Laptop', 'Electronics', 'Computers', 999.99, 650.00, 'High-performance laptop suitable for enterprises');


-- ============================================================
-- 15. Insert a new order
-- ============================================================
INSERT INTO "orders"
("customer_id", "sales_rep_id", "required_date",
 "payment_method", "payment_status")
VALUES
(1, 1, '2025-02-10', 'Credit Card', 'Pending');


-- ============================================================
-- 16. Insert order details for an order
-- ============================================================
INSERT INTO "order_details"
("order_id", "product_id", "quantity", "unit_price", "discount")
VALUES
(1, 1, 3, 999.99, 10);


-- ============================================================
-- 17. Insert a sales target entry
-- ============================================================
INSERT INTO "sales_targets"
("sales_rep_id", "target_period", "start_date", "end_date",
 "revenue_target", "product_category")
VALUES
(1, 'Monthly', '2025-02-01', '2025-02-28', 50000, 'Electronics');

-- ============================================================
-- 18. Deactivate a product (soft delete)
-- ============================================================
UPDATE "products"
SET "is_active" = 0
WHERE "product_name" = 'Widget A';

-- ============================================================
-- 19. Mark a customer inactive
-- ============================================================
UPDATE "customers"
SET "status" = 'Inactive'
WHERE "email" = 'alice@acme.com';

-- ============================================================
-- 20. Increase unit price of a product by 5 %
-- ============================================================
UPDATE "products"
SET "unit_price" = ROUND("unit_price" * 1.05, 2)
WHERE "product_name" = 'Widget A';

-- ============================================================
-- 21. Customer acquisition by month
-- ============================================================
SELECT strftime('%Y-%m', "created_date") AS 'signup_month',
       "customer_type",
       COUNT(*) AS 'new_customers'
FROM "customers"
GROUP BY strftime('%Y-%m', "created_date"), "customer_type"
ORDER BY 'signup_month' DESC;
