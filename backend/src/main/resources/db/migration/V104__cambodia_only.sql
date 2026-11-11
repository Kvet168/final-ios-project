-- WAYFARER focuses on Cambodia: removes every destination outside Cambodia with its stays (rooms, reviews, bookings
-- and payments on them), places and restaurants, curated and saved trips, guides and saved items, the Vietnam-only FAQ,
-- and every currency except US dollars and Cambodian riel. Region-wide guides (etiquette, safety, packing) are kept.
-- Same approach as V102 (Thailand). Numbered above the seed data (V100) so it also cleans a freshly seeded database,
-- and safe to run when only Cambodian data exists.
DO $$
DECLARE
  dest_ids uuid[];
  acc_ids  uuid[];
  att_ids  uuid[];
BEGIN
  SELECT coalesce(array_agg(id), '{}') INTO dest_ids FROM destinations WHERE country <> 'Cambodia';
  SELECT coalesce(array_agg(id), '{}') INTO acc_ids FROM accommodations WHERE destination_id = ANY(dest_ids);
  SELECT coalesce(array_agg(id), '{}') INTO att_ids FROM attractions WHERE destination_id = ANY(dest_ids);

  -- Money first: payments (their events cascade), then reviews and bookings on those stays (items and status events cascade).
  DELETE FROM payments WHERE booking_id IN (SELECT id FROM bookings WHERE accommodation_id = ANY(acc_ids));
  DELETE FROM reviews WHERE accommodation_id = ANY(acc_ids)
    OR booking_id IN (SELECT id FROM bookings WHERE accommodation_id = ANY(acc_ids));
  DELETE FROM bookings WHERE accommodation_id = ANY(acc_ids);

  -- Trips: every itinerary for those destinations, plus any stop elsewhere that points at one of their places.
  DELETE FROM itinerary_items WHERE attraction_id = ANY(att_ids);
  DELETE FROM itineraries WHERE destination_id = ANY(dest_ids) OR accommodation_id = ANY(acc_ids);

  -- Saved items and guides (their search chunks cascade).
  DELETE FROM wishlist_items WHERE ref_id = ANY(dest_ids) OR ref_id = ANY(acc_ids) OR ref_id = ANY(att_ids);
  DELETE FROM travel_documents WHERE destination_id = ANY(dest_ids);
  DELETE FROM travel_documents WHERE destination_id IS NULL AND title ILIKE 'Vietnam practical FAQ%';

  -- The catalogue itself (rooms, images, amenities and related-destination links cascade).
  DELETE FROM accommodations WHERE id = ANY(acc_ids);
  DELETE FROM attractions WHERE id = ANY(att_ids);
  DELETE FROM destinations WHERE id = ANY(dest_ids);

  -- Currencies: US dollars and riel only. Anyone who had another one falls back to US dollars.
  UPDATE users SET preferred_currency = 'USD' WHERE preferred_currency NOT IN ('USD', 'KHR');
  DELETE FROM exchange_rate_snapshots WHERE code NOT IN ('USD', 'KHR');
  DELETE FROM currencies c WHERE c.code NOT IN ('USD', 'KHR') AND NOT EXISTS (SELECT 1 FROM destinations d WHERE d.currency = c.code);
END $$;
