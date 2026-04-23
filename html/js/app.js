const model = new Model();
const view = new View();
const resourceName = GetParentResourceName();

const CSS_ROOT = document.querySelector(':root');
const CSS_ROOT_COMPUTED_STYLE = getComputedStyle(CSS_ROOT);

let locale = {};

function numberFormat(num) {

    return (num === undefined || !num) ? 0 : num.toLocaleString('hu-HU');
}

function translate(key) {

    return locale[key] ? locale[key] : key;
}

function postNui(path) {

    $.post(`https://${resourceName}/${path}`);
}

const Subject = {
    PAGE: 'page',
    HUD: 'hud',
    ALL: 'all'
};

function onUpdate(item) {

    if (item.subject === Subject.PAGE) {

        model.metadata = item.metadata;
        view.updateStat();
        view.updateHud();
        return;
    }

    if (item.subject === Subject.HUD) {

        model.metadata = item.metadata;
        view.updateHud();
    }
}

function onInit(item) {

    locale = item.locale || {};
    model.init = item;
    view.init();
}

function onOpen(item) {

    if (item.subject === Subject.PAGE) {

        model.metadata = item.metadata;
        view.updateStat();
        view.openPage();
        return;
    }

    if (item.subject === Subject.HUD) {

        view.openHud();
    }
}

function onClose(item) {

    if (item.subject === Subject.PAGE) {

        view.closePage();
        return;
    }

    if (item.subject === Subject.HUD) {

        view.closeHud();
        return;
    }

    if (item.subject === Subject.ALL) {

        view.closePage();
        view.closeHud();
        if (typeof window.eCoreDiagCloseSilent === 'function') {
            window.eCoreDiagCloseSilent();
        }
    }
}

const messageHandlers = {
    UPDATE: onUpdate,
    INIT: onInit,
    OPEN: onOpen,
    CLOSE: onClose,
    POPUP: (item) => view.popUp(item.data),
    DIAGNOSTICS_OPEN: (item) => {
        const h = window.eCoreDiagnosticsHandlers;
        if (h && typeof h.DIAGNOSTICS_OPEN === 'function') {
            h.DIAGNOSTICS_OPEN(item);
        }
    },
    DIAGNOSTICS_APPEND: (item) => {
        const h = window.eCoreDiagnosticsHandlers;
        if (h && typeof h.DIAGNOSTICS_APPEND === 'function') {
            h.DIAGNOSTICS_APPEND(item);
        }
    },
    DIAGNOSTICS_CLOSE: () => {
        const h = window.eCoreDiagnosticsHandlers;
        if (h && typeof h.DIAGNOSTICS_CLOSE === 'function') {
            h.DIAGNOSTICS_CLOSE();
        }
    },
    DIAGNOSTICS_RUN_START: (item) => {
        const h = window.eCoreDiagnosticsHandlers;
        if (h && typeof h.DIAGNOSTICS_RUN_START === 'function') {
            h.DIAGNOSTICS_RUN_START(item);
        }
    },
    DIAGNOSTICS_CHECKLIST_INIT: (item) => {
        const h = window.eCoreDiagnosticsHandlers;
        if (h && typeof h.DIAGNOSTICS_CHECKLIST_INIT === 'function') {
            h.DIAGNOSTICS_CHECKLIST_INIT(item);
        }
    },
    DIAGNOSTICS_CHECKLIST_SET: (item) => {
        const h = window.eCoreDiagnosticsHandlers;
        if (h && typeof h.DIAGNOSTICS_CHECKLIST_SET === 'function') {
            h.DIAGNOSTICS_CHECKLIST_SET(item);
        }
    },
    DIAGNOSTICS_LOG_SET: (item) => {
        const h = window.eCoreDiagnosticsHandlers;
        if (h && typeof h.DIAGNOSTICS_LOG_SET === 'function') {
            h.DIAGNOSTICS_LOG_SET(item);
        }
    },
    DIAGNOSTICS_LIVE_HINT: (item) => {
        const h = window.eCoreDiagnosticsHandlers;
        if (h && typeof h.DIAGNOSTICS_LIVE_HINT === 'function') {
            h.DIAGNOSTICS_LIVE_HINT(item);
        }
    },
};

function onNuiMessage(event) {

    const item = event.data;
    const handler = messageHandlers[item.action];

    if (typeof handler === 'function') {

        handler(item);
    }
}

function closePageAndExit() {

    view.closePage();
    postNui('exit');
}

postNui('nuiReady');

window.addEventListener('message', onNuiMessage);

$('#close').on('click', closePageAndExit);

$(document).on('keyup', (e) => {

    if (e.which === 27) {
        const diag = document.getElementById('diag_overlay');
        if (diag && diag.classList.contains('diag-visible')) {
            return;
        }

        closePageAndExit();
    }
});
