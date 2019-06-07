import * as React from 'react';
import { i18n, I18nProvider } from '../../i18n';
import { LoginHandler, SignupHandler } from './def';
import { LoginFormContents, LoginFormFooter } from '../../common/login-form';
import {
  FormWrapper,
  AppWrapper,
  ErrorLine,
  ContentsWrapper,
} from './elements';
import { FontAwesomeIcon } from '../../util/icon';
import { WideButton } from '../../common/button';
import { PlainText } from '../../common/forms/plain-text';
import { InlineWarning } from '../../common/warning';
import { useRefs } from '../../util/useRefs';

interface Props {
  i18n: i18n;
  onLogin: LoginHandler;
  onSignup: SignupHandler;
}
export const TopPage = ({ i18n, onLogin, onSignup }: Props) => {
  const [loginError, updateLoginError] = React.useState('');
  const [signupError, updateSignupError] = React.useState('');

  const [
    loginFormUserIdRef,
    loginFormPasswordRef,
    signupFormUserIdRef,
    signupFormPasswordRef,
  ] = useRefs<
    [HTMLInputElement, HTMLInputElement, HTMLInputElement, HTMLInputElement]
  >(null, null, null, null);

  const loginFormSubmitHandler = (e: React.SyntheticEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (loginFormUserIdRef.current && loginFormPasswordRef.current) {
      onLogin({
        userId: loginFormUserIdRef.current.value,
        password: loginFormPasswordRef.current.value,
      })
        .then(({ error }) => {
          updateLoginError(error ? i18n.t('top_client:app.loginError') : '');
        })
        .catch(err => {
          updateLoginError(String(err));
        });
    }
  };
  const signupFormSubmitHandler = (
    e: React.SyntheticEvent<HTMLFormElement>,
  ) => {
    e.preventDefault();
    if (signupFormUserIdRef.current && signupFormPasswordRef.current) {
      onSignup({
        userId: signupFormUserIdRef.current.value,
        password: signupFormPasswordRef.current.value,
      })
        .then(({ error }) => {
          updateSignupError(error || '');
        })
        .catch(err => {
          updateSignupError(String(err));
        });
    }
  };
  return (
    <I18nProvider i18n={i18n}>
      <AppWrapper>
        <h1>{i18n.t('common:app.name')}</h1>
        <p>
          {i18n.t('top_client:app.description')}
          <a href="/manual/features">{i18n.t('top_client:app.featuresLink')}</a>
        </p>
        <ContentsWrapper>
          <FormWrapper onSubmit={loginFormSubmitHandler}>
            <h2>
              <FontAwesomeIcon icon="user" />
              {i18n.t('common:loginForm.title')}
            </h2>
            <LoginFormContents
              userIdRef={loginFormUserIdRef}
              passwordRef={loginFormPasswordRef}
            />
            <ErrorLine>
              <InlineWarning>{loginError}</InlineWarning>
            </ErrorLine>
            <WideButton>{i18n.t('common:loginForm.ok')}</WideButton>
            <LoginFormFooter />
          </FormWrapper>
          <FormWrapper onSubmit={signupFormSubmitHandler}>
            <h2>
              <FontAwesomeIcon icon="file-signature" />
              {i18n.t('top_client:signup.title')}
            </h2>
            <PlainText>{i18n.t('top_client:signup.description1')}</PlainText>
            <PlainText>{i18n.t('top_client:signup.description2')}</PlainText>
            <LoginFormContents
              userIdRef={signupFormUserIdRef}
              passwordRef={signupFormPasswordRef}
            />
            <ErrorLine>
              <InlineWarning>{signupError}</InlineWarning>
            </ErrorLine>
            <WideButton>{i18n.t('top_client:signup.submit')}</WideButton>
          </FormWrapper>
        </ContentsWrapper>
      </AppWrapper>
    </I18nProvider>
  );
};
