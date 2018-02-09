import * as React from 'react';
import {
    observer,
} from 'mobx-react';
import styled, {
    StyledFunction,
} from 'styled-components';

import {
    RoleCategoryDefinition,
} from '../defs';
import {
    TranslationFunction,
} from '../i18n';

import {
    bind,
} from '../util/bind';
import {
    FontAwesomeIcon,
} from '../util/icon';
import {
    withProps,
} from '../util/styled';

const Wrapper = styled.dl`
`;
const CategoryTitle = styled.dt`
    display: block;
    margin: 0.2em;
    padding: 2px;
    background-color: rgba(255, 255, 255, 0.6);

    text-align: center;
    font-weight: bold;
`;
const JobsWrapper = styled.dd`
    display: flex;
    flex-flow: row wrap;
    justify-content: flex-start;
    margin: auto;
`;

export interface IPropSelectRoles {
    categories: RoleCategoryDefinition[];
    t: TranslationFunction;
    jobNumbers: Record<string, number>;
    jobInclusions: Map<string, boolean>;
    roleExclusion: boolean;
    noFill: boolean;
    onUpdate(role: string, value: number, include: boolean): void;
}

/**
 * Interface to select role numbers.
 */
@observer
export class SelectRoles extends React.PureComponent<IPropSelectRoles, {}> {
    protected updateMap: Map<string, (value: number, included: boolean)=> void> = new Map();

    public render() {
        const {
            categories,
            t,
            jobNumbers,
            jobInclusions,
            roleExclusion,
            noFill,
            onUpdate,
        } = this.props;

        return (<Wrapper>{
            categories.map(({
                id,
                roles,
            })=> {
                return (<React.Fragment key={id}>
                    <CategoryTitle key={id}>
                        {t(`roles:categoryName.${id}`)}
                    </CategoryTitle>
                    <JobsWrapper>
                        {
                            roles.map((role)=> {
                                const included = jobInclusions.get(role) || false;
                                const changeHandler = this.getChangeHandler(role);
                                return (<RoleCounter
                                    key={role}
                                    role={role}
                                    t={t}
                                    roleExclusion={roleExclusion}
                                    noFill={noFill}
                                    included={included}
                                    value={jobNumbers[role] || 0}
                                    onChange={changeHandler}
                                />);
                            })
                        }
                    </JobsWrapper>
                </React.Fragment>);
            })
        }</Wrapper>);
    }
    protected getChangeHandler(role: string): ((value: number, included: boolean)=>void) {
        const v = this.updateMap.get(role);
        if (v != null) {
            return v;
        }
        const f = this.handleUpdate.bind(this, role);
        this.updateMap.set(role, f);
        return f;
    }
    protected handleUpdate(role: string, value: number, included: boolean) {
        this.props.onUpdate(role, value, included);
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

const RoleWrapper = withProps<IPropRoleWrapper>()(styled.div)`
    flex: 0 0 8.6em;
    margin: 0.25em;
    padding: 0.3em;

    display: flex;
    flex-flow: column nowrap;
    justify-content: space-between;

    background-color: ${({status})=> {
        return (
            status === 'active' ?
            'rgba(255, 255, 255, 0.6)' :
            status === 'inactive' ?
            'rgba(255, 255, 255, 0.3)' :
            'rgba(255, 255, 255, 0.15)'
        )}};

    b {
        display: flex;
        flex-flow: row nowrap;
        margin-bottom: 0.25em;
        color: ${({status})=> status === 'excluded' ? 'rgba(0, 0, 0, 0.4)' : 'inherit'};

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
     * Number of this role.
     */
    value: number;
    /**
     * Whether this role is included by user.
     */
    included: boolean;
    /**
     * Whether role exclusion is enabled.
     */
    roleExclusion: boolean;
    /**
     * Whether Human filling is disabled/
     */
    noFill: boolean;
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
            t,
            value,
            included,
            roleExclusion,
            noFill,
            onChange,
        } = this.props;

        console.log('render', role, included);

        const roleName = t(`roles:jobname.${role}`);

        // Checkbox for exclusion.
        const exclusion =
            roleExclusion ?
            <input
                type='checkbox'
                checked={included}
                onChange={this.handleExclusionCheck}
            /> :
            null;

        const roleStatus =
            included ?
            (value > 0 ? 'active' : 'inactive') :
            'excluded';

        return (<RoleWrapper status={roleStatus}>
            <b>
                <span>{roleName}</span>
                <a href={`/manual/job/${role}`}>
                    <FontAwesomeIcon icon={['far', 'question-circle']} />
                </a>
            </b>
            <RoleControls>
                {
                    role === 'Human' && !noFill ?
                    // Just display computed number for Human
                    (<span>{value}</span>) :
                    (<>
                        {exclusion}
                        <NumberWrap>
                            <input
                                type='number'
                                value={value}
                                min={0}
                                step={1}
                                onChange={this.handleNumberChange}
                            />
                        </NumberWrap>
                        {/* +1 button */}
                        <button
                            onClick={this.handlePlusButton}
                        >
                            <FontAwesomeIcon icon='plus-square' />
                        </button>
                        {/* -1 button */}
                        <button
                            onClick={this.handleMinusButton}
                        >
                            <FontAwesomeIcon icon='minus-square' />
                        </button>
                </>)
                }
            </RoleControls>
        </RoleWrapper>);
    }
    /**
     * Handler of input change event.
     */
    @bind
    protected handleNumberChange(e: React.SyntheticEvent<HTMLInputElement>): void {
        const {
            onChange,
            included,
        } = this.props;
        this.props.onChange(Number(e.currentTarget.value), included);
    }
    /**
     * Handler of clicking of plus button.
     */
    @bind
    protected handlePlusButton(): void {
        const {
            onChange,
            value,
            included,
        } = this.props;
        onChange(value+1, included);
    }
    /**
     * Handler of clicking of minus button.
     */
    @bind
    protected handleMinusButton(): void {
        const {
            onChange,
            value,
            included,
        } = this.props;
        if (value > 0) {
            onChange(value-1, included);
        }
    }
    /**
     * Handler of changing role inclusion check.
     */
    @bind
    protected handleExclusionCheck(e: React.SyntheticEvent<HTMLInputElement>): void {
        const {
            onChange,
            value,
        } = this.props;
        onChange(value, e.currentTarget.checked);
    }

}
