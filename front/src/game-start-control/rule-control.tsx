import * as React from 'react';
import {
    RuleGroup,
} from '../defs';
import {
} from '../util/labeled-group';

export interface IPropRuleControl {
    rules: RuleGroup;
}
/**
 * Interface of editing rules.
 */
export class RuleControl extends React.PureComponent<IPropRuleControl, {}> {
    public render(): JSX.Element {
        const {
            rules,
        } = this.props;

        return (<>{
            rules.map((rule)=> {
                console.log(rule);
                if (rule.type === 'group') {
                    const {
                        name,
                    } = rule.label;
                    return (<fieldset key={`group-${name}`}>
                        <legend>{name}</legend>
                        <RuleControl
                            rules={rule.items}
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
                        case 'checkbox': {
                            return (<label key={`item-${value.id}`}>
                                {value.name}
                                <input
                                    type='checkbox'
                                />
                            </label>);
                        }
                        case 'hidden': {
                            return (<input
                                key={`item-${value.id}`}
                                type='hidden'
                                name={value.id}
                            />);
                        }
                        case 'integer': {
                            return (<label
                                key={`item-${value.id}`}
                            >
                                {value.name}
                                <input
                                    type='number'
                                    step='1'
                                    min='0'
                                />
                            </label>);
                        }
                        case 'select': {
                            return (<label
                                key={`item-${value.id}`}
                            >
                                {value.name}
                                <select
                                    name={value.id}
                                    defaultValue={value.defaultValue}
                                >{
                                    value.values.map((v)=> {
                                        return (<option
                                            key={v.value}
                                        >
                                            {v.label}
                                            </option>);
                                    })
                                }</select>
                            </label>);
                        }
                        case 'time': {
                            return (<React.Fragment
                                key={`item-${value.id}`}
                            >
                                {value.name}
                                <input
                                    type='number'
                                    min='0'
                                    step='1'
                                />
                                分
                                <input
                                    type='number'
                                    min='0'
                                    step='1'
                                />
                                秒
                            </React.Fragment>);
                        }
                    }
                }
            })
        }</>);
    }
}
