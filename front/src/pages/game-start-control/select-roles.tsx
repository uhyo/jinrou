import * as React from 'react';
import { observer } from 'mobx-react';
import styled from '../../util/styled';

import { RoleCategoryDefinition } from '../../defs';
import { TranslationFunction } from '../../i18n';

import { bind } from '../../util/bind';
import { FontAwesomeIcon } from '../../util/icon';

const Wrapper = styled.dl``;
const CategoryTitle = styled.dt`
  display: block;
  margin: 0.2em;
  padding: 2px;
  background-color: rgba(255, 255, 255, 0.6);

  text-align: center;
  font-weight: bold;

  cursor: pointer;
`;
const JobsWrapper = styled.dd`
  display: flex;
  flex-flow: row wrap;
  justify-content: flex-start;
  margin: auto;
`;

export interface IPropSelectRoles {
  /**
   * Definition of role categories.
   */
  categories: RoleCategoryDefinition[];
  /**
   * Translation function.
   */
  t: TranslationFunction;
  /**
   * Current number of jobs.
   */
  jobNumbers: Record<string, number>;
  /**
   * Current inclusion state of jobs.
   */
  jobInclusions: Map<string, boolean>;
  /**
   * Current number of categories.
   */
  categoryNumbers: Map<string, number>;
  /**
   * Whether role exclusion is enabled.
   */
  roleExclusion: boolean;
  /**
   * Whether Human is filled by remaining numbers.
   */
  noFill: boolean;
  /**
   * Whether using category query.
   */
  useCategory: boolean;

  onUpdate(role: string, value: number, include: boolean): void;
  onCategoryUpdate(category: string, value: number): void;
}

/**
 * Interface to select role numbers.
 */
@observer
export class SelectRoles extends React.Component<IPropSelectRoles, {}> {
  protected updateMap: Map<
    string,
    (value: number, included: boolean) => void
  > = new Map();
  protected updateCategoryMap: Map<string, (value: number) => void> = new Map();

  public render() {
    const {
      categories,
      t,
      jobNumbers,
      jobInclusions,
      categoryNumbers,
      roleExclusion,
      noFill,
      useCategory,
    } = this.props;

    return (
      <Wrapper>
        {categories.map(({ id, roles }) => {
          return (
            <RoleCategoryFolder key={id} name={t(`roles:categoryName.${id}`)}>
              <JobsWrapper>
                {roles.map(role => {
                  const included = jobInclusions.get(role) || false;
                  const changeHandler = this.getChangeHandler(role);
                  return (
                    <RoleCounter
                      key={role}
                      role={role}
                      roleName={t(`roles:jobname.${role}`)}
                      helpLink={`/manual/job/${role}`}
                      editable={role !== 'Human' || noFill}
                      t={t}
                      roleExclusion={roleExclusion}
                      included={included}
                      value={jobNumbers[role] || 0}
                      onChange={changeHandler}
                    />
                  );
                })}
              </JobsWrapper>
            </RoleCategoryFolder>
          );
        })}
        {useCategory ? (
          <RoleCategoryFolder
            name={t('game_client:gamestart.control.categorySelection')}
          >
            <JobsWrapper>
              {categories.map(({ id }) => {
                const num = categoryNumbers.get(id) || 0;
                const changeHandler = this.getCategoryChangeHandler(id);
                return (
                  <RoleCounter
                    key={id}
                    t={t}
                    role="foo"
                    roleName={t(`roles:categoryName.${id}`)}
                    editable={true}
                    value={num}
                    included={true}
                    roleExclusion={false}
                    onChange={changeHandler}
                  />
                );
              })}
            </JobsWrapper>
          </RoleCategoryFolder>
        ) : null}
      </Wrapper>
    );
  }
  protected getChangeHandler(
    role: string,
  ): ((value: number, included: boolean) => void) {
    const v = this.updateMap.get(role);
    if (v != null) {
      return v;
    }
    const f = this.handleUpdate.bind(this, role);
    this.updateMap.set(role, f);
    return f;
  }
  protected getCategoryChangeHandler(cat: string): ((value: number) => void) {
    const v = this.updateCategoryMap.get(cat);
    if (v != null) {
      return v;
    }
    const f = this.handleCategoryUpdate.bind(this, cat);
    this.updateCategoryMap.set(cat, f);
    return f;
  }
  protected handleUpdate(role: string, value: number, included: boolean) {
    this.props.onUpdate(role, value, included);
  }
  protected handleCategoryUpdate(cat: string, value: number) {
    this.props.onCategoryUpdate(cat, value);
  }
}

interface IPropRoleCategoryFolder {
  name: string;
}
interface IStateRoleCategoryFolder {
  open: boolean;
}
class RoleCategoryFolder extends React.PureComponent<
  IPropRoleCategoryFolder,
  IStateRoleCategoryFolder
> {
  constructor(props: IPropRoleCategoryFolder) {
    super(props);

    this.state = {
      open: true,
    };
  }
  public render() {
    const {
      props: { children, name },
      state: { open },
    } = this;

    const icon = open ? 'folder-open' : 'folder';

    return (
      <>
        <CategoryTitle
          role="button"
          aria-expanded={open}
          onClick={this.handleClick}
        >
          <FontAwesomeIcon icon={icon} fixedWidth />
          {name}
        </CategoryTitle>
        <div hidden={!open}>{children}</div>
      </>
    );
  }
  @bind
  protected handleClick() {
    this.setState({
      open: !this.state.open,
    });
  }
}

interface IPropRoleWrapper {
  /**
   * State of this role.
   * active: value > 0,
   * inactive: value == 0.
   */
  status: 'active' | 'inactive' | 'excluded';
}

const RoleWrapper = styled.div<IPropRoleWrapper>`
  flex: 0 0 8.6em;
  margin: 0.25em;
  padding: 0.3em;

  display: flex;
  flex-flow: column nowrap;
  justify-content: space-between;

  background-color: ${({ status }) => {
    return status === 'active'
      ? 'rgba(255, 255, 255, 0.6)'
      : status === 'inactive'
        ? 'rgba(255, 255, 255, 0.3)'
        : 'rgba(255, 255, 255, 0.15)';
  }};

  b {
    display: flex;
    flex-flow: row nowrap;
    margin-bottom: 0.25em;
    color: ${({ status }) =>
      status === 'excluded' ? 'rgba(0, 0, 0, 0.4)' : 'inherit'};

    text-align: center;

    span {
      flex: 1 1 auto;
    }
  }
`;

interface IPropRoleCounter {
  /**
   * i18n function.
   */
  t: TranslationFunction;
  /**
   * The role which this component counts.
   */
  role: string;
  /**
   * Display name of this role.
   */
  roleName: string;
  /**
   * href of help icon.
   */
  helpLink?: string;
  /**
   * Whether this control is editable.
   */
  editable: boolean;
  /**
   * Whether role exclusion is enabled.
   */
  roleExclusion: boolean;
  /**
   * Number of this role.
   */
  value: number;
  /**
   * Whether this role is included by user.
   */
  included: boolean;
  /**
   * Change number of role.
   */
  onChange(value: number, included: boolean): void;
}

const RoleControls = styled.div`
  display: flex;

  button {
    border: none;
    margin: 0 0.2em;
    padding: 2px;

    background: transparent;
    font-size: 1.05em;
    color: rgba(0, 0, 0, 0.6);
    cursor: pointer;
  }
`;

const NumberWrap = styled.span`
  flex: 1 0 2.8em;
  padding: 0 1ex;

  input {
    box-sizing: border-box;
    width: 100%;
  }
`;
class RoleCounter extends React.PureComponent<IPropRoleCounter, {}> {
  public render() {
    const {
      role,
      roleName,
      helpLink,
      editable,
      roleExclusion,
      t,
      value,
      included,
      onChange,
    } = this.props;

    // Checkbox for exclusion.
    const exclusion = roleExclusion ? (
      <input
        type="checkbox"
        checked={included}
        onChange={this.handleExclusionCheck}
      />
    ) : null;

    const roleStatus = included
      ? value > 0
        ? 'active'
        : 'inactive'
      : 'excluded';

    return (
      <RoleWrapper status={roleStatus}>
        <b>
          <span>{roleName}</span>
          {helpLink != null ? (
            <a href={helpLink}>
              <FontAwesomeIcon icon={['far', 'question-circle']} />
            </a>
          ) : null}
        </b>
        <RoleControls>
          {!editable ? (
            // Just display computed number for Human
            <span>{value}</span>
          ) : (
            <>
              {exclusion}
              <NumberWrap>
                <input
                  type="number"
                  value={value}
                  min={0}
                  step={1}
                  onChange={this.handleNumberChange}
                />
              </NumberWrap>
              {/* +1 button */}
              <button onClick={this.handlePlusButton}>
                <FontAwesomeIcon icon="plus-square" />
              </button>
              {/* -1 button */}
              <button onClick={this.handleMinusButton}>
                <FontAwesomeIcon icon="minus-square" />
              </button>
            </>
          )}
        </RoleControls>
      </RoleWrapper>
    );
  }
  /**
   * Handler of input change event.
   */
  @bind
  protected handleNumberChange(
    e: React.SyntheticEvent<HTMLInputElement>,
  ): void {
    const { onChange, included } = this.props;
    this.props.onChange(Number(e.currentTarget.value), included);
  }
  /**
   * Handler of clicking of plus button.
   */
  @bind
  protected handlePlusButton(): void {
    const { onChange, value, included } = this.props;
    onChange(value + 1, included);
  }
  /**
   * Handler of clicking of minus button.
   */
  @bind
  protected handleMinusButton(): void {
    const { onChange, value, included } = this.props;
    if (value > 0) {
      onChange(value - 1, included);
    }
  }
  /**
   * Handler of changing role inclusion check.
   */
  @bind
  protected handleExclusionCheck(
    e: React.SyntheticEvent<HTMLInputElement>,
  ): void {
    const { onChange, value } = this.props;
    onChange(value, e.currentTarget.checked);
  }
}
