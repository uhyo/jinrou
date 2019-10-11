import * as React from 'react';
import { i18n, I18nProvider, I18nInterp } from '../../i18n';
import { LoginHandler, SignupHandler } from './def';
import { LoginFormContents, LoginFormFooter } from '../../common/login-form';
import {
  FormWrapper,
  AppWrapper,
  ErrorLine,
  ContentsWrapper,
  Footer,
  NoticeUl,
} from './elements';
import { FontAwesomeIcon } from '../../util/icon';
import { WideButton } from '../../common/button';
import { PlainText } from '../../common/forms/plain-text';
import { InlineWarning } from '../../common/warning';
import { useRefs } from '../../util/useRefs';
import { Details } from '../../common/forms/details';
import { Features } from './features';
import { Headline } from './headline';

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
    featuresSectionRef,
  ] = useRefs<
    [
      HTMLInputElement,
      HTMLInputElement,
      HTMLInputElement,
      HTMLInputElement,
      HTMLElement
    ]
  >(null, null, null, null, null);

  const loginFormSubmitHandler = (e: React.SyntheticEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (loginFormUserIdRef.current && loginFormPasswordRef.current) {
      onLogin({
        userId: loginFormUserIdRef.current.value,
        password: loginFormPasswordRef.current.value,
        rememberMe: true,
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

  const gotoFeaturesHandler = (e: React.SyntheticEvent<HTMLAnchorElement>) => {
    e.preventDefault();
    const target = featuresSectionRef.current;
    if (!target) {
      return;
    }

    target.scrollIntoView({
      behavior: 'smooth',
    });
  };

  return (
    <I18nProvider i18n={i18n}>
      <Headline onSeeFeature={gotoFeaturesHandler} />
      <AppWrapper>
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
              signup
              userIdRef={signupFormUserIdRef}
              passwordRef={signupFormPasswordRef}
            />
            <Details
              summaryOpen={i18n.t('top_client:signup.notice.summaryOpen')}
              summaryClosed={i18n.t('top_client:signup.notice.summaryClosed')}
            >
              <NoticeUl>
                <li>{i18n.t('top_client:signup.notice.notice1')}</li>
                <li>{i18n.t('top_client:signup.notice.notice2')}</li>
                <li>
                  <I18nInterp ns="top_client" k="signup.notice.notice3">
                    {{
                      link: (
                        <a href="/manual/prohibited">
                          {i18n.t('top_client:signup.notice.manualLink')}
                        </a>
                      ),
                    }}
                  </I18nInterp>
                </li>
              </NoticeUl>
            </Details>
            <ErrorLine>
              <InlineWarning>{signupError}</InlineWarning>
            </ErrorLine>
            <WideButton>{i18n.t('top_client:signup.submit')}</WideButton>
          </FormWrapper>
          <Features i18n={i18n} ref={featuresSectionRef} />
        </ContentsWrapper>
        <Footer>
          <p>
            {i18n.t('top_client:footer.text')} (
            <a href="http://github.com/uhyo/jinrou" target="_blank">
              {i18n.t('top_client:footer.github')}
            </a>
            )
          </p>
        </Footer>
      </AppWrapper>
    </I18nProvider>
  );
};
