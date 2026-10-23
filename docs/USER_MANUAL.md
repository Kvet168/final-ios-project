# User manual and demo guide

Start the backend (`docker compose up --build`), then run the app: `cd app && flutter run --dart-define=API_BASE_URL=http://localhost:8080/api` (iOS Simulator) or `http://10.0.2.2:8080/api` (Android emulator).

## Demo accounts
| Role | Email | Password |
|---|---|---|
| Customer | `maya@demo.wayfarer.test`, `liam@demo.wayfarer.test`, `sophea@demo.wayfarer.test` (and 11 more) | `Wayfarer#Demo2026` |
| Staff / partner / admin | `staff1@`, `partner.pp@`, `admin@demo.wayfarer.test` | same demo password (the `DEMO_PASSWORD` environment variable; development default shown above) |

## Web dashboards
Both open in a browser from the running backend and use the demo accounts above.

| Dashboard | URL | Sign in as | Try |
|---|---|---|---|
| Admin console | `http://localhost:8080/admin` | `admin@demo.wayfarer.test` (or `staff1@`) | **Partners -> Create partner account** (copy the one-time password), browse **Hotels & hostels** (read-only), open a booking, edit a destination, hide a review, change a user's role (admin only), read the audit log |
| Partner dashboard | `http://localhost:8080/partner` | `partner.pp@demo.wayfarer.test`, or a partner you created | **My properties -> Add property** (hotel, resort, bungalow, hostel ... with photos and rooms), Stock & price, **QR payments** (upload your QR, confirm a guest's payment), Bookings (check-in), Account (change password) |

A customer account is refused on both, and the Admin console cannot be used on `/partner` (or the reverse). Administrators cannot change hotels, rooms, prices or stock; partners only see and edit their own properties. A partner created by an administrator must choose a new password at first sign-in.

## 10-minute walkthrough
1. **Search:** Home -> destination "Phnom Penh", pick dates 3 weeks out -> Search stays. Apply filters (price, free cancellation, pool).
2. **Open** a property; compare room totals (taxes and fees itemised).
3. **Book:** sign in as Maya -> Reserve -> guest details -> "Pay now (simulate success)". Booking becomes *Confirmed*; open the receipt (marked simulated).
4. **Failure case:** book another room and choose "Simulate a declined card"; the booking stays *Awaiting payment*.
5. **Cancel:** My bookings -> open -> Cancel; see refund status and restored availability.
6. **Planner:** Trips -> enter the Phnom Penh $150 example -> review budget and assumptions -> Save -> reorder/remove stops -> regenerate a day.
7. **Guide:** ask "What should I wear at temples?" and inspect the sources.
8. **Admin:** sign in with an admin/staff account -> Account -> Administration.

Blocked-dates demo: Riverside Heritage Hotel has no rooms from day +30 to +34.
