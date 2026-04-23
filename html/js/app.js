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
    }
}

const messageHandlers = {
    UPDATE: onUpdate,
    INIT: onInit,
    OPEN: onOpen,
    CLOSE: onClose,
    POPUP: (item) => view.popUp(item.data)
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

        closePageAndExit();
    }
});
