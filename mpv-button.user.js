// ==UserScript==
// @name         mpv browser button
// @name:ru      Кнопка «mpv» на видео
// @namespace    https://github.com/VasiliskBRO/mpv-browser-button
// @version      1.4
// @description  Button on any video: opens it in mpv from the same moment and pauses it in the browser.
// @description:ru При наведении на видео появляется кнопка: открывает ролик в mpv с того же места, а в браузере ставит на паузу.
// @homepageURL  https://github.com/VasiliskBRO/mpv-browser-button
// @downloadURL  https://raw.githubusercontent.com/VasiliskBRO/mpv-browser-button/master/mpv-button.user.js
// @updateURL    https://raw.githubusercontent.com/VasiliskBRO/mpv-browser-button/master/mpv-button.user.js
// @match        *://*/*
// @grant        GM_getValue
// @grant        GM_setValue
// @grant        GM_registerMenuCommand
// @inject-into  content
// @run-at       document-idle
// ==/UserScript==

(() => {
  "use strict";

  // Ссылки mpvpip:// ловит mpvpip.ps1 (его ставит install.ps1).
  const SCHEME = "mpvpip://play";
  const MIN_W = 200;
  const MIN_H = 110;
  const HIDE_AFTER_MS = 2200;

  // Где стоит кнопка — меняется в меню Violentmonkey и переживает обновления скрипта.
  const POSITIONS = { center: "сверху по центру", right: "сверху справа", left: "сверху слева" };
  let position = GM_getValue("position", "center");
  if (!(position in POSITIONS)) position = "center";
  if (window === top) {
    GM_registerMenuCommand(`Кнопка mpv: ${POSITIONS[position]} (сменить)`, () => {
      const keys = Object.keys(POSITIONS);
      GM_setValue("position", keys[(keys.indexOf(position) + 1) % keys.length]);
      location.reload();
    });
  }

  let target = null;
  let hideTimer = 0;
  let framePending = false;
  let lastX = -1;
  let lastY = -1;

  // Кнопка живёт в shadow DOM, чтобы стили сайта её не ломали.
  const host = document.createElement("div");
  host.style.cssText = "all:initial;position:fixed;top:0;left:0;z-index:2147483647;pointer-events:none;";
  const root = host.attachShadow({ mode: "closed" });

  const style = document.createElement("style");
  style.textContent = `
    button {
      position: fixed;
      display: flex; align-items: center; gap: 6px;
      height: 32px; padding: 0 12px 0 8px;
      border: 1px solid rgba(255,255,255,.18); border-radius: 16px;
      background: rgba(18,18,24,.72);
      backdrop-filter: blur(8px);
      color: #fff; font: 600 13px/1 "Segoe UI", system-ui, sans-serif; letter-spacing: .02em;
      cursor: pointer; pointer-events: auto;
      opacity: 0; transform: translateY(-4px);
      transition: opacity .15s, transform .15s, background .15s;
      box-shadow: 0 2px 10px rgba(0,0,0,.35);
    }
    button.show { opacity: 1; transform: none; }
    button:hover { background: rgba(126,58,180,.92); }
    button:active { transform: scale(.96); }
    svg { width: 18px; height: 18px; flex: none; }
  `;

  const btn = document.createElement("button");
  btn.type = "button";
  btn.title = "Открыть в mpv (с этого места)";
  btn.hidden = true;

  // Значок: кольцо с треугольником «play», как у mpv. Без innerHTML — YouTube его запрещает.
  const NS = "http://www.w3.org/2000/svg";
  const svg = document.createElementNS(NS, "svg");
  svg.setAttribute("viewBox", "0 0 24 24");
  const ring = document.createElementNS(NS, "circle");
  ring.setAttribute("cx", "12");
  ring.setAttribute("cy", "12");
  ring.setAttribute("r", "10");
  ring.setAttribute("fill", "none");
  ring.setAttribute("stroke", "currentColor");
  ring.setAttribute("stroke-width", "2");
  const play = document.createElementNS(NS, "path");
  play.setAttribute("d", "M10 7.5v9l7-4.5z");
  play.setAttribute("fill", "currentColor");
  svg.append(ring, play);
  btn.append(svg, document.createTextNode("mpv"));
  root.append(style, btn);

  function mount() {
    const parent = document.fullscreenElement || document.documentElement;
    if (host.parentNode !== parent) parent.append(host);
  }

  function videoAt(x, y) {
    let best = null;
    let bestArea = 0;
    for (const v of document.querySelectorAll("video")) {
      const r = v.getBoundingClientRect();
      if (r.width < MIN_W || r.height < MIN_H) continue;
      if (x < r.left || x > r.right || y < r.top || y > r.bottom) continue;
      const area = r.width * r.height;
      if (area > bestArea) {
        best = v;
        bestArea = area;
      }
    }
    return best;
  }

  function place() {
    if (!target || !target.isConnected) return hide();
    const r = target.getBoundingClientRect();
    const w = btn.offsetWidth || 74;
    // Считаем от видимой части видео, если страница прокручена.
    const left = Math.max(r.left, 0);
    const right = Math.min(r.right, innerWidth);
    const x = { center: (left + right - w) / 2, right: right - w - 12, left: left + 12 }[position];
    btn.style.top = `${Math.max(r.top, 0) + 12}px`;
    btn.style.left = `${Math.round(x)}px`;
  }

  // Плеер в чужом окошке (Kodik и т.п.) не знает названия серии — спрашиваем у страницы-хозяйки.
  // Строки, а не объекты: так сообщения без проблем проходят между скриптом и страницей.
  let parentTitle = "";
  addEventListener("message", (e) => {
    if (typeof e.data !== "string") return;
    if (e.data === "mpvpip-ask") {
      const isChild = [...Array(frames.length).keys()].some((i) => frames[i] === e.source);
      if (isChild) e.source.postMessage(`mpvpip-title:${document.title}`, "*");
    } else if (e.data.startsWith("mpvpip-title:") && e.source === parent) {
      parentTitle = e.data.slice("mpvpip-title:".length);
    }
  });

  function show(v) {
    if (window !== top && !target) parent.postMessage("mpvpip-ask", "*");
    target = v;
    mount();
    btn.hidden = false;
    place();
    requestAnimationFrame(() => btn.classList.add("show"));
    clearTimeout(hideTimer);
    hideTimer = setTimeout(hide, HIDE_AFTER_MS);
  }

  function hide() {
    clearTimeout(hideTimer);
    btn.classList.remove("show");
    target = null;
    setTimeout(() => {
      if (!target) btn.hidden = true;
    }, 160);
  }

  function onMove(e) {
    lastX = e.clientX;
    lastY = e.clientY;
    if (framePending) return;
    framePending = true;
    requestAnimationFrame(() => {
      framePending = false;
      const v = videoAt(lastX, lastY);
      if (v) show(v);
      else if (target) hide();
    });
  }

  // Сайты, которые yt-dlp понимает по адресу страницы (там выйдет лучше качество).
  const YTDL_HOSTS = /(^|\.)(youtube\.com|youtu\.be|twitch\.tv|kick\.com|vk\.com|vkvideo\.ru|rutube\.ru|vimeo\.com|dailymotion\.com|ok\.ru|bilibili\.com|tiktok\.com|x\.com|twitter\.com|reddit\.com)$/;

  // Прямая ссылка на то, что плеер реально играет: файл или список кусков HLS/DASH.
  function streamUrl(v) {
    const src = v.currentSrc || v.src || "";
    if (/^https?:/.test(src)) return src;
    const manifests = performance
      .getEntriesByType("resource")
      .map((e) => e.name)
      .filter((n) => /\.(m3u8|mpd)(\?|$)|manifest\.m3u8/i.test(n));
    return manifests.length ? manifests[manifests.length - 1] : "";
  }

  function openInMpv() {
    const v = target;
    if (!v) return;
    // У прямых эфиров длина бесконечная — там время не передаём.
    const start = Number.isFinite(v.duration) ? Math.floor(v.currentTime) : 0;
    const stream = YTDL_HOSTS.test(location.hostname) ? "" : streamUrl(v);
    const params = new URLSearchParams({
      url: stream || location.href,
      start: String(start),
      ref: location.href,
      title: parentTitle || document.title || "",
    });
    v.pause();
    const a = document.createElement("a");
    a.href = `${SCHEME}?${params}`;
    a.click();
    hide();
  }

  // Клик не должен доходить до плеера сайта (иначе он сам снимет паузу).
  for (const type of ["pointerdown", "mousedown", "mouseup", "dblclick"]) {
    btn.addEventListener(type, (e) => e.stopPropagation());
  }
  btn.addEventListener("click", (e) => {
    e.preventDefault();
    e.stopPropagation();
    openInMpv();
  });

  document.addEventListener("mousemove", onMove, { passive: true, capture: true });
  addEventListener("scroll", () => target && place(), { passive: true, capture: true });
  addEventListener("resize", () => target && place(), { passive: true });
  document.addEventListener("fullscreenchange", () => {
    mount();
    if (target) place();
  });
})();
