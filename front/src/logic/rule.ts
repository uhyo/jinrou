// Logics related to game rules.

import {
    OptionSuggestion,
} from '../defs/casting-definition';
import {
    RuleDefinition,
} from '../defs/rule-definition';
import {
    TranslationFunction,
} from '../i18n';

/**
 * Check the suggestion to rules.
 * @returns {boolean} true if suggestion is satisfied.
 */
export function checkSuggestion(
    ruleValue: string,
    suggestion: OptionSuggestion,
): boolean {
    if (typeof suggestion === 'string') {
        // String suggestion.
        return ruleValue === suggestion;
    } else if (suggestion.type === 'string') {
        return ruleValue === suggestion.value;
    } else if (suggestion.type === 'range') {
        // Range suggestion.
        const v = Number(ruleValue);
        if (!isFinite(v)) {
            return false;
        }
        if (suggestion.min != null && v < suggestion.min) {
            return false;
        }
        if (suggestion.max != null && v > suggestion.max) {
            return false;
        }
        return true;
    }
    // XXX https://github.com/Microsoft/TypeScript/issues/16976
    // https://github.com/Microsoft/TypeScript/issues/16976
    const n: never = suggestion;
    throw new Error('Unreachable');
}

export interface RuleText {
    name: string;
    label: string;
}
/**
 * Retrieve name and label of given rule item from language file.
 */
export function getRuleName(t: TranslationFunction, id: string): RuleText {
    const name = t(`rules:rule.${id}.name`);
    const label = t(`rules:rule.${id}.label`);
    return {
        name,
        label,
    };
}

export interface RuleExpression {
    /**
     * Label of this rule setting.
     */
    label: string;
    value: string;
}
/**
 * Get an expression of one rule setting as a name-value object.
 */
export function getRuleExpression(
    t: TranslationFunction,
    rule: RuleDefinition,
    value: string,
): RuleExpression {
    if (rule.type === 'separator') {
        return {
            label: '',
            value: '',
        };
    }
    if (rule.getstr != null) {
        const gotstr = rule.getstr(t, value);

        const label =
            gotstr != null && gotstr.label != null ?
            gotstr.label :
            t(`rules:rule.${rule.id}.name`);

        const v =
            gotstr != null && gotstr.value != null ?
            gotstr.value :
            getRuleValue(t, rule, value);

        return {
            label,
            value: v,
        };
    } else {
        return {
            label: t(`rules:rule.${rule.id}.name`),
            value: getRuleValue(t, rule, value),
        };
    }
}

/**
 * Get a default expression of rule value.
 */
function getRuleValue(
    t: TranslationFunction,
    rule: RuleDefinition,
    value: string,
): string {
    switch (rule.type) {
        case 'checkbox':
        case 'hidden':
            {
            if (value === rule.value) {
                // checked
                return t(`rules:rule.${rule.id}.yes`);
            } else {
                // not checked
                return t(`rules:rule.${rule.id}.no`);
            }
        }
        case 'integer': {
            return String(value);
        }
        case 'select': {
            return t(`rules:rule.${rule.id}.labels.${value}`);
        }
        case 'separator': {
            return '';
        }
        case 'time': {
            const v = Number(value);
            if (isFinite(v)) {
                const minutes = Math.floor(v / 60);
                const seconds = v % 60;

                const minutessep = t('rules:common.minutes');
                const secondssep = t('rules:common.seconds');
                if (minutes !== 0) {
                    return `${minutes}${minutessep}${seconds}${secondssep}`;
                } else {
                    return `${seconds}${secondssep}`;
                }
            }
            return '';
        }
    }
}
