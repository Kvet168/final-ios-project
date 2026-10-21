// Removes mirrored photos that no database row references any more (from app/web/img and app/assets/img, full size and thumbnails).
import "dotenv/config";
import { existsSync, readdirSync, unlinkSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import pg from "pg";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "..", "app");
const c = new pg.Client({ connectionString: process.env.DATABASE_URL });
await c.connect();
const rows = (await c.query(`SELECT u FROM (SELECT cover_image u FROM destinations UNION SELECT image FROM attractions UNION SELECT cover_image FROM accommodations
   UNION SELECT url FROM destination_images UNION SELECT url FROM accommodation_images) x WHERE u IS NOT NULL`)).rows;
await c.end();
const keep = new Set(rows.map((r: any) => String(r.u).split("?")[0].split("/").pop()));
let removed = 0;
for (const dir of [join(root, "web", "img"), join(root, "web", "img", "t"), join(root, "assets", "img"), join(root, "assets", "img", "t")]) {
  if (!existsSync(dir)) continue;
  for (const f of readdirSync(dir)) if (f.endsWith(".jpg") && !keep.has(f)) { unlinkSync(join(dir, f)); removed++; }
}
console.log("referenced", keep.size, "removed", removed);
