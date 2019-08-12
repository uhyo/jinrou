import { SectionWrapper } from '../elements';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { useI18n } from '../../../i18n/react';
import React, { useState, useEffect } from 'react';
import { CheckButton } from '../../../common/forms/check-button';
import { Store } from '../store';
import { Description } from './elements';
import { Button } from '../../../common/forms/button';
import { ChangePassword } from './change-password';
import { ChangePasswordQuery } from '../defs';

interface Props {
  store: Store;
  /**
   * Change the mail confirm security flag.
   * Resolves to true if accepted.
   */
  onMailConfirmSecurityChange: (value: boolean) => Promise<boolean>;
  /**
   * Change the password.
   */
  onChangePassword: (value: ChangePasswordQuery) => Promise<boolean>;
}

export const Security = ({
  store,
  onMailConfirmSecurityChange,
  onChangePassword,
}: Props) => {
  const t = useI18n('mypage_client');

  const [mailConfirmSecurity, setMCS] = useState(store.mailConfirmSecurity);

  const mcsChangeHandler = (value: boolean) => {
    setMCS(value);
    onMailConfirmSecurityChange(value).then(accepted => {
      if (accepted) {
        onMailConfirmSecurityChange(value);
      } else {
        setMCS(!value);
      }
    });
  };

  const [changingPassword, setChangingPassword] = useState(false);

  const handleChangePassword = async (query: ChangePasswordQuery) => {
    const changed = await onChangePassword(query);
    if (changed) {
      setChangingPassword(false);
    }
  };

  return (
    <SectionWrapper>
      <h2>
        <FontAwesomeIcon icon="lock" />
        {t('security.title')}
      </h2>
      <p>
        <CheckButton checked={mailConfirmSecurity} onChange={mcsChangeHandler}>
          {t('security.mailConfirmSecurity')}
        </CheckButton>
      </p>
      <Description>{t('security.mailConfirmSecurityHelp')}</Description>
      <hr />
      {changingPassword ? (
        <ChangePassword onChangePassword={handleChangePassword} />
      ) : (
        <p>
          <Button onClick={() => setChangingPassword(v => !v)}>
            {t('security.changePassword')}
          </Button>
        </p>
      )}
    </SectionWrapper>
  );
};
