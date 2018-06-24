import * as React from 'react';
import { observer } from 'mobx-react';
import { PlayerInfo } from '../defs';
import styled from 'styled-components';
import { PlayerBox } from './box';
import { I18n, TranslationFunction } from '../../i18n';

export interface IPropPlayers {
  players: PlayerInfo[];
}
/**
 * Show a list of players.
 */
export class Players extends React.Component<IPropPlayers, {}> {
  public render() {
    const { players } = this.props;
    return <I18n>{t => <PlayersInner t={t} players={players} />}</I18n>;
  }
}

/**
 * Inner component to apply mobx's observer.
 */
@observer
class PlayersInner extends React.Component<
  {
    t: TranslationFunction;
    players: PlayerInfo[];
  },
  {}
> {
  public render() {
    const { t, players } = this.props;
    return (
      <Wrapper>
        {players.map(pl => <PlayerBox t={t} key={pl.id} player={pl} />)}
      </Wrapper>
    );
  }
}

const Wrapper = styled.div``;
