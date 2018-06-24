import * as React from 'react';
import { observer } from 'mobx-react';
import { PlayerInfo } from '../defs';
import styled from 'styled-components';
import { PlayerBox } from './box';
import { I18n } from '../../i18n';

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
      <I18n>
        {t => (
          <Wrapper>
            {players.map(pl => <PlayerBox t={t} key={pl.id} player={pl} />)}
          </Wrapper>
        )}
      </I18n>
    );
  }
}

const Wrapper = styled.div``;
