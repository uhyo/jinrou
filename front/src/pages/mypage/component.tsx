import * as React from 'react';
import { useI18n } from '../../i18n/react';
import { Store } from './store';
import { AppWrapper } from './elements';
import { Profile } from './profile';
import { ProfileSaveQuery } from './defs';

interface Props {
  store: Store;
  onProfileSave: (query: ProfileSaveQuery) => Promise<boolean>;
}
export const MyPage: React.FunctionComponent<Props> = ({
  store,
  onProfileSave,
}) => {
  const t = useI18n('mypage_client');
  return (
    <AppWrapper>
      <h1>{t('title')}</h1>
      <Profile store={store} onSave={onProfileSave} />
    </AppWrapper>
  );
};
