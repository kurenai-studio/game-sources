-- The points ledger is append-only: a row is never changed. Rows can still be deleted, because
-- deleting an account removes its ledger with it (ON DELETE CASCADE).
CREATE FUNCTION "PointsLedger_guard_append_only"() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'PointsLedger % cannot be updated', OLD."id"
    USING ERRCODE = 'restrict_violation';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "PointsLedger_append_only"
  BEFORE UPDATE ON "PointsLedger"
  FOR EACH ROW EXECUTE FUNCTION "PointsLedger_guard_append_only"();
