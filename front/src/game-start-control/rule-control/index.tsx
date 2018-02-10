import * as React from 'react';
import {
    observer,
} from 'mobx-react';

import {
    RuleGroup,
} from '../../defs';
import {
    bind,
} from '../../util/bind';
import {
    CachedBinder,
} from '../../util/cached-binder';

import {
    CheckboxControl,
    IntegerControl,
    SelectControl,
    TimeControl,
    Separator,
} from './rule';
import {
    RuleSetGroup,
} from './group';

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
                    return (<RuleSetGroup
                        key={`group-${name}`}
                        name={name}
                    >
                        <RuleControl
                            ruledefs={rule.items}
                            rules={rules}
                            onUpdate={onUpdate}
                        />
                    </RuleSetGroup>)
                } else {
                    const {
                        value,
                    } = rule;
                    switch (value.type) {
                        case 'separator': {
                            return (<Separator />);
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

