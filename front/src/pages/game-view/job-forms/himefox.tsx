import * as React from 'react';
import { FormContentProps } from './defs';

export function makeHimeFoxSacrificeForm({ t }: FormContentProps<'HimeFox'>) {
  return {
    content: <p>{t('game_client_form:HimeFox.sacrifice.description')}</p>,
    buttons: (
      <input
        name="himefoxSacrifice"
        type="submit"
        value={t('game_client_form:HimeFox.sacrifice.button')}
      />
    ),
  };
}

export function makeNekikillTargetForm({
  t,
}: FormContentProps<'NekikillTarget'>) {
  return {
    content: <p>{t('game_client_form:HimeFox.nekikill.description')}</p>,
    buttons: (
      <input
        name="nekikillTarget"
        type="submit"
        value={t('game_client_form:HimeFox.nekikill.button')}
      />
    ),
  };
}
