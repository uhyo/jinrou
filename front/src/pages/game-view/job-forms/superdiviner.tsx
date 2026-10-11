import * as React from 'react';
import { FormContentProps } from './defs';
import { getFormData } from '../defs';

/**
 * Make a form for SuperGuard skills.
 */
export function makeNormalDivinerForm({
  form,
  t,
}: FormContentProps<'NormalDiviner'>) {
  const data = getFormData(form);
  const content = <p>{t('game_client_form:SuperDiviner.description')}</p>;
  // name will be used as commandname in query.
  const buttons = (
    <>
      <input
        name="NormalDiviner"
        type="submit"
        value={t('game_client_form:SuperDiviner.DivinerButton')}
      />
    </>
  );
  return {
    content,
    buttons,
  };
}

export function makeSuperDivinerForm({
  form,
  t,
}: FormContentProps<'SuperDiviner'>) {
  const data = getFormData(form);
  const content = <p>{t('game_client_form:SuperDiviner.Superdescription')}</p>;
  // name will be used as commandname in query.
  const buttons = (
    <>
      <input
        name="SuperDiviner"
        type="submit"
        disabled={data.SuperDivinerUsed}
        value={t('game_client_form:SuperDiviner.SuperDivinerUsedButton')}
      />
    </>
  );
  return {
    content,
    buttons,
  };
}
