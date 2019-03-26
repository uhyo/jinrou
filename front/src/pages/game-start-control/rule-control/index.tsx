import * as React from 'react';
import { observer } from 'mobx-react';

import { OptionSuggestion } from '../../../defs/casting-definition';
import { RuleGroup, Rule } from '../../../defs/rule-definition';
import { TranslationFunction } from '../../../i18n';
import { bind } from '../../../util/bind';
import { CachedBinder } from '../../../util/cached-binder';

import {
  CheckboxControl,
  IntegerControl,
  SelectControl,
  TimeControl,
  Separator,
} from './rule';
import { RuleSetGroup } from './group';

export interface IPropRuleControl {
  t: TranslationFunction;
  /**
   * Definition of all rule settings.
   */
  ruledefs: RuleGroup;
  /**
   * Suggestion of rule options.
   */
  suggestedOptions?: Record<string, OptionSuggestion>;
  /**
   * Current rule setting.
   */
  ruleObject: Rule;
  /**
   * Callback function for rule updates.
   */
  onUpdate: (rule: string, value: string) => void;
}
/**
 * Interface of editing rules.
 */
@observer
export class RuleControl extends React.Component<IPropRuleControl, {}> {
  protected updateHandlers = new CachedBinder<string, string, void>();
  public render(): JSX.Element {
    const {
      t,
      ruledefs,
      suggestedOptions = {},
      ruleObject,
      onUpdate,
    } = this.props;
    const { rules } = ruleObject;

    return (
      <>
        {ruledefs.map((rule, i) => {
          if (rule.type === 'group') {
            const { id, visible } = rule.label;
            const vi = visible(ruleObject, true);
            if (vi) {
              return (
                <RuleSetGroup
                  key={`group-${id}`}
                  name={t(`rules:ruleGroup.${id}.name`)}
                >
                  <RuleControl
                    t={t}
                    ruledefs={rule.items}
                    suggestedOptions={suggestedOptions}
                    ruleObject={ruleObject}
                    onUpdate={onUpdate}
                  />
                </RuleSetGroup>
              );
            } else {
              return null;
            }
          } else {
            const { value } = rule;
            switch (value.type) {
              case 'separator': {
                return <Separator key={`separator-${i}`} />;
              }
              case 'hidden': {
                return null;
              }
              case 'checkbox': {
                const cur = rules.get(value.id)!;
                const onChange = this.updateHandlers.bind(
                  value.id,
                  this.handleChange,
                );
                const disabled =
                  value.disabled != null && value.disabled(ruleObject, true);
                return (
                  <CheckboxControl
                    key={`item-${value.id}`}
                    t={t}
                    item={value}
                    value={cur}
                    disabled={disabled}
                    onChange={onChange}
                  />
                );
              }
              case 'integer': {
                const cur = rules.get(value.id)!;
                const onChange = this.updateHandlers.bind(
                  value.id,
                  this.handleChange,
                );
                const disabled =
                  value.disabled != null && value.disabled(ruleObject, true);
                return (
                  <IntegerControl
                    key={`item-${value.id}`}
                    t={t}
                    item={value}
                    value={cur}
                    disabled={disabled}
                    onChange={onChange}
                  />
                );
              }
              case 'select': {
                const cur = rules.get(value.id)!;
                const onChange = this.updateHandlers.bind(
                  value.id,
                  this.handleChange,
                );
                const disabled =
                  value.disabled != null && value.disabled(ruleObject, true);
                return (
                  <SelectControl
                    key={`item-${value.id}`}
                    t={t}
                    item={value}
                    suggestion={suggestedOptions[value.id]}
                    value={cur}
                    disabled={disabled}
                    onChange={onChange}
                  />
                );
              }
              case 'time': {
                const cur = rules.get(value.id)!;
                const onChange = this.updateHandlers.bind(
                  value.id,
                  this.handleChange,
                );
                const disabled =
                  value.disabled != null && value.disabled(ruleObject, true);
                return (
                  <TimeControl
                    key={`item-${value.id}`}
                    t={t}
                    item={value}
                    value={cur}
                    disabled={disabled}
                    onChange={onChange}
                  />
                );
              }
            }
          }
        })}
      </>
    );
  }
  @bind
  protected handleChange(rule: string, value: string): void {
    this.props.onUpdate(rule, value);
  }
}
