import { createDashboard } from '/dashboard/js/app.js';
import { bookingsPage } from '/dashboard/js/bookings.js';
import { accountPage } from '/dashboard/js/account.js';
import { overviewPage } from './pages/overview.js';
import { usersPage } from './pages/users.js';
import { paymentsPage } from './pages/payments.js';
import { reviewsPage } from './pages/reviews.js';
import { destinationsPage } from './pages/destinations.js';
import { auditPage } from './pages/audit.js';
import { aiPage } from './pages/ai.js';
import { partnersPage } from './pages/partners.js';
import { hotelsPage } from './pages/hotels.js';

createDashboard({
  name: 'Admin console',
  roleLabel: 'Staff and administrators',
  allowedRoles: ['staff', 'admin'],
  nav: [
    { id: 'overview', label: 'Overview', icon: 'chart', page: overviewPage },
    { id: 'partners', label: 'Partners', icon: 'users', page: partnersPage },
    { id: 'hotels', label: 'Hotels & hostels', icon: 'bed', page: hotelsPage },
    { id: 'bookings', label: 'Bookings', icon: 'ticket', page: (ctx) => bookingsPage({ ...ctx, scope: 'admin' }) },
    { id: 'payments', label: 'Payments', icon: 'card', page: paymentsPage },
    { id: 'destinations', label: 'Destinations', icon: 'map', page: destinationsPage },
    { id: 'reviews', label: 'Reviews', icon: 'star', page: reviewsPage },
    { id: 'users', label: 'Users', icon: 'users', page: usersPage },
    { id: 'audit', label: 'Audit log', icon: 'log', page: auditPage },
    { id: 'ai', label: 'AI usage', icon: 'bot', page: aiPage },
    { id: 'account', label: 'Account', icon: 'users', page: accountPage },
  ],
});
