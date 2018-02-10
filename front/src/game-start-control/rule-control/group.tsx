import * as React from 'react';
import styled from 'styled-components';

export interface IPropRuleGroup {
    /**
     * class name passed by styled-components.
     */
    className?: string;
    /**
     * shown name of this group.
     */
    name: string;
}
/**
 * Wrapper of rule group.
 */
class RuleSetGroupInner extends React.PureComponent<IPropRuleGroup, {}> {
    public render() {
        const {
            children,
            className,
            name,
        } = this.props;
        return (<fieldset className={className}>
            <legend>{name}</legend>
            <div>
                {children}
            </div>
        </fieldset>);
    }
}

export const RuleSetGroup = styled(RuleSetGroupInner)`
    margin: 0 0.2em;
    border: none;
    border-top: 1px dashed rgba(0, 0, 0, 0.4);

    legend:not(:empty) {
        padding: 0 1ex;
    }

    > div {
        display: flex;
        flex-flow: row wrap;
        justify-content: flex-start;
    }
`;
