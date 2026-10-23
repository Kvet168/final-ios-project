// Partner property manager: hotels, resorts, bungalows, hostels and their rooms, photos, stock and prices.
import { checkbox, confirmDialog, field, h, icon, imagePicker, input, modal, money, num, select, showErrors, stars, textarea, todayIso, toast } from './ui.js';

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

  const card = (a) => h('article', { class: 'card hotel' },
    a.cover_image ? h('img', { class: 'hotel-cover', src: a.cover_image, alt: `${a.name}` }) : null,
    h('div', { class: 'row between' }, h('div', {}, h('h3', {}, a.name), h('div', { class: 'muted small' }, `${typeLabel(a.type)} · `, stars(a.stars))),
      h('div', { class: 'right' }, h('div', { class: 'small muted' }, 'from'), h('strong', {}, money(a.from_price_usd)))),
    h('div', { class: 'small muted' }, `Rating ${Number(a.rating_avg).toFixed(1)} (${num(a.review_count)} reviews) · ${(a.images || []).length} photos`),
    h('div', { class: 'rooms' }, (a.rooms || []).map((r) => h('div', { class: 'room' },
      h('div', { class: 'row' }, r.cover_image ? h('img', { class: 'thumb', src: r.cover_image, alt: '' }) : null,
        h('div', {}, h('strong', {}, r.name), h('div', { class: 'small muted' }, `${money(r.base_price_usd)} / night · ${r.total_units} rooms`))),
      h('div', { class: 'row' },
        h('button', { class: 'btn small', type: 'button', onclick: () => inventoryForm(r) }, icon('calendar'), 'Stock & price'),
        h('button', { class: 'btn small', type: 'button', onclick: () => roomForm({ accommodationId: a.id, roomId: r.id }) }, icon('edit'), 'Edit'),
        h('button', { class: 'btn small danger', type: 'button', 'aria-label': `Delete ${r.name}`, onclick: () => deleteRoom(r) }, icon('trash')))))),
    h('div', { class: 'row' },
      h('button', { class: 'btn small primary', type: 'button', onclick: () => roomForm({ accommodationId: a.id }) }, icon('plus'), 'Add room'),
      h('button', { class: 'btn small', type: 'button', onclick: () => propertyForm(a.id) }, icon('edit'), 'Edit details'),
      h('button', { class: 'btn small', type: 'button', onclick: () => photosForm(a) }, 'Photos'),
      h('button', { class: 'btn small danger', type: 'button', onclick: () => deleteProperty(a) }, icon('trash'), 'Delete')));

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
    const dest = editing ? null : select(dests.items.map((d) => [d.id, `${d.name}, ${d.country}`]), '');
    const name = input({ value: v.name || '', required: true, maxlength: 100 });
    const type = select(TYPES, v.type || 'hotel');
    const starsIn = select([1, 2, 3, 4, 5], v.stars || 3);
    const address = input({ value: v.address || '', required: true, maxlength: 200 });
    const lat = input({ type: 'number', step: 'any', value: v.lat ?? '' }), lng = input({ type: 'number', step: 'any', value: v.lng ?? '' });
    const desc = textarea({ maxlength: 3000 }); desc.value = v.description || '';
    const free = input({ type: 'number', min: 0, max: 720, value: v.free_cancel_hours ?? 48 });
    const breakfast = checkbox('Breakfast included', !!v.breakfast_included), family = checkbox('Family friendly', !!v.family_friendly);
    const cover = imagePicker({ current: v.cover_image, label: 'Upload cover photo', upload: up });
    const rooms = [];
    const roomBox = h('div', { class: 'stack' });
    const addRoom = () => {
      const r = { name: input({ placeholder: 'e.g. Garden bungalow', maxlength: 80 }), description: input({ placeholder: 'Short description', maxlength: 500 }), bed: input({ value: 'queen', maxlength: 40 }),
        adults: input({ type: 'number', min: 1, max: 8, value: 2 }), children: input({ type: 'number', min: 0, max: 6, value: 0 }), price: input({ type: 'number', min: 1, step: '0.01', placeholder: 'USD per night' }),
        units: input({ type: 'number', min: 1, max: 500, value: 3 }), image: imagePicker({ label: 'Upload room photo', upload: up }) };
      rooms.push(r);
      const wrap = h('div', { class: 'card card-pad stack' }, h('div', { class: 'row between' }, h('strong', {}, 'Room / bungalow type'),
        rooms.length > 1 ? h('button', { class: 'btn small', type: 'button', 'aria-label': 'Remove this room type', onclick: () => { rooms.splice(rooms.indexOf(r), 1); wrap.remove(); } }, icon('x')) : null),
      h('div', { class: 'form-grid' }, field('Name', r.name), field('Bed type', r.bed), field('Description', r.description, { full: true }), field('Max adults', r.adults), field('Max children', r.children),
        field('Price / night (USD)', r.price), field('How many of these', r.units)), r.image.el);
      roomBox.append(wrap);
    };
    if (!editing) addRoom();
    const errors = h('div', { 'aria-live': 'polite' });
    const body = h('div', { class: 'stack' }, h('div', { class: 'form-grid' },
      editing ? null : field('Destination', dest, { full: true }), field('Property name', name), field('Type', type), field('Stars (1-5)', starsIn), field('Free cancellation (hours, 0 = non-refundable)', free),
      field('Address', address, { full: true }), field('Latitude', lat, { hint: 'Right-click the place in Google Maps to copy it' }), field('Longitude', lng),
      field('Description', desc, { full: true, hint: 'At least 20 characters' }), h('div', { class: 'full' }, h('label', { class: 'small muted' }, 'Cover photo'), cover.el),
      h('div', { class: 'row full' }, breakfast.el, family.el)),
    editing ? null : h('div', { class: 'stack' }, h('div', { class: 'row between' }, h('h3', {}, 'Rooms you sell'), h('button', { class: 'btn small', type: 'button', onclick: addRoom }, icon('plus'), 'Add another room type')), roomBox),
    errors);
    const save = h('button', { class: 'btn primary', type: 'button', onclick: async () => {
      const common = { name: name.value.trim(), type: type.value, stars: Number(starsIn.value), address: address.value.trim(), description: desc.value.trim(), lat: numOrNull(lat.value), lng: numOrNull(lng.value),
        freeCancelHours: numOrNull(free.value), breakfastIncluded: breakfast.input.checked, familyFriendly: family.input.checked, coverImage: cover.get() };
      m.setBusy(true);
      try {
        if (editing) await api.patch(`/partner/accommodations/${id}`, common);
        else await api.post('/partner/accommodations', { ...common, destinationId: dest.value, rooms: rooms.map((r) => ({ name: r.name.value.trim(), description: r.description.value.trim(),
          bedType: r.bed.value.trim() || 'double', maxAdults: Number(r.adults.value), maxChildren: Number(r.children.value), basePriceUsd: numOrNull(r.price.value), totalUnits: Number(r.units.value), coverImage: r.image.get() })) });
        toast(editing ? 'Property updated' : 'Property created and open for booking for the next 180 days', 'ok'); m.close(); await load();
      } catch (e) { showErrors(errors, e); m.setBusy(false); }
    } }, editing ? 'Save changes' : 'Create property');
    const m = modal({ title: editing ? `Edit ${v.name}` : 'New property', body, width: 780, actions: [h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Cancel'), save] });
  }

  /* ---------------- add / edit room ---------------- */
  async function roomForm({ accommodationId, roomId }) {
    const editing = !!roomId;
    const r = editing ? await api.get(`/room-types/${roomId}`).catch((e) => { toast(e.message, 'bad'); return null; }) : {};
    if (!r) return;
    const name = input({ value: r.name || '', maxlength: 80 }), bed = input({ value: r.bed_type || 'queen', maxlength: 40 });
    const desc = textarea({ maxlength: 500 }); desc.value = r.description || '';
    const adults = input({ type: 'number', min: 1, max: 8, value: r.max_adults ?? 2 }), children = input({ type: 'number', min: 0, max: 6, value: r.max_children ?? 0 });
    const price = input({ type: 'number', min: 1, step: '0.01', value: r.base_price_usd ?? '' }), units = input({ type: 'number', min: 1, max: 500, value: r.total_units ?? 3 });
    const image = imagePicker({ current: r.cover_image, label: 'Upload room photo', upload: up });
    const errors = h('div', { 'aria-live': 'polite' });
    const m = modal({
      title: editing ? `Edit ${r.name}` : 'Add a room or bungalow type', width: 680,
      body: h('div', { class: 'stack' }, h('div', { class: 'form-grid' }, field('Name', name), field('Bed type', bed), field('Description', desc, { full: true }), field('Max adults', adults), field('Max children', children),
        field('Price per night (USD)', price, editing ? { hint: 'Applies to new nights. Use Stock & price to change dates that are already open.' } : {}),
        field(editing ? 'Total rooms of this type' : 'How many of these', units, editing ? { hint: 'Changing this adjusts tonight-onwards availability by the same amount.' } : {})), image.el, errors),
      actions: [h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Cancel'), h('button', { class: 'btn primary', type: 'button', onclick: async () => {
        const body = { name: name.value.trim(), bedType: bed.value.trim() || 'double', description: desc.value.trim(), maxAdults: Number(adults.value), maxChildren: Number(children.value),
          basePriceUsd: numOrNull(price.value), totalUnits: Number(units.value), coverImage: image.get() };
        m.setBusy(true);
        try {
          if (editing) await api.patch(`/partner/room-types/${roomId}`, body); else await api.post(`/partner/accommodations/${accommodationId}/rooms`, body);
          toast(editing ? 'Room updated' : 'Room added and open for booking', 'ok'); m.close(); await load();
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
        } }, icon('trash'))))) : [h('div', { class: 'muted' }, 'No photos yet. Add some so guests can see your property.')]));
    };
    async function refresh() { const d = await api.get(`/accommodations/${a.id}`); draw(d.images || [], d.cover_image); await load(); }
    const picker = imagePicker({ label: 'Add a photo', upload: up });
    const addBtn = h('button', { class: 'btn primary', type: 'button', onclick: async () => {
      if (!picker.get()) return showErrors(errors, { message: 'Choose a photo first.' });
      try { await api.post(`/partner/accommodations/${a.id}/images`, { url: picker.get() }); picker.set(null); showErrors(errors, null); await refresh(); } catch (e) { showErrors(errors, e); }
    } }, 'Add to gallery');
    modal({ title: `Photos: ${a.name}`, width: 760, body: h('div', { class: 'stack' }, grid, h('div', { class: 'card card-pad stack' }, picker.el, h('div', {}, addBtn)), errors) });
    refresh().catch((e) => showErrors(errors, e));
  }

  /* ---------------- nightly stock and price ---------------- */
  function inventoryForm(room) {
    const from = input({ type: 'date', value: todayIso(), min: todayIso() }), to = input({ type: 'date', value: todayIso(), min: todayIso() });
    const units = input({ type: 'number', min: 0, max: room.total_units, value: room.total_units });
    const price = input({ type: 'number', min: 1, step: '0.01', placeholder: 'Leave empty to keep current prices' });
    const errors = h('div', { 'aria-live': 'polite' });
    const m = modal({
      title: `Stock & price: ${room.name}`, width: 560,
      body: h('div', { class: 'stack' }, h('p', { class: 'muted small' }, `Sets rooms available (0 closes the dates, maximum ${room.total_units}) and optionally the price for every night in the range. Use it for seasons, events and blackouts.`),
        h('div', { class: 'form-grid' }, field('From', from), field('To (inclusive)', to), field('Rooms available per night', units), field('Price per night (USD)', price)), errors),
      actions: [h('button', { class: 'btn', type: 'button', onclick: () => m.close() }, 'Cancel'), h('button', { class: 'btn primary', type: 'button', onclick: async () => {
        m.setBusy(true);
        try { const r = await api.put(`/partner/room-types/${room.id}/inventory`, { from: from.value, to: to.value, units: Number(units.value), priceUsd: numOrNull(price.value) }); toast(`${r.updatedNights} nights updated`, 'ok'); m.close(); }
        catch (e) { showErrors(errors, e); m.setBusy(false); }
      } }, 'Apply')],
    });
  }

  reload();
  root.append(h('div', { class: 'row between' }, h('p', { class: 'muted' }, 'Your hotels, resorts, bungalows and hostels: photos, rooms, stock and prices.'),
    h('button', { class: 'btn primary', type: 'button', onclick: () => propertyForm() }, icon('plus'), 'Add property')), list);
  return root;
}
