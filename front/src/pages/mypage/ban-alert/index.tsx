import React from 'react';
import { Store } from '../store';
import { useI18n } from '../../../i18n/react';
import { BanSectionWrapper } from './element';

interface Props {
  store: Store;
}

export const BanAlert: React.FunctionComponent<Props> = ({ store }) => {
  const t = useI18n('mypage_client');
  const { ban } = store;
  if (ban == null) {
    return null;
  }
  console.log(ban);
  return (
    <BanSectionWrapper>
      <p>{t('ban.announcement')}</p>
      <p>
        {t('ban.reason')} <b>{ban.reason}</b>
      </p>
    </BanSectionWrapper>
  );
};
