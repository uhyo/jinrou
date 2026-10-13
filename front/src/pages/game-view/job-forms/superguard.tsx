import * as React from 'react';
import { FormContentProps } from './defs';
import { getFormData } from '../defs';

/**
 * Make a form for SuperGuard skills.
 */
export function makeNormalGuardForm({
  form,
  t,
}: FormContentProps<'NormalGuard'>) {
  const data = getFormData(form);
  const content = <p>{t('game_client_form:SuperGuard.description')}</p>;
  // name will be used as commandname in query.
  const buttons = (
    <>
      <input
        name="NormalGuard"
        type="submit"
        value={t('game_client_form:SuperGuard.GuardButton')}
      />
    </>
  );
  return {
    content,
    buttons,
  };
}

export function makeSuperGuardForm({
  form,
  t,
}: FormContentProps<'SuperGuard'>) {
  const data = getFormData(form);
  const content = <p>{t('game_client_form:SuperGuard.Superdescription')}</p>;
  // name will be used as commandname in query.
  const buttons = (
    <>
      <input
        name="SuperGuard"
        type="submit"
        disabled={data.SuperGuardUsed}
        value={t('game_client_form:SuperGuard.SuperGuardUsedButton')}
      />
    </>
  );
  return {
    content,
    buttons,
  };
}
