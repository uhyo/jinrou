import * as React from 'react';
import {
    observer,
} from 'mobx-react';

import {
    RuleGroup,
} from '../defs';
import {
    CheckboxRule,
    IntegerRule,
    SelectRule,
    TimeRule,
} from '../defs/rule-definition';
import {
    bind,
} from '../util/bind';
import {
    CachedBinder,
} from '../util/cached-binder';

export interface IPropRuleControl {
    ruledefs: RuleGroup;
    rules: Map<string, string>;
    onUpdate: (rule: string, value: string)=> void;
}
/**
 * Interface of editing rules.
 */
@observer
export class RuleControl extends React.Component<IPropRuleControl, {}> {
    protected updateHandlers = new CachedBinder<string, string, void>();
    public render(): JSX.Element {
        const {
            ruledefs,
            rules,
            onUpdate,
        } = this.props;

        return (<>{
            ruledefs.map((rule)=> {
                if (rule.type === 'group') {
                    const {
                        name,
                    } = rule.label;
                    return (<fieldset key={`group-${name}`}>
                        <legend>{name}</legend>
                        <RuleControl
                            ruledefs={rule.items}
                            rules={rules}
                            onUpdate={onUpdate}
                        />
                    </fieldset>)
                } else {
                    const {
                        value,
                    } = rule;
                    switch (value.type) {
                        case 'separator': {
                            return null;
                        }
                        case 'hidden': {
                            return null;
                        }
                        case 'checkbox': {
                            const cur = rules.get(value.id)!;
                            const onChange = this.updateHandlers.bind(value.id, this.handleChange);
                            return (<CheckboxControl
                                key={`item-${value.id}`}
                                item={value}
                                value={cur}
                                onChange={onChange}
                            />);
                        }
                        case 'integer': {
                            const cur = rules.get(value.id)!;
                            const onChange = this.updateHandlers.bind(value.id, this.handleChange);
                            return (<IntegerControl
                                key={`item-${value.id}`}
                                item={value}
                                value={cur}
                                onChange={onChange}
                            />);
                        }
                        case 'select': {
                            const cur = rules.get(value.id)!;
                            const onChange = this.updateHandlers.bind(value.id, this.handleChange);
                            return (<SelectControl
                                key={`item-${value.id}`}
                                item={value}
                                value={cur}
                                onChange={onChange}
                            />);
                        }
                        case 'time': {
                            const cur = rules.get(value.id)!;
                            const onChange = this.updateHandlers.bind(value.id, this.handleChange);
                            return (<TimeControl
                                key={`item-${value.id}`}
                                item={value}
                                value={cur}
                                onChange={onChange}
                            />);
                        }
                    }
                }
            })
        }</>);
    }
    @bind
    protected handleChange(rule: string, value: string): void {
        this.props.onUpdate(rule, value);
    }
}

interface IPropCheckboxControl {
    item: CheckboxRule;
    value: string;
    onChange: (value: string)=> void;
}
/**
 * Show one control.
 */
class CheckboxControl extends React.PureComponent<IPropCheckboxControl, {}> {
    public render() {
        const {
            item,
            value,
        } = this.props;

        const checked = value === item.value.value;

        return (<label title={item.label}>
            {item.name}
            <input
                type='checkbox'
                checked={checked}
                onChange={this.handleChange}
            />
        </label>);
    }
    @bind
    protected handleChange(e: React.SyntheticEvent<HTMLInputElement>) {
        this.props.onChange(e.currentTarget.checked ? this.props.item.value.value : '');
    }
}

interface IPropIntegerControl {
    item: IntegerRule;
    value: string;
    onChange: (value: string)=> void;
}
/**
 * Show integer control.
 */
class IntegerControl extends React.PureComponent<IPropIntegerControl, {}> {
    public render() {
        const {
            item,
            value,
        } = this.props;

        return (<label title={item.label}>
            {item.name}
            <input
                type='number'
                value={value}
                onChange={this.handleChange}
            />
        </label>);
    }
    @bind
    protected handleChange(e: React.SyntheticEvent<HTMLInputElement>) {
        this.props.onChange(e.currentTarget.value);
    }
}

interface IPropSelectControl {
    item: SelectRule;
    value: string;
    onChange: (value: string)=> void;
}
/**
 * Show integer control.
 */
class SelectControl extends React.PureComponent<IPropSelectControl, {}> {
    public render() {
        const {
            item,
            value,
        } = this.props;

        return (<label>
            {item.name}
            <select
                title={item.label}
                value={value}
                onChange={this.handleChange}
            >{
                item.values.map((v)=> {
                    return (<option
                        key={v.value}
                        title={v.description}
                        label={v.label}
                        value={v.value}
                    />);
                })
            }</select>
        </label>);
    }
    @bind
    protected handleChange(e: React.SyntheticEvent<HTMLSelectElement>) {
        this.props.onChange(e.currentTarget.value);
    }
}
interface IPropTimeControl {
    item: TimeRule;
    value: string;
    onChange: (value: string)=> void;
}

/**
 * Show time control.
 */
class TimeControl extends React.PureComponent<IPropTimeControl, {}> {
    protected minutes: HTMLInputElement | null = null;
    protected seconds: HTMLInputElement | null = null;
    public render() {
        const {
            item,
            value,
        } = this.props;

        const v = Number(value);
        const minutes = Math.floor(v / 60);
        const seconds = v % 60;

        return (<>
            {item.name}
            <input
                ref={i=> this.minutes=i}
                type='number'
                value={minutes}
                min={0}
                step={1}
                onChange={this.handleChange}
            />
            分
            <input
                ref={i=> this.seconds=i}
                type='number'
                value={seconds}
                min={-1}
                max={60}
                step={1}
                onChange={this.handleChange}
            />
            秒
        </>);
    }
    @bind
    protected handleChange() {
        const minutes = this.minutes ? Number(this.minutes.value) : 0;
        const seconds = this.seconds ? Number(this.seconds.value) : 0;
        const value = minutes * 60 + seconds;
        this.props.onChange(String(value >= 0 ? value : 0));
    }
}
