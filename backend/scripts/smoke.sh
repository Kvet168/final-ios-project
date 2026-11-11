#!/usr/bin/env bash
# End-to-end smoke test against a running API with the seed data loaded. Usage: scripts/smoke.sh [base-url]
# Requires: curl, python3. Demo password comes from DEMO_PASSWORD (default matches application.yml).
set -u
BASE="${1:-http://localhost:8081}"
DEMO_PW="${DEMO_PASSWORD:-Wayfarer#Demo2026}"
PASS=0; FAIL=0
j() { python3 -c "import sys,json; d=json.load(sys.stdin); print(eval(sys.argv[1]))" "$1"; }
req() { # method path [token] [body]  -> sets BODY and CODE
  local m="$1" p="$2" t="${3:-}" b="${4:-}"
  local args=(-s -o /tmp/wf_body -w '%{http_code}' -X "$m" "$BASE$p" -H 'Content-Type: application/json')
  [ -n "$t" ] && args+=(-H "Authorization: Bearer $t")
  [ -n "$b" ] && args+=(-d "$b")
  CODE=$(curl "${args[@]}"); BODY=$(cat /tmp/wf_body)
}
check() { if [ "$CODE" = "$2" ]; then PASS=$((PASS+1)); echo "ok    $1 ($CODE)"; else FAIL=$((FAIL+1)); echo "FAIL  $1: expected $2 got $CODE: ${BODY:0:300}"; fi; }
check_any() { local name="$1"; shift; case " $* " in *" $CODE "*) PASS=$((PASS+1)); echo "ok    $name ($CODE)";; *) FAIL=$((FAIL+1)); echo "FAIL  $name: expected one of $* got $CODE: ${BODY:0:200}";; esac; }
upload() { # token file -> sets BODY and CODE
  CODE=$(curl -s -o /tmp/wf_body -w '%{http_code}' -X POST "$BASE/api/media" -H "Authorization: Bearer $1" -F "file=@$2"); BODY=$(cat /tmp/wf_body)
}
expect_eq() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); echo "ok    $1"; else FAIL=$((FAIL+1)); echo "FAIL  $1: expected '$3' got '$2'"; fi; }
login() { req POST /api/auth/login "" "{\"email\":\"$1\",\"password\":\"$DEMO_PW\"}"; echo "$BODY" | j "d['accessToken']"; }

EMAIL="smoke$(date +%s)@example.com"; PW="Smoke-test-12345"
# random dates inside the 180-day stock window so the script can be re-run on the same database
OFF=$((20 + RANDOM % 120)); STAMP=$(date +%s)
CI=$(python3 -c "import datetime;print(datetime.date.today()+datetime.timedelta(days=$OFF))")
CO=$(python3 -c "import datetime;print(datetime.date.today()+datetime.timedelta(days=$OFF+2))")

PDEST=$(curl -s "$BASE/api/destinations/phnom-penh" | j "d['id']")
echo "== system and public catalogue"
req GET /api/health;                                  check "health" 200
req GET /actuator/health;                             check "actuator health" 200
req GET /api/meta;                                    check "meta" 200
req GET /api/home;                                    check "home feed" 200
expect_eq "12 destinations seeded (Cambodia only)" "$(echo "$BODY" | j "d['counts']['destinations']")" "12"
req GET "/api/destinations?q=siem";                   check "destination search" 200
expect_eq "search finds siem-reap" "$(echo "$BODY" | j "d['items'][0]['slug']")" "siem-reap"
req GET /api/destinations/phnom-penh;                 check "destination detail" 200
req GET "/api/destinations/phnom-penh/attractions?kind=restaurant"; check "restaurant search" 200
req GET /api/destinations/phnom-penh/accommodations;  check "hotels in destination" 200
req GET "/api/attractions?category=temple&pageSize=3"; check "attraction search" 200
req GET "/api/locations/search?q=ang";                check "location search" 200
req POST /api/routes/estimate "" '{"points":[{"lat":11.55,"lng":104.92},{"lat":11.56,"lng":104.93}]}'; check "route estimate" 200
req POST /api/routes/estimate "" '{"points":[{"lat":11.55,"lng":104.92}]}'; check "route estimate needs 2 points -> 422" 422
req GET "/api/accommodations?destination=phnom-penh&sort=price_asc&checkIn=$CI&checkOut=$CO"; check "hotel + room search with dates" 200
SLUG=$(echo "$BODY" | j "d['items'][0]['slug']")
req GET "/api/accommodations/$SLUG?checkIn=$CI&checkOut=$CO"; check "hotel detail with room quotes" 200
req GET "/api/accommodations/$SLUG/availability?checkIn=$CI&checkOut=$CO"; check "availability" 200
req GET "/api/accommodations/$SLUG/reviews";          check "reviews" 200
req GET /api/documents;                               check "guides" 200
req GET /api/users/me;                                check "users/me without token -> 401" 401

echo "== auth"
req POST /api/auth/register "" "{\"email\":\"$EMAIL\",\"password\":\"short\",\"name\":\"Smoke\"}"; check "register weak password -> 422" 422
req POST /api/auth/register "" "{\"email\":\"$EMAIL\",\"password\":\"$PW\",\"name\":\"Smoke Tester\",\"role\":\"admin\"}"; check "register" 201
expect_eq "role is customer even if client sends admin" "$(echo "$BODY" | j "d['user']['role']")" "customer"
req POST /api/auth/register "" "{\"email\":\"$EMAIL\",\"password\":\"$PW\",\"name\":\"Smoke Tester\"}"; check "duplicate email -> 409" 409
req POST /api/auth/login "" "{\"email\":\"$EMAIL\",\"password\":\"wrong-password-1\"}"; check "wrong password -> 401" 401
req POST /api/auth/login "" "{\"email\":\"$EMAIL\",\"password\":\"$PW\"}"; check "login" 200
AT=$(echo "$BODY" | j "d['accessToken']"); RT=$(echo "$BODY" | j "d['refreshToken']")
req GET /api/users/me "$AT";                          check "users/me" 200
req PATCH /api/users/me "$AT" '{"name":"Smoke Renamed","preferredCurrency":"khr"}'; check "patch profile" 200
req GET /api/admin/users "$AT";                       check "customer on admin route -> 403" 403
req GET /api/partner/bookings "$AT";                  check "customer on partner route -> 403" 403
req POST /api/auth/refresh "" "{\"refreshToken\":\"$RT\"}"; check "refresh" 200
RT2=$(echo "$BODY" | j "d['refreshToken']")
req POST /api/auth/refresh "" "{\"refreshToken\":\"$RT\"}"; check "old refresh token reuse -> 401" 401
req POST /api/auth/refresh "" "{\"refreshToken\":\"$RT2\"}"; check "reuse revoked the whole family -> 401" 401
req POST /api/auth/login "" "{\"email\":\"$EMAIL\",\"password\":\"$PW\"}"; AT=$(echo "$BODY" | j "d['accessToken']"); RT=$(echo "$BODY" | j "d['refreshToken']")
req POST /api/auth/forgot-password "" "{\"email\":\"$EMAIL\"}"; check "forgot password" 200
RESET=$(echo "$BODY" | j "d.get('demoResetToken') or ''")
if [ -n "$RESET" ]; then
  req POST /api/auth/reset-password "" "{\"token\":\"$RESET\",\"password\":\"New-password-12345\"}"; check "reset password" 200
  req POST /api/auth/login "" "{\"email\":\"$EMAIL\",\"password\":\"New-password-12345\"}"; check "login with new password" 200
  AT=$(echo "$BODY" | j "d['accessToken']"); RT=$(echo "$BODY" | j "d['refreshToken']")
else
  echo "skip  reset password (production mode: the reset token is only sent by email)"
fi

echo "== roles"
STAFF=$(login staff1@demo.wayfarer.test); ADMIN=$(login admin@demo.wayfarer.test); PARTNER=$(login partner.pp@demo.wayfarer.test)
req GET /api/partner/accommodations "$PARTNER";       check "partner lists own hotels" 200
ROOM=$(echo "$BODY" | j "d['items'][0]['rooms'][0]['id']")
PSLUG=$(echo "$BODY" | j "d['items'][0]['slug']")
ROOMUNITS=$(echo "$BODY" | j "d['items'][0]['rooms'][0]['total_units']")
req GET /api/partner/analytics "$PARTNER";            check "partner analytics" 200
req GET /api/partner/bookings "$PARTNER";             check "partner bookings" 200

echo "== booking and payment (room of partner's hotel)"
req POST /api/bookings/quote "$AT" "{\"roomTypeId\":\"$ROOM\",\"checkIn\":\"$CI\",\"checkOut\":\"$CO\",\"rooms\":1}"; check "quote" 200
req POST /api/bookings "$AT" "{\"roomTypeId\":\"$ROOM\",\"checkIn\":\"2020-01-01\",\"checkOut\":\"2020-01-03\",\"rooms\":1,\"adults\":2,\"guestName\":\"Smoke\",\"guestEmail\":\"$EMAIL\"}"; check "past dates -> 422" 422
req POST /api/bookings "$AT" "{\"roomTypeId\":\"$ROOM\",\"checkIn\":\"$CI\",\"checkOut\":\"$CO\",\"rooms\":1,\"adults\":99,\"guestName\":\"Smoke\",\"guestEmail\":\"$EMAIL\"}"; check "invalid party size -> 422" 422
req POST /api/bookings "$AT" "{\"roomTypeId\":\"$ROOM\",\"checkIn\":\"$CI\",\"checkOut\":\"$CO\",\"rooms\":1,\"adults\":2,\"guestName\":\"Smoke\",\"guestEmail\":\"$EMAIL\"}"; check "create booking" 201
BID=$(echo "$BODY" | j "d['id']")
req POST /api/payments/intent "$AT" "{\"bookingId\":\"$BID\",\"idempotencyKey\":\"idem-$BID\"}"; check "payment intent" 201
PID=$(echo "$BODY" | j "d['id']")
req POST /api/payments/intent "$AT" "{\"bookingId\":\"$BID\",\"idempotencyKey\":\"idem-$BID\"}"; expect_eq "intent is idempotent" "$(echo "$BODY" | j "d['id']")" "$PID"
req POST /api/payments/webhook "" '{"id":"evt_x","type":"payment.succeeded","payment_ref":"x","amount_usd":1}'; check "webhook without signature -> 401" 401
req POST "/api/payments/$PID/simulate" "$AT" '{"outcome":"success"}'; check "simulate success" 200
req GET "/api/bookings/$BID" "$AT";                   expect_eq "CONFIRMED after payment" "$(echo "$BODY" | j "d['status']")" "CONFIRMED"
req GET "/api/bookings/$BID/receipt" "$AT";           check "receipt" 200
req GET /api/notifications "$AT";                     check "notifications" 200
req POST "/api/partner/bookings/$BID/transition" "$PARTNER" '{"to":"CHECKED_IN"}'; check "partner checks guest in" 200
req POST "/api/partner/bookings/$BID/transition" "$PARTNER" '{"to":"COMPLETED"}'; check "partner completes stay" 200

echo "== reviews (stay required, one per guest, moderation)"
req POST "/api/accommodations/$PSLUG/reviews" "$AT" '{"rating":5,"title":"Lovely stay","body":"Friendly staff and a spotless room."}'; check "review after stay" 201
RV=$(echo "$BODY" | j "d['id']")
req POST "/api/accommodations/$PSLUG/reviews" "$AT" '{"rating":4,"title":"Again","body":"Trying to review twice here."}'; check "second review -> 409" 409
req GET /api/users/me/reviews "$AT";                  check "my reviews" 200
req PATCH "/api/admin/reviews/$RV" "$STAFF" '{"status":"hidden"}'; check "staff hides review" 204

echo "== cancel and orders alias"
req POST "/api/bookings/$BID/cancel" "$AT";           check "cancel completed stay -> 409" 409
req POST /api/orders "$AT" "{\"roomTypeId\":\"$ROOM\",\"checkIn\":\"$CI\",\"checkOut\":\"$CO\",\"rooms\":1,\"adults\":2,\"guestName\":\"Smoke\",\"guestEmail\":\"$EMAIL\"}"; check "orders: create" 201
OID=$(echo "$BODY" | j "d['id']")
req GET "/api/orders/$OID" "$AT";                     check "orders: get" 200
req PATCH "/api/orders/$OID/status" "$AT" '{"status":"CONFIRMED"}'; check "orders: customer cannot confirm -> 403" 403
req PATCH "/api/orders/$OID/status" "$STAFF" '{"status":"CHECKED_IN"}'; check "orders: illegal jump -> 409" 409
req DELETE "/api/orders/$OID" "$AT";                  check "orders: delete (cancel)" 200
E2="smoke2$(date +%s)@example.com"
req POST /api/auth/register "" "{\"email\":\"$E2\",\"password\":\"$PW\",\"name\":\"Other Person\"}"; AT2=$(echo "$BODY" | j "d['accessToken']")
req GET "/api/bookings/$BID" "$AT2";                  check "other user's booking -> 404" 404

echo "== wishlist and search history"
DID=$(curl -s "$BASE/api/destinations/siem-reap" | j "d['id']")
req PUT "/api/wishlist/destination/$DID" "$AT";       check "wishlist add" 204
req GET /api/wishlist "$AT";                          expect_eq "wishlist has 1 item" "$(echo "$BODY" | j "len(d['items'])")" "1"
req PUT "/api/wishlist/destination/$DID" "$AT";       check "wishlist add again is idempotent" 204
req PUT "/api/wishlist/spaceship/$DID" "$AT";         check "wishlist bad kind -> 422" 422
req DELETE "/api/wishlist/destination/$DID" "$AT";    check "wishlist remove" 204
curl -s "$BASE/api/accommodations?q=riverside" -H "Authorization: Bearer $AT" >/dev/null
req GET /api/search-history "$AT";                    check "search history" 200

echo "== AI planner and assistant"
req GET /api/ai/status;                               check "ai status" 200
req POST /api/ai/travel-plan "" '{"prompt":"I have three days in Phnom Penh and $150"}'; check "travel plan from prompt" 200
expect_eq "plan has 3 days" "$(echo "$BODY" | j "len(d['plan']['days'])")" "3"
req POST /api/ai/travel-plan "" '{"prompt":"somewhere nice"}'; expect_eq "asks for missing info" "$(echo "$BODY" | j "d['status']")" "needs_more_info"
req POST /api/ai/travel-plan "" '{"prompt":"two days in Kampot","save":true}'; check "saving a plan needs sign-in -> 401" 401
req POST /api/ai/travel-plan "$AT" '{"prompt":"two days in Siem Reap, we love temples","save":true}'; check "plan saved as trip" 200
IID=$(echo "$BODY" | j "d['itineraryId']")
req POST /api/ai/assistant "" '{"question":"What is the best time to visit Siem Reap?"}'; check "assistant answers" 200
expect_eq "assistant is grounded" "$(echo "$BODY" | j "d['grounded']")" "True"
req POST /api/ai/assistant "" '{"question":"zzzz qqqq xxxx"}'; expect_eq "assistant refuses to guess" "$(echo "$BODY" | j "d['grounded']")" "False"
req POST /api/ai/recommendations "" '{"destination":"siem-reap","interests":["temples"]}'; check "recommendations" 200
req GET /api/ai/sources;                              check "ai sources" 200

echo "== trip through two cities"
req POST /api/ai/travel-plan "$AT" '{"prompt":"3 days in Kampot and 2 days in Siem Reap, 2 adults","save":true}'; check "two-city plan saved" 200
MID=$(echo "$BODY" | j "d['itineraryId']")
expect_eq "cities in the order named" "$(echo "$BODY" | j "[d['understood']['destination']] + d['understood']['alsoVisit']")" "['kampot', 'siem-reap']"
expect_eq "days follow the request" "$(echo "$BODY" | j "[x['destination']['slug'] for x in d['plan']['days']]")" "['kampot', 'kampot', 'kampot', 'siem-reap', 'siem-reap']"
expect_eq "transfer on the first day in the new city" "$(echo "$BODY" | j "[x['day'] for x in d['plan']['days'] if x.get('transfer')]")" "[4]"
expect_eq "a stay in each city" "$(echo "$BODY" | j "[l['destination'] for l in d['plan']['lodgings']]")" "['kampot', 'siem-reap']"
req GET "/api/itineraries/$MID" "$AT";                check "get saved two-city trip" 200
expect_eq "saved days keep their city" "$(echo "$BODY" | j "[x['destination']['slug'] for x in d['days']]")" "['kampot', 'kampot', 'kampot', 'siem-reap', 'siem-reap']"
req GET /api/itineraries "$AT";                       expect_eq "trip list names both cities" "$(echo "$BODY" | j "[i['destination_name'] for i in d['items'] if i['id'] == '$MID']")" "['Kampot · Siem Reap']"
req POST "/api/ai/travel-plan" "$AT" '{"prompt":"kampot and siemreap. for 5 days"}'; expect_eq "misspelt run-together names still give two cities" "$(echo "$BODY" | j "len(d['plan']['destinations'])")" "2"
SR_PLACE=$(curl -s "$BASE/api/destinations/siem-reap/attractions?pageSize=50" | j "[a['id'] for a in d['items']][0]")
KP_PLACE=$(curl -s "$BASE/api/destinations/kampot/attractions?pageSize=5" | j "d['items'][0]['id']")
req PATCH "/api/itineraries/$MID" "$AT" "{\"days\":[{\"day\":5,\"items\":[{\"attractionId\":\"$KP_PLACE\"}]}]}"; check "a Kampot place cannot go on a Siem Reap day -> 422" 422
req POST "/api/itineraries/$MID/generate" "$AT" '{"day":4}'; check "regenerate the arrival day" 200
expect_eq "arrival day stays in Siem Reap" "$(echo "$BODY" | j "d['days'][3]['destination']['slug']")" "siem-reap"
req POST "/api/itineraries/$MID/recalculate" "$AT";   check "recalculate the two-city trip" 200
req POST "/api/itineraries/$MID/copy" "$AT";          check "copy keeps the cities" 201
expect_eq "copy has both cities" "$(echo "$BODY" | j "sorted({x['destination']['slug'] for x in d['days']})")" "['kampot', 'siem-reap']"
req DELETE "/api/itineraries/$MID" "$AT";             check "delete the two-city trip" 204

echo "== itineraries"
req GET "/api/itineraries/$IID" "$AT";                check "get saved trip" 200
req GET "/api/itineraries/$IID" "$AT2";               check "other user cannot read it -> 404" 404
req GET /api/itineraries "$AT";                       check "list trips" 200
req PATCH "/api/itineraries/$IID" "$AT" '{"title":"Temple run","adults":3}'; check "edit trip" 200
req POST "/api/itineraries/$IID/generate" "$AT" '{"day":1}'; check "regenerate day 1" 200
req POST "/api/itineraries/$IID/recalculate" "$AT";   check "recalculate" 200
req POST "/api/itineraries/$IID/copy" "$AT";          check "copy own trip" 201
TPL=$(curl -s "$BASE/api/home" | j "d['itineraries'][0]['id']")
req GET "/api/itineraries/$TPL";                      check "curated template is public" 200
req POST "/api/itineraries/$TPL/copy" "$AT";          check "copy template" 201
req DELETE "/api/itineraries/$IID" "$AT2";            check "other user cannot delete -> 404" 404
req DELETE "/api/itineraries/$IID" "$AT";             check "delete trip" 204

echo "== staff and admin"
req GET /api/admin/overview "$STAFF";                 check "overview" 200
req GET "/api/admin/users?role=customer" "$STAFF";    check "users list" 200
req GET /api/admin/bookings "$STAFF";                 check "bookings list" 200
req GET "/api/admin/bookings/$BID" "$STAFF";          check "any booking" 200
req GET /api/admin/payments "$STAFF";                 check "payments" 200
req GET /api/admin/audit-logs "$STAFF";               check "audit logs" 200
req GET /api/admin/reviews "$STAFF";                  check "review moderation list" 200
req GET /api/admin/ai-usage "$STAFF";                 check "ai usage" 200
UID2=$(curl -s "$BASE/api/admin/users?q=$E2" -H "Authorization: Bearer $ADMIN" | j "d['items'][0]['id']")
req PATCH "/api/admin/users/$UID2/role" "$STAFF" '{"role":"staff"}'; check "staff cannot change roles -> 403" 403
req PATCH "/api/admin/users/$UID2/role" "$ADMIN" '{"role":"staff"}'; check "admin changes role" 204
req GET /api/admin/overview "$AT2";                   check "role change applies immediately" 200
req POST /api/admin/destinations "$STAFF" "{\"name\":\"Smoke Island $STAMP\",\"country\":\"Testland\",\"shortDescription\":\"A tiny island for testing.\",\"longDescription\":\"A tiny test island that exists only in the smoke test suite.\",\"lat\":10.5,\"lng\":104.5,\"dailyBudgetUsd\":40,\"tags\":[\"test\"]}"; check "create destination" 201
NDID=$(echo "$BODY" | j "d['id']")
req GET /api/destinations/smoke-island-$STAMP;               check "new destination is visible" 200
req PATCH "/api/admin/destinations/$NDID" "$STAFF" '{"isFeatured":true}'; check "update destination" 200
req DELETE "/api/admin/destinations/$NDID" "$STAFF";  check "staff cannot delete destination -> 403" 403
req DELETE "/api/admin/destinations/$NDID" "$ADMIN";  check "admin deletes destination" 204
req GET /api/destinations/smoke-island-$STAMP;               check "deleted destination is gone -> 404" 404
req PUT "/api/partner/room-types/$ROOM/inventory" "$PARTNER" "{\"from\":\"$CI\",\"to\":\"$CO\",\"units\":1}"; check "partner edits stock" 200
req GET "/api/room-types/$ROOM?checkIn=$CI&checkOut=$CO"; expect_eq "stock edit is visible" "$(echo "$BODY" | j "d['quote']['nightly'][0]['units_available']")" "1"
req PUT "/api/partner/room-types/$ROOM/inventory" "$PARTNER" "{\"from\":\"$CI\",\"to\":\"$CO\",\"units\":$ROOMUNITS}"; check "restore stock" 200

echo "== administrator is read-only on hotels, rooms and prices"
req GET "/api/admin/hotels?pageSize=5" "$STAFF";       check "admin lists hotels (read-only)" 200
req GET "/api/admin/hotels?type=hostel" "$STAFF";      check "admin filters hotels by type" 200
req GET /api/admin/partners "$STAFF";                  check "admin lists partners" 200
HID=$(curl -s "$BASE/api/accommodations?pageSize=1" | j "d['items'][0]['id']")
req PATCH "/api/admin/accommodations/$HID" "$ADMIN" '{"stars":1}';           check_any "admin cannot edit a hotel" 404 405 403
req DELETE "/api/admin/accommodations/$HID" "$ADMIN";                         check_any "admin cannot delete a hotel" 404 405 403
req PUT "/api/admin/room-types/$ROOM/inventory" "$ADMIN" "{\"from\":\"$CI\",\"to\":\"$CO\",\"units\":1}"; check_any "admin cannot change stock" 404 405 403
req PATCH "/api/admin/room-types/$ROOM" "$ADMIN" '{"basePriceUsd":1}';       check_any "admin cannot change a room price" 404 405 403
req POST /api/admin/accommodations "$ADMIN" '{}';                              check_any "admin cannot add a hotel" 404 405 403
req GET /api/partner/accommodations "$ADMIN";          check "admin cannot use partner endpoints -> 403" 403
req GET /api/admin/partners "$AT";                     check "customer cannot list partners -> 403" 403

echo "== admin creates a partner account"
PEMAIL="owner$STAMP@example.com"
req POST /api/admin/partners "$STAFF" "{\"businessName\":\"Smoke Bungalows $STAMP\",\"ownerName\":\"Sok Owner\",\"email\":\"$PEMAIL\"}"; check "staff cannot create partner accounts -> 403" 403
req POST /api/admin/partners "$ADMIN" "{\"businessName\":\"Smoke Bungalows $STAMP\",\"ownerName\":\"Sok Owner\",\"email\":\"$PEMAIL\"}"; check "admin creates a partner account" 201
NPID=$(echo "$BODY" | j "d['id']"); TEMP=$(echo "$BODY" | j "d['temporaryPassword']")
req POST /api/admin/partners "$ADMIN" "{\"businessName\":\"Dup\",\"ownerName\":\"Dup Owner\",\"email\":\"$PEMAIL\"}"; check "duplicate partner email -> 409" 409
req POST /api/auth/login "" "{\"email\":\"$PEMAIL\",\"password\":\"$TEMP\"}"; check "partner signs in with the temporary password" 200
expect_eq "must change password flag" "$(echo "$BODY" | j "d['user']['mustChangePassword']")" "True"
expect_eq "role is partner" "$(echo "$BODY" | j "d['user']['role']")" "partner"
NP=$(echo "$BODY" | j "d['accessToken']")
req POST /api/auth/change-password "$NP" "{\"currentPassword\":\"wrong-password-1\",\"newPassword\":\"Brand-new-pass-77\"}"; check "wrong current password -> 403" 403
req POST /api/auth/change-password "$NP" "{\"currentPassword\":\"$TEMP\",\"newPassword\":\"weak\"}"; check "weak new password -> 422" 422
req POST /api/auth/change-password "$NP" "{\"currentPassword\":\"$TEMP\",\"newPassword\":\"Brand-new-pass-77\"}"; check "partner changes the password" 200
expect_eq "flag cleared" "$(echo "$BODY" | j "d['user']['mustChangePassword']")" "False"
NP=$(echo "$BODY" | j "d['accessToken']")
req POST /api/auth/login "" "{\"email\":\"$PEMAIL\",\"password\":\"$TEMP\"}"; check "temporary password no longer works -> 401" 401
req GET "/api/admin/partners/$NPID" "$ADMIN";           check "admin views the partner" 200

echo "== partner uploads images and creates a bungalow resort"
python3 - <<'PY'
import base64
open('/tmp/wf_pixel.png','wb').write(base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgYGD4DwABBAEAHGnW3wAAAABJRU5ErkJggg=='))
open('/tmp/wf_note.txt','w').write('not an image')
open('/tmp/wf_evil.svg','w').write('<svg xmlns="http://www.w3.org/2000/svg" onload="alert(1)"/>')
PY
upload "$NP" /tmp/wf_pixel.png;                         check "partner uploads an image" 200
IMG=$(echo "$BODY" | j "d['url']"); IMGID=$(echo "$BODY" | j "d['id']")
upload "$NP" /tmp/wf_note.txt;                          check "text file is refused -> 422" 422
upload "$NP" /tmp/wf_evil.svg;                          check "SVG is refused -> 422" 422
upload "$AT" /tmp/wf_pixel.png;                         check "customer cannot upload -> 403" 403
curl -s -o /dev/null -D /tmp/wf_hdr "$BASE$IMG"; expect_eq "image is served with its type" "$(grep -i '^content-type' /tmp/wf_hdr | tr -d '\r' | awk '{print tolower($2)}')" "image/png"
BUNG="{\"destinationId\":\"$PDEST\",\"name\":\"Smoke Riverside Bungalows\",\"type\":\"bungalow\",\"stars\":3,\"description\":\"Wooden bungalows beside the river created by the smoke test.\",\"address\":\"2 River Lane, Phnom Penh\",\"lat\":11.55,\"lng\":104.92,\"freeCancelHours\":24,\"coverImage\":\"$IMG\",\"rooms\":[{\"name\":\"River bungalow\",\"description\":\"Private bungalow\",\"maxAdults\":2,\"basePriceUsd\":40,\"totalUnits\":3,\"coverImage\":\"$IMG\"}]}"
req POST /api/partner/accommodations "$AT" "$BUNG";     check "customer cannot create a property -> 403" 403
req POST /api/partner/accommodations "$NP" "$BUNG";     check "partner creates a bungalow resort with images" 201
NH=$(echo "$BODY" | j "d['id']")
req GET "/api/accommodations/$NH?checkIn=$CI&checkOut=$CO"; expect_eq "bungalow is bookable immediately" "$(echo "$BODY" | j "d['room_types'][0]['quote']['available']")" "True"
expect_eq "bungalow has the uploaded cover" "$(echo "$BODY" | j "d['cover_image']")" "$IMG"
expect_eq "type is bungalow" "$(echo "$BODY" | j "d['type']")" "bungalow"
req POST /api/partner/accommodations "$PARTNER" "{\"destinationId\":\"$PDEST\",\"name\":\"Stolen image\",\"type\":\"hotel\",\"stars\":3,\"description\":\"Trying to reuse somebody else's upload.\",\"address\":\"3 Test Street\",\"lat\":11.5,\"lng\":104.9,\"coverImage\":\"$IMG\",\"rooms\":[{\"name\":\"R\",\"description\":\"Room\",\"maxAdults\":2,\"basePriceUsd\":20,\"totalUnits\":1}]}"; check "another partner cannot use my upload -> 422" 422
req POST /api/partner/accommodations "$NP" "$(echo "$BUNG" | python3 -c "import sys,json; d=json.load(sys.stdin); d['coverImage']='javascript:alert(1)'; print(json.dumps(d))")"; check "unsafe image URL -> 422" 422
req POST "/api/partner/accommodations/$NH/images" "$NP" "{\"url\":\"$IMG\",\"caption\":\"Front\"}"; check "partner adds a gallery photo" 201
GIMG=$(echo "$BODY" | j "d['id']")
req GET "/api/accommodations/$NH"; expect_eq "gallery has the photo" "$(echo "$BODY" | j "len(d['images'])")" "1"
req POST "/api/partner/accommodations/$NH/rooms" "$NP" "{\"name\":\"Family bungalow\",\"description\":\"Two bedrooms\",\"maxAdults\":4,\"maxChildren\":2,\"basePriceUsd\":70,\"totalUnits\":2,\"coverImage\":\"$IMG\"}"; check "partner adds a room type" 201
req GET "/api/partner/accommodations" "$NP"; NROOM=$(echo "$BODY" | j "[r for r in d['items'][0]['rooms'] if r['name']=='River bungalow'][0]['id']"); FROOM=$(echo "$BODY" | j "[r for r in d['items'][0]['rooms'] if r['name']=='Family bungalow'][0]['id']")
req PATCH "/api/partner/room-types/$NROOM" "$NP" '{"basePriceUsd":35,"totalUnits":5}'; check "partner changes room price and count" 200
req GET "/api/accommodations/$NH"; expect_eq "from-price follows the cheapest room" "$(echo "$BODY" | j "d['from_price_usd']")" "35.0"
req PATCH "/api/partner/room-types/$NROOM" "$PARTNER" '{"basePriceUsd":1}'; check "another partner cannot change it -> 404" 404
req PATCH "/api/partner/accommodations/$NH" "$PARTNER" '{"stars":1}'; check "another partner cannot edit the property -> 404" 404
req PUT "/api/partner/room-types/$NROOM/inventory" "$NP" "{\"from\":\"$CI\",\"to\":\"$CO\",\"units\":2,\"priceUsd\":50}"; check "partner sets stock and price for dates" 200
req GET "/api/admin/hotels?q=Smoke%20Riverside" "$STAFF"; expect_eq "admin sees the new bungalow" "$(echo "$BODY" | j "d['items'][0]['type']")" "bungalow"
expect_eq "admin sees its partner" "$(echo "$BODY" | j "d['items'][0]['partner_name']")" "Smoke Bungalows $STAMP"

echo "== QR payment: partner sets the QR, guest pays, partner confirms"
req GET "/api/bookings/x/pay-qr" "$AT";                  check_any "bad booking id" 404 422
req POST /api/bookings "$AT" "{\"roomTypeId\":\"$NROOM\",\"checkIn\":\"$CI\",\"checkOut\":\"$CO\",\"rooms\":1,\"adults\":2,\"guestName\":\"QR Guest\",\"guestEmail\":\"$EMAIL\"}"; check "guest books the bungalow" 201
QB=$(echo "$BODY" | j "d['id']")
req GET "/api/bookings/$QB/pay-qr" "$AT";                expect_eq "QR not offered before the partner sets one up" "$(echo "$BODY" | j "d['available']")" "False"
req POST /api/payments/intent "$AT" "{\"bookingId\":\"$QB\",\"idempotencyKey\":\"qr-early-$QB\",\"method\":\"qr\"}"; check "QR payment refused until set up -> 409" 409
req PUT /api/partner/profile "$NP" "{\"qrMediaId\":\"$IMGID\",\"bank\":\"ABA\"}"; check "QR without account name -> 422" 422
req PUT /api/partner/profile "$PARTNER" "{\"qrMediaId\":\"$IMGID\",\"accountName\":\"X\"}"; check "cannot use someone else's image as QR -> 422" 422
req PUT /api/partner/profile "$NP" "{\"name\":\"Smoke Bungalows $STAMP\",\"qrMediaId\":\"$IMGID\",\"accountName\":\"SOK OWNER\",\"bank\":\"ABA\",\"note\":\"Put the booking reference in the note\",\"contactPhone\":\"+85512000000\"}"; check "partner saves QR payment settings" 200
expect_eq "profile accepts QR" "$(echo "$BODY" | j "d['acceptsQr']")" "True"
req GET "/api/bookings/$QB/pay-qr" "$AT";                expect_eq "QR offered once set up" "$(echo "$BODY" | j "d['available']")" "True"
expect_eq "QR info has the account name" "$(echo "$BODY" | j "d['accountName']")" "SOK OWNER"
req GET "/api/bookings/$QB/pay-qr" "$AT2";               check "another guest cannot read it -> 404" 404
req POST /api/payments/intent "$AT" "{\"bookingId\":\"$QB\",\"idempotencyKey\":\"qr-$QB\",\"method\":\"qr\"}"; check "guest starts a QR payment" 201
QP=$(echo "$BODY" | j "d['id']"); expect_eq "payment method is qr" "$(echo "$BODY" | j "d['method']")" "qr"
req POST "/api/payments/$QP/simulate" "$AT" '{"outcome":"success"}'; check "QR payments cannot be simulated -> 409" 409
req POST "/api/partner/payments/$QP/confirm" "$PARTNER"; check "another partner cannot confirm it -> 404" 404
req GET "/api/partner/payments?method=qr&status=PENDING" "$NP"; expect_eq "partner sees the pending payment" "$(echo "$BODY" | j "d['items'][0]['id']")" "$QP"
req POST "/api/payments/$QP/claim" "$AT" '{"note":"Paid from my ABA app"}'; check "guest says they paid" 200
req GET "/api/partner/payments?method=qr&status=PENDING" "$NP"; expect_eq "claim is visible to the partner" "$(echo "$BODY" | j "d['items'][0]['claimed_at'] is not None")" "True"
req GET /api/notifications "$NP"; expect_eq "partner was notified" "$(echo "$BODY" | j "any('QR payment' in n['title'] for n in d['items'])")" "True"
req POST "/api/partner/payments/$QP/confirm" "$NP";      check "partner confirms the money arrived" 200
req GET "/api/bookings/$QB" "$AT";                       expect_eq "booking is CONFIRMED" "$(echo "$BODY" | j "d['status']")" "CONFIRMED"
req POST "/api/partner/payments/$QP/confirm" "$NP";      check "confirming twice -> 409" 409
req GET "/api/bookings/$QB/receipt" "$AT";               check "receipt after QR payment" 200
expect_eq "QR receipt is not marked simulated" "$(echo "$BODY" | j "d['simulated']")" "False"
req POST /api/bookings "$AT" "{\"roomTypeId\":\"$NROOM\",\"checkIn\":\"$CI\",\"checkOut\":\"$CO\",\"rooms\":1,\"adults\":2,\"guestName\":\"QR Guest\",\"guestEmail\":\"$EMAIL\"}"; QB2=$(echo "$BODY" | j "d['id']")
req POST /api/payments/intent "$AT" "{\"bookingId\":\"$QB2\",\"idempotencyKey\":\"qr2-$QB2\",\"method\":\"qr\"}"; QP2=$(echo "$BODY" | j "d['id']")
req POST "/api/payments/$QP2/claim" "$AT" '{}'; check "second guest payment claimed" 200
req POST "/api/partner/payments/$QP2/reject" "$NP" '{"reason":"Amount does not match"}'; check "partner rejects a payment" 200
req GET "/api/bookings/$QB2" "$AT";                      expect_eq "rejected payment keeps the booking pending" "$(echo "$BODY" | j "d['status']")" "PENDING_CONFIRMATION"
req POST /api/payments/intent "$AT" "{\"bookingId\":\"$QB2\",\"idempotencyKey\":\"card-$QB2\",\"method\":\"card\"}"; check "guest can switch to card after rejection" 201
req POST "/api/bookings/$QB2/cancel" "$AT";              check "cancel the second booking" 200

echo "== deleting rooms and properties is guarded"
req DELETE "/api/partner/room-types/$FROOM" "$PARTNER";  check "another partner cannot delete a room -> 404" 404
req DELETE "/api/partner/room-types/$NROOM" "$NP";       check "room with an active booking cannot be deleted -> 409" 409
req DELETE "/api/partner/room-types/$FROOM" "$NP";       check "partner deletes an unused room" 204
req DELETE "/api/partner/room-types/$NROOM" "$NP";       check "the last room cannot be deleted -> 409" 409
req DELETE "/api/partner/accommodations/$NH" "$NP";      check "property with an active booking cannot be deleted -> 409" 409
req POST "/api/partner/bookings/$QB/transition" "$NP" '{"to":"CHECKED_IN"}'; check "partner checks the QR guest in" 200
req POST "/api/partner/bookings/$QB/transition" "$NP" '{"to":"COMPLETED"}'; check "and completes the stay" 200
req DELETE "/api/partner/accommodations/$NH/images/$GIMG" "$NP"; check "partner removes a photo" 204
req DELETE "/api/partner/accommodations/$NH" "$NP";      check "partner deletes the property" 204
req GET "/api/accommodations/$NH";                       check "deleted property is gone -> 404" 404
req POST "/api/admin/partners/$NPID/reset-password" "$ADMIN"; check "admin resets the partner password" 200
RTEMP=$(echo "$BODY" | j "d['temporaryPassword']")
req POST /api/auth/login "" "{\"email\":\"$PEMAIL\",\"password\":\"Brand-new-pass-77\"}"; check "old password stops working after reset -> 401" 401
req POST /api/auth/login "" "{\"email\":\"$PEMAIL\",\"password\":\"$RTEMP\"}"; check "partner signs in with the reset password" 200
for p in admin partner; do curl -s -o /dev/null -w "dashboard /$p %{http_code}\n" "$BASE/$p/" | grep -q "200" && { PASS=$((PASS+1)); echo "ok    dashboard /$p is served"; } || { FAIL=$((FAIL+1)); echo "FAIL  dashboard /$p not served"; }; done

echo "== logout"
req POST /api/auth/logout "$AT" "{\"refreshToken\":\"$RT\"}"; check "logout" 204
req GET /api/users/me "$AT";                          check "access token rejected after logout -> 401" 401
req POST /api/auth/refresh "" "{\"refreshToken\":\"$RT\"}"; check "refresh after logout -> 401" 401

echo; echo "passed=$PASS failed=$FAIL"; [ "$FAIL" = 0 ]
