import { h, money, num } from '/dashboard/js/ui.js';
import {
  animateNumber,
  lollipopEntityChart,
  miniProgressCard,
  reportHeroBar,
  segmentedPieCard,
  verticalCategoryChart,
} from '/dashboard/js/charts.js';

// Admin overview: only real numbers from /admin/overview. No invented targets, growth rates or placeholder data.
export async function overviewPage({ api, user }) {
  const o = await api.get('/admin/overview');
  const c = o.counts || {};
  const revUsd = Number(o.revenueSimulatedUsd?.usd ?? 0);
  const byStatus = o.bookingsByStatus || [];
  const realTotal = byStatus.reduce((sum, s) => sum + Number(s.count || 0), 0);

  const statusCount = (key) => Number(byStatus.find((s) => s.status === key)?.count ?? 0);
  const completedCount = statusCount('COMPLETED');
  const confirmedCount = statusCount('CONFIRMED') + statusCount('CHECKED_IN');
  const pendingCount = statusCount('PENDING_CONFIRMATION');
  const cancelledCount = statusCount('CANCELLED');
  const fulfilled = completedCount + confirmedCount;
  const fulfillmentPct = realTotal ? Math.round((fulfilled / realTotal) * 100) : 0;

  // Animated KPI strip at top
  const kpiStat = (label, rawVal, hint, { isMoney = false, delay = 0 } = {}) => {
    const valEl = h('div', { class: 'value' }, isMoney ? money(rawVal) : num(rawVal));
    animateNumber(valEl, rawVal, { prefix: isMoney ? '$' : '', decimals: isMoney ? 2 : 0, duration: 900 });
    return h('div', { class: 'card stat anim-card', style: `--delay:${delay}ms` },
      h('div', { class: 'label' }, label),
      valEl,
      hint ? h('div', { class: 'hint' }, hint) : null);
  };

  const palette = ['#6347F9', '#E6485C', '#F59E0B', '#10B981', '#EC4899'];
  const statusItems = byStatus.length
    ? byStatus.map((s, idx) => ({
      label: String(s.status).replaceAll('_', ' ').toLowerCase(),
      value: Number(s.count || 0),
      color: palette[idx % palette.length],
    }))
    : [{ label: 'no bookings yet', value: 0, color: '#9AA0A6' }];

  const entityItems = [
    { label: 'Users', value: c.users || 0, icon: 'users', color: '#6347F9' },
    { label: 'Hotels', value: c.accommodations || 0, icon: 'bed', color: '#EC4899' },
    { label: 'Rooms', value: c.room_types || 0, icon: 'home', color: '#F59E0B' },
    { label: 'Places', value: c.attractions || 0, icon: 'map', color: '#7C5CFC' },
    { label: 'Reviews', value: c.reviews || 0, icon: 'star', color: '#E6485C' },
    { label: 'Trips', value: c.itineraries || 0, icon: 'compass', color: '#10B981' },
  ];

  // Real counts only (no minimum slice size), and one neutral slice when there are no bookings yet.
  const realSlices = [
    { label: 'Completed', value: completedCount, color: '#6347F9' },
    { label: 'Confirmed', value: confirmedCount + pendingCount, color: '#F59E0B' },
    { label: 'Cancelled', value: cancelledCount, color: '#EC4899' },
  ].filter((s) => s.value > 0);
  const pieSlices = realSlices.length ? realSlices : [{ label: 'No bookings yet', value: 1, color: '#9AA0A6' }];

  return h('div', { class: 'stack report-page' },
    reportHeroBar({
      user,
      roleTitle: 'Admin Analytics Dashboard',
      subtitle: 'Live platform telemetry & booking performance',
      actionHref: '#/destinations',
      actionTitle: 'Add destination',
    }),
    h('div', { class: 'stats' },
      kpiStat('Users', c.users || 0, 'registered accounts', { delay: 20 }),
      kpiStat('Bookings', c.bookings || 0, `${num(confirmedCount)} confirmed / active`, { delay: 50 }),
      kpiStat('Revenue', revUsd, 'simulated & QR payments', { isMoney: true, delay: 80 }),
      kpiStat('Hotels', c.accommodations || 0, `${num(c.room_types || 0)} room types`, { delay: 110 }),
      kpiStat('Destinations', c.destinations || 0, `${num(c.attractions || 0)} places`, { delay: 140 }),
      kpiStat('Reviews', c.reviews || 0, `${num(c.itineraries || 0)} trips saved`, { delay: 170 })),
    h('div', { class: 'report-bento' },
      h('div', { class: 'report-main' },
        h('div', { class: 'report-row-2' },
          verticalCategoryChart({
            title: 'Bookings by status',
            subtitle: 'Reservation pipeline distribution',
            items: statusItems,
            delay: 90,
          }),
          lollipopEntityChart({
            title: 'Catalog & user activity',
            subtitle: 'Active entities across modules',
            items: entityItems,
            delay: 140,
          }))),
      h('aside', { class: 'report-rail' },
        segmentedPieCard({
          title: 'Status Share',
          subtitle: 'Proportion of bookings by stage',
          slices: pieSlices,
          delay: 120,
        }),
        miniProgressCard({
          eyebrow: 'Booking Pipeline',
          title: 'Fulfillment',
          amountLabel: 'Revenue',
          amountValue: money(revUsd),
          growth: `${num(fulfilled)} of ${num(realTotal)} fulfilled`,
          percent: fulfillmentPct,
          color: '#E6485C',
          buttonLabel: 'Bookings',
          buttonHref: '#/bookings',
          statLeft: `${c.bookings || 0} bookings`,
          statRight: `${c.users || 0} users`,
          delay: 200,
        }))),
    o.note ? h('p', { class: 'muted small' }, o.note) : null);
}
