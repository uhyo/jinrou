import * as React from 'react';
import styled from '../util/styled';
import { WithSeparator } from '../util/with-separator';

import { RoleInfo, RolePeersInfo, RoleOtherPlayerInfo } from './defs';

import { I18nInterp, I18n } from '../i18n';

const Wrapper = styled.div`
  margin: 5px;
  padding: 8px;
  border: 2px dashed currentColor;
`;
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
];
/**
 * Keys of RoleOtherPlayerINfo for use in JobInfo.
 */
const otherPlayerKeys: Array<keyof RoleOtherPlayerInfo> = [
  'stalking',
  'dogOwner',
];

export interface IPropJobInfo extends RoleInfo {}

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
    } = this.props;
    return (
      <I18n namespace="game_client">
        {t => (
          <Wrapper>
            {/* Job Status. */}
            <p>
              <I18nInterp ns="game_client" k="jobinfo.status">
                {{
                  job: <b>{jobname}</b>,
                  details:
                    desc.length === 0
                      ? null
                      : [
                          ...mapJoin(desc, '・', (obj, idx) => (
                            <React.Fragment key={`${idx}-${obj.type}`}>
                              <a
                                href={`/manual/job/${
                                  obj.type
                                }?jobname=${encodeURIComponent(obj.name)}`}
                                data-jobname={obj.name}
                              >
                                {desc.length === 1
                                  ? t('jobinfo.detail_one')
                                  : t('jobinfo.detail', { job: obj.name })}
                              </a>
                            </React.Fragment>
                          )),
                        ],
                }}
              </I18nInterp>
            </p>
            {/* Team info when provided. */}
            {myteam != null ? (
              <p>
                {myteam === '' ? (
                  t('jobinfo.team.none')
                ) : (
                  <I18nInterp ns="game_client" k="jobinfo.team.message">
                    {{
                      team: (
                        <b>
                          <I18nInterp ns="roles" k={`teamName.${myteam}`} />
                        </b>
                      ),
                    }}
                  </I18nInterp>
                )}
              </p>
            ) : null}
            {/* Info of peers. */}
            {peers.map(key => {
              const pls = this.props[key];
              if (pls == null || pls.length === 0) {
                return null;
              }
              // If this field exists, list up name of players.
              const names = pls.map(({ id, name }) => <b key={id}>{name}</b>);
              return (
                <p key={`peers-${key}`}>
                  <I18nInterp ns="game_client" k={`jobinfo.peers.${key}`}>
                    {{
                      names: (
                        <WithSeparator separator="，">{names}</WithSeparator>
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
          </Wrapper>
        )}
      </I18n>
    );
  }
}

/**
 * map and join given array.
 */
function* mapJoin<T, U>(
  arr: T[],
  join: string,
  func: (elm: T, idx: number) => U,
): IterableIterator<U | string> {
  let idx = 0;
  for (const elm of arr) {
    if (idx > 0) {
      yield join;
    }
    yield func(elm, idx);
    idx++;
  }
}
