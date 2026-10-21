// One-off curation (run after curate-galleries): hotel photos are illustrative photos of the destination. A few automatic
// picks were unsuitable (drawings, interiors, unrelated subjects); give those properties a curated destination photo instead.
import "dotenv/config";
import pg from "pg";

const replace = [
  "mangrove-guesthouse", "borobudur-valley-villa", "koh-trong-homestay-house", "yaklom-lakeside-bungalows", "mekong-dolphin-lodge", "hongdae-pod-hostel",
  "thu-bon-riverside-villa", "mekong-riverside-hotel", "sukhumvit-sky-hotel", "west-lake-residence", "clarke-quay-courtyard", "campuhan-riverside-retreat",
  "kraton-courtyard-hotel", "old-town-garden-homestay", "patuxai-guesthouse", "harbour-stay-inn",
];

const c = new pg.Client({ connectionString: process.env.DATABASE_URL });
await c.connect();
const q = async <T = any>(s: string, p: unknown[] = []) => (await c.query(s, p)).rows as T[];
const used = new Set((await q<any>("SELECT cover_image FROM accommodations WHERE slug <> ALL($1::text[])", [replace])).map((r) => r.cover_image));

for (const slug of replace) {
  const a = (await q<any>("SELECT id, destination_id FROM accommodations WHERE slug=$1", [slug]))[0];
  if (!a) continue;
  const pool = await q<any>("SELECT url, credit FROM destination_images WHERE destination_id=$1 ORDER BY position", [a.destination_id]);
  const pick = pool.find((p) => !used.has(p.url)) ?? pool[pool.length - 1];
  if (!pick) continue;
  used.add(pick.url);
  const d = (await q<any>("SELECT name FROM destinations WHERE id=$1", [a.destination_id]))[0];
  await q("UPDATE accommodations SET cover_image=$2, image_credit=$3 WHERE id=$1", [a.id, pick.url, `Illustrative photo of ${d.name}, not this property.${pick.credit ? " " + pick.credit : ""}`]);
  console.log("recovered", slug);
}

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
