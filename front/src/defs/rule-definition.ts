import {
    CastingDefinition,
} from './casting-definition';
import {
    LabeledGroup,
} from './labeled-group';

export interface RuleDefinitionBase {
    /**
     * Id of this rule setting.
     */
    id: string;
    /**
     * Rule string generation function.
     */
    getstr?: (value: string, rule: Rule)=> GetstrResult | null;
}

export interface GetstrResult {
    /**
     * Title of this rule setting.
     */
    label: string;
    /**
     * Value of this rule setting.
     */
    value: string;
}

export interface SelectRule extends RuleDefinitionBase {
    type: 'select';
    values: SelectValue[];
    defaultValue: string;
}
export interface SelectValue {
    value: string;
}

export interface CheckboxRule extends RuleDefinitionBase {
    type: 'checkbox';
    value: CheckboxValue;
    defaultChecked?: boolean;
}
export interface CheckboxValue {
    /**
     * Value of checkbox.
     */
    value: string;
    /**
     * Label expressing the meaning of setting this true.
     */
    label: string;
    /**
     * Label of false.
     */
    nolabel?: string;
}

export interface TimeRule extends RuleDefinitionBase {
    type: 'time';
    defaultValue: number;
}

export interface Separator {
    type: 'separator';
}

export interface HiddenRule extends RuleDefinitionBase {
    type: 'hidden';
    value: CheckboxValue;
}

export interface IntegerRule extends RuleDefinitionBase {
    type: 'integer';
    defaultValue: number;
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
    | Separator
;

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
     */
    visible: (rule: Rule)=> boolean;
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
    casting: CastingDefinition;
    /**
     * Options.
     */
    rules: Map<string, string>;
    /**
     * Job numbers.
     */
    jobNumbers: Record<string, number>;
}
