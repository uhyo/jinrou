import * as React from 'react';
import { i18n, I18nProvider } from '../../i18n';
import { LoginHandler } from './def';
import { LoginFormContents, LoginFormFooter } from '../../common/login-form';
import { FormWrapper, AppWrapper } from './elements';
import { FontAwesomeIcon } from '../../util/icon';
import { WideButton } from '../../common/button';

interface Props {
  i18n: i18n;
  onLogin: LoginHandler;
}
export const TopPage = ({ i18n }: Props) => (
  <I18nProvider i18n={i18n}>
    <AppWrapper>
      <h1>{i18n.t('common:app.name')}</h1>
      <p>
        {i18n.t('top_client:app.description')}
        <a href="/manual/features">{i18n.t('top_client:app.featuresLink')}</a>
      </p>
      <FormWrapper>
        <h2>
          <FontAwesomeIcon icon="user" />
          {i18n.t('common:loginForm.title')}
        </h2>
        <LoginFormContents />
        <WideButton>{i18n.t('common:loginForm.ok')}</WideButton>
        <LoginFormFooter />
      </FormWrapper>
    </AppWrapper>
  </I18nProvider>
);
