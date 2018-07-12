import * as React from 'react';
import { FormContentProps } from './defs';

/**
 * Make a form for Witch.
 */
export function makeWitchForm({ t }: FormContentProps) {
  return (
    <>
      <p>{t('game_client_form:Witch.description')}</p>
      <p>
        <select name="Witch_drug">
          {['kill', 'revive'].map(name => (
            <option key={name} value={name}>
              {t(`game_client_form:Witch.drug.${name}`)}
            </option>
          ))}
        </select>
      </p>
    </>
  );
}
