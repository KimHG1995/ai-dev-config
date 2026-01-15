#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const opencodeDir = path.join(repoDir, "opencode");
const compiledDir = path.join(opencodeDir, "compiled");

let jsoncParserPromise;
const loadJsoncParser = async () => {
  if (!jsoncParserPromise) {
    jsoncParserPromise = import("jsonc-parser").catch((err) => {
      console.error("오류: jsonc-parser가 필요합니다. 설치 후 다시 실행하세요.");
      console.error("예: pnpm add -D jsonc-parser");
      throw err;
    });
  }
  return jsoncParserPromise;
};

const readJsonc = async (filePath) => {
  if (!fs.existsSync(filePath)) {
    throw new Error(`필수 파일이 없습니다: ${filePath}`);
  }
  const raw = fs.readFileSync(filePath, "utf8");
  const { parse, printParseErrorCode } = await loadJsoncParser();
  /** @type {import("jsonc-parser").ParseError[]} */
  const errors = [];
  const data = parse(raw, errors, { allowTrailingComma: true });
  if (errors.length > 0) {
    const first = errors[0];
    const message = printParseErrorCode(first.error);
    const location = `offset=${first.offset}, length=${first.length}`;
    throw new Error(`JSONC 파싱 실패: ${filePath} (${message}, ${location})`);
  }
  if (data === null || data === undefined || typeof data !== "object") {
    throw new Error(`JSONC 파싱 결과가 객체가 아닙니다: ${filePath}`);
  }
  return data;
};

const isPlainObject = (value) =>
  value !== null && typeof value === "object" && !Array.isArray(value);

const mergeConfigs = (base, overlay) => {
  if (Array.isArray(base) && Array.isArray(overlay)) {
    return overlay.slice();
  }
  if (isPlainObject(base) && isPlainObject(overlay)) {
    const out = { ...base };
    for (const [key, value] of Object.entries(overlay)) {
      if (key in out) {
        out[key] = mergeConfigs(out[key], value);
      } else {
        out[key] = value;
      }
    }
    return out;
  }
  return overlay !== undefined ? overlay : base;
};

const buildProfile = async (profileName, overlayFile) => {
  const baseFile = path.join(opencodeDir, "base.opencode.jsonc");
  const overlayPath = path.join(opencodeDir, overlayFile);

  const base = await readJsonc(baseFile);
  const overlay = await readJsonc(overlayPath);
  const merged = mergeConfigs(base, overlay);

  const outPath = path.join(compiledDir, `${profileName}.opencode.json`);
  fs.writeFileSync(outPath, JSON.stringify(merged, null, 2) + "\n", "utf8");
  return outPath;
};

const main = async () => {
  fs.mkdirSync(compiledDir, { recursive: true });
  const outputs = [];
  outputs.push(await buildProfile("docker", "mcp.docker.opencode.jsonc"));
  outputs.push(await buildProfile("local", "mcp.local.opencode.jsonc"));

  console.log("Generated:");
  for (const out of outputs) {
    console.log(`- ${path.relative(repoDir, out)}`);
  }
};

try {
  await main();
} catch (err) {
  console.error(String(err instanceof Error ? err.message : err));
  process.exit(1);
}
