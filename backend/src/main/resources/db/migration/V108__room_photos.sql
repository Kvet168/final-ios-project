-- Every room shows a photo. Rooms without one get a photo of their property (rotating through the property's gallery),
-- and the owner can replace it with the room's own photo at any time.
WITH ranked AS (
  SELECT r.id, r.accommodation_id, row_number() OVER (PARTITION BY r.accommodation_id ORDER BY r.base_price_usd, r.id) - 1 AS n
  FROM room_types r WHERE r.cover_image IS NULL AND r.deleted_at IS NULL
)
UPDATE room_types rt
SET cover_image = COALESCE(
      (SELECT (array_agg(i.url ORDER BY i.position, i.id))[(k.n % count(*))::int + 1]
         FROM accommodation_images i WHERE i.accommodation_id = k.accommodation_id),
      (SELECT a.cover_image FROM accommodations a WHERE a.id = k.accommodation_id))
FROM ranked k WHERE rt.id = k.id;
