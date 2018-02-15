import * as React from 'react';
import * as ReactDOM from 'react-dom';
import {
    runInAction,
} from 'mobx';

import {
    CastingStore,
} from './store';
import {
    Casting,
} from './component';
import {
    CastingDefinition,
    LabeledGroup,
    RoleCategoryDefinition,
    RuleGroup,
} from '../defs';
import {
    i18n,
} from '../i18n';
import {
    findLabeledGroupItem,
} from '../util/labeled-group';

/**
 * Options to place.
 */
export interface IPlaceOptions {
    /**
     * i18n instance to use.
     */
    i18n: i18n;
    /**
     * A node to place the component to.
     */
    node: HTMLElement;
    /**
     * Id of roles.
     */
    roles: string[];
    /**
     * Definition of castings.
     */
    castings: LabeledGroup<CastingDefinition, string>;
    /**
     * Definition of categories.
     */
    categories: RoleCategoryDefinition[];
    /**
     * Definition of rules.
     */
    rules: RuleGroup;
    /**
     * Initial selection of casting.
     */
    initialCasting: CastingDefinition;
    /**
     * Event of pressing gamestart button.
     */
    onStart: (query: Record<string, string>)=> void;
}
export interface IPlaceResult {
    store: CastingStore;
    unmount(): void;
}

/**
 * Place a game start control component.
 * @returns Unmount point with newly created store.
 */
export function place({
    i18n,
    node,
    roles,
    castings,
    categories,
    rules,
    initialCasting,
    onStart,
}: IPlaceOptions): IPlaceResult {
    const store = new CastingStore(roles, categories, initialCasting);
    runInAction(()=> {
        store.setCurrentCasting(initialCasting);
        setInitialRules(rules, store);
        loadSavedRules(castings, categories, roles, store);
    });

    // XXX ad-hoc but exclude hidden roles.
    const cs = excludeHiddenRoles(categories, roles);

    const com =
        <Casting
            i18n={i18n}
            store={store}
            roles={roles}
            castings={castings}
            categories={cs}
            ruledefs={rules}
            onStart={onStart}
        />;

    ReactDOM.render(com, node);

    return {
        store,
        unmount: ()=>{
            ReactDOM.unmountComponentAtNode(node);
        },
    };
}

/**
 * Filter out hidden roles from categories.
 */
function excludeHiddenRoles(categories: RoleCategoryDefinition[], roles: string[]): RoleCategoryDefinition[] {
    // rolesをsetに変換
    const rolesSet = new Set(roles);
    const result: RoleCategoryDefinition[] = [];
    for (const {id, roles} of categories) {
        const r = roles.filter((x)=> rolesSet.has(x));
        if (r.length > 0) {
            result.push({
                id,
                roles: r,
            });
        }
    }
    return result;
}

/**
 * Set initial rule settings to store.
 */
function setInitialRules(rules: RuleGroup, store: CastingStore): void {
    for (const rule of rules) {
        if (rule.type === 'group') {
            setInitialRules(rule.items, store);
        } else {
            const {
                value,
            } = rule;
            switch (value.type) {
                case 'checkbox': {
                    const v = value.defaultChecked ? value.value : '';
                    store.updateRule(value.id, v, true);
                    break;
                }
                case 'hidden': {
                    store.updateRule(value.id, value.value, true);
                    break;
                }
                case 'integer': {
                    store.updateRule(value.id, String(value.defaultValue), true);
                    break;
                }
                case 'select': {
                    store.updateRule(value.id, value.defaultValue, true);
                    break;
                }
                case 'time': {
                    store.updateRule(value.id, String(value.defaultValue), true);
                    break;
                }
            }
        }
    }
}

/**
 * Load saved rule settings.
 * @param roles provided list of roles.
 * @param store Rule store.
 */
function loadSavedRules(
    castings: LabeledGroup<CastingDefinition, string>,
    categories: RoleCategoryDefinition[],
    roles: string[],
    store: CastingStore,
): void {
    const {
        savedRule,
    } = localStorage;
    if (!savedRule) {
        return;
    }

    const rule = JSON.parse(savedRule);
    // First, set casting.
    const castingId = rule.jobrule;
    const casting = findLabeledGroupItem(castings, (item)=> item.id === castingId);
    if (casting != null) {
        store.setCurrentCasting(casting);
    }

    for (const key in rule) {
        // XXX we have to ignore some keys.
        if (['number', 'maxnumber', 'blind', 'gm', 'jobrule', '_jobquery'].includes(key)) {
            continue;
        }
        store.updateRule(key, rule[key]);
    }
    // XXX we are following old query-based formats.
    const jobs = rule._jobquery;
    if (jobs != null) {
        for (const role of roles) {
            const num = Number(jobs[role]);
            if (isFinite(num)) {
                const included = jobs[`job_use_${role}`] === 'on';
                store.updateJobNumber(role, num, included);
            }
        }
        for (const cat of categories) {
            const num = Number(jobs[`category_${cat.id}`]);
            if (isFinite(num)) {
                store.updateCategoryNumber(cat.id, num);
            }
        }
    }

    localStorage.removeItem('savedRule');
}
