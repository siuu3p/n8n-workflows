-- Baseline table for the Competitive Pricing Intelligence workflow.
-- Run once in the Postgres database the workflow's Postgres credential points at.
CREATE TABLE IF NOT EXISTS competitor_pricing (
  id             BIGSERIAL PRIMARY KEY,
  competitor     TEXT        NOT NULL,
  plan_name      TEXT        NOT NULL,
  price          NUMERIC,                -- NULL = custom / contact sales
  currency       TEXT,
  billing_period TEXT,
  features       JSONB       NOT NULL DEFAULT '[]'::jsonb,
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS competitor_pricing_competitor_idx
  ON competitor_pricing (competitor);
