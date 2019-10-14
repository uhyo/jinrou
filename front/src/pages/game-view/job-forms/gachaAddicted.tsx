import React from 'react';
import { FormContentProps } from './defs';
import { getFormData } from '../defs';

/**
 * Make GachaAddicted form for normal gacha.
 */
export function makeGachaAddictedNormalForm({
  t,
}: FormContentProps<'GachaAddicted_Normal'>) {
  const content = (
    <p>{t('game_client_form:GachaAddicted.descriptionNormal')}</p>
  );
  // name will be used as commandname in query.
  const buttons = (
    <>
      <input
        name="normal"
        type="submit"
        value={t('game_client_form:GachaAddicted.normalButton')}
      />
    </>
  );
  return {
    content,
    buttons,
  };
}

/**
 * Make GachaAddicted form for premium gacha.
 */
export function makeGachaAddictedPremiumForm({
  form,
  t,
}: FormContentProps<'GachaAddicted_Premium'>) {
  const data = getFormData(form);
  const content = (
    <p>
      {t('game_client_form:GachaAddicted.descriptionPremium', {
        votes: data.votes,
      })}
    </p>
  );
  // name will be used as commandname in query.
  const buttons = (
    <>
      <input
        name="premium"
        type="submit"
        value={t('game_client_form:GachaAddicted.premiumButton')}
      />
    </>
  );
  return {
    content,
    buttons,
  };
}

/**
 * Make GachaAddicted form for job commission.
 */
export function makeGachaAddictedCommitForm({
  form,
  t,
}: FormContentProps<'GachaAddicted_Commit'>) {
  const data = getFormData(form);
  const jobname = t(`roles:jobname.${data.job}`);
  const content = (
    <p>
      {t('game_client_form:GachaAddicted.descriptionCommit', {
        jobname,
      })}{' '}
      <a
        href={`/manual/job/${data.job}?jobname=${encodeURIComponent(jobname)}`}
        data-jobname={jobname}
      >
        {t('game_client:jobinfo.detail_one')}
      </a>
    </p>
  );
  // name will be used as commandname in query.
  const buttons = (
    <>
      <input
        name="commit"
        type="submit"
        value={t('game_client_form:GachaAddicted.commitButton', { jobname })}
      />
    </>
  );
  return {
    content,
    buttons,
  };
}
