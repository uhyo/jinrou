import * as React from 'react';
import { WithSeparator } from '../../../util/with-separator';

import {
  RoleInfo,
  RolePeersInfo,
  RoleOtherPlayerInfo,
  TimerInfo,
  PlayerInfo,
} from '../defs';

import { I18nInterp, I18n, TranslationFunction } from '../../../i18n';
import { JobStatus } from './job-status';
import { Wrapper } from './wrapper';
import { Timer } from './timer';
import { RoleInfoPart, GameInfoPart, JobInfoButton } from './elements';
import { SensitiveButton } from '../../../util/sensitive-button';
import { FontAwesomeIcon } from '../../../util/icon';
import { bind } from 'bind-decorator';

/**
 * Keys of RolePeersInfo for use in JobInfo.
 */
const peers: Array<keyof RolePeersInfo> = [
  'wolves',
  'peers',
  'madpeers',
  'foxes',
  'nobles',
  'queens',
  'spy2s',
  'friends',
  'cultmembers',
  'vampires',
  'twins',
  'myfans',
  'ravens',
];
/**
 * Keys of RoleOtherPlayerINfo for use in JobInfo.
 */
const otherPlayerKeys: Array<keyof RoleOtherPlayerInfo> = [
  'stalking',
  'dogOwner',
  'fanof',
];

export interface IPropJobInfo {
  /**
   * Role-related info.
   */
  roleInfo: RoleInfo | null;
  /**
   * Timer info.
   */
  timer: TimerInfo;
  /**
   * List of players to show.
   */
  players: PlayerInfo[];
}

/**
 * Player's information.
 */
export class JobInfo extends React.PureComponent<
  IPropJobInfo,
  {
    /**
     * Whether full information is open,
     * only effective on phone UI.
     */
    fullOpen: boolean;
  }
> {
  state = {
    fullOpen: true,
  };
  public render() {
    const { roleInfo, timer, players } = this.props;
    const { fullOpen } = this.state;

    // count alive and dead players.
    const aliveNum = players.filter(pl => !pl.dead).length;
    const deadNum = players.filter(pl => pl.dead).length;

    // team of player, or undefined if not available.
    const myteam = roleInfo != null ? roleInfo.myteam : undefined;

    return (
      <I18n namespace="game_client">
        {t => {
          return (
            <Wrapper t={t} team={myteam} slim={!fullOpen}>
              {roleInfo != null ? (
                <RoleInfoPart hidden={!fullOpen}>
                  <RoleInfoInner t={t} roleInfo={roleInfo} />
                </RoleInfoPart>
              ) : null}
              <GameInfoPart>
                {/* Show alive/dead player number. */}
                <p>
                  {t('game_client:playerbox.aliveNum', { count: aliveNum })} /{' '}
                  {t('game_client:playerbox.deadNum', { count: deadNum })}
                </p>
                {/* timer. */}
                <p>
                  <Timer timer={timer} />
                </p>
                <JobInfoButton hidden={roleInfo == null}>
                  <SensitiveButton onClick={this.handleFullClick}>
                    <FontAwesomeIcon
                      icon={fullOpen ? 'caret-square-up' : 'caret-square-down'}
                    />
                  </SensitiveButton>
                </JobInfoButton>
              </GameInfoPart>
            </Wrapper>
          );
        }}
      </I18n>
    );
  }
  @bind
  private handleFullClick() {
    this.setState(({ fullOpen }) => ({ fullOpen: !fullOpen }));
  }
}

/**
 * Component to show given RoleInfo.
 */
const RoleInfoInner = ({
  t,
  roleInfo,
}: {
  t: TranslationFunction;
  roleInfo: RoleInfo;
}) => {
  const { jobname, desc, win, quantumwerewolf_number, supporting } = roleInfo;
  return (
    <>
      <JobStatus t={t} jobname={jobname} desc={desc} />
      {supporting == null ? null : (
        <p>
          <I18nInterp ns="game_client" k="jobinfo.peers.supporting">
            {{
              name: <b>{supporting.name}</b>,
              job: <b>{supporting.supportingJob}</b>,
            }}
          </I18nInterp>
        </p>
      )}
      {/* Info of peers. */}
      {peers.map(key => {
        const pls = roleInfo[key];
        if (pls == null || pls.length === 0) {
          return null;
        }
        // If this field exists, list up name of players.
        const names = pls.map(({ name }, i) => <b key={i}>{name}</b>);
        return (
          <p key={`peers-${key}`}>
            <I18nInterp ns="game_client" k={`jobinfo.peers.${key}`}>
              {{
                names: <WithSeparator separator="，">{names}</WithSeparator>,
              }}
            </I18nInterp>
          </p>
        );
      })}
      {otherPlayerKeys.map(key => {
        const pl = roleInfo[key];
        if (pl == null) {
          return;
        }
        return (
          <p key={`otherPlayer-${key}`}>
            <I18nInterp ns="game_client" k={`jobinfo.peers.${key}`}>
              {{
                name: <b>{pl.name}</b>,
              }}
            </I18nInterp>
          </p>
        );
      })}
      {/* Handling of special peer info. */}
      {quantumwerewolf_number == null ? null : (
        <p>
          <I18nInterp ns="game_client" k="jobinfo.peers.quantumwerewolfNumber">
            {{
              number: quantumwerewolf_number,
            }}
          </I18nInterp>
        </p>
      )}
      {/* Victory or defeat. */}
      {win === true ? (
        <p>
          <I18nInterp ns="game_client" k="jobinfo.win" />
        </p>
      ) : win === false ? (
        <p>
          <I18nInterp ns="game_client" k="jobinfo.lose" />
        </p>
      ) : null}
    </>
  );
};
