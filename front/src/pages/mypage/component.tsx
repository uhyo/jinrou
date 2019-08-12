import * as React from 'react';
import { useI18n } from '../../i18n/react';
import { Store } from './store';
import { AppWrapper } from './elements';
import { Profile } from './profile';
import { ProfileSaveQuery, ChangePasswordQuery } from './defs';
import { Security } from './security';
import { News } from './news';
import { BanAlert } from './ban-alert';
import { Links } from './links';

interface Props {
  store: Store;
  onProfileSave: (query: ProfileSaveQuery) => Promise<boolean>;
  onMailConfirmSecurityChange: (value: boolean) => Promise<boolean>;
  onChangePassword: (query: ChangePasswordQuery) => Promise<boolean>;
}
export const MyPage: React.FunctionComponent<Props> = ({
  store,
  onProfileSave,
  onMailConfirmSecurityChange,
  onChangePassword,
}) => {
  const t = useI18n('mypage_client');
  return (
    <AppWrapper>
      <h1>{t('title')}</h1>
      <BanAlert store={store} />
      <Profile store={store} onSave={onProfileSave} />
      <Security
        store={store}
        onMailConfirmSecurityChange={onMailConfirmSecurityChange}
        onChangePassword={onChangePassword}
      />
      <News store={store} />
      <Links store={store} />
    </AppWrapper>
  );
};
