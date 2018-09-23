import * as React from 'react';
import styled from 'styled-components';

import { FontAwesomeIcon } from '../../../util/icon';
import { bind } from '../../../util/bind';

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
export interface IStateRuleGroup {
  /**
   * Whether this group is open.
   */
  open: boolean;
}

/**
 * Wrapper of rule group.
 */
class RuleSetGroupInner extends React.PureComponent<
  IPropRuleGroup,
  IStateRuleGroup
> {
  constructor(props: IPropRuleGroup) {
    super(props);
    this.state = {
      open: true,
    };
  }
  public render() {
    const { children, className, name } = this.props;
    const { open } = this.state;
    return (
      <fieldset className={className}>
        <legend role="button" aria-expanded={open} onClick={this.handleClick}>
          <FontAwesomeIcon fixedWidth icon={open ? 'folder-open' : 'folder'} />
          {name}
        </legend>
        <div hidden={!open} style={{ display: open ? undefined : 'none' }}>
          {children}
        </div>
      </fieldset>
    );
  }
  @bind
  protected handleClick() {
    this.setState({
      open: !this.state.open,
    });
  }
}

export const RuleSetGroup = styled(RuleSetGroupInner)`
  margin: 0 0.2em;
  border: none;
  border-top: 1px dashed rgba(0, 0, 0, 0.4);

  > legend:not(:empty) {
    padding: 0 1ex;

    cursor: pointer;
  }

  > div {
    display: flex;
    flex-flow: row wrap;
    justify-content: flex-start;
  }
`;
