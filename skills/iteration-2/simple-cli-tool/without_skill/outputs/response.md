# Simulated Claude Code Response (Without Skill)

---

**User:** 간단한 CLI 도구 하나 만들어줘. 마크다운 파일을 읽어서 목차를 자동 생성하는 거야. Node.js로.

---

**Claude Code Response:**

마크다운 파일에서 목차를 자동 생성하는 Node.js CLI 도구를 만들겠습니다.

먼저 프로젝트를 초기화하고 필요한 파일들을 생성하겠습니다.

```bash
mkdir -p md-toc && cd md-toc && npm init -y
```

`package.json`을 수정합니다.

```json
{
  "name": "md-toc",
  "version": "1.0.0",
  "description": "Markdown Table of Contents generator",
  "main": "index.js",
  "bin": {
    "md-toc": "./index.js"
  },
  "type": "module",
  "license": "MIT"
}
```

핵심 CLI 파일 `index.js`를 생성합니다.

```js
#!/usr/bin/env node

import { readFileSync, writeFileSync } from "fs";
import { resolve } from "path";

const args = process.argv.slice(2);

if (args.length === 0 || args.includes("--help") || args.includes("-h")) {
  console.log(`
Usage: md-toc <file.md> [options]

Options:
  --max-depth, -d <n>   Maximum heading depth (default: 3)
  --insert, -i          Insert TOC into the file (between <!-- toc --> markers)
  --help, -h            Show this help message
`);
  process.exit(0);
}

const filePath = resolve(args[0]);
let maxDepth = 3;
let insertMode = false;

for (let i = 1; i < args.length; i++) {
  if ((args[i] === "--max-depth" || args[i] === "-d") && args[i + 1]) {
    maxDepth = parseInt(args[i + 1], 10);
    i++;
  }
  if (args[i] === "--insert" || args[i] === "-i") {
    insertMode = true;
  }
}

let content;
try {
  content = readFileSync(filePath, "utf-8");
} catch (err) {
  console.error(`Error: Could not read file "${filePath}"`);
  process.exit(1);
}

function generateSlug(text) {
  return text
    .toLowerCase()
    .replace(/[^\w\s가-힣-]/g, "")
    .replace(/\s+/g, "-")
    .replace(/-+$/, "");
}

function extractHeadings(markdown) {
  const lines = markdown.split("\n");
  const headings = [];
  let inCodeBlock = false;

  for (const line of lines) {
    if (line.trim().startsWith("```")) {
      inCodeBlock = !inCodeBlock;
      continue;
    }
    if (inCodeBlock) continue;

    const match = line.match(/^(#{1,6})\s+(.+)$/);
    if (match) {
      const level = match[1].length;
      if (level <= maxDepth) {
        const text = match[2].trim();
        headings.push({ level, text, slug: generateSlug(text) });
      }
    }
  }

  return headings;
}

function buildToc(headings) {
  if (headings.length === 0) return "No headings found.";

  const minLevel = Math.min(...headings.map((h) => h.level));
  const lines = headings.map((h) => {
    const indent = "  ".repeat(h.level - minLevel);
    return `${indent}- [${h.text}](#${h.slug})`;
  });

  return lines.join("\n");
}

const headings = extractHeadings(content);
const toc = buildToc(headings);

if (insertMode) {
  const tocMarkerRegex = /<!-- toc -->\n[\s\S]*?\n<!-- \/toc -->/;
  const tocBlock = `<!-- toc -->\n${toc}\n<!-- /toc -->`;

  if (tocMarkerRegex.test(content)) {
    const updated = content.replace(tocMarkerRegex, tocBlock);
    writeFileSync(filePath, updated, "utf-8");
    console.log("TOC updated in file.");
  } else {
    const lines = content.split("\n");
    const firstHeadingIdx = lines.findIndex((l) => /^#{1,6}\s+/.test(l));
    const insertIdx = firstHeadingIdx > 0 ? firstHeadingIdx : 0;
    lines.splice(insertIdx, 0, tocBlock, "");
    writeFileSync(filePath, lines.join("\n"), "utf-8");
    console.log("TOC inserted into file.");
  }
} else {
  console.log(toc);
}
```

실행 권한을 부여합니다.

```bash
chmod +x index.js
```

이제 사용할 수 있습니다.

**기본 사용법 (stdout으로 목차 출력):**

```bash
node index.js README.md
```

**최대 깊이 지정:**

```bash
node index.js README.md --max-depth 2
```

**파일에 직접 목차 삽입:**

```bash
node index.js README.md --insert
```

`--insert` 모드는 파일 안에 `<!-- toc -->` ... `<!-- /toc -->` 마커가 있으면 그 사이를 업데이트하고, 없으면 첫 번째 헤딩 위에 삽입합니다.

**글로벌 설치 후 어디서든 사용:**

```bash
npm link
md-toc some-doc.md
```

주요 기능 정리:
- 마크다운 파일의 `#` ~ `######` 헤딩을 파싱하여 목차 생성
- 코드 블록 내부의 `#`은 무시
- 한글 헤딩도 지원하는 slug 생성
- `--max-depth` 옵션으로 목차 깊이 제한
- `--insert` 옵션으로 파일에 직접 목차 삽입/업데이트
- `<!-- toc -->` 마커 기반으로 반복 실행 시 목차 갱신 가능
