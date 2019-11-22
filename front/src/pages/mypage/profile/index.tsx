import React, { useState } from 'react';
import { observer } from 'mobx-react-lite';
import { Store } from '../store';
import { SectionWrapper } from '../elements';
import { FontAwesomeIcon } from '../../../util/icon';
import { useI18n } from '../../../i18n/react';
import { EditButton, SaveButtonArea } from './elements';
import { EditableInput, EditableInputs } from '../editable-input';
import { SubActiveButton } from '../../../common/forms/button';
import { IconEdit } from './edit-icon';
import { showPromptDialog } from '../../../dialog';
import { ProfileSaveQuery } from '../defs';

export const Profile: React.FunctionComponent<{
  store: Store;
  onSave: (query: ProfileSaveQuery) => Promise<boolean>;
}> = observer(({ store, onSave }) => {
  const t = useI18n('mypage_client');

  const [editing, setEditing] = useState(false);
  const [newName, setNewName] = useState(store.profile.name);
  const [newComment, setNewComment] = useState(store.profile.comment);
  const [newMailAddress, setNewMailAddress] = useState(
    store.profile.mail.address,
  );
  const [icon, setIcon] = useState(store.profile.icon);

  const { mail } = store.profile;

  const saveHandler = () => {
    showPromptDialog({
      modal: true,
      password: true,
      autocomplete: 'current-password',
      title: t('profile.title'),
      message: t('profile.savePrompt.message'),
      ok: t('profile.savePrompt.ok'),
      cancel: t('profile.savePrompt.cancel'),
    }).then(async password => {
      if (!password) {
        return;
      }
      const query = {
        name: newName !== store.profile.name ? newName : undefined,
        comment: newComment !== store.profile.comment ? newComment : undefined,
        mail:
          newMailAddress !== store.profile.mail.address
            ? newMailAddress
            : undefined,
        icon: icon !== store.profile.icon ? icon || '' : undefined,
        password,
      };
      const saved = await onSave(query);
      if (saved) {
        setEditing(false);
      }
    });
  };

  return (
    <SectionWrapper>
      <h2>
        <FontAwesomeIcon icon="user" /> {t('profile.title')}
        <EditButton slim onClick={() => setEditing(true)}>
          {t('profile.edit')}
        </EditButton>
      </h2>
      <EditableInputs>
        <EditableInput
          type="text"
          label={t('profile.userid')}
          defaultValue={store.profile.userid}
          readOnly
        />
        <EditableInput
          type="text"
          label={t('profile.name')}
          helpText={t('profile.nameHelp')}
          defaultValue={store.profile.name}
          readOnly={!editing}
          maxLength={20}
          onChange={setNewName}
        />
        <EditableInput
          type="text"
          label={t('profile.comment')}
          helpText={t('profile.commentHelp')}
          defaultValue={store.profile.comment}
          readOnly={!editing}
          maxLength={100}
          onChange={setNewComment}
        />
        <EditableInput
          label={t('profile.mailAddress')}
          helpText={t('profile.mailAddressHelp')}
          defaultValue={mail.address}
          readOnly={!editing}
          maxLength={50}
          type="email"
          onChange={setNewMailAddress}
          additionalText={
            mail.new
              ? t('profile.mailAddressChanging')
              : mail.address && !mail.verified
                ? t('profile.mailAddressNotVerified')
                : undefined
          }
        />
        <IconEdit icon={icon} setIcon={setIcon} setEditing={setEditing} />
        {editing ? (
          <SaveButtonArea>
            <SubActiveButton active type="button" onClick={saveHandler}>
              {t('profile.save')}
            </SubActiveButton>
          </SaveButtonArea>
        ) : null}
      </EditableInputs>
    </SectionWrapper>
  );
});
