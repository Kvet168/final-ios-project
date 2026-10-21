// One-off curation pass (run after finalize-images): keeps only hand-picked gallery photos per destination,
// sets the cover to the first kept photo and rebuilds the per-property galleries that are derived from them.
// `keep` indexes refer to the destination_images order at the time of review (position 0 = lead image).
import "dotenv/config";
import pg from "pg";

const keep: Record<string, number[]> = {
  "siem-reap": [0, 4, 6], "phnom-penh": [0, 1, 2, 3, 4, 5, 6, 7], bangkok: [0, 1, 2, 3, 4, 5, 6], kyoto: [0, 1, 2, 4, 5, 7], tokyo: [0, 1, 3, 4, 5, 7],
  "hoi-an": [0, 1, 2, 3, 4, 5, 6], singapore: [0, 1, 2, 3, 4, 5, 6, 7], bali: [3, 7, 6, 2, 4, 5, 1], penang: [0, 1, 3, 4, 5, 7], phuket: [0, 2, 3, 4, 6],
  kampot: [0, 1, 2, 3, 4], seoul: [0, 1, 2, 3, 7], "ho-chi-minh-city": [0, 4, 7, 2], "da-nang": [0, 5, 6, 7, 1, 4], hanoi: [0, 1, 5, 6, 7],
  "kuala-lumpur": [7, 0], "chiang-mai": [0, 1], krabi: [0, 1, 2, 5], "koh-rong": [0, 2, 4, 6, 7], yogyakarta: [0, 4, 1, 3, 5], kep: [1, 0, 3, 4, 7],
  battambang: [0, 1, 5], "luang-prabang": [0, 3, 6, 5], sihanoukville: [5, 2, 3, 7, 0], vientiane: [6, 1, 3, 5, 2], mondulkiri: [0, 1, 5, 7],
  ratanakiri: [7, 6, 0, 3], kratie: [0, 1, 3, 5], "kampong-cham": [6, 3, 2, 4, 5], "koh-kong": [0, 4, 2, 6],
};
const galleries: Record<string, { url: string; caption: string | null; credit: string | null }[]> = JSON.parse(process.argv[2] ? (await import("node:fs")).readFileSync(process.argv[2], "utf8") : "{}");

const c = new pg.Client({ connectionString: process.env.DATABASE_URL });
await c.connect();
const q = async <T = any>(s: string, p: unknown[] = []) => (await c.query(s, p)).rows as T[];

for (const [slug, idx] of Object.entries(keep)) {
  const d = (await q<any>("SELECT id FROM destinations WHERE slug=$1", [slug]))[0];
  if (!d) continue;
  const rows = await q<any>("SELECT url, caption, credit FROM destination_images WHERE destination_id=$1 ORDER BY position", [d.id]);
  const picked = idx.map((i) => rows[i]).filter(Boolean);
  // Thin galleries are topped up with the destination's own landmark photos.
  if (picked.length < 5) {
    const extra = await q<any>(
      `SELECT image AS url, name AS caption, image_credit AS credit FROM attractions WHERE destination_id=$1 AND image IS NOT NULL AND kind <> 'restaurant'
        ORDER BY (category IN ('landmark','temple','nature')) DESC, name LIMIT 6`, [d.id]);
    for (const e of extra) if (!picked.some((p) => p.url === e.url) && picked.length < 5) picked.push(e);
  }
  if (!picked.length) continue;
  await q("DELETE FROM destination_images WHERE destination_id=$1", [d.id]);
  for (const [pos, p] of picked.entries()) {
    await q("INSERT INTO destination_images(destination_id,url,caption,credit,position) VALUES ($1,$2,$3,$4,$5)", [d.id, p.url, p.caption, p.credit, pos]);
  }
  await q("UPDATE destinations SET cover_image=$2, image_credit=COALESCE($3, image_credit) WHERE id=$1", [d.id, picked[0].url, picked[0].credit]);
  console.log(slug, picked.length);
}

// Rebuild property galleries from the curated destination galleries (same rule as finalize-images).
await q("DELETE FROM accommodation_images");
await q(`INSERT INTO accommodation_images(accommodation_id, url, caption, position)
         SELECT a.id, x.url, 'Illustrative photo of ' || d.name, (row_number() OVER (PARTITION BY a.id ORDER BY x.ord))::int - 1
           FROM accommodations a JOIN destinations d ON d.id=a.destination_id
           JOIN LATERAL (SELECT a.cover_image AS url, 0 AS ord WHERE a.cover_image IS NOT NULL
                         UNION ALL (SELECT di.url, 1 + di.position FROM destination_images di
                                     WHERE di.destination_id=a.destination_id AND di.url IS DISTINCT FROM a.cover_image
                                     ORDER BY md5(di.url || a.slug) LIMIT 3)) x ON true`);
console.log("property galleries rebuilt");
await c.end();
void galleries;
