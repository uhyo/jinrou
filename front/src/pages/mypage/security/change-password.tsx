import React from 'react';
import { useI18n } from '../../../i18n/react';
import { EditableInputs, EditableInput } from '../editable-input';
import { SubActiveButton } from '../../../common/forms/button';

export const ChangePassword = () => {
  const t = useI18n('mypage_client');
  return (
    <form>
      <h3>{t('security.changePassword')}</h3>
      <EditableInputs>
        <EditableInput
          label={t('security.newPassword')}
          defaultValue=""
          type="password"
          autoComplete="new-password"
        />
        <EditableInput
          label={t('security.newPassword2')}
          defaultValue=""
          type="password"
          autoComplete="new-password"
        />
        <EditableInput
          label={t('security.currentPassword')}
          defaultValue=""
          type="password"
          autoComplete="current-password"
        />
      </EditableInputs>
      <p>
        <SubActiveButton active>{t('security.passwordSave')} </SubActiveButton>
      </p>
    </form>
  );
};
