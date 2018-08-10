import * as React from 'react';
import { FormContentProps } from './defs';

/**
 * Make a form for GM.
 */
export function makeGameMasterForm({ t }: FormContentProps) {
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
          value={t('game_client_form:GameMaster.longer', { count: 30 })}
        />
        <input
          name="shorter"
          type="submit"
          value={t('game_client_form:GameMaster.shorter', { count: 30 })}
        />
      </p>
    </>
  );
}
