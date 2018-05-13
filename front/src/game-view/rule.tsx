import * as React from 'react';
import styled from 'styled-components';
import { I18n, TranslationFunction } from '../i18n';
import { RuleGroup } from '../defs';
import { RuleInfo } from './defs';

import { getRuleExpression } from '../logic/rule';

export interface IPropShowRule {
  /**
   * Current rule.
   */
  rule: RuleInfo;
  /**
   * Id of roles.
   */
  roles: string[];
  /**
   * Definition of rules.
   */
  ruleDefs: RuleGroup;
}
/**
 * Component which shows current rule.
 */
export class ShowRule extends React.PureComponent<IPropShowRule, {}> {
  public render() {
    const { roles, rule, ruleDefs } = this.props;
    return (
      <I18n>
        {t => (
          <>
            {rule.jobNumbers != null ? (
              <JobNumbers roles={roles} jobs={rule.jobNumbers} t={t} />
            ) : null}
            {rule.rule != null ? (
              <RuleItems items={ruleDefs} rule={rule.rule} t={t} />
            ) : null}
          </>
        )}
      </I18n>
    );
  }
}

/**
 * Show the number of jobs.
 */
class JobNumbers extends React.PureComponent<
  {
    roles: string[];
    jobs: Record<string, number>;
    t: TranslationFunction;
  },
  {}
> {
  public render() {
    const { roles, jobs, t } = this.props;
    return (
      <p>
        {roles.map(
          role =>
            jobs[role] > 0 ? (
              <>
                <a href={`/manual/job/${role}`}>
                  {t(`roles:jobname.${role}`)}
                  {jobs[role]}
                </a>{' '}
              </>
            ) : null,
        )}
      </p>
    );
  }
}

/**
 * Show value of each rule.
 */
class RuleItems extends React.PureComponent<
  {
    rule: Record<string, string>;
    items: RuleGroup;
    t: TranslationFunction;
  },
  {}
> {
  public render(): React.ReactNode {
    const { rule, items, t } = this.props;
    return items.map(item => {
      if (item.type === 'group') {
        // group of rule
        const groupdef = item.label;

        // TODO: check visibility of group

        return (
          <section key={`group-${groupdef.id}`}>
            <h1>{t(`rules:ruleGroup.${groupdef.id}.name`)}</h1>
            <RuleItems rule={rule} items={item.items} t={t} />
          </section>
        );
      } else {
        // TODO
        const ruledef = item.value;
        if (ruledef.type === 'separator' || ruledef.type === 'hidden') {
          // non-setting or hidden rule is not displayed
          return null;
        }
        const { label, value } = getRuleExpression(
          t,
          ruledef,
          rule[ruledef.id],
        );
        return value ? (
          <p>
            {label}: {value}
          </p>
        ) : null;
      }
    });
  }
}
