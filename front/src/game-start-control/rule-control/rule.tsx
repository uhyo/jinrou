import * as React from 'react';
import styled from 'styled-components';

import {
    CheckboxRule,
    IntegerRule,
    SelectRule,
    TimeRule,
} from '../../defs/rule-definition';

import {
    TranslationFunction,
} from '../../i18n';

import {
    bind,
} from '../../util/bind';

import {
    getRuleName,
} from '../../logic/rule';

/**
 * Wrapper of rules.
 */
const RuleWrapper = styled.div`
    flex: 0 0 auto;

    margin: 4px;
    padding: 0;
    border: 1px solid rgba(0, 0, 0, 0.4);

    text-align: center;

    > label, > span {
        display: block;
        box-sizing: border-box;
        width: 100%;
        padding: 6px;
    }

    :hover {
        background-color: rgba(255, 255, 255, 0.35);
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
    item: CheckboxRule;
    value: string;
    onChange: (value: string)=> void;
}
/**
 * Show one control.
 */
export class CheckboxControl extends React.PureComponent<IPropCheckboxControl, {}> {
    public render() {
        const {
            t,
            item,
            value,
        } = this.props;

        const checked = value === item.value;
        const {name, label} = getRuleName(t, item.id);

        return (<RuleWrapper>
            <label title={label}>
                <RuleName>{name}</RuleName>
                <input
                    type='checkbox'
                    checked={checked}
                    onChange={this.handleChange}
                />
            </label>
        </RuleWrapper>);
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
    onChange: (value: string)=> void;
}
/**
 * Show integer control.
 */
export class IntegerControl extends React.PureComponent<IPropIntegerControl, {}> {
    public render() {
        const {
            t,
            item,
            value,
        } = this.props;

        const {name, label} = getRuleName(t, item.id);

        return (<RuleWrapper>
            <label title={label}>
                <RuleName>{name}</RuleName>
                <input
                    type='number'
                    value={value}
                    onChange={this.handleChange}
                />
            </label>
        </RuleWrapper>);
    }
    @bind
    protected handleChange(e: React.SyntheticEvent<HTMLInputElement>) {
        this.props.onChange(e.currentTarget.value);
    }
}

interface IPropSelectControl {
    t: TranslationFunction;
    item: SelectRule;
    value: string;
    onChange: (value: string)=> void;
}
/**
 * Show integer control.
 */
export class SelectControl extends React.PureComponent<IPropSelectControl, {}> {
    public render() {
        const {
            t,
            item,
            value,
        } = this.props;

        const {name, label} = getRuleName(t, item.id);

        return (<RuleWrapper>
            <label title={label}>
                <RuleName>{name}</RuleName>
                <select
                    value={value}
                    onChange={this.handleChange}
                >{
                    item.values.map((v)=> {
                        const label = t(`rules:rule.${item.id}.labels.${v}`);
                        const description = t(`rules:rule.${item.id}.descriptions.${v}`);
                        return (<option
                            key={v}
                            title={description}
                            value={v}
                        >{label}</option>);
                    })
                }</select>
            </label>
        </RuleWrapper>);
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
    onChange: (value: string)=> void;
}

/**
 * Show time control.
 */
export class TimeControl extends React.PureComponent<IPropTimeControl, {}> {
    protected minutes: HTMLInputElement | null = null;
    protected seconds: HTMLInputElement | null = null;
    public render() {
        const {
            t,
            item,
            value,
        } = this.props;

        const v = Number(value);
        const minutes = Math.floor(v / 60);
        const seconds = v % 60;

        const {name, label} = getRuleName(t, item.id);

        return (<RuleWrapper>
            <span title={label}>
                <RuleName>{name}</RuleName>
                <input
                    ref={i=> this.minutes=i}
                    type='number'
                    value={minutes}
                    min={0}
                    step={1}
                    onChange={this.handleChange}
                />
                {t('game_client:gamestart.control.minutes')}
                <input
                    ref={i=> this.seconds=i}
                    type='number'
                    value={seconds}
                    min={-1}
                    max={60}
                    step={1}
                    onChange={this.handleChange}
                />
                {t('game_client:gamestart.control.seconds')}
            </span>
        </RuleWrapper>);
    }
    @bind
    protected handleChange() {
        const minutes = this.minutes ? Number(this.minutes.value) : 0;
        const seconds = this.seconds ? Number(this.seconds.value) : 0;
        const value = minutes * 60 + seconds;
        this.props.onChange(String(value >= 0 ? value : 0));
    }
}

