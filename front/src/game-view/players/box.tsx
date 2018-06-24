import * as React from 'react';
import { observer } from 'mobx-react';
import { PlayerInfo } from '../defs';
import styled from 'styled-components';
import { withProps } from '../../util/styled';
import { Icon } from './icon';
import { TranslationFunction } from 'i18next';

export interface IPropPlayerBox {
  t: TranslationFunction;
  player: PlayerInfo;
}
/**
 * A box which shows one player.
 */
@observer
export class PlayerBox extends React.Component<IPropPlayerBox, {}> {
  public render() {
    const {
      t,
      player: { id, icon, name, anonymous, dead, jobname, winner, flags },
    } = this.props;
    return (
      <Wrapper dead={dead} icon={icon != null}>
        <Icon t={t} icon={icon} dead={dead} />
        <Name dead={dead}>
          {anonymous ? name : <a href={`/user/${id}`}>{name}</a>}
        </Name>
        {flags.map(flag => (
          <Jobname>[{t(`game_client:playerbox.flags.${flag}`)}]</Jobname>
        ))}
        {jobname ? <Jobname>{jobname}</Jobname> : null}
        {winner != null ? (
          <Winner winner={winner}>
            {winner
              ? t('game_client:playerbox.win')
              : t('game_client:playerbox.lose')}
          </Winner>
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
  icon: boolean;
}>()(styled.div)`
  display: inline-block;
  min-width: ${props => (props.icon ? '8em' : '5em')};
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
