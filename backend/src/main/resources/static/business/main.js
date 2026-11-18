import { createDashboard } from '/dashboard/js/app.js';
import { accountPage } from '/dashboard/js/account.js';
import { adPaymentsPage, adsDashboardPage, businessProfilePage, campaignsPage, registerBusinessModal } from '/dashboard/js/ads.js';

// Business owners (hotels, restaurants, cafés, camping sites, tour operators ...) buy and track advertising here.
// Hotel partners can use the same pages from their own dashboard (see /partner).
createDashboard({
  name: 'Business advertising',
  roleLabel: 'Business owners',
  allowedRoles: ['business', 'partner'],
  demoEmail: 'business.demo@demo.wayfarer.test',
  demoLabel: 'Try demo business account',
  hint: 'Sign in with your business account to run advertising campaigns.',
  register: registerBusinessModal,
  nav: [
    { id: 'dashboard', group: 'Analytics', label: 'Ad performance', icon: 'chart', page: adsDashboardPage },
    { id: 'campaigns', group: 'Advertising', label: 'My campaigns', icon: 'ticket', page: campaignsPage },
    { id: 'payments', group: 'Advertising', label: 'Spend & payments', icon: 'card', page: adPaymentsPage },
    { id: 'profile', group: 'Settings', label: 'Business profile', icon: 'home', page: businessProfilePage },
    { id: 'account', group: 'Settings', label: 'Account', icon: 'users', page: accountPage },
  ],
});
