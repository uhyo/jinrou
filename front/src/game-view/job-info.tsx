import * as React from 'react';
import styled from '../util/styled';

import { RoleInfo } from './defs';

import { i18n, I18nInterp } from '../i18n';

const Wrapper = styled.div`
  margin: 5px;
  padding: 8px;
  border: 2px dashed currentColor;
`;

export interface IPropJobInfo extends RoleInfo {
  i18n: i18n;
}

/**
 * Player's information.
 */
export class JobInfo extends React.PureComponent<IPropJobInfo, {}> {
  public render() {
    const { i18n, jobname, desc, win } = this.props;

    console.log(desc);
    return (
      <Wrapper>
        {/* Job Status. */}
        <p>
          <I18nInterp i18n={i18n} ns="game_client" k="jobinfo.status">
            {{
              job: <b>{jobname}</b>,
              details:
                desc.length === 0
                  ? null
                  : [
                      ...mapJoin(desc, '・', (obj, idx) => (
                        <React.Fragment key={`${idx}-${obj.type}`}>
                          <a href={`/manual/job/${obj.type}`}>
                            {desc.length === 1 ? '詳細' : `${obj.name}の詳細`}
                          </a>
                        </React.Fragment>
                      )),
                    ],
            }}
          </I18nInterp>
          {/* Victory or defeat. */}
          {win === true ? (
            <p>
              <I18nInterp i18n={i18n} ns="game_client" k="jobinfo.win" />
            </p>
          ) : win === false ? (
            <p>
              <I18nInterp i18n={i18n} ns="game_client" k="jobinfo.lose" />
            </p>
          ) : null}
        </p>
      </Wrapper>
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
