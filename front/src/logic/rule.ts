// Logics related to game rules.

import { OptionSuggestion } from '../defs/casting-definition';
import { RuleDefinition, SelectRule } from '../defs/rule-definition';
import { TranslationFunction } from '../i18n';
import { createDeflate } from 'zlib';

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
 * If rule value is invalid or has no expression, return null.
 */
export function getRuleExpression(
  t: TranslationFunction,
  rule: RuleDefinition,
  value: string,
): RuleExpression | null {
  // Check validity of rule.
  if (!checkRuleValidity(rule, value)) {
    return null;
  }
  if (rule.type === 'separator') {
    return null;
  }
  if (rule.getstr != null) {
    const gotstr = rule.getstr(t, value);

    const label =
      gotstr != null && gotstr.label != null
        ? gotstr.label
        : t(`rules:rule.${rule.id}.name`);

    const v =
      gotstr != null && gotstr.value != null
        ? gotstr.value
        : getRuleValue(t, rule, value);

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
 * Check validity of given value of rule.
 */
export function checkRuleValidity(
  rule: RuleDefinition,
  value: string,
): boolean {
  switch (rule.type) {
    case 'checkbox': {
      return value === '' || value === rule.value;
    }
    case 'hidden':
      return true;
    case 'integer':
      return Number.isFinite(parseInt(value, 10));
    case 'select': {
      return rule.values.includes(value);
    }
    case 'separator':
      return false;
    case 'time': {
      const num = parseInt(value, 10);
      return Number.isFinite(num) && num >= 0;
    }
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
    case 'hidden': {
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
      const { label } = getOptionString(t, rule, value);
      return label;
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

/**
 * Get label and description of given option.
 */
export function getOptionString(
  t: TranslationFunction,
  rule: SelectRule,
  value: string,
): OptionExpression {
  const res = (rule.getOptionStr && rule.getOptionStr(t, value)) || {};
  const label = res.label || t(`rules:rule.${rule.id}.labels.${value}`);
  const description =
    res.description || t(`rules:rule.${rule.id}.descriptions.${value}`);
  return {
    label,
    description,
  };
}

export interface OptionExpression {
  label: string;
  description: string;
}
