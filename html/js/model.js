class Model {

    set init(data) {

        this._laborLimit = data.laborLimit || 0;
        this._abilityLimit = data.abilityLimit || 0;
        this._displayComponent = data.displayComponent || {};
        this._metadata = data.metadata || {};
        this._levels = data.levels || {};
    }

    get laborLimit() {

        return this._laborLimit
    }

    get abilityLimit() {

        return this._abilityLimit
    }

    get metadata() {

        return this._metadata
    }

    get levels() {

        return this._levels;
    }

    get maxLevel() {

        return this._levels.length - 1;
    }

    get displayComponent() {

        return this._displayComponent
    }

    set metadata(metadata) {

        this._metadata = metadata;
    }

    rankData(value) {

        let numberOfRanks = this._levels.length;

        if (numberOfRanks === 0 || value === undefined) {

            return false
        }

        if (value < this._levels[0].limit) {

            return {
                level: 0,
                progress: (value > 0) ? Math.floor(value / this._levels[0].limit * 100) : 0
            };
        }

        for (let i = 1; i < numberOfRanks; i++) {

            if (this._levels[i].limit !== undefined && this._levels[i].limit > value) {

                let range = this._levels[i].limit - this._levels[i - 1].limit;

                return {
                    level: i,
                    progress: Math.floor(((value - this._levels[i - 1].limit) / range) * 100)
                };
            }
        }

        return {
            level: numberOfRanks - 1,
            progress: 100
        }
    }
}