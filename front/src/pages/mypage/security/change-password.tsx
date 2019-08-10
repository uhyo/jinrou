import React, { useState } from 'react';
import { useI18n } from '../../../i18n/react';
import { EditableInputs, EditableInput } from '../editable-input';
import { SubActiveButton } from '../../../common/forms/button';
import { ChangePasswordQuery } from '../defs';

export const ChangePassword: React.FunctionComponent<{
  onChangePassword: (query: ChangePasswordQuery) => void;
}> = ({ onChangePassword }) => {
  const t = useI18n('mypage_client');
  const [values] = useState(() => ({
    newPassword: '',
    newPassword2: '',
    currentPassword: '',
  }));

  const submitHandler = (e: React.SyntheticEvent<HTMLFormElement>) => {
    e.preventDefault();
    onChangePassword(values);
  };

  return (
    <form onSubmit={submitHandler}>
      <h3>{t('security.changePassword')}</h3>
      <EditableInputs>
        <EditableInput
          label={t('security.newPassword')}
          defaultValue=""
          required
          type="password"
          autoComplete="new-password"
          onChange={v => (values.newPassword = v)}
        />
        <EditableInput
          label={t('security.newPassword2')}
          defaultValue=""
          type="password"
          required
          autoComplete="new-password"
          onChange={v => (values.newPassword2 = v)}
        />
        <EditableInput
          label={t('security.currentPassword')}
          defaultValue=""
          type="password"
          required
          autoComplete="current-password"
          onChange={v => (values.currentPassword = v)}
        />
      </EditableInputs>
      <p>
        <SubActiveButton active>{t('security.passwordSave')} </SubActiveButton>
      </p>
    </form>
  );
};
