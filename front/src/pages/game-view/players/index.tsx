import * as React from 'react';
import { observer } from 'mobx-react';
import { PlayerInfo } from '../defs';
import styled from 'styled-components';
import { PlayerBox } from './box';
import { I18n, TranslationFunction } from '../../../i18n';
import { CachedBinder } from '../../../util/cached-binder';
import { bind } from 'bind-decorator';

export interface IPropPlayers {
  /**
   * List of players to show.
   */
  players: PlayerInfo[];
  /**
   * Callback for filtering specific player.
   */
  onFilter(userid: string): void;
}
/**
 * Show a list of players.
 */
export class Players extends React.Component<IPropPlayers, {}> {
  public render() {
    const { players, onFilter } = this.props;
    return (
      <I18n>
        {t => <PlayersInner t={t} players={players} onFilter={onFilter} />}
      </I18n>
    );
  }
}

/**
 * Inner component to apply mobx's observer.
 */
@observer
class PlayersInner extends React.Component<
  {
    t: TranslationFunction;
  } & IPropPlayers,
  {}
> {
  private filterHandlers = new CachedBinder<string, undefined>();
  public render() {
    const { t, players } = this.props;
    return (
      <Wrapper>
        {players.map(pl => {
          const filterHandler = this.filterHandlers.bind(
            pl.id,
            this.handleFilter,
          );
          return (
            <PlayerBox
              t={t}
              key={pl.id}
              player={pl}
              onEnableFilter={filterHandler}
            />
          );
        })}
      </Wrapper>
    );
  }
  @bind
  private handleFilter(userid: string): void {
    // filter is enabled for this player.
    this.props.onFilter(userid);
  }
}

const Wrapper = styled.div`
  display: flex;
  flex-flow: row wrap;
`;
