// Shared pieces of the advertising screens (business portal and admin console): labels, status badges, previews, a small chart and Khmer text.
import { addTranslations, getLang, h, num, t } from './ui.js';

/** Picks the Khmer text when the dashboard is in Khmer and a Khmer version exists, otherwise English. */
export const L = (en, km) => (getLang() === 'km' && km ? km : en);

export const PLACEMENTS = {
  featured_destination: 'Featured Destination',
  top_search: 'Top Search Placement',
  homepage_banner: 'Homepage Banner',
  sponsored_article: 'Sponsored Travel Article',
  festival: 'Festival Campaign',
};

export const CATEGORIES = [
  ['hotel', 'Hotel'], ['resort', 'Resort'], ['restaurant', 'Restaurant'], ['cafe', 'Café'], ['camping', 'Camping site'],
  ['tour_operator', 'Tour operator'], ['activity', 'Activity'], ['shop', 'Shop'], ['other', 'Other'],
];

const TONE = {
  draft: 'neutral', pending_review: 'warn', rejected: 'bad', awaiting_payment: 'info', payment_review: 'warn', scheduled: 'info', active: 'ok', paused: 'neutral', expired: 'neutral', cancelled: 'bad',
  pending: 'warn', claimed: 'warn', verified: 'ok', suspended: 'bad',
};
const LABEL = {
  draft: 'Draft', pending_review: 'In review', rejected: 'Rejected', awaiting_payment: 'Awaiting payment', payment_review: 'Verifying payment', scheduled: 'Scheduled', active: 'Active',
  paused: 'Paused', expired: 'Expired', cancelled: 'Cancelled', pending: 'Pending', claimed: 'Submitted', verified: 'Verified', suspended: 'Suspended',
};
export const statusBadge = (s) => h('span', { class: `badge ${TONE[s] || 'neutral'}` }, LABEL[s] || String(s));
export const STATUS_OPTIONS = (keys) => [['', 'All'], ...keys.map((k) => [k, LABEL[k]])];

export const usd = (v) => (v == null ? '-' : new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(Number(v)));
export const riel = (v) => (v == null ? '-' : `${new Intl.NumberFormat('en-US').format(Number(v))} ៛`);
export const amountOf = (cur, v) => (cur === 'KHR' ? riel(v) : usd(v));
export const pct = (v) => `${Number(v || 0).toFixed(2)}%`;

export function thumb(url) {
  return url ? h('img', { class: 'thumb', src: url, alt: '', loading: 'lazy' }) : h('span', { class: 'thumb empty' }, 'No image');
}

/** How the campaign will look to travellers (a rough preview; the app draws it natively). */
export function preview(c, businessName) {
  const style = c.image_url ? `background-image:url("${String(c.image_url).replace(/"/g, '%22')}")` : '';
  return h('div', { class: 'ad-preview', style },
    h('div', { class: 'in' },
      h('span', { class: 'tag' }, 'Sponsored'),
      h('h4', {}, L(c.title_en, c.title_km) || 'Your title'),
      c.body_en || c.body_km ? h('p', {}, L(c.body_en, c.body_km)) : null,
      c.offer_en || c.offer_km ? h('span', { class: 'offer' }, L(c.offer_en, c.offer_km)) : null,
      businessName ? h('p', { class: 'small' }, businessName) : null));
}

/** Daily impressions (blue) and clicks (green) as bars; no chart library needed. */
export function dailyBars(daily, { height = 150 } = {}) {
  const rows = daily || [];
  const maxImp = Math.max(1, ...rows.map((r) => Number(r.impressions) || 0));
  const maxClk = Math.max(1, ...rows.map((r) => Number(r.clicks) || 0));
  return h('div', { class: 'stack', style: 'gap:8px' },
    h('div', { class: 'bars', style: `height:${height}px`, role: 'img', 'aria-label': t('Impressions and clicks per day') },
      rows.map((r) => h('div', { class: 'col', title: `${String(r.day).slice(5)}: ${num(r.impressions)} / ${num(r.clicks)}` },
        h('i', { class: 'clk', style: `height:${Math.round((Number(r.clicks) || 0) / maxClk * 45)}%` }),
        h('i', { class: 'imp', style: `height:${Math.round((Number(r.impressions) || 0) / maxImp * 55)}%` })))),
    h('div', { class: 'bars-axis' }, h('span', {}, rows.length ? String(rows[0].day).slice(5) : ''), h('span', {}, rows.length ? String(rows[rows.length - 1].day).slice(5) : '')),
    h('div', { class: 'bars-legend' }, h('span', {}, h('b', { style: 'background:var(--brand)' }), 'Impressions'), h('span', {}, h('b', { style: 'background:var(--ok)' }), 'Clicks')));
}

/** Revenue bars (single series). */
export function revenueBars(rows, { height = 150 } = {}) {
  const max = Math.max(1, ...rows.map((r) => Number(r.revenue_usd) || 0));
  return h('div', { class: 'stack', style: 'gap:8px' },
    h('div', { class: 'bars', style: `height:${height}px`, role: 'img', 'aria-label': t('Revenue per day') },
      rows.map((r) => h('div', { class: 'col', title: `${String(r.day).slice(5)}: ${usd(r.revenue_usd)}` },
        h('i', { class: 'imp', style: `height:${Math.round((Number(r.revenue_usd) || 0) / max * 100)}%` })))),
    h('div', { class: 'bars-axis' }, h('span', {}, rows.length ? String(rows[0].day).slice(5) : ''), h('span', {}, rows.length ? String(rows[rows.length - 1].day).slice(5) : '')));
}

export const statCard = (label, value, hint) => h('div', { class: 'card stat anim-card' }, h('div', { class: 'label' }, label), h('div', { class: 'value' }, value), hint ? h('div', { class: 'hint' }, hint) : null);

addTranslations({
  'Advertising': 'ការផ្សព្វផ្សាយ',
  'Campaigns': 'យុទ្ធនាការ',
  'My campaigns': 'យុទ្ធនាការរបស់ខ្ញុំ',
  'Campaign': 'យុទ្ធនាការ',
  'New campaign': 'យុទ្ធនាការថ្មី',
  'Edit campaign': 'កែសម្រួលយុទ្ធនាការ',
  'Ad performance': 'លទ្ធផលផ្សព្វផ្សាយ',
  'Performance': 'លទ្ធផល',
  'Spend & payments': 'ចំណាយ និងការទូទាត់',
  'Business profile': 'ព័ត៌មានអាជីវកម្ម',
  'Business advertising': 'ការផ្សព្វផ្សាយអាជីវកម្ម',
  'Business owners': 'ម្ចាស់អាជីវកម្ម',
  'Impressions': 'ចំនួនបង្ហាញ',
  'Clicks': 'ចំនួនចុច',
  'Click rate': 'អត្រាចុច',
  'Total spent': 'ចំណាយសរុប',
  'Awaiting payment': 'រង់ចាំការទូទាត់',
  'Active campaigns': 'យុទ្ធនាការកំពុងដំណើរការ',
  'Impressions and clicks per day': 'ចំនួនបង្ហាញ និងចុច ក្នុងមួយថ្ងៃ',
  'Revenue per day': 'ចំណូលក្នុងមួយថ្ងៃ',
  'Last 30 days': '៣០ ថ្ងៃចុងក្រោយ',
  'Sponsored': 'ឧបត្ថម្ភ',
  'Draft': 'សេចក្តីព្រាង', 'In review': 'កំពុងពិនិត្យ', 'Rejected': 'បានបដិសេធ', 'Verifying payment': 'កំពុងផ្ទៀងផ្ទាត់ការទូទាត់',
  'Scheduled': 'បានកំណត់ពេល', 'Active': 'កំពុងដំណើរការ', 'Paused': 'ផ្អាក', 'Expired': 'ផុតកំណត់', 'Cancelled': 'បានលុបចោល',
  'Pending': 'កំពុងរង់ចាំ', 'Submitted': 'បានដាក់ស្នើ', 'Verified': 'បានផ្ទៀងផ្ទាត់', 'Suspended': 'ត្រូវបានផ្អាក',
  'Featured Destination': 'គោលដៅពិសេស', 'Top Search Placement': 'ទីតាំងកំពូលក្នុងការស្វែងរក', 'Homepage Banner': 'បដាទំព័រដើម',
  'Sponsored Travel Article': 'អត្ថបទធ្វើដំណើរឧបត្ថម្ភ', 'Festival Campaign': 'យុទ្ធនាការពិធីបុណ្យ',
  'Hotel': 'សណ្ឋាគារ', 'Resort': 'រមណីយដ្ឋាន', 'Restaurant': 'ភោជនីយដ្ឋាន', 'Café': 'ហាងកាហ្វេ', 'Camping site': 'ទីតាំងបោះជំរំ', 'Tour operator': 'ក្រុមហ៊ុនទេសចរណ៍', 'Activity': 'សកម្មភាព', 'Shop': 'ហាង', 'Other': 'ផ្សេងៗ',
  'Package': 'កញ្ចប់', 'Dates': 'កាលបរិច្ឆេទ', 'Status': 'ស្ថានភាព', 'Price': 'តម្លៃ', 'Business': 'អាជីវកម្ម', 'Method': 'វិធីសាស្ត្រ', 'Amount': 'ចំនួនទឹកប្រាក់', 'Reference': 'លេខយោង', 'Date': 'កាលបរិច្ឆេទ',
  'Choose a package': 'ជ្រើសរើសកញ្ចប់', 'How long': 'រយៈពេល', 'Start date': 'ថ្ងៃចាប់ផ្តើម', 'Where should it appear?': 'បង្ហាញនៅទីណា?',
  'All Cambodia': 'ទូទាំងកម្ពុជា', 'Title (English)': 'ចំណងជើង (អង់គ្លេស)', 'Title (Khmer)': 'ចំណងជើង (ខ្មែរ)', 'Short text (English)': 'អត្ថបទខ្លី (អង់គ្លេស)', 'Short text (Khmer)': 'អត្ថបទខ្លី (ខ្មែរ)',
  'Promotional offer (English)': 'ការផ្តល់ជូនពិសេស (អង់គ្លេស)', 'Promotional offer (Khmer)': 'ការផ្តល់ជូនពិសេស (ខ្មែរ)', 'Image': 'រូបភាព', 'Link (https://...)': 'តំណភ្ជាប់ (https://...)',
  'Keywords': 'ពាក្យគន្លឹះ', 'Article (English)': 'អត្ថបទ (អង់គ្លេស)', 'Article (Khmer)': 'អត្ថបទ (ខ្មែរ)', 'Festival name (English)': 'ឈ្មោះពិធីបុណ្យ (អង់គ្លេស)', 'Festival name (Khmer)': 'ឈ្មោះពិធីបុណ្យ (ខ្មែរ)',
  'Save draft': 'រក្សាទុកសេចក្តីព្រាង', 'Submit for review': 'ដាក់ស្នើដើម្បីពិនិត្យ', 'Cancel': 'បោះបង់', 'Close': 'បិទ', 'Save': 'រក្សាទុក', 'Edit': 'កែសម្រួល',
  'Pay now': 'បង់ប្រាក់ឥឡូវនេះ', 'Renew': 'បន្តសុពលភាព', 'Cancel campaign': 'លុបចោលយុទ្ធនាការ', 'Submit': 'ដាក់ស្នើ',
  'Pay with KHQR': 'បង់តាម KHQR', 'Bank transfer': 'ផ្ទេរតាមធនាគារ', 'Currency': 'រូបិយប័ណ្ណ', 'Bank transaction reference': 'លេខយោងប្រតិបត្តិការធនាគារ', 'Payment proof (optional)': 'ភស្តុតាងការទូទាត់ (ស្រេចចិត្ត)',
  'I have paid': 'ខ្ញុំបានបង់ប្រាក់ហើយ', 'Create payment': 'បង្កើតការទូទាត់', 'Amount to pay': 'ចំនួនត្រូវបង់', 'Include this reference in the transfer note': 'សូមដាក់លេខយោងនេះក្នុងកំណត់ត្រាផ្ទេរ',
  'Account name': 'ឈ្មោះគណនី', 'Bank': 'ធនាគារ', 'Account number': 'លេខគណនី',
  'Create a business account': 'បង្កើតគណនីអាជីវកម្ម', 'Your name': 'ឈ្មោះរបស់អ្នក', 'Business name': 'ឈ្មោះអាជីវកម្ម', 'Business type': 'ប្រភេទអាជីវកម្ម', 'Email': 'អ៊ីមែល', 'Password': 'ពាក្យសម្ងាត់', 'Phone': 'ទូរស័ព្ទ',
  'Business name (Khmer)': 'ឈ្មោះអាជីវកម្ម (ខ្មែរ)', 'Description (English)': 'ការពិពណ៌នា (អង់គ្លេស)', 'Description (Khmer)': 'ការពិពណ៌នា (ខ្មែរ)', 'Website': 'គេហទំព័រ', 'Address': 'អាសយដ្ឋាន', 'Main location': 'ទីតាំងសំខាន់', 'Logo': 'និមិត្តសញ្ញា',
  'Verification': 'ការផ្ទៀងផ្ទាត់', 'Packages & pricing': 'កញ្ចប់ និងតម្លៃ', 'Payment settings': 'ការកំណត់ការទូទាត់', 'Placements': 'ទីតាំងបង្ហាញ', 'Businesses': 'អាជីវកម្ម', 'Ad payments': 'ការទូទាត់ផ្សព្វផ្សាយ',
  'Ad campaigns': 'យុទ្ធនាការផ្សព្វផ្សាយ', 'Advertising overview': 'ទិដ្ឋភាពទូទៅនៃការផ្សព្វផ្សាយ', 'Ad revenue': 'ចំណូលពីការផ្សព្វផ្សាយ', 'Verified payments': 'ការទូទាត់ដែលបានផ្ទៀងផ្ទាត់',
  'New package': 'កញ្ចប់ថ្មី', 'New': 'ថ្មី', 'Unit': 'ឯកតា', 'Sort': 'លំដាប់', 'Only an administrator can change prices and packages.': 'មានតែអ្នកគ្រប់គ្រងប្រព័ន្ធប៉ុណ្ណោះដែលអាចកែប្រែតម្លៃ និងកញ្ចប់។',
  'Only an administrator can verify payments.': 'មានតែអ្នកគ្រប់គ្រងប្រព័ន្ធប៉ុណ្ណោះដែលអាចផ្ទៀងផ្ទាត់ការទូទាត់។',
  'Approve': 'អនុម័ត', 'Reject': 'បដិសេធ', 'Verify': 'ផ្ទៀងផ្ទាត់', 'Suspend': 'ផ្អាក', 'Pause': 'ផ្អាកជាបណ្តោះអាសន្ន', 'Resume': 'បន្ត', 'Reschedule': 'កំណត់ពេលឡើងវិញ',
  'Reason': 'មូលហេតុ', 'Note': 'កំណត់ចំណាំ', 'Amount received': 'ចំនួនទឹកប្រាក់ដែលបានទទួល', 'Confirm payment received': 'បញ្ជាក់ថាបានទទួលប្រាក់',
  'Price per unit (USD)': 'តម្លៃក្នុងមួយឯកតា (USD)', 'Days per unit': 'ចំនួនថ្ងៃក្នុងមួយឯកតា', 'Minimum units': 'ឯកតាអប្បបរមា', 'Maximum units': 'ឯកតាអតិបរមា', 'Slots per day': 'ចំនួនកន្លែងក្នុងមួយថ្ងៃ', 'On sale': 'កំពុងលក់',
  'Name (English)': 'ឈ្មោះ (អង់គ្លេស)', 'Name (Khmer)': 'ឈ្មោះ (ខ្មែរ)', 'KHQR image': 'រូបភាព KHQR', 'Bank name': 'ឈ្មោះធនាគារ', 'Transfer instructions': 'ការណែនាំអំពីការផ្ទេរ', 'KHR rounding step': 'ជំហានបង្គត់ប្រាក់រៀល',
  'Outstanding': 'ជំពាក់', 'This month': 'ខែនេះ', 'To review': 'រង់ចាំពិនិត្យ', 'Payments to verify': 'ការទូទាត់រង់ចាំផ្ទៀងផ្ទាត់', 'Businesses to verify': 'អាជីវកម្មរង់ចាំផ្ទៀងផ្ទាត់',
  'Revenue by package': 'ចំណូលតាមកញ្ចប់', 'Top campaigns': 'យុទ្ធនាការល្អបំផុត', 'Free slots left': 'កន្លែងទំនេរ', 'Booked': 'បានកក់', 'Full': 'ពេញ',
  'All': 'ទាំងអស់', 'Search': 'ស្វែងរក', 'Previous': 'មុន', 'Next': 'បន្ទាប់',
  'Your business is waiting for verification. You can prepare campaigns now and submit them once our team has verified your business.': 'អាជីវកម្មរបស់អ្នកកំពុងរង់ចាំការផ្ទៀងផ្ទាត់។ អ្នកអាចរៀបចំយុទ្ធនាការឥឡូវនេះ ហើយដាក់ស្នើនៅពេលក្រុមការងារយើងបានផ្ទៀងផ្ទាត់រួច។',
  'Paid placements are always labelled Sponsored in the app.': 'ការផ្សព្វផ្សាយបង់ប្រាក់ត្រូវបានដាក់ស្លាក «ឧបត្ថម្ភ» ជានិច្ចក្នុងកម្មវិធី។',
  'No campaigns yet': 'មិនទាន់មានយុទ្ធនាការ', 'No payments yet': 'មិនទាន់មានការទូទាត់', 'Nothing to show': 'គ្មានអ្វីត្រូវបង្ហាញ',
  'Sign in with your business account to run advertising campaigns.': 'ចូលដោយប្រើគណនីអាជីវកម្មរបស់អ្នក ដើម្បីដំណើរការយុទ្ធនាការផ្សព្វផ្សាយ។',
  'Try demo business account': 'សាកល្បងគណនីអាជីវកម្មគំរូ',
});
