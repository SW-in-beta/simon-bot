/* ============================================================
   Report Viewer — report.js
   TOC generation, markdown rendering, custom blocks,
   comment system, theme toggle
   ============================================================ */

(function () {
  'use strict';

  // --- State ---
  const state = {
    comments: { report: '', comments: [] },
    selectedIntent: 'fix',
    selectedText: '',
    selectedSectionId: '',
    selectedSectionTitle: '',
    activeTocId: '',
    editMode: false,
  };

  let vditorInstance = null;

  // --- Refs ---
  const $ = (sel) => document.querySelector(sel);
  const $$ = (sel) => [...document.querySelectorAll(sel)];

  // --- Init ---
  document.addEventListener('DOMContentLoaded', init);

  function init() {
    initTheme();
    renderMarkdown();
    processCustomBlocks();
    buildTOC();
    initComments();
    initToolbar();
    initEditMode();
    initScrollSpy();
    setReportDate();
  }

  // ============================================================
  // Theme
  // ============================================================
  function initTheme() {
    const saved = localStorage.getItem('rv-theme') || 'auto';
    document.documentElement.setAttribute('data-theme', saved);
    updateHljsTheme(saved);

    const btn = $('#themeToggle');
    if (!btn) return;

    btn.addEventListener('click', () => {
      const current = document.documentElement.getAttribute('data-theme');
      const next = current === 'dark' ? 'light' : current === 'light' ? 'auto' : 'dark';
      document.documentElement.setAttribute('data-theme', next);
      localStorage.setItem('rv-theme', next);
      updateHljsTheme(next);
      reRenderMermaid();
    });
  }

  function updateHljsTheme(theme) {
    const light = $('#hljs-light');
    const dark = $('#hljs-dark');
    if (!light || !dark) return;

    if (theme === 'dark') {
      light.media = 'not all';
      dark.media = 'all';
    } else if (theme === 'light') {
      light.media = 'all';
      dark.media = 'not all';
    } else {
      light.media = '(prefers-color-scheme: light)';
      dark.media = '(prefers-color-scheme: dark)';
    }
  }

  // ============================================================
  // Markdown Rendering
  // ============================================================
  function renderMarkdown() {
    const article = $('#article');
    if (!article || !REPORT_CONFIG.markdownContent) return;

    // Configure marked
    if (typeof marked !== 'undefined') {
      marked.setOptions({
        gfm: true,
        breaks: false,
        highlight: function (code, lang) {
          if (typeof hljs !== 'undefined' && lang && hljs.getLanguage(lang)) {
            try {
              return hljs.highlight(code, { language: lang }).value;
            } catch (_) {}
          }
          return code;
        },
      });

      const renderer = new marked.Renderer();

      // Add language label to code blocks
      renderer.code = function ({ text, lang }) {
        const langClass = lang ? ` class="language-${lang}"` : '';
        const langLabel = lang ? `<span class="rv-code-lang">${lang}</span>` : '';
        let highlighted = text;
        if (typeof hljs !== 'undefined' && lang && hljs.getLanguage(lang)) {
          try {
            highlighted = hljs.highlight(text, { language: lang }).value;
          } catch (_) {}
        }
        return `<pre>${langLabel}<code${langClass}>${highlighted}</code></pre>`;
      };

      // Wrap h2/h3 sections for comment targeting
      marked.use({ renderer });

      // Pre-process: replace ::: directive blocks with placeholders before marked.parse()
      const { processed, directives } = preprocessDirectives(REPORT_CONFIG.markdownContent);

      let html = marked.parse(processed);

      // Post-process: replace placeholder divs with rendered directive HTML
      html = postprocessDirectives(html, directives);

      // Wrap each h2 section with a commentable div
      html = wrapSections(html);

      article.innerHTML = html;
    }
  }

  function wrapSections(html) {
    const wrapper = document.createElement('div');
    wrapper.innerHTML = html;

    const children = [...wrapper.children];
    const result = document.createDocumentFragment();
    let currentSection = null;

    for (const el of children) {
      const tag = el.tagName;

      if (tag === 'H2' || tag === 'H1') {
        if (currentSection) {
          result.appendChild(currentSection);
        }
        currentSection = document.createElement('div');
        currentSection.className = 'rv-section';
        const id = slugify(el.textContent);
        el.id = id;
        currentSection.setAttribute('data-section-id', id);
        currentSection.setAttribute('data-section-title', el.textContent);
        currentSection.appendChild(el);
      } else if (tag === 'H3') {
        const id = slugify(el.textContent);
        el.id = id;
        if (currentSection) {
          currentSection.appendChild(el);
        } else {
          result.appendChild(el);
        }
      } else {
        if (currentSection) {
          currentSection.appendChild(el);
        } else {
          result.appendChild(el);
        }
      }
    }

    if (currentSection) {
      result.appendChild(currentSection);
    }

    const tmp = document.createElement('div');
    tmp.appendChild(result);
    return tmp.innerHTML;
  }

  function slugify(text) {
    return text
      .trim()
      .toLowerCase()
      .replace(/[^\w\s가-힣-]/g, '')
      .replace(/[\s]+/g, '-')
      .replace(/-+/g, '-');
  }

  // ============================================================
  // Custom Blocks
  // ============================================================

  function preprocessDirectives(md) {
    const directives = [];
    const blockRegex = /^:::(\w+)(?:\[([^\]]*)\])?\s*\n([\s\S]*?)^:::\s*$/gm;

    const processed = md.replace(blockRegex, (fullMatch, type, param, content) => {
      const index = directives.length;
      directives.push({ type, param: param || '', content: content.trim() });
      return `<div data-rv-directive="${index}"></div>`;
    });

    return { processed, directives };
  }

  function postprocessDirectives(html, directives) {
    for (let i = 0; i < directives.length; i++) {
      const { type, param, content } = directives[i];
      const rendered = renderDirective(type, param, content);
      if (rendered) {
        html = html.replace(`<div data-rv-directive="${i}"></div>`, rendered);
      }
    }
    return html;
  }

  function processCustomBlocks() {
    const article = $('#article');
    if (!article) return;

    // Process mermaid blocks
    article.querySelectorAll('pre code.language-mermaid').forEach((block) => {
      const pre = block.parentElement;
      const container = document.createElement('div');
      container.className = 'rv-mermaid';
      container.textContent = block.textContent;
      pre.replaceWith(container);
    });

    // Process math blocks
    article.querySelectorAll('pre code.language-math').forEach((block) => {
      const pre = block.parentElement;
      const container = document.createElement('div');
      container.className = 'rv-math';
      if (typeof katex !== 'undefined') {
        katex.render(block.textContent, container, { displayMode: true, throwOnError: false });
      } else {
        container.textContent = block.textContent;
      }
      pre.replaceWith(container);
    });

    // Init mermaid
    initMermaid();
  }

  function renderDirective(type, param, content) {
    switch (type) {
      case 'callout':
        return renderCallout(param || 'info', content);
      case 'comparison':
        return renderComparison(content);
      case 'timeline':
        return renderTimeline(content);
      case 'steps':
        return renderSteps(content);
      case 'metric':
        return renderMetric(param, content);
      case 'tabs':
        return renderTabs(content);
      case 'collapse':
        return renderCollapse(param || '', content);
      case 'quote':
        return renderQuote(param, content);
      default:
        return null;
    }
  }

  function renderCallout(type, content) {
    const labels = { info: 'INFO', warning: 'WARNING', error: 'ERROR', success: 'SUCCESS' };
    const html = typeof marked !== 'undefined' ? marked.parse(content) : content;
    return `<div class="rv-callout rv-callout--${type}">
      <div class="rv-callout__title">${labels[type] || type.toUpperCase()}</div>
      ${html}
    </div>`;
  }

  function renderComparison(content) {
    const cards = content.split(/^---$/m).map((c) => c.trim());
    let html = '<div class="rv-comparison">';
    for (const card of cards) {
      const lines = card.split('\n');
      const titleLine = lines[0] || '';
      const isRec = titleLine.includes('*');
      const title = titleLine.replace(/\*/g, '').trim();
      const body = lines.slice(1).join('\n');
      const bodyHtml = typeof marked !== 'undefined' ? marked.parse(body) : body;
      html += `<div class="rv-comparison__card${isRec ? ' rv-comparison__card--recommended' : ''}">
        <div class="rv-comparison__card-title">${title}</div>
        ${bodyHtml}
      </div>`;
    }
    html += '</div>';
    return html;
  }

  function renderTimeline(content) {
    const items = content.split(/^---$/m).map((c) => c.trim());
    let html = '<div class="rv-timeline">';
    for (const item of items) {
      const lines = item.split('\n');
      const title = lines[0] || '';
      const body = lines.slice(1).join('\n');
      const bodyHtml = typeof marked !== 'undefined' ? marked.parse(body) : body;
      html += `<div class="rv-timeline__item">
        <div class="rv-timeline__marker"></div>
        <div class="rv-timeline__title">${title}</div>
        <div class="rv-timeline__content">${bodyHtml}</div>
      </div>`;
    }
    html += '</div>';
    return html;
  }

  function renderSteps(content) {
    const items = content.split(/^---$/m).map((c) => c.trim());
    let html = '<div class="rv-steps">';
    for (const item of items) {
      const itemHtml = typeof marked !== 'undefined' ? marked.parse(item) : item;
      html += `<div class="rv-steps__item">
        <div class="rv-steps__number"></div>
        <div class="rv-steps__content">${itemHtml}</div>
      </div>`;
    }
    html += '</div>';
    return html;
  }

  function renderMetric(label, content) {
    const value = content.trim();
    return `<div class="rv-metric">
      <div class="rv-metric__value">${value}</div>
      <div class="rv-metric__label">${label || ''}</div>
    </div>`;
  }

  function renderTabs(content) {
    const tabs = content.split(/^---$/m).map((c) => c.trim());
    const id = 'tabs-' + Math.random().toString(36).slice(2, 8);
    let headerHtml = '<div class="rv-tabs__header">';
    let panelsHtml = '';

    tabs.forEach((tab, i) => {
      const lines = tab.split('\n');
      const title = lines[0] || `Tab ${i + 1}`;
      const body = lines.slice(1).join('\n');
      const bodyHtml = typeof marked !== 'undefined' ? marked.parse(body) : body;
      const active = i === 0;

      headerHtml += `<button class="rv-tabs__btn${active ? ' rv-tabs__btn--active' : ''}"
        data-tabs-id="${id}" data-tab-index="${i}"
        onclick="window.__rvSwitchTab('${id}', ${i})">${title}</button>`;

      panelsHtml += `<div class="rv-tabs__panel${active ? ' rv-tabs__panel--active' : ''}"
        data-tabs-id="${id}" data-tab-index="${i}">${bodyHtml}</div>`;
    });

    headerHtml += '</div>';
    return `<div class="rv-tabs">${headerHtml}${panelsHtml}</div>`;
  }

  // Global tab switcher
  window.__rvSwitchTab = function (tabsId, index) {
    document.querySelectorAll(`.rv-tabs__btn[data-tabs-id="${tabsId}"]`).forEach((btn, i) => {
      btn.classList.toggle('rv-tabs__btn--active', i === index);
    });
    document.querySelectorAll(`.rv-tabs__panel[data-tabs-id="${tabsId}"]`).forEach((panel, i) => {
      panel.classList.toggle('rv-tabs__panel--active', i === index);
    });
  };

  function renderCollapse(title, content) {
    const bodyHtml = typeof marked !== 'undefined' ? marked.parse(content) : content;
    const id = 'collapse-' + Math.random().toString(36).slice(2, 8);
    return `<div class="rv-collapse" id="${id}">
      <button class="rv-collapse__header" onclick="document.getElementById('${id}').classList.toggle('rv-collapse--open')">
        <svg class="rv-collapse__arrow" viewBox="0 0 20 20" fill="currentColor" width="14" height="14">
          <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd"/>
        </svg>
        ${title}
      </button>
      <div class="rv-collapse__body">${bodyHtml}</div>
    </div>`;
  }

  function renderQuote(source, content) {
    const bodyHtml = typeof marked !== 'undefined' ? marked.parse(content) : content;
    return `<div class="rv-quote">
      <div class="rv-quote__text">${bodyHtml}</div>
      ${source ? `<div class="rv-quote__source">— ${source}</div>` : ''}
    </div>`;
  }

  // ============================================================
  // Mermaid
  // ============================================================
  function initMermaid() {
    if (typeof mermaid === 'undefined') return;

    const isDark = isDarkMode();
    mermaid.initialize({
      startOnLoad: false,
      theme: isDark ? 'dark' : 'default',
      securityLevel: 'loose',
    });

    renderAllMermaid();
  }

  async function renderAllMermaid() {
    const blocks = $$('.rv-mermaid');
    for (let i = 0; i < blocks.length; i++) {
      const block = blocks[i];
      const code = block.textContent;
      try {
        const { svg } = await mermaid.render(`mermaid-${i}`, code);
        block.innerHTML = svg;
      } catch (e) {
        block.innerHTML = `<pre style="color:var(--rv-error);font-size:12px">${e.message}</pre>`;
      }
    }
  }

  function reRenderMermaid() {
    if (typeof mermaid === 'undefined') return;
    const isDark = isDarkMode();
    mermaid.initialize({
      startOnLoad: false,
      theme: isDark ? 'dark' : 'default',
      securityLevel: 'loose',
    });
    // Re-render would require original source — skip for now
  }

  function isDarkMode() {
    const theme = document.documentElement.getAttribute('data-theme');
    if (theme === 'dark') return true;
    if (theme === 'light') return false;
    return window.matchMedia('(prefers-color-scheme: dark)').matches;
  }

  // ============================================================
  // TOC
  // ============================================================
  function buildTOC() {
    const tocList = $('#tocList');
    const article = $('#article');
    if (!tocList || !article) return;

    const headings = article.querySelectorAll('h2, h3');
    const fragment = document.createDocumentFragment();

    headings.forEach((h) => {
      const id = h.id || slugify(h.textContent);
      if (!h.id) h.id = id;

      const li = document.createElement('li');
      li.className = 'rv-toc__item';

      const a = document.createElement('a');
      a.className = 'rv-toc__link' + (h.tagName === 'H3' ? ' rv-toc__link--h3' : '');
      a.href = '#' + id;
      a.textContent = h.textContent;
      a.setAttribute('data-toc-id', id);

      a.addEventListener('click', (e) => {
        e.preventDefault();
        const target = document.getElementById(id);
        if (target) {
          target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
      });

      li.appendChild(a);
      fragment.appendChild(li);
    });

    tocList.appendChild(fragment);
  }

  // ============================================================
  // Scroll Spy
  // ============================================================
  function initScrollSpy() {
    const headings = $$('#article h2, #article h3');
    if (headings.length === 0) return;

    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            setActiveToc(entry.target.id);
            break;
          }
        }
      },
      {
        rootMargin: `-${parseInt(getComputedStyle(document.documentElement).getPropertyValue('--rv-header-h')) || 56}px 0px -70% 0px`,
      }
    );

    headings.forEach((h) => observer.observe(h));
  }

  function setActiveToc(id) {
    if (state.activeTocId === id) return;
    state.activeTocId = id;

    $$('.rv-toc__link').forEach((link) => {
      link.classList.toggle('rv-toc__link--active', link.getAttribute('data-toc-id') === id);
    });
  }

  // ============================================================
  // Comment System
  // ============================================================
  function initComments() {
    if (REPORT_CONFIG.serverMode) {
      loadComments();
    }

    initCommentTrigger();
    initCommentPanel();
    initSectionHover();
  }

  async function loadComments() {
    try {
      const res = await fetch('/comments');
      if (res.ok) {
        state.comments = await res.json();
        renderComments();
        updateCommentBadge();
        updateReviewStats();
      }
    } catch (_) {}
  }

  async function saveComments() {
    if (!REPORT_CONFIG.serverMode) {
      // Fallback: store in memory only
      renderComments();
      updateCommentBadge();
      updateReviewStats();
      return;
    }

    try {
      await fetch('/comments', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(state.comments),
      });
      renderComments();
      updateCommentBadge();
      updateReviewStats();
    } catch (e) {
      showToast('코멘트 저장 실패', 'error');
    }
  }

  function renderComments() {
    const margin = $('#commentsMargin');
    if (!margin) return;

    margin.innerHTML = '';

    // Clear section highlights
    $$('.rv-section').forEach((sec) => sec.classList.remove('rv-section--has-comment'));

    const activeComments = state.comments.comments.filter((c) => c.status !== 'resolved');

    if (activeComments.length === 0) {
      margin.innerHTML = `<div class="rv-margin-empty">
        <svg viewBox="0 0 20 20" fill="currentColor" width="24" height="24">
          <path fill-rule="evenodd" d="M18 13V5a2 2 0 00-2-2H4a2 2 0 00-2 2v8a2 2 0 002 2h3l3 3 3-3h3a2 2 0 002-2zM5 7a1 1 0 011-1h8a1 1 0 110 2H6a1 1 0 01-1-1zm1 3a1 1 0 100 2h3a1 1 0 100-2H6z" clip-rule="evenodd"/>
        </svg>
        <p class="rv-margin-empty__text">코멘트 없음</p>
        <p class="rv-margin-empty__hint">섹션 호버 또는 텍스트 선택 후<br>말풍선 아이콘을 클릭하세요</p>
      </div>`;
      return;
    }

    for (const comment of activeComments) {
      // Mark section
      const section = $(`[data-section-id="${comment.section_id}"]`);
      if (section) {
        section.classList.add('rv-section--has-comment');
      }

      const el = document.createElement('div');
      el.className = 'rv-margin-comment';
      el.setAttribute('data-comment-id', comment.id);
      el.setAttribute('data-comment-section', comment.section_id);
      el.innerHTML = `
        <div class="rv-margin-comment__header">
          <span class="rv-margin-comment__intent rv-margin-comment__intent--${comment.intent}">
            ${intentLabel(comment.intent)}
          </span>
          <button class="rv-margin-comment__delete" title="삭제" aria-label="코멘트 삭제">
            <svg viewBox="0 0 20 20" fill="currentColor" width="12" height="12">
              <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
            </svg>
          </button>
        </div>
        ${comment.selected_text ? `<div class="rv-margin-comment__quote">${escapeHtml(comment.selected_text)}</div>` : ''}
        <div class="rv-margin-comment__text">${escapeHtml(comment.comment)}</div>
        <div class="rv-margin-comment__meta">${comment.section_title || ''} · ${formatTime(comment.timestamp)}</div>
      `;

      // Click comment card → scroll to section
      el.addEventListener('click', (e) => {
        if (e.target.closest('.rv-margin-comment__delete')) return;
        scrollToSection(comment.section_id);
      });

      // Delete button
      el.querySelector('.rv-margin-comment__delete').addEventListener('click', (e) => {
        e.stopPropagation();
        deleteComment(comment.id);
      });

      margin.appendChild(el);
    }
  }

  function deleteComment(commentId) {
    if (!confirm('이 코멘트를 삭제하시겠습니까?')) return;
    const idx = state.comments.comments.findIndex((c) => c.id === commentId);
    if (idx === -1) return;
    state.comments.comments.splice(idx, 1);
    saveComments();
    showToast('코멘트 삭제됨');
  }

  function updateCommentBadge() {
    const badge = $('#commentCountBadge');
    if (!badge) return;

    const count = state.comments.comments.filter((c) => c.status !== 'resolved').length;
    badge.textContent = count;
    badge.hidden = count === 0;

    // Update per-section counts in TOC
    const sectionCounts = {};
    for (const c of state.comments.comments) {
      if (c.status === 'resolved') continue;
      sectionCounts[c.section_id] = (sectionCounts[c.section_id] || 0) + 1;
    }

    $$('.rv-toc__link').forEach((link) => {
      const id = link.getAttribute('data-toc-id');
      let countEl = link.querySelector('.rv-toc__comment-count');
      if (sectionCounts[id]) {
        if (!countEl) {
          countEl = document.createElement('span');
          countEl.className = 'rv-toc__comment-count';
          link.appendChild(countEl);
        }
        countEl.textContent = sectionCounts[id];
      } else if (countEl) {
        countEl.remove();
      }
    });
  }

  function updateReviewStats() {
    const statsEl = $('#reviewStats');
    if (!statsEl) return;

    const counts = { fix: 0, question: 0, expand: 0, approve: 0 };
    for (const c of state.comments.comments) {
      if (c.status === 'resolved') continue;
      if (counts.hasOwnProperty(c.intent)) counts[c.intent]++;
    }

    const labels = { fix: '수정 요청', question: '질문', expand: '확장 요청', approve: '승인' };
    statsEl.innerHTML = Object.entries(counts)
      .filter(([, v]) => v > 0)
      .map(
        ([k, v]) => `<div class="rv-review-stat">
        <span class="rv-review-stat__dot rv-review-stat__dot--${k}"></span>
        <span>${labels[k]}</span>
        <span class="rv-review-stat__count">${v}</span>
      </div>`
      )
      .join('');
  }

  // --- Comment Trigger (text selection) ---
  function initCommentTrigger() {
    const trigger = $('#commentTrigger');
    if (!trigger) return;

    document.addEventListener('mouseup', (e) => {
      if (e.target.closest('.rv-comment-panel') || e.target.closest('.rv-comment-trigger')) return;

      const selection = window.getSelection();
      const text = selection.toString().trim();

      if (text.length > 0 && e.target.closest('#article')) {
        const range = selection.getRangeAt(0);
        const rect = range.getBoundingClientRect();

        // Find parent section
        const section = e.target.closest('.rv-section');
        state.selectedSectionId = section?.getAttribute('data-section-id') || '';
        state.selectedSectionTitle = section?.getAttribute('data-section-title') || '';
        state.selectedText = text.slice(0, 200);

        trigger.style.top = `${rect.top + window.scrollY - 40}px`;
        trigger.style.left = `${rect.left + rect.width / 2 - 16}px`;
        trigger.hidden = false;
      } else {
        setTimeout(() => {
          if (!document.querySelector('.rv-comment-panel--open')) {
            trigger.hidden = true;
          }
        }, 200);
      }
    });

    trigger.addEventListener('click', () => {
      trigger.hidden = true;
      openCommentPanel();
    });
  }

  // --- Section hover comment icons ---
  function initSectionHover() {
    $$('.rv-section').forEach((section) => {
      const heading = section.querySelector('h1, h2');
      if (!heading) return;

      const icon = document.createElement('button');
      icon.className = 'rv-section__comment-icon';
      icon.title = '코멘트 추가';
      icon.setAttribute('aria-label', '코멘트 추가');
      icon.innerHTML = `<svg viewBox="0 0 20 20" fill="currentColor" width="14" height="14">
        <path fill-rule="evenodd" d="M18 13V5a2 2 0 00-2-2H4a2 2 0 00-2 2v8a2 2 0 002 2h3l3 3 3-3h3a2 2 0 002-2zM5 7a1 1 0 011-1h8a1 1 0 110 2H6a1 1 0 01-1-1zm1 3a1 1 0 100 2h3a1 1 0 100-2H6z" clip-rule="evenodd"/>
      </svg>`;
      icon.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();
        state.selectedSectionId = section.getAttribute('data-section-id') || '';
        state.selectedSectionTitle = section.getAttribute('data-section-title') || '';
        state.selectedText = '';
        openCommentPanel();
      });

      heading.style.display = 'inline-flex';
      heading.style.alignItems = 'center';
      heading.style.gap = '8px';
      heading.style.width = '100%';
      heading.appendChild(icon);
    });
  }

  // --- Comment Panel ---
  function initCommentPanel() {
    const panel = $('#commentPanel');
    if (!panel) return;

    // Intent buttons
    $$('.rv-intent-btn').forEach((btn) => {
      btn.addEventListener('click', () => {
        $$('.rv-intent-btn').forEach((b) => b.classList.remove('rv-intent-btn--active'));
        btn.classList.add('rv-intent-btn--active');
        state.selectedIntent = btn.getAttribute('data-intent');
      });
    });

    // Close buttons
    $('#commentCancelBtn')?.addEventListener('click', closeCommentPanel);
    $('#commentPanelClose')?.addEventListener('click', closeCommentPanel);

    // Save
    $('#commentSaveBtn')?.addEventListener('click', () => {
      const input = $('#commentInput');
      const text = input?.value.trim();
      if (!text) {
        showToast('코멘트를 입력하세요', 'error');
        return;
      }

      const comment = {
        id: 'c-' + Date.now().toString(36),
        section_id: state.selectedSectionId,
        section_title: state.selectedSectionTitle,
        selected_text: state.selectedText,
        comment: text,
        intent: state.selectedIntent,
        timestamp: new Date().toISOString(),
        status: 'pending',
      };

      state.comments.report = REPORT_CONFIG.markdownPath;
      state.comments.comments.push(comment);
      saveComments();
      closeCommentPanel();
      showToast('코멘트 저장 완료');
    });

    // Escape to close
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && panel.classList.contains('rv-comment-panel--open')) {
        closeCommentPanel();
      }
    });

    // Click outside to close
    document.addEventListener('mousedown', (e) => {
      if (
        panel.classList.contains('rv-comment-panel--open') &&
        !e.target.closest('.rv-comment-panel') &&
        !e.target.closest('.rv-comment-trigger') &&
        !e.target.closest('.rv-section__comment-icon')
      ) {
        closeCommentPanel();
      }
    });
  }

  function openCommentPanel() {
    const panel = $('#commentPanel');
    if (!panel) return;

    panel.removeAttribute('hidden');
    panel.classList.add('rv-comment-panel--open');
    $('#commentSelectedText').textContent = state.selectedText || '(섹션 전체)';
    $('#commentInput').value = '';

    // Reset intent
    $$('.rv-intent-btn').forEach((b) => b.classList.remove('rv-intent-btn--active'));
    const targetBtn =
      $(`.rv-intent-btn[data-intent="${state.selectedIntent}"]`) || $('.rv-intent-btn');
    targetBtn?.classList.add('rv-intent-btn--active');

    renderPanelExistingComments();
    setTimeout(() => $('#commentInput')?.focus(), 50);
  }

  function renderPanelExistingComments() {
    const container = $('#commentExisting');
    if (!container) return;

    const sectionComments = state.comments.comments.filter(
      (c) => c.section_id === state.selectedSectionId && c.status !== 'resolved'
    );

    if (sectionComments.length === 0) {
      container.innerHTML = '';
      container.style.display = 'none';
      return;
    }

    container.style.display = 'block';
    container.innerHTML =
      `<div class="rv-comment-panel__existing-label">이 섹션의 코멘트 (${sectionComments.length})</div>` +
      sectionComments
        .map(
          (c) => `<div class="rv-panel-comment">
          <div class="rv-panel-comment__header">
            <span class="rv-margin-comment__intent rv-margin-comment__intent--${c.intent}">${intentLabel(c.intent)}</span>
            <span class="rv-panel-comment__time">${formatTime(c.timestamp)}</span>
          </div>
          ${c.selected_text ? `<div class="rv-panel-comment__quote">${escapeHtml(c.selected_text)}</div>` : ''}
          <div class="rv-panel-comment__text">${escapeHtml(c.comment)}</div>
        </div>`
        )
        .join('');
  }

  function closeCommentPanel() {
    const panel = $('#commentPanel');
    if (!panel) return;
    panel.classList.remove('rv-comment-panel--open');
    state.selectedText = '';
  }

  // ============================================================
  // Toolbar
  // ============================================================
  function initToolbar() {
    // Copy path
    $('#copyPathBtn')?.addEventListener('click', async () => {
      try {
        await navigator.clipboard.writeText(REPORT_CONFIG.markdownPath);
        showToast('경로 복사 완료!', 'success');
      } catch (_) {
        // Fallback
        const ta = document.createElement('textarea');
        ta.value = REPORT_CONFIG.markdownPath;
        document.body.appendChild(ta);
        ta.select();
        document.execCommand('copy');
        ta.remove();
        showToast('경로 복사 완료!', 'success');
      }
    });

    // Export comments
    $('#exportCommentsBtn')?.addEventListener('click', () => {
      const json = JSON.stringify(state.comments, null, 2);
      const blob = new Blob([json], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = REPORT_CONFIG.reportTitle + '-comments.json';
      a.click();
      URL.revokeObjectURL(url);
      showToast('코멘트 내보내기 완료');
    });

    // Review done
    $('#reviewDoneBtn')?.addEventListener('click', () => {
      const count = state.comments.comments.filter((c) => c.status !== 'resolved').length;
      if (count === 0) {
        showToast('작성된 코멘트가 없습니다');
        return;
      }
      showToast(`리뷰 완료! ${count}개 코멘트 전달됨`, 'success');
    });
  }

  // ============================================================
  // Toast
  // ============================================================
  function showToast(message, type) {
    const container = $('#toastContainer');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = 'rv-toast' + (type ? ` rv-toast--${type}` : '');
    toast.textContent = message;
    container.appendChild(toast);

    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateY(8px)';
      toast.style.transition = 'all 200ms ease-in';
      setTimeout(() => toast.remove(), 200);
    }, 2500);
  }

  // ============================================================
  // Helpers
  // ============================================================
  function setReportDate() {
    const el = $('#reportDate');
    if (el) {
      el.textContent = new Date().toLocaleDateString('ko-KR', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
      });
    }
  }

  function intentLabel(intent) {
    const labels = { fix: '수정 요청', question: '질문', expand: '확장 요청', approve: '승인' };
    return labels[intent] || intent;
  }

  function formatTime(iso) {
    if (!iso) return '';
    const d = new Date(iso);
    return d.toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit' });
  }

  function scrollToSection(sectionId) {
    const section = $(`[data-section-id="${sectionId}"]`);
    if (!section) return;

    const headerH = parseInt(getComputedStyle(document.documentElement).getPropertyValue('--rv-header-h')) || 56;
    const sectionTop = section.getBoundingClientRect().top + window.scrollY - headerH - 16;
    window.scrollTo({ top: sectionTop, behavior: 'smooth' });

    section.classList.remove('rv-section--highlight-out');
    section.classList.add('rv-section--highlight');
    setTimeout(() => {
      section.classList.add('rv-section--highlight-out');
      section.addEventListener('transitionend', function handler() {
        section.classList.remove('rv-section--highlight', 'rv-section--highlight-out');
        section.removeEventListener('transitionend', handler);
      });
    }, 2000);
  }

  function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }

  // ============================================================
  // Edit Mode (Vditor WYSIWYG)
  // ============================================================
  function initEditMode() {
    if (!REPORT_CONFIG.serverMode || typeof Vditor === 'undefined') {
      const btn = $('#editToggleBtn');
      if (btn) btn.style.display = 'none';
      return;
    }

    $('#editToggleBtn')?.addEventListener('click', enterEditMode);
    $('#editSaveBtn')?.addEventListener('click', saveEdit);
    $('#editCancelBtn')?.addEventListener('click', cancelEdit);
  }

  async function enterEditMode() {
    state.editMode = true;
    document.body.classList.add('rv-edit-mode');

    let markdown = REPORT_CONFIG.markdownContent;
    try {
      const res = await fetch('/markdown-raw');
      if (res.ok) markdown = await res.text();
    } catch (_) {}

    const article = $('#article');
    const container = $('#editorContainer');
    article.style.display = 'none';
    container.removeAttribute('hidden');
    container.style.display = 'block';

    vditorInstance = new Vditor('vditorEditor', {
      value: markdown,
      mode: 'wysiwyg',
      height: 'auto',
      minHeight: 600,
      theme: isDarkMode() ? 'dark' : 'classic',
      toolbar: [
        'headings', 'bold', 'italic', 'strike', '|',
        'list', 'ordered-list', 'check', '|',
        'quote', 'code', 'inline-code', '|',
        'table', 'link', '|',
        'undo', 'redo',
      ],
      cache: { enable: false },
      after: function () {
        vditorInstance.focus();
      },
    });
  }

  async function saveEdit() {
    if (!vditorInstance) return;
    const markdown = vditorInstance.getValue();

    try {
      const res = await fetch('/save-markdown', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ markdown }),
      });
      if (!res.ok) throw new Error('save failed');
    } catch (e) {
      showToast('저장 실패', 'error');
      return;
    }

    REPORT_CONFIG.markdownContent = markdown;
    exitEditMode();
    reRenderContent();
    showToast('저장 완료', 'success');
  }

  function cancelEdit() {
    exitEditMode();
  }

  function exitEditMode() {
    state.editMode = false;
    document.body.classList.remove('rv-edit-mode');

    if (vditorInstance) {
      vditorInstance.destroy();
      vditorInstance = null;
    }

    const article = $('#article');
    const container = $('#editorContainer');
    article.style.display = '';
    container.style.display = 'none';
    container.setAttribute('hidden', '');
  }

  function reRenderContent() {
    const article = $('#article');
    const tocList = $('#tocList');
    if (article) article.innerHTML = '';
    if (tocList) tocList.innerHTML = '';

    renderMarkdown();
    processCustomBlocks();
    buildTOC();
    initSectionHover();
    initScrollSpy();
    renderComments();
    updateCommentBadge();
    updateReviewStats();
  }
})();
