import * as React from 'react';
import { useI18n } from '../../i18n/react';
import { FormAsideText } from '../../dialog/components/parts';

interface Props {
  /**
   * Called when content of footer causes a move to another page.
   * TODO: remove need of this prop
   */
  onCancel(): void;
}
/**
 * Show the footer of login form.
 * @internal
 */
export const LoginFormFooter = ({ onCancel }: Props) => {
  const t = useI18n('common');

  return (
    <FormAsideText>
      <a href="/" onClick={onCancel}>
        {t('loginForm.signup')}
      </a>
      {'　'}
      <a href="/manual/login" target="_blank">
        {t('loginForm.help')}
      </a>
    </FormAsideText>
  );
};
