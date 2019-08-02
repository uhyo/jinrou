import * as React from 'react';
import { useI18n } from '../../i18n/react';
import { Store } from './store';
import { AppWrapper } from './elements';
import { Profile } from './profile';

interface Props {
  store: Store;
}
export const MyPage: React.FunctionComponent<Props> = ({ store }) => {
  const t = useI18n('mypage_client');
  return (
    <AppWrapper>
      <h1>{t('title')}</h1>
      <Profile store={store} />
    </AppWrapper>
  );
};
