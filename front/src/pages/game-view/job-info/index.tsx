import * as React from 'react';
import { WithSeparator } from '../../../util/with-separator';

import {
  RoleInfo,
  RolePeersInfo,
  RoleOtherPlayerInfo,
  TimerInfo,
} from '../defs';

import { I18nInterp, I18n } from '../../../i18n';
import { JobStatus } from './job-status';
import { Wrapper } from './wrapper';
import { Timer } from './timer';
import { RoleInfoPart, GameInfoPart } from './elements';

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

export interface IPropJobInfo extends RoleInfo {
  /**
   * Timer info.
   */
  timer: TimerInfo;
}

/**
 * Player's information.
 */
export class JobInfo extends React.PureComponent<IPropJobInfo, {}> {
  public render() {
    const {
      jobname,
      desc,
      win,
      myteam,
      quantumwerewolf_number,
      supporting,
      timer,
    } = this.props;

    return (
      <I18n namespace="game_client">
        {t => {
          return (
            <Wrapper t={t} team={myteam}>
              <RoleInfoPart>
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
                  const pls = this.props[key];
                  if (pls == null || pls.length === 0) {
                    return null;
                  }
                  // If this field exists, list up name of players.
                  const names = pls.map(({ name }, i) => <b key={i}>{name}</b>);
                  return (
                    <p key={`peers-${key}`}>
                      <I18nInterp ns="game_client" k={`jobinfo.peers.${key}`}>
                        {{
                          names: (
                            <WithSeparator separator="，">
                              {names}
                            </WithSeparator>
                          ),
                        }}
                      </I18nInterp>
                    </p>
                  );
                })}
                {otherPlayerKeys.map(key => {
                  const pl = this.props[key];
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
                    <I18nInterp
                      ns="game_client"
                      k="jobinfo.peers.quantumwerewolfNumber"
                    >
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
              </RoleInfoPart>
              <GameInfoPart>
                {/* (TMP) timer. */}
                <Timer timer={timer} />
              </GameInfoPart>
            </Wrapper>
          );
        }}
      </I18n>
    );
  }
}
