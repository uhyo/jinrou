import * as React from 'react';
import { useI18n } from '../../i18n/react';
import styled from '../../util/styled';
import { formLinkColor } from '../color';
import { contentMargin } from '../forms/style';
import { smallTextSize } from '../style';

interface Props {
  /**
   * Whether to show sign up link.
   */
  signup?: boolean;
  /**
   * Called when content of footer causes a move to another page.
   * TODO: remove need of this prop
   */
  onCancel?(): void;
}
/**
 * Show the footer of login form.
 * @internal
 */
export const LoginFormFooter = ({ signup, onCancel }: Props) => {
  const t = useI18n('common');

  return (
    <FooterWrapper>
      <a href="/reset" target="_blank">
        {t('loginForm.passwordReset')}
      </a>
      {signup ? (
        <>
          {'　'}
          <a href="/" onClick={onCancel}>
            {t('loginForm.signup')}
          </a>
        </>
      ) : null}
      {'　'}
      <a href="/manual/login" target="_blank">
        {t('loginForm.help')}
      </a>
    </FooterWrapper>
  );
};

const FooterWrapper = styled.div`
  margin: ${contentMargin}px 0;

  text-align: right;
  font-size: ${smallTextSize};

  a {
    color: ${formLinkColor};
  }
`;
