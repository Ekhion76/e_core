/*
 * Reusable NUI access helper class.
 * Lua parity target: e_core/src/libs/GroupAccess.lua
 *
 * Consumer usage:
 *   GroupAccess.check(playerData, recipeOrZoneData)
 */
class GroupAccess {
    static isObject(value) {
        return value && typeof value === 'object' && !Array.isArray(value);
    }

    static isPopulatedTable(value) {
        if (!value || typeof value !== 'object') {
            return false;
        }
        return Object.keys(value).length > 0;
    }

    static inArray(needle, haystack) {
        return Array.isArray(haystack) && haystack.indexOf(needle) !== -1;
    }

    static collectGroups(playerData) {
        var groups = [];
        if (!this.isObject(playerData)) {
            return groups;
        }

        if (this.isObject(playerData.job) && typeof playerData.job.name === 'string' && playerData.job.name.trim() !== '') {
            groups.push({ name: playerData.job.name, grade: playerData.job.grade });
        }

        if (this.isObject(playerData.gang) && typeof playerData.gang.name === 'string' && playerData.gang.name.trim() !== '') {
            groups.push({ name: playerData.gang.name, grade: playerData.gang.grade });
        }

        return groups;
    }

    static matchGroup(group, list) {
        if (this.inArray(group.name, list)) {
            return true;
        }

        if (!this.isObject(list) && !Array.isArray(list)) {
            return false;
        }

        var gradeList = list[group.name];
        if (gradeList !== undefined && gradeList !== null) {
            if (!this.isPopulatedTable(gradeList)) {
                return true;
            }
            return this.inArray(group.grade, gradeList);
        }

        return false;
    }

    static evaluate(groups, list, isWhitelist) {
        for (var i = 0; i < groups.length; i++) {
            if (this.matchGroup(groups[i], list)) {
                return isWhitelist;
            }
        }
        return !isWhitelist;
    }

    static check(playerData, data) {
        if (!this.isObject(data)) {
            return true;
        }

        var hasWhitelist = this.isPopulatedTable(data.whitelist);
        var hasBlacklist = this.isPopulatedTable(data.blacklist);
        if (!hasWhitelist && !hasBlacklist) {
            return true;
        }

        var groups = this.collectGroups(playerData);
        if (hasWhitelist) {
            return this.evaluate(groups, data.whitelist, true);
        }

        return this.evaluate(groups, data.blacklist, false);
    }
}

window.GroupAccess = GroupAccess;
