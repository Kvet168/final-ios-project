-- Integrity hardening on top of V1: automatic updated_at, extra indexes, and DB-level audit of role changes.

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_set_updated_at          BEFORE UPDATE ON users          FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER destinations_set_updated_at   BEFORE UPDATE ON destinations   FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER accommodations_set_updated_at BEFORE UPDATE ON accommodations FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER attractions_set_updated_at    BEFORE UPDATE ON attractions    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER bookings_set_updated_at       BEFORE UPDATE ON bookings       FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER payments_set_updated_at       BEFORE UPDATE ON payments       FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- A role can only change through an audited path, even if someone edits the table by hand.
CREATE OR REPLACE FUNCTION audit_role_change() RETURNS trigger AS $$
BEGIN
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    INSERT INTO audit_logs(actor_id, action, entity, entity_id, meta)
    VALUES (NULL, 'db.user_role_changed', 'user', NEW.id::text, jsonb_build_object('from', OLD.role, 'to', NEW.role));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_audit_role AFTER UPDATE OF role ON users FOR EACH ROW EXECUTE FUNCTION audit_role_change();

CREATE INDEX audit_logs_actor_idx      ON audit_logs (actor_id, created_at DESC);
CREATE INDEX audit_logs_entity_idx     ON audit_logs (entity, entity_id);
CREATE INDEX refresh_tokens_family_idx ON refresh_tokens (family_id);
CREATE INDEX payments_user_idx         ON payments (user_id, created_at DESC);
CREATE INDEX bookings_hold_idx         ON bookings (hold_expires_at) WHERE status = 'PENDING_CONFIRMATION';
CREATE INDEX destinations_active_pop_idx ON destinations (popularity DESC) WHERE deleted_at IS NULL;
