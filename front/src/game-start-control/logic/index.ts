import {
    RoleCategoryDefinition,
} from '../../defs/category-definition';
import {
    RuleGroup,
} from '../../defs/rule-definition';

import {
    CastingStore,
} from '../store';

import {
    getQuery,
} from './query';
import {
    checkSuggestion,
} from './suggestion';

export interface GameStartInput {
    roles: string[];
    categories: RoleCategoryDefinition[];
    ruledefs: RuleGroup,
    store: CastingStore;
}
/**
 * Logic of game start.
 * @returns {Promise} Promise which resolves to query object if game can be started, undefined otherwise.
 */
export async function gameStart({
    roles,
    categories,
    store,
}: GameStartInput): Promise<Record<string, string> | undefined> {
    const {
        currentCasting,
        rules,
    } = store;
    const query = getQuery(roles, categories, store);

    // Check suggested options.
    if (currentCasting.suggestedOptions != null) {
        for (const name in currentCasting.suggestedOptions) {
            const sug = currentCasting.suggestedOptions[name];
            // Current value of this rule.
            const val = rules.get(name);
            if (val == null) {
                throw new Error(`undefined value of rule '${name}'`);
            }

            if (!checkSuggestion(val, sug)) {
                // are---
            }
        }
    }

    return undefined;
}

