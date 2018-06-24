import * as React from 'react';
import { observer } from 'mobx-react';
import { PlayerInfo } from '../defs';
import styled from 'styled-components';
import { PlayerBox } from './box';

export interface IPropPlayers {
  players: PlayerInfo[];
}
/**
 * Show a list of players.
 */
@observer
export class Players extends React.Component<IPropPlayers, {}> {
  public render() {
    const { players } = this.props;
    return (
      <Wrapper>
        {players.map(pl => <PlayerBox key={pl.id} player={pl} />)}
      </Wrapper>
    );
  }
}

const Wrapper = styled.div``;
