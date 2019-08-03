import React, { useState } from 'react';
import { observer } from 'mobx-react-lite';
import { Store } from '../store';
import { SectionWrapper } from '../elements';
import { FontAwesomeIcon } from '../../../util/icon';
import { useI18n } from '../../../i18n/react';
import { EditableInputs, EditButton, SaveButtonArea } from './elements';
import { EditableInput } from './editable-input';
import { ActiveButton } from '../../../common/forms/button';
import { IconEdit } from './edit-icon';

export const Profile: React.FunctionComponent<{
  store: Store;
}> = observer(({ store }) => {
  const t = useI18n('mypage_client');

  const [editing, setEditing] = useState(false);
  const [newName, setNewName] = useState(store.profile.name);
  const [newComment, setNewComment] = useState(store.profile.comment);
  const [newMailAddress, setNewMailAddress] = useState(
    store.profile.mail.address,
  );
  const [icon, setIcon] = useState(store.profile.icon);

  const { mail } = store.profile;

  const onSave = () => {};

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
          label={t('profile.userid')}
          defaultValue={store.profile.userid}
          readOnly
        />
        <EditableInput
          label={t('profile.name')}
          helpText={t('profile.nameHelp')}
          defaultValue={store.profile.name}
          readOnly={!editing}
          maxLength={20}
          onChange={setNewName}
        />
        <EditableInput
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
          onChange={setNewComment}
          additionalText={
            mail.new
              ? t('profile.mailAddressChanging')
              : mail.address && !mail.verified
                ? t('profile.mailAddressNotVerified')
                : 'あいう'
          }
        />
        <IconEdit icon={icon} setIcon={setIcon} />
        {editing ? (
          <SaveButtonArea>
            <ActiveButton active type="button" onClick={onSave}>
              {t('profile.save')}
            </ActiveButton>
          </SaveButtonArea>
        ) : null}
      </EditableInputs>
    </SectionWrapper>
  );
});
