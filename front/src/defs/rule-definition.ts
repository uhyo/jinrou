import { TranslationFunction } from '../i18n';

import { LabeledGroup } from './labeled-group';

export interface RuleDefinitionBase {
  /**
   * Id of this rule setting.
   */
  id: string;
  /**
   * Whether this setting is disabled.
   */
  disabled?: (rule: Rule, isEditor: boolean) => boolean;
  /**
   * Rule string generation function.
   */
  getstr?: (t: TranslationFunction, value: string) => GetstrResult | undefined;
}

export interface GetstrResult {
  /**
   * Title of this rule setting.
   * If undefined, default rule name is used.
   */
  label?: string;
  /**
   * Value of this rule setting.
   */
  value?: string;
}

export interface SelectRule extends RuleDefinitionBase {
  type: 'select';
  values: string[];
  defaultValue: string;
  /**
   * Label and description of each option.
   */
  getOptionStr?: (
    t: TranslationFunction,
    value: string,
  ) => GetOptionStrResult | undefined;
}

export interface GetOptionStrResult {
  /**
   * Label of this option.
   */
  label?: string;
  /**
   * Description of this option.
   */
  description?: string;
}

export interface CheckboxRule extends RuleDefinitionBase {
  type: 'checkbox';
  value: string;
  defaultChecked?: boolean;
}

export interface TimeRule extends RuleDefinitionBase {
  type: 'time';
  defaultValue: number;
  minValue?: number;
}

export interface Separator {
  id?: string;
  type: 'separator';
}

export interface HiddenRule extends RuleDefinitionBase {
  type: 'hidden';
  value: string;
}

export interface IntegerRule extends RuleDefinitionBase {
  type: 'integer';
  defaultValue: number;
  minValue?: number;
  step?: number;
}

/**
 * Definition of rule setting.
 */
export type RuleDefinition =
  | SelectRule
  | CheckboxRule
  | TimeRule
  | IntegerRule
  | HiddenRule
  | Separator;

/**
 * Label of rule.
 */
export interface RuleGroupLabel {
  /**
   * Id of this group.
   * Only used for user interface purposes.
   */
  id: string;
  /**
   * Whether this setting is visible for current setting.
   * @param {Rule} rule current rule
   * @param {boolean} isEditor whether currently showing a rule editor
   */
  visible: (rule: Rule, isEditor: boolean) => boolean;
}

/**
 * Labeled group of options.
 */
export type RuleGroup = LabeledGroup<RuleDefinition, RuleGroupLabel>;

/**
 * All rule sertings.
 */
export interface Rule {
  /**
   * Setting of casting.
   */
  casting: string;
  /**
   * Options.
   */
  rules: Map<string, string>;
  /**
   * Job numbers.
   */
  jobNumbers: Record<string, number>;
}
