import * as React from 'react';
import { TranslationFunction } from '../../../i18n';
import { PlayerInfo, getSpeakKindPriority } from '../defs';
import { sortBy } from '../../../util/sort-by';

/**
 * Speak kind select control.
 */
export const SpeakKindSelect: React.StatelessComponent<{
  /**
   * List of available speak kind.
   */
  kinds: string[];
  /**
   * Currently selected speak kind.
   */
  current: string;
  /**
   * i18n function.
   */
  t: TranslationFunction;
  /**
   * Map from player id to its info.
   */
  playersMap: Map<string, PlayerInfo>;
  /**
   * Callback for change.
   */
  onChange: (kind: string) => void;
}> = ({ kinds, current, playersMap, t, onChange }) => {
  // sort kinds by its priority.
  const sortedKinds = sortBy(kinds, getSpeakKindPriority);
  return (
    <select value={current} onChange={e => onChange(e.currentTarget.value)}>
      {sortedKinds.map(value => {
        // special handling of speech kind.
        let label;
        if (value.startsWith('gmreply_')) {
          const playerObj = playersMap.get(value.slice(8));
          label = t('game_client:speak.kind.gmreply', {
            target: playerObj != null ? playerObj.name : '',
          });
        } else if (value.startsWith('helperwhisper_')) {
          label = t('game_client:speak.kind.helperwhisper');
        } else {
          label = t(`game_client:speak.kind.${value}`);
        }
        return (
          <option key={value} value={value}>
            {label}
          </option>
        );
      })}
    </select>
  );
};
