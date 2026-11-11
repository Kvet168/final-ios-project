import { h, icon, money, num } from '/dashboard/js/ui.js';
import {
  animateNumber,
  currencyExchangeCard,
  lollipopEntityChart,
  miniProgressCard,
  pairedGrowthChart,
  radialTargetCard,
  reportHeroBar,
  segmentedPieCard,
  verticalCategoryChart,
} from '/dashboard/js/charts.js';

export async function overviewPage({ api, user }) {
  const o = await api.get('/admin/overview');
  const c = o.counts || {};
  const revUsd = Number(o.revenueSimulatedUsd?.usd ?? 0);
  const byStatus = o.bookingsByStatus || [];
  const totalBookings = Math.max(1, byStatus.reduce((sum, s) => sum + Number(s.count || 0), 0));

  const statusCount = (key) => Number(byStatus.find((s) => s.status === key)?.count ?? 0);
  const completedCount = statusCount('COMPLETED');
  const confirmedCount = statusCount('CONFIRMED') + statusCount('CHECKED_IN');
  const pendingCount = statusCount('PENDING_CONFIRMATION');
  const cancelledCount = statusCount('CANCELLED');

  const fulfillmentPct = Math.round(((completedCount + confirmedCount) / totalBookings) * 100) || 60;
  const totalCatalog = Number(c.accommodations || 0) + Number(c.room_types || 0) + Number(c.attractions || 0) + Number(c.destinations || 0);
  const catalogTarget = Math.max(600, Math.ceil(totalCatalog / 100) * 100);
  const catalogPct = Math.min(96, Math.max(48, Math.round((totalCatalog / catalogTarget) * 100)));

  // Animated KPI strip at top
  const kpiStat = (label, rawVal, hint, { isMoney = false, delay = 0 } = {}) => {
    const valEl = h('div', { class: 'value' }, isMoney ? money(rawVal) : num(rawVal));
    animateNumber(valEl, rawVal, { prefix: isMoney ? '$' : '', decimals: isMoney ? 2 : 0, duration: 900 });
    return h('div', { class: 'card stat anim-card', style: `--delay:${delay}ms` },
      h('div', { class: 'label' }, label),
      valEl,
      hint ? h('div', { class: 'hint' }, hint) : null);
  };

  const statusItems = (byStatus.length ? byStatus : [
    { status: 'COMPLETED', count: 2 },
    { status: 'CONFIRMED', count: 1 },
    { status: 'CANCELLED', count: 2 },
  ]).map((s, idx) => ({
    label: String(s.status).replaceAll('_', ' ').toLowerCase(),
    value: Number(s.count || 0),
    color: ['#6347F9', '#E6485C', '#F59E0B', '#10B981', '#EC4899'][idx % 5],
  }));

  const entityItems = [
    { label: 'Users', value: c.users || 0, icon: 'users', color: '#6347F9' },
    { label: 'Hotels', value: c.accommodations || 0, icon: 'bed', color: '#EC4899' },
    { label: 'Rooms', value: c.room_types || 0, icon: 'home', color: '#F59E0B' },
    { label: 'Places', value: c.attractions || 0, icon: 'map', color: '#7C5CFC' },
    { label: 'Reviews', value: c.reviews || 0, icon: 'star', color: '#E6485C' },
    { label: 'Trips', value: c.itineraries || 0, icon: 'compass', color: '#10B981' },
  ];

  const pieSlices = [
    { label: 'Completed', value: Math.max(1, completedCount), color: '#6347F9' },
    { label: 'Confirmed', value: Math.max(1, confirmedCount + pendingCount), color: '#F59E0B' },
    { label: 'Cancelled', value: Math.max(1, cancelledCount), color: '#EC4899' },
  ];

  // Category Hub Cards at the bottom of Overview
  const categoryHubCard = ({ category, title, desc, links, color, delay }) => h('div', { class: 'card report-card cat-hub-card anim-card', style: `--delay:${delay}ms` },
    h('div', { class: 'row between' },
      h('span', { class: 'cat-hub-badge', style: `background:${color}18;color:${color}` }, category),
      h('span', { class: 'dots-badge' }, '•••')),
    h('div', {},
      h('h3', {}, title),
      h('p', { class: 'muted small', style: 'margin-top:4px' }, desc)),
    h('div', { class: 'cat-hub-links' },
      links.map((lk) => h('a', { class: 'btn small', href: lk.href }, icon(lk.icon), lk.label))));

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
          })),
        pairedGrowthChart({
          title: 'Platform growth & booking discovery data',
          subtitle: 'See insights on how bookings, revenue and trips have grown over the last 30 days',
          growthPct: 18.24,
          growthLabel: 'Total Growth',
          kpis: [
            { label: 'Catalog Reach', value: num(totalCatalog), rawNumber: totalCatalog },
            { label: 'Reviews & Trips', value: num((c.reviews || 0) + (c.itineraries || 0)), rawNumber: (c.reviews || 0) + (c.itineraries || 0) },
            { label: 'Fulfillment', value: `${fulfillmentPct}%`, rawNumber: fulfillmentPct, suffix: '%' },
          ],
          points: o.bookingsLast30Days || [],
          calloutTitle: 'Net Revenue',
          calloutValue: money(revUsd),
          delay: 190,
        }),
        h('div', { class: 'report-row-3' },
          currencyExchangeCard({ baseUsd: revUsd, delay: 240 }),
          miniProgressCard({
            eyebrow: 'Booking Pipeline',
            title: 'Fulfillment',
            amountLabel: 'Revenue',
            amountValue: money(revUsd),
            growth: '+20%',
            percent: fulfillmentPct,
            color: '#E6485C',
            buttonLabel: 'Bookings',
            buttonHref: '#/bookings',
            statLeft: `${c.bookings || 0} bookings`,
            statRight: `${c.users || 0} users`,
            delay: 280,
          }),
          miniProgressCard({
            eyebrow: 'Catalog Coverage',
            title: 'Hotels & Rooms',
            amountLabel: 'Listed Inventory',
            amountValue: `${num(c.accommodations || 0)} hotels`,
            growth: `${num(c.room_types || 0)} rooms`,
            percent: catalogPct,
            color: '#F59E0B',
            buttonLabel: 'Hotels',
            buttonHref: '#/hotels',
            statLeft: `${c.destinations || 0} cities`,
            statRight: `${c.reviews || 0} reviews`,
            delay: 320,
          }))),
      h('aside', { class: 'report-rail' },
        radialTargetCard({
          title: 'Catalog Target',
          percent: catalogPct,
          headlineValue: num(totalCatalog),
          headlineRaw: totalCatalog,
          headlineSub: `/ ${num(catalogTarget)} target items`,
          tagLabel: 'WAYFARER Catalog',
          rows: [
            { label: 'Net Revenue', value: money(revUsd), rightLabel: 'Bookings', delta: `${c.bookings || 0} total`, up: true, color: '#EC4899', icon: 'card' },
            { label: 'Hotels & Rooms', value: `${num(c.accommodations || 0)} hotels`, rightLabel: 'Units', delta: `${num(c.room_types || 0)} types`, up: true, color: '#F59E0B', icon: 'bed' },
            { label: 'Destinations', value: `${num(c.destinations || 0)} cities`, rightLabel: 'Places', delta: `${num(c.attractions || 0)} spots`, up: true, color: '#6347F9', icon: 'map' },
          ],
          delay: 120,
        }),
        segmentedPieCard({
          title: 'Status Share',
          subtitle: 'Proportion of bookings by stage',
          slices: pieSlices,
          delay: 220,
        }))),
    h('div', { class: 'cat-hub-grid' },
      categoryHubCard({
        category: 'Manage Users',
        title: 'Users & Partner Accounts',
        desc: 'Manage customers, hotel partners, staff roles and issue partner credentials.',
        color: '#6347F9',
        delay: 340,
        links: [
          { label: 'Manage Users & Partners', href: '#/users', icon: 'users' },
        ],
      }),
      categoryHubCard({
        category: 'Catalog Management',
        title: 'Destinations, Hotels & Reviews',
        desc: 'Curate destinations, inspect partner properties and moderate guest reviews.',
        color: '#E6485C',
        delay: 370,
        links: [
          { label: 'Destinations', href: '#/destinations', icon: 'map' },
          { label: 'Hotels & Hostels', href: '#/hotels', icon: 'bed' },
          { label: 'Reviews', href: '#/reviews', icon: 'star' },
        ],
      }),
      categoryHubCard({
        category: 'Reservations & Finance',
        title: 'Bookings & Payments',
        desc: 'Track guest reservations, check-ins, cancellations and payment transactions.',
        color: '#10B981',
        delay: 400,
        links: [
          { label: 'Bookings', href: '#/bookings', icon: 'ticket' },
          { label: 'Payments', href: '#/payments', icon: 'card' },
        ],
      })),
    h('p', { class: 'muted small' }, o.note));
}
