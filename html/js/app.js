const model = new Model();
const view = new View();
const resourceName = GetParentResourceName();

const CSS_ROOT = document.querySelector(':root');
const CSS_ROOT_COMPUTED_STYLE = getComputedStyle(CSS_ROOT);

let locale = {};

const numberFormat = function (num) {

    return (num === undefined || !num) ? 0 : num.toLocaleString('hu-HU');
};

const translate = function (key) {

    return (locale[key]) ? locale[key] : key;
};


$.post(`https://${resourceName}/nuiReady`);


window.addEventListener('message', function (event) {

    let item = event.data;

    switch (item.action) {

        case 'UPDATE':

            if (item.subject === 'page') {

                model.metadata = item.metadata;
                view.updateStat();
                view.updateHud();

            } else if (item.subject === 'hud') {

                model.metadata = item.metadata;
                view.updateHud();
            }
            break;

        case 'INIT':

            locale = item.locale || {};
            model.init = item;
            view.init();
            break;

        case 'OPEN':

            if (item.subject === 'page') {

                model.metadata = item.metadata;
                view.updateStat();
                view.openPage();

            } else if (item.subject === 'hud') {

                view.openHud();
            }
            break;

        case 'CLOSE':

            if (item.subject === 'page') {

                view.closePage();

            } else if (item.subject === 'hud') {

                view.closeHud();

            } else if (item.subject === 'all') {

                view.closePage();
                view.closeHud();
            }
            break;

        case 'POPUP':

            view.popUp(item.data);
            break;
    }
});

//CLOSE BUTTON
$('#close').on('click', function () {

    view.closePage();
    $.post(`https://${resourceName}/exit`);
});

$(document).on('keyup', function (e) {

    if (e.which === 27) {

        view.closePage();
        $.post(`https://${resourceName}/exit`);
    }
});