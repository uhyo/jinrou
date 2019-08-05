import React from 'react';
import { useI18n } from '../../../i18n/react';

export const ChangePassword = () => {
  const t = useI18n('mypage_client');
  return (
    <form>
      <h3>{t('security.changePassword')}</h3>
    </form>
  );
};
