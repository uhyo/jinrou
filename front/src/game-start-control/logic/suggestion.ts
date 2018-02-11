import {
    OptionSuggestion,
} from '../../defs/casting-definition';
import {
    RuleDefinition,
} from '../../defs/rule-definition';

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
    throw new Error('Unreachable');
}
