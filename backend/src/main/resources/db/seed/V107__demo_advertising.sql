-- Demo advertisers, campaigns, payments and statistics so the dashboards and the app show sponsored content straight away.
-- Remove this file (together with V100) from FLYWAY_LOCATIONS for a clean production database.

INSERT INTO users (id, email, password_hash, name, phone, role, preferred_currency, is_demo) VALUES
 ('b1000000-0000-4000-8000-000000000001', 'business.demo@demo.wayfarer.test', crypt('${demoPassword}', gen_salt('bf', 10)), 'Sreymom Chea', '+855 12 345 678', 'business', 'USD', true),
 ('b1000000-0000-4000-8000-000000000002', 'cafe.demo@demo.wayfarer.test',     crypt('${demoPassword}', gen_salt('bf', 10)), 'Vireak Sok',   '+855 77 222 333', 'business', 'USD', true),
 ('b1000000-0000-4000-8000-000000000003', 'camp.demo@demo.wayfarer.test',     crypt('${demoPassword}', gen_salt('bf', 10)), 'Dina Pich',    '+855 96 111 000', 'business', 'USD', true),
 ('b1000000-0000-4000-8000-000000000004', 'crab.demo@demo.wayfarer.test',     crypt('${demoPassword}', gen_salt('bf', 10)), 'Kosal Ung',    '+855 15 444 555', 'business', 'USD', true);

INSERT INTO businesses (id, user_id, name, name_km, category, description, description_km, phone, website, address, destination_id, verification_status, verified_at) VALUES
 ('b2000000-0000-4000-8000-000000000001', 'b1000000-0000-4000-8000-000000000001', 'Mekong Sunset Cruises', 'ទូកកម្សាន្តថ្ងៃលិចទន្លេមេគង្គ', 'tour_operator',
  'Small-group sunset cruises on the Tonle Sap and Mekong with local snacks and a guide.', 'ដំណើរកម្សាន្តលើទូកនៅពេលថ្ងៃលិច ជាក្រុមតូច មានអាហារសម្រន់ និងអ្នកណែនាំ។', '+855 12 345 678', 'https://example.com/mekong-sunset',
  'Sisowath Quay, Phnom Penh', (SELECT id FROM destinations WHERE slug = 'phnom-penh'), 'verified', now()),
 ('b2000000-0000-4000-8000-000000000002', 'b1000000-0000-4000-8000-000000000002', 'Angkor Garden Café', 'កាហ្វេសួនអង្គរ', 'cafe',
  'Specialty Cambodian coffee, brunch and baked goods in a garden courtyard, ten minutes from Pub Street.', 'កាហ្វេកម្ពុជាពិសេស អាហារពេលព្រឹក និងនំ នៅក្នុងសួនស្ងប់ស្ងាត់ ជិតផ្លូវ Pub Street។', '+855 77 222 333', 'https://example.com/angkor-garden',
  'Wat Bo Road, Siem Reap', (SELECT id FROM destinations WHERE slug = 'siem-reap'), 'verified', now()),
 ('b2000000-0000-4000-8000-000000000003', 'b1000000-0000-4000-8000-000000000003', 'Kampot Riverside Camp', 'ជំរំមាត់ទន្លេកំពត', 'camping',
  'Riverside tents and hammocks with kayaks, fireflies at night and a pepper-farm walk in the morning.', 'តង់ និងអង្រឹងមាត់ទន្លេ មានកាយ៉ាក់ ពន្លឺទ្វីតនៅពេលយប់ និងដើរកម្សាន្តចម្ការម្រេចពេលព្រឹក។', '+855 96 111 000', 'https://example.com/kampot-camp',
  'Teuk Chhou Road, Kampot', (SELECT id FROM destinations WHERE slug = 'kampot'), 'verified', now()),
 ('b2000000-0000-4000-8000-000000000004', 'b1000000-0000-4000-8000-000000000004', 'Kep Crab House', 'ភោជនីយដ្ឋានក្តាមកែប', 'restaurant',
  'Fresh Kep crab with Kampot pepper, straight from the market next door.', 'ក្តាមកែបស្រស់ជាមួយម្រេចកំពត ទិញផ្ទាល់ពីផ្សារក្បែរនោះ។', '+855 15 444 555', NULL, 'Crab Market, Kep',
  (SELECT id FROM destinations WHERE slug = 'kep'), 'pending', NULL);

-- Campaigns (dates are relative to the day the demo data is loaded)
INSERT INTO ad_campaigns (id, business_id, package_id, placement, status, title_en, title_km, body_en, body_km, offer_en, offer_km, article_en, article_km, image_url, cta_url,
                          target_destination_ids, keywords, festival_name_en, festival_name_km, start_date, end_date, units, price_usd, reviewed_at) VALUES
 ('b3000000-0000-4000-8000-000000000001', 'b2000000-0000-4000-8000-000000000001', (SELECT id FROM ad_packages WHERE code = 'homepage_banner'), 'homepage_banner', 'active',
  'Sunset river cruise', 'ដំណើរកម្សាន្តលើទូកពេលថ្ងៃលិច', 'Watch the sun go down over the Mekong from a small wooden boat.', 'មើលថ្ងៃលិចលើទន្លេមេគង្គពីទូកឈើតូច។', '2 for 1 on weekdays', 'ទិញ ១ បាន ២ ថ្ងៃធម្មតា', NULL, NULL,
  (SELECT cover_image FROM destinations WHERE slug = 'phnom-penh'), 'https://example.com/mekong-sunset', '{}', '{}', NULL, NULL, CURRENT_DATE - 6, CURRENT_DATE + 22, 4, 120.00, now() - interval '7 days'),
 ('b3000000-0000-4000-8000-000000000002', 'b2000000-0000-4000-8000-000000000002', (SELECT id FROM ad_packages WHERE code = 'homepage_banner'), 'homepage_banner', 'active',
  'Brunch in the garden', 'អាហារពេលព្រឹកក្នុងសួន', 'Cambodian coffee, fresh bread and mango smoothies after a sunrise at Angkor.', 'កាហ្វេកម្ពុជា នំបុ័ងស្រស់ និងស្មូធីស្វាយ បន្ទាប់ពីមើលថ្ងៃរះនៅអង្គរ។', '10% off for WAYFARER travellers', 'បញ្ចុះតម្លៃ ១០% សម្រាប់អ្នកដំណើរ WAYFARER', NULL, NULL,
  (SELECT cover_image FROM destinations WHERE slug = 'siem-reap'), 'https://example.com/angkor-garden', '{}', '{}', NULL, NULL, CURRENT_DATE - 3, CURRENT_DATE + 25, 4, 120.00, now() - interval '5 days'),
 ('b3000000-0000-4000-8000-000000000003', 'b2000000-0000-4000-8000-000000000003', (SELECT id FROM ad_packages WHERE code = 'featured_destination'), 'featured_destination', 'active',
  'Sleep by the Kampot river', 'ដេកនៅមាត់ទន្លេកំពត', 'Riverside tents, kayaks and fireflies, an hour from the sea.', 'តង់មាត់ទន្លេ កាយ៉ាក់ និងពន្លឺទ្វីត ឆ្ងាយពីសមុទ្រតែមួយម៉ោង។', 'Free kayak with 2 nights', 'កាយ៉ាក់ឥតគិតថ្លៃ ពេលស្នាក់ ២ យប់', NULL, NULL,
  (SELECT cover_image FROM destinations WHERE slug = 'kampot'), 'https://example.com/kampot-camp', ARRAY[(SELECT id FROM destinations WHERE slug = 'kampot'), (SELECT id FROM destinations WHERE slug = 'kep')], '{}', NULL, NULL, CURRENT_DATE - 2, CURRENT_DATE + 33, 6, 60.00, now() - interval '4 days'),
 ('b3000000-0000-4000-8000-000000000004', 'b2000000-0000-4000-8000-000000000001', (SELECT id FROM ad_packages WHERE code = 'featured_destination'), 'featured_destination', 'active',
  'Phnom Penh by boat', 'ភ្នំពេញតាមទូក', 'See the Royal Palace and riverfront from the water.', 'មើលព្រះបរមរាជវាំង និងមាត់ទន្លេពីលើទឹក។', NULL, NULL, NULL, NULL,
  (SELECT cover_image FROM destinations WHERE slug = 'phnom-penh'), 'https://example.com/mekong-sunset', ARRAY[(SELECT id FROM destinations WHERE slug = 'phnom-penh')], '{}', NULL, NULL, CURRENT_DATE - 5, CURRENT_DATE + 9, 3, 30.00, now() - interval '6 days'),
 ('b3000000-0000-4000-8000-000000000005', 'b2000000-0000-4000-8000-000000000002', (SELECT id FROM ad_packages WHERE code = 'top_search'), 'top_search', 'active',
  'Angkor Garden Café', 'កាហ្វេសួនអង្គរ', 'Specialty coffee and brunch, five minutes from the temples ticket office.', 'កាហ្វេពិសេស និងអាហារពេលព្រឹក ជិតការិយាល័យលក់សំបុត្រប្រាសាទ។', '10% off', 'បញ្ចុះតម្លៃ ១០%', NULL, NULL,
  (SELECT cover_image FROM destinations WHERE slug = 'siem-reap'), 'https://example.com/angkor-garden', ARRAY[(SELECT id FROM destinations WHERE slug = 'siem-reap')], ARRAY['coffee','cafe','brunch','breakfast','កាហ្វេ'], NULL, NULL, CURRENT_DATE - 3, CURRENT_DATE + 25, 4, 60.00, now() - interval '5 days'),
 ('b3000000-0000-4000-8000-000000000006', 'b2000000-0000-4000-8000-000000000003', (SELECT id FROM ad_packages WHERE code = 'sponsored_article'), 'sponsored_article', 'active',
  'A night under the fireflies in Kampot', 'យប់មួយក្រោមពន្លឺទ្វីតនៅកំពត', 'Why a riverside tent beats a hotel room on the southern coast.', 'ហេតុអ្វីតង់មាត់ទន្លេល្អជាងបន្ទប់សណ្ឋាគារនៅឆ្នេរខាងត្បូង។', NULL, NULL,
  E'Kampot is slow on purpose. By late afternoon the river turns copper, the kayaks come back in, and the camp starts to smell of woodsmoke and lemongrass.\n\nAt Kampot Riverside Camp the tents sit on a raised deck a few steps from the water. Dinner is a shared table of fish amok, pepper crab and rice from the farm next door. After dark, guides paddle small groups out to see the fireflies that gather in the mangroves.\n\nIn the morning, walk to a pepper farm before breakfast, then join the 10 o''clock kayak to the old salt fields. Pack light clothes, insect repellent and a small torch.',
  E'កំពតយឺតៗដោយចេតនា។ ពេលល្ងាច ទន្លេប្រែជាពណ៌ស្ពាន់ កាយ៉ាក់វិលត្រឡប់មកវិញ ហើយជំរំមានក្លិនផ្សែងឈើ និងស្លឹកស្ដៅ។\n\nនៅជំរំមាត់ទន្លេកំពត តង់ត្រូវបានតំឡើងលើយ៉ៅខ្ពស់ ជិតមាត់ទឹក។ អាហារពេលល្ងាចជាតុរួមមាន អាម៉ុកត្រី ក្តាមម្រេច និងបាយពីចម្ការជិតខាង។ ពេលយប់ អ្នកណែនាំនាំក្រុមតូចៗចេញទៅមើលពន្លឺទ្វីតនៅព្រៃកោងកាង។',
  (SELECT cover_image FROM destinations WHERE slug = 'kampot'), 'https://example.com/kampot-camp', ARRAY[(SELECT id FROM destinations WHERE slug = 'kampot')], '{}', NULL, NULL, CURRENT_DATE - 1, CURRENT_DATE + 29, 1, 20.00, now() - interval '3 days'),
 ('b3000000-0000-4000-8000-000000000007', 'b2000000-0000-4000-8000-000000000001', (SELECT id FROM ad_packages WHERE code = 'festival_campaign'), 'festival', 'active',
  'Water Festival river dinner', 'អាហារពេលល្ងាចលើទូកក្នុងបុណ្យអុំទូក', 'A front-row dinner cruise for the boat races, with a Khmer set menu.', 'ទូកអាហារពេលល្ងាចកន្លែងល្អសម្រាប់មើលការប្រណាំងទូក មានម្ហូបខ្មែរជាសេត។', 'Book 2, get a free drink', 'កក់ ២ ទទួលភេសជ្ជៈឥតគិតថ្លៃ', NULL, NULL,
  (SELECT cover_image FROM destinations WHERE slug = 'phnom-penh'), 'https://example.com/mekong-sunset', ARRAY[(SELECT id FROM destinations WHERE slug = 'phnom-penh')], '{}', 'Water Festival', 'បុណ្យអុំទូក', CURRENT_DATE - 1, CURRENT_DATE + 28, 1, 100.00, now() - interval '3 days'),
 -- queue states for the admin screens
 ('b3000000-0000-4000-8000-000000000008', 'b2000000-0000-4000-8000-000000000002', (SELECT id FROM ad_packages WHERE code = 'featured_destination'), 'featured_destination', 'pending_review',
  'Coffee that tastes of Cambodia', 'កាហ្វេដែលមានរសជាតិកម្ពុជា', 'Single-origin Mondulkiri beans, roasted in Siem Reap.', 'គ្រាប់កាហ្វេមណ្ឌលគិរី អាំងនៅសៀមរាប។', NULL, NULL, NULL, NULL,
  (SELECT cover_image FROM destinations WHERE slug = 'siem-reap'), 'https://example.com/angkor-garden', ARRAY[(SELECT id FROM destinations WHERE slug = 'siem-reap')], '{}', NULL, NULL, CURRENT_DATE + 7, CURRENT_DATE + 20, 2, 20.00, NULL),
 ('b3000000-0000-4000-8000-000000000009', 'b2000000-0000-4000-8000-000000000003', (SELECT id FROM ad_packages WHERE code = 'top_search'), 'top_search', 'payment_review',
  'Kampot camping', 'ជំរំនៅកំពត', 'Tents on the river with kayaks included.', 'តង់លើទន្លេ រួមមានកាយ៉ាក់។', NULL, NULL, NULL, NULL,
  (SELECT cover_image FROM destinations WHERE slug = 'kampot'), 'https://example.com/kampot-camp', ARRAY[(SELECT id FROM destinations WHERE slug = 'kampot')], ARRAY['camping','tent','kayak'], NULL, NULL, CURRENT_DATE + 3, CURRENT_DATE + 16, 2, 30.00, now() - interval '1 day'),
 ('b3000000-0000-4000-8000-00000000000a', 'b2000000-0000-4000-8000-000000000001', (SELECT id FROM ad_packages WHERE code = 'top_search'), 'top_search', 'awaiting_payment',
  'River cruises in Phnom Penh', 'ដំណើរកម្សាន្តលើទូកនៅភ្នំពេញ', 'Daily departures from Sisowath Quay.', 'ចេញដំណើរជារៀងរាល់ថ្ងៃពីមាត់ទន្លេ។', NULL, NULL, NULL, NULL,
  (SELECT cover_image FROM destinations WHERE slug = 'phnom-penh'), 'https://example.com/mekong-sunset', ARRAY[(SELECT id FROM destinations WHERE slug = 'phnom-penh')], ARRAY['cruise','boat','river'], NULL, NULL, CURRENT_DATE + 5, CURRENT_DATE + 11, 1, 15.00, now() - interval '12 hours');

-- Payments: verified for the live campaigns, one claimed waiting for the administrator
INSERT INTO ad_payments (campaign_id, business_id, reference, method, currency, amount_usd, amount_local, fx_rate, status, bank_txn_ref, claimed_at, verified_at, verified_by)
SELECT c.id, c.business_id, 'WF-AD-DEMO' || row_number() OVER (ORDER BY c.id), CASE WHEN row_number() OVER (ORDER BY c.id) % 2 = 0 THEN 'khqr' ELSE 'bank_transfer' END, 'USD',
       c.price_usd, c.price_usd, 4100, 'verified', 'DEMO-TXN-' || row_number() OVER (ORDER BY c.id), c.reviewed_at + interval '2 hours', c.reviewed_at + interval '6 hours', '7f46d742-bf01-456f-8e4f-348203e59afc'
FROM ad_campaigns c WHERE c.status = 'active';

INSERT INTO ad_payments (campaign_id, business_id, reference, method, currency, amount_usd, amount_local, fx_rate, status, bank_txn_ref, claimed_at)
VALUES ('b3000000-0000-4000-8000-000000000009', 'b2000000-0000-4000-8000-000000000003', 'WF-AD-DEMOCLM1', 'khqr', 'KHR', 30.00, 123000, 4100, 'claimed', 'ACL-77310452', now() - interval '3 hours');

-- Statistics for the past days of each live campaign
INSERT INTO ad_stats_daily (campaign_id, day, impressions, clicks)
SELECT c.id, g::date,
       (60 + (random() * 140))::int * CASE c.placement WHEN 'homepage_banner' THEN 4 WHEN 'top_search' THEN 1 ELSE 2 END,
       (2 + (random() * 9))::int * CASE c.placement WHEN 'homepage_banner' THEN 1 WHEN 'top_search' THEN 2 ELSE 1 END
FROM ad_campaigns c, generate_series(c.start_date, CURRENT_DATE - 1, interval '1 day') g
WHERE c.status = 'active';
