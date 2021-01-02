import { observer } from 'mobx-react';
import * as React from 'react';
import styled, { ThemeProvider } from '../../util/styled';
import { themeStore } from '../../theme';

import { WideButton } from '../../common/button';
import { showConfirmDialog, showMessageDialog } from '../../dialog';
import {
  CastingDefinition,
  LabeledGroup,
  RoleCategoryDefinition,
  RuleGroup,
} from '../../defs';
import { bind } from '../../util/bind';
import {
  SelectLabeledGroup,
  IPropSelectLabeledGroup,
} from '../../util/labeled-group';
import { ReactCtor } from '../../util/react-type';

import { JobsString, PlayerNumberError } from './jobs-string';
import { gameStart } from './logic';
import { RuleControl } from './rule-control';
import { SelectRoles } from './select-roles';
import { CastingStore } from './store';

import { i18n, I18n, I18nProvider } from '../../i18n';
import { AppStyling } from '../../styles/phone';

const StatusLine = styled.div`
  position: sticky;
  top: 0;

  padding: 0.3em;
  background-color: ${props => props.theme.user.day.bg || 'transparent'};
`;

interface IPropCasting {
  /**
   * i18n instance.
   */
  i18n: i18n;
  /**
   * store.
   */
  store: CastingStore;
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
   * Categories including hidden roles.
   */
  allCategories: RoleCategoryDefinition[];
  /**
   * Definition of rules.
   */
  ruledefs: RuleGroup;
  /**
   * Event of pressing gamestart button.
   */
  onStart: (query: Record<string, string>) => void;
}

@observer
export class Casting extends React.Component<IPropCasting, {}> {
  public render() {
    const {
      i18n,
      store,
      roles,
      castings,
      categories,
      allCategories,
      ruledefs,
    } = this.props;
    const {
      playersNumber,
      currentCasting,
      jobNumbers,
      jobInclusions,
      categoryNumbers,
      ruleObject,
    } = store;

    // Check whether current number of players is admissible.
    const { min = undefined, max = undefined } =
      currentCasting.suggestedPlayersNumber || {};
    const minReq = Math.max(min || -Infinity, store.requiredPlayersNumber);

    // Specialized generic component.
    const SLG: ReactCtor<
      IPropSelectLabeledGroup<CastingDefinition, string>,
      {}
    > = SelectLabeledGroup;

    // XXX some of themes are not provided!
    const theme = {
      user: themeStore.themeObject,
      teamColors: {},
    };

    return (
      <ThemeProvider theme={theme} mode={null}>
        <I18nProvider i18n={i18n}>
          <I18n namespace="game_client">
            {t => {
              // status line indicating jobs.
              const warning =
                max && max < playersNumber ? (
                  <p>
                    <PlayerNumberError t={t} maxNumber={max} />
                  </p>
                ) : minReq > playersNumber ? (
                  <p>
                    <PlayerNumberError t={t} minNumber={minReq} />
                  </p>
                ) : null;
              // name of this casting.
              const castingName = t(
                `casting:castingName.${store.currentCasting.id}`,
              );
              const castingTitle = t(
                `casting:castingTitle.${store.currentCasting.id}`,
              );
              return (
                <Wrapper>
                  <StatusLine>
                    {t('gamestart.info.playerNumber', { count: playersNumber })}
                    {' - '}
                    {castingName}
                    {store.currentCasting.noShow ? null : (
                      <>
                        {' / '}
                        <JobsString
                          t={t}
                          i18n={i18n}
                          jobNumbers={jobNumbers}
                          categoryNumbers={categoryNumbers}
                          roles={roles}
                          categories={allCategories}
                        />
                      </>
                    )}
                    {warning}
                  </StatusLine>
                  <fieldset>
                    <legend>{t('gamestart.control.roles')}</legend>

                    <p>
                      <SLG
                        items={castings}
                        value={currentCasting.id}
                        getGroupLabel={(x: string) => ({
                          key: x,
                          label: t(`casting:castingGroupName.${x}._name`),
                        })}
                        getOptionKey={({ id }: CastingDefinition) => id}
                        makeOption={(obj: CastingDefinition) => {
                          return (
                            <option
                              value={obj.id}
                              title={t(`casting:castingTitle.${obj.id}`)}
                            >
                              {t(`casting:castingName.${obj.id}`)}
                            </option>
                          );
                        }}
                        onChange={this.handleCastingChange}
                      />
                      {'　'}
                      <b>{castingName}</b>: {castingTitle}
                    </p>
                    {currentCasting.roleSelect ? (
                      <SelectRoles
                        categories={categories}
                        t={t}
                        jobNumbers={jobNumbers}
                        jobInclusions={jobInclusions}
                        categoryNumbers={categoryNumbers}
                        roleExclusion={currentCasting.roleExclusion || false}
                        noFill={currentCasting.noFill || false}
                        useCategory={currentCasting.category || false}
                        onUpdate={this.handleJobUpdate}
                        onCategoryUpdate={this.handleCategoryUpdate}
                      />
                    ) : null}
                  </fieldset>
                  {/* Controls for rules. */}
                  <fieldset>
                    <legend>{t('gamestart.control.rules')}</legend>
                    <RuleControl
                      t={t}
                      ruledefs={ruledefs}
                      ruleObject={ruleObject}
                      suggestedOptions={currentCasting.suggestedOptions}
                      onUpdate={this.handleRuleUpdate}
                    />
                  </fieldset>
                  {/* Game start button */}
                  <div>
                    <WideButton onClick={this.handleGameStart}>
                      {t('gamestart.control.start')}
                    </WideButton>
                  </div>
                </Wrapper>
              );
            }}
          </I18n>
        </I18nProvider>
      </ThemeProvider>
    );
  }
  public componentDidCatch(err: any) {
    console.error(err);
  }
  @bind
  protected handleCastingChange(value: CastingDefinition): void {
    this.props.store.setCurrentCasting(value);
  }
  @bind
  protected handleJobUpdate(
    role: string,
    value: number,
    included: boolean,
  ): void {
    this.props.store.updateJobNumber(role, value, included);
  }
  @bind
  protected handleCategoryUpdate(cat: string, value: number): void {
    this.props.store.updateCategoryNumber(cat, value);
  }
  @bind
  protected handleRuleUpdate(rule: string, value: string): void {
    this.props.store.updateRule(rule, value);
  }
  @bind
  protected async handleGameStart(): Promise<void> {
    const { i18n, roles, categories, ruledefs, store, onStart } = this.props;
    const query = await gameStart({
      i18n: this.props.i18n,
      roles,
      categories,
      ruledefs,
      store,
    });

    if (query != null) {
      onStart(query);
    }
  }
}

const Wrapper = styled(AppStyling)`
  margin-bottom: 1.2em;
`;
