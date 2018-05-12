import * as React from 'react';
import { FormDesc } from '../defs';
import { TranslationFunction } from '../../i18n';

/**
 * Make a form for Witch.
 */
export function makeWitchForm(form: FormDesc, t: TranslationFunction) {
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
