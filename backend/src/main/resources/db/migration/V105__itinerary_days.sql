-- Trips through several cities: each day of an itinerary now knows its own city, the stay for that night and, on the first
-- day in a new city, the estimated transfer from the previous one. Existing single-city trips are backfilled: every day is
-- in the trip's destination and sleeps at the trip's stay, except the last day (no night after it).
-- (A later migration that deletes destinations or stays must delete the itineraries that use them first, as V102 and V104 do.)
CREATE TABLE itinerary_days (
  itinerary_id      uuid          NOT NULL REFERENCES itineraries(id) ON DELETE CASCADE,
  day_index         integer       NOT NULL CHECK (day_index >= 1),
  destination_id    uuid          NOT NULL REFERENCES destinations(id),
  accommodation_id  uuid          REFERENCES accommodations(id),           -- the stay for that night; NULL on the last day or when none is booked
  transfer_from     text,                                                  -- previous city's name, only on the first day in a new city
  transfer_km       numeric(7,1),
  transfer_min      integer       NOT NULL DEFAULT 0,
  transfer_cost_usd numeric(10,2) NOT NULL DEFAULT 0,
  PRIMARY KEY (itinerary_id, day_index)
);
CREATE INDEX itinerary_days_destination_idx ON itinerary_days (destination_id);

INSERT INTO itinerary_days (itinerary_id, day_index, destination_id, accommodation_id)
SELECT i.id, d, i.destination_id, CASE WHEN d < i.num_days THEN i.accommodation_id END
FROM itineraries i CROSS JOIN LATERAL generate_series(1, i.num_days) AS d;
