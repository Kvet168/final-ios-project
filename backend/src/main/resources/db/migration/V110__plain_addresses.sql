-- Listings show the city as their address until partners enter a street address.
UPDATE accommodations SET address = regexp_replace(address, '^Sample address, ', '') WHERE address LIKE 'Sample address, %';
