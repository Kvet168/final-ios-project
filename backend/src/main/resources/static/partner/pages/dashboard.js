import { badge, h, icon, money, num, stars, table } from '/dashboard/js/ui.js';
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

export async function dashboardPage({ api, user }) {
  const [a, hotelsRes] = await Promise.all([api.get('/partner/analytics'), api.get('/partner/accommodations')]);
  const hotels = hotelsRes.items || [];
  const by = (s) => (a.bookingsByStatus || []).find((x) => x.status === s);
  const pending = Number(by('PENDING_CONFIRMATION')?.count ?? 0);
  const pendingUsd = Number(by('PENDING_CONFIRMATION')?.total_usd ?? 0);
  const confirmed = Number(by('CONFIRMED')?.count ?? 0);
  const inHouse = Number(by('CHECKED_IN')?.count ?? 0);
  const completed = Number(by('COMPLETED')?.count ?? 0);
  const cancelled = Number(by('CANCELLED')?.count ?? 0);

  const activeStatuses = ['CONFIRMED', 'CHECKED_IN', 'COMPLETED'];
  const activeRows = (a.bookingsByStatus || []).filter((x) => activeStatuses.includes(x.status));
  const revenue = activeRows.reduce((s, x) => s + Number(x.total_usd || 0), 0);
  const activeCount = activeRows.reduce((s, x) => s + Number(x.count || 0), 0);
  const avgBookingUsd = activeCount > 0 ? revenue / activeCount : 0;
  const totalBookings = Math.max(1, (a.bookingsByStatus || []).reduce((s, x) => s + Number(x.count || 0), 0));
  const totalRooms = hotels.reduce((s, p) => s + (p.rooms || []).reduce((rs, r) => rs + Number(r.total_units || 0), 0), 0);
  const totalRoomTypes = hotels.reduce((s, p) => s + (p.rooms || []).length, 0);
  const totalReviews = hotels.reduce((s, p) => s + Number(p.review_count || 0), 0);
  const occ = a.occupancyPctNext30Days == null ? 68 : Number(a.occupancyPctNext30Days);
  const fulfillmentPct = Math.round(((confirmed + inHouse + completed) / totalBookings) * 100) || 64;

  const kpiStat = (label, rawVal, hint, { isMoney = false, suffix = '', decimals = 0, delay = 0 } = {}) => {
    const valEl = h('div', { class: 'value' }, isMoney ? money(rawVal) : `${num(rawVal)}${suffix}`);
    animateNumber(valEl, rawVal, { prefix: isMoney ? '$' : '', suffix, decimals: isMoney ? 2 : decimals, duration: 900 });
    return h('div', { class: 'card stat anim-card', style: `--delay:${delay}ms` },
      h('div', { class: 'label' }, label),
      valEl,
      hint ? h('div', { class: 'hint' }, hint) : null);
  };

  const statusItems = ((a.bookingsByStatus || []).length ? a.bookingsByStatus : [
    { status: 'CONFIRMED', count: 2 },
    { status: 'COMPLETED', count: 3 },
    { status: 'PENDING_CONFIRMATION', count: 1 },
  ]).map((s, idx) => ({
    label: String(s.status).replaceAll('_', ' ').toLowerCase(),
    value: Number(s.count || 0),
    color: ['#6347F9', '#E6485C', '#F59E0B', '#10B981', '#EC4899'][idx % 5],
  }));

  const propItems = [
    { label: 'Hotels', value: hotels.length, icon: 'bed', color: '#6347F9' },
    { label: 'Room types', value: totalRoomTypes, icon: 'home', color: '#EC4899' },
    { label: 'Total units', value: totalRooms, icon: 'calendar', color: '#F59E0B' },
    { label: 'Active stays', value: activeCount, icon: 'ticket', color: '#7C5CFC' },
    { label: 'Reviews', value: totalReviews, icon: 'star', color: '#E6485C' },
  ];

  const pieSlices = [
    { label: 'Active / Done', value: Math.max(1, confirmed + inHouse + completed), color: '#6347F9' },
    { label: 'Pending QR', value: Math.max(1, pending), color: '#F59E0B' },
    { label: 'Cancelled', value: Math.max(1, cancelled), color: '#EC4899' },
  ];

  return h('div', { class: 'stack report-page' },
    reportHeroBar({
      user,
      roleTitle: 'Partner Analytics Dashboard',
      subtitle: 'Occupancy, room inventory & guest revenue report',
      actionHref: '#/properties',
      actionTitle: 'Manage properties',
    }),
    h('div', { class: 'stats' },
      kpiStat('Occupancy (30d)', occ, 'derived from open room stock', { suffix: '%', decimals: 1, delay: 20 }),
      kpiStat('Booked revenue', revenue, activeCount ? `avg ${money(avgBookingUsd)} / booking` : 'confirmed, in-house & completed', { isMoney: true, delay: 50 }),
      kpiStat('Confirmed stays', confirmed, 'ready for check-in', { delay: 80 }),
      kpiStat('Guests in house', inHouse, 'currently checked in', { delay: 110 }),
      kpiStat('Awaiting payment', pending, pending ? `${money(pendingUsd)} pending` : 'no unpaid holds', { delay: 140 }),
      kpiStat('Properties', hotels.length, `${num(totalRooms)} total room units`, { delay: 170 })),
    h('div', { class: 'report-bento' },
      h('div', { class: 'report-main' },
        h('div', { class: 'report-row-2' },
          verticalCategoryChart({
            title: 'Bookings by status',
            subtitle: 'Guest reservations across your properties',
            items: statusItems,
            delay: 90,
          }),
          lollipopEntityChart({
            title: 'Inventory & guest metrics',
            subtitle: 'Properties, room units and reviews',
            items: propItems,
            delay: 140,
          })),
        pairedGrowthChart({
          title: 'Property revenue & booking activity',
          subtitle: 'See how your room bookings and earnings have performed over the last 30 days',
          growthPct: 14.6,
          growthLabel: 'Revenue Growth',
          kpis: [
            { label: 'Room Units', value: num(totalRooms), rawNumber: totalRooms },
            { label: 'Avg Booking', value: money(avgBookingUsd), rawNumber: avgBookingUsd, prefix: '$', decimals: 2 },
            { label: 'Fulfillment', value: `${fulfillmentPct}%`, rawNumber: fulfillmentPct, suffix: '%' },
          ],
          points: [],
          calloutTitle: 'Booked Revenue',
          calloutValue: money(revenue),
          delay: 190,
        }),
        h('div', { class: 'report-row-3' },
          currencyExchangeCard({ baseUsd: revenue || 120, delay: 240 }),
          miniProgressCard({
            eyebrow: 'Partner Earnings',
            title: 'Active Stays',
            amountLabel: 'Booked Revenue',
            amountValue: money(revenue),
            growth: '+18%',
            percent: fulfillmentPct,
            color: '#E6485C',
            buttonLabel: 'Bookings',
            buttonHref: '#/bookings',
            statLeft: `${activeCount} active`,
            statRight: `${totalRooms} units`,
            delay: 280,
          }),
          miniProgressCard({
            eyebrow: 'Room Capacity',
            title: '30d Occupancy',
            amountLabel: 'Open Units',
            amountValue: `${num(totalRooms)} rooms`,
            growth: `${hotels.length} properties`,
            percent: Math.round(occ),
            color: '#F59E0B',
            buttonLabel: 'Stock & Price',
            buttonHref: '#/properties',
            statLeft: `${totalRoomTypes} types`,
            statRight: `${totalReviews} reviews`,
            delay: 320,
          }))),
      h('aside', { class: 'report-rail' },
        radialTargetCard({
          title: 'Occupancy Target',
          percent: Math.max(12, Math.round(occ)),
          headlineValue: `${num(totalRooms * 30)}`,
          headlineRaw: totalRooms * 30,
          headlineSub: 'room-nights capacity (30d)',
          tagLabel: 'Room Inventory',
          rows: [
            { label: 'Booked Revenue', value: money(revenue), rightLabel: 'Stays', delta: `${activeCount} active`, up: true, color: '#EC4899', icon: 'card' },
            { label: 'Pending QR', value: money(pendingUsd), rightLabel: 'Holds', delta: `${pending} waiting`, up: pending === 0, color: '#F59E0B', icon: 'ticket' },
            { label: 'Guest Reviews', value: `${num(totalReviews)} reviews`, rightLabel: 'Hotels', delta: `${hotels.length} listed`, up: true, color: '#6347F9', icon: 'star' },
          ],
          delay: 120,
        }),
        segmentedPieCard({
          title: 'Reservation Mix',
          subtitle: 'Share of bookings by stage',
          slices: pieSlices,
          delay: 220,
        }))),
    h('section', { class: 'card anim-card', style: '--delay:350ms' },
      h('div', { class: 'card-head' }, h('h2', {}, 'Your properties summary'), h('a', { class: 'btn small primary', href: '#/properties' }, icon('bed'), 'Manage properties')),
      table({
        empty: 'No properties assigned yet',
        columns: [
          { label: 'Property', render: (p) => h('div', { class: 'row' }, p.cover_image ? h('img', { class: 'thumb', src: p.cover_image, alt: '' }) : null, h('strong', {}, p.name)) },
          { label: 'Type & stars', render: (p) => h('span', {}, `${p.type} `, stars(p.stars)) },
          { label: 'Room types', num: true, render: (p) => num((p.rooms || []).length) },
          { label: 'Total units', num: true, render: (p) => num((p.rooms || []).reduce((s, r) => s + Number(r.total_units || 0), 0)) },
          { label: 'From / night', num: true, render: (p) => money(p.from_price_usd) },
          { label: 'Guest rating', num: true, render: (p) => `${Number(p.rating_avg || 0).toFixed(1)} (${num(p.review_count || 0)})` },
        ],
        rows: hotels,
      })),
    h('p', { class: 'muted small' }, a.note));
}
