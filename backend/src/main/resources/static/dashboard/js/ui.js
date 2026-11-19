// Small DOM toolkit. Elements are built with createElement/textContent only (never innerHTML), so data from the API cannot inject markup.

const SVG_NS = 'http://www.w3.org/2000/svg';

/* ---------- Khmer / English i18n ---------- */
const KM = {
  // Shell & Navigation
  'Admin console': 'ផ្ទាំងគ្រប់គ្រងអ្នកអភិបាល',
  'Partner dashboard': 'ផ្ទាំងគ្រប់គ្រងដៃគូសណ្ឋាគារ',
  'Staff and administrators': 'បុគ្គលិក និងអ្នកគ្រប់គ្រង',
  'Hotel partners': 'ដៃគូសណ្ឋាគារ និងផ្ទះសំណាក់',
  'Overview': 'ទិដ្ឋភាពទូទៅ',
  'Partners': 'ដៃគូអាជីវកម្ម',
  'Hotels & hostels': 'សណ្ឋាគារ និងផ្ទះសំណាក់',
  'Bookings': 'ការកក់ទុក',
  'Payments': 'ការទូទាត់ប្រាក់',
  'Destinations': 'គោលដៅទេសចរណ៍',
  'Reviews': 'ការវាយតម្លៃ',
  'Users': 'អ្នកប្រើប្រាស់',
  'Audit log': 'កំណត់ហេតុត្រួតពិនិត្យ',
  'AI usage': 'ការប្រើប្រាស់ AI',
  'Account': 'គណនី',
  'Dashboard': 'ទិដ្ឋភាពទូទៅ',
  'My properties': 'អចលនទ្រព្យរបស់ខ្ញុំ',
  'QR payments': 'ការទូទាត់តាម QR',
  'Guest reviews': 'មតិភ្ញៀវ',
  'Theme': 'ផ្ទៃពណ៌',
  'Sign out': 'ចាកចេញ',
  'Sign in': 'ចូលគណនី',
  'Signing in...': 'កំពុងចូល...',
  'Email': 'អ៊ីមែល',
  'Password': 'ពាក្យសម្ងាត់',
  'Enter your password': 'បញ្ចូលពាក្យសម្ងាត់របស់អ្នក',
  'Try demo partner account': 'សាកល្បងគណនីដៃគូគំរូ',
  'Try demo admin account': 'សាកល្បងគណនីអភិបាលគំរូ',
  'Sign in with your partner account to manage properties, rooms and bookings.': 'ចូលប្រើដោយគណនីដៃគូរបស់អ្នក ដើម្បីគ្រប់គ្រងសណ្ឋាគារ បន្ទប់ និងការកក់។',
  'Sign in with your staff or administrator account.': 'ចូលប្រើដោយគណនីបុគ្គលិក ឬអ្នកគ្រប់គ្រងរបស់អ្នក។',
  'Sign out of Travel?': 'ចាកចេញពី Travel ឬ?',
  'Cancel': 'បោះបង់',
  'Confirm': 'បញ្ជាក់',
  'Done': 'រួចរាល់',
  'Close': 'បិទ',
  'Save': 'រក្សាទុក',
  'Save changes': 'រក្សាទុកការផ្លាស់ប្តូរ',
  'Save settings': 'រក្សាទុកការកំណត់',
  'Apply': 'អនុវត្ត',
  'Edit': 'កែសម្រួល',
  'Delete': 'លុប',
  'Remove': 'លុបចេញ',
  'Refresh': 'ផ្ទុកឡើងវិញ',
  'Previous': 'មុន',
  'Next': 'បន្ទាប់',
  'Copy': 'ចម្លង',
  'Copied ✓': 'បានចម្លង ✓',
  'Try again': 'ព្យាយាមម្តងទៀត',
  'Nothing here yet': 'មិនទាន់មានទិន្នន័យនៅឡើយទេ',

  // Table headers & Filters
  'All statuses': 'គ្រប់ស្ថានភាពទាំងអស់',
  'All types': 'គ្រប់ប្រភេទទាំងអស់',
  'All partners': 'គ្រប់ដៃគូទាំងអស់',
  'All roles': 'គ្រប់តួនាទីទាំងអស់',
  'All reviews': 'គ្រប់ការវាយតម្លៃទាំងអស់',
  'All': 'ទាំងអស់',
  'Waiting for you': 'កំពុងរង់ចាំអ្នកបញ្ជាក់',
  'Confirmed': 'បានបញ្ជាក់',
  'Rejected': 'បានបដិសេធ',
  'Booking': 'លេខកក់',
  'No.': 'ល.រ',
  'Reference': 'លេខយោង',
  'Property & Room': 'អចលនទ្រព្យ និងបន្ទប់',
  'Check-In → Check-Out': 'ថ្ងៃចូល → ថ្ងៃចេញ',
  'Gross Total': 'ទឹកប្រាក់សរុប',
  'Net Payout': 'ប្រាក់ទទួលបានសុទ្ធ',
  'OTA Commission': 'កម្រៃជើងសារ OTA',
  'Front Desk Action': 'សកម្មភាពទទួលភ្ញៀវ',
  'View voucher': 'មើលបង្កាន់ដៃកក់',
  'Booking & Guest': 'លេខកក់ និងភ្ញៀវ',
  'Property & Partner': 'សណ្ឋាគារ និងដៃគូ',
  'Property & Stay': 'សណ្ឋាគារ និងថ្ងៃស្នាក់នៅ',
  'Transaction Ref': 'លេខប្រតិបត្តិការ',
  'Gross Paid': 'ប្រាក់បានបង់សរុប',
  'OTA Fee': 'កម្រៃប្រព័ន្ធ OTA',
  'Partner Net': 'ប្រាក់ដៃគូសុទ្ធ',
  'Channel': 'ប្រព័ន្ធទូទាត់',
  'Guest Claim': 'ការបញ្ជាក់ពីភ្ញៀវ',
  'All OTA Bookings': 'ការកក់ទាំងអស់ក្នុងប្រព័ន្ធ',
  'All Reservations': 'ការកក់ទាំងអស់',
  'Awaiting Payment': 'រង់ចាំការទូទាត់',
  'Ready for Check-In': 'ត្រៀមចូលស្នាក់នៅ',
  'In-House Guests': 'ភ្ញៀវកំពុងស្នាក់នៅ',
  'Completed Stays': 'ការស្នាក់នៅបានបញ្ចប់',
  'All Transactions': 'ប្រតិបត្តិការទាំងអស់',
  'Gross Booking Value (GBV)': 'ទឹកប្រាក់កក់សរុប (GBV)',
  'Travel OTA Commission': 'កម្រៃជើងសារ Travel',
  'Net Partner Payouts': 'ប្រាក់ទូទាត់ជូនដៃគូសណ្ឋាគារ',
  'Customer Refunds': 'ប្រាក់បង្វិលជូនភ្ញៀវវិញ',
  'All Property Payments': 'ការទូទាត់ទាំងអស់',
  'Awaiting Confirmation': 'រង់ចាំការបញ្ជាក់',
  'Gross Room Revenue': 'ចំណូលបន្ទប់សរុប',
  'Net Partner Earnings': 'ចំណូលសុទ្ធរបស់ដៃគូ',
  'Provider ref': 'លេខប្រតិបត្តិការ',
  'Amount': 'ទឹកប្រាក់',
  'Refunded': 'ប្រាក់បង្វិលសង',
  'Mode': 'របៀបទូទាត់',
  'Status': 'ស្ថានភាព',
  'When': 'កាលបរិច្ឆេទ',
  'Guest': 'ភ្ញៀវ',
  'Hotel': 'សណ្ឋាគារ',
  'Stay': 'រយៈពេលស្នាក់នៅ',
  'Total': 'សរុប',
  'Name': 'ឈ្មោះ',
  'Country': 'ប្រទេស',
  'Region': 'តំបន់',
  'Daily budget': 'ថវិកាប្រចាំថ្ងៃ',
  'Hotels': 'សណ្ឋាគារ',
  'Places': 'ទីកន្លែង',
  'Featured': 'ពេញនិយម',
  'Property': 'អចលនទ្រព្យ',
  'Type': 'ប្រភេទ',
  'Stars': 'ផ្កាយ',
  'Partner': 'ដៃគូ',
  'Rooms': 'បន្ទប់',
  'From': 'តម្លៃចាប់ពី',
  'Rating': 'ពិន្ទុ',
  'Business': 'អាជីវកម្ម',
  'Owner login': 'គណនីម្ចាស់',
  'Properties': 'អចលនទ្រព្យ',
  'Bookings': 'ការកក់',
  'Created': 'បង្កើតនៅ',
  'Review': 'មតិយោបល់',
  'Author': 'អ្នកសរសេរ',
  'Date': 'កាលបរិច្ឆេទ',
  'Joined': 'ចូលរួមនៅ',
  'Role': 'តួនាទី',
  'Action': 'សកម្មភាព',
  'Who': 'អ្នកធ្វើ',
  'Entity': 'ផ្នែក',
  'Details': 'ព័ត៌មានលម្អិត',
  'Feature': 'មុខងារ',
  'Provider': 'ប្រព័ន្ធ',
  'Latency': 'ល្បឿនឆ្លើយតប',
  'Result': 'លទ្ធផល',
  'Count': 'ចំនួន',
  'Share': 'ភាគរយ',
  'Gross revenue': 'ចំណូលសរុប',
  'Avg / booking': 'មធ្យមក្នុងមួយការកក់',
  'Destination': 'គោលដៅ',
  'Starting from': 'តម្លៃចាប់ពី',
  'Guest says': 'ភ្ញៀវបានបញ្ជាក់',

  // Actions & Buttons
  'Add destination': 'បន្ថែមគោលដៅ',
  'New destination': 'គោលដៅថ្មី',
  'Create destination': 'បង្កើតគោលដៅ',
  'Create partner account': 'បង្កើតគណនីដៃគូ',
  'Create administrator account': 'បង្កើតគណនីអ្នកអភិបាល',
  'Create staff account': 'បង្កើតគណនីបុគ្គលិក',
  'Create customer account': 'បង្កើតគណនីអតិថិជន',
  'Create account': 'បង្កើតគណនី',
  'Reset password': 'កំណត់ពាក្យសម្ងាត់ឡើងវិញ',
  'Add property': 'បន្ថែមអចលនទ្រព្យ',
  'Add your first property': 'បន្ថែមអចលនទ្រព្យដំបូងរបស់អ្នក',
  'New property': 'អចលនទ្រព្យថ្មី',
  'Create property': 'បង្កើតអចលនទ្រព្យ',
  'Add room': 'បន្ថែមបន្ទប់',
  'Edit details': 'កែព័ត៌មាន',
  'Photos': 'រូបភាព',
  'Stock & price': 'ចំនួនបន្ទប់ និងតម្លៃ',
  'Money received': 'បានទទួលប្រាក់',
  'Reject': 'បដិសេធ',
  'Hide': 'លាក់',
  'Publish': 'បង្ហាញ',
  'Check guest in': 'ចុះឈ្មោះភ្ញៀវចូលស្នាក់នៅ',
  'Complete stay': 'បញ្ចប់ការស្នាក់នៅ',
  'Cancel booking': 'បោះបង់ការកក់',
  'Update password': 'ប្តូរពាក្យសម្ងាត់',
  'Sign out of this session': 'ចាកចេញពីសម័យនេះ',

  // Status badges
  'pending': 'រង់ចាំ',
  'pending confirmation': 'រង់ចាំការបញ្ជាក់',
  'confirmed': 'បានបញ្ជាក់',
  'checked in': 'បានចូលស្នាក់នៅ',
  'completed': 'បានបញ្ចប់',
  'cancelled': 'បានបោះបង់',
  'refunded': 'បានបង្វិលប្រាក់',
  'expired': 'ផុតកំណត់',
  'failed': 'បរាជ័យ',
  'success': 'ជោគជ័យ',
  'simulated': 'សាកល្បង',
  'published': 'បានបង្ហាញ',
  'hidden': 'បានលាក់',
  'featured': 'ពេញនិយម',
  'set up': 'បានរៀបចំ',
  'not yet': 'មិនទាន់មាន',
  'active': 'ដំណើរការ',
  'never signed in': 'មិនទាន់ចូលប្រើ',
  'cover': 'រូបក្រប',

  // Overview & Sections
  'Bookings by status': 'ការកក់តាមស្ថានភាព',
  'Bookings over the last 30 days': 'ការកក់ក្នុងរយៈពេល ៣០ ថ្ងៃចុងក្រោយ',
  'AI assistant & planner calls': 'ការហៅប្រើជំនួយការ AI និងផែនការធ្វើដំណើរ',
  'Revenue by booking status': 'ចំណូលតាមស្ថានភាពនៃការកក់',
  'Quick actions': 'សកម្មភាពរហ័ស',
  'Your properties summary': 'សង្ខេបអចលនទ្រព្យរបស់អ្នក',
  'Your payment QR code': 'កូដ QR សម្រាប់ទទួលប្រាក់របស់អ្នក',
  'Guest QR payments': 'ការទូទាត់តាម QR របស់ភ្ញៀវ',
  'Change password': 'ផ្លាស់ប្តូរពាក្យសម្ងាត់',
  'Signed in': 'គណនីកំពុងប្រើប្រាស់',
  'Current password': 'ពាក្យសម្ងាត់បច្ចុប្បន្ន',
  'New password': 'ពាក្យសម្ងាត់ថ្មី',
  'Confirm new password': 'បញ្ជាក់ពាក្យសម្ងាត់ថ្មី',
  'No payments': 'មិនមានការទូទាត់ទេ',
  'No destinations': 'មិនមានគោលដៅទេ',
  'No reviews': 'មិនមានការវាយតម្លៃទេ',
  'No users match': 'មិនមានអ្នកប្រើប្រាស់ត្រូវគ្នាទេ',
  'No audit records': 'មិនមានកំណត់ហេតុទេ',
  'No bookings match these filters': 'មិនមានការកក់ត្រូវនឹងការស្វែងរកនេះទេ',
  'Hello': 'សួស្តី',
  'Admin Analytics Dashboard': 'ផ្ទាំងរបាយការណ៍វិភាគអ្នកគ្រប់គ្រង',
  'Partner Analytics Dashboard': 'ផ្ទាំងរបាយការណ៍វិភាគដៃគូសណ្ឋាគារ',
  'Live platform telemetry & booking performance': 'ទិន្នន័យប្រតិបត្តិការ និងលទ្ធផលនៃការកក់ផ្ទាល់',
  'Occupancy, room inventory & guest revenue report': 'របាយការណ៍អត្រាស្នាក់នៅ ចំនួនបន្ទប់ និងចំណូល',
  'Reservation pipeline distribution': 'ការបែងចែកការកក់តាមស្ថានភាព',
  'Catalog & user activity': 'ទិន្នន័យសរុប និងសកម្មភាពអ្នកប្រើប្រាស់',
  'Active entities across modules': 'ទិន្នន័យសកម្មនៅទូទាំងប្រព័ន្ធ',
  'Platform growth & booking discovery data': 'កំណើនប្រព័ន្ធ និងទិន្នន័យការកក់ប្រចាំខែ',
  'See insights on how bookings, revenue and trips have grown over the last 30 days': 'មើលការវិភាគអំពីកំណើននៃការកក់ ចំណូល និងផែនការធ្វើដំណើរក្នុងរយៈពេល ៣០ ថ្ងៃ',
  'Property revenue & booking activity': 'ចំណូលអចលនទ្រព្យ និងសកម្មភាពនៃការកក់',
  'See how your room bookings and earnings have performed over the last 30 days': 'មើលលទ្ធផលនៃការកក់បន្ទប់ និងចំណូលរបស់អ្នកក្នុងរយៈពេល ៣០ ថ្ងៃចុងក្រោយ',
  'Total Growth': 'កំណើនសរុប',
  'Revenue Growth': 'កំណើនចំណូល',
  'Catalog Reach': 'ទិន្នន័យសរុប',
  'Reviews & Trips': 'មតិយោបល់ និងដំណើរកម្សាន្ត',
  'Fulfillment': 'អត្រាជោគជ័យ',
  'Net Revenue': 'ចំណូលសុទ្ធ',
  'Booked Revenue': 'ចំណូលបានកក់',
  'Catalog Target': 'គោលដៅទិន្នន័យសរុប',
  'Occupancy Target': 'គោលដៅអត្រាស្នាក់នៅ',
  'reached': 'សម្រេចបាន',
  'Status Share': 'សមាមាត្រតាមស្ថានភាព',
  'Proportion of bookings by stage': 'ភាគរយនៃការកក់តាមដំណាក់កាល',
  'Reservation Mix': 'សមាមាត្រនៃការកក់',
  'Share of bookings by stage': 'ភាគរយនៃការកក់តាមស្ថានភាព',
  'Currency Exchange': 'គណនាអត្រាប្តូរប្រាក់',
  'Receive': 'ទទួលបាន',
  'Swap USD ⇄ KHR': 'ប្តូរ USD ⇄ KHR',
  'Trips': 'ដំណើរកម្សាន្ត',
  'Analytics': 'របាយការណ៍វិភាគ',
  'Reservations & Finance': 'ការកក់ និងហិរញ្ញវត្ថុ',
  'Catalog Management': 'គ្រប់គ្រងទិន្នន័យទេសចរណ៍',
  'Property Management': 'គ្រប់គ្រងអចលនទ្រព្យ',
  'Manage Users': 'គ្រប់គ្រងអ្នកប្រើប្រាស់',
  'Settings': 'ការកំណត់',
  'All Categories (Grouped)': 'គ្រប់ប្រភេទ (បែងចែកតាមក្រុម)',
  'Administrators': 'អ្នកអភិបាលប្រព័ន្ធ',
  'Staff': 'បុគ្គលិកប្រតិបត្តិការ',
  'Operations Staff': 'បុគ្គលិកប្រតិបត្តិការ',
  'Hotel Partners': 'ដៃគូសណ្ឋាគារ',
  'Customers': 'អតិថិជន',
  'Customers & Travelers': 'អតិថិជន និងអ្នកធ្វើដំណើរ',
  'Administrators & Operations Staff': 'អ្នកអភិបាល និងបុគ្គលិកប្រតិបត្តិការ',
  'Category': 'ប្រភេទគណនី',
  'Manage Partner Businesses': 'គ្រប់គ្រងអាជីវកម្មដៃគូ',
  'Users & Partner Accounts': 'គណនីអ្នកប្រើប្រាស់ និងដៃគូ',
  'Destinations, Hotels & Reviews': 'គោលដៅ សណ្ឋាគារ និងការវាយតម្លៃ',
  'Bookings & Payments': 'ការកក់ និងការទូទាត់ប្រាក់',
};

/** Pages add their own Khmer strings (English text -> Khmer). */
export function addTranslations(map) { Object.assign(KM, map); }

let currentLang = localStorage.getItem('wf.lang') === 'km' ? 'km' : 'en';
document.documentElement.lang = currentLang;
const langListeners = new Set();

export const getLang = () => currentLang;
export function setLang(lang) {
  currentLang = lang === 'km' ? 'km' : 'en';
  localStorage.setItem('wf.lang', currentLang);
  document.documentElement.lang = currentLang;
  langListeners.forEach((fn) => fn(currentLang));
}
export function onLangChange(fn) {
  langListeners.add(fn);
  return () => langListeners.delete(fn);
}

export function t(str) {
  if (typeof str !== 'string' || currentLang !== 'km') return str;
  const trimmed = str.trim();
  if (KM[trimmed]) return str.replace(trimmed, KM[trimmed]);
  return str;
}

export function langSwitchButton(extraClass = '', { iconOnly = false } = {}) {
  const isKm = currentLang === 'km';
  return h('button', {
    class: `btn small lang-btn${iconOnly ? ' icon-only' : ''} ${extraClass}`.trim(),
    type: 'button',
    title: isKm ? 'Switch to English' : 'ប្តូរទៅភាសាខ្មែរ',
    'aria-label': isKm ? 'Switch to English' : 'ប្តូរទៅភាសាខ្មែរ',
    onclick: () => setLang(isKm ? 'en' : 'km'),
  }, icon('globe'), iconOnly ? null : (isKm ? 'ខ្មែរ · EN' : 'EN · ខ្មែរ'));
}

export function h(tag, props, ...children) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(props || {})) {
    if (v == null || v === false) continue;
    if (k === 'class') el.className = v;
    else if (k.startsWith('on') && typeof v === 'function') el.addEventListener(k.slice(2).toLowerCase(), v);
    else if (k === 'value') el.value = v;
    else if (k === 'checked' || k === 'disabled' || k === 'selected' || k === 'required' || k === 'hidden') el[k] = !!v;
    else if (k === 'placeholder' || k === 'title' || k === 'aria-label') el.setAttribute(k, t(String(v)));
    else el.setAttribute(k, v === true ? '' : String(v));
  }
  append(el, children);
  return el;
}

export function append(el, children) {
  for (const c of children.flat(Infinity)) {
    if (c == null || c === false) continue;
    el.append(c instanceof Node ? c : document.createTextNode(t(String(c))));
  }
  return el;
}

export const clear = (el) => { while (el.firstChild) el.removeChild(el.firstChild); return el; };

const ICONS = {
  compass: 'M12 2a10 10 0 100 20 10 10 0 000-20zm4.2 5.8l-2.6 6.6-6.6 2.6 2.6-6.6 6.6-2.6z',
  home: 'M3 11l9-8 9 8v9a1 1 0 01-1 1h-5v-6H9v6H4a1 1 0 01-1-1z',
  users: 'M16 11a4 4 0 10-8 0 4 4 0 008 0zM4 21a8 8 0 0116 0',
  ticket: 'M3 8a2 2 0 002-2h14a2 2 0 002 2v2a2 2 0 000 4v2a2 2 0 00-2 2H5a2 2 0 00-2-2v-2a2 2 0 000-4z',
  card: 'M3 6h18v12H3zM3 10h18',
  star: 'M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z',
  map: 'M9 4L3 6v14l6-2 6 2 6-2V4l-6 2zM9 4v14M15 6v14',
  bed: 'M3 18V6M3 14h18v4M21 14v-3a3 3 0 00-3-3h-7v6M7 11h.01',
  log: 'M6 3h9l4 4v14H6zM9 12h7M9 16h7M9 8h3',
  bot: 'M5 9h14v10H5zM12 5v4M9 14h.01M15 14h.01',
  chart: 'M4 20V10M10 20V4M16 20v-8M22 20H2',
  out: 'M15 4h4v16h-4M10 8l-4 4 4 4M6 12h10',
  plus: 'M12 5v14M5 12h14',
  image: 'M3 5h18v14H3zM3 16l5-5 4 4 3-3 6 6M8.5 9.5h.01',
  key: 'M14.5 10a4.5 4.5 0 10-4.2-3M10.5 9.5L3 17v4h4v-2h2v-2h2l2.5-2.5',
  menu: 'M4 7h16M4 12h16M4 17h16',
  x: 'M6 6l12 12M18 6L6 18',
  edit: 'M4 20h4L19 9l-4-4L4 16zM13 7l4 4',
  trash: 'M5 7h14M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3',
  moon: 'M20 14A8 8 0 019.5 3.5 8 8 0 1020 14z',
  calendar: 'M4 6h16v14H4zM4 10h16M8 3v4M16 3v4',
  eye: 'M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7-10-7-10-7zm10 3a3 3 0 100-6 3 3 0 000 6z',
  eyeOff: 'M17.94 17.94A10.07 10.07 0 0112 19c-6.4 0-10-7-10-7a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c6.4 0 10 7 10 7a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24M3 3l18 18',
  check: 'M20 6L9 17l-5-5',
  alert: 'M12 9v4M12 17h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z',
  refresh: 'M23 4v6h-6M1 20v-6h6M3.51 9a9 9 0 0114.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0020.49 15',
  chevronDown: 'M6 9l6 6 6-6',
  sortNeutral: 'M8 9l4-4 4 4M16 15l-4 4-4-4',
  sortAsc: 'M12 19V5M6 11l6-6 6 6',
  sortDesc: 'M12 5v14M18 13l-6 6-6-6',
  globe: 'M12 2a10 10 0 100 20 10 10 0 000-20zM2 12h20M12 2a15.3 15.3 0 014 10 15.3 15.3 0 01-4 10 15.3 15.3 0 01-4-10 15.3 15.3 0 014-10z',
};

export function icon(name) {
  const svg = document.createElementNS(SVG_NS, 'svg');
  svg.setAttribute('viewBox', '0 0 24 24');
  svg.setAttribute('fill', 'none');
  svg.setAttribute('stroke', 'currentColor');
  svg.setAttribute('stroke-width', '1.9');
  svg.setAttribute('stroke-linecap', 'round');
  svg.setAttribute('stroke-linejoin', 'round');
  svg.setAttribute('aria-hidden', 'true');
  const p = document.createElementNS(SVG_NS, 'path');
  p.setAttribute('d', ICONS[name] || ICONS.home);
  svg.append(p);
  return svg;
}

/* ---------- formatting ---------- */
export const money = (v) => (v == null ? '-' : new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(Number(v)));
export const num = (v) => (v == null ? '-' : new Intl.NumberFormat('en-US').format(Number(v)));
export const date = (v) => (v ? new Date(`${String(v).slice(0, 10)}T00:00:00`).toLocaleDateString(currentLang === 'km' ? 'km-KH' : undefined, { day: 'numeric', month: 'short', year: 'numeric' }) : '-');
export const dateTime = (v) => (v ? new Date(v).toLocaleString(currentLang === 'km' ? 'km-KH' : undefined, { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }) : '-');
export const todayIso = () => new Date().toISOString().slice(0, 10);

const STATUS_TONE = {
  CONFIRMED: 'ok', COMPLETED: 'ok', SUCCESS: 'ok', published: 'ok', REFUNDED: 'info', CHECKED_IN: 'info',
  PENDING_CONFIRMATION: 'warn', PENDING: 'warn', REFUND_PENDING: 'warn', CANCELLED: 'bad', EXPIRED: 'neutral', FAILED: 'bad', hidden: 'neutral',
};
export const badge = (status) => {
  const raw = String(status ?? '-').replaceAll('_', ' ').toLowerCase();
  return h('span', { class: `badge ${STATUS_TONE[status] || 'neutral'}` }, t(raw));
};
export const stars = (n) => h('span', { class: 'stars', 'aria-label': `${n} stars` }, '★'.repeat(Number(n) || 0));

/* ---------- toasts ---------- */
let toastBox;
export function toast(message, kind = '') {
  if (!toastBox) { toastBox = h('div', { class: 'toasts', role: 'status', 'aria-live': 'polite' }); document.body.append(toastBox); }
  const node = h('div', { class: `toast ${kind}` }, message);
  toastBox.append(node);
  setTimeout(() => node.remove(), kind === 'bad' ? 6000 : 3400);
}

/* ---------- modal ---------- */
/** Opens a dialog. `body` is a Node; `actions` are buttons. Returns { close, setBusy }. */
export function modal({ title, body, actions = [], width = 640, onClose }) {
  const previous = document.activeElement;
  const close = () => {
    closeAllCustomSelects();
    overlay.remove();
    document.removeEventListener('keydown', onKey);
    previous?.focus?.();
    onClose?.();
  };
  const onKey = (e) => { if (e.key === 'Escape') close(); };
  const overlay = h('div', { class: 'overlay', onclick: (e) => { if (e.target === overlay) close(); } },
    h('div', { class: 'modal', role: 'dialog', 'aria-modal': 'true', 'aria-label': title, style: `--w:${width}px` },
      h('div', { class: 'modal-head' }, h('h2', {}, title), h('button', { class: 'btn small', type: 'button', 'aria-label': 'Close', onclick: close }, icon('x'))),
      h('div', { class: 'modal-body' }, body),
      actions.length ? h('div', { class: 'modal-foot' }, actions) : null));
  document.body.append(overlay);
  document.addEventListener('keydown', onKey);
  overlay.querySelector('input, .cselect-btn, textarea, button.primary')?.focus();
  const setBusy = (busy) => overlay.querySelectorAll('.modal-foot button').forEach((b) => { b.disabled = busy; });
  return { close, setBusy };
}

export function confirmDialog({ title, message, confirmLabel = 'Confirm', danger = false }) {
  return new Promise((resolve) => {
    let done = false;
    const finish = (v) => { if (!done) { done = true; resolve(v); } m.close(); };
    const m = modal({
      title, width: 440, body: h('p', { class: 'dialog-msg' }, message), onClose: () => { if (!done) { done = true; resolve(false); } },
      actions: [h('button', { class: 'btn', type: 'button', onclick: () => finish(false) }, 'Cancel'),
        h('button', { class: `btn ${danger ? 'danger' : 'primary'}`, type: 'button', onclick: () => finish(true) }, danger ? icon('trash') : null, confirmLabel)],
    });
  });
}

/**
 * Celebratory pop-up dialog shown after creating or updating a record.
 */
export function successDialog({ title, message, details = [], extra = null, buttonLabel = 'Done' }) {
  return new Promise((resolve) => {
    let done = false;
    const finish = () => { if (!done) { done = true; resolve(); } m.close(); };
    const rows = details.filter((d) => d && d[1] != null && d[1] !== '');
    const m = modal({
      title,
      width: 500,
      onClose: () => { if (!done) { done = true; resolve(); } },
      body: h('div', { class: 'success-pop' },
        h('div', { class: 'success-badge', 'aria-hidden': 'true' }, icon('check')),
        h('div', { class: 'success-copy' },
          h('h3', {}, title),
          message ? h('p', { class: 'muted' }, message) : null),
        rows.length
          ? h('dl', { class: 'kv success-kv' }, rows.flatMap(([k, v]) => [h('dt', {}, k), h('dd', {}, v)]))
          : null,
        extra),
      actions: [h('button', { class: 'btn primary', type: 'button', onclick: finish }, icon('check'), buttonLabel)],
    });
  });
}

/* ---------- form helpers & validation ---------- */
const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

function clearFieldInvalid(el) {
  el.classList.remove('invalid');
  el.removeAttribute('aria-invalid');
  const wrap = el.closest('.field');
  wrap?.querySelector('.field-error')?.remove();
}

export function markFieldInvalid(el, message) {
  if (!el) return;
  el.classList.add('invalid');
  el.setAttribute('aria-invalid', 'true');
  const wrap = el.closest('.field');
  if (wrap) {
    wrap.querySelector('.field-error')?.remove();
    wrap.append(h('div', { class: 'field-error', role: 'alert' }, message));
  }
}

export function validate(rules, box = null) {
  const errs = [];
  let firstInput = null;
  for (const r of rules) {
    if (!r || !r.input) continue;
    clearFieldInvalid(r.input);
    const raw = String(r.input.value ?? '').trim();
    const label = r.label || 'This field';
    let msg = null;

    if (r.required && !raw) {
      msg = `${label} is required.`;
    } else if (raw) {
      if (r.minLen != null && raw.length < r.minLen) msg = `${label} must be at least ${r.minLen} characters (currently ${raw.length}).`;
      else if (r.maxLen != null && raw.length > r.maxLen) msg = `${label} must be at most ${r.maxLen} characters.`;
      else if (r.email && !EMAIL_RE.test(raw)) msg = `Enter a valid email address (e.g. name@example.com).`;
      else if (r.pattern && !r.pattern.test(raw)) msg = r.patternMsg || `${label} format is invalid.`;
      else if (r.min != null || r.max != null) {
        const n = Number(raw);
        if (Number.isNaN(n)) msg = `${label} must be a valid number.`;
        else if (r.min != null && r.max != null && (n < r.min || n > r.max)) msg = `${label} must be between ${r.min} and ${r.max}.`;
        else if (r.min != null && n < r.min) msg = `${label} must be at least ${r.min}.`;
        else if (r.max != null && n > r.max) msg = `${label} must be at most ${r.max}.`;
      }
    }
    if (!msg && typeof r.custom === 'function') {
      msg = r.custom(raw, r.input);
    }
    if (msg) {
      markFieldInvalid(r.input, msg);
      errs.push({ path: label, message: msg });
      if (!firstInput) firstInput = r.input;
    }
  }
  if (errs.length) {
    if (box) showErrors(box, { message: errs.length === 1 ? errs[0].message : `Please fix ${errs.length} highlighted fields before continuing.`, details: errs.length > 1 ? errs : [] });
    firstInput?.focus?.();
    return false;
  }
  if (box) clear(box);
  return true;
}

export function field(label, inputEl, { hint, full = false, id, required = false } = {}) {
  const fid = id || `f${Math.random().toString(36).slice(2, 8)}`;
  inputEl.id = fid;
  inputEl.addEventListener('input', () => clearFieldInvalid(inputEl));
  inputEl.addEventListener('change', () => clearFieldInvalid(inputEl));
  let control = inputEl;
  if (inputEl.tagName === 'INPUT' && inputEl.type === 'password') {
    const toggle = h('button', {
      class: 'pw-toggle',
      type: 'button',
      'aria-label': 'Show password',
      title: 'Show password',
      onclick: () => {
        const show = inputEl.type === 'password';
        inputEl.type = show ? 'text' : 'password';
        toggle.setAttribute('aria-label', show ? 'Hide password' : 'Show password');
        toggle.title = show ? 'Hide password' : 'Show password';
        toggle.replaceChildren(icon(show ? 'eyeOff' : 'eye'));
        inputEl.focus();
      },
    }, icon('eye'));
    control = h('div', { class: 'pw-wrap' }, inputEl, toggle);
  }
  const reqMark = (required || inputEl.required) ? h('span', { class: 'req-star', 'aria-hidden': 'true' }, ' *') : null;
  return h('div', { class: `field ${full ? 'full' : ''}` }, h('label', { for: fid }, label, reqMark), control, hint ? h('div', { class: 'hint' }, hint) : null);
}
export const input = (props) => h('input', { class: 'input', ...props });
export const textarea = (props) => h('textarea', { class: 'input', ...props });

/* ---------- Custom Dropdown Select (replaces native OS <select> popup) ---------- */
const openSelectCleanups = new Set();
function closeAllCustomSelects() {
  openSelectCleanups.forEach((fn) => fn());
  openSelectCleanups.clear();
}
document.addEventListener('click', (e) => {
  if (!e.target.closest('.cselect') && !e.target.closest('.cselect-menu')) {
    closeAllCustomSelects();
  }
});
window.addEventListener('resize', closeAllCustomSelects);
window.addEventListener('scroll', (e) => {
  if (e.target && e.target.classList && e.target.classList.contains('cselect-menu')) return;
  closeAllCustomSelects();
}, true);

export function select(options, value, props = {}) {
  const normalized = options.map((o) => {
    const [v, label] = Array.isArray(o) ? o : [o, o];
    return { value: String(v ?? ''), label: t(String(label ?? v ?? '')) };
  });

  let currentVal = value != null ? String(value) : (normalized[0]?.value ?? '');
  if (!normalized.some((o) => o.value === currentVal) && normalized.length) {
    currentVal = normalized[0].value;
  }

  const labelSpan = h('span', { class: 'cselect-label' });
  const arrowSpan = h('span', { class: 'cselect-arrow', 'aria-hidden': 'true' }, icon('chevronDown'));
  const btn = h('button', {
    class: 'cselect-btn',
    type: 'button',
    'aria-haspopup': 'listbox',
    'aria-expanded': 'false',
    ...(props['aria-label'] ? { 'aria-label': props['aria-label'] } : {}),
  }, labelSpan, arrowSpan);

  const root = h('div', { class: 'cselect' }, btn);
  let menuEl = null;

  function syncLabel() {
    const found = normalized.find((o) => o.value === currentVal) || normalized[0];
    labelSpan.textContent = found ? found.label : '';
  }
  syncLabel();

  function closeMenu() {
    if (!menuEl) return;
    menuEl.remove();
    menuEl = null;
    root.classList.remove('open');
    btn.setAttribute('aria-expanded', 'false');
    openSelectCleanups.delete(closeMenu);
  }

  function selectValue(nextVal, fireEvent = true) {
    const prev = currentVal;
    currentVal = String(nextVal ?? '');
    syncLabel();
    closeMenu();
    if (fireEvent && prev !== currentVal) {
      const evt = new Event('change', { bubbles: true });
      root.dispatchEvent(evt);
      root.dispatchEvent(new Event('input', { bubbles: true }));
    }
  }

  function openMenu() {
    if (root.disabled) return;
    if (menuEl) { closeMenu(); return; }
    closeAllCustomSelects();

    const items = normalized.map((opt) => {
      const active = opt.value === currentVal;
      return h('button', {
        class: `cselect-opt ${active ? 'active' : ''}`.trim(),
        type: 'button',
        role: 'option',
        'aria-selected': active ? 'true' : 'false',
        onclick: (e) => {
          e.stopPropagation();
          selectValue(opt.value, true);
          btn.focus();
        },
      },
      h('span', { class: 'cselect-opt-text' }, opt.label),
      active ? h('span', { class: 'cselect-check' }, icon('check')) : null);
    });

    menuEl = h('div', { class: 'cselect-menu', role: 'listbox' }, items);
    document.body.append(menuEl);

    const rect = btn.getBoundingClientRect();
    const menuWidth = Math.max(rect.width, 185);
    menuEl.style.minWidth = `${menuWidth}px`;
    const spaceBelow = window.innerHeight - rect.bottom - 12;
    const menuHeight = Math.min(280, menuEl.scrollHeight || 220);
    const openUp = spaceBelow < menuHeight && rect.top > spaceBelow;

    menuEl.style.left = `${Math.min(rect.left, window.innerWidth - menuWidth - 12)}px`;
    if (openUp) {
      menuEl.style.top = `${Math.max(8, rect.top - menuHeight - 6)}px`;
    } else {
      menuEl.style.top = `${rect.bottom + 6}px`;
    }

    root.classList.add('open');
    btn.setAttribute('aria-expanded', 'true');
    openSelectCleanups.add(closeMenu);

    const activeBtn = menuEl.querySelector('.cselect-opt.active') || menuEl.querySelector('.cselect-opt');
    activeBtn?.scrollIntoView?.({ block: 'nearest' });
  }

  btn.addEventListener('click', (e) => {
    e.stopPropagation();
    openMenu();
  });

  btn.addEventListener('keydown', (e) => {
    if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
      e.preventDefault();
      if (!menuEl) {
        openMenu();
      } else {
        const idx = normalized.findIndex((o) => o.value === currentVal);
        const nextIdx = e.key === 'ArrowDown'
          ? Math.min(normalized.length - 1, idx + 1)
          : Math.max(0, idx - 1);
        if (normalized[nextIdx]) selectValue(normalized[nextIdx].value, true);
      }
    } else if (e.key === 'Escape' && menuEl) {
      e.stopPropagation();
      closeMenu();
    }
  });

  Object.defineProperty(root, 'value', {
    get: () => currentVal,
    set: (v) => { currentVal = String(v ?? ''); syncLabel(); },
  });
  Object.defineProperty(root, 'disabled', {
    get: () => btn.disabled,
    set: (v) => { btn.disabled = !!v; root.classList.toggle('is-disabled', !!v); },
  });
  root.focus = () => btn.focus();

  for (const [k, v] of Object.entries(props || {})) {
    if (v == null || v === false || k === 'aria-label') continue;
    if (k === 'class') root.classList.add(...String(v).split(/\s+/).filter(Boolean));
    else if (k.startsWith('on') && typeof v === 'function') root.addEventListener(k.slice(2).toLowerCase(), v);
    else if (k === 'disabled' || k === 'required') root[k] = !!v;
    else root.setAttribute(k, String(v));
  }

  return root;
}

export const checkbox = (label, checked) => { const i = h('input', { type: 'checkbox', checked }); return { el: h('label', { class: 'check' }, i, label), input: i }; };

/** Shows API validation details under a form. */
export function showErrors(box, error) {
  clear(box);
  if (!error) return;
  const details = Array.isArray(error.details) ? error.details : [];
  const banner = h('div', { class: 'error-banner', role: 'alert' },
    icon('alert'),
    h('div', { class: 'stack', style: 'gap:4px' },
      h('div', { class: 'error-text' }, error.message || 'Something went wrong'),
      ...details.map((d) => h('div', { class: 'error-text small' }, `• ${d.path}: ${d.message}`))));
  box.append(banner);
}

/* ---------- Sortable Data Table (Big→Small amount, A→Z / Z→A, Date) ---------- */
function extractCellSortValue(col, row) {
  if (typeof col.sortValue === 'function') return col.sortValue(row);
  if (col.key && row[col.key] != null) return row[col.key];
  const rendered = col.render ? col.render(row) : (row[col.key] ?? '');
  const text = rendered instanceof Node ? (rendered.textContent || '').trim() : String(rendered ?? '').trim();
  if (!text || text === '-') return col.num ? -Infinity : '';

  if (col.num) {
    // Parse currency ($112.00), numbers (1,234.5), ratings (4.8 (12)), percentages (75%), latency (42 ms)
    const m = text.replace(/,/g, '').match(/-?\d+(\.\d+)?/);
    return m ? parseFloat(m[0]) : -Infinity;
  }

  // Check if currency/numeric string even when col.num isn't set
  if (/^\$?-?\d[\d,]*(\.\d+)?%?$/.test(text)) {
    return parseFloat(text.replace(/[^0-9.-]+/g, ''));
  }

  return text;
}

const collator = new Intl.Collator(undefined, { numeric: true, sensitivity: 'base' });

export function table({ columns, rows, onRowClick, empty = 'Nothing here yet', startIndex = 1 }) {
  if (!rows.length) return h('div', { class: 'empty' }, h('strong', {}, empty));

  const originalRows = [...rows];
  const rowOriginalIndex = new Map(originalRows.map((r, i) => [r, startIndex + i]));
  const allColumns = [
    {
      label: 'No.',
      isRowNo: true,
      sortValue: (r) => rowOriginalIndex.get(r) ?? 0,
      render: (_r, displayIdx) => h('span', { class: 'row-no-badge' }, String(startIndex + displayIdx)),
    },
    ...columns,
  ];
  let sortColIdx = -1;
  let sortDir = null; // 'asc' | 'desc' | null

  const tbody = h('tbody', {});

  function renderBody(list) {
    tbody.replaceChildren(...list.map((r, displayIdx) => h('tr', {
      class: onRowClick ? 'click' : '',
      tabindex: onRowClick ? 0 : null,
      onclick: onRowClick ? () => onRowClick(r) : null,
      onkeydown: onRowClick ? (e) => { if (e.key === 'Enter') onRowClick(r); } : null,
    }, allColumns.map((c) => h('td', {
      class: `${c.num ? 'num ' : ''}${c.isRowNo ? 'col-no' : ''}`.trim(),
    }, c.render ? c.render(r, displayIdx) : (r[c.key] ?? '-'))))));
  }

  const thEls = allColumns.map((c, idx) => {
    const labelText = (c.label || '').trim();
    const isSortable = labelText.length > 0 && c.sortable !== false;
    if (!isSortable) return h('th', { class: `${c.num ? 'num ' : ''}${c.isRowNo ? 'col-no' : ''}`.trim() }, c.label);

    const sortIconWrap = h('span', { class: 'th-sort-icon', 'aria-hidden': 'true' }, icon('sortNeutral'));
    const th = h('th', {
      class: `${c.num ? 'num ' : ''}${c.isRowNo ? 'col-no ' : ''}sortable`.trim(),
      tabindex: 0,
      role: 'columnheader',
      'aria-sort': 'none',
      title: c.num ? 'Click to sort Big → Small / Small → Big' : 'Click to sort A → Z / Z → A',
      onclick: () => toggleSort(idx),
      onkeydown: (e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          toggleSort(idx);
        }
      },
    },
    h('span', { class: 'th-inner' }, h('span', {}, c.label), sortIconWrap));

    th._updateSortUI = (active, dir) => {
      th.classList.toggle('sorted', active);
      th.setAttribute('aria-sort', !active ? 'none' : dir === 'asc' ? 'ascending' : 'descending');
      sortIconWrap.replaceChildren(icon(!active ? 'sortNeutral' : dir === 'asc' ? 'sortAsc' : 'sortDesc'));
    };
    return th;
  });

  function toggleSort(idx) {
    const col = allColumns[idx];
    if (sortColIdx !== idx) {
      sortColIdx = idx;
      // Numeric/amount columns default to Big -> Small ('desc') on first click; text columns default to A -> Z ('asc')
      sortDir = col.num ? 'desc' : 'asc';
    } else if (col.num) {
      sortDir = sortDir === 'desc' ? 'asc' : sortDir === 'asc' ? null : 'desc';
    } else {
      sortDir = sortDir === 'asc' ? 'desc' : sortDir === 'desc' ? null : 'asc';
    }
    if (!sortDir) sortColIdx = -1;

    thEls.forEach((th, i) => th._updateSortUI?.(i === sortColIdx && !!sortDir, sortDir));

    if (!sortDir) {
      renderBody(originalRows);
      return;
    }

    const sorted = [...originalRows].sort((a, b) => {
      const va = extractCellSortValue(col, a);
      const vb = extractCellSortValue(col, b);
      let cmp = 0;
      if (typeof va === 'number' && typeof vb === 'number') {
        cmp = va - vb;
      } else {
        cmp = collator.compare(String(va ?? ''), String(vb ?? ''));
      }
      return sortDir === 'asc' ? cmp : -cmp;
    });
    renderBody(sorted);
  }

  renderBody(originalRows);
  return h('div', { class: 'table-wrap' }, h('table', {}, h('thead', {}, h('tr', {}, thEls)), tbody));
}

export function pager({ page, pageSize, total, onChange }) {
  const pages = Math.max(1, Math.ceil(total / pageSize));
  const from = total ? (page - 1) * pageSize + 1 : 0, to = Math.min(total, page * pageSize);
  return h('div', { class: 'pager' }, h('span', { class: 'muted small' }, `${from}–${to} of ${num(total)}`),
    h('div', { class: 'row' },
      h('button', { class: 'btn small', type: 'button', disabled: page <= 1, onclick: () => onChange(page - 1) }, 'Previous'),
      h('span', { class: 'small' }, `Page ${page} of ${pages}`),
      h('button', { class: 'btn small', type: 'button', disabled: page >= pages, onclick: () => onChange(page + 1) }, 'Next')));
}

export const skeleton = (lines = 4) => h('div', { class: 'card card-pad', 'aria-busy': 'true' }, Array.from({ length: lines }, () => h('div', { class: 'skeleton', style: 'margin:10px 0' })));
export const debounce = (fn, ms = 300) => { let tId; return (...a) => { clearTimeout(tId); tId = setTimeout(() => fn(...a), ms); }; };

/* ---------- clipboard ---------- */
export function copyButton(text, label = 'Copy') {
  const b = h('button', { class: 'btn small', type: 'button', onclick: async () => {
    try { await navigator.clipboard.writeText(text); b.textContent = t('Copied ✓'); setTimeout(() => { b.textContent = t(label); }, 1500); } catch { toast('Select the text and copy it manually', 'bad'); }
  } }, label);
  return b;
}

/* ---------- image picker ---------- */
export function imagePicker({ current = null, label = 'Choose image', upload, round = false }) {
  let url = current;
  const preview = h('div', { class: `img-preview ${round ? 'round' : ''}` });
  const status = h('span', { class: 'hint' });
  const draw = () => { preview.replaceChildren(url ? h('img', { src: url, alt: '' }) : h('span', { class: 'muted small' }, 'No image')); };
  const file = h('input', { type: 'file', accept: 'image/png,image/jpeg,image/webp', class: 'sr-only', tabindex: -1,
    onchange: async () => {
      const f = file.files[0];
      if (!f) return;
      if (!['image/png', 'image/jpeg', 'image/webp'].includes(f.type)) {
        status.textContent = 'Only PNG, JPEG or WebP images are supported.';
        status.className = 'field-error';
        file.value = '';
        return;
      }
      if (f.size > 2 * 1024 * 1024) {
        status.textContent = 'That file is over 2 MB. Please choose a smaller image.';
        status.className = 'field-error';
        file.value = '';
        return;
      }
      status.className = 'hint';
      status.textContent = 'Uploading...';
      try {
        const r = await upload(f);
        url = r.url;
        status.textContent = 'Uploaded ✓';
        draw();
      } catch (e) {
        status.className = 'field-error';
        status.textContent = e.message;
      } finally {
        file.value = '';
      }
    } });
  draw();
  const el = h('div', { class: 'picker' }, preview,
    h('div', { class: 'stack', style: 'gap:6px' }, h('div', { class: 'row' }, h('button', { class: 'btn small', type: 'button', onclick: () => file.click() }, label),
      h('button', { class: 'btn small danger', type: 'button', onclick: () => { url = null; status.textContent = ''; draw(); } }, icon('trash'), 'Remove')), status, h('div', { class: 'hint' }, 'PNG, JPEG or WebP, up to 2 MB'), file));
  return { el, get: () => url, set: (u) => { url = u; draw(); } };
}
