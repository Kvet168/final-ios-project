// Partner property manager: hotels, resorts, bungalows, hostels and their rooms, photos, stock and prices.
import { checkbox, confirmDialog, date, field, h, icon, imagePicker, input, modal, money, num, select, showErrors, stars, successDialog, textarea, todayIso, toast, validate } from './ui.js';

const TYPES = [['hotel', 'Hotel'], ['resort', 'Resort'], ['bungalow', 'Bungalow'], ['hostel', 'Hostel'], ['guesthouse', 'Guesthouse'], ['boutique', 'Boutique hotel'], ['villa', 'Villa'], ['apartment', 'Apartment']];
const typeLabel = (t) => (TYPES.find((x) => x[0] === t) || [t, t])[1];
const numOrNull = (v) => (v === '' || v == null ? null : Number(v));

export function propertiesPage({ api }) {
  const list = h('div', { class: 'hotel-grid' });
  const root = h('div', { class: 'stack' });
  const up = (f) => api.upload(f);

  async function load() {
    const r = await api.get('/partner/accommodations');
    list.replaceChildren(...(r.items.length ? r.items.map(card) : [h('div', { class: 'card empty' }, h('strong', {}, 'No properties yet'),
      h('span', {}, 'Add your hotel, resort, bungalow or hostel to start receiving bookings.'),
      h('div', {}, h('button', { class: 'btn primary', type: 'button', onclick: () => propertyForm() }, icon('plus'), 'Add your first property')))]));
  }
  const reload = () => load().catch((e) => toast(e.message, 'bad'));

  // Icon-only action: the tooltip is the title, screen readers read the aria-label.
  const iconBtn = (name, label, onclick, danger = false) => h('button', {
    class: `btn small icon-only${danger ? ' danger' : ''}`, type: 'button', title: label, 'aria-label': label, onclick,
  }, icon(name));

  const card = (a) => h('article', { class: 'card hotel' },
    h('div', { class: 'hotel-media' },
      a.cover_image
        ? h('img', { class: 'hotel-cover', src: a.cover_image, alt: `${a.name}` })
        : h('div', { class: 'hotel-cover hotel-cover-empty' }, icon('bed')),
      h('div', { class: 'hotel-tools' },
        iconBtn('edit', `Edit details of ${a.name}`, () => propertyForm(a.id)),
        iconBtn('image', `Photos of ${a.name} (${(a.images || []).length})`, () => photosForm(a)),
        iconBtn('trash', `Delete ${a.name}`, () => deleteProperty(a), true))),
    h('div', { class: 'row between hotel-head' },
      h('div', { class: 'hotel-title' }, h('h3', {}, a.name),
        h('div', { class: 'muted small' }, `${typeLabel(a.type)} · `, stars(a.stars), ` · ${Number(a.rating_avg).toFixed(1)} (${num(a.review_count)})`)),
      h('div', { class: 'hotel-price' }, h('span', { class: 'small muted' }, 'from '), h('strong', {}, money(a.from_price_usd)))),
    h('div', { class: 'rooms' }, (a.rooms || []).map((r) => h('div', { class: 'room' },
      r.cover_image ? h('img', { class: 'thumb', src: r.cover_image, alt: '' }) : null,
      h('div', { class: 'room-info' }, h('strong', {}, r.name), h('div', { class: 'small muted' }, `${money(r.base_price_usd)} / night · ${r.total_units} rooms`)),
      h('div', { class: 'room-actions' },
        iconBtn('calendar', `Stock and price of ${r.name}`, () => inventoryForm(r)),
        iconBtn('edit', `Edit ${r.name}`, () => roomForm({ accommodationId: a.id, roomId: r.id })),
        iconBtn('trash', `Delete ${r.name}`, () => deleteRoom(r), true))))),
    h('button', { class: 'btn small add-room', type: 'button', onclick: () => roomForm({ accommodationId: a.id }) }, icon('plus'), 'Add room'));

  async function deleteProperty(a) {
    if (!(await confirmDialog({ title: 'Delete property', message: `Remove ${a.name} and all its rooms from the catalogue? Properties with pending, confirmed or in-house bookings cannot be deleted.`, confirmLabel: 'Delete', danger: true }))) return;
    try { await api.del(`/partner/accommodations/${a.id}`); toast('Property deleted', 'ok'); await load(); } catch (e) { toast(e.message, 'bad'); }
  }

  async function deleteRoom(r) {
    if (!(await confirmDialog({ title: 'Delete room type', message: `Remove ${r.name}? Rooms with active bookings and the last room of a property cannot be deleted.`, confirmLabel: 'Delete', danger: true }))) return;
    try { await api.del(`/partner/room-types/${r.id}`); toast('Room deleted', 'ok'); await load(); } catch (e) { toast(e.message, 'bad'); }
  }

  /* ---------------- create / edit property ---------------- */
  async function propertyForm(id) {
    const editing = !!id;
    const [dests, cur] = await Promise.all([editing ? null : api.get('/destinations', { pageSize: 50, sort: 'name' }), editing ? api.get(`/accommodations/${id}`) : null])
      .catch((e) => { toast(e.message, 'bad'); return []; });
    if (editing ? !cur : !dests) return;
    const v = cur || {};
    const dest = editing ? null : select(dests.items.map((d) => [d.id, `${d.name}, ${d.country}`]), dests.items[0]?.id || '');
    const name = input({ value: v.name || '', required: true, maxlength: 100, placeholder: 'e.g. Mekong Breeze Resort' });
    const type = select(TYPES, v.type || 'hotel');
    const starsIn = select([1, 2, 3, 4, 5], v.stars || 3);
    const address = input({ value: v.address || '', required: true, maxlength: 200, placeholder: 'Street address and district' });
    const lat = input({ type: 'number', step: 'any', required: !editing, value: v.lat ?? '11.5564', placeholder: 'e.g. 11.5564' });
    const lng = input({ type: 'number', step: 'any', required: !editing, value: v.lng ?? '104.9282', placeholder: 'e.g. 104.9282' });
    const desc = textarea({ maxlength: 3000, required: !editing, placeholder: 'Describe your property, atmosphere and location (at least 20 characters)...' }); desc.value = v.description || '';
    const free = input({ type: 'number', min: 0, max: 720, value: v.free_cancel_hours ?? 48 });
    const breakfast = checkbox('Breakfast included', !!v.breakfast_included), family = checkbox('Family friendly', !!v.family_friendly);
    const cover = imagePicker({ current: v.cover_image, label: 'Upload cover photo', upload: up });
    const rooms = [];
    const roomBox = h('div', { class: 'stack' });
    const addRoom = () => {
      const r = {
        name: input({ placeholder: 'e.g. Garden bungalow', maxlength: 80, required: true }),
        description: input({ placeholder: 'Short description (5+ chars)', maxlength: 500, required: true }),
        bed: input({ value: 'queen', maxlength: 40 }),
        adults: input({ type: 'number', min: 1, max: 8, value: 2, required: true }),
        children: input({ type: 'number', min: 0, max: 6, value: 0 }),
        price: input({ type: 'number', min: 1, max: 10000, step: '0.01', placeholder: 'USD per night', required: true }),
        units: input({ type: 'number', min: 1, max: 500, value: 3, required: true }),
        image: imagePicker({ label: 'Upload room photo', upload: up }),
      };
      rooms.push(r);
      const wrap = h('div', { class: 'card card-pad stack' }, h('div', { class: 'row between' }, h('strong', {}, 'Room / bungalow type'),
        rooms.length > 1 ? h('button', { class: 'btn small danger', type: 'button', 'aria-label': 'Remove this room type', onclick: () => { rooms.splice(rooms.indexOf(r), 1); wrap.remove(); } }, icon('trash'), 'Remove') : null),
      h('div', { class: 'form-grid' },
        field('Room name', r.name, { required: true }),
        field('Bed type', r.bed),
        field('Description', r.description, { full: true, required: true, hint: '5–500 characters' }),
        field('Max adults', r.adults, { required: true }),
        field('Max children', r.children),
        field('Price / night (USD)', r.price, { required: true }),
        field('How many of these', r.units, { required: true })),
      r.image.el);
      roomBox.append(wrap);
    };
    if (!editing) addRoom();
    const errors = h('div', { 'aria-live': 'polite' });
    const body = h('div', { class: 'stack' }, h('div', { class: 'form-grid' },
      editing ? null : field('Destination', dest, { full: true, required: true }),
      field('Property name', name, { required: true }),
      field('Type', type),
      field('Stars (1-5)', starsIn),
      field('Free cancellation (hours, 0 = non-refundable)', free),
      field('Address', address, { full: true, required: true, hint: '5–200 characters' }),
      field('Latitude', lat, { hint: 'Right-click the place in Google Maps to copy it (-90 to 90)', required: !editing }),
      field('Longitude', lng, { hint: '-180 to 180', required: !editing }),
      field('Description', desc, { full: true, hint: 'At least 20 characters', required: !editing }),
      h('div', { class: 'full' }, h('label', { class: 'small muted' }, 'Cover photo'), cover.el),
      h('div', { class: 'row full' }, breakfast.el, family.el)),
    editing ? null : h('div', { class: 'stack' }, h('div', { class: 'row between' }, h('h3', {}, 'Rooms you sell'), h('button', { class: 'btn small', type: 'button', onclick: addRoom }, icon('plus'), 'Add another room type')), roomBox),
    errors);

    const save = h('button', { class: 'btn primary', type: 'button', onclick: async () => {
      const rules = [
        editing ? null : { input: dest, label: 'Destination', required: true },
        { input: name, label: 'Property name', required: true, minLen: 2, maxLen: 100 },
        { input: free, label: 'Free cancellation hours', min: 0, max: 720 },
        { input: address, label: 'Address', required: true, minLen: 5, maxLen: 200 },
        { input: lat, label: 'Latitude', required: !editing, min: -90, max: 90 },
        { input: lng, label: 'Longitude', required: !editing, min: -180, max: 180 },
        { input: desc, label: 'Description', required: !editing, minLen: 20, maxLen: 3000 },
      ];
      if (!editing) {
        rooms.forEach((r, idx) => {
          const prefix = rooms.length > 1 ? `Room #${idx + 1} ` : 'Room ';
          rules.push(
            { input: r.name, label: `${prefix}name`, required: true, minLen: 2, maxLen: 80 },
            { input: r.description, label: `${prefix}description`, required: true, minLen: 5, maxLen: 500 },
            { input: r.adults, label: `${prefix}max adults`, required: true, min: 1, max: 8 },
            { input: r.children, label: `${prefix}max children`, min: 0, max: 6 },
            { input: r.price, label: `${prefix}price / night`, required: true, min: 1, max: 10000 },
            { input: r.units, label: `${prefix}units`, required: true, min: 1, max: 500 },
          );
        });
      }
      if (!validate(rules, errors)) return;

      const common = { name: name.value.trim(), type: type.value, stars: Number(starsIn.value), address: address.value.trim(), description: desc.value.trim(), lat: numOrNull(lat.value), lng: numOrNull(lng.value),
        freeCancelHours: numOrNull(free.value), breakfastIncluded: breakfast.input.checked, familyFriendly: family.input.checked, coverImage: cover.get() };
      m.setBusy(true);
      try {
        if (editing) await api.patch(`/partner/accommodations/${id}`, common);
        else await api.post('/partner/accommodations', { ...common, destinationId: dest.value, rooms: rooms.map((r) => ({ name: r.name.value.trim(), description: r.description.value.trim(),
          bedType: r.bed.value.trim() || 'double', maxAdults: Number(r.adults.value), maxChildren: Number(r.children.value), basePriceUsd: numOrNull(r.price.value), totalUnits: Number(r.units.value), coverImage: r.image.get() })) });
        m.close();
        await load();
        const cheapest = !editing && rooms.length ? Math.min(...rooms.map((r) => Number(r.price.value))) : null;
        await successDialog({
          title: editing ? 'Property updated' : 'Property created & open for booking',
          message: editing
            ? `Your changes to ${name.value.trim()} are now live in the Travel app.`
            : `${name.value.trim()} is live and open for guest bookings across the next 180 days.`,
          details: [
            ['Property', name.value.trim()],
            ['Type', `${typeLabel(type.value)} (${starsIn.value} ★)`],
            !editing ? ['Room types added', String(rooms.length)] : null,
            cheapest != null ? ['Starting rate', `${money(cheapest)} / night`] : null,
          ],
        });
      } catch (e) { showErrors(errors, e); m.setBusy(false); }
    } }, editing ? 'Save changes' : 'Create property');
    const m = modal({ title: editing ? `Edit ${v.name}` : 'New property', body, width: 780, actions: [h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Cancel'), save] });
  }

  /* ---------------- add / edit room ---------------- */
  async function roomForm({ accommodationId, roomId }) {
    const editing = !!roomId;
    const r = editing ? await api.get(`/room-types/${roomId}`).catch((e) => { toast(e.message, 'bad'); return null; }) : {};
    if (!r) return;
    const name = input({ value: r.name || '', maxlength: 80, required: true, placeholder: 'e.g. Deluxe River View' }), bed = input({ value: r.bed_type || 'queen', maxlength: 40 });
    const desc = textarea({ maxlength: 500, required: true, placeholder: 'Room highlights, view and amenities (5–500 chars)' }); desc.value = r.description || '';
    const adults = input({ type: 'number', min: 1, max: 8, value: r.max_adults ?? 2, required: true }), children = input({ type: 'number', min: 0, max: 6, value: r.max_children ?? 0 });
    const price = input({ type: 'number', min: 1, max: 10000, step: '0.01', value: r.base_price_usd ?? '', required: true, placeholder: 'USD per night' });
    const units = input({ type: 'number', min: 1, max: 500, value: r.total_units ?? 3, required: true });
    const image = imagePicker({ current: r.cover_image, label: 'Upload room photo', upload: up });
    const errors = h('div', { 'aria-live': 'polite' });
    const m = modal({
      title: editing ? `Edit ${r.name}` : 'Add a room or bungalow type', width: 680,
      body: h('div', { class: 'stack' }, h('div', { class: 'form-grid' },
        field('Name', name, { required: true }),
        field('Bed type', bed),
        field('Description', desc, { full: true, required: true, hint: '5–500 characters' }),
        field('Max adults', adults, { required: true }),
        field('Max children', children),
        field('Price per night (USD)', price, editing ? { hint: 'Applies to new nights. Use Stock & price to change dates that are already open.', required: true } : { required: true }),
        field(editing ? 'Total rooms of this type' : 'How many of these', units, editing ? { hint: 'Changing this adjusts tonight-onwards availability by the same amount.', required: true } : { required: true })), image.el, errors),
      actions: [h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Cancel'), h('button', { class: 'btn primary', type: 'button', onclick: async () => {
        if (!validate([
          { input: name, label: 'Room name', required: true, minLen: 2, maxLen: 80 },
          { input: bed, label: 'Bed type', maxLen: 40 },
          { input: desc, label: 'Description', required: true, minLen: 5, maxLen: 500 },
          { input: adults, label: 'Max adults', required: true, min: 1, max: 8 },
          { input: children, label: 'Max children', min: 0, max: 6 },
          { input: price, label: 'Price per night', required: true, min: 1, max: 10000 },
          { input: units, label: 'Total rooms', required: true, min: 1, max: 500 },
        ], errors)) return;

        const body = { name: name.value.trim(), bedType: bed.value.trim() || 'double', description: desc.value.trim(), maxAdults: Number(adults.value), maxChildren: Number(children.value),
          basePriceUsd: numOrNull(price.value), totalUnits: Number(units.value), coverImage: image.get() };
        m.setBusy(true);
        try {
          if (editing) await api.patch(`/partner/room-types/${roomId}`, body); else await api.post(`/partner/accommodations/${accommodationId}/rooms`, body);
          m.close();
          await load();
          await successDialog({
            title: editing ? 'Room type updated' : 'Room type added',
            message: editing ? `${name.value.trim()} has been updated.` : `${name.value.trim()} is now open for guest bookings.`,
            details: [
              ['Room', name.value.trim()],
              ['Base rate', `${money(price.value)} / night`],
              ['Total units', `${units.value} rooms`],
              ['Capacity', `${adults.value} adults${Number(children.value) ? ` + ${children.value} children` : ''}`],
            ],
          });
        } catch (e) { showErrors(errors, e); m.setBusy(false); }
      } }, editing ? 'Save changes' : 'Add room')],
    });
  }

  /* ---------------- photo gallery ---------------- */
  function photosForm(a) {
    const grid = h('div', { class: 'gallery' });
    const errors = h('div', { 'aria-live': 'polite' });
    const draw = (images, coverUrl) => {
      grid.replaceChildren(...(images.length ? images.map((i) => h('figure', {}, h('img', { src: i.url, alt: i.caption || '' }),
        h('div', { class: 'row' }, coverUrl === i.url ? h('span', { class: 'badge ok' }, 'cover') : h('button', { class: 'btn small', type: 'button', onclick: async () => {
          try { await api.patch(`/partner/accommodations/${a.id}`, { coverImage: i.url }); toast('Cover photo set', 'ok'); await refresh(); } catch (e) { showErrors(errors, e); }
        } }, 'Set cover'), h('button', { class: 'btn small danger', type: 'button', 'aria-label': 'Delete photo', onclick: async () => {
          try { await api.del(`/partner/accommodations/${a.id}/images/${i.id}`); await refresh(); } catch (e) { showErrors(errors, e); }
        } }, icon('trash'), 'Delete')))) : [h('div', { class: 'muted' }, 'No photos yet. Add some so guests can see your property.')]));
    };
    async function refresh() { const d = await api.get(`/accommodations/${a.id}`); draw(d.images || [], d.cover_image); await load(); }
    const picker = imagePicker({ label: 'Add a photo', upload: up });
    const addBtn = h('button', { class: 'btn primary', type: 'button', onclick: async () => {
      if (!picker.get()) return showErrors(errors, { message: 'Choose a photo first.' });
      try { await api.post(`/partner/accommodations/${a.id}/images`, { url: picker.get() }); picker.set(null); showErrors(errors, null); toast('Photo added to gallery', 'ok'); await refresh(); } catch (e) { showErrors(errors, e); }
    } }, 'Add to gallery');
    modal({ title: `Photos: ${a.name}`, width: 760, body: h('div', { class: 'stack' }, grid, h('div', { class: 'card card-pad stack' }, picker.el, h('div', {}, addBtn)), errors) });
    refresh().catch((e) => showErrors(errors, e));
  }

  /* ---------------- nightly stock and price (with live night & revenue algorithm) ---------------- */
  function inventoryForm(room) {
    const from = input({ type: 'date', value: todayIso(), min: todayIso(), required: true });
    const to = input({ type: 'date', value: todayIso(), min: todayIso(), required: true });
    const units = input({ type: 'number', min: 0, max: room.total_units, value: room.total_units, required: true });
    const price = input({ type: 'number', min: 1, max: 10000, step: '0.01', placeholder: `Current: ${money(room.base_price_usd)}` });
    const summary = h('div', { class: 'notice info small' });
    const errors = h('div', { 'aria-live': 'polite' });

    function updateSummary() {
      const d1 = new Date(`${from.value}T00:00:00`), d2 = new Date(`${to.value}T00:00:00`);
      const nights = Math.round((d2 - d1) / 86400000) + 1;
      const u = Math.max(0, Number(units.value) || 0);
      const rate = price.value ? Number(price.value) : Number(room.base_price_usd);
      if (Number.isNaN(nights) || nights < 1) {
        summary.textContent = 'Select a valid date range (From date must be on or before To date).';
        return;
      }
      const totalRoomNights = nights * u;
      const maxPotential = totalRoomNights * rate;
      summary.textContent = u === 0
        ? `Closing ${room.name} for ${nights} night${nights === 1 ? '' : 's'} (${date(from.value)} – ${date(to.value)}).`
        : `${nights} night${nights === 1 ? '' : 's'} × ${u} room${u === 1 ? '' : 's'} = ${num(totalRoomNights)} room-nights open at ${money(rate)}/night (max capacity value: ${money(maxPotential)}).`;
    }
    [from, to, units, price].forEach((el) => el.addEventListener('input', updateSummary));
    updateSummary();

    const m = modal({
      title: `Stock & price: ${room.name}`, width: 560,
      body: h('div', { class: 'stack' },
        h('p', { class: 'muted small' }, `Sets rooms available (0 closes the dates, maximum ${room.total_units}) and optionally overrides the nightly price for every night in the range.`),
        h('div', { class: 'form-grid' },
          field('From', from, { required: true }),
          field('To (inclusive)', to, { required: true }),
          field(`Rooms available per night (0–${room.total_units})`, units, { required: true }),
          field('Price per night (USD, optional)', price)),
        summary,
        errors),
      actions: [h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Cancel'), h('button', { class: 'btn primary', type: 'button', onclick: async () => {
        if (!validate([
          { input: from, label: 'From date', required: true },
          {
            input: to,
            label: 'To date',
            required: true,
            custom: (v) => {
              if (!from.value || !v) return null;
              if (v < from.value) return 'End date must be on or after the start date.';
              const days = Math.round((new Date(`${v}T00:00:00`) - new Date(`${from.value}T00:00:00`)) / 86400000) + 1;
              if (days > 365) return 'Range cannot exceed 365 nights at once.';
              return null;
            },
          },
          { input: units, label: 'Rooms available', required: true, min: 0, max: room.total_units },
          { input: price, label: 'Price per night', min: 1, max: 10000 },
        ], errors)) return;

        m.setBusy(true);
        try {
          const r = await api.put(`/partner/room-types/${room.id}/inventory`, { from: from.value, to: to.value, units: Number(units.value), priceUsd: numOrNull(price.value) });
          m.close();
          await load();
          await successDialog({
            title: 'Inventory & pricing updated',
            message: `Updated ${r.updatedNights} night${r.updatedNights === 1 ? '' : 's'} for ${room.name}.`,
            details: [
              ['Room type', room.name],
              ['Date range', `${date(from.value)} → ${date(to.value)}`],
              ['Nights updated', String(r.updatedNights)],
              ['Open units / night', `${units.value} of ${room.total_units}`],
              ['Nightly rate', price.value ? money(price.value) : `${money(room.base_price_usd)} (unchanged)`],
            ],
          });
        } catch (e) { showErrors(errors, e); m.setBusy(false); }
      } }, 'Apply')],
    });
  }

  reload();
  root.append(h('div', { class: 'row between' }, h('p', { class: 'muted' }, 'Your hotels, resorts, bungalows and hostels: photos, rooms, stock and prices.'),
    h('button', { class: 'btn primary', type: 'button', onclick: () => propertyForm() }, icon('plus'), 'Add property')), list);
  return root;
}
