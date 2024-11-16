CREATE TABLE IF NOT EXISTS employees (
    employee_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    position VARCHAR(50) NOT NULL,
    department VARCHAR(50) NOT NULL,
    salary NUMERIC(10, 2) NOT NULL,
    manager_id INT REFERENCES employees(employee_id)
);

-- Пример данных
INSERT INTO employees (name, position, department, salary, manager_id)
VALUES
    ('Alice Johnson', 'Manager', 'Sales', 85000, NULL),
    ('Bob Smith', 'Sales Associate', 'Sales', 50000, 1),
    ('Carol Lee', 'Sales Associate', 'Sales', 48000, 1),
    ('David Brown', 'Sales Intern', 'Sales', 30000, 2),
    ('Eve Davis', 'Developer', 'IT', 75000, NULL),
    ('Frank Miller', 'Intern', 'IT', 35000, 5);

SELECT * FROM employees LIMIT 5;

CREATE TABLE IF NOT EXISTS sales(
    sale_id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES employees(employee_id),
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    sale_date DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    price NUMERIC(10, 2) NOT NULL
);

-- Пример данных
INSERT INTO products (name, price)
VALUES
    ('Product A', 150.00),
    ('Product B', 200.00),
    ('Product C', 100.00);



-- HW 3
-- Дополнил таблицу sales
INSERT INTO sales (employee_id, product_id, quantity, sale_date)
VALUES
    (2, 1, 20, '2024-11-15'),
    (2, 2, 15, '2024-11-16'),
    (3, 1, 10, '2024-11-17'),
    (3, 3, 5, '2024-11-20'),
    (4, 2, 8, '2024-11-21'),
    (2, 1, 12, '2024-12-01'),
    (2, 1, 12, '2024-11-22'),
    (2, 1, 15, '2024-11-23');

-- Создание временной таблицы high_sales_products и вывод данных:
CREATE TEMPORARY TABLE high_sales_products AS
SELECT product_id, SUM(quantity) AS total_quantity
FROM sales
WHERE sale_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY product_id
HAVING SUM(quantity) > 10;

SELECT * FROM high_sales_products LIMIT 3;

-- Создание CTE employee_sales_stats и вывод сотрудников с количеством продаж выше среднего:
WITH employee_sales_stats AS (
    SELECT employee_id,
           COUNT(*) AS total_sales,
           AVG(quantity) AS avg_sales
    FROM sales
    WHERE sale_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY employee_id
)
SELECT employee_id, total_sales, avg_sales
FROM employee_sales_stats
WHERE total_sales > (SELECT AVG(total_sales) FROM employee_sales_stats) LIMIT 3;

-- Дополнил таблицу employees
INSERT INTO employees (name, position, department, salary, manager_id)
VALUES
    ('Dwayne Hardy', 'Sysadmin', 'IT', 35000, 5),
    ('Marshall Anderson', 'Developer', 'IT', 32000, 5),
    ('Wanda Mendoza', 'Developer', 'IT', 33000, 5);

-- Создание иерархической структуры сотрудников:
WITH RECURSIVE employee_hierarchy AS (
    SELECT employee_id, manager_id, 1 AS level
    FROM employees
    WHERE manager_id = 5 -- всё кто подчиненны id 5 (Eve Davis)
    UNION ALL
    SELECT e.employee_id, e.manager_id, eh.level + 1
    FROM employees e
    INNER JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT * FROM employee_hierarchy LIMIT 5;

-- Топ-3 продукта по количеству продаж за текущий и прошлый месяц:
WITH sales_current_month AS (
    SELECT product_id, SUM(quantity) AS total_quantity, 'current_month' AS period
    FROM sales
    WHERE date_trunc('month', sale_date) = date_trunc('month', CURRENT_DATE)
    GROUP BY product_id
),
sales_last_month AS (
    SELECT product_id, SUM(quantity) AS total_quantity, 'last_month' AS period
    FROM sales
    WHERE date_trunc('month', sale_date) = date_trunc('month', CURRENT_DATE - INTERVAL '1 month')
    GROUP BY product_id
),
combined_sales AS (
    SELECT * FROM sales_current_month
    UNION ALL
    SELECT * FROM sales_last_month
)
SELECT product_id, total_quantity, period
FROM combined_sales
ORDER BY total_quantity DESC LIMIT 3;

-- Создание индекса и проверка производительности с трассировкой:
CREATE INDEX idx_sales_employee_date ON sales (employee_id, sale_date);

EXPLAIN ANALYZE
SELECT employee_id, SUM(quantity) AS total_quantity
FROM sales GROUP BY employee_id;

-- Анализ запроса с использованием трассировки:
EXPLAIN ANALYZE
SELECT product_id, SUM(quantity) AS total_quantity
FROM sales
GROUP BY product_id;
