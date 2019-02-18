import * as React from 'react';
import { FormContentProps } from './defs';
import { getFormData } from '../defs';

/**
 * Make a form for DragonKnight skills.
 */
export function makeDragonKnightForm({
  form,
  t,
}: FormContentProps<'DragonKnight'>) {
  const data = getFormData(form);
  const content = <p>{t('game_client_form:DragonKnight.description')}</p>;
  // name will be used as commandname in query.
  const buttons = (
    <>
      <input
        name="kill"
        type="submit"
        disabled={data.killUsed}
        value={
          data.killUsed
            ? t('game_client_form:DragonKnight.killButtonUsed')
            : t('game_client_form:DragonKnight.killButton')
        }
      />
      <input
        name="guard"
        type="submit"
        value={t('game_client_form:DragonKnight.guardButton')}
      />
    </>
  );
  return {
    content,
    buttons,
  };
}
