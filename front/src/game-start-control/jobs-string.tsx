import * as React from 'react';
import { observer } from 'mobx-react';

import { i18n, I18n, TranslationFunction } from '../i18n';

import { InlineWarning } from '../common/warning';
import { RoleCategoryDefinition } from '../defs';

export interface IPropJobsString {
  t: TranslationFunction;
  i18n: i18n;
  jobNumbers: Record<string, number>;
  categoryNumbers: Map<string, number>;
  roles: string[];
  categories: RoleCategoryDefinition[];
}
/**
 * String representing given jobNumbers.
 */
@observer
export class JobsString extends React.Component<IPropJobsString, {}> {
  public render() {
    const {
      t,
      i18n,
      jobNumbers,
      categoryNumbers,
      roles,
      categories,
    } = this.props;
    return (
      <>
        {roles.map(id => {
          const val = jobNumbers[id] || 0;
          if (val > 0) {
            return (
              <React.Fragment key={id}>
                {t(`roles:jobname.${id}`)}: {val}{' '}
              </React.Fragment>
            );
          } else {
            return null;
          }
        })}
        {categories.map(({ id }) => {
          const val = categoryNumbers.get(id) || 0;
          if (val > 0) {
            return (
              <React.Fragment key={id}>
                {t(`roles:categoryName.${id}`)}: {val}{' '}
              </React.Fragment>
            );
          } else {
            return null;
          }
        })}
      </>
    );
  }
}

export interface IPropPlayerNumberError {
  t: TranslationFunction;
  minNumber?: number;
  maxNumber?: number;
}

/**
 * Player number is not enough.
 */
export function PlayerNumberError({
  t,
  minNumber,
  maxNumber,
}: IPropPlayerNumberError) {
  if (minNumber != null) {
    return (
      <InlineWarning>
        {t('game_client:gamestart.info.playerTooFew', {
          count: minNumber,
        })}
      </InlineWarning>
    );
  } else if (maxNumber != null) {
    return (
      <InlineWarning>
        {t('game_client:gamestart.info.playerTooMany', {
          count: maxNumber,
        })}
      </InlineWarning>
    );
  } else {
    return null;
  }
}
