/**
 * e_core – diagnosztika NUI: checklist, élő státusz, átlátszó háttér.
 */
(function () {
    const resourceName = GetParentResourceName();
    const overlay = document.getElementById('diag_overlay');
    const modal = document.getElementById('diag_modal');
    const titleEl = document.getElementById('diag_title');
    const subtitleEl = document.getElementById('diag_subtitle');
    const liveStrip = document.getElementById('diag_live_strip');
    const liveText = document.getElementById('diag_live_text');
    const checklistEl = document.getElementById('diag_checklist');
    const serverBody = document.getElementById('diag_server_body');
    const progressBody = document.getElementById('diag_progress_body');
    const progressSection = document.getElementById('diag_section_progress');
    const btnCopy = document.getElementById('diag_btn_copy');
    const btnClose = document.getElementById('diag_btn_close');
    const toast = document.getElementById('diag_toast');

    let fullTextCache = '';
    let toastTimer = null;

    const statusIcons = {
        pending: '<i class="fa-regular fa-circle"></i>',
        running: '<i class="fa-solid fa-spinner fa-spin"></i>',
        ok: '<i class="fa-solid fa-circle-check"></i>',
        fail: '<i class="fa-solid fa-circle-xmark"></i>',
        skipped: '<i class="fa-solid fa-forward"></i>',
        cancelled: '<i class="fa-solid fa-ban"></i>',
    };

    function escapeHtml(s) {
        const d = document.createElement('div');
        d.textContent = s == null ? '' : String(s);
        return d.innerHTML;
    }

    function lineTone(line) {
        const t = String(line).toLowerCase();
        if (t.includes('megszakít') || t.includes('megszakit')) {
            return 'diag-line--cancel';
        }
        if (t.includes('hiba') || t.includes(': nem,')) {
            return 'diag-line--bad';
        }
        if (t.includes(': ok') || t.includes('): ok') || t.endsWith(': ok')) {
            return 'diag-line--ok';
        }
        if (t.includes('kihagyva')) {
            return 'diag-line--muted';
        }
        if (t.startsWith('---')) {
            return 'diag-line--sep';
        }
        return '';
    }

    function renderLines(lines, container) {
        if (!container) {
            return;
        }
        const arr = Array.isArray(lines) ? lines : [];
        const html = arr
            .map((line) => {
                const tone = lineTone(line);
                return `<div class="diag-line ${tone}">${escapeHtml(line)}</div>`;
            })
            .join('');
        container.innerHTML = html;
    }

    function setToast(msg, isError) {
        if (!toast) {
            return;
        }
        if (toastTimer) {
            clearTimeout(toastTimer);
        }
        toast.textContent = msg || '';
        toast.classList.toggle('diag-toast--error', !!isError);
        toast.classList.add('diag-toast--visible');
        toastTimer = setTimeout(() => {
            toast.classList.remove('diag-toast--visible');
        }, 2200);
    }

    function buildChecklistPlain() {
        if (!checklistEl) {
            return '';
        }
        const rows = checklistEl.querySelectorAll('.diag-cl-row');
        const parts = [];
        rows.forEach((row) => {
            const lbl = row.querySelector('.diag-cl-lbl');
            const det = row.querySelector('.diag-cl-det');
            const st = row.getAttribute('data-status') || '';
            parts.push(
                [lbl ? lbl.textContent : '', det ? det.textContent : '', st].filter(Boolean).join(' — ')
            );
        });
        return parts.join('\n');
    }

    function buildFullText() {
        const a = buildChecklistPlain();
        const b = serverBody ? serverBody.innerText : '';
        const c = progressBody ? progressBody.innerText : '';
        return [a, b, c].filter(Boolean).join('\n\n');
    }

    function showOverlay() {
        if (!overlay) {
            return;
        }
        overlay.classList.remove('diag-hidden');
        overlay.setAttribute('aria-hidden', 'false');
        requestAnimationFrame(() => {
            overlay.classList.add('diag-visible');
        });
    }

    function hideOverlayDom() {
        if (!overlay) {
            return;
        }
        overlay.classList.remove('diag-visible');
        overlay.setAttribute('aria-hidden', 'true');
        setTimeout(() => {
            overlay.classList.add('diag-hidden');
        }, 200);
    }

    function postJson(path, payload, onDone) {
        $.ajax({
            url: `https://${resourceName}/${path}`,
            method: 'POST',
            data: JSON.stringify(payload || {}),
            contentType: 'application/json; charset=UTF-8',
            complete: function () {
                if (typeof onDone === 'function') {
                    onDone();
                }
            },
        });
    }

    function requestClose() {
        postJson('diagnosticsExit', {}, hideOverlayDom);
    }

    function resetChecklistUi() {
        if (checklistEl) {
            checklistEl.innerHTML = '';
        }
        if (liveText) {
            liveText.textContent = '';
        }
        if (liveStrip) {
            liveStrip.classList.remove('diag-live-strip--active');
        }
    }

    function closeSilent() {
        if (!overlay || overlay.classList.contains('diag-hidden')) {
            return;
        }
        overlay.classList.remove('diag-visible');
        overlay.setAttribute('aria-hidden', 'true');
        overlay.classList.add('diag-hidden');
        fullTextCache = '';
        resetChecklistUi();
        if (modal) {
            modal.classList.remove('diag-modal--error');
        }
        if (progressSection) {
            progressSection.classList.add('diag-section--idle');
        }
    }

    function setLiveHint(text) {
        if (liveText) {
            liveText.textContent = text || '';
        }
        if (liveStrip) {
            liveStrip.classList.toggle('diag-live-strip--active', !!(text && String(text).trim()));
        }
    }

    function onChecklistInit(item) {
        if (!checklistEl) {
            return;
        }
        const items = Array.isArray(item.items) ? item.items : [];
        checklistEl.innerHTML = items
            .map((it) => {
                const id = escapeHtml(it.id);
                const label = escapeHtml(it.label || it.id);
                return `<div class="diag-cl-row diag-cl-pending" data-id="${id}" data-status="pending">
                    <span class="diag-cl-ic">${statusIcons.pending}</span>
                    <span class="diag-cl-lbl">${label}</span>
                    <span class="diag-cl-det"></span>
                </div>`;
            })
            .join('');
    }

    function onChecklistSet(item) {
        if (!checklistEl) {
            return;
        }
        const id = item.id;
        const status = item.status || 'pending';
        const detail = item.detail != null ? String(item.detail) : '';
        const row = checklistEl.querySelector('[data-id="' + String(id).replace(/"/g, '') + '"]');
        if (!row) {
            return;
        }
        row.setAttribute('data-status', status);
        row.className = 'diag-cl-row diag-cl-' + status;
        const ic = row.querySelector('.diag-cl-ic');
        const det = row.querySelector('.diag-cl-det');
        if (ic) {
            ic.innerHTML = statusIcons[status] || statusIcons.pending;
        }
        if (det) {
            det.textContent = detail;
        }
        fullTextCache = buildFullText();
    }

    function onRunStart(item) {
        if (modal) {
            modal.classList.remove('diag-modal--error');
        }
        if (titleEl) {
            titleEl.textContent = 'e_core – integritás';
        }
        if (subtitleEl) {
            subtitleEl.textContent =
                'Átlátszó panel: mögötte látod a játékot, a progress sávot és az üzeneteket.';
        }
        if (serverBody) {
            serverBody.innerHTML = '';
        }
        if (progressBody) {
            progressBody.innerHTML = '';
        }
        resetChecklistUi();
        if (progressSection) {
            progressSection.style.display = '';
            progressSection.classList.toggle('diag-section--idle', item.progressPending !== true);
        }
        setLiveHint('Szerver ellenőrzések indulnak…');
        showOverlay();
    }

    function onLogSet(item) {
        renderLines(item.lines || [], serverBody);
        fullTextCache = buildFullText();
    }

    function onDiagOpen(item) {
        const section = item.section || 'server';
        const lines = item.lines || [];
        const pending = item.progressPending === true;

        if (modal) {
            modal.classList.toggle('diag-modal--error', section === 'error');
        }
        if (titleEl) {
            titleEl.textContent =
                section === 'error' ? 'e_core – hiba' : 'e_core – integritás';
        }
        if (subtitleEl) {
            subtitleEl.textContent =
                section === 'error'
                    ? 'A futtatás nem folytatható.'
                    : 'Átlátszó panel: mögötte látod a játékot és a progress sávot.';
        }

        resetChecklistUi();
        renderLines(lines, serverBody);
        if (progressBody) {
            progressBody.innerHTML = '';
        }
        if (progressSection) {
            if (section === 'error') {
                progressSection.style.display = 'none';
            } else {
                progressSection.style.display = '';
                progressSection.classList.toggle('diag-section--idle', !pending);
            }
        }

        setLiveHint(section === 'error' ? '' : '');
        fullTextCache = buildFullText();
        showOverlay();
    }

    function onDiagAppend(item) {
        const lines = item.lines || [];
        renderLines(lines, progressBody);
        if (progressSection) {
            progressSection.classList.remove('diag-section--idle');
        }
        fullTextCache = buildFullText();
    }

    function onDiagClose() {
        closeSilent();
    }

    function copyTextToClipboard(txt) {
        if (navigator.clipboard && typeof navigator.clipboard.writeText === 'function') {
            navigator.clipboard.writeText(txt).then(
                () => setToast('Vágólapra másolva.', false),
                () => copyWithTextarea(txt)
            );
            return;
        }
        copyWithTextarea(txt);
    }

    function copyWithTextarea(txt) {
        const ta = document.createElement('textarea');
        ta.value = txt;
        ta.setAttribute('readonly', '');
        ta.style.position = 'fixed';
        ta.style.left = '-9999px';
        document.body.appendChild(ta);
        ta.select();
        ta.setSelectionRange(0, txt.length);
        let ok = false;
        try {
            ok = document.execCommand('copy');
        } catch (e) {
            ok = false;
        }
        document.body.removeChild(ta);
        if (ok) {
            setToast('Vágólapra másolva.', false);
        } else {
            setToast('Másolás nem sikerült (böngésző / CEF).', true);
        }
    }

    function onCopyClick() {
        const txt = fullTextCache || buildFullText();
        if (!txt) {
            setToast('Nincs másolható szöveg.', true);
            return;
        }
        copyTextToClipboard(txt);
    }

    function onKeydownCapture(e) {
        if (e.key !== 'Escape') {
            return;
        }
        if (!overlay || !overlay.classList.contains('diag-visible')) {
            return;
        }
        e.preventDefault();
        e.stopImmediatePropagation();
        requestClose();
    }

    document.addEventListener('keydown', onKeydownCapture, true);

    if (btnCopy) {
        btnCopy.addEventListener('click', onCopyClick);
    }
    if (btnClose) {
        btnClose.addEventListener('click', requestClose);
    }

    window.eCoreDiagCloseSilent = closeSilent;

    window.eCoreDiagnosticsHandlers = {
        DIAGNOSTICS_RUN_START: onRunStart,
        DIAGNOSTICS_CHECKLIST_INIT: onChecklistInit,
        DIAGNOSTICS_CHECKLIST_SET: onChecklistSet,
        DIAGNOSTICS_LOG_SET: onLogSet,
        DIAGNOSTICS_LIVE_HINT: (item) => setLiveHint(item.text),
        DIAGNOSTICS_OPEN: onDiagOpen,
        DIAGNOSTICS_APPEND: onDiagAppend,
        DIAGNOSTICS_CLOSE: onDiagClose,
    };
})();
