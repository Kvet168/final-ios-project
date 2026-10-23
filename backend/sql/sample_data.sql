--
-- PostgreSQL database dump
--

\restrict clqV55nzCJaxQzQ5QN0zyiLm3pckaYsQU8SM0l6a7EpPLrQMX6Tzm6NSLqq6e1M

-- Dumped from database version 16.15
-- Dumped by pg_dump version 16.15

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: currencies; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.currencies VALUES ('USD', 'US Dollar', '$', 1.0000, 'sample', '2026-10-22 14:29:25.112001+00');
INSERT INTO public.currencies VALUES ('KHR', 'Cambodian Riel', '៛', 4100.0000, 'sample', '2026-10-22 14:29:25.112001+00');
INSERT INTO public.currencies VALUES ('EUR', 'Euro', '€', 0.9200, 'sample', '2026-10-22 14:29:25.112001+00');
INSERT INTO public.currencies VALUES ('THB', 'Thai Baht', '฿', 35.5000, 'sample', '2026-10-22 14:29:25.112001+00');


--
-- Data for Name: destinations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.destinations VALUES ('d0000000-0000-0000-0000-000000000001', 'siem-reap', 'Siem Reap', 'Cambodia', 'Siem Reap Province', false, 'Gateway to the temples of Angkor.', 'Siem Reap is the base for exploring Angkor Wat and the surrounding temples, with night markets, cafes and day trips to the countryside.', 13.3671, 103.8448, NULL, NULL, 55.00, 'USD', 'Nov to Mar', NULL, NULL, '{temples,culture,history}', 100, true, true, NULL, '2026-10-22 14:29:25.112001+00', '2026-10-22 14:29:25.112001+00');
INSERT INTO public.destinations VALUES ('d0000000-0000-0000-0000-000000000002', 'phnom-penh', 'Phnom Penh', 'Cambodia', 'Phnom Penh', false, 'Capital city on the Mekong riverfront.', 'Phnom Penh combines French-colonial streets, the Royal Palace, museums and a lively riverside food scene.', 11.5564, 104.9282, NULL, NULL, 60.00, 'USD', 'Nov to Feb', NULL, NULL, '{city,museum,food}', 90, true, true, NULL, '2026-10-22 14:29:25.112001+00', '2026-10-22 14:29:25.112001+00');
INSERT INTO public.destinations VALUES ('d0000000-0000-0000-0000-000000000003', 'kampot', 'Kampot', 'Cambodia', 'Kampot Province', false, 'Riverside town known for pepper and relaxed pace.', 'Kampot is a slow-paced river town near Bokor National Park, salt fields and pepper farms.', 10.6104, 104.1815, NULL, NULL, 45.00, 'USD', 'Nov to Apr', NULL, NULL, '{river,nature,relaxed}', 60, false, true, NULL, '2026-10-22 14:29:25.112001+00', '2026-10-22 14:29:25.112001+00');


--
-- Data for Name: partners; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.partners VALUES ('aaaaaaaa-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333', 'Demo Hospitality Group', '2026-10-22 14:29:25.112001+00');


--
-- Data for Name: accommodations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.accommodations VALUES ('a0000000-0000-0000-0000-000000000001', 'angkor-garden-hotel', 'd0000000-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', 'Angkor Garden Hotel', 'hotel', 4, 'Quiet garden hotel ten minutes from the temples.', 'Street 20, Siem Reap', 13.36, 103.856, NULL, NULL, '14:00', '12:00', 48, 'Free cancellation up to 48 hours before check-in.', true, true, 0.1000, 0.0200, 4.40, 12, 55.00, true, NULL, '2026-10-22 14:29:25.112001+00', '2026-10-22 14:29:25.112001+00');
INSERT INTO public.accommodations VALUES ('a0000000-0000-0000-0000-000000000002', 'riverside-boutique-pp', 'd0000000-0000-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0000-000000000001', 'Riverside Boutique', 'boutique', 4, 'Boutique rooms on the Phnom Penh riverfront.', 'Sisowath Quay, Phnom Penh', 11.568, 104.933, NULL, NULL, '14:00', '12:00', 24, 'Free cancellation up to 24 hours before check-in.', false, false, 0.1000, 0.0200, 4.60, 20, 70.00, true, NULL, '2026-10-22 14:29:25.112001+00', '2026-10-22 14:29:25.112001+00');
INSERT INTO public.accommodations VALUES ('a0000000-0000-0000-0000-000000000003', 'kampot-river-guesthouse', 'd0000000-0000-0000-0000-000000000003', NULL, 'Kampot River Guesthouse', 'guesthouse', 2, 'Simple, friendly guesthouse beside the river.', 'Riverside Rd, Kampot', 10.609, 104.183, NULL, NULL, '14:00', '12:00', 0, 'Non-refundable.', true, true, 0.1000, 0.0200, 4.10, 5, 22.00, true, NULL, '2026-10-22 14:29:25.112001+00', '2026-10-22 14:29:25.112001+00');


--
-- Data for Name: amenities; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.amenities VALUES (1, 'wifi', 'Free Wi-Fi');
INSERT INTO public.amenities VALUES (2, 'pool', 'Swimming pool');
INSERT INTO public.amenities VALUES (3, 'spa', 'Spa');
INSERT INTO public.amenities VALUES (4, 'breakfast', 'Breakfast');
INSERT INTO public.amenities VALUES (5, 'aircon', 'Air conditioning');
INSERT INTO public.amenities VALUES (6, 'airport_shuttle', 'Airport shuttle');
INSERT INTO public.amenities VALUES (7, 'parking', 'Free parking');


--
-- Data for Name: accommodation_amenities; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.accommodation_amenities VALUES ('a0000000-0000-0000-0000-000000000001', 1);
INSERT INTO public.accommodation_amenities VALUES ('a0000000-0000-0000-0000-000000000002', 1);
INSERT INTO public.accommodation_amenities VALUES ('a0000000-0000-0000-0000-000000000003', 1);
INSERT INTO public.accommodation_amenities VALUES ('a0000000-0000-0000-0000-000000000001', 2);
INSERT INTO public.accommodation_amenities VALUES ('a0000000-0000-0000-0000-000000000002', 3);
INSERT INTO public.accommodation_amenities VALUES ('a0000000-0000-0000-0000-000000000001', 4);
INSERT INTO public.accommodation_amenities VALUES ('a0000000-0000-0000-0000-000000000003', 4);
INSERT INTO public.accommodation_amenities VALUES ('a0000000-0000-0000-0000-000000000001', 5);
INSERT INTO public.accommodation_amenities VALUES ('a0000000-0000-0000-0000-000000000002', 5);
INSERT INTO public.accommodation_amenities VALUES ('a0000000-0000-0000-0000-000000000001', 6);
INSERT INTO public.accommodation_amenities VALUES ('a0000000-0000-0000-0000-000000000003', 7);


--
-- Data for Name: attractions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.attractions VALUES ('46095293-d3bc-4e64-b77b-3728c9207c07', 'angkor-wat-sunrise', 'd0000000-0000-0000-0000-000000000001', 'attraction', 'temple', 'Angkor Wat at sunrise', 'The largest religious monument in the world.', 13.4125, 103.867, NULL, NULL, 37.00, 180, NULL, NULL, false, NULL, '{temple,sunrise}', true, true, NULL, '2026-10-22 14:29:25.112001+00', '2026-10-22 14:29:25.112001+00');
INSERT INTO public.attractions VALUES ('77207c13-beda-48a5-b287-25d86e5cffc4', 'royal-palace-phnom-penh', 'd0000000-0000-0000-0000-000000000002', 'attraction', 'landmark', 'Royal Palace', 'Residence of the King of Cambodia.', 11.564, 104.9312, NULL, NULL, 10.00, 90, NULL, NULL, false, NULL, '{palace}', true, true, NULL, '2026-10-22 14:29:25.112001+00', '2026-10-22 14:29:25.112001+00');
INSERT INTO public.attractions VALUES ('8da34b39-96c6-468f-879f-1f172b91a350', 'kampot-pepper-farm', 'd0000000-0000-0000-0000-000000000003', 'activity', 'tour', 'Pepper farm tour', 'Visit a working pepper plantation.', 10.65, 104.2, NULL, NULL, 5.00, 120, NULL, NULL, false, NULL, '{food,nature}', true, true, NULL, '2026-10-22 14:29:25.112001+00', '2026-10-22 14:29:25.112001+00');


--
-- Data for Name: related_destinations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.related_destinations VALUES ('d0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000002');
INSERT INTO public.related_destinations VALUES ('d0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000001');
INSERT INTO public.related_destinations VALUES ('d0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000003');
INSERT INTO public.related_destinations VALUES ('d0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000002');


--
-- Data for Name: room_types; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.room_types VALUES ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Deluxe Double', 'Garden view, queen bed.', 'queen', 2, 1, 28, 55.00, 6, true, NULL, '2026-10-22 14:29:25.112001+00');
INSERT INTO public.room_types VALUES ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Family Suite', 'Two beds and a sitting area.', 'twin', 4, 2, 45, 95.00, 3, true, NULL, '2026-10-22 14:29:25.112001+00');
INSERT INTO public.room_types VALUES ('b0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000002', 'River View King', 'King bed with river view.', 'king', 2, 0, 32, 70.00, 5, false, NULL, '2026-10-22 14:29:25.112001+00');
INSERT INTO public.room_types VALUES ('b0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000003', 'Standard Fan Room', 'Fan-cooled double room.', 'double', 2, 1, 18, 22.00, 4, true, NULL, '2026-10-22 14:29:25.112001+00');


--
-- Name: amenities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.amenities_id_seq', 7, true);


--
-- PostgreSQL database dump complete
--

\unrestrict clqV55nzCJaxQzQ5QN0zyiLm3pckaYsQU8SM0l6a7EpPLrQMX6Tzm6NSLqq6e1M

