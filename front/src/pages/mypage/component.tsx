import * as React from 'react';
import { AppWrapper } from '../top-page/elements';
import { useI18n } from '../../i18n/react';

interface Props {}
export const MyPage = () => {
  const t = useI18n('mypage_client');
  return (
    <AppWrapper>
      <h1>{t('title')}</h1>
    </AppWrapper>
  );
};
