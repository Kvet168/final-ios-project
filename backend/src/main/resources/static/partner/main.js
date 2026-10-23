import { createDashboard } from '/dashboard/js/app.js';
import { bookingsPage } from '/dashboard/js/bookings.js';
import { propertiesPage } from '/dashboard/js/properties.js';
import { accountPage } from '/dashboard/js/account.js';
import { dashboardPage } from './pages/dashboard.js';
import { paymentsPage } from './pages/payments.js';
import { reviewsPage } from './pages/reviews.js';

createDashboard({
  name: 'Partner dashboard',
  roleLabel: 'Hotel partners',
  allowedRoles: ['partner'],
  nav: [
    { id: 'dashboard', label: 'Dashboard', icon: 'chart', page: dashboardPage },
    { id: 'properties', label: 'My properties', icon: 'bed', page: propertiesPage },
    { id: 'bookings', label: 'Bookings', icon: 'ticket', page: (ctx) => bookingsPage({ ...ctx, scope: 'partner' }) },
    { id: 'payments', label: 'QR payments', icon: 'card', page: paymentsPage },
    { id: 'reviews', label: 'Guest reviews', icon: 'star', page: reviewsPage },
    { id: 'account', label: 'Account', icon: 'users', page: accountPage },
  ],
});
