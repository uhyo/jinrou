import { useI18n } from '../../i18n/react';
import * as React from 'react';
import { FormInput } from '../../dialog/components/parts';
import { FormWrapper, Label, LabelInner } from './elements';
import { useUniqueId } from '../../util/useUniqueId';

interface Props {
  /**
   * ref to userid input
   */
  userIdRef?: React.RefObject<HTMLInputElement>;
  /**
   * ref to password input
   */
  passwordRef?: React.RefObject<HTMLInputElement>;
  /**
   * Whether this is for signup form.
   */
  signup?: boolean;
}

/**
 * Show the main contents of login form.
 * @internal
 */
export const LoginFormContents = ({
  userIdRef,
  passwordRef,
  signup,
}: Props) => {
  const t = useI18n('common');
  const nameInputId = useUniqueId();
  const passwordInputId = useUniqueId();
  return (
    <FormWrapper>
      <Label htmlFor={nameInputId}>
        <LabelInner>{t('loginForm.userid')}</LabelInner>
      </Label>
      <span>
        <FormInput
          ref={userIdRef}
          id={nameInputId}
          type="text"
          autoComplete="username"
          required
        />
      </span>
      <Label htmlFor={passwordInputId}>
        <LabelInner>{t('loginForm.password')}</LabelInner>
      </Label>
      <span>
        <FormInput
          ref={passwordRef}
          id={passwordInputId}
          type="password"
          autoComplete={signup ? 'new-password' : 'current-password'}
          required
        />
      </span>
    </FormWrapper>
  );
};
