import { badge, h, money, num, table } from '/dashboard/js/ui.js';

export async function dashboardPage({ api }) {
  const [a, hotels] = await Promise.all([api.get('/partner/analytics'), api.get('/partner/accommodations')]);
  const by = (s) => a.bookingsByStatus.find((x) => x.status === s);
  const pending = by('PENDING_CONFIRMATION')?.count ?? 0, confirmed = by('CONFIRMED')?.count ?? 0, inHouse = by('CHECKED_IN')?.count ?? 0;
  const revenue = a.bookingsByStatus.filter((x) => ['CONFIRMED', 'CHECKED_IN', 'COMPLETED'].includes(x.status)).reduce((s, x) => s + Number(x.total_usd), 0);
  const stat = (label, value, hint) => h('div', { class: 'card stat' }, h('div', { class: 'label' }, label), h('div', { class: 'value' }, value), hint ? h('div', { class: 'hint' }, hint) : null);
  return h('div', { class: 'stack' },
    h('div', { class: 'stats' },
      stat('Occupancy, next 30 days', a.occupancyPctNext30Days == null ? '-' : `${a.occupancyPctNext30Days}%`, 'from open room stock'),
      stat('Upcoming confirmed', num(confirmed)), stat('Guests in house', num(inHouse)), stat('Awaiting payment', num(pending)),
      stat('Booked revenue', money(revenue), 'confirmed, in house and completed'), stat('Hotels', num(hotels.items.length))),
    h('section', { class: 'card' }, h('div', { class: 'card-head' }, h('h2', {}, 'Bookings by status')),
      table({ empty: 'No bookings yet', columns: [{ label: 'Status', render: (r) => badge(r.status) }, { label: 'Bookings', num: true, render: (r) => num(r.count) }, { label: 'Value', num: true, render: (r) => money(r.total_usd) }], rows: a.bookingsByStatus })),
    h('p', { class: 'muted small' }, a.note));
}
