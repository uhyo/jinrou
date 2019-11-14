import React from 'react';
import { useI18n } from '../../../i18n/react';
import { EditableInputWrapper } from '../editable-input';
import { Button } from '../../../common/forms/button';
import { showIconSelectDialog } from '../../../dialog';
import styled from '../../../util/styled';

interface Props {
  icon: string | null;
  setIcon: (newIcon: string | null) => void;
  setEditing: (editing: true | false) => void;
}
export const IconEdit: React.FunctionComponent<Props> = ({
  icon,
  setIcon,
  setEditing,
}) => {
  const t = useI18n('mypage_client');

  const clickHandler = () => {
    showIconSelectDialog({
      modal: true,
    }).then(newIcon => {
      newIcon && setEditing(newIcon != icon);
      newIcon && setIcon(newIcon);
    });
  };
  return (
    <EditableInputWrapper label={t('profile.icon')}>
      {icon ? <img src={icon} width={48} height={48} /> : null}
      <EditButton onClick={clickHandler}>{t('profile.iconSelect')}</EditButton>
      {icon ? (
        <EditButton
          onClick={() => {
            setEditing(true);
            setIcon(null);
          }}
        >
          {t('profile.iconDelete')}
        </EditButton>
      ) : null}
    </EditableInputWrapper>
  );
};

const EditButton = styled(Button)`
  vertical-align: text-bottom;
`;
