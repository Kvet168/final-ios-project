-- Removes Thailand from the catalogue: its destinations, stays (rooms, reviews, bookings and payments on them), places, curated trips and guides,
-- and the Thai baht from the currency list. Destination-agnostic guides that merely mention Thailand (region-wide FAQs) are kept.
-- Numbered above the seed data (V100) so it also cleans a freshly seeded database. Safe to run when no Thailand data exists.
DO $$
DECLARE
  dest_ids uuid[];
  acc_ids  uuid[];
  att_ids  uuid[];
BEGIN
  SELECT coalesce(array_agg(id), '{}') INTO dest_ids FROM destinations WHERE country = 'Thailand';
  SELECT coalesce(array_agg(id), '{}') INTO acc_ids FROM accommodations WHERE destination_id = ANY(dest_ids);
  SELECT coalesce(array_agg(id), '{}') INTO att_ids FROM attractions WHERE destination_id = ANY(dest_ids);

  -- Money first: payments (their events cascade), then reviews and bookings on Thai stays (booking items and status events cascade).
  DELETE FROM payments WHERE booking_id IN (SELECT id FROM bookings WHERE accommodation_id = ANY(acc_ids));
  DELETE FROM reviews WHERE accommodation_id = ANY(acc_ids)
    OR booking_id IN (SELECT id FROM bookings WHERE accommodation_id = ANY(acc_ids));
  DELETE FROM bookings WHERE accommodation_id = ANY(acc_ids);

  -- Trips: every itinerary for a Thai destination, plus any stop elsewhere that points at a Thai place.
  DELETE FROM itinerary_items WHERE attraction_id = ANY(att_ids);
  DELETE FROM itineraries WHERE destination_id = ANY(dest_ids) OR accommodation_id = ANY(acc_ids);

  -- Saved items and guides.
  DELETE FROM wishlist_items WHERE ref_id = ANY(dest_ids) OR ref_id = ANY(acc_ids) OR ref_id = ANY(att_ids);
  DELETE FROM travel_documents WHERE destination_id = ANY(dest_ids);

  -- The catalogue itself (rooms, images, amenities and related-destination links cascade).
  DELETE FROM accommodations WHERE id = ANY(acc_ids);
  DELETE FROM attractions WHERE id = ANY(att_ids);
  DELETE FROM destinations WHERE id = ANY(dest_ids);

  -- Thai baht: nobody can pick it any more, and anyone who had it falls back to US dollars.
  UPDATE users SET preferred_currency = 'USD' WHERE preferred_currency = 'THB';
  DELETE FROM exchange_rate_snapshots WHERE code = 'THB';
  DELETE FROM currencies WHERE code = 'THB' AND NOT EXISTS (SELECT 1 FROM destinations WHERE currency = 'THB');
END $$;
