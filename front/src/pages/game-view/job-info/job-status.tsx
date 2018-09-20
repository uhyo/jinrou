import * as React from 'react';
import { RoleDesc } from '../defs';
import { TranslationFunction, I18nInterp } from '../../../i18n';

/**
 * Component to show job status.
 * @package
 */
export const JobStatus: React.StatelessComponent<{
  jobname: string;
  desc: RoleDesc[];
  t: TranslationFunction;
}> = ({ jobname, desc, t }) => {
  return (
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
  );
};

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
