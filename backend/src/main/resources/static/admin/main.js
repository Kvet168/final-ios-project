import { createDashboard } from '/dashboard/js/app.js';
import { bookingsPage } from '/dashboard/js/bookings.js';
import { accountPage } from '/dashboard/js/account.js';
import { overviewPage } from './pages/overview.js';
import { usersPage } from './pages/users.js';
import { paymentsPage } from './pages/payments.js';
import { reviewsPage } from './pages/reviews.js';
import { destinationsPage } from './pages/destinations.js';
import { hotelsPage } from './pages/hotels.js';
import { auditPage } from './pages/audit.js';
import { aiPage } from './pages/ai.js';
import { adBusinessesPage, adCampaignsPage, adPackagesPage, adPaymentsPage, adPlacementsPage, adsOverviewPage } from './pages/ads.js';

createDashboard({
  name: 'Admin console',
  roleLabel: 'Staff and administrators',
  allowedRoles: ['staff', 'admin'],
  nav: [
    // Analytics
    { id: 'overview', group: 'Analytics', label: 'Overview', icon: 'chart', page: overviewPage },

    // Reservations & Finance
    { id: 'bookings', group: 'Reservations & Finance', label: 'Bookings', icon: 'ticket', page: (ctx) => bookingsPage({ ...ctx, scope: 'admin' }) },
    // Payments page hidden for the demo: each booking's payment is shown in its detail view.
    // { id: 'payments', group: 'Reservations & Finance', label: 'Payments', icon: 'card', page: paymentsPage },

    // Advertising & sponsored listings: hidden from the menu to keep the demo focused.
    // To bring it back, uncomment these six lines (the pages and the API are untouched).
    // { id: 'ads', group: 'Advertising', label: 'Advertising overview', icon: 'chart', page: adsOverviewPage },
    // { id: 'ad-campaigns', group: 'Advertising', label: 'Ad campaigns', icon: 'ticket', page: adCampaignsPage },
    // { id: 'ad-payments', group: 'Advertising', label: 'Ad payments', icon: 'card', page: adPaymentsPage },
    // { id: 'ad-businesses', group: 'Advertising', label: 'Businesses', icon: 'users', page: adBusinessesPage },
    // { id: 'ad-placements', group: 'Advertising', label: 'Placements', icon: 'calendar', page: adPlacementsPage },
    // { id: 'ad-packages', group: 'Advertising', label: 'Packages & pricing', icon: 'star', page: adPackagesPage },

    // Catalog Management
    { id: 'destinations', group: 'Catalog Management', label: 'Destinations', icon: 'map', page: destinationsPage },
    { id: 'hotels', group: 'Catalog Management', label: 'Hotels & hostels', icon: 'bed', page: hotelsPage },
    { id: 'reviews', group: 'Catalog Management', label: 'Reviews', icon: 'star', page: reviewsPage },

    // Manage Users (customers, staff, admins and hotel partner businesses)
    { id: 'users', group: 'Manage Users', label: 'Users', icon: 'users', page: usersPage },

    // Platform oversight: who did what, and how the AI features are used
    { id: 'audit', group: 'Platform', label: 'Audit log', icon: 'ticket', page: auditPage },
    { id: 'ai', group: 'Platform', label: 'AI usage', icon: 'chart', page: aiPage },

    // Account Settings
    { id: 'account', group: 'Settings', label: 'Account', icon: 'home', page: accountPage },
  ],
});
