class View {

    _selectedCategory = '';
    _pageContainer = $('#container');
    _metaHud = $('#meta_hud');
    _laborHudPoint = $('#labor_hud_point');
    _laborHudProgress = $('#labor_hud_progress');

    init() {

        //locale HTML
        /*
            $.each($('*[data-translate]'), function () {

                let $this = $(this);
                let txt = translate($this.data().translate);
                $this.text(txt);
            });
        */

        this.createCategoryMenu();
    }

    updateHud() {

        let data = model.metadata.labor;

        if (!$.isEmptyObject(data)) {

            this._laborHudPoint.text(data.val);
            this._laborHudProgress.css('width', Math.floor((data.val / model.laborLimit) * 100) + '%');
        }
    }

    createCategoryMenu() {

        let menuContainer = $('#meta_categories');

        if (!$.trim(menuContainer.html())) {

            let categories = model.displayComponent.statisticsPage;
            let metadata = model.metadata;

            let parent = $("<ul/>", {
                "class": "menu",
                "id": "meta_categories_menu"
            }).appendTo(menuContainer);

            categories.forEach(function (categoryName) {

                if (metadata[categoryName] !== undefined) {

                    $("<li/>", {
                        "text": translate(categoryName),
                        "id": `${categoryName}_menu_item`,
                        "class": "category_menu_item",
                        "click": function () {
                            view._selectedCategory = categoryName;
                            view.applySelectedCategory();
                            return false;
                        }
                    }).appendTo(parent);
                }
            })
        }
    }

    createStatHtml(categoryName, data) {

        let content = $('.content');
        let section = content.find(`#${ categoryName }_section`);
        let displayIcon = model.displayComponent.icon;
        let container;

        if (section.html() === undefined) {

            let section = $("<section/>", {
                "html": `<h2>${translate(categoryName)}</h2>`,
                "id": categoryName + "_section",
                "class": "category_section"
            }).appendTo(content);

            container = $("<div/>", {
                "id": categoryName + "_section_content"
            }).appendTo(section);
        }

        let firstLetter = '';
        let bgImage = '';
        let colors = [
            "#ec6f86",
            "#4573e7",
            "#d187ef",
            "#fe816d",
            "#7e69ff",
            "#ffba6d",
            "#b2f068",
            "#45b4e7",
            "#ad61ed"];


        let statArray = [];

        $.each(data, function (key, value) {

            statArray.push([key, value, translate(key)])
        });

        statArray.sort((a, b) => a[2].localeCompare(b[2]));

        let colorIdx = 0;

        let parent = $("<ul/>", {
            "class": "stats",
        });

        statArray.forEach(function (statData) {

            if (displayIcon) {

                bgImage = `background-image: url(img/${ statData[0] }.png)`;
            } else {

                firstLetter = statData[2].substring(0, 1);
            }

            $("<li/>", {
                "html": `<span 
                    style="background-color: ${colors[colorIdx]};${ bgImage }" 
                    class="icon">${ firstLetter }</span>
                    <span class="data">
                        <span class="name" id="${ statData[0] }_name">${ statData[2] }</span>
                        <span class="${ statData[0] }_value value">${ numberFormat(statData[1]) }</span>
                        <span class="bar">
                            <span class="${ statData[0] }_progress progress"></span>
                        </span>
                    </span>`
            }).appendTo(parent);

            colorIdx++;

            if (colorIdx >= colors.length) {

                colorIdx = 0;
            }
        });

        parent.appendTo(container);

        return container;
    }

    updateStat() {

        let categories = model.displayComponent.statisticsPage;
        let metadata = model.metadata;
        let maxLevel = model.maxLevel;

        let data = {};
        let rank = {};

        let progress = 0;
        let level = 0;

        let content = $('.content');

        categories.forEach(function (categoryName) {

            if (metadata[categoryName] !== undefined) {

                data = metadata[categoryName];

                let container = content.find(`#${ categoryName }_section_content`);

                if (container.html() === undefined || !$.trim(container.html())) {

                    container = view.createStatHtml(categoryName, data);
                }

                progress = 0;
                level = 0;

                $.each(data, function (stat, value) {

                    rank = model.rankData(value);
                    level = (rank.level === maxLevel) ? 'famed' : rank.level;
                    progress = rank.progress;

                    container.find(`#${ stat }_name`).attr("class", `name level lvl_${ level }`);
                    container.find(`.${ stat }_progress`).css('width', progress + '%');
                    container.find(`.${ stat }_value`).text(numberFormat(value));
                });
            }
        });

        this.applySelectedCategory();
    }

    applySelectedCategory() {

        let categories = model.displayComponent.statisticsPage;
        let metadata = model.metadata;

        if (!metadata[this._selectedCategory]) {

            this._selectedCategory = categories[0];
        }

        $('.category_menu_item').removeClass('selected');
        $(`#${this._selectedCategory}_menu_item`).addClass('selected');

        $('.category_section').css('display', 'none');
        $(`#${this._selectedCategory}_section`).css('display', 'block');
    }

    openPage() {

        this._pageContainer.fadeIn();
    }

    closePage() {

        this._pageContainer.fadeOut();
    }

    openHud() {

        this._metaHud.fadeIn()
    }

    closeHud() {

        this._metaHud.fadeOut();
    }

    popUp(data) {
        /*
                category = category,
                    name = name,
                    baseLevel = baseLevel,
                    newLevel = newLevel
                */

        //let display = data.baseLevel + " => " + data.newLevel;
        let display, color;

        if (data.newLevel === model.maxLevel) {

            display = "⭐";
            color = CSS_ROOT_COMPUTED_STYLE.getPropertyValue('--lvl-famed-color');
        } else {

            display = data.newLevel;
            color = CSS_ROOT_COMPUTED_STYLE.getPropertyValue(`--lvl-${ data.newLevel }-color`);
        }

        let popup = $("<div/>", {
            "style": `border-color:${ color }; box-shadow: 0 0 3rem ${ color };`,
            "id": "popup_container",
            "html": `<h1>${ translate('level_up') }</h1>
                    <h4>${ translate(data.category) }</h4>
                    <h2>${ translate(data.name) }</h2>
                    <span class="up_level" style="background-color:${ color };">${ display }</span>
                    <span class="level_name" style="color:${ color };">${ translate('level ' + data.newLevel) }</span>`
        }).appendTo($('body'));

        setTimeout(() => {

            popup.fadeOut(800, () => {

                popup.remove();
            });
        }, 5000);
    }
}