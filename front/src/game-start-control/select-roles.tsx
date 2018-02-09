import * as React from 'react';
import styled from 'styled-components';

import {
    RoleCategoryDefinition,
} from '../defs';
import {
    TranslationFunction,
} from '../i18n';

import {
    FontAwesomeIcon,
} from '../util/icon';

export interface IPropSelectRoles {
    categories: RoleCategoryDefinition[];
    t: TranslationFunction;
    jobNumbers: Record<string, number>;
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
export function SelectRoles({
    categories,
    t,
    jobNumbers,
    onUpdate,
}: IPropSelectRoles) {
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
                            return (<RoleCounter
                                key={role}
                                role={role}
                                t={t}
                                value={jobNumbers[role] || 0}
                                onChange={onUpdate.bind(null, role)}
                                />);
                        })
                    }
                </JobsWrapper>
            </React.Fragment>);
        })
    }</Wrapper>);
}

interface IPropRoleCounter {
    role: string;
    t: TranslationFunction;
    value: number;
    onChange(value: number): void;
}

const RoleWrapper = styled.div`
    flex: 0 0 8.6em;
    margin: 0.25em;
    padding: 0.3em;

    display: flex;
    flex-flow: column nowrap;
    justify-content: space-between;

    background-color: rgba(255, 255, 255, 0.3);

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
function RoleCounter({
    role,
    t,
    value,
    onChange,
}: IPropRoleCounter) {
    const roleName = t(`roles:jobname.${role}`);

    // value less than 0 is error.
    const RW =
        value >= 0 ? RoleWrapper : ErrorRoleWrapper;

    return (<RW>
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
                    <NumberWrap>
                        <input
                            type='number'
                            value={value}
                            min={0}
                            step={1}
                            onChange={(e)=>{ onChange(Number(e.currentTarget.value)) }}
                        />
                    </NumberWrap>
                    {/* +1 button */}
                    <button
                        onClick={()=> {
                            onChange(value+1);
                        }}
                    >
                        <FontAwesomeIcon icon='plus-square' />
                    </button>
                    {/* -1 button */}
                    <button
                        onClick={()=> {
                            if (value > 0) {
                                onChange(value-1);
                            }
                        }}
                    >
                        <FontAwesomeIcon icon='minus-square' />
                    </button>
            </>)
            }
        </RoleControls>
    </RW>);
}
