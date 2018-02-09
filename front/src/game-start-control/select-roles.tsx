import * as React from 'react';
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

export interface IPropSelectRoles {
    categories: RoleCategoryDefinition[];
    t: TranslationFunction;
    jobNumbers: Record<string, number>;
    jobInclusions: Map<string, boolean>;
    roleExclusion: boolean;
    onUpdate(role: string, value: number): void;
}

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

/**
 * Interface to select role numbers.
 */
export class SelectRoles extends React.PureComponent<IPropSelectRoles, {}> {
    protected updateMap: Map<string, (value: number)=> void> = new Map();

    public render() {
        const {
            categories,
            t,
            jobNumbers,
            jobInclusions,
            roleExclusion,
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
    protected getChangeHandler(role: string): ((value: number)=>void) {
        const v = this.updateMap.get(role);
        if (v != null) {
            return v;
        }
        const f = this.handleUpdate.bind(this, role);
        this.updateMap.set(role, f);
        return f;
    }
    protected handleUpdate(role: string, value: number) {
        this.props.onUpdate(role, value);
    }
}

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
    onChange(value: number): void;
}

interface IPropRoleWrapper {
    active: boolean;
}

const RoleWrapper = withProps<IPropRoleWrapper>()(styled.div)`
    flex: 0 0 8.6em;
    margin: 0.25em;
    padding: 0.3em;

    display: flex;
    flex-flow: column nowrap;
    justify-content: space-between;

    background-color: ${props=> props.active ? 'rgba(255, 255, 255, 0.6)' : 'rgba(255, 255, 255, 0.3)'};

    b {
        display: flex;
        flex-flow: row nowrap;
        margin-bottom: 0.25em;

        text-align: center;

        span {
            flex: 1 1 auto;
        }
    }
`;
const ErrorRoleWrapper = styled(RoleWrapper)`
    background-color: rgba(255, 96, 96, 0.5);
`;
const ActiveRoleWrapper = styled(RoleWrapper)`
    background-color: rgba(255, 255, 255, 0.6);
`;

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
            onChange,
        } = this.props;

        console.log('render', role);

        const roleName = t(`roles:jobname.${role}`);

        // value less than 0 is error.
        const RW =
            value > 0 ?
            ActiveRoleWrapper :
            RoleWrapper;

        // Checkbox for exclusion.
        const exclusion =
            roleExclusion ?
            <input
                type='checkbox'
                checked={included}
            /> :
            null;

        return (<RoleWrapper active={value > 0}>
            <b>
                <span>{roleName}</span>
                <a href={`/manual/job/${role}`}>
                    <FontAwesomeIcon icon={['far', 'question-circle']} />
                </a>
            </b>
            <RoleControls>
                {
                    role === 'Human' ?
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
        this.props.onChange(Number(e.currentTarget.value));
    }
    /**
     * Handler of clicking of plus button.
     */
    @bind
    protected handlePlusButton(): void {
        this.props.onChange(this.props.value+1);
    }
    /**
     * Handler of clicking of minus button.
     */
    @bind
    protected handleMinusButton(): void {
        const {
            onChange,
            value,
        } = this.props;
        if (value > 0) {
            onChange(value-1);
        }
    }
}
