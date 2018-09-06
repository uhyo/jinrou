import * as React from 'react';
import { FormContentProps } from './defs';
import { getFormData } from '../defs';

/**
 * Make a form for Werewolf attack.
 */
export function makeWerewolfForm({ form, t }: FormContentProps<'_Werewolf'>) {
  const data = getFormData(form);
  return (
    <>
      <p>{t('game_client_form:_Werewolf.description')}</p>
      {data.remains > 1 ? (
        // notify that more than one attacks can be made.
        <p>
          {t('game_client_form:_Werewolf.remains', { count: data.remains })}
        </p>
      ) : null}
    </>
  );
}
