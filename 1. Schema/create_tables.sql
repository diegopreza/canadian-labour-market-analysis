CREATE TABLE lfs_employment (
    id SERIAL PRIMARY KEY,
    ref_date DATE,
    geo VARCHAR(100),
    industry VARCHAR(200),
    sex VARCHAR(50),
    age_group VARCHAR(100),
    value NUMERIC(12,1)
);