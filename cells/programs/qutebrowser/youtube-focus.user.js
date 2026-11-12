// ==UserScript==
// @name         Local YouTube focus mode
// @description  Hide recommendations, comments, Shorts and end-screen suggestions.
// @match        https://www.youtube.com/*
// @grant        none
// ==/UserScript==

// Local CSS only: no remote code, requests, tracking or persistent page storage.
// Toggle the class with qutebrowser's ,f binding. A full reload re-enables it.
(() => {
    const style = document.createElement('style');
    style.textContent = `
        .qute-focus ytd-watch-flexy #secondary,
        .qute-focus ytd-comments,
        .qute-focus ytd-reel-shelf-renderer,
        .qute-focus ytd-rich-section-renderer,
        .qute-focus ytd-browse[page-subtype="home"] #contents,
        .qute-focus .ytp-endscreen-content {
            display: none !important;
        }
    `;
    document.documentElement.appendChild(style);
    document.documentElement.classList.add('qute-focus');
})();
