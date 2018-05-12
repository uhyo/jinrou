import * as React from 'react';
import { FormDesc } from '../defs';
import { TranslationFunction } from '../../i18n';

/**
 * Make a form for GM.
 */
export function makeGameMasterForm(form: FormDesc, t: TranslationFunction) {
  return (
    <>
      <p>
        {t('game_client_form:GameMaster.deadalive')}:
        <input
          name="kill"
          type="submit"
          value={t('game_client_form:GameMaster.kill')}
        />
        <input
          name="revive"
          type="submit"
          value={t('game_client_form:GameMaster.revive')}
        />
      </p>
      <p>
        {t('game_client_form:GameMaster.time')}:
        <input
          name="longer"
          type="submit"
          value={t('game_client_form:GameMaster.longer')}
        />
        <input
          name="shorter"
          type="submit"
          value={t('game_client_form:GameMaster.shorter')}
        />
      </p>
    </>
  );
}
