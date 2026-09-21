#!/usr/bin/env node
// Canvas API helper for opencode class agents.
// Reads credentials from this folder's .env (or real environment variables):
//   CANVAS_API_TOKEN=<your access token>
//   CANVAS_API_BASE=https://<your-school>.instructure.com
//
// Usage:
//   node canvas.mjs courses
//   node canvas.mjs modules <courseId>
//   node canvas.mjs pages <courseId>
//   node canvas.mjs page <courseId> <pageUrl>
//   node canvas.mjs frontpage <courseId>
//   node canvas.mjs assignments <courseId>
//   node canvas.mjs files <courseId>
//   node canvas.mjs download <courseId> <fileId> [outfile]
//   node canvas.mjs whoami

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const dir = path.dirname(fileURLToPath(import.meta.url));
const envPath = path.join(dir, ".env");

function loadEnv() {
  if (!fs.existsSync(envPath)) return;
  for (const line of fs.readFileSync(envPath, "utf8").split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$/);
    if (!m) continue;
    if (process.env[m[1]] === undefined) {
      process.env[m[1]] = m[2].replace(/^["']|["']$/g, "").trim();
    }
  }
}

loadEnv();

const token = (process.env.CANVAS_API_TOKEN || "").trim();
const cookie = (process.env.CANVAS_COOKIE || "")
  .trim()
  .replace(/^cookie\s*:\s*/i, "")
  .replace(/^["']|["']$/g, "")
  .trim();
const base = (process.env.CANVAS_API_BASE || "").replace(/\/+$/, "");

if (!base) {
  console.error(`Missing CANVAS_API_BASE. Fill in ${envPath}:
  CANVAS_API_BASE=https://<your-school>.instructure.com`);
  process.exit(2);
}

if (!token && !cookie) {
  console.error(`Missing credentials. Fill in ${envPath} with either a session cookie (preferred when tokens are disabled):
  CANVAS_COOKIE=<Cookie header value copied from your browser>
or, if you have an access token:
  CANVAS_API_TOKEN=<your access token>`);
  process.exit(2);
}

function firstNonAscii(s) {
  for (let i = 0; i < s.length; i++) if (s.charCodeAt(i) > 255) return i;
  return -1;
}

const badIndex = firstNonAscii(cookie);
if (badIndex !== -1) {
  const code = cookie.charCodeAt(badIndex).toString(16).toUpperCase().padStart(4, "0");
  console.error(`CANVAS_COOKIE contains a non-ASCII character (U+${code}) at index ${badIndex}.
That is usually a "..." (ellipsis) that DevTools inserts when it truncates a long header value.
Recopy the FULL cookie:
  Network tab -> right-click a request to your Canvas domain -> Copy -> Copy as cURL
  then extract everything after "cookie:" from the pasted text (its value is long and untruncated).`);
  process.exit(2);
}


function authHeaders() {
  if (cookie) return { Cookie: cookie, Accept: "application/json" };
  return { Authorization: `Bearer ${token}`, Accept: "application/json" };
}

const URL_BASE = base + "/api/v1";

function htmlToText(html) {
  return String(html || "")
    .replace(/<script[\s\S]*?<\/script>/gi, " ")
    .replace(/<style[\s\S]*?<\/style>/gi, " ")
    .replace(/<(br\s*\/?|hr\s*\/?|p\s*\/?|\/p|\/div|\/li|\/ul|\/ol|\/h[1-6]|tr|td)/gi, "\n")
    .replace(/<(li|h[1-6])\b[^>]*>/gi, "\n$&")
    .replace(/<[^>]+>/g, "")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;/g, "'")
    .replace(/[ \t]{2,}/g, " ")
    .replace(/\n[ \t]+/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

function truncate(str, max) {
  if (str.length <= max) return str;
  return str.slice(0, max) + "\n...[truncated]";
}

async function getRaw(pathWithQuery) {
  const headers = authHeaders();
  let url = URL_BASE + pathWithQuery;
  url += (url.includes("?") ? "&" : "?") + "per_page=100";
  const items = [];
  while (url) {
    const res = await fetch(url, { headers, redirect: "follow" });
    if (!res.ok) {
      const body = await res.text().catch(() => "");
      console.error(`HTTP ${res.status} for ${url}`);
      if (body) console.error(truncate(body, 800));
      if (res.status === 401 || res.status === 403)
        console.error(cookie
          ? "Session cookie rejected or expired — log into Canvas and copy a fresh Cookie header into .env."
          : "Access token rejected — check CANVAS_API_TOKEN.");
      process.exit(1);
    }
    const ct = res.headers.get("content-type") || "";
    if (!ct.includes("json")) {
      const body = await res.text().catch(() => "");
      console.error(`Canvas returned ${ct || "non-JSON"} instead of JSON — you were probably redirected to a login page.`);
      if (cookie) console.error("Your session cookie is likely expired; copy a fresh one into .env.");
      if (body) console.error(truncate(htmlToText(body), 400));
      process.exit(1);
    }
    const data = await res.json();
    if (Array.isArray(data)) items.push(...data);
    else return data;
    const link = res.headers.get("link") || "";
    const next = link.split(",").find((s) => s.includes('rel="next"'));
    url = next ? (next.match(/<([^>]+)>/) || [])[1] || null : null;
  }
  return items;
}

async function streamToFile(url) {
  const res = await fetch(url, { headers: authHeaders(), redirect: "follow" });
  if (!res.ok) {
    console.error(`HTTP ${res.status} while downloading`);
    process.exit(1);
  }
  return Buffer.from(await res.arrayBuffer());
}

const [cmd, a, b, c] = process.argv.slice(2);

async function main() {
  switch (cmd) {
    case "courses": {
      const courses = await getRaw("/courses?enrollment_state=active");
      for (const co of courses)
        console.log(`${co.id}\t${co.course_code || ""}\t${co.name || ""}`);
      break;
    }
    case "modules": {
      const mods = await getRaw(`/courses/${a}/modules`);
      for (const m of mods) console.log(`Module ${m.position ?? ""}: ${m.name}`);
      break;
    }
    case "pages": {
      const pages = await getRaw(`/courses/${a}/pages`);
      for (const p of pages) console.log(`${p.url}\t${p.title}`);
      break;
    }
    case "page": {
      if (!b) return fail("page <courseId> <pageUrl>");
      const p = await getRaw(`/courses/${a}/pages/${encodeURIComponent(b)}`);
      console.log(`# ${p.title}\n`);
      console.log(truncate(htmlToText(p.body), 30000));
      break;
    }
    case "frontpage": {
      const p = await getRaw(`/courses/${a}/pages/front_page`);
      console.log(`# ${p.title}\n`);
      console.log(truncate(htmlToText(p.body), 30000));
      break;
    }
    case "assignments": {
      const list = await getRaw(`/courses/${a}/assignments?include[]=submission`);
      for (const x of list) {
        console.log(`Assignment ${x.id}: ${x.name} (${x.points_possible ?? 0} pts) due ${x.due_at || "no due date"}${x.submission && !x.submission.workflow_state ? "" : ""}`);
        if (x.description) console.log(truncate(htmlToText(x.description), 1500));
        console.log("---");
      }
      break;
    }
    case "files": {
      const files = await getRaw(`/courses/${a}/files`);
      for (const f of files) console.log(`${f.id}\t${f.folder_id ?? ""}\t${f.display_name}\t${Math.round((f.size || 0) / 1024)} KB`);
      break;
    }
    case "download": {
      if (!b) return fail("download <courseId> <fileId> [outfile]");
      const f = await getRaw(`/files/${b}?include[]=verifiers`);
      const out = c || f.display_name || path.basename(f.url || "file");
      const buf = await streamToFile(f.url);
      fs.writeFileSync(out, buf);
      console.log(`Saved ${buf.length} bytes to ${out}`);
      break;
    }
    case "whoami": {
      const me = await getRaw("/users/self");
      console.log(`Authenticated as ${me.name} (${me.id})`);
      break;
    }
    default:
      console.log(`Unknown command: ${cmd || "(none)"}

Canvas helper commands:
  courses                                    list your active courses (id, code, name)
  modules <courseId>                         list a course's modules
  pages <courseId>                           list a course's wiki pages
  page <courseId> <pageUrl>                  show a wiki page as readable text
  frontpage <courseId>                       show a course's home/front page
  assignments <courseId>                     list assignments + due dates
  files <courseId>                           list course files
  download <courseId> <fileId> [outfile]     download a course file
  whoami                                     verify the token works`);
      process.exit(cmd ? 1 : 0);
  }
}

function fail(msg) {
  console.error(`Usage: node canvas.mjs ${msg}`);
  process.exit(1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});