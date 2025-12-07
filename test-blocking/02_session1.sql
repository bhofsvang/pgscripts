BEGIN;
UPDATE test_table SET name = 'locked' WHERE id = 1;
-- Do NOT commit yet
