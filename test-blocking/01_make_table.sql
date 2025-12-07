-- 1: Create table if not exists
CREATE TABLE IF NOT EXISTS test_table (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    value INT NOT NULL
);

-- 2: Insert 10 sample rows only if table was empty
INSERT INTO test_table (name, value)
SELECT 'Name ' || i, (i * 10)
FROM generate_series(1, 10) AS s(i)
WHERE NOT EXISTS (SELECT 1 FROM test_table);

-- 3: Show the data
SELECT * FROM test_table;


