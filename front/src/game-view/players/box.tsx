import * as React from 'react';
import { observer } from 'mobx-react';
import { PlayerInfo } from '../defs';
import styled from 'styled-components';
import { withProps } from '../../util/styled';
import { Icon } from './icon';

export interface IPropPlayerBox {
  player: PlayerInfo;
}
/**
 * A box which shows one player.
 */
@observer
export class PlayerBox extends React.Component<IPropPlayerBox, {}> {
  public render() {
    const {
      player: { id, icon, name, anonymous, dead, jobname, winner },
    } = this.props;
    return (
      <Wrapper dead={dead}>
        <Icon icon={icon} dead={dead} />
        <Name dead={dead}>
          {anonymous ? name : <a href={`/user/${id}`}>{name}</a>}
        </Name>
        {jobname ? <Jobname>{jobname}</Jobname> : null}
        {winner != null ? (
          <Winner winner={winner}>{winner ? '勝利' : '敗北'}</Winner>
        ) : null}
      </Wrapper>
    );
  }
}

/**
 * Wrapper of player box.
 */
const Wrapper = withProps<{
  dead: boolean;
}>()(styled.div)`
  display: inline-block;
  min-width: 5em;
  min-height: 2em;
  vertical-align: top;

  background-color: ${props =>
    props.dead ? 'rgba(0, 0, 0, 0.1)' : 'transparent'};

  &:not(:first-child) {
    margin-left: 0.5em;
  }
`;

const Name = withProps<{ dead: boolean }>()(styled.span)`
  text-decoration: ${props => (props.dead ? 'line-through' : 'none')};
`;

const Jobname = styled.div`
  font-weight: bold;
`;

const Winner = withProps<{ winner: boolean }>()(styled.div)`
  font-weight: bold;
  color: ${props => (props.winner ? 'red' : 'blue')};
`;
