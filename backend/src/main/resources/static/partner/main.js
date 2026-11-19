import { createDashboard } from '/dashboard/js/app.js';
import { bookingsPage } from '/dashboard/js/bookings.js';
import { propertiesPage } from '/dashboard/js/properties.js';
import { accountPage } from '/dashboard/js/account.js';
import { adPaymentsPage, adsDashboardPage, businessProfilePage, campaignsPage } from '/dashboard/js/ads.js';
import { dashboardPage } from './pages/dashboard.js';
import { paymentsPage } from './pages/payments.js';
import { reviewsPage } from './pages/reviews.js';

createDashboard({
  name: 'Partner dashboard',
  roleLabel: 'Hotel partners',
  allowedRoles: ['partner'],
  nav: [
    // Analytics
    { id: 'dashboard', group: 'Analytics', label: 'Dashboard', icon: 'chart', page: dashboardPage },

    // Property Management
    { id: 'properties', group: 'Property Management', label: 'My properties', icon: 'bed', page: propertiesPage },
    { id: 'reviews', group: 'Property Management', label: 'Guest reviews', icon: 'star', page: reviewsPage },

    // Reservations & Finance
    { id: 'bookings', group: 'Reservations & Finance', label: 'Bookings', icon: 'ticket', page: (ctx) => bookingsPage({ ...ctx, scope: 'partner' }) },
    { id: 'payments', group: 'Reservations & Finance', label: 'QR payments', icon: 'card', page: paymentsPage },

    // Advertising: hidden from the menu to keep the demo focused.
    // To bring it back, uncomment these four lines (the pages and the API are untouched).
    // { id: 'ads', group: 'Advertising', label: 'Ad performance', icon: 'chart', page: adsDashboardPage },
    // { id: 'campaigns', group: 'Advertising', label: 'My campaigns', icon: 'ticket', page: campaignsPage },
    // { id: 'adpayments', group: 'Advertising', label: 'Spend & payments', icon: 'card', page: adPaymentsPage },
    // { id: 'business', group: 'Advertising', label: 'Business profile', icon: 'home', page: businessProfilePage },

    // Account Settings
    { id: 'account', group: 'Settings', label: 'Account', icon: 'users', page: accountPage },
  ],
});
