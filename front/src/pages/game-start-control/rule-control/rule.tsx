import * as React from 'react';
import styled from 'styled-components';

import { OptionSuggestion } from '../../../defs/casting-definition';
import {
  CheckboxRule,
  IntegerRule,
  SelectRule,
  TimeRule,
} from '../../../defs/rule-definition';

import { TranslationFunction } from '../../../i18n';

import { bind } from '../../../util/bind';

import { getRuleName, getOptionString } from '../../../logic/rule';

/**
 * Wrapper of rules.
 */
const RuleWrapper = styled.div<{
  /**
   * Whether this rule is disabled.
   */
  disabled: boolean;
}>`
  flex: 0 0 auto;

  margin: 4px;
  padding: 0;
  border: 1px solid
    ${props => (props.disabled ? 'rgba(0, 0, 0, 0.25)' : 'rgba(0, 0, 0, 0.4)')};
  color: ${props => (props.disabled ? 'rgba(0, 0, 0, 0.25)' : 'inherit')};

  text-align: center;

  > label,
  > span {
    display: block;
    box-sizing: border-box;
    width: 100%;
    padding: 6px;
  }

  :hover {
    background-color: ${props =>
      props.disabled ? 'transparent' : 'rgba(255, 255, 255, 0.35)'};
  }
`;

/**
 * Separator for breaking line.
 */
export const Separator = styled.div`
  flex: 0 9999 9999px;
`;

/**
 * Rule name.
 */
const RuleName = styled.b`
  display: inline-block;
  margin-right: 0.8ex;

  font-weight: normal;
`;

interface IPropCheckboxControl {
  t: TranslationFunction;
  /**
   * Whether this item is disabled
   */
  disabled: boolean;
  /**
   * Setting of this rule option.
   */
  item: CheckboxRule;
  /**
   * Current value of this rule.
   */
  value: string;
  /**
   * Callback on changing this rule.
   */
  onChange: (value: string) => void;
}
/**
 * Show one control.
 */
export class CheckboxControl extends React.PureComponent<
  IPropCheckboxControl,
  {}
> {
  public render() {
    const { t, item, value, disabled } = this.props;

    const checked = value === item.value;
    const { name, label } = getRuleName(t, item.id);

    return (
      <RuleWrapper disabled={disabled}>
        <label title={label}>
          <RuleName>{name}</RuleName>
          <input
            type="checkbox"
            checked={checked}
            disabled={disabled}
            onChange={this.handleChange}
          />
        </label>
      </RuleWrapper>
    );
  }
  @bind
  protected handleChange(e: React.SyntheticEvent<HTMLInputElement>) {
    this.props.onChange(e.currentTarget.checked ? this.props.item.value : '');
  }
}

interface IPropIntegerControl {
  t: TranslationFunction;
  item: IntegerRule;
  value: string;
  disabled: boolean;
  onChange: (value: string) => void;
}
/**
 * Show integer control.
 */
export class IntegerControl extends React.PureComponent<
  IPropIntegerControl,
  {}
> {
  public render() {
    const { t, item, value, disabled } = this.props;

    const { name, label } = getRuleName(t, item.id);

    return (
      <RuleWrapper disabled={disabled}>
        <label title={label}>
          <RuleName>{name}</RuleName>
          <input
            type="number"
            value={value}
            min={item.minValue}
            step={item.step}
            disabled={disabled}
            onChange={this.handleChange}
          />
        </label>
      </RuleWrapper>
    );
  }
  @bind
  protected handleChange(e: React.SyntheticEvent<HTMLInputElement>) {
    this.props.onChange(e.currentTarget.value);
  }
}

interface IPropSelectControl {
  t: TranslationFunction;
  /**
   * Definition of this select rule option.
   */
  item: SelectRule;
  /**
   * Current value of this rule.
   */
  value: string;
  /**
   * Whether this rule is disabled.
   */
  disabled: boolean;
  /**
   * Suggestion to this rule, if any.
   */
  suggestion?: OptionSuggestion;
  onChange: (value: string) => void;
}
/**
 * Show integer control.
 */
export class SelectControl extends React.PureComponent<IPropSelectControl, {}> {
  public render() {
    const { t, item, suggestion, value, disabled } = this.props;

    const { name, label } = getRuleName(t, item.id);

    // If there is a must-suggestion, set it read-only.
    const readonly =
      suggestion != null &&
      suggestion.type === 'string' &&
      suggestion.must &&
      suggestion.value === value;

    return (
      <RuleWrapper disabled={disabled}>
        <label title={label}>
          <RuleName>{name}</RuleName>
          <select
            value={value}
            disabled={disabled}
            onChange={this.handleChange}
          >
            {item.values.map(v => {
              const { label, description } = getOptionString(t, item, v);
              return (
                <option
                  key={v}
                  title={description}
                  value={v}
                  // if read-only, other options are disabled.
                  disabled={readonly && v !== value}
                >
                  {label}
                </option>
              );
            })}
          </select>
        </label>
      </RuleWrapper>
    );
  }
  @bind
  protected handleChange(e: React.SyntheticEvent<HTMLSelectElement>) {
    this.props.onChange(e.currentTarget.value);
  }
}
interface IPropTimeControl {
  t: TranslationFunction;
  item: TimeRule;
  value: string;
  disabled: boolean;
  onChange: (value: string) => void;
}

/**
 * Show time control.
 */
export class TimeControl extends React.PureComponent<IPropTimeControl, {}> {
  protected minutes: HTMLInputElement | null = null;
  protected seconds: HTMLInputElement | null = null;
  public render() {
    const { t, item, value, disabled } = this.props;

    const v = Number(value);
    const minutes = Math.floor(v / 60);
    const seconds = v % 60;

    const { name, label } = getRuleName(t, item.id);

    return (
      <RuleWrapper disabled={disabled}>
        <span title={label}>
          <RuleName>{name}</RuleName>
          <input
            ref={i => (this.minutes = i)}
            type="number"
            value={minutes}
            min={0}
            step={1}
            disabled={disabled}
            onChange={this.handleChange}
          />
          {t('game_client:gamestart.control.minutes')}
          <input
            ref={i => (this.seconds = i)}
            type="number"
            value={seconds}
            min={-1}
            max={60}
            step={1}
            disabled={disabled}
            onChange={this.handleChange}
          />
          {t('game_client:gamestart.control.seconds')}
        </span>
      </RuleWrapper>
    );
  }
  @bind
  protected handleChange() {
    // calculate current value.
    const minutes = this.minutes ? Number(this.minutes.value) : 0;
    const seconds = this.seconds ? Number(this.seconds.value) : 0;
    const value = minutes * 60 + seconds;
    // retrieve minimum value.
    const minimum = this.props.item.minValue || 0;
    this.props.onChange(String(value >= minimum ? value : minimum));
  }
}
