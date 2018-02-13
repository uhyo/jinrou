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
    forLanguage,
} from '../i18n';

/**
 * Options to place.
 */
export interface IPlaceOptions {
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
    });

    // TODO language
    const i18n = forLanguage('ja');

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
                    store.updateRule(value.id, v);
                    break;
                }
                case 'hidden': {
                    store.updateRule(value.id, value.value);
                    break;
                }
                case 'integer': {
                    store.updateRule(value.id, String(value.defaultValue));
                    break;
                }
                case 'select': {
                    store.updateRule(value.id, value.defaultValue);
                    break;
                }
                case 'time': {
                    store.updateRule(value.id, String(value.defaultValue));
                    break;
                }
            }
        }
    }
}
