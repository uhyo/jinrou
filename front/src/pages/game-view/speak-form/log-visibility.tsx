import * as React from 'react';

import { bind } from '../../../util/bind';
import { intRange } from '../../../util/range';
import { i18n, I18n } from '../../../i18n';

import { LogVisibility } from '../defs';

export interface IPropLogVisibility {
  /**
   * current visibility of logs.
   */
  visibility: LogVisibility;
  /**
   * current day of game.
   */
  day: number;
  /**
   * Update handler of visibility.
   */
  onUpdate: (obj: LogVisibility) => void;
}

/**
 * Control for manipulating log visibility.
 */
export class LogVisibilityControl extends React.PureComponent<
  IPropLogVisibility,
  {}
> {
  public render() {
    const { visibility, day } = this.props;

    // current select value.
    let value: string;
    switch (visibility.type) {
      case 'all': {
        value = 'all';
        break;
      }
      case 'today': {
        value = 'today';
        break;
      }
      case 'one': {
        value = String(visibility.day);
        break;
      }
      default: {
        const n: never = visibility;
        value = n;
        break;
      }
    }

    return (
      <I18n namespace="game_client">
        {t => (
          <select value={value} onChange={this.handleUpdate}>
            <option value="all">{t('speak.logVisibility.all')}</option>
            <option value="today">{t('speak.logVisibility.today')}</option>
            {day >= 1 ? (
              <optgroup label={t('speak.logVisibility.onedayLabel')}>
                {[...intRange(1, day)].map(day => {
                  return (
                    <option key={String(day)} value={String(day)}>
                      {t('speak.logVisibility.oneday', { day })}
                    </option>
                  );
                })}
              </optgroup>
            ) : null}
          </select>
        )}
      </I18n>
    );
  }
  @bind
  protected handleUpdate(e: React.SyntheticEvent<HTMLSelectElement>): void {
    const { onUpdate } = this.props;

    const v = e.currentTarget.value;
    if (v === 'all') {
      onUpdate({
        type: v,
      });
    } else if (v === 'today') {
      onUpdate({
        type: v,
      });
    } else {
      const day = Number(v);
      if (isFinite(day)) {
        onUpdate({
          type: 'one',
          day,
        });
      }
    }
  }
}
