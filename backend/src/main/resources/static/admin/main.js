import { createDashboard } from '/dashboard/js/app.js';
import { bookingsPage } from '/dashboard/js/bookings.js';
import { accountPage } from '/dashboard/js/account.js';
import { overviewPage } from './pages/overview.js';
import { usersPage } from './pages/users.js';
import { paymentsPage } from './pages/payments.js';
import { reviewsPage } from './pages/reviews.js';
import { destinationsPage } from './pages/destinations.js';
import { hotelsPage } from './pages/hotels.js';

createDashboard({
  name: 'Admin console',
  roleLabel: 'Staff and administrators',
  allowedRoles: ['staff', 'admin'],
  nav: [
    // Analytics
    { id: 'overview', group: 'Analytics', label: 'Overview', icon: 'chart', page: overviewPage },

    // Reservations & Finance
    { id: 'bookings', group: 'Reservations & Finance', label: 'Bookings', icon: 'ticket', page: (ctx) => bookingsPage({ ...ctx, scope: 'admin' }) },
    { id: 'payments', group: 'Reservations & Finance', label: 'Payments', icon: 'card', page: paymentsPage },

    // Catalog Management
    { id: 'destinations', group: 'Catalog Management', label: 'Destinations', icon: 'map', page: destinationsPage },
    { id: 'hotels', group: 'Catalog Management', label: 'Hotels & hostels', icon: 'bed', page: hotelsPage },
    { id: 'reviews', group: 'Catalog Management', label: 'Reviews', icon: 'star', page: reviewsPage },

    // Manage Users (customers, staff, admins and hotel partner businesses)
    { id: 'users', group: 'Manage Users', label: 'Users', icon: 'users', page: usersPage },

    // Account Settings
    { id: 'account', group: 'Settings', label: 'Account', icon: 'home', page: accountPage },
  ],
});
